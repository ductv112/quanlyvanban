-- ============================================================================
-- fix-lgsp-config-prod.sql — One-shot fix cho prod KH Lang Son (Phase 37 go-live)
-- Date: 2026-05-21
-- ----------------------------------------------------------------------------
-- Van de:
--   /lgsp/cau-hinh tren prod doanhnghiep.vatk.org hien thi "Chua co cau hinh
--   LGSP nao" (0/0 connected). Nguyen nhan: seed/001 Phase 33.2 INSERT 9 row
--   vao edoc.lgsp_agency_config bi skip vi lookup unit_id voi filter
--   `parent_id IS NULL`, nhung tren prod 6 DN nam DUOI 'UBND tinh Lang Son'
--   (parent_id NOT NULL — hop le ve to chuc).
--
--   Tham khao chi tiet: thread chat 2026-05-21 + screenshot /quan-tri/don-vi.
-- ----------------------------------------------------------------------------
-- Cach fix (3 buoc, idempotent):
--   1. Update trigger fn_lgsp_agency_config_validate_root_unit:
--      Doi semantic tu "parent_id IS NULL" sang "lgsp_org_code IS NOT NULL".
--      (Same content as schema/000_schema_v3.0.sql sau Phase 37.2 fix.)
--   2. Lookup unit_id 6 DN theo lgsp_org_code (KHONG filter parent_id).
--   3. INSERT 9 row placeholder (6 prod + 3 sandbox) ON CONFLICT DO NOTHING.
--
-- Yeu cau truoc khi chay:
--   - SET app.signing_secret_key = '<JWT_SECRET tu backend/.env>';
--   - Su dung wrapper fix-lgsp-config-prod.ps1 de auto-set tu .env.
--
-- An toan:
--   - Idempotent: ON CONFLICT DO NOTHING (chay lai khong gay duplicate).
--   - Khong DROP, khong DELETE — chi UPDATE trigger + INSERT placeholder.
--   - secret_key_encrypted = 'placeholder_not_configured' → admin UI nhap that sau.
-- ============================================================================

\set ON_ERROR_STOP on

-- --- 1. Update trigger function (idempotent CREATE OR REPLACE) ---
CREATE OR REPLACE FUNCTION edoc.fn_lgsp_agency_config_validate_root_unit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $func$
DECLARE
  v_lgsp_code VARCHAR(13);
BEGIN
  SELECT lgsp_org_code INTO v_lgsp_code
    FROM public.departments
    WHERE id = NEW.unit_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'unit_id=% khong ton tai trong departments', NEW.unit_id
      USING ERRCODE = '23503';
  END IF;

  IF v_lgsp_code IS NULL OR length(trim(v_lgsp_code)) = 0 THEN
    RAISE EXCEPTION 'unit_id=% chua co lgsp_org_code. Set lgsp_org_code truoc khi cau hinh LGSP.',
      NEW.unit_id
      USING ERRCODE = '23514';
  END IF;

  RETURN NEW;
END;
$func$;

-- --- 2. Re-seed Phase 33.2 INSERT (no parent_id filter) ---
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
  -- Doc session var (set boi PowerShell wrapper)
  BEGIN
    v_key := current_setting('app.signing_secret_key', FALSE);
  EXCEPTION WHEN OTHERS THEN
    v_key := NULL;
  END;

  IF v_key IS NULL OR length(trim(v_key)) < 16 THEN
    RAISE EXCEPTION 'app.signing_secret_key chua set hoac < 16 ky tu. Chay qua wrapper fix-lgsp-config-prod.ps1.';
  END IF;

  -- Sync lgsp_org_code = code cho 6 DN neu KH set qua UI vao cot 'code' nhung
  -- 'lgsp_org_code' (cot ALTER them sau, khong hien UI) van NULL. Idempotent.
  UPDATE public.departments
     SET lgsp_org_code = code
   WHERE code IN ('H37.DN.001','H37.DN.002','H37.DN.003','H37.DN.004','H37.DN.005','H37.DN.006')
     AND (lgsp_org_code IS NULL OR lgsp_org_code = '');

  -- Lookup KHONG filter parent_id (6 DN co the la sub-unit cua UBND tinh)
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
    RAISE EXCEPTION 'Thieu 1 trong 6 DN lgsp_org_code H37.DN.001..006 trong departments. Check /quan-tri/don-vi.';
  END IF;

  -- DN.001 prod + sandbox
  INSERT INTO edoc.lgsp_agency_config (unit_id, environment, system_id, secret_key_encrypted, base_url, is_active, created_by, updated_by) VALUES
    (v_unit_dn_001, 'prod',    'H37.DN.001', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',                FALSE, 1, 1),
    (v_unit_dn_001, 'sandbox', 'H37.DN.001', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://trucltvb.langson.gov.vn/apithunghiem',   FALSE, 1, 1),
    (v_unit_dn_002, 'prod',    'H37.DN.002', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',                FALSE, 1, 1),
    (v_unit_dn_002, 'sandbox', 'H37.DN.002', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://trucltvb.langson.gov.vn/apithunghiem',   FALSE, 1, 1),
    (v_unit_dn_003, 'prod',    'H37.DN.003', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',                FALSE, 1, 1),
    (v_unit_dn_003, 'sandbox', 'H37.DN.003', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://trucltvb.langson.gov.vn/apithunghiem',   FALSE, 1, 1),
    (v_unit_dn_004, 'prod',    'H37.DN.004', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',                FALSE, 1, 1),
    (v_unit_dn_005, 'prod',    'H37.DN.005', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',                FALSE, 1, 1),
    (v_unit_dn_006, 'prod',    'H37.DN.006', pgp_sym_encrypt('placeholder_not_configured', v_key), 'https://apiltvb.langson.gov.vn',                FALSE, 1, 1)
  ON CONFLICT (unit_id, environment) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RAISE NOTICE 'INSERTed % row vao edoc.lgsp_agency_config (0 = da co tu lan chay truoc, idempotent OK)', v_count;

  PERFORM setval(pg_get_serial_sequence('edoc.lgsp_agency_config', 'id'),
                 COALESCE((SELECT MAX(id) FROM edoc.lgsp_agency_config), 1));
END $$;

-- --- 3. Verify ---
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
