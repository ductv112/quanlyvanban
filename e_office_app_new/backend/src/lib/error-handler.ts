import type { Response } from 'express';

/**
 * Maps PostgreSQL constraint violation errors to Vietnamese user messages.
 * Shared across all route files — add new constraint names here when new tables are created.
 */
export function handleDbError(error: unknown, res: Response): void {
  const err = error as any;

  // PostgreSQL unique violation (error code 23505)
  if (err?.code === '23505') {
    const constraint = err?.constraint || '';
    const messageMap: Record<string, string> = {
      // Admin — System entities (admin.ts)
      'uq_departments_code': 'Mã đơn vị đã tồn tại',
      'uq_positions_code': 'Mã chức vụ đã tồn tại',
      'uq_roles_name': 'Tên nhóm quyền đã tồn tại',
      'staff_username_key': 'Tên đăng nhập đã tồn tại',
      // Admin — Catalog entities (admin-catalog.ts)
      'uq_doc_books_name': 'Tên sổ văn bản đã tồn tại',
      'uq_doc_types_code': 'Mã loại văn bản đã tồn tại',
      'uq_doc_fields_code': 'Mã lĩnh vực đã tồn tại',
      'uq_provinces_code': 'Mã tỉnh/thành phố đã tồn tại',
      'uq_districts_code': 'Mã quận/huyện đã tồn tại',
      'uq_communes_code': 'Mã xã/phường đã tồn tại',
      'uq_signers_staff': 'Người ký đã tồn tại',
      'uq_work_groups_name': 'Tên nhóm làm việc đã tồn tại',
      'uq_delegations_from_to': 'Ủy quyền đã tồn tại',
      // Handling docs
      'handling_doc_links_handling_doc_id_doc_type_doc_id_key': 'Văn bản này đã được liên kết',
      // Archive (esto)
      'uq_warehouses_code': 'Mã kho đã tồn tại',
      'uq_fonds_code': 'Mã phông đã tồn tại',
      // Documents (iso)
      'uq_doc_categories_code': 'Mã danh mục đã tồn tại',
      // Contracts (cont)
      'uq_contract_types_code': 'Mã loại hợp đồng đã tồn tại',
      // Meetings (edoc)
      'uq_rooms_code': 'Mã phòng họp đã tồn tại',
      'uq_room_schedule_staff': 'Thành viên đã được thêm vào cuộc họp',
      'room_schedule_staff_room_schedule_id_staff_id_key': 'Thành viên đã được thêm vào cuộc họp',
      // Phase 6 — LGSP (edoc)
      'uq_lgsp_org_code': 'Mã cơ quan LGSP đã tồn tại',
      // Phase 6 — Notifications (edoc)
      'uq_device_token': 'Device token đã được đăng ký',
      'uq_notif_pref_staff_channel': 'Cấu hình kênh thông báo đã tồn tại',
    };
    const msg = messageMap[constraint] || 'Dữ liệu đã tồn tại, vui lòng kiểm tra lại';
    res.status(409).json({ success: false, message: msg });
    return;
  }

  // PostgreSQL foreign key violation (error code 23503)
  if (err?.code === '23503') {
    res.status(400).json({ success: false, message: 'Không thể thực hiện: dữ liệu đang được tham chiếu' });
    return;
  }

  // PostgreSQL not null violation (error code 23502)
  if (err?.code === '23502') {
    const column = err?.column || '';
    res.status(400).json({ success: false, message: `Trường "${column}" là bắt buộc` });
    return;
  }

  // Default — hide raw error in production
  const isDev = process.env.NODE_ENV !== 'production';
  res.status(500).json({
    success: false,
    message: isDev ? (err as Error).message : 'Có lỗi xảy ra, vui lòng thử lại sau',
  });
}
