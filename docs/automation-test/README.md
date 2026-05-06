# QLVB Automation Test — Onboarding Guide

> **Mục tiêu:** QA mới (chưa biết Playwright) đọc tài liệu này ≤ 30 phút là chạy được smoke test đầu tiên xanh trên local.

**Plan:** 21-05 RPT-07
**Source plan tổng:** [.planning/AUTOMATION_TEST_PLAN.md](../../.planning/AUTOMATION_TEST_PLAN.md)

---

## 0. Tổng quan stack

| Tier | Framework | Số TC | Run time | Khi nào chạy |
|------|-----------|-------|----------|---------------|
| **Unit** | Vitest 2.1 | ~50 helper | < 5s | Mỗi PR |
| **Integration** | Vitest + supertest + nock | ~464 (target) | ~5 phút | Mỗi PR |
| **E2E** | Playwright 1.59 | ~383 (target) | ~30 phút | Nightly |
| **Smoke (PR gate)** | Playwright `@smoke` filter | **30** (Phase 21) | **< 5 phút** | Mỗi PR |

**Test DB:** `qlvb_test` (tách hoàn toàn `qlvb_dev` — không bao giờ ghi đè data dev).
**Mock servers:** SmartCA (8181), MySign (8182), LGSP (8183) — boot bằng `tools/mocks/`.
**Browser:** Chromium-only (Phase 21). Firefox/WebKit deferred Phase 22.

---

## 1. Cài đặt môi trường (~10 phút lần đầu)

### 1.1. Pre-requisites

- Node.js 20+ ([download](https://nodejs.org/))
- Docker Desktop ([download](https://www.docker.com/products/docker-desktop/))
- Git
- 8GB RAM (Chromium + Postgres + Next.js đồng thời)

### 1.2. Clone repo + install deps

```powershell
git clone <repo-url> qlvb
cd qlvb

# 1) Install Playwright + Chromium browser (~5 phút lần đầu, ~170MB)
npm install
npx playwright install chromium

# 2) Install backend test deps (Vitest + supertest + nock)
cd e_office_app_new/backend
$env:NODE_ENV='development'; npm install; Remove-Item Env:NODE_ENV
cd ../..

# 3) Install mock server deps (SmartCA/MySign/LGSP)
cd tools/mocks
npm install
cd ../..

# 4) Install Excel report tool deps
cd tools/test-report
npm install
cd ../..
```

### 1.3. Setup .env.test

Template `.env.test.example` nằm trong `e_office_app_new/backend/`. Copy thành `.env.test`:

**Windows (PowerShell):**
```powershell
cd e_office_app_new/backend
Copy-Item .env.test.example .env.test
cd ../..
```

**Linux/macOS:**
```bash
cd e_office_app_new/backend
cp .env.test.example .env.test
cd ../..
```

**File đã có sẵn:** qlvb_test DB credential + mock URLs (8181/8182/8183) + JWT secret + signing key.

> **Windows + Docker Desktop dev — IMPORTANT:**
> Template đã pre-set `PG_DOCKER_CONTAINER=qlvb_postgres`. **KHÔNG xóa dòng này** trên Windows.
> Phase 21-07 đã thêm auto-detect Docker trên Windows trong `test-db-reset.ts`, nhưng explicit set qua env nhanh hơn (~50ms) và tránh phụ thuộc `docker ps` trong PATH.
> CI ubuntu-latest dùng psql native — comment hoặc xóa dòng này nếu chạy CI local mà KHÔNG có Docker container `qlvb_postgres`.

### 1.4. Boot Docker services

```powershell
cd e_office_app_new
docker compose up -d
cd ..

# Verify (4 container running):
docker ps
# qlvb_postgres / qlvb_mongo / qlvb_redis / qlvb_minio
```

---

## 2. Setup test DB (~30 giây)

```powershell
cd e_office_app_new/backend
$env:PG_DATABASE='qlvb_test'
npm run test:db:reset
# Output: "[test-db-reset] DONE in <Xms" (X < 30000)
```

**qlvb_test fixtures (sau reset):**

| Loại | Số lượng | Chi tiết |
|------|----------|----------|
| User | 6 | admin/vanthu/lanhdao/canbo/canbo_x/locked |
| VB đến | 5 | 5 trạng thái: new/distributed/processing/completed/rejected |
| VB đi | 3 | released/sent/cross_unit |
| Dự thảo | 2 | pending/approved |
| HSCV | 2 | active/closed |
| Thông báo | 3 | id 90001-90003 |

### Test accounts (mọi user password = `Test@123`)

| Username | Role | Đơn vị | Dùng cho test |
|----------|------|--------|----------------|
| `test_admin` | Quản trị hệ thống | UBND | Admin pages /quan-tri/* |
| `test_vanthu` | Văn thư | Sở Nội vụ | VB đến/đi vào sổ + giao việc |
| `test_lanhdao` | Ban Lãnh đạo | Sở Nội vụ | Phê duyệt + giao xử lý |
| `test_canbo` | Cán bộ | Sở Nội vụ | Xử lý văn bản + HSCV |
| `test_canbo_x` | Cán bộ | Sở Tài chính | Cross-unit test (RBAC) |
| `test_locked` | Cán bộ (khoá) | Sở Nội vụ | Negative login test |

---

## 3. Boot backend + frontend + mocks (~10 giây)

Cần 4 terminal song song. Dùng PowerShell tab hoặc Windows Terminal split panes.

**Terminal 1 — Backend (port 4000):**
```powershell
cd e_office_app_new/backend
$env:PG_DATABASE='qlvb_test'
npm run dev
# Verify: http://localhost:4000/api/health -> {"status":"ok"}
```

**Terminal 2 — Frontend (port 3000):**
```powershell
cd e_office_app_new/frontend
npm run dev
# Verify: http://localhost:3000 -> redirect /login (page render OK)
```

**Terminal 3 — Mock servers (8181/8182/8183):**
```powershell
cd tools/mocks
npm start
# Verify: http://localhost:8181/health, /8182, /8183 -> 200
```

**Terminal 4 — Test runner:** Để trống, sẽ chạy commands ở bước 4.

---

## 4. Chạy smoke test đầu tiên (~5 phút)

```powershell
# Từ root dir
npm run test:smoke
# Tương đương: npx playwright test --grep @smoke
```

**Output expected:**
```
Running 30 tests using 4 workers
  ✓ TC-AUTH-001 Đăng nhập thành công với tài khoản admin (1.5s)
  ✓ TC-AUTH-002 Đăng nhập thành công với tài khoản văn thư (1.4s)
  ✓ TC-AUTH-003 Đăng nhập thất bại — sai mật khẩu (1.2s)
  ...
  ✓ TC-DASH-003 Sidebar menu hiển thị đầy đủ (1.0s)

  30 passed (4.2m)
```

**Mục tiêu acceptance (AUTO-11):**
- 30/30 PASS hoặc PASS + 1-2 SKIP với reason rõ ràng
- Tổng thời gian < 5 phút (4 worker parallel)
- Trace artifact lưu vào `tests/results/playwright-report/` khi fail

---

## 5. Sync results về Excel template

```powershell
# Sau khi smoke chạy xong (tests/results/playwright-results.json đã có)
cd tools/test-report
npm run sync
# (alias: npx tsx sync-to-excel.ts)
```

**Output:**
- File: `docs/hdsd/<YYYYMMDD>_Testcase_QLVB_V2_results.xlsx` (~100KB)
- Stdout: Coverage report
  ```
  ============================================================
  Total TC trong Excel: 847
  Mapped (auto coverage): 30 (3.5%)
    Pass: 30
    Fail: 0
    Skip: 0
  Not run: 817
  ============================================================
  ```

**5 cột mới trong Excel** (sau cột cuối cùng template):
- **Trạng thái** — Pass / Fail / Skip / Not run (tô màu cell)
- **Run date** — yyyy-mm-dd
- **Duration** — `1500ms` hoặc `2.3s`
- **Error msg** — 200 ký tự đầu của lỗi (chỉ Fail)
- **Trace link** — đường dẫn artifact (chỉ Fail E2E)

Mở file output bằng Excel để gửi PM/khách hàng.

---

## 6. Khi test fail — debug

```powershell
# 1) Open trace viewer (HTML report)
npx playwright show-report tests/results/playwright-report
# Browser tab mở -> click test fail -> tab "Trace" -> time-travel debugging

# 2) Run lại 1 test cụ thể
npx playwright test tests/smoke/auth.spec.ts --grep "TC-AUTH-001"

# 3) Run với headed browser (xem trực tiếp)
npx playwright test --headed --grep @smoke

# 4) Run với UI mode (interactive — best DX để debug)
npx playwright test --ui

# 5) Print logs đầy đủ (verbose)
npx playwright test --grep @smoke --reporter=list
```

---

## 7. Convention quan trọng

### 7.1. Naming test

**BẮT BUỘC:** title bắt đầu bằng `TC-XXX-NNN ` để Excel parser map ngược về template.

```typescript
// ✅ ĐÚNG
test('TC-AUTH-001 Đăng nhập thành công với tài khoản admin @smoke @P-High', ...);

// ❌ SAI — không có TC-ID prefix
test('Đăng nhập thành công với tài khoản admin', ...);

// ❌ SAI — TC-ID viết thường
test('tc-auth-001 Login OK', ...);
```

**Regex parser:** `^(TC-[A-Z0-9-]+)` — uppercase, dash-separated, có thể chứa số.

### 7.2. Tags

| Tag | Ý nghĩa | Filter |
|-----|---------|--------|
| `@smoke` | Smoke 30 TC P-High (PR gate) | `--grep @smoke` |
| `@regression` | Regression suite Phase 22 | `--grep @regression` |
| `@P-High` | Priority cao (per Excel column) | `--grep @P-High` |
| `@P-Medium` | Priority trung bình | `--grep @P-Medium` |
| `@flaky` | Quarantine flaky test | `--grep -v @flaky` |
| `@auth` `@vbden` `@vbdi` `@hscv` | Module tag (Phase 22) | `--grep @vbden` |

### 7.3. Storage state per role (skip login)

```typescript
import { storageStateFor } from '../fixtures/auth';

test.use({ storageState: storageStateFor('vanthu') });

test('TC-VBD-001 Mở danh sách @smoke @P-High', async ({ page }) => {
  // Page đã có session vanthu — KHÔNG cần login
  await page.goto('/van-ban-den');
});
```

Storage state files được generate bởi `tests/globalSetup.ts` (Plan 21-04) — login 5 user fixture parallel, lưu cookies + localStorage vào `tests/.auth/<role>.json`.

### 7.4. Locator best practice

```typescript
// ✅ ĐÚNG — semantic + stable
page.getByRole('button', { name: /Đăng nhập/i })
page.getByLabel('Tên đăng nhập')
page.locator('[data-testid="search-input"]')

// ❌ TRÁNH — fragile khi UI thay đổi
page.locator('text="Đăng nhập"')           // text-only dễ vỡ
page.locator('.css-xyz123')                 // CSS class hash đổi mỗi build
page.locator('div > div > button:nth-child(2)')  // brittle XPath/selector chain
```

---

### 7.5. Add test mới (boilerplate)

Khi QA muốn thêm TC mới (smoke / integration / E2E), copy 1 trong 3 template dưới đây:

#### 7.5.1. Smoke E2E (Playwright) — UI flow

File path: `tests/smoke/<module>.spec.ts`

```typescript
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';
import { TEST_USERS } from '../../e_office_app_new/backend/tests/fixtures/users';
import { TEST_DOCS } from '../../e_office_app_new/backend/tests/fixtures/docs';

// Dùng storage state per role để skip login
test.use({ storageState: storageStateFor('vanthu') });

test.describe('Smoke — <Module name>', () => {
  test('TC-XXX-NNN <Mô tả tiếng Việt> @smoke @P-High', async ({ page }) => {
    // Arrange: navigate
    await page.goto('/<route-vietnamese>');

    // Act: tương tác UI
    const button = page.getByRole('button', { name: /<button-text>/i });
    await button.click();

    // Assert: verify state
    await expect(page.locator('.ant-drawer-content').first()).toBeVisible({ timeout: 5000 });

    // Optional: dùng fixture data
    const adminUser = TEST_USERS.admin;  // { username: 'test_admin', password: 'Test@123', ... }
    const docId = TEST_DOCS.incoming.new.id;  // 90001
  });
});
```

**Convention:**
- File 1 module/spec (auth.spec.ts, incoming-doc.spec.ts, etc.)
- Title BẮT BUỘC bắt đầu `TC-XXX-NNN ` (regex `^(TC-[A-Z0-9-]+)`)
- Tag `@smoke` để filter (PR gate run smoke)
- Tag `@P-High` cho priority (per Excel column)
- Dùng `test.use({ storageState })` ở top file (KHÔNG login lại trong test)

#### 7.5.2. Integration test (Vitest + supertest) — API contract

File path: `e_office_app_new/backend/tests/integration/<module>/<endpoint>.test.ts`

```typescript
import { describe, test, expect, beforeAll, afterAll } from 'vitest';
import request from 'supertest';
import { app } from '@/server';  // backend Express app
import { TEST_USERS } from '../../fixtures/users';
import { withTransaction, closeTestPool } from '../../helpers/db';

describe('TC-API-NNN <Endpoint description>', () => {
  let token: string;

  beforeAll(async () => {
    const res = await request(app)
      .post('/api/auth/login')
      .send({ username: TEST_USERS.vanthu.username, password: TEST_USERS.vanthu.password });
    token = res.body.accessToken;
  });

  afterAll(async () => {
    await closeTestPool();
  });

  test('TC-API-NNN-001 GET /api/<route> trả 200 + data shape đúng', async () => {
    await withTransaction(async () => {
      const res = await request(app)
        .get('/api/<route>')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('items');
      expect(Array.isArray(res.body.items)).toBe(true);
    });
    // withTransaction auto-rollback → DB không thay đổi
  });
});
```

**Convention:**
- 1 file test/endpoint
- Dùng `withTransaction()` cho tests modify DB (auto rollback)
- Login 1 lần ở `beforeAll`, reuse `token` cho các test trong describe
- TC-ID `TC-API-XXX` cho integration (vs `TC-AUTH/VBD/HSCV` cho UI smoke)

#### 7.5.3. E2E full flow (Playwright) — Multi-step business

File path: `tests/e2e/<scenario>.spec.ts` (Phase 23 backlog — example structure)

```typescript
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

test.describe('E2E — Full lifecycle <scenario>', () => {
  test('TC-E2E-NNN <Scenario name> @e2e @P-High', async ({ browser }) => {
    // 2 contexts cho 2 user khác nhau
    const vanthuCtx = await browser.newContext({ storageState: storageStateFor('vanthu') });
    const lanhdaoCtx = await browser.newContext({ storageState: storageStateFor('lanhdao') });

    const vanthuPage = await vanthuCtx.newPage();
    const lanhdaoPage = await lanhdaoCtx.newPage();

    // Step 1: vanthu vào sổ VB đến
    await vanthuPage.goto('/van-ban-den');
    // ... click Vào sổ, fill form, save

    // Step 2: lanhdao phê duyệt
    await lanhdaoPage.goto('/van-ban-den');
    // ... click VB vừa tạo, approve

    // Cleanup
    await vanthuCtx.close();
    await lanhdaoCtx.close();
  });
});
```

#### 7.5.4. Checklist trước khi commit test mới

- [ ] Test title có TC-ID prefix (`TC-XXX-NNN `)
- [ ] Tag `@smoke` / `@regression` / `@e2e` theo loại
- [ ] Tag priority `@P-High` / `@P-Medium` / `@P-Low`
- [ ] Dùng `getByRole` / `getByLabel` / `[data-testid]` thay vì raw `text=` hay CSS class
- [ ] TC-ID đã có trong `docs/hdsd/20260505_Testcase_QLVB_V2.xlsx` template (Excel parser warn nếu thiếu)
- [ ] Chạy local: `npx playwright test --grep <TC-ID>` PASS
- [ ] Nếu test modify DB → dùng `withTransaction()` (integration) hoặc reset DB sau (E2E)
- [ ] Comment Vietnamese có dấu OK trong test title (UI render đúng cho Vietnamese QA review)

---

## 8. Troubleshooting

| Vấn đề | Nguyên nhân | Fix |
|--------|-------------|-----|
| `Error: spawnSync psql ENOENT` khi chạy `npm run test:db:reset` trên Windows | psql CLI không có trong PATH + auto-detect Docker probe fail (docker daemon down hoặc container `qlvb_postgres` không chạy) | (1) Verify Docker Desktop đang chạy + container `qlvb_postgres` UP: `docker ps --filter name=qlvb_postgres`. (2) Set explicit `PG_DOCKER_CONTAINER=qlvb_postgres` trong `e_office_app_new/backend/.env.test` (template `.env.test.example` đã pre-set — copy lại nếu lỡ xoá). (3) Restart Docker Desktop nếu container không list. |
| `[globalSetup] Backend không phản hồi tại http://localhost:4000` | Backend chưa chạy hoặc PG_DATABASE sai | Bước 3 Terminal 1 — set `PG_DATABASE=qlvb_test` rồi `npm run dev` |
| `Login fail cho admin (test_admin)` | Test DB chưa seed fixture | Bước 2 — `npm run test:db:reset` |
| `Cannot find module '@playwright/test'` | Chưa install root deps | Root dir: `npm install && npx playwright install chromium` |
| `port 3000 đã có app khác` | Frontend dev chạy trùng port | Tắt process cũ: `Get-NetTCPConnection -LocalPort 3000` rồi `Stop-Process` |
| Test pass local nhưng fail CI | UI render khác CI ubuntu (font/locale) | Mở trace viewer artifact từ CI: GitHub Actions → workflow → artifacts |
| `qlvb_test` đã tồn tại nhưng test fail "fixture not found" | Schema cũ từ phiên trước | `npm run test:db:reset` (DROP + CREATE + seed lại) |
| `Cannot connect to docker daemon` | Docker Desktop chưa start | Mở Docker Desktop, chờ tray icon xanh |
| Tiếng Việt corrupt trong stdout PowerShell | PS 5.1 default codepage | Chạy `chcp 65001` trước, hoặc dùng PowerShell 7 |
| Mock server stop sau vài phút | Restart Docker / windows sleep | `cd tools/mocks && npm start` lại |
| Smoke fail vì search input không tìm thấy | UI chưa có `data-testid="search-input"` | Test có `test.skip()` với reason — không fail (Phase 22 fix) |

---

## 9. Tài nguyên

- [Playwright official docs](https://playwright.dev/docs/intro)
- [Vitest official docs](https://vitest.dev/)
- `.planning/AUTOMATION_TEST_PLAN.md` — Master plan 12 sections (architecture, REQ-IDs, CI gates)
- `.planning/REQUIREMENTS.md` — 43 REQ-IDs (AUTO/REG/E2E/CI/RPT) status
- `tools/mocks/README.md` — Mock server reference (SmartCA/MySign/LGSP shapes)
- `tools/test-report/README.md` — Excel sync tool reference
- Excel template: `docs/hdsd/20260505_Testcase_QLVB_V2.xlsx` (847 TC source-of-truth)

---

## 10. Câu hỏi thường gặp (FAQ)

**Q: Smoke chạy nhanh hơn 5 phút được không?**
A: Hiện dùng 4 workers. Tăng `--workers=8` nếu máy ≥ 16GB RAM. CI giới hạn 2 workers (Phase 21-06 setup).

**Q: Thêm TC mới làm sao?**
A: Tạo `test('TC-NEWMODULE-001 Mô tả ngắn @smoke @P-High', ...)` trong file spec phù hợp dưới `tests/smoke/`. KHÔNG quên TC-ID prefix + tag `@smoke`.

**Q: TC mới chưa có trong Excel template thì sao?**
A: Excel parser sẽ in warning `WARN: TC X có trong test nhưng KHÔNG có trong Excel template`. Update template `docs/hdsd/20260505_Testcase_QLVB_V2.xlsx` thêm row mới (col A = TC-ID).

**Q: Khi nào cần update mock server?**
A: Khi real provider (SmartCA/LGSP) đổi response shape. Run real handshake → diff → update fixture trong `tools/mocks/`.

**Q: Test fail intermittent (flaky)?**
A: Thêm tag `@flaky` quarantine ra khỏi PR gate (`--grep -v @flaky`). Investigate sau, KHÔNG để fail thật bị che. Phase 22 sẽ có dashboard track flaky.

**Q: Storage state file `tests/.auth/vanthu.json` đã expired (JWT 15min)?**
A: globalSetup tự regen trước mỗi run. Nếu không regen (skip globalSetup), xóa thư mục `tests/.auth/*.json` rồi chạy lại.

**Q: Run smoke trong CI thì sao?**
A: Phase 21-06 sẽ wire `.github/workflows/test-pr.yml` chạy `npm run test:smoke` sau khi setup postgres + mock + frontend/backend. CI fail = block merge.

**Q: Excel output có push lên git không?**
A: KHÔNG. File `<YYYYMMDD>_Testcase_QLVB_V2_results.xlsx` đã thêm `.gitignore` pattern. Chỉ giữ Excel template (1 file) trong git.

---

**Onboarding complete!** Nếu QA mới đi qua 1-5 step trong ≤ 30 phút có smoke đầu tiên xanh thì đã đạt RPT-07 acceptance.

Phản hồi/câu hỏi: tag `@dev-team` trên Slack hoặc tạo issue `[automation-test]` label.
