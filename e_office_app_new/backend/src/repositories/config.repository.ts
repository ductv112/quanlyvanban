import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult } from './doc-book.repository.js';

export interface ConfigRow {
  id: number;
  unit_id: number;
  key: string;
  value: string;
  description: string;
}

export const configRepository = {
  async getList(unitId: number): Promise<ConfigRow[]> {
    return callFunction<ConfigRow>('public.fn_config_get_list', [unitId]);
  },

  async upsert(unitId: number, key: string, value: string, description: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_config_upsert',
      [unitId, key, value, description],
    );
    return row ?? { success: false, message: 'Không thể cập nhật cấu hình' };
  },
};
