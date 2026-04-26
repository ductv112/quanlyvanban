# Hướng dẫn sử dụng: Văn bản đi

Tài liệu này mô tả đầy đủ các chức năng có trong hai màn hình **Văn bản đi (Danh sách)** và **Văn bản đi (Chi tiết)** của hệ thống Quản lý văn bản điện tử (e-Office), giúp người dùng hiểu rõ cách sử dụng và quy trình nghiệp vụ.

---

## 1. Giới thiệu

**Văn bản đi** là toàn bộ các văn bản do cơ quan / đơn vị soạn thảo, ban hành và gửi đến các đơn vị, cá nhân khác — bao gồm gửi nội bộ trong hệ thống và gửi ra ngoài qua trục liên thông LGSP. Đây là một trong ba luồng nghiệp vụ cốt lõi của hệ thống e-Office (cùng với Văn bản đến và Hồ sơ công việc).

Vòng đời điển hình của một văn bản đi gồm các giai đoạn:

1. **Soạn thảo** — cán bộ chuyên môn nhập thông tin văn bản, đính kèm file, chọn nơi nhận (đơn vị nội bộ + cơ quan ngoài qua LGSP).
2. **Trình duyệt** — văn bản đang ở trạng thái "Chờ duyệt", chờ lãnh đạo xem xét.
3. **Lãnh đạo phê duyệt** — bấm Duyệt (đồng ý) / Từ chối (kèm lý do).
4. **Ban hành** — văn thư cấp số văn bản chính thức theo sổ và đặt văn bản ở trạng thái **Đã ban hành**.
5. **Gửi** — hệ thống tự động sinh "Văn bản đến" cho từng đơn vị nội bộ và đẩy lên LGSP cho từng cơ quan ngoài.
6. **Theo dõi** — văn thư xem trạng thái nhận của từng nơi nhận (đã nhận / đang chờ / lỗi LGSP).
7. **Thu hồi (nếu cần)** — xóa toàn bộ người nhận và đặt văn bản về trạng thái chưa duyệt khi phát hiện sai sót.

Cùng văn bản đó, có thể được dùng để **giao việc** (tạo hồ sơ công việc xử lý nội dung văn bản) hoặc **thêm vào một hồ sơ công việc** đã tồn tại để gắn nó vào tập hồ sơ liên quan.

---

## 2. Bố cục màn hình Danh sách

![Màn hình danh sách Văn bản đi](screenshots/van_ban_di_01_main.png)

Màn hình **Văn bản đi** (đường dẫn `/van-ban-di`) gồm 4 phần chính:

- **Thanh tiêu đề** — biểu tượng máy bay giấy + chữ "Văn bản đi" ở góc trên bên trái thẻ dữ liệu, các nút thao tác chung ở góc trên bên phải:
  - **Đánh dấu đã đọc (N)** — chỉ hiện khi đã tích chọn tối thiểu 1 dòng.
  - **Xuất Excel** — tải file `VanBanDi_yyyy-mm-dd.xlsx` chứa danh sách hiện tại.
  - **In** — in danh sách thẳng từ trình duyệt.
  - **Thêm mới** — mở cửa sổ soạn văn bản đi mới.
- **Thanh bộ lọc** — bộ lọc nhanh (xem mục 4).
- **Bảng danh sách** — các văn bản đi (xem mục 3).
- **Cửa sổ phụ (Drawer)** — soạn / sửa văn bản đi mở từ bên phải khi bấm Thêm mới hoặc Sửa.

---

## 3. Các cột trong Bảng Văn bản đi

| Tên cột | Mô tả |
|---|---|
| **Ô chọn** | Tích chọn để đánh dấu đã đọc hàng loạt. |
| **Số đi** | Số đăng ký của văn bản trong sổ. In đậm nếu chưa đọc, in thường nếu đã đọc. |
| **Số phụ** | Số phụ (nếu có) — ví dụ `a`, `b`, `c`. |
| **Ngày đề** | Ngày văn bản (format `DD/MM/YYYY`). |
| **Ký hiệu** | Số ký hiệu văn bản — ví dụ `123/UBND-VP`. |
| **Trích yếu** | Nội dung tóm tắt văn bản (đường dẫn — bấm vào sẽ mở Chi tiết). Nếu văn bản được "Gửi cho tôi" (cá nhân là người nhận), sẽ hiện thẻ vàng cam **📩 Gửi cho tôi** kèm tooltip cho biết ai gửi và vào lúc nào. |
| **Đơn vị soạn** | Tên phòng ban / đơn vị soạn thảo. |
| **Nơi nhận** | Tổng hợp các đơn vị / cơ quan nhận, ngăn cách bởi dấu `;`. |
| **Loại VB** | Tên loại văn bản (ví dụ Công văn, Quyết định). |
| **Trạng thái** | Thẻ màu tương ứng — **Đã duyệt** (xanh lá), **Từ chối** (đỏ), **Chờ duyệt** (vàng). |
| (cột thao tác) | Nút **ba chấm dọc** mở menu các lệnh — Xem chi tiết, Sửa, Duyệt, Từ chối, Hủy duyệt, Thu hồi, Xóa (các lệnh chỉ hiển thị nếu trạng thái cho phép và quyền hiện có). |

Mỗi trang mặc định **20 dòng**. Có thể chuyển 10 / 50 / 100 dòng / trang tại thanh phân trang dưới bảng.

---

## 4. Bộ lọc nhanh phía trên bảng

| Bộ lọc | Hành vi |
|---|---|
| **Tìm kiếm** | Ô tìm kiếm theo trích yếu, ký hiệu — bấm Enter để áp dụng. |
| **Phòng ban** (chỉ Quản trị) | Lọc theo phòng ban — chỉ tài khoản admin có cây phòng ban. |
| **Sổ văn bản** | Lọc theo Sổ đăng ký văn bản đi (ví dụ Sổ đi 2026, Sổ Quyết định 2026...). |
| **Loại văn bản** | Lọc theo loại văn bản (Công văn, Quyết định, Báo cáo...). |
| **Độ khẩn** | Lọc theo độ khẩn — Thường / Khẩn / Hỏa tốc. |
| **Khoảng ngày** | Khoảng ngày đề — chọn "Từ ngày", "Đến ngày" theo lịch. |
| **Nút Tải lại** (mũi tên tròn) | Xóa toàn bộ bộ lọc, đưa danh sách về mặc định. |

---

## 5. Các trạng thái của Văn bản đi

Một văn bản đi tại một thời điểm sẽ ở một trong các trạng thái dưới đây — quyết định màu thẻ, các nút có thể bấm và việc cấp số / gửi:

| Trạng thái | Ý nghĩa | Thẻ hiển thị |
|---|---|---|
| **Chờ duyệt** | Văn bản vừa soạn xong, lãnh đạo chưa duyệt. | Vàng (gold) |
| **Đã duyệt** | Lãnh đạo đã đồng ý nội dung văn bản. | Xanh lá (success) |
| **Đã ban hành** | Sau khi duyệt, văn thư đã cấp số chính thức. Hiển thị thêm thẻ tím "Đã ban hành" + thời điểm. | Tím (purple) |
| **Đã gửi** (`status = 'sent'`) | Hệ thống đã sinh Văn bản đến cho các đơn vị nội bộ và đẩy LGSP cho cơ quan ngoài. | Mặc dù không có thẻ riêng, nhóm nút thay đổi sang chế độ chỉ đọc + Thu hồi. |
| **Từ chối** | Lãnh đạo không đồng ý — kèm lý do từ chối hiển thị ở banner đỏ ngay bên dưới tiêu đề. | Đỏ (error) |

Các thẻ phụ luôn hiển thị bên cạnh trạng thái chính:

| Thẻ phụ | Khi nào hiển thị |
|---|---|
| **Khẩn** (cam) / **Hỏa tốc** (đỏ) | Khi độ khẩn khác Thường. |
| **Mật / Tối mật / Tuyệt mật** | Khi độ mật khác Thường. |
| **Đã ký số** (xanh lá) | Khi văn bản đã có file đính kèm được ký số. |
| **Liên thông** (xanh dương) / **Nội bộ** | Văn bản đã được gửi qua LGSP hay chỉ nội bộ. |
| **Quá hạn** (đỏ) | Khi hạn xử lý đã quá ngày hiện tại. |

---

## 6. Cửa sổ Soạn / Sửa văn bản đi

![Cửa sổ Thêm văn bản đi](screenshots/van_ban_di_02_drawer.png)

Khi bấm **Thêm mới** hoặc menu **Sửa** trên một dòng, hệ thống mở một cửa sổ rộng 720 px từ bên phải. Tiêu đề là "Thêm văn bản đi" (mới) hoặc "Sửa văn bản đi" (chỉnh sửa). Nút **Tạo mới** / **Cập nhật** + **Hủy** ở góc trên bên phải.

### 6.1. Các trường nhập

| Tên trường | Bắt buộc | Mô tả & ràng buộc |
|---|---|---|
| **Sổ văn bản** | Có | Chọn sổ đi (lọc theo `type_id = 2` — sổ đi). Khi chọn xong, ô **Số đi** tự động điền số kế tiếp lấy từ máy chủ. |
| **Số đi** | Tự sinh | Số nguyên ≥ 1. Hệ thống đề xuất sẵn số kế tiếp; có thể sửa thủ công nếu cần. |
| **Số phụ** | Không | Tối đa 20 ký tự. Dùng khi cần đánh số phụ a, b, c. |
| **Ngày đề** | Không | Mặc định ngày hiện tại. Định dạng `DD/MM/YYYY`. |
| **Ký hiệu** | Không | Tối đa 100 ký tự. Ví dụ `123/UBND-VP`. |
| **Mã văn bản** | Không | Mã định danh nội bộ (tối đa 100 ký tự). |
| **Trích yếu nội dung** | Có | Bắt buộc. Tối đa 2000 ký tự, có hiển thị bộ đếm. Bỏ trống → "Trích yếu nội dung không được để trống". |
| **Đơn vị soạn thảo** | Có | Mặc định là phòng ban của người đang đăng nhập. Khi đổi, danh sách "Người soạn thảo" cũng được tải lại. |
| **Người soạn thảo** | Có | Lọc theo đơn vị soạn vừa chọn. Mặc định là tài khoản đang đăng nhập. |
| **Đơn vị ban hành** | Không | Đơn vị đứng tên ban hành (thường là đơn vị cấp trên trực tiếp của đơn vị soạn). |
| **Người ký** | Không | Họ tên người ký (tối đa 200 ký tự). |
| **Loại văn bản** | Không | Chọn từ danh mục (Công văn, Quyết định...). |
| **Lĩnh vực** | Không | Chọn từ danh mục lĩnh vực. |
| **Độ mật** | Có | Mặc định **Thường**. Các giá trị: Thường, Mật, Tối mật, Tuyệt mật. |
| **Độ khẩn** | Có | Mặc định **Thường**. Các giá trị: Thường, Khẩn, Hỏa tốc. |
| **Ngày ký** | Không | Định dạng `DD/MM/YYYY`. |
| **Ngày ban hành** | Không | Định dạng `DD/MM/YYYY`. |
| **Hạn xử lý** | Không | Định dạng `DD/MM/YYYY`. Khi quá hạn, hiển thị thẻ đỏ "Quá hạn" trên màn chi tiết. |
| **Số tờ / Số bản** | Không | Mặc định mỗi ô là 1, không âm. |
| **Đơn vị nhận (nội bộ — trong hệ thống)** | Không | Chọn nhiều đơn vị từ danh sách phòng ban / đơn vị nội bộ. Ghi chú: "Khi 'Gửi', mỗi đơn vị tự nhận được Văn bản đến". Tự loại trừ chính đơn vị đang đăng nhập. |
| **Cơ quan nhận (ngoài — qua LGSP)** | Không | Chọn nhiều cơ quan ngoài tỉnh từ danh mục cơ quan liên thông. Ghi chú: "Khi 'Gửi', văn bản được đẩy lên LGSP để gửi đến các cơ quan này". |

> **Lưu ý**: Nếu không chọn bất kỳ đơn vị / cơ quan nhận nào ở bước này, hệ thống vẫn cho phép tạo. Khi bấm **Gửi** ở màn chi tiết, hệ thống sẽ mở cửa sổ phụ cho người dùng chọn đơn vị nhận trước khi gửi.

### 6.2. Nút Tạo mới / Cập nhật / Hủy

| Nút | Tác dụng |
|---|---|
| **Tạo mới** | Tạo văn bản đi mới. Khi thành công: thông báo "Tạo văn bản đi thành công", lưu danh sách nơi nhận, đóng cửa sổ và làm tươi danh sách. |
| **Cập nhật** | Lưu thay đổi. Khi thành công: thông báo "Cập nhật thành công". **Không sửa được nếu văn bản đã duyệt** — báo lỗi "Không thể sửa văn bản đã được duyệt". |
| **Hủy** | Đóng cửa sổ, không lưu thay đổi. |

---

## 7. Bố cục màn hình Chi tiết

![Màn hình chi tiết Văn bản đi](screenshots/van_ban_di_03_detail.png)

Khi bấm trích yếu trên bảng (hoặc menu **Xem chi tiết**), hệ thống mở trang chi tiết tại đường dẫn `/van-ban-di/<id>`. Trang gồm 3 phần lớn:

- **Thanh tiêu đề (Header)** — đỉnh trang, gồm:
  - Nút **Quay lại** (mũi tên trái).
  - Dòng "Số đi: N — Ký hiệu" + dòng phụ "Đơn vị soạn • Ngày ban hành".
  - Các thẻ trạng thái (Chờ duyệt / Đã duyệt / Từ chối, Khẩn, Hỏa tốc, Mật, Đã ban hành, Đã ký số, Liên thông).
  - Banner đỏ hiển thị **Lý do từ chối** (chỉ khi văn bản bị từ chối và có lý do).
  - Thanh nút thao tác (xem mục 9).
- **Cột trái** — thông tin nội dung:
  - Trích yếu nội dung (banner xanh nhạt).
  - Khối "Thông tin văn bản" — đầy đủ trường (xem mục 8.1).
  - Khối "Tài liệu đính kèm" (xem mục 8.4).
- **Cột phải** — theo dõi & lịch sử:
  - "Đơn vị / Cơ quan nhận" — danh sách `outgoing_doc_recipients` kèm trạng thái gửi (xem mục 8.2).
  - "Người nhận" — danh sách cá nhân nhận trực tiếp (xem mục 8.3).
  - "Ý kiến lãnh đạo" — kèm ô gửi ý kiến mới.
  - "Lịch sử xử lý" — timeline các sự kiện.

---

## 8. Các khối thông tin trong màn Chi tiết

### 8.1. Khối "Thông tin văn bản"

Hiển thị đầy đủ các trường đã nhập ở cửa sổ Soạn / Sửa, gồm:

- **Số đi**, **Ngày ban hành**, **Số ký hiệu** (chữ xanh teal), **Sổ văn bản**.
- **Đơn vị soạn**, **Người soạn**, **Đơn vị phát hành**.
- **Loại văn bản**, **Lĩnh vực**, **Người ký**, **Ngày ký**.
- **Hạn xử lý** — chữ đỏ + thẻ "Quá hạn" nếu đã trễ.
- **Nơi nhận** — chuỗi tổng hợp các đơn vị / cơ quan nhận. Khi chưa có nơi nhận và văn bản chưa ban hành, có thẻ vàng cảnh báo: *"Chưa chọn đơn vị nhận chính thức — sẽ yêu cầu chọn khi Gửi"*.
- **Người duyệt** — kèm thẻ thời điểm duyệt (xanh lá).
- **Trạng thái phát hành** — thẻ tím "Đã ban hành <thời điểm>" hoặc thẻ xám "Chưa ban hành".
- **Độ mật** + **Độ khẩn**.
- **Số tờ / Số bản**, **Ký số**, **Liên thông**.
- **Người nhập** + **Thời gian tạo**.

### 8.2. Khối "Đơn vị / Cơ quan nhận" (cột phải)

Chỉ hiển thị khi có ít nhất một nơi nhận. Mỗi dòng là một nơi nhận, gồm:

- **Thẻ "Nội bộ"** (xanh dương) — đơn vị trong hệ thống.
- **Thẻ "LGSP"** (xanh lá) — cơ quan ngoài qua LGSP, kèm mã định danh trong ngoặc.
- **Trạng thái gửi**:
  - Đơn vị nội bộ đã nhận: ✓ "Đã nhận lúc HH:mm DD/MM" (xanh).
  - Cơ quan LGSP gửi thành công: ✓ "LGSP đã gửi (#mã 12 ký tự đầu...)".
  - LGSP lỗi: ✗ "Lỗi: <thông điệp>" (đỏ).
  - LGSP đang chờ: ⏳ "Đang chờ worker đẩy LGSP" (vàng).
  - Chưa gửi: ⏳ "Chưa gửi" (vàng).

### 8.3. Khối "Người nhận" (cột phải)

Chỉ hiển thị khi có cá nhân là người nhận trực tiếp (chức năng Gửi cho cá nhân). Mỗi dòng là một cán bộ, gồm:

- **Avatar** + **Tên** + **Chức vụ** + **Phòng ban**.
- **Trạng thái đọc** — "Đã đọc lúc HH:mm DD/MM" (xanh) hoặc "Chưa đọc" (vàng).

### 8.4. Khối "Tài liệu đính kèm" (cột trái)

- Số file ở tiêu đề: "Tài liệu đính kèm (N)".
- Mỗi dòng file: biểu tượng (PDF / Word / Excel / ảnh / khác), tên file, kích thước, thời gian tải lên.
- Các nút bên phải mỗi file:
  - **Ký số** (chỉ hiện khi file chưa ký số — mở luồng ký qua hook `useSigning`).
  - Thẻ **Đã ký số** (xanh lá) — thay nút Ký số khi file đã ký.
  - Nút **Tải xuống** — tải file qua proxy backend (đảm bảo tên file tiếng Việt).
  - Nút **Xóa** (đỏ) — chỉ hiện khi văn bản chưa duyệt; có hộp xác nhận.
- Nút **Thêm file** ở góc trên — chỉ hiện khi văn bản chưa duyệt. Kéo thả hoặc bấm chọn file để tải lên.

### 8.5. Khối "Ý kiến lãnh đạo" (cột phải)

- Liệt kê các ý kiến đã ghi nhận, mỗi ý kiến hiển thị tên + chức vụ + nội dung + thời gian (nền vàng nhạt).
- Người gửi ý kiến có thể xóa ý kiến của chính mình.
- Ô nhập ở dưới + nút **Gửi ý kiến** — không cho gửi ý kiến trống.

### 8.6. Khối "Lịch sử xử lý" (cột phải)

Timeline (đường dọc) các sự kiện:

- **Tạo văn bản** (xanh dương) — "Tạo văn bản đi, số: N".
- **Đã duyệt** (xanh lá) — "Duyệt văn bản đi".
- **Đã gửi** (xanh ngọc) — "Nhận văn bản" (1 dòng cho mỗi cá nhân nhận).
- **Ý kiến lãnh đạo** (cam).

Mỗi dòng có tên cán bộ + thời điểm `DD/MM/YYYY HH:mm`.

---

## 9. Các nút thao tác theo từng trạng thái

Thanh nút thao tác trên Header chỉ hiển thị các nút phù hợp với trạng thái + quyền của người dùng. Quyền (`canEdit`, `canApprove`, `canRelease`, `canSend`, `canRetract`) được tính sẵn ở backend dựa theo:

- Người soạn thảo (drafting_user_id) hoặc người tạo bản ghi (created_by) → là **chủ sở hữu** văn bản.
- Cùng đơn vị (theo cây phòng ban) hay không.
- Quyền (right) gắn với vai trò của tài khoản.

### 9.1. Khi văn bản ở trạng thái **Chờ duyệt**

| Nút | Khi nào hiển thị | Tác dụng |
|---|---|---|
| **Đánh dấu / Bỏ đánh dấu** (sao) | Luôn | Đánh dấu văn bản cá nhân để dễ truy cập. |
| **Sửa** | Có quyền sửa | Mở Drawer Sửa văn bản — quay lại màn Danh sách với tham số `?edit=<id>`. |
| **Duyệt** | Có quyền duyệt | Đặt văn bản về Đã duyệt. Thông báo "Duyệt văn bản đi thành công". |
| (Menu ba chấm) **Từ chối** | Có quyền duyệt và chưa từng bị từ chối | Mở hộp xác nhận có ô nhập "Lý do từ chối (không bắt buộc)". |
| (Menu ba chấm) **Xóa văn bản** | Có quyền sửa | Hộp xác nhận; chỉ xóa được khi văn bản chưa duyệt. |

> Hai nút **Giao việc** và **Thêm vào HSCV** **luôn hiển thị** ở mọi trạng thái khi người dùng có quyền duyệt — không phụ thuộc văn bản đã duyệt hay chưa. Chi tiết tác dụng:
>
> - **Giao việc** — Mở Drawer "Giao việc" để tạo Hồ sơ công việc mới gắn với văn bản này, chọn người phụ trách, ngày bắt đầu, hạn hoàn thành, ghi chú.
> - **Thêm vào HSCV** — Mở Modal để chọn một Hồ sơ công việc đã tồn tại và gắn văn bản vào đó.

### 9.2. Khi văn bản ở trạng thái **Đã duyệt** nhưng **Chưa ban hành**

| Nút | Khi nào hiển thị | Tác dụng |
|---|---|---|
| **Ban hành** (tím) | Có quyền ban hành | Cấp số chính thức, đặt cờ `is_released = TRUE`. Báo "Ban hành thành công". |
| **Ban hành & Gửi** (xanh lá) | Có quyền ban hành + gửi | Ban hành rồi gửi luôn trong cùng một thao tác. Nếu chưa có nơi nhận, mở Modal chọn đơn vị nhận trước. |
| (Menu ba chấm) **Hủy duyệt** | Có quyền duyệt | Đặt lại văn bản về Chờ duyệt. **Không hủy được nếu văn bản đã được gửi cho cán bộ** — báo "Không thể hủy duyệt: văn bản đã được gửi cho cán bộ". |

### 9.3. Khi văn bản ở trạng thái **Đã ban hành** nhưng **Chưa gửi**

| Nút | Khi nào hiển thị | Tác dụng |
|---|---|---|
| **Gửi** (xanh teal) | Có quyền gửi | Đẩy văn bản đến các nơi nhận đã lưu — sinh "Văn bản đến" cho mỗi đơn vị nội bộ + đẩy LGSP cho mỗi cơ quan ngoài. Nếu **chưa có nơi nhận**, mở Modal "Gửi nội bộ — chọn đơn vị nhận" để chọn trước. |
| (Menu ba chấm) **Thu hồi** | Có quyền thu hồi và đã có người nhận | Mở hộp xác nhận: "Thu hồi sẽ xóa tất cả người nhận và đặt lại trạng thái chưa duyệt. Bạn chắc chắn?" |

### 9.4. Khi văn bản ở trạng thái **Đã gửi** (`status = 'sent'`)

| Nút | Khi nào hiển thị | Tác dụng |
|---|---|---|
| (Menu ba chấm) **Thu hồi** | Có quyền thu hồi và đã có người nhận | Như mục 9.3. |

Các thao tác khác chỉ ở chế độ đọc.

---

## 10. Quy trình nghiệp vụ chính

### 10.1. Soạn và trình một văn bản đi mới

1. Trên màn Danh sách, bấm **Thêm mới**.
2. Chọn **Sổ văn bản** — số đi sẽ tự đề xuất.
3. Nhập **Trích yếu nội dung** (bắt buộc).
4. Điền các thông tin còn lại — đơn vị soạn, người soạn, người ký, độ khẩn, độ mật...
5. Tại mục **Đơn vị nhận (nội bộ)** và/hoặc **Cơ quan nhận (ngoài qua LGSP)**, chọn các nơi sẽ gửi tới.
6. Bấm **Tạo mới** → "Tạo văn bản đi thành công".
7. Mở Chi tiết, vào khối **Tài liệu đính kèm**, bấm **Thêm file** để tải file văn bản (PDF, Word, ảnh...).

### 10.2. Lãnh đạo duyệt / từ chối

1. Lãnh đạo mở văn bản ở trạng thái Chờ duyệt.
2. Đọc trích yếu, mở file đính kèm để xem nội dung.
3. Nếu **đồng ý**: bấm **Duyệt** → văn bản chuyển sang **Đã duyệt**.
4. Nếu **không đồng ý**: bấm **Từ chối** ở menu ba chấm → nhập lý do (tùy chọn) → văn bản chuyển sang **Từ chối**, banner đỏ hiển thị lý do.

### 10.3. Văn thư ban hành và gửi

1. Sau khi văn bản **Đã duyệt**, văn thư mở chi tiết.
2. Có 2 cách xử lý:
   - **Tách bước**: bấm **Ban hành** → văn bản được cấp số + chuyển sang Đã ban hành. Sau đó bấm **Gửi** để đẩy đi.
   - **Gộp 1 bước**: bấm **Ban hành & Gửi** → hệ thống thực hiện tuần tự cả 2 thao tác.
3. Nếu chưa có nơi nhận, hệ thống mở **Modal "Gửi nội bộ — chọn đơn vị nhận"** liệt kê toàn bộ đơn vị (loại trừ đơn vị đang phát hành). Tích chọn các đơn vị nhận → bấm **Gửi (N đơn vị)** → hệ thống lưu nơi nhận + sinh "Văn bản đến" cho từng đơn vị + đẩy LGSP cho cơ quan ngoài (nếu có).
4. Sau khi gửi, kiểm tra khối **Đơn vị / Cơ quan nhận** để xem trạng thái thực gửi của từng nơi.

### 10.4. Thu hồi văn bản đã gửi

1. Khi phát hiện sai sót sau khi đã gửi, bấm **Menu ba chấm → Thu hồi**.
2. Xác nhận trong hộp thoại "Thu hồi sẽ xóa tất cả người nhận và đặt lại trạng thái chưa duyệt".
3. Sau thu hồi: toàn bộ người nhận bị xóa, văn bản về **Chưa duyệt**, có thể sửa lại và phát hành lần nữa.

### 10.5. Giao việc / Thêm vào hồ sơ công việc

- **Giao việc**: bấm **Giao việc** → tạo Hồ sơ công việc mới với người phụ trách + hạn xử lý → văn bản đi được gắn vào HSCV mới đó.
- **Thêm vào HSCV**: bấm **Thêm vào HSCV** → chọn HSCV đã tồn tại từ Modal → văn bản được liên kết vào HSCV đã chọn.

### 10.6. Ký số file đính kèm

1. Mở Chi tiết, đến khối **Tài liệu đính kèm**.
2. Bên cạnh mỗi file, nút **Ký số** (xanh dương) sẽ hiện nếu file chưa ký.
3. Bấm Ký số → mở Modal ký theo luồng `useSigning` (kèm chữ ký, lý do mặc định "Phê duyệt VB đi số N/Ký hiệu", địa điểm là tên đơn vị soạn).
4. Sau khi ký xong, file có thẻ **Đã ký số** (xanh lá).

---

## 11. Sơ đồ vòng đời văn bản đi

```
                 ┌──────────────┐
                 │ Cán bộ soạn  │
                 │ (Thêm mới)   │
                 └──────┬───────┘
                        │ tạo
                        ▼
                  ┌───────────┐
                  │ Chờ duyệt │◄───────────┐
                  └─────┬─────┘            │
                        │                  │ Hủy duyệt
        ┌───────────────┼──────────┐       │ (chưa gửi)
        │ Duyệt         │          │       │
        ▼               │          ▼       │
  ┌───────────┐         │     ┌─────────┐  │
  │ Đã duyệt  │         │     │ Từ chối │  │
  └─────┬─────┘         │     └─────────┘  │
        │ Ban hành      │                  │
        ▼               │                  │
  ┌──────────────┐      │                  │
  │ Đã ban hành  │──────┘                  │
  │ (cấp số)     │                         │
  └──────┬───────┘                         │
         │ Gửi                             │
         ▼                                 │
  ┌───────────┐         Thu hồi            │
  │  Đã gửi   │─────────────────────────────┘
  │ (sent)    │   (xóa người nhận, reset duyệt)
  └───────────┘
```

Các nhánh phụ:
- **Từ chối** có thể chuyển ngược về **Chờ duyệt** (cán bộ sửa nội dung và trình lại — văn bản bị từ chối đặt cờ `approved = FALSE`).
- **Đã duyệt** có thể bị **Hủy duyệt** đưa về Chờ duyệt — chỉ khi chưa gửi.
- **Ban hành** và **Gửi** có thể được gộp chung qua nút **Ban hành & Gửi** ở 1 click.

---

## 12. Lưu ý / Ràng buộc nghiệp vụ

### 12.1. Quy tắc cấp số

- Số đi đề xuất tự động bằng số lớn nhất hiện có trong sổ + 1 — tính theo đơn vị (`unit_id`) và sổ (`doc_book_id`) trong năm hiện tại.
- Có thể nhập số thủ công, nhưng nếu trùng số đã tồn tại trong cùng sổ + năm, hệ thống báo lỗi khi tạo / sửa.
- **Khi ban hành**: nếu văn bản chưa có số (`number IS NULL`), hệ thống sẽ tự cấp số kế tiếp dựa trên các văn bản đã ban hành (`is_released = TRUE`) trong cùng sổ.

### 12.2. Trạng thái và quyền

- Chỉ **người soạn (drafting_user_id)** hoặc **người tạo bản ghi (created_by)** được coi là chủ sở hữu của văn bản.
- Quyền **Sửa** chỉ dành cho chủ sở hữu (hoặc admin / cùng đơn vị có quyền cao hơn).
- Quyền **Duyệt / Từ chối / Hủy duyệt** dành cho lãnh đạo có quyền duyệt văn bản đi của đơn vị tương ứng.
- Quyền **Ban hành** và **Gửi** thường dành cho văn thư đơn vị.
- Quyền **Thu hồi** dành cho người có quyền gửi và áp dụng cho văn bản đã gửi.

### 12.3. Không sửa được khi đã duyệt

Văn bản đã duyệt KHÔNG cho phép sửa nội dung — phải **Hủy duyệt** trước (nếu chưa gửi). Hệ thống báo:

> *"Không thể sửa văn bản đã được duyệt"*

Tương tự, không xóa được văn bản đã duyệt:

> *"Không thể xóa văn bản đã được duyệt"*

### 12.4. Không hủy duyệt được khi đã gửi

Sau khi văn bản đã được gửi cho cán bộ (có ít nhất 1 dòng `user_outgoing_docs`), không cho hủy duyệt nữa — phải dùng chức năng **Thu hồi** thay thế:

> *"Không thể hủy duyệt: văn bản đã được gửi cho cán bộ"*

### 12.5. Phải duyệt trước khi gửi

Cố gắng gửi văn bản chưa duyệt sẽ bị từ chối:

> *"Văn bản chưa được duyệt, không thể gửi"*

Cố gắng gửi văn bản đã duyệt nhưng chưa ban hành cũng bị từ chối:

> *"Văn bản chưa ban hành, không thể gửi"*

### 12.6. Phải có nơi nhận

Khi bấm **Gửi** mà chưa có dòng nào trong `outgoing_doc_recipients`:

> *"Chưa có nơi nhận"*

Frontend bắt sẵn tình huống này và mở Modal cho người dùng chọn đơn vị nhận thay vì hiển thị lỗi.

### 12.7. Liên thông LGSP

- Hệ thống không gửi LGSP đồng bộ — chỉ tạo bản ghi `lgsp_tracking` ở trạng thái `pending`, sau đó worker nền sẽ đẩy lên trục LGSP và cập nhật trạng thái thành `success` / `error`.
- Trạng thái LGSP thực tế hiển thị ngay trong khối "Đơn vị / Cơ quan nhận" ở cột phải — không cần mở màn riêng.
- Mỗi cơ quan ngoài tỉnh trong danh mục **Cơ quan liên thông** đều có mã (`code`) — dùng làm `dest_org_code` khi đẩy LGSP.

### 12.8. File đính kèm

- Chỉ tải lên / xóa được khi văn bản **chưa duyệt**.
- Sau khi văn bản đã duyệt, file đính kèm là cố định — chỉ còn xem, tải xuống và ký số.
- File ký số là file PDF — sau khi ký, có thẻ **Đã ký số** màu xanh.
- Tải xuống file qua proxy backend (`/dinh-kem/<id>/download`) — không trả presigned URL ra ngoài để bảo mật.

### 12.9. Số phụ và mã văn bản

- **Số phụ** chỉ là chuỗi định danh phụ (a, b, c) — dùng khi cần phân biệt nhiều văn bản cùng số đi gốc.
- **Mã văn bản** là mã định danh nội bộ của tổ chức (nếu có quy định riêng) — không trùng với "Số ký hiệu".


---

*Tài liệu được biên soạn dựa trên hệ thống thực tế đang triển khai. Mọi thắc mắc vui lòng liên hệ với đội phát triển để được hỗ trợ.*
