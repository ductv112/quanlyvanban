-- ============================================================================
-- Migration 042: Signing stats SP — CFG-07 (Admin config page stats)
-- Requirements: CFG-07
-- Depends on: 040_signing_schema.sql (staff_signing_config + edoc.sign_transactions)
-- Idempotent: CREATE OR REPLACE
--
-- Phase 9 - Plan 02 - Task 1
-- NOTE: Migration number 042 thay vì 041 (plan draft ghi 041) — 041 đã dùng cho
--       `migrate_sign_phone` trong Phase 8. Deviation Rule 3 (blocker — không thể
--       đè migration hiện có).
--
-- Returns 5 stats per provider_code:
--   - total_users:           total rows trong staff_signing_config
--   - verified_users:        rows với is_verified=TRUE
--   - monthly_transactions:  sign_transactions trong tháng hiện tại
--   - monthly_completed:     completed trong tháng hiện tại
--   - monthly_failed:        failed + expired + cancelled trong tháng hiện tại
--
-- Reserved-word guard: `status` là reserved → quote bằng "status" trong
-- RETURNS TABLE và SELECT (per CLAUDE.md checklist #4). Phase 8 migration 040
-- đã follow pattern này ở bảng edoc.sign_transactions.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.fn_signing_stats(
  p_provider_code VARCHAR(30)
)
RETURNS TABLE(
  total_users          INT,
  verified_users       INT,
  monthly_transactions INT,
  monthly_completed    INT,
  monthly_failed       INT
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT
    COALESCE((
      SELECT COUNT(*)::INT
        FROM public.staff_signing_config
       WHERE provider_code = p_provider_code
    ), 0),
    COALESCE((
      SELECT COUNT(*)::INT
        FROM public.staff_signing_config
       WHERE provider_code = p_provider_code
         AND is_verified = TRUE
    ), 0),
    COALESCE((
      SELECT COUNT(*)::INT
        FROM edoc.sign_transactions
       WHERE provider_code = p_provider_code
         AND created_at >= date_trunc('month', NOW())
    ), 0),
    COALESCE((
      SELECT COUNT(*)::INT
        FROM edoc.sign_transactions
       WHERE provider_code = p_provider_code
         AND "status" = 'completed'
         AND created_at >= date_trunc('month', NOW())
    ), 0),
    COALESCE((
      SELECT COUNT(*)::INT
        FROM edoc.sign_transactions
       WHERE provider_code = p_provider_code
         AND "status" IN ('failed', 'expired', 'cancelled')
         AND created_at >= date_trunc('month', NOW())
    ), 0);
END;
$$;

COMMENT ON FUNCTION public.fn_signing_stats(VARCHAR) IS
  'Phase 9 CFG-07: trả stats per provider cho Admin dashboard (total_users, verified_users, monthly_transactions, monthly_completed, monthly_failed). NULL input → all 0s.';
