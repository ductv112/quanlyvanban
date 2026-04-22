---
phase: 12
plan: 02
subsystem: frontend
tags: [frontend, next-app-router, antd6, tabs, socket-client, realtime, ky-so]

requires:
  - phase: 12
    plan: 01
    provides: "Sidebar submenu /ky-so/danh-sach + breadcrumb + GET /api/ky-so/sign/:id/download endpoint"
  - phase: 11
    plan: 05
    provides: "GET /ky-so/danh-sach (list 4 tab) + GET /ky-so/danh-sach/counts (4 badge)"
  - phase: 11
    plan: 06
    provides: "useSigning hook + SignModal — consume KHÔNG sửa"
  - phase: 11
    plan: 03
    provides: "POST /ky-so/sign/:id/cancel endpoint (owner-only)"
  - phase: 11
    plan: 04
    provides: "Socket.IO events sign_completed / sign_failed → room user_{staffId}"

provides:
  - "Trang /ky-so/danh-sach — 4 tab với Badge count, table per tab, pagination, realtime refresh"
  - "URL state sync ?tab=X&page=Y&pageSize=Z — refresh/share URL giữ state"
  - "4 bộ column definitions riêng cho need_sign/pending/completed/failed"
  - "3 action handlers: handleSign (open modal), handleCancel (modal.confirm + POST cancel), handleDownload (window.open presigned URL)"

affects:
  - 12-03 (E2E verify + seed test data — trang đã ready test end-to-end với real data)
  - 13 (Modal ký robust + Root CA — UX polish layer trên cùng flow)

tech-stack:
  added: []
  patterns:
    - "Discriminated union render pattern — NeedSignRow vs TxnRow khác schema theo tab, rowKey check 'transaction_id' in row để generate key riêng"
    - "axios baseURL convention — dùng path '/ky-so/...' (không prefix '/api/') vì api instance đã có baseURL='/api' sẵn; khớp với SignModal + cau-hinh page"
    - "URL state sync — router.replace với scroll:false để không jump top khi state change; parsePositiveInt + parsePageSize guard URL tampering (T-12-04/07)"
    - "Socket realtime refresh-all pattern — khi nhận SIGN_COMPLETED/FAILED, gọi cả fetchCounts + fetchList; defense-in-depth BE đã filter room user_{staffId}"
    - "useMemo columns per tab — dep đúng handler tương ứng (handleSign / handleCancel / handleDownload); tab switch reset page=1 giữ pageSize"
    - "Tooltip truncate 80 chars cho error_message + show full trong title; dùng Tag color blue/green cho provider, Tag default cho doc type"

key-files:
  created:
    - e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx
  modified: []

key-decisions:
  - "axios path '/ky-so/...' thay vì '/api/ky-so/...' (deviation khỏi draft plan) — api instance có baseURL ending in '/api' nên prefix /api sẽ double; khớp convention thực tế trong dự án (SignModal, cau-hinh, tai-khoan pages)"
  - "File đơn ~800 dòng thay vì tách component — D-14 CONTEXT chỉ đạo: inline column defs + tab content trong 1 file để giữ đơn giản; chấp nhận trade-off file dài đổi lấy dễ trace state + 1 điểm maintain"
  - "Pagination state reset khi tab switch — setPage(1), giữ pageSize (D-11); tránh edge case user ở page 5 tab pending rồi switch tab completed chỉ có 1 page — page 5 invalid"
  - "initialLoading vs loading — initialLoading chỉ chạy 1 lần lúc mount (skeleton full page); loading dùng cho mọi refetch về sau (table prop loading) — tránh flash skeleton mỗi lần tab switch"
  - "showZero trong Badge — mặc định hiển thị 0 với style grey (D-05 CONTEXT); overflowCount=999 cho case user có rất nhiều giao dịch failed/completed"
  - "Error message theo HTTP status code — 403 → 'không có quyền', 404 → 'chưa sẵn sàng', default → 'không tải được'; BE message nếu có được ưu tiên"
  - "Tooltip error_message show full + truncate 80 chars — cân bằng UI không overflow + không mất thông tin lỗi chi tiết"
  - "destroyOnHidden trên Tabs — AntD 6 convention (thay destroyOnClose deprecated); giúp unmount Table khi switch tab nhằm clean up loading state"
  - "Tab switch KHÔNG refetch counts — counts đã fetch từ mount + refetch khi action success hoặc Socket event; tiết kiệm 1 round-trip"

requirements-completed:
  - UX-02
  - UX-03
  - UX-04
  - UX-05
  - UX-06

duration: ~15min
started: 2026-04-22T09:45:00Z
completed: 2026-04-22T10:00:00Z
---

# Phase 12 Plan 02: FE Page /ky-so/danh-sach — 4 tab Summary

**Trang `/ky-so/danh-sach` Next.js App Router client component — 4 tab (Cần ký / Đang xử lý / Đã ký / Thất bại) với Badge count, Table per tab, action buttons (ký / hủy / tải / ký lại), URL state sync, Socket.IO realtime refresh. Consume Phase 11-03/05/06 + 12-01 endpoints KHÔNG sửa.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-22T09:45:00Z
- **Completed:** 2026-04-22T10:00:00Z
- **Tasks:** 2
- **Files created:** 1 (page.tsx)
- **Files modified:** 0
- **TypeScript errors introduced:** 0 (baseline 21 pre-existing unchanged — 22 lines tsc output cùng)
- **Deviations:** 1 (Rule 1 bug — API path convention)

## Accomplishments

- **`src/app/(main)/ky-so/danh-sach/page.tsx`** — 806 dòng, 1 file tự túc:
  - 4 TabKey constants + TAB_LABELS tiếng Việt có dấu + TAB_BADGE_COLOR 4 màu (orange/cyan/green/red)
  - 2 row interfaces discriminated union: `NeedSignRow` (9 fields, tab Cần ký) vs `TxnRow` (13 fields, 3 tab txn)
  - URL state: `parsePositiveInt` + `parsePageSize` guard cả `-1`, `NaN`, `9999` → cap 100 (T-12-04/07 mitigation)
  - Fetchers: `fetchCounts()` (silent fail, giữ counts cũ) + `fetchList(tab, p, ps)` (toast error, reset rows)
  - 3 useEffect: Mount (Promise.all initial fetch) / State-change (refetch + syncUrl) / Socket listener
  - Socket refresh-all: bất kể event transaction_id có trong page hiện tại hay không, refetch cả counts + list (counts có thể đổi từ tab khác)
  - 3 action handlers bọc `useCallback`:
    - `handleSign` — `openSign()` với onSuccess callback refresh
    - `handleCancel` — `modal.confirm` + POST cancel + message success + parallel refresh
    - `handleDownload` — GET download + `window.open(url, '_blank', 'noopener,noreferrer')`
  - 4 column definitions bọc `useMemo` (dep đúng handler tương ứng):
    - `needSignColumns` — 5 cột, button primary "Ký số"
    - `pendingColumns` — 5 cột, button danger "Hủy"
    - `completedColumns` — 5 cột, button default "Tải file đã ký" (icon DownloadOutlined)
    - `failedColumns` — 5 cột, Tooltip error truncate 80 chars, button primary "Ký lại"
  - Helpers: `formatDate` (dayjs DD/MM/YYYY HH:mm), `docTypeLabel` (3 loại VB), `providerLabel` (fallback chain), `statusFallbackLabel` (tiếng Việt cho expired/cancelled)
  - Empty state tiếng Việt mỗi tab, Skeleton initial + Table loading prop refetch

## Task Commits

1. **Task 1: page.tsx structure + state + fetchers + Tabs + counts + socket** — `6c26b83` (feat)
2. **Task 2: 4 bộ column defs + 3 action handlers (sign/cancel/download/retry)** — `d9d8a3d` (feat)

## API Contract Consumed (verified)

| Method | Path | Purpose | Source |
|--------|------|---------|--------|
| GET | `/ky-so/danh-sach/counts` | Badge 4 tab | Phase 11-05 |
| GET | `/ky-so/danh-sach?tab=X&page=Y&page_size=Z` | List 1 tab paginated | Phase 11-05 |
| POST | `/ky-so/sign/:id/cancel` | Hủy txn pending | Phase 11-03 |
| GET | `/ky-so/sign/:id/download` | Presigned URL file đã ký | Phase 12-01 |

**Lưu ý:** Tất cả path dùng convention `'/ky-so/...'` (KHÔNG `'/api/ky-so/...'`) — axios instance `@/lib/api` đã có `baseURL='http://localhost:4000/api'`. Khớp với pattern đã thiết lập trong `SignModal.tsx:160` + `cau-hinh/page.tsx:207` + `tai-khoan/page.tsx:299`.

## Decisions Made

- **axios path convention khớp SignModal** — Plan 12-02 draft viết `api.get('/api/ky-so/danh-sach/counts')` nhưng thực tế `api.ts` đã cấu hình `baseURL='/api'`. Code đúng: `api.get('/ky-so/danh-sach/counts')`. Phát hiện qua grep các consumer hiện có. Áp dụng Rule 1 auto-fix.
- **1 file đơn 806 dòng** — D-14 CONTEXT cho phép; component tách ra không mang giá trị tái sử dụng (mỗi tab layout khác, row schema khác). File vẫn trace được dễ: 1 component + 4 useMemo columns + 3 useCallback actions + 2 helpers.
- **Reset page khi tab switch** — `setPage(1)` trong `onChange` Tab, giữ `pageSize`. UX chuẩn: user ở page 5 tab pending → switch tab completed chỉ có 2 rows → page 5 invalid → reset về 1.
- **Socket refresh-all pattern** — Bất kể `transaction_id` trong list hiện tại hay không, refresh cả counts + list. Counts có thể đổi từ tab khác (VD tab pending rời → tab completed tăng). Đúng với D-10 CONTEXT "no polling, socket triggered refetch".
- **Dùng `destroyOnHidden` trên Tabs** — AntD 6 convention. Khi switch tab, Table unmount để clean loading state + pagination reset. Tránh state leak giữa 4 tabs (mỗi tab có dataSource khác nhau).
- **`parsePositiveInt` + `parsePageSize` defense** — URL `?page=-1&pageSize=9999` attack vector (T-12-07). Parse reject non-positive, cap 100 (khớp BE SP cap). BE cũng có cap → defense-in-depth.
- **Error message theo HTTP status** — 403 → "Bạn không có quyền tải file này", 404 → "File đã ký chưa sẵn sàng hoặc giao dịch không tồn tại", default → "Không tải được file đã ký". BE message ưu tiên nếu có.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] API path convention — `/ky-so/...` thay vì `/api/ky-so/...`**

- **Found during:** Task 1 (before writing file — code review `api.ts` + existing consumers)
- **Issue:** Plan draft và các snippet trong `<action>` viết `api.get('/api/ky-so/danh-sach/counts')`. Nếu giữ nguyên, axios sẽ gọi `http://localhost:4000/api/api/ky-so/danh-sach/counts` (double `/api/`) — 404.
- **Root cause:** `e_office_app_new/frontend/src/lib/api.ts:3-5` cấu hình `const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api'; axios.create({ baseURL: API_URL })`. Mọi consumer hiện có dùng path relative (không `/api/` prefix).
- **Fix:** Tất cả API call trong page.tsx dùng `'/ky-so/...'`:
  - `api.get('/ky-so/danh-sach/counts')`
  - `api.get('/ky-so/danh-sach', { params: { tab, page, page_size } })`
  - `api.post('/ky-so/sign/${row.transaction_id}/cancel')`
  - `api.get('/ky-so/sign/${row.transaction_id}/download')`
- **Verification:** Grep existing consumers `api\.(get|post).*['"]/ky-so` → SignModal.tsx, SigningModal.tsx, tai-khoan/page.tsx, van-ban-den/[id]/page.tsx — tất cả dùng `/ky-so/...` không `/api/ky-so/...`. Convention đã established.
- **Impact:** Zero scope creep — chỉ là đúng convention. Nếu không fix, trang sẽ không gọi được API (runtime 404).
- **Committed in:** `6c26b83` (Task 1)

---

**Total deviations:** 1 (Rule 1 bug — API path convention)
**Impact on plan:** Bắt buộc cho runtime correctness. Nếu theo plan draft, trang sẽ broken 100%.

## Authentication Gates

None encountered. Page mount chỉ gọi API cần JWT — `api.ts` interceptor tự attach từ localStorage.

## Self-Check

- `e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx` — FOUND (806 lines)
- Commit `6c26b83` (Task 1) — FOUND in git log
- Commit `d9d8a3d` (Task 2) — FOUND in git log
- `grep "'need_sign'"` — PRESENT
- `grep "'pending'"` — PRESENT
- `grep "'completed'"` — PRESENT
- `grep "'failed'"` — PRESENT
- `grep "SOCKET_EVENTS.SIGN_COMPLETED"` — PRESENT
- `grep "SOCKET_EVENTS.SIGN_FAILED"` — PRESENT
- `grep "useSigning()"` — PRESENT
- `grep "page_size:"` — PRESENT (axios params)
- `grep "/ky-so/danh-sach/counts"` — PRESENT
- `grep "App.useApp"` — PRESENT
- `grep "handleSign"` — PRESENT (useCallback + column render onClick)
- `grep "handleCancel"` — PRESENT
- `grep "handleDownload"` — PRESENT
- `grep "window.open"` — PRESENT (inside handleDownload)
- `grep "modal.confirm"` — PRESENT (inside handleCancel)
- `grep "openSign({"` — PRESENT (inside handleSign)
- `grep "/ky-so/sign/\${row.transaction_id}/cancel"` — PRESENT
- `grep "/ky-so/sign/\${row.transaction_id}/download"` — PRESENT
- `grep "parsePageSize"` — PRESENT (T-12-07 mitigation)
- `grep "isValidTab"` — PRESENT (T-12-04 mitigation)
- `grep "destroyOnHidden"` — PRESENT (Tabs AntD 6 convention)
- TypeScript baseline: 22 lines tsc output pre-execution → 22 lines post-execution (0 new errors)
- `grep -E "danh-sach/page\.tsx" tsc_output` → empty (0 errors in new file)
- No `alert()` / `notification` popup usage — CONFIRMED (all via `message` / `modal.confirm` from `App.useApp()`)
- No `<Spin>` full-page — CONFIRMED (uses `<Skeleton>` initial, `loading` prop refetch)
- Tab labels Vietnamese có dấu: "Cần ký" / "Đang xử lý" / "Đã ký" / "Thất bại" — CONFIRMED
- Button labels Vietnamese: "Ký số" / "Hủy" / "Tải file đã ký" / "Ký lại" — CONFIRMED
- Empty state messages Vietnamese mỗi tab — CONFIRMED
- Confirm dialog Vietnamese — CONFIRMED ('Bạn có chắc muốn hủy giao dịch ký cho file "..."?')

## Known Stubs

None. Page fully functional end-to-end: fetch counts/list, action handlers wired, Socket listener active. Plan 12-03 sẽ seed test data và verify runtime với real transactions.

## Threat Flags

No new threat surface beyond `<threat_model>` trong plan. Page chỉ là thin render layer — mọi data flow qua BE API đã có JWT auth + owner check (Phase 11-03/04/05 + 12-01).

Các threat đã mitigate đầy đủ:

| Threat ID | Category | Mitigation Implemented |
|-----------|----------|------------------------|
| T-12-04 | T (Tampering) URL `?tab=X` | `isValidTab()` allowlist; tab lạ → fallback `need_sign` |
| T-12-05 | E (Elevation) Socket lọt event user khác | BE emit room `user_{staffId}` + FE refresh gọi API với JWT hiện tại (server-side filter) |
| T-12-06 | I (Info Disclosure) Presigned URL leak | TTL 600s (Plan 12-01) + `noopener,noreferrer` cho window.open |
| T-12-07 | T (Tampering) URL `?page=-1&pageSize=9999` | `parsePositiveInt` reject non-positive; `parsePageSize` cap 100 (khớp BE SP) |
| T-12-08 | E (Elevation) Bypass Modal.confirm | BE endpoint /cancel kiểm tra owner + status='pending' (Phase 11-03) — UI chỉ là UX |

## How Downstream Plans Consume This

**Plan 12-03 (E2E verify + seed)** — Sẽ test runtime trên trang này:
1. Seed 1 txn Cần ký + 1 txn Pending + 1 txn Completed (có signed_file_path) + 1 txn Failed
2. Navigate `/ky-so/danh-sach` → verify 4 tab hiển thị đúng count + row data
3. Click tab pending → click "Hủy" → verify row disappear + count giảm
4. Click tab completed → click "Tải file đã ký" → verify window.open + file download
5. Click tab failed → click "Ký lại" → verify SignModal mở + POST /sign tạo txn mới
6. Socket manually emit SIGN_COMPLETED → verify list auto refresh

**Phase 13 (UX polish)** — Layer lên trên trang này:
- Countdown 3:00 trong SignModal (UX-09) — không sửa page.tsx
- Root CA banner cho MYSIGN provider trong SignModal (UX-11 + DEP-02) — không sửa page.tsx
- Spam click disable trên button "Ký số" / "Ký lại" — có thể sửa page để disable trong thời gian openSign pending

## Next Plan Readiness

- Trang `/ky-so/danh-sach` live — mount page không 404, 4 tab render
- 4 API endpoint consumed đúng path + param — Phase 12-03 seed data sẽ thấy data hiển thị
- Socket listener registered khi page active — Phase 12-03 có thể smoke test SIGN_COMPLETED event
- Zero blockers cho Phase 12-03 — trang đã sẵn sàng E2E test

## Self-Check: PASSED

---
*Phase: 12-menu-ky-so-danh-sach-4-tab*
*Completed: 2026-04-22*
