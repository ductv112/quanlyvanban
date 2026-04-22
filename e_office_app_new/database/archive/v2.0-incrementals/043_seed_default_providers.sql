-- ============================================================================
-- Migration 043: Seed 2 provider configs mặc định (fix patch Phase 9 Plan 03)
-- Requirements: CFG-01, CFG-03 (seed SmartCA VNPT default active)
-- Depends on: 040_signing_schema.sql (bảng public.signing_provider_config)
-- Idempotent: chỉ INSERT nếu chưa tồn tại (WHERE NOT EXISTS)
--
-- LÝ DO: Hệ thống CHỈ CÓ 2 provider cố định (SmartCA VNPT + MySign Viettel).
--  UI không cho phép add/delete provider mới — chỉ sửa 2 row này. Seed sẵn
--  2 row để Admin vào trang /ky-so/cau-hinh thấy ngay 2 card cố định.
--
-- Credentials SmartCA VNPT lấy từ source cũ (.NET):
--   File: docs/source_code_cu/sources/OneWin.WebApp/SmartCA_VNPT/Model.cs
--   Dòng 136-137:
--     client_id     = "4d00-638392811079166938.apps.smartcaapi.com"
--     client_secret = "ZjA4MjE4NDg-MjU3Mi00ZDAw"   -- dev/demo key
--
-- CÁCH CHẠY:
--   1. Set session variable app.signing_secret_key TRƯỚC khi chạy file này:
--      SET app.signing_secret_key = 'qlvb-signing-dev-key-change-production-2026';
--      \i 043_seed_default_providers.sql
--
--   2. Hoặc 1 lệnh duy nhất qua docker:
--      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c \
--        "SET app.signing_secret_key='<key>'; \i /tmp/043.sql"
--
-- LƯU Ý: Key phải TRÙNG với env SIGNING_SECRET_KEY của backend, nếu không
--  backend sẽ không decrypt được client_secret khi gọi provider API.
-- ============================================================================

\set ON_ERROR_STOP on

DO $$
DECLARE
  v_key TEXT;
  v_existing_smartca INT;
  v_existing_mysign  INT;
  v_actor_id         INT;
BEGIN
  -- Đọc key từ session variable (set trước khi chạy file này)
  BEGIN
    v_key := current_setting('app.signing_secret_key', FALSE);
  EXCEPTION WHEN OTHERS THEN
    v_key := NULL;
  END;

  IF v_key IS NULL OR length(trim(v_key)) < 16 THEN
    RAISE EXCEPTION 'app.signing_secret_key chưa set hoặc quá ngắn (cần >= 16 ký tự). Chạy: SET app.signing_secret_key=''<key>'' trước khi \i file này';
  END IF;

  -- Lấy 1 admin staff_id làm created_by/updated_by (seed data, không cần actor thật)
  SELECT s.id INTO v_actor_id
    FROM public.staff s
    ORDER BY s.id ASC
    LIMIT 1;

  IF v_actor_id IS NULL THEN
    RAISE EXCEPTION 'Không tìm thấy staff nào để set created_by/updated_by — seed staff trước khi chạy migration này';
  END IF;

  -- ─────────────────────────────────────────────────────────────────────────
  -- 1. SmartCA VNPT — default active với credentials từ source cũ
  -- ─────────────────────────────────────────────────────────────────────────
  SELECT COUNT(*)::INT INTO v_existing_smartca
    FROM public.signing_provider_config
    WHERE provider_code = 'SMARTCA_VNPT';

  IF v_existing_smartca = 0 THEN
    INSERT INTO public.signing_provider_config (
      provider_code, provider_name, base_url, client_id, client_secret,
      profile_id, extra_config, is_active,
      created_by, updated_by
    )
    VALUES (
      'SMARTCA_VNPT',
      'SmartCA VNPT',
      'https://gwsca.vnpt.vn',
      '4d00-638392811079166938.apps.smartcaapi.com',
      pgp_sym_encrypt('ZjA4MjE4NDg-MjU3Mi00ZDAw', v_key),
      NULL,
      '{}'::jsonb,
      TRUE,
      v_actor_id, v_actor_id
    );
    RAISE NOTICE 'Đã seed SmartCA VNPT (is_active=TRUE) với credentials từ source cũ';
  ELSE
    RAISE NOTICE 'SmartCA VNPT đã tồn tại — bỏ qua INSERT';
  END IF;

  -- ─────────────────────────────────────────────────────────────────────────
  -- 2. MySign Viettel — chưa cấu hình (is_active=false, placeholder)
  -- ─────────────────────────────────────────────────────────────────────────
  SELECT COUNT(*)::INT INTO v_existing_mysign
    FROM public.signing_provider_config
    WHERE provider_code = 'MYSIGN_VIETTEL';

  IF v_existing_mysign = 0 THEN
    INSERT INTO public.signing_provider_config (
      provider_code, provider_name, base_url, client_id, client_secret,
      profile_id, extra_config, is_active,
      created_by, updated_by
    )
    VALUES (
      'MYSIGN_VIETTEL',
      'MySign Viettel',
      '',
      '',
      pgp_sym_encrypt('placeholder_not_configured', v_key),
      '',
      '{}'::jsonb,
      FALSE,
      v_actor_id, v_actor_id
    );
    RAISE NOTICE 'Đã seed MySign Viettel (is_active=FALSE, chưa cấu hình)';
  ELSE
    RAISE NOTICE 'MySign Viettel đã tồn tại — bỏ qua INSERT';
  END IF;

  RAISE NOTICE 'Migration 043: Seed default providers — OK';
END $$;
