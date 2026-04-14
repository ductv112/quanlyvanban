import { callFunction, callFunctionOne, rawQuery } from '../lib/db/query.js';

// ============ Row types ============

export interface WorkflowListRow {
  id: number;
  name: string;
  version: string;
  doc_field_id: number;
  doc_field_name: string;
  is_active: boolean;
  step_count: number;
  created_at: string;
}

export interface WorkflowDetailRow {
  id: number;
  unit_id: number;
  name: string;
  version: string;
  doc_field_id: number;
  doc_field_name: string;
  is_active: boolean;
  created_by: number;
  created_at: string;
  updated_at: string;
}

export interface WorkflowStepRow {
  id: number;
  step_name: string;
  step_order: number;
  step_type: string;
  allow_sign: boolean;
  deadline_days: number;
  position_x: number;
  position_y: number;
}

export interface WorkflowStepLinkRow {
  id: number;
  from_step_id: number;
  to_step_id: number;
}

export interface WorkflowStepStaffRow {
  id: number;
  staff_id: number;
  staff_name: string;
  position_name: string;
  department_name: string;
}

export interface WorkflowDbResult {
  success: boolean;
  message: string;
  id?: number;
}

// ============ Repository ============

export const workflowRepository = {
  getList(unitId: number, docFieldId?: number | null, isActive?: boolean | null): Promise<WorkflowListRow[]> {
    return callFunction<WorkflowListRow>('edoc.fn_doc_flow_get_list', [
      unitId,
      docFieldId ?? null,
      isActive ?? null,
    ]);
  },

  getById(id: number): Promise<WorkflowDetailRow | null> {
    return callFunctionOne<WorkflowDetailRow>('edoc.fn_doc_flow_get_by_id', [id]);
  },

  create(unitId: number, name: string, version: string | null, docFieldId: number | null, createdBy: number): Promise<WorkflowDbResult | null> {
    return callFunctionOne<WorkflowDbResult>('edoc.fn_doc_flow_create', [
      unitId, name, version, docFieldId, createdBy,
    ]);
  },

  update(id: number, name: string, version: string | null, docFieldId: number | null, isActive: boolean | null): Promise<WorkflowDbResult | null> {
    return callFunctionOne<WorkflowDbResult>('edoc.fn_doc_flow_update', [
      id, name, version, docFieldId, isActive,
    ]);
  },

  delete(id: number): Promise<WorkflowDbResult | null> {
    return callFunctionOne<WorkflowDbResult>('edoc.fn_doc_flow_delete', [id]);
  },

  getSteps(flowId: number): Promise<WorkflowStepRow[]> {
    return callFunction<WorkflowStepRow>('edoc.fn_doc_flow_step_get_list', [flowId]);
  },

  createStep(
    flowId: number,
    stepName: string,
    stepOrder: number,
    stepType: string,
    allowSign: boolean,
    deadlineDays: number,
    posX: number,
    posY: number,
  ): Promise<WorkflowDbResult | null> {
    return callFunctionOne<WorkflowDbResult>('edoc.fn_doc_flow_step_create', [
      flowId, stepName, stepOrder, stepType, allowSign, deadlineDays, posX, posY,
    ]);
  },

  updateStep(
    stepId: number,
    stepName: string,
    stepOrder: number,
    stepType: string,
    allowSign: boolean,
    deadlineDays: number,
    posX: number,
    posY: number,
  ): Promise<WorkflowDbResult | null> {
    return callFunctionOne<WorkflowDbResult>('edoc.fn_doc_flow_step_update', [
      stepId, stepName, stepOrder, stepType, allowSign, deadlineDays, posX, posY,
    ]);
  },

  deleteStep(stepId: number): Promise<WorkflowDbResult | null> {
    return callFunctionOne<WorkflowDbResult>('edoc.fn_doc_flow_step_delete', [stepId]);
  },

  createStepLink(fromStepId: number, toStepId: number): Promise<WorkflowDbResult | null> {
    return callFunctionOne<WorkflowDbResult>('edoc.fn_doc_flow_step_link_create', [fromStepId, toStepId]);
  },

  deleteStepLink(linkId: number): Promise<WorkflowDbResult | null> {
    return callFunctionOne<WorkflowDbResult>('edoc.fn_doc_flow_step_link_delete', [linkId]);
  },

  getStepStaff(stepId: number): Promise<WorkflowStepStaffRow[]> {
    return callFunction<WorkflowStepStaffRow>('edoc.fn_doc_flow_step_get_staff', [stepId]);
  },

  assignStepStaff(stepId: number, staffIds: number[]): Promise<WorkflowDbResult | null> {
    return callFunctionOne<WorkflowDbResult>('edoc.fn_doc_flow_step_assign_staff', [stepId, staffIds]);
  },

  getStepLinks(stepIds: number[]): Promise<WorkflowStepLinkRow[]> {
    if (stepIds.length === 0) return Promise.resolve([]);
    return rawQuery<WorkflowStepLinkRow>(
      'SELECT * FROM edoc.doc_flow_step_links WHERE from_step_id = ANY($1) OR to_step_id = ANY($1)',
      [stepIds],
    );
  },
};
