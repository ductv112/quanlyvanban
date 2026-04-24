# Roadmap: e-Office — Quản lý Văn bản điện tử

> **Xem thêm:** Chi tiết 17 sprints (SP, API, UI) tại `e_office_app_new/ROADMAP.md`

## Overview

Rebuild hệ thống quản lý văn bản điện tử (.NET cũ) thành stack mới (Next.js + Express + PostgreSQL).

## Milestones

- ✅ **v1.0 MVP** — Phases 1-7 (shipped 2026-04-18) — `.planning/milestones/v1.0-phases/`
- ✅ **v2.0 Tích hợp ký số 2 kênh** — Phases 8-14 + 11.1 (shipped 2026-04-23) — `.planning/milestones/v2.0-ROADMAP.md`
- 🚧 **v3.0 Chuẩn hoá quy trình văn bản** — Phases 15-20 (planned)

## Phases

### v3.0 (Active — Milestone: Chuẩn hoá data model + workflow nghiệp vụ văn bản)

- [ ] **Phase 15: Audit & design data model** (0 plans)
- [ ] **Phase 16: Schema rebuild v3.0** (0 plans)
- [ ] **Phase 17: Tách bước Ban hành/Gửi + Auto-sinh Incoming nội bộ + Approver** (0 plans)
- [ ] **Phase 18: Real LGSP HTTP client + worker polling thật** (0 plans)
- [ ] **Phase 19: UI rewrite 3 màn + gộp menu Liên thông vào VB đến** (0 plans)
- [ ] **Phase 20: Regression + UAT toàn bộ** (0 plans)

## Phase Details

### Phase 15: Audit & design data model

**Goal:** Phân tích gap toàn diện giữa data model hiện tại của 3 bảng văn bản (incoming_docs/outgoing_docs/drafting_docs) so với source .NET cũ + nghiệp vụ thực tế. Sản phẩm là **DESIGN.md** chốt cụ thể: cột nào thêm/sửa/xóa, ENUM values, FK relationships, recipient table schema, lifecycle workflow, migration strategy. Không code, không reset DB — chỉ design doc để Phase 16 implement.

**Depends on:** —

**Requirements:** DM-01, DM-02, DM-03, DM-04, DM-05, DM-06, DM-07

**Success Criteria** (what must be TRUE):
  1. DESIGN.md liệt kê đầy đủ cột mới cho `incoming_docs` (`source_type`, `is_unit_send`, `unit_send`, `previous_outgoing_doc_id`, `external_doc_id`, `approver`, `approved`, `approved_at`) với data type, NULL/NOT NULL, default value, foreign key, comment giải thích nghiệp vụ
  2. DESIGN.md có schema bảng mới `outgoing_doc_recipients` (multi-recipient, phân loại internal/external) + bảng `inter_organizations` (danh mục cơ quan LGSP) với đầy đủ columns + indexes
  3. DESIGN.md có schema mới cho `drafting_docs` + `outgoing_docs`: `drafting_unit_id`, `publish_unit_id` (tách riêng), `is_released`, `released_date`, `previous_outgoing_doc_id`, `approver`, `approved`, `approved_at`
  4. DESIGN.md mô tả lifecycle 3 trạng thái: Drafting → Ban hành → Gửi với SP signatures dự kiến (`fn_outgoing_doc_release`, `fn_outgoing_doc_send`, `fn_drafting_doc_approve`)
  5. DESIGN.md có sơ đồ ERD/relationships diagram (mermaid hoặc text) thể hiện mối liên kết: drafting → outgoing (PreviousOutgoingDocId), outgoing → incoming (PreviousOutgoingDocId), outgoing → recipients → unit/inter_organization
  6. DESIGN.md document migration strategy: reset DB clean (user approved D-2026-04-23), bump master schema `000_schema_v2.0.sql` → `000_schema_v3.0.sql`, list các bảng/cột bị drop (inter_incoming_docs, attachment_inter_incoming_docs)
  7. DESIGN.md identify breaking changes ảnh hưởng module xuống dòng (HSCV, ký số, dashboard, báo cáo) + plan mitigation cho mỗi cái

### Phase 16: Schema rebuild v3.0

**Goal:** Implement schema mới theo Phase 15 DESIGN.md. Bump master schema file `database/schema/000_schema_v2.0.sql` → `000_schema_v3.0.sql`. Drop bảng `inter_incoming_docs` riêng, gộp vào `incoming_docs` với cột `source_type`. Thêm bảng `outgoing_doc_recipients` + `inter_organizations`. Thêm cột `is_released`/`released_date`/`approver`/`approved` cho drafting/outgoing/incoming. Reset DB clean + apply schema mới + seed.

**Depends on:** Phase 15

**Requirements:** DM-01, DM-02, DM-03, DM-04, DM-05, DM-06, DM-07, DM-08

### Phase 17: Tách bước Ban hành/Gửi + Auto-sinh Incoming nội bộ + Approver

**Goal:** Implement 3 SP chính (`fn_outgoing_doc_release`, `fn_outgoing_doc_send`, `fn_drafting_doc_approve`) + repository + routes + UI 2 button "Ban hành"/"Gửi" trên outgoing detail + nút "Duyệt"/"Bỏ duyệt" trên drafting detail. Khi gửi recipient nội bộ → SP tự INSERT `incoming_docs` với `source_type='internal'` + đầy đủ field cross-reference.

**Depends on:** Phase 16

**Requirements:** WF-01, WF-02, WF-03, WF-04, WF-05

### Phase 18: Real LGSP HTTP client + worker polling thật

**Goal:** Thay `lgsp-mock.service.ts` bằng real `LGSPRealService` với OAuth2 + REST client tới `apiltvb.langson.gov.vn` (token cache 29 phút). Worker BullMQ `lgsp-send` đẩy outgoing pending lên LGSP. Worker `lgsp-receive` polling 60s nhận VB từ LGSP → INSERT `incoming_docs` với `source_type='external_lgsp'`.

**Depends on:** Phase 16

**Requirements:** LGSP-01, LGSP-02, LGSP-03, LGSP-04, LGSP-05

### Phase 19: UI rewrite 3 màn + gộp menu Liên thông vào VB đến

**Goal:** Form drafting/outgoing thêm field "Đơn vị soạn thảo" + "Cơ quan ban hành" tách riêng + recipient picker (tab nội bộ tree multi-select / tab ngoài search). Form incoming hiển thị 3 field "Cơ quan ban hành" + "Nơi gửi" + "Nơi nhận" rõ ràng. Bỏ menu sidebar "Văn bản liên thông" + route `/van-ban-lien-thong`. Trang `/van-ban-den` thêm filter `source_type` + badge tag màu khác nhau. Workflow recall (thu hồi LGSP) chuyển vào trang chi tiết `/van-ban-den/[id]`.

**Depends on:** Phase 17, Phase 18

**Requirements:** UI-01, UI-02, UI-03, UI-04, UI-05, UI-06, UI-07, UI-08

### Phase 20: Regression + UAT toàn bộ

**Goal:** Regression test E2E các module xuống dòng (HSCV, ký số 4 tab, báo cáo, dashboard, lịch) đảm bảo không vỡ sau schema rebuild. UAT 3 luồng chính: (1) Sở A soạn → ban hành → gửi Sở B nội bộ; (2) gửi LGSP outgoing → worker đẩy + tracking status; (3) nhận LGSP incoming → worker pull về INSERT incoming_docs. Reset DB + seed demo + verify khả năng ship cho KH.

**Depends on:** Phase 15, Phase 16, Phase 17, Phase 18, Phase 19

**Requirements:** QA-01, QA-02, QA-03

<details>
<summary>✅ v1.0 MVP (Phases 1-7) — SHIPPED 2026-04-18</summary>

- [x] **Phase 1: Stabilize Sprint 0-4** — Fix visible bugs, refactor shared patterns, golden path mượt
- [x] **Phase 2: Hồ sơ công việc** — HSCV CRUD, 6-tab detail, workflow designer, KPI, 3 reports, Excel export
- [x] **Phase 3: Liên thông & Tin nhắn** — VB liên thông (tiếp nhận/từ chối/thu hồi), tin nhắn nội bộ
- [x] **Phase 4: Lịch, Danh bạ & Dashboard** — Lịch 3 loại, danh bạ, dashboard charts + feeds
- [x] **Phase 5: Kho lưu trữ, Tài liệu & Họp** — Kho/Phông + mượn/trả, tài liệu, họp không giấy
- [x] **Phase 6: Tích hợp hệ thống ngoài** — LGSP mock, ký số mock (SmartCA OTP), Trục CP mock
- [x] **Phase 7: Polish & Redirect** — HDSD compliance 97.8%, sidebar dynamic, redirect đối tác

Detail: `.planning/milestones/v1.0-phases/`
</details>

<details>
<summary>✅ v2.0 Tích hợp ký số 2 kênh (Phases 8-14 + 11.1) — SHIPPED 2026-04-23</summary>

- [x] **Phase 8: Schema foundation + PDF signing layer** — 3 bảng + migration `staff.sign_phone` + PDF pure JS
- [x] **Phase 9: Admin config + provider adapters** — SmartCA + MySign adapters, trang Admin với test connection
- [x] **Phase 10: User config page** — `/ky-so/tai-khoan` form dynamic theo provider + verify
- [x] **Phase 11: Sign flow + async worker** — BullMQ poll 5s × 3', Socket.IO SIGN_COMPLETED, ký lại/hủy
- [x] **Phase 11.1: DB Consolidation & Seed Strategy** — Master schema idempotent + tách seed required/demo
- [x] **Phase 12: Menu Ký số + Danh sách 4 tab UI** — `/ky-so/danh-sach` 4 tab dynamic
- [x] **Phase 13: Modal ký số robust + Root CA UX** — Countdown 3:00, banner Root CA Viettel
- [x] **Phase 14: Deployment + HDSD + verification** — Deploy scripts Windows, REQUIREMENTS audit 41 REQ

Detail: `.planning/milestones/v2.0-phases/`, audit: `.planning/milestones/v2.0-MILESTONE-AUDIT.md`
</details>

## Progress

| Phase range | Milestone | Plans | Status | Completed |
|-------------|-----------|-------|--------|-----------|
| 1-7 | v1.0 | 26/26 | Complete | 2026-04-14 → 2026-04-18 |
| 8-14 + 11.1 | v2.0 | 39/39 | Complete | 2026-04-21 → 2026-04-23 |
| 15-20 | v3.0 | 0/? | Not started | — |
