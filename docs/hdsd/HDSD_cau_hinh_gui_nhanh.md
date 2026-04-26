# Cấu hình gửi nhanh

## 1. Giới thiệu

Cấu hình gửi nhanh là phân hệ giúp người dùng tự chọn sẵn một danh sách cán bộ thường xuyên gửi văn bản tới (cấp dưới hoặc đồng nghiệp hay phối hợp). Khi gửi văn bản hoặc bút phê phân công ở các phân hệ khác, danh sách này được tick sẵn — tiết kiệm thời gian thay vì chọn lại từng người mỗi lần.

Phân hệ chỉ phục vụ một vai duy nhất:
- Mọi cán bộ đăng nhập đều có thể tự cấu hình danh sách gửi nhanh cá nhân của riêng mình.

Cấu hình mang tính cá nhân — mỗi tài khoản có danh sách riêng, không ảnh hưởng đến tài khoản khác.

## 2. Quy trình thao tác và ràng buộc nghiệp vụ

Quy trình chuẩn:

1. Mở màn hình Cấu hình gửi nhanh từ menu.
2. Tìm kiếm cán bộ ở cột trái theo tên, chức vụ hoặc phòng ban.
3. Tick ô chọn ở dòng cán bộ — họ xuất hiện ngay ở cột phải "Đã chọn gửi nhanh".
4. Có thể bỏ tick ở cột trái hoặc bấm Bỏ ở cột phải để loại khỏi danh sách.
5. Bấm Lưu cấu hình. Danh sách sẽ áp dụng cho lần gửi văn bản hoặc bút phê tiếp theo.

Ràng buộc nghiệp vụ:

- Cấu hình gắn với tài khoản đăng nhập, không chia sẻ giữa người dùng.
- Khi lưu, hệ thống ghi đè toàn bộ cấu hình cũ bằng danh sách hiện tại — không cộng dồn.
- Tìm kiếm cán bộ ở cột trái không làm mất danh sách đã chọn ở cột phải. Người dùng có thể tìm theo nhiều keyword khác nhau và tick chọn dồn vào cột phải.
- Danh sách gửi nhanh dùng chung cho tính năng Gửi văn bản đến và bút phê Phân công giải quyết — không cần cấu hình riêng cho từng phân hệ.

## 3. Các màn hình chức năng

### 3.1. Màn hình cấu hình gửi nhanh

![Màn hình cấu hình gửi nhanh](screenshots/cau_hinh_gui_nhanh_01_main.png)

#### Bố cục màn hình

Trên cùng là tiêu đề "Cấu hình gửi nhanh" với nút Lưu cấu hình ở góc phải. Dưới tiêu đề có khung hướng dẫn xanh nhạt giải thích mục đích của cấu hình.

Phần thân chia hai cột:
- Cột trái (60% bề rộng): ô tìm kiếm cán bộ (theo tên, chức vụ, phòng ban) và bảng danh sách cán bộ phân trang. Mỗi dòng có ô chọn ở đầu, sau đó là Họ tên, Chức vụ, Phòng ban.
- Cột phải (40% bề rộng): khung vàng nhạt hiển thị các cán bộ đã chọn. Mỗi dòng gồm Họ tên, Chức vụ, Phòng ban và nút Bỏ (đỏ) để loại khỏi danh sách.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Lưu cấu hình (N người) | Góc phải tiêu đề | Luôn hiển thị | Ghi đè cấu hình hiện tại với danh sách N cán bộ đang chọn |
| Tìm kiếm | Đầu cột trái | Luôn hiển thị | Tìm cán bộ theo tên, chức vụ hoặc phòng ban (chống dội 350ms) |
| Ô chọn dòng | Mỗi dòng cột trái | Luôn hiển thị | Tick = thêm vào danh sách; bỏ tick = loại khỏi danh sách |
| Bỏ | Mỗi dòng cột phải | Luôn hiển thị | Loại cán bộ khỏi danh sách đã chọn |
| Phân trang | Dưới bảng cột trái | Khi tổng > 20 cán bộ | Chuyển trang trong danh sách cán bộ |

#### Các cột hiển thị (cột trái)

| Tên cột | Mô tả |
|---|---|
| Ô chọn | Ô check chọn cán bộ vào danh sách |
| Họ tên | Họ tên đầy đủ của cán bộ |
| Chức vụ | Chức vụ hiện tại; hiển thị "—" nếu chưa có |
| Phòng ban | Phòng ban đang công tác; hiển thị "—" nếu chưa có |

#### Các cột hiển thị (cột phải — danh sách đã chọn)

| Tên cột | Mô tả |
|---|---|
| Họ tên | Họ tên cán bộ đã chọn |
| Chức vụ | Hiển thị dạng thẻ |
| Phòng ban | Tên phòng ban |
| Bỏ | Nút bỏ chọn (đỏ) |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Lỗi tải danh sách cán bộ | Lỗi tải danh sách cán bộ |
| Lỗi tải cấu hình hiện tại | Lỗi tải cấu hình hiện tại |
| Lưu thành công | Đã lưu cấu hình gửi nhanh |
| Lỗi lưu | Lỗi lưu |
| Danh sách cán bộ rỗng | Không tìm thấy cán bộ |
| Chưa chọn cán bộ | Chưa chọn cán bộ nào |
| Danh sách người nhận không hợp lệ | Danh sách người nhận không hợp lệ |
