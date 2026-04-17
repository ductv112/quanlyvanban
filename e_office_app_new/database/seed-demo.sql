-- ================================================================
-- SEED DATA: Dữ liệu demo cho e-Office
-- Chạy sau 000_full_schema.sql trên database trống
-- Cách dùng:
--   psql -U qlvb_admin -d qlvb_prod -f seed-demo.sql
-- ================================================================

-- Xóa dữ liệu cũ (nếu có) theo thứ tự FK
TRUNCATE TABLE
  esto.borrow_request_records,
  esto.borrow_requests,
  esto.document_archives,
  esto.records,
  esto.fonds,
  esto.warehouses,
  cont.contracts,
  cont.contract_types,
  iso.documents,
  iso.doc_categories,
  edoc.room_schedule_votes,
  edoc.room_schedule_answers,
  edoc.room_schedule_questions,
  edoc.room_schedule_staff,
  edoc.room_schedules,
  edoc.rooms,
  edoc.meeting_types,
  edoc.lgsp_tracking,
  edoc.notice_reads,
  edoc.notices,
  edoc.message_recipients,
  edoc.messages,
  edoc.notification_preferences,
  edoc.notification_logs,
  edoc.device_tokens,
  edoc.digital_signatures,
  edoc.send_doc_user_configs,
  edoc.opinion_handling_docs,
  edoc.attachment_handling_docs,
  edoc.staff_handling_docs,
  edoc.handling_doc_links,
  edoc.handling_docs,
  edoc.user_drafting_docs,
  edoc.attachment_drafting_docs,
  edoc.drafting_docs,
  edoc.user_outgoing_docs,
  edoc.attachment_outgoing_docs,
  edoc.outgoing_docs,
  edoc.staff_notes,
  edoc.leader_notes,
  edoc.attachment_incoming_docs,
  edoc.user_incoming_docs,
  edoc.incoming_docs,
  edoc.delegations,
  edoc.work_group_members,
  edoc.work_groups,
  edoc.signers,
  edoc.organizations,
  edoc.doc_columns,
  edoc.doc_fields,
  edoc.doc_types,
  edoc.doc_books,
  edoc.doc_flows,
  public.calendar_events,
  public.work_calendar,
  public.login_history,
  public.refresh_tokens,
  public.role_of_staff,
  public.action_of_role,
  public.rights,
  public.roles,
  public.staff,
  public.departments,
  public.positions,
  public.configurations
CASCADE;

-- Dumped from database version 16.13

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: contract_types; Type: TABLE DATA; Schema: cont; Owner: -
--

SET SESSION AUTHORIZATION DEFAULT;

ALTER TABLE cont.contract_types DISABLE TRIGGER ALL;

INSERT INTO cont.contract_types VALUES (1, 1, 0, 'CNTT', 'Hợp đồng CNTT', NULL, 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO cont.contract_types VALUES (2, 1, 0, 'XD', 'Hợp đồng xây dựng', NULL, 2, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO cont.contract_types VALUES (3, 1, 0, 'MUA', 'Hợp đồng mua sắm', NULL, 3, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO cont.contract_types VALUES (4, 1, 0, 'DV', 'Hợp đồng dịch vụ', NULL, 4, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);


ALTER TABLE cont.contract_types ENABLE TRIGGER ALL;

--
-- Data for Name: contracts; Type: TABLE DATA; Schema: cont; Owner: -
--

ALTER TABLE cont.contracts DISABLE TRIGGER ALL;

INSERT INTO cont.contracts VALUES (1, NULL, 1, 8, 0, NULL, NULL, 1, 'HD-CNTT-2026-001', '2026-01-15', '2026-01-16', NULL, 'Hợp đồng triển khai hệ thống e-Office v2.0', 'Quản trị Hệ thống', 1, NULL, NULL, 'Bùi Thị Hương', 'VND', NULL, 8, 'Hợp đồng với đơn vị phát triển phần mềm', 1, '2.500.000.000', NULL, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO cont.contracts VALUES (2, NULL, 1, 8, 0, NULL, NULL, 1, 'HD-CNTT-2026-002', '2026-02-01', '2026-02-02', NULL, 'Hợp đồng bảo trì hạ tầng mạng UBND tỉnh năm 2026', 'Lê Văn Đức', 2, NULL, NULL, 'Bùi Thị Hương', 'VND', NULL, 8, 'Bảo trì hệ thống mạng, máy chủ, thiết bị CNTT', 1, '800.000.000', NULL, 4, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO cont.contracts VALUES (3, NULL, 3, 9, 0, NULL, NULL, 1, 'HD-MUA-2026-001', '2026-03-10', '2026-03-11', NULL, 'Hợp đồng mua sắm máy tính và thiết bị văn phòng', 'Phạm Văn Em', 1, NULL, NULL, 'Vũ Thị Kim', 'VND', NULL, 9, 'Mua 50 bộ máy tính, 10 máy in cho các phòng ban', 2, '1.200.000.000', NULL, 5, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO cont.contracts VALUES (4, NULL, 4, 5, 0, NULL, NULL, 1, 'HD-DV-2026-001', '2026-04-01', '2026-04-02', NULL, 'Hợp đồng dịch vụ vệ sinh trụ sở UBND tỉnh năm 2026', 'Phạm Văn Em', 1, NULL, NULL, 'Vũ Thị Kim', 'VND', NULL, 9, 'Dịch vụ vệ sinh hàng ngày cho trụ sở UBND', 0, '360.000.000', NULL, 5, '2026-04-17 12:09:34.966774+00', NULL, NULL);


ALTER TABLE cont.contracts ENABLE TRIGGER ALL;

--
-- Data for Name: contract_attachments; Type: TABLE DATA; Schema: cont; Owner: -
--

ALTER TABLE cont.contract_attachments DISABLE TRIGGER ALL;



ALTER TABLE cont.contract_attachments ENABLE TRIGGER ALL;

--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.departments DISABLE TRIGGER ALL;

INSERT INTO public.departments VALUES (1, NULL, 'UBND', 'UBND tỉnh Lào Cai', NULL, 'UBND', NULL, true, 0, 1, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, false, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.departments VALUES (2, 1, 'SNV', 'Sở Nội vụ', NULL, 'SNV', NULL, true, 1, 2, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.departments VALUES (3, 1, 'STC', 'Sở Tài chính', NULL, 'STC', NULL, true, 1, 3, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.departments VALUES (4, 1, 'STTTT', 'Sở Thông tin và Truyền thông', NULL, 'STTTT', NULL, true, 1, 4, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.departments VALUES (5, 1, 'VPUBND', 'Văn phòng UBND tỉnh', NULL, 'VP', NULL, true, 1, 5, true, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.departments VALUES (6, 2, 'TCHC', 'Phòng Tổ chức - Hành chính', NULL, 'TCHC', NULL, false, 2, 1, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.departments VALUES (7, 3, 'QLNS', 'Phòng Quản lý Ngân sách', NULL, 'QLNS', NULL, false, 2, 1, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.departments VALUES (8, 4, 'CNTT', 'Phòng Công nghệ thông tin', NULL, 'CNTT', NULL, false, 2, 1, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.departments VALUES (9, 5, 'TH', 'Phòng Tổng hợp', NULL, 'TH', NULL, false, 2, 1, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.departments VALUES (10, 2, 'CCVC', 'Phòng Công chức - Viên chức', NULL, 'CCVC', NULL, false, 2, 2, false, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, false, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');


ALTER TABLE public.departments ENABLE TRIGGER ALL;

--
-- Data for Name: doc_books; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.doc_books DISABLE TRIGGER ALL;

INSERT INTO edoc.doc_books VALUES (1, 1, 1, 'Sổ văn bản đến 2026', NULL, 1, true, false, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.doc_books VALUES (2, 1, 2, 'Sổ văn bản đi 2026', NULL, 2, true, false, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.doc_books VALUES (3, 1, 3, 'Sổ dự thảo 2026', NULL, 3, true, false, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.doc_books VALUES (4, 2, 1, 'Sổ VB đến - Sở Nội vụ', NULL, 1, true, false, 2, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.doc_books VALUES (5, 3, 1, 'Sổ VB đến - Sở Tài chính', NULL, 1, true, false, 3, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.doc_books ENABLE TRIGGER ALL;

--
-- Data for Name: doc_fields; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.doc_fields DISABLE TRIGGER ALL;

INSERT INTO edoc.doc_fields VALUES (1, 1, 'HC', 'Hành chính', 1, true, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.doc_fields VALUES (2, 1, 'TC', 'Tài chính', 2, true, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.doc_fields VALUES (3, 1, 'NS', 'Nhân sự', 3, true, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.doc_fields VALUES (4, 1, 'CNTT', 'Công nghệ thông tin', 4, true, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.doc_fields VALUES (5, 1, 'XDCB', 'Xây dựng cơ bản', 5, true, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.doc_fields ENABLE TRIGGER ALL;

--
-- Data for Name: doc_types; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.doc_types DISABLE TRIGGER ALL;

INSERT INTO edoc.doc_types VALUES (1, 2, 'CV', 'Công văn', NULL, 1, 0, false, false, NULL, '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.doc_types VALUES (2, 1, 'NQ', 'Nghị quyết', NULL, 2, 0, false, false, NULL, '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.doc_types VALUES (3, 1, 'QD', 'Quyết định', NULL, 3, 0, false, false, NULL, '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.doc_types VALUES (4, 1, 'CT', 'Chỉ thị', NULL, 4, 0, false, false, NULL, '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.doc_types VALUES (5, 1, 'QC', 'Quy chế', NULL, 5, 0, false, false, NULL, '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.doc_types VALUES (6, 2, 'TB', 'Thông báo', NULL, 6, 0, false, false, NULL, '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.doc_types VALUES (7, 2, 'BC', 'Báo cáo', NULL, 7, 0, false, false, NULL, '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.doc_types VALUES (8, 2, 'TTr', 'Tờ trình', NULL, 8, 0, false, false, NULL, '2026-04-17 12:09:34.966774+00', NULL);


ALTER TABLE edoc.doc_types ENABLE TRIGGER ALL;

--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.positions DISABLE TRIGGER ALL;

INSERT INTO public.positions VALUES (1, 'Giám đốc', 'GD', 1, true, NULL, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00', false, false);
INSERT INTO public.positions VALUES (2, 'Phó Giám đốc', 'PGD', 2, true, NULL, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00', false, false);
INSERT INTO public.positions VALUES (3, 'Trưởng phòng', 'TP', 3, true, NULL, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00', false, false);
INSERT INTO public.positions VALUES (4, 'Phó Trưởng phòng', 'PTP', 4, true, NULL, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00', false, false);
INSERT INTO public.positions VALUES (5, 'Chuyên viên', 'CV', 5, true, NULL, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00', false, false);
INSERT INTO public.positions VALUES (6, 'Văn thư', 'VT', 6, true, NULL, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00', false, false);


ALTER TABLE public.positions ENABLE TRIGGER ALL;

--
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.staff DISABLE TRIGGER ALL;

INSERT INTO public.staff VALUES (3, 3, 3, 1, 'tranthib', '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Trần Thị', 'Bình', DEFAULT, 2, NULL, 'tranthib@stc.laocai.gov.vn', '02093801003', '0912000003', NULL, NULL, NULL, NULL, NULL, NULL, false, false, false, false, NULL, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00', 'NV003', false, NULL, NULL, NULL);
INSERT INTO public.staff VALUES (7, 7, 3, 5, 'dangvang', '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Đặng Văn', 'Giang', DEFAULT, 1, NULL, 'dangvang@stc.laocai.gov.vn', '02093801007', '0912000007', NULL, NULL, NULL, NULL, NULL, NULL, false, false, false, false, NULL, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00', 'NV007', false, NULL, NULL, NULL);
INSERT INTO public.staff VALUES (8, 8, 4, 5, 'buithih', '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Bùi Thị', 'Hương', DEFAULT, 2, NULL, 'buithih@stttt.laocai.gov.vn', '02093801008', '0912000008', NULL, NULL, NULL, NULL, NULL, NULL, false, false, false, false, NULL, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00', 'NV008', false, NULL, NULL, NULL);
INSERT INTO public.staff VALUES (9, 9, 5, 6, 'vuthik', '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Vũ Thị', 'Kim', DEFAULT, 2, NULL, 'vuthik@vpubnd.laocai.gov.vn', '02093801009', '0912000009', NULL, NULL, NULL, NULL, NULL, NULL, false, false, false, false, NULL, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00', 'NV009', false, NULL, NULL, NULL);
INSERT INTO public.staff VALUES (10, 10, 2, 4, 'dothil', '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Đỗ Thị', 'Lan', DEFAULT, 2, NULL, 'dothil@snv.laocai.gov.vn', '02093801010', '0912000010', NULL, NULL, NULL, NULL, NULL, NULL, false, false, false, false, NULL, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00', 'NV010', false, NULL, NULL, NULL);
INSERT INTO public.staff VALUES (1, 1, 1, 1, 'admin', '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', true, 'Quản trị', 'Hệ thống', DEFAULT, 1, NULL, 'admin@laocai.gov.vn', '02093801001', '0912000001', NULL, NULL, NULL, NULL, NULL, NULL, false, false, false, false, '2026-04-17 17:04:32.792886+00', NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 17:04:32.792886+00', 'NV001', false, NULL, NULL, NULL);
INSERT INTO public.staff VALUES (2, 2, 2, 1, 'nguyenvana', '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Nguyễn Văn', 'An', DEFAULT, 1, NULL, 'nguyenvana@snv.laocai.gov.vn', '02093801002', '0912000002', NULL, NULL, NULL, NULL, NULL, NULL, false, false, false, false, '2026-04-17 14:02:51.18476+00', NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 14:02:51.18476+00', 'NV002', false, NULL, NULL, NULL);
INSERT INTO public.staff VALUES (5, 5, 5, 3, 'phamvane', '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Phạm Văn', 'Em', DEFAULT, 1, NULL, 'phamvane@vpubnd.laocai.gov.vn', '02093801005', '0912000005', NULL, NULL, NULL, NULL, NULL, NULL, false, false, false, false, '2026-04-17 14:02:51.328656+00', NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 14:02:51.328656+00', 'NV005', false, NULL, NULL, NULL);
INSERT INTO public.staff VALUES (6, 6, 2, 5, 'hoangthif', '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Hoàng Thị', 'Phương', DEFAULT, 2, NULL, 'hoangthif@snv.laocai.gov.vn', '02093801006', '0912000006', NULL, NULL, NULL, NULL, NULL, NULL, false, false, false, false, '2026-04-17 14:02:51.481613+00', NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 14:02:51.481613+00', 'NV006', false, NULL, NULL, NULL);
INSERT INTO public.staff VALUES (4, 4, 4, 1, 'levand', '$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi', false, 'Lê Văn', 'Đức', DEFAULT, 1, NULL, 'levand@stttt.laocai.gov.vn', '02093801004', '0912000004', NULL, NULL, NULL, NULL, NULL, NULL, false, false, false, false, '2026-04-17 14:02:51.625175+00', NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 14:02:51.625175+00', 'NV004', false, NULL, NULL, NULL);


ALTER TABLE public.staff ENABLE TRIGGER ALL;

--
-- Data for Name: drafting_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.drafting_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.drafting_docs VALUES (1, 1, '2026-04-12 12:09:34.966774+00', 1, NULL, 'DT-01/UBND', 'Dự thảo Quyết định ban hành Quy chế quản lý tài liệu điện tử', 1, 5, NULL, NULL, 'Quản trị Hệ thống', NULL, 1, 1, 1, 1, 'Các Sở, ngành, UBND huyện/TX', 3, 3, 1, true, true, NULL, 5, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', NULL, NULL, NULL, NULL, '{}', 5, NULL, NULL);
INSERT INTO edoc.drafting_docs VALUES (2, 1, '2026-04-14 12:09:34.966774+00', 2, NULL, 'DT-02/UBND', 'Dự thảo Công văn triển khai ứng dụng chữ ký số trong cơ quan nhà nước', 4, 8, NULL, NULL, 'Lê Văn Đức', NULL, 1, 1, 1, 2, 'Các Sở TT&TT, Sở Nội vụ', 3, 1, 4, true, true, NULL, 8, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', NULL, NULL, NULL, NULL, '{}', 8, NULL, NULL);
INSERT INTO edoc.drafting_docs VALUES (3, 1, '2026-04-16 12:09:34.966774+00', 3, NULL, 'DT-03/UBND', 'Dự thảo Báo cáo tình hình ứng dụng CNTT quý I/2026', 4, 4, NULL, NULL, 'Lê Văn Đức', NULL, 1, 1, 1, 1, 'UBND tỉnh, Bộ TT&TT', 3, 7, 4, false, false, NULL, 4, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', NULL, NULL, NULL, NULL, '{}', 4, NULL, NULL);
INSERT INTO edoc.drafting_docs VALUES (4, 2, '2026-04-15 12:09:34.966774+00', 1, NULL, 'DT-01/SNV', 'Dự thảo Kế hoạch tuyển dụng viên chức sự nghiệp GD năm 2026', 2, 6, NULL, NULL, 'Nguyễn Văn An', NULL, 1, 1, 1, 1, 'Sở GD&ĐT, UBND các huyện/TX', 3, 1, 3, false, false, NULL, 6, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', NULL, NULL, NULL, 'Cần bổ sung thêm chỉ tiêu tuyển dụng từ các đơn vị sự nghiệp', '{}', 6, NULL, NULL);
INSERT INTO edoc.drafting_docs VALUES (5, 1, '2026-04-17 15:37:21.1+00', 4, NULL, 'tt', 'ttttt', 1, 1, NULL, '2026-04-17 15:37:37.8+00', 'ttt', '2026-04-17 15:37:36.4+00', 1, 1, 1, 1, 'ttt', 3, 3, 4, true, true, '2026-04-17 15:38:23.669189+00', 1, '2026-04-17 15:37:48.000687+00', 1, '2026-04-17 15:38:23.669189+00', 'Quản trị Hệ thống', '2026-04-17 15:37:39.4+00', 'tt', NULL, '{}', 1, NULL, NULL);


ALTER TABLE edoc.drafting_docs ENABLE TRIGGER ALL;

--
-- Data for Name: attachment_drafting_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.attachment_drafting_docs DISABLE TRIGGER ALL;



ALTER TABLE edoc.attachment_drafting_docs ENABLE TRIGGER ALL;

--
-- Data for Name: handling_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.handling_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.handling_docs VALUES (6, 2, 6, 'Chuẩn bị phương án tuyển dụng Sở Nội vụ', 'Phương án tuyển dụng năm 2026 theo CV-201/BNV', NULL, NULL, 1, 3, NULL, '2026-04-15 12:09:34.966774+00', '2026-05-07 12:09:34.966774+00', NULL, 6, 2, 1, 0, NULL, 40, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, 2, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.handling_docs VALUES (1, 1, 1, 'Triển khai Chính phủ điện tử 2026-2030', 'Xử lý CV-101/UBND về triển khai CPĐT', NULL, NULL, 1, 4, NULL, '2026-04-16 12:09:34.966774+00', '2026-05-17 12:09:34.966774+00', NULL, 4, 1, 1, 0, NULL, 30, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:52:38.890685+00');
INSERT INTO edoc.handling_docs VALUES (2, 1, 1, 'Phê duyệt dự toán ngân sách 2026', 'Xử lý QĐ-102/STC về dự toán ngân sách', NULL, NULL, 3, 2, NULL, '2026-04-15 12:09:34.966774+00', '2026-05-02 12:09:34.966774+00', NULL, 3, 1, 2, 0, NULL, 60, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:52:38.890685+00');
INSERT INTO edoc.handling_docs VALUES (3, 1, 5, 'Tuyển dụng viên chức năm 2026', 'Xử lý CV-104/SNV về tuyển dụng viên chức', NULL, NULL, 1, 3, NULL, '2026-04-16 12:09:34.966774+00', '2026-06-01 12:09:34.966774+00', NULL, 2, 1, 1, 0, NULL, 20, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, 5, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:52:38.890685+00');
INSERT INTO edoc.handling_docs VALUES (4, 1, 1, 'Chuyển đổi số quốc gia — triển khai tại tỉnh', 'Xử lý CT-106/TTg về CĐS quốc gia', NULL, NULL, 4, 4, NULL, '2026-04-17 12:09:34.966774+00', '2026-06-16 12:09:34.966774+00', NULL, 4, 1, 0, 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:52:38.890685+00');
INSERT INTO edoc.handling_docs VALUES (5, 1, 4, 'Soạn thảo báo cáo ứng dụng CNTT quý I/2026', 'Lập báo cáo tình hình ứng dụng CNTT', NULL, NULL, 7, 4, NULL, '2026-04-12 12:09:34.966774+00', '2026-04-27 12:09:34.966774+00', NULL, 4, 1, 4, 0, NULL, 100, NULL, NULL, 4, '2026-04-16 12:09:34.966774+00', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, false, 4, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:52:38.890685+00');
INSERT INTO edoc.handling_docs VALUES (7, 1, NULL, 'Test CRUD VB den', NULL, 'ttt', NULL, NULL, NULL, NULL, '2026-04-17 00:00:00+00', '2026-04-17 00:00:00+00', NULL, 2, NULL, 0, 0, NULL, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, true, 1, '2026-04-17 14:31:56.992542+00', NULL, '2026-04-17 14:31:56.992542+00');


ALTER TABLE edoc.handling_docs ENABLE TRIGGER ALL;

--
-- Data for Name: attachment_handling_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.attachment_handling_docs DISABLE TRIGGER ALL;



ALTER TABLE edoc.attachment_handling_docs ENABLE TRIGGER ALL;

--
-- Data for Name: incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.incoming_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.incoming_docs VALUES (3, 1, '2026-04-14 12:09:34.966774+00', 103, 'CV-103/STTTT', 'CV103', 'V/v rà soát hạ tầng CNTT các cơ quan nhà nước', 'Sở TT&TT', '2026-04-13 12:09:34.966774+00', 'Lê Văn Đức', NULL, 1, 1, 4, 1, 1, 2, 1, NULL, NULL, NULL, false, false, false, false, false, NULL, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', 'Phòng CNTT', NULL, '{}', 1, NULL, NULL);
INSERT INTO edoc.incoming_docs VALUES (5, 1, '2026-04-13 12:09:34.966774+00', 105, 'NQ-105/HDND', 'NQ105', 'Nghị quyết về chương trình giám sát năm 2026', 'HĐND tỉnh Lào Cai', '2026-04-12 12:09:34.966774+00', 'Hoàng Văn Dũng', NULL, 1, 2, 1, 1, 1, 8, 2, NULL, NULL, NULL, false, false, false, false, false, NULL, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', 'UBND tỉnh Lào Cai', NULL, '{}', 1, NULL, NULL);
INSERT INTO edoc.incoming_docs VALUES (7, 2, '2026-04-15 12:09:34.966774+00', 201, 'CV-201/BNV', 'CV201', 'V/v hướng dẫn thi nâng ngạch công chức năm 2026', 'Bộ Nội vụ', '2026-04-14 12:09:34.966774+00', 'Phạm Thị Thanh Trà', NULL, 4, 1, 3, 1, 2, 10, 2, NULL, NULL, NULL, false, false, false, false, false, NULL, 2, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', 'Phòng HC-QT', NULL, '{}', 2, NULL, NULL);
INSERT INTO edoc.incoming_docs VALUES (1, 1, '2026-04-16 12:09:34.966774+00', 101, 'CV-101/UBND', 'CV101', 'V/v triển khai Chính phủ điện tử giai đoạn 2026-2030', 'Văn phòng Chính phủ', '2026-04-15 12:09:34.966774+00', 'Trần Văn Sơn', NULL, 1, 1, 4, 1, 1, 5, 1, NULL, NULL, NULL, false, true, false, false, false, NULL, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', 'UBND tỉnh Lào Cai', NULL, '{}', 1, NULL, NULL);
INSERT INTO edoc.incoming_docs VALUES (2, 1, '2026-04-15 12:09:34.966774+00', 102, 'QD-102/STC', 'QD102', 'Quyết định phê duyệt dự toán ngân sách năm 2026', 'Sở Tài chính', '2026-04-14 12:09:34.966774+00', 'Trần Thị Bình', NULL, 1, 3, 2, 1, 2, 3, 2, NULL, NULL, NULL, false, true, false, false, false, NULL, 1, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', 'Phòng Kế hoạch - Tài chính', NULL, '{}', 1, NULL, NULL);
INSERT INTO edoc.incoming_docs VALUES (4, 1, '2026-04-16 12:09:34.966774+00', 104, 'CV-104/SNV', 'CV104', 'V/v tuyển dụng viên chức năm 2026', 'Sở Nội vụ', '2026-04-15 12:09:34.966774+00', 'Nguyễn Văn An', NULL, 1, 1, 3, 1, 1, 4, 1, NULL, NULL, NULL, false, true, false, false, false, NULL, 5, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', 'Phòng Tổ chức cán bộ', NULL, '{}', 5, NULL, NULL);
INSERT INTO edoc.incoming_docs VALUES (6, 1, '2026-04-17 12:09:34.966774+00', 106, 'CT-106/TTg', 'CT106', 'Chỉ thị về đẩy mạnh chuyển đổi số quốc gia', 'Thủ tướng Chính phủ', '2026-04-16 12:09:34.966774+00', 'Phạm Minh Chính', NULL, 1, 4, 4, 1, 3, 6, 3, NULL, NULL, 'Quản trị Hệ thống', true, false, false, true, false, NULL, 1, '2026-04-17 12:09:34.966774+00', 1, '2026-04-17 15:05:50.150041+00', 'Văn phòng UBND tỉnh', NULL, '{}', 1, NULL, NULL);
INSERT INTO edoc.incoming_docs VALUES (8, 1, '2026-04-17 14:03:28.592+00', 107, 'tttttttt', 't', 'Test CRUD VB den', 'tttt', '2026-04-17 14:30:50.3+00', 't', '2026-04-17 14:30:47.5+00', 1, 1, 1, 1, 1, 1, 1, '2026-04-17 14:30:51.8+00', 't', 'Quản trị Hệ thống', true, false, false, true, false, NULL, 1, '2026-04-17 14:03:28.592696+00', 1, '2026-04-17 15:27:21.740343+00', 't', NULL, '{}', 1, NULL, NULL);


ALTER TABLE edoc.incoming_docs ENABLE TRIGGER ALL;

--
-- Data for Name: attachment_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.attachment_incoming_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.attachment_incoming_docs VALUES (1, 4, 'quy_uoc_chung.md', 'incoming/4/08645e01-80f0-413c-8038-bfab7cf12f1d.md', 13550, 'application/octet-stream', 0, 1, '2026-04-17 17:08:50.929598+00', NULL, true, '2026-04-17 17:08:58.673383+00', 'incoming/4/08645e01-80f0-413c-8038-bfab7cf12f1d.md');


ALTER TABLE edoc.attachment_incoming_docs ENABLE TRIGGER ALL;

--
-- Data for Name: inter_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.inter_incoming_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.inter_incoming_docs VALUES (1, 1, '2026-04-16 12:09:34.966774', 'LT-001/VPCP', 'LT001', 'V/v triển khai Đề án 06 về CSDL quốc gia dân cư', 'Văn phòng Chính phủ', '2026-04-15', 'Trần Văn Sơn', NULL, NULL, 1, 'pending', 'LGSP-TW', 'VPCP-2026-001', 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', NULL, NULL, 1, 1, 1, 1, NULL, NULL, 1);
INSERT INTO edoc.inter_incoming_docs VALUES (2, 1, '2026-04-14 12:09:34.966774', 'LT-002/BTTTT', 'LT002', 'V/v triển khai nền tảng LGSP tỉnh', 'Bộ TT&TT', '2026-04-13', 'Nguyễn Mạnh Hùng', NULL, NULL, 1, 'received', 'LGSP-TW', 'BTTTT-2026-015', 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', NULL, NULL, 1, 1, 1, 1, NULL, NULL, 1);
INSERT INTO edoc.inter_incoming_docs VALUES (3, 1, '2026-04-17 12:09:34.966774', 'LT-003/UBND-YB', 'LT003', 'V/v phối hợp xử lý văn bản liên thông Tây Bắc', 'UBND tỉnh Yên Bái', '2026-04-16', 'Trần Huy Tuấn', NULL, NULL, 1, 'pending', 'LGSP-YB', 'YB-2026-042', 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', NULL, NULL, 1, 1, 1, 1, NULL, NULL, 1);


ALTER TABLE edoc.inter_incoming_docs ENABLE TRIGGER ALL;

--
-- Data for Name: attachment_inter_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.attachment_inter_incoming_docs DISABLE TRIGGER ALL;



ALTER TABLE edoc.attachment_inter_incoming_docs ENABLE TRIGGER ALL;

--
-- Data for Name: outgoing_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.outgoing_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.outgoing_docs VALUES (3, 1, '2026-04-16 12:09:34.966774+00', 203, NULL, 'CV-203/UBND', 'CV203', 'Công văn về việc tăng cường an toàn thông tin mạng cơ quan nhà nước', 4, 4, 1, '2026-04-16 12:09:34.966774+00', 'Lê Văn Đức', '2026-04-16 12:09:34.966774+00', NULL, 1, 1, 1, 2, 'Các Sở, Ban, ngành', 2, 1, 4, true, false, false, false, NULL, 0, 4, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', NULL, '{}', 4, NULL, NULL);
INSERT INTO edoc.outgoing_docs VALUES (4, 2, '2026-04-17 12:09:34.966774+00', 101, NULL, 'CV-101/SNV', 'CV101S', 'Công văn hướng dẫn thực hiện chế độ báo cáo thống kê ngành nội vụ', 2, 10, 2, '2026-04-17 12:09:34.966774+00', 'Nguyễn Văn An', '2026-04-17 12:09:34.966774+00', NULL, 1, 1, 1, 1, 'Phòng Nội vụ các huyện/thành phố', 2, 1, 3, true, false, false, false, NULL, 0, 2, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', NULL, '{}', 2, NULL, NULL);
INSERT INTO edoc.outgoing_docs VALUES (1, 1, '2026-04-13 12:09:34.966774+00', 201, NULL, 'QD-201/UBND', 'QD201', 'Quyết định ban hành Quy chế quản lý tài liệu điện tử tỉnh Lào Cai', 1, 5, 1, '2026-04-13 12:09:34.966774+00', 'Quản trị Hệ thống', '2026-04-13 12:09:34.966774+00', NULL, 1, 1, 1, 1, 'Các Sở, ngành, UBND huyện/TX', 2, 3, 1, true, false, false, false, NULL, 1, 5, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', NULL, '{}', 5, NULL, NULL);
INSERT INTO edoc.outgoing_docs VALUES (2, 1, '2026-04-15 12:09:34.966774+00', 202, NULL, 'CV-202/UBND', 'CV202', 'Công văn triển khai ứng dụng chữ ký số trong cơ quan nhà nước', 4, 8, 1, '2026-04-15 12:09:34.966774+00', 'Lê Văn Đức', '2026-04-15 12:09:34.966774+00', NULL, 1, 1, 1, 2, 'Các Sở TT&TT, Sở Nội vụ', 2, 1, 4, true, false, false, false, NULL, 1, 8, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:34:37.287276+00', NULL, '{}', 8, NULL, NULL);
INSERT INTO edoc.outgoing_docs VALUES (6, 1, '2026-04-17 15:37:21.1+00', 4, NULL, 'tt', 'tt', 'ttttt', 1, 1, NULL, '2026-04-17 15:37:37.8+00', 'ttt', '2026-04-17 15:37:36.4+00', '2026-04-17 15:37:39.4+00', 1, 1, 1, 1, 'ttt', 3, 3, 4, true, false, false, false, NULL, 0, 1, '2026-04-17 15:38:23.669189+00', 1, '2026-04-17 15:38:23.669189+00', 'Quản trị Hệ thống', '{}', NULL, NULL, NULL);
INSERT INTO edoc.outgoing_docs VALUES (5, 1, '2026-04-17 15:09:30.008+00', 204, NULL, 'tttttt', NULL, 'tttttt', 1, 1, 1, '2026-04-17 15:09:58.2+00', 'ttt', '2026-04-17 15:09:55.7+00', NULL, 1, 1, 1, 1, 'ttt', 2, 1, 1, false, false, false, false, NULL, 0, 1, '2026-04-17 15:10:09.4589+00', 1, '2026-04-17 15:38:43.229478+00', 'Quản trị Hệ thống', '{}', 1, 1, 'ko');


ALTER TABLE edoc.outgoing_docs ENABLE TRIGGER ALL;

--
-- Data for Name: attachment_outgoing_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.attachment_outgoing_docs DISABLE TRIGGER ALL;



ALTER TABLE edoc.attachment_outgoing_docs ENABLE TRIGGER ALL;

--
-- Data for Name: delegations; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.delegations DISABLE TRIGGER ALL;

INSERT INTO edoc.delegations VALUES (1, 2, 10, '2026-04-10', '2026-04-20', 'Ủy quyền xử lý văn bản khi đi công tác', false, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.delegations VALUES (2, 3, 7, '2026-04-15', '2026-04-25', 'Ủy quyền ký văn bản trong thời gian nghỉ phép', false, NULL, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.delegations ENABLE TRIGGER ALL;

--
-- Data for Name: device_tokens; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.device_tokens DISABLE TRIGGER ALL;

INSERT INTO edoc.device_tokens VALUES (1, 1, 'fcm-token-admin-web-abc123def456', 'web', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.device_tokens VALUES (2, 2, 'fcm-token-nguyenvana-android-xyz789', 'android', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.device_tokens VALUES (3, 4, 'fcm-token-levand-web-ghi012jkl345', 'web', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.device_tokens VALUES (4, 5, 'fcm-token-phamvane-ios-mno678pqr901', 'ios', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.device_tokens ENABLE TRIGGER ALL;

--
-- Data for Name: digital_signatures; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.digital_signatures DISABLE TRIGGER ALL;

INSERT INTO edoc.digital_signatures VALUES (1, 1, 'outgoing', 1, 'smart_ca', 'CERT-SMARTCA-001', 'CN=Quản trị Hệ thống, O=UBND tỉnh Lào Cai', 'VNPT-CA', 'signed/QD-201-signed.pdf', 'original/QD-201.pdf', 'signed', NULL, '2026-04-13 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.digital_signatures VALUES (2, 2, 'outgoing', 4, 'smart_ca', 'CERT-SMARTCA-004', 'CN=Lê Văn Đức, O=Sở TT&TT Lào Cai', 'VNPT-CA', 'signed/CV-202-signed.pdf', 'original/CV-202.pdf', 'signed', NULL, '2026-04-15 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.digital_signatures VALUES (3, 3, 'outgoing', 4, 'esign_neac', 'CERT-NEAC-004', 'CN=Lê Văn Đức, O=Sở TT&TT Lào Cai', 'NEAC-CA', NULL, 'original/CV-203.pdf', 'pending', NULL, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.digital_signatures VALUES (4, 1, 'drafting', 5, 'smart_ca', 'CERT-SMARTCA-005', 'CN=Phạm Văn Em, O=VP UBND tỉnh Lào Cai', 'VNPT-CA', 'signed/DT-01-signed.pdf', 'original/DT-01.pdf', 'signed', NULL, '2026-04-12 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.digital_signatures ENABLE TRIGGER ALL;

--
-- Data for Name: doc_columns; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.doc_columns DISABLE TRIGGER ALL;

INSERT INTO edoc.doc_columns VALUES (47, 1, 'old_notation', 'Số hiệu cũ', false, true, 1, 'Số hiệu từ hệ thống cũ (nếu có)', '2026-04-17 12:09:34.966774+00', 'text', 100, false);
INSERT INTO edoc.doc_columns VALUES (48, 2, 'effective_from', 'Hiệu lực từ ngày', false, true, 1, 'Ngày bắt đầu có hiệu lực', '2026-04-17 12:09:34.966774+00', 'date', NULL, false);
INSERT INTO edoc.doc_columns VALUES (49, 2, 'effective_to', 'Hiệu lực đến ngày', false, true, 2, 'Ngày hết hiệu lực', '2026-04-17 12:09:34.966774+00', 'date', NULL, false);
INSERT INTO edoc.doc_columns VALUES (50, 3, 'review_deadline', 'Hạn góp ý', false, true, 1, 'Hạn chót gửi ý kiến góp ý', '2026-04-17 12:09:34.966774+00', 'date', NULL, false);
INSERT INTO edoc.doc_columns VALUES (51, 3, 'version_number', 'Số phiên bản', false, true, 2, 'Phiên bản dự thảo (VD: 1, 2, 3)', '2026-04-17 12:09:34.966774+00', 'number', NULL, false);


ALTER TABLE edoc.doc_columns ENABLE TRIGGER ALL;

--
-- Data for Name: doc_flows; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.doc_flows DISABLE TRIGGER ALL;



ALTER TABLE edoc.doc_flows ENABLE TRIGGER ALL;

--
-- Data for Name: doc_flow_steps; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.doc_flow_steps DISABLE TRIGGER ALL;



ALTER TABLE edoc.doc_flow_steps ENABLE TRIGGER ALL;

--
-- Data for Name: doc_flow_step_links; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.doc_flow_step_links DISABLE TRIGGER ALL;



ALTER TABLE edoc.doc_flow_step_links ENABLE TRIGGER ALL;

--
-- Data for Name: doc_flow_step_staff; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.doc_flow_step_staff DISABLE TRIGGER ALL;



ALTER TABLE edoc.doc_flow_step_staff ENABLE TRIGGER ALL;

--
-- Data for Name: email_templates; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.email_templates DISABLE TRIGGER ALL;

INSERT INTO edoc.email_templates VALUES (1, 1, 'Thông báo VB đến mới', 'Văn bản đến mới: {doc_code}', '<p>Kính gửi <strong>{staff_name}</strong>,</p><p>Bạn nhận được văn bản đến mới số <strong>{doc_code}</strong> ngày {doc_date}.</p><p>Trích yếu: {abstract}</p><p>Vui lòng đăng nhập hệ thống e-Office để xử lý.</p><p>Trân trọng,<br/>Hệ thống e-Office</p>', 'Email thông báo VB đến mới', true, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.email_templates VALUES (2, 1, 'Nhắc nhở hạn xử lý', 'Nhắc nhở: VB {doc_code} sắp hết hạn', '<p>Kính gửi <strong>{staff_name}</strong>,</p><p>Văn bản số <strong>{doc_code}</strong> có hạn xử lý đến <strong>{deadline}</strong>.</p><p>Vui lòng hoàn thành xử lý trước thời hạn.</p><p>Trân trọng,<br/>Hệ thống e-Office</p>', 'Email nhắc hạn xử lý', true, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.email_templates VALUES (3, 1, 'Thông báo cuộc họp', 'Mời họp: {meeting_title}', '<p>Kính gửi <strong>{staff_name}</strong>,</p><p>Bạn được mời tham dự cuộc họp:</p><ul><li>Tiêu đề: <strong>{meeting_title}</strong></li><li>Thời gian: {meeting_time}</li><li>Phòng họp: {meeting_room}</li></ul><p>Vui lòng xác nhận tham dự trên hệ thống.</p><p>Trân trọng,<br/>Hệ thống e-Office</p>', 'Email mời họp', true, 1, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.email_templates ENABLE TRIGGER ALL;

--
-- Data for Name: handling_doc_links; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.handling_doc_links DISABLE TRIGGER ALL;

INSERT INTO edoc.handling_doc_links VALUES (1, 1, 'incoming', 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.handling_doc_links VALUES (2, 2, 'incoming', 2, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.handling_doc_links VALUES (3, 3, 'incoming', 4, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.handling_doc_links VALUES (4, 4, 'incoming', 6, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.handling_doc_links VALUES (5, 5, 'outgoing', 3, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.handling_doc_links VALUES (6, 6, 'incoming', 7, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.handling_doc_links VALUES (7, 7, 'incoming', 8, '2026-04-17 14:31:56.992542+00');
INSERT INTO edoc.handling_doc_links VALUES (8, 4, 'incoming', 8, '2026-04-17 14:33:44.834562+00');


ALTER TABLE edoc.handling_doc_links ENABLE TRIGGER ALL;

--
-- Data for Name: leader_notes; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.leader_notes DISABLE TRIGGER ALL;

INSERT INTO edoc.leader_notes VALUES (1, 1, 1, 'Giao Sở TT&TT chủ trì, phối hợp các đơn vị triển khai. Hạn: 30/04/2026.', '2026-04-17 12:09:34.966774+00', NULL, NULL, NULL, NULL);
INSERT INTO edoc.leader_notes VALUES (2, 2, 1, 'Đồng ý dự toán. Sở TC theo dõi triển khai.', '2026-04-17 12:09:34.966774+00', NULL, NULL, NULL, NULL);
INSERT INTO edoc.leader_notes VALUES (3, 4, 2, 'Phòng TCHC chuẩn bị phương án tuyển dụng, báo cáo trước 20/04.', '2026-04-17 12:09:34.966774+00', NULL, NULL, NULL, NULL);
INSERT INTO edoc.leader_notes VALUES (4, NULL, 1, 'Duyệt nội dung. Phát hành ngay.', '2026-04-17 12:09:34.966774+00', NULL, 1, NULL, NULL);
INSERT INTO edoc.leader_notes VALUES (5, NULL, 2, 'Cần bổ sung số liệu quý I trước khi trình.', '2026-04-17 12:09:34.966774+00', NULL, 3, NULL, NULL);
INSERT INTO edoc.leader_notes VALUES (6, NULL, 1, 'Ban hành đúng tiến độ. Giao Sở TT&TT hướng dẫn thực hiện.', '2026-04-17 12:09:34.966774+00', 1, NULL, NULL, NULL);
INSERT INTO edoc.leader_notes VALUES (7, NULL, 2, 'Đẩy mạnh triển khai chữ ký số tại các đơn vị trực thuộc.', '2026-04-17 12:09:34.966774+00', 2, NULL, NULL, NULL);
INSERT INTO edoc.leader_notes VALUES (8, 8, 1, 'ok', '2026-04-17 14:58:49.535711+00', NULL, NULL, NULL, '{2,3}');


ALTER TABLE edoc.leader_notes ENABLE TRIGGER ALL;

--
-- Data for Name: lgsp_config; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.lgsp_config DISABLE TRIGGER ALL;

INSERT INTO edoc.lgsp_config VALUES (1, 1, 'https://lgsp.laocai.gov.vn/api', 'UBND_LC', 'admin_lgsp', NULL, 300, true, NULL, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.lgsp_config ENABLE TRIGGER ALL;

--
-- Data for Name: lgsp_organizations; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.lgsp_organizations DISABLE TRIGGER ALL;

INSERT INTO edoc.lgsp_organizations VALUES (1, 'BNV', 'Bộ Nội vụ', NULL, 'Số 8 Tôn Thất Thuyết, Hà Nội', 'bnv@chinhphu.vn', '024.38240101', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.lgsp_organizations VALUES (2, 'BTTTT', 'Bộ Thông tin và Truyền thông', NULL, 'Số 18 Nguyễn Du, Hà Nội', 'btttt@mic.gov.vn', '024.39437010', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.lgsp_organizations VALUES (3, 'BTC', 'Bộ Tài chính', NULL, 'Số 28 Trần Hưng Đạo, Hà Nội', 'btc@mof.gov.vn', '024.22202828', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.lgsp_organizations VALUES (4, 'UBND-YB', 'UBND tỉnh Yên Bái', NULL, 'Đường Yên Ninh, TP Yên Bái', 'ubnd@yenbai.gov.vn', '02163852223', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.lgsp_organizations VALUES (5, 'UBND-HP', 'UBND tỉnh Hải Phòng', NULL, 'Số 18 Hoàng Diệu, Hải Phòng', 'ubnd@haiphong.gov.vn', '02253842658', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.lgsp_organizations VALUES (6, 'VPCP', 'Văn phòng Chính phủ', NULL, 'Số 1 Hoàng Hoa Thám, Hà Nội', 'vpcp@chinhphu.vn', '024.08043100', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.lgsp_organizations VALUES (7, 'UBND-LC', 'UBND tỉnh Lào Cai', NULL, 'Đường Hoàng Liên, TP Lào Cai', 'ubnd@laocai.gov.vn', '02143840888', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.lgsp_organizations ENABLE TRIGGER ALL;

--
-- Data for Name: lgsp_tracking; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.lgsp_tracking DISABLE TRIGGER ALL;

INSERT INTO edoc.lgsp_tracking VALUES (1, 1, NULL, 'send', 'LGSP-LC-2026-0001', 'BNV', 'Bộ Nội vụ', NULL, 'success', NULL, '2026-04-13 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00', 1);
INSERT INTO edoc.lgsp_tracking VALUES (2, 2, NULL, 'send', 'LGSP-LC-2026-0002', 'BTTTT', 'Bộ Thông tin và Truyền thông', NULL, 'success', NULL, '2026-04-15 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00', 1);
INSERT INTO edoc.lgsp_tracking VALUES (3, NULL, 1, 'receive', 'LGSP-TW-2026-0101', 'VPCP', 'Văn phòng Chính phủ', NULL, 'success', NULL, NULL, '2026-04-16 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00', 1);
INSERT INTO edoc.lgsp_tracking VALUES (4, 3, NULL, 'send', 'LGSP-LC-2026-0003', 'UBND-YB', 'UBND tỉnh Yên Bái', NULL, 'pending', NULL, '2026-04-16 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00', 4);
INSERT INTO edoc.lgsp_tracking VALUES (5, NULL, 7, 'receive', 'LGSP-TW-2026-0205', 'BNV', 'Bộ Nội vụ', NULL, 'success', NULL, NULL, '2026-04-15 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00', 1);
INSERT INTO edoc.lgsp_tracking VALUES (6, NULL, 8, 'send', NULL, 'BNV', 'Bộ Nội vụ', NULL, 'pending', NULL, NULL, NULL, '2026-04-17 14:33:57.903341+00', 1);


ALTER TABLE edoc.lgsp_tracking ENABLE TRIGGER ALL;

--
-- Data for Name: meeting_types; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.meeting_types DISABLE TRIGGER ALL;

INSERT INTO edoc.meeting_types VALUES (1, 1, 'Họp giao ban', 'Họp giao ban định kỳ', 1, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO edoc.meeting_types VALUES (2, 1, 'Họp chuyên đề', 'Họp theo chuyên đề cụ thể', 2, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO edoc.meeting_types VALUES (3, 1, 'Họp Ban lãnh đạo', 'Họp nội bộ Ban lãnh đạo', 3, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);


ALTER TABLE edoc.meeting_types ENABLE TRIGGER ALL;

--
-- Data for Name: messages; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.messages DISABLE TRIGGER ALL;

INSERT INTO edoc.messages VALUES (1, 1, 'Họp giao ban tuần 15', 'Kính gửi các đồng chí, cuộc họp giao ban tuần 15 sẽ diễn ra vào 8h00 thứ Hai ngày 14/04/2026 tại phòng họp A.', NULL, '2026-04-17 12:09:34.966774', false, NULL);
INSERT INTO edoc.messages VALUES (2, 3, 'Báo cáo tiến độ dự án CĐS', 'Anh/chị cho em xin báo cáo tiến độ dự án Chuyển đổi số đến hết tuần 14.', NULL, '2026-04-17 12:09:34.966774', false, NULL);
INSERT INTO edoc.messages VALUES (3, 1, 'Thông báo lịch nghỉ lễ 30/4-1/5', 'Thông báo đến toàn thể CBCC: Lịch nghỉ lễ từ 30/04 đến 01/05/2026.', NULL, '2026-04-17 12:09:34.966774', false, NULL);
INSERT INTO edoc.messages VALUES (4, 4, 'Đề xuất nâng cấp hệ thống mạng', 'Kính gửi BGĐ, em xin đề xuất phương án nâng cấp hạ tầng mạng nội bộ.', NULL, '2026-04-17 12:09:34.966774', false, NULL);
INSERT INTO edoc.messages VALUES (5, 1, 'Phân công nhiệm vụ Sprint 5', 'Phân công chi tiết nhiệm vụ Sprint 5 — Module HSCV cho từng thành viên.', NULL, '2026-04-17 12:09:34.966774', false, NULL);
INSERT INTO edoc.messages VALUES (6, 8, 'Báo lỗi chức năng tìm kiếm VB', 'Anh ơi, em phát hiện lỗi tìm kiếm VB đến với từ khóa tiếng Việt có dấu.', NULL, '2026-04-17 12:09:34.966774', false, NULL);
INSERT INTO edoc.messages VALUES (7, 1, 'Re: Báo lỗi chức năng tìm kiếm VB', 'Cảm ơn em đã báo, anh đã ghi nhận và sẽ xử lý trong Sprint tiếp theo.', 6, '2026-04-17 12:09:34.966774', false, NULL);
INSERT INTO edoc.messages VALUES (8, 1, 'Kế hoạch demo cuối tuần', 'Kế hoạch demo e-Office cho BLĐ ngày 18-19/04/2026. Các phòng ban chuẩn bị dữ liệu demo.', NULL, '2026-04-17 12:09:34.966774', false, NULL);
INSERT INTO edoc.messages VALUES (10, 1, 'Re: hi', 'hehe', 9, '2026-04-17 15:47:34.014389', false, NULL);
INSERT INTO edoc.messages VALUES (11, 1, 'Re: Báo cáo tiến độ dự án CĐS', 'he', 2, '2026-04-17 15:47:41.701511', false, NULL);
INSERT INTO edoc.messages VALUES (12, 1, 'Re: Báo cáo tiến độ dự án CĐS', 'test reply', 2, '2026-04-17 15:47:53.974244', false, NULL);
INSERT INTO edoc.messages VALUES (14, 1, 'Re: test', 'ok', 13, '2026-04-17 15:49:57.192008', false, NULL);
INSERT INTO edoc.messages VALUES (15, 1, 'Re: Báo cáo tiến độ dự án CĐS', 'ko', 2, '2026-04-17 15:50:02.702821', false, NULL);
INSERT INTO edoc.messages VALUES (16, 1, 't', 't', NULL, '2026-04-17 15:50:21.657516', true, '2026-04-17 16:01:26.786731+00');
INSERT INTO edoc.messages VALUES (13, 1, 'test', 'test msg', NULL, '2026-04-17 15:47:54.026433', true, '2026-04-17 16:01:30.78705+00');
INSERT INTO edoc.messages VALUES (9, 1, 'hi', 'hi', NULL, '2026-04-17 15:47:21.49242', true, '2026-04-17 16:05:03.092654+00');


ALTER TABLE edoc.messages ENABLE TRIGGER ALL;

--
-- Data for Name: message_recipients; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.message_recipients DISABLE TRIGGER ALL;

INSERT INTO edoc.message_recipients VALUES (1, 1, 2, true, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (2, 1, 3, true, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (3, 1, 4, true, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (4, 1, 5, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (6, 3, 2, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (7, 3, 3, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (8, 3, 4, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (9, 3, 5, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (10, 3, 6, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (11, 3, 7, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (12, 3, 8, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (13, 3, 9, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (14, 3, 10, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (16, 5, 4, true, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (17, 5, 8, true, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (18, 6, 1, true, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (19, 7, 8, true, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (20, 8, 2, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (21, 8, 3, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (22, 8, 4, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (23, 8, 5, true, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (24, 9, 2, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (25, 9, 3, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (26, 10, 1, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (27, 10, 2, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (28, 10, 3, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (29, 11, 3, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (30, 12, 3, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (31, 13, 2, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (32, 14, 1, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (33, 14, 2, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (34, 15, 3, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (35, 16, 2, false, NULL, false, NULL);
INSERT INTO edoc.message_recipients VALUES (15, 4, 1, true, NULL, false, NULL);


ALTER TABLE edoc.message_recipients ENABLE TRIGGER ALL;

--
-- Data for Name: notices; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.notices DISABLE TRIGGER ALL;

INSERT INTO edoc.notices VALUES (1, NULL, 'Hệ thống e-Office chính thức hoạt động', 'Hệ thống Quản lý văn bản điện tử e-Office triển khai từ 14/04/2026. Đề nghị toàn thể CBCC sử dụng hệ thống mới.', 'system', 1, '2026-04-17 12:09:34.966774', 1);
INSERT INTO edoc.notices VALUES (2, NULL, 'Bảo trì hệ thống ngày 15/04/2026', 'Hệ thống tạm ngưng từ 22h00 đến 23h00 ngày 15/04/2026 để nâng cấp và bảo trì.', 'maintenance', 1, '2026-04-17 12:09:34.966774', 1);
INSERT INTO edoc.notices VALUES (3, NULL, 'Cập nhật phiên bản v2.0 — Module mới', 'Tính năng mới: Họp không giấy, Kho lưu trữ, Tài liệu, Hợp đồng, LGSP, Ký số.', 'update', 1, '2026-04-17 12:09:34.966774', 1);
INSERT INTO edoc.notices VALUES (4, NULL, 'Hướng dẫn sử dụng module Ký số điện tử', 'Tài liệu hướng dẫn ký số đã được cập nhật tại mục Tài liệu chung.', 'guide', 1, '2026-04-17 12:09:34.966774', 1);
INSERT INTO edoc.notices VALUES (5, NULL, 'Nhắc nhở đổi mật khẩu định kỳ', 'Đề nghị toàn bộ CBCC đổi mật khẩu 3 tháng/lần để đảm bảo an toàn thông tin.', 'security', 1, '2026-04-17 12:09:34.966774', 1);
INSERT INTO edoc.notices VALUES (6, NULL, 'Demo hệ thống cho Ban lãnh đạo 18-19/04', 'Các phòng ban chuẩn bị dữ liệu demo. Lịch demo: Buổi sáng 18/04 — module VB, buổi chiều — module HSCV và Họp.', 'important', 1, '2026-04-17 12:09:34.966774', 1);


ALTER TABLE edoc.notices ENABLE TRIGGER ALL;

--
-- Data for Name: notice_reads; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.notice_reads DISABLE TRIGGER ALL;

INSERT INTO edoc.notice_reads VALUES (1, 1, 1, '2026-04-17 15:58:15.861662');


ALTER TABLE edoc.notice_reads ENABLE TRIGGER ALL;

--
-- Data for Name: notification_logs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.notification_logs DISABLE TRIGGER ALL;

INSERT INTO edoc.notification_logs VALUES (1, 2, 'fcm', 'incoming_doc_assigned', 'Văn bản đến mới', 'Bạn được giao xử lý CV-101/UBND: V/v triển khai Chính phủ điện tử', 'incoming_doc', 1, 'sent', NULL, '2026-04-16 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_logs VALUES (2, 4, 'fcm', 'incoming_doc_assigned', 'Văn bản đến mới', 'Bạn được giao xử lý CV-101/UBND: V/v triển khai Chính phủ điện tử', 'incoming_doc', 1, 'sent', NULL, '2026-04-16 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_logs VALUES (3, 3, 'email', 'incoming_doc_assigned', 'Văn bản đến mới — QD-102/STC', 'Bạn được giao xử lý QĐ-102/STC: Quyết định phê duyệt dự toán ngân sách năm 2026', 'incoming_doc', 2, 'sent', NULL, '2026-04-15 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_logs VALUES (4, 4, 'sms', 'handling_doc_deadline', 'Nhắc hạn xử lý', 'HSCV "Triển khai CPĐT 2026-2030" sắp đến hạn (30 ngày). Tiến độ: 30%.', 'handling_doc', 1, 'sent', NULL, '2026-04-17 00:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_logs VALUES (5, 8, 'fcm', 'handling_doc_assigned', 'Phối hợp HSCV', 'Bạn được giao phối hợp HSCV "Triển khai CPĐT 2026-2030".', 'handling_doc', 1, 'sent', NULL, '2026-04-16 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_logs VALUES (6, 1, 'zalo', 'meeting_reminder', 'Nhắc lịch họp', 'Họp triển khai CĐS tỉnh — 09:00 ngày 15/04/2026 tại Phòng họp A.', 'room_schedule', 2, 'sent', NULL, '2026-04-17 06:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_logs VALUES (7, 2, 'email', 'meeting_invitation', 'Mời họp giao ban tuần 15', 'Bạn được mời tham dự Họp giao ban tuần 15/2026, 08:00 ngày 14/04/2026.', 'room_schedule', 1, 'sent', NULL, '2026-04-15 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_logs VALUES (8, 6, 'fcm', 'delegation_created', 'Ủy quyền mới', 'Bạn được ủy quyền xử lý văn bản từ Nguyễn Văn An (10/04 - 20/04/2026).', 'delegation', 1, 'sent', NULL, '2026-04-13 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_logs VALUES (9, 7, 'sms', 'delegation_created', 'Ủy quyền mới', 'Bạn được ủy quyền ký văn bản từ Trần Thị Bình (15/04 - 25/04/2026).', 'delegation', 2, 'sent', NULL, '2026-04-17 00:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_logs VALUES (10, 4, 'fcm', 'digital_sign_pending', 'Yêu cầu ký số', 'VB đi CV-203/UBND cần ký số. Vui lòng ký để hoàn thành phát hành.', 'outgoing_doc', 3, 'sent', NULL, '2026-04-16 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.notification_logs ENABLE TRIGGER ALL;

--
-- Data for Name: notification_preferences; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.notification_preferences DISABLE TRIGGER ALL;

INSERT INTO edoc.notification_preferences VALUES (1, 1, 'fcm', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (2, 1, 'email', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (3, 1, 'zalo', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (4, 1, 'sms', false, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (5, 2, 'fcm', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (6, 2, 'email', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (7, 2, 'zalo', false, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (8, 2, 'sms', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (9, 3, 'fcm', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (10, 3, 'email', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (11, 3, 'zalo', false, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (12, 3, 'sms', false, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (13, 4, 'fcm', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (14, 4, 'email', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (15, 4, 'zalo', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (16, 4, 'sms', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (17, 5, 'fcm', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (18, 5, 'email', false, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (19, 5, 'zalo', false, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (20, 5, 'sms', false, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (21, 8, 'fcm', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (22, 8, 'email', true, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (23, 8, 'zalo', false, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.notification_preferences VALUES (24, 8, 'sms', false, '2026-04-17 12:09:34.966774+00', '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.notification_preferences ENABLE TRIGGER ALL;

--
-- Data for Name: opinion_handling_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.opinion_handling_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.opinion_handling_docs VALUES (1, 1, 4, 'Đã liên hệ Cục CNTT - Bộ TT&TT để xin hướng dẫn chi tiết.', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.opinion_handling_docs VALUES (2, 1, 8, 'Đề xuất tổ chức hội thảo triển khai CĐS cấp tỉnh.', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.opinion_handling_docs VALUES (3, 2, 3, 'Dự toán phù hợp, đề nghị phê duyệt.', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.opinion_handling_docs VALUES (4, 5, 4, 'Báo cáo đã hoàn thành, gửi BGĐ phê duyệt.', NULL, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.opinion_handling_docs ENABLE TRIGGER ALL;

--
-- Data for Name: organizations; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.organizations DISABLE TRIGGER ALL;

INSERT INTO edoc.organizations VALUES (1, 1, 'UBND-LC', 'UBND tỉnh Lào Cai', 'Đường Hoàng Liên, TP Lào Cai', '02143840888', NULL, 'ubnd@laocai.gov.vn', NULL, 'Vũ Thị Kim', NULL, 1, false, NULL, NULL, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.organizations VALUES (2, 2, 'SNV-LC', 'Sở Nội vụ tỉnh Lào Cai', '123 Trần Phú, TP Lào Cai', '02143840102', NULL, 'snv@laocai.gov.vn', NULL, 'Đỗ Thị Lan', NULL, 2, false, NULL, NULL, NULL, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.organizations ENABLE TRIGGER ALL;

--
-- Data for Name: rooms; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.rooms DISABLE TRIGGER ALL;

INSERT INTO edoc.rooms VALUES (1, 1, 'Phòng họp A — Tầng 3', 'PH-A', 'Tầng 3, Trụ sở UBND tỉnh', 'Sức chứa 50 người, có máy chiếu', 1, true, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO edoc.rooms VALUES (2, 1, 'Phòng họp B — Tầng 2', 'PH-B', 'Tầng 2, Trụ sở UBND tỉnh', 'Sức chứa 20 người, có TV lớn', 2, true, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO edoc.rooms VALUES (3, 1, 'Hội trường lớn', 'HT', 'Tầng 1, Trụ sở UBND tỉnh', 'Sức chứa 200 người', 3, true, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);


ALTER TABLE edoc.rooms ENABLE TRIGGER ALL;

--
-- Data for Name: room_schedules; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.room_schedules DISABLE TRIGGER ALL;

INSERT INTO edoc.room_schedules VALUES (1, 1, 1, 1, 'Họp giao ban tuần 15/2026', 'Giao ban tình hình tuần 15, triển khai nhiệm vụ tuần 16.', NULL, '2026-04-14', '2026-04-14', '08:00', '09:30', 1, 9, 1, NULL, NULL, NULL, 2, NULL, 0, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, 1);
INSERT INTO edoc.room_schedules VALUES (2, 1, 1, 2, 'Họp triển khai Chuyển đổi số tỉnh', 'Rà soát tiến độ CĐS, phân công nhiệm vụ CĐS quý II/2026.', NULL, '2026-04-15', '2026-04-15', '09:00', '11:00', 1, 5, 1, NULL, NULL, NULL, 0, NULL, 0, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, 1);
INSERT INTO edoc.room_schedules VALUES (3, 1, 3, 3, 'Họp Ban lãnh đạo — kế hoạch quý II', 'Thảo luận kế hoạch công tác quý II/2026.', NULL, '2026-04-16', '2026-04-16', '14:00', '16:00', 1, 9, 1, NULL, NULL, NULL, 0, NULL, 0, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, 1);
INSERT INTO edoc.room_schedules VALUES (4, 1, 2, 2, 'Demo hệ thống e-Office cho BLĐ', 'Trình diễn các chức năng mới: HSCV, Họp, Kho lưu trữ, LGSP, Ký số.', NULL, '2026-04-18', '2026-04-18', '14:00', '16:00', 4, 8, 0, NULL, NULL, NULL, 0, NULL, 0, 4, '2026-04-17 12:09:34.966774+00', NULL, NULL, 4);


ALTER TABLE edoc.room_schedules ENABLE TRIGGER ALL;

--
-- Data for Name: room_schedule_questions; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.room_schedule_questions DISABLE TRIGGER ALL;



ALTER TABLE edoc.room_schedule_questions ENABLE TRIGGER ALL;

--
-- Data for Name: room_schedule_answers; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.room_schedule_answers DISABLE TRIGGER ALL;



ALTER TABLE edoc.room_schedule_answers ENABLE TRIGGER ALL;

--
-- Data for Name: room_schedule_attachments; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.room_schedule_attachments DISABLE TRIGGER ALL;



ALTER TABLE edoc.room_schedule_attachments ENABLE TRIGGER ALL;

--
-- Data for Name: room_schedule_staff; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.room_schedule_staff DISABLE TRIGGER ALL;

INSERT INTO edoc.room_schedule_staff VALUES (1, 1, 1, 1, false, false, true, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (2, 1, 2, 0, false, false, true, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (3, 1, 3, 0, false, false, true, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (4, 1, 4, 0, false, false, true, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (5, 1, 5, 0, false, false, true, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (6, 1, 9, 2, true, false, true, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (7, 2, 1, 1, false, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (8, 2, 2, 0, false, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (9, 2, 4, 0, false, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (10, 2, 5, 2, true, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (11, 2, 8, 0, false, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (12, 3, 1, 1, false, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (13, 3, 2, 0, false, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (14, 3, 3, 0, false, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (15, 3, 4, 0, false, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (16, 3, 9, 2, true, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (17, 4, 1, 0, false, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (18, 4, 4, 1, false, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (19, 4, 8, 2, true, false, false, NULL, NULL, 0, NULL, NULL);
INSERT INTO edoc.room_schedule_staff VALUES (20, 4, 5, 0, false, false, false, NULL, NULL, 0, NULL, NULL);


ALTER TABLE edoc.room_schedule_staff ENABLE TRIGGER ALL;

--
-- Data for Name: room_schedule_votes; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.room_schedule_votes DISABLE TRIGGER ALL;



ALTER TABLE edoc.room_schedule_votes ENABLE TRIGGER ALL;

--
-- Data for Name: send_doc_user_configs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.send_doc_user_configs DISABLE TRIGGER ALL;

INSERT INTO edoc.send_doc_user_configs VALUES (1, 1, 2, 'doc', '2026-04-17 14:30:16.430757+00');
INSERT INTO edoc.send_doc_user_configs VALUES (2, 1, 3, 'doc', '2026-04-17 14:30:16.430757+00');


ALTER TABLE edoc.send_doc_user_configs ENABLE TRIGGER ALL;

--
-- Data for Name: signers; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.signers DISABLE TRIGGER ALL;

INSERT INTO edoc.signers VALUES (1, 1, 1, 1, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.signers VALUES (2, 2, 2, 2, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.signers VALUES (3, 3, 3, 3, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.signers VALUES (4, 4, 4, 4, 1, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.signers ENABLE TRIGGER ALL;

--
-- Data for Name: sms_templates; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.sms_templates DISABLE TRIGGER ALL;

INSERT INTO edoc.sms_templates VALUES (1, 1, 'Thông báo VB đến mới', 'Ban nhan VB den moi so {doc_code} ngay {doc_date}. Vui long dang nhap e-Office de xu ly.', 'Gửi khi có VB đến mới', true, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.sms_templates VALUES (2, 1, 'Nhắc nhở xử lý VB', 'VB so {doc_code} sap het han xu ly ({deadline}). Vui long hoan thanh truoc thoi han.', 'Nhắc trước hạn 1 ngày', true, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.sms_templates VALUES (3, 1, 'Thông báo cuộc họp', 'Ban duoc moi hop: {meeting_title} luc {meeting_time} tai {meeting_room}. Vui long xac nhan.', 'Gửi khi mời họp', true, 1, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.sms_templates ENABLE TRIGGER ALL;

--
-- Data for Name: staff_handling_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.staff_handling_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.staff_handling_docs VALUES (1, 1, 4, 1, 'xu_ly', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (2, 1, 8, 2, 'phoi_hop', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (3, 2, 3, 1, 'xu_ly', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (4, 2, 7, 2, 'phoi_hop', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (5, 3, 2, 1, 'xu_ly', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (6, 3, 6, 2, 'phoi_hop', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (7, 3, 10, 2, 'phoi_hop', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (8, 4, 4, 1, 'xu_ly', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (9, 4, 8, 2, 'phoi_hop', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (10, 5, 4, 1, 'xu_ly', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (11, 5, 8, 2, 'hoan_thanh', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (12, 6, 6, 1, 'xu_ly', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (13, 6, 10, 2, 'phoi_hop', '2026-04-17 12:09:34.966774+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (14, 7, 2, 1, NULL, '2026-04-17 14:31:56.992542+00', NULL);
INSERT INTO edoc.staff_handling_docs VALUES (15, 7, 3, 1, NULL, '2026-04-17 14:31:56.992542+00', NULL);


ALTER TABLE edoc.staff_handling_docs ENABLE TRIGGER ALL;

--
-- Data for Name: staff_notes; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.staff_notes DISABLE TRIGGER ALL;

INSERT INTO edoc.staff_notes VALUES (1, 'incoming', 1, 2, 'Văn bản quan trọng — Chính phủ điện tử', '2026-04-17 12:09:34.966774+00', true);
INSERT INTO edoc.staff_notes VALUES (2, 'incoming', 6, 2, 'Chỉ thị Thủ tướng — cần theo dõi', '2026-04-17 12:09:34.966774+00', true);
INSERT INTO edoc.staff_notes VALUES (3, 'incoming', 3, 4, 'Liên quan đến hạ tầng CNTT', '2026-04-17 12:09:34.966774+00', false);
INSERT INTO edoc.staff_notes VALUES (4, 'outgoing', 1, 5, 'QĐ do mình soạn', '2026-04-17 12:09:34.966774+00', false);
INSERT INTO edoc.staff_notes VALUES (5, 'drafting', 3, 4, 'Báo cáo CNTT quý I', '2026-04-17 12:09:34.966774+00', true);
INSERT INTO edoc.staff_notes VALUES (6, 'incoming', 8, 1, NULL, '2026-04-17 14:59:08.054489+00', false);
INSERT INTO edoc.staff_notes VALUES (7, 'outgoing', 5, 1, NULL, '2026-04-17 15:37:13.84283+00', false);


ALTER TABLE edoc.staff_notes ENABLE TRIGGER ALL;

--
-- Data for Name: user_drafting_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.user_drafting_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.user_drafting_docs VALUES (1, 5, 1, true, '2026-04-17 15:38:08.061468+00', '2026-04-17 15:38:08.061468+00', NULL, NULL);


ALTER TABLE edoc.user_drafting_docs ENABLE TRIGGER ALL;

--
-- Data for Name: user_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.user_incoming_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.user_incoming_docs VALUES (1, 1, 2, true, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (2, 1, 4, true, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (3, 1, 5, false, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (4, 2, 3, true, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (5, 2, 7, false, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (6, 3, 4, true, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (7, 3, 8, true, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (8, 4, 2, true, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (9, 4, 6, false, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (10, 4, 10, false, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (11, 5, 1, true, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (12, 5, 5, true, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (14, 6, 4, false, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (15, 7, 2, true, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (16, 7, 6, false, NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (13, 6, 1, true, '2026-04-17 14:59:14.698346+00', '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.user_incoming_docs VALUES (17, 8, 1, true, '2026-04-17 14:30:27.159239+00', '2026-04-17 14:30:27.159239+00');
INSERT INTO edoc.user_incoming_docs VALUES (41, 4, 1, true, '2026-04-17 17:08:08.162079+00', '2026-04-17 17:08:08.162079+00');


ALTER TABLE edoc.user_incoming_docs ENABLE TRIGGER ALL;

--
-- Data for Name: user_outgoing_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.user_outgoing_docs DISABLE TRIGGER ALL;

INSERT INTO edoc.user_outgoing_docs VALUES (1, 4, 1, true, '2026-04-17 15:06:07.330199+00', '2026-04-17 15:06:07.330199+00', NULL, NULL);
INSERT INTO edoc.user_outgoing_docs VALUES (20, 6, 1, true, '2026-04-17 15:38:26.229279+00', '2026-04-17 15:38:26.229279+00', NULL, NULL);
INSERT INTO edoc.user_outgoing_docs VALUES (3, 5, 1, true, '2026-04-17 15:16:04.654169+00', '2026-04-17 15:16:04.654169+00', NULL, NULL);


ALTER TABLE edoc.user_outgoing_docs ENABLE TRIGGER ALL;

--
-- Data for Name: work_groups; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.work_groups DISABLE TRIGGER ALL;

INSERT INTO edoc.work_groups VALUES (1, 1, 'Ban Chỉ đạo Chuyển đổi số', NULL, 1, false, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.work_groups VALUES (2, 1, 'Tổ Công tác cải cách hành chính', NULL, 2, false, 1, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.work_groups ENABLE TRIGGER ALL;

--
-- Data for Name: work_group_members; Type: TABLE DATA; Schema: edoc; Owner: -
--

ALTER TABLE edoc.work_group_members DISABLE TRIGGER ALL;

INSERT INTO edoc.work_group_members VALUES (1, 1, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.work_group_members VALUES (2, 1, 2, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.work_group_members VALUES (3, 1, 4, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.work_group_members VALUES (4, 1, 8, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.work_group_members VALUES (5, 2, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.work_group_members VALUES (6, 2, 5, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.work_group_members VALUES (7, 2, 6, '2026-04-17 12:09:34.966774+00');
INSERT INTO edoc.work_group_members VALUES (8, 2, 10, '2026-04-17 12:09:34.966774+00');


ALTER TABLE edoc.work_group_members ENABLE TRIGGER ALL;

--
-- Data for Name: borrow_requests; Type: TABLE DATA; Schema: esto; Owner: -
--

ALTER TABLE esto.borrow_requests DISABLE TRIGGER ALL;

INSERT INTO esto.borrow_requests VALUES (1, 'Mượn hồ sơ tuyển dụng 2025 để đối chiếu', 1, 0, 'Cần đối chiếu số liệu cho kế hoạch tuyển dụng 2026', '2026-04-10', 1, 6, '2026-04-17 12:09:34.966774+00', NULL, NULL, 6);
INSERT INTO esto.borrow_requests VALUES (2, 'Mượn hồ sơ ngân sách 2025 để lập dự toán', 1, 1, 'Cần gấp để lập dự toán ngân sách quý II/2026', '2026-04-12', 0, 7, '2026-04-17 12:09:34.966774+00', NULL, NULL, 7);


ALTER TABLE esto.borrow_requests ENABLE TRIGGER ALL;

--
-- Data for Name: fonds; Type: TABLE DATA; Schema: esto; Owner: -
--

ALTER TABLE esto.fonds DISABLE TRIGGER ALL;

INSERT INTO esto.fonds VALUES (1, 1, 0, 'P-UBND', 'Phông UBND tỉnh Lào Cai', 'Phông lưu trữ văn bản UBND tỉnh từ năm 2020', '2020-2026', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO esto.fonds VALUES (2, 1, 0, 'P-SNV', 'Phông Sở Nội vụ', 'Phông lưu trữ văn bản Sở Nội vụ', '2022-2026', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, 2, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO esto.fonds VALUES (3, 1, 0, 'P-STTTT', 'Phông Sở TT&TT', 'Phông lưu trữ Sở TT&TT tỉnh Lào Cai', '2023-2026', NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, NULL, NULL, 4, '2026-04-17 12:09:34.966774+00', NULL, NULL);


ALTER TABLE esto.fonds ENABLE TRIGGER ALL;

--
-- Data for Name: warehouses; Type: TABLE DATA; Schema: esto; Owner: -
--

ALTER TABLE esto.warehouses DISABLE TRIGGER ALL;

INSERT INTO esto.warehouses VALUES (1, 1, 1, 'KHO-01', 'Kho lưu trữ UBND tỉnh', '02143840900', 'Tầng hầm, Trụ sở UBND tỉnh Lào Cai', true, NULL, 0, true, 0, 0, NULL, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, 1);
INSERT INTO esto.warehouses VALUES (2, 1, 1, 'KHO-02', 'Kho lưu trữ Sở TT&TT', '02143840901', 'Phòng 101, Trụ sở Sở TT&TT tỉnh Lào Cai', true, NULL, 0, true, 0, 0, NULL, false, 4, '2026-04-17 12:09:34.966774+00', NULL, NULL, 4);
INSERT INTO esto.warehouses VALUES (3, 1, 2, 'KE-A1', 'Kệ A1 — Tủ văn bản hành chính', NULL, NULL, true, NULL, 1, false, 1, 0, NULL, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, 1);
INSERT INTO esto.warehouses VALUES (4, 1, 2, 'KE-A2', 'Kệ A2 — Tủ văn bản tài chính', NULL, NULL, true, NULL, 1, false, 1, 0, NULL, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, 1);


ALTER TABLE esto.warehouses ENABLE TRIGGER ALL;

--
-- Data for Name: records; Type: TABLE DATA; Schema: esto; Owner: -
--

ALTER TABLE esto.records DISABLE TRIGGER ALL;

INSERT INTO esto.records VALUES (1, 1, 1, 'HS-UBND-001', NULL, 'UBND/QD/2025', 'Hồ sơ Quyết định nhân sự năm 2025', '15 năm', NULL, 'Tiếng Việt', '2025-01-01', '2025-12-31', 45, 'Tập hợp QĐ bổ nhiệm, điều động, khen thưởng năm 2025', NULL, NULL, 120, NULL, 0, NULL, NULL, 5, 0, 3, NULL, 0, NULL, NULL, NULL, NULL, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, 1);
INSERT INTO esto.records VALUES (2, 1, 1, 'HS-UBND-002', NULL, 'UBND/CV/2025', 'Hồ sơ Công văn hành chính năm 2025', '10 năm', NULL, 'Tiếng Việt', '2025-01-01', '2025-12-31', 230, 'Công văn hành chính nội bộ và liên cơ quan', NULL, NULL, 580, NULL, 0, NULL, NULL, 5, 0, 3, NULL, 0, NULL, NULL, NULL, NULL, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, 1);
INSERT INTO esto.records VALUES (3, 1, 2, 'HS-SNV-001', NULL, 'SNV/TD/2025', 'Hồ sơ tuyển dụng công chức năm 2025', '20 năm', NULL, 'Tiếng Việt', '2025-03-01', '2025-09-30', 85, 'Hồ sơ thi tuyển, xét tuyển công chức năm 2025', NULL, NULL, 250, NULL, 0, NULL, NULL, 6, 0, 3, NULL, 0, NULL, NULL, NULL, NULL, false, 2, '2026-04-17 12:09:34.966774+00', NULL, NULL, 2);
INSERT INTO esto.records VALUES (4, 1, 3, 'HS-STTTT-001', NULL, 'STTTT/CDS/2025', 'Hồ sơ Chuyển đổi số năm 2025', '10 năm', NULL, 'Tiếng Việt', '2025-01-01', '2025-12-31', 60, 'Kế hoạch, báo cáo, đánh giá CĐS năm 2025', NULL, NULL, 150, NULL, 0, NULL, NULL, 8, 0, 4, NULL, 0, NULL, NULL, NULL, NULL, false, 4, '2026-04-17 12:09:34.966774+00', NULL, NULL, 4);
INSERT INTO esto.records VALUES (5, 1, 1, 'HS-UBND-003', NULL, 'UBND/NS/2025', 'Hồ sơ ngân sách năm 2025', '15 năm', NULL, 'Tiếng Việt', '2025-01-01', '2025-12-31', 120, 'Dự toán, quyết toán, phân bổ ngân sách năm 2025', NULL, NULL, 350, NULL, 0, NULL, NULL, 7, 0, 4, NULL, 0, NULL, NULL, NULL, NULL, false, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, 1);


ALTER TABLE esto.records ENABLE TRIGGER ALL;

--
-- Data for Name: borrow_request_records; Type: TABLE DATA; Schema: esto; Owner: -
--

ALTER TABLE esto.borrow_request_records DISABLE TRIGGER ALL;

INSERT INTO esto.borrow_request_records VALUES (1, 1, 3, '2026-04-25', NULL);
INSERT INTO esto.borrow_request_records VALUES (2, 2, 5, '2026-04-20', NULL);


ALTER TABLE esto.borrow_request_records ENABLE TRIGGER ALL;

--
-- Data for Name: document_archives; Type: TABLE DATA; Schema: esto; Owner: -
--

ALTER TABLE esto.document_archives DISABLE TRIGGER ALL;

INSERT INTO esto.document_archives VALUES (3, 'incoming', 8, NULL, NULL, NULL, NULL, NULL, NULL, 'Tiếng Việt', NULL, NULL, 'Điện tử', NULL, true, '2026-04-17 14:53:19.576311+00', 1, '2026-04-17 14:53:19.576311+00');
INSERT INTO esto.document_archives VALUES (4, 'incoming', 6, 2, 2, NULL, 't', 't', NULL, 'Tiếng Việt', 't', 'tt', 'Điện tử', 't', true, '2026-04-17 15:05:50.150041+00', 1, '2026-04-17 15:05:50.150041+00');


ALTER TABLE esto.document_archives ENABLE TRIGGER ALL;

--
-- Data for Name: document_categories; Type: TABLE DATA; Schema: iso; Owner: -
--

ALTER TABLE iso.document_categories DISABLE TRIGGER ALL;

INSERT INTO iso.document_categories VALUES (1, 0, 'ISO', 'Tài liệu ISO', NULL, 1, NULL, NULL, 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO iso.document_categories VALUES (2, 0, 'NB', 'Tài liệu nội bộ', NULL, 1, NULL, NULL, 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO iso.document_categories VALUES (3, 0, 'PQ', 'Văn bản pháp quy', NULL, 1, NULL, NULL, 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO iso.document_categories VALUES (4, 1, 'ISO-QT', 'Quy trình ISO 9001:2015', NULL, 1, NULL, NULL, 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);
INSERT INTO iso.document_categories VALUES (5, 2, 'NB-HD', 'Hướng dẫn sử dụng', NULL, 1, NULL, NULL, 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL);


ALTER TABLE iso.document_categories ENABLE TRIGGER ALL;

--
-- Data for Name: documents; Type: TABLE DATA; Schema: iso; Owner: -
--

ALTER TABLE iso.documents DISABLE TRIGGER ALL;

INSERT INTO iso.documents VALUES (1, 1, 4, 'Quy trình tiếp nhận và xử lý văn bản đến', 'Quy trình ISO cho văn bản đến theo ISO 9001:2015', 'QT-QLVB-01.pdf', 'iso/QT-QLVB-01.pdf', 2048000, 'application/pdf', 'ISO, văn bản đến, quy trình', 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, false, 1);
INSERT INTO iso.documents VALUES (2, 1, 4, 'Quy trình soạn thảo và ban hành văn bản', 'Quy trình ISO cho VB đi từ dự thảo đến phát hành', 'QT-QLVB-02.pdf', 'iso/QT-QLVB-02.pdf', 1536000, 'application/pdf', 'ISO, văn bản đi, soạn thảo', 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, false, 1);
INSERT INTO iso.documents VALUES (3, 1, 5, 'Hướng dẫn sử dụng hệ thống e-Office v2.0', 'Tài liệu hướng dẫn chi tiết cho người dùng cuối', 'HD-eOffice-v2.pdf', 'nb/HD-eOffice-v2.pdf', 5120000, 'application/pdf', 'hướng dẫn, e-Office, sử dụng', 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, false, 1);
INSERT INTO iso.documents VALUES (4, 1, 5, 'Hướng dẫn ký số điện tử trên e-Office', 'Hướng dẫn sử dụng chữ ký số SmartCA và EsignNEAC', 'HD-KySo.pdf', 'nb/HD-KySo.pdf', 3072000, 'application/pdf', 'ký số, SmartCA, hướng dẫn', 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, false, 1);
INSERT INTO iso.documents VALUES (5, 1, 3, 'Nghị định 30/2020/NĐ-CP về công tác văn thư', 'Nghị định quy định về công tác văn thư trong cơ quan nhà nước', 'ND-30-2020.pdf', 'pq/ND-30-2020.pdf', 4096000, 'application/pdf', 'nghị định, văn thư, pháp quy', 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, false, 1);
INSERT INTO iso.documents VALUES (6, 1, 3, 'Thông tư 01/2011/TT-BNV hướng dẫn thể thức VB', 'Thông tư hướng dẫn thể thức và kỹ thuật trình bày văn bản', 'TT-01-2011.pdf', 'pq/TT-01-2011.pdf', 2560000, 'application/pdf', 'thông tư, thể thức, trình bày', 1, 1, '2026-04-17 12:09:34.966774+00', NULL, NULL, false, 1);


ALTER TABLE iso.documents ENABLE TRIGGER ALL;

--
-- Data for Name: rights; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.rights DISABLE TRIGGER ALL;

INSERT INTO public.rights VALUES (1, NULL, 'Dashboard', 'Dashboard', '/dashboard', 'DashboardOutlined', 1, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (2, NULL, 'Văn bản đến', 'Văn bản đến', '/van-ban-den', 'InboxOutlined', 2, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (3, NULL, 'Văn bản đi', 'Văn bản đi', '/van-ban-di', 'SendOutlined', 3, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (4, NULL, 'Dự thảo', 'Dự thảo', '/du-thao', 'EditOutlined', 4, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (5, NULL, 'Hồ sơ công việc', 'Hồ sơ công việc', '/ho-so-cong-viec', 'FolderOutlined', 5, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (6, NULL, 'Lịch làm việc', 'Lịch làm việc', '/lich-lam-viec', 'CalendarOutlined', 6, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (7, NULL, 'Tin nhắn', 'Tin nhắn', '/tin-nhan', 'MessageOutlined', 7, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (8, NULL, 'Thông báo', 'Thông báo', '/thong-bao', 'BellOutlined', 8, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (9, NULL, 'Họp không giấy', 'Họp không giấy', '/hop-khong-giay', 'TeamOutlined', 9, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (10, NULL, 'Kho lưu trữ', 'Kho lưu trữ', '/kho-luu-tru', 'DatabaseOutlined', 10, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (11, NULL, 'Tài liệu', 'Tài liệu', '/tai-lieu', 'FileTextOutlined', 11, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (12, NULL, 'Hợp đồng', 'Hợp đồng', '/hop-dong', 'AuditOutlined', 12, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (13, NULL, 'Quản trị', 'Quản trị', '/quan-tri', 'SettingOutlined', 13, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (14, 13, 'Đơn vị', 'Đơn vị', '/quan-tri/don-vi', NULL, 1, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (15, 13, 'Người dùng', 'Người dùng', '/quan-tri/nguoi-dung', NULL, 2, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (16, 13, 'Nhóm quyền', 'Nhóm quyền', '/quan-tri/nhom-quyen', NULL, 3, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (17, 13, 'Chức vụ', 'Chức vụ', '/quan-tri/chuc-vu', NULL, 4, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.rights VALUES (18, 13, 'Danh mục', 'Danh mục', '/quan-tri/danh-muc', NULL, 5, true, false, false, NULL, false, '2026-04-17 12:09:34.966774+00');


ALTER TABLE public.rights ENABLE TRIGGER ALL;

--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.roles DISABLE TRIGGER ALL;

INSERT INTO public.roles VALUES (1, NULL, 'Ban Lãnh đạo', 'Ban lãnh đạo cơ quan', false, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.roles VALUES (2, NULL, 'Cán bộ', 'Cán bộ, Chuyên viên', false, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.roles VALUES (3, NULL, 'Chỉ đạo điều hành', 'Chỉ đạo điều hành', false, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.roles VALUES (4, NULL, 'Nhóm Trưởng phòng', 'Nhóm Trưởng phòng', false, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.roles VALUES (5, NULL, 'Quản trị hệ thống', 'Quản trị hệ thống', false, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.roles VALUES (6, NULL, 'Văn thư', 'Văn thư đơn vị', false, NULL, '2026-04-17 12:09:34.966774+00', NULL, '2026-04-17 12:09:34.966774+00');


ALTER TABLE public.roles ENABLE TRIGGER ALL;

--
-- Data for Name: action_of_role; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.action_of_role DISABLE TRIGGER ALL;

INSERT INTO public.action_of_role VALUES (27, 5, 1);
INSERT INTO public.action_of_role VALUES (28, 5, 2);
INSERT INTO public.action_of_role VALUES (29, 5, 3);
INSERT INTO public.action_of_role VALUES (30, 5, 4);
INSERT INTO public.action_of_role VALUES (31, 5, 5);
INSERT INTO public.action_of_role VALUES (32, 5, 6);
INSERT INTO public.action_of_role VALUES (33, 5, 7);
INSERT INTO public.action_of_role VALUES (34, 5, 8);
INSERT INTO public.action_of_role VALUES (35, 5, 9);
INSERT INTO public.action_of_role VALUES (36, 5, 10);
INSERT INTO public.action_of_role VALUES (37, 5, 11);
INSERT INTO public.action_of_role VALUES (38, 5, 12);
INSERT INTO public.action_of_role VALUES (39, 5, 13);
INSERT INTO public.action_of_role VALUES (40, 5, 14);
INSERT INTO public.action_of_role VALUES (41, 5, 15);
INSERT INTO public.action_of_role VALUES (42, 5, 16);
INSERT INTO public.action_of_role VALUES (43, 5, 17);
INSERT INTO public.action_of_role VALUES (44, 5, 18);
INSERT INTO public.action_of_role VALUES (45, 1, 1);
INSERT INTO public.action_of_role VALUES (46, 1, 2);
INSERT INTO public.action_of_role VALUES (47, 1, 3);
INSERT INTO public.action_of_role VALUES (48, 1, 4);
INSERT INTO public.action_of_role VALUES (49, 1, 5);
INSERT INTO public.action_of_role VALUES (50, 1, 6);
INSERT INTO public.action_of_role VALUES (51, 1, 7);
INSERT INTO public.action_of_role VALUES (52, 1, 8);
INSERT INTO public.action_of_role VALUES (53, 1, 9);
INSERT INTO public.action_of_role VALUES (54, 1, 10);
INSERT INTO public.action_of_role VALUES (55, 1, 11);
INSERT INTO public.action_of_role VALUES (56, 1, 12);
INSERT INTO public.action_of_role VALUES (57, 2, 1);
INSERT INTO public.action_of_role VALUES (58, 2, 2);
INSERT INTO public.action_of_role VALUES (59, 2, 3);
INSERT INTO public.action_of_role VALUES (60, 2, 4);
INSERT INTO public.action_of_role VALUES (61, 2, 5);
INSERT INTO public.action_of_role VALUES (62, 2, 6);
INSERT INTO public.action_of_role VALUES (63, 2, 7);
INSERT INTO public.action_of_role VALUES (64, 2, 8);
INSERT INTO public.action_of_role VALUES (65, 2, 9);
INSERT INTO public.action_of_role VALUES (66, 2, 10);
INSERT INTO public.action_of_role VALUES (67, 2, 11);
INSERT INTO public.action_of_role VALUES (68, 2, 12);


ALTER TABLE public.action_of_role ENABLE TRIGGER ALL;

--
-- Data for Name: calendar_events; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.calendar_events DISABLE TRIGGER ALL;

INSERT INTO public.calendar_events VALUES (1, 'Họp giao ban đầu tuần', 'Họp giao ban tuần 15 — tất cả trưởng phòng', '2026-04-14 08:00:00', '2026-04-14 09:00:00', false, '#1B3A5C', 'none', 'unit', 1, 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 1);
INSERT INTO public.calendar_events VALUES (2, 'Review code Sprint 5', 'Review module HSCV và Dashboard', '2026-04-14 14:00:00', '2026-04-14 16:00:00', false, '#0891B2', 'none', 'personal', 1, 4, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 4);
INSERT INTO public.calendar_events VALUES (3, 'Họp triển khai CĐS tỉnh', 'Ban chỉ đạo CĐS tỉnh Lào Cai', '2026-04-15 09:00:00', '2026-04-15 11:00:00', false, '#D97706', 'none', 'leader', 1, 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 1);
INSERT INTO public.calendar_events VALUES (4, 'Đào tạo e-Office buổi 1', 'Đào tạo CBCC sử dụng hệ thống e-Office mới', '2026-04-16 08:00:00', '2026-04-16 11:00:00', false, '#059669', 'none', 'unit', 1, 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 1);
INSERT INTO public.calendar_events VALUES (5, 'Đào tạo e-Office buổi 2', 'Đào tạo tiếp: Module VB đi, Dự thảo, Ký số', '2026-04-17 08:00:00', '2026-04-17 11:00:00', false, '#059669', 'none', 'unit', 1, 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 1);
INSERT INTO public.calendar_events VALUES (6, 'Demo cho Ban lãnh đạo', 'Demo hệ thống e-Office cho BLĐ tỉnh', '2026-04-18 14:00:00', '2026-04-18 16:00:00', false, '#DC2626', 'none', 'leader', 1, 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 1);
INSERT INTO public.calendar_events VALUES (7, 'Tiếp công dân định kỳ', 'Chủ tịch UBND tiếp công dân tháng 4', '2026-04-16 08:00:00', '2026-04-16 11:00:00', false, '#DC2626', 'none', 'leader', 1, 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 1);
INSERT INTO public.calendar_events VALUES (8, 'Lễ chào cờ đầu tháng 5', 'Sinh hoạt chính trị đầu tháng 5/2026', '2026-05-01 07:00:00', '2026-05-01 08:00:00', false, '#D97706', 'none', 'unit', 1, 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 1);
INSERT INTO public.calendar_events VALUES (9, 'Kiểm tra email và phê duyệt VB', 'Xử lý văn bản đến, ký duyệt VB đi buổi sáng', '2026-04-21 07:30:00', '2026-04-21 08:30:00', false, '#1B3A5C', 'none', 'personal', 1, 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 1);
INSERT INTO public.calendar_events VALUES (10, 'Họp ban giám đốc', 'Họp tổng kết tuần và giao nhiệm vụ tuần mới', '2026-04-21 09:00:00', '2026-04-21 10:30:00', false, '#D97706', 'none', 'personal', 1, 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 1);
INSERT INTO public.calendar_events VALUES (11, 'Duyệt hồ sơ tuyển dụng', 'Xem hồ sơ ứng viên vị trí chuyên viên CNTT', '2026-04-22 14:00:00', '2026-04-22 16:00:00', false, '#059669', 'none', 'personal', 1, 1, '2026-04-17 12:09:34.966774', '2026-04-17 12:09:34.966774', false, 1);


ALTER TABLE public.calendar_events ENABLE TRIGGER ALL;

--
-- Data for Name: provinces; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.provinces DISABLE TRIGGER ALL;

INSERT INTO public.provinces VALUES (1, 'Lào Cai', '10', true);
INSERT INTO public.provinces VALUES (2, 'Hà Nội', '01', true);
INSERT INTO public.provinces VALUES (3, 'TP Hồ Chí Minh', '79', true);
INSERT INTO public.provinces VALUES (4, 'Yên Bái', '15', true);
INSERT INTO public.provinces VALUES (5, 'Hà Giang', '02', true);
INSERT INTO public.provinces VALUES (6, 'Lai Châu', '12', true);
INSERT INTO public.provinces VALUES (7, 'Sơn La', '14', true);
INSERT INTO public.provinces VALUES (8, 'Điện Biên', '11', true);
INSERT INTO public.provinces VALUES (9, 'Đà Nẵng', '48', true);
INSERT INTO public.provinces VALUES (10, 'Hải Phòng', '31', true);


ALTER TABLE public.provinces ENABLE TRIGGER ALL;

--
-- Data for Name: districts; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.districts DISABLE TRIGGER ALL;

INSERT INTO public.districts VALUES (1, 1, 'TP Lào Cai', '080', true);
INSERT INTO public.districts VALUES (2, 1, 'Sa Pa', '082', true);
INSERT INTO public.districts VALUES (3, 1, 'Bát Xát', '083', true);
INSERT INTO public.districts VALUES (4, 1, 'Bảo Thắng', '085', true);
INSERT INTO public.districts VALUES (5, 1, 'Bảo Yên', '086', true);
INSERT INTO public.districts VALUES (6, 1, 'Văn Bàn', '091', true);
INSERT INTO public.districts VALUES (7, 2, 'Ba Đình', '001', true);
INSERT INTO public.districts VALUES (8, 2, 'Hoàn Kiếm', '002', true);
INSERT INTO public.districts VALUES (9, 2, 'Đống Đa', '006', true);
INSERT INTO public.districts VALUES (10, 2, 'Cầu Giấy', '005', true);


ALTER TABLE public.districts ENABLE TRIGGER ALL;

--
-- Data for Name: communes; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.communes DISABLE TRIGGER ALL;

INSERT INTO public.communes VALUES (1, 1, 'Phường Cốc Lếu', '02545', true);
INSERT INTO public.communes VALUES (2, 1, 'Phường Duyên Hải', '02548', true);
INSERT INTO public.communes VALUES (3, 1, 'Phường Lào Cai', '02551', true);
INSERT INTO public.communes VALUES (4, 1, 'Phường Kim Tân', '02554', true);
INSERT INTO public.communes VALUES (5, 2, 'TT Sa Pa', '02590', true);
INSERT INTO public.communes VALUES (6, 2, 'Xã San Sả Hồ', '02596', true);
INSERT INTO public.communes VALUES (7, 3, 'TT Bát Xát', '02560', true);
INSERT INTO public.communes VALUES (8, 3, 'Xã A Mú Sung', '02563', true);


ALTER TABLE public.communes ENABLE TRIGGER ALL;

--
-- Data for Name: configurations; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.configurations DISABLE TRIGGER ALL;

INSERT INTO public.configurations VALUES (2, 1, 'org_name', 'Ủy ban Nhân dân tỉnh Lào Cai', 'Tên cơ quan');
INSERT INTO public.configurations VALUES (3, 1, 'org_code', 'UBND_LAOCAI', 'Mã cơ quan');
INSERT INTO public.configurations VALUES (4, 1, 'org_address', 'Đường Hoàng Liên, TP Lào Cai', 'Địa chỉ cơ quan');
INSERT INTO public.configurations VALUES (5, 1, 'org_phone', '02143840900', 'Số điện thoại');
INSERT INTO public.configurations VALUES (6, 1, 'org_fax', '02143840901', 'Số fax');
INSERT INTO public.configurations VALUES (7, 1, 'org_email', 'ubnd@laocai.gov.vn', 'Email cơ quan');
INSERT INTO public.configurations VALUES (8, 1, 'org_website', 'https://laocai.gov.vn', 'Website');
INSERT INTO public.configurations VALUES (9, 1, 'max_upload_size', '52428800', 'Dung lượng upload tối đa (bytes) — 50MB');
INSERT INTO public.configurations VALUES (10, 1, 'session_timeout', '900', 'Thời gian timeout session (giây) — 15 phút');
INSERT INTO public.configurations VALUES (11, 1, 'password_min_len', '6', 'Độ dài tối thiểu mật khẩu');
INSERT INTO public.configurations VALUES (12, 1, 'password_expiry', '90', 'Số ngày hết hạn mật khẩu');
INSERT INTO public.configurations VALUES (13, 1, 'doc_number_format', '{year}/{book_code}/{number}', 'Định dạng số văn bản');
INSERT INTO public.configurations VALUES (14, 1, 'default_language', 'vi', 'Ngôn ngữ mặc định');


ALTER TABLE public.configurations ENABLE TRIGGER ALL;

--
-- Data for Name: login_history; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.login_history DISABLE TRIGGER ALL;

INSERT INTO public.login_history VALUES (1, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 12:52:13.567146+00');
INSERT INTO public.login_history VALUES (2, 2, 'nguyenvana', '::1', 'curl/8.18.0', true, '2026-04-17 12:52:13.959574+00');
INSERT INTO public.login_history VALUES (3, 6, 'hoangthif', '::1', 'curl/8.18.0', true, '2026-04-17 12:52:14.396289+00');
INSERT INTO public.login_history VALUES (4, 5, 'phamvane', '::1', 'curl/8.18.0', true, '2026-04-17 12:52:14.744111+00');
INSERT INTO public.login_history VALUES (5, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 12:53:08.573573+00');
INSERT INTO public.login_history VALUES (6, 2, 'nguyenvana', '::1', 'curl/8.18.0', true, '2026-04-17 12:53:08.7823+00');
INSERT INTO public.login_history VALUES (7, 6, 'hoangthif', '::1', 'curl/8.18.0', true, '2026-04-17 12:53:08.944166+00');
INSERT INTO public.login_history VALUES (8, 5, 'phamvane', '::1', 'curl/8.18.0', true, '2026-04-17 12:53:09.099422+00');
INSERT INTO public.login_history VALUES (9, 4, 'levand', '::1', 'curl/8.18.0', true, '2026-04-17 12:53:09.254992+00');
INSERT INTO public.login_history VALUES (10, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 12:57:42.208474+00');
INSERT INTO public.login_history VALUES (11, 2, 'nguyenvana', '::1', 'curl/8.18.0', true, '2026-04-17 12:57:42.374613+00');
INSERT INTO public.login_history VALUES (12, 6, 'hoangthif', '::1', 'curl/8.18.0', true, '2026-04-17 12:57:42.54188+00');
INSERT INTO public.login_history VALUES (13, 5, 'phamvane', '::1', 'curl/8.18.0', true, '2026-04-17 12:57:42.695226+00');
INSERT INTO public.login_history VALUES (14, 4, 'levand', '::1', 'curl/8.18.0', true, '2026-04-17 12:57:42.842347+00');
INSERT INTO public.login_history VALUES (15, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 13:40:03.746998+00');
INSERT INTO public.login_history VALUES (16, 2, 'nguyenvana', '::1', 'curl/8.18.0', true, '2026-04-17 13:40:03.930681+00');
INSERT INTO public.login_history VALUES (17, 6, 'hoangthif', '::1', 'curl/8.18.0', true, '2026-04-17 13:40:04.22436+00');
INSERT INTO public.login_history VALUES (18, 4, 'levand', '::1', 'curl/8.18.0', true, '2026-04-17 13:40:04.37614+00');
INSERT INTO public.login_history VALUES (19, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 13:40:20.130182+00');
INSERT INTO public.login_history VALUES (20, 6, 'hoangthif', '::1', 'curl/8.18.0', true, '2026-04-17 13:40:20.274193+00');
INSERT INTO public.login_history VALUES (21, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 13:42:29.849281+00');
INSERT INTO public.login_history VALUES (22, 2, 'nguyenvana', '::1', 'curl/8.18.0', true, '2026-04-17 13:42:30.02978+00');
INSERT INTO public.login_history VALUES (23, 6, 'hoangthif', '::1', 'curl/8.18.0', true, '2026-04-17 13:42:30.206016+00');
INSERT INTO public.login_history VALUES (24, 4, 'levand', '::1', 'curl/8.18.0', true, '2026-04-17 13:42:30.370564+00');
INSERT INTO public.login_history VALUES (25, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 13:42:42.827293+00');
INSERT INTO public.login_history VALUES (26, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 13:44:43.775353+00');
INSERT INTO public.login_history VALUES (27, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 13:44:51.728669+00');
INSERT INTO public.login_history VALUES (28, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 13:45:19.572198+00');
INSERT INTO public.login_history VALUES (29, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 13:45:53.845979+00');
INSERT INTO public.login_history VALUES (30, 2, 'nguyenvana', '::1', 'curl/8.18.0', true, '2026-04-17 13:45:54.033122+00');
INSERT INTO public.login_history VALUES (31, 6, 'hoangthif', '::1', 'curl/8.18.0', true, '2026-04-17 13:45:54.179303+00');
INSERT INTO public.login_history VALUES (32, 4, 'levand', '::1', 'curl/8.18.0', true, '2026-04-17 13:45:54.339895+00');
INSERT INTO public.login_history VALUES (33, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 14:02:51.042372+00');
INSERT INTO public.login_history VALUES (34, 2, 'nguyenvana', '::1', 'curl/8.18.0', true, '2026-04-17 14:02:51.18476+00');
INSERT INTO public.login_history VALUES (35, 5, 'phamvane', '::1', 'curl/8.18.0', true, '2026-04-17 14:02:51.328656+00');
INSERT INTO public.login_history VALUES (36, 6, 'hoangthif', '::1', 'curl/8.18.0', true, '2026-04-17 14:02:51.481613+00');
INSERT INTO public.login_history VALUES (37, 4, 'levand', '::1', 'curl/8.18.0', true, '2026-04-17 14:02:51.625175+00');
INSERT INTO public.login_history VALUES (38, 1, 'admin', '::1', 'curl/8.18.0', false, '2026-04-17 14:02:51.758438+00');
INSERT INTO public.login_history VALUES (39, 1, 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', true, '2026-04-17 14:29:06.16048+00');
INSERT INTO public.login_history VALUES (40, 1, 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', true, '2026-04-17 14:53:06.714131+00');
INSERT INTO public.login_history VALUES (41, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:27:49.885294+00');
INSERT INTO public.login_history VALUES (42, 1, 'admin', '::ffff:127.0.0.1', 'curl/8.18.0', true, '2026-04-17 15:28:46.553184+00');
INSERT INTO public.login_history VALUES (43, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:31:09.079127+00');
INSERT INTO public.login_history VALUES (44, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:31:20.125019+00');
INSERT INTO public.login_history VALUES (45, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:39:40.374439+00');
INSERT INTO public.login_history VALUES (46, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:39:50.978422+00');
INSERT INTO public.login_history VALUES (47, 1, 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', true, '2026-04-17 15:40:33.30714+00');
INSERT INTO public.login_history VALUES (48, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:43:45.023586+00');
INSERT INTO public.login_history VALUES (49, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:44:34.876081+00');
INSERT INTO public.login_history VALUES (50, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:44:58.303701+00');
INSERT INTO public.login_history VALUES (51, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:45:08.025152+00');
INSERT INTO public.login_history VALUES (52, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:47:12.016134+00');
INSERT INTO public.login_history VALUES (53, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:47:53.909995+00');
INSERT INTO public.login_history VALUES (54, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:48:02.043346+00');
INSERT INTO public.login_history VALUES (55, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:50:51.874048+00');
INSERT INTO public.login_history VALUES (56, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 15:51:45.120311+00');
INSERT INTO public.login_history VALUES (57, 1, 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', true, '2026-04-17 15:58:07.531673+00');
INSERT INTO public.login_history VALUES (58, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 16:03:48.29907+00');
INSERT INTO public.login_history VALUES (59, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 16:07:44.468213+00');
INSERT INTO public.login_history VALUES (60, 1, 'admin', '::1', 'curl/8.18.0', true, '2026-04-17 16:09:32.877253+00');
INSERT INTO public.login_history VALUES (61, 1, 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', true, '2026-04-17 16:27:30.010151+00');
INSERT INTO public.login_history VALUES (62, 1, 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', true, '2026-04-17 16:45:29.621204+00');
INSERT INTO public.login_history VALUES (63, 1, 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', false, '2026-04-17 17:04:22.293961+00');
INSERT INTO public.login_history VALUES (64, 1, 'admin', '::1', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36', true, '2026-04-17 17:04:32.792886+00');


ALTER TABLE public.login_history ENABLE TRIGGER ALL;

--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.refresh_tokens DISABLE TRIGGER ALL;

INSERT INTO public.refresh_tokens VALUES (1, 1, '3afbd33247f466efbae88e80518287019385cdd4eb0f2600f8e8fb7b8dedc0bf', '2026-04-24 12:52:13.555+00', '2026-04-17 12:52:13.557271+00', '2026-04-17 12:53:08.568107+00');
INSERT INTO public.refresh_tokens VALUES (2, 2, 'a9856fa6f07449851760a9403b7b66511d84a225b1d473f981ea00001792a7bb', '2026-04-24 12:52:13.919+00', '2026-04-17 12:52:13.920911+00', '2026-04-17 12:53:08.773749+00');
INSERT INTO public.refresh_tokens VALUES (3, 6, 'f74b3333c819a058ee92d8401eebfb285e287a207ba66eee88035ca12f420c84', '2026-04-24 12:52:14.389+00', '2026-04-17 12:52:14.391954+00', '2026-04-17 12:53:08.941078+00');
INSERT INTO public.refresh_tokens VALUES (4, 5, 'd93b12d87ece67778a9aaf27222d463e4c4e5312e39267b6466530883c37f195', '2026-04-24 12:52:14.739+00', '2026-04-17 12:52:14.741055+00', '2026-04-17 12:53:09.094759+00');
INSERT INTO public.refresh_tokens VALUES (5, 1, '6cb1ef8ca72ce1bd7196716beab9b58cbc379f196902657089c3128e7fddff41', '2026-04-24 12:53:08.565+00', '2026-04-17 12:53:08.568107+00', '2026-04-17 12:57:42.203169+00');
INSERT INTO public.refresh_tokens VALUES (6, 2, '5a0cb16198a3ce9690c0d6d6adfa709924e5a89c1b96b172a693dee638b49f63', '2026-04-24 12:53:08.771+00', '2026-04-17 12:53:08.773749+00', '2026-04-17 12:57:42.370291+00');
INSERT INTO public.refresh_tokens VALUES (7, 6, 'bce1505578cf9368f2dd8f6c14e754fe54885c9eba3dcc6fbbe9ea1205166d1f', '2026-04-24 12:53:08.938+00', '2026-04-17 12:53:08.941078+00', '2026-04-17 12:57:42.537786+00');
INSERT INTO public.refresh_tokens VALUES (8, 5, 'e5686d1862b9d4de02c48995ec25fb2876bd0e5fc0d6e9f37cd472d62b1901bd', '2026-04-24 12:53:09.091+00', '2026-04-17 12:53:09.094759+00', '2026-04-17 12:57:42.691272+00');
INSERT INTO public.refresh_tokens VALUES (9, 4, '1add8296db1e83aa68c621271e353f2147b2935e11f755675ecdc12593cbe0ab', '2026-04-24 12:53:09.247+00', '2026-04-17 12:53:09.25038+00', '2026-04-17 12:57:42.837803+00');
INSERT INTO public.refresh_tokens VALUES (10, 1, '4eb188e43b5413669b49a86ef843807e08de9c0f8084f376995250accfdc1ab7', '2026-04-24 12:57:42.201+00', '2026-04-17 12:57:42.203169+00', '2026-04-17 13:40:03.73596+00');
INSERT INTO public.refresh_tokens VALUES (11, 2, '44ff1176c916fac8787ddf9382455e3193ef9b88078e2d0509575e960646be33', '2026-04-24 12:57:42.368+00', '2026-04-17 12:57:42.370291+00', '2026-04-17 13:40:03.925883+00');
INSERT INTO public.refresh_tokens VALUES (12, 6, '14e1172a6cfc05d312edaa92a05b97a760dea192794b3927ae91694d74b8167f', '2026-04-24 12:57:42.535+00', '2026-04-17 12:57:42.537786+00', '2026-04-17 13:40:04.220081+00');
INSERT INTO public.refresh_tokens VALUES (14, 4, '8895ebc26a16a10b24020427a817ff4c4cb02b12ec0856174ebd8046c77ceb49', '2026-04-24 12:57:42.835+00', '2026-04-17 12:57:42.837803+00', '2026-04-17 13:40:04.371847+00');
INSERT INTO public.refresh_tokens VALUES (15, 1, '578997d38d0435657dc843d6ff7fee83c640429a912779c83cbeafdcbe030843', '2026-04-24 13:40:03.739+00', '2026-04-17 13:40:03.73596+00', '2026-04-17 13:40:20.113808+00');
INSERT INTO public.refresh_tokens VALUES (17, 6, 'ff820ac7e5cb2d85f4b3e229b4a65c9667f45f84a051c62976a6f7a3535e3531', '2026-04-24 13:40:04.223+00', '2026-04-17 13:40:04.220081+00', '2026-04-17 13:40:20.269322+00');
INSERT INTO public.refresh_tokens VALUES (19, 1, '49e1bcf6e89221400c07623b625e188f8501668805883c5b14599fe288feb645', '2026-04-24 13:40:20.114+00', '2026-04-17 13:40:20.113808+00', '2026-04-17 13:42:29.843747+00');
INSERT INTO public.refresh_tokens VALUES (16, 2, '4d6d8769aaa42d3ea07903d36c50378ba6f7f72483869483b3313fc635af318f', '2026-04-24 13:40:03.929+00', '2026-04-17 13:40:03.925883+00', '2026-04-17 13:42:30.025218+00');
INSERT INTO public.refresh_tokens VALUES (20, 6, '48f3ce9159e30e60d92737b765d3d1dcdad2f1e47aecfba0cd9ea6a586ce1550', '2026-04-24 13:40:20.269+00', '2026-04-17 13:40:20.269322+00', '2026-04-17 13:42:30.201806+00');
INSERT INTO public.refresh_tokens VALUES (18, 4, '6fabb36f2d7a64cd699adc61f5c1bd9319da8c1f13ef40cb8c7add9fb930cbe1', '2026-04-24 13:40:04.375+00', '2026-04-17 13:40:04.371847+00', '2026-04-17 13:42:30.366149+00');
INSERT INTO public.refresh_tokens VALUES (21, 1, 'cb4313b8a0c959da5fb8ab214614acf67814b9b918f549a1d053d54b4656f4e9', '2026-04-24 13:42:29.851+00', '2026-04-17 13:42:29.843747+00', '2026-04-17 13:42:42.820989+00');
INSERT INTO public.refresh_tokens VALUES (25, 1, 'b0b8037002f1158b18b8ce52d23ae735d20075f26d94b8bc3acb66106e640171', '2026-04-24 13:42:42.827+00', '2026-04-17 13:42:42.820989+00', '2026-04-17 13:44:43.768497+00');
INSERT INTO public.refresh_tokens VALUES (26, 1, 'e1f7874971820e48cc1b3c08404ba18cc507932ed4c9b13990e2daaa5c88c033', '2026-04-24 13:44:43.765+00', '2026-04-17 13:44:43.768497+00', '2026-04-17 13:44:51.712276+00');
INSERT INTO public.refresh_tokens VALUES (27, 1, '0510a2c9537a26b0364197797d3544753a6651dabc3971124c336b33fca5708f', '2026-04-24 13:44:51.709+00', '2026-04-17 13:44:51.712276+00', '2026-04-17 13:45:19.56619+00');
INSERT INTO public.refresh_tokens VALUES (28, 1, 'f913844ac6251a40c8aaf489ffe1ce7199ad1a5678aa074b99c5571c3858f2c0', '2026-04-24 13:45:19.57+00', '2026-04-17 13:45:19.56619+00', '2026-04-17 13:45:53.820276+00');
INSERT INTO public.refresh_tokens VALUES (22, 2, 'cf2c587b48d72b88a4005a3cf85aa5e12f6ea005cb17a64498255b83d897cc0d', '2026-04-24 13:42:30.032+00', '2026-04-17 13:42:30.025218+00', '2026-04-17 13:45:54.029751+00');
INSERT INTO public.refresh_tokens VALUES (23, 6, '710c092802a2da658dc69f337d1704a24a4301efcf2a3e8961eba820621707a2', '2026-04-24 13:42:30.209+00', '2026-04-17 13:42:30.201806+00', '2026-04-17 13:45:54.174364+00');
INSERT INTO public.refresh_tokens VALUES (24, 4, '3beed3fa1c212218927a3140d1d4e39f19ab0ae2ae2bdf1ae1bb84b6b8270eda', '2026-04-24 13:42:30.373+00', '2026-04-17 13:42:30.366149+00', '2026-04-17 13:45:54.335623+00');
INSERT INTO public.refresh_tokens VALUES (29, 1, '957b3a3aa3fa21099ad36ef073ef6355f0f35e0415ee5c0121c2b40424a7e462', '2026-04-24 13:45:53.814+00', '2026-04-17 13:45:53.820276+00', '2026-04-17 14:02:51.036734+00');
INSERT INTO public.refresh_tokens VALUES (30, 2, '4c965fd7d51d9772d6164a59f1fca8540f74b62b42e71c1749e8c01a25eb0f07', '2026-04-24 13:45:54.024+00', '2026-04-17 13:45:54.029751+00', '2026-04-17 14:02:51.1803+00');
INSERT INTO public.refresh_tokens VALUES (34, 2, '98572655397963e9810be387b47c96a2ec4a5a3ffc6ba81aa5cccb58df34f88c', '2026-04-24 14:02:51.178+00', '2026-04-17 14:02:51.1803+00', NULL);
INSERT INTO public.refresh_tokens VALUES (13, 5, '8bdb935a326c8600f7cdb2c1dd796db7d7f543be771d64bd1f9124f3cd36e9ee', '2026-04-24 12:57:42.689+00', '2026-04-17 12:57:42.691272+00', '2026-04-17 14:02:51.323539+00');
INSERT INTO public.refresh_tokens VALUES (35, 5, '745e998427f53303dfcdf61b57c35c507a065a329ca9703e515ffca957583998', '2026-04-24 14:02:51.321+00', '2026-04-17 14:02:51.323539+00', NULL);
INSERT INTO public.refresh_tokens VALUES (31, 6, 'b12060e24068b8cb18693b335b8c0e40ad1aa6800a90f809a747b7e282e9326b', '2026-04-24 13:45:54.169+00', '2026-04-17 13:45:54.174364+00', '2026-04-17 14:02:51.476242+00');
INSERT INTO public.refresh_tokens VALUES (36, 6, '9b3e177df8cf301a0ca357ddfddc6ffd5466a4d6868ba476742e89bcda6cc7a4', '2026-04-24 14:02:51.473+00', '2026-04-17 14:02:51.476242+00', NULL);
INSERT INTO public.refresh_tokens VALUES (32, 4, 'd9cacd304f0c544438308269ebad2ad2cd8e4891ad2e9d76943a78ea40ff5770', '2026-04-24 13:45:54.33+00', '2026-04-17 13:45:54.335623+00', '2026-04-17 14:02:51.61992+00');
INSERT INTO public.refresh_tokens VALUES (37, 4, '04dcfeb7d292ebbc196479ef4e470869a9370e8ca930e72a101468c357998b29', '2026-04-24 14:02:51.617+00', '2026-04-17 14:02:51.61992+00', NULL);
INSERT INTO public.refresh_tokens VALUES (33, 1, 'e4f396ea73e9cb16c24420e741a238d5474e559f222fbe4478d7d6b22883806a', '2026-04-24 14:02:51.033+00', '2026-04-17 14:02:51.036734+00', '2026-04-17 14:29:06.147098+00');
INSERT INTO public.refresh_tokens VALUES (38, 1, '145687286f81a7de0c7e6a7058954580f7ffc83ea3dbd66deb3e76a6d72ff4ae', '2026-04-24 14:29:06.13+00', '2026-04-17 14:29:06.147098+00', '2026-04-17 14:52:59.463872+00');
INSERT INTO public.refresh_tokens VALUES (39, 1, '7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2', '2026-04-24 14:52:59.485+00', '2026-04-17 14:52:59.487254+00', '2026-04-17 14:53:06.709806+00');
INSERT INTO public.refresh_tokens VALUES (40, 1, '7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2', '2026-04-24 14:52:59.485+00', '2026-04-17 14:52:59.487715+00', '2026-04-17 14:53:06.709806+00');
INSERT INTO public.refresh_tokens VALUES (41, 1, '7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2', '2026-04-24 14:52:59.483+00', '2026-04-17 14:52:59.48748+00', '2026-04-17 14:53:06.709806+00');
INSERT INTO public.refresh_tokens VALUES (42, 1, '7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2', '2026-04-24 14:52:59.486+00', '2026-04-17 14:52:59.487981+00', '2026-04-17 14:53:06.709806+00');
INSERT INTO public.refresh_tokens VALUES (43, 1, '7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2', '2026-04-24 14:52:59.486+00', '2026-04-17 14:52:59.488061+00', '2026-04-17 14:53:06.709806+00');
INSERT INTO public.refresh_tokens VALUES (44, 1, '7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2', '2026-04-24 14:52:59.485+00', '2026-04-17 14:52:59.487188+00', '2026-04-17 14:53:06.709806+00');
INSERT INTO public.refresh_tokens VALUES (45, 1, '9bcb270da5568512743d0ca158f403c2344858eda00ed5674b30fedcbdb2755f', '2026-04-24 14:53:06.707+00', '2026-04-17 14:53:06.709806+00', '2026-04-17 15:08:17.398058+00');
INSERT INTO public.refresh_tokens VALUES (46, 1, '71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580', '2026-04-24 15:08:17.415+00', '2026-04-17 15:08:17.416693+00', '2026-04-17 15:25:07.423914+00');
INSERT INTO public.refresh_tokens VALUES (47, 1, '71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580', '2026-04-24 15:08:17.416+00', '2026-04-17 15:08:17.417036+00', '2026-04-17 15:25:07.423914+00');
INSERT INTO public.refresh_tokens VALUES (48, 1, '71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580', '2026-04-24 15:08:17.415+00', '2026-04-17 15:08:17.415822+00', '2026-04-17 15:25:07.423914+00');
INSERT INTO public.refresh_tokens VALUES (49, 1, '71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580', '2026-04-24 15:08:17.413+00', '2026-04-17 15:08:17.415781+00', '2026-04-17 15:25:07.423914+00');
INSERT INTO public.refresh_tokens VALUES (50, 1, '71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580', '2026-04-24 15:08:17.415+00', '2026-04-17 15:08:17.416086+00', '2026-04-17 15:25:07.423914+00');
INSERT INTO public.refresh_tokens VALUES (51, 1, '71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580', '2026-04-24 15:08:17.415+00', '2026-04-17 15:08:17.416056+00', '2026-04-17 15:25:07.423914+00');
INSERT INTO public.refresh_tokens VALUES (53, 1, '4234db91737ea39a787313f5b05faf2a8cb8ce3557a6957c706413ccd9acdc97', '2026-04-24 15:25:07.456+00', '2026-04-17 15:25:07.455807+00', '2026-04-17 15:27:49.878779+00');
INSERT INTO public.refresh_tokens VALUES (52, 1, '4234db91737ea39a787313f5b05faf2a8cb8ce3557a6957c706413ccd9acdc97', '2026-04-24 15:25:07.456+00', '2026-04-17 15:25:07.456108+00', '2026-04-17 15:27:49.878779+00');
INSERT INTO public.refresh_tokens VALUES (55, 1, '4234db91737ea39a787313f5b05faf2a8cb8ce3557a6957c706413ccd9acdc97', '2026-04-24 15:25:07.456+00', '2026-04-17 15:25:07.45585+00', '2026-04-17 15:27:49.878779+00');
INSERT INTO public.refresh_tokens VALUES (54, 1, '4234db91737ea39a787313f5b05faf2a8cb8ce3557a6957c706413ccd9acdc97', '2026-04-24 15:25:07.457+00', '2026-04-17 15:25:07.456651+00', '2026-04-17 15:27:49.878779+00');
INSERT INTO public.refresh_tokens VALUES (56, 1, '8fb0210e108d998d03e761d1fdf13fe7b48db1a3fef207d191e90167b5187755', '2026-04-24 15:27:49.875+00', '2026-04-17 15:27:49.878779+00', '2026-04-17 15:28:46.547426+00');
INSERT INTO public.refresh_tokens VALUES (57, 1, 'f79537d05acf0086f63de3bbeadfa9dcf429ee7f22d7ddd39791806a77dd4230', '2026-04-24 15:28:46.543+00', '2026-04-17 15:28:46.547426+00', '2026-04-17 15:31:09.06777+00');
INSERT INTO public.refresh_tokens VALUES (58, 1, '8615195a8e7a069ae33078f6b2c443dc98a9f3f202c65738b53991a12d2a682e', '2026-04-24 15:31:09.058+00', '2026-04-17 15:31:09.06777+00', '2026-04-17 15:31:20.120726+00');
INSERT INTO public.refresh_tokens VALUES (59, 1, '3e69728bfd8a332a28ef2ba1b9d62a66ab97bface6c1f3fe62367c6499e1d386', '2026-04-24 15:31:20.113+00', '2026-04-17 15:31:20.120726+00', '2026-04-17 15:39:40.367368+00');
INSERT INTO public.refresh_tokens VALUES (60, 1, '977c2d367592bd08e6b98060b6d3382de1648ff07d6b75e23291ae4d77279180', '2026-04-24 15:39:40.365+00', '2026-04-17 15:39:40.367368+00', '2026-04-17 15:39:50.974951+00');
INSERT INTO public.refresh_tokens VALUES (61, 1, '6f2600c3f440f34141eacfb13ab688b3b964665466f006613641d637ad7c93e5', '2026-04-24 15:39:50.972+00', '2026-04-17 15:39:50.974951+00', '2026-04-17 15:40:33.30063+00');
INSERT INTO public.refresh_tokens VALUES (62, 1, '863682e25e27008fd8bc3506e3cfd86ab36ff11dd3ab9d31ef6a738d450e48b6', '2026-04-24 15:40:33.298+00', '2026-04-17 15:40:33.30063+00', '2026-04-17 15:43:45.018057+00');
INSERT INTO public.refresh_tokens VALUES (63, 1, '698fbc7f9060614ed930e4b006c12cfd11cf87ae74e8199d929cbb76a1a9ff2e', '2026-04-24 15:43:45.015+00', '2026-04-17 15:43:45.018057+00', '2026-04-17 15:44:34.870898+00');
INSERT INTO public.refresh_tokens VALUES (64, 1, '5cf69473cd6a65e4d13b17d894714b9a286965942069217365b2c08aa576b6c5', '2026-04-24 15:44:34.871+00', '2026-04-17 15:44:34.870898+00', '2026-04-17 15:44:58.298329+00');
INSERT INTO public.refresh_tokens VALUES (65, 1, 'a7ba79723612451ea6db5c05cbb40cb1bcf9230b74b95ef182808107045b4ea0', '2026-04-24 15:44:58.295+00', '2026-04-17 15:44:58.298329+00', '2026-04-17 15:45:08.021222+00');
INSERT INTO public.refresh_tokens VALUES (66, 1, '190234e7a23b65dbef870ecf7cf3a33358faf528f4520ebf6d0a1fd2de6bbdee', '2026-04-24 15:45:08.017+00', '2026-04-17 15:45:08.021222+00', '2026-04-17 15:47:12.009677+00');
INSERT INTO public.refresh_tokens VALUES (67, 1, '26ef405d27edb4f687e50266b98e62117d7dd2cf8b3ff8324517f72e8f6bcf53', '2026-04-24 15:47:12.009+00', '2026-04-17 15:47:12.009677+00', '2026-04-17 15:47:53.904432+00');
INSERT INTO public.refresh_tokens VALUES (68, 1, 'acd0d6ac38a62b89377e79af51671d5a233ba39af9cec34db60f67ff742a91eb', '2026-04-24 15:47:53.901+00', '2026-04-17 15:47:53.904432+00', '2026-04-17 15:48:02.037645+00');
INSERT INTO public.refresh_tokens VALUES (69, 1, 'ec352d1c0ad8716db8c92d65e7072c7074f2c12c87199e71ed7979ea4633ee5d', '2026-04-24 15:48:02.037+00', '2026-04-17 15:48:02.037645+00', '2026-04-17 15:50:51.857162+00');
INSERT INTO public.refresh_tokens VALUES (70, 1, '8c3a0d2b489d3db4296cafb30603aefc4c76bbe73d4e1c3c46434dca0fd83018', '2026-04-24 15:50:51.852+00', '2026-04-17 15:50:51.857162+00', '2026-04-17 15:51:45.115109+00');
INSERT INTO public.refresh_tokens VALUES (71, 1, '8156c1138d1915529bdb4b8b400e2c2fdaadd120fbba7d52b1d6b0edc9cb7fdc', '2026-04-24 15:51:45.113+00', '2026-04-17 15:51:45.115109+00', '2026-04-17 15:58:07.503911+00');
INSERT INTO public.refresh_tokens VALUES (72, 1, '5821d42d3ca65d7ccd3b7fadf0fc79af1079f5b2fd42837f1e824bbb1675a277', '2026-04-24 15:58:07.506+00', '2026-04-17 15:58:07.503911+00', '2026-04-17 16:03:48.293188+00');
INSERT INTO public.refresh_tokens VALUES (73, 1, '7aecb9b61da41dc86e72da086be24cbf64b7185a5c4a42f924d079bd0517c71f', '2026-04-24 16:03:48.292+00', '2026-04-17 16:03:48.293188+00', '2026-04-17 16:07:44.461949+00');
INSERT INTO public.refresh_tokens VALUES (74, 1, 'd720c873f264345eb369bde292895b3179aa97af3f51f4abc569d3aa9ea0144c', '2026-04-24 16:07:44.462+00', '2026-04-17 16:07:44.461949+00', '2026-04-17 16:09:32.865061+00');
INSERT INTO public.refresh_tokens VALUES (75, 1, '0d0fb646243a00b8acc7bdf888292ee18d20efa8da50c0c2e46b8f3ad7ecf8fd', '2026-04-24 16:09:32.864+00', '2026-04-17 16:09:32.865061+00', '2026-04-17 16:27:29.99433+00');
INSERT INTO public.refresh_tokens VALUES (76, 1, '92e43b9d54ed1df9cbce5c9684513c11bc43cf993714d46bde70b707285f3fb8', '2026-04-24 16:27:29.994+00', '2026-04-17 16:27:29.99433+00', '2026-04-17 16:44:26.828613+00');
INSERT INTO public.refresh_tokens VALUES (77, 1, '0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363', '2026-04-24 16:44:26.853+00', '2026-04-17 16:44:26.847283+00', '2026-04-17 16:45:29.615577+00');
INSERT INTO public.refresh_tokens VALUES (78, 1, '0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363', '2026-04-24 16:44:26.853+00', '2026-04-17 16:44:26.847832+00', '2026-04-17 16:45:29.615577+00');
INSERT INTO public.refresh_tokens VALUES (80, 1, '0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363', '2026-04-24 16:44:26.856+00', '2026-04-17 16:44:26.849535+00', '2026-04-17 16:45:29.615577+00');
INSERT INTO public.refresh_tokens VALUES (79, 1, '0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363', '2026-04-24 16:44:26.856+00', '2026-04-17 16:44:26.849579+00', '2026-04-17 16:45:29.615577+00');
INSERT INTO public.refresh_tokens VALUES (81, 1, '0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363', '2026-04-24 16:44:26.858+00', '2026-04-17 16:44:26.851514+00', '2026-04-17 16:45:29.615577+00');
INSERT INTO public.refresh_tokens VALUES (82, 1, '0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363', '2026-04-24 16:44:26.858+00', '2026-04-17 16:44:26.851578+00', '2026-04-17 16:45:29.615577+00');
INSERT INTO public.refresh_tokens VALUES (83, 1, 'e86d0a668a4547e32fdb242eb2097a30ee5980c6305c58becffe43ce934db666', '2026-04-24 16:45:29.613+00', '2026-04-17 16:45:29.615577+00', '2026-04-17 17:04:11.116847+00');
INSERT INTO public.refresh_tokens VALUES (86, 1, '11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64', '2026-04-24 17:04:11.136+00', '2026-04-17 17:04:11.138131+00', '2026-04-17 17:04:32.786422+00');
INSERT INTO public.refresh_tokens VALUES (85, 1, '11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64', '2026-04-24 17:04:11.133+00', '2026-04-17 17:04:11.13483+00', '2026-04-17 17:04:32.786422+00');
INSERT INTO public.refresh_tokens VALUES (87, 1, '11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64', '2026-04-24 17:04:11.136+00', '2026-04-17 17:04:11.138083+00', '2026-04-17 17:04:32.786422+00');
INSERT INTO public.refresh_tokens VALUES (84, 1, '11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64', '2026-04-24 17:04:11.135+00', '2026-04-17 17:04:11.136609+00', '2026-04-17 17:04:32.786422+00');
INSERT INTO public.refresh_tokens VALUES (88, 1, '11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64', '2026-04-24 17:04:11.132+00', '2026-04-17 17:04:11.133216+00', '2026-04-17 17:04:32.786422+00');
INSERT INTO public.refresh_tokens VALUES (89, 1, '11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64', '2026-04-24 17:04:11.139+00', '2026-04-17 17:04:11.140332+00', '2026-04-17 17:04:32.786422+00');
INSERT INTO public.refresh_tokens VALUES (90, 1, 'f41846e8b6891f4bef0205a3ca7603c5076835a115fe60f68cc94e7a54e26347', '2026-04-24 17:04:32.785+00', '2026-04-17 17:04:32.786422+00', '2026-04-17 18:41:43.982785+00');


ALTER TABLE public.refresh_tokens ENABLE TRIGGER ALL;

--
-- Data for Name: role_of_staff; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.role_of_staff DISABLE TRIGGER ALL;

INSERT INTO public.role_of_staff VALUES (2, 1, 5);
INSERT INTO public.role_of_staff VALUES (3, 1, 1);
INSERT INTO public.role_of_staff VALUES (4, 2, 1);
INSERT INTO public.role_of_staff VALUES (5, 2, 3);
INSERT INTO public.role_of_staff VALUES (6, 3, 1);
INSERT INTO public.role_of_staff VALUES (7, 3, 3);
INSERT INTO public.role_of_staff VALUES (8, 4, 1);
INSERT INTO public.role_of_staff VALUES (9, 4, 3);
INSERT INTO public.role_of_staff VALUES (10, 5, 4);
INSERT INTO public.role_of_staff VALUES (11, 5, 6);
INSERT INTO public.role_of_staff VALUES (12, 6, 2);
INSERT INTO public.role_of_staff VALUES (13, 7, 2);
INSERT INTO public.role_of_staff VALUES (14, 8, 2);
INSERT INTO public.role_of_staff VALUES (15, 9, 6);
INSERT INTO public.role_of_staff VALUES (16, 10, 2);


ALTER TABLE public.role_of_staff ENABLE TRIGGER ALL;

--
-- Data for Name: work_calendar; Type: TABLE DATA; Schema: public; Owner: -
--

ALTER TABLE public.work_calendar DISABLE TRIGGER ALL;

INSERT INTO public.work_calendar VALUES (1, '2026-04-30', 'Ngày Giải phóng miền Nam', true, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.work_calendar VALUES (2, '2026-05-01', 'Ngày Quốc tế Lao động', true, 1, '2026-04-17 12:09:34.966774+00');
INSERT INTO public.work_calendar VALUES (3, '2026-09-02', 'Ngày Quốc khánh', true, 1, '2026-04-17 12:09:34.966774+00');


ALTER TABLE public.work_calendar ENABLE TRIGGER ALL;

--
-- Name: contract_attachments_id_seq; Type: SEQUENCE SET; Schema: cont; Owner: -
--

SELECT pg_catalog.setval('cont.contract_attachments_id_seq', 1, false);


--
-- Name: contract_types_id_seq; Type: SEQUENCE SET; Schema: cont; Owner: -
--

SELECT pg_catalog.setval('cont.contract_types_id_seq', 4, true);


--
-- Name: contracts_id_seq; Type: SEQUENCE SET; Schema: cont; Owner: -
--

SELECT pg_catalog.setval('cont.contracts_id_seq', 4, true);


--
-- Name: attachment_drafting_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.attachment_drafting_docs_id_seq', 1, false);


--
-- Name: attachment_handling_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.attachment_handling_docs_id_seq', 1, false);


--
-- Name: attachment_incoming_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.attachment_incoming_docs_id_seq', 1, true);


--
-- Name: attachment_inter_incoming_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.attachment_inter_incoming_docs_id_seq', 1, false);


--
-- Name: attachment_outgoing_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.attachment_outgoing_docs_id_seq', 1, false);


--
-- Name: delegations_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.delegations_id_seq', 2, true);


--
-- Name: device_tokens_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.device_tokens_id_seq', 4, true);


--
-- Name: digital_signatures_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.digital_signatures_id_seq', 4, true);


--
-- Name: doc_books_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.doc_books_id_seq', 5, true);


--
-- Name: doc_columns_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.doc_columns_id_seq', 51, true);


--
-- Name: doc_fields_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.doc_fields_id_seq', 5, true);


--
-- Name: doc_flow_step_links_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.doc_flow_step_links_id_seq', 1, false);


--
-- Name: doc_flow_step_staff_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.doc_flow_step_staff_id_seq', 1, false);


--
-- Name: doc_flow_steps_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.doc_flow_steps_id_seq', 1, false);


--
-- Name: doc_flows_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.doc_flows_id_seq', 1, false);


--
-- Name: doc_types_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.doc_types_id_seq', 8, true);


--
-- Name: drafting_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.drafting_docs_id_seq', 5, true);


--
-- Name: email_templates_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.email_templates_id_seq', 3, true);


--
-- Name: handling_doc_links_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.handling_doc_links_id_seq', 8, true);


--
-- Name: handling_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.handling_docs_id_seq', 7, true);


--
-- Name: incoming_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.incoming_docs_id_seq', 8, true);


--
-- Name: inter_incoming_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.inter_incoming_docs_id_seq', 3, true);


--
-- Name: leader_notes_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.leader_notes_id_seq', 8, true);


--
-- Name: lgsp_config_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.lgsp_config_id_seq', 1, true);


--
-- Name: lgsp_organizations_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.lgsp_organizations_id_seq', 7, true);


--
-- Name: lgsp_tracking_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.lgsp_tracking_id_seq', 6, true);


--
-- Name: meeting_types_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.meeting_types_id_seq', 3, true);


--
-- Name: message_recipients_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.message_recipients_id_seq', 35, true);


--
-- Name: messages_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.messages_id_seq', 16, true);


--
-- Name: notice_reads_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.notice_reads_id_seq', 1, true);


--
-- Name: notices_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.notices_id_seq', 6, true);


--
-- Name: notification_logs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.notification_logs_id_seq', 10, true);


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.notification_preferences_id_seq', 24, true);


--
-- Name: opinion_handling_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.opinion_handling_docs_id_seq', 4, true);


--
-- Name: organizations_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.organizations_id_seq', 2, true);


--
-- Name: outgoing_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.outgoing_docs_id_seq', 6, true);


--
-- Name: room_schedule_attachments_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.room_schedule_attachments_id_seq', 1, false);


--
-- Name: room_schedule_staff_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.room_schedule_staff_id_seq', 20, true);


--
-- Name: room_schedule_votes_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.room_schedule_votes_id_seq', 1, false);


--
-- Name: room_schedules_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.room_schedules_id_seq', 4, true);


--
-- Name: rooms_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.rooms_id_seq', 3, true);


--
-- Name: send_doc_user_configs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.send_doc_user_configs_id_seq', 2, true);


--
-- Name: signers_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.signers_id_seq', 4, true);


--
-- Name: sms_templates_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.sms_templates_id_seq', 3, true);


--
-- Name: staff_handling_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.staff_handling_docs_id_seq', 15, true);


--
-- Name: staff_notes_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.staff_notes_id_seq', 7, true);


--
-- Name: user_drafting_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.user_drafting_docs_id_seq', 3, true);


--
-- Name: user_incoming_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.user_incoming_docs_id_seq', 42, true);


--
-- Name: user_outgoing_docs_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.user_outgoing_docs_id_seq', 27, true);


--
-- Name: work_group_members_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.work_group_members_id_seq', 8, true);


--
-- Name: work_groups_id_seq; Type: SEQUENCE SET; Schema: edoc; Owner: -
--

SELECT pg_catalog.setval('edoc.work_groups_id_seq', 2, true);


--
-- Name: borrow_request_records_id_seq; Type: SEQUENCE SET; Schema: esto; Owner: -
--

SELECT pg_catalog.setval('esto.borrow_request_records_id_seq', 2, true);


--
-- Name: borrow_requests_id_seq; Type: SEQUENCE SET; Schema: esto; Owner: -
--

SELECT pg_catalog.setval('esto.borrow_requests_id_seq', 2, true);


--
-- Name: document_archives_id_seq; Type: SEQUENCE SET; Schema: esto; Owner: -
--

SELECT pg_catalog.setval('esto.document_archives_id_seq', 4, true);


--
-- Name: fonds_id_seq; Type: SEQUENCE SET; Schema: esto; Owner: -
--

SELECT pg_catalog.setval('esto.fonds_id_seq', 3, true);


--
-- Name: records_id_seq; Type: SEQUENCE SET; Schema: esto; Owner: -
--

SELECT pg_catalog.setval('esto.records_id_seq', 5, true);


--
-- Name: warehouses_id_seq; Type: SEQUENCE SET; Schema: esto; Owner: -
--

SELECT pg_catalog.setval('esto.warehouses_id_seq', 4, true);


--
-- Name: document_categories_id_seq; Type: SEQUENCE SET; Schema: iso; Owner: -
--

SELECT pg_catalog.setval('iso.document_categories_id_seq', 5, true);


--
-- Name: documents_id_seq; Type: SEQUENCE SET; Schema: iso; Owner: -
--

SELECT pg_catalog.setval('iso.documents_id_seq', 6, true);


--
-- Name: action_of_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.action_of_role_id_seq', 68, true);


--
-- Name: calendar_events_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.calendar_events_id_seq', 11, true);


--
-- Name: communes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.communes_id_seq', 8, true);


--
-- Name: configurations_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.configurations_id_seq', 14, true);


--
-- Name: departments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.departments_id_seq', 10, true);


--
-- Name: districts_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.districts_id_seq', 10, true);


--
-- Name: login_history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.login_history_id_seq', 64, true);


--
-- Name: positions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.positions_id_seq', 6, true);


--
-- Name: provinces_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.provinces_id_seq', 10, true);


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.refresh_tokens_id_seq', 90, true);


--
-- Name: rights_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.rights_id_seq', 18, true);


--
-- Name: role_of_staff_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.role_of_staff_id_seq', 16, true);


--
-- Name: roles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.roles_id_seq', 6, true);


--
-- Name: seq_staff_code; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.seq_staff_code', 1001, true);


--
-- Name: staff_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.staff_id_seq', 10, true);


--
-- Name: work_calendar_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.work_calendar_id_seq', 3, true);


--
-- PostgreSQL database dump complete
--

-- Done.

