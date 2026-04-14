import { callFunction, callFunctionOne } from '../lib/db/query.js';

// ============ Row types ============

export interface MessageListRow {
  id: number;
  from_staff_id: number;
  from_staff_name: string;
  subject: string;
  content: string; // truncated
  is_read: boolean;
  created_at: string;
  total_count: number;
}

export interface MessageDetailRow {
  id: number;
  from_staff_id: number;
  from_staff_name: string;
  subject: string;
  content: string;
  parent_id: number | null;
  is_read: boolean;
  created_at: string;
  recipients: string; // comma-separated names
}

export interface MessageReplyRow {
  id: number;
  from_staff_id: number;
  from_staff_name: string;
  content: string;
  created_at: string;
}

export interface UnreadCountRow {
  count: bigint;
}

export interface MessageCreateResult {
  success: boolean;
  message: string;
  id: number;
}

// fn_message_reply returns reply_id (not id) — separate type to avoid confusion
export interface MessageReplyResult {
  success: boolean;
  message: string;
  reply_id: number;
}

export interface MessageActionResult {
  success: boolean;
  message: string;
}

// ============ Repository ============

export const messageRepository = {

  async getInbox(
    staffId: number,
    keyword: string | null,
    page: number,
    pageSize: number,
  ): Promise<MessageListRow[]> {
    return callFunction<MessageListRow>('edoc.fn_message_get_inbox', [
      staffId, keyword ?? null, page, pageSize,
    ]);
  },

  async getSent(
    staffId: number,
    keyword: string | null,
    page: number,
    pageSize: number,
  ): Promise<MessageListRow[]> {
    return callFunction<MessageListRow>('edoc.fn_message_get_sent', [
      staffId, keyword ?? null, page, pageSize,
    ]);
  },

  async getTrash(
    staffId: number,
    page: number,
    pageSize: number,
  ): Promise<MessageListRow[]> {
    return callFunction<MessageListRow>('edoc.fn_message_get_trash', [
      staffId, page, pageSize,
    ]);
  },

  async getById(id: number, staffId: number): Promise<MessageDetailRow | null> {
    return callFunctionOne<MessageDetailRow>('edoc.fn_message_get_by_id', [id, staffId]);
  },

  async create(
    fromStaffId: number,
    toStaffIds: number[],
    subject: string,
    content: string,
    parentId: number | null,
  ): Promise<MessageCreateResult> {
    // Convert array to PostgreSQL array literal {1,2,3}
    const pgArray = `{${toStaffIds.join(',')}}`;
    const row = await callFunctionOne<MessageCreateResult>('edoc.fn_message_create', [
      fromStaffId, pgArray, subject, content, parentId,
    ]);
    return row ?? { success: false, message: 'Không thể gửi tin nhắn', id: 0 };
  },

  async reply(
    messageId: number,
    staffId: number,
    content: string,
  ): Promise<MessageReplyResult> {
    const row = await callFunctionOne<MessageReplyResult>('edoc.fn_message_reply', [
      messageId, staffId, content,
    ]);
    return row ?? { success: false, message: 'Không thể trả lời tin nhắn', reply_id: 0 };
  },

  async delete(id: number, staffId: number): Promise<MessageActionResult> {
    const row = await callFunctionOne<MessageActionResult>('edoc.fn_message_delete', [id, staffId]);
    return row ?? { success: false, message: 'Không tìm thấy tin nhắn' };
  },

  async countUnread(staffId: number): Promise<number> {
    const row = await callFunctionOne<{ count: bigint }>('edoc.fn_message_count_unread', [staffId]);
    return row ? Number(row.count) : 0;
  },
};
