-- ============================================================================
-- Migration: quick_260418_hlj_hscv
-- Mục đích: Thêm chức năng Mở lại + Lấy số HSCV (HDSD 3.1, 3.2)
-- Locked decisions:
--   A2: GIỮ NGUYÊN progress=100 khi reopen (status 4 → 1)
--   A3: Reset số theo năm `created_at` + doc_book_id
-- Lưu ý:
--   - handling_docs.id là BIGSERIAL → SP params p_id BIGINT.
--   - doc_books.id là SERIAL (INT) → p_doc_book_id INT.
--   - staff.id là SERIAL (INT) → p_user_id INT.
--   - Cột thực: doc_notation VARCHAR(100) (KHÔNG dùng `notation` — bảng có cả 2 cột).
-- ============================================================================

-- 1) SP: Mở lại HSCV (status=4 → 1, GIỮ progress=100 per A2)
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_reopen(
    p_id      BIGINT,
    p_user_id INT
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_status SMALLINT;
BEGIN
    SELECT status INTO v_status
      FROM edoc.handling_docs
      WHERE id = p_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy hồ sơ công việc'::TEXT;
        RETURN;
    END IF;

    IF v_status <> 4 THEN
        RETURN QUERY SELECT FALSE,
            ('Chỉ có thể mở lại HSCV đã hoàn thành. Trạng thái hiện tại: ' || v_status)::TEXT;
        RETURN;
    END IF;

    -- A2: status 4 → 1, GIỮ NGUYÊN progress, clear complete_date / complete_user_id
    UPDATE edoc.handling_docs
    SET status           = 1,
        complete_date    = NULL,
        complete_user_id = NULL,
        updated_by       = p_user_id,
        updated_at       = NOW()
    WHERE id = p_id;

    RETURN QUERY SELECT TRUE, 'Đã mở lại hồ sơ công việc'::TEXT;
END;
$$;

COMMENT ON FUNCTION edoc.fn_handling_doc_reopen(BIGINT, INT)
    IS 'Mở lại HSCV (status 4 → 1). Giữ nguyên progress per A2.';

-- 2) SP: Tính số kế tiếp theo năm created_at + doc_book_id (per A3)
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_next_number(
    p_doc_book_id INT,
    p_unit_id     INT
)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_next INT;
BEGIN
    SELECT COALESCE(MAX(number), 0) + 1
      INTO v_next
      FROM edoc.handling_docs
      WHERE doc_book_id = p_doc_book_id
        AND unit_id = p_unit_id
        AND number IS NOT NULL
        AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM NOW());
    RETURN v_next;
END;
$$;

COMMENT ON FUNCTION edoc.fn_handling_doc_get_next_number(INT, INT)
    IS 'Tính số HSCV kế tiếp = MAX(number)+1 theo năm created_at + doc_book_id + unit_id (A3).';

-- 3) SP: Gán số cho HSCV (Lấy số)
--    Trả về RETURNS TABLE với cột "number" (đặt trong dấu nháy kép cho an toàn).
CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_assign_number(
    p_id          BIGINT,
    p_user_id     INT,
    p_doc_book_id INT
)
RETURNS TABLE(success BOOLEAN, message TEXT, "number" INT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_unit_id          INT;
    v_existing_number  INT;
    v_next             INT;
BEGIN
    SELECT h.unit_id, h.number
      INTO v_unit_id, v_existing_number
      FROM edoc.handling_docs h
      WHERE h.id = p_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy hồ sơ công việc'::TEXT, NULL::INT;
        RETURN;
    END IF;

    IF v_existing_number IS NOT NULL THEN
        RETURN QUERY SELECT FALSE,
            ('HSCV đã có số ' || v_existing_number)::TEXT,
            v_existing_number;
        RETURN;
    END IF;

    IF p_doc_book_id IS NULL THEN
        RETURN QUERY SELECT FALSE, 'Vui lòng chọn sổ văn bản'::TEXT, NULL::INT;
        RETURN;
    END IF;

    -- A3: Tính số kế tiếp theo năm created_at + doc_book_id + unit_id
    v_next := edoc.fn_handling_doc_get_next_number(p_doc_book_id, v_unit_id);

    UPDATE edoc.handling_docs
    SET number      = v_next,
        doc_book_id = p_doc_book_id,
        updated_by  = p_user_id,
        updated_at  = NOW()
    WHERE id = p_id;

    RETURN QUERY SELECT TRUE, ('Đã lấy số ' || v_next)::TEXT, v_next;
END;
$$;

COMMENT ON FUNCTION edoc.fn_handling_doc_assign_number(BIGINT, INT, INT)
    IS 'Gán số HSCV: kiểm tra chưa có số → tính MAX+1 theo năm + sổ → UPDATE row.';

-- 4) Cập nhật fn_handling_doc_get_by_id để trả thêm 4 field:
--    number, sub_number, doc_book_id, doc_book_name (JOIN doc_books)
--    + GIỮ NGUYÊN doc_notation (đã có trong SP cũ).
--    DROP trước vì RETURNS TABLE thay đổi cấu trúc.
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_by_id(BIGINT);

CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_by_id(p_id BIGINT)
RETURNS TABLE(
    id              BIGINT,
    unit_id         INT,
    unit_name       VARCHAR,
    department_id   INT,
    department_name VARCHAR,
    name            VARCHAR,
    abstract        TEXT,
    comments        TEXT,
    doc_notation    VARCHAR,
    doc_type_id     INT,
    doc_type_name   VARCHAR,
    doc_field_id    INT,
    doc_field_name  VARCHAR,
    start_date      TIMESTAMPTZ,
    end_date        TIMESTAMPTZ,
    curator_id      INT,
    curator_name    TEXT,
    signer_id       INT,
    signer_name     TEXT,
    status          SMALLINT,
    progress        SMALLINT,
    workflow_id     INT,
    workflow_name   VARCHAR,
    parent_id       BIGINT,
    parent_name     VARCHAR,
    is_from_doc     BOOLEAN,
    created_by      INT,
    created_at      TIMESTAMPTZ,
    updated_at      TIMESTAMPTZ,
    -- 4 field MỚI cho HDSD 3.2 (Lấy số)
    "number"        INT,
    sub_number      VARCHAR,
    doc_book_id     INT,
    doc_book_name   VARCHAR
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
        db.name::VARCHAR                            AS doc_book_name
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

COMMENT ON FUNCTION edoc.fn_handling_doc_get_by_id(BIGINT)
    IS 'Chi tiết HSCV + 4 field number/sub_number/doc_book_id/doc_book_name (HDSD 3.2).';
