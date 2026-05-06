/**
 * mysign-mock.ts — Mock MySign Viettel signing provider (backup)
 * Port 8182, similar API như SmartCA
 *
 * MySign khác SmartCA: ít field hơn, response shape đơn giản hơn (theo guide thực tế)
 *
 * X-Mock-Scenario: timeout | invalid_cert | provider_down | slow
 */

import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';

const PORT = Number(process.env.MYSIGN_MOCK_PORT) || 8182;
const SERVICE = 'mysign';

const app = express();
app.use(express.json({ limit: '10mb' }));
app.use(cors());

app.use((req: Request, res: Response, next: NextFunction) => {
  const scenario = req.header('X-Mock-Scenario');
  if (!scenario) return next();
  console.log(`[mock-mysign] scenario=${scenario} ${req.method} ${req.path}`);
  switch (scenario) {
    case 'timeout':
      setTimeout(() => res.status(504).json({ error: 'timeout', mock_scenario: scenario }), 5000);
      return;
    case 'invalid_cert':
      res.status(400).json({ code: 99, error: 'Chứng thư số không hợp lệ', mock_scenario: scenario });
      return;
    case 'provider_down':
      res.status(503).json({ code: 503, error: 'Dịch vụ tạm ngừng', mock_scenario: scenario });
      return;
    case 'slow':
      setTimeout(() => next(), 3000);
      return;
    default:
      return next();
  }
});

app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: SERVICE, port: PORT, timestamp: new Date().toISOString() });
});

// POST /mysign/auth — initiate signing session
app.post('/mysign/auth', (req: Request, res: Response) => {
  const { user_id } = req.body || {};
  if (!user_id) {
    res.status(400).json({ code: 99, error: 'user_id required' });
    return;
  }
  res.json({
    code: 0,
    message: 'OK',
    tran_id: `MS-${Date.now()}`,
    auth_url: `http://localhost:${PORT}/mysign/mock-confirm`,
    expires_in: 600,
  });
});

// POST /mysign/sign — perform signing
app.post('/mysign/sign', (req: Request, res: Response) => {
  const { tran_id, payload } = req.body || {};
  if (!tran_id || !payload) {
    res.status(400).json({ code: 99, error: 'tran_id and payload required' });
    return;
  }
  res.json({
    code: 0,
    message: 'Signed',
    tran_id,
    signature: Buffer.from(`MOCK-MS-${tran_id}`).toString('base64'),
    signed_at: new Date().toISOString(),
  });
});

// POST /mysign/verify
app.post('/mysign/verify', (req: Request, res: Response) => {
  const { signature, payload } = req.body || {};
  if (!signature || !payload) {
    res.status(400).json({ code: 99, error: 'signature and payload required' });
    return;
  }
  res.json({
    code: 0,
    valid: true,
    signer: 'Mock MySign Signer',
    signed_at: new Date().toISOString(),
  });
});

// GET /mysign/cert/:userId
app.get('/mysign/cert/:userId', (req: Request, res: Response) => {
  res.json({
    code: 0,
    user_id: req.params.userId,
    cert_pem: '-----BEGIN CERTIFICATE-----\nMOCK_MYSIGN_CERT\n-----END CERTIFICATE-----',
    cert_serial: 'MOCK-MS-CERT-001',
    issuer: 'Mock Viettel-CA',
    expires_at: new Date(Date.now() + 365 * 86400000).toISOString(),
  });
});

// Mock confirm page
app.get('/mysign/mock-confirm', (req: Request, res: Response) => {
  res.send(`
    <html><body style="font-family: sans-serif; padding: 24px">
      <h1>MySign Mock Confirm</h1>
      <p>tran_id: ${req.query.tran_id || 'N/A'}</p>
      <button onclick="window.location.href='http://localhost:3000'">Đồng ý ký</button>
    </body></html>
  `);
});

app.all('*splat', (req: Request, res: Response) => {
  res.status(404).json({ error: `Not found: ${req.method} ${req.path}`, mock: SERVICE });
});

const server = app.listen(PORT, () => {
  console.log(`[mock-mysign] listening on http://localhost:${PORT}`);
});

process.on('SIGTERM', () => {
  console.log('[mock-mysign] SIGTERM');
  server.close(() => process.exit(0));
});
process.on('SIGINT', () => {
  console.log('[mock-mysign] SIGINT');
  server.close(() => process.exit(0));
});

export {};
