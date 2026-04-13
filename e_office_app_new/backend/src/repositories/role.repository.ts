import { callFunction, callFunctionOne } from '../lib/db/query.js';

export interface RoleRow {
  id: number;
  unit_id: number;
  name: string;
  description: string;
  created_at: string;
  updated_at: string;
}

export interface RoleRightRow {
  right_id: number;
}

export interface StaffRoleRow {
  role_id: number;
  role_name: string;
}

export const roleRepository = {
  async getList(unitId: number | null, keyword: string): Promise<RoleRow[]> {
    return callFunction<RoleRow>('public.fn_role_get_list', [unitId, keyword]);
  },

  async getById(id: number): Promise<RoleRow | null> {
    return callFunctionOne<RoleRow>('public.fn_role_get_by_id', [id]);
  },

  async create(unitId: number, name: string, description: string, createdBy: number): Promise<number | null> {
    const row = await callFunctionOne<{ fn_role_create: number }>(
      'public.fn_role_create',
      [unitId, name, description, createdBy],
    );
    return row?.fn_role_create ?? null;
  },

  async update(id: number, name: string, description: string, updatedBy: number): Promise<boolean> {
    const row = await callFunctionOne<{ fn_role_update: boolean }>(
      'public.fn_role_update',
      [id, name, description, updatedBy],
    );
    return row?.fn_role_update ?? false;
  },

  async delete(id: number): Promise<{ success: boolean; message: string }> {
    const row = await callFunctionOne<{ success: boolean; message: string }>(
      'public.fn_role_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy nhóm quyền' };
  },

  async getRights(roleId: number): Promise<RoleRightRow[]> {
    return callFunction<RoleRightRow>('public.fn_role_get_rights', [roleId]);
  },

  async assignRights(roleId: number, rightIds: number[]): Promise<void> {
    await callFunction('public.fn_role_assign_rights', [roleId, rightIds]);
  },

  async getStaffRoles(staffId: number): Promise<StaffRoleRow[]> {
    return callFunction<StaffRoleRow>('public.fn_staff_get_roles', [staffId]);
  },

  async assignStaffRoles(staffId: number, roleIds: number[]): Promise<void> {
    await callFunction('public.fn_staff_assign_roles', [staffId, roleIds]);
  },
};
