import {
  type DocPermissionContext,
  type DocPermissions,
  type UserPermissionContext,
  getUserPermissionContext,
  computePermsFromContext,
} from './_shared.js';

export interface IncomingDocInfo {
  id: number;
  unit_id: number;
  created_by: number | null;
}

/**
 * Compute pure sync — dùng trong loop batch list (N+1 safe).
 * VB đến: isOwner = staffId === created_by (người văn thư tạo VB — không có khái niệm "drafter").
 */
export function computeIncomingPermsWithContext(
  ctx: UserPermissionContext,
  doc: IncomingDocInfo,
): DocPermissions {
  const isOwner = doc.created_by != null && ctx.staffId === doc.created_by;
  return computePermsFromContext(ctx, { id: doc.id, unit_id: doc.unit_id }, isOwner);
}

/**
 * Async compute cho 1 doc (load ctx + pure compute).
 *
 * Ngữ nghĩa VB đến:
 * - canApprove = "duyệt VB đến" (vào sổ) + "giao xử lý" + "nhận bản giấy" (action lãnh đạo)
 * - canSend    = "gửi VB cho cán bộ xử lý nội bộ"
 * - canRetract = "thu hồi VB đã gửi" / "chuyển lại VB đã nhận"
 * - canRelease = không có endpoint ban hành VB đến, nhưng giữ field cho uniform
 */
export async function computeIncomingPermissions(
  user: DocPermissionContext,
  doc: IncomingDocInfo,
): Promise<DocPermissions> {
  const ctx = await getUserPermissionContext(user);
  return computeIncomingPermsWithContext(ctx, doc);
}
