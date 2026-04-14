import { callFunction, callFunctionOne } from '../lib/db/query.js';

// ==========================================
// ROW INTERFACES — DOCUMENT CATEGORIES
// ==========================================

export interface DocCategoryRow {
  id: number;
  parent_id: number;
  code: string | null;
  name: string;
  date_process: number | null;
  status: number;
  description: string | null;
  version: number | null;
  unit_id: number | null;
  created_date: string;
}

// ==========================================
// ROW INTERFACES — DOCUMENTS
// ==========================================

export interface DocumentListRow {
  id: bigint;
  unit_id: number;
  category_id: number | null;
  category_name: string | null;
  title: string;
  description: string | null;
  file_name: string | null;
  file_path: string | null;
  file_size: bigint | null;
  mime_type: string | null;
  keyword: string | null;
  status: number;
  created_user_id: number;
  creator_name: string;
  created_date: string;
  total_count: bigint;
}

export interface DocumentDetailRow {
  id: bigint;
  unit_id: number;
  category_id: number | null;
  category_name: string | null;
  title: string;
  description: string | null;
  file_name: string | null;
  file_path: string | null;
  file_size: bigint | null;
  mime_type: string | null;
  keyword: string | null;
  status: number;
  created_user_id: number;
  creator_name: string;
  created_date: string;
  modified_user_id: number | null;
  modified_date: string | null;
}

interface DbResult {
  success: boolean;
  message: string;
  id?: number | bigint;
}

// ==========================================
// REPOSITORY
// ==========================================

export const documentRepository = {

  // ---- CATEGORIES ----

  async getCategoryTree(unitId: number): Promise<DocCategoryRow[]> {
    return callFunction<DocCategoryRow>('iso.fn_doc_category_get_tree', [unitId]);
  },

  async createCategory(
    parentId: number,
    code: string | null,
    name: string,
    dateProcess: number | null,
    description: string | null,
    version: number | null,
    unitId: number,
    createdUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('iso.fn_doc_category_create', [
      parentId, code, name, dateProcess, description, version, unitId, createdUserId,
    ]);
    return row ?? { success: false, message: 'Không thể tạo danh mục' };
  },

  async updateCategory(
    id: number,
    parentId: number,
    code: string | null,
    name: string,
    dateProcess: number | null,
    status: number,
    description: string | null,
    version: number | null,
    modifiedUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('iso.fn_doc_category_update', [
      id, parentId, code, name, dateProcess, status, description, version, modifiedUserId,
    ]);
    return row ?? { success: false, message: 'Không thể cập nhật danh mục' };
  },

  async deleteCategory(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('iso.fn_doc_category_delete', [id]);
    return row ?? { success: false, message: 'Không thể xóa danh mục' };
  },

  // ---- DOCUMENTS ----

  async getDocumentList(
    unitId: number,
    categoryId: number | null,
    keyword: string | null,
    page: number,
    pageSize: number,
  ): Promise<DocumentListRow[]> {
    return callFunction<DocumentListRow>('iso.fn_document_get_list', [
      unitId, categoryId, keyword, page, pageSize,
    ]);
  },

  async getDocumentById(id: number): Promise<DocumentDetailRow | null> {
    return callFunctionOne<DocumentDetailRow>('iso.fn_document_get_by_id', [id]);
  },

  async createDocument(
    unitId: number,
    categoryId: number | null,
    title: string,
    description: string | null,
    fileName: string | null,
    filePath: string | null,
    fileSize: number | null,
    mimeType: string | null,
    keyword: string | null,
    status: number,
    createdUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('iso.fn_document_create', [
      unitId, categoryId, title, description, fileName, filePath, fileSize,
      mimeType, keyword, status, createdUserId,
    ]);
    return row ?? { success: false, message: 'Không thể tạo tài liệu' };
  },

  async updateDocument(
    id: number,
    categoryId: number | null,
    title: string,
    description: string | null,
    fileName: string | null,
    filePath: string | null,
    fileSize: number | null,
    mimeType: string | null,
    keyword: string | null,
    status: number,
    modifiedUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('iso.fn_document_update', [
      id, categoryId, title, description, fileName, filePath, fileSize,
      mimeType, keyword, status, modifiedUserId,
    ]);
    return row ?? { success: false, message: 'Không thể cập nhật tài liệu' };
  },

  async deleteDocument(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('iso.fn_document_delete', [id]);
    return row ?? { success: false, message: 'Không thể xóa tài liệu' };
  },
};
