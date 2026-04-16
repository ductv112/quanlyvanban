import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';
import type { RecipientRow, HistoryRow, AttachmentRow, AttachmentDeleteResult, BookmarkToggleResult, StaffNoteRow, SendableStaffRow } from './incoming-doc.repository.js';

// ============ Row types ============

export interface DraftingDocListRow {
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
  is_released: boolean;
  released_date: string;
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

export interface DraftingDocDetailRow extends Omit<DraftingDocListRow, 'attachment_count' | 'total_count'> {
  updated_by: number;
  updated_at: string;
}

export interface ReleaseResult extends DbResult {
  outgoing_doc_id: number;
}

// ============ Repository ============

export const draftingDocRepository = {

  // --- List ---
  async getList(
    unitId: number, staffId: number,
    filters: {
      docBookId?: number; docTypeId?: number; docFieldId?: number;
      urgentId?: number; isReleased?: boolean; approved?: boolean;
      fromDate?: string; toDate?: string; keyword?: string;
      page?: number; pageSize?: number;
    } = {},
  ): Promise<DraftingDocListRow[]> {
    return callFunction<DraftingDocListRow>('edoc.fn_drafting_doc_get_list', [
      unitId, staffId,
      filters.docBookId ?? null, filters.docTypeId ?? null, filters.docFieldId ?? null,
      filters.urgentId ?? null, filters.isReleased ?? null, filters.approved ?? null,
      filters.fromDate ?? null, filters.toDate ?? null, filters.keyword ?? null,
      filters.page ?? 1, filters.pageSize ?? 20,
    ]);
  },

  async countUnread(unitId: number, staffId: number): Promise<number> {
    const row = await callFunctionOne<{ fn_drafting_doc_count_unread: number }>(
      'edoc.fn_drafting_doc_count_unread', [unitId, staffId],
    );
    return row?.fn_drafting_doc_count_unread ?? 0;
  },

  async markReadBulk(docIds: number[], staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_drafting_doc_mark_read_bulk', [docIds, staffId],
    );
    return row ?? { success: true, message: '' };
  },

  // --- CRUD ---
  async getNextNumber(docBookId: number, unitId: number): Promise<number> {
    const row = await callFunctionOne<{ fn_drafting_doc_get_next_number: number }>(
      'edoc.fn_drafting_doc_get_next_number', [docBookId, unitId],
    );
    return row?.fn_drafting_doc_get_next_number ?? 1;
  },

  async create(params: {
    unitId: number; receivedDate?: string; number?: number; subNumber?: string;
    notation?: string; documentCode?: string; abstract: string;
    draftingUnitId?: number; draftingUserId?: number; publishUnitId?: number;
    publishDate?: string; signer?: string; signDate?: string;
    docBookId: number; docTypeId?: number; docFieldId?: number;
    secretId?: number; urgentId?: number; numberPaper?: number;
    numberCopies?: number; expiredDate?: string; recipients?: string;
    createdBy: number;
  }): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_drafting_doc_create', [
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
    ]);
    return row ?? { success: false, message: 'Không thể tạo văn bản dự thảo', id: 0 };
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
    const row = await callFunctionOne<DbResult>('edoc.fn_drafting_doc_update', [
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
    return row ?? { success: false, message: 'Không tìm thấy văn bản dự thảo' };
  },

  async delete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_drafting_doc_delete', [id]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản dự thảo' };
  },

  // --- Detail ---
  async getById(id: number, staffId: number): Promise<DraftingDocDetailRow | null> {
    return callFunctionOne<DraftingDocDetailRow>('edoc.fn_drafting_doc_get_by_id', [id, staffId]);
  },

  async getRecipients(docId: number): Promise<RecipientRow[]> {
    return callFunction<RecipientRow>('edoc.fn_drafting_doc_get_recipients', [docId]);
  },

  async getHistory(docId: number): Promise<HistoryRow[]> {
    return callFunction<HistoryRow>('edoc.fn_drafting_doc_get_history', [docId]);
  },

  // --- Attachments ---
  async getAttachments(docId: number): Promise<AttachmentRow[]> {
    return callFunction<AttachmentRow>('edoc.fn_attachment_drafting_get_list', [docId]);
  },

  async createAttachment(
    docId: number, fileName: string, filePath: string,
    fileSize: number, contentType: string, createdBy: number,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_attachment_drafting_create', [
      docId, fileName, filePath, fileSize, contentType, createdBy,
    ]);
    return row ?? { success: false, message: 'Không thể tải lên file', id: 0 };
  },

  async deleteAttachment(id: number): Promise<AttachmentDeleteResult> {
    const row = await callFunctionOne<AttachmentDeleteResult>('edoc.fn_attachment_drafting_delete', [id]);
    return row ?? { success: false, message: 'Không tìm thấy file', file_path: '' };
  },

  // --- Send ---
  async getSendableStaff(unitId: number): Promise<SendableStaffRow[]> {
    return callFunction<SendableStaffRow>('edoc.fn_incoming_doc_get_sendable_staff', [unitId]);
  },

  async send(docId: number, staffIds: number[], sentBy: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_drafting_doc_send', [docId, staffIds, sentBy]);
    return row ?? { success: false, message: 'Không thể gửi văn bản' };
  },

  // --- Approve / Release ---
  async approve(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_drafting_doc_approve', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async unapprove(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_drafting_doc_unapprove', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async reject(id: number, staffId: number, reason?: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_drafting_doc_reject', [id, staffId, reason ?? null]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async retract(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_drafting_doc_retract', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async release(id: number, releasedBy: number): Promise<ReleaseResult> {
    const row = await callFunctionOne<ReleaseResult>('edoc.fn_drafting_doc_release', [id, releasedBy]);
    return row ?? { success: false, message: 'Không thể phát hành', outgoing_doc_id: 0 };
  },

  // --- Bookmarks ---
  async toggleBookmark(docId: number, staffId: number, note?: string): Promise<BookmarkToggleResult> {
    const row = await callFunctionOne<BookmarkToggleResult>('edoc.fn_staff_note_toggle', ['drafting', docId, staffId, note ?? null]);
    return row ?? { success: false, message: 'Lỗi đánh dấu', is_bookmarked: false };
  },

  async getBookmarks(staffId: number): Promise<StaffNoteRow[]> {
    return callFunction<StaffNoteRow>('edoc.fn_staff_note_get_list', [staffId, 'drafting']);
  },
};
