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
**Plans:** TBD — chạy `/gsd-plan-phase 21` khi sẵn sàng.
**Phase directory:** `.planning/phases/21-automation-foundation/`
**UI hint:** yes

### Phase 22: Regression Backbone
**Goal:** Mỗi đêm 00:00 ICT chạy được toàn bộ regression Wave a-g (815/847 TC) < 45 phút và file Excel kết quả + Slack summary tự động về tay QA lead trước giờ làm.
**Depends on:** Phase 21 (test infrastructure + mock servers + Excel parser MVP + CI workflow `test-pr.yml`)
**Estimated:** 5 working days
**Requirements (16):** REG-01, REG-02, REG-03, REG-04, REG-05, REG-06, REG-07, REG-08, REG-09, REG-10, CI-03, CI-04, RPT-02, RPT-03, RPT-04, RPT-06
**Success criteria** (what must be TRUE):
  1. Nightly job `test-nightly.yml` (cron `0 17 * * *` UTC = 00:00 ICT) chạy 815 TC Wave a-g hoàn tất < 45 phút trên `ubuntu-latest`; chạy 7 đêm liên tiếp đều xanh.
  2. Pyramid phân bố thực tế đo bằng đếm `test()` block: 50 unit ± 10% / 464 integration ± 10% / 383 E2E ± 10%; lint check title `^TC-[A-Z0-9-]+` chạy trong CI và fail nếu có test thiếu TC-ID.
  3. File `<YYYYMMDD>_Testcase_QLVB_V2_results.xlsx` được commit vào branch `test-results/<YYYYMMDD>` mỗi đêm; cột `Trạng thái` / `Run date` / `Duration` / `Error msg` đầy đủ cho 815 dòng; TC-ID test có nhưng không có trong Excel → cảnh báo "TC chưa tracking", TC trong Excel không có test → đánh "Not run".
  4. Coverage report cuối nightly print đúng số liệu: tổng 847 TC, auto coverage % thực tế, hybrid count, "Not run" count với lý do (HYBRID weekly hay missing automation).
  5. Slack `#qlvb-qa` nhận message tự động vào 00:00 ICT mỗi ngày: total / pass / fail / skip / duration / link Excel artifact; nightly fail → alert kèm link artifact để QA truy lỗi sáng hôm sau.
  6. Flaky rate < 1% sau 7 nightly liên tiếp; test fail không reproducible bị tag `@flaky` và quarantine ra khỏi gate, không che fail thật.
**Plans:** TBD — chạy `/gsd-plan-phase 22` khi sẵn sàng.
**Phase directory:** `.planning/phases/22-regression-backbone/`
**UI hint:** yes

### Phase 23: E2E + Concurrent + Hybrid
**Goal:** Coverage cuối milestone đạt 100% (843 auto + 4 hybrid weekly) — bao gồm full luồng VB đến → giao việc → ký số → phát hành VB đi, race condition đa tab, perf k6, và 1 lần/tuần test thật trên staging với SmartCA/LGSP real.
**Depends on:** Phase 22 (regression baseline xanh, mock fidelity validated, Excel parser ổn định)
**Estimated:** 3 working days
**Requirements (10):** E2E-01, E2E-02, E2E-03, E2E-04, E2E-05, E2E-06, E2E-07, CI-05, CI-08, RPT-05
**Success criteria** (what must be TRUE):
  1. 17/19 TC Wave h (E2E flow) chạy auto với mock — luồng "VB đến → giao việc → tạo dự thảo → ký số → phát hành VB đi" pass đầu cuối; TC-E2E-EXT-004 dừng MinIO container runtime → backend trả 503 + form data giữ nguyên.
  2. 10/13 TC Wave i concurrent chạy được với Playwright multi-context (2 user cùng edit 1 record race condition, multi-tab session); concurrent test chạy `workers: 1` để không nhiễu shared runner.
  3. Workflow `test-weekly-hybrid.yml` (cron `0 18 * * 1` UTC = Thứ Hai 01:00 ICT) chạy 4 TC trên staging với credentials thật từ secret store: TC-E2E-EXT-001 (SmartCA real handshake) + TC-E2E-EXT-003 (LGSP real submit) + TC-CONC-PERF-001/002/003 (k6 ramp-up 100 vUser/30s, gate p95 < 800ms).
  4. 110 TC UI category có visual snapshot baseline trong `tests/__snapshots__/`; diff > 0.1% pixel báo fail; fail trong CI tự động upload Playwright trace + screenshot + video làm artifact, retain 7 ngày, link trace gắn vào PR comment.
  5. Coverage cuối nightly = 100% (843 auto + 4 hybrid weekly = 847/847 TC); auto coverage drop < 95% bất kỳ đêm nào → Slack alert đỏ tag QA lead trong vòng 1 giờ sau nightly kết thúc.
**Plans:** TBD — chạy `/gsd-plan-phase 23` khi sẵn sàng.
**Phase directory:** `.planning/phases/23-e2e-concurrent-hybrid/`
**UI hint:** yes

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
