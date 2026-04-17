# Phase 3: Liên thông & Tin nhắn - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Văn bản liên thông (danh sách + chi tiết), giao việc nhanh từ VB đến, tin nhắn nội bộ (inbox/sent/trash + thread), thông báo hệ thống (bell icon + dropdown + trang), và realtime qua Socket.IO. Bao phủ Sprint 7 + Sprint 8. Requirements: VBLT-01 → VBLT-03, MSG-01 → MSG-04.

</domain>

<decisions>
## Implementation Decisions

### Văn bản liên thông (VBLT-01)
- **D-01:** Danh sách VB liên thông reuse pattern VB đến — Table với columns: Ngày nhận, Ký hiệu, Trích yếu, Hạn trả lời, Đơn vị phát hành, Người ký.
- **D-02:** Chi tiết VB liên thông: trang riêng tương tự VB đến detail page.
- **D-03:** Route: `/van-ban-lien-thong` trong (main) group.

### Giao việc từ VB (VBLT-02)
- **D-04:** Nút "Giao việc" trên toolbar chi tiết VB đến → mở Drawer tạo HSCV nhanh.
- **D-05:** Drawer tự động fill: trích yếu từ VB, hạn xử lý. User chỉ cần chọn người phụ trách.
- **D-06:** Sau khi tạo HSCV, auto link VB đến vào HSCV (via fn_handling_doc_create_from_doc).

### Nhận bàn giao / Chuyển lại / Hủy duyệt (VBLT-03)
- **D-07:** 3 action buttons trên toolbar chi tiết VB đến: "Nhận bàn giao", "Chuyển lại", "Hủy duyệt".
- **D-08:** "Chuyển lại" yêu cầu nhập lý do (Modal.confirm với TextArea). "Nhận bàn giao" và "Hủy duyệt" dùng Popconfirm.

### Tin nhắn nội bộ (MSG-01, MSG-02)
- **D-09:** Layout **mail-like 3-panel**: sidebar trái (Hộp thư đến/Đã gửi/Thùng rác + badge count), list giữa, detail phải.
- **D-10:** Soạn tin: Modal hoặc Drawer với Select người nhận (multi-select từ staff), Subject input, Content TextArea.
- **D-11:** Thread: trả lời hiển thị dạng comment list dưới tin nhắn gốc (tương tự ý kiến HSCV).
- **D-12:** Badge count tin chưa đọc trên sidebar "Hộp thư đến".
- **D-13:** Route: `/tin-nhan` trong (main) group.

### Thông báo hệ thống (MSG-03)
- **D-14:** Bell icon trong header (MainLayout) → Dropdown danh sách thông báo mới (max 10 items).
- **D-15:** Badge count thông báo chưa đọc trên bell icon.
- **D-16:** Trang thông báo đầy đủ: `/thong-bao` — Table/List view với filter đã đọc/chưa đọc.
- **D-17:** Admin có thể tạo thông báo mới qua Drawer.

### Realtime Socket.IO (MSG-04)
- **D-18:** Backend: Socket.IO server tích hợp vào Express HTTP server (cùng port 4000).
- **D-19:** Authentication: verify JWT token khi socket connect (middleware).
- **D-20:** Events: `new_document`, `new_message`, `new_notification`, `doc_status_changed`.
- **D-21:** Frontend: `socket.io-client` auto connect khi login (trong auth store hoặc layout).
- **D-22:** Khi nhận event → toast notification (message.info) + cập nhật badge counts.

### Claude's Discretion
- Cách tổ chức route files (1 file hay nhiều file)
- Socket.IO room strategy (per-user, per-unit, broadcast)
- Rich text editor cho tin nhắn content hay plain TextArea
- Cách paginate tin nhắn list vs infinite scroll

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Sprint Specs
- `e_office_app_new/ROADMAP.md` §Sprint 7 (lines 677-717) — VB liên thông, Giao việc, Nhận bàn giao
- `e_office_app_new/ROADMAP.md` §Sprint 8 (lines 720-766) — Tin nhắn nội bộ, Thông báo, Socket.IO

### Existing Code (reuse patterns)
- `e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx` — VB đến list pattern (reuse cho VB liên thông)
- `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/page.tsx` — HSCV list pattern (Phase 2)
- `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` — Header layout (thêm bell icon)
- `e_office_app_new/backend/src/server.ts` — Server entry point (tích hợp Socket.IO)

### Database
- `e_office_app_new/database/migrations/002_edoc_tables.sql` — Existing tables (cần tạo tables mới cho messages, notices, inter_incoming)

### Project Conventions
- `e_office_app_new/docs/quy_uoc_chung.md` — Validation, naming, security conventions
- `.planning/codebase/CONVENTIONS.md` — Code style, error handling patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- VB đến page pattern (list + drawer + detail) — reuse cho VB liên thông
- `lib/tree-utils.ts` — buildTree, filterTree cho department selection
- `lib/api.ts` — Axios instance with auth interceptor
- `stores/auth.store.ts` — Zustand auth store (user, unitId, staffId)
- `lib/error-handler.ts` — Shared handleDbError
- `globals.css` — .page-header, .page-card, .drawer-gradient, .stat-card, .filter-row
- Socket.IO dependencies already installed (socket.io + socket.io-client in package.json)

### Established Patterns
- Repository pattern: route → repository → PostgreSQL stored function
- Drawer 720px for add/edit, Modal.confirm for delete
- Card tabs for multi-section detail pages
- Vietnamese text with diacritics for all UI

### Integration Points
- MainLayout.tsx: thêm bell icon + badge count vào header
- server.ts: tích hợp Socket.IO server
- VB đến detail page: thêm toolbar buttons (Giao việc, Nhận bàn giao, Chuyển lại, Hủy duyệt)
- Auth store: thêm socket connection management

</code_context>

<specifics>
## Specific Ideas

- Tin nhắn layout giống Gmail: sidebar categories, message list, reading pane
- Bell icon dropdown: hiện tối đa 10 thông báo mới nhất, "Xem tất cả" link tới /thong-bao
- Socket.IO rooms: mỗi user join room riêng (user_{staffId}) để nhận events targeted
- Giao việc drawer: pre-fill từ VB đến data, giảm effort nhập liệu

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-li-n-th-ng-tin-nh-n*
*Context gathered: 2026-04-14*
