---
phase: 32-hdsd-audit-update
plan: 07
subsystem: docs
tags: [hdsd, markdown, merge, node-script, pandoc-prep]

# Dependency graph
requires:
  - phase: 32-hdsd-audit-update
    provides: "Plans 02-04 — Updated 20 HDSD_*.md module files with 3 GAP subsections inserted"
provides:
  - "docs/hdsd/HDSD_full.md re-merged (4496 lines) — single source for pandoc export in Plan 32-08"
  - "tools/screenshots/merge-and-export.js — added --merge-only flag for separating merge from export"
affects: [32-08-export-docx, future-hdsd-updates]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "merge-only flag pattern on combined merge+export scripts so Wave 3 (merge) and Wave 3 (export) plans run independently"

key-files:
  created: []
  modified:
    - "docs/hdsd/HDSD_full.md (4424 → 4496 lines, +72 lines from Plans 02-04 GAP insertions)"
    - "tools/screenshots/merge-and-export.js (added --merge-only flag)"

key-decisions:
  - "Option A — Reuse merge-and-export.js with new --merge-only flag (vs Option B = new script). Reason: existing script already encodes all merge logic (heading demotion, auto-numbering, screenshot fallback, link stripping). Adding a flag is 8 lines vs duplicating 100+ lines."
  - "Merge order from MODULES array in merge-and-export.js is authoritative — already aligned with HDSD_index.md sections 5.1 → 5.6."
  - "Did NOT change MODULES array order — verified existing order matches HDSD_index.md."

patterns-established:
  - "Pattern: When a build script does merge + export in one go but downstream waves need to isolate them, add a --merge-only flag rather than splitting into two files. Keeps a single source of merge truth."

requirements-completed: []

# Metrics
duration: 2min
completed: 2026-05-11
---

# Phase 32 Plan 07: Re-merge HDSD_full.md Summary

**Re-merged HDSD_full.md (4496 lines) from 20 module files via merge-and-export.js --merge-only; all 3 GAP subsections from Plans 02-04 now present; all 82 unique screenshot references resolve.**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-11T04:48:36Z
- **Completed:** 2026-05-11T04:50:15Z
- **Tasks:** 2 (Task 1 analysis-only, Task 2 commit)
- **Files modified:** 2

## Accomplishments

- HDSD_full.md regenerated: 4424 → 4496 lines (+72 lines from 3 GAP subsections inserted in Plans 02-04)
- All 20 module files concatenated in HDSD_index.md order (verified against existing MODULES array)
- All 3 mandatory GAP subsections present in merged output (line numbers below)
- All 82 unique `screenshots/*.png` references resolve to existing files in `docs/hdsd/screenshots/`
- merge-and-export.js gained `--merge-only` flag so Plan 32-08 (docx export) can run independently

## Task Commits

1. **Task 1: Determine merge order + check existing merge tool** — _no commit (analysis only, no file changes)._
   Decision recorded inline in this Summary: **Option A — Reuse merge-and-export.js with new --merge-only flag.**
2. **Task 2: Execute merge → produce updated HDSD_full.md** — `5c2e981` (docs)

## Files Created/Modified

- `docs/hdsd/HDSD_full.md` — Re-merged from 20 modules; 4496 lines, 252 KB. Includes 3 GAP subsections.
- `tools/screenshots/merge-and-export.js` — Added `MERGE_ONLY` constant + `--merge-only` flag handler before pandoc step.

## GAP Subsections — Final Positions in HDSD_full.md

| # | Heading | Line | Source module |
|---|---|---|---|
| GAP 1 (VB đến) | `##### 4.3.6.5. Sau khi giao việc — văn bản xuất hiện ở đâu của TK được giao?` | 827 | HDSD_van_ban_den.md |
| GAP 2 (VB đi — luồng gửi) | `##### 5.3.7.5. Luồng kỹ thuật khi Gửi (3 bước nối tiếp)` | 1240 | HDSD_van_ban_di.md |
| GAP 3 (VB đi — giao việc) | `##### 5.3.8.5. Sau khi giao việc — văn bản xuất hiện ở đâu?` + `KHÔNG có chuông thông báo` (gap note) | 1299, 1305 | HDSD_van_ban_di.md |

Cross-reference also added to HDSD_van_ban_du_thao.md (line 1582 of full.md) pointing readers to Section 3.7 of VB đi for the technical send flow.

## Module Chapter Anchors in Phần I (after re-merge)

| Chapter | Module | Line in HDSD_full.md |
|---|---|---|
| 1 | Đăng nhập và Thông tin cá nhân | 71 |
| 2 | Tổng quan (Dashboard) | 235 |
| 3 | Thông báo nội bộ | 360 |
| 4 | Văn bản đến | 530 |
| 5 | Văn bản đi | 930 |
| 6 | Văn bản dự thảo | 1345 |
| 7 | Đánh dấu cá nhân | 1666 |
| 8 | Cấu hình gửi nhanh | 1755 |
| 9 | Hồ sơ công việc | 1838 |
| 10 | Cấu hình ký số hệ thống | 2654 |
| 11 | Tài khoản ký số cá nhân | 2829 |
| 12 | Danh sách ký số | 2926 |
| 13 | Quản trị đơn vị | 3155 |
| 14 | Quản trị chức vụ | 3341 |
| 15 | Quản trị người dùng | 3508 |
| 16 | Quản trị nhóm quyền | 3805 |
| 17 | Quản lý sổ văn bản | 3998 |
| 18 | Quản lý loại văn bản | 4136 |
| 19 | Quản lý lĩnh vực | 4264 |
| 20 | Quản lý người ký | 4384 |

Order is consistent with `HDSD_index.md` sections 5.1 (Tổng quan/cá nhân: 1-3) → 5.2 (Văn bản: 4-8) → 5.3 (HSCV: 9) → 5.4 (Ký số: 10-12) → 5.5 (Quản trị: 13-16) → 5.6 (Danh mục: 17-20).

## Decisions Made

- **Reuse merge-and-export.js with a `--merge-only` flag** rather than writing a new merge-only script. Rationale: the existing script encodes 100+ lines of merge logic (heading demotion based on H1 context, auto-numbering H2..H5 with chapter restart at "Phần I", screenshot existence fallback to italic caption, markdown link stripping, horizontal rule stripping). Duplicating this in a new file would be a maintenance liability — Plan 32-08 will reuse the same script (without `--merge-only`) to do the full merge+pandoc pipeline.
- **Did not touch MODULES array order** — verified the existing order in `merge-and-export.js` already follows `HDSD_index.md` sections 5.1 → 5.6. Re-ordering would risk breaking continuity of cross-references in module text (e.g., "see Section 3.7 of VB đi").

## Deviations from Plan

**None — plan executed exactly as written.**

The plan specified Option A vs Option B; Option A was chosen and executed faithfully. The `--merge-only` flag implementation is a small additive change (8 lines) that does not affect default behavior — running `node merge-and-export.js` without the flag still performs the full merge + pandoc pipeline as before.

## Issues Encountered

- **Plan's automated PowerShell verification command failed with `-match` on Vietnamese diacritics** (output: `g1=False g2=False g3=False`). Root cause: PS 5.1 default encoding does not handle UTF-8 multibyte characters in `-match` regex. **Re-ran verification with explicit UTF-8 encoding** (`Get-Content -Encoding UTF8` + `String.Contains()` instead of `-match`) — all 3 GAPs verified PASS. Content of HDSD_full.md is correct; only the verification harness needed encoding awareness. (Same pitfall noted in CLAUDE.md item 1 — "PowerShell 5.1 + UTF-8 no BOM".)

## Self-Check: PASSED

**Files verified:**
- `docs/hdsd/HDSD_full.md` — exists, 4496 lines (≥ 4400 required).
- `tools/screenshots/merge-and-export.js` — exists with `--merge-only` flag.
- `.planning/phases/32-hdsd-audit-update/32-07-SUMMARY.md` — this file.

**Commits verified:**
- `5c2e981` — present in `git log` on branch `v3.1/phase-21-foundation`.

**Verification commands re-run:**
- Line count: 4496 ≥ 4400 ✓
- GAP 1 present (line 827) ✓
- GAP 2 present (line 1240) ✓
- GAP 3 present (lines 1299, 1305) ✓
- Screenshot refs: 82 unique, 0 missing ✓

## User Setup Required

None — no external service configuration required. This is a pure documentation merge step.

## Next Phase Readiness

- **Plan 32-08 (Export HDSD_full.docx via pandoc) is unblocked.** It can either:
  1. Run `node tools/screenshots/merge-and-export.js` (no flag) to do merge + export in one shot — recommended for consistency.
  2. Run `pandoc docs/hdsd/HDSD_full.md -o docs/hdsd/HDSD_full.docx ...` directly using the current merged file — works since merged file is ready.

- **No blockers.** All 20 module HDSD files are settled (Plans 02-05) and screenshots (Plan 06) are in place — the merged document references 82 PNGs that all exist on disk.

---
*Phase: 32-hdsd-audit-update*
*Completed: 2026-05-11*
