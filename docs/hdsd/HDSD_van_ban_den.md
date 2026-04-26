# Hướng dẫn sử dụng: Văn bản đến

Tài liệu này mô tả đầy đủ các chức năng của hai màn hình **Danh sách Văn bản đến** và **Chi tiết Văn bản đến** trong hệ thống Quản lý văn bản điện tử (e-Office), giúp người dùng nắm vững cách tiếp nhận, vào sổ, phân công và xử lý một văn bản đến đúng quy trình của cơ quan nhà nước.

---

## 1. Giới thiệu

**Văn bản đến** là toàn bộ giấy tờ, công văn, công điện, quyết định... mà cơ quan nhận được từ bên ngoài (cơ quan cấp trên, cơ quan ngang cấp, cơ quan cấp dưới, doanh nghiệp, công dân) hoặc từ nội bộ (đơn vị khác trong tỉnh gửi qua liên thông LGSP, đơn vị nội bộ gửi văn bản đi). Đây là **module cốt lõi**, là điểm bắt đầu của hầu hết mọi quy trình hành chính trong cơ quan.

Vòng đời tổng quan của một văn bản đến gồm 4 chặng chính:

1. **Tiếp nhận và vào sổ** — Văn thư nhập thông tin văn bản, hệ thống cấp số đến tự động.
2. **Lãnh đạo duyệt và bút phê** — Lãnh đạo xem xét, ghi ý kiến chỉ đạo, có thể phân công ngay.
3. **Phân công xử lý** — Lãnh đạo gửi văn bản tới các cán bộ phối hợp, hoặc tạo Hồ sơ công việc (HSCV) giao việc cho người phụ trách kèm hạn xử lý.
4. **Theo dõi xử lý và lưu trữ** — Cán bộ xử lý đọc, xử lý, báo cáo qua HSCV; cuối cùng văn bản được chuyển vào kho lưu trữ.

Hệ thống hỗ trợ ba **nguồn văn bản đến** khác nhau:

- **Nhập tay (manual)**: Văn thư tự nhập từ văn bản giấy hoặc file đính kèm — đây là trường hợp phổ biến nhất.
- **Nội bộ (internal)**: Văn bản tự động sinh ra khi một đơn vị trong cùng tỉnh phát hành văn bản đi gửi tới đơn vị mình.
- **Liên thông LGSP (external_lgsp)**: Văn bản nhận qua trục liên thông Chính phủ điện tử.

Văn bản đến nguồn **internal** và **external_lgsp** không được sửa nội dung gốc — chỉ tiếp nhận, phân công xử lý hoặc chuyển lại.

---

## 2. Bố cục màn hình Danh sách

![Màn hình Danh sách Văn bản đến](screenshots/van_ban_den_01_main.png)

Màn hình Danh sách được chia thành các phần:

- **Phần đầu trang**: Tiêu đề "Văn bản đến" kèm biểu tượng. Bên phải có thanh nút công cụ: **Đánh dấu đã đọc** (chỉ hiện khi có dòng tích chọn), **Xuất Excel**, **In**, **Thêm mới**.
- **Hàng bộ lọc**: Ô tìm kiếm trích yếu/ký hiệu, ô chọn Phòng ban (chỉ Quản trị thấy), ô chọn Sổ văn bản, ô chọn Loại văn bản, ô chọn Độ khẩn, dải ngày, nút **Xóa bộ lọc**.
- **Bảng dữ liệu**: Hiển thị danh sách văn bản đến với các cột mô tả ở mục 3. Các dòng **chưa đọc** được tô đậm để dễ phân biệt.
- **Cửa sổ phụ (Drawer)**: **Thêm văn bản đến** / **Sửa văn bản đến** mở từ bên phải khi bấm Thêm mới hoặc Sửa.

---

## 3. Các cột trong Bảng danh sách

| Tên cột | Mô tả |
|---|---|
| **Số đến** | Số thứ tự vào sổ, hệ thống tự cấp theo sổ và năm. Dòng chưa đọc — số đến in đậm. |
| **Ngày đến** | Ngày văn thư tiếp nhận văn bản (định dạng `DD/MM/YYYY`). |
| **Số ký hiệu** | Số/ký hiệu văn bản gốc do cơ quan ban hành đặt (VD: `123/UBND-VP`). |
| **Trích yếu** | Tóm tắt nội dung văn bản. Bấm vào trích yếu để mở **Chi tiết**. Nếu văn bản được đồng nghiệp gửi cho mình, có nhãn nhỏ **"Gửi cho tôi"** kèm tooltip "Do [tên người] gửi lúc [thời gian]". |
| **CQ ban hành** | Cơ quan ban hành văn bản (đơn vị cấp văn bản). |
| **Loại VB** | Loại văn bản (Công văn, Quyết định, Báo cáo...). |
| **Độ khẩn** | Nhãn màu cam **Khẩn** hoặc đỏ **Hỏa tốc**. Nếu là **Thường** thì bỏ trống cột. |
| **Trạng thái** | **Đã duyệt** (xanh lá), **Chờ duyệt** (vàng), **Từ chối** (đỏ). |
| (cột thao tác) | Nút **ba chấm dọc** mở menu các lệnh tùy theo quyền và trạng thái: Xem chi tiết, Sửa, Duyệt, Hủy duyệt, Thu hồi, Xóa. |

---

## 4. Bộ lọc và thanh công cụ

### 4.1. Các bộ lọc (hàng phía trên bảng)

| Bộ lọc | Mô tả |
|---|---|
| **Tìm kiếm trích yếu, ký hiệu...** | Ô gõ từ khóa, tìm trong các trường: trích yếu, số ký hiệu, cơ quan ban hành, người ký, mã văn bản. |
| **Phòng ban** (chỉ Quản trị) | Chọn phòng ban để xem văn bản đến của đơn vị/phòng ban đó (TreeSelect dạng cây). |
| **Sổ văn bản** | Chọn 1 sổ văn bản đến để lọc. |
| **Loại văn bản** | Chọn 1 loại văn bản (Công văn, Báo cáo...) để lọc. |
| **Độ khẩn** | Lọc theo **Thường / Khẩn / Hỏa tốc**. |
| **Khoảng ngày** (Từ ngày — Đến ngày) | Lọc theo ngày đến. |
| **Xóa bộ lọc** (biểu tượng mũi tên xoay) | Đặt lại tất cả ô lọc về rỗng và trở về trang 1. |

> Khi đổi bất kỳ bộ lọc nào, danh sách tự động chuyển về trang 1 và tải lại. Số lượng tổng hiển thị ở góc dưới bảng dạng *"Tổng [N] văn bản"*.

### 4.2. Thanh nút công cụ (góc trên bên phải)

| Nút | Khi nào hiển thị | Tác dụng |
|---|---|---|
| **Đánh dấu đã đọc (N)** | Khi có ít nhất 1 dòng được tích chọn ở cột đầu | Đánh dấu hàng loạt các văn bản đã chọn là đã đọc, cập nhật badge "chưa đọc" trên thanh điều hướng. |
| **Xuất Excel** | Luôn hiển thị | Tải xuống file `.xlsx` chứa danh sách văn bản theo bộ lọc đang áp dụng (tối đa 10.000 dòng). Tên file: `VanBanDen_YYYYMMDD.xlsx`. |
| **In** | Luôn hiển thị | Mở hộp thoại in của trình duyệt với danh sách văn bản đến hiện tại. |
| **Thêm mới** | Luôn hiển thị (kiểm tra quyền ở backend) | Mở **Drawer Thêm văn bản đến** để văn thư nhập văn bản mới. |

---

## 5. Drawer Thêm / Sửa Văn bản đến

![Drawer Thêm văn bản đến](screenshots/van_ban_den_02_add_drawer.png)

Khi bấm **Thêm mới** hoặc chọn **Sửa** từ menu, hệ thống mở Drawer rộng 800px ở bên phải. Tiêu đề là *"Thêm văn bản đến"* hoặc *"Sửa văn bản đến"*. Nút **Hủy** và **Tạo mới** / **Cập nhật** ở góc trên bên phải.

Các trường nhập liệu:

| Tên trường | Bắt buộc | Mô tả & ràng buộc |
|---|---|---|
| **Sổ văn bản** | Có | Chọn từ danh sách sổ văn bản đến. Khi chọn xong (chỉ ở chế độ Thêm), hệ thống tự gợi ý **Số đến** kế tiếp. |
| **Số đến** | Không (auto) | Số nguyên ≥ 1. Để trống — hệ thống tự cấp số kế tiếp theo công thức: số lớn nhất hiện có trong sổ + 1, theo năm hiện tại. |
| **Số phụ** | Không | Mã ngắn cho văn bản phụ (VD: `a`, `b`, `c`). Tối đa 20 ký tự. |
| **Ngày đến** | Có | Mặc định là hôm nay. Định dạng `DD/MM/YYYY`. |
| **Ký hiệu** | Không | Số/ký hiệu trên văn bản gốc (VD: `123/UBND-VP`). Tối đa 100 ký tự. |
| **Cơ quan ban hành** | Không | Có thể chọn từ danh sách đơn vị nội bộ (cây phẳng) hoặc gõ tự do tên cơ quan. |
| **Trích yếu nội dung** | Có | Tóm tắt nội dung văn bản. Tối đa 2000 ký tự, có đếm ký tự. |
| **Loại văn bản** | Không | Chọn từ danh sách (Công văn, Quyết định, Báo cáo...). |
| **Lĩnh vực** | Không | Chọn từ danh sách lĩnh vực. |
| **Người ký** | Không | Họ tên người ký bên cơ quan ban hành. Tối đa 200 ký tự. |
| **Ngày ký** | Không | Ngày ký trên văn bản gốc. |
| **Ngày ban hành** | Không | Ngày văn bản được phát hành chính thức. |
| **Hạn xử lý** | Không | Ngày phải hoàn thành xử lý văn bản. Khi quá hạn, ở Chi tiết sẽ có nhãn đỏ **"Quá hạn"**. |
| **Độ mật** | Không | **Thường / Mật / Tối mật / Tuyệt mật**. Mặc định: Thường. |
| **Độ khẩn** | Không | **Thường / Khẩn / Hỏa tốc**. Mặc định: Thường. |
| **Số tờ** | Không | Số nguyên ≥ 0. Mặc định: 1. |
| **Số bản** | Không | Số nguyên ≥ 0. Mặc định: 1. |
| **Bản giấy** | Không | **Chưa nhận** / **Đã nhận** — đánh dấu khi văn thư đã nhận được bản giấy đối chiếu. |
| **Mã văn bản (số CV gốc bên gửi)** | Không | Mã định danh văn bản từ phía cơ quan ban hành (nếu có). Tối đa 100 ký tự. |
| **Nơi gửi** | Có (khi tự nhập) | Cơ quan/đơn vị đã gửi văn bản này tới. Có thể chọn từ danh sách (đơn vị nội bộ + cơ quan ngoài LGSP) hoặc gõ tên tự do. |

Khi để trống **Trích yếu nội dung**, hệ thống báo *"Trích yếu nội dung không được để trống"*. Khi để trống **Sổ văn bản**, hệ thống báo *"Sổ văn bản là bắt buộc"*. Khi sửa văn bản đã duyệt, hệ thống báo *"Không thể sửa văn bản đã được duyệt"* — phải Hủy duyệt trước.

> **Lưu ý nguồn**: Drawer Sửa chỉ hoạt động cho văn bản nguồn **Nhập tay**. Nếu cố sửa văn bản nguồn **internal** hoặc **LGSP**, hệ thống báo: *"Văn bản đến từ đơn vị nội bộ không được sửa nội dung gốc. Chỉ có thể tiếp nhận / phân công xử lý / từ chối."*

---

## 6. Các trạng thái của Văn bản đến

Mỗi văn bản đến tại một thời điểm sẽ ở một trong các trạng thái sau:

| Trạng thái | Ý nghĩa |
|---|---|
| **Chờ duyệt** | Văn bản vừa được vào sổ, lãnh đạo chưa duyệt. Văn thư còn được phép sửa nội dung. |
| **Đã duyệt** | Lãnh đạo đã duyệt. Có thể bút phê, gửi cho cán bộ xử lý, giao việc, gửi liên thông LGSP. |
| **Từ chối** | Văn bản đã bị **chuyển lại** kèm lý do (sau khi đã được duyệt và phân công). Có thể duyệt lại để xử lý tiếp. |
| **Đã lưu trữ** *(ẩn ở Phase hiện tại)* | Đã chuyển vào kho lưu trữ — không thao tác tiếp được. |

Ngoài ra, văn bản còn có 2 thuộc tính phụ ảnh hưởng đến hành động:

- **Đã nhận bản giấy** (`is_received_paper`) — đối chiếu bản cứng đã nhận hay chưa.
- **Là văn bản liên thông** (`is_inter_doc`) — văn bản đến từ tỉnh khác qua LGSP, có nút **Nhận bàn giao** / **Chuyển lại** riêng.

Thanh công cụ trên màn hình **Chi tiết** sẽ **hiển thị khác nhau tùy theo trạng thái và quyền của người dùng** — chỉ các nút phù hợp mới được hiện ra (xem mục 9).

---

## 7. Bố cục màn hình Chi tiết

![Màn hình Chi tiết Văn bản đến](screenshots/van_ban_den_03_detail.png)

Màn hình chi tiết được mở khi bấm vào trích yếu hoặc chọn **Xem chi tiết** từ menu. Bố cục gồm:

- **Thanh đầu trang (Header bar)**: Nút mũi tên quay lại, dòng "Số đến: [N] — [Ký hiệu]", dòng phụ "[Cơ quan ban hành] • Ngày đến: [ngày]", các nhãn trạng thái + độ khẩn + độ mật, các nút thao tác (xem mục 9). Nếu văn bản đã bị từ chối, hiển thị thêm hộp đỏ "Lý do từ chối: ...".
- **Cột trái (rộng ~2/3)**:
  - **Trích yếu nội dung** (khung viền trái màu xanh teal).
  - **Thông tin văn bản** — đầy đủ trường (xem mục 8.1).
  - **Tài liệu đính kèm** — danh sách file (xem mục 8.2).
  - **Ý kiến bút phê** — danh sách ý kiến lãnh đạo + ô nhập bút phê mới (xem mục 8.3).
- **Cột phải (rộng ~1/3)**:
  - **Phân công xử lý** — danh sách cán bộ đã được gửi văn bản (xem mục 8.4).
  - **Lịch sử xử lý** — Timeline các sự kiện (xem mục 8.5).

---

## 8. Nội dung chi tiết các phần

### 8.1. Phần "Thông tin văn bản"

Hiển thị toàn bộ trường của văn bản theo nhóm 2 cột:

- **Số đến** — số đã vào sổ.
- **Ngày đến** — định dạng `DD/MM/YYYY`.
- **Số ký hiệu** — in màu xanh teal.
- **Sổ văn bản** — tên sổ.
- **Cơ quan ban hành** (chiếm cả 2 cột).
- **Loại văn bản**, **Lĩnh vực**.
- **Người ký**, **Ngày ký**.
- **Hạn xử lý** — chữ đỏ kèm nhãn **"Quá hạn"** nếu đã quá hạn so với hôm nay.
- **Nơi nhận** — danh sách đơn vị nhận (đối với văn bản đến nguồn nội bộ — tự fill từ văn bản đi gốc).
- **Người duyệt** — họ tên + nhãn xanh thời điểm duyệt.
- **Nguồn** — nhãn:
  - **Nội bộ** (xanh dương) — kèm tên đơn vị gửi.
  - **LGSP** (xanh lá) — kèm mã văn bản ngoài.
  - **Nhập tay** (xám) — văn bản văn thư tự nhập.
- **Độ mật**, **Độ khẩn** — nhãn màu.
- **Số tờ / Số bản**.
- **Bản giấy** — nhãn xanh **"Đã nhận"** hoặc xám **"Chưa nhận"**.
- **Người nhập** + **Thời gian tạo** (phần đáy có gạch ngăn).

### 8.2. Phần "Tài liệu đính kèm"

Mỗi file hiển thị: biểu tượng theo loại file (PDF, Word, Excel, ảnh...), tên file, dung lượng, thời gian tải lên, nhãn **"Đã ký số"** (xanh) nếu đã ký.

Thao tác trên mỗi file:

- **Tải xuống** (biểu tượng tải về) — luôn có. Hệ thống stream file qua backend (không lộ link MinIO).
- **Ký số** — chỉ hiển thị khi file **chưa được ký số**.
- **Xác thực** — chỉ hiển thị khi file **đã ký số**. Nếu hợp lệ — hộp xanh "Chữ ký hợp lệ" kèm tên người ký + thời gian; nếu chưa ký — hộp vàng "Chưa ký số".
- **Xóa file** (chỉ khi văn bản chưa duyệt) — Popconfirm "Xóa file?" trước khi xóa.

Ở góc phải tiêu đề có nút **"Thêm file"** (chỉ khi văn bản **chưa duyệt**) — chọn file để tải lên. Định dạng cho phép: PDF, Word, Excel, ảnh. Dung lượng tối đa 50 MB/file. Nếu chưa chọn file mà bấm tải lên, hệ thống báo *"Vui lòng chọn file"*.

### 8.3. Phần "Ý kiến bút phê"

Mỗi ý kiến hiển thị: ảnh đại diện, tên + chức vụ người bút phê, nội dung bút phê, thời gian. Nền xanh nhạt, viền trái xanh lá để dễ nhận biết. Người tự bút phê có nút xóa **Popconfirm "Xóa bút phê?"**.

Khi văn bản **đã duyệt**, dưới danh sách bút phê hiện ra ô nhập:

- Ô vùng văn bản 2 dòng *"Nhập nội dung bút phê..."*.
- Ô tích **"Phân công giải quyết"** — khi tích, mở thêm:
  - **Cán bộ xử lý** (chọn nhiều) — danh sách nạp sẵn từ "Cấu hình gửi nhanh" của người dùng.
  - **Hạn giải quyết** — chọn ngày.
- Nút **"Gửi bút phê"** (khi không tích phân công) hoặc **"Bút phê & Phân công"** (khi có tích).

Nếu để trống nội dung mà bấm gửi, hệ thống báo *"Nội dung bút phê không được để trống"*. Nếu tích Phân công nhưng không chọn cán bộ, báo *"Vui lòng chọn cán bộ phân công"*. Khi gửi thành công kèm phân công, hệ thống báo: *"Bút phê thành công, đã phân công [N] cán bộ"*.

### 8.4. Phần "Phân công xử lý"

Hiển thị số lượng cán bộ đã được gửi văn bản: *"Phân công xử lý ([N])"*. Mỗi dòng:

- Avatar có dấu chấm trạng thái (xanh — đã đọc, xám — chưa đọc).
- Họ tên cán bộ — chức vụ • phòng ban.
- Trạng thái đọc: **"Đã đọc lúc HH:mm DD/MM"** (xanh) hoặc **"Chưa đọc"** (vàng).

Khi chưa có ai được phân công: *"Chưa phân công cho phòng/cá nhân nào xử lý"*.

### 8.5. Phần "Lịch sử xử lý"

Timeline các sự kiện đã xảy ra trên văn bản, theo thứ tự mới nhất trên đầu:

| Loại sự kiện | Nội dung hiển thị | Màu chấm |
|---|---|---|
| **Tạo văn bản** | "Tạo văn bản đến, số đến: [N]" | Xanh dương |
| **Duyệt** | "Duyệt văn bản" | Xanh lá |
| **Gửi cho cán bộ** | "Nhận văn bản" | Xanh ngọc |
| **Bút phê** | Nội dung bút phê | Cam |

Khi chưa có sự kiện nào — hiển thị *"Chưa có lịch sử"*.

---

## 9. Các nút hành động theo trạng thái và quyền

Thanh công cụ trên đầu màn hình Chi tiết có các nút sau, **hiển thị tùy theo trạng thái + quyền của người dùng**.

### 9.1. Nút luôn hiển thị (mọi trạng thái)

| Nút | Tác dụng |
|---|---|
| **Mũi tên quay lại** | Trở về Danh sách văn bản đến. |
| **Ngôi sao** (đánh dấu cá nhân) | Bật/tắt đánh dấu — văn bản sẽ xuất hiện ở mục **Văn bản đánh dấu** của tôi. Khi đã đánh dấu, sao chuyển vàng. |
| **Giao việc** (xanh teal) | Mở Drawer **Giao việc** — tạo HSCV mới gắn văn bản này, cử người phụ trách + hạn xử lý (xem mục 10.2). |
| **Thêm vào HSCV** | Mở Modal — chọn HSCV sẵn có để thêm văn bản vào (xem mục 10.3). |

### 9.2. Khi văn bản **Chờ duyệt**

| Nút | Hiển thị khi | Tác dụng |
|---|---|---|
| **Sửa** | Người dùng có quyền sửa **VÀ** nguồn = Nhập tay | Mở Drawer Sửa văn bản đến (chuyển sang trang Danh sách rồi mở Drawer kèm `?edit=ID`). |
| **Duyệt** (chính, xanh dương) | Người dùng có quyền duyệt | Bấm — duyệt ngay (không cần xác nhận). Hệ thống báo *"Duyệt văn bản thành công"*. |
| **Thu hồi** (trong menu ba chấm) | Đã có người được gửi VB **VÀ** có quyền thu hồi | Mở hộp xác nhận đỏ — xóa tất cả người nhận và đặt lại trạng thái Chờ duyệt. |
| **Xóa văn bản** (trong menu ba chấm, đỏ) | Có quyền sửa | Mở hộp xác nhận. **Không xóa được nếu văn bản đã duyệt.** |

### 9.3. Khi văn bản **Đã duyệt**

| Nút | Hiển thị khi | Tác dụng |
|---|---|---|
| **Gửi** (chính, xanh dương) | Có quyền gửi | Mở Modal **Gửi văn bản** — chọn danh sách cán bộ nhận (xem mục 10.1). |
| **Bút phê** | Luôn hiển thị | Cuộn xuống và đặt con trỏ vào ô nhập bút phê. |
| **Gửi liên thông** (xanh lá) | Văn bản đã duyệt | Mở Modal — chọn các đơn vị LGSP để gửi văn bản qua trục liên thông (xem mục 10.5). |
| **Nhận bản giấy** (trong menu ba chấm) | Chưa nhận bản giấy **VÀ** có quyền duyệt | Đánh dấu đã nhận đối chiếu bản cứng. Hệ thống báo *"Đã xác nhận nhận bản giấy"*. |
| **Hủy duyệt** (trong menu ba chấm, đỏ) | Có quyền duyệt | Hủy duyệt. **Không hủy được nếu đã gửi cho cán bộ** — phải Thu hồi trước. |
| **Thu hồi** (trong menu ba chấm) | Có quyền thu hồi | Xóa tất cả người nhận (trừ chính mình) và đặt lại trạng thái chưa duyệt. |

### 9.4. Khi văn bản là **Liên thông** (`is_inter_doc = true`)

| Nút | Tác dụng |
|---|---|
| **Nhận bàn giao** (xanh lá) | Popconfirm "Nhận bàn giao văn bản? Bạn có chắc chắn nhận bàn giao văn bản này?". Bấm Xác nhận — hệ thống ghi nhận đã nhận. |
| **Chuyển lại** | Mở Modal **Lý do chuyển lại** — bắt buộc nhập lý do (≥10 ký tự) để gửi trả lại văn bản (xem mục 10.4). |

### 9.5. Quy tắc quyền hạn

Quyền các nút được tính theo công thức sau (khi không phải Quản trị):

- **canEdit (Sửa, Xóa, Tải/Xóa file)** = là người tạo VB **HOẶC** cùng đơn vị + được đánh dấu *"Xử lý văn bản"*.
- **canApprove (Duyệt, Hủy duyệt, Nhận bản giấy, Giao việc, Thêm vào HSCV, Gửi liên thông, Chuyển lưu trữ)** = cùng đơn vị + có chức vụ **Lãnh đạo**.
- **canSend (Gửi cho cán bộ)** = là người tạo VB **HOẶC** cùng đơn vị + Lãnh đạo.
- **canRetract (Thu hồi, Chuyển lại)** = cùng đơn vị + Lãnh đạo.

Quản trị có toàn quyền. Trường hợp đặc biệt: cán bộ **được giao** văn bản (có trong danh sách người nhận) và có chức vụ **Lãnh đạo** — được mở rộng quyền `canApprove`, `canSend`, `canRetract` để xử lý trong phạm vi mình.

---

## 10. Các Drawer / Modal phụ — chi tiết

### 10.1. Modal Gửi văn bản

![Modal Gửi văn bản](screenshots/van_ban_den_04_send_modal.png)

Mở khi bấm **Gửi**. Tiêu đề *"Gửi văn bản"*.

- Ô tích **Chọn tất cả** ở phía trên.
- Danh sách cán bộ gom theo **phòng ban**. Mỗi cán bộ có ô tích kèm họ tên + chức vụ.
- Hệ thống chỉ liệt kê cán bộ thuộc đơn vị mình hoặc các phòng trực thuộc, **chưa bị khóa**.
- Nút **OK** ghi *"Gửi (N)"* — N là số người đã chọn.
- Khi không chọn ai, hệ thống báo *"Chọn ít nhất một người nhận"*.
- Sau khi gửi thành công, hệ thống hiển thị *"Đã gửi cho [N] người nhận"* và cập nhật phần "Phân công xử lý" + "Lịch sử".

### 10.2. Drawer Giao việc (tạo HSCV)

Mở khi bấm **Giao việc** (xanh teal). Tiêu đề *"Giao việc"*. Drawer rộng 720px.

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| **Tên hồ sơ** | Có | Tên HSCV — mặc định lấy từ trích yếu của VB. Tối đa 200 ký tự. |
| **Hạn xử lý** | Có | Mặc định lấy từ Hạn xử lý của VB (nếu có). |
| **Người phụ trách** | Có (≥1) | Chọn nhiều cán bộ — người đầu tiên là **người phụ trách chính**. |
| **Ghi chú** | Không | Tối đa 500 ký tự, có đếm. |

Bấm **Tạo và giao việc** — hệ thống tạo HSCV mới, gắn văn bản hiện tại vào HSCV và phân công cán bộ. Báo: *"Giao việc thành công"*.

### 10.3. Modal Thêm vào HSCV

Mở khi bấm **Thêm vào HSCV**. Tiêu đề *"Thêm vào hồ sơ công việc"*.

- Ô chọn HSCV — danh sách các HSCV của đơn vị, kèm trạng thái: **(Mới)**, **(Đang xử lý)**, **(Trình duyệt)**.
- Khi chưa chọn HSCV mà bấm OK, hệ thống báo *"Vui lòng chọn hồ sơ công việc"*.
- Sau khi thêm thành công, hệ thống báo *"Đã thêm vào hồ sơ công việc"*.

### 10.4. Modal Chuyển lại (chỉ VB liên thông)

Mở khi bấm **Chuyển lại** (chỉ với VB `is_inter_doc`). Tiêu đề *"Lý do chuyển lại"*.

- Ô **Lý do chuyển lại** — bắt buộc, tối đa 500 ký tự, có đếm.
- Quy tắc: lý do phải có **ít nhất 10 ký tự**.
  - Để trống — báo *"Lý do chuyển lại là bắt buộc"* (frontend) hoặc *"Lý do chuyển lại không được để trống"* (SP).
  - Dưới 10 ký tự — báo *"Lý do chuyển lại phải có ít nhất 10 ký tự"*.

Bấm **Chuyển lại** — hệ thống lưu lý do dưới dạng bút phê *"[Chuyển lại] [lý do]"*, đặt văn bản về Chờ duyệt và báo *"Chuyển lại văn bản thành công"*.

### 10.5. Modal Gửi liên thông LGSP

Mở khi bấm **Gửi liên thông** (chỉ khi VB đã duyệt). Tiêu đề *"Gửi liên thông LGSP"*.

- Ô chọn nhiều đơn vị nhận — danh sách các cơ quan trên trục LGSP.
- Khi không chọn đơn vị nào, báo *"Vui lòng chọn ít nhất một đơn vị"*.
- Sau khi gửi, báo *"Đã gửi liên thông cho [N] đơn vị"*.

### 10.6. Drawer Chuyển lưu trữ *(tạm ẩn)*

Phase hiện tại tạm ẩn. Khi bật lại, mở khi bấm **Chuyển lưu trữ** (chỉ VB đã duyệt, chưa lưu trữ). Các trường: Kho lưu trữ (bắt buộc), Phông lưu trữ (bắt buộc), Mục lục hồ sơ, Ký hiệu hồ sơ, Thứ tự VB, Ngôn ngữ, Định dạng, Bút tích, Từ khóa, Mức độ tin cậy, Bản gốc.

---

## 11. Quy trình nghiệp vụ chính

### 11.1. Văn thư tiếp nhận và vào sổ văn bản đến

1. Văn thư bấm **Thêm mới** ở Danh sách.
2. Drawer mở ra, văn thư:
   - Chọn **Sổ văn bản** — hệ thống tự gợi ý **Số đến**.
   - Nhập **Trích yếu nội dung** (bắt buộc).
   - Nhập các thông tin còn lại từ văn bản giấy: ký hiệu, cơ quan ban hành, người ký, ngày ký, độ khẩn, độ mật...
3. Bấm **Tạo mới** — hệ thống báo *"Tạo văn bản đến thành công"*.
4. Văn bản xuất hiện ở Danh sách với trạng thái **Chờ duyệt**.
5. Văn thư mở Chi tiết — bấm **Thêm file** để tải lên file scan/file đính kèm gốc.
6. (Tùy chọn) Khi nhận đối chiếu bản giấy — vào menu ba chấm bấm **Nhận bản giấy**.

### 11.2. Lãnh đạo duyệt và bút phê

1. Lãnh đạo vào Chi tiết một văn bản **Chờ duyệt**.
2. Đọc thông tin + tải file đính kèm để xem.
3. Bấm **Duyệt** — văn bản chuyển sang **Đã duyệt**.
4. Cuộn xuống ô **Ý kiến bút phê** — nhập nội dung chỉ đạo.
5. (Tùy chọn) Tích **"Phân công giải quyết"** — chọn cán bộ + Hạn giải quyết.
6. Bấm **Bút phê & Phân công** (hoặc **Gửi bút phê**) — văn bản được gửi tới cán bộ chỉ định kèm ý kiến chỉ đạo.

### 11.3. Lãnh đạo giao việc qua HSCV

Khi nội dung văn bản cần phối hợp nhiều cán bộ + theo dõi tiến độ chi tiết hơn:

1. Lãnh đạo bấm **Giao việc** ở header.
2. Drawer Giao việc mở:
   - Tên hồ sơ (mặc định = trích yếu).
   - Hạn xử lý (mặc định = Hạn xử lý của VB).
   - Chọn 1 hoặc nhiều **Người phụ trách** (người đầu = phụ trách chính).
   - Ghi chú (tùy chọn).
3. Bấm **Tạo và giao việc** — hệ thống tạo HSCV mới, gắn VB này vào và phân công cán bộ.
4. Cán bộ nhận thấy HSCV trong danh sách HSCV của mình.

### 11.4. Cán bộ xử lý văn bản

1. Cán bộ thấy văn bản mới (đậm, có nhãn *"Gửi cho tôi"*) ở Danh sách.
2. Bấm vào trích yếu để mở Chi tiết — hệ thống tự đánh dấu **đã đọc**.
3. Tải file đính kèm về xử lý.
4. Nếu được giao việc qua HSCV — vào HSCV để cập nhật tiến độ, trao đổi ý kiến.
5. Trường hợp văn bản gửi nhầm hoặc không thuộc thẩm quyền (chỉ với VB liên thông):
   - Bấm **Chuyển lại**, nhập lý do (≥10 ký tự).
   - Bấm **Chuyển lại** — văn bản trở về Chờ duyệt với bút phê *"[Chuyển lại] [lý do]"*.

### 11.5. Văn thư rà soát và lưu trữ

1. Văn thư rà soát các văn bản đã đánh dấu **Đã nhận bản giấy** + **Đã duyệt**.
2. Khi đến kỳ lưu trữ — bấm **Chuyển lưu trữ** (khi tính năng bật), nhập thông tin lưu trữ.
3. Văn bản chuyển sang trạng thái **Đã lưu trữ** — không thao tác tiếp được.

### 11.6. Liên thông LGSP — gửi và nhận

**Gửi đi**: Sau khi duyệt — bấm **Gửi liên thông**, chọn đơn vị nhận trên trục LGSP, bấm **Gửi liên thông**. Hệ thống gọi API LGSP đẩy văn bản sang.

**Nhận về**: Văn bản từ tỉnh khác tự động chui vào Danh sách với nguồn **LGSP**. Nếu là văn bản liên thông cần xác nhận, sẽ có nút **Nhận bàn giao** — Popconfirm xác nhận, bấm Xác nhận để ghi nhận.

---

## 12. Sơ đồ vòng đời văn bản đến

```
┌───────────────────────────────────────────────────────────┐
│  NGUỒN: Nhập tay / Nội bộ / LGSP                          │
└──────────────────────┬────────────────────────────────────┘
                       │
                       ▼
                ┌──────────────┐
                │  Chờ duyệt   │  ◄── Văn thư tạo (vào sổ)
                └──────┬───────┘
                       │
   ┌───────────────────┼───────────────────┐
   │                   │                   │
   │ (Sửa/Xóa)         │ (Lãnh đạo Duyệt)  │ (Hủy duyệt)
   │                   ▼                   │
   │            ┌──────────────┐           │
   │            │   Đã duyệt   │ ──────────┘
   │            └──────┬───────┘
   │                   │
   │     ┌─────────────┼──────────────┐
   │     │             │              │
   │  (Gửi cho      (Bút phê +    (Gửi liên
   │  cán bộ)      Phân công)    thông LGSP)
   │     │             │              │
   │     ▼             ▼              ▼
   │  ┌───────────────────────────────────┐
   │  │  Cán bộ xử lý / HSCV / LGSP gửi   │
   │  └────────────┬──────────────────────┘
   │               │
   │     ┌─────────┴─────────┐
   │     │                   │
   │  (Thu hồi)         (Chuyển lại
   │     │              — VB liên thông)
   │     ▼                   │
   │  Chờ duyệt              ▼
   │     │              (về Chờ duyệt
   │     │               + bút phê lý do)
   │     │
   │     ▼
   └─►  (Chuyển lưu trữ — khi tính năng bật)
         │
         ▼
   ┌──────────────┐
   │  Đã lưu trữ  │  (không thao tác tiếp)
   └──────────────┘
```

---

## 13. Lưu ý / Ràng buộc nghiệp vụ

### 13.1. Số đến tự động — theo sổ và năm

Hệ thống cấp **Số đến** dựa trên công thức:

> *Số đến mới = MAX(số đến trong cùng sổ, cùng đơn vị, cùng năm hiện tại) + 1*

Đầu năm, số bắt đầu lại từ **1** cho mỗi sổ. Văn thư có thể chỉnh tay số đến trong Drawer Thêm — nhưng hệ thống không kiểm tra trùng nội bộ; nếu trùng sẽ gây nhầm lẫn về sổ — không nên làm.

### 13.2. Nguồn văn bản và quyền sửa

Văn bản có 3 nguồn — chỉ nguồn **Nhập tay (manual)** mới được sửa nội dung gốc:

- **Nội bộ (internal)**: Tự sinh từ văn bản đi của Sở/đơn vị khác — không được sửa, chỉ phân công xử lý.
- **LGSP (external_lgsp)**: Nhận qua trục liên thông — không được sửa, chỉ tiếp nhận hoặc chuyển lại.

Khi cố sửa văn bản ngoài Nhập tay, hệ thống chặn với thông báo: *"Văn bản đến từ đơn vị nội bộ không được sửa nội dung gốc. Chỉ có thể tiếp nhận / phân công xử lý / từ chối."* (hoặc *"...từ LGSP..."* tùy nguồn).

### 13.3. Không xóa được văn bản đã duyệt

Khi xóa một văn bản đã duyệt, hệ thống báo *"Không thể xóa văn bản đã được duyệt"*. Phải **Hủy duyệt** trước. Tuy nhiên không hủy duyệt được nếu văn bản đã được gửi cho cán bộ — phải **Thu hồi** trước.

### 13.4. Thu hồi — xóa người nhận, đặt lại Chờ duyệt

Khi bấm **Thu hồi**:

- Hệ thống xóa tất cả người nhận (giữ lại chính người thu hồi).
- Đặt lại trạng thái **Chờ duyệt** (không còn duyệt).
- Báo: *"Thu hồi thành công — đã xóa [N] người nhận"*.

Sau khi thu hồi, văn bản có thể được sửa lại, sau đó duyệt lại và gửi lại nếu cần.

### 13.5. "Gửi cho tôi" — đồng nghiệp gửi thay

Khi một cán bộ nhận được văn bản do người khác chuyển tới (qua chức năng Gửi hoặc Bút phê & Phân công), ở Danh sách văn bản đó hiển thị nhãn **"Gửi cho tôi"** kèm tooltip: *"Do [tên người gửi] gửi lúc [thời gian]"*. Giúp cán bộ phân biệt văn bản chính mình tiếp nhận với văn bản được giao.

### 13.6. Đánh dấu đã đọc tự động

Khi mở Chi tiết một văn bản, hệ thống **tự đánh dấu đã đọc** cho người dùng hiện tại. Văn bản chuyển từ chữ in đậm sang in thường ở Danh sách. Có thể đánh dấu hàng loạt qua nút **Đánh dấu đã đọc (N)** ở Danh sách (chọn nhiều dòng trước).

### 13.7. Hạn xử lý quá hạn

Khi **Hạn xử lý** đã qua so với hôm nay, ở Chi tiết hiển thị nhãn đỏ **"Quá hạn"** bên cạnh ngày hạn. Đây là dấu hiệu để lãnh đạo đôn đốc cán bộ xử lý.


---

*Tài liệu được biên soạn dựa trên hệ thống thực tế đang triển khai. Mọi thắc mắc vui lòng liên hệ với đội phát triển để được hỗ trợ.*
