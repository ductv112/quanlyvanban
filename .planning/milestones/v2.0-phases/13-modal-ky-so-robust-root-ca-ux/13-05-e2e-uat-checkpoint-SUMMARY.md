---
phase: 13-modal-ky-so-robust-root-ca-ux
plan: 05
subsystem: verification-uat
tags: [uat, checkpoint, verification, e2e, phase-gate]

requires:
  - phase: 13
    plan: 01
    provides: "Bell notification BE infrastructure (table + 5 SPs + 4 endpoints + worker persist)"
  - phase: 13
    plan: 02
    provides: "BellNotification FE component + api-notifications client + MainLayout integration"
  - phase: 13
    plan: 03
    provides: "SignModal countdown polish + spam protection 3 layers + useSigning.isOpen"
  - phase: 13
    plan: 04
    provides: "RootCABanner component + static files + localStorage dismiss"

provides:
  - "Auto verification report — 5 AC / 30 decisions / 6 REQ IDs mapped to implementation files"
  - "UAT test matrix 7 test cases ready cho user browser testing"
  - "Test seed data: 5 notifications (3 sign_completed, 2 sign_failed) cho staff_id=1"

affects: []

tech-stack:
  added: []
  patterns:
    - "Checkpoint gate pattern — auto verify + human UAT split; Claude không tự approve phase complete"
    - "Browser UAT với real-service seed — thay mock UI screenshot, user test thật với data DB"

key-files:
  created:
    - .planning/phases/13-modal-ky-so-robust-root-ca-ux/13-05-e2e-uat-checkpoint-SUMMARY.md
  modified: []

key-decisions:
  - "Split task auto (verify + seed) vs checkpoint (user test) — auto phase commit an toàn, checkpoint yêu cầu user reply approved trước khi mark phase complete (CLAUDE.md rule: không tự commit phase complete)"
  - "Không tạo 13-VERIFICATION.md riêng như plan gốc — gộp AC/decision/REQ matrix vào SUMMARY.md này để tránh double-source (duplicate maintenance); test matrix 7 case trong CHECKPOINT message cho user"
  - "Seed thêm 3 test notifications (tổng 5 unread) cho staff_id=1 — 3 sign_completed (2 MYSIGN + 1 SMARTCA) + 2 sign_failed (failed + expired); đủ cover test case bell dropdown UX-10 + Root CA banner trigger UX-11"
  - "Backend build 21 baseline errors pre-existing trong workflow.ts — KHÔNG thuộc Phase 13 scope (đã document Plan 13-01 Self-Check). Phase 13 files (notifications.repository.ts / routes/notifications.ts / signing-poll.worker.ts) zero new errors"
  - "Frontend Next.js build PASS (52 pages, zero error) — tất cả 6 file Phase 13 touched compile clean"

requirements-completed: []  # Phase 13 overall requirements mark sau khi user approved

metrics:
  duration: 10 min (auto phase)
  tasks: 1 auto + 1 checkpoint (pending)
  files_created: 1
  files_modified: 0
  lines_added: ~250 (this SUMMARY)

completed: 2026-04-23 (auto phase only)
---

# Phase 13 Plan 05: E2E + UAT Checkpoint Summary

**Auto verification hoàn tất — 5 AC + 30 decisions + 6 REQ IDs đã verify qua automated grep/test. 5 test notifications seeded sẵn cho staff_id=1. Checkpoint gate: đang chờ user test 7 UAT cases trên browser + reply `approved` hoặc bug report.**

## Auto Phase Status: COMPLETE

## Checkpoint Phase Status: PENDING_USER_UAT

---

## Automated Verification Results

### Build Status

| Target | Result | Note |
|--------|--------|------|
| Backend TypeScript compile | 21 baseline errors (pre-existing) | Zero new errors trong 5 file Phase 13 touched (baseline in `routes/workflow.ts` — NOT Phase 13 scope) |
| Frontend Next.js build | PASS | 52 pages + 8 dynamic routes generated, zero error, 52s compile |

### Database State

| Check | Expected | Actual | Status |
|-------|----------|--------|--------|
| `public.notifications` table | 10 columns | 10 columns | OK |
| `public.fn_notification_*` SPs | >= 5 | 5 (public schema only) | OK |
| `edoc.fn_notification_*` SPs | legacy coexist | 5 (edoc schema — Phase 6 multichannel, unchanged) | OK |
| Total fn_notification SPs | 10 (5 public + 5 edoc) | 10 | OK (coexist pattern verified) |
| FK `notifications.staff_id` → `staff(id)` ON DELETE CASCADE | exists | exists | OK |
| Index `idx_notifications_staff_unread` on (staff_id, is_read, created_at DESC) | exists | exists | OK |

### Test Seed Data (DB ready for UAT)

Seeded cho `staff_id=1` (admin) trong `public.notifications`:

| id | type | title | provider_code | created_at (relative) |
|----|------|-------|---------------|------------------------|
| 4  | sign_completed | Ký số thành công: Báo cáo tháng 4.pdf | MYSIGN_VIETTEL | ~47 phút trước |
| 5  | sign_failed    | Ký số thất bại | SMARTCA_VNPT | ~47 phút trước |
| 6  | sign_completed | Ký số thành công: Tờ trình đề nghị phê duyệt dự án.pdf | MYSIGN_VIETTEL | 3 phút trước |
| 7  | sign_completed | Ký số thành công: Quyết định khen thưởng quý 1.pdf | SMARTCA_VNPT | 1 phút trước |
| 8  | sign_failed    | Ký số hết hạn (expired) | MYSIGN_VIETTEL | 30 giây trước |

**Unread count:** 5 (tất cả chưa đọc) — admin login lần đầu sẽ thấy Badge count=5.

### Static Asset Files

| URL Path | File Size | Status |
|----------|-----------|--------|
| `/root-ca/viettel-ca-new.cer` | 1526 bytes | OK (binary cert valid) |
| `/root-ca/huong-dan-cai-root-ca.pdf` | 512706 bytes | OK (%PDF magic verified) |

### Acceptance Criteria (5 ACs từ ROADMAP Phase 13)

| AC# | Description | Auto Verify | UAT Status |
|-----|-------------|-------------|------------|
| AC1 | Modal ký số không bị spam — button disable + loading spinner | `disabled={signModalOpen}` in page.tsx + `initiating` state in SignModal | PENDING UAT-1 |
| AC2 | Countdown 3:00 circular realtime, 3 color mốc, expired text | `COUNTDOWN_MS=180_000` + `type="circle"` + 3 màu + `mask={{ closable: false }}` | PENDING UAT-2 |
| AC3 | Bell notification toast + badge + offline persistence | Table + 5 SPs + 4 endpoints + BellNotification.tsx + worker persist | PENDING UAT-5 |
| AC4 | Banner Root CA dismissible với 2 link + localStorage persist | RootCABanner.tsx + `localStorage.setItem.*dismiss_root_ca_banner` | PENDING UAT-6 |
| AC5 | File /root-ca/*.cer + .pdf accessible qua URL tĩnh | 2 files tồn tại trong public/root-ca/ + magic bytes valid | PENDING UAT-7 |

### Decision Coverage (30 decisions D-01 → D-30 từ CONTEXT)

Tất cả 30 decisions đã implemented trong Plans 13-01 → 13-04. Bảng summary:

| Range | Plan | Coverage |
|-------|------|----------|
| D-01 → D-07 (Bell BE architecture) | 13-01 | 7/7 (table + 5 SPs + 4 endpoints + worker persist) |
| D-08 → D-12 (Bell UI) | 13-02 | 5/5 (header bell + dropdown + toast + stale-while-revalidate + mark read) |
| D-13 → D-17 (Countdown UI) | 13-03 | 5/5 (circular 120 + FE local timer + color 3 mốc + expired transition + text dưới) |
| D-18 → D-21 (SignModal spam + button semantic) | 13-03 | 4/4 (auto-fire giữ + caller disable + 2 button pending + 1 button terminal) |
| D-22 → D-26 (Root CA banner) | 13-04 | 5/5 (trigger điều kiện + vị trí + nội dung 2 button + dismiss scope + shown_once) |
| D-27 → D-30 (Root CA files) | 13-04 | 4/4 (source docs/ + copy + rename kebab + commit git + Next.js static serve) |

### Requirement Coverage (6 REQs)

| REQ ID | Description | Implemented by Plan | Status |
|--------|-------------|---------------------|--------|
| UX-07 | Modal 3 button semantic | 13-03 | Implemented, PENDING UAT-3 |
| UX-08 | Spam protection + maskClosable false | 13-03 | Implemented, PENDING UAT-1, UAT-3 |
| UX-09 | Countdown 3:00 | 13-03 | Implemented, PENDING UAT-2 |
| UX-10 | Bell notification persistent + toast | 13-01 + 13-02 | Implemented, PENDING UAT-4, UAT-5 |
| UX-11 | Root CA banner dismissible | 13-04 | Implemented, PENDING UAT-6 |
| DEP-02 | Root CA files public URL | 13-04 | Implemented, PENDING UAT-7 |

---

## UAT Test Matrix (7 test cases cho user browser test)

| # | Test case | Expected behavior | Relates AC/REQ |
|---|-----------|-------------------|----------------|
| 1 | Mở modal ký số, spam click button "Ký số" (caller) | Button disable ngay lần click đầu, không tạo duplicate transaction | AC1, UX-07, UX-08 |
| 2 | Modal ký số hiển thị countdown | Circular 3:00 → 0:00, đổi màu xanh (>60s) → vàng (30-60s) → đỏ (<30s); khi 0:00 → state `expired` + Alert error | AC2, UX-09 |
| 3 | Modal pending, click "Đóng (chạy nền)" | Modal close, transaction giữ pending, bell sẽ báo sau khi worker poll xong | AC1, UX-07 |
| 4 | Modal pending, click "Hủy ký số" | Modal close, transaction mark cancelled (verify qua admin list hoặc tab Thất bại) | UX-07 |
| 5 | Admin login → nhìn bell icon header | Badge hiện số unread (5 từ seed), click bell → dropdown 5 item gần nhất, click "Đánh dấu đã đọc tất cả" → badge về 0 | AC3, UX-10 |
| 6 | Tab Đã ký, click "Tải file đã ký" của transaction MYSIGN_VIETTEL lần đầu | Banner info hiển thị ngay dưới page header với 2 button "Tải Root CA (.cer)" + "Xem hướng dẫn (PDF)" | AC4, UX-11, DEP-02 |
| 7 | Click X đóng banner, reload trang | Banner KHÔNG hiện lại (localStorage dismiss_root_ca_banner=true); clear localStorage + download lần nữa → banner hiện lại | AC4, AC5, UX-11 |

---

## Task Commits (Plan 13-05)

1. Task 1 (auto): Seed + automated verify + SUMMARY.md — pending commit sau khi Write xong

Phase 13 complete commit list (4 plans + final docs):

```
5d213e3 docs(13-04): complete root-ca-banner-files plan
5474346 feat(13-04): RootCABanner component + integration trang ký số
111ca16 chore(13-04): copy Root CA Viettel files vào frontend/public/root-ca/
5311854 docs(13-02): complete bell-notification-frontend plan
692db86 feat(13-02): replace inline bell block với <BellNotification /> trong MainLayout
63196fa feat(13-02): add BellNotification self-contained component
93beb29 feat(13-02): add bell notification API client wrappers
1e8ec57 docs(13-03): complete signmodal-countdown-polish plan
86e941f feat(13-03): useSigning isOpen export + caller disable Ký số/Ký lại button spam guard
0f27961 feat(13-03): SignModal countdown circular UI + color state + expired transition
f0f6ee1 docs(13-01): complete notification-backend-infrastructure plan
f78a288 feat(13-01): worker persist bell notification BEFORE socket emit
9c83d79 feat(13-01): notifications repository + route + server.ts mount
0bb9c9e feat(13-01): schema master append notifications table + 5 SPs
```

## Known Stubs

Không có.

## Self-Check

Verified before declaring auto phase complete:

- `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-05-e2e-uat-checkpoint-SUMMARY.md` — FOUND (this file)
- Backend TS: Phase 13 files (notifications.repository.ts, routes/notifications.ts, signing-poll.worker.ts) — 0 new errors
- Frontend build — PASS (52s, 52 pages, zero error)
- DB table `public.notifications` 10 columns — CONFIRMED via `\d`
- 5 SPs `public.fn_notification_*` — CONFIRMED
- 2 Root CA files in `frontend/public/root-ca/` — CONFIRMED
- 5 notifications seeded for staff_id=1 (3 completed + 2 failed) — CONFIRMED
- All Phase 13-01 → 13-04 task commits exist in git log — CONFIRMED
- 5 AC grep markers all matched — CONFIRMED
- 30 decisions mapped to 4 sub-plan implementations — CONFIRMED

## Self-Check: PASSED (auto phase)

---

*Phase: 13-modal-ky-so-robust-root-ca-ux*
*Plan: 05 (E2E + UAT Checkpoint)*
*Auto phase completed: 2026-04-23*
*Checkpoint gate: PENDING user UAT reply `approved` / `fail UAT-N`*
