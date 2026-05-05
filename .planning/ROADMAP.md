# Roadmap: e-Office — Quản lý Văn bản điện tử

> **Xem thêm:** Chi tiết 17 sprints (SP, API, UI) tại `e_office_app_new/ROADMAP.md`

## Overview

Rebuild hệ thống quản lý văn bản điện tử (.NET cũ) thành stack mới (Next.js + Express + PostgreSQL).

## Milestones

- ✅ **v1.0 MVP** — Phases 1-7 (shipped 2026-04-18) — `.planning/milestones/v1.0-phases/`
- ✅ **v2.0 Tích hợp ký số 2 kênh** — Phases 8-14 + 11.1 (shipped 2026-04-23) — `.planning/milestones/v2.0-ROADMAP.md`
- ✅ **v3.0 Chuẩn hoá quy trình văn bản** — Phases 15-20 (shipped 2026-04-24) — `.planning/milestones/v3.0-ROADMAP.md`
- 📋 **v3.1+** — Defer items (drafting recipients structured, admin CRUD inter_orgs, multi-level approval...)

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
| 21+ | v3.1+ | Planning | — |

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
