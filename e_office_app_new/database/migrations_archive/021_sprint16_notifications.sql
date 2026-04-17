-- ================================================================
-- MIGRATION 021: Sprint 16 — Thong bao da kenh (Notifications)
-- Schema: edoc
-- Tables: edoc.device_tokens, edoc.notification_logs, edoc.notification_preferences
-- Functions: 8 stored functions
-- ================================================================

-- ==========================================
-- 1. BANG DEVICE TOKEN (device_tokens)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.device_tokens (
  id           BIGSERIAL PRIMARY KEY,
  staff_id     INT NOT NULL REFERENCES public.staff(id),
  device_token VARCHAR(500) NOT NULL,
  device_type  VARCHAR(20) DEFAULT 'web' CHECK(device_type IN ('web', 'android', 'ios')),
  is_active    BOOLEAN DEFAULT true,
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_device_token UNIQUE(device_token)
);

CREATE INDEX IF NOT EXISTS idx_device_tokens_staff ON edoc.device_tokens(staff_id);

COMMENT ON TABLE edoc.device_tokens IS 'FCM device tokens cho push notification';

-- ==========================================
-- 2. BANG LOG THONG BAO (notification_logs)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.notification_logs (
  id            BIGSERIAL PRIMARY KEY,
  staff_id      INT NOT NULL REFERENCES public.staff(id),
  channel       VARCHAR(20) NOT NULL CHECK(channel IN ('fcm', 'zalo', 'sms', 'email')),
  event_type    VARCHAR(50) NOT NULL,
  title         VARCHAR(500),
  body          TEXT,
  ref_type      VARCHAR(30),
  ref_id        BIGINT,
  send_status   VARCHAR(20) NOT NULL DEFAULT 'pending'
                CHECK(send_status IN ('pending', 'sent', 'failed')),
  error_message TEXT,
  sent_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notif_log_staff ON edoc.notification_logs(staff_id);
CREATE INDEX IF NOT EXISTS idx_notif_log_channel ON edoc.notification_logs(channel);
CREATE INDEX IF NOT EXISTS idx_notif_log_status ON edoc.notification_logs(send_status);
CREATE INDEX IF NOT EXISTS idx_notif_log_created ON edoc.notification_logs(created_at DESC);

COMMENT ON TABLE edoc.notification_logs IS 'Log tat ca thong bao gui qua cac kenh (FCM, Zalo, SMS, Email)';

-- ==========================================
-- 3. BANG CAU HINH THONG BAO (notification_preferences)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.notification_preferences (
  id         BIGSERIAL PRIMARY KEY,
  staff_id   INT NOT NULL REFERENCES public.staff(id),
  channel    VARCHAR(20) NOT NULL CHECK(channel IN ('fcm', 'zalo', 'sms', 'email')),
  is_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  CONSTRAINT uq_notif_pref_staff_channel UNIQUE(staff_id, channel)
);

COMMENT ON TABLE edoc.notification_preferences IS 'Cau hinh kenh thong bao theo user';

-- ==========================================
-- 4. FN: UPSERT DEVICE TOKEN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_device_token_upsert(
  p_staff_id     INT,
  p_device_token VARCHAR,
  p_device_type  VARCHAR DEFAULT 'web'
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.device_tokens (staff_id, device_token, device_type, updated_at)
  VALUES (p_staff_id, p_device_token, p_device_type, NOW())
  ON CONFLICT (device_token) DO UPDATE SET
    staff_id    = EXCLUDED.staff_id,
    device_type = EXCLUDED.device_type,
    is_active   = true,
    updated_at  = NOW()
  RETURNING edoc.device_tokens.id INTO v_id;

  RETURN QUERY SELECT true, 'Luu device token thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 5. FN: LAY DEVICE TOKEN THEO STAFF
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_device_token_get_by_staff(
  p_staff_id INT
)
RETURNS TABLE (
  id           BIGINT,
  device_token VARCHAR,
  device_type  VARCHAR,
  is_active    BOOLEAN,
  created_at   TIMESTAMPTZ
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    dt.id,
    dt.device_token,
    dt.device_type,
    dt.is_active,
    dt.created_at
  FROM edoc.device_tokens dt
  WHERE dt.staff_id = p_staff_id
    AND dt.is_active = true
  ORDER BY dt.created_at DESC;
END;
$$;

-- ==========================================
-- 6. FN: XOA DEVICE TOKEN
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_device_token_delete(
  p_id       BIGINT,
  p_staff_id INT
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  DELETE FROM edoc.device_tokens
  WHERE id = p_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay device token'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xoa device token thanh cong'::TEXT;
END;
$$;

-- ==========================================
-- 7. FN: TAO LOG THONG BAO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notification_log_create(
  p_staff_id   INT,
  p_channel    VARCHAR,
  p_event_type VARCHAR,
  p_title      VARCHAR DEFAULT NULL,
  p_body       TEXT DEFAULT NULL,
  p_ref_type   VARCHAR DEFAULT NULL,
  p_ref_id     BIGINT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.notification_logs (
    staff_id, channel, event_type, title, body, ref_type, ref_id
  )
  VALUES (
    p_staff_id, p_channel, p_event_type, p_title, p_body, p_ref_type, p_ref_id
  )
  RETURNING edoc.notification_logs.id INTO v_id;

  RETURN QUERY SELECT true, 'Tao log thong bao thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 8. FN: CAP NHAT TRANG THAI THONG BAO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notification_log_update_status(
  p_id            BIGINT,
  p_send_status   VARCHAR,
  p_error_message TEXT DEFAULT NULL
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT
)
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE edoc.notification_logs
  SET send_status   = p_send_status,
      error_message = p_error_message,
      sent_at       = CASE WHEN p_send_status = 'sent' THEN NOW() ELSE sent_at END
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay log thong bao'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cap nhat trang thai thong bao thanh cong'::TEXT;
END;
$$;

-- ==========================================
-- 9. FN: DANH SACH LOG THONG BAO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notification_log_get_list(
  p_staff_id    INT DEFAULT NULL,
  p_channel     VARCHAR DEFAULT NULL,
  p_send_status VARCHAR DEFAULT NULL,
  p_page        INT DEFAULT 1,
  p_page_size   INT DEFAULT 20
)
RETURNS TABLE (
  id            BIGINT,
  staff_id      INT,
  channel       VARCHAR,
  event_type    VARCHAR,
  title         VARCHAR,
  body          TEXT,
  ref_type      VARCHAR,
  ref_id        BIGINT,
  send_status   VARCHAR,
  error_message TEXT,
  sent_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ,
  total_count   BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_offset INT := (p_page - 1) * p_page_size;
  v_total  BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM edoc.notification_logs nl
  WHERE (p_staff_id IS NULL OR nl.staff_id = p_staff_id)
    AND (p_channel IS NULL OR p_channel = '' OR nl.channel = p_channel)
    AND (p_send_status IS NULL OR p_send_status = '' OR nl.send_status = p_send_status);

  RETURN QUERY
  SELECT
    nl.id,
    nl.staff_id,
    nl.channel,
    nl.event_type,
    nl.title,
    nl.body,
    nl.ref_type,
    nl.ref_id,
    nl.send_status,
    nl.error_message,
    nl.sent_at,
    nl.created_at,
    v_total
  FROM edoc.notification_logs nl
  WHERE (p_staff_id IS NULL OR nl.staff_id = p_staff_id)
    AND (p_channel IS NULL OR p_channel = '' OR nl.channel = p_channel)
    AND (p_send_status IS NULL OR p_send_status = '' OR nl.send_status = p_send_status)
  ORDER BY nl.created_at DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;

-- ==========================================
-- 10. FN: UPSERT CAU HINH THONG BAO
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notification_pref_upsert(
  p_staff_id   INT,
  p_channel    VARCHAR,
  p_is_enabled BOOLEAN DEFAULT true
)
RETURNS TABLE (
  success BOOLEAN,
  message TEXT,
  id      BIGINT
)
LANGUAGE plpgsql AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.notification_preferences (staff_id, channel, is_enabled, updated_at)
  VALUES (p_staff_id, p_channel, p_is_enabled, NOW())
  ON CONFLICT (staff_id, channel) DO UPDATE SET
    is_enabled = EXCLUDED.is_enabled,
    updated_at = NOW()
  RETURNING edoc.notification_preferences.id INTO v_id;

  RETURN QUERY SELECT true, 'Cap nhat cau hinh thong bao thanh cong'::TEXT, v_id;
END;
$$;

-- ==========================================
-- 11. FN: LAY CAU HINH THONG BAO THEO STAFF
-- ==========================================
CREATE OR REPLACE FUNCTION edoc.fn_notification_pref_get_by_staff(
  p_staff_id INT
)
RETURNS TABLE (
  id         BIGINT,
  channel    VARCHAR,
  is_enabled BOOLEAN
)
LANGUAGE plpgsql AS $$
BEGIN
  RETURN QUERY
  SELECT
    np.id,
    np.channel,
    np.is_enabled
  FROM edoc.notification_preferences np
  WHERE np.staff_id = p_staff_id
  ORDER BY np.channel;
END;
$$;
