# TEST TỔNG THỂ — e-Office Quản lý Văn bản

> **Ngày tạo:** 2026-04-17
> **Mục tiêu:** Test toàn diện trước demo ngày 18-19/04/2026
> **Phương pháp:** Manual test trên browser (Chrome) + kiểm tra API + kiểm tra DB
> **Base URL:** Frontend http://localhost:3000 | Backend http://localhost:4000/api

---

## Quy ước ký hiệu

| Ký hiệu | Ý nghĩa |
|----------|----------|
| ⬜ | Chưa test |
| ✅ | PASS |
| ❌ | FAIL — ghi rõ lỗi |
| ⚠️ | Có vấn đề nhỏ, chấp nhận được |

---

## PHẦN 0: HẠ TẦNG & KHỞI ĐỘNG

### 0.1 Docker Services
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 0.1.1 | `docker ps` — 4 containers running (postgres, mongodb, redis, minio) | ⬜ | |
| 0.1.2 | PostgreSQL: `docker exec qlvb_postgres pg_isready -U qlvb_admin` → accepting | ⬜ | |
| 0.1.3 | Redis: `docker exec qlvb_redis redis-cli -a QlvbRedis@2026 ping` → PONG | ⬜ | |
| 0.1.4 | MinIO Console: http://localhost:9001 accessible | ⬜ | |
| 0.1.5 | MongoDB: `docker exec qlvb_mongodb mongosh --eval "db.stats()"` → OK | ⬜ | |

### 0.2 Backend
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 0.2.1 | `npm run dev` khởi động không lỗi | ⬜ | |
| 0.2.2 | GET http://localhost:4000/api/health → 200 OK | ⬜ | |
| 0.2.3 | Console không có lỗi kết nối DB/Redis/Mongo | ⬜ | |

### 0.3 Frontend
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 0.3.1 | `npm run dev` khởi động không lỗi | ⬜ | |
| 0.3.2 | http://localhost:3000 → redirect đến /login | ⬜ | |
| 0.3.3 | Trang login render đúng, không FOUC | ⬜ | |

---

## PHẦN 1: ĐĂNG NHẬP & PHÂN QUYỀN

### 1.1 Đăng nhập
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 1.1.1 | Login `admin` / `Admin@123` → thành công, redirect /dashboard | ⬜ | |
| 1.1.2 | Login `nguyenvana` / `Admin@123` → thành công | ⬜ | |
| 1.1.3 | Login `phamvane` / `Admin@123` → thành công | ⬜ | |
| 1.1.4 | Login `hoangthif` / `Admin@123` → thành công | ⬜ | |
| 1.1.5 | Login sai password → hiện thông báo lỗi tiếng Việt | ⬜ | |
| 1.1.6 | Login username không tồn tại → thông báo lỗi | ⬜ | |
| 1.1.7 | Bỏ trống username/password → validation required | ⬜ | |
| 1.1.8 | Sau login, F5 refresh → vẫn giữ session (token) | ⬜ | |

### 1.2 Phân quyền menu theo vai trò
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 1.2.1 | `admin`: thấy TẤT CẢ menu (Nghiệp vụ + Quản lý + Tích hợp + Hệ thống) | ⬜ | |
| 1.2.2 | `nguyenvana` (Lãnh đạo): thấy Nghiệp vụ + Quản lý, KHÔNG thấy Hệ thống | ⬜ | |
| 1.2.3 | `phamvane` (TP + Văn thư): thấy Nghiệp vụ + Quản lý, KHÔNG thấy Hệ thống | ⬜ | |
| 1.2.4 | `hoangthif` (Cán bộ): chỉ thấy Nghiệp vụ + Đối tác, KHÔNG thấy Quản lý | ⬜ | |
| 1.2.5 | Truy cập URL `/quan-tri/...` khi không có quyền → redirect hoặc 403 | ⬜ | |

### 1.3 Đăng xuất
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 1.3.1 | Click Đăng xuất → redirect /login, token bị xóa | ⬜ | |
| 1.3.2 | Sau đăng xuất, truy cập /dashboard → redirect /login | ⬜ | |

---

## PHẦN 2: DASHBOARD (Tổng quan)

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 2.1 | Trang load không lỗi, hiện stat cards | ⬜ | |
| 2.2 | Stat cards hiện đúng số liệu (VB đến, VB đi, HSCV...) | ⬜ | |
| 2.3 | Danh sách VB đến gần đây hiện data | ⬜ | |
| 2.4 | Danh sách VB đi gần đây hiện data | ⬜ | |
| 2.5 | Responsive: thu nhỏ sidebar → content co lại đúng | ⬜ | |

---

## PHẦN 3: QUẢN TRỊ HỆ THỐNG (Admin only)

### 3.1 Đơn vị (Phòng ban) — `/quan-tri/don-vi`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 3.1.1 | Hiện tree phòng ban (seed: 10 phòng ban) | ⬜ | |
| 3.1.2 | Click node → hiện detail bên phải | ⬜ | |
| 3.1.3 | Thêm phòng ban con: Drawer mở, nhập đủ thông tin → Lưu thành công | ⬜ | |
| 3.1.4 | Sửa phòng ban: pre-fill đúng data → Lưu thành công | ⬜ | |
| 3.1.5 | Xóa phòng ban không có con/nhân viên → thành công | ⬜ | |
| 3.1.6 | Xóa phòng ban có con → báo lỗi (FK constraint) | ⬜ | |
| 3.1.7 | Khóa/Mở khóa phòng ban | ⬜ | |
| 3.1.8 | Trùng mã phòng ban → hiện lỗi inline trên field code | ⬜ | |

### 3.2 Chức vụ — `/quan-tri/chuc-vu`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 3.2.1 | Hiện danh sách chức vụ (seed: 6 chức vụ) | ⬜ | |
| 3.2.2 | Thêm mới: Drawer → nhập tên + mã + thứ tự → Lưu OK | ⬜ | |
| 3.2.3 | Sửa: pre-fill đúng → Lưu OK | ⬜ | |
| 3.2.4 | Xóa chức vụ không ai dùng → OK | ⬜ | |
| 3.2.5 | Xóa chức vụ đang gán nhân viên → báo lỗi | ⬜ | |
| 3.2.6 | Trùng mã → lỗi inline | ⬜ | |

### 3.3 Người dùng — `/quan-tri/nguoi-dung`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 3.3.1 | Hiện danh sách nhân viên (seed: 10 người) | ⬜ | |
| 3.3.2 | Tìm kiếm theo tên/username → filter đúng | ⬜ | |
| 3.3.3 | Lọc theo phòng ban → đúng | ⬜ | |
| 3.3.4 | Thêm mới: Drawer → nhập đủ thông tin bắt buộc → Lưu OK | ⬜ | |
| 3.3.5 | Sửa nhân viên: pre-fill đúng → Lưu OK | ⬜ | |
| 3.3.6 | Khóa/Mở khóa tài khoản | ⬜ | |
| 3.3.7 | Reset mật khẩu → OK, đăng nhập lại bằng mật khẩu mới | ⬜ | |
| 3.3.8 | Đổi mật khẩu: yêu cầu mật khẩu cũ + mới (min 6 ký tự, chữ hoa + số) | ⬜ | |
| 3.3.9 | Gán nhóm quyền cho nhân viên | ⬜ | |
| 3.3.10 | Trùng username → lỗi inline | ⬜ | |
| 3.3.11 | Xóa nhân viên không liên quan dữ liệu → OK | ⬜ | |
| 3.3.12 | Pagination: chuyển trang đúng | ⬜ | |

### 3.4 Nhóm quyền — `/quan-tri/nhom-quyen`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 3.4.1 | Hiện danh sách nhóm quyền (seed: 6 nhóm) | ⬜ | |
| 3.4.2 | Thêm nhóm quyền mới | ⬜ | |
| 3.4.3 | Gán quyền (checkbox tree) cho nhóm | ⬜ | |
| 3.4.4 | Sửa/Xóa nhóm quyền | ⬜ | |
| 3.4.5 | Xóa nhóm đang gán nhân viên → báo lỗi | ⬜ | |

### 3.5 Chức năng (Menu) — `/quan-tri/chuc-nang`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 3.5.1 | Hiện tree chức năng/menu | ⬜ | |
| 3.5.2 | Thêm/Sửa/Xóa chức năng | ⬜ | |

---

## PHẦN 4: DANH MỤC (Admin only)

### 4.1 Sổ văn bản — `/quan-tri/so-van-ban`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.1.1 | Hiện danh sách sổ (seed: 5 sổ) | ⬜ | |
| 4.1.2 | Thêm sổ mới: tên + mã + năm → Lưu OK | ⬜ | |
| 4.1.3 | Sửa sổ → OK | ⬜ | |
| 4.1.4 | Xóa sổ không dùng → OK | ⬜ | |
| 4.1.5 | Đặt sổ mặc định | ⬜ | |

### 4.2 Loại văn bản — `/quan-tri/loai-van-ban`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.2.1 | Hiện tree loại VB (seed: 8 loại) | ⬜ | |
| 4.2.2 | Thêm loại VB (parent/child) → OK | ⬜ | |
| 4.2.3 | Sửa/Xóa → OK | ⬜ | |

### 4.3 Lĩnh vực — `/quan-tri/linh-vuc`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.3.1 | Hiện danh sách lĩnh vực (seed: 5) | ⬜ | |
| 4.3.2 | CRUD → OK | ⬜ | |

### 4.4 Cấu hình trường (S5 Dynamic) — `/quan-tri/cau-hinh-truong`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.4.1 | Hiện danh sách trường bổ sung (seed: ~5 trường) | ⬜ | |
| 4.4.2 | Thêm trường mới: chọn loại (text/number/date/select) + tên | ⬜ | |
| 4.4.3 | Toggle ẩn/hiện trường | ⬜ | |
| 4.4.4 | Sửa/Xóa trường | ⬜ | |

### 4.5 Cơ quan — `/quan-tri/co-quan`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.5.1 | Hiện thông tin cơ quan hiện tại | ⬜ | |
| 4.5.2 | Cập nhật thông tin → Lưu OK | ⬜ | |

### 4.6 Người ký — `/quan-tri/nguoi-ky`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.6.1 | Hiện danh sách người ký | ⬜ | |
| 4.6.2 | Thêm/Xóa người ký | ⬜ | |

### 4.7 Nhóm làm việc — `/quan-tri/nhom-lam-viec`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.7.1 | Hiện danh sách nhóm | ⬜ | |
| 4.7.2 | Thêm nhóm mới → OK | ⬜ | |
| 4.7.3 | Thêm/Xóa thành viên nhóm | ⬜ | |
| 4.7.4 | Sửa/Xóa nhóm | ⬜ | |

### 4.8 Ủy quyền — `/quan-tri/uy-quyen`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.8.1 | Hiện danh sách ủy quyền | ⬜ | |
| 4.8.2 | Tạo ủy quyền mới: người ủy quyền + người nhận + thời hạn | ⬜ | |
| 4.8.3 | Sửa/Xóa/Chấp nhận/Từ chối ủy quyền | ⬜ | |

### 4.9 Địa bàn — `/quan-tri/dia-ban`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.9.1 | Hiện danh sách địa bàn | ⬜ | |
| 4.9.2 | CRUD → OK | ⬜ | |

### 4.10 Lịch làm việc — `/quan-tri/lich-lam-viec`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.10.1 | Hiện lịch năm hiện tại | ⬜ | |
| 4.10.2 | Đánh dấu ngày nghỉ / bỏ đánh dấu | ⬜ | |

### 4.11 Mẫu thông báo — `/quan-tri/mau-thong-bao`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.11.1 | Hiện danh sách mẫu | ⬜ | |
| 4.11.2 | CRUD mẫu thông báo | ⬜ | |

### 4.12 Cấu hình hệ thống — `/quan-tri/cau-hinh`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 4.12.1 | Hiện các tham số cấu hình | ⬜ | |
| 4.12.2 | Sửa → Lưu OK | ⬜ | |

---

## PHẦN 5: VĂN BẢN ĐẾN (Core flow) — `/van-ban-den`

### 5.1 Danh sách
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 5.1.1 | Hiện danh sách VB đến (seed: 7 VB) | ⬜ | |
| 5.1.2 | Tìm kiếm theo trích yếu | ⬜ | |
| 5.1.3 | Lọc theo trạng thái (Mới tiếp nhận / Đang xử lý / Đã xử lý...) | ⬜ | |
| 5.1.4 | Lọc theo sổ văn bản | ⬜ | |
| 5.1.5 | Lọc theo loại văn bản | ⬜ | |
| 5.1.6 | Lọc theo khoảng thời gian | ⬜ | |
| 5.1.7 | Lọc theo độ khẩn (Thường / Khẩn / Hỏa tốc) | ⬜ | |
| 5.1.8 | Lọc theo độ mật | ⬜ | |
| 5.1.9 | Pagination hoạt động đúng | ⬜ | |
| 5.1.10 | Badge đếm VB chưa đọc trên sidebar | ⬜ | |
| 5.1.11 | Đánh dấu đã đọc (bulk) | ⬜ | |
| 5.1.12 | Xuất Excel danh sách | ⬜ | |

### 5.2 Tạo mới VB đến
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 5.2.1 | Mở Drawer thêm mới → form hiện đúng, số đến tự tăng | ⬜ | |
| 5.2.2 | Nhập đủ thông tin bắt buộc → Lưu thành công | ⬜ | |
| 5.2.3 | Bỏ trống field bắt buộc → validation hiện lỗi | ⬜ | |
| 5.2.4 | maxLength validation trên các field text | ⬜ | |
| 5.2.5 | Upload file đính kèm → OK | ⬜ | |
| 5.2.6 | Trường bổ sung (dynamic S5) hiện nếu được cấu hình | ⬜ | |

### 5.3 Chi tiết VB đến — `/van-ban-den/[id]`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 5.3.1 | Click VB từ danh sách → mở trang detail đúng | ⬜ | |
| 5.3.2 | Hiện đầy đủ thông tin: trích yếu, số ký hiệu, ngày đến, nơi gửi... | ⬜ | |
| 5.3.3 | Tab Đính kèm: hiện danh sách file, download được | ⬜ | |
| 5.3.4 | Tab Ý kiến lãnh đạo (Bút phê): xem/thêm/xóa ý kiến | ⬜ | |
| 5.3.5 | Tab Người nhận: hiện danh sách người đã gửi | ⬜ | |
| 5.3.6 | Tab Lịch sử: hiện log thao tác | ⬜ | |

### 5.4 Thao tác nghiệp vụ VB đến
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 5.4.1 | **Gửi VB**: chọn người nhận → Gửi → trạng thái chuyển | ⬜ | |
| 5.4.2 | **Duyệt VB**: click Duyệt → status chuyển "Đã duyệt" | ⬜ | |
| 5.4.3 | **Hủy duyệt**: Hủy duyệt → quay về trạng thái trước | ⬜ | |
| 5.4.4 | **Thu hồi**: Thu hồi VB đã gửi → người nhận không thấy nữa | ⬜ | |
| 5.4.5 | **Giao việc**: Tạo HSCV từ VB đến → mở form giao việc | ⬜ | |
| 5.4.6 | **Thêm vào HSCV**: Chọn HSCV có sẵn → link VB vào | ⬜ | |
| 5.4.7 | **Nhận bản giấy**: Đánh dấu đã nhận bản giấy | ⬜ | |
| 5.4.8 | **Đánh dấu cá nhân**: Toggle bookmark → hiện trong tab "Đánh dấu" | ⬜ | |
| 5.4.9 | **Chuyển lại**: Forward VB cho người khác | ⬜ | |
| 5.4.10 | **Sửa VB**: Chỉ người tạo hoặc admin mới sửa được | ⬜ | |
| 5.4.11 | **Xóa VB**: Chỉ VB chưa gửi mới xóa được | ⬜ | |

### 5.5 Bút phê kết hợp phân công (S2)
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 5.5.1 | Lãnh đạo ghi ý kiến + chọn người phân công → Lưu cùng lúc | ⬜ | |
| 5.5.2 | Người được phân công nhận VB + thấy ý kiến lãnh đạo | ⬜ | |

### 5.6 Gửi liên thông (LGSP - S6)
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 5.6.1 | Chọn "Gửi liên thông" → hiện danh sách đơn vị LGSP | ⬜ | |
| 5.6.2 | Gửi → tạo tracking record | ⬜ | |

### 5.7 Chuyển lưu trữ (S3)
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 5.7.1 | Chọn "Chuyển lưu trữ" → chọn kho + phông → OK | ⬜ | |

---

## PHẦN 6: VĂN BẢN ĐI — `/van-ban-di`

### 6.1 Danh sách
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 6.1.1 | Hiện danh sách VB đi (seed: 4 VB) | ⬜ | |
| 6.1.2 | Tìm kiếm / lọc theo trạng thái / sổ / loại / khoảng thời gian | ⬜ | |
| 6.1.3 | Pagination | ⬜ | |
| 6.1.4 | Badge chưa đọc | ⬜ | |
| 6.1.5 | Xuất Excel | ⬜ | |

### 6.2 Tạo mới VB đi
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 6.2.1 | Mở form → số đi tự tăng | ⬜ | |
| 6.2.2 | Nhập đủ thông tin → Lưu OK | ⬜ | |
| 6.2.3 | Validation required + maxLength | ⬜ | |
| 6.2.4 | Upload đính kèm | ⬜ | |
| 6.2.5 | Trường bổ sung (dynamic S5) | ⬜ | |

### 6.3 Chi tiết VB đi — `/van-ban-di/[id]`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 6.3.1 | Hiện đúng thông tin chi tiết | ⬜ | |
| 6.3.2 | Tab Đính kèm / Ý kiến / Người nhận / Lịch sử | ⬜ | |

### 6.4 Thao tác nghiệp vụ VB đi
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 6.4.1 | **Gửi VB đi**: chọn người nhận → Gửi | ⬜ | |
| 6.4.2 | **Duyệt / Hủy duyệt** | ⬜ | |
| 6.4.3 | **Từ chối** VB đi | ⬜ | |
| 6.4.4 | **Thu hồi** VB đi (per-person hoặc all) | ⬜ | |
| 6.4.5 | **Đánh dấu cá nhân** | ⬜ | |
| 6.4.6 | **Giao việc** / Thêm vào HSCV | ⬜ | |
| 6.4.7 | **Kiểm tra số**: kiểm tra số đi trùng | ⬜ | |
| 6.4.8 | **Số chưa phát hành**: hiện danh sách gap | ⬜ | |
| 6.4.9 | **Gửi liên thông** | ⬜ | |
| 6.4.10 | **Chuyển lưu trữ** | ⬜ | |
| 6.4.11 | Sửa / Xóa VB đi | ⬜ | |

---

## PHẦN 7: VĂN BẢN DỰ THẢO — `/van-ban-du-thao`

### 7.1 Danh sách
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 7.1.1 | Hiện danh sách (seed: 4 VB) | ⬜ | |
| 7.1.2 | Tìm kiếm / Lọc | ⬜ | |
| 7.1.3 | Pagination + badge chưa đọc | ⬜ | |
| 7.1.4 | Xuất Excel | ⬜ | |

### 7.2 CRUD dự thảo
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 7.2.1 | Tạo dự thảo mới → OK | ⬜ | |
| 7.2.2 | Sửa dự thảo → OK | ⬜ | |
| 7.2.3 | Xóa dự thảo chưa gửi → OK | ⬜ | |
| 7.2.4 | Upload đính kèm | ⬜ | |

### 7.3 Chi tiết & thao tác — `/van-ban-du-thao/[id]`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 7.3.1 | Hiện chi tiết đúng | ⬜ | |
| 7.3.2 | **Gửi trình duyệt**: gửi cho người duyệt | ⬜ | |
| 7.3.3 | **Duyệt / Hủy duyệt** dự thảo | ⬜ | |
| 7.3.4 | **Thu hồi** dự thảo | ⬜ | |
| 7.3.5 | **Phát hành**: chuyển dự thảo → VB đi chính thức | ⬜ | |
| 7.3.6 | **Từ chối** dự thảo (ghi lý do) | ⬜ | |
| 7.3.7 | Tab Ý kiến / Đính kèm / Người nhận / Lịch sử | ⬜ | |

---

## PHẦN 8: VĂN BẢN LIÊN THÔNG — `/van-ban-lien-thong`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 8.1 | Hiện danh sách VB liên thông (seed: 3 VB) | ⬜ | |
| 8.2 | Chi tiết VB liên thông — hiện đúng thông tin LGSP | ⬜ | |
| 8.3 | **Nhận** VB liên thông → chuyển thành VB đến | ⬜ | |
| 8.4 | **Trả lại** VB liên thông | ⬜ | |
| 8.5 | **Hoàn thành** xử lý VB liên thông | ⬜ | |
| 8.6 | Upload/Xóa đính kèm cho VB liên thông | ⬜ | |
| 8.7 | Tìm kiếm / Lọc | ⬜ | |

---

## PHẦN 9: VĂN BẢN ĐÁNH DẤU — `/van-ban-danh-dau`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 9.1 | Hiện danh sách VB đã đánh dấu (tổng hợp VB đến + đi + dự thảo) | ⬜ | |
| 9.2 | Toggle đánh dấu quan trọng (is_important) | ⬜ | |
| 9.3 | Click VB → mở chi tiết đúng module | ⬜ | |
| 9.4 | Bỏ đánh dấu → biến mất khỏi danh sách | ⬜ | |

---

## PHẦN 10: CẤU HÌNH GỬI NHANH (S1) — `/cau-hinh-gui-nhanh`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 10.1 | Hiện danh sách cấu hình gửi nhanh của user hiện tại | ⬜ | |
| 10.2 | Tạo cấu hình: chọn danh sách người nhận mặc định → Lưu | ⬜ | |
| 10.3 | Khi gửi VB, có option "Gửi nhanh" sử dụng cấu hình đã lưu | ⬜ | |

---

## PHẦN 11: HỒ SƠ CÔNG VIỆC — `/ho-so-cong-viec`

### 11.1 Danh sách
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 11.1.1 | Hiện danh sách HSCV (seed: 6 hồ sơ) | ⬜ | |
| 11.1.2 | Lọc theo trạng thái (Mới / Đang thực hiện / Chờ duyệt / Hoàn thành) | ⬜ | |
| 11.1.3 | Tìm kiếm theo tên hồ sơ | ⬜ | |
| 11.1.4 | Đếm theo trạng thái hiện trên stat cards | ⬜ | |
| 11.1.5 | Pagination | ⬜ | |

### 11.2 CRUD hồ sơ
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 11.2.1 | Tạo HSCV mới → OK | ⬜ | |
| 11.2.2 | Sửa HSCV → OK | ⬜ | |
| 11.2.3 | Xóa HSCV chưa có VB liên quan → OK | ⬜ | |

### 11.3 Chi tiết HSCV — `/ho-so-cong-viec/[id]`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 11.3.1 | Hiện chi tiết: tên, mô tả, trạng thái, tiến độ | ⬜ | |
| 11.3.2 | Danh sách nhân sự phân công | ⬜ | |
| 11.3.3 | Thêm/Xóa nhân sự | ⬜ | |
| 11.3.4 | Danh sách VB liên quan (VB đến + VB đi đã link) | ⬜ | |
| 11.3.5 | Thêm/Xóa VB liên quan | ⬜ | |
| 11.3.6 | Danh sách đính kèm | ⬜ | |

### 11.4 Workflow HSCV
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 11.4.1 | **Nộp** (submit) HSCV → chuyển "Chờ duyệt" | ⬜ | |
| 11.4.2 | **Duyệt** → chuyển "Đã duyệt" | ⬜ | |
| 11.4.3 | **Từ chối** → chuyển "Từ chối" | ⬜ | |
| 11.4.4 | **Trả về** → chuyển "Trả về" | ⬜ | |
| 11.4.5 | **Hoàn thành** → chuyển "Hoàn thành" | ⬜ | |
| 11.4.6 | **Cập nhật tiến độ** (%) | ⬜ | |
| 11.4.7 | Nút bấm hiện/ẩn đúng theo trạng thái hiện tại | ⬜ | |

### 11.5 Báo cáo HSCV — `/ho-so-cong-viec/bao-cao`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 11.5.1 | Báo cáo theo đơn vị | ⬜ | |
| 11.5.2 | Báo cáo theo người xử lý | ⬜ | |
| 11.5.3 | KPI report | ⬜ | |

---

## PHẦN 12: TIN NHẮN — `/tin-nhan`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 12.1 | Hộp thư đến: hiện danh sách (seed: 8 tin nhắn) | ⬜ | |
| 12.2 | Hộp thư đi | ⬜ | |
| 12.3 | Thùng rác | ⬜ | |
| 12.4 | Soạn tin nhắn mới: chọn người nhận + nội dung → Gửi OK | ⬜ | |
| 12.5 | Đọc chi tiết tin nhắn | ⬜ | |
| 12.6 | Trả lời tin nhắn | ⬜ | |
| 12.7 | Xóa tin nhắn | ⬜ | |
| 12.8 | Badge đếm chưa đọc trên sidebar | ⬜ | |

---

## PHẦN 13: THÔNG BÁO — `/thong-bao`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 13.1 | Hiện danh sách thông báo (seed: 6 thông báo) | ⬜ | |
| 13.2 | Tạo thông báo mới (admin/văn thư) | ⬜ | |
| 13.3 | Đọc chi tiết thông báo | ⬜ | |
| 13.4 | Đánh dấu đã đọc / đánh dấu tất cả đã đọc | ⬜ | |
| 13.5 | Badge đếm chưa đọc | ⬜ | |
| 13.6 | Sửa/Xóa thông báo (admin) | ⬜ | |

---

## PHẦN 14: LỊCH

### 14.1 Lịch cá nhân — `/lich/ca-nhan`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 14.1.1 | Hiện lịch tháng/tuần/ngày với các sự kiện (seed: 8 events) | ⬜ | |
| 14.1.2 | Tạo sự kiện mới → OK | ⬜ | |
| 14.1.3 | Sửa/Xóa sự kiện | ⬜ | |
| 14.1.4 | Validation end_date >= start_date | ⬜ | |

### 14.2 Lịch cơ quan — `/lich/co-quan`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 14.2.1 | Hiện lịch chung cơ quan | ⬜ | |
| 14.2.2 | Hiện ngày nghỉ lễ | ⬜ | |

### 14.3 Lịch lãnh đạo — `/lich/lanh-dao`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 14.3.1 | Chỉ admin/lãnh đạo truy cập được | ⬜ | |
| 14.3.2 | Hiện lịch các lãnh đạo | ⬜ | |

---

## PHẦN 15: DANH BẠ — `/danh-ba`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 15.1 | Hiện danh sách nhân viên (tên, SĐT, email, phòng ban, chức vụ) | ⬜ | |
| 15.2 | Tìm kiếm theo tên | ⬜ | |
| 15.3 | Lọc theo phòng ban | ⬜ | |

---

## PHẦN 16: THÔNG TIN CÁ NHÂN — `/thong-tin-ca-nhan`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 16.1 | Hiện thông tin cá nhân đúng (tên, email, SĐT, phòng ban, chức vụ) | ⬜ | |
| 16.2 | Đổi mật khẩu: yêu cầu MK cũ + MK mới (min 6, có chữ hoa + số) + xác nhận | ⬜ | |
| 16.3 | Upload avatar | ⬜ | |

---

## PHẦN 17: QUẢN LÝ — KHO LƯU TRỮ — `/kho-luu-tru`

### 17.1 Danh mục kho/phông
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 17.1.1 | Hiện danh sách kho (seed: 4 kho) | ⬜ | |
| 17.1.2 | CRUD kho → OK | ⬜ | |
| 17.1.3 | Hiện danh sách phông (seed: 3 phông) | ⬜ | |
| 17.1.4 | CRUD phông → OK | ⬜ | |
| 17.1.5 | Hiện danh sách hồ sơ lưu trữ (seed: 5 hồ sơ) | ⬜ | |
| 17.1.6 | CRUD hồ sơ → OK | ⬜ | |

### 17.2 Mượn/trả hồ sơ — `/kho-luu-tru/muon-tra`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 17.2.1 | Hiện danh sách yêu cầu mượn (seed: 2 yêu cầu) | ⬜ | |
| 17.2.2 | Tạo yêu cầu mượn → OK | ⬜ | |
| 17.2.3 | Duyệt yêu cầu mượn | ⬜ | |
| 17.2.4 | Trả hồ sơ | ⬜ | |

---

## PHẦN 18: TÀI LIỆU (ISO) — `/tai-lieu`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 18.1 | Hiện danh sách danh mục tài liệu (seed: 5 danh mục) | ⬜ | |
| 18.2 | Hiện danh sách tài liệu (seed: 6 tài liệu) | ⬜ | |
| 18.3 | CRUD tài liệu → OK | ⬜ | |
| 18.4 | Quản lý phiên bản tài liệu | ⬜ | |
| 18.5 | Bình luận tài liệu | ⬜ | |

---

## PHẦN 19: HỢP ĐỒNG — `/hop-dong`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 19.1 | Hiện danh sách hợp đồng (seed: 4 hợp đồng) | ⬜ | |
| 19.2 | CRUD hợp đồng → OK | ⬜ | |
| 19.3 | Upload/Xóa đính kèm | ⬜ | |
| 19.4 | Ký hợp đồng (mock) | ⬜ | |
| 19.5 | Thực hiện hợp đồng (execute) | ⬜ | |

---

## PHẦN 20: CUỘC HỌP — `/cuoc-hop`

### 20.1 Danh sách cuộc họp
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 20.1.1 | Hiện danh sách (seed: 4 cuộc họp) | ⬜ | |
| 20.1.2 | Tìm kiếm / Lọc | ⬜ | |

### 20.2 CRUD cuộc họp
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 20.2.1 | Tạo cuộc họp: chọn phòng, thời gian, loại → OK | ⬜ | |
| 20.2.2 | Sửa/Xóa cuộc họp → OK | ⬜ | |
| 20.2.3 | Thêm/Xóa người tham dự | ⬜ | |
| 20.2.4 | Tạo chương trình nghị sự (agenda) | ⬜ | |
| 20.2.5 | Biên bản cuộc họp (minutes): tạo/sửa | ⬜ | |

### 20.3 Điều hành cuộc họp
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 20.3.1 | **Bắt đầu** cuộc họp | ⬜ | |
| 20.3.2 | **Điểm danh** người tham dự | ⬜ | |
| 20.3.3 | **Kết thúc** cuộc họp | ⬜ | |
| 20.3.4 | Link tài liệu vào cuộc họp | ⬜ | |

### 20.4 Thống kê — `/cuoc-hop/thong-ke`
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 20.4.1 | Hiện thống kê cuộc họp | ⬜ | |

---

## PHẦN 21: QUY TRÌNH (Workflow) — `/quan-tri/quy-trinh`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 21.1 | Hiện danh sách quy trình | ⬜ | |
| 21.2 | Tạo quy trình mới | ⬜ | |
| 21.3 | Thiết kế quy trình (kéo thả bước/liên kết) — `/quan-tri/quy-trinh/[id]/thiet-ke` | ⬜ | |
| 21.4 | Thêm/Sửa/Xóa bước xử lý | ⬜ | |
| 21.5 | Thêm/Sửa/Xóa liên kết giữa các bước | ⬜ | |
| 21.6 | Validate quy trình (kiểm tra hợp lệ) | ⬜ | |

---

## PHẦN 22: TÍCH HỢP LGSP — `/lgsp`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 22.1 | Hiện danh sách tracking liên thông | ⬜ | |
| 22.2 | Cơ quan liên thông: hiện danh sách đơn vị (seed: 7 đơn vị) | ⬜ | |
| 22.3 | Đồng bộ cơ quan | ⬜ | |
| 22.4 | Mock gửi VB qua LGSP → tạo tracking | ⬜ | |
| 22.5 | Mock nhận VB từ LGSP → tạo VB liên thông | ⬜ | |

---

## PHẦN 23: KÝ SỐ — Digital Signature (S7)

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 23.1 | Mock ký số: chọn file đính kèm → ký → is_ca = true | ⬜ | |
| 23.2 | Mock xác minh chữ ký → trả kết quả is_valid | ⬜ | |
| 23.3 | Hiện trạng thái ký số trên file đính kèm | ⬜ | |

---

## PHẦN 24: THÔNG BÁO KÊNH — `/thong-bao-kenh`

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 24.1 | Hiện danh sách log thông báo (seed: 10 logs) | ⬜ | |
| 24.2 | Hiện cấu hình notification preferences (seed: 24 prefs) | ⬜ | |
| 24.3 | Gửi test notification | ⬜ | |

---

## PHẦN 25: CROSS-MODULE FLOW (End-to-End)

### 25.1 Flow chính: VB đến → Xử lý → VB đi
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 25.1.1 | Login `phamvane` (Văn thư) → Tạo VB đến mới | ⬜ | |
| 25.1.2 | Gửi VB đến cho `nguyenvana` (Lãnh đạo) | ⬜ | |
| 25.1.3 | Login `nguyenvana` → Thấy VB đến trong hộp thư | ⬜ | |
| 25.1.4 | Nguyenvana ghi bút phê + phân công cho `hoangthif` | ⬜ | |
| 25.1.5 | Login `hoangthif` → Thấy VB đến + ý kiến lãnh đạo | ⬜ | |
| 25.1.6 | Hoangthif tạo HSCV từ VB đến → xử lý → hoàn thành | ⬜ | |
| 25.1.7 | Phamvane tạo VB dự thảo → gửi trình duyệt cho nguyenvana | ⬜ | |
| 25.1.8 | Nguyenvana duyệt dự thảo | ⬜ | |
| 25.1.9 | Phamvane phát hành dự thảo → tạo VB đi chính thức | ⬜ | |
| 25.1.10 | VB đi xuất hiện trong danh sách VB đi | ⬜ | |

### 25.2 Flow liên thông
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 25.2.1 | Admin gửi VB đến qua LGSP → tạo tracking | ⬜ | |
| 25.2.2 | VB xuất hiện trong danh sách VB liên thông | ⬜ | |
| 25.2.3 | Nhận VB liên thông → tạo VB đến mới | ⬜ | |

### 25.3 Flow lưu trữ
| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 25.3.1 | Chuyển VB đã xử lý vào kho lưu trữ | ⬜ | |
| 25.3.2 | Tìm thấy VB trong kho lưu trữ | ⬜ | |
| 25.3.3 | Tạo yêu cầu mượn hồ sơ → duyệt → trả | ⬜ | |

---

## PHẦN 26: UI/UX QUALITY

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 26.1 | Tất cả text hiển thị tiếng Việt có dấu | ⬜ | |
| 26.2 | Sidebar collapse/expand hoạt động mượt | ⬜ | |
| 26.3 | Drawer mở/đóng animation mượt | ⬜ | |
| 26.4 | Table loading skeleton khi fetch data | ⬜ | |
| 26.5 | Toast notification hiện đúng (success/error) | ⬜ | |
| 26.6 | Modal.confirm cho delete actions | ⬜ | |
| 26.7 | Dropdown menu (...) cho table actions | ⬜ | |
| 26.8 | Không FOUC (Flash Of Unstyled Content) khi load trang | ⬜ | |
| 26.9 | Theme đúng: Primary #1B3A5C, Background #F0F2F5 | ⬜ | |
| 26.10 | Font Plus Jakarta Sans load đúng | ⬜ | |
| 26.11 | Responsive: co sidebar khi viewport nhỏ | ⬜ | |
| 26.12 | Breadcrumb / page title hiện đúng | ⬜ | |

---

## PHẦN 27: ERROR HANDLING

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 27.1 | Unique constraint → hiện lỗi inline trên field (không alert) | ⬜ | |
| 27.2 | FK constraint → thông báo "Không thể xóa vì đang được sử dụng" | ⬜ | |
| 27.3 | Required field bỏ trống → validation message tiếng Việt | ⬜ | |
| 27.4 | API 500 → `message.error(...)` chung, không lộ stack trace | ⬜ | |
| 27.5 | Token hết hạn → auto refresh, nếu fail → redirect login | ⬜ | |
| 27.6 | Network error → thông báo "Không kết nối được server" | ⬜ | |

---

## PHẦN 28: FILE UPLOAD / DOWNLOAD

| # | Test case | Kết quả | Ghi chú |
|---|-----------|---------|---------|
| 28.1 | Upload file .pdf → OK | ⬜ | |
| 28.2 | Upload file .docx → OK | ⬜ | |
| 28.3 | Upload file .xlsx → OK | ⬜ | |
| 28.4 | Upload file .jpg/.png → OK | ⬜ | |
| 28.5 | Upload file > 50MB → báo lỗi | ⬜ | |
| 28.6 | Upload file không hợp lệ (.exe) → báo lỗi | ⬜ | |
| 28.7 | Download file → nhận đúng file, tên đúng | ⬜ | |
| 28.8 | Xóa file đính kèm → OK | ⬜ | |

---

## TỔNG KẾT

| Phần | Số test cases | Pass | Fail | Chưa test |
|------|:---:|:---:|:---:|:---:|
| 0. Hạ tầng | 8 | | | |
| 1. Đăng nhập & Phân quyền | 15 | | | |
| 2. Dashboard | 5 | | | |
| 3. Quản trị HT | 25 | | | |
| 4. Danh mục | 22 | | | |
| 5. VB Đến | 30 | | | |
| 6. VB Đi | 18 | | | |
| 7. VB Dự thảo | 14 | | | |
| 8. VB Liên thông | 7 | | | |
| 9. VB Đánh dấu | 4 | | | |
| 10. Gửi nhanh | 3 | | | |
| 11. HSCV | 20 | | | |
| 12. Tin nhắn | 8 | | | |
| 13. Thông báo | 6 | | | |
| 14. Lịch | 7 | | | |
| 15. Danh bạ | 3 | | | |
| 16. Thông tin cá nhân | 3 | | | |
| 17. Kho lưu trữ | 10 | | | |
| 18. Tài liệu ISO | 5 | | | |
| 19. Hợp đồng | 5 | | | |
| 20. Cuộc họp | 10 | | | |
| 21. Quy trình | 6 | | | |
| 22. LGSP | 5 | | | |
| 23. Ký số | 3 | | | |
| 24. Thông báo kênh | 3 | | | |
| 25. E2E Flow | 13 | | | |
| 26. UI/UX | 12 | | | |
| 27. Error Handling | 6 | | | |
| 28. File Upload | 8 | | | |
| **TỔNG** | **~284** | | | |

---

## ƯU TIÊN TEST CHO DEMO (18-19/04)

### P0 — Phải pass 100% (Core flow):
1. Đăng nhập 4 tài khoản (1.1.1 → 1.1.4)
2. Phân quyền menu (1.2.1 → 1.2.4)
3. VB Đến: CRUD + Gửi + Duyệt + Giao việc (5.1 → 5.4)
4. VB Đi: CRUD + Gửi + Duyệt (6.1 → 6.4)
5. VB Dự thảo: CRUD + Trình duyệt + Phát hành (7.1 → 7.3)
6. HSCV: CRUD + Workflow (11.1 → 11.4)
7. E2E Flow: VB đến → Xử lý → VB đi (25.1)
8. Dashboard hiện đúng (2.1 → 2.4)

### P1 — Nên pass (Important):
1. Quản trị: Đơn vị, Chức vụ, Người dùng (3.1 → 3.3)
2. Danh mục: Sổ VB, Loại VB, Lĩnh vực (4.1 → 4.3)
3. VB Liên thông (8.x)
4. Tin nhắn + Thông báo (12.x, 13.x)
5. Lịch (14.x)
6. File upload/download (28.x)

### P2 — Nice to have:
1. Kho lưu trữ, Tài liệu, Hợp đồng (17-19)
2. Cuộc họp (20.x)
3. LGSP + Ký số (22-23)
4. Quy trình workflow design (21.x)
5. UI/UX polish (26.x)
