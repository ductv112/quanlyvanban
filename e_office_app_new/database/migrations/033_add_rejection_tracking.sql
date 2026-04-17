-- ================================================================
-- Migration 033: Thêm rejection tracking cho VB đến/đi/dự thảo
--
-- Thêm cột: rejected_by INT, rejection_reason TEXT
-- Sửa SP reject để lưu thông tin
-- Sửa SP list để trả thêm rejected_by, rejection_reason
-- ================================================================

BEGIN;

-- ============================================================
-- 1. ALTER TABLE — thêm cột rejection
-- ============================================================

ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS rejected_by INT REFERENCES public.staff(id);
ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

ALTER TABLE edoc.outgoing_docs ADD COLUMN IF NOT EXISTS rejected_by INT REFERENCES public.staff(id);
ALTER TABLE edoc.outgoing_docs ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS rejected_by INT REFERENCES public.staff(id);
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS rejection_reason TEXT;

DO $$ BEGIN RAISE NOTICE '033-1: rejection columns added to 3 doc tables'; END $$;

-- ============================================================
-- 2. SP: fn_outgoing_doc_reject — lưu rejected_by + reason
-- ============================================================

CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_reject(
  p_id BIGINT, p_staff_id INT, p_reason TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;
  UPDATE edoc.outgoing_docs
  SET approved = FALSE, rejected_by = p_staff_id, rejection_reason = NULLIF(TRIM(p_reason), ''),
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản đi'::TEXT;
END; $$;

-- ============================================================
-- 3. SP: fn_drafting_doc_reject — lưu rejected_by + reason
-- ============================================================

CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_reject(
  p_id BIGINT, p_staff_id INT, p_reason TEXT DEFAULT NULL
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT; RETURN;
  END IF;
  UPDATE edoc.drafting_docs
  SET approved = FALSE, rejected_by = p_staff_id, rejection_reason = NULLIF(TRIM(p_reason), ''),
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản dự thảo'::TEXT;
END; $$;

-- ============================================================
-- 4. SP: fn_outgoing_doc_approve — clear rejection khi duyệt lại
-- ============================================================

CREATE OR REPLACE FUNCTION edoc.fn_outgoing_doc_approve(
  p_id BIGINT, p_staff_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_name TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;
  SELECT full_name INTO v_name FROM public.staff WHERE id = p_staff_id;
  UPDATE edoc.outgoing_docs
  SET approved = TRUE, approver = v_name, rejected_by = NULL, rejection_reason = NULL,
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Duyệt văn bản đi thành công'::TEXT;
END; $$;

-- ============================================================
-- 5. SP: fn_drafting_doc_approve — clear rejection khi duyệt lại
-- ============================================================

CREATE OR REPLACE FUNCTION edoc.fn_drafting_doc_approve(
  p_id BIGINT, p_staff_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_name TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT; RETURN;
  END IF;
  SELECT full_name INTO v_name FROM public.staff WHERE id = p_staff_id;
  UPDATE edoc.drafting_docs
  SET approved = TRUE, approver = v_name, rejected_by = NULL, rejection_reason = NULL,
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Duyệt văn bản dự thảo thành công'::TEXT;
END; $$;

-- ============================================================
-- 6. SP: fn_incoming_doc_approve — clear rejection khi duyệt lại
-- ============================================================

CREATE OR REPLACE FUNCTION edoc.fn_incoming_doc_approve(
  p_id BIGINT, p_staff_id INT
)
RETURNS TABLE (success BOOLEAN, message TEXT)
LANGUAGE plpgsql SECURITY DEFINER AS $$
DECLARE v_name TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT; RETURN;
  END IF;
  SELECT full_name INTO v_name FROM public.staff WHERE id = p_staff_id;
  UPDATE edoc.incoming_docs
  SET approved = TRUE, approver = v_name, rejected_by = NULL, rejection_reason = NULL,
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Duyệt văn bản đến thành công'::TEXT;
END; $$;

DO $$ BEGIN RAISE NOTICE '033: Migration complete — rejection tracking added'; END $$;

COMMIT;
