-- Gap B (TC-045): thêm cột channel vào lgsp_tracking + mở rộng SP fn_lgsp_tracking_create
-- CHÚ Ý: cột DB là outgoing_doc_id, incoming_doc_id, edxml_content (KHÔNG phải doc_id, incoming_id, response).

-- 1. ADD cột channel
ALTER TABLE edoc.lgsp_tracking
  ADD COLUMN IF NOT EXISTS channel VARCHAR(20) DEFAULT 'lgsp' NOT NULL;

-- 2. ADD CHECK constraint
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'lgsp_tracking_channel_check'
    ) THEN
        ALTER TABLE edoc.lgsp_tracking
          ADD CONSTRAINT lgsp_tracking_channel_check CHECK (channel IN ('lgsp', 'cp'));
    END IF;
END $$;

-- 3. DROP signature cũ (7 params)
DROP FUNCTION IF EXISTS edoc.fn_lgsp_tracking_create(
    BIGINT, BIGINT, VARCHAR, VARCHAR, VARCHAR, TEXT, INT
);

-- 4. CREATE mới với thêm p_channel default 'lgsp' ở cuối (backward-compat)
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_create(
    p_outgoing_doc_id BIGINT DEFAULT NULL,
    p_incoming_doc_id BIGINT DEFAULT NULL,
    p_direction VARCHAR DEFAULT 'send',
    p_dest_org_code VARCHAR DEFAULT NULL,
    p_dest_org_name VARCHAR DEFAULT NULL,
    p_edxml_content TEXT DEFAULT NULL,
    p_created_by INT DEFAULT NULL,
    p_channel VARCHAR DEFAULT 'lgsp'
)
RETURNS TABLE(success BOOLEAN, message TEXT, id BIGINT)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_id BIGINT;
BEGIN
    IF p_channel NOT IN ('lgsp', 'cp') THEN
        RETURN QUERY SELECT FALSE, 'channel phải là lgsp hoặc cp'::TEXT, NULL::BIGINT;
        RETURN;
    END IF;
    IF p_direction NOT IN ('send', 'receive') THEN
        RETURN QUERY SELECT FALSE, 'direction phải là send hoặc receive'::TEXT, NULL::BIGINT;
        RETURN;
    END IF;

    INSERT INTO edoc.lgsp_tracking(
        outgoing_doc_id, incoming_doc_id, direction,
        dest_org_code, dest_org_name, edxml_content,
        channel, status, created_by, created_at
    )
    VALUES (
        p_outgoing_doc_id, p_incoming_doc_id, p_direction,
        p_dest_org_code, p_dest_org_name, p_edxml_content,
        p_channel, 'pending', p_created_by, NOW()
    )
    RETURNING edoc.lgsp_tracking.id INTO v_id;

    RETURN QUERY SELECT TRUE, 'Đã log tracking record'::TEXT, v_id;
END;
$$;
