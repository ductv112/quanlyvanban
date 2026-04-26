# Quản lý người ký

## 1. Giới thiệu

Người ký là danh sách những nhân viên trong đơn vị có quyền ký các văn bản đi và văn bản dự thảo. Mỗi phòng ban có thể có một hoặc nhiều người ký riêng. Khi soạn văn bản đi hoặc dự thảo, người dùng sẽ chọn người ký từ danh sách này.

Người quản trị đơn vị sử dụng chức năng này để thêm hoặc gỡ bỏ người ký theo từng phòng ban.

## 2. Quy trình thao tác và ràng buộc nghiệp vụ

- Người ký được phân theo phòng ban. Phải chọn một phòng ban trên cây ở bên trái trước khi thêm người ký mới.
- Một nhân viên đã được thêm làm người ký của một phòng ban không thể được thêm lại vào cùng phòng ban đó.
- Trong hộp thoại thêm người ký, danh sách nhân viên chỉ hiển thị các nhân viên thuộc phòng ban đang chọn (kể cả các phòng ban con). Người dùng chỉ chọn nhân viên có sẵn, không nhập tay.
- Khi nhân viên được điều chuyển sang phòng ban khác, hệ thống tự động đồng bộ thông tin phòng ban của người ký theo nhân viên (qua trigger ở cơ sở dữ liệu). Người quản trị không cần thao tác thủ công.
- Bảng danh sách người ký không có thao tác chỉnh sửa, chỉ có thao tác xóa. Muốn thay đổi thông tin người ký, hãy xóa người ký hiện tại và thêm lại.

## 3. Các màn hình chức năng

### 3.1. Màn hình danh sách

![Danh sách người ký](screenshots/nguoi_ky_01_danh_sach.png)

#### Bố cục màn hình

- Khu vực trên cùng: tiêu đề "Quản lý người ký" và mô tả ngắn.
- Hai cột:
  - Cột trái (thẻ "Phòng ban"): cây phòng ban của đơn vị, có ô tìm kiếm phòng ban và nút tải lại.
  - Cột phải (thẻ "Danh sách người ký"): bảng danh sách các nhân viên đã được thêm làm người ký, kèm nút "Thêm người ký" ở góc phải tiêu đề thẻ.
- Khi chưa chọn phòng ban nào trên cây, bảng bên phải hiển thị toàn bộ người ký của đơn vị. Khi chọn một nhánh, bảng hiển thị người ký thuộc nhánh đó.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Thêm người ký | Góc phải tiêu đề thẻ Danh sách người ký | Luôn hiển thị | Mở hộp thoại Thêm người ký |
| Ô tìm kiếm phòng ban | Trên cùng cột trái | Luôn hiển thị | Lọc cây phòng ban theo từ khóa |
| Biểu tượng tải lại | Góc phải tiêu đề thẻ Phòng ban | Luôn hiển thị | Tải lại cây phòng ban |
| Nhánh trên cây phòng ban | Cột trái | Luôn hiển thị | Lọc danh sách người ký theo nhánh đã chọn |
| Biểu tượng thùng rác | Cuối mỗi dòng trong bảng | Luôn hiển thị | Mở hộp xác nhận xóa người ký |

#### Các cột / trường dữ liệu

| Cột | Ý nghĩa |
|---|---|
| Họ tên | Họ và tên đầy đủ của người ký, hiển thị in đậm màu xanh đậm |
| Chức vụ | Chức vụ hiện tại của người ký |
| Phòng ban | Phòng ban hiện tại của người ký (đồng bộ tự động khi nhân viên đổi phòng ban) |
| Thao tác | Biểu tượng thùng rác để xóa người ký |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Lỗi khi tải cây phòng ban | Lỗi tải dữ liệu đơn vị |
| Lỗi khi tải danh sách người ký | Lỗi tải danh sách người ký |

### 3.2. Hộp thoại Thêm người ký

![Hộp thoại thêm người ký](screenshots/nguoi_ky_02_them_moi.png)

#### Bố cục màn hình

- Hộp thoại nổi giữa màn hình, tiêu đề "Thêm người ký".
- Phần thân: dòng hướng dẫn "Chọn nhân viên để thêm vào danh sách người ký" và một ô chọn nhân viên dạng tìm kiếm.
- Hai nút Hủy và Thêm ở góc phải dưới hộp thoại.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Hủy | Góc phải dưới | Luôn hiển thị | Đóng hộp thoại, không thêm |
| Thêm | Góc phải dưới | Luôn hiển thị | Thêm nhân viên đã chọn vào danh sách người ký |
| Ô chọn nhân viên | Giữa hộp thoại | Luôn hiển thị | Tìm kiếm và chọn nhân viên theo họ tên, chức vụ hoặc phòng ban |

#### Các trường nhập

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Nhân viên | Có | Chọn từ danh sách nhân viên thuộc phòng ban đang chọn (gồm cả các phòng ban con); hiển thị theo định dạng "Họ tên - Chức vụ - Phòng ban"; không được nhập tay |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Chưa chọn nhân viên | Vui lòng chọn nhân viên |
| Chưa chọn phòng ban trên cây trái | Vui lòng chọn phòng ban / đơn vị từ cây bên trái trước |
| Thêm thành công | Thêm người ký thành công |
| Thêm thất bại | Lỗi khi thêm người ký |

### 3.3. Hộp xác nhận xóa

![Xác nhận xóa người ký](screenshots/nguoi_ky_03_xac_nhan_xoa.png)

#### Bố cục màn hình

- Hộp thoại nổi giữa màn hình, tiêu đề "Xác nhận xóa".
- Nội dung: 'Bạn có chắc chắn muốn xóa người ký "[Họ tên]"?', trong đó [Họ tên] là tên của người ký được chọn.
- Hai nút: Hủy và Xóa (màu đỏ).

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Hủy | Góc phải dưới | Luôn hiển thị | Đóng hộp thoại, không xóa |
| Xóa | Góc phải dưới, màu đỏ | Luôn hiển thị | Gỡ bỏ người ký khỏi danh sách và đóng hộp thoại |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Xóa thành công | Xóa người ký thành công |
| Xóa thất bại | Lỗi khi xóa |
