# Requirements — Milestone v3.2 LGSP Production Go-live cho 6 DN Lạng Sơn

**Milestone:** v3.2
**Status:** Active (started 2026-05-19)
**Goal:** Wire toàn bộ LGSP API thật để 6 DN Lạng Sơn (6 đơn vị cấp cao trong cây `departments` của hệ thống `doanhnghiep.vatk.org`) gửi/nhận VB **với các đơn vị NGOÀI hệ thống** qua trục liên thông tỉnh `apiltvb.langson.gov.vn`. Giao tiếp giữa 6 DN với nhau vẫn dùng flow nội bộ — KHÔNG qua LGSP.

**Routing rule (chốt 2026-05-19):**

| Sender → Recipient | Cách xử lý |
|---|---|
| 6 DN ↔ 6 DN (cả 2 trong `departments`) | Internal flow (Phase 17 v3.0 đã có) |
| 6 DN → đơn vị ngoài (`external_org`) | LGSP `sendEdoc` với credential của DN gửi |
| Đơn vị ngoài → 1 trong 6 DN | LGSP cron sync với credential của DN nhận |

Phân loại tự động theo `outgoing_doc_recipients.recipient_type` — KHÔNG hỏi user.

**Spec tham khảo:**
- Tài liệu: `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/` (HDSD v2.2 PDF + Postman collection + 6 credential Excel + List.txt prod/sandbox endpoint)
- Chuẩn nghiệp vụ: Quyết định 28/2018/QĐ-TTg (mã định danh + 9 mã trạng thái)
- Code reference: Phase 18 v3.0 `LGSPRealService` (OAuth2 + REST → `apiltvb.langson.gov.vn`)

---

## v3.2 Requirements (36 REQ-IDs / 5 categories)

### LGSP-CRED — Credential Management theo Đơn vị (5 reqs)

- [x] **LGSP-CRED-01**: Schema — Bảng `lgsp_agency_config` (`id, unit_id BIGINT NOT NULL FK→departments(id), environment ENUM('sandbox','prod'), system_id VARCHAR(13), secret_key_encrypted TEXT, base_url, is_active BOOLEAN DEFAULT FALSE, last_synced_at TIMESTAMPTZ, created_at, updated_at`) + UNIQUE(`unit_id`, `environment`)
- [x] **LGSP-CRED-02**: Schema — Cột `lgsp_org_code VARCHAR(13)` trong `departments` (NULL cho non-LGSP unit) — chỉ root unit của 6 DN có giá trị (H37.DN.001..006)
- [x] **LGSP-CRED-03**: Backend — Service `getLgspService(unit_id)` trace user → root unit → lookup credential, cache LRU 5 phút
- [x] **LGSP-CRED-04**: Backend — `secret_key` encrypted bằng `pgcrypto.pgp_sym_encrypt` với `SIGNING_SECRET_KEY` (pattern đã dùng cho `signing_provider_config`)
- [x] **LGSP-CRED-05**: Seed — 6 row prod + 3 row sandbox với credential từ Excel + List.txt (DN.001/002/003 sandbox, DN.004/005/006 prod-only), `is_active=FALSE` mặc định

### LGSP-SEND — Gửi VB đi qua trục (6 reqs)

- [x] **LGSP-SEND-01**: Builder — Module `lib/lgsp/edxml-builder.ts` build edXMLEnvelope đúng spec QĐ 28 (MessageHeader: From + To + Code + PromulgationInfo + DocumentType + Subject + SignerInfo + OtherInfo + DocumentId + TraceHeaderList)
- [x] **LGSP-SEND-02**: Builder — Hỗ trợ attachment encode base64 trong edXML body + Manifest references
- [x] **LGSP-SEND-03**: Routing — Trong flow `Ban hành & Gửi`, phân loại recipient từ `outgoing_doc_recipients.recipient_type`: `internal_unit` → flow nội bộ Phase 17, `external_org` → enqueue LGSP send job
- [x] **LGSP-SEND-04**: Worker — `workers/src/lgsp-send.ts` extend: lookup credential theo sender's root unit, build edXML, gọi `POST /v1/sendEdoc` multipart, update `lgsp_tracking.lgsp_doc_id` + sent_status
- [x] **LGSP-SEND-05**: Error mapping — Map 9 ErrorCode LGSP (0/10/15/18/19/20/21/22/23) thành Vietnamese message hiển thị inline VB đi
- [x] **LGSP-SEND-06**: UI — Badge "Đang chờ worker đẩy LGSP" → "Đã gửi LGSP" / "Lỗi gửi LGSP: <msg>" inline VB đi chi tiết (extend tracking inline đã có Phase 19 v3.0)

### LGSP-RECV — Nhận VB đến từ trục (7 reqs)

- [x] **LGSP-RECV-01**: Cron — `workers/src/lgsp-receive.ts` chạy mỗi 5 phút (BullMQ repeat job), loop tất cả `lgsp_agency_config.is_active=TRUE`
- [x] **LGSP-RECV-02**: API call — Mỗi vòng gọi `GET /v1/syncReceivedEdocList?messageType=edoc&fromDate=<last_synced>&toDate=<now>` với credential của đơn vị đó
- [x] **LGSP-RECV-03**: API call — Loop từng `docId` mới → `GET /v1/getEdoc?docId=` lấy base64 edXML payload
- [x] **LGSP-RECV-04**: Parser — Module `lib/lgsp/edxml-parser.ts` parse edXML → extract MessageHeader + Manifest + attachments base64
- [x] **LGSP-RECV-05**: INSERT — Tạo `incoming_docs` với `source='LGSP'`, `unit_id`=đơn vị nhận, `lgsp_doc_id` (UNIQUE constraint dedup), `lgsp_sender_org_code` từ MessageHeader.From.OrganId
- [x] **LGSP-RECV-06**: Attachments — Decode base64 → upload MinIO bucket `documents` → INSERT `incoming_doc_attachments`
- [x] **LGSP-RECV-07**: Tracking — Update `lgsp_agency_config.last_synced_at` sau mỗi vòng thành công + log errors vào `lgsp_tracking`

### LGSP-STATUS — Status callback chain (9 mã QĐ 28) (10 reqs)

- [x] **LGSP-STATUS-01**: Schema — Bảng `lgsp_status_outbox` (`id, incoming_doc_id, target_status VARCHAR(2), payload JSONB, sent_at, sent_status ENUM('pending','success','error'), retry_count INT DEFAULT 0, error_message TEXT, created_at`) — outbox pattern cho async LGSP callback
- [x] **LGSP-STATUS-02**: Backend — Auto fire status `03` "Đã tiếp nhận" khi văn thư bấm "Tiếp nhận" VB đến nguồn LGSP
- [x] **LGSP-STATUS-03**: Backend — Auto fire status `04` "Phân công" khi lãnh đạo bấm "Tạo và giao việc" trên VB LGSP
- [x] **LGSP-STATUS-04**: Backend — Auto fire status `05` "Đang xử lý" khi chuyên viên có activity đầu tiên trên HSCV (bấm "Bắt đầu xử lý" hoặc upload file/comment đầu tiên)
- [x] **LGSP-STATUS-05**: Backend — Auto fire status `06` "Hoàn thành" khi đóng HSCV (đặt status `completed`) hoặc khi ban hành VB trả lời referencing VB LGSP gốc
- [x] **LGSP-STATUS-06**: Refactor — Rename SP `edoc.fn_incoming_doc_return` → `edoc.fn_incoming_doc_reject_intake`, set `lgsp_status='02'`, ghi outbox event (= DEFER-07 từ v3.1); rename route `POST /van-ban-den/:id/chuyen-lai` → `/tu-choi-tiep-nhan` (giữ alias 301 redirect 1 sprint)
- [x] **LGSP-STATUS-07**: Frontend — Đổi nút "Chuyển lại" → "Từ chối tiếp nhận" (icon RollbackOutlined giữ), Modal title "Lý do chuyển lại" → "Lý do từ chối tiếp nhận", placeholder mới
- [x] **LGSP-STATUS-08**: Lấy lại flow — Status `13` (đơn vị gửi lấy lại VB đã gửi) + `15` (recipient đồng ý lấy lại) + `16` (recipient từ chối lấy lại). UI thêm nút "Lấy lại VB" trong VB đi đã gửi LGSP + UI cho recipient quyết định 15/16
- [x] **LGSP-STATUS-09**: Worker — `workers/src/lgsp-status-sync.ts` poll `lgsp_status_outbox` mỗi 30s → gọi `POST /v1/updateStatus` với credential đúng → exponential backoff (1m, 5m, 30m, 2h, 6h), max retry 5
- [x] **LGSP-STATUS-10**: UI — Hiển thị tag trạng thái LGSP (01/02/03/04/05/06/13/15/16) với màu phân biệt + tooltip Vietnamese name trên chi tiết VB đến + VB đi LGSP

### LGSP-UI — Admin UI cấu hình + bật lại menu (8 reqs)

- [ ] **LGSP-UI-01**: Trang `/quan-tri/lgsp-config` CRUD per-unit credential — bảng list 6 row × 2 env (prod/sandbox), Drawer 720 cho Add/Edit (theo pattern admin pages khác)
- [ ] **LGSP-UI-02**: Form Drawer — Select đơn vị cấp cao (từ root departments), Radio environment (sandbox/prod), Input `base_url`, Input `system_id`, Input.Password `secret_key` (mask), Switch `is_active`, Input `lgsp_org_code` (H37.DN.001..006)
- [ ] **LGSP-UI-03**: Test connection button — gọi backend `POST /api/lgsp-config/test-connection` ping `/v1/auth/login` với credential trong form, hiển thị OK / Error inline (KHÔNG save credential nếu test fail)
- [ ] **LGSP-UI-04**: Hiển thị `last_synced_at` từ cron + button "Force sync now" để trigger ngoài cron (queue job LGSP-RECV-01 immediate)
- [ ] **LGSP-UI-05**: Catalog `inter_organizations` admin CRUD — trang `/quan-tri/inter-organizations`, bảng list + Drawer 720 thêm/sửa đơn vị ngoài (code, name, parent_id, address, mail)
- [ ] **LGSP-UI-06**: Catalog sync — Button "Sync danh sách từ trục" gọi `GET /v1/getAgenciesList` → batch INSERT/UPDATE `inter_organizations` với credential của 1 trong 6 DN active
- [ ] **LGSP-UI-07**: Gỡ `/lgsp` + `/lgsp/co-quan` khỏi `hidden-routes.ts` → menu sidebar hiển thị lại (Phase 19 v3.0 đã có UI, chỉ ẩn menu)
- [ ] **LGSP-UI-08**: Verify regression — Tracking dashboard inline VB đi (Phase 19 v3.0) + 5 trạng thái badge (`pending`/`success`/`error`/`đã gửi LGSP`/`lỗi gửi LGSP`) còn hoạt động sau wire LGSP thật

---

## Future Requirements (defer v3.3+)

- [ ] **LGSP-AUTO-SYNC-CRON**: Auto-sync danh mục `inter_organizations` theo lịch (cron daily) thay vì manual button
- [ ] **LGSP-DLQ**: Dead letter queue cho failed status callback sau exponential backoff 5 lần → MongoDB collection `lgsp_dlq` để admin re-trigger
- [ ] **LGSP-AUDIT-LOG**: MongoDB collection `lgsp_audit` cho mọi API call (forensics debug)
- [ ] **LGSP-BUSINESS-DOC**: Recall/Update/Replace flow (`edXML:Bussiness` type 1/2/3 — Thu hồi / Cập nhật / Thay thế VB đã gửi)
- [ ] **LGSP-LARGE-ATTACH**: Hỗ trợ chunked upload cho file > 50MB + encrypted attachment per spec
- [ ] **LGSP-METRICS**: Prometheus metrics LGSP call rate / error rate / retry count + Grafana dashboard
- [ ] **LGSP-SIGNATURE**: Ký số gói tin edXML (XMLDSig RSA-SHA1 theo spec section 3) — hiện chưa cần vì trục Lạng Sơn không enforce
- [ ] **HDSD-REFRESH-2**: Re-audit + re-capture ~80 screenshots + re-merge HDSD_full.docx (user sẽ tự yêu cầu khi cần)

---

## Out of Scope (v3.2)

- **HDSD full refresh** — user quyết định defer ra ngoài milestone, sẽ tự yêu cầu sau
- **Auto-sync `inter_organizations` từ trục theo lịch** — v3.2 chỉ làm CRUD manual + button sync, defer auto cron sang v3.3+
- **E2E test automation cho LGSP flow** — mock LGSP server đã có từ Phase 21, dùng manual test thật với 3 sandbox DN
- **Multi-language LGSP UI** — chỉ tiếng Việt
- **Mobile responsive LGSP config UI** — admin desktop-only
- **Multi-level approval LGSP-side** — vẫn 1 cấp duyệt như nội bộ
- **Onboarding doc/HDSD per-DN** — defer cho phase HDSD refresh sau
- **Ký số gói tin edXML (XMLDSig)** — trục Lạng Sơn không enforce, để Future
- **Replace/Update/Recall flow** (edXML Bussiness type 1/2/3) — chỉ làm "send new" + "lấy lại" (status 13), defer "update existing" sang v3.3+

---

## Traceability

Phase mapping — every REQ-ID assigned to exactly one phase. Coverage: **36/36 ✓**

| REQ-ID | Phase | Phase Name |
|---|---|---|
| LGSP-CRED-01 | 33 | Database + Core Infrastructure |
| LGSP-CRED-02 | 33 | Database + Core Infrastructure |
| LGSP-CRED-03 | 33 | Database + Core Infrastructure |
| LGSP-CRED-04 | 33 | Database + Core Infrastructure |
| LGSP-CRED-05 | 33 | Database + Core Infrastructure |
| LGSP-SEND-01 | 34 | Send Flow (sendEdoc) |
| LGSP-SEND-02 | 34 | Send Flow (sendEdoc) |
| LGSP-SEND-03 | 34 | Send Flow (sendEdoc) |
| LGSP-SEND-04 | 34 | Send Flow (sendEdoc) |
| LGSP-SEND-05 | 34 | Send Flow (sendEdoc) |
| LGSP-SEND-06 | 34 | Send Flow (sendEdoc) |
| LGSP-RECV-01 | 35 | Receive Flow (cron syncReceivedEdocList) |
| LGSP-RECV-02 | 35 | Receive Flow (cron syncReceivedEdocList) |
| LGSP-RECV-03 | 35 | Receive Flow (cron syncReceivedEdocList) |
| LGSP-RECV-04 | 35 | Receive Flow (cron syncReceivedEdocList) |
| LGSP-RECV-05 | 35 | Receive Flow (cron syncReceivedEdocList) |
| LGSP-RECV-06 | 35 | Receive Flow (cron syncReceivedEdocList) |
| LGSP-RECV-07 | 35 | Receive Flow (cron syncReceivedEdocList) |
| LGSP-STATUS-01 | 33 | Database + Core Infrastructure (outbox schema) |
| LGSP-STATUS-02 | 36 | Status Callback Chain (9 mã QĐ 28) |
| LGSP-STATUS-03 | 36 | Status Callback Chain (9 mã QĐ 28) |
| LGSP-STATUS-04 | 36 | Status Callback Chain (9 mã QĐ 28) |
| LGSP-STATUS-05 | 36 | Status Callback Chain (9 mã QĐ 28) |
| LGSP-STATUS-06 | 36 | Status Callback Chain (9 mã QĐ 28) |
| LGSP-STATUS-07 | 36 | Status Callback Chain (9 mã QĐ 28) |
| LGSP-STATUS-08 | 36 | Status Callback Chain (9 mã QĐ 28) |
| LGSP-STATUS-09 | 36 | Status Callback Chain (9 mã QĐ 28) |
| LGSP-STATUS-10 | 36 | Status Callback Chain (9 mã QĐ 28) |
| LGSP-UI-01 | 37 | Admin UI + Catalog + Go-live |
| LGSP-UI-02 | 37 | Admin UI + Catalog + Go-live |
| LGSP-UI-03 | 37 | Admin UI + Catalog + Go-live |
| LGSP-UI-04 | 37 | Admin UI + Catalog + Go-live |
| LGSP-UI-05 | 37 | Admin UI + Catalog + Go-live |
| LGSP-UI-06 | 37 | Admin UI + Catalog + Go-live |
| LGSP-UI-07 | 37 | Admin UI + Catalog + Go-live |
| LGSP-UI-08 | 37 | Admin UI + Catalog + Go-live |

**Summary by phase:**

| Phase | Name | REQ count | REQ-IDs |
|---|---|---|---|
| 33 | Database + Core Infrastructure | 6 | LGSP-CRED-01..05 + LGSP-STATUS-01 |
| 34 | Send Flow (sendEdoc) | 6 | LGSP-SEND-01..06 |
| 35 | Receive Flow (cron) | 7 | LGSP-RECV-01..07 |
| 36 | Status Callback Chain | 9 | LGSP-STATUS-02..10 |
| 37 | Admin UI + Catalog + Go-live | 8 | LGSP-UI-01..08 |
| **Total** | | **36** | All 36 REQ-IDs mapped ✓ |

---

*Created 2026-05-19 — 36 REQ-IDs / 5 categories. Source spec: `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/` + QĐ 28/2018/QĐ-TTg. Phase 18 v3.0 LGSPRealService làm code reference. Traceability filled 2026-05-19 via /gsd-roadmapper — 5 phases (33-37), roll-out wave config-level (toggle `is_active` per row): Wave 1 (DN.001/002/003 sandbox) → Wave 2 (DN.004/005/006).*
