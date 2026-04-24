import { rawQuery } from '../db/query.js';
import { resolveAncestorUnit } from '../department-subtree.js';

export interface DocPermissionContext {
  staffId: number;
  departmentId: number;
  isAdmin: boolean;
}

export interface DocOwnershipInfo {
  id: number;
  unit_id: number;
}

export interface DocPermissions {
  canEdit: boolean;
  canApprove: boolean;
  canRelease: boolean;
  canSend: boolean;
  canRetract: boolean;
}

interface StaffPositionRow {
  is_leader: boolean;
  is_handle_document: boolean;
}

/**
 * Query position flag của staff.
 * Trả FALSE cho cả 2 flag nếu staff không tồn tại hoặc chưa gán position.
 */
async function getStaffPosition(staffId: number): Promise<StaffPositionRow> {
  const rows = await rawQuery<StaffPositionRow>(
    `SELECT COALESCE(p.is_leader, FALSE) AS is_leader,
            COALESCE(p.is_handle_document, FALSE) AS is_handle_document
       FROM public.staff s
       LEFT JOIN public.positions p ON p.id = s.position_id
      WHERE s.id = $1`,
    [staffId],
  );
  return rows[0] ?? { is_leader: false, is_handle_document: false };
}

/**
 * Context bắt buộc để compute permission — load 1 lần/request, tránh N+1 query khi list.
 */
export interface UserPermissionContext {
  staffId: number;
  userUnitId: number | null;
  isAdmin: boolean;
  is_leader: boolean;
  is_handle_document: boolean;
}

/**
 * Load user context (query 1 lần cho cả request).
 * - resolveAncestorUnit: nếu user đã ở top-unit thì trả chính nó
 * - Admin không cần position info nhưng vẫn load cho consistent
 */
export async function getUserPermissionContext(
  user: DocPermissionContext,
): Promise<UserPermissionContext> {
  const [userUnitId, pos] = await Promise.all([
    resolveAncestorUnit(user.departmentId),
    getStaffPosition(user.staffId),
  ]);
  return {
    staffId: user.staffId,
    userUnitId,
    isAdmin: user.isAdmin,
    is_leader: pos.is_leader,
    is_handle_document: pos.is_handle_document,
  };
}

/**
 * Compute permissions pure sync, nhận sẵn isOwner (caller tự tính).
 *
 * Rules (KHÔNG hard-code role/position name — chỉ flag + ownership + admin):
 *   canEdit    = isAdmin || isOwner || (sameUnit && is_handle_document)
 *   canApprove = isAdmin || (sameUnit && is_leader)
 *   canRelease = isAdmin || (sameUnit && is_leader)
 *   canSend    = isAdmin || isOwner || (sameUnit && is_leader)
 *   canRetract = isAdmin || (sameUnit && is_leader)
 *
 * Dùng trong loop list để tránh N+1.
 */
export function computePermsFromContext(
  ctx: UserPermissionContext,
  doc: DocOwnershipInfo,
  isOwner: boolean,
): DocPermissions {
  if (ctx.isAdmin) {
    return {
      canEdit: true,
      canApprove: true,
      canRelease: true,
      canSend: true,
      canRetract: true,
    };
  }
  const sameUnit = ctx.userUnitId === doc.unit_id;
  const isLeader = sameUnit && ctx.is_leader;
  const isHandler = sameUnit && ctx.is_handle_document;

  return {
    canEdit: isOwner || isHandler,
    canApprove: isLeader,
    canRelease: isLeader,
    canSend: isOwner || isLeader,
    canRetract: isLeader,
  };
}
