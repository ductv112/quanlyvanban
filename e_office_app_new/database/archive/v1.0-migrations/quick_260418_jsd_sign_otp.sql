-- Gap A (TC-011): bổ sung is_ca/ca_date/signed_file_path vào 2 SP get_attachments
-- GIỮ ĐẦY ĐỦ 9 field cũ + JOIN public.staff cho created_by_name
-- CHÚ Ý: cột FK là outgoing_doc_id / drafting_doc_id (KHÔNG phải doc_id)

DROP FUNCTION IF EXISTS edoc.fn_attachment_outgoing_get_list(BIGINT);
CREATE OR REPLACE FUNCTION edoc.fn_attachment_outgoing_get_list(p_doc_id BIGINT)
RETURNS TABLE(
    id BIGINT,
    file_name VARCHAR,
    file_path VARCHAR,
    file_size BIGINT,
    content_type VARCHAR,
    sort_order INT,
    created_by INT,
    created_at TIMESTAMPTZ,
    created_by_name VARCHAR,
    -- 3 field MỚI thêm vào cuối:
    is_ca BOOLEAN,
    ca_date TIMESTAMPTZ,
    signed_file_path VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
           a.sort_order, a.created_by, a.created_at, s.full_name AS created_by_name,
           COALESCE(a.is_ca, FALSE) AS is_ca,
           a.ca_date,
           a.signed_file_path
    FROM edoc.attachment_outgoing_docs a
    LEFT JOIN public.staff s ON s.id = a.created_by
    WHERE a.outgoing_doc_id = p_doc_id
    ORDER BY a.sort_order, a.created_at;
END;
$$;

DROP FUNCTION IF EXISTS edoc.fn_attachment_drafting_get_list(BIGINT);
CREATE OR REPLACE FUNCTION edoc.fn_attachment_drafting_get_list(p_doc_id BIGINT)
RETURNS TABLE(
    id BIGINT,
    file_name VARCHAR,
    file_path VARCHAR,
    file_size BIGINT,
    content_type VARCHAR,
    sort_order INT,
    created_by INT,
    created_at TIMESTAMPTZ,
    created_by_name VARCHAR,
    is_ca BOOLEAN,
    ca_date TIMESTAMPTZ,
    signed_file_path VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
           a.sort_order, a.created_by, a.created_at, s.full_name AS created_by_name,
           COALESCE(a.is_ca, FALSE) AS is_ca,
           a.ca_date,
           a.signed_file_path
    FROM edoc.attachment_drafting_docs a
    LEFT JOIN public.staff s ON s.id = a.created_by
    WHERE a.drafting_doc_id = p_doc_id
    ORDER BY a.sort_order, a.created_at;
END;
$$;
