import { callFunction, callFunctionOne } from '../lib/db/query.js';

export interface DepartmentTreeRow {
  id: number;
  parent_id: number | null;
  code: string;
  name: string;
  name_en: string;
  short_name: string;
  abb_name: string;
  is_unit: boolean;
  level: number;
  sort_order: number;
  phone: string;
  fax: string;
  email: string;
  address: string;
  allow_doc_book: boolean;
  is_locked: boolean;
  staff_count: number;
}

// fn_department_get_by_id returns these extra fields vs tree row:
// description, is_locked (already in tree), lgsp_system_id, lgsp_secret_key, created_at, updated_at
// NOTE: created_by and updated_by are NOT returned by this SP
export interface DepartmentDetailRow extends DepartmentTreeRow {
  description: string;
  lgsp_system_id: string;
  lgsp_secret_key: string;
  created_at: string;
  updated_at: string;
}

export const departmentRepository = {
  async getTree(unitId: number | null): Promise<DepartmentTreeRow[]> {
    return callFunction<DepartmentTreeRow>('public.fn_department_get_tree', [unitId]);
  },

  async getById(id: number): Promise<DepartmentDetailRow | null> {
    return callFunctionOne<DepartmentDetailRow>('public.fn_department_get_by_id', [id]);
  },

  async create(
    parentId: number | null,
    code: string,
    name: string,
    nameEn: string,
    shortName: string,
    abbName: string,
    isUnit: boolean,
    level: number,
    sortOrder: number,
    phone: string,
    fax: string,
    email: string,
    address: string,
    allowDocBook: boolean,
    description: string,
    createdBy: number,
  ): Promise<number | null> {
    const row = await callFunctionOne<{ fn_department_create: number }>(
      'public.fn_department_create',
      [parentId, code, name, nameEn, shortName, abbName, isUnit, level, sortOrder, phone, fax, email, address, allowDocBook, description, createdBy],
    );
    return row?.fn_department_create ?? null;
  },

  async update(
    id: number,
    parentId: number | null,
    code: string,
    name: string,
    nameEn: string,
    shortName: string,
    abbName: string,
    isUnit: boolean,
    level: number,
    sortOrder: number,
    phone: string,
    fax: string,
    email: string,
    address: string,
    allowDocBook: boolean,
    description: string,
    updatedBy: number,
  ): Promise<boolean> {
    const row = await callFunctionOne<{ fn_department_update: boolean }>(
      'public.fn_department_update',
      [id, parentId, code, name, nameEn, shortName, abbName, isUnit, level, sortOrder, phone, fax, email, address, allowDocBook, description, updatedBy],
    );
    return row?.fn_department_update ?? false;
  },

  async delete(id: number): Promise<{ success: boolean; message: string }> {
    const row = await callFunctionOne<{ success: boolean; message: string }>(
      'public.fn_department_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy đơn vị' };
  },

  async toggleLock(id: number): Promise<boolean> {
    const row = await callFunctionOne<{ fn_department_toggle_lock: boolean }>(
      'public.fn_department_toggle_lock',
      [id],
    );
    return row?.fn_department_toggle_lock ?? false;
  },
};
