import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult } from './doc-book.repository.js';

export interface WorkCalendarRow {
  id: number;
  date: string;
  description: string;
  is_holiday: boolean;
  created_by: number;
}

export const workCalendarRepository = {
  async get(year: number): Promise<WorkCalendarRow[]> {
    return callFunction<WorkCalendarRow>('public.fn_work_calendar_get', [year]);
  },

  async setHoliday(date: string, description: string, createdBy: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_work_calendar_set_holiday',
      [date, description, createdBy],
    );
    return row ?? { success: false, message: 'Không thể thiết lập ngày nghỉ' };
  },

  async removeHoliday(date: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_work_calendar_remove_holiday',
      [date],
    );
    return row ?? { success: false, message: 'Không tìm thấy ngày nghỉ' };
  },
};
