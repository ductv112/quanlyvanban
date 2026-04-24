import {
  type DocPermissionContext,
  type DocPermissions,
  type UserPermissionContext,
  getUserPermissionContext,
  computePermsFromContext,
} from './_shared.js';

// Re-export để route drafting không phải đổi import
export { getUserPermissionContext };
export type { DocPermissionContext, UserPermissionContext };

// Alias giữ backward-compat
export type DraftingPermissions = DocPermissions;

// DocInfo vẫn export (route drafting-doc.ts dùng)
export interface DocInfo {
  id: number;
  drafting_user_id: number | null;
  unit_id: number;
}

/**
 * Wrap compute — isOwner = staffId === drafting_user_id.
 * Dùng trong loop list để tránh N+1.
 */
export function computePermsWithContext(
  ctx: UserPermissionContext,
  doc: DocInfo,
): DraftingPermissions {
  const isOwner = doc.drafting_user_id != null && ctx.staffId === doc.drafting_user_id;
  return computePermsFromContext(ctx, { id: doc.id, unit_id: doc.unit_id }, isOwner);
}

/**
 * Mô hình v2 capability-based permission cho VB dự thảo.
 *
 * Rules (KHÔNG hard-code role/position name — chỉ flag + ownership + admin):
 *   canEdit    = isAdmin || isDrafter || (sameUnit && is_handle_document)
 *   canApprove = isAdmin || (sameUnit && is_leader)
 *   canRelease = isAdmin || (sameUnit && is_leader)
 *   canSend    = isAdmin || isDrafter || (sameUnit && is_leader)
 *   canRetract = isAdmin || (sameUnit && is_leader)
 */
export async function computeDraftingPermissions(
  user: DocPermissionContext,
  doc: DocInfo,
): Promise<DraftingPermissions> {
  const ctx = await getUserPermissionContext(user);
  return computePermsWithContext(ctx, doc);
}
