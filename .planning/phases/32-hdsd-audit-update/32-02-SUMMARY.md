---
phase: 32-hdsd-audit-update
plan: 02
subsystem: docs/hdsd
tags: [hdsd, documentation, vb-den, vb-di, vb-du-thao, vb-danh-dau, gap-fill]
dependency_graph:
  requires:
    - 32-01-SUMMARY.md (audit report — 3 critical GAPs identified)
    - 32-CONTEXT.md `<specifics>` blocks 1 & 2 (verbatim text)
  provides:
    - HDSD_van_ban_den.md with GAP 1 filled (mục 3.6)
    - HDSD_van_ban_di.md with GAP 2 (mục 3.8) + GAP 3 (mục 3.7) filled
    - HDSD_van_ban_du_thao.md with cross-ref to VB đi mục 3.7
    - HDSD_van_ban_danh_dau.md (reviewed, no change per audit)
  affects:
    - Plan 32-07 (re-merge HDSD_full.md must pull updated text from these 4 files)
    - Plan 32-06 (Playwright screenshots may need to re-capture mục 3.6/3.7/3.8 to match new captions)
tech_stack:
  added: []
  patterns:
    - Verbatim text insertion from CONTEXT.md `<specifics>` blocks (no paraphrase)
    - Idempotent doc updates (no duplicate subsections)
    - Cross-reference linking between HDSD files via relative markdown links
key_files:
  created: []
  modified:
    - docs/hdsd/HDSD_van_ban_den.md (+14 lines — GAP 1 subsection after mục 3.6 Thông báo table)
    - docs/hdsd/HDSD_van_ban_di.md (+42 lines — GAP 3 in mục 3.7 + GAP 2 in mục 3.8)
    - docs/hdsd/HDSD_van_ban_du_thao.md (+2 lines — optional cross-ref in mục 3.6 → VB đi mục 3.7)
decisions:
  - "GAP text inserted verbatim from CONTEXT.md `<specifics>` — no paraphrase, no embellishment"
  - "Optional cross-ref applied to HDSD_van_ban_du_thao.md mục 3.6 (audit-recommended nice-to-have): link Phát hành flow to VB đi mục 3.7 GAP 3"
  - "HDSD_van_ban_danh_dau.md untouched per audit verdict 'No change' (read-only screen, no workflow gaps)"
metrics:
  duration: ~3 minutes
  completed: 2026-05-11
  tasks: 3
  files_modified: 3
  files_reviewed: 4
---

# Phase 32 Plan 02: Update text 4 VB HDSD files (đến, đi, dự thảo, đánh dấu) Summary

**One-liner:** Inserted 3 tester-reported GAPs verbatim into VB đến (mục 3.6) and VB đi (mục 3.7 + 3.8), plus 1 optional cross-reference in VB dự thảo mục 3.6 → VB đi mục 3.7. VB đánh dấu reviewed clean per audit verdict.

## Scope

Per audit report (32-AUDIT-REPORT.md):

- **Bắt buộc**: GAP 1 (VB đến 3.6), GAP 2 (VB đi 3.8), GAP 3 (VB đi 3.7)
- **Optional applied**: 1-line cross-ref VB dự thảo mục 3.6 → VB đi mục 3.7
- **No change**: VB đánh dấu (audit verdict)

## Tasks Completed

| Task | Name | Commit | Files | Insertions |
|------|------|--------|-------|------------|
| 1 | GAP 1: HDSD_van_ban_den.md — subsection "Sau khi giao việc — văn bản xuất hiện ở đâu của TK được giao?" | `66ab22b` | HDSD_van_ban_den.md | +14 lines @ line 298 (sau bảng Thông báo mục 3.6) |
| 2 | GAP 2 (3.8) + GAP 3 (3.7): HDSD_van_ban_di.md — "Luồng kỹ thuật khi Gửi (3 bước nối tiếp)" + "Sau khi giao việc — văn bản xuất hiện ở đâu?" | `a9598b0` | HDSD_van_ban_di.md | +42 lines (GAP 3 @ line 311, GAP 2 @ line 370) |
| 3 | Cross-ref VB dự thảo mục 3.6 → VB đi mục 3.7; VB đánh dấu reviewed clean | `d02b456` | HDSD_van_ban_du_thao.md | +2 lines @ line 238 (cuối mục 3.6) |

## Detailed Changes

### docs/hdsd/HDSD_van_ban_den.md (commit 66ab22b)

**Inserted after line 296 (sau dòng "Không có quyền giao xử lý văn bản đến này" của bảng Thông báo trong mục 3.6 Drawer giao việc):**

```markdown
#### Sau khi giao việc — văn bản xuất hiện ở đâu của TK được giao?

Khi bấm "Tạo và giao việc", hệ thống tạo một Hồ sơ công việc (HSCV) mới và liên kết với văn bản đến này:

1. **TK được chọn làm Người phụ trách** sẽ nhận:
   - **Chuông thông báo** (góc trên màn hình) với nội dung "Bạn vừa được giao việc..." — bấm vào điều hướng sang HSCV chi tiết.
   - HSCV mới xuất hiện ở trang **Hồ sơ công việc** (menu trái), tab **"Mới tạo"** (status mặc định khi giao việc).

2. **Vào chi tiết HSCV**, người được giao thấy:
   - Thông tin HSCV (tên, ngày bắt đầu, hạn, ghi chú, người phụ trách)
   - Văn bản đến nguồn được link sẵn — bấm để mở chi tiết văn bản

3. **Văn bản đến** vẫn nằm ở trang VB đến cũ của người tiếp nhận ban đầu (lãnh đạo) — KHÔNG bị chuyển đi.
```

Verbatim từ CONTEXT.md `<specifics>` block 1 (lines 188-206).

### docs/hdsd/HDSD_van_ban_di.md (commit a9598b0)

**GAP 3 — Inserted after line 309 (sau bảng "Thông báo của hệ thống" mục 3.7 Modal gửi nội bộ):**

```markdown
#### Luồng kỹ thuật khi Gửi (3 bước nối tiếp)

Khi bấm nút "Ban hành & Gửi" hoặc "Gửi" trong modal, hệ thống thực hiện 3 bước nối tiếp:

**Bước 1 — Lưu danh sách đơn vị nhận:**
- Mỗi đơn vị/cơ quan được chọn được lưu thành 1 dòng trong bảng `outgoing_doc_recipients` với `sent_status='pending'`.
- Phân loại: `internal_unit` (đơn vị trong tỉnh) hoặc `external_org` (cơ quan ngoài tỉnh — gửi qua LGSP).

**Bước 2 — Ban hành cấp số:**
- Hệ thống cấp số văn bản đi chính thức và đánh dấu `is_released = TRUE`.
- Trạng thái văn bản đi chuyển sang **"Đã ban hành"**.

**Bước 3 — Gửi (loop từng recipient):**

- **Nếu là đơn vị Nội bộ:** Hệ thống tự sinh 1 Văn bản đến cho đơn vị nhận:
  - Văn bản đến nằm ngay ở trang **Văn bản đến** của đơn vị nhận, trạng thái "Chưa duyệt".
  - Người nhận có thể đăng nhập và xử lý ngay (duyệt → giao việc → ban hành công văn trả lời...).
  - Số văn bản đến được cấp tự động theo sổ của đơn vị nhận.

- **Nếu là cơ quan ngoài LGSP:** Hệ thống tạo bản ghi trong `lgsp_tracking` (trạng thái `pending`):
  - Badge **"Đang chờ worker đẩy LGSP"** hiển thị ở khung "Đơn vị / Cơ quan nhận" trên trang chi tiết.
  - Worker BullMQ (`lgsp-send`) sẽ pick lên, gọi API LGSP thật (apiltvb.langson.gov.vn), update trạng thái → `success` / `error`.
  - Khi worker xong, badge đổi thành **"Đã gửi LGSP"** hoặc **"Lỗi gửi LGSP"** (kèm thông báo lỗi).

Trạng thái cuối cùng của văn bản đi: **"Đã gửi"** (nội bộ done ngay, LGSP đợi worker).
```

Verbatim từ CONTEXT.md `<specifics>` block 2 (lines 213-238).

**GAP 2 — Inserted after line 368 (sau bảng "Thông báo" mục 3.8 Drawer giao việc):**

```markdown
#### Sau khi giao việc — văn bản xuất hiện ở đâu?

Khi bấm "Tạo và giao việc" trong Drawer giao việc của VB đi, hệ thống tạo một Hồ sơ công việc (HSCV) mới liên kết với văn bản đi này:

1. **TK được chọn làm Người phụ trách** sẽ thấy:
   - HSCV mới xuất hiện ở trang **Hồ sơ công việc** (menu trái), tab **"Mới tạo"**.
   - **KHÔNG có chuông thông báo** (gap code chưa fix — sẽ bổ sung ở phiên bản sau v3.2+). Người được giao phải tự vào trang HSCV để biết có việc mới.

2. **Vào chi tiết HSCV**, người được giao thấy:
   - Thông tin HSCV (tên, ngày bắt đầu, hạn, ghi chú, người phụ trách).
   - Văn bản đi nguồn được link sẵn — bấm để mở chi tiết văn bản.

3. **Văn bản đi** vẫn nằm ở trang VB đi của người soạn — KHÔNG bị chuyển đi.

**Lưu ý:** form Drawer giao việc VB đi hiện KHÔNG validate `Người phụ trách` rỗng và `Hạn hoàn thành` rỗng — đề nghị người dùng nhập đủ các trường trước khi bấm Tạo. Validation sẽ bổ sung ở phiên bản sau (v3.2+).
```

Text mới (audit report nội dung), phản ánh 2 gap code:
1. VB đi giao việc KHÔNG có `notifyBell()` call (backend grep: 0 matches `task_assigned` trong `outgoing-doc.ts` line 899-926).
2. Backend KHÔNG validate `end_date` + `curator_ids` rỗng (so với VB đến route line 927-934 vốn yêu cầu `end_date`).

### docs/hdsd/HDSD_van_ban_du_thao.md (commit d02b456)

**Inserted after line 236 (sau dòng "Không có quyền phát hành văn bản này" cuối mục 3.6 Confirm phát hành):**

```markdown
> **Lưu ý nghiệp vụ:** sau khi Phát hành, dự thảo trở thành một Văn bản đi mới (ID hiển thị ngay trên hộp thoại thành công). Văn bản đi mới ở trạng thái "Đã duyệt" — chưa được Ban hành cấp số và chưa Gửi. Toàn bộ luồng kỹ thuật khi Ban hành cấp số và Gửi tới các đơn vị nhận (nội bộ + LGSP) được mô tả tại mục **3.7 — Luồng kỹ thuật khi Gửi (3 bước nối tiếp)** trong [HDSD Văn bản đi](HDSD_van_ban_di.md).
```

Optional cross-ref recommended by audit (verdict: "Optional 1 dòng cross-reference"). Giúp tester nối flow dự thảo → VB đi.

### docs/hdsd/HDSD_van_ban_danh_dau.md

Reviewed — KHÔNG modify. Audit verdict: "No change". File mô tả màn hình read-only (đánh dấu cá nhân), không có workflow gap, không có button/menu mới ở Phase 31, không có schema field change.

## Verification

Toàn bộ verify automated bằng PowerShell + Grep:

- `grep "Sau khi giao việc — văn bản xuất hiện ở đâu của TK được giao" HDSD_van_ban_den.md` → 1 match @ line 298
- `grep "TK được chọn làm Người phụ trách" HDSD_van_ban_den.md` → 1 match
- `grep "Luồng kỹ thuật khi Gửi" HDSD_van_ban_di.md` → 1 match @ line 311
- `grep "outgoing_doc_recipients" HDSD_van_ban_di.md` → 1 match @ line 316
- `grep "lgsp_tracking" HDSD_van_ban_di.md` → 1 match @ line 330
- `grep "KHÔNG có chuông thông báo" HDSD_van_ban_di.md` → 1 match @ line 376
- `grep "Sau khi giao việc" HDSD_van_ban_di.md` → 1 match @ line 370
- 4 target files tồn tại (HDSD_van_ban_den/di/du_thao/danh_dau.md)

Tất cả PASS.

## Deviations from Plan

None — plan executed exactly as written. 3 GAP texts inserted verbatim, 1 optional cross-ref applied per audit recommendation, danh_dau.md reviewed-only per audit verdict.

## Downstream Effect

- **Plan 32-06 (screenshots):** Captions for 3 screenshots (`van_ban_den_06_drawer_giao_viec.png`, `van_ban_di_07_modal_send_internal.png`, `van_ban_di_08_drawer_giao_viec.png`) sẽ ăn theo subsections mới được insert ở plan này. Screenshot retake không bắt buộc đổi content (UI không đổi) — chỉ caption fresh.
- **Plan 32-07 (re-merge HDSD_full.md):** Phải re-merge 4 file con đã update vào `HDSD_full.md` (sau khi 32-03, 32-04, 32-05 hoàn tất).
- **Plan 32-08 (export DOCX):** Sau re-merge, pandoc export tự pick up text mới.

## Self-Check: PASSED

**Files created (modified):**
- `docs/hdsd/HDSD_van_ban_den.md` — FOUND, contains GAP 1 marker (line 298)
- `docs/hdsd/HDSD_van_ban_di.md` — FOUND, contains GAP 2 (line 370) + GAP 3 (line 311) markers
- `docs/hdsd/HDSD_van_ban_du_thao.md` — FOUND, contains cross-ref (line 238)
- `docs/hdsd/HDSD_van_ban_danh_dau.md` — FOUND (untouched per audit)

**Commits:**
- `66ab22b` — FOUND (Task 1, GAP 1)
- `a9598b0` — FOUND (Task 2, GAP 2 + GAP 3)
- `d02b456` — FOUND (Task 3, cross-ref + danh_dau review)

Tất cả truths trong plan frontmatter `must_haves` đã được đáp ứng.
