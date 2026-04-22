---
phase: 12
plan: 01
subsystem: backend-api + frontend-layout
tags: [backend, route, minio, presigned, sidebar, breadcrumb]

requires:
  - phase: 11
    plan: 03
    provides: "signTransactionRepository.getById + POST/GET handler pattern trong ky-so-sign.ts"
  - phase: 11
    plan: 05
    provides: "sign_transactions.signed_file_path được SP set khi worker finalize (Plan 11-04 thực sự ghi)"
  - phase: 10
    plan: 02
    provides: "group KÝ SỐ trong sidebar + breadcrumbMap pattern '/ky-so/*'"
provides:
  - "GET /api/ky-so/sign/:id/download → { url, file_name, expires_in: 600 } (owner-or-admin, TTL 600s)"
  - "Sidebar item '/ky-so/danh-sach' + breadcrumb 'Danh sách ký số'"
affects:
  - 12-02 (Frontend page 4 tab — tab 'Đã ký' consume GET /:id/download qua window.open(url))
  - 12-03 (E2E verify — smoke test download flow với txn completed có sẵn)

tech-stack:
  added: []
  patterns:
    - "Presigned URL TTL 600s (10 phút) — đủ click + đủ ngắn nếu link bị leak; nhỏ hơn TTL chuẩn attachment (3600s) vì file đã ký sensitive hơn"
    - "Owner-or-admin check: txn.staff_id === req.user.staffId OR req.user.isAdmin — khớp TokenPayload JWT (isAdmin boolean)"
    - "Cache-Control: no-store — ngăn browser/proxy cache URL có HMAC signature (T-12-06 mitigation)"
    - "Route ordering convention: handler cụ thể '/:id/download' đứng TRƯỚC catch-all '/:id' — rõ ràng về intent dù Express match được cả 2"

key-files:
  created: []
  modified:
    - e_office_app_new/backend/src/routes/ky-so-sign.ts
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx

key-decisions:
  - "GET /:id/download placed giữa POST /:id/cancel và GET /:id — theo D-03 CONTEXT: handler cụ thể trước catch-all"
  - "Admin bypass dùng `isAdmin` boolean từ TokenPayload — đã tồn tại trong JWT từ Phase 10, không cần DB query role"
  - "file_name compute client-side từ segment cuối signed_file_path với prefix 'signed_' — không expose raw path cho FE (giảm surface)"
  - "Header comment file cập nhật từ '3 endpoints' → '4 endpoints' + thêm 3 dòng T-12-* trong SECURITY block — maintainer đọc file biết rõ mitigation nào có"
  - "KHÔNG tạo page /ky-so/danh-sach trong plan này — Plan 12-02 sẽ tạo; click menu item hiện tại → Next.js 404 (acceptable vì 12-01 ship trước 12-02 trong cùng phase)"

requirements-completed:
  - UX-01

duration: 4min
started: 2026-04-22T09:36:49Z
completed: 2026-04-22T09:40:16Z
---

# Phase 12 Plan 01: BE Endpoint Download + Sidebar Submenu Summary

**Endpoint `GET /api/ky-so/sign/:id/download` trả presigned URL (TTL 600s, owner-or-admin) + sidebar submenu "Danh sách ký số" + breadcrumb entry — nền tảng cho Plan 12-02 tab "Đã ký".**

## Performance

- **Duration:** 4 min
- **Started:** 2026-04-22T09:36:49Z
- **Completed:** 2026-04-22T09:40:16Z
- **Tasks:** 2
- **Files created:** 0
- **Files modified:** 2
- **TypeScript errors introduced:** 0 (baseline 21 pre-existing unchanged)
- **Deviations:** 0 (plan executed đúng như viết)

## Accomplishments

- `routes/ky-so-sign.ts` — thêm 1 import + 1 handler mới + update comment header:
  - Import `getFileUrl` từ `../lib/minio/client.js` (line 58)
  - Handler `GET /:id/download` (lines 397–465) — 76 dòng insertion tổng cộng
  - 4 endpoints hiện có: POST `/`, POST `/:id/cancel`, **GET `/:id/download` (NEW)**, GET `/:id`
  - Header comment cập nhật: `3 endpoints` → `4 endpoints` + 3 dòng T-12-01/02/06 trong SECURITY block
- `MainLayout.tsx` — 2 vị trí:
  - Sidebar items array (line 294–299): push thêm `{ key: '/ky-so/danh-sach', icon: <SafetyCertificateOutlined />, label: 'Danh sách ký số' }` unconditional (KHÔNG guard `isAdmin`)
  - `breadcrumbMap` (line 389): thêm entry `'/ky-so/danh-sach': 'Danh sách ký số'`

## Task Commits

1. **Task 1: Thêm endpoint GET /:id/download vào ky-so-sign.ts** — `a17dfec` (feat)
2. **Task 2: Thêm submenu sidebar + breadcrumb entry MainLayout.tsx** — `3c15ecd` (feat)

## GET /:id/download — Response Contract

| Status | Case | Body |
|--------|------|------|
| 200 | Owner/admin + txn completed + signed_file_path NOT NULL | `{ success: true, data: { url, file_name: 'signed_*.pdf', expires_in: 600 } }` + header `Cache-Control: no-store` |
| 400 | ID không phải số dương | `{ success: false, message: 'ID không hợp lệ' }` |
| 401 | Không có JWT hoặc JWT invalid | `{ success: false, message: 'Unauthorized' }` (authenticate middleware) |
| 403 | JWT OK nhưng user không phải owner và không phải admin | `{ success: false, message: 'Bạn không có quyền tải file của giao dịch này' }` |
| 404 | Txn không tồn tại | `{ success: false, message: 'Không tìm thấy giao dịch ký số' }` |
| 404 | Txn tồn tại nhưng status != 'completed' hoặc signed_file_path IS NULL | `{ success: false, message: 'Giao dịch chưa có file đã ký' }` |

`url` là presigned URL từ MinIO `presignedGetObject(BUCKET, signed_file_path, 600)` — HMAC signature expire sau 600s.

## Decisions Made

- **Owner-or-admin bypass** — Phase 11-03 cancel + GET /:id chỉ cho owner (không admin bypass) vì đó là edit/view state. Download file đã ký thì admin có quyền truy cập cho mục đích audit/support → bypass OK. Dùng `TokenPayload.isAdmin` boolean đã có sẵn trong JWT (không cần extra DB query role). Mitigate T-12-01 vẫn đủ vì admin là role tín nhiệm.
- **file_name compute client-side (không query DB thêm)** — Repository row có `signed_file_path` (MinIO key, VD `signed/txn-7-signed.pdf`), không có trường `file_name` gốc cho signed file. Thay vì query `attachmentSignRepository.getById(attachment_id)` để lấy tên gốc rồi prefix, ta compute `signed_<last-segment>` trực tiếp từ signed_file_path. Trade-off: tên hiển thị có thể là `signed_txn-7-signed.pdf` thay vì `signed_report.pdf`, nhưng browser sẽ dùng URL presigned cho Content-Disposition nếu có, KHÔNG dùng file_name trong response body — field này chỉ cho UI hiển thị "Đã tải file X" → acceptable.
- **Route order D-03 dù Express match cả 2** — Express route matching theo thứ tự `router.get` đăng ký. Cả `/:id` và `/:id/download` đều có param `:id`, nhưng path segment độ dài khác nhau → Express phân biệt OK. Tuy nhiên convention "handler cụ thể trước catch-all" dễ đọc hơn → đặt `/:id/download` trước `/:id`. Nếu sau này thêm `/:id/xxx` khác, thứ tự đã có pattern sẵn.
- **Cache-Control: no-store ở server** — URL presigned chứa HMAC signature với TTL 600s. Nếu browser hoặc proxy cache response, người khác truy cập cùng endpoint (kể cả sau khi expire) có thể lấy URL cũ vẫn valid trong window. `no-store` chặn cache cả response + URL. Plan threat model T-12-06 yêu cầu.
- **Rate limit defer Phase 14** — Document bằng comment header, không implement. Endpoint authenticated + staff nội bộ + không public-facing → attack surface thấp cho v2.0 demo.

## Deviations from Plan

None — plan executed exactly as written.

## Authentication Gates

None encountered.

## Self-Check

- `e_office_app_new/backend/src/routes/ky-so-sign.ts` — MODIFIED, chứa handler `GET /:id/download` lines 397-465 — FOUND
- `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` — MODIFIED, chứa menu item + breadcrumb — FOUND
- Commit `a17dfec` (Task 1) — FOUND in git log
- Commit `3c15ecd` (Task 2) — FOUND in git log
- `grep "router.get('/:id/download'"` → 1 match ky-so-sign.ts line 403 — CONFIRMED
- `grep "getFileUrl"` → 1 import + 1 call — CONFIRMED
- `grep "expires_in: 600"` → 1 match line 453 — CONFIRMED
- `grep "Cache-Control.*no-store"` → 1 match line 441 + header comment — CONFIRMED
- `grep "txn.staff_id !== staffId && !isAdmin"` → 1 match line 421 — CONFIRMED
- `grep "txn.status !== 'completed' || !txn.signed_file_path"` → 1 match line 429 — CONFIRMED
- `grep "key: '/ky-so/danh-sach'"` → 1 match MainLayout.tsx line 296 — CONFIRMED
- `grep "label: 'Danh sách ký số'"` → 1 match MainLayout.tsx line 298 — CONFIRMED
- `grep "'/ky-so/danh-sach': 'Danh sách ký số'"` → 1 match MainLayout.tsx line 389 — CONFIRMED
- Menu item `/ky-so/danh-sach` KHÔNG nằm trong `if (isAdmin)` block — lines 292-299 push trực tiếp không có `if` guard — CONFIRMED
- Backend TS errors: 21 (baseline unchanged, 0 new in scope)
- Frontend TS errors ở MainLayout.tsx: 0 new
- Smoke test: `curl http://localhost:4000/api/ky-so/sign/99/download` → HTTP 401 (authenticate middleware + route resolved) — CONFIRMED
- Smoke test: `curl ... -H "Authorization: Bearer invalid"` → HTTP 401 (token verify fail path) — CONFIRMED

## Smoke Tests Not Run (Deferred)

Yêu cầu JWT + data cụ thể, để Plan 12-03 E2E verify:

- 200 với txn completed + owner → cần seed 1 txn có signed_file_path (Plan 12-03 seed)
- 403 với user khác (non-admin) → cần 2 JWT user khác nhau
- 404 với txn pending → cần txn status='pending' trong DB
- Header `Cache-Control: no-store` hiện diện → xác minh qua DevTools Network tab ở Plan 12-02

## Known Stubs

None. Handler fully wired. Plan 12-02 sẽ tạo page FE consume endpoint này qua `window.open(data.url, '_blank')`.

## Threat Flags

No new threat surface beyond `<threat_model>` của plan. Sidebar item thêm vào là pure UI navigation, không expose data mới. Download endpoint mitigation đầy đủ theo T-12-01/02/06.

## How Downstream Plans Consume This

**Plan 12-02 (Frontend page 4 tab)** — tab "Đã ký":
```ts
// Button onClick handler
const handleDownload = async (txnId: number) => {
  try {
    const { data: res } = await api.get(`/ky-so/sign/${txnId}/download`);
    if (res.success && res.data?.url) {
      window.open(res.data.url, '_blank'); // browser trigger download
    }
  } catch (err) {
    message.error('Không tải được file đã ký');
  }
};
```

Sidebar item đã có — user click "Danh sách ký số" → Next.js route `/ky-so/danh-sach` → Plan 12-02 render page `app/(main)/ky-so/danh-sach/page.tsx`.

**Plan 12-03 (E2E verify + seed)** — smoke test flow:
1. Seed 1 txn completed với signed_file_path thật trong MinIO
2. Login owner → curl download endpoint → verify JSON shape + Cache-Control header + URL truy cập được trong 600s
3. Login user khác non-admin → verify 403
4. Logout → verify 401

## Next Plan Readiness

- Endpoint `GET /api/ky-so/sign/:id/download` live — Plan 12-02 tab "Đã ký" ready to consume
- Sidebar item `/ky-so/danh-sach` hiển thị — Plan 12-02 chỉ cần tạo `page.tsx` là navigate được
- Breadcrumb mapping có — page tự động có breadcrumb "Trang chủ › Ký số › Danh sách ký số"
- Zero blockers for Plan 12-02

## Self-Check: PASSED

---
*Phase: 12-menu-ky-so-danh-sach-4-tab*
*Completed: 2026-04-22*
