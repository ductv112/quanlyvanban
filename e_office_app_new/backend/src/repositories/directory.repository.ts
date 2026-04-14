import { callFunction } from '../lib/db/query.js';

export interface DirectoryRow {
  id: number;
  full_name: string;
  position_name: string;
  department_name: string;
  unit_name: string;
  phone: string;
  mobile: string;
  email: string;
  image: string;
  total_count: number;
}

export const directoryRepository = {
  async getList(
    unitId: number | null,
    departmentId: number | null,
    search: string | null,
    page: number,
    pageSize: number,
  ): Promise<DirectoryRow[]> {
    return callFunction<DirectoryRow>(
      'public.fn_directory_get_list',
      [unitId, departmentId, search, page, pageSize],
    );
  },
};
