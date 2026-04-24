---
phase: 13
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - e_office_app_new/database/schema/000_schema_v2.0.sql
  - e_office_app_new/backend/src/repositories/notification.repository.ts
  - e_office_app_new/backend/src/routes/notifications.ts
  - e_office_app_new/backend/src/server.ts
  - e_office_app_new/backend/src/lib/signing/sign-events.ts
  - e_office_app_new/backend/src/workers/signing-poll.worker.ts
autonomous: true
requirements:
  - UX-10
tags: [backend, database, notifications, signing, repository, api]
must_haves:
  truths:
    - "Table public.notifications tồn tại với 10 cột đúng schema D-02"
    - "5 SPs public.fn_notification_* tồn tại trong DB, callable qua psql"
    - "GET /api/notifications + /unread-count + PATCH /:id/read + /read-all trả 200 với JWT hợp lệ"
    - "Worker signing-poll persist notification TRƯỚC khi emit Socket event cho cả sign_completed + sign_failed"
    - "Mỗi notification gắn chính xác staff_id của owner transaction — user A không thấy notification user B"
  artifacts:
    - path: "e_office_app_new/database/schema/000_schema_v2.0.sql"
      provides: "CREATE TABLE public.notifications + 5 SPs append ở cuối file, idempotent"
      contains: "CREATE TABLE IF NOT EXISTS public.notifications"
    - path: "e_office_app_new/backend/src/repositories/notification.repository.ts"
      provides: "notificationRepository với 5 methods: create, list, unreadCount, markRead, markAllRead"
      exports: ["notificationRepository", "NotificationListRow", "NotificationCreateResult"]
    - path: "e_office_app_new/backend/src/routes/notifications.ts"
      provides: "Router với 4 endpoints: GET /, GET /unread-count, PATCH /read-all, PATCH /:id/read"
      exports: ["default"]
    - path: "e_office_app_new/backend/src/server.ts"
      provides: "Mount /api/notifications BEFORE thong-bao generic, authenticate middleware"
      contains: "app.use('/api/notifications', authenticate, notificationsRoutes)"
    - path: "e_office_app_new/backend/src/lib/signing/sign-events.ts"
      provides: "Extension — thêm persistNotificationAndEmit helpers wrap emitSignCompleted/Failed"
      contains: "notificationRepository.create"
    - path: "e_office_app_new/backend/src/workers/signing-poll.worker.ts"
      provides: "handleFailure + success branch gọi notificationRepository.create TRƯỚC emit"
      contains: "notificationRepository.create"
  key_links:
    - from: "workers/signing-poll.worker.ts"
      to: "notificationRepository.create"
      via: "persist trước emitSign*"
      pattern: "notificationRepository\\.create"
    - from: "routes/notifications.ts"
      to: "fn_notification_list"
      via: "callFunction qua repository"
      pattern: "fn_notification_(list|unread_count|mark_read|mark_all_read|create)"
    - from: "server.ts"
      to: "routes/notifications.ts"
      via: "app.use('/api/notifications', ...)"
      pattern: "/api/notifications.*notificationsRoutes"
---

<objective>
Xây dựng hạ tầng backend cho bell notification system — PostgreSQL-backed persistent notifications (D-01 → D-07). Thực hiện:

1. Tạo table `public.notifications` (schema D-02 nguyên văn) trong file master schema `000_schema_v2.0.sql` (NGUYÊN TẮC DB Migration Strategy — KHÔNG tạo file migration 047 rời).
2. Tạo 5 Stored Functions (D-03): `fn_notification_create`, `fn_notification_list`, `fn_notification_unread_count`, `fn_notification_mark_read`, `fn_notification_mark_all_read`.
3. Tạo `notification.repository.ts` theo pattern const object + `callFunction`/`callFunctionOne` (giống `notice.repository.ts` hiện có).
4. Tạo `notifications.ts` route với 4 endpoint REST (D-07): GET list, GET unread-count, PATCH /:id/read, PATCH /read-all. Mount trong `server.ts` TRƯỚC các route `/api/ky-so/*` catch-all (longer-prefix-wins pattern).
5. Extend `signing-poll.worker.ts` + `sign-events.ts`: persist notification row TRƯỚC khi emit Socket event trong CẢ `handleFailure` (failed/expired branches) VÀ success branch — bảo đảm offline user vẫn thấy khi login lại (D-06).

Purpose: UX-10 phần BE — persistent notification để user offline nhận được khi quay lại. Scope Phase 13 CHỈ 2 type: `sign_completed` + `sign_failed` (D-05).

Output: 1 new table, 5 new SPs, 1 new repository, 1 new route file, 2 modified files (worker + sign-events), server.ts mount.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md
@.planning/phases/11-sign-flow-async-worker/11-04-SUMMARY.md
@CLAUDE.md

<interfaces>
<!-- Tham chiếu nhanh để executor không phải grep codebase -->

**Repository pattern hiện tại (từ notice.repository.ts):**
```typescript
import { callFunction, callFunctionOne } from '../lib/db/query.js';

export interface NoticeListRow {
  id: number;
  title: string;
  // ...
}

export const noticeRepository = {
  async getList(unitId: number, staffId: number, isRead: boolean | null, page: number, pageSize: number) {
    return callFunction<NoticeListRow>('edoc.fn_notice_get_list', [unitId, staffId, isRead ?? null, page, pageSize]);
  },
  async create(unitId: number, title: string, content: string, noticeType: string | null, createdBy: number) {
    const row = await callFunctionOne<NoticeCreateResult>('edoc.fn_notice_create', [unitId, title, content, noticeType, createdBy]);
    return row ?? { success: false, message: 'Không thể tạo thông báo', id: 0 };
  },
  // ...
};
```

**Route pattern hiện tại (từ notice.ts):**
```typescript
import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const { page, page_size } = req.query;
    // ... call repo, return { success, data, pagination }
  } catch (error) {
    handleDbError(error, res);
  }
});

// NOTE: /read-all phải mount TRƯỚC /:id/read để tránh route shadowing
router.patch('/read-all', async (req, res) => { ... });
router.patch('/:id/read', async (req, res) => { ... });

export default router;
```

**Server.ts mount pattern hiện tại (longer-prefix-wins):**
```typescript
// Đã có:
app.use('/api/thong-bao', authenticate, noticeRoutes);  // unit-wide edoc notices (legacy)

// THÊM MỚI (Phase 13):
app.use('/api/notifications', authenticate, notificationsRoutes); // personal — Phase 13 bell
```

**Worker helper signature hiện tại (signing-poll.worker.ts):**
```typescript
async function handleFailure(
  txnId: number, staffId: number, providerCode: string,
  attachmentId: number, attachmentType: string,
  status: 'failed' | 'expired', errorMessage: string,
): Promise<void> {
  // 1. updateStatus DB
  // 2. removePlaceholder MinIO
  // 3. emitSignFailed Socket
  // 4. noticeRepository.createForStaff (unit-wide notice — LEGACY, giữ nguyên)
  // Phase 13 INSERT: notificationRepository.create PHẢI đặt TRƯỚC bước 3 emitSignFailed
}
```

**Success branch hiện tại (signing-poll.worker.ts ~ line 350+, sau uploadSignedPdf + complete + finalizeSign):**
```typescript
// ... await attachmentSignRepository.finalizeSign(...)
// THÊM: await notificationRepository.create(...) — TRƯỚC emitSignCompleted
emitSignCompleted(txn.staff_id, { transaction_id, provider_code, ... });
// Giữ noticeRepository.createForStaff legacy (hoặc cân nhắc remove sau khi Phase 13 migrate xong — decision defer)
```

**Current sign-events.ts exports:**
```typescript
export const SIGN_EVENTS = { SIGN_COMPLETED: 'sign_completed', SIGN_FAILED: 'sign_failed' } as const;
export function emitSignCompleted(staffId: number, payload: SignCompletedPayload): void;
export function emitSignFailed(staffId: number, payload: SignFailedPayload): void;
```

**Schema file master location (25343 lines, append ở cuối):**
- Path: `e_office_app_new/database/schema/000_schema_v2.0.sql`
- Append trước bất kỳ final DO block hoặc `-- end` marker nếu có — grep `-- ==.*end|RAISE NOTICE.*applied` để tìm. Hiện tại file kết thúc ở dòng 25343 với `$$;` của `fn_dashboard_doc_by_department` — APPEND DIRECTLY ở cuối.
- DB master schema RULE (CLAUDE.md): DROP SP trước CREATE bằng tên chính xác + args, KHÔNG dùng `LIKE 'fn_notification%'` broad.
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Append table notifications + 5 SPs vào schema master, apply vào dev DB, verify SPs callable</name>
  <files>e_office_app_new/database/schema/000_schema_v2.0.sql</files>
  <read_first>
    - `e_office_app_new/database/schema/000_schema_v2.0.sql` (dòng 1-100 header + cleanup block, dòng 25200-25343 cuối file để biết append vị trí)
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md` section `<decisions>` D-02, D-03 (schema + SP signatures)
    - `CLAUDE.md` section "DB Migration Strategy (v2.0+)" — rule APPEND vào master schema, idempotent, DROP targeted
    - `CLAUDE.md` checklist lỗi mục 4 (reserved words) + mục 5 (cột không tồn tại) + mục 1 (field naming SP ↔ repo)
  </read_first>
  <action>
APPEND vào CUỐI file `e_office_app_new/database/schema/000_schema_v2.0.sql` (sau dòng 25343 `$$;` của `fn_dashboard_doc_by_department`) section mới với comment banner:

```sql
-- ============================================================================
-- SECTION: Phase 13 — Bell Notification Infrastructure (added 2026-04-22)
-- Mục đích: persistent bell notification cho sign_completed + sign_failed events
-- Scope hiện tại: CHỈ 2 type (sign_completed, sign_failed) — D-05 Phase 13
-- ============================================================================

-- --- Table ---
CREATE TABLE IF NOT EXISTS public.notifications (
  id            BIGSERIAL PRIMARY KEY,
  staff_id      INTEGER NOT NULL REFERENCES public.staff(id) ON DELETE CASCADE,
  type          VARCHAR(50) NOT NULL,
  title         VARCHAR(200) NOT NULL,
  message       TEXT,
  link          VARCHAR(500),
  metadata      JSONB,
  is_read       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  read_at       TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_notifications_staff_unread
  ON public.notifications(staff_id, is_read, created_at DESC);

-- --- Targeted DROP (chính xác tên + args, KHÔNG dùng LIKE broad) ---
DROP FUNCTION IF EXISTS public.fn_notification_create(INTEGER, VARCHAR, VARCHAR, TEXT, VARCHAR, JSONB) CASCADE;
DROP FUNCTION IF EXISTS public.fn_notification_list(INTEGER, INTEGER, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.fn_notification_unread_count(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.fn_notification_mark_read(BIGINT, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS public.fn_notification_mark_all_read(INTEGER) CASCADE;

-- --- SP 1: Create notification ---
CREATE OR REPLACE FUNCTION public.fn_notification_create(
  p_staff_id    INTEGER,
  p_type        VARCHAR,
  p_title       VARCHAR,
  p_message     TEXT,
  p_link        VARCHAR,
  p_metadata    JSONB
) RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  IF p_staff_id IS NULL OR NOT EXISTS (SELECT 1 FROM public.staff s WHERE s.id = p_staff_id) THEN
    RETURN QUERY SELECT FALSE, 'Nhân viên không tồn tại'::TEXT, 0::BIGINT;
    RETURN;
  END IF;
  IF p_type IS NULL OR length(trim(p_type)) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Loại thông báo không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;
  IF p_title IS NULL OR length(trim(p_title)) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO public.notifications(staff_id, type, title, message, link, metadata)
  VALUES (p_staff_id, p_type, p_title, p_message, p_link, p_metadata)
  RETURNING public.notifications.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Đã tạo thông báo'::TEXT, v_id;
END;
$$;

-- --- SP 2: List notifications paginated (newest first) ---
-- NOTE: "type" là reserved word trong RETURNS TABLE → phải QUOTE bằng "" (checklist lỗi #4)
CREATE OR REPLACE FUNCTION public.fn_notification_list(
  p_staff_id  INTEGER,
  p_limit     INTEGER,
  p_offset    INTEGER
) RETURNS TABLE (
  id          BIGINT,
  staff_id    INTEGER,
  "type"      VARCHAR,
  title       VARCHAR,
  message     TEXT,
  link        VARCHAR,
  metadata    JSONB,
  is_read     BOOLEAN,
  created_at  TIMESTAMPTZ,
  read_at     TIMESTAMPTZ,
  total_count BIGINT
) LANGUAGE plpgsql AS $$
DECLARE
  v_limit  INTEGER := COALESCE(p_limit, 10);
  v_offset INTEGER := COALESCE(p_offset, 0);
  v_total  BIGINT;
BEGIN
  IF v_limit > 100 THEN v_limit := 100; END IF;
  IF v_limit < 1 THEN v_limit := 10; END IF;
  IF v_offset < 0 THEN v_offset := 0; END IF;

  SELECT COUNT(*) INTO v_total FROM public.notifications n WHERE n.staff_id = p_staff_id;

  RETURN QUERY
  SELECT
    n.id,
    n.staff_id,
    n.type,
    n.title,
    n.message,
    n.link,
    n.metadata,
    n.is_read,
    n.created_at,
    n.read_at,
    v_total AS total_count
  FROM public.notifications n
  WHERE n.staff_id = p_staff_id
  ORDER BY n.created_at DESC, n.id DESC
  LIMIT v_limit OFFSET v_offset;
END;
$$;

-- --- SP 3: Unread count ---
CREATE OR REPLACE FUNCTION public.fn_notification_unread_count(
  p_staff_id INTEGER
) RETURNS TABLE (count BIGINT) LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT COUNT(*)::BIGINT FROM public.notifications n
  WHERE n.staff_id = p_staff_id AND n.is_read = FALSE;
END;
$$;

-- --- SP 4: Mark one read (owner check qua staff_id) ---
CREATE OR REPLACE FUNCTION public.fn_notification_mark_read(
  p_id       BIGINT,
  p_staff_id INTEGER
) RETURNS TABLE (
  success BOOLEAN,
  message TEXT
) LANGUAGE plpgsql AS $$
DECLARE
  v_rows INTEGER;
BEGIN
  UPDATE public.notifications
  SET is_read = TRUE, read_at = NOW()
  WHERE id = p_id AND staff_id = p_staff_id AND is_read = FALSE;
  GET DIAGNOSTICS v_rows = ROW_COUNT;

  IF v_rows = 0 THEN
    -- Có thể record không tồn tại, không thuộc staff, hoặc đã đọc
    IF NOT EXISTS (SELECT 1 FROM public.notifications WHERE id = p_id AND staff_id = p_staff_id) THEN
      RETURN QUERY SELECT FALSE, 'Thông báo không tồn tại hoặc không thuộc về bạn'::TEXT;
      RETURN;
    END IF;
    RETURN QUERY SELECT TRUE, 'Thông báo đã được đánh dấu đã đọc trước đó'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu đã đọc'::TEXT;
END;
$$;

-- --- SP 5: Mark all read ---
CREATE OR REPLACE FUNCTION public.fn_notification_mark_all_read(
  p_staff_id INTEGER
) RETURNS TABLE (
  success       BOOLEAN,
  message       TEXT,
  updated_count INTEGER
) LANGUAGE plpgsql AS $$
DECLARE
  v_rows INTEGER;
BEGIN
  UPDATE public.notifications
  SET is_read = TRUE, read_at = NOW()
  WHERE staff_id = p_staff_id AND is_read = FALSE;
  GET DIAGNOSTICS v_rows = ROW_COUNT;

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu tất cả đã đọc'::TEXT, v_rows;
END;
$$;

-- End of Phase 13 Notification section
```

SAU KHI APPEND, apply vào DB dev (docker) VÀ verify idempotent:

```bash
# Apply lần 1
docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 < e_office_app_new/database/schema/000_schema_v2.0.sql

# Apply lần 2 (PHẢI zero error — idempotent)
docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 < e_office_app_new/database/schema/000_schema_v2.0.sql

# Verify table
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\d public.notifications"

# Verify 5 SPs
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT proname FROM pg_proc WHERE proname LIKE 'fn_notification_%' ORDER BY proname;"

# Test SPs end-to-end: tạo → list → count → mark-read → mark-all-read
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "
SELECT * FROM public.fn_notification_create(1, 'sign_completed', 'Test title', 'Test msg', '/ky-so/danh-sach?tab=completed', '{\"transaction_id\":123}'::jsonb);
SELECT id, \"type\", title, is_read FROM public.fn_notification_list(1, 10, 0);
SELECT * FROM public.fn_notification_unread_count(1);
"
```

Chú ý đặc biệt (checklist CLAUDE.md):
- **#4 Reserved words:** `"type"` trong RETURNS TABLE PHẢI quote. Column `staff_id` (không phải `staffId`), `is_read` (không phải `isRead`).
- **#5 Cột tồn tại:** `public.staff(id)` tồn tại (đã verify qua schema, line 14911). `public.staff.is_deleted` có thể không có — KHÔNG reference trong FK cascade.
- **#8 Data type:** `staff_id INTEGER` khớp với `staff.id` (integer PK per schema). `id BIGSERIAL`. Reply TABLE.`id` là `BIGINT`.
- **Idempotent:** DROP target chính xác + `CREATE OR REPLACE` cho SPs, `CREATE TABLE IF NOT EXISTS` cho table, `CREATE INDEX IF NOT EXISTS` cho index.
- **KHÔNG tạo file migration 047 rời** (CLAUDE.md rule DB Migration Strategy).
  </action>
  <verify>
<automated>
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -tAc "SELECT count(*) FROM information_schema.columns WHERE table_schema='public' AND table_name='notifications' AND column_name IN ('id','staff_id','type','title','message','link','metadata','is_read','created_at','read_at');" | grep -q "^10$" && \
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -tAc "SELECT count(*) FROM pg_proc WHERE proname IN ('fn_notification_create','fn_notification_list','fn_notification_unread_count','fn_notification_mark_read','fn_notification_mark_all_read');" | grep -q "^5$" && \
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 -c "SELECT (public.fn_notification_create(1, 'sign_completed', 'T', NULL, NULL, NULL::jsonb)).success" | grep -q "t" && \
echo "Task 1 OK"
</automated>
  </verify>
  <done>
    - Table `public.notifications` có đủ 10 cột đúng schema D-02
    - 5 SPs `public.fn_notification_*` tồn tại, callable
    - Apply schema master lần 2 không lỗi (idempotent)
    - `fn_notification_create` test run trả `success=TRUE`
    - Không có SP overload (cùng tên, 2 signature)
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Tạo notification.repository.ts + routes/notifications.ts + mount server.ts</name>
  <files>
    e_office_app_new/backend/src/repositories/notification.repository.ts,
    e_office_app_new/backend/src/routes/notifications.ts,
    e_office_app_new/backend/src/server.ts
  </files>
  <read_first>
    - `e_office_app_new/backend/src/repositories/notice.repository.ts` (pattern const object + callFunction — copy style)
    - `e_office_app_new/backend/src/routes/notice.ts` (route pattern + mark-all-read TRƯỚC /:id/read tránh route shadow)
    - `e_office_app_new/backend/src/lib/db/query.ts` (hoặc check import path của callFunction/callFunctionOne từ notice.repository.ts)
    - `e_office_app_new/backend/src/middleware/auth.ts` (AuthRequest interface, staffId từ JWT)
    - `e_office_app_new/backend/src/server.ts` (hiện tại line 107 mount `/api/ky-so` catch-all — phải mount `/api/notifications` TRƯỚC hoặc không conflict vì prefix khác)
    - `e_office_app_new/backend/src/lib/error-handler.ts` (handleDbError pattern)
  </read_first>
  <action>
**Bước 1: Tạo `e_office_app_new/backend/src/repositories/notification.repository.ts` (file mới):**

```typescript
import { callFunction, callFunctionOne } from '../lib/db/query.js';

// =============================================================================
// Row types — snake_case khớp SP output (CLAUDE.md checklist #1)
// =============================================================================

export interface NotificationListRow {
  id: number;
  staff_id: number;
  type: string;
  title: string;
  message: string | null;
  link: string | null;
  metadata: Record<string, unknown> | null;
  is_read: boolean;
  created_at: string;   // ISO string — pg driver trả string (CLAUDE.md checklist #8)
  read_at: string | null;
  total_count: number;
}

export interface NotificationCreateResult {
  success: boolean;
  message: string;
  id: number;
}

export interface NotificationActionResult {
  success: boolean;
  message: string;
}

export interface MarkAllReadResult {
  success: boolean;
  message: string;
  updated_count: number;
}

// =============================================================================
// Repository (const object — pattern thống nhất dự án)
// =============================================================================

export const notificationRepository = {
  /**
   * Tạo notification mới.
   * Gọi từ worker (signing-poll.worker.ts) + route handlers nếu cần.
   */
  async create(
    staffId: number,
    type: string,
    title: string,
    message: string | null,
    link: string | null,
    metadata: Record<string, unknown> | null,
  ): Promise<NotificationCreateResult> {
    const row = await callFunctionOne<NotificationCreateResult>(
      'public.fn_notification_create',
      [staffId, type, title, message, link, metadata],
    );
    return row ?? { success: false, message: 'Không tạo được thông báo', id: 0 };
  },

  /**
   * List notifications của staff, paginated (newest first).
   * Backend convert page → offset trước khi gọi SP (SP chỉ nhận limit/offset).
   */
  async list(
    staffId: number,
    page: number,
    pageSize: number,
  ): Promise<NotificationListRow[]> {
    const offset = Math.max(0, (page - 1) * pageSize);
    return callFunction<NotificationListRow>('public.fn_notification_list', [
      staffId,
      pageSize,
      offset,
    ]);
  },

  /**
   * Unread count (dùng cho badge).
   */
  async unreadCount(staffId: number): Promise<number> {
    const row = await callFunctionOne<{ count: string | number }>(
      'public.fn_notification_unread_count',
      [staffId],
    );
    return Number(row?.count ?? 0);
  },

  /**
   * Mark 1 notification đã đọc. Owner check qua staff_id (IDOR mitigation).
   */
  async markRead(id: number, staffId: number): Promise<NotificationActionResult> {
    const row = await callFunctionOne<NotificationActionResult>(
      'public.fn_notification_mark_read',
      [id, staffId],
    );
    return row ?? { success: false, message: 'Không tìm thấy thông báo' };
  },

  /**
   * Mark tất cả notification của staff đã đọc.
   */
  async markAllRead(staffId: number): Promise<MarkAllReadResult> {
    const row = await callFunctionOne<MarkAllReadResult>(
      'public.fn_notification_mark_all_read',
      [staffId],
    );
    return row ?? { success: true, message: 'Đã đánh dấu tất cả đã đọc', updated_count: 0 };
  },
};
```

**Bước 2: Tạo `e_office_app_new/backend/src/routes/notifications.ts` (file mới):**

```typescript
import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { notificationRepository } from '../repositories/notification.repository.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// =============================================================================
// GET / — List paginated notifications (newest first)
// Query: page, page_size (snake_case khớp convention dự án)
// =============================================================================
router.get('/', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const rawPage = Number(req.query.page ?? 1);
    const rawPageSize = Number(req.query.page_size ?? 10);

    // Guard URL tampering (T-13-01)
    const page = Number.isFinite(rawPage) && rawPage >= 1 ? Math.floor(rawPage) : 1;
    const pageSize = Number.isFinite(rawPageSize) && rawPageSize >= 1
      ? Math.min(Math.floor(rawPageSize), 100)
      : 10;

    const rows = await notificationRepository.list(staffId, page, pageSize);
    const total = rows.length > 0 ? Number(rows[0].total_count) : 0;

    res.json({
      success: true,
      data: rows.map((r) => ({
        id: r.id,
        type: r.type,
        title: r.title,
        message: r.message,
        link: r.link,
        metadata: r.metadata,
        is_read: r.is_read,
        created_at: r.created_at,
        read_at: r.read_at,
      })),
      pagination: { total, page, pageSize },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// =============================================================================
// GET /unread-count — Badge count
// =============================================================================
router.get('/unread-count', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const count = await notificationRepository.unreadCount(staffId);
    res.json({ success: true, data: { count } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// =============================================================================
// PATCH /read-all — Mark all read
// NOTE: PHẢI đặt TRƯỚC /:id/read để tránh route shadowing (pattern notice.ts)
// =============================================================================
router.patch('/read-all', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const result = await notificationRepository.markAllRead(staffId);
    res.json({ success: true, data: { updated_count: result.updated_count, message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

// =============================================================================
// PATCH /:id/read — Mark one read (owner-only check trong SP via staff_id)
// =============================================================================
router.patch('/:id/read', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    if (!Number.isFinite(id) || id < 1) {
      res.status(400).json({ success: false, message: 'ID không hợp lệ' });
      return;
    }

    const result = await notificationRepository.markRead(id, staffId);
    if (!result.success) {
      // Owner-check failure (IDOR) hoặc not-found — cùng trả 404 để không leak existence
      res.status(404).json({ success: false, message: result.message });
      return;
    }
    res.json({ success: true, data: { id, is_read: true, message: result.message } });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
```

**Bước 3: Modify `e_office_app_new/backend/src/server.ts`:**

- Thêm import ở block imports (sau dòng `import notificationRoutes from './routes/notification.js';` hiện có):
  ```typescript
  import notificationsRoutes from './routes/notifications.js';  // Phase 13 — personal bell
  ```
  CHÚ Ý TÊN: `notificationsRoutes` (plural s) để phân biệt với `notificationRoutes` đã tồn tại (kênh thông báo admin route khác hoàn toàn).

- Thêm mount SAU dòng `app.use('/api/thong-bao', authenticate, noticeRoutes);` (hiện tại line 81). Thứ tự:
  ```typescript
  app.use('/api/thong-bao', authenticate, noticeRoutes);  // unit-wide (legacy)
  app.use('/api/notifications', authenticate, notificationsRoutes);  // Phase 13 — personal bell
  ```
  Prefix `/api/notifications` KHÔNG xung đột với `/api/ky-so/*` hoặc `/api/thong-bao-kenh/*` (đã check: không có route nào mount `/api/notifications` hiện tại).

Sau khi lưu 3 file, restart backend dev server (nếu đang chạy) và test 4 endpoint bằng curl:

```bash
# Lấy JWT từ login (thay email/password thực tế)
TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/login \
  -H 'Content-Type: application/json' \
  -d '{"email":"admin@qlvb.vn","password":"Admin@123"}' | jq -r '.data.accessToken')

# GET /unread-count
curl -s http://localhost:4000/api/notifications/unread-count -H "Authorization: Bearer $TOKEN"
# Expected: {"success":true,"data":{"count":<N>}}

# GET / list
curl -s 'http://localhost:4000/api/notifications?page=1&page_size=10' -H "Authorization: Bearer $TOKEN"
# Expected: {"success":true,"data":[...],"pagination":{...}}

# PATCH /read-all
curl -s -X PATCH http://localhost:4000/api/notifications/read-all -H "Authorization: Bearer $TOKEN"
# Expected: {"success":true,"data":{"updated_count":<N>}}
```

Chú ý checklist lỗi CLAUDE.md:
- **#1 Field naming:** Row interface dùng đúng tên SP trả về (`staff_id`, `is_read`, `created_at`, `type`, `total_count`) — KHÔNG rename.
- **#3 Query param:** backend đọc `page_size` (snake_case) — frontend phải gửi đúng tên này.
- **#8 Data type:** `id: number` (BIGINT → number OK cho ID thông thường), `metadata: Record<string, unknown> | null`, `created_at: string` (KHÔNG Date).
- **Route order:** `/read-all` TRƯỚC `/:id/read` — nếu đảo ngược sẽ bị catch bởi `:id`.
  </action>
  <verify>
<automated>
# Verify 3 files tồn tại + TypeScript compile OK
test -f e_office_app_new/backend/src/repositories/notification.repository.ts && \
test -f e_office_app_new/backend/src/routes/notifications.ts && \
grep -q "notificationsRoutes" e_office_app_new/backend/src/server.ts && \
grep -q "app.use('/api/notifications'" e_office_app_new/backend/src/server.ts && \
grep -q "export const notificationRepository" e_office_app_new/backend/src/repositories/notification.repository.ts && \
grep -q "fn_notification_create" e_office_app_new/backend/src/repositories/notification.repository.ts && \
grep -q "fn_notification_list" e_office_app_new/backend/src/repositories/notification.repository.ts && \
grep -q "fn_notification_unread_count" e_office_app_new/backend/src/repositories/notification.repository.ts && \
grep -q "fn_notification_mark_read" e_office_app_new/backend/src/repositories/notification.repository.ts && \
grep -q "fn_notification_mark_all_read" e_office_app_new/backend/src/repositories/notification.repository.ts && \
cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | grep -E "notification\.repository\.ts|routes/notifications\.ts" | (! grep -q "error TS") && \
echo "Task 2 OK"
</automated>
  </verify>
  <done>
    - 3 files tồn tại với đúng nội dung
    - TypeScript compile 0 new errors trong 3 file này
    - 4 endpoint (GET list, GET unread-count, PATCH read-all, PATCH /:id/read) mounted và trả 200 khi có JWT, 401 khi thiếu
    - Owner-check: `markRead` của user B cho notification của user A trả `success=FALSE` (từ SP)
    - Route `/read-all` mount TRƯỚC `/:id/read` — grep order verify
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Extend signing-poll.worker.ts — persist notification TRƯỚC emit Socket cho completed + failed branches</name>
  <files>
    e_office_app_new/backend/src/workers/signing-poll.worker.ts,
    e_office_app_new/backend/src/lib/signing/sign-events.ts
  </files>
  <read_first>
    - `e_office_app_new/backend/src/workers/signing-poll.worker.ts` (full file, đặc biệt `handleFailure` line 103-150 + success branch sau line 350 nơi gọi `emitSignCompleted`)
    - `e_office_app_new/backend/src/lib/signing/sign-events.ts` (full file — chỉ 70 dòng, giữ nguyên exports hiện có)
    - `e_office_app_new/backend/src/repositories/notification.repository.ts` (file vừa tạo ở Task 2)
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md` D-05 D-06 (scope 2 type + persist TRƯỚC emit)
    - `.planning/phases/11-sign-flow-async-worker/11-04-SUMMARY.md` section "Worker State Machine" + "Socket.IO Event Contract"
  </read_first>
  <action>
**Chiến lược:** KHÔNG sửa `sign-events.ts` signatures (giữ API hiện tại để không break Phase 11 callers). Thay vào đó:
- Import `notificationRepository` vào `signing-poll.worker.ts`.
- Gọi `notificationRepository.create(...)` TRƯỚC `emitSignCompleted(...)` / `emitSignFailed(...)` trong cả 2 paths.
- Wrap try/catch (best-effort pattern giống `noticeRepository.createForStaff` hiện tại — notification fail không được throw lên BullMQ).
- Giữ `noticeRepository.createForStaff` legacy (unit-wide notice) — coexist 2 kênh, Phase 13 BE chỉ THÊM kênh personal.

**Step 1: Modify `signing-poll.worker.ts`:**

Thêm import (gần dòng `import { noticeRepository } from '../repositories/notice.repository.js';`):
```typescript
import { notificationRepository } from '../repositories/notification.repository.js';
```

Sửa `handleFailure` — thêm bước 3.5 persist notification TRƯỚC bước 3 emit Socket:

Tìm block trong handleFailure:
```typescript
  // 3. Socket emit
  emitSignFailed(staffId, {
    transaction_id: txnId,
    provider_code: providerCode,
    attachment_id: attachmentId,
    attachment_type: attachmentType,
    error_message: errMsg,
    status,
  });

  // 4. Bell notification (persistent)
  try {
    await noticeRepository.createForStaff(...)
  }
```

Thay bằng:
```typescript
  // 3. Bell notification PERSONAL (Phase 13) — PERSIST TRƯỚC emit Socket
  //    để offline user thấy được khi login lại. Best-effort — DB source of truth.
  try {
    await notificationRepository.create(
      staffId,
      'sign_failed',
      status === 'expired' ? 'Ký số hết hạn' : 'Ký số thất bại',
      status === 'expired'
        ? `Giao dịch ký số #${txnId} đã hết hạn sau 3 phút không xác nhận: ${errMsg}`
        : `Giao dịch ký số #${txnId} thất bại: ${errMsg}`,
      `/ky-so/danh-sach?tab=failed`,
      {
        transaction_id: txnId,
        provider_code: providerCode,
        attachment_id: attachmentId,
        attachment_type: attachmentType,
        error_message: errMsg,
        status,
      },
    );
  } catch (err) {
    logger.warn({ err, txnId }, 'Failed to create personal notification (sign_failed) — best-effort');
  }

  // 4. Socket emit (best-effort, user online nhận ngay)
  emitSignFailed(staffId, {
    transaction_id: txnId,
    provider_code: providerCode,
    attachment_id: attachmentId,
    attachment_type: attachmentType,
    error_message: errMsg,
    status,
  });

  // 5. Bell notification UNIT-WIDE legacy (Phase 11) — giữ nguyên, coexist
  try {
    await noticeRepository.createForStaff(
      staffId,
      status === 'expired' ? 'Ký số hết hạn' : 'Ký số thất bại',
      status === 'expired'
        ? `Giao dịch ký số #${txnId} đã hết hạn sau 3 phút không xác nhận: ${errMsg}`
        : `Giao dịch ký số #${txnId} thất bại: ${errMsg}`,
      'SIGN_RESULT',
    );
  } catch (err) {
    logger.warn({ err, txnId }, 'Failed to create failure notification (legacy)');
  }
```

Tương tự cho success branch. Trong `processJob`, tìm block sau `await attachmentSignRepository.finalizeSign(...)` nơi gọi `emitSignCompleted(...)`. Thêm persist PERSONAL notification TRƯỚC `emitSignCompleted`:

```typescript
  // Phase 13: Persist personal notification TRƯỚC emit Socket
  //   File name có trong txn? Nếu không, dùng fallback. buildSignedObjectKey ra dạng
  //   'signed/txn-{txnId}-signed.pdf' — filename phần cuối dùng cho title.
  try {
    const fileNameHint = `đính kèm #${txn.attachment_id}`;
    await notificationRepository.create(
      txn.staff_id,
      'sign_completed',
      `Ký số thành công: ${fileNameHint}`,
      `Giao dịch ký số #${txn.id} đã hoàn tất. Nhấn để xem file đã ký.`,
      `/ky-so/danh-sach?tab=completed`,
      {
        transaction_id: txn.id,
        provider_code: txn.provider_code,
        attachment_id: txn.attachment_id,
        attachment_type: txn.attachment_type,
        signed_file_path: signedKey,
        completed_at: new Date().toISOString(),
      },
    );
  } catch (err) {
    logger.warn({ err, txnId: txn.id }, 'Failed to create personal notification (sign_completed) — best-effort');
  }

  // Socket emit (Phase 11)
  emitSignCompleted(txn.staff_id, { ... existing payload ... });
```

CHÚ Ý: 
- Giữ nguyên call `noticeRepository.createForStaff` legacy (unit-wide notice) — 2 kênh coexist, FE Plan 13-02 consume `/api/notifications` cho bell mới.
- `link` dùng query string `?tab=completed` / `?tab=failed` để frontend click navigate đúng tab.
- `metadata` chứa đủ info cho FE toast decision (provider_code cho Root CA banner trigger, transaction_id cho filter).
- Wrap try/catch — nếu SP fail (rare), worker KHÔNG throw lên BullMQ → job vẫn thành công.

**Step 2: sign-events.ts KHÔNG cần sửa** (giữ nguyên API Phase 11, chỉ worker extend). Xác nhận bằng diff = empty cho `sign-events.ts`.

Compile + restart worker:
```bash
cd e_office_app_new/backend
npx tsc --noEmit 2>&1 | grep -E "workers/signing-poll|lib/signing/sign-events" | (! grep -q "error TS")

# Restart dev server (nếu đang chạy) để worker pickup code mới
```

Smoke test manual qua DB + fake job (optional, Plan 13-05 E2E sẽ verify end-to-end):
```bash
# Tạo 1 notification giả lập qua SP (đảm bảo FE Plan 13-02 có data test)
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "
SELECT * FROM public.fn_notification_create(
  1, 'sign_completed', 'Smoke test',
  'Giao dịch ký số #999 đã hoàn tất',
  '/ky-so/danh-sach?tab=completed',
  '{\"transaction_id\":999,\"provider_code\":\"MYSIGN_VIETTEL\"}'::jsonb
);"
```
  </action>
  <verify>
<automated>
# Verify worker imports + gọi notificationRepository.create ở 2 branches
grep -q "import { notificationRepository }" e_office_app_new/backend/src/workers/signing-poll.worker.ts && \
grep -cE "notificationRepository\.create\(" e_office_app_new/backend/src/workers/signing-poll.worker.ts | (read n && [ "$n" -ge 2 ]) && \
# Verify persist TRƯỚC emit (kiểm tra dòng notificationRepository.create xuất hiện TRƯỚC dòng emitSignFailed trong handleFailure function)
awk '/^async function handleFailure/,/^}/' e_office_app_new/backend/src/workers/signing-poll.worker.ts | awk '/notificationRepository\.create/{n=NR} /emitSignFailed/{e=NR} END{exit !(n && e && n<e)}' && \
# Verify sign-events.ts KHÔNG đổi signature (giữ emitSignCompleted/emitSignFailed)
grep -q "export function emitSignCompleted" e_office_app_new/backend/src/lib/signing/sign-events.ts && \
grep -q "export function emitSignFailed" e_office_app_new/backend/src/lib/signing/sign-events.ts && \
# TypeScript compile clean
cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | grep -E "workers/signing-poll\.worker\.ts|lib/signing/sign-events\.ts" | (! grep -q "error TS") && \
echo "Task 3 OK"
</automated>
  </verify>
  <done>
    - `signing-poll.worker.ts` import `notificationRepository` + gọi `create()` ở cả handleFailure + success branches
    - Trong handleFailure, `notificationRepository.create` xuất hiện TRƯỚC `emitSignFailed` (order verified qua awk)
    - Trong success branch, `notificationRepository.create` xuất hiện TRƯỚC `emitSignCompleted`
    - Try/catch wrap quanh cả 2 persist calls (best-effort pattern)
    - `noticeRepository.createForStaff` legacy giữ nguyên (coexist 2 kênh)
    - TypeScript compile 0 new errors
    - Smoke test: 1 notification test tồn tại trong DB cho staff_id=1 (optional, FE Plan 13-02 dùng)
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| client → API `/api/notifications/*` | Untrusted HTTP requests cross này; JWT từ `Authorization: Bearer` header decode bởi `authenticate` middleware |
| Redis job payload → Worker | BullMQ trust zone; attacker có thể inject job giả (T-11-13 Phase 11) — đã mitigate bằng DB re-read |
| Worker → Notification SP | Worker code chạy trusted; staffId từ DB txn record (`txn.staff_id`), không từ job payload |
| DB SP → Table | PL/pgSQL SECURITY DEFINER (hoặc default INVOKER) — owner check staff_id tại SP boundary |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-13-01 | T (Tampering) — URL `?page=-1&pageSize=9999` | GET /api/notifications | mitigate | Parse với `Number.isFinite + floor + clamp min 1` + cap pageSize 100 — defense-in-depth với SP cũng cap (line 68 trong fn_notification_list) |
| T-13-02 | I (Info Disclosure) — IDOR xem notification user khác | GET /api/notifications, PATCH /:id/read | mitigate | `staffId` LẤY TỪ JWT (`(req as AuthRequest).user.staffId`), KHÔNG từ query/body. SP `fn_notification_list` filter `WHERE staff_id = p_staff_id`; SP `fn_notification_mark_read` check `WHERE id = p_id AND staff_id = p_staff_id` |
| T-13-03 | E (Elevation) — Mark read notification user khác qua param `:id` mà không cần biết staff_id owner | PATCH /:id/read | mitigate | SP `fn_notification_mark_read(p_id, p_staff_id)` yêu cầu `staff_id` match; nếu không match trả `success=FALSE` + message; route trả 404 không leak existence |
| T-13-04 | I (Info Disclosure) — Metadata JSONB leak thông tin nhạy cảm | fn_notification_create call từ worker | mitigate | Worker build metadata từ DB-authoritative fields (txn.id, txn.attachment_id, txn.provider_code, signed_file_path) — không đưa error stack trace / raw provider response / user input |
| T-13-05 | D (DoS) — Spam notification flood | Worker extend | accept | Worker chỉ tạo notification tại terminal states (completed / failed / expired / cancelled) — upper bound = number of sign transactions = rate-limited bởi provider API + BullMQ concurrency=1. Volume thực tế vài chục notifications/user/day max |
| T-13-06 | R (Repudiation) — User claim không nhận notification | Whole flow | accept | DB `public.notifications` persistent với `created_at` timestamp — audit trail đầy đủ. Retention 30 ngày (D-04) defer cleanup Phase 14 |
| T-13-07 | T (Tampering) — Worker inject notification cho staff_id khác owner của transaction | signing-poll.worker.ts | mitigate | Worker dùng `txn.staff_id` đọc từ DB (fn_sign_transaction_get_by_id) — không từ job payload. Attacker cần compromise DB để inject staff_id sai, lúc đó đã có exposure lớn hơn |
</threat_model>

<verification>
## Backend Integration Tests

1. **Schema migration idempotent:** `schema/000_schema_v2.0.sql` apply 2 lần liên tiếp — 0 error. Count SPs total ≥ 391 (baseline 386 + 5 mới).

2. **5 SPs callable qua psql:**
   ```bash
   docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "
   SELECT (public.fn_notification_create(1, 'sign_completed', 'T', 'M', '/l', NULL::jsonb)).*;
   SELECT id, \"type\", title FROM public.fn_notification_list(1, 10, 0) LIMIT 1;
   SELECT * FROM public.fn_notification_unread_count(1);
   SELECT * FROM public.fn_notification_mark_all_read(1);
   "
   ```
   Mọi câu trả `success=t` hoặc row khớp.

3. **4 REST endpoints:** với JWT user A, test:
   - `GET /api/notifications?page=1&page_size=10` → 200 + `data: [...]` + `pagination`
   - `GET /api/notifications/unread-count` → 200 + `data: { count }`
   - `PATCH /api/notifications/<id>/read` (id thuộc user A) → 200 + `success`
   - `PATCH /api/notifications/<id>/read` (id thuộc user B) → 404 (owner check)
   - `PATCH /api/notifications/read-all` → 200 + `updated_count`

4. **Worker persist order:** manual test bằng cách trigger handleFailure qua job mock hoặc:
   - Tạo sign_transaction giả lập → cancel → worker log + DB `public.notifications` có row mới type=`sign_failed` + metadata khớp

5. **TypeScript clean:** `npx tsc --noEmit` zero new errors trong 4 file đã touch (repo + route + worker + server.ts).
</verification>

<success_criteria>
Plan 13-01 hoàn tất khi:
- [ ] `public.notifications` table exists với 10 cột khớp D-02 nguyên văn
- [ ] 5 SPs `public.fn_notification_*` callable, test insert/list/count/mark thành công
- [ ] `notification.repository.ts` exports `notificationRepository` const object với 5 methods khớp SP signatures
- [ ] `routes/notifications.ts` exports Router với 4 endpoints (GET /, GET /unread-count, PATCH /read-all, PATCH /:id/read)
- [ ] `server.ts` mount `/api/notifications` với `authenticate` middleware
- [ ] `workers/signing-poll.worker.ts` gọi `notificationRepository.create(...)` TRƯỚC `emitSignCompleted/Failed` trong cả 2 paths (success + handleFailure)
- [ ] Try/catch wrap quanh persist — best-effort không throw lên BullMQ
- [ ] Schema master idempotent (apply lần 2 không lỗi)
- [ ] TypeScript compile 0 new errors
- [ ] Checklist lỗi #1 (SP ↔ repo field name), #3 (page_size snake_case), #4 (reserved word `"type"`), #8 (data type) đều passed
</success_criteria>

<output>
Tạo `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-01-SUMMARY.md` theo template sau khi hoàn tất.
</output>
