import { callFunction, callFunctionOne, rawQuery } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

// ============ Phase 35 Plan 35-01: LGSP receive types ============

/**
 * Input for createFromLgsp -- assembled by Plan 35-02 worker from ParsedEdxml.messageHeader.
 *
 * All string fields must be pre-trimmed by caller. Repo slices to DB VARCHAR limits as a safety net.
 */
export interface CreateFromLgspInput {
  unit_id: number;                          // root unit id of the receiving DN (from job data)
  external_doc_id: string;                  // lgsp_doc_id (UUID from /v1/syncReceivedEdocList) -- UNIQUE dedup key
  lgsp_sender_org_code: string;             // From.OrganId (e.g. 'H37.DN.002')
  publish_unit: string;                     // From.OrganName
  notation: string;                         // Code.CodeNumber
  document_code: string;                    // Code.CodeNotation
  abstract: string;                         // Subject
  signer: string;                           // SignerInfo.Signer
  sign_date: string | null;                 // PromulgationInfo.PromulgationDate (ISO-ish)
  publish_date: string | null;              // Same as sign_date per CONTEXT D-06
  doc_type_id: number | null;               // Lookup by name OR null (admin assigns later)
  number_paper: number;                     // OtherInfo.PageAmount fallback 1
  recipients_text: string;                  // From.OrganName + ' -> ' + To.OrganName concat
  created_by: number;                       // system staff_id (1=admin TODO Phase 37 dedicated lgsp-system user)
  edxml_raw: string;                        // Full edXML for audit (currently not stored; reserved for future extra_fields column)
}

export interface CreateFromLgspResult {
  inserted: boolean;
  skipped: boolean;            // true when dedup catch fired (already exists)
  id: number | null;           // present when inserted=true
  message: string;
}

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
  sents: string;
  approver: string;
  approved: boolean;
  is_handling: boolean;
  is_received_paper: boolean;
  archive_status: boolean;
  // Phase 35-04: source tracking + LGSP metadata (exposed by fn_incoming_doc_get_list)
  source_type: 'manual' | 'internal' | 'external_lgsp';
  is_unit_send: boolean;
  unit_send: string | null;
  external_doc_id: string | null;
  lgsp_sender_org_code: string | null;
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
  received_paper_date: string;
  is_inter_doc: boolean;
  inter_doc_id: number;
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
  // Gap A (HDSD I.5): ký số — optional để backward-compat các repo khác
  is_ca?: boolean;
  ca_date?: string | null;
  signed_file_path?: string | null;
  sign_provider_code?: string | null;
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
  is_important: boolean;
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
      signer?: string; fromNumber?: number; toNumber?: number;
      page?: number; pageSize?: number;
      deptIds?: number[] | null;
      sourceType?: 'manual' | 'internal' | 'external_lgsp' | null;  // Phase 35-04
    } = {},
  ): Promise<IncomingDocListRow[]> {
    return callFunction<IncomingDocListRow>('edoc.fn_incoming_doc_get_list', [
      unitId, staffId,
      filters.docBookId ?? null, filters.docTypeId ?? null, filters.docFieldId ?? null,
      filters.urgentId ?? null, filters.isRead ?? null, filters.approved ?? null,
      filters.fromDate ?? null, filters.toDate ?? null, filters.keyword ?? null,
      filters.signer ?? null, filters.fromNumber ?? null, filters.toNumber ?? null,
      filters.page ?? 1, filters.pageSize ?? 20,
      filters.deptIds ?? null,
      filters.sourceType ?? null,  // Phase 35-04 p_source_type
    ]);
  },

  async countUnread(unitId: number, staffId: number, deptIds?: number[] | null): Promise<number> {
    const row = await callFunctionOne<{ fn_incoming_doc_count_unread: number }>(
      'edoc.fn_incoming_doc_count_unread', [unitId, staffId, deptIds ?? null],
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
    sents?: string; isReceivedPaper?: boolean; createdBy: number;
    departmentId?: number;
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
      params.sents ?? null,
      params.isReceivedPaper ?? false, params.createdBy,
      params.departmentId ?? null,
    ]);
    return row ?? { success: false, message: 'Không thể tạo văn bản đến', id: 0 };
  },

  async update(id: number, params: {
    receivedDate?: string; number?: number; notation?: string;
    documentCode?: string; abstract: string; publishUnit?: string; publishDate?: string;
    signer?: string; signDate?: string; docBookId: number; docTypeId?: number;
    docFieldId?: number; secretId?: number; urgentId?: number; numberPaper?: number;
    numberCopies?: number; expiredDate?: string; recipients?: string;
    sents?: string; isReceivedPaper?: boolean; updatedBy: number;
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
      params.sents ?? null,
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
  async getSendableStaff(unitId: number, excludeStaffId?: number | null): Promise<SendableStaffRow[]> {
    return callFunction<SendableStaffRow>(
      'edoc.fn_incoming_doc_get_sendable_staff',
      [unitId, null, excludeStaffId ?? null],
    );
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

  async commentAndAssign(docId: number, staffId: number, content: string, docType: string, expiredDate?: string, staffIds?: number[]): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_leader_note_comment_and_assign', [
      docId, staffId, content, expiredDate ?? null, staffIds ?? null, docType,
    ]);
    return row ?? { success: false, message: 'Lỗi bút phê', id: 0 };
  },

  // --- 3.7 Staff Notes / Bookmarks ---
  async toggleBookmark(docType: string, docId: number, staffId: number, note?: string, isImportant?: boolean): Promise<BookmarkToggleResult> {
    const row = await callFunctionOne<BookmarkToggleResult>('edoc.fn_staff_note_toggle', [docType, docId, staffId, note ?? null, isImportant ?? false]);
    return row ?? { success: false, message: 'Lỗi đánh dấu', is_bookmarked: false };
  },

  async getBookmarks(staffId: number, docType: string = 'incoming'): Promise<StaffNoteRow[]> {
    return callFunction<StaffNoteRow>('edoc.fn_staff_note_get_list', [staffId, docType]);
  },

  // --- 3.8 Retract ---
  async retract(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_retract', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  // --- 3.9 Approve ---
  async approve(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_approve', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async unapprove(id: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_unapprove', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy văn bản' };
  },

  async receivePaper(id: number, staffId: number, receivedPaperDate?: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_incoming_doc_receive_paper', [id, staffId, receivedPaperDate ?? null]);
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

  // --- Link to existing HSCV ---
  async getHandlingDocsForLink(unitId: number, keyword?: string): Promise<{ id: number; name: string; abstract: string; status: number; start_date: string; end_date: string; curator_name: string }[]> {
    return callFunction('edoc.fn_handling_doc_get_for_link', [unitId, keyword ?? null]);
  },

  async linkToHandlingDoc(handlingDocId: number, docId: number, docType: string, linkedBy: number): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_handling_doc_link_doc', [handlingDocId, docId, docType, linkedBy]);
    return row ?? { success: false, message: 'Không thể liên kết', id: 0 };
  },

  // --- LGSP send ---
  async sendLgsp(params: { outgoingDocId?: number; incomingDocId?: number; direction: string; destOrgCode: string; destOrgName: string; createdBy: number }): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('edoc.fn_lgsp_tracking_create', [
      params.outgoingDocId ?? null, params.incomingDocId ?? null,
      params.direction, params.destOrgCode, params.destOrgName, null, params.createdBy,
    ]);
    return row ?? { success: false, message: 'Không thể gửi liên thông', id: 0 };
  },

  async getLgspOrganizations(search?: string, pageSize: number = 100): Promise<{ id: number; org_code: string; org_name: string; is_active: boolean }[]> {
    return callFunction('edoc.fn_lgsp_org_get_list', [search ?? null, 1, pageSize]);
  },

  // --- Archive ---
  async createArchive(docType: string, docId: number, params: Record<string, unknown>): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>('esto.fn_document_archive_create', [
      docType, docId,
      params.fond_id ?? null, params.warehouse_id ?? null, params.record_id ?? null,
      params.file_catalog ?? null, params.file_notation ?? null, params.doc_ordinal ?? null,
      params.language ?? 'Tiếng Việt', params.autograph ?? null, params.keyword ?? null,
      params.format ?? 'Điện tử', params.confidence_level ?? null, params.is_original ?? true,
      params.archived_by ?? null,
    ]);
    return row ?? { success: false, message: 'Lỗi chuyển lưu trữ', id: 0 };
  },

  async getArchive(docType: string, docId: number): Promise<Record<string, unknown> | null> {
    return callFunctionOne('esto.fn_document_archive_get_by_doc', [docType, docId]);
  },

  async getFonds(unitId?: number): Promise<{ id: number; name: string; code: string }[]> {
    return callFunction('esto.fn_get_fonds_list', [unitId ?? null]);
  },

  async getWarehouses(unitId?: number): Promise<{ id: number; name: string; code: string }[]> {
    return callFunction('esto.fn_get_warehouses_list', [unitId ?? null]);
  },

  // --- Phase 35 Plan 35-01: LGSP receive (createFromLgsp + dedup catch) ---

  /**
   * Phase 35: Insert an incoming_docs row from a parsed LGSP edXML.
   *
   * Uses the existing SP `edoc.fn_incoming_doc_create` (28 positional args) which supports
   * `p_source_type='external_lgsp'` + `p_external_doc_id`. The UNIQUE INDEX
   * `idx_incoming_docs_external_dedupe` enforces dedup per CONTEXT D-09.
   *
   * Dedup behavior: When `p_external_doc_id` already exists, the underlying INSERT raises
   * SQLSTATE 23505 inside the SP's BEGIN block, the WHEN OTHERS catch converts it to
   * { success: false, message: <SQLERRM mentioning idx_incoming_docs_external_dedupe> }.
   * This method detects that case via message substring + returns skipped=true (no throw).
   *
   * After insert, populates the new `lgsp_sender_org_code` column (Phase 35 new column
   * NOT in SP signature -- append UPDATE).
   */
  async createFromLgsp(input: CreateFromLgspInput): Promise<CreateFromLgspResult> {
    const row = await callFunctionOne<{ success: boolean; message: string; id: number | null }>(
      'edoc.fn_incoming_doc_create',
      [
        input.unit_id,                                                         // p_unit_id
        new Date().toISOString(),                                              // p_received_date = NOW
        null,                                                                  // p_number -- SP auto-increment per unit
        input.notation.slice(0, 50),                                           // p_notation VARCHAR(50)
        input.document_code.slice(0, 100),                                     // p_document_code VARCHAR(100)
        input.abstract,                                                        // p_abstract TEXT
        input.publish_unit.slice(0, 500),                                      // p_publish_unit VARCHAR(500)
        input.publish_date,                                                    // p_publish_date timestamptz
        input.signer.slice(0, 200),                                            // p_signer VARCHAR(200)
        input.sign_date,                                                       // p_sign_date timestamptz
        null,                                                                  // p_doc_book_id -- LGSP doc has no in-DN book
        input.doc_type_id,                                                     // p_doc_type_id (may be null)
        null,                                                                  // p_doc_field_id
        1,                                                                     // p_secret_id DEFAULT 1 (Thuong)
        1,                                                                     // p_urgent_id DEFAULT 1 (Khan thuong)
        input.number_paper,                                                    // p_number_paper
        1,                                                                     // p_number_copies
        null,                                                                  // p_expired_date
        input.recipients_text.slice(0, 1000),                                  // p_recipients
        null,                                                                  // p_sents
        false,                                                                 // p_is_received_paper
        input.created_by,                                                      // p_created_by
        input.unit_id,                                                         // p_department_id = unit_id (root pattern Phase 17)
        'external_lgsp',                                                       // p_source_type ENUM
        false,                                                                 // p_is_unit_send
        input.publish_unit.slice(0, 500),                                      // p_unit_send (display "from <org>")
        null,                                                                  // p_previous_outgoing_doc_id
        input.external_doc_id.slice(0, 200),                                   // p_external_doc_id (UNIQUE dedup)
      ],
    );

    if (!row) {
      return { inserted: false, skipped: false, id: null, message: 'SP returned no row' };
    }

    if (row.success && row.id) {
      // Populate the new lgsp_sender_org_code column (NOT in SP signature -- append UPDATE).
      await rawQuery(
        'UPDATE edoc.incoming_docs SET lgsp_sender_org_code = $1 WHERE id = $2',
        [input.lgsp_sender_org_code.slice(0, 13), row.id],
      );
      return { inserted: true, skipped: false, id: Number(row.id), message: row.message };
    }

    // Dedup detection: SP message contains the unique index name OR generic 23505 marker.
    const msg = (row.message || '').toLowerCase();
    const isDedup =
      msg.includes('idx_incoming_docs_external_dedupe') ||
      msg.includes('duplicate key') ||
      msg.includes('unique constraint');
    if (isDedup) {
      return {
        inserted: false,
        skipped: true,
        id: null,
        message: `LGSP doc ${input.external_doc_id} already exists -- skipped (dedup)`,
      };
    }

    // Other SP failures -- bubble up (caller may decide retry).
    return { inserted: false, skipped: false, id: null, message: row.message };
  },

  /**
   * Phase 35 Plan 35-01: Insert an attachment row for an LGSP-received incoming_doc.
   *
   * MinIO upload happens BEFORE this -- caller passes the final `file_path`
   * (e.g. 'lgsp/<docId>/<fileName>').
   *
   * Uses the existing SP `edoc.fn_attachment_incoming_create` (verified at
   * schema/000_schema_v3.0.sql line 722).
   */
  async createLgspAttachment(params: {
    incoming_doc_id: number;
    file_name: string;
    file_path: string;
    file_size: number;
    content_type: string;
    uploaded_by: number;
  }): Promise<{ success: boolean; id: number | null; message: string }> {
    const row = await callFunctionOne<{ success: boolean; message: string; id: number | null }>(
      'edoc.fn_attachment_incoming_create',
      [
        params.incoming_doc_id,
        params.file_name.slice(0, 500),
        params.file_path.slice(0, 1000),
        params.file_size,
        params.content_type.slice(0, 200),
        params.uploaded_by,
      ],
    );
    return row ?? { success: false, id: null, message: 'attachment SP returned no row' };
  },
};
