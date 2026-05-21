# Phase 33: Database + Core Infrastructure - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-19
**Phase:** 33-database-core-infrastructure
**Areas presented:** Encryption key strategy, Cache invalidation strategy, Seed strategy production credentials, Unit_id validation
**Mode:** Auto (user delegation full trust)

---

## User Response to Gray Area Selection

> "Tôi cũng ko hiểu đâu nên ko cần discuss, bạn cứ tự đọc toàn bộ tài liệu tôi đã cung cấp, hướng dẫn, code mẫu... sử dụng các thông tin tôi đã cung cấp và tự động thực hiện. Khi nào hoàn thành toàn bộ thì tôi sẽ chạy thử và test."

→ Skip interactive discuss. Auto-decide tất cả gray areas dùng best judgment + project context.

---

## Encryption Key Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse SIGNING_SECRET_KEY | Chung env var với signing_provider_config | ✓ |
| LGSP_SECRET_KEY riêng | Separate key, leak isolation tốt hơn | |

**Decision:** Reuse SIGNING_SECRET_KEY
**Rationale:** Pattern đã verify trên prod KH (signing module). CLAUDE.md pitfall #14 đã document setup + rotation. Trade-off: 1 key lộ = cả 2 module lộ — chấp nhận vì ops simpler.

---

## Cache Invalidation Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| TTL only (5 phút) | Wait expire, simple | |
| Invalidate-on-write | Admin update → gọi invalidate ngay | ✓ |
| Redis pub/sub multi-instance | Broadcast invalidation | |

**Decision:** Invalidate-on-write + TTL 5 phút làm safety net
**Rationale:** TTL-only có 5 phút stale window — UX kém. Pub/sub overkill cho 1 instance hiện tại (defer khi scale).

---

## Seed Strategy Production Credentials

| Option | Description | Selected |
|--------|-------------|----------|
| Seed empty placeholder + admin nhập UI | Production-safe, không leak credential | ✓ |
| Seed từ env vars expand SQL | Phức tạp, rủi ro typo | |
| Seed file ignored | Khó deploy reproducibility | |

**Decision:** Seed empty placeholder (9 row: 6 prod + 3 sandbox, `is_active=FALSE`, encrypted placeholder text)
**Rationale:** Pattern đã verify (signing_provider_config seed row VNPT + MySign placeholder). KHÔNG commit credential nhạy cảm.

---

## Unit_id Validation (root unit only)

| Option | Description | Selected |
|--------|-------------|----------|
| Soft validation UI only | Admin UI Select chỉ show root | |
| CHECK constraint inline | Không gọi được subquery → không khả thi | |
| Trigger BEFORE INSERT/UPDATE | DB enforce + UI guard | ✓ |
| Both soft UI + DB trigger | Best of both | ✓ |

**Decision:** Soft validation ở admin UI (Phase 37) + DB trigger enforce
**Rationale:** UI alone không đủ — dirty insert/script có thể bypass. Trigger pattern đã có ở SPs khác.

---

## FK Delete Behavior (Claude's Discretion)

- `lgsp_agency_config.unit_id FK departments(id)` → **ON DELETE RESTRICT**
- `lgsp_status_outbox.incoming_doc_id FK incoming_docs(id)` → **ON DELETE CASCADE**

**Rationale:** Departments rarely deleted (safer block). Outbox event mồ côi vô nghĩa (cascade).

---

## Outbox Indexing (Claude's Discretion)

- Partial index `WHERE sent_status='pending' ORDER BY created_at`
- Regular index `(incoming_doc_id, target_status, sent_at DESC)` cho UI history query

**Rationale:** Worker poll mỗi 30s → partial index optimize cực tốt.

---

## Refactor Phase 18 LGSPRealService (Claude's Discretion)

Phase 18 singleton đọc env → Phase 33 refactor:
- Constructor nhận `{ baseUrl, systemId, secretKey }` parameter
- Factory `getLgspService(unit_id)` lookup credential + instantiate + cache

**Rationale:** Reuse Phase 18 OAuth2 + REST client code, chỉ tách credential parameter.

---

## Schema Versioning (Claude's Discretion)

Edit trực tiếp `database/schema/000_schema_v3.0.sql` (KHÔNG tạo migration rời).

**Rationale:** Per CLAUDE.md DB Migration Strategy v2.0+ — bắt buộc.

---

## Deferred Ideas

- Multi-instance cache invalidation qua Redis pub/sub
- DLQ cho outbox failed events
- Encryption key rotation tool
- MongoDB audit log `lgsp_audit`
- Auto-sync `inter_organizations` cron
