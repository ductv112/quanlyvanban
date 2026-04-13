import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

export interface DelegationRow {
  id: number;
  from_staff_id: number;
  from_staff_name: string;
  to_staff_id: number;
  to_staff_name: string;
  start_date: string;
  end_date: string;
  note: string;
  is_revoked: boolean;
  revoked_at: string | null;
  created_at: string;
}

export const delegationRepository = {
  async getList(unitId: number, staffId: number | null): Promise<DelegationRow[]> {
    return callFunction<DelegationRow>('edoc.fn_delegation_get_list', [unitId, staffId]);
  },

  async create(
    fromStaffId: number,
    toStaffId: number,
    startDate: string,
    endDate: string,
    note: string,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_delegation_create',
      [fromStaffId, toStaffId, startDate, endDate, note],
    );
    return row ?? { success: false, message: 'Không thể tạo ủy quyền', id: 0 };
  },

  async revoke(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_delegation_revoke',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy ủy quyền' };
  },
};
