import { callFunction, callFunctionOne } from '../lib/db/query.js';

export interface RightTreeRow {
  id: number;
  parent_id: number | null;
  name: string;
  name_of_menu: string;
  action_link: string;
  icon: string;
  sort_order: number;
  show_menu: boolean;
  default_page: boolean;
  show_in_app: boolean;
  description: string;
  is_locked: boolean;
}

export interface RightMenuRow {
  id: number;
  parent_id: number | null;
  name: string;
  name_of_menu: string;
  action_link: string;
  icon: string;
  sort_order: number;
  default_page: boolean;
  show_in_app: boolean;
}

export const rightRepository = {
  async getTree(): Promise<RightTreeRow[]> {
    return callFunction<RightTreeRow>('public.fn_right_get_tree', []);
  },

  async getById(id: number): Promise<RightTreeRow | null> {
    return callFunctionOne<RightTreeRow>('public.fn_right_get_by_id', [id]);
  },

  async create(
    parentId: number | null,
    name: string,
    nameOfMenu: string,
    actionLink: string,
    icon: string,
    sortOrder: number,
    showMenu: boolean,
    defaultPage: boolean,
    showInApp: boolean,
    description: string,
  ): Promise<number | null> {
    const row = await callFunctionOne<{ fn_right_create: number }>(
      'public.fn_right_create',
      [parentId, name, nameOfMenu, actionLink, icon, sortOrder, showMenu, defaultPage, showInApp, description],
    );
    return row?.fn_right_create ?? null;
  },

  async update(
    id: number,
    parentId: number | null,
    name: string,
    nameOfMenu: string,
    actionLink: string,
    icon: string,
    sortOrder: number,
    showMenu: boolean,
    defaultPage: boolean,
    showInApp: boolean,
    description: string,
  ): Promise<boolean> {
    const row = await callFunctionOne<{ fn_right_update: boolean }>(
      'public.fn_right_update',
      [id, parentId, name, nameOfMenu, actionLink, icon, sortOrder, showMenu, defaultPage, showInApp, description],
    );
    return row?.fn_right_update ?? false;
  },

  async delete(id: number): Promise<{ success: boolean; message: string }> {
    const row = await callFunctionOne<{ success: boolean; message: string }>(
      'public.fn_right_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy chức năng' };
  },

  async getByStaff(staffId: number): Promise<RightMenuRow[]> {
    return callFunction<RightMenuRow>('public.fn_right_get_by_staff', [staffId]);
  },
};
