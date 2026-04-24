import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult } from './doc-book.repository.js';

export interface DocColumnRow {
  id: number;
  type_id: number;
  column_name: string;
  label: string;
  is_mandatory: boolean;
  is_show_all: boolean;
  sort_order: number;
  description: string;
}

export const docColumnRepository = {
  async getList(typeId: number | null): Promise<DocColumnRow[]> {
    return callFunction<DocColumnRow>('edoc.fn_doc_column_get_list', [typeId]);
  },

  async update(
    id: number,
    label: string,
    isMandatory: boolean,
    isShowAll: boolean,
    sortOrder: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_doc_column_update',
      [id, label, isMandatory, isShowAll, sortOrder],
    );
    return row ?? { success: false, message: 'Không tìm thấy thuộc tính' };
  },

  async toggleVisibility(id: number): Promise<boolean> {
    const row = await callFunctionOne<{ fn_doc_column_toggle_visibility: boolean }>(
      'edoc.fn_doc_column_toggle_visibility',
      [id],
    );
    return row?.fn_doc_column_toggle_visibility ?? false;
  },
};
