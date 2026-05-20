---
phase: 32-hdsd-audit-update
plan: 06
subsystem: docs/hdsd/screenshots
tags: [docs, hdsd, screenshots, playwright]
requires:
  - 32-AUDIT-REPORT.md retake list
provides:
  - "Updated PNG screenshots reflecting Phase 21 LGSP + Phase 31 fix-gom UI"
affects:
  - docs/hdsd/screenshots/*.png (6 files overwritten)
  - tools/screenshots/capture-phase32.js (new script)
tech-stack:
  added: []
  patterns:
    - "Focused Playwright recapture (only the 6 flagged PNGs, not blanket re-run)"
    - "page.waitForFunction() for portal-rendered AntD modal detection (avoids :visible flakiness)"
key-files:
  created:
    - tools/screenshots/capture-phase32.js
  modified:
    - docs/hdsd/screenshots/dashboard_01_main.png
    - docs/hdsd/screenshots/van_ban_den_04_detail.png
    - docs/hdsd/screenshots/van_ban_den_06_drawer_giao_viec.png
    - docs/hdsd/screenshots/van_ban_di_05_detail.png
    - docs/hdsd/screenshots/van_ban_di_07_modal_send_internal.png
    - docs/hdsd/screenshots/van_ban_di_08_drawer_giao_viec.png
decisions:
  - "Created focused capture-phase32.js (220 lines) instead of running broad capture-all-rev3-fix5.js — avoids overwriting ~80 unrelated PNGs and reduces risk."
  - "Used admin/Admin@123 test account (seed/002) for all captures — no real PII."
  - "Picked VB đi id=4 (approved=true, is_released=false, recipients=[]) for modal Ban hành & Gửi capture — only such state opens the modal (page.tsx handleReleaseAndSend line 337)."
  - "Picked VB đi id=1005 (sent, fully populated) for detail + Giao việc drawer — best layout coverage."
  - "Picked VB đến id=1025 (most recent) for detail + Giao việc drawer — Giao việc button is always visible on VB đến (page.tsx line 425)."
metrics:
  duration_minutes: 12
  completed: 2026-05-11
  task_count: 4
  files_modified: 7
---

# Phase 32 Plan 06: Re-capture HDSD Screenshots Summary

Re-captured 6 HDSD screenshots flagged by `32-AUDIT-REPORT.md` using a new focused Playwright script (`tools/screenshots/capture-phase32.js`). All target PNGs in `docs/hdsd/screenshots/` overwritten while preserving filenames so MD `![](screenshots/...)` references continue to resolve.

## Tasks Completed

| Task | Name                                                       | Status                     | Commit    |
| ---- | ---------------------------------------------------------- | -------------------------- | --------- |
| 1    | Verify dev servers running + DB seeded                     | Pre-approved by orchestrator (no manual check needed) | n/a       |
| 2    | Determine viewport + active capture script                 | Done                       | `3245f00` |
| 3    | Run Playwright capture(s) — overwrite flagged screenshots  | Done                       | `55916ae` |
| 4    | Verify all HDSD screenshot references resolve              | Done (verification-only)   | n/a       |

## Viewport Investigation (Task 2)

Inspected 7 existing baseline PNGs via PowerShell `System.Drawing` — all share **width 1440px**, heights vary 900-1741px (fullPage captures expand to content height while modal captures stay at viewport 900).

| File                                      | Existing dim |
| ----------------------------------------- | ------------ |
| `van_ban_den_01_main.png`                 | 1440x1741    |
| `van_ban_den_04_detail.png`               | 1440x1164    |
| `van_ban_den_06_drawer_giao_viec.png`     | 1440x1330    |
| `van_ban_di_05_detail.png`                | 1440x1177    |
| `van_ban_di_07_modal_send_internal.png`   | 1440x900     |
| `van_ban_di_08_drawer_giao_viec.png`      | 1440x1177    |
| `dashboard_01_main.png`                   | 1440x1446    |

Decision: viewport `{ width: 1440, height: 900 }` — matches existing `capture-all-rev3-fix5.js` and `capture-detail3.js`.

## New Capture Script

**Path:** `tools/screenshots/capture-phase32.js` (220 lines)

Why a new focused script instead of re-running existing scripts:
- `capture-main.js`, `capture-all-rev3.js`, `capture-detail3.js` together cover ~80 PNGs. Re-running them all would overwrite many PNGs unrelated to this audit — wasted work + risk of changing screenshots that are still correct.
- The audit flagged exactly 6 PNGs for retake. A focused script targets only those 6, keeping the diff minimal.

Reused patterns from `capture-all-rev3-fix5.js`:
- `login(page)` helper
- `apiFetch(page, urlPath)` via `localStorage.accessToken` Bearer
- `snap(page, file, opts)` with `fullPage` toggle
- `runCase(label, fn, results)` per-case try/catch (best-effort, batch never aborts)

## Capture Results

All 6/6 captured successfully on second run:

| File                                      | Size  | Dim       | Source page                                |
| ----------------------------------------- | ----- | --------- | ------------------------------------------ |
| `dashboard_01_main.png`                   | 256 KB | 1440x1446 | `/dashboard` (admin)                       |
| `van_ban_den_04_detail.png`               | 138 KB | 1440x1165 | `/van-ban-den/1025` (admin)                |
| `van_ban_den_06_drawer_giao_viec.png`     | 156 KB | 1440x1165 | `/van-ban-den/1025` + Giao việc drawer     |
| `van_ban_di_05_detail.png`                | 170 KB | 1440x1171 | `/van-ban-di/1005` (sent, full status)     |
| `van_ban_di_07_modal_send_internal.png`   | 164 KB | 1440x900  | `/van-ban-di/4` + "Ban hành & Gửi" modal   |
| `van_ban_di_08_drawer_giao_viec.png`      | 164 KB | 1440x1171 | `/van-ban-di/1005` + Giao việc drawer      |

## Verification (Task 4)

PowerShell regex scan across all 22 `docs/hdsd/HDSD_*.md` files:

- **Total `![](screenshots/...)` references:** 196
- **Missing PNGs:** 0
- **Total PNGs in `docs/hdsd/screenshots/`:** 136 (>= 50 baseline)

All 196 references resolve. No MD links broken.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed modal detection in capture-phase32.js**

- **Found during:** Task 3 first run
- **Issue:** Initial code used `page.waitForSelector('.ant-modal-content:has-text("chọn đơn vị nhận")')` to detect that the "Ban hành & Gửi" modal had opened. AntD 6 renders modals into a React portal with fade-in animation; Playwright's `:visible` pseudo-selector and `:has-text()` on `.ant-modal-content` were both flaky against the portal — selector resolved `count=0` even though the modal was clearly rendered (confirmed by capturing a debug screenshot of the post-click state — modal was visible with correct title and dept checkboxes).
- **Fix:** Replaced selector-based detection with `page.waitForFunction()` that probes `document.querySelectorAll('.ant-modal-title')` for textContent containing `'chọn đơn vị nhận'` (the literal title from `page.tsx` line 916). This bypasses the portal/visibility quirk entirely.
- **Files modified:** `tools/screenshots/capture-phase32.js` (case 5 block, lines ~196-209)
- **Commit:** Folded into `55916ae` (Task 3 commit) along with the captured PNGs since the script fix was discovered mid-execution
- **Result:** Second run produced 6/6 OK.

## Authentication Gates

None encountered. Backend health, frontend health, and admin login were pre-approved by the orchestrator (verified before plan launch per `<pre_approved_checkpoint>` block in the prompt).

## Known Stubs

None. All captures show real production-ready UI with seeded test data — no placeholder text, no empty states except where empty state is the correct UX (e.g., empty "Ý kiến lãnh đạo (0)" panel in VB đi detail because no opinions were posted yet — this is realistic, not a stub).

## Self-Check: PASSED

- **Files exist:**
  - `D:\ProjectAI\quanlyvanban\tools\screenshots\capture-phase32.js` — FOUND
  - `D:\ProjectAI\quanlyvanban\docs\hdsd\screenshots\dashboard_01_main.png` — FOUND
  - `D:\ProjectAI\quanlyvanban\docs\hdsd\screenshots\van_ban_den_04_detail.png` — FOUND
  - `D:\ProjectAI\quanlyvanban\docs\hdsd\screenshots\van_ban_den_06_drawer_giao_viec.png` — FOUND
  - `D:\ProjectAI\quanlyvanban\docs\hdsd\screenshots\van_ban_di_05_detail.png` — FOUND
  - `D:\ProjectAI\quanlyvanban\docs\hdsd\screenshots\van_ban_di_07_modal_send_internal.png` — FOUND
  - `D:\ProjectAI\quanlyvanban\docs\hdsd\screenshots\van_ban_di_08_drawer_giao_viec.png` — FOUND
- **Commits exist:**
  - `3245f00` — FOUND (Task 2)
  - `55916ae` — FOUND (Task 3)
- **PNG dimensions match baseline viewport:** width=1440 across all 6 — confirmed
- **HDSD MD references resolve:** 196/196 — confirmed
