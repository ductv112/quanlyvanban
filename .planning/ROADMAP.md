# Roadmap: e-Office — Quản lý Văn bản điện tử

## Overview

Rebuild hệ thống quản lý văn bản điện tử (.NET cũ) thành stack mới (Next.js + Express + PostgreSQL). Sprint 0-4 đã implemented (hạ tầng, auth, layout, danh mục, VB đến/đi/dự thảo). Roadmap này bao phủ toàn bộ công việc còn lại từ stabilize đến tích hợp, deadline demo cuối tuần 2026-04-18/19. 7 phases theo granularity coarse — mỗi phase là một nhóm sprint có thể verify độc lập.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [x] **Phase 1: Stabilize Sprint 0-4** - Fix visible bugs, refactor shared patterns, đảm bảo golden path chạy mượt (completed 2026-04-14)
- [x] **Phase 2: Hồ sơ công việc** - Module HSCV hoàn chỉnh: danh sách, CRUD, workflow, báo cáo (completed 2026-04-14)
- [x] **Phase 3: Liên thông & Tin nhắn** - Văn bản liên thông, giao việc từ VB, tin nhắn nội bộ & thông báo realtime (completed 2026-04-14)
- [x] **Phase 4: Lịch, Danh bạ & Dashboard** - Lịch 3 loại, danh bạ, dashboard hoàn thiện với widget thật (completed 2026-04-14)
- [ ] **Phase 5: Kho lưu trữ, Tài liệu & Họp** - Kho/Phông, tài liệu/hợp đồng, họp không giấy
- [ ] **Phase 6: Tích hợp hệ thống ngoài** - LGSP liên thông, ký số điện tử, thông báo đa kênh
- [ ] **Phase 7: Polish & Redirect** - Sidebar dynamic, responsive, skeleton, redirect trang đối tác

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
**Goal**: Hệ thống kết nối được với LGSP (liên thông văn bản), ký số điện tử (SmartCA/NEAC), và gửi thông báo đa kênh (FCM/Zalo/SMS/Email)
**Depends on**: Phase 5
**Requirements**: LGSP-01, LGSP-02, LGSP-03, LGSP-04, SIGN-01, SIGN-02, SIGN-03, NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04
**Success Criteria** (what must be TRUE):
  1. Worker polling nhận được VB liên thông từ LGSP (edXML → VB đến) và đồng bộ danh sách cơ quan
  2. Người dùng gửi VB đi liên thông qua LGSP và xem tracking trạng thái
  3. Người dùng ký số VB qua VNPT SmartCA hoặc EsignNEAC với preview PDF và trạng thái đã ký
  4. Worker gửi thông báo qua ít nhất 2 trong 4 kênh (FCM, Zalo OA, SMS, Email) hoạt động đúng
**Plans**: 5 plans
Plans:
- [ ] 06-01-PLAN.md — Database: 3 migrations (Sprint 14 LGSP, Sprint 15 signing, Sprint 16 notifications)
- [ ] 06-02-PLAN.md — Backend: LGSP service interface + mock + repository + routes + Redis token cache
- [ ] 06-03-PLAN.md — Backend: Signing service mock + notification channel mocks + BullMQ workers + repositories + routes
- [ ] 06-04-PLAN.md — Frontend: LGSP pages + signing modal + notification preferences + sidebar update + checkpoint
- [ ] 06-05-PLAN.md — Seed data: comprehensive seed_full_demo.sql covering all modules Sprint 0-16
**UI hint**: yes

### Phase 7: Polish & Redirect
**Goal**: Hệ thống đạt chất lượng demo — sidebar dynamic, responsive trên mobile, UX smooth, redirect đúng trang đối tác
**Depends on**: Phase 6
**Requirements**: UI-01, UI-02, UI-03, UI-04
**Success Criteria** (what must be TRUE):
  1. Menu redirect đúng trang đối tác (VNPT/Viettel Invoice, Contract, BHXH, Tax)
  2. Sidebar menu load từ API quyền và badge counts cập nhật realtime
  3. Giao diện responsive trên mobile với hamburger menu và tables touch-friendly
  4. Skeleton loading, empty states, error boundaries, và toast notification hoạt động nhất quán trên toàn app
**Plans**: TBD
**UI hint**: yes

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Stabilize Sprint 0-4 | 3/3 | Complete    | 2026-04-14 |
| 2. Hồ sơ công việc | 8/8 | Complete    | 2026-04-14 |
| 3. Liên thông & Tin nhắn | 5/5 | Complete    | 2026-04-14 |
| 4. Lịch, Danh bạ & Dashboard | 4/4 | Complete    | 2026-04-14 |
| 5. Kho lưu trữ, Tài liệu & Họp | 0/6 | Not started | - |
| 6. Tích hợp hệ thống ngoài | 0/5 | Not started | - |
| 7. Polish & Redirect | 0/TBD | Not started | - |
