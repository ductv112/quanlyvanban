import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

// ============ Row types ============

export interface HandlingDocListRow {
  id: number;
  name: string;
  start_date: string;
  end_date: string;
  status: number;
  curator_id: number;
  curator_name: string;
  signer_id: number;
  signer_name: string;
  progress: number;
  doc_field_name: string;
  doc_type_name: string;
  created_at: string;
  total_count: number;
}

export interface HandlingDocDetailRow {
  id: number;
  unit_id: number;
  unit_name: string;
  department_id: number;
  department_name: string;
  name: string;
  abstract: string;
  comments: string;
  doc_notation: string;
  doc_type_id: number;
  doc_type_name: string;
  doc_field_id: number;
  doc_field_name: string;
  start_date: string;
  end_date: string;
  curator_id: number;
  curator_name: string;
  signer_id: number;
  signer_name: string;
  status: number;
  progress: number;
  workflow_id: number;
  workflow_name: string;
  parent_id: number;
  parent_name: string;
  is_from_doc: boolean;
  created_by: number;
  created_at: string;
  updated_at: string;
  // HDSD 3.2 — Lấy số (4 field bổ sung từ fn_handling_doc_get_by_id)
  number: number | null;
  sub_number: string | null;
  doc_book_id: number | null;
  doc_book_name: string | null;
  // Gap D (HDSD III.2.5): Hủy HSCV
  cancel_reason: string | null;
  cancelled_at: string | null;
  cancelled_by: number | null;
}

export interface StatusCountRow {
  filter_type: string;
  count: number;
}

export interface StaffAssignmentRow {
  id: number;
  staff_id: number;
  staff_name: string;
  position_name: string;
  department_name: string;
  role: number;
  step: string;
  assigned_at: string;
  completed_at: string;
}

export interface OpinionRow {
  id: number;
  staff_id: number;
  staff_name: string;
  content: string;
  attachment_path: string;
  created_at: string;
}

export interface LinkedDocRow {
  link_id: number;
  doc_id: number;
  doc_type: string;
  doc_number: number;
  doc_notation: string;
  doc_abstract: string;
  doc_date: string;
}

export interface AttachmentRow {
  id: number;
  file_name: string;
  file_path: string;
  file_size: number;
  content_type: string;
  sort_order: number;
  created_by: number;
  created_by_name: string;
  created_at: string;
}

// ============ Repository ============

export const handlingDocRepository = {

  // --- 5.1 List ---
  async getList(
    unitId: number,
    deptIds: number[] | null,
    staffId: number,
    filters: {
      status?: number;
      filterType?: string;
      keyword?: string;
      fromDate?: string;
      toDate?: string;
      page?: number;
      pageSize?: number;
    } = {},
  ): Promise<HandlingDocListRow[]> {
    return callFunction<HandlingDocListRow>('edoc.fn_handling_doc_get_list', [
      unitId,
      deptIds ?? null,
      staffId,
      filters.status ?? null,
      filters.filterType ?? null,
      filters.keyword ?? null,
      filters.fromDate ?? null,
      filters.toDate ?? null,
      filters.page ?? 1,
      filters.pageSize ?? 20,
    ]);
  },

  async countByStatus(unitId: number, staffId: number, deptIds?: number[] | null): Promise<StatusCountRow[]> {
    return callFunction<StatusCountRow>('edoc.fn_handling_doc_count_by_status', [unitId, staffId, deptIds ?? null]);
  },

  // --- 5.3 Detail ---
  async getById(id: number): Promise<HandlingDocDetailRow | null> {
    return callFunctionOne<HandlingDocDetailRow>('edoc.fn_handling_doc_get_by_id', [id]);
  },

  // --- 5.2 CRUD ---
  async create(params: {
    unitId: number;
    departmentId: number;
    docTypeId?: number;
    docFieldId?: number;
    name: string;
    comments?: string;
    startDate?: string;
    endDate?: string;
    curatorId?: number;
    signerId?: number;
    workflowId?: number;
    isFromDoc?: boolean;
    parentId?: number;
    createdBy: number;
  }): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_handling_doc_create', [
      params.unitId,
      params.departmentId,
      params.docTypeId ?? null,
      params.docFieldId ?? null,
      params.name,
      params.comments ?? null,
      params.startDate ?? null,
      params.endDate ?? null,
      params.curatorId ?? null,
      params.signerId ?? null,
      params.workflowId ?? null,
      params.isFromDoc ?? false,
      params.parentId ?? null,
      params.createdBy,
    ]);
    return row ?? { success: false, message: 'Không thể tạo hồ sơ công việc', id: 0 };
  },

  async update(id: number, params: {
    docTypeId?: number;
    docFieldId?: number;
    name: string;
    comments?: string;
    startDate?: string;
    endDate?: string;
    curatorId?: number;
    signerId?: number;
    workflowId?: number;
    updatedBy: number;
  }): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_update', [
      id,
      params.docTypeId ?? null,
      params.docFieldId ?? null,
      params.name,
      params.comments ?? null,
      params.startDate ?? null,
      params.endDate ?? null,
      params.curatorId ?? null,
      params.signerId ?? null,
      params.workflowId ?? null,
      params.updatedBy,
    ]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },

  async delete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_delete', [id]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },

  // --- 5.4 Staff Assignment ---
  async getStaff(docId: number): Promise<StaffAssignmentRow[]> {
    return callFunction<StaffAssignmentRow>('edoc.fn_handling_doc_get_staff', [docId]);
  },

  async assignStaff(
    docId: number,
    staffIds: number[],
    roleType: number,
    deadline: string | null,
    assignedBy: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_assign_staff', [
      docId, staffIds, roleType, deadline, assignedBy,
    ]);
    return row ?? { success: false, message: 'Không thể phân công cán bộ' };
  },

  async removeStaff(docId: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_remove_staff', [docId, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy cán bộ xử lý' };
  },

  // --- 5.5 Opinions ---
  async getOpinions(docId: number): Promise<OpinionRow[]> {
    return callFunction<OpinionRow>('edoc.fn_opinion_get_list', [docId]);
  },

  async createOpinion(
    docId: number,
    staffId: number,
    content: string,
    opinionType: string,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_opinion_create', [
      docId, staffId, content, opinionType,
    ]);
    return row ?? { success: false, message: 'Không thể thêm ý kiến', id: 0 };
  },

  // --- 5.6 Linked Docs ---
  async getLinkedDocs(docId: number): Promise<LinkedDocRow[]> {
    return callFunction<LinkedDocRow>('edoc.fn_handling_doc_get_linked_docs', [docId]);
  },

  async linkDoc(
    docId: number,
    linkedDocId: number,
    docType: string,
    linkedBy: number,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_handling_doc_link_doc', [
      docId, linkedDocId, docType, linkedBy,
    ]);
    return row ?? { success: false, message: 'Không thể liên kết văn bản', id: 0 };
  },

  async unlinkDoc(linkId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_unlink_doc', [linkId]);
    return row ?? { success: false, message: 'Không tìm thấy liên kết' };
  },

  // --- 5.3 Attachments ---
  async getAttachments(docId: number): Promise<AttachmentRow[]> {
    return callFunction<AttachmentRow>('edoc.fn_handling_doc_get_attachments', [docId]);
  },

  // --- 5.3 Children ---
  async getChildren(docId: number): Promise<HandlingDocListRow[]> {
    return callFunction<HandlingDocListRow>('edoc.fn_handling_doc_get_children', [docId]);
  },

  // --- 5.7 Status Transitions ---
  async submit(id: number, submittedBy: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_submit', [id, submittedBy]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },

  async approve(id: number, approvedBy: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_approve', [id, approvedBy]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },

  async reject(id: number, rejectedBy: number, reason: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_reject', [id, rejectedBy, reason]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },

  async returnDoc(id: number, returnedBy: number, reason: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_return', [id, returnedBy, reason]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },

  async complete(id: number, completedBy: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_complete', [id, completedBy]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },

  async updateProgress(id: number, progress: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_update_progress', [id, progress]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },

  async changeStatus(
    id: number,
    newStatus: number,
    changedBy: number,
    reason?: string,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_change_status', [
      id, newStatus, changedBy, reason ?? null,
    ]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },

  // --- HDSD 3.1 — Mở lại HSCV ---
  async reopen(id: number, userId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_reopen', [id, userId]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },

  // --- HDSD 3.2 — Lấy số HSCV ---
  async assignNumber(
    id: number,
    userId: number,
    docBookId: number,
  ): Promise<{ success: boolean; message: string; number: number | null }> {
    const row = await callFunctionOne<{ success: boolean; message: string; number: number | null }>(
      'edoc.fn_handling_doc_assign_number',
      [id, userId, docBookId],
    );
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc', number: null };
  },

  // --- Gap D (HDSD III.2.5) — Hủy HSCV với lý do ---
  async cancel(id: number, userId: number, reason: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_handling_doc_cancel', [id, userId, reason]);
    return row ?? { success: false, message: 'Không tìm thấy hồ sơ công việc' };
  },
};
