import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

// ============ Row types ============

export interface IncomingDocListRow {
  id: number;
  unit_id: number;
  received_date: string;
  number: number;
  notation: string;
  document_code: string;
  abstract: string;
  publish_unit: string;
  publish_date: string;
  signer: string;
  sign_date: string;
  doc_book_id: number;
  doc_type_id: number;
  doc_field_id: number;
  secret_id: number;
  urgent_id: number;
  number_paper: number;
  number_copies: number;
  expired_date: string;
  recipients: string;
  approver: string;
  approved: boolean;
  is_handling: boolean;
  is_received_paper: boolean;
  archive_status: boolean;
  created_by: number;
  created_at: string;
  doc_book_name: string;
  doc_type_name: string;
  doc_type_code: string;
  doc_field_name: string;
  created_by_name: string;
  is_read: boolean;
  read_at: string;
  attachment_count: number;
  total_count: number;
}

export interface IncomingDocDetailRow extends Omit<IncomingDocListRow, 'attachment_count' | 'total_count'> {
  updated_by: number;
  updated_at: string;
}

export interface RecipientRow {
  id: number;
  staff_id: number;
  staff_name: string;
  position_name: string;
  department_name: string;
  is_read: boolean;
  read_at: string;
  created_at: string;
}

export interface HistoryRow {
  event_type: string;
  event_time: string;
  staff_name: string;
  content: string;
}

export interface AttachmentRow {
  id: number;
  file_name: string;
  file_path: string;
  file_size: number;
  content_type: string;
  sort_order: number;
  created_by: number;
  created_at: string;
  created_by_name: string;
}

export interface AttachmentDeleteResult extends DbResult {
  file_path: string;
}

export interface LeaderNoteRow {
  id: number;
  staff_id: number;
  staff_name: string;
  position_name: string;
  content: string;
  created_at: string;
}

export interface StaffNoteRow {
  note_id: number;
  doc_id: number;
  note: string;
  created_at: string;
  doc_number: number;
  doc_notation: string;
  doc_abstract: string;
  doc_received_date: string;
  doc_publish_unit: string;
}

export interface BookmarkToggleResult extends DbResult {
  is_bookmarked: boolean;
}

export interface SendableStaffRow {
  staff_id: number;
  full_name: string;
  position_name: string;
  department_id: number;
  department_name: string;
}

// ============ Repository ============

export const incomingDocRepository = {

  // --- 3.1 List ---
  async getList(
    unitId: number, staffId: number,
    filters: {
      docBookId?: number; docTypeId?: number; docFieldId?: number;
      urgentId?: number; isRead?: boolean; approved?: boolean;
      fromDate?: string; toDate?: string; keyword?: string;
      page?: number; pageSize?: number;
    } = {},
  ): Promise<IncomingDocListRow[]> {
    return callFunction<IncomingDocListRow>('edoc.fn_incoming_doc_get_list', [
      unitId, staffId,
      filters.docBookId ?? null, filters.docTypeId ?? null, filters.docFieldId ?? null,
      filters.urgentId ?? null, filters.isRead ?? null, filters.approved ?? null,
      filters.fromDate ?? null, filters.toDate ?? null, filters.keyword ?? null,
      filters.page ?? 1, filters.pageSize ?? 20,
    ]);
  },

  async countUnread(unitId: number, staffId: number): Promise<number> {
    const row = await callFunctionOne<{ fn_incoming_doc_count_unread: number }>(
      'edoc.fn_incoming_doc_count_unread', [unitId, staffId],
    );
    return row?.fn_incoming_doc_count_unread ?? 0;
  },

  async markRead(docId: number, staffId: number): Promise<void> {
    await callFunction('edoc.fn_incoming_doc_mark_read', [docId, staffId]);
  },

  async markReadBulk(docIds: number[], staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_incoming_doc_mark_read_bulk', [docIds, staffId],
    );
    return row ?? { success: true, message: '' };
  },

  // --- 3.2 CRUD ---
  async getNextNumber(docBookId: number, unitId: number): Promise<number> {
    const row = await callFunctionOne<{ fn_incoming_doc_get_next_number: number }>(
      'edoc.fn_incoming_doc_get_next_number', [docBookId, unitId],
    );
    return row?.fn_incoming_doc_get_next_number ?? 1;
  },

  async create(params: {
    unitId: number; receivedDate?: string; number?: number; notation?: string;
    documentCode?: string; abstract: string; publishUnit?: string; publishDate?: string;
    signer?: string; signDate?: string; docBookId: number; docTypeId?: number;
    docFieldId?: number; secretId?: number; urgentId?: number; numberPaper?: number;
    numberCopies?: number; expiredDate?: string; recipients?: string;
    isReceivedPaper?: boolean; createdBy: number;
  }): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_incoming_doc_create', [
      params.unitId, params.receivedDate ?? null, params.number ?? null,
      params.notation ?? null, params.documentCode ?? null, params.abstract,
      params.publishUnit ?? null, params.publishDate ?? null,
      params.signer ?? null, params.signDate ?? null,
      params.docBookId, params.docTypeId ?? null, params.docFieldId ?? null,
      params.secretId ?? 1, params.urgentId ?? 1,
      params.numberPaper ?? 1, params.numberCopies ?? 1,
      params.expiredDate ?? null, params.recipients ?? null,
      params.isReceivedPaper ?? false, params.createdBy,
    ]);
    return row ?? { success: false, message: 'Không thể tạo văn bản đến', id: 0 };
  },

  async update(id: number, params: {
    receivedDate?: string; number?: number; notation?: string;
    documentCode?: string; abstract: string; publishUnit?: string; publishDate?: string;
    signer?: string; signDate?: string; docBookId: number; docTypeId?: number;
    docFieldId?: number; secretId?: number; urgentId?: number; numberPaper?: number;
    numberCopies?: number; expiredDate?: string; recipients?: string;
    isReceivedPaper?: boolean; updatedBy: number;
  }): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_update', [
      id, params.receivedDate ?? null, params.number ?? null,
      params.notation ?? null, params.documentCode ?? null, params.abstract,
      params.publishUnit ?? null, params.publishDate ?? null,
      params.signer ?? null, params.signDate ?? null,
      params.docBookId, params.docTypeId ?? null, params.docFieldId ?? null,
      params.secretId ?? 1, params.urgentId ?? 1,
      params.numberPaper ?? 1, params.numberCopies ?? 1,
      params.expiredDate ?? null, params.recipients ?? null,
      params.isReceivedPaper ?? false, params.updatedBy,
    ]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản đến' };
  },

  async delete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_delete', [id]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản đến' };
  },

  // --- 3.3 Detail ---
  async getById(id: number, staffId: number): Promise<IncomingDocDetailRow | null> {
    return callFunctionOne<IncomingDocDetailRow>('edoc.fn_incoming_doc_get_by_id', [id, staffId]);
  },

  async getRecipients(docId: number): Promise<RecipientRow[]> {
    return callFunction<RecipientRow>('edoc.fn_incoming_doc_get_recipients', [docId]);
  },

  async getHistory(docId: number): Promise<HistoryRow[]> {
    return callFunction<HistoryRow>('edoc.fn_incoming_doc_get_history', [docId]);
  },

  // --- 3.4 Attachments ---
  async getAttachments(docId: number): Promise<AttachmentRow[]> {
    return callFunction<AttachmentRow>('edoc.fn_attachment_incoming_get_list', [docId]);
  },

  async createAttachment(
    docId: number, fileName: string, filePath: string,
    fileSize: number, contentType: string, createdBy: number,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_attachment_incoming_create', [
      docId, fileName, filePath, fileSize, contentType, createdBy,
    ]);
    return row ?? { success: false, message: 'Không thể tải lên file', id: 0 };
  },

  async deleteAttachment(id: number): Promise<AttachmentDeleteResult> {
    const row = await callFunctionOne<AttachmentDeleteResult>('edoc.fn_attachment_incoming_delete', [id]);
    return row ?? { success: false, message: 'Không tìm thấy file', file_path: '' };
  },

  // --- 3.5 Send ---
  async getSendableStaff(unitId: number): Promise<SendableStaffRow[]> {
    return callFunction<SendableStaffRow>('edoc.fn_incoming_doc_get_sendable_staff', [unitId]);
  },

  async send(docId: number, staffIds: number[], sentBy: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_send', [docId, staffIds, sentBy]);
    return row ?? { success: false, message: 'Không thể gửi văn bản' };
  },

  // --- 3.6 Leader Notes ---
  async getLeaderNotes(docId: number): Promise<LeaderNoteRow[]> {
    return callFunction<LeaderNoteRow>('edoc.fn_leader_note_get_list', [docId]);
  },

  async createLeaderNote(docId: number, staffId: number, content: string): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_leader_note_create', [docId, staffId, content]);
    return row ?? { success: false, message: 'Không thể thêm bút phê', id: 0 };
  },

  async deleteLeaderNote(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_leader_note_delete', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy bút phê' };
  },

  // --- 3.7 Staff Notes / Bookmarks ---
  async toggleBookmark(docType: string, docId: number, staffId: number, note?: string): Promise<BookmarkToggleResult> {
    const row = await callFunctionOne<BookmarkToggleResult>('edoc.fn_staff_note_toggle', [docType, docId, staffId, note ?? null]);
    return row ?? { success: false, message: 'Lỗi đánh dấu', is_bookmarked: false };
  },

  async getBookmarks(staffId: number, docType: string = 'incoming'): Promise<StaffNoteRow[]> {
    return callFunction<StaffNoteRow>('edoc.fn_staff_note_get_list', [staffId, docType]);
  },

  // --- 3.8 Approve ---
  async approve(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_approve', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async unapprove(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_unapprove', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async receivePaper(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_receive_paper', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  // --- 3.9 Actions — Giao viec, Nhan ban giao, Chuyen lai, Huy duyet ---
  async createHandlingDocFromDoc(
    docId: number,
    docType: string,
    name: string,
    startDate: string | null,
    endDate: string | null,
    curatorIds: number[],
    note: string | null,
    createdBy: number,
  ): Promise<DbResultWithId> {
    // fn_handling_doc_create_from_doc returns TABLE(success, message, id bigint)
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_handling_doc_create_from_doc', [
      docId, docType, name, startDate, endDate, curatorIds, note, createdBy,
    ]);
    return row ?? { success: false, message: 'Không thể tạo hồ sơ công việc', id: 0 };
  },

  async handover(docId: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_handover', [docId, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async returnDoc(docId: number, returnedBy: number, reason: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_return', [docId, returnedBy, reason]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async cancelApprove(docId: number, cancelledBy: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_cancel_approve', [docId, cancelledBy]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },
};
