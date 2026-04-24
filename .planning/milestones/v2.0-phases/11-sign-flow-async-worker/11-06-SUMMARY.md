---
phase: 11-sign-flow-async-worker
plan: 06
subsystem: ui
tags: [frontend, react, hook, socket-client, modal, shared-component, sign-flow]

requires:
  - phase: 11-03
    provides: POST /api/ky-so/sign + GET /:id + POST /:id/cancel REST endpoints
  - phase: 11-04
    provides: Socket.IO emitSignCompleted / emitSignFailed events (sign_completed / sign_failed)
provides:
  - SignModal component — shared modal wiring POST/GET/cancel REST + Socket fast-path
  - useSigning hook — stable API { openSign, closeSign, renderSignModal } cho consumers
  - lib/signing/types.ts — shared TypeScript types (AttachmentType, TxnStatus, ProviderCode, SignPayload, SignResponseData, TxnStatusData, SignCompletedEvent, SignFailedEvent)
  - SOCKET_EVENTS extended với SIGN_COMPLETED + SIGN_FAILED
affects: [11-07, 11-08, 11-09, 12, 13]

tech-stack:
  added: []
  patterns:
    - "Shared hook + modal pattern cho async flows — state isolated trong hook, caller chỉ call openSign() + render {renderSignModal()}"
    - "Socket fast-path + REST polling fallback — modal luôn eventually consistent dù Socket disconnected"
    - "useRef cho onSuccess callback — tránh re-render loop khi caller pass inline arrow"

key-files:
  created:
    - e_office_app_new/frontend/src/lib/signing/types.ts
    - e_office_app_new/frontend/src/components/signing/SignModal.tsx
    - e_office_app_new/frontend/src/hooks/use-signing.tsx
  modified:
    - e_office_app_new/frontend/src/lib/socket.ts

key-decisions:
  - "Hook file dùng .tsx extension (không .ts) — file chứa JSX từ renderSignModal (Rule 3 auto-fix TS1005 JSX syntax)"
  - "AntD 6 Modal dùng destroyOnHidden thay destroyOnClose — AntD 6 rename prop, destroyOnClose deprecated"
  - "Modal width=560 (không dùng size prop) — Modal AntD 6 vẫn dùng width, size chỉ áp dụng cho Drawer"
  - "successFired useRef guard — đảm bảo onSuccess fire exactly once ngay cả khi polling + Socket cả 2 nhận completed"
  - "MAX_MODAL_LIFETIME_MS=4min FE timeout > backend expires_at=3min — buffer cho clock skew + network latency"
  - "Đóng (chạy nền) KHÔNG auto-cancel txn — worker tiếp tục poll + bell notification báo kết quả khi user quay lại"
  - "onSuccessRef pattern thay state — caller inline arrow function không trigger re-render loop trong useSigning"

patterns-established:
  - "Frontend Socket event consumer: filter by transaction_id trước khi update UI (mitigate T-11-21 Info Disclosure)"
  - "Auth.store không cần sửa — MainLayout.tsx đã có useEffect call initSocket(token) sau login (Phase 3 pattern)"
  - "Terminal state footer: button label 'Đóng' cho terminal vs 'Đóng (chạy nền)' cho pending — UX distinction rõ ràng"

requirements-completed: [SIGN-03, MIG-05]

duration: ~5min
completed: 2026-04-21
---

# Phase 11 Plan 06: Shared SignModal + useSigning Hook Summary

**Shared frontend sign flow — SignModal component (POST /api/ky-so/sign + polling GET /:id + Socket.IO fast-path) + useSigning hook với stable API cho Plans 07/08/09 detail page migrations.**

## Performance

- **Duration:** ~5 phút
- **Started:** 2026-04-21T11:06:26Z
- **Completed:** 2026-04-21T11:11:41Z
- **Tasks:** 3
- **Files created:** 3
- **Files modified:** 1

## Accomplishments

- **SignModal component** (~425 dòng) — reusable modal cho toàn bộ sign flow: khởi tạo transaction, polling status, lắng nghe Socket.IO event, hiển thị Alert phù hợp cho 5 terminal states (pending/completed/failed/expired/cancelled), action buttons contextual (Hủy ký số / Đóng / Đóng chạy nền)
- **useSigning hook** — API ổn định `{ openSign, closeSign, renderSignModal }` để Plans 07/08/09 import + gọi từ action menu attachment
- **Shared types** (lib/signing/types.ts) — 8 exports mirror chính xác backend response shapes (Plans 11-03/04)
- **Socket events extended** — thêm SIGN_COMPLETED + SIGN_FAILED vào SOCKET_EVENTS constants, giữ nguyên initSocket/getSocket/disconnectSocket logic

## Task Commits

1. **Task 1: Shared types + extend socket.ts** — `4e9f46a` (feat)
2. **Task 2: SignModal component** — `787ecfa` (feat)
3. **Task 3: useSigning hook** — `f288d11` (feat)

## Modal Props Signature (stable cho Plans 07/08/09)

```typescript
export interface SignModalProps {
  open: boolean;
  onClose: () => void;
  onSuccess?: (data: {
    transaction_id: number;
    signed_file_path: string | null;
  }) => void;
  attachmentId: number;
  attachmentType: AttachmentType;  // 'outgoing' | 'drafting' | 'handling' | 'incoming'
  fileName: string;
  docId?: number;
  signReason?: string;
  signLocation?: string;
}
```

## useSigning Hook Signature (stable cho Plans 07/08/09)

```typescript
const { openSign, closeSign, renderSignModal } = useSigning();

// Action handler:
openSign({
  attachment: { id: number, file_name: string },
  attachmentType: 'outgoing' | 'drafting' | 'handling',
  docId?: number,
  signReason?: string,
  signLocation?: string,
  onSuccess?: () => void,  // Parent refresh file list
});

// Render:
return <>...page JSX...{renderSignModal()}</>;
```

## Socket.IO Events Hooked

Đã verify event names khớp chính xác với backend emit (workers/signing-poll.worker.ts + lib/signing/sign-events.ts):

| FE Constant | Wire Event Name | Backend Emitter |
|-------------|-----------------|-----------------|
| `SOCKET_EVENTS.SIGN_COMPLETED` | `sign_completed` | `emitSignCompleted(staffId, payload)` → room `user_{staffId}` |
| `SOCKET_EVENTS.SIGN_FAILED` | `sign_failed` | `emitSignFailed(staffId, payload)` → room `user_{staffId}` |

Payload shape match 1-1 với interfaces `SignCompletedEvent` / `SignFailedEvent` trong `lib/signing/types.ts`.

## Files Created/Modified

- **Created** `e_office_app_new/frontend/src/lib/signing/types.ts` — 8 shared TS types
- **Created** `e_office_app_new/frontend/src/components/signing/SignModal.tsx` — 425 dòng, full flow
- **Created** `e_office_app_new/frontend/src/hooks/use-signing.tsx` — state isolation + render helper
- **Modified** `e_office_app_new/frontend/src/lib/socket.ts` — thêm 2 event constants (10 dòng change)

## Decisions Made

- **.tsx extension cho hook** — `use-signing.tsx` (không `.ts`) vì file chứa JSX (renderSignModal returns `<SignModal .../>`)
- **destroyOnHidden vs destroyOnClose** — AntD 6 rename, dùng `destroyOnHidden` để tránh warning
- **maskClosable={false}** — user KHÔNG được đóng modal bằng cách click backdrop khi pending (tránh mất txn_id state)
- **width=560 (Modal vẫn dùng width)** — chỉ Drawer rename width → size ở AntD 6, Modal giữ width
- **MAX_MODAL_LIFETIME_MS=4min > backend 3min expires_at** — buffer cho network latency + clock skew giữa BE/FE
- **Đóng (chạy nền) không auto-cancel** — txn tiếp tục chạy, worker gửi bell notification khi xong (persistent fallback cho Socket miss)
- **successFired useRef guard** — fire onSuccess exactly once dù polling + Socket cả 2 cùng set completed
- **onSuccessRef pattern** — callback stored ngoài state, tránh re-render loop với inline arrow caller
- **Không thay đổi auth.store.ts** — MainLayout.tsx đã call initSocket(token) sau login (Phase 3 pattern). Verified bằng grep, task plan chỉ yêu cầu "verify hoặc add", verified OK.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Rename use-signing.ts → use-signing.tsx**
- **Found during:** Task 3 (useSigning hook)
- **Issue:** File có `.ts` extension nhưng renderSignModal return JSX `<SignModal .../>` → TypeScript báo 15 lỗi TS1005/TS1109/TS1128 (JSX không allowed trong .ts file)
- **Fix:** `mv use-signing.ts use-signing.tsx` — match plan's spec filename was `use-signing.ts` nhưng content có JSX bắt buộc .tsx
- **Files modified:** e_office_app_new/frontend/src/hooks/use-signing.tsx
- **Verification:** `npx tsc --noEmit` trả 0 errors cho file này sau rename
- **Committed in:** f288d11 (Task 3 commit)

**2. [Rule 2 - Missing Critical] successFired useRef guard**
- **Found during:** Task 2 (SignModal — code review)
- **Issue:** Plan draft chỉ check `if (status === 'completed')` trong useEffect không dedupe — nếu Socket event + REST poll cả 2 cập nhật status trong cùng render → onSuccess fire 2 lần → parent fetch list 2 lần (waste)
- **Fix:** Add `successFired.current` ref check — fire onSuccess exactly once, reset khi bắt đầu new transaction
- **Files modified:** e_office_app_new/frontend/src/components/signing/SignModal.tsx
- **Verification:** Logic review — fire điều kiện `!successFired.current`, reset trong `start()` khi open mới
- **Committed in:** 787ecfa (Task 2 commit)

**3. [Rule 2 - Missing Critical] onSuccessRef pattern cho useSigning**
- **Found during:** Task 3 (useSigning hook)
- **Issue:** Plan draft lưu onSuccess trong state object → mỗi call openSign với inline arrow `() => refresh()` tạo new function reference → state thay đổi → hook re-render → SignModal re-render loop (caller không memoize được)
- **Fix:** Lưu onSuccess vào `useRef` ngoài state — openSign chỉ set state cho fields ảnh hưởng render; onSuccess chỉ fire-and-forget
- **Files modified:** e_office_app_new/frontend/src/hooks/use-signing.tsx
- **Verification:** Hook state shape chỉ có serializable fields; onSuccessRef.current updated bởi openSign, fire trong handleSuccess with try/catch swallow
- **Committed in:** f288d11 (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (1 Rule 3 blocking, 2 Rule 2 missing critical)
**Impact on plan:** Tất cả deviations essential cho correctness. File extension bắt buộc (TS không compile với JSX trong .ts); successFired guard mitigate double-callback bug; onSuccessRef mitigate re-render loop tiềm ẩn trong consumer code. Không scope creep — các fix đều liên quan trực tiếp đến correctness của Tasks đang làm.

## Issues Encountered

- **Pre-existing tsc errors** trong các page không liên quan (lich/ca-nhan, van-ban-den/[id], ho-so-cong-viec/[id]...) — out of scope Plan 11-06, baseline hiện có. Verified bằng `git log + tsc --noEmit` — không phải do plan này introduce.
- **Legacy `SigningModal.tsx`** (chú ý: `SigningModal`, không phải `SignModal`) tồn tại từ v1.0 (OTP mock + fake SmartCA). KHÔNG bị ảnh hưởng bởi plan này — đây là file khác hoàn toàn. Phase 11-07/08/09 sẽ thay references từ `SigningModal` → `SignModal` + `useSigning`.

## Phase 13 TODOs (inline comments)

Phase 13 sẽ polish UX, các TODO đã comment inline để grep dễ tìm:

```
e_office_app_new/frontend/src/components/signing/SignModal.tsx:
  Line 28-32: Block comment "Phase 13 TODOs (UX polish — out of scope this plan):"
    - countdown timer 3:00 — see MAX_MODAL_LIFETIME_MS
    - Root CA banner cho MYSIGN_VIETTEL (link PDF + .cer download)
    - Spam-click disable trên trigger button (caller hook responsibility)
    - maskClosable guardrail với confirm warning (currently just false)
  Line 59: "// TODO Phase 13: countdown 3:00 timer UI (UX-03)"
```

Grep command: `grep -n "Phase 13\|TODO Phase" e_office_app_new/frontend/src/components/signing/SignModal.tsx`

## User Setup Required

None — không cần external config. Modal sẽ dùng Socket.IO connection + API endpoints đã có từ Phases 11-03/04.

## Next Phase Readiness

- **Plan 11-07** (VB đi detail page migration) — import `useSigning` from `@/hooks/use-signing`, thay old `SigningModal` tại action menu file attachment
- **Plan 11-08** (VB dự thảo detail page migration) — same pattern
- **Plan 11-09** (HSCV detail page migration với attachmentType='handling') — same pattern
- **Plan 11-10+** hoặc Phase 12 — UX polish (countdown timer, Root CA banner) — grep "Phase 13" comments để tìm điểm cần sửa
- **Verified:** Modal compiles clean, không block downstream. Backend endpoints ready (Plans 11-03/04/05). Socket events wired 2 chiều (BE emit + FE listen).

## Self-Check: PASSED

- `e_office_app_new/frontend/src/lib/signing/types.ts` — FOUND
- `e_office_app_new/frontend/src/components/signing/SignModal.tsx` — FOUND
- `e_office_app_new/frontend/src/hooks/use-signing.tsx` — FOUND
- Commit `4e9f46a` (Task 1 types + socket) — FOUND
- Commit `787ecfa` (Task 2 SignModal) — FOUND
- Commit `f288d11` (Task 3 useSigning) — FOUND
- TypeScript compile — NO ERRORS trong 4 files của plan (types.ts, socket.ts, SignModal.tsx, use-signing.tsx)

---
*Phase: 11-sign-flow-async-worker*
*Completed: 2026-04-21*
