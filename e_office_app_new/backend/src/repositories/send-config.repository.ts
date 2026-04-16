import { callFunction, callFunctionOne } from '../lib/db/query.js';

export interface SendConfigRow {
  id: number;
  target_user_id: number;
  target_name: string;
  position_name: string;
  department_name: string;
}

export const sendConfigRepository = {

  async getByUser(userId: number, configType: string = 'doc'): Promise<SendConfigRow[]> {
    return callFunction<SendConfigRow>('edoc.fn_send_config_get_by_user', [userId, configType]);
  },

  async save(userId: number, configType: string, targetUserIds: number[]): Promise<{ success: boolean; message: string }> {
    const row = await callFunctionOne<{ success: boolean; message: string }>('edoc.fn_send_config_save', [userId, configType, targetUserIds]);
    return row ?? { success: false, message: 'Lỗi lưu cấu hình' };
  },
};
