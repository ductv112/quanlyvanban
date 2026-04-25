# Hướng dẫn sử dụng: Màn hình Ký số > Danh sách ký số

Tài liệu này mô tả đầy đủ các chức năng có trong màn hình **Ký số > Danh sách ký số** (đường dẫn `/ky-so/danh-sach`) của hệ thống Quản lý văn bản điện tử (e-Office), giúp người dùng hiểu rõ cách sử dụng và quy trình nghiệp vụ.

---

## 1. Giới thiệu

Màn hình **Ký số > Danh sách ký số** là nơi cán bộ thực hiện thao tác **ký số điện tử** trên các tệp đính kèm dạng PDF của văn bản đi, văn bản dự thảo và hồ sơ công việc. Đây là công cụ thay thế cho việc ký giấy, sử dụng chứng thư số (CKS) và ứng dụng OTP trên thiết bị di động (VNPT SmartCA, Viettel MySign) để gắn chữ ký số hợp lệ vào tệp PDF của văn bản.

Mỗi bản ký số gồm 2 thành phần:

- **Tệp PDF gốc** (đính kèm trên văn bản đi / dự thảo / hồ sơ công việc).
- **Giao dịch ký số** (sign transaction): bản ghi nhận yêu cầu ký số gửi sang nhà cung cấp dịch vụ chứng thực, lưu trạng thái (đang chờ OTP, đã ký, thất bại, hết hạn, đã hủy) cùng `provider_transaction_id` để tra cứu.

Màn hình này gom toàn bộ các tệp **cần ký** và các giao dịch **đã / đang / không thành công** của tài khoản đăng nhập hiện tại. Đây là **danh sách cá nhân** — mỗi người dùng chỉ thấy các tệp / giao dịch của chính mình; máy chủ luôn lọc theo `staffId` lấy từ phiên đăng nhập (JWT), không thể xem dữ liệu của người khác.

> **Lưu ý nghiệp vụ**: Hệ thống **không cho phép ký số văn bản đến** — chỉ có 3 loại được ký: **Văn bản đi**, **Dự thảo**, **Hồ sơ công việc**.

---

## 2. Bố cục màn hình

![Màn hình Danh sách ký số](screenshots/ky_so_danh_sach_01_main.png)

Màn hình gồm các khu vực chính sau:

- **Phần đầu trang**: Tiêu đề **"Danh sách ký số"** kèm biểu tượng chứng thư an toàn (hình khiên).
- **Khung "Cần cài Root CA Viettel"** (dải thông báo màu xanh dương ngay dưới tiêu đề): Hướng dẫn cài Root CA của Viettel để Adobe Reader hiển thị chữ ký hợp lệ. Khung này luôn hiển thị, gồm 2 nút:
  - **Tải Root CA (.cer)** — tải tệp chứng thư gốc về máy.
  - **Xem hướng dẫn (PDF)** — mở tài liệu hướng dẫn cài Root CA trong tab mới.
- **Thanh phân loại (tab)**: Gồm 4 tab xếp hàng ngang, mỗi tab kèm **huy hiệu số đếm** màu phân biệt:
  - **Cần ký** (huy hiệu cam) — số tệp đang chờ ký.
  - **Đang xử lý** (huy hiệu xanh teal) — số giao dịch đã gửi đi, đang chờ xác nhận OTP.
  - **Đã ký** (huy hiệu xanh lá) — số giao dịch đã hoàn tất.
  - **Thất bại** (huy hiệu đỏ) — số giao dịch thất bại / hết hạn / đã hủy.
- **Bảng danh sách**: Hiển thị các dòng tương ứng với tab đang chọn. Mặc định mở tab **Cần ký**.
- **Phân trang**: Dưới chân bảng, mặc định **20 dòng / trang**, có thể đổi sang 10 / 50 / 100 dòng. Dòng tổng kết hiển thị *"Tổng N giao dịch"*.

> **Realtime cập nhật**: Khi giao dịch ký của bạn được nhà cung cấp xử lý xong (thành công hoặc thất bại), hệ thống tự đẩy thông báo qua Socket.IO và **bảng + huy hiệu số đếm sẽ tự động làm mới** mà không cần tải lại trang.

> **Đồng bộ với địa chỉ web**: Tab đang chọn, số trang và kích thước trang đều được lưu trên thanh địa chỉ (ví dụ `?tab=completed&page=2&pageSize=20`). Có thể chia sẻ liên kết hoặc dùng nút **Quay lại / Tiến** của trình duyệt mà không mất ngữ cảnh.

---

## 3. Các tab phân loại

| Tab | Số đếm hiển thị | Nội dung |
|---|---|---|
| **Cần ký** | `need_sign` | Các **tệp PDF đính kèm** thuộc văn bản đi / dự thảo / hồ sơ công việc mà bạn **có quyền ký** (signer / approver / người tạo / quản trị) nhưng **chưa ký** và **chưa có giao dịch ký nào đang chạy**. Đây là danh sách hành động — bạn cần xử lý từng dòng. |
| **Đang xử lý** | `pending` | Các **giao dịch ký số** đã được gửi sang nhà cung cấp dịch vụ chứng thực, đang **chờ bạn xác nhận OTP** trên ứng dụng di động (VNPT SmartCA / Viettel MySign). Mỗi giao dịch có thời hạn xác nhận **3 phút**; quá hạn sẽ tự chuyển sang **Thất bại** với trạng thái *Hết thời gian*. |
| **Đã ký** | `completed` | Các giao dịch đã hoàn tất — file PDF đã được gắn chữ ký số và lưu vào kho tệp. Tải file đã ký từ tab này. |
| **Thất bại** | `failed` | Gộp 3 trạng thái: **failed** (nhà cung cấp từ chối / lỗi kỹ thuật), **expired** (hết 3 phút không xác nhận OTP), **cancelled** (bạn chủ động hủy). Có thể bấm **Ký lại** để mở lại modal ký. |

Bấm vào tab nào, bảng bên dưới chỉ hiển thị các dòng thuộc loại đó. Khi chuyển tab, hệ thống **đặt lại số trang về 1** nhưng **giữ nguyên kích thước trang** đã chọn.

---

## 4. Các cột trong bảng danh sách

Cột hiển thị **khác nhau theo từng tab** vì bản chất dữ liệu khác nhau (tab **Cần ký** là tệp đính kèm, 3 tab còn lại là giao dịch ký).

### 4.1. Tab "Cần ký"

| Tên cột | Mô tả |
|---|---|
| **Mã VB** | Số ký hiệu của văn bản (ví dụ `123/QĐ-UBND`). Nếu chưa cấp số, hiển thị nhãn loại văn bản hoặc `#<id>`. |
| **Tên file** | Tên tệp PDF đính kèm. Tooltip hiển thị đầy đủ khi rê chuột. Nếu dài sẽ tự động cắt bớt. |
| **Loại VB** | Nhãn xám phân biệt: **Văn bản đi**, **Dự thảo**, **Hồ sơ công việc**. |
| **Ngày tạo** | Ngày giờ tệp đính kèm được tạo, định dạng `DD/MM/YYYY HH:mm`. |
| (cột thao tác) | Nút **Ký số** màu xanh navy (xem mục 6). |

### 4.2. Tab "Đang xử lý"

| Tên cột | Mô tả |
|---|---|
| **Mã VB** | Nhãn văn bản (`doc_label`) hoặc `#<doc_id>`. |
| **Tên file** | Tên tệp PDF đang được ký. |
| **Nhà cung cấp** | Nhãn xanh dương: **VNPT SmartCA** hoặc **Viettel MySign** — nhà cung cấp dịch vụ chứng thực đang xử lý giao dịch. |
| **Bắt đầu lúc** | Thời điểm bạn gửi yêu cầu ký, định dạng `DD/MM/YYYY HH:mm`. |
| (cột thao tác) | Nút **Hủy** (màu đỏ) — chỉ hiển thị cho giao dịch của chính bạn (xem mục 6.2). |

### 4.3. Tab "Đã ký"

| Tên cột | Mô tả |
|---|---|
| **Mã VB** | Nhãn văn bản hoặc `#<doc_id>`. |
| **Tên file** | Tên tệp PDF đã ký. |
| **Nhà cung cấp** | Nhãn xanh lá: nhà cung cấp đã thực hiện ký (VNPT / Viettel). |
| **Ngày ký** | Thời điểm hoàn tất (`completed_at`), định dạng `DD/MM/YYYY HH:mm`. |
| (cột thao tác) | Nút **Tải file đã ký** (biểu tượng mũi tên xuống) — xem mục 6.3. |

### 4.4. Tab "Thất bại"

| Tên cột | Mô tả |
|---|---|
| **Mã VB** | Nhãn văn bản hoặc `#<doc_id>`. |
| **Tên file** | Tên tệp PDF của giao dịch thất bại. |
| **Lý do lỗi** | Thông điệp lỗi chi tiết (`error_message`). Nếu để trống, hệ thống hiển thị nhãn dự phòng theo trạng thái: **Hết thời gian**, **Đã hủy**, **Thất bại**. Nếu dài quá 80 ký tự sẽ cắt bớt và hiện đầy đủ khi rê chuột. |
| **Thất bại lúc** | Thời điểm `completed_at`; nếu trống dùng `created_at`. |
| (cột thao tác) | Nút **Ký lại** màu xanh navy (xem mục 6.4). |

> **Lưu ý**: Trên màn hình này hiện **chưa có ô tìm kiếm tự do và chưa có bộ lọc nâng cao**. Để thu hẹp danh sách, sử dụng các tab phân loại và phân trang.

---

## 5. Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| **Tải Root CA (.cer)** | Khung Root CA dưới tiêu đề | Luôn hiển thị | Tải tệp chứng thư gốc Viettel về máy (`viettel-ca-new.cer`). Cài 1 lần duy nhất vào kho chứng thư của Windows / Adobe Reader để chữ ký hiển thị **hợp lệ**. |
| **Xem hướng dẫn (PDF)** | Khung Root CA dưới tiêu đề | Luôn hiển thị | Mở tài liệu hướng dẫn cài Root CA dạng PDF (`huong-dan-cai-root-ca.pdf`) trong tab mới. |
| **Tab "Cần ký" / "Đang xử lý" / "Đã ký" / "Thất bại"** | Thanh phân loại | Luôn hiển thị | Chuyển bảng sang loại dữ liệu tương ứng. Mỗi tab kèm số đếm cập nhật theo thời gian thực. |
| **Ký số** (biểu tượng khiên, nền xanh navy) | Cột thao tác — tab **Cần ký** | Mỗi dòng | Mở **cửa sổ Ký số điện tử** để bắt đầu giao dịch ký với nhà cung cấp. **Bị vô hiệu hóa khi đang có 1 cửa sổ ký mở** (chống bấm 2 lần tạo 2 giao dịch). |
| **Hủy** (màu đỏ) | Cột thao tác — tab **Đang xử lý** | Mỗi dòng có giao dịch trạng thái `pending` của chính bạn | Mở hộp xác nhận, sau đó hủy giao dịch. Chỉ hủy được giao dịch **chưa hoàn tất** và **của chính mình**. |
| **Tải file đã ký** (biểu tượng mũi tên xuống) | Cột thao tác — tab **Đã ký** | Mỗi dòng | Tải tệp PDF đã ký về máy. Tệp được phân phát qua máy chủ proxy (không tiết lộ địa chỉ kho lưu trữ nội bộ). Tên tệp tự động thêm tiền tố `signed_`. |
| **Ký lại** (biểu tượng làm mới) | Cột thao tác — tab **Thất bại** | Mỗi dòng | Mở lại **cửa sổ Ký số điện tử** với cùng tệp đính kèm để tạo giao dịch mới. **Bị vô hiệu hóa khi đang có 1 cửa sổ ký mở**. |
| **Hủy ký số** (trong cửa sổ ký) | Footer cửa sổ ký | Khi giao dịch đang ở trạng thái `pending` | Hủy giao dịch hiện tại — sau khi xác nhận, trạng thái chuyển sang **Đã hủy**. |
| **Đóng (chạy nền)** (trong cửa sổ ký) | Footer cửa sổ ký | Khi giao dịch đang ở trạng thái `pending` | Đóng cửa sổ — giao dịch tiếp tục chạy nền, hệ thống sẽ thông báo qua **chuông thông báo** khi hoàn tất. |
| **Đóng** (trong cửa sổ ký) | Footer cửa sổ ký | Khi giao dịch ở trạng thái cuối (đã ký / thất bại / hết hạn / đã hủy) | Đóng cửa sổ. |

---

## 6. Quy trình thao tác chính

### 6.1. Ký số một tệp đính kèm

> **Điều kiện trước khi ký** (kiểm tra ở mục 7.1, 7.2): (1) Quản trị viên đã cấu hình nhà cung cấp ký số ở trạng thái hoạt động; (2) Bạn đã cấu hình **Tài khoản ký số cá nhân** ở trang `/ky-so/tai-khoan` và đã **xác thực** thành công; (3) Tệp đính kèm đúng định dạng PDF.

1. Vào menu **Ký số > Danh sách ký số**, bấm tab **Cần ký**.
2. Tìm dòng tương ứng với tệp cần ký.
3. Bấm nút **Ký số** ở cột thao tác.
4. Cửa sổ **Ký số điện tử** mở ra (xem ảnh dưới), hiển thị:
   - **File**: tên tệp đang ký.
   - **Nhà cung cấp**: nhãn xanh — **SmartCA VNPT** hoặc **MySign Viettel** — tùy cấu hình hệ thống.
   - **Trạng thái**: ban đầu *"Đang khởi tạo giao dịch..."*.

   ![Cửa sổ Ký số điện tử — đang chờ OTP](screenshots/ky_so_danh_sach_02_sign_modal_pending.png)

5. Sau khoảng 0,5–1 giây, trạng thái chuyển sang **Đang chờ xác nhận OTP** kèm:
   - **Đồng hồ đếm ngược 3:00** dạng vòng tròn ở giữa cửa sổ (xanh navy → vàng khi còn 30–60s → đỏ khi còn dưới 30s).
   - Khung thông báo *"Chờ xác nhận OTP trên thiết bị di động"*.
6. Mở ứng dụng **VNPT SmartCA** hoặc **Viettel MySign** trên điện thoại của bạn, vào mục thông báo / yêu cầu ký, **xác nhận OTP**.
7. Khi nhà cung cấp ký xong, cửa sổ tự động chuyển sang trạng thái **Đã ký** (màu xanh lá), kèm thông báo *"Ký số thành công"*. File đã ký được lưu tự động vào kho tệp.
8. Bấm **Đóng** để thoát. Tab **Cần ký** tự giảm số đếm, tab **Đã ký** tăng tương ứng.

> **Mẹo**: Có thể bấm **Đóng (chạy nền)** ngay khi đang chờ OTP — giao dịch không bị hủy mà tiếp tục chạy. Khi hoàn tất, hệ thống đẩy thông báo qua **chuông thông báo** ở góc trên màn hình; hoặc bạn quay lại tab **Đã ký** sẽ thấy giao dịch xuất hiện.

### 6.2. Hủy một giao dịch đang xử lý

1. Vào tab **Đang xử lý**.
2. Tìm dòng giao dịch cần hủy.
3. Bấm nút **Hủy** (màu đỏ) ở cột thao tác.
4. Hộp xác nhận hiện ra với câu hỏi *"Bạn có chắc muốn hủy giao dịch ký cho file ..."*.
5. Bấm **Hủy giao dịch** (màu đỏ) để xác nhận, hoặc **Đóng** để bỏ qua.
6. Hệ thống thông báo **"Đã hủy giao dịch ký số"**. Giao dịch chuyển từ tab **Đang xử lý** sang tab **Thất bại** với trạng thái *Đã hủy*.

> **Lưu ý**: Chỉ hủy được giao dịch **của chính mình** và **đang ở trạng thái `pending`**. Hệ thống đối chiếu `staff_id` của giao dịch với tài khoản đang đăng nhập — nếu khác sẽ trả lỗi *"Bạn không có quyền hủy giao dịch này"*.

### 6.3. Tải file đã ký

1. Vào tab **Đã ký**.
2. Tìm dòng giao dịch tương ứng.
3. Bấm nút **Tải file đã ký** (biểu tượng mũi tên xuống) ở cột thao tác.
4. Trình duyệt tải tệp PDF đã ký về máy với tên dạng `signed_<tên_file_gốc>.pdf`.

> **Lưu ý**: Tệp được phát qua máy chủ proxy (không phải qua liên kết tạm thời `presigned URL`). Hệ thống đặt `Cache-Control: no-store` để chống lưu cache trình duyệt — mỗi lần tải đều xác thực lại quyền sở hữu.

### 6.4. Ký lại một giao dịch thất bại

1. Vào tab **Thất bại**.
2. Tìm dòng giao dịch thất bại / hết hạn / đã hủy.
3. (Khuyến nghị) Rê chuột vào cột **Lý do lỗi** để xem nguyên nhân đầy đủ.
4. Bấm nút **Ký lại** ở cột thao tác → mở lại **cửa sổ Ký số điện tử** với cùng tệp PDF.
5. Thực hiện tiếp các bước 5 → 8 ở mục 6.1.

> **Lưu ý**: Nút **Ký lại** tạo **giao dịch mới hoàn toàn** (transaction_id mới); giao dịch thất bại cũ vẫn lưu lại trong tab **Thất bại** để phục vụ kiểm tra / đối chiếu.

---

## 7. Lưu ý / Ràng buộc nghiệp vụ

### 7.1. Điều kiện hệ thống — Cấu hình nhà cung cấp

Trước khi user ký được, **Quản trị viên** phải cấu hình ít nhất 1 nhà cung cấp dịch vụ chứng thực (CFG-01) ở màn hình **Ký số > Cấu hình** và đặt trạng thái **Đang hoạt động**. Nếu chưa có nhà cung cấp đang hoạt động, bấm **Ký số** sẽ nhận lỗi:

> *"Hệ thống chưa cấu hình provider ký số. Vui lòng liên hệ Quản trị viên."*

### 7.2. Điều kiện cá nhân — Tài khoản ký số đã xác thực

Mỗi user phải tự cấu hình thông tin định danh (`user_id`, `credential_id`) của mình tại màn hình **Ký số > Tài khoản ký số cá nhân** (`/ky-so/tai-khoan`) và bấm **Kiểm tra** để xác thực. Nếu chưa cấu hình hoặc chưa xác thực, bấm **Ký số** sẽ nhận một trong hai lỗi:

- *"Bạn chưa cấu hình tài khoản ký số. Vui lòng vào "Tài khoản ký số cá nhân" để cấu hình."*
- *"Tài khoản ký số chưa được xác thực. Vui lòng bấm "Kiểm tra" trong trang Tài khoản ký số cá nhân."*

### 7.3. Quyền ký theo từng tệp

Hệ thống chỉ cho phép ký nếu user thuộc **một trong các nhóm** sau (kiểm tra qua hàm `edoc.fn_attachment_can_sign`):

- **Người ký** (`signer`) hoặc **Người duyệt** (`approver`) được gán cho văn bản (so khớp tên không phân biệt dấu, hoa thường — UNACCENT + LOWER).
- **Người tạo** (`created_by`) văn bản.
- **Quản trị viên** (`isAdmin`).

Nếu không thỏa, bấm **Ký số** sẽ nhận lỗi *"Bạn không có quyền ký file này"* (HTTP 403).

### 7.4. Không ký số văn bản đến

Văn bản đến (`incoming_doc`) **không được phép ký số** theo quy định nghiệp vụ cơ quan nhà nước. Nếu cố ý gửi yêu cầu, hệ thống chặn ngay và trả lỗi:

> *"Không được ký số văn bản đến"*

Tab **Cần ký** trên màn hình này chỉ liệt kê tệp thuộc 3 loại được phép: **Văn bản đi**, **Dự thảo**, **Hồ sơ công việc**.

### 7.5. Chỉ ký được file PDF

Hệ thống kiểm tra phần mở rộng tệp; nếu tên tệp không kết thúc bằng `.pdf` sẽ trả lỗi:

> *"Chỉ hỗ trợ ký file PDF. File hiện tại không phải định dạng PDF."*

Trường hợp tệp PDF lỗi cấu trúc (corrupt) không thể chèn placeholder chữ ký, hệ thống trả:

> *"File PDF không hợp lệ hoặc không tương thích ký số: ..."*

### 7.6. Thời hạn xác nhận OTP — 3 phút

Mỗi giao dịch ký có thời hạn **180 giây** kể từ lúc gửi sang nhà cung cấp. Nếu user không xác nhận OTP trong thời gian này, giao dịch tự động chuyển sang trạng thái **Hết thời gian** (`expired`) và xuất hiện ở tab **Thất bại**. Đồng hồ đếm ngược trên cửa sổ ký:

- **Xanh navy** khi còn > 60 giây.
- **Vàng** khi còn 30–60 giây.
- **Đỏ** khi còn dưới 30 giây.

### 7.7. Cài Root CA Viettel để hiển thị chữ ký hợp lệ

Đối với các tệp ký bằng **Viettel MySign**, Adobe Reader có thể hiển thị cảnh báo *"chữ ký không xác thực"* nếu máy tính chưa có Root CA của Viettel trong kho chứng thư hệ thống. Cài Root CA **một lần duy nhất** trên mỗi máy tính:

1. Bấm **Tải Root CA (.cer)** trên khung thông báo đầu trang.
2. Bấm **Xem hướng dẫn (PDF)** để xem các bước cài chi tiết.
3. Sau khi cài, mở lại tệp đã ký bằng Adobe Reader — chữ ký sẽ hiển thị tích xanh **hợp lệ**.

### 7.8. Cập nhật theo thời gian thực

Trang lắng nghe 2 sự kiện qua Socket.IO:

- `sign_completed` — kích hoạt khi nhà cung cấp ký xong và worker hoàn tất gắn chữ ký vào tệp.
- `sign_failed` — kích hoạt khi giao dịch thất bại / hết hạn / bị hủy.

Khi nhận được sự kiện của chính mình, bảng **tự làm mới** đồng thời các huy hiệu số đếm trên 4 tab cũng được cập nhật. Server lọc sự kiện theo phòng `user_{staffId}` — user khác không nhận được.

### 7.9. Phạm vi cá nhân — không chia sẻ

Mỗi user chỉ thấy giao dịch / tệp cần ký của chính mình. Server lấy `staffId` từ JWT của phiên đăng nhập, **không bao giờ** lấy từ tham số URL hay body — đảm bảo không thể truy cập danh sách của người khác (mitigate T-11-18).

### 7.10. Tải lại danh sách

Hệ thống không có nút **Làm mới** thủ công. Danh sách tự cập nhật trong các trường hợp:

- Khi mở trang lần đầu.
- Khi chuyển tab, đổi trang, đổi kích thước trang.
- Khi nhận sự kiện Socket.IO `sign_completed` / `sign_failed`.
- Khi thực hiện thành công thao tác **Ký số** / **Hủy** trên cùng trang.

Nếu nghi ngờ dữ liệu không đồng bộ, có thể tải lại trang bằng phím **F5**.

### 7.11. Bảng tổng hợp các thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Khởi tạo ký số thành công | Yêu cầu ký đã được gửi. Vui lòng xác nhận OTP trên ứng dụng di động. |
| Ký số thành công | Ký số thành công |
| Hủy giao dịch thành công | Đã hủy giao dịch ký số |
| Hết thời gian chờ OTP | Hết thời gian chờ xác nhận OTP. Vui lòng thử lại. |
| Chưa cấu hình nhà cung cấp | Hệ thống chưa cấu hình provider ký số. Vui lòng liên hệ Quản trị viên. |
| Chưa cấu hình tài khoản ký số | Bạn chưa cấu hình tài khoản ký số. Vui lòng vào "Tài khoản ký số cá nhân" để cấu hình. |
| Tài khoản ký số chưa xác thực | Tài khoản ký số chưa được xác thực. Vui lòng bấm "Kiểm tra" trong trang Tài khoản ký số cá nhân. |
| Không có quyền ký tệp | Bạn không có quyền ký file này |
| Cố ký văn bản đến | Không được ký số văn bản đến |
| Tệp không phải PDF | Chỉ hỗ trợ ký file PDF. File hiện tại không phải định dạng PDF. |
| PDF lỗi cấu trúc | File PDF không hợp lệ hoặc không tương thích ký số: \<chi tiết\> |
| Nhà cung cấp từ chối yêu cầu | Provider từ chối yêu cầu ký: \<chi tiết\> |
| Hủy giao dịch của người khác | Bạn không có quyền hủy giao dịch này |
| Hủy giao dịch không ở trạng thái pending | Giao dịch không thể hủy (trạng thái hiện tại: \<status\>) |
| Tải file khi giao dịch chưa hoàn tất | Giao dịch chưa có file đã ký |
| Tải file của giao dịch người khác (không phải admin) | Bạn không có quyền tải file của giao dịch này |
| Lỗi tải danh sách | Không tải được danh sách |
| Tab "Cần ký" trống | Bạn không có văn bản nào đang chờ ký |
| Tab "Đang xử lý" trống | Không có giao dịch nào đang xử lý |
| Tab "Đã ký" trống | Bạn chưa có giao dịch ký số hoàn tất |
| Tab "Thất bại" trống | Không có giao dịch thất bại / hết hạn / đã hủy |

---

*Tài liệu được biên soạn dựa trên hệ thống thực tế đang triển khai. Mọi thắc mắc vui lòng liên hệ với đội phát triển để được hỗ trợ.*
