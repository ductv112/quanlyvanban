# Cấu hình ký số hệ thống

## 1. Giới thiệu

Trang Cấu hình ký số hệ thống là nơi quản trị viên khai báo thông tin kết nối tới các nhà cung cấp dịch vụ ký số điện tử và chọn nhà cung cấp đang vận hành cho toàn hệ thống. Hệ thống hỗ trợ cố định hai nhà cung cấp:

- SmartCA VNPT
- MySign Viettel

Cả hai nhà cung cấp được hệ thống tạo sẵn — quản trị viên chỉ cập nhật thông tin kết nối (Base URL, Client ID, Client Secret, Profile ID) và bấm Kích hoạt một nhà cung cấp duy nhất. Khi đổi nhà cung cấp, hệ thống tự động tắt nhà cung cấp đang chạy. Trang chỉ truy cập được khi tài khoản có quyền quản trị.

## 2. Quy trình thao tác và ràng buộc nghiệp vụ

Quy trình chuẩn để bật ký số cho hệ thống:

1. Mở trang Cấu hình ký số hệ thống. Nếu chưa có nhà cung cấp nào hoạt động — banner màu vàng cảnh báo.
2. Bấm Sửa cấu hình ở thẻ nhà cung cấp tương ứng — Drawer mở.
3. Nhập đủ Base URL, Client ID, Client Secret. Riêng MySign Viettel phải nhập thêm Profile ID.
4. Bấm Kiểm tra với secret mới — hệ thống gọi thử API nhà cung cấp với thông tin vừa nhập.
5. Khi kết quả OK — bấm Lưu & Kích hoạt để vừa lưu thông tin vừa đặt nhà cung cấp này làm mặc định.
6. Sau khi kích hoạt — banner đầu trang đổi sang màu xanh, các thẻ thống kê được cập nhật theo nhà cung cấp đang chạy.

Ràng buộc nghiệp vụ:

- Base URL bắt buộc, phải bắt đầu bằng `https://` hoặc `http://localhost` (cho môi trường dev).
- Client ID bắt buộc, tối đa 200 ký tự.
- Client Secret tối thiểu 8 ký tự khi nhập mới; để trống nếu giữ nguyên giá trị cũ.
- Profile ID bắt buộc với MySign Viettel.
- Chỉ có thể bấm Lưu & Kích hoạt sau khi Kiểm tra với secret mới trả về OK.
- Tại mỗi thời điểm chỉ có một nhà cung cấp ở trạng thái đang kích hoạt.
- Hệ thống không cho phép thêm hoặc xóa nhà cung cấp.

## 3. Các màn hình chức năng

### 3.1. Màn hình Cấu hình ký số hệ thống

![Màn hình cấu hình ký số](screenshots/ky_so_cau_hinh_01_main.png)

#### Bố cục màn hình

Từ trên xuống:

- Đầu trang: tiêu đề "Cấu hình ký số hệ thống" và mô tả ngắn.
- Banner trạng thái: nếu đã có nhà cung cấp đang hoạt động — banner xanh báo tên, Base URL và lần kiểm tra gần nhất; nếu chưa có — banner vàng cảnh báo. Banner có nút Làm mới.
- Khu thống kê: thẻ tiêu đề "Thống kê (<tên nhà cung cấp>)", bên trong là 5 thẻ KPI nhỏ.
- Hai thẻ nhà cung cấp đặt cạnh nhau (xếp dọc trên màn hình hẹp), mỗi thẻ chứa thông tin và cụm nút thao tác.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Làm mới | Banner đầu trang | Luôn hiển thị | Tải lại thông tin cấu hình và thống kê. |
| Sửa cấu hình | Đáy thẻ nhà cung cấp | Luôn hiển thị, vô hiệu khi nhà cung cấp chưa được khởi tạo | Mở Drawer Sửa cấu hình. |
| Kích hoạt | Đáy thẻ nhà cung cấp | Khi nhà cung cấp chưa kích hoạt và đã được cấu hình | Mở Modal xác nhận kích hoạt. |

#### Các trường dữ liệu trong thẻ nhà cung cấp

| Trường | Mô tả |
|---|---|
| Base URL | URL cổng API (font monospace). Trống — Tag "Chưa cấu hình". |
| Client ID | Mã định danh app QLVB do nhà cung cấp cấp. |
| Client Secret | Hiển thị `***` nếu đã có. Trống — dấu gạch ngang. |
| Profile ID | Chỉ hiển thị với MySign Viettel. |
| Kiểm tra | Tag Kết nối OK / Lỗi kết nối / Chưa kiểm tra, kèm thời điểm kiểm tra gần nhất. |
| Cập nhật | Thời điểm thay đổi cấu hình gần nhất. |

#### Các thẻ KPI

| Thẻ | Ý nghĩa |
|---|---|
| Tổng người dùng | Số tài khoản đã cấu hình ký số với nhà cung cấp. |
| Đã xác thực | Số tài khoản đã xác thực được chứng thư số. |
| Giao dịch tháng | Số giao dịch ký số trong tháng. |
| Thành công | Số giao dịch ký thành công trong tháng. |
| Thất bại | Số giao dịch thất bại trong tháng. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Người dùng không có quyền | Bạn không có quyền truy cập trang này |
| Tải cấu hình thất bại | Không tải được cấu hình ký số |
| Banner: chưa có nhà cung cấp | Chưa có provider nào được kích hoạt. Vui lòng cấu hình và kích hoạt 1 provider để bật tính năng ký số. |
| Banner: đã có nhà cung cấp | Provider đang hoạt động: <tên> (<Base URL>) Kiểm tra lần cuối: <thời gian> |
| Bấm Kích hoạt khi chưa cấu hình | Provider này chưa được cấu hình |
| Bấm Kích hoạt khi đã đang chạy | Provider này đang được kích hoạt |
| Bấm Kích hoạt khi chưa kiểm tra OK (Modal cảnh báo) | Không thể kích hoạt provider <tên> khi chưa kiểm tra kết nối thành công. |
| Kích hoạt thành công | Đã kích hoạt <tên nhà cung cấp> |
| Kích hoạt thất bại | Kích hoạt thất bại |

### 3.2. Drawer Sửa cấu hình nhà cung cấp

![Drawer sửa cấu hình](screenshots/ky_so_cau_hinh_02_edit_drawer.png)

#### Bố cục màn hình

Drawer trượt từ phải, rộng 720px, tiêu đề "Sửa cấu hình — <tên nhà cung cấp>". Đầu thân drawer có Alert thông tin về nhà cung cấp đang sửa. Form bên dưới gồm Base URL, Client ID, Client Secret, và Profile ID (chỉ với MySign Viettel). Phía cuối form là khu Kiểm tra kết nối nền xám gồm hai nút và khu kết quả. Góc trên drawer có cụm nút Hủy / Lưu / Lưu & Kích hoạt.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Hủy | Góc trên drawer | Luôn hiển thị | Đóng drawer, bỏ thay đổi. |
| Lưu | Góc trên drawer | Luôn hiển thị | Lưu cấu hình mà không kích hoạt. |
| Lưu & Kích hoạt | Góc trên drawer | Hiển thị khi nhà cung cấp chưa kích hoạt | Vô hiệu cho đến khi Kiểm tra với secret mới trả về OK. Lưu rồi kích hoạt nhà cung cấp. |
| Kiểm tra cấu hình đã lưu | Khu kiểm tra | Luôn hiển thị; vô hiệu khi nhà cung cấp chưa từng có Client Secret | Test bằng thông tin đã lưu trong cơ sở dữ liệu. |
| Kiểm tra với secret mới | Khu kiểm tra | Vô hiệu khi chưa nhập Client Secret mới | Test bằng thông tin user vừa nhập trong form. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Base URL | Có | Tối đa 500 ký tự, phải bắt đầu `https://` hoặc `http://localhost`. Có gợi ý ví dụ. |
| Client ID | Có | Tối đa 200 ký tự. |
| Client Secret | Khi tạo mới | Tối thiểu 8 ký tự. Để trống — giữ nguyên giá trị cũ. Có nhãn "Để trống nếu giữ nguyên" và biểu tượng ổ khóa nhắc rằng giá trị cũ đã được mã hóa. |
| Profile ID | Có với MySign Viettel | Chuỗi định danh hồ sơ ký do Viettel cấp. |

#### Khu kết quả kiểm tra

Sau khi bấm Kiểm tra, khu này hiển thị Alert kết quả:

- Thành công — Alert xanh, kèm thông tin chứng thư (nếu có).
- Thất bại — Alert đỏ kèm lý do.

Mỗi kết quả gắn nhãn nguồn: "Cấu hình đã lưu" hoặc "Secret mới nhập" và thời gian phản hồi (ms).

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Trống Base URL | Nhập Base URL của provider |
| Base URL không hợp lệ | Base URL phải bắt đầu bằng https:// (hoặc http://localhost cho dev) |
| Trống Client ID | Nhập Client ID |
| Client Secret < 8 ký tự | Client Secret tối thiểu 8 ký tự |
| Trống Profile ID (MySign Viettel) | Profile ID là bắt buộc với MySign Viettel |
| Bấm Kiểm tra với secret mới khi chưa nhập secret | Nhập client_secret để kiểm tra kết nối |
| Kiểm tra thành công | Kiểm tra kết nối thành công |
| Kiểm tra cấu hình đã lưu thành công | Kiểm tra cấu hình đã lưu thành công |
| Kiểm tra thất bại | Không kết nối được provider |
| Lưu thành công không kèm kích hoạt | Cập nhật cấu hình thành công |
| Lưu kèm kích hoạt thành công | Lưu và kích hoạt cấu hình thành công |
| Lưu OK nhưng kích hoạt lỗi | Lưu thành công. Kích hoạt thất bại |
| Lưu thất bại | Lưu cấu hình thất bại |
| Backend báo provider_code sai | provider_code không hợp lệ |
| Backend báo client_id thiếu | client_id là bắt buộc |
| Backend báo client_secret thiếu | client_secret là bắt buộc |
| Backend báo cấu hình không tồn tại | Không tìm thấy cấu hình |

### 3.3. Modal Xác nhận kích hoạt nhà cung cấp

![Modal kích hoạt](screenshots/ky_so_cau_hinh_03_activate_confirm.png)

#### Bố cục màn hình

Modal nhỏ chính giữa, tiêu đề "Kích hoạt provider". Nội dung mô tả nhà cung cấp đang chuẩn bị kích hoạt và cảnh báo: "Provider đang hoạt động khác (nếu có) sẽ tự động bị tắt.". Đáy modal có nút Kích hoạt và Hủy.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Kích hoạt | Đáy modal | Luôn hiển thị | Đặt nhà cung cấp này làm mặc định, tự tắt nhà cung cấp khác. |
| Hủy | Đáy modal | Luôn hiển thị | Đóng modal, không thay đổi. |

#### Các trường dữ liệu

Không có trường nhập liệu.

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Kích hoạt thành công | Đã kích hoạt <tên nhà cung cấp> |
| Kích hoạt thất bại | Kích hoạt thất bại |
