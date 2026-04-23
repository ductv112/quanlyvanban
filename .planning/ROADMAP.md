# Roadmap: e-Office — Quản lý Văn bản điện tử

> **Xem thêm:** Chi tiết 17 sprints (SP, API, UI) tại `e_office_app_new/ROADMAP.md`

## Overview

Rebuild hệ thống quản lý văn bản điện tử (.NET cũ) thành stack mới (Next.js + Express + PostgreSQL).

- **v1.0 (Shipped 2026-04-18):** 7 phases — stabilize Sprint 0-4, HSCV, liên thông, lịch/danh bạ/dashboard, kho lưu trữ/tài liệu/họp, tích hợp ngoài (LGSP + ký số MOCK + trục CP mock), polish & redirect. 26 plans executed, 97.8% HDSD coverage (92 test cases).
- **v2.0 (In progress 2026-04-21):** 7 phases (Phase 8-14) — Tích hợp ký số 2 kênh thật (SmartCA VNPT + MySign Viettel), menu Ký số riêng, async worker BullMQ, migration schema multi-provider, Root CA UX, deployment. 42 REQ-IDs across 6 categories (SIGN / CFG / UX / ASYNC / MIG / DEP).

## Phases

**Phase Numbering:**
- Integer phases (1-14): Planned milestone work (v1.0: 1-7, v2.0: 8-14)
- Decimal phases (e.g. 2.1, 8.1): Urgent insertions (marked with INSERTED)

### v1.0 (Shipped)

- [x] **Phase 1: Stabilize Sprint 0-4** - Fix visible bugs, refactor shared patterns, đảm bảo golden path chạy mượt (completed 2026-04-14)
- [x] **Phase 2: Hồ sơ công việc** - Module HSCV hoàn chỉnh: danh sách, CRUD, workflow, báo cáo (completed 2026-04-14)
- [x] **Phase 3: Liên thông & Tin nhắn** - Văn bản liên thông, giao việc từ VB, tin nhắn nội bộ & thông báo realtime (completed 2026-04-14)
- [x] **Phase 4: Lịch, Danh bạ & Dashboard** - Lịch 3 loại, danh bạ, dashboard hoàn thiện với widget thật (completed 2026-04-14)
- [x] **Phase 5: Kho lưu trữ, Tài liệu & Họp** - Kho/Phông, tài liệu/hợp đồng, họp không giấy (completed 2026-04-16)
- [x] **Phase 6: Tích hợp hệ thống ngoài** - LGSP liên thông, ký số MOCK, thông báo đa kênh, trục CP mock (completed 2026-04-18)
- [x] **Phase 7: Polish & Redirect** - HDSD compliance 97.8%, sidebar dynamic, redirect trang đối tác (completed 2026-04-18)

### v2.0 (Active — Milestone: Tích hợp ký số 2 kênh)

- [x] **Phase 8: Schema foundation + PDF signing generic layer** - 3 bảng mới, migration `staff.sign_phone`, PDF signing pure JS (`node-signpdf` + `node-forge`) (completed 2026-04-21)
- [x] **Phase 9: Admin config + provider adapters** - SmartCA VNPT + MySign Viettel adapters, trang Admin cấu hình hệ thống với test connection, dashboard stats (completed 2026-04-21)
- [x] **Phase 10: User config page + migrate tab chữ ký số** - Trang `/ky-so/tai-khoan` với form dynamic theo provider + button verify, remove tab cũ trong `/thong-tin-ca-nhan` (completed 2026-04-21)
- [x] **Phase 11: Sign flow + async worker (core)** - API `/ky-so/sign` real, BullMQ worker poll 5s × 3 phút, Socket.IO `SIGN_COMPLETED`, ký lại/hủy transaction (completed 2026-04-21)
- [x] **Phase 12: Menu Ký số + Danh sách 4 tab UI** - Sidebar menu mới, trang `/ky-so/danh-sach` 4 tab dynamic (Cần ký / Đang xử lý / Đã ký / Thất bại), re-wire detail VB pages (completed 2026-04-22)
- [x] **Phase 13: Modal ký số robust + Root CA UX** - Modal countdown 3:00, disable spam, maskClosable=false, banner Root CA Viettel dismissible + link `.cer` + HDSD PDF (completed 2026-04-23)
- [x] **Phase 14: Deployment + HDSD triển khai + verification** - Deploy scripts seed provider config disabled, copy Root CA static files, HDSD cho IT triển khai, UAT cuối (completed 2026-04-23)

## Phase Details

### Phase 1: Stabilize Sprint 0-4
**Goal**: Sprint 0-4 chạy ổn định end-to-end — không có lỗi visible, code shared được tái sử dụng đúng cách
**Depends on**: Nothing (brownfield — Sprint 0-4 đã build)
**Requirements**: STAB-01, STAB-02, STAB-03
**Success Criteria** (what must be TRUE):
  1. Người dùng có thể thực hiện toàn bộ luồng VB đến → xử lý → VB đi mà không gặp lỗi UI
  2. Tree đơn vị/phòng ban render đúng ở tất cả 6 trang admin không có duplicate hoặc sai mapping
  3. Validation lỗi hiển thị inline trên Drawer (không bị mất sau submit)
  4. handleDbError và API response format nhất quán trên toàn backend
**Plans**: 3 plans
Plans:
- [x] 01-01-PLAN.md — Frontend tree utilities: tạo shared lib/tree-utils.ts + types/tree.ts, cập nhật 4 trang admin
- [x] 01-02-PLAN.md — Backend error handler: tạo shared lib/error-handler.ts, cập nhật 5 route files
- [x] 01-03-PLAN.md — Golden path & bug fixes: fix backslash paths, kiểm tra Vietnamese text, checkpoint xác nhận

### Phase 2: Hồ sơ công việc
**Goal**: Người dùng có thể quản lý toàn bộ vòng đời hồ sơ công việc — tạo, phân công, xử lý, chuyển trạng thái, và xem báo cáo
**Depends on**: Phase 1
**Requirements**: HSCV-01, HSCV-02, HSCV-03, HSCV-04, HSCV-05, HSCV-06, HSCV-07, HSCV-08, HSCV-09, HSCV-10
**Success Criteria** (what must be TRUE):
  1. Người dùng xem danh sách HSCV với filter 10 trạng thái và badge count hiển thị đúng số lượng
  2. Người dùng tạo/sửa/xóa HSCV qua Drawer và chi tiết hiển thị đầy đủ 6 tab
  3. Người dùng phân công cán bộ qua Transfer panel và chuyển trạng thái HSCV (trình ký → duyệt → hoàn thành)
  4. Admin thiết kế quy trình workflow bằng flowchart kéo thả
  5. Người dùng xem KPI dashboard và xuất được 3 báo cáo thống kê ra Excel
**Plans**: 8 plans
Plans:
- [x] 02-01-PLAN.md — Database: Sprint 5+6 stored procedures + workflow tables
- [x] 02-02-PLAN.md — Backend: HSCV core repository + routes (CRUD, assignments, opinions, doc links, status)
- [x] 02-03-PLAN.md — Backend: Workflow repository + routes, KPI + report endpoints
- [x] 02-04-PLAN.md — Frontend: HSCV list page with filter tabs + Drawer CRUD
- [x] 02-05-PLAN.md — Frontend: HSCV detail page with 6 tabs + toolbar actions
- [x] 02-06-PLAN.md — Frontend: Workflow list + ReactFlow designer page
- [x] 02-07-PLAN.md — Frontend: KPI dashboard + reports + Excel export
- [x] 02-08-PLAN.md — Seed data + human verification checkpoint
**UI hint**: yes

### Phase 3: Liên thông & Tin nhắn
**Goal**: Người dùng nhận và xử lý văn bản liên thông, giao việc nhanh từ VB đến, và giao tiếp nội bộ qua tin nhắn với thông báo realtime
**Depends on**: Phase 2
**Requirements**: VBLT-01, VBLT-02, VBLT-03, MSG-01, MSG-02, MSG-03, MSG-04
**Success Criteria** (what must be TRUE):
  1. Người dùng xem danh sách và chi tiết văn bản liên thông, thực hiện nhận bàn giao / chuyển lại / hủy duyệt
  2. Người dùng tạo HSCV nhanh từ VB đến bằng nút "Giao việc" mà không cần nhập lại thông tin
  3. Người dùng gửi/nhận tin nhắn nội bộ (inbox, sent, trash) và trả lời dạng thread
  4. Bell icon hiển thị badge count và dropdown thông báo cập nhật realtime qua Socket.IO
**Plans**: 5 plans
Plans:
- [x] 03-01-PLAN.md — Database: Sprint 7+8 migration (VB lien thong + messages + notices tables + 20 stored functions)
- [x] 03-02-PLAN.md — Backend: VB lien thong repository + routes, incoming doc action endpoints (giao viec, nhan ban giao, chuyen lai, huy duyet)
- [x] 03-03-PLAN.md — Backend: Message + notice repositories + routes, Socket.IO server setup with JWT auth
- [x] 03-04-PLAN.md — Frontend: VB lien thong list + detail pages, giao viec drawer + action buttons on VB den detail
- [x] 03-05-PLAN.md — Frontend: Tin nhan 3-panel mail, thong bao page, bell dropdown, Socket.IO client, sidebar nav updates
**UI hint**: yes

### Phase 4: Lịch, Danh bạ & Dashboard
**Goal**: Người dùng có lịch làm việc cá nhân và cơ quan, tra cứu danh bạ, và dashboard hiển thị dữ liệu thật với widget tùy chỉnh
**Depends on**: Phase 3
**Requirements**: CAL-01, CAL-02, CAL-03, CAL-04, DASH-01, DASH-02, DASH-03
**Success Criteria** (what must be TRUE):
  1. Người dùng tạo/sửa/xóa sự kiện lịch cá nhân trên calendar view
  2. Admin quản lý lịch cơ quan và lịch lãnh đạo với phân quyền xem
  3. Người dùng tra cứu danh bạ điện thoại với filter đơn vị/phòng ban
  4. Dashboard hiển thị 4 KPI card với dữ liệu thật và widget kéo thả được sắp xếp lại
**Plans**: 4 plans
Plans:
- [x] 04-01-PLAN.md — Database: Sprint 9+10 migration (calendar_events table + calendar SPs + dashboard stats SPs)
- [x] 04-02-PLAN.md — Backend: Calendar + Directory + Dashboard repositories and routes, server.ts mount
- [x] 04-03-PLAN.md — Frontend: Dashboard rewrite with real KPI cards + 3 data widgets + react-grid-layout drag-drop
- [x] 04-04-PLAN.md — Frontend: Calendar 3 pages (cá nhân/cơ quan/lãnh đạo) + Danh bạ + sidebar nav update + checkpoint
**UI hint**: yes

### Phase 5: Kho lưu trữ, Tài liệu & Họp
**Goal**: Hệ thống có kho lưu trữ hồ sơ, quản lý tài liệu/hợp đồng, và họp không giấy với biểu quyết realtime
**Depends on**: Phase 4
**Requirements**: KHO-01, KHO-02, KHO-03, DOC-01, DOC-02, HOP-01, HOP-02, HOP-03, HOP-04
**Success Criteria** (what must be TRUE):
  1. Admin quản lý danh mục Kho/Phông (tree) và người dùng quản lý hồ sơ lưu trữ với luồng mượn/trả
  2. Người dùng upload và quản lý tài liệu chung theo danh mục, quản lý hợp đồng với scan
  3. Admin quản lý phòng họp/loại cuộc họp, người dùng đăng ký cuộc họp và duyệt lịch
  4. Biểu quyết realtime hoạt động trong cuộc họp và thống kê cuộc họp hiển thị đúng chart
**Plans**: 6 plans
Plans:
- [x] 05-01-PLAN.md — Database: 3 migrations (Sprint 11 archive esto, Sprint 12 docs/contracts iso+cont, Sprint 13 meetings edoc)
- [x] 05-02-PLAN.md — Backend: Archive + Document + Contract repositories + routes + error-handler update
- [x] 05-03-PLAN.md — Backend: Meeting repository + routes + server.ts mount all Phase 5 routes
- [x] 05-04-PLAN.md — Frontend: Archive pages (kho/phong tree, ho so luu tru, muon/tra)
- [x] 05-05-PLAN.md — Frontend: Document management + Contract management pages
- [x] 05-06-PLAN.md — Frontend: Meeting pages (list, detail with voting, statistics charts) + sidebar nav + checkpoint
**UI hint**: yes

### Phase 6: Tích hợp hệ thống ngoài
**Goal**: Hệ thống kết nối được với LGSP (liên thông văn bản), ký số MOCK (OTP flow), và gửi thông báo đa kênh (FCM/Zalo/SMS/Email)
**Depends on**: Phase 5
**Requirements**: LGSP-01, LGSP-02, LGSP-03, LGSP-04, SIGN-MOCK-01, SIGN-MOCK-02, SIGN-MOCK-03, NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04
**Success Criteria** (what must be TRUE):
  1. Worker polling nhận được VB liên thông từ LGSP (edXML → VB đến) và đồng bộ danh sách cơ quan
  2. Người dùng gửi VB đi liên thông qua LGSP và xem tracking trạng thái
  3. Người dùng ký số MOCK VB qua SmartCA OTP (giả lập) với preview PDF và trạng thái đã ký
  4. Worker gửi thông báo qua ít nhất 2 trong 4 kênh (FCM, Zalo OA, SMS, Email) hoạt động đúng
**Plans**: Completed (shipped v1.0)

### Phase 7: Polish & Redirect
**Goal**: Hệ thống đạt chất lượng demo — sidebar dynamic, responsive trên mobile, UX smooth, redirect đúng trang đối tác
**Depends on**: Phase 6
**Requirements**: UI-01, UI-02, UI-03, UI-04
**Success Criteria** (what must be TRUE):
  1. Menu redirect đúng trang đối tác (VNPT/Viettel Invoice, Contract, BHXH, Tax)
  2. Sidebar menu load từ API quyền và badge counts cập nhật realtime
  3. Giao diện responsive trên mobile với hamburger menu và tables touch-friendly
  4. Skeleton loading, empty states, error boundaries, và toast notification hoạt động nhất quán trên toàn app
**Plans**: Completed (shipped v1.0)
**UI hint**: yes

---

### Phase 8: Schema foundation + PDF signing generic layer
**Goal**: Hạ tầng DB multi-provider sẵn sàng + layer ký PDF pure JS dùng chung cho cả 2 provider — downstream phases build trên nền này
**Depends on**: v1.0 shipped (Phase 7)
**Requirements**: MIG-01, MIG-02, MIG-03, MIG-04, SIGN-04
**Success Criteria** (what must be TRUE):
  1. 3 bảng mới (`signing_provider_config`, `staff_signing_config`, `sign_transactions`) tồn tại với constraints đúng (composite PK, partial unique index cho `is_active`, pgcrypto column)
  2. Bảng `attachments` có thêm 2 cột `sign_provider_code` + `sign_transaction_id` (nullable) — file ký cũ không bị break
  3. Data trong `staff.sign_phone` (nếu có user đã cấu hình v1.0) được migrate sang `staff_signing_config` với `provider_code='SMARTCA_VNPT'` không mất record nào
  4. Cột `staff.sign_phone` bị drop (hoặc mark deprecated) sau khi verify migration count khớp
  5. Hàm generic `signPdf(pdfBuffer, signatureBase64)` dùng `node-signpdf` + `node-forge` tạo PKCS7 detached chuẩn PAdES, verify được bằng Adobe Reader
**Plans**: 4 plans
Plans:
- [x] 08-01-PLAN.md — DB: schema 3 bảng mới (signing_provider_config, staff_signing_config, sign_transactions) + ALTER 4 attachment tables + 15 SPs CRUD
- [x] 08-02-PLAN.md — DB: data migration staff.sign_phone → staff_signing_config (atomic DO block) + DROP column
- [x] 08-03-PLAN.md — Backend: generic PDF signing (@signpdf/signpdf + node-forge), 3 function export (computePdfHash, signPdf, prepareSignPdf) + unit test
- [x] 08-04-PLAN.md — Backend: crypto helper (pgp_sym_encrypt) + 3 repositories (signing-provider-config, staff-signing-config, sign-transaction) gọi 15 SPs
**UI hint**: no

### Phase 9: Admin config + provider adapters
**Goal**: Admin có thể chọn 1 trong 2 provider (SmartCA VNPT / MySign Viettel), lưu credentials hệ thống (encrypted), test connection trước khi lưu, và xem dashboard stats
**Depends on**: Phase 8
**Requirements**: SIGN-01, SIGN-02, CFG-01, CFG-02, CFG-03, CFG-04, CFG-07
**Success Criteria** (what must be TRUE):
  1. Admin truy cập `/ky-so/cau-hinh` thấy form chọn provider (SmartCA VNPT hoặc MySign Viettel) với fields tương ứng (`base_url`, `client_id`, `client_secret`, + `profile_id` nếu MySign)
  2. Admin bấm "Test connection" → hệ thống thực gọi API provider (login/get_certificate) → chỉ cho lưu nếu response OK, lỗi hiển thị message rõ ràng
  3. Admin lưu config → `client_secret` được encrypt bằng `pgp_sym_encrypt` trong DB, không bao giờ trả plaintext về frontend
  4. Hệ thống enforce single active: khi Admin set provider A active, provider B tự động bị `is_active=false` (partial unique index chặn duplicate)
  5. Admin xem dashboard stats: số user đã cấu hình, số user đã verify, số giao dịch ký tháng hiện tại
**Plans**: 3 plans
Plans:
- [x] 09-01-PLAN.md — Backend: provider adapters (strategy pattern) + factory (SmartCA VNPT + MySign Viettel)
- [x] 09-02-PLAN.md — Backend: API route /api/ky-so/cau-hinh (6 endpoints) + stats SP migration 041
- [x] 09-03-PLAN.md — Frontend: Admin config page /ky-so/cau-hinh + sidebar menu Ký số + checkpoint verify
**UI hint**: yes

### Phase 10: User config page + migrate tab chữ ký số
**Goal**: Mỗi user có thể cấu hình tài khoản ký số cá nhân qua trang riêng (menu độc lập), verify config hoạt động, và tab cũ trong `/thong-tin-ca-nhan` bị remove
**Depends on**: Phase 9
**Requirements**: CFG-05, CFG-06, UX-13
**Success Criteria** (what must be TRUE):
  1. User truy cập `/ky-so/tai-khoan` thấy form dynamic theo provider active: SmartCA VNPT chỉ input `user_id`; MySign Viettel có `user_id` + button "Tải danh sách CTS" → Select `credential_id`
  2. User bấm "Kiểm tra" → hệ thống call provider fetch certificate → lưu `is_verified=true` + `last_verified_at`, hiển thị tag "Đã xác thực" trên UI
  3. Tab "Chữ ký số" cũ trong `/thong-tin-ca-nhan` bị remove; truy cập link cũ redirect sang `/ky-so/tai-khoan`
  4. Khi Admin switch provider, config cũ của user ở provider khác vẫn giữ (composite PK `staff_id + provider_code`) — user không phải nhập lại nếu quay lại provider cũ
**Plans**: 3 plans
Plans:
- [x] 10-01-PLAN.md — Backend API /api/ky-so/tai-khoan (4 endpoints: GET/POST/certificates/verify, authenticate only)
- [x] 10-02-PLAN.md — Frontend trang /ky-so/tai-khoan + sidebar submenu 'Tài khoản ký số cá nhân' cho mọi user (checkpoint)
- [x] 10-03-PLAN.md — Remove tab 'Chữ ký số' cũ trong /thong-tin-ca-nhan, thêm Alert pointer sang /ky-so/tai-khoan
**UI hint**: yes

### Phase 11: Sign flow + async worker (core)
**Goal**: Flow ký thật end-to-end hoạt động async: user click "Ký" → nhận `transaction_id` ngay → worker poll provider → user nhận kết quả qua Socket.IO / notification dù tắt browser
**Depends on**: Phase 10
**Requirements**: SIGN-03, SIGN-05, SIGN-06, SIGN-07, SIGN-08, ASYNC-01, ASYNC-02, ASYNC-03, ASYNC-04, ASYNC-05, ASYNC-06, MIG-05
**Success Criteria** (what must be TRUE):
  1. User bấm "Ký số" trên VB đi / dự thảo / HSCV trình ký → POST `/ky-so/sign` trả `{ transaction_id }` < 1 giây → worker BullMQ enqueue job
  2. Worker poll `provider.getStatus(provider_txn_id)` mỗi 5s, tối đa 36 lần (3 phút); khi ký xong: embed PKCS7 vào PDF, upload MinIO key mới, update `attachments.is_ca=true`, lưu `sign_provider_code`, emit Socket.IO `SIGN_COMPLETED`, tạo notification bell
  3. User đóng browser / tắt modal giữa chừng → worker vẫn chạy → kết quả ký vẫn lưu vào DB + MinIO; user mở lại thấy file đã ký trong tab "Đã ký"
  4. Backend restart giữa flow ký → BullMQ job persistent trong Redis → job tự resume sau backend start, không mất transaction
  5. User có thể ký lại sau fail/expire (tạo transaction MỚI, không reset record cũ) và hủy transaction pending (status → `cancelled`); tất cả 3 trang detail VB (`van-ban-di/[id]`, `van-ban-du-thao/[id]`, `ho-so-cong-viec/[id]`) đã được cập nhật từ `/ky-so/mock/sign` sang `/ky-so/sign`
**Plans**: 8 plans
Plans:
- [x] 11-01-PLAN.md — DB + Repo: migration 045 (4 SPs — finalize_sign, can_sign, list_txn, count_txn) + ALTER attachment_handling_docs + typed repository + sign-helpers
- [x] 11-02-PLAN.md — Infra: BullMQ queue 'signing' + Redis connection singleton + typed job payload + env docs (no worker yet)
- [x] 11-03-PLAN.md — Backend: POST /api/ky-so/sign + POST /:id/cancel + GET /:id — async entry point returning transaction_id < 1s
- [x] 11-04-PLAN.md — Worker: BullMQ Worker poll-sign-status — embed signature, upload MinIO signed key, emit Socket SIGN_COMPLETED/FAILED, bell notification
- [x] 11-05-PLAN.md — Backend: GET /api/ky-so/danh-sach (4 tab list) + /counts (badge) + migration 046 SP for 'Cần ký' tab
- [x] 11-06-PLAN.md — Frontend: shared SignModal component + useSigning hook + socket event extensions (functional, polish deferred to Phase 13)
- [x] 11-07-PLAN.md — Frontend: migrate VB đi + VB dự thảo detail pages (remove mock OTP) + checkpoint
- [x] 11-08-PLAN.md — Frontend: add Ký số button to HSCV detail page (first-time functionality) + checkpoint
**UI hint**: yes

### Phase 11.1: DB Consolidation & Seed Strategy (INSERTED)
**Goal**: Gộp tất cả migrations hiện tại thành 1 file schema master idempotent (DROP IF EXISTS trước CREATE để không còn lỗi SP overload cũ), viết seed data phong phú cho test, cập nhật deploy scripts để reset-db chạy 1 phát là xong. Mục tiêu: pull code ở máy mới → reset-db → test ngay không lỗi.
**Depends on**: Phase 11
**Requirements**: (urgent insertion — addresses tech debt, no new REQ-IDs)
**Success Criteria** (what must be TRUE):
  1. `database/schema/000_schema_v2.0.sql` master idempotent — DROP IF EXISTS tất cả SPs trước CREATE, có thể re-run không lỗi overload
  2. `database/seed/002_demo_data.sql` phong phú: 50+ VB đến/đi/dự thảo, 20+ HSCV, 10+ user với các phòng ban, đính kèm PDF mẫu, provider config seed sẵn
  3. `deploy/reset-db.sh` + `.ps1` chạy 1 phát xong: drop DB → recreate → run schema → run seeds → app sẵn sàng test
  4. Migrations cũ (001-046 + quick_*.sql) move vào `database/archive/` — giữ lịch sử nhưng không chạy
  5. CLAUDE.md cập nhật rules DB migration mới: edit schema master + bump version khi milestone mới, KHÔNG thêm file 047+ rời
**Plans**: 3 plans
Plans:
- [x] 11.1-01-PLAN.md — Schema consolidation: hợp nhất 18 migration files thành 1 file master idempotent (database/schema/000_schema_v2.0.sql) + archive folder skeleton
- [x] 11.1-02-PLAN.md — Seed data: tách required data (001_required_data.sql) + rich demo data (002_demo_data.sql, 150+ records)
- [ ] 11.1-03-PLAN.md — Deploy scripts (reset-db.sh/.ps1 + deploy.sh/.ps1) + move 18 migrations vào archive + CLAUDE.md DB Migration Strategy rules + human-verify checkpoint
**UI hint**: no

### Phase 12: Menu Ký số + Danh sách 4 tab UI
**Goal**: Menu "Ký số" xuất hiện ở sidebar với 3 submenu, trang `/ky-so/danh-sach` có 4 tab dynamic giúp user quản lý tập trung mọi giao dịch ký số của mình
**Depends on**: Phase 11
**Requirements**: UX-01, UX-02, UX-03, UX-04, UX-05, UX-06, UX-12
**Success Criteria** (what must be TRUE):
  1. Sidebar có menu "Ký số" (icon SafetyCertificate) với 3 submenu: "Cấu hình ký số hệ thống" (Admin only), "Tài khoản ký số cá nhân", "Danh sách ký số" — phân quyền đúng theo role
  2. Trang `/ky-so/danh-sach` hiển thị 4 tab với badge count chính xác: "Cần ký" / "Đang xử lý" / "Đã ký" / "Thất bại"
  3. Tab "Cần ký" liệt kê VB đi / dự thảo / HSCV có `signer_id = currentUser` chưa ký; button "Ký số" mở modal ký trực tiếp không cần vào trang detail
  4. Tab "Đang xử lý" có button "Hủy" gọi cancel transaction; tab "Đã ký" có button "Xem file" (download + banner Root CA nếu MySign); tab "Thất bại" có button "Ký lại" tạo transaction mới
  5. Trang chi tiết VB (`van-ban-di/[id]`, `van-ban-du-thao/[id]`, `ho-so-cong-viec/[id]`) giữ button "Ký số" trên file đính kèm — đường dẫn thứ 2 vào flow ký, mở cùng modal như tab "Cần ký"
**Plans**: 3 plans
Plans:
- [x] 12-01-PLAN.md — BE endpoint GET /api/ky-so/sign/:id/download + sidebar submenu Danh sách ký số + breadcrumb entry
- [x] 12-02-PLAN.md — FE trang /ky-so/danh-sach 4 tab (Cần ký / Đang xử lý / Đã ký / Thất bại) + realtime socket
- [x] 12-03-PLAN.md — E2E verify + seed SQL 4 test state + UAT checkpoint (không regression AC#5)
**UI hint**: yes

### Phase 13: Modal ký số robust + Root CA UX
**Goal**: Modal ký số không còn spam-click, user biết rõ còn bao nhiêu thời gian xác nhận OTP, và khi file ký bằng MySign Viettel user được hướng dẫn cài Root CA Viettel để Adobe Reader hiển thị "Signature valid"
**Depends on**: Phase 12
**Requirements**: UX-07, UX-08, UX-09, UX-10, UX-11, DEP-02
**Success Criteria** (what must be TRUE):
  1. Modal ký số có `maskClosable: false`; button "Thực hiện ký" tự động disable + hiển thị `<LoadingOutlined />` ngay khi click, không cho user spam tạo duplicate transaction
  2. Modal hiển thị countdown 3:00 → 0:00 realtime + text "Vui lòng xác nhận OTP trên ứng dụng [SmartCA/MySign] mobile"; có 2 button phân biệt "Đóng" (giữ transaction chạy ngầm) vs "Hủy ký số" (mark cancelled)
  3. Bell notification hiện toast + badge khi Socket event `SIGN_COMPLETED` / `SIGN_FAILED` đến; user offline lúc nhận cũng thấy notification trong dropdown bell khi đăng nhập lại
  4. Khi user download file ký bằng MySign Viettel, banner dismissible xuất hiện với link tải Root CA `.cer` + HDSD PDF; localStorage lưu `dismiss_root_ca_banner=true` để không hiện lại
  5. File Root CA Viettel `.cer` + HDSD cài Root CA PDF được copy vào `frontend/public/root-ca/` sẵn sàng tải về từ URL tĩnh (không cần API call)
**Plans**: 5 plans
Plans:
- [ ] 13-01-PLAN.md — BE notification infrastructure (table notifications + 5 SPs + repository + routes + worker extend persist trước emit)
- [ ] 13-02-PLAN.md — FE bell component (api-notifications lib + BellNotification + MainLayout swap from /api/thong-bao → /api/notifications + toast)
- [ ] 13-03-PLAN.md — SignModal polish (countdown circular 3:00 + color states + expired transition + caller disable spam + verify 2 button)
- [ ] 13-04-PLAN.md — Root CA (copy .cer + PDF vào public/root-ca/ + RootCABanner component + integration danh-sach page download trigger)
- [ ] 13-05-PLAN.md — E2E + UAT checkpoint (seed test notifications + verification report + 7 UAT cases human-verify)
**UI hint**: yes

### Phase 14: Deployment + HDSD triển khai + verification
**Goal**: Hệ thống sẵn sàng deploy cho KH trên Windows Server + IIS — deploy scripts seed config mặc định disabled + dev workflow documented + REQUIREMENTS.md audit 41 REQ v2.0 với verify evidence. Cleanup Linux scripts không còn support.
**Depends on**: Phase 13
**Requirements**: DEP-01
**Success Criteria** (what must be TRUE):
  1. Deploy scripts (`deploy/*.ps1` — Windows-only; 4 file `.sh` Linux đã xóa khỏi repo) seed `signing_provider_config` 2 rows (SmartCA + MySign) với `is_active=false` và empty credentials — Admin bắt buộc phải config sau deploy trước khi user ký
  2. `deploy/README.md` rewrite Windows-only + thêm section "Development setup sau reset-db" hướng dẫn admin login → menu Ký số → nhập credentials từ `.env.dev-creds` → test connection → lưu
  3. Checklist acceptance **41 REQ-IDs v2.0** (DEP-03 defer sang v2.1) được tick đủ với column `Verify Evidence` concrete (grep/psql/test commands); không có blocker Pass/Deferred cho production deploy
**Plans**: 3 plans
Plans:
- [x] 14-01-cleanup-linux-rewrite-readme-PLAN.md — Xóa 4 file Linux shell scripts + rewrite deploy/README.md Windows-only
- [x] 14-02-seed-fix-dev-workflow-PLAN.md — Fix seed 001_required_data.sql (cả 2 provider disabled + empty creds) + thêm section Development setup vào README
- [x] 14-03-requirements-roadmap-audit-PLAN.md — Update REQUIREMENTS.md (41 REQ + 2 column Verify Evidence/Status, remove DEP-03) + đồng bộ ROADMAP.md Phase 14 section
**UI hint**: no

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8 → 9 → 10 → 11 → 12 → 13 → 14

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Stabilize Sprint 0-4 | 3/3 | Complete | 2026-04-14 |
| 2. Hồ sơ công việc | 8/8 | Complete | 2026-04-14 |
| 3. Liên thông & Tin nhắn | 5/5 | Complete | 2026-04-14 |
| 4. Lịch, Danh bạ & Dashboard | 4/4 | Complete | 2026-04-14 |
| 5. Kho lưu trữ, Tài liệu & Họp | 6/6 | Complete | 2026-04-16 |
| 6. Tích hợp hệ thống ngoài | -/- | Complete | 2026-04-18 |
| 7. Polish & Redirect | -/- | Complete | 2026-04-18 |
| 8. Schema foundation + PDF signing layer | 4/4 | Complete    | 2026-04-21 |
| 9. Admin config + provider adapters | 3/3 | Complete    | 2026-04-21 |
| 10. User config page | 3/3 | Complete   | 2026-04-21 |
| 11. Sign flow + async worker | 8/8 | Complete    | 2026-04-21 |
| 11.1. DB Consolidation & Seed Strategy | 2/3 | Complete    | 2026-04-22 |
| 12. Menu Ký số + Danh sách UI | 3/3 | Complete    | 2026-04-22 |
| 13. Modal ký số + Root CA UX | 5/5 | Complete    | 2026-04-23 |
| 14. Deployment + HDSD + verification | 3/3 | Complete   | 2026-04-23 |
