---
phase: 13-modal-ky-so-robust-root-ca-ux
plan: 03
subsystem: frontend
tags: [frontend, signing, modal, countdown, antd6, spam-protection, ux-polish]

requires:
  - phase: 11-06
    provides: SignModal baseline + useSigning hook (successFired, destroyOnHidden, mask={closable:false})
  - phase: 12-02
    provides: /ky-so/danh-sach 4-tab với 4 column defs (needSign, pending, completed, failed)
provides:
  - SignModal countdown circular UI 3:00 (MM:SS center) với color state theo remaining time
  - Expired transition idempotent qua expiredFired useRef (tương tự successFired pattern Phase 11-06)
  - useSigning hook export `isOpen` — caller dùng để disable trigger button (spam-click guard layer 3)
  - openSign functional setState guard — skip khi modal đã mở (stale closure safe)
  - Caller disable disabled={signModalOpen} trên Button "Ký số" + "Ký lại" trong /ky-so/danh-sach
affects: [13-05]

tech-stack:
  added: []  # Dùng AntD Progress sẵn có, không thêm dep mới
  patterns:
    - "FE-local timer authoritative cho countdown UI (D-14) — BE sign_transactions.expires_at=180s là SoT backend nhưng không cần clock sync với FE cho UX countdown"
    - "Idempotent terminal state via useRef guard (successFired, expiredFired) — prevent double fire khi polling + Socket cả 2 đến"
    - "3 lớp spam-click protection: hook openSign functional setState guard + SignModal initiating state + caller button disabled prop"
    - "AntD Progress size=number (120) cho circle type — v6 API nhất quán"

key-files:
  created: []  # Chỉ modify, không tạo file mới
  modified:
    - e_office_app_new/frontend/src/components/signing/SignModal.tsx
    - e_office_app_new/frontend/src/hooks/use-signing.tsx
    - e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx

key-decisions:
  - "Phase 13-03: COUNTDOWN_MS=180_000 (3:00) thay MAX_MODAL_LIFETIME_MS=240_000 (4:00) — khớp BE expires_at=180s thay vì giữ buffer clock skew (FE local timer không so sánh BE time)"
  - "Phase 13-03: Xóa lifetimeTimer setTimeout ở Effect 2 (poll+socket), countdown useEffect mới là authoritative duy nhất — tránh 2 timer fire cùng expired state"
  - "Phase 13-03: expiredFired useRef guard áp dụng CẢ trong countdown tick CỘNG onFailed socket handler — BE emit sign_failed status=expired không làm setStatus lần 2 nếu FE timer đã fire trước"
  - "Phase 13-03: openSign functional setState pattern — prev.open check tránh stale closure (state var trong useCallback không rebind khi state đổi)"
  - "Phase 13-03: useMemo deps 2 column defs thêm signModalOpen — React rebuild column khi modal mở/đóng để disabled prop update đúng; thiếu deps sẽ stuck disabled state"
  - "Phase 13-03: Button 'Hủy' pending + 'Tải file đã ký' completed KHÔNG disable — scope boundary chỉ chặn tạo TXN MỚI (Ký số + Ký lại), các action khác không conflict modal"

patterns-established:
  - "Countdown UI pattern cho async flow có deadline: circular progress + MM:SS + color theo remaining + Alert khi expired — reusable cho các flow khác (VD: approve deadline, OTP login...)"
  - "3-lớp spam-click defense: caller-visible (disabled prop) + hook internal (functional setState guard) + component internal (initiating/loading state) — tương lai áp dụng cho mọi async modal trigger"

requirements-completed: [UX-07, UX-08, UX-09]

metrics:
  duration: 6 min
  tasks: 2
  files_modified: 3
  files_created: 0
  lines_added: ~170
  lines_removed: ~32

completed: 2026-04-23
---

# Phase 13 Plan 03: SignModal Countdown Polish Summary

**Polish SignModal UX — countdown circular 3:00 với color state (xanh > 60s, vàng 30-60s, đỏ < 30s), expired transition idempotent qua expiredFired useRef, useSigning hook export isOpen cho caller disable trigger button spam-click, áp dụng 3 lớp defense spam protection.**

## Performance

- **Duration:** ~6 phút
- **Tasks:** 2/2 (auto, no checkpoint)
- **Files modified:** 3 (SignModal.tsx, use-signing.tsx, danh-sach/page.tsx)
- **Lines:** +170 / -32 (net +138, mostly new countdown UI block + 2 helpers + new useEffect)
- **Build status:** Next.js compile PASS (53s)
- **TypeScript:** 0 new errors in touched files

## What Was Built

### Task 1 — SignModal countdown circular UI (commit `0f27961`)

**File:** `e_office_app_new/frontend/src/components/signing/SignModal.tsx` (+131/-19)

Thêm circular progress 120px với MM:SS center, color state dynamic theo remaining time:

```tsx
{status === 'pending' && (
  <div style={{ textAlign: 'center', padding: '16px 0 12px' }}>
    <Progress
      type="circle"
      size={120}
      percent={Math.round((remainingMs / COUNTDOWN_MS) * 100)}
      strokeColor={countdownColor(remainingMs)}
      format={() => (
        <span style={{ fontSize: 24, fontWeight: 600, color: countdownColor(remainingMs), fontVariantNumeric: 'tabular-nums' }}>
          {formatMMSS(remainingMs)}
        </span>
      )}
    />
    <div style={{ marginTop: 12, fontSize: 13, color: '#475569', lineHeight: 1.5 }}>
      Vui lòng xác nhận OTP trên ứng dụng <b>{providerName}</b> trên điện thoại
    </div>
  </div>
)}
```

**Color mapping (D-15):**
- `> 60s` → `#1B3A5C` (xanh navy brand)
- `30s <= remaining <= 60s` → `#D97706` (vàng warning)
- `< 30s` → `#DC2626` (đỏ danger)

**Constants:**
- `COUNTDOWN_MS = 180_000` (3:00) — thay `MAX_MODAL_LIFETIME_MS = 240_000` để khớp BE `sign_transactions.expires_at=180s`

**Helpers (top-level functions):**
- `countdownColor(ms): string` — D-15 color mapping
- `formatMMSS(ms): string` — format `M:SS` với zero-padded seconds

**State + Refs:**
- `remainingMs: number` state (init = COUNTDOWN_MS) — source cho Progress percent
- `countdownTimer: useRef` — cleanup setInterval
- `expiredFired: useRef<boolean>` — idempotent guard (FE timer + BE Socket event không double setStatus)

**Timer useEffect (D-14) — thêm sau Effect 2 (poll+socket):**
```tsx
useEffect(() => {
  if (!open || !txnId || status !== 'pending') return;
  const startAt = Date.now();
  countdownTimer.current = setInterval(() => {
    const elapsed = Date.now() - startAt;
    const remain = COUNTDOWN_MS - elapsed;
    if (remain <= 0) {
      setRemainingMs(0);
      if (!expiredFired.current) {
        expiredFired.current = true;
        setStatus('expired');
        setErrorMsg('Hết thời gian chờ xác nhận OTP. Vui lòng thử lại.');
      }
      if (countdownTimer.current) clearInterval(countdownTimer.current);
      countdownTimer.current = null;
    } else {
      setRemainingMs(remain);
    }
  }, 1000);
  return () => {
    if (countdownTimer.current) clearInterval(countdownTimer.current);
    countdownTimer.current = null;
  };
}, [open, txnId, status]);
```

**Effect 2 onFailed handler** — thêm expiredFired guard khi BE emit `sign_failed` với `status=expired`:
```tsx
if (payload.status === 'expired') {
  if (expiredFired.current) return;
  expiredFired.current = true;
}
```

**Đã xóa:**
- `const MAX_MODAL_LIFETIME_MS = 240_000`
- `const lifetimeTimer = useRef<ReturnType<typeof setTimeout> | null>(null)`
- `lifetimeTimer.current = setTimeout(...)` trong Effect 2
- Cleanup `clearTimeout(lifetimeTimer.current)`
- `TODO Phase 13` comment trong file header

**Đã verify KHÔNG sửa:**
- Footer 2 button khi status=pending (Hủy ký số danger + Đóng (chạy nền) default) — Phase 11-06 đã đúng
- Footer 1 button khi terminal (Đóng primary) — đúng D-21
- `mask={{ closable: false }}` AntD 6 API — Phase 12 hotfix giữ
- `destroyOnHidden` + `width={560}` — Phase 11-06 baseline

### Task 2 — useSigning.isOpen + caller disable spam guard (commit `86e941f`)

**Files:**
- `e_office_app_new/frontend/src/hooks/use-signing.tsx` (+16/-6)
- `e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx` (+23/-7)

**useSigning hook:**
- Return object mở rộng `isOpen: state.open` — caller consume để disable trigger button
- `openSign` chuyển sang functional setState pattern với guard `if (prev.open) return prev` — bảo đảm stale closure safe, spam click không tạo 2 modal cùng lúc

**danh-sach/page.tsx:**
- Destructure `const { openSign, renderSignModal, isOpen: signModalOpen } = useSigning()`
- Button "Ký số" (needSignColumns) thêm `disabled={signModalOpen}`
- Button "Ký lại" (failedColumns) thêm `disabled={signModalOpen}`
- useMemo deps 2 column defs thêm `signModalOpen` để React rebuild column khi modal mở/đóng
- **KHÔNG đổi:** Button "Hủy" pendingColumns + "Tải file đã ký" completedColumns — scope boundary D-18/D-19 chỉ chặn tạo TXN MỚI

**3 lớp spam-click defense:**
1. **Caller button `disabled={signModalOpen}`** — UX layer, user nhìn thấy button xám, không click được
2. **SignModal `initiating` state** — disable internal action khi POST /sign đang fire (Phase 11-06)
3. **useSigning `openSign` functional setState guard** — bypass caller nếu ai đó gọi openSign programmatically khi modal đã mở

## Requirements Delivered

| REQ-ID | Description | Evidence |
|--------|-------------|----------|
| UX-07 | Giải thích rõ chức năng 3 nút (Thực hiện ký / Hủy ký số / Đóng) | 2 button pending + 1 button terminal logic verify giữ đúng Phase 11-06 baseline |
| UX-08 | Vô hiệu hóa "Thực hiện ký" khi đang chờ OTP + xử lý double-click | 3 lớp defense spam-click: useSigning functional setState guard + initiating state + caller disabled prop |
| UX-09 | Đếm ngược 3 phút rõ ràng UI | Progress circle 120px + MM:SS center + color xanh/vàng/đỏ + text "Vui lòng xác nhận OTP trên ứng dụng {provider} trên điện thoại" |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical functionality] Thêm openSign functional setState guard trong use-signing.tsx**

- **Found during:** Task 2 review
- **Issue:** CONTEXT D-18 nói "openSign guard `if (open) return` (đã có)" nhưng thực tế file use-signing.tsx trước Task 2 chưa có guard — openSign chỉ `setState({ open: true, ... })` không kiểm tra state cũ
- **Fix:** Chuyển sang functional setState `setState((prev) => { if (prev.open) return prev; return { ... }; })` — pattern này stale-closure safe vì đọc prev state tại runtime, không capture state var tại mount
- **Rationale:** Spam-click defense cần đủ 3 lớp (D-18 nói rõ "3 lớp bảo vệ"). Nếu thiếu lớp hook internal, caller disable có thể bypass qua programmatic call.
- **Files modified:** `e_office_app_new/frontend/src/hooks/use-signing.tsx`
- **Commit:** `86e941f`

### Không có deviation khác — plan executed exactly như designed.

## Authentication Gates

Không có — task pure FE modification, không cần credential/auth setup.

## Known Stubs

Không có stub. Tất cả text, action, color đều hard-coded từ spec CONTEXT.md (không placeholder).

Note: comment "Custom metadata embed vào PDF placeholder" trong JSDoc SignModalProps.signReason là thuật ngữ **PDF digital signature placeholder** (byte range cho signature bytes) — KHÔNG phải UI stub.

## Verification Results

### Automated checks — Task 1 SignModal.tsx

| Check | Expected | Actual |
|-------|----------|--------|
| `import Progress from 'antd'` | present | ✓ |
| `const COUNTDOWN_MS = 180_000` | present | ✓ |
| `MAX_MODAL_LIFETIME_MS` removed | absent | ✓ |
| `function countdownColor` | present | ✓ |
| `function formatMMSS` | present | ✓ |
| `'#1B3A5C'` | >= 1 | 2 (brand + title icon) |
| `'#D97706'` | >= 1 | 1 |
| `'#DC2626'` | >= 1 | 1 |
| `expiredFired` refs | >= 1 | 9 occurrences |
| `remainingMs` state | >= 1 | 6 occurrences |
| `type="circle"` | 1 | 1 |
| `size={120}` | 1 | 1 |
| `"xác nhận OTP trên ứng dụng"` | 1 | 1 |
| `mask={{ closable: false }}` | 1 | 1 |
| TypeScript errors in SignModal.tsx | 0 | 0 |

### Automated checks — Task 2

| Check | Expected | Actual |
|-------|----------|--------|
| `isOpen: state.open` in use-signing.tsx | present | ✓ |
| `isOpen: signModalOpen` destructure page.tsx | present | ✓ |
| `disabled={signModalOpen}` count | >= 2 | 2 (Ký số + Ký lại) |
| `[handleSign, signModalOpen]` useMemo deps | >= 2 | 2 |
| TS errors in touched files | 0 | 0 |

### Build verification

```
✓ Compiled successfully in 53s
```

Frontend Next.js 16 production build PASS. Tất cả static/dynamic routes render OK.

### Manual smoke test TODO (Phase 13-05 UAT checkpoint scope)

- [ ] Navigate `/ky-so/danh-sach` tab "Cần ký", click "Ký số" → Modal mở với countdown 3:00 xanh
- [ ] Observe tick 1s đếm xuống, tại 1:00 đổi vàng, tại 0:29 đổi đỏ
- [ ] Tại 0:00 state chuyển expired, Alert error, footer 1 button "Đóng" primary
- [ ] Mở modal xong, button "Ký số" (row khác) + "Ký lại" (tab Thất bại) DISABLE
- [ ] Đóng modal → các button re-enable
- [ ] maskClosable verify: click backdrop → modal KHÔNG đóng

## Threat Flags

Không có surface mới ngoài phạm vi threat_model của PLAN.md. Cả 3 threat đều accept hoặc mitigate theo kế hoạch:

- **T-13-13 Tampering FE timer** — accept (BE authoritative qua expires_at)
- **T-13-14 DoS spam-click** — mitigate (3 lớp defense đã verify)
- **T-13-15 Bypass disabled** — accept (BE idempotent)
- **T-13-16 Info disclosure expires_at timing** — accept (public info)

## Self-Check: PASSED

**Files:**
- FOUND: e_office_app_new/frontend/src/components/signing/SignModal.tsx
- FOUND: e_office_app_new/frontend/src/hooks/use-signing.tsx
- FOUND: e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx

**Commits:**
- FOUND: 0f27961 (Task 1 — SignModal countdown)
- FOUND: 86e941f (Task 2 — useSigning.isOpen + caller disable)

**Grep verifications all passed.**
**TypeScript compile clean for touched files.**
**Frontend build PASS.**
