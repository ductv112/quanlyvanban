import { callFunction, callFunctionOne } from '../lib/db/query.js';

// ============ Row types ============

export interface InterIncomingListRow {
  id: number;
  unit_id: number;
  received_date: string;
  notation: string;
  document_code: string;
  abstract: string;
  publish_unit: string;
  publish_date: string;
  signer: string;
  sign_date: string;
  expired_date: string;
  doc_type_id: number;
  status: string;
  source_system: string;
  external_doc_id: string;
  created_by: number;
  created_at: string;
  total_count: number;
}

export interface InterIncomingDetailRow {
  id: number;
  unit_id: number;
  received_date: string;
  notation: string;
  document_code: string;
  abstract: string;
  publish_unit: string;
  publish_date: string;
  signer: string;
  sign_date: string;
  expired_date: string;
  doc_type_id: number;
  status: string;
  source_system: string;
  external_doc_id: string;
  created_by: number;
  created_at: string;
}

// ============ Repository ============

export const interIncomingRepository = {

  async getList(
    unitId: number,
    filters: {
      keyword?: string;
      status?: string;
      fromDate?: string;
      toDate?: string;
      page?: number;
      pageSize?: number;
    } = {},
  ): Promise<InterIncomingListRow[]> {
    return callFunction<InterIncomingListRow>('edoc.fn_inter_incoming_get_list', [
      unitId,
      filters.keyword ?? null,
      filters.status ?? null,
      filters.fromDate ?? null,
      filters.toDate ?? null,
      filters.page ?? 1,
      filters.pageSize ?? 20,
    ]);
  },

  async getById(id: number): Promise<InterIncomingDetailRow | null> {
    return callFunctionOne<InterIncomingDetailRow>('edoc.fn_inter_incoming_get_by_id', [id]);
  },

  async receive(id: number, staffId: number): Promise<{ success: boolean; message: string } | null> {
    return callFunctionOne<{ success: boolean; message: string }>('edoc.fn_inter_incoming_receive', [id, staffId]);
  },

  async returnDoc(id: number, staffId: number, reason?: string): Promise<{ success: boolean; message: string } | null> {
    return callFunctionOne<{ success: boolean; message: string }>('edoc.fn_inter_incoming_return', [id, staffId, reason ?? null]);
  },

  async complete(id: number, staffId: number): Promise<{ success: boolean; message: string } | null> {
    return callFunctionOne<{ success: boolean; message: string }>('edoc.fn_inter_incoming_complete', [id, staffId]);
  },
};
