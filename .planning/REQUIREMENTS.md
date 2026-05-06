# Requirements — Milestone v3.1 Manual Test Execution + Bug Fix

> **2026-05-06 RE-SCOPE:** Đổi từ "Automation Test Suite production-grade với CI/Slack/k6" → "Claude (AI tester) execute 847 TC thủ công + fill Excel + log bug → user duyệt → fix → re-test". Lý do: user clarify intent — không có team QA, không cần CI/cron/automation framework, chỉ cần đảm bảo chất lượng sản phẩm trước khi đàm phán xong với KH.
>
> **Source TC:** [`docs/hdsd/20260505_Testcase_QLVB_V2.xlsx`](../docs/hdsd/20260505_Testcase_QLVB_V2.xlsx) (847 TC, 9 wave a-i)
>
> **Workflow:** Mỗi Phase (22-30) = 1 Wave execute + report Excel. Bug discovered → user duyệt scope → tôi insert phase fix qua `/gsd-insert-phase`.

---

## v3.1 Requirements (re-scoped)

### INFRA — Test infrastructure (Phase 21 — DONE)

Đã build trong Phase 21, dùng làm utility cho Claude execute test:

- [x] **INFRA-01**: Test DB `qlvb_test` tách hoàn toàn `qlvb_dev` — script `npm run test:db:reset` < 30s, idempotent, KHÔNG TOUCH dev DB
- [x] **INFRA-02**: File `seed/003_test_fixtures.sql` idempotent với guard `app.environment != 'prod'`
- [x] **INFRA-03**: 6 user fixture (`test_admin/vanthu/lanhdao/canbo/canbo_x/locked` password `Test@123`) + 16 VB fixture data
- [x] **INFRA-04**: Mock SmartCA (8181) + MySign (8182) + LGSP (8183) — emulate endpoint thật + scenario header `X-Mock-Scenario`
- [x] **INFRA-05**: Excel sync tool `tools/test-report/sync-to-excel.ts` — fill cột "Trạng thái" + "Run date" + "Duration" + "Error msg" vào Excel template
- [x] **INFRA-06**: Vitest + Playwright + supertest installed — utility cho Claude tự `npm run test:smoke` sanity check sau fix bug
- [x] **INFRA-07**: Onboarding doc `docs/automation-test/README.md` (~150 dòng, Claude usage notes)

### EXEC — Execute 847 TC theo wave (Phase 22-30 — IN PROGRESS)

- [ ] **EXEC-22**: Phase 22 execute Wave a (83 TC Auth + Admin) → fill Excel → bug list
- [ ] **EXEC-23**: Phase 23 execute Wave b (181 TC VB đến/đi) → fill Excel → bug list
- [ ] **EXEC-24**: Phase 24 execute Wave c (203 TC HSCV + Dự thảo + Ký số DS) → fill Excel → bug list (mock SmartCA active)
- [ ] **EXEC-25**: Phase 25 execute Wave d (126 TC Boundary form fields) → fill Excel → bug list
- [ ] **EXEC-26**: Phase 26 execute Wave e (75 TC 4 Danh mục) → fill Excel → bug list
- [ ] **EXEC-27**: Phase 27 execute Wave f (97 TC Boundary VARCHAR + upload) → fill Excel → bug list
- [ ] **EXEC-28**: Phase 28 execute Wave g (50 TC Permission cross-unit + role matrix) → fill Excel → bug list
- [ ] **EXEC-29**: Phase 29 execute Wave h (19 TC E2E flow xuyên module) → fill Excel → bug list (mock SmartCA + LGSP active)
- [ ] **EXEC-30**: Phase 30 execute Wave i (13 TC Concurrent + race + perf) → fill Excel → bug list

### REPORT — Đầu ra cuối milestone

- [ ] **REPORT-01**: Excel `<YYYYMMDD>_Testcase_QLVB_V2_results.xlsx` có cột "Trạng thái" fill 100% (Pass/Fail/Skip kèm reason)
- [ ] **REPORT-02**: Tổng pass rate sau bug fix loop ≥ 95% — chuẩn bị bàn giao KH
- [ ] **REPORT-03**: Bug list cuối cùng với severity classification (blocker/major/minor/cosmetic) — danh sách bug RESOLVED + REMAINING

---

## Phase mapping (re-scoped 2026-05-06)

| Phase | Scope | REQs | Time |
|-------|-------|------|------|
| 21 — Automation Foundation (DONE) | Build test DB + fixtures + mocks + Excel tool | INFRA-01..07 | 3 ngày |
| 22 — Execute Wave a | 83 TC Auth + Admin | EXEC-22 | ~2h |
| 23 — Execute Wave b | 181 TC VB đến/đi | EXEC-23 | ~4h |
| 24 — Execute Wave c | 203 TC HSCV + Dự thảo + Ký số | EXEC-24 | ~5h |
| 25 — Execute Wave d | 126 TC Boundary | EXEC-25 | ~2h |
| 26 — Execute Wave e | 75 TC Danh mục | EXEC-26 | ~2h |
| 27 — Execute Wave f | 97 TC Boundary VARCHAR + upload | EXEC-27 | ~2h |
| 28 — Execute Wave g | 50 TC Permission | EXEC-28 | ~2h |
| 29 — Execute Wave h | 19 TC E2E flow | EXEC-29 | ~2h |
| 30 — Execute Wave i | 13 TC Concurrent | EXEC-30 | ~1h |
| **31+ (dynamic)** | **Bug fix insert phase** | — | TBD |
| **Cuối** | Excel report + bug remaining list | REPORT-01..03 | — |

> **Phase 31** (LGSP "Từ chối tiếp nhận" cũ Phase 24) đã renumber → đẩy sang v3.2 backlog hoặc insert dynamic.

---

## Out of Scope (re-scoped)

- **Automation framework production-grade** — không build CI/CD, không cron nightly, không Slack alert, không k6 perf load testing, không visual regression pixel-diff
- **Team QA onboarding** — không có team, chỉ Claude + user
- **Cypress** — không dùng vì không có code test runner
- **Multi-browser testing** — chỉ Chromium nếu cần screenshot (Firefox/WebKit defer)
- **Hybrid weekly real provider** — defer khi có credentials KH thật
- **Mobile responsive E2E** — defer
- **i18n test** — hệ thống chỉ tiếng Việt
- **Accessibility (a11y)** — defer

## Future Requirements (defer v3.2+)

- [ ] **DEFER-01**: CI/CD pipeline với GitHub Actions (chỉ khi có team)
- [ ] **DEFER-02**: Nightly automated regression
- [ ] **DEFER-03**: Visual regression pixel-diff (Percy/Chromatic)
- [ ] **DEFER-04**: Accessibility test với axe-core
- [ ] **DEFER-05**: Mobile responsive E2E
- [ ] **DEFER-06**: k6 load testing
- [ ] **DEFER-07**: LGSP "Từ chối tiếp nhận" production wiring
- [ ] **DEFER-08**: Drafting recipients structured
- [ ] **DEFER-09**: Trang admin CRUD `inter_organizations`
- [ ] **DEFER-10**: Multi-level approval workflow

---

*Last updated: 2026-05-06 — re-scope từ "Automation Test Suite" → "Manual Test Execution by Claude". 7 INFRA done (Phase 21), 9 EXEC pending (Phase 22-30), 3 REPORT pending.*
