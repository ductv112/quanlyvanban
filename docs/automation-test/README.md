# QLVB Test Tooling — Claude Usage Notes

> **Mục đích:** Tooling Claude (AI tester) dùng để execute 847 TC ([`docs/hdsd/20260505_Testcase_QLVB_V2.xlsx`](../hdsd/20260505_Testcase_QLVB_V2.xlsx)) và fill kết quả ngược về Excel.
>
> **KHÔNG phải** automation framework cho team QA — không có CI, không có cron nightly, không có Slack alert. Chỉ utility cho Claude execute manual + report.

---

## 1. Stack có sẵn (đã build trong Phase 21)

| Component | Path | Dùng để |
|---|---|---|
| Test DB fixture | `database/seed/003_test_fixtures.sql` | Seed 6 user + 16 VB data consistent cho mỗi batch test |
| Test DB reset | `backend/tools/test-db-reset.ts` | Drop + recreate `qlvb_test` + apply schema + seed (chỉ qlvb_test, KHÔNG TOUCH qlvb_dev) |
| Mock servers | `tools/mocks/{smartca,mysign,lgsp}-mock.ts` | Test ký số/liên thông không cần cert thật |
| Excel sync | `tools/test-report/sync-to-excel.ts` | Fill cột "Trạng thái" trong Excel template từ JSON results |
| Playwright + 30 smoke | `tests/smoke/*.spec.ts` | Sanity check sau mỗi fix bug (tùy chọn) |

---

## 2. Setup nhanh (chỉ 1 lần)

### Pre-requisites
- Node 20+, Docker Desktop, Git Bash
- 4 container UP: `docker compose -f e_office_app_new/docker-compose.yml up -d`

### Install deps
```bash
cd e_office_app_new/backend && npm install
cd ../../tools/mocks && npm install
cd ../test-report && npm install
```

### Setup .env.test
```powershell
cd e_office_app_new/backend
Copy-Item .env.test.example .env.test
# Template đã pre-set PG_DOCKER_CONTAINER=qlvb_postgres cho Windows
```

---

## 3. Workflow Claude execute 1 batch test

### 3.1. Reset state (chỉ qlvb_test, dev DB không touch)
```bash
cd e_office_app_new/backend
npm run test:db:reset    # ~10s
```

### 3.2. Boot backend trỏ test DB
```bash
NODE_ENV=test npm run dev    # port 4000, dùng .env.test
```

### 3.3. Boot mocks (chỉ khi batch có TC ký số/LGSP)
```bash
cd tools/mocks
npx tsx start.ts    # 8181/8182/8183
```

### 3.4. Execute TC bằng API + DB query
- API: `curl -X POST http://localhost:4000/api/...` với token từ login
- DB: `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -c "..."`
- KHÔNG screenshot trừ khi cần evidence bug critical

### 3.5. Fill kết quả Excel
```bash
cd tools/test-report
npx tsx sync-to-excel.ts    # Output: docs/hdsd/<YYYYMMDD>_results.xlsx
```

---

## 4. Test accounts (mọi user password = `Test@123`)

| Username | Vai trò | Đơn vị | Dùng để test |
|---|---|---|---|
| `test_admin` | Quản trị hệ thống | UBND (id=1) | Cấu hình hệ thống, danh mục, người dùng |
| `test_vanthu` | Văn thư | Sở Nội vụ (id=2) | Vào sổ VB đến/đi, phân loại |
| `test_lanhdao` | Lãnh đạo | Sở Nội vụ (id=2) | Phê duyệt, ký số, giao việc |
| `test_canbo` | Cán bộ | Sở Nội vụ (id=2) | Xử lý VB được giao, dự thảo |
| `test_canbo_x` | Cán bộ | Sở Tài chính (id=3) | Test cross-unit isolation |
| `test_locked` | (locked) | Sở Nội vụ | Test login fail (HTTP 403) |

---

## 5. Mock scenarios (header `X-Mock-Scenario`)

| Scenario | SmartCA/MySign | LGSP |
|---|---|---|
| (default) | success | success |
| `timeout` | 504 sau 30s | timeout |
| `invalid_cert` | 400 "Chứng thư số không hợp lệ" | n/a |
| `provider_down` | 503 "Dịch vụ ký số tạm ngưng" | 503 |

Endpoints:
- SmartCA: `http://localhost:8181/smartca/{auth,sign,verify}`
- MySign: `http://localhost:8182/mysign/{auth,sign,verify}`
- LGSP: `http://localhost:8183/api/lgspedoc/{login,send-document,update-status}`

---

## 6. Safety guarantees

- `test-db-reset.ts` có guard `if PG_DATABASE !== 'qlvb_test' throw` — KHÔNG BAO GIỜ touch `qlvb_dev`
- Seed `003_test_fixtures.sql` có guard `app.environment != 'prod'`
- Backend dev `npm run dev` mặc định dùng `.env` (qlvb_dev) — chỉ khi set `NODE_ENV=test` hoặc dùng `.env.test` mới trỏ qlvb_test

---

## 7. Troubleshooting

| Vấn đề | Fix |
|---|---|
| `spawnSync psql ENOENT` (Windows) | `.env.test` đã pre-set `PG_DOCKER_CONTAINER=qlvb_postgres` |
| Backend không respond port 4000 | Set `NODE_ENV=test` trước `npm run dev` để load `.env.test` |
| Login 401 `test_admin` | `npm run test:db:reset` để seed lại fixture |
| Mock server stop | `cd tools/mocks && npx tsx start.ts` lại |
| Tiếng Việt corrupt PowerShell | `chcp 65001` trước, hoặc PowerShell 7 |

---

*Last updated: 2026-05-06 — re-scope từ "team QA framework" → "Claude tester utility".*
