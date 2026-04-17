-- ================================================================
-- Migration 029: Fix bugs from test report (2026-04-17)
-- A1: Fix fn_doc_column_get_all type_id smallint mismatch
-- ================================================================

BEGIN;

-- ============================================================
-- A1: Fix SP fn_doc_column_get_all — type_id phải là SMALLINT
-- ============================================================
DROP FUNCTION IF EXISTS edoc.fn_doc_column_get_all();
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_all()
RETURNS TABLE(
  id          INTEGER,
  type_id     SMALLINT,
  doc_type_name VARCHAR,
  column_name VARCHAR,
  label       VARCHAR,
  data_type   VARCHAR,
  max_length  INTEGER,
  sort_order  INTEGER,
  is_mandatory BOOLEAN,
  is_system   BOOLEAN
)
LANGUAGE plpgsql STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.type_id, dt.name, c.column_name, c.label, c.data_type,
         c.max_length, c.sort_order, c.is_mandatory, c.is_system
  FROM edoc.doc_columns c
  JOIN edoc.doc_types dt ON dt.id = c.type_id
  ORDER BY dt.name, c.sort_order;
END;
$$;

-- Also fix fn_doc_column_get_by_type if it has the same issue
CREATE OR REPLACE FUNCTION edoc.fn_doc_column_get_by_type(p_type_id SMALLINT)
RETURNS TABLE(
  id          INTEGER,
  type_id     SMALLINT,
  column_name VARCHAR,
  label       VARCHAR,
  data_type   VARCHAR,
  max_length  INTEGER,
  sort_order  INTEGER,
  is_mandatory BOOLEAN,
  is_system   BOOLEAN,
  is_show_all BOOLEAN,
  description TEXT
)
LANGUAGE plpgsql STABLE
AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.type_id, c.column_name, c.label, c.data_type,
         c.max_length, c.sort_order, c.is_mandatory, c.is_system,
         c.is_show_all, c.description
  FROM edoc.doc_columns c
  WHERE c.type_id = p_type_id
  ORDER BY c.sort_order;
END;
$$;

DO $$ BEGIN RAISE NOTICE '✅ Migration 029: Fixed fn_doc_column SPs (type_id smallint)'; END $$;

COMMIT;
