import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

export interface DocFieldRow {
  id: number;
  unit_id: number;
  code: string;
  name: string;
  sort_order: number;
  is_active: boolean;
}

export const docFieldRepository = {
  async getList(unitId: number, keyword: string): Promise<DocFieldRow[]> {
    return callFunction<DocFieldRow>('edoc.fn_doc_field_get_list', [unitId, keyword]);
  },

  async getById(id: number): Promise<DocFieldRow | null> {
    return callFunctionOne<DocFieldRow>('edoc.fn_doc_field_get_by_id', [id]);
  },

  async create(unitId: number, code: string, name: string): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_doc_field_create',
      [unitId, code, name],
    );
    return row ?? { success: false, message: 'Không thể tạo lĩnh vực', id: 0 };
  },

  async update(
    id: number,
    code: string,
    name: string,
    sortOrder: number,
    isActive: boolean,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_doc_field_update',
      [id, code, name, sortOrder, isActive],
    );
    return row ?? { success: false, message: 'Không tìm thấy lĩnh vực' };
  },

  async delete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_doc_field_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy lĩnh vực' };
  },
};
