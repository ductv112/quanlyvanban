import { callFunctionOne } from '../lib/db/query.js';
import type { DbResult } from './doc-book.repository.js';

export interface OrganizationRow {
  id: number;
  unit_id: number;
  code: string;
  name: string;
  address: string;
  phone: string;
  fax: string;
  email: string;
  email_doc: string;
  secretary: string;
  chairman_number: string;
  level: number;
  is_exchange: boolean;
  lgsp_system_id: string;
  lgsp_secret_key: string;
  updated_by: number;
  updated_at: string;
}

export const organizationRepository = {
  async get(unitId: number): Promise<OrganizationRow | null> {
    return callFunctionOne<OrganizationRow>('edoc.fn_organization_get', [unitId]);
  },

  async upsert(
    unitId: number,
    code: string,
    name: string,
    address: string,
    phone: string,
    fax: string,
    email: string,
    emailDoc: string,
    secretary: string,
    chairmanNumber: string,
    level: number,
    isExchange: boolean,
    updatedBy: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_organization_upsert',
      [unitId, code, name, address, phone, fax, email, emailDoc, secretary, chairmanNumber, level, isExchange, updatedBy],
    );
    return row ?? { success: false, message: 'Không thể cập nhật thông tin cơ quan' };
  },
};
