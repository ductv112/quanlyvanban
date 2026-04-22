-- Gap D (TC-066): HSCV hủy action riêng với lý do

-- 1. ALTER handling_docs: thêm 3 cột audit hủy
ALTER TABLE edoc.handling_docs
  ADD COLUMN IF NOT EXISTS cancel_reason TEXT,
  ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS cancelled_by INT;

-- 2. SP fn_handling_doc_cancel
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_cancel(
    p_id BIGINT,
    p_user_id INT,
    p_reason TEXT
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_status SMALLINT;
BEGIN
    IF p_reason IS NULL OR LENGTH(TRIM(p_reason)) = 0 THEN
        RETURN QUERY SELECT FALSE, 'Vui lòng nhập lý do hủy'::TEXT;
        RETURN;
    END IF;

    SELECT h.status INTO v_status FROM edoc.handling_docs h WHERE h.id = p_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy hồ sơ công việc'::TEXT;
        RETURN;
    END IF;
    IF v_status = -3 THEN
        RETURN QUERY SELECT FALSE, 'HSCV đã hủy trước đó'::TEXT;
        RETURN;
    END IF;
    IF v_status = 4 THEN
        RETURN QUERY SELECT FALSE, 'HSCV đã hoàn thành, không thể hủy'::TEXT;
        RETURN;
    END IF;

    UPDATE edoc.handling_docs
    SET status = -3,
        cancel_reason = p_reason,
        cancelled_at = NOW(),
        cancelled_by = p_user_id,
        updated_at = NOW()
    WHERE id = p_id;

    RETURN QUERY SELECT TRUE, 'Đã hủy hồ sơ công việc'::TEXT;
END;
$$;

-- 3. DROP/CREATE fn_handling_doc_get_by_id
-- GIỮ ĐẦY ĐỦ 33 field cũ (copy EXACT từ pg_get_functiondef) + thêm 3 field cancel_* cuối
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_by_id(BIGINT);

CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_by_id(p_id BIGINT)
RETURNS TABLE(
    id bigint,
    unit_id integer,
    unit_name character varying,
    department_id integer,
    department_name character varying,
    name character varying,
    abstract text,
    comments text,
    doc_notation character varying,
    doc_type_id integer,
    doc_type_name character varying,
    doc_field_id integer,
    doc_field_name character varying,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    curator_id integer,
    curator_name text,
    signer_id integer,
    signer_name text,
    "status" smallint,
    progress smallint,
    workflow_id integer,
    workflow_name character varying,
    parent_id bigint,
    parent_name character varying,
    is_from_doc boolean,
    created_by integer,
    created_at timestamp with time zone,
    updated_at timestamp with time zone,
    "number" integer,
    sub_number character varying,
    doc_book_id integer,
    doc_book_name character varying,
    -- Gap D: 3 field cancel_*
    cancel_reason TEXT,
    cancelled_at TIMESTAMPTZ,
    cancelled_by INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        h.id,
        h.unit_id,
        du.name                                     AS unit_name,
        h.department_id,
        dd.name                                     AS department_name,
        h.name,
        h.abstract,
        h.comments,
        h.doc_notation,
        h.doc_type_id,
        dt.name                                     AS doc_type_name,
        h.doc_field_id,
        df.name                                     AS doc_field_name,
        h.start_date,
        h.end_date,
        h.curator                                   AS curator_id,
        CONCAT(sc.last_name, ' ', sc.first_name)    AS curator_name,
        h.signer                                    AS signer_id,
        CONCAT(ss.last_name, ' ', ss.first_name)    AS signer_name,
        h.status,
        h.progress,
        h.workflow_id,
        NULL::VARCHAR                               AS workflow_name,
        h.parent_id,
        hp.name                                     AS parent_name,
        h.is_from_doc,
        h.created_by,
        h.created_at,
        h.updated_at,
        h.number,
        h.sub_number,
        h.doc_book_id,
        db.name::VARCHAR                            AS doc_book_name,
        h.cancel_reason,
        h.cancelled_at,
        h.cancelled_by
    FROM edoc.handling_docs h
    LEFT JOIN public.departments du ON du.id = h.unit_id
    LEFT JOIN public.departments dd ON dd.id = h.department_id
    LEFT JOIN edoc.doc_types     dt ON dt.id = h.doc_type_id
    LEFT JOIN edoc.doc_fields    df ON df.id = h.doc_field_id
    LEFT JOIN public.staff       sc ON sc.id = h.curator
    LEFT JOIN public.staff       ss ON ss.id = h.signer
    LEFT JOIN edoc.handling_docs hp ON hp.id = h.parent_id
    LEFT JOIN edoc.doc_books     db ON db.id = h.doc_book_id AND db.is_deleted = FALSE
    WHERE h.id = p_id;
END;
$$;
