# QUY ƯỚC CHUNG — Dự án Quản lý Văn bản

> File này là quy ước binding cho toàn bộ dự án.
> Mọi code mới PHẢI tuân theo. Cập nhật khi có thay đổi.

---

## 1. DATABASE — Giới hạn độ dài cột (maxLength)

| Loại trường | PostgreSQL type | maxLength | Áp dụng cho |
|---|---|---|---|
| Mã (code) | VARCHAR(20) | 20 | department.code, position.code, doc_field.code... |
| Tên ngắn | VARCHAR(50) | 50 | short_name, abb_name, first_name, last_name |
| Tên thường | VARCHAR(100) | 100 | position.name, role.name |
| Tên dài | VARCHAR(200) | 200 | department.name, right.name, name_of_menu, id_card_place |
| Username | VARCHAR(50) | 50 | staff.username |
| Password | VARCHAR(200) | 50 (input) | Giới hạn ở UI, hash lưu DB dài hơn |
| Email | VARCHAR(100) | 100 | staff.email, department.email |
| SĐT | VARCHAR(20) | 20 | phone, mobile, fax |
| Địa chỉ | TEXT | 500 (UI) | address |
| Mô tả | TEXT | 500 (UI) | description |
| URL / Link | VARCHAR(500) | 500 | action_link |
| Icon class | VARCHAR(100) | 100 | icon |
| File path | VARCHAR(500) | 500 | image, sign_image |
| CMND/CCCD | VARCHAR(20) | 20 | id_card |

**Quy tắc:** Frontend `<Input maxLength={N}>` PHẢI khớp với DB column size.

---

## 2. VALIDATION RULES

### 2.1 Password Policy
- Tối thiểu **6 ký tự**
- Phải chứa ít nhất: **1 chữ hoa**, **1 chữ thường**, **1 chữ số**
- Regex: `/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{6,}$/`
- Mật khẩu mặc định khi reset: `Admin@123`

### 2.2 Username
- Tối thiểu **3 ký tự**
- Chỉ chứa: chữ cái, số, dấu chấm, gạch ngang, gạch dưới
- Regex: `/^[a-zA-Z0-9._-]{3,50}$/`
- Lưu DB: **lowercase, trim**

### 2.3 Email
- Regex: `/^[^\s@]+@[^\s@]+\.[^\s@]+$/`
- Lưu DB: **lowercase, trim**
- Unique per staff (case-insensitive)

### 2.4 Số điện thoại
- Regex: `/^[0-9+\-\s()]{8,15}$/`
- Cho phép: số, dấu +, dấu -, khoảng trắng, ngoặc
- Lưu DB: **trim**

### 2.5 Mã (code)
- Unique per entity (case-insensitive)
- Chỉ chữ cái, số, gạch ngang, gạch dưới
- Regex khuyến nghị: `/^[a-zA-Z0-9_-]+$/`

### 2.6 Required fields theo entity

| Entity | Required fields |
|---|---|
| Department | name, code |
| Position | name |
| Staff | username, last_name, first_name, department_id, unit_id |
| Role | name |
| Right | name |

---

## 3. ERROR MESSAGES — Quy ước thông báo

### 3.1 Thông báo thành công (message.success)
| Action | Message |
|---|---|
| Tạo mới | `Thêm thành công` |
| Cập nhật | `Cập nhật thành công` |
| Xóa | `Xóa thành công` |
| Khóa | `Đã khóa` |
| Mở khóa | `Đã mở khóa` |
| Reset password | `Đã reset mật khẩu về mặc định (Admin@123)` |
| Đổi password | `Đổi mật khẩu thành công` |
| Phân quyền | `Lưu phân quyền thành công` |
| Đăng nhập | `Đăng nhập thành công` |
| Đăng xuất | `Đăng xuất thành công` |

### 3.2 Thông báo lỗi validation (400)
| Lỗi | Message |
|---|---|
| Thiếu field bắt buộc | `{Tên trường} là bắt buộc` |
| Trùng mã | `Mã {entity} đã tồn tại` |
| Trùng tên | `Tên {entity} đã tồn tại` |
| Trùng username | `Tên đăng nhập đã tồn tại` |
| Trùng email | `Email đã được sử dụng` |
| Password yếu | `Mật khẩu phải có ít nhất 6 ký tự, chứa chữ hoa, chữ thường và số` |
| Password trùng cũ | `Mật khẩu mới không được trùng với mật khẩu hiện tại` |
| Password cũ sai | `Mật khẩu hiện tại không đúng` |
| Email sai format | `Email không đúng định dạng` |
| SĐT sai format | `Số điện thoại không đúng định dạng` |
| Username sai format | `Tên đăng nhập chỉ chứa chữ cái, số, dấu chấm, gạch ngang` |
| Username quá ngắn | `Tên đăng nhập phải có ít nhất 3 ký tự` |
| ID không hợp lệ | `ID không hợp lệ` |

### 3.3 Thông báo lỗi nghiệp vụ (400/409)
| Lỗi | Message |
|---|---|
| Xóa đơn vị có con | `Không thể xóa: còn {N} phòng ban con` |
| Xóa đơn vị có NV | `Không thể xóa: còn {N} nhân viên thuộc phòng ban này` |
| Xóa chức vụ đang dùng | `Không thể xóa: còn {N} nhân viên đang sử dụng chức vụ này` |
| Xóa role đang dùng | `Không thể xóa: còn {N} nhân viên trong nhóm quyền này` |
| Xóa right có con | `Không thể xóa: còn {N} chức năng con` |
| Tài khoản bị khóa | `Tài khoản đã bị khóa` |
| Tài khoản bị xóa | `Tài khoản đã bị xóa` |
| Sai đăng nhập | `Tên đăng nhập hoặc mật khẩu không đúng` |
| FK tham chiếu | `Không thể thực hiện: dữ liệu đang được tham chiếu` |

### 3.4 Thông báo lỗi hệ thống (500)
| Môi trường | Message |
|---|---|
| Development | Show raw error message (debug) |
| Production | `Có lỗi xảy ra, vui lòng thử lại sau` |

### 3.5 HTTP Status Code
| Code | Ý nghĩa | Khi nào dùng |
|---|---|---|
| 200 | OK | GET, PUT, PATCH, DELETE thành công |
| 201 | Created | POST tạo mới thành công |
| 400 | Bad Request | Validation fail, format sai |
| 401 | Unauthorized | Chưa đăng nhập, token hết hạn |
| 403 | Forbidden | Không có quyền |
| 404 | Not Found | Không tìm thấy record |
| 409 | Conflict | Trùng dữ liệu (unique violation) |
| 500 | Server Error | Lỗi hệ thống |

---

## 4. API RESPONSE FORMAT

### 4.1 Success response (không phân trang)
```json
{
  "success": true,
  "data": { ... },
  "message": "Thêm thành công"
}
```

### 4.2 Success response (có phân trang)
```json
{
  "success": true,
  "data": [ ... ],
  "total": 150,
  "page": 1,
  "pageSize": 20,
  "totalPages": 8
}
```

### 4.3 Error response
```json
{
  "success": false,
  "message": "Mã đơn vị đã tồn tại"
}
```

---

## 5. NAMING CONVENTION

### 5.1 Database
- Table: **snake_case**, số nhiều (`departments`, `incoming_docs`)
- Column: **snake_case** (`first_name`, `created_at`, `is_locked`)
- SP: `{schema}.fn_{module}_{action}` (`public.fn_staff_get_list`, `edoc.fn_incoming_doc_create`)
- Index: `idx_{table}_{column}`
- Constraint: `uq_{table}_{column}` (unique), `fk_{table}_{ref}` (foreign key)

### 5.2 Backend (TypeScript)
- File: **kebab-case** (`department.repository.ts`, `auth.service.ts`)
- Interface: **PascalCase** (`DepartmentTreeRow`, `StaffDetailRow`)
- Variable/function: **camelCase** (`getTree`, `staffId`)
- Route params từ frontend: **snake_case** (khớp DB column name)

### 5.3 Frontend
- Component: **PascalCase** (`MainLayout`, `AntdProvider`)
- Page file: `page.tsx` (Next.js convention)
- Hook: `use-{name}.ts`
- Store: `{name}.store.ts`
- Form field `name=`: **snake_case** (khớp DB column name)

### 5.4 API URL
- Prefix: `/api/`
- Resource: **kebab-case** tiếng Việt (`/van-ban/den`, `/ho-so-cong-viec`, `/quan-tri/nguoi-dung`)
- CRUD: `GET /resource`, `POST /resource`, `PUT /resource/:id`, `DELETE /resource/:id`
- Action: `PATCH /resource/:id/lock`, `PATCH /resource/:id/reset-password`

---

## 6. UI/UX CONVENTION

### 6.1 Form patterns
- **Thêm/Sửa**: Drawer (width 720px), header gradient (#1B3A5C → #0891B2)
- **Xóa**: Modal.confirm (từ dropdown menu)
- **Phân quyền**: Drawer riêng
- **Chi tiết**: Page riêng (cho entities phức tạp: VB, HSCV)

### 6.2 Table actions
- Dùng **Dropdown menu** (icon ⋮ MoreOutlined), KHÔNG dùng nhiều icon buttons
- Divider trước action nguy hiểm (xóa)
- Action nguy hiểm: `danger: true`

### 6.3 Form hints & helper text
- Gợi ý cho field: dùng **`placeholder`** trong Input, KHÔNG dùng div/text bên ngoài
- Giải thích thêm cho label: dùng **`tooltip`** prop của Form.Item (icon ? bên cạnh)
- KHÔNG BAO GIỜ dùng `<div>` hoặc `<p>` bên ngoài Form.Item để hiển thị gợi ý → gây lệch layout 2 cột

### 6.4 Error display (validation)
- Lỗi validation (required, format): **text đỏ dưới field** — tự động bởi Ant Design Form rules
- Lỗi backend (trùng dữ liệu, nghiệp vụ): **text đỏ dưới field tương ứng** — dùng `form.setFields([{name, errors}])`
- Lỗi hệ thống (500, network): **toast message** fallback — `message.error('...')`
- PHẢI đồng nhất: mọi lỗi liên quan đến 1 field → hiện dưới field đó, KHÔNG dùng toast
- Form 2 cột: dùng `validateTrigger="onSubmit"` để tránh vỡ layout khi validate realtime

### 6.5 Notifications
- Thành công: `message.success('...')`
- Lỗi hệ thống: `message.error('...')` (chỉ khi không map được vào field cụ thể)
- KHÔNG dùng alert, KHÔNG dùng notification popup

### 6.6 Loading
- Table/List: `loading` prop
- Page: `<Skeleton />`
- KHÔNG dùng `<Spin />` toàn trang

### 6.7 Ngôn ngữ
- **LUÔN** viết tiếng Việt **CÓ DẤU** đầy đủ
- Labels, messages, placeholders, tooltips, tags — tất cả phải có dấu

---

## 7. CSS-FIRST LAYOUT — CHỐNG FOUC (Flash of Unstyled Content)

> **Bắt buộc áp dụng cho toàn bộ dự án.**

### 7.1 Nguyên tắc

Inline styles (`style={{ ... }}`) trên React components chỉ render **SAU** khi JavaScript hydrate xong → gây flash trắng 1-2 giây khi navigate lần đầu. CSS classes render ngay khi browser nhận HTML.

**QUY TẮC:**
- Layout/structural styles (position, display, flex, grid, width, height, padding, margin, background, border-radius, box-shadow) → **PHẢI dùng CSS class** trong `globals.css`
- Dynamic/data-driven styles (color thay đổi theo data, conditional visibility) → **ĐƯỢC dùng inline `style={{}}`**

### 7.2 Shared CSS Classes có sẵn trong `globals.css`

| CSS Class | Dùng cho | Thay thế inline |
|---|---|---|
| `.main-layout`, `.main-sider`, `.main-header`, `.main-content` | Layout shell (sidebar, header, content) | `style={styles.sider}`, `style={styles.header}` |
| `.page-header`, `.page-title`, `.page-description` | Tiêu đề + mô tả mỗi trang | `style={{ fontSize: 22, fontWeight: 700 }}` |
| `.page-card` | Card wrapper (borderRadius 12, shadow) | `style={{ borderRadius: 12, boxShadow: '...' }}` |
| `.drawer-gradient` | Drawer có header gradient | `styles={{ header: { background: gradient } }}` |
| `.section-title` | Tiêu đề section trong detail page | `style={sectionTitle}` |
| `.info-grid`, `.info-grid-full` | Grid 2 cột thông tin | `style={infoRow}` |
| `.info-label`, `.info-value` | Label + value trong info grid | `style={fieldLabel}`, `style={fieldValue}` |
| `.doc-abstract-box` | Box highlight trích yếu | `style={{ borderLeft: '4px solid #0891B2', ... }}` |
| `.stat-card`, `.stat-card-body`, `.stat-card-icon` | Dashboard KPI cards | `style={{ display: 'flex', ... }}` |
| `.section-card-header`, `.section-card-icon` | Card header có icon | `style={{ display: 'flex', gap: 10 }}` |
| `.profile-header` | Header gradient trang profile | `style={{ background: gradient, display: 'flex' }}` |
| `.detail-header`, `.detail-header-left`, `.detail-header-right` | Header bar trang chi tiết | `style={{ display: 'flex', ... }}` |
| `.filter-row` | Row filter/search | `style={{ marginBottom: 16 }}` |
| `.empty-center` | Empty state | `style={{ textAlign: 'center', ... }}` |

### 7.3 Cách áp dụng khi tạo trang mới

```tsx
// ❌ SAI — inline layout styles → FOUC
<div style={{ display: 'flex', gap: 12, padding: 16, background: '#fff', borderRadius: 12 }}>

// ✅ ĐÚNG — CSS class cho layout, inline chỉ cho dynamic
<div className="page-card" style={{ borderColor: isActive ? '#52c41a' : undefined }}>
```

**Drawer:**
```tsx
// ❌ SAI
<Drawer styles={{ header: { background: 'linear-gradient(...)' }, body: { padding: 24 } }}>

// ✅ ĐÚNG — dùng rootClassName
<Drawer rootClassName="drawer-gradient" width={720}>
```

### 7.4 Khi nào thêm CSS class mới

Nếu một pattern layout xuất hiện ở **2+ trang trở lên** → tạo CSS class trong `globals.css`.
Pattern chỉ dùng 1 lần → inline OK (nhưng ưu tiên CSS nếu là structural).

---

## 8. SECURITY

### 7.1 Authentication
- JWT access token: 15 phút, Bearer header
- Refresh token: 7 ngày, httpOnly cookie, SameSite=Lax
- Token rotation khi refresh

### 7.2 Password
- Hash: bcryptjs, cost factor 12
- KHÔNG BAO GIỜ lưu plain text
- KHÔNG BAO GIỜ trả password_hash về frontend

### 7.3 SQL Injection
- LUÔN dùng parameterized queries (`$1, $2`)
- KHÔNG BAO GIỜ string concatenation cho SQL

### 7.4 Error exposure
- Development: show raw error (debug)
- Production: generic message, log chi tiết server-side
- KHÔNG BAO GIỜ show stack trace, DB schema, constraint names cho user

---

## 9. GIT CONVENTION

### 8.1 Commit message
```
{type}: {description}

{body — chi tiết}

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
```

### 8.2 Types
- `feat:` — tính năng mới
- `fix:` — sửa lỗi
- `refactor:` — refactor không thay đổi tính năng
- `docs:` — tài liệu
- `style:` — format, không thay đổi logic
