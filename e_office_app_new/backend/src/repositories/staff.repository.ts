import { callFunction, callFunctionOne } from '../lib/db/query.js';

export interface StaffListRow {
  id: number;
  username: string;
  first_name: string;
  last_name: string;
  full_name: string;
  gender: number;
  email: string;
  phone: string;
  mobile: string;
  image: string;
  position_name: string;
  department_name: string;
  unit_name: string;
  is_admin: boolean;
  is_locked: boolean;
  total_count: number;
}

export interface StaffDetailRow {
  id: number;
  department_id: number;
  unit_id: number;
  position_id: number;
  username: string;
  first_name: string;
  last_name: string;
  full_name: string;
  gender: number;
  birth_date: string;
  email: string;
  phone: string;
  mobile: string;
  address: string;
  id_card: string;
  id_card_date: string;
  id_card_place: string;
  image: string;
  is_admin: boolean;
  is_represent_unit: boolean;
  is_represent_department: boolean;
  is_locked: boolean;
  position_name: string;
  department_name: string;
  unit_name: string;
  created_at: string;
  updated_at: string;
}

export const staffRepository = {
  async getList(
    unitId: number | null,
    departmentId: number | null,
    keyword: string,
    isLocked: boolean | null,
    page: number,
    pageSize: number,
  ): Promise<StaffListRow[]> {
    return callFunction<StaffListRow>('public.fn_staff_get_list', [
      unitId, departmentId, keyword, isLocked, page, pageSize,
    ]);
  },

  async getById(id: number): Promise<StaffDetailRow | null> {
    return callFunctionOne<StaffDetailRow>('public.fn_staff_get_by_id', [id]);
  },

  async create(
    departmentId: number,
    unitId: number,
    positionId: number,
    username: string,
    passwordHash: string,
    firstName: string,
    lastName: string,
    gender: number,
    birthDate: string | null,
    email: string,
    phone: string,
    mobile: string,
    address: string,
    idCard: string,
    idCardDate: string | null,
    idCardPlace: string,
    isAdmin: boolean,
    isRepresentUnit: boolean,
    isRepresentDepartment: boolean,
    createdBy: number,
  ): Promise<{ id: number; message: string } | null> {
    return callFunctionOne<{ id: number; message: string }>(
      'public.fn_staff_create',
      [departmentId, unitId, positionId, username, passwordHash, firstName, lastName, gender, birthDate, email, phone, mobile, address, idCard, idCardDate, idCardPlace, isAdmin, isRepresentUnit, isRepresentDepartment, createdBy],
    );
  },

  async update(
    id: number,
    departmentId: number,
    unitId: number,
    positionId: number,
    firstName: string,
    lastName: string,
    gender: number,
    birthDate: string | null,
    email: string,
    phone: string,
    mobile: string,
    address: string,
    idCard: string,
    idCardDate: string | null,
    idCardPlace: string,
    isAdmin: boolean,
    isRepresentUnit: boolean,
    isRepresentDepartment: boolean,
    updatedBy: number,
  ): Promise<boolean> {
    const row = await callFunctionOne<{ fn_staff_update: boolean }>(
      'public.fn_staff_update',
      [id, departmentId, unitId, positionId, firstName, lastName, gender, birthDate, email, phone, mobile, address, idCard, idCardDate, idCardPlace, isAdmin, isRepresentUnit, isRepresentDepartment, updatedBy],
    );
    return row?.fn_staff_update ?? false;
  },

  async delete(id: number): Promise<boolean> {
    const row = await callFunctionOne<{ fn_staff_delete: boolean }>(
      'public.fn_staff_delete',
      [id],
    );
    return row?.fn_staff_delete ?? false;
  },

  async toggleLock(id: number): Promise<boolean> {
    const row = await callFunctionOne<{ fn_staff_toggle_lock: boolean }>(
      'public.fn_staff_toggle_lock',
      [id],
    );
    return row?.fn_staff_toggle_lock ?? false;
  },

  async resetPassword(id: number, newPasswordHash: string): Promise<boolean> {
    const row = await callFunctionOne<{ fn_staff_reset_password: boolean }>(
      'public.fn_staff_reset_password',
      [id, newPasswordHash],
    );
    return row?.fn_staff_reset_password ?? false;
  },

  async updateAvatar(id: number, imagePath: string): Promise<boolean> {
    const row = await callFunctionOne<{ fn_staff_update_avatar: boolean }>(
      'public.fn_staff_update_avatar',
      [id, imagePath],
    );
    return row?.fn_staff_update_avatar ?? false;
  },
};
