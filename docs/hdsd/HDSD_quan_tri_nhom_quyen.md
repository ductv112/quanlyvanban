# Quản trị nhóm quyền

## Giới thiệu

Module Quản trị nhóm quyền giúp quản trị viên tạo các nhóm quyền (vai trò) và gán cho nhóm đó các chức năng (menu, nút bấm, hành động) cụ thể trong hệ thống. Sau khi nhóm quyền có quyền hợp lý, quản trị viên gán nhóm quyền cho người dùng tại màn hình Quản trị → Người dùng → Phân quyền.

Truy cập: menu **Quản trị → Nhóm quyền**.

Đối tượng sử dụng: quản trị viên hệ thống.

## Quy trình thao tác và ràng buộc nghiệp vụ

Quy trình chuẩn:

1. Tạo các nhóm quyền theo vai trò công việc, ví dụ: Quản trị hệ thống, Văn thư đơn vị, Lãnh đạo phòng, Chuyên viên, Trợ lý.
2. Với mỗi nhóm quyền, mở **Phân quyền** và tích chọn các chức năng được phép sử dụng — các chức năng được tổ chức dạng cây (menu cha → menu con → hành động).
3. Sang màn hình Quản trị → Người dùng, gán nhóm quyền cho từng người dùng.
4. Một người dùng có thể được gán nhiều nhóm quyền — quyền cuối cùng là tổng hợp (union) của các nhóm.

Ràng buộc nghiệp vụ:

- **Tên nhóm quyền** là trường bắt buộc và phải duy nhất trong hệ thống.
- Không thể xóa nhóm quyền nếu còn nhân viên đang được gán nhóm quyền đó — phải gỡ phân quyền của các nhân viên đó trước.
- Khi tích chọn 1 mục cha trong cây phân quyền, mặc định các mục con cũng được chọn (theo cơ chế của Tree component).
- Nhóm quyền là cấp gán quyền duy nhất — quyền không gán trực tiếp cho người dùng.

## Các màn hình chức năng

### Màn hình danh sách nhóm quyền

![Danh sách nhóm quyền](screenshots/quan_tri_nhom_quyen_01_danh_sach.png)

#### Bố cục màn hình

Toàn màn hình là một bảng danh sách trong card chính. Trên cùng là tiêu đề trang **Quản lý nhóm quyền** kèm dòng mô tả ngắn.

Header card gồm tiêu đề **Danh sách nhóm quyền** ở bên trái và hai thành phần ở bên phải: ô tìm kiếm và nút Thêm nhóm quyền.

Cuối bảng có thanh phân trang với tổng số bản ghi và bộ chọn số dòng/trang.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Tìm kiếm | Header card, bên trái nút Thêm | Luôn hiển thị | Lọc danh sách theo từ khóa, gõ Enter để tìm |
| Thêm nhóm quyền | Header card, góc phải | Luôn hiển thị | Mở Drawer nhập thông tin nhóm quyền mới |
| Sửa thông tin | Trong menu ba chấm cuối mỗi dòng | Mọi dòng | Mở Drawer chỉnh sửa nhóm quyền |
| Phân quyền | Trong menu ba chấm cuối mỗi dòng | Mọi dòng | Mở Drawer chọn các chức năng cho nhóm quyền |
| Xóa | Trong menu ba chấm cuối mỗi dòng | Mọi dòng | Mở hộp xác nhận xóa |

#### Các cột / trường dữ liệu

| Cột | Ý nghĩa |
|---|---|
| Tên nhóm | Tên nhóm quyền, in đậm màu xanh navy |
| Mô tả | Dòng giải thích vai trò của nhóm |
| Số người dùng | Số nhân viên được gán nhóm quyền (thẻ xanh) |
| Ngày tạo | Ngày tạo nhóm quyền (định dạng dd/MM/yyyy) |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải bảng không thành công | Lỗi tải dữ liệu |
| Xóa thành công | Xóa thành công |
| Xóa khi còn người dùng | Không thể xóa: còn N nhân viên trong nhóm quyền này |

### Màn hình Thêm nhóm quyền mới

![Drawer thêm nhóm quyền](screenshots/quan_tri_nhom_quyen_02_drawer_them.png)

Mở khi nhấn nút **Thêm nhóm quyền**. Drawer trượt từ phải vào, tiêu đề **Thêm nhóm quyền mới**, nền gradient xanh navy.

#### Bố cục màn hình

Drawer rộng 720px, gồm 2 trường xếp dọc:

1. Tên nhóm quyền (Input).
2. Mô tả (TextArea 4 dòng).

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Hủy | Header drawer (góc phải trên) | Luôn hiển thị | Đóng drawer, không lưu thay đổi |
| Thêm mới | Header drawer (góc phải trên) | Luôn hiển thị | Lưu nhóm quyền mới, đóng drawer khi thành công |

#### Các cột / trường dữ liệu

| Trường | Bắt buộc | Ý nghĩa |
|---|---|---|
| Tên nhóm quyền | Có | Tối đa 100 ký tự, ví dụ "Quản trị hệ thống". Phải duy nhất |
| Mô tả | Không | Ghi chú vai trò của nhóm quyền, tối đa 500 ký tự |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Bỏ trống Tên nhóm quyền | Nhập tên nhóm quyền |
| Tên rỗng (server) | Tên nhóm quyền là bắt buộc (inline ở trường Tên) |
| Tên đã tồn tại | Tên nhóm quyền đã tồn tại (inline ở trường Tên) |
| Lưu thành công | Thêm thành công |

### Màn hình Cập nhật nhóm quyền

![Drawer cập nhật nhóm quyền](screenshots/quan_tri_nhom_quyen_03_drawer_sua.png)

Mở khi chọn **Sửa thông tin** trong menu ba chấm. Drawer giống Drawer Thêm về bố cục và các trường, chỉ khác hai điểm:

- Tiêu đề là **Cập nhật nhóm quyền**.
- Nút lưu là **Cập nhật**.

Toàn bộ trường được tải sẵn dữ liệu hiện tại. Người dùng sửa các trường cần thay đổi và bấm **Cập nhật** để lưu.

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Cập nhật thành công | Cập nhật thành công |
| Tên đã tồn tại ở nhóm khác | Tên nhóm quyền đã tồn tại |

Các thông báo còn lại giống Drawer Thêm.

### Màn hình Phân quyền cho nhóm

![Drawer phân quyền nhóm](screenshots/quan_tri_nhom_quyen_04_drawer_phan_quyen.png)

Mở khi chọn **Phân quyền** trong menu ba chấm. Tiêu đề **Phân quyền: <Tên nhóm quyền>**.

#### Bố cục màn hình

Drawer rộng 720px, gồm:

- Cây các chức năng của hệ thống dưới dạng tree có checkbox.
- Cây tổ chức theo phân cấp menu cha → menu con → hành động (ví dụ: Văn bản đến → Danh sách → Tiếp nhận).
- Mặc định mở rộng tất cả các nút.
- Khi tích chọn nút cha, các nút con tự động được chọn theo.

Khi mở Drawer, hệ thống tải song song hai dữ liệu: cây chức năng và danh sách quyền hiện tại của nhóm — các quyền đã có sẽ được tích sẵn.

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Lưu phân quyền | Header drawer (góc phải trên) | Luôn hiển thị | Lưu danh sách quyền đã chọn cho nhóm |

Trong lúc đang tải dữ liệu, drawer hiển thị biểu tượng quay vòng (loading) ở giữa nội dung.

#### Các cột / trường dữ liệu

| Trường | Ý nghĩa |
|---|---|
| Tên chức năng | Tên menu / hành động trong cây — lấy từ trường tên menu của chức năng |
| Checkbox | Tích để gán quyền, bỏ tích để gỡ quyền |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Tải cây quyền không thành công | Lỗi tải quyền |
| Lưu thành công | Lưu phân quyền thành công |
| Lưu không thành công | Lỗi lưu phân quyền |

### Hộp xác nhận xóa nhóm quyền

![Modal xác nhận xóa](screenshots/quan_tri_nhom_quyen_05_modal_xoa.png)

Hiển thị khi chọn **Xóa** trong menu ba chấm.

#### Bố cục màn hình

Modal nhỏ nằm giữa màn hình:

- Tiêu đề: **Xác nhận xóa**.
- Nội dung: dòng văn bản hỏi xác nhận.
- Hai nút ở chân: **Hủy** và **Xóa** (nút Xóa màu đỏ).

#### Các nút chức năng

| Nút | Vị trí | Khi nào hiển thị | Tác dụng |
|---|---|---|---|
| Hủy | Chân modal, bên trái | Luôn hiển thị | Đóng modal, không xóa |
| Xóa | Chân modal, bên phải | Luôn hiển thị | Gọi API xóa nhóm quyền |

#### Thông báo của hệ thống

| Tình huống | Thông báo |
|---|---|
| Nội dung modal | Bạn có chắc chắn muốn xóa nhóm quyền này? |
| Xóa thành công | Xóa thành công |
| Còn người dùng đang dùng | Không thể xóa: còn N nhân viên trong nhóm quyền này |
