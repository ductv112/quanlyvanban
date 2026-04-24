# Phase 2: Hồ sơ công việc - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Module Hồ sơ công việc (HSCV) hoàn chỉnh: danh sách với filter 10 trạng thái + badge count, CRUD qua Drawer, trang chi tiết với 6 tab (thông tin, VB liên kết, cán bộ, ý kiến, đính kèm, HSCV con), phân công cán bộ qua Transfer panel, chuyển trạng thái workflow, workflow designer kéo thả, KPI dashboard, và 3 báo cáo thống kê + export Excel.

Bao phủ Sprint 5 (Core) + Sprint 6 (Workflow & Báo cáo). Requirements: HSCV-01 → HSCV-10.

</domain>

<decisions>
## Implementation Decisions

### Danh sách HSCV & Filter (HSCV-01)
- **D-01:** Filter 10 trạng thái dùng **tab/filter bar ngang** ở đầu trang (Tabs hoặc Segmented), KHÔNG dùng sidebar sub-menu — giữ nhất quán với VB đến/đi pages, giảm complexity navigation.
- **D-02:** Badge count hiển thị trên mỗi tab/filter item — gọi `fn_handling_doc_count_by_status` khi load trang.
- **D-03:** Table columns theo ROADMAP: Tên HSCV, Ngày mở, Hạn giải quyết, Trạng thái (Tag màu), Phụ trách, Lãnh đạo ký, Tiến độ (Progress bar %).

### CRUD HSCV (HSCV-02)
- **D-04:** Drawer 720px cho add/edit (consistent với pattern hiện tại) — rootClassName="drawer-gradient".
- **D-05:** Form fields theo ROADMAP: Tên HSCV, Loại VB, Lĩnh vực, Ghi chú, Ngày mở, Hạn giải quyết, Người phụ trách (Select), Lãnh đạo ký (Select), Quy trình (Select), HSCV cha (nếu tạo con).

### Chi tiết HSCV (HSCV-03)
- **D-06:** **Trang riêng** `/ho-so-cong-viec/:id` (KHÔNG dùng Drawer vì quá nhiều nội dung) — route mới trong (main) group.
- **D-07:** Card Tabs 6 tab: Thông tin chung | Văn bản liên kết | Cán bộ xử lý | Ý kiến xử lý | File đính kèm | HSCV con.
- **D-08:** Toolbar actions trên detail header: Chuyển xử lý, Trình ký, Duyệt, Từ chối, Trả về, Hoàn thành — hiển thị theo trạng thái hiện tại và quyền user.

### Phân công cán bộ (HSCV-04)
- **D-09:** Transfer panel: tree đơn vị/phòng ban bên trái → danh sách cán bộ đã chọn bên phải. Radio chọn vai trò: Phụ trách / Phối hợp. Input hạn xử lý.
- **D-10:** Dùng lại `tree-utils.ts` đã extract ở Phase 1 cho department tree trong Transfer panel.

### Ý kiến xử lý (HSCV-05)
- **D-11:** Hiển thị trong tab "Ý kiến" dạng comment list (avatar, tên, nội dung, ngày). Form thêm ý kiến ở cuối với TextArea + nút Gửi.

### Liên kết VB (HSCV-06)
- **D-12:** Tab "VB liên kết" — Table VB đã link + nút "Thêm VB" mở Modal search VB (tìm kiếm VB đến/đi/dự thảo).

### Chuyển trạng thái (HSCV-07)
- **D-13:** Toolbar buttons hiển thị dynamic theo trạng thái hiện tại. Từ chối/Trả về yêu cầu nhập lý do (Modal.confirm với TextArea). Cập nhật tiến độ % qua slider hoặc InputNumber.

### Workflow Designer (HSCV-08)
- **D-14:** Dùng **ReactFlow** (thư viện drag-and-drop flowchart) cho visual workflow designer — ROADMAP chỉ định rõ kéo thả.
- **D-15:** Node types: Bắt đầu (circle), Bước xử lý (rectangle), Kết thúc (circle). Connection arrows giữa các bước.
- **D-16:** Click node → panel bên phải hiển thị: Tên bước, Loại bước, Cho phép trình ký, Danh sách cán bộ (Transfer panel), Thời hạn.
- **D-17:** Trang riêng `/quan-tri/quy-trinh/:id/thiet-ke` cho workflow designer.

### KPI Dashboard (HSCV-09)
- **D-18:** KPI cards gradient (reuse stat-card CSS class): Tổng số, Chuyển kỳ trước, Kỳ này, Hoàn thành, Đang thực hiện, Quá hạn %.
- **D-19:** Biểu đồ dùng **Ant Design Charts** — Bar chart cho so sánh số lượng, Pie chart cho tỷ lệ phần trăm.

### Báo cáo thống kê (HSCV-10)
- **D-20:** Card tabs 3 loại: Theo đơn vị, Theo cán bộ, Theo người giao.
- **D-21:** Filter: Đơn vị (Select), Từ ngày - Đến ngày (RangePicker). Table thống kê + chart.
- **D-22:** Export Excel dùng **exceljs** (đã có trong dependencies).

### Claude's Discretion
- Thứ tự implement các sub-features (có thể nhóm SP + route + page theo flow)
- Chi tiết styling cho KPI cards, tag colors, progress bar appearance
- Cách tổ chức code: 1 route file lớn hay chia nhỏ (handling-doc.ts, workflow.ts, report.ts)
- ReactFlow node styling và interaction details
- Cách handle HSCV con (nested level depth)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Sprint Specs (implementation details)
- `e_office_app_new/ROADMAP.md` §Sprint 5 (lines 520-610) — DB SPs, API endpoints, UI specs cho HSCV Core
- `e_office_app_new/ROADMAP.md` §Sprint 6 (lines 612-675) — Workflow Designer, KPI Dashboard, Báo cáo

### Database Schema
- `e_office_app_new/database/migrations/002_edoc_tables.sql` §13-17 (lines 332-450) — Tables: handling_docs, handling_doc_links, staff_handling_docs, opinion_handling_docs, attachment_handling_docs

### Project Conventions
- `e_office_app_new/docs/quy_uoc_chung.md` — maxLength, validation, error messages, naming, security
- `.planning/codebase/CONVENTIONS.md` — Naming patterns, code style, import organization, error handling

### Architecture
- `.planning/codebase/ARCHITECTURE.md` — Repository pattern, data flow, query helpers
- `.planning/codebase/STRUCTURE.md` — Directory layout, key file locations

### Source Code Reference (old system)
- `docs/source_code_cu/sources/OneWin.WebApp/` — .NET controllers for HandlingDoc business logic
- `docs/source_code_cu/sources/OneWin.Data.Services/` — Service layer for HSCV workflow logic

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `e_office_app_new/frontend/src/lib/tree-utils.ts` — buildTree, filterTree, flattenTreeForSelect — dùng cho Transfer panel và department selection
- `e_office_app_new/frontend/src/types/tree.ts` — TreeNode type definitions
- `e_office_app_new/frontend/src/lib/api.ts` — Axios instance with auth interceptor
- `e_office_app_new/frontend/src/stores/auth.store.ts` — Zustand auth store (user, unitId, staffId)
- `e_office_app_new/frontend/src/app/globals.css` — CSS classes: .page-header, .page-title, .page-card, .drawer-gradient, .stat-card, .filter-row
- `e_office_app_new/backend/src/lib/db/query.ts` — callFunction, callFunctionOne, callProcedure, withTransaction
- `e_office_app_new/backend/src/lib/minio/client.ts` — uploadFile, getFileUrl, deleteFile (cho đính kèm)
- `e_office_app_new/backend/src/middleware/upload.ts` — multer memory storage 50MB (cho file upload)

### Established Patterns
- Repository pattern: route handler → repository → PostgreSQL stored function (xem incoming-doc.repository.ts, incoming-doc.ts route)
- Frontend page: 'use client', useState/useEffect, Ant Design Table + Drawer + Form, api.get/post/put/delete
- Error handling: handleDbError() from shared lib/error-handler.ts
- Drawer pattern: 720px, gradient header, footer with Save/Cancel
- Delete: Modal.confirm với danger: true
- Actions: Dropdown with MoreOutlined icon button

### Integration Points
- Frontend routing: thêm `/ho-so-cong-viec` route trong `(main)` group
- Backend routing: thêm route module mới, mount trong server.ts
- Sidebar menu: đã có entry "Hồ sơ công việc" trong seed data (menu ID 7, path `/ho-so-cong-viec`)
- Database: tables đã tạo trong 002_edoc_tables.sql, cần tạo migration cho stored procedures

</code_context>

<specifics>
## Specific Ideas

- Filter trạng thái dùng Tabs component hoặc Segmented component của Ant Design — mỗi tab hiển thị badge count
- Detail page toolbar buttons chỉ hiện các action hợp lệ theo trạng thái hiện tại (VD: HSCV "Mới" chỉ có Trình ký, không có Duyệt)
- Progress bar trong table dùng Ant Design Progress component (compact, inline)
- Comment/opinion list style tương tự chat — avatar tròn bên trái, nội dung bên phải, timestamp nhỏ
- Workflow designer canvas chiếm full width, panel chi tiết node ở drawer hoặc sidebar phải

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 02-h-s-c-ng-vi-c*
*Context gathered: 2026-04-14*
