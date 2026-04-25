# Hướng dẫn sử dụng: Màn hình Ký số > Tài khoản ký số cá nhân

Tài liệu này mô tả đầy đủ các chức năng có trong màn hình **Ký số > Tài khoản ký số cá nhân** (đường dẫn `/ky-so/tai-khoan`) của hệ thống Quản lý văn bản điện tử (e-Office), giúp người dùng hiểu rõ cách sử dụng và quy trình nghiệp vụ.

---

## 1. Giới thiệu

Màn hình **Tài khoản ký số cá nhân** dùng để mỗi cán bộ **tự khai báo tài khoản ký số của riêng mình** trên hệ thống e-Office, làm nền tảng để có thể **ký số các văn bản điện tử** (văn bản đi, văn bản dự thảo) sau này. Mỗi tài khoản đăng nhập có một cấu hình ký số riêng, **không nhìn thấy và không ảnh hưởng** đến cấu hình của người khác.

Khác với chữ ký số dạng USB Token, Smart Card cắm trực tiếp vào máy tính, hệ thống e-Office hiện tại tích hợp **dịch vụ ký số từ xa (ký số trên nền tảng đám mây — remote signing)** thông qua hai nhà cung cấp dịch vụ chứng thực:

- **SmartCA VNPT** — dịch vụ ký số cá nhân của VNPT.
- **MySign Viettel** — dịch vụ ký số cá nhân của Viettel.

Tại mỗi thời điểm, **Quản trị viên chỉ kích hoạt một trong hai nhà cung cấp** ở màn hình **Ký số > Cấu hình ký số (cấp đơn vị)**. Người dùng cuối khai báo tài khoản theo đúng nhà cung cấp đang hoạt động đó. Nếu Quản trị viên chưa kích hoạt nhà cung cấp nào, màn hình này sẽ hiện thông báo nhắc liên hệ Quản trị viên.

Việc khai báo bao gồm 2 bước cốt lõi:

1. **Lưu cấu hình** — nhập **Mã định danh** đã đăng ký với nhà cung cấp dịch vụ (và chọn **Chứng thư số** nếu là MySign Viettel).
2. **Xác thực tài khoản ký số** — bấm nút để hệ thống gọi sang nhà cung cấp dịch vụ kiểm tra xem mã định danh có hợp lệ không, đồng thời lấy về thông tin chứng thư số (chủ thể, số serial). Sau khi xác thực thành công, tài khoản mới sẵn sàng dùng để ký số văn bản.

---

## 2. Bố cục màn hình

![Màn hình Tài khoản ký số cá nhân](screenshots/ky_so_tai_khoan_01_main.png)

Màn hình chia thành các khu vực sau (chỉ hiển thị khi Quản trị viên đã kích hoạt nhà cung cấp dịch vụ):

- **Phần đầu trang**: Tiêu đề **"Tài khoản ký số cá nhân"** kèm biểu tượng chứng thư bảo mật, dòng mô tả ngắn *"Cấu hình tài khoản ký số của bạn theo nhà cung cấp dịch vụ mà hệ thống đang sử dụng."*.
- **Khung thông báo Provider đang hoạt động**: Một dải thông báo (màu xanh dương, biểu tượng `i`) hiển thị tên nhà cung cấp đang được hệ thống sử dụng (ví dụ *"Provider đang hoạt động: SmartCA VNPT"*) kèm địa chỉ máy chủ (URL gốc) bên cạnh và nút **Làm mới** (biểu tượng mũi tên xoay) ở góc phải để tải lại trạng thái cấu hình.
- **Thẻ "Cấu hình tài khoản"**:
  - Tiêu đề thẻ kèm **nhãn trạng thái xác thực**:
    - **Đã xác thực** (nhãn xanh lá, biểu tượng dấu tích) — khi đã xác thực thành công.
    - **Chưa xác thực** (nhãn vàng cam, biểu tượng cảnh báo) — khi chưa xác thực hoặc cấu hình mới được lưu lại.
  - Góc trên bên phải thẻ hiện dòng *"Xác thực gần nhất: ..."* (chỉ khi đã xác thực).
  - **Biểu mẫu nhập Mã định danh** (và chọn Chứng thư số nếu là MySign).
  - **Khối thông tin chứng thư đã xác thực** — bảng nhỏ hiện *Chủ thể chứng thư* và *Số serial* (chỉ hiện khi đã xác thực).
  - **Hai nút thao tác** ở dưới cùng: **Lưu cấu hình** (màu xanh đậm) và **Xác thực tài khoản ký số**.

**Khi Quản trị viên chưa kích hoạt nhà cung cấp dịch vụ**: Toàn bộ thẻ Cấu hình bị thay bằng một khung cảnh báo màu vàng cam *"Hệ thống chưa kích hoạt provider ký số"* kèm hướng dẫn liên hệ Quản trị viên và nút **Làm mới**.

---

## 3. Các trường nhập liệu trong biểu mẫu

Các trường thay đổi tùy theo nhà cung cấp dịch vụ đang hoạt động.

### 3.1. Khi nhà cung cấp là SmartCA VNPT

| Tên trường | Bắt buộc | Mô tả & ràng buộc |
|---|---|---|
| **Mã định danh SmartCA** | Có | Số CMND/CCCD hoặc Mã định danh đã đăng ký với VNPT SmartCA. Tối đa 200 ký tự. Có biểu tượng dấu hỏi để rê chuột xem chú thích. Ô nhập có placeholder gợi ý *"Ví dụ: 012345678901"*. Nếu để trống khi bấm Lưu, hệ thống báo *"Vui lòng nhập Mã định danh SmartCA"*. |

> Với SmartCA VNPT, **không cần chọn Chứng thư số** — hệ thống tự lấy chứng thư khi xác thực (mỗi mã định danh thường chỉ có một chứng thư).

### 3.2. Khi nhà cung cấp là MySign Viettel

| Tên trường | Bắt buộc | Mô tả & ràng buộc |
|---|---|---|
| **Mã định danh MySign** | Có | Mã định danh cá nhân đã đăng ký với Viettel MySign (do Viettel cấp). Tối đa 200 ký tự. Có biểu tượng dấu hỏi để rê chuột xem chú thích. Ô nhập có placeholder gợi ý *"Ví dụ: CMT_123456"*. Nếu để trống khi bấm Lưu, hệ thống báo *"Vui lòng nhập Mã định danh MySign"*. |
| **Chứng thư số** | Có | Danh sách chọn (Select). Mặc định bị **vô hiệu hóa** với placeholder *"Bấm 'Tải danh sách chứng thư' để chọn"*. Sau khi bấm nút **Tải danh sách chứng thư từ MySign**, danh sách được điền đầy với các tùy chọn theo dạng *"<Chủ thể chứng thư> (hết hạn: DD/MM/YYYY)"*. Bắt buộc chọn một chứng thư trước khi Lưu cấu hình. Nếu chưa chọn, hệ thống báo *"Vui lòng chọn chứng thư số"*. |

> Với MySign Viettel, một mã định danh có thể gắn với **nhiều chứng thư số**, nên người dùng phải tự chọn một chứng thư cụ thể.

### 3.3. Khối thông tin chứng thư (chỉ đọc, hiển thị sau khi đã xác thực)

| Tên hiển thị | Nội dung |
|---|---|
| **Chủ thể chứng thư** | Chuỗi định danh chủ sở hữu chứng thư (ví dụ: `CN=Nguyễn Văn A, OU=..., O=..., C=VN`). Hiển thị bằng phông chữ máy in (monospace). |
| **Số serial** | Số serial của chứng thư số (chuỗi mã hex). Hiển thị bằng phông chữ máy in. |

---

## 4. Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| **Làm mới** (biểu tượng mũi tên xoay) | Góc trên bên phải dải thông báo Provider đang hoạt động | Khi đã có nhà cung cấp dịch vụ đang hoạt động | Tải lại trạng thái cấu hình từ máy chủ. Dùng khi nghi ngờ dữ liệu chưa cập nhật, hoặc sau khi Quản trị viên đổi nhà cung cấp. |
| **Làm mới** (biểu tượng mũi tên xoay) | Trong khung cảnh báo "Hệ thống chưa kích hoạt provider ký số" | Khi chưa có nhà cung cấp dịch vụ nào kích hoạt | Tải lại trạng thái — dùng để kiểm tra lại sau khi Quản trị viên vừa kích hoạt nhà cung cấp dịch vụ. |
| **Tải danh sách chứng thư từ MySign** (biểu tượng mũi tên xoay) | Bên trong biểu mẫu, ngay dưới ô Mã định danh | Chỉ hiển thị khi nhà cung cấp dịch vụ là **MySign Viettel** | Gọi sang MySign để lấy danh sách các chứng thư số của mã định danh đã nhập, đổ vào danh sách chọn **Chứng thư số**. **Phải nhập Mã định danh trước khi bấm.** |
| **Lưu cấu hình** (màu xanh đậm, biểu tượng đĩa lưu) | Cuối thẻ Cấu hình tài khoản | Luôn hiển thị khi có biểu mẫu | Lưu Mã định danh (và Chứng thư số nếu là MySign) lên hệ thống. **Sau khi lưu, trạng thái sẽ trở về Chưa xác thực**, người dùng cần bấm tiếp nút Xác thực. |
| **Xác thực tài khoản ký số** (biểu tượng dấu tích) | Cuối thẻ Cấu hình tài khoản, bên phải nút Lưu | Luôn hiển thị | Gọi sang nhà cung cấp dịch vụ để kiểm tra Mã định danh có hợp lệ không, đồng thời lấy về thông tin chứng thư (chủ thể, số serial) để hiển thị. **Bị vô hiệu hóa khi người dùng chưa lưu cấu hình lần nào**, và có chú thích *"Vui lòng lưu cấu hình trước khi xác thực"*. |

---

## 5. Quy trình thao tác chính

### 5.1. Trường hợp 1 — Hệ thống chưa kích hoạt nhà cung cấp dịch vụ

1. Mở menu **Ký số > Tài khoản ký số cá nhân**.
2. Màn hình hiển thị khung cảnh báo màu vàng cam *"Hệ thống chưa kích hoạt provider ký số"* kèm dòng hướng dẫn *"Vui lòng liên hệ Quản trị viên để cấu hình và kích hoạt nhà cung cấp dịch vụ ký số."*.
3. Liên hệ Quản trị viên đề nghị kích hoạt một nhà cung cấp dịch vụ tại màn hình **Ký số > Cấu hình ký số (cấp đơn vị)**.
4. Sau khi Quản trị viên đã kích hoạt, bấm nút **Làm mới** (biểu tượng mũi tên xoay) trên cùng khung cảnh báo. Khi nhà cung cấp đã sẵn sàng, biểu mẫu cấu hình sẽ hiện ra.

### 5.2. Trường hợp 2 — Khai báo tài khoản với SmartCA VNPT

1. Mở menu **Ký số > Tài khoản ký số cá nhân**.
2. Trên dải thông báo, kiểm tra **Provider đang hoạt động** ghi *"SmartCA VNPT"*.
3. Nhập **Mã định danh SmartCA** (số CMND/CCCD hoặc Mã định danh đã đăng ký với VNPT SmartCA).
4. Bấm **Lưu cấu hình**.
5. Hệ thống hiển thị thông báo *"Lưu cấu hình thành công. Vui lòng bấm 'Xác thực tài khoản ký số' để kiểm tra."*. Nhãn trạng thái chuyển về **Chưa xác thực**.
6. Bấm **Xác thực tài khoản ký số**.
7. Nếu chứng thư hợp lệ, hệ thống thông báo *"Kiểm tra thành công — chứng thư hợp lệ"*. Nhãn trạng thái chuyển sang **Đã xác thực** (xanh lá), khối thông tin Chủ thể chứng thư và Số serial xuất hiện, dòng *"Xác thực gần nhất: ..."* hiển thị thời điểm vừa xác thực.

![Đã xác thực thành công](screenshots/ky_so_tai_khoan_02_verified.png)

### 5.3. Trường hợp 3 — Khai báo tài khoản với MySign Viettel

1. Mở menu **Ký số > Tài khoản ký số cá nhân**.
2. Trên dải thông báo, kiểm tra **Provider đang hoạt động** ghi *"MySign Viettel"*.
3. Nhập **Mã định danh MySign** (do Viettel cấp).
4. Bấm **Tải danh sách chứng thư từ MySign**:
   - Nếu chưa nhập Mã định danh, hệ thống báo dưới ô nhập *"Vui lòng nhập Mã định danh trước"*.
   - Nếu MySign trả về danh sách chứng thư, hệ thống thông báo *"Đã tải N chứng thư số"* và đổ danh sách vào ô **Chứng thư số**.
   - Nếu mã định danh không có chứng thư nào, hệ thống thông báo *"Không tìm thấy chứng thư nào cho mã định danh này"*.
5. Mở ô **Chứng thư số** và chọn một chứng thư phù hợp (mỗi mục hiển thị Chủ thể chứng thư kèm hạn sử dụng).
6. Bấm **Lưu cấu hình** → thông báo *"Lưu cấu hình thành công..."*. Nhãn trạng thái về **Chưa xác thực**.
7. Bấm **Xác thực tài khoản ký số** → thông báo *"Kiểm tra thành công — chứng thư hợp lệ"*. Nhãn trạng thái chuyển sang **Đã xác thực**.

![Tải danh sách chứng thư MySign](screenshots/ky_so_tai_khoan_03_mysign_certs.png)

### 5.4. Cập nhật lại Mã định danh hoặc đổi Chứng thư số

1. Mở lại màn hình **Ký số > Tài khoản ký số cá nhân**.
2. Sửa thông tin Mã định danh, hoặc (với MySign) bấm lại **Tải danh sách chứng thư từ MySign** rồi chọn lại chứng thư khác.
3. Bấm **Lưu cấu hình**. Hệ thống thông báo *"Lưu cấu hình thành công..."* và **đặt lại trạng thái về Chưa xác thực**, cho dù trước đó đã xác thực rồi.
4. Bấm lại **Xác thực tài khoản ký số** để xác thực với cấu hình mới.

> **Quan trọng**: Mỗi lần Lưu cấu hình, hệ thống đều coi như cấu hình mới và yêu cầu xác thực lại. Nếu không xác thực lại, các chức năng ký số có thể không sử dụng được tài khoản này.

---

## 6. Lưu ý / Ràng buộc nghiệp vụ

### 6.1. Mỗi tài khoản người dùng có một cấu hình riêng

Cấu hình ký số trên màn hình này gắn với **tài khoản đăng nhập hiện tại**. Người dùng A không thể nhìn thấy, sửa hoặc xác thực thay cho người dùng B. Hệ thống xác định danh tính dựa vào phiên đăng nhập, do đó luôn an toàn về phía người dùng cuối.

### 6.2. Một tài khoản — một cấu hình theo đúng nhà cung cấp đang hoạt động

Mỗi tài khoản người dùng trên hệ thống e-Office tại **một thời điểm** chỉ cần khai báo cấu hình ký số ứng với **đúng nhà cung cấp dịch vụ mà Quản trị viên đang kích hoạt**. Nếu sau này Quản trị viên đổi sang nhà cung cấp khác, người dùng cần quay lại màn hình này khai báo lại theo nhà cung cấp mới.

### 6.3. Điều kiện cần để có thể ký số văn bản

Tài khoản ký số chỉ được coi là **sẵn sàng** khi nhãn trạng thái trên thẻ Cấu hình hiển thị **Đã xác thực** (màu xanh lá). Nếu trạng thái là **Chưa xác thực**, các chức năng ký số ở các màn hình **Văn bản đi**, **Văn bản dự thảo** có thể không sử dụng được tài khoản này.

### 6.4. Sau khi Lưu cấu hình, BẮT BUỘC phải Xác thực lại

Mỗi lần bấm **Lưu cấu hình**, hệ thống đặt lại trạng thái về **Chưa xác thực**. Đây là cơ chế an toàn để đảm bảo cấu hình mới luôn được kiểm tra với nhà cung cấp dịch vụ trước khi sử dụng. Người dùng cần chủ động bấm **Xác thực tài khoản ký số** sau mỗi lần Lưu.

### 6.5. Nút Xác thực bị vô hiệu hóa khi chưa Lưu lần nào

Khi mở màn hình lần đầu (chưa từng lưu cấu hình nào), nút **Xác thực tài khoản ký số** bị mờ đi và không bấm được. Rê chuột lên sẽ thấy chú thích *"Vui lòng lưu cấu hình trước khi xác thực"*. Sau khi Lưu lần đầu, nút sẽ được kích hoạt.

### 6.6. Với MySign Viettel: PHẢI tải danh sách chứng thư trước khi chọn

Ô **Chứng thư số** mặc định bị vô hiệu hóa với placeholder *"Bấm 'Tải danh sách chứng thư' để chọn"*. Người dùng phải:

1. Nhập **Mã định danh MySign** trước.
2. Bấm **Tải danh sách chứng thư từ MySign** để hệ thống lấy về danh sách thật từ Viettel.
3. Sau đó mới mở được ô chọn chứng thư.

Nếu danh sách trả về rỗng (*"Không tìm thấy chứng thư nào cho mã định danh này"*), kiểm tra lại Mã định danh đã đăng ký đúng chưa, hoặc liên hệ Viettel để xác nhận tình trạng tài khoản.

### 6.7. Thời điểm xác thực gần nhất được ghi lại

Sau mỗi lần xác thực thành công, hệ thống ghi lại thời điểm xác thực và hiển thị ở góc trên bên phải thẻ Cấu hình tài khoản: *"Xác thực gần nhất: DD/MM/YYYY HH:MM"*. Nếu hạn của chứng thư đã sắp hết, người dùng nên xác thực lại định kỳ để bảo đảm cấu hình còn hiệu lực.

### 6.8. Lỗi kết nối đến nhà cung cấp dịch vụ

Khi bấm **Tải danh sách chứng thư từ MySign** hoặc **Xác thực tài khoản ký số**, hệ thống cần gọi sang dịch vụ của VNPT hoặc Viettel. Nếu mạng có sự cố, hoặc dịch vụ phía nhà cung cấp đang gián đoạn, hệ thống sẽ hiển thị thông báo dạng *"Không kết nối được provider: ..."* hoặc *"Không lấy được danh sách chứng thư: ..."*. Trong trường hợp này, thử lại sau ít phút; nếu vẫn không được, liên hệ Quản trị viên để kiểm tra cấu hình kết nối ở cấp đơn vị.

### 6.9. Khi xác thực thất bại nhưng không phải do lỗi mạng

Có những trường hợp hệ thống kết nối được sang nhà cung cấp dịch vụ nhưng không tìm thấy chứng thư khớp:

- Với **MySign Viettel**: chứng thư đã chọn không còn có trong danh sách hiện tại của mã định danh (có thể đã bị thu hồi hoặc hết hạn). Hệ thống thông báo *"Không tìm thấy chứng thư khớp credential_id đã chọn. Vui lòng tải lại danh sách CTS."*.
- Với **SmartCA VNPT**: mã định danh không gắn với chứng thư nào. Hệ thống thông báo *"Không tìm thấy chứng thư nào cho user_id này"*.

Khi gặp các thông báo này, kiểm tra lại Mã định danh, tải lại danh sách chứng thư (với MySign) và xác thực lại.

### 6.10. Bảng tổng hợp các thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Lưu cấu hình thành công | Lưu cấu hình thành công. Vui lòng bấm "Xác thực tài khoản ký số" để kiểm tra. |
| Xác thực thành công | Kiểm tra thành công — chứng thư hợp lệ |
| Tải danh sách chứng thư MySign thành công | Đã tải N chứng thư số |
| Tải danh sách chứng thư MySign nhưng rỗng | Không tìm thấy chứng thư nào cho mã định danh này |
| Bấm Tải danh sách khi chưa nhập Mã định danh | Vui lòng nhập Mã định danh trước |
| Để trống Mã định danh khi Lưu (SmartCA) | Vui lòng nhập Mã định danh SmartCA |
| Để trống Mã định danh khi Lưu (MySign) | Vui lòng nhập Mã định danh MySign |
| Mã định danh quá 200 ký tự | Tối đa 200 ký tự |
| Không chọn Chứng thư số (MySign) | Vui lòng chọn chứng thư số |
| Bấm Xác thực khi chưa Lưu cấu hình lần nào | Vui lòng lưu cấu hình trước khi kiểm tra |
| Xác thực thất bại — không tìm thấy chứng thư khớp (MySign) | Không tìm thấy chứng thư khớp credential_id đã chọn. Vui lòng tải lại danh sách CTS. |
| Xác thực thất bại — không có chứng thư (SmartCA) | Không tìm thấy chứng thư nào cho user_id này |
| Lỗi kết nối đến nhà cung cấp khi xác thực | Không kết nối được provider: <chi tiết> |
| Lỗi kết nối đến nhà cung cấp khi tải danh sách chứng thư | Không lấy được danh sách chứng thư: <chi tiết> |
| Hệ thống chưa kích hoạt nhà cung cấp dịch vụ | Hệ thống chưa kích hoạt provider ký số / Admin chưa kích hoạt provider ký số nào. Vui lòng liên hệ Quản trị viên. |
| Lỗi tải cấu hình | Không tải được cấu hình |
| Lỗi lưu cấu hình | Lưu cấu hình thất bại |

---

*Tài liệu được biên soạn dựa trên hệ thống thực tế đang triển khai. Mọi thắc mắc vui lòng liên hệ với đội phát triển để được hỗ trợ.*
