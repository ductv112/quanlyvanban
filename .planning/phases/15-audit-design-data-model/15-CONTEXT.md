# Phase 15: Audit & design data model — Context

**Gathered:** 2026-04-23 (auto-mode, recommended defaults)
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 15 produces **DESIGN.md** — a comprehensive data model design document for v3.0 schema rebuild. Output is **design documentation only** — no SQL execution, no DB reset, no code changes. Phase 16 will implement the design.

The design document must cover:
- Schema changes for 3 core tables (`incoming_docs`, `outgoing_docs`, `drafting_docs`)
- New tables (`outgoing_doc_recipients`, `inter_organizations`)
- Tables to drop and merge (`inter_incoming_docs` → `incoming_docs`)
- Lifecycle workflow (Drafting → Ban hành → Gửi)
- Stored procedure signatures (preview)
- ERD diagram
- Migration strategy
- Breaking change impact analysis on downstream modules (HSCV, ký số, dashboard, báo cáo)

**Out of scope (deferred to other phases):**
- Phase 16: Schema implementation (write SQL)
- Phase 17: SP implementation + UI 2 button "Ban hành"/"Gửi"
- Phase 18: Real LGSP HTTP client
- Phase 19: UI form rewrite + menu consolidation
- Phase 20: Regression + UAT

</domain>

<decisions>
## Implementation Decisions

### Schema Strategy

- **D-01:** Reset DB clean — không migration script preserve data v2.0 (user approved 2026-04-23). Bump master schema file `database/schema/000_schema_v2.0.sql` → `database/schema/000_schema_v3.0.sql`. Move v2.0 schema sang `database/archive/v2.0-finalized/`.
- **D-02:** Schema vẫn idempotent (DROP IF EXISTS + CREATE OR REPLACE) — apply lại an toàn, không overload SP.
- **D-03:** Giữ pattern targeted DROP (DROP cụ thể từng SP signature, không dùng `LIKE 'fn_%'` broad — bài học Phase 11.1).

### Data Model — incoming_docs

- **D-04:** Thêm `source_type` ENUM với 3 values: `'internal'` (gửi nội bộ trong tỉnh) / `'external_lgsp'` (nhận qua LGSP) / `'manual'` (nhập tay từ giấy hoặc import). Default = `'manual'` cho backward compat khi nhập mới.
- **D-05:** Thêm `is_unit_send BOOLEAN DEFAULT FALSE` + `unit_send VARCHAR(500)` để phân biệt rõ "Cơ quan ban hành" (publish_unit, ai ký) vs "Nơi gửi" (unit_send, ai chuyển đến).
- **D-06:** Thêm `previous_outgoing_doc_id BIGINT` (NULL FK trỏ về `outgoing_docs.id` ON DELETE SET NULL) — trace ngược văn bản đến nội bộ về outgoing gốc của Sở A.
- **D-07:** Thêm `external_doc_id VARCHAR(100)` — lưu LGSP doc id để dedupe khi worker pull về (UNIQUE INDEX khi `source_type='external_lgsp'`).
- **D-08:** Gộp tất cả cột recall flow (`recall_reason`, `recall_requested_at`, `recall_response`, `recall_responded_at`, `status_before_recall`) từ `inter_incoming_docs` cũ vào `incoming_docs`. Recall logic chỉ apply khi `source_type='external_lgsp'`.

### Data Model — outgoing_docs + drafting_docs

- **D-09:** `outgoing_docs` tách 2 cột riêng: `drafting_unit_id BIGINT NOT NULL FK departments.id` (đơn vị soạn) + `publish_unit_id BIGINT NOT NULL FK departments.id` (cơ quan ban hành — có thể chọn cấp trên).
- **D-10:** `outgoing_docs` thêm `is_released BOOLEAN DEFAULT FALSE` + `released_date TIMESTAMPTZ` để track bước "Ban hành" tách khỏi "Gửi".
- **D-11:** `drafting_docs` thêm cùng 2 cột `is_released` + `released_date` để track lifecycle drafting → outgoing.
- **D-12:** `outgoing_docs` + `drafting_docs` thêm `previous_outgoing_doc_id BIGINT` (NULL FK self/cross) — track bản chỉnh sửa lại sau khi đã ban hành.

### Data Model — Approver/Approved

- **D-13:** Approver dùng **VARCHAR(255) text** thay FK staff_id — match source .NET cũ, đơn giản hiển thị, không cần JOIN. Set khi click "Duyệt" với `approver=current_user.full_name`.
- **D-14:** Approved boolean 3 trạng thái: `NULL` (chưa duyệt) / `FALSE` (bỏ duyệt) / `TRUE` (đã duyệt). Không multi-level workflow — defer v3.1.
- **D-15:** Thêm `approved_at TIMESTAMPTZ NULL` — timestamp action duyệt (audit purpose).

### Data Model — Recipients

- **D-16:** Bảng mới `outgoing_doc_recipients` với 1 bảng cho cả 2 loại recipient (recipient_type ENUM `'internal_unit' | 'external_org'`). Lý do: query đơn giản, source cũ cũng dùng pattern ListRecipients chung.
- **D-17:** Schema:
  ```
  outgoing_doc_recipients (
    id BIGSERIAL PK,
    outgoing_doc_id BIGINT NOT NULL FK outgoing_docs.id ON DELETE CASCADE,
    recipient_type ENUM('internal_unit','external_org') NOT NULL,
    recipient_unit_id BIGINT NULL FK departments.id,    -- NOT NULL khi internal_unit
    recipient_org_id BIGINT NULL FK inter_organizations.id, -- NOT NULL khi external_org
    sent_at TIMESTAMPTZ NULL,
    sent_status VARCHAR(20) DEFAULT 'pending',  -- pending/sent/failed
    error_message TEXT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CHECK (
      (recipient_type='internal_unit' AND recipient_unit_id IS NOT NULL AND recipient_org_id IS NULL) OR
      (recipient_type='external_org' AND recipient_org_id IS NOT NULL AND recipient_unit_id IS NULL)
    )
  )
  ```
- **D-18:** Bảng mới `inter_organizations` cho danh mục cơ quan LGSP ngoài tỉnh (parent của recipient_org_id). Schema:
  ```
  inter_organizations (
    id BIGSERIAL PK,
    code VARCHAR(50) UNIQUE NOT NULL,        -- mã cơ quan
    name VARCHAR(500) NOT NULL,              -- tên cơ quan
    lgsp_organ_id VARCHAR(100) NULL,         -- mã LGSP gốc (cho gửi/nhận)
    parent_id BIGINT NULL FK inter_organizations.id, -- cây cơ quan
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
  )
  ```
- **D-19:** Seed `inter_organizations` từ Phase 16 với 8 cơ quan demo (giữ data hiện có ở `lgsp_organizations`). Sync thật từ LGSP `/organizations/sync` endpoint defer Phase 18 khi có credentials thật.

### Lifecycle Workflow

- **D-20:** Drafting status (text VARCHAR): `'draft'` → `'reviewing'` (optional) → `'approved'` → `'released'` (đã ban hành thành Outgoing). Giữ `is_released` boolean để query nhanh + match source cũ.
- **D-21:** Outgoing status (text VARCHAR): `'draft'` (chưa ban hành) → `'released'` (đã ban hành, chưa gửi) → `'sent'` (đã gửi cho recipients) → `'completed'` (tất cả recipients confirmed). Giữ `is_released` boolean.
- **D-22:** Incoming status giữ nguyên hiện tại (`pending` → `received` → `completed` / `returned` / `recall_*`). Recall flow chỉ apply khi `source_type='external_lgsp'`.

### Stored Procedure Preview (cho Phase 17)

- **D-23:** SP signatures dự kiến trong DESIGN.md (chỉ preview, implement Phase 17):
  - `fn_outgoing_doc_release(p_outgoing_doc_id BIGINT, p_user_id BIGINT) RETURNS TABLE(success BOOL, message TEXT, number INT)`
  - `fn_outgoing_doc_send(p_outgoing_doc_id BIGINT, p_user_id BIGINT) RETURNS TABLE(success BOOL, message TEXT, internal_count INT, external_count INT)`
  - `fn_drafting_doc_approve(p_drafting_doc_id BIGINT, p_user_id BIGINT, p_approver_name TEXT) RETURNS TABLE(success BOOL, message TEXT)`
  - `fn_drafting_doc_unapprove(p_drafting_doc_id BIGINT, p_user_id BIGINT) RETURNS TABLE(success BOOL, message TEXT)`
  - `fn_outgoing_doc_recipients_create(p_outgoing_doc_id BIGINT, p_recipients JSONB) RETURNS INT` — bulk insert từ JSON array

### Breaking Change Mitigation

- **D-24:** DESIGN.md phải liệt kê các module xuống dòng bị ảnh hưởng + plan mitigation:
  - **HSCV:** liên kết `incoming_docs` qua FK — verify status text values mới không vỡ filter
  - **Ký số:** `attachments` link tới `outgoing_docs.id` + `drafting_docs.id` — không thay đổi PK, OK
  - **Dashboard widgets:** count statistics — verify SP `fn_dashboard_*` còn dùng đúng cột
  - **Reports:** Excel export — verify column names match
  - **API consumers (frontend pages cũ):** verify response shape không break
- **D-25:** Phase 20 sẽ regression test toàn bộ — DESIGN.md flag những module có high risk.

### Claude's Discretion

- ENUM PostgreSQL syntax: dùng native ENUM type (`CREATE TYPE source_type_enum AS ENUM (...)`) hay dùng VARCHAR + CHECK constraint — Claude pick dựa trên existing pattern trong schema (default native ENUM cho extensible)
- Index strategy chi tiết (covering index, partial index) — Claude design dựa trên query pattern
- ERD diagram format (mermaid vs ASCII art vs PlantUML) — Claude pick mermaid (đã dùng trong PROJECT.md)

### Folded Todos

None — không có todo backlog cho phase này, requirements lấy từ REQUIREMENTS.md DM-01..DM-08.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### v3.0 Requirements & Project Context
- `.planning/REQUIREMENTS.md` — 29 REQ-IDs v3.0 (DM×8, WF×5, LGSP×5, UI×8, QA×3)
- `.planning/PROJECT.md` — Goal v3.0, decisions table, constraints
- `.planning/ROADMAP.md` §Phase 15 — Goal + Success Criteria 7 items
- `.planning/STATE.md` — Milestone v3.0 reference docs

### v2.0 Archive (cho schema baseline + decisions context)
- `.planning/milestones/v2.0-MILESTONE-AUDIT.md` — Tech debt deferred sang v3.0
- `.planning/milestones/v2.0-ROADMAP.md` — v2.0 phase context
- `e_office_app_new/database/schema/000_schema_v2.0.sql` — Master schema HIỆN TẠI (20,168 dòng) — baseline để diff design v3.0

### Source .NET cũ (nghiệp vụ reference — MANDATORY đọc trước khi design)
- `docs/source_code_cu/sources/OneWin.Data.Object/Base/edoc/IncomingDoc.cs` — schema reference incoming
- `docs/source_code_cu/sources/OneWin.Data.Object/Base/edoc/OutgoingDoc.cs` — schema reference outgoing
- `docs/source_code_cu/sources/OneWin.Data.Object/Base/edoc/DraftingDoc.cs` — schema reference drafting
- `docs/source_code_cu/sources/OneWin.Data.Services/Implementations/edoc/UserDraftingDocService.cs` (line 99-117) — Released() method reference
- `docs/source_code_cu/sources/OneWin.Data.Services/Implementations/edoc/UserOutgoingDocService.cs` — Send() method + ListRecipients pattern
- SP cũ: `[edoc].[Prc_OutgoingDocSave]`, `[edoc].[Prc_DraftingDocReleased]`, `[edoc].[Prc_UserOutgoingDocSend]` — search trong `docs/source_code_cu/sources/Database/`

### LGSP Integration (cho Phase 18 reference, Phase 15 chỉ design schema cờ)
- `docs/source_code_cu/sources/LGSP-LANGSON-API-GUIDE.md` — endpoints + auth
- `docs/source_code_cu/sources/LGSP-Token-Manager-Example.cs` — token cache pattern

### CLAUDE.md project rules (MANDATORY)
- `CLAUDE.md` §"DB Migration Strategy (v2.0+)" — schema bump rules, idempotent pattern, drop pattern không broad
- `CLAUDE.md` §"Phase Execution Rules (Bài học từ Phase 4-5)" — wave-based parallel rules
- `CLAUDE.md` §"Checklist lỗi thường gặp" — field name mismatch, reserved words, FK conventions

### Codebase intel
- `.planning/codebase/` (nếu có) — đọc tất cả `*.md` trong này để biết existing patterns

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`database/schema/000_schema_v2.0.sql`** (20,168 dòng): Master schema hiện tại — Phase 15 design dựa trên file này, Phase 16 sẽ rewrite thành `000_schema_v3.0.sql`
- **`database/seed/001_required_data.sql` + `002_demo_data.sql`**: Seed pattern idempotent — Phase 16 sẽ update `002_demo_data.sql` cho schema mới (50 incoming demo + recipients demo)
- **Pattern `IF NOT EXISTS` + `DROP IF EXISTS` + `ADD CONSTRAINT IF NOT EXISTS`**: Apply trong Phase 11.1 master schema — Phase 16 dùng lại
- **DO block catch 4 SQLSTATE codes** (42710, 42P07, 42P16, 42701): Pattern idempotent migration — Phase 16 reuse

### Established Patterns
- **Stored Procedures, KHÔNG ORM**: Mọi business logic + validation trong SP, repository chỉ là wrapper typed
- **Schema naming**: `public` (system), `edoc` (document business), `esto` (archive), `cont` (contract), `iso` (ISO docs)
- **Repository pattern**: `*-Row interface` exact match SP RETURNS TABLE column names (snake_case), no alias
- **Status text VARCHAR**: Source cũ + v2.0 đều dùng VARCHAR + CHECK thay ENUM PostgreSQL — Phase 15 cân nhắc native ENUM cho v3.0 (cleaner, type-safe)
- **soft delete**: KHÔNG dùng nhất quán (incoming_docs/outgoing_docs/handling_docs KHÔNG có `is_deleted`) — Phase 15 phải confirm policy

### Integration Points
- **HSCV** (`handling_docs` + `attachment_handling_docs`): liên kết qua `attachment_handling_docs.handling_doc_id`. Verify schema HSCV không phụ thuộc trực tiếp vào `inter_incoming_docs`.
- **Ký số v2.0** (`sign_transactions` + `attachments` polymorphic): `attachments.entity_type` ∈ {'incoming','outgoing','drafting','handling'} — không thay đổi enum này, an toàn.
- **Dashboard SP** (`fn_dashboard_stats_*`): Phase 15 verify SP đếm đúng `incoming_docs` mới (gộp internal+lgsp+manual) — có thể cần GROUP BY `source_type`.
- **Báo cáo Excel export** (`reports/*.repository.ts`): query columns explicit — verify alias không break.

### Đặc biệt cần check trong Phase 15
- Bảng `lgsp_tracking` hiện có (Phase 11) — có giữ nguyên hay merge với `outgoing_doc_recipients.sent_status`? **Recommended:** giữ riêng vì lgsp_tracking là transport-level (request/response), recipients là business-level (mapping).
- Bảng `lgsp_organizations` hiện có — đổi tên thành `inter_organizations` cho consistency (theo D-18). Migrate data trong Phase 16.
- Cột `IsHandling`, `IsInterDoc`, `MoveAnnouncement` trong source cũ — REMOVE khỏi schema mới (không dùng) hay giữ? **Recommended:** REMOVE để clean (reset DB rồi không sợ vỡ).

</code_context>

<specifics>
## Specific Ideas

### User-confirmed in session 2026-04-23

1. **Phân biệt 3 trường rõ ràng** trong incoming_docs:
   - "Cơ quan ban hành" (`publish_unit` text/FK) = ai ký văn bản gốc
   - "Nơi gửi" (`unit_send` text + `is_unit_send` flag) = ai chuyển đến tay mình
   - "Nơi nhận" (`recipients` text) = phòng/người trong đơn vị mình xử lý

2. **Outgoing có 2 action riêng biệt:**
   - "Ban hành" (Release): cấp số `number` từ `doc_book`, set `is_released=true`, **CHƯA gửi đi**
   - "Gửi" (Send): loop recipients → INSERT incoming_docs (nội bộ) hoặc đẩy LGSP (ngoài)

3. **Auto-sinh Incoming nội bộ:**
   - Khi Sở A "Gửi" outgoing với recipient là Sở B (internal_unit) → SP `fn_outgoing_doc_send` tự INSERT `incoming_docs` cho Sở B với:
     - `source_type='internal'`
     - `unit_send='Sở A'` + `is_unit_send=true`
     - `publish_unit='Sở A'` (hoặc cơ quan publish của outgoing gốc)
     - `previous_outgoing_doc_id=outgoing.id`
     - `unit_id=Sở B.id` (đơn vị nhận)
   - Sở B mở `/van-ban-den` → thấy ngay văn bản này

4. **Bỏ menu sidebar "Văn bản liên thông"** — gộp vào `/van-ban-den`:
   - Filter `source_type` (tất cả / nội bộ / LGSP / nhập tay)
   - Badge tag màu khác cho mỗi `source_type`
   - Workflow recall (thu hồi LGSP) chuyển vào trang chi tiết `/van-ban-den/[id]`

5. **Approver/Approved 1 cấp boolean** như source cũ, không multi-level workflow:
   - Drafting có nút "Duyệt" / "Bỏ duyệt"
   - `approved=true` mới cho phép "Ban hành"
   - Multi-level approval (Trưởng phòng → Phó GĐ → Giám đốc) defer v3.1

### Reference docs đã verify trong session
- Source .NET schema 3 bảng (báo cáo agent đã extract đầy đủ field names)
- Flow Drafting → Outgoing → Incoming với 2 bước riêng (Release vs Send)
- LGSP polling pattern (Windows Service mỗi 1 phút trong source cũ)

</specifics>

<deferred>
## Deferred Ideas

### Defer v3.1+
- **Multi-level approval workflow** (Trưởng phòng → Phó GĐ → Giám đốc) với `approval_chains` + `approval_logs` tables — defer khi KH yêu cầu
- **LGSP credentials production thật** cho Lào Cai — defer khi có thông tin từ KH
- **Audit log đầy đủ cho approval actions** trong MongoDB — defer (hiện chỉ có `approved_at` timestamp)
- **Migration data v2.0 → v3.0** (preserve incoming/outgoing cũ) — user explicit chọn reset DB clean

### Defer trong v3.0 (phase sau Phase 15)
- **SP implementation** — Phase 17
- **Real LGSP HTTP client** — Phase 18
- **UI form rewrite + recipient picker component** — Phase 19
- **Regression + UAT** — Phase 20

### Reviewed Todos (not folded)
None — không có pending todos cho phase này.

</deferred>

---

*Phase: 15-audit-design-data-model*
*Context gathered: 2026-04-23 (auto-mode)*
