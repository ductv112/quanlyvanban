# Phase 32 Audit Report — HDSD vs Current Code

**Audit date:** 2026-05-11
**Scope:** 22 HDSD files in `docs/hdsd/` (20 module + `HDSD_index.md` + `HDSD_full.md`)
**Reference baseline:** Phase 21 LGSP foundation + Phase 31 fix-gom UI (commit `1c1c414` và parents `fba2764`, `2248d5e`, `202f874`, `bb824f6`, `d30cdd2`)
**Code source-of-truth:** `e_office_app_new/backend/src/routes/*.ts`, `e_office_app_new/database/schema/000_schema_v3.0.sql`, `e_office_app_new/frontend/src/{app,components,config}`

## Summary

- Total files audited: 22 (20 module + 1 index + 1 merged-full)
- Critical GAPs: 3 (`van_ban_den` 3.6, `van_ban_di` 3.7 và 3.8) — đã enumerate dưới.
- Files needing text changes: 8 (van_ban_den, van_ban_di, ho_so_cong_viec, dang_nhap_va_thong_tin_ca_nhan, thong_bao, ho_so_cong_viec_minor, index, full)
- Files needing screenshot retake: 6 (`van_ban_den_06_drawer_giao_viec`, `van_ban_di_07_modal_send_internal`, `van_ban_di_08_drawer_giao_viec`, `van_ban_di_05_detail`, `van_ban_den_04_detail`, `dashboard_01_main`)
- Files clean (no change needed): 14 module + 0 index files (HDSD_index sẽ cần re-verify TOC sau update; HDSD_full re-merge bắt buộc)

## Critical GAPs

### GAP 1 — HDSD_van_ban_den.md mục 3.6 (Drawer giao việc)

- **File:** `docs/hdsd/HDSD_van_ban_den.md`
- **Current state:** Mục 3.6 (lines 264-296) hiện chỉ tả Drawer form + bảng "Thông báo của hệ thống" kết thúc ở line 296. KHÔNG có mô tả nghiệp vụ "VB hiện ra ở đâu của TK được giao".
- **Missing:** Subsection `#### Sau khi giao việc — văn bản xuất hiện ở đâu của TK được giao?` mô tả: (a) chuông bell `task_assigned` của TK được chọn làm Người phụ trách, (b) HSCV mới xuất hiện ở trang `/ho-so-cong-viec`, tab "Mới tạo" (status=0), (c) văn bản đến vẫn ở trang VB đến cũ của người tiếp nhận ban đầu.
- **Code evidence:**
  - `e_office_app_new/backend/src/routes/incoming-doc.ts` lines 909-973 — POST `/:id/giao-viec` có khối `notifyBell({...type: 'task_assigned'...})` line 956-964.
  - `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/page.tsx` lines 28 + 43 — `tabs[0] = { key: 'new', label: 'Mới tạo' }` với `status=0`.
- **Source of truth for new text:** `32-CONTEXT.md` `<specifics>` block 1, lines 188-206 (đã chuẩn hoá full Vietnamese diacritics).
- **Insertion point:** Sau line 296 (sau bảng "Thông báo của hệ thống" của 3.6), trước line 298 `### 3.7. Modal chuyển lại văn bản`.

### GAP 2 — HDSD_van_ban_di.md mục 3.8 (Drawer giao việc VB đi)

- **File:** `docs/hdsd/HDSD_van_ban_di.md`
- **Current state:** Mục 3.8 (lines 311-342) hiện chỉ tả form fields (4/5 fields đánh "Không bắt buộc" — line 331-334) + bảng "Thông báo của hệ thống" kết thúc ở line 342. KHÔNG có note về gap chuông bell, KHÔNG có note về validation thiếu.
- **Missing 1:** Note nghiệp vụ rõ KHÔNG có chuông bell cho TK được giao (gap code chưa fix — đã track v3.2+ backlog trong CONTEXT.md `<deferred>`), KHÔNG validate `Người phụ trách` rỗng + `Hạn hoàn thành` rỗng.
- **Missing 2:** Subsection `#### Sau khi giao việc — văn bản xuất hiện ở đâu?` (giống GAP 1 nhưng KHÔNG có chuông bell mention, chỉ HSCV tab "Mới tạo").
- **Code evidence:**
  - `e_office_app_new/backend/src/routes/outgoing-doc.ts` lines 899-926 — POST `/:id/giao-viec` (VB đi) KHÔNG có `notifyBell()` call (xác nhận bằng grep `notifyBell|task_assigned` trong file = 0 match).
  - Route line 906-908: `const { name, start_date, end_date, curator_ids, note } = req.body;` — chỉ validate `name?.trim()` (line 908-911), KHÔNG validate `end_date` (so sánh với route VB đến lines 927-934 vốn yêu cầu `end_date`).
  - `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx` lines 209-217 — `handleGiaoViec()` gọi `api.post('/van-ban-di/${docId}/giao-viec', ...)` không có pre-validate `curator_ids` non-empty hoặc `end_date` non-null trong code form rules.
- **Note text required (insert after current bảng "Thông báo của hệ thống" line 342):**

  > **Lưu ý:** hiện tại VB đi giao việc CHƯA có chuông thông báo cho người được giao (gap code chưa fix — sẽ bổ sung ở phiên bản sau v3.2+). Form cũng KHÔNG validate `Người phụ trách` rỗng + `Hạn hoàn thành` rỗng — đề nghị nhập đủ trước khi bấm Tạo. Sau khi giao việc thành công, HSCV mới xuất hiện ở trang **Hồ sơ công việc** (menu trái), tab **Mới tạo** của người được chọn làm Người phụ trách (status mặc định khi tạo HSCV). Văn bản đi nguồn vẫn nằm ở trang VB đi của người soạn / văn thư cũ — KHÔNG bị chuyển đi.

- **Insertion point:** Sau line 342 (cuối mục 3.8), trước line 344 `### 3.9. Modal thêm văn bản vào hồ sơ công việc`.

### GAP 3 — HDSD_van_ban_di.md mục 3.7 (Modal Ban hành & Gửi)

- **File:** `docs/hdsd/HDSD_van_ban_di.md`
- **Current state:** Mục 3.7 (lines 282-309) mô tả Modal UI + 3 thông báo (lines 305-309 — "Chưa chọn đơn vị / Gửi thành công / Ban hành & Gửi thành công"). KHÔNG có mô tả luồng kỹ thuật 3 bước nội bộ.
- **Missing:** Subsection `#### Luồng kỹ thuật khi Gửi (3 bước nối tiếp)` mô tả: (Bước 1) Lưu recipients → `outgoing_doc_recipients` status `pending`; (Bước 2) Ban hành cấp số `is_released=TRUE`; (Bước 3) Gửi loop — Internal sinh `incoming_docs` của đơn vị nhận status "Chưa duyệt", External LGSP tạo `lgsp_tracking` status `pending` + queue worker BullMQ `lgsp-send` + badge UI "Đang chờ worker đẩy LGSP" → khi worker xong đổi badge "Đã gửi LGSP"/"Lỗi gửi LGSP".
- **Code evidence:**
  - `e_office_app_new/backend/src/routes/outgoing-doc.ts` lines 672-693 (POST `/:id/noi-nhan` — Bước 1) + lines 651-668 (PATCH `/:id/ban-hanh` — Bước 2) + lines 696-719 (POST `/:id/gui-noi-bo` — Bước 3 trigger SP).
  - `e_office_app_new/database/schema/000_schema_v3.0.sql` lines 27846-27948 — SP `edoc.fn_outgoing_doc_send_to_recipients` loop FOR `v_recipient IN ... WHERE sent_status = 'pending'`:
    - `recipient_type = 'internal_unit'` → INSERT vào `edoc.incoming_docs` (lines 27893-27914) với `source_type='internal'`, `unit_id=recipient_unit_id`, `department_id=unit_id` (v3.0 fix non-admin filter subtree).
    - `recipient_type = 'external_org'` → INSERT vào `edoc.lgsp_tracking` (lines 27922-27930) với `direction='send'`, `status='pending'`.
    - Cuối: UPDATE outgoing_docs SET `status = 'sent'` (line 27940).
  - `e_office_app_new/workers/src/index.ts` lines 210-243 — Worker `lgsp-send` pick job → gọi `lgspSendEdoc()` real API hoặc mock → `fn_lgsp_tracking_update_status` thành `success`/`error`.
  - `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx` lines 334-357 — `handleReleaseAndSend()` gọi 2 API liên tiếp: `PATCH /ban-hanh` + `POST /gui-noi-bo`, sau đó refresh `fetchRecipients`/`fetchNoiNhan` để hiển thị badge LGSP.
- **Source of truth for new text:** `32-CONTEXT.md` `<specifics>` block 2, lines 213-238.
- **Insertion point:** Sau line 309 (sau bảng "Thông báo của hệ thống" của 3.7), trước line 311 `### 3.8. Drawer giao việc`.

## Per-File Audit

### docs/hdsd/HDSD_van_ban_den.md (384 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Danh sách / 3.2 Drawer thêm-sửa / 3.3 Modal xóa / 3.4 Chi tiết / 3.5 Modal gửi / 3.6 Drawer giao việc / 3.7 Modal chuyển lại / 3.8 Modal thêm HSCV / 3.9 Modal gửi LGSP
- **Button/menu diff:** UI hiện tại match HDSD — `Thêm mới / Xuất Excel / In / Đánh dấu đã đọc / Xóa bộ lọc` + Dropdown "Sửa, Duyệt, Hủy duyệt, Thu hồi, Xóa" đều có. Mục 3.4 chi tiết: các nút "Giao việc / Thêm vào HSCV / Gửi liên thông / Sửa / Duyệt / Gửi / Bút phê / Nhận bàn giao / Chuyển lại" + dropdown phụ "Thu hồi / Xóa văn bản / Nhận bản giấy / Hủy duyệt" đều khớp với van-ban-den/[id]/page.tsx hiện tại.
- **Field diff:** Form Thêm/Sửa VB đến (mục 3.2) liệt kê đủ 19 fields. Schema v3.0 không có thay đổi đáng kể. maxLength match (Trích yếu 2000, Ký hiệu 100, Người ký 200, Số phụ 20).
- **Workflow gap:** **GAP 1** (mục 3.6 — Drawer giao việc thiếu mô tả "Sau khi giao việc — VB xuất hiện ở đâu?")
- **Notification diff:** Mục 3.6 hiện chỉ ghi "gửi thông báo cho người phụ trách" (line 276) nhưng KHÔNG nêu rõ là chuông bell `task_assigned`. Cần bổ sung — thuộc GAP 1.
- **Hidden routes diff:** Không có route VB đến nào bị ẩn (xem `hidden-routes.ts` — chỉ ẩn `/tin-nhan`, `/lich/*`, `/danh-ba`, `/kho-luu-tru`, `/tai-lieu`, `/hop-dong`, `/cuoc-hop`, `/lgsp`, `/quan-tri/{chuc-nang,cau-hinh-truong,co-quan,nhom-lam-viec,uy-quyen,dia-ban,lich-lam-viec,mau-thong-bao,cau-hinh}`). VB đến không bị ảnh hưởng.
- **Screenshot retake:** `van_ban_den_06_drawer_giao_viec.png` — sau update text 3.6 sẽ có subsection mới, ảnh cần retake để cover state "drawer mở + filled form trước khi bấm Tạo". `van_ban_den_04_detail.png` — sau Phase 31 fix-gom group action buttons, layout phải nút có thể đã đổi → retake để an toàn. Các ảnh khác giữ nguyên.
- **Verdict:** **Update text (GAP 1) + retake screenshots 2 ảnh** (`van_ban_den_06_drawer_giao_viec`, `van_ban_den_04_detail`).

### docs/hdsd/HDSD_van_ban_di.md (371 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Danh sách / 3.2 Drawer thêm-sửa / 3.3 Modal xóa / 3.4 Modal từ chối / 3.5 Chi tiết / 3.6 Modal gửi cán bộ / 3.7 Modal gửi nội bộ (Ban hành & Gửi) / 3.8 Drawer giao việc / 3.9 Modal thêm HSCV
- **Button/menu diff:** Mục 3.5 chi tiết khớp với van-ban-di/[id]/page.tsx — `Quay lại / Đánh dấu / Giao việc / Thêm vào HSCV / Sửa / Duyệt / Ban hành / Ban hành & Gửi / Gửi / Dropdown thao tác phụ`. Lines 488-503 của page.tsx confirm 2 nút "Ban hành" (purple `#7C3AED`) + "Ban hành & Gửi" (green `#059669`) khi approved + chưa is_released. Dropdown phụ "Từ chối / Xóa / Hủy duyệt / Thu hồi" — khớp.
- **Field diff:** Form Thêm/Sửa (3.2) liệt kê 24 fields. Schema match (Trích yếu 2000, Ký hiệu 100, Người ký 200, Số phụ 20, Mã văn bản 100).
- **Workflow gap:** **GAP 2** (mục 3.8) + **GAP 3** (mục 3.7) — cả 2 mục đều thiếu mô tả nghiệp vụ chi tiết.
- **Notification diff:**
  - Mục 3.7 chỉ liệt kê 3 thông báo client-side ("Chưa chọn đơn vị / Gửi thành công / Ban hành & Gửi thành công") — KHÔNG có giải thích badge "Đang chờ worker đẩy LGSP" / "Đã gửi LGSP" / "Lỗi gửi LGSP" hiển thị trên UI sau khi worker LGSP pick job. Thuộc GAP 3.
  - Mục 3.8 chỉ ghi "Tạo HSCV từ văn bản đi" — KHÔNG note rằng người được giao việc KHÔNG có chuông bell `task_assigned` (khác với VB đến). Thuộc GAP 2.
- **Hidden routes diff:** Không ảnh hưởng VB đi.
- **Screenshot retake:** `van_ban_di_07_modal_send_internal.png` (Modal Ban hành & Gửi — sau GAP 3 cần caption mô tả thêm), `van_ban_di_08_drawer_giao_viec.png` (Drawer Giao việc — sau GAP 2 cần caption thêm note), `van_ban_di_05_detail.png` (trang chi tiết — Phase 31 fix-gom đã group action buttons + đổi màu, layout phải nút có thể đã đổi).
- **Verdict:** **Update text (GAP 2 + GAP 3) + retake 3 screenshots**.

### docs/hdsd/HDSD_van_ban_du_thao.md (317 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Danh sách / 3.2 Drawer thêm-sửa / 3.3 Modal xóa / 3.4 Confirm duyệt / 3.5 Modal từ chối / 3.6 Confirm phát hành / 3.7 Chi tiết / 3.8 Modal gửi
- **Button/menu diff:** Không phát hiện thay đổi UI Phase 31 ảnh hưởng tới module này. Buttons "Thêm mới / Xuất Excel / In / Xóa bộ lọc / Dropdown thao tác" + dropdown "Xem chi tiết / Sửa / Duyệt / Từ chối / Phát hành / Hủy duyệt / Thu hồi / Xóa" — tất cả khớp.
- **Field diff:** Match schema v3.0.
- **Workflow gap:** Không có gap nghiệp vụ. Tuy nhiên — Dự thảo "Phát hành" sinh ra Văn bản đi → có thể link tới GAP 3 mô tả luồng VB đi tiếp theo. Đề xuất thêm 1 câu cross-reference ngắn "(xem mục 3.7 HDSD_van_ban_di để hiểu luồng kỹ thuật khi Ban hành & Gửi VB đi sau khi Phát hành dự thảo)" trong mục 3.6 Confirm phát hành. **Không bắt buộc — optional nice-to-have.**
- **Notification diff:** Không có gap.
- **Hidden routes diff:** Không ảnh hưởng.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change** (optional 1 dòng cross-reference — sẽ flag trong Plan 02 nếu agent thấy hợp lý).

### docs/hdsd/HDSD_van_ban_danh_dau.md (87 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Màn hình chính
- **Button/menu diff:** UI khớp — "In / Tab Tất cả/VB đến/VB đi/Dự thảo / Ngôi sao / Trích yếu link / Xem (con mắt) / Thùng rác / Phân trang". Trong menu sidebar (MainLayout.tsx line 156): `'/van-ban-danh-dau'` không bị HIDDEN → menu vẫn hiển thị "Đánh dấu cá nhân".
- **Field diff:** N/A (read-only screen).
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** Không ảnh hưởng.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_cau_hinh_gui_nhanh.md (81 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Màn hình cấu hình
- **Button/menu diff:** UI khớp — "Lưu cấu hình (N người) / Tìm kiếm / Ô chọn dòng / Bỏ / Phân trang". Menu sidebar (MainLayout.tsx line 157): `'/cau-hinh-gui-nhanh'` không bị HIDDEN.
- **Field diff:** N/A.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** Không ảnh hưởng.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_ho_so_cong_viec.md (802 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình + 7 trạng thái / 3.1-3.X Danh sách + Drawer tạo + Chi tiết + nhiều screen khác (file dài 802 dòng)
- **Button/menu diff:** Tab "Mới tạo / Đang xử lý / Chờ duyệt / Hoàn thành / Trả về / Bị từ chối / Đã hủy" + tab phụ "Tất cả / Tôi tạo" — khớp với page.tsx lines 28-50.
- **Field diff:** Match schema v3.0.
- **Workflow gap:** GAP cross-reference — mục 3.1 (tab "Mới tạo") nên thêm 1 câu giải thích "HSCV xuất hiện ở tab Mới tạo của người được chọn làm Người phụ trách khi:
  - Cán bộ tự bấm "Tạo hồ sơ mới" → tab Tôi tạo + tab Mới tạo,
  - Lãnh đạo bấm "Giao việc" trên chi tiết VB đến (xem `HDSD_van_ban_den.md` mục 3.6) → HSCV vào tab Mới tạo của người được giao,
  - Cán bộ bấm "Giao việc" trên chi tiết VB đi (xem `HDSD_van_ban_di.md` mục 3.8) → HSCV vào tab Mới tạo của người được giao."
  - **Insertion point:** Trong mục 3.1 bảng "Các tab phân loại" — sau dòng tab "Mới tạo" thêm note nhỏ kèm cross-reference. **Optional** — sẽ giảm rủi ro tester hiểu nhầm HSCV xuất hiện từ đâu.
- **Notification diff:** Không có direct gap.
- **Hidden routes diff:** Không ảnh hưởng.
- **Screenshot retake:** Không cần (UI HSCV không đổi Phase 31).
- **Verdict:** **Optional minor update** — thêm cross-reference tab "Mới tạo" tới VB đến mục 3.6 + VB đi mục 3.8 (HDSD_van_ban_di GAP 2). Không bắt buộc nhưng giúp tester nối các luồng.

### docs/hdsd/HDSD_thong_bao.md (166 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Chuông bell / 3.2 Trang Thông báo nội bộ / 3.3 Drawer tạo thông báo
- **Button/menu diff:** UI khớp. Mục 3.1 đã liệt kê 5 loại biểu tượng bell (ký số thành công, ký số thất bại, được giao VB đến, được giao việc, ý kiến lãnh đạo) — đầy đủ.
- **Field diff:** Form tạo thông báo (3.3) — Tiêu đề (300 char), Nội dung (5000 char) — match constraint backend.
- **Workflow gap:** Cross-reference — mục 3.1 (biểu tượng "được giao việc") nên thêm note: "Lưu ý: hiện chỉ áp dụng cho **giao việc từ VB đến** (xem `HDSD_van_ban_den.md` mục 3.6). **Giao việc từ VB đi chưa có chuông bell** trong phiên bản hiện hành — sẽ bổ sung ở phiên bản sau v3.2+". **Optional** — giúp tester không bị surprise.
- **Notification diff:** Không có.
- **Hidden routes diff:** Trong sidebar `'/thong-bao'` không bị ẩn nhưng `'/thong-bao-kenh'` BỊ ẨN (admin only nếu được). Mục 3.2 không nhắc tới `/thong-bao-kenh` nên không bị ảnh hưởng.
- **Screenshot retake:** Không cần.
- **Verdict:** **Optional minor update** — thêm 1 dòng cross-reference về limitation của bell `task_assigned` cho VB đi.

### docs/hdsd/HDSD_dashboard.md (123 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Màn hình Tổng quan
- **Button/menu diff:** UI khớp — 6 stat cards (VB đến chưa đọc / VB đi chờ duyệt / HSCV / Việc quá hạn / Dự thảo chờ phát hành / Thông báo chưa đọc), 2 biểu đồ, 2 bảng (VB mới nhận / VB đi mới), khung Việc sắp tới hạn, 4 nút Thao tác nhanh.
- **Field diff:** N/A.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** Không ảnh hưởng.
- **Screenshot retake:** `dashboard_01_main.png` — Phase 31 fix-gom có thể đã đổi color/spacing của stat cards. **Đề xuất retake để chắc chắn** (low priority — chỉ aesthetic).
- **Verdict:** **No text change + retake 1 screenshot** (optional).

### docs/hdsd/HDSD_dang_nhap_va_thong_tin_ca_nhan.md (162 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Đăng nhập / 3.2 Thông tin cá nhân
- **Button/menu diff:** UI khớp với login screen + profile page. Mục 3.1 mention "Phiên bản 2.0 · Chuyển đổi số Doanh nghiệp" ở chân trang — **cần verify v3.1 vs 2.0** (text có thể đã update ở Phase 21+). **Đề xuất check `frontend/src/app/(auth)/login/page.tsx` để xác định version string hiện tại**.
- **Field diff:** Quy tắc mật khẩu mới "tối thiểu 6 ký tự, chứa chữ hoa + chữ thường + số" — match backend `auth.service.ts`.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** Không ảnh hưởng.
- **Screenshot retake:** Không cần (login UI không đổi).
- **Verdict:** **Text update minor** — verify + update version string ở mục 3.1 (line ~51). Plan 02-05 cần check.

### docs/hdsd/HDSD_ky_so_cau_hinh.md (173 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Màn hình cấu hình / 3.2 Drawer sửa cấu hình / 3.3 Confirm kích hoạt
- **Button/menu diff:** UI khớp. Mục 3.1 mô tả 2 provider cards (SmartCA VNPT + MySign Viettel) khớp với seed/001_required_data.sql.
- **Field diff:** Base URL bắt buộc, Client ID 200 char, Client Secret ≥8 char, Profile ID (chỉ MySign). Match schema.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** `'/ky-so/cau-hinh'` chỉ admin (MainLayout line 232-238) — HDSD đã ghi "chỉ truy cập được khi tài khoản có quyền quản trị" → match.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_ky_so_danh_sach.md (227 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Danh sách / 3.2 Banner Root CA Viettel / 3.3 Modal ký số
- **Button/menu diff:** UI khớp — 4 tab (Cần ký / Đang xử lý / Đã ký / Thất bại), nút Ký số / Hủy / Tải file đã ký / Ký lại.
- **Field diff:** Match schema.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** `'/ky-so/danh-sach'` không bị ẩn (mọi user thấy).
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_ky_so_tai_khoan.md (95 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Màn hình + form khai báo
- **Button/menu diff:** UI khớp — Làm mới / Tải danh sách chứng thư từ MySign / Lưu cấu hình / Xác thực tài khoản ký số.
- **Field diff:** Mã định danh max 200 char — match.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** `'/ky-so/tai-khoan'` không bị ẩn.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_quan_tri_don_vi.md (184 dòng)

- **Sections present:** Giới thiệu / Quy trình / 3.1 Danh sách / 3.2 Drawer thêm-sửa / 3.3 Confirm xóa
- **Button/menu diff:** UI khớp — cây trái + bảng phải, "Tải lại / Thêm đơn vị / Sửa / Khóa / Mở khóa / Xóa".
- **Field diff:** Mã đơn vị unique + Tên bắt buộc + Cấp (Đơn vị/Phòng ban) + Cho phép sổ VB — match schema.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** `'/quan-tri/don-vi'` không bị ẩn (admin thấy).
- **Screenshot retake:** Không cần (admin UI Phase 31 không đổi nhiều).
- **Verdict:** **No change**.

### docs/hdsd/HDSD_quan_tri_chuc_vu.md (165 dòng)

- **Sections present:** Giới thiệu / Quy trình / 3.1 Danh sách / 3.2 Drawer / 3.3 Confirm xóa
- **Button/menu diff:** UI khớp.
- **Field diff:** Mã chức vụ unique + Tên bắt buộc + Chức vụ lãnh đạo + Được xử lý văn bản — match.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** Không ảnh hưởng.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_quan_tri_nguoi_dung.md (295 dòng)

- **Sections present:** Giới thiệu / Quy trình / 3.1 Danh sách / 3.2 Drawer thêm-sửa / 3.3 Drawer phân quyền / 3.4 Modal reset / 3.5 Confirm xóa
- **Button/menu diff:** UI khớp.
- **Field diff:** Username (3+ char, chữ/số/./-) + Password (6+, hoa+thường+số, mặc định Admin@123) + Email duy nhất + Số điện thoại 8-15 char + Đơn vị/Phòng ban bắt buộc — match.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** Không ảnh hưởng.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_quan_tri_nhom_quyen.md (191 dòng)

- **Sections present:** Giới thiệu / Quy trình / 3.1 Danh sách / 3.2 Drawer thêm-sửa / 3.3 Drawer phân quyền / 3.4 Confirm xóa
- **Button/menu diff:** UI khớp.
- **Field diff:** Tên nhóm quyền unique + bắt buộc — match.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** Không ảnh hưởng (`/quan-tri/nhom-quyen` không bị ẩn).
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_quan_tri_so_van_ban.md (136 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Danh sách / 3.2 Drawer / 3.3 Confirm
- **Button/menu diff:** UI khớp — 3 tab (Văn bản đến / đi / dự thảo), nút Thêm sổ + dropdown "Sửa / Đặt mặc định / Xóa".
- **Field diff:** Tên sổ max 200 + Mô tả max 500 + Thứ tự int ≥0 + duy nhất 1 mặc định/nhóm — match.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** `/quan-tri/so-van-ban` không bị ẩn.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_quan_tri_linh_vuc.md (118 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Danh sách / 3.2 Drawer / 3.3 Confirm
- **Button/menu diff:** UI khớp.
- **Field diff:** Mã max 20 unique + Tên max 200 + Thứ tự int ≥0 + Trạng thái Hoạt động/Ngừng — match.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** `/quan-tri/linh-vuc` không bị ẩn.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_quan_tri_loai_van_ban.md (126 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Danh sách / 3.2 Drawer / 3.3 Confirm
- **Button/menu diff:** UI khớp — 3 tab + dạng cây có loại cha-con.
- **Field diff:** Mã max 20 unique + Tên max 200 + Loại cha (cấp lồng) + Kiểu ký hiệu (3 option) — match.
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** `/quan-tri/loai-van-ban` không bị ẩn.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_quan_tri_nguoi_ky.md (112 dòng)

- **Sections present:** 1 Giới thiệu / 2 Quy trình / 3.1 Danh sách / 3.2 Modal thêm
- **Button/menu diff:** UI khớp — cây trái phòng ban + bảng phải, nút Thêm người ký + chỉ có nút Xóa (không Sửa).
- **Field diff:** Người ký được chọn từ nhân viên phòng ban — match schema (trigger DB tự sync khi nhân viên đổi phòng).
- **Workflow gap:** Không có.
- **Notification diff:** Không có.
- **Hidden routes diff:** `/quan-tri/nguoi-ky` không bị ẩn.
- **Screenshot retake:** Không cần.
- **Verdict:** **No change**.

### docs/hdsd/HDSD_index.md (129 dòng)

- **Sections present:** TOC chỉ mục
- **Button/menu diff:** N/A.
- **Field diff:** N/A.
- **Workflow gap:** TOC chia 6 nhóm — 5.1 Cá nhân + 5.2 VB + 5.3 HSCV + 5.4 Ký số + 5.5 Quản trị + 5.6 Danh mục. Liệt kê đúng 20+ file. Hiện ghi "Bộ tài liệu này mô tả ... phiên bản hiện hành" — không có hard-coded version string. Cần verify TOC vẫn match thứ tự file sau update.
- **Notification diff:** Không có.
- **Hidden routes diff:** Index nhắc "Tin nhắn" (line 66) — `/tin-nhan` BỊ ẨN ở `hidden-routes.ts`. **Phải remove dòng "Tin nhắn" khỏi TOC 5.1** (line 66 trong index) hoặc thêm note "(chưa kích hoạt)". Đề xuất: Plan 02-05 remove tham chiếu "Tin nhắn" trong TOC.
- **Screenshot retake:** Không cần.
- **Verdict:** **Update TOC** — remove dòng "Tin nhắn" hoặc đánh dấu "(chưa kích hoạt v3.1)". Verify sau khi 3 GAP đã apply rằng heading lookup TOC vẫn correct.

### docs/hdsd/HDSD_full.md (4424 dòng — bản merged)

- **Sections present:** Merged của 20 file con (theo HDSD_index thứ tự).
- **Button/menu diff:** Reflect content của 20 file con.
- **Field diff:** Reflect content của 20 file con.
- **Workflow gap:** Cần re-merge sau khi 3 GAP + minor updates apply vào file con.
- **Notification diff:** N/A.
- **Hidden routes diff:** N/A.
- **Screenshot retake:** N/A (refer to source files).
- **Verdict:** **Re-merge required after Plans 02-05 update text** (Plan 07 will handle). Sau đó Plan 08 export `HDSD_full.docx` qua pandoc.

## Screenshots to re-capture (Wave 2 — Plan 06)

| Screenshot file | Reason |
|---|---|
| `docs/hdsd/screenshots/van_ban_den_06_drawer_giao_viec.png` | Sau GAP 1 update text — đảm bảo state Drawer mở match HDSD mới |
| `docs/hdsd/screenshots/van_ban_den_04_detail.png` | Phase 31 fix-gom có thể đã đổi layout group action buttons |
| `docs/hdsd/screenshots/van_ban_di_05_detail.png` | Phase 31 group "Ban hành / Ban hành & Gửi / Gửi / Dropdown phụ" có color customization (`#7C3AED`, `#059669`, `#0891B2`) — retake để verify |
| `docs/hdsd/screenshots/van_ban_di_07_modal_send_internal.png` | Sau GAP 3 update — caption đi cùng cần ảnh fresh |
| `docs/hdsd/screenshots/van_ban_di_08_drawer_giao_viec.png` | Sau GAP 2 update — caption đi cùng cần ảnh fresh |
| `docs/hdsd/screenshots/dashboard_01_main.png` | (Optional low-priority) Phase 31 có thể đã đổi spacing/color của 6 stat cards |

**Total: 5 mandatory + 1 optional = 6 screenshots.**

## Files unchanged (no text or screenshot change)

14 files: `HDSD_van_ban_du_thao.md`, `HDSD_van_ban_danh_dau.md`, `HDSD_cau_hinh_gui_nhanh.md`, `HDSD_ky_so_cau_hinh.md`, `HDSD_ky_so_danh_sach.md`, `HDSD_ky_so_tai_khoan.md`, `HDSD_quan_tri_don_vi.md`, `HDSD_quan_tri_chuc_vu.md`, `HDSD_quan_tri_nguoi_dung.md`, `HDSD_quan_tri_nhom_quyen.md`, `HDSD_quan_tri_so_van_ban.md`, `HDSD_quan_tri_linh_vuc.md`, `HDSD_quan_tri_loai_van_ban.md`, `HDSD_quan_tri_nguoi_ky.md`.

Files cần update text:

- **Bắt buộc:** `HDSD_van_ban_den.md` (GAP 1), `HDSD_van_ban_di.md` (GAP 2 + GAP 3)
- **Khuyến nghị (optional cross-reference):** `HDSD_ho_so_cong_viec.md`, `HDSD_thong_bao.md`, `HDSD_dang_nhap_va_thong_tin_ca_nhan.md` (verify version string), `HDSD_index.md` (remove/mark "Tin nhắn")
- **Re-merge sau Plans 02-05:** `HDSD_full.md` (Plan 07)
- **Export docx sau re-merge:** `HDSD_full.docx` (Plan 08)

## Contract for Plans 02-05

Plans 02-05 sẽ chia 4 nhóm:

| Plan | Files | Số file | Bắt buộc | Optional |
|---|---|---|---|---|
| **02 — VB (đến/đi/dự thảo/đánh dấu)** | `HDSD_van_ban_den.md`, `HDSD_van_ban_di.md`, `HDSD_van_ban_du_thao.md`, `HDSD_van_ban_danh_dau.md` | 4 | GAP 1, GAP 2, GAP 3 | 1 dòng cross-ref ở `du_thao` |
| **03 — HSCV/Dashboard/Thông báo/Gửi nhanh** | `HDSD_ho_so_cong_viec.md`, `HDSD_dashboard.md`, `HDSD_thong_bao.md`, `HDSD_cau_hinh_gui_nhanh.md` | 4 | (nothing critical) | Cross-ref HSCV tab "Mới tạo", note bell `task_assigned` chỉ áp dụng VB đến |
| **04 — Ký số + Đăng nhập + Index** | `HDSD_ky_so_cau_hinh.md`, `HDSD_ky_so_danh_sach.md`, `HDSD_ky_so_tai_khoan.md`, `HDSD_dang_nhap_va_thong_tin_ca_nhan.md`, `HDSD_index.md` | 5 | (nothing critical) | Verify version string login + remove "Tin nhắn" trong TOC index |
| **05 — Quản trị (8 file)** | `HDSD_quan_tri_don_vi.md`, `HDSD_quan_tri_chuc_vu.md`, `HDSD_quan_tri_nguoi_dung.md`, `HDSD_quan_tri_nhom_quyen.md`, `HDSD_quan_tri_so_van_ban.md`, `HDSD_quan_tri_loai_van_ban.md`, `HDSD_quan_tri_linh_vuc.md`, `HDSD_quan_tri_nguoi_ky.md` | 8 | (nothing critical) | (none) |

Plan 06 — chụp lại 5+1 screenshots (Playwright + tools/screenshots existing infra).
Plan 07 — re-merge `HDSD_full.md` từ 20 file con theo thứ tự `HDSD_index.md`.
Plan 08 — export `HDSD_full.docx` qua pandoc 3.9 với `--reference-doc=tools/screenshots/reference.docx --resource-path=docs/hdsd`.

## Audit Confidence

- **High confidence** (đã verify trực tiếp code): GAP 1, GAP 2, GAP 3, hidden routes, MainLayout menu, schema field constraints VB đến/đi.
- **Medium confidence** (verify bằng heading scan + spot check): Quản trị 8 file, ký số 3 file.
- **Low confidence** (optional only): Dashboard screenshot retake, version string login.

Audit này là source-of-truth cho 4 plan update text (02-05) — downstream agent đọc audit + CONTEXT.md là đủ context, không cần re-scan code.
