import { callFunction, callFunctionOne } from '../lib/db/query.js';

// ============================================================
// Row interfaces (matching SP output exactly per D-00b)
// ============================================================

export interface RoomRow {
  id: number;
  unit_id: number;
  name: string;
  code: string | null;
  location: string | null;
  note: string | null;
  sort_order: number;
  show_in_calendar: boolean;
  created_date: string;
}

export interface MeetingTypeRow {
  id: number;
  unit_id: number;
  name: string;
  description: string | null;
  sort_order: number;
  created_date: string;
}

export interface RoomScheduleListRow {
  id: number;
  unit_id: number;
  room_id: number;
  room_name: string;
  meeting_type_id: number | null;
  meeting_type_name: string | null;
  name: string;
  content: string | null;
  start_date: string;
  end_date: string | null;
  start_time: string | null;
  end_time: string | null;
  master_id: number | null;
  master_name: string | null;
  approved: number;
  meeting_status: number;
  online_link: string | null;
  created_date: string;
  staff_count: number;
  total_count: number;
}

export interface RoomScheduleDetailRow {
  id: number;
  unit_id: number;
  room_id: number;
  room_name: string;
  meeting_type_id: number | null;
  meeting_type_name: string | null;
  name: string;
  content: string | null;
  component: string | null;
  start_date: string;
  end_date: string | null;
  start_time: string | null;
  end_time: string | null;
  master_id: number | null;
  master_name: string | null;
  secretary_id: number | null;
  approved: number;
  approved_date: string | null;
  approved_staff_id: number | null;
  rejection_reason: string | null;
  meeting_status: number;
  online_link: string | null;
  is_cancel: number;
  created_user_id: number;
  created_date: string;
  modified_user_id: number | null;
  modified_date: string | null;
}

export interface RoomScheduleStaffRow {
  id: number;
  room_schedule_id: number;
  staff_id: number;
  staff_name: string;
  position_name: string | null;
  user_type: number;
  is_secretary: boolean;
  is_represent: boolean;
  attendance: boolean;
  attendance_date: string | null;
  attendance_note: string | null;
  received_appointment: number;
  received_appointment_date: string | null;
  view_date: string | null;
}

export interface VoteQuestionRow {
  id: string;
  room_schedule_id: number;
  name: string;
  start_time: string | null;
  stop_time: string | null;
  duration: number;
  status: number;
  question_type: number;
  order_no: number;
}

export interface VoteResultRow {
  answer_id: string;
  answer_name: string;
  order_no: number;
  vote_count: number;
  voter_names: string;
}

export interface MeetingStatsRow {
  stat_type: string;
  category_id: number;
  category_name: string;
  month_num: number;
  count: number;
}

interface DbResult {
  success: boolean;
  message: string;
  id?: number | string;
}

// ============================================================
// meetingRepository
// ============================================================

export const meetingRepository = {

  // ==========================================
  // ROOMS (PHÒNG HỌP)
  // ==========================================

  async getRoomList(unitId: number): Promise<RoomRow[]> {
    return callFunction<RoomRow>('edoc.fn_room_get_list', [unitId]);
  },

  async createRoom(
    unitId: number,
    name: string,
    code: string | null,
    location: string | null,
    note: string | null,
    sortOrder: number,
    showInCalendar: boolean,
    createdUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_room_create',
      [unitId, name, code, location, note, sortOrder, showInCalendar, createdUserId],
    );
    return row ?? { success: false, message: 'Không thể tạo phòng họp' };
  },

  async updateRoom(
    id: number,
    name: string,
    code: string | null,
    location: string | null,
    note: string | null,
    sortOrder: number,
    showInCalendar: boolean,
    modifiedUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_room_update',
      [id, name, code, location, note, sortOrder, showInCalendar, modifiedUserId],
    );
    return row ?? { success: false, message: 'Không thể cập nhật phòng họp' };
  },

  async deleteRoom(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_room_delete', [id]);
    return row ?? { success: false, message: 'Không thể xóa phòng họp' };
  },

  // ==========================================
  // MEETING TYPES (LOẠI CUỘC HỌP)
  // ==========================================

  async getMeetingTypeList(unitId: number): Promise<MeetingTypeRow[]> {
    return callFunction<MeetingTypeRow>('edoc.fn_meeting_type_get_list', [unitId]);
  },

  async createMeetingType(
    unitId: number,
    name: string,
    description: string | null,
    sortOrder: number,
    createdUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_meeting_type_create',
      [unitId, name, description, sortOrder, createdUserId],
    );
    return row ?? { success: false, message: 'Không thể tạo loại cuộc họp' };
  },

  async updateMeetingType(
    id: number,
    name: string,
    description: string | null,
    sortOrder: number,
    modifiedUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_meeting_type_update',
      [id, name, description, sortOrder, modifiedUserId],
    );
    return row ?? { success: false, message: 'Không thể cập nhật loại cuộc họp' };
  },

  async deleteMeetingType(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_meeting_type_delete', [id]);
    return row ?? { success: false, message: 'Không thể xóa loại cuộc họp' };
  },

  // ==========================================
  // ROOM SCHEDULES (CUỘC HỌP)
  // ==========================================

  async getRoomScheduleList(
    unitId: number,
    roomId: number | null,
    status: number | null,
    fromDate: string | null,
    toDate: string | null,
    keyword: string | null,
    page: number,
    pageSize: number,
  ): Promise<RoomScheduleListRow[]> {
    return callFunction<RoomScheduleListRow>(
      'edoc.fn_room_schedule_get_list',
      [unitId, roomId, status, fromDate, toDate, keyword, page, pageSize],
    );
  },

  async getRoomScheduleById(id: number): Promise<RoomScheduleDetailRow | null> {
    return callFunctionOne<RoomScheduleDetailRow>('edoc.fn_room_schedule_get_by_id', [id]);
  },

  async createRoomSchedule(
    unitId: number,
    roomId: number,
    meetingTypeId: number | null,
    name: string,
    content: string | null,
    component: string | null,
    startDate: string,
    endDate: string | null,
    startTime: string | null,
    endTime: string | null,
    masterId: number | null,
    secretaryId: number | null,
    onlineLink: string | null,
    createdUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_room_schedule_create',
      [unitId, roomId, meetingTypeId, name, content, component,
        startDate, endDate, startTime, endTime, masterId, secretaryId,
        onlineLink, createdUserId],
    );
    return row ?? { success: false, message: 'Không thể tạo cuộc họp' };
  },

  async updateRoomSchedule(
    id: number,
    roomId: number,
    meetingTypeId: number | null,
    name: string,
    content: string | null,
    component: string | null,
    startDate: string,
    endDate: string | null,
    startTime: string | null,
    endTime: string | null,
    masterId: number | null,
    secretaryId: number | null,
    onlineLink: string | null,
    modifiedUserId: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_room_schedule_update',
      [id, roomId, meetingTypeId, name, content, component,
        startDate, endDate, startTime, endTime, masterId, secretaryId,
        onlineLink, modifiedUserId],
    );
    return row ?? { success: false, message: 'Không thể cập nhật cuộc họp' };
  },

  async deleteRoomSchedule(id: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>('edoc.fn_room_schedule_delete', [id]);
    return row ?? { success: false, message: 'Không thể xóa cuộc họp' };
  },

  async approveRoomSchedule(id: number, approvedStaffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_room_schedule_approve',
      [id, approvedStaffId],
    );
    return row ?? { success: false, message: 'Không thể duyệt cuộc họp' };
  },

  async rejectRoomSchedule(id: number, approvedStaffId: number, reason: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_room_schedule_reject',
      [id, approvedStaffId, reason],
    );
    return row ?? { success: false, message: 'Không thể từ chối cuộc họp' };
  },

  // ==========================================
  // STAFF MANAGEMENT (THÀNH VIÊN)
  // ==========================================

  async getRoomScheduleStaff(roomScheduleId: number): Promise<RoomScheduleStaffRow[]> {
    return callFunction<RoomScheduleStaffRow>(
      'edoc.fn_room_schedule_get_staff',
      [roomScheduleId],
    );
  },

  async assignStaff(
    roomScheduleId: number,
    staffIds: number[],
    userType: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_room_schedule_assign_staff',
      [roomScheduleId, staffIds, userType],
    );
    return row ?? { success: false, message: 'Không thể phân công thành viên' };
  },

  async removeStaff(roomScheduleId: number, staffId: number): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_room_schedule_remove_staff',
      [roomScheduleId, staffId],
    );
    return row ?? { success: false, message: 'Không thể xóa thành viên' };
  },

  // ==========================================
  // VOTING (BIỂU QUYẾT)
  // ==========================================

  async getVoteQuestions(roomScheduleId: number): Promise<VoteQuestionRow[]> {
    return callFunction<VoteQuestionRow>(
      'edoc.fn_vote_question_get_list',
      [roomScheduleId],
    );
  },

  async createVoteQuestion(
    roomScheduleId: number,
    name: string,
    questionType: number,
    duration: number,
    orderNo: number,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_vote_question_create',
      [roomScheduleId, name, questionType, duration, orderNo],
    );
    return row ?? { success: false, message: 'Không thể tạo câu hỏi biểu quyết' };
  },

  async createVoteAnswer(
    questionId: string,
    roomScheduleId: number,
    name: string,
    orderNo: number,
    isOther: boolean,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_vote_answer_create',
      [questionId, roomScheduleId, name, orderNo, isOther],
    );
    return row ?? { success: false, message: 'Không thể tạo đáp án biểu quyết' };
  },

  async castVote(
    questionId: string,
    answerId: string,
    staffId: number,
    otherText: string | null,
  ): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_vote_cast',
      [questionId, answerId, staffId, otherText],
    );
    return row ?? { success: false, message: 'Không thể ghi nhận biểu quyết' };
  },

  async startVoteQuestion(questionId: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_vote_question_start',
      [questionId],
    );
    return row ?? { success: false, message: 'Không thể bắt đầu biểu quyết' };
  },

  async stopVoteQuestion(questionId: string): Promise<DbResult> {
    const row = await callFunctionOne<DbResult>(
      'edoc.fn_vote_question_stop',
      [questionId],
    );
    return row ?? { success: false, message: 'Không thể kết thúc biểu quyết' };
  },

  async getVoteResults(questionId: string): Promise<VoteResultRow[]> {
    return callFunction<VoteResultRow>('edoc.fn_vote_get_results', [questionId]);
  },

  // ==========================================
  // STATISTICS (THỐNG KÊ)
  // ==========================================

  async getMeetingStats(unitId: number, year: number): Promise<MeetingStatsRow[]> {
    return callFunction<MeetingStatsRow>('edoc.fn_room_schedule_stats', [unitId, year]);
  },
};
