# Phase 33: Database + Core Infrastructure - Context

**Gathered:** 2026-05-19
**Status:** Ready for planning
**Mode:** Auto (user delegation: "tôi cũng ko hiểu đâu nên ko cần discuss, bạn cứ tự đọc toàn bộ tài liệu... tự động thực hiện")

<domain>
## Phase Boundary

Hạ tầng schema PostgreSQL + service lookup credential per-unit sẵn sàng cho 4 phase wire LGSP thật (34-37).

**Trong scope:**
- Schema bảng `lgsp_agency_config` per `unit_id` + UNIQUE + FK + CHECK constraints
- Cột `lgsp_org_code VARCHAR(13)` trong `departments`
- Schema bảng `lgsp_status_outbox` (outbox pattern)
- Service `getLgspService(unit_id)` lookup credential động + cache + invalidation
- Encrypt `secret_key` bằng `pgcrypto.pgp_sym_encrypt` reuse `SIGNING_SECRET_KEY`
- Seed `001_required_data.sql` (chỉ insert empty placeholder row, không chứa credential thật)
- Repository `lgsp-agency-config.repository.ts` mirror pattern `signing-provider-config.repository.ts`
- TypeScript types + interfaces cho `LgspAgencyConfig` + `LgspStatusOutboxEvent`

**Ngoài scope (defer các phase sau):**
- Admin UI cấu hình credential → Phase 37 (LGSP-UI-01..04)
- Builder edXML / parser → Phase 34/35
- Worker send/receive/status-sync → Phase 34/35/36
- Auto fire status callback (03/04/05/06) → Phase 36
- Routing logic external_org vs internal_unit trong outgoing flow → Phase 34
- Gỡ `/lgsp` khỏi `hidden-routes.ts` → Phase 37

</domain>

<decisions>
## Implementation Decisions

### Encryption Strategy

- **D-01 (auto-decided):** Reuse `SIGNING_SECRET_KEY` env variable (chung với `signing_provider_config`) cho `lgsp_agency_config.secret_key_encrypted`. KHÔNG tạo `LGSP_SECRET_KEY` riêng.
- **Why:** Pattern đã verify trên prod KH (signing module). CLAUDE.md pitfall #14 đã document setup + rotation policy cho `SIGNING_SECRET_KEY` — KHÔNG cần duplicate. Trade-off: 1 key lộ = cả 2 module lộ — chấp nhận vì ops simpler + key rotation đã có quy trình.
- **Reuse code:** `backend/src/services/signing/crypto.ts` — `encrypt(plaintext: string): Promise<Buffer>` và `decrypt(ciphertext: Buffer): Promise<string>`. Mirror sang `backend/src/services/lgsp/crypto.ts` hoặc export shared từ `lib/crypto.ts`.

### Cache Invalidation Strategy

- **D-02 (auto-decided):** `getLgspService(unit_id)` dùng LRU cache 5 phút TTL (safety net) + **invalidate-on-write** từ admin route khi Phase 37 update credential.
- **Implementation:** `LgspServiceCache.invalidate(unit_id: number)` method exposed, gọi từ admin update route. TTL backup cho trường hợp multi-instance (chưa cần Redis pub/sub).
- **Why:** TTL-only sẽ có 5 phút stale window sau khi admin update credential — UX kém. Invalidate-on-write thì user thấy ngay. Redis pub/sub là overkill cho 1 instance hiện tại (defer khi scale ra cluster).

### Seed Strategy Production-Safe

- **D-03 (auto-decided):** Seed `001_required_data.sql` insert **9 row placeholder** (6 prod + 3 sandbox) với `secret_key_encrypted = pgp_sym_encrypt('placeholder_not_configured', SIGNING_SECRET_KEY)`, `is_active=FALSE` mặc định. Admin nhập credential thật qua UI Phase 37.
- **Why:** Pattern đã verify trên prod KH (signing_provider_config seed row VNPT + MySign placeholder, admin nhập credential qua `/ky-so/cau-hinh`). KHÔNG commit credential nhạy cảm lên git. KHÔNG dùng env var expand SQL (script phức tạp + rủi ro typo).
- **Row content:** 6 prod row dùng `base_url='https://apiltvb.langson.gov.vn'`, 3 sandbox row dùng `base_url='https://trucltvb.langson.gov.vn/apithunghiem'` (theo `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/List.txt`). `lgsp_org_code` set sẵn (H37.DN.001..006) vì đã biết, KHÔNG nhạy cảm.

### Unit_id Validation (root unit only)

- **D-04 (auto-decided):** **Soft validation ở admin UI Phase 37** (Select chỉ show root departments `WHERE parent_id IS NULL`) + **DB trigger BEFORE INSERT OR UPDATE** trên `lgsp_agency_config` check `EXISTS(SELECT 1 FROM departments WHERE id = NEW.unit_id AND parent_id IS NULL)` → RAISE EXCEPTION nếu không phải root.
- **Why:** UI alone không đủ — dirty admin/script INSERT có thể bypass. CHECK constraint inline không gọi được subquery → phải dùng trigger. Pattern đã có ở SPs `fn_*` khác (validate FK + business rule trong trigger).

### FK Delete Behavior

- **D-05 (auto-decided):** `lgsp_agency_config.unit_id FK departments(id)` → **ON DELETE RESTRICT** (chặn xóa department nếu còn LGSP config).
- **D-06 (auto-decided):** `lgsp_status_outbox.incoming_doc_id FK incoming_docs(id)` → **ON DELETE CASCADE** (outbox event mồ côi vô nghĩa).
- **Why:** Departments (6 DN) rarely deleted — block là an toàn, force admin disable LGSP trước khi xóa unit. Outbox event là transient queue — gắn liền VB nguồn, VB xóa thì event không còn ý nghĩa.

### Outbox Indexing

- **D-07 (auto-decided):** `lgsp_status_outbox` có 2 index:
  - **Partial index** `WHERE sent_status='pending' ORDER BY created_at` — worker poll oldest pending first, partial index nhỏ.
  - **Regular index** `(incoming_doc_id, target_status, sent_at DESC)` — query history trạng thái 1 VB cho UI.
- **Why:** Worker poll mỗi 30s sẽ chạy `SELECT ... WHERE sent_status='pending' ORDER BY created_at LIMIT 10` — partial index optimize cực tốt (chỉ index pending rows, drop sau success).

### Refactor Phase 18 `LGSPRealService`

- **D-08 (auto-decided):** Phase 18 `lgsp-real.service.ts` hiện đọc credential từ env (`LGSP_ENDPOINT`, `LGSP_USERNAME`, `LGSP_PASSWORD`). Phase 33 refactor:
  - Đổi `LGSPRealService` constructor nhận object `{ baseUrl, systemId, secretKey }`
  - Factory function `getLgspService(unit_id)` lookup credential từ `lgsp_agency_config` → instantiate `LGSPRealService` với credential đó → cache instance theo `unit_id`
  - `lgsp.service.ts` factory giữ `getLgspService(unit_id?)` — nếu không truyền `unit_id` (legacy mock test) fallback `MOCK_EXTERNAL=true` path
- **Why:** Phase 18 đã build OAuth2 + REST client + login flow + send/receive helper — KHÔNG cần rewrite. Chỉ tách credential ra parameter để per-unit lookup hoạt động.

### Schema versioning

- **D-09 (auto-decided):** Edit trực tiếp `database/schema/000_schema_v3.0.sql` (per CLAUDE.md DB Migration Strategy v3.0). Append:
  - `CREATE TABLE IF NOT EXISTS edoc.lgsp_agency_config (...)` ở phần Tables
  - `CREATE TABLE IF NOT EXISTS edoc.lgsp_status_outbox (...)` ở phần Tables
  - `ALTER TABLE public.departments ADD COLUMN IF NOT EXISTS lgsp_org_code VARCHAR(13)` (inline ALTER)
  - Trigger `fn_lgsp_agency_config_validate_root_unit()` + `CREATE TRIGGER` (idempotent DROP IF EXISTS first)
  - FK constraints wrap trong DO block catch 4 SQLSTATE (per CLAUDE.md rule)
- **Why:** Avoid creating new migration file `database/migrations/047_*.sql` — CLAUDE.md Migration Strategy explicit "KHÔNG tạo file migrations rời từ Phase 11.1".

### Claude's Discretion

- **Tên cột exact** (snake_case theo dự án convention): `lgsp_agency_config(id, unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, last_synced_at, last_sync_error, created_at, updated_at)`, `lgsp_status_outbox(id, incoming_doc_id, target_status, payload, sent_at, sent_status, retry_count, next_retry_at, error_message, created_at)`
- **CHECK constraint** `environment IN ('sandbox','prod')` và `sent_status IN ('pending','success','error')` và `target_status IN ('01','02','03','04','05','06','13','15','16')`
- **Default values**: `is_active DEFAULT FALSE`, `retry_count DEFAULT 0`, `created_at DEFAULT now()`, `updated_at DEFAULT now()` + trigger auto update
- **Triggers**: `trg_lgsp_agency_config_updated_at` auto-set `updated_at` (pattern đã có)
- **Repository methods**: `getByUnitId(unit_id, env)`, `create(...)`, `update(id, ...)`, `setActive(id, is_active)`, `updateLastSynced(unit_id, last_synced_at, error?)`, `getAllActive(env?)` — mirror signing-provider-config.repository
- **LRU cache implementation**: Dùng `lru-cache` npm package (đã có hoặc add 1 dep) hoặc inline `Map` với manual TTL — Claude chọn `Map` inline nếu chưa có dep để giảm dependency
- **Migration verification**: Sau apply schema lần 2 phải zero error (per CLAUDE.md DB Migration Rule)

### Folded Todos

None — không có todo backlog liên quan trực tiếp.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### LGSP API Spec (từ tỉnh Lạng Sơn)

- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/HuongDanKetNoiLienThongVB_v2.2.pdf` — 46-page HDSD chính thức v2.2 (10 API + edXML spec)
- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/LTVB_API_TRUC_PROD_TICHHOP.postman_collection.json` — Postman collection 9 request, dùng để E2E test sandbox
- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/QLVBDNAgencies.xlsx` — 6 credential prod (SystemId + SecretKey) cho 6 DN
- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/List.txt` — endpoint prod (`apiltvb.langson.gov.vn`) + sandbox (`trucltvb.langson.gov.vn/apithunghiem`) + 3 sandbox credential (H37.DN.001/002/003)

### Existing code patterns to mirror

- `e_office_app_new/backend/src/services/signing/crypto.ts` — encrypt/decrypt helper với `SIGNING_SECRET_KEY` (Phase 33 reuse, có thể export ra `lib/crypto.ts`)
- `e_office_app_new/backend/src/repositories/signing-provider-config.repository.ts` — repo pattern (Phase 33 mirror sang `lgsp-agency-config.repository.ts`)
- `e_office_app_new/backend/src/services/signing/providers/provider-factory.ts` — factory pattern lookup credential động (Phase 33 mirror cho `getLgspService(unit_id)`)
- `e_office_app_new/backend/src/services/lgsp-real.service.ts` — Phase 18 v3.0 LGSPRealService baseline (Phase 33 refactor: tách credential ra constructor param)
- `e_office_app_new/backend/src/services/lgsp.service.ts` — Phase 18 factory mock/real switch (Phase 33 extend: per-unit lookup)
- `e_office_app_new/backend/src/repositories/lgsp.repository.ts` — Phase 18 repo (Phase 33 không động, để Phase 35 dùng)
- `e_office_app_new/database/seed/001_required_data.sql` — seed pattern với placeholder encrypted (Phase 33 append 9 row LGSP)
- `e_office_app_new/database/archive/v2.0-incrementals/040_signing_schema.sql` — schema pattern cho `signing_provider_config` (Phase 33 reference structure khi viết `lgsp_agency_config`)

### Schema file (single source of truth)

- `e_office_app_new/database/schema/000_schema_v3.0.sql` — master schema 26K+ dòng, idempotent. Phase 33 append vào file này (KHÔNG tạo migration rời).

### Project rules (CLAUDE.md sections)

- `CLAUDE.md` § "DB Migration Strategy (v2.0+)" — bắt buộc edit `000_schema_v3.0.sql`, không tạo file mới + verify idempotent + verify SP count
- `CLAUDE.md` § "Deploy Pitfalls" #14 — SIGNING_SECRET_KEY setup, encrypt/rotation policy (apply cho LGSP secret_key)
- `CLAUDE.md` § "Phase Execution Rules" — Wave 1 DB migrations + apply DB ngay + verify SP, Wave 2 backend tuần tự, Wave 3 frontend tuần tự
- `CLAUDE.md` § "Customer-Facing Scope" — Module LGSP hiện ẩn (sẽ bật lại Phase 37), KHÔNG nhắc trong tài liệu KH cho đến khi go-live

### Project memory

- `~/.claude/projects/d--ProjectAI-quanlyvanban/memory/project_lgsp_architecture.md` — kiến trúc per-unit (đã chốt 2026-05-19, KHÔNG dùng "multi-tenant")
- `~/.claude/projects/d--ProjectAI-quanlyvanban/memory/project_phase21_lgsp_reject_intake.md` — DEFER-07 status 02 (Phase 36 sẽ wire, KHÔNG động Phase 33)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`signing/crypto.ts`** — `encrypt()` + `decrypt()` đã có, dùng `SIGNING_SECRET_KEY` + pgcrypto. Phase 33 import lại (hoặc move lên `lib/crypto.ts` shared).
- **`signing-provider-config.repository.ts`** — repo pattern + methods (getByCode, create, update, encrypt secret on write). Mirror exactly cho `lgsp-agency-config.repository.ts`.
- **`provider-factory.ts`** — factory với cache instance per-key. Phase 33 mirror với key = `unit_id + environment`.
- **`lgsp-real.service.ts`** — Phase 18 OAuth2 login + 10 API helper methods sẵn sàng. Phase 33 chỉ tách credential ra constructor param.
- **`callFunction<T>()`** trong `lib/db.ts` — call SP pattern. Repo dùng để gọi `fn_lgsp_agency_config_*`.

### Established Patterns

- **Repository = const object** export, không class (per project convention)
- **SP naming**: `edoc.fn_lgsp_<entity>_<action>` — match dự án convention
- **Encrypted credential**: pgcrypto pgp_sym_encrypt với env var `SIGNING_SECRET_KEY`, decrypt lazy khi cần (KHÔNG decrypt ở repo, để service layer làm)
- **Repo Row interface** + `*Row` type cho mỗi bảng
- **Idempotent schema**: `CREATE TABLE IF NOT EXISTS`, `ALTER ... ADD COLUMN IF NOT EXISTS`, DROP+CREATE cho SPs với chính xác list (CLAUDE.md DB Migration Strategy)
- **Trigger naming**: `trg_<table>_<action>`, function `fn_<table>_<action>()`

### Integration Points

- **`departments` table** (existing) — Phase 33 ADD COLUMN `lgsp_org_code VARCHAR(13)` + UPDATE 6 root unit set H37.DN.001..006 (qua seed hoặc migration data)
- **`incoming_docs` table** (existing) — Phase 33 KHÔNG động trực tiếp, chỉ refer qua FK trong `lgsp_status_outbox.incoming_doc_id`
- **`lib/queue/client.ts`** (existing BullMQ) — Phase 33 KHÔNG dùng (worker jobs là Phase 34/35/36), nhưng schema outbox phải sẵn sàng cho Phase 36 worker consume
- **`backend/src/server.ts`** — Phase 33 KHÔNG mount route mới (admin UI là Phase 37), chỉ register `getLgspService` shared trong service registry nếu có

</code_context>

<specifics>
## Specific Ideas

- **Seed 9 row exact content** (từ Excel + List.txt user cung cấp):
  - Prod env (6 row, `base_url='https://apiltvb.langson.gov.vn'`):
    - DN.001: H37.DN.001 — Cty CP Hữu nghị Xuân Cương
    - DN.002: H37.DN.002 — Cty CP Sản xuất và Thương Mại Lạng Sơn
    - DN.003: H37.DN.003 — Cty CP Tập đoàn ĐT & XD Phú Lộc
    - DN.004: H37.DN.004 — Cty CP Kim loại màu Bắc Bộ
    - DN.005: H37.DN.005 — Cty TNHH TM XD Thiên Phú
    - DN.006: H37.DN.006 — Cty TNHH MTV Xe điện DK Việt Nhật
  - Sandbox env (3 row, `base_url='https://trucltvb.langson.gov.vn/apithunghiem'`):
    - DN.001, DN.002, DN.003 (cùng tên như prod)
  - Tất cả row `secret_key_encrypted = pgp_sym_encrypt('placeholder_not_configured', '<SIGNING_SECRET_KEY>')`, `is_active=FALSE`, `system_id = lgsp_org_code` (= H37.DN.00x)

- **Sample test cho `getLgspService(unit_id)`** sau Phase 33:
  ```ts
  const svc = await getLgspService(rootUnitIdOfDN001);
  // Returns LGSPRealService instance với placeholder credential
  // is_active=FALSE → service throw "LGSP not configured for this unit"
  // Sau admin UI Phase 37 nhập credential + bật is_active=TRUE → svc.login() works
  ```

- **CLAUDE.md `MANUAL_UPDATE_PROD.md` compliance**: Phase 33 schema thay đổi → apply re-master schema idempotent trên prod 6 DN, KHÔNG drop DB. Verify SP count ≥ baseline (Phase 11.1 v2.0.2 = 386 SPs + Phase 33 thêm ~5-10 SPs cho lgsp module).

</specifics>

<deferred>
## Deferred Ideas

- **Multi-instance cache invalidation qua Redis pub/sub** — defer khi scale ra cluster (hiện 1 instance đủ)
- **DLQ cho outbox failed events** — Future Requirement LGSP-DLQ v3.3+ đã list, Phase 33 chỉ có `sent_status='error'` flag, không tách DLQ table
- **Encryption key rotation tool** — pattern đã có cho `signing_provider_config`, sẽ áp dụng cùng khi rotate `SIGNING_SECRET_KEY`
- **MongoDB audit log `lgsp_audit`** — Future Requirement LGSP-AUDIT-LOG v3.3+
- **Auto-sync `inter_organizations` cron** — Future Requirement LGSP-AUTO-SYNC-CRON v3.3+

### Reviewed Todos (not folded)

None — không có todo backlog liên quan.

</deferred>

---

*Phase: 33-database-core-infrastructure*
*Context gathered: 2026-05-19 (auto-mode, user delegation full trust)*
*Next: /gsd-plan-phase 33 → /gsd-execute-phase 33 → tiếp Phase 34-37 qua /gsd-autonomous*
