# Hướng dẫn sử dụng: Văn bản dự thảo

Tài liệu này mô tả đầy đủ các chức năng có trong màn hình **Văn bản dự thảo** của hệ thống Quản lý văn bản điện tử (e-Office), giúp người dùng hiểu rõ cách sử dụng và quy trình nghiệp vụ.

---

## 1. Giới thiệu

**Văn bản dự thảo** là văn bản đang trong giai đoạn **soạn thảo nội bộ** — đã được biên tập, có thể đã được gắn file đính kèm, đã được gửi cho lãnh đạo cho ý kiến, nhưng **chưa được phát hành chính thức** ra bên ngoài. Khi nội dung dự thảo đã được lãnh đạo duyệt và phát hành, hệ thống sẽ **tự động tạo một Văn bản đi tương ứng** (kèm theo các file đính kèm), từ đó văn bản mới chính thức bước vào luồng phát hành ra ngoài đơn vị.

Vòng đời điển hình của một văn bản dự thảo gồm các bước chính:

1. **Soạn thảo** — Cán bộ soạn thảo nhập thông tin văn bản, đính kèm file, ghi chú nơi nhận.
2. **Trình duyệt / Gửi cho lãnh đạo** — Cán bộ gửi văn bản dự thảo cho lãnh đạo (hoặc đồng nghiệp) để xem xét.
3. **Cho ý kiến** — Lãnh đạo có thể ghi ý kiến, yêu cầu chỉnh sửa.
4. **Duyệt / Từ chối** — Lãnh đạo bấm **Duyệt** (đồng ý) hoặc **Từ chối** (kèm lý do). Có thể **Hủy duyệt** để mở khóa cho cán bộ sửa lại.
5. **Ký số** (tùy chọn) — Lãnh đạo có thể ký số trực tiếp lên file PDF đính kèm trước khi phát hành.
6. **Phát hành** — Sau khi đã duyệt, lãnh đạo bấm **Phát hành** để tạo văn bản đi chính thức.
7. **Thu hồi** (khi cần) — Trước khi phát hành, có thể thu hồi để xóa người nhận và trở về trạng thái chưa duyệt.

Mọi cán bộ trong đơn vị đều có thể truy cập màn hình Văn bản dự thảo, nhưng các nút thao tác (Sửa, Duyệt, Phát hành, Gửi…) chỉ hiển thị tùy theo **vai trò** (cán bộ soạn / cán bộ xử lý / lãnh đạo) và **trạng thái** hiện tại của văn bản.

---

## 2. Bố cục màn hình Danh sách

![Màn hình danh sách Văn bản dự thảo](screenshots/van_ban_du_thao_01_main.png)

Màn hình danh sách được chia thành các phần sau:

- **Phần đầu trang**: Tiêu đề "Văn bản dự thảo" cùng cụm 3 nút bên phải:
  - **Xuất Excel** — tải danh sách hiện tại theo bộ lọc đang chọn về file `.xlsx`.
  - **In** — kích hoạt hộp thoại in của trình duyệt (in danh sách dạng bảng đơn giản).
  - **Thêm mới** (nút màu xanh navy, biểu tượng dấu cộng) — mở cửa sổ tạo dự thảo mới.
- **Thanh bộ lọc** (ngay dưới tiêu đề): Ô tìm kiếm và các bộ lọc nhanh.
- **Bảng danh sách văn bản dự thảo**: Mỗi dòng là một văn bản, có nút thao tác **ba chấm dọc** ở cột cuối.
- **Cửa sổ phụ (Drawer)** — mở từ bên phải khi bấm **Thêm mới** hoặc **Sửa**.
- **Hộp xác nhận (Modal)** — mở khi thực hiện các thao tác Duyệt, Từ chối, Phát hành, Thu hồi, Xóa.

---

## 3. Bộ lọc và ô tìm kiếm

| Bộ lọc | Vị trí | Mô tả |
|---|---|---|
| **Tìm kiếm** | Đầu thanh bộ lọc | Ô tìm kiếm theo trích yếu, ký hiệu, người ký, nơi nhận. Bấm Enter hoặc biểu tượng kính lúp để áp dụng. Có nút xóa nhanh. |
| **Phòng ban** | (chỉ Quản trị viên) | Ô chọn dạng cây, lọc văn bản theo phòng ban. Có ô tìm kiếm trong cây. |
| **Sổ văn bản** | Thanh bộ lọc | Lọc theo sổ văn bản dự thảo (loại sổ = 3). |
| **Loại văn bản** | Thanh bộ lọc | Lọc theo loại văn bản (Quyết định, Công văn, Tờ trình…). |
| **Trạng thái** | Thanh bộ lọc | Hai giá trị: **Đã phát hành** / **Chưa phát hành**. |
| **Độ khẩn** | Thanh bộ lọc | Thường / Khẩn / Hỏa tốc. |
| **Khoảng ngày** | Thanh bộ lọc | Chọn khoảng ngày soạn (Từ ngày — Đến ngày), định dạng `DD/MM/YYYY`. |
| **Xóa bộ lọc** (biểu tượng vòng tròn quay) | Cuối thanh bộ lọc | Đặt lại tất cả bộ lọc và ô tìm kiếm về trạng thái mặc định. |

> Khi đổi bất kỳ bộ lọc nào, bảng tự động tải lại và quay về trang 1.

---

## 4. Các cột trong Bảng danh sách

| Cột | Mô tả |
|---|---|
| **Số** | Số văn bản (số đăng ký theo sổ). Hiển thị in đậm. |
| **Số phụ** | Số phụ kèm theo (`a`, `b`, `bis`…) nếu có. |
| **Ký hiệu** | Ký hiệu văn bản (VD: `123/UBND-VP`). |
| **Trích yếu** | Tóm tắt nội dung văn bản. Bấm vào trích yếu để mở chi tiết. Nếu văn bản đã được người khác **gửi cho mình**, có thêm nhãn `Gửi cho tôi` màu vàng kèm tooltip "Do … gửi lúc …". Dòng văn bản chưa đọc dành cho người nhận sẽ có vạch màu cam ở mép trái. |
| **Đơn vị soạn** | Tên đơn vị / phòng ban soạn văn bản. |
| **Người soạn** | Tên cán bộ trực tiếp soạn văn bản. |
| **Loại VB** | Loại văn bản. |
| **Trạng thái** | Một trong 4 nhãn: **Đã phát hành** (xanh lá), **Đã duyệt** (xanh dương), **Từ chối** (đỏ), **Dự thảo** (vàng). Xem chi tiết ở mục 5. |
| (cột thao tác) | Nút **ba chấm dọc** mở menu các lệnh tương ứng với trạng thái + quyền của người dùng (xem mục 9). |

Phía dưới bảng có dòng tổng "Tổng N văn bản" và bộ chuyển trang. Có thể chọn 10 / 20 / 50 / 100 văn bản trên một trang.

---

## 5. Bảng trạng thái

Trạng thái văn bản dự thảo được tính từ **3 cờ** trên bản ghi: `approved` (đã duyệt), `is_released` (đã phát hành), và `rejected_by` (có bị từ chối hay không). Cụ thể:

| Nhãn trạng thái | Màu nhãn | Ý nghĩa |
|---|---|---|
| **Dự thảo** | vàng | Mới tạo, chưa được duyệt, chưa bị từ chối — đang trong quá trình soạn thảo / chờ trình duyệt. |
| **Từ chối** | đỏ | Lãnh đạo đã từ chối. Cán bộ có thể tiếp tục sửa và trình lại; khi duyệt lại, cờ từ chối sẽ được xóa. |
| **Đã duyệt** | xanh dương | Lãnh đạo đã duyệt, văn bản đang chờ phát hành (hoặc chờ ký số). |
| **Đã phát hành** | xanh lá | Đã phát hành ra văn bản đi. Văn bản trở thành **chỉ đọc** — không sửa, không xóa, không thu hồi được nữa. |

Ngoài ra, ở phần đầu trang chi tiết có thể xuất hiện thêm các nhãn phụ:

- **Khẩn** / **Hỏa tốc** (cam / đỏ) — khi độ khẩn lớn hơn "Thường".
- **Mật** / **Tối mật** / **Tuyệt mật** (cam / đỏ / volcano) — khi độ mật lớn hơn "Thường".
- **Quá hạn** (đỏ) — khi đã qua "Hạn xử lý" mà chưa phát hành.

---

## 6. Bố cục màn hình Chi tiết

![Màn hình chi tiết Văn bản dự thảo](screenshots/van_ban_du_thao_02_detail.png)

Màn hình chi tiết được chia làm 3 phần:

- **Thanh tiêu đề (Header)** — phía trên cùng:
  - Nút **mũi tên trái** quay về danh sách.
  - Dòng tiêu đề "Số: [số]/[số phụ] — [ký hiệu]" và dòng phụ "[Đơn vị soạn] • Người soạn: …".
  - Các nhãn trạng thái và nhãn độ khẩn / độ mật (nếu có).
  - Nếu đang ở trạng thái **Từ chối**, một dải đỏ ngay dưới hiển thị **lý do từ chối**.
  - **Cụm nút thao tác** bên phải: nút **ngôi sao** (đánh dấu cá nhân) + các nút theo trạng thái (xem mục 9).
- **Cột trái** — chứa 3 thẻ thông tin xếp dọc:
  - **Trích yếu nội dung** (viền teal bên trái).
  - **Thông tin văn bản dự thảo** (block thông tin chi tiết — xem mục 7.1).
  - **Tài liệu đính kèm** — danh sách file kèm các nút Tải lên / Tải xuống / Ký số / Xóa (xem mục 7.2).
- **Cột phải** — chứa 3 thẻ thông tin xếp dọc:
  - **Người nhận** — danh sách cán bộ đã được gửi văn bản (xem mục 7.3).
  - **Ý kiến lãnh đạo** — danh sách ý kiến và ô gửi ý kiến mới (xem mục 7.4).
  - **Lịch sử xử lý** — timeline các sự kiện trên văn bản (xem mục 7.5).

---

## 7. Các thẻ thông tin trên màn hình Chi tiết

### 7.1. Thẻ "Thông tin văn bản dự thảo"

Hiển thị các thuộc tính của văn bản dạng nhãn–giá trị, gồm:

- **Số văn bản** (kèm số phụ nếu có), **Số ký hiệu**.
- **Sổ văn bản**, **Loại văn bản**.
- **Đơn vị soạn**, **Người soạn**, **Đơn vị phát hành**.
- **Lĩnh vực**, **Ngày ban hành**.
- **Người ký**, **Ngày ký**.
- **Hạn xử lý** (chữ đỏ + nhãn **Quá hạn** nếu đã trễ), **Nơi nhận**, **Người duyệt** (kèm thời điểm duyệt nếu đã duyệt).
- **Lý do từ chối** (chỉ hiển thị khi văn bản bị từ chối).
- **Độ mật**, **Độ khẩn** (dạng nhãn).
- **Số tờ / Số bản**, **Trạng thái phát hành** (nhãn "Đã phát hành — [ngày]" hoặc "Chưa phát hành").
- Phần dưới cùng: **Người nhập** và **Thời gian tạo**.

> Các trường có giá trị rỗng được hiển thị bằng dấu `—`.

### 7.2. Thẻ "Tài liệu đính kèm"

Hiển thị danh sách file đính kèm của văn bản dự thảo. Tiêu đề thẻ kèm số lượng — VD: "Tài liệu đính kèm (3)".

**Mỗi file** gồm: biểu tượng theo định dạng (PDF / Word / Excel / Ảnh / khác), tên file, kích cỡ, thời gian tải lên. Bên phải có các nút:

- **Đã ký số** (nhãn xanh, có dấu tick) — hiển thị khi file đã được ký số.
- **Ký số** (nút xanh có viền) — hiển thị khi file **chưa** được ký số. Bấm để mở cửa sổ ký số (sử dụng dịch vụ ký số đã cấu hình sẵn). Cửa sổ tự gửi sẵn lý do "Phê duyệt VB dự thảo số [số]/[ký hiệu]" và vị trí ký theo đơn vị soạn.
- **Tải xuống** (biểu tượng mũi tên xuống).
- **Xóa** (biểu tượng thùng rác, màu đỏ) — chỉ hiển thị khi văn bản **chưa phát hành** và người dùng có quyền sửa. Có hộp xác nhận trước khi xóa.

**Nút "Thêm file"** ở góc trên bên phải thẻ — chỉ hiển thị khi văn bản **chưa phát hành** và người dùng có quyền sửa. Bấm để chọn file từ máy. Sau khi tải lên thành công, hệ thống thông báo "Tải lên thành công".

### 7.3. Thẻ "Người nhận"

Hiển thị danh sách cán bộ đã được **gửi** văn bản dự thảo này (qua chức năng "Gửi" — xem mục 9). Tiêu đề thẻ kèm số lượng — VD: "Người nhận (5)".

Mỗi người nhận hiển thị: ảnh đại diện, **họ tên**, **chức vụ • phòng ban**, và trạng thái đọc:

- **Đã đọc lúc HH:mm DD/MM** (xanh lá) — nếu đã mở văn bản.
- **Chưa đọc** (cam) — nếu chưa mở.

Nếu chưa gửi cho ai, hiển thị "Chưa gửi cho ai".

### 7.4. Thẻ "Ý kiến lãnh đạo"

Nơi các cán bộ (đặc biệt là lãnh đạo) ghi **ý kiến** lên văn bản dự thảo. Tiêu đề thẻ kèm số lượng ý kiến.

- Mỗi ý kiến hiển thị trên nền vàng nhạt, gồm: tên người gửi (kèm chức vụ nếu có), nội dung, thời gian.
- Người tự gửi ý kiến của mình thấy nút **xóa** (thùng rác) ở góc — bấm có hộp xác nhận "Xóa ý kiến?" trước khi thực sự xóa.
- Phía dưới có ô **Nhập ý kiến…** và nút **Gửi ý kiến** (mặc định bị mờ, chỉ kích hoạt khi có nội dung).

> Trong giao diện cũ tài liệu có lúc dùng từ "Ý kiến / Comments" — trên hệ thống hiện tại nhãn chính thức là **Ý kiến lãnh đạo**.

### 7.5. Thẻ "Lịch sử xử lý"

Timeline (cột thời gian) các sự kiện trên văn bản, mỗi điểm có màu khác nhau theo loại sự kiện:

| Loại sự kiện | Mô tả | Màu chấm |
|---|---|---|
| **created** | Tạo văn bản dự thảo, kèm số văn bản | xanh dương |
| **approved** | Duyệt văn bản dự thảo | xanh lá |
| **sent** | Nhận văn bản (xuất hiện cho mỗi người nhận) | xanh ngọc (cyan) |
| **released** | Phát hành thành văn bản đi | tím |
| **rejected** | Từ chối | đỏ |
| (khác) | Sự kiện khác | xám |

Mỗi sự kiện hiển thị: nội dung mô tả, tên người thực hiện, thời điểm (`DD/MM/YYYY HH:mm`). Sắp xếp theo thời gian giảm dần (mới nhất ở trên).

---

## 8. Nhãn "Đánh dấu cá nhân" (ngôi sao)

Nút **ngôi sao** ở thanh tiêu đề chi tiết cho phép cán bộ tự đánh dấu một văn bản dự thảo cần chú ý. Bấm một lần để **đánh dấu** (sao chuyển vàng), bấm lần nữa để **bỏ đánh dấu**. Đây là nhãn cá nhân — chỉ chính người đánh dấu thấy. Có thể xem lại danh sách văn bản đã đánh dấu trong mục **Văn bản đã đánh dấu** (tham khảo HDSD riêng cho mục đó).

---

## 9. Các nút thao tác theo trạng thái

Cụm nút thao tác trên thanh tiêu đề (và trong menu **ba chấm dọc** trên dòng bảng danh sách) **hiển thị khác nhau theo trạng thái** kết hợp với **quyền** của người dùng. Một nút được phép hiện ra khi và chỉ khi cả 2 điều kiện đều đúng.

### 9.1. Quyền (do hệ thống tự tính)

Hệ thống tính 5 quyền cho mỗi văn bản, dựa trên: **vai trò Quản trị viên**, **người soạn của văn bản**, **đơn vị**, và **chức vụ** (`is_leader` — lãnh đạo, `is_handle_document` — cán bộ xử lý văn bản):

| Quyền | Khi nào có |
|---|---|
| **canEdit** (sửa) | Là Quản trị viên, **HOẶC** là người soạn của văn bản, **HOẶC** cùng đơn vị và là cán bộ xử lý văn bản. |
| **canApprove** (duyệt / từ chối / hủy duyệt) | Là Quản trị viên, **HOẶC** cùng đơn vị và là lãnh đạo. |
| **canRelease** (phát hành) | Là Quản trị viên, **HOẶC** cùng đơn vị và là lãnh đạo. |
| **canSend** (gửi cho người khác) | Là Quản trị viên, **HOẶC** là người soạn, **HOẶC** cùng đơn vị và là lãnh đạo. |
| **canRetract** (thu hồi) | Là Quản trị viên, **HOẶC** cùng đơn vị và là lãnh đạo. |

> "Cùng đơn vị" được tính theo **đơn vị cấp cao nhất (đơn vị tổ chức)** mà người dùng và văn bản thuộc về — không phải theo phòng ban. Vì vậy lãnh đạo của một Sở có thể thao tác trên văn bản của các phòng ban thuộc Sở đó.

### 9.2. Bảng nút theo trạng thái — màn Chi tiết

Khi văn bản **chưa duyệt và chưa phát hành** (Dự thảo / Từ chối):

| Nút | Khi nào hiển thị | Tác dụng |
|---|---|---|
| **Sửa** (biểu tượng bút) | Có quyền `canEdit` | Quay về danh sách và mở Drawer sửa với dữ liệu hiện có. |
| **Duyệt** (nút xanh, dấu tick) | Có quyền `canApprove` | Mở hộp xác nhận "Duyệt văn bản dự thảo …?". Xác nhận → đặt cờ `approved=TRUE`, ghi tên người duyệt + thời điểm, xóa cờ từ chối nếu đang có. |
| **Từ chối** (trong menu ba chấm, nhãn đỏ) | Có quyền `canApprove` và văn bản chưa bị từ chối | Mở Modal "Từ chối văn bản dự thảo" — cho phép nhập **lý do** (không bắt buộc). Lưu cờ từ chối và lý do. |
| **Xóa văn bản** (trong menu ba chấm, nhãn đỏ) | Có quyền `canEdit` | Mở hộp xác nhận "Xóa văn bản dự thảo này?". Xác nhận → xóa hẳn văn bản và quay về danh sách. |

Khi văn bản **đã duyệt nhưng chưa phát hành**:

| Nút | Khi nào hiển thị | Tác dụng |
|---|---|---|
| **Phát hành** (nút xanh lá, biểu tượng tên lửa) | Có quyền `canRelease` | Mở hộp xác nhận "Phát hành văn bản …?" kèm cảnh báo "Sau khi phát hành sẽ không thể sửa hoặc xóa". Xác nhận → tạo văn bản đi mới, copy đính kèm, đánh dấu dự thảo `is_released=TRUE`. Hệ thống hiển thị thông báo "Phát hành thành công, đã tạo văn bản đi #..." kèm 2 nút: **Xem văn bản đi** (chuyển trang) hoặc **Ở lại trang này**. |
| **Gửi** (nút xanh, biểu tượng máy bay giấy) | Có quyền `canSend` | Mở Modal "Gửi văn bản dự thảo" — danh sách cán bộ trong đơn vị (gom nhóm theo phòng ban). Tích chọn nhiều người, có hộp **Chọn tất cả**. Bấm **Gửi (N)** để gửi. |
| **Hủy duyệt** (trong menu ba chấm) | Có quyền `canApprove` | Mở hộp xác nhận. Xác nhận → đặt `approved=FALSE`, xóa người duyệt — văn bản trở lại trạng thái Dự thảo để có thể sửa lại. |
| **Thu hồi** (trong menu ba chấm) | Có quyền `canRetract` | Mở hộp xác nhận "Thu hồi sẽ xóa tất cả người nhận và đặt lại trạng thái chưa duyệt. Bạn chắc chắn?". Xác nhận → xóa toàn bộ bản ghi gửi và đặt lại `approved=FALSE`. |

Khi văn bản **đã phát hành**:

- Không còn nút thao tác — chỉ hiển thị nhãn xanh "**Đã phát hành ngày DD/MM/YYYY**" thay cho cụm nút.

### 9.3. Bảng nút theo trạng thái — màn Danh sách (menu ba chấm)

Trên dòng bảng danh sách, menu ba chấm gom các thao tác tương đương vào dạng danh sách. Trình tự xuất hiện:

1. **Xem chi tiết** (luôn có) — mở chi tiết văn bản.
2. **Sửa** — khi `canEdit` + văn bản chưa duyệt + chưa phát hành.
3. **Duyệt** — khi `canApprove` + văn bản chưa duyệt + chưa phát hành.
4. **Từ chối** — cùng điều kiện với Duyệt, và văn bản chưa bị từ chối.
5. **Phát hành** — khi `canRelease` + đã duyệt + chưa phát hành.
6. **Hủy duyệt** — khi `canApprove` + đã duyệt + chưa phát hành.
7. **Thu hồi** — khi `canRetract` + đã duyệt + chưa phát hành.
8. **Xóa** (nhãn đỏ, nằm cuối, có vạch ngăn cách phía trên) — khi `canEdit` + văn bản chưa duyệt + chưa phát hành.

> Nếu văn bản đã phát hành, chỉ còn lệnh **Xem chi tiết** trong menu.

---

## 10. Cửa sổ Thêm mới / Sửa văn bản dự thảo

Bấm **Thêm mới** ở danh sách (hoặc **Sửa** trên một văn bản) để mở Drawer phía bên phải. Tiêu đề Drawer thay đổi theo ngữ cảnh: "Thêm văn bản dự thảo" hoặc "Sửa văn bản dự thảo".

![Cửa sổ Thêm mới văn bản dự thảo](screenshots/van_ban_du_thao_03_drawer_add.png)

Drawer chứa các trường sau:

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| **Sổ văn bản** | Có | Chọn sổ văn bản dự thảo. Khi chọn xong, hệ thống tự đề xuất **Số** kế tiếp theo sổ (số lớn nhất trong sổ + 1). |
| **Số** | Không | Số văn bản (nguyên ≥ 1). Có thể sửa lại nếu cần. |
| **Số phụ** | Không | Số phụ kèm theo (`a`, `b`, `bis`…). Tối đa 20 ký tự. |
| **Ký hiệu** | Không | Ký hiệu văn bản, VD `123/UBND-VP`. Tối đa 100 ký tự. |
| **Mã văn bản** | Không | Mã nội bộ (nếu có). Tối đa 100 ký tự. |
| **Ngày soạn** | Không | Mặc định là ngày hôm nay khi tạo mới. Định dạng `DD/MM/YYYY`. |
| **Trích yếu nội dung** | Có | Vùng văn bản nhiều dòng. Tối đa 2000 ký tự, có hiển thị bộ đếm. |
| **Đơn vị soạn thảo** | Có | Chọn đơn vị / phòng ban. Khi chọn xong, ô "Người soạn thảo" sẽ tải lại danh sách nhân viên thuộc đơn vị đó. Mặc định là phòng ban / đơn vị của người tạo. |
| **Người soạn thảo** | Có | Chọn người trực tiếp soạn. Khóa khi chưa chọn đơn vị. Mặc định là người tạo. |
| **Đơn vị ban hành** | Không | Đơn vị sẽ đứng tên ban hành văn bản. |
| **Loại văn bản** | Không | Chọn từ danh mục Loại văn bản. |
| **Lĩnh vực** | Không | Chọn từ danh mục Lĩnh vực. |
| **Người ký** | Không | Họ tên người ký dạng văn bản. Tối đa 200 ký tự. |
| **Ngày ký** | Không | Định dạng `DD/MM/YYYY`. |
| **Ngày ban hành** | Không | Định dạng `DD/MM/YYYY`. |
| **Hạn xử lý** | Không | Định dạng `DD/MM/YYYY`. Khi quá hạn, chi tiết văn bản hiển thị nhãn **Quá hạn** màu đỏ. |
| **Độ mật** | Có (mặc định) | Thường / Mật / Tối mật / Tuyệt mật. Mặc định **Thường**. |
| **Độ khẩn** | Có (mặc định) | Thường / Khẩn / Hỏa tốc. Mặc định **Thường**. |
| **Số tờ** | Không | Số nguyên ≥ 0. Mặc định 1. |
| **Số bản** | Không | Số nguyên ≥ 0. Mặc định 1. |
| **Nơi nhận** | Không | Vùng văn bản nhiều dòng, tối đa 2000 ký tự. **Đây chỉ là mô tả dạng chữ.** Sau khi phát hành thành VB đi, nơi nhận chính thức (đơn vị nhận) sẽ được chọn lại trên màn hình **Văn bản đi**. |

**Nút hành động** ở góc trên bên phải Drawer:

- **Hủy** — đóng Drawer, không lưu thay đổi.
- **Tạo mới** / **Cập nhật** — lưu dữ liệu. Nhãn nút thay đổi theo ngữ cảnh Thêm hay Sửa.

> **Lưu ý**: Sau khi đã được duyệt hoặc đã phát hành, văn bản không thể sửa nữa — hệ thống sẽ trả lỗi "Không thể sửa văn bản đã được duyệt" hoặc "Không thể sửa văn bản đã phát hành".

---

## 11. Quy trình thao tác chính

### 11.1. Soạn thảo và trình duyệt

1. Vào **Văn bản dự thảo** → bấm **Thêm mới**.
2. Chọn **Sổ văn bản** (hệ thống tự gợi ý **Số** kế tiếp). Nhập **Trích yếu** (bắt buộc), **Đơn vị soạn**, **Người soạn**, và các thông tin khác.
3. Bấm **Tạo mới**. Hệ thống thông báo "Tạo văn bản dự thảo thành công" và đóng Drawer.
4. Mở chi tiết văn bản vừa tạo. Trong thẻ **Tài liệu đính kèm**, bấm **Thêm file** để tải file Word/PDF nội dung dự thảo lên.
5. Bấm **Gửi** (nếu có quyền) → mở Modal **Gửi văn bản dự thảo** → chọn lãnh đạo (và các đồng nghiệp cần xem) → bấm **Gửi**.
6. Người nhận sẽ thấy văn bản trong danh sách của họ với nhãn **Gửi cho tôi**.

### 11.2. Lãnh đạo cho ý kiến / duyệt / từ chối

1. Lãnh đạo mở văn bản, đọc nội dung và file đính kèm.
2. (Tùy chọn) Trong thẻ **Ý kiến lãnh đạo**, nhập nội dung góp ý → bấm **Gửi ý kiến**.
3. Quyết định:
   - **Đồng ý** → bấm **Duyệt** trên thanh tiêu đề. Hệ thống ghi tên người duyệt + thời điểm, xóa cờ từ chối nếu có. Trạng thái chuyển sang **Đã duyệt**.
   - **Không đồng ý** → mở menu ba chấm → **Từ chối** → nhập lý do (không bắt buộc) → bấm **Từ chối**. Trạng thái chuyển sang **Từ chối**, cán bộ vẫn có thể sửa lại và trình duyệt lần nữa.

### 11.3. Hủy duyệt để cán bộ chỉnh sửa

Nếu sau khi đã duyệt mà phát hiện cần sửa lại, lãnh đạo bấm **Hủy duyệt** (trong menu ba chấm phụ trên thanh tiêu đề). Văn bản trở lại trạng thái Dự thảo, cán bộ soạn có thể sửa và trình lại.

### 11.4. Ký số file đính kèm (tùy chọn)

Trong thẻ **Tài liệu đính kèm**, bên cạnh mỗi file PDF chưa ký, có nút **Ký số**. Bấm để mở cửa sổ ký số (hệ thống đã điền sẵn lý do "Phê duyệt VB dự thảo số …" và vị trí ký theo đơn vị soạn). Sau khi ký thành công, file được gắn nhãn **Đã ký số** màu xanh.

### 11.5. Phát hành thành Văn bản đi

1. Khi văn bản đã ở trạng thái **Đã duyệt**, lãnh đạo (hoặc Quản trị viên) bấm **Phát hành** trên thanh tiêu đề.
2. Hệ thống mở hộp xác nhận với cảnh báo: "*Phát hành văn bản …? Sau khi phát hành sẽ không thể sửa hoặc xóa.*"
3. Bấm **Phát hành**.
4. Hệ thống tạo một **Văn bản đi** mới với nội dung sao chép từ dự thảo, copy luôn các file đính kèm, đánh dấu dự thảo `Đã phát hành` (kèm ngày phát hành).
5. Hộp thông báo "**Phát hành thành công** — Đã tạo văn bản đi #N từ dự thảo này" hiện ra với 2 lựa chọn:
   - **Xem văn bản đi** — chuyển sang chi tiết văn bản đi vừa tạo.
   - **Ở lại trang này** — vẫn ở chi tiết dự thảo.

> Sau bước này, dự thảo trở thành **chỉ đọc**. Mọi việc tiếp theo (chọn đơn vị nhận, gửi đi liên thông…) thực hiện trên màn **Văn bản đi**.

### 11.6. Thu hồi (trước khi phát hành)

Nếu sau khi đã duyệt và đã gửi cho một số người nhận, nhưng cần dừng và sửa lại, lãnh đạo bấm **Thu hồi** (trong menu ba chấm phụ). Hệ thống xóa **toàn bộ** bản ghi gửi (danh sách "Người nhận" trống) và đặt lại `approved=FALSE`. Văn bản trở về trạng thái Dự thảo.

> Không thu hồi được khi văn bản đã được phát hành — lỗi "Không thể thu hồi — văn bản đã phát hành".

### 11.7. Xóa văn bản dự thảo

Mở menu ba chấm → **Xóa**. Hộp xác nhận hiện ra. Sau khi xác nhận, văn bản và toàn bộ liên kết bị xóa khỏi hệ thống. Chỉ thực hiện được khi văn bản chưa duyệt và chưa phát hành — và người dùng có quyền `canEdit`.

---

## 12. Sơ đồ vòng đời

```
                ┌─────────────┐
                │   Dự thảo   │ ◄─────────────────┐
                └──────┬──────┘                   │
                       │                          │
            ┌──────────┼──────────┐               │
            │          │          │               │
       (Duyệt)    (Từ chối)    (Sửa)              │
            │          │          │               │
            ▼          ▼          ▼               │
     ┌────────────┐ ┌──────┐  ┌─────────┐         │
     │  Đã duyệt  │ │Từ    │  │  Dự     │         │
     │            │ │chối  │  │  thảo   │         │
     └─────┬──────┘ └──┬───┘  └────┬────┘         │
           │           │           │              │
           │       (Sửa &           │              │
           │        Duyệt          │              │
           │        lại)           │              │
   ┌───────┼─────────┐ │           │              │
   │       │         │ │           │              │
(Phát   (Hủy      (Thu  │           │              │
hành)   duyệt)    hồi)  │           │              │
   │       │         │ │           │              │
   ▼       ▼         ▼ ▼           ▼              │
┌──────┐  ─┘─────────┘─┘───────────┘              │
│ Đã   │                                          │
│ phát │      (Hủy duyệt / Thu hồi —              │
│ hành │       trở về Dự thảo)──────────────────┘
└──────┘
   (chỉ đọc, sinh ra Văn bản đi #N)
```

> **Đã phát hành** là trạng thái cuối — không có nút nào đưa văn bản trở lại Dự thảo. Mọi xử lý tiếp theo nằm trên Văn bản đi.

---

## 13. Lưu ý / Ràng buộc nghiệp vụ

### 13.1. Sửa / Xóa chỉ trước khi duyệt và phát hành

- Sau khi đã **Duyệt**, hệ thống không cho sửa nữa (lỗi "Không thể sửa văn bản đã được duyệt"). Nếu cần sửa, dùng **Hủy duyệt** trước.
- Sau khi đã **Phát hành**, hệ thống không cho sửa, không cho xóa, không cho thu hồi (lỗi "Không thể thu hồi — văn bản đã phát hành").

### 13.2. Phát hành chỉ thực hiện khi đã duyệt

Phát hành yêu cầu cờ `approved=TRUE`. Nếu chưa duyệt, hệ thống báo "**Văn bản chưa được duyệt, không thể phát hành**".

### 13.3. Gửi yêu cầu đã duyệt

Chức năng **Gửi** (cho cán bộ trong đơn vị) chỉ hoạt động khi văn bản đã được duyệt — báo "**Văn bản chưa được duyệt, không thể gửi**" nếu chưa.

### 13.4. Trùng người nhận khi gửi

Khi gửi cùng một văn bản nhiều lần cho cùng một người, hệ thống chỉ ghi nhận một bản ghi (không tạo bản trùng). Thông báo trả về "**Đã gửi cho N người nhận**" trong đó N là số người nhận **mới**.

### 13.5. Phạm vi danh sách

- Người dùng thường chỉ thấy văn bản dự thảo của **đơn vị tổ chức** mà mình thuộc về.
- Quản trị viên thấy tất cả, có thêm bộ lọc **Phòng ban** dạng cây.

### 13.6. Định dạng và giới hạn dữ liệu

- **Trích yếu**: tối đa 2000 ký tự, **bắt buộc**.
- **Nơi nhận**: tối đa 2000 ký tự, mô tả dạng chữ (không phải danh sách định danh).
- **Số tờ**, **Số bản**: số nguyên ≥ 0, mặc định 1.
- **Sổ văn bản**: bắt buộc khi tạo và khi sửa.


---

*Tài liệu được biên soạn dựa trên hệ thống thực tế đang triển khai. Mọi thắc mắc vui lòng liên hệ với đội phát triển để được hỗ trợ.*
