---
status: testing
phase: 21-automation-foundation
source:
  - .planning/phases/21-automation-foundation/21-01-SUMMARY.md
  - .planning/phases/21-automation-foundation/21-02-SUMMARY.md
  - .planning/phases/21-automation-foundation/21-03-SUMMARY.md
  - .planning/phases/21-automation-foundation/21-04-SUMMARY.md
  - .planning/phases/21-automation-foundation/21-05-SUMMARY.md
  - .planning/phases/21-automation-foundation/21-06-SUMMARY.md
started: "2026-05-06T12:30:00.000Z"
updated: "2026-05-06T16:15:00.000Z"
---

## Current Test

[testing complete — 2 passed / 2 issues / 2 blocked / 1 pending→pass via README review]

## Tests

### 1. Cold Start Smoke Test
expected: Fresh start 4 step (DB reset + mocks boot + Playwright install) hoàn tất không lỗi, qlvb_test có data, 3 mock /health trả 200.
result: issue
reported: |
  Step 1 (test:db:reset) FAIL: spawnSync psql ENOENT trên Windows.
  Logic auto-detect Docker tại test-db-reset.ts:122-124 chỉ check '/var/run/docker.sock' (Linux only) — fall through tới direct psql CLI → ENOENT.
  Workaround đã verify: set PG_DOCKER_CONTAINER=qlvb_postgres trong .env.test → script dùng docker exec.
  Step 2 (mocks boot) PASS: 3 server UP trong 149ms, /health 200.
  Step 4 chỉ là issue trong test instructions (PowerShell 5.1 không support `&&`) — không phải bug code.
severity: blocker

### 2. Test DB reset speed + idempotent
expected: 3 lần `npm run test:db:reset` PASS, mỗi lần < 30s, idempotent (sequence không duplicate), VERIFY counts giống nhau.
result: pass
notes: |
  Run #1: 9.17s, VERIFY staff=6 incoming_docs=5 role_of_staff=6
  Run #2: 10.30s, VERIFY identical
  Run #3: 9.82s, VERIFY identical
  AUTO-02 target < 30s — ACHIEVED 3.3x faster.

### 3. 5 user fixture login OK
expected: 5 user login HTTP 200 + accessToken non-empty + tiếng Việt có dấu trong full_name. test_locked → 401/403.
result: pass
notes: |
  5 user (test_admin/vanthu/lanhdao/canbo/canbo_x) → HTTP 200, accessToken length 254-274.
  test_locked → HTTP 403 + body "Tài khoản đã bị khóa" (tiếng Việt có dấu OK).
  Minor cosmetic: fixture full_name dùng KHÔNG DẤU ("TEST Quan tri" thay vì "TEST Quản trị") — vi phạm convention CLAUDE.md feedback #4. Functional OK nhưng E2E test sẽ không exercise UTF-8 path đúng.
  Note: response field là `fullName` (camelCase) chứ không phải `full_name` — backend serializer convert OK, không phải bug.

### 4. 3 Mock servers boot + X-Mock-Scenario hoạt động
expected: 3 /health 200 + scenario header trả status đúng (invalid_cert→400, provider_down→503).
result: pass
notes: |
  3 /health: smartca/mysign/lgsp đều 200, body có status+service+port+timestamp.
  Scenario header verified:
    invalid_cert → 400 "Chứng thư số không hợp lệ hoặc đã hết hạn" (tiếng Việt có dấu)
    provider_down → 503 "Dịch vụ ký số tạm ngưng"
    default (no header) /smartca/sign → 400 "tran_id and payload required" (validation OK)
  Minor doc drift: AUTOMATION_TEST_PLAN.md section 7.1 viết generic `/auth, /sign, /verify` nhưng implementation dùng prefix `/smartca/sign`, `/mysign/sign`, `/api/lgspedoc/*` — implementation chính xác hơn vì khớp real provider URL convention.

### 5. Smoke 30 TC PASS 30/30 < 5 phút (CORE must_have)
expected: PASS 30/30 < 5 min trên local Windows.
result: blocked
blocked_by: local_ram_constraint
reason: |
  Máy 10GB total, 92-93% RAM used (Vmmem WSL2 2.16GB + VS Code 1.24GB + Chrome 687MB + Defender + SQL + Zalo). Free chỉ ~0.55GB.
  Build/start frontend cần thêm ~1.5GB peak → trước đó đã gây force shutdown khi tôi spawn `npm run dev`.
  Defer sang CI verify: workflow `.github/workflows/test-pr.yml` chạy đúng kịch bản này trên ubuntu-latest runner (RAM rộng hơn) khi push branch lên PR đầu tiên.

### 6. Excel report sync sinh đúng file output
expected: sync-to-excel.ts sinh `<YYYYMMDD>_Testcase_QLVB_V2_results.xlsx` với 5 cột mới + coverage report.
result: blocked
blocked_by: depends_on_test_5
reason: |
  Cần Playwright JSON results từ Test 5 làm input. Test 5 blocked → Test 6 cũng blocked.
  Verify trên CI cùng lúc với Test 5.

### 7. Onboarding README ≤ 30 phút
expected: 11 section đủ + ≤ 30 phút setup khả thi cho QA mới chưa biết Playwright.
result: issue
reported: |
  PASS phần lớn: 348 dòng, 10 section + sub-section, troubleshooting 10 entry, FAQ, tiếng Việt có dấu xuyên suốt, code block PowerShell concrete.

  3 GAP phát hiện:
  (1) MAJOR: Section 1.3 (.env.test) + Section 8 (Troubleshooting) KHÔNG có note Windows dev cần `PG_DOCKER_CONTAINER=qlvb_postgres` — đây chính là blocker Test 1. QA mới Windows sẽ stuck ngay step DB reset, mất 10-30 phút troubleshoot → break ≤ 30 phút target.
  (2) MINOR: Thiếu section "CI integration" — không nói workflow `test-pr.yml` chạy gì, cách trigger thủ công, cách đọc artifact CI khi fail.
  (3) MINOR: Thiếu section "Add test mới" — chỉ có convention naming + locator best practice, không có template/boilerplate viết test mới.

  Estimate ≤ 30 phút technically pass (nếu QA biết workaround Windows), nhưng thực tế Windows dev sẽ vượt 30 phút vì gap (1).
severity: major

## Summary

total: 7
passed: 3
issues: 2
blocked: 2
skipped: 0
pending: 0

## Status

partial — 3 PASS (T2/T3/T4) + 2 ISSUE cần fix (T1 blocker workaround applied + T7 README gaps) + 2 BLOCKED-deferred-to-CI (T5 smoke + T6 Excel sync, do local RAM constraint).

Phase 21 infrastructure verified working (DB reset OK, login OK, mocks OK with scenarios). Smoke 30 TC sẽ verify trên CI runner ubuntu-latest qua workflow `.github/workflows/test-pr.yml` khi push branch.

## Gaps

- truth: "test:db:reset chạy được trên Windows local sau npm install (không cần thao tác thủ công thêm)"
  status: failed
  reason: |
    User reported: "spawnSync psql ENOENT" trên Windows.
    Root cause: tools/test-db-reset.ts:122-124 logic `useDocker` chỉ check `/var/run/docker.sock` (Linux only), Windows fallthrough → direct psql CLI → ENOENT.
    Workaround verify: set `PG_DOCKER_CONTAINER=qlvb_postgres` trong `.env.test` → script chuyển sang docker exec.
  severity: blocker
  test: 1
  artifacts:
    - "e_office_app_new/backend/.env.test (đã thêm PG_DOCKER_CONTAINER=qlvb_postgres làm workaround)"
  missing:
    - "Auto-detect Docker trên Windows trong test-db-reset.ts: thay check `/var/run/docker.sock` bằng `process.platform === 'win32' && child_process.execSync('docker ps -q -f name=qlvb_postgres', {stdio: 'pipe'}).length > 0` để fallback Docker khi platform Windows"
    - "Tạo file .env.test.example có sẵn dòng `PG_DOCKER_CONTAINER=qlvb_postgres` + comment giải thích Windows dev cần"
    - "Cập nhật docs/automation-test/README.md section 1.3 (.env.test) + section 8 Troubleshooting: thêm entry 'spawnSync psql ENOENT → set PG_DOCKER_CONTAINER trong .env.test'"

- truth: "Test fixture user full_name có dấu tiếng Việt (CLAUDE.md feedback #4: LUÔN viết tiếng Việt có dấu)"
  status: failed
  reason: |
    Fixture seed/003_test_fixtures.sql line 75-90 dùng KHÔNG DẤU: 'TEST', 'Quan tri'/'Van thu'/'Lanh dao'/'Can bo'.
    Login response trả full_name "TEST Quan tri" — UI test sẽ render text không dấu, không exercise UTF-8 path đúng.
  severity: minor
  test: 3
  artifacts: []
  missing:
    - "Update seed 003_test_fixtures.sql: 'TEST', 'Quản trị' / 'Văn thư' / 'Lãnh đạo' / 'Cán bộ' / 'Cán bộ đơn vị khác' / 'User đã khóa' (last_name có dấu, first_name 'TEST' giữ ASCII)"
    - "Re-run test:db:reset sau update để fixture mới apply"

- truth: "Onboarding README có section 'CI integration' và note Windows-specific config trong section 1.3 + 8"
  status: failed
  reason: |
    README 348 dòng tuy đầy đủ 10 section + sub-section + 10 troubleshooting entry, nhưng thiếu:
    (1) Note PG_DOCKER_CONTAINER cho Windows dev — gây stuck Test 1 ngay từ step DB reset.
    (2) Section CI integration giải thích test-pr.yml.
    (3) Section/template "Add test mới" cho QA viết test mới.
  severity: major
  test: 7
  artifacts: []
  missing:
    - "README section 1.3 (.env.test): bổ sung block code mới highlight Windows dev cần PG_DOCKER_CONTAINER=qlvb_postgres"
    - "README section 8 (Troubleshooting): thêm row đầu '`spawnSync psql ENOENT` | Windows: auto-detect Docker không work | Set `PG_DOCKER_CONTAINER=qlvb_postgres` trong `.env.test`'"
    - "README section mới '8.5 CI integration': workflow test-pr.yml chạy gì, cách trigger thủ công, đọc artifact GitHub Actions khi fail"
    - "README section mới '7.5 Add test mới': boilerplate template `import { test, expect } from '@playwright/test'; test('TC-XXX-NNN <vietnamese title> @smoke', async ({ page }) => { ... })` với reference TEST_USERS / TEST_DOCS"

# Note: Test 5 (smoke 30 TC) + Test 6 (Excel sync) blocked by local RAM constraint (10GB total, 92% used by Vmmem WSL2 + VS Code + Chrome).
# KHÔNG đưa vào Gaps vì không phải code bug — là prerequisite gate. CI runner ubuntu-latest sẽ verify cả 2 khi push branch (workflow test-pr.yml).
