---
status: complete
phase: 32-hdsd-audit-update
source: [32-01-SUMMARY.md, 32-02-SUMMARY.md, 32-03-SUMMARY.md, 32-04-SUMMARY.md, 32-05-SUMMARY.md, 32-06-SUMMARY.md, 32-07-SUMMARY.md, 32-08-SUMMARY.md]
started: 2026-05-19T16:50:00Z
updated: 2026-05-19T17:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. GAP 1 — HDSD VB đến mục 3.6 có subsection "Sau khi giao việc — văn bản xuất hiện ở đâu"
expected: Subsection mới ở mục 3.6 mô tả 3 điểm (chuông + HSCV "Mới tạo" + VB không chuyển đi)
result: pass

### 2. GAP 2 + GAP 3 — HDSD VB đi mục 3.7 + 3.8
expected: |
  Mục 3.7 (Modal gửi nội bộ): có subsection `#### Luồng kỹ thuật khi Gửi (3 bước nối tiếp)` mô tả Bước 1 (lưu recipients) → Bước 2 (cấp số) → Bước 3 (loop: internal sinh VB đến / external sinh lgsp_tracking pending + worker BullMQ)
  Mục 3.8 (Drawer giao việc): có subsection `#### Sau khi giao việc — văn bản xuất hiện ở đâu?` + ghi rõ "**KHÔNG có chuông thông báo** (gap code chưa fix — sẽ bổ sung ở phiên bản sau v3.2+)"
result: pass

### 3. Cross-ref HDSD Hồ sơ công việc tab "Mới tạo"
expected: |
  Mở `docs/hdsd/HDSD_ho_so_cong_viec.md`, mục 3.1 (Màn hình Danh sách HSCV) sau bảng "Các tab phân loại" có subsection mới
  `#### HSCV tự xuất hiện ở tab "Mới tạo" khi được giao việc` liệt kê 3 nguồn:
    1. Cán bộ tự bấm "Tạo hồ sơ mới"
    2. Lãnh đạo giao việc từ VB đến — có chuông (link sang HDSD VB đến mục 3.6)
    3. Người soạn giao việc từ VB đi — chưa có chuông (link sang HDSD VB đi mục 3.8)
result: pass
note: "User confirm OK nhưng note HDSD đang out-of-date so với thực tế (code đã fix bug từ 2026-05-11). Pass cho spot-check Phase 32 — sẽ refresh trong v3.2+ phase 'HDSD full refresh'."

### 4. HDSD_index.md — 20 link TOC đều resolve
expected: |
  Mở `docs/hdsd/HDSD_index.md`, section 5.3 "Hồ sơ công việc" chỉ có 1 mục #9 "Hồ sơ công việc (danh sách + chi tiết + báo cáo)" → `HDSD_ho_so_cong_viec.md` (KHÔNG còn 3 link cũ tới `_danh_sach.md` / `_chi_tiet.md` / `_bao_cao.md` đã bị xóa).
  TOC items section 5.4 trở đi đánh số liên tục #10 → #20.
  Tất cả 20 link click được, không 404.
result: pass

### 5. Screenshots cập nhật theo UI mới (Phase 21 LGSP + Phase 31 fix-gom)
expected: |
  Mở 2 file:
    - `docs/hdsd/screenshots/dashboard_01_main.png` (256 KB, 1440x1446) — phản ánh layout dashboard mới (6 stat cards + 2 charts + 2 tables)
    - `docs/hdsd/screenshots/van_ban_di_07_modal_send_internal.png` (164 KB, 1440x900) — phản ánh modal "Ban hành & Gửi" mới (chứa "chọn đơn vị nhận" + checkbox phòng ban)
  Ảnh ĐÚNG state hiện tại, KHÔNG còn UI cũ trước Phase 21/31.
  (4 ảnh còn lại: van_ban_den_04/06, van_ban_di_05/08 — cũng có thể kiểm spot-check nếu muốn)
result: skipped
reason: "User quyết định bỏ verify — HDSD + screenshots đã out-of-date so với thực tế (phần mềm đã fix nhiều sau 2026-05-11). Sẽ refresh full trong v3.2+ phase 'HDSD full refresh'."

### 6. HDSD_full.docx (export pandoc)
expected: |
  Mở `docs/hdsd/HDSD_full.docx` (~13.3 MB) bằng Word/LibreOffice:
    - Có Mục lục (TOC) đầu file, depth 3
    - 20 chương Phần I (mục 4.x = VB đến, 5.x = VB đi, 9.x = HSCV, ...)
    - 82 ảnh embed inline trong nội dung (KHÔNG broken image)
    - 3 GAP mới đọc được:
      • Mục 4.3.6.5 "Sau khi giao việc — văn bản xuất hiện ở đâu của TK được giao?"
      • Mục 5.3.7.5 "Luồng kỹ thuật khi Gửi (3 bước nối tiếp)"
      • Mục 5.3.8.5 "Sau khi giao việc — văn bản xuất hiện ở đâu?" + cảnh báo "KHÔNG có chuông thông báo"
  File mở không lỗi, có thể gửi KH dùng như HDSD chính thức.
result: skipped
reason: "User quyết định bỏ verify — HDSD_full.docx export cùng nguồn stale → cũng outdated. Sẽ re-export sau khi refresh HDSD trong v3.2+."

## Summary

total: 6
passed: 4
issues: 0
pending: 0
skipped: 2
blocked: 0

## Gaps

[none — Phase 32 đạt goal tại thời điểm execute. HDSD stale là natural drift sau 8 ngày, được track riêng ở v3.2+ backlog "HDSD full refresh"]
