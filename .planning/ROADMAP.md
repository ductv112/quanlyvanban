# Roadmap: e-Office — Quản lý Văn bản điện tử

> **Xem thêm:** Chi tiết 17 sprints (SP, API, UI) tại `e_office_app_new/ROADMAP.md`

## Overview

Rebuild hệ thống quản lý văn bản điện tử (.NET cũ) thành stack mới (Next.js + Express + PostgreSQL).

## Milestones

- ✅ **v1.0 MVP** — Phases 1-7 (shipped 2026-04-18) — `.planning/milestones/v1.0-phases/`
- ✅ **v2.0 Tích hợp ký số 2 kênh** — Phases 8-14 + 11.1 (shipped 2026-04-23) — `.planning/milestones/v2.0-ROADMAP.md`
- ✅ **v3.0 Chuẩn hoá quy trình văn bản** — Phases 15-20 (shipped 2026-04-24) — `.planning/milestones/v3.0-ROADMAP.md`
- 🚧 **v3.1 Automation Test Suite + Bug Fix** — Phases 21-23 (started 2026-05-05)
- 📋 **v3.2+** — Defer items (drafting recipients structured, admin CRUD inter_orgs, multi-level approval...) + Phase 24 LGSP "Từ chối tiếp nhận"

## Phases

<details>
<summary>✅ v1.0 MVP (Phases 1-7) — SHIPPED 2026-04-18</summary>

- [x] Phase 1-7. Detail: `.planning/milestones/v1.0-phases/`
</details>

<details>
<summary>✅ v2.0 Tích hợp ký số 2 kênh (Phases 8-14 + 11.1) — SHIPPED 2026-04-23</summary>

- [x] Phase 8-14 + 11.1. Detail: `.planning/milestones/v2.0-phases/`
</details>

<details>
<summary>✅ v3.0 Chuẩn hoá quy trình văn bản (Phases 15-20) — SHIPPED 2026-04-24</summary>

- [x] **Phase 15: Audit & design data model** — DESIGN.md user-approved
- [x] **Phase 16: Schema rebuild v3.0** — Master schema v3.0 idempotent (~27K lines)
- [x] **Phase 17: Tách Ban hành/Gửi + Auto-sinh Incoming nội bộ + Approver** — 5 SPs + 4 routes + UI buttons
- [x] **Phase 18: Real LGSP HTTP client + worker BullMQ thật** — `LGSPRealService` OAuth2 + REST `apiltvb.langson.gov.vn`
- [x] **Phase 19: UI rewrite + bỏ menu Liên thông** — Tracking inline VB đi
- [x] **Phase 20: Regression + UAT + audit đối xứng** — 27/27 endpoints PASS, 17 bugs UAT fixed

Detail: `.planning/milestones/v3.0-phases/`, audit: `.planning/milestones/v3.0-MILESTONE-AUDIT.md`
</details>

## Progress

| Phase range | Milestone | Status | Completed |
|-------------|-----------|--------|-----------|
| 1-7 | v1.0 | Complete | 2026-04-14 → 2026-04-18 |
| 8-14 + 11.1 | v2.0 | Complete | 2026-04-21 → 2026-04-23 |
| 15-20 | v3.0 | Complete | 2026-04-23 → 2026-04-24 |
| 21-23 | v3.1 | In Progress | 2026-05-05 → — |
| 24+ | v3.2+ | Planning | — |

## v3.1 Automation Test Suite + Bug Fix (Phases 21-23) — IN PROGRESS

**Started:** 2026-05-05
**Source plan:** [`.planning/AUTOMATION_TEST_PLAN.md`](AUTOMATION_TEST_PLAN.md)
**Estimated:** 11 working days (~2.5 sprint weeks)
**Goal:** Tự động hoá ≥ 95% bộ 847 TC ([`docs/hdsd/20260505_Testcase_QLVB_V2.xlsx`](../docs/hdsd/20260505_Testcase_QLVB_V2.xlsx)) chạy regression < 45 phút mỗi đêm; CI gate smoke 30 TC < 8 phút trên PR; Pass/Fail map ngược về cột "Trạng thái" Excel; bug nào phát hiện → fix bằng phase chèn (`/gsd-insert-phase`).

### Phase 21: Automation Foundation
**Goal:** Một QA mới clone repo + chạy 1 lệnh là có smoke 30 TC P-High xanh trên local < 5 phút và CI block PR khi smoke fail.
**Depends on:** Nothing (first phase v3.1)
**Estimated:** 3 working days
**Requirements (17):** AUTO-01, AUTO-02, AUTO-03, AUTO-04, AUTO-05, AUTO-06, AUTO-07, AUTO-08, AUTO-09, AUTO-10, AUTO-11, RPT-01, RPT-07, CI-01, CI-02, CI-06, CI-07
**Success criteria** (what must be TRUE):
  1. `npm run test:smoke` chạy local PASS 30/30 trong < 5 phút trên máy mới (clone xong, không setup tay).
  2. Mở 1 PR test → workflow `Test PR` chạy 3 job song song (build-check + integration-tests + e2e-smoke) hoàn tất < 8 phút trên `ubuntu-latest`; cố tình break 1 test → PR bị block đỏ.
  3. Test DB `qlvb_test` tách hẳn `qlvb_dev`; `npm run test:db:reset` (apply schema + seed 001 + seed 003) chạy lại N lần liên tiếp đều xong < 30 giây, không có lỗi sequence/duplicate.
  4. 5 user fixture (`test_admin`, `test_vanthu`, `test_lanhdao`, `test_canbo`, `test_canbo_x`) đăng nhập được với `Test@123`; 5 file `tests/.auth/<role>.json` được auto-gen ở `globalSetup` để E2E reuse session.
  5. Mock SmartCA (8181) + MySign (8182) + LGSP (8183) tự boot trong CI; gửi 3 scenario `X-Mock-Scenario` (`timeout`, `invalid_cert`, `provider_down`) trả đúng status code và payload — backend không cần kết nối real provider.
  6. QA mới (chưa biết Playwright) đọc `docs/automation-test/README.md` chạy được test đầu tiên trong ≤ 30 phút; smoke run xong sinh `<date>_results.xlsx` đúng 30 dòng `Pass`.
**Plans:** 7 plans (6 complete + 1 gap closure)
- [x] 21-01-PLAN.md — Wave 1: Test infrastructure (Playwright + Vitest + supertest install + config)
- [x] 21-02-PLAN.md — Wave 1: DB strategy + 003_test_fixtures.sql + reset script
- [x] 21-03-PLAN.md — Wave 2: Mock servers (SmartCA 8181 + MySign 8182 + LGSP 8183)
- [x] 21-04-PLAN.md — Wave 2: Auth fixtures + storage state per role (globalSetup)
- [x] 21-05-PLAN.md — Wave 3: Smoke 30 TC P-High + Excel parser MVP + onboarding README
- [x] 21-06-PLAN.md — Wave 4: CI workflow test-pr.yml (3 job parallel)
- [ ] 21-07-PLAN.md — Gap closure: Windows Docker auto-detect + .env.test.example + fixture diacritics + README onboarding completeness (3 UAT gaps)
**Phase directory:** `.planning/phases/21-automation-foundation/`
**UI hint:** yes

> **2026-05-06 RE-SCOPE:** Phase 22+23 ban đầu over-engineered (CI nightly + Slack + k6 weekly + visual regression). User clarified intent thật: **Claude (AI) làm tester thủ công execute 847 TC theo Excel + fill Pass/Fail + log bug → user duyệt → fix → re-test**. Không cần CI/CD vì không có team. Tách Phase 22→30 thành 9 batch theo wave (mỗi wave = 1 phase execute) + reserve phase fix bug.

### Phase 22: Execute Wave a (Auth + Admin) — 83 TC
**Goal:** Claude execute 83 TC Wave a (đăng nhập + quản trị đơn vị/người dùng/vai trò/danh mục) → fill Pass/Fail vào Excel → log bug.
**Depends on:** Phase 21 (test DB + 6 user fixture + Excel sync tool)
**Estimated:** 1 session (~2 giờ)
**Requirements:** REG-01
**Success criteria:**
  1. Toàn bộ 83 TC có cột "Trạng thái" trong Excel (Pass/Fail/Skip kèm reason)
  2. Bug list ghi riêng (severity blocker/major/minor/cosmetic) — nộp user duyệt fix scope
  3. Tỷ lệ Pass đầu tiên (chưa fix bug) ≥ 80% — nếu < 80% → có vấn đề lớn cần audit Phase 1 trước khi tiếp tục
**Source:** `tools/screenshots/testcases-wave-a.json` (83 TC structured)
**Phase directory:** `.planning/phases/22-execute-wave-a/`

### Phase 23: Execute Wave b (Văn bản đến + đi) — 181 TC
**Goal:** Execute 181 TC CRUD VB đến/đi + attachment + status flow.
**Depends on:** Phase 22 (xác nhận Auth+Admin stable trước khi test luồng VB)
**Estimated:** 1-2 session (~4 giờ)
**Requirements:** REG-02
**Source:** `tools/screenshots/testcases-wave-b.json`
**Phase directory:** `.planning/phases/23-execute-wave-b/`

### Phase 24: Execute Wave c (HSCV + Dự thảo + Ký số DS) — 203 TC
**Goal:** Execute 203 TC HSCV/dự thảo/danh sách ký số. Mock SmartCA active.
**Depends on:** Phase 23 + mock SmartCA boot
**Estimated:** 1-2 session (~5 giờ)
**Requirements:** REG-03
**Source:** `tools/screenshots/testcases-wave-c.json`
**Phase directory:** `.planning/phases/24-execute-wave-c/`

> **Lưu ý renumber:** Phase 24 LGSP "Từ chối tiếp nhận" cũ → Phase 31 (đẩy xuống cuối backlog).

### Phase 25: Execute Wave d (Boundary form fields) — 126 TC
**Goal:** Execute 126 TC boundary kiểu input form (max length, special char, empty).
**Source:** `tools/screenshots/testcases-wave-d.json`
**Phase directory:** `.planning/phases/25-execute-wave-d/`

### Phase 26: Execute Wave e (4 Danh mục) — 75 TC
**Goal:** Execute 75 TC CRUD Sổ VB / Loại VB / Lĩnh vực / Người ký.
**Source:** `tools/screenshots/testcases-wave-e.json`
**Phase directory:** `.planning/phases/26-execute-wave-e/`

### Phase 27: Execute Wave f (Boundary VARCHAR + upload) — 97 TC
**Goal:** Execute 97 TC boundary VARCHAR theo DB schema + file upload limits.
**Source:** `tools/screenshots/testcases-wave-f.json`
**Phase directory:** `.planning/phases/27-execute-wave-f/`

### Phase 28: Execute Wave g (Permission cross-unit + role matrix) — 50 TC
**Goal:** Execute 50 TC quyền 4 role × cross-unit isolation. Login đa user concurrent.
**Source:** `tools/screenshots/testcases-wave-g.json`
**Phase directory:** `.planning/phases/28-execute-wave-g/`

### Phase 29: Execute Wave h (E2E flow xuyên module) — 19 TC
**Goal:** Execute 19 TC luồng đầu cuối "VB đến → giao việc → ký số → phát hành VB đi". Mock SmartCA + LGSP active.
**Source:** `tools/screenshots/testcases-wave-h.json`
**Phase directory:** `.planning/phases/29-execute-wave-h/`

### Phase 30: Execute Wave i (Concurrent + race + perf) — 13 TC
**Goal:** Execute 13 TC concurrent (2 user cùng edit, multi-tab) + perf cơ bản (response time < 800ms).
**Source:** `tools/screenshots/testcases-wave-i.json`
**Phase directory:** `.planning/phases/30-execute-wave-i/`

### Phase 31+: Bug fix loop (insert dynamic)
Sau mỗi Wave execute → bug list. User duyệt → tôi insert phase fix qua `/gsd-insert-phase` (vd 22.1 fix Auth bug discovered từ Phase 22).

## v3.1+ Backlog (chờ kích hoạt milestone)

### Phase 24: Hoàn thiện nghiệp vụ "Từ chối tiếp nhận VB liên thông LGSP" (status 02 theo QĐ 28/2018/QĐ-TTg)

> **Renumbered:** 21 → 24 (2026-05-05) — nhường slot 21-23 cho milestone v3.1 Automation Test Suite. Phase này giữ trong backlog, kích hoạt sau khi v3.1 ship hoặc chèn bằng `/gsd-insert-phase` nếu LGSP production cần urgent.

**Trigger:** Sau khi tích hợp LGSP production thật (Phase 18 đã có `LGSPRealService` nhưng chưa wire `update-status`).
**Created:** 2026-05-05 (từ phát hiện trong session review HDSD_full mục 4.3.7)

**Vấn đề (cosmetic implementation hiện tại):**
- SP `edoc.fn_incoming_doc_return` ([000_schema_v3.0.sql:5027-5060](../e_office_app_new/database/schema/000_schema_v3.0.sql#L5027-L5060)) chỉ INSERT 1 leader_note `[Chuyển lại] {lý do}` + `UPDATE approved=FALSE`.
- KHÔNG gọi LGSP API `POST /api/lgspedoc/update-status` với `status: '02'` → đơn vị gửi qua trục liên thông HOÀN TOÀN không biết VB bị từ chối.
- Tên UI "Chuyển lại" sai terminology — chuẩn LGSP là **"Từ chối tiếp nhận"** (status code `02` per [LGSP-LANGSON-API-GUIDE.md mục 7](../docs/source_code_cu/sources/LGSP-LANGSON-API-GUIDE.md)).

**Goal:** Hoàn thiện flow để khi văn thư từ chối tiếp nhận, trục LGSP nhận status 02 và đơn vị gửi biết để gửi lại đúng đơn vị / bổ sung file / sửa thể thức.

**Scope:**

*Database:*
- `ALTER TABLE edoc.incoming_docs ADD COLUMN lgsp_status VARCHAR(2)` — lưu mã LGSP (01/02/03/04/05/06/13/15/16)
- `ALTER TABLE edoc.incoming_docs ADD COLUMN lgsp_status_synced_at TIMESTAMP` — last sync với trục
- Đổi tên SP `fn_incoming_doc_return` → `fn_incoming_doc_reject_intake`; set `lgsp_status='02'`; ghi outbox event
- Tạo bảng `edoc.lgsp_status_outbox` (id, doc_id, target_status, payload, sent_at, sent_status, retry_count) — outbox pattern cho LGSP API call async

*Backend:*
- Đổi route `POST /van-ban-den/:id/chuyen-lai` → `/tu-choi-tiep-nhan` (giữ alias 301 redirect 1 sprint)
- Worker `workers/src/lgsp-status-sync.ts`: poll outbox → gọi LGSP `update-status` với token từ provider config (encrypted client_secret) → exponential backoff 5 lần
- Service `lgsp.service.ts` quản lý token (login + refresh-token theo guide)
- Permission `canRetract` → đổi tên thành `canRejectIntake`
- Audit log MongoDB collection `lgsp_audit` cho mỗi update-status call

*Frontend:*
- Đổi nút "Chuyển lại" → "Từ chối tiếp nhận" (icon RollbackOutlined giữ)
- Modal title "Lý do chuyển lại" → "Lý do từ chối tiếp nhận"
- Placeholder mới: "Nhập lý do từ chối tiếp nhận (gửi nhầm đơn vị, sai thẩm quyền, thiếu file...)"
- Hiển thị tag trạng thái LGSP (01/02/03/04/05/06) với màu phân biệt trên chi tiết VB
- Block cảnh báo "Đã từ chối tiếp nhận lúc HH:mm DD/MM/YYYY — đã đồng bộ với trục LGSP" khi `lgsp_status='02' AND lgsp_status_synced_at IS NOT NULL`

*Tài liệu:*
- Cập nhật [docs/hdsd/HDSD_full.md](../docs/hdsd/HDSD_full.md) mục 4.3.7: rename "Modal chuyển lại văn bản" → "Modal từ chối tiếp nhận văn bản liên thông"
- Chụp lại screenshot `van_ban_den_07_modal_chuyen_lai.png` (file hiện tại SAI — MD5 trùng với file 06 Drawer Giao việc) → đổi tên → `van_ban_den_07_modal_tu_choi_tiep_nhan.png`
- Cập nhật bảng nút mục 4.3.4.2 (chi tiết VB đến)

*Testing:*
- Unit test SP `fn_incoming_doc_reject_intake`: idempotent, set `lgsp_status='02'` đúng, ghi outbox đúng
- Integration test: POST `/tu-choi-tiep-nhan` → outbox row → mock worker → mock LGSP API → `lgsp_status_synced_at` updated
- E2E Playwright: login văn thư → mở VB liên thông thật → click "Từ chối tiếp nhận" → nhập lý do ≥10 ký tự → tag "Đã từ chối tiếp nhận" hiển thị

**Depends on:**
- LGSP production integration ổn định (Phase 18 done — chỉ thêm endpoint update-status)
- Có VB liên thông THẬT trong DB demo/staging (KHÔNG dùng inject fetch như script `tools/screenshots/capture-all-rev3-fix5.js`)

**Ghi chú quan trọng:**
- KHÔNG xóa endpoint `/chuyen-lai` cũ ngay khi deploy — giữ alias 301 redirect ≥1 sprint để frontend cũ không vỡ trong giai đoạn rolling deploy. Sau khi confirm tất cả client update mới xóa.
- Có thể bundle với các v3.1 backlog liên quan (CRUD inter_organizations, sync from LGSP) để giảm chi phí deploy.

**Plans:** TBD — chạy `/gsd-plan-phase 24` khi sẵn sàng.

**Phase directory:** `.planning/phases/24-hoan-thien-nghiep-vu-tu-choi-tiep-nhan-vb-lien-thong-lgsp-st/`

### Phase 32: Audit & cập nhật toàn bộ HDSD (16 module)

**Mục tiêu:** Đối chiếu toàn bộ 16 file HDSD (~4400 dòng) với code hiện tại sau Phase 21 (LGSP foundation) + Phase 31 (fix-gom UI). Bổ sung mô tả luồng nghiệp vụ còn thiếu (đặc biệt: hậu quả khi Giao việc — VB xuất hiện ở đâu của TK được giao, có chuông bell không; luồng "Ban hành & Gửi" chi tiết — phân biệt internal vs LGSP, queue worker BullMQ, badge "Đang chờ worker đẩy LGSP"). Đồng bộ button/menu/field theo UI mới. Chụp lại toàn bộ screenshots bằng Playwright (script `tools/screenshots/capture-*` có sẵn). Merge tất cả file con thành `HDSD_full.md`. Export `HDSD_full.docx` bằng pandoc 3.9 (đã cài).

**Output:** 16 file `HDSD_*.md` updated + screenshots mới trong `docs/hdsd/screenshots/` + `HDSD_full.md` + `HDSD_full.docx` với ảnh embedded.

**Depends on:** Phase 31 (fix-gom UI đã commit — pull về 1c1c414)
**Plans:** 4/8 plans executed

Plans:
- [x] 32-01-PLAN.md — Audit toàn bộ 22 HDSD vs code → 32-AUDIT-REPORT.md (source of truth)
- [x] 32-02-PLAN.md — Update text 4 file VB (đến + đi + dự thảo + đánh dấu) + insert GAP 1/2/3
- [x] 32-03-PLAN.md — Update text HSCV + Dashboard + Thông báo + Cấu hình gửi nhanh
- [x] 32-04-PLAN.md — Update text 3 Ký số + Đăng nhập + HDSD_index.md
- [ ] 32-05-PLAN.md — Update text 8 Quản trị HDSD (đơn vị, chức vụ, người dùng, nhóm quyền, sổ VB, lĩnh vực, loại VB, người ký)
- [ ] 32-06-PLAN.md — Chụp lại screenshots Playwright (depends on dev servers running)
- [ ] 32-07-PLAN.md — Re-merge HDSD_full.md từ 20 file con
- [ ] 32-08-PLAN.md — Export HDSD_full.docx qua pandoc 3.9

**Phase directory:** `.planning/phases/32-hdsd-audit-update/`
