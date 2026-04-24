# Phase 13: Modal ký số robust + Root CA UX — Context

**Gathered:** 2026-04-22
**Status:** Ready for planning
**Source:** Interactive discuss-phase — 4 gray area locked

<domain>
## Phase Boundary

Phase 13 polish UX flow ký số (modal + bell notification) + trải nghiệm Root CA Viettel cho end user. 3 deliverable chính:

1. **SignModal polish** — countdown 3:00 UI render, spam-click disable, 2 button semantic (Đóng vs Hủy ký số) clear — UX-07, UX-08, UX-09
2. **Bell notification system** — Postgres-backed persistent notifications, toast + badge + dropdown trong header, scope: sign events only — UX-10
3. **Root CA UX** — banner dismissible trong trang danh sách ký số sau khi user tải file MySign lần đầu + copy Root CA files vào `frontend/public/root-ca/` sẵn sàng tải từ URL tĩnh — UX-11, DEP-02

**KHÔNG thuộc Phase 13:**
- Notification types khác (VB đến mới, HSCV giao, lịch họp...) — infrastructure mở rộng dễ nhưng scope Phase 13 chỉ sign events; generic notification types defer
- MinIO production config (public URL/TLS/CORS) — Phase 14
- Rate limit download endpoint — Phase 14
- Audit log MongoDB — Phase 14 (tech gap độc lập)
- `SigningModal.tsx` legacy cleanup — nếu có thời gian sau Phase 13

**Foundation đã có sẵn (không làm lại):**
- SignModal khung đầy đủ: `initiating` state, `MAX_MODAL_LIFETIME_MS=240_000` internal timer, `Hủy ký số` button (pending), `Đóng (chạy nền)` button (pending), `Đóng` button (terminal), Alert description đã giải thích "Đóng chạy nền" — chỉ thiếu countdown UI visual
- Phase 12 hotfix đã fix `mask={{ closable: false }}` (AntD 6) — AC#1.a của UX-08 xong
- Socket events `SIGN_COMPLETED` / `SIGN_FAILED` đã emit (BE Phase 11-04) + listen (FE Phase 11-06) — bell chỉ cần hook vào
- Root CA files đã có trong repo `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Code demo ky Mysign/DEMO_CLOUD_CA_JAVA/RootCA/viettel-ca-new.cer` + HDSD PDF

</domain>

<decisions>
## Implementation Decisions (Locked)

### Bell Notification Architecture (UX-10)

- **D-01:** Bell notification lưu vào **PostgreSQL** table mới `public.notifications` — pattern repository + SP nhất quán với stack.
- **D-02:** Schema tối thiểu:
  ```sql
  CREATE TABLE public.notifications (
    id            BIGSERIAL PRIMARY KEY,
    staff_id      INTEGER NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
    type          VARCHAR(50) NOT NULL,    -- 'sign_completed' | 'sign_failed'
    title         VARCHAR(200) NOT NULL,
    message       TEXT,
    link          VARCHAR(500),            -- /ky-so/danh-sach?tab=completed
    metadata      JSONB,                   -- { transaction_id, provider_code, file_name }
    is_read       BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    read_at       TIMESTAMPTZ
  );
  CREATE INDEX idx_notifications_staff_unread ON public.notifications(staff_id, is_read, created_at DESC);
  ```
- **D-03:** SPs cần tạo:
  - `fn_notification_create(staff_id, type, title, message, link, metadata)` — insert row
  - `fn_notification_list(staff_id, limit, offset)` — list paginated, order by created_at DESC
  - `fn_notification_unread_count(staff_id)` — badge count
  - `fn_notification_mark_read(id, staff_id)` — mark 1 item
  - `fn_notification_mark_all_read(staff_id)` — "Đánh dấu đã đọc tất cả"
- **D-04:** **Retention 30 ngày** — cron/scheduled cleanup hoặc thủ công; Phase 13 chỉ tạo structure, cleanup job defer (document trong CONTEXT).
- **D-05:** **Scope event Phase 13**: CHỈ `sign_completed` + `sign_failed` — infrastructure sẵn sàng extend cho event khác sau, nhưng không làm trong Phase 13.
- **D-06:** Worker (Phase 11-04) `emitSignCompleted`/`emitSignFailed` extend thêm `notificationRepo.create(...)` BEFORE `socket.emit(...)` — persist trước, emit sau. Worker đã có staffId context.
- **D-07:** API mới `GET /api/notifications` + `PATCH /api/notifications/:id/read` + `PATCH /api/notifications/read-all` — authenticate, staff_id từ JWT.

### Bell UI (UX-10)

- **D-08:** Icon bell đặt **trong `MainLayout` header** (gần avatar dropdown) — pattern chung admin dashboard. Icon `BellOutlined` + `<Badge count={unreadCount}>`.
- **D-09:** Click bell → AntD `<Dropdown>` hoặc `<Popover>` hiển thị 10 notification gần nhất + link "Xem tất cả" (nếu > 10) + button "Đánh dấu đã đọc tất cả".
- **D-10:** Mỗi item:
  - Icon status (✓ hoặc ✗) theo type
  - Title (VD: "Ký số thành công: report.pdf")
  - Message ngắn
  - Relative time (dayjs.fromNow(): "vài giây trước", "5 phút trước")
  - Click item → navigate tới `link` + mark read
- **D-11:** **Toast** khi nhận socket event realtime (user đang online) — dùng AntD `notification.success()` / `.error()` 3s auto close — defence-in-depth: check `payload.staff_id === currentUser.staffId` trước khi show (đã có pattern Phase 12).
- **D-12:** Fetch list mỗi khi mở dropdown (stale-while-revalidate: render cache cũ + fetch mới). Unread count refresh qua socket event trigger.

### Countdown UI (UX-09)

- **D-13:** **Circular progress + MM:SS center** — AntD `<Progress type='circle' size={120} percent={...}>` với `format={(p) => '2:45'}`.
- **D-14:** Timer source-of-truth: **FE local timer**, khởi chạy từ `POST /api/ky-so/sign` response (`expires_at` hoặc `created_at + 180s` nếu chưa có expires_at). Tick every 1s bằng `setInterval`.
- **D-15:** Color state theo remaining time:
  - `> 60s`: xanh (`strokeColor: '#1B3A5C'`)
  - `30s - 60s`: vàng (`strokeColor: '#D97706'`)
  - `< 30s`: đỏ (`strokeColor: '#DC2626'`)
- **D-16:** Khi hết 3:00 (countdown = 0): transition modal state sang `expired` (đã có từ Phase 11-06 — chỉ cần render nếu FE timer hết trước khi BE emit `expired`). Hiển thị Alert error "OTP hết hạn — vui lòng thử lại" + button "Đóng".
- **D-17:** Text dưới countdown: "Vui lòng xác nhận OTP trên ứng dụng **{providerName}** trên điện thoại" — `providerName` dynamic (SmartCA VNPT / MySign Viettel).

### SignModal Spam-click & Semantics (UX-07, UX-08)

- **D-18:** Button "Thực hiện ký" **KHÔNG TỒN TẠI trong SignModal hiện tại** — flow hiện là: user click "Ký số" ở bên ngoài → openSign() → SignModal mount → POST /sign AUTO fire ngay trong useEffect. Spam protection hiện đã có qua `initiating` state (line 130 SignModal). Nhưng UX-07 nói "button Thực hiện ký" → gợi ý có confirm step trước khi POST. Gray area đã chốt: **giữ auto-fire, KHÔNG thêm confirm button**. Spam protection bảo đảm qua:
  - `openSign()` trong `useSigning` hook — guard `if (open) return` (đã có)
  - Caller (table action button "Ký số") — disable button khi hook state `open=true` (có thể Phase 13 verify, chưa chắc đã có)
- **D-19:** Verify caller "Ký số" button các tab (12-02) có disable pattern khi modal đang open — nếu chưa có thì fix trong Phase 13 (nhỏ, 1-2 dòng per tab).
- **D-20:** 2 button footer khi `status='pending'`:
  - **"Hủy ký số"** (type=danger, icon `CloseOutlined`) — POST `/:id/cancel` → mark cancelled → modal close
  - **"Đóng (chạy nền)"** (default) — modal close ONLY, transaction pending tiếp tục, bell notification sẽ báo sau
- **D-21:** 1 button footer khi terminal state:
  - **"Đóng"** (type=primary) — modal close, không ảnh hưởng txn (đã terminal)

### Root CA Banner (UX-11)

- **D-22:** **Trigger**: banner xuất hiện **ngay sau** user click "Tải file đã ký" lần đầu tiên trong tab Đã ký **AND** transaction provider_code = `MYSIGN_VIETTEL` **AND** `localStorage.getItem('dismiss_root_ca_banner') !== 'true'`.
- **D-23:** **Vị trí**: AntD `<Alert>` type=info, placement ngay DƯỚI page header `/ky-so/danh-sach`, span full width. Không phải modal popup.
- **D-24:** **Nội dung banner**:
  - Icon `SafetyCertificateOutlined` + title "Cần cài Root CA Viettel để Adobe Reader hiển thị chữ ký hợp lệ"
  - Message: "Nếu Adobe Reader báo chữ ký không xác thực, hãy cài Root CA Viettel 1 lần duy nhất theo hướng dẫn."
  - 2 button action:
    - "Tải Root CA (.cer)" → `<a href="/root-ca/viettel-ca-new.cer" download>` (URL tĩnh)
    - "Xem hướng dẫn (PDF)" → `<a href="/root-ca/huong-dan-cai-root-ca.pdf" target="_blank">`
  - Icon X (close) góc phải → set `localStorage.dismiss_root_ca_banner=true` + unmount banner
- **D-25:** **Dismiss scope**: per-browser/device qua localStorage (không lưu DB). User sang máy khác sẽ thấy lại banner — chấp nhận vì scope nhỏ.
- **D-26:** Sau khi banner mount 1 lần, set `localStorage.setItem('root_ca_banner_shown_once', 'true')` → chỉ hiện khi user click download lần đầu, lần sau download vẫn không hiện (trừ khi user clear localStorage).

### Root CA Files (DEP-02)

- **D-27:** Source files đã có trong repo tại:
  - `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Code demo ky Mysign/DEMO_CLOUD_CA_JAVA/RootCA/viettel-ca-new.cer` — file .cer chính (dùng bản NEW)
  - `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/HUONG DAN CAI DAT CTS ROOT CA VIETTEL  Mysign.pdf` — PDF HDSD
- **D-28:** Copy sang `e_office_app_new/frontend/public/root-ca/` với tên chuẩn hóa:
  - `viettel-ca-new.cer` (giữ nguyên tên gốc)
  - `huong-dan-cai-root-ca.pdf` (đổi tên kebab-case, không dấu, không space)
- **D-29:** **Files committed vào git** (không gitignore) — size `.cer` thường < 2KB, PDF có thể 500KB-2MB, chấp nhận được. Lý do: deploy server lấy code từ git, không cần copy script riêng.
- **D-30:** Next.js 16 tự serve `public/*` tại URL root — `/root-ca/viettel-ca-new.cer` sẽ hoạt động out-of-the-box.

### Claude's Discretion

- Exact copy text tiếng Việt cho toast, banner title, empty state "Không có thông báo"
- Header bell icon placement chi tiết (trước/sau avatar, spacing)
- Dropdown max-height + scroll behavior
- Toast position (top-right default AntD OK)
- Cron/scheduled notification cleanup — defer Phase 14 hoặc sau (document trong SUMMARY.md không làm)
- Circular progress size, stroke width, animation easing
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap + Requirements
- `.planning/ROADMAP.md` — Phase 13 section (AC 1-5 + Phase 14 boundary)
- `.planning/REQUIREMENTS.md` — UX-07, UX-08, UX-09, UX-10, UX-11, DEP-02

### Prior phase SUMMARY (foundation)
- `.planning/phases/11-sign-flow-async-worker/11-04-SUMMARY.md` — Worker emit pattern (bell sẽ extend `emitSignCompleted`/`emitSignFailed` để persist notification trước emit)
- `.planning/phases/11-sign-flow-async-worker/11-06-SUMMARY.md` — SignModal + useSigning hook API signature
- `.planning/phases/12-menu-ky-so-danh-sach-4-tab/12-02-SUMMARY.md` — Page `/ky-so/danh-sach` (Root CA banner sẽ mount ở đây)
- `.planning/phases/12-menu-ky-so-danh-sach-4-tab/12-CONTEXT.md` — Parent phase decisions

### Backend code (read-first)
- `e_office_app_new/backend/src/lib/signing/sign-events.ts` — `emitSignCompleted` / `emitSignFailed` (sẽ extend tạo notification row)
- `e_office_app_new/workers/src/signing-poll.worker.ts` — caller của emitSign* (flow persist notification)
- `e_office_app_new/backend/src/repositories/` — pattern repository để tạo `notification.repository.ts` mới
- `e_office_app_new/backend/src/routes/` — pattern route file để tạo `notifications.ts` mới
- `e_office_app_new/database/schema/000_schema_v2.0.sql` — MASTER schema (thêm table `notifications` + 5 SPs)

### Frontend code (read-first)
- `e_office_app_new/frontend/src/components/signing/SignModal.tsx` — file sẽ polish countdown UI + verify 2 button
- `e_office_app_new/frontend/src/hooks/use-signing.tsx` — hook, có thể cần extend spam-protection
- `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` — nơi mount icon bell (header section, gần avatar)
- `e_office_app_new/frontend/src/lib/socket.ts` — SOCKET_EVENTS, bell component sẽ listen chung
- `e_office_app_new/frontend/src/lib/api.ts` — axios instance cho API notifications
- `e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx` — nơi mount Root CA banner (conditional render theo D-22)

### External docs (đã có trong repo)
- `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/HUONG DAN CAI DAT CTS ROOT CA VIETTEL  Mysign.pdf` — HDSD end user cài Root CA (source cho copy vào public/)
- `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Code demo ky Mysign/DEMO_CLOUD_CA_JAVA/RootCA/viettel-ca-new.cer` — Root CA certificate (source cho copy vào public/)

### Project conventions
- `CLAUDE.md` — AntD 6, maxLength, Vietnamese diacritics, kebab-case paths, SP-first contract, field-mismatch lessons (checklist 1-14)
- `CLAUDE.md` section "DB Migration Strategy" — schema change PHẢI edit `schema/000_schema_v2.0.sql` trực tiếp (idempotent), KHÔNG tạo file migration rời

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **SignModal.tsx** — khung countdown timer đã có (`MAX_MODAL_LIFETIME_MS=240_000`), chỉ cần thêm UI visual + đổi từ 240s xuống 180s cho match spec 3:00 (cân nhắc giữ 4 phút buffer nếu BE expires_at=3 phút — D-14 quyết định source of truth là FE với 3:00 khớp spec)
- **AntD `<Progress type='circle'>`** — built-in, không cần install thêm
- **AntD `<Badge>`** + `<Dropdown>` — built-in cho bell
- **`dayjs`** — đã install, dùng `.fromNow()` cho relative time (cần `dayjs.extend(relativeTime)` + locale vi)
- **Socket `getSocket()`** — đã có trong lib/socket.ts, bell component listen chung không conflict SignModal listener

### Established Patterns
- **Repository pattern** — const object export, `callFunction<T>`/`callFunctionOne<T>` — notification.repository.ts theo pattern này
- **SP naming** — `public.fn_notification_*` (public schema vì entity system-level, không phải edoc)
- **Socket event filter** — `if (payload.staff_id !== currentUser.staffId) return` — áp dụng cho bell toast (defense-in-depth dù BE đã emit tới room)
- **Error mapping** — `handleDbError` pattern trong route file (xem `incoming-doc.ts`)
- **Auth middleware** — `authenticate` trung gian cho mọi route /api/notifications

### Integration Points
- **Worker → notification persist** — `workers/src/signing-poll.worker.ts` gọi `emitSignCompleted/Failed` → extend để call `notificationRepo.create()` TRƯỚC socket.emit
- **Header → bell mount** — `MainLayout.tsx` hiện có header với avatar, thêm bell icon trước avatar
- **`/ky-so/danh-sach` → Root CA banner mount** — conditional render sau page header, trước Tabs
- **Public static** — `public/root-ca/` là Next.js convention, URL `/root-ca/*` tự serve

</code_context>

<specifics>
## Specific Ideas & Patterns

### Notification API shape
```
GET /api/notifications?page=1&pageSize=10
→ { success, data: [{ id, type, title, message, link, metadata, is_read, created_at }...], pagination }

GET /api/notifications/unread-count
→ { success, data: { count: 3 } }

PATCH /api/notifications/:id/read
→ { success, data: { id, is_read: true, read_at } }

PATCH /api/notifications/read-all
→ { success, data: { updated_count: 3 } }
```

### Bell component render structure (pseudo)
```tsx
<Dropdown trigger={['click']} overlay={<NotificationDropdown />}>
  <Badge count={unreadCount} offset={[-4, 4]}>
    <BellOutlined style={{ fontSize: 20 }} />
  </Badge>
</Dropdown>
```

### NotificationDropdown
- Header row: "Thông báo" + button "Đánh dấu đã đọc tất cả" (disable nếu unread=0)
- List 10 items max, border-bottom separator
- Footer: link "Xem tất cả" → `/thong-bao` (nếu sau này làm trang chi tiết, Phase 13 chỉ stub hoặc bỏ)
- Empty: "Không có thông báo mới"

### Root CA banner
```tsx
<Alert
  type="info"
  showIcon
  icon={<SafetyCertificateOutlined />}
  message="Cần cài Root CA Viettel để Adobe Reader hiển thị chữ ký hợp lệ"
  description={
    <Space>
      <span>Nếu Adobe Reader báo chữ ký không xác thực, hãy cài Root CA Viettel 1 lần duy nhất.</span>
      <a href="/root-ca/viettel-ca-new.cer" download>Tải Root CA (.cer)</a>
      <a href="/root-ca/huong-dan-cai-root-ca.pdf" target="_blank">Xem hướng dẫn (PDF)</a>
    </Space>
  }
  closable
  onClose={() => localStorage.setItem('dismiss_root_ca_banner', 'true')}
/>
```

### Plan breakdown (proposed — let planner confirm)
- **Plan 13-01**: BE notification infrastructure — migration table + 5 SPs + repository + routes + worker extend (6 tasks)
- **Plan 13-02**: FE bell component — icon + badge + dropdown + toast + socket listener + MainLayout integration (3 tasks)
- **Plan 13-03**: SignModal polish — countdown circular UI + color states + spam verification + 2 button semantic verify (2 tasks)
- **Plan 13-04**: Root CA — copy files vào `public/root-ca/` + banner component trong `/ky-so/danh-sach` (2 tasks)
- **Plan 13-05**: E2E + UAT checkpoint (test bell với txn real, test banner trigger, test countdown 3:00) (autonomous: false)

5 plan / 4-5 wave (13-01 có thể chia 2 sub-task nhưng giữ 1 plan).

</specifics>

<deferred>
## Deferred Ideas

### Phase 14 (Deployment)
- MinIO production config (MINIO_PUBLIC_URL, TLS, CORS, bucket policy)
- Audit log download vào MongoDB
- Rate limit endpoint download
- Cron job cleanup notifications > 30 ngày
- HDSD triển khai section "Cấu hình ký số sau deploy" (DEP-03)

### Sau Milestone v2.0
- Generic notification types extend (VB đến mới, HSCV giao, lịch họp, nhắc hẹn deadline)
- Trang chi tiết `/thong-bao` list tất cả notifications với filter + pagination
- Notification setting per user (email/bell/SMS toggle)
- `SigningModal.tsx` legacy cleanup (orphan file từ Phase 6 mock)
- `van-ban-den/[id]` → review path `/ky-so/mock/sign` có nên xóa hoàn toàn (VB đến không ký nghiệp vụ)
- Root CA for non-MySign providers nếu cần sau này

### Nice-to-have không scope
- Push notification browser (Web Push API)
- Dashboard widget "Thông báo gần nhất"
- Mute notification per VB/HSCV

</deferred>

---

*Phase: 13-modal-ky-so-robust-root-ca-ux*
*Context gathered: 2026-04-22 via discuss-phase — 4 gray area locked*
