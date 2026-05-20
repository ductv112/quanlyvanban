# Phase 35: Receive Flow (cron syncReceivedEdocList) - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning
**Mode:** Smart discuss (autonomous --from 34) — user accepted all 4 area defaults; user feedback validated production-grade architecture, KHÔNG cắt giảm

<domain>
## Phase Boundary

Worker BullMQ repeat job mỗi 5 phút loop tất cả DN có `lgsp_agency_config.is_active=TRUE`, gọi LGSP API `GET /v1/syncReceivedEdocList` lấy danh sách VB mới (incremental theo `last_synced_at`), `GET /v1/getEdoc` tải edXML từng cái, parse + map → INSERT `incoming_docs` với dedup, upload attachment lên MinIO. Văn thư của 6 DN thấy VB từ trục trong vòng ≤5 phút trong tab "Văn bản đến".

**Trong scope:**
- Fix `LGSPRealService.receiveDocuments()` (Phase 18) → real API endpoints `/v1/syncReceivedEdocList` + `/v1/getEdoc` với headers `X-SystemId` + `X-SecretKey` (mirror Phase 34 fix)
- BullMQ repeat job `lgsp-receive-tick` mỗi 5 phút → spawn child jobs `lgsp-receive-dn` per active DN
- Worker `workers/src/jobs/lgsp-receive-worker.ts` consume child job: gọi syncReceivedEdocList → loop docs → getEdoc full → parse edXML → upload attachments MinIO → INSERT incoming_docs + attachments → INSERT outbox status='01' (cho Phase 36)
- edXML parser module: `services/lgsp/edxml-parser.ts` (mirror builder pattern Phase 34)
- Schema: ADD COLUMN `incoming_docs.lgsp_sender_org_code VARCHAR(13) NULL` + index, append `database/schema/000_schema_v3.0.sql` idempotent
- Repo `incoming-doc.repository.ts` extend: `createFromLgsp(dataFromEdxml)` method + handle SQLSTATE 23505 unique violation → skip + log
- Auto-INSERT new sender vào `inter_organizations` nếu chưa có (set is_active=false, admin verify sau)
- Backend route `POST /api/lgsp/sync-now` (admin only, Phase 37 sẽ wire UI button) — enqueue 1 immediate parent tick
- UI VB đến: tag "LGSP" cho row source_type='external_lgsp', filter dropdown nguồn (Nội bộ / LGSP / Manual)

**Ngoài scope (defer):**
- Admin UI "Sync ngay" button → Phase 37 (Phase 35 chỉ API endpoint)
- Auto fire status callback `01 đã nhận` lên trục → Phase 36 (Phase 35 chỉ INSERT outbox)
- Status callback `02/03/04/05/06/13/15/16` → Phase 36
- Menu LGSP unhide → Phase 37
- Toast notification realtime khi VB mới đến → defer v3.3+
- Auto-sync `inter_organizations` cron riêng → defer v3.3+ (Phase 35 chỉ auto-INSERT on receive)
- DLQ table → defer v3.3+

</domain>

<decisions>
## Implementation Decisions

### Area 1: Cron Architecture

- **D-01:** Cron mechanism = **BullMQ Queue.add với `repeat: { every: 300000 }`** (5 phút). Reuse Phase 34 BullMQ infra (Redis connection, Queue/Worker pattern). KHÔNG dùng setInterval/node-cron — anh đã chốt giữ kiến trúc.
- **D-02:** Job granularity = **Parent "tick" job → spawn N child "sync-dn" jobs** (1 per active DN). Cấu trúc:
  - Queue `lgsp-receive` chứa 2 loại job:
    - Job name `'receive-tick'`: chạy theo repeat 5 phút (cũng nhận manual trigger qua route). Handler query `SELECT * FROM edoc.lgsp_agency_config WHERE is_active=TRUE` → for each row enqueue child job `'receive-dn'`
    - Job name `'receive-dn'`: 1 DN cụ thể. Job data `{ unit_id, environment }`. Handler gọi syncReceivedEdocList → loop getEdoc → INSERT.
  - Tách 2 job → retry per DN độc lập, 1 DN fail không drop 5 DN khác. Tick job retry=1 (tránh duplicate ticks); DN job retry=3 (network resilience).
- **D-03:** Manual trigger = Backend route `POST /api/lgsp/sync-now` (admin role required) — enqueue 1 immediate `'receive-tick'` job. Phase 37 admin UI sẽ thêm button "Sync ngay" gọi route này. Phase 35 chỉ build route + log.
- **D-04:** Worker concurrency:
  - Tick job: concurrency=1 (chỉ 1 tick chạy 1 lúc — race khi user spam manual + cron 5min trùng)
  - DN job: concurrency=3 (mirror Phase 34 — 3 DN sync parallel max, tránh spam LGSP)
  - Separate Worker instances cho 2 job names cùng queue (BullMQ support `Worker(queueName, processor, { name: 'job-name', concurrency })`)

### Area 2: edXML Parser + Map → incoming_docs

- **D-05:** Library = **`fast-xml-parser`** (add dep mới, ~50KB). Type-safe parser XML → JSON, escape handling, configurable arrayMode. Pair với `xmlbuilder2` Phase 34 (cùng nhánh dep).
- **D-06:** edXML → incoming_docs mapping (parse MessageHeader):
  - `external_doc_id` ← `MessageHeader.DocumentId` (UNIQUE dedup key)
  - `source_type` ← `'external_lgsp'` (enum value Phase 17)
  - `lgsp_sender_org_code` ← `MessageHeader.From.OrganizationId` (NEW column, D-13)
  - `publish_unit` ← `MessageHeader.From.OrganizationName` (display name)
  - `notation` ← `MessageHeader.Code.CodeNumber`
  - `document_code` ← `MessageHeader.Code.CodeNotation`
  - `abstract` ← `MessageHeader.Subject`
  - `signer` ← `MessageHeader.SignerInfo.Signer`
  - `sign_date` ← `MessageHeader.PromulgationInfo.PromulgationDate`
  - `publish_date` ← `MessageHeader.PromulgationInfo.PromulgationDate` (same — KH practice)
  - `doc_type_id` ← lookup `doc_types.name = MessageHeader.DocumentType` HOẶC NULL nếu không match (admin assign sau)
  - `secret_id, urgent_id` ← default = 1 ('Thường', 'Khẩn thường')
  - `number_paper, number_copies` ← default 1, lấy từ `MessageHeader.OtherInfo.PageAmount` nếu có
  - `recipients` ← edXML.From.OrganizationName + recipient text (concat)
  - `received_date` ← `NOW()`
  - `unit_id` ← unit_id của DN nhận (từ job data)
  - `department_id` ← `unit_id` (root unit để non-admin subtree filter — pattern Phase 17)
  - `extra_fields.edxml_raw` ← full edXML string (audit + future re-parse)
  - `extra_fields.message_header` ← MessageHeader JSON parsed (debug/UI display)
  - `created_by` ← system staff_id 1 (admin) — TODO: dedicated `lgsp-system` user id (Phase 37)
- **D-07:** Attachment storage:
  - Loop `edXML.Manifest.Attachment[]`
  - Mỗi attachment: base64 decode `<Content>` → Buffer → upload MinIO `documents` bucket với key pattern `lgsp/<lgsp_doc_id>/<file_name>` (UUID prefix tránh collision filename)
  - INSERT `attachments` table row: `{ outgoing_doc_id: NULL, incoming_doc_id: <new_id>, file_name, file_path: <minio_key>, file_size, mime_type, uploaded_by: system_staff_id }`
  - File >50MB → skip + log warn (LGSP spec limit + RAM safety)
- **D-08:** Sender catalog handling:
  - Lookup `SELECT id FROM edoc.inter_organizations WHERE code = $1` (org code từ From.OrganizationId)
  - Nếu found → save id (FK cho future trace)
  - Nếu KHÔNG found → INSERT new row `{ code, name: From.OrganizationName, is_active: false }` → log info "auto-registered new external org: <code>" → admin verify sau qua Phase 37 catalog page
  - Pattern auto-sync — KHÔNG reject doc (KH expect VB từ trục tự xuất hiện không cần config trước)

### Area 3: Dedup + Idempotency

- **D-09:** Dedup mechanism = **UNIQUE index `idx_incoming_docs_external_dedupe` (đã có Phase 17)** trên `(external_doc_id) WHERE external_doc_id IS NOT NULL AND source_type='external_lgsp'`. Worker insert qua `try/catch`:
  - SQLSTATE 23505 (unique_violation) → catch + log info "dedup: doc <id> already exists, skipped" → return (no error)
  - Other SQLSTATE → throw để BullMQ retry
  - KHÔNG dùng SELECT-then-INSERT (race condition khi 2 cron tick chạy gần nhau)
- **D-10:** Resume strategy:
  - `lgsp_agency_config.last_synced_at` chỉ UPDATE **sau khi full success per DN** (cuối handler `receive-dn` job)
  - Fail giữa chừng → last_synced_at giữ nguyên timestamp cũ → vòng cron sau retry từ điểm dừng
  - LGSP API query: `fromDate = last_synced_at OR (NOW() - 7 days)` (safety net 7 ngày — tránh API reject `fromDate` quá xa)
  - `toDate = NOW()`
  - Format LGSP yêu cầu: `YYYY/MM/DD` (verify từ Postman collection)
- **D-11:** Per-DN error handling:
  - Try/catch wrap toàn bộ DN sync logic trong job handler
  - Fail → UPDATE `lgsp_agency_config SET last_sync_error = $1` (truncate 1000 chars), `last_synced_at` GIỮ NGUYÊN
  - Success → UPDATE `last_sync_error = NULL, last_synced_at = NOW()`
  - Throw error (cho BullMQ retry 3 lần exponential 30s/60s/120s)
  - on('failed') final → log error + leave last_sync_error populated (admin sẽ thấy ở Phase 37 UI)
- **D-12:** Auto fire callback `01 đã nhận`:
  - Phase 35 KHÔNG fire trực tiếp lên trục. Chỉ INSERT outbox event `lgsp_status_outbox` row `{ incoming_doc_id, target_status: '01', payload: { lgsp_doc_id, sender_org_code }, sent_status: 'pending' }`
  - Phase 36 worker sẽ consume outbox event + đẩy POST /v1/updateStatus
  - Đảm bảo separation of concerns + retry per-event độc lập

### Area 4: Schema + UI + Verification

- **D-13:** Schema thay đổi (append `database/schema/000_schema_v3.0.sql` idempotent):
  ```sql
  ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS lgsp_sender_org_code VARCHAR(13) NULL;
  CREATE INDEX IF NOT EXISTS idx_incoming_docs_lgsp_sender ON edoc.incoming_docs(lgsp_sender_org_code) WHERE lgsp_sender_org_code IS NOT NULL;
  ```
  Lý do: tiện UI badge "LGSP from H37.SO.001" + filter theo sender bên ngoài. Có thể derive từ JOIN `inter_organizations` nhưng denormalize tối ưu list query.
- **D-14:** UI VB đến:
  - Tab "Văn bản đến" page list: render Tag "LGSP" (color blue) cho row `source_type='external_lgsp'`. Tooltip: `publish_unit + " (" + lgsp_sender_org_code + ")"`.
  - Filter dropdown nguồn: 3 option "Tất cả / Nội bộ / LGSP / Manual". Backend route `GET /api/van-ban-den?source=external_lgsp` filter SQL.
  - Detail page VB đến: hiển thị section "Nguồn LGSP" nếu `source_type='external_lgsp'` — show: lgsp_doc_id, sender_org_code + name, received_date từ LGSP, link MessageHeader raw JSON (collapse panel `extra_fields.message_header`)
- **D-15:** Realtime hay refresh:
  - Tab VB đến refetch khi `useEffect` mount + focus + nút "Làm mới"
  - KHÔNG polling 30s (cron 5min → polling 30s overhead vô ích)
  - Toast notification realtime defer v3.3+ (Socket.IO chưa active)
- **D-16:** E2E sandbox test luồng cụ thể (gating Phase 35 verification):
  - DN.001 sandbox active (Phase 33 seed)
  - Gửi 1 edXML test từ DN sandbox khác đến DN.001 sandbox via Postman collection `/v1/sendEdoc` (file edXML đã có trong `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/`)
  - Method 1 (chờ cron): wait 5 phút → cron tick chạy
  - Method 2 (trigger manual): admin token POST `/api/lgsp/sync-now` ngay
  - Verify:
    - `SELECT * FROM edoc.incoming_docs WHERE source_type='external_lgsp' AND external_doc_id='<sent_doc_id>'` → 1 row, fields match
    - MinIO bucket `documents` có object key `lgsp/<doc_id>/<file_name>`
    - Login user DN.001 → tab VB đến thấy row mới với tag "LGSP"
    - `SELECT * FROM edoc.lgsp_status_outbox WHERE incoming_doc_id=<new_id>` → 1 row target_status='01' sent_status='pending' (Phase 36 sẽ consume)
    - `SELECT last_synced_at FROM edoc.lgsp_agency_config WHERE unit_id=<DN001> AND environment='sandbox'` → updated to recent NOW
  - Dedup test: trigger sync-now lần 2 → SELECT count → vẫn 1 row, log có "dedup: ... skipped"
  - Error test: tạm tắt LGSP credential (UPDATE is_active=false rồi lại true với secret_key sai) → cron fail → last_sync_error populated, last_synced_at giữ nguyên

### Claude's Discretion

- Tên cột exact follow snake_case
- BullMQ Queue/Job/Worker naming: queue `'lgsp-receive'`, jobs `'receive-tick'` + `'receive-dn'`
- Type interfaces: `LgspReceiveTickJobData {}` (empty, just tick), `LgspReceiveDnJobData { unit_id: number; environment: 'sandbox'|'prod' }`
- Parser output type: `ParsedEdxml { messageHeader: {...typed...}, attachments: { fileName: string; content: Buffer }[], raw: string }`
- Logging: pino structured log mỗi step với `tick_id`, `unit_id`, `lgsp_doc_id`, `docs_synced_count`
- Approach A/B for shared code (parser/error-codes) — Phase 34 đã ratify Approach B duplicate, Phase 35 cũng follow Approach B (workers/ tự chứa edxml-parser.ts duplicate khỏi backend)

### Folded Todos

None.

</decisions>

<canonical_refs>
## Canonical References

### LGSP API Spec (Postman authoritative)

- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/LTVB_API_TRUC_PROD_TICHHOP.postman_collection.json`:
  - `GET {baseUrl}/v1/syncReceivedEdocList?messageType=edoc&fromDate=YYYY/MM/DD&toDate=YYYY/MM/DD` — Response: `{ success, count, data: [{ serviceType, createdTime, updatedTime, messageType, docId, from, to, status, statusDesc }] }`
  - `GET {baseUrl}/v1/getEdoc?docId=<uuid>` — Response: `{ success, data: { docId, from, fromName?, edocCode?, edocAbstract?, edxml: string, attachments?: [{ fileName, fileContent (base64) }] } }`
  - Headers cho cả 2: `X-SystemId` + `X-SecretKey`
- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/HuongDanKetNoiLienThongVB_v2.2.pdf` — Section "edXML Structure" + "Status codes 9 mã"

### Code đã có Phase 17/18/33/34 (reuse)

- `e_office_app_new/backend/src/services/lgsp-real.service.ts` — Phase 18 receiveDocuments() **SAI endpoint** (`/api/lgspedoc/received-edocs` thay vì `/v1/syncReceivedEdocList`). Phase 35 PHẢI fix giống cách Phase 34 đã fix sendDocument()
- `e_office_app_new/backend/src/services/lgsp.service.ts` — factory `getLgspService(unit_id, env)` reuse nguyên
- `e_office_app_new/backend/src/repositories/lgsp-agency-config.repository.ts` — Phase 33 có `getAllActive(env?)`, `updateLastSynced(unit_id, error?)` methods (verify exist hoặc add)
- `e_office_app_new/backend/src/repositories/incoming-doc.repository.ts` — extend với `createFromLgsp()` method
- `e_office_app_new/database/schema/000_schema_v3.0.sql`:
  - `incoming_docs.source_type` enum + `external_doc_id` + UNIQUE index dedup (Phase 17 đã có)
  - `inter_organizations` catalog + `lgsp_organ_id` (line 26474)
  - `lgsp_status_outbox` table (Phase 33)
  - Phase 35 APPEND: `ADD COLUMN lgsp_sender_org_code` + index
- `e_office_app_new/backend/src/lib/minio/client.ts` — `putObject(bucket, key, buffer, size, metadata)` cho upload attachment
- `e_office_app_new/backend/src/services/lgsp/error-codes.ts` (Phase 34) — reuse LgspSendError class + 9 codes
- `e_office_app_new/workers/src/jobs/lgsp-send-worker.ts` (Phase 34) — pattern reference for receive worker
- `e_office_app_new/workers/src/queues/lgsp-send-queue.ts` (Phase 34) — pattern reference for receive queue
- Frontend `e_office_app_new/frontend/src/app/(main)/van-ban-den/page.tsx` — extend với tag LGSP + filter nguồn

### Phase 33/34 SUMMARYs

- `.planning/phases/33-database-core-infrastructure/33-05-SUMMARY.md` — schema baseline
- `.planning/phases/34-send-flow-sendedoc/34-01-SUMMARY.md` — LGSPRealService fix pattern (Phase 35 mirror cho receive)
- `.planning/phases/34-send-flow-sendedoc/34-02-SUMMARY.md` — BullMQ worker module pattern + Approach B duplicate
- `.planning/phases/34-send-flow-sendedoc/34-05-VERIFICATION-REPORT.md` — verification template Phase 35 sẽ mirror

### Project rules

- `CLAUDE.md` § "DB Migration Strategy" — append `000_schema_v3.0.sql` idempotent (Phase 35 ALTER ADD COLUMN IF NOT EXISTS)
- `CLAUDE.md` § "Customer-Facing Scope" — menu LGSP còn ẩn
- `CLAUDE.md` § "Deploy Pitfalls" #8 — `streamFileToResponse` cho download attachment (Phase 35 upload qua minioClient direct)
- `CLAUDE.md` § "Phase Execution Rules" — wave-based, parallel safety, no inline assumptions
- Memory `project_production_ready.md` (updated 2026-05-20) — user "Giữ nguyên kiến trúc... ko cần cắt giảm" — KHÔNG đề xuất shortcut

### Project memory

- `~/.claude/projects/d--ProjectAI-quanlyvanban/memory/project_lgsp_architecture.md`
- `~/.claude/projects/d--ProjectAI-quanlyvanban/memory/project_production_ready.md` (just updated với feedback Phase 35)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`getLgspService(unit_id, env)`** — factory Phase 33, mỗi job attempt gọi lại pick up rotation
- **`lgspAgencyConfigRepository.getAllActive(env?)`** — query 6 DN active (Phase 33 hoặc Phase 35 sẽ add)
- **`minioClient.putObject()`** — upload attachment, mirror existing attachment upload flow
- **`callFunctionOne/callFunction`** — SP call pattern (nếu cần SP cho INSERT phức tạp)
- **`pool.query`** — raw SQL cho UPDATE last_synced_at + outbox INSERT
- **BullMQ Queue + Worker pattern Phase 34** — copy structure cho lgsp-receive-queue + lgsp-receive-worker
- **`pino` logger** structured log
- **`LgspSendError class` + `mapLgspError`** Phase 34 — reuse cho receive error mapping

### Established Patterns

- Repository = const object
- Worker file = `start()` function exported, `workers/src/index.ts` gọi
- BullMQ retry config: `{ attempts, backoff: { type: 'exponential', delay } }`
- ESM imports `.js` extension
- Native `fetch` (Node 22+) qua `fetchJson()` helper
- pino structured log với context fields

### Integration Points

- **Route `lgsp.ts`** Phase 18 `POST /api/lgsp/receive-poll` — Phase 35 thay thế bằng `POST /api/lgsp/sync-now` (enqueue tick job, không gọi đồng bộ inline)
- **`incoming_docs` table** Phase 17 — extend với column mới + INSERT pattern qua repo
- **`inter_organizations` table** Phase 18 catalog — auto-INSERT new sender
- **`lgsp_status_outbox` table** Phase 33 — INSERT row target_status='01' (Phase 36 sẽ consume)
- **`attachments` table** existing — INSERT row link incoming_doc_id + MinIO file_path
- **Frontend `van-ban-den/page.tsx`** — extend list + filter
- **`workers/src/index.ts`** — register lgsp-receive-tick-worker + lgsp-receive-dn-worker
- **`backend/src/server.ts`** — on backend start register repeat job (qua lib/queue helper)

</code_context>

<specifics>
## Specific Ideas

- **fast-xml-parser config (Phase 35 reference):**
  ```ts
  import { XMLParser } from 'fast-xml-parser';
  const parser = new XMLParser({
    ignoreAttributes: false,
    attributeNamePrefix: '@_',
    parseAttributeValue: true,
    parseTagValue: true,
    trimValues: true,
    isArray: (name) => ['Attachment', 'Path'].includes(name),  // force array even if 1 element
  });
  const parsed = parser.parse(edxmlString);
  // Access: parsed.EdXML.MessageHeader.DocumentId
  ```

- **BullMQ repeat job registration (in lib/queue helper, called from server.ts on start):**
  ```ts
  await receiveTickQueue.add(
    'receive-tick',
    {},
    {
      repeat: { every: 5 * 60 * 1000 },  // 5 phut
      jobId: 'lgsp-receive-tick-singleton',  // prevent duplicate scheduler
    }
  );
  ```

- **Worker pattern (2 worker instances cùng queue):**
  ```ts
  // workers/src/jobs/lgsp-receive-tick-worker.ts
  const tickWorker = new Worker('lgsp-receive', handleTick, {
    connection,
    concurrency: 1,
    autorun: true,
    // Process chi 'receive-tick' jobs
    runRetryDelay: 0,
  });
  // BullMQ filter by job name in handler:
  async function handleTick(job: Job) {
    if (job.name !== 'receive-tick') return;  // skip other job names
    const dnList = await lgspAgencyConfigRepository.getAllActive();
    for (const dn of dnList) {
      await receiveDnQueue.add('receive-dn', { unit_id: dn.unit_id, environment: dn.environment });
    }
  }
  ```

- **Dedup INSERT pattern:**
  ```ts
  try {
    const result = await pool.query(
      `INSERT INTO edoc.incoming_docs (...) VALUES (...) RETURNING id`,
      [...]
    );
    return { inserted: true, id: result.rows[0].id };
  } catch (err: any) {
    if (err.code === '23505') {
      logger.info({ external_doc_id, unit_id }, 'LGSP doc dedup: already exists, skipped');
      return { inserted: false, skipped: true };
    }
    throw err;
  }
  ```

- **E2E test data setup:**
  - 3 DN sandbox: DN.001/002/003 (List.txt — anh đã có credential)
  - Test edXML file đã có sẵn trong `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/` (Postman var src)
  - Hoặc dùng Postman collection: import → set env DN.002 sandbox creds → POST /v1/sendEdoc với recipient DN.001 → wait → trigger sync-now → verify

</specifics>

<deferred>
## Deferred Ideas

- Admin UI "Sync ngay" button → Phase 37
- Toast notification realtime VB mới → defer v3.3+
- Socket.IO realtime push → defer (polling đủ)
- Auto-sync inter_organizations cron riêng → defer v3.3+
- DLQ table → defer v3.3+
- MongoDB audit log `lgsp_audit` → defer v3.3+
- Dedicated `lgsp-system` staff user (vs hard-code id=1) → Phase 37 admin setup
- Bulk parser optimization (>100 docs/tick) → defer (chưa gặp)
- edXML XSD validation strict → defer (LGSP server đã validate)
- Auto-fire callback 03/04/05/06 khi VB đến processing → Phase 36

### Reviewed Todos (not folded)

None.

</deferred>

---

*Phase: 35-receive-flow-cron-syncreceivededoclist*
*Context gathered: 2026-05-20 (smart discuss, user accept all 4 area defaults + production-grade no shortcut)*
*Next: /gsd-plan-phase 35 → /gsd-execute-phase 35 → continue Phase 36-37*
