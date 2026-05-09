/**
 * lgsp-mock.ts — Mock LGSP Lào Cai gateway
 * Port 8183, REST endpoints (LGSP real dùng REST/JSON, không phải SOAP — đã verify Phase 18)
 *
 * Endpoint pattern khớp LGSP-LANGSON-API-GUIDE.md (Phase 18 v3.0 LGSPRealService):
 *   POST /api/lgspedoc/login              → token
 *   POST /api/lgspedoc/refresh-token       → new token
 *   POST /api/lgspedoc/send-document       → submit VB đi
 *   POST /api/lgspedoc/update-status       → update VB status (01/02/03/04/05/06)
 *   GET  /api/lgspedoc/get-documents      → poll inbox
 *   GET  /api/lgspedoc/get-document/:id    → detail
 *   GET  /api/lgspedoc/cert                → cert info
 *   GET  /health                           → health check
 *
 * Status codes (per LGSP guide):
 *   01 = received, 02 = rejected, 03 = processing, 04 = completed, 05 = forwarded, 06 = error
 *
 * X-Mock-Scenario:
 *   - timeout            → 504 sau 5s
 *   - auth_fail          → 401
 *   - provider_down      → 503
 *   - invalid_payload    → 400 với detailed validation error
 *   - slow               → normal response sau 3s (test loading state)
 */

import express, { Request, Response, NextFunction } from 'express';
import cors from 'cors';

const PORT = Number(process.env.LGSP_MOCK_PORT) || 8183;
const SERVICE = 'lgsp';

const app = express();
app.use(express.json({ limit: '50mb' })); // LGSP có thể nhận file base64 lớn
app.use(cors());

// Scenario middleware
app.use((req: Request, res: Response, next: NextFunction) => {
  const scenario = req.header('X-Mock-Scenario');
  if (!scenario) return next();
  console.log(`[mock-lgsp] scenario=${scenario} ${req.method} ${req.path}`);
  switch (scenario) {
    case 'timeout':
      setTimeout(() => res.status(504).json({ error: 'timeout', mock_scenario: scenario }), 5000);
      return;
    case 'auth_fail':
      res.status(401).json({ code: 401, message: 'Token không hợp lệ', mock_scenario: scenario });
      return;
    case 'provider_down':
      res.status(503).json({ code: 503, message: 'Dịch vụ trục liên thông tạm ngưng', mock_scenario: scenario });
      return;
    case 'invalid_payload':
      res.status(400).json({
        code: 400,
        message: 'Payload không hợp lệ',
        errors: ['document_code required', 'recipient_unit_id required'],
        mock_scenario: scenario,
      });
      return;
    case 'slow':
      setTimeout(() => next(), 3000);
      return;
    default:
      return next();
  }
});

// /health
app.get('/health', (_req: Request, res: Response) => {
  res.json({ status: 'ok', service: SERVICE, port: PORT, timestamp: new Date().toISOString() });
});

// POST /api/lgspedoc/login
app.post('/api/lgspedoc/login', (req: Request, res: Response) => {
  const { username, password, application_code } = req.body || {};
  if (!username || !password) {
    res.status(400).json({ code: 400, message: 'username/password required' });
    return;
  }
  res.json({
    code: 0,
    message: 'Đăng nhập thành công',
    data: {
      access_token: `MOCK-LGSP-TOKEN-${Date.now()}`,
      refresh_token: `MOCK-LGSP-REFRESH-${Date.now()}`,
      expires_in: 3600,
      application_code: application_code || 'QLVB-MOCK',
    },
  });
});

// POST /api/lgspedoc/refresh-token
app.post('/api/lgspedoc/refresh-token', (req: Request, res: Response) => {
  const { refresh_token } = req.body || {};
  if (!refresh_token) {
    res.status(400).json({ code: 400, message: 'refresh_token required' });
    return;
  }
  res.json({
    code: 0,
    data: { access_token: `MOCK-LGSP-TOKEN-${Date.now()}`, expires_in: 3600 },
  });
});

// POST /api/lgspedoc/send-document — submit VB đi
app.post('/api/lgspedoc/send-document', (req: Request, res: Response) => {
  const { document_code, abstract, recipient_unit_id } = req.body || {};
  if (!document_code || !recipient_unit_id) {
    res.status(400).json({ code: 400, message: 'document_code and recipient_unit_id required' });
    return;
  }
  res.json({
    code: 0,
    message: 'Gửi văn bản thành công',
    data: {
      lgsp_doc_id: `LGSP-${Date.now()}`,
      external_doc_id: `EXT-${Date.now()}`,
      document_code,
      abstract: abstract || null,
      recipient_unit_id,
      status: '01', // received
      submitted_at: new Date().toISOString(),
    },
  });
});

// POST /api/lgspedoc/update-status — update VB status
// Quan trọng: status='02' = "Từ chối tiếp nhận" (Phase 24 backlog feature)
app.post('/api/lgspedoc/update-status', (req: Request, res: Response) => {
  const { lgsp_doc_id, status, reason } = req.body || {};
  if (!lgsp_doc_id || !status) {
    res.status(400).json({ code: 400, message: 'lgsp_doc_id and status required' });
    return;
  }
  if (!['01', '02', '03', '04', '05', '06'].includes(status)) {
    res.status(400).json({ code: 400, message: 'status must be 01..06' });
    return;
  }
  res.json({
    code: 0,
    message: 'Cập nhật trạng thái thành công',
    data: {
      lgsp_doc_id,
      status,
      reason: reason || null,
      updated_at: new Date().toISOString(),
    },
  });
});

// GET /api/lgspedoc/get-documents — poll inbox
app.get('/api/lgspedoc/get-documents', (req: Request, res: Response) => {
  const { from_date, to_date, org_code } = req.query;
  // Trả 2 mock VB
  res.json({
    code: 0,
    data: {
      total: 2,
      documents: [
        {
          lgsp_doc_id: 'LGSP-INBOX-1',
          external_doc_id: 'EXT-INBOX-1',
          document_code: 'CV-MOCK-001',
          abstract: 'Mock VB liên thông 1 — đề nghị phối hợp triển khai',
          sender_unit: 'Mock UBND TP HCM',
          received_at: new Date(Date.now() - 3600000).toISOString(),
          status: '01',
        },
        {
          lgsp_doc_id: 'LGSP-INBOX-2',
          external_doc_id: 'EXT-INBOX-2',
          document_code: 'CV-MOCK-002',
          abstract: 'Mock VB liên thông 2 — báo cáo định kỳ tháng 4',
          sender_unit: 'Mock Sở Y tế Hà Nội',
          received_at: new Date(Date.now() - 7200000).toISOString(),
          status: '01',
        },
      ],
      from_date: from_date || null,
      to_date: to_date || null,
      org_code: org_code || null,
    },
  });
});

// GET /api/lgspedoc/get-document/:id
app.get('/api/lgspedoc/get-document/:id', (req: Request, res: Response) => {
  const { id } = req.params;
  res.json({
    code: 0,
    data: {
      lgsp_doc_id: id,
      document_code: `MOCK-${id}`,
      abstract: `Mock VB chi tiết ${id}`,
      file_base64: Buffer.from('MOCK PDF CONTENT').toString('base64'),
      file_name: 'mock-vb.pdf',
      file_size: 16,
      sender_unit: 'Mock sender',
      received_at: new Date().toISOString(),
      status: '01',
    },
  });
});

// GET /api/lgspedoc/cert
app.get('/api/lgspedoc/cert', (_req: Request, res: Response) => {
  res.json({
    code: 0,
    data: {
      cert_pem: '-----BEGIN CERTIFICATE-----\nMOCK_LGSP_CERT\n-----END CERTIFICATE-----',
      cert_serial: 'MOCK-LGSP-CERT-001',
      issued_at: new Date(Date.now() - 30 * 86400000).toISOString(),
      expires_at: new Date(Date.now() + 365 * 86400000).toISOString(),
    },
  });
});

app.all('*splat', (req: Request, res: Response) => {
  res.status(404).json({ error: `Not found: ${req.method} ${req.path}`, mock: SERVICE });
});

const server = app.listen(PORT, () => {
  console.log(`[mock-lgsp] listening on http://localhost:${PORT}`);
});

process.on('SIGTERM', () => {
  console.log('[mock-lgsp] SIGTERM');
  server.close(() => process.exit(0));
});
process.on('SIGINT', () => {
  console.log('[mock-lgsp] SIGINT');
  server.close(() => process.exit(0));
});

export {};
