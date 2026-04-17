--
-- PostgreSQL database dump
--

\restrict aqCAIEULn3F8l7tK9vepLSezbuunMkcuGAAEZkMF5IvHhJJPkDP1cjVG1hWIbtV

-- Dumped from database version 16.13
-- Dumped by pg_dump version 16.13

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

COPY cont.contract_types (id, unit_id, parent_id, code, name, note, sort_order, created_user_id, created_date, modified_user_id, modified_date) FROM stdin;
1	1	0	CNTT	Hợp đồng CNTT	\N	1	1	2026-04-17 12:09:34.966774+00	\N	\N
2	1	0	XD	Hợp đồng xây dựng	\N	2	1	2026-04-17 12:09:34.966774+00	\N	\N
3	1	0	MUA	Hợp đồng mua sắm	\N	3	1	2026-04-17 12:09:34.966774+00	\N	\N
4	1	0	DV	Hợp đồng dịch vụ	\N	4	1	2026-04-17 12:09:34.966774+00	\N	\N
\.


--
-- Data for Name: contracts; Type: TABLE DATA; Schema: cont; Owner: -
--

COPY cont.contracts (id, code_index, contract_type_id, department_id, type_of_contract, contact_id, contact_name, unit_id, code, sign_date, input_date, receive_date, name, signer, number, ballot, marker, curator_name, currency, transporter, staff_id, note, status, amount, payment_amount, created_user_id, created_date, modified_user_id, modified_date) FROM stdin;
1	\N	1	8	0	\N	\N	1	HD-CNTT-2026-001	2026-01-15	2026-01-16	\N	Hợp đồng triển khai hệ thống e-Office v2.0	Quản trị Hệ thống	1	\N	\N	Bùi Thị Hương	VND	\N	8	Hợp đồng với đơn vị phát triển phần mềm	1	2.500.000.000	\N	1	2026-04-17 12:09:34.966774+00	\N	\N
2	\N	1	8	0	\N	\N	1	HD-CNTT-2026-002	2026-02-01	2026-02-02	\N	Hợp đồng bảo trì hạ tầng mạng UBND tỉnh năm 2026	Lê Văn Đức	2	\N	\N	Bùi Thị Hương	VND	\N	8	Bảo trì hệ thống mạng, máy chủ, thiết bị CNTT	1	800.000.000	\N	4	2026-04-17 12:09:34.966774+00	\N	\N
3	\N	3	9	0	\N	\N	1	HD-MUA-2026-001	2026-03-10	2026-03-11	\N	Hợp đồng mua sắm máy tính và thiết bị văn phòng	Phạm Văn Em	1	\N	\N	Vũ Thị Kim	VND	\N	9	Mua 50 bộ máy tính, 10 máy in cho các phòng ban	2	1.200.000.000	\N	5	2026-04-17 12:09:34.966774+00	\N	\N
4	\N	4	5	0	\N	\N	1	HD-DV-2026-001	2026-04-01	2026-04-02	\N	Hợp đồng dịch vụ vệ sinh trụ sở UBND tỉnh năm 2026	Phạm Văn Em	1	\N	\N	Vũ Thị Kim	VND	\N	9	Dịch vụ vệ sinh hàng ngày cho trụ sở UBND	0	360.000.000	\N	5	2026-04-17 12:09:34.966774+00	\N	\N
\.


--
-- Data for Name: contract_attachments; Type: TABLE DATA; Schema: cont; Owner: -
--

COPY cont.contract_attachments (id, contract_id, file_name, file_path, file_size, mime_type, created_user_id, created_date) FROM stdin;
\.


--
-- Data for Name: departments; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.departments (id, parent_id, code, name, name_en, short_name, abb_name, is_unit, level, sort_order, allow_doc_book, description, phone, fax, email, address, lgsp_system_id, lgsp_secret_key, is_locked, is_deleted, created_by, created_at, updated_by, updated_at) FROM stdin;
1	\N	UBND	UBND tỉnh Lào Cai	\N	UBND	\N	t	0	1	t	\N	\N	\N	\N	\N	\N	\N	f	f	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
2	1	SNV	Sở Nội vụ	\N	SNV	\N	t	1	2	t	\N	\N	\N	\N	\N	\N	\N	f	f	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
3	1	STC	Sở Tài chính	\N	STC	\N	t	1	3	t	\N	\N	\N	\N	\N	\N	\N	f	f	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
4	1	STTTT	Sở Thông tin và Truyền thông	\N	STTTT	\N	t	1	4	t	\N	\N	\N	\N	\N	\N	\N	f	f	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
5	1	VPUBND	Văn phòng UBND tỉnh	\N	VP	\N	t	1	5	t	\N	\N	\N	\N	\N	\N	\N	f	f	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
6	2	TCHC	Phòng Tổ chức - Hành chính	\N	TCHC	\N	f	2	1	f	\N	\N	\N	\N	\N	\N	\N	f	f	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
7	3	QLNS	Phòng Quản lý Ngân sách	\N	QLNS	\N	f	2	1	f	\N	\N	\N	\N	\N	\N	\N	f	f	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
8	4	CNTT	Phòng Công nghệ thông tin	\N	CNTT	\N	f	2	1	f	\N	\N	\N	\N	\N	\N	\N	f	f	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
9	5	TH	Phòng Tổng hợp	\N	TH	\N	f	2	1	f	\N	\N	\N	\N	\N	\N	\N	f	f	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
10	2	CCVC	Phòng Công chức - Viên chức	\N	CCVC	\N	f	2	2	f	\N	\N	\N	\N	\N	\N	\N	f	f	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: doc_books; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.doc_books (id, unit_id, type_id, name, description, sort_order, is_default, is_deleted, created_by, created_at) FROM stdin;
1	1	1	Sổ văn bản đến 2026	\N	1	t	f	1	2026-04-17 12:09:34.966774+00
2	1	2	Sổ văn bản đi 2026	\N	2	t	f	1	2026-04-17 12:09:34.966774+00
3	1	3	Sổ dự thảo 2026	\N	3	t	f	1	2026-04-17 12:09:34.966774+00
4	2	1	Sổ VB đến - Sở Nội vụ	\N	1	t	f	2	2026-04-17 12:09:34.966774+00
5	3	1	Sổ VB đến - Sở Tài chính	\N	1	t	f	3	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: doc_fields; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.doc_fields (id, unit_id, code, name, sort_order, is_active, created_at) FROM stdin;
1	1	HC	Hành chính	1	t	2026-04-17 12:09:34.966774+00
2	1	TC	Tài chính	2	t	2026-04-17 12:09:34.966774+00
3	1	NS	Nhân sự	3	t	2026-04-17 12:09:34.966774+00
4	1	CNTT	Công nghệ thông tin	4	t	2026-04-17 12:09:34.966774+00
5	1	XDCB	Xây dựng cơ bản	5	t	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: doc_types; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.doc_types (id, type_id, code, name, description, sort_order, notation_type, is_default, is_deleted, created_by, created_at, parent_id) FROM stdin;
1	2	CV	Công văn	\N	1	0	f	f	\N	2026-04-17 12:09:34.966774+00	\N
2	1	NQ	Nghị quyết	\N	2	0	f	f	\N	2026-04-17 12:09:34.966774+00	\N
3	1	QD	Quyết định	\N	3	0	f	f	\N	2026-04-17 12:09:34.966774+00	\N
4	1	CT	Chỉ thị	\N	4	0	f	f	\N	2026-04-17 12:09:34.966774+00	\N
5	1	QC	Quy chế	\N	5	0	f	f	\N	2026-04-17 12:09:34.966774+00	\N
6	2	TB	Thông báo	\N	6	0	f	f	\N	2026-04-17 12:09:34.966774+00	\N
7	2	BC	Báo cáo	\N	7	0	f	f	\N	2026-04-17 12:09:34.966774+00	\N
8	2	TTr	Tờ trình	\N	8	0	f	f	\N	2026-04-17 12:09:34.966774+00	\N
\.


--
-- Data for Name: positions; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.positions (id, name, code, sort_order, is_active, description, created_at, updated_at, is_leader, is_handle_document) FROM stdin;
1	Giám đốc	GD	1	t	\N	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00	f	f
2	Phó Giám đốc	PGD	2	t	\N	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00	f	f
3	Trưởng phòng	TP	3	t	\N	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00	f	f
4	Phó Trưởng phòng	PTP	4	t	\N	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00	f	f
5	Chuyên viên	CV	5	t	\N	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00	f	f
6	Văn thư	VT	6	t	\N	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00	f	f
\.


--
-- Data for Name: staff; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.staff (id, department_id, unit_id, position_id, username, password_hash, is_admin, first_name, last_name, gender, birth_date, email, phone, mobile, address, image, id_card, id_card_date, id_card_place, digital_cert, is_represent_unit, is_represent_department, is_locked, is_deleted, last_login_at, created_by, created_at, updated_by, updated_at, code, password_changed, sign_phone, sign_ca, sign_image) FROM stdin;
3	3	3	1	tranthib	$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi	f	Trần Thị	Bình	2	\N	tranthib@stc.laocai.gov.vn	02093801003	0912000003	\N	\N	\N	\N	\N	\N	f	f	f	f	\N	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00	NV003	f	\N	\N	\N
7	7	3	5	dangvang	$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi	f	Đặng Văn	Giang	1	\N	dangvang@stc.laocai.gov.vn	02093801007	0912000007	\N	\N	\N	\N	\N	\N	f	f	f	f	\N	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00	NV007	f	\N	\N	\N
8	8	4	5	buithih	$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi	f	Bùi Thị	Hương	2	\N	buithih@stttt.laocai.gov.vn	02093801008	0912000008	\N	\N	\N	\N	\N	\N	f	f	f	f	\N	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00	NV008	f	\N	\N	\N
9	9	5	6	vuthik	$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi	f	Vũ Thị	Kim	2	\N	vuthik@vpubnd.laocai.gov.vn	02093801009	0912000009	\N	\N	\N	\N	\N	\N	f	f	f	f	\N	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00	NV009	f	\N	\N	\N
10	10	2	4	dothil	$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi	f	Đỗ Thị	Lan	2	\N	dothil@snv.laocai.gov.vn	02093801010	0912000010	\N	\N	\N	\N	\N	\N	f	f	f	f	\N	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00	NV010	f	\N	\N	\N
1	1	1	1	admin	$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi	t	Quản trị	Hệ thống	1	\N	admin@laocai.gov.vn	02093801001	0912000001	\N	\N	\N	\N	\N	\N	f	f	f	f	2026-04-17 17:04:32.792886+00	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 17:04:32.792886+00	NV001	f	\N	\N	\N
2	2	2	1	nguyenvana	$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi	f	Nguyễn Văn	An	1	\N	nguyenvana@snv.laocai.gov.vn	02093801002	0912000002	\N	\N	\N	\N	\N	\N	f	f	f	f	2026-04-17 14:02:51.18476+00	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 14:02:51.18476+00	NV002	f	\N	\N	\N
5	5	5	3	phamvane	$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi	f	Phạm Văn	Em	1	\N	phamvane@vpubnd.laocai.gov.vn	02093801005	0912000005	\N	\N	\N	\N	\N	\N	f	f	f	f	2026-04-17 14:02:51.328656+00	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 14:02:51.328656+00	NV005	f	\N	\N	\N
6	6	2	5	hoangthif	$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi	f	Hoàng Thị	Phương	2	\N	hoangthif@snv.laocai.gov.vn	02093801006	0912000006	\N	\N	\N	\N	\N	\N	f	f	f	f	2026-04-17 14:02:51.481613+00	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 14:02:51.481613+00	NV006	f	\N	\N	\N
4	4	4	1	levand	$2b$10$xupDqmYXFYRiLmPdbB5N3uJPMdIG3Qz2xj.DN52R1hg1V.DeDxaQi	f	Lê Văn	Đức	1	\N	levand@stttt.laocai.gov.vn	02093801004	0912000004	\N	\N	\N	\N	\N	\N	f	f	f	f	2026-04-17 14:02:51.625175+00	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 14:02:51.625175+00	NV004	f	\N	\N	\N
\.


--
-- Data for Name: drafting_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.drafting_docs (id, unit_id, received_date, number, sub_number, notation, abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date, signer, sign_date, number_paper, number_copies, secret_id, urgent_id, recipients, doc_book_id, doc_type_id, doc_field_id, approved, is_released, released_date, created_by, created_at, updated_by, updated_at, approver, expired_date, document_code, reject_reason, extra_fields, department_id, rejected_by, rejection_reason) FROM stdin;
1	1	2026-04-12 12:09:34.966774+00	1	\N	DT-01/UBND	Dự thảo Quyết định ban hành Quy chế quản lý tài liệu điện tử	1	5	\N	\N	Quản trị Hệ thống	\N	1	1	1	1	Các Sở, ngành, UBND huyện/TX	3	3	1	t	t	\N	5	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	\N	\N	\N	\N	{}	5	\N	\N
2	1	2026-04-14 12:09:34.966774+00	2	\N	DT-02/UBND	Dự thảo Công văn triển khai ứng dụng chữ ký số trong cơ quan nhà nước	4	8	\N	\N	Lê Văn Đức	\N	1	1	1	2	Các Sở TT&TT, Sở Nội vụ	3	1	4	t	t	\N	8	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	\N	\N	\N	\N	{}	8	\N	\N
3	1	2026-04-16 12:09:34.966774+00	3	\N	DT-03/UBND	Dự thảo Báo cáo tình hình ứng dụng CNTT quý I/2026	4	4	\N	\N	Lê Văn Đức	\N	1	1	1	1	UBND tỉnh, Bộ TT&TT	3	7	4	f	f	\N	4	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	\N	\N	\N	\N	{}	4	\N	\N
4	2	2026-04-15 12:09:34.966774+00	1	\N	DT-01/SNV	Dự thảo Kế hoạch tuyển dụng viên chức sự nghiệp GD năm 2026	2	6	\N	\N	Nguyễn Văn An	\N	1	1	1	1	Sở GD&ĐT, UBND các huyện/TX	3	1	3	f	f	\N	6	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	\N	\N	\N	Cần bổ sung thêm chỉ tiêu tuyển dụng từ các đơn vị sự nghiệp	{}	6	\N	\N
5	1	2026-04-17 15:37:21.1+00	4	\N	tt	ttttt	1	1	\N	2026-04-17 15:37:37.8+00	ttt	2026-04-17 15:37:36.4+00	1	1	1	1	ttt	3	3	4	t	t	2026-04-17 15:38:23.669189+00	1	2026-04-17 15:37:48.000687+00	1	2026-04-17 15:38:23.669189+00	Quản trị Hệ thống	2026-04-17 15:37:39.4+00	tt	\N	{}	1	\N	\N
\.


--
-- Data for Name: attachment_drafting_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.attachment_drafting_docs (id, drafting_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at, description, is_ca, ca_date, signed_file_path) FROM stdin;
\.


--
-- Data for Name: handling_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.handling_docs (id, unit_id, department_id, name, abstract, comments, doc_notation, doc_type_id, doc_field_id, doc_book_id, start_date, end_date, received_date, curator, signer, status, sign_status, sign_date, progress, workflow_id, step, complete_user_id, complete_date, publish_unit_id, publish_name, drafting_unit_id, number, sub_number, notation, parent_id, root_id, is_from_doc, created_by, created_at, updated_by, updated_at) FROM stdin;
6	2	6	Chuẩn bị phương án tuyển dụng Sở Nội vụ	Phương án tuyển dụng năm 2026 theo CV-201/BNV	\N	\N	1	3	\N	2026-04-15 12:09:34.966774+00	2026-05-07 12:09:34.966774+00	\N	6	2	1	0	\N	40	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	2	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
1	1	1	Triển khai Chính phủ điện tử 2026-2030	Xử lý CV-101/UBND về triển khai CPĐT	\N	\N	1	4	\N	2026-04-16 12:09:34.966774+00	2026-05-17 12:09:34.966774+00	\N	4	1	1	0	\N	30	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:52:38.890685+00
2	1	1	Phê duyệt dự toán ngân sách 2026	Xử lý QĐ-102/STC về dự toán ngân sách	\N	\N	3	2	\N	2026-04-15 12:09:34.966774+00	2026-05-02 12:09:34.966774+00	\N	3	1	2	0	\N	60	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:52:38.890685+00
3	1	5	Tuyển dụng viên chức năm 2026	Xử lý CV-104/SNV về tuyển dụng viên chức	\N	\N	1	3	\N	2026-04-16 12:09:34.966774+00	2026-06-01 12:09:34.966774+00	\N	2	1	1	0	\N	20	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	5	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:52:38.890685+00
4	1	1	Chuyển đổi số quốc gia — triển khai tại tỉnh	Xử lý CT-106/TTg về CĐS quốc gia	\N	\N	4	4	\N	2026-04-17 12:09:34.966774+00	2026-06-16 12:09:34.966774+00	\N	4	1	0	0	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:52:38.890685+00
5	1	4	Soạn thảo báo cáo ứng dụng CNTT quý I/2026	Lập báo cáo tình hình ứng dụng CNTT	\N	\N	7	4	\N	2026-04-12 12:09:34.966774+00	2026-04-27 12:09:34.966774+00	\N	4	1	4	0	\N	100	\N	\N	4	2026-04-16 12:09:34.966774+00	\N	\N	\N	\N	\N	\N	\N	\N	f	4	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:52:38.890685+00
7	1	\N	Test CRUD VB den	\N	ttt	\N	\N	\N	\N	2026-04-17 00:00:00+00	2026-04-17 00:00:00+00	\N	2	\N	0	0	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	\N	t	1	2026-04-17 14:31:56.992542+00	\N	2026-04-17 14:31:56.992542+00
\.


--
-- Data for Name: attachment_handling_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.attachment_handling_docs (id, handling_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.incoming_docs (id, unit_id, received_date, number, notation, document_code, abstract, publish_unit, publish_date, signer, sign_date, doc_book_id, doc_type_id, doc_field_id, secret_id, urgent_id, number_paper, number_copies, expired_date, recipients, approver, approved, is_handling, is_received_paper, archive_status, is_inter_doc, inter_doc_id, created_by, created_at, updated_by, updated_at, sents, received_paper_date, extra_fields, department_id, rejected_by, rejection_reason) FROM stdin;
3	1	2026-04-14 12:09:34.966774+00	103	CV-103/STTTT	CV103	V/v rà soát hạ tầng CNTT các cơ quan nhà nước	Sở TT&TT	2026-04-13 12:09:34.966774+00	Lê Văn Đức	\N	1	1	4	1	1	2	1	\N	\N	\N	f	f	f	f	f	\N	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	Phòng CNTT	\N	{}	1	\N	\N
5	1	2026-04-13 12:09:34.966774+00	105	NQ-105/HDND	NQ105	Nghị quyết về chương trình giám sát năm 2026	HĐND tỉnh Lào Cai	2026-04-12 12:09:34.966774+00	Hoàng Văn Dũng	\N	1	2	1	1	1	8	2	\N	\N	\N	f	f	f	f	f	\N	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	UBND tỉnh Lào Cai	\N	{}	1	\N	\N
7	2	2026-04-15 12:09:34.966774+00	201	CV-201/BNV	CV201	V/v hướng dẫn thi nâng ngạch công chức năm 2026	Bộ Nội vụ	2026-04-14 12:09:34.966774+00	Phạm Thị Thanh Trà	\N	4	1	3	1	2	10	2	\N	\N	\N	f	f	f	f	f	\N	2	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	Phòng HC-QT	\N	{}	2	\N	\N
1	1	2026-04-16 12:09:34.966774+00	101	CV-101/UBND	CV101	V/v triển khai Chính phủ điện tử giai đoạn 2026-2030	Văn phòng Chính phủ	2026-04-15 12:09:34.966774+00	Trần Văn Sơn	\N	1	1	4	1	1	5	1	\N	\N	\N	f	t	f	f	f	\N	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	UBND tỉnh Lào Cai	\N	{}	1	\N	\N
2	1	2026-04-15 12:09:34.966774+00	102	QD-102/STC	QD102	Quyết định phê duyệt dự toán ngân sách năm 2026	Sở Tài chính	2026-04-14 12:09:34.966774+00	Trần Thị Bình	\N	1	3	2	1	2	3	2	\N	\N	\N	f	t	f	f	f	\N	1	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	Phòng Kế hoạch - Tài chính	\N	{}	1	\N	\N
4	1	2026-04-16 12:09:34.966774+00	104	CV-104/SNV	CV104	V/v tuyển dụng viên chức năm 2026	Sở Nội vụ	2026-04-15 12:09:34.966774+00	Nguyễn Văn An	\N	1	1	3	1	1	4	1	\N	\N	\N	f	t	f	f	f	\N	5	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	Phòng Tổ chức cán bộ	\N	{}	5	\N	\N
6	1	2026-04-17 12:09:34.966774+00	106	CT-106/TTg	CT106	Chỉ thị về đẩy mạnh chuyển đổi số quốc gia	Thủ tướng Chính phủ	2026-04-16 12:09:34.966774+00	Phạm Minh Chính	\N	1	4	4	1	3	6	3	\N	\N	Quản trị Hệ thống	t	f	f	t	f	\N	1	2026-04-17 12:09:34.966774+00	1	2026-04-17 15:05:50.150041+00	Văn phòng UBND tỉnh	\N	{}	1	\N	\N
8	1	2026-04-17 14:03:28.592+00	107	tttttttt	t	Test CRUD VB den	tttt	2026-04-17 14:30:50.3+00	t	2026-04-17 14:30:47.5+00	1	1	1	1	1	1	1	2026-04-17 14:30:51.8+00	t	Quản trị Hệ thống	t	f	f	t	f	\N	1	2026-04-17 14:03:28.592696+00	1	2026-04-17 15:27:21.740343+00	t	\N	{}	1	\N	\N
\.


--
-- Data for Name: attachment_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.attachment_incoming_docs (id, incoming_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at, description, is_ca, ca_date, signed_file_path) FROM stdin;
1	4	quy_uoc_chung.md	incoming/4/08645e01-80f0-413c-8038-bfab7cf12f1d.md	13550	application/octet-stream	0	1	2026-04-17 17:08:50.929598+00	\N	t	2026-04-17 17:08:58.673383+00	incoming/4/08645e01-80f0-413c-8038-bfab7cf12f1d.md
\.


--
-- Data for Name: inter_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.inter_incoming_docs (id, unit_id, received_date, notation, document_code, abstract, publish_unit, publish_date, signer, sign_date, expired_date, doc_type_id, status, source_system, external_doc_id, created_by, created_at, updated_at, organ_id, from_organ_id, number_paper, number_copies, secret_id, urgent_id, recipients, doc_field_id, department_id) FROM stdin;
1	1	2026-04-16 12:09:34.966774	LT-001/VPCP	LT001	V/v triển khai Đề án 06 về CSDL quốc gia dân cư	Văn phòng Chính phủ	2026-04-15	Trần Văn Sơn	\N	\N	1	pending	LGSP-TW	VPCP-2026-001	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	\N	\N	1	1	1	1	\N	\N	1
2	1	2026-04-14 12:09:34.966774	LT-002/BTTTT	LT002	V/v triển khai nền tảng LGSP tỉnh	Bộ TT&TT	2026-04-13	Nguyễn Mạnh Hùng	\N	\N	1	received	LGSP-TW	BTTTT-2026-015	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	\N	\N	1	1	1	1	\N	\N	1
3	1	2026-04-17 12:09:34.966774	LT-003/UBND-YB	LT003	V/v phối hợp xử lý văn bản liên thông Tây Bắc	UBND tỉnh Yên Bái	2026-04-16	Trần Huy Tuấn	\N	\N	1	pending	LGSP-YB	YB-2026-042	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	\N	\N	1	1	1	1	\N	\N	1
\.


--
-- Data for Name: attachment_inter_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.attachment_inter_incoming_docs (id, inter_incoming_doc_id, file_name, file_path, file_size, content_type, description, sort_order, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: outgoing_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.outgoing_docs (id, unit_id, received_date, number, sub_number, notation, document_code, abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date, signer, sign_date, expired_date, number_paper, number_copies, secret_id, urgent_id, recipients, doc_book_id, doc_type_id, doc_field_id, approved, is_handling, archive_status, is_inter_doc, inter_doc_id, is_digital_signed, created_by, created_at, updated_by, updated_at, approver, extra_fields, department_id, rejected_by, rejection_reason) FROM stdin;
3	1	2026-04-16 12:09:34.966774+00	203	\N	CV-203/UBND	CV203	Công văn về việc tăng cường an toàn thông tin mạng cơ quan nhà nước	4	4	1	2026-04-16 12:09:34.966774+00	Lê Văn Đức	2026-04-16 12:09:34.966774+00	\N	1	1	1	2	Các Sở, Ban, ngành	2	1	4	t	f	f	f	\N	0	4	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	\N	{}	4	\N	\N
4	2	2026-04-17 12:09:34.966774+00	101	\N	CV-101/SNV	CV101S	Công văn hướng dẫn thực hiện chế độ báo cáo thống kê ngành nội vụ	2	10	2	2026-04-17 12:09:34.966774+00	Nguyễn Văn An	2026-04-17 12:09:34.966774+00	\N	1	1	1	1	Phòng Nội vụ các huyện/thành phố	2	1	3	t	f	f	f	\N	0	2	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	\N	{}	2	\N	\N
1	1	2026-04-13 12:09:34.966774+00	201	\N	QD-201/UBND	QD201	Quyết định ban hành Quy chế quản lý tài liệu điện tử tỉnh Lào Cai	1	5	1	2026-04-13 12:09:34.966774+00	Quản trị Hệ thống	2026-04-13 12:09:34.966774+00	\N	1	1	1	1	Các Sở, ngành, UBND huyện/TX	2	3	1	t	f	f	f	\N	1	5	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	\N	{}	5	\N	\N
2	1	2026-04-15 12:09:34.966774+00	202	\N	CV-202/UBND	CV202	Công văn triển khai ứng dụng chữ ký số trong cơ quan nhà nước	4	8	1	2026-04-15 12:09:34.966774+00	Lê Văn Đức	2026-04-15 12:09:34.966774+00	\N	1	1	1	2	Các Sở TT&TT, Sở Nội vụ	2	1	4	t	f	f	f	\N	1	8	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:34:37.287276+00	\N	{}	8	\N	\N
6	1	2026-04-17 15:37:21.1+00	4	\N	tt	tt	ttttt	1	1	\N	2026-04-17 15:37:37.8+00	ttt	2026-04-17 15:37:36.4+00	2026-04-17 15:37:39.4+00	1	1	1	1	ttt	3	3	4	t	f	f	f	\N	0	1	2026-04-17 15:38:23.669189+00	1	2026-04-17 15:38:23.669189+00	Quản trị Hệ thống	{}	\N	\N	\N
5	1	2026-04-17 15:09:30.008+00	204	\N	tttttt	\N	tttttt	1	1	1	2026-04-17 15:09:58.2+00	ttt	2026-04-17 15:09:55.7+00	\N	1	1	1	1	ttt	2	1	1	f	f	f	f	\N	0	1	2026-04-17 15:10:09.4589+00	1	2026-04-17 15:38:43.229478+00	Quản trị Hệ thống	{}	1	1	ko
\.


--
-- Data for Name: attachment_outgoing_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.attachment_outgoing_docs (id, outgoing_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at, description, is_ca, ca_date, signed_file_path) FROM stdin;
\.


--
-- Data for Name: delegations; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.delegations (id, from_staff_id, to_staff_id, start_date, end_date, note, is_revoked, revoked_at, created_at) FROM stdin;
1	2	10	2026-04-10	2026-04-20	Ủy quyền xử lý văn bản khi đi công tác	f	\N	2026-04-17 12:09:34.966774+00
2	3	7	2026-04-15	2026-04-25	Ủy quyền ký văn bản trong thời gian nghỉ phép	f	\N	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: device_tokens; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.device_tokens (id, staff_id, device_token, device_type, is_active, created_at, updated_at) FROM stdin;
1	1	fcm-token-admin-web-abc123def456	web	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
2	2	fcm-token-nguyenvana-android-xyz789	android	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
3	4	fcm-token-levand-web-ghi012jkl345	web	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
4	5	fcm-token-phamvane-ios-mno678pqr901	ios	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: digital_signatures; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.digital_signatures (id, doc_id, doc_type, staff_id, sign_method, certificate_serial, certificate_subject, certificate_issuer, signed_file_path, original_file_path, sign_status, error_message, signed_at, created_at) FROM stdin;
1	1	outgoing	1	smart_ca	CERT-SMARTCA-001	CN=Quản trị Hệ thống, O=UBND tỉnh Lào Cai	VNPT-CA	signed/QD-201-signed.pdf	original/QD-201.pdf	signed	\N	2026-04-13 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
2	2	outgoing	4	smart_ca	CERT-SMARTCA-004	CN=Lê Văn Đức, O=Sở TT&TT Lào Cai	VNPT-CA	signed/CV-202-signed.pdf	original/CV-202.pdf	signed	\N	2026-04-15 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
3	3	outgoing	4	esign_neac	CERT-NEAC-004	CN=Lê Văn Đức, O=Sở TT&TT Lào Cai	NEAC-CA	\N	original/CV-203.pdf	pending	\N	\N	2026-04-17 12:09:34.966774+00
4	1	drafting	5	smart_ca	CERT-SMARTCA-005	CN=Phạm Văn Em, O=VP UBND tỉnh Lào Cai	VNPT-CA	signed/DT-01-signed.pdf	original/DT-01.pdf	signed	\N	2026-04-12 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: doc_columns; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.doc_columns (id, type_id, column_name, label, is_mandatory, is_show_all, sort_order, description, created_at, data_type, max_length, is_system) FROM stdin;
47	1	old_notation	Số hiệu cũ	f	t	1	Số hiệu từ hệ thống cũ (nếu có)	2026-04-17 12:09:34.966774+00	text	100	f
48	2	effective_from	Hiệu lực từ ngày	f	t	1	Ngày bắt đầu có hiệu lực	2026-04-17 12:09:34.966774+00	date	\N	f
49	2	effective_to	Hiệu lực đến ngày	f	t	2	Ngày hết hiệu lực	2026-04-17 12:09:34.966774+00	date	\N	f
50	3	review_deadline	Hạn góp ý	f	t	1	Hạn chót gửi ý kiến góp ý	2026-04-17 12:09:34.966774+00	date	\N	f
51	3	version_number	Số phiên bản	f	t	2	Phiên bản dự thảo (VD: 1, 2, 3)	2026-04-17 12:09:34.966774+00	number	\N	f
\.


--
-- Data for Name: doc_flows; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.doc_flows (id, unit_id, name, version, doc_field_id, is_active, created_by, created_at, updated_at, department_id) FROM stdin;
\.


--
-- Data for Name: doc_flow_steps; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.doc_flow_steps (id, flow_id, step_name, step_order, step_type, allow_sign, deadline_days, position_x, position_y, created_at) FROM stdin;
\.


--
-- Data for Name: doc_flow_step_links; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.doc_flow_step_links (id, from_step_id, to_step_id, created_at) FROM stdin;
\.


--
-- Data for Name: doc_flow_step_staff; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.doc_flow_step_staff (id, step_id, staff_id, created_at) FROM stdin;
\.


--
-- Data for Name: email_templates; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.email_templates (id, unit_id, name, subject, content, description, is_active, created_by, created_at) FROM stdin;
1	1	Thông báo VB đến mới	Văn bản đến mới: {doc_code}	<p>Kính gửi <strong>{staff_name}</strong>,</p><p>Bạn nhận được văn bản đến mới số <strong>{doc_code}</strong> ngày {doc_date}.</p><p>Trích yếu: {abstract}</p><p>Vui lòng đăng nhập hệ thống e-Office để xử lý.</p><p>Trân trọng,<br/>Hệ thống e-Office</p>	Email thông báo VB đến mới	t	1	2026-04-17 12:09:34.966774+00
2	1	Nhắc nhở hạn xử lý	Nhắc nhở: VB {doc_code} sắp hết hạn	<p>Kính gửi <strong>{staff_name}</strong>,</p><p>Văn bản số <strong>{doc_code}</strong> có hạn xử lý đến <strong>{deadline}</strong>.</p><p>Vui lòng hoàn thành xử lý trước thời hạn.</p><p>Trân trọng,<br/>Hệ thống e-Office</p>	Email nhắc hạn xử lý	t	1	2026-04-17 12:09:34.966774+00
3	1	Thông báo cuộc họp	Mời họp: {meeting_title}	<p>Kính gửi <strong>{staff_name}</strong>,</p><p>Bạn được mời tham dự cuộc họp:</p><ul><li>Tiêu đề: <strong>{meeting_title}</strong></li><li>Thời gian: {meeting_time}</li><li>Phòng họp: {meeting_room}</li></ul><p>Vui lòng xác nhận tham dự trên hệ thống.</p><p>Trân trọng,<br/>Hệ thống e-Office</p>	Email mời họp	t	1	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: handling_doc_links; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.handling_doc_links (id, handling_doc_id, doc_type, doc_id, created_at) FROM stdin;
1	1	incoming	1	2026-04-17 12:09:34.966774+00
2	2	incoming	2	2026-04-17 12:09:34.966774+00
3	3	incoming	4	2026-04-17 12:09:34.966774+00
4	4	incoming	6	2026-04-17 12:09:34.966774+00
5	5	outgoing	3	2026-04-17 12:09:34.966774+00
6	6	incoming	7	2026-04-17 12:09:34.966774+00
7	7	incoming	8	2026-04-17 14:31:56.992542+00
8	4	incoming	8	2026-04-17 14:33:44.834562+00
\.


--
-- Data for Name: leader_notes; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.leader_notes (id, incoming_doc_id, staff_id, content, created_at, outgoing_doc_id, drafting_doc_id, expired_date, assigned_staff_ids) FROM stdin;
1	1	1	Giao Sở TT&TT chủ trì, phối hợp các đơn vị triển khai. Hạn: 30/04/2026.	2026-04-17 12:09:34.966774+00	\N	\N	\N	\N
2	2	1	Đồng ý dự toán. Sở TC theo dõi triển khai.	2026-04-17 12:09:34.966774+00	\N	\N	\N	\N
3	4	2	Phòng TCHC chuẩn bị phương án tuyển dụng, báo cáo trước 20/04.	2026-04-17 12:09:34.966774+00	\N	\N	\N	\N
4	\N	1	Duyệt nội dung. Phát hành ngay.	2026-04-17 12:09:34.966774+00	\N	1	\N	\N
5	\N	2	Cần bổ sung số liệu quý I trước khi trình.	2026-04-17 12:09:34.966774+00	\N	3	\N	\N
6	\N	1	Ban hành đúng tiến độ. Giao Sở TT&TT hướng dẫn thực hiện.	2026-04-17 12:09:34.966774+00	1	\N	\N	\N
7	\N	2	Đẩy mạnh triển khai chữ ký số tại các đơn vị trực thuộc.	2026-04-17 12:09:34.966774+00	2	\N	\N	\N
8	8	1	ok	2026-04-17 14:58:49.535711+00	\N	\N	\N	{2,3}
\.


--
-- Data for Name: lgsp_config; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.lgsp_config (id, unit_id, endpoint_url, org_code, username, password_encrypted, polling_interval_sec, is_active, last_sync_at, created_at) FROM stdin;
1	1	https://lgsp.laocai.gov.vn/api	UBND_LC	admin_lgsp	\N	300	t	\N	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: lgsp_organizations; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.lgsp_organizations (id, org_code, org_name, parent_code, address, email, phone, is_active, synced_at, created_at) FROM stdin;
1	BNV	Bộ Nội vụ	\N	Số 8 Tôn Thất Thuyết, Hà Nội	bnv@chinhphu.vn	024.38240101	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
2	BTTTT	Bộ Thông tin và Truyền thông	\N	Số 18 Nguyễn Du, Hà Nội	btttt@mic.gov.vn	024.39437010	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
3	BTC	Bộ Tài chính	\N	Số 28 Trần Hưng Đạo, Hà Nội	btc@mof.gov.vn	024.22202828	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
4	UBND-YB	UBND tỉnh Yên Bái	\N	Đường Yên Ninh, TP Yên Bái	ubnd@yenbai.gov.vn	02163852223	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
5	UBND-HP	UBND tỉnh Hải Phòng	\N	Số 18 Hoàng Diệu, Hải Phòng	ubnd@haiphong.gov.vn	02253842658	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
6	VPCP	Văn phòng Chính phủ	\N	Số 1 Hoàng Hoa Thám, Hà Nội	vpcp@chinhphu.vn	024.08043100	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
7	UBND-LC	UBND tỉnh Lào Cai	\N	Đường Hoàng Liên, TP Lào Cai	ubnd@laocai.gov.vn	02143840888	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: lgsp_tracking; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.lgsp_tracking (id, outgoing_doc_id, incoming_doc_id, direction, lgsp_doc_id, dest_org_code, dest_org_name, edxml_content, status, error_message, sent_at, received_at, created_at, created_by) FROM stdin;
1	1	\N	send	LGSP-LC-2026-0001	BNV	Bộ Nội vụ	\N	success	\N	2026-04-13 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00	1
2	2	\N	send	LGSP-LC-2026-0002	BTTTT	Bộ Thông tin và Truyền thông	\N	success	\N	2026-04-15 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00	1
3	\N	1	receive	LGSP-TW-2026-0101	VPCP	Văn phòng Chính phủ	\N	success	\N	\N	2026-04-16 12:09:34.966774+00	2026-04-17 12:09:34.966774+00	1
4	3	\N	send	LGSP-LC-2026-0003	UBND-YB	UBND tỉnh Yên Bái	\N	pending	\N	2026-04-16 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00	4
5	\N	7	receive	LGSP-TW-2026-0205	BNV	Bộ Nội vụ	\N	success	\N	\N	2026-04-15 12:09:34.966774+00	2026-04-17 12:09:34.966774+00	1
6	\N	8	send	\N	BNV	Bộ Nội vụ	\N	pending	\N	\N	\N	2026-04-17 14:33:57.903341+00	1
\.


--
-- Data for Name: meeting_types; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.meeting_types (id, unit_id, name, description, sort_order, is_deleted, created_user_id, created_date, modified_user_id, modified_date) FROM stdin;
1	1	Họp giao ban	Họp giao ban định kỳ	1	f	1	2026-04-17 12:09:34.966774+00	\N	\N
2	1	Họp chuyên đề	Họp theo chuyên đề cụ thể	2	f	1	2026-04-17 12:09:34.966774+00	\N	\N
3	1	Họp Ban lãnh đạo	Họp nội bộ Ban lãnh đạo	3	f	1	2026-04-17 12:09:34.966774+00	\N	\N
\.


--
-- Data for Name: messages; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.messages (id, from_staff_id, subject, content, parent_id, created_at, sender_deleted, sender_deleted_at) FROM stdin;
1	1	Họp giao ban tuần 15	Kính gửi các đồng chí, cuộc họp giao ban tuần 15 sẽ diễn ra vào 8h00 thứ Hai ngày 14/04/2026 tại phòng họp A.	\N	2026-04-17 12:09:34.966774	f	\N
2	3	Báo cáo tiến độ dự án CĐS	Anh/chị cho em xin báo cáo tiến độ dự án Chuyển đổi số đến hết tuần 14.	\N	2026-04-17 12:09:34.966774	f	\N
3	1	Thông báo lịch nghỉ lễ 30/4-1/5	Thông báo đến toàn thể CBCC: Lịch nghỉ lễ từ 30/04 đến 01/05/2026.	\N	2026-04-17 12:09:34.966774	f	\N
4	4	Đề xuất nâng cấp hệ thống mạng	Kính gửi BGĐ, em xin đề xuất phương án nâng cấp hạ tầng mạng nội bộ.	\N	2026-04-17 12:09:34.966774	f	\N
5	1	Phân công nhiệm vụ Sprint 5	Phân công chi tiết nhiệm vụ Sprint 5 — Module HSCV cho từng thành viên.	\N	2026-04-17 12:09:34.966774	f	\N
6	8	Báo lỗi chức năng tìm kiếm VB	Anh ơi, em phát hiện lỗi tìm kiếm VB đến với từ khóa tiếng Việt có dấu.	\N	2026-04-17 12:09:34.966774	f	\N
7	1	Re: Báo lỗi chức năng tìm kiếm VB	Cảm ơn em đã báo, anh đã ghi nhận và sẽ xử lý trong Sprint tiếp theo.	6	2026-04-17 12:09:34.966774	f	\N
8	1	Kế hoạch demo cuối tuần	Kế hoạch demo e-Office cho BLĐ ngày 18-19/04/2026. Các phòng ban chuẩn bị dữ liệu demo.	\N	2026-04-17 12:09:34.966774	f	\N
10	1	Re: hi	hehe	9	2026-04-17 15:47:34.014389	f	\N
11	1	Re: Báo cáo tiến độ dự án CĐS	he	2	2026-04-17 15:47:41.701511	f	\N
12	1	Re: Báo cáo tiến độ dự án CĐS	test reply	2	2026-04-17 15:47:53.974244	f	\N
14	1	Re: test	ok	13	2026-04-17 15:49:57.192008	f	\N
15	1	Re: Báo cáo tiến độ dự án CĐS	ko	2	2026-04-17 15:50:02.702821	f	\N
16	1	t	t	\N	2026-04-17 15:50:21.657516	t	2026-04-17 16:01:26.786731+00
13	1	test	test msg	\N	2026-04-17 15:47:54.026433	t	2026-04-17 16:01:30.78705+00
9	1	hi	hi	\N	2026-04-17 15:47:21.49242	t	2026-04-17 16:05:03.092654+00
\.


--
-- Data for Name: message_recipients; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.message_recipients (id, message_id, staff_id, is_read, read_at, is_deleted, deleted_at) FROM stdin;
1	1	2	t	\N	f	\N
2	1	3	t	\N	f	\N
3	1	4	t	\N	f	\N
4	1	5	f	\N	f	\N
6	3	2	f	\N	f	\N
7	3	3	f	\N	f	\N
8	3	4	f	\N	f	\N
9	3	5	f	\N	f	\N
10	3	6	f	\N	f	\N
11	3	7	f	\N	f	\N
12	3	8	f	\N	f	\N
13	3	9	f	\N	f	\N
14	3	10	f	\N	f	\N
16	5	4	t	\N	f	\N
17	5	8	t	\N	f	\N
18	6	1	t	\N	f	\N
19	7	8	t	\N	f	\N
20	8	2	f	\N	f	\N
21	8	3	f	\N	f	\N
22	8	4	f	\N	f	\N
23	8	5	t	\N	f	\N
24	9	2	f	\N	f	\N
25	9	3	f	\N	f	\N
26	10	1	f	\N	f	\N
27	10	2	f	\N	f	\N
28	10	3	f	\N	f	\N
29	11	3	f	\N	f	\N
30	12	3	f	\N	f	\N
31	13	2	f	\N	f	\N
32	14	1	f	\N	f	\N
33	14	2	f	\N	f	\N
34	15	3	f	\N	f	\N
35	16	2	f	\N	f	\N
15	4	1	t	\N	f	\N
\.


--
-- Data for Name: notices; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.notices (id, unit_id, title, content, notice_type, created_by, created_at, department_id) FROM stdin;
1	\N	Hệ thống e-Office chính thức hoạt động	Hệ thống Quản lý văn bản điện tử e-Office triển khai từ 14/04/2026. Đề nghị toàn thể CBCC sử dụng hệ thống mới.	system	1	2026-04-17 12:09:34.966774	1
2	\N	Bảo trì hệ thống ngày 15/04/2026	Hệ thống tạm ngưng từ 22h00 đến 23h00 ngày 15/04/2026 để nâng cấp và bảo trì.	maintenance	1	2026-04-17 12:09:34.966774	1
3	\N	Cập nhật phiên bản v2.0 — Module mới	Tính năng mới: Họp không giấy, Kho lưu trữ, Tài liệu, Hợp đồng, LGSP, Ký số.	update	1	2026-04-17 12:09:34.966774	1
4	\N	Hướng dẫn sử dụng module Ký số điện tử	Tài liệu hướng dẫn ký số đã được cập nhật tại mục Tài liệu chung.	guide	1	2026-04-17 12:09:34.966774	1
5	\N	Nhắc nhở đổi mật khẩu định kỳ	Đề nghị toàn bộ CBCC đổi mật khẩu 3 tháng/lần để đảm bảo an toàn thông tin.	security	1	2026-04-17 12:09:34.966774	1
6	\N	Demo hệ thống cho Ban lãnh đạo 18-19/04	Các phòng ban chuẩn bị dữ liệu demo. Lịch demo: Buổi sáng 18/04 — module VB, buổi chiều — module HSCV và Họp.	important	1	2026-04-17 12:09:34.966774	1
\.


--
-- Data for Name: notice_reads; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.notice_reads (id, notice_id, staff_id, read_at) FROM stdin;
1	1	1	2026-04-17 15:58:15.861662
\.


--
-- Data for Name: notification_logs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.notification_logs (id, staff_id, channel, event_type, title, body, ref_type, ref_id, send_status, error_message, sent_at, created_at) FROM stdin;
1	2	fcm	incoming_doc_assigned	Văn bản đến mới	Bạn được giao xử lý CV-101/UBND: V/v triển khai Chính phủ điện tử	incoming_doc	1	sent	\N	2026-04-16 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
2	4	fcm	incoming_doc_assigned	Văn bản đến mới	Bạn được giao xử lý CV-101/UBND: V/v triển khai Chính phủ điện tử	incoming_doc	1	sent	\N	2026-04-16 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
3	3	email	incoming_doc_assigned	Văn bản đến mới — QD-102/STC	Bạn được giao xử lý QĐ-102/STC: Quyết định phê duyệt dự toán ngân sách năm 2026	incoming_doc	2	sent	\N	2026-04-15 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
4	4	sms	handling_doc_deadline	Nhắc hạn xử lý	HSCV "Triển khai CPĐT 2026-2030" sắp đến hạn (30 ngày). Tiến độ: 30%.	handling_doc	1	sent	\N	2026-04-17 00:09:34.966774+00	2026-04-17 12:09:34.966774+00
5	8	fcm	handling_doc_assigned	Phối hợp HSCV	Bạn được giao phối hợp HSCV "Triển khai CPĐT 2026-2030".	handling_doc	1	sent	\N	2026-04-16 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
6	1	zalo	meeting_reminder	Nhắc lịch họp	Họp triển khai CĐS tỉnh — 09:00 ngày 15/04/2026 tại Phòng họp A.	room_schedule	2	sent	\N	2026-04-17 06:09:34.966774+00	2026-04-17 12:09:34.966774+00
7	2	email	meeting_invitation	Mời họp giao ban tuần 15	Bạn được mời tham dự Họp giao ban tuần 15/2026, 08:00 ngày 14/04/2026.	room_schedule	1	sent	\N	2026-04-15 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
8	6	fcm	delegation_created	Ủy quyền mới	Bạn được ủy quyền xử lý văn bản từ Nguyễn Văn An (10/04 - 20/04/2026).	delegation	1	sent	\N	2026-04-13 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
9	7	sms	delegation_created	Ủy quyền mới	Bạn được ủy quyền ký văn bản từ Trần Thị Bình (15/04 - 25/04/2026).	delegation	2	sent	\N	2026-04-17 00:09:34.966774+00	2026-04-17 12:09:34.966774+00
10	4	fcm	digital_sign_pending	Yêu cầu ký số	VB đi CV-203/UBND cần ký số. Vui lòng ký để hoàn thành phát hành.	outgoing_doc	3	sent	\N	2026-04-16 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: notification_preferences; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.notification_preferences (id, staff_id, channel, is_enabled, created_at, updated_at) FROM stdin;
1	1	fcm	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
2	1	email	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
3	1	zalo	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
4	1	sms	f	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
5	2	fcm	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
6	2	email	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
7	2	zalo	f	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
8	2	sms	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
9	3	fcm	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
10	3	email	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
11	3	zalo	f	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
12	3	sms	f	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
13	4	fcm	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
14	4	email	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
15	4	zalo	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
16	4	sms	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
17	5	fcm	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
18	5	email	f	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
19	5	zalo	f	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
20	5	sms	f	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
21	8	fcm	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
22	8	email	t	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
23	8	zalo	f	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
24	8	sms	f	2026-04-17 12:09:34.966774+00	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: opinion_handling_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.opinion_handling_docs (id, handling_doc_id, staff_id, content, attachment_path, created_at) FROM stdin;
1	1	4	Đã liên hệ Cục CNTT - Bộ TT&TT để xin hướng dẫn chi tiết.	\N	2026-04-17 12:09:34.966774+00
2	1	8	Đề xuất tổ chức hội thảo triển khai CĐS cấp tỉnh.	\N	2026-04-17 12:09:34.966774+00
3	2	3	Dự toán phù hợp, đề nghị phê duyệt.	\N	2026-04-17 12:09:34.966774+00
4	5	4	Báo cáo đã hoàn thành, gửi BGĐ phê duyệt.	\N	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: organizations; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.organizations (id, unit_id, code, name, address, phone, fax, email, email_doc, secretary, chairman_number, level, is_exchange, lgsp_system_id, lgsp_secret_key, updated_by, updated_at) FROM stdin;
1	1	UBND-LC	UBND tỉnh Lào Cai	Đường Hoàng Liên, TP Lào Cai	02143840888	\N	ubnd@laocai.gov.vn	\N	Vũ Thị Kim	\N	1	f	\N	\N	\N	2026-04-17 12:09:34.966774+00
2	2	SNV-LC	Sở Nội vụ tỉnh Lào Cai	123 Trần Phú, TP Lào Cai	02143840102	\N	snv@laocai.gov.vn	\N	Đỗ Thị Lan	\N	2	f	\N	\N	\N	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: rooms; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.rooms (id, unit_id, name, code, location, note, sort_order, show_in_calendar, is_deleted, created_user_id, created_date, modified_user_id, modified_date) FROM stdin;
1	1	Phòng họp A — Tầng 3	PH-A	Tầng 3, Trụ sở UBND tỉnh	Sức chứa 50 người, có máy chiếu	1	t	f	1	2026-04-17 12:09:34.966774+00	\N	\N
2	1	Phòng họp B — Tầng 2	PH-B	Tầng 2, Trụ sở UBND tỉnh	Sức chứa 20 người, có TV lớn	2	t	f	1	2026-04-17 12:09:34.966774+00	\N	\N
3	1	Hội trường lớn	HT	Tầng 1, Trụ sở UBND tỉnh	Sức chứa 200 người	3	t	f	1	2026-04-17 12:09:34.966774+00	\N	\N
\.


--
-- Data for Name: room_schedules; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.room_schedules (id, unit_id, room_id, meeting_type_id, name, content, component, start_date, end_date, start_time, end_time, master_id, secretary_id, approved, approved_date, approved_staff_id, rejection_reason, meeting_status, online_link, is_cancel, created_user_id, created_date, modified_user_id, modified_date, department_id) FROM stdin;
1	1	1	1	Họp giao ban tuần 15/2026	Giao ban tình hình tuần 15, triển khai nhiệm vụ tuần 16.	\N	2026-04-14	2026-04-14	08:00	09:30	1	9	1	\N	\N	\N	2	\N	0	1	2026-04-17 12:09:34.966774+00	\N	\N	1
2	1	1	2	Họp triển khai Chuyển đổi số tỉnh	Rà soát tiến độ CĐS, phân công nhiệm vụ CĐS quý II/2026.	\N	2026-04-15	2026-04-15	09:00	11:00	1	5	1	\N	\N	\N	0	\N	0	1	2026-04-17 12:09:34.966774+00	\N	\N	1
3	1	3	3	Họp Ban lãnh đạo — kế hoạch quý II	Thảo luận kế hoạch công tác quý II/2026.	\N	2026-04-16	2026-04-16	14:00	16:00	1	9	1	\N	\N	\N	0	\N	0	1	2026-04-17 12:09:34.966774+00	\N	\N	1
4	1	2	2	Demo hệ thống e-Office cho BLĐ	Trình diễn các chức năng mới: HSCV, Họp, Kho lưu trữ, LGSP, Ký số.	\N	2026-04-18	2026-04-18	14:00	16:00	4	8	0	\N	\N	\N	0	\N	0	4	2026-04-17 12:09:34.966774+00	\N	\N	4
\.


--
-- Data for Name: room_schedule_questions; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.room_schedule_questions (id, room_schedule_id, name, start_time, stop_time, duration, status, question_type, order_no) FROM stdin;
\.


--
-- Data for Name: room_schedule_answers; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.room_schedule_answers (id, room_schedule_id, room_schedule_question_id, name, order_no, is_other) FROM stdin;
\.


--
-- Data for Name: room_schedule_attachments; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.room_schedule_attachments (id, room_schedule_id, file_name, file_path, file_size, mime_type, description, created_user_id, created_date) FROM stdin;
\.


--
-- Data for Name: room_schedule_staff; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.room_schedule_staff (id, room_schedule_id, staff_id, user_type, is_secretary, is_represent, attendance, attendance_date, attendance_note, received_appointment, received_appointment_date, view_date) FROM stdin;
1	1	1	1	f	f	t	\N	\N	0	\N	\N
2	1	2	0	f	f	t	\N	\N	0	\N	\N
3	1	3	0	f	f	t	\N	\N	0	\N	\N
4	1	4	0	f	f	t	\N	\N	0	\N	\N
5	1	5	0	f	f	t	\N	\N	0	\N	\N
6	1	9	2	t	f	t	\N	\N	0	\N	\N
7	2	1	1	f	f	f	\N	\N	0	\N	\N
8	2	2	0	f	f	f	\N	\N	0	\N	\N
9	2	4	0	f	f	f	\N	\N	0	\N	\N
10	2	5	2	t	f	f	\N	\N	0	\N	\N
11	2	8	0	f	f	f	\N	\N	0	\N	\N
12	3	1	1	f	f	f	\N	\N	0	\N	\N
13	3	2	0	f	f	f	\N	\N	0	\N	\N
14	3	3	0	f	f	f	\N	\N	0	\N	\N
15	3	4	0	f	f	f	\N	\N	0	\N	\N
16	3	9	2	t	f	f	\N	\N	0	\N	\N
17	4	1	0	f	f	f	\N	\N	0	\N	\N
18	4	4	1	f	f	f	\N	\N	0	\N	\N
19	4	8	2	t	f	f	\N	\N	0	\N	\N
20	4	5	0	f	f	f	\N	\N	0	\N	\N
\.


--
-- Data for Name: room_schedule_votes; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.room_schedule_votes (id, room_schedule_id, question_id, answer_id, staff_id, other_text, voted_at) FROM stdin;
\.


--
-- Data for Name: send_doc_user_configs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.send_doc_user_configs (id, user_id, target_user_id, config_type, created_at) FROM stdin;
1	1	2	doc	2026-04-17 14:30:16.430757+00
2	1	3	doc	2026-04-17 14:30:16.430757+00
\.


--
-- Data for Name: signers; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.signers (id, unit_id, department_id, staff_id, sort_order, created_at) FROM stdin;
1	1	1	1	1	2026-04-17 12:09:34.966774+00
2	2	2	2	1	2026-04-17 12:09:34.966774+00
3	3	3	3	1	2026-04-17 12:09:34.966774+00
4	4	4	4	1	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: sms_templates; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.sms_templates (id, unit_id, name, content, description, is_active, created_by, created_at) FROM stdin;
1	1	Thông báo VB đến mới	Ban nhan VB den moi so {doc_code} ngay {doc_date}. Vui long dang nhap e-Office de xu ly.	Gửi khi có VB đến mới	t	1	2026-04-17 12:09:34.966774+00
2	1	Nhắc nhở xử lý VB	VB so {doc_code} sap het han xu ly ({deadline}). Vui long hoan thanh truoc thoi han.	Nhắc trước hạn 1 ngày	t	1	2026-04-17 12:09:34.966774+00
3	1	Thông báo cuộc họp	Ban duoc moi hop: {meeting_title} luc {meeting_time} tai {meeting_room}. Vui long xac nhan.	Gửi khi mời họp	t	1	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: staff_handling_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.staff_handling_docs (id, handling_doc_id, staff_id, role, step, assigned_at, completed_at) FROM stdin;
1	1	4	1	xu_ly	2026-04-17 12:09:34.966774+00	\N
2	1	8	2	phoi_hop	2026-04-17 12:09:34.966774+00	\N
3	2	3	1	xu_ly	2026-04-17 12:09:34.966774+00	\N
4	2	7	2	phoi_hop	2026-04-17 12:09:34.966774+00	\N
5	3	2	1	xu_ly	2026-04-17 12:09:34.966774+00	\N
6	3	6	2	phoi_hop	2026-04-17 12:09:34.966774+00	\N
7	3	10	2	phoi_hop	2026-04-17 12:09:34.966774+00	\N
8	4	4	1	xu_ly	2026-04-17 12:09:34.966774+00	\N
9	4	8	2	phoi_hop	2026-04-17 12:09:34.966774+00	\N
10	5	4	1	xu_ly	2026-04-17 12:09:34.966774+00	\N
11	5	8	2	hoan_thanh	2026-04-17 12:09:34.966774+00	\N
12	6	6	1	xu_ly	2026-04-17 12:09:34.966774+00	\N
13	6	10	2	phoi_hop	2026-04-17 12:09:34.966774+00	\N
14	7	2	1	\N	2026-04-17 14:31:56.992542+00	\N
15	7	3	1	\N	2026-04-17 14:31:56.992542+00	\N
\.


--
-- Data for Name: staff_notes; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.staff_notes (id, doc_type, doc_id, staff_id, note, created_at, is_important) FROM stdin;
1	incoming	1	2	Văn bản quan trọng — Chính phủ điện tử	2026-04-17 12:09:34.966774+00	t
2	incoming	6	2	Chỉ thị Thủ tướng — cần theo dõi	2026-04-17 12:09:34.966774+00	t
3	incoming	3	4	Liên quan đến hạ tầng CNTT	2026-04-17 12:09:34.966774+00	f
4	outgoing	1	5	QĐ do mình soạn	2026-04-17 12:09:34.966774+00	f
5	drafting	3	4	Báo cáo CNTT quý I	2026-04-17 12:09:34.966774+00	t
6	incoming	8	1	\N	2026-04-17 14:59:08.054489+00	f
7	outgoing	5	1	\N	2026-04-17 15:37:13.84283+00	f
\.


--
-- Data for Name: user_drafting_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.user_drafting_docs (id, drafting_doc_id, staff_id, is_read, read_at, created_at, sent_by, expired_date) FROM stdin;
1	5	1	t	2026-04-17 15:38:08.061468+00	2026-04-17 15:38:08.061468+00	\N	\N
\.


--
-- Data for Name: user_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.user_incoming_docs (id, incoming_doc_id, staff_id, is_read, read_at, created_at) FROM stdin;
1	1	2	t	\N	2026-04-17 12:09:34.966774+00
2	1	4	t	\N	2026-04-17 12:09:34.966774+00
3	1	5	f	\N	2026-04-17 12:09:34.966774+00
4	2	3	t	\N	2026-04-17 12:09:34.966774+00
5	2	7	f	\N	2026-04-17 12:09:34.966774+00
6	3	4	t	\N	2026-04-17 12:09:34.966774+00
7	3	8	t	\N	2026-04-17 12:09:34.966774+00
8	4	2	t	\N	2026-04-17 12:09:34.966774+00
9	4	6	f	\N	2026-04-17 12:09:34.966774+00
10	4	10	f	\N	2026-04-17 12:09:34.966774+00
11	5	1	t	\N	2026-04-17 12:09:34.966774+00
12	5	5	t	\N	2026-04-17 12:09:34.966774+00
14	6	4	f	\N	2026-04-17 12:09:34.966774+00
15	7	2	t	\N	2026-04-17 12:09:34.966774+00
16	7	6	f	\N	2026-04-17 12:09:34.966774+00
13	6	1	t	2026-04-17 14:59:14.698346+00	2026-04-17 12:09:34.966774+00
17	8	1	t	2026-04-17 14:30:27.159239+00	2026-04-17 14:30:27.159239+00
41	4	1	t	2026-04-17 17:08:08.162079+00	2026-04-17 17:08:08.162079+00
\.


--
-- Data for Name: user_outgoing_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.user_outgoing_docs (id, outgoing_doc_id, staff_id, is_read, read_at, created_at, sent_by, expired_date) FROM stdin;
1	4	1	t	2026-04-17 15:06:07.330199+00	2026-04-17 15:06:07.330199+00	\N	\N
20	6	1	t	2026-04-17 15:38:26.229279+00	2026-04-17 15:38:26.229279+00	\N	\N
3	5	1	t	2026-04-17 15:16:04.654169+00	2026-04-17 15:16:04.654169+00	\N	\N
\.


--
-- Data for Name: work_groups; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.work_groups (id, unit_id, name, function, sort_order, is_deleted, created_by, created_at) FROM stdin;
1	1	Ban Chỉ đạo Chuyển đổi số	\N	1	f	1	2026-04-17 12:09:34.966774+00
2	1	Tổ Công tác cải cách hành chính	\N	2	f	1	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: work_group_members; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.work_group_members (id, group_id, staff_id, created_at) FROM stdin;
1	1	1	2026-04-17 12:09:34.966774+00
2	1	2	2026-04-17 12:09:34.966774+00
3	1	4	2026-04-17 12:09:34.966774+00
4	1	8	2026-04-17 12:09:34.966774+00
5	2	1	2026-04-17 12:09:34.966774+00
6	2	5	2026-04-17 12:09:34.966774+00
7	2	6	2026-04-17 12:09:34.966774+00
8	2	10	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: borrow_requests; Type: TABLE DATA; Schema: esto; Owner: -
--

COPY esto.borrow_requests (id, name, unit_id, emergency, notice, borrow_date, status, created_user_id, created_date, modified_user_id, modified_date, department_id) FROM stdin;
1	Mượn hồ sơ tuyển dụng 2025 để đối chiếu	1	0	Cần đối chiếu số liệu cho kế hoạch tuyển dụng 2026	2026-04-10	1	6	2026-04-17 12:09:34.966774+00	\N	\N	6
2	Mượn hồ sơ ngân sách 2025 để lập dự toán	1	1	Cần gấp để lập dự toán ngân sách quý II/2026	2026-04-12	0	7	2026-04-17 12:09:34.966774+00	\N	\N	7
\.


--
-- Data for Name: fonds; Type: TABLE DATA; Schema: esto; Owner: -
--

COPY esto.fonds (id, unit_id, parent_id, fond_code, fond_name, fond_history, archives_time, paper_total, paper_digital, keys_group, other_type, language, lookup_tools, coppy_number, status, description, version, created_user_id, created_date, modified_user_id, modified_date) FROM stdin;
1	1	0	P-UBND	Phông UBND tỉnh Lào Cai	Phông lưu trữ văn bản UBND tỉnh từ năm 2020	2020-2026	\N	\N	\N	\N	\N	\N	\N	1	\N	\N	1	2026-04-17 12:09:34.966774+00	\N	\N
2	1	0	P-SNV	Phông Sở Nội vụ	Phông lưu trữ văn bản Sở Nội vụ	2022-2026	\N	\N	\N	\N	\N	\N	\N	1	\N	\N	2	2026-04-17 12:09:34.966774+00	\N	\N
3	1	0	P-STTTT	Phông Sở TT&TT	Phông lưu trữ Sở TT&TT tỉnh Lào Cai	2023-2026	\N	\N	\N	\N	\N	\N	\N	1	\N	\N	4	2026-04-17 12:09:34.966774+00	\N	\N
\.


--
-- Data for Name: warehouses; Type: TABLE DATA; Schema: esto; Owner: -
--

COPY esto.warehouses (id, unit_id, type_id, code, name, phone_number, address, status, description, parent_id, is_unit, warehouse_level, limit_child, "position", is_deleted, created_user_id, created_date, modified_user_id, modified_date, department_id) FROM stdin;
1	1	1	KHO-01	Kho lưu trữ UBND tỉnh	02143840900	Tầng hầm, Trụ sở UBND tỉnh Lào Cai	t	\N	0	t	0	0	\N	f	1	2026-04-17 12:09:34.966774+00	\N	\N	1
2	1	1	KHO-02	Kho lưu trữ Sở TT&TT	02143840901	Phòng 101, Trụ sở Sở TT&TT tỉnh Lào Cai	t	\N	0	t	0	0	\N	f	4	2026-04-17 12:09:34.966774+00	\N	\N	4
3	1	2	KE-A1	Kệ A1 — Tủ văn bản hành chính	\N	\N	t	\N	1	f	1	0	\N	f	1	2026-04-17 12:09:34.966774+00	\N	\N	1
4	1	2	KE-A2	Kệ A2 — Tủ văn bản tài chính	\N	\N	t	\N	1	f	1	0	\N	f	1	2026-04-17 12:09:34.966774+00	\N	\N	1
\.


--
-- Data for Name: records; Type: TABLE DATA; Schema: esto; Owner: -
--

COPY esto.records (id, unit_id, fond_id, file_code, file_catalog, file_notation, title, maintenance, rights, language, start_date, complete_date, total_doc, description, infor_sign, keyword, total_paper, page_number, format, archive_date, reception_archive_id, in_charge_staff_id, parent_id, warehouse_id, reception_date, reception_from, transfer_staff, is_document_original, number_of_copy, doc_field_id, transfer_online_status, created_user_id, created_date, modified_user_id, modified_date, department_id) FROM stdin;
1	1	1	HS-UBND-001	\N	UBND/QD/2025	Hồ sơ Quyết định nhân sự năm 2025	15 năm	\N	Tiếng Việt	2025-01-01	2025-12-31	45	Tập hợp QĐ bổ nhiệm, điều động, khen thưởng năm 2025	\N	\N	120	\N	0	\N	\N	5	0	3	\N	0	\N	\N	\N	\N	f	1	2026-04-17 12:09:34.966774+00	\N	\N	1
2	1	1	HS-UBND-002	\N	UBND/CV/2025	Hồ sơ Công văn hành chính năm 2025	10 năm	\N	Tiếng Việt	2025-01-01	2025-12-31	230	Công văn hành chính nội bộ và liên cơ quan	\N	\N	580	\N	0	\N	\N	5	0	3	\N	0	\N	\N	\N	\N	f	1	2026-04-17 12:09:34.966774+00	\N	\N	1
3	1	2	HS-SNV-001	\N	SNV/TD/2025	Hồ sơ tuyển dụng công chức năm 2025	20 năm	\N	Tiếng Việt	2025-03-01	2025-09-30	85	Hồ sơ thi tuyển, xét tuyển công chức năm 2025	\N	\N	250	\N	0	\N	\N	6	0	3	\N	0	\N	\N	\N	\N	f	2	2026-04-17 12:09:34.966774+00	\N	\N	2
4	1	3	HS-STTTT-001	\N	STTTT/CDS/2025	Hồ sơ Chuyển đổi số năm 2025	10 năm	\N	Tiếng Việt	2025-01-01	2025-12-31	60	Kế hoạch, báo cáo, đánh giá CĐS năm 2025	\N	\N	150	\N	0	\N	\N	8	0	4	\N	0	\N	\N	\N	\N	f	4	2026-04-17 12:09:34.966774+00	\N	\N	4
5	1	1	HS-UBND-003	\N	UBND/NS/2025	Hồ sơ ngân sách năm 2025	15 năm	\N	Tiếng Việt	2025-01-01	2025-12-31	120	Dự toán, quyết toán, phân bổ ngân sách năm 2025	\N	\N	350	\N	0	\N	\N	7	0	4	\N	0	\N	\N	\N	\N	f	1	2026-04-17 12:09:34.966774+00	\N	\N	1
\.


--
-- Data for Name: borrow_request_records; Type: TABLE DATA; Schema: esto; Owner: -
--

COPY esto.borrow_request_records (id, borrow_request_id, record_id, return_date, actual_return_date) FROM stdin;
1	1	3	2026-04-25	\N
2	2	5	2026-04-20	\N
\.


--
-- Data for Name: document_archives; Type: TABLE DATA; Schema: esto; Owner: -
--

COPY esto.document_archives (id, doc_type, doc_id, fond_id, warehouse_id, record_id, file_catalog, file_notation, doc_ordinal, language, autograph, keyword, format, confidence_level, is_original, archive_date, archived_by, created_at) FROM stdin;
3	incoming	8	\N	\N	\N	\N	\N	\N	Tiếng Việt	\N	\N	Điện tử	\N	t	2026-04-17 14:53:19.576311+00	1	2026-04-17 14:53:19.576311+00
4	incoming	6	2	2	\N	t	t	\N	Tiếng Việt	t	tt	Điện tử	t	t	2026-04-17 15:05:50.150041+00	1	2026-04-17 15:05:50.150041+00
\.


--
-- Data for Name: document_categories; Type: TABLE DATA; Schema: iso; Owner: -
--

COPY iso.document_categories (id, parent_id, code, name, date_process, status, description, version, unit_id, created_user_id, created_date, modified_user_id, modified_date) FROM stdin;
1	0	ISO	Tài liệu ISO	\N	1	\N	\N	1	1	2026-04-17 12:09:34.966774+00	\N	\N
2	0	NB	Tài liệu nội bộ	\N	1	\N	\N	1	1	2026-04-17 12:09:34.966774+00	\N	\N
3	0	PQ	Văn bản pháp quy	\N	1	\N	\N	1	1	2026-04-17 12:09:34.966774+00	\N	\N
4	1	ISO-QT	Quy trình ISO 9001:2015	\N	1	\N	\N	1	1	2026-04-17 12:09:34.966774+00	\N	\N
5	2	NB-HD	Hướng dẫn sử dụng	\N	1	\N	\N	1	1	2026-04-17 12:09:34.966774+00	\N	\N
\.


--
-- Data for Name: documents; Type: TABLE DATA; Schema: iso; Owner: -
--

COPY iso.documents (id, unit_id, category_id, title, description, file_name, file_path, file_size, mime_type, keyword, status, created_user_id, created_date, modified_user_id, modified_date, is_deleted, department_id) FROM stdin;
1	1	4	Quy trình tiếp nhận và xử lý văn bản đến	Quy trình ISO cho văn bản đến theo ISO 9001:2015	QT-QLVB-01.pdf	iso/QT-QLVB-01.pdf	2048000	application/pdf	ISO, văn bản đến, quy trình	1	1	2026-04-17 12:09:34.966774+00	\N	\N	f	1
2	1	4	Quy trình soạn thảo và ban hành văn bản	Quy trình ISO cho VB đi từ dự thảo đến phát hành	QT-QLVB-02.pdf	iso/QT-QLVB-02.pdf	1536000	application/pdf	ISO, văn bản đi, soạn thảo	1	1	2026-04-17 12:09:34.966774+00	\N	\N	f	1
3	1	5	Hướng dẫn sử dụng hệ thống e-Office v2.0	Tài liệu hướng dẫn chi tiết cho người dùng cuối	HD-eOffice-v2.pdf	nb/HD-eOffice-v2.pdf	5120000	application/pdf	hướng dẫn, e-Office, sử dụng	1	1	2026-04-17 12:09:34.966774+00	\N	\N	f	1
4	1	5	Hướng dẫn ký số điện tử trên e-Office	Hướng dẫn sử dụng chữ ký số SmartCA và EsignNEAC	HD-KySo.pdf	nb/HD-KySo.pdf	3072000	application/pdf	ký số, SmartCA, hướng dẫn	1	1	2026-04-17 12:09:34.966774+00	\N	\N	f	1
5	1	3	Nghị định 30/2020/NĐ-CP về công tác văn thư	Nghị định quy định về công tác văn thư trong cơ quan nhà nước	ND-30-2020.pdf	pq/ND-30-2020.pdf	4096000	application/pdf	nghị định, văn thư, pháp quy	1	1	2026-04-17 12:09:34.966774+00	\N	\N	f	1
6	1	3	Thông tư 01/2011/TT-BNV hướng dẫn thể thức VB	Thông tư hướng dẫn thể thức và kỹ thuật trình bày văn bản	TT-01-2011.pdf	pq/TT-01-2011.pdf	2560000	application/pdf	thông tư, thể thức, trình bày	1	1	2026-04-17 12:09:34.966774+00	\N	\N	f	1
\.


--
-- Data for Name: rights; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.rights (id, parent_id, name, name_of_menu, action_link, icon, sort_order, show_menu, default_page, show_in_app, description, is_locked, created_at) FROM stdin;
1	\N	Dashboard	Dashboard	/dashboard	DashboardOutlined	1	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
2	\N	Văn bản đến	Văn bản đến	/van-ban-den	InboxOutlined	2	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
3	\N	Văn bản đi	Văn bản đi	/van-ban-di	SendOutlined	3	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
4	\N	Dự thảo	Dự thảo	/du-thao	EditOutlined	4	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
5	\N	Hồ sơ công việc	Hồ sơ công việc	/ho-so-cong-viec	FolderOutlined	5	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
6	\N	Lịch làm việc	Lịch làm việc	/lich-lam-viec	CalendarOutlined	6	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
7	\N	Tin nhắn	Tin nhắn	/tin-nhan	MessageOutlined	7	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
8	\N	Thông báo	Thông báo	/thong-bao	BellOutlined	8	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
9	\N	Họp không giấy	Họp không giấy	/hop-khong-giay	TeamOutlined	9	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
10	\N	Kho lưu trữ	Kho lưu trữ	/kho-luu-tru	DatabaseOutlined	10	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
11	\N	Tài liệu	Tài liệu	/tai-lieu	FileTextOutlined	11	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
12	\N	Hợp đồng	Hợp đồng	/hop-dong	AuditOutlined	12	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
13	\N	Quản trị	Quản trị	/quan-tri	SettingOutlined	13	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
14	13	Đơn vị	Đơn vị	/quan-tri/don-vi	\N	1	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
15	13	Người dùng	Người dùng	/quan-tri/nguoi-dung	\N	2	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
16	13	Nhóm quyền	Nhóm quyền	/quan-tri/nhom-quyen	\N	3	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
17	13	Chức vụ	Chức vụ	/quan-tri/chuc-vu	\N	4	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
18	13	Danh mục	Danh mục	/quan-tri/danh-muc	\N	5	t	f	f	\N	f	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: roles; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.roles (id, unit_id, name, description, is_locked, created_by, created_at, updated_by, updated_at) FROM stdin;
1	\N	Ban Lãnh đạo	Ban lãnh đạo cơ quan	f	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
2	\N	Cán bộ	Cán bộ, Chuyên viên	f	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
3	\N	Chỉ đạo điều hành	Chỉ đạo điều hành	f	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
4	\N	Nhóm Trưởng phòng	Nhóm Trưởng phòng	f	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
5	\N	Quản trị hệ thống	Quản trị hệ thống	f	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
6	\N	Văn thư	Văn thư đơn vị	f	\N	2026-04-17 12:09:34.966774+00	\N	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: action_of_role; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.action_of_role (id, role_id, right_id) FROM stdin;
27	5	1
28	5	2
29	5	3
30	5	4
31	5	5
32	5	6
33	5	7
34	5	8
35	5	9
36	5	10
37	5	11
38	5	12
39	5	13
40	5	14
41	5	15
42	5	16
43	5	17
44	5	18
45	1	1
46	1	2
47	1	3
48	1	4
49	1	5
50	1	6
51	1	7
52	1	8
53	1	9
54	1	10
55	1	11
56	1	12
57	2	1
58	2	2
59	2	3
60	2	4
61	2	5
62	2	6
63	2	7
64	2	8
65	2	9
66	2	10
67	2	11
68	2	12
\.


--
-- Data for Name: calendar_events; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.calendar_events (id, title, description, start_time, end_time, all_day, color, repeat_type, scope, unit_id, created_by, created_at, updated_at, is_deleted, department_id) FROM stdin;
1	Họp giao ban đầu tuần	Họp giao ban tuần 15 — tất cả trưởng phòng	2026-04-14 08:00:00	2026-04-14 09:00:00	f	#1B3A5C	none	unit	1	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	1
2	Review code Sprint 5	Review module HSCV và Dashboard	2026-04-14 14:00:00	2026-04-14 16:00:00	f	#0891B2	none	personal	1	4	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	4
3	Họp triển khai CĐS tỉnh	Ban chỉ đạo CĐS tỉnh Lào Cai	2026-04-15 09:00:00	2026-04-15 11:00:00	f	#D97706	none	leader	1	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	1
4	Đào tạo e-Office buổi 1	Đào tạo CBCC sử dụng hệ thống e-Office mới	2026-04-16 08:00:00	2026-04-16 11:00:00	f	#059669	none	unit	1	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	1
5	Đào tạo e-Office buổi 2	Đào tạo tiếp: Module VB đi, Dự thảo, Ký số	2026-04-17 08:00:00	2026-04-17 11:00:00	f	#059669	none	unit	1	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	1
6	Demo cho Ban lãnh đạo	Demo hệ thống e-Office cho BLĐ tỉnh	2026-04-18 14:00:00	2026-04-18 16:00:00	f	#DC2626	none	leader	1	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	1
7	Tiếp công dân định kỳ	Chủ tịch UBND tiếp công dân tháng 4	2026-04-16 08:00:00	2026-04-16 11:00:00	f	#DC2626	none	leader	1	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	1
8	Lễ chào cờ đầu tháng 5	Sinh hoạt chính trị đầu tháng 5/2026	2026-05-01 07:00:00	2026-05-01 08:00:00	f	#D97706	none	unit	1	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	1
9	Kiểm tra email và phê duyệt VB	Xử lý văn bản đến, ký duyệt VB đi buổi sáng	2026-04-21 07:30:00	2026-04-21 08:30:00	f	#1B3A5C	none	personal	1	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	1
10	Họp ban giám đốc	Họp tổng kết tuần và giao nhiệm vụ tuần mới	2026-04-21 09:00:00	2026-04-21 10:30:00	f	#D97706	none	personal	1	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	1
11	Duyệt hồ sơ tuyển dụng	Xem hồ sơ ứng viên vị trí chuyên viên CNTT	2026-04-22 14:00:00	2026-04-22 16:00:00	f	#059669	none	personal	1	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	f	1
\.


--
-- Data for Name: provinces; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.provinces (id, name, code, is_active) FROM stdin;
1	Lào Cai	10	t
2	Hà Nội	01	t
3	TP Hồ Chí Minh	79	t
4	Yên Bái	15	t
5	Hà Giang	02	t
6	Lai Châu	12	t
7	Sơn La	14	t
8	Điện Biên	11	t
9	Đà Nẵng	48	t
10	Hải Phòng	31	t
\.


--
-- Data for Name: districts; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.districts (id, province_id, name, code, is_active) FROM stdin;
1	1	TP Lào Cai	080	t
2	1	Sa Pa	082	t
3	1	Bát Xát	083	t
4	1	Bảo Thắng	085	t
5	1	Bảo Yên	086	t
6	1	Văn Bàn	091	t
7	2	Ba Đình	001	t
8	2	Hoàn Kiếm	002	t
9	2	Đống Đa	006	t
10	2	Cầu Giấy	005	t
\.


--
-- Data for Name: communes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.communes (id, district_id, name, code, is_active) FROM stdin;
1	1	Phường Cốc Lếu	02545	t
2	1	Phường Duyên Hải	02548	t
3	1	Phường Lào Cai	02551	t
4	1	Phường Kim Tân	02554	t
5	2	TT Sa Pa	02590	t
6	2	Xã San Sả Hồ	02596	t
7	3	TT Bát Xát	02560	t
8	3	Xã A Mú Sung	02563	t
\.


--
-- Data for Name: configurations; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.configurations (id, unit_id, key, value, description) FROM stdin;
2	1	org_name	Ủy ban Nhân dân tỉnh Lào Cai	Tên cơ quan
3	1	org_code	UBND_LAOCAI	Mã cơ quan
4	1	org_address	Đường Hoàng Liên, TP Lào Cai	Địa chỉ cơ quan
5	1	org_phone	02143840900	Số điện thoại
6	1	org_fax	02143840901	Số fax
7	1	org_email	ubnd@laocai.gov.vn	Email cơ quan
8	1	org_website	https://laocai.gov.vn	Website
9	1	max_upload_size	52428800	Dung lượng upload tối đa (bytes) — 50MB
10	1	session_timeout	900	Thời gian timeout session (giây) — 15 phút
11	1	password_min_len	6	Độ dài tối thiểu mật khẩu
12	1	password_expiry	90	Số ngày hết hạn mật khẩu
13	1	doc_number_format	{year}/{book_code}/{number}	Định dạng số văn bản
14	1	default_language	vi	Ngôn ngữ mặc định
\.


--
-- Data for Name: login_history; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.login_history (id, staff_id, username, ip_address, user_agent, success, created_at) FROM stdin;
1	1	admin	::1	curl/8.18.0	t	2026-04-17 12:52:13.567146+00
2	2	nguyenvana	::1	curl/8.18.0	t	2026-04-17 12:52:13.959574+00
3	6	hoangthif	::1	curl/8.18.0	t	2026-04-17 12:52:14.396289+00
4	5	phamvane	::1	curl/8.18.0	t	2026-04-17 12:52:14.744111+00
5	1	admin	::1	curl/8.18.0	t	2026-04-17 12:53:08.573573+00
6	2	nguyenvana	::1	curl/8.18.0	t	2026-04-17 12:53:08.7823+00
7	6	hoangthif	::1	curl/8.18.0	t	2026-04-17 12:53:08.944166+00
8	5	phamvane	::1	curl/8.18.0	t	2026-04-17 12:53:09.099422+00
9	4	levand	::1	curl/8.18.0	t	2026-04-17 12:53:09.254992+00
10	1	admin	::1	curl/8.18.0	t	2026-04-17 12:57:42.208474+00
11	2	nguyenvana	::1	curl/8.18.0	t	2026-04-17 12:57:42.374613+00
12	6	hoangthif	::1	curl/8.18.0	t	2026-04-17 12:57:42.54188+00
13	5	phamvane	::1	curl/8.18.0	t	2026-04-17 12:57:42.695226+00
14	4	levand	::1	curl/8.18.0	t	2026-04-17 12:57:42.842347+00
15	1	admin	::1	curl/8.18.0	t	2026-04-17 13:40:03.746998+00
16	2	nguyenvana	::1	curl/8.18.0	t	2026-04-17 13:40:03.930681+00
17	6	hoangthif	::1	curl/8.18.0	t	2026-04-17 13:40:04.22436+00
18	4	levand	::1	curl/8.18.0	t	2026-04-17 13:40:04.37614+00
19	1	admin	::1	curl/8.18.0	t	2026-04-17 13:40:20.130182+00
20	6	hoangthif	::1	curl/8.18.0	t	2026-04-17 13:40:20.274193+00
21	1	admin	::1	curl/8.18.0	t	2026-04-17 13:42:29.849281+00
22	2	nguyenvana	::1	curl/8.18.0	t	2026-04-17 13:42:30.02978+00
23	6	hoangthif	::1	curl/8.18.0	t	2026-04-17 13:42:30.206016+00
24	4	levand	::1	curl/8.18.0	t	2026-04-17 13:42:30.370564+00
25	1	admin	::1	curl/8.18.0	t	2026-04-17 13:42:42.827293+00
26	1	admin	::1	curl/8.18.0	t	2026-04-17 13:44:43.775353+00
27	1	admin	::1	curl/8.18.0	t	2026-04-17 13:44:51.728669+00
28	1	admin	::1	curl/8.18.0	t	2026-04-17 13:45:19.572198+00
29	1	admin	::1	curl/8.18.0	t	2026-04-17 13:45:53.845979+00
30	2	nguyenvana	::1	curl/8.18.0	t	2026-04-17 13:45:54.033122+00
31	6	hoangthif	::1	curl/8.18.0	t	2026-04-17 13:45:54.179303+00
32	4	levand	::1	curl/8.18.0	t	2026-04-17 13:45:54.339895+00
33	1	admin	::1	curl/8.18.0	t	2026-04-17 14:02:51.042372+00
34	2	nguyenvana	::1	curl/8.18.0	t	2026-04-17 14:02:51.18476+00
35	5	phamvane	::1	curl/8.18.0	t	2026-04-17 14:02:51.328656+00
36	6	hoangthif	::1	curl/8.18.0	t	2026-04-17 14:02:51.481613+00
37	4	levand	::1	curl/8.18.0	t	2026-04-17 14:02:51.625175+00
38	1	admin	::1	curl/8.18.0	f	2026-04-17 14:02:51.758438+00
39	1	admin	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-17 14:29:06.16048+00
40	1	admin	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-17 14:53:06.714131+00
41	1	admin	::1	curl/8.18.0	t	2026-04-17 15:27:49.885294+00
42	1	admin	::ffff:127.0.0.1	curl/8.18.0	t	2026-04-17 15:28:46.553184+00
43	1	admin	::1	curl/8.18.0	t	2026-04-17 15:31:09.079127+00
44	1	admin	::1	curl/8.18.0	t	2026-04-17 15:31:20.125019+00
45	1	admin	::1	curl/8.18.0	t	2026-04-17 15:39:40.374439+00
46	1	admin	::1	curl/8.18.0	t	2026-04-17 15:39:50.978422+00
47	1	admin	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-17 15:40:33.30714+00
48	1	admin	::1	curl/8.18.0	t	2026-04-17 15:43:45.023586+00
49	1	admin	::1	curl/8.18.0	t	2026-04-17 15:44:34.876081+00
50	1	admin	::1	curl/8.18.0	t	2026-04-17 15:44:58.303701+00
51	1	admin	::1	curl/8.18.0	t	2026-04-17 15:45:08.025152+00
52	1	admin	::1	curl/8.18.0	t	2026-04-17 15:47:12.016134+00
53	1	admin	::1	curl/8.18.0	t	2026-04-17 15:47:53.909995+00
54	1	admin	::1	curl/8.18.0	t	2026-04-17 15:48:02.043346+00
55	1	admin	::1	curl/8.18.0	t	2026-04-17 15:50:51.874048+00
56	1	admin	::1	curl/8.18.0	t	2026-04-17 15:51:45.120311+00
57	1	admin	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-17 15:58:07.531673+00
58	1	admin	::1	curl/8.18.0	t	2026-04-17 16:03:48.29907+00
59	1	admin	::1	curl/8.18.0	t	2026-04-17 16:07:44.468213+00
60	1	admin	::1	curl/8.18.0	t	2026-04-17 16:09:32.877253+00
61	1	admin	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-17 16:27:30.010151+00
62	1	admin	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-17 16:45:29.621204+00
63	1	admin	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	f	2026-04-17 17:04:22.293961+00
64	1	admin	::1	Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/147.0.0.0 Safari/537.36	t	2026-04-17 17:04:32.792886+00
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.refresh_tokens (id, staff_id, token_hash, expires_at, created_at, revoked_at) FROM stdin;
1	1	3afbd33247f466efbae88e80518287019385cdd4eb0f2600f8e8fb7b8dedc0bf	2026-04-24 12:52:13.555+00	2026-04-17 12:52:13.557271+00	2026-04-17 12:53:08.568107+00
2	2	a9856fa6f07449851760a9403b7b66511d84a225b1d473f981ea00001792a7bb	2026-04-24 12:52:13.919+00	2026-04-17 12:52:13.920911+00	2026-04-17 12:53:08.773749+00
3	6	f74b3333c819a058ee92d8401eebfb285e287a207ba66eee88035ca12f420c84	2026-04-24 12:52:14.389+00	2026-04-17 12:52:14.391954+00	2026-04-17 12:53:08.941078+00
4	5	d93b12d87ece67778a9aaf27222d463e4c4e5312e39267b6466530883c37f195	2026-04-24 12:52:14.739+00	2026-04-17 12:52:14.741055+00	2026-04-17 12:53:09.094759+00
5	1	6cb1ef8ca72ce1bd7196716beab9b58cbc379f196902657089c3128e7fddff41	2026-04-24 12:53:08.565+00	2026-04-17 12:53:08.568107+00	2026-04-17 12:57:42.203169+00
6	2	5a0cb16198a3ce9690c0d6d6adfa709924e5a89c1b96b172a693dee638b49f63	2026-04-24 12:53:08.771+00	2026-04-17 12:53:08.773749+00	2026-04-17 12:57:42.370291+00
7	6	bce1505578cf9368f2dd8f6c14e754fe54885c9eba3dcc6fbbe9ea1205166d1f	2026-04-24 12:53:08.938+00	2026-04-17 12:53:08.941078+00	2026-04-17 12:57:42.537786+00
8	5	e5686d1862b9d4de02c48995ec25fb2876bd0e5fc0d6e9f37cd472d62b1901bd	2026-04-24 12:53:09.091+00	2026-04-17 12:53:09.094759+00	2026-04-17 12:57:42.691272+00
9	4	1add8296db1e83aa68c621271e353f2147b2935e11f755675ecdc12593cbe0ab	2026-04-24 12:53:09.247+00	2026-04-17 12:53:09.25038+00	2026-04-17 12:57:42.837803+00
10	1	4eb188e43b5413669b49a86ef843807e08de9c0f8084f376995250accfdc1ab7	2026-04-24 12:57:42.201+00	2026-04-17 12:57:42.203169+00	2026-04-17 13:40:03.73596+00
11	2	44ff1176c916fac8787ddf9382455e3193ef9b88078e2d0509575e960646be33	2026-04-24 12:57:42.368+00	2026-04-17 12:57:42.370291+00	2026-04-17 13:40:03.925883+00
12	6	14e1172a6cfc05d312edaa92a05b97a760dea192794b3927ae91694d74b8167f	2026-04-24 12:57:42.535+00	2026-04-17 12:57:42.537786+00	2026-04-17 13:40:04.220081+00
14	4	8895ebc26a16a10b24020427a817ff4c4cb02b12ec0856174ebd8046c77ceb49	2026-04-24 12:57:42.835+00	2026-04-17 12:57:42.837803+00	2026-04-17 13:40:04.371847+00
15	1	578997d38d0435657dc843d6ff7fee83c640429a912779c83cbeafdcbe030843	2026-04-24 13:40:03.739+00	2026-04-17 13:40:03.73596+00	2026-04-17 13:40:20.113808+00
17	6	ff820ac7e5cb2d85f4b3e229b4a65c9667f45f84a051c62976a6f7a3535e3531	2026-04-24 13:40:04.223+00	2026-04-17 13:40:04.220081+00	2026-04-17 13:40:20.269322+00
19	1	49e1bcf6e89221400c07623b625e188f8501668805883c5b14599fe288feb645	2026-04-24 13:40:20.114+00	2026-04-17 13:40:20.113808+00	2026-04-17 13:42:29.843747+00
16	2	4d6d8769aaa42d3ea07903d36c50378ba6f7f72483869483b3313fc635af318f	2026-04-24 13:40:03.929+00	2026-04-17 13:40:03.925883+00	2026-04-17 13:42:30.025218+00
20	6	48f3ce9159e30e60d92737b765d3d1dcdad2f1e47aecfba0cd9ea6a586ce1550	2026-04-24 13:40:20.269+00	2026-04-17 13:40:20.269322+00	2026-04-17 13:42:30.201806+00
18	4	6fabb36f2d7a64cd699adc61f5c1bd9319da8c1f13ef40cb8c7add9fb930cbe1	2026-04-24 13:40:04.375+00	2026-04-17 13:40:04.371847+00	2026-04-17 13:42:30.366149+00
21	1	cb4313b8a0c959da5fb8ab214614acf67814b9b918f549a1d053d54b4656f4e9	2026-04-24 13:42:29.851+00	2026-04-17 13:42:29.843747+00	2026-04-17 13:42:42.820989+00
25	1	b0b8037002f1158b18b8ce52d23ae735d20075f26d94b8bc3acb66106e640171	2026-04-24 13:42:42.827+00	2026-04-17 13:42:42.820989+00	2026-04-17 13:44:43.768497+00
26	1	e1f7874971820e48cc1b3c08404ba18cc507932ed4c9b13990e2daaa5c88c033	2026-04-24 13:44:43.765+00	2026-04-17 13:44:43.768497+00	2026-04-17 13:44:51.712276+00
27	1	0510a2c9537a26b0364197797d3544753a6651dabc3971124c336b33fca5708f	2026-04-24 13:44:51.709+00	2026-04-17 13:44:51.712276+00	2026-04-17 13:45:19.56619+00
28	1	f913844ac6251a40c8aaf489ffe1ce7199ad1a5678aa074b99c5571c3858f2c0	2026-04-24 13:45:19.57+00	2026-04-17 13:45:19.56619+00	2026-04-17 13:45:53.820276+00
22	2	cf2c587b48d72b88a4005a3cf85aa5e12f6ea005cb17a64498255b83d897cc0d	2026-04-24 13:42:30.032+00	2026-04-17 13:42:30.025218+00	2026-04-17 13:45:54.029751+00
23	6	710c092802a2da658dc69f337d1704a24a4301efcf2a3e8961eba820621707a2	2026-04-24 13:42:30.209+00	2026-04-17 13:42:30.201806+00	2026-04-17 13:45:54.174364+00
24	4	3beed3fa1c212218927a3140d1d4e39f19ab0ae2ae2bdf1ae1bb84b6b8270eda	2026-04-24 13:42:30.373+00	2026-04-17 13:42:30.366149+00	2026-04-17 13:45:54.335623+00
29	1	957b3a3aa3fa21099ad36ef073ef6355f0f35e0415ee5c0121c2b40424a7e462	2026-04-24 13:45:53.814+00	2026-04-17 13:45:53.820276+00	2026-04-17 14:02:51.036734+00
30	2	4c965fd7d51d9772d6164a59f1fca8540f74b62b42e71c1749e8c01a25eb0f07	2026-04-24 13:45:54.024+00	2026-04-17 13:45:54.029751+00	2026-04-17 14:02:51.1803+00
34	2	98572655397963e9810be387b47c96a2ec4a5a3ffc6ba81aa5cccb58df34f88c	2026-04-24 14:02:51.178+00	2026-04-17 14:02:51.1803+00	\N
13	5	8bdb935a326c8600f7cdb2c1dd796db7d7f543be771d64bd1f9124f3cd36e9ee	2026-04-24 12:57:42.689+00	2026-04-17 12:57:42.691272+00	2026-04-17 14:02:51.323539+00
35	5	745e998427f53303dfcdf61b57c35c507a065a329ca9703e515ffca957583998	2026-04-24 14:02:51.321+00	2026-04-17 14:02:51.323539+00	\N
31	6	b12060e24068b8cb18693b335b8c0e40ad1aa6800a90f809a747b7e282e9326b	2026-04-24 13:45:54.169+00	2026-04-17 13:45:54.174364+00	2026-04-17 14:02:51.476242+00
36	6	9b3e177df8cf301a0ca357ddfddc6ffd5466a4d6868ba476742e89bcda6cc7a4	2026-04-24 14:02:51.473+00	2026-04-17 14:02:51.476242+00	\N
32	4	d9cacd304f0c544438308269ebad2ad2cd8e4891ad2e9d76943a78ea40ff5770	2026-04-24 13:45:54.33+00	2026-04-17 13:45:54.335623+00	2026-04-17 14:02:51.61992+00
37	4	04dcfeb7d292ebbc196479ef4e470869a9370e8ca930e72a101468c357998b29	2026-04-24 14:02:51.617+00	2026-04-17 14:02:51.61992+00	\N
33	1	e4f396ea73e9cb16c24420e741a238d5474e559f222fbe4478d7d6b22883806a	2026-04-24 14:02:51.033+00	2026-04-17 14:02:51.036734+00	2026-04-17 14:29:06.147098+00
38	1	145687286f81a7de0c7e6a7058954580f7ffc83ea3dbd66deb3e76a6d72ff4ae	2026-04-24 14:29:06.13+00	2026-04-17 14:29:06.147098+00	2026-04-17 14:52:59.463872+00
39	1	7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2	2026-04-24 14:52:59.485+00	2026-04-17 14:52:59.487254+00	2026-04-17 14:53:06.709806+00
40	1	7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2	2026-04-24 14:52:59.485+00	2026-04-17 14:52:59.487715+00	2026-04-17 14:53:06.709806+00
41	1	7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2	2026-04-24 14:52:59.483+00	2026-04-17 14:52:59.48748+00	2026-04-17 14:53:06.709806+00
42	1	7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2	2026-04-24 14:52:59.486+00	2026-04-17 14:52:59.487981+00	2026-04-17 14:53:06.709806+00
43	1	7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2	2026-04-24 14:52:59.486+00	2026-04-17 14:52:59.488061+00	2026-04-17 14:53:06.709806+00
44	1	7b61882ea39766c08d3d0a1e9065b430d4490a22498731021166198c66148ee2	2026-04-24 14:52:59.485+00	2026-04-17 14:52:59.487188+00	2026-04-17 14:53:06.709806+00
45	1	9bcb270da5568512743d0ca158f403c2344858eda00ed5674b30fedcbdb2755f	2026-04-24 14:53:06.707+00	2026-04-17 14:53:06.709806+00	2026-04-17 15:08:17.398058+00
46	1	71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580	2026-04-24 15:08:17.415+00	2026-04-17 15:08:17.416693+00	2026-04-17 15:25:07.423914+00
47	1	71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580	2026-04-24 15:08:17.416+00	2026-04-17 15:08:17.417036+00	2026-04-17 15:25:07.423914+00
48	1	71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580	2026-04-24 15:08:17.415+00	2026-04-17 15:08:17.415822+00	2026-04-17 15:25:07.423914+00
49	1	71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580	2026-04-24 15:08:17.413+00	2026-04-17 15:08:17.415781+00	2026-04-17 15:25:07.423914+00
50	1	71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580	2026-04-24 15:08:17.415+00	2026-04-17 15:08:17.416086+00	2026-04-17 15:25:07.423914+00
51	1	71b834ea16cac2ac3783d384fb379128509ba13f823847ed5cb8166bba5cb580	2026-04-24 15:08:17.415+00	2026-04-17 15:08:17.416056+00	2026-04-17 15:25:07.423914+00
53	1	4234db91737ea39a787313f5b05faf2a8cb8ce3557a6957c706413ccd9acdc97	2026-04-24 15:25:07.456+00	2026-04-17 15:25:07.455807+00	2026-04-17 15:27:49.878779+00
52	1	4234db91737ea39a787313f5b05faf2a8cb8ce3557a6957c706413ccd9acdc97	2026-04-24 15:25:07.456+00	2026-04-17 15:25:07.456108+00	2026-04-17 15:27:49.878779+00
55	1	4234db91737ea39a787313f5b05faf2a8cb8ce3557a6957c706413ccd9acdc97	2026-04-24 15:25:07.456+00	2026-04-17 15:25:07.45585+00	2026-04-17 15:27:49.878779+00
54	1	4234db91737ea39a787313f5b05faf2a8cb8ce3557a6957c706413ccd9acdc97	2026-04-24 15:25:07.457+00	2026-04-17 15:25:07.456651+00	2026-04-17 15:27:49.878779+00
56	1	8fb0210e108d998d03e761d1fdf13fe7b48db1a3fef207d191e90167b5187755	2026-04-24 15:27:49.875+00	2026-04-17 15:27:49.878779+00	2026-04-17 15:28:46.547426+00
57	1	f79537d05acf0086f63de3bbeadfa9dcf429ee7f22d7ddd39791806a77dd4230	2026-04-24 15:28:46.543+00	2026-04-17 15:28:46.547426+00	2026-04-17 15:31:09.06777+00
58	1	8615195a8e7a069ae33078f6b2c443dc98a9f3f202c65738b53991a12d2a682e	2026-04-24 15:31:09.058+00	2026-04-17 15:31:09.06777+00	2026-04-17 15:31:20.120726+00
59	1	3e69728bfd8a332a28ef2ba1b9d62a66ab97bface6c1f3fe62367c6499e1d386	2026-04-24 15:31:20.113+00	2026-04-17 15:31:20.120726+00	2026-04-17 15:39:40.367368+00
60	1	977c2d367592bd08e6b98060b6d3382de1648ff07d6b75e23291ae4d77279180	2026-04-24 15:39:40.365+00	2026-04-17 15:39:40.367368+00	2026-04-17 15:39:50.974951+00
61	1	6f2600c3f440f34141eacfb13ab688b3b964665466f006613641d637ad7c93e5	2026-04-24 15:39:50.972+00	2026-04-17 15:39:50.974951+00	2026-04-17 15:40:33.30063+00
62	1	863682e25e27008fd8bc3506e3cfd86ab36ff11dd3ab9d31ef6a738d450e48b6	2026-04-24 15:40:33.298+00	2026-04-17 15:40:33.30063+00	2026-04-17 15:43:45.018057+00
63	1	698fbc7f9060614ed930e4b006c12cfd11cf87ae74e8199d929cbb76a1a9ff2e	2026-04-24 15:43:45.015+00	2026-04-17 15:43:45.018057+00	2026-04-17 15:44:34.870898+00
64	1	5cf69473cd6a65e4d13b17d894714b9a286965942069217365b2c08aa576b6c5	2026-04-24 15:44:34.871+00	2026-04-17 15:44:34.870898+00	2026-04-17 15:44:58.298329+00
65	1	a7ba79723612451ea6db5c05cbb40cb1bcf9230b74b95ef182808107045b4ea0	2026-04-24 15:44:58.295+00	2026-04-17 15:44:58.298329+00	2026-04-17 15:45:08.021222+00
66	1	190234e7a23b65dbef870ecf7cf3a33358faf528f4520ebf6d0a1fd2de6bbdee	2026-04-24 15:45:08.017+00	2026-04-17 15:45:08.021222+00	2026-04-17 15:47:12.009677+00
67	1	26ef405d27edb4f687e50266b98e62117d7dd2cf8b3ff8324517f72e8f6bcf53	2026-04-24 15:47:12.009+00	2026-04-17 15:47:12.009677+00	2026-04-17 15:47:53.904432+00
68	1	acd0d6ac38a62b89377e79af51671d5a233ba39af9cec34db60f67ff742a91eb	2026-04-24 15:47:53.901+00	2026-04-17 15:47:53.904432+00	2026-04-17 15:48:02.037645+00
69	1	ec352d1c0ad8716db8c92d65e7072c7074f2c12c87199e71ed7979ea4633ee5d	2026-04-24 15:48:02.037+00	2026-04-17 15:48:02.037645+00	2026-04-17 15:50:51.857162+00
70	1	8c3a0d2b489d3db4296cafb30603aefc4c76bbe73d4e1c3c46434dca0fd83018	2026-04-24 15:50:51.852+00	2026-04-17 15:50:51.857162+00	2026-04-17 15:51:45.115109+00
71	1	8156c1138d1915529bdb4b8b400e2c2fdaadd120fbba7d52b1d6b0edc9cb7fdc	2026-04-24 15:51:45.113+00	2026-04-17 15:51:45.115109+00	2026-04-17 15:58:07.503911+00
72	1	5821d42d3ca65d7ccd3b7fadf0fc79af1079f5b2fd42837f1e824bbb1675a277	2026-04-24 15:58:07.506+00	2026-04-17 15:58:07.503911+00	2026-04-17 16:03:48.293188+00
73	1	7aecb9b61da41dc86e72da086be24cbf64b7185a5c4a42f924d079bd0517c71f	2026-04-24 16:03:48.292+00	2026-04-17 16:03:48.293188+00	2026-04-17 16:07:44.461949+00
74	1	d720c873f264345eb369bde292895b3179aa97af3f51f4abc569d3aa9ea0144c	2026-04-24 16:07:44.462+00	2026-04-17 16:07:44.461949+00	2026-04-17 16:09:32.865061+00
75	1	0d0fb646243a00b8acc7bdf888292ee18d20efa8da50c0c2e46b8f3ad7ecf8fd	2026-04-24 16:09:32.864+00	2026-04-17 16:09:32.865061+00	2026-04-17 16:27:29.99433+00
76	1	92e43b9d54ed1df9cbce5c9684513c11bc43cf993714d46bde70b707285f3fb8	2026-04-24 16:27:29.994+00	2026-04-17 16:27:29.99433+00	2026-04-17 16:44:26.828613+00
77	1	0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363	2026-04-24 16:44:26.853+00	2026-04-17 16:44:26.847283+00	2026-04-17 16:45:29.615577+00
78	1	0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363	2026-04-24 16:44:26.853+00	2026-04-17 16:44:26.847832+00	2026-04-17 16:45:29.615577+00
80	1	0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363	2026-04-24 16:44:26.856+00	2026-04-17 16:44:26.849535+00	2026-04-17 16:45:29.615577+00
79	1	0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363	2026-04-24 16:44:26.856+00	2026-04-17 16:44:26.849579+00	2026-04-17 16:45:29.615577+00
81	1	0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363	2026-04-24 16:44:26.858+00	2026-04-17 16:44:26.851514+00	2026-04-17 16:45:29.615577+00
82	1	0f7f5caee82fa70a847f29003af2bd502c99fb039719b2b78657db6523e8c363	2026-04-24 16:44:26.858+00	2026-04-17 16:44:26.851578+00	2026-04-17 16:45:29.615577+00
83	1	e86d0a668a4547e32fdb242eb2097a30ee5980c6305c58becffe43ce934db666	2026-04-24 16:45:29.613+00	2026-04-17 16:45:29.615577+00	2026-04-17 17:04:11.116847+00
86	1	11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64	2026-04-24 17:04:11.136+00	2026-04-17 17:04:11.138131+00	2026-04-17 17:04:32.786422+00
85	1	11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64	2026-04-24 17:04:11.133+00	2026-04-17 17:04:11.13483+00	2026-04-17 17:04:32.786422+00
87	1	11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64	2026-04-24 17:04:11.136+00	2026-04-17 17:04:11.138083+00	2026-04-17 17:04:32.786422+00
84	1	11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64	2026-04-24 17:04:11.135+00	2026-04-17 17:04:11.136609+00	2026-04-17 17:04:32.786422+00
88	1	11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64	2026-04-24 17:04:11.132+00	2026-04-17 17:04:11.133216+00	2026-04-17 17:04:32.786422+00
89	1	11a26e0b0ecee3ec70d48bb601f6a1481a734e8e3ea068a9c47866246264fd64	2026-04-24 17:04:11.139+00	2026-04-17 17:04:11.140332+00	2026-04-17 17:04:32.786422+00
90	1	f41846e8b6891f4bef0205a3ca7603c5076835a115fe60f68cc94e7a54e26347	2026-04-24 17:04:32.785+00	2026-04-17 17:04:32.786422+00	2026-04-17 18:41:43.982785+00
\.


--
-- Data for Name: role_of_staff; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.role_of_staff (id, staff_id, role_id) FROM stdin;
2	1	5
3	1	1
4	2	1
5	2	3
6	3	1
7	3	3
8	4	1
9	4	3
10	5	4
11	5	6
12	6	2
13	7	2
14	8	2
15	9	6
16	10	2
\.


--
-- Data for Name: work_calendar; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.work_calendar (id, date, description, is_holiday, created_by, created_at) FROM stdin;
1	2026-04-30	Ngày Giải phóng miền Nam	t	1	2026-04-17 12:09:34.966774+00
2	2026-05-01	Ngày Quốc tế Lao động	t	1	2026-04-17 12:09:34.966774+00
3	2026-09-02	Ngày Quốc khánh	t	1	2026-04-17 12:09:34.966774+00
\.


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

\unrestrict aqCAIEULn3F8l7tK9vepLSezbuunMkcuGAAEZkMF5IvHhJJPkDP1cjVG1hWIbtV

