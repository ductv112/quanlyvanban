---
phase: 32
plan: 01
subsystem: documentation
tags: [hdsd, audit, gap-analysis]
requires: []
provides:
  - audit_report_22_hdsd_files
  - 3_critical_gaps_enumerated
  - screenshot_retake_list
  - downstream_contract_plans_02_05
affects:
  - .planning/phases/32-hdsd-audit-update/32-AUDIT-REPORT.md
tech-stack-added: []
tech-stack-patterns: []
key-files:
  created:
    - .planning/phases/32-hdsd-audit-update/32-AUDIT-REPORT.md
  modified: []
decisions:
  - "Auto-detect 22 HDSD files via ls glob (20 module + 1 index + 1 full)"
  - "Verify GAP 2 by direct grep of notifyBell/task_assigned in outgoing-doc.ts — confirmed 0 match → gap legitimate"
  - "Confirm GAP 1 source: incoming-doc.ts line 956 notifyBell with type='task_assigned' → wording in CONTEXT.md is accurate"
  - "GAP 3 verified via SP fn_outgoing_doc_send_to_recipients lines 27846-27948 + worker lgsp-send lines 210-243"
  - "Split text-update work into 4 plans (02-05) — VB, HSCV+Dashboard+Notif+GuiNhanh, KySo+DangNhap+Index, QuanTri"
  - "Mark 5 screenshots mandatory + 1 optional for Wave 2"
metrics:
  duration_minutes: ~25
  completed: 2026-05-11
  files_audited: 22
  gaps_critical: 3
  files_needing_text_change: 8
  files_clean: 14
  screenshots_retake: 6
---

# Phase 32 Plan 01: HDSD Audit Report Summary

**One-liner:** Audit 22 HDSD files vs current code (post Phase 21 LGSP + Phase 31 fix-gom) — enumerate 3 critical GAPs (VB đến giao việc thiếu mô tả VB ở đâu / VB đi giao việc thiếu note no-bell / VB đi Ban hành & Gửi thiếu luồng kỹ thuật) + screenshot retake list + contract cho 4 plan update downstream.

## What was audited

| File | Lines | Verdict |
|---|---|---|
| HDSD_van_ban_den.md | 384 | **Update (GAP 1) + retake 2 screenshots** |
| HDSD_van_ban_di.md | 371 | **Update (GAP 2 + GAP 3) + retake 3 screenshots** |
| HDSD_van_ban_du_thao.md | 317 | No change (optional 1 cross-ref) |
| HDSD_van_ban_danh_dau.md | 87 | No change |
| HDSD_cau_hinh_gui_nhanh.md | 81 | No change |
| HDSD_ho_so_cong_viec.md | 802 | Optional minor (cross-ref tab "Mới tạo") |
| HDSD_thong_bao.md | 166 | Optional minor (note bell `task_assigned` only VB đến) |
| HDSD_dashboard.md | 123 | No text change (retake 1 optional) |
| HDSD_dang_nhap_va_thong_tin_ca_nhan.md | 162 | Verify version string |
| HDSD_ky_so_cau_hinh.md | 173 | No change |
| HDSD_ky_so_danh_sach.md | 227 | No change |
| HDSD_ky_so_tai_khoan.md | 95 | No change |
| HDSD_quan_tri_don_vi.md | 184 | No change |
| HDSD_quan_tri_chuc_vu.md | 165 | No change |
| HDSD_quan_tri_nguoi_dung.md | 295 | No change |
| HDSD_quan_tri_nhom_quyen.md | 191 | No change |
| HDSD_quan_tri_so_van_ban.md | 136 | No change |
| HDSD_quan_tri_linh_vuc.md | 118 | No change |
| HDSD_quan_tri_loai_van_ban.md | 126 | No change |
| HDSD_quan_tri_nguoi_ky.md | 112 | No change |
| HDSD_index.md | 129 | Update TOC (remove "Tin nhắn" / mark "(chưa kích hoạt)") |
| HDSD_full.md | 4424 | Re-merge after Plans 02-05 (Plan 07) |

**Totals:**

- 22 files audited
- 14 clean (no change)
- 8 need updates (3 critical GAPs in 2 files + 5 minor/cross-ref in 5 files + HDSD_index + HDSD_full re-merge)
- 6 screenshots flagged for Wave 2 retake (5 mandatory + 1 optional)

## 3 GAP confirmations (with code evidence)

### GAP 1 — `HDSD_van_ban_den.md` mục 3.6

- **Confirmed via:** `backend/src/routes/incoming-doc.ts` lines 909-973 (notifyBell `task_assigned` block lines 949-967) + `frontend/src/app/(main)/ho-so-cong-viec/page.tsx` line 43 (`tabs[0] = { key: 'new', label: 'Mới tạo' }`).
- **Insertion point identified:** Sau line 296 (sau bảng "Thông báo của hệ thống" của mục 3.6), trước line 298 `### 3.7. Modal chuyển lại`.
- **Text source-of-truth:** `32-CONTEXT.md` `<specifics>` block 1 lines 188-206.

### GAP 2 — `HDSD_van_ban_di.md` mục 3.8

- **Confirmed via:** Direct grep `notifyBell|notification_log|task_assigned` ở `backend/src/routes/outgoing-doc.ts` → **0 match** (xác nhận VB đi giao việc KHÔNG có chuông bell).
- Route POST `/:id/giao-viec` lines 899-926 chỉ validate `name?.trim()` (line 908) — KHÔNG validate `end_date` / `curator_ids` non-empty (khác với incoming-doc.ts lines 922-930 vốn check `curator_ids.length === 0` + `!end_date`).
- **Insertion point identified:** Sau line 342 (cuối bảng "Thông báo" của mục 3.8), trước line 344 `### 3.9. Modal thêm văn bản vào HSCV`.
- **Text source-of-truth:** CONTEXT.md `<decisions>` GAP 2 note + custom subsection "Sau khi giao việc — VB xuất hiện ở đâu?".

### GAP 3 — `HDSD_van_ban_di.md` mục 3.7

- **Confirmed via:** SP `edoc.fn_outgoing_doc_send_to_recipients` (`database/schema/000_schema_v3.0.sql` lines 27846-27948) implements 3-step loop: lưu recipients → cấp số `is_released` → loop recipient → internal sinh `incoming_docs`, external sinh `lgsp_tracking` status `pending` + queue worker BullMQ. Worker `lgsp-send` (`workers/src/index.ts` lines 210-243) pick lên `success`/`error`. Frontend `van-ban-di/[id]/page.tsx` lines 334-357 `handleReleaseAndSend()` confirm 2-API call pattern + refresh badge UI.
- **Insertion point identified:** Sau line 309 (sau bảng "Thông báo" của mục 3.7), trước line 311 `### 3.8. Drawer giao việc`.
- **Text source-of-truth:** `32-CONTEXT.md` `<specifics>` block 2 lines 213-238.

## Screenshots flagged for retake (Plan 06)

| File | Reason | Priority |
|---|---|---|
| `van_ban_den_06_drawer_giao_viec.png` | Sau GAP 1 update — match new caption | Mandatory |
| `van_ban_den_04_detail.png` | Phase 31 fix-gom group action buttons | Mandatory |
| `van_ban_di_05_detail.png` | Phase 31 group "Ban hành / Ban hành & Gửi / Gửi / Dropdown" có custom colors | Mandatory |
| `van_ban_di_07_modal_send_internal.png` | Sau GAP 3 update — match new caption | Mandatory |
| `van_ban_di_08_drawer_giao_viec.png` | Sau GAP 2 update — match new caption | Mandatory |
| `dashboard_01_main.png` | Phase 31 spacing/color của stat cards | Optional |

## Contract for downstream plans

| Plan | Files | Critical work | Optional work |
|---|---|---|---|
| 02 | VB (đến/đi/dự thảo/đánh dấu) | GAP 1 + GAP 2 + GAP 3 | 1 cross-ref ở dự thảo |
| 03 | HSCV + Dashboard + Thông báo + Gửi nhanh | (none critical) | Cross-ref tab "Mới tạo" + note bell only VB đến |
| 04 | Ký số (3 file) + Đăng nhập + Index | (none critical) | Verify version string + remove "Tin nhắn" trong index TOC |
| 05 | Quản trị (8 file) | (none critical) | (none) |
| 06 | Screenshots Playwright | 5 mandatory + 1 optional retake | — |
| 07 | Re-merge HDSD_full.md | Merge 20 file con theo thứ tự HDSD_index.md | — |
| 08 | Export HDSD_full.docx | pandoc 3.9 với reference.docx + resource-path docs/hdsd | — |

## Deviations from Plan

None — plan executed exactly as written. Audit report sections + minimum line count + 3 GAP enumerations all met.

## Self-Check: PASSED

- File `.planning/phases/32-hdsd-audit-update/32-AUDIT-REPORT.md` — FOUND (356 lines, 31537 bytes — well over 8KB minimum)
- 22 `### docs/hdsd/HDSD_*` sections — FOUND (`grep -c` returned 22)
- 3 `### GAP ` sections — FOUND (`grep -c` returned 3)
- Commit `af4caa8` — FOUND (in `git log --all`)
- Each per-file section has `**Verdict:**` line — confirmed
