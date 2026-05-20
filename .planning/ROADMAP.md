# Roadmap: e-Office — Quản lý Văn bản điện tử

> **Xem thêm:** Chi tiết 17 sprints (SP, API, UI) tại `e_office_app_new/ROADMAP.md`

## Overview

Rebuild hệ thống quản lý văn bản điện tử (.NET cũ) thành stack mới (Next.js + Express + PostgreSQL).

## Milestones

- ✅ **v1.0 MVP** — Phases 1-7 (shipped 2026-04-18) — `.planning/milestones/v1.0-phases/`
- ✅ **v2.0 Tích hợp ký số 2 kênh** — Phases 8-14 + 11.1 (shipped 2026-04-23) — `.planning/milestones/v2.0-ROADMAP.md`
- ✅ **v3.0 Chuẩn hoá quy trình văn bản** — Phases 15-20 (shipped 2026-04-24) — `.planning/milestones/v3.0-ROADMAP.md`
- ✅ **v3.1 Manual Test Execution + Bug Fix** — Phases 21-32 (shipped 2026-05-19) — `.planning/milestones/v3.1-ROADMAP.md`
- 🚧 **v3.2 LGSP Production Go-live cho 6 DN Lạng Sơn** — Phases 33-37 (Active, started 2026-05-19)

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

<details>
<summary>✅ v3.1 Manual Test Execution + Bug Fix (Phases 21-32) — SHIPPED 2026-05-19</summary>

- [x] **Phase 21: Automation Foundation (INFRA)** — Test DB tách dev, 6 user fixture, 3 mock server, Vitest+Playwright+supertest, Excel sync tool
- [x] **Phase 22-30: Execute 847 TC qua 9 wave** — Manual test execution, RESULTS file mỗi wave, bug logged (90+ BUG fixed)
- [x] **Phase 31: Fix-gom UI** — 164+ commit bug fix ký số / phân quyền / menu / HSCV / setup KH Lạng Sơn
- [x] **Phase 32: HDSD audit + update** — 16 HDSD updated, 6 screenshots re-captured, HDSD_full.md (4496 dòng) + HDSD_full.docx (13.3MB, 82 ảnh)

Detail: `.planning/milestones/v3.1-phases/`, archive: `.planning/milestones/v3.1-ROADMAP.md`, helpers: `.planning/milestones/v3.1-helpers/`
</details>

### 🚧 v3.2 LGSP Production Go-live (Active — started 2026-05-19)

**Trigger:** Có credential thật từ tỉnh Lạng Sơn (6 SystemId + SecretKey + 3 sandbox) — tài liệu trong `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/`.

**Goal:** Wire toàn bộ LGSP API thật để 6 DN Lạng Sơn (6 đơn vị cấp cao trong cây `departments`) gửi/nhận VB **với đơn vị NGOÀI hệ thống** qua trục liên thông tỉnh `apiltvb.langson.gov.vn`. 6 DN ↔ 6 DN vẫn dùng flow nội bộ (Phase 17 v3.0) — KHÔNG qua LGSP.

**Kiến trúc cốt lõi:**
- 1 deploy / 1 DB / 6 DN = 6 root unit trong cây `departments` (KHÔNG dùng từ "multi-tenant")
- `lgsp_agency_config` per `unit_id` + `getLgspService(unit_id)` lookup credential động
- Routing tự động theo `outgoing_doc_recipients.recipient_type`: `internal_unit` → nội bộ, `external_org` → LGSP
- Roll-out qua toggle `is_active` per row trong `lgsp_agency_config` — KHÔNG cần deploy/restart

**Summary phases:**

- [ ] **Phase 33: Database + Core Infrastructure** — Schema `lgsp_agency_config` per-unit + `lgsp_org_code` cột + outbox + `getLgspService()` lookup + seed 9 row
- [ ] **Phase 34: Send Flow (sendEdoc)** — edXML builder + routing internal/external + worker send + error mapping + UI badge
- [ ] **Phase 35: Receive Flow (cron syncReceivedEdocList)** — Cron loop 6 DN + parser edXML + INSERT incoming_docs dedup + attachments MinIO + tracking
- [ ] **Phase 36: Status Callback Chain (9 mã QĐ 28)** — Outbox worker poll + auto fire 03/04/05/06 + refactor "Chuyển lại" → "Từ chối tiếp nhận" (02) + Lấy lại 13/15/16 + UI tag trạng thái
- [ ] **Phase 37: Admin UI + Catalog + Go-live** — `/quan-tri/lgsp-config` CRUD + test connection + Catalog `inter_organizations` + gỡ hidden-routes + Wave 1/2 roll-out

## Phase Details

### Phase 33: Database + Core Infrastructure
**Goal:** Hạ tầng schema + service lookup credential per-unit sẵn sàng cho các phase wire LGSP thật. Sau phase này, admin có thể seed 9 row credential (6 prod + 3 sandbox) và backend resolve được service LGSP đúng cho mỗi sender unit.
**Depends on:** Phase 18 v3.0 (`LGSPRealService` OAuth2 + REST client) + Phase 17 v3.0 (`outgoing_doc_recipients` table + recipient_type column)
**Estimated:** 2 ngày
**Requirements:** LGSP-CRED-01, LGSP-CRED-02, LGSP-CRED-03, LGSP-CRED-04, LGSP-CRED-05, LGSP-STATUS-01
**Success Criteria** (what must be TRUE):
  1. `psql` chạy `\d lgsp_agency_config` thấy bảng đủ cột (`unit_id`, `environment`, `system_id`, `secret_key_encrypted`, `base_url`, `is_active`, `last_synced_at`) + UNIQUE(`unit_id`, `environment`)
  2. `\d departments` thấy cột `lgsp_org_code VARCHAR(13)` đã add (NULL cho non-LGSP unit, có giá trị H37.DN.001..006 cho 6 root unit)
  3. Seed `seed/002_demo_data.sql` insert 9 row (6 prod + 3 sandbox với `is_active=FALSE`), `client_secret` encrypted bằng `pgp_sym_encrypt` với `SIGNING_SECRET_KEY` (verify decrypt OK qua test SP)
  4. Backend service `getLgspService(unit_id)` test: input user thuộc subtree unit nào → trace root → trả về `LGSPRealService` instance với credential đúng; cache LRU 5 phút hit lần 2; throw error nếu root unit không có credential active
  5. Bảng `lgsp_status_outbox` tồn tại với đủ cột (`incoming_doc_id`, `target_status`, `payload`, `sent_status`, `retry_count`, `error_message`) sẵn sàng cho Phase 36 worker consume
**Plans:** 2/5 plans executed
  - [x] 33-01-PLAN.md — Schema infra (lgsp_agency_config + lgsp_status_outbox + departments.lgsp_org_code + trigger validate root)
  - [x] 33-02-PLAN.md — Seed 9 row placeholder + UPDATE 6 root unit lgsp_org_code (user checkpoint mapping)
  - [ ] 33-03-PLAN.md — 11 SPs + 2 repository (lgsp-agency-config + lgsp-status-outbox)
  - [ ] 33-04-PLAN.md — Refactor LGSPRealService constructor inject + factory getLgspService(unit_id) + cache + invalidate
  - [ ] 33-05-PLAN.md — Final verification (TypeScript + idempotent re-apply + E2E smoke test + user approval)

### Phase 34: Send Flow (sendEdoc)
**Goal:** Khi văn thư bấm "Gửi" VB đi với recipient `external_org`, hệ thống tự build edXML đúng spec QĐ 28, gọi `POST /v1/sendEdoc` qua credential của DN gửi, và hiển thị tracking inline. Recipient `internal_unit` (6 DN với nhau) vẫn dùng flow nội bộ — không qua LGSP.
**Depends on:** Phase 33
**Estimated:** 3 ngày
**Requirements:** LGSP-SEND-01, LGSP-SEND-02, LGSP-SEND-03, LGSP-SEND-04, LGSP-SEND-05, LGSP-SEND-06
**Success Criteria** (what must be TRUE):
  1. Văn thư DN.001 (sandbox active) tạo VB đi với recipient mix (3 internal_unit DN.002+003+004 + 2 external_org từ catalog `inter_organizations`) → bấm "Gửi" → backend tự phân loại: 3 internal auto-sinh `incoming_docs` cho 3 DN nội bộ (flow Phase 17), 2 external enqueue LGSP send job
  2. Worker `lgsp-send.ts` consume job → lookup credential qua `getLgspService(sender_unit_id)` → build edXML có đầy đủ MessageHeader (From + To + Code + PromulgationInfo + DocumentType + Subject + SignerInfo + OtherInfo + DocumentId + TraceHeaderList) + attachment base64 trong Manifest → POST sandbox `apiltvb.langson.gov.vn/v1/sendEdoc` thành công, lưu `lgsp_tracking.lgsp_doc_id` trả về
  3. Postman collection trong `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/` import + chạy `getEdoc?docId=<id vừa send>` từ phía recipient sandbox → nhận lại edXML khớp với gì đã gửi (verify E2E)
  4. Khi gửi lỗi (VD: secret_key sai), backend map 9 ErrorCode LGSP (0/10/15/18/19/20/21/22/23) thành Vietnamese message, lưu `lgsp_tracking.error_message`, hiển thị inline VB đi chi tiết: "Lỗi gửi LGSP: Sai SystemId hoặc SecretKey (Code 15)"
  5. UI VB đi chi tiết hiển thị badge per-recipient: 3 internal "Đã gửi nội bộ", 2 external "Đang chờ worker đẩy LGSP" → sau worker chạy thành công đổi "Đã gửi LGSP" (xanh) hoặc "Lỗi gửi LGSP: ..." (đỏ) — extend tracking inline đã có Phase 19 v3.0
**Plans:** TBD
**UI hint**: yes

### Phase 35: Receive Flow (cron syncReceivedEdocList)
**Goal:** Mỗi 5 phút, cron worker loop tất cả 6 DN có `is_active=TRUE`, gọi `/v1/syncReceivedEdocList` lấy danh sách VB mới, tải edXML qua `/v1/getEdoc`, parse + INSERT vào `incoming_docs` với dedup. Văn thư của 6 DN sẽ thấy VB từ trục xuất hiện trong tab "Văn bản đến" trong vòng 5 phút sau khi đơn vị ngoài gửi.
**Depends on:** Phase 33
**Estimated:** 3 ngày
**Requirements:** LGSP-RECV-01, LGSP-RECV-02, LGSP-RECV-03, LGSP-RECV-04, LGSP-RECV-05, LGSP-RECV-06, LGSP-RECV-07
**Success Criteria** (what must be TRUE):
  1. Worker `lgsp-receive.ts` đăng ký BullMQ repeat job mỗi 5 phút khi backend start, log `pino` mỗi vòng với số `agency_count` + `docs_synced`; dừng worker → cron stop, restart → cron resume
  2. E2E sandbox test: dùng Postman gửi 1 edXML từ DN sandbox khác đến DN.001 sandbox của hệ thống → trong vòng ≤ 5 phút (hoặc trigger manual qua "Force sync now" Phase 37), VB xuất hiện trong tab "Văn bản đến" của user DN.001 với `source='LGSP'`, `lgsp_sender_org_code` từ MessageHeader.From.OrganId
  3. Attachment encoded base64 trong edXML decode đúng → upload MinIO bucket `documents` → user click "Tải về" trong VB đến chi tiết tải được file gốc (test với file PDF + DOCX)
  4. Dedup test: gửi cùng 1 edXML 2 lần (cùng `lgsp_doc_id`) → cron loop 2 vòng → DB chỉ có 1 row `incoming_docs` (UNIQUE constraint `lgsp_doc_id` chặn duplicate)
  5. Sau mỗi vòng cron thành công, `lgsp_agency_config.last_synced_at` được update; nếu fail (VD: trục lỗi 500), log vào `lgsp_tracking` với `error_message`, `last_synced_at` GIỮ NGUYÊN giá trị cũ để vòng sau retry từ điểm dừng
**Plans:** TBD

### Phase 36: Status Callback Chain (9 mã QĐ 28)
**Goal:** Mỗi khi văn thư/lãnh đạo/chuyên viên thực hiện hành động trên VB nguồn LGSP (tiếp nhận, phân công, xử lý, hoàn thành, từ chối tiếp nhận, lấy lại), hệ thống tự enqueue outbox event và worker poll mỗi 30s đẩy `POST /v1/updateStatus` lên trục với credential đúng. Đơn vị gửi biết trạng thái xử lý real-time qua trục.
**Depends on:** Phase 33
**Estimated:** 3 ngày
**Requirements:** LGSP-STATUS-02, LGSP-STATUS-03, LGSP-STATUS-04, LGSP-STATUS-05, LGSP-STATUS-06, LGSP-STATUS-07, LGSP-STATUS-08, LGSP-STATUS-09, LGSP-STATUS-10
**Success Criteria** (what must be TRUE):
  1. E2E test status 03→04→05→06: văn thư DN.001 bấm "Tiếp nhận" VB LGSP → outbox INSERT status `03`; lãnh đạo bấm "Tạo và giao việc" → outbox INSERT status `04`; chuyên viên bấm "Bắt đầu xử lý" trên HSCV → outbox INSERT status `05`; HSCV đóng `completed` (hoặc ban hành VB trả lời) → outbox INSERT status `06`. Worker poll 30s đẩy lần lượt lên trục, đơn vị gửi sandbox `GET /v1/getReceiveStatus` thấy đủ 4 mốc.
  2. Refactor DEFER-07 v3.1 hoàn tất: SP `edoc.fn_incoming_doc_return` rename → `edoc.fn_incoming_doc_reject_intake`, set `lgsp_status='02'` + insert outbox event; route `POST /van-ban-den/:id/chuyen-lai` redirect 301 → `/tu-choi-tiep-nhan`; UI button đổi label "Chuyển lại" → "Từ chối tiếp nhận", modal title + placeholder cập nhật theo, smoke test văn thư từ chối VB LGSP → trục nhận status 02
  3. E2E Lấy lại flow: DN.001 sandbox gửi VB đến DN ngoài → bấm "Lấy lại VB" → outbox INSERT status `13`; recipient sandbox đồng ý (UI quyết định 15/16) → trục push status `15` về → backend update `lgsp_tracking`. Test cả 16 (từ chối lấy lại).
  4. Worker `lgsp-status-sync.ts` exponential backoff verified: kill trục giả lập lỗi → worker retry 1m → 5m → 30m → 2h → 6h (timestamp log); sau 5 lần max → `sent_status='error'`, không loop infinit. Restart trục → manual re-trigger thành công.
  5. UI VB đến + VB đi nguồn LGSP hiển thị tag trạng thái cuối cùng (01/02/03/04/05/06/13/15/16) với màu phân biệt (xanh lá `06`, đỏ `02/16`, vàng `03/04/05`, xám `13`, xanh `15`) + tooltip Vietnamese name đầy đủ ("Đã tiếp nhận", "Từ chối tiếp nhận", ...) — hover ra tooltip + tap ra full label
**Plans:** TBD
**UI hint**: yes

### Phase 37: Admin UI + Catalog + Go-live
**Goal:** Admin có UI tự cấu hình credential per-unit + test connection trước khi bật, có catalog đơn vị ngoài để chọn khi gửi VB external, menu LGSP hiện lại trên sidebar, và hệ thống sẵn sàng roll-out Wave 1 (DN.001/002/003 sandbox) → Wave 2 (DN.004/005/006 prod) qua toggle `is_active` per row mà không cần deploy/restart.
**Depends on:** Phase 33, Phase 34, Phase 35, Phase 36
**Estimated:** 3 ngày
**Requirements:** LGSP-UI-01, LGSP-UI-02, LGSP-UI-03, LGSP-UI-04, LGSP-UI-05, LGSP-UI-06, LGSP-UI-07, LGSP-UI-08
**Success Criteria** (what must be TRUE):
  1. Admin login → `/quan-tri/lgsp-config` thấy bảng list 9 row (6 prod + 3 sandbox), Drawer 720 Add/Edit theo pattern admin pages khác với form: Select root unit (chỉ 6 DN), Radio environment, Input base_url, Input system_id, Input.Password secret_key (mask), Switch is_active, Input lgsp_org_code (H37.DN.001..006); save → DB updated, secret encrypted lại
  2. Test connection button: nhập credential vào form → bấm "Test kết nối" → backend `POST /api/lgsp-config/test-connection` ping `/v1/auth/login` với credential trong form (không lưu DB) → hiển thị inline "OK — kết nối thành công" (xanh) hoặc "Lỗi: Sai SystemId/SecretKey" (đỏ); chỉ cho save khi test PASS
  3. Force sync now button hiển thị cạnh mỗi row + `last_synced_at` từ cron → bấm → enqueue ngay job LGSP-RECV (không chờ 5 phút) → trong ≤ 10 giây thấy VB mới (nếu có) trong `incoming_docs`
  4. Trang `/quan-tri/inter-organizations` CRUD đơn vị ngoài (code, name, parent_id, address, mail) Drawer 720; button "Sync danh sách từ trục" gọi `GET /v1/getAgenciesList` qua credential DN active đầu tiên → batch INSERT/UPDATE thành công (verify count tăng); file `frontend/src/config/hidden-routes.ts` đã gỡ `/lgsp` + `/lgsp/co-quan` khỏi `HIDDEN_ROUTES` Set → sidebar hiển thị menu Liên thông
  5. Roll-out verification: Wave 1 ready — bật `is_active=TRUE` cho 3 row sandbox DN.001/002/003 qua UI → 3 DN này thấy VB LGSP trong tab VB đến + gửi được external; 3 row prod còn lại + 3 row sandbox còn lại `is_active=FALSE` → KHÔNG ảnh hưởng. Verify tracking inline VB đi (Phase 19 v3.0) + 5 trạng thái badge (`pending`/`success`/`error`/`đã gửi LGSP`/`lỗi gửi LGSP`) còn hoạt động — không regression flow nội bộ Phase 17.
**Plans:** TBD
**UI hint**: yes

## Progress

| Phase range | Milestone | Status | Completed |
|-------------|-----------|--------|-----------|
| 1-7 | v1.0 | Complete | 2026-04-14 → 2026-04-18 |
| 8-14 + 11.1 | v2.0 | Complete | 2026-04-21 → 2026-04-23 |
| 15-20 | v3.0 | Complete | 2026-04-23 → 2026-04-24 |
| 21-32 | v3.1 | Complete | 2026-05-05 → 2026-05-19 |
| 33 | 2/5 | In Progress|  |
| 34 | v3.2 — Send Flow | Not started | — |
| 35 | v3.2 — Receive Flow | Not started | — |
| 36 | v3.2 — Status Callback Chain | Not started | — |
| 37 | v3.2 — Admin UI + Catalog + Go-live | Not started | — |
