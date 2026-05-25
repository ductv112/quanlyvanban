-- ============================================================================
-- seed/003_lang_son_init.sql — Init server moi cho 6 DN tinh Lang Son
-- Date: 2026-05-25
-- ----------------------------------------------------------------------------
-- Muc dich:
--   Sau khi seed/001_required_data.sql tao 5 unit demo Lao Cai (UBND + 4 So),
--   file nay BIEN DOI cay to chuc cho phu hop server Lang Son:
--     1. Rename UBND tinh Lao Cai (id=1) -> UBND tinh Lang Son
--     2. Xoa 4 So Lao Cai demo (id=2..5) - chi an toan tren fresh install
--     3. Insert 6 DN lam child cua UBND tinh Lang Son (id=1)
--        Code = lgsp_org_code = H37.DN.001..006
--     4. Insert 9 row edoc.lgsp_agency_config placeholder (6 prod + 3 sandbox)
--     5. Cap nhat email admin
--
-- LUU Y CAU TRUC (theo deploy/fix-lgsp-config-prod.sql + commit b056abb):
--   - 6 DN nam DUOI 'UBND tinh Lang Son' (parent_id = 1, KHONG phai root)
--   - Lookup lgsp_agency_config theo lgsp_org_code (KHONG filter parent_id)
--   - Trigger validate_root_unit kiem tra lgsp_org_code IS NOT NULL
--
-- IDEMPOTENT: chay 2+ lan khong gay duplicate, khong loi.
--   - UPDATE WHERE id=1 AND code='UBND' -> no-op khi da rename
--   - DELETE WHERE id IN (2,3,4,5) AND code IN (...) -> no-op khi da xoa
--   - INSERT ... SELECT WHERE NOT EXISTS -> skip khi da insert
--   - INSERT lgsp_agency_config ON CONFLICT (unit_id, environment) DO NOTHING
--
-- YEU CAU TRUOC KHI CHAY:
--   SET app.signing_secret_key = '<JWT_SECRET tu backend/.env>' (>= 16 chars)
--   Deploy script (deploy-windows.ps1) tu dong set env var nay.
--
-- CACH CHAY:
--   psql -U qlvb_admin -d qlvb_prod -v ON_ERROR_STOP=1 \
--     -c "SET app.signing_secret_key='...';" \
--     -f e_office_app_new/database/seed/003_lang_son_init.sql
-- ============================================================================

\set ON_ERROR_STOP on

BEGIN;

-- ─── 1. Rename root: UBND tinh Lao Cai -> UBND tinh Lang Son ────────────────
UPDATE public.departments
   SET name = 'UBND tỉnh Lạng Sơn',
       short_name = 'UBND LS'
 WHERE id = 1
   AND code = 'UBND';

-- ─── 2. Xoa 4 So demo Lao Cai (chi an toan tren fresh install) ──────────────
-- Idempotent: chay lai sau khi da xoa -> 0 row affected
-- An toan: chi xoa khi code khop chinh xac (tranh xoa nham don vi that)
-- KHONG xoa cascade: neu admin da tao staff/data thuoc 1 trong 4 So nay,
-- DELETE se fail voi FK violation -> seed abort -> can xu ly thu cong.
DELETE FROM public.departments
 WHERE id IN (2, 3, 4, 5)
   AND code IN ('SNV', 'STC', 'STTTT', 'VPUBND');

-- ─── 3. Cap nhat email admin sang domain langson ────────────────────────────
UPDATE public.staff
   SET email = 'admin@langson.gov.vn'
 WHERE id = 1
   AND username = 'admin'
   AND email = 'admin@laocai.gov.vn';

-- ─── 4. Insert 6 DN lam child cua UBND tinh Lang Son ────────────────────────
-- Pattern: INSERT ... SELECT WHERE NOT EXISTS de idempotent
-- code = lgsp_org_code = H37.DN.001..006 (set luon de seed Phase 33 khong can UPDATE)

INSERT INTO public.departments
       (parent_id, code, name, short_name, is_unit, level, sort_order, allow_doc_book, created_by, lgsp_org_code)
SELECT 1, 'H37.DN.001', 'Công ty CP Hữu nghị Xuân Cương', 'Xuân Cương', true, 1, 1, true, 1, 'H37.DN.001'
 WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE code = 'H37.DN.001');

INSERT INTO public.departments
       (parent_id, code, name, short_name, is_unit, level, sort_order, allow_doc_book, created_by, lgsp_org_code)
SELECT 1, 'H37.DN.002', 'Công ty CP Sản xuất và Thương Mại Lạng Sơn', 'SX TM LS', true, 1, 2, true, 1, 'H37.DN.002'
 WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE code = 'H37.DN.002');

INSERT INTO public.departments
       (parent_id, code, name, short_name, is_unit, level, sort_order, allow_doc_book, created_by, lgsp_org_code)
SELECT 1, 'H37.DN.003', 'Công ty CP Tập đoàn đầu tư và xây dựng Phú Lộc', 'Phú Lộc', true, 1, 3, true, 1, 'H37.DN.003'
 WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE code = 'H37.DN.003');

INSERT INTO public.departments
       (parent_id, code, name, short_name, is_unit, level, sort_order, allow_doc_book, created_by, lgsp_org_code)
SELECT 1, 'H37.DN.004', 'Công ty CP Kim loại màu Bắc Bộ', 'KLM Bắc Bộ', true, 1, 4, true, 1, 'H37.DN.004'
 WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE code = 'H37.DN.004');

INSERT INTO public.departments
       (parent_id, code, name, short_name, is_unit, level, sort_order, allow_doc_book, created_by, lgsp_org_code)
SELECT 1, 'H37.DN.005', 'Công ty TNHH Thương mại xây dựng Thiên Phú', 'Thiên Phú', true, 1, 5, true, 1, 'H37.DN.005'
 WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE code = 'H37.DN.005');

INSERT INTO public.departments
       (parent_id, code, name, short_name, is_unit, level, sort_order, allow_doc_book, created_by, lgsp_org_code)
SELECT 1, 'H37.DN.006', 'Công ty TNHH một thành viên Xe điện DK Việt Nhật', 'Xe điện DK', true, 1, 6, true, 1, 'H37.DN.006'
 WHERE NOT EXISTS (SELECT 1 FROM public.departments WHERE code = 'H37.DN.006');

-- Setval sequence sau bulk insert (CLAUDE.md pitfall #12)
SELECT setval(pg_get_serial_sequence('public.departments', 'id'),
              GREATEST((SELECT MAX(id) FROM public.departments), 100));

-- ─── 5. Insert 9 row lgsp_agency_config placeholder (is_active=FALSE) ───────
-- 6 DN x prod (luon co) + 3 DN dau co them sandbox (DN.001/002/003)
-- secret_key = pgp_sym_encrypt('placeholder_not_configured', SIGNING_SECRET_KEY)
-- Admin se nhap credential that qua UI /lgsp/cau-hinh sau khi go-live.

DO $$
DECLARE
  v_key TEXT;
  v_unit_dn_001 INT;
  v_unit_dn_002 INT;
  v_unit_dn_003 INT;
  v_unit_dn_004 INT;
  v_unit_dn_005 INT;
  v_unit_dn_006 INT;
  v_count INT;
BEGIN
  BEGIN
    v_key := current_setting('app.signing_secret_key', FALSE);
  EXCEPTION WHEN OTHERS THEN
    v_key := NULL;
  END;

  IF v_key IS NULL OR length(trim(v_key)) < 16 THEN
    RAISE EXCEPTION 'app.signing_secret_key chua set hoac < 16 ky tu. Chay qua wrapper deploy-windows.ps1.';
  END IF;

  -- Lookup unit_id theo lgsp_org_code (KHONG filter parent_id - 6 DN la child cua UBND)
  SELECT id INTO v_unit_dn_001 FROM public.departments WHERE lgsp_org_code = 'H37.DN.001' LIMIT 1;
  SELECT id INTO v_unit_dn_002 FROM public.departments WHERE lgsp_org_code = 'H37.DN.002' LIMIT 1;
  SELECT id INTO v_unit_dn_003 FROM public.departments WHERE lgsp_org_code = 'H37.DN.003' LIMIT 1;
  SELECT id INTO v_unit_dn_004 FROM public.departments WHERE lgsp_org_code = 'H37.DN.004' LIMIT 1;
  SELECT id INTO v_unit_dn_005 FROM public.departments WHERE lgsp_org_code = 'H37.DN.005' LIMIT 1;
  SELECT id INTO v_unit_dn_006 FROM public.departments WHERE lgsp_org_code = 'H37.DN.006' LIMIT 1;

  RAISE NOTICE 'Lookup unit_id: DN.001=%, DN.002=%, DN.003=%, DN.004=%, DN.005=%, DN.006=%',
    v_unit_dn_001, v_unit_dn_002, v_unit_dn_003, v_unit_dn_004, v_unit_dn_005, v_unit_dn_006;

  IF v_unit_dn_001 IS NULL OR v_unit_dn_002 IS NULL OR v_unit_dn_003 IS NULL
     OR v_unit_dn_004 IS NULL OR v_unit_dn_005 IS NULL OR v_unit_dn_006 IS NULL THEN
    RAISE EXCEPTION 'Thieu 1 trong 6 DN lgsp_org_code H37.DN.001..006 sau buoc 4.';
  END IF;

  INSERT INTO edoc.lgsp_agency_config
         (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by)
  VALUES
    (v_unit_dn_001, 'prod',    'H37.DN.001', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',              FALSE, 1, 1),
    (v_unit_dn_001, 'sandbox', 'H37.DN.001', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://trucltvb.langson.gov.vn/apithunghiem', FALSE, 1, 1),
    (v_unit_dn_002, 'prod',    'H37.DN.002', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',              FALSE, 1, 1),
    (v_unit_dn_002, 'sandbox', 'H37.DN.002', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://trucltvb.langson.gov.vn/apithunghiem', FALSE, 1, 1),
    (v_unit_dn_003, 'prod',    'H37.DN.003', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',              FALSE, 1, 1),
    (v_unit_dn_003, 'sandbox', 'H37.DN.003', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://trucltvb.langson.gov.vn/apithunghiem', FALSE, 1, 1),
    (v_unit_dn_004, 'prod',    'H37.DN.004', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',              FALSE, 1, 1),
    (v_unit_dn_005, 'prod',    'H37.DN.005', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',              FALSE, 1, 1),
    (v_unit_dn_006, 'prod',    'H37.DN.006', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',              FALSE, 1, 1)
  ON CONFLICT (unit_id, environment) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'INSERTed % row vao edoc.lgsp_agency_config (0 = da co tu lan chay truoc, idempotent OK)', v_count;

  PERFORM setval(pg_get_serial_sequence('edoc.lgsp_agency_config', 'id'),
                 COALESCE((SELECT MAX(id) FROM edoc.lgsp_agency_config), 1));
END $$;

COMMIT;

-- ─── Verify ─────────────────────────────────────────────────────────────────
SELECT id, parent_id, code, name, short_name, lgsp_org_code, level
  FROM public.departments
 WHERE id = 1 OR lgsp_org_code LIKE 'H37.DN.%'
 ORDER BY COALESCE(parent_id, 0), id;

SELECT
  c.id,
  d.name AS don_vi,
  c.environment,
  c.system_id,
  CASE WHEN length(c.base_url) > 40 THEN substring(c.base_url, 1, 37) || '...' ELSE c.base_url END AS base_url,
  c.is_active
FROM edoc.lgsp_agency_config c
JOIN public.departments d ON d.id = c.unit_id
WHERE d.lgsp_org_code LIKE 'H37.DN.%'
ORDER BY c.system_id, c.environment;
