-- ============================================
-- SEED DATA FOR DEMO — Phase 1-4
-- ============================================

-- 1. Lĩnh vực
INSERT INTO edoc.doc_fields (name, description, is_active, created_by) VALUES
  ('Hành chính', 'Văn bản hành chính', true, 1),
  ('Tài chính', 'Văn bản tài chính', true, 1),
  ('Nhân sự', 'Văn bản nhân sự', true, 1),
  ('CNTT', 'Công nghệ thông tin', true, 1)
ON CONFLICT DO NOTHING;

-- 2. Sổ VB đến
INSERT INTO edoc.doc_books (name, code, book_type, year, unit_id, is_active, created_by)
SELECT 'Sổ văn bản đến 2026', 'SVD-2026', 1, 2026, 1, true, 1
WHERE NOT EXISTS (SELECT 1 FROM edoc.doc_books WHERE code = 'SVD-2026');

-- 3. VĂN BẢN ĐẾN (20 records)
INSERT INTO edoc.incoming_docs (unit_id, received_date, number, notation, document_code, abstract, publish_unit, publish_date, signer, doc_book_id, doc_type_id, urgent_id, secret_id, created_by) VALUES
  (1, NOW() - interval '1 day', 101, 'CV-101/UBND', 'CV101', 'V/v triển khai Chính phủ điện tử giai đoạn 2026-2030', 'UBND Tỉnh', NOW() - interval '2 days', 'Nguyễn Văn A', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 1, 1, 1),
  (1, NOW() - interval '2 days', 102, 'QĐ-102/STC', 'QD102', 'Quyết định phê duyệt dự toán ngân sách năm 2026', 'Sở Tài chính', NOW() - interval '3 days', 'Trần Thị B', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 3, 2, 1, 1),
  (1, NOW() - interval '3 days', 103, 'CV-103/STTTT', 'CV103', 'V/v rà soát hạ tầng CNTT các cơ quan nhà nước', 'Sở TT&TT', NOW() - interval '4 days', 'Lê Văn C', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 1, 1, 1),
  (1, NOW() - interval '1 day', 104, 'CV-104/SNV', 'CV104', 'V/v tuyển dụng viên chức năm 2026', 'Sở Nội vụ', NOW() - interval '2 days', 'Phạm Thị D', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 1, 1, 1),
  (1, NOW() - interval '4 days', 105, 'NQ-105/HDND', 'NQ105', 'Nghị quyết về chương trình giám sát năm 2026', 'HĐND Tỉnh', NOW() - interval '5 days', 'Hoàng Văn E', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 2, 1, 1, 1),
  (1, NOW(), 106, 'CV-106/UBND', 'CV106', 'V/v tăng cường an toàn thông tin mạng', 'UBND Tỉnh', NOW() - interval '1 day', 'Nguyễn Văn A', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 2, 1, 1),
  (1, NOW(), 107, 'CT-107/TTg', 'CT107', 'Chỉ thị về đẩy mạnh chuyển đổi số quốc gia', 'Thủ tướng CP', NOW() - interval '1 day', 'Phạm Minh Chính', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 4, 3, 1, 1),
  (1, NOW() - interval '5 days', 108, 'CV-108/SYT', 'CV108', 'V/v phòng chống dịch bệnh mùa hè 2026', 'Sở Y tế', NOW() - interval '6 days', 'Bùi Thị F', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 1, 1, 1),
  (1, NOW() - interval '2 days', 109, 'QĐ-109/SGDDT', 'QD109', 'Quyết định thi tuyển giáo viên năm học 2026-2027', 'Sở GD&ĐT', NOW() - interval '3 days', 'Vũ Văn G', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 3, 1, 1, 1),
  (1, NOW() - interval '3 days', 110, 'CV-110/SKHDT', 'CV110', 'V/v lập kế hoạch đầu tư công trung hạn', 'Sở KH&ĐT', NOW() - interval '4 days', 'Đỗ Thị H', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 1, 1, 1),
  (1, NOW() - interval '1 day', 111, 'CV-111/VPUB', 'CV111', 'V/v chuẩn bị họp UBND tỉnh tháng 4/2026', 'VP UBND', NOW() - interval '1 day', 'Nguyễn Văn K', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 2, 1, 1),
  (1, NOW(), 112, 'CV-112/STP', 'CV112', 'V/v rà soát văn bản quy phạm pháp luật', 'Sở Tư pháp', NOW(), 'Trần Văn L', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 1, 1, 1),
  (1, NOW() - interval '6 days', 113, 'QC-113/UBND', 'QC113', 'Quy chế quản lý, sử dụng chứng thư số', 'UBND Tỉnh', NOW() - interval '7 days', 'Nguyễn Văn A', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 5, 1, 2, 1),
  (1, NOW() - interval '2 days', 114, 'CV-114/BCA', 'CV114', 'V/v phối hợp đảm bảo an ninh trật tự', 'Bộ Công an', NOW() - interval '3 days', 'Tô Lâm', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 3, 1, 1),
  (1, NOW() - interval '4 days', 115, 'CV-115/BTTTT', 'CV115', 'V/v triển khai nền tảng số quốc gia', 'Bộ TT&TT', NOW() - interval '5 days', 'Nguyễn Mạnh Hùng', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 2, 1, 1),
  (1, NOW() - interval '1 day', 116, 'CV-116/SNN', 'CV116', 'V/v phòng chống thiên tai mùa mưa bão 2026', 'Sở NN&PTNT', NOW() - interval '2 days', 'Lê Minh N', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 2, 1, 1),
  (1, NOW(), 117, 'CV-117/STNMT', 'CV117', 'V/v quản lý đất đai, bảo vệ môi trường', 'Sở TN&MT', NOW(), 'Phạm Thị O', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 1, 1, 1),
  (1, NOW() - interval '5 days', 118, 'QĐ-118/UBND', 'QD118', 'Quyết định thành lập Ban chỉ đạo CĐS', 'UBND Tỉnh', NOW() - interval '6 days', 'Nguyễn Văn A', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 3, 1, 1, 1),
  (1, NOW() - interval '3 days', 119, 'CV-119/SLDTBXH', 'CV119', 'V/v thực hiện chính sách BHXH, BHYT', 'Sở LĐ-TB&XH', NOW() - interval '4 days', 'Hoàng Thị P', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 1, 1, 1),
  (1, NOW() - interval '1 day', 120, 'CV-120/SVHTT', 'CV120', 'V/v tổ chức lễ hội văn hóa du lịch 2026', 'Sở VH-TT&DL', NOW() - interval '2 days', 'Ngô Văn Q', (SELECT id FROM edoc.doc_books WHERE code='SVD-2026' LIMIT 1), 1, 1, 1, 1);

-- 4. CẬP NHẬT TRẠNG THÁI HSCV
UPDATE edoc.handling_docs SET status = 1, progress = 30 WHERE id IN (4, 10, 15);
UPDATE edoc.handling_docs SET status = 2, progress = 60 WHERE id IN (5, 11);
UPDATE edoc.handling_docs SET status = 3, progress = 80 WHERE id IN (6, 12);
UPDATE edoc.handling_docs SET status = 4, progress = 100, complete_date = NOW(), complete_user_id = 1 WHERE id IN (7, 14);
UPDATE edoc.handling_docs SET status = -1 WHERE id = 8;
UPDATE edoc.handling_docs SET status = -2 WHERE id = 9;

-- 5. TIN NHẮN NỘI BỘ
INSERT INTO edoc.messages (from_staff_id, subject, content, created_at) VALUES
  (1, 'Họp giao ban tuần 15', 'Kính gửi các đồng chí, cuộc họp giao ban tuần 15 sẽ diễn ra vào 8h00 thứ Hai ngày 14/04/2026 tại phòng họp A.', NOW() - interval '2 hours'),
  (3, 'Báo cáo tiến độ dự án CĐS', 'Anh/chị cho em xin báo cáo tiến độ dự án Chuyển đổi số đến hết tuần 14.', NOW() - interval '1 day'),
  (1, 'Thông báo lịch nghỉ lễ 30/4-1/5', 'Thông báo đến toàn thể CBCC: Lịch nghỉ lễ từ 30/04 đến 01/05/2026.', NOW() - interval '3 days'),
  (3, 'Đề xuất nâng cấp hệ thống mạng', 'Kính gửi BGĐ, em xin đề xuất phương án nâng cấp hạ tầng mạng nội bộ.', NOW() - interval '2 days'),
  (1, 'Phân công nhiệm vụ Sprint 5', 'Phân công chi tiết nhiệm vụ Sprint 5 - Module HSCV cho từng thành viên.', NOW() - interval '4 days'),
  (1, 'Yêu cầu cập nhật thông tin cá nhân', 'Đề nghị toàn bộ CBCC cập nhật SĐT, email trên hệ thống trước 20/04/2026.', NOW() - interval '1 day'),
  (3, 'Góp ý giao diện hệ thống mới', 'Em có góp ý về giao diện dashboard và sidebar của e-Office mới.', NOW() - interval '5 hours'),
  (1, 'Lịch đào tạo sử dụng hệ thống', 'Lịch đào tạo e-Office: Buổi 1: 16/04, Buổi 2: 17/04.', NOW() - interval '6 hours'),
  (3, 'Báo lỗi chức năng tìm kiếm VB', 'Anh ơi, em phát hiện lỗi tìm kiếm VB đến với từ khóa tiếng Việt có dấu.', NOW() - interval '3 hours'),
  (1, 'Kế hoạch demo cuối tuần', 'Kế hoạch demo e-Office cho BLĐ ngày 18-19/04/2026.', NOW());

INSERT INTO edoc.message_recipients (message_id, staff_id, is_read)
SELECT m.id, CASE WHEN m.from_staff_id = 1 THEN 3 ELSE 1 END, false
FROM edoc.messages m;

UPDATE edoc.message_recipients SET is_read = true, read_at = NOW()
WHERE message_id IN (SELECT id FROM edoc.messages ORDER BY id LIMIT 5);

-- 6. THÔNG BÁO
INSERT INTO edoc.notices (unit_id, title, content, notice_type, created_by, created_at) VALUES
  (1, 'Hệ thống e-Office chính thức hoạt động', 'Hệ thống QLVB e-Office triển khai từ 14/04/2026.', 'system', 1, NOW() - interval '7 days'),
  (1, 'Bảo trì hệ thống ngày 15/04', 'Hệ thống tạm ngưng 22h-23h ngày 15/04 để bảo trì.', 'maintenance', 1, NOW() - interval '1 day'),
  (1, 'Cập nhật phiên bản v1.2', 'Tính năng mới: HSCV, Tin nhắn, Lịch làm việc.', 'update', 1, NOW() - interval '2 hours'),
  (1, 'Hướng dẫn module Hồ sơ công việc', 'Tài liệu HSCV đã cập nhật tại mục Tài liệu.', 'guide', 1, NOW() - interval '3 days'),
  (1, 'Nhắc nhở đổi mật khẩu định kỳ', 'Đề nghị CBCC đổi mật khẩu 3 tháng/lần.', 'security', 1, NOW() - interval '5 days'),
  (1, 'Lịch họp trực tuyến toàn tỉnh', 'Họp CĐS lúc 14h ngày 16/04/2026.', 'meeting', 1, NOW() - interval '4 hours'),
  (1, 'Kết quả CĐS quý I/2026', 'Kết quả đánh giá CĐS đã công bố.', 'report', 1, NOW() - interval '6 days'),
  (1, 'Demo cho Ban lãnh đạo 18-19/04', 'Các phòng ban chuẩn bị dữ liệu demo.', 'important', 1, NOW());

-- 7. LỊCH
INSERT INTO public.calendar_events (staff_id, unit_id, scope, title, description, start_time, end_time, location, color, created_by) VALUES
  (1, 1, 'personal', 'Họp giao ban đầu tuần', 'Họp giao ban tuần 15', NOW()::date + interval '8 hours', NOW()::date + interval '9 hours', 'Phòng họp A', '#1B3A5C', 1),
  (1, 1, 'personal', 'Review code Sprint 5', 'Review module HSCV', NOW()::date + interval '14 hours', NOW()::date + interval '16 hours', 'Phòng CNTT', '#0891B2', 1),
  (1, 1, 'personal', 'Họp triển khai CĐS', 'Ban chỉ đạo CĐS tỉnh', (NOW() + interval '1 day')::date + interval '9 hours', (NOW() + interval '1 day')::date + interval '11 hours', 'Phòng họp lớn', '#D97706', 1),
  (1, 1, 'personal', 'Đào tạo e-Office buổi 1', 'Đào tạo CBCC sử dụng', (NOW() + interval '2 days')::date + interval '8 hours', (NOW() + interval '2 days')::date + interval '11 hours', 'Hội trường', '#059669', 1),
  (1, 1, 'personal', 'Demo cho BLĐ', 'Demo hệ thống e-Office', (NOW() + interval '4 days')::date + interval '14 hours', (NOW() + interval '4 days')::date + interval '16 hours', 'Phòng VIP', '#DC2626', 1),
  (1, 1, 'personal', 'Kế hoạch Q2/2026', 'Lập kế hoạch quý II', (NOW() + interval '3 days')::date + interval '9 hours', (NOW() + interval '3 days')::date + interval '11 hours', 'Phòng họp B', '#1B3A5C', 1),
  (1, 1, 'unit', 'Họp UBND tỉnh tháng 4', 'Phiên họp thường kỳ', (NOW() + interval '1 day')::date + interval '8 hours', (NOW() + interval '1 day')::date + interval '11 hours', 'Hội trường UBND', '#1B3A5C', 1),
  (1, 1, 'unit', 'Lễ chào cờ đầu tháng 5', 'Sinh hoạt chính trị', (NOW() + interval '16 days')::date + interval '7 hours', (NOW() + interval '16 days')::date + interval '8 hours', 'Sân UBND', '#D97706', 1),
  (1, 1, 'leader', 'Tiếp công dân định kỳ', 'Chủ tịch tiếp dân tháng 4', (NOW() + interval '2 days')::date + interval '8 hours', (NOW() + interval '2 days')::date + interval '11 hours', 'Phòng tiếp dân', '#DC2626', 1),
  (1, 1, 'leader', 'Kiểm tra dự án huyện', 'Kiểm tra đường giao thông', (NOW() + interval '5 days')::date + interval '8 hours', (NOW() + interval '5 days')::date + interval '17 hours', 'Huyện Sa Pa', '#D97706', 1);

-- 8. VĂN BẢN LIÊN THÔNG
INSERT INTO edoc.inter_incoming_docs (unit_id, received_date, notation, document_code, abstract, publish_unit, publish_date, signer, doc_type_id, status, created_by) VALUES
  (1, NOW() - interval '1 day', 'LT-001/VPCP', 'LT001', 'V/v triển khai Đề án 06 về CSDL quốc gia dân cư', 'Văn phòng Chính phủ', NOW() - interval '2 days', 'Trần Văn Sơn', 1, 0, 1),
  (1, NOW() - interval '2 days', 'LT-002/BNV', 'LT002', 'V/v cải cách TTHC và ứng dụng CNTT', 'Bộ Nội vụ', NOW() - interval '3 days', 'Phạm Thị Thanh Trà', 1, 0, 1),
  (1, NOW() - interval '3 days', 'LT-003/BTTTT', 'LT003', 'V/v triển khai nền tảng LGSP', 'Bộ TT&TT', NOW() - interval '4 days', 'Nguyễn Mạnh Hùng', 1, 1, 1),
  (1, NOW() - interval '5 days', 'LT-004/BTC', 'LT004', 'V/v quản lý ngân sách qua hệ thống điện tử', 'Bộ Tài chính', NOW() - interval '6 days', 'Hồ Đức Phước', 1, 1, 1),
  (1, NOW(), 'LT-005/VPUB-LC', 'LT005', 'V/v phối hợp xử lý VB liên thông Tây Bắc', 'VP UBND Lai Châu', NOW() - interval '1 day', 'Trần Tiến Dũng', 1, 0, 1);

-- Verify counts
SELECT 'VB_DEN: ' || count(*) FROM edoc.incoming_docs;
SELECT 'VB_DI: ' || count(*) FROM edoc.outgoing_docs;
SELECT 'HSCV: ' || count(*) FROM edoc.handling_docs;
SELECT 'MESSAGES: ' || count(*) FROM edoc.messages;
SELECT 'NOTICES: ' || count(*) FROM edoc.notices;
SELECT 'CALENDAR: ' || count(*) FROM public.calendar_events;
SELECT 'INTER_INCOMING: ' || count(*) FROM edoc.inter_incoming_docs;
SELECT '=== SEED COMPLETE ===' as result;
