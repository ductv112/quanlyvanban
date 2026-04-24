# Requirements — v3.0 Chuẩn hoá quy trình văn bản

**Milestone:** v3.0
**Status:** Active (started 2026-04-23)
**Goal:** Chuẩn hoá data model 3 bảng văn bản (incoming/outgoing/drafting) đúng nghiệp vụ source .NET cũ — tách "Cơ quan ban hành" vs "Nơi gửi" vs "Nơi nhận", auto-sinh văn bản đến khi gửi nội bộ, real LGSP HTTP client thay mock, gộp menu Liên thông vào VB đến.

## v3.0 Requirements

### DM — Data Model Standardization (8 requirements)

- [ ] **DM-01:** Bảng `incoming_docs` thêm cột `source_type ENUM('internal','external_lgsp','manual')` để phân biệt nguồn gốc văn bản đến (thay thế bảng `inter_incoming_docs` riêng)
- [ ] **DM-02:** Bảng `incoming_docs` thêm `is_unit_send BOOLEAN` + `unit_send VARCHAR(500)` để phân biệt "Cơ quan ban hành" (publish_unit) vs "Nơi gửi" (unit_send)
- [ ] **DM-03:** Bảng `incoming_docs` thêm `previous_outgoing_doc_id BIGINT` (FK trỏ về `outgoing_docs.id`) để trace ngược văn bản đến nội bộ về văn bản đi gốc của đơn vị gửi
- [ ] **DM-04:** Bảng mới `outgoing_doc_recipients (outgoing_doc_id, recipient_type ENUM('internal_unit','external_org'), recipient_unit_id, recipient_org_id, sent_at, sent_status)` cho phép multi-recipient phân loại nội bộ vs ngoài
- [ ] **DM-05:** Bảng mới `inter_organizations (id, code, name, lgsp_organ_id, parent_id, is_active)` thay danh mục cơ quan LGSP cũ — dùng cho `outgoing_doc_recipients.recipient_org_id`
- [ ] **DM-06:** Bảng `drafting_docs` thêm `is_released BOOLEAN DEFAULT FALSE` + `released_date TIMESTAMPTZ` + `previous_outgoing_doc_id BIGINT` để track lifecycle drafting → outgoing
- [ ] **DM-07:** Bảng `drafting_docs` + `outgoing_docs` + `incoming_docs` thêm `approver VARCHAR(255)` + `approved BOOLEAN` + `approved_at TIMESTAMPTZ` cho 1 cấp duyệt boolean (như source .NET cũ)
- [ ] **DM-08:** Migration: drop bảng `inter_incoming_docs` + `attachment_inter_incoming_docs` riêng, gộp data về `incoming_docs` với `source_type='external_lgsp'` (reset DB clean — không preserve data v2.0)

### WF — Workflow Ban hành / Gửi (5 requirements)

- [ ] **WF-01:** Trang chi tiết `outgoing_docs` có 2 action riêng: "Ban hành" (set `is_released=true`, cấp số `number` từ doc_book) và "Gửi" (loop recipients → INSERT incoming hoặc đẩy LGSP queue)
- [ ] **WF-02:** SP `fn_outgoing_doc_release(p_outgoing_doc_id, p_user_id)` — validate prerequisites (đã ký, có signer/approver, status='draft'), cấp số tự động từ `doc_book`, set `is_released=true`
- [ ] **WF-03:** SP `fn_outgoing_doc_send(p_outgoing_doc_id, p_user_id)` — loop `outgoing_doc_recipients`: nếu `recipient_type='internal_unit'` → INSERT `incoming_docs` với `source_type='internal'` + `unit_send=` tên đơn vị gửi + `is_unit_send=true` + `previous_outgoing_doc_id`; nếu `recipient_type='external_org'` → INSERT `lgsp_tracking` queue
- [ ] **WF-04:** Trang chi tiết drafting có nút "Duyệt" / "Bỏ duyệt" — set `approved=true/false` + `approver=tên user` + `approved_at`. Validate `approved=true` mới cho phép "Ban hành"
- [ ] **WF-05:** Khi sửa drafting đã `is_released=true` → tạo OutgoingDoc mới với `previous_outgoing_doc_id` trỏ về Outgoing cũ (giữ lịch sử ban hành lại)

### LGSP — Real HTTP Client (5 requirements)

- [ ] **LGSP-01:** Implement `LGSPRealService` thay `lgsp-mock.service.ts` — OAuth2 flow tới `apiltvb.langson.gov.vn` (login + refresh token với cache 29 phút như source cũ `LgspTokenManager`)
- [ ] **LGSP-02:** Endpoint client: `POST /v1/sendEdoc` (gửi VB đi) + `GET /v1/getInbox` (nhận VB đến) + `GET /v1/getDocStatus/:id` (track status)
- [ ] **LGSP-03:** Worker BullMQ job `lgsp-send` — query `lgsp_tracking WHERE direction='send' AND status='pending'`, gọi LGSP `/v1/sendEdoc`, update `status='success'/'failed'`, lưu `lgsp_doc_id` response
- [ ] **LGSP-04:** Worker BullMQ job `lgsp-receive` — polling mỗi 60s gọi `/v1/getInbox`, nhận VB mới → INSERT `incoming_docs` với `source_type='external_lgsp'` + `external_doc_id=` LGSP doc id (skip duplicate)
- [ ] **LGSP-05:** Factory `lgsp.service.ts` switch: `MOCK_EXTERNAL=true` → mock service; `MOCK_EXTERNAL=false` + có `LGSP_ENDPOINT/LGSP_CLIENT_ID/LGSP_CLIENT_SECRET` → real service. Throw rõ ràng nếu thiếu config

### UI — UI Rewrite & Menu Consolidation (8 requirements)

- [ ] **UI-01:** Form drafting + outgoing thêm field "Đơn vị soạn thảo" (`drafting_unit_id` — dropdown Department) tách riêng với "Cơ quan ban hành" (`publish_unit_id` — dropdown Department, có thể chọn cấp trên)
- [ ] **UI-02:** Form drafting + outgoing thêm component "Nơi nhận" (recipient picker) — 2 tab "Đơn vị nội bộ" (multi-select tree từ `departments`) + "Cơ quan ngoài LGSP" (multi-select từ `inter_organizations`)
- [ ] **UI-03:** Trang chi tiết outgoing có 2 button riêng "Ban hành" (disabled nếu chưa ký + chưa duyệt) và "Gửi" (disabled nếu chưa ban hành) với confirm modal
- [ ] **UI-04:** Trang chi tiết drafting có button "Duyệt" / "Bỏ duyệt" + hiển thị badge "Đã duyệt by [tên] lúc [ngày]" hoặc "Chưa duyệt"
- [ ] **UI-05:** Form `incoming_docs`: tách rõ 3 field "Cơ quan ban hành" (publish_unit, text), "Nơi gửi" (unit_send, text), "Nơi nhận để xử lý" (recipients, text). Khi `source_type='internal'` → publish_unit + unit_send tự fill từ outgoing gốc
- [ ] **UI-06:** Bỏ menu sidebar "Văn bản liên thông" (`/van-ban-lien-thong`). Trang `/van-ban-den` thêm filter `source_type` (dropdown: Tất cả / Nội bộ / LGSP / Nhập tay) + badge tag màu khác nhau
- [ ] **UI-07:** Trang chi tiết `incoming_docs` với `source_type='external_lgsp'` hiển thị workflow recall (thu hồi LGSP, chuyển lại, hoàn thành) như cũ — không cần page `/van-ban-lien-thong/[id]` riêng nữa
- [ ] **UI-08:** Recipient picker có search realtime + tree expand đơn vị (cho internal) / search code+name (cho external_org)

### QA — Regression & UAT (3 requirements)

- [ ] **QA-01:** Regression test E2E: HSCV (workflow + KPI), ký số (4 tab), báo cáo, dashboard, lịch — tất cả không vỡ sau schema rebuild v3.0
- [ ] **QA-02:** UAT 3 luồng chính: (1) Sở A soạn → ban hành → gửi Sở B → Sở B thấy ở VB đến với đầy đủ field; (2) gửi LGSP outgoing → worker đẩy lên `apiltvb.langson.gov.vn` (mock nếu không có credentials); (3) nhận LGSP incoming → worker pull về INSERT incoming_docs
- [ ] **QA-03:** Reset DB clean với schema v3.0 + seed `001_required_data.sql` + seed `002_demo_data.sql` (rich demo) — admin login + 50+ VB demo sẵn sàng test trong 30s

## Future Requirements (v3.1+)

- Multi-level approval workflow (Trưởng phòng → Phó GĐ → Giám đốc) với `approval_chains` table — defer khi KH yêu cầu
- LGSP credentials production thật cho Lào Cai — defer khi có thông tin từ KH
- Audit log đầy đủ cho approval actions (who/when/why) trong MongoDB

## Out of Scope (v3.0)

- Migration data v2.0 → v3.0: reset DB clean (user approved 2026-04-23)
- Multi-tenant phân tán theo tỉnh: vẫn 1 deployment cho 1 tỉnh
- Mobile app native: vẫn responsive web only
- Tách menu lại sau khi gộp: cam kết 1 chiều, không revert

## Traceability

### Category summary

| Category | Count | Phase mapping |
|----------|-------|---------------|
| DM-* | 8 | DM-01..DM-08 → Phase 15-16 |
| WF-* | 5 | WF-01..WF-05 → Phase 17 |
| LGSP-* | 5 | LGSP-01..LGSP-05 → Phase 18 |
| UI-* | 8 | UI-01..UI-08 → Phase 19 |
| QA-* | 3 | QA-01..QA-03 → Phase 20 |
| **Total** | **29** | — |

### Chi tiết REQ → Phase

| Requirement | Phase | Status | Verify Evidence |
|-------------|-------|--------|-----------------|
| DM-01 | Phase 15-16 | Active | _TBD by phase planner_ |
| DM-02 | Phase 15-16 | Active | _TBD_ |
| DM-03 | Phase 15-16 | Active | _TBD_ |
| DM-04 | Phase 15-16 | Active | _TBD_ |
| DM-05 | Phase 15-16 | Active | _TBD_ |
| DM-06 | Phase 15-16 | Active | _TBD_ |
| DM-07 | Phase 15-16 | Active | _TBD_ |
| DM-08 | Phase 16 | Active | _TBD_ |
| WF-01 | Phase 17 | Active | _TBD_ |
| WF-02 | Phase 17 | Active | _TBD_ |
| WF-03 | Phase 17 | Active | _TBD_ |
| WF-04 | Phase 17 | Active | _TBD_ |
| WF-05 | Phase 17 | Active | _TBD_ |
| LGSP-01 | Phase 18 | Active | _TBD_ |
| LGSP-02 | Phase 18 | Active | _TBD_ |
| LGSP-03 | Phase 18 | Active | _TBD_ |
| LGSP-04 | Phase 18 | Active | _TBD_ |
| LGSP-05 | Phase 18 | Active | _TBD_ |
| UI-01 | Phase 19 | Active | _TBD_ |
| UI-02 | Phase 19 | Active | _TBD_ |
| UI-03 | Phase 19 | Active | _TBD_ |
| UI-04 | Phase 19 | Active | _TBD_ |
| UI-05 | Phase 19 | Active | _TBD_ |
| UI-06 | Phase 19 | Active | _TBD_ |
| UI-07 | Phase 19 | Active | _TBD_ |
| UI-08 | Phase 19 | Active | _TBD_ |
| QA-01 | Phase 20 | Active | _TBD_ |
| QA-02 | Phase 20 | Active | _TBD_ |
| QA-03 | Phase 20 | Active | _TBD_ |

### Phase load

| Phase | # REQs | Categories |
|-------|--------|------------|
| Phase 15 | 7 | DM (audit + design, derived from DM-01..DM-07) |
| Phase 16 | 8 | DM (rebuild schema) — implements DM-01..DM-08 |
| Phase 17 | 5 | WF (5) |
| Phase 18 | 5 | LGSP (5) |
| Phase 19 | 8 | UI (8) |
| Phase 20 | 3 | QA (3) |
| **Total** | **29** (DM counted once across Phase 15+16) | — |
