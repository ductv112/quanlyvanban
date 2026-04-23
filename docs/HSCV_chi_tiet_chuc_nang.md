# Hướng dẫn sử dụng: Màn hình Chi tiết Hồ sơ công việc

Tài liệu này mô tả đầy đủ các chức năng có trong màn hình **Chi tiết Hồ sơ công việc (HSCV)** của hệ thống Quản lý văn bản điện tử, giúp người dùng hiểu rõ cách sử dụng và quy trình nghiệp vụ.

---

## 1. Giới thiệu

**Hồ sơ công việc (HSCV)** là một "tập hồ sơ điện tử" dùng để quản lý toàn bộ công việc liên quan đến một vụ việc cụ thể. Một HSCV có thể gắn nhiều văn bản liên quan, phân công cho nhiều cán bộ cùng phối hợp xử lý, đính kèm tài liệu, trao đổi ý kiến và có cả HSCV con (trường hợp công việc lớn cần chia nhỏ).

Màn hình chi tiết HSCV là nơi người dùng theo dõi và thực hiện mọi thao tác trong vòng đời của một hồ sơ — từ khi mới tạo cho đến khi hoàn thành hoặc bị hủy.

---

## 2. Bố cục màn hình

Màn hình chi tiết HSCV gồm 3 phần chính:

- **Phần đầu trang**: Hiển thị tên HSCV, trạng thái hiện tại, số văn bản đã lấy (nếu có), và thanh công cụ chứa các nút hành động.
- **Phần giữa — các Tab**: 6 tab chứa đầy đủ thông tin và thao tác của hồ sơ.
- **Các cửa sổ phụ (Modal/Drawer)**: Mở ra khi người dùng bấm các nút tương ứng để nhập thông tin thao tác.

---

## 3. Trạng thái của Hồ sơ công việc

Mỗi HSCV tại một thời điểm sẽ ở một trong các trạng thái sau:

| Trạng thái | Ý nghĩa |
|---|---|
| **Mới tạo** | HSCV vừa được lập, chưa bắt đầu xử lý |
| **Đang xử lý** | Cán bộ phụ trách đã bắt đầu làm việc với hồ sơ |
| **Chờ trình ký** | Hồ sơ đã xong giai đoạn xử lý, chờ gửi lên lãnh đạo |
| **Đã trình ký** | Hồ sơ đã được gửi lên lãnh đạo để xem xét |
| **Hoàn thành** | Lãnh đạo đã duyệt, hồ sơ kết thúc |
| **Tạm dừng** | Tạm thời ngừng xử lý (do nguyên nhân khách quan) |
| **Từ chối** | Lãnh đạo không đồng ý duyệt |
| **Trả về** | Lãnh đạo trả lại để bổ sung, chỉnh sửa |
| **Đã hủy** | HSCV không còn giá trị, đã bị hủy bỏ |

Thanh công cụ (các nút hành động) sẽ **hiển thị khác nhau tùy theo trạng thái** — chỉ các nút phù hợp với trạng thái hiện tại mới được hiện ra, giúp người dùng không thao tác sai quy trình.

---

## 4. Các Tab trong chi tiết HSCV

### 4.1. Tab "Thông tin chung"

Hiển thị toàn bộ thông tin cơ bản của hồ sơ công việc:

- **Ngày mở**: Thời điểm hồ sơ bắt đầu
- **Hạn giải quyết**: Thời hạn phải hoàn thành (chữ đỏ nếu đã quá hạn)
- **Lĩnh vực**: Lĩnh vực nghiệp vụ của hồ sơ
- **Loại văn bản**: Loại hồ sơ/văn bản chính
- **Quy trình**: Quy trình xử lý áp dụng
- **Trạng thái hiện tại**
- **Người phụ trách**: Cán bộ chính chịu trách nhiệm
- **Lãnh đạo ký**: Lãnh đạo sẽ xem xét phê duyệt
- **Tiến độ**: Thanh hiển thị phần trăm hoàn thành (0–100%)
- **Ghi chú**: Nội dung ghi chú thêm (nếu có)
- **Thông tin hủy** (chỉ hiện khi hồ sơ đã hủy): lý do, thời điểm, người hủy
- **Liên kết đến HSCV cha** (nếu hồ sơ này là hồ sơ con)

### 4.2. Tab "Văn bản liên kết"

Quản lý tất cả văn bản liên quan đến HSCV (văn bản đến, văn bản đi, dự thảo).

**Thao tác**:
- **Thêm văn bản**: Mở cửa sổ tìm kiếm và chọn văn bản từ danh sách (Văn bản đến / Văn bản đi / Dự thảo), hỗ trợ tìm kiếm theo số văn bản hoặc trích yếu, chọn nhiều văn bản cùng lúc.
- **Gỡ liên kết**: Mỗi văn bản đều có nút gỡ bỏ, có xác nhận trước khi thực hiện.

**Thông tin hiển thị mỗi văn bản**: Số văn bản, trích yếu, loại văn bản, ngày ký.

Tab này có hiển thị số lượng văn bản đã liên kết.

### 4.3. Tab "Cán bộ xử lý"

Quản lý danh sách cán bộ tham gia xử lý HSCV.

**Giao diện 3 cột**:
1. **Cột trái**: Cây đơn vị — chọn đơn vị để xem danh sách nhân viên, tích chọn nhiều nhân viên cùng lúc
2. **Cột giữa**: Nút "Thêm" để chuyển nhân viên đã chọn sang danh sách phân công
3. **Cột phải**: Danh sách cán bộ đã được phân công, mỗi người có:
   - **Vai trò**: Phụ trách hoặc Phối hợp
   - **Hạn xử lý**: Ngày phải hoàn thành
   - **Xóa**: Bỏ cán bộ khỏi danh sách

Sau khi điều chỉnh xong, bấm **"Lưu phân công"** để ghi nhận thay đổi.

Tab này có hiển thị số lượng cán bộ được phân công.

### 4.4. Tab "Ý kiến xử lý"

Nơi các cán bộ tham gia HSCV trao đổi, ghi ý kiến trong quá trình xử lý.

**Thao tác**:
- **Gửi ý kiến mới**: Nhập nội dung vào ô ở cuối tab và bấm "Gửi ý kiến"
- **Chuyển tiếp ý kiến**: Mỗi ý kiến có nút "Chuyển tiếp" để gửi nội dung này đến một cán bộ khác, kèm ghi chú bổ sung. Các ý kiến chuyển tiếp sẽ được hiển thị thụt vào và có biểu tượng chuyển tiếp để dễ nhận biết.

**Thông tin mỗi ý kiến**: Ảnh đại diện, tên người gửi, thời gian, nội dung.

### 4.5. Tab "File đính kèm"

Quản lý các tài liệu, file đính kèm của HSCV.

**Thao tác**:
- **Tải lên file**: Kéo thả file vào khu vực upload hoặc bấm chọn file. Hỗ trợ các định dạng: PDF, Word (doc, docx), Excel (xls, xlsx), ảnh (png, jpg, jpeg). Dung lượng tối đa 50 MB mỗi file.
- **Tải xuống**: Bấm nút tải xuống ở mỗi file
- **Ký số**: Chỉ hiển thị khi đủ các điều kiện sau:
  - Người đang đăng nhập là lãnh đạo ký của HSCV
  - HSCV đang ở trạng thái "Chờ trình ký" hoặc "Đã trình ký"
  - File là định dạng PDF
  - File chưa được ký số trước đó
- **Xóa file**: Có xác nhận trước khi xóa

**Thông tin mỗi file**: Tên file, kích cỡ, thời gian tải lên, người tải lên. File đã ký số sẽ có nhãn "Đã ký số" màu xanh.

### 4.6. Tab "HSCV con"

Quản lý các hồ sơ công việc con — dùng khi công việc lớn cần chia nhỏ.

**Thao tác**:
- **Tạo HSCV con**: Mở cửa sổ nhập thông tin hồ sơ con (tên, ngày mở, hạn giải quyết, người phụ trách, lãnh đạo ký, ghi chú)
- **Xem chi tiết**: Bấm vào tên HSCV con để mở màn hình chi tiết của nó

**Thông tin mỗi HSCV con**: Tên, ngày mở, hạn giải quyết (chữ đỏ + cảnh báo nếu quá hạn), trạng thái, tiến độ.

---

## 5. Các nút hành động theo từng trạng thái

Dưới đây là các nút hành động sẽ hiển thị trên thanh công cụ — **tùy thuộc vào trạng thái hiện tại** của HSCV.

### 5.1. Khi HSCV ở trạng thái **"Mới tạo"**

| Nút | Chức năng |
|---|---|
| **Chuyển xử lý** | Bắt đầu xử lý hồ sơ. Trạng thái chuyển từ "Mới tạo" → "Đang xử lý" |
| **Sửa** | Mở cửa sổ chỉnh sửa thông tin HSCV (tên, hạn, người phụ trách, lãnh đạo ký...) |
| **Chuyển tiếp HSCV** | Bàn giao cả hồ sơ cho cán bộ khác (xem mục 6.2) |
| **Lịch sử** | Xem toàn bộ lịch sử thao tác trên HSCV |
| **Xóa** | Xóa hẳn HSCV (chỉ cho phép khi mới tạo) |

### 5.2. Khi HSCV ở trạng thái **"Đang xử lý"**

| Nút | Chức năng |
|---|---|
| **Trình ký** | Chuyển hồ sơ sang trạng thái "Chờ trình ký" để gửi lãnh đạo |
| **Cập nhật tiến độ** | Mở cửa sổ điều chỉnh phần trăm hoàn thành (0–100%) |
| **Lấy số** | Lấy số văn bản theo sổ (chỉ hiện nếu chưa lấy số) |
| **Chuyển tiếp HSCV** | Bàn giao cho cán bộ khác |
| **Lịch sử** | Xem lịch sử thao tác |
| **Tạm dừng** | Tạm ngưng xử lý (do nguyên nhân khách quan) |

### 5.3. Khi HSCV ở trạng thái **"Chờ trình ký"**

| Nút | Chức năng |
|---|---|
| **Gửi trình ký** | Đẩy lên trạng thái "Đã trình ký" để lãnh đạo xem xét |
| **Trả về** | Trả về để cán bộ xử lý lại, kèm lý do |
| **Chuyển tiếp HSCV** | Bàn giao cho cán bộ khác |
| **Lịch sử** | Xem lịch sử thao tác |

### 5.4. Khi HSCV ở trạng thái **"Đã trình ký"**

| Nút | Chức năng |
|---|---|
| **Duyệt hồ sơ** | Lãnh đạo đồng ý — chuyển sang "Hoàn thành" |
| **Từ chối** | Lãnh đạo không đồng ý — kèm lý do từ chối |
| **Trả về** | Trả lại để bổ sung — kèm lý do trả về |
| **Lấy số** | Lấy số văn bản (nếu chưa lấy số) |
| **Chuyển tiếp HSCV** | Bàn giao cho cán bộ khác |
| **Lịch sử** | Xem lịch sử thao tác |

### 5.5. Khi HSCV ở trạng thái **"Hoàn thành"**

| Nút | Chức năng |
|---|---|
| **Mở lại** | Trường hợp cần chỉnh sửa sau khi đã hoàn thành — chuyển về "Đang xử lý", giữ nguyên tiến độ 100% |
| **Xem lịch sử** | Xem lại toàn bộ quá trình xử lý |

### 5.6. Khi HSCV ở trạng thái **"Tạm dừng"**

| Nút | Chức năng |
|---|---|
| **Tiếp tục xử lý** | Chuyển lại về "Đang xử lý" để tiếp tục làm việc |

### 5.7. Khi HSCV bị **"Từ chối"** hoặc **"Trả về"**

| Nút | Chức năng |
|---|---|
| **Xử lý lại** | Chuyển về "Đang xử lý" để bổ sung, chỉnh sửa |
| **Hủy HSCV** | Hủy bỏ hồ sơ — kèm lý do hủy (chuyển sang trạng thái "Đã hủy") |

---

## 6. Các thao tác quan trọng — Giải thích chi tiết

### 6.1. Chuyển xử lý

**Mục đích**: Đánh dấu "Tôi bắt đầu làm việc với hồ sơ này".

Khi HSCV vừa được tạo, trạng thái mặc định là **"Mới tạo"**. Khi cán bộ phụ trách chính thức bắt đầu xử lý, bấm nút **"Chuyển xử lý"** để chuyển trạng thái sang **"Đang xử lý"**.

Chức năng này giúp lãnh đạo nhìn vào danh sách biết được hồ sơ nào chưa ai bắt đầu xử lý, hồ sơ nào đang được thực hiện — phục vụ theo dõi tiến độ và đôn đốc khi cần.

### 6.2. Chuyển tiếp HSCV

**Mục đích**: Bàn giao toàn bộ hồ sơ sang cán bộ khác (đi công tác, nghỉ phép, chuyển công tác, hoặc công việc không thuộc phạm vi phụ trách).

**Cách dùng**:
1. Bấm nút **"Chuyển tiếp HSCV"**
2. Chọn **Người nhận** (cán bộ cùng đơn vị)
3. Nhập **Ghi chú** (tùy chọn) — giải thích lý do bàn giao
4. Bấm **"Chuyển tiếp"**

**Sau khi chuyển tiếp**:
- Người mới trở thành **người phụ trách chính** của HSCV
- Mọi thao tác (cập nhật, thêm ý kiến, gắn văn bản...) đều chuyển sang người mới
- **Lịch sử chuyển tiếp được ghi lại đầy đủ** — có thể xem ở nút "Lịch sử"

**Ràng buộc**: Chỉ được chuyển trong cùng đơn vị, không chuyển cho chính mình, không chuyển cho tài khoản đã khóa.

### 6.3. Lấy số văn bản

**Mục đích**: Cấp số văn bản chính thức theo sổ đăng ký của đơn vị.

**Cách dùng**:
- **Lần đầu lấy số**: Bấm "Lấy số" → mở cửa sổ chọn **Sổ văn bản** → bấm "Lấy số". Hệ thống tự động cấp số kế tiếp theo công thức: số lớn nhất hiện có + 1.
- **Đã có sổ**: Chỉ cần xác nhận, hệ thống lấy số kế tiếp theo sổ đã chọn.

Sau khi lấy số thành công, phần đầu trang sẽ hiển thị "Số: [số] / [tên sổ]".

Nút "Lấy số" chỉ hiển thị ở trạng thái "Đang xử lý" hoặc "Đã trình ký", và chỉ khi HSCV chưa được lấy số.

### 6.4. Cập nhật tiến độ

**Mục đích**: Cập nhật phần trăm hoàn thành của hồ sơ (0–100%) để lãnh đạo theo dõi.

Nút này chỉ hiện khi HSCV đang ở trạng thái **"Đang xử lý"**. Người dùng điều chỉnh bằng thanh trượt hoặc nhập số trực tiếp.

### 6.5. Trả về / Từ chối

**Khi lãnh đạo không đồng ý với hồ sơ** (ở trạng thái "Chờ trình ký" hoặc "Đã trình ký"):

- **Trả về**: Hồ sơ còn có thể sửa chữa, cán bộ xử lý lại và trình ký lại. Kèm lý do trả về.
- **Từ chối**: Không đồng ý hoàn toàn. Kèm lý do từ chối.

Cả hai trường hợp đều **bắt buộc nhập lý do** để cán bộ hiểu và điều chỉnh.

### 6.6. Hủy HSCV

**Mục đích**: Đóng HSCV khi không còn giá trị xử lý.

Chỉ áp dụng được khi HSCV đã bị **Từ chối** hoặc **Trả về**. Người dùng phải nhập **lý do hủy** (bắt buộc).

Sau khi hủy:
- Trạng thái chuyển sang **"Đã hủy"**
- Thông tin hủy (lý do, người hủy, thời điểm) được hiển thị trong tab "Thông tin chung"
- HSCV không thể thao tác tiếp

### 6.7. Mở lại HSCV (sau khi đã hoàn thành)

Trường hợp hồ sơ đã "Hoàn thành" nhưng cần chỉnh sửa, bổ sung, người dùng có thể bấm **"Mở lại"** để đưa HSCV về trạng thái **"Đang xử lý"** (giữ nguyên tiến độ 100%).

### 6.8. Ký số trên file đính kèm

Trong tab **"File đính kèm"**, lãnh đạo ký có thể thực hiện ký số trực tiếp trên file PDF đính kèm. Nút "Ký số" chỉ xuất hiện khi:
- Người đăng nhập đúng là lãnh đạo ký của HSCV
- HSCV ở trạng thái "Chờ trình ký" hoặc "Đã trình ký"
- File là định dạng PDF
- File chưa được ký số

Sau khi ký thành công, file được gắn nhãn **"Đã ký số"** màu xanh.

### 6.9. Xem lịch sử HSCV

Bấm nút **"Lịch sử"** để xem toàn bộ các thao tác đã thực hiện trên HSCV, bao gồm:
- **Chuyển tiếp HSCV**: Ai chuyển, chuyển cho ai, khi nào, ghi chú gì
- **Hủy HSCV**: Ai hủy, khi nào, lý do
- **Mở lại HSCV**: Ai mở lại, khi nào

Mọi thao tác đều được ghi lại đầy đủ, minh bạch — phục vụ công tác kiểm tra, thanh tra về sau.

---

## 7. Quy trình nghiệp vụ tham khảo

Vòng đời điển hình của một HSCV:

```
Mới tạo
   │  (Cán bộ phụ trách bấm "Chuyển xử lý")
   ▼
Đang xử lý ◄────────────────┐
   │                        │
   │  (Bấm "Trình ký")      │  (Trả về / Xử lý lại)
   ▼                        │
Chờ trình ký                │
   │                        │
   │  (Bấm "Gửi trình ký")  │
   ▼                        │
Đã trình ký ────────────────┘
   │
   │  (Lãnh đạo bấm "Duyệt hồ sơ")
   ▼
Hoàn thành
```

Các trạng thái phụ **"Tạm dừng"**, **"Từ chối"**, **"Trả về"**, **"Đã hủy"** là các nhánh rẽ khi có tình huống đặc biệt.

---

## 8. Tóm tắt các tính năng chính

| Nhóm | Tính năng |
|---|---|
| **Thông tin hồ sơ** | Xem/sửa thông tin chung, theo dõi tiến độ |
| **Văn bản liên kết** | Gắn/gỡ các văn bản đến, đi, dự thảo |
| **Phân công cán bộ** | Thêm/xóa thành viên, gán vai trò (phụ trách/phối hợp) và hạn xử lý |
| **Trao đổi ý kiến** | Gửi ý kiến, chuyển tiếp ý kiến giữa các thành viên |
| **File đính kèm** | Tải lên, tải xuống, xóa file; ký số PDF trực tiếp |
| **HSCV con** | Chia hồ sơ lớn thành các hồ sơ con |
| **Quản lý trạng thái** | Chuyển xử lý, trình ký, duyệt, trả về, từ chối, tạm dừng, mở lại, hủy |
| **Bàn giao** | Chuyển tiếp toàn bộ HSCV cho cán bộ khác |
| **Cấp số văn bản** | Lấy số tự động theo sổ đăng ký |
| **Lịch sử** | Xem toàn bộ lịch sử thao tác — minh bạch, đầy đủ |

---

*Tài liệu được biên soạn dựa trên hệ thống thực tế đang triển khai. Mọi thắc mắc vui lòng liên hệ với đội phát triển để được hỗ trợ.*
