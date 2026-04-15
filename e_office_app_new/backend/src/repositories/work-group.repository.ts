import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

export interface WorkGroupRow {
  id: number;
  unit_id: number;
  name: string;
  function: string;
  sort_order: number;
  member_count: number;
  created_at: string;
}

// SP: fn_work_group_get_members returns: (id, group_id, staff_id, staff_name, position_name, department_name, created_at)
export interface WorkGroupMemberRow {
  id: number;
  group_id: number;
  staff_id: number;
  staff_name: string;
  position_name: string;
  department_name: string;
  created_at: string;
}

export const workGroupRepository = {
  async getList(unitId: number): Promise<WorkGroupRow[]> {
    return callFunction<WorkGroupRow>('edoc.fn_work_group_get_list', [unitId]);
  },

  async getById(id: number): Promise<WorkGroupRow | null> {
    return callFunctionOne<WorkGroupRow>('edoc.fn_work_group_get_by_id', [id]);
  },

  async create(
    unitId: number,
    name: string,
    func: string,
    sortOrder: number,
    createdBy: number,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_work_group_create',
      [unitId, name, func, sortOrder, createdBy],
    );
    return row ?? { success: false, message: 'Không thể tạo nhóm làm việc', id: 0 };
  },

  async update(
    id: number,
    name: string,
    func: string,
    sortOrder: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_work_group_update',
      [id, name, func, sortOrder],
    );
    return row ?? { success: false, message: 'Không tìm thấy nhóm làm việc' };
  },

  async delete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_work_group_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy nhóm làm việc' };
  },

  async getMembers(groupId: number): Promise<WorkGroupMemberRow[]> {
    return callFunction<WorkGroupMemberRow>('edoc.fn_work_group_get_members', [groupId]);
  },

  async assignMembers(groupId: number, staffIds: number[]): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_work_group_assign_members',
      [groupId, staffIds],
    );
    return row ?? { success: false, message: 'Không thể cập nhật thành viên' };
  },
};
