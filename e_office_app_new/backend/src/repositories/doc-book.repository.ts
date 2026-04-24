import { callFunction, callFunctionOne } from '../lib/db/query.js';

export interface DocBookRow {
  id: number;
  unit_id: number;
  type_id: number;
  name: string;
  description: string;
  sort_order: number;
  is_default: boolean;
  created_by: number;
  created_at: string;
}

export interface DbResult {
  success: boolean;
  message: string;
}

export interface DbResultWithId extends DbResult {
  id: number;
}

export const docBookRepository = {
  async getList(typeId: number | null, unitId: number): Promise<DocBookRow[]> {
    return callFunction<DocBookRow>('edoc.fn_doc_book_get_list', [typeId, unitId]);
  },

  async getById(id: number): Promise<DocBookRow | null> {
    return callFunctionOne<DocBookRow>('edoc.fn_doc_book_get_by_id', [id]);
  },

  async create(
    typeId: number,
    unitId: number,
    name: string,
    isDefault: boolean,
    description: string,
    createdBy: number,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_doc_book_create',
      [typeId, unitId, name, isDefault, description, createdBy],
    );
    return row ?? { success: false, message: 'Không thể tạo sổ văn bản', id: 0 };
  },

  async update(
    id: number,
    name: string,
    isDefault: boolean,
    description: string,
    sortOrder: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_doc_book_update',
      [id, name, isDefault, description, sortOrder],
    );
    return row ?? { success: false, message: 'Không tìm thấy sổ văn bản' };
  },

  async delete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_doc_book_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy sổ văn bản' };
  },

  async setDefault(id: number, typeId: number, unitId: number): Promise<boolean> {
    const row = await callFunctionOne<{ fn_doc_book_set_default: boolean }>(
      'edoc.fn_doc_book_set_default',
      [id, typeId, unitId],
    );
    return row?.fn_doc_book_set_default ?? false;
  },
};
