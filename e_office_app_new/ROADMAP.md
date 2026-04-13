# ROADMAP — Hệ thống Quản lý Văn bản điện tử

> Tài liệu tham chiếu chính: Phân tích 47 screenshots + source code cũ (270+ controllers, 10 areas)
> Mỗi Sprint = 1 nhóm module hoàn chỉnh (SP + API + UI + test)
> Tiêu chí DONE: Database migration → Stored Procedures → Backend API → Frontend UI → Test trên trình duyệt
>
> **SP Naming Convention:** `{schema}.fn_{module}_{action}` — VD: `public.fn_auth_login`, `edoc.fn_incoming_doc_get_list`
> Trong tài liệu này viết tắt không có schema prefix, khi implement cần thêm schema phù hợp.

---

## Sprint 0: Nền tảng & Authentication ✅ DONE

### 0.1 Infrastructure
- [x] Docker Compose (PostgreSQL 16, MongoDB 7, Redis 7, MinIO)
- [x] Database schemas: public, edoc, esto, cont, iso
- [x] Extensions: uuid-ossp, pgcrypto, unaccent, pg_trgm
- [x] Migration 001: System tables (staff, departments, positions, roles, rights, refresh_tokens, login_history, configurations, provinces/districts/communes)
- [x] Migration 002: Document tables (edoc schema — incoming/outgoing/drafting/handling docs + attachments + workflows)

### 0.2 Backend
- [x] Express 5 + TypeScript setup (helmet, CORS, compression, pino logging)
- [x] PostgreSQL pool + query helpers (callFunction, callFunctionOne, callProcedure, withTransaction)
- [x] Redis client + cache helpers
- [x] MinIO client (upload/download/delete)
- [x] JWT auth (jose) + bcrypt password
- [x] Auth middleware (authenticate, requireRoles)

### 0.3 Auth Module
- [x] SP: fn_auth_login, fn_auth_log_login, fn_auth_save_refresh_token, fn_auth_verify_refresh_token, fn_auth_logout, fn_auth_logout_all, fn_auth_get_me, fn_auth_cleanup_expired_tokens
- [x] Backend: auth.repository → auth.service → auth.routes (login, refresh, logout, me)
- [x] Refresh token rotation + httpOnly cookie

### 0.4 Frontend
- [x] Next.js 16 + React 19 + Ant Design 6 + Zustand + Axios
- [x] Ant Design theme customization (Deep Navy #1B3A5C, Accent Teal #0891B2)
- [x] Login page (split layout 55/45, branding + form)
- [x] Auth store (Zustand): login, logout, fetchMe
- [x] Main layout: Sidebar (collapsible, dark navy) + Header (breadcrumb, notification bell, avatar dropdown)
- [x] Dashboard placeholder (4 KPI cards + 2 content cards)
- [x] API interceptor (auto Bearer token + 401 refresh)

---

## Sprint 1: Quản trị hệ thống — Core

> Ref: Module 10 hệ thống cũ (Manager Area — 25 controllers)
> Đây là nền tảng bắt buộc, mọi module khác đều phụ thuộc

### 1.1 Quản lý Đơn vị / Phòng ban (Department)
> Ref cũ: Manager/Department, ApiService/DepartmentController
> UI: Tree trái + Table phải (master-detail split 30/70)

**Database & SP:**
- fn_department_get_tree(p_unit_id) → Cây tổ chức đệ quy
- fn_department_get_by_id(p_id)
- fn_department_create(p_parent_id, p_code, p_name, p_name_en, p_short_name, p_abb_name, p_is_unit, p_level, p_sort_order, p_phone, p_fax, p_email, p_address, p_allow_doc_book, p_created_by)
- fn_department_update(p_id, ...)
- fn_department_delete(p_id) — soft delete, check có nhân viên không
- fn_department_toggle_lock(p_id)

**API:**
- GET /api/quan-tri/don-vi/tree
- GET /api/quan-tri/don-vi/:id
- POST /api/quan-tri/don-vi
- PUT /api/quan-tri/don-vi/:id
- DELETE /api/quan-tri/don-vi/:id

**UI:**
- Tree bên trái: Ant Design Tree, drag & drop sắp xếp, search filter, lazy load
- Table bên phải: Danh sách phòng ban con của node đang chọn
- Drawer thêm/sửa (width 720px)
- Popconfirm xóa
- Fields: Mã, Tên, Tên tiếng Anh, Tên viết tắt, Cấp (Đơn vị/Phòng ban), Thứ tự, SĐT, Fax, Email, Địa chỉ, Cho phép sổ VB, Trạng thái

### 1.2 Quản lý Chức vụ (Position)
> Ref cũ: Manager/Position, ApiService/PositionController
> UI: Table đơn giản

**Database & SP:**
- fn_position_get_list(p_keyword, p_page, p_page_size)
- fn_position_get_by_id(p_id)
- fn_position_create(p_name, p_code, p_sort_order, p_description)
- fn_position_update(p_id, ...)
- fn_position_delete(p_id) — check có nhân viên nào đang dùng không

**API:**
- GET /api/quan-tri/chuc-vu
- POST /api/quan-tri/chuc-vu
- PUT /api/quan-tri/chuc-vu/:id
- DELETE /api/quan-tri/chuc-vu/:id

**UI:**
- Table: Mã, Tên chức vụ, Thứ tự, Mô tả, Trạng thái
- Drawer thêm/sửa, Popconfirm xóa

### 1.3 Quản lý Người dùng (Staff)
> Ref cũ: Manager/Staff (Save), ApiService/StaffController
> UI: Tree đơn vị bên trái → Danh sách nhân viên bên phải

**Database & SP:**
- fn_staff_get_list(p_unit_id, p_department_id, p_keyword, p_is_locked, p_page, p_page_size)
- fn_staff_get_by_id(p_id)
- fn_staff_create(p_department_id, p_unit_id, p_position_id, p_username, p_password_hash, p_first_name, p_last_name, p_gender, p_birth_date, p_email, p_phone, p_mobile, p_address, p_id_card, p_id_card_date, p_id_card_place, p_is_admin, p_is_represent_unit, p_is_represent_department, p_created_by)
- fn_staff_update(p_id, ...)
- fn_staff_delete(p_id) — soft delete
- fn_staff_toggle_lock(p_id)
- fn_staff_reset_password(p_id, p_new_password_hash)
- fn_staff_change_password(p_id, p_new_password_hash) — user tự đổi
- fn_staff_update_avatar(p_id, p_image_path)

**API:**
- GET /api/quan-tri/nguoi-dung?unit_id=&department_id=&keyword=&page=&pageSize=
- GET /api/quan-tri/nguoi-dung/:id
- POST /api/quan-tri/nguoi-dung
- PUT /api/quan-tri/nguoi-dung/:id
- DELETE /api/quan-tri/nguoi-dung/:id
- PATCH /api/quan-tri/nguoi-dung/:id/lock
- PATCH /api/quan-tri/nguoi-dung/:id/reset-password
- PATCH /api/quan-tri/nguoi-dung/:id/avatar (multipart upload → MinIO)

**UI:**
- Layout: Tree đơn vị (trái 30%) + Table nhân viên (phải 70%)
- Click node tree → filter nhân viên theo đơn vị/phòng ban
- Table columns: Avatar, Họ tên, Username, Chức vụ, Phòng ban, Email, SĐT, Trạng thái
- Drawer thêm/sửa (720px): 2 cột form — Thông tin tài khoản (trái) + Thông tin cá nhân (phải)
- Upload ảnh đại diện (MinIO)
- Popconfirm xóa, nút khóa/mở khóa, reset mật khẩu

### 1.4 Quản lý Nhóm quyền (Role)
> Ref cũ: Manager/Role, Manager/Right, ApiService/RoleController, ApiService/ActionOfRoleController
> UI: Table nhóm quyền + Drawer phân quyền (tree chức năng)

**Database & SP:**
- fn_role_get_list(p_unit_id, p_keyword)
- fn_role_get_by_id(p_id)
- fn_role_create(p_unit_id, p_name, p_description)
- fn_role_update(p_id, ...)
- fn_role_delete(p_id) — check có user nào đang dùng không
- fn_role_get_rights(p_role_id) → Danh sách right_id đã gán
- fn_role_assign_rights(p_role_id, p_right_ids INT[]) — gán quyền
- fn_staff_get_roles(p_staff_id) → Danh sách role đã gán cho nhân viên
- fn_staff_assign_roles(p_staff_id, p_role_ids INT[]) — gán nhóm quyền cho nhân viên

**API:**
- GET /api/quan-tri/nhom-quyen
- POST /api/quan-tri/nhom-quyen
- PUT /api/quan-tri/nhom-quyen/:id
- DELETE /api/quan-tri/nhom-quyen/:id
- GET /api/quan-tri/nhom-quyen/:id/quyen — lấy danh sách quyền
- PUT /api/quan-tri/nhom-quyen/:id/quyen — gán quyền
- GET /api/quan-tri/nguoi-dung/:id/nhom-quyen — lấy roles của user
- PUT /api/quan-tri/nguoi-dung/:id/nhom-quyen — gán roles cho user

**UI:**
- Table nhóm quyền: Tên, Mô tả, Số người dùng, Đơn vị
- Drawer thêm/sửa nhóm quyền
- Tab "Phân quyền": Tree chức năng (checkbox) — tick để gán
- Tab "Thành viên": Danh sách user trong nhóm
- Trong trang Người dùng: nút "Phân quyền" → Drawer chọn nhóm quyền (Transfer panel)

### 1.5 Quản lý Chức năng / Menu (Right)
> Ref cũ: Manager/Action, ApiService/ActionController
> UI: Tree chức năng + Form chi tiết bên phải

**Database & SP:**
- fn_right_get_tree()
- fn_right_get_by_id(p_id)
- fn_right_create(p_parent_id, p_name, p_name_of_menu, p_action_link, p_icon, p_sort_order, p_show_menu, p_default_page, p_show_in_app, p_description)
- fn_right_update(p_id, ...)
- fn_right_delete(p_id) — check có con không
- fn_right_get_by_staff(p_staff_id) → Menu items user được phép truy cập

**API:**
- GET /api/quan-tri/chuc-nang/tree
- POST /api/quan-tri/chuc-nang
- PUT /api/quan-tri/chuc-nang/:id
- DELETE /api/quan-tri/chuc-nang/:id
- GET /api/quan-tri/chuc-nang/menu — lấy menu theo quyền user hiện tại

**UI:**
- Tree bên trái: hiển thị cây chức năng
- Form bên phải: Tên, Tên menu, URL, Icon, Thứ tự, Hiện menu, Trang mặc định, Hiện trên app, Mô tả
- Sidebar menu sẽ được render dynamic từ API này (thay vì hardcode)

---

## Sprint 2: Quản trị hệ thống — Danh mục & Cấu hình

> Ref: Module 10.3–10.13 hệ thống cũ
> Tất cả danh mục con phục vụ cho module Văn bản

### 2.1 Sổ văn bản (DocBook)
> Ref cũ: edoc/DocBook, ApiService/DocBookController
> Table: 3 tab (Văn bản đến | Văn bản đi | Văn bản dự thảo)

**Database & SP:**
- fn_doc_book_get_list(p_type_id, p_unit_id) — type_id: 1=đến, 2=đi, 3=dự thảo
- fn_doc_book_create(p_type_id, p_unit_id, p_name, p_is_default, p_description)
- fn_doc_book_update(p_id, ...)
- fn_doc_book_delete(p_id)
- fn_doc_book_set_default(p_id, p_type_id, p_unit_id)

**API:** GET/POST/PUT/DELETE /api/quan-tri/so-van-ban

**UI:** Card Tabs (Đến | Đi | Dự thảo), mỗi tab 1 table, Drawer thêm/sửa

### 2.2 Phân loại văn bản (DocType)
> Ref cũ: edoc/DocType, Manager/DocumentType
> Cây phân loại cha-con: VB quy phạm PL, VB hành chính, Ban sao...
> Mỗi loại: CV (Công văn), NQ (Nghị quyết), QĐ (Quyết định), CT (Chỉ thị), QC (Quy chế)

**Database & SP:**
- fn_doc_type_get_tree(p_type_id) — type_id: 1=đến, 2=đi, 3=dự thảo
- fn_doc_type_create(p_type_id, p_parent_id, p_name, p_code, p_notation_type, p_sort_order)
- fn_doc_type_update(p_id, ...)
- fn_doc_type_delete(p_id)

**API:** GET/POST/PUT/DELETE /api/quan-tri/loai-van-ban

**UI:** Tree + Table, Drawer thêm/sửa. Fields: Mã, Tên, Phân loại cha, Ký hiệu, Thứ tự

### 2.3 Lĩnh vực văn bản (DocField)
> Ref cũ: edoc/Field, ApiService/FieldController

**Database & SP:**
- fn_doc_field_get_list(p_unit_id, p_keyword)
- fn_doc_field_create(p_unit_id, p_code, p_name)
- fn_doc_field_update / delete

**API:** GET/POST/PUT/DELETE /api/quan-tri/linh-vuc

**UI:** Table đơn giản: Mã, Tên lĩnh vực, Đơn vị

### 2.4 Thuộc tính văn bản (DocColumn)
> Ref cũ: edoc/DocColumn, ApiService/DocColumnController
> Cấu hình các cột/trường hiển thị trên form VB đến, đi, dự thảo

**Database & SP:**
- fn_doc_column_get_list(p_type_id) — 1=đến, 2=đi, 3=dự thảo
- fn_doc_column_update(p_id, p_label, p_is_mandatory, p_is_show_all, p_sort_order)
- fn_doc_column_toggle_visibility(p_id)

**API:** GET/PUT /api/quan-tri/thuoc-tinh-van-ban

**UI:** Card Tabs (Đến | Đi | Dự thảo), mỗi tab = table cấu hình trường. Checkbox bật/tắt hiển thị, bắt buộc

### 2.5 Thông tin Cơ quan (Organization)
> Ref cũ: edoc/Organization

**Database & SP:**
- fn_organization_get(p_unit_id)
- fn_organization_update(p_unit_id, p_code, p_name, p_address, p_phone, p_fax, p_email, p_secretary, p_chairman_number, p_level, p_email_doc, p_is_exchange)

**API:** GET/PUT /api/quan-tri/co-quan

**UI:** Form đơn lẻ (không phải table): Mã, Tên, Địa chỉ, SĐT, Fax, Email, Thư ký, Cấp cơ quan, Email VB, Tham gia trao đổi VBĐT

### 2.6 Quản lý Người ký văn bản (Signer)
> Ref cũ: edoc/Signer, ApiService/SignerController

**Database & SP:**
- fn_signer_get_list(p_unit_id)
- fn_signer_create(p_unit_id, p_department_id, p_staff_id)
- fn_signer_delete(p_id)

**API:** GET/POST/DELETE /api/quan-tri/nguoi-ky

**UI:** Layout: Phòng ban (tree trái) → Cán bộ ký (table phải). Transfer panel chọn người

### 2.7 Nhóm làm việc (Groups)
> Ref cũ: edoc/Groups, ApiService/GroupsController

**Database & SP:**
- fn_group_get_list(p_unit_id)
- fn_group_create(p_unit_id, p_name, p_function, p_sort_order)
- fn_group_update / delete
- fn_group_get_members(p_group_id)
- fn_group_assign_members(p_group_id, p_staff_ids INT[])

**API:** GET/POST/PUT/DELETE /api/quan-tri/nhom-lam-viec + /members

**UI:** Table nhóm + Drawer chi tiết với Transfer panel chọn thành viên

### 2.8 Ủy quyền (Delegation)
> Ref cũ: edoc/Deligation

**Database & SP:**
- fn_delegation_get_list(p_staff_id)
- fn_delegation_create(p_from_staff_id, p_to_staff_id, p_start_date, p_end_date, p_note)
- fn_delegation_revoke(p_id)

**API:** GET/POST/DELETE /api/quan-tri/uy-quyen

**UI:** Table: Người ủy quyền, Người được UQ, Từ ngày, Đến ngày, Ghi chú. Drawer thêm

### 2.9 Địa bàn hành chính (Province/District/Commune)
> Ref cũ: Manager/Province, Manager/District, Manager/Commune

**Database & SP:**
- fn_province_get_list(p_keyword)
- fn_province_create / update / delete
- fn_district_get_list(p_province_id, p_keyword)
- fn_district_create / update / delete
- fn_commune_get_list(p_district_id, p_keyword)
- fn_commune_create / update / delete

**API:** GET/POST/PUT/DELETE cho mỗi cấp

**UI:** 3 tab hoặc cascade: Tỉnh → Huyện → Xã. Click tỉnh → load huyện → click huyện → load xã

### 2.10 Cấu hình lịch làm việc (Calendar Config)
> Ref cũ: Manager/Calendar

**Database & SP:**
- fn_work_calendar_get(p_year)
- fn_work_calendar_set_holiday(p_date, p_description)
- fn_work_calendar_remove_holiday(p_date)

**API:** GET/POST/DELETE /api/quan-tri/lich-lam-viec

**UI:** Calendar view (Ant Design Calendar), đánh dấu ngày nghỉ lễ

### 2.11 Mẫu SMS & Email (Templates)
> Ref cũ: ApiService/SmsMessageController, ApiService/EmailMessageController

**Database & SP:**
- fn_sms_template_get_list(p_unit_id)
- fn_sms_template_create / update / delete
- fn_email_template_get_list(p_unit_id)
- fn_email_template_create / update / delete

**API:** GET/POST/PUT/DELETE /api/quan-tri/mau-sms + /mau-email

**UI:** Table: Tên mẫu, Nội dung (với placeholder [CVNAME], [STAFFNAME]...), Đơn vị. Drawer thêm/sửa

### 2.12 Cấu hình hệ thống (Configuration)
> Ref cũ: ApiService/ConfigurationController

**API:** GET/PUT /api/quan-tri/cau-hinh

**UI:** Form key-value theo đơn vị

---

## Sprint 3: Văn bản đến (Incoming Documents)

> Ref: Module 2.1 hệ thống cũ — Module lớn nhất, core business
> Ref cũ: edoc/Incoming (32 actions), ApiService/IncomingController
> DB table: edoc.incoming_docs, user_incoming_docs, attachment_incoming_docs, leader_notes, staff_notes

### 3.1 Danh sách Văn bản đến
**Database & SP:**
- fn_incoming_doc_get_list(p_unit_id, p_staff_id, p_doc_book_id, p_doc_field_id, p_doc_type_id, p_is_read, p_status, p_from_date, p_to_date, p_keyword, p_page, p_page_size)
- fn_incoming_doc_count_unread(p_unit_id, p_staff_id) — cho dashboard widget
- fn_incoming_doc_mark_read(p_doc_id, p_staff_id)
- fn_incoming_doc_mark_read_bulk(p_doc_ids INT[], p_staff_id)

**API:**
- GET /api/van-ban/den?filters...
- PATCH /api/van-ban/den/danh-dau-da-doc

**UI:**
- Filter bar: Sổ VB, Lĩnh vực, Loại VB, Từ ngày-Đến ngày, Trạng thái, Keyword
- "Tìm kiếm nâng cao" mở rộng thêm filter
- Table columns: #, Ngày đến, Số đến, Số Ký hiệu, Trích yếu, Cơ quan ban hành, Tài liệu (icon file), Trạng thái đọc
- Toolbar: Thêm mới, Đánh dấu đã đọc (bulk), In danh sách (export Excel/PDF)
- Row actions: Xem chi tiết, Sửa, Xóa (Popconfirm)
- VB chưa đọc: in đậm

### 3.2 Thêm / Sửa Văn bản đến
**Database & SP:**
- fn_incoming_doc_create(p_unit_id, p_received_date, p_number, p_notation, p_document_code, p_abstract, p_publish_unit, p_publish_date, p_signer, p_sign_date, p_number_paper, p_number_copies, p_secret_id, p_urgent_id, p_doc_book_id, p_doc_type_id, p_doc_field_id, p_expired_date, p_is_received_paper, p_recipients TEXT, p_created_by)
- fn_incoming_doc_update(p_id, ...)
- fn_incoming_doc_delete(p_id)
- fn_incoming_doc_get_next_number(p_doc_book_id, p_year) — tự tăng số đến

**API:**
- POST /api/van-ban/den
- PUT /api/van-ban/den/:id
- DELETE /api/van-ban/den/:id

**UI:**
- Drawer (720px), 2 cột form:
  - **Trái:** Người nhận, Ngày đến, Số đến (auto), Cơ quan phát hành, Trích yếu (textarea), Người ký, Hạn giải quyết, Nơi nhận, Độ mật, Trạng thái VB giấy, Trạng thái lưu trữ
  - **Phải:** Số văn bản, Số Ký hiệu, Loại văn bản (Select), Ngày ký, Lĩnh vực (Select), Độ khẩn (Thường/Khẩn/Hỏa tốc), Số bản, Ngày nhận, Sổ văn bản (Select)

### 3.3 Chi tiết Văn bản đến (Page riêng)
**Database & SP:**
- fn_incoming_doc_get_by_id(p_id, p_staff_id) — trả đầy đủ + đánh dấu đã đọc
- fn_incoming_doc_get_recipients(p_doc_id) — danh sách người nhận + trạng thái đọc
- fn_incoming_doc_get_history(p_doc_id) — lịch sử xử lý (timeline)

**API:**
- GET /api/van-ban/den/:id
- GET /api/van-ban/den/:id/nguoi-nhan
- GET /api/van-ban/den/:id/lich-su

**UI:**
- **Layout 2 cột:**
  - Trái (65%): Thông tin VB (dạng Descriptions), file đính kèm (preview/download), Gửi nhanh
  - Phải (35%): Timeline lịch sử xử lý, danh sách người nhận + trạng thái đọc
- **Toolbar actions trên:** Nhận bàn giao, Hủy duyệt, Bút phê, Thêm vào HSCV, Giao việc, Gửi, Chuyển lại HĐ, Đánh dấu cá nhân

### 3.4 File đính kèm (Attachment)
**Database & SP:**
- fn_attachment_incoming_create(p_doc_id, p_file_name, p_file_path, p_file_size, p_file_type, p_uploaded_by)
- fn_attachment_incoming_delete(p_id)
- fn_attachment_incoming_get_list(p_doc_id)

**API:**
- POST /api/van-ban/den/:id/dinh-kem (multipart → MinIO)
- DELETE /api/van-ban/den/:id/dinh-kem/:attachmentId
- GET /api/van-ban/den/:id/dinh-kem/:attachmentId/download

**UI:** Upload area (drag & drop), danh sách file (icon, tên, size, download, xóa), preview PDF/ảnh inline

### 3.5 Gửi nhanh / Phân phối (Send/Distribute)
> Ref cũ: Screen 2_5 — Chọn người nhận checkbox, Radio Gửi nhanh / Lãnh đạo UBND

**Database & SP:**
- fn_incoming_doc_send(p_doc_id, p_staff_ids INT[], p_send_type, p_sent_by)
- fn_incoming_doc_get_sendable_staff(p_unit_id) — danh sách cán bộ có thể gửi

**API:**
- POST /api/van-ban/den/:id/gui
- GET /api/van-ban/den/:id/danh-sach-gui

**UI:** Checkbox list cán bộ (nhóm theo phòng ban), Radio: Gửi nhanh / Lãnh đạo. Nút Gửi

### 3.6 Bút phê lãnh đạo (Leader Notes)
> Ref cũ: leader_notes table

**Database & SP:**
- fn_leader_note_create(p_doc_id, p_staff_id, p_content, p_note_type)
- fn_leader_note_get_list(p_doc_id)
- fn_leader_note_delete(p_id)

**API:**
- GET /api/van-ban/den/:id/but-phe
- POST /api/van-ban/den/:id/but-phe
- DELETE /api/van-ban/den/:id/but-phe/:noteId

**UI:** Trong trang chi tiết VB — section bút phê: danh sách bút phê (tên lãnh đạo, nội dung, ngày), form thêm bút phê mới

### 3.7 Đánh dấu cá nhân (Staff Notes / Bookmarks)
> Ref cũ: staff_notes table

**Database & SP:**
- fn_staff_note_toggle(p_doc_id, p_staff_id, p_doc_type, p_note)
- fn_staff_note_get_list(p_staff_id, p_doc_type)

**API:**
- POST /api/van-ban/den/:id/danh-dau
- GET /api/van-ban/danh-dau-ca-nhan

**UI:** Icon bookmark trên toolbar chi tiết VB. Trang riêng "VB đánh dấu cá nhân"

### 3.8 In danh sách (Print/Export)
**API:**
- GET /api/van-ban/den/export?format=xlsx&filters...
- GET /api/van-ban/den/export?format=pdf&filters...

**UI:** Nút "In danh sách" trên toolbar → dropdown (Excel, PDF). Xuất theo filter hiện tại

---

## Sprint 4: Văn bản đi & Văn bản dự thảo

> Ref: Module 2.3 + 2.4 hệ thống cũ
> Ref cũ: edoc/Outgoing, edoc/Drafting controllers
> Flow: Dự thảo → Trình ký → Phát hành (VB đi)

### 4.1 Văn bản dự thảo (Drafting)
**Database & SP:**
- fn_drafting_doc_get_list(p_unit_id, p_staff_id, p_doc_book_id, p_doc_type_id, p_keyword, p_from_date, p_to_date, p_is_released, p_page, p_page_size)
- fn_drafting_doc_create(p_unit_id, p_received_date, p_number, p_sub_number, p_notation, p_abstract, p_drafting_unit_id, p_drafting_user_id, p_signer, p_doc_book_id, p_doc_type_id, p_doc_field_id, p_expired_date, p_secret_id, p_urgent_id, p_created_by)
- fn_drafting_doc_update(p_id, ...)
- fn_drafting_doc_delete(p_id)
- fn_drafting_doc_release(p_id, p_released_by) — Phát hành → chuyển thành VB đi

**API:** CRUD + POST /api/van-ban/du-thao/:id/phat-hanh

**UI:**
- Danh sách: Table columns — #, Ngày đề, Số đề, Ký hiệu, Trích yếu, Nơi nhận, Trạng thái (Dự thảo / Đã phát hành)
- Drawer thêm/sửa: 2 cột form tương tự VB đến, thêm: Đơn vị soạn, Người soạn
- Chi tiết: Page riêng, layout 2 cột
- Upload đính kèm (tương tự VB đến)

### 4.2 Văn bản đi / Phát hành (Outgoing)
**Database & SP:**
- fn_outgoing_doc_get_list(p_unit_id, p_staff_id, p_doc_book_id, p_doc_type_id, p_keyword, p_from_date, p_to_date, p_page, p_page_size)
- fn_outgoing_doc_create(...) — tương tự drafting + publish fields
- fn_outgoing_doc_update / delete
- fn_outgoing_doc_count_unread(p_unit_id, p_staff_id) — dashboard widget
- fn_outgoing_doc_mark_read(p_doc_id, p_staff_id)
- fn_outgoing_doc_get_next_number(p_doc_book_id, p_year)

**API:** CRUD /api/van-ban/di + mark read + export

**UI:**
- Danh sách: Columns — #, Ngày đề, Số đề, Ký Số, Ký Hiệu, Trích yếu, Tài liệu
- Toolbar: Thêm mới, Đánh dấu đã đọc, In danh sách
- Drawer thêm/sửa, Chi tiết page, Đính kèm, Gửi/phân phối

### 4.3 Luồng Dự thảo → Trình ký → Phát hành
**Database & SP:**
- fn_drafting_doc_submit_for_approval(p_id, p_submitted_by) — trình ký
- fn_drafting_doc_approve(p_id, p_approved_by) — duyệt
- fn_drafting_doc_reject(p_id, p_rejected_by, p_reason) — từ chối
- fn_drafting_doc_release(p_id, p_released_by) — phát hành

**UI:** Status badges trên danh sách + action buttons trên chi tiết (Trình ký, Duyệt, Từ chối, Phát hành)

---

## Sprint 5: Hồ sơ công việc — Core

> Ref: Module 3.1–3.3 hệ thống cũ
> Ref cũ: edoc/HandlingDoc, ApiService/HandlingDocController
> DB table: edoc.handling_docs, staff_handling_docs, handling_doc_links, opinion_handling_docs, attachment_handling_docs

### 5.1 Danh sách HSCV + Sub-menus theo trạng thái
**Database & SP:**
- fn_handling_doc_get_list(p_unit_id, p_department_id, p_staff_id, p_status, p_filter_type, p_keyword, p_from_date, p_to_date, p_page, p_page_size)
  - filter_type: 'all' | 'created_by_me' | 'rejected' | 'returned' | 'pending_primary' | 'pending_coord' | 'submitting' | 'in_progress' | 'proposed_complete' | 'completed'
- fn_handling_doc_count_by_status(p_unit_id, p_staff_id) — count cho sidebar badges

**API:** GET /api/ho-so-cong-viec?filter_type=&status=&...

**UI:**
- Sidebar sub-menu (hoặc tab/filter): Toàn bộ, Tôi tạo (bị từ chối), Trả về bổ sung, Chưa XL phụ trách, Chưa XL phối hợp, Trình ký, Đang giải quyết, Đề xuất hoàn thành, Đã hoàn thành
- Badge count trên mỗi sub-menu
- Table columns: Tên HSCV, Ngày mở, Hạn giải quyết, Trạng thái (Tag màu), Phụ trách, Lãnh đạo ký, Tiến độ (Progress bar %)

### 5.2 Thêm / Sửa HSCV
**Database & SP:**
- fn_handling_doc_create(p_unit_id, p_department_id, p_doc_type_id, p_doc_field_id, p_name, p_comments, p_start_date, p_end_date, p_curator_id, p_signer_id, p_workflow_id, p_is_from_doc, p_parent_id, p_created_by)
- fn_handling_doc_update(p_id, ...)
- fn_handling_doc_delete(p_id)

**API:** CRUD /api/ho-so-cong-viec

**UI:** Drawer (720px): Tên HSCV, Loại VB, Lĩnh vực, Ghi chú, Ngày mở, Hạn giải quyết, Người phụ trách (Select), Lãnh đạo ký (Select), Quy trình (Select), HSCV cha (nếu tạo con)

### 5.3 Chi tiết HSCV (Page riêng)
**Database & SP:**
- fn_handling_doc_get_by_id(p_id)
- fn_handling_doc_get_linked_docs(p_id) — VB liên kết
- fn_handling_doc_get_staff(p_id) — Cán bộ tham gia (phụ trách + phối hợp)
- fn_handling_doc_get_opinions(p_id) — Ý kiến xử lý
- fn_handling_doc_get_attachments(p_id)
- fn_handling_doc_get_children(p_id) — HSCV con

**API:**
- GET /api/ho-so-cong-viec/:id (full detail)
- GET /api/ho-so-cong-viec/:id/van-ban-lien-ket
- GET /api/ho-so-cong-viec/:id/can-bo
- GET /api/ho-so-cong-viec/:id/y-kien

**UI:**
- Card tabs: Thông tin chung | Văn bản liên kết | Cán bộ xử lý | Ý kiến xử lý | File đính kèm | HSCV con
- Toolbar: Chuyển xử lý, Trình ký, Duyệt, Từ chối, Trả về, Hoàn thành

### 5.4 Giao việc / Phân công (Assignment)
> Ref cũ: Screen 3_3 — Transfer panel chọn người theo Phòng ban

**Database & SP:**
- fn_handling_doc_assign_staff(p_doc_id, p_staff_ids INT[], p_role_type, p_deadline, p_assigned_by)
  - role_type: 'primary' (phụ trách) | 'coordinator' (phối hợp)
- fn_handling_doc_remove_staff(p_doc_id, p_staff_id)

**API:**
- POST /api/ho-so-cong-viec/:id/phan-cong
- DELETE /api/ho-so-cong-viec/:id/phan-cong/:staffId

**UI:** Transfer panel (Phòng ban tree trái → Cán bộ chọn phải), Radio phụ trách/phối hợp, Hạn xử lý

### 5.5 Ý kiến xử lý (Opinions)
**Database & SP:**
- fn_opinion_create(p_doc_id, p_staff_id, p_content, p_opinion_type)
- fn_opinion_get_list(p_doc_id)

**API:** GET/POST /api/ho-so-cong-viec/:id/y-kien

**UI:** Trong tab "Ý kiến" — danh sách comment (avatar, tên, nội dung, ngày) + form thêm ý kiến

### 5.6 Liên kết VB ↔ HSCV
**Database & SP:**
- fn_handling_doc_link_doc(p_handling_doc_id, p_doc_id, p_doc_type, p_linked_by)
  - doc_type: 'incoming' | 'outgoing' | 'drafting'
- fn_handling_doc_unlink_doc(p_link_id)

**API:** POST/DELETE /api/ho-so-cong-viec/:id/lien-ket-van-ban

**UI:** Trong tab "VB liên kết" — Table VB đã link + nút "Thêm VB" mở modal search VB

### 5.7 Chuyển trạng thái HSCV
**Database & SP:**
- fn_handling_doc_change_status(p_id, p_new_status, p_changed_by, p_reason)
- fn_handling_doc_submit(p_id, p_submitted_by) — trình ký
- fn_handling_doc_approve(p_id, p_approved_by) — duyệt
- fn_handling_doc_reject(p_id, p_rejected_by, p_reason) — từ chối
- fn_handling_doc_return(p_id, p_returned_by, p_reason) — trả về
- fn_handling_doc_complete(p_id, p_completed_by) — hoàn thành
- fn_handling_doc_update_progress(p_id, p_progress) — cập nhật tiến độ %

**API:** PATCH /api/ho-so-cong-viec/:id/trang-thai

---

## Sprint 6: Hồ sơ công việc — Workflow & Báo cáo

> Ref: Module 3.4–3.5 hệ thống cũ
> Ref cũ: edoc/Workflow (V2), edoc/Report, Manager/Workflow

### 6.1 Quy trình xử lý (Workflow Designer)
> Ref cũ: Screen 3_5 — Visual flowchart: Bắt đầu → Soạn → Hành động → Kết thúc

**Database & SP:**
- fn_doc_flow_get_list(p_unit_id, p_doc_field_id, p_is_active)
- fn_doc_flow_get_by_id(p_id) — trả kèm steps + staff
- fn_doc_flow_create(p_unit_id, p_name, p_version, p_doc_field_id)
- fn_doc_flow_update / delete / activate / deactivate
- fn_doc_flow_step_create(p_flow_id, p_step_name, p_step_order, p_step_type, p_allow_sign, p_deadline_days)
- fn_doc_flow_step_update / delete
- fn_doc_flow_step_assign_staff(p_step_id, p_staff_ids INT[])
- fn_doc_flow_step_link_create(p_from_step_id, p_to_step_id)
- fn_doc_flow_step_link_delete(p_link_id)

**API:** CRUD /api/quan-tri/quy-trinh + /steps + /links

**UI:**
- Danh sách quy trình: Table (Tên, Lĩnh vực, Version, Trạng thái active/inactive)
- **Trang thiết kế quy trình (page riêng):**
  - Canvas kéo thả flowchart (dùng ReactFlow hoặc tương đương)
  - Node types: Bắt đầu (circle), Bước xử lý (rectangle), Kết thúc (circle)
  - Connection arrows giữa các bước
  - Click node → Panel bên phải: Tên bước, Loại bước, Cho phép trình ký, Danh sách cán bộ (Transfer panel), Thời hạn

### 6.2 Kiểm soát công việc — KPI Dashboard
> Ref cũ: Screen 3_4 — Tổng quan công việc

**Database & SP:**
- fn_handling_doc_kpi(p_unit_id, p_from_date, p_to_date)
  → Trả về: Tổng số, Chuyển kỳ trước, Kỳ này, Hoàn thành, Đang thực hiện, Quá hạn, % quá hạn
- fn_handling_doc_kpi_by_staff(p_unit_id, p_from_date, p_to_date)
  → Theo từng cán bộ

**API:** GET /api/ho-so-cong-viec/thong-ke/kpi?unit_id=&from=&to=

**UI:**
- KPI cards (gradient): Tổng số, Chuyển kỳ trước, Kỳ này, Hoàn thành, Đang thực hiện, Quá hạn %
- Biểu đồ tiến độ (Ant Design Charts — Bar/Pie)

### 6.3 Báo cáo thống kê HSCV
> Ref cũ: 3 báo cáo: Tình hình tại đơn vị, Giải quyết công việc, Theo cán bộ giao việc

**Database & SP:**
- fn_report_handling_by_unit(p_unit_id, p_from_date, p_to_date)
- fn_report_handling_by_resolver(p_unit_id, p_from_date, p_to_date)
- fn_report_handling_by_assigner(p_unit_id, p_from_date, p_to_date)

**API:**
- GET /api/ho-so-cong-viec/bao-cao/theo-don-vi
- GET /api/ho-so-cong-viec/bao-cao/theo-can-bo
- GET /api/ho-so-cong-viec/bao-cao/theo-nguoi-giao

**UI:**
- Card tabs cho 3 loại báo cáo
- Filter: Đơn vị, Từ ngày - Đến ngày
- Bảng thống kê + biểu đồ (Chart)
- Nút Export Excel

---

## Sprint 7: Văn bản liên thông & Giao việc từ VB

> Ref: Module 2.2 hệ thống cũ + Action buttons trên chi tiết VB đến

### 7.1 Văn bản liên thông (Inter-agency docs)
> Ref cũ: edoc/InterIncoming, ApiService — bản chất là VB đến từ LGSP

**Database & SP:**
- fn_inter_incoming_get_list(p_unit_id, p_keyword, p_from_date, p_to_date, p_page, p_page_size)
- fn_inter_incoming_create(...) — tạo từ dữ liệu LGSP parse
- fn_inter_incoming_get_by_id(p_id)

**API:** GET /api/van-ban/lien-thong + /:id

**UI:**
- Table columns: Ngày nhận, Ký hiệu, Trích yếu, Hạn trả lời, Đơn vị phát hành, Người ký
- Chi tiết: Page riêng tương tự VB đến

### 7.2 Giao việc từ Văn bản (Create HSCV from Doc)
> Ref cũ: Nút "Thêm vào HSCV" + "Giao việc" trên toolbar chi tiết VB đến

**Database & SP:**
- fn_handling_doc_create_from_doc(p_doc_id, p_doc_type, p_name, p_start_date, p_end_date, p_curator_id, p_created_by)
  — Tạo HSCV mới + tự động link VB

**API:** POST /api/van-ban/den/:id/giao-viec

**UI:** Nút "Giao việc" trên toolbar → Drawer tạo HSCV nhanh (tự fill trích yếu, hạn xử lý) + chọn người phụ trách

### 7.3 Nhận bàn giao / Chuyển lại / Hủy duyệt
> Ref cũ: Các action trên toolbar chi tiết VB đến

**Database & SP:**
- fn_incoming_doc_handover(p_doc_id, p_staff_id) — nhận bàn giao
- fn_incoming_doc_return(p_doc_id, p_returned_by, p_reason) — chuyển lại
- fn_incoming_doc_cancel_approve(p_doc_id, p_cancelled_by) — hủy duyệt

**API:** POST /api/van-ban/den/:id/nhan-ban-giao, /chuyen-lai, /huy-duyet

**UI:** Buttons trên toolbar chi tiết VB đến + Popconfirm/modal xác nhận

---

## Sprint 8: Tin nhắn nội bộ & Thông báo

> Ref: Module 4 + Module 5.1 hệ thống cũ
> Ref cũ: edoc/InternalMessages, ApiService/InternalMessagesController, ApiService/MessageRepliesController

### 8.1 Tin nhắn nội bộ
**Database & SP:**
- fn_message_get_inbox(p_staff_id, p_keyword, p_page, p_page_size)
- fn_message_get_sent(p_staff_id, p_keyword, p_page, p_page_size)
- fn_message_get_trash(p_staff_id, p_page, p_page_size)
- fn_message_get_by_id(p_id, p_staff_id) — đánh dấu đã đọc
- fn_message_create(p_from_staff_id, p_to_staff_ids INT[], p_subject, p_content, p_parent_id)
- fn_message_reply(p_message_id, p_staff_id, p_content)
- fn_message_delete(p_id, p_staff_id) — soft delete (chuyển thùng rác)
- fn_message_delete_permanent(p_id, p_staff_id) — xóa vĩnh viễn
- fn_message_count_unread(p_staff_id) — cho badge notification

**API:** CRUD /api/tin-nhan + /reply + /trash

**UI:**
- Layout mail-like: Sidebar (Hộp thư đến, Đã gửi, Thùng rác) + List + Detail
- Soạn tin: Select người nhận (multi-select), Subject, Content (rich text)
- Badge count tin chưa đọc
- Tìm kiếm

### 8.2 Thông báo hệ thống (Notice)
> Ref cũ: edoc/Notice, ApiService/NoticeController

**Database & SP:**
- fn_notice_get_list(p_unit_id, p_staff_id, p_page, p_page_size)
- fn_notice_create(p_unit_id, p_title, p_content, p_notice_type, p_created_by)
- fn_notice_mark_read(p_notice_id, p_staff_id)
- fn_notice_count_unread(p_staff_id) — cho bell icon

**API:** CRUD /api/thong-bao

**UI:**
- Notification bell (header) → Dropdown danh sách thông báo mới
- Trang thông báo: Table/List (Tiêu đề, Nội dung, Ngày, Trạng thái đọc)
- Admin: tạo thông báo mới (Drawer)

### 8.3 Realtime (Socket.IO)
- Backend: Socket.IO server tích hợp Express
- Events: new_document, new_message, new_notification, doc_status_changed
- Frontend: socket.io-client, auto connect khi login, listen events → toast notification + badge update

---

## Sprint 9: Lịch & Danh bạ

> Ref: Module 5.2–5.6 hệ thống cũ
> Ref cũ: edoc/CalendarEvent, edoc/CalendarLeaderPublic, edoc/ShortCalendar

### 9.1 Lịch cá nhân
**Database & SP:**
- fn_calendar_event_get(p_staff_id, p_from_date, p_to_date)
- fn_calendar_event_create(p_staff_id, p_title, p_description, p_start_time, p_end_time, p_location, p_repeat_type, p_color)
- fn_calendar_event_update / delete

**API:** CRUD /api/lich/ca-nhan

**UI:** Ant Design Calendar (month/week view), click ngày → popover tạo sự kiện, event cards có màu

### 9.2 Lịch cơ quan
**Database & SP:**
- fn_calendar_office_get(p_unit_id, p_from_date, p_to_date)
- fn_calendar_office_create(p_unit_id, p_title, p_content, p_event_date, p_location, p_participants, p_created_by)
- fn_calendar_office_update / delete

**API:** CRUD /api/lich/co-quan

**UI:** Calendar view, chỉ admin/văn thư được tạo. Có view "Rút gọn" (list tuần)

### 9.3 Lịch lãnh đạo
**Database & SP:**
- fn_calendar_leader_get(p_unit_id, p_from_date, p_to_date)
- fn_calendar_leader_create(...)
- fn_calendar_leader_update / delete

**API:** CRUD /api/lich/lanh-dao

**UI:** Calendar view riêng cho lãnh đạo, cấu hình ai được xem

### 9.4 Danh bạ điện thoại
**Database & SP:**
- fn_phonebook_get(p_unit_id, p_department_id, p_keyword) — lấy từ bảng staff

**API:** GET /api/danh-ba

**UI:** Table: Họ tên, Chức vụ, Phòng ban, SĐT, Email. Filter theo đơn vị/phòng ban. Search by name

---

## Sprint 10: Dashboard hoàn thiện

> Ref: Module 1 hệ thống cũ — Tổng quan
> Hoàn thiện dashboard với dữ liệu thật + widget configurable

### 10.1 Dashboard Widgets (dữ liệu thật)
**Database & SP:**
- fn_dashboard_get_stats(p_unit_id, p_staff_id) → VB đến chưa đọc, VB đi chưa đọc, HSCV tổng, Việc sắp tới hạn
- fn_dashboard_get_upcoming_tasks(p_staff_id, p_limit) → Danh sách việc sắp tới hạn
- fn_dashboard_get_recent_incoming(p_unit_id, p_staff_id, p_limit) → VB đến mới nhất
- fn_dashboard_get_recent_outgoing(p_unit_id, p_staff_id, p_limit) → VB đi mới nhất

**API:**
- GET /api/dashboard/stats
- GET /api/dashboard/viec-sap-toi-han
- GET /api/dashboard/van-ban-moi

**UI:**
- 4 KPI cards (dữ liệu thật, click → navigate tới danh sách tương ứng)
- Widget "Văn bản mới nhận": Table 5-10 dòng gần nhất + link "Xem thêm"
- Widget "Việc sắp tới hạn": List (Tên, Ngày mở, Trạng thái, Tiến độ %) + link "Xem thêm"
- Widget "Văn bản đi mới": Table gần nhất

### 10.2 Widget Layout (react-grid-layout)
- Cho phép user kéo thả sắp xếp widget
- Lưu layout vào localStorage hoặc configurations table
- Responsive breakpoints

---

## Sprint 11: Kho lưu trữ

> Ref: Module 8 hệ thống cũ
> Ref cũ: Storage Area — 9 controllers (DocumentArchive, Record, Fond, Warehouse, Borrower, RegistrasionList...)

### 11.1 Danh mục Kho (Warehouse/Fond)
**Database & SP:**
- CRUD cho: esto.warehouses, esto.fonds, esto.doc_types_archive
- fn_warehouse_get_tree() — Phòng lưu trữ → Kho → Kệ
- fn_fond_get_list()

**API:** CRUD /api/kho-luu-tru/kho + /phong + /loai-van-kien

**UI:** Tree + Table (master-detail)

### 11.2 Quản lý Hồ sơ lưu trữ (Document Archive)
**Database & SP:**
- fn_doc_archive_get_list(p_warehouse_id, p_fond_id, p_keyword, p_page, p_page_size)
- fn_doc_archive_create(p_title, p_archive_number, p_warehouse_id, p_fond_id, p_doc_type_id, p_start_date, p_end_date, p_total_pages, p_description, p_created_by)
- fn_doc_archive_update / delete

**API:** CRUD /api/kho-luu-tru/ho-so

**UI:** Table + Drawer thêm/sửa. Fields: Số hồ sơ, Tiêu đề, Kho, Phông, Loại, Từ ngày-Đến ngày, Số trang

### 11.3 Mượn trả hồ sơ (Borrowing)
**Database & SP:**
- fn_borrow_request_create(p_doc_archive_id, p_borrower_staff_id, p_borrow_date, p_expected_return_date, p_purpose)
- fn_borrow_request_approve(p_id, p_approved_by)
- fn_borrow_request_return(p_id, p_returned_date, p_returned_by)
- fn_borrow_request_get_list(p_status, p_page, p_page_size)

**API:** CRUD /api/kho-luu-tru/muon-tra

**UI:** Table: Hồ sơ, Người mượn, Ngày mượn, Hạn trả, Trạng thái (Chờ duyệt/Đang mượn/Đã trả). Actions: Duyệt, Trả

---

## Sprint 12: Tài liệu chung & Hợp đồng

> Ref: Module 7 + Module 9 hệ thống cũ

### 12.1 Tài liệu chung
> Ref cũ: ISO Area — IsoDocument controller
> Categories: Đào tạo, Nội bộ, ISO, Pháp quy, Khác, VB đến

**Database & SP:**
- fn_shared_doc_get_list(p_category_id, p_keyword, p_page, p_page_size)
- fn_shared_doc_create(p_category_id, p_title, p_description, p_created_by)
- fn_shared_doc_update / delete
- fn_shared_doc_category_get_list()
- fn_shared_doc_category_create / update / delete

**API:** CRUD /api/tai-lieu + /danh-muc

**UI:**
- Sidebar categories (Đào tạo, Nội bộ, ISO...) + Table tài liệu
- Upload file đính kèm (MinIO)
- Drawer thêm/sửa

### 12.2 Hợp đồng
> Ref cũ: Contract Area — Contract + ContractType controllers

**Database & SP:**
- fn_contract_get_list(p_type_id, p_keyword, p_from_date, p_to_date, p_page, p_page_size)
- fn_contract_create(p_type_id, p_contract_number, p_title, p_partner, p_sign_date, p_start_date, p_end_date, p_value, p_description, p_created_by)
- fn_contract_update / delete
- fn_contract_type_get_list()
- fn_contract_type_create / update / delete

**API:** CRUD /api/hop-dong + /loai-hop-dong

**UI:**
- Table: Số HĐ, Tiêu đề, Đối tác, Ngày ký, Thời hạn, Giá trị, Loại, Trạng thái
- Drawer thêm/sửa (720px)
- Upload file HĐ scan (MinIO)
- DM Loại hợp đồng: Table đơn giản

---

## Sprint 13: Họp không giấy

> Ref: Module 6 hệ thống cũ
> Ref cũ: edoc/Room, RoomSchedule, RoomScheduleCalendar, RoomScheduleDetail, RoomGroups, Vote

### 13.1 Quản lý Phòng họp & Loại cuộc họp (Danh mục)
**Database & SP:**
- CRUD cho: meeting_rooms, meeting_types
- fn_room_get_list(p_unit_id)

**API:** CRUD /api/hop/phong-hop + /loai-cuoc-hop

### 13.2 Quản lý Cuộc họp
**Database & SP:**
- fn_meeting_get_list(p_unit_id, p_status, p_from_date, p_to_date, p_page, p_page_size)
  - status: 'upcoming' | 'in_progress' | 'pending_approval' | 'completed'
- fn_meeting_create(p_unit_id, p_room_id, p_type_id, p_title, p_content, p_start_time, p_end_time, p_chairperson_id, p_participants INT[], p_created_by)
- fn_meeting_update / delete / approve / reject
- fn_meeting_get_by_id(p_id)

**API:** CRUD /api/hop/cuoc-hop + /approve + /reject

**UI:**
- Sub-menus: Đang diễn ra, Chờ phê duyệt, Sắp tới
- Đăng ký lịch họp (Drawer/Page): Phòng, Loại, Tiêu đề, Nội dung, Thời gian, Chủ trì, Thành viên (Transfer)
- Calendar view lịch phòng họp

### 13.3 Biểu quyết (Vote)
> Ref cũ: edoc/Vote — Realtime voting trong cuộc họp

**Database & SP:**
- fn_vote_create(p_meeting_id, p_question, p_options JSONB, p_created_by)
- fn_vote_cast(p_vote_id, p_staff_id, p_option_index)
- fn_vote_get_results(p_vote_id)

**API:** POST /api/hop/cuoc-hop/:id/bieu-quyet

**UI:** Trong chi tiết cuộc họp — tạo câu hỏi + options, realtime kết quả (Socket.IO)

### 13.4 Thống kê cuộc họp
**Database & SP:**
- fn_meeting_statistics(p_unit_id, p_from_date, p_to_date)

**API:** GET /api/hop/thong-ke

**UI:** Charts: số cuộc họp theo tháng, theo phòng, theo loại

---

## Sprint 14: Tích hợp — LGSP Liên thông văn bản

> Ref cũ: LgspController, LgspEdocController, VNPT.Get/Send services
> Endpoint: https://apiltvb.langson.gov.vn
> Format: edXML

### 14.1 LGSP Token Manager
- OAuth2 authentication với LGSP server
- Token caching (Redis, 29 min TTL)
- Auto refresh token

### 14.2 Nhận văn bản liên thông (Receive)
- Worker (BullMQ): Polling LGSP API định kỳ
- Parse edXML → tạo VB liên thông đến
- Download file đính kèm → MinIO
- Gửi thông báo realtime

### 14.3 Gửi văn bản liên thông (Send)
- API: POST /api/van-ban/di/:id/gui-lien-thong
- Convert VB đi → edXML format
- Upload lên LGSP API
- Tracking trạng thái gửi

### 14.4 Tra cứu cơ quan liên thông
- Đồng bộ danh sách cơ quan từ LGSP
- Select cơ quan khi gửi VB liên thông

---

## Sprint 15: Tích hợp — Ký số điện tử

> Ref cũ: SignPDFController, Vgca controller, EsignNEAC, SmartCA_VNPT

### 15.1 VNPT SmartCA (ký số từ xa)
- Tích hợp SDK VNPT SmartCA
- API: POST /api/ky-so/smart-ca/sign
- Flow: Chọn file → Gọi SmartCA API → Xác thực OTP → Ký → Lưu file đã ký

### 15.2 EsignNEAC (ký số đa CA)
- Tích hợp EsignNEAC API
- Hỗ trợ nhiều nhà cung cấp CA
- Xác thực chứng thư số

### 15.3 UI Ký số
- Nút "Ký số" trên toolbar VB đi / VB dự thảo
- Modal chọn phương thức ký (SmartCA / Token USB / EsignNEAC)
- Preview PDF trước khi ký
- Hiển thị trạng thái đã ký (badge + thông tin chữ ký)

---

## Sprint 16: Tích hợp — Thông báo đa kênh

> Ref cũ: FcmWindowsService, ZaloMessage, SmsController, EmailMessageController

### 16.1 Firebase FCM (Push notification)
- Worker (BullMQ): fcm-push
- Gửi push khi: nhận VB mới, giao việc, deadline sắp tới
- Lưu device token vào DB

### 16.2 Zalo OA API
- Worker (BullMQ): zalo-send
- Gửi thông báo VB qua Zalo Official Account
- Template message theo sự kiện

### 16.3 SMS Gateway
- Worker (BullMQ): sms-send
- Gửi SMS theo template (đã cấu hình ở Sprint 2)
- Template: "Công việc: [CVNAME] sắp đến hạn giải quyết"

### 16.4 Email Notification
- Worker (BullMQ): email-send
- Nodemailer + templates
- Gửi khi: nhận VB, giao việc, nhắc deadline

---

## Sprint 17: Redirect pages & Polish

### 17.1 Menu Redirect (VNPT/Viettel)
> Ref cũ: Top nav menu redirect sang trang đối tác

- VNPT Invoice → redirect URL
- Viettel Invoice → redirect URL
- VNPT Contract → redirect URL
- Viettel Contract → redirect URL
- VNPT BHXH → redirect URL
- Viettel BHXH → redirect URL
- VNPT Tax → redirect URL

**UI:** Menu items mở tab mới (target="_blank"). URL cấu hình trong bảng configurations

### 17.2 Dynamic Sidebar Menu
- Sidebar render từ API fn_right_get_by_staff (thay vì hardcode)
- Menu items redirect → open new tab
- Badge counts realtime (VB chưa đọc, tin nhắn, thông báo)

### 17.3 Responsive & Mobile
- Responsive breakpoints cho tất cả trang
- Hamburger menu trên mobile/tablet
- Touch-friendly tables (horizontal scroll)
- PWA manifest (optional)

### 17.4 Polish & UX
- Skeleton loading cho mọi trang
- Empty states (illustration + CTA)
- Error boundaries
- Toast notifications thống nhất
- Keyboard shortcuts (Ctrl+N tạo mới, Ctrl+S lưu...)
- Print stylesheets

---

## Tổng kết Sprint

| Sprint | Module | Ước lượng tasks |
|--------|--------|----------------|
| **0** ✅ | Infrastructure + Auth + Layout | Done |
| **1** | Quản trị — Core (Department, Position, Staff, Role, Right) | ~25 SP, 20 API, 5 pages |
| **2** | Quản trị — Danh mục (DocBook, DocType, DocField, DocColumn, Org, Signer, Groups, Delegation, Address, Calendar, Templates, Config) | ~35 SP, 30 API, 12 pages |
| **3** | Văn bản đến (full CRUD + detail + attachments + send + notes + export) | ~20 SP, 15 API, 3 pages |
| **4** | Văn bản đi + Dự thảo (CRUD + approval flow) | ~15 SP, 12 API, 4 pages |
| **5** | HSCV — Core (CRUD + assignment + opinions + links + status) | ~20 SP, 18 API, 3 pages |
| **6** | HSCV — Workflow designer + Báo cáo/KPI | ~15 SP, 10 API, 4 pages |
| **7** | VB liên thông + Giao việc từ VB + Actions VB | ~10 SP, 8 API, 2 pages |
| **8** | Tin nhắn nội bộ + Thông báo + Realtime | ~15 SP, 12 API, 3 pages |
| **9** | Lịch (cá nhân, cơ quan, lãnh đạo) + Danh bạ | ~12 SP, 10 API, 4 pages |
| **10** | Dashboard hoàn thiện (real data + widget layout) | ~5 SP, 5 API, 1 page |
| **11** | Kho lưu trữ (archive, borrowing, warehouses) | ~12 SP, 10 API, 3 pages |
| **12** | Tài liệu chung + Hợp đồng | ~10 SP, 8 API, 4 pages |
| **13** | Họp không giấy (rooms, meetings, voting, stats) | ~12 SP, 10 API, 4 pages |
| **14** | Tích hợp — LGSP liên thông | ~5 SP, 4 API, 2 workers |
| **15** | Tích hợp — Ký số (SmartCA, EsignNEAC) | ~3 SP, 3 API, 1 page |
| **16** | Tích hợp — Thông báo (FCM, Zalo, SMS, Email) | ~4 SP, 4 workers |
| **17** | Redirect pages + Dynamic menu + Responsive + Polish | ~2 SP, 2 API, UI fixes |
| **TOTAL** | | **~220 SP, ~180 API, ~55 pages** |
