-- ============================================================================
-- Migration 046: "Cần ký" list SPs (Phase 11, Plan 05)
-- Requirements: SIGN-06
-- Depends on: 040_signing_schema.sql (sign_transactions) + 045 (attachment_handling_docs ALTER)
--
-- Creates 2 SPs for the "Cần ký" tab (Phase 12 UI sidebar):
--   fn_sign_need_list_by_staff  — list VB/HSCV attachments cần ký (PDF, chưa ký, user có quyền)
--   fn_sign_need_count_by_staff — count tương ứng cho badge
--
-- Khác với 3 tab còn lại (pending/completed/failed) — đã có trong migration 045
-- dùng sign_transactions table. "Cần ký" query các attachment PDF chưa có
-- transaction active (is_ca=FALSE AND NOT EXISTS pending transaction).
--
-- Quyền ký khớp với fn_attachment_can_sign (migration 045):
--   - outgoing/drafting: signer VARCHAR name match (UNACCENT+LOWER) OR approver match OR created_by OR admin
--   - handling: hd.signer INT = p_staff_id OR staff.is_admin
-- ============================================================================

-- ============================================================================
-- Part 1: fn_sign_need_list_by_staff
-- Paginated list của attachment PDF cần ký, union 3 nguồn:
--   outgoing_docs / drafting_docs / handling_docs
--
-- Trả total_count qua WINDOW để 1 query duy nhất là đủ cho paginated response.
-- ============================================================================
CREATE OR REPLACE FUNCTION edoc.fn_sign_need_list_by_staff(
  p_staff_id  INT,
  p_page      INT,
  p_page_size INT
)
RETURNS TABLE (
  attachment_id   BIGINT,
  attachment_type VARCHAR(20),
  file_name       VARCHAR(500),
  doc_id          BIGINT,
  doc_type        VARCHAR(20),
  doc_label       TEXT,
  doc_number      INT,
  doc_notation    VARCHAR(100),
  created_at      TIMESTAMPTZ,
  total_count     BIGINT
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_staff_name VARCHAR;
  v_is_admin   BOOLEAN := FALSE;
  v_offset     INT;
  v_limit      INT;
BEGIN
  -- Resolve staff name + admin flag once (reused across 3 union branches).
  -- Junction table is `public.role_of_staff` (khớp migration 045 fn_attachment_can_sign).
  SELECT s.full_name,
         (COALESCE(s.is_admin, FALSE) OR EXISTS (
            SELECT 1 FROM public.role_of_staff ros
              JOIN public.roles r ON r.id = ros.role_id
             WHERE ros.staff_id = s.id
               AND r.name = 'Quản trị hệ thống'
         ))
    INTO v_staff_name, v_is_admin
    FROM public.staff s
   WHERE s.id = p_staff_id;

  v_offset := GREATEST(0, (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20));
  v_limit  := GREATEST(1, LEAST(COALESCE(p_page_size, 20), 100));

  RETURN QUERY
  WITH combined AS (
    -- --------------------------------------------------------------------
    -- (1) Outgoing docs — signer/approver VARCHAR name match OR created_by OR admin
    -- --------------------------------------------------------------------
    SELECT aod.id                             AS attachment_id,
           'outgoing'::VARCHAR(20)            AS attachment_type,
           aod.file_name,
           od.id                              AS doc_id,
           'outgoing_doc'::VARCHAR(20)        AS doc_type,
           ('VB đi số ' || COALESCE(od.number::TEXT, '?')
                        || ' — '
                        || COALESCE(od.notation, '?'))::TEXT AS doc_label,
           od.number                          AS doc_number,
           od.notation                        AS doc_notation,
           aod.created_at
      FROM edoc.attachment_outgoing_docs aod
      JOIN edoc.outgoing_docs od ON od.id = aod.outgoing_doc_id
     WHERE COALESCE(aod.is_ca, FALSE) = FALSE
       AND LOWER(aod.file_name) LIKE '%.pdf'
       AND NOT EXISTS (
         SELECT 1 FROM edoc.sign_transactions st
          WHERE st.attachment_id   = aod.id
            AND st.attachment_type = 'outgoing'
            AND st.status          = 'pending'
       )
       AND (
         v_is_admin
         OR od.created_by = p_staff_id
         OR (od.signer   IS NOT NULL AND v_staff_name IS NOT NULL
             AND LOWER(UNACCENT(od.signer))   = LOWER(UNACCENT(v_staff_name)))
         OR (od.approver IS NOT NULL AND v_staff_name IS NOT NULL
             AND LOWER(UNACCENT(od.approver)) = LOWER(UNACCENT(v_staff_name)))
       )

    UNION ALL

    -- --------------------------------------------------------------------
    -- (2) Drafting docs — same permission model as outgoing
    -- --------------------------------------------------------------------
    SELECT add2.id,
           'drafting'::VARCHAR(20),
           add2.file_name,
           dd.id,
           'drafting_doc'::VARCHAR(20),
           ('VB dự thảo số ' || COALESCE(dd.number::TEXT, '?')
                             || ' — '
                             || COALESCE(dd.notation, '?'))::TEXT,
           dd.number,
           dd.notation,
           add2.created_at
      FROM edoc.attachment_drafting_docs add2
      JOIN edoc.drafting_docs dd ON dd.id = add2.drafting_doc_id
     WHERE COALESCE(add2.is_ca, FALSE) = FALSE
       AND LOWER(add2.file_name) LIKE '%.pdf'
       AND NOT EXISTS (
         SELECT 1 FROM edoc.sign_transactions st
          WHERE st.attachment_id   = add2.id
            AND st.attachment_type = 'drafting'
            AND st.status          = 'pending'
       )
       AND (
         v_is_admin
         OR dd.created_by = p_staff_id
         OR (dd.signer   IS NOT NULL AND v_staff_name IS NOT NULL
             AND LOWER(UNACCENT(dd.signer))   = LOWER(UNACCENT(v_staff_name)))
         OR (dd.approver IS NOT NULL AND v_staff_name IS NOT NULL
             AND LOWER(UNACCENT(dd.approver)) = LOWER(UNACCENT(v_staff_name)))
       )

    UNION ALL

    -- --------------------------------------------------------------------
    -- (3) Handling docs (HSCV) — signer là INT, match p_staff_id trực tiếp
    -- status IN (2,3) = đang xử lý / chờ duyệt (chưa đóng)
    -- --------------------------------------------------------------------
    SELECT ahd.id,
           'handling'::VARCHAR(20),
           ahd.file_name,
           hd.id,
           'handling_doc'::VARCHAR(20),
           ('HSCV: ' || COALESCE(hd.name, 'không tên'))::TEXT,
           NULL::INT,
           NULL::VARCHAR(100),
           ahd.created_at
      FROM edoc.attachment_handling_docs ahd
      JOIN edoc.handling_docs hd ON hd.id = ahd.handling_doc_id
     WHERE COALESCE(ahd.is_ca, FALSE) = FALSE
       AND LOWER(ahd.file_name) LIKE '%.pdf'
       AND NOT EXISTS (
         SELECT 1 FROM edoc.sign_transactions st
          WHERE st.attachment_id   = ahd.id
            AND st.attachment_type = 'handling'
            AND st.status          = 'pending'
       )
       AND (
         v_is_admin
         OR hd.created_by = p_staff_id
         OR hd.signer     = p_staff_id
       )
  )
  SELECT c.attachment_id,
         c.attachment_type,
         c.file_name,
         c.doc_id,
         c.doc_type,
         c.doc_label,
         c.doc_number,
         c.doc_notation,
         c.created_at,
         COUNT(*) OVER ()::BIGINT AS total_count
    FROM combined c
   ORDER BY c.created_at DESC
   LIMIT v_limit OFFSET v_offset;
END;
$$;

COMMENT ON FUNCTION edoc.fn_sign_need_list_by_staff(INT, INT, INT) IS
'Phase 11 Plan 05 — Paginated list of PDF attachments needing signature for a staff. Combines outgoing/drafting/handling sources. Permission model mirrors fn_attachment_can_sign (signer/approver/created_by/admin).';

DO $$ BEGIN
  RAISE NOTICE 'Migration 046 Part 1: fn_sign_need_list_by_staff created';
END $$;

-- ============================================================================
-- Part 2: fn_sign_need_count_by_staff
-- Trả count đơn giản cho badge sidebar.
-- Implementation: wrap Part 1 với page_size lớn + COUNT — acceptable cho dashboard-level
-- (số lượng attachment cần ký của 1 user thường <1000).
-- Alternative nếu cần perf: inline WITH combined AS(...) SELECT COUNT(*). Hiện chọn
-- wrap để giảm duplicate SQL — nếu logic permission thay đổi, chỉ cần sửa 1 chỗ.
-- ============================================================================
CREATE OR REPLACE FUNCTION edoc.fn_sign_need_count_by_staff(p_staff_id INT)
RETURNS INT
LANGUAGE plpgsql STABLE AS $$
DECLARE
  v_count INT;
BEGIN
  -- total_count từ row đầu tiên của list SP; nếu không có row thì 0.
  SELECT COALESCE((SELECT total_count FROM edoc.fn_sign_need_list_by_staff(p_staff_id, 1, 1) LIMIT 1), 0)::INT
    INTO v_count;
  RETURN COALESCE(v_count, 0);
END;
$$;

COMMENT ON FUNCTION edoc.fn_sign_need_count_by_staff(INT) IS
'Phase 11 Plan 05 — Badge count of PDF attachments needing signature for a staff. Thin wrapper around fn_sign_need_list_by_staff total_count window.';

DO $$ BEGIN
  RAISE NOTICE 'Migration 046 Part 2: fn_sign_need_count_by_staff created';
END $$;

-- ============================================================================
-- Verification (manual)
--   SELECT * FROM edoc.fn_sign_need_count_by_staff(1);
--   SELECT * FROM edoc.fn_sign_need_list_by_staff(1, 1, 20);
-- ============================================================================
