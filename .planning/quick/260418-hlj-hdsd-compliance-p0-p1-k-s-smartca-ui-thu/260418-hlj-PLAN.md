---
phase: quick-260418-hlj
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
requirements: [HDSD-I.4, HDSD-2.3, HDSD-3.1, HDSD-3.2]
files_modified:
  # Task 1 — Gap 1 SmartCA UI
  - e_office_app_new/database/migrations/quick_260418_hlj_signature.sql
  - e_office_app_new/backend/src/routes/profile.ts
  - e_office_app_new/backend/src/repositories/profile.repository.ts
  - e_office_app_new/backend/src/server.ts
  - e_office_app_new/backend/src/services/auth.service.ts
  - e_office_app_new/frontend/src/stores/auth.store.ts
  - e_office_app_new/frontend/src/app/(main)/thong-tin-ca-nhan/page.tsx

  # Task 2 — Gap 2 Thu hồi VB liên thông
  - e_office_app_new/database/migrations/quick_260418_hlj_recall.sql
  - e_office_app_new/backend/src/repositories/inter-incoming.repository.ts
  - e_office_app_new/backend/src/routes/inter-incoming.ts
  - e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/[id]/page.tsx
  - e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/page.tsx

  # Task 3 — Gap 3 HSCV Mở lại + Lấy số
  - e_office_app_new/database/migrations/quick_260418_hlj_hscv.sql
  - e_office_app_new/backend/src/repositories/handling-doc.repository.ts
  - e_office_app_new/backend/src/routes/handling-doc.ts
  - e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx

must_haves:
  truths:
    # Gap 1
    - "User authenticated bất kỳ (không cần admin) có thể mở /thong-tin-ca-nhan và thấy section Chữ ký số"
    - "User upload được file PNG (≤2MB) → backend lưu MinIO → DB cột sign_image set thành path mới"
    - "User nhập sign_phone (số điện thoại SmartCA) → Lưu → backend update sign_phone trong DB"
    - "Sau Lưu, gọi /auth/me trả về sign_phone và sign_image (presigned URL) — store cập nhật"
    - "User thấy preview ảnh chữ ký nếu đã có sign_image"

    # Gap 2
    - "Khi inter_incoming_docs.status='recall_requested', detail page hiện 2 nút 'Đồng ý thu hồi' + 'Từ chối thu hồi'"
    - "Bấm 'Đồng ý thu hồi' → Modal.confirm → backend đổi status='recalled' VÀ soft-delete incoming_docs liên kết (is_deleted=TRUE, deleted_at=NOW(), deleted_by=user_id)"
    - "Bấm 'Từ chối thu hồi' → Modal nhập lý do bắt buộc → backend restore status về status_before_recall (COALESCE 'received') + lưu recall_response"
    - "Detail page gọi fn_inter_incoming_get_by_id trả về 5 field recall_* để hiển thị lý do/thời điểm yêu cầu/phản hồi"
    - "List page filter trạng thái có option 'Đang yêu cầu thu hồi' và STATUS_MAP render đúng tag"
    - "Sau action, page reload và hiển thị status mới"

    # Gap 3
    - "Khi handling_docs.status=4 (Hoàn thành), detail page hiện nút 'Mở lại'"
    - "Bấm 'Mở lại' → Popconfirm → backend đổi status=1 + GIỮ NGUYÊN progress=100 + ghi log action"
    - "Khi status=1 và number IS NULL, detail page hiện nút 'Lấy số'"
    - "Bấm 'Lấy số' → nếu chưa có doc_book_id thì mở Modal Select sổ → backend tính MAX(number)+1 theo năm created_at + doc_book_id → UPDATE row"
    - "Sau lấy số, hiển thị message success kèm số mới và detail refresh hiển thị number + doc_book_name (JOIN doc_books)"
    - "fn_handling_doc_get_by_id trả về 5 field: number, sub_number, notation, doc_book_id, doc_book_name"

  artifacts:
    # Gap 1
    - path: e_office_app_new/database/migrations/quick_260418_hlj_signature.sql
      provides: "SP public.fn_staff_update_signature(p_id, p_sign_phone, p_sign_ca, p_sign_image)"
      contains: "CREATE OR REPLACE FUNCTION public.fn_staff_update_signature"
    - path: e_office_app_new/backend/src/routes/profile.ts
      provides: "Routes /api/ho-so-ca-nhan/chu-ky-so (PATCH text), /anh-chu-ky (POST upload + GET presigned)"
      exports: ["default"]
    - path: e_office_app_new/backend/src/repositories/profile.repository.ts
      provides: "profileRepository.updateSignature()"
    - path: e_office_app_new/frontend/src/app/(main)/thong-tin-ca-nhan/page.tsx
      provides: "UI section Chữ ký số: Upload PNG + Input sign_phone + Save"
      contains: "Tài khoản ký số"

    # Gap 2
    - path: e_office_app_new/database/migrations/quick_260418_hlj_recall.sql
      provides: "ALTER TABLE inter_incoming_docs (recall_* + status_before_recall) + ALTER TABLE incoming_docs (is_deleted/deleted_at/deleted_by NẾU THIẾU) + 3 SP recall_approve/reject/get_by_id"
      contains: "fn_inter_incoming_recall_approve"
    - path: e_office_app_new/backend/src/routes/inter-incoming.ts
      provides: "POST /:id/dong-y-thu-hoi + POST /:id/tu-choi-thu-hoi"
    - path: e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/[id]/page.tsx
      provides: "2 button conditional render khi status='recall_requested' + Modal lý do từ chối"

    # Gap 3
    - path: e_office_app_new/database/migrations/quick_260418_hlj_hscv.sql
      provides: "SP fn_handling_doc_reopen + fn_handling_doc_get_next_number + fn_handling_doc_assign_number + fn_handling_doc_get_by_id (JOIN doc_books)"
      contains: "fn_handling_doc_reopen"
    - path: e_office_app_new/backend/src/routes/handling-doc.ts
      provides: "POST /ho-so-cong-viec/:id/mo-lai + POST /:id/lay-so"
    - path: e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx
      provides: "Toolbar buttons 'Mở lại' (status=4) + 'Lấy số' (status=1, number=null) + Modal Select sổ"

  key_links:
    - from: "frontend thong-tin-ca-nhan/page.tsx"
      to: "/api/ho-so-ca-nhan/chu-ky-so + /anh-chu-ky"
      via: "axios PATCH/POST"
      pattern: "api\\.(patch|post)\\(['\"]/ho-so-ca-nhan"
    - from: "backend routes/profile.ts"
      to: "public.fn_staff_update_signature"
      via: "callFunctionOne"
      pattern: "fn_staff_update_signature"
    - from: "frontend van-ban-lien-thong/[id]/page.tsx"
      to: "/api/van-ban-lien-thong/:id/dong-y-thu-hoi + /tu-choi-thu-hoi"
      via: "axios POST"
      pattern: "(dong-y-thu-hoi|tu-choi-thu-hoi)"
    - from: "edoc.fn_inter_incoming_recall_approve"
      to: "edoc.incoming_docs (soft-delete)"
      via: "UPDATE SET is_deleted=TRUE WHERE is_inter_doc=TRUE AND inter_doc_id=p_id"
      pattern: "UPDATE edoc\\.incoming_docs SET is_deleted"
    - from: "edoc.fn_inter_incoming_recall_reject"
      to: "edoc.inter_incoming_docs (restore status)"
      via: "UPDATE SET status = COALESCE(status_before_recall, 'received')"
      pattern: "COALESCE\\(status_before_recall"
    - from: "frontend ho-so-cong-viec/[id]/page.tsx"
      to: "/api/ho-so-cong-viec/:id/mo-lai + /lay-so"
      via: "axios POST"
      pattern: "(/mo-lai|/lay-so)"
    - from: "edoc.fn_handling_doc_assign_number"
      to: "edoc.handling_docs.number"
      via: "UPDATE SET number = MAX+1 theo năm created_at + doc_book_id"
      pattern: "EXTRACT\\(YEAR FROM created_at\\)"
---

<objective>
Hoàn thành 3 gap HDSD compliance trước demo:
- **Gap 1 (P0)** — Profile page bổ sung UI upload chữ ký số (PNG) + nhập tài khoản SmartCA (`sign_phone`).
- **Gap 2 (P1)** — Detail VB liên thông bổ sung 2 action "Đồng ý / Từ chối thu hồi" với soft-delete VB đến liên kết khi đồng ý.
- **Gap 3 (P1)** — Detail HSCV bổ sung "Mở lại" (status 4→1, giữ progress=100) và "Lấy số" (MAX(number)+1 theo năm + sổ).

Purpose: thay vì 3 quick task riêng, gom 1 PLAN với 3 task TUẦN TỰ vì share migration approach + commit riêng từng task.
Output: 3 commit độc lập (mỗi task 1 commit) — feature ready cho demo cuối tuần 2026-04-18/19.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@CLAUDE.md
@e_office_app_new/frontend/CLAUDE.md
@e_office_app_new/frontend/AGENTS.md
@.planning/quick/260418-hlj-hdsd-compliance-p0-p1-k-s-smartca-ui-thu/260418-hlj-RESEARCH.md
@e_office_app_new/backend/src/server.ts
@e_office_app_new/backend/src/middleware/upload.ts
@e_office_app_new/backend/src/middleware/auth.ts
@e_office_app_new/backend/src/lib/db/pool.ts
@e_office_app_new/backend/src/lib/minio/client.ts
@e_office_app_new/backend/src/services/auth.service.ts
@e_office_app_new/backend/src/repositories/auth.repository.ts
@e_office_app_new/backend/src/routes/inter-incoming.ts
@e_office_app_new/backend/src/repositories/inter-incoming.repository.ts
@e_office_app_new/backend/src/routes/handling-doc.ts
@e_office_app_new/backend/src/repositories/handling-doc.repository.ts
@e_office_app_new/frontend/src/lib/api.ts
@e_office_app_new/frontend/src/stores/auth.store.ts
@e_office_app_new/frontend/src/app/(main)/thong-tin-ca-nhan/page.tsx
@e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/page.tsx
@e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/[id]/page.tsx
@e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx

<critical_constraints>
- AntD 6: Drawer dùng `size={720}` (không `width`). Modal OK.
- Reserved words trong PostgreSQL phải quote bằng `""`: `"position"`, `"offset"`, `"limit"`, `"order"`, `"user"`, `"type"`, `"name"`, `"value"`. Trong task này: `number`, `status`, `recall_*`, `sign_*` — KHÔNG reserved, OK.
- SP trả đúng tên cột DB (snake_case), KHÔNG alias rename.
- Migration phải chạy ngay vào DB bằng `docker exec qlvb_postgres psql -U postgres -d qlvb -f ...` rồi verify SP hoạt động.
- Type-check sau mỗi task: `cd e_office_app_new/backend && npx tsc --noEmit` + `cd e_office_app_new/frontend && npx tsc --noEmit`.
- Field name SP ↔ repo Row interface ↔ FE field PHẢI khớp (CLAUDE.md hard-learned).
- maxLength khớp DB VARCHAR: `sign_phone VARCHAR(20)` → `<Input maxLength={20}>`; `sign_image VARCHAR(500)`.
- Data type: `sign_phone VARCHAR` → FE `<Input>` KHÔNG `<InputNumber>`. `handling_docs.number INTEGER` → `<InputNumber>` (nhưng read-only display).
- Required validation: NOT NULL columns → Form.Item rules required. Reason khi "Từ chối thu hồi" bắt buộc.
- Format validation: sign_phone pattern `^[0-9+\-\s()]*$`.
- Authorization: profile routes mount `/api/ho-so-ca-nhan` với CHỈ `authenticate`, KHÔNG `requireRoles` (mọi user dùng được).
- **ID type rule (HARD-LEARNED)**: `handling_docs.id` và `inter_incoming_docs.id` là **BIGSERIAL** → SP parameters PHẢI là `p_id BIGINT`, KHÔNG `INT`. `doc_books.id` là `SERIAL` (INT) → `p_doc_book_id INT` OK. `staff.id` là `INT` → `p_user_id INT` OK.
- KHÔNG commit tự động. Commit từng task khi user xác nhận hoặc khi task hoàn tất theo commit message đã chỉ định.
- Locked decisions: A1 SOFT-DELETE incoming_docs (không hard), A2 giữ progress=100 khi reopen, A3 reset số theo năm `created_at`, A4 dùng `sign_phone` cho SmartCA.
</critical_constraints>

<interfaces>
<!-- Key types/contracts từ codebase — executor dùng trực tiếp, không cần explore -->
<!-- REVISED v2: fixed uploadFile/getFileUrl signatures + upload middleware name -->

From e_office_app_new/backend/src/lib/db/pool.ts (function helpers):
```typescript
export async function callFunction<T>(name: string, params: unknown[]): Promise<T[]>;
export async function callFunctionOne<T>(name: string, params: unknown[]): Promise<T | null>;
export async function rawQuery<T>(sql: string, params?: unknown[]): Promise<T[]>;
export async function withTransaction<T>(callback: (client: PoolClient) => Promise<T>): Promise<T>;
```

From e_office_app_new/backend/src/middleware/auth.ts:
```typescript
export interface AuthRequest extends Request {
  user?: { staffId: number; unitId: number; departmentId: number; roles: string[]; ... };
}
export const authenticate: RequestHandler;
export const requireRoles: (...roles: string[]) => RequestHandler;
```

From e_office_app_new/backend/src/middleware/upload.ts — VERIFIED signatures:
```typescript
// EXACT export name is `upload`, NOT `uploadMemory`
export const upload: multer.Multer; // memoryStorage, limit MAX_FILE_SIZE (default 50MB)
// Use: router.post('/x', upload.single('file'), handler) → req.file: Express.Multer.File
// Import: import { upload } from '../middleware/upload.js';
```

From e_office_app_new/backend/src/lib/minio/client.ts — VERIFIED signatures:
```typescript
// Bucket is FIXED in ENV (MINIO_BUCKET, default 'documents') — NOT a function parameter.

export async function uploadFile(
  path: string,
  buffer: Buffer,
  contentType: string
): Promise<string>;
// Usage: await uploadFile(key, req.file.buffer, 'image/png');
// Returns the path (same as input `path` arg).

export async function getFileUrl(
  path: string,
  expirySeconds?: number       // default 3600
): Promise<string>;
// Usage: const url = await getFileUrl(signImage, 3600);

export async function deleteFile(path: string): Promise<void>;
// Usage: await deleteFile(oldKey);
```

From e_office_app_new/backend/src/services/auth.service.ts (cần update):
```typescript
// Hiện tại fn_auth_me trả về UserInfo cơ bản
// Phải bổ sung sign_phone, sign_image (nếu chưa có) vào response
```

From e_office_app_new/frontend/src/stores/auth.store.ts:
```typescript
export interface UserInfo {
  id: number; username: string; full_name: string; email?: string;
  unit_id: number; department_id: number; roles: string[];
  // CẦN THÊM: sign_phone?: string | null; sign_image?: string | null; sign_image_url?: string | null;
}
export const useAuthStore: ZustandStore;
// Methods: setUser, fetchMe, logout
```

From e_office_app_new/frontend/src/lib/api.ts:
```typescript
export const api: AxiosInstance; // baseURL: /api, withCredentials: true, JWT auto-attached
```

DB schema verified (theo RESEARCH.md + 000_full_schema.sql):

public.staff (Gap 1) — ĐÃ CÓ ĐỦ CỘT, KHÔNG CẦN ALTER:
  - id INT (SERIAL)
  - sign_phone VARCHAR(20)
  - sign_ca TEXT
  - sign_image VARCHAR(500)

edoc.inter_incoming_docs (Gap 2) — id là BIGSERIAL → p_id BIGINT:
  - id BIGSERIAL (BIGINT)
  - status VARCHAR(50) — đã có (pending/received/completed/returned). Thêm 2 enum string mới: 'recall_requested', 'recalled'
  - recall_reason TEXT (NULL) — CẦN ALTER ADD
  - recall_requested_at TIMESTAMPTZ (NULL) — CẦN ALTER ADD
  - recall_response TEXT (NULL) — CẦN ALTER ADD
  - recall_responded_by INT (NULL) — CẦN ALTER ADD
  - recall_responded_at TIMESTAMPTZ (NULL) — CẦN ALTER ADD
  - status_before_recall VARCHAR(50) (NULL) — CẦN ALTER ADD (MỚI — lưu status cũ để restore khi reject)

edoc.incoming_docs (Gap 2 cascade) — VERIFY trước khi viết SP:
  - Phải kiểm tra `\d edoc.incoming_docs` xem có sẵn `is_deleted/deleted_at/deleted_by` chưa.
  - Nếu THIẾU → migration thêm 3 cột:
    `ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE NOT NULL,
     ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
     ADD COLUMN IF NOT EXISTS deleted_by INT;`
  - Cũng phải kiểm tra cột `is_inter_doc BOOLEAN`, `inter_doc_id BIGINT` để filter cascade.

edoc.handling_docs (Gap 3) — id là BIGSERIAL → p_id BIGINT:
  - id BIGSERIAL (BIGINT)
  - status SMALLINT (0=Nháp, 1=Đang xử lý, 2=Trình ký, 3=Đã duyệt, 4=Hoàn thành, ...)
  - number INT (NULL nếu chưa lấy số)
  - sub_number VARCHAR(20) (NULL)
  - notation VARCHAR(100) (NULL) — a.k.a. doc_notation trong schema (verify cột chính xác)
  - doc_book_id INT (NULL) — FK đến edoc.doc_books(id) [SERIAL = INT]
  - created_at TIMESTAMPTZ (luôn có)
  - unit_id INT
  - progress SMALLINT (0-100)
  - complete_date TIMESTAMPTZ (NULL)
  - complete_user_id INT (NULL)

edoc.doc_books (Gap 3 JOIN) — id là SERIAL (INT):
  - id SERIAL (INT) → p_doc_book_id INT OK
  - name VARCHAR(200) NOT NULL
  - unit_id INT NOT NULL
  - type_id SMALLINT NOT NULL
  - is_deleted BOOLEAN

Reference SP patterns (đọc trước khi viết SP mới):
  - public.fn_staff_update_avatar (~ line tương tự fn_staff_update_signature) — pattern UPDATE 1 cột.
  - edoc.fn_outgoing_doc_get_next_number (line 6038 in 000_full_schema.sql) — pattern lấy số.
  - edoc.fn_inter_incoming_return (line 8947) — pattern action change status với reason.
  - edoc.fn_handling_doc_complete (line 7806) — pattern HSCV change status.
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Gap 1 — Ký số SmartCA UI (DB SP + Backend route + FE Profile section)</name>
  <files>
    e_office_app_new/database/migrations/quick_260418_hlj_signature.sql,
    e_office_app_new/backend/src/repositories/profile.repository.ts,
    e_office_app_new/backend/src/routes/profile.ts,
    e_office_app_new/backend/src/server.ts,
    e_office_app_new/backend/src/services/auth.service.ts,
    e_office_app_new/frontend/src/stores/auth.store.ts,
    e_office_app_new/frontend/src/app/(main)/thong-tin-ca-nhan/page.tsx
  </files>
  <action>
    **Wave 1 — DB (per A4: dùng `sign_phone` cho SmartCA):**

    1. Tạo file `e_office_app_new/database/migrations/quick_260418_hlj_signature.sql`:
       ```sql
       -- Verify cột tồn tại (chỉ comment, không cần ALTER vì RESEARCH.md đã verify)
       -- public.staff đã có: sign_phone VARCHAR(20), sign_ca TEXT, sign_image VARCHAR(500)
       -- public.staff.id là SERIAL (INT) → p_id INT đúng.

       CREATE OR REPLACE FUNCTION public.fn_staff_update_signature(
           p_id INT,
           p_sign_phone VARCHAR DEFAULT NULL,
           p_sign_ca TEXT DEFAULT NULL,
           p_sign_image VARCHAR DEFAULT NULL
       )
       RETURNS TABLE(success BOOLEAN, message TEXT)
       LANGUAGE plpgsql
       SECURITY DEFINER
       AS $$
       BEGIN
           IF NOT EXISTS (SELECT 1 FROM public.staff WHERE id = p_id) THEN
               RETURN QUERY SELECT FALSE, 'Không tìm thấy nhân viên'::TEXT;
               RETURN;
           END IF;

           UPDATE public.staff
           SET sign_phone = COALESCE(p_sign_phone, sign_phone),
               sign_ca = COALESCE(p_sign_ca, sign_ca),
               sign_image = COALESCE(p_sign_image, sign_image),
               updated_at = NOW()
           WHERE id = p_id;

           RETURN QUERY SELECT TRUE, 'Cập nhật chữ ký số thành công'::TEXT;
       END;
       $$;
       ```
    2. Chạy migration vào DB:
       ```bash
       docker cp e_office_app_new/database/migrations/quick_260418_hlj_signature.sql qlvb_postgres:/tmp/
       docker exec qlvb_postgres psql -U postgres -d qlvb -f /tmp/quick_260418_hlj_signature.sql
       ```
    3. Test SP:
       ```bash
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT * FROM public.fn_staff_update_signature(1, '84813789393', NULL, NULL);"
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT id, sign_phone, sign_image FROM public.staff WHERE id = 1;"
       ```

    **Wave 2 — Backend:**

    4. Tạo `e_office_app_new/backend/src/repositories/profile.repository.ts`:
       ```typescript
       import { callFunctionOne } from '../lib/db/pool.js';

       export interface UpdateSignatureResult {
         success: boolean;
         message: string;
       }

       export const profileRepository = {
         async updateSignature(staffId: number, signPhone: string | null, signCa: string | null, signImage: string | null): Promise<UpdateSignatureResult | null> {
           return callFunctionOne<UpdateSignatureResult>('public.fn_staff_update_signature', [staffId, signPhone, signCa, signImage]);
         },
       };
       ```
    5. Tạo `e_office_app_new/backend/src/routes/profile.ts`:
       - **Imports (VERIFIED exact signatures):**
         ```typescript
         import { Router, Response, NextFunction } from 'express';
         import { randomUUID } from 'node:crypto';
         import { authenticate, type AuthRequest } from '../middleware/auth.js';
         import { upload } from '../middleware/upload.js';          // NOT `uploadMemory`
         import { uploadFile, getFileUrl } from '../lib/minio/client.js';
         import { profileRepository } from '../repositories/profile.repository.js';
         import { rawQuery } from '../lib/db/pool.js';
         ```
       - Mount handler `authenticate` cho TẤT CẢ routes.
       - `PATCH /chu-ky-so` body `{ sign_phone?: string; sign_ca?: string }`:
         - Validate `sign_phone` nếu có: type string, maxLength 20, pattern `^[0-9+\-\s()]*$`. Trả 400 nếu invalid.
         - `staffId = req.user!.staffId`. Gọi `profileRepository.updateSignature(staffId, sign_phone || null, sign_ca || null, null)`.
         - Trả `{ success, message }` từ SP.
       - `POST /anh-chu-ky` middleware `upload.single('file')`:
         - Validate `req.file` exists, `req.file.mimetype === 'image/png'`, `req.file.size <= 2 * 1024 * 1024`. Trả 400 nếu không hợp lệ ("Chỉ chấp nhận file PNG ≤ 2MB").
         - `const key = \`signatures/${req.user!.staffId}/${randomUUID()}.png\`;`
         - **`await uploadFile(key, req.file.buffer, 'image/png');`** — 3 args, KHÔNG bucket arg (bucket cố định trong ENV).
         - Gọi `profileRepository.updateSignature(staffId, null, null, key)`.
         - Trả `{ success, message, sign_image: key }`.
       - `GET /anh-chu-ky` (presigned URL cho preview):
         - Lấy `sign_image` từ DB: `const rows = await rawQuery<{ sign_image: string | null }>('SELECT sign_image FROM public.staff WHERE id = $1', [req.user!.staffId]);`
         - Nếu `sign_image` null → trả `{ url: null }`.
         - **Else: `const url = await getFileUrl(rows[0].sign_image, 3600);`** — 2 args (path, expirySeconds), KHÔNG bucket arg. Trả `{ url }`.
       - `export default router`.
    6. Mount trong `e_office_app_new/backend/src/server.ts`:
       - Thêm `import profileRoutes from './routes/profile.js';`
       - Thêm `app.use('/api/ho-so-ca-nhan', authenticate, profileRoutes);` ở vị trí phù hợp (sau `/api/auth`, trước `/api/quan-tri`).
       - **KHÔNG mount dưới `/api/quan-tri`** để tránh `requireRoles` (per RESEARCH.md pitfall).
    7. Update `e_office_app_new/backend/src/services/auth.service.ts`:
       - Tìm hàm `me()` hoặc tương đương trả về UserInfo.
       - Đảm bảo response include `sign_phone` và `sign_image` (nếu sign_image có giá trị → **gọi `getFileUrl(sign_image, 3600)`** (2 args) để trả về presigned URL trong field `sign_image_url`, giữ raw path trong `sign_image`).
       - Nếu repository chưa trả 2 field này, query thêm `SELECT sign_phone, sign_image FROM public.staff WHERE id = $1` hoặc bổ sung vào SP `fn_auth_me`.

    **Wave 3 — Frontend:**

    8. Update `e_office_app_new/frontend/src/stores/auth.store.ts`:
       - Mở rộng `UserInfo` interface thêm `sign_phone?: string | null; sign_image?: string | null; sign_image_url?: string | null;`.
       - `fetchMe()` đã set toàn bộ user — giữ nguyên, chỉ cần `/auth/me` trả thêm field.

    9. Update `e_office_app_new/frontend/src/app/(main)/thong-tin-ca-nhan/page.tsx`:
       - **Đọc trước file hiện tại để hiểu layout.** Hiện trang có form đổi mật khẩu — thêm Card mới HOẶC chuyển sang `<Tabs>` với 2 tab: "Đổi mật khẩu" / "Chữ ký số".
       - Khuyến nghị: dùng `<Tabs items={[...]} />` để gọn.
       - Tab "Chữ ký số":
         - `<Form layout="vertical" onFinish={handleSaveSignature}>` với:
           - `<Form.Item label="Tài khoản ký số (SmartCA)" name="sign_phone" rules={[{ pattern: /^[0-9+\-\s()]*$/, message: 'Số điện thoại không hợp lệ' }]}>`
             `<Input maxLength={20} placeholder="Ví dụ: 84813789393" />`
           - `<Form.Item label="Ảnh chữ ký (PNG, khuyến nghị 150×150)">`:
             `<Upload accept=".png,image/png" maxCount={1} beforeUpload={(file) => { ... validate PNG + Image() check 150x150 (warn nếu khác, vẫn cho submit) ...; setSignatureFile(file); return false; }} fileList={signatureFile ? [{ uid: '-1', name: signatureFile.name, status: 'done' }] : []} onRemove={() => setSignatureFile(null)}>`
             `<Button icon={<UploadOutlined />}>Chọn file PNG</Button>`
             `</Upload>`
           - Preview ảnh hiện tại: nếu `user.sign_image_url` có giá trị → `<Avatar shape="square" size={150} src={user.sign_image_url} />` với label "Chữ ký hiện tại".
           - Nút Lưu: `<Button type="primary" htmlType="submit" loading={saving}>Lưu thông tin ký số</Button>`
         - `handleSaveSignature(values)`:
           ```typescript
           setSaving(true);
           try {
             // 1. Upload ảnh trước nếu có file mới
             if (signatureFile) {
               const fd = new FormData();
               fd.append('file', signatureFile);
               await api.post('/ho-so-ca-nhan/anh-chu-ky', fd, { headers: { 'Content-Type': 'multipart/form-data' } });
             }
             // 2. Update sign_phone
             await api.patch('/ho-so-ca-nhan/chu-ky-so', { sign_phone: values.sign_phone || null });
             message.success('Đã lưu. Vui lòng đăng xuất và đăng nhập lại để áp dụng');
             await fetchMe();  // refresh store
             setSignatureFile(null);
           } catch (err: any) {
             message.error(err.response?.data?.message || 'Lưu thất bại');
           } finally {
             setSaving(false);
           }
           ```
       - Pre-fill `initialValues={{ sign_phone: user?.sign_phone || '' }}`.
       - Sau khi lưu thành công, `fetchMe()` đảm bảo `sign_image_url` được refresh (sẽ là presigned URL mới).

    10. Authorization note: `/api/ho-so-ca-nhan/*` chỉ require `authenticate`, mọi user (Văn thư, Lãnh đạo, Cán bộ...) đều dùng được — KHÔNG đặt vào `/quan-tri/*`.

    **Verification sau task:**
    - `cd e_office_app_new/backend && npx tsc --noEmit` → 0 errors.
    - `cd e_office_app_new/frontend && npx tsc --noEmit` → 0 errors.
    - Test manual: login → mở `/thong-tin-ca-nhan` → tab "Chữ ký số" → upload PNG + nhập sign_phone → Lưu → check DB `SELECT sign_phone, sign_image FROM staff WHERE id = <user_id>`.

    **Commit:** `feat: thêm UI upload chữ ký số và tài khoản SmartCA — HDSD I.4`
  </action>
  <verify>
    <automated>
      cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tail -20 &&
      cd ../frontend && npx tsc --noEmit 2>&1 | tail -20 &&
      docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT proname FROM pg_proc WHERE proname = 'fn_staff_update_signature';" &&
      docker exec qlvb_postgres psql -U postgres -d qlvb -c "\df public.fn_staff_update_signature"
    </automated>
  </verify>
  <done>
    - SP `public.fn_staff_update_signature` exists và test chạy success.
    - Backend `npx tsc --noEmit` pass.
    - Frontend `npx tsc --noEmit` pass.
    - Route `/api/ho-so-ca-nhan/chu-ky-so` (PATCH) + `/anh-chu-ky` (POST/GET) mount tại server.ts với chỉ `authenticate`.
    - **Backend dùng đúng signature: `upload.single('file')`, `uploadFile(key, buffer, 'image/png')` (3 args), `getFileUrl(path, 3600)` (2 args).**
    - Profile page có tab/section "Chữ ký số" với Upload PNG + Input sign_phone + nút Lưu.
    - `/auth/me` trả về `sign_phone` và `sign_image_url` (presigned).
    - Manual test: upload PNG + nhập sign_phone → DB cập nhật đúng.
    - Commit: `feat: thêm UI upload chữ ký số và tài khoản SmartCA — HDSD I.4`.
  </done>
</task>

<task type="auto">
  <name>Task 2: Gap 2 — Đồng ý / Từ chối thu hồi VB liên thông (DB SP + Backend route + FE detail)</name>
  <files>
    e_office_app_new/database/migrations/quick_260418_hlj_recall.sql,
    e_office_app_new/backend/src/repositories/inter-incoming.repository.ts,
    e_office_app_new/backend/src/routes/inter-incoming.ts,
    e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/[id]/page.tsx,
    e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/page.tsx
  </files>
  <action>
    **Wave 1 — DB (per A1: SOFT-DELETE incoming_docs liên kết khi đồng ý thu hồi):**
    **Reminder: `inter_incoming_docs.id` là BIGSERIAL → p_id BIGINT. `staff.id` là INT → p_user_id INT.**

    1. **VERIFY trước:** kiểm tra schema `incoming_docs` và `inter_incoming_docs`:
       ```bash
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "\d edoc.incoming_docs" | grep -E "is_deleted|deleted_at|deleted_by|is_inter_doc|inter_doc_id"
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "\d edoc.inter_incoming_docs" | head -40
       ```
       - Nếu `incoming_docs` THIẾU `is_deleted/deleted_at/deleted_by` → phải thêm migration cho 3 cột này (theo locked decision A1).
       - Verify `is_inter_doc BOOLEAN` và `inter_doc_id BIGINT` có trong incoming_docs để filter cascade.

    2. Tạo `e_office_app_new/database/migrations/quick_260418_hlj_recall.sql`:
       ```sql
       -- Bổ sung cột metadata cho inter_incoming_docs (recall flow)
       ALTER TABLE edoc.inter_incoming_docs
         ADD COLUMN IF NOT EXISTS recall_reason TEXT,
         ADD COLUMN IF NOT EXISTS recall_requested_at TIMESTAMPTZ,
         ADD COLUMN IF NOT EXISTS recall_response TEXT,
         ADD COLUMN IF NOT EXISTS recall_responded_by INT,
         ADD COLUMN IF NOT EXISTS recall_responded_at TIMESTAMPTZ,
         ADD COLUMN IF NOT EXISTS status_before_recall VARCHAR(50);
         -- status_before_recall: lưu status TRƯỚC khi chuyển sang 'recall_requested',
         -- để reject có thể restore về đúng trạng thái (pending / received / ...)

       -- Bổ sung soft-delete cho incoming_docs nếu thiếu (theo A1)
       ALTER TABLE edoc.incoming_docs
         ADD COLUMN IF NOT EXISTS is_deleted BOOLEAN DEFAULT FALSE NOT NULL,
         ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
         ADD COLUMN IF NOT EXISTS deleted_by INT;

       -- TRIGGER: tự động snapshot status_before_recall khi status chuyển sang 'recall_requested'
       -- Đảm bảo mọi code path (webhook LGSP, admin tool, SP nội bộ) đều auto-save status cũ.
       CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_snapshot_status_before_recall()
       RETURNS TRIGGER
       LANGUAGE plpgsql
       AS $$
       BEGIN
           IF NEW.status = 'recall_requested'
              AND (OLD.status IS DISTINCT FROM 'recall_requested')
              AND NEW.status_before_recall IS NULL THEN
               NEW.status_before_recall := OLD.status;
           END IF;
           RETURN NEW;
       END;
       $$;

       DROP TRIGGER IF EXISTS trg_inter_incoming_snapshot_status_before_recall ON edoc.inter_incoming_docs;
       CREATE TRIGGER trg_inter_incoming_snapshot_status_before_recall
           BEFORE UPDATE ON edoc.inter_incoming_docs
           FOR EACH ROW
           EXECUTE FUNCTION edoc.fn_inter_incoming_snapshot_status_before_recall();

       -- SP: Đồng ý thu hồi (status='recall_requested' → 'recalled' + soft-delete incoming_docs liên kết)
       -- id là BIGSERIAL → p_id BIGINT
       CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_recall_approve(
           p_id BIGINT,
           p_user_id INT
       )
       RETURNS TABLE(success BOOLEAN, message TEXT)
       LANGUAGE plpgsql
       SECURITY DEFINER
       AS $$
       DECLARE
           v_status VARCHAR(50);
           v_deleted_count INT;
       BEGIN
           SELECT status INTO v_status FROM edoc.inter_incoming_docs WHERE id = p_id;
           IF NOT FOUND THEN
               RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản liên thông'::TEXT;
               RETURN;
           END IF;
           IF v_status <> 'recall_requested' THEN
               RETURN QUERY SELECT FALSE, ('Trạng thái hiện tại không cho phép đồng ý thu hồi: ' || v_status)::TEXT;
               RETURN;
           END IF;

           UPDATE edoc.inter_incoming_docs
           SET status = 'recalled',
               recall_responded_by = p_user_id,
               recall_responded_at = NOW(),
               updated_at = NOW()
           WHERE id = p_id;

           -- Soft-delete VB đến đã phát sinh (per A1)
           UPDATE edoc.incoming_docs
           SET is_deleted = TRUE,
               deleted_at = NOW(),
               deleted_by = p_user_id
           WHERE is_inter_doc = TRUE AND inter_doc_id = p_id AND is_deleted = FALSE;

           GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

           RETURN QUERY SELECT TRUE, ('Đã đồng ý thu hồi. Xóa ' || v_deleted_count || ' văn bản đến liên kết.')::TEXT;
       END;
       $$;

       -- SP: Từ chối thu hồi (restore status_before_recall, fallback 'received')
       -- id là BIGSERIAL → p_id BIGINT
       CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_recall_reject(
           p_id BIGINT,
           p_user_id INT,
           p_reason TEXT
       )
       RETURNS TABLE(success BOOLEAN, message TEXT)
       LANGUAGE plpgsql
       SECURITY DEFINER
       AS $$
       DECLARE
           v_status VARCHAR(50);
           v_prev_status VARCHAR(50);
           v_restore_status VARCHAR(50);
       BEGIN
           IF p_reason IS NULL OR LENGTH(TRIM(p_reason)) = 0 THEN
               RETURN QUERY SELECT FALSE, 'Vui lòng nhập lý do từ chối thu hồi'::TEXT;
               RETURN;
           END IF;

           SELECT status, status_before_recall
             INTO v_status, v_prev_status
             FROM edoc.inter_incoming_docs WHERE id = p_id;

           IF NOT FOUND THEN
               RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản liên thông'::TEXT;
               RETURN;
           END IF;
           IF v_status <> 'recall_requested' THEN
               RETURN QUERY SELECT FALSE, ('Trạng thái hiện tại không cho phép từ chối thu hồi: ' || v_status)::TEXT;
               RETURN;
           END IF;

           -- Restore status trước khi yêu cầu thu hồi. Nếu snapshot null → fallback 'received'.
           v_restore_status := COALESCE(v_prev_status, 'received');

           UPDATE edoc.inter_incoming_docs
           SET status = v_restore_status,
               recall_response = p_reason,
               recall_responded_by = p_user_id,
               recall_responded_at = NOW(),
               status_before_recall = NULL,  -- clear snapshot sau khi restore
               updated_at = NOW()
           WHERE id = p_id;

           RETURN QUERY SELECT TRUE, ('Đã từ chối yêu cầu thu hồi. Khôi phục trạng thái: ' || v_restore_status)::TEXT;
       END;
       $$;

       -- SP get_by_id: CREATE OR REPLACE để trả về 5 field recall_* + status_before_recall
       -- id là BIGSERIAL → p_id BIGINT
       -- LƯU Ý: Phải đọc SP fn_inter_incoming_get_by_id HIỆN CÓ trong 000_full_schema.sql trước,
       -- copy nguyên RETURNS TABLE cũ, CHỈ THÊM 6 field mới vào cuối (KHÔNG rename/remove field cũ).
       CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_get_by_id(p_id BIGINT)
       RETURNS TABLE(
           -- ===== COPY toàn bộ field cũ từ SP hiện tại ở đây (id, unit_id, status, ...) =====
           -- Giữ nguyên thứ tự và tên field để không break FE/BE hiện tại.
           -- Thêm 6 field mới vào cuối:
           recall_reason TEXT,
           recall_requested_at TIMESTAMPTZ,
           recall_response TEXT,
           recall_responded_by INT,
           recall_responded_at TIMESTAMPTZ,
           status_before_recall VARCHAR
       )
       LANGUAGE plpgsql
       AS $$
       BEGIN
           RETURN QUERY
           SELECT
               -- ===== COPY toàn bộ SELECT cũ ở đây =====
               iid.recall_reason,
               iid.recall_requested_at,
               iid.recall_response,
               iid.recall_responded_by,
               iid.recall_responded_at,
               iid.status_before_recall
           FROM edoc.inter_incoming_docs iid
           WHERE iid.id = p_id;
       END;
       $$;
       ```
       **HƯỚNG DẪN cho executor:** Trước khi viết `CREATE OR REPLACE fn_inter_incoming_get_by_id`, chạy:
       ```bash
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "\df+ edoc.fn_inter_incoming_get_by_id"
       ```
       Copy toàn bộ RETURNS TABLE + body hiện tại, THÊM 6 field mới vào cuối. KHÔNG viết lại từ đầu để tránh break contract.

    3. Chạy migration + seed test data:
       ```bash
       docker cp e_office_app_new/database/migrations/quick_260418_hlj_recall.sql qlvb_postgres:/tmp/
       docker exec qlvb_postgres psql -U postgres -d qlvb -f /tmp/quick_260418_hlj_recall.sql
       # Seed 1 row test (trigger sẽ auto-save status_before_recall):
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "UPDATE edoc.inter_incoming_docs SET status='recall_requested', recall_reason='Test thu hồi', recall_requested_at=NOW() WHERE id = (SELECT MIN(id) FROM edoc.inter_incoming_docs);"
       # Verify trigger đã lưu status_before_recall:
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT id, status, status_before_recall FROM edoc.inter_incoming_docs WHERE status='recall_requested' LIMIT 1;"
       # Test SP reject — phải restore về status_before_recall:
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT * FROM edoc.fn_inter_incoming_recall_reject((SELECT MIN(id) FROM edoc.inter_incoming_docs WHERE status='recall_requested'), 1, 'Lý do test');"
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT id, status, status_before_recall, recall_response FROM edoc.inter_incoming_docs WHERE id = (SELECT MIN(id) FROM edoc.inter_incoming_docs);"
       ```

    **Wave 2 — Backend:**

    4. Update `e_office_app_new/backend/src/repositories/inter-incoming.repository.ts`:
       - Thêm 2 method (đặt sau `complete()` hoặc tương đương):
         ```typescript
         async recallApprove(id: number, userId: number) {
           return callFunctionOne<{ success: boolean; message: string }>('edoc.fn_inter_incoming_recall_approve', [id, userId]);
         },
         async recallReject(id: number, userId: number, reason: string) {
           return callFunctionOne<{ success: boolean; message: string }>('edoc.fn_inter_incoming_recall_reject', [id, userId, reason]);
         },
         ```
       - **Bổ sung 6 field vào Row interface `InterIncomingDocDetail`** (đồng bộ với SP `fn_inter_incoming_get_by_id` đã cập nhật):
         ```typescript
         recall_reason: string | null;
         recall_requested_at: string | null;
         recall_response: string | null;
         recall_responded_by: number | null;
         recall_responded_at: string | null;
         status_before_recall: string | null;
         ```

    5. Update `e_office_app_new/backend/src/routes/inter-incoming.ts`:
       - Thêm 2 route sau `/hoan-thanh` (theo pattern hiện có):
         ```typescript
         router.post('/:id/dong-y-thu-hoi', async (req: AuthRequest, res, next) => {
           try {
             const id = Number(req.params.id);
             if (!Number.isInteger(id) || id <= 0) return res.status(400).json({ message: 'ID không hợp lệ' });
             const result = await interIncomingRepository.recallApprove(id, req.user!.staffId);
             if (!result?.success) return res.status(400).json({ message: result?.message || 'Thao tác thất bại' });
             res.json({ success: true, message: result.message });
           } catch (err) { handleDbError(err, res, next); }
         });

         router.post('/:id/tu-choi-thu-hoi', async (req: AuthRequest, res, next) => {
           try {
             const id = Number(req.params.id);
             const reason = String(req.body?.reason || '').trim();
             if (!Number.isInteger(id) || id <= 0) return res.status(400).json({ message: 'ID không hợp lệ' });
             if (!reason) return res.status(400).json({ message: 'Vui lòng nhập lý do từ chối' });
             const result = await interIncomingRepository.recallReject(id, req.user!.staffId, reason);
             if (!result?.success) return res.status(400).json({ message: result?.message || 'Thao tác thất bại' });
             res.json({ success: true, message: result.message });
           } catch (err) { handleDbError(err, res, next); }
         });
         ```

    **Wave 3 — Frontend:**

    6. Update `e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/[id]/page.tsx`:
       - **Đọc file trước** để biết structure (`STATUS_MAP`, `LienThongDocDetail` interface, action handlers).
       - Cập nhật `STATUS_MAP`:
         ```typescript
         const STATUS_MAP: Record<string, { text: string; color: string }> = {
           pending: { text: 'Chờ tiếp nhận', color: 'gold' },
           received: { text: 'Đã tiếp nhận', color: 'blue' },
           completed: { text: 'Hoàn thành', color: 'green' },
           returned: { text: 'Đã chuyển lại', color: 'red' },
           recall_requested: { text: 'Đang yêu cầu thu hồi', color: 'volcano' },
           recalled: { text: 'Đã thu hồi', color: 'red' },
         };
         ```
       - Bổ sung interface `LienThongDocDetail` các field `recall_reason?`, `recall_requested_at?`, `recall_response?`, `recall_responded_at?`, `status_before_recall?`.
       - Thêm 2 handler:
         ```typescript
         const [rejectOpen, setRejectOpen] = useState(false);
         const [rejectReason, setRejectReason] = useState('');
         const [rejecting, setRejecting] = useState(false);

         const handleDongY = () => {
           Modal.confirm({
             title: 'Đồng ý thu hồi văn bản?',
             content: 'Văn bản đến đã phát sinh từ văn bản liên thông này sẽ bị xóa (chuyển vào thùng rác). Bạn xác nhận?',
             okText: 'Đồng ý thu hồi',
             okButtonProps: { danger: true },
             cancelText: 'Hủy',
             onOk: async () => {
               try {
                 const res = await api.post(`/van-ban-lien-thong/${id}/dong-y-thu-hoi`);
                 message.success(res.data?.message || 'Đã đồng ý thu hồi');
                 fetchDetail();
               } catch (err: any) {
                 message.error(err.response?.data?.message || 'Thao tác thất bại');
               }
             },
           });
         };

         const handleTuChoi = async () => {
           if (!rejectReason.trim()) {
             message.warning('Vui lòng nhập lý do từ chối');
             return;
           }
           setRejecting(true);
           try {
             const res = await api.post(`/van-ban-lien-thong/${id}/tu-choi-thu-hoi`, { reason: rejectReason.trim() });
             message.success(res.data?.message || 'Đã từ chối thu hồi');
             setRejectOpen(false);
             setRejectReason('');
             fetchDetail();
           } catch (err: any) {
             message.error(err.response?.data?.message || 'Thao tác thất bại');
           } finally {
             setRejecting(false);
           }
         };
         ```
       - Render 2 button conditional (đặt cùng khu vực với `/nhan-ban-giao`, `/chuyen-lai`):
         ```tsx
         {doc?.status === 'recall_requested' && (
           <Space>
             <Button danger onClick={handleDongY}>Đồng ý thu hồi</Button>
             <Button type="primary" onClick={() => setRejectOpen(true)}>Từ chối thu hồi</Button>
           </Space>
         )}
         ```
       - Hiển thị `recall_reason` (nếu có): card alert "Lý do yêu cầu thu hồi: ...".
       - Modal Từ chối thu hồi:
         ```tsx
         <Modal
           open={rejectOpen}
           title="Từ chối yêu cầu thu hồi"
           okText="Gửi từ chối"
           cancelText="Hủy"
           confirmLoading={rejecting}
           onCancel={() => { setRejectOpen(false); setRejectReason(''); }}
           onOk={handleTuChoi}
         >
           <Form layout="vertical">
             <Form.Item label="Lý do từ chối" required>
               <Input.TextArea
                 rows={4}
                 maxLength={1000}
                 showCount
                 value={rejectReason}
                 onChange={(e) => setRejectReason(e.target.value)}
                 placeholder="Nhập lý do từ chối thu hồi..."
               />
             </Form.Item>
           </Form>
         </Modal>
         ```

    7. Update `e_office_app_new/frontend/src/app/(main)/van-ban-lien-thong/page.tsx`:
       - Cập nhật `STATUS_MAP` đồng bộ với detail page (thêm `recall_requested`, `recalled`).
       - Nếu có filter Select status → thêm 2 option: "Đang yêu cầu thu hồi" (`recall_requested`), "Đã thu hồi" (`recalled`).

    **Verification sau task:**
    - `cd e_office_app_new/backend && npx tsc --noEmit` → 0 errors.
    - `cd e_office_app_new/frontend && npx tsc --noEmit` → 0 errors.
    - Test manual:
      - Seed 1 row status='received' → UPDATE status='recall_requested' → trigger tự save status_before_recall='received'.
      - Mở detail → thấy 2 button.
      - Bấm "Đồng ý" → check DB incoming_docs cột is_deleted=TRUE.
      - Reset rồi bấm "Từ chối" reason rỗng → 400. Reason hợp lệ → status về 'received' (restore) + status_before_recall=NULL.

    **Commit:** `feat: thêm chức năng đồng ý/từ chối thu hồi VB liên thông — HDSD 2.3`
  </action>
  <verify>
    <automated>
      cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tail -20 &&
      cd ../frontend && npx tsc --noEmit 2>&1 | tail -20 &&
      docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT proname FROM pg_proc WHERE proname IN ('fn_inter_incoming_recall_approve','fn_inter_incoming_recall_reject','fn_inter_incoming_get_by_id','fn_inter_incoming_snapshot_status_before_recall');" &&
      docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT column_name FROM information_schema.columns WHERE table_schema='edoc' AND table_name='inter_incoming_docs' AND (column_name LIKE 'recall_%' OR column_name='status_before_recall');" &&
      docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT column_name FROM information_schema.columns WHERE table_schema='edoc' AND table_name='incoming_docs' AND column_name IN ('is_deleted','deleted_at','deleted_by');" &&
      docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT tgname FROM pg_trigger WHERE tgname = 'trg_inter_incoming_snapshot_status_before_recall';"
    </automated>
  </verify>
  <done>
    - 4 SP/trigger function exist: `fn_inter_incoming_recall_approve`, `fn_inter_incoming_recall_reject`, `fn_inter_incoming_get_by_id` (revised với 6 recall fields), `fn_inter_incoming_snapshot_status_before_recall`.
    - Trigger `trg_inter_incoming_snapshot_status_before_recall` active.
    - `inter_incoming_docs` có 6 cột mới: 5 `recall_*` + `status_before_recall`.
    - **SP params dùng `p_id BIGINT` (đúng với BIGSERIAL), KHÔNG `p_id INT`.**
    - `incoming_docs` có `is_deleted/deleted_at/deleted_by` (đã có hoặc vừa thêm).
    - Backend `npx tsc --noEmit` pass.
    - Frontend `npx tsc --noEmit` pass.
    - 2 route `POST /:id/dong-y-thu-hoi` + `POST /:id/tu-choi-thu-hoi` mount.
    - Detail page render 2 button conditional khi `status='recall_requested'` + Modal từ chối với reason required.
    - STATUS_MAP cập nhật cả list page + detail page.
    - Manual test: đồng ý → incoming_docs liên kết bị soft-delete. Từ chối → status restore về status_before_recall.
    - Commit: `feat: thêm chức năng đồng ý/từ chối thu hồi VB liên thông — HDSD 2.3`.
  </done>
</task>

<task type="auto">
  <name>Task 3: Gap 3 — HSCV Mở lại + Lấy số (DB SP + Backend route + FE detail)</name>
  <files>
    e_office_app_new/database/migrations/quick_260418_hlj_hscv.sql,
    e_office_app_new/backend/src/repositories/handling-doc.repository.ts,
    e_office_app_new/backend/src/routes/handling-doc.ts,
    e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx
  </files>
  <action>
    **Wave 1 — DB (per A2: giữ progress=100 khi reopen; per A3: reset số theo năm `created_at`):**
    **Reminder: `handling_docs.id` là BIGSERIAL → p_id BIGINT. `doc_books.id` là SERIAL → p_doc_book_id INT. `staff.id` là INT → p_user_id INT.**

    1. **VERIFY trước:**
       ```bash
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "\d edoc.handling_docs" | grep -E "number|status|progress|doc_book_id|created_at|complete_date|complete_user_id|unit_id|sub_number|notation|doc_notation"
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "\d edoc.doc_books" | head -20
       ```
       - Đảm bảo các cột tồn tại. Theo schema 000_full_schema.sql: `handling_docs` có `doc_notation VARCHAR(100)` (KHÔNG phải `notation` — verify lại).
       - Nếu cột là `doc_notation` → khi SP `fn_handling_doc_get_by_id` trả về, dùng tên thật của DB. FE interface cũng phải match.

    2. Tạo `e_office_app_new/database/migrations/quick_260418_hlj_hscv.sql`:
       ```sql
       -- SP: Mở lại HSCV (status=4 → 1, GIỮ progress=100 per A2)
       -- handling_docs.id là BIGSERIAL → p_id BIGINT
       CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_reopen(
           p_id BIGINT,
           p_user_id INT
       )
       RETURNS TABLE(success BOOLEAN, message TEXT)
       LANGUAGE plpgsql
       SECURITY DEFINER
       AS $$
       DECLARE
           v_status SMALLINT;
       BEGIN
           SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
           IF NOT FOUND THEN
               RETURN QUERY SELECT FALSE, 'Không tìm thấy hồ sơ công việc'::TEXT;
               RETURN;
           END IF;
           IF v_status <> 4 THEN
               RETURN QUERY SELECT FALSE, ('Chỉ có thể mở lại HSCV đã hoàn thành. Trạng thái hiện tại: ' || v_status)::TEXT;
               RETURN;
           END IF;

           -- A2: status 4→1, GIỮ progress=100, clear complete_date/complete_user_id, log action
           UPDATE edoc.handling_docs
           SET status = 1,
               complete_date = NULL,
               complete_user_id = NULL,
               updated_by = p_user_id,
               updated_at = NOW()
           WHERE id = p_id;

           -- Log action vào handling_doc_history nếu bảng tồn tại (optional)
           -- Nếu chưa có log table, có thể bỏ qua hoặc dùng comment.

           RETURN QUERY SELECT TRUE, 'Đã mở lại hồ sơ công việc'::TEXT;
       END;
       $$;

       -- SP: Lấy số kế tiếp (per A3: reset theo năm created_at + doc_book_id)
       -- doc_books.id là SERIAL → p_doc_book_id INT OK
       CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_next_number(
           p_doc_book_id INT,
           p_unit_id INT
       )
       RETURNS INT
       LANGUAGE plpgsql
       AS $$
       DECLARE
           v_next INT;
       BEGIN
           SELECT COALESCE(MAX(number), 0) + 1
           INTO v_next
           FROM edoc.handling_docs
           WHERE doc_book_id = p_doc_book_id
             AND unit_id = p_unit_id
             AND number IS NOT NULL
             AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW());
           RETURN v_next;
       END;
       $$;

       -- SP: Gán số cho HSCV
       -- handling_docs.id là BIGSERIAL → p_id BIGINT
       CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_assign_number(
           p_id BIGINT,
           p_user_id INT,
           p_doc_book_id INT
       )
       RETURNS TABLE(success BOOLEAN, message TEXT, "number" INT)
       LANGUAGE plpgsql
       SECURITY DEFINER
       AS $$
       DECLARE
           v_unit_id INT;
           v_existing_number INT;
           v_next INT;
       BEGIN
           SELECT unit_id, number INTO v_unit_id, v_existing_number FROM edoc.handling_docs WHERE id = p_id;
           IF NOT FOUND THEN
               RETURN QUERY SELECT FALSE, 'Không tìm thấy hồ sơ công việc'::TEXT, NULL::INT;
               RETURN;
           END IF;
           IF v_existing_number IS NOT NULL THEN
               RETURN QUERY SELECT FALSE, ('HSCV đã có số ' || v_existing_number)::TEXT, v_existing_number;
               RETURN;
           END IF;
           IF p_doc_book_id IS NULL THEN
               RETURN QUERY SELECT FALSE, 'Vui lòng chọn sổ văn bản'::TEXT, NULL::INT;
               RETURN;
           END IF;

           -- Tính số kế tiếp (A3: theo năm created_at)
           v_next := edoc.fn_handling_doc_get_next_number(p_doc_book_id, v_unit_id);

           UPDATE edoc.handling_docs
           SET number = v_next,
               doc_book_id = p_doc_book_id,
               updated_by = p_user_id,
               updated_at = NOW()
           WHERE id = p_id;

           RETURN QUERY SELECT TRUE, ('Đã lấy số ' || v_next)::TEXT, v_next;
       END;
       $$;

       -- SP get_by_id: CREATE OR REPLACE để trả về number, sub_number, doc_notation, doc_book_id, doc_book_name
       -- handling_docs.id là BIGSERIAL → p_id BIGINT
       -- LƯU Ý: Phải đọc SP fn_handling_doc_get_by_id HIỆN CÓ trong 000_full_schema.sql trước,
       -- copy nguyên RETURNS TABLE + SELECT cũ, CHỈ THÊM 5 field vào cuối + JOIN doc_books.
       -- KHÔNG rename/remove field hiện có để giữ backward compatibility với code đang dùng.
       CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_by_id(p_id BIGINT)
       RETURNS TABLE(
           -- ===== COPY toàn bộ field cũ từ SP hiện tại (id, unit_id, status, name, abstract, ...) =====
           -- Thêm 5 field mới vào cuối:
           "number" INT,
           sub_number VARCHAR,
           doc_notation VARCHAR,
           doc_book_id INT,
           doc_book_name VARCHAR
       )
       LANGUAGE plpgsql
       AS $$
       BEGIN
           RETURN QUERY
           SELECT
               -- ===== COPY toàn bộ SELECT cũ ở đây =====
               hd.number,
               hd.sub_number,
               hd.doc_notation,
               hd.doc_book_id,
               db.name AS doc_book_name
           FROM edoc.handling_docs hd
           LEFT JOIN edoc.doc_books db ON db.id = hd.doc_book_id AND db.is_deleted = FALSE
           WHERE hd.id = p_id;
       END;
       $$;
       ```

       **Lưu ý reserved word**: `number` là tên cột → trong `RETURNS TABLE` dùng `"number" INT` để an toàn (mặc dù `number` không phải reserved trong PG).

       **HƯỚNG DẪN cho executor:** Trước khi viết `CREATE OR REPLACE fn_handling_doc_get_by_id`, chạy:
       ```bash
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "\df+ edoc.fn_handling_doc_get_by_id"
       ```
       Copy toàn bộ RETURNS TABLE + SELECT hiện tại, THÊM 5 field mới + JOIN doc_books vào cuối. KHÔNG viết lại từ đầu để tránh break contract.

       **Verify exact column name** trong handling_docs: nếu là `doc_notation` thay vì `notation` → FE interface phải dùng `doc_notation` (không alias).

    3. Chạy migration + test:
       ```bash
       docker cp e_office_app_new/database/migrations/quick_260418_hlj_hscv.sql qlvb_postgres:/tmp/
       docker exec qlvb_postgres psql -U postgres -d qlvb -f /tmp/quick_260418_hlj_hscv.sql
       # Test SP get_next_number:
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT edoc.fn_handling_doc_get_next_number(1, 1);"
       # Test reopen với HSCV status=4 (cần seed nếu chưa có):
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT * FROM edoc.fn_handling_doc_reopen((SELECT MIN(id) FROM edoc.handling_docs WHERE status=4), 1);"
       # Test get_by_id trả 5 field mới:
       docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT number, sub_number, doc_notation, doc_book_id, doc_book_name FROM edoc.fn_handling_doc_get_by_id((SELECT MIN(id) FROM edoc.handling_docs));"
       ```

    **Wave 2 — Backend:**

    4. Update `e_office_app_new/backend/src/repositories/handling-doc.repository.ts`:
       - Thêm method (sau `complete()` hoặc tương đương):
         ```typescript
         async reopen(id: number, userId: number) {
           return callFunctionOne<{ success: boolean; message: string }>('edoc.fn_handling_doc_reopen', [id, userId]);
         },
         async assignNumber(id: number, userId: number, docBookId: number) {
           return callFunctionOne<{ success: boolean; message: string; number: number | null }>('edoc.fn_handling_doc_assign_number', [id, userId, docBookId]);
         },
         ```
       - **Bổ sung 5 field vào Row interface `HscvDetail`** (đồng bộ với SP `fn_handling_doc_get_by_id` đã cập nhật):
         ```typescript
         number: number | null;
         sub_number: string | null;
         doc_notation: string | null;   // Exact DB column name — KHÔNG rename thành 'notation'
         doc_book_id: number | null;
         doc_book_name: string | null;  // JOIN từ doc_books.name
         ```

    5. Update `e_office_app_new/backend/src/routes/handling-doc.ts`:
       - Thêm 2 route MỚI (KHÔNG động vào `/trang-thai` hiện có):
         ```typescript
         router.post('/:id/mo-lai', async (req: AuthRequest, res, next) => {
           try {
             const id = Number(req.params.id);
             if (!Number.isInteger(id) || id <= 0) return res.status(400).json({ message: 'ID không hợp lệ' });
             const result = await handlingDocRepository.reopen(id, req.user!.staffId);
             if (!result?.success) return res.status(400).json({ message: result?.message || 'Thao tác thất bại' });
             res.json({ success: true, message: result.message });
           } catch (err) { handleDbError(err, res, next); }
         });

         router.post('/:id/lay-so', async (req: AuthRequest, res, next) => {
           try {
             const id = Number(req.params.id);
             const docBookId = Number(req.body?.doc_book_id);
             if (!Number.isInteger(id) || id <= 0) return res.status(400).json({ message: 'ID không hợp lệ' });
             if (!Number.isInteger(docBookId) || docBookId <= 0) return res.status(400).json({ message: 'Vui lòng chọn sổ văn bản' });
             const result = await handlingDocRepository.assignNumber(id, req.user!.staffId, docBookId);
             if (!result?.success) return res.status(400).json({ message: result?.message || 'Thao tác thất bại' });
             res.json({ success: true, message: result.message, number: result.number });
           } catch (err) { handleDbError(err, res, next); }
         });
         ```

    **Wave 3 — Frontend:**

    6. Update `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`:
       - **Đọc file trước** để hiểu `getToolbarButtons(status)` và `handleButtonClick(action)` pattern.
       - Bổ sung interface `HscvDetail`: `number?: number | null; sub_number?: string | null; doc_notation?: string | null; doc_book_id?: number | null; doc_book_name?: string | null;` (exact tên field từ SP — `doc_notation` KHÔNG `notation`).
       - Update `getToolbarButtons(status)`:
         - case 4 (Hoàn thành): thêm `{ label: 'Mở lại', type: 'primary' as const, action: 'reopen' }` ở đầu list (trước "Xem lịch sử").
         - case 1 (Đang xử lý) và case 3 (Đã duyệt): thêm `{ label: 'Lấy số', type: 'default' as const, action: 'get_number' }` (chỉ hiện khi `detail?.number == null` — thêm điều kiện trong nơi render: `{btn.action === 'get_number' && detail?.number != null ? null : <Button ...>}`).
       - Thêm 2 handler:
         ```typescript
         const [laySoOpen, setLaySoOpen] = useState(false);
         const [docBooks, setDocBooks] = useState<{ id: number; name: string; code?: string }[]>([]);
         const [selectedBookId, setSelectedBookId] = useState<number | null>(null);
         const [laying, setLaying] = useState(false);

         const handleReopen = () => {
           Modal.confirm({
             title: 'Mở lại hồ sơ công việc?',
             content: 'Trạng thái sẽ chuyển từ "Hoàn thành" về "Đang xử lý" (giữ nguyên tiến độ 100%). Bạn xác nhận?',
             okText: 'Mở lại',
             cancelText: 'Hủy',
             onOk: async () => {
               try {
                 const res = await api.post(`/ho-so-cong-viec/${id}/mo-lai`);
                 message.success(res.data?.message || 'Đã mở lại HSCV');
                 fetchDetail();
               } catch (err: any) {
                 message.error(err.response?.data?.message || 'Thao tác thất bại');
               }
             },
           });
         };

         const handleLaySo = async () => {
           // Nếu detail đã có doc_book_id → dùng luôn, hỏi confirm
           if (detail?.doc_book_id) {
             Modal.confirm({
               title: 'Lấy số văn bản?',
               content: `Sẽ cấp số kế tiếp theo sổ "${detail.doc_book_name || '#' + detail.doc_book_id}". Bạn xác nhận?`,
               okText: 'Lấy số',
               cancelText: 'Hủy',
               onOk: async () => {
                 try {
                   const res = await api.post(`/ho-so-cong-viec/${id}/lay-so`, { doc_book_id: detail.doc_book_id });
                   message.success(`Đã lấy số ${res.data?.number}`);
                   fetchDetail();
                 } catch (err: any) {
                   message.error(err.response?.data?.message || 'Thao tác thất bại');
                 }
               },
             });
             return;
           }
           // Chưa có sổ → mở Modal Select
           try {
             const res = await api.get('/quan-tri/so-van-ban', { params: { pageSize: 1000 } });
             setDocBooks(res.data?.items || res.data?.data || []);
             setSelectedBookId(null);
             setLaySoOpen(true);
           } catch {
             message.error('Không tải được danh sách sổ văn bản');
           }
         };

         const handleConfirmLaySo = async () => {
           if (!selectedBookId) {
             message.warning('Vui lòng chọn sổ văn bản');
             return;
           }
           setLaying(true);
           try {
             const res = await api.post(`/ho-so-cong-viec/${id}/lay-so`, { doc_book_id: selectedBookId });
             message.success(`Đã lấy số ${res.data?.number}`);
             setLaySoOpen(false);
             fetchDetail();
           } catch (err: any) {
             message.error(err.response?.data?.message || 'Thao tác thất bại');
           } finally {
             setLaying(false);
           }
         };
         ```
       - Update `handleButtonClick(action)` switch:
         - `case 'reopen': handleReopen(); break;`
         - `case 'get_number': handleLaySo(); break;`
       - Thêm Modal Lấy số:
         ```tsx
         <Modal
           open={laySoOpen}
           title="Chọn sổ văn bản để lấy số"
           okText="Lấy số"
           cancelText="Hủy"
           confirmLoading={laying}
           onCancel={() => setLaySoOpen(false)}
           onOk={handleConfirmLaySo}
         >
           <Form layout="vertical">
             <Form.Item label="Sổ văn bản" required>
               <Select
                 placeholder="Chọn sổ văn bản"
                 value={selectedBookId ?? undefined}
                 onChange={setSelectedBookId}
                 options={docBooks.map((b) => ({ value: b.id, label: b.code ? `${b.code} - ${b.name}` : b.name }))}
                 showSearch
                 optionFilterProp="label"
               />
             </Form.Item>
           </Form>
         </Modal>
         ```
       - Hiển thị số văn bản trong header detail (nếu chưa có): `{detail?.number ? `Số: ${detail.number}${detail.doc_book_name ? ' / ' + detail.doc_book_name : ''}` : 'Chưa có số'}`.

    **Verification sau task:**
    - `cd e_office_app_new/backend && npx tsc --noEmit` → 0 errors.
    - `cd e_office_app_new/frontend && npx tsc --noEmit` → 0 errors.
    - Test manual: HSCV status=4 → bấm "Mở lại" → DB status=1, progress vẫn 100. HSCV status=1 number NULL → bấm "Lấy số" → chọn sổ → DB number = MAX+1 theo năm.

    **Commit:** `feat: thêm chức năng mở lại và lấy số HSCV — HDSD 3.1, 3.2`
  </action>
  <verify>
    <automated>
      cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tail -20 &&
      cd ../frontend && npx tsc --noEmit 2>&1 | tail -20 &&
      docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT proname FROM pg_proc WHERE proname IN ('fn_handling_doc_reopen','fn_handling_doc_get_next_number','fn_handling_doc_assign_number','fn_handling_doc_get_by_id');" &&
      docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT edoc.fn_handling_doc_get_next_number(1, 1);" &&
      docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT number, sub_number, doc_notation, doc_book_id, doc_book_name FROM edoc.fn_handling_doc_get_by_id((SELECT MIN(id) FROM edoc.handling_docs)) LIMIT 1;"
    </automated>
  </verify>
  <done>
    - 4 SP exist: `fn_handling_doc_reopen`, `fn_handling_doc_get_next_number`, `fn_handling_doc_assign_number`, `fn_handling_doc_get_by_id` (revised với 5 field mới + JOIN doc_books).
    - **SP params dùng `p_id BIGINT` (đúng với BIGSERIAL), `p_doc_book_id INT` (đúng với SERIAL), `p_user_id INT`.**
    - Backend `npx tsc --noEmit` pass.
    - Frontend `npx tsc --noEmit` pass.
    - 2 route `POST /:id/mo-lai` + `POST /:id/lay-so` mount.
    - Detail page hiển thị nút "Mở lại" khi status=4, nút "Lấy số" khi status=1 và number=null.
    - Modal Select sổ văn bản load từ `/quan-tri/so-van-ban`.
    - Header hiển thị số văn bản sau khi lấy (kèm doc_book_name).
    - Manual test: reopen → status 4→1, progress giữ 100. Lấy số → number = MAX+1 theo năm.
    - Commit: `feat: thêm chức năng mở lại và lấy số HSCV — HDSD 3.1, 3.2`.
  </done>
</task>

</tasks>

<verification>
Sau khi cả 3 task hoàn tất:

1. **DB verification:**
   ```bash
   docker exec qlvb_postgres psql -U postgres -d qlvb -c "
     SELECT proname FROM pg_proc WHERE proname IN (
       'fn_staff_update_signature',
       'fn_inter_incoming_recall_approve','fn_inter_incoming_recall_reject','fn_inter_incoming_get_by_id','fn_inter_incoming_snapshot_status_before_recall',
       'fn_handling_doc_reopen','fn_handling_doc_get_next_number','fn_handling_doc_assign_number','fn_handling_doc_get_by_id'
     ) ORDER BY proname;
   "
   ```
   Expected: 9 SP/function names (1 Gap1 + 4 Gap2 + 4 Gap3).

2. **Backend type-check:** `cd e_office_app_new/backend && npx tsc --noEmit` → 0 errors.

3. **Frontend type-check:** `cd e_office_app_new/frontend && npx tsc --noEmit` → 0 errors.

4. **Manual UAT:**
   - Gap 1: Login (user thường, không cần admin) → `/thong-tin-ca-nhan` → tab "Chữ ký số" → upload PNG + nhập sign_phone → Lưu → success. Logout/login → `/auth/me` trả về sign_phone + sign_image_url presigned.
   - Gap 2: Seed `UPDATE inter_incoming_docs SET status='recall_requested' WHERE id=X` (trigger auto-save status_before_recall) → mở `/van-ban-lien-thong/X` → thấy 2 button + thấy recall_reason. "Đồng ý" → confirm → status='recalled' + incoming_docs liên kết is_deleted=TRUE. Reset rồi test "Từ chối" với reason rỗng → 400. Với reason hợp lệ → status về trạng thái trước recall (status_before_recall, fallback 'received') + recall_response lưu.
   - Gap 3: HSCV status=4 → mở detail → thấy "Mở lại" → confirm → status=1, progress=100. HSCV status=1 number=null → "Lấy số" → chọn sổ → success message kèm số. Refresh → header hiển thị số + doc_book_name. Re-bấm "Lấy số" → 400 "HSCV đã có số".

5. **Route mount check:** route `/api/ho-so-ca-nhan/*` chỉ require `authenticate` (test bằng JWT của user role thường, không phải admin).

6. **Authorization check:** user role "Cán bộ" (không phải admin) gọi PATCH `/api/ho-so-ca-nhan/chu-ky-so` → 200 OK (không 403).

7. **Soft-delete cascade check (Gap 2):**
   ```bash
   docker exec qlvb_postgres psql -U postgres -d qlvb -c "
     SELECT i.id, i.is_deleted, i.deleted_at, i.deleted_by, i.is_inter_doc, i.inter_doc_id
     FROM edoc.incoming_docs i WHERE i.is_inter_doc = TRUE AND i.is_deleted = TRUE LIMIT 5;
   "
   ```
   Sau khi test đồng ý thu hồi → ít nhất 1 row có is_deleted=TRUE.

8. **Status restore check (Gap 2):**
   ```bash
   # Trước khi chuyển 'recall_requested', lưu lại status cũ
   docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT id, status FROM edoc.inter_incoming_docs WHERE id=X;"
   # Sau UPDATE status='recall_requested' → trigger lưu status_before_recall
   docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT id, status, status_before_recall FROM edoc.inter_incoming_docs WHERE id=X;"
   # Sau reject → status restore
   docker exec qlvb_postgres psql -U postgres -d qlvb -c "SELECT id, status, status_before_recall, recall_response FROM edoc.inter_incoming_docs WHERE id=X;"
   ```
   Expected: status = status cũ (received/pending/...), status_before_recall = NULL (đã clear).
</verification>

<success_criteria>
- [ ] Task 1 (Gap 1): Profile page có UI Upload PNG + Input sign_phone hoạt động end-to-end. Backend dùng đúng signature `upload.single('file')`, `uploadFile(key, buffer, type)` (3 args), `getFileUrl(path, 3600)` (2 args). Commit `feat: thêm UI upload chữ ký số và tài khoản SmartCA — HDSD I.4`.
- [ ] Task 2 (Gap 2): Detail VB liên thông có 2 button đồng ý/từ chối thu hồi. Đồng ý → soft-delete incoming_docs liên kết (per A1). Từ chối → restore status_before_recall (fallback 'received'). SP params `p_id BIGINT`. `fn_inter_incoming_get_by_id` trả 6 field recall_*/status_before_recall. Commit `feat: thêm chức năng đồng ý/từ chối thu hồi VB liên thông — HDSD 2.3`.
- [ ] Task 3 (Gap 3): Detail HSCV có nút Mở lại (giữ progress=100 per A2) và Lấy số (reset theo năm `created_at` per A3). SP params `p_id BIGINT`, `p_doc_book_id INT`. `fn_handling_doc_get_by_id` trả 5 field `number, sub_number, doc_notation, doc_book_id, doc_book_name` (JOIN doc_books). Commit `feat: thêm chức năng mở lại và lấy số HSCV — HDSD 3.1, 3.2`.
- [ ] Type-check backend + frontend: 0 errors.
- [ ] 9 SP/trigger function mới tồn tại trong DB và test inline thành công.
- [ ] Migration files committed kèm code.
- [ ] Manual UAT pass cho cả 3 gap (theo checklist verification).
- [ ] KHÔNG vi phạm CLAUDE.md rules (AntD 6 size, reserved words, field name match, maxLength, required validation, **ID type BIGINT khi bảng dùng BIGSERIAL**).
- [ ] 3 commit độc lập (1 commit cho mỗi task).
</success_criteria>

<output>
Sau khi hoàn tất, tạo `.planning/quick/260418-hlj-hdsd-compliance-p0-p1-k-s-smartca-ui-thu/260418-hlj-SUMMARY.md` với:
- Liệt kê 3 commit hash + commit messages.
- Tóm tắt thay đổi DB schema (cột mới + SP mới + trigger mới).
- Tóm tắt route mới mount + authorization.
- Manual UAT checklist + kết quả.
- Bài học rút ra (nếu có) → bổ sung vào CLAUDE.md `Phase Execution Rules` nếu phát hiện pattern mới (VD: BIGINT vs INT cho BIGSERIAL).
</output>
