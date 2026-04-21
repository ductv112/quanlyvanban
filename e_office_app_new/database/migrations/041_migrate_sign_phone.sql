-- ============================================================================
-- Migration 041: Migrate staff.sign_phone → staff_signing_config + DROP column
-- Requirements: MIG-03, MIG-04
-- Depends on: 040_signing_schema.sql (staff_signing_config table exists)
-- Idempotent: chạy 2 lần không fail (2nd run: cột đã drop → skip INSERT + DROP no-op)
--
-- Strategy (ATOMIC — toàn bộ trong 1 DO block, lỗi giữa chừng rollback tự động):
--   1. Guard: kiểm tra cột sign_phone còn tồn tại không (idempotent)
--   2. Count source rows có sign_phone non-empty
--   3. INSERT INTO staff_signing_config (provider_code='SMARTCA_VNPT', is_verified=FALSE)
--      — dùng EXECUTE (dynamic SQL) vì PL/pgSQL static sẽ fail parse khi cột đã drop
--   4. Verify target count >= source count → RAISE EXCEPTION nếu không
--   5. ALTER TABLE DROP COLUMN sign_phone
--
-- Note: sign_ca (chứng thư số) và sign_image (ảnh chữ ký scan) KHÔNG drop
-- (out of scope MIG-04 — giữ nguyên trong staff table cho UI hiển thị)
-- ============================================================================

DO $$
DECLARE
  v_column_exists BOOLEAN;
  v_source_count  INT := 0;
  v_target_count  INT := 0;
  v_inserted      INT := 0;
BEGIN
  -- ======== Guard: kiểm tra cột sign_phone còn tồn tại không ========
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name   = 'staff'
      AND column_name  = 'sign_phone'
  ) INTO v_column_exists;

  IF NOT v_column_exists THEN
    RAISE NOTICE '⚠️  Migration 041: Cột staff.sign_phone đã bị drop — skip (idempotent)';
    RETURN;
  END IF;

  -- ======== Count source rows có sign_phone non-empty ========
  -- Dùng EXECUTE dynamic SQL để PL/pgSQL không parse sign_phone tại compile time
  -- (nếu chạy 2nd run sau khi đã drop, PL/pgSQL static SELECT sẽ fail parse)
  EXECUTE 'SELECT COUNT(*) FROM public.staff
           WHERE sign_phone IS NOT NULL AND TRIM(sign_phone) != '''''
    INTO v_source_count;

  RAISE NOTICE '📊 Source: % staff có sign_phone non-empty', v_source_count;

  -- ======== Copy data sang staff_signing_config ========
  EXECUTE '
    INSERT INTO public.staff_signing_config
      (staff_id, provider_code, user_id, is_verified, created_at, updated_at)
    SELECT s.id,
           ''SMARTCA_VNPT''::VARCHAR,
           s.sign_phone::VARCHAR,
           FALSE,
           NOW(),
           NOW()
    FROM public.staff s
    WHERE s.sign_phone IS NOT NULL
      AND TRIM(s.sign_phone) != ''''
    ON CONFLICT (staff_id, provider_code) DO NOTHING
  ';

  GET DIAGNOSTICS v_inserted = ROW_COUNT;
  RAISE NOTICE '✅ Inserted % rows vào staff_signing_config', v_inserted;

  -- ======== Verify count match ========
  SELECT COUNT(*) FROM public.staff_signing_config
    WHERE provider_code = 'SMARTCA_VNPT'
    INTO v_target_count;

  RAISE NOTICE '📊 Target count (staff_signing_config WHERE provider=SMARTCA_VNPT): %', v_target_count;

  -- Target phải >= source (có thể > nếu user đã manual tạo config qua API mới trước migration)
  IF v_target_count < v_source_count THEN
    RAISE EXCEPTION 'Migration FAILED: target count (%) < source count (%) — rollback', v_target_count, v_source_count;
  END IF;

  -- ======== DROP column staff.sign_phone ========
  ALTER TABLE public.staff DROP COLUMN IF EXISTS sign_phone;
  RAISE NOTICE '✅ DROP COLUMN public.staff.sign_phone — hoàn tất';

  -- Note: sign_ca và sign_image KHÔNG drop (theo spec MIG-04 chỉ drop sign_phone)
  -- Lý do giữ: sign_ca (chứng thư số) có thể cần cho hiển thị subject;
  --            sign_image (ảnh chữ ký scan) dùng cho stamp PDF

  RAISE NOTICE '✅ Migration 041 HOÀN TẤT: % rows migrated, cột sign_phone đã drop', v_inserted;
END $$;

DO $$ BEGIN
  RAISE NOTICE '✅ Migration 041: staff.sign_phone → staff_signing_config + DROP column';
END $$;
