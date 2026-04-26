# Đánh dấu cá nhân

## 1. Giới thiệu

Màn hình **Văn bản đánh dấu cá nhân** (`/van-ban-danh-dau`) tập hợp tất cả các văn bản mà người dùng đã đánh dấu (bookmark) ở các phân hệ Văn bản đến, Văn bản đi và Văn bản dự thảo về cùng một nơi để tra cứu nhanh. Đây là **danh sách riêng của từng cán bộ** — mỗi người chỉ thấy các văn bản chính mình đã đánh dấu, không phụ thuộc phòng ban hay đơn vị.

Cán bộ thường dùng tính năng đánh dấu để:
- Đánh dấu các văn bản quan trọng cần theo dõi liên tục.
- Lưu lại các văn bản đang đợi xử lý cá nhân.
- Tổng hợp các văn bản tham chiếu thường dùng để mở nhanh.

Việc **đánh dấu** hoặc **bỏ đánh dấu** một văn bản được thực hiện ngay tại màn hình chi tiết của văn bản (nút ngôi sao). Màn hình này chỉ tổng hợp lại — không phải nơi đầu tiên đánh dấu.

## 2. Quy trình thao tác và ràng buộc nghiệp vụ

**Quy trình tra cứu văn bản đã đánh dấu:**

1. Vào menu **Văn bản đánh dấu** ở sidebar (hoặc truy cập đường dẫn `/van-ban-danh-dau`).
2. Hệ thống tự gộp các văn bản đã đánh dấu từ ba phân hệ — Văn bản đến, Văn bản đi và Văn bản dự thảo — và sắp xếp theo thứ tự: văn bản **Quan trọng** lên đầu, sau đó theo **ngày đánh dấu mới nhất**.
3. Sử dụng các tab **Tất cả / VB đến / VB đi / Dự thảo** để lọc nhóm tương ứng. Số trong ngoặc của mỗi tab là tổng số văn bản đã đánh dấu thuộc nhóm đó.
4. Bấm vào tiêu đề **Trích yếu** hoặc nút **Xem (con mắt)** để mở chi tiết văn bản.
5. Bấm **In** ở góc phải đầu trang để in danh sách hiện tại theo bộ lọc đang chọn.

**Quy trình quản lý đánh dấu:**

1. Bấm biểu tượng **ngôi sao** ở đầu mỗi dòng để bật/tắt cờ "Quan trọng" cho văn bản đó. Văn bản quan trọng có ngôi sao vàng và được sắp lên đầu danh sách.
2. Bấm biểu tượng **thùng rác** ở cuối dòng để **bỏ đánh dấu** văn bản — văn bản sẽ biến mất khỏi danh sách (vẫn tồn tại ở phân hệ gốc của nó).

**Ràng buộc nghiệp vụ:**

- **Phạm vi cá nhân**: mỗi người chỉ thấy danh sách đánh dấu của riêng mình. Không có chế độ xem chung của phòng ban hay đơn vị.
- **Đánh dấu được tạo ở đâu**: nút đánh dấu (ngôi sao) nằm ở các màn hình chi tiết Văn bản đến, Văn bản đi và Văn bản dự thảo. Người dùng **không tạo mới đánh dấu trực tiếp** trên màn hình này.
- **Bỏ đánh dấu**: hành động bỏ đánh dấu chỉ xóa cờ bookmark — không xóa văn bản gốc.
- **Quan trọng vs đánh dấu thường**: cả hai đều thuộc danh sách đánh dấu cá nhân; cờ Quan trọng chỉ ảnh hưởng thứ tự sắp xếp (ưu tiên lên đầu).
- **In ấn**: tính năng In sử dụng hộp in của trình duyệt; chỉ in các dòng đang hiển thị trong tab đang chọn.
- **Chuyển nhánh phân hệ**: khi mở chi tiết một văn bản, hệ thống chuyển sang đường dẫn của phân hệ tương ứng — `/van-ban-den/[id]`, `/van-ban-di/[id]` hoặc `/van-ban-du-thao/[id]`.

## 3. Các màn hình chức năng

### 3.1. Màn hình Văn bản đánh dấu cá nhân

![Màn hình Văn bản đánh dấu cá nhân](screenshots/van_ban_danh_dau_01_main.png)

#### Bố cục màn hình

- **Thẻ chứa toàn bộ màn hình**: tiêu đề **"Văn bản đánh dấu cá nhân"** kèm biểu tượng ngôi sao vàng ở góc trái đầu thẻ; nút **In** ở góc phải.
- **Hàng tab lọc theo loại văn bản**: ngay dưới tiêu đề thẻ, gồm 4 tab: **Tất cả ([n]) / VB đến ([n]) / VB đi ([n]) / Dự thảo ([n])** — số trong ngoặc cập nhật theo dữ liệu thực tế.
- **Bảng danh sách**: bảng nhỏ gọn (size small), 10 cột (xem mục dưới), phân trang 20 dòng/trang. Thông tin tổng số hiển thị ở góc phải bảng dạng *"Tổng [n] văn bản"*.
- **Trạng thái rỗng**: khi tab đang chọn không có dòng nào, hiển thị hộp rỗng và dòng *"Chưa đánh dấu văn bản nào"*.
- **Khu vực in (ẩn trên màn hình, chỉ hiện khi in)**: bao gồm dòng tiêu đề lớn *"VĂN BẢN ĐÁNH DẤU CÁ NHÂN"*, ngày in và bảng tóm tắt 8 cột.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| **In** | Góc phải tiêu đề thẻ | Luôn | Mở hộp thoại in của trình duyệt, in danh sách hiện tại theo tab đang chọn. |
| **Tab Tất cả / VB đến / VB đi / Dự thảo** | Đầu thẻ | Luôn | Lọc danh sách theo nhóm. Khi đổi tab, bảng tải lại tức thì (không gọi lại máy chủ). |
| **Ngôi sao** (đầu mỗi dòng) | Cột đầu tiên | Luôn | Bật/tắt cờ "Quan trọng" cho văn bản đó. Sao vàng = quan trọng, sao xám = chưa đặt. Sau khi bấm, danh sách tải lại để cập nhật thứ tự. |
| **Trích yếu** (dạng liên kết) | Cột Trích yếu | Luôn | Mở màn hình chi tiết văn bản tương ứng (`/van-ban-den/[id]`, `/van-ban-di/[id]` hoặc `/van-ban-du-thao/[id]`). |
| **Con mắt (Xem)** | Cột thao tác cuối | Luôn | Mở màn hình chi tiết văn bản tương ứng — giống bấm vào Trích yếu. |
| **Thùng rác (Bỏ đánh dấu)** | Cột thao tác cuối | Luôn | Xóa cờ đánh dấu của văn bản đó — văn bản biến mất khỏi danh sách. Vẫn tồn tại ở phân hệ gốc. |
| **Phân trang** | Cuối bảng | Khi tổng số > 20 | Chuyển trang. Mỗi trang 20 dòng. |

#### Các cột

| Tên cột | Mô tả |
|---|---|
| (Ngôi sao Quan trọng) | Biểu tượng ngôi sao — vàng nếu được đặt là Quan trọng, xám nếu chưa. Chú giải khi rê chuột: *"Bỏ quan trọng"* hoặc *"Đánh dấu quan trọng"*. |
| Loại | Nhãn màu phân biệt phân hệ: **VB đến** (xanh dương), **VB đi** (xanh lá), **VB dự thảo** (cam). |
| Số VB | Số văn bản (số thứ tự đăng ký trong sổ). |
| Ngày nhận | Ngày văn bản được tiếp nhận / phát hành / soạn thảo. Định dạng `DD/MM/YYYY`. Trống → ô rỗng. |
| Số ký hiệu | Số ký hiệu văn bản. |
| Trích yếu | Nội dung trích yếu của văn bản. Hiển thị dạng liên kết — bấm để mở chi tiết. Cắt bằng `...` nếu quá dài. |
| CQ ban hành | Tên cơ quan / đơn vị ban hành văn bản. Cắt bằng `...` nếu dài. |
| Ghi chú | Ghi chú do người dùng nhập khi đánh dấu (ở phân hệ gốc). Cắt bằng `...` nếu dài. |
| Ngày đánh dấu | Ngày người dùng đặt cờ đánh dấu cho văn bản. Định dạng `DD/MM/YYYY`. |
| (Thao tác) | Hai nút **Xem** (con mắt) và **Bỏ đánh dấu** (thùng rác đỏ). |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tab đang chọn không có dòng nào | Chưa đánh dấu văn bản nào |
| Tải dữ liệu thất bại (lỗi mạng / máy chủ) | Lỗi tải dữ liệu |
| Bỏ đánh dấu thành công | Đã bỏ đánh dấu |
| Bỏ đánh dấu hoặc đổi cờ Quan trọng thất bại | Lỗi |
| Tổng số văn bản (góc phải bảng) | Tổng [n] văn bản |
