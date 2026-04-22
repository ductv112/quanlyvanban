-- ============================================================================
-- Phase 12 Plan 03: Seed 4 sign states cho UAT /ky-so/danh-sach
-- ============================================================================
-- KHÔNG dùng trong production — chỉ dev/test sau khi chạy seed 001+002.
-- Idempotent: re-run OK (DELETE marker-based + INSERT).
--
-- Sau khi apply, tab /ky-so/danh-sach của admin staff_id=1 sẽ có:
--   - need_sign:  1+ row (tuỳ seed 002 có sẵn attachment và can_sign — script KHÔNG tạo
--                 attachment mới; tab này dựa vào SP fn_sign_need_list_by_staff +
--                 fn_attachment_can_sign vốn allow admin với is_admin=true)
--   - pending:    1 row (txn fake đang chờ — expires_at = NOW()+3 phút)
--   - completed:  1 row (signed_file_path fake — download endpoint Plan 12-01 sẽ
--                 trả presigned URL nhưng MinIO không có object thật → HTTP 404
--                 khi browser mở URL; UI vẫn render nút + endpoint trả JSON đúng shape)
--   - failed:     1 row (error_message có marker PHASE12_SEED_ + Tooltip test)
--
-- Marker-based cleanup: provider_txn_id LIKE 'PHASE12_%'
-- Chạy lại nhiều lần an toàn — DELETE theo marker trước khi INSERT.
-- ============================================================================

BEGIN;

-- 1. Verify prerequisites (admin staff_id=1 + providers)
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.staff WHERE id = 1) THEN
    RAISE EXCEPTION 'Seed 001 required_data.sql chưa chạy — admin staff_id=1 không tồn tại';
  END IF;
  IF NOT EXISTS (
    SELECT 1 FROM public.signing_provider_config
    WHERE provider_code = 'SMARTCA_VNPT'
  ) THEN
    RAISE EXCEPTION 'Seed 001 chưa chạy — signing_provider_config không có SMARTCA_VNPT';
  END IF;
END $$;

-- 2. Cleanup marker-based (idempotent)
DELETE FROM edoc.sign_transactions
WHERE provider_txn_id LIKE 'PHASE12_%';

-- 3. Insert 3 txn: pending / completed / failed
--    Dùng 1 attachment_outgoing_docs mẫu bất kỳ (MIN id). Nếu seed 002 chưa chạy
--    và không có attachment → gracefully RETURN; 3 tab txn sẽ trống.
DO $$
DECLARE
  v_attachment_id BIGINT;
  v_doc_id BIGINT;
  v_file_name VARCHAR(500);
BEGIN
  SELECT a.id, a.outgoing_doc_id, a.file_name
    INTO v_attachment_id, v_doc_id, v_file_name
    FROM edoc.attachment_outgoing_docs a
    ORDER BY a.id
    LIMIT 1;

  IF v_attachment_id IS NULL THEN
    RAISE NOTICE '[PHASE12_SEED] Không có attachment_outgoing_docs nào — SKIP seed txn. Tab pending/completed/failed sẽ trống. Hãy chạy seed/002_demo_data.sql trước.';
    RETURN;
  END IF;

  RAISE NOTICE '[PHASE12_SEED] Dùng attachment_id=% (file=%) của outgoing_doc_id=%', v_attachment_id, v_file_name, v_doc_id;

  -- 3a. Pending transaction (đang chờ worker/OTP)
  INSERT INTO edoc.sign_transactions
    (staff_id, provider_code, provider_txn_id, attachment_id, attachment_type,
     doc_id, doc_type, status, retry_count,
     created_at, started_at, expires_at)
  VALUES
    (1, 'SMARTCA_VNPT', 'PHASE12_PENDING_001', v_attachment_id, 'outgoing',
     v_doc_id, 'outgoing_doc', 'pending', 0,
     NOW(), NOW(), NOW() + INTERVAL '3 minutes');

  -- 3b. Completed transaction (giả lập đã ký xong — signed_file_path fake)
  INSERT INTO edoc.sign_transactions
    (staff_id, provider_code, provider_txn_id, attachment_id, attachment_type,
     doc_id, doc_type, signature_base64, signed_file_path,
     status, retry_count,
     created_at, started_at, completed_at, expires_at)
  VALUES
    (1, 'SMARTCA_VNPT', 'PHASE12_COMPLETED_001', v_attachment_id, 'outgoing',
     v_doc_id, 'outgoing_doc',
     'PHASE12_FAKE_SIGNATURE_BASE64_FOR_UAT_ONLY',
     'signed/phase12/fake-signed-uat.pdf',
     'completed', 0,
     NOW() - INTERVAL '1 hour',
     NOW() - INTERVAL '59 minutes',
     NOW() - INTERVAL '58 minutes',
     NOW() + INTERVAL '2 minutes');

  -- 3c. Failed transaction (error_message có marker PHASE12_SEED_ để nhận dạng)
  INSERT INTO edoc.sign_transactions
    (staff_id, provider_code, provider_txn_id, attachment_id, attachment_type,
     doc_id, doc_type,
     status, error_message, retry_count,
     created_at, started_at, completed_at, expires_at)
  VALUES
    (1, 'SMARTCA_VNPT', 'PHASE12_FAILED_001', v_attachment_id, 'outgoing',
     v_doc_id, 'outgoing_doc',
     'failed',
     'PHASE12_SEED_Provider phản hồi: Người dùng từ chối xác nhận OTP trong thời gian cho phép (3 phút). Vui lòng thử lại hoặc liên hệ quản trị viên nếu sự cố tiếp diễn.',
     2,
     NOW() - INTERVAL '2 hours',
     NOW() - INTERVAL '119 minutes',
     NOW() - INTERVAL '117 minutes',
     NOW() - INTERVAL '116 minutes');

  RAISE NOTICE '[PHASE12_SEED] 3 sign_transactions (pending/completed/failed) INSERTED cho attachment_id=%, doc_id=%', v_attachment_id, v_doc_id;
END $$;

-- 4. Verify result
DO $$
DECLARE
  v_count INT;
  v_pending INT;
  v_completed INT;
  v_failed INT;
BEGIN
  SELECT COUNT(*) INTO v_count
    FROM edoc.sign_transactions
    WHERE provider_txn_id LIKE 'PHASE12_%';

  SELECT COUNT(*) INTO v_pending
    FROM edoc.sign_transactions
    WHERE provider_txn_id = 'PHASE12_PENDING_001' AND status = 'pending';

  SELECT COUNT(*) INTO v_completed
    FROM edoc.sign_transactions
    WHERE provider_txn_id = 'PHASE12_COMPLETED_001' AND status = 'completed';

  SELECT COUNT(*) INTO v_failed
    FROM edoc.sign_transactions
    WHERE provider_txn_id = 'PHASE12_FAILED_001' AND status = 'failed';

  IF v_count NOT IN (0, 3) THEN
    RAISE EXCEPTION 'Expected 0 or 3 seed txns, got %', v_count;
  END IF;

  RAISE NOTICE '[PHASE12_SEED] Verify kết quả: total=%, pending=%, completed=%, failed=%',
    v_count, v_pending, v_completed, v_failed;

  IF v_count = 3 THEN
    RAISE NOTICE '[PHASE12_SEED] OK — Login admin (staff_id=1) /ky-so/danh-sach để test 4 tab.';
  ELSE
    RAISE NOTICE '[PHASE12_SEED] Seed skip do chưa có attachment_outgoing_docs. Chạy seed/002_demo_data.sql trước.';
  END IF;
END $$;

COMMIT;

-- ============================================================================
-- HƯỚNG DẪN CHẠY
--
-- Linux/macOS:
--   docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 \
--     -f - < e_office_app_new/database/test_data/phase12_seed_sign_states.sql
--
-- Windows PowerShell:
--   Get-Content e_office_app_new/database/test_data/phase12_seed_sign_states.sql | `
--     docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1
--
-- Login UAT:
--   staff_id=1, username=admin, password=admin@123  (theo seed 001_required_data.sql)
--   URL: http://localhost:3000/ky-so/danh-sach
--
-- ============================================================================
-- CLEANUP (khi muốn xóa seed Phase 12 sau UAT)
--
--   DELETE FROM edoc.sign_transactions WHERE provider_txn_id LIKE 'PHASE12_%';
--
-- ============================================================================
