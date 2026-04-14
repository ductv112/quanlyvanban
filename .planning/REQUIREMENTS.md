# Requirements: e-Office — Quản lý Văn bản điện tử

**Defined:** 2026-04-14
**Core Value:** Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước

## v1 Requirements

### Stabilize (Sprint 0-4 đã build)

- [ ] **STAB-01**: Fix bug visible trên UI — tree mapping, validation, data display
- [ ] **STAB-02**: Refactor shared patterns — tree utility, handleDbError, API response format
- [ ] **STAB-03**: Đảm bảo golden path Sprint 0-4 chạy mượt end-to-end

### Hồ sơ công việc (Sprint 5-6)

- [ ] **HSCV-01**: Người dùng xem danh sách HSCV với filter theo trạng thái (10 loại) và badge count
- [ ] **HSCV-02**: Người dùng tạo/sửa/xóa hồ sơ công việc qua Drawer
- [ ] **HSCV-03**: Người dùng xem chi tiết HSCV với card tabs (thông tin, VB liên kết, cán bộ, ý kiến, đính kèm, HSCV con)
- [ ] **HSCV-04**: Người dùng phân công cán bộ xử lý (phụ trách / phối hợp) qua Transfer panel
- [ ] **HSCV-05**: Người dùng thêm ý kiến xử lý trong HSCV
- [ ] **HSCV-06**: Người dùng liên kết VB đến/đi/dự thảo vào HSCV
- [ ] **HSCV-07**: Người dùng chuyển trạng thái HSCV (trình ký → duyệt → hoàn thành / từ chối / trả về)
- [ ] **HSCV-08**: Admin thiết kế quy trình xử lý (workflow designer) với flowchart kéo thả
- [ ] **HSCV-09**: Người dùng xem KPI dashboard công việc (tổng, hoàn thành, quá hạn)
- [ ] **HSCV-10**: Người dùng xem 3 báo cáo thống kê HSCV (theo đơn vị, cán bộ, người giao) + export Excel

### Văn bản liên thông & Giao việc (Sprint 7)

- [ ] **VBLT-01**: Người dùng xem danh sách + chi tiết văn bản liên thông
- [ ] **VBLT-02**: Người dùng tạo HSCV nhanh từ VB đến (nút "Giao việc")
- [ ] **VBLT-03**: Người dùng thao tác nhận bàn giao / chuyển lại / hủy duyệt trên VB đến

### Tin nhắn & Thông báo (Sprint 8)

- [ ] **MSG-01**: Người dùng gửi/nhận tin nhắn nội bộ (inbox, sent, trash) với giao diện mail-like
- [ ] **MSG-02**: Người dùng trả lời tin nhắn (thread)
- [ ] **MSG-03**: Hệ thống hiển thị thông báo (bell icon, dropdown, trang thông báo)
- [ ] **MSG-04**: Hệ thống push realtime qua Socket.IO (VB mới, tin nhắn, thông báo, trạng thái)

### Lịch & Danh bạ (Sprint 9)

- [ ] **CAL-01**: Người dùng quản lý lịch cá nhân (tạo/sửa/xóa sự kiện, calendar view)
- [ ] **CAL-02**: Admin quản lý lịch cơ quan + view rút gọn
- [ ] **CAL-03**: Lịch lãnh đạo (riêng, cấu hình quyền xem)
- [ ] **CAL-04**: Người dùng tra cứu danh bạ điện thoại (từ bảng staff, filter đơn vị/phòng ban)

### Dashboard (Sprint 10)

- [ ] **DASH-01**: Dashboard hiển thị 4 KPI cards dữ liệu thật (VB đến, VB đi, HSCV, việc sắp hạn)
- [ ] **DASH-02**: Widget "Văn bản mới nhận" + "Việc sắp tới hạn" + "VB đi mới"
- [ ] **DASH-03**: User có thể kéo thả sắp xếp widget (react-grid-layout)

### Kho lưu trữ (Sprint 11)

- [ ] **KHO-01**: Admin quản lý danh mục Kho/Phông (tree + CRUD)
- [ ] **KHO-02**: Người dùng quản lý hồ sơ lưu trữ (CRUD, filter theo kho/phông)
- [ ] **KHO-03**: Người dùng mượn/trả hồ sơ (tạo yêu cầu → duyệt → trả)

### Tài liệu & Hợp đồng (Sprint 12)

- [ ] **DOC-01**: Người dùng quản lý tài liệu chung theo danh mục (Đào tạo, Nội bộ, ISO...) + upload MinIO
- [ ] **DOC-02**: Người dùng quản lý hợp đồng (CRUD, upload scan, DM loại HĐ)

### Họp không giấy (Sprint 13)

- [ ] **HOP-01**: Admin quản lý phòng họp + loại cuộc họp (danh mục)
- [ ] **HOP-02**: Người dùng đăng ký/quản lý cuộc họp (CRUD, duyệt, calendar view)
- [ ] **HOP-03**: Biểu quyết realtime trong cuộc họp (Socket.IO)
- [ ] **HOP-04**: Thống kê cuộc họp (charts theo tháng/phòng/loại)

### Tích hợp — LGSP (Sprint 14)

- [ ] **LGSP-01**: Hệ thống quản lý OAuth2 token với LGSP server (cache Redis)
- [ ] **LGSP-02**: Worker polling nhận VB liên thông từ LGSP (edXML → VB đến)
- [ ] **LGSP-03**: Người dùng gửi VB đi liên thông qua LGSP + tracking trạng thái
- [ ] **LGSP-04**: Đồng bộ danh sách cơ quan liên thông từ LGSP

### Tích hợp — Ký số (Sprint 15)

- [ ] **SIGN-01**: Người dùng ký số VB qua VNPT SmartCA (ký từ xa, OTP)
- [ ] **SIGN-02**: Người dùng ký số qua EsignNEAC (đa CA)
- [ ] **SIGN-03**: UI ký số: chọn phương thức, preview PDF, hiển thị trạng thái đã ký

### Tích hợp — Thông báo đa kênh (Sprint 16)

- [ ] **NOTIF-01**: Worker gửi push notification qua Firebase FCM
- [ ] **NOTIF-02**: Worker gửi thông báo qua Zalo OA API
- [ ] **NOTIF-03**: Worker gửi SMS qua gateway
- [ ] **NOTIF-04**: Worker gửi email notification qua Nodemailer

### Polish & Redirect (Sprint 17)

- [ ] **UI-01**: Menu redirect sang trang đối tác (VNPT/Viettel Invoice, Contract, BHXH, Tax)
- [ ] **UI-02**: Sidebar menu dynamic từ API quyền + badge counts realtime
- [ ] **UI-03**: Responsive toàn bộ + hamburger menu mobile + touch-friendly tables
- [ ] **UI-04**: Polish UX: skeleton loading, empty states, error boundaries, toast, keyboard shortcuts

## v2 Requirements (tuần sau — Deep Stabilize)

- **DEEP-01**: Security audit — JWT secret, RBAC enforcement, XSS prevention, rate limiting
- **DEEP-02**: Test coverage cơ bản — API tests, frontend state tests
- **DEEP-03**: Performance tuning — DB pool, query optimization, caching strategy
- **DEEP-04**: Error handling chuẩn hóa — Zod validation, centralized error middleware
- **DEEP-05**: Audit logging system
- **DEEP-06**: Refactor monolithic route files (admin-catalog.ts 1492 lines)

## Out of Scope

| Feature | Reason |
|---------|--------|
| Mobile app native (iOS/Android) | Chỉ responsive web, không build native |
| Thay đổi nghiệp vụ so với hệ thống cũ | Giữ nguyên logic cũ, chỉ cải tiến tech/UI |
| Multilingual (i18n) | Chỉ tiếng Việt, khách hàng là CQNN Việt Nam |
| AI/ML features | Không trong scope hiện tại |
| Offline mode / PWA full | Chỉ cần online |

## Traceability

Updated during roadmap creation (2026-04-14).

| Requirement | Phase | Status |
|-------------|-------|--------|
| STAB-01 | Phase 1 | Pending |
| STAB-02 | Phase 1 | Pending |
| STAB-03 | Phase 1 | Pending |
| HSCV-01 | Phase 2 | Pending |
| HSCV-02 | Phase 2 | Pending |
| HSCV-03 | Phase 2 | Pending |
| HSCV-04 | Phase 2 | Pending |
| HSCV-05 | Phase 2 | Pending |
| HSCV-06 | Phase 2 | Pending |
| HSCV-07 | Phase 2 | Pending |
| HSCV-08 | Phase 2 | Pending |
| HSCV-09 | Phase 2 | Pending |
| HSCV-10 | Phase 2 | Pending |
| VBLT-01 | Phase 3 | Pending |
| VBLT-02 | Phase 3 | Pending |
| VBLT-03 | Phase 3 | Pending |
| MSG-01 | Phase 3 | Pending |
| MSG-02 | Phase 3 | Pending |
| MSG-03 | Phase 3 | Pending |
| MSG-04 | Phase 3 | Pending |
| CAL-01 | Phase 4 | Pending |
| CAL-02 | Phase 4 | Pending |
| CAL-03 | Phase 4 | Pending |
| CAL-04 | Phase 4 | Pending |
| DASH-01 | Phase 4 | Pending |
| DASH-02 | Phase 4 | Pending |
| DASH-03 | Phase 4 | Pending |
| KHO-01 | Phase 5 | Pending |
| KHO-02 | Phase 5 | Pending |
| KHO-03 | Phase 5 | Pending |
| DOC-01 | Phase 5 | Pending |
| DOC-02 | Phase 5 | Pending |
| HOP-01 | Phase 5 | Pending |
| HOP-02 | Phase 5 | Pending |
| HOP-03 | Phase 5 | Pending |
| HOP-04 | Phase 5 | Pending |
| LGSP-01 | Phase 6 | Pending |
| LGSP-02 | Phase 6 | Pending |
| LGSP-03 | Phase 6 | Pending |
| LGSP-04 | Phase 6 | Pending |
| SIGN-01 | Phase 6 | Pending |
| SIGN-02 | Phase 6 | Pending |
| SIGN-03 | Phase 6 | Pending |
| NOTIF-01 | Phase 6 | Pending |
| NOTIF-02 | Phase 6 | Pending |
| NOTIF-03 | Phase 6 | Pending |
| NOTIF-04 | Phase 6 | Pending |
| UI-01 | Phase 7 | Pending |
| UI-02 | Phase 7 | Pending |
| UI-03 | Phase 7 | Pending |
| UI-04 | Phase 7 | Pending |

**Coverage:**
- v1 requirements: 51 total (note: header said 47, actual count by ID is 51)
- Mapped to phases: 51
- Unmapped: 0

---
*Requirements defined: 2026-04-14*
*Last updated: 2026-04-14 after roadmap creation — traceability populated*
