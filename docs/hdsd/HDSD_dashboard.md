# Tổng quan (Dashboard)

## 1. Giới thiệu

**Tổng quan** là màn hình đầu tiên người dùng nhìn thấy ngay sau khi đăng nhập vào hệ thống Quản lý văn bản điện tử (e-Office). Màn hình đóng vai trò trang chủ — cho người dùng cái nhìn nhanh về khối lượng công việc đang chờ xử lý, xu hướng văn bản theo tháng, các văn bản và đầu việc mới nhất cùng các lối tắt tạo nhanh sang các phân hệ khác.

Đối tượng sử dụng là **toàn bộ cán bộ, công chức** đã đăng nhập vào hệ thống. Dữ liệu hiển thị trên màn hình **phụ thuộc vai trò người dùng**:

- **Quản trị viên** thấy số liệu tổng hợp toàn hệ thống.
- **Người dùng thông thường** chỉ thấy số liệu thuộc phòng ban, đơn vị mình (bao gồm cả các phòng ban con thuộc nhánh tổ chức của mình), kèm các văn bản và việc được giao trực tiếp cho cá nhân.

## 2. Quy trình thao tác và ràng buộc nghiệp vụ

**Quy trình sử dụng hằng ngày:**

1. Đăng nhập vào hệ thống — hệ thống tự đưa đến màn hình **Tổng quan**.
2. Quan sát các thẻ thống kê ở đầu trang để biết khối lượng công việc đang chờ. Thẻ có giá trị khác 0 → có việc cần xử lý.
3. Bấm vào thẻ thống kê tương ứng để chuyển sang màn hình chi tiết (VB đến, VB đi, HSCV, Dự thảo, Thông báo).
4. Quan sát hai bảng "Văn bản mới nhận" và "Văn bản đi mới" để nắm 5 văn bản mới nhất; danh sách "Việc sắp tới hạn" để nắm hồ sơ công việc gần hạn.
5. Sử dụng khu vực "Thao tác nhanh" để tạo mới văn bản đến, văn bản đi, dự thảo, hồ sơ công việc... mà không cần vào menu sidebar.

**Ràng buộc nghiệp vụ:**

- **Phạm vi dữ liệu**: bốn thẻ chính (VB đến chưa đọc, VB đi chờ duyệt, Hồ sơ công việc, Việc quá hạn), hai bảng VB mới và biểu đồ thống kê đều **lọc theo phòng ban — đơn vị** của người dùng đối với người dùng thường, **toàn hệ thống** đối với Quản trị viên.
- **Việc sắp tới hạn**: chỉ tính các hồ sơ công việc mà người dùng được giao trực tiếp.
- **Thông báo chưa đọc**: tính theo cá nhân người đang đăng nhập đối với chuông thông báo cá nhân.
- **Tự động tải lại**: dữ liệu được tải khi vào trang. Để cập nhật số liệu mới nhất, tải lại trang trình duyệt (`F5`) hoặc rời và quay lại màn hình.

## 3. Các màn hình chức năng

### 3.1. Màn hình Tổng quan

![Màn hình Tổng quan](screenshots/dashboard_01_main.png)

#### Bố cục màn hình

Màn hình xếp dọc thành 4 khu vực, từ trên xuống:

- **Phần đầu trang**: lời chào *"Xin chào, [Họ tên người dùng]"* và dòng mô tả *"Tổng quan hoạt động hệ thống văn bản"*.
- **Khu vực 1 — Hàng thẻ thống kê**: 6 thẻ thống kê màu sắc khác nhau, mỗi thẻ là một hình chữ nhật bo tròn. Bấm vào thẻ → chuyển đến màn hình chi tiết tương ứng.
- **Khu vực 2 — Biểu đồ thống kê**: 2 biểu đồ trên cùng một hàng — biểu đồ cột "Văn bản đến/đi theo tháng" (chiếm phần lớn bên trái) và biểu đồ tròn "HSCV theo trạng thái" (bên phải).
- **Khu vực 3 — Văn bản đến mới + Việc sắp tới hạn**: bảng "Văn bản mới nhận" (bên trái, 5 dòng) và khung "Việc sắp tới hạn" (bên phải).
- **Khu vực 4 — Văn bản đi mới + Thao tác nhanh**: bảng "Văn bản đi mới" (bên trái, 5 dòng) và lưới 4 nút "Thao tác nhanh" (bên phải).

Trên thiết bị di động, các khu vực và các cột bên trong tự xếp chồng dọc.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Thẻ **VB đến chưa đọc** | Khu vực 1 | Luôn | Chuyển đến màn hình **Văn bản đến**. |
| Thẻ **VB đi chờ duyệt** | Khu vực 1 | Luôn | Chuyển đến màn hình **Văn bản đi**. |
| Thẻ **Hồ sơ công việc** | Khu vực 1 | Luôn | Chuyển đến màn hình **Hồ sơ công việc**. |
| Thẻ **Việc quá hạn** | Khu vực 1 | Luôn | Chuyển đến màn hình **Hồ sơ công việc**. |
| Thẻ **Dự thảo chờ phát hành** | Khu vực 1 | Luôn | Chuyển đến màn hình **Văn bản dự thảo**. |
| Thẻ **Thông báo chưa đọc** | Khu vực 1 | Luôn | Chuyển đến màn hình **Thông báo nội bộ**. |
| **Xem thêm** | Góc phải tiêu đề bảng "Văn bản mới nhận" | Luôn | Mở danh sách đầy đủ ở **Văn bản đến**. |
| **Xem thêm** | Góc phải tiêu đề khung "Việc sắp tới hạn" | Luôn | Mở danh sách đầy đủ ở **Hồ sơ công việc**. |
| **Xem thêm** | Góc phải tiêu đề bảng "Văn bản đi mới" | Luôn | Mở danh sách đầy đủ ở **Văn bản đi**. |
| **Tạo VB đến** | Khu vực 4 | Luôn | Mở màn hình **Văn bản đến** để tạo mới. |
| **Tạo VB đi** | Khu vực 4 | Luôn | Mở màn hình **Văn bản đi** để tạo mới. |
| **Soạn dự thảo** | Khu vực 4 | Luôn | Mở màn hình **Văn bản dự thảo** để soạn mới. |
| **Tạo HSCV** | Khu vực 4 | Luôn | Mở màn hình **Hồ sơ công việc** để tạo mới. |

#### Các trường dữ liệu

**Bảng thẻ thống kê (Khu vực 1):**

| Tên thẻ | Mô tả |
|---|---|
| VB đến chưa đọc | Số văn bản đến chưa được người dùng (hoặc phòng ban) đọc. |
| VB đi chờ duyệt | Số văn bản đi đang trong trạng thái chờ lãnh đạo duyệt. |
| Hồ sơ công việc | Tổng số hồ sơ công việc thuộc phạm vi của người dùng. |
| Việc quá hạn | Số hồ sơ công việc đã quá hạn xử lý. |
| Dự thảo chờ phát hành | Số văn bản dự thảo đã được duyệt nhưng chưa phát hành thành VB đi. |
| Thông báo chưa đọc | Số thông báo nội bộ của đơn vị chưa được người dùng đọc. |

**Biểu đồ (Khu vực 2):**

| Biểu đồ | Loại | Nội dung |
|---|---|---|
| Văn bản đến/đi theo tháng | Cột nhóm | Mỗi tháng có 2 cột: VB đến (xanh navy) và VB đi (xanh teal). Hiển thị 6 tháng gần nhất theo định dạng `MM/YYYY`. Trục dọc là số lượng. Khi không có dữ liệu, hiển thị nền trắng. |
| HSCV theo trạng thái | Tròn (donut) | Phân bố hồ sơ công việc theo các trạng thái: Mới, Đang xử lý, Chờ duyệt, Đã duyệt, Hoàn thành, Từ chối, Trả về. Mỗi lát bánh là một trạng thái kèm số lượng. Khi không có dữ liệu hiển thị dòng *"Chưa có dữ liệu"*. |

Rê chuột lên biểu đồ để xem chi tiết số liệu (tooltip).

**Bảng "Văn bản mới nhận" (Khu vực 3 — bên trái):**

| Tên cột | Mô tả |
|---|---|
| Số/Ký hiệu | Số ký hiệu đã đăng số của văn bản đến. Trống hiển thị `—`. |
| Trích yếu | Nội dung trích yếu, bị cắt nếu quá dài (`...`). |
| Ngày nhận | Ngày văn bản được tiếp nhận, định dạng `DD/MM/YYYY`. |
| Độ khẩn | Nhãn màu: đỏ (Hỏa tốc), cam (Khẩn), xanh (các mức còn lại). Trống không hiển thị nhãn. |

**Khung "Việc sắp tới hạn" (Khu vực 3 — bên phải):**

| Tên trường | Mô tả |
|---|---|
| Tên việc | Tên hồ sơ công việc, in đậm. |
| Trạng thái | Nhãn màu theo trạng thái: Mới (xám), Đang xử lý / Chờ duyệt (xanh dương), Đã duyệt (cam), Hoàn thành (xanh lá), Từ chối / Trả về (đỏ). |
| Tiến độ | Thanh tiến độ phần trăm (xanh teal). |
| Thời hạn | Ngày hết hạn, định dạng `DD/MM`. Trống hiển thị `—`. |

Khi không có dữ liệu, khung hiển thị dòng *"Không có việc sắp tới hạn"*.

**Bảng "Văn bản đi mới" (Khu vực 4 — bên trái):**

| Tên cột | Mô tả |
|---|---|
| Số/Ký hiệu | Số ký hiệu của văn bản đi. Trống hiển thị `—`. |
| Trích yếu | Nội dung trích yếu, bị cắt nếu quá dài. |
| Ngày ban hành | Ngày phát hành, định dạng `DD/MM/YYYY`. |
| Loại VB | Nhãn xanh dương ghi loại văn bản. Trống không hiển thị nhãn. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Bảng "Văn bản mới nhận" không có dữ liệu | Chưa có văn bản mới |
| Bảng "Văn bản đi mới" không có dữ liệu | Chưa có văn bản đi mới |
| Khung "Việc sắp tới hạn" không có dữ liệu | Không có việc sắp tới hạn |
| Biểu đồ "HSCV theo trạng thái" không có dữ liệu | Chưa có dữ liệu |
