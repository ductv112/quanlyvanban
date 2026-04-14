import { callFunction, callFunctionOne } from '../lib/db/query.js';

export interface CalendarEventRow {
  id: number;
  title: string;
  description: string;
  start_time: string;
  end_time: string;
  all_day: boolean;
  color: string;
  repeat_type: string;
  scope: string;
  unit_id: number;
  created_by: number;
  creator_name: string;
  created_at: string;
  updated_at: string;
}

interface DbResult {
  success: boolean;
  message: string;
  id?: number;
}

export const calendarRepository = {
  async getList(
    scope: string,
    unitId: number,
    staffId: number,
    start: string,
    end: string,
  ): Promise<CalendarEventRow[]> {
    return callFunction<CalendarEventRow>(
      'public.fn_calendar_event_get_list',
      [scope, unitId, staffId, start, end],
    );
  },

  async getById(id: number): Promise<CalendarEventRow | null> {
    return callFunctionOne<CalendarEventRow>(
      'public.fn_calendar_event_get_by_id',
      [id],
    );
  },

  async create(
    title: string,
    description: string | null,
    startTime: string,
    endTime: string,
    allDay: boolean,
    color: string | null,
    repeatType: string,
    scope: string,
    unitId: number | null,
    createdBy: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_calendar_event_create',
      [title, description, startTime, endTime, allDay, color, repeatType, scope, unitId, createdBy],
    );
    return row ?? { success: false, message: 'Không thể tạo sự kiện lịch' };
  },

  async update(
    id: number,
    title: string,
    description: string | null,
    startTime: string,
    endTime: string,
    allDay: boolean,
    color: string | null,
    repeatType: string,
    scope: string,
    unitId: number | null,
    staffId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_calendar_event_update',
      [id, title, description, startTime, endTime, allDay, color, repeatType, scope, unitId, staffId],
    );
    return row ?? { success: false, message: 'Không thể cập nhật sự kiện lịch' };
  },

  async delete(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_calendar_event_delete',
      [id, staffId],
    );
    return row ?? { success: false, message: 'Không thể xóa sự kiện lịch' };
  },
};
