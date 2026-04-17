import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';
import type { RecipientRow, HistoryRow, AttachmentRow, AttachmentDeleteResult, BookmarkToggleResult, StaffNoteRow, SendableStaffRow, LeaderNoteRow } from './incoming-doc.repository.js';

// ============ Row types ============

export interface OutgoingDocListRow {
  id: number;
  unit_id: number;
  received_date: string;
  number: number;
  sub_number: string;
  notation: string;
  document_code: string;
  abstract: string;
  drafting_unit_id: number;
  drafting_user_id: number;
  publish_unit_id: number;
  publish_date: string;
  signer: string;
  sign_date: string;
  expired_date: string;
  doc_book_id: number;
  doc_type_id: number;
  doc_field_id: number;
  secret_id: number;
  urgent_id: number;
  number_paper: number;
  number_copies: number;
  recipients: string;
  approver: string;
  approved: boolean;
  is_handling: boolean;
  archive_status: boolean;
  created_by: number;
  created_at: string;
  doc_book_name: string;
  doc_type_name: string;
  doc_type_code: string;
  doc_field_name: string;
  drafting_unit_name: string;
  drafting_user_name: string;
  created_by_name: string;
  is_read: boolean;
  read_at: string;
  attachment_count: number;
  total_count: number;
}

export interface OutgoingDocDetailRow extends Omit<OutgoingDocListRow, 'attachment_count' | 'total_count'> {
  is_inter_doc: boolean;
  is_digital_signed: number;
  publish_unit_name: string;
  updated_by: number;
  updated_at: string;
}

// ============ Repository ============

export const outgoingDocRepository = {

  // --- List ---
  async getList(
    unitId: number, staffId: number,
    filters: {
      docBookId?: number; docTypeId?: number; docFieldId?: number;
      urgentId?: number; approved?: boolean;
      fromDate?: string; toDate?: string; keyword?: string;
      page?: number; pageSize?: number;
      deptIds?: number[] | null;
    } = {},
  ): Promise<OutgoingDocListRow[]> {
    return callFunction<OutgoingDocListRow>('edoc.fn_outgoing_doc_get_list', [
      unitId, staffId,
      filters.docBookId ?? null, filters.docTypeId ?? null, filters.docFieldId ?? null,
      filters.urgentId ?? null, filters.approved ?? null,
      filters.fromDate ?? null, filters.toDate ?? null, filters.keyword ?? null,
      filters.page ?? 1, filters.pageSize ?? 20,
      filters.deptIds ?? null,
    ]);
  },

  async countUnread(unitId: number, staffId: number, deptIds?: number[] | null): Promise<number> {
    const row = await callFunctionOne<{ fn_outgoing_doc_count_unread: number }>(
      'edoc.fn_outgoing_doc_count_unread', [unitId, staffId, deptIds ?? null],
    );
    return row?.fn_outgoing_doc_count_unread ?? 0;
  },

  async markReadBulk(docIds: number[], staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_outgoing_doc_mark_read_bulk', [docIds, staffId],
    );
    return row ?? { success: true, message: '' };
  },

  // --- CRUD ---
  async getNextNumber(docBookId: number, unitId: number): Promise<number> {
    const row = await callFunctionOne<{ fn_outgoing_doc_get_next_number: number }>(
      'edoc.fn_outgoing_doc_get_next_number', [docBookId, unitId],
    );
    return row?.fn_outgoing_doc_get_next_number ?? 1;
  },

  async create(params: {
    unitId: number; receivedDate?: string; number?: number; subNumber?: string;
    notation?: string; documentCode?: string; abstract: string;
    draftingUnitId?: number; draftingUserId?: number; publishUnitId?: number;
    publishDate?: string; signer?: string; signDate?: string;
    docBookId: number; docTypeId?: number; docFieldId?: number;
    secretId?: number; urgentId?: number; numberPaper?: number;
    numberCopies?: number; expiredDate?: string; recipients?: string;
    createdBy: number; departmentId?: number;
  }): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_outgoing_doc_create', [
      params.unitId, params.receivedDate ?? null, params.number ?? null,
      params.subNumber ?? null, params.notation ?? null, params.documentCode ?? null,
      params.abstract,
      params.draftingUnitId ?? null, params.draftingUserId ?? null,
      params.publishUnitId ?? null, params.publishDate ?? null,
      params.signer ?? null, params.signDate ?? null,
      params.docBookId, params.docTypeId ?? null, params.docFieldId ?? null,
      params.secretId ?? 1, params.urgentId ?? 1,
      params.numberPaper ?? 1, params.numberCopies ?? 1,
      params.expiredDate ?? null, params.recipients ?? null,
      params.createdBy,
      params.departmentId ?? null,
    ]);
    return row ?? { success: false, message: 'Không thể tạo văn bản đi', id: 0 };
  },

  async update(id: number, params: {
    receivedDate?: string; number?: number; subNumber?: string;
    notation?: string; documentCode?: string; abstract: string;
    draftingUnitId?: number; draftingUserId?: number; publishUnitId?: number;
    publishDate?: string; signer?: string; signDate?: string;
    docBookId: number; docTypeId?: number; docFieldId?: number;
    secretId?: number; urgentId?: number; numberPaper?: number;
    numberCopies?: number; expiredDate?: string; recipients?: string;
    updatedBy: number;
  }): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_outgoing_doc_update', [
      id, params.receivedDate ?? null, params.number ?? null,
      params.subNumber ?? null, params.notation ?? null, params.documentCode ?? null,
      params.abstract,
      params.draftingUnitId ?? null, params.draftingUserId ?? null,
      params.publishUnitId ?? null, params.publishDate ?? null,
      params.signer ?? null, params.signDate ?? null,
      params.docBookId, params.docTypeId ?? null, params.docFieldId ?? null,
      params.secretId ?? 1, params.urgentId ?? 1,
      params.numberPaper ?? 1, params.numberCopies ?? 1,
      params.expiredDate ?? null, params.recipients ?? null,
      params.updatedBy,
    ]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản đi' };
  },

  async delete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_outgoing_doc_delete', [id]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản đi' };
  },

  // --- Detail ---
  async getById(id: number, staffId: number): Promise<OutgoingDocDetailRow | null> {
    return callFunctionOne<OutgoingDocDetailRow>('edoc.fn_outgoing_doc_get_by_id', [id, staffId]);
  },

  async getRecipients(docId: number): Promise<RecipientRow[]> {
    return callFunction<RecipientRow>('edoc.fn_outgoing_doc_get_recipients', [docId]);
  },

  async getHistory(docId: number): Promise<HistoryRow[]> {
    return callFunction<HistoryRow>('edoc.fn_outgoing_doc_get_history', [docId]);
  },

  // --- Attachments ---
  async getAttachments(docId: number): Promise<AttachmentRow[]> {
    return callFunction<AttachmentRow>('edoc.fn_attachment_outgoing_get_list', [docId]);
  },

  async createAttachment(
    docId: number, fileName: string, filePath: string,
    fileSize: number, contentType: string, createdBy: number,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_attachment_outgoing_create', [
      docId, fileName, filePath, fileSize, contentType, createdBy,
    ]);
    return row ?? { success: false, message: 'Không thể tải lên file', id: 0 };
  },

  async deleteAttachment(id: number): Promise<AttachmentDeleteResult> {
    const row = await callFunctionOne<AttachmentDeleteResult>('edoc.fn_attachment_outgoing_delete', [id]);
    return row ?? { success: false, message: 'Không tìm thấy file', file_path: '' };
  },

  // --- Send ---
  async getSendableStaff(unitId: number): Promise<SendableStaffRow[]> {
    return callFunction<SendableStaffRow>('edoc.fn_incoming_doc_get_sendable_staff', [unitId]);
  },

  async send(docId: number, staffIds: number[], sentBy: number, expiredDate?: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_outgoing_doc_send', [docId, staffIds, sentBy, expiredDate ?? null]);
    return row ?? { success: false, message: 'Không thể gửi văn bản' };
  },

  // --- Approve ---
  async approve(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_outgoing_doc_approve', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async unapprove(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_outgoing_doc_unapprove', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  // --- Retract & Reject ---
  async retract(id: number, staffId: number, staffIds?: number[]): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_outgoing_doc_retract', [id, staffId, staffIds ?? null]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async reject(id: number, staffId: number, reason?: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_outgoing_doc_reject', [id, staffId, reason ?? null]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  // --- Check number ---
  async checkNumber(unitId: number, docBookId: number, number: number, excludeId?: number): Promise<boolean> {
    const row = await callFunctionOne<{ is_exists: boolean }>('edoc.fn_outgoing_doc_check_number', [unitId, docBookId, number, excludeId ?? null]);
    return row?.is_exists ?? false;
  },

  // --- Leader Notes ---
  async getLeaderNotes(docId: number): Promise<LeaderNoteRow[]> {
    return callFunction<LeaderNoteRow>('edoc.fn_leader_note_get_by_outgoing_doc', [docId]);
  },

  async createLeaderNote(docId: number, staffId: number, content: string): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_leader_note_create_outgoing', [docId, staffId, content]);
    return row ?? { success: false, message: 'Không thể thêm ý kiến', id: 0 };
  },

  async deleteLeaderNote(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_leader_note_delete', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy ý kiến' };
  },

  // --- Bookmarks ---
  async toggleBookmark(docId: number, staffId: number, note?: string): Promise<BookmarkToggleResult> {
    const row = await callFunctionOne<BookmarkToggleResult>('edoc.fn_staff_note_toggle', ['outgoing', docId, staffId, note ?? null]);
    return row ?? { success: false, message: 'Lỗi đánh dấu', is_bookmarked: false };
  },

  async getBookmarks(staffId: number): Promise<StaffNoteRow[]> {
    return callFunction<StaffNoteRow>('edoc.fn_staff_note_get_list', [staffId, 'outgoing']);
  },

  // --- Unused numbers ---
  async getUnusedNumbers(unitId: number, docBookId: number): Promise<{ unused_number: number }[]> {
    return callFunction<{ unused_number: number }>('edoc.fn_outgoing_doc_get_unused_numbers', [unitId, docBookId]);
  },

  // --- Giao việc (tạo HSCV từ VB đi) ---
  async createHandlingDocFromDoc(
    docId: number, docType: string, name: string,
    startDate: string | null, endDate: string | null,
    curatorIds: number[], note: string | null, createdBy: number,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_handling_doc_create_from_doc', [
      docId, docType, name, startDate, endDate, curatorIds, note, createdBy,
    ]);
    return row ?? { success: false, message: 'Không thể tạo hồ sơ công việc', id: 0 };
  },

  // --- Link to existing HSCV ---
  async linkToHandlingDoc(handlingDocId: number, docId: number, linkedBy: number): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_handling_doc_link_doc', [handlingDocId, docId, 'outgoing', linkedBy]);
    return row ?? { success: false, message: 'Không thể liên kết', id: 0 };
  },

  // --- LGSP send ---
  async sendLgsp(docId: number, destOrgCode: string, destOrgName: string, createdBy: number): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_lgsp_tracking_create', [docId, null, 'send', destOrgCode, destOrgName, null, createdBy]);
    return row ?? { success: false, message: 'Không thể gửi liên thông', id: 0 };
  },
};
