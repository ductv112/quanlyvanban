-- ================================================================
-- MIGRATION 019: Sprint 14 — LGSP Lien thong van ban
-- Schema: edoc
-- Tables: edoc.lgsp_organizations, edoc.lgsp_tracking
-- Functions: 6 stored functions
-- ================================================================

-- ==========================================
-- 1. BANG CO QUAN LIEN THONG (lgsp_organizations)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.lgsp_organizations (
  id          BIGSERIAL PRIMARY KEY,
  org_code    VARCHAR(100) NOT NULL,
  org_name    VARCHAR(500) NOT NULL,
  parent_code VARCHAR(100),
  address     VARCHAR(500),
  email       VARCHAR(200),
  phone       VARCHAR(50),
  is_active   BOOLEAN DEFAULT true,
  synced_at   TIMESTAMPTZ DEFAULT NOW(),
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_lgsp_org_code UNIQUE(org_code)
);

COMMENT ON TABLE edoc.lgsp_organizations IS 'Danh sach co quan lien thong dong bo tu LGSP';

-- ==========================================
-- 2. BANG TRACKING LIEN THONG (lgsp_tracking)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.lgsp_tracking (
  id               BIGSERIAL PRIMARY KEY,
  outgoing_doc_id  BIGINT REFERENCES edoc.outgoing_docs(id),
  incoming_doc_id  BIGINT REFERENCES edoc.incoming_docs(id),
  direction        VARCHAR(10) NOT NULL CHECK(direction IN ('send', 'receive')),
  lgsp_doc_id      VARCHAR(200),
  dest_org_code    VARCHAR(100),
  dest_org_name    VARCHAR(500),
  edxml_content    TEXT,
  status           VARCHAR(50) NOT NULL DEFAULT 'pending'
                   CHECK(status IN ('pending', 'processing', 'success', 'error')),
  error_message    TEXT,
  sent_at          TIMESTAMPTZ,
  received_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  created_by       INT REFERENCES public.staff(id)
);

CREATE INDEX IF NOT EXISTS idx_lgsp_tracking_outgoing ON edoc.lgsp_tracking(outgoing_doc_id);
CREATE INDEX IF NOT EXISTS idx_lgsp_tracking_status ON edoc.lgsp_tracking(status);
CREATE INDEX IF NOT EXISTS idx_lgsp_tracking_direction ON edoc.lgsp_tracking(direction);

COMMENT ON TABLE edoc.lgsp_tracking IS 'Tracking trang thai gui/nhan van ban lien thong LGSP';

-- ==========================================
-- 3. FN: DONG BO CO QUAN LIEN THONG (UPSERT)
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_org_sync(
  p_org_code    VARCHAR,
  p_org_name    VARCHAR,
  p_parent_code VARCHAR DEFAULT NULL,
  p_address     VARCHAR DEFAULT NULL,
  p_email       VARCHAR DEFAULT NULL,
  p_phone       VARCHAR DEFAULT NULL
)
RETURNS TABLE (
  success   BOOLEAN,
  message   TEXT,
  id        BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_organizations (org_code, org_name, parent_code, address, email, phone, synced_at)
  VALUES (p_org_code, p_org_name, p_parent_code, p_address, p_email, p_phone, NOW())
  ON CONFLICT (org_code) DO UPDATE SET
    org_name    = EXCLUDED.org_name,
    parent_code = EXCLUDED.parent_code,
    address     = EXCLUDED.address,
    email       = EXCLUDED.email,
    phone       = EXCLUDED.phone,
    synced_at   = NOW()
  RETURNING edoc.lgsp_organizations.id INTO v_id;

  RETURN QUERY SELECT true, 'Dong bo co quan thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 4. FN: DANH SACH CO QUAN LIEN THONG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_org_get_list(
  p_search    TEXT DEFAULT NULL,
  p_page      INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id          BIGINT,
  org_code    VARCHAR,
  org_name    VARCHAR,
  parent_code VARCHAR,
  address     VARCHAR,
  email       VARCHAR,
  phone       VARCHAR,
  is_active   BOOLEAN,
  synced_at   TIMESTAMPTZ,
  total_count BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT := (p_page - 1) * p_page_size;
  v_total  BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM edoc.lgsp_organizations o
  WHERE (p_search IS NULL OR p_search = ''
    OR o.org_code ILIKE '%' || p_search || '%'
    OR o.org_name ILIKE '%' || p_search || '%');

  RETURN QUERY
  SELECT
    o.id,
    o.org_code,
    o.org_name,
    o.parent_code,
    o.address,
    o.email,
    o.phone,
    o.is_active,
    o.synced_at,
    v_total
  FROM edoc.lgsp_organizations o
  WHERE (p_search IS NULL OR p_search = ''
    OR o.org_code ILIKE '%' || p_search || '%'
    OR o.org_name ILIKE '%' || p_search || '%')
  ORDER BY o.org_name
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- ==========================================
-- 5. FN: TAO TRACKING LIEN THONG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_create(
  p_outgoing_doc_id BIGINT DEFAULT NULL,
  p_direction       VARCHAR DEFAULT 'send',
  p_dest_org_code   VARCHAR DEFAULT NULL,
  p_dest_org_name   VARCHAR DEFAULT NULL,
  p_edxml_content   TEXT DEFAULT NULL,
  p_created_by      INT DEFAULT NULL
)
RETURNS TABLE (
  success   BOOLEAN,
  message   TEXT,
  id        BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_tracking (
    outgoing_doc_id, direction, dest_org_code, dest_org_name,
    edxml_content, created_by
  )
  VALUES (
    p_outgoing_doc_id, p_direction, p_dest_org_code, p_dest_org_name,
    p_edxml_content, p_created_by
  )
  RETURNING edoc.lgsp_tracking.id INTO v_id;

  RETURN QUERY SELECT true, 'Tao tracking thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 6. FN: CAP NHAT TRANG THAI TRACKING
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_update_status(
  p_id            BIGINT,
  p_status        VARCHAR,
  p_lgsp_doc_id   VARCHAR DEFAULT NULL,
  p_error_message TEXT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE edoc.lgsp_tracking
  SET status        = p_status,
      lgsp_doc_id   = COALESCE(p_lgsp_doc_id, lgsp_doc_id),
      error_message = p_error_message,
      sent_at       = CASE WHEN p_status = 'success' THEN NOW() ELSE sent_at END,
      received_at   = CASE WHEN p_status = 'success' AND direction = 'receive' THEN NOW() ELSE received_at END
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay tracking'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cap nhat trang thai thanh cong'::TEXT;
END;
$$;

-- ==========================================
-- 7. FN: DANH SACH TRACKING LIEN THONG
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_get_list(
  p_direction VARCHAR DEFAULT NULL,
  p_status    VARCHAR DEFAULT NULL,
  p_page      INT DEFAULT 1,
  p_page_size INT DEFAULT 20
)
RETURNS TABLE (
  id              BIGINT,
  outgoing_doc_id BIGINT,
  incoming_doc_id BIGINT,
  direction       VARCHAR,
  lgsp_doc_id     VARCHAR,
  dest_org_code   VARCHAR,
  dest_org_name   VARCHAR,
  status          VARCHAR,
  error_message   TEXT,
  sent_at         TIMESTAMPTZ,
  received_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ,
  total_count     BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT := (p_page - 1) * p_page_size;
  v_total  BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM edoc.lgsp_tracking t
  WHERE (p_direction IS NULL OR p_direction = '' OR t.direction = p_direction)
    AND (p_status IS NULL OR p_status = '' OR t.status = p_status);

  RETURN QUERY
  SELECT
    t.id,
    t.outgoing_doc_id,
    t.incoming_doc_id,
    t.direction,
    t.lgsp_doc_id,
    t.dest_org_code,
    t.dest_org_name,
    t.status,
    t.error_message,
    t.sent_at,
    t.received_at,
    t.created_at,
    v_total
  FROM edoc.lgsp_tracking t
  WHERE (p_direction IS NULL OR p_direction = '' OR t.direction = p_direction)
    AND (p_status IS NULL OR p_status = '' OR t.status = p_status)
  ORDER BY t.created_at DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- ==========================================
-- 8. FN: TRACKING THEO VAN BAN DI
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_get_by_doc(
  p_outgoing_doc_id BIGINT
)
RETURNS TABLE (
  id            BIGINT,
  direction     VARCHAR,
  lgsp_doc_id   VARCHAR,
  dest_org_code VARCHAR,
  dest_org_name VARCHAR,
  status        VARCHAR,
  error_message TEXT,
  sent_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.direction,
    t.lgsp_doc_id,
    t.dest_org_code,
    t.dest_org_name,
    t.status,
    t.error_message,
    t.sent_at,
    t.created_at
  FROM edoc.lgsp_tracking t
  WHERE t.outgoing_doc_id = p_outgoing_doc_id
  ORDER BY t.created_at DESC;
END;
$$;
