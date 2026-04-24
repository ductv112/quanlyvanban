# Phase 12: Menu Ký số + Danh sách 4 tab UI — Context

**Gathered:** 2026-04-22
**Status:** Ready for planning
**Source:** Captured from conversation (2026-04-22) — scope rà với Phase 9-11.1 + khuyến nghị download endpoint

<domain>
## Phase Boundary

**Phase 12 giao 3 deliverable FE-heavy + 1 endpoint BE nhỏ:**

1. **Sidebar submenu thứ 3** `/ky-so/danh-sach` "Danh sách ký số" — hiển thị cho MỌI user (không admin-only), đứng sau "Tài khoản ký số cá nhân" trong group "KÝ SỐ". Breadcrumb tương ứng.
2. **Trang mới `app/(main)/ky-so/danh-sach/page.tsx`** — 4 Tabs (AntD) `items` mode với badge count: "Cần ký" / "Đang xử lý" / "Đã ký" / "Thất bại". Mỗi tab là Table + action menu + pagination.
3. **Backend endpoint mới `GET /api/ky-so/sign/:id/download`** — trả JSON `{ url: <presigned>, file_name, expires_in: 600 }` cho file đã ký; phân quyền: chỉ owner transaction (staff_id match). Dùng pattern presigned URL giống `incoming-doc.ts:435`.

**KHÔNG nằm trong Phase 12 (đã xong ở Phase 9-11.1):**
- Backend list API `/api/ky-so/danh-sach?tab=X` + `/counts` (Phase 11-05) — consume trực tiếp, 0 sửa
- `POST /api/ky-so/sign` + `/:id/cancel` (Phase 11-03) — consume trực tiếp
- `SignModal` + `useSigning` hook (Phase 11-06) — consume trực tiếp, 0 sửa
- Socket events `SIGN_COMPLETED` / `SIGN_FAILED` — đã có, chỉ cần listen
- Sidebar group "KÝ SỐ" + 2 submenu đầu (Phase 9-03, 10-02) — đã có
- Nút "Ký số" trên trang detail VB đi / VB dự thảo / HSCV (Phase 11-07/08) — đã có (đường dẫn thứ 2, không sửa)

**KHÔNG nằm trong Phase 12 (để Phase 14 Deploy):**
- MinIO production config (`MINIO_PUBLIC_URL` tách internal vs public, TLS, CORS, bucket policy PRIVATE)
- Audit log download vào MongoDB (non-repudiation log)
- Rate limit endpoint download

</domain>

<decisions>
## Implementation Decisions (Locked)

### D-01: Tách endpoint download file đã ký (Option B)
- **Quyết định:** Thêm endpoint MỚI `GET /api/ky-so/sign/:id/download` thay vì mở rộng endpoint attachment download hiện có.
- **Không sửa:** `/:docId/dinh-kem/:attachmentId/download` hiện tại (vẫn trả file gốc `file_path`).
- **Lý do:** DB giữ `file_path` (gốc) + `signed_file_path` (đã ký) ở 2 field riêng. Semantic phải tách — file gốc cho archive, file đã ký cho phát hành. Production cần audit riêng 2 hành động.

### D-02: Endpoint download — response shape & security
- **Response:** JSON `{ url: "<presigned-10min>", file_name: "<original>.pdf", expires_in: 600 }` (KHÔNG 302 redirect — để FE log client-side và tránh browser cache)
- **TTL presigned:** 600 giây (10 phút) — đủ click + đủ ngắn nếu URL bị leak
- **Auth:** `authenticate` middleware + kiểm tra owner transaction (`staff_id = req.user.staffId` hoặc admin)
- **Status checks:** txn phải `status='completed'` + `signed_file_path IS NOT NULL`, nếu không → 404 "Giao dịch chưa có file đã ký"
- **KHÔNG làm trong phase này:** Audit log MongoDB (deferred Phase 14)

### D-03: Endpoint mount position
- Mount trong `routes/ky-so-sign.ts` (cùng file với POST /sign, /:id/cancel, GET /:id). Path: `GET /:id/download`.
- Thứ tự route trong file: `POST /` → `POST /:id/cancel` → `GET /:id/download` → `GET /:id` (cuối để không catch path có suffix).
- Không thêm file route mới, không sửa `server.ts` mount order.

### D-04: Sidebar submenu thứ 3
- **Vị trí:** Sau item "Tài khoản ký số cá nhân" trong group "KÝ SỐ" tại [MainLayout.tsx:293](e_office_app_new/frontend/src/components/layout/MainLayout.tsx#L293).
- **Config:** `{ key: '/ky-so/danh-sach', icon: <SafetyCertificateOutlined />, label: 'Danh sách ký số' }` (dùng cùng icon với 2 submenu khác để group visual consistent)
- **Phân quyền:** Hiển thị cho MỌI user đã đăng nhập — không guard `isAdmin`.
- **Breadcrumbs:** Thêm entry `'/ky-so/danh-sach': 'Danh sách ký số'` vào BREADCRUMBS constant cuối file.

### D-05: Trang `/ky-so/danh-sach` — layout tổng
- **Structure:** Page header (title "Danh sách ký số" + icon) → Card chứa `<Tabs items={...}>` với `activeKey` sync URL query `?tab=`.
- **4 tab keys:** `need_sign` / `pending` / `completed` / `failed` — khớp EXACT với backend enum (Phase 11-05).
- **Badge count:** `<Badge count={counts.need_sign}>` ngay trong tab label.
- **Default tab:** `need_sign` (mở ra user thấy ngay việc cần làm).
- **Page card className:** `page-card` (theo CLAUDE.md convention).

### D-06: Tab "Cần ký" — hành vi
- **Columns:** "Mã VB" (doc_notation), "Tên file" (file_name), "Loại VB" (doc_type → display label: Văn bản đi / Dự thảo / HSCV), "Ngày tạo" (created_at), "Thao tác".
- **Action:** Button "Ký số" (icon `SafetyCertificateOutlined`, type primary) → gọi `openSign({ attachment: {id, file_name}, attachmentType, docId, onSuccess: refreshList })` từ `useSigning` hook.
- **Sau khi ký xong** (onSuccess fire): refetch `/counts` + refetch list tab `need_sign` (record đã chuyển sang `pending`).
- **Empty state:** "Bạn không có văn bản nào đang chờ ký" + icon.

### D-07: Tab "Đang xử lý" — hành vi
- **Columns:** "Mã VB", "Tên file", "Provider" (provider_name), "Bắt đầu lúc" (created_at), "Thao tác".
- **Action:** Button "Hủy" (type danger, icon `CloseOutlined`) → `Modal.confirm` (theo convention) → `POST /api/ky-so/sign/:id/cancel` → message.success + refetch.
- **Real-time:** Nếu worker emit `SIGN_COMPLETED` hoặc `SIGN_FAILED` với `transaction_id` trong list này → tự động remove khỏi tab + refetch counts (không cần user F5).

### D-08: Tab "Đã ký" — hành vi
- **Columns:** "Mã VB", "Tên file", "Provider", "Ngày ký" (completed_at), "Thao tác".
- **Action:** Button "Tải file đã ký" (icon `DownloadOutlined`) → GET `/api/ky-so/sign/:id/download` → nhận `{ url }` → `window.open(url, '_blank')` (trigger browser download).
- **Error handling:** Nếu 404 (file chưa sẵn sàng) / 500 → `message.error(...)`. KHÔNG retry tự động.

### D-09: Tab "Thất bại" — hành vi
- **Columns:** "Mã VB", "Tên file", "Lý do lỗi" (error_message, Tooltip + truncate 80 chars), "Thất bại lúc" (completed_at hoặc created_at), "Thao tác".
- **Action:** Button "Ký lại" (icon `ReloadOutlined`) → `openSign({...})` giống tab Cần ký → tạo transaction MỚI (không reset record cũ).
- **Chú thích:** Sau khi ký lại thành công, record cũ vẫn giữ `status='failed'` trong DB, record mới ở tab Đang xử lý/Đã ký. User có thể thấy cả 2 — đây là behavior đúng (audit trail).

### D-10: Badge count + realtime refresh
- **Initial fetch:** `GET /api/ky-so/danh-sach/counts` ngay khi page mount → 4 số.
- **Refetch triggers:**
  - Socket event `SIGN_COMPLETED` hoặc `SIGN_FAILED` (bất kể transaction_id có trong list hiện tại hay không — counts có thể thay đổi từ tab khác)
  - Action thành công (cancel / ký lại / ký mới) trong page
  - Tab change (optional — chỉ refetch list, không refetch counts)
- **KHÔNG polling** — đã có socket rồi, polling thừa.

### D-11: Pagination
- **Default page size:** 20 (khớp backend default Phase 11-05).
- **Size options:** `[10, 20, 50, 100]` (cap 100 khớp SP).
- **URL sync:** `?tab=X&page=Y&pageSize=Z` để refresh/share URL giữ state.
- **Tab switch:** Reset về page=1, giữ pageSize.

### D-12: Response shape khác nhau giữa các tab
- Tab `need_sign` KHÔNG có `transaction_id`, `provider_*`, `status`, `completed_at`, `error_message` — TypeScript discriminated union dựa trên `tab`:
  ```ts
  type NeedSignRow = { attachment_id, attachment_type, file_name, doc_id, doc_type, doc_label, doc_number, doc_notation, created_at }
  type TxnRow = { transaction_id, provider_code, provider_name, attachment_id, attachment_type, file_name, doc_id, doc_type, doc_label, status, error_message, created_at, completed_at }
  ```
- Mỗi tab có component column definition riêng → KHÔNG force shared columns.

### D-13: Nhất quán UI conventions (theo CLAUDE.md)
- AntD 6: `<Table>` với loading prop, `<Tabs items={...}>` (không deprecated tab children)
- Loading: `<Skeleton active>` cho initial, `loading` prop cho table refetch
- Notification: `message.success/error` qua `App.useApp()`, KHÔNG `alert()` / `notification` popup
- Icon button trong table: dùng dropdown `MoreOutlined` nếu nhiều action, button đơn cho 1 action
- Tiếng Việt có dấu TOÀN BỘ UI text

### D-14: File organization
- **BE mới:** chỉ sửa 1 file `backend/src/routes/ky-so-sign.ts` (thêm 1 handler) + optional comment update
- **FE mới:** 
  - 1 file mới: `frontend/src/app/(main)/ky-so/danh-sach/page.tsx`
  - 1 file sửa: `frontend/src/components/layout/MainLayout.tsx` (thêm 1 menu item + 1 breadcrumb entry)
- **Không tạo:** shared component riêng cho từng tab — dùng inline Column definitions trong page để giữ đơn giản (~1 file ~500 dòng OK).

### D-15: Plan structure (3 plans)
- **Plan 12-01 (Wave 1):** Backend endpoint download + sidebar submenu + breadcrumb. Nhỏ, không block FE page → có thể chạy trước.
- **Plan 12-02 (Wave 2):** Frontend page `/ky-so/danh-sach` 4 tab + realtime. Depends on 12-01 (endpoint phải live để tab Đã ký test được).
- **Plan 12-03 (Wave 3):** E2E verify + seed test data + UAT checkpoint. Depends on 12-02.

### Claude's Discretion
- Chi tiết column widths, spacing, responsive breakpoints
- Copy tiếng Việt cho empty state, tooltip, confirm dialogs
- Internal naming cho helpers (formatDocLabel, getTabColumns...)
- Error message exact wording (phải tiếng Việt có dấu)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap + Requirements
- `.planning/ROADMAP.md` — Phase 12 section (AC 1-5), Phase 13 & 14 (để biết scope ranh giới)
- `.planning/REQUIREMENTS.md` — SIGN-* / UX-* IDs nếu có cho Phase 12

### Prior phase SUMMARY (đã triển khai — consume as API contract)
- `.planning/phases/11-sign-flow-async-worker/11-03-SUMMARY.md` — POST `/ky-so/sign`, POST `/:id/cancel`, GET `/:id` (endpoint ref + error codes)
- `.planning/phases/11-sign-flow-async-worker/11-05-SUMMARY.md` — GET `/ky-so/danh-sach?tab=X` + `/counts` (response shapes CHÍNH XÁC theo tab)
- `.planning/phases/11-sign-flow-async-worker/11-06-SUMMARY.md` — `SignModal` + `useSigning` hook API signature
- `.planning/phases/09-admin-config-provider-adapters/09-03-SUMMARY.md` — sidebar group Ký số pattern (Phase 9)

### Backend code (read-first)
- `e_office_app_new/backend/src/routes/ky-so-sign.ts` — file sẽ thêm handler download
- `e_office_app_new/backend/src/routes/ky-so-danh-sach.ts` — API list 4 tab (đã có, KHÔNG sửa)
- `e_office_app_new/backend/src/routes/incoming-doc.ts` — line ~435 pattern presigned URL mẫu để copy
- `e_office_app_new/backend/src/lib/minio/client.ts` — presigned URL generation
- `e_office_app_new/backend/src/repositories/sign-transaction.repository.ts` — getById method để lấy txn + signed_file_path + staff_id owner

### Frontend code (read-first)
- `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` — sidebar items + BREADCRUMBS (lines 278-293 group KÝ SỐ, ~380-382 breadcrumbs)
- `e_office_app_new/frontend/src/hooks/use-signing.tsx` — useSigning hook API
- `e_office_app_new/frontend/src/components/signing/SignModal.tsx` — shared modal (KHÔNG sửa, chỉ consume qua hook)
- `e_office_app_new/frontend/src/lib/signing/types.ts` — shared types `AttachmentType`, `TxnStatus`, `SignCompletedEvent`, `SignFailedEvent`
- `e_office_app_new/frontend/src/lib/socket.ts` — `SOCKET_EVENTS.SIGN_COMPLETED` / `SIGN_FAILED`
- `e_office_app_new/frontend/src/lib/api.ts` — shared axios instance
- `e_office_app_new/frontend/src/app/(main)/ky-so/cau-hinh/page.tsx` — reference trang trong group Ký số (convention page structure)

### Project conventions
- `CLAUDE.md` — project instructions (maxLength, AntD 6, validation, Vietnamese, kebab-case paths, SP-first contract, wave rules)
- `e_office_app_new/docs/quy_uoc_chung.md` — quy ước chung dự án

</canonical_refs>

<specifics>
## Specific API Contracts (để planner không guess)

### GET /api/ky-so/danh-sach/counts → response
```json
{ "success": true, "data": { "need_sign": 0, "pending": 0, "completed": 0, "failed": 0 } }
```

### GET /api/ky-so/danh-sach?tab=need_sign&page=1&page_size=20 → response
```json
{
  "success": true,
  "data": [
    { "attachment_id": 42, "attachment_type": "outgoing", "file_name": "report.pdf",
      "doc_id": 101, "doc_type": "outgoing_doc",
      "doc_label": "VB đi số 15 — 01/UBND-VP",
      "doc_number": 15, "doc_notation": "01/UBND-VP",
      "created_at": "2026-04-21T10:00:00Z" }
  ],
  "pagination": { "total": 1, "page": 1, "pageSize": 20 }
}
```

### GET /api/ky-so/danh-sach?tab=pending|completed|failed → response
```json
{
  "success": true,
  "data": [
    { "transaction_id": 7, "provider_code": "SMARTCA_VNPT", "provider_name": "VNPT SmartCA",
      "attachment_id": 42, "attachment_type": "outgoing", "file_name": "report.pdf",
      "doc_id": 101, "doc_type": "outgoing_doc",
      "doc_label": "VB đi số 15 — 01/UBND-VP",
      "status": "pending", "error_message": null,
      "created_at": "2026-04-21T10:00:00Z", "completed_at": null }
  ],
  "pagination": { "total": 1, "page": 1, "pageSize": 20 }
}
```

### Endpoint MỚI: GET /api/ky-so/sign/:id/download → response
```json
{
  "success": true,
  "data": {
    "url": "https://minio.example/documents/signed/txn-7-signed.pdf?X-Amz-Expires=600&...",
    "file_name": "signed_report.pdf",
    "expires_in": 600
  }
}
```
**Error cases:**
- 401: unauth
- 403: không phải owner transaction
- 404: txn không tồn tại HOẶC status != 'completed' HOẶC signed_file_path IS NULL

### useSigning hook signature (consume, không sửa)
```ts
const { openSign, closeSign, renderSignModal } = useSigning();
openSign({
  attachment: { id: number, file_name: string },
  attachmentType: 'outgoing' | 'drafting' | 'handling',
  docId?: number,
  onSuccess?: () => void,  // refresh list + counts
});
return <>...page JSX...{renderSignModal()}</>;
```

### Socket events (consume)
```ts
socket.on(SOCKET_EVENTS.SIGN_COMPLETED, (payload: SignCompletedEvent) => { ... });
socket.on(SOCKET_EVENTS.SIGN_FAILED, (payload: SignFailedEvent) => { ... });
```

## Doc type → display label map
```ts
const DOC_TYPE_LABEL: Record<string, string> = {
  'outgoing_doc': 'Văn bản đi',
  'drafting_doc': 'Dự thảo',
  'handling_doc': 'Hồ sơ công việc',
};
```

## Provider code → display label (fallback dùng provider_name từ BE)
- `SMARTCA_VNPT` → "VNPT SmartCA"
- `MYSIGN_VIETTEL` → "Viettel MySign"

</specifics>

<deferred>
## Deferred Ideas

### Phase 14 (Deployment Readiness)
- **MinIO production config verify** — tách `MINIO_PUBLIC_URL` vs `MINIO_ENDPOINT` để presigned URL trỏ đúng domain user truy cập được. Test: nếu BE qua `minio:9000` internal, FE qua `https://s3.domain.gov.vn`, presigned URL PHẢI chứa public URL.
- **MinIO TLS + CORS** — MinIO sau nginx/traefik HTTPS, allow origin frontend production.
- **Bucket policy PRIVATE** — verify `mc policy get myminio/documents` = `none` (không public read).
- **Audit log download signed file** — log vào MongoDB `{ staff_id, txn_id, action: 'download_signed', ts, ip, user_agent }` cho non-repudiation.
- **Rate limit download endpoint** — tránh lạm dụng.
- **MinIO bucket versioning + lifecycle** — recover file xóa nhầm; auto-cleanup placeholder `signing-placeholders/*` sau 1 ngày.

### Phase 13 (Modal ký số robust + Root CA UX)
- Countdown 3:00, disable spam-click, maskClosable với confirm
- Root CA Viettel banner dismissible trong modal download khi provider = MYSIGN_VIETTEL
- HDSD cài Root CA PDF + link `.cer` download
- `localStorage.dismiss_root_ca_banner`

### Nice-to-have không xác định phase
- Filter theo provider trong mỗi tab
- Filter theo ngày (from/to)
- Search theo tên file / số hiệu
- Export danh sách ra Excel
- Bulk cancel (chọn nhiều txn Đang xử lý để hủy cùng lúc)

</deferred>

---

*Phase: 12-menu-ky-so-danh-sach-4-tab*
*Context captured: 2026-04-22 — từ conversation rà scope + khuyến nghị Option B (download endpoint dedicated)*
