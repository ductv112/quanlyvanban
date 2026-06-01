-- =============================================================================
-- FIX schema bug: idx_incoming_docs_external_dedupe — Phase 37.12 (2026-06-01)
--
-- Root cause: UNIQUE index cu chi tren (external_doc_id) chan 1 VB Sở gửi cho
-- nhiều DN qua LGSP. Khi worker insert cùng lgsp_doc_id cho 6 DN -> chỉ DN đầu
-- tiên insert được, 5 DN sau bị 23505 unique violation -> SP skip -> UI không
-- hiển thị VB cho 5 DN còn lại.
--
-- Fix: composite UNIQUE (unit_id, external_doc_id) cho phép cùng VB cho nhiều
-- unit nhưng vẫn dedup intra-unit retry.
--
-- Run: psql -f deploy/fix-lgsp-incoming-dedupe-20260601.sql
-- =============================================================================

BEGIN;

-- Verify data trước migration: KHÔNG có duplicate hiện tại
SELECT external_doc_id, COUNT(*) AS cnt
  FROM edoc.incoming_docs
 WHERE source_type = 'external_lgsp' AND external_doc_id IS NOT NULL
 GROUP BY external_doc_id
HAVING COUNT(*) > 1;
-- Expected: 0 rows. Nếu > 0 -> DỪNG, không apply migration vì sẽ fail unique check.

-- DROP old index
DROP INDEX IF EXISTS edoc.idx_incoming_docs_external_dedupe;

-- CREATE composite unique
CREATE UNIQUE INDEX idx_incoming_docs_external_dedupe
  ON edoc.incoming_docs(unit_id, external_doc_id)
 WHERE external_doc_id IS NOT NULL AND source_type = 'external_lgsp';

-- Verify index mới
SELECT indexname, indexdef
  FROM pg_indexes
 WHERE schemaname = 'edoc' AND indexname = 'idx_incoming_docs_external_dedupe';

-- Reset last_synced_at cho 5 DN (102-106) để worker re-pull VB Sở gửi
-- DN.001 đã có incoming_doc id=4 — KHÔNG reset (giữ data)
UPDATE edoc.lgsp_agency_config
   SET last_synced_at = '2026-05-31 00:00:00'::timestamptz,
       last_sync_error = NULL
 WHERE unit_id IN (102, 103, 104, 105, 106)
   AND environment = 'prod';

-- Verify reset
SELECT unit_id, environment, is_active, last_synced_at::TIMESTAMP(0)
  FROM edoc.lgsp_agency_config
 WHERE environment = 'prod'
 ORDER BY unit_id;

COMMIT;
