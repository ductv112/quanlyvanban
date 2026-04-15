import { callFunction, callFunctionOne } from '../lib/db/query.js';

// ============ Row types — matched to actual SP RETURNS TABLE ============

// fn_message_get_inbox returns: (id, from_staff_id, from_staff_name, subject, content, parent_id, created_at, is_read, total_count)
export interface MessageInboxRow {
  id: number;
  from_staff_id: number;
  from_staff_name: string;
  subject: string;
  content: string;
  parent_id: number | null;
  created_at: string;
  is_read: boolean;
  total_count: number;
}

// fn_message_get_sent returns: (id, subject, content, parent_id, created_at, recipient_names, total_count)
// NOTE: NO from_staff_id/from_staff_name/is_read — sent messages don't need these
export interface MessageSentRow {
  id: number;
  subject: string;
  content: string;
  parent_id: number | null;
  created_at: string;
  recipient_names: string;
  total_count: number;
}

// fn_message_get_trash returns: (id, from_staff_id, from_staff_name, subject, content, parent_id, created_at, deleted_at, total_count)
export interface MessageTrashRow {
  id: number;
  from_staff_id: number;
  from_staff_name: string;
  subject: string;
  content: string;
  parent_id: number | null;
  created_at: string;
  deleted_at: string;
  total_count: number;
}

// fn_message_get_by_id returns: (id, from_staff_id, from_staff_name, subject, content, parent_id, created_at, is_read, recipient_names)
export interface MessageDetailRow {
  id: number;
  from_staff_id: number;
  from_staff_name: string;
  subject: string;
  content: string;
  parent_id: number | null;
  created_at: string;
  is_read: boolean;
  recipient_names: string;
}

// fn_message_create returns: (success, message, id)
export interface MessageCreateResult {
  success: boolean;
  message: string;
  id: number;
}

// fn_message_reply returns: (success, message, id) — NOT reply_id
export interface MessageReplyResult {
  success: boolean;
  message: string;
  id: number;
}

// fn_message_delete returns: (success, message)
export interface MessageActionResult {
  success: boolean;
  message: string;
}

// ============ Repository ============

export const messageRepository = {

  // fn_message_get_inbox(p_staff_id, p_keyword, p_page, p_page_size)
  async getInbox(
    staffId: number,
    keyword: string | null,
    page: number,
    pageSize: number,
  ): Promise<MessageInboxRow[]> {
    return callFunction<MessageInboxRow>('edoc.fn_message_get_inbox', [
      staffId, keyword ?? null, page, pageSize,
    ]);
  },

  // fn_message_get_sent(p_staff_id, p_keyword, p_page, p_page_size)
  async getSent(
    staffId: number,
    keyword: string | null,
    page: number,
    pageSize: number,
  ): Promise<MessageSentRow[]> {
    return callFunction<MessageSentRow>('edoc.fn_message_get_sent', [
      staffId, keyword ?? null, page, pageSize,
    ]);
  },

  // fn_message_get_trash(p_staff_id, p_page, p_page_size)
  async getTrash(
    staffId: number,
    page: number,
    pageSize: number,
  ): Promise<MessageTrashRow[]> {
    return callFunction<MessageTrashRow>('edoc.fn_message_get_trash', [
      staffId, page, pageSize,
    ]);
  },

  // fn_message_get_by_id(p_id, p_staff_id)
  async getById(id: number, staffId: number): Promise<MessageDetailRow | null> {
    return callFunctionOne<MessageDetailRow>('edoc.fn_message_get_by_id', [id, staffId]);
  },

  // fn_message_create(p_from_staff_id, p_to_staff_ids integer[], p_subject, p_content, p_parent_id)
  async create(
    fromStaffId: number,
    toStaffIds: number[],
    subject: string,
    content: string,
    parentId: number | null,
  ): Promise<MessageCreateResult> {
    // pg driver handles JS arrays as PostgreSQL integer[] natively
    const row = await callFunctionOne<MessageCreateResult>('edoc.fn_message_create', [
      fromStaffId, toStaffIds, subject, content, parentId,
    ]);
    return row ?? { success: false, message: 'Không thể gửi tin nhắn', id: 0 };
  },

  // fn_message_reply(p_message_id, p_staff_id, p_content) -> (success, message, id)
  async reply(
    messageId: number,
    staffId: number,
    content: string,
  ): Promise<MessageReplyResult> {
    const row = await callFunctionOne<MessageReplyResult>('edoc.fn_message_reply', [
      messageId, staffId, content,
    ]);
    return row ?? { success: false, message: 'Không thể trả lời tin nhắn', id: 0 };
  },

  // fn_message_delete(p_id, p_staff_id)
  async delete(id: number, staffId: number): Promise<MessageActionResult> {
    const row = await callFunctionOne<MessageActionResult>('edoc.fn_message_delete', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy tin nhắn' };
  },

  // fn_message_count_unread(p_staff_id)
  async countUnread(staffId: number): Promise<number> {
    const row = await callFunctionOne<{ count: bigint }>('edoc.fn_message_count_unread', [staffId]);
    return row ? Number(row.count) : 0;
  },
};
