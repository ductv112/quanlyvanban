import { callFunction, callFunctionOne } from '../lib/db/query.js';

// SP: edoc.fn_dashboard_get_stats(p_unit_id, p_staff_id)
// Returns: TABLE(incoming_unread bigint, outgoing_pending bigint, handling_total bigint, handling_overdue bigint)
export interface DashboardStatsRow {
  incoming_unread: number;
  outgoing_pending: number;
  handling_total: number;
  handling_overdue: number;
}

// SP: edoc.fn_dashboard_recent_incoming(p_unit_id, p_staff_id, p_limit)
// Returns: TABLE(id, number, notation, abstract, publish_unit, received_date, doc_type_name, urgent_id)
export interface RecentIncomingRow {
  id: number;
  number: number;
  notation: string;
  abstract: string;
  publish_unit: string;
  received_date: string;
  doc_type_name: string;
  urgent_id: number;
}

// SP: edoc.fn_dashboard_upcoming_tasks(p_staff_id, p_limit)
// Returns: TABLE(id, name, start_date, end_date, status, progress, curator_name)
export interface UpcomingTaskRow {
  id: number;
  name: string;
  start_date: string;
  end_date: string;
  status: number;
  progress: number;
  curator_name: string;
}

// SP: edoc.fn_dashboard_recent_outgoing(p_unit_id, p_staff_id, p_limit)
// Returns: TABLE(id, number, notation, abstract, publish_date, doc_type_name)
export interface RecentOutgoingRow {
  id: number;
  number: number;
  notation: string;
  abstract: string;
  publish_date: string;
  doc_type_name: string;
}

export const dashboardRepository = {
  // NOTE: SP signature is (p_unit_id, p_staff_id) — unitId FIRST, staffId SECOND
  async getStats(unitId: number, staffId: number): Promise<DashboardStatsRow | null> {
    return callFunctionOne<DashboardStatsRow>(
      'edoc.fn_dashboard_get_stats',
      [unitId, staffId],
    );
  },

  // SP signature: (p_unit_id, p_staff_id, p_limit)
  async getRecentIncoming(unitId: number, staffId: number, limit = 10): Promise<RecentIncomingRow[]> {
    return callFunction<RecentIncomingRow>(
      'edoc.fn_dashboard_recent_incoming',
      [unitId, staffId, limit],
    );
  },

  async getUpcomingTasks(staffId: number, limit = 10): Promise<UpcomingTaskRow[]> {
    return callFunction<UpcomingTaskRow>(
      'edoc.fn_dashboard_upcoming_tasks',
      [staffId, limit],
    );
  },

  // SP signature: (p_unit_id, p_staff_id, p_limit)
  async getRecentOutgoing(unitId: number, staffId: number, limit = 10): Promise<RecentOutgoingRow[]> {
    return callFunction<RecentOutgoingRow>(
      'edoc.fn_dashboard_recent_outgoing',
      [unitId, staffId, limit],
    );
  },
};
