import { callFunctionOne, rawQuery } from './db/query.js';

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
 * - User thường, KHÔNG có filter:
 *     + Nếu staffId pass + is_leader=TRUE → expand subtree LÊN to don vi (ancestor unit) để leader xem toàn bộ VB đơn vị
 *     + Else → subtree của dept mình
 * - User thường có filter → subtree của filterDeptId (giữ nguyên — leader chọn phòng cụ thể)
 *
 * staffId là optional để backward compat. List endpoints nên pass staffId để leader xem dược toan don vi.
 */
export async function resolveDeptSubtree(
  departmentId: number,
  isAdmin: boolean,
  filterDeptId?: number,
  staffId?: number,
): Promise<number[] | null> {
  // Admin không chọn filter → thấy tất cả
  if (isAdmin && !filterDeptId) return null;

  // Non-admin, no filter, has staffId → check is_leader → expand to unit if leader.
  // v3.2.5: lanh dao co quyen giam sat toan bo VB cua don vi (Giam doc / Truong phong / Pho truong phong cua Sở thay het VB cua Sở).
  let targetDeptId: number;
  if (filterDeptId) {
    targetDeptId = filterDeptId;
  } else if (!isAdmin && staffId != null) {
    const rows = await rawQuery<{ is_leader: boolean }>(
      `SELECT COALESCE(p.is_leader, FALSE) AS is_leader
         FROM public.staff s LEFT JOIN public.positions p ON p.id = s.position_id
        WHERE s.id = $1`,
      [staffId],
    );
    if (rows[0]?.is_leader) {
      targetDeptId = await resolveAncestorUnit(departmentId);
    } else {
      targetDeptId = departmentId;
    }
  } else {
    targetDeptId = departmentId;
  }

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
