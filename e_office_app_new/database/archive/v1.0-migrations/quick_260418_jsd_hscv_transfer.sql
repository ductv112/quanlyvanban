-- Gap F (TC-068): Chuyển tiếp HSCV (transfer ownership)
-- Dùng cột `action_type` thay vì `action` cho safety

-- 1. CREATE TABLE handling_doc_history
CREATE TABLE IF NOT EXISTS edoc.handling_doc_history (
    id BIGSERIAL PRIMARY KEY,
    handling_doc_id BIGINT NOT NULL REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL,  -- 'transfer','cancel','reopen'
    from_staff_id INT REFERENCES public.staff(id),
    to_staff_id INT REFERENCES public.staff(id),
    note TEXT,
    created_by INT REFERENCES public.staff(id),
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_handling_doc_history_doc_id
  ON edoc.handling_doc_history(handling_doc_id);
CREATE INDEX IF NOT EXISTS idx_handling_doc_history_created_at
  ON edoc.handling_doc_history(created_at DESC);

-- 2. SP fn_handling_doc_transfer
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_transfer(
    p_id BIGINT,
    p_from_staff_id INT,
    p_to_staff_id INT,
    p_note TEXT,
    p_by INT
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_curator INT;
    v_doc_unit INT;
    v_to_unit INT;
    v_to_locked BOOLEAN;
    v_to_deleted BOOLEAN;
BEGIN
    IF p_to_staff_id IS NULL OR p_to_staff_id <= 0 THEN
        RETURN QUERY SELECT FALSE, 'Vui lòng chọn người nhận'::TEXT;
        RETURN;
    END IF;
    IF p_from_staff_id = p_to_staff_id THEN
        RETURN QUERY SELECT FALSE, 'Không thể chuyển cho chính mình'::TEXT;
        RETURN;
    END IF;

    SELECT h.curator, h.unit_id INTO v_current_curator, v_doc_unit
      FROM edoc.handling_docs h WHERE h.id = p_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy hồ sơ công việc'::TEXT;
        RETURN;
    END IF;

    SELECT s.unit_id, COALESCE(s.is_locked, FALSE), COALESCE(s.is_deleted, FALSE)
      INTO v_to_unit, v_to_locked, v_to_deleted
      FROM public.staff s WHERE s.id = p_to_staff_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy người nhận'::TEXT;
        RETURN;
    END IF;
    IF v_to_locked THEN
        RETURN QUERY SELECT FALSE, 'Người nhận đã khóa tài khoản'::TEXT;
        RETURN;
    END IF;
    IF v_to_deleted THEN
        RETURN QUERY SELECT FALSE, 'Người nhận đã bị xoá'::TEXT;
        RETURN;
    END IF;
    IF v_to_unit <> v_doc_unit THEN
        RETURN QUERY SELECT FALSE, 'Chỉ có thể chuyển HSCV cho người cùng đơn vị'::TEXT;
        RETURN;
    END IF;

    UPDATE edoc.handling_docs
    SET curator = p_to_staff_id,
        updated_at = NOW()
    WHERE id = p_id;

    INSERT INTO edoc.handling_doc_history(
        handling_doc_id, action_type, from_staff_id, to_staff_id, note, created_by, created_at
    )
    VALUES (p_id, 'transfer', v_current_curator, p_to_staff_id, p_note, p_by, NOW());

    RETURN QUERY SELECT TRUE, 'Đã chuyển tiếp hồ sơ công việc'::TEXT;
END;
$$;

-- 3. SP fn_handling_doc_history_list
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_history_list(p_id BIGINT)
RETURNS TABLE(
    id BIGINT,
    handling_doc_id BIGINT,
    action_type VARCHAR,
    from_staff_id INT,
    from_staff_name TEXT,
    to_staff_id INT,
    to_staff_name TEXT,
    note TEXT,
    created_by INT,
    created_by_name TEXT,
    created_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.id,
        h.handling_doc_id,
        h.action_type,
        h.from_staff_id,
        CASE WHEN fs.id IS NOT NULL THEN CONCAT(fs.last_name, ' ', fs.first_name)::TEXT ELSE NULL::TEXT END AS from_staff_name,
        h.to_staff_id,
        CASE WHEN ts.id IS NOT NULL THEN CONCAT(ts.last_name, ' ', ts.first_name)::TEXT ELSE NULL::TEXT END AS to_staff_name,
        h.note,
        h.created_by,
        CASE WHEN cs.id IS NOT NULL THEN CONCAT(cs.last_name, ' ', cs.first_name)::TEXT ELSE NULL::TEXT END AS created_by_name,
        h.created_at
    FROM edoc.handling_doc_history h
    LEFT JOIN public.staff fs ON fs.id = h.from_staff_id
    LEFT JOIN public.staff ts ON ts.id = h.to_staff_id
    LEFT JOIN public.staff cs ON cs.id = h.created_by
    WHERE h.handling_doc_id = p_id
    ORDER BY h.created_at DESC;
END;
$$;
