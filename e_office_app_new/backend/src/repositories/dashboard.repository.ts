import { callFunction, callFunctionOne } from '../lib/db/query.js';

// SP: edoc.fn_dashboard_get_stats(p_staff_id, p_unit_id)
// Returns: TABLE(incoming_unread bigint, outgoing_pending bigint, handling_total bigint, handling_overdue bigint)
export interface DashboardStatsRow {
  incoming_unread: number;
  outgoing_pending: number;
  handling_total: number;
  handling_overdue: number;
}

// SP: edoc.fn_dashboard_recent_incoming(p_unit_id, p_limit)
// Returns: TABLE(id bigint, doc_code varchar, abstract text, received_date timestamptz, urgency_name varchar, sender_name varchar)
export interface RecentIncomingRow {
  id: number;
  doc_code: string;
  abstract: string;
  received_date: string;
  urgency_name: string;
  sender_name: string;
}

// SP: edoc.fn_dashboard_upcoming_tasks(p_staff_id, p_limit)
// Returns: TABLE(id bigint, title varchar, open_date timestamptz, status smallint, progress_percent smallint, deadline timestamptz)
export interface UpcomingTaskRow {
  id: number;
  title: string;
  open_date: string;
  status: number;
  progress_percent: number;
  deadline: string;
}

// SP: edoc.fn_dashboard_recent_outgoing(p_unit_id, p_limit)
// Returns: TABLE(id bigint, doc_code varchar, abstract text, sent_date timestamptz, doc_type_name varchar)
export interface RecentOutgoingRow {
  id: number;
  doc_code: string;
  abstract: string;
  sent_date: string;
  doc_type_name: string;
}

// ---- Dashboard V2 types ----

export interface StatsExtraRow {
  drafting_pending: number;
  message_unread: number;
  notice_unread: number;
  today_meetings: number;
}

export interface DocByMonthRow {
  month_label: string;
  incoming_count: number;
  outgoing_count: number;
}

export interface TaskByStatusRow {
  status_code: number;
  status_name: string;
  task_count: number;
}

export interface TopDepartmentRow {
  department_id: number;
  department_name: string;
  doc_count: number;
}

export interface RecentNoticeRow {
  id: number;
  title: string;
  notice_type: string;
  created_at: string;
  is_read: boolean;
}

export interface CalendarTodayRow {
  id: number;
  title: string;
  start_time: string;
  end_time: string;
  all_day: boolean;
  color: string;
  scope: string;
}

export interface OntimeRateRow {
  total_completed: number;
  ontime_count: number;
  overdue_count: number;
  ontime_percent: number;
}

export interface DocByDepartmentRow {
  department_id: number;
  department_name: string;
  incoming_count: number;
  outgoing_count: number;
}

export const dashboardRepository = {
  // SP: fn_dashboard_get_stats(p_staff_id, p_unit_id, p_dept_ids)
  async getStats(staffId: number, unitId: number, deptIds?: number[] | null): Promise<DashboardStatsRow | null> {
    return callFunctionOne<DashboardStatsRow>(
      'edoc.fn_dashboard_get_stats',
      [staffId, unitId, deptIds ?? null],
    );
  },

  // SP: fn_dashboard_recent_incoming(p_unit_id, p_limit, p_dept_ids)
  async getRecentIncoming(unitId: number, limit = 10, deptIds?: number[] | null): Promise<RecentIncomingRow[]> {
    return callFunction<RecentIncomingRow>(
      'edoc.fn_dashboard_recent_incoming',
      [unitId, limit, deptIds ?? null],
    );
  },

  // SP: fn_dashboard_upcoming_tasks(p_staff_id, p_limit, p_dept_ids)
  async getUpcomingTasks(staffId: number, limit = 10, deptIds?: number[] | null): Promise<UpcomingTaskRow[]> {
    return callFunction<UpcomingTaskRow>(
      'edoc.fn_dashboard_upcoming_tasks',
      [staffId, limit, deptIds ?? null],
    );
  },

  // SP: fn_dashboard_recent_outgoing(p_unit_id, p_limit, p_dept_ids)
  async getRecentOutgoing(unitId: number, limit = 10, deptIds?: number[] | null): Promise<RecentOutgoingRow[]> {
    return callFunction<RecentOutgoingRow>(
      'edoc.fn_dashboard_recent_outgoing',
      [unitId, limit, deptIds ?? null],
    );
  },

  // ---- Dashboard V2 ----

  async getStatsExtra(staffId: number, deptIds?: number[] | null): Promise<StatsExtraRow | null> {
    return callFunctionOne<StatsExtraRow>(
      'edoc.fn_dashboard_get_stats_extra',
      [staffId, deptIds ?? null],
    );
  },

  async getDocByMonth(deptIds?: number[] | null, months = 6): Promise<DocByMonthRow[]> {
    return callFunction<DocByMonthRow>(
      'edoc.fn_dashboard_doc_by_month',
      [deptIds ?? null, months],
    );
  },

  async getTaskByStatus(staffId: number, deptIds?: number[] | null): Promise<TaskByStatusRow[]> {
    return callFunction<TaskByStatusRow>(
      'edoc.fn_dashboard_task_by_status',
      [staffId, deptIds ?? null],
    );
  },

  async getTopDepartments(deptIds?: number[] | null, limit = 5): Promise<TopDepartmentRow[]> {
    return callFunction<TopDepartmentRow>(
      'edoc.fn_dashboard_top_departments',
      [deptIds ?? null, limit],
    );
  },

  async getRecentNotices(staffId: number, deptIds?: number[] | null, limit = 5): Promise<RecentNoticeRow[]> {
    return callFunction<RecentNoticeRow>(
      'edoc.fn_dashboard_recent_notices',
      [staffId, deptIds ?? null, limit],
    );
  },

  async getCalendarToday(staffId: number, deptIds?: number[] | null, days = 7): Promise<CalendarTodayRow[]> {
    return callFunction<CalendarTodayRow>(
      'edoc.fn_dashboard_calendar_today',
      [staffId, deptIds ?? null, days],
    );
  },

  async getOntimeRate(deptIds?: number[] | null): Promise<OntimeRateRow | null> {
    return callFunctionOne<OntimeRateRow>(
      'edoc.fn_dashboard_ontime_rate',
      [deptIds ?? null],
    );
  },

  async getDocByDepartment(deptIds?: number[] | null): Promise<DocByDepartmentRow[]> {
    return callFunction<DocByDepartmentRow>(
      'edoc.fn_dashboard_doc_by_department',
      [deptIds ?? null],
    );
  },
};
