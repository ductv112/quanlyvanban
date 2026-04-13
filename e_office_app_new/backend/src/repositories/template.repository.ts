import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { DbResult, DbResultWithId } from './doc-book.repository.js';

export interface SmsTemplateRow {
  id: number;
  unit_id: number;
  name: string;
  content: string;
  description: string;
  is_active: boolean;
  created_by: number;
  created_at: string;
}

export interface EmailTemplateRow {
  id: number;
  unit_id: number;
  name: string;
  subject: string;
  content: string;
  description: string;
  is_active: boolean;
  created_by: number;
  created_at: string;
}

export const templateRepository = {
  // SMS Templates
  async smsGetList(unitId: number): Promise<SmsTemplateRow[]> {
    return callFunction<SmsTemplateRow>('edoc.fn_sms_template_get_list', [unitId]);
  },

  async smsCreate(
    unitId: number,
    name: string,
    content: string,
    description: string,
    createdBy: number,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_sms_template_create',
      [unitId, name, content, description, createdBy],
    );
    return row ?? { success: false, message: 'Không thể tạo mẫu SMS', id: 0 };
  },

  async smsUpdate(
    id: number,
    name: string,
    content: string,
    description: string,
    isActive: boolean,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_sms_template_update',
      [id, name, content, description, isActive],
    );
    return row ?? { success: false, message: 'Không tìm thấy mẫu SMS' };
  },

  async smsDelete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_sms_template_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy mẫu SMS' };
  },

  // Email Templates
  async emailGetList(unitId: number): Promise<EmailTemplateRow[]> {
    return callFunction<EmailTemplateRow>('edoc.fn_email_template_get_list', [unitId]);
  },

  async emailCreate(
    unitId: number,
    name: string,
    subject: string,
    content: string,
    description: string,
    createdBy: number,
  ): Promise<DbResultWithId> {
    const row = await callFunctionOne<DbResultWithId>(
      'edoc.fn_email_template_create',
      [unitId, name, subject, content, description, createdBy],
    );
    return row ?? { success: false, message: 'Không thể tạo mẫu email', id: 0 };
  },

  async emailUpdate(
    id: number,
    name: string,
    subject: string,
    content: string,
    description: string,
    isActive: boolean,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_email_template_update',
      [id, name, subject, content, description, isActive],
    );
    return row ?? { success: false, message: 'Không tìm thấy mẫu email' };
  },

  async emailDelete(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_email_template_delete',
      [id],
    );
    return row ?? { success: false, message: 'Không tìm thấy mẫu email' };
  },
};
