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
  canApprove: boolean;     // duyet/huy duyet/but phe (chi lanh dao)
  canRelease: boolean;     // cap so VB di (sau khi lanh dao duyet) — van thu/chuyen vien thuc thi
  canSend: boolean;        // gui noi bo cho can bo xu ly
  canAssign: boolean;      // v3.2.5: giao viec / tao HSCV / them vao HSCV / gui lien thong — van thu/chuyen vien thuc thi
  canRetract: boolean;     // thu hoi (lanh dao)
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
 * v3.2.5 redesign — tach quyen theo dung nghiep vu thuc te VN:
 *   canEdit    = isAdmin || isOwner || (sameUnit && is_handle_document)  // sua metadata
 *   canApprove = isAdmin || (sameUnit && is_leader)                       // duyet/but phe — CHI lanh dao
 *   canRelease = isAdmin || isOwner || (sameUnit && is_handle_document)   // cap so VB di — van thu thuc thi sau khi duyet
 *   canSend    = isAdmin || isOwner || (sameUnit && is_handle_document)   // gui noi bo can bo xu ly
 *   canAssign  = isAdmin || isOwner || (sameUnit && is_handle_document)   // giao viec/HSCV/lien thong — van thu thuc thi
 *   canRetract = isAdmin || (sameUnit && is_leader)                       // thu hoi (lanh dao)
 *
 * Truoc redesign: tat ca action thao tac deu yeu cau is_leader → chuyen vien xu ly VB bi chan giao viec/cap so/gui lien thong.
 * Sai voi thuc te: lanh dao chi DUYET/BUT PHE/THU HOI; van thu/chuyen vien thuc thi cac thao tac con lai.
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
      canAssign: true,
      canRetract: true,
    };
  }
  const sameUnit = ctx.userUnitId === doc.unit_id;
  const isLeader = sameUnit && ctx.is_leader;
  const isHandler = sameUnit && ctx.is_handle_document;

  return {
    canEdit: isOwner || isHandler,
    canApprove: isLeader,
    canRelease: isOwner || isHandler,
    canSend: isOwner || isHandler,
    canAssign: isOwner || isHandler,
    canRetract: isLeader,
  };
}
