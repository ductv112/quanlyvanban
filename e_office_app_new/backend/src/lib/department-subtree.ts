import { callFunctionOne } from './db/query.js';

interface SubtreeRow {
  fn_get_department_subtree: number[];
}

interface AncestorRow {
  fn_get_ancestor_unit: number;
}

/**
 * Resolve department ID thành mảng subtree IDs.
 * - Admin không filter → return null (thấy tất cả)
 * - Admin chọn filter cụ thể → return subtree của dept đó
 * - User thường → return subtree của dept mình
 */
export async function resolveDeptSubtree(
  departmentId: number,
  isAdmin: boolean,
  filterDeptId?: number,
): Promise<number[] | null> {
  // Admin không chọn filter → thấy tất cả
  if (isAdmin && !filterDeptId) return null;

  const targetDeptId = filterDeptId || departmentId;
  const row = await callFunctionOne<SubtreeRow>(
    'public.fn_get_department_subtree',
    [targetDeptId],
  );
  return row?.fn_get_department_subtree ?? [targetDeptId];
}

/**
 * Resolve department ID lên ancestor unit (is_unit=true).
 * Dùng cho catalog queries — phòng ban con kế thừa catalog từ đơn vị cha.
 */
export async function resolveAncestorUnit(departmentId: number): Promise<number> {
  const row = await callFunctionOne<AncestorRow>(
    'public.fn_get_ancestor_unit',
    [departmentId],
  );
  return row?.fn_get_ancestor_unit ?? departmentId;
}
