import {
  type DocPermissionContext,
  type DocPermissions,
  type UserPermissionContext,
  getUserPermissionContext,
  computePermsFromContext,
} from './_shared.js';

export interface OutgoingDocInfo {
  id: number;
  unit_id: number;
  drafting_user_id: number | null;
  created_by: number | null;
}

/**
 * Compute pure sync — dùng trong loop batch list (N+1 safe).
 * VB đi: isOwner = (staffId === drafting_user_id) OR (staffId === created_by).
 * Lý do: cả người soạn (drafting_user_id) lẫn người tạo record (created_by) đều coi là "owner".
 */
export function computeOutgoingPermsWithContext(
  ctx: UserPermissionContext,
  doc: OutgoingDocInfo,
): DocPermissions {
  const isDrafter = doc.drafting_user_id != null && ctx.staffId === doc.drafting_user_id;
  const isCreator = doc.created_by != null && ctx.staffId === doc.created_by;
  const isOwner = isDrafter || isCreator;
  return computePermsFromContext(ctx, { id: doc.id, unit_id: doc.unit_id }, isOwner);
}

/**
 * Async compute cho 1 doc (load ctx + pure compute).
 */
export async function computeOutgoingPermissions(
  user: DocPermissionContext,
  doc: OutgoingDocInfo,
): Promise<DocPermissions> {
  const ctx = await getUserPermissionContext(user);
  return computeOutgoingPermsWithContext(ctx, doc);
}
