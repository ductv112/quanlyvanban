# Hướng dẫn sử dụng: Màn hình Tổng quan (Dashboard)

Tài liệu này mô tả màn hình **Tổng quan** — màn hình đầu tiên người dùng nhìn thấy ngay sau khi đăng nhập vào hệ thống Quản lý văn bản điện tử (e-Office).

---

## 1. Giới thiệu

Màn hình **Tổng quan** đóng vai trò là **trang chủ** của toàn bộ hệ thống. Mục đích chính là:

- Cung cấp một cái nhìn nhanh về khối lượng công việc đang chờ xử lý của người dùng (văn bản đến chưa đọc, hồ sơ công việc, dự thảo, tin nhắn, lịch họp...).
- Hiển thị xu hướng văn bản đến/đi theo tháng và phân bố hồ sơ công việc theo trạng thái dưới dạng biểu đồ.
- Liệt kê các văn bản và đầu việc mới nhất để người dùng truy cập trực tiếp, không cần vào từng phân hệ riêng.
- Cho phép tạo nhanh các loại văn bản, hồ sơ, lịch chỉ với một cú bấm.

Dữ liệu trên màn hình này **phụ thuộc vào vai trò người dùng**:

- **Quản trị hệ thống**: thấy số liệu tổng hợp toàn hệ thống.
- **Người dùng thông thường**: chỉ thấy số liệu thuộc phòng ban / đơn vị mình (kể cả các phòng ban con thuộc nhánh tổ chức của mình), kèm theo các văn bản được giao trực tiếp cho cá nhân.

---

## 2. Bố cục màn hình

![Màn hình Tổng quan](screenshots/dashboard_01_main.png)

Màn hình được chia thành 4 khu vực, xếp dọc từ trên xuống:

- **Phần đầu trang**: Lời chào *"Xin chào, [Họ tên người dùng]"* và dòng mô tả ngắn *"Tổng quan hoạt động hệ thống văn bản"*.
- **Khu vực 1 — Hàng thẻ thống kê**: 8 thẻ thống kê màu sắc khác nhau, hiển thị các chỉ số chính (xem mục 3). Bấm vào mỗi thẻ sẽ chuyển đến màn hình tương ứng.
- **Khu vực 2 — Biểu đồ thống kê**: 2 biểu đồ trên cùng một hàng:
  - Biểu đồ cột "Văn bản đến/đi theo tháng" (chiếm phần lớn bên trái).
  - Biểu đồ tròn "HSCV theo trạng thái" (bên phải).
- **Khu vực 3 — Văn bản đến mới + Việc sắp tới hạn**:
  - Bảng "Văn bản mới nhận" (bên trái) — 5 văn bản đến mới nhất.
  - Khung "Việc sắp tới hạn" (bên phải) — danh sách hồ sơ công việc gần tới hạn.
- **Khu vực 4 — Văn bản đi mới + Thao tác nhanh**:
  - Bảng "Văn bản đi mới" (bên trái) — 5 văn bản đi mới nhất.
  - Lưới các nút "Thao tác nhanh" (bên phải) — 6 nút tạo nhanh.

Trên thiết bị di động, các khu vực sẽ tự động xếp dọc một cột để dễ thao tác.

---

## 3. Các thẻ thống kê

Mỗi thẻ thống kê là một hình chữ nhật màu, hiển thị **tên chỉ số** ở dòng trên và **giá trị số** to ở dòng dưới. Bấm vào thẻ để chuyển đến màn hình chi tiết tương ứng.

| Thẻ thống kê | Ý nghĩa | Khi bấm sẽ chuyển đến |
|---|---|---|
| **VB đến chưa đọc** | Số văn bản đến chưa được người dùng (hoặc phòng ban / đơn vị) đọc. | Văn bản đến |
| **VB đi chờ duyệt** | Số văn bản đi đang trong trạng thái chờ lãnh đạo duyệt. | Văn bản đi |
| **Hồ sơ công việc** | Tổng số hồ sơ công việc thuộc phạm vi của người dùng. | Hồ sơ công việc |
| **Việc quá hạn** | Số hồ sơ công việc đã quá hạn xử lý. | Hồ sơ công việc |
| **Dự thảo chờ phát hành** | Số văn bản dự thảo đã được duyệt nhưng chưa phát hành (chưa thành văn bản đi). | Văn bản dự thảo |
| **Tin nhắn chưa đọc** *(module tạm ẩn)* | Số tin nhắn nội bộ gửi đến cá nhân chưa đọc. | Tin nhắn |
| **Thông báo chưa đọc** | Số thông báo nội bộ của đơn vị chưa đọc. | Thông báo nội bộ |
| **Lịch họp hôm nay** *(module tạm ẩn)* | Số cuộc họp / sự kiện sử dụng phòng họp diễn ra trong ngày hôm nay. | Lịch cơ quan |

> **Phạm vi dữ liệu**: Với người dùng thường, bốn thẻ đầu (VB đến / VB đi / HSCV / Việc quá hạn) tính theo phòng ban — đơn vị của người dùng (bao gồm cả các phòng ban con). Với quản trị viên, các thẻ này tính trên toàn hệ thống. Thẻ "Tin nhắn chưa đọc" luôn tính theo cá nhân người đang đăng nhập.

> **Phiên bản hiện tại — module tạm ẩn**: Hai thẻ **Tin nhắn chưa đọc** và **Lịch họp hôm nay** vẫn hiển thị giá trị thống kê, nhưng các module **Tin nhắn** và **Lịch** chưa được mở trên menu sidebar ở phiên bản này. Bấm vào thẻ vẫn dẫn đến trang tương ứng; tuy nhiên việc truy cập thường xuyên qua menu chính sẽ được mở lại ở các phiên bản sau khi module hoàn thiện.

---

## 4. Các biểu đồ thống kê

| Biểu đồ | Loại | Nội dung | Dữ liệu hiển thị |
|---|---|---|---|
| **Văn bản đến/đi theo tháng** | Biểu đồ cột nhóm (grouped bar) | Mỗi tháng có 2 cột — một cột cho **VB đến** (màu xanh navy) và một cột cho **VB đi** (màu xanh teal). | 6 tháng gần nhất, theo tháng / năm (định dạng `MM/YYYY`). Trục ngang là tháng, trục dọc là số lượng. |
| **HSCV theo trạng thái** | Biểu đồ tròn (donut) | Phân bố hồ sơ công việc theo các trạng thái: Mới, Đang xử lý, Chờ duyệt, Đã duyệt, Hoàn thành, Từ chối, Trả về. | Tổng tất cả HSCV thuộc phạm vi người dùng. Mỗi lát bánh là một trạng thái, kèm số lượng. Khi không có dữ liệu, hiển thị dòng *"Chưa có dữ liệu"*. |

Rê chuột lên các phần của biểu đồ để xem chi tiết số liệu (tooltip).

---

## 5. Bảng "Văn bản mới nhận" và "Văn bản đi mới"

Hai bảng nhỏ nằm ở khu vực 3 và 4, mỗi bảng hiển thị **tối đa 5 dòng** — văn bản mới nhất theo ngày nhận / ngày ban hành.

### 5.1. Bảng "Văn bản mới nhận"

| Cột | Mô tả |
|---|---|
| **Số/Ký hiệu** | Số văn bản đến (in đậm, màu xanh navy). Nếu không có hiển thị dấu gạch ngang `—`. |
| **Trích yếu** | Trích yếu nội dung văn bản. Nếu quá dài sẽ tự động cắt và hiện đầy đủ khi rê chuột. |
| **Ngày nhận** | Ngày tiếp nhận văn bản, định dạng `DD/MM/YYYY`. |
| **Độ khẩn** | Nhãn màu hiển thị độ khẩn của văn bản. Quy ước màu: **đỏ** cho mức "Hỏa tốc", **cam** cho "Khẩn", **xanh** cho các mức còn lại. |

Nếu chưa có dữ liệu, bảng hiển thị thông báo *"Chưa có văn bản mới"*.

Bấm nút **Xem thêm** ở góc phải bảng để chuyển sang màn hình **Văn bản đến** đầy đủ.

### 5.2. Bảng "Văn bản đi mới"

| Cột | Mô tả |
|---|---|
| **Số/Ký hiệu** | Số văn bản đi (in đậm, màu xanh navy). |
| **Trích yếu** | Trích yếu nội dung văn bản, có cắt ngắn khi quá dài. |
| **Ngày ban hành** | Ngày ban hành văn bản, định dạng `DD/MM/YYYY`. |
| **Loại VB** | Nhãn xanh hiển thị loại văn bản (ví dụ: Công văn, Quyết định, Thông báo...). |

Nếu chưa có dữ liệu, hiển thị *"Chưa có văn bản đi mới"*.

Bấm **Xem thêm** để chuyển sang màn hình **Văn bản đi**.

---

## 6. Khung "Việc sắp tới hạn"

Khung này nằm bên phải khu vực 3, hiển thị danh sách **hồ sơ công việc** mà người dùng sắp phải hoàn thành. Mỗi dòng gồm:

- **Tiêu đề việc**: in đậm, màu xanh navy.
- **Nhãn trạng thái**: màu sắc theo quy ước:

  | Trạng thái | Màu nhãn |
  |---|---|
  | Hoàn thành | Xanh lá |
  | Từ chối / Trả về | Đỏ |
  | Đang xử lý / Chờ duyệt | Xanh dương (processing) |
  | Đã duyệt | Vàng cảnh báo |
  | Mới (và các trạng thái khác) | Xám mặc định |

- **Thanh tiến độ**: hiển thị phần trăm hoàn thành công việc, màu xanh teal.
- **Hạn xử lý**: ngày hạn ở góc phải, định dạng `DD/MM`. Nếu không có hạn hiển thị `—`.

Khi không có việc sắp tới hạn, khung hiển thị *"Không có việc sắp tới hạn"*.

Bấm **Xem thêm** để chuyển sang màn hình **Hồ sơ công việc**.

---

## 7. Khung "Thao tác nhanh"

Lưới 6 nút nằm bên phải khu vực 4, dùng để **tạo nhanh** các đối tượng nghiệp vụ thường gặp.

| Nút | Tác dụng |
|---|---|
| **Tạo VB đến** | Chuyển đến màn hình Văn bản đến để tạo mới. |
| **Tạo VB đi** | Chuyển đến màn hình Văn bản đi để tạo mới. |
| **Soạn dự thảo** | Chuyển đến màn hình Văn bản dự thảo. |
| **Soạn tin nhắn** *(module tạm ẩn)* | Chuyển đến màn hình Tin nhắn. |
| **Tạo HSCV** | Chuyển đến màn hình Hồ sơ công việc. |
| **Tạo lịch** *(module tạm ẩn)* | Chuyển đến màn hình Lịch cá nhân. |

> **Lưu ý**: Các nút này chỉ điều hướng đến đúng phân hệ — việc tạo mới sẽ thực hiện tiếp tại màn hình đích (bấm thêm nút "Thêm" trên màn hình đó).

---

## 8. Cách dùng dashboard hằng ngày

Quy trình khuyến nghị khi mở màn hình Tổng quan đầu giờ làm việc:

1. **Quan sát hàng thẻ thống kê** — tập trung vào các thẻ đang có số > 0, đặc biệt:
   - **VB đến chưa đọc** > 0 → bấm vào thẻ để vào danh sách văn bản đến và xử lý.
   - **Việc quá hạn** > 0 → bấm vào thẻ để vào hồ sơ công việc, xử lý ngay các việc đã quá hạn.
   - **VB đi chờ duyệt** > 0 (với lãnh đạo) → bấm vào thẻ để duyệt văn bản đi.
2. **Liếc qua biểu đồ** — kiểm tra xu hướng văn bản tháng này so với các tháng trước, phân bố HSCV để biết khối lượng việc đang dồn ở trạng thái nào.
3. **Xem khung "Việc sắp tới hạn"** — sắp xếp ưu tiên xử lý theo ngày hạn.
4. **Xem các văn bản mới nhất** ở 2 bảng để kiểm tra có văn bản nào quan trọng vừa đến không.
5. **Sử dụng khung "Thao tác nhanh"** khi cần tạo mới một loại văn bản / hồ sơ ngay.

---

## 9. Lưu ý / Ràng buộc

### 9.1. Phạm vi dữ liệu phụ thuộc vai trò

Dữ liệu trên dashboard được tự động lọc theo phòng ban / đơn vị của người đăng nhập:

- **Tài khoản quản trị (admin)**: nhìn thấy số liệu **toàn hệ thống** ở tất cả các thẻ và biểu đồ.
- **Người dùng thường**: chỉ thấy số liệu thuộc **đơn vị / phòng ban của mình** (bao gồm cả các phòng ban con thuộc nhánh tổ chức). Riêng bảng "Văn bản mới nhận" còn hiển thị thêm các văn bản được phân công trực tiếp cho cá nhân (kể cả khi văn bản đó thuộc phòng ban khác).

### 9.2. Dữ liệu được làm mới khi nào?

Dashboard **không tự động làm mới theo thời gian thực**. Số liệu được lấy **một lần** khi mở màn hình. Để cập nhật, người dùng cần:

- Tải lại trang (phím tắt `F5` hoặc `Ctrl+R`), hoặc
- Bấm chuyển sang một màn hình khác rồi quay lại Tổng quan từ thanh điều hướng bên trái.

### 9.3. Khi nào số liệu hiển thị bằng 0?

- Người dùng chưa có hoạt động trong phạm vi tương ứng (ví dụ: phòng ban chưa nhận văn bản nào).
- Lỗi tải dữ liệu — khi đó các thẻ vẫn hiển thị giá trị `0` thay vì báo lỗi (để không cản trở thao tác).
- Riêng các bảng và biểu đồ sẽ hiển thị thông báo *"Chưa có dữ liệu"* / *"Chưa có văn bản mới"* / *"Không có việc sắp tới hạn"* khi rỗng.

### 9.4. Định dạng ngày tháng

Toàn bộ ngày trên dashboard sử dụng định dạng Việt Nam:

- Ngày đầy đủ: `DD/MM/YYYY` (ví dụ: `25/04/2026`).
- Ngày rút gọn (cột "Hạn" trong khung Việc sắp tới hạn): `DD/MM`.

### 9.5. Tương tác trên thẻ thống kê

Mọi thẻ ở khu vực 1 đều có thể bấm vào — con trỏ chuột sẽ chuyển sang dạng "bàn tay" khi rê qua. Thẻ có hiệu ứng nổi nhẹ (hover) để báo hiệu là phần tử có thể bấm.

---

*Tài liệu được biên soạn dựa trên hệ thống thực tế đang triển khai. Mọi thắc mắc vui lòng liên hệ với đội phát triển để được hỗ trợ.*
