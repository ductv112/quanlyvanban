/**
 * smartca-mock.ts — Mock SmartCA VNPT signing provider
 * Port 8181, 4 endpoints + /health
 *
 * Header X-Mock-Scenario:
 *   - (none)             → success path
 *   - timeout            → trả 504 sau 5s (KHÔNG 30s thật để không slow test)
 *   - invalid_cert       → trả 400 'Chứng thư số không hợp lệ'
 *   - provider_down      → trả 503
 *   - rate_limit         → trả 429 (extra cho future TC)
 *   - slow               → trả normal response sau 3s (test loading state)
 */

import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';

const PORT = Number(process.env.SMARTCA_MOCK_PORT) || 8181;
const SERVICE = 'smartca';

const app = express();
app.use(express.json({ limit: '10mb' }));
app.use(cors());

// Scenario middleware (works on all endpoints, including /health)
app.use((req: Request, res: Response, next: NextFunction) => {
  const scenario = req.header('X-Mock-Scenario');
  if (!scenario) return next();

  console.log(`[mock-smartca] scenario=${scenario} ${req.method} ${req.path}`);

  switch (scenario) {
    case 'timeout':
      // KHÔNG sleep 30s thật — sleep 5s rồi 504. Test có timeout 10s vẫn catch được
      setTimeout(() => res.status(504).json({ error: 'Gateway timeout', mock_scenario: 'timeout' }), 5000);
      return;
    case 'invalid_cert':
      res.status(400).json({ error: 'Chứng thư số không hợp lệ hoặc đã hết hạn', mock_scenario: 'invalid_cert' });
      return;
    case 'provider_down':
      res.status(503).json({ error: 'Dịch vụ ký số tạm ngưng', mock_scenario: 'provider_down' });
      return;
    case 'rate_limit':
      res.status(429).json({ error: 'Quá giới hạn yêu cầu', mock_scenario: 'rate_limit' });
      return;
    case 'slow':
      // 3s delay rồi normal response — test loading UI
      setTimeout(() => next(), 3000);
      return;
    default:
      return next();
  }
});

// /health (cho CI wait-on)
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: SERVICE, port: PORT, timestamp: new Date().toISOString() });
});

// POST /smartca/auth (initiate signing session)
app.post('/smartca/auth', (req: Request, res: Response) => {
  const { user_id, redirect_uri } = req.body || {};
  if (!user_id) {
    res.status(400).json({ status_code: '99', error: 'user_id required' });
    return;
  }
  const tranId = `MOCK-TRAN-${Date.now()}`;
  res.json({
    status_code: '00',
    message: 'Khởi tạo phiên ký thành công',
    data: {
      tran_id: tranId,
      auth_url: `http://localhost:${PORT}/smartca/mock-confirm?tran_id=${tranId}`,
      redirect_uri: redirect_uri || 'http://localhost:3000/ky-so/callback',
      expires_in: 600,
    },
  });
});

// POST /smartca/sign (perform signing)
app.post('/smartca/sign', (req: Request, res: Response) => {
  const { tran_id, payload } = req.body || {};
  if (!tran_id || !payload) {
    res.status(400).json({ status_code: '99', error: 'tran_id and payload required' });
    return;
  }
  // Mock signed XML/PDF response
  const signedHex = Buffer.from(`MOCK-SIGNED-${tran_id}`).toString('hex');
  res.json({
    status_code: '00',
    message: 'Ký thành công',
    data: {
      tran_id,
      signature: signedHex,
      signed_at: new Date().toISOString(),
      cert_serial: 'MOCK-CERT-SERIAL-12345',
      cert_subject: 'CN=Mock Signer,O=Mock Org,C=VN',
    },
  });
});

// POST /smartca/verify (verify signature)
app.post('/smartca/verify', (req: Request, res: Response) => {
  const { signature, payload } = req.body || {};
  if (!signature || !payload) {
    res.status(400).json({ status_code: '99', error: 'signature and payload required' });
    return;
  }
  res.json({
    status_code: '00',
    message: 'Chữ ký hợp lệ',
    data: {
      valid: true,
      signer_name: 'Mock Signer',
      cert_serial: 'MOCK-CERT-SERIAL-12345',
      signed_at: new Date().toISOString(),
    },
  });
});

// GET /smartca/cert/:userId (fetch user cert)
app.get('/smartca/cert/:userId', (req: Request, res: Response) => {
  const { userId } = req.params;
  res.json({
    status_code: '00',
    message: 'Lấy chứng thư số thành công',
    data: {
      user_id: userId,
      cert_serial: 'MOCK-CERT-SERIAL-12345',
      cert_pem: '-----BEGIN CERTIFICATE-----\nMOCK_CERT_PEM_DATA\n-----END CERTIFICATE-----',
      issued_at: new Date(Date.now() - 90 * 86400000).toISOString(),
      expires_at: new Date(Date.now() + 365 * 86400000).toISOString(),
      issuer: 'Mock VNPT-CA',
      common_name: `TEST CN ${userId}`,
    },
  });
});

// Mock confirm page (cho TC user click "Đồng ý" trên mobile)
app.get('/smartca/mock-confirm', (req: Request, res: Response) => {
  res.send(`
    <html><body style="font-family: sans-serif; padding: 24px">
      <h1>SmartCA Mock Confirm</h1>
      <p>tran_id: ${req.query.tran_id}</p>
      <button onclick="window.location.href='${req.query.redirect_uri || 'http://localhost:3000'}'">Đồng ý ký</button>
    </body></html>
  `);
});

// Catch-all for unknown endpoints (Express 5 syntax: '*splat')
app.all('*splat', (req: Request, res: Response) => {
  res.status(404).json({ error: `Endpoint không tồn tại: ${req.method} ${req.path}`, mock: SERVICE });
});

const server = app.listen(PORT, () => {
  console.log(`[mock-smartca] listening on http://localhost:${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('[mock-smartca] SIGTERM — shutting down');
  server.close(() => process.exit(0));
});
process.on('SIGINT', () => {
  console.log('[mock-smartca] SIGINT — shutting down');
  server.close(() => process.exit(0));
});

export {};
