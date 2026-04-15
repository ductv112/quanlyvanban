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

export const dashboardRepository = {
  // SP: fn_dashboard_get_stats(p_staff_id, p_unit_id) — staffId FIRST
  async getStats(staffId: number, unitId: number): Promise<DashboardStatsRow | null> {
    return callFunctionOne<DashboardStatsRow>(
      'edoc.fn_dashboard_get_stats',
      [staffId, unitId],
    );
  },

  // SP: fn_dashboard_recent_incoming(p_unit_id, p_limit)
  async getRecentIncoming(unitId: number, limit = 10): Promise<RecentIncomingRow[]> {
    return callFunction<RecentIncomingRow>(
      'edoc.fn_dashboard_recent_incoming',
      [unitId, limit],
    );
  },

  // SP: fn_dashboard_upcoming_tasks(p_staff_id, p_limit)
  async getUpcomingTasks(staffId: number, limit = 10): Promise<UpcomingTaskRow[]> {
    return callFunction<UpcomingTaskRow>(
      'edoc.fn_dashboard_upcoming_tasks',
      [staffId, limit],
    );
  },

  // SP: fn_dashboard_recent_outgoing(p_unit_id, p_limit)
  async getRecentOutgoing(unitId: number, limit = 10): Promise<RecentOutgoingRow[]> {
    return callFunction<RecentOutgoingRow>(
      'edoc.fn_dashboard_recent_outgoing',
      [unitId, limit],
    );
  },
};
