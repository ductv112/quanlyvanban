---
phase: 260424-wve-permission-v2-vb-den-vb-di-apply-pattern
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - e_office_app_new/backend/src/lib/permissions/_shared.ts
  - e_office_app_new/backend/src/lib/permissions/drafting-doc.ts
  - e_office_app_new/backend/src/lib/permissions/incoming-doc.ts
  - e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts
  - e_office_app_new/backend/src/routes/incoming-doc.ts
  - e_office_app_new/backend/src/routes/outgoing-doc.ts
  - e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx
  - e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx
  - e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx
  - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
autonomous: true
requirements:
  - QUICK-260424-wve
user_setup: []

must_haves:
  truths:
    - "Permission v2 capability-based apply tới VB đến + VB đi (khớp pattern đã settle ở VB dự thảo 260424-w4u)"
    - "Admin có full 5 quyền (canEdit/canApprove/canRelease/canSend/canRetract) ở cả VB đến + VB đi"
    - "User cùng unit với doc nhưng không phải leader/handler → KHÔNG thao tác mutation được (403 hoặc nút ẩn)"
    - "User khác unit (không phải admin, không phải owner) → KHÔNG thao tác mutation được (403)"
    - "User là owner (created_by hoặc drafting_user_id) → canEdit/canSend true bất kể position flag"
    - "Frontend list dropdown + detail buttons gate theo record.permissions kết hợp status flag (approved/is_released/rejected_by)"
    - "Rules không hard-code role name — chỉ dùng is_admin + is_leader + is_handle_document + ownership + sameUnit"
    - "TypeScript compile (backend + frontend) 0 new errors sau task"
  artifacts:
    - path: "e_office_app_new/backend/src/lib/permissions/_shared.ts"
      provides: "Shared types (DocPermissions, UserPermissionContext) + getUserPermissionContext + computePermsFromContext(ctx, doc, isOwner)"
      exports: ["DocPermissions", "DocPermissionContext", "UserPermissionContext", "DocOwnershipInfo", "getUserPermissionContext", "computePermsFromContext"]
    - path: "e_office_app_new/backend/src/lib/permissions/drafting-doc.ts"
      provides: "Wrapper truyền isOwner = staffId === drafting_user_id, re-export types để không phải sửa import ở route drafting"
      exports: ["DraftingPermissions", "DocPermissionContext", "DocInfo", "getUserPermissionContext", "computePermsWithContext", "computeDraftingPermissions"]
    - path: "e_office_app_new/backend/src/lib/permissions/incoming-doc.ts"
      provides: "computeIncomingPermissions(user, doc) + computeIncomingPermsWithContext(ctx, doc) — isOwner = staffId === created_by"
      exports: ["IncomingDocInfo", "computeIncomingPermissions", "computeIncomingPermsWithContext"]
    - path: "e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts"
      provides: "computeOutgoingPermissions(user, doc) + computeOutgoingPermsWithContext(ctx, doc) — isOwner = staffId === drafting_user_id OR staffId === created_by"
      exports: ["OutgoingDocInfo", "computeOutgoingPermissions", "computeOutgoingPermsWithContext"]
    - path: "e_office_app_new/backend/src/routes/incoming-doc.ts"
      provides: "Guard canEdit trên PUT /:id + DELETE /:id. Guard canApprove trên PATCH /:id/duyet + PATCH /:id/huy-duyet + PATCH /:id/nhan-ban-giay + POST /:id/giao-viec + POST /:id/gui-lien-thong + POST /:id/them-vao-hscv. Guard canSend trên POST /:id/gui. Guard canRetract trên POST /:id/thu-hoi + POST /:id/chuyen-lai. Enrich permissions ở GET / (batch) + GET /:id."
      contains: "loadDocAndPerms"
    - path: "e_office_app_new/backend/src/routes/outgoing-doc.ts"
      provides: "Guard canEdit trên PUT /:id + DELETE /:id. Guard canApprove trên PATCH /:id/duyet + PATCH /:id/huy-duyet + PATCH /:id/tu-choi + POST /:id/giao-viec + POST /:id/them-vao-hscv. Guard canRelease trên PATCH /:id/ban-hanh + POST /:id/noi-nhan. Guard canSend trên POST /:id/gui + POST /:id/gui-noi-bo + POST /:id/gui-lien-thong + POST /:id/gui-truc-cp. Guard canRetract trên POST /:id/thu-hoi. Enrich permissions ở GET / (batch) + GET /:id."
      contains: "loadDocAndPerms"
    - path: "e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx"
      provides: "IncomingDoc interface thêm `permissions?: DocPermissions`; dropdown items trong actions column gate theo perms kết hợp status"
    - path: "e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx"
      provides: "DocDetail interface thêm `permissions?`; detail action buttons + dropdown menu gate theo doc.permissions kết hợp status"
    - path: "e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx"
      provides: "OutgoingDoc interface thêm `permissions?`; dropdown gate theo perms kết hợp approved/is_released/rejected_by"
    - path: "e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx"
      provides: "DocDetail interface thêm `permissions?`; action buttons gate (Ban hành, Ban hành & Gửi, Gửi, Duyệt, Từ chối, Hủy duyệt, Thu hồi) theo perms kết hợp status"
  key_links:
    - from: "e_office_app_new/backend/src/lib/permissions/drafting-doc.ts"
      to: "e_office_app_new/backend/src/lib/permissions/_shared.ts"
      via: "import + wrap"
      pattern: "from '\\./_shared\\.js'"
    - from: "e_office_app_new/backend/src/lib/permissions/incoming-doc.ts"
      to: "e_office_app_new/backend/src/lib/permissions/_shared.ts"
      via: "import + wrap"
      pattern: "from '\\./_shared\\.js'"
    - from: "e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts"
      to: "e_office_app_new/backend/src/lib/permissions/_shared.ts"
      via: "import + wrap"
      pattern: "from '\\./_shared\\.js'"
    - from: "e_office_app_new/backend/src/routes/incoming-doc.ts"
      to: "e_office_app_new/backend/src/lib/permissions/incoming-doc.ts"
      via: "import computeIncomingPermissions + loadDocAndPerms helper"
      pattern: "from '\\.\\./lib/permissions/incoming-doc\\.js'"
    - from: "e_office_app_new/backend/src/routes/outgoing-doc.ts"
      to: "e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts"
      via: "import computeOutgoingPermissions + loadDocAndPerms helper"
      pattern: "from '\\.\\./lib/permissions/outgoing-doc\\.js'"
    - from: "e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx"
      to: "record.permissions"
      via: "gate dropdown items"
      pattern: "record\\.permissions"
    - from: "e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx"
      to: "record.permissions"
      via: "gate dropdown items"
      pattern: "record\\.permissions"
---

<objective>
Mở rộng permission v2 capability-based (đã settle ở VB dự thảo 260424-w4u) cho VB đến + VB đi:

1. Refactor shared permission logic ra `_shared.ts` để drafting/incoming/outgoing cùng import (tránh drafting thành "parent")
2. Tạo helper riêng cho incoming-doc + outgoing-doc wrap shared
3. Guard mutation endpoints ở 2 routes với 403 khi thiếu perm
4. Enrich `permissions: DocPermissions` ở GET / (batch) + GET /:id (2 modules)
5. Frontend: gate dropdown list + detail action buttons theo `record.permissions`/`doc.permissions` kết hợp status flag

Purpose: Người nhận khác unit không thao tác được VB đến/đi; leader cùng unit duyệt/phát hành/thu hồi; owner tự sửa/gửi được; admin full quyền. Không hard-code role name — chỉ flag + ownership + admin.

Output: 1 file shared mới + 2 helper mới + drafting helper refactor + 2 routes có guards + 4 frontend pages gate UI.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@./CLAUDE.md
@.planning/STATE.md

# Pattern reference (ĐỌC TRƯỚC KHI CODE)
@e_office_app_new/backend/src/lib/permissions/drafting-doc.ts
@e_office_app_new/backend/src/routes/drafting-doc.ts
@e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/page.tsx
@e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx

# Target files (sẽ sửa)
@e_office_app_new/backend/src/routes/incoming-doc.ts
@e_office_app_new/backend/src/routes/outgoing-doc.ts
@e_office_app_new/backend/src/repositories/incoming-doc.repository.ts
@e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts
@e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx
@e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx
@e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx
@e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx

<interfaces>
<!-- Key contracts (đã grep từ codebase). Executor KHÔNG phải explore — dùng trực tiếp. -->

From backend/src/lib/permissions/drafting-doc.ts (pattern hiện tại — sẽ refactor):
```typescript
export interface DocPermissionContext {
  staffId: number;
  departmentId: number;
  isAdmin: boolean;
}
export interface DocInfo {
  id: number;
  drafting_user_id: number | null;
  unit_id: number;
}
export interface DraftingPermissions {
  canEdit: boolean;
  canApprove: boolean;
  canRelease: boolean;
  canSend: boolean;
  canRetract: boolean;
}
export interface UserPermissionContext {
  staffId: number;
  userUnitId: number | null;
  isAdmin: boolean;
  is_leader: boolean;
  is_handle_document: boolean;
}
export async function getUserPermissionContext(user: DocPermissionContext): Promise<UserPermissionContext>;
export function computePermsWithContext(ctx: UserPermissionContext, doc: DocInfo): DraftingPermissions;
export async function computeDraftingPermissions(user: DocPermissionContext, doc: DocInfo): Promise<DraftingPermissions>;
```

Schema ownership columns (đã grep repository — KHÔNG tự đoán):
- `edoc.incoming_docs`: `unit_id BIGINT`, `created_by BIGINT` (KHÔNG có drafting_user_id)
- `edoc.outgoing_docs`: `unit_id BIGINT`, `created_by BIGINT`, `drafting_user_id BIGINT`
- `edoc.drafting_docs`: `unit_id BIGINT`, `drafting_user_id BIGINT`, `created_by BIGINT`

Frontend DocPermissions interface (copy trực tiếp từ VB dự thảo):
```typescript
permissions?: {
  canEdit: boolean;
  canApprove: boolean;
  canRelease: boolean;
  canSend: boolean;
  canRetract: boolean;
};
```

Route `loadDocAndPerms` pattern (drafting-doc.ts dòng 19-31) — copy cấu trúc:
```typescript
async function loadDocAndPerms(docId: number, userCtx: DocPermissionContext) {
  const doc = await <repo>.getById(docId, userCtx.staffId);
  if (!doc) return null;
  const perms = await compute<X>Permissions(userCtx, {...});
  return { doc, perms };
}
```

Route guard pattern (drafting-doc.ts dòng 302-317) — copy y nguyên:
```typescript
const loaded = await loadDocAndPerms(id, { staffId, departmentId, isAdmin });
if (!loaded) { res.status(404).json({...}); return; }
if (!loaded.perms.canX) { res.status(403).json({ success: false, message: '...' }); return; }
```

Batch enrich pattern cho GET / (drafting-doc.ts dòng 77-87):
```typescript
if (rows.length > 0) {
  const userCtx = await getUserPermissionContext({ staffId, departmentId, isAdmin });
  rows.forEach((r: any) => {
    r.permissions = computePermsWithContext(userCtx, { id: r.id, ..., unit_id: r.unit_id });
  });
}
```

Rules (không đổi, copy từ drafting-doc.ts comment):
```
canEdit    = isAdmin || isOwner || (sameUnit && is_handle_document)
canApprove = isAdmin || (sameUnit && is_leader)
canRelease = isAdmin || (sameUnit && is_leader)
canSend    = isAdmin || isOwner || (sameUnit && is_leader)
canRetract = isAdmin || (sameUnit && is_leader)
```
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Refactor drafting-doc permission helper — tách shared logic ra _shared.ts</name>
  <files>
    - e_office_app_new/backend/src/lib/permissions/_shared.ts (CREATE)
    - e_office_app_new/backend/src/lib/permissions/drafting-doc.ts (UPDATE — wrap shared, giữ backward-compat exports)
  </files>
  <read_first>
    - e_office_app_new/backend/src/lib/permissions/drafting-doc.ts (pattern hiện tại — 128 dòng)
    - e_office_app_new/backend/src/routes/drafting-doc.ts (import để verify không break — dòng 12 import list)
  </read_first>
  <action>
Tạo `_shared.ts` và refactor `drafting-doc.ts` wrap shared.

### Bước 1: Tạo `_shared.ts`

Copy toàn bộ nội dung từ `drafting-doc.ts` sang `_shared.ts` với 4 thay đổi:

a) Đổi tên `DraftingPermissions` → `DocPermissions` (type chung cho 3 module).

b) Đổi tên `DocInfo` → `DocOwnershipInfo`, chỉ chứa `{ id: number; unit_id: number }` (KHÔNG chứa `drafting_user_id`, vì ownership field khác nhau giữa 3 module).

c) Tách logic compute thành **pure function nhận flag `isOwner: boolean`** (module caller tự tính isOwner):

```typescript
// _shared.ts
export interface DocPermissionContext {
  staffId: number;
  departmentId: number;
  isAdmin: boolean;
}

export interface DocOwnershipInfo {
  id: number;
  unit_id: number;
}

export interface DocPermissions {
  canEdit: boolean;
  canApprove: boolean;
  canRelease: boolean;
  canSend: boolean;
  canRetract: boolean;
}

export interface UserPermissionContext {
  staffId: number;
  userUnitId: number | null;
  isAdmin: boolean;
  is_leader: boolean;
  is_handle_document: boolean;
}

// Giữ nguyên getStaffPosition + getUserPermissionContext (copy 1:1 từ drafting-doc.ts).

/**
 * Compute permissions pure sync, nhận sẵn isOwner (caller tự tính).
 * Rules giống hệt drafting — không đổi.
 */
export function computePermsFromContext(
  ctx: UserPermissionContext,
  doc: DocOwnershipInfo,
  isOwner: boolean,
): DocPermissions {
  if (ctx.isAdmin) {
    return { canEdit: true, canApprove: true, canRelease: true, canSend: true, canRetract: true };
  }
  const sameUnit = ctx.userUnitId === doc.unit_id;
  const isLeader = sameUnit && ctx.is_leader;
  const isHandler = sameUnit && ctx.is_handle_document;
  return {
    canEdit: isOwner || isHandler,
    canApprove: isLeader,
    canRelease: isLeader,
    canSend: isOwner || isLeader,
    canRetract: isLeader,
  };
}
```

d) `getStaffPosition` chuyển thành private (không export — chỉ dùng nội bộ).

### Bước 2: Refactor `drafting-doc.ts` wrap `_shared.ts`

Giữ backward-compat 100% (route file drafting-doc.ts hiện import: `computeDraftingPermissions, computePermsWithContext, getUserPermissionContext, DocPermissionContext` — KHÔNG được break):

```typescript
// drafting-doc.ts
import {
  type DocPermissionContext,
  type DocPermissions,
  type UserPermissionContext,
  getUserPermissionContext,
  computePermsFromContext,
} from './_shared.js';

// Re-export để route drafting không phải đổi import
export { getUserPermissionContext };
export type { DocPermissionContext, UserPermissionContext };

// Alias giữ backward-compat
export type DraftingPermissions = DocPermissions;

// DocInfo vẫn export (route drafting-doc.ts dùng)
export interface DocInfo {
  id: number;
  drafting_user_id: number | null;
  unit_id: number;
}

// Wrap compute — isOwner = staffId === drafting_user_id
export function computePermsWithContext(
  ctx: UserPermissionContext,
  doc: DocInfo,
): DraftingPermissions {
  const isOwner = doc.drafting_user_id != null && ctx.staffId === doc.drafting_user_id;
  return computePermsFromContext(ctx, { id: doc.id, unit_id: doc.unit_id }, isOwner);
}

export async function computeDraftingPermissions(
  user: DocPermissionContext,
  doc: DocInfo,
): Promise<DraftingPermissions> {
  const ctx = await getUserPermissionContext(user);
  return computePermsWithContext(ctx, doc);
}
```

**CRITICAL:** KHÔNG đổi signature/tên export nào ở `drafting-doc.ts` — route drafting-doc.ts dòng 12 phải import OK mà không sửa gì.

### Bước 3: TS check
Chạy `cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | head -30` → verify 0 new errors (baseline existing errors nếu có thì ghi xuống).
  </action>
  <verify>
    <automated>cd e_office_app_new/backend &amp;&amp; npx tsc --noEmit 2>&amp;1 | grep -E "lib/permissions|routes/drafting-doc" ; exit 0</automated>
  </verify>
  <acceptance_criteria>
    - `grep -l "computePermsFromContext" e_office_app_new/backend/src/lib/permissions/_shared.ts` trả 1 file (hàm exist)
    - `grep -c "export" e_office_app_new/backend/src/lib/permissions/_shared.ts` ≥ 5 (có ít nhất 5 exports: DocPermissionContext, DocOwnershipInfo, DocPermissions, UserPermissionContext, getUserPermissionContext, computePermsFromContext)
    - `grep -l "from './_shared.js'" e_office_app_new/backend/src/lib/permissions/drafting-doc.ts` trả 1 file
    - `grep -E "export (async )?function computeDraftingPermissions|export function computePermsWithContext|export (async )?function getUserPermissionContext|export type" e_office_app_new/backend/src/lib/permissions/drafting-doc.ts | wc -l` ≥ 4 (backward-compat exports giữ nguyên)
    - TypeScript compile file route drafting-doc.ts → 0 error liên quan permissions
  </acceptance_criteria>
  <done>_shared.ts có pure compute function + context loader. drafting-doc.ts wrap shared, pass `isOwner = staffId === drafting_user_id`. Route drafting-doc.ts compile OK không sửa.</done>
</task>

<task type="auto">
  <name>Task 2: Backend helper cho VB đến — incoming-doc.ts</name>
  <files>
    - e_office_app_new/backend/src/lib/permissions/incoming-doc.ts (CREATE)
  </files>
  <read_first>
    - e_office_app_new/backend/src/lib/permissions/_shared.ts (Task 1 — shared types)
    - e_office_app_new/backend/src/lib/permissions/drafting-doc.ts (pattern wrap)
    - e_office_app_new/backend/src/repositories/incoming-doc.repository.ts dòng 1-50 (verify `created_by` + `unit_id` trong IncomingDocRow / getById return)
  </read_first>
  <action>
Tạo file wrap `_shared.ts` với `isOwner = staffId === created_by` (VB đến không có `drafting_user_id`).

```typescript
// incoming-doc.ts
import {
  type DocPermissionContext,
  type DocPermissions,
  type UserPermissionContext,
  getUserPermissionContext,
  computePermsFromContext,
} from './_shared.js';

export interface IncomingDocInfo {
  id: number;
  unit_id: number;
  created_by: number | null;
}

/**
 * Compute pure sync — dùng trong loop batch list (N+1 safe).
 * VB đến: isOwner = staffId === created_by (người văn thư tạo VB — không có khái niệm "drafter").
 */
export function computeIncomingPermsWithContext(
  ctx: UserPermissionContext,
  doc: IncomingDocInfo,
): DocPermissions {
  const isOwner = doc.created_by != null && ctx.staffId === doc.created_by;
  return computePermsFromContext(ctx, { id: doc.id, unit_id: doc.unit_id }, isOwner);
}

/**
 * Async compute cho 1 doc (load ctx + pure compute).
 */
export async function computeIncomingPermissions(
  user: DocPermissionContext,
  doc: IncomingDocInfo,
): Promise<DocPermissions> {
  const ctx = await getUserPermissionContext(user);
  return computeIncomingPermsWithContext(ctx, doc);
}
```

**Note ngữ nghĩa VB đến:**
- `canRelease` hơi "thừa" về mặt nghiệp vụ (VB đến không có phát hành) — nhưng vẫn return cho uniform. Route sẽ không dùng field này (không có endpoint "ban-hanh" cho VB đến). Frontend cũng không hiển thị nút "Phát hành" trên VB đến. OK để tồn tại.
- `canApprove` = "duyệt VB đến" (vào sổ / chấp nhận VB) + "giao xử lý" + "nhận bản giấy" (các action lãnh đạo).
- `canSend` = "gửi VB cho cán bộ xử lý nội bộ".
- `canRetract` = "thu hồi VB đã gửi" / "chuyển lại VB đã nhận" (reject bàn giao).

TypeScript check: `cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | grep permissions/incoming-doc`.
  </action>
  <verify>
    <automated>cd e_office_app_new/backend &amp;&amp; npx tsc --noEmit 2>&amp;1 | grep "lib/permissions/incoming-doc" ; exit 0</automated>
  </verify>
  <acceptance_criteria>
    - File `e_office_app_new/backend/src/lib/permissions/incoming-doc.ts` tồn tại
    - `grep -c "export" e_office_app_new/backend/src/lib/permissions/incoming-doc.ts` ≥ 3 (IncomingDocInfo + computeIncomingPermsWithContext + computeIncomingPermissions)
    - `grep "from './_shared.js'" e_office_app_new/backend/src/lib/permissions/incoming-doc.ts` → 1 match
    - `grep "staffId === doc.created_by" e_office_app_new/backend/src/lib/permissions/incoming-doc.ts` → 1 match (isOwner đúng logic)
    - TS check 0 new errors trong file này
  </acceptance_criteria>
  <done>Helper incoming-doc.ts tạo xong, wrap _shared.ts, isOwner tính theo created_by.</done>
</task>

<task type="auto">
  <name>Task 3: Backend helper cho VB đi — outgoing-doc.ts</name>
  <files>
    - e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts (CREATE)
  </files>
  <read_first>
    - e_office_app_new/backend/src/lib/permissions/_shared.ts (Task 1 shared types)
    - e_office_app_new/backend/src/lib/permissions/drafting-doc.ts (pattern — giống drafting do outgoing có drafting_user_id)
    - e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts dòng 1-50 (verify `unit_id` + `drafting_user_id` + `created_by` trong OutgoingDocRow)
  </read_first>
  <action>
Tạo wrap `_shared.ts` với **isOwner = (staffId === drafting_user_id) OR (staffId === created_by)**. Lý do: VB đi có cả 2 trường — người soạn (drafting_user_id) + người tạo record (created_by). Cả 2 đều coi là "owner" để không mất quyền khi văn thư tạo giúp.

```typescript
// outgoing-doc.ts
import {
  type DocPermissionContext,
  type DocPermissions,
  type UserPermissionContext,
  getUserPermissionContext,
  computePermsFromContext,
} from './_shared.js';

export interface OutgoingDocInfo {
  id: number;
  unit_id: number;
  drafting_user_id: number | null;
  created_by: number | null;
}

export function computeOutgoingPermsWithContext(
  ctx: UserPermissionContext,
  doc: OutgoingDocInfo,
): DocPermissions {
  const isDrafter = doc.drafting_user_id != null && ctx.staffId === doc.drafting_user_id;
  const isCreator = doc.created_by != null && ctx.staffId === doc.created_by;
  const isOwner = isDrafter || isCreator;
  return computePermsFromContext(ctx, { id: doc.id, unit_id: doc.unit_id }, isOwner);
}

export async function computeOutgoingPermissions(
  user: DocPermissionContext,
  doc: OutgoingDocInfo,
): Promise<DocPermissions> {
  const ctx = await getUserPermissionContext(user);
  return computeOutgoingPermsWithContext(ctx, doc);
}
```

TS check file.
  </action>
  <verify>
    <automated>cd e_office_app_new/backend &amp;&amp; npx tsc --noEmit 2>&amp;1 | grep "lib/permissions/outgoing-doc" ; exit 0</automated>
  </verify>
  <acceptance_criteria>
    - File `e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts` tồn tại
    - `grep -c "export" e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts` ≥ 3
    - `grep "from './_shared.js'" e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts` → 1 match
    - `grep "drafting_user_id" e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts` → ≥ 2 match (interface + isOwner check)
    - `grep "created_by" e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts` → ≥ 2 match (interface + isOwner check)
    - TS check 0 new errors
  </acceptance_criteria>
  <done>Helper outgoing-doc.ts tạo xong, isOwner = drafter OR creator.</done>
</task>

<task type="auto">
  <name>Task 4: Routes VB đến — guard + enrich permissions</name>
  <files>
    - e_office_app_new/backend/src/routes/incoming-doc.ts (UPDATE)
  </files>
  <read_first>
    - e_office_app_new/backend/src/routes/drafting-doc.ts dòng 1-32 (pattern loadDocAndPerms + import)
    - e_office_app_new/backend/src/routes/drafting-doc.ts dòng 302-390 (pattern PUT + DELETE guard)
    - e_office_app_new/backend/src/routes/drafting-doc.ts dòng 558-707 (pattern approve/reject/retract/release guard)
    - e_office_app_new/backend/src/routes/drafting-doc.ts dòng 40-102 (pattern GET / batch enrich)
    - e_office_app_new/backend/src/routes/drafting-doc.ts dòng 275-300 (pattern GET /:id enrich permissions)
    - e_office_app_new/backend/src/routes/incoming-doc.ts (target — đọc 870+ dòng để liệt kê endpoints chính xác)
    - e_office_app_new/backend/src/lib/permissions/incoming-doc.ts (Task 2)
  </read_first>
  <action>
Áp pattern từ drafting-doc.ts vào incoming-doc.ts. 3 phần: (A) helper loadDocAndPerms, (B) guard mutation endpoints, (C) enrich list + detail.

### Bước 0: Grep endpoints thực tế để verify trước khi code
```bash
grep -nE "^router\.(get|post|put|patch|delete)" e_office_app_new/backend/src/routes/incoming-doc.ts
```
Danh sách dự kiến (đã grep — verify khớp):
- PUT /:id → canEdit
- DELETE /:id → canEdit
- POST /:id/gui → canSend
- PATCH /:id/duyet → canApprove
- PATCH /:id/huy-duyet → canApprove
- PATCH /:id/nhan-ban-giay → canApprove (action lãnh đạo xác nhận nhận bản giấy)
- POST /:id/giao-viec → canApprove (giao xử lý — action lãnh đạo)
- POST /:id/them-vao-hscv → canApprove (link HSCV — action lãnh đạo, tương tự giao-viec)
- POST /:id/gui-lien-thong → canApprove (gửi LGSP ra ngoài — action lãnh đạo / văn thư)
- POST /:id/thu-hoi → canRetract
- POST /:id/chuyen-lai → canRetract (chuyển lại VB đã nhận — đối xứng retract)
- POST /:id/chuyen-luu-tru → canApprove (chuyển lưu trữ — action lãnh đạo)

KHÔNG guard (giữ nguyên):
- GET / (enrich permissions instead)
- GET /:id (enrich permissions)
- GET /:id/nguoi-nhan, /lich-su, /dinh-kem (read-only)
- GET /:id/danh-sach-gui, /danh-sach-hscv, /lgsp/don-vi (read-only dropdown helpers)
- POST / (create — ai cũng tạo được VB đến mới)
- POST /:id/dinh-kem, DELETE /:id/dinh-kem/:attId (attachment — giữ permission model hiện tại, khó map, out of scope)
- POST /:id/nhan-ban-giao (nhận bàn giao — cán bộ được gán tự nhận, KHÔNG guard)
- PATCH /danh-dau-da-doc, POST /:id/danh-dau (bookmark cá nhân — KHÔNG guard)
- POST /:id/but-phe, DELETE /:id/but-phe/:noteId (ý kiến lãnh đạo — backend SP tự check ownership, KHÔNG guard lại ở route)

### Bước 1: Import helper + tạo loadDocAndPerms

Thêm dòng import (sau import hiện có):
```typescript
import {
  computeIncomingPermissions,
  computeIncomingPermsWithContext,
} from '../lib/permissions/incoming-doc.js';
import { getUserPermissionContext, type DocPermissionContext } from '../lib/permissions/_shared.js';
```

Thêm hàm sau `const router = Router();`:

```typescript
/** Load doc + compute perms. Dùng rawQuery để lấy unit_id + created_by (lean — không cần full getById). */
async function loadDocAndPerms(docId: number, userCtx: DocPermissionContext) {
  const rows = await rawQuery<{ id: number; unit_id: number; created_by: number | null }>(
    `SELECT id, unit_id, created_by FROM edoc.incoming_docs WHERE id = $1`, [docId],
  );
  if (rows.length === 0) return null;
  const doc = rows[0];
  const perms = await computeIncomingPermissions(userCtx, doc);
  return { doc, perms };
}
```

### Bước 2: Guard mutation endpoints

Cho mỗi endpoint trong danh sách ở Bước 0, thêm block guard ngay đầu handler (sau khi parse `docId`, trước mọi validation khác):

```typescript
const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
const docId = Number(req.params.id);
const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
if (!loaded) { res.status(404).json({ success: false, message: 'Không tìm thấy văn bản đến' }); return; }
if (!loaded.perms.<canX>) { res.status(403).json({ success: false, message: '<msg>' }); return; }
```

Message mapping (Vietnamese):
- canEdit guard trên PUT /:id: `'Không có quyền sửa văn bản đến này'`
- canEdit guard trên DELETE /:id: `'Không có quyền xóa văn bản đến này'`
- canSend guard trên POST /:id/gui: `'Không có quyền gửi văn bản đến này'`
- canApprove trên PATCH /:id/duyet: `'Không có quyền duyệt văn bản đến này'`
- canApprove trên PATCH /:id/huy-duyet: `'Không có quyền hủy duyệt văn bản đến này'`
- canApprove trên PATCH /:id/nhan-ban-giay: `'Không có quyền xác nhận nhận bản giấy'`
- canApprove trên POST /:id/giao-viec: `'Không có quyền giao xử lý văn bản đến này'`
- canApprove trên POST /:id/them-vao-hscv: `'Không có quyền thêm vào hồ sơ công việc'`
- canApprove trên POST /:id/gui-lien-thong: `'Không có quyền gửi liên thông văn bản đến này'`
- canApprove trên POST /:id/chuyen-luu-tru: `'Không có quyền chuyển lưu trữ văn bản này'`
- canRetract trên POST /:id/thu-hoi: `'Không có quyền thu hồi văn bản đến này'`
- canRetract trên POST /:id/chuyen-lai: `'Không có quyền chuyển lại văn bản đến này'`

**LƯU Ý khi sửa PUT /:id**: File hiện tại đã có check `source_type='manual'` — GIỮ NGUYÊN check đó, chỉ thêm guard canEdit **trước** check source_type (để người không có quyền sẽ thấy 403 ngay, không lộ thông tin source_type).

### Bước 3: Enrich GET / (batch — pattern drafting-doc.ts dòng 77-87)

Sau block enrich `rejected_by` hiện có (dòng ~50-59 file incoming-doc.ts), thêm:

```typescript
// Enrich permissions per row (batch — 1 query load user ctx, pure compute per row)
if (rows.length > 0) {
  const userCtx = await getUserPermissionContext({ staffId, departmentId, isAdmin });
  rows.forEach((r: any) => {
    r.permissions = computeIncomingPermsWithContext(userCtx, {
      id: r.id,
      unit_id: r.unit_id,
      created_by: r.created_by ?? null,
    });
  });
}
```

**Precheck:** `IncomingDocListRow` phải có `unit_id` + `created_by`. Grep `incoming-doc.repository.ts` → nếu thiếu field nào thì JOIN/SELECT thêm trong SP `fn_incoming_doc_get_list` bằng **additional enrich query** thay vì sửa SP (an toàn hơn):

```typescript
// Nếu rows thiếu unit_id/created_by (verify bằng grep repo Row interface):
const ids = rows.map(r => r.id);
const ownershipRows = await rawQuery<{ id: number; unit_id: number; created_by: number | null }>(
  `SELECT id, unit_id, created_by FROM edoc.incoming_docs WHERE id = ANY($1)`, [ids],
);
const ownMap = new Map(ownershipRows.map(r => [r.id, r]));
rows.forEach((r: any) => {
  const own = ownMap.get(r.id);
  if (own) { r.unit_id = own.unit_id; r.created_by = own.created_by; }
});
```

Làm tương tự cho GET /xuat-excel nếu cần (nhưng xuất Excel KHÔNG cần permissions — skip).

### Bước 4: Enrich GET /:id

Sau khi load doc + enrich extra_fields/recipientsSummary (dòng ~292), thêm:

```typescript
// Compute permissions
const permissions = await computeIncomingPermissions(
  { staffId, departmentId, isAdmin },
  {
    id: doc.id,
    unit_id: (doc as any).unit_id,
    created_by: (doc as any).created_by ?? null,
  },
);
```

Và inject vào response:
```typescript
res.json({ success: true, data: { ...doc, recipients: recipientsSummary, ..., permissions } });
```

**Verify:** destructure `isAdmin` từ req.user ở đầu handler (hiện chỉ có `staffId` — phải update line).

### Bước 5: TS check backend

```bash
cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | grep "routes/incoming-doc" ; exit 0
```

0 new errors.
  </action>
  <verify>
    <automated>cd e_office_app_new/backend &amp;&amp; npx tsc --noEmit 2>&amp;1 | grep "routes/incoming-doc" ; exit 0</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "loadDocAndPerms" e_office_app_new/backend/src/routes/incoming-doc.ts` ≥ 10 (1 definition + ≥ 9 usage sites tương ứng số mutation endpoint guard)
    - `grep -c "computeIncomingPermissions\|computeIncomingPermsWithContext" e_office_app_new/backend/src/routes/incoming-doc.ts` ≥ 2
    - `grep -c "res.status(403)" e_office_app_new/backend/src/routes/incoming-doc.ts` ≥ 9 (ít nhất 9 guard 403)
    - `grep -nE "perms\.(canEdit|canApprove|canSend|canRetract)" e_office_app_new/backend/src/routes/incoming-doc.ts | wc -l` ≥ 9
    - GET /:id handler có inject `permissions` vào response: `grep -A3 "permissions = await computeIncomingPermissions" e_office_app_new/backend/src/routes/incoming-doc.ts` → match
    - GET / handler có batch enrich: `grep "computeIncomingPermsWithContext" e_office_app_new/backend/src/routes/incoming-doc.ts` → match
    - TS 0 new errors trong file
  </acceptance_criteria>
  <done>Route VB đến có loadDocAndPerms, ≥ 9 mutation endpoints guard 403, list batch enrich + detail enrich permissions. Check source_type vẫn còn (không bị xóa).</done>
</task>

<task type="auto">
  <name>Task 5: Routes VB đi — guard + enrich permissions</name>
  <files>
    - e_office_app_new/backend/src/routes/outgoing-doc.ts (UPDATE)
  </files>
  <read_first>
    - e_office_app_new/backend/src/routes/drafting-doc.ts (pattern guard + batch enrich — đã đọc ở Task 4)
    - e_office_app_new/backend/src/routes/outgoing-doc.ts (target — 940 dòng)
    - e_office_app_new/backend/src/lib/permissions/outgoing-doc.ts (Task 3)
  </read_first>
  <action>
Áp pattern tương tự Task 4 cho outgoing-doc.ts. Endpoints khác do VB đi có "Ban hành" (release) đầy đủ.

### Bước 0: Grep endpoints actual
```bash
grep -nE "^router\.(get|post|put|patch|delete)" e_office_app_new/backend/src/routes/outgoing-doc.ts
```

Mapping action → flag:
- PUT /:id → canEdit
- DELETE /:id → canEdit
- POST /:id/gui → canSend
- POST /:id/gui-noi-bo → canSend
- POST /:id/gui-lien-thong → canSend (gửi LGSP — action owner/leader)
- POST /:id/gui-truc-cp → canSend (mock trục CP — tương tự LGSP)
- PATCH /:id/duyet → canApprove
- PATCH /:id/huy-duyet → canApprove
- PATCH /:id/tu-choi → canApprove (từ chối duyệt — action lãnh đạo)
- POST /:id/giao-viec → canApprove (tạo HSCV — action lãnh đạo)
- POST /:id/them-vao-hscv → canApprove
- PATCH /:id/ban-hanh → canRelease (CHÍNH — ban hành cấp số)
- POST /:id/noi-nhan → canRelease (set recipients trước ban hành — cùng nhóm ban hành)
- POST /:id/thu-hoi → canRetract
- POST /:id/chuyen-luu-tru → canApprove

KHÔNG guard:
- GET / (enrich permissions)
- GET /:id (enrich permissions)
- GET /:id/nguoi-nhan, /noi-nhan, /lich-su, /dinh-kem, /danh-sach-gui, /danh-sach-hscv, /kiem-tra-so (read-only)
- POST / (create)
- POST /:id/dinh-kem, DELETE /:id/dinh-kem/:attId (attachment — out of scope)
- POST /:id/danh-dau, PATCH /danh-dau-da-doc (bookmark cá nhân)
- POST /:id/y-kien, DELETE /:id/y-kien/:noteId (ý kiến — SP tự check ownership)

### Bước 1: Import + loadDocAndPerms

```typescript
import {
  computeOutgoingPermissions,
  computeOutgoingPermsWithContext,
} from '../lib/permissions/outgoing-doc.js';
import { getUserPermissionContext, type DocPermissionContext } from '../lib/permissions/_shared.js';

async function loadDocAndPerms(docId: number, userCtx: DocPermissionContext) {
  const rows = await rawQuery<{ id: number; unit_id: number; drafting_user_id: number | null; created_by: number | null }>(
    `SELECT id, unit_id, drafting_user_id, created_by FROM edoc.outgoing_docs WHERE id = $1`, [docId],
  );
  if (rows.length === 0) return null;
  const doc = rows[0];
  const perms = await computeOutgoingPermissions(userCtx, doc);
  return { doc, perms };
}
```

### Bước 2: Guard 15 mutation endpoints

Pattern giống Task 4. Message Vietnamese:
- canEdit: `'Không có quyền sửa văn bản đi này'` / `'Không có quyền xóa văn bản đi này'`
- canSend: `'Không có quyền gửi văn bản đi này'` (gui, gui-noi-bo) / `'Không có quyền gửi liên thông văn bản đi này'` (gui-lien-thong) / `'Không có quyền gửi trục CP văn bản đi này'` (gui-truc-cp)
- canApprove: `'Không có quyền duyệt/hủy duyệt/từ chối văn bản đi này'` (tùy endpoint) / `'Không có quyền giao xử lý văn bản đi này'` / `'Không có quyền thêm vào hồ sơ công việc'` / `'Không có quyền chuyển lưu trữ văn bản này'`
- canRelease: `'Không có quyền ban hành văn bản đi này'` / `'Không có quyền cập nhật nơi nhận văn bản đi này'`
- canRetract: `'Không có quyền thu hồi văn bản đi này'`

### Bước 3: Enrich GET / (batch)

Sau block enrich `rejected_by` + `recipients_summary` hiện có (dòng ~46-77), thêm:

```typescript
if (rows.length > 0) {
  const userCtx = await getUserPermissionContext({ staffId, departmentId, isAdmin });
  // Nếu rows thiếu ownership fields — enrich từ edoc.outgoing_docs
  const ids = rows.map(r => r.id);
  const ownershipRows = await rawQuery<{ id: number; unit_id: number; drafting_user_id: number | null; created_by: number | null }>(
    `SELECT id, unit_id, drafting_user_id, created_by FROM edoc.outgoing_docs WHERE id = ANY($1)`, [ids],
  );
  const ownMap = new Map(ownershipRows.map(r => [r.id, r]));
  rows.forEach((r: any) => {
    const own = ownMap.get(r.id);
    if (own) {
      r.permissions = computeOutgoingPermsWithContext(userCtx, {
        id: own.id,
        unit_id: own.unit_id,
        drafting_user_id: own.drafting_user_id,
        created_by: own.created_by,
      });
    }
  });
}
```

### Bước 4: Enrich GET /:id

Ngay trước `res.json({ success: true, data: doc })` (dòng ~312):

```typescript
// Compute permissions
const permissions = await computeOutgoingPermissions(
  { staffId, departmentId, isAdmin },
  {
    id: (doc as any).id,
    unit_id: (doc as any).unit_id,
    drafting_user_id: (doc as any).drafting_user_id ?? null,
    created_by: (doc as any).created_by ?? null,
  },
);
(doc as any).permissions = permissions;
```

**Verify:** `isAdmin` + `departmentId` có destructure ở đầu handler (hiện chỉ có `staffId` — phải update).

### Bước 5: TS check
```bash
cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | grep "routes/outgoing-doc" ; exit 0
```

0 new errors.
  </action>
  <verify>
    <automated>cd e_office_app_new/backend &amp;&amp; npx tsc --noEmit 2>&amp;1 | grep "routes/outgoing-doc" ; exit 0</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "loadDocAndPerms" e_office_app_new/backend/src/routes/outgoing-doc.ts` ≥ 16 (1 def + ≥ 15 usage)
    - `grep -c "computeOutgoingPermissions\|computeOutgoingPermsWithContext" e_office_app_new/backend/src/routes/outgoing-doc.ts` ≥ 2
    - `grep -c "res.status(403)" e_office_app_new/backend/src/routes/outgoing-doc.ts` ≥ 15
    - `grep -nE "perms\.(canEdit|canApprove|canRelease|canSend|canRetract)" e_office_app_new/backend/src/routes/outgoing-doc.ts | wc -l` ≥ 15
    - Endpoint `/ban-hanh` + `/noi-nhan` dùng `canRelease`: `grep -B2 "perms.canRelease" e_office_app_new/backend/src/routes/outgoing-doc.ts` → ≥ 2 block
    - TS 0 new errors
  </acceptance_criteria>
  <done>Route VB đi có loadDocAndPerms, ≥ 15 endpoints guard 403, list + detail enrich permissions.</done>
</task>

<task type="auto">
  <name>Task 6: Frontend VB đến — conditional render theo permissions</name>
  <files>
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx (UPDATE)
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx (UPDATE)
  </files>
  <read_first>
    - e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/page.tsx dòng 70-80 (interface DocPermissions)
    - e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/page.tsx dòng 450-515 (pattern gate dropdown — copy structure)
    - e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx dòng 40-48 (interface DocDetail permissions)
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx (target — đọc full interface IncomingDoc + actions column)
    - e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx (target — buttons pattern)
  </read_first>
  <action>

### Phần A: `page.tsx` (list)

1. **Thêm permissions vào interface** `IncomingDoc` (grep current: dòng ~30 — tìm `interface IncomingDoc {`):
```typescript
permissions?: {
  canEdit: boolean;
  canApprove: boolean;
  canRelease: boolean;
  canSend: boolean;
  canRetract: boolean;
};
```

2. **Update actions column** (dòng ~350-375). Thay pattern cũ chỉ gate theo `record.approved`:

```typescript
// Cũ: ...(!record.approved ? [...] : [...])
// Mới: gate theo perms + status

const perms = record.permissions;
const statusAllowEdit = !record.approved;
const statusAllowRetract = !!record.approved;
const isSourceManual = ((record as any).source_type || 'manual') === 'manual';
const isRejected = !!(record as any).rejected_by;

const canEdit = statusAllowEdit && isSourceManual && (perms?.canEdit ?? false);
const canApprove = statusAllowEdit && (perms?.canApprove ?? false);
const canUnapprove = !statusAllowEdit && (perms?.canApprove ?? false);
const canRetract = statusAllowRetract && (perms?.canRetract ?? false);
const canDelete = statusAllowEdit && (perms?.canEdit ?? false);

const items = [
  { key: 'view', icon: <EyeOutlined />, label: 'Xem chi tiết', onClick: () => { window.location.href = `/van-ban-den/${record.id}`; } },
  ...(canEdit ? [{ key: 'edit', icon: <EditOutlined />, label: 'Sửa', onClick: () => openDrawer(record) }] : []),
  ...(canApprove ? [{ key: 'approve', icon: <CheckCircleOutlined />, label: 'Duyệt', onClick: () => handleApprove(record) }] : []),
  ...(canUnapprove ? [{ key: 'unapprove', icon: <CloseCircleOutlined />, label: 'Hủy duyệt', onClick: () => handleUnapprove(record) }] : []),
  ...(canRetract ? [{ key: 'retract', icon: <RollbackOutlined />, label: 'Thu hồi', onClick: () => handleRetract(record) }] : []),
  ...(canDelete ? [
    { type: 'divider' as const },
    { key: 'delete', icon: <DeleteOutlined />, label: 'Xóa', danger: true, onClick: () => handleDelete(record) },
  ] : []),
];
```

**CHÚ Ý:** Giữ lại logic hiện có — chỉ bọc thêm `perms?.canX` kết hợp status. KHÔNG xóa check `source_type === 'manual'` cho edit.

### Phần B: `[id]/page.tsx` (detail)

1. **Thêm `permissions?` vào interface DocDetail** (dòng ~30):
```typescript
permissions?: {
  canEdit: boolean;
  canApprove: boolean;
  canRelease: boolean;
  canSend: boolean;
  canRetract: boolean;
};
```

2. **Grep các nút action hiện có** (dòng ~470-500):
```bash
grep -nE "Button|key: '(edit|approve|unapprove|retract|reject|delete)" e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx
```

3. **Gate từng button/dropdown item** theo `doc.permissions` giống Phần A. Ví dụ nút Duyệt (dòng ~476):
```typescript
{doc && !doc.approved && (doc.permissions?.canApprove ?? false) && (
  <Button type="primary" icon={<CheckCircleOutlined />} onClick={handleApprove}>Duyệt</Button>
)}
```

Áp dụng cho các nút: Sửa, Duyệt, Hủy duyệt, Giao xử lý, Chuyển lại, Thu hồi, Xóa, Gửi cán bộ, Nhận bản giấy, Gửi liên thông.

Mapping:
- Sửa (mở drawer hoặc link `/van-ban-den/${id}/edit`): `perms.canEdit && !approved && source_type === 'manual'`
- Duyệt: `perms.canApprove && !approved`
- Hủy duyệt: `perms.canApprove && approved`
- Giao xử lý / Giao việc: `perms.canApprove && approved` (chỉ giao sau khi duyệt)
- Gửi cán bộ: `perms.canSend && approved`
- Nhận bản giấy: `perms.canApprove` (có thể không phụ thuộc approved — kiểm tra logic hiện tại)
- Thu hồi: `perms.canRetract && approved` (hoặc `recipients.length > 0` nếu logic hiện có)
- Chuyển lại: `perms.canRetract`
- Xóa: `perms.canEdit && !approved && source_type === 'manual'`
- Gửi liên thông: `perms.canApprove` (nếu LGSP modal có)

**KHÔNG xóa check hiện tại** (status, recipients.length, source_type) — chỉ AND thêm `perms`.

### TS check frontend
```bash
cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | grep "van-ban-den" ; exit 0
```

0 new errors.
  </action>
  <verify>
    <automated>cd e_office_app_new/frontend &amp;&amp; npx tsc --noEmit 2>&amp;1 | grep "van-ban-den" ; exit 0</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "permissions?:" e_office_app_new/frontend/src/app/\(main\)/van-ban-den/page.tsx` ≥ 1
    - `grep -c "permissions?:" e_office_app_new/frontend/src/app/\(main\)/van-ban-den/\[id\]/page.tsx` ≥ 1
    - `grep -cE "perms\?\.(canEdit|canApprove|canSend|canRetract)" e_office_app_new/frontend/src/app/\(main\)/van-ban-den/page.tsx` ≥ 4
    - `grep -cE "doc\.permissions\?\.(canEdit|canApprove|canSend|canRetract)|doc\?\.permissions\?" e_office_app_new/frontend/src/app/\(main\)/van-ban-den/\[id\]/page.tsx` ≥ 5
    - Logic `source_type === 'manual'` vẫn còn: `grep "source_type" e_office_app_new/frontend/src/app/\(main\)/van-ban-den/page.tsx` → match
    - TS frontend 0 new errors
  </acceptance_criteria>
  <done>VB đến list + detail render có điều kiện theo permissions, giữ các status gate hiện có.</done>
</task>

<task type="auto">
  <name>Task 7: Frontend VB đi — conditional render theo permissions</name>
  <files>
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx (UPDATE)
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx (UPDATE)
  </files>
  <read_first>
    - e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx (pattern detail với nhiều button — Duyệt/Ban hành/Gửi/Thu hồi)
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/page.tsx (target — actions column dòng 384-411)
    - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx (target — buttons dòng 430-470)
  </read_first>
  <action>

### Phần A: `page.tsx` (list)

1. **Thêm `permissions?:`** vào interface `OutgoingDoc` (giống Task 6 Phần A).

2. **Update actions column** (dòng ~388-411):

```typescript
const perms = record.permissions;
const statusAllowEdit = !record.approved;
const statusAllowRelease = !!record.approved && !(record as any).is_released;
const statusAllowRetract = !!record.approved;
const isRejected = !!record.rejected_by;

const canEdit = statusAllowEdit && (perms?.canEdit ?? false);
const canApprove = statusAllowEdit && (perms?.canApprove ?? false);
const canReject = statusAllowEdit && !isRejected && (perms?.canApprove ?? false);
const canUnapprove = !statusAllowEdit && (perms?.canApprove ?? false);
const canRetract = statusAllowRetract && (perms?.canRetract ?? false);
const canDelete = statusAllowEdit && (perms?.canEdit ?? false);

const items = [
  { key: 'view', icon: <EyeOutlined />, label: 'Xem chi tiết', onClick: () => { window.location.href = `/van-ban-di/${record.id}`; } },
  ...(canEdit ? [{ key: 'edit', icon: <EditOutlined />, label: 'Sửa', onClick: () => openDrawer(record) }] : []),
  ...(canApprove ? [{ key: 'approve', icon: <CheckCircleOutlined />, label: 'Duyệt', onClick: () => handleApprove(record) }] : []),
  ...(canReject ? [{ key: 'reject', icon: <StopOutlined />, label: 'Từ chối', danger: true, onClick: () => handleReject(record) }] : []),
  ...(canUnapprove ? [{ key: 'unapprove', icon: <CloseCircleOutlined />, label: 'Hủy duyệt', onClick: () => handleUnapprove(record) }] : []),
  ...(canRetract ? [{ key: 'retract', icon: <RollbackOutlined />, label: 'Thu hồi', onClick: () => handleRetract(record) }] : []),
  ...(canDelete ? [
    { type: 'divider' as const },
    { key: 'delete', icon: <DeleteOutlined />, label: 'Xóa', danger: true, onClick: () => handleDelete(record) },
  ] : []),
];
```

### Phần B: `[id]/page.tsx` (detail)

1. **Thêm `permissions?:`** vào interface DocDetail.

2. **Gate từng button** (grep pattern hiện tại ở dòng 430-470):

Mapping (VB đi có nhiều flow):
- Duyệt: `!doc.approved && perms.canApprove`
- Từ chối: `!doc.approved && !rejected_by && perms.canApprove`
- Hủy duyệt: `doc.approved && !is_released && perms.canApprove`
- Ban hành (release): `doc.approved && !is_released && perms.canRelease`
- Ban hành & Gửi: `doc.approved && !is_released && perms.canRelease && perms.canSend`
- Gửi (handleSendDirect, handleSend): `doc.approved && is_released && perms.canSend` HOẶC nếu UX hiện tại cho gửi khi chưa release thì chỉ `perms.canSend`
- Gửi nội bộ (handleSendNoiBo): `perms.canSend`
- Gửi liên thông LGSP: `perms.canSend`
- Gửi trục CP: `perms.canSend`
- Thu hồi: `recipients.length > 0 && perms.canRetract`
- Sửa (Edit button nếu có): `!doc.approved && perms.canEdit`
- Xóa: `!doc.approved && perms.canEdit`

**Pattern áp:**
```typescript
{doc && !doc.approved && (doc.permissions?.canApprove ?? false) && (
  <Button type="primary" icon={<CheckCircleOutlined />} onClick={handleApprove}>Duyệt</Button>
)}
```

**CHÚ Ý Dropdown:** Các action trong Dropdown menu (dòng 448 `items: [{ key: 'unapprove', ... }]` và dòng 458 `recipients.length > 0 ? [{ key: 'retract', ... }] : []`) cần gate tương tự:

```typescript
<Dropdown menu={{ items: [
  ...((doc.permissions?.canApprove ?? false) ? [{ key: 'unapprove', ... }] : []),
] }}>
```

### TS check
```bash
cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | grep "van-ban-di" ; exit 0
```
  </action>
  <verify>
    <automated>cd e_office_app_new/frontend &amp;&amp; npx tsc --noEmit 2>&amp;1 | grep "van-ban-di" ; exit 0</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "permissions?:" e_office_app_new/frontend/src/app/\(main\)/van-ban-di/page.tsx` ≥ 1
    - `grep -c "permissions?:" e_office_app_new/frontend/src/app/\(main\)/van-ban-di/\[id\]/page.tsx` ≥ 1
    - `grep -cE "perms\?\.(canEdit|canApprove|canRelease|canSend|canRetract)" e_office_app_new/frontend/src/app/\(main\)/van-ban-di/page.tsx` ≥ 5
    - `grep -cE "doc\.permissions\?\.(canEdit|canApprove|canRelease|canSend|canRetract)|doc\?\.permissions\?" e_office_app_new/frontend/src/app/\(main\)/van-ban-di/\[id\]/page.tsx` ≥ 6
    - Status gates giữ nguyên: `grep -cE "(is_released|approved|rejected_by)" e_office_app_new/frontend/src/app/\(main\)/van-ban-di/\[id\]/page.tsx` ≥ 5
    - TS frontend 0 new errors
  </acceptance_criteria>
  <done>VB đi list + detail render có điều kiện theo permissions, giữ status gate.</done>
</task>

<task type="auto">
  <name>Task 8: Smoke test matrix — backend curl + DB setup</name>
  <files>
    - (test thủ công, không tạo file)
  </files>
  <read_first>
    - docker-compose.yml hoặc docker ps để confirm container name postgres
  </read_first>
  <action>
Smoke test matrix bằng curl để verify guard + enrich hoạt động.

### Chuẩn bị: Login lấy token

```bash
# Admin
ADMIN_TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin@123"}' | jq -r '.data.token')

# User cùng unit với VB test (ví dụ nguyenvana — Sở Nội vụ)
USER1_TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"nguyenvana","password":"Admin@123"}' | jq -r '.data.token')

# User khác unit (tranthib — Sở Tài chính)
USER2_TOKEN=$(curl -s -X POST http://localhost:4000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"tranthib","password":"Admin@123"}' | jq -r '.data.token')
```

### Lấy 1 VB đến + 1 VB đi để test

```bash
# Admin lấy list để có id test
curl -s http://localhost:4000/api/van-ban-den?page=1\&page_size=5 \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.data[0] | {id, unit_id, approved, permissions}'
# Lưu INCOMING_ID + INCOMING_UNIT_ID

curl -s http://localhost:4000/api/van-ban-di?page=1\&page_size=5 \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.data[0] | {id, unit_id, approved, is_released, permissions}'
# Lưu OUTGOING_ID
```

### Test matrix

| # | Token | Endpoint | Expected |
|---|-------|----------|----------|
| 1 | ADMIN | GET /api/van-ban-den | Mỗi row có `permissions: {canEdit:true, canApprove:true, canRelease:true, canSend:true, canRetract:true}` |
| 2 | USER2 (khác unit) | GET /api/van-ban-den/$INCOMING_ID | `data.permissions.canEdit === false`, `canApprove === false`, `canSend === false` |
| 3 | USER2 (khác unit) | PATCH /api/van-ban-den/$INCOMING_ID/duyet | HTTP 403 + message "Không có quyền duyệt..." |
| 4 | USER2 (khác unit) | POST /api/van-ban-den/$INCOMING_ID/gui -d '{"staff_ids":[1]}' | HTTP 403 |
| 5 | USER2 (khác unit) | POST /api/van-ban-den/$INCOMING_ID/thu-hoi | HTTP 403 + message "Không có quyền thu hồi..." |
| 6 | ADMIN | GET /api/van-ban-di | Mỗi row có `permissions: {canRelease:true, ...}` tất cả true |
| 7 | USER2 (khác unit) | PATCH /api/van-ban-di/$OUTGOING_ID/ban-hanh | HTTP 403 + message "Không có quyền ban hành..." |
| 8 | USER2 (khác unit) | PATCH /api/van-ban-di/$OUTGOING_ID/duyet | HTTP 403 |
| 9 | USER2 (khác unit) | POST /api/van-ban-di/$OUTGOING_ID/gui -d '{"staff_ids":[1]}' | HTTP 403 |
| 10 | USER2 (khác unit) | POST /api/van-ban-di/$OUTGOING_ID/noi-nhan -d '{"recipients":[]}' | HTTP 403 (canRelease guard) |

### Commands cụ thể

```bash
# Test 1
curl -s http://localhost:4000/api/van-ban-den?page=1\&page_size=3 \
  -H "Authorization: Bearer $ADMIN_TOKEN" | jq '.data[0].permissions'
# Expect: {"canEdit":true,"canApprove":true,"canRelease":true,"canSend":true,"canRetract":true}

# Test 3
curl -s -w "\nHTTP %{http_code}\n" -X PATCH http://localhost:4000/api/van-ban-den/$INCOMING_ID/duyet \
  -H "Authorization: Bearer $USER2_TOKEN"
# Expect: HTTP 403 + {"success":false,"message":"Không có quyền duyệt văn bản đến này"}

# Test 7
curl -s -w "\nHTTP %{http_code}\n" -X PATCH http://localhost:4000/api/van-ban-di/$OUTGOING_ID/ban-hanh \
  -H "Authorization: Bearer $USER2_TOKEN"
# Expect: HTTP 403 + {"success":false,"message":"Không có quyền ban hành văn bản đi này"}

# Test 9
curl -s -w "\nHTTP %{http_code}\n" -X POST http://localhost:4000/api/van-ban-di/$OUTGOING_ID/gui \
  -H "Authorization: Bearer $USER2_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"staff_ids":[1]}'
# Expect: HTTP 403
```

### Happy-path test (admin thành công)

```bash
# Admin approve (nếu chưa approved)
curl -s -X PATCH http://localhost:4000/api/van-ban-di/$OUTGOING_ID/duyet \
  -H "Authorization: Bearer $ADMIN_TOKEN"
# Expect: 200 + success:true (hoặc 400 nếu đã approved — OK)
```

### Pass criteria

**ALL must pass:**
- Test 1, 6: admin có `permissions` tất cả true
- Test 2: user khác unit có `permissions.canEdit/canApprove/canSend/canRetract` = false (canRelease có thể true/false — tùy rule, VB đến không quan tâm)
- Test 3, 4, 5, 7, 8, 9, 10: HTTP 403 với message tiếng Việt đúng

### Ghi nhận kết quả

Print bảng kết quả ra terminal hoặc log vào `.planning/quick/260424-wve-permission-v2-vb-den-vb-di-apply-pattern/SMOKE-RESULT.txt` (file text plain, không phải md):

```
Test 1: [PASS|FAIL] — <1-line note>
Test 2: ...
...
```

Nếu 1 test FAIL → dừng, report lỗi + hỏi user (không tự fix).
  </action>
  <verify>
    <automated>curl -s http://localhost:4000/api/health 2>/dev/null | grep -q '"ok":true' &amp;&amp; echo "backend up" || echo "backend DOWN — start backend trước"</automated>
  </verify>
  <acceptance_criteria>
    - Backend Express đang chạy port 4000 (curl health OK)
    - 10 test trong matrix chạy xong, ≥ 10/10 PASS
    - File `SMOKE-RESULT.txt` tạo trong plan dir với kết quả từng test
    - Không có response 500 (server error) — nếu có phải dừng và debug
  </acceptance_criteria>
  <done>Permission v2 hoạt động đúng ở VB đến + VB đi: admin full, user khác unit 403, user cùng unit tùy flag. Kết quả ghi vào SMOKE-RESULT.txt.</done>
</task>

</tasks>

<verification>

## Wave structure (4 waves)

- **Wave 1 — Backend helpers (sequential Task 1 → parallel Tasks 2+3):**
  - Task 1: Refactor `_shared.ts` + drafting wrap (BLOCKING — Task 2 & 3 đều depend on _shared.ts)
  - Task 2 + Task 3: Có thể parallel (khác file, đều depend on _shared.ts)

  **Note:** Task 2 & 3 run tuần tự nếu risk lo ngại (đơn giản — mỗi task chỉ tạo 1 file ~40 dòng). Planner khuyến nghị: Task 1 xong → chạy Task 2 + Task 3 parallel.

- **Wave 2 — Routes (parallel Tasks 4+5):**
  - Task 4 + Task 5: Khác file, khác helper. Parallel OK.
  - Integration check sau Wave 2: Run `cd e_office_app_new/backend && npm run dev` → start không lỗi + admin login + GET /van-ban-den trả permissions.

- **Wave 3 — Frontend (parallel Tasks 6+7):**
  - Task 6 + Task 7: Khác file. Parallel OK.
  - Integration check: Run `cd e_office_app_new/frontend && npm run dev` → build OK + mở VB đến list, thấy permissions trong dev console (network tab).

- **Wave 4 — Smoke test (Task 8):**
  - Backend phải đang chạy. Curl matrix.

## Post-plan checks

```bash
# Backend TS
cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | grep -E "(permissions|routes/incoming-doc|routes/outgoing-doc)" | head -20
# Expect: 0 new errors

# Frontend TS
cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | grep -E "van-ban-(den|di)" | head -20
# Expect: 0 new errors

# SP không bị ảnh hưởng (task này KHÔNG đụng DB)
# → skip DB check

# File count verify
ls -la e_office_app_new/backend/src/lib/permissions/
# Expect: _shared.ts, drafting-doc.ts, incoming-doc.ts, outgoing-doc.ts (4 files)
```

## Integration verify (sau Wave 4)

1. Start backend + frontend (hoặc user confirm đã chạy)
2. Login admin → mở VB đến list → verify dropdown có đủ actions (admin thấy hết)
3. Login nguyenvana (Sở Nội vụ) → mở VB đến của Sở khác → verify dropdown CHỈ có "Xem chi tiết" (không thấy Sửa/Duyệt/Xóa)
4. Login admin → VB đi đã approved → verify nút "Ban hành" hiển thị
5. Login tranthib (Sở Tài chính) → VB đi của Sở Nội vụ → verify KHÔNG thấy nút Ban hành/Duyệt/Hủy duyệt/Thu hồi

</verification>

<success_criteria>

- [ ] 4 file mới tạo: `_shared.ts`, `incoming-doc.ts`, `outgoing-doc.ts` (permission helpers) + smoke result
- [ ] `drafting-doc.ts` refactor wrap `_shared.ts`, backward-compat 100% (route drafting-doc.ts không cần sửa import)
- [ ] Route `incoming-doc.ts`: ≥ 9 mutation endpoints guard 403 + GET list batch enrich + GET detail enrich
- [ ] Route `outgoing-doc.ts`: ≥ 15 mutation endpoints guard 403 + GET list batch enrich + GET detail enrich
- [ ] Frontend 4 file gate UI theo permissions, giữ status gate hiện có (approved/is_released/source_type/rejected_by)
- [ ] TypeScript backend + frontend: 0 new errors sau toàn bộ plan
- [ ] Smoke test 10/10 PASS: admin full, user khác unit 403 ở mutation, enrich permissions hoạt động
- [ ] KHÔNG tự git commit (chờ user yêu cầu)
- [ ] Rules permission không hard-code role name — chỉ flag + ownership + admin (verify: `grep -nE "role\s*===\s*'|role\s*==\s*\"" e_office_app_new/backend/src/lib/permissions/` = 0 match)

</success_criteria>

<output>
Sau khi execute xong, tạo summary tại:
`.planning/quick/260424-wve-permission-v2-vb-den-vb-di-apply-pattern/SUMMARY.md` (chỉ sau khi user yêu cầu commit).

Smoke result text file:
`.planning/quick/260424-wve-permission-v2-vb-den-vb-di-apply-pattern/SMOKE-RESULT.txt` (tạo ở Task 8).
</output>
