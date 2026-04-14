import { callFunction, callFunctionOne } from '../lib/db/query.js';

// ==========================================
// ROW INTERFACES — WAREHOUSE (KHO LƯU TRỮ)
// ==========================================

export interface WarehouseRow {
  id: number;
  unit_id: number;
  type_id: number | null;
  code: string | null;
  name: string;
  phone_number: string | null;
  address: string | null;
  status: boolean;
  description: string | null;
  parent_id: number;
  is_unit: boolean;
  warehouse_level: number;
  limit_child: number;
  position: string | null;
  created_user_id: number;
  created_date: string;
  modified_user_id?: number | null;
  modified_date?: string | null;
}

// ==========================================
// ROW INTERFACES — FOND (PHÔNG LƯU TRỮ)
// ==========================================

export interface FondRow {
  id: number;
  unit_id: number;
  parent_id: number;
  fond_code: string | null;
  fond_name: string;
  fond_history: string | null;
  archives_time: string | null;
  paper_total: number | null;
  paper_digital: number | null;
  keys_group: string | null;
  other_type: string | null;
  language: string | null;
  lookup_tools: string | null;
  coppy_number: number | null;
  status: number;
  description: string | null;
  version: number | null;
  created_date: string;
  modified_user_id?: number | null;
  modified_date?: string | null;
}

// ==========================================
// ROW INTERFACES — RECORD (HỒ SƠ LƯU TRỮ)
// ==========================================

export interface RecordListRow {
  id: bigint;
  unit_id: number;
  fond_id: number;
  fond_name: string | null;
  file_code: string | null;
  file_catalog: number | null;
  file_notation: string | null;
  title: string;
  maintenance: string | null;
  rights: string | null;
  language: string | null;
  start_date: string | null;
  complete_date: string | null;
  total_doc: number | null;
  description: string | null;
  infor_sign: string | null;
  keyword: string | null;
  total_paper: number | null;
  page_number: number | null;
  format: number;
  archive_date: string | null;
  in_charge_staff_id: number;
  warehouse_id: number;
  warehouse_name: string | null;
  transfer_online_status: boolean;
  created_date: string;
  total_count: bigint;
}

export interface RecordDetailRow extends RecordListRow {
  reception_archive_id: number | null;
  parent_id: number;
  reception_date: string | null;
  reception_from: number;
  transfer_staff: string | null;
  is_document_original: boolean | null;
  number_of_copy: number | null;
  doc_field_id: number | null;
  created_user_id: number;
  modified_user_id: number | null;
  modified_date: string | null;
}

// ==========================================
// ROW INTERFACES — BORROW REQUEST (MƯỢN/TRẢ)
// ==========================================

export interface BorrowRequestListRow {
  id: bigint;
  name: string;
  unit_id: number;
  emergency: number | null;
  notice: string | null;
  borrow_date: string | null;
  status: number;
  created_user_id: number;
  creator_name: string;
  created_date: string;
  record_count: bigint;
  total_count: bigint;
}

export interface BorrowRequestDetailRow {
  id: bigint;
  name: string;
  unit_id: number;
  emergency: number | null;
  notice: string | null;
  borrow_date: string | null;
  status: number;
  created_user_id: number;
  creator_name: string;
  created_date: string;
  modified_user_id: number | null;
  modified_date: string | null;
  record_id: bigint | null;
  record_title: string | null;
  return_date: string | null;
  actual_return_date: string | null;
}

interface DbResult {
  success: boolean;
  message: string;
  id?: number | bigint;
}

// ==========================================
// REPOSITORY
// ==========================================

export const archiveRepository = {

  // ---- WAREHOUSE ----

  async getWarehouseTree(unitId: number): Promise<WarehouseRow[]> {
    return callFunction<WarehouseRow>('esto.fn_warehouse_get_tree', [unitId]);
  },

  async getWarehouseById(id: number): Promise<WarehouseRow | null> {
    return callFunctionOne<WarehouseRow>('esto.fn_warehouse_get_by_id', [id]);
  },

  async createWarehouse(
    unitId: number,
    typeId: number | null,
    code: string | null,
    name: string,
    phoneNumber: string | null,
    address: string | null,
    status: boolean,
    description: string | null,
    parentId: number,
    isUnit: boolean,
    warehouseLevel: number,
    limitChild: number,
    position: string | null,
    createdUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_warehouse_create', [
      unitId, typeId, code, name, phoneNumber, address, status, description,
      parentId, isUnit, warehouseLevel, limitChild, position, createdUserId,
    ]);
    return row ?? { success: false, message: 'Không thể tạo kho' };
  },

  async updateWarehouse(
    id: number,
    typeId: number | null,
    code: string | null,
    name: string,
    phoneNumber: string | null,
    address: string | null,
    status: boolean,
    description: string | null,
    parentId: number,
    isUnit: boolean,
    warehouseLevel: number,
    limitChild: number,
    position: string | null,
    modifiedUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_warehouse_update', [
      id, typeId, code, name, phoneNumber, address, status, description,
      parentId, isUnit, warehouseLevel, limitChild, position, modifiedUserId,
    ]);
    return row ?? { success: false, message: 'Không thể cập nhật kho' };
  },

  async deleteWarehouse(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_warehouse_delete', [id]);
    return row ?? { success: false, message: 'Không thể xóa kho' };
  },

  // ---- FOND ----

  async getFondTree(unitId: number): Promise<FondRow[]> {
    return callFunction<FondRow>('esto.fn_fond_get_tree', [unitId]);
  },

  async getFondById(id: number): Promise<FondRow | null> {
    return callFunctionOne<FondRow>('esto.fn_fond_get_by_id', [id]);
  },

  async createFond(
    unitId: number,
    parentId: number,
    fondCode: string | null,
    fondName: string,
    fondHistory: string | null,
    archivesTime: string | null,
    paperTotal: number | null,
    paperDigital: number | null,
    keysGroup: string | null,
    otherType: string | null,
    language: string | null,
    lookupTools: string | null,
    coppyNumber: number | null,
    status: number,
    description: string | null,
    version: number | null,
    createdUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_fond_create', [
      unitId, parentId, fondCode, fondName, fondHistory, archivesTime,
      paperTotal, paperDigital, keysGroup, otherType, language, lookupTools,
      coppyNumber, status, description, version, createdUserId,
    ]);
    return row ?? { success: false, message: 'Không thể tạo phông' };
  },

  async updateFond(
    id: number,
    parentId: number,
    fondCode: string | null,
    fondName: string,
    fondHistory: string | null,
    archivesTime: string | null,
    paperTotal: number | null,
    paperDigital: number | null,
    keysGroup: string | null,
    otherType: string | null,
    language: string | null,
    lookupTools: string | null,
    coppyNumber: number | null,
    status: number,
    description: string | null,
    version: number | null,
    modifiedUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_fond_update', [
      id, parentId, fondCode, fondName, fondHistory, archivesTime,
      paperTotal, paperDigital, keysGroup, otherType, language, lookupTools,
      coppyNumber, status, description, version, modifiedUserId,
    ]);
    return row ?? { success: false, message: 'Không thể cập nhật phông' };
  },

  async deleteFond(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_fond_delete', [id]);
    return row ?? { success: false, message: 'Không thể xóa phông' };
  },

  // ---- RECORD ----

  async getRecordList(
    unitId: number,
    fondId: number | null,
    warehouseId: number | null,
    keyword: string | null,
    page: number,
    pageSize: number,
  ): Promise<RecordListRow[]> {
    return callFunction<RecordListRow>('esto.fn_record_get_list', [
      unitId, fondId, warehouseId, keyword, page, pageSize,
    ]);
  },

  async getRecordById(id: number): Promise<RecordDetailRow | null> {
    return callFunctionOne<RecordDetailRow>('esto.fn_record_get_by_id', [id]);
  },

  async createRecord(
    unitId: number,
    fondId: number,
    warehouseId: number,
    fileCode: string | null,
    fileCatalog: number | null,
    fileNotation: string | null,
    title: string,
    maintenance: string | null,
    rights: string | null,
    language: string | null,
    startDate: string | null,
    completeDate: string | null,
    totalDoc: number | null,
    description: string | null,
    inforSign: string | null,
    keyword: string | null,
    totalPaper: number | null,
    pageNumber: number | null,
    format: number,
    archiveDate: string | null,
    inChargeStaffId: number,
    receptionDate: string | null,
    receptionFrom: number,
    transferStaff: string | null,
    isDocumentOriginal: boolean | null,
    numberOfCopy: number | null,
    docFieldId: number | null,
    createdUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_record_create', [
      unitId, fondId, warehouseId, fileCode, fileCatalog, fileNotation,
      title, maintenance, rights, language, startDate, completeDate, totalDoc,
      description, inforSign, keyword, totalPaper, pageNumber, format,
      archiveDate, inChargeStaffId, receptionDate, receptionFrom,
      transferStaff, isDocumentOriginal, numberOfCopy, docFieldId, createdUserId,
    ]);
    return row ?? { success: false, message: 'Không thể tạo hồ sơ' };
  },

  async updateRecord(
    id: number,
    fondId: number,
    warehouseId: number,
    fileCode: string | null,
    fileCatalog: number | null,
    fileNotation: string | null,
    title: string,
    maintenance: string | null,
    rights: string | null,
    language: string | null,
    startDate: string | null,
    completeDate: string | null,
    totalDoc: number | null,
    description: string | null,
    inforSign: string | null,
    keyword: string | null,
    totalPaper: number | null,
    pageNumber: number | null,
    format: number,
    archiveDate: string | null,
    inChargeStaffId: number,
    receptionDate: string | null,
    receptionFrom: number,
    transferStaff: string | null,
    isDocumentOriginal: boolean | null,
    numberOfCopy: number | null,
    docFieldId: number | null,
    modifiedUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_record_update', [
      id, fondId, warehouseId, fileCode, fileCatalog, fileNotation,
      title, maintenance, rights, language, startDate, completeDate, totalDoc,
      description, inforSign, keyword, totalPaper, pageNumber, format,
      archiveDate, inChargeStaffId, receptionDate, receptionFrom,
      transferStaff, isDocumentOriginal, numberOfCopy, docFieldId, modifiedUserId,
    ]);
    return row ?? { success: false, message: 'Không thể cập nhật hồ sơ' };
  },

  async deleteRecord(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_record_delete', [id]);
    return row ?? { success: false, message: 'Không thể xóa hồ sơ' };
  },

  // ---- BORROW REQUEST ----

  async getBorrowRequestList(
    unitId: number,
    status: number | null,
    keyword: string | null,
    page: number,
    pageSize: number,
  ): Promise<BorrowRequestListRow[]> {
    return callFunction<BorrowRequestListRow>('esto.fn_borrow_request_get_list', [
      unitId, status, keyword, page, pageSize,
    ]);
  },

  async getBorrowRequestById(id: number): Promise<BorrowRequestDetailRow[]> {
    return callFunction<BorrowRequestDetailRow>('esto.fn_borrow_request_get_by_id', [id]);
  },

  async createBorrowRequest(
    name: string,
    unitId: number,
    emergency: number | null,
    notice: string | null,
    borrowDate: string | null,
    createdUserId: number,
    recordIds: number[],
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_borrow_request_create', [
      name, unitId, emergency, notice, borrowDate, createdUserId, recordIds,
    ]);
    return row ?? { success: false, message: 'Không thể tạo yêu cầu mượn' };
  },

  async approveBorrowRequest(id: number, modifiedUserId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_borrow_request_approve', [id, modifiedUserId]);
    return row ?? { success: false, message: 'Không thể duyệt yêu cầu mượn' };
  },

  async rejectBorrowRequest(id: number, modifiedUserId: number, notice: string | null): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_borrow_request_reject', [id, modifiedUserId, notice]);
    return row ?? { success: false, message: 'Không thể từ chối yêu cầu mượn' };
  },

  async checkoutBorrowRequest(id: number, modifiedUserId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_borrow_request_checkout', [id, modifiedUserId]);
    return row ?? { success: false, message: 'Không thể xác nhận mượn' };
  },

  async returnBorrowRequest(id: number, modifiedUserId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('esto.fn_borrow_request_return', [id, modifiedUserId]);
    return row ?? { success: false, message: 'Không thể xác nhận trả' };
  },
};
