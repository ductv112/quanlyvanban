# QLVB Mock Servers

3 mock server cho automation testing — emulate SmartCA / MySign / LGSP API contracts đủ để smoke + regression test pass mà không cần real provider.

Standalone npm package — KHÔNG depend vào backend hoặc DB.

## Quick start

```bash
cd tools/mocks
npm install
npm start
# 3 mock chạy trên port 8181 (SmartCA), 8182 (MySign), 8183 (LGSP)
```

## Endpoints

### SmartCA (8181)
- `GET  /health`
- `POST /smartca/auth` — initiate signing session, returns `tran_id` + `auth_url`
- `POST /smartca/sign` — perform signing, returns `signature` + `cert_serial`
- `POST /smartca/verify` — verify signature, returns `valid: true`
- `GET  /smartca/cert/:userId` — fetch user cert (PEM)
- `GET  /smartca/mock-confirm` — mock confirm page (HTML)

### MySign (8182)
- `GET  /health`
- `POST /mysign/auth`, `/mysign/sign`, `/mysign/verify`
- `GET  /mysign/cert/:userId`
- `GET  /mysign/mock-confirm`

### LGSP (8183)
- `GET  /health`
- `POST /api/lgspedoc/login` + `/refresh-token` (OAuth2-style)
- `POST /api/lgspedoc/send-document` — submit VB đi
- `POST /api/lgspedoc/update-status` — update VB status (01..06)
- `GET  /api/lgspedoc/get-documents` — poll inbox
- `GET  /api/lgspedoc/get-document/:id` — detail with file_base64
- `GET  /api/lgspedoc/cert`

## Scenarios (X-Mock-Scenario header)

| Scenario           | HTTP Status      | Use case                        |
|--------------------|------------------|---------------------------------|
| (none)             | 200              | Smoke + happy path              |
| `timeout`          | 504 (after 5s)   | Test client timeout handling    |
| `invalid_cert`     | 400              | Test cert validation error UI   |
| `provider_down`    | 503              | Test fallback behavior          |
| `auth_fail`        | 401 (LGSP only)  | Test re-login flow              |
| `invalid_payload`  | 400 (LGSP only)  | Test request validation         |
| `rate_limit`       | 429 (SmartCA)    | Test backoff                    |
| `slow`             | 200 (after 3s)   | Test loading state              |

Example:
```bash
curl -X POST http://localhost:8181/smartca/sign \
  -H "X-Mock-Scenario: invalid_cert" \
  -H "Content-Type: application/json" \
  -d '{"tran_id":"T1","payload":"x"}'
# → 400 {"error":"Chứng thư số không hợp lệ hoặc đã hết hạn",...}
```

## LGSP status codes (per LGSP-LANGSON-API-GUIDE)

| Code | Meaning              |
|------|----------------------|
| 01   | received             |
| 02   | rejected (Từ chối)   |
| 03   | processing           |
| 04   | completed            |
| 05   | forwarded            |
| 06   | error                |

Phase 24 backlog (LGSP "Từ chối tiếp nhận" status='02') đã có endpoint mock sẵn.

## Stop / cleanup

```bash
npm run stop          # tear down 3 servers via port detection (taskkill on Windows, kill on Unix)
```

## Individual server boot

```bash
npm run smartca       # boot only SmartCA (port 8181)
npm run mysign        # boot only MySign (port 8182)
npm run lgsp          # boot only LGSP (port 8183)
```

## CI integration

CI workflow (`.github/workflows/test-pr.yml` — plan 21-06):
```yaml
- name: Boot mocks
  run: |
    cd tools/mocks
    npm ci
    npx tsx start.ts > /tmp/mocks.log 2>&1 &
    sleep 3
- name: Verify health
  run: |
    curl -fsS http://localhost:8181/health
    curl -fsS http://localhost:8182/health
    curl -fsS http://localhost:8183/health
- name: Stop mocks (cleanup)
  if: always()
  run: cd tools/mocks && npx tsx stop.ts
```

## Backend wiring

Set in `.env.test`:
```
SMARTCA_BASE_URL=http://localhost:8181
MYSIGN_BASE_URL=http://localhost:8182
LGSP_ENDPOINT=http://localhost:8183
SIGNING_MOCK_MODE=true
MOCK_EXTERNAL=true
```

Backend `src/services/lgsp.service.ts` đọc `process.env.LGSP_ENDPOINT` → tự động trỏ sang mock khi chạy test.

## Architecture

- **Tech**: Express 5 + cors, ESM TypeScript, executed via tsx
- **Storage**: In-memory only (Map) — không cần persistent storage
- **Logging**: prefix `[mock-smartca]`, `[mock-mysign]`, `[mock-lgsp]` cho dễ grep
- **Isolation**: Standalone npm package (own `package.json` + `node_modules`) — không leak deps vào backend
- **Boot**: < 3s cho 3 server (target CI acceptable)
- **Shutdown**: SIGTERM/SIGINT graceful close + cross-platform tear down (taskkill /T trên Windows kill toàn bộ child tree npx → tsx → node)
