---
plan: AUTOMATION_TEST_PLAN
source: docs/hdsd/20260505_Testcase_QLVB_V2.xlsx
testcase_count: 847
testcase_waves: a..i (9 file JSON)
priority_split: { High: 440, Medium: 311, Low: 96 }
category_split: { Positive: 280, Negative: 184, Boundary: 153, UI: 110, Permission: 88, E2E: 19, Concurrent: 13 }
target_milestone: v3.1 (đề xuất — chưa active)
estimated_effort: 11 working days (~2.5 sprint weeks)
generated: 2026-05-05
---

# Automation Test Plan — 847 TC × 31 nhóm

## Mục tiêu

Tự động hóa **≥ 95%** bộ 847 TC tại [`docs/hdsd/20260505_Testcase_QLVB_V2.xlsx`](docs/hdsd/20260505_Testcase_QLVB_V2.xlsx) để:

1. Chạy regression đầy đủ < 45 phút mỗi đêm.
2. Pass/Fail map ngược về cột `Trạng thái` trong Excel — bằng chứng cho KH/QA.
3. PR → CI gate: build + smoke 30 TC P-High trong < 8 phút.
4. Giảm rủi ro hồi quy khi merge fix vào prod đã có data KH.

Bộ TC đã đóng đủ gap (Boundary 153, Permission 88, E2E 19, Concurrent 13) — đủ chất liệu cho automation pyramid 3 tầng.

---

## 1. Framework — Playwright (chính) + Vitest (integration) + k6 (perf)

| Tầng | Framework | Lý do chọn |
|------|-----------|-----------|
| **E2E + UI + Permission + Concurrent** | **Playwright 1.50+** | (1) Multi-tab/multi-context native — bắt buộc cho 13 TC concurrent + 88 TC permission (4 role × parallel session). (2) File upload native với tên tiếng Việt UTF-8 — Cypress phải hack `cy.fixture` + `attachFile` plugin. (3) `page.route()` intercept HTTP — chặn được call SmartCA/LGSP ngay tại browser. (4) Trace viewer + screenshot/video mặc định — debug TC fail không cần config thêm. (5) Workers parallel native (`fullyParallel: true`) — cần cho 383 TC E2E chạy < 30 phút. (6) TS native, không cần Babel/wrapper. |
| **Integration API (280 Pos + 184 Neg)** | **Vitest 2.x + supertest** | 464/847 TC chỉ test API behavior (status code, response body, DB state) — không cần UI. Chạy supertest trực tiếp vào Express app → 5-10× nhanh hơn E2E. Vitest > Jest: native ESM (backend dùng ESM `.js` imports), watch mode tốt hơn, compatibility với TS strict. |
| **Performance (3 TC wave-i)** | **k6 0.50+** | TC-CONC-PERF-001/002/003 đo throughput/latency dưới tải — không phải chức năng. k6 chuyên trị, output Prometheus/InfluxDB nếu cần grafana. |
| **Helper unit (~50 test mới)** | **Vitest** | Cho `lib/department-subtree`, `lib/error-handler`, `lib/auth/jwt`, sign-helpers. Không có trong 847 TC nhưng cần để CI gate stable. |

**Tại sao KHÔNG Cypress (đã loại):**
- Multi-tab thật là deal-breaker: 13 TC concurrent (TC-CONC-RACE-001 đến 005) yêu cầu 2 user cùng edit 1 record — Cypress không hỗ trợ (chỉ multi-iframe). Playwright `browser.newContext()` giải quyết native.
- Upload file tiếng Việt: Multer middleware đã handle latin1→utf8 (CLAUDE.md pitfall #7) — Cypress test bằng `cy.attachFile` thường bypass MIME header chuẩn → false negative.
- Worker parallelism Cypress kém + license $$ với Cypress Cloud cho dashboard.

**Tại sao KHÔNG dùng k6 thay Playwright:**
k6 là load tool, không emulate trình duyệt full DOM. 110 TC UI category test visual hierarchy/Drawer behavior/AntD form validation — bắt buộc browser thật.

---

## 2. Test pyramid — phân loại 847 TC

| Tầng | Số TC | Tỷ lệ | Tốc độ chạy | Map từ wave |
|------|-------|-------|------------|-------------|
| **Unit (Vitest)** | ~50 helper tests | – | < 5s/all | Bổ sung — không có trong 847 |
| **Integration (Vitest + supertest)** | **464** | 55% | ~5 phút all | Wave a/b/c **Positive + Negative** không yêu cầu UI |
| **E2E (Playwright)** | **383** | 45% | ~25-30 phút all | Wave d/e/f Boundary form-level + Wave g Permission + Wave h E2E + Wave i Concurrent + 110 UI |

**Quy tắc phân loại 1 TC vào tầng nào:**

```
expected có chứa "hiển thị" / "Drawer" / "Modal" / "validation inline" / "skeleton"  → E2E
        hoặc "Boundary" cần form thật                                                 → E2E
expected chỉ check "API trả 4xx/5xx" / "Bản ghi lưu vào DB" / "JSON response..."      → Integration
preconditions yêu cầu "2 user" / "đa tab" / "phiên đăng nhập song song"               → E2E
category = "Permission" + chỉ test API authorization (403)                            → Integration
category = "Permission" + cần test redirect/UI hide menu                              → E2E
category = "E2E" hoặc "Concurrent"                                                    → E2E (luôn)
```

**Phân tách cụ thể:**

| Category | Total | Integration | E2E |
|----------|-------|-------------|-----|
| Positive | 280 | 220 | 60 |
| Negative | 184 | 150 | 34 |
| Boundary | 153 | 60 (API field validation) | 93 (Drawer form input) |
| UI | 110 | 0 | 110 |
| Permission | 88 | 30 (403 API) | 58 (menu/redirect) |
| E2E | 19 | 0 | 19 |
| Concurrent | 13 | 4 (race ở SP level) | 9 (multi-context) |
| **Tổng** | **847** | **464** | **383** |

---

## 3. Wave auto được vs giữ manual

**Tất cả 847 TC đều auto được**, nhưng có 4 TC cần hybrid (auto với mock + 1 lần/tuần manual với real provider):

| Wave | Số TC | Cấp tự động | Mock cần |
|------|-------|-------------|----------|
| **a** Auth + Admin (83) | 100% auto | Pure | Không |
| **b** VB đến/đi (181) | 100% auto | Pure | MinIO local container đủ |
| **c** HSCV + Dự thảo + Ký số DS (203) | 100% auto | Mock signing UI flow (placeholder) | SmartCA mock |
| **d** Boundary (126) | 100% auto | Pure | Không |
| **e** Danh mục (75) | 100% auto | Pure | Không |
| **f** Boundary VARCHAR + upload (97) | 100% auto | Pure | MinIO local |
| **g** Permission (50) | 100% auto | Pure | Không |
| **h** E2E (19) | **17 auto + 2 hybrid** | TC-E2E-EXT-001 (SmartCA real handshake) + TC-E2E-EXT-003 (LGSP real submit) → smoke staging weekly | SmartCA/LGSP/MinIO mock cho 17 còn lại |
| **i** Concurrent (13) | **10 auto + 3 hybrid (k6)** | 3 TC perf chạy k6 weekly trên staging với data thật | Không |

**Hybrid strategy** (4 TC weekly trên staging):
- TC-E2E-EXT-001 (SmartCA handshake real) — chạy CronCreate weekly với cert SmartCA staging KH cấp.
- TC-E2E-EXT-003 (LGSP real submit) — gửi 1 VB test có prefix `[AUTOTEST-WEEKLY]` đến đơn vị test partner.
- TC-CONC-PERF-001/002/003 — k6 ramp-up 100 vUser/30s trên staging, gate p95 < 800ms.

**Manual-only TC: 0** — bộ TC này được thiết kế cho automation từ đầu, không có TC nào yêu cầu thị giác con người (kiểu "kiểm tra trực quan UX có hợp lý không").

---

## 4. Test data — seed DB strategy + fixture 4 vai trò

### 4.1 Layered seed

```
Level 0: schema/000_schema_v3.0.sql              (idempotent — đã có)
Level 1: seed/001_required_data.sql              (admin + roles + rights — đã có)
Level 2: seed/002_demo_data.sql                  (312 demo records — đã có, ENV != prod)
Level 3: seed/003_test_fixtures.sql              (MỚI — fixture cho automation)
```

**File mới `database/seed/003_test_fixtures.sql`** (idempotent + ENV guard):

```sql
DO $$
BEGIN
  IF current_setting('app.environment', true) = 'prod' THEN
    RAISE EXCEPTION 'KHONG duoc chay test fixtures tren PROD';
  END IF;
END$$;

-- 4 user fixtures với password = 'Test@123' (bcrypt hash sẵn)
INSERT INTO public.staffs (id, username, password_hash, full_name, department_id, ...)
VALUES
  (9001, 'test_admin',   '$2a$10$...', 'TEST Quan tri',     1, ...),
  (9002, 'test_vanthu',  '$2a$10$...', 'TEST Van thu',      2, ...),
  (9003, 'test_lanhdao', '$2a$10$...', 'TEST Lanh dao',     2, ...),
  (9004, 'test_canbo',   '$2a$10$...', 'TEST Can bo',       2, ...),
  (9005, 'test_canbo_x', '$2a$10$...', 'TEST CB don vi khac', 3, ...)
ON CONFLICT (id) DO UPDATE SET password_hash = EXCLUDED.password_hash;

-- Gán role
INSERT INTO public.staff_roles VALUES (9001, 1) ON CONFLICT DO NOTHING; -- admin
INSERT INTO public.staff_roles VALUES (9002, 2) ON CONFLICT DO NOTHING; -- vanthu
INSERT INTO public.staff_roles VALUES (9003, 3) ON CONFLICT DO NOTHING; -- lanhdao
INSERT INTO public.staff_roles VALUES (9004, 4) ON CONFLICT DO NOTHING; -- canbo
INSERT INTO public.staff_roles VALUES (9005, 4) ON CONFLICT DO NOTHING;

-- VB đến fixture (5 trạng thái khác nhau cho TC test status flow)
INSERT INTO edoc.incoming_docs (id, doc_number, status, ...) VALUES
  (90001, 'TEST/VBD-NEW',   'new',          ...),
  (90002, 'TEST/VBD-DIS',   'distributing', ...),
  (90003, 'TEST/VBD-PROC',  'processing',   ...),
  (90004, 'TEST/VBD-DONE',  'completed',    ...),
  (90005, 'TEST/VBD-RJCT',  'rejected',     ...)
ON CONFLICT (id) DO NOTHING;

-- Tương tự VB đi (3), Dự thảo (2), HSCV (1 active + 1 closed), Notification (3)

-- Sequence reset (CLAUDE.md pitfall #12)
SELECT setval(pg_get_serial_sequence('public.staffs', 'id'),
       (SELECT MAX(id) FROM public.staffs));
```

### 4.2 Test isolation per worker

**Integration (Vitest + supertest):**
- Mỗi `describe` block bọc trong **transaction rollback**:

```ts
beforeEach(async () => { await db.query('BEGIN'); });
afterEach(async () => { await db.query('ROLLBACK'); });
```

→ DB reset về fixture state sau mỗi test, đa worker an toàn vì mỗi worker dùng connection riêng.

**E2E (Playwright):**
- Không thể TX rollback (test cross-process). Dùng **snapshot/restore**:

```bash
# globalSetup.ts — chạy 1 lần trước toàn bộ E2E suite
pg_dump qlvb_test > /tmp/qlvb_baseline.sql
# afterAll mỗi project — restore từ snapshot
psql qlvb_test < /tmp/qlvb_baseline.sql
```

- Hoặc nhanh hơn: dùng **template DB** (`CREATE DATABASE qlvb_test_w1 TEMPLATE qlvb_baseline`) — mỗi worker 1 DB riêng. Tốc độ: ~2s/restore.
- Workers per E2E project = 4 (config `playwright.config.ts`) — giảm còn 2 trên CI runner standard.

### 4.3 Fixture 4 vai trò — TS helper

`tests/fixtures/users.ts`:

```ts
export const TEST_USERS = {
  admin:   { username: 'test_admin',    password: 'Test@123', deptId: 1, role: 'Quản trị viên' },
  vanthu:  { username: 'test_vanthu',   password: 'Test@123', deptId: 2, role: 'Văn thư' },
  lanhdao: { username: 'test_lanhdao',  password: 'Test@123', deptId: 2, role: 'Lãnh đạo' },
  canbo:   { username: 'test_canbo',    password: 'Test@123', deptId: 2, role: 'Cán bộ' },
  canboX:  { username: 'test_canbo_x',  password: 'Test@123', deptId: 3, role: 'Cán bộ' }, // cho TC cross-unit isolation
} as const;
```

`tests/fixtures/auth.ts` — Playwright `storageState`:

```ts
// Login 1 lần, save cookie/localStorage → reuse cho mọi test
test.use({ storageState: 'tests/.auth/vanthu.json' });
```

→ Mỗi role có 1 file `.auth/<role>.json` được gen tại `globalSetup`. Login API call < 200ms × 5 role = 1s setup.

---

## 5. CI/CD — mở rộng `.github/workflows/build-check.yml`

### 5.1 Cấu trúc 3 workflow

| Workflow | Trigger | Thời gian | Block PR? |
|----------|---------|-----------|-----------|
| `build-check.yml` (đã có) | push/PR | ~3 phút | Yes |
| **`test-pr.yml`** (mới) | PR | ~8 phút | Yes |
| **`test-nightly.yml`** (mới) | cron `0 17 * * *` (00:00 ICT) | ~45 phút | No (kết quả → Slack/Excel) |

### 5.2 `test-pr.yml` — gate cho mọi PR

```yaml
name: Test PR
on:
  pull_request:
    branches: [main]

jobs:
  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_DB: qlvb_test
          POSTGRES_USER: qlvb_admin
          POSTGRES_PASSWORD: dev_password
        ports: [5432:5432]
        options: --health-cmd pg_isready --health-interval 5s
      redis:
        image: redis:7-alpine
        ports: [6379:6379]
      minio:
        image: minio/minio
        env: { MINIO_ROOT_USER: minio, MINIO_ROOT_PASSWORD: minio123 }
        ports: [9000:9000]
        options: >-
          --health-cmd "curl -f http://localhost:9000/minio/health/live"
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20', cache: 'npm' }
      - run: npm ci
        working-directory: e_office_app_new/backend
      - name: Apply schema + seed test fixtures
        run: |
          psql -h localhost -U qlvb_admin -d qlvb_test \
            -f e_office_app_new/database/init/01_create_schemas.sql
          psql -h localhost -U qlvb_admin -d qlvb_test \
            -f e_office_app_new/database/schema/000_schema_v3.0.sql
          psql -h localhost -U qlvb_admin -d qlvb_test \
            -f e_office_app_new/database/seed/001_required_data.sql
          psql -h localhost -U qlvb_admin -d qlvb_test \
            -f e_office_app_new/database/seed/003_test_fixtures.sql
      - name: Run integration tests
        run: npm run test:integration
        working-directory: e_office_app_new/backend

  e2e-smoke:
    runs-on: ubuntu-latest
    needs: integration-tests
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
      - run: npm ci && npx playwright install chromium --with-deps
      - name: Boot backend + frontend (background)
        run: |
          npm --prefix e_office_app_new/backend run build
          npm --prefix e_office_app_new/backend start &
          npm --prefix e_office_app_new/frontend run build
          npm --prefix e_office_app_new/frontend start &
          npx wait-on http://localhost:4000/health http://localhost:3000
      - name: Run smoke (P-High only, ~30 TC)
        run: npx playwright test --grep @smoke
      - uses: actions/upload-artifact@v4
        if: failure()
        with: { name: playwright-trace, path: playwright-report/ }
```

### 5.3 `test-nightly.yml` — full regression

- Chạy đầy đủ 847 TC: integration + e2e + perf k6.
- Output: file Excel `<date>_Testcase_QLVB_V2_results.xlsx` upload as artifact + commit vào branch `test-results/<YYYYMMDD>` để team tester so sánh tuần sau.
- Slack webhook `#qlvb-qa` báo Pass/Fail summary + link Excel.

### 5.4 Tag selection

Mỗi test có tag tương ứng để CI chọn:

```ts
test('TC-AUTH-001 đăng nhập thành công với admin @smoke @P-High', async ({ page }) => { ... });
test('TC-VBD-CRUD-045 boundary doc_number 200 chars @regression @P-Medium', ...);
```

PR gate dùng `--grep "@smoke"` (~30 TC). Nightly không filter → toàn bộ.

---

## 6. Báo cáo Pass/Fail → cột "Trạng thái" trong Excel

### 6.1 Mỗi test viết với TC-ID là tag

Quy ước **bắt buộc**: title test = `${TC_ID} ${original_title}` để parser dùng regex `^(TC-[A-Z0-9-]+)` extract id.

```ts
test('TC-AUTH-001 Đăng nhập thành công với tài khoản admin hợp lệ @smoke', async ({ page }) => {
  // ...
});
```

### 6.2 Tool sync ngược về Excel

`tools/test-report/sync-to-excel.js` — dùng `exceljs` (đã có trong `package.json` backend + frontend):

```js
// Input:
//   tools/test-report/playwright-results.json  (Playwright reporter "json")
//   tools/test-report/vitest-results.json      (Vitest reporter "json")
//   docs/hdsd/20260505_Testcase_QLVB_V2.xlsx  (template gốc)
//
// Output:
//   docs/hdsd/<YYYYMMDD>_Testcase_QLVB_V2_results.xlsx
//
// Mapping:
//   Cell row tương ứng TC-ID → cột "Trạng thái" = Pass/Fail/Skip
//                              cột "Run date"   = ISO date
//                              cột "Duration"   = ms
//                              cột "Error msg"  = nếu fail, lấy 200 chars đầu
//                              cột "Trace link" = URL artifact CI nếu fail (E2E)

const ExcelJS = require('exceljs');
const fs = require('fs');
const wb = new ExcelJS.Workbook();
await wb.xlsx.readFile('docs/hdsd/20260505_Testcase_QLVB_V2.xlsx');
const sheet = wb.getWorksheet(1);

const playwrightResults = JSON.parse(fs.readFileSync('tools/test-report/playwright-results.json'));
const vitestResults     = JSON.parse(fs.readFileSync('tools/test-report/vitest-results.json'));

const tcMap = new Map();
[...flattenPwResults(playwrightResults), ...flattenVitestResults(vitestResults)]
  .forEach(r => {
    const m = r.title.match(/^(TC-[A-Z0-9-]+)/);
    if (m) tcMap.set(m[1], r);
  });

sheet.eachRow((row, idx) => {
  if (idx < 2) return; // skip header
  const tcId = row.getCell('A').value;
  const result = tcMap.get(tcId);
  if (!result) {
    row.getCell('Trạng thái').value = 'Not run';
    return;
  }
  row.getCell('Trạng thái').value = result.status; // Pass/Fail/Skip
  row.getCell('Run date').value   = new Date().toISOString().slice(0,10);
  row.getCell('Duration').value   = `${result.duration}ms`;
  if (result.status === 'Fail') {
    row.getCell('Error msg').value  = (result.error || '').slice(0, 200);
    row.getCell('Trace link').value = result.traceUrl || '';
  }
});

await wb.xlsx.writeFile(`docs/hdsd/${date}_Testcase_QLVB_V2_results.xlsx`);
```

### 6.3 Coverage gap detection

Cuối mỗi nightly run, parser cũng output **coverage report**:

```
Total TC trong Excel: 847
Auto coverage:        823 (97.2%)
Not run (no automation): 24
  - TC-CONC-PERF-001 → marked HYBRID (k6 weekly)
  - TC-E2E-EXT-001 → marked HYBRID (SmartCA real weekly)
  ...
Coverage drop alert: nếu < 95% → Slack alert đỏ
```

---

## 7. Mock strategy

### 7.1 SmartCA + MySign (signing providers)

**Approach:** Mock server riêng tại `tools/mocks/signing-mock-server.ts` (Express, port 8181 SmartCA / 8182 MySign).

```ts
// Endpoints emulated:
// POST /smartca/auth          → trả tokenAuth giả + redirectUrl mock
// POST /smartca/sign          → trả signedXml giả nếu cert hợp lệ
// POST /smartca/verify        → trả status: 'valid' | 'invalid' theo body
// GET  /smartca/cert/:userId  → trả cert PEM dummy

// Chế độ:
//  - Default: success path (cho TC Positive)
//  - Header X-Mock-Scenario: timeout         → trả 504 sau 30s
//  - Header X-Mock-Scenario: invalid_cert    → trả 400 'Cert expired'
//  - Header X-Mock-Scenario: provider_down   → trả 503
```

**Backend dev/test config:** `.env.test`

```bash
SMARTCA_BASE_URL=http://localhost:8181
MYSIGN_BASE_URL=http://localhost:8182
SIGNING_MOCK_MODE=true   # Bật chế độ skip cert validation
```

**Boot sequence trong CI:**
```yaml
- name: Start mock servers
  run: node tools/mocks/signing-mock-server.js &
- name: Wait for mocks
  run: npx wait-on http://localhost:8181/health http://localhost:8182/health
```

**Test với scenario header:**
```ts
test('TC-SC-EXT-002 ký số fail khi provider trả error', async ({ page, request }) => {
  await request.post('/api/ky-so/start', {
    headers: { 'X-Mock-Scenario': 'invalid_cert' }
  });
  // Assert: UI hiển thị "Chứng thư số không hợp lệ" + flow rollback
});
```

### 7.2 LGSP (liên thông SOAP)

LGSP gateway = SOAP + dùng cho VB đi gửi sang đơn vị khác. **2 cấp mock:**

- **Integration tests:** dùng `nock` HTTP interceptor → mock SOAP response trong process Node.

```ts
nock('https://lgsp-test.gov.vn')
  .post('/api/document/send')
  .reply(200, '<soap:Envelope>...<status>SUCCESS</status>...</soap:Envelope>');
```

- **E2E tests:** mock server riêng `tools/mocks/lgsp-mock-server.ts` (Express, port 8183) — emulate SOAP envelope. Tests TC-E2E-EXT-003/004 chạy với mock này.

### 7.3 MinIO offline (TC-E2E-EXT-004)

Test "MinIO offline → fallback hợp lý":

```ts
test('TC-E2E-EXT-004 upload file khi MinIO offline', async ({ page }) => {
  // Method: stop minio container giữa chừng
  await execAsync('docker stop qlvb_minio_test');
  
  await page.goto('/van-ban-den/them-moi');
  await page.locator('input[type=file]').setInputFiles('fixtures/sample.pdf');
  await page.click('text=Lưu');
  
  // Assert: backend trả 503 "Dịch vụ lưu trữ tạm thời không khả dụng"
  // và UI hiển thị thông báo + giữ form data (không mất input)
  await expect(page.locator('.ant-message-error')).toContainText('Dịch vụ lưu trữ');
  await expect(page.locator('input[name=doc_number]')).toHaveValue('VBD/123/2026');
  
  // Cleanup
  await execAsync('docker start qlvb_minio_test');
});
```

### 7.4 Mock fidelity matrix

| External | Mock fidelity | Lý do |
|----------|--------------|-------|
| SmartCA  | High (full handshake state machine) | 38 TC ký số dependency |
| MySign   | Medium (chỉ success + 2 error) | Backup provider — ít TC |
| LGSP     | Medium (success + 3 error code) | 5 TC liên thông |
| MinIO    | None (dùng container thật, stop để test offline) | Local minio < 50MB, dễ run |
| MongoDB audit | None (dùng container thật) | Audit verification cần query thật |
| Redis    | None (dùng container thật) | Session/cache cần thật |

**Provider record/replay (P-D phase, optional):** lần đầu chạy với staging real → save response JSON → replay nếu cần increase fidelity của SmartCA mock.

---

## 8. Phân pha triển khai — 3 phase × 11 working days

### Phase A — Foundation (3 ngày)

**Mục tiêu:** Setup infra + smoke 30 TC chạy được trên CI.

| Wave | Tasks | Files thay đổi/tạo mới |
|------|-------|----------------------|
| A.1 | Setup Vitest + Playwright + supertest | `e_office_app_new/backend/vitest.config.ts`, `e_office_app_new/backend/package.json` (deps + scripts), `playwright.config.ts` (root) |
| A.2 | Test DB strategy + 4 user fixture | `database/seed/003_test_fixtures.sql`, `tests/fixtures/users.ts`, `tests/globalSetup.ts` |
| A.3 | Mock servers (SmartCA + LGSP) | `tools/mocks/signing-mock-server.ts`, `tools/mocks/lgsp-mock-server.ts`, `tools/mocks/package.json` |
| A.4 | Smoke 30 TC P-High | `tests/smoke/auth.spec.ts` (5 TC), `tests/smoke/incoming-doc.spec.ts` (8), `tests/smoke/outgoing-doc.spec.ts` (5), `tests/smoke/hscv.spec.ts` (5), `tests/smoke/admin.spec.ts` (4), `tests/smoke/dashboard.spec.ts` (3) |
| A.5 | Excel report parser MVP | `tools/test-report/sync-to-excel.js`, `tools/test-report/package.json` |
| A.6 | CI test-pr.yml | `.github/workflows/test-pr.yml` |

**Acceptance:**
- `npm run test:smoke` chạy local PASS 30/30 trong < 5 phút.
- Mở 1 PR test → CI gate `Test PR / e2e-smoke` đỏ nếu fail.
- File `<date>_results.xlsx` được generate, có 30 dòng `Pass`.

### Phase B — Regression backbone (5 ngày)

**Mục tiêu:** Cover 700+/847 TC, nightly chạy đủ.

| Wave | Tasks | Số TC |
|------|-------|-------|
| B.1 | Integration: Wave a Pos+Neg (auth, admin) | 83 |
| B.2 | Integration: Wave b Pos+Neg (VB đến/đi) | 181 |
| B.3 | Integration: Wave c Pos+Neg (HSCV + dự thảo + ký số DS) | 203 |
| B.4 | E2E: Wave d Boundary (Drawer form-level) | 126 |
| B.5 | E2E: Wave e Danh mục (Drawer CRUD) | 75 |
| B.6 | E2E: Wave f Boundary VARCHAR + upload | 97 |
| B.7 | E2E: Wave g Permission (5 role × cross-unit) | 50 |
| B.8 | CI test-nightly.yml + Excel report full sync | – |

**Acceptance:**
- Nightly chạy 815/847 TC trong < 40 phút.
- Excel results có cột `Trạng thái` cập nhật đầy đủ 815 dòng.
- Coverage report: 96.2% auto, 32 TC còn lại = 19 E2E + 13 Concurrent (sang Phase C).

### Phase C — E2E + Concurrent + Hybrid (3 ngày)

**Mục tiêu:** Cover 100% (trừ 4 hybrid weekly), publish QA dashboard.

| Wave | Tasks | Số TC |
|------|-------|-------|
| C.1 | E2E: Wave h flows (mock SmartCA/LGSP/MinIO offline) | 17/19 (2 hybrid weekly) |
| C.2 | E2E: Wave i Concurrent (multi-context Playwright) | 10/13 |
| C.3 | k6 perf 3 TC (TC-CONC-PERF-001/002/003) | 3 (k6 weekly) |
| C.4 | Hybrid weekly job: SmartCA/LGSP real + k6 perf | `.github/workflows/test-weekly-hybrid.yml` |
| C.5 | Update Wave a-g với 110 TC UI category (visual snapshot) | 110 |
| C.6 | Onboarding doc cho QA team | `docs/automation-test/README.md` |

**Acceptance:**
- Full suite: 843/847 auto + 4 hybrid weekly = **100% coverage**.
- Tester có thể run `npm run test:tc TC-VBD-CRUD-045` để chạy 1 TC riêng lẻ.
- Slack `#qlvb-qa` nhận summary nightly hằng ngày.

---

## 9. Acceptance criteria toàn dự án

- [ ] **847 TC mapped** vào file test thực thi (1 TC = 1 `test()` block, không gộp).
- [ ] **Nightly suite < 45 phút** trên CI runner ubuntu-latest 4-core.
- [ ] **PR smoke < 8 phút** từ push → kết quả.
- [ ] **Coverage ≥ 95%** (đo bằng tỉ lệ TC có status ≠ "Not run" trong Excel report).
- [ ] **Excel results có cột "Trạng thái"** cập nhật đầy đủ + commit về `test-results/<date>` branch hằng đêm.
- [ ] **0 flaky test rate < 1%** sau 7 lần chạy nightly liên tiếp (test fail không reproducible bị quarantine).
- [ ] **Mock servers self-contained** — clone repo, `npm run test:smoke` chạy được không cần kết nối SmartCA/LGSP thật.
- [ ] **Onboarding doc** ≤ 30 phút để QA member mới chạy được test đầu tiên.

---

## 10. Risks + mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Test DB reset chậm (847 TC × 200ms restore = 3 phút) | High | Med | Dùng template DB + per-worker isolation (mỗi worker 1 DB, restore 1 lần đầu) |
| Tiếng Việt có dấu trong locator/assertion bị lỗi UTF-8 trên Windows runner | Med | High | Pin runner = ubuntu-latest, KHÔNG dùng windows-latest cho test job. Source files set BOM cho UTF-8 |
| SmartCA mock drift với real provider | Low | Med | Phase D quarter (sau 1 tháng): chạy lại real handshake → diff với mock response → cập nhật mock fixture |
| Playwright auto-wait timeout với Drawer animation AntD 6 | Med | Low | Set `actionTimeout: 10000` trong playwright.config + wait `data-testid` thay vì text |
| Concurrent TC race trên CI shared runner | Low | High | Concurrent test chạy serial (`workers: 1`), perf test chỉ chạy weekly trên dedicated staging |
| Flaky do upload file (multer + tiếng Việt) | Med | Med | Test fixtures upload chỉ ASCII + 1 fixture có dấu để pin TC-UPLOAD-VN-001 |

---

## 11. Out of scope (v3.1, có thể v3.2)

- **Visual regression** (pixel diff): chỉ làm Phase D nếu KH yêu cầu. Hiện tại 110 UI test = functional check, không pixel.
- **Accessibility (a11y)**: bộ TC không cover. Phase D có thể thêm `axe-core` integration.
- **Mobile responsive E2E**: chỉ smoke 1 TC `viewport: { width: 375, height: 667 }`. Full mobile suite = v3.2.
- **Internationalization** (i18n): hệ thống chỉ tiếng Việt → không có TC EN.

---

## 12. Routing

**Plan này là planning research — chưa thi hành.** User phê duyệt → 2 hướng:

1. **Apply như guideline** (giữ tại `.planning/AUTOMATION_TEST_PLAN.md`, nhân sự tự follow):

   ```
   /gsd-quick "implement Phase A automation foundation theo .planning/AUTOMATION_TEST_PLAN.md section 8"
   ```

2. **Convert thành milestone v3.1 chính thức** (recommended cho dự án 11 ngày):

   ```
   /gsd-new-milestone v3.1
   # Discussion với scope: automation test 847 TC theo AUTOMATION_TEST_PLAN.md
   /gsd-add-phase  # Phase A Foundation
   /gsd-add-phase  # Phase B Regression backbone  
   /gsd-add-phase  # Phase C E2E + Concurrent + Hybrid
   /gsd-plan-phase A
   /gsd-execute-phase A
   ```

**Khuyến nghị:** Đi hướng (2). 11 ngày là milestone-scale, cần atomic commit + verification + summary chuẩn GSD để không drift giữa plan và thực tế.
