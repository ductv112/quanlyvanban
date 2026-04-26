# Tài khoản ký số cá nhân

## 1. Giới thiệu

Trang Tài khoản ký số cá nhân là nơi mỗi cán bộ khai báo thông tin định danh ký số của mình theo nhà cung cấp đang được hệ thống sử dụng. Sau khi khai báo, hệ thống xác thực tài khoản với nhà cung cấp để lưu lại thông tin chứng thư số. Khi đã xác thực xong, cán bộ mới ký được tài liệu PDF trong các module Văn bản đi, Dự thảo và Hồ sơ công việc.

Hệ thống hỗ trợ hai nhà cung cấp do quản trị cấu hình ở module Cấu hình ký số hệ thống:

- SmartCA VNPT — yêu cầu Mã định danh SmartCA (số CMND/CCCD hoặc mã đã đăng ký).
- MySign Viettel — yêu cầu Mã định danh MySign + chọn chứng thư số trong danh sách lấy từ Viettel.

Mỗi cán bộ chỉ có một cấu hình duy nhất tương ứng với nhà cung cấp đang hoạt động. Khi quản trị đổi nhà cung cấp, hệ thống nhắc cán bộ cấu hình lại theo nhà cung cấp mới.

## 2. Quy trình thao tác và ràng buộc nghiệp vụ

Quy trình chuẩn:

1. Mở trang Tài khoản ký số cá nhân.
2. Nếu hệ thống chưa kích hoạt nhà cung cấp — trang hiển thị banner cảnh báo và nút Làm mới. Cán bộ liên hệ quản trị.
3. Khi đã có nhà cung cấp hoạt động — trang hiển thị banner xanh kèm tên nhà cung cấp và Base URL.
4. Nhập Mã định danh theo nhà cung cấp đang dùng.
5. Riêng MySign Viettel: bấm Tải danh sách chứng thư từ MySign — hệ thống gọi API Viettel để lấy danh sách chứng thư của mã định danh, sau đó chọn 1 chứng thư.
6. Bấm Lưu cấu hình — thông tin được lưu lại nhưng chưa được xác thực.
7. Bấm Xác thực tài khoản ký số — hệ thống gọi API nhà cung cấp để kiểm tra mã định danh và lưu thông tin chứng thư (chủ thể, số serial). Khi thành công, nhãn trạng thái đổi thành Đã xác thực.

Ràng buộc nghiệp vụ:

- Mã định danh bắt buộc, tối đa 200 ký tự.
- Với MySign Viettel: phải chọn chứng thư số trong danh sách trước khi Lưu.
- Phải Lưu cấu hình trước khi bấm Xác thực.
- Mỗi cán bộ chỉ có một cấu hình; nhập lại Mã định danh sẽ ghi đè cấu hình cũ.
- Khi quản trị đổi nhà cung cấp, cán bộ phải khai báo lại theo nhà cung cấp mới.

## 3. Các màn hình chức năng

### 3.1. Màn hình Tài khoản ký số cá nhân

![Màn hình tài khoản ký số](screenshots/ky_so_tai_khoan_01_main.png)

#### Bố cục màn hình

Từ trên xuống:

- Đầu trang: tiêu đề "Tài khoản ký số cá nhân" và mô tả ngắn.
- Khi hệ thống chưa có nhà cung cấp hoạt động — thẻ Alert vàng "Hệ thống chưa kích hoạt provider ký số" kèm nút Làm mới.
- Khi đã có nhà cung cấp:
  - Banner xanh báo nhà cung cấp đang hoạt động và Base URL, có nút Làm mới.
  - Thẻ "Cấu hình tài khoản" chứa nhãn trạng thái (Đã xác thực / Chưa xác thực) và Form khai báo. Khi đã xác thực, góc phải thẻ hiển thị "Xác thực gần nhất: <thời gian>".

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Làm mới | Banner đầu trang | Luôn hiển thị | Tải lại thông tin nhà cung cấp đang hoạt động và cấu hình của cán bộ. |
| Tải danh sách chứng thư từ MySign | Trong Form | Chỉ với MySign Viettel | Gọi API Viettel để lấy danh sách chứng thư theo Mã định danh đang nhập. |
| Lưu cấu hình | Đáy thẻ cấu hình | Luôn hiển thị | Lưu Mã định danh (và chứng thư đã chọn nếu là MySign). |
| Xác thực tài khoản ký số | Đáy thẻ cấu hình | Vô hiệu khi chưa Lưu cấu hình | Gọi API nhà cung cấp để xác thực, lưu thông tin chứng thư. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Mã định danh | Có | Tên nhãn thay đổi theo nhà cung cấp: "Mã định danh SmartCA" hoặc "Mã định danh MySign". Tối đa 200 ký tự. Có ô tìm kiếm xóa nhanh. |
| Chứng thư số | Có với MySign Viettel | Select danh sách chứng thư đã tải về. Mỗi mục hiển thị `<chủ thể> (hết hạn: <ngày>)`. Vô hiệu khi danh sách trống. |
| Chủ thể chứng thư | (chỉ đọc) | Hiển thị sau khi xác thực, font monospace. |
| Số serial | (chỉ đọc) | Hiển thị sau khi xác thực, font monospace. |

#### Nhãn trạng thái

| Nhãn | Khi nào | Ý nghĩa |
|---|---|---|
| Đã xác thực (xanh) | Sau khi Xác thực thành công | Tài khoản đã sẵn sàng ký số. |
| Chưa xác thực (vàng) | Khi chưa Lưu hoặc xác thực thất bại | Cần hoàn tất xác thực để bật chức năng ký. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải cấu hình thất bại | Không tải được cấu hình |
| Hệ thống chưa kích hoạt nhà cung cấp (banner) | Hệ thống chưa kích hoạt provider ký số. Vui lòng liên hệ Quản trị viên để cấu hình và kích hoạt nhà cung cấp dịch vụ ký số. |
| Bấm Tải danh sách chứng thư khi trống Mã định danh | Vui lòng nhập Mã định danh trước |
| Tải danh sách chứng thư trống | Không tìm thấy chứng thư nào cho mã định danh này |
| Tải danh sách chứng thư thành công | Đã tải <N> chứng thư số |
| Tải danh sách chứng thư thất bại | Không tải được danh sách chứng thư |
| Backend báo lỗi với chi tiết | Không lấy được danh sách chứng thư: <chi tiết> |
| Trống Mã định danh khi Lưu | Vui lòng nhập <tên nhãn> |
| Quá 200 ký tự | Tối đa 200 ký tự |
| Trống chứng thư khi Lưu (MySign) | Vui lòng chọn chứng thư số |
| Lưu thành công | Lưu cấu hình thành công. Vui lòng bấm "Xác thực tài khoản ký số" để kiểm tra. |
| Lưu thất bại | Lưu cấu hình thất bại |
| Backend báo user_id | Vui lòng nhập user_id (không quá 200 ký tự) |
| Bấm Xác thực khi chưa Lưu | Vui lòng lưu cấu hình trước khi kiểm tra |
| Xác thực thành công | Kiểm tra thành công — chứng thư hợp lệ |
| Xác thực thất bại (200 nhưng không hợp lệ) | Kiểm tra thất bại — chứng thư không hợp lệ |
| Xác thực lỗi kết nối | Không kết nối được provider |
