import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

export interface SignerRow {
  id: number;
  unit_id: number;
  department_id: number;
  staff_id: number;
  staff_name: string;
  position_name: string;
  department_name: string;
  sort_order: number;
}

export const signerRepository = {
  async getList(unitId: number, departmentId: number | null): Promise<SignerRow[]> {
    return callFunction<SignerRow>('edoc.fn_signer_get_list', [unitId, departmentId]);
  },

  async create(unitId: number, departmentId: number, staffId: number): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_signer_create',
      [unitId, departmentId, staffId],
    );
    return row ?? { success: false, message: 'Không thể thêm người ký', id: 0 };
  },

  async delete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_signer_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy người ký' };
  },
};
