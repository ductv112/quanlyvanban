# Requirements — Milestone v3.1 Automation Test Suite

> **Source of truth:** [`.planning/AUTOMATION_TEST_PLAN.md`](AUTOMATION_TEST_PLAN.md) — research artifact với 12 section chi tiết (framework rationale, pyramid mapping, mock fidelity, CI strategy, risks).
>
> **Scope:** Tự động hoá ≥ 95% bộ 847 TC ([`docs/hdsd/20260505_Testcase_QLVB_V2.xlsx`](../docs/hdsd/20260505_Testcase_QLVB_V2.xlsx)) thành regression suite chạy < 45 phút mỗi đêm + smoke 30 TC < 8 phút trên mỗi PR + map Pass/Fail ngược về Excel cho KH/QA.
>
> **REQ-ID format:** `[CATEGORY]-[NUMBER]`. v3.1 dùng 5 category mới: **AUTO** (infrastructure), **REG** (regression coverage), **E2E** (end-to-end + concurrent + perf), **CI** (CI/CD integration), **RPT** (reporting + Excel sync).

---

## v3.1 Requirements

### AUTO — Automation Infrastructure (foundation)

- [x] **AUTO-01**: Dev cài đặt được toàn bộ test stack (Playwright + Vitest + supertest + k6 + nock + wait-on) qua `npm install` 1 lần — không cần config thủ công
- [x] **AUTO-02**: Test DB tách biệt hoàn toàn với dev DB (`qlvb_test` vs `qlvb_dev`) — script `npm run test:db:reset` apply schema + seed 001 + seed 003 trong < 30 giây
- [x] **AUTO-03**: File `database/seed/003_test_fixtures.sql` idempotent với guard `app.environment != 'prod'` — chạy nhiều lần không lỗi sequence/duplicate, tuyệt đối không apply được lên prod
- [x] **AUTO-04**: 5 user fixture chuẩn (`test_admin`, `test_vanthu`, `test_lanhdao`, `test_canbo`, `test_canbo_x`) đăng nhập được với password `Test@123` — phục vụ test 4 vai trò + cross-unit isolation
- [x] **AUTO-05**: 16 fixture data seed (5 VB đến đa status + 3 VB đi + 2 dự thảo + 1 HSCV active + 1 HSCV closed + 3 notification + 1 user khoá) — đủ chất liệu test status flow
- [x] **AUTO-06**: Mock SmartCA server (port 8181) emulate đủ 4 endpoint (`/auth`, `/sign`, `/verify`, `/cert/:userId`) + 3 scenario qua header `X-Mock-Scenario` (`timeout`, `invalid_cert`, `provider_down`)
- [x] **AUTO-07**: Mock MySign server (port 8182) tương tự SmartCA — backup provider scenarios
- [x] **AUTO-08**: Mock LGSP server (port 8183) emulate SOAP envelope với 4 status code (success + 3 error) — phục vụ TC liên thông
- [x] **AUTO-09**: Test isolation: integration tests dùng `BEGIN`/`ROLLBACK` per `describe` block, E2E tests dùng template-DB clone per worker (`CREATE DATABASE qlvb_test_w1 TEMPLATE qlvb_baseline`)
- [ ] **AUTO-10**: Storage state per role: 5 file `tests/.auth/<role>.json` được auto-gen trong `globalSetup` để E2E reuse session, không phải re-login mỗi test
- [ ] **AUTO-11**: Smoke suite gồm 30 TC P-High cover 6 module trọng yếu (Auth 5, VB đến 8, VB đi 5, HSCV 5, Admin 4, Dashboard 3) chạy local < 5 phút PASS 30/30

### REG — Regression Coverage (Wave a-g, 815/847 TC)

- [ ] **REG-01**: Toàn bộ Wave a (83 TC Auth + Admin) auto được — Positive + Negative qua integration (supertest) + UI category qua Playwright
- [ ] **REG-02**: Toàn bộ Wave b (181 TC Văn bản đến/đi) auto được — bao gồm CRUD, attachment upload, status flow
- [ ] **REG-03**: Toàn bộ Wave c (203 TC HSCV + Dự thảo + Ký số DS) auto được — sign flow chạy với SmartCA mock
- [ ] **REG-04**: Toàn bộ Wave d (126 TC Boundary) auto được — form-level Drawer input via Playwright
- [ ] **REG-05**: Toàn bộ Wave e (75 TC 4 module Danh mục) auto được — CRUD Sổ VB / Loại VB / Lĩnh vực / Người ký
- [ ] **REG-06**: Toàn bộ Wave f (97 TC Boundary VARCHAR + upload) auto được — bao gồm test maxLength tất cả field theo DB schema
- [ ] **REG-07**: Toàn bộ Wave g (50 TC Permission) auto được — cross-unit isolation + role matrix 4 vai trò + token/session
- [ ] **REG-08**: Mỗi test có title bắt đầu bằng TC-ID format `^TC-[A-Z0-9-]+` để parser map ngược về Excel — convention bắt buộc, lint check trong CI
- [ ] **REG-09**: Test pyramid đúng phân bố — 50 unit / 464 integration / 383 E2E ± 10% — đo bằng số `test()` block per category
- [ ] **REG-10**: Flaky rate < 1% sau 7 lần chạy nightly liên tiếp — test fail không reproducible bị quarantine với tag `@flaky` để xử lý sau

### E2E — End-to-End + Concurrent + Performance (Wave h, i)

- [ ] **E2E-01**: 17/19 TC Wave h (E2E flow) auto được với mock — bao gồm full luồng "VB đến → giao việc → tạo dự thảo → ký số → phát hành VB đi"
- [ ] **E2E-02**: 2/19 TC Wave h hybrid weekly trên staging — TC-E2E-EXT-001 (SmartCA real handshake) + TC-E2E-EXT-003 (LGSP real submit) — cron weekly với cert thật
- [ ] **E2E-03**: 10/13 TC Wave i (concurrent) auto được với Playwright `browser.newContext()` multi-tab — race condition VB đồng thời edit, multi-tab session
- [ ] **E2E-04**: 3/13 TC Wave i (perf) chạy k6 weekly trên staging — TC-CONC-PERF-001/002/003 với gate p95 < 800ms
- [ ] **E2E-05**: 110 TC UI category visual snapshot baseline lưu trong `tests/__snapshots__/` — diff > 0.1% pixel báo fail
- [ ] **E2E-06**: TC-E2E-EXT-004 "MinIO offline" auto được bằng `docker stop qlvb_minio_test` runtime — verify backend trả 503 + form data giữ nguyên
- [ ] **E2E-07**: Coverage cuối cùng = 100% — 843 auto + 4 hybrid weekly cover toàn bộ 847 TC, không TC nào "Manual only"

### CI — CI/CD Integration

- [ ] **CI-01**: Workflow `test-pr.yml` trigger trên mọi PR — chạy integration tests + e2e-smoke (30 TC) trên ubuntu-latest với services postgres/redis/minio — block merge nếu fail
- [ ] **CI-02**: Workflow `test-pr.yml` chạy < 8 phút từ push → kết quả — không vượt quota CI free tier
- [ ] **CI-03**: Workflow `test-nightly.yml` trigger cron `0 17 * * *` UTC (00:00 ICT) — chạy đầy đủ 815 TC + integration + smoke trên ubuntu-latest
- [ ] **CI-04**: Workflow `test-nightly.yml` chạy < 45 phút — fail thì Slack `#qlvb-qa` nhận alert kèm link artifact
- [ ] **CI-05**: Workflow `test-weekly-hybrid.yml` trigger cron `0 18 * * 1` UTC (Thứ Hai 01:00 ICT) — chạy 4 TC hybrid trên staging với cert/credentials thật từ secret store
- [ ] **CI-06**: Workflow chỉ dùng `runs-on: ubuntu-latest` — KHÔNG dùng `windows-latest` (rủi ro UTF-8 corrupt với tiếng Việt có dấu, theo CLAUDE.md pitfall #1)
- [ ] **CI-07**: PR gate gồm 3 job song song: build-check (đã có) + integration-tests (mới) + e2e-smoke (mới) — fail bất kỳ job nào → block merge
- [ ] **CI-08**: Mỗi test fail trong CI tự động upload Playwright trace + screenshot + video làm artifact, retain 7 ngày, link trace có trong PR comment

### RPT — Reporting & Excel Sync

- [ ] **RPT-01**: Tool `tools/test-report/sync-to-excel.js` đọc 2 input (`playwright-results.json` + `vitest-results.json`) + Excel template gốc, output `docs/hdsd/<YYYYMMDD>_Testcase_QLVB_V2_results.xlsx` với 5 cột mới: Trạng thái / Run date / Duration / Error msg / Trace link
- [ ] **RPT-02**: Mapping TC-ID → row dùng regex `^(TC-[A-Z0-9-]+)` extract từ test title — TC nào không có trong Excel → report cảnh báo "TC chưa tracking", TC trong Excel không có test → đánh "Not run"
- [ ] **RPT-03**: Sau mỗi nightly run, file Excel được commit về branch `test-results/<YYYYMMDD>` — team tester có lịch sử so sánh tuần
- [ ] **RPT-04**: Coverage report cuối nightly print đúng số liệu: tổng 847 TC, auto coverage %, hybrid count, "Not run" count với lý do (HYBRID weekly hay missing automation)
- [ ] **RPT-05**: Coverage drop alert: nếu auto coverage < 95% sau nightly → Slack alert đỏ + tag QA lead để truy nguyên nhân
- [ ] **RPT-06**: Báo cáo Pass/Fail summary đẩy Slack `#qlvb-qa` mỗi 00:00 ICT với format: total / pass / fail / skip / duration / link Excel artifact
- [ ] **RPT-07**: Onboarding doc `docs/automation-test/README.md` ≤ 30 phút để QA member mới (chưa biết Playwright) chạy được test đầu tiên — bao gồm setup local DB test, run smoke, đọc trace fail

---

## Phase mapping (final — confirmed by roadmapper 2026-05-05)

| Phase | REQ-IDs | Days | Total |
|-------|---------|------|-------|
| 21 — Automation Foundation | AUTO-01..11, RPT-01, RPT-07, CI-01, CI-02, CI-06, CI-07 | 3 | 17 |
| 22 — Regression Backbone | REG-01..10, CI-03, CI-04, RPT-02, RPT-03, RPT-04, RPT-06 | 5 | 16 |
| 23 — E2E + Concurrent + Hybrid | E2E-01..07, CI-05, CI-08, RPT-05 | 3 | 10 |
| **TOTAL** | **43 REQ-IDs** | **11** | **43/43 (100%)** |
| 25+ (reserve) | Bug fix discovered từ regression — `/gsd-insert-phase` khi cần | TBD | 0 |

> **Phase 24** (LGSP "Từ chối tiếp nhận") thuộc backlog ngoài v3.1 — kích hoạt v3.2 hoặc chèn urgent qua `/gsd-insert-phase` nếu LGSP production cần.

---

## Future Requirements (defer v3.2+)

- [ ] **DEFER-01**: Visual regression pixel-diff tool (Percy / Chromatic) — v3.1 chỉ làm functional UI snapshot, chưa pixel-perfect
- [ ] **DEFER-02**: Accessibility (a11y) test với `axe-core` integration
- [ ] **DEFER-03**: Mobile responsive E2E full suite (hiện tại chỉ smoke 1 viewport `375×667`)
- [ ] **DEFER-04**: Test suite cho i18n (hệ thống chỉ tiếng Việt → không có TC EN)
- [ ] **DEFER-05**: Provider record/replay framework — record real SmartCA response → replay khi cần fidelity cao hơn
- [ ] **DEFER-06**: LGSP "Từ chối tiếp nhận" production wiring (Phase 24 backlog)
- [ ] **DEFER-07**: Drafting recipients structured + carry-over Outgoing
- [ ] **DEFER-08**: Trang admin CRUD `inter_organizations` + Sync from LGSP button
- [ ] **DEFER-09**: Multi-level approval workflow

---

## Out of Scope

- **Cypress framework**: loại từ đầu — yếu trên multi-tab thật (cần cho 13 concurrent TC), upload tiếng Việt UTF-8 hack, license dashboard $$
- **Test trên Windows runner CI**: rủi ro UTF-8 corrupt với tiếng Việt có dấu (CLAUDE.md pitfall #1) — chỉ dùng ubuntu-latest
- **Manual test đơn thuần**: 0 TC giữ manual-only — bộ 847 TC được thiết kế cho automation từ đầu, không có TC kiểu "kiểm tra UX trực quan"
- **Test trên dev DB**: bắt buộc `qlvb_test` riêng — không bao giờ run automation lên dev/staging có data thật
- **Real provider trong CI mỗi PR**: SmartCA + LGSP real chỉ chạy weekly trên staging job riêng, KHÔNG bao giờ block PR
- **Browser khác Chromium trong PR**: Firefox + WebKit chỉ test trong nightly, smoke PR chỉ Chromium để giữ < 8 phút
- **Test data từ prod**: KHÔNG copy data KH thật vào test DB — fixture phải gen synthetic, không có dấu vết PII

---

## Traceability

| REQ-ID | Phase | Plan | Status |
|--------|-------|------|--------|
| AUTO-01 | 21 | 21-01 | Complete |
| AUTO-02 | 21 | TBD | Active |
| AUTO-03 | 21 | TBD | Active |
| AUTO-04 | 21 | TBD | Active |
| AUTO-05 | 21 | TBD | Active |
| AUTO-06 | 21 | TBD | Active |
| AUTO-07 | 21 | TBD | Active |
| AUTO-08 | 21 | TBD | Active |
| AUTO-09 | 21 | TBD | Active |
| AUTO-10 | 21 | TBD | Active |
| AUTO-11 | 21 | TBD | Active |
| REG-01 | 22 | TBD | Active |
| REG-02 | 22 | TBD | Active |
| REG-03 | 22 | TBD | Active |
| REG-04 | 22 | TBD | Active |
| REG-05 | 22 | TBD | Active |
| REG-06 | 22 | TBD | Active |
| REG-07 | 22 | TBD | Active |
| REG-08 | 22 | TBD | Active |
| REG-09 | 22 | TBD | Active |
| REG-10 | 22 | TBD | Active |
| E2E-01 | 23 | TBD | Active |
| E2E-02 | 23 | TBD | Active |
| E2E-03 | 23 | TBD | Active |
| E2E-04 | 23 | TBD | Active |
| E2E-05 | 23 | TBD | Active |
| E2E-06 | 23 | TBD | Active |
| E2E-07 | 23 | TBD | Active |
| CI-01 | 21 | TBD | Active |
| CI-02 | 21 | TBD | Active |
| CI-03 | 22 | TBD | Active |
| CI-04 | 22 | TBD | Active |
| CI-05 | 23 | TBD | Active |
| CI-06 | 21 | TBD | Active |
| CI-07 | 21 | TBD | Active |
| CI-08 | 23 | TBD | Active |
| RPT-01 | 21 | TBD | Active |
| RPT-02 | 22 | TBD | Active |
| RPT-03 | 22 | TBD | Active |
| RPT-04 | 22 | TBD | Active |
| RPT-05 | 23 | TBD | Active |
| RPT-06 | 22 | TBD | Active |
| RPT-07 | 21 | TBD | Active |

**Coverage:** 43/43 REQ-IDs mapped (100%) — no orphans, no duplicates.
**Phase 21 (Foundation):** 17 REQ-IDs (AUTO×11 + RPT×2 + CI×4)
**Phase 22 (Regression Backbone):** 16 REQ-IDs (REG×10 + CI×2 + RPT×4)
**Phase 23 (E2E + Concurrent + Hybrid):** 10 REQ-IDs (E2E×7 + CI×2 + RPT×1)

---

*Last updated: 2026-05-05 — Roadmap v3.1 created, 43 REQ-IDs mapped 100% across 3 phases (21-23)*
