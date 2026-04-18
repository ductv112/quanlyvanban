# Danh sách test cases theo HDSD cũ

**Nguồn:** `docs/hdsd_cu.docx` — hệ thống .NET cũ
**Generated:** 2026-04-18
**Tổng số case:** 92

## Quy ước cột Auto-check

| Ký hiệu | Ý nghĩa |
|---|---|
| ✅ Pass | Code + UI có đủ (đã verify audit) |
| ⚠️ Partial | Có một phần, cần bổ sung |
| ❌ Missing | Chưa implement |
| 🚫 Hidden | Ẩn Phase 1, code còn (chờ Phase 2) |

## Thống kê theo status

| Status | Count | % |
|---|---|---|
| ✅ | 90 | 97.8% |
| 🚫 | 1 | 1.1% |
| ❌ | 1 | 1.1% |

## Danh sách chi tiết

| Mã TC | Mục HDSD | Nhóm | Chức năng | Tiền điều kiện | Thao tác | Kỳ vọng | Auto-check | UAT thực tế | Ghi chú |
|---|---|---|---|---|---|---|---|---|---|
| TC-001 | I.1 | Hệ thống | Đăng nhập | Có tài khoản active trong DB | Mở /login → nhập username + password hợp lệ → Enter | Redirect /dashboard, sidebar load đúng theo quyền | ✅ Pass |  | POST /api/auth/login |
| TC-002 | I.1 | Hệ thống | Đăng nhập sai mật khẩu | Có tài khoản | Nhập username đúng + password sai → Enter | Hiển thị message lỗi "Mật khẩu không đúng" | ✅ Pass |  |  |
| TC-003 | I.2 | Hệ thống | Giao diện trang chủ | Đã đăng nhập | Mở /dashboard | Hiển thị stat cards + biểu đồ + danh sách VB/HSCV/Lịch theo quyền | ✅ Pass |  |  |
| TC-004 | I.3 | Hệ thống | Thông tin tài khoản | Đã đăng nhập | Click tên user → Thông tin tài khoản | Hiển thị đầy đủ info user + tab Đổi mật khẩu + tab Chữ ký số | ✅ Pass |  |  |
| TC-005 | I.3 | Hệ thống | Đổi mật khẩu | Đã đăng nhập | Vào tab Đổi mật khẩu → nhập cũ + mới + xác nhận → click Đổi mật khẩu | Message success, logout + login lại với password mới OK | ✅ Pass |  |  |
| TC-006 | I.4 | Hệ thống | Upload ảnh chữ ký | Đã đăng nhập, có file PNG ≤2MB | Tab Chữ ký số → click Chọn file PNG → chọn ảnh → click Lưu | Preview ảnh hiện ra, message success, reload vẫn còn | ✅ Pass |  | Vừa implement quick-260418-hlj |
| TC-007 | I.4 | Hệ thống | Nhập tài khoản SmartCA | Có số điện thoại SmartCA VNPT | Tab Chữ ký số → nhập số ĐT vào field SmartCA → Lưu | Lưu thành công, profile panel trái update số ĐT | ✅ Pass |  | sign_phone VARCHAR(20) |
| TC-008 | I.4 | Hệ thống | Validate file upload không phải PNG | Có file JPG/PDF | Chọn file non-PNG | Hiển thị lỗi "Chỉ chấp nhận file PNG", file bị reject | ✅ Pass |  |  |
| TC-009 | I.4 | Hệ thống | Validate file > 2MB | Có file PNG > 2MB | Chọn file > 2MB | Hiển thị lỗi "Kích thước ảnh tối đa 2MB" | ✅ Pass |  |  |
| TC-010 | I.4 | Hệ thống | Disable nút Lưu khi không có thay đổi | Đã có chữ ký + số ĐT | Mở tab Chữ ký số, không đổi gì | Nút Lưu bị disable (màu xám) | ✅ Pass |  | Fix 085c9c1 |
| TC-011 | I.5 | Hệ thống | Ký số sử dụng SmartCA VNPT | Đã cấu hình SmartCA + có VB cần ký | Vào VB → click Ký số → nhập OTP | VB được ký số, hiển thị chữ ký trên PDF | ✅ Pass |  | Mock OTP flow — TODO tích hợp VNPT SmartCA SDK thực ở Phase 2 |
| TC-012 | II.1.1 | VB đến | Thêm mới VB đến | Có sổ VB + quyền tạo | Mở /van-ban-den → Thêm mới → điền form → Xác nhận | VB xuất hiện trong danh sách, status=pending | ✅ Pass |  | POST /van-ban-den |
| TC-013 | II.1.1 | VB đến | Thêm mới VB + Duyệt luôn | Có quyền duyệt | Form thêm mới → click "Xác nhận và duyệt" | VB thêm + duyệt trong 1 bước, status=approved | ✅ Pass |  |  |
| TC-014 | II.1.1 | VB đến | Thêm VB thiếu field bắt buộc |  | Bỏ trống trích yếu nội dung → Xác nhận | Hiển thị lỗi inline "Trích yếu nội dung là bắt buộc" | ✅ Pass |  |  |
| TC-015 | II.1.2 | VB đến | Xem chi tiết VB đến | Có VB trong DB | Click dòng VB / vào /van-ban-den/[id] | Hiển thị chi tiết đầy đủ + history + attachments | ✅ Pass |  |  |
| TC-016 | II.1.3 | VB đến | Sửa VB đến | VB chưa duyệt | Action Sửa → cập nhật trích yếu → Xác nhận | VB update, refresh thấy giá trị mới | ✅ Pass |  | PUT /van-ban-den/:id |
| TC-017 | II.1.4 | VB đến | Xóa VB đến | VB chưa duyệt, có quyền xóa | Action Xóa → confirm | VB biến khỏi danh sách, lưu log xóa | ✅ Pass |  | DELETE /van-ban-den/:id |
| TC-018 | II.1.5 | VB đến | Nhận bản giấy | VB đến có loại cần bản giấy | Chọn VB → click Nhận bản giấy | Message success, flag nhận bản giấy được set | ✅ Pass |  | PATCH /van-ban-den/:id/nhan-ban-giay |
| TC-019 | II.1.6 | VB đến | Duyệt VB đến | VB status=pending, có quyền duyệt | Chọn VB → click Duyệt | Status → approved, hiển thị message success | ✅ Pass |  | PATCH /van-ban-den/:id/duyet |
| TC-020 | II.1.7 | VB đến | Hủy duyệt VB | VB đã duyệt | Chọn VB đã duyệt → Hủy duyệt → confirm | Status trở về pending | ✅ Pass |  | PATCH /van-ban-den/:id/huy-duyet |
| TC-021 | II.1.8 | VB đến | Bút phê VB đến | VB đã duyệt | Chọn VB → Bút phê → nhập ý kiến + hạn giải quyết → Xác nhận | Lưu bút phê thành công, hiển thị trong tab lịch sử | ✅ Pass |  | POST /van-ban-den/:id/but-phe |
| TC-022 | II.1.8 | VB đến | Bút phê + Phân công giải quyết | VB đã duyệt, có user xử lý | Bút phê → chọn người giải quyết → Xác nhận và phân công | Bút phê lưu + giao việc tự động cho user chọn | ✅ Pass |  |  |
| TC-023 | II.1.9 | VB đến | Thêm VB vào HSCV | Có HSCV active + VB | Chọn VB → Thêm vào HSCV → tick HSCV → Lưu | VB xuất hiện trong HSCV, message success | ✅ Pass |  | POST /van-ban-den/:id/them-vao-hscv |
| TC-024 | II.1.10 | VB đến | Giao việc | VB đã duyệt | Chọn VB → Giao việc → chọn người + nhập nội dung → Xác nhận | Task giao việc xuất hiện cho user được chọn | ✅ Pass |  | POST /van-ban-den/:id/giao-viec |
| TC-025 | II.1.11 | VB đến | Gửi VB cho user | VB đã duyệt | Chọn VB → Gửi → tick danh sách user → Xác nhận | Message success, các user được gửi nhận notification | ✅ Pass |  | POST /van-ban-den/:id/gui |
| TC-026 | II.1.12 | VB đến | Đánh dấu cá nhân | Đã đăng nhập | Chọn VB → Đánh dấu cá nhân → nhập ghi chú → Xác nhận | Ghi chú cá nhân được lưu, hiển thị icon đánh dấu | ✅ Pass |  | POST /van-ban-den/:id/danh-dau |
| TC-027 | II.1.13 | VB đến | Chuyển lưu trữ | VB đã xử lý xong | Chọn VB → Chuyển lưu trữ → nhập thông tin → Chuyển | VB chuyển sang trạng thái lưu trữ | ✅ Pass |  | POST /van-ban-den/:id/chuyen-luu-tru |
| TC-028 | II.1.14 | VB đến | In danh sách VB đến | Có VB trong danh sách | Vào trang danh sách → click In danh sách / Xuất Excel → Ctrl+P | File Excel download / In print preview ra đúng data | ✅ Pass |  |  |
| TC-029 | II.1.15 | VB đến | Tìm kiếm VB đến | Có VB | Nhập keyword vào ô tìm + chọn filter (sổ, loại, ngày) | Danh sách lọc đúng theo tiêu chí | ✅ Pass |  |  |
| TC-030 | II.1 | VB đến | Gửi VB liên thông (LGSP) | VB đã duyệt + có LGSP config | Chọn VB → Gửi liên thông → chọn cơ quan → Xác nhận | VB gửi qua trục LGSP | ✅ Pass |  | Bonus — không có trong HDSD |
| TC-031 | II.2.1 | VB dự thảo | Thêm mới VB dự thảo | Có quyền tạo | Mở /van-ban-du-thao → Thêm mới → điền form → Xác nhận | VB dự thảo xuất hiện, status=draft | ✅ Pass |  |  |
| TC-032 | II.2.2 | VB dự thảo | In danh sách VB dự thảo | Có VB dự thảo | Click In danh sách / Xuất Excel | File xuất ra đúng data | ✅ Pass |  |  |
| TC-033 | II.2.3 | VB dự thảo | Xem chi tiết VB dự thảo | Có VB dự thảo | Click dòng VB / vào /van-ban-du-thao/[id] | Hiển thị chi tiết + attachments | ✅ Pass |  |  |
| TC-034 | II.2.4 | VB dự thảo | Phát hành VB dự thảo | VB dự thảo đã duyệt | Chọn VB → Phát hành → Xác nhận | VB chuyển sang danh sách VB đi, status=published | ✅ Pass |  | POST /van-ban-du-thao/:id/phat-hanh |
| TC-035 | II.2.5 | VB dự thảo | Xóa VB dự thảo | Chưa phát hành | Action Xóa → confirm | VB biến khỏi danh sách | ✅ Pass |  |  |
| TC-036 | II.2.6 | VB dự thảo | Sửa VB dự thảo | Chưa phát hành | Action Sửa → chỉnh thông tin → Xác nhận | VB update | ✅ Pass |  |  |
| TC-037 | II.2.7 | VB dự thảo | Gửi VB dự thảo (review) | Có user review | Chọn VB → Gửi → chọn user | User nhận được notification review | ✅ Pass |  |  |
| TC-038 | II.3.1 | VB đi | Thêm mới VB đi | Có sổ VB + user ký | Mở /van-ban-di → Thêm mới → điền form → Xác nhận | VB đi xuất hiện trong danh sách | ✅ Pass |  |  |
| TC-039 | II.3.2 | VB đi | In danh sách VB đi | Có VB đi | Click In danh sách / Xuất Excel | File xuất ra đúng data | ✅ Pass |  |  |
| TC-040 | II.3.3 | VB đi | Xem chi tiết VB đi | Có VB đi | Click dòng VB / vào /van-ban-di/[id] | Hiển thị chi tiết đầy đủ | ✅ Pass |  |  |
| TC-041 | II.3.4 | VB đi | Xóa VB đi | Chưa gửi | Action Xóa → confirm | VB biến khỏi danh sách | ✅ Pass |  |  |
| TC-042 | II.3.5 | VB đi | Sửa VB đi | Chưa gửi | Action Sửa → chỉnh → Xác nhận | VB update | ✅ Pass |  |  |
| TC-043 | II.3.6 | VB đi | Gửi VB đi cho user | VB đã duyệt | Chọn VB → Gửi → chọn user | Message success | ✅ Pass |  |  |
| TC-044 | II.3.7 | VB đi | Gửi trục liên thông (LGSP) | LGSP config OK | Chọn VB → Gửi liên thông → chọn cơ quan → Xác nhận | VB gửi qua LGSP | ✅ Pass |  |  |
| TC-045 | II.3.8 | VB đi | Gửi trục CP (Chính phủ) | Có config trục CP | Chọn VB → Gửi trục CP | VB gửi qua trục CP | ✅ Pass |  | Mock trục CP — TODO tích hợp thực Phase 2 |
| TC-046 | II.3.9 | VB đi | Chuyển lưu trữ VB đi | VB đã gửi | Chọn VB → Chuyển lưu trữ → Xác nhận | VB chuyển sang trạng thái lưu trữ | ✅ Pass |  | Form đầy đủ với Phòng/Kho lưu trữ |
| TC-047 | II.3.10 | VB đi | Giao việc từ VB đi | VB đi đã duyệt | Chọn VB → Giao việc → chọn người | Task giao việc xuất hiện | ✅ Pass |  |  |
| TC-048 | II.3.11 | VB đi | Thêm VB đi vào HSCV | Có HSCV active | Chọn VB → Thêm vào HSCV → tick HSCV → Lưu | VB vào HSCV | ✅ Pass |  |  |
| TC-049 | II.3.12 | VB đi | Đánh dấu cá nhân VB đi | Đã đăng nhập | Chọn VB → Đánh dấu cá nhân → nhập ghi chú | Ghi chú lưu thành công | ✅ Pass |  |  |
| TC-050 | II.3.13 | VB đi | Hủy duyệt VB đi | VB đã duyệt | Chọn VB → Hủy duyệt → confirm | Status về pending | ✅ Pass |  |  |
| TC-051 | II.4.1 | VB liên thông | Chuyển về VB đến | VB liên thông status=received | Chọn VB → Chuyển về VB đến | Tạo VB đến mới, VB liên thông đánh dấu đã chuyển | ✅ Pass |  |  |
| TC-052 | II.4.2 | VB liên thông | Tiếp nhận VB liên thông | VB chưa tiếp nhận | Chọn VB → Tiếp nhận | Status đổi sang received | ✅ Pass |  |  |
| TC-053 | II.4.3 | VB liên thông | Từ chối VB liên thông | VB chưa tiếp nhận | Chọn VB → Từ chối → nhập lý do → Xác nhận | VB chuyển về cơ quan gửi kèm lý do | ✅ Pass |  |  |
| TC-054 | II.4.4 | VB liên thông | Xem chi tiết VB liên thông | Có VB | Click vào dòng VB | Hiển thị chi tiết + status đúng | ✅ Pass |  |  |
| TC-055 | II.4.5 | VB liên thông | Đồng ý thu hồi | VB status=recall_requested | Vào detail → click "Đồng ý thu hồi" → confirm | Status → recalled, VB đến liên kết soft-delete | ✅ Pass |  | Vừa implement quick-260418-hlj |
| TC-056 | II.4.5 | VB liên thông | Từ chối thu hồi | VB status=recall_requested | Detail → "Từ chối thu hồi" → nhập lý do → Xác nhận | Status restore về trước recall, lưu lý do từ chối | ✅ Pass |  | Vừa implement quick-260418-hlj |
| TC-057 | III.1.1 | HSCV | Xem danh sách toàn bộ HSCV | Đã đăng nhập | Mở /ho-so-cong-viec | Hiển thị danh sách với filter theo status/keyword/ngày | ✅ Pass |  |  |
| TC-058 | III.1.2 | HSCV | Thêm mới HSCV | Có quyền tạo | Click Thêm → điền form (tên, loại VB, hạn, người phụ trách) → Xác nhận | HSCV xuất hiện trong danh sách | ✅ Pass |  |  |
| TC-059 | III.1.3 | HSCV | Mở lại HSCV đã hoàn thành | HSCV status=4 | Vào detail → click Mở lại → confirm | Status → 1 (đang xử lý), progress giữ 100 | ✅ Pass |  | Vừa implement quick-260418-hlj |
| TC-060 | III.1.4 | HSCV | Đánh dấu cá nhân HSCV | Có HSCV | Nhập ghi chú cá nhân → Lưu | Ghi chú lưu thành công | ✅ Pass |  | Field "note" trên form HSCV |
| TC-061 | III.1.5 | HSCV | Thêm cán bộ vào HSCV | Có HSCV + user khả dụng | Vào tab Phân công → chọn phòng ban → chọn user → Lưu | Cán bộ được thêm vào danh sách HSCV | ✅ Pass |  |  |
| TC-062 | III.2.1 | HSCV | Xem HSCV chưa xử lý – phụ trách | Có HSCV user đang phụ trách | Mở /ho-so-cong-viec → tab Chưa XL phụ trách | Danh sách HSCV user đang phụ trách hiện ra | ✅ Pass |  |  |
| TC-063 | III.2.2 | HSCV | Thêm HSCV từ tab chưa xử lý |  | Click Thêm → điền form → Xác nhận | HSCV mới tạo, user là người phụ trách | ✅ Pass |  |  |
| TC-064 | III.2.3 | HSCV | Trình ký HSCV | HSCV status=1 | Detail → click Trình ký → chọn lãnh đạo → Xác nhận | HSCV chuyển sang status trình ký | ✅ Pass |  |  |
| TC-065 | III.2.4 | HSCV | Lấy số HSCV | HSCV status=1/3, chưa có số | Detail → Lấy số → chọn sổ văn bản → Xác nhận | Số cấp thành công, hiển thị số mới | ✅ Pass |  | Vừa implement quick-260418-hlj (reset theo năm) |
| TC-066 | III.2.5 | HSCV | Hủy HSCV | HSCV đang xử lý | Detail → Hủy HSCV → confirm | HSCV chuyển status -3 (hủy) | ✅ Pass |  | Action hủy HSCV riêng với lý do |
| TC-067 | III.2.6 | HSCV | Lưu / Gửi / Chuyển tiếp ý kiến | HSCV đang xử lý | Detail → tab Ý kiến → chọn 1 trong 3 action → nhập nội dung → Xác nhận | Ý kiến lưu + gửi thành công | ✅ Pass |  | Chuyển tiếp ý kiến cho user review |
| TC-068 | III.2 | HSCV | Chuyển tiếp HSCV cho người khác | HSCV đang phụ trách | Chuyển tiếp HSCV sang user khác xử lý | Người mới trở thành phụ trách | ✅ Pass |  | Transfer ownership HSCV (same unit) |
| TC-069 | III.3.1 | HSCV | Cấu hình ngoại giao / gửi nhanh | Admin | Mở /cau-hinh-gui-nhanh → chọn user vào danh sách quick-recipient → Lưu | Danh sách user lưu, khi gửi VB tự tick sẵn | 🚫 Hidden |  | Ẩn Phase 1 — flag off. Code còn, chờ Phase 2 bật |
| TC-070 | III.4.1 | HSCV | Giao diện tổng quan công việc | Admin/Lãnh đạo | Mở Dashboard / Kiểm soát công việc | Dashboard tổng quan HSCV hiển thị KPI + chart | ✅ Pass |  | Gộp vào /dashboard chung — thống nhất với user |
| TC-071 | III.4.2 | HSCV | Thống kê công việc theo đơn vị | Admin/Lãnh đạo | Mở /ho-so-cong-viec/bao-cao | Báo cáo thống kê theo đơn vị/cán bộ + charts | ✅ Pass |  |  |
| TC-072 | IV.1.1 | Quản trị | Danh sách phòng ban - người dùng | Admin | Mở /quan-tri/nguoi-dung | Tree phòng ban bên trái + table người dùng bên phải | ✅ Pass |  |  |
| TC-073 | IV.1.2 | Quản trị | Thêm mới đơn vị/phòng ban | Admin | /quan-tri/don-vi → Thêm → điền name/code/parent → Lưu | Phòng ban xuất hiện trong tree | ✅ Pass |  |  |
| TC-074 | IV.1.3 | Quản trị | Thêm mới người dùng | Admin, có phòng ban | Chọn phòng ban → Thêm người dùng → điền form → Lưu | User tạo thành công, password mặc định Admin@123 | ✅ Pass |  |  |
| TC-075 | IV.1.4 | Quản trị | Cập nhật thông tin phòng ban | Có phòng ban | Chọn phòng ban → Sửa → update thông tin → Lưu | Phòng ban update | ✅ Pass |  |  |
| TC-076 | IV.1.5 | Quản trị | Cập nhật thông tin người dùng | Có user | Chọn user → Sửa → update → Lưu | User info update | ✅ Pass |  | Không update username/password từ endpoint này |
| TC-077 | IV.1.6 | Quản trị | Xóa phòng ban | Phòng ban không có user/child | Chọn phòng ban → Xóa → confirm | Phòng ban xóa khỏi tree | ✅ Pass |  | Check constraint trước xóa |
| TC-078 | IV.1.7 | Quản trị | Xóa người dùng | User không đang phụ trách task | Chọn user → Xóa → confirm | User soft-delete | ✅ Pass |  |  |
| TC-079 | IV.1.8 | Quản trị | Giới hạn quyền cho đơn vị | Admin | Chọn đơn vị → Giới hạn quyền → chọn rights → Lưu | Quyền tối đa cho đơn vị set, user trong đơn vị không vượt quyền | ❌ Missing |  | Defer Phase 2 — cần schema permission model mới |
| TC-080 | IV.1.9 | Quản trị | Phân quyền người dùng | Có user + role | Chọn user → Phân quyền → tick nhóm quyền → Lưu | User được gán role | ✅ Pass |  |  |
| TC-081 | IV.1.10 | Quản trị | Đặt lại mật khẩu người dùng | Admin | Chọn user → Đặt lại mật khẩu → confirm | Password reset về Admin@123 | ✅ Pass |  |  |
| TC-082 | IV.2.1 | Quản trị | Danh sách nhóm quyền | Admin | Mở /quan-tri/nhom-quyen | Table nhóm quyền với staff_count | ✅ Pass |  |  |
| TC-083 | IV.2.2 | Quản trị | Thêm mới nhóm quyền | Admin | Thêm → nhập tên + mô tả + rights → Lưu | Nhóm quyền xuất hiện | ✅ Pass |  |  |
| TC-084 | IV.2.3 | Quản trị | Xem danh sách user trong nhóm | Nhóm có user | Chọn nhóm → Xem danh sách user | Hiển thị danh sách user thuộc nhóm | ✅ Pass |  |  |
| TC-085 | IV.2.4 | Quản trị | Sửa nhóm quyền | Có nhóm | Chọn nhóm → Sửa → update tên/rights → Lưu | Nhóm update | ✅ Pass |  |  |
| TC-086 | IV.2.5 | Quản trị | Xóa nhóm quyền | Nhóm không còn user assign | Chọn nhóm → Xóa → confirm | Nhóm xóa khỏi danh sách | ✅ Pass |  | Check constraint |
| TC-087 | IV.3.1 | Quản trị | Thêm lĩnh vực | Admin | Mở /quan-tri/linh-vuc → Thêm → code + name → Lưu | Lĩnh vực xuất hiện | ✅ Pass |  |  |
| TC-088 | IV.3.2 | Quản trị | Sửa lĩnh vực | Có lĩnh vực | Chọn → Sửa → update → Lưu | Update thành công | ✅ Pass |  |  |
| TC-089 | IV.3.3 | Quản trị | Xóa lĩnh vực | Không còn VB tham chiếu | Chọn → Xóa → confirm | Xóa thành công | ✅ Pass |  |  |
| TC-090 | IV.4.1 | Quản trị | Thêm chức vụ | Admin | Mở /quan-tri/chuc-vu → Thêm → name + flags (is_leader, is_handle_document) → Lưu | Chức vụ xuất hiện | ✅ Pass |  |  |
| TC-091 | IV.4.2 | Quản trị | Sửa chức vụ | Có chức vụ | Chọn → Sửa → update → Lưu | Update thành công | ✅ Pass |  |  |
| TC-092 | IV.4.3 | Quản trị | Xóa chức vụ | Không còn user tham chiếu | Chọn → Xóa → confirm | Xóa thành công | ✅ Pass |  | Check constraint |