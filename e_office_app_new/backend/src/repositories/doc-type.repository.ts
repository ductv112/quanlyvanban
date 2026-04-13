import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

export interface DocTypeRow {
  id: number;
  type_id: number;
  parent_id: number | null;
  code: string;
  name: string;
  description: string;
  sort_order: number;
  notation_type: string;
  is_default: boolean;
}

export const docTypeRepository = {
  async getTree(typeId: number): Promise<DocTypeRow[]> {
    return callFunction<DocTypeRow>('edoc.fn_doc_type_get_tree', [typeId]);
  },

  async getById(id: number): Promise<DocTypeRow | null> {
    return callFunctionOne<DocTypeRow>('edoc.fn_doc_type_get_by_id', [id]);
  },

  async create(
    typeId: number,
    parentId: number | null,
    name: string,
    code: string,
    notationType: number,
    sortOrder: number,
    createdBy: number,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_doc_type_create',
      [typeId, parentId, name, code, notationType, sortOrder, createdBy],
    );
    return row ?? { success: false, message: 'Không thể tạo loại văn bản', id: 0 };
  },

  async update(
    id: number,
    parentId: number | null,
    name: string,
    code: string,
    notationType: number,
    sortOrder: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_doc_type_update',
      [id, parentId, name, code, notationType, sortOrder],
    );
    return row ?? { success: false, message: 'Không tìm thấy loại văn bản' };
  },

  async delete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_doc_type_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy loại văn bản' };
  },
};
