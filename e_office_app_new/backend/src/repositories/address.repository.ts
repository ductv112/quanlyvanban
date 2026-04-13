import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

export interface ProvinceRow {
  id: number;
  name: string;
  code: string;
  is_active: boolean;
}

export interface DistrictRow {
  id: number;
  province_id: number;
  name: string;
  code: string;
  is_active: boolean;
}

export interface CommuneRow {
  id: number;
  district_id: number;
  name: string;
  code: string;
  is_active: boolean;
}

export const addressRepository = {
  // Province
  async provinceGetList(keyword: string): Promise<ProvinceRow[]> {
    return callFunction<ProvinceRow>('public.fn_province_get_list', [keyword]);
  },

  async provinceCreate(name: string, code: string): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'public.fn_province_create',
      [name, code],
    );
    return row ?? { success: false, message: 'Không thể tạo tỉnh/thành phố', id: 0 };
  },

  async provinceUpdate(id: number, name: string, code: string, isActive: boolean): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_province_update',
      [id, name, code, isActive],
    );
    return row ?? { success: false, message: 'Không tìm thấy tỉnh/thành phố' };
  },

  async provinceDelete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_province_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy tỉnh/thành phố' };
  },

  // District
  async districtGetList(provinceId: number, keyword: string): Promise<DistrictRow[]> {
    return callFunction<DistrictRow>('public.fn_district_get_list', [provinceId, keyword]);
  },

  async districtCreate(provinceId: number, name: string, code: string): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'public.fn_district_create',
      [provinceId, name, code],
    );
    return row ?? { success: false, message: 'Không thể tạo quận/huyện', id: 0 };
  },

  async districtUpdate(id: number, name: string, code: string, isActive: boolean): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_district_update',
      [id, name, code, isActive],
    );
    return row ?? { success: false, message: 'Không tìm thấy quận/huyện' };
  },

  async districtDelete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_district_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy quận/huyện' };
  },

  // Commune
  async communeGetList(districtId: number, keyword: string): Promise<CommuneRow[]> {
    return callFunction<CommuneRow>('public.fn_commune_get_list', [districtId, keyword]);
  },

  async communeCreate(districtId: number, name: string, code: string): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'public.fn_commune_create',
      [districtId, name, code],
    );
    return row ?? { success: false, message: 'Không thể tạo xã/phường', id: 0 };
  },

  async communeUpdate(id: number, name: string, code: string, isActive: boolean): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_commune_update',
      [id, name, code, isActive],
    );
    return row ?? { success: false, message: 'Không tìm thấy xã/phường' };
  },

  async communeDelete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'public.fn_commune_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy xã/phường' };
  },
};
