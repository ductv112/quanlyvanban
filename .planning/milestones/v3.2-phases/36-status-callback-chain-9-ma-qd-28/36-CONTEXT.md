# Phase 36: Status Callback Chain (9 mã QĐ 28) - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning
**Mode:** Smart discuss (autonomous --from 35 resume) — user accepted all 4 area defaults; production-grade per user feedback "ko cần cắt giảm"

<domain>
## Phase Boundary

Mỗi khi văn thư/lãnh đạo/chuyên viên thực hiện hành động trên VB đến nguồn LGSP (`source_type='external_lgsp'`), route handler tự INSERT row vào `edoc.lgsp_status_outbox` với `target_status` tương ứng (02/03/04/05/06). Worker BullMQ poll tick mỗi 30s query rows pending → spawn child jobs per event → POST `/v1/updateStatus` lên trục với credential của DN sở hữu doc → update outbox sent_status=success/error.

**Trong scope:**
- Schema APPEND `000_schema_v3.0.sql` idempotent: UNIQUE constraint `(incoming_doc_id, target_status)` trên `lgsp_status_outbox` (dedup chống double-INSERT khi user trigger 2 lần)
- Fix `LGSPRealService.updateStatus()` Phase 18 (broken endpoint) → đúng `POST {baseUrl}/v1/updateStatus` JSON body `{docId, status}` headers X-SystemId/X-SecretKey (mirror Phase 34 sendDocument fix pattern)
- Repo `lgsp-status-outbox.repository.ts` extend với `insertEvent(doc_id, target_status, payload)` (swallow SQLSTATE 23505), `getPendingEvents(limit)`, `markSuccess(id)`, `markError(id, msg)`, `getDocStatusHistory(doc_id)`
- Route handler hook: 5 routes trong `backend/src/routes/incoming-doc.ts` + 1 trong `handling-doc.ts` extend gọi `lgspStatusOutboxRepository.insertEvent()` sau SP success NẾU doc source_type='external_lgsp':
  - PATCH `/:id/danh-dau-da-doc` → mã 03 (lần đầu mark read)
  - POST `/:id/giao-viec` → mã 04
  - POST `/:id/but-phe` → mã 05 (lần đầu)
  - POST `/:id/them-vao-hscv` → mã 05 (lần đầu, NOOP nếu 05 đã có)
  - POST `/:id/chuyen-luu-tru` → mã 06
  - handling-doc complete (`fn_handling_doc_complete`) → mã 06 (nếu doc cha là LGSP source)
  - POST `/:id/chuyen-lai` LGSP doc → mã 02 (từ chối tiếp nhận) — guard chỉ khi source_type='external_lgsp'
- BullMQ Queue `'lgsp-status'` + 2 worker:
  - `'status-tick'` concurrency=1 repeat 30s — query pending rows + enqueue child
  - `'status-event'` concurrency=5 retry 5x exp 30s — process 1 event: lookup credential, POST /v1/updateStatus, mark success/error
- Frontend detail VB đến: thêm section "Lịch sử trạng thái LGSP" hiển thị list từ `getDocStatusHistory()` (chỉ render khi source_type='external_lgsp')

**Ngoài scope (defer):**
- Mã 13 (lấy lại) + 15 (đồng ý lấy lại) + 16 (từ chối lấy lại) → Phase 37 (sender-side action, không thuộc receive flow Phase 35-36)
- Admin UI "Gửi lại" event error → Phase 37
- DLQ table tách → defer v3.3+
- Strict per-doc ordering serialize → defer (LGSP idempotent theo mã, loose FIFO chấp nhận)
- Auto-fire status từ MongoDB audit hook → defer v3.3+

</domain>

<decisions>
## Implementation Decisions

### Area 1: Action → Status Mapping + Trigger Point

- **D-01: Action → Mã QĐ 28 mapping table:**
  | Action | Route | Mã | Note |
  |---|---|---|---|
  | Mark read (lần đầu) | PATCH /:id/danh-dau-da-doc | 03 | First-time guard (UNIQUE outbox sẽ chặn duplicate) |
  | Assign work | POST /:id/giao-viec | 04 | Mỗi lần assign mới đều fire (nhưng UNIQUE chặn — chỉ 04 đầu tiên thực sự gửi) |
  | Annotate (but-phe) | POST /:id/but-phe | 05 | UNIQUE chặn |
  | Add to HSCV | POST /:id/them-vao-hscv | 05 | UNIQUE chặn — NOOP nếu đã có 05 từ but-phe |
  | Archive | POST /:id/chuyen-luu-tru | 06 | |
  | Handling-doc complete | (fn_handling_doc_complete trigger from POST handling-doc routes) | 06 | Hook gắn vào route handler handling-doc complete |
  | Reject (chuyen-lai LGSP) | POST /:id/chuyen-lai | 02 | Chỉ khi source_type='external_lgsp' |
  - Mã 13/15/16: defer Phase 37 sender-side
- **D-02:** Fire chỉ khi `incoming_docs.source_type='external_lgsp'`. Route handler PHẢI load doc record trước (đã có từ existing handlers — verify) + check source_type. KHÔNG INSERT outbox cho doc nội bộ (no callback target).
- **D-03:** Trigger WHERE = **Route handler sau SP success commit** (explicit + testable, mirror Phase 34). Pattern:
  ```ts
  const result = await someSpCall(...);
  if (!result.success) { handleError; return; }
  // After SP commit:
  if (doc.source_type === 'external_lgsp') {
    await lgspStatusOutboxRepository.insertEvent(docId, '03', { lgsp_doc_id: doc.external_doc_id, sender_org_code: doc.lgsp_sender_org_code });
  }
  res.json(...);
  ```
- **D-04:** Idempotency = **UNIQUE constraint `(incoming_doc_id, target_status)` trên `lgsp_status_outbox`**. Schema append `000_schema_v3.0.sql`:
  ```sql
  DO $$
  BEGIN
    BEGIN
      ALTER TABLE edoc.lgsp_status_outbox
        ADD CONSTRAINT uq_lgsp_status_outbox_doc_status UNIQUE (incoming_doc_id, target_status);
    EXCEPTION WHEN duplicate_object THEN NULL; WHEN duplicate_table THEN NULL; WHEN invalid_table_definition THEN NULL; WHEN duplicate_column THEN NULL;
    END;
  END $$;
  ```
  Repo `insertEvent()` try/catch SQLSTATE 23505 → log info "status callback dedup: <doc_id>/<status> already exists, skipped" → return null id. Worker handler skip null return.

### Area 2: Worker Architecture

- **D-05:** Mechanism = **BullMQ `Queue.add` với `repeat: { every: 30000 }`** (30s tick singleton job id `lgsp-status-tick-singleton`). Mirror Phase 35 cron pattern.
- **D-06:** Granularity = **Per-event job** (1 outbox row = 1 'status-event' job). Retry độc lập. Tick handler query pending + enqueue child.
- **D-07:** Concurrency:
  - Tick worker: concurrency=1
  - Event worker: **concurrency=5** (status update payload nhỏ ~200 bytes, parallel cao hơn Phase 35 dn=3 không spam vì RPC nhanh)
  - 2 Worker instances cùng queue `'lgsp-status'` filter by job.name
- **D-08:** LGSP API call:
  - `POST {baseUrl}/v1/updateStatus` JSON body `{ docId: string, status: string }`
  - Headers: `Content-Type: application/json`, `X-SystemId`, `X-SecretKey` (của DN sở hữu doc = `incoming_doc.unit_id` → lookup `lgsp_agency_config` qua `getLgspService(unit_id, env)`)
  - Status value: `target_status` đúng spec QĐ 28 ('01'..'16'). Postman sample dùng `"status": "done"` — verify nếu LGSP có 2 format (mã số vs từ khoá). Default dùng mã số. Adjust nếu LGSP reject.
  - Resolve environment: query `lgsp_agency_config WHERE unit_id=$1 AND is_active=true ORDER BY (environment='prod') DESC LIMIT 1` (giống Phase 34)

### Area 3: Error Handling + Retry

- **D-09:** Retry = **BullMQ `attempts: 5, backoff: { type: 'exponential', delay: 30000 }`** → 30s/60s/120s/240s/480s. Mirror Phase 34.
- **D-10:** Classification = **Reuse Phase 34 `isLgspNonRetryableError()` từ `services/lgsp/error-codes.ts`**:
  - 4xx LGSP error codes (10/15/18/19/20/21/22/23) → catch + mark error + KHÔNG throw (no retry)
  - Network/5xx → throw → BullMQ retry
  - Success (code 0) → markSuccess
- **D-11:** Retry exhausted = **outbox row update `sent_status='error', error_message='Retry exhausted: <last>', next_retry_at=NULL`**. on('failed') worker listener. Admin "Gửi lại" defer Phase 37 (sẽ set sent_status='pending' + next_retry_at=NOW reset retry_count).
- **D-12:** Ordering = **FIFO best-effort theo created_at**. Per-doc loose ordering chấp nhận — LGSP server idempotent theo mã. Tick handler `ORDER BY created_at ASC LIMIT 100` enqueue. KHÔNG strict serialize per-doc (overkill cho v3.2 small scale).

### Area 4: UI + Schema + Verification

- **D-13:** Schema thay đổi (append `000_schema_v3.0.sql` idempotent):
  - UNIQUE constraint `uq_lgsp_status_outbox_doc_status (incoming_doc_id, target_status)` — wrap DO block catch 4 SQLSTATE per Phase 33 pattern
  - Verify Phase 33 partial index `idx_lgsp_status_outbox_pending WHERE sent_status='pending'` + regular index `(incoming_doc_id, target_status, sent_at DESC)` còn (đã có)
  - Apply dev DB + verify lần 2 zero error
- **D-14:** UI VB đến detail page (extend Phase 35-04):
  - Conditional section "Lịch sử trạng thái LGSP" chỉ render khi `source_type='external_lgsp'`
  - Backend endpoint mới: `GET /api/van-ban-den/:id/lgsp-status-history` returns `[{ target_status, sent_status, sent_at, error_message, retry_count, created_at }]` ORDER BY created_at ASC
  - Helper map: `'01'='Đã gửi'`, `'02'='Từ chối tiếp nhận'`, `'03'='Tiếp nhận'`, `'04'='Phân công'`, `'05'='Đang xử lý'`, `'06'='Hoàn thành'`, `'13'='Lấy lại'`, `'15'='Đồng ý lấy lại'`, `'16'='Từ chối lấy lại'`
  - Render Timeline component (AntD `<Timeline>`) — sent_status badge: pending (orange spin), success (green check), error (red exclamation + tooltip error_message)
- **D-15:** Worker hosting = **`workers/` module** (mirror Phase 34+35):
  - NEW `workers/src/queues/lgsp-status-queue.ts` (Queue + constants)
  - NEW `workers/src/jobs/lgsp-status-tick-worker.ts` (concurrency=1)
  - NEW `workers/src/jobs/lgsp-status-event-worker.ts` (concurrency=5 retry 5x)
  - NEW `workers/src/lgsp/lgsp-status-service.ts` (worker-local service, mirror lgsp-send/receive-service pattern)
  - MODIFY `workers/src/index.ts` (start status workers + SIGTERM)
  - NEW `backend/src/lib/queue/lgsp-status-queue.ts` (backend producer + `registerStatusTickRepeatJob()` helper)
  - Backend server.ts startup gọi `registerStatusTickRepeatJob()` (mirror Phase 35-03)
  - SIGTERM extend close lgsp-status queue
- **D-16:** E2E test (gating Phase 36 verification):
  - DN.001 sandbox active + có ít nhất 1 incoming_doc source_type='external_lgsp' (có thể tạo manual qua DB INSERT cho test, hoặc reuse từ Phase 35 receive test nếu sandbox có doc)
  - Trigger các action sequence trên doc đó:
    1. PATCH `/:id/danh-dau-da-doc` → verify outbox INSERTED row target_status='03' sent_status='pending'
    2. wait ≤30s tick → verify sent_status='success' (hoặc credential rotation caveat giống Phase 34/35 — đều log)
    3. POST `/:id/giao-viec` body assign 1 staff → verify outbox 04 → success
    4. POST `/:id/but-phe` body comment → verify outbox 05 → success
    5. POST `/:id/chuyen-luu-tru` → verify outbox 06 → success
  - Dedup test: PATCH danh-dau-da-doc lần 2 → repo log skipped, KHÔNG có row 03 thứ 2
  - Error path: tạm UPDATE credential sai → giao-viec → outbox 04 enqueued → worker fail → sent_status='error' + retry_count populated. RESTORE credential sau test.
  - UI verify: detail page hiển thị section "Lịch sử trạng thái LGSP" với Timeline 4 entries (03/04/05/06) + badge

### Claude's Discretion

- Tên cột exact follow snake_case
- BullMQ queue name `'lgsp-status'`, job names `'status-tick'` + `'status-event'`, singleton id `'lgsp-status-tick-singleton'`
- Type interfaces: `LgspStatusTickJobData = Record<string, never>`, `LgspStatusEventJobData = { outbox_id: number; incoming_doc_id: number; unit_id: number; target_status: string; payload: Record<string, unknown> }`
- Worker pickup credential mỗi attempt (D-14 Phase 33 rotation pattern)
- Logging pino structured: tick_id, outbox_id, doc_id, target_status, sent_status
- Approach B duplicate (workers/ tự chứa) per Phase 34/35 ratified

### Folded Todos

None.

</decisions>

<canonical_refs>
## Canonical References

### LGSP API Spec (Postman authoritative)

- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/LTVB_API_TRUC_PROD_TICHHOP.postman_collection.json`:
  - `POST {baseUrl}/v1/updateStatus` JSON body `{docId, status}`, headers X-SystemId + X-SecretKey
  - Sample body: `{ "docId": "2ac3bb00-9469-4fdf-8f35-0a5f72348e4b", "status": "done" }` — verify nếu LGSP có alias mã số vs từ khoá
- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/HuongDanKetNoiLienThongVB_v2.2.pdf` — section "9 mã trạng thái QĐ 28"
- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/List.txt` — sandbox URL + 3 sandbox credential

### Code đã có (reuse)

- `e_office_app_new/backend/src/services/lgsp-real.service.ts` — Phase 18 method `updateStatus()` SAI endpoint, Phase 36 fix giống cách Phase 34 fix sendDocument
- `e_office_app_new/backend/src/services/lgsp.service.ts` — factory `getLgspService(unit_id, env)` reuse
- `e_office_app_new/backend/src/services/lgsp/error-codes.ts` Phase 34 — reuse `LgspSendError` + `mapLgspError` + `isLgspNonRetryableError`
- `e_office_app_new/backend/src/lib/queue/{lgsp-send-queue, lgsp-receive-queue}.ts` — pattern reference (Phase 36 mirror sang lgsp-status-queue)
- `e_office_app_new/workers/src/queues/{lgsp-send-queue, lgsp-receive-queue}.ts` — pattern reference
- `e_office_app_new/workers/src/jobs/{lgsp-send-worker, lgsp-receive-{tick,dn}-worker}.ts` — pattern reference
- `e_office_app_new/workers/src/lgsp/{edxml-builder, edxml-parser, error-codes, lgsp-send-service, lgsp-receive-service}.ts` — pattern reference (Phase 36 thêm lgsp-status-service)
- `e_office_app_new/database/schema/000_schema_v3.0.sql`:
  - `edoc.lgsp_status_outbox` table Phase 33 đã có (id, incoming_doc_id, target_status, payload, sent_status, retry_count, next_retry_at, error_message, sent_at, created_at)
  - CHECK constraint target_status IN ('01'..'16') đã có
  - Index partial pending + regular per-doc đã có
  - Phase 36 APPEND: UNIQUE constraint (incoming_doc_id, target_status)
- `e_office_app_new/backend/src/repositories/lgsp-status-outbox.repository.ts` (Phase 33 đã tạo basic — verify có hay extend)
- `e_office_app_new/backend/src/repositories/incoming-doc.repository.ts` — load doc.source_type cho route handler check (Phase 17 + Phase 35 đã expose field)
- `e_office_app_new/backend/src/routes/incoming-doc.ts` — 5 routes extend hook outbox INSERT
- `e_office_app_new/backend/src/routes/handling-doc.ts` — extend complete route hook outbox 06
- `e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx` — extend Phase 35-04 detail section thêm Timeline
- `e_office_app_new/backend/src/server.ts` — startup gọi `registerStatusTickRepeatJob()`, SIGTERM close queue

### Phase 33/34/35 SUMMARYs

- `.planning/phases/33-database-core-infrastructure/33-05-SUMMARY.md` — schema lgsp_status_outbox baseline
- `.planning/phases/34-send-flow-sendedoc/34-02-SUMMARY.md` — BullMQ pattern + Approach B
- `.planning/phases/34-send-flow-sendedoc/34-05-VERIFICATION-REPORT.md` — verification template
- `.planning/phases/35-receive-flow-cron-syncreceivededoclist/35-02-SUMMARY.md` — tick+event 2-worker pattern (closest analog cho Phase 36)
- `.planning/phases/35-receive-flow-cron-syncreceivededoclist/35-03-SUMMARY.md` — server.ts startup + SIGTERM extend pattern
- `.planning/phases/35-receive-flow-cron-syncreceivededoclist/35-05-VERIFICATION-REPORT.md` — verification template

### Project rules

- `CLAUDE.md` § "DB Migration Strategy" — append schema master idempotent
- `CLAUDE.md` § "Customer-Facing Scope" — menu LGSP còn ẩn
- `CLAUDE.md` § "Phase Execution Rules" — wave-based parallel safety
- `CLAUDE.md` § "Deploy Pitfalls" #11 — interactive prompt KHÔNG có cho production scripts
- Memory `project_production_ready.md` (validated 2026-05-20) — "Giữ kiến trúc, không cắt giảm"

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `getLgspService(unit_id, env)` factory
- `LgspSendError` + `mapLgspError` + `isLgspNonRetryableError` error-codes (Phase 34)
- `lgspAgencyConfigRepository.getAllActive()`, `getByUnitId(unit_id, env)` (Phase 33+35)
- `incomingDocRepository.getById()` returns full doc incl `source_type`, `external_doc_id`, `lgsp_sender_org_code` (Phase 35-04)
- BullMQ Queue + Worker pattern x3 plans (Phase 34+35)
- `pool.query` raw SQL pattern Phase 35-02 worker
- `minioClient` (KHÔNG cần Phase 36 — status update không có attachment)
- pino structured log

### Established Patterns

- Repository const object
- ESM `.js` imports
- Native fetch
- BullMQ retry `{ attempts: 5, backoff: { type: 'exponential', delay: 30000 } }`
- Approach B duplicate workers/ (ratified)
- Backend `lib/queue/<name>-queue.ts` = producer + register helper. workers/src/queues/<name>-queue.ts = constants/types.

### Integration Points

- 5 existing routes incoming-doc + 1 handling-doc — extend với hook INSERT outbox
- `lgsp_status_outbox` table Phase 33 (extend với UNIQUE)
- `workers/src/index.ts` register status workers
- `backend/src/server.ts` startup register cron + SIGTERM extend
- Frontend detail page Phase 35-04 extend Timeline section

</code_context>

<specifics>
## Specific Ideas

- **Route handler hook pattern** (mirror cho 6 routes):
  ```ts
  // After SP success commit:
  const doc = await incomingDocRepository.getById(docId, staffId);
  if (doc.source_type === 'external_lgsp') {
    try {
      await lgspStatusOutboxRepository.insertEvent({
        incoming_doc_id: docId,
        target_status: '03',  // mark-read example
        payload: {
          lgsp_doc_id: doc.external_doc_id,
          sender_org_code: doc.lgsp_sender_org_code,
        },
      });
      logger.info({ doc_id: docId, target_status: '03' }, 'LGSP status outbox enqueued');
    } catch (err) {
      logger.warn({ err, doc_id: docId, target_status: '03' }, 'Failed to enqueue LGSP status outbox — action still succeeded');
      // KHÔNG fail request — status callback là async best-effort
    }
  }
  res.json({ success: true, ... });
  ```

- **Worker event handler skeleton:**
  ```ts
  async function handleStatusEvent(job: Job<LgspStatusEventJobData>) {
    const { outbox_id, incoming_doc_id, unit_id, target_status, payload } = job.data;
    const env = await resolveLgspEnvironment(unit_id);
    if (!env) {
      await markOutboxError(outbox_id, 'LGSP not configured for unit');
      return;  // no retry
    }
    const svc = createLgspStatusService(unit_id, env);
    try {
      await svc.updateStatus(payload.lgsp_doc_id as string, target_status);
      await markOutboxSuccess(outbox_id);
      logger.info({ outbox_id, doc_id: incoming_doc_id, target_status }, 'LGSP status updated');
    } catch (err) {
      if (err instanceof LgspSendError && isLgspNonRetryableError(err)) {
        await markOutboxError(outbox_id, `LGSP code ${err.code}: ${err.message}`);
        return;
      }
      throw err;  // BullMQ retry
    }
  }
  ```

- **History UI Timeline pattern (AntD):**
  ```tsx
  <Timeline mode="left">
    {history.map(h => (
      <Timeline.Item
        key={h.id}
        color={h.sent_status === 'success' ? 'green' : h.sent_status === 'error' ? 'red' : 'gray'}
        label={dayjs(h.created_at).format('DD/MM HH:mm')}
      >
        <Tag>{statusLabel(h.target_status)}</Tag>
        {h.sent_status === 'pending' && <Spin size="small" />}
        {h.sent_status === 'error' && (
          <Tooltip title={h.error_message}>
            <Tag color="red">Lỗi</Tag>
          </Tooltip>
        )}
        {h.sent_status === 'success' && <Tag color="green">Đã gửi</Tag>}
      </Timeline.Item>
    ))}
  </Timeline>
  ```

</specifics>

<deferred>
## Deferred Ideas

- Mã 13/15/16 (lấy lại) → Phase 37 sender-side (admin retract sent doc)
- Admin UI "Gửi lại" event error → Phase 37
- DLQ tách bảng → defer v3.3+
- Strict per-doc ordering serialize → defer (loose FIFO chấp nhận)
- Auto-fire status từ MongoDB audit hook → defer v3.3+
- Bulk batch update API (>10 status cùng lần) → defer (LGSP /v1/updateStatus single-doc)

### Reviewed Todos (not folded)

None.

</deferred>

---

*Phase: 36-status-callback-chain-9-ma-qd-28*
*Context gathered: 2026-05-21 (smart discuss, user accept all 4 defaults, production-grade per memory)*
*Next: /gsd-plan-phase 36 → /gsd-execute-phase 36 → tiếp Phase 37*
