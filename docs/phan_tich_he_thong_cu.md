# PHÂN TÍCH TOÀN DIỆN HỆ THỐNG CŨ
> Ngày phân tích: 2026-04-13 | Source: AngularJS + ASP.NET MVC 5 + SQL Server

---

## I. CẬP NHẬT FUNCTION LIST — CÁC CHỨC NĂNG BỊ THIẾU

Sau khi phân tích source code, phát hiện **26 chức năng** chưa có trong function list v1.0:

### A. Module CHƯA CÓ trong function list

#### Module: Ủy quyền (Delegation)
| Mã | Chức năng | Mô tả |
|----|-----------|-------|
| UQ-01 | Xem danh sách ủy quyền | Danh sách ủy quyền xử lý VB/HSCV |
| UQ-02 | Tạo ủy quyền | Ủy quyền cho cán bộ khác xử lý VB/HSCV trong khoảng thời gian |
| UQ-03 | Thu hồi ủy quyền | Hủy ủy quyền trước hạn |

#### Module: Biểu quyết (Vote - trong Họp không giấy)
| Mã | Chức năng | Mô tả |
|----|-----------|-------|
| HP-11 | Bắt đầu biểu quyết | Real-time vote trong phòng họp (Socket.IO) |
| HP-12 | Bỏ phiếu | Người tham gia chọn phương án |
| HP-13 | Kết thúc + xem kết quả | Thống kê kết quả biểu quyết |
| HP-14 | Upload tài liệu cuộc họp | Đính kèm file vào lịch họp |
| HP-15 | Ý kiến cuộc họp | Nhập ý kiến thảo luận trong phòng họp |
| HP-16 | Upload audio | Tải file ghi âm cuộc họp |

#### Module: Ký số điện tử (Digital Signature)
| Mã | Chức năng | Mô tả |
|----|-----------|-------|
| KS-01 | Ký số VNPT SmartCA | Ký số từ xa qua VNPT gateway |
| KS-02 | Ký số NEAC (ESign) | Ký số qua nền tảng NEAC (đa CA: MISA, Bkav, VNPT, Viettel, FPT) |
| KS-03 | Ký số USB Token | Ký số bằng USB token vật lý |
| KS-04 | Xác minh chữ ký | Kiểm tra tính hợp lệ của chữ ký số trên VB |

#### Module: Liên thông văn bản (LGSP)
| Mã | Chức năng | Mô tả |
|----|-----------|-------|
| LT-01 | Gửi văn bản liên thông | Gửi VB đi sang đơn vị ngoài qua trục LGSP (edXML format) |
| LT-02 | Nhận văn bản liên thông | Tự động nhận VB đến từ trục LGSP |
| LT-03 | Cập nhật trạng thái liên thông | Đồng bộ trạng thái xử lý giữa các đơn vị |
| LT-04 | Quản lý tổ chức liên thông | CRUD danh sách đơn vị tham gia liên thông |

### B. Chức năng BỊ THIẾU trong module đã có

| Mã | Chức năng | Thuộc module | Mô tả |
|----|-----------|-------------|-------|
| VBD-22 | Bút phê lãnh đạo (LeaderNote) | Văn bản đến | Lãnh đạo ghi chú/bút phê trực tiếp lên VB |
| HSV-26 | Ý kiến xử lý (OpinionHandlingDoc) | HSCV | Cán bộ gửi ý kiến trao đổi trong HSCV |
| HSV-27 | Phối hợp xử lý | HSCV | Mời cán bộ khác phối hợp giải quyết (Prim/Coordinator) |
| DAS-07 | Dashboard đơn vị | Dashboard | Tổng quan theo đơn vị (khác Dashboard cá nhân) |
| TN-07 | File đính kèm tin nhắn | Tin nhắn | Đính kèm file trong tin nhắn nội bộ |
| AUTH-06 | SSO / OpenID Connect | Xác thực | Đăng nhập SSO qua OAuth2 Authorization Code |
| QT-CN-06 | Nhật ký thay đổi (Audit Log) | Quản trị | Ghi log mọi thao tác thay đổi dữ liệu |
| QT-VB-10 | Convert DOCX → PDF | Danh mục VB | Chuyển đổi file văn bản sang PDF (LibreOffice) |
| QT-VB-11 | Tạo mã vạch / QR Code | Danh mục VB | Sinh barcode/QR cho VB và hồ sơ |

---

## II. CÔNG NGHỆ ĐẶC BIỆT TRONG DỰ ÁN CŨ

### A. Công nghệ CÓ THỂ tái sử dụng / cần giữ lại

| Công nghệ | Vai trò | Áp dụng cho dự án mới? |
|-----------|---------|----------------------|
| **edXML format** | Chuẩn quốc gia liên thông VB điện tử | **BẮT BUỘC** — Phải implement lại bằng Node.js/TypeScript |
| **LGSP API (Lạng Sơn)** | REST API kết nối trục liên thông | **BẮT BUỘC** — Cùng endpoint, cần viết service client mới |
| **VNPT SmartCA** | Ký số từ xa | **GIỮ** — Tích hợp qua REST API, dễ implement lại |
| **EsignNEAC** | Ký số đa CA | **GIỮ** — REST API, viết lại client bằng TypeScript |
| **Firebase FCM** | Push notification mobile | **GIỮ** — Dùng Firebase Admin SDK for Node.js |
| **Zalo OA API** | Gửi thông báo Zalo | **GIỮ** — REST API, implement lại dễ dàng |
| **Socket.IO** | Biểu quyết + thông báo real-time | **GIỮ** — Next.js hỗ trợ Socket.IO tốt |
| **Barcode/QR Code** | Mã định danh VB/hồ sơ | **GIỮ** — Dùng thư viện JS: qrcode, jsbarcode |
| **SMS Gateway** | Gửi SMS thông báo | **TÙY CHỌN** — Nếu vẫn cần SMS |
| **Workflow Engine** | Quy trình phê duyệt visual | **VIẾT LẠI** — Linked-list flowchart, cần redesign DB + UI |

### B. Công nghệ KHÔNG cần / KHÔNG nên tái sử dụng

| Công nghệ | Lý do bỏ |
|-----------|----------|
| **ADO.NET + Stored Procedures** | Thay bằng Prisma ORM + PostgreSQL |
| **ASP.NET MVC 5 + Autofac DI** | Thay bằng Next.js API Routes |
| **COM Interop Word** | Thay bằng LibreOffice headless hoặc thư viện JS |
| **iTextSharp/iText7 (.NET)** | Thay bằng pdf-lib (JS) hoặc Puppeteer |
| **EPPlus (.NET)** | Thay bằng exceljs hoặc SheetJS |
| **GoJS (flowchart)** | Thay bằng React Flow hoặc tương đương |
| **FancyTree (tree view)** | Ant Design Tree component |
| **CKEditor + CKFinder** | Thay bằng TipTap hoặc Ant Design editor |
| **Windows Services** | Thay bằng Background Jobs (Bull + Redis) hoặc Cron |
| **HtmlToOpenXml** | Thay bằng docx (npm) |

### C. Kiến trúc đáng chú ý

1. **Workflow Engine tự viết**: Dạng linked-list flowchart (nodes + links), lưu vị trí top/left cho visual designer. Mỗi step có: StaffPrim (người chính), StaffCoordinator (phối hợp), TotalDate (deadline). Cần thiết kế lại cho Next.js.

2. **Dynamic Properties**: DocColumn cho phép admin tùy chỉnh trường dữ liệu VB (bật/tắt, bắt buộc, loại input). Rất hữu ích — nên giữ.

3. **Multi-result-set Stored Procedures**: 1 query trả về 2-7 bảng dữ liệu cùng lúc. Khi chuyển sang PostgreSQL + Prisma, cần tách thành nhiều query hoặc dùng PostgreSQL functions.

4. **SSO (OpenID Connect)**: Hệ thống hỗ trợ SSO nhưng đang tắt (flag = 0). Nên thiết kế sẵn cho dự án mới.

---

## III. ĐỀ XUẤT TỐI ƯU CHO DỰ ÁN MỚI

### A. KHÔNG chỉ "làm giống hệt" — cần cải thiện

#### 1. Kiến trúc & Công nghệ
| Vấn đề hệ thống cũ | Đề xuất hệ thống mới |
|---------------------|----------------------|
| Stored Procedures chứa toàn bộ logic → khó maintain, debug | **Prisma ORM** + business logic ở service layer (TypeScript) |
| ADO.NET + Reflection mapping → chậm, dễ lỗi | **Prisma** với type-safe queries, auto migration |
| Không có async/await (trừ LGSP) → blocking I/O | **Async/Await mặc định** — Node.js event loop |
| Không có Unit of Work / Transaction | **Prisma $transaction** cho multi-table operations |
| Credentials hard-coded trong config XML | **Environment variables** (.env) + Vault/secrets manager |
| File lưu trên disk server (C:\Temp\) | **MinIO** — Object storage, scalable, S3 compatible |
| Log ghi vào DB + file text | **MongoDB** cho log (theo yêu cầu) + structured logging |
| Không có cache | **Redis** cache cho danh mục, session, frequently accessed data |
| 6 Windows Services chạy riêng | **Bull/BullMQ + Redis** — Job queue chạy trong Node.js process |

#### 2. UI/UX
| Vấn đề cũ | Đề xuất mới |
|-----------|-------------|
| AngularJS SPA cũ, UI kiểu 2015 | **Next.js** + Ant Design 5 (customized) — modern, responsive |
| GoJS flowchart — nặng, khó customize | **React Flow** — lightweight, React-native, free for commercial |
| FancyTree — jQuery plugin | **Ant Design Tree** — native React |
| CKEditor — jQuery-based | **TipTap** hoặc **Ant Design RichText** |
| Dashboard cố định | **Dashboard widget configurable** (drag & drop) — dùng react-grid-layout |
| Không responsive mobile | **Responsive first** + có thể Progressive Web App |

#### 3. Business Logic cần cải thiện
| Vấn đề cũ | Đề xuất mới |
|-----------|-------------|
| Workflow chỉ linked-list đơn giản | **Workflow engine** hỗ trợ: parallel branches, conditional routing, auto-escalation |
| Notification chỉ qua SMS/Email | Thêm: **In-app notification**, **WebSocket real-time**, Zalo, push |
| Không có full-text search VB | **PostgreSQL full-text search** hoặc tích hợp **Elasticsearch** |
| Không có version control cho VB | **Document versioning** — lưu lịch sử mọi thay đổi |
| Không có OCR | Tùy chọn: **OCR** cho VB scan (Tesseract.js) — tìm kiếm trong file ảnh/PDF |
| Không track ai đọc VB khi nào | **Read tracking** chi tiết (ai đọc, lúc nào, bao lâu) |
| Báo cáo static, xuất Excel | **Dashboard analytics** real-time + export Excel/PDF |

#### 4. Bảo mật
| Vấn đề cũ | Đề xuất mới |
|-----------|-------------|
| MD5 hash password | **bcrypt** hoặc **argon2** |
| Cookie-based auth | **JWT** (access + refresh token) + **HttpOnly cookie** |
| Không rate limiting | **Rate limiting** trên API |
| Không có RBAC rõ ràng | **RBAC** (Role-Based Access Control) + **ABAC** khi cần |
| SQL Injection risk (raw SQL) | **Prisma** parameterized queries — an toàn mặc định |

### B. Giữ nguyên từ hệ thống cũ

- ✅ Cấu trúc tổ chức: Đơn vị → Phòng ban → Cán bộ (tree)
- ✅ 3 loại văn bản: Đến / Đi / Dự thảo + Sổ văn bản riêng
- ✅ Dynamic DocColumn (thuộc tính VB tùy chỉnh)
- ✅ Workflow visual designer cho quy trình
- ✅ Tích hợp LGSP / edXML
- ✅ Ký số điện tử (SmartCA, NEAC)
- ✅ Hệ thống nhóm quyền + phân quyền chức năng
- ✅ Module Họp không giấy + biểu quyết
- ✅ Module Kho lưu trữ
- ✅ Module Hợp đồng

---

## IV. QUY MÔ DỰ ÁN

### Hệ thống cũ (tham khảo)
- ~200+ entity classes (models)
- ~130+ service classes
- ~70+ request/response DTOs
- ~300+ stored procedures
- ~40 controllers (API) + ~30 controllers (Views)
- 9 Areas (sub-apps)
- 6 Windows Services
- 1 Node.js app (Socket.IO)

### Ước tính hệ thống mới (Next.js)
- ~80-100 database tables (PostgreSQL)
- ~60-80 API routes
- ~40-50 pages/layouts
- ~20-30 reusable components
- ~10-15 background job types (Bull/Redis)
- Dashboard widget system
