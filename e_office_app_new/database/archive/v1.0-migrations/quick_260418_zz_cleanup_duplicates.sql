-- ZZ_ prefix để chạy SAU CÙNG (sort alphabet, sau tất cả quick_*.sql khác)
-- Drop duplicate function overloads — giữ overload mới nhất (OID cao nhất)
-- Cần chạy lại sau restore_030_to_037 vì script này tạo overload mới
-- → 2 overload cùng tồn tại → backend call ambiguous → 500

DO $$
DECLARE
  r RECORD;
  drop_count INTEGER := 0;
BEGIN
  FOR r IN
    SELECT n.nspname, p.proname, p.oid,
           pg_get_function_identity_arguments(p.oid) as args,
           ROW_NUMBER() OVER (PARTITION BY n.nspname, p.proname ORDER BY p.oid DESC) as rn
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname IN ('edoc', 'public', 'esto', 'cont', 'iso')
      AND p.proname LIKE 'fn_%'
      AND p.proname IN (
        SELECT p2.proname FROM pg_proc p2
        JOIN pg_namespace n2 ON n2.oid = p2.pronamespace
        WHERE n2.nspname IN ('edoc', 'public', 'esto', 'cont', 'iso')
          AND p2.proname LIKE 'fn_%'
        GROUP BY n2.nspname, p2.proname HAVING count(*) > 1
      )
  LOOP
    IF r.rn > 1 THEN
      EXECUTE format('DROP FUNCTION %I.%I(%s)', r.nspname, r.proname, r.args);
      RAISE NOTICE 'Dropped old overload: %.%(%)', r.nspname, r.proname, r.args;
      drop_count := drop_count + 1;
    END IF;
  END LOOP;
  RAISE NOTICE 'Total dropped: % duplicate overloads', drop_count;
END
$$;
