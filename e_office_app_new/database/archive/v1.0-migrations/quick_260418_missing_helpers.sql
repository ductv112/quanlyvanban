-- Restore helper SPs bị bỏ sót trong commit consolidate 3837d94
-- fn_get_department_subtree — đệ quy từ dept về tất cả children (subtree IDs)
-- fn_get_ancestor_unit — đệ quy từ dept lên đến root unit (is_unit=TRUE)

CREATE OR REPLACE FUNCTION public.fn_get_department_subtree(p_dept_id INT)
RETURNS INT[]
LANGUAGE sql STABLE
AS $$
  WITH RECURSIVE tree AS (
    SELECT id FROM public.departments WHERE id = p_dept_id AND is_deleted = FALSE
    UNION ALL
    SELECT d.id FROM public.departments d
    JOIN tree t ON d.parent_id = t.id
    WHERE d.is_deleted = FALSE
  )
  SELECT COALESCE(ARRAY(SELECT id FROM tree), ARRAY[p_dept_id]);
$$;

CREATE OR REPLACE FUNCTION public.fn_get_ancestor_unit(p_dept_id INT)
RETURNS INT
LANGUAGE sql STABLE
AS $$
  WITH RECURSIVE ancestors AS (
    SELECT id, parent_id, is_unit
    FROM public.departments
    WHERE id = p_dept_id AND is_deleted = FALSE
    UNION ALL
    SELECT d.id, d.parent_id, d.is_unit
    FROM public.departments d
    JOIN ancestors a ON d.id = a.parent_id
    WHERE d.is_deleted = FALSE
  )
  SELECT COALESCE(
    (SELECT id FROM ancestors WHERE is_unit = TRUE LIMIT 1),
    p_dept_id
  );
$$;
