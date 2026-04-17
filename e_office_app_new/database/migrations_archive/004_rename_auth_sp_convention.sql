-- ============================================
-- MIGRATION 004: Rename Auth SPs theo convention
-- Convention: {schema}.fn_{module}_{action}
-- sp_auth_* → public.fn_auth_*
-- ============================================

-- 1. fn_auth_login
ALTER FUNCTION public.sp_auth_login(VARCHAR, VARCHAR, TEXT)
  RENAME TO fn_auth_login;

-- 2. fn_auth_log_login
ALTER FUNCTION public.sp_auth_log_login(INT, VARCHAR, VARCHAR, TEXT, BOOLEAN)
  RENAME TO fn_auth_log_login;

-- 3. fn_auth_save_refresh_token
ALTER FUNCTION public.sp_auth_save_refresh_token(INT, VARCHAR, TIMESTAMPTZ)
  RENAME TO fn_auth_save_refresh_token;

-- 4. fn_auth_verify_refresh_token
ALTER FUNCTION public.sp_auth_verify_refresh_token(VARCHAR)
  RENAME TO fn_auth_verify_refresh_token;

-- 5. fn_auth_logout
ALTER FUNCTION public.sp_auth_logout(VARCHAR)
  RENAME TO fn_auth_logout;

-- 6. fn_auth_logout_all
ALTER FUNCTION public.sp_auth_logout_all(INT)
  RENAME TO fn_auth_logout_all;

-- 7. fn_auth_get_me
ALTER FUNCTION public.sp_auth_get_me(INT)
  RENAME TO fn_auth_get_me;

-- 8. fn_auth_cleanup_expired_tokens
ALTER FUNCTION public.sp_auth_cleanup_expired_tokens()
  RENAME TO fn_auth_cleanup_expired_tokens;
