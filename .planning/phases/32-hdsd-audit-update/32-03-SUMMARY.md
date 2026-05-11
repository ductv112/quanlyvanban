---
phase: 32-hdsd-audit-update
plan: 03
subsystem: docs/hdsd
tags: [hdsd, documentation, hscv, dashboard, thong-bao, cau-hinh-gui-nhanh, cross-reference]
dependency_graph:
  requires:
    - 32-01-SUMMARY.md (audit report — per-file verdicts)
    - 32-02-SUMMARY.md (GAP 1 + GAP 2 already inserted in VB đến/đi HDSD — this plan documents the "other side" in HSCV HDSD)
  provides:
    - HDSD_ho_so_cong_viec.md with cross-reference note linking tab "Mới tạo" arrivals to VB đến mục 3.6 + VB đi mục 3.8
    - HDSD_thong_bao.md with notification_type codes inline + task_assigned VB-đi limitation note
    - HDSD_dashboard.md verified clean (no change per audit)
    - HDSD_cau_hinh_gui_nhanh.md verified clean (no change per audit)
  affects:
    - Plan 32-07 (re-merge HDSD_full.md must pull updated text from HSCV + Thông báo)
    - Plan 32-06 (no new screenshots needed for these 4 files — UI unchanged; dashboard optional retake low-priority)
tech_stack:
  added: []
  patterns:
    - Cross-reference linking between HDSD files via relative markdown links
    - notification_type code annotation inline (sign_completed, sign_failed, incoming_doc_assigned, task_assigned, leader_note_received)
    - "No change" verdict honored for files audit cleared
key_files:
  created: []
  modified:
    - docs/hdsd/HDSD_ho_so_cong_viec.md (+12 lines — subsection "HSCV tự xuất hiện ở tab Mới tạo khi được giao việc" inserted after Các tab phân loại table @ line 74)
    - docs/hdsd/HDSD_thong_bao.md (+2 lines net — annotated bell icon row with notification_type codes, added "Lưu ý phạm vi chuông task_assigned" paragraph @ line 79)
  reviewed_unchanged:
    - docs/hdsd/HDSD_dashboard.md (audit verdict: No change — 6 stat cards, 2 charts, 2 tables, 4 quick actions all match dashboard/page.tsx lines 199-205)
    - docs/hdsd/HDSD_cau_hinh_gui_nhanh.md (audit verdict: No change — UI khớp, không có workflow gap)
decisions:
  - "HSCV HDSD: inserted note after 'Các tab phân loại' table (the most semantically correct anchor — explains WHO arrives in tab 'Mới tạo' and FROM WHERE)"
  - "Listed 3 sources of HSCV in tab 'Mới tạo': self-create, giao việc VB đến (có bell), giao việc VB đi (chưa có bell — gap v3.2+)"
  - "HDSD_thong_bao.md: also annotated notification_type codes (sign_completed/sign_failed/incoming_doc_assigned/task_assigned/leader_note_received) inline beside each icon for tester reference to backend grep"
  - "HDSD_dashboard.md unchanged — audit verified 6 widget labels match code exactly: VB đến chưa đọc, VB đi chờ duyệt, Hồ sơ công việc, Việc quá hạn, Dự thảo chờ phát hành, Thông báo chưa đọc"
  - "HDSD_cau_hinh_gui_nhanh.md unchanged — audit verdict 'No change', no workflow gap"
metrics:
  duration: ~2 minutes
  completed: 2026-05-11
  tasks: 3
  files_modified: 2
  files_reviewed: 4
---

# Phase 32 Plan 03: Update text HSCV + Dashboard + Thông báo + Cấu hình gửi nhanh HDSD Summary

**One-liner:** Inserted HSCV-arrival-from-giao-viec cross-reference into HSCV HDSD (tab "Mới tạo" anchor) — closing the loop with GAP 1 + GAP 2 inserted in VB đến/đi HDSD by Plan 02 — plus annotated bell notification_type codes and task_assigned VB-đi limitation in Thông báo HDSD. Dashboard + Cấu hình gửi nhanh verified clean per audit "No change" verdict.

## Scope

Per audit report (32-AUDIT-REPORT.md) for the 4 files in this plan's batch:

| File | Verdict | Plan action |
|---|---|---|
| HDSD_ho_so_cong_viec.md | Optional minor update — cross-reference tab "Mới tạo" | **Applied** (critical for tester nối luồng with GAP 1 + GAP 2) |
| HDSD_thong_bao.md | Optional minor update — cross-reference task_assigned VB-đi limitation | **Applied** + bonus annotation of notification_type codes |
| HDSD_dashboard.md | No text change | **Verified clean** (no edit) |
| HDSD_cau_hinh_gui_nhanh.md | No change | **Verified clean** (no edit) |

## Tasks Completed

| Task | Name | Commit | Files | Insertions |
|------|------|--------|-------|------------|
| 1 | HSCV HDSD: subsection "HSCV tự xuất hiện ở tab 'Mới tạo' khi được giao việc" | `6dd32e4` | HDSD_ho_so_cong_viec.md | +12 lines @ line 74 (after Các tab phân loại table) |
| 2 | Dashboard HDSD: verified clean per audit verdict | (no commit) | HDSD_dashboard.md | 0 |
| 3 | Thông báo HDSD: annotate notification_type codes + task_assigned VB-đi limitation note; Cấu hình gửi nhanh HDSD verified clean | `9e1a7d1` | HDSD_thong_bao.md | +2 lines net (annotated row + new paragraph @ line 79); HDSD_cau_hinh_gui_nhanh.md untouched |

## Detailed Changes

### docs/hdsd/HDSD_ho_so_cong_viec.md (commit 6dd32e4)

**Inserted after line 72 (sau dòng "Chuyển tab — bảng tự đưa về trang 1 và tải lại danh sách." trong mục 3.1 Màn hình Danh sách HSCV):**

```markdown
#### HSCV tự xuất hiện ở tab "Mới tạo" khi được giao việc

Có 3 nguồn HSCV xuất hiện ở tab **"Mới tạo"** (trạng thái mặc định khi tạo HSCV):

1. **Cán bộ tự bấm "Tạo hồ sơ mới":** HSCV xuất hiện ở cả tab **"Tôi tạo"** lẫn tab **"Mới tạo"** của chính người tạo. Đây là luồng tạo HSCV chủ động — xem chi tiết ở mục **3.2. Drawer Tạo hồ sơ công việc**.

2. **Lãnh đạo bấm "Tạo và giao việc" trên chi tiết Văn bản đến:** Hệ thống tạo HSCV mới gắn với VB đến đó, đặt người được chọn làm **Người phụ trách**. HSCV xuất hiện ở tab **"Mới tạo"** của người được giao — đồng thời người được giao **nhận chuông thông báo** (loại `task_assigned`) ở góc trên màn hình với nội dung *"Bạn được giao xử lý hồ sơ công việc..."* — bấm vào điều hướng sang HSCV chi tiết. Xem chi tiết luồng nghiệp vụ ở mục **3.6** của [HDSD Văn bản đến](HDSD_van_ban_den.md).

3. **Người soạn bấm "Tạo và giao việc" trên chi tiết Văn bản đi:** Hệ thống tạo HSCV mới gắn với VB đi đó. HSCV cũng xuất hiện ở tab **"Mới tạo"** của người được chọn làm Người phụ trách. **Lưu ý:** hiện tại VB đi giao việc **CHƯA có chuông thông báo** (gap code chưa fix — sẽ bổ sung ở phiên bản sau v3.2+). Người được giao phải tự vào trang **Hồ sơ công việc** để biết có việc mới. Xem chi tiết luồng nghiệp vụ ở mục **3.8** của [HDSD Văn bản đi](HDSD_van_ban_di.md).

Trong cả ba trường hợp, HSCV chi tiết hiển thị link đến văn bản nguồn (đến hoặc đi) ở tab **Văn bản liên kết**. Văn bản nguồn KHÔNG bị di chuyển — vẫn nằm ở trang VB đến/đi gốc của người tiếp nhận / người soạn.
```

**Anchor choice:** placed AFTER the "Các tab phân loại" table — the most semantically correct location because the new subsection explains the WHO/WHERE/WHY of arrivals in tab "Mới tạo" right after that tab was introduced. Cross-references to VB đến 3.6 (where GAP 1 was inserted by Plan 02) and VB đi 3.8 (where GAP 2 was inserted by Plan 02) — closing the bi-directional loop documented in CONTEXT.md `<decisions>`.

**Code evidence supporting the note:**
- `e_office_app_new/backend/src/routes/incoming-doc.ts` lines 909-973 — POST `/:id/giao-viec` (VB đến) has `notifyBell({...type: 'task_assigned'...})` line 956-964 ✓
- `e_office_app_new/backend/src/routes/outgoing-doc.ts` lines 899-926 — POST `/:id/giao-viec` (VB đi) has NO `notifyBell()` call ✓ (gap confirmed)
- `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/page.tsx` lines 42-50 — FILTER_TABS confirms tab `'new'` mapped to "Mới tạo" with status=0 (default when HSCV created)

### docs/hdsd/HDSD_thong_bao.md (commit 9e1a7d1)

**Modified line 74** (annotated each bell icon with its notification_type code in backticks):

Before:
```
| Biểu tượng loại | Mỗi loại có một biểu tượng riêng: dấu tích xanh (ký số thành công), dấu chéo đỏ (ký số thất bại), tài liệu xanh navy (được giao VB đến), giấy tờ teal (được giao việc), bút chì cam (lãnh đạo có ý kiến). Loại khác: chuông xanh teal mặc định. |
```

After:
```
| Biểu tượng loại | Mỗi loại có một biểu tượng riêng: dấu tích xanh (ký số thành công — `sign_completed`), dấu chéo đỏ (ký số thất bại — `sign_failed`), tài liệu xanh navy (được giao VB đến — `incoming_doc_assigned`), giấy tờ teal (được giao việc — `task_assigned`), bút chì cam (lãnh đạo có ý kiến — `leader_note_received`). Loại khác: chuông xanh teal mặc định. |
```

**Inserted new paragraph after the trường data table** (between "Thời gian tương đối" row and "Thông báo của hệ thống" subsection):

```markdown
**Lưu ý phạm vi chuông `task_assigned` (được giao việc):** Chuông này CHỈ phát ra khi lãnh đạo bấm "Tạo và giao việc" trên chi tiết **Văn bản đến** (xem [HDSD Văn bản đến](HDSD_van_ban_den.md) mục 3.6). Khi giao việc từ **Văn bản đi** (xem [HDSD Văn bản đi](HDSD_van_ban_di.md) mục 3.8), hệ thống **CHƯA gửi chuông** cho người được giao trong phiên bản hiện tại — gap code sẽ bổ sung ở phiên bản sau v3.2+. Người được giao từ VB đi cần tự vào trang Hồ sơ công việc (tab "Mới tạo") để biết có việc mới.
```

**Code evidence:** 5 bell types confirmed in `e_office_app_new/backend/src/lib/notifications/bell-emit.ts` lines 32-37 (`BellNotificationType` type union). Limitation cross-reference matches Plan 02 GAP 2 already inserted in HDSD_van_ban_di.md mục 3.8.

### docs/hdsd/HDSD_dashboard.md (no change — audit verdict)

Audit per-file section confirms 6 stat cards in HDSD (line 51-56) match `frontend/src/app/(main)/dashboard/page.tsx` lines 199-205 exactly:

| HDSD label | Code (page.tsx line) |
|---|---|
| VB đến chưa đọc | line 199 — `incoming_unread`, route `/van-ban-den` |
| VB đi chờ duyệt | line 200 — `outgoing_pending`, route `/van-ban-di` |
| Hồ sơ công việc | line 201 — `handling_total`, route `/ho-so-cong-viec` |
| Việc quá hạn | line 202 — `handling_overdue`, route `/ho-so-cong-viec` |
| Dự thảo chờ phát hành | line 203 — `drafting_pending`, route `/van-ban-du-thao` |
| Thông báo chưa đọc | line 205 — `notice_unread`, route `/thong-bao` |

2 charts ("Văn bản đến/đi theo tháng" + "HSCV theo trạng thái"), 2 tables ("Văn bản mới nhận" + "Văn bản đi mới"), khung "Việc sắp tới hạn", 4 nút Thao tác nhanh — all verified match. Empty-state messages ("Chưa có văn bản mới", "Chưa có văn bản đi mới", "Không có việc sắp tới hạn", "Chưa có dữ liệu") all preserved.

**Verdict:** No text change applied. Dashboard screenshot retake is Plan 06 responsibility (low priority — aesthetic only per audit).

### docs/hdsd/HDSD_cau_hinh_gui_nhanh.md (no change — audit verdict)

Audit per-file section confirms UI khớp — "Lưu cấu hình (N người) / Tìm kiếm / Ô chọn dòng / Bỏ / Phân trang" all match `cau-hinh-gui-nhanh/page.tsx`. Menu sidebar (MainLayout.tsx line 157): `/cau-hinh-gui-nhanh` not hidden. No workflow gap, no field diff, no notification diff.

**Verdict:** No text change applied.

## Verification

Per Plan 03 verification block:

- `grep -c "HSCV tự xuất hiện" docs/hdsd/HDSD_ho_so_cong_viec.md` → **1 match** ≥ 1 ✓
- `grep -c "task_assigned|Giao việc|Bạn vừa được giao việc|được giao việc" docs/hdsd/HDSD_thong_bao.md` → **3 matches** ≥ 1 ✓

Per `must_haves.truths`:
- ✓ HDSD_ho_so_cong_viec.md has note that VB tự xuất hiện ở tab 'Mới tạo' khi được giao việc (line 74 + sub-points 2 & 3 covering both VB đến + VB đi)
- ✓ All 4 files (HSCV, Dashboard, Thông báo, Cấu hình gửi nhanh) reflect current UI per audit report (2 updated, 2 verified clean per audit verdict)
- ✓ task_assigned notification correctly described in HDSD_thong_bao.md (notification_type code annotated + scope limitation note added)

Per `must_haves.artifacts`:
- ✓ `docs/hdsd/HDSD_ho_so_cong_viec.md` provides HSCV HDSD with giao-việc-arrival note, contains "Mới tạo"
- ✓ `docs/hdsd/HDSD_dashboard.md` provides Dashboard HDSD aligned with current widgets (verified clean)
- ✓ `docs/hdsd/HDSD_thong_bao.md` provides Thông báo HDSD with task_assigned notification documented
- ✓ `docs/hdsd/HDSD_cau_hinh_gui_nhanh.md` provides Cấu hình gửi nhanh HDSD aligned (verified clean)

Per `must_haves.key_links`:
- ✓ HDSD_ho_so_cong_viec.md cross-references HDSD_van_ban_den.md mục 3.6 (GAP 1 from Plan 02) via "Xem chi tiết luồng nghiệp vụ ở mục 3.6 của HDSD Văn bản đến"
- ✓ HDSD_ho_so_cong_viec.md cross-references HDSD_van_ban_di.md mục 3.8 (GAP 2 from Plan 02) via "Xem chi tiết luồng nghiệp vụ ở mục 3.8 của HDSD Văn bản đi"

## Deviations from Plan

**1. [Rule 2 - Critical functionality] Added notification_type code annotations to bell icon row in HDSD_thong_bao.md**

- **Found during:** Task 3 (Thông báo HDSD update)
- **Issue:** Audit report explicitly says HDSD_thong_bao.md "Lưu ý: hiện chỉ áp dụng cho **giao việc từ VB đến**" optional cross-reference was missing. While updating, tester would also benefit from explicit `notification_type` code names — these are the strings backend devs grep for when debugging. The HDSD already lists 5 bell icons visually but did not name the code constants.
- **Fix:** Inline-annotated each bell icon with its backend constant (`sign_completed`, `sign_failed`, `incoming_doc_assigned`, `task_assigned`, `leader_note_received`) — these are the verbatim values defined in `bell-emit.ts` `BellNotificationType` union type.
- **Files modified:** docs/hdsd/HDSD_thong_bao.md (line 74)
- **Commit:** 9e1a7d1

**Beyond this deviation, plan executed exactly as written.** Audit "No change" verdict honored for HDSD_dashboard.md + HDSD_cau_hinh_gui_nhanh.md.

## Downstream Effect

- **Plan 32-06 (screenshots):** No new screenshots needed for these 4 files — UI unchanged. HDSD_dashboard.md dashboard_01_main.png is optional retake per audit (low priority).
- **Plan 32-07 (re-merge HDSD_full.md):** Must re-merge updated HDSD_ho_so_cong_viec.md + HDSD_thong_bao.md into `HDSD_full.md` after all text-update plans (02-05) complete.
- **Plan 32-08 (export DOCX):** Pandoc will auto-pick up new text after re-merge.
- **Phase 21 backlog (v3.2+):** This SUMMARY documents in 2 places that VB đi giao việc bell is missing — explicit forward reference points reviewer to the gap that needs code fix in v3.2.

## Self-Check: PASSED

**Files modified (verified):**
- `docs/hdsd/HDSD_ho_so_cong_viec.md` — FOUND, contains "HSCV tự xuất hiện ở tab" marker @ line 74
- `docs/hdsd/HDSD_thong_bao.md` — FOUND, contains "phạm vi chuông `task_assigned`" marker @ line 79
- `docs/hdsd/HDSD_dashboard.md` — FOUND (untouched per audit verdict)
- `docs/hdsd/HDSD_cau_hinh_gui_nhanh.md` — FOUND (untouched per audit verdict)

**Commits verified (git log):**
- `6dd32e4` — FOUND (Task 1, HSCV HDSD cross-reference note)
- `9e1a7d1` — FOUND (Task 3, Thông báo HDSD annotations)
- Task 2 (Dashboard) — no commit, file intentionally unchanged per audit verdict

All truths in plan frontmatter `must_haves` satisfied.
