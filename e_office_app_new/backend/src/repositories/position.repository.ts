import { callFunction, callFunctionOne } from '../lib/db/query.js';

export interface PositionRow {
  id: number;
  name: string;
  code: string;
  sort_order: number;
  description: string;
  is_active: boolean;
  total_count: number;
}

export const positionRepository = {
  async getList(keyword: string, page: number, pageSize: number): Promise<PositionRow[]> {
    return callFunction<PositionRow>('public.fn_position_get_list', [keyword, page, pageSize]);
  },

  async getById(id: number): Promise<PositionRow | null> {
    return callFunctionOne<PositionRow>('public.fn_position_get_by_id', [id]);
  },

  async create(name: string, code: string, sortOrder: number, description: string): Promise<number | null> {
    const row = await callFunctionOne<{ fn_position_create: number }>(
      'public.fn_position_create',
      [name, code, sortOrder, description],
    );
    return row?.fn_position_create ?? null;
  },

  async update(
    id: number,
    name: string,
    code: string,
    sortOrder: number,
    description: string,
    isActive: boolean,
  ): Promise<boolean> {
    const row = await callFunctionOne<{ fn_position_update: boolean }>(
      'public.fn_position_update',
      [id, name, code, sortOrder, description, isActive],
    );
    return row?.fn_position_update ?? false;
  },

  async delete(id: number): Promise<{ success: boolean; message: string }> {
    const row = await callFunctionOne<{ success: boolean; message: string }>(
      'public.fn_position_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy chức vụ' };
  },
};
