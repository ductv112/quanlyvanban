-- =============================================================================
-- CLEANUP VB TEST LGSP — 2026-05-27 prod Lang Son (qlvbdn.lstt.vn)
-- Scope:
--   - outgoing_docs: tao hom nay + co recipient_type='external_org' (= gui LGSP)
--   - incoming_docs: tao hom nay + source_type='external_lgsp' (= nhan tu LGSP)
--   - lgsp_tracking lien quan
--   - CASCADE auto: outgoing_doc_recipients, attachment_outgoing_docs,
--                   attachment_incoming_docs, user_outgoing_docs, user_incoming_docs
-- File dinh kem trong MinIO: KHONG xoa (orphan, ~vai MB)
-- =============================================================================

-- ───────────────────────────────────────────────────────────────────────────
-- BUOC 1: PREVIEW (chay 4 query nay TRUOC, verify list dung khong)
-- ───────────────────────────────────────────────────────────────────────────

-- 1.1 List VB di gui LGSP tao hom nay
SELECT od.id, od.notation, od.document_code, LEFT(od.abstract, 60) AS abstract_snip,
       od.unit_id, d.name AS sender_name, od.created_at::TIMESTAMP(0)
  FROM edoc.outgoing_docs od
  JOIN public.departments d ON d.id = od.unit_id
 WHERE od.created_at::DATE = '2026-05-27'
   AND EXISTS (
     SELECT 1 FROM edoc.outgoing_doc_recipients r
      WHERE r.outgoing_doc_id = od.id
        AND r.recipient_type = 'external_org'::edoc.recipient_type_enum
   )
 ORDER BY od.id;

-- 1.2 List VB den tu LGSP tao hom nay
SELECT id.id, id.notation, id.document_code, LEFT(id.abstract, 60) AS abstract_snip,
       id.unit_id, d.name AS receiver_name, id.source_type, id.lgsp_sender_org_code,
       id.created_at::TIMESTAMP(0)
  FROM edoc.incoming_docs id
  JOIN public.departments d ON d.id = id.unit_id
 WHERE id.created_at::DATE = '2026-05-27'
   AND id.source_type = 'external_lgsp'
 ORDER BY id.id;

-- 1.3 Count tracking lien quan
SELECT 'tracking_for_outgoing' AS what, COUNT(*) AS cnt
  FROM edoc.lgsp_tracking t
 WHERE t.outgoing_doc_id IN (
   SELECT id FROM edoc.outgoing_docs
    WHERE created_at::DATE = '2026-05-27'
      AND EXISTS (SELECT 1 FROM edoc.outgoing_doc_recipients r
                   WHERE r.outgoing_doc_id = edoc.outgoing_docs.id
                     AND r.recipient_type = 'external_org'::edoc.recipient_type_enum)
 )
UNION ALL
SELECT 'tracking_for_incoming', COUNT(*)
  FROM edoc.lgsp_tracking t
 WHERE t.incoming_doc_id IN (
   SELECT id FROM edoc.incoming_docs
    WHERE created_at::DATE = '2026-05-27'
      AND source_type = 'external_lgsp'
 );

-- 1.4 Count attachment lien quan (chi de info, KHONG xoa MinIO file)
SELECT 'attach_outgoing' AS what, COUNT(*) AS cnt
  FROM edoc.attachment_outgoing_docs a
 WHERE a.outgoing_doc_id IN (
   SELECT id FROM edoc.outgoing_docs
    WHERE created_at::DATE = '2026-05-27'
      AND EXISTS (SELECT 1 FROM edoc.outgoing_doc_recipients r
                   WHERE r.outgoing_doc_id = edoc.outgoing_docs.id
                     AND r.recipient_type = 'external_org'::edoc.recipient_type_enum)
 )
UNION ALL
SELECT 'attach_incoming', COUNT(*)
  FROM edoc.attachment_incoming_docs a
 WHERE a.incoming_doc_id IN (
   SELECT id FROM edoc.incoming_docs
    WHERE created_at::DATE = '2026-05-27'
      AND source_type = 'external_lgsp'
 );

-- ───────────────────────────────────────────────────────────────────────────
-- BUOC 2: DELETE (chi chay SAU KHI verify Buoc 1)
-- Wrap trong transaction de ROLLBACK neu thay so luong la
-- ───────────────────────────────────────────────────────────────────────────

BEGIN;

-- Materialize id list vao temp table de tranh re-evaluate subquery
CREATE TEMP TABLE _target_outgoing_ids AS
SELECT od.id
  FROM edoc.outgoing_docs od
 WHERE od.created_at::DATE = '2026-05-27'
   AND EXISTS (
     SELECT 1 FROM edoc.outgoing_doc_recipients r
      WHERE r.outgoing_doc_id = od.id
        AND r.recipient_type = 'external_org'::edoc.recipient_type_enum
   );

CREATE TEMP TABLE _target_incoming_ids AS
SELECT id
  FROM edoc.incoming_docs
 WHERE created_at::DATE = '2026-05-27'
   AND source_type = 'external_lgsp';

-- 2.1 Xoa lgsp_tracking (FK khong cascade, phai xoa truoc parent)
DELETE FROM edoc.lgsp_tracking
 WHERE outgoing_doc_id IN (SELECT id FROM _target_outgoing_ids);

DELETE FROM edoc.lgsp_tracking
 WHERE incoming_doc_id IN (SELECT id FROM _target_incoming_ids);

-- 2.2 Xoa outgoing_docs (CASCADE: outgoing_doc_recipients, attachment_outgoing_docs,
--     user_outgoing_docs, leader_notes_outgoing)
DELETE FROM edoc.outgoing_docs
 WHERE id IN (SELECT id FROM _target_outgoing_ids);

-- 2.3 Xoa incoming_docs (CASCADE: attachment_incoming_docs, user_incoming_docs,
--     leader_notes_incoming)
DELETE FROM edoc.incoming_docs
 WHERE id IN (SELECT id FROM _target_incoming_ids);

-- 2.4 Verify counts sau xoa (phai = 0)
SELECT 'outgoing_remaining' AS what, COUNT(*) AS cnt FROM edoc.outgoing_docs
 WHERE id IN (SELECT id FROM _target_outgoing_ids)
UNION ALL
SELECT 'incoming_remaining', COUNT(*) FROM edoc.incoming_docs
 WHERE id IN (SELECT id FROM _target_incoming_ids);

-- ───────────────────────────────────────────────────────────────────────────
-- BUOC 3: COMMIT
-- Preview da verify 2026-05-27: 16 outgoing + 18 tracking + 8 attach + 0 incoming.
-- incoming_docs = 0 vi gui NOI TINH Lang Son, Phu Loc thay VB qua recipient
-- view cua outgoing_doc (perspective inversion), KHONG can duplicate.
-- ───────────────────────────────────────────────────────────────────────────

COMMIT;
