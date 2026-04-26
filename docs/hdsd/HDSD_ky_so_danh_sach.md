# Danh sách ký số

## 1. Giới thiệu

Trang Danh sách ký số là điểm vào tập trung để cán bộ ký số các tệp PDF đính kèm trên Văn bản đi, Dự thảo và Hồ sơ công việc. Trang gom tất cả tệp đang chờ ký, các giao dịch đang chạy, đã hoàn tất hoặc thất bại theo bốn tab. Mỗi cán bộ chỉ thấy giao dịch của riêng mình.

Khi bấm Ký số, hệ thống mở Modal ký số: gọi API tới nhà cung cấp đang hoạt động (SmartCA VNPT hoặc MySign Viettel), tạo giao dịch ký với thời hạn 3:00 phút và yêu cầu cán bộ xác nhận OTP trên ứng dụng nhà cung cấp đã cài trên điện thoại. Khi cán bộ xác nhận xong, tệp PDF được đính kèm chữ ký số và lưu lại trên hệ thống.

Đặc biệt với MySign Viettel: file PDF đã ký dùng chứng thư từ Viettel — Adobe Reader chỉ hiển thị chữ ký hợp lệ khi máy người xem đã cài Root CA Viettel. Trang luôn hiển thị banner cung cấp tệp Root CA và hướng dẫn cài đặt.

## 2. Quy trình thao tác và ràng buộc nghiệp vụ

Quy trình ký số một tệp:

1. Mở trang Danh sách ký số. Mặc định mở tab Cần ký.
2. Tìm dòng tệp cần ký, bấm Ký số — Modal Ký số bật ra. Hệ thống tự gửi yêu cầu ký tới nhà cung cấp và bắt đầu đếm ngược 3:00 phút.
3. Mở ứng dụng nhà cung cấp trên điện thoại (SmartCA / MySign), xác nhận yêu cầu OTP đang chờ.
4. Khi xác nhận xong, modal đổi trạng thái sang Đã ký — tệp đã ký nằm trên Văn bản tương ứng và xuất hiện trong tab Đã ký.
5. Nếu hết 3:00 phút mà chưa xác nhận — giao dịch chuyển sang Hết thời gian (xem trong tab Thất bại). Cán bộ có thể bấm Ký lại để tạo giao dịch mới.
6. Cán bộ có thể đóng modal trong khi đang chờ — giao dịch tiếp tục chạy nền và Bell thông báo sẽ báo khi xong.

Ràng buộc nghiệp vụ:

- Chỉ ký được tệp PDF.
- Văn bản đến (incoming) không được phép ký số.
- Mỗi giao dịch ký có thời hạn 3:00 phút (180 giây). Hết hạn mà chưa OTP — giao dịch tự chuyển trạng thái Hết thời gian.
- Cán bộ chỉ ký được tệp mà mình có quyền (lãnh đạo ký được chỉ định trên Văn bản đi / Dự thảo / HSCV và Văn bản đó đang ở đúng bước trình ký).
- Mỗi tệp chỉ ký 1 lần. Sau khi ký, tệp gốc không sửa được nữa và sinh ra phiên bản đã ký.
- Để bật Adobe Reader xác thực chữ ký Viettel — máy người xem phải cài Root CA Viettel.

## 3. Các màn hình chức năng

### 3.1. Màn hình Danh sách ký số

![Màn hình danh sách ký số](screenshots/ky_so_danh_sach_01_main.png)

#### Bố cục màn hình

Từ trên xuống:

- Đầu trang: tiêu đề "Danh sách ký số".
- Banner Root CA Viettel (luôn hiển thị) — xem 3.2.
- Thẻ chính chứa 4 tab. Mỗi tab có Badge số lượng giao dịch tương ứng. Bên dưới mỗi tab là bảng dữ liệu phân trang.

#### Các tab

| Tab | Badge | Mô tả |
|---|---|---|
| Cần ký | Cam | Tệp PDF cán bộ đang được giao trách nhiệm ký nhưng chưa tạo giao dịch. |
| Đang xử lý | Xanh teal | Giao dịch đã tạo, đang đợi OTP hoặc đang chạy nền. |
| Đã ký | Xanh lá | Giao dịch đã hoàn tất, có tệp đã ký. |
| Thất bại | Đỏ | Giao dịch đã hủy, hết thời gian, hoặc bị nhà cung cấp từ chối. |

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Ký số | Cột Thao tác — tab Cần ký | Luôn hiển thị; vô hiệu khi đang mở Modal ký | Mở Modal ký số. |
| Hủy | Cột Thao tác — tab Đang xử lý | Luôn hiển thị | Mở Modal xác nhận hủy giao dịch. |
| Tải file đã ký | Cột Thao tác — tab Đã ký | Luôn hiển thị | Tải tệp PDF đã ký từ máy chủ. |
| Ký lại | Cột Thao tác — tab Thất bại | Luôn hiển thị; vô hiệu khi đang mở Modal ký | Mở Modal ký số để tạo giao dịch mới. |

#### Các cột / trường dữ liệu theo tab

Tab Cần ký:

| Cột | Mô tả |
|---|---|
| Mã VB | Mã hiệu hoặc số văn bản gắn tệp. |
| Tên file | Tên tệp PDF cần ký (cắt ngắn, có tooltip). |
| Loại VB | Văn bản đi, Dự thảo, hoặc Hồ sơ công việc. |
| Ngày tạo | Thời điểm tạo tệp (DD/MM/YYYY HH:mm). |

Tab Đang xử lý:

| Cột | Mô tả |
|---|---|
| Mã VB | Mã hiệu văn bản. |
| Tên file | Tên tệp PDF đang ký. |
| Nhà cung cấp | Tag xanh — VNPT SmartCA hoặc Viettel MySign. |
| Bắt đầu lúc | Thời điểm tạo giao dịch ký (DD/MM/YYYY HH:mm). |

Tab Đã ký:

| Cột | Mô tả |
|---|---|
| Mã VB | Mã hiệu văn bản. |
| Tên file | Tên tệp PDF gốc. |
| Nhà cung cấp | Tag xanh lá — nhà cung cấp đã ký. |
| Ngày ký | Thời điểm hoàn tất (DD/MM/YYYY HH:mm). |

Tab Thất bại:

| Cột | Mô tả |
|---|---|
| Mã VB | Mã hiệu văn bản. |
| Tên file | Tên tệp PDF. |
| Lý do lỗi | Mô tả lỗi do nhà cung cấp trả về hoặc nhãn Hết thời gian / Đã hủy / Thất bại. |
| Thất bại lúc | Thời điểm kết thúc giao dịch (DD/MM/YYYY HH:mm). |

#### Phân trang và URL

Phân trang đặt ở chân bảng — chuyển trang, đổi số dòng/trang (10/20/50/100), hiển thị "Tổng N giao dịch". Khi đổi tab/trang/cỡ trang, đường dẫn URL được cập nhật theo tham số `?tab=...&page=...&pageSize=...`. Tải lại trang giữ nguyên trạng thái hiển thị.

Hệ thống có realtime: khi giao dịch hoàn tất ở phía nhà cung cấp, danh sách tự cập nhật mà không cần làm mới thủ công.

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải danh sách thất bại | Không tải được danh sách |
| Tab Cần ký trống | Bạn không có văn bản nào đang chờ ký |
| Tab Đang xử lý trống | Không có giao dịch nào đang xử lý |
| Tab Đã ký trống | Bạn chưa có giao dịch ký số hoàn tất |
| Tab Thất bại trống | Không có giao dịch thất bại / hết hạn / đã hủy |
| Tải file đã ký 403 | Bạn không có quyền tải file này |
| Tải file đã ký 404 | File đã ký chưa sẵn sàng hoặc giao dịch không tồn tại |
| Tải file đã ký lỗi khác | Không tải được file đã ký |

### 3.2. Banner cài Root CA Viettel

![Banner Root CA](screenshots/ky_so_danh_sach_01_main.png)

#### Bố cục màn hình

Banner xanh dương đặt ngay dưới tiêu đề trang. Tiêu đề: "Cần cài Root CA Viettel để Adobe Reader hiển thị chữ ký hợp lệ". Mô tả: nếu Adobe Reader báo chữ ký không xác thực khi mở tệp đã ký bằng MySign Viettel — cán bộ cài Root CA Viettel theo hướng dẫn. Hai nút thao tác phía dưới mô tả.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Tải Root CA (.cer) | Trong banner | Luôn hiển thị | Tải tệp `.cer` Root CA Viettel để cài vào Trusted Root trên máy. |
| Xem hướng dẫn (PDF) | Trong banner | Luôn hiển thị | Mở tệp PDF hướng dẫn cài Root CA trong tab mới. |

#### Các trường dữ liệu

Không có trường nhập liệu.

#### Thông báo của hệ thống

Banner không có thông báo riêng.

### 3.3. Modal Ký số

![Modal ký số](screenshots/ky_so_danh_sach_02_sign_modal_pending.png)

#### Bố cục màn hình

Modal rộng 560px, tiêu đề "Ký số điện tử" có biểu tượng chứng thư. Bên trong từ trên xuống:

- Dòng "File: <tên tệp>".
- Dòng "Nhà cung cấp: <tên>" (hiển thị sau khi tạo giao dịch xong).
- Dòng "Trạng thái: ..." kèm Tag màu — Đang khởi tạo giao dịch / Đang chờ xác nhận OTP / Đã ký / Thất bại / Hết thời gian / Đã hủy.
- Khi đang chờ OTP — đồng hồ đếm ngược dạng vòng tròn 3:00. Vòng đổi màu theo thời gian còn lại: trên 60s — xanh navy, từ 30 đến 60s — vàng, dưới 30s — đỏ. Bên dưới có dòng nhắc "Vui lòng xác nhận OTP trên ứng dụng <nhà cung cấp> trên điện thoại".
- Khu Alert mô tả trạng thái:
  - Đang chờ — Alert xanh, hướng dẫn xác nhận OTP, gợi ý có thể đóng để chạy nền.
  - Thành công — Alert xanh "Ký số thành công", nhắc đóng modal để xem tệp đã ký.
  - Thất bại / Hết thời gian / Đã hủy — Alert đỏ hoặc vàng kèm lý do từ máy chủ.

Đáy modal có cụm nút thay đổi theo trạng thái.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Hủy ký số | Đáy modal | Khi giao dịch đang chờ OTP | Gửi lệnh hủy giao dịch lên máy chủ. |
| Đóng (chạy nền) | Đáy modal | Khi giao dịch đang chờ OTP | Đóng modal nhưng không hủy — giao dịch tiếp tục chạy, Bell thông báo sẽ báo khi xong. |
| Đóng | Đáy modal | Khi giao dịch đã kết thúc (Đã ký / Thất bại / Hết thời gian / Đã hủy) | Đóng modal. |

#### Các trường dữ liệu

Modal không có trường nhập liệu — toàn bộ thông tin lấy từ giao dịch ký đang chạy.

#### Vòng đời và thời hạn

| Pha | Mô tả |
|---|---|
| Khởi tạo | Hệ thống đẩy tệp lên nhà cung cấp, lấy mã giao dịch. Có Tag "Đang khởi tạo giao dịch...". |
| Đang chờ OTP | Đồng hồ đếm ngược 3:00 chạy. Cán bộ phải xác nhận trên điện thoại trong khoảng thời gian này. |
| Hết thời gian | Sau 3:00 mà chưa xác nhận — modal đổi sang trạng thái Hết thời gian, ghi nhận trong tab Thất bại. |
| Đã ký | Cán bộ xác nhận trên điện thoại — modal hiện Alert thành công. |
| Đã hủy | Cán bộ bấm Hủy ký số — giao dịch chuyển sang Đã hủy. |
| Thất bại | Nhà cung cấp từ chối hoặc lỗi mạng — Alert đỏ kèm lý do. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Khởi tạo lỗi mạng | Không thể kết nối đến máy chủ |
| Khởi tạo lỗi từ máy chủ | Khởi tạo ký số thất bại |
| Phản hồi không hợp lệ | Phản hồi không hợp lệ từ máy chủ |
| Backend báo file không phải PDF | Chỉ hỗ trợ ký file PDF. File hiện tại không phải định dạng PDF. |
| Backend báo không có quyền ký | Bạn không có quyền ký file này |
| Backend báo ký văn bản đến | Không được ký số văn bản đến |
| Backend báo PDF không hợp lệ | File PDF không hợp lệ hoặc không tương thích ký số |
| Backend báo không tải file PDF | Không thể tải file PDF từ MinIO |
| Backend báo nhà cung cấp từ chối | Provider từ chối yêu cầu ký |
| Hết thời gian (FE đếm ngược) | Hết thời gian chờ xác nhận OTP. Vui lòng thử lại. |
| Ký thành công | Ký số thành công |
| Bấm Hủy ký số thành công | Đã hủy giao dịch ký số |
| Bấm Hủy ký số thất bại | Không thể hủy giao dịch |

### 3.4. Modal Xác nhận hủy giao dịch ký số

#### Bố cục màn hình

Modal nhỏ chính giữa, tiêu đề "Hủy giao dịch ký số". Nội dung: "Bạn có chắc muốn hủy giao dịch ký cho file '<tên tệp>'?". Đáy có nút Hủy giao dịch (đỏ) và Đóng.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Hủy giao dịch | Đáy modal | Luôn hiển thị | Gọi máy chủ hủy giao dịch ký số. |
| Đóng | Đáy modal | Luôn hiển thị | Đóng modal, giao dịch giữ nguyên. |

#### Các trường dữ liệu

Không có trường nhập liệu.

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Hủy thành công | Đã hủy giao dịch ký số |
| Hủy thất bại | Không thể hủy giao dịch |
| Backend báo không có quyền | Bạn không có quyền hủy giao dịch này |
| Backend báo giao dịch không tồn tại | Không tìm thấy giao dịch ký số |
