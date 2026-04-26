# Hồ sơ công việc

## 1. Giới thiệu

Hồ sơ công việc (HSCV) là tập hồ sơ điện tử gắn với một vụ việc cụ thể trong cơ quan. Mỗi HSCV cho phép cán bộ quản lý các văn bản liên quan, phân công cán bộ phối hợp xử lý, theo dõi tiến độ hoàn thành, ghi nhận ý kiến trao đổi giữa các bên, đính kèm tệp tin và tổ chức theo cây hồ sơ cha — hồ sơ con.

Module gồm hai phần chính:

- **Danh sách hồ sơ công việc**: nơi cán bộ tra cứu, lập mới, lọc và xuất dữ liệu HSCV theo nghiệp vụ.
- **Chi tiết hồ sơ công việc**: nơi cán bộ thực hiện toàn bộ thao tác xử lý nội dung của một HSCV cụ thể (chuyển xử lý, trình ký, duyệt, ký số, lấy số văn bản, chuyển tiếp, hủy bỏ, mở lại...).

Phạm vi dữ liệu cán bộ nhìn thấy phụ thuộc vai trò:

- **Quản trị**: thấy toàn bộ HSCV của tất cả phòng ban, có ô lọc Phòng ban dạng cây.
- **Người dùng thường**: chỉ thấy HSCV trong phạm vi đơn vị mình (đơn vị cha và các phòng ban con trực thuộc), có ô lọc Đơn vị dạng danh sách.

## 2. Quy trình thao tác và ràng buộc nghiệp vụ

Vòng đời chuẩn của một HSCV gồm các trạng thái:

1. **Mới tạo** (status = 0): cán bộ vừa lập HSCV. Có thể sửa, xóa, chuyển xử lý, chuyển tiếp HSCV cho người khác.
2. **Đang xử lý** (status = 1): HSCV đã được chuyển vào xử lý. Cập nhật tiến độ, lấy số văn bản (nếu có), trình ký lên lãnh đạo.
3. **Đã trình ký** (status = 3): lãnh đạo nhận hồ sơ. Lãnh đạo có thể duyệt, từ chối hoặc trả về.
4. **Hoàn thành** (status = 4): lãnh đạo đã duyệt. Tiến độ tự động đặt 100%. Vẫn có thể mở lại nếu cần.
5. **Trả về** (status = -2): lãnh đạo trả về để bổ sung. Cán bộ có thể xử lý lại hoặc hủy bỏ.
6. **Bị từ chối** (status = -1): lãnh đạo từ chối. Cán bộ có thể xử lý lại hoặc hủy bỏ.
7. **Đã hủy** (status = -3): HSCV đã bị hủy bỏ kèm lý do.

Ràng buộc nghiệp vụ chính:

- Tên HSCV bắt buộc, không quá 500 ký tự.
- Hạn giải quyết phải sau hoặc bằng ngày mở.
- Chỉ ở trạng thái **Mới tạo** mới sửa, xóa được HSCV.
- Chỉ ở trạng thái **Bị từ chối** hoặc **Trả về** mới hủy được HSCV; lý do hủy bắt buộc.
- Chỉ ở trạng thái **Hoàn thành** mới mở lại được HSCV (về Đang xử lý, giữ nguyên tiến độ 100%).
- Chuyển tiếp HSCV chỉ chuyển được cho người cùng đơn vị và không trùng với người hiện tại.
- Lấy số văn bản: số = MAX(số) + 1 trong cùng sổ và năm tạo HSCV; HSCV đã có số không lấy lại được.
- Phân công cán bộ: tối đa 50 cán bộ mỗi lần. Mỗi cán bộ có vai trò Phụ trách hoặc Phối hợp.
- Tệp đính kèm: tối đa 50 MB mỗi tệp; định dạng cho phép gồm PDF, Word, Excel, PNG, JPG.
- Ký số: chỉ áp dụng cho tệp PDF, chỉ lãnh đạo ký được chỉ định mới có nút Ký số, và chỉ khi HSCV đang Đã trình ký.

## 3. Các màn hình chức năng

### 3.1. Màn hình Danh sách hồ sơ công việc

![Danh sách hồ sơ công việc](screenshots/hscv_danh_sach_01_main.png)

#### Bố cục màn hình

Từ trên xuống:

- Đầu trang: tiêu đề "Hồ sơ công việc" bên trái; bên phải là cụm nút In, Xuất Excel, Tạo hồ sơ mới.
- Hàng tab phân loại: 9 tab kèm Badge đếm số lượng theo trạng thái và phạm vi tạo.
- Hàng bộ lọc phụ: ô tìm kiếm tên hồ sơ, ô chọn Lĩnh vực, ô chọn Đơn vị/Phòng ban, ô khoảng ngày, nút Tìm kiếm và Đặt lại.
- Bảng dữ liệu: 9 cột (xem bên dưới); cột thao tác cuối cùng là nút ba chấm dọc.
- Phân trang ở cuối bảng: chuyển trang, đổi số dòng/trang, hiển thị "Tổng N hồ sơ".

#### Các tab phân loại

| Tab | Phạm vi |
|---|---|
| Tất cả | Toàn bộ HSCV người dùng được phép xem. |
| Tôi tạo | HSCV do tài khoản đang đăng nhập tạo. |
| Mới tạo | HSCV ở trạng thái Mới tạo (status = 0). |
| Đang xử lý | HSCV ở trạng thái Đang xử lý (status = 1). |
| Chờ duyệt | HSCV đã trình ký, chờ lãnh đạo duyệt (status = 3). |
| Hoàn thành | HSCV đã được duyệt (status = 4). |
| Trả về | HSCV bị lãnh đạo trả về (status = -2). |
| Bị từ chối | HSCV bị lãnh đạo từ chối (status = -1). |
| Đã hủy | HSCV đã bị hủy bỏ (status = -3). |

Chuyển tab — bảng tự đưa về trang 1 và tải lại danh sách.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| In | Góc trên bên phải | Luôn hiển thị | Mở hộp thoại in của trình duyệt với phần "DANH SÁCH HỒ SƠ CÔNG VIỆC", ngày in và bảng dữ liệu HSCV hiện tại. |
| Xuất Excel | Góc trên bên phải | Luôn hiển thị | Tải tệp `.xlsx` chứa toàn bộ HSCV theo bộ lọc và tab đang chọn (tối đa 10.000 dòng). Tệp có 10 cột: STT, Tên hồ sơ, Loại văn bản, Lĩnh vực, Ngày mở, Hạn giải quyết, Trạng thái, Người phụ trách, Lãnh đạo ký, Tiến độ. |
| Tạo hồ sơ mới | Góc trên bên phải | Luôn hiển thị | Mở Drawer Tạo hồ sơ công việc. |
| Tìm kiếm | Hàng bộ lọc | Luôn hiển thị | Áp dụng các bộ lọc đang chọn, đưa danh sách về trang 1. |
| Đặt lại | Hàng bộ lọc | Luôn hiển thị | Xóa Từ khóa, Lĩnh vực, Đơn vị/Phòng ban, Khoảng ngày và đưa về trang 1. |
| Ba chấm dọc | Cột cuối mỗi dòng | Luôn hiển thị | Mở menu thao tác. Mặc định có Xem chi tiết. Khi HSCV ở trạng thái Mới tạo có thêm Sửa và Xóa. |

#### Các cột / trường dữ liệu

| Cột | Mô tả |
|---|---|
| STT | Số thứ tự dòng theo trang hiện tại. |
| Tên hồ sơ công việc | Tên HSCV in màu xanh navy đậm, bấm vào để mở Chi tiết HSCV. |
| Ngày mở | Ngày bắt đầu HSCV (DD/MM/YYYY). Trống hiển thị `—`. |
| Hạn giải quyết | Hạn hoàn thành. Quá hạn so với hôm nay và HSCV chưa Hoàn thành — chữ đỏ in đậm kèm biểu tượng cảnh báo. |
| Trạng thái | Nhãn màu theo trạng thái: Mới tạo, Đang xử lý, Chờ trình ký, Đã trình ký, Hoàn thành, Từ chối, Trả về, Đã hủy. |
| Phụ trách | Họ tên cán bộ được chọn làm người phụ trách. |
| Lãnh đạo ký | Họ tên lãnh đạo sẽ ký duyệt HSCV. |
| Tiến độ | Thanh phần trăm hoàn thành (0–100%) màu xanh teal. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải danh sách thất bại | Lỗi tải danh sách hồ sơ công việc |
| Bảng trống không có bộ lọc | Chưa có hồ sơ công việc |
| Bảng trống có bộ lọc | Không tìm thấy hồ sơ phù hợp. Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm. |
| Tải dữ liệu xuất Excel thất bại | Không tải được dữ liệu để xuất Excel |
| Xuất Excel khi danh sách trống | Không có hồ sơ nào phù hợp để xuất |
| Xuất Excel thành công | Đã xuất N hồ sơ |

### 3.2. Drawer Tạo hồ sơ công việc

![Drawer tạo hồ sơ](screenshots/hscv_danh_sach_02_create_drawer.png)

#### Bố cục màn hình

Drawer trượt từ phải, rộng 720px, tiêu đề "Tạo hồ sơ công việc". Phần thân chia 5 nhóm trường, sắp xếp theo thứ tự logic. Phần đáy có hai nút Hủy và Lưu hồ sơ ở góc trên bên phải.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Lưu hồ sơ | Góc trên drawer | Luôn hiển thị | Kiểm tra dữ liệu, gọi tạo HSCV. Thành công đóng drawer và tải lại danh sách. |
| Hủy | Góc trên drawer | Luôn hiển thị | Đóng drawer, bỏ qua dữ liệu đang nhập. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Tên hồ sơ công việc | Có | Tối đa 500 ký tự, có đếm số ký tự. |
| Loại văn bản | Không | Chọn từ cây loại văn bản. |
| Lĩnh vực | Không | Chọn từ danh sách lĩnh vực nghiệp vụ. |
| Ngày mở | Có | Chọn ngày bắt đầu HSCV. |
| Hạn giải quyết | Có | Phải sau hoặc bằng ngày mở. |
| Người phụ trách | Có | Danh sách cán bộ cùng đơn vị. |
| Lãnh đạo ký | Có | Danh sách người ký được đăng ký cho đơn vị. |
| Quy trình | Không | Chọn quy trình xử lý đã cấu hình. |
| Hồ sơ cha | Không | Chọn HSCV cha nếu là hồ sơ con. |
| Ghi chú | Không | Tối đa 2000 ký tự. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Trống tên HSCV | Vui lòng nhập tên hồ sơ công việc |
| Trống ngày mở | Vui lòng chọn ngày mở hồ sơ |
| Trống hạn giải quyết | Vui lòng chọn hạn giải quyết |
| Hạn giải quyết trước ngày mở | Hạn giải quyết phải sau hoặc bằng ngày mở hồ sơ |
| Trống người phụ trách | Vui lòng chọn người phụ trách |
| Trống lãnh đạo ký | Vui lòng chọn lãnh đạo ký |
| Đơn vị chưa có lãnh đạo trong dropdown | Đơn vị chưa có lãnh đạo |
| Tạo HSCV thành công | Tạo hồ sơ thành công |
| Tạo HSCV thất bại có thông tin SP | (Thông điệp do hệ thống trả về, ví dụ: Tên hồ sơ công việc không được để trống) |
| Tạo HSCV thất bại không xác định | Lưu hồ sơ thất bại. Vui lòng kiểm tra lại thông tin và thử lại. |

### 3.3. Drawer Chỉnh sửa hồ sơ công việc

![Drawer chỉnh sửa hồ sơ](screenshots/hscv_danh_sach_02_create_drawer.png)

#### Bố cục màn hình

Drawer giống Drawer Tạo hồ sơ công việc, tiêu đề chuyển thành "Chỉnh sửa hồ sơ công việc". Các trường được điền sẵn dữ liệu HSCV đang chọn. Chỉ mở được khi HSCV ở trạng thái Mới tạo.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Lưu hồ sơ | Góc trên drawer | Luôn hiển thị | Cập nhật HSCV. Thành công đóng drawer và tải lại danh sách. |
| Hủy | Góc trên drawer | Luôn hiển thị | Đóng drawer, bỏ qua thay đổi. |

#### Các trường dữ liệu

Giống Drawer Tạo hồ sơ công việc.

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Cập nhật thành công | Lưu hồ sơ thành công |
| Cập nhật thất bại | Lưu hồ sơ thất bại. Vui lòng kiểm tra lại thông tin và thử lại. |

### 3.4. Hộp thoại Xác nhận xóa HSCV

![Xóa hồ sơ](screenshots/hscv_chi_tiet_05_toolbar.png)

#### Bố cục màn hình

Modal nhỏ chính giữa, tiêu đề "Xóa hồ sơ", có biểu tượng cảnh báo. Nội dung yêu cầu xác nhận xóa. Hai nút Xóa (đỏ) và Hủy bỏ.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Xóa | Đáy modal | Luôn hiển thị | Xóa HSCV và làm mới danh sách. |
| Hủy bỏ | Đáy modal | Luôn hiển thị | Đóng hộp thoại, không thay đổi. |

#### Các trường dữ liệu

Không có trường nhập liệu.

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Yêu cầu xác nhận | Bạn có chắc muốn xóa hồ sơ này? Hành động này không thể hoàn tác. |
| Xóa thành công | Đã xóa hồ sơ |
| Xóa thất bại | Lỗi xóa hồ sơ |

### 3.5. Màn hình Chi tiết hồ sơ công việc

![Chi tiết hồ sơ — header](screenshots/hscv_chi_tiet_01_main.png)

#### Bố cục màn hình

Từ trên xuống:

- Breadcrumb: Trang chủ — Hồ sơ công việc — Tên HSCV.
- Khung tiêu đề: nút quay lại, nhãn trạng thái, tên HSCV, nhãn số văn bản (nếu đã lấy số), thanh nút thao tác bên phải.
- Khu nội dung: thẻ chứa 6 tab (Thông tin chung, Văn bản liên kết, Cán bộ xử lý, Ý kiến xử lý, File đính kèm, HSCV con).

Thanh nút thao tác thay đổi theo trạng thái HSCV:

| Trạng thái | Nút hiển thị |
|---|---|
| Mới tạo | Chuyển xử lý, Sửa, Chuyển tiếp HSCV, Lịch sử, Xóa |
| Đang xử lý | Trình ký, Cập nhật tiến độ, Lấy số (khi chưa có số), Chuyển tiếp HSCV, Lịch sử |
| Đã trình ký | Duyệt hồ sơ, Từ chối, Trả về, Lấy số (khi chưa có số), Chuyển tiếp HSCV, Lịch sử |
| Hoàn thành | Mở lại, Xem lịch sử |
| Bị từ chối, Trả về | Xử lý lại, Hủy HSCV |

#### Các tab nội dung

| Tab | Mô tả |
|---|---|
| Thông tin chung | Hiển thị 8 ô thông tin (Ngày mở, Hạn giải quyết, Lĩnh vực, Loại văn bản, Quy trình, Trạng thái, Người phụ trách, Lãnh đạo ký), thanh tiến độ, ghi chú. Khi HSCV đã hủy hiển thị thêm khung Thông tin hủy (lý do, thời điểm). |
| Văn bản liên kết | Bảng văn bản đến/đi/dự thảo đã được liên kết với HSCV. Có nút Thêm văn bản. |
| Cán bộ xử lý | Khung phân công 3 cột: cây đơn vị bên trái, danh sách cán bộ chọn được ở giữa, danh sách cán bộ đã phân công bên phải. |
| Ý kiến xử lý | Danh sách ý kiến theo dòng thời gian, có khu vực nhập ý kiến mới. Mỗi ý kiến có nút Chuyển tiếp. |
| File đính kèm | Khung kéo thả tệp + danh sách tệp. Mỗi tệp có nút Tải xuống, Ký số (nếu đủ điều kiện), Xóa. |
| HSCV con | Bảng HSCV con của HSCV hiện tại. Có nút Tạo HSCV con. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải HSCV thất bại | Không thể tải hồ sơ công việc. Kiểm tra kết nối mạng và thử lại. |
| Cập nhật trạng thái thành công | Cập nhật trạng thái thành công |
| Cập nhật trạng thái thất bại | Cập nhật trạng thái thất bại |

### 3.6. Tab Thông tin chung

![Tab thông tin chung](screenshots/hscv_chi_tiet_02_tab_thong_tin.png)

#### Bố cục màn hình

Lưới 8 ô: Ngày mở, Hạn giải quyết, Lĩnh vực, Loại văn bản, Quy trình, Trạng thái, Người phụ trách, Lãnh đạo ký. Thanh tiến độ, khu Ghi chú và (nếu là hồ sơ con) liên kết tới HSCV cha. Khi HSCV đã hủy có thêm khung Thông tin hủy nền đỏ nhạt.

#### Các nút chức năng

Không có nút riêng trong tab này — sử dụng các nút trên thanh tiêu đề HSCV.

#### Các trường dữ liệu

| Trường | Mô tả |
|---|---|
| Ngày mở | Ngày bắt đầu HSCV. |
| Hạn giải quyết | Quá hạn so với hôm nay sẽ in màu đỏ. |
| Lĩnh vực | Lĩnh vực nghiệp vụ. |
| Loại văn bản | Loại văn bản gắn HSCV. |
| Quy trình | Quy trình xử lý. |
| Trạng thái | Nhãn màu trạng thái hiện tại. |
| Người phụ trách | Họ tên cán bộ phụ trách. |
| Lãnh đạo ký | Họ tên lãnh đạo ký. |
| Tiến độ | Thanh phần trăm 0–100%. |
| Ghi chú | Phần văn bản ghi chú khi tạo/sửa HSCV. |
| HSCV cha | Liên kết về HSCV cha (chỉ hiện khi có). |
| Thông tin hủy | Lý do, thời điểm và người hủy (chỉ hiện khi đã hủy). |

#### Thông báo của hệ thống

Không có thông báo riêng tab này.

### 3.7. Tab Văn bản liên kết

![Tab văn bản liên kết](screenshots/hscv_chi_tiet_05_toolbar.png)

#### Bố cục màn hình

Đầu tab: nhãn "Văn bản liên kết" + Badge số lượng + nút Thêm văn bản. Bảng dưới có 5 cột: Số VB, Trích yếu, Loại, Ngày ký, Thao tác.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Thêm văn bản | Đầu tab | Luôn hiển thị | Mở Modal Thêm văn bản liên kết. |
| Gỡ liên kết | Cột Thao tác | Luôn hiển thị | Mở Popconfirm "Gỡ liên kết văn bản này?", xác nhận để gỡ. |

#### Các cột / trường dữ liệu

| Cột | Mô tả |
|---|---|
| Số VB | Số văn bản liên kết. |
| Trích yếu | Trích yếu văn bản. |
| Loại | Tên loại văn bản (Tag xanh). |
| Ngày ký | Ngày ký văn bản (DD/MM/YYYY). |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải danh sách thất bại | Lỗi tải văn bản liên kết |
| Bảng trống | Chưa có văn bản liên kết. Nhấn "Thêm văn bản" để liên kết văn bản đến/đi/dự thảo. |
| Gỡ liên kết thành công | Đã gỡ liên kết văn bản |
| Gỡ liên kết thất bại | Lỗi gỡ liên kết |

### 3.8. Modal Thêm văn bản liên kết

![Modal thêm văn bản](screenshots/hscv_chi_tiet_06_chuyen_tiep.png)

#### Bố cục màn hình

Modal rộng 800px. Đầu modal có 3 tab: Văn bản đến, Văn bản đi, Dự thảo. Mỗi tab có hàng tìm kiếm (ô nhập từ khóa + nút Tìm kiếm) và bảng kết quả có cột chọn (checkbox).

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Tìm kiếm | Hàng tìm kiếm | Luôn hiển thị | Tìm văn bản theo từ khóa trong tab đang chọn. |
| Liên kết | Đáy modal | Luôn hiển thị | Liên kết các văn bản đã chọn vào HSCV. |
| Hủy bỏ | Đáy modal | Luôn hiển thị | Đóng modal. |

#### Các cột / trường dữ liệu

| Cột | Mô tả |
|---|---|
| Số VB | Số văn bản gốc. |
| Trích yếu | Trích yếu văn bản. |
| Loại | Tên loại văn bản. |
| Ngày ký | Ngày ký (DD/MM/YYYY). |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tìm kiếm thất bại | Lỗi tìm kiếm văn bản |
| Bấm Liên kết khi chưa chọn dòng | Vui lòng chọn ít nhất một văn bản |
| Liên kết thành công | Liên kết văn bản thành công |
| Liên kết thất bại | Lỗi liên kết văn bản |

### 3.9. Tab Cán bộ xử lý

![Tab cán bộ xử lý](screenshots/hscv_chi_tiet_03_tab_can_bo.png)

#### Bố cục màn hình

Tab chia 3 cột:

- Trái: cây đơn vị "Chọn đơn vị" + danh sách cán bộ của đơn vị đã chọn (mỗi cán bộ có checkbox).
- Giữa: nút Thêm >> để chuyển cán bộ đã tích sang khung phải.
- Phải: danh sách cán bộ đã được phân công, mỗi dòng có Radio (Phụ trách / Phối hợp), DatePicker hạn xử lý, nút thùng rác xóa.

Đáy tab có nút Lưu phân công.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Thêm >> | Cột giữa | Luôn hiển thị | Chuyển cán bộ đã tích từ khung trái sang khung phải. |
| Thùng rác | Mỗi dòng cán bộ đã phân công | Luôn hiển thị | Bỏ cán bộ khỏi khung phân công. |
| Lưu phân công | Đáy tab | Luôn hiển thị | Lưu danh sách cán bộ và vai trò vào HSCV. |

#### Các trường dữ liệu

| Trường | Mô tả |
|---|---|
| Vai trò | Phụ trách (xanh lá) hoặc Phối hợp (xanh teal). |
| Hạn xử lý | Ngày hạn cán bộ phải xử lý phần việc của mình. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải danh sách cán bộ thất bại | Lỗi tải danh sách cán bộ |
| Tải nhân viên đơn vị thất bại | Lỗi tải danh sách nhân viên |
| Bấm Thêm khi chưa tích cán bộ | Vui lòng chọn cán bộ cần thêm |
| Cán bộ đã có sẵn trong khung phải | Các cán bộ đã được phân công rồi |
| Lưu khi khung phân công trống | Chưa có cán bộ nào được phân công |
| Lưu thành công | Phân công cán bộ thành công |
| Lưu thất bại | Lỗi phân công cán bộ |
| Vượt 50 cán bộ | Không được phân công quá 50 cán bộ cùng lúc |

### 3.10. Tab Ý kiến xử lý

![Tab ý kiến](screenshots/hscv_chi_tiet_02_tab_thong_tin.png)

#### Bố cục màn hình

Mỗi ý kiến hiển thị thành dòng có Avatar màu, họ tên, thời điểm và nội dung. Ý kiến chuyển tiếp được thụt lề trái và có nhãn "Chuyển tiếp cho ...". Mỗi ý kiến có nút Chuyển tiếp ở chân.

Phía dưới có khung soạn ý kiến mới (TextArea tối đa 2000 ký tự + nút Gửi ý kiến).

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Chuyển tiếp | Mỗi ý kiến | Luôn hiển thị | Mở Modal Chuyển tiếp ý kiến. |
| Gửi ý kiến | Khung soạn | Luôn hiển thị | Gửi ý kiến mới vào HSCV. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Nội dung ý kiến | Có | Tối đa 2000 ký tự, hiển thị bộ đếm. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải danh sách ý kiến thất bại | Lỗi tải ý kiến xử lý |
| Bảng trống | Chưa có ý kiến xử lý. Hãy là người đầu tiên thêm ý kiến. |
| Trống nội dung khi gửi | Vui lòng nhập ý kiến |
| Gửi thành công | Gửi ý kiến thành công |
| Gửi thất bại | Gửi ý kiến thất bại |

### 3.11. Modal Chuyển tiếp ý kiến

![Modal chuyển tiếp ý kiến](screenshots/hscv_chi_tiet_06_chuyen_tiep.png)

#### Bố cục màn hình

Modal rộng 500px, tiêu đề "Chuyển tiếp ý kiến". Form có 2 trường: Người nhận (Select) và Nội dung chuyển tiếp (TextArea).

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Gửi | Đáy modal | Luôn hiển thị | Gửi ý kiến chuyển tiếp đến người nhận. |
| Hủy | Đáy modal | Luôn hiển thị | Đóng modal. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Người nhận | Có | Cán bộ cùng đơn vị, có ô tìm kiếm. |
| Nội dung chuyển tiếp | Có | Tối đa 1000 ký tự. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Trống người nhận | Vui lòng chọn người nhận |
| Trống nội dung | Vui lòng nhập nội dung chuyển tiếp |
| Gửi thành công | Đã chuyển tiếp ý kiến |
| Gửi thất bại | Chuyển tiếp thất bại |

### 3.12. Tab File đính kèm

![Tab file đính kèm](screenshots/hscv_chi_tiet_04_tab_file.png)

#### Bố cục màn hình

Đầu tab: khung kéo thả "Kéo thả file vào đây hoặc nhấn để chọn file" với gợi ý định dạng. Bên dưới là danh sách tệp đã đính kèm. Mỗi dòng tệp có biểu tượng theo định dạng, tên tệp, dung lượng, thời gian, người tải lên và cụm nút thao tác.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Tải xuống | Mỗi dòng tệp | Luôn hiển thị | Mở tệp trong tab mới. |
| Ký số | Mỗi dòng tệp | Tệp PDF + cán bộ là lãnh đạo ký + HSCV ở Chờ trình ký hoặc Đã trình ký + tệp chưa ký | Mở Modal Ký số (xem 3.x trong module Danh sách ký số). |
| Xóa | Mỗi dòng tệp | Luôn hiển thị | Mở Popconfirm xác nhận xóa tệp. |

#### Các trường dữ liệu

Hiển thị tên tệp, dung lượng (B/KB/MB), thời gian (DD/MM/YYYY HH:mm), tên người tải lên. Tệp đã ký số có nhãn "Đã ký số".

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải danh sách thất bại | Lỗi tải file đính kèm |
| Bảng trống | Chưa có file đính kèm |
| Tải lên thành công | Tải lên file thành công |
| Tải lên thất bại | Tải lên file thất bại |
| Tải xuống thất bại | Không thể tải xuống file "<tên tệp>" |
| Loại tệp không hỗ trợ (BE) | Loại file không được hỗ trợ |
| Tệp trống khi gửi | Vui lòng chọn file |
| Xóa thành công | Đã xóa file |
| Xóa thất bại | Xóa file thất bại |

### 3.13. Tab HSCV con

![Tab HSCV con](screenshots/hscv_chi_tiet_05_toolbar.png)

#### Bố cục màn hình

Đầu tab có nút Tạo HSCV con. Bên dưới là bảng 5 cột: Tên hồ sơ, Ngày mở, Hạn giải quyết, Trạng thái, Tiến độ. Bấm tên hồ sơ để mở Chi tiết HSCV con.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Tạo HSCV con | Đầu tab | Luôn hiển thị | Mở Drawer Tạo hồ sơ con. |

#### Các cột / trường dữ liệu

| Cột | Mô tả |
|---|---|
| Tên hồ sơ | Tên HSCV con — bấm vào để mở Chi tiết. |
| Ngày mở | Ngày bắt đầu HSCV con. |
| Hạn giải quyết | Quá hạn — chữ đỏ kèm biểu tượng cảnh báo. |
| Trạng thái | Nhãn màu theo trạng thái. |
| Tiến độ | Thanh phần trăm. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải danh sách thất bại | Lỗi tải hồ sơ con |
| Bảng trống | Chưa có hồ sơ con. Nhấn "Tạo HSCV con" để thêm hồ sơ con. |

### 3.14. Drawer Tạo HSCV con

![Drawer tạo HSCV con](screenshots/hscv_danh_sach_02_create_drawer.png)

#### Bố cục màn hình

Drawer trượt từ phải, rộng 720px, tiêu đề "Tạo hồ sơ con". Trường Hồ sơ cha hiển thị tên HSCV hiện tại (chỉ đọc). Các trường còn lại tương tự Drawer Tạo hồ sơ công việc nhưng giảm bớt: Tên hồ sơ con, Ngày mở, Hạn giải quyết, Người phụ trách, Lãnh đạo ký, Ghi chú.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Lưu | Góc trên drawer | Luôn hiển thị | Tạo HSCV con thuộc HSCV hiện tại. |
| Hủy | Góc trên drawer | Luôn hiển thị | Đóng drawer, bỏ qua. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Hồ sơ cha | (chỉ đọc) | Tên HSCV hiện tại. |
| Tên hồ sơ con | Có | Tối đa 500 ký tự. |
| Ngày mở | Có | Ngày bắt đầu. |
| Hạn giải quyết | Có | Phải sau hoặc bằng ngày mở. |
| Người phụ trách | Không | Cán bộ cùng đơn vị. |
| Lãnh đạo ký | Không | Người ký được đăng ký cho đơn vị. |
| Ghi chú | Không | Tối đa 2000 ký tự. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Trống tên | Vui lòng nhập tên hồ sơ con |
| Trống ngày mở | Vui lòng chọn ngày mở |
| Trống hạn | Vui lòng chọn hạn |
| Đơn vị chưa có lãnh đạo | Đơn vị chưa có lãnh đạo |
| Tạo thành công | Tạo hồ sơ con thành công |
| Tạo thất bại | Tạo hồ sơ thất bại |

### 3.15. Modal Cập nhật tiến độ

![Modal tiến độ](screenshots/hscv_chi_tiet_05_toolbar.png)

#### Bố cục màn hình

Modal nhỏ, tiêu đề "Cập nhật tiến độ". Bên trong có nhãn "Tiến độ hoàn thành (%)", thanh trượt 0–100, ô nhập số có hậu tố `%`.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Cập nhật | Đáy modal | Luôn hiển thị | Lưu tiến độ và làm mới HSCV. |
| Hủy bỏ | Đáy modal | Luôn hiển thị | Đóng modal. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Tiến độ hoàn thành (%) | Có | Số nguyên 0–100, đồng bộ giữa thanh trượt và ô nhập. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Cập nhật thành công | Cập nhật tiến độ thành công |
| Cập nhật thất bại | Cập nhật tiến độ thất bại |
| Vượt giới hạn (BE) | Tiến độ phải trong khoảng 0-100 |

### 3.16. Modal Lấy số văn bản

![Modal lấy số](screenshots/hscv_chi_tiet_05_toolbar.png)

#### Bố cục màn hình

Modal nhỏ, tiêu đề "Chọn sổ văn bản để lấy số". Form có 1 trường Sổ văn bản (Select có ô tìm kiếm). Phía dưới hiển thị ghi chú: "Số văn bản được tính theo công thức MAX(số) + 1 trong cùng sổ và năm tạo HSCV.". Khi HSCV đã chọn sẵn sổ, hệ thống hiển thị Modal xác nhận đơn giản với nội dung "Sẽ cấp số kế tiếp theo sổ ... Bạn xác nhận?".

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Lấy số | Đáy modal | Luôn hiển thị | Cấp số kế tiếp theo sổ đã chọn. |
| Hủy | Đáy modal | Luôn hiển thị | Đóng modal. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Sổ văn bản | Có | Danh sách sổ — hiển thị `<mã> - <tên>`. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải sổ thất bại | Không tải được danh sách sổ văn bản |
| Trống sổ khi xác nhận | Vui lòng chọn sổ văn bản |
| Cấp số thành công | Đã lấy số <số> |
| HSCV đã có số | HSCV đã có số <số> |
| Lỗi nghiệp vụ khác | Thao tác thất bại |

### 3.17. Modal Trình ký / Duyệt hồ sơ / Xử lý lại / Chuyển xử lý

#### Bố cục màn hình

Đây là các nút thao tác đơn giản (không mở thêm cửa sổ). Khi bấm — hệ thống gọi đổi trạng thái HSCV ngay và làm mới chi tiết.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Chuyển xử lý | Thanh nút | Trạng thái Mới tạo | Chuyển HSCV sang trạng thái Đang xử lý. |
| Trình ký | Thanh nút | Trạng thái Đang xử lý | Chuyển HSCV sang trạng thái Đã trình ký. |
| Duyệt hồ sơ | Thanh nút | Trạng thái Đã trình ký | Phê duyệt HSCV — chuyển sang Hoàn thành, tiến độ = 100%. |
| Xử lý lại | Thanh nút | Trạng thái Bị từ chối / Trả về | Chuyển HSCV về Đang xử lý. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Thành công | Cập nhật trạng thái thành công |
| Thất bại | Cập nhật trạng thái thất bại |

### 3.18. Modal Từ chối hồ sơ

![Modal từ chối](screenshots/hscv_chi_tiet_05_toolbar.png)

#### Bố cục màn hình

Modal nhỏ, tiêu đề "Từ chối hồ sơ". Trên là dòng hướng dẫn "Nhập lý do từ chối để thông báo cho người xử lý.", dưới là TextArea (tối đa 500 ký tự, có đếm). Đáy có 2 nút Từ chối (đỏ, vô hiệu khi trống lý do) và Hủy.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Từ chối | Đáy modal | Luôn hiển thị; vô hiệu khi trống lý do | Chuyển HSCV sang Bị từ chối kèm lý do. |
| Hủy | Đáy modal | Luôn hiển thị | Đóng modal. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Lý do từ chối | Có | Tối đa 500 ký tự. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Trống lý do (BE) | Lý do là bắt buộc khi từ chối hoặc trả về |
| Từ chối thành công | Cập nhật trạng thái thành công |

### 3.19. Modal Trả về hồ sơ

![Modal trả về](screenshots/hscv_chi_tiet_05_toolbar.png)

#### Bố cục màn hình

Giống Modal Từ chối nhưng tiêu đề "Trả về hồ sơ", dòng hướng dẫn "Nhập lý do trả về để người xử lý biết cần chỉnh sửa gì.". Nút chính là Trả về (vô hiệu khi trống lý do).

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Trả về | Đáy modal | Luôn hiển thị; vô hiệu khi trống lý do | Chuyển HSCV sang Trả về kèm lý do. |
| Hủy | Đáy modal | Luôn hiển thị | Đóng modal. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Lý do trả về | Có | Tối đa 500 ký tự. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Trả về thành công | Cập nhật trạng thái thành công |

### 3.20. Modal Hủy HSCV

![Modal hủy](screenshots/hscv_chi_tiet_06_chuyen_tiep.png)

#### Bố cục màn hình

Modal rộng 480px, tiêu đề "Hủy hồ sơ công việc". Form có 1 trường Lý do hủy HSCV (TextArea, 1000 ký tự). Đáy có nút Xác nhận hủy (đỏ) và Hủy thao tác.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Xác nhận hủy | Đáy modal | Luôn hiển thị | Đặt HSCV về trạng thái Đã hủy kèm lý do. |
| Hủy thao tác | Đáy modal | Luôn hiển thị | Đóng modal. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Lý do hủy HSCV | Có | Tối đa 1000 ký tự. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Trống lý do | Vui lòng nhập lý do hủy |
| Hủy thành công | Đã hủy hồ sơ công việc |
| Trạng thái không cho hủy | Chỉ được hủy HSCV ở trạng thái Từ chối (-1) hoặc Trả về (-2). Trạng thái hiện tại: <mã> |

### 3.21. Hộp thoại Mở lại HSCV

![Mở lại HSCV](screenshots/hscv_chi_tiet_05_toolbar.png)

#### Bố cục màn hình

Modal nhỏ "Mở lại hồ sơ công việc?" với mô tả: "Trạng thái sẽ chuyển từ 'Hoàn thành' về 'Đang xử lý' (giữ nguyên tiến độ 100%). Bạn xác nhận?". Nút Mở lại và Hủy.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Mở lại | Đáy modal | Luôn hiển thị | Đưa HSCV về Đang xử lý, giữ tiến độ. |
| Hủy | Đáy modal | Luôn hiển thị | Đóng modal. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Mở lại thành công | Đã mở lại hồ sơ công việc |
| Trạng thái không cho mở lại | Chỉ có thể mở lại HSCV đã hoàn thành. Trạng thái hiện tại: <mã> |
| Lỗi khác | Thao tác thất bại |

### 3.22. Modal Chuyển tiếp HSCV

![Modal chuyển tiếp HSCV](screenshots/hscv_chi_tiet_06_chuyen_tiep.png)

#### Bố cục màn hình

Modal rộng 500px, tiêu đề "Chuyển tiếp hồ sơ công việc". Đầu modal có dòng nhắc "Chỉ có thể chuyển HSCV cho người cùng đơn vị". Form gồm Người nhận (Select có ô tìm kiếm) và Ghi chú (TextArea).

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Chuyển tiếp | Đáy modal | Luôn hiển thị | Chuyển HSCV cho người nhận. |
| Hủy | Đáy modal | Luôn hiển thị | Đóng modal. |

#### Các trường dữ liệu

| Trường | Bắt buộc | Mô tả |
|---|---|---|
| Người nhận | Có | Cán bộ cùng đơn vị (loại trừ chính mình). |
| Ghi chú | Không | Tối đa 500 ký tự. |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Trống người nhận | Vui lòng chọn người nhận |
| Chuyển tiếp thành công | Đã chuyển tiếp hồ sơ công việc |
| Người nhận khác đơn vị | Chỉ có thể chuyển HSCV cho người cùng đơn vị |
| Người nhận không tồn tại | Không tìm thấy người nhận |
| Người nhận đã khóa | Người nhận đã khóa tài khoản |
| Người nhận đã xóa | Người nhận đã bị xoá |
| Chuyển cho chính mình | Không thể chuyển cho chính mình |

### 3.23. Modal Lịch sử HSCV

![Modal lịch sử HSCV](screenshots/hscv_chi_tiet_06_chuyen_tiep.png)

#### Bố cục màn hình

Modal rộng 720px, tiêu đề "Lịch sử hồ sơ công việc". Bên trong là danh sách thẻ, mỗi thẻ mô tả một sự kiện trong vòng đời HSCV: Tạo HSCV, Trình ký, Duyệt hồ sơ, Từ chối, Trả về bổ sung, Hoàn thành, Lấy số văn bản, Chuyển tiếp, Hủy HSCV, Mở lại, Đổi trạng thái → <tên>. Mỗi thẻ có ghi chú (nếu có) và thời điểm + người thao tác. Đáy modal có nút Đóng.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Đóng | Đáy modal | Luôn hiển thị | Đóng modal. |

#### Các trường dữ liệu

Hiển thị: loại hành động, ghi chú (nếu có), thời điểm (DD/MM/YYYY HH:mm), tên người thao tác.

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Bảng trống | Chưa có lịch sử |
