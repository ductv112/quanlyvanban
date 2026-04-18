/**
 * Generate test catalog from HDSD cũ → markdown + Excel.
 * Nguồn truth: array `cases` bên dưới (82 cases từ docs/hdsd_cu.docx).
 * Auto-check status đã fill sẵn theo kết quả audit (quick-260418-hlj).
 *
 * Chạy: node scripts/gen-test-catalog.cjs
 * Output:
 *   docs/test_theo_hdsd_cu.md
 *   docs/test_theo_hdsd_cu.xlsx
 */

const path = require('path');
const fs = require('fs');
const ExcelJS = require('exceljs');

// ─── Test cases (HDSD cũ) ────────────────────────────────────────────────────
// auto: ✅ Pass | ⚠️ Partial | ❌ Missing | 🚫 Hidden (Phase 1)
const cases = [
  // ═══════════════ I. HỆ THỐNG ═══════════════
  { id: 'TC-001', muc: 'I.1', nhom: 'Hệ thống', cn: 'Đăng nhập', pre: 'Có tài khoản active trong DB', thao: 'Mở /login → nhập username + password hợp lệ → Enter', ky: 'Redirect /dashboard, sidebar load đúng theo quyền', auto: '✅ Pass', note: 'POST /api/auth/login' },
  { id: 'TC-002', muc: 'I.1', nhom: 'Hệ thống', cn: 'Đăng nhập sai mật khẩu', pre: 'Có tài khoản', thao: 'Nhập username đúng + password sai → Enter', ky: 'Hiển thị message lỗi "Mật khẩu không đúng"', auto: '✅ Pass', note: '' },
  { id: 'TC-003', muc: 'I.2', nhom: 'Hệ thống', cn: 'Giao diện trang chủ', pre: 'Đã đăng nhập', thao: 'Mở /dashboard', ky: 'Hiển thị stat cards + biểu đồ + danh sách VB/HSCV/Lịch theo quyền', auto: '✅ Pass', note: '' },
  { id: 'TC-004', muc: 'I.3', nhom: 'Hệ thống', cn: 'Thông tin tài khoản', pre: 'Đã đăng nhập', thao: 'Click tên user → Thông tin tài khoản', ky: 'Hiển thị đầy đủ info user + tab Đổi mật khẩu + tab Chữ ký số', auto: '✅ Pass', note: '' },
  { id: 'TC-005', muc: 'I.3', nhom: 'Hệ thống', cn: 'Đổi mật khẩu', pre: 'Đã đăng nhập', thao: 'Vào tab Đổi mật khẩu → nhập cũ + mới + xác nhận → click Đổi mật khẩu', ky: 'Message success, logout + login lại với password mới OK', auto: '✅ Pass', note: '' },
  { id: 'TC-006', muc: 'I.4', nhom: 'Hệ thống', cn: 'Upload ảnh chữ ký', pre: 'Đã đăng nhập, có file PNG ≤2MB', thao: 'Tab Chữ ký số → click Chọn file PNG → chọn ảnh → click Lưu', ky: 'Preview ảnh hiện ra, message success, reload vẫn còn', auto: '✅ Pass', note: 'Vừa implement quick-260418-hlj' },
  { id: 'TC-007', muc: 'I.4', nhom: 'Hệ thống', cn: 'Nhập tài khoản SmartCA', pre: 'Có số điện thoại SmartCA VNPT', thao: 'Tab Chữ ký số → nhập số ĐT vào field SmartCA → Lưu', ky: 'Lưu thành công, profile panel trái update số ĐT', auto: '✅ Pass', note: 'sign_phone VARCHAR(20)' },
  { id: 'TC-008', muc: 'I.4', nhom: 'Hệ thống', cn: 'Validate file upload không phải PNG', pre: 'Có file JPG/PDF', thao: 'Chọn file non-PNG', ky: 'Hiển thị lỗi "Chỉ chấp nhận file PNG", file bị reject', auto: '✅ Pass', note: '' },
  { id: 'TC-009', muc: 'I.4', nhom: 'Hệ thống', cn: 'Validate file > 2MB', pre: 'Có file PNG > 2MB', thao: 'Chọn file > 2MB', ky: 'Hiển thị lỗi "Kích thước ảnh tối đa 2MB"', auto: '✅ Pass', note: '' },
  { id: 'TC-010', muc: 'I.4', nhom: 'Hệ thống', cn: 'Disable nút Lưu khi không có thay đổi', pre: 'Đã có chữ ký + số ĐT', thao: 'Mở tab Chữ ký số, không đổi gì', ky: 'Nút Lưu bị disable (màu xám)', auto: '✅ Pass', note: 'Fix 085c9c1' },
  { id: 'TC-011', muc: 'I.5', nhom: 'Hệ thống', cn: 'Ký số sử dụng SmartCA VNPT', pre: 'Đã cấu hình SmartCA + có VB cần ký', thao: 'Vào VB → click Ký số → nhập OTP', ky: 'VB được ký số, hiển thị chữ ký trên PDF', auto: '✅ Pass', note: 'Mock OTP flow — TODO tích hợp VNPT SmartCA SDK thực ở Phase 2' },

  // ═══════════════ II.1 VĂN BẢN ĐẾN (16) ═══════════════
  { id: 'TC-012', muc: 'II.1.1', nhom: 'VB đến', cn: 'Thêm mới VB đến', pre: 'Có sổ VB + quyền tạo', thao: 'Mở /van-ban-den → Thêm mới → điền form → Xác nhận', ky: 'VB xuất hiện trong danh sách, status=pending', auto: '✅ Pass', note: 'POST /van-ban-den' },
  { id: 'TC-013', muc: 'II.1.1', nhom: 'VB đến', cn: 'Thêm mới VB + Duyệt luôn', pre: 'Có quyền duyệt', thao: 'Form thêm mới → click "Xác nhận và duyệt"', ky: 'VB thêm + duyệt trong 1 bước, status=approved', auto: '✅ Pass', note: '' },
  { id: 'TC-014', muc: 'II.1.1', nhom: 'VB đến', cn: 'Thêm VB thiếu field bắt buộc', pre: '', thao: 'Bỏ trống trích yếu nội dung → Xác nhận', ky: 'Hiển thị lỗi inline "Trích yếu nội dung là bắt buộc"', auto: '✅ Pass', note: '' },
  { id: 'TC-015', muc: 'II.1.2', nhom: 'VB đến', cn: 'Xem chi tiết VB đến', pre: 'Có VB trong DB', thao: 'Click dòng VB / vào /van-ban-den/[id]', ky: 'Hiển thị chi tiết đầy đủ + history + attachments', auto: '✅ Pass', note: '' },
  { id: 'TC-016', muc: 'II.1.3', nhom: 'VB đến', cn: 'Sửa VB đến', pre: 'VB chưa duyệt', thao: 'Action Sửa → cập nhật trích yếu → Xác nhận', ky: 'VB update, refresh thấy giá trị mới', auto: '✅ Pass', note: 'PUT /van-ban-den/:id' },
  { id: 'TC-017', muc: 'II.1.4', nhom: 'VB đến', cn: 'Xóa VB đến', pre: 'VB chưa duyệt, có quyền xóa', thao: 'Action Xóa → confirm', ky: 'VB biến khỏi danh sách, lưu log xóa', auto: '✅ Pass', note: 'DELETE /van-ban-den/:id' },
  { id: 'TC-018', muc: 'II.1.5', nhom: 'VB đến', cn: 'Nhận bản giấy', pre: 'VB đến có loại cần bản giấy', thao: 'Chọn VB → click Nhận bản giấy', ky: 'Message success, flag nhận bản giấy được set', auto: '✅ Pass', note: 'PATCH /van-ban-den/:id/nhan-ban-giay' },
  { id: 'TC-019', muc: 'II.1.6', nhom: 'VB đến', cn: 'Duyệt VB đến', pre: 'VB status=pending, có quyền duyệt', thao: 'Chọn VB → click Duyệt', ky: 'Status → approved, hiển thị message success', auto: '✅ Pass', note: 'PATCH /van-ban-den/:id/duyet' },
  { id: 'TC-020', muc: 'II.1.7', nhom: 'VB đến', cn: 'Hủy duyệt VB', pre: 'VB đã duyệt', thao: 'Chọn VB đã duyệt → Hủy duyệt → confirm', ky: 'Status trở về pending', auto: '✅ Pass', note: 'PATCH /van-ban-den/:id/huy-duyet' },
  { id: 'TC-021', muc: 'II.1.8', nhom: 'VB đến', cn: 'Bút phê VB đến', pre: 'VB đã duyệt', thao: 'Chọn VB → Bút phê → nhập ý kiến + hạn giải quyết → Xác nhận', ky: 'Lưu bút phê thành công, hiển thị trong tab lịch sử', auto: '✅ Pass', note: 'POST /van-ban-den/:id/but-phe' },
  { id: 'TC-022', muc: 'II.1.8', nhom: 'VB đến', cn: 'Bút phê + Phân công giải quyết', pre: 'VB đã duyệt, có user xử lý', thao: 'Bút phê → chọn người giải quyết → Xác nhận và phân công', ky: 'Bút phê lưu + giao việc tự động cho user chọn', auto: '✅ Pass', note: '' },
  { id: 'TC-023', muc: 'II.1.9', nhom: 'VB đến', cn: 'Thêm VB vào HSCV', pre: 'Có HSCV active + VB', thao: 'Chọn VB → Thêm vào HSCV → tick HSCV → Lưu', ky: 'VB xuất hiện trong HSCV, message success', auto: '✅ Pass', note: 'POST /van-ban-den/:id/them-vao-hscv' },
  { id: 'TC-024', muc: 'II.1.10', nhom: 'VB đến', cn: 'Giao việc', pre: 'VB đã duyệt', thao: 'Chọn VB → Giao việc → chọn người + nhập nội dung → Xác nhận', ky: 'Task giao việc xuất hiện cho user được chọn', auto: '✅ Pass', note: 'POST /van-ban-den/:id/giao-viec' },
  { id: 'TC-025', muc: 'II.1.11', nhom: 'VB đến', cn: 'Gửi VB cho user', pre: 'VB đã duyệt', thao: 'Chọn VB → Gửi → tick danh sách user → Xác nhận', ky: 'Message success, các user được gửi nhận notification', auto: '✅ Pass', note: 'POST /van-ban-den/:id/gui' },
  { id: 'TC-026', muc: 'II.1.12', nhom: 'VB đến', cn: 'Đánh dấu cá nhân', pre: 'Đã đăng nhập', thao: 'Chọn VB → Đánh dấu cá nhân → nhập ghi chú → Xác nhận', ky: 'Ghi chú cá nhân được lưu, hiển thị icon đánh dấu', auto: '✅ Pass', note: 'POST /van-ban-den/:id/danh-dau' },
  { id: 'TC-027', muc: 'II.1.13', nhom: 'VB đến', cn: 'Chuyển lưu trữ', pre: 'VB đã xử lý xong', thao: 'Chọn VB → Chuyển lưu trữ → nhập thông tin → Chuyển', ky: 'VB chuyển sang trạng thái lưu trữ', auto: '✅ Pass', note: 'POST /van-ban-den/:id/chuyen-luu-tru' },
  { id: 'TC-028', muc: 'II.1.14', nhom: 'VB đến', cn: 'In danh sách VB đến', pre: 'Có VB trong danh sách', thao: 'Vào trang danh sách → click In danh sách / Xuất Excel → Ctrl+P', ky: 'File Excel download / In print preview ra đúng data', auto: '✅ Pass', note: '' },
  { id: 'TC-029', muc: 'II.1.15', nhom: 'VB đến', cn: 'Tìm kiếm VB đến', pre: 'Có VB', thao: 'Nhập keyword vào ô tìm + chọn filter (sổ, loại, ngày)', ky: 'Danh sách lọc đúng theo tiêu chí', auto: '✅ Pass', note: '' },
  { id: 'TC-030', muc: 'II.1', nhom: 'VB đến', cn: 'Gửi VB liên thông (LGSP)', pre: 'VB đã duyệt + có LGSP config', thao: 'Chọn VB → Gửi liên thông → chọn cơ quan → Xác nhận', ky: 'VB gửi qua trục LGSP', auto: '✅ Pass', note: 'Bonus — không có trong HDSD' },

  // ═══════════════ II.2 VĂN BẢN DỰ THẢO (7) ═══════════════
  { id: 'TC-031', muc: 'II.2.1', nhom: 'VB dự thảo', cn: 'Thêm mới VB dự thảo', pre: 'Có quyền tạo', thao: 'Mở /van-ban-du-thao → Thêm mới → điền form → Xác nhận', ky: 'VB dự thảo xuất hiện, status=draft', auto: '✅ Pass', note: '' },
  { id: 'TC-032', muc: 'II.2.2', nhom: 'VB dự thảo', cn: 'In danh sách VB dự thảo', pre: 'Có VB dự thảo', thao: 'Click In danh sách / Xuất Excel', ky: 'File xuất ra đúng data', auto: '✅ Pass', note: '' },
  { id: 'TC-033', muc: 'II.2.3', nhom: 'VB dự thảo', cn: 'Xem chi tiết VB dự thảo', pre: 'Có VB dự thảo', thao: 'Click dòng VB / vào /van-ban-du-thao/[id]', ky: 'Hiển thị chi tiết + attachments', auto: '✅ Pass', note: '' },
  { id: 'TC-034', muc: 'II.2.4', nhom: 'VB dự thảo', cn: 'Phát hành VB dự thảo', pre: 'VB dự thảo đã duyệt', thao: 'Chọn VB → Phát hành → Xác nhận', ky: 'VB chuyển sang danh sách VB đi, status=published', auto: '✅ Pass', note: 'POST /van-ban-du-thao/:id/phat-hanh' },
  { id: 'TC-035', muc: 'II.2.5', nhom: 'VB dự thảo', cn: 'Xóa VB dự thảo', pre: 'Chưa phát hành', thao: 'Action Xóa → confirm', ky: 'VB biến khỏi danh sách', auto: '✅ Pass', note: '' },
  { id: 'TC-036', muc: 'II.2.6', nhom: 'VB dự thảo', cn: 'Sửa VB dự thảo', pre: 'Chưa phát hành', thao: 'Action Sửa → chỉnh thông tin → Xác nhận', ky: 'VB update', auto: '✅ Pass', note: '' },
  { id: 'TC-037', muc: 'II.2.7', nhom: 'VB dự thảo', cn: 'Gửi VB dự thảo (review)', pre: 'Có user review', thao: 'Chọn VB → Gửi → chọn user', ky: 'User nhận được notification review', auto: '✅ Pass', note: '' },

  // ═══════════════ II.3 VĂN BẢN ĐI / PHÁT HÀNH (13) ═══════════════
  { id: 'TC-038', muc: 'II.3.1', nhom: 'VB đi', cn: 'Thêm mới VB đi', pre: 'Có sổ VB + user ký', thao: 'Mở /van-ban-di → Thêm mới → điền form → Xác nhận', ky: 'VB đi xuất hiện trong danh sách', auto: '✅ Pass', note: '' },
  { id: 'TC-039', muc: 'II.3.2', nhom: 'VB đi', cn: 'In danh sách VB đi', pre: 'Có VB đi', thao: 'Click In danh sách / Xuất Excel', ky: 'File xuất ra đúng data', auto: '✅ Pass', note: '' },
  { id: 'TC-040', muc: 'II.3.3', nhom: 'VB đi', cn: 'Xem chi tiết VB đi', pre: 'Có VB đi', thao: 'Click dòng VB / vào /van-ban-di/[id]', ky: 'Hiển thị chi tiết đầy đủ', auto: '✅ Pass', note: '' },
  { id: 'TC-041', muc: 'II.3.4', nhom: 'VB đi', cn: 'Xóa VB đi', pre: 'Chưa gửi', thao: 'Action Xóa → confirm', ky: 'VB biến khỏi danh sách', auto: '✅ Pass', note: '' },
  { id: 'TC-042', muc: 'II.3.5', nhom: 'VB đi', cn: 'Sửa VB đi', pre: 'Chưa gửi', thao: 'Action Sửa → chỉnh → Xác nhận', ky: 'VB update', auto: '✅ Pass', note: '' },
  { id: 'TC-043', muc: 'II.3.6', nhom: 'VB đi', cn: 'Gửi VB đi cho user', pre: 'VB đã duyệt', thao: 'Chọn VB → Gửi → chọn user', ky: 'Message success', auto: '✅ Pass', note: '' },
  { id: 'TC-044', muc: 'II.3.7', nhom: 'VB đi', cn: 'Gửi trục liên thông (LGSP)', pre: 'LGSP config OK', thao: 'Chọn VB → Gửi liên thông → chọn cơ quan → Xác nhận', ky: 'VB gửi qua LGSP', auto: '✅ Pass', note: '' },
  { id: 'TC-045', muc: 'II.3.8', nhom: 'VB đi', cn: 'Gửi trục CP (Chính phủ)', pre: 'Có config trục CP', thao: 'Chọn VB → Gửi trục CP', ky: 'VB gửi qua trục CP', auto: '✅ Pass', note: 'Mock trục CP — TODO tích hợp thực Phase 2' },
  { id: 'TC-046', muc: 'II.3.9', nhom: 'VB đi', cn: 'Chuyển lưu trữ VB đi', pre: 'VB đã gửi', thao: 'Chọn VB → Chuyển lưu trữ → Xác nhận', ky: 'VB chuyển sang trạng thái lưu trữ', auto: '✅ Pass', note: 'Form đầy đủ với Phòng/Kho lưu trữ' },
  { id: 'TC-047', muc: 'II.3.10', nhom: 'VB đi', cn: 'Giao việc từ VB đi', pre: 'VB đi đã duyệt', thao: 'Chọn VB → Giao việc → chọn người', ky: 'Task giao việc xuất hiện', auto: '✅ Pass', note: '' },
  { id: 'TC-048', muc: 'II.3.11', nhom: 'VB đi', cn: 'Thêm VB đi vào HSCV', pre: 'Có HSCV active', thao: 'Chọn VB → Thêm vào HSCV → tick HSCV → Lưu', ky: 'VB vào HSCV', auto: '✅ Pass', note: '' },
  { id: 'TC-049', muc: 'II.3.12', nhom: 'VB đi', cn: 'Đánh dấu cá nhân VB đi', pre: 'Đã đăng nhập', thao: 'Chọn VB → Đánh dấu cá nhân → nhập ghi chú', ky: 'Ghi chú lưu thành công', auto: '✅ Pass', note: '' },
  { id: 'TC-050', muc: 'II.3.13', nhom: 'VB đi', cn: 'Hủy duyệt VB đi', pre: 'VB đã duyệt', thao: 'Chọn VB → Hủy duyệt → confirm', ky: 'Status về pending', auto: '✅ Pass', note: '' },

  // ═══════════════ II.4 VĂN BẢN LIÊN THÔNG (5) ═══════════════
  { id: 'TC-051', muc: 'II.4.1', nhom: 'VB liên thông', cn: 'Chuyển về VB đến', pre: 'VB liên thông status=received', thao: 'Chọn VB → Chuyển về VB đến', ky: 'Tạo VB đến mới, VB liên thông đánh dấu đã chuyển', auto: '✅ Pass', note: '' },
  { id: 'TC-052', muc: 'II.4.2', nhom: 'VB liên thông', cn: 'Tiếp nhận VB liên thông', pre: 'VB chưa tiếp nhận', thao: 'Chọn VB → Tiếp nhận', ky: 'Status đổi sang received', auto: '✅ Pass', note: '' },
  { id: 'TC-053', muc: 'II.4.3', nhom: 'VB liên thông', cn: 'Từ chối VB liên thông', pre: 'VB chưa tiếp nhận', thao: 'Chọn VB → Từ chối → nhập lý do → Xác nhận', ky: 'VB chuyển về cơ quan gửi kèm lý do', auto: '✅ Pass', note: '' },
  { id: 'TC-054', muc: 'II.4.4', nhom: 'VB liên thông', cn: 'Xem chi tiết VB liên thông', pre: 'Có VB', thao: 'Click vào dòng VB', ky: 'Hiển thị chi tiết + status đúng', auto: '✅ Pass', note: '' },
  { id: 'TC-055', muc: 'II.4.5', nhom: 'VB liên thông', cn: 'Đồng ý thu hồi', pre: 'VB status=recall_requested', thao: 'Vào detail → click "Đồng ý thu hồi" → confirm', ky: 'Status → recalled, VB đến liên kết soft-delete', auto: '✅ Pass', note: 'Vừa implement quick-260418-hlj' },
  { id: 'TC-056', muc: 'II.4.5', nhom: 'VB liên thông', cn: 'Từ chối thu hồi', pre: 'VB status=recall_requested', thao: 'Detail → "Từ chối thu hồi" → nhập lý do → Xác nhận', ky: 'Status restore về trước recall, lưu lý do từ chối', auto: '✅ Pass', note: 'Vừa implement quick-260418-hlj' },

  // ═══════════════ III.1 TOÀN BỘ HSCV (5) ═══════════════
  { id: 'TC-057', muc: 'III.1.1', nhom: 'HSCV', cn: 'Xem danh sách toàn bộ HSCV', pre: 'Đã đăng nhập', thao: 'Mở /ho-so-cong-viec', ky: 'Hiển thị danh sách với filter theo status/keyword/ngày', auto: '✅ Pass', note: '' },
  { id: 'TC-058', muc: 'III.1.2', nhom: 'HSCV', cn: 'Thêm mới HSCV', pre: 'Có quyền tạo', thao: 'Click Thêm → điền form (tên, loại VB, hạn, người phụ trách) → Xác nhận', ky: 'HSCV xuất hiện trong danh sách', auto: '✅ Pass', note: '' },
  { id: 'TC-059', muc: 'III.1.3', nhom: 'HSCV', cn: 'Mở lại HSCV đã hoàn thành', pre: 'HSCV status=4', thao: 'Vào detail → click Mở lại → confirm', ky: 'Status → 1 (đang xử lý), progress giữ 100', auto: '✅ Pass', note: 'Vừa implement quick-260418-hlj' },
  { id: 'TC-060', muc: 'III.1.4', nhom: 'HSCV', cn: 'Đánh dấu cá nhân HSCV', pre: 'Có HSCV', thao: 'Nhập ghi chú cá nhân → Lưu', ky: 'Ghi chú lưu thành công', auto: '✅ Pass', note: 'Field "note" trên form HSCV' },
  { id: 'TC-061', muc: 'III.1.5', nhom: 'HSCV', cn: 'Thêm cán bộ vào HSCV', pre: 'Có HSCV + user khả dụng', thao: 'Vào tab Phân công → chọn phòng ban → chọn user → Lưu', ky: 'Cán bộ được thêm vào danh sách HSCV', auto: '✅ Pass', note: '' },

  // ═══════════════ III.2 HSCV CHƯA XỬ LÝ (7) ═══════════════
  { id: 'TC-062', muc: 'III.2.1', nhom: 'HSCV', cn: 'Xem HSCV chưa xử lý – phụ trách', pre: 'Có HSCV user đang phụ trách', thao: 'Mở /ho-so-cong-viec → tab Chưa XL phụ trách', ky: 'Danh sách HSCV user đang phụ trách hiện ra', auto: '✅ Pass', note: '' },
  { id: 'TC-063', muc: 'III.2.2', nhom: 'HSCV', cn: 'Thêm HSCV từ tab chưa xử lý', pre: '', thao: 'Click Thêm → điền form → Xác nhận', ky: 'HSCV mới tạo, user là người phụ trách', auto: '✅ Pass', note: '' },
  { id: 'TC-064', muc: 'III.2.3', nhom: 'HSCV', cn: 'Trình ký HSCV', pre: 'HSCV status=1', thao: 'Detail → click Trình ký → chọn lãnh đạo → Xác nhận', ky: 'HSCV chuyển sang status trình ký', auto: '✅ Pass', note: '' },
  { id: 'TC-065', muc: 'III.2.4', nhom: 'HSCV', cn: 'Lấy số HSCV', pre: 'HSCV status=1/3, chưa có số', thao: 'Detail → Lấy số → chọn sổ văn bản → Xác nhận', ky: 'Số cấp thành công, hiển thị số mới', auto: '✅ Pass', note: 'Vừa implement quick-260418-hlj (reset theo năm)' },
  { id: 'TC-066', muc: 'III.2.5', nhom: 'HSCV', cn: 'Hủy HSCV', pre: 'HSCV đang xử lý', thao: 'Detail → Hủy HSCV → confirm', ky: 'HSCV chuyển status -3 (hủy)', auto: '✅ Pass', note: 'Action hủy HSCV riêng với lý do' },
  { id: 'TC-067', muc: 'III.2.6', nhom: 'HSCV', cn: 'Lưu / Gửi / Chuyển tiếp ý kiến', pre: 'HSCV đang xử lý', thao: 'Detail → tab Ý kiến → chọn 1 trong 3 action → nhập nội dung → Xác nhận', ky: 'Ý kiến lưu + gửi thành công', auto: '✅ Pass', note: 'Chuyển tiếp ý kiến cho user review' },
  { id: 'TC-068', muc: 'III.2', nhom: 'HSCV', cn: 'Chuyển tiếp HSCV cho người khác', pre: 'HSCV đang phụ trách', thao: 'Chuyển tiếp HSCV sang user khác xử lý', ky: 'Người mới trở thành phụ trách', auto: '✅ Pass', note: 'Transfer ownership HSCV (same unit)' },

  // ═══════════════ III.3 CẤU HÌNH NGOẠI GIAO (1) ═══════════════
  { id: 'TC-069', muc: 'III.3.1', nhom: 'HSCV', cn: 'Cấu hình ngoại giao / gửi nhanh', pre: 'Admin', thao: 'Mở /cau-hinh-gui-nhanh → chọn user vào danh sách quick-recipient → Lưu', ky: 'Danh sách user lưu, khi gửi VB tự tick sẵn', auto: '🚫 Hidden', note: 'Ẩn Phase 1 — flag off. Code còn, chờ Phase 2 bật' },

  // ═══════════════ III.4 KIỂM SOÁT CÔNG VIỆC (2) ═══════════════
  { id: 'TC-070', muc: 'III.4.1', nhom: 'HSCV', cn: 'Giao diện tổng quan công việc', pre: 'Admin/Lãnh đạo', thao: 'Mở Dashboard / Kiểm soát công việc', ky: 'Dashboard tổng quan HSCV hiển thị KPI + chart', auto: '✅ Pass', note: 'Gộp vào /dashboard chung — thống nhất với user' },
  { id: 'TC-071', muc: 'III.4.2', nhom: 'HSCV', cn: 'Thống kê công việc theo đơn vị', pre: 'Admin/Lãnh đạo', thao: 'Mở /ho-so-cong-viec/bao-cao', ky: 'Báo cáo thống kê theo đơn vị/cán bộ + charts', auto: '✅ Pass', note: '' },

  // ═══════════════ IV.1 QUẢN LÝ NGƯỜI DÙNG (10) ═══════════════
  { id: 'TC-072', muc: 'IV.1.1', nhom: 'Quản trị', cn: 'Danh sách phòng ban - người dùng', pre: 'Admin', thao: 'Mở /quan-tri/nguoi-dung', ky: 'Tree phòng ban bên trái + table người dùng bên phải', auto: '✅ Pass', note: '' },
  { id: 'TC-073', muc: 'IV.1.2', nhom: 'Quản trị', cn: 'Thêm mới đơn vị/phòng ban', pre: 'Admin', thao: '/quan-tri/don-vi → Thêm → điền name/code/parent → Lưu', ky: 'Phòng ban xuất hiện trong tree', auto: '✅ Pass', note: '' },
  { id: 'TC-074', muc: 'IV.1.3', nhom: 'Quản trị', cn: 'Thêm mới người dùng', pre: 'Admin, có phòng ban', thao: 'Chọn phòng ban → Thêm người dùng → điền form → Lưu', ky: 'User tạo thành công, password mặc định Admin@123', auto: '✅ Pass', note: '' },
  { id: 'TC-075', muc: 'IV.1.4', nhom: 'Quản trị', cn: 'Cập nhật thông tin phòng ban', pre: 'Có phòng ban', thao: 'Chọn phòng ban → Sửa → update thông tin → Lưu', ky: 'Phòng ban update', auto: '✅ Pass', note: '' },
  { id: 'TC-076', muc: 'IV.1.5', nhom: 'Quản trị', cn: 'Cập nhật thông tin người dùng', pre: 'Có user', thao: 'Chọn user → Sửa → update → Lưu', ky: 'User info update', auto: '✅ Pass', note: 'Không update username/password từ endpoint này' },
  { id: 'TC-077', muc: 'IV.1.6', nhom: 'Quản trị', cn: 'Xóa phòng ban', pre: 'Phòng ban không có user/child', thao: 'Chọn phòng ban → Xóa → confirm', ky: 'Phòng ban xóa khỏi tree', auto: '✅ Pass', note: 'Check constraint trước xóa' },
  { id: 'TC-078', muc: 'IV.1.7', nhom: 'Quản trị', cn: 'Xóa người dùng', pre: 'User không đang phụ trách task', thao: 'Chọn user → Xóa → confirm', ky: 'User soft-delete', auto: '✅ Pass', note: '' },
  { id: 'TC-079', muc: 'IV.1.8', nhom: 'Quản trị', cn: 'Giới hạn quyền cho đơn vị', pre: 'Admin', thao: 'Chọn đơn vị → Giới hạn quyền → chọn rights → Lưu', ky: 'Quyền tối đa cho đơn vị set, user trong đơn vị không vượt quyền', auto: '❌ Missing', note: 'Defer Phase 2 — cần schema permission model mới' },
  { id: 'TC-080', muc: 'IV.1.9', nhom: 'Quản trị', cn: 'Phân quyền người dùng', pre: 'Có user + role', thao: 'Chọn user → Phân quyền → tick nhóm quyền → Lưu', ky: 'User được gán role', auto: '✅ Pass', note: '' },
  { id: 'TC-081', muc: 'IV.1.10', nhom: 'Quản trị', cn: 'Đặt lại mật khẩu người dùng', pre: 'Admin', thao: 'Chọn user → Đặt lại mật khẩu → confirm', ky: 'Password reset về Admin@123', auto: '✅ Pass', note: '' },

  // ═══════════════ IV.2 NHÓM QUYỀN (5) ═══════════════
  { id: 'TC-082', muc: 'IV.2.1', nhom: 'Quản trị', cn: 'Danh sách nhóm quyền', pre: 'Admin', thao: 'Mở /quan-tri/nhom-quyen', ky: 'Table nhóm quyền với staff_count', auto: '✅ Pass', note: '' },
  { id: 'TC-083', muc: 'IV.2.2', nhom: 'Quản trị', cn: 'Thêm mới nhóm quyền', pre: 'Admin', thao: 'Thêm → nhập tên + mô tả + rights → Lưu', ky: 'Nhóm quyền xuất hiện', auto: '✅ Pass', note: '' },
  { id: 'TC-084', muc: 'IV.2.3', nhom: 'Quản trị', cn: 'Xem danh sách user trong nhóm', pre: 'Nhóm có user', thao: 'Chọn nhóm → Xem danh sách user', ky: 'Hiển thị danh sách user thuộc nhóm', auto: '✅ Pass', note: '' },
  { id: 'TC-085', muc: 'IV.2.4', nhom: 'Quản trị', cn: 'Sửa nhóm quyền', pre: 'Có nhóm', thao: 'Chọn nhóm → Sửa → update tên/rights → Lưu', ky: 'Nhóm update', auto: '✅ Pass', note: '' },
  { id: 'TC-086', muc: 'IV.2.5', nhom: 'Quản trị', cn: 'Xóa nhóm quyền', pre: 'Nhóm không còn user assign', thao: 'Chọn nhóm → Xóa → confirm', ky: 'Nhóm xóa khỏi danh sách', auto: '✅ Pass', note: 'Check constraint' },

  // ═══════════════ IV.3 LĨNH VỰC (3) ═══════════════
  { id: 'TC-087', muc: 'IV.3.1', nhom: 'Quản trị', cn: 'Thêm lĩnh vực', pre: 'Admin', thao: 'Mở /quan-tri/linh-vuc → Thêm → code + name → Lưu', ky: 'Lĩnh vực xuất hiện', auto: '✅ Pass', note: '' },
  { id: 'TC-088', muc: 'IV.3.2', nhom: 'Quản trị', cn: 'Sửa lĩnh vực', pre: 'Có lĩnh vực', thao: 'Chọn → Sửa → update → Lưu', ky: 'Update thành công', auto: '✅ Pass', note: '' },
  { id: 'TC-089', muc: 'IV.3.3', nhom: 'Quản trị', cn: 'Xóa lĩnh vực', pre: 'Không còn VB tham chiếu', thao: 'Chọn → Xóa → confirm', ky: 'Xóa thành công', auto: '✅ Pass', note: '' },

  // ═══════════════ IV.4 CHỨC VỤ (3) ═══════════════
  { id: 'TC-090', muc: 'IV.4.1', nhom: 'Quản trị', cn: 'Thêm chức vụ', pre: 'Admin', thao: 'Mở /quan-tri/chuc-vu → Thêm → name + flags (is_leader, is_handle_document) → Lưu', ky: 'Chức vụ xuất hiện', auto: '✅ Pass', note: '' },
  { id: 'TC-091', muc: 'IV.4.2', nhom: 'Quản trị', cn: 'Sửa chức vụ', pre: 'Có chức vụ', thao: 'Chọn → Sửa → update → Lưu', ky: 'Update thành công', auto: '✅ Pass', note: '' },
  { id: 'TC-092', muc: 'IV.4.3', nhom: 'Quản trị', cn: 'Xóa chức vụ', pre: 'Không còn user tham chiếu', thao: 'Chọn → Xóa → confirm', ky: 'Xóa thành công', auto: '✅ Pass', note: 'Check constraint' },
];

// ─── Markdown ────────────────────────────────────────────────────────────────
function generateMarkdown() {
  const lines = [];
  lines.push('# Danh sách test cases theo HDSD cũ');
  lines.push('');
  lines.push('**Nguồn:** `docs/hdsd_cu.docx` — hệ thống .NET cũ');
  lines.push(`**Generated:** ${new Date().toISOString().slice(0, 10)}`);
  lines.push(`**Tổng số case:** ${cases.length}`);
  lines.push('');
  lines.push('## Quy ước cột Auto-check');
  lines.push('');
  lines.push('| Ký hiệu | Ý nghĩa |');
  lines.push('|---|---|');
  lines.push('| ✅ Pass | Code + UI có đủ (đã verify audit) |');
  lines.push('| ⚠️ Partial | Có một phần, cần bổ sung |');
  lines.push('| ❌ Missing | Chưa implement |');
  lines.push('| 🚫 Hidden | Ẩn Phase 1, code còn (chờ Phase 2) |');
  lines.push('');
  lines.push('## Thống kê theo status');
  lines.push('');
  const stats = cases.reduce((acc, c) => {
    const key = c.auto.split(' ')[0]; // emoji only
    acc[key] = (acc[key] || 0) + 1;
    return acc;
  }, {});
  lines.push('| Status | Count | % |');
  lines.push('|---|---|---|');
  for (const [k, v] of Object.entries(stats)) {
    lines.push(`| ${k} | ${v} | ${((v / cases.length) * 100).toFixed(1)}% |`);
  }
  lines.push('');
  lines.push('## Danh sách chi tiết');
  lines.push('');
  lines.push('| Mã TC | Mục HDSD | Nhóm | Chức năng | Tiền điều kiện | Thao tác | Kỳ vọng | Auto-check | UAT thực tế | Ghi chú |');
  lines.push('|---|---|---|---|---|---|---|---|---|---|');
  for (const c of cases) {
    const escape = (s) => String(s || '').replace(/\|/g, '\\|').replace(/\n/g, ' ');
    lines.push(`| ${c.id} | ${c.muc} | ${c.nhom} | ${escape(c.cn)} | ${escape(c.pre)} | ${escape(c.thao)} | ${escape(c.ky)} | ${c.auto} |  | ${escape(c.note)} |`);
  }
  return lines.join('\n');
}

// ─── Excel ───────────────────────────────────────────────────────────────────
async function generateExcel(outPath) {
  const wb = new ExcelJS.Workbook();
  wb.creator = 'QLVB auto-generate';
  wb.created = new Date();

  const ws = wb.addWorksheet('Test cases', {
    views: [{ state: 'frozen', ySplit: 1 }],
  });

  ws.columns = [
    { header: 'Mã TC', key: 'id', width: 10 },
    { header: 'Mục HDSD', key: 'muc', width: 10 },
    { header: 'Nhóm', key: 'nhom', width: 14 },
    { header: 'Chức năng', key: 'cn', width: 32 },
    { header: 'Tiền điều kiện', key: 'pre', width: 30 },
    { header: 'Thao tác', key: 'thao', width: 50 },
    { header: 'Kỳ vọng', key: 'ky', width: 45 },
    { header: 'Auto-check', key: 'auto', width: 14 },
    { header: 'UAT thực tế', key: 'uat', width: 14 },
    { header: 'Ghi chú', key: 'note', width: 40 },
  ];

  // Header style
  ws.getRow(1).eachCell((cell) => {
    cell.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1B3A5C' } };
    cell.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
    cell.border = { top: { style: 'thin' }, bottom: { style: 'thin' }, left: { style: 'thin' }, right: { style: 'thin' } };
  });
  ws.getRow(1).height = 32;

  // Data rows with color coding by Auto-check
  const autoColors = {
    '✅': 'FFD1FAE5', // green-100
    '⚠️': 'FFFEF3C7', // yellow-100
    '❌': 'FFFEE2E2', // red-100
    '🚫': 'FFE5E7EB', // gray-200
  };

  cases.forEach((c) => {
    const row = ws.addRow({
      id: c.id,
      muc: c.muc,
      nhom: c.nhom,
      cn: c.cn,
      pre: c.pre,
      thao: c.thao,
      ky: c.ky,
      auto: c.auto,
      uat: '',
      note: c.note,
    });
    const emoji = c.auto.split(' ')[0];
    const color = autoColors[emoji];
    row.eachCell((cell) => {
      cell.alignment = { vertical: 'top', wrapText: true };
      cell.border = { top: { style: 'thin', color: { argb: 'FFE5E7EB' } }, bottom: { style: 'thin', color: { argb: 'FFE5E7EB' } }, left: { style: 'thin', color: { argb: 'FFE5E7EB' } }, right: { style: 'thin', color: { argb: 'FFE5E7EB' } } };
    });
    if (color) {
      // Color Auto-check column only
      row.getCell('auto').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: color } };
      row.getCell('auto').font = { bold: true };
    }
  });

  // AutoFilter
  ws.autoFilter = { from: 'A1', to: `J${cases.length + 1}` };

  await wb.xlsx.writeFile(outPath);
}

// ─── Main ────────────────────────────────────────────────────────────────────
(async () => {
  const projectRoot = path.resolve(__dirname, '../../..');
  const mdPath = path.join(projectRoot, 'docs', 'test_theo_hdsd_cu.md');
  const xlsxPath = path.join(projectRoot, 'docs', 'test_theo_hdsd_cu.xlsx');

  fs.writeFileSync(mdPath, generateMarkdown(), 'utf-8');
  console.log(`✓ Markdown written: ${mdPath}`);

  await generateExcel(xlsxPath);
  console.log(`✓ Excel written:    ${xlsxPath}`);

  console.log(`\nTotal: ${cases.length} test cases`);
})();
