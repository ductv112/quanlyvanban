# Hướng dẫn sử dụng: Thông báo (Chuông cá nhân + Thông báo nội bộ)

Tài liệu này mô tả đầy đủ cách sử dụng tính năng thông báo của hệ thống Quản lý văn bản điện tử (e-Office), bao gồm **hai vùng tách biệt** và bổ sung cho nhau: **chuông thông báo cá nhân trên thanh đầu trang** và **trang Thông báo nội bộ** (đường dẫn `/thong-bao`).

---

## 1. Giới thiệu

Trong quá trình làm việc, mỗi cán bộ thường nhận được nhiều loại thông tin từ hệ thống: kết quả ký số, được giao văn bản, được giao hồ sơ công việc, được nhắc tới trong bút phê chỉ đạo, các thông báo chung do quản trị viên gửi đến đơn vị… Hệ thống chia các thông tin này thành **hai luồng riêng**, hiển thị ở hai nơi rõ ràng:

- **Chuông thông báo cá nhân** trên thanh đầu trang — biểu tượng chuông kèm số đếm chưa đọc, có ở mọi màn hình. Chỉ hiển thị các sự kiện **liên quan trực tiếp đến chính người đăng nhập** (ký số của mình, được giao việc cho mình, được nhắc tên mình…). Người dùng tự thực hiện một thao tác mà sinh ra thông báo cho chính họ thì **không nhận chuông** (ví dụ: tự tạo HSCV cho mình, tự gửi văn bản lại cho mình) — đây là quy ước "không tự thông báo".
- **Trang Thông báo nội bộ** (`/thong-bao`) — danh sách thông báo dùng chung cho **toàn bộ cán bộ trong cùng một đơn vị**, do quản trị viên hoặc cán bộ có quyền tạo (ví dụ: thông báo nghỉ lễ, lịch tập huấn, thay đổi quy trình nội bộ…). Truy cập từ menu bên trái mục **Thông báo nội bộ**.

Hai luồng này **độc lập về dữ liệu**: mở trang Thông báo nội bộ thấy 10 thông báo của đơn vị, nhưng chuông góc phải có thể vẫn trống nếu cá nhân chưa có việc gì được giao. Đây là hành vi đúng theo thiết kế, không phải lỗi.

Hai khu vực này hiển thị **hai nguồn thông báo khác nhau** (xem mục 4), tuy đều là "thông báo" nhưng được lưu riêng để phục vụ hai mục đích khác nhau:

- Chuông tập trung **các thông báo cá nhân** (gắn với riêng một tài khoản — ví dụ: "Ký số thành công cho file của bạn").
- Trang `/thong-bao` hiển thị **các thông báo theo đơn vị** (do quản trị viên hoặc văn thư đơn vị gửi tới toàn bộ nhân sự cùng đơn vị — ví dụ thông báo nội bộ).

Việc đánh dấu đã đọc hay chưa đọc là **của riêng từng tài khoản**, không ảnh hưởng đến người khác cùng đơn vị.

---

## 2. Bố cục Chuông trên thanh đầu trang

![Chuông thông báo trên thanh đầu trang](screenshots/thong_bao_01_bell_header.png)

Chuông thông báo nằm ở **góc trên bên phải mọi màn hình**, kế bên ảnh đại diện người dùng, gồm:

- **Biểu tượng chuông** (BellOutlined).
- **Huy hiệu số** màu đỏ ở góc phải trên của chuông — hiển thị số thông báo **chưa đọc**. Nếu vượt quá 99, hiển thị **99+**. Khi không có thông báo chưa đọc, huy hiệu ẩn đi.

Bấm vào biểu tượng chuông sẽ mở **bảng thả xuống (dropdown)** với cấu trúc:

- **Phần đầu**: tiêu đề **"Thông báo"** ở bên trái, nút **"Đánh dấu đã đọc tất cả"** ở bên phải (nút này bị mờ đi khi không có thông báo chưa đọc).
- **Phần thân**: tối đa **10 thông báo gần nhất**, sắp xếp theo thời gian — mới nhất lên đầu.
  - Mỗi thông báo gồm: biểu tượng (xem mục 4), **tiêu đề** (in đậm nếu chưa đọc), **mô tả ngắn**, và **thời điểm tương đối** (ví dụ *"3 phút trước"*, *"2 giờ trước"*).
  - Thông báo **chưa đọc** có nền sáng nổi bật hơn so với thông báo đã đọc.
- Khi chưa có thông báo nào, hiển thị thông báo *"Không có thông báo"*.

Bấm vào một dòng thông báo trong bảng thả xuống sẽ:

1. Đánh dấu thông báo đó là đã đọc (huy hiệu số trên chuông giảm đi 1).
2. Đóng bảng thả xuống.
3. **Mở thẳng tới màn hình liên quan** (ví dụ: thông báo ký số → mở tab "Đã ký" trong màn hình **Danh sách giao dịch ký số**).

> **Lưu ý**: Khi có sự kiện mới (ví dụ vừa ký xong một văn bản) hệ thống sẽ **tự động cập nhật** số trên huy hiệu và hiển thị **thông báo nổi (toast)** ở góc trên bên phải trong khoảng 3 giây — không cần tải lại trang.

---

## 3. Bố cục Trang Thông báo nội bộ (`/thong-bao`)

![Màn hình Thông báo nội bộ](screenshots/thong_bao_02_main_page.png)

Truy cập từ menu bên trái → bấm mục **Thông báo nội bộ** (biểu tượng chuông). Nếu trên menu có số đếm in đậm bên cạnh nhãn, đó là số thông báo chưa đọc của trang này (theo nguồn đơn vị).

Bố cục màn hình gồm:

- **Phần đầu trang**:
  - Tiêu đề **"Thông báo nội bộ"** kèm biểu tượng chuông và dòng mô tả ngắn *"Quản lý và theo dõi các thông báo nội bộ của đơn vị"*.
  - **Nút "Đánh dấu đã đọc tất cả"** — đánh dấu toàn bộ thông báo đang còn chưa đọc thành đã đọc.
  - **Nút "Tạo thông báo"** (màu xanh) — chỉ hiển thị với tài khoản **Quản trị**. Người dùng thường không thấy nút này.
- **Thanh phân loại (tab)**:
  - **Tất cả** — hiển thị toàn bộ thông báo của đơn vị, bất kể đã đọc hay chưa.
  - **Chưa đọc** — chỉ thông báo còn chưa đọc.
  - **Đã đọc** — chỉ thông báo đã được đánh dấu đã đọc.
- **Danh sách thông báo**:
  - Mỗi thông báo gồm: biểu tượng chuông tròn, **tiêu đề** (in đậm nếu chưa đọc, kèm chấm xanh nhỏ ở đầu dòng), **thời gian** dạng `DD/MM/YYYY HH:mm` ở bên phải, **nội dung** rút gọn 2 dòng phía dưới.
  - Bấm vào dòng thông báo còn chưa đọc → đánh dấu thành đã đọc; chấm xanh và in đậm sẽ biến mất.
- **Phân trang**: 20 thông báo / trang. Phân trang chỉ hiển thị khi tổng số thông báo vượt quá 20.
- **Khi danh sách trống**: hiển thị biểu tượng chuông xám lớn cùng dòng chữ *"Chưa có thông báo"* và *"Hệ thống sẽ thông báo khi có văn bản mới hoặc việc được giao."*

---

## 4. Các loại thông báo

Hệ thống phân biệt **hai nguồn thông báo** với hai vùng hiển thị khác nhau:

| Nguồn | Hiển thị ở đâu | Khi nào hệ thống tạo | Bấm vào dẫn đến đâu |
|---|---|---|---|
| **Ký số thành công** (`sign_completed`) | Chuông thông báo trên thanh đầu trang | Sau khi giao dịch ký số của chính người dùng kết thúc thành công | **Danh sách giao dịch ký số** → tab **Đã ký** |
| **Ký số thất bại / hết hạn / đã hủy** (`sign_failed`) | Chuông thông báo trên thanh đầu trang | Khi giao dịch ký số của chính người dùng bị **thất bại**, **hết hạn** (không xác nhận trong 3 phút) hoặc **bị hủy** | **Danh sách giao dịch ký số** → tab **Thất bại** |
| **Văn bản đến được giao cho mình** (`incoming_doc_assigned`) | Chuông thông báo trên thanh đầu trang | Khi văn thư / lãnh đạo gửi văn bản đến cho cán bộ này, hoặc khi văn bản được phân công cho cán bộ qua thao tác **Gửi** trên màn hình chi tiết VB đến | **Chi tiết Văn bản đến** liên quan |
| **Được giao xử lý hồ sơ công việc** (`task_assigned`) | Chuông thông báo trên thanh đầu trang | Khi tạo HSCV mới với mình là người phụ trách, hoặc khi mình được **phân công thêm** vào HSCV (vai trò phụ trách hoặc phối hợp) | **Chi tiết Hồ sơ công việc** liên quan |
| **Bút phê / ý kiến chỉ đạo gắn tên mình** (`leader_note_received`) | Chuông thông báo trên thanh đầu trang | Khi lãnh đạo có ý kiến chỉ đạo trên văn bản đến và **chỉ định đích danh** mình trong phần phân công | **Chi tiết Văn bản đến** liên quan |
| **Thông báo nội bộ đơn vị** | Trang **Thông báo** (`/thong-bao`) | Quản trị viên hoặc cán bộ có quyền **bấm "Tạo thông báo"** trên trang này (xem mục 6.4) | Không có đường dẫn — chỉ hiển thị nội dung và đánh dấu đã đọc tại chỗ |

> **Phân biệt**:
>
> - Thông báo **ký số** là **của riêng từng người** — chỉ chính người yêu cầu ký mới thấy.
> - Thông báo **nội bộ đơn vị** dùng chung cho toàn bộ cán bộ thuộc cùng một **đơn vị** (cấp đơn vị cha — Sở, Ban, Ngành) — ai cùng đơn vị đều thấy và mỗi người tự đánh dấu đã đọc cho riêng mình.

> **Phạm vi thông báo qua chuông tại phiên bản hiện tại**: chuông trên thanh đầu trang phát thông báo cá nhân cho **5 nhóm sự kiện**:
>
> - *Ký số thành công* và *Ký số thất bại / hết hạn / đã hủy* (biểu tượng và màu riêng).
> - *Văn bản đến vừa được giao cho mình* (`incoming_doc_assigned`) — sinh khi văn thư hoặc lãnh đạo gửi văn bản đến cho cán bộ này; bấm vào mở thẳng **chi tiết Văn bản đến**.
> - *Được giao xử lý hồ sơ công việc* (`task_assigned`) — sinh khi tạo HSCV mới với mình là người phụ trách, hoặc khi mình được phân công thêm vào HSCV (vai trò phụ trách / phối hợp); bấm vào mở thẳng **chi tiết Hồ sơ công việc**.
> - *Bút phê / ý kiến chỉ đạo gắn tên mình* (`leader_note_received`) — sinh khi lãnh đạo có ý kiến chỉ đạo và chỉ định đích danh; bấm vào mở thẳng **chi tiết Văn bản đến** liên quan.
>
> Các sự kiện chưa nối vào chuông ở phiên bản này: gửi Văn bản đi, phê duyệt dự thảo, chuyển tiếp HSCV, ý kiến chuyển tiếp, lịch họp, tin nhắn nội bộ.

---

## 5. Các nút và thao tác

| Nút / Thao tác | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| **Biểu tượng chuông** | Góc trên bên phải mọi màn hình | Luôn hiển thị | Bật / tắt bảng thả xuống thông báo. |
| **Huy hiệu số (badge) trên chuông** | Trên biểu tượng chuông | Khi có thông báo chưa đọc | Hiển thị số thông báo cá nhân chưa đọc (tối đa hiển thị **99+**). |
| **Đánh dấu đã đọc tất cả** (trong bảng thả xuống) | Phần đầu của bảng thả xuống | Luôn hiển thị; mờ đi nếu không có thông báo chưa đọc | Đánh dấu toàn bộ thông báo cá nhân thành đã đọc. Huy hiệu trên chuông trở về 0. |
| **Bấm vào một dòng thông báo** (trong bảng thả xuống) | Trong bảng thả xuống | Luôn hiển thị | Đánh dấu dòng đó là đã đọc, đóng bảng và **chuyển tới màn hình liên quan** (nếu thông báo có gắn đường dẫn). |
| **Mục "Thông báo" trong menu bên trái** | Menu chính bên trái | Luôn hiển thị | Mở **trang Thông báo** (`/thong-bao`). |
| **Tab Tất cả / Chưa đọc / Đã đọc** | Phần đầu trang Thông báo | Luôn hiển thị | Lọc danh sách hiển thị bên dưới theo trạng thái đọc. |
| **Đánh dấu đã đọc tất cả** (trang Thông báo) | Góc trên bên phải trang Thông báo | Luôn hiển thị | Đánh dấu toàn bộ thông báo đơn vị còn chưa đọc thành đã đọc. Hệ thống báo **"Đã đánh dấu tất cả là đã đọc"**. |
| **Tạo thông báo** (trang Thông báo) | Góc trên bên phải trang Thông báo | **Chỉ Quản trị viên** (admin) | Mở cửa sổ phụ để tạo thông báo nội bộ mới gửi cho toàn đơn vị. |
| **Bấm vào một dòng thông báo** (trang Thông báo) | Bất kỳ dòng nào trong danh sách | Luôn hiển thị | Đánh dấu dòng đó là đã đọc (chấm xanh và in đậm biến mất). |
| **Nút Hủy** (cửa sổ Tạo thông báo) | Góc trên bên phải cửa sổ phụ | Trong cửa sổ Tạo thông báo | Đóng cửa sổ, không lưu. |
| **Nút Tạo thông báo** (trong cửa sổ phụ) | Góc trên bên phải cửa sổ phụ | Trong cửa sổ Tạo thông báo | Lưu và phát hành thông báo cho đơn vị. |

---

## 6. Quy trình thao tác

### 6.1. Xem nhanh thông báo cá nhân qua chuông

1. Trên thanh đầu trang, để ý **huy hiệu số** trên biểu tượng chuông — đó là số thông báo chưa đọc.
2. Bấm vào **biểu tượng chuông**.
3. Bảng thả xuống mở ra với 10 thông báo gần nhất. Các thông báo chưa đọc có **tiêu đề in đậm** và nền nổi bật hơn.
4. Đọc nhanh tiêu đề, mô tả ngắn và thời gian *"x phút/giờ/ngày trước"* để nắm tình hình.

### 6.2. Mở chi tiết một thông báo cá nhân

1. Trong bảng thả xuống của chuông, **bấm vào dòng thông báo** muốn xem.
2. Hệ thống đồng thời thực hiện 3 việc:
   - Đánh dấu thông báo đó là đã đọc.
   - Giảm huy hiệu trên chuông đi 1.
   - Chuyển sang màn hình liên quan (ví dụ: thông báo ký số sẽ mở **Danh sách giao dịch ký số**).
3. Tại màn hình liên quan, có thể xem chi tiết và thực hiện thao tác tiếp theo (xem file đã ký, kiểm tra lý do thất bại…).

### 6.3. Đánh dấu đã đọc tất cả

**Cách 1 — từ chuông**:

1. Bấm vào biểu tượng chuông.
2. Bấm **"Đánh dấu đã đọc tất cả"** ở phần đầu bảng thả xuống.
3. Toàn bộ thông báo trong danh sách trở thành đã đọc, huy hiệu trên chuông biến mất.

**Cách 2 — từ trang Thông báo**:

1. Vào menu bên trái → **Thông báo**.
2. Bấm nút **"Đánh dấu đã đọc tất cả"** ở góc trên bên phải.
3. Hệ thống thông báo **"Đã đánh dấu tất cả là đã đọc"**, danh sách cập nhật ngay.

> Hai nút này hoạt động trên **hai nguồn dữ liệu khác nhau**: nút trên chuông áp dụng cho thông báo cá nhân (ký số), nút trên trang `/thong-bao` áp dụng cho thông báo đơn vị. Cần thực hiện cả hai nếu muốn xóa hết huy hiệu chưa đọc ở cả hai nơi.

### 6.4. Tạo thông báo nội bộ (chỉ Quản trị viên)

![Cửa sổ Tạo thông báo mới](screenshots/thong_bao_03_create_drawer.png)

1. Vào menu bên trái → **Thông báo**.
2. Bấm nút **Tạo thông báo** (màu xanh) ở góc trên bên phải. Cửa sổ phụ mở ra từ bên phải.
3. Trong cửa sổ, điền:
   - **Tiêu đề** (bắt buộc) — tối đa **300 ký tự**, có hiển thị số ký tự đã nhập.
   - **Nội dung** (bắt buộc) — vùng văn bản 6 dòng, tối đa **5.000 ký tự**, có hiển thị số ký tự đã nhập.
4. Bấm **Tạo thông báo**. Hệ thống thông báo **"Tạo thông báo thành công"** và đóng cửa sổ. Danh sách tự động tải lại — thông báo vừa tạo xuất hiện ở đầu danh sách.
5. Nếu bấm **Hủy** thì đóng cửa sổ và không lưu.

> Thông báo này được phát hành cho **toàn bộ cán bộ cùng đơn vị (đơn vị cha)** với người tạo. Mỗi người sẽ thấy thông báo trong trang Thông báo của mình ở trạng thái chưa đọc; sau khi bấm vào / đánh dấu đã đọc thì thông báo trở thành đã đọc **chỉ với riêng người đó**.

### 6.5. Lọc thông báo trên trang Thông báo

1. Vào trang **Thông báo**.
2. Bấm tab tương ứng:
   - **Tất cả** — toàn bộ.
   - **Chưa đọc** — chỉ thông báo chưa đọc.
   - **Đã đọc** — chỉ thông báo đã đọc.
3. Danh sách bên dưới được lọc lại ngay. Trang số quay về 1 mỗi khi đổi tab.

---

## 7. Lưu ý / Ràng buộc nghiệp vụ

### 7.1. Hai vùng thông báo độc lập

Chuông trên thanh đầu trang và trang `/thong-bao` đọc **hai nguồn dữ liệu khác nhau**:

- **Chuông** → các thông báo cá nhân (kết quả ký số…).
- **Trang `/thong-bao`** → các thông báo nội bộ đơn vị do người có quyền tạo thủ công.

Vì vậy, nếu chỉ vào trang `/thong-bao` và đánh dấu đã đọc tất cả, **huy hiệu trên chuông không bị giảm**. Ngược lại, đánh dấu đã đọc trong chuông cũng không ảnh hưởng đến danh sách trên trang `/thong-bao`.

### 7.2. Tự động cập nhật khi có thông báo mới

Khi có sự kiện mới (kết thúc một giao dịch ký số…), hệ thống đồng thời:

1. **Lưu lại** thông báo vào hệ thống — kể cả khi người dùng đang ngoại tuyến cũng thấy được khi đăng nhập lại.
2. **Tự động cập nhật** số trên huy hiệu của chuông và (nếu đang mở bảng thả xuống) làm mới danh sách.
3. **Hiển thị thông báo nổi (toast)** trong khoảng 3 giây ở góc trên bên phải, kèm tiêu đề và mô tả ngắn.

Người dùng không cần làm mới (F5) để thấy thông báo mới.

### 7.3. Phạm vi cá nhân của trạng thái đọc

Mỗi thông báo có một trạng thái **đã đọc / chưa đọc** **riêng cho từng tài khoản**. Người này đánh dấu đã đọc không ảnh hưởng đến người khác — kể cả khi cùng nhận một thông báo nội bộ đơn vị.

### 7.4. Quyền tạo thông báo nội bộ

Nút **Tạo thông báo** trên trang `/thong-bao` chỉ hiển thị với tài khoản có vai trò **Quản trị**. Người dùng thường không thấy nút này và không tự tạo được. Nếu cần phát hành thông báo cho đơn vị, liên hệ với cán bộ phụ trách hoặc văn thư.

### 7.5. Giới hạn ký tự khi tạo thông báo

- **Tiêu đề**: tối đa **300 ký tự**, không được để trống.
- **Nội dung**: tối đa **5.000 ký tự**, không được để trống.

Nếu để trống một trong hai, hệ thống báo **"Vui lòng nhập tiêu đề"** hoặc **"Vui lòng nhập nội dung"** ngay dưới ô tương ứng.

### 7.6. Hiển thị tối đa 10 trong chuông, 20 trong trang

- Bảng thả xuống của chuông chỉ hiển thị **10 thông báo cá nhân gần nhất**. Thông báo cá nhân (ký số) cũ hơn 10 mục **không có giao diện để xem lại** — chuông không có nút "Xem tất cả" và cũng không có trang riêng cho danh sách thông báo cá nhân. Trang `/thong-bao` (mở từ menu **Thông báo**) chỉ hiển thị **thông báo nội bộ đơn vị**, **không** liệt kê thông báo ký số. Vì vậy: khi cần tra cứu lịch sử các giao dịch ký số đã xảy ra, hãy vào thẳng **Ký số > Danh sách giao dịch** và lọc theo tab **Đã ký** / **Thất bại** thay vì tìm trên chuông.
- Trang `/thong-bao` hiển thị **20 thông báo / trang** với phân trang đầy đủ.

### 7.7. Bảng tổng hợp các thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Đánh dấu đã đọc tất cả (trang Thông báo) | Đã đánh dấu tất cả là đã đọc |
| Đánh dấu đã đọc tất cả (trang Thông báo) — thất bại | Thao tác thất bại. Vui lòng thử lại. |
| Tạo thông báo thành công (trang Thông báo) | Tạo thông báo thành công |
| Tạo thông báo (trang Thông báo) — thất bại | Tạo thông báo thất bại. Vui lòng thử lại. |
| Tạo thông báo (trang Thông báo) — bỏ trống tiêu đề | Vui lòng nhập tiêu đề |
| Tạo thông báo (trang Thông báo) — bỏ trống nội dung | Vui lòng nhập nội dung |
| Tạo thông báo (trang Thông báo) — tiêu đề rỗng phía máy chủ | Tiêu đề thông báo là bắt buộc |
| Tạo thông báo (trang Thông báo) — tiêu đề quá 300 ký tự | Tiêu đề không được vượt quá 300 ký tự |
| Tạo thông báo (trang Thông báo) — nội dung rỗng phía máy chủ | Nội dung thông báo là bắt buộc |
| Toast nổi khi ký số thành công (chuông) | **Ký số thành công** — Giao dịch #N đã hoàn tất |
| Toast nổi khi ký số thất bại (chuông) | **Ký số thất bại** — chi tiết lý do |
| Toast nổi khi ký số hết hạn (chuông) | **Ký số hết hạn** — chi tiết lý do |
| Toast nổi khi ký số bị hủy (chuông) | **Đã hủy ký số** — chi tiết lý do |
| Tiêu đề thông báo bell — ký số thành công | Ký số thành công: *(tên file)* |
| Tiêu đề thông báo bell — ký số thất bại | Ký số thất bại |
| Tiêu đề thông báo bell — ký số hết hạn | Ký số hết hạn |
| Bảng thả xuống chuông — không có thông báo | Không có thông báo |
| Trang Thông báo — danh sách rỗng | Chưa có thông báo / Hệ thống sẽ thông báo khi có văn bản mới hoặc việc được giao. |
| Đánh dấu một thông báo (chuông) — không tìm thấy / không phải của mình | Thông báo không tồn tại hoặc không thuộc về bạn |

---

*Tài liệu được biên soạn dựa trên hệ thống thực tế đang triển khai. Mọi thắc mắc vui lòng liên hệ với đội phát triển để được hỗ trợ.*
