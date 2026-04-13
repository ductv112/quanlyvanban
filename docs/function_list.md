# FUNCTION LIST — HỆ THỐNG QUẢN LÝ VĂN BẢN
> Phiên bản: 2.0 | Ngày: 2026-04-13
> Phân tích từ: 47 screenshots UI + source code .NET (9.308 files)
> Dự án mới: Next.js + PostgreSQL + MongoDB + Redis + MinIO

---

## MODULE 1: TỔNG QUAN (Dashboard)

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| DAS-01 | Xem Dashboard cá nhân | Hiển thị widget: VB đến chưa đọc, VB đi chưa đọc, Hồ sơ thống kê, Việc sắp hạn | |
| DAS-02 | Widget Văn bản đến chưa đọc | Hiển thị số lượng, link "Xem thêm" tới danh sách VB đến | |
| DAS-03 | Widget Văn bản đi chưa đọc | Hiển thị số lượng, link "Xem thêm" tới danh sách VB đi | |
| DAS-04 | Widget Hồ sơ thống kê | Hiển thị số lượng hồ sơ công việc theo trạng thái | |
| DAS-05 | Widget Việc sắp tới hạn | Danh sách công việc gần đến hạn (Tên, Ngày mở, Trạng thái, Tiến độ %) | |
| DAS-06 | Cấu hình Dashboard | Người dùng tự thêm/xóa/sắp xếp/kéo thả widget theo nhu cầu | MỚI — react-grid-layout |
| DAS-07 | Dashboard đơn vị | Tổng quan thống kê theo đơn vị (khác Dashboard cá nhân) | MỚI — từ source code |

---

## MODULE 2: VĂN BẢN ĐẾN

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| VBD-01 | Danh sách Văn bản đến | Hiển thị danh sách, phân trang; cột: #, Ngày đến, Số đến, Số Ký hiệu, Trích yếu, Cơ quan ban hành, Tài liệu | |
| VBD-02 | Tìm kiếm / Lọc VB đến | Lọc theo ngày, cơ quan, số hiệu, trích yếu, trạng thái đọc | |
| VBD-03 | Tìm kiếm nâng cao | Mở rộng bộ lọc với nhiều tiêu chí hơn | |
| VBD-04 | Thêm mới VB đến | Nhập thông tin VB đến mới vào hệ thống | |
| VBD-05 | Xem chi tiết VB đến | Hiển thị đầy đủ thông tin 2 cột + file đính kèm + danh sách gửi nhanh | |
| VBD-06 | Chỉnh sửa VB đến | Cập nhật thông tin VB đến đã nhập | |
| VBD-07 | Xóa VB đến | Xóa văn bản đến khỏi hệ thống | |
| VBD-08 | Upload tài liệu đính kèm | Đính kèm file PDF/Office vào VB đến (lưu MinIO) | |
| VBD-09 | Tải xuống tài liệu đính kèm | Download file đính kèm | |
| VBD-10 | Đánh dấu đã đọc / Chưa đọc | Thay đổi trạng thái đọc của VB đến | |
| VBD-11 | Nhận bàn giao | Xác nhận tiếp nhận VB đến được bàn giao | |
| VBD-12 | Hủy duyệt | Hủy xác nhận đã duyệt VB đến | |
| VBD-13 | Bút phê | Thêm ý kiến/bút phê của lãnh đạo lên VB đến | |
| VBD-14 | Thêm vào Hồ sơ công việc | Gắn VB đến vào một HSCV đang xử lý | |
| VBD-15 | Giao việc từ VB đến | Tạo công việc và giao cho cán bộ từ VB đến | |
| VBD-16 | Gửi nhanh VB đến | Chuyển tiếp VB đến tới danh sách người nhận được chọn | |
| VBD-17 | Chuyển lại Hội đồng | Chuyển VB đến trở lại cho hội đồng xem xét | |
| VBD-18 | Đánh dấu cá nhân | Gắn nhãn cá nhân cho VB đến (bookmark) | |
| VBD-19 | In danh sách VB đến | Xuất danh sách ra file in | |
| VBD-20 | Cập nhật trạng thái văn bản giấy | Đánh dấu Chưa nhận / Đã nhận bản giấy | |
| VBD-21 | Cập nhật trạng thái lưu trữ | Đánh dấu Chưa lưu trữ / Đã lưu trữ | |
| VBD-22 | Bút phê lãnh đạo (LeaderNote) | Lãnh đạo ghi chú/bút phê trực tiếp lên VB đến, lưu lịch sử nhiều bút phê | MỚI — entity LeaderNote |
| VBD-23 | Xem lịch sử phân phối | Xem danh sách ai đã nhận, ai đã đọc VB đến, thời gian đọc | MỚI — entity UserIncomingDoc |

---

## MODULE 3: VĂN BẢN LIÊN THÔNG

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| VBL-01 | Danh sách VB liên thông đến | Hiển thị VB nhận từ đơn vị khác qua trục LGSP; cột: Ngày nhận, Ký hiệu, Trích yếu, Hạn trả lời, Đơn vị phát hành, Người ký | |
| VBL-02 | Xem chi tiết VB liên thông | Xem nội dung đầy đủ VB liên thông | |
| VBL-03 | Tìm kiếm / Lọc | Lọc theo ngày, đơn vị, ký hiệu | |
| VBL-04 | Trả lời VB liên thông | Soạn và gửi phản hồi tới đơn vị phát hành | |
| VBL-05 | Gửi VB liên thông đi | Chuyển VB đi sang đơn vị ngoài qua trục LGSP (edXML format) | MỚI — entity InterOutgoingDoc |
| VBL-06 | Cập nhật trạng thái liên thông | Đồng bộ trạng thái xử lý giữa các đơn vị (done/received/processing) | MỚI — LGSP API update-status |
| VBL-07 | Quản lý tổ chức liên thông | CRUD danh sách đơn vị tham gia liên thông (InterOrganization) | MỚI — entity InterOrganization |
| VBL-08 | Tự động nhận VB liên thông | Background job định kỳ quét VB mới từ trục LGSP | MỚI — thay Windows Service VNPT.Get |

---

## MODULE 4: VĂN BẢN DỰ THẢO

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| VBT-01 | Danh sách VB dự thảo | Hiển thị danh sách; cột: #, Ngày đề, Số đề, Ký hiệu, Trích yếu, Nơi nhận | |
| VBT-02 | Thêm mới VB dự thảo | Soạn văn bản dự thảo mới | |
| VBT-03 | Chỉnh sửa VB dự thảo | Cập nhật nội dung dự thảo | |
| VBT-04 | Xóa VB dự thảo | Xóa bản dự thảo | |
| VBT-05 | Upload file dự thảo | Đính kèm file nội dung dự thảo (lưu MinIO) | |
| VBT-06 | Trình ký dự thảo | Chuyển dự thảo lên lãnh đạo ký duyệt | |
| VBT-07 | Phát hành VB dự thảo | Sau khi được ký, chuyển thành VB phát hành (Approve → OutgoingDoc) | |
| VBT-08 | In danh sách dự thảo | Xuất danh sách ra file in | |
| VBT-09 | Xem lịch sử phân phối | Ai đã nhận/đọc dự thảo | MỚI — entity UserDraftingDoc |

---

## MODULE 5: VĂN BẢN PHÁT HÀNH (Văn bản đi)

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| VBI-01 | Danh sách VB phát hành | Hiển thị danh sách; cột: #, Ngày đề, Số đề, Ký Số, Ký Hiệu, Trích yếu, Tài liệu | |
| VBI-02 | Thêm mới VB phát hành | Nhập thông tin phát hành văn bản đi | |
| VBI-03 | Xem chi tiết VB phát hành | Xem đầy đủ thông tin VB đã phát hành | |
| VBI-04 | Chỉnh sửa VB phát hành | Cập nhật thông tin VB phát hành | |
| VBI-05 | Xóa VB phát hành | Xóa VB phát hành | |
| VBI-06 | Upload tài liệu đính kèm | Đính kèm file VB phát hành (lưu MinIO) | |
| VBI-07 | Tải xuống tài liệu | Download file đính kèm | |
| VBI-08 | Đánh dấu đã đọc | Đánh dấu đã đọc VB phát hành | |
| VBI-09 | Tìm kiếm / Lọc | Lọc theo ngày, số hiệu, trích yếu | |
| VBI-10 | In danh sách VB phát hành | Xuất danh sách ra file in | |
| VBI-11 | Cấp số phát hành tự động | Hệ thống tự sinh số VB phát hành theo sổ văn bản | MỚI — entity OutgoingDocNumber |
| VBI-12 | Xem lịch sử phân phối | Ai đã nhận/đọc VB đi | MỚI — entity UserOutgoingDoc |

---

## MODULE 6: HỒ SƠ CÔNG VIỆC (Workflow)

### 6.1 Quản lý Hồ sơ công việc

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| HSV-01 | Xem toàn bộ công việc | Danh sách tất cả HSCV; cột: Tên, Ngày mở, Hạn giải quyết, Trạng thái, Phụ trách, Lãnh đạo ký, Tiến độ % | |
| HSV-02 | Xem công việc tôi tạo | Lọc chỉ hiện HSCV do người dùng hiện tại tạo | |
| HSV-03 | Xem công việc bị từ chối | Danh sách HSCV bị từ chối | |
| HSV-04 | Xem công việc trả về bổ sung | Danh sách HSCV bị trả về cần bổ sung hồ sơ | |
| HSV-05 | Xem công việc chưa xử lý (phụ trách) | HSCV được giao cho tôi chưa xử lý | |
| HSV-06 | Xem công việc chưa xử lý (phối hợp) | HSCV tôi tham gia phối hợp chưa xử lý | |
| HSV-07 | Xem công việc đang trình ký | HSCV đang chờ lãnh đạo ký | |
| HSV-08 | Xem công việc đang giải quyết | HSCV đang trong quá trình xử lý | |
| HSV-09 | Xem công việc đề xuất hoàn thành | HSCV chờ xác nhận hoàn thành | |
| HSV-10 | Xem công việc đã hoàn thành | Lịch sử HSCV đã kết thúc | |
| HSV-11 | Tạo mới HSCV | Tạo hồ sơ công việc mới, gắn văn bản, chỉ định quy trình | |
| HSV-12 | Xem chi tiết HSCV | Xem toàn bộ thông tin, lịch sử xử lý, file đính kèm | |
| HSV-13 | Chỉnh sửa HSCV | Cập nhật thông tin HSCV | |
| HSV-14 | Xóa HSCV | Xóa hồ sơ công việc | |
| HSV-15 | Giao việc / Phân công | Giao HSCV cho cán bộ phụ trách (Prim) | |
| HSV-16 | Xử lý / Giải quyết | Cán bộ thực hiện xử lý bước công việc | |
| HSV-17 | Trình ký | Chuyển HSCV lên lãnh đạo ký duyệt | |
| HSV-18 | Ký duyệt | Lãnh đạo ký duyệt HSCV | |
| HSV-19 | Từ chối | Từ chối xử lý HSCV | |
| HSV-20 | Trả về bổ sung | Yêu cầu bổ sung hồ sơ/thông tin | |
| HSV-21 | Đề xuất hoàn thành | Cán bộ đề xuất đóng HSCV | |
| HSV-22 | Xác nhận hoàn thành | Lãnh đạo/quản lý xác nhận đóng HSCV | |
| HSV-23 | Cập nhật tiến độ % | Nhập % tiến độ hoàn thành công việc | |
| HSV-24 | Upload tài liệu HSCV | Đính kèm file vào HSCV (lưu MinIO) | |
| HSV-25 | Xem lịch sử xử lý | Xem toàn bộ log các bước đã thực hiện | |
| HSV-26 | Ý kiến xử lý (Opinion) | Cán bộ gửi ý kiến trao đổi trong HSCV, đính kèm file | MỚI — entity OpinionHandlingDoc |
| HSV-27 | Phối hợp xử lý | Mời cán bộ khác phối hợp giải quyết (vai trò Prim/Coordinator) | MỚI — entity StaffHandlingDoc.Role |
| HSV-28 | Liên kết HSCV với VB | Gắn nhiều VB đến/đi/dự thảo vào 1 HSCV | MỚI — entity HandlingDocLink |
| HSV-29 | Mở lại HSCV đã đóng | Mở lại HSCV đã hoàn thành nếu cần xử lý tiếp | MỚI — UserCanReopen flag |

### 6.2 Cấu hình giao việc

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| HSV-30 | Cấu hình danh sách giao việc | Chọn cán bộ có thể được giao việc theo phòng ban/đơn vị | |

### 6.3 Kiểm soát công việc (Báo cáo)

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| HSV-40 | Tổng quan công việc | KPI: Tổng số, Chuyển kỳ trước, Kỳ này, Hoàn thành, Đang thực hiện, Đang quá hạn (%) + biểu đồ | |
| HSV-41 | Bảng cá nhân được giao | Danh sách cán bộ + tổng đầu việc + tỉ lệ hoàn thành | |
| HSV-42 | Báo cáo HSCV tại đơn vị | Bảng thống kê theo đơn vị: tổng HSCV, chuyển kỳ, mới giao, đã xử lý, quá hạn | |
| HSV-43 | Báo cáo giải quyết công việc | Bảng thống kê theo cán bộ phụ trách | |
| HSV-44 | Báo cáo HSCV theo cán bộ giao việc | Thống kê hiệu quả giao việc của từng cán bộ | |
| HSV-45 | Lọc báo cáo theo thời gian/đơn vị | Bộ lọc: Đơn vị, Từ ngày, Đến ngày, Cán bộ | |
| HSV-46 | Xuất báo cáo Excel/PDF | Export báo cáo thống kê ra file | MỚI — từ StatisticController |

---

## MODULE 7: QUY TRÌNH GIẢI QUYẾT (Workflow Designer)

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-01 | Xem danh sách quy trình | Danh sách các quy trình đã tạo, lọc theo lĩnh vực/đơn vị | |
| QT-02 | Tạo quy trình mới | Thiết kế quy trình bằng visual flowchart (kéo thả) | React Flow |
| QT-03 | Chỉnh sửa quy trình | Cập nhật các bước, điều kiện trong quy trình | |
| QT-04 | Xóa quy trình | Xóa quy trình không dùng | |
| QT-05 | Thêm bước xử lý (node) | Thêm node vào flowchart: Bắt đầu, Tiếp nhận, Soạn, Hành động, Kết thúc, Ghi chú | |
| QT-06 | Cấu hình bước xử lý | Tên bước, Loại bước, Cho phép trình ký, DS cán bộ (Prim/Coordinator), Thời hạn (ngày) | |
| QT-07 | Gán quy trình cho HSCV | Khi tạo HSCV chọn quy trình áp dụng | |
| QT-08 | Kết nối các bước (links) | Vẽ đường nối giữa các node (inputs/outputs connectors) | MỚI — entity WorkflowStepLink |
| QT-09 | Versioning quy trình | Lưu nhiều phiên bản của cùng 1 quy trình (DocFlow.Version) | MỚI — từ source code |
| QT-10 | Nhân bản quy trình | Clone quy trình có sẵn để chỉnh sửa | MỚI — tiện ích |

---

## MODULE 8: ỦY QUYỀN

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| UQ-01 | Xem danh sách ủy quyền | Danh sách ủy quyền xử lý VB/HSCV đang có hiệu lực | MỚI — entity Authorized, Deligation |
| UQ-02 | Tạo ủy quyền | Ủy quyền cho cán bộ khác xử lý VB/HSCV trong khoảng thời gian | MỚI |
| UQ-03 | Thu hồi ủy quyền | Hủy ủy quyền trước hạn | MỚI |
| UQ-04 | Xem lịch sử ủy quyền | Danh sách ủy quyền đã hết hạn/thu hồi | MỚI |

---

## MODULE 9: TIN NHẮN NỘI BỘ

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| TN-01 | Soạn tin nhắn | Soạn và gửi tin nhắn tới người dùng/nhóm trong hệ thống | |
| TN-02 | Hộp thư đến | Xem tin nhắn nhận được | |
| TN-03 | Hộp thư đã gửi | Xem tin nhắn đã gửi | |
| TN-04 | Thùng rác | Xem tin nhắn đã xóa, khôi phục hoặc xóa vĩnh viễn | |
| TN-05 | Tìm kiếm tin nhắn | Tìm theo nội dung, người gửi, ngày gửi | |
| TN-06 | Xóa tin nhắn | Chuyển tin vào thùng rác | |
| TN-07 | Đính kèm file trong tin nhắn | Upload file đính kèm khi gửi tin nhắn nội bộ | MỚI — entity AttachmentsOfInternalMessages |
| TN-08 | Trả lời tin nhắn | Reply trực tiếp trong thread tin nhắn | MỚI — entity MessageReplies |

---

## MODULE 10: THÔNG BÁO & NOTIFICATION

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| TB-01 | Xem danh sách thông báo | Thông báo hệ thống gửi tới người dùng | |
| TB-02 | Đánh dấu đã đọc | Cập nhật trạng thái thông báo | |
| TB-03 | Tạo thông báo | Admin/lãnh đạo gửi thông báo nội bộ kèm file đính kèm | MỚI — entity Notice, AttachmentNotice |
| TB-04 | Notification real-time | Đẩy thông báo tức thì qua WebSocket khi có VB/HSCV mới | MỚI — Socket.IO |
| TB-05 | Push notification mobile | Gửi push notification tới app mobile qua Firebase FCM | MỚI — FCM integration |
| TB-06 | Gửi thông báo Zalo | Gửi tin nhắn thông báo qua Zalo Official Account | MỚI — Zalo OA API |

---

## MODULE 11: TIỆN ÍCH

### 11.1 Lịch

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| LI-01 | Lịch cá nhân | Xem/thêm sự kiện cá nhân trên calendar | |
| LI-02 | Lịch cơ quan | Xem lịch chung của toàn đơn vị (tuần/tháng) | |
| LI-03 | Lịch cơ quan rút gọn | Hiển thị lịch cơ quan dạng compact | |
| LI-04 | Lịch lãnh đạo | Xem lịch làm việc của Ban Lãnh đạo | |
| LI-05 | Thêm sự kiện lịch | Tạo sự kiện trên lịch cá nhân hoặc cơ quan | |
| LI-06 | Chỉnh sửa sự kiện | Cập nhật thông tin sự kiện | |
| LI-07 | Xóa sự kiện | Xóa sự kiện khỏi lịch | |
| LI-08 | Lịch công tác | Lịch làm việc / công tác của đơn vị | MỚI — entity WorkSchedule |

### 11.2 Danh bạ điện thoại

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| DB-01 | Xem danh bạ | Danh sách cán bộ kèm SĐT, chức vụ, phòng ban | |
| DB-02 | Tìm kiếm danh bạ | Tìm theo tên, phòng ban, chức vụ | |

---

## MODULE 12: HỌP KHÔNG GIẤY

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| HP-01 | Danh sách cuộc họp đang diễn ra | Hiển thị các cuộc họp đang diễn ra | |
| HP-02 | Danh sách cuộc họp chờ phê duyệt | Cuộc họp chờ lãnh đạo phê duyệt | |
| HP-03 | Danh sách cuộc họp sắp tới | Cuộc họp đã được duyệt, sắp diễn ra | |
| HP-04 | Đăng ký lịch họp | Tạo yêu cầu tổ chức cuộc họp | |
| HP-05 | Phê duyệt cuộc họp | Lãnh đạo duyệt/từ chối lịch họp | |
| HP-06 | Xem chi tiết cuộc họp | Thông tin: thời gian, địa điểm, thành phần, tài liệu, nội dung | |
| HP-07 | Chỉnh sửa cuộc họp | Cập nhật thông tin cuộc họp | |
| HP-08 | Hủy cuộc họp | Hủy lịch họp đã đặt | |
| HP-09 | Thống kê cuộc họp | Báo cáo số lượng, tần suất cuộc họp | |
| HP-10 | Quản lý loại cuộc họp | CRUD danh mục loại họp | |
| HP-11 | Upload tài liệu cuộc họp | Đính kèm file tài liệu vào cuộc họp | MỚI — entity RoomScheduleAttachment |
| HP-12 | Nội dung cuộc họp | Quản lý nội dung/chương trình từng cuộc họp | MỚI — entity RoomScheduleContent |
| HP-13 | Ý kiến cuộc họp | Thành viên nhập ý kiến thảo luận trong cuộc họp | MỚI — entity RoomScheduleOpinion |
| HP-14 | Biểu quyết trực tuyến | Real-time vote trong phòng họp (Socket.IO), đếm ngược, hiển thị kết quả | MỚI — Socket.IO vote |
| HP-15 | Upload audio ghi âm | Tải file ghi âm cuộc họp | MỚI — entity RoomScheduleAudioUpload |
| HP-16 | Quản lý phòng họp | CRUD danh mục phòng họp vật lý | MỚI — entity Room |
| HP-17 | Nhóm phòng họp | Phân nhóm phòng họp theo đơn vị | MỚI — entity RoomGroups |
| HP-18 | Chia sẻ cá nhân | Chia sẻ tài liệu cá nhân cho cuộc họp | MỚI — entity RoomSchedulePersonalShare |

---

## MODULE 13: HỢP ĐỒNG

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| HD-01 | Danh sách hợp đồng | Xem toàn bộ hợp đồng | |
| HD-02 | Thêm mới hợp đồng | Nhập thông tin hợp đồng mới | |
| HD-03 | Xem chi tiết hợp đồng | Xem đầy đủ thông tin + file đính kèm | |
| HD-04 | Chỉnh sửa hợp đồng | Cập nhật thông tin hợp đồng | |
| HD-05 | Xóa hợp đồng | Xóa hợp đồng | |
| HD-06 | Upload file hợp đồng | Đính kèm file scan/PDF (lưu MinIO) | |
| HD-07 | Quản lý loại hợp đồng | CRUD danh mục loại hợp đồng | |
| HD-08 | Tìm kiếm / Lọc | Lọc theo ngày, đối tác, loại hợp đồng | |
| HD-09 | Phụ lục hợp đồng | CRUD phụ lục đính kèm hợp đồng chính | MỚI — entity SubContract |
| HD-10 | Quản lý đối tác | CRUD thông tin đối tác/bên ký hợp đồng | MỚI — entity Contact |
| HD-11 | Phân quyền hợp đồng | Gán quyền xem/sửa hợp đồng cho người dùng | MỚI — entity UserContract |

---

## MODULE 14: KHO LƯU TRỮ

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| KL-01 | Quản lý tổ chức lưu trữ | Cấu hình cấu trúc kho: Phòng lưu trữ → Kho → Kệ | |
| KL-02 | Mượn hồ sơ | Đăng ký mượn hồ sơ từ kho | |
| KL-03 | Trả hồ sơ | Xác nhận trả hồ sơ về kho | |
| KL-04 | Theo dõi mượn/trả | Xem lịch sử mượn/trả | |
| KL-05 | Danh mục Kho - kệ | CRUD danh mục kho, kệ | |
| KL-06 | Danh mục Phòng lưu trữ | CRUD danh mục phòng lưu trữ | |
| KL-07 | Danh mục Loại văn kiện lưu trữ | CRUD loại văn kiện | |
| KL-08 | Phông lưu trữ | Quản lý phông (Fond) — đơn vị tổ chức lưu trữ cấp cao | MỚI — entity Fond |
| KL-09 | Hồ sơ lưu trữ | Quản lý hồ sơ trong kho (Record), gắn tài liệu | MỚI — entity Record |
| KL-10 | Mục lục đăng ký | Danh mục đăng ký hồ sơ lưu trữ | MỚI — entity Registrasionlist |
| KL-11 | Chỉnh lý hồ sơ | Quy trình chỉnh lý tài liệu lưu trữ | MỚI — entity ReadjustmentProcess |
| KL-12 | Lưu trữ từ VB đi | Chuyển VB phát hành vào kho lưu trữ | MỚI — DocumentArchive.FromOutgoingDoc |

---

## MODULE 15: TÀI LIỆU CHUNG

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| TL-01 | Tài liệu đào tạo | Xem/upload/quản lý tài liệu đào tạo | |
| TL-02 | Tài liệu nội bộ | Xem/upload/quản lý tài liệu nội bộ | |
| TL-03 | Tài liệu ISO | Xem/upload/quản lý tài liệu tiêu chuẩn ISO | |
| TL-04 | Văn bản pháp quy | Xem/upload/quản lý văn bản pháp quy | |
| TL-05 | Tài liệu khác | Xem/upload/quản lý tài liệu tổng hợp | |
| TL-06 | Upload tài liệu | Tải file lên hệ thống (lưu MinIO) | |
| TL-07 | Tải xuống tài liệu | Download file tài liệu | |
| TL-08 | Tìm kiếm tài liệu | Tìm theo tên, loại, nhóm | |
| TL-09 | Quản lý nhóm tài liệu | CRUD danh mục nhóm (đào tạo, nội bộ, ISO, pháp quy, khác) | |
| TL-10 | Lịch sử thay đổi tài liệu | Ghi log mọi thay đổi trên tài liệu (versioning) | MỚI — entity IsoDocumentHistory |

---

## MODULE 16: KÝ SỐ ĐIỆN TỬ

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| KS-01 | Ký số VNPT SmartCA | Ký số từ xa qua VNPT gateway (SHA256, ký PDF append) | MỚI — REST API SmartCA |
| KS-02 | Ký số NEAC (ESign) | Ký số qua nền tảng NEAC — hỗ trợ đa CA: MISA, Bkav, VNPT, Viettel, FPT | MỚI — REST API NEAC |
| KS-03 | Ký số USB Token | Ký số bằng USB token vật lý (client-side) | MỚI — Web Crypto API |
| KS-04 | Xác minh chữ ký | Kiểm tra tính hợp lệ của chữ ký số trên VB/PDF | MỚI |
| KS-05 | Hiển thị chữ ký trên PDF | Hiển thị ảnh chữ ký (logo, text, background) tại vị trí chỉ định trên PDF | MỚI — pdf-lib |
| KS-06 | Quản lý chứng thư số | CRUD chứng thư số (.cer) của cán bộ | MỚI — từ thư mục Certs/ |

---

## MODULE 17: QUẢN TRỊ HỆ THỐNG

### 17.1 Quản lý Người dùng

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-ND-01 | Xem cây tổ chức | Tree: Đơn vị → Phòng ban → Cán bộ | |
| QT-ND-02 | Danh sách người dùng | Danh sách cán bộ trong phòng ban được chọn | |
| QT-ND-03 | Thêm người dùng mới | Tạo tài khoản mới với đầy đủ thông tin | |
| QT-ND-04 | Chỉnh sửa người dùng | Cập nhật thông tin cán bộ | |
| QT-ND-05 | Xóa người dùng | Xóa tài khoản (soft delete) | |
| QT-ND-06 | Tạm dừng / Kích hoạt tài khoản | Bật/tắt quyền đăng nhập | |
| QT-ND-07 | Đặt lại mật khẩu | Reset mật khẩu cho người dùng | |
| QT-ND-08 | Phân quyền nhóm | Gán nhóm quyền (Lãnh đạo / Chuyên viên / Văn thư...) cho người dùng | |
| QT-ND-09 | Upload ảnh đại diện | Tải ảnh profile lên hệ thống (lưu MinIO) | |

### 17.2 Quản lý Nhóm quyền

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-NQ-01 | Danh sách nhóm quyền | Hiển thị: Ban Lãnh đạo, Cán bộ, Chỉ đạo điều hành, Trưởng phòng, Quản trị, Văn thư | |
| QT-NQ-02 | Thêm nhóm quyền | Tạo nhóm quyền mới | |
| QT-NQ-03 | Chỉnh sửa nhóm quyền | Cập nhật tên, mô tả nhóm | |
| QT-NQ-04 | Xóa nhóm quyền | Xóa nhóm quyền | |
| QT-NQ-05 | Phân quyền chức năng | Gán/thu hồi quyền truy cập chức năng cho nhóm | |
| QT-NQ-06 | Xem danh sách người dùng trong nhóm | Hiển thị: Họ tên, Tài khoản, Chức vụ, Đơn vị/Phòng ban | |

### 17.3 Quản lý Chức năng (Menu/Permissions)

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-CN-01 | Xem cây chức năng | Hiển thị toàn bộ cây menu hệ thống | |
| QT-CN-02 | Thêm chức năng | Tạo mục menu mới (Tên, ID, URL, Icon, Thứ tự, Nhóm, Hiện trên menu, Trang mặc định) | |
| QT-CN-03 | Chỉnh sửa chức năng | Cập nhật thông tin chức năng | |
| QT-CN-04 | Xóa chức năng | Xóa mục menu | |
| QT-CN-05 | Gán quyền cho chức năng | Thiết lập danh sách quyền trên từng chức năng | |
| QT-CN-06 | Nhật ký thay đổi (Audit Log) | Xem log mọi thao tác thay đổi dữ liệu trong hệ thống | MỚI — entity LogAllChange |

### 17.4 Quản lý Đơn vị / Phòng ban

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-DV-01 | Xem cây đơn vị | Tree: Đơn vị → Phòng ban | |
| QT-DV-02 | Thêm đơn vị/phòng ban | Tạo mới node tổ chức | |
| QT-DV-03 | Chỉnh sửa đơn vị | Cập nhật thông tin (tên, mã, LGSP SystemId/SecretKey...) | |
| QT-DV-04 | Xóa đơn vị | Xóa đơn vị/phòng ban (soft delete) | |

### 17.5 Quản lý Chức vụ

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-CV-01 | Danh sách chức vụ | Trưởng phòng, Phó Trưởng phòng, Chuyên viên, Giám đốc, Phó Giám đốc, Văn Thư... | |
| QT-CV-02 | Thêm chức vụ | Tạo chức vụ mới | |
| QT-CV-03 | Chỉnh sửa chức vụ | Cập nhật tên, mã, thứ tự | |
| QT-CV-04 | Xóa chức vụ | Xóa chức vụ không dùng | |

### 17.6 Quản lý Thông báo (SMS / Email / Push)

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-SMS-01 | Danh sách template SMS | Xem mẫu SMS theo đơn vị | |
| QT-SMS-02 | Thêm template SMS | Tạo mẫu SMS với biến động (vd: [CVNAME]) | |
| QT-SMS-03 | Chỉnh sửa template SMS | Cập nhật nội dung mẫu | |
| QT-SMS-04 | Xóa template SMS | Xóa mẫu | |
| QT-SMS-05 | Xem lịch sử gửi SMS | Log các tin SMS đã gửi | |
| QT-EM-01 | Danh sách template Email | Quản lý mẫu email thông báo | |
| QT-EM-02 | Chỉnh sửa template Email | Cập nhật HTML nội dung email | |
| QT-EM-03 | Gửi email test | Kiểm tra template bằng cách gửi thử | |
| QT-EM-04 | Xem lịch sử gửi Email | Log các email đã gửi (hàng đợi, đã gửi, lỗi) | MỚI — entity EmailMessageHistory |
| QT-FCM-01 | Cấu hình Push Notification | Cấu hình Firebase FCM key, template push | MỚI — FCM integration |

### 17.7 Địa bàn hành chính

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-DC-01 | Quản lý Tỉnh/Thành phố | CRUD danh mục tỉnh/thành phố | |
| QT-DC-02 | Quản lý Quận/Huyện | CRUD danh mục quận/huyện theo tỉnh | |
| QT-DC-03 | Quản lý Phường/Xã | CRUD danh mục phường/xã theo huyện | |

### 17.8 Cấu hình Lịch làm việc

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-LV-01 | Xem lịch làm việc | Calendar view toàn hệ thống | |
| QT-LV-02 | Cấu hình ngày nghỉ | Đánh dấu ngày lễ, ngày nghỉ bù | |
| QT-LV-03 | Cấu hình giờ làm việc | Thiết lập khung giờ làm việc | |

### 17.9 Danh mục Văn bản

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-VB-01 | Quản lý sổ VB đến | CRUD sổ đăng ký VB đến theo đơn vị | |
| QT-VB-02 | Quản lý sổ VB đi | CRUD sổ đăng ký VB đi theo đơn vị | |
| QT-VB-03 | Quản lý sổ VB dự thảo | CRUD sổ đăng ký VB dự thảo | |
| QT-VB-04 | Phân loại văn bản | CRUD loại VB (CV, NQ, QĐ, CT, QC...) theo nhóm (QPPL, hành chính...) | |
| QT-VB-05 | Thuộc tính VB đến | Cấu hình trường dữ liệu VB đến (bật/tắt, bắt buộc, hiển thị mặc định) | |
| QT-VB-06 | Thuộc tính VB đi | Cấu hình trường dữ liệu VB đi | |
| QT-VB-07 | Thuộc tính VB dự thảo | Cấu hình trường dữ liệu VB dự thảo | |
| QT-VB-08 | Lĩnh vực văn bản | CRUD mã và tên lĩnh vực theo đơn vị | |
| QT-VB-09 | Thông tin cơ quan | Cập nhật thông tin đơn vị (mã, tên, địa chỉ, SĐT, fax, email, cấp cơ quan) | |
| QT-VB-10 | Convert DOCX → PDF | Chuyển đổi file văn bản sang PDF (LibreOffice headless) | MỚI — thay DocXToPdfConverter |
| QT-VB-11 | Tạo mã vạch / QR Code | Sinh barcode (Code128) và QR code cho VB và hồ sơ | MỚI — thay QRCodeLib |

### 17.10 Nhóm làm việc

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-NL-01 | Danh sách nhóm làm việc | Xem các nhóm theo đơn vị | |
| QT-NL-02 | Thêm nhóm làm việc | Tạo nhóm, gán thành viên | |
| QT-NL-03 | Chỉnh sửa nhóm | Cập nhật thành viên, chức năng nhóm | |
| QT-NL-04 | Xóa nhóm | Xóa nhóm làm việc | |

### 17.11 Lãnh đạo ký lịch

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-LK-01 | Cấu hình lãnh đạo ký lịch | Gán cán bộ lãnh đạo có quyền ký lịch cho từng phòng ban | |

### 17.12 Quản lý người ký văn bản

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-NK-01 | Cấu hình người ký VB | Gán cán bộ có quyền ký văn bản cho từng phòng ban/đơn vị | |

### 17.13 Cấu hình hệ thống

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| QT-HT-01 | Cấu hình chung | Quản lý key/value cấu hình hệ thống (upload size, extension cho phép...) | MỚI — entity Configuration |
| QT-HT-02 | Cấu hình LGSP | SystemId, SecretKey, endpoint cho từng đơn vị kết nối trục liên thông | MỚI — từ Web.config lgsp.* |
| QT-HT-03 | Cấu hình ký số | Client ID/Secret cho SmartCA, endpoint NEAC, CA settings | MỚI — từ Web.config smartca.* |

---

## MODULE 18: XÁC THỰC & PHIÊN LÀM VIỆC

| Mã | Chức năng | Mô tả | Ghi chú |
|----|-----------|-------|---------|
| AUTH-01 | Đăng nhập | Xác thực bằng tên tài khoản + mật khẩu (bcrypt) | Nâng cấp từ MD5 |
| AUTH-02 | Đăng xuất | Kết thúc phiên làm việc, xóa JWT token | |
| AUTH-03 | Đổi mật khẩu | Người dùng tự đổi mật khẩu cá nhân | |
| AUTH-04 | Quên mật khẩu | Khôi phục mật khẩu qua email | |
| AUTH-05 | Kiểm soát phiên | Timeout tự động, refresh token, single session | |
| AUTH-06 | SSO / OpenID Connect | Đăng nhập qua hệ thống SSO bên ngoài (OAuth2 Authorization Code flow) | MỚI — CallbackController |
| AUTH-07 | Phân quyền theo API | Middleware kiểm tra quyền truy cập từng API route | MỚI — nâng cấp |

---

## TỔNG HỢP

| # | Module | v1.0 | v2.0 | Thay đổi |
|---|--------|------|------|----------|
| 1 | Dashboard | 6 | 7 | +1 |
| 2 | Văn bản đến | 21 | 23 | +2 |
| 3 | Văn bản liên thông | 4 | 8 | +4 |
| 4 | Văn bản dự thảo | 8 | 9 | +1 |
| 5 | Văn bản phát hành | 10 | 12 | +2 |
| 6 | Hồ sơ công việc | 31 | 36 | +5 |
| 7 | Quy trình (Workflow) | 7 | 10 | +3 |
| 8 | **Ủy quyền** | — | **4** | **MỚI** |
| 9 | Tin nhắn nội bộ | 6 | 8 | +2 |
| 10 | **Thông báo & Notification** | 2 | **6** | **MỚI** (tách ra) |
| 11 | Tiện ích (Lịch, Danh bạ) | 11 | 10 | Tách TB ra module riêng |
| 12 | Họp không giấy | 10 | 18 | +8 |
| 13 | Hợp đồng | 8 | 11 | +3 |
| 14 | Kho lưu trữ | 7 | 12 | +5 |
| 15 | Tài liệu chung | 9 | 10 | +1 |
| 16 | **Ký số điện tử** | — | **6** | **MỚI** |
| 17 | Quản trị hệ thống | 47 | 56 | +9 |
| 18 | Xác thực | 5 | 7 | +2 |
| | **TỔNG** | **192** | **243** | **+51** |

---

## DANH SÁCH CHỨC NĂNG MỚI SO VỚI v1.0

> Tổng cộng **51 chức năng bổ sung**, bao gồm:
> - **3 module hoàn toàn mới**: Ủy quyền (4), Ký số điện tử (6), Thông báo & Notification (6 — tách + bổ sung)
> - **Văn bản**: +9 chức năng (liên thông LGSP, phân phối, cấp số tự động)
> - **HSCV + Workflow**: +8 chức năng (ý kiến xử lý, phối hợp, liên kết VB, versioning)
> - **Họp không giấy**: +8 chức năng (biểu quyết, tài liệu, ý kiến, audio, phòng họp)
> - **Hợp đồng**: +3 (phụ lục, đối tác, phân quyền)
> - **Kho lưu trữ**: +5 (phông, hồ sơ, mục lục, chỉnh lý)
> - **Quản trị**: +9 (audit log, email history, FCM, LGSP config, ký số config, convert, QR)
> - **Xác thực**: +2 (SSO, API authorization)
