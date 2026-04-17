import { callFunction, callFunctionOne } from '../lib/db/query.js';

// ============ Row types ============

export interface KpiRow {
  total: number;
  prev_period: number;
  current_period: number;
  completed: number;
  in_progress: number;
  overdue: number;
  overdue_percent: number;
}

export interface ReportByUnitRow {
  department_id: number;
  department_name: string;
  total: number;
  completed: number;
  in_progress: number;
  overdue: number;
  completion_rate: number;
}

export interface ReportByStaffRow {
  staff_id: number;
  staff_name: string;
  department_name: string;
  total: number;
  completed: number;
  in_progress: number;
  overdue: number;
  completion_rate: number;
}

// ============ Repository ============

export const handlingDocReportRepository = {
  getKpi(unitId: number, fromDate: string | null, toDate: string | null, deptIds?: number[] | null): Promise<KpiRow | null> {
    return callFunctionOne<KpiRow>('edoc.fn_handling_doc_kpi', [unitId, fromDate, toDate, deptIds ?? null]);
  },

  reportByUnit(unitId: number, fromDate: string | null, toDate: string | null, deptIds?: number[] | null): Promise<ReportByUnitRow[]> {
    return callFunction<ReportByUnitRow>('edoc.fn_report_handling_by_unit', [unitId, fromDate, toDate, deptIds ?? null]);
  },

  reportByResolver(unitId: number, fromDate: string | null, toDate: string | null, deptIds?: number[] | null): Promise<ReportByStaffRow[]> {
    return callFunction<ReportByStaffRow>('edoc.fn_report_handling_by_resolver', [unitId, fromDate, toDate, deptIds ?? null]);
  },

  reportByAssigner(unitId: number, fromDate: string | null, toDate: string | null, deptIds?: number[] | null): Promise<ReportByStaffRow[]> {
    return callFunction<ReportByStaffRow>('edoc.fn_report_handling_by_assigner', [unitId, fromDate, toDate, deptIds ?? null]);
  },
};
