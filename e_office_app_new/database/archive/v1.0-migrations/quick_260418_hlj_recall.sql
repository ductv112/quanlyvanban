-- ============================================================================
-- Migration: quick_260418_hlj_recall
-- Mục đích: Thêm chức năng Đồng ý / Từ chối thu hồi VB liên thông (HDSD 2.3)
-- Locked decisions:
--   A1: SOFT-DELETE incoming_docs (không hard delete)
-- Lưu ý:
--   - inter_incoming_docs.id là BIGSERIAL → SP params p_id BIGINT.
--   - staff.id là SERIAL (INT) → p_user_id INT.
--   - incoming_docs hiện CHƯA có is_deleted/deleted_at/deleted_by → cần ALTER.
-- ============================================================================

-- 1) Bổ sung 6 cột metadata cho recall flow vào inter_incoming_docs
ALTER TABLE edoc.inter_incoming_docs
    ADD COLUMN IF NOT EXISTS recall_reason         TEXT,
    ADD COLUMN IF NOT EXISTS recall_requested_at   TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS recall_response       TEXT,
    ADD COLUMN IF NOT EXISTS recall_responded_by   INT,
    ADD COLUMN IF NOT EXISTS recall_responded_at   TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS status_before_recall  VARCHAR(50);

COMMENT ON COLUMN edoc.inter_incoming_docs.status_before_recall
    IS 'Snapshot status TRƯỚC khi chuyển sang ''recall_requested'', để khi reject có thể restore đúng trạng thái cũ.';

-- 2) Bổ sung soft-delete cho incoming_docs (theo A1 — bảng hiện CHƯA có 3 cột này)
ALTER TABLE edoc.incoming_docs
    ADD COLUMN IF NOT EXISTS is_deleted  BOOLEAN DEFAULT FALSE NOT NULL,
    ADD COLUMN IF NOT EXISTS deleted_at  TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS deleted_by  INT;

CREATE INDEX IF NOT EXISTS idx_incoming_docs_is_deleted
    ON edoc.incoming_docs (is_deleted)
    WHERE is_deleted = TRUE;

-- 3) TRIGGER: tự động snapshot status_before_recall khi status chuyển sang 'recall_requested'.
--    Đảm bảo mọi code path (webhook LGSP, admin tool, SP nội bộ, raw UPDATE) đều auto-save status cũ.
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_snapshot_status_before_recall()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'recall_requested'
       AND (OLD.status IS DISTINCT FROM 'recall_requested')
       AND NEW.status_before_recall IS NULL THEN
        NEW.status_before_recall := OLD.status;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_inter_incoming_snapshot_status_before_recall
    ON edoc.inter_incoming_docs;
CREATE TRIGGER trg_inter_incoming_snapshot_status_before_recall
    BEFORE UPDATE ON edoc.inter_incoming_docs
    FOR EACH ROW
    EXECUTE FUNCTION edoc.fn_inter_incoming_snapshot_status_before_recall();

-- 4) SP: Đồng ý thu hồi
--    status='recall_requested' → 'recalled'
--    + soft-delete incoming_docs liên kết (is_inter_doc=TRUE AND inter_doc_id=p_id)
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_recall_approve(
    p_id      BIGINT,
    p_user_id INT
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_status         VARCHAR(50);
    v_deleted_count  INT;
BEGIN
    SELECT status INTO v_status
      FROM edoc.inter_incoming_docs
      WHERE id = p_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản liên thông'::TEXT;
        RETURN;
    END IF;

    IF v_status <> 'recall_requested' THEN
        RETURN QUERY SELECT FALSE, ('Trạng thái hiện tại không cho phép đồng ý thu hồi: ' || v_status)::TEXT;
        RETURN;
    END IF;

    UPDATE edoc.inter_incoming_docs
    SET status              = 'recalled',
        recall_responded_by = p_user_id,
        recall_responded_at = NOW(),
        updated_at          = NOW()
    WHERE id = p_id;

    -- Soft-delete VB đến đã phát sinh (per A1)
    UPDATE edoc.incoming_docs
    SET is_deleted = TRUE,
        deleted_at = NOW(),
        deleted_by = p_user_id
    WHERE is_inter_doc = TRUE
      AND inter_doc_id = p_id
      AND is_deleted = FALSE;

    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

    RETURN QUERY SELECT TRUE,
        ('Đã đồng ý thu hồi. Xóa ' || v_deleted_count || ' văn bản đến liên kết.')::TEXT;
END;
$$;

COMMENT ON FUNCTION edoc.fn_inter_incoming_recall_approve(BIGINT, INT)
    IS 'Đồng ý thu hồi VB liên thông: status → recalled + soft-delete incoming_docs liên kết (is_inter_doc=TRUE AND inter_doc_id=p_id).';

-- 5) SP: Từ chối thu hồi (restore status_before_recall, fallback 'received')
CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_recall_reject(
    p_id      BIGINT,
    p_user_id INT,
    p_reason  TEXT
)
RETURNS TABLE(success BOOLEAN, message TEXT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_status         VARCHAR(50);
    v_prev_status    VARCHAR(50);
    v_restore_status VARCHAR(50);
BEGIN
    IF p_reason IS NULL OR LENGTH(TRIM(p_reason)) = 0 THEN
        RETURN QUERY SELECT FALSE, 'Vui lòng nhập lý do từ chối thu hồi'::TEXT;
        RETURN;
    END IF;

    SELECT status, status_before_recall
      INTO v_status, v_prev_status
      FROM edoc.inter_incoming_docs
      WHERE id = p_id;

    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản liên thông'::TEXT;
        RETURN;
    END IF;

    IF v_status <> 'recall_requested' THEN
        RETURN QUERY SELECT FALSE, ('Trạng thái hiện tại không cho phép từ chối thu hồi: ' || v_status)::TEXT;
        RETURN;
    END IF;

    -- Restore status trước khi yêu cầu thu hồi. Nếu snapshot null → fallback 'received'.
    v_restore_status := COALESCE(v_prev_status, 'received');

    UPDATE edoc.inter_incoming_docs
    SET status                = v_restore_status,
        recall_response       = p_reason,
        recall_responded_by   = p_user_id,
        recall_responded_at   = NOW(),
        status_before_recall  = NULL,  -- clear snapshot sau khi restore
        updated_at            = NOW()
    WHERE id = p_id;

    RETURN QUERY SELECT TRUE,
        ('Đã từ chối yêu cầu thu hồi. Khôi phục trạng thái: ' || v_restore_status)::TEXT;
END;
$$;

COMMENT ON FUNCTION edoc.fn_inter_incoming_recall_reject(BIGINT, INT, TEXT)
    IS 'Từ chối yêu cầu thu hồi: restore status từ status_before_recall (fallback ''received''), lưu recall_response.';

-- 6) Cập nhật fn_inter_incoming_get_by_id để trả thêm 6 field recall_*/status_before_recall.
--    Copy nguyên RETURNS TABLE + body cũ, thêm 6 field vào cuối — KHÔNG rename/remove field cũ.
--    DROP trước vì RETURNS TABLE thay đổi cấu trúc → CREATE OR REPLACE không cho phép.
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_get_by_id(BIGINT);

CREATE OR REPLACE FUNCTION edoc.fn_inter_incoming_get_by_id(p_id BIGINT)
RETURNS TABLE(
    id                    BIGINT,
    unit_id               INT,
    received_date         TIMESTAMP,
    notation              VARCHAR,
    document_code         VARCHAR,
    abstract              TEXT,
    publish_unit          VARCHAR,
    publish_date          DATE,
    signer                VARCHAR,
    sign_date             DATE,
    expired_date          DATE,
    doc_type_id           INT,
    doc_field_id          INT,
    secret_id             SMALLINT,
    urgent_id             SMALLINT,
    number_paper          INT,
    number_copies         INT,
    recipients            TEXT,
    status                VARCHAR,
    source_system         VARCHAR,
    external_doc_id       VARCHAR,
    organ_id              VARCHAR,
    from_organ_id         VARCHAR,
    created_by            INT,
    created_at            TIMESTAMP,
    updated_at            TIMESTAMP,
    doc_type_name         VARCHAR,
    doc_field_name        VARCHAR,
    created_by_name       VARCHAR,
    -- 6 field MỚI cho recall flow (HDSD 2.3)
    recall_reason         TEXT,
    recall_requested_at   TIMESTAMPTZ,
    recall_response       TEXT,
    recall_responded_by   INT,
    recall_responded_at   TIMESTAMPTZ,
    status_before_recall  VARCHAR
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        d.id, d.unit_id, d.received_date, d.notation, d.document_code,
        d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
        d.expired_date, d.doc_type_id,
        d.doc_field_id,
        d.secret_id,
        d.urgent_id,
        d.number_paper,
        d.number_copies,
        d.recipients,
        d.status, d.source_system, d.external_doc_id,
        d.organ_id,
        d.from_organ_id,
        d.created_by, d.created_at, d.updated_at,
        dt.name::VARCHAR  AS doc_type_name,
        df.name::VARCHAR  AS doc_field_name,
        s.full_name::VARCHAR AS created_by_name,
        d.recall_reason,
        d.recall_requested_at,
        d.recall_response,
        d.recall_responded_by,
        d.recall_responded_at,
        d.status_before_recall
    FROM edoc.inter_incoming_docs d
    LEFT JOIN edoc.doc_types dt  ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.staff s     ON s.id  = d.created_by
    WHERE d.id = p_id;
END;
$$;

COMMENT ON FUNCTION edoc.fn_inter_incoming_get_by_id(BIGINT)
    IS 'Chi tiết VB liên thông + 6 field recall_*/status_before_recall (HDSD 2.3).';
