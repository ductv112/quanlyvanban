# TEST PLAN — Rà soát toàn bộ cập nhật session 2026-04-16

## Phạm vi test

### A. Batch 1-6: Audit + Fix 5 module VB
### B. 5 tính năng bổ sung  
### C. S1-S7: 7 sprint features

---

## CHECKLIST

### 1. DATABASE — Schema + SPs

| # | Test | Expected | Status |
|---|------|----------|--------|
| D1 | incoming_docs có cột sents, received_paper_date | Cả 2 cột tồn tại | |
| D2 | leader_notes có outgoing_doc_id, drafting_doc_id (nullable) | Cả 2 + XOR constraint | |
| D3 | staff_notes có is_important | boolean default false | |
| D4 | drafting_docs có reject_reason | text | |
| D5 | 3 attachment tables có description | text | |
| D6 | user_outgoing/drafting_docs có sent_by, expired_date | FK + timestamptz | |
| D7 | inter_incoming_docs có 8 cột LGSP mới | organ_id, from_organ_id... | |
| D8 | attachment_inter_incoming_docs table tồn tại | 10 cột | |
| D9 | send_doc_user_configs table tồn tại | S1 | |
| D10 | leader_notes có expired_date, assigned_staff_ids | S2 | |
| D11 | esto.document_archives table tồn tại | S3 | |
| D12 | doc_columns có data_type, max_length, is_system | S5 | |
| D13 | lgsp_config table tồn tại | S6 | |
| D14 | 3 attachment tables có is_ca, ca_date, signed_file_path | S7 | |

### 2. STORED PROCEDURES — Smoke test

| # | SP | Test | Expected |
|---|-----|------|----------|
| SP1 | fn_incoming_doc_get_by_id | Trả is_inter_doc, sents, received_paper_date | Có giá trị |
| SP2 | fn_outgoing_doc_get_by_id | Trả publish_unit_name | Tên đơn vị (không #ID) |
| SP3 | fn_drafting_doc_get_by_id | Trả publish_unit_name, reject_reason | Có giá trị |
| SP4 | fn_inter_incoming_get_by_id | Trả doc_type_name, created_by_name | JOIN hoạt động |
| SP5 | fn_incoming_doc_get_list | Filter signer, from_number, to_number | Không lỗi |
| SP6 | fn_outgoing_doc_check_number | Check trùng số | Trả boolean |
| SP7 | fn_outgoing_doc_retract (per-person) | p_staff_ids = NULL vs array | Cả 2 hoạt động |
| SP8 | fn_drafting_doc_reject | Lưu reject_reason | Cột có giá trị |
| SP9 | fn_staff_note_toggle | Truyền is_important | Lưu đúng |
| SP10 | fn_staff_note_get_list | Trả is_important | Có trong output |
| SP11 | fn_leader_note_create_outgoing | Tạo note cho VB đi | Success |
| SP12 | fn_leader_note_create_drafting | Tạo note cho dự thảo | Success |
| SP13 | fn_leader_note_comment_and_assign | Combo bút phê + phân công | Success + gửi VB |
| SP14 | fn_send_config_get_by_user | Lấy preset | Trả danh sách |
| SP15 | fn_send_config_save | Lưu config | Success |
| SP16 | fn_handling_doc_get_for_link | DS HSCV sẵn có | Trả records |
| SP17 | fn_outgoing_doc_get_unused_numbers | Số chưa phát hành | Trả gaps |
| SP18 | fn_lgsp_tracking_create (incoming_doc_id) | Hỗ trợ VB đến | Success |
| SP19 | fn_attachment_inter_incoming_create | Tạo đính kèm liên thông | Success |
| SP20 | esto.fn_document_archive_create | Chuyển lưu trữ | Success + set archive_status |
| SP21 | fn_lgsp_mock_receive | Mock nhận VB | Success |
| SP22 | fn_lgsp_mock_send | Mock gửi VB | Success |
| SP23 | fn_attachment_mock_sign | Mock ký số | Success, is_ca=true |
| SP24 | fn_attachment_mock_verify | Mock xác thực | is_valid=true/false |
| SP25 | fn_doc_column_get_by_type | Lấy columns | 8 records cho type 1 |
| SP26 | fn_doc_column_save | Lưu column | Success |

### 3. BACKEND — TypeScript compile + Route check

| # | Test | Expected |
|---|------|----------|
| B1 | tsc --noEmit | 0 errors trong files đã sửa |
| B2 | incoming-doc.ts: routes sents, signer filter, export, archive, HSCV, LGSP | Tồn tại |
| B3 | outgoing-doc.ts: routes export, leader notes, check number, giao viec, HSCV, LGSP, archive | Tồn tại |
| B4 | drafting-doc.ts: routes export, leader notes | Tồn tại |
| B5 | inter-incoming.ts: routes attachment CRUD | Tồn tại |
| B6 | digital-signature.ts: mock sign/verify routes | Tồn tại |
| B7 | send-config.ts: GET/POST routes | Tồn tại |
| B8 | admin-catalog.ts: doc column CRUD routes | Tồn tại |
| B9 | server.ts: mount /cau-hinh-gui-nhanh | Tồn tại |

### 4. FRONTEND — Files + Key changes

| # | Test | Expected |
|---|------|----------|
| F1 | VB đến page: sents trong interface, filter signer, nút Xuất Excel + In | Có |
| F2 | VB đến detail: is_inter_doc hiển thị nút, sents field, bút phê combo, HSCV, LGSP, archive, ký số | Có |
| F3 | VB đi page: nút Xuất Excel + In | Có |
| F4 | VB đi detail: publish_unit_name, ý kiến lãnh đạo, giao việc, HSCV, LGSP | Có |
| F5 | VB dự thảo page: api.post (không patch) phát hành, nút Xuất Excel + In, received_date | Có |
| F6 | VB dự thảo detail: publish_unit_name, reject_reason, ý kiến lãnh đạo | Có |
| F7 | VB liên thông: bỏ processing/cancelled, fix interface, file đính kèm | Có |
| F8 | VB đánh dấu: is_important star, filter tabs, rename Số VB | Có |
| F9 | Trang cấu hình gửi nhanh: Transfer component | Có |
| F10 | globals.css: @media print styles | Có |
