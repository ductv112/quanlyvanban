---
phase: 13
plan: 03
type: execute
wave: 1
depends_on: []
files_modified:
  - e_office_app_new/frontend/src/components/signing/SignModal.tsx
  - e_office_app_new/frontend/src/hooks/use-signing.tsx
  - e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx
autonomous: true
requirements:
  - UX-07
  - UX-08
  - UX-09
tags: [frontend, signing, modal, countdown, antd6, spam-protection]
must_haves:
  truths:
    - "SignModal hiển thị circular progress 3:00 → 0:00 với MM:SS center format realtime tick 1s"
    - "Color state theo remaining: >60s xanh #1B3A5C, 30-60s vàng #D97706, <30s đỏ #DC2626"
    - "Text dưới countdown: 'Vui lòng xác nhận OTP trên ứng dụng {providerName} trên điện thoại'"
    - "Khi remaining=0s, modal state chuyển expired + Alert error + button 'Đóng' primary"
    - "Caller 'Ký số' button trong /ky-so/danh-sach 4 tab disable khi useSigning.state.open=true (spam protection)"
    - "Modal footer 2 button phân biệt khi status=pending: 'Hủy ký số' danger + 'Đóng (chạy nền)' default. Khi terminal: 1 button 'Đóng' primary"
    - "maskClosable:false (đã có Phase 12 hotfix) — verify lại"
  artifacts:
    - path: "e_office_app_new/frontend/src/components/signing/SignModal.tsx"
      provides: "Countdown circular UI + color state + expired transition + verify 2 button footer"
      contains: "Progress type=\"circle\""
    - path: "e_office_app_new/frontend/src/hooks/use-signing.tsx"
      provides: "Export hook state `isOpen` boolean cho caller disable button"
      contains: "isOpen: state.open"
    - path: "e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx"
      provides: "Button 'Ký số' / 'Ký lại' trong needSignColumns + failedColumns disable khi useSigning isOpen=true"
      contains: "disabled={isOpen}"
  key_links:
    - from: "SignModal.tsx"
      to: "AntD <Progress type='circle' />"
      via: "countdown UI"
      pattern: "Progress.*type=\"circle\""
    - from: "page.tsx (danh-sach)"
      to: "useSigning isOpen guard"
      via: "Button disabled prop"
      pattern: "disabled=\\{.*isOpen"
---

<objective>
Polish SignModal UX cho Phase 13 AC#1, AC#2:

1. **Countdown circular UI (D-13, D-14, D-15, D-16, D-17):** thêm `<Progress type='circle' size={120}>` hiển thị MM:SS center với color state theo remaining time. Timer FE-local nguồn chính (D-14), setInterval 1s. Khi hết 3:00 chuyển state `expired` + Alert error.

2. **Spam-click protection (D-18, D-19):** useSigning hook export `isOpen` boolean. Caller (page `/ky-so/danh-sach`) disable button "Ký số" / "Ký lại" khi `isOpen=true` — tránh user double-click mở 2 modal (tạo 2 transaction).

3. **2 button semantic verify (D-20, D-21):** Modal đã có đúng 2 button footer khi pending (Hủy ký số + Đóng (chạy nền)) và 1 button khi terminal (Đóng primary) — Plan 13-03 chỉ verify + gắn countdown timer source cho state logic.

**KHÔNG thuộc scope:**
- `maskClosable:false` (Phase 12 hotfix đã fix qua `mask={{ closable: false }}` AntD 6 API) — chỉ verify lại trong test.
- Thêm button "Thực hiện ký" — D-18 giữ auto-fire POST /sign trong useEffect on open; spam protection qua `initiating` state (đã có) + caller button disable (new in Plan 13-03).
- Thay đổi `POST /api/ky-so/sign` API shape — BE không đổi.

**Quyết định timer source (D-14 chi tiết):**
- `MAX_MODAL_LIFETIME_MS=240_000` (4 phút) hiện tại đổi sang `COUNTDOWN_MS=180_000` (3 phút) = `3 * 60 * 1000` — khớp BE `expires_at` của `sign_transactions` table.
- Khởi timer từ khi nhận response `POST /ky-so/sign` (có `transaction_id + provider_code`) — tức sau `setStatus('pending')`.
- Buffer cho clock skew không cần vì FE local timer, không compare với BE time.
- Nếu BE emit `sign_expired` (hoặc `sign_failed` với `status=expired`) TRƯỚC FE timer hết → Socket event wins, hiển thị Alert expired ngay.
- Nếu FE timer hết TRƯỚC BE emit → FE set `status='expired'` + hiển thị Alert. BE worker sau đó có thể emit expired lần nữa — đã có `successFired` useRef pattern variant; cần thêm `expiredFired` để idempotent.

Output: 2 file modify + 1 file caller adjust.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md
@.planning/phases/11-sign-flow-async-worker/11-06-SUMMARY.md
@CLAUDE.md
@e_office_app_new/frontend/CLAUDE.md
@e_office_app_new/frontend/AGENTS.md

<interfaces>
**SignModal current shape (để biết điều gì giữ, điều gì đổi):**

Imports (giữ):
```typescript
import { useEffect, useRef, useState } from 'react';
import { Modal, Alert, Space, Typography, Tag, Button, App as AntApp } from 'antd';
import { LoadingOutlined, CheckCircleOutlined, CloseCircleOutlined, ClockCircleOutlined, SafetyCertificateOutlined } from '@ant-design/icons';
```

THÊM:
```typescript
import { Progress } from 'antd';
```

State (current):
```typescript
const [initiating, setInitiating] = useState(false);
const [txnId, setTxnId] = useState<number | null>(null);
const [providerCode, setProviderCode] = useState<string | null>(null);
const [providerMessage, setProviderMessage] = useState<string | null>(null);
const [status, setStatus] = useState<TxnStatus | null>(null);
const [errorMsg, setErrorMsg] = useState<string | null>(null);
const [cancelling, setCancelling] = useState(false);
const [signedFilePath, setSignedFilePath] = useState<string | null>(null);
```

THÊM:
```typescript
const [remainingMs, setRemainingMs] = useState<number>(COUNTDOWN_MS);
// expiredFired guard — tránh set status='expired' 2 lần khi FE timer + BE event clash
const expiredFired = useRef(false);
const countdownTimer = useRef<ReturnType<typeof setInterval> | null>(null);
```

Constants (đổi):
```typescript
// Phase 13 — countdown cho OTP confirmation (khớp BE sign_transactions.expires_at = 3 phút)
const COUNTDOWN_MS = 180_000;  // 3:00
// REMOVE: const MAX_MODAL_LIFETIME_MS = 240_000;  (thay bằng COUNTDOWN_MS)
const POLL_INTERVAL_MS = 3000;  // giữ nguyên
```

**use-signing.tsx API extension:**

Hiện tại:
```typescript
export function useSigning() {
  return { openSign, closeSign, renderSignModal };
}
```

Đổi thành:
```typescript
export function useSigning() {
  return { openSign, closeSign, renderSignModal, isOpen: state.open };
}
```

**Caller pattern (danh-sach/page.tsx):**

Hiện tại line 56:
```typescript
const { openSign, renderSignModal } = useSigning();
```

Đổi thành:
```typescript
const { openSign, renderSignModal, isOpen: signModalOpen } = useSigning();
```

Trong columns (needSignColumns + failedColumns), Button "Ký số" và "Ký lại" thêm `disabled={signModalOpen}` để spam protection:
```tsx
<Button type="primary" onClick={() => handleSign(row)} disabled={signModalOpen}>
  Ký số
</Button>
```

**Countdown render block (NEW):**

Đặt trong Modal body, ABOVE Alert status block. Pseudo:
```tsx
{status === 'pending' && (
  <div style={{ textAlign: 'center', padding: '16px 0 8px' }}>
    <Progress
      type="circle"
      size={120}
      percent={Math.round((remainingMs / COUNTDOWN_MS) * 100)}
      strokeColor={countdownColor(remainingMs)}
      format={() => (
        <span style={{ fontSize: 24, fontWeight: 600, color: countdownColor(remainingMs) }}>
          {formatMMSS(remainingMs)}
        </span>
      )}
    />
    <div style={{ marginTop: 12, fontSize: 13, color: '#475569' }}>
      Vui lòng xác nhận OTP trên ứng dụng <b>{providerName}</b> trên điện thoại
    </div>
  </div>
)}
```

Helpers (top-level functions trong file):
```typescript
function countdownColor(ms: number): string {
  const s = Math.ceil(ms / 1000);
  if (s > 60) return '#1B3A5C';        // xanh — brand primary
  if (s >= 30) return '#D97706';       // vàng — warning
  return '#DC2626';                     // đỏ — danger
}

function formatMMSS(ms: number): string {
  const totalSec = Math.max(0, Math.ceil(ms / 1000));
  const mm = Math.floor(totalSec / 60);
  const ss = totalSec % 60;
  return `${mm}:${ss.toString().padStart(2, '0')}`;
}
```

**Countdown timer useEffect (NEW):**

Đặt SAU effect poll + socket listen, body:
```typescript
useEffect(() => {
  if (!open || !txnId || status !== 'pending') return;

  // Reset khi start mới
  setRemainingMs(COUNTDOWN_MS);
  expiredFired.current = false;

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

**Change existing lifetime guard:**

Hiện có (trong poll useEffect, line ~206):
```typescript
lifetimeTimer.current = setTimeout(() => {
  setErrorMsg('Hết thời gian chờ từ hệ thống. Vui lòng thử lại.');
  setStatus('expired');
}, MAX_MODAL_LIFETIME_MS);
```

REMOVE block này — countdown useEffect mới handle expire state. Giữ `pollTimer` setInterval cho REST poll fallback (3s interval). Remove ref `lifetimeTimer`.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Extend SignModal.tsx — thêm countdown circular UI + color state + expired transition</name>
  <files>e_office_app_new/frontend/src/components/signing/SignModal.tsx</files>
  <read_first>
    - `e_office_app_new/frontend/src/components/signing/SignModal.tsx` (full file, đặc biệt line 36-60 imports + constants, 115-250 state + useEffects, 300-425 footer + render block)
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md` section D-13 đến D-17 (countdown specs)
    - `.planning/phases/11-sign-flow-async-worker/11-06-SUMMARY.md` (understand successFired pattern trước khi add expiredFired)
    - AntD 6 Progress docs: `node_modules/antd/lib/progress/` hoặc test render để verify `type="circle" size={120}` + `format` prop shape
  </read_first>
  <action>
Modify `e_office_app_new/frontend/src/components/signing/SignModal.tsx`:

**Change 1: Imports (line 36-45)** — thêm `Progress`:
```typescript
import { Modal, Alert, Space, Typography, Tag, Button, App as AntApp, Progress } from 'antd';
```

**Change 2: Constants (line 56-60)** — đổi MAX_MODAL_LIFETIME_MS thành COUNTDOWN_MS:
```typescript
// Phase 13: countdown 3:00 OTP (khớp BE sign_transactions.expires_at)
const COUNTDOWN_MS = 180_000;
const POLL_INTERVAL_MS = 3000;
// Phase 13 TODO đã xong — remove MAX_MODAL_LIFETIME_MS
```

Remove comment line `TODO Phase 13: countdown 3:00 timer UI (UX-03)` và block comment "Phase 13 TODOs (UX polish — out of scope this plan)" ở đầu file.

**Change 3: Thêm helpers top-level** (sau `const PROVIDER_NAMES` ~line 80):
```typescript
/** Color theo remaining time — D-15: xanh > 60s, vàng 30-60s, đỏ < 30s */
function countdownColor(ms: number): string {
  const s = Math.ceil(ms / 1000);
  if (s > 60) return '#1B3A5C';        // brand primary
  if (s >= 30) return '#D97706';       // warning
  return '#DC2626';                     // danger
}

/** Format ms → 'M:SS' (zero-padded seconds) */
function formatMMSS(ms: number): string {
  const totalSec = Math.max(0, Math.ceil(ms / 1000));
  const mm = Math.floor(totalSec / 60);
  const ss = totalSec % 60;
  return `${mm}:${ss.toString().padStart(2, '0')}`;
}
```

**Change 4: State (line 129-137)** — add 2 state + 2 refs, remove `lifetimeTimer`:
```typescript
// --- Phase 13: countdown state ---
const [remainingMs, setRemainingMs] = useState<number>(COUNTDOWN_MS);
const countdownTimer = useRef<ReturnType<typeof setInterval> | null>(null);
const expiredFired = useRef(false);

// Remove: const lifetimeTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
```

**Change 5: Effect 1 (initiate)** — reset `remainingMs` + `expiredFired` khi open mới. Tìm block `start()` async function inside useEffect (line 151-191):
```typescript
async function start() {
  setInitiating(true);
  setErrorMsg(null);
  setStatus(null);
  setTxnId(null);
  setSignedFilePath(null);
  successFired.current = false;
  // ADD:
  setRemainingMs(COUNTDOWN_MS);
  expiredFired.current = false;
  // ... rest giữ nguyên
}
```

**Change 6: Effect 2 (poll + socket)** — remove `lifetimeTimer` block (line ~205-209 `lifetimeTimer.current = setTimeout(...)` và cleanup):

Remove:
```typescript
lifetimeTimer.current = setTimeout(() => {
  setErrorMsg('Hết thời gian chờ từ hệ thống. Vui lòng thử lại.');
  setStatus('expired');
}, MAX_MODAL_LIFETIME_MS);
```

Và trong cleanup return:
```typescript
return () => {
  if (pollTimer.current) clearInterval(pollTimer.current);
  // REMOVE: if (lifetimeTimer.current) clearTimeout(lifetimeTimer.current);
  pollTimer.current = null;
  // REMOVE: lifetimeTimer.current = null;
  socket?.off(SOCKET_EVENTS.SIGN_COMPLETED, onCompleted);
  socket?.off(SOCKET_EVENTS.SIGN_FAILED, onFailed);
};
```

**Change 7: Thêm useEffect 3 (countdown)** — đặt SAU Effect 2 (poll+socket), TRƯỚC Effect "React to terminal 'completed'":
```typescript
// ==========================================================================
// Phase 13 Step 2.5: Countdown timer (FE local, tick 1s — D-14)
// ==========================================================================
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

**Change 8: Render — thêm countdown block TRƯỚC Alert pending** (trong Modal body, tìm block `{status === 'pending' && (...)}` line ~364):

Trước `{status === 'pending' && (` (giữ block Alert hiện tại), thêm:
```tsx
{status === 'pending' && (
  <div style={{ textAlign: 'center', padding: '16px 0 12px' }}>
    <Progress
      type="circle"
      size={120}
      percent={Math.round((remainingMs / COUNTDOWN_MS) * 100)}
      strokeColor={countdownColor(remainingMs)}
      format={() => (
        <span
          style={{
            fontSize: 24,
            fontWeight: 600,
            color: countdownColor(remainingMs),
            fontVariantNumeric: 'tabular-nums',
          }}
        >
          {formatMMSS(remainingMs)}
        </span>
      )}
    />
    <div
      style={{
        marginTop: 12,
        fontSize: 13,
        color: '#475569',
        lineHeight: 1.5,
      }}
    >
      Vui lòng xác nhận OTP trên ứng dụng <b>{providerName}</b> trên điện thoại
    </div>
  </div>
)}
```

**Change 9: Giữ nguyên Alert pending block** (nội dung Alert hiện tại OK — D-17 đã cover qua countdown text trên, Alert block bên dưới bổ sung context). Tuy nhiên, đơn giản hóa Alert description vì countdown đã cover "chờ OTP" phần chính. Tìm block:
```tsx
{status === 'pending' && (
  <Alert
    type="info"
    showIcon
    ...
    message="Chờ xác nhận OTP trên thiết bị di động"
    description={
      <div>
        <p>Mở ứng dụng <b>{providerName}</b> trên điện thoại và xác nhận yêu cầu ký số.</p>
        <p>Hệ thống sẽ tự động cập nhật khi bạn xác nhận. Bạn có thể bấm <b>"Đóng (chạy nền)"</b> — giao dịch vẫn tiếp tục và bạn sẽ nhận thông báo khi hoàn tất.</p>
        {providerMessage && <Text type="secondary" style={{ fontSize: 12 }}>Phản hồi từ provider: {providerMessage}</Text>}
      </div>
    }
  />
)}
```

GIỮ NGUYÊN — không đổi (countdown ở TRÊN Alert, Alert vẫn giải thích "Đóng chạy nền" cho user).

**Change 10: Verify footer logic** (đã đúng từ Phase 11-06). Kiểm tra block:
- `status === 'pending'` → push `<Button danger>Hủy ký số</Button>` + `<Button>Đóng (chạy nền)</Button>`
- terminal → push `<Button type="primary">Đóng</Button>`

Hiện tại code đúng (line 300-321) — KHÔNG sửa.

**Change 11: maskClosable verify** — line 334 có `mask={{ closable: false }}` (AntD 6 API) — giữ nguyên, đã fix Phase 12 hotfix.

Compile check:
```bash
cd e_office_app_new/frontend
npx tsc --noEmit 2>&1 | grep -E "components/signing/SignModal\.tsx" | (! grep -q "error TS")
```

Smoke test bằng dev tools:
1. Login + navigate `/ky-so/danh-sach` tab "Cần ký"
2. Click "Ký số" một attachment test → Modal mở
3. Observe countdown `3:00` xanh đậm ngay lập tức
4. Tick 1s xanh → 2:59, 2:58, ... cho đến 1:01 vẫn xanh
5. Tại 1:00 đổi vàng #D97706
6. Tại 0:29 đổi đỏ #DC2626
7. Tại 0:00 state chuyển `expired`, Alert error hiển thị, circular dừng, button chỉ còn "Đóng" primary
  </action>
  <verify>
<automated>
grep -q "import.*Progress.*from 'antd'" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q "const COUNTDOWN_MS = 180_000" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
! grep -q "MAX_MODAL_LIFETIME_MS" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q "function countdownColor" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q "function formatMMSS" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q "'#1B3A5C'" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q "'#D97706'" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q "'#DC2626'" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q "expiredFired" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q "remainingMs" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q 'type="circle"' e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q "size={120}" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q "xác nhận OTP trên ứng dụng" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -q 'mask={{ closable: false }}' e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
grep -cE 'Button.*(danger|type="primary"|>Đóng)' e_office_app_new/frontend/src/components/signing/SignModal.tsx | (read n && [ "$n" -ge 2 ]) && \
cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | grep -E "components/signing/SignModal\.tsx" | (! grep -q "error TS") && \
echo "Task 1 OK"
</automated>
  </verify>
  <done>
    - Progress imported from antd
    - COUNTDOWN_MS = 180_000 replaces MAX_MODAL_LIFETIME_MS
    - helpers countdownColor + formatMMSS defined
    - 3 color codes present (1B3A5C, D97706, DC2626)
    - expiredFired ref + remainingMs state added
    - countdown useEffect tick 1s với setInterval
    - Progress circle 120px render trong pending block, format prop hiển thị MM:SS
    - Text "Vui lòng xác nhận OTP trên ứng dụng {providerName}" present
    - maskClosable verify giữ đúng AntD 6 API `mask={{ closable: false }}`
    - Footer 2 button pending (Hủy ký số + Đóng) + 1 button terminal (Đóng primary) — giữ nguyên logic Phase 11-06
    - TypeScript clean
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Extend useSigning hook export isOpen + Caller disable "Ký số" button trong danh-sach</name>
  <files>
    e_office_app_new/frontend/src/hooks/use-signing.tsx,
    e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx
  </files>
  <read_first>
    - `e_office_app_new/frontend/src/hooks/use-signing.tsx` (full file — 120 dòng)
    - `e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx` (line 56 import useSigning + line 360+ where Button "Ký số" rendered trong needSignColumns + failedColumns)
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md` D-18 D-19 (spam protection strategy — caller disable khi open=true)
  </read_first>
  <action>
**Part A: Modify `e_office_app_new/frontend/src/hooks/use-signing.tsx`:**

Trong return statement cuối hook (line ~119):

Đổi:
```typescript
return { openSign, closeSign, renderSignModal };
```

Thành:
```typescript
return {
  openSign,
  closeSign,
  renderSignModal,
  /** Phase 13 — caller dùng để disable trigger button tránh spam-click (D-18, D-19). */
  isOpen: state.open,
};
```

**Part B: Modify `e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx`:**

Hiện tại line 56 (hoặc gần đó):
```typescript
const { openSign, renderSignModal } = useSigning();
```

Đổi thành:
```typescript
const { openSign, renderSignModal, isOpen: signModalOpen } = useSigning();
```

Sau đó trong 2 column definitions (`needSignColumns` + `failedColumns`), tìm Button "Ký số" / "Ký lại":

**needSignColumns** (tab Cần ký — có button "Ký số"):
```tsx
<Button type="primary" onClick={() => handleSign(row)}>
  Ký số
</Button>
```

Đổi thành:
```tsx
<Button
  type="primary"
  onClick={() => handleSign(row)}
  disabled={signModalOpen}
>
  Ký số
</Button>
```

**failedColumns** (tab Thất bại — có button "Ký lại"):
```tsx
<Button
  type="primary"
  icon={<ReloadOutlined />}
  onClick={() => handleSign(row)}
>
  Ký lại
</Button>
```

Đổi thành:
```tsx
<Button
  type="primary"
  icon={<ReloadOutlined />}
  onClick={() => handleSign(row)}
  disabled={signModalOpen}
>
  Ký lại
</Button>
```

**LƯU Ý useMemo deps:** column defs dùng `useMemo` với deps `[handleSign]`. Giờ column depends thêm `signModalOpen` → BẮT BUỘC thêm `signModalOpen` vào useMemo deps array của CẢ 2 useMemo (needSignColumns + failedColumns):

```tsx
const needSignColumns: ColumnsType<NeedSignRow> = useMemo(
  () => [ /* ... columns with Button disabled={signModalOpen} ... */ ],
  [handleSign, signModalOpen],  // <-- ADD signModalOpen
);

const failedColumns: ColumnsType<TxnRow> = useMemo(
  () => [ /* ... columns with Button disabled={signModalOpen} ... */ ],
  [handleSign, signModalOpen],  // <-- ADD signModalOpen
);
```

**Không cần disable "Hủy" trong pendingColumns** — user đang xem list pending có quyền cancel txn khác trong khi modal cho txn khác đang mở. `signModalOpen=true` chỉ guard cho việc tạo TXN MỚI.

**Không cần disable "Tải file đã ký" trong completedColumns** — download là read-only action, không conflict modal.

Compile check:
```bash
cd e_office_app_new/frontend
npx tsc --noEmit 2>&1 | grep -E "hooks/use-signing\.tsx|ky-so/danh-sach/page\.tsx" | (! grep -q "error TS")
```

Smoke test manual:
1. Navigate `/ky-so/danh-sach` tab "Cần ký" (có data)
2. Click "Ký số" row 1 → Modal mở
3. Cố click "Ký số" row 2 (hoặc row 1 khác) — button disable
4. Đóng modal → các button "Ký số" re-enable
5. Tab Thất bại: tương tự với button "Ký lại"
  </action>
  <verify>
<automated>
grep -q "isOpen: state.open" e_office_app_new/frontend/src/hooks/use-signing.tsx && \
grep -q "isOpen: signModalOpen" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx && \
grep -q "disabled={signModalOpen}" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx && \
grep -cE 'disabled=\{signModalOpen\}' e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx | (read n && [ "$n" -ge 2 ]) && \
grep -q "\[handleSign, signModalOpen\]" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx && \
cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | grep -E "hooks/use-signing\.tsx|ky-so/danh-sach/page\.tsx" | (! grep -q "error TS") && \
echo "Task 2 OK"
</automated>
  </verify>
  <done>
    - `useSigning` export `isOpen: state.open` (D-18)
    - `/ky-so/danh-sach/page.tsx` destructure `isOpen: signModalOpen`
    - Button "Ký số" (needSignColumns) có `disabled={signModalOpen}`
    - Button "Ký lại" (failedColumns) có `disabled={signModalOpen}`
    - Cả 2 useMemo column definitions thêm `signModalOpen` vào deps array
    - Button "Hủy" pending tab + "Tải file" completed tab KHÔNG disable (đúng scope)
    - TypeScript clean
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Browser user input → Modal lifecycle | User có thể double-click button "Ký số" trong window ngắn — đã mitigate qua `disabled={signModalOpen}` + `initiating` state guard |
| FE countdown timer → state transition | Client-controlled timer, attacker có thể freeze tab → backend vẫn authoritative (worker poll provider độc lập) |
| Socket event → Modal status | BE emit room `user_{staffId}` — trusted. FE filter by `transaction_id` (existing) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-13-13 | T (Tampering) — User tamper FE timer qua DevTools | SignModal countdown | accept | FE timer purely cosmetic — BE `sign_transactions.expires_at` (set tại POST /sign) là authoritative. Attacker có thể giữ timer ≠ 0 mãi nhưng BE sẽ emit `sign_failed` status=expired sau 3 phút, Socket/poll nhận ngay và force state terminal |
| T-13-14 | D (DoS) — Spam click tạo nhiều transaction | Caller button | mitigate | `disabled={signModalOpen}` + `initiating` state trong SignModal + `useSigning.openSign` guard `if (open) return` (từ Phase 11-06). 3 lớp bảo vệ |
| T-13-15 | E (Elevation) — User bypass `disabled` qua DevTools | Button disabled prop | accept | HTML `disabled` dễ bypass, nhưng backend `POST /api/ky-so/sign` xử lý idempotent nếu user spam: mỗi call tạo transaction mới nhưng worker poll tất cả, không corrupt state. Max impact là provider rate limit — accept vì providers có rate limit built-in |
| T-13-16 | I (Info Disclosure) — Countdown leak expires_at timing | SignModal | accept | Countdown hiển thị timing là expected UX; không leak sensitive info. `expires_at` = `created_at + 3min` là public |
</threat_model>

<verification>
1. **Circular countdown render:** Khi modal status=pending, Progress type=circle size=120 hiển thị với percent = remainingMs / 180000 * 100. MM:SS center.
2. **Color transitions:**
   - remainingMs = 179_000 (2:59) → countdownColor returns `#1B3A5C` (xanh)
   - remainingMs = 59_000 (0:59) → returns `#D97706` (vàng)
   - remainingMs = 29_000 (0:29) → returns `#DC2626` (đỏ)
   - remainingMs = 0 → state transitions to 'expired', Alert error hiển thị
3. **Expired transition idempotent:** nếu FE timer hit 0 và Socket event `sign_failed` status=expired cũng đến, `expiredFired.current` prevent double setStatus (tương tự successFired pattern).
4. **Spam protection:** manual test click "Ký số" rapidly 5 lần → chỉ 1 modal mở, các button sau disable.
5. **Terminal footer:** khi status ∈ ['completed','failed','expired','cancelled'], footer chỉ 1 button "Đóng" primary (không còn "Hủy ký số").
6. **maskClosable verify:** click backdrop modal — modal KHÔNG đóng (giữ Phase 12 hotfix fix).
</verification>

<success_criteria>
Plan 13-03 hoàn tất khi:
- [ ] SignModal hiển thị circular progress 120px với MM:SS center trong pending state
- [ ] Color transition xanh → vàng → đỏ theo 3 mốc (>60, 30-60, <30 seconds)
- [ ] Text "Vui lòng xác nhận OTP trên ứng dụng {providerName} trên điện thoại" dưới countdown
- [ ] Khi remainingMs=0, state chuyển 'expired' với Alert error
- [ ] Timer cleanup trong cleanup function của useEffect (no memory leak)
- [ ] `expiredFired` ref prevent double-set expire (idempotent với BE Socket event)
- [ ] useSigning hook export `isOpen`
- [ ] Button "Ký số" (tab Cần ký) và "Ký lại" (tab Thất bại) trong `/ky-so/danh-sach` disable khi `signModalOpen=true`
- [ ] useMemo deps include `signModalOpen` cho cả 2 column defs
- [ ] maskClosable={false} giữ nguyên (AntD 6 `mask={{ closable: false }}`)
- [ ] 2 button pending (Hủy ký số + Đóng (chạy nền)) + 1 button terminal (Đóng) — giữ nguyên Phase 11-06
- [ ] TypeScript compile 0 new errors
- [ ] UX-07, UX-08, UX-09 all covered
</success_criteria>

<output>
Tạo `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-03-SUMMARY.md` sau khi hoàn tất.
</output>
