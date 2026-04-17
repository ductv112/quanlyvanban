# Phase 5: Kho lưu trữ, Tài liệu & Họp - Context

**Gathered:** 2026-04-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Kho lưu trữ hồ sơ (danh mục Kho/Phông, hồ sơ lưu trữ, mượn/trả), quản lý tài liệu chung & hợp đồng, và họp không giấy (phòng họp, cuộc họp, biểu quyết realtime, thống kê). Sprint 11 + Sprint 12 + Sprint 13. Requirements: KHO-01 → KHO-03, DOC-01, DOC-02, HOP-01 → HOP-04.

</domain>

<decisions>
## Implementation Decisions

### Nguyên tắc chung — BẮT BUỘC cho toàn bộ Phase 5
- **D-00a:** **PHẢI tham chiếu source code cũ (.NET)** trước khi implement bất kỳ module nào. Đọc Controllers, Services, Stored Procedures cũ để áp dụng đúng nghiệp vụ, flow, và tên trường dữ liệu. Source code cũ là tài liệu tham chiếu CHÍNH.
- **D-00b:** **Quy ước tên trường nghiêm ngặt** — Bài học từ Sprint 4 (nhiều lỗi do tên trường không thống nhất):
  1. SP PHẢI trả về đúng tên cột trong bảng DB (snake_case), KHÔNG rename/alias
  2. Sau khi viết SP, PHẢI kiểm tra chéo tên trường trả về khớp với interface TypeScript ở repository VÀ frontend
  3. Repository Row interface phải khớp 1:1 với output của SP
- **D-00c:** **Tuân thủ quy tắc UI mới** — Font Inter, typography system, color palette Deep Navy #1B3A5C đã cập nhật hôm nay. Dùng CSS classes trong globals.css, không inline styles.
- **D-00d:** **Tích hợp với Phase 1-4** — Các chức năng mới PHẢI liên kết với code đã có:
  - Kho lưu trữ ↔ HSCV (Phase 2): Hồ sơ công việc hoàn thành → chuyển vào kho
  - Kho lưu trữ ↔ VB đến/đi: Văn bản liên kết với hồ sơ lưu trữ
  - Tài liệu ↔ MinIO upload: Reuse pattern upload đính kèm đã có
  - Họp ↔ Lịch (Phase 4): Cuộc họp hiển thị trên lịch cơ quan/cá nhân
  - Họp ↔ Thông báo (Phase 3): Mời họp → thông báo realtime Socket.IO
  - Họp ↔ Danh bạ/Staff (Phase 4): Chọn thành viên họp từ danh bạ

### Kho lưu trữ (KHO-01, KHO-02, KHO-03)
- **D-01:** Cấu trúc Kho/Phông — **theo source code cũ**. Researcher phải đọc source cũ (.NET) để xác định đúng cấu trúc tree (bao nhiêu cấp, entity nào).
- **D-02:** Quản lý hồ sơ lưu trữ — **theo source code cũ**. CRUD, filter theo kho/phông, các trường dữ liệu lấy từ source cũ.
- **D-03:** Luồng mượn/trả — **theo source code cũ**. Flow tạo yêu cầu → duyệt → trả, trạng thái, deadline — tất cả phải khớp nghiệp vụ cũ.

### Tài liệu & Hợp đồng (DOC-01, DOC-02)
- **D-04:** Danh mục tài liệu chung — **theo source code cũ**. Cấu trúc danh mục (flat hay tree, loại danh mục) lấy từ source cũ.
- **D-05:** Upload tài liệu — reuse pattern MinIO upload đã có (multer + presigned URL).
- **D-06:** Quản lý hợp đồng — **theo source code cũ**. Bao gồm danh mục loại HĐ, CRUD, upload scan, có hay không luồng duyệt — theo nghiệp vụ cũ.

### Họp không giấy (HOP-01, HOP-02, HOP-03, HOP-04)
- **D-07:** Danh mục phòng họp + loại cuộc họp — **theo source code cũ**. Admin CRUD danh mục.
- **D-08:** Đăng ký/quản lý cuộc họp — **theo source code cũ**. Flow đăng ký, duyệt, calendar view, tài liệu họp.
- **D-09:** Biểu quyết realtime — **theo source code cũ** + Socket.IO (đã setup từ Phase 3). Chủ tọa tạo câu hỏi, thành viên vote, kết quả hiển thị realtime.
- **D-10:** Thống kê cuộc họp — dùng **@ant-design/charts** cho chart (bar/pie/line theo tháng/phòng/loại). Thống nhất với Ant Design ecosystem.

### Database & API
- **D-11:** Schema — **theo source code cũ**. Đã có schema esto (archive/storage) và cont (contracts) định nghĩa trong `01_create_schemas.sql`. Researcher xác nhận mapping.
- **D-12:** SP naming — tiếp tục convention `{schema}.fn_{module}_{action}`.
- **D-13:** Migration — 3 file mới: `016_sprint11_archive_storage.sql`, `017_sprint12_documents_contracts.sql`, `018_sprint13_meetings.sql`.

### Claude's Discretion
- Chi tiết UI layout cho từng page (table columns, drawer fields) — miễn tuân thủ Ant Design pattern đã có
- Cách tích hợp cụ thể giữa các module (API endpoint design, data flow)
- Ant Design Charts configuration cho thống kê họp

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Source code cũ (.NET) — QUAN TRỌNG NHẤT
- Source code cũ (.NET) trên GitLab — ĐỌC Controllers, Services, Stored Procedures cũ cho mỗi module trước khi implement
- Đặc biệt: Areas/Esto (lưu trữ), Areas/Cont (hợp đồng), Areas/Meeting (họp)

### Codebase hiện tại
- `.planning/codebase/STRUCTURE.md` — Current directory layout, all routes/repositories
- `.planning/codebase/CONVENTIONS.md` — Naming patterns, error handling, component patterns
- `.planning/codebase/STACK.md` — Technology stack and versions
- `e_office_app_new/backend/src/lib/error-handler.ts` — Shared handleDbError (add new constraints here)
- `e_office_app_new/backend/src/lib/socket.ts` — Socket.IO server (reuse for biểu quyết)
- `e_office_app_new/frontend/src/lib/tree-utils.ts` — Shared tree utilities (reuse for Kho/Phông tree)
- `e_office_app_new/frontend/src/lib/socket.ts` — Socket.IO client
- `e_office_app_new/backend/src/middleware/upload.ts` — Multer upload middleware (reuse for tài liệu)
- `e_office_app_new/backend/src/lib/minio/client.ts` — MinIO file storage client
- `e_office_app_new/database/init/01_create_schemas.sql` — Schema definitions (esto, cont already exist)

### Prior phase context
- `.planning/phases/02-h-s-c-ng-vi-c/02-CONTEXT.md` — HSCV patterns (integrate with kho lưu trữ)
- `.planning/phases/03-li-n-th-ng-tin-nh-n/03-CONTEXT.md` — Socket.IO + thông báo patterns
- `.planning/phases/04-l-ch-danh-b-dashboard/04-CONTEXT.md` — Calendar + danh bạ patterns (integrate with họp)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `tree-utils.ts` (buildTree, filterTree, flattenTreeForSelect) — dùng cho Kho/Phông tree
- `error-handler.ts` (handleDbError) — thêm constraint names mới cho kho/tài liệu/họp
- `socket.ts` (backend + frontend) — dùng cho biểu quyết realtime
- `upload.ts` + `minio/client.ts` — dùng cho upload tài liệu, scan hợp đồng, tài liệu họp
- `MainLayout.tsx` menuItems — thêm menu mới cho 3 module
- `globals.css` — thêm CSS classes mới nếu cần (tuân thủ Inter font + navy palette)

### Established Patterns
- Repository pattern: `{module}.repository.ts` → `callFunction<T>('schema.fn_module_action', [params])`
- Route pattern: `{module}.ts` → import handleDbError + repository → export Router
- Page pattern: `'use client'` + useState + useEffect + fetchData + Ant Design Table/Drawer
- Detail page pattern: `[id]/page.tsx` with tabs (reuse for chi tiết cuộc họp)
- Calendar pattern: Ant Design Calendar with cellRender (Phase 4 — reuse for lịch họp)

### Integration Points
- `server.ts` — mount new routes: `/api/kho-luu-tru`, `/api/tai-lieu`, `/api/hop-dong`, `/api/cuoc-hop`
- `MainLayout.tsx` — add sidebar menu items for new modules
- `globals.css` — add new CSS classes following existing conventions
- Lịch cơ quan/cá nhân — cuộc họp hiển thị như events trên calendar
- Thông báo — mời họp tạo notice qua Socket.IO

</code_context>

<specifics>
## Specific Ideas

- Sprint 4 đã có nhiều lỗi do tên trường không thống nhất giữa SP, repository, và frontend. Phase 5 PHẢI kiểm tra chéo nghiêm ngặt.
- Mỗi module phải tham chiếu source code cũ (.NET) — đây là yêu cầu bắt buộc từ user, không phải optional.
- Chart thống kê họp dùng @ant-design/charts để thống nhất ecosystem.
- Các chức năng mới phải có sự liên kết với chức năng đã làm ở Phase 1-4 (không hoạt động cô lập).

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 05-kho-luu-tru-tai-lieu-hop*
*Context gathered: 2026-04-14*
