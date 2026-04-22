-- Gap E (TC-067): Chuyển tiếp ý kiến HSCV

-- 1. ALTER: thêm 4 cột forward
ALTER TABLE edoc.opinion_handling_docs
  ADD COLUMN IF NOT EXISTS forwarded_to_staff_id INT,
  ADD COLUMN IF NOT EXISTS forwarded_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS forward_note TEXT,
  ADD COLUMN IF NOT EXISTS parent_opinion_id BIGINT;

-- Thêm FK self-reference (ON DELETE SET NULL — giữ forward history)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'fk_opinion_parent'
    ) THEN
        ALTER TABLE edoc.opinion_handling_docs
          ADD CONSTRAINT fk_opinion_parent
          FOREIGN KEY (parent_opinion_id)
          REFERENCES edoc.opinion_handling_docs(id)
          ON DELETE SET NULL;
    END IF;
END $$;

-- 2. SP fn_opinion_forward
CREATE OR REPLACE FUNCTION edoc.fn_opinion_forward(
    p_opinion_id BIGINT,
    p_from_staff_id INT,
    p_to_staff_id INT,
    p_note TEXT
)
RETURNS TABLE(success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_handling_doc_id BIGINT;
    v_to_exists BOOLEAN;
    v_new_id BIGINT;
BEGIN
    IF p_note IS NULL OR LENGTH(TRIM(p_note)) = 0 THEN
        RETURN QUERY SELECT FALSE, 'Vui lòng nhập nội dung chuyển tiếp'::TEXT, NULL::BIGINT;
        RETURN;
    END IF;

    SELECT o.handling_doc_id INTO v_handling_doc_id
      FROM edoc.opinion_handling_docs o
      WHERE o.id = p_opinion_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy ý kiến gốc'::TEXT, NULL::BIGINT;
        RETURN;
    END IF;

    SELECT EXISTS(
        SELECT 1 FROM public.staff s
        WHERE s.id = p_to_staff_id
          AND COALESCE(s.is_locked, FALSE) = FALSE
          AND COALESCE(s.is_deleted, FALSE) = FALSE
    ) INTO v_to_exists;
    IF NOT v_to_exists THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy người nhận hoặc đã khóa/xoá'::TEXT, NULL::BIGINT;
        RETURN;
    END IF;

    INSERT INTO edoc.opinion_handling_docs(
        handling_doc_id, staff_id, content, created_at,
        forwarded_to_staff_id, forwarded_at, forward_note, parent_opinion_id
    )
    VALUES (
        v_handling_doc_id, p_from_staff_id, p_note, NOW(),
        p_to_staff_id, NOW(), p_note, p_opinion_id
    )
    RETURNING edoc.opinion_handling_docs.id INTO v_new_id;

    RETURN QUERY SELECT TRUE, 'Đã chuyển tiếp ý kiến'::TEXT, v_new_id;
END;
$$;

-- 3. DROP/CREATE fn_opinion_get_list — GIỮ param name p_doc_id, GIỮ staff_name TEXT
DROP FUNCTION IF EXISTS edoc.fn_opinion_get_list(BIGINT);

CREATE OR REPLACE FUNCTION edoc.fn_opinion_get_list(p_doc_id BIGINT)
RETURNS TABLE(
    -- 6 field cũ (GIỮ NGUYÊN):
    id BIGINT,
    staff_id INT,
    staff_name TEXT,
    content TEXT,
    attachment_path VARCHAR,
    created_at TIMESTAMPTZ,
    -- 5 field MỚI:
    forwarded_to_staff_id INT,
    forwarded_to_name TEXT,
    forwarded_at TIMESTAMPTZ,
    forward_note TEXT,
    parent_opinion_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        o.id,
        o.staff_id,
        CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
        o.content,
        o.attachment_path,
        o.created_at,
        o.forwarded_to_staff_id,
        CASE
            WHEN ts.id IS NOT NULL THEN CONCAT(ts.last_name, ' ', ts.first_name)::TEXT
            ELSE NULL::TEXT
        END AS forwarded_to_name,
        o.forwarded_at,
        o.forward_note,
        o.parent_opinion_id
    FROM edoc.opinion_handling_docs o
    JOIN public.staff s ON s.id = o.staff_id
    LEFT JOIN public.staff ts ON ts.id = o.forwarded_to_staff_id
    WHERE o.handling_doc_id = p_doc_id
    ORDER BY o.created_at ASC;
END;
$$;
