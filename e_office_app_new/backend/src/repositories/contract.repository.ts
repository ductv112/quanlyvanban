import { callFunction, callFunctionOne, rawQuery } from '../lib/db/query.js';

// ==========================================
// ROW INTERFACES — CONTRACT TYPES
// ==========================================

export interface ContractTypeRow {
  id: number;
  unit_id: number | null;
  parent_id: number;
  code: string | null;
  name: string;
  note: string | null;
  sort_order: number;
  created_date: string;
}

// ==========================================
// ROW INTERFACES — CONTRACTS
// ==========================================

export interface ContractListRow {
  id: number;
  code_index: number | null;
  contract_type_id: number | null;
  type_name: string | null;
  unit_id: number;
  code: string | null;
  name: string;
  sign_date: string | null;
  signer: string | null;
  contact_name: string | null;
  staff_id: number | null;
  status: number;
  amount: string | null;
  payment_amount: number | null;
  created_date: string;
  attachment_count: bigint;
  total_count: bigint;
}

export interface ContractDetailRow {
  id: number;
  code_index: number | null;
  contract_type_id: number | null;
  type_name: string | null;
  department_id: number | null;
  type_of_contract: number;
  contact_id: number | null;
  contact_name: string | null;
  unit_id: number;
  code: string | null;
  sign_date: string | null;
  input_date: string | null;
  receive_date: string | null;
  name: string;
  signer: string | null;
  number: number | null;
  ballot: string | null;
  marker: string | null;
  curator_name: string | null;
  currency: string | null;
  transporter: string | null;
  staff_id: number | null;
  note: string | null;
  status: number;
  amount: string | null;
  payment_amount: number | null;
  created_user_id: number;
  created_date: string;
  modified_user_id: number | null;
  modified_date: string | null;
  attachment_count: bigint;
}

// ==========================================
// ROW INTERFACES — CONTRACT ATTACHMENTS
// ==========================================

export interface ContractAttachmentRow {
  id: bigint;
  contract_id: number;
  file_name: string;
  file_path: string;
  file_size: bigint | null;
  mime_type: string | null;
  created_user_id: number;
  created_date: string;
}

interface DbResult {
  success: boolean;
  message: string;
  id?: number | bigint;
}

// ==========================================
// REPOSITORY
// ==========================================

export const contractRepository = {

  // ---- CONTRACT TYPES ----

  async getContractTypeList(unitId: number): Promise<ContractTypeRow[]> {
    return callFunction<ContractTypeRow>('cont.fn_contract_type_get_list', [unitId]);
  },

  async createContractType(
    unitId: number,
    parentId: number,
    code: string | null,
    name: string,
    note: string | null,
    sortOrder: number,
    createdUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('cont.fn_contract_type_create', [
      unitId, parentId, code, name, note, sortOrder, createdUserId,
    ]);
    return row ?? { success: false, message: 'Không thể tạo loại hợp đồng' };
  },

  async updateContractType(
    id: number,
    parentId: number,
    code: string | null,
    name: string,
    note: string | null,
    sortOrder: number,
    modifiedUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('cont.fn_contract_type_update', [
      id, parentId, code, name, note, sortOrder, modifiedUserId,
    ]);
    return row ?? { success: false, message: 'Không thể cập nhật loại hợp đồng' };
  },

  async deleteContractType(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('cont.fn_contract_type_delete', [id]);
    return row ?? { success: false, message: 'Không thể xóa loại hợp đồng' };
  },

  // ---- CONTRACTS ----

  async getContractList(
    unitId: number,
    contractTypeId: number | null,
    status: number | null,
    keyword: string | null,
    page: number,
    pageSize: number,
  ): Promise<ContractListRow[]> {
    return callFunction<ContractListRow>('cont.fn_contract_get_list', [
      unitId, contractTypeId, status, keyword, page, pageSize,
    ]);
  },

  async getContractById(id: number): Promise<ContractDetailRow | null> {
    return callFunctionOne<ContractDetailRow>('cont.fn_contract_get_by_id', [id]);
  },

  async createContract(
    codeIndex: number | null,
    contractTypeId: number | null,
    departmentId: number | null,
    typeOfContract: number,
    contactId: number | null,
    contactName: string | null,
    unitId: number,
    code: string | null,
    signDate: string | null,
    inputDate: string | null,
    receiveDate: string | null,
    name: string,
    signer: string | null,
    number: number | null,
    ballot: string | null,
    marker: string | null,
    curatorName: string | null,
    currency: string | null,
    transporter: string | null,
    staffId: number | null,
    note: string | null,
    status: number,
    amount: string | null,
    paymentAmount: number | null,
    createdUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('cont.fn_contract_create', [
      codeIndex, contractTypeId, departmentId, typeOfContract, contactId, contactName,
      unitId, code, signDate, inputDate, receiveDate, name, signer, number,
      ballot, marker, curatorName, currency, transporter, staffId, note,
      status, amount, paymentAmount, createdUserId,
    ]);
    return row ?? { success: false, message: 'Không thể tạo hợp đồng' };
  },

  async updateContract(
    id: number,
    codeIndex: number | null,
    contractTypeId: number | null,
    departmentId: number | null,
    typeOfContract: number,
    contactId: number | null,
    contactName: string | null,
    code: string | null,
    signDate: string | null,
    inputDate: string | null,
    receiveDate: string | null,
    name: string,
    signer: string | null,
    number: number | null,
    ballot: string | null,
    marker: string | null,
    curatorName: string | null,
    currency: string | null,
    transporter: string | null,
    staffId: number | null,
    note: string | null,
    status: number,
    amount: string | null,
    paymentAmount: number | null,
    modifiedUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('cont.fn_contract_update', [
      id, codeIndex, contractTypeId, departmentId, typeOfContract, contactId, contactName,
      code, signDate, inputDate, receiveDate, name, signer, number,
      ballot, marker, curatorName, currency, transporter, staffId, note,
      status, amount, paymentAmount, modifiedUserId,
    ]);
    return row ?? { success: false, message: 'Không thể cập nhật hợp đồng' };
  },

  async deleteContract(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('cont.fn_contract_delete', [id]);
    return row ?? { success: false, message: 'Không thể xóa hợp đồng' };
  },

  // ---- CONTRACT ATTACHMENTS ----

  async getContractAttachments(contractId: number): Promise<ContractAttachmentRow[]> {
    return callFunction<ContractAttachmentRow>('cont.fn_contract_get_attachments', [contractId]);
  },

  async addContractAttachment(
    contractId: number,
    fileName: string,
    filePath: string,
    fileSize: number | null,
    mimeType: string | null,
    createdUserId: number,
  ): Promise<{ id: bigint }> {
    const rows = await rawQuery<{ id: bigint }>(
      `INSERT INTO cont.contract_attachments (contract_id, file_name, file_path, file_size, mime_type, created_user_id)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING id`,
      [contractId, fileName, filePath, fileSize, mimeType, createdUserId],
    );
    return rows[0];
  },

  async deleteContractAttachment(id: number): Promise<{ found: boolean; file_path: string | null }> {
    const rows = await rawQuery<{ id: bigint; file_path: string }>(
      `DELETE FROM cont.contract_attachments WHERE id = $1 RETURNING id, file_path`,
      [id],
    );
    if (rows.length === 0) return { found: false, file_path: null };
    return { found: true, file_path: rows[0].file_path };
  },
};
