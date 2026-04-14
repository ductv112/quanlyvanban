import { Router, type Request, type Response } from 'express';
import type { AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { meetingRepository } from '../repositories/meeting.repository.js';
import { uploadFile } from '../lib/minio/client.js';
import { emitToUsers } from '../lib/socket.js';
import { v4 as uuidv4 } from 'uuid';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

// ============================================================
// PHÒNG HỌP (ROOMS)
// ============================================================

// GET /phong-hop — Danh sách phòng họp
router.get('/phong-hop', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const rows = await meetingRepository.getRoomList(unitId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /phong-hop — Tạo phòng họp
router.post('/phong-hop', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const { name, code, location, note, sort_order, show_in_calendar } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên phòng họp là bắt buộc' });
      return;
    }

    const result = await meetingRepository.createRoom(
      unitId,
      name.trim(),
      code || null,
      location || null,
      note || null,
      sort_order ? Number(sort_order) : 0,
      show_in_calendar !== false,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.status(201).json({ success: true, message: result.message, id: result.id });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /phong-hop/:id — Cập nhật phòng họp
router.put('/phong-hop/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const { name, code, location, note, sort_order, show_in_calendar } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên phòng họp là bắt buộc' });
      return;
    }

    const result = await meetingRepository.updateRoom(
      id,
      name.trim(),
      code || null,
      location || null,
      note || null,
      sort_order ? Number(sort_order) : 0,
      show_in_calendar !== false,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /phong-hop/:id — Xóa phòng họp
router.delete('/phong-hop/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await meetingRepository.deleteRoom(id);

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// LOẠI CUỘC HỌP (MEETING TYPES)
// ============================================================

// GET /loai-cuoc-hop — Danh sách loại cuộc họp
router.get('/loai-cuoc-hop', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const rows = await meetingRepository.getMeetingTypeList(unitId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /loai-cuoc-hop — Tạo loại cuộc họp
router.post('/loai-cuoc-hop', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const { name, description, sort_order } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên loại cuộc họp là bắt buộc' });
      return;
    }

    const result = await meetingRepository.createMeetingType(
      unitId,
      name.trim(),
      description || null,
      sort_order ? Number(sort_order) : 0,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.status(201).json({ success: true, message: result.message, id: result.id });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /loai-cuoc-hop/:id — Cập nhật loại cuộc họp
router.put('/loai-cuoc-hop/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const { name, description, sort_order } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên loại cuộc họp là bắt buộc' });
      return;
    }

    const result = await meetingRepository.updateMeetingType(
      id,
      name.trim(),
      description || null,
      sort_order ? Number(sort_order) : 0,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /loai-cuoc-hop/:id — Xóa loại cuộc họp
router.delete('/loai-cuoc-hop/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await meetingRepository.deleteMeetingType(id);

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// THỐNG KÊ — MUST be before /:id to prevent param shadowing
// ============================================================

// GET /thong-ke — Thống kê cuộc họp
router.get('/thong-ke', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const year = req.query.year ? Number(req.query.year) : new Date().getFullYear();
    const rows = await meetingRepository.getMeetingStats(unitId, year);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// LỊCH HỌP / CUỘC HỌP (ROOM SCHEDULES)
// ============================================================

// GET / — Danh sách cuộc họp (phân trang + filter)
router.get('/', async (req: Request, res: Response) => {
  try {
    const { unitId } = (req as AuthRequest).user;
    const { room_id, status, from_date, to_date, keyword, page, page_size } = req.query;

    const rows = await meetingRepository.getRoomScheduleList(
      unitId,
      room_id ? Number(room_id) : null,
      status !== undefined ? Number(status) : null,
      from_date as string || null,
      to_date as string || null,
      keyword as string || null,
      page ? Number(page) : 1,
      page_size ? Number(page_size) : 20,
    );

    const total = rows[0]?.total_count ?? 0;
    res.json({
      success: true,
      data: rows,
      pagination: {
        total: Number(total),
        page: page ? Number(page) : 1,
        pageSize: page_size ? Number(page_size) : 20,
      },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id — Chi tiết cuộc họp
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const row = await meetingRepository.getRoomScheduleById(id);

    if (!row) {
      res.status(404).json({ success: false, message: 'Không tìm thấy cuộc họp' });
      return;
    }

    res.json({ success: true, data: row });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST / — Tạo cuộc họp
router.post('/', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const body = req.body;

    if (!body.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên cuộc họp là bắt buộc' });
      return;
    }
    if (!body.room_id) {
      res.status(400).json({ success: false, message: 'Phòng họp là bắt buộc' });
      return;
    }
    if (!body.start_date) {
      res.status(400).json({ success: false, message: 'Ngày họp là bắt buộc' });
      return;
    }

    const result = await meetingRepository.createRoomSchedule(
      unitId,
      Number(body.room_id),
      body.meeting_type_id ? Number(body.meeting_type_id) : null,
      body.name.trim(),
      body.content || null,
      body.component || null,
      body.start_date,
      body.end_date || null,
      body.start_time || null,
      body.end_time || null,
      body.master_id ? Number(body.master_id) : null,
      body.secretary_id ? Number(body.secretary_id) : null,
      body.online_link || null,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.status(201).json({ success: true, message: result.message, id: result.id });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PUT /:id — Cập nhật cuộc họp
router.put('/:id', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const body = req.body;

    if (!body.name?.trim()) {
      res.status(400).json({ success: false, message: 'Tên cuộc họp là bắt buộc' });
      return;
    }

    const result = await meetingRepository.updateRoomSchedule(
      id,
      body.room_id ? Number(body.room_id) : 0,
      body.meeting_type_id ? Number(body.meeting_type_id) : null,
      body.name.trim(),
      body.content || null,
      body.component || null,
      body.start_date,
      body.end_date || null,
      body.start_time || null,
      body.end_time || null,
      body.master_id ? Number(body.master_id) : null,
      body.secretary_id ? Number(body.secretary_id) : null,
      body.online_link || null,
      staffId,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /:id — Xóa cuộc họp
router.delete('/:id', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const result = await meetingRepository.deleteRoomSchedule(id);

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /:id/approve — Duyệt cuộc họp (approved_staff_id from JWT — T-05-12)
router.patch('/:id/approve', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);

    const result = await meetingRepository.approveRoomSchedule(id, staffId);

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /:id/reject — Từ chối cuộc họp
router.patch('/:id/reject', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const { rejection_reason } = req.body;

    if (!rejection_reason?.trim()) {
      res.status(400).json({ success: false, message: 'Lý do từ chối là bắt buộc' });
      return;
    }

    const result = await meetingRepository.rejectRoomSchedule(id, staffId, rejection_reason.trim());

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// THÀNH VIÊN HỌP (STAFF)
// ============================================================

// GET /:id/thanh-vien — Danh sách thành viên cuộc họp
router.get('/:id/thanh-vien', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const rows = await meetingRepository.getRoomScheduleStaff(id);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/thanh-vien — Phân công thành viên
router.post('/:id/thanh-vien', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { staff_ids, user_type } = req.body;

    if (!Array.isArray(staff_ids) || staff_ids.length === 0) {
      res.status(400).json({ success: false, message: 'Danh sách nhân sự không hợp lệ' });
      return;
    }

    const result = await meetingRepository.assignStaff(
      id,
      staff_ids.map(Number),
      user_type ? Number(user_type) : 0,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.status(201).json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// DELETE /:id/thanh-vien/:staffId — Xóa thành viên
router.delete('/:id/thanh-vien/:staffId', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const staffId = Number(req.params.staffId);

    const result = await meetingRepository.removeStaff(id, staffId);

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// TÀI LIỆU HỌP (ATTACHMENTS)
// ============================================================

// POST /:id/tai-lieu — Tải lên tài liệu cuộc họp (D-05 pattern)
router.post('/:id/tai-lieu', upload.single('file'), async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const scheduleId = Number(req.params.id);

    if (!req.file) {
      res.status(400).json({ success: false, message: 'Không có file được tải lên' });
      return;
    }

    const fileId = uuidv4();
    const objectName = `cuoc-hop/${scheduleId}/${fileId}/${req.file.originalname}`;
    await uploadFile(objectName, req.file.buffer, req.file.mimetype);

    // Record attachment in DB via raw insert (no SP for this, store path directly)
    const { rawQuery } = await import('../lib/db/query.js');
    await rawQuery(
      `INSERT INTO edoc.room_schedule_attachments
        (room_schedule_id, file_name, file_path, file_size, mime_type, created_user_id)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [scheduleId, req.file.originalname, objectName, req.file.size, req.file.mimetype, staffId],
    );

    res.status(201).json({
      success: true,
      message: 'Tải lên tài liệu thành công',
      data: { file_name: req.file.originalname, file_path: objectName },
    });
  } catch (error) {
    handleDbError(error, res);
  }
});

// ============================================================
// BIỂU QUYẾT (VOTING) — T-05-10, T-05-11
// ============================================================

// GET /:id/bieu-quyet — Danh sách câu hỏi biểu quyết
router.get('/:id/bieu-quyet', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const rows = await meetingRepository.getVoteQuestions(id);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/bieu-quyet/cau-hoi — Tạo câu hỏi biểu quyết
router.post('/:id/bieu-quyet/cau-hoi', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const { name, question_type, duration, order_no } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Nội dung câu hỏi là bắt buộc' });
      return;
    }

    const result = await meetingRepository.createVoteQuestion(
      id,
      name.trim(),
      question_type ? Number(question_type) : 0,
      duration ? Number(duration) : 60,
      order_no ? Number(order_no) : 0,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.status(201).json({ success: true, message: result.message, id: result.id });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/bieu-quyet/cau-hoi/:questionId/dap-an — Tạo đáp án
router.post('/:id/bieu-quyet/cau-hoi/:questionId/dap-an', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const questionId = req.params.questionId as string;
    const { name, order_no, is_other } = req.body;

    if (!name?.trim()) {
      res.status(400).json({ success: false, message: 'Nội dung đáp án là bắt buộc' });
      return;
    }

    const result = await meetingRepository.createVoteAnswer(
      questionId,
      id,
      name.trim(),
      order_no ? Number(order_no) : 0,
      is_other === true || is_other === 'true',
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    res.status(201).json({ success: true, message: result.message, id: result.id });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /:id/bieu-quyet/cau-hoi/:questionId/bat-dau — Bắt đầu biểu quyết
router.patch('/:id/bieu-quyet/cau-hoi/:questionId/bat-dau', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const questionId = req.params.questionId as string;

    const result = await meetingRepository.startVoteQuestion(questionId);

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    // Emit vote_status_change to all meeting staff
    const staffList = await meetingRepository.getRoomScheduleStaff(id);
    const staffIds = staffList.map(s => s.staff_id);
    emitToUsers(staffIds, 'vote_status_change', { question_id: questionId, status: 1 });

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// PATCH /:id/bieu-quyet/cau-hoi/:questionId/ket-thuc — Kết thúc biểu quyết
router.patch('/:id/bieu-quyet/cau-hoi/:questionId/ket-thuc', async (req: Request, res: Response) => {
  try {
    const id = Number(req.params.id);
    const questionId = req.params.questionId as string;

    const result = await meetingRepository.stopVoteQuestion(questionId);

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    // Emit vote_status_change to all meeting staff
    const staffList = await meetingRepository.getRoomScheduleStaff(id);
    const staffIds = staffList.map(s => s.staff_id);
    emitToUsers(staffIds, 'vote_status_change', { question_id: questionId, status: 2 });

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// POST /:id/bieu-quyet/cau-hoi/:questionId/vote — Bỏ phiếu (staff_id from JWT — T-05-10)
router.post('/:id/bieu-quyet/cau-hoi/:questionId/vote', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const id = Number(req.params.id);
    const questionId = req.params.questionId as string;
    const { answer_id, other_text } = req.body;

    if (!answer_id) {
      res.status(400).json({ success: false, message: 'Đáp án là bắt buộc' });
      return;
    }

    const result = await meetingRepository.castVote(
      questionId,
      answer_id,
      staffId, // T-05-10: staff_id from JWT, not body
      other_text || null,
    );

    if (!result.success) {
      res.status(400).json({ success: false, message: result.message });
      return;
    }

    // Emit vote_update to all meeting staff (T-05-11: filter via room_schedule_id)
    const staffList = await meetingRepository.getRoomScheduleStaff(id);
    const staffIds = staffList.map(s => s.staff_id);
    emitToUsers(staffIds, 'vote_update', { room_schedule_id: id, question_id: questionId });

    res.json({ success: true, message: result.message });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /:id/bieu-quyet/cau-hoi/:questionId/ket-qua — Kết quả biểu quyết
router.get('/:id/bieu-quyet/cau-hoi/:questionId/ket-qua', async (req: Request, res: Response) => {
  try {
    const questionId = req.params.questionId as string;
    const rows = await meetingRepository.getVoteResults(questionId);
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
