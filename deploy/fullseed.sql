--
-- PostgreSQL database dump
--

\restrict VaH2ZtMkMxebpmflnpFPFcnXeD2F39FpjnUgR3YnqiOHCnrEa9Pdj6GbLF0Pxlx

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

ALTER TABLE IF EXISTS ONLY public.staff DROP CONSTRAINT IF EXISTS staff_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY public.staff DROP CONSTRAINT IF EXISTS staff_position_id_fkey;
ALTER TABLE IF EXISTS ONLY public.staff DROP CONSTRAINT IF EXISTS staff_department_id_fkey;
ALTER TABLE IF EXISTS ONLY public.roles DROP CONSTRAINT IF EXISTS roles_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY public.role_of_staff DROP CONSTRAINT IF EXISTS role_of_staff_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY public.role_of_staff DROP CONSTRAINT IF EXISTS role_of_staff_role_id_fkey;
ALTER TABLE IF EXISTS ONLY public.rights DROP CONSTRAINT IF EXISTS rights_parent_id_fkey;
ALTER TABLE IF EXISTS ONLY public.refresh_tokens DROP CONSTRAINT IF EXISTS refresh_tokens_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY public.login_history DROP CONSTRAINT IF EXISTS login_history_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY public.districts DROP CONSTRAINT IF EXISTS districts_province_id_fkey;
ALTER TABLE IF EXISTS ONLY public.departments DROP CONSTRAINT IF EXISTS departments_parent_id_fkey;
ALTER TABLE IF EXISTS ONLY public.configurations DROP CONSTRAINT IF EXISTS configurations_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY public.communes DROP CONSTRAINT IF EXISTS communes_district_id_fkey;
ALTER TABLE IF EXISTS ONLY public.calendar_events DROP CONSTRAINT IF EXISTS calendar_events_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY public.calendar_events DROP CONSTRAINT IF EXISTS calendar_events_department_id_fkey;
ALTER TABLE IF EXISTS ONLY public.calendar_events DROP CONSTRAINT IF EXISTS calendar_events_created_by_fkey;
ALTER TABLE IF EXISTS ONLY public.action_of_role DROP CONSTRAINT IF EXISTS action_of_role_role_id_fkey;
ALTER TABLE IF EXISTS ONLY public.action_of_role DROP CONSTRAINT IF EXISTS action_of_role_right_id_fkey;
ALTER TABLE IF EXISTS ONLY iso.documents DROP CONSTRAINT IF EXISTS documents_department_id_fkey;
ALTER TABLE IF EXISTS ONLY iso.documents DROP CONSTRAINT IF EXISTS documents_category_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.warehouses DROP CONSTRAINT IF EXISTS warehouses_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.warehouses DROP CONSTRAINT IF EXISTS warehouses_department_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.records DROP CONSTRAINT IF EXISTS records_warehouse_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.records DROP CONSTRAINT IF EXISTS records_fond_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.records DROP CONSTRAINT IF EXISTS records_department_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.document_archives DROP CONSTRAINT IF EXISTS document_archives_warehouse_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.document_archives DROP CONSTRAINT IF EXISTS document_archives_record_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.document_archives DROP CONSTRAINT IF EXISTS document_archives_fond_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.document_archives DROP CONSTRAINT IF EXISTS document_archives_archived_by_fkey;
ALTER TABLE IF EXISTS ONLY esto.borrow_requests DROP CONSTRAINT IF EXISTS borrow_requests_department_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.borrow_request_records DROP CONSTRAINT IF EXISTS borrow_request_records_record_id_fkey;
ALTER TABLE IF EXISTS ONLY esto.borrow_request_records DROP CONSTRAINT IF EXISTS borrow_request_records_borrow_request_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.work_groups DROP CONSTRAINT IF EXISTS work_groups_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.work_group_members DROP CONSTRAINT IF EXISTS work_group_members_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.work_group_members DROP CONSTRAINT IF EXISTS work_group_members_group_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.user_outgoing_docs DROP CONSTRAINT IF EXISTS user_outgoing_docs_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.user_outgoing_docs DROP CONSTRAINT IF EXISTS user_outgoing_docs_sent_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.user_outgoing_docs DROP CONSTRAINT IF EXISTS user_outgoing_docs_outgoing_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.user_incoming_docs DROP CONSTRAINT IF EXISTS user_incoming_docs_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.user_incoming_docs DROP CONSTRAINT IF EXISTS user_incoming_docs_incoming_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.user_drafting_docs DROP CONSTRAINT IF EXISTS user_drafting_docs_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.user_drafting_docs DROP CONSTRAINT IF EXISTS user_drafting_docs_sent_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.user_drafting_docs DROP CONSTRAINT IF EXISTS user_drafting_docs_drafting_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.staff_notes DROP CONSTRAINT IF EXISTS staff_notes_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.staff_handling_docs DROP CONSTRAINT IF EXISTS staff_handling_docs_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.staff_handling_docs DROP CONSTRAINT IF EXISTS staff_handling_docs_handling_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.sms_templates DROP CONSTRAINT IF EXISTS sms_templates_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.signers DROP CONSTRAINT IF EXISTS signers_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.signers DROP CONSTRAINT IF EXISTS signers_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.signers DROP CONSTRAINT IF EXISTS signers_department_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.send_doc_user_configs DROP CONSTRAINT IF EXISTS send_doc_user_configs_user_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.send_doc_user_configs DROP CONSTRAINT IF EXISTS send_doc_user_configs_target_user_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedules DROP CONSTRAINT IF EXISTS room_schedules_room_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedules DROP CONSTRAINT IF EXISTS room_schedules_meeting_type_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedules DROP CONSTRAINT IF EXISTS room_schedules_department_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_votes DROP CONSTRAINT IF EXISTS room_schedule_votes_question_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_votes DROP CONSTRAINT IF EXISTS room_schedule_votes_answer_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_staff DROP CONSTRAINT IF EXISTS room_schedule_staff_room_schedule_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_questions DROP CONSTRAINT IF EXISTS room_schedule_questions_room_schedule_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_attachments DROP CONSTRAINT IF EXISTS room_schedule_attachments_room_schedule_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_answers DROP CONSTRAINT IF EXISTS room_schedule_answers_room_schedule_question_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_rejected_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_publish_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_drafting_user_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_drafting_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_doc_type_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_doc_field_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_doc_book_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_department_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.organizations DROP CONSTRAINT IF EXISTS organizations_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.opinion_handling_docs DROP CONSTRAINT IF EXISTS opinion_handling_docs_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.opinion_handling_docs DROP CONSTRAINT IF EXISTS opinion_handling_docs_handling_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.notification_preferences DROP CONSTRAINT IF EXISTS notification_preferences_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.notification_logs DROP CONSTRAINT IF EXISTS notification_logs_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.notices DROP CONSTRAINT IF EXISTS notices_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.notices DROP CONSTRAINT IF EXISTS notices_department_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.notices DROP CONSTRAINT IF EXISTS notices_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.notice_reads DROP CONSTRAINT IF EXISTS notice_reads_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.notice_reads DROP CONSTRAINT IF EXISTS notice_reads_notice_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.messages DROP CONSTRAINT IF EXISTS messages_parent_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.messages DROP CONSTRAINT IF EXISTS messages_from_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.message_recipients DROP CONSTRAINT IF EXISTS message_recipients_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.message_recipients DROP CONSTRAINT IF EXISTS message_recipients_message_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.lgsp_tracking DROP CONSTRAINT IF EXISTS lgsp_tracking_outgoing_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.lgsp_tracking DROP CONSTRAINT IF EXISTS lgsp_tracking_incoming_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.lgsp_tracking DROP CONSTRAINT IF EXISTS lgsp_tracking_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.lgsp_config DROP CONSTRAINT IF EXISTS lgsp_config_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.leader_notes DROP CONSTRAINT IF EXISTS leader_notes_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.leader_notes DROP CONSTRAINT IF EXISTS leader_notes_outgoing_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.leader_notes DROP CONSTRAINT IF EXISTS leader_notes_incoming_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.leader_notes DROP CONSTRAINT IF EXISTS leader_notes_drafting_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.inter_incoming_docs DROP CONSTRAINT IF EXISTS inter_incoming_docs_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.inter_incoming_docs DROP CONSTRAINT IF EXISTS inter_incoming_docs_doc_type_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.inter_incoming_docs DROP CONSTRAINT IF EXISTS inter_incoming_docs_doc_field_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.inter_incoming_docs DROP CONSTRAINT IF EXISTS inter_incoming_docs_department_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.inter_incoming_docs DROP CONSTRAINT IF EXISTS inter_incoming_docs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.incoming_docs DROP CONSTRAINT IF EXISTS incoming_docs_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.incoming_docs DROP CONSTRAINT IF EXISTS incoming_docs_rejected_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.incoming_docs DROP CONSTRAINT IF EXISTS incoming_docs_doc_type_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.incoming_docs DROP CONSTRAINT IF EXISTS incoming_docs_doc_field_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.incoming_docs DROP CONSTRAINT IF EXISTS incoming_docs_doc_book_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.incoming_docs DROP CONSTRAINT IF EXISTS incoming_docs_department_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.incoming_docs DROP CONSTRAINT IF EXISTS incoming_docs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_signer_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_publish_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_parent_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_drafting_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_doc_type_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_doc_field_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_doc_book_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_department_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_curator_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_complete_user_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_doc_links DROP CONSTRAINT IF EXISTS handling_doc_links_handling_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.email_templates DROP CONSTRAINT IF EXISTS email_templates_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_rejected_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_publish_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_drafting_user_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_drafting_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_doc_type_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_doc_field_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_doc_book_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_department_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_types DROP CONSTRAINT IF EXISTS doc_types_parent_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flows DROP CONSTRAINT IF EXISTS doc_flows_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flows DROP CONSTRAINT IF EXISTS doc_flows_doc_field_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flows DROP CONSTRAINT IF EXISTS doc_flows_department_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flows DROP CONSTRAINT IF EXISTS doc_flows_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flow_steps DROP CONSTRAINT IF EXISTS doc_flow_steps_flow_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flow_step_staff DROP CONSTRAINT IF EXISTS doc_flow_step_staff_step_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flow_step_staff DROP CONSTRAINT IF EXISTS doc_flow_step_staff_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flow_step_links DROP CONSTRAINT IF EXISTS doc_flow_step_links_to_step_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flow_step_links DROP CONSTRAINT IF EXISTS doc_flow_step_links_from_step_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_fields DROP CONSTRAINT IF EXISTS doc_fields_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_books DROP CONSTRAINT IF EXISTS doc_books_unit_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.digital_signatures DROP CONSTRAINT IF EXISTS digital_signatures_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.device_tokens DROP CONSTRAINT IF EXISTS device_tokens_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.delegations DROP CONSTRAINT IF EXISTS delegations_to_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.delegations DROP CONSTRAINT IF EXISTS delegations_from_staff_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_outgoing_docs DROP CONSTRAINT IF EXISTS attachment_outgoing_docs_outgoing_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_outgoing_docs DROP CONSTRAINT IF EXISTS attachment_outgoing_docs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_inter_incoming_docs DROP CONSTRAINT IF EXISTS attachment_inter_incoming_docs_inter_incoming_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_inter_incoming_docs DROP CONSTRAINT IF EXISTS attachment_inter_incoming_docs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_incoming_docs DROP CONSTRAINT IF EXISTS attachment_incoming_docs_incoming_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_incoming_docs DROP CONSTRAINT IF EXISTS attachment_incoming_docs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_handling_docs DROP CONSTRAINT IF EXISTS attachment_handling_docs_handling_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_handling_docs DROP CONSTRAINT IF EXISTS attachment_handling_docs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_drafting_docs DROP CONSTRAINT IF EXISTS attachment_drafting_docs_drafting_doc_id_fkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_drafting_docs DROP CONSTRAINT IF EXISTS attachment_drafting_docs_created_by_fkey;
ALTER TABLE IF EXISTS ONLY cont.contracts DROP CONSTRAINT IF EXISTS contracts_contract_type_id_fkey;
ALTER TABLE IF EXISTS ONLY cont.contract_attachments DROP CONSTRAINT IF EXISTS contract_attachments_contract_id_fkey;
DROP TRIGGER IF EXISTS trg_staff_updated_at ON public.staff;
DROP TRIGGER IF EXISTS trg_staff_auto_unit_id ON public.staff;
DROP TRIGGER IF EXISTS trg_roles_updated_at ON public.roles;
DROP TRIGGER IF EXISTS trg_positions_updated_at ON public.positions;
DROP TRIGGER IF EXISTS trg_departments_updated_at ON public.departments;
DROP TRIGGER IF EXISTS trg_outgoing_docs_updated_at ON edoc.outgoing_docs;
DROP TRIGGER IF EXISTS trg_incoming_docs_updated_at ON edoc.incoming_docs;
DROP TRIGGER IF EXISTS trg_handling_docs_updated_at ON edoc.handling_docs;
DROP TRIGGER IF EXISTS trg_drafting_docs_updated_at ON edoc.drafting_docs;
DROP TRIGGER IF EXISTS trg_doc_flows_updated_at ON edoc.doc_flows;
DROP INDEX IF EXISTS public.idx_staff_username;
DROP INDEX IF EXISTS public.idx_staff_unit;
DROP INDEX IF EXISTS public.idx_staff_fullname;
DROP INDEX IF EXISTS public.idx_staff_department;
DROP INDEX IF EXISTS public.idx_rights_parent;
DROP INDEX IF EXISTS public.idx_refresh_tokens_staff;
DROP INDEX IF EXISTS public.idx_refresh_tokens_hash;
DROP INDEX IF EXISTS public.idx_login_history_staff;
DROP INDEX IF EXISTS public.idx_departments_parent;
DROP INDEX IF EXISTS public.idx_departments_is_unit;
DROP INDEX IF EXISTS public.idx_calendar_events_scope_unit_start;
DROP INDEX IF EXISTS public.idx_calendar_events_is_deleted;
DROP INDEX IF EXISTS public.idx_calendar_events_department;
DROP INDEX IF EXISTS public.idx_calendar_events_created_by_start;
DROP INDEX IF EXISTS iso.uq_doc_categories_code;
DROP INDEX IF EXISTS iso.idx_documents_unit_id;
DROP INDEX IF EXISTS iso.idx_documents_department;
DROP INDEX IF EXISTS iso.idx_documents_category_id;
DROP INDEX IF EXISTS esto.uq_warehouses_code;
DROP INDEX IF EXISTS esto.uq_fonds_code;
DROP INDEX IF EXISTS esto.idx_warehouses_unit_id;
DROP INDEX IF EXISTS esto.idx_warehouses_parent_id;
DROP INDEX IF EXISTS esto.idx_warehouses_department;
DROP INDEX IF EXISTS esto.idx_records_warehouse_id;
DROP INDEX IF EXISTS esto.idx_records_unit_id;
DROP INDEX IF EXISTS esto.idx_records_fond_id;
DROP INDEX IF EXISTS esto.idx_records_department;
DROP INDEX IF EXISTS esto.idx_fonds_unit_id;
DROP INDEX IF EXISTS esto.idx_doc_archives_doc;
DROP INDEX IF EXISTS esto.idx_borrow_requests_unit_id;
DROP INDEX IF EXISTS esto.idx_borrow_requests_status;
DROP INDEX IF EXISTS esto.idx_borrow_requests_department;
DROP INDEX IF EXISTS edoc.uq_rooms_code;
DROP INDEX IF EXISTS edoc.idx_user_outgoing_docs_staff;
DROP INDEX IF EXISTS edoc.idx_user_incoming_docs_staff;
DROP INDEX IF EXISTS edoc.idx_user_drafting_docs_staff;
DROP INDEX IF EXISTS edoc.idx_staff_handling_docs_staff;
DROP INDEX IF EXISTS edoc.idx_send_config_user;
DROP INDEX IF EXISTS edoc.idx_room_schedules_unit_id;
DROP INDEX IF EXISTS edoc.idx_room_schedules_start_date;
DROP INDEX IF EXISTS edoc.idx_room_schedules_room_id;
DROP INDEX IF EXISTS edoc.idx_room_schedules_department;
DROP INDEX IF EXISTS edoc.idx_questions_room_schedule_id;
DROP INDEX IF EXISTS edoc.idx_outgoing_docs_unit;
DROP INDEX IF EXISTS edoc.idx_outgoing_docs_search;
DROP INDEX IF EXISTS edoc.idx_outgoing_docs_department;
DROP INDEX IF EXISTS edoc.idx_notif_log_status;
DROP INDEX IF EXISTS edoc.idx_notif_log_staff;
DROP INDEX IF EXISTS edoc.idx_notif_log_created;
DROP INDEX IF EXISTS edoc.idx_notif_log_channel;
DROP INDEX IF EXISTS edoc.idx_notices_unit_id;
DROP INDEX IF EXISTS edoc.idx_notices_department;
DROP INDEX IF EXISTS edoc.idx_notices_created_at;
DROP INDEX IF EXISTS edoc.idx_msg_recipients_staff_id;
DROP INDEX IF EXISTS edoc.idx_msg_recipients_message_id;
DROP INDEX IF EXISTS edoc.idx_messages_parent_id;
DROP INDEX IF EXISTS edoc.idx_messages_from_staff;
DROP INDEX IF EXISTS edoc.idx_lgsp_tracking_status;
DROP INDEX IF EXISTS edoc.idx_lgsp_tracking_outgoing;
DROP INDEX IF EXISTS edoc.idx_lgsp_tracking_direction;
DROP INDEX IF EXISTS edoc.idx_leader_notes_outgoing;
DROP INDEX IF EXISTS edoc.idx_leader_notes_drafting;
DROP INDEX IF EXISTS edoc.idx_inter_incoming_unit_id;
DROP INDEX IF EXISTS edoc.idx_inter_incoming_status;
DROP INDEX IF EXISTS edoc.idx_inter_incoming_received_date;
DROP INDEX IF EXISTS edoc.idx_inter_incoming_organ;
DROP INDEX IF EXISTS edoc.idx_inter_incoming_external;
DROP INDEX IF EXISTS edoc.idx_inter_incoming_department;
DROP INDEX IF EXISTS edoc.idx_incoming_docs_unit;
DROP INDEX IF EXISTS edoc.idx_incoming_docs_search;
DROP INDEX IF EXISTS edoc.idx_incoming_docs_number;
DROP INDEX IF EXISTS edoc.idx_incoming_docs_notation;
DROP INDEX IF EXISTS edoc.idx_incoming_docs_department;
DROP INDEX IF EXISTS edoc.idx_handling_docs_unit;
DROP INDEX IF EXISTS edoc.idx_handling_docs_search;
DROP INDEX IF EXISTS edoc.idx_handling_docs_curator;
DROP INDEX IF EXISTS edoc.idx_drafting_docs_unit;
DROP INDEX IF EXISTS edoc.idx_drafting_docs_search;
DROP INDEX IF EXISTS edoc.idx_drafting_docs_department;
DROP INDEX IF EXISTS edoc.idx_doc_flows_unit;
DROP INDEX IF EXISTS edoc.idx_doc_flows_department;
DROP INDEX IF EXISTS edoc.idx_doc_flow_steps_flow;
DROP INDEX IF EXISTS edoc.idx_doc_flow_step_staff_step;
DROP INDEX IF EXISTS edoc.idx_doc_columns_type;
DROP INDEX IF EXISTS edoc.idx_digsig_status;
DROP INDEX IF EXISTS edoc.idx_digsig_staff;
DROP INDEX IF EXISTS edoc.idx_digsig_doc;
DROP INDEX IF EXISTS edoc.idx_device_tokens_staff;
DROP INDEX IF EXISTS edoc.idx_delegations_to;
DROP INDEX IF EXISTS edoc.idx_delegations_from;
DROP INDEX IF EXISTS edoc.idx_attach_inter_incoming_doc;
DROP INDEX IF EXISTS cont.uq_contract_types_code;
DROP INDEX IF EXISTS cont.idx_contracts_unit_id;
DROP INDEX IF EXISTS cont.idx_contracts_contract_type_id;
ALTER TABLE IF EXISTS ONLY public.work_calendar DROP CONSTRAINT IF EXISTS work_calendar_pkey;
ALTER TABLE IF EXISTS ONLY public.work_calendar DROP CONSTRAINT IF EXISTS work_calendar_date_key;
ALTER TABLE IF EXISTS ONLY public.staff DROP CONSTRAINT IF EXISTS staff_username_key;
ALTER TABLE IF EXISTS ONLY public.staff DROP CONSTRAINT IF EXISTS staff_pkey;
ALTER TABLE IF EXISTS ONLY public.roles DROP CONSTRAINT IF EXISTS roles_pkey;
ALTER TABLE IF EXISTS ONLY public.role_of_staff DROP CONSTRAINT IF EXISTS role_of_staff_staff_id_role_id_key;
ALTER TABLE IF EXISTS ONLY public.role_of_staff DROP CONSTRAINT IF EXISTS role_of_staff_pkey;
ALTER TABLE IF EXISTS ONLY public.rights DROP CONSTRAINT IF EXISTS rights_pkey;
ALTER TABLE IF EXISTS ONLY public.refresh_tokens DROP CONSTRAINT IF EXISTS refresh_tokens_pkey;
ALTER TABLE IF EXISTS ONLY public.provinces DROP CONSTRAINT IF EXISTS provinces_pkey;
ALTER TABLE IF EXISTS ONLY public.positions DROP CONSTRAINT IF EXISTS positions_pkey;
ALTER TABLE IF EXISTS ONLY public.login_history DROP CONSTRAINT IF EXISTS login_history_pkey;
ALTER TABLE IF EXISTS ONLY public.districts DROP CONSTRAINT IF EXISTS districts_pkey;
ALTER TABLE IF EXISTS ONLY public.departments DROP CONSTRAINT IF EXISTS departments_pkey;
ALTER TABLE IF EXISTS ONLY public.configurations DROP CONSTRAINT IF EXISTS configurations_unit_id_key_key;
ALTER TABLE IF EXISTS ONLY public.configurations DROP CONSTRAINT IF EXISTS configurations_pkey;
ALTER TABLE IF EXISTS ONLY public.communes DROP CONSTRAINT IF EXISTS communes_pkey;
ALTER TABLE IF EXISTS ONLY public.calendar_events DROP CONSTRAINT IF EXISTS calendar_events_pkey;
ALTER TABLE IF EXISTS ONLY public.action_of_role DROP CONSTRAINT IF EXISTS action_of_role_role_id_right_id_key;
ALTER TABLE IF EXISTS ONLY public.action_of_role DROP CONSTRAINT IF EXISTS action_of_role_pkey;
ALTER TABLE IF EXISTS ONLY iso.documents DROP CONSTRAINT IF EXISTS documents_pkey;
ALTER TABLE IF EXISTS ONLY iso.document_categories DROP CONSTRAINT IF EXISTS document_categories_pkey;
ALTER TABLE IF EXISTS ONLY esto.warehouses DROP CONSTRAINT IF EXISTS warehouses_pkey;
ALTER TABLE IF EXISTS ONLY esto.records DROP CONSTRAINT IF EXISTS records_pkey;
ALTER TABLE IF EXISTS ONLY esto.fonds DROP CONSTRAINT IF EXISTS fonds_pkey;
ALTER TABLE IF EXISTS ONLY esto.document_archives DROP CONSTRAINT IF EXISTS document_archives_pkey;
ALTER TABLE IF EXISTS ONLY esto.document_archives DROP CONSTRAINT IF EXISTS document_archives_doc_type_doc_id_key;
ALTER TABLE IF EXISTS ONLY esto.borrow_requests DROP CONSTRAINT IF EXISTS borrow_requests_pkey;
ALTER TABLE IF EXISTS ONLY esto.borrow_request_records DROP CONSTRAINT IF EXISTS borrow_request_records_pkey;
ALTER TABLE IF EXISTS ONLY esto.borrow_request_records DROP CONSTRAINT IF EXISTS borrow_request_records_borrow_request_id_record_id_key;
ALTER TABLE IF EXISTS ONLY edoc.work_groups DROP CONSTRAINT IF EXISTS work_groups_pkey;
ALTER TABLE IF EXISTS ONLY edoc.work_group_members DROP CONSTRAINT IF EXISTS work_group_members_pkey;
ALTER TABLE IF EXISTS ONLY edoc.work_group_members DROP CONSTRAINT IF EXISTS work_group_members_group_id_staff_id_key;
ALTER TABLE IF EXISTS ONLY edoc.user_outgoing_docs DROP CONSTRAINT IF EXISTS user_outgoing_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.user_outgoing_docs DROP CONSTRAINT IF EXISTS user_outgoing_docs_outgoing_doc_id_staff_id_key;
ALTER TABLE IF EXISTS ONLY edoc.user_incoming_docs DROP CONSTRAINT IF EXISTS user_incoming_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.user_incoming_docs DROP CONSTRAINT IF EXISTS user_incoming_docs_incoming_doc_id_staff_id_key;
ALTER TABLE IF EXISTS ONLY edoc.user_drafting_docs DROP CONSTRAINT IF EXISTS user_drafting_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.user_drafting_docs DROP CONSTRAINT IF EXISTS user_drafting_docs_drafting_doc_id_staff_id_key;
ALTER TABLE IF EXISTS ONLY edoc.notification_preferences DROP CONSTRAINT IF EXISTS uq_notif_pref_staff_channel;
ALTER TABLE IF EXISTS ONLY edoc.notice_reads DROP CONSTRAINT IF EXISTS uq_notice_reads_notice_staff;
ALTER TABLE IF EXISTS ONLY edoc.message_recipients DROP CONSTRAINT IF EXISTS uq_msg_recipients_message_staff;
ALTER TABLE IF EXISTS ONLY edoc.lgsp_organizations DROP CONSTRAINT IF EXISTS uq_lgsp_org_code;
ALTER TABLE IF EXISTS ONLY edoc.doc_flows DROP CONSTRAINT IF EXISTS uq_doc_flows_unit_name_version;
ALTER TABLE IF EXISTS ONLY edoc.doc_flow_step_staff DROP CONSTRAINT IF EXISTS uq_doc_flow_step_staff;
ALTER TABLE IF EXISTS ONLY edoc.doc_flow_step_links DROP CONSTRAINT IF EXISTS uq_doc_flow_step_links;
ALTER TABLE IF EXISTS ONLY edoc.device_tokens DROP CONSTRAINT IF EXISTS uq_device_token;
ALTER TABLE IF EXISTS ONLY edoc.staff_notes DROP CONSTRAINT IF EXISTS staff_notes_pkey;
ALTER TABLE IF EXISTS ONLY edoc.staff_notes DROP CONSTRAINT IF EXISTS staff_notes_doc_type_doc_id_staff_id_key;
ALTER TABLE IF EXISTS ONLY edoc.staff_handling_docs DROP CONSTRAINT IF EXISTS staff_handling_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.sms_templates DROP CONSTRAINT IF EXISTS sms_templates_pkey;
ALTER TABLE IF EXISTS ONLY edoc.signers DROP CONSTRAINT IF EXISTS signers_unit_id_staff_id_key;
ALTER TABLE IF EXISTS ONLY edoc.signers DROP CONSTRAINT IF EXISTS signers_pkey;
ALTER TABLE IF EXISTS ONLY edoc.send_doc_user_configs DROP CONSTRAINT IF EXISTS send_doc_user_configs_user_id_target_user_id_config_type_key;
ALTER TABLE IF EXISTS ONLY edoc.send_doc_user_configs DROP CONSTRAINT IF EXISTS send_doc_user_configs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.rooms DROP CONSTRAINT IF EXISTS rooms_pkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedules DROP CONSTRAINT IF EXISTS room_schedules_pkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_votes DROP CONSTRAINT IF EXISTS room_schedule_votes_question_id_staff_id_key;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_votes DROP CONSTRAINT IF EXISTS room_schedule_votes_pkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_staff DROP CONSTRAINT IF EXISTS room_schedule_staff_room_schedule_id_staff_id_key;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_staff DROP CONSTRAINT IF EXISTS room_schedule_staff_pkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_questions DROP CONSTRAINT IF EXISTS room_schedule_questions_pkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_attachments DROP CONSTRAINT IF EXISTS room_schedule_attachments_pkey;
ALTER TABLE IF EXISTS ONLY edoc.room_schedule_answers DROP CONSTRAINT IF EXISTS room_schedule_answers_pkey;
ALTER TABLE IF EXISTS ONLY edoc.outgoing_docs DROP CONSTRAINT IF EXISTS outgoing_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.organizations DROP CONSTRAINT IF EXISTS organizations_unit_id_key;
ALTER TABLE IF EXISTS ONLY edoc.organizations DROP CONSTRAINT IF EXISTS organizations_pkey;
ALTER TABLE IF EXISTS ONLY edoc.opinion_handling_docs DROP CONSTRAINT IF EXISTS opinion_handling_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.notification_preferences DROP CONSTRAINT IF EXISTS notification_preferences_pkey;
ALTER TABLE IF EXISTS ONLY edoc.notification_logs DROP CONSTRAINT IF EXISTS notification_logs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.notices DROP CONSTRAINT IF EXISTS notices_pkey;
ALTER TABLE IF EXISTS ONLY edoc.notice_reads DROP CONSTRAINT IF EXISTS notice_reads_pkey;
ALTER TABLE IF EXISTS ONLY edoc.messages DROP CONSTRAINT IF EXISTS messages_pkey;
ALTER TABLE IF EXISTS ONLY edoc.message_recipients DROP CONSTRAINT IF EXISTS message_recipients_pkey;
ALTER TABLE IF EXISTS ONLY edoc.meeting_types DROP CONSTRAINT IF EXISTS meeting_types_pkey;
ALTER TABLE IF EXISTS ONLY edoc.lgsp_tracking DROP CONSTRAINT IF EXISTS lgsp_tracking_pkey;
ALTER TABLE IF EXISTS ONLY edoc.lgsp_organizations DROP CONSTRAINT IF EXISTS lgsp_organizations_pkey;
ALTER TABLE IF EXISTS ONLY edoc.lgsp_config DROP CONSTRAINT IF EXISTS lgsp_config_pkey;
ALTER TABLE IF EXISTS ONLY edoc.leader_notes DROP CONSTRAINT IF EXISTS leader_notes_pkey;
ALTER TABLE IF EXISTS ONLY edoc.inter_incoming_docs DROP CONSTRAINT IF EXISTS inter_incoming_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.incoming_docs DROP CONSTRAINT IF EXISTS incoming_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_docs DROP CONSTRAINT IF EXISTS handling_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_doc_links DROP CONSTRAINT IF EXISTS handling_doc_links_pkey;
ALTER TABLE IF EXISTS ONLY edoc.handling_doc_links DROP CONSTRAINT IF EXISTS handling_doc_links_handling_doc_id_doc_type_doc_id_key;
ALTER TABLE IF EXISTS ONLY edoc.email_templates DROP CONSTRAINT IF EXISTS email_templates_pkey;
ALTER TABLE IF EXISTS ONLY edoc.drafting_docs DROP CONSTRAINT IF EXISTS drafting_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_types DROP CONSTRAINT IF EXISTS doc_types_pkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flows DROP CONSTRAINT IF EXISTS doc_flows_pkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flow_steps DROP CONSTRAINT IF EXISTS doc_flow_steps_pkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flow_step_staff DROP CONSTRAINT IF EXISTS doc_flow_step_staff_pkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_flow_step_links DROP CONSTRAINT IF EXISTS doc_flow_step_links_pkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_fields DROP CONSTRAINT IF EXISTS doc_fields_pkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_columns DROP CONSTRAINT IF EXISTS doc_columns_type_id_column_name_key;
ALTER TABLE IF EXISTS ONLY edoc.doc_columns DROP CONSTRAINT IF EXISTS doc_columns_pkey;
ALTER TABLE IF EXISTS ONLY edoc.doc_books DROP CONSTRAINT IF EXISTS doc_books_pkey;
ALTER TABLE IF EXISTS ONLY edoc.digital_signatures DROP CONSTRAINT IF EXISTS digital_signatures_pkey;
ALTER TABLE IF EXISTS ONLY edoc.device_tokens DROP CONSTRAINT IF EXISTS device_tokens_pkey;
ALTER TABLE IF EXISTS ONLY edoc.delegations DROP CONSTRAINT IF EXISTS delegations_pkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_outgoing_docs DROP CONSTRAINT IF EXISTS attachment_outgoing_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_inter_incoming_docs DROP CONSTRAINT IF EXISTS attachment_inter_incoming_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_incoming_docs DROP CONSTRAINT IF EXISTS attachment_incoming_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_handling_docs DROP CONSTRAINT IF EXISTS attachment_handling_docs_pkey;
ALTER TABLE IF EXISTS ONLY edoc.attachment_drafting_docs DROP CONSTRAINT IF EXISTS attachment_drafting_docs_pkey;
ALTER TABLE IF EXISTS ONLY cont.contracts DROP CONSTRAINT IF EXISTS contracts_pkey;
ALTER TABLE IF EXISTS ONLY cont.contract_types DROP CONSTRAINT IF EXISTS contract_types_pkey;
ALTER TABLE IF EXISTS ONLY cont.contract_attachments DROP CONSTRAINT IF EXISTS contract_attachments_pkey;
ALTER TABLE IF EXISTS public.work_calendar ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.staff ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.roles ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.role_of_staff ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.rights ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.refresh_tokens ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.provinces ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.positions ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.login_history ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.districts ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.departments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.configurations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.communes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.calendar_events ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS public.action_of_role ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS iso.documents ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS iso.document_categories ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS esto.warehouses ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS esto.records ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS esto.fonds ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS esto.document_archives ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS esto.borrow_requests ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS esto.borrow_request_records ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.work_groups ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.work_group_members ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.user_outgoing_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.user_incoming_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.user_drafting_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.staff_notes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.staff_handling_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.sms_templates ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.signers ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.send_doc_user_configs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.rooms ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.room_schedules ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.room_schedule_votes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.room_schedule_staff ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.room_schedule_attachments ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.outgoing_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.organizations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.opinion_handling_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.notification_preferences ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.notification_logs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.notices ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.notice_reads ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.messages ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.message_recipients ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.meeting_types ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.lgsp_tracking ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.lgsp_organizations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.lgsp_config ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.leader_notes ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.inter_incoming_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.incoming_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.handling_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.handling_doc_links ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.email_templates ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.drafting_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.doc_types ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.doc_flows ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.doc_flow_steps ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.doc_flow_step_staff ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.doc_flow_step_links ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.doc_fields ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.doc_columns ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.doc_books ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.digital_signatures ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.device_tokens ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.delegations ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.attachment_outgoing_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.attachment_inter_incoming_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.attachment_incoming_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.attachment_handling_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS edoc.attachment_drafting_docs ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS cont.contracts ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS cont.contract_types ALTER COLUMN id DROP DEFAULT;
ALTER TABLE IF EXISTS cont.contract_attachments ALTER COLUMN id DROP DEFAULT;
DROP SEQUENCE IF EXISTS public.work_calendar_id_seq;
DROP TABLE IF EXISTS public.work_calendar;
DROP SEQUENCE IF EXISTS public.staff_id_seq;
DROP TABLE IF EXISTS public.staff;
DROP SEQUENCE IF EXISTS public.seq_staff_code;
DROP SEQUENCE IF EXISTS public.roles_id_seq;
DROP TABLE IF EXISTS public.roles;
DROP SEQUENCE IF EXISTS public.role_of_staff_id_seq;
DROP TABLE IF EXISTS public.role_of_staff;
DROP SEQUENCE IF EXISTS public.rights_id_seq;
DROP TABLE IF EXISTS public.rights;
DROP SEQUENCE IF EXISTS public.refresh_tokens_id_seq;
DROP TABLE IF EXISTS public.refresh_tokens;
DROP SEQUENCE IF EXISTS public.provinces_id_seq;
DROP TABLE IF EXISTS public.provinces;
DROP SEQUENCE IF EXISTS public.positions_id_seq;
DROP TABLE IF EXISTS public.positions;
DROP SEQUENCE IF EXISTS public.login_history_id_seq;
DROP TABLE IF EXISTS public.login_history;
DROP SEQUENCE IF EXISTS public.districts_id_seq;
DROP TABLE IF EXISTS public.districts;
DROP SEQUENCE IF EXISTS public.departments_id_seq;
DROP TABLE IF EXISTS public.departments;
DROP SEQUENCE IF EXISTS public.configurations_id_seq;
DROP TABLE IF EXISTS public.configurations;
DROP SEQUENCE IF EXISTS public.communes_id_seq;
DROP TABLE IF EXISTS public.communes;
DROP SEQUENCE IF EXISTS public.calendar_events_id_seq;
DROP TABLE IF EXISTS public.calendar_events;
DROP SEQUENCE IF EXISTS public.action_of_role_id_seq;
DROP TABLE IF EXISTS public.action_of_role;
DROP SEQUENCE IF EXISTS iso.documents_id_seq;
DROP TABLE IF EXISTS iso.documents;
DROP SEQUENCE IF EXISTS iso.document_categories_id_seq;
DROP TABLE IF EXISTS iso.document_categories;
DROP SEQUENCE IF EXISTS esto.warehouses_id_seq;
DROP TABLE IF EXISTS esto.warehouses;
DROP SEQUENCE IF EXISTS esto.records_id_seq;
DROP TABLE IF EXISTS esto.records;
DROP SEQUENCE IF EXISTS esto.fonds_id_seq;
DROP TABLE IF EXISTS esto.fonds;
DROP SEQUENCE IF EXISTS esto.document_archives_id_seq;
DROP TABLE IF EXISTS esto.document_archives;
DROP SEQUENCE IF EXISTS esto.borrow_requests_id_seq;
DROP TABLE IF EXISTS esto.borrow_requests;
DROP SEQUENCE IF EXISTS esto.borrow_request_records_id_seq;
DROP TABLE IF EXISTS esto.borrow_request_records;
DROP SEQUENCE IF EXISTS edoc.work_groups_id_seq;
DROP TABLE IF EXISTS edoc.work_groups;
DROP SEQUENCE IF EXISTS edoc.work_group_members_id_seq;
DROP TABLE IF EXISTS edoc.work_group_members;
DROP SEQUENCE IF EXISTS edoc.user_outgoing_docs_id_seq;
DROP TABLE IF EXISTS edoc.user_outgoing_docs;
DROP SEQUENCE IF EXISTS edoc.user_incoming_docs_id_seq;
DROP TABLE IF EXISTS edoc.user_incoming_docs;
DROP SEQUENCE IF EXISTS edoc.user_drafting_docs_id_seq;
DROP TABLE IF EXISTS edoc.user_drafting_docs;
DROP SEQUENCE IF EXISTS edoc.staff_notes_id_seq;
DROP TABLE IF EXISTS edoc.staff_notes;
DROP SEQUENCE IF EXISTS edoc.staff_handling_docs_id_seq;
DROP TABLE IF EXISTS edoc.staff_handling_docs;
DROP SEQUENCE IF EXISTS edoc.sms_templates_id_seq;
DROP TABLE IF EXISTS edoc.sms_templates;
DROP SEQUENCE IF EXISTS edoc.signers_id_seq;
DROP TABLE IF EXISTS edoc.signers;
DROP SEQUENCE IF EXISTS edoc.send_doc_user_configs_id_seq;
DROP TABLE IF EXISTS edoc.send_doc_user_configs;
DROP SEQUENCE IF EXISTS edoc.rooms_id_seq;
DROP TABLE IF EXISTS edoc.rooms;
DROP SEQUENCE IF EXISTS edoc.room_schedules_id_seq;
DROP TABLE IF EXISTS edoc.room_schedules;
DROP SEQUENCE IF EXISTS edoc.room_schedule_votes_id_seq;
DROP TABLE IF EXISTS edoc.room_schedule_votes;
DROP SEQUENCE IF EXISTS edoc.room_schedule_staff_id_seq;
DROP TABLE IF EXISTS edoc.room_schedule_staff;
DROP TABLE IF EXISTS edoc.room_schedule_questions;
DROP SEQUENCE IF EXISTS edoc.room_schedule_attachments_id_seq;
DROP TABLE IF EXISTS edoc.room_schedule_attachments;
DROP TABLE IF EXISTS edoc.room_schedule_answers;
DROP SEQUENCE IF EXISTS edoc.outgoing_docs_id_seq;
DROP TABLE IF EXISTS edoc.outgoing_docs;
DROP SEQUENCE IF EXISTS edoc.organizations_id_seq;
DROP TABLE IF EXISTS edoc.organizations;
DROP SEQUENCE IF EXISTS edoc.opinion_handling_docs_id_seq;
DROP TABLE IF EXISTS edoc.opinion_handling_docs;
DROP SEQUENCE IF EXISTS edoc.notification_preferences_id_seq;
DROP TABLE IF EXISTS edoc.notification_preferences;
DROP SEQUENCE IF EXISTS edoc.notification_logs_id_seq;
DROP TABLE IF EXISTS edoc.notification_logs;
DROP SEQUENCE IF EXISTS edoc.notices_id_seq;
DROP TABLE IF EXISTS edoc.notices;
DROP SEQUENCE IF EXISTS edoc.notice_reads_id_seq;
DROP TABLE IF EXISTS edoc.notice_reads;
DROP SEQUENCE IF EXISTS edoc.messages_id_seq;
DROP TABLE IF EXISTS edoc.messages;
DROP SEQUENCE IF EXISTS edoc.message_recipients_id_seq;
DROP TABLE IF EXISTS edoc.message_recipients;
DROP SEQUENCE IF EXISTS edoc.meeting_types_id_seq;
DROP TABLE IF EXISTS edoc.meeting_types;
DROP SEQUENCE IF EXISTS edoc.lgsp_tracking_id_seq;
DROP TABLE IF EXISTS edoc.lgsp_tracking;
DROP SEQUENCE IF EXISTS edoc.lgsp_organizations_id_seq;
DROP TABLE IF EXISTS edoc.lgsp_organizations;
DROP SEQUENCE IF EXISTS edoc.lgsp_config_id_seq;
DROP TABLE IF EXISTS edoc.lgsp_config;
DROP SEQUENCE IF EXISTS edoc.leader_notes_id_seq;
DROP TABLE IF EXISTS edoc.leader_notes;
DROP SEQUENCE IF EXISTS edoc.inter_incoming_docs_id_seq;
DROP TABLE IF EXISTS edoc.inter_incoming_docs;
DROP SEQUENCE IF EXISTS edoc.incoming_docs_id_seq;
DROP TABLE IF EXISTS edoc.incoming_docs;
DROP SEQUENCE IF EXISTS edoc.handling_docs_id_seq;
DROP TABLE IF EXISTS edoc.handling_docs;
DROP SEQUENCE IF EXISTS edoc.handling_doc_links_id_seq;
DROP TABLE IF EXISTS edoc.handling_doc_links;
DROP SEQUENCE IF EXISTS edoc.email_templates_id_seq;
DROP TABLE IF EXISTS edoc.email_templates;
DROP SEQUENCE IF EXISTS edoc.drafting_docs_id_seq;
DROP TABLE IF EXISTS edoc.drafting_docs;
DROP SEQUENCE IF EXISTS edoc.doc_types_id_seq;
DROP TABLE IF EXISTS edoc.doc_types;
DROP SEQUENCE IF EXISTS edoc.doc_flows_id_seq;
DROP TABLE IF EXISTS edoc.doc_flows;
DROP SEQUENCE IF EXISTS edoc.doc_flow_steps_id_seq;
DROP TABLE IF EXISTS edoc.doc_flow_steps;
DROP SEQUENCE IF EXISTS edoc.doc_flow_step_staff_id_seq;
DROP TABLE IF EXISTS edoc.doc_flow_step_staff;
DROP SEQUENCE IF EXISTS edoc.doc_flow_step_links_id_seq;
DROP TABLE IF EXISTS edoc.doc_flow_step_links;
DROP SEQUENCE IF EXISTS edoc.doc_fields_id_seq;
DROP TABLE IF EXISTS edoc.doc_fields;
DROP SEQUENCE IF EXISTS edoc.doc_columns_id_seq;
DROP TABLE IF EXISTS edoc.doc_columns;
DROP SEQUENCE IF EXISTS edoc.doc_books_id_seq;
DROP TABLE IF EXISTS edoc.doc_books;
DROP SEQUENCE IF EXISTS edoc.digital_signatures_id_seq;
DROP TABLE IF EXISTS edoc.digital_signatures;
DROP SEQUENCE IF EXISTS edoc.device_tokens_id_seq;
DROP TABLE IF EXISTS edoc.device_tokens;
DROP SEQUENCE IF EXISTS edoc.delegations_id_seq;
DROP TABLE IF EXISTS edoc.delegations;
DROP SEQUENCE IF EXISTS edoc.attachment_outgoing_docs_id_seq;
DROP TABLE IF EXISTS edoc.attachment_outgoing_docs;
DROP SEQUENCE IF EXISTS edoc.attachment_inter_incoming_docs_id_seq;
DROP TABLE IF EXISTS edoc.attachment_inter_incoming_docs;
DROP SEQUENCE IF EXISTS edoc.attachment_incoming_docs_id_seq;
DROP TABLE IF EXISTS edoc.attachment_incoming_docs;
DROP SEQUENCE IF EXISTS edoc.attachment_handling_docs_id_seq;
DROP TABLE IF EXISTS edoc.attachment_handling_docs;
DROP SEQUENCE IF EXISTS edoc.attachment_drafting_docs_id_seq;
DROP TABLE IF EXISTS edoc.attachment_drafting_docs;
DROP SEQUENCE IF EXISTS cont.contracts_id_seq;
DROP TABLE IF EXISTS cont.contracts;
DROP SEQUENCE IF EXISTS cont.contract_types_id_seq;
DROP TABLE IF EXISTS cont.contract_types;
DROP SEQUENCE IF EXISTS cont.contract_attachments_id_seq;
DROP TABLE IF EXISTS cont.contract_attachments;
DROP FUNCTION IF EXISTS public.fn_work_calendar_set_holiday(p_date date, p_description character varying, p_created_by integer);
DROP FUNCTION IF EXISTS public.fn_work_calendar_remove_holiday(p_date date);
DROP FUNCTION IF EXISTS public.fn_work_calendar_get(p_year integer);
DROP FUNCTION IF EXISTS public.fn_update_timestamp();
DROP FUNCTION IF EXISTS public.fn_staff_update_avatar(p_id integer, p_image_path character varying);
DROP FUNCTION IF EXISTS public.fn_staff_update(p_id integer, p_department_id integer, p_unit_id integer, p_position_id integer, p_first_name character varying, p_last_name character varying, p_gender smallint, p_birth_date date, p_email character varying, p_phone character varying, p_mobile character varying, p_address text, p_id_card character varying, p_id_card_date date, p_id_card_place character varying, p_is_admin boolean, p_is_represent_unit boolean, p_is_represent_department boolean, p_updated_by integer);
DROP FUNCTION IF EXISTS public.fn_staff_toggle_lock(p_id integer);
DROP FUNCTION IF EXISTS public.fn_staff_reset_password(p_id integer, p_new_password_hash character varying);
DROP FUNCTION IF EXISTS public.fn_staff_get_roles(p_staff_id integer);
DROP FUNCTION IF EXISTS public.fn_staff_get_list(p_unit_id integer, p_department_id integer, p_keyword character varying, p_is_locked boolean, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS public.fn_staff_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS public.fn_staff_generate_code();
DROP FUNCTION IF EXISTS public.fn_staff_delete(p_id integer);
DROP FUNCTION IF EXISTS public.fn_staff_create(p_department_id integer, p_unit_id integer, p_position_id integer, p_username character varying, p_password_hash character varying, p_first_name character varying, p_last_name character varying, p_gender smallint, p_birth_date date, p_email character varying, p_phone character varying, p_mobile character varying, p_address text, p_id_card character varying, p_id_card_date date, p_id_card_place character varying, p_is_admin boolean, p_is_represent_unit boolean, p_is_represent_department boolean, p_created_by integer);
DROP FUNCTION IF EXISTS public.fn_staff_change_password(p_id integer, p_new_password_hash character varying);
DROP FUNCTION IF EXISTS public.fn_staff_auto_unit_id();
DROP FUNCTION IF EXISTS public.fn_staff_assign_roles(p_staff_id integer, p_role_ids integer[]);
DROP FUNCTION IF EXISTS public.fn_role_update(p_id integer, p_name character varying, p_description text, p_updated_by integer);
DROP FUNCTION IF EXISTS public.fn_role_get_rights(p_role_id integer);
DROP FUNCTION IF EXISTS public.fn_role_get_list(p_unit_id integer, p_keyword character varying);
DROP FUNCTION IF EXISTS public.fn_role_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS public.fn_role_delete(p_id integer);
DROP FUNCTION IF EXISTS public.fn_role_create(p_unit_id integer, p_name character varying, p_description text, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS public.fn_role_assign_rights(p_role_id integer, p_right_ids integer[]);
DROP FUNCTION IF EXISTS public.fn_right_update(p_id integer, p_parent_id integer, p_name character varying, p_name_of_menu character varying, p_action_link character varying, p_icon character varying, p_sort_order integer, p_show_menu boolean, p_default_page boolean, p_show_in_app boolean, p_description text);
DROP FUNCTION IF EXISTS public.fn_right_get_tree();
DROP FUNCTION IF EXISTS public.fn_right_get_by_staff(p_staff_id integer);
DROP FUNCTION IF EXISTS public.fn_right_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS public.fn_right_delete(p_id integer);
DROP FUNCTION IF EXISTS public.fn_right_create(p_parent_id integer, p_name character varying, p_name_of_menu character varying, p_action_link character varying, p_icon character varying, p_sort_order integer, p_show_menu boolean, p_default_page boolean, p_show_in_app boolean, p_description text);
DROP FUNCTION IF EXISTS public.fn_province_update(p_id integer, p_name character varying, p_code character varying, p_is_active boolean);
DROP FUNCTION IF EXISTS public.fn_province_get_list(p_keyword character varying);
DROP FUNCTION IF EXISTS public.fn_province_delete(p_id integer);
DROP FUNCTION IF EXISTS public.fn_province_create(p_name character varying, p_code character varying);
DROP FUNCTION IF EXISTS public.fn_position_update(p_id integer, p_name character varying, p_code character varying, p_sort_order integer, p_description text, p_is_active boolean, p_is_leader boolean, p_is_handle_document boolean);
DROP FUNCTION IF EXISTS public.fn_position_get_list(p_keyword character varying, p_page integer, p_page_size integer);
DROP FUNCTION IF EXISTS public.fn_position_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS public.fn_position_delete(p_id integer);
DROP FUNCTION IF EXISTS public.fn_position_create(p_name character varying, p_code character varying, p_sort_order integer, p_description text, p_is_leader boolean, p_is_handle_document boolean);
DROP FUNCTION IF EXISTS public.fn_get_department_subtree(p_dept_id integer);
DROP FUNCTION IF EXISTS public.fn_get_ancestor_unit(p_dept_id integer);
DROP FUNCTION IF EXISTS public.fn_district_update(p_id integer, p_name character varying, p_code character varying, p_is_active boolean);
DROP FUNCTION IF EXISTS public.fn_district_get_list(p_province_id integer, p_keyword character varying);
DROP FUNCTION IF EXISTS public.fn_district_delete(p_id integer);
DROP FUNCTION IF EXISTS public.fn_district_create(p_province_id integer, p_name character varying, p_code character varying);
DROP FUNCTION IF EXISTS public.fn_directory_get_list(p_unit_id integer, p_department_id integer, p_search character varying, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS public.fn_department_update(p_id integer, p_parent_id integer, p_code character varying, p_name character varying, p_name_en character varying, p_short_name character varying, p_abb_name character varying, p_is_unit boolean, p_level integer, p_sort_order integer, p_phone character varying, p_fax character varying, p_email character varying, p_address text, p_allow_doc_book boolean, p_description text, p_updated_by integer);
DROP FUNCTION IF EXISTS public.fn_department_toggle_lock(p_id integer);
DROP FUNCTION IF EXISTS public.fn_department_get_tree(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS public.fn_department_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS public.fn_department_delete(p_id integer);
DROP FUNCTION IF EXISTS public.fn_department_create(p_parent_id integer, p_code character varying, p_name character varying, p_name_en character varying, p_short_name character varying, p_abb_name character varying, p_is_unit boolean, p_level integer, p_sort_order integer, p_phone character varying, p_fax character varying, p_email character varying, p_address text, p_allow_doc_book boolean, p_description text, p_created_by integer);
DROP FUNCTION IF EXISTS public.fn_config_upsert(p_unit_id integer, p_key character varying, p_value text, p_description text, p_department_id integer);
DROP FUNCTION IF EXISTS public.fn_config_get_list(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS public.fn_commune_update(p_id integer, p_name character varying, p_code character varying, p_is_active boolean);
DROP FUNCTION IF EXISTS public.fn_commune_get_list(p_district_id integer, p_keyword character varying);
DROP FUNCTION IF EXISTS public.fn_commune_delete(p_id integer);
DROP FUNCTION IF EXISTS public.fn_commune_create(p_district_id integer, p_name character varying, p_code character varying);
DROP FUNCTION IF EXISTS public.fn_calendar_event_update(p_id bigint, p_title character varying, p_description text, p_start_time timestamp without time zone, p_end_time timestamp without time zone, p_all_day boolean, p_color character varying, p_repeat_type character varying, p_scope character varying, p_unit_id integer, p_staff_id integer, p_department_id integer);
DROP FUNCTION IF EXISTS public.fn_calendar_event_get_list(p_scope character varying, p_unit_id integer, p_staff_id integer, p_start timestamp without time zone, p_end timestamp without time zone, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS public.fn_calendar_event_get_by_id(p_id bigint);
DROP FUNCTION IF EXISTS public.fn_calendar_event_delete(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS public.fn_calendar_event_create(p_title character varying, p_description text, p_start_time timestamp without time zone, p_end_time timestamp without time zone, p_all_day boolean, p_color character varying, p_repeat_type character varying, p_scope character varying, p_unit_id integer, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS public.fn_auth_verify_refresh_token(p_token_hash character varying);
DROP FUNCTION IF EXISTS public.fn_auth_save_refresh_token(p_staff_id integer, p_token_hash character varying, p_expires_at timestamp with time zone);
DROP FUNCTION IF EXISTS public.fn_auth_logout_all(p_staff_id integer);
DROP FUNCTION IF EXISTS public.fn_auth_logout(p_token_hash character varying);
DROP FUNCTION IF EXISTS public.fn_auth_login(p_username character varying, p_ip_address character varying, p_user_agent text);
DROP FUNCTION IF EXISTS public.fn_auth_log_login(p_staff_id integer, p_username character varying, p_ip_address character varying, p_user_agent text, p_success boolean);
DROP FUNCTION IF EXISTS public.fn_auth_get_me(p_staff_id integer);
DROP FUNCTION IF EXISTS public.fn_auth_cleanup_expired_tokens();
DROP FUNCTION IF EXISTS iso.fn_document_update(p_id bigint, p_category_id integer, p_title character varying, p_description text, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_mime_type character varying, p_keyword character varying, p_status integer, p_modified_user_id integer);
DROP FUNCTION IF EXISTS iso.fn_document_get_list(p_unit_id integer, p_category_id integer, p_keyword text, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS iso.fn_document_get_by_id(p_id bigint);
DROP FUNCTION IF EXISTS iso.fn_document_delete(p_id bigint);
DROP FUNCTION IF EXISTS iso.fn_document_create(p_unit_id integer, p_category_id integer, p_title character varying, p_description text, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_mime_type character varying, p_keyword character varying, p_status integer, p_created_user_id integer, p_department_id integer);
DROP FUNCTION IF EXISTS iso.fn_doc_category_update(p_id integer, p_parent_id integer, p_code character varying, p_name character varying, p_date_process numeric, p_status integer, p_description text, p_version numeric, p_modified_user_id integer);
DROP FUNCTION IF EXISTS iso.fn_doc_category_get_tree(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS iso.fn_doc_category_delete(p_id integer);
DROP FUNCTION IF EXISTS iso.fn_doc_category_create(p_parent_id integer, p_code character varying, p_name character varying, p_date_process numeric, p_description text, p_version numeric, p_unit_id integer, p_created_user_id integer);
DROP FUNCTION IF EXISTS esto.fn_warehouse_update(p_id integer, p_type_id integer, p_code character varying, p_name character varying, p_phone_number character varying, p_address character varying, p_status boolean, p_description text, p_parent_id integer, p_is_unit boolean, p_warehouse_level integer, p_limit_child integer, p_position character varying, p_modified_user_id integer);
DROP FUNCTION IF EXISTS esto.fn_warehouse_get_tree(p_unit_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS esto.fn_warehouse_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS esto.fn_warehouse_delete(p_id integer);
DROP FUNCTION IF EXISTS esto.fn_warehouse_create(p_unit_id integer, p_type_id integer, p_code character varying, p_name character varying, p_phone_number character varying, p_address character varying, p_status boolean, p_description text, p_parent_id integer, p_is_unit boolean, p_warehouse_level integer, p_limit_child integer, p_position character varying, p_created_user_id integer, p_department_id integer);
DROP FUNCTION IF EXISTS esto.fn_record_update(p_id bigint, p_fond_id integer, p_warehouse_id integer, p_file_code character varying, p_file_catalog integer, p_file_notation character varying, p_title character varying, p_maintenance character varying, p_rights character varying, p_language character varying, p_start_date date, p_complete_date date, p_total_doc integer, p_description text, p_infor_sign character varying, p_keyword character varying, p_total_paper numeric, p_page_number numeric, p_format integer, p_archive_date date, p_in_charge_staff_id integer, p_reception_date date, p_reception_from integer, p_transfer_staff character varying, p_is_document_original boolean, p_number_of_copy integer, p_doc_field_id integer, p_modified_user_id integer);
DROP FUNCTION IF EXISTS esto.fn_record_get_list(p_unit_id integer, p_fond_id integer, p_warehouse_id integer, p_keyword text, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS esto.fn_record_get_by_id(p_id bigint);
DROP FUNCTION IF EXISTS esto.fn_record_delete(p_id bigint);
DROP FUNCTION IF EXISTS esto.fn_record_create(p_unit_id integer, p_fond_id integer, p_warehouse_id integer, p_file_code character varying, p_file_catalog integer, p_file_notation character varying, p_title character varying, p_maintenance character varying, p_rights character varying, p_language character varying, p_start_date date, p_complete_date date, p_total_doc integer, p_description text, p_infor_sign character varying, p_keyword character varying, p_total_paper numeric, p_page_number numeric, p_format integer, p_archive_date date, p_in_charge_staff_id integer, p_reception_date date, p_reception_from integer, p_transfer_staff character varying, p_is_document_original boolean, p_number_of_copy integer, p_doc_field_id integer, p_created_user_id integer, p_department_id integer);
DROP FUNCTION IF EXISTS esto.fn_get_warehouses_list(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS esto.fn_get_fonds_list(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS esto.fn_fond_update(p_id integer, p_parent_id integer, p_fond_code character varying, p_fond_name character varying, p_fond_history text, p_archives_time character varying, p_paper_total numeric, p_paper_digital numeric, p_keys_group character varying, p_other_type character varying, p_language character varying, p_lookup_tools character varying, p_coppy_number numeric, p_status integer, p_description text, p_version numeric, p_modified_user_id integer);
DROP FUNCTION IF EXISTS esto.fn_fond_get_tree(p_unit_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS esto.fn_fond_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS esto.fn_fond_delete(p_id integer);
DROP FUNCTION IF EXISTS esto.fn_fond_create(p_unit_id integer, p_parent_id integer, p_fond_code character varying, p_fond_name character varying, p_fond_history text, p_archives_time character varying, p_paper_total numeric, p_paper_digital numeric, p_keys_group character varying, p_other_type character varying, p_language character varying, p_lookup_tools character varying, p_coppy_number numeric, p_status integer, p_description text, p_version numeric, p_created_user_id integer, p_department_id integer);
DROP FUNCTION IF EXISTS esto.fn_document_archive_get_by_doc(p_doc_type character varying, p_doc_id bigint);
DROP FUNCTION IF EXISTS esto.fn_document_archive_create(p_doc_type character varying, p_doc_id bigint, p_fond_id integer, p_warehouse_id integer, p_record_id bigint, p_file_catalog character varying, p_file_notation character varying, p_doc_ordinal integer, p_language character varying, p_autograph text, p_keyword text, p_format character varying, p_confidence_level character varying, p_is_original boolean, p_archived_by integer);
DROP FUNCTION IF EXISTS esto.fn_borrow_request_return(p_id bigint, p_modified_user_id integer);
DROP FUNCTION IF EXISTS esto.fn_borrow_request_reject(p_id bigint, p_modified_user_id integer, p_notice text);
DROP FUNCTION IF EXISTS esto.fn_borrow_request_get_list(p_unit_id integer, p_status integer, p_keyword text, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS esto.fn_borrow_request_get_by_id(p_id bigint);
DROP FUNCTION IF EXISTS esto.fn_borrow_request_create(p_name character varying, p_unit_id integer, p_emergency integer, p_notice text, p_borrow_date date, p_created_user_id integer, p_record_ids integer[], p_department_id integer);
DROP FUNCTION IF EXISTS esto.fn_borrow_request_checkout(p_id bigint, p_modified_user_id integer);
DROP FUNCTION IF EXISTS esto.fn_borrow_request_approve(p_id bigint, p_modified_user_id integer);
DROP FUNCTION IF EXISTS edoc.fn_work_group_update(p_id integer, p_name character varying, p_function text, p_sort_order integer);
DROP FUNCTION IF EXISTS edoc.fn_work_group_get_members(p_group_id integer);
DROP FUNCTION IF EXISTS edoc.fn_work_group_get_list(p_unit_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_work_group_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_work_group_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_work_group_create(p_unit_id integer, p_name character varying, p_function text, p_sort_order integer, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_work_group_assign_members(p_group_id integer, p_staff_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_vote_question_stop(p_question_id uuid);
DROP FUNCTION IF EXISTS edoc.fn_vote_question_start(p_question_id uuid);
DROP FUNCTION IF EXISTS edoc.fn_vote_question_get_list(p_room_schedule_id integer);
DROP FUNCTION IF EXISTS edoc.fn_vote_question_create(p_room_schedule_id integer, p_name character varying, p_question_type integer, p_duration integer, p_order_no integer);
DROP FUNCTION IF EXISTS edoc.fn_vote_get_results(p_question_id uuid);
DROP FUNCTION IF EXISTS edoc.fn_vote_cast(p_question_id uuid, p_answer_id uuid, p_staff_id integer, p_other_text text);
DROP FUNCTION IF EXISTS edoc.fn_vote_answer_create(p_question_id uuid, p_room_schedule_id integer, p_name character varying, p_order_no integer, p_is_other boolean);
DROP FUNCTION IF EXISTS edoc.fn_staff_note_update_important(p_doc_type character varying, p_doc_id bigint, p_staff_id integer, p_is_important boolean);
DROP FUNCTION IF EXISTS edoc.fn_staff_note_toggle(p_doc_type character varying, p_doc_id bigint, p_staff_id integer, p_note text, p_is_important boolean);
DROP FUNCTION IF EXISTS edoc.fn_staff_note_get_list(p_staff_id integer, p_doc_type character varying);
DROP FUNCTION IF EXISTS edoc.fn_sms_template_update(p_id integer, p_name character varying, p_content text, p_description text, p_is_active boolean);
DROP FUNCTION IF EXISTS edoc.fn_sms_template_get_list(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_sms_template_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_sms_template_create(p_unit_id integer, p_name character varying, p_content text, p_description text, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_signer_get_list(p_unit_id integer, p_department_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_signer_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_signer_create(p_unit_id integer, p_department_id integer, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_send_config_save(p_user_id integer, p_config_type character varying, p_target_user_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_send_config_get_by_user(p_user_id integer, p_config_type character varying);
DROP FUNCTION IF EXISTS edoc.fn_room_update(p_id integer, p_name character varying, p_code character varying, p_location character varying, p_note text, p_sort_order integer, p_show_in_calendar boolean, p_modified_user_id integer);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_update(p_id integer, p_room_id integer, p_meeting_type_id integer, p_name character varying, p_content text, p_component character varying, p_start_date date, p_end_date date, p_start_time character varying, p_end_time character varying, p_master_id integer, p_secretary_id integer, p_online_link character varying, p_modified_user_id integer);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_stats(p_unit_id integer, p_year integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_remove_staff(p_room_schedule_id integer, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_reject(p_id integer, p_approved_staff_id integer, p_reason text);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_get_staff(p_room_schedule_id integer);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_get_list(p_unit_id integer, p_room_id integer, p_status integer, p_from_date date, p_to_date date, p_keyword text, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_create(p_unit_id integer, p_room_id integer, p_meeting_type_id integer, p_name character varying, p_content text, p_component character varying, p_start_date date, p_end_date date, p_start_time character varying, p_end_time character varying, p_master_id integer, p_secretary_id integer, p_online_link character varying, p_created_user_id integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_assign_staff(p_room_schedule_id integer, p_staff_ids integer[], p_user_type integer);
DROP FUNCTION IF EXISTS edoc.fn_room_schedule_approve(p_id integer, p_approved_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_room_get_list(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_room_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_room_create(p_unit_id integer, p_name character varying, p_code character varying, p_location character varying, p_note text, p_sort_order integer, p_show_in_calendar boolean, p_created_user_id integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_report_handling_by_unit(p_unit_id integer, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_report_handling_by_resolver(p_unit_id integer, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_report_handling_by_assigner(p_unit_id integer, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_update(p_id bigint, p_received_date timestamp with time zone, p_number integer, p_sub_number character varying, p_notation character varying, p_document_code character varying, p_abstract text, p_drafting_unit_id integer, p_drafting_user_id integer, p_publish_unit_id integer, p_publish_date timestamp with time zone, p_signer character varying, p_sign_date timestamp with time zone, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_secret_id smallint, p_urgent_id smallint, p_number_paper integer, p_number_copies integer, p_expired_date timestamp with time zone, p_recipients text, p_updated_by integer);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_unapprove(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_send(p_doc_id bigint, p_staff_ids integer[], p_sent_by integer, p_expired_date timestamp with time zone);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_retract(p_id bigint, p_staff_id integer, p_staff_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_reject(p_id bigint, p_staff_id integer, p_reason text);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_mark_read_bulk(p_doc_ids bigint[], p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_get_unused_numbers(p_unit_id integer, p_doc_book_id integer);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_get_recipients(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_get_next_number(p_doc_book_id integer, p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_get_list(p_unit_id integer, p_staff_id integer, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_urgent_id smallint, p_approved boolean, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_keyword text, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_get_history(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_get_by_id(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_delete(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_create(p_unit_id integer, p_received_date timestamp with time zone, p_number integer, p_sub_number character varying, p_notation character varying, p_document_code character varying, p_abstract text, p_drafting_unit_id integer, p_drafting_user_id integer, p_publish_unit_id integer, p_publish_date timestamp with time zone, p_signer character varying, p_sign_date timestamp with time zone, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_secret_id smallint, p_urgent_id smallint, p_number_paper integer, p_number_copies integer, p_expired_date timestamp with time zone, p_recipients text, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_count_unread(p_unit_id integer, p_staff_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_check_number(p_unit_id integer, p_doc_book_id integer, p_number integer, p_exclude_id bigint, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_outgoing_doc_approve(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_organization_upsert(p_unit_id integer, p_code character varying, p_name character varying, p_address text, p_phone character varying, p_fax character varying, p_email character varying, p_email_doc character varying, p_secretary character varying, p_chairman_number character varying, p_level smallint, p_is_exchange boolean, p_updated_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_organization_get(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_opinion_get_list(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_opinion_create(p_doc_id bigint, p_staff_id integer, p_content text, p_opinion_type text);
DROP FUNCTION IF EXISTS edoc.fn_notification_pref_upsert(p_staff_id integer, p_channel character varying, p_is_enabled boolean);
DROP FUNCTION IF EXISTS edoc.fn_notification_pref_get_by_staff(p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_notification_log_update_status(p_id bigint, p_send_status character varying, p_error_message text);
DROP FUNCTION IF EXISTS edoc.fn_notification_log_get_list(p_staff_id integer, p_channel character varying, p_send_status character varying, p_page integer, p_page_size integer);
DROP FUNCTION IF EXISTS edoc.fn_notification_log_create(p_staff_id integer, p_channel character varying, p_event_type character varying, p_title character varying, p_body text, p_ref_type character varying, p_ref_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_notice_mark_read(p_notice_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_notice_mark_all_read(p_staff_id integer, p_unit_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_notice_get_list(p_unit_id integer, p_staff_id integer, p_is_read text, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_notice_create(p_unit_id integer, p_title character varying, p_content text, p_notice_type character varying, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_notice_count_unread(p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_message_restore(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_message_reply(p_message_id bigint, p_staff_id integer, p_content text);
DROP FUNCTION IF EXISTS edoc.fn_message_permanent_delete(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_message_get_trash(p_staff_id integer, p_page integer, p_page_size integer);
DROP FUNCTION IF EXISTS edoc.fn_message_get_sent(p_staff_id integer, p_keyword text, p_page integer, p_page_size integer);
DROP FUNCTION IF EXISTS edoc.fn_message_get_inbox(p_staff_id integer, p_keyword text, p_page integer, p_page_size integer);
DROP FUNCTION IF EXISTS edoc.fn_message_get_by_id(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_message_delete(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_message_create(p_from_staff_id integer, p_to_staff_ids integer[], p_subject character varying, p_content text, p_parent_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_message_count_unread(p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_meeting_type_update(p_id integer, p_name character varying, p_description text, p_sort_order integer, p_modified_user_id integer);
DROP FUNCTION IF EXISTS edoc.fn_meeting_type_get_list(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_meeting_type_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_meeting_type_create(p_unit_id integer, p_name character varying, p_description text, p_sort_order integer, p_created_user_id integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_lgsp_tracking_update_status(p_id bigint, p_status character varying, p_lgsp_doc_id character varying, p_error_message text);
DROP FUNCTION IF EXISTS edoc.fn_lgsp_tracking_get_list(p_direction character varying, p_status character varying, p_page integer, p_page_size integer);
DROP FUNCTION IF EXISTS edoc.fn_lgsp_tracking_get_by_doc(p_outgoing_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_lgsp_tracking_create(p_outgoing_doc_id bigint, p_incoming_doc_id bigint, p_direction character varying, p_dest_org_code character varying, p_dest_org_name character varying, p_edxml_content text, p_created_by integer);
DROP FUNCTION IF EXISTS edoc.fn_lgsp_org_sync(p_org_code character varying, p_org_name character varying, p_parent_code character varying, p_address character varying, p_email character varying, p_phone character varying);
DROP FUNCTION IF EXISTS edoc.fn_lgsp_org_get_list(p_search text, p_page integer, p_page_size integer);
DROP FUNCTION IF EXISTS edoc.fn_lgsp_mock_send(p_doc_id bigint, p_doc_type character varying, p_dest_org_code character varying, p_dest_org_name character varying, p_sent_by integer);
DROP FUNCTION IF EXISTS edoc.fn_lgsp_mock_receive(p_unit_id integer, p_notation character varying, p_abstract text, p_publish_unit character varying, p_signer character varying, p_doc_type_id integer, p_created_by integer);
DROP FUNCTION IF EXISTS edoc.fn_leader_note_get_list(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_leader_note_get_by_outgoing_doc(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_leader_note_get_by_drafting_doc(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_leader_note_delete(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_leader_note_create_outgoing(p_doc_id bigint, p_staff_id integer, p_content text);
DROP FUNCTION IF EXISTS edoc.fn_leader_note_create_drafting(p_doc_id bigint, p_staff_id integer, p_content text);
DROP FUNCTION IF EXISTS edoc.fn_leader_note_create(p_doc_id bigint, p_staff_id integer, p_content text);
DROP FUNCTION IF EXISTS edoc.fn_leader_note_comment_and_assign(p_doc_id bigint, p_staff_id integer, p_content text, p_expired_date timestamp with time zone, p_staff_ids integer[], p_doc_type character varying);
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_return(p_id bigint, p_staff_id integer, p_reason text);
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_receive(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_get_list(p_unit_id integer, p_keyword text, p_status text, p_from_date date, p_to_date date, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_get_by_id(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_create(p_unit_id integer, p_notation character varying, p_document_code character varying, p_abstract text, p_publish_unit character varying, p_publish_date date, p_signer character varying, p_sign_date date, p_expired_date date, p_doc_type_id integer, p_source_system character varying, p_external_doc_id character varying, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_inter_incoming_complete(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_update(p_id bigint, p_received_date timestamp with time zone, p_number integer, p_notation character varying, p_document_code character varying, p_abstract text, p_publish_unit character varying, p_publish_date timestamp with time zone, p_signer character varying, p_sign_date timestamp with time zone, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_secret_id smallint, p_urgent_id smallint, p_number_paper integer, p_number_copies integer, p_expired_date timestamp with time zone, p_recipients text, p_sents text, p_is_received_paper boolean, p_updated_by integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_unapprove(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_send(p_doc_id bigint, p_staff_ids integer[], p_sent_by integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_return(p_doc_id bigint, p_returned_by integer, p_reason text);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_retract(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_receive_paper(p_id bigint, p_staff_id integer, p_received_paper_date timestamp with time zone);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_mark_read_bulk(p_doc_ids bigint[], p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_mark_read(p_doc_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_handover(p_doc_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_sendable_staff(p_unit_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_recipients(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_next_number(p_doc_book_id integer, p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_list(p_unit_id integer, p_staff_id integer, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_urgent_id smallint, p_is_read boolean, p_approved boolean, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_keyword text, p_signer text, p_from_number integer, p_to_number integer, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_history(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_get_by_id(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_delete(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_create(p_unit_id integer, p_received_date timestamp with time zone, p_number integer, p_notation character varying, p_document_code character varying, p_abstract text, p_publish_unit character varying, p_publish_date timestamp with time zone, p_signer character varying, p_sign_date timestamp with time zone, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_secret_id smallint, p_urgent_id smallint, p_number_paper integer, p_number_copies integer, p_expired_date timestamp with time zone, p_recipients text, p_is_received_paper boolean, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_count_unread(p_unit_id integer, p_staff_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_cancel_approve(p_doc_id bigint, p_cancelled_by integer);
DROP FUNCTION IF EXISTS edoc.fn_incoming_doc_approve(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_update_progress(p_id bigint, p_progress smallint);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_update(p_id bigint, p_doc_type_id integer, p_doc_field_id integer, p_name character varying, p_comments text, p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_curator_id integer, p_signer_id integer, p_workflow_id integer, p_updated_by integer);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_unlink_doc(p_link_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_submit(p_id bigint, p_submitted_by integer);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_return(p_id bigint, p_returned_by integer, p_reason text);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_remove_staff(p_doc_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_reject(p_id bigint, p_rejected_by integer, p_reason text);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_link_doc(p_handling_doc_id bigint, p_doc_id bigint, p_doc_type character varying, p_linked_by integer);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_kpi(p_unit_id integer, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_staff(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_list(p_unit_id integer, p_dept_ids integer[], p_staff_id integer, p_status integer, p_filter_type text, p_keyword text, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_page integer, p_page_size integer);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_linked_docs(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_for_link(p_unit_id integer, p_keyword text, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_children(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_by_id(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_attachments(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_delete(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_create_from_doc(p_doc_id bigint, p_doc_type character varying, p_name text, p_start_date date, p_end_date date, p_curator_ids integer[], p_note text, p_created_by integer);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_create(p_unit_id integer, p_department_id integer, p_doc_type_id integer, p_doc_field_id integer, p_name character varying, p_comments text, p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_curator_id integer, p_signer_id integer, p_workflow_id integer, p_is_from_doc boolean, p_parent_id bigint, p_created_by integer);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_count_by_status(p_unit_id integer, p_staff_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_complete(p_id bigint, p_completed_by integer);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_change_status(p_id bigint, p_new_status smallint, p_changed_by integer, p_reason text);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_assign_staff(p_doc_id bigint, p_staff_ids integer[], p_role_type smallint, p_deadline timestamp with time zone, p_assigned_by integer);
DROP FUNCTION IF EXISTS edoc.fn_handling_doc_approve(p_id bigint, p_approved_by integer);
DROP FUNCTION IF EXISTS edoc.fn_email_template_update(p_id integer, p_name character varying, p_subject character varying, p_content text, p_description text, p_is_active boolean);
DROP FUNCTION IF EXISTS edoc.fn_email_template_get_list(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_email_template_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_email_template_create(p_unit_id integer, p_name character varying, p_subject character varying, p_content text, p_description text, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_update(p_id bigint, p_received_date timestamp with time zone, p_number integer, p_sub_number character varying, p_notation character varying, p_document_code character varying, p_abstract text, p_drafting_unit_id integer, p_drafting_user_id integer, p_publish_unit_id integer, p_publish_date timestamp with time zone, p_signer character varying, p_sign_date timestamp with time zone, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_secret_id smallint, p_urgent_id smallint, p_number_paper integer, p_number_copies integer, p_expired_date timestamp with time zone, p_recipients text, p_updated_by integer);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_unapprove(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_send(p_doc_id bigint, p_staff_ids integer[], p_sent_by integer, p_expired_date timestamp with time zone);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_retract(p_id bigint, p_staff_id integer, p_staff_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_release(p_id bigint, p_released_by integer);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_reject(p_id bigint, p_staff_id integer, p_reason text);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_mark_read_bulk(p_doc_ids bigint[], p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_get_recipients(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_get_next_number(p_doc_book_id integer, p_unit_id integer);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_get_list(p_unit_id integer, p_staff_id integer, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_urgent_id smallint, p_is_released boolean, p_approved boolean, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_keyword text, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_get_history(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_get_by_id(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_delete(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_create(p_unit_id integer, p_received_date timestamp with time zone, p_number integer, p_sub_number character varying, p_notation character varying, p_document_code character varying, p_abstract text, p_drafting_unit_id integer, p_drafting_user_id integer, p_publish_unit_id integer, p_publish_date timestamp with time zone, p_signer character varying, p_sign_date timestamp with time zone, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_secret_id smallint, p_urgent_id smallint, p_number_paper integer, p_number_copies integer, p_expired_date timestamp with time zone, p_recipients text, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_count_unread(p_unit_id integer, p_staff_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_drafting_doc_approve(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_type_update(p_id integer, p_parent_id integer, p_name character varying, p_code character varying, p_notation_type smallint, p_sort_order integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_type_get_tree(p_type_id smallint);
DROP FUNCTION IF EXISTS edoc.fn_doc_type_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_type_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_type_create(p_type_id smallint, p_parent_id integer, p_name character varying, p_code character varying, p_notation_type smallint, p_sort_order integer, p_created_by integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_save_extra_fields(p_doc_type character varying, p_doc_id bigint, p_extra jsonb);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_update(p_id integer, p_name character varying, p_version character varying, p_doc_field_id integer, p_is_active boolean);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_step_update(p_step_id integer, p_step_name character varying, p_step_order integer, p_step_type character varying, p_allow_sign boolean, p_deadline_days integer, p_position_x double precision, p_position_y double precision);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_step_link_delete(p_link_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_step_link_create(p_from_step_id integer, p_to_step_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_step_get_staff(p_step_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_step_get_list(p_flow_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_step_delete(p_step_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_step_create(p_flow_id integer, p_step_name character varying, p_step_order integer, p_step_type character varying, p_allow_sign boolean, p_deadline_days integer, p_position_x double precision, p_position_y double precision);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_step_assign_staff(p_step_id integer, p_staff_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_get_list(p_unit_id integer, p_doc_field_id integer, p_is_active boolean, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_flow_create(p_unit_id integer, p_name character varying, p_version character varying, p_doc_field_id integer, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_field_update(p_id integer, p_code character varying, p_name character varying, p_sort_order integer, p_is_active boolean);
DROP FUNCTION IF EXISTS edoc.fn_doc_field_get_list(p_unit_id integer, p_keyword character varying, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_field_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_field_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_field_create(p_unit_id integer, p_code character varying, p_name character varying, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_column_update(p_id integer, p_label character varying, p_is_mandatory boolean, p_is_show_all boolean, p_sort_order integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_column_toggle_visibility(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_column_save(p_id integer, p_type_id integer, p_column_name character varying, p_label character varying, p_data_type character varying, p_max_length integer, p_sort_order integer, p_is_mandatory boolean, p_description text);
DROP FUNCTION IF EXISTS edoc.fn_doc_column_get_list(p_type_id smallint);
DROP FUNCTION IF EXISTS edoc.fn_doc_column_get_by_type(p_type_id smallint);
DROP FUNCTION IF EXISTS edoc.fn_doc_column_get_all();
DROP FUNCTION IF EXISTS edoc.fn_doc_column_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_book_update(p_id integer, p_name character varying, p_is_default boolean, p_description text, p_sort_order integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_book_set_default(p_id integer, p_type_id smallint, p_unit_id integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_book_get_list(p_type_id smallint, p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_book_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_book_delete(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_doc_book_create(p_type_id smallint, p_unit_id integer, p_name character varying, p_is_default boolean, p_description text, p_created_by integer, p_department_id integer);
DROP FUNCTION IF EXISTS edoc.fn_digital_signature_update_status(p_id bigint, p_sign_status character varying, p_certificate_serial character varying, p_certificate_subject character varying, p_certificate_issuer character varying, p_signed_file_path character varying, p_error_message text);
DROP FUNCTION IF EXISTS edoc.fn_digital_signature_get_by_id(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_digital_signature_get_by_doc(p_doc_id bigint, p_doc_type character varying);
DROP FUNCTION IF EXISTS edoc.fn_digital_signature_create(p_doc_id bigint, p_doc_type character varying, p_staff_id integer, p_sign_method character varying, p_original_file_path character varying);
DROP FUNCTION IF EXISTS edoc.fn_device_token_upsert(p_staff_id integer, p_device_token character varying, p_device_type character varying);
DROP FUNCTION IF EXISTS edoc.fn_device_token_get_by_staff(p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_device_token_delete(p_id bigint, p_staff_id integer);
DROP FUNCTION IF EXISTS edoc.fn_delegation_revoke(p_id integer);
DROP FUNCTION IF EXISTS edoc.fn_delegation_get_list(p_unit_id integer, p_staff_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_delegation_create(p_from_staff_id integer, p_to_staff_id integer, p_start_date date, p_end_date date, p_note text);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_upcoming_tasks(p_staff_id integer, p_limit integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_top_departments(p_dept_ids integer[], p_limit integer);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_task_by_status(p_staff_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_recent_outgoing(p_unit_id integer, p_limit integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_recent_notices(p_staff_id integer, p_dept_ids integer[], p_limit integer);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_recent_incoming(p_unit_id integer, p_limit integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_ontime_rate(p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_get_stats_extra(p_staff_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_get_stats(p_staff_id integer, p_unit_id integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_doc_by_month(p_dept_ids integer[], p_months integer);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_doc_by_department(p_dept_ids integer[]);
DROP FUNCTION IF EXISTS edoc.fn_dashboard_calendar_today(p_staff_id integer, p_dept_ids integer[], p_days integer);
DROP FUNCTION IF EXISTS edoc.fn_attachment_outgoing_get_list(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_attachment_outgoing_delete(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_attachment_outgoing_create(p_doc_id bigint, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_content_type character varying, p_created_by integer);
DROP FUNCTION IF EXISTS edoc.fn_attachment_mock_verify(p_attachment_id bigint, p_attachment_type character varying);
DROP FUNCTION IF EXISTS edoc.fn_attachment_mock_sign(p_attachment_id bigint, p_attachment_type character varying, p_signed_by integer);
DROP FUNCTION IF EXISTS edoc.fn_attachment_inter_incoming_get_list(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_attachment_inter_incoming_delete(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_attachment_inter_incoming_create(p_doc_id bigint, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_content_type character varying, p_description text, p_created_by integer);
DROP FUNCTION IF EXISTS edoc.fn_attachment_incoming_get_list(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_attachment_incoming_delete(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_attachment_incoming_create(p_doc_id bigint, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_content_type character varying, p_created_by integer);
DROP FUNCTION IF EXISTS edoc.fn_attachment_drafting_get_list(p_doc_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_attachment_drafting_delete(p_id bigint);
DROP FUNCTION IF EXISTS edoc.fn_attachment_drafting_create(p_doc_id bigint, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_content_type character varying, p_created_by integer);
DROP FUNCTION IF EXISTS cont.fn_contract_update(p_id integer, p_code_index integer, p_contract_type_id integer, p_department_id integer, p_type_of_contract integer, p_contact_id integer, p_contact_name character varying, p_code character varying, p_sign_date date, p_input_date date, p_receive_date date, p_name character varying, p_signer character varying, p_number integer, p_ballot character varying, p_marker character varying, p_curator_name character varying, p_currency character varying, p_transporter character varying, p_staff_id integer, p_note text, p_status integer, p_amount character varying, p_payment_amount numeric, p_modified_user_id integer);
DROP FUNCTION IF EXISTS cont.fn_contract_type_update(p_id integer, p_parent_id integer, p_code character varying, p_name character varying, p_note text, p_sort_order integer, p_modified_user_id integer);
DROP FUNCTION IF EXISTS cont.fn_contract_type_get_list(p_unit_id integer, p_dept_id integer);
DROP FUNCTION IF EXISTS cont.fn_contract_type_delete(p_id integer);
DROP FUNCTION IF EXISTS cont.fn_contract_type_create(p_unit_id integer, p_parent_id integer, p_code character varying, p_name character varying, p_note text, p_sort_order integer, p_created_user_id integer, p_department_id integer);
DROP FUNCTION IF EXISTS cont.fn_contract_get_list(p_unit_id integer, p_contract_type_id integer, p_status integer, p_keyword text, p_page integer, p_page_size integer, p_dept_ids integer[]);
DROP FUNCTION IF EXISTS cont.fn_contract_get_by_id(p_id integer);
DROP FUNCTION IF EXISTS cont.fn_contract_get_attachments(p_contract_id integer);
DROP FUNCTION IF EXISTS cont.fn_contract_delete(p_id integer);
DROP FUNCTION IF EXISTS cont.fn_contract_create(p_code_index integer, p_contract_type_id integer, p_department_id integer, p_type_of_contract integer, p_contact_id integer, p_contact_name character varying, p_unit_id integer, p_code character varying, p_sign_date date, p_input_date date, p_receive_date date, p_name character varying, p_signer character varying, p_number integer, p_ballot character varying, p_marker character varying, p_curator_name character varying, p_currency character varying, p_transporter character varying, p_staff_id integer, p_note text, p_status integer, p_amount character varying, p_payment_amount numeric, p_created_user_id integer);
DROP EXTENSION IF EXISTS "uuid-ossp";
DROP EXTENSION IF EXISTS unaccent;
DROP EXTENSION IF EXISTS pgcrypto;
DROP EXTENSION IF EXISTS pg_trgm;
DROP SCHEMA IF EXISTS iso;
DROP SCHEMA IF EXISTS esto;
DROP SCHEMA IF EXISTS edoc;
DROP SCHEMA IF EXISTS cont;
--
-- Name: cont; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA cont;


--
-- Name: SCHEMA cont; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA cont IS 'Hợp đồng: hợp đồng, phụ lục, đối tác, loại hợp đồng';


--
-- Name: edoc; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA edoc;


--
-- Name: SCHEMA edoc; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA edoc IS 'Văn bản điện tử: VB đến, VB đi, dự thảo, HSCV, workflow, lịch, họp, tin nhắn';


--
-- Name: esto; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA esto;


--
-- Name: SCHEMA esto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA esto IS 'Kho lưu trữ: phông, hồ sơ, mục lục, kho, kệ, mượn trả';


--
-- Name: iso; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA iso;


--
-- Name: SCHEMA iso; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA iso IS 'Tài liệu: ISO, đào tạo, nội bộ, pháp quy';


--
-- Name: SCHEMA public; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON SCHEMA public IS 'Hệ thống: users, departments, roles, rights, SMS, email, địa bàn';


--
-- Name: pg_trgm; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA public;


--
-- Name: EXTENSION pg_trgm; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pg_trgm IS 'text similarity measurement and index searching based on trigrams';


--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: EXTENSION unaccent; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION unaccent IS 'text search dictionary that removes accents';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: fn_contract_create(integer, integer, integer, integer, integer, character varying, integer, character varying, date, date, date, character varying, character varying, integer, character varying, character varying, character varying, character varying, character varying, integer, text, integer, character varying, numeric, integer); Type: FUNCTION; Schema: cont; Owner: -
--

CREATE FUNCTION cont.fn_contract_create(p_code_index integer, p_contract_type_id integer, p_department_id integer, p_type_of_contract integer, p_contact_id integer, p_contact_name character varying, p_unit_id integer, p_code character varying, p_sign_date date, p_input_date date, p_receive_date date, p_name character varying, p_signer character varying, p_number integer, p_ballot character varying, p_marker character varying, p_curator_name character varying, p_currency character varying, p_transporter character varying, p_staff_id integer, p_note text, p_status integer, p_amount character varying, p_payment_amount numeric, p_created_user_id integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên hợp đồng không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO cont.contracts (
    code_index, contract_type_id, department_id, type_of_contract, contact_id,
    contact_name, unit_id, code, sign_date, input_date, receive_date, name,
    signer, number, ballot, marker, curator_name, currency, transporter,
    staff_id, note, status, amount, payment_amount, created_user_id
  ) VALUES (
    p_code_index, p_contract_type_id, p_department_id, COALESCE(p_type_of_contract, 0),
    p_contact_id, p_contact_name, v_unit_id, p_code, p_sign_date, p_input_date,
    p_receive_date, p_name, p_signer, p_number, p_ballot, p_marker, p_curator_name,
    p_currency, p_transporter, p_staff_id, p_note, COALESCE(p_status, 0),
    p_amount, p_payment_amount, p_created_user_id
  ) RETURNING cont.contracts.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo hợp đồng thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_contract_delete(integer); Type: FUNCTION; Schema: cont; Owner: -
--

CREATE FUNCTION cont.fn_contract_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM cont.contracts WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hợp đồng'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Chỉ có thể xóa hợp đồng ở trạng thái Mới'::TEXT;
    RETURN;
  END IF;

  DELETE FROM cont.contracts WHERE id = p_id;

  RETURN QUERY SELECT true, 'Xóa hợp đồng thành công'::TEXT;
END;
$$;


--
-- Name: fn_contract_get_attachments(integer); Type: FUNCTION; Schema: cont; Owner: -
--

CREATE FUNCTION cont.fn_contract_get_attachments(p_contract_id integer) RETURNS TABLE(id bigint, contract_id integer, file_name character varying, file_path character varying, file_size bigint, mime_type character varying, created_user_id integer, created_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    ca.id, ca.contract_id, ca.file_name, ca.file_path,
    ca.file_size, ca.mime_type, ca.created_user_id, ca.created_date
  FROM cont.contract_attachments ca
  WHERE ca.contract_id = p_contract_id
  ORDER BY ca.created_date DESC;
END;
$$;


--
-- Name: fn_contract_get_by_id(integer); Type: FUNCTION; Schema: cont; Owner: -
--

CREATE FUNCTION cont.fn_contract_get_by_id(p_id integer) RETURNS TABLE(id integer, code_index integer, contract_type_id integer, type_name character varying, department_id integer, type_of_contract integer, contact_id integer, contact_name character varying, unit_id integer, code character varying, sign_date date, input_date date, receive_date date, name character varying, signer character varying, number integer, ballot character varying, marker character varying, curator_name character varying, currency character varying, transporter character varying, staff_id integer, note text, status integer, amount character varying, payment_amount numeric, created_user_id integer, created_date timestamp with time zone, modified_user_id integer, modified_date timestamp with time zone, attachment_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    c.id, c.code_index, c.contract_type_id, ct.name AS type_name,
    c.department_id, c.type_of_contract, c.contact_id, c.contact_name,
    c.unit_id, c.code, c.sign_date, c.input_date, c.receive_date,
    c.name, c.signer, c.number, c.ballot, c.marker, c.curator_name,
    c.currency, c.transporter, c.staff_id, c.note, c.status,
    c.amount, c.payment_amount, c.created_user_id, c.created_date,
    c.modified_user_id, c.modified_date,
    (SELECT COUNT(*) FROM cont.contract_attachments ca WHERE ca.contract_id = c.id) AS attachment_count
  FROM cont.contracts c
  LEFT JOIN cont.contract_types ct ON ct.id = c.contract_type_id
  WHERE c.id = p_id;
END;
$$;


--
-- Name: fn_contract_get_list(integer, integer, integer, text, integer, integer, integer[]); Type: FUNCTION; Schema: cont; Owner: -
--

CREATE FUNCTION cont.fn_contract_get_list(p_unit_id integer, p_contract_type_id integer, p_status integer, p_keyword text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id integer, code_index integer, contract_type_id integer, type_name character varying, unit_id integer, code character varying, name character varying, sign_date date, signer character varying, contact_name character varying, staff_id integer, status integer, amount character varying, payment_amount numeric, created_date timestamp with time zone, attachment_count bigint, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT c.id, c.code_index, c.contract_type_id, ct.name AS type_name,
      c.unit_id, c.code, c.name, c.sign_date, c.signer, c.contact_name,
      c.staff_id, c.status, c.amount, c.payment_amount, c.created_date,
      (SELECT COUNT(*) FROM cont.contract_attachments ca WHERE ca.contract_id = c.id) AS attachment_count
    FROM cont.contracts c
    LEFT JOIN cont.contract_types ct ON ct.id = c.contract_type_id
    WHERE c.unit_id = p_unit_id
      AND (p_dept_ids IS NULL OR c.department_id = ANY(p_dept_ids))
      AND (p_contract_type_id IS NULL OR c.contract_type_id = p_contract_type_id)
      AND (p_status IS NULL OR p_status = -99 OR c.status = p_status)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           c.name ILIKE '%' || p_keyword || '%' OR c.code ILIKE '%' || p_keyword || '%' OR
           c.contact_name ILIKE '%' || p_keyword || '%')
  )
  SELECT flt.*, COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;


--
-- Name: fn_contract_type_create(integer, integer, character varying, character varying, text, integer, integer, integer); Type: FUNCTION; Schema: cont; Owner: -
--

CREATE FUNCTION cont.fn_contract_type_create(p_unit_id integer, p_parent_id integer, p_code character varying, p_name character varying, p_note text, p_sort_order integer, p_created_user_id integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại hợp đồng không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO cont.contract_types (unit_id, parent_id, code, name, note, sort_order, created_user_id)
  VALUES (v_unit_id, COALESCE(p_parent_id, 0), NULLIF(TRIM(p_code),''), p_name, p_note, COALESCE(p_sort_order, 0), p_created_user_id)
  RETURNING cont.contract_types.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo loại hợp đồng thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã loại hợp đồng đã tồn tại'::TEXT, NULL::INT;
END;
$$;


--
-- Name: fn_contract_type_delete(integer); Type: FUNCTION; Schema: cont; Owner: -
--

CREATE FUNCTION cont.fn_contract_type_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM cont.contracts WHERE contract_type_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Loại hợp đồng đang được sử dụng, không thể xóa'::TEXT;
    RETURN;
  END IF;

  DELETE FROM cont.contract_types WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy loại hợp đồng'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa loại hợp đồng thành công'::TEXT;
END;
$$;


--
-- Name: fn_contract_type_get_list(integer, integer); Type: FUNCTION; Schema: cont; Owner: -
--

CREATE FUNCTION cont.fn_contract_type_get_list(p_unit_id integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, unit_id integer, parent_id integer, code character varying, name character varying, note text, sort_order integer, created_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT ct.id, ct.unit_id, ct.parent_id, ct.code, ct.name, ct.note,
    ct.sort_order, ct.created_date
  FROM cont.contract_types ct
  WHERE (ct.unit_id IS NULL OR ct.unit_id = v_unit_id)
  ORDER BY ct.sort_order, ct.name;
END;
$$;


--
-- Name: fn_contract_type_update(integer, integer, character varying, character varying, text, integer, integer); Type: FUNCTION; Schema: cont; Owner: -
--

CREATE FUNCTION cont.fn_contract_type_update(p_id integer, p_parent_id integer, p_code character varying, p_name character varying, p_note text, p_sort_order integer, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại hợp đồng không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE cont.contract_types SET
    parent_id        = COALESCE(p_parent_id, 0),
    code             = NULLIF(TRIM(p_code),''),
    name             = p_name,
    note             = p_note,
    sort_order       = COALESCE(p_sort_order, 0),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy loại hợp đồng'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã loại hợp đồng đã tồn tại'::TEXT;
END;
$$;


--
-- Name: fn_contract_update(integer, integer, integer, integer, integer, integer, character varying, character varying, date, date, date, character varying, character varying, integer, character varying, character varying, character varying, character varying, character varying, integer, text, integer, character varying, numeric, integer); Type: FUNCTION; Schema: cont; Owner: -
--

CREATE FUNCTION cont.fn_contract_update(p_id integer, p_code_index integer, p_contract_type_id integer, p_department_id integer, p_type_of_contract integer, p_contact_id integer, p_contact_name character varying, p_code character varying, p_sign_date date, p_input_date date, p_receive_date date, p_name character varying, p_signer character varying, p_number integer, p_ballot character varying, p_marker character varying, p_curator_name character varying, p_currency character varying, p_transporter character varying, p_staff_id integer, p_note text, p_status integer, p_amount character varying, p_payment_amount numeric, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên hợp đồng không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE cont.contracts SET
    code_index        = p_code_index,
    contract_type_id  = p_contract_type_id,
    department_id     = p_department_id,
    type_of_contract  = COALESCE(p_type_of_contract, 0),
    contact_id        = p_contact_id,
    contact_name      = p_contact_name,
    code              = p_code,
    sign_date         = p_sign_date,
    input_date        = p_input_date,
    receive_date      = p_receive_date,
    name              = p_name,
    signer            = p_signer,
    number            = p_number,
    ballot            = p_ballot,
    marker            = p_marker,
    curator_name      = p_curator_name,
    currency          = p_currency,
    transporter       = p_transporter,
    staff_id          = p_staff_id,
    note              = p_note,
    status            = COALESCE(p_status, status),
    amount            = p_amount,
    payment_amount    = p_payment_amount,
    modified_user_id  = p_modified_user_id,
    modified_date     = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hợp đồng'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;


--
-- Name: fn_attachment_drafting_create(bigint, character varying, character varying, bigint, character varying, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_drafting_create(p_doc_id bigint, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_content_type character varying, p_created_by integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_file_name IS NULL OR TRIM(p_file_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên file không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.attachment_drafting_docs (drafting_doc_id, file_name, file_path, file_size, content_type, created_by)
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, p_created_by)
  RETURNING edoc.attachment_drafting_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_attachment_drafting_delete(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_drafting_delete(p_id bigint) RETURNS TABLE(success boolean, message text, file_path character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_drafting_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_drafting_docs WHERE edoc.attachment_drafting_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;


--
-- Name: fn_attachment_drafting_get_list(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_drafting_get_list(p_doc_id bigint) RETURNS TABLE(id bigint, file_name character varying, file_path character varying, file_size bigint, content_type character varying, sort_order integer, created_by integer, created_at timestamp with time zone, created_by_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
         a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_drafting_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.drafting_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;


--
-- Name: fn_attachment_incoming_create(bigint, character varying, character varying, bigint, character varying, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_incoming_create(p_doc_id bigint, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_content_type character varying, p_created_by integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_file_name IS NULL OR TRIM(p_file_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên file không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.attachment_incoming_docs (incoming_doc_id, file_name, file_path, file_size, content_type, created_by)
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, p_created_by)
  RETURNING edoc.attachment_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_attachment_incoming_delete(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_incoming_delete(p_id bigint) RETURNS TABLE(success boolean, message text, file_path character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_incoming_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_incoming_docs WHERE edoc.attachment_incoming_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;


--
-- Name: fn_attachment_incoming_get_list(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_incoming_get_list(p_doc_id bigint) RETURNS TABLE(id bigint, file_name character varying, file_path character varying, file_size bigint, content_type character varying, sort_order integer, created_by integer, created_at timestamp with time zone, created_by_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
         a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_incoming_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.incoming_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;


--
-- Name: fn_attachment_inter_incoming_create(bigint, character varying, character varying, bigint, character varying, text, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_inter_incoming_create(p_doc_id bigint, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_content_type character varying, p_description text DEFAULT NULL::text, p_created_by integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_file_name IS NULL OR TRIM(p_file_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên file không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.attachment_inter_incoming_docs (
    inter_incoming_doc_id, file_name, file_path, file_size, content_type, description, created_by
  )
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, NULLIF(TRIM(p_description), ''), p_created_by)
  RETURNING edoc.attachment_inter_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_attachment_inter_incoming_delete(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_inter_incoming_delete(p_id bigint) RETURNS TABLE(success boolean, message text, file_path character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_inter_incoming_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_inter_incoming_docs WHERE edoc.attachment_inter_incoming_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;


--
-- Name: fn_attachment_inter_incoming_get_list(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_inter_incoming_get_list(p_doc_id bigint) RETURNS TABLE(id bigint, file_name character varying, file_path character varying, file_size bigint, content_type character varying, description text, sort_order integer, created_by integer, created_at timestamp with time zone, created_by_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
         a.description, a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_inter_incoming_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.inter_incoming_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;


--
-- Name: fn_attachment_mock_sign(bigint, character varying, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_mock_sign(p_attachment_id bigint, p_attachment_type character varying, p_signed_by integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF p_attachment_type = 'incoming' THEN
    UPDATE edoc.attachment_incoming_docs SET is_ca = true, ca_date = NOW(), signed_file_path = file_path WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'outgoing' THEN
    UPDATE edoc.attachment_outgoing_docs SET is_ca = true, ca_date = NOW(), signed_file_path = file_path WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'drafting' THEN
    UPDATE edoc.attachment_drafting_docs SET is_ca = true, ca_date = NOW(), signed_file_path = file_path WHERE id = p_attachment_id;
  ELSE
    RETURN QUERY SELECT FALSE, 'Loại không hợp lệ'::TEXT; RETURN;
  END IF;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT; RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, '[MOCK] Ký số thành công'::TEXT;
END;
$$;


--
-- Name: fn_attachment_mock_verify(bigint, character varying); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_mock_verify(p_attachment_id bigint, p_attachment_type character varying) RETURNS TABLE(is_valid boolean, signer_name character varying, sign_date timestamp with time zone, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_ca BOOLEAN; v_date TIMESTAMPTZ;
BEGIN
  IF p_attachment_type = 'incoming' THEN
    SELECT is_ca, ca_date INTO v_ca, v_date FROM edoc.attachment_incoming_docs WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'outgoing' THEN
    SELECT is_ca, ca_date INTO v_ca, v_date FROM edoc.attachment_outgoing_docs WHERE id = p_attachment_id;
  ELSIF p_attachment_type = 'drafting' THEN
    SELECT is_ca, ca_date INTO v_ca, v_date FROM edoc.attachment_drafting_docs WHERE id = p_attachment_id;
  END IF;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, ''::VARCHAR, NULL::TIMESTAMPTZ, 'Không tìm thấy file'::TEXT; RETURN;
  END IF;

  IF COALESCE(v_ca, false) THEN
    RETURN QUERY SELECT TRUE, '[MOCK] Người ký hợp lệ'::VARCHAR, v_date, 'Chữ ký số hợp lệ (MOCK)'::TEXT;
  ELSE
    RETURN QUERY SELECT FALSE, ''::VARCHAR, NULL::TIMESTAMPTZ, 'File chưa được ký số'::TEXT;
  END IF;
END;
$$;


--
-- Name: fn_attachment_outgoing_create(bigint, character varying, character varying, bigint, character varying, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_outgoing_create(p_doc_id bigint, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_content_type character varying, p_created_by integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_file_name IS NULL OR TRIM(p_file_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên file không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.attachment_outgoing_docs (outgoing_doc_id, file_name, file_path, file_size, content_type, created_by)
  VALUES (p_doc_id, p_file_name, p_file_path, COALESCE(p_file_size, 0), p_content_type, p_created_by)
  RETURNING edoc.attachment_outgoing_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tải lên thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_attachment_outgoing_delete(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_outgoing_delete(p_id bigint) RETURNS TABLE(success boolean, message text, file_path character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE v_path VARCHAR;
BEGIN
  SELECT a.file_path INTO v_path FROM edoc.attachment_outgoing_docs a WHERE a.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy file đính kèm'::TEXT, ''::VARCHAR;
    RETURN;
  END IF;

  DELETE FROM edoc.attachment_outgoing_docs WHERE edoc.attachment_outgoing_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa file thành công'::TEXT, v_path;
END;
$$;


--
-- Name: fn_attachment_outgoing_get_list(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_attachment_outgoing_get_list(p_doc_id bigint) RETURNS TABLE(id bigint, file_name character varying, file_path character varying, file_size bigint, content_type character varying, sort_order integer, created_by integer, created_at timestamp with time zone, created_by_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
         a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_outgoing_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.outgoing_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;


--
-- Name: fn_dashboard_calendar_today(integer, integer[], integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_calendar_today(p_staff_id integer, p_dept_ids integer[] DEFAULT NULL::integer[], p_days integer DEFAULT 7) RETURNS TABLE(id bigint, title character varying, start_time timestamp without time zone, end_time timestamp without time zone, all_day boolean, color character varying, scope character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    ce.id,
    ce.title,
    ce.start_time,
    ce.end_time,
    ce.all_day,
    ce.color,
    ce.scope
  FROM public.calendar_events ce
  WHERE ce.is_deleted = FALSE
    AND ce.start_time < (CURRENT_DATE + p_days * interval '1 day')
    AND ce.end_time >= CURRENT_DATE
    AND (
      (ce.scope = 'personal' AND ce.created_by = p_staff_id)
      OR (ce.scope IN ('unit', 'leader') AND (
        p_dept_ids IS NULL
        OR ce.unit_id = ANY(p_dept_ids)
      ))
    )
  ORDER BY ce.start_time ASC
  LIMIT 10;
END;
$$;


--
-- Name: fn_dashboard_doc_by_department(integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_doc_by_department(p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(department_id integer, department_name character varying, incoming_count bigint, outgoing_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  WITH depts AS (
    SELECT d.id, d.name
    FROM public.departments d
    WHERE d.is_deleted = FALSE
      AND d.is_unit = FALSE
      AND (p_dept_ids IS NULL OR d.id = ANY(p_dept_ids))
  ),
  inc AS (
    SELECT ind.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.incoming_docs ind
    WHERE ind.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    GROUP BY ind.department_id
  ),
  outg AS (
    SELECT od.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.outgoing_docs od
    WHERE od.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    GROUP BY od.department_id
  )
  SELECT
    dp.id AS department_id,
    dp.name AS department_name,
    COALESCE(i.cnt, 0) AS incoming_count,
    COALESCE(o.cnt, 0) AS outgoing_count
  FROM depts dp
  LEFT JOIN inc i ON i.dept_id = dp.id
  LEFT JOIN outg o ON o.dept_id = dp.id
  WHERE COALESCE(i.cnt, 0) + COALESCE(o.cnt, 0) > 0
  ORDER BY (COALESCE(i.cnt, 0) + COALESCE(o.cnt, 0)) DESC
  LIMIT 10;
END;
$$;


--
-- Name: fn_dashboard_doc_by_month(integer[], integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_doc_by_month(p_dept_ids integer[] DEFAULT NULL::integer[], p_months integer DEFAULT 6) RETURNS TABLE(month_label text, incoming_count bigint, outgoing_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  WITH months AS (
    SELECT generate_series(
      date_trunc('month', CURRENT_DATE) - ((p_months - 1) || ' months')::interval,
      date_trunc('month', CURRENT_DATE),
      '1 month'::interval
    )::date AS m
  )
  SELECT
    to_char(mo.m, 'MM/YYYY')::TEXT AS month_label,
    COALESCE((
      SELECT COUNT(*)
      FROM edoc.incoming_docs ind
      WHERE date_trunc('month', COALESCE(ind.received_date, ind.created_at)) = mo.m
        AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    ), 0) AS incoming_count,
    COALESCE((
      SELECT COUNT(*)
      FROM edoc.outgoing_docs od
      WHERE date_trunc('month', COALESCE(od.publish_date, od.created_at)) = mo.m
        AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    ), 0) AS outgoing_count
  FROM months mo
  ORDER BY mo.m;
END;
$$;


--
-- Name: fn_dashboard_get_stats(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_get_stats(p_staff_id integer, p_unit_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(incoming_unread bigint, outgoing_pending bigint, handling_total bigint, handling_overdue bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY SELECT
    (SELECT COUNT(*) FROM edoc.user_incoming_docs uid
     INNER JOIN edoc.incoming_docs ind ON ind.id = uid.incoming_doc_id
     WHERE uid.staff_id = p_staff_id AND uid.is_read = FALSE
       AND (p_dept_ids IS NULL OR ind.department_id = ANY(p_dept_ids))
    ),
    (SELECT COUNT(*) FROM edoc.outgoing_docs
     WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND approved = FALSE
    ),
    (SELECT COUNT(*) FROM edoc.handling_docs
     WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    ),
    (SELECT COUNT(*) FROM edoc.handling_docs
     WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
       AND end_date IS NOT NULL AND end_date < NOW() AND status != 4
    );
END; $$;


--
-- Name: fn_dashboard_get_stats_extra(integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_get_stats_extra(p_staff_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(drafting_pending bigint, message_unread bigint, notice_unread bigint, today_meetings bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    -- VB dự thảo chờ phát hành (approved nhưng chưa released)
    (
      SELECT COUNT(*)
      FROM edoc.drafting_docs dd
      WHERE dd.approved = TRUE
        AND dd.is_released = FALSE
        AND (p_dept_ids IS NULL OR dd.unit_id = ANY(p_dept_ids))
    ) AS drafting_pending,

    -- Tin nhắn chưa đọc
    (
      SELECT COUNT(*)
      FROM edoc.message_recipients mr
      WHERE mr.staff_id = p_staff_id
        AND mr.is_read = FALSE
        AND mr.is_deleted = FALSE
    ) AS message_unread,

    -- Thông báo chưa đọc
    (
      SELECT COUNT(*)
      FROM edoc.notices n
      WHERE NOT EXISTS (
        SELECT 1 FROM edoc.notice_reads nr
        WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
      )
      AND (
        n.unit_id IS NULL
        OR n.unit_id = ANY(COALESCE(p_dept_ids, ARRAY[]::INT[]))
      )
    ) AS notice_unread,

    -- Lịch họp hôm nay
    (
      SELECT COUNT(*)
      FROM edoc.room_schedules rs
      WHERE rs.start_date = CURRENT_DATE
        AND (p_dept_ids IS NULL OR rs.unit_id = ANY(p_dept_ids))
    ) AS today_meetings;
END;
$$;


--
-- Name: fn_dashboard_ontime_rate(integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_ontime_rate(p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(total_completed bigint, ontime_count bigint, overdue_count bigint, ontime_percent numeric)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  WITH completed AS (
    SELECT
      hd.id,
      CASE
        WHEN hd.complete_date IS NOT NULL AND hd.end_date IS NOT NULL
             AND hd.complete_date <= hd.end_date THEN TRUE
        ELSE FALSE
      END AS is_ontime
    FROM edoc.handling_docs hd
    WHERE hd.status = 4  -- Hoàn thành
      AND (p_dept_ids IS NULL OR hd.unit_id = ANY(p_dept_ids))
  )
  SELECT
    COUNT(*)::BIGINT AS total_completed,
    COUNT(*) FILTER (WHERE c.is_ontime = TRUE)::BIGINT AS ontime_count,
    COUNT(*) FILTER (WHERE c.is_ontime = FALSE)::BIGINT AS overdue_count,
    CASE
      WHEN COUNT(*) = 0 THEN 0
      ELSE ROUND(COUNT(*) FILTER (WHERE c.is_ontime = TRUE)::NUMERIC / COUNT(*)::NUMERIC * 100, 1)
    END AS ontime_percent
  FROM completed c;
END;
$$;


--
-- Name: fn_dashboard_recent_incoming(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_recent_incoming(p_unit_id integer, p_limit integer DEFAULT 10, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, doc_code character varying, abstract text, received_date timestamp with time zone, urgency_name character varying, sender_name character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY SELECT d.id,
    COALESCE(NULLIF(d.notation, ''), d.document_code, '')::VARCHAR,
    d.abstract, d.received_date,
    CASE d.urgent_id WHEN 1 THEN 'Thường' WHEN 2 THEN 'Khẩn' WHEN 3 THEN 'Hỏa tốc' ELSE 'Thường' END::VARCHAR,
    COALESCE(d.publish_unit, '')::VARCHAR
  FROM edoc.incoming_docs d
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
  ORDER BY d.received_date DESC NULLS LAST, d.created_at DESC
  LIMIT COALESCE(p_limit, 10);
END; $$;


--
-- Name: fn_dashboard_recent_notices(integer, integer[], integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_recent_notices(p_staff_id integer, p_dept_ids integer[] DEFAULT NULL::integer[], p_limit integer DEFAULT 5) RETURNS TABLE(id bigint, title character varying, notice_type character varying, created_at timestamp without time zone, is_read boolean)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    n.id,
    n.title,
    n.notice_type,
    n.created_at,
    EXISTS (
      SELECT 1 FROM edoc.notice_reads nr
      WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
    ) AS is_read
  FROM edoc.notices n
  WHERE (
    n.unit_id IS NULL
    OR n.unit_id = ANY(COALESCE(p_dept_ids, ARRAY[]::INT[]))
  )
  ORDER BY n.created_at DESC
  LIMIT COALESCE(p_limit, 5);
END;
$$;


--
-- Name: fn_dashboard_recent_outgoing(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_recent_outgoing(p_unit_id integer, p_limit integer DEFAULT 10, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, doc_code character varying, abstract text, sent_date timestamp with time zone, doc_type_name character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY SELECT d.id,
    COALESCE(NULLIF(d.notation, ''), d.document_code, '')::VARCHAR,
    d.abstract, COALESCE(d.publish_date, d.received_date, d.created_at),
    COALESCE(dt.name, '')::VARCHAR
  FROM edoc.outgoing_docs d LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
  ORDER BY COALESCE(d.publish_date, d.received_date, d.created_at) DESC
  LIMIT COALESCE(p_limit, 10);
END; $$;


--
-- Name: fn_dashboard_task_by_status(integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_task_by_status(p_staff_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(status_code smallint, status_name text, task_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    hd.status AS status_code,
    CASE hd.status
      WHEN 0 THEN 'Mới'
      WHEN 1 THEN 'Đang xử lý'
      WHEN 2 THEN 'Chờ duyệt'
      WHEN 3 THEN 'Đã duyệt'
      WHEN 4 THEN 'Hoàn thành'
      WHEN -1 THEN 'Từ chối'
      WHEN -2 THEN 'Trả về'
      ELSE 'Khác'
    END::TEXT AS status_name,
    COUNT(*)::BIGINT AS task_count
  FROM edoc.handling_docs hd
  WHERE (p_dept_ids IS NULL OR hd.unit_id = ANY(p_dept_ids))
  GROUP BY hd.status
  ORDER BY hd.status;
END;
$$;


--
-- Name: fn_dashboard_top_departments(integer[], integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_top_departments(p_dept_ids integer[] DEFAULT NULL::integer[], p_limit integer DEFAULT 5) RETURNS TABLE(department_id integer, department_name character varying, doc_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  WITH dept_incoming AS (
    SELECT ind.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.incoming_docs ind
    WHERE ind.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR ind.unit_id = ANY(p_dept_ids))
    GROUP BY ind.department_id
  ),
  dept_outgoing AS (
    SELECT od.department_id AS dept_id, COUNT(*) AS cnt
    FROM edoc.outgoing_docs od
    WHERE od.department_id IS NOT NULL
      AND (p_dept_ids IS NULL OR od.unit_id = ANY(p_dept_ids))
    GROUP BY od.department_id
  ),
  combined AS (
    SELECT dept_id, SUM(cnt)::BIGINT AS total
    FROM (
      SELECT * FROM dept_incoming
      UNION ALL
      SELECT * FROM dept_outgoing
    ) sub
    GROUP BY dept_id
  )
  SELECT
    c.dept_id AS department_id,
    d.name AS department_name,
    c.total AS doc_count
  FROM combined c
  INNER JOIN public.departments d ON d.id = c.dept_id
  ORDER BY c.total DESC
  LIMIT COALESCE(p_limit, 5);
END;
$$;


--
-- Name: fn_dashboard_upcoming_tasks(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_dashboard_upcoming_tasks(p_staff_id integer, p_limit integer DEFAULT 10, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, title character varying, open_date timestamp with time zone, status smallint, progress_percent smallint, deadline timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT DISTINCT hd.id, hd.name::VARCHAR, hd.start_date, hd.status,
    COALESCE(hd.progress, 0::SMALLINT), hd.end_date
  FROM edoc.handling_docs hd
  WHERE hd.status != 4 AND hd.end_date >= NOW()
    AND (
      p_dept_ids IS NULL  -- admin: thấy tất cả
      OR hd.department_id = ANY(p_dept_ids)  -- user: filter theo subtree
      OR hd.curator = p_staff_id
      OR EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = hd.id AND shd.staff_id = p_staff_id)
    )
  ORDER BY hd.end_date ASC
  LIMIT COALESCE(p_limit, 10);
END; $$;


--
-- Name: fn_delegation_create(integer, integer, date, date, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_delegation_create(p_from_staff_id integer, p_to_staff_id integer, p_start_date date, p_end_date date, p_note text DEFAULT NULL::text) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  IF p_from_staff_id IS NULL OR p_to_staff_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn người ủy quyền và người nhận ủy quyền'::TEXT, 0;
    RETURN;
  END IF;
  IF p_from_staff_id = p_to_staff_id THEN
    RETURN QUERY SELECT FALSE, 'Không thể ủy quyền cho chính mình'::TEXT, 0;
    RETURN;
  END IF;
  IF p_start_date IS NULL OR p_end_date IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Ngày bắt đầu và ngày kết thúc không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_end_date < p_start_date THEN
    RETURN QUERY SELECT FALSE, 'Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu'::TEXT, 0;
    RETURN;
  END IF;

  -- Check staff exists
  IF NOT EXISTS(SELECT 1 FROM public.staff s WHERE s.id = p_from_staff_id AND s.is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Người ủy quyền không tồn tại'::TEXT, 0;
    RETURN;
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.staff s WHERE s.id = p_to_staff_id AND s.is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Người nhận ủy quyền không tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  -- Check overlap: same from_staff, active, date range overlaps
  IF EXISTS(
    SELECT 1 FROM edoc.delegations d
    WHERE d.from_staff_id = p_from_staff_id
      AND d.is_revoked = FALSE
      AND d.start_date <= p_end_date
      AND d.end_date >= p_start_date
  ) THEN
    RETURN QUERY SELECT FALSE, 'Đã tồn tại ủy quyền trong khoảng thời gian này'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.delegations (from_staff_id, to_staff_id, start_date, end_date, note)
  VALUES (p_from_staff_id, p_to_staff_id, p_start_date, p_end_date, p_note)
  RETURNING edoc.delegations.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao uy quyen thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_delegation_get_list(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_delegation_get_list(p_unit_id integer DEFAULT NULL::integer, p_staff_id integer DEFAULT NULL::integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id integer, from_staff_id integer, from_staff_name character varying, to_staff_id integer, to_staff_name character varying, start_date date, end_date date, note text, is_revoked boolean, revoked_at timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT dl.id, dl.from_staff_id,
         sf.full_name::VARCHAR AS from_staff_name,
         dl.to_staff_id,
         st.full_name::VARCHAR AS to_staff_name,
         dl.start_date, dl.end_date, dl.note,
         dl.is_revoked, dl.revoked_at, dl.created_at
  FROM edoc.delegations dl
    JOIN public.staff sf ON sf.id = dl.from_staff_id
    JOIN public.staff st ON st.id = dl.to_staff_id
  WHERE (p_dept_ids IS NULL OR sf.department_id = ANY(p_dept_ids))
    AND (p_unit_id IS NULL OR sf.unit_id = p_unit_id)
    AND (p_staff_id IS NULL OR dl.from_staff_id = p_staff_id OR dl.to_staff_id = p_staff_id)
  ORDER BY dl.created_at DESC;
$$;


--
-- Name: fn_delegation_revoke(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_delegation_revoke(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.delegations WHERE id = p_id AND is_revoked = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy ủy quyền hoặc đã thu hồi'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.delegations SET is_revoked = TRUE, revoked_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Thu hoi uy quyen thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_device_token_delete(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_device_token_delete(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM edoc.device_tokens
  WHERE id = p_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay device token'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xoa device token thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_device_token_get_by_staff(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_device_token_get_by_staff(p_staff_id integer) RETURNS TABLE(id bigint, device_token character varying, device_type character varying, is_active boolean, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    dt.id,
    dt.device_token,
    dt.device_type,
    dt.is_active,
    dt.created_at
  FROM edoc.device_tokens dt
  WHERE dt.staff_id = p_staff_id
    AND dt.is_active = true
  ORDER BY dt.created_at DESC;
END;
$$;


--
-- Name: fn_device_token_upsert(integer, character varying, character varying); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_device_token_upsert(p_staff_id integer, p_device_token character varying, p_device_type character varying DEFAULT 'web'::character varying) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.device_tokens (staff_id, device_token, device_type, updated_at)
  VALUES (p_staff_id, p_device_token, p_device_type, NOW())
  ON CONFLICT (device_token) DO UPDATE SET
    staff_id    = EXCLUDED.staff_id,
    device_type = EXCLUDED.device_type,
    is_active   = true,
    updated_at  = NOW()
  RETURNING edoc.device_tokens.id INTO v_id;

  RETURN QUERY SELECT true, 'Luu device token thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_digital_signature_create(bigint, character varying, integer, character varying, character varying); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_digital_signature_create(p_doc_id bigint, p_doc_type character varying, p_staff_id integer, p_sign_method character varying, p_original_file_path character varying DEFAULT NULL::character varying) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_id BIGINT;
BEGIN
  -- Validate doc_type
  IF p_doc_type NOT IN ('outgoing', 'drafting') THEN
    RETURN QUERY SELECT false, 'Loai van ban khong hop le'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Validate sign_method
  IF p_sign_method NOT IN ('smart_ca', 'esign_neac', 'usb_token') THEN
    RETURN QUERY SELECT false, 'Phuong thuc ky khong hop le'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.digital_signatures (
    doc_id, doc_type, staff_id, sign_method, original_file_path
  )
  VALUES (
    p_doc_id, p_doc_type, p_staff_id, p_sign_method, p_original_file_path
  )
  RETURNING edoc.digital_signatures.id INTO v_id;

  RETURN QUERY SELECT true, 'Tao yeu cau ky so thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_digital_signature_get_by_doc(bigint, character varying); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_digital_signature_get_by_doc(p_doc_id bigint, p_doc_type character varying) RETURNS TABLE(id bigint, doc_id bigint, doc_type character varying, staff_id integer, staff_name character varying, sign_method character varying, certificate_serial character varying, certificate_subject character varying, certificate_issuer character varying, signed_file_path character varying, original_file_path character varying, sign_status character varying, error_message text, signed_at timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    ds.id,
    ds.doc_id,
    ds.doc_type,
    ds.staff_id,
    s.full_name::VARCHAR AS staff_name,
    ds.sign_method,
    ds.certificate_serial,
    ds.certificate_subject,
    ds.certificate_issuer,
    ds.signed_file_path,
    ds.original_file_path,
    ds.sign_status,
    ds.error_message,
    ds.signed_at,
    ds.created_at
  FROM edoc.digital_signatures ds
  JOIN public.staff s ON s.id = ds.staff_id
  WHERE ds.doc_id = p_doc_id
    AND ds.doc_type = p_doc_type
  ORDER BY ds.created_at DESC;
END;
$$;


--
-- Name: fn_digital_signature_get_by_id(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_digital_signature_get_by_id(p_id bigint) RETURNS TABLE(id bigint, doc_id bigint, doc_type character varying, staff_id integer, staff_name character varying, sign_method character varying, certificate_serial character varying, certificate_subject character varying, certificate_issuer character varying, signed_file_path character varying, original_file_path character varying, sign_status character varying, error_message text, signed_at timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    ds.id,
    ds.doc_id,
    ds.doc_type,
    ds.staff_id,
    s.full_name::VARCHAR AS staff_name,
    ds.sign_method,
    ds.certificate_serial,
    ds.certificate_subject,
    ds.certificate_issuer,
    ds.signed_file_path,
    ds.original_file_path,
    ds.sign_status,
    ds.error_message,
    ds.signed_at,
    ds.created_at
  FROM edoc.digital_signatures ds
  JOIN public.staff s ON s.id = ds.staff_id
  WHERE ds.id = p_id;
END;
$$;


--
-- Name: fn_digital_signature_update_status(bigint, character varying, character varying, character varying, character varying, character varying, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_digital_signature_update_status(p_id bigint, p_sign_status character varying, p_certificate_serial character varying DEFAULT NULL::character varying, p_certificate_subject character varying DEFAULT NULL::character varying, p_certificate_issuer character varying DEFAULT NULL::character varying, p_signed_file_path character varying DEFAULT NULL::character varying, p_error_message text DEFAULT NULL::text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE edoc.digital_signatures
  SET sign_status         = p_sign_status,
      certificate_serial  = COALESCE(p_certificate_serial, certificate_serial),
      certificate_subject = COALESCE(p_certificate_subject, certificate_subject),
      certificate_issuer  = COALESCE(p_certificate_issuer, certificate_issuer),
      signed_file_path    = COALESCE(p_signed_file_path, signed_file_path),
      error_message       = p_error_message,
      signed_at           = CASE WHEN p_sign_status = 'signed' THEN NOW() ELSE signed_at END
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay ban ghi ky so'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cap nhat trang thai ky so thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_doc_book_create(smallint, integer, character varying, boolean, text, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_book_create(p_type_id smallint, p_unit_id integer DEFAULT NULL::integer, p_name character varying DEFAULT NULL::character varying, p_is_default boolean DEFAULT false, p_description text DEFAULT NULL::text, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT; v_exists BOOLEAN; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  SELECT EXISTS(
    SELECT 1 FROM edoc.doc_books
    WHERE type_id = p_type_id AND unit_id = v_unit_id
      AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND is_deleted = FALSE
  ) INTO v_exists;

  IF v_exists THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  IF p_is_default THEN
    UPDATE edoc.doc_books SET is_default = FALSE
    WHERE type_id = p_type_id AND unit_id = v_unit_id AND is_deleted = FALSE;
  END IF;

  INSERT INTO edoc.doc_books (type_id, unit_id, name, is_default, description, created_by)
  VALUES (p_type_id, v_unit_id, TRIM(p_name), COALESCE(p_is_default, FALSE), p_description, p_created_by)
  RETURNING doc_books.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao so van ban thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_doc_book_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_book_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_books WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sổ văn bản'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_books SET is_deleted = TRUE WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa so van ban thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_doc_book_get_by_id(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_book_get_by_id(p_id integer) RETURNS TABLE(id integer, unit_id integer, type_id smallint, name character varying, description text, sort_order integer, is_default boolean, created_by integer, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT b.id, b.unit_id, b.type_id, b.name::VARCHAR,
         b.description, b.sort_order, b.is_default,
         b.created_by, b.created_at
  FROM edoc.doc_books b
  WHERE b.id = p_id AND b.is_deleted = FALSE;
$$;


--
-- Name: fn_doc_book_get_list(smallint, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_book_get_list(p_type_id smallint DEFAULT NULL::smallint, p_unit_id integer DEFAULT NULL::integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, unit_id integer, type_id smallint, name character varying, description text, sort_order integer, is_default boolean, created_by integer, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT b.id, b.unit_id, b.type_id, b.name::VARCHAR,
         b.description, b.sort_order, b.is_default,
         b.created_by, b.created_at
  FROM edoc.doc_books b
  WHERE b.is_deleted = FALSE
    AND (p_type_id IS NULL OR b.type_id = p_type_id)
    AND (
      CASE WHEN p_dept_id IS NOT NULL THEN b.unit_id = public.fn_get_ancestor_unit(p_dept_id)
      ELSE (p_unit_id IS NULL OR b.unit_id = p_unit_id) END
    )
  ORDER BY b.sort_order, b.name;
$$;


--
-- Name: fn_doc_book_set_default(integer, smallint, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_book_set_default(p_id integer, p_type_id smallint, p_unit_id integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  UPDATE edoc.doc_books SET is_default = FALSE
  WHERE type_id = p_type_id AND unit_id = v_unit_id AND is_deleted = FALSE;

  UPDATE edoc.doc_books SET is_default = TRUE
  WHERE id = p_id AND is_deleted = FALSE;

  RETURN FOUND;
END;
$$;


--
-- Name: fn_doc_book_update(integer, character varying, boolean, text, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_book_update(p_id integer, p_name character varying, p_is_default boolean DEFAULT NULL::boolean, p_description text DEFAULT NULL::text, p_sort_order integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_rec edoc.doc_books%ROWTYPE;
BEGIN
  SELECT * INTO v_rec FROM edoc.doc_books WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sổ văn bản'::TEXT;
    RETURN;
  END IF;

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique name (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.doc_books
    WHERE type_id = v_rec.type_id AND unit_id = v_rec.unit_id
      AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND id <> p_id AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Tên sổ văn bản đã tồn tại trong đơn vị'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_books SET
    name        = TRIM(p_name),
    is_default  = COALESCE(p_is_default, is_default),
    description = COALESCE(p_description, description),
    sort_order  = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_doc_column_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_column_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM edoc.doc_columns WHERE id = p_id AND is_system = false;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy hoặc không thể xóa trường hệ thống'::TEXT; RETURN;
  END IF;
  RETURN QUERY SELECT TRUE, 'Đã xóa'::TEXT;
END;
$$;


--
-- Name: fn_doc_column_get_all(); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_column_get_all() RETURNS TABLE(id integer, type_id smallint, doc_type_name character varying, column_name character varying, label character varying, data_type character varying, max_length integer, sort_order integer, is_mandatory boolean, is_system boolean)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.type_id, dt.name, c.column_name, c.label, c.data_type,
         c.max_length, c.sort_order, c.is_mandatory, c.is_system
  FROM edoc.doc_columns c
  JOIN edoc.doc_types dt ON dt.id = c.type_id
  ORDER BY dt.name, c.sort_order;
END;
$$;


--
-- Name: fn_doc_column_get_by_type(smallint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_column_get_by_type(p_type_id smallint) RETURNS TABLE(id integer, type_id smallint, column_name character varying, label character varying, data_type character varying, max_length integer, sort_order integer, is_mandatory boolean, is_system boolean, is_show_all boolean, description text)
    LANGUAGE plpgsql STABLE
    AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.type_id, c.column_name, c.label, c.data_type,
         c.max_length, c.sort_order, c.is_mandatory, c.is_system,
         c.is_show_all, c.description
  FROM edoc.doc_columns c
  WHERE c.type_id = p_type_id
  ORDER BY c.sort_order;
END;
$$;


--
-- Name: fn_doc_column_get_list(smallint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_column_get_list(p_type_id smallint) RETURNS TABLE(id integer, type_id smallint, column_name character varying, label character varying, is_mandatory boolean, is_show_all boolean, sort_order integer, description text)
    LANGUAGE sql STABLE
    AS $$
  SELECT c.id, c.type_id, c.column_name::VARCHAR, c.label::VARCHAR,
         c.is_mandatory, c.is_show_all, c.sort_order, c.description
  FROM edoc.doc_columns c
  WHERE c.type_id = p_type_id
  ORDER BY c.sort_order;
$$;


--
-- Name: fn_doc_column_save(integer, integer, character varying, character varying, character varying, integer, integer, boolean, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_column_save(p_id integer DEFAULT NULL::integer, p_type_id integer DEFAULT NULL::integer, p_column_name character varying DEFAULT NULL::character varying, p_label character varying DEFAULT NULL::character varying, p_data_type character varying DEFAULT 'text'::character varying, p_max_length integer DEFAULT NULL::integer, p_sort_order integer DEFAULT 0, p_is_mandatory boolean DEFAULT false, p_description text DEFAULT NULL::text) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  IF p_label IS NULL OR TRIM(p_label) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nhãn hiển thị là bắt buộc'::TEXT, 0; RETURN;
  END IF;

  IF p_id IS NOT NULL AND p_id > 0 THEN
    -- Update
    UPDATE edoc.doc_columns SET
      column_name = COALESCE(p_column_name, column_name),
      label = TRIM(p_label),
      data_type = COALESCE(p_data_type, data_type),
      max_length = p_max_length,
      sort_order = COALESCE(p_sort_order, sort_order),
      is_mandatory = COALESCE(p_is_mandatory, is_mandatory),
      description = NULLIF(TRIM(p_description), '')
    WHERE edoc.doc_columns.id = p_id AND is_system = false;

    IF NOT FOUND THEN
      RETURN QUERY SELECT FALSE, 'Không tìm thấy hoặc không thể sửa trường hệ thống'::TEXT, 0; RETURN;
    END IF;
    v_id := p_id;
  ELSE
    -- Insert
    INSERT INTO edoc.doc_columns (type_id, column_name, label, data_type, max_length, sort_order, is_mandatory, description)
    VALUES (p_type_id, p_column_name, TRIM(p_label), COALESCE(p_data_type, 'text'), p_max_length, COALESCE(p_sort_order, 0), COALESCE(p_is_mandatory, false), NULLIF(TRIM(p_description), ''))
    RETURNING edoc.doc_columns.id INTO v_id;
  END IF;

  RETURN QUERY SELECT TRUE, 'Lưu thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_doc_column_toggle_visibility(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_column_toggle_visibility(p_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE edoc.doc_columns SET is_show_all = NOT is_show_all WHERE id = p_id;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_doc_column_update(integer, character varying, boolean, boolean, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_column_update(p_id integer, p_label character varying DEFAULT NULL::character varying, p_is_mandatory boolean DEFAULT NULL::boolean, p_is_show_all boolean DEFAULT NULL::boolean, p_sort_order integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_columns WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy thuộc tính'::TEXT;
    RETURN;
  END IF;

  IF p_label IS NOT NULL AND LENGTH(p_label) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Nhãn hiển thị không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_columns SET
    label        = COALESCE(NULLIF(TRIM(p_label), ''), label),
    is_mandatory = COALESCE(p_is_mandatory, is_mandatory),
    is_show_all  = COALESCE(p_is_show_all, is_show_all),
    sort_order   = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_doc_field_create(integer, character varying, character varying, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_field_create(p_unit_id integer DEFAULT NULL::integer, p_code character varying DEFAULT NULL::character varying, p_name character varying DEFAULT NULL::character varying, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên lĩnh vực không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được vượt quá 20 ký tự'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên lĩnh vực không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  IF EXISTS(
    SELECT 1 FROM edoc.doc_fields
    WHERE unit_id = v_unit_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_fields (unit_id, code, name)
  VALUES (v_unit_id, TRIM(p_code), TRIM(p_name))
  RETURNING doc_fields.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao linh vuc thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_doc_field_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_field_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_fields WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy lĩnh vực'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.doc_fields WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa linh vuc thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_doc_field_get_by_id(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_field_get_by_id(p_id integer) RETURNS TABLE(id integer, unit_id integer, code character varying, name character varying, sort_order integer, is_active boolean, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT f.id, f.unit_id, f.code::VARCHAR, f.name::VARCHAR,
         f.sort_order, f.is_active, f.created_at
  FROM edoc.doc_fields f WHERE f.id = p_id;
$$;


--
-- Name: fn_doc_field_get_list(integer, character varying, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_field_get_list(p_unit_id integer DEFAULT NULL::integer, p_keyword character varying DEFAULT NULL::character varying, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, unit_id integer, code character varying, name character varying, sort_order integer, is_active boolean, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT f.id, f.unit_id, f.code::VARCHAR, f.name::VARCHAR,
         f.sort_order, f.is_active, f.created_at
  FROM edoc.doc_fields f
  WHERE (
    CASE WHEN p_dept_id IS NOT NULL THEN f.unit_id = public.fn_get_ancestor_unit(p_dept_id)
    ELSE (p_unit_id IS NULL OR f.unit_id = p_unit_id) END
  )
    AND (p_keyword IS NULL OR f.name ILIKE '%' || p_keyword || '%'
         OR f.code ILIKE '%' || p_keyword || '%')
  ORDER BY f.sort_order, f.name;
$$;


--
-- Name: fn_doc_field_update(integer, character varying, character varying, integer, boolean); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_field_update(p_id integer, p_code character varying DEFAULT NULL::character varying, p_name character varying DEFAULT NULL::character varying, p_sort_order integer DEFAULT NULL::integer, p_is_active boolean DEFAULT NULL::boolean) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_unit_id INT;
BEGIN
  SELECT unit_id INTO v_unit_id FROM edoc.doc_fields WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy lĩnh vực'::TEXT;
    RETURN;
  END IF;

  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên lĩnh vực không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.doc_fields
    WHERE unit_id = v_unit_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã lĩnh vực đã tồn tại trong đơn vị'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_fields SET
    code       = TRIM(p_code),
    name       = TRIM(p_name),
    sort_order = COALESCE(p_sort_order, sort_order),
    is_active  = COALESCE(p_is_active, is_active)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_doc_flow_create(integer, character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_create(p_unit_id integer DEFAULT NULL::integer, p_name character varying DEFAULT NULL::character varying, p_version character varying DEFAULT NULL::character varying, p_doc_field_id integer DEFAULT NULL::integer, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quy trình không được để trống'::TEXT, 0::INT;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM edoc.doc_flows
    WHERE unit_id = v_unit_id AND name = TRIM(p_name)
      AND (version = p_version OR (version IS NULL AND p_version IS NULL))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Quy trình với tên và phiên bản này đã tồn tại'::TEXT, 0::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_flows (unit_id, name, version, doc_field_id, is_active, created_by, department_id)
  VALUES (v_unit_id, TRIM(p_name), NULLIF(TRIM(COALESCE(p_version, '')), ''), p_doc_field_id, TRUE, p_created_by, p_department_id)
  RETURNING edoc.doc_flows.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo quy trình thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_doc_flow_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Không xóa nếu đang được sử dụng bởi HSCV
  IF EXISTS (SELECT 1 FROM edoc.handling_docs WHERE workflow_id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa quy trình đang được sử dụng bởi hồ sơ công việc'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.doc_flows WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Quy trình không tồn tại'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa quy trình thành công'::TEXT;
END;
$$;


--
-- Name: fn_doc_flow_get_by_id(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_get_by_id(p_id integer) RETURNS TABLE(id integer, unit_id integer, name character varying, version character varying, doc_field_id integer, doc_field_name character varying, is_active boolean, created_by integer, created_at timestamp with time zone, updated_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id,
    f.unit_id,
    f.name,
    f.version,
    f.doc_field_id,
    df.name  AS doc_field_name,
    f.is_active,
    f.created_by,
    f.created_at,
    f.updated_at
  FROM edoc.doc_flows f
  LEFT JOIN edoc.doc_fields df ON df.id = f.doc_field_id
  WHERE f.id = p_id;
END;
$$;


--
-- Name: fn_doc_flow_get_list(integer, integer, boolean, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_get_list(p_unit_id integer, p_doc_field_id integer DEFAULT NULL::integer, p_is_active boolean DEFAULT NULL::boolean, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, name character varying, version character varying, doc_field_id integer, doc_field_name character varying, is_active boolean, step_count bigint, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT f.id, f.name, f.version, f.doc_field_id, df.name AS doc_field_name,
    f.is_active, COUNT(s.id) AS step_count, f.created_at
  FROM edoc.doc_flows f
  LEFT JOIN edoc.doc_fields df ON df.id = f.doc_field_id
  LEFT JOIN edoc.doc_flow_steps s ON s.flow_id = f.id
  WHERE f.unit_id = v_unit_id
    AND (p_doc_field_id IS NULL OR f.doc_field_id = p_doc_field_id)
    AND (p_is_active IS NULL OR f.is_active = p_is_active)
  GROUP BY f.id, f.name, f.version, f.doc_field_id, df.name, f.is_active, f.created_at
  ORDER BY f.name, f.version;
END;
$$;


--
-- Name: fn_doc_flow_step_assign_staff(integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_step_assign_staff(p_step_id integer, p_staff_ids integer[]) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_staff_id INT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.doc_flow_steps WHERE id = p_step_id) THEN
    RETURN QUERY SELECT FALSE, 'Bước quy trình không tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Xóa toàn bộ cán bộ cũ của bước
  DELETE FROM edoc.doc_flow_step_staff WHERE step_id = p_step_id;

  -- Gán mới nếu có danh sách
  IF p_staff_ids IS NOT NULL AND ARRAY_LENGTH(p_staff_ids, 1) > 0 THEN
    FOREACH v_staff_id IN ARRAY p_staff_ids LOOP
      INSERT INTO edoc.doc_flow_step_staff (step_id, staff_id)
      VALUES (p_step_id, v_staff_id)
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;

  RETURN QUERY SELECT TRUE, 'Cập nhật cán bộ thực hiện bước thành công'::TEXT;
END;
$$;


--
-- Name: fn_doc_flow_step_create(integer, character varying, integer, character varying, boolean, integer, double precision, double precision); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_step_create(p_flow_id integer, p_step_name character varying, p_step_order integer, p_step_type character varying, p_allow_sign boolean, p_deadline_days integer, p_position_x double precision, p_position_y double precision) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  IF p_step_name IS NULL OR TRIM(p_step_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên bước không được để trống'::TEXT, 0::INT;
    RETURN;
  END IF;

  IF p_step_type NOT IN ('start', 'process', 'end') THEN
    RETURN QUERY SELECT FALSE, 'Loại bước không hợp lệ (start/process/end)'::TEXT, 0::INT;
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM edoc.doc_flows WHERE id = p_flow_id) THEN
    RETURN QUERY SELECT FALSE, 'Quy trình không tồn tại'::TEXT, 0::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_flow_steps (
    flow_id, step_name, step_order, step_type,
    allow_sign, deadline_days, position_x, position_y
  ) VALUES (
    p_flow_id, TRIM(p_step_name), COALESCE(p_step_order, 0),
    COALESCE(p_step_type, 'process'), COALESCE(p_allow_sign, FALSE),
    COALESCE(p_deadline_days, 0), COALESCE(p_position_x, 0), COALESCE(p_position_y, 0)
  )
  RETURNING edoc.doc_flow_steps.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo bước quy trình thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_doc_flow_step_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_step_delete(p_step_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM edoc.doc_flow_steps WHERE id = p_step_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Bước quy trình không tồn tại'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa bước quy trình thành công'::TEXT;
END;
$$;


--
-- Name: fn_doc_flow_step_get_list(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_step_get_list(p_flow_id integer) RETURNS TABLE(id integer, step_name character varying, step_order integer, step_type character varying, allow_sign boolean, deadline_days integer, position_x double precision, position_y double precision)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    s.step_name,
    s.step_order,
    s.step_type,
    s.allow_sign,
    s.deadline_days,
    s.position_x,
    s.position_y
  FROM edoc.doc_flow_steps s
  WHERE s.flow_id = p_flow_id
  ORDER BY s.step_order, s.id;
END;
$$;


--
-- Name: fn_doc_flow_step_get_staff(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_step_get_staff(p_step_id integer) RETURNS TABLE(id integer, staff_id integer, staff_name text, position_name character varying, department_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    ss.id,
    ss.staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
    p.name                                        AS position_name,
    d.name                                        AS department_name
  FROM edoc.doc_flow_step_staff ss
  JOIN public.staff s ON s.id = ss.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE ss.step_id = p_step_id
  ORDER BY s.last_name, s.first_name;
END;
$$;


--
-- Name: fn_doc_flow_step_link_create(integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_step_link_create(p_from_step_id integer, p_to_step_id integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  IF p_from_step_id = p_to_step_id THEN
    RETURN QUERY SELECT FALSE, 'Không thể tạo liên kết vòng lặp cùng bước'::TEXT, 0::INT;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM edoc.doc_flow_step_links
    WHERE from_step_id = p_from_step_id AND to_step_id = p_to_step_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Liên kết giữa hai bước này đã tồn tại'::TEXT, 0::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.doc_flow_step_links (from_step_id, to_step_id)
  VALUES (p_from_step_id, p_to_step_id)
  RETURNING edoc.doc_flow_step_links.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo liên kết bước thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_doc_flow_step_link_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_step_link_delete(p_link_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM edoc.doc_flow_step_links WHERE id = p_link_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Liên kết không tồn tại'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa liên kết bước thành công'::TEXT;
END;
$$;


--
-- Name: fn_doc_flow_step_update(integer, character varying, integer, character varying, boolean, integer, double precision, double precision); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_step_update(p_step_id integer, p_step_name character varying, p_step_order integer, p_step_type character varying, p_allow_sign boolean, p_deadline_days integer, p_position_x double precision, p_position_y double precision) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF p_step_name IS NULL OR TRIM(p_step_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên bước không được để trống'::TEXT;
    RETURN;
  END IF;

  IF p_step_type NOT IN ('start', 'process', 'end') THEN
    RETURN QUERY SELECT FALSE, 'Loại bước không hợp lệ (start/process/end)'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_flow_steps SET
    step_name     = TRIM(p_step_name),
    step_order    = COALESCE(p_step_order, step_order),
    step_type     = COALESCE(p_step_type, step_type),
    allow_sign    = COALESCE(p_allow_sign, allow_sign),
    deadline_days = COALESCE(p_deadline_days, deadline_days),
    position_x    = COALESCE(p_position_x, position_x),
    position_y    = COALESCE(p_position_y, position_y)
  WHERE id = p_step_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Bước quy trình không tồn tại'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Cập nhật bước quy trình thành công'::TEXT;
END;
$$;


--
-- Name: fn_doc_flow_update(integer, character varying, character varying, integer, boolean); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_flow_update(p_id integer, p_name character varying, p_version character varying, p_doc_field_id integer, p_is_active boolean) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quy trình không được để trống'::TEXT;
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM edoc.doc_flows WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Quy trình không tồn tại'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_flows SET
    name          = TRIM(p_name),
    version       = NULLIF(TRIM(COALESCE(p_version, '')), ''),
    doc_field_id  = p_doc_field_id,
    is_active     = COALESCE(p_is_active, is_active),
    updated_at    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật quy trình thành công'::TEXT;
END;
$$;


--
-- Name: fn_doc_save_extra_fields(character varying, bigint, jsonb); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_save_extra_fields(p_doc_type character varying, p_doc_id bigint, p_extra jsonb) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF p_doc_type = 'incoming' THEN
    UPDATE edoc.incoming_docs SET extra_fields = COALESCE(p_extra, '{}') WHERE id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    UPDATE edoc.outgoing_docs SET extra_fields = COALESCE(p_extra, '{}') WHERE id = p_doc_id;
  ELSIF p_doc_type = 'drafting' THEN
    UPDATE edoc.drafting_docs SET extra_fields = COALESCE(p_extra, '{}') WHERE id = p_doc_id;
  ELSE
    RETURN QUERY SELECT FALSE, 'Loại VB không hợp lệ'::TEXT; RETURN;
  END IF;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT; RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Lưu trường bổ sung thành công'::TEXT;
END;
$$;


--
-- Name: fn_doc_type_create(smallint, integer, character varying, character varying, smallint, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_type_create(p_type_id smallint, p_parent_id integer DEFAULT NULL::integer, p_name character varying DEFAULT NULL::character varying, p_code character varying DEFAULT NULL::character varying, p_notation_type smallint DEFAULT 0, p_sort_order integer DEFAULT 0, p_created_by integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  -- Validate required
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên loại văn bản không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được vượt quá 20 ký tự'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên loại văn bản không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code
  IF EXISTS(
    SELECT 1 FROM edoc.doc_types
    WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code)) AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản đã tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  -- Check parent exists
  IF p_parent_id IS NOT NULL THEN
    IF NOT EXISTS(SELECT 1 FROM edoc.doc_types dt WHERE dt.id = p_parent_id AND dt.is_deleted = FALSE) THEN
      RETURN QUERY SELECT FALSE, 'Loại văn bản cha không tồn tại'::TEXT, 0;
      RETURN;
    END IF;
  END IF;

  INSERT INTO edoc.doc_types (type_id, parent_id, code, name, notation_type, sort_order, created_by)
  VALUES (p_type_id, p_parent_id, TRIM(p_code), TRIM(p_name), p_notation_type, p_sort_order, p_created_by)
  RETURNING doc_types.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao loai van ban thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_doc_type_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_type_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_child_count INT;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_types WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy loại văn bản'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_child_count
  FROM edoc.doc_types WHERE parent_id = p_id AND is_deleted = FALSE;

  IF v_child_count > 0 THEN
    RETURN QUERY SELECT FALSE, ('Không thể xóa: còn '|| v_child_count ||' loại văn bản con')::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_types SET is_deleted = TRUE WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa loai van ban thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_doc_type_get_by_id(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_type_get_by_id(p_id integer) RETURNS TABLE(id integer, type_id smallint, parent_id integer, code character varying, name character varying, description text, sort_order integer, notation_type smallint, is_default boolean, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT t.id, t.type_id, t.parent_id, t.code::VARCHAR, t.name::VARCHAR,
         t.description, t.sort_order, t.notation_type,
         t.is_default, t.created_at
  FROM edoc.doc_types t
  WHERE t.id = p_id AND t.is_deleted = FALSE;
$$;


--
-- Name: fn_doc_type_get_tree(smallint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_type_get_tree(p_type_id smallint DEFAULT NULL::smallint) RETURNS TABLE(id integer, type_id smallint, parent_id integer, code character varying, name character varying, description text, sort_order integer, notation_type smallint, is_default boolean, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT t.id, t.type_id, t.parent_id, t.code::VARCHAR, t.name::VARCHAR,
         t.description, t.sort_order, t.notation_type,
         t.is_default, t.created_at
  FROM edoc.doc_types t
  WHERE t.is_deleted = FALSE
    AND (p_type_id IS NULL OR t.type_id = p_type_id)
  ORDER BY t.sort_order, t.name;
$$;


--
-- Name: fn_doc_type_update(integer, integer, character varying, character varying, smallint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_doc_type_update(p_id integer, p_parent_id integer DEFAULT NULL::integer, p_name character varying DEFAULT NULL::character varying, p_code character varying DEFAULT NULL::character varying, p_notation_type smallint DEFAULT NULL::smallint, p_sort_order integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.doc_types WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy loại văn bản'::TEXT;
    RETURN;
  END IF;

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên loại văn bản không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_code IS NULL OR TRIM(p_code) = '' THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.doc_types
    WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã loại văn bản đã tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Prevent self-referencing
  IF p_parent_id = p_id THEN
    RETURN QUERY SELECT FALSE, 'Không thể chọn chính mình làm cha'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.doc_types SET
    parent_id     = p_parent_id,
    name          = TRIM(p_name),
    code          = TRIM(p_code),
    notation_type = COALESCE(p_notation_type, notation_type),
    sort_order    = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_drafting_doc_approve(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_approve(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_name TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT; RETURN;
  END IF;
  SELECT full_name INTO v_name FROM public.staff WHERE id = p_staff_id;
  UPDATE edoc.drafting_docs
  SET approved = TRUE, approver = v_name, rejected_by = NULL, rejection_reason = NULL,
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Duyệt văn bản dự thảo thành công'::TEXT;
END; $$;


--
-- Name: fn_drafting_doc_count_unread(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_count_unread(p_unit_id integer, p_staff_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
    AND (ud.is_read IS NULL OR ud.is_read = FALSE);
  RETURN v_count;
END; $$;


--
-- Name: fn_drafting_doc_create(integer, timestamp with time zone, integer, character varying, character varying, character varying, text, integer, integer, integer, timestamp with time zone, character varying, timestamp with time zone, integer, integer, integer, smallint, smallint, integer, integer, timestamp with time zone, text, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_create(p_unit_id integer, p_received_date timestamp with time zone, p_number integer, p_sub_number character varying, p_notation character varying, p_document_code character varying, p_abstract text, p_drafting_unit_id integer DEFAULT NULL::integer, p_drafting_user_id integer DEFAULT NULL::integer, p_publish_unit_id integer DEFAULT NULL::integer, p_publish_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_signer character varying DEFAULT NULL::character varying, p_sign_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_doc_book_id integer DEFAULT NULL::integer, p_doc_type_id integer DEFAULT NULL::integer, p_doc_field_id integer DEFAULT NULL::integer, p_secret_id smallint DEFAULT 1, p_urgent_id smallint DEFAULT 1, p_number_paper integer DEFAULT 1, p_number_copies integer DEFAULT 1, p_expired_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_recipients text DEFAULT NULL::text, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_number IS NULL OR p_number = 0 THEN
    p_number := edoc.fn_drafting_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  -- Resolve department_id from created_by if not provided
  IF p_department_id IS NULL AND p_created_by IS NOT NULL THEN
    SELECT s.department_id INTO p_department_id FROM public.staff s WHERE s.id = p_created_by;
  END IF;

  INSERT INTO edoc.drafting_docs (
    unit_id, department_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, doc_book_id, doc_type_id, doc_field_id,
    secret_id, urgent_id, number_paper, number_copies, expired_date,
    recipients, created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_department_id, p_unit_id), COALESCE(p_received_date, NOW()), p_number,
    NULLIF(TRIM(p_sub_number), ''), NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), p_drafting_unit_id, p_drafting_user_id, p_publish_unit_id, p_publish_date,
    NULLIF(TRIM(p_signer), ''), p_sign_date, p_doc_book_id, p_doc_type_id, p_doc_field_id,
    COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1), p_expired_date,
    NULLIF(TRIM(p_recipients), ''), p_created_by, p_created_by
  )
  RETURNING edoc.drafting_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản dự thảo thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_drafting_doc_delete(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_delete(p_id bigint) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_approved BOOLEAN;
  v_released BOOLEAN;
BEGIN
  SELECT approved, is_released INTO v_approved, v_released
  FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;
  IF v_released = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa văn bản dự thảo thành công'::TEXT;
END;
$$;


--
-- Name: fn_drafting_doc_get_by_id(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_get_by_id(p_id bigint, p_staff_id integer) RETURNS TABLE(id bigint, unit_id integer, received_date timestamp with time zone, number integer, sub_number character varying, notation character varying, document_code character varying, abstract text, drafting_unit_id integer, drafting_user_id integer, publish_unit_id integer, publish_date timestamp with time zone, signer character varying, sign_date timestamp with time zone, doc_book_id integer, doc_type_id integer, doc_field_id integer, secret_id smallint, urgent_id smallint, number_paper integer, number_copies integer, expired_date timestamp with time zone, recipients text, approver character varying, approved boolean, is_released boolean, released_date timestamp with time zone, reject_reason text, created_by integer, created_at timestamp with time zone, updated_by integer, updated_at timestamp with time zone, doc_book_name character varying, doc_type_name character varying, doc_type_code character varying, doc_field_name character varying, drafting_unit_name character varying, drafting_user_name character varying, publish_unit_name character varying, created_by_name character varying, is_read boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Đánh dấu đã đọc
  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, is_read, read_at)
  VALUES (p_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (drafting_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_drafting_docs.read_at, NOW());

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.sub_number,
    d.notation, d.document_code, d.abstract,
    d.drafting_unit_id, d.drafting_user_id, d.publish_unit_id, d.publish_date,
    d.signer, d.sign_date, d.doc_book_id, d.doc_type_id, d.doc_field_id,
    d.secret_id, d.urgent_id, d.number_paper, d.number_copies,
    d.expired_date, d.recipients, d.approver, d.approved,
    d.is_released, d.released_date,
    d.reject_reason,                                -- MỚI
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name,
    du.name, ds.full_name,
    pu.name,                                        -- MỚI: publish_unit_name
    s.full_name,
    TRUE
  FROM edoc.drafting_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
  LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
  LEFT JOIN public.departments pu ON pu.id = d.publish_unit_id    -- MỚI
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;


--
-- Name: fn_drafting_doc_get_history(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_get_history(p_doc_id bigint) RETURNS TABLE(event_type character varying, event_time timestamp with time zone, staff_name character varying, content text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM (
    -- Tạo
    SELECT 'created'::VARCHAR AS evt, d.created_at AS etime, s.full_name AS sname,
           ('Tạo văn bản dự thảo, số: ' || d.number)::TEXT AS econtent
    FROM edoc.drafting_docs d
    JOIN public.staff s ON s.id = d.created_by
    WHERE d.id = p_doc_id

    UNION ALL
    -- Duyệt
    SELECT 'approved'::VARCHAR, d.updated_at, d.approver::VARCHAR, 'Duyệt văn bản dự thảo'::TEXT
    FROM edoc.drafting_docs d
    WHERE d.id = p_doc_id AND d.approved = TRUE

    UNION ALL
    -- Phát hành
    SELECT 'released'::VARCHAR, d.released_date, s.full_name, 'Phát hành thành văn bản đi'::TEXT
    FROM edoc.drafting_docs d
    JOIN public.staff s ON s.id = d.updated_by
    WHERE d.id = p_doc_id AND d.is_released = TRUE

    UNION ALL
    -- Gửi
    SELECT 'sent'::VARCHAR, ud.created_at, s.full_name, 'Nhận văn bản'::TEXT
    FROM edoc.user_drafting_docs ud
    JOIN public.staff s ON s.id = ud.staff_id
    WHERE ud.drafting_doc_id = p_doc_id
  ) sub
  ORDER BY sub.etime DESC;
END;
$$;


--
-- Name: fn_drafting_doc_get_list(integer, integer, integer, integer, integer, smallint, boolean, boolean, timestamp with time zone, timestamp with time zone, text, integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_get_list(p_unit_id integer, p_staff_id integer, p_doc_book_id integer DEFAULT NULL::integer, p_doc_type_id integer DEFAULT NULL::integer, p_doc_field_id integer DEFAULT NULL::integer, p_urgent_id smallint DEFAULT NULL::smallint, p_is_released boolean DEFAULT NULL::boolean, p_approved boolean DEFAULT NULL::boolean, p_from_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_to_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_keyword text DEFAULT NULL::text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, unit_id integer, received_date timestamp with time zone, number integer, sub_number character varying, notation character varying, document_code character varying, abstract text, drafting_unit_id integer, drafting_user_id integer, publish_unit_id integer, publish_date timestamp with time zone, signer character varying, sign_date timestamp with time zone, doc_book_id integer, doc_type_id integer, doc_field_id integer, secret_id smallint, urgent_id smallint, number_paper integer, number_copies integer, expired_date timestamp with time zone, recipients text, approver character varying, approved boolean, is_released boolean, released_date timestamp with time zone, created_by integer, created_at timestamp with time zone, doc_book_name character varying, doc_type_name character varying, doc_type_code character varying, doc_field_name character varying, drafting_unit_name character varying, drafting_user_name character varying, created_by_name character varying, is_read boolean, read_at timestamp with time zone, attachment_count bigint, total_count bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_offset INT; v_keyword TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id AS doc_id, d.*,
      db.name AS _doc_book_name, dt.name AS _doc_type_name, dt.code AS _doc_type_code,
      df.name AS _doc_field_name, du.name AS _drafting_unit_name, ds.full_name AS _drafting_user_name,
      s.full_name AS _created_by_name, ud.is_read AS _is_read, ud.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_drafting_docs a WHERE a.drafting_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.drafting_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_drafting_docs ud ON ud.drafting_doc_id = d.id AND ud.staff_id = p_staff_id
    WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_is_released IS NULL OR d.is_released = p_is_released)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (v_keyword IS NULL OR d.abstract ILIKE '%' || v_keyword || '%' OR d.notation ILIKE '%' || v_keyword || '%' OR d.signer ILIKE '%' || v_keyword || '%' OR d.recipients ILIKE '%' || v_keyword || '%')
    ORDER BY d.received_date DESC, d.number DESC LIMIT p_page_size OFFSET v_offset
  )
  SELECT f.doc_id, f.unit_id, f.received_date, f.number, f.sub_number, f.notation, f.document_code, f.abstract,
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id, f.publish_date, f.signer, f.sign_date,
    f.doc_book_id, f.doc_type_id, f.doc_field_id, f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.expired_date, f.recipients, f.approver, f.approved, f.is_released, f.released_date,
    f.created_by, f.created_at, f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at, f._attachment_count, f._total_count
  FROM filtered f;
END; $$;


--
-- Name: fn_drafting_doc_get_next_number(integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_get_next_number(p_doc_book_id integer, p_unit_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_max INT;
BEGIN
  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.drafting_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = p_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;


--
-- Name: fn_drafting_doc_get_recipients(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_get_recipients(p_doc_id bigint) RETURNS TABLE(id bigint, staff_id integer, staff_name character varying, position_name character varying, department_name character varying, is_read boolean, read_at timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    ud.id, ud.staff_id,
    s.full_name,
    p.name AS position_name,
    dep.name AS department_name,
    ud.is_read, ud.read_at, ud.created_at
  FROM edoc.user_drafting_docs ud
  JOIN public.staff s ON s.id = ud.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  WHERE ud.drafting_doc_id = p_doc_id
  ORDER BY ud.created_at DESC;
END;
$$;


--
-- Name: fn_drafting_doc_mark_read_bulk(bigint[], integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_mark_read_bulk(p_doc_ids bigint[], p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, is_read, read_at)
  SELECT unnest(p_doc_ids), p_staff_id, TRUE, NOW()
  ON CONFLICT (drafting_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_drafting_docs.read_at, NOW());

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu đọc thành công'::TEXT;
END;
$$;


--
-- Name: fn_drafting_doc_reject(bigint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_reject(p_id bigint, p_staff_id integer, p_reason text DEFAULT NULL::text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT; RETURN;
  END IF;
  UPDATE edoc.drafting_docs
  SET approved = FALSE, rejected_by = p_staff_id, rejection_reason = NULLIF(TRIM(p_reason), ''),
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản dự thảo'::TEXT;
END; $$;


--
-- Name: fn_drafting_doc_release(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_release(p_id bigint, p_released_by integer) RETURNS TABLE(success boolean, message text, outgoing_doc_id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_draft   edoc.drafting_docs%ROWTYPE;
  v_out_id  BIGINT;
BEGIN
  SELECT * INTO v_draft FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF v_draft.approved IS NULL OR v_draft.approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể phát hành'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF v_draft.is_released = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản đã được phát hành trước đó'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Tạo VB đi từ dự thảo
  INSERT INTO edoc.outgoing_docs (
    unit_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, expired_date,
    number_paper, number_copies, secret_id, urgent_id,
    recipients, doc_book_id, doc_type_id, doc_field_id,
    approved, approver, created_by, updated_by
  ) VALUES (
    v_draft.unit_id, v_draft.received_date, v_draft.number, v_draft.sub_number,
    v_draft.notation, v_draft.document_code, v_draft.abstract,
    v_draft.drafting_unit_id, v_draft.drafting_user_id, v_draft.publish_unit_id, v_draft.publish_date,
    v_draft.signer, v_draft.sign_date, v_draft.expired_date,
    v_draft.number_paper, v_draft.number_copies, v_draft.secret_id, v_draft.urgent_id,
    v_draft.recipients, v_draft.doc_book_id, v_draft.doc_type_id, v_draft.doc_field_id,
    TRUE, v_draft.approver, p_released_by, p_released_by
  )
  RETURNING edoc.outgoing_docs.id INTO v_out_id;

  -- Copy đính kèm từ dự thảo sang VB đi
  INSERT INTO edoc.attachment_outgoing_docs (outgoing_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by)
  SELECT v_out_id, file_name, file_path, file_size, content_type, sort_order, created_by
  FROM edoc.attachment_drafting_docs
  WHERE drafting_doc_id = p_id;

  -- Đánh dấu dự thảo đã phát hành
  UPDATE edoc.drafting_docs SET
    is_released = TRUE,
    released_date = NOW(),
    updated_by = p_released_by,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Phát hành thành công, đã tạo văn bản đi'::TEXT, v_out_id;
END;
$$;


--
-- Name: fn_drafting_doc_retract(bigint, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_retract(p_id bigint, p_staff_id integer, p_staff_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_is_released BOOLEAN;
  v_deleted_count INT;
BEGIN
  SELECT d.is_released INTO v_is_released
  FROM edoc.drafting_docs d WHERE d.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT; RETURN;
  END IF;

  IF v_is_released THEN
    RETURN QUERY SELECT FALSE, 'Không thể thu hồi — văn bản đã phát hành'::TEXT; RETURN;
  END IF;

  IF p_staff_ids IS NULL THEN
    DELETE FROM edoc.user_drafting_docs WHERE drafting_doc_id = p_id;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    UPDATE edoc.drafting_docs SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  ELSE
    DELETE FROM edoc.user_drafting_docs WHERE drafting_doc_id = p_id AND staff_id = ANY(p_staff_ids);
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    UPDATE edoc.drafting_docs SET updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  END IF;

  RETURN QUERY SELECT TRUE, ('Thu hồi thành công — đã xóa ' || v_deleted_count || ' người nhận')::TEXT;
END;
$$;


--
-- Name: fn_drafting_doc_send(bigint, integer[], integer, timestamp with time zone); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_send(p_doc_id bigint, p_staff_ids integer[], p_sent_by integer, p_expired_date timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_approved BOOLEAN;
  v_count INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;
  IF v_approved IS NULL OR v_approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể gửi'::TEXT;
    RETURN;
  END IF;

  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn ít nhất một người nhận'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, sent_by, expired_date, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), p_sent_by, p_expired_date, FALSE, NOW()
  ON CONFLICT (drafting_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;


--
-- Name: fn_drafting_doc_unapprove(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_unapprove(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;

  IF (SELECT is_released FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id) = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể hủy duyệt: văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.drafting_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt thành công'::TEXT;
END;
$$;


--
-- Name: fn_drafting_doc_update(bigint, timestamp with time zone, integer, character varying, character varying, character varying, text, integer, integer, integer, timestamp with time zone, character varying, timestamp with time zone, integer, integer, integer, smallint, smallint, integer, integer, timestamp with time zone, text, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_drafting_doc_update(p_id bigint, p_received_date timestamp with time zone, p_number integer, p_sub_number character varying, p_notation character varying, p_document_code character varying, p_abstract text, p_drafting_unit_id integer DEFAULT NULL::integer, p_drafting_user_id integer DEFAULT NULL::integer, p_publish_unit_id integer DEFAULT NULL::integer, p_publish_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_signer character varying DEFAULT NULL::character varying, p_sign_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_doc_book_id integer DEFAULT NULL::integer, p_doc_type_id integer DEFAULT NULL::integer, p_doc_field_id integer DEFAULT NULL::integer, p_secret_id smallint DEFAULT 1, p_urgent_id smallint DEFAULT 1, p_number_paper integer DEFAULT 1, p_number_copies integer DEFAULT 1, p_expired_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_recipients text DEFAULT NULL::text, p_updated_by integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_approved BOOLEAN;
  v_released BOOLEAN;
BEGIN
  SELECT approved, is_released INTO v_approved, v_released
  FROM edoc.drafting_docs WHERE edoc.drafting_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản dự thảo'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;
  IF v_released = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã phát hành'::TEXT;
    RETURN;
  END IF;

  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.drafting_docs SET
    received_date     = COALESCE(p_received_date, received_date),
    number            = COALESCE(p_number, number),
    sub_number        = NULLIF(TRIM(p_sub_number), ''),
    notation          = NULLIF(TRIM(p_notation), ''),
    document_code     = NULLIF(TRIM(p_document_code), ''),
    abstract          = TRIM(p_abstract),
    drafting_unit_id  = p_drafting_unit_id,
    drafting_user_id  = p_drafting_user_id,
    publish_unit_id   = p_publish_unit_id,
    publish_date      = p_publish_date,
    signer            = NULLIF(TRIM(p_signer), ''),
    sign_date         = p_sign_date,
    doc_book_id       = p_doc_book_id,
    doc_type_id       = p_doc_type_id,
    doc_field_id      = p_doc_field_id,
    secret_id         = COALESCE(p_secret_id, 1),
    urgent_id         = COALESCE(p_urgent_id, 1),
    number_paper      = COALESCE(p_number_paper, 1),
    number_copies     = COALESCE(p_number_copies, 1),
    expired_date      = p_expired_date,
    recipients        = NULLIF(TRIM(p_recipients), ''),
    updated_by        = p_updated_by,
    updated_at        = NOW()
  WHERE edoc.drafting_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản dự thảo thành công'::TEXT;
END;
$$;


--
-- Name: fn_email_template_create(integer, character varying, character varying, text, text, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_email_template_create(p_unit_id integer DEFAULT NULL::integer, p_name character varying DEFAULT NULL::character varying, p_subject character varying DEFAULT NULL::character varying, p_content text DEFAULT NULL::text, p_description text DEFAULT NULL::text, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu email không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu email không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu email không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;
  IF p_subject IS NOT NULL AND LENGTH(p_subject) > 500 THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề email không được vượt quá 500 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.email_templates (unit_id, name, subject, content, description, created_by)
  VALUES (v_unit_id, TRIM(p_name), TRIM(p_subject), TRIM(p_content), p_description, p_created_by)
  RETURNING email_templates.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao mau email thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_email_template_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_email_template_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.email_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu email'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.email_templates WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa mau email thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_email_template_get_list(integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_email_template_get_list(p_unit_id integer DEFAULT NULL::integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, unit_id integer, name character varying, subject character varying, content text, description text, is_active boolean, created_by integer, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT t.id, t.unit_id, t.name::VARCHAR, t.subject::VARCHAR,
         t.content, t.description, t.is_active, t.created_by, t.created_at
  FROM edoc.email_templates t
  WHERE t.unit_id = CASE WHEN p_dept_id IS NOT NULL THEN public.fn_get_ancestor_unit(p_dept_id)
                         ELSE p_unit_id END
  ORDER BY t.name;
$$;


--
-- Name: fn_email_template_update(integer, character varying, character varying, text, text, boolean); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_email_template_update(p_id integer, p_name character varying DEFAULT NULL::character varying, p_subject character varying DEFAULT NULL::character varying, p_content text DEFAULT NULL::text, p_description text DEFAULT NULL::text, p_is_active boolean DEFAULT NULL::boolean) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.email_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu email'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu email không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu email không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.email_templates SET
    name        = TRIM(p_name),
    subject     = COALESCE(TRIM(p_subject), subject),
    content     = TRIM(p_content),
    description = COALESCE(p_description, description),
    is_active   = COALESCE(p_is_active, is_active)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat mau email thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_approve(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_approve(p_id bigint, p_approved_by integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- T-02-01: validate current status before transition
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 2 THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được duyệt khi hồ sơ ở trạng thái Chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status     = 3,  -- Đã duyệt
    updated_by = p_approved_by,
    updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Duyệt hồ sơ công việc thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_assign_staff(bigint, integer[], smallint, timestamp with time zone, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_assign_staff(p_doc_id bigint, p_staff_ids integer[], p_role_type smallint, p_deadline timestamp with time zone, p_assigned_by integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_staff_id INT;
BEGIN
  IF p_staff_ids IS NULL OR ARRAY_LENGTH(p_staff_ids, 1) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Danh sách cán bộ không được để trống'::TEXT;
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM edoc.handling_docs WHERE id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  FOREACH v_staff_id IN ARRAY p_staff_ids LOOP
    INSERT INTO edoc.staff_handling_docs (handling_doc_id, staff_id, role, assigned_at)
    VALUES (p_doc_id, v_staff_id, COALESCE(p_role_type, 1), NOW())
    ON CONFLICT DO NOTHING;
  END LOOP;

  RETURN QUERY SELECT TRUE, 'Phân công cán bộ thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_change_status(bigint, smallint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_change_status(p_id bigint, p_new_status smallint, p_changed_by integer, p_reason text DEFAULT NULL::text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_status SMALLINT;
BEGIN
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status     = p_new_status,
    updated_by = p_changed_by,
    updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật trạng thái thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_complete(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_complete(p_id bigint, p_completed_by integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- T-02-01: validate current status before transition
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 3 THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được hoàn thành khi hồ sơ ở trạng thái Đã duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status           = 4,  -- Hoàn thành
    complete_user_id = p_completed_by,
    complete_date    = NOW(),
    progress         = 100,
    updated_by       = p_completed_by,
    updated_at       = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Hoàn thành hồ sơ công việc thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_count_by_status(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_count_by_status(p_unit_id integer, p_staff_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(filter_type text, count bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT 'all'::TEXT,               COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
  UNION ALL
  SELECT 'created_by_me'::TEXT,     COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND created_by = p_staff_id
  UNION ALL
  SELECT 'rejected'::TEXT,          COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = -1 AND created_by = p_staff_id
  UNION ALL
  SELECT 'returned'::TEXT,          COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = -2
  UNION ALL
  SELECT 'pending_primary'::TEXT,   COUNT(*)::BIGINT
    FROM edoc.handling_docs h
    WHERE (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids)) AND h.status = 0
      AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 1)
  UNION ALL
  SELECT 'pending_coord'::TEXT,     COUNT(*)::BIGINT
    FROM edoc.handling_docs h
    WHERE (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids)) AND h.status IN (0, 1)
      AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 2)
  UNION ALL
  SELECT 'submitting'::TEXT,        COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 2
  UNION ALL
  SELECT 'in_progress'::TEXT,       COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 1
  UNION ALL
  SELECT 'proposed_complete'::TEXT, COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 3
  UNION ALL
  SELECT 'completed'::TEXT,         COUNT(*)::BIGINT FROM edoc.handling_docs WHERE (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids)) AND status = 4;
END; $$;


--
-- Name: fn_handling_doc_create(integer, integer, integer, integer, character varying, text, timestamp with time zone, timestamp with time zone, integer, integer, integer, boolean, bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_create(p_unit_id integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer, p_doc_type_id integer DEFAULT NULL::integer, p_doc_field_id integer DEFAULT NULL::integer, p_name character varying DEFAULT NULL::character varying, p_comments text DEFAULT NULL::text, p_start_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_end_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_curator_id integer DEFAULT NULL::integer, p_signer_id integer DEFAULT NULL::integer, p_workflow_id integer DEFAULT NULL::integer, p_is_from_doc boolean DEFAULT NULL::boolean, p_parent_id bigint DEFAULT NULL::bigint, p_created_by integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên hồ sơ công việc không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_end_date < p_start_date THEN
    RETURN QUERY SELECT FALSE, 'Hạn giải quyết phải sau hoặc bằng ngày mở'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.handling_docs (
    unit_id, department_id, doc_type_id, doc_field_id, name, comments,
    start_date, end_date, curator, signer, workflow_id, is_from_doc,
    parent_id, created_by, updated_by
  ) VALUES (
    v_unit_id, p_department_id, p_doc_type_id, p_doc_field_id,
    TRIM(p_name), NULLIF(TRIM(COALESCE(p_comments, '')), ''),
    COALESCE(p_start_date, NOW()), p_end_date, p_curator_id, p_signer_id,
    p_workflow_id, COALESCE(p_is_from_doc, FALSE), p_parent_id,
    p_created_by, p_created_by
  )
  RETURNING edoc.handling_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo hồ sơ công việc thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_handling_doc_create_from_doc(bigint, character varying, text, date, date, integer[], text, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_create_from_doc(p_doc_id bigint, p_doc_type character varying, p_name text, p_start_date date, p_end_date date, p_curator_ids integer[], p_note text, p_created_by integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id      BIGINT;
  v_unit_id INT;
  v_curator_id INT;
  v_cid     INT;
BEGIN
  -- Lấy unit_id từ văn bản gốc
  IF p_doc_type = 'incoming' THEN
    SELECT ind.unit_id INTO v_unit_id FROM edoc.incoming_docs ind WHERE ind.id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    SELECT od.unit_id INTO v_unit_id FROM edoc.outgoing_docs od WHERE od.id = p_doc_id;
  ELSIF p_doc_type = 'drafting' THEN
    SELECT dd.unit_id INTO v_unit_id FROM edoc.drafting_docs dd WHERE dd.id = p_doc_id;
  END IF;

  IF v_unit_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản nguồn'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Lấy người phụ trách đầu tiên (primary curator)
  IF p_curator_ids IS NOT NULL AND array_length(p_curator_ids, 1) > 0 THEN
    v_curator_id := p_curator_ids[1];
  END IF;

  -- Tạo hồ sơ công việc
  INSERT INTO edoc.handling_docs (
    unit_id, name, comments, start_date, end_date,
    curator, status, is_from_doc, created_by, created_at, updated_at
  ) VALUES (
    v_unit_id, p_name, p_note, p_start_date, p_end_date,
    v_curator_id, 0, TRUE, p_created_by, NOW(), NOW()
  )
  RETURNING edoc.handling_docs.id INTO v_id;

  -- Liên kết văn bản với HSCV
  INSERT INTO edoc.handling_doc_links (handling_doc_id, doc_type, doc_id)
  VALUES (v_id, p_doc_type, p_doc_id)
  ON CONFLICT DO NOTHING;

  -- Thêm các người phụ trách vào staff_handling_docs
  IF p_curator_ids IS NOT NULL THEN
    FOREACH v_cid IN ARRAY p_curator_ids LOOP
      INSERT INTO edoc.staff_handling_docs (handling_doc_id, staff_id, role, assigned_at)
      VALUES (v_id, v_cid, 1, NOW())
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;

  RETURN QUERY SELECT TRUE, 'Tạo hồ sơ công việc thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_handling_doc_delete(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_delete(p_id bigint) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_status SMALLINT;
BEGIN
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Chỉ xóa khi trạng thái = 0 (Mới) — T-02-02 threat mitigation
  IF v_status <> 0 THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được xóa hồ sơ công việc ở trạng thái Mới'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.handling_docs WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa hồ sơ công việc thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_get_attachments(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_get_attachments(p_doc_id bigint) RETURNS TABLE(id bigint, file_name character varying, file_path character varying, file_size bigint, content_type character varying, sort_order integer, created_by integer, created_by_name text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id,
    a.file_name,
    a.file_path,
    a.file_size,
    a.content_type,
    a.sort_order,
    a.created_by,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT AS created_by_name,
    a.created_at
  FROM edoc.attachment_handling_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.handling_doc_id = p_doc_id
  ORDER BY a.sort_order, a.created_at;
END;
$$;


--
-- Name: fn_handling_doc_get_by_id(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_get_by_id(p_id bigint) RETURNS TABLE(id bigint, unit_id integer, unit_name character varying, department_id integer, department_name character varying, name character varying, abstract text, comments text, doc_notation character varying, doc_type_id integer, doc_type_name character varying, doc_field_id integer, doc_field_name character varying, start_date timestamp with time zone, end_date timestamp with time zone, curator_id integer, curator_name text, signer_id integer, signer_name text, status smallint, progress smallint, workflow_id integer, workflow_name character varying, parent_id bigint, parent_name character varying, is_from_doc boolean, created_by integer, created_at timestamp with time zone, updated_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    h.id,
    h.unit_id,
    du.name                                 AS unit_name,
    h.department_id,
    dd.name                                 AS department_name,
    h.name,
    h.abstract,
    h.comments,
    h.doc_notation,
    h.doc_type_id,
    dt.name                                 AS doc_type_name,
    h.doc_field_id,
    df.name                                 AS doc_field_name,
    h.start_date,
    h.end_date,
    h.curator                               AS curator_id,
    CONCAT(sc.last_name, ' ', sc.first_name) AS curator_name,
    h.signer                                AS signer_id,
    CONCAT(ss.last_name, ' ', ss.first_name) AS signer_name,
    h.status,
    h.progress,
    h.workflow_id,
    NULL::VARCHAR                           AS workflow_name,
    h.parent_id,
    hp.name                                 AS parent_name,
    h.is_from_doc,
    h.created_by,
    h.created_at,
    h.updated_at
  FROM edoc.handling_docs h
  LEFT JOIN public.departments du ON du.id = h.unit_id
  LEFT JOIN public.departments dd ON dd.id = h.department_id
  LEFT JOIN edoc.doc_types dt ON dt.id = h.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = h.doc_field_id
  LEFT JOIN public.staff sc ON sc.id = h.curator
  LEFT JOIN public.staff ss ON ss.id = h.signer
  LEFT JOIN edoc.handling_docs hp ON hp.id = h.parent_id
  WHERE h.id = p_id;
END;
$$;


--
-- Name: fn_handling_doc_get_children(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_get_children(p_id bigint) RETURNS TABLE(id bigint, name character varying, start_date timestamp with time zone, end_date timestamp with time zone, status smallint, curator_id integer, curator_name text, signer_id integer, signer_name text, progress smallint, doc_field_name character varying, doc_type_name character varying, created_at timestamp with time zone, total_count bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    h.id,
    h.name,
    h.start_date,
    h.end_date,
    h.status,
    h.curator                                  AS curator_id,
    CONCAT(sc.last_name, ' ', sc.first_name)   AS curator_name,
    h.signer                                   AS signer_id,
    CONCAT(ss.last_name, ' ', ss.first_name)   AS signer_name,
    h.progress,
    df.name                                    AS doc_field_name,
    dt.name                                    AS doc_type_name,
    h.created_at,
    COUNT(*) OVER()::BIGINT                    AS total_count
  FROM edoc.handling_docs h
  LEFT JOIN public.staff sc ON sc.id = h.curator
  LEFT JOIN public.staff ss ON ss.id = h.signer
  LEFT JOIN edoc.doc_fields df ON df.id = h.doc_field_id
  LEFT JOIN edoc.doc_types dt ON dt.id = h.doc_type_id
  WHERE h.parent_id = p_id
  ORDER BY h.created_at DESC;
END;
$$;


--
-- Name: fn_handling_doc_get_for_link(integer, text, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_get_for_link(p_unit_id integer, p_keyword text DEFAULT NULL::text, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, name character varying, abstract text, status smallint, start_date timestamp with time zone, end_date timestamp with time zone, curator_name character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE v_kw TEXT := NULLIF(TRIM(p_keyword), '');
BEGIN
  RETURN QUERY
  SELECT h.id, h.name::VARCHAR, h.abstract, h.status, h.start_date, h.end_date,
         s.full_name
  FROM edoc.handling_docs h
  LEFT JOIN public.staff s ON s.id = h.curator
  WHERE h.unit_id = p_unit_id
    AND (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids))
    AND h.status < 3
    AND (v_kw IS NULL OR h.name ILIKE '%' || v_kw || '%' OR h.abstract ILIKE '%' || v_kw || '%')
  ORDER BY h.created_at DESC
  LIMIT 50;
END;
$$;


--
-- Name: fn_handling_doc_get_linked_docs(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_get_linked_docs(p_id bigint) RETURNS TABLE(link_id bigint, doc_id bigint, doc_type character varying, doc_number integer, doc_notation character varying, doc_abstract text, doc_date timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    l.id       AS link_id,
    l.doc_id,
    l.doc_type,
    CASE l.doc_type
      WHEN 'incoming' THEN (SELECT d.number FROM edoc.incoming_docs d WHERE d.id = l.doc_id)
      ELSE NULL
    END        AS doc_number,
    CASE l.doc_type
      WHEN 'incoming' THEN (SELECT d.notation FROM edoc.incoming_docs d WHERE d.id = l.doc_id)
      ELSE NULL
    END        AS doc_notation,
    CASE l.doc_type
      WHEN 'incoming' THEN (SELECT d.abstract FROM edoc.incoming_docs d WHERE d.id = l.doc_id)
      ELSE NULL
    END        AS doc_abstract,
    CASE l.doc_type
      WHEN 'incoming' THEN (SELECT d.received_date FROM edoc.incoming_docs d WHERE d.id = l.doc_id)
      ELSE NULL
    END        AS doc_date
  FROM edoc.handling_doc_links l
  WHERE l.handling_doc_id = p_id
  ORDER BY l.created_at DESC;
END;
$$;


--
-- Name: fn_handling_doc_get_list(integer, integer[], integer, integer, text, text, timestamp with time zone, timestamp with time zone, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_get_list(p_unit_id integer, p_dept_ids integer[] DEFAULT NULL::integer[], p_staff_id integer DEFAULT NULL::integer, p_status integer DEFAULT NULL::integer, p_filter_type text DEFAULT NULL::text, p_keyword text DEFAULT NULL::text, p_from_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_to_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20) RETURNS TABLE(id bigint, name character varying, start_date timestamp with time zone, end_date timestamp with time zone, status smallint, curator_id integer, curator_name text, signer_id integer, signer_name text, progress smallint, doc_field_name character varying, doc_type_name character varying, created_at timestamp with time zone, total_count bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT h.id, h.name, h.start_date, h.end_date, h.status,
      h.curator AS curator_id, CONCAT(sc.last_name, ' ', sc.first_name) AS curator_name,
      h.signer AS signer_id, CONCAT(ss.last_name, ' ', ss.first_name) AS signer_name,
      h.progress, df.name AS doc_field_name, dt.name AS doc_type_name, h.created_at
    FROM edoc.handling_docs h
    LEFT JOIN public.staff sc ON sc.id = h.curator LEFT JOIN public.staff ss ON ss.id = h.signer
    LEFT JOIN edoc.doc_fields df ON df.id = h.doc_field_id LEFT JOIN edoc.doc_types dt ON dt.id = h.doc_type_id
    WHERE (p_dept_ids IS NULL OR h.department_id = ANY(p_dept_ids))
      AND (p_status IS NULL OR p_status = -99 OR h.status = p_status)
      AND (p_filter_type IS NULL OR p_filter_type = 'all' OR
        (p_filter_type = 'created_by_me' AND h.created_by = p_staff_id) OR
        (p_filter_type = 'rejected' AND h.status = -1 AND h.created_by = p_staff_id) OR
        (p_filter_type = 'returned' AND h.status = -2) OR
        (p_filter_type = 'pending_primary' AND h.status = 0 AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 1)) OR
        (p_filter_type = 'pending_coord' AND h.status IN (0, 1) AND EXISTS (SELECT 1 FROM edoc.staff_handling_docs shd WHERE shd.handling_doc_id = h.id AND shd.staff_id = p_staff_id AND shd.role = 2)) OR
        (p_filter_type = 'submitting' AND h.status = 2) OR (p_filter_type = 'in_progress' AND h.status = 1) OR
        (p_filter_type = 'proposed_complete' AND h.status = 3) OR (p_filter_type = 'completed' AND h.status = 4))
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR h.name ILIKE '%' || p_keyword || '%')
      AND (p_from_date IS NULL OR h.start_date >= p_from_date)
      AND (p_to_date IS NULL OR h.start_date <= p_to_date)
  )
  SELECT f.id, f.name, f.start_date, f.end_date, f.status,
    f.curator_id, f.curator_name::TEXT, f.signer_id, f.signer_name::TEXT,
    f.progress, f.doc_field_name, f.doc_type_name, f.created_at,
    COUNT(*) OVER() AS total_count
  FROM filtered f ORDER BY f.created_at DESC LIMIT p_page_size OFFSET v_offset;
END; $$;


--
-- Name: fn_handling_doc_get_staff(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_get_staff(p_doc_id bigint) RETURNS TABLE(id bigint, staff_id integer, staff_name text, position_name character varying, department_name character varying, role smallint, step character varying, assigned_at timestamp with time zone, completed_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    shd.id,
    shd.staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
    p.name                                        AS position_name,
    d.name                                        AS department_name,
    shd.role,
    shd.step,
    shd.assigned_at,
    shd.completed_at
  FROM edoc.staff_handling_docs shd
  JOIN public.staff s ON s.id = shd.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE shd.handling_doc_id = p_doc_id
  ORDER BY shd.role, shd.assigned_at;
END;
$$;


--
-- Name: fn_handling_doc_kpi(integer, timestamp with time zone, timestamp with time zone, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_kpi(p_unit_id integer, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(total bigint, prev_period bigint, current_period bigint, completed bigint, in_progress bigint, overdue bigint, overdue_percent numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_total BIGINT; v_prev BIGINT; v_current BIGINT;
  v_completed BIGINT; v_in_progress BIGINT; v_overdue BIGINT; v_percent NUMERIC;
BEGIN
  SELECT COUNT(*) INTO v_total FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids));

  SELECT COUNT(*) INTO v_prev FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    AND created_at < p_from_date AND status NOT IN (4, -1);

  SELECT COUNT(*) INTO v_current FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    AND (p_from_date IS NULL OR created_at >= p_from_date)
    AND (p_to_date IS NULL OR created_at <= p_to_date);

  SELECT COUNT(*) INTO v_completed FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    AND status = 4
    AND (p_from_date IS NULL OR complete_date >= p_from_date)
    AND (p_to_date IS NULL OR complete_date <= p_to_date);

  SELECT COUNT(*) INTO v_in_progress FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    AND status IN (0, 1, 2, 3)
    AND (p_from_date IS NULL OR created_at >= p_from_date)
    AND (p_to_date IS NULL OR created_at <= p_to_date);

  SELECT COUNT(*) INTO v_overdue FROM edoc.handling_docs
  WHERE unit_id = p_unit_id AND (p_dept_ids IS NULL OR department_id = ANY(p_dept_ids))
    AND end_date < NOW() AND status NOT IN (4, -1)
    AND (p_from_date IS NULL OR created_at >= p_from_date)
    AND (p_to_date IS NULL OR created_at <= p_to_date);

  IF v_current > 0 THEN v_percent := ROUND((v_overdue::NUMERIC / v_current::NUMERIC) * 100, 2);
  ELSE v_percent := 0; END IF;

  RETURN QUERY SELECT v_total, v_prev, v_current, v_completed, v_in_progress, v_overdue, v_percent;
END;
$$;


--
-- Name: fn_handling_doc_link_doc(bigint, bigint, character varying, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_link_doc(p_handling_doc_id bigint, p_doc_id bigint, p_doc_type character varying, p_linked_by integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_doc_type NOT IN ('incoming', 'outgoing', 'drafting') THEN
    RETURN QUERY SELECT FALSE, 'Loại văn bản không hợp lệ'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF EXISTS (
    SELECT 1 FROM edoc.handling_doc_links
    WHERE handling_doc_id = p_handling_doc_id AND doc_id = p_doc_id AND doc_type = p_doc_type
  ) THEN
    RETURN QUERY SELECT FALSE, 'Văn bản này đã được liên kết'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.handling_doc_links (handling_doc_id, doc_type, doc_id)
  VALUES (p_handling_doc_id, p_doc_type, p_doc_id)
  RETURNING edoc.handling_doc_links.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Liên kết văn bản thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_handling_doc_reject(bigint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_reject(p_id bigint, p_rejected_by integer, p_reason text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- T-02-01: validate current status before transition
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RETURN QUERY SELECT FALSE, 'Lý do từ chối không được để trống'::TEXT;
    RETURN;
  END IF;

  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 2 THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được từ chối khi hồ sơ ở trạng thái Chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status     = -1,  -- Từ chối
    comments   = COALESCE(comments, '') || E'\n[Từ chối] ' || TRIM(p_reason),
    updated_by = p_rejected_by,
    updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Từ chối hồ sơ công việc thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_remove_staff(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_remove_staff(p_doc_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM edoc.staff_handling_docs
  WHERE handling_doc_id = p_doc_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Cán bộ không có trong danh sách xử lý'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Hủy phân công thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_return(bigint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_return(p_id bigint, p_returned_by integer, p_reason text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- T-02-01: validate current status before transition
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RETURN QUERY SELECT FALSE, 'Lý do trả về không được để trống'::TEXT;
    RETURN;
  END IF;

  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_status NOT IN (1, 2) THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được trả về khi hồ sơ ở trạng thái Đang xử lý hoặc Chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status     = -2,  -- Trả về
    comments   = COALESCE(comments, '') || E'\n[Trả về] ' || TRIM(p_reason),
    updated_by = p_returned_by,
    updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Trả về hồ sơ công việc thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_submit(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_submit(p_id bigint, p_submitted_by integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- T-02-01: validate current status before transition
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF v_status NOT IN (0, 1) THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được trình ký khi hồ sơ ở trạng thái Mới hoặc Đang xử lý'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    status     = 2,  -- Chờ duyệt
    updated_by = p_submitted_by,
    updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Trình ký thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_unlink_doc(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_unlink_doc(p_link_id bigint) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM edoc.handling_doc_links WHERE id = p_link_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Liên kết không tồn tại'::TEXT;
    RETURN;
  END IF;
  RETURN QUERY SELECT TRUE, 'Hủy liên kết thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_update(bigint, integer, integer, character varying, text, timestamp with time zone, timestamp with time zone, integer, integer, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_update(p_id bigint, p_doc_type_id integer, p_doc_field_id integer, p_name character varying, p_comments text, p_start_date timestamp with time zone, p_end_date timestamp with time zone, p_curator_id integer, p_signer_id integer, p_workflow_id integer, p_updated_by integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_status SMALLINT;
BEGIN
  -- Validate: tên bắt buộc
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên hồ sơ công việc không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Validate: hạn giải quyết >= ngày mở
  IF p_start_date IS NOT NULL AND p_end_date IS NOT NULL AND p_end_date < p_start_date THEN
    RETURN QUERY SELECT FALSE, 'Hạn giải quyết phải sau hoặc bằng ngày mở'::TEXT;
    RETURN;
  END IF;

  -- Kiểm tra tồn tại và trạng thái
  SELECT status INTO v_status FROM edoc.handling_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Chỉ cập nhật khi trạng thái = 0 (Mới)
  IF v_status <> 0 THEN
    RETURN QUERY SELECT FALSE, 'Chỉ được cập nhật hồ sơ công việc ở trạng thái Mới'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    doc_type_id  = p_doc_type_id,
    doc_field_id = p_doc_field_id,
    name         = TRIM(p_name),
    comments     = NULLIF(TRIM(COALESCE(p_comments, '')), ''),
    start_date   = p_start_date,
    end_date     = p_end_date,
    curator      = p_curator_id,
    signer       = p_signer_id,
    workflow_id  = p_workflow_id,
    updated_by   = p_updated_by,
    updated_at   = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật hồ sơ công việc thành công'::TEXT;
END;
$$;


--
-- Name: fn_handling_doc_update_progress(bigint, smallint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_handling_doc_update_progress(p_id bigint, p_progress smallint) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- T-02-04: validate progress range 0-100
  IF p_progress < 0 OR p_progress > 100 THEN
    RETURN QUERY SELECT FALSE, 'Tiến độ phải trong khoảng 0-100%'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.handling_docs SET
    progress   = p_progress,
    updated_at = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Cập nhật tiến độ thành công'::TEXT;
END;
$$;


--
-- Name: fn_incoming_doc_approve(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_approve(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_name TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT; RETURN;
  END IF;
  SELECT full_name INTO v_name FROM public.staff WHERE id = p_staff_id;
  UPDATE edoc.incoming_docs
  SET approved = TRUE, approver = v_name, rejected_by = NULL, rejection_reason = NULL,
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Duyệt văn bản đến thành công'::TEXT;
END; $$;


--
-- Name: fn_incoming_doc_cancel_approve(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_cancel_approve(p_doc_id bigint, p_cancelled_by integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_approved BOOLEAN;
BEGIN
  -- Kiểm tra văn bản tồn tại và đã được duyệt
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT;
    RETURN;
  END IF;

  IF NOT COALESCE(v_approved, FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể hủy duyệt'::TEXT;
    RETURN;
  END IF;

  -- Hủy duyệt
  UPDATE edoc.incoming_docs
  SET
    approved = FALSE,
    updated_by = p_cancelled_by,
    updated_at = NOW()
  WHERE id = p_doc_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt văn bản thành công'::TEXT;
END;
$$;


--
-- Name: fn_incoming_doc_count_unread(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_count_unread(p_unit_id integer, p_staff_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.incoming_docs d
  LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
    AND (uid.is_read IS NULL OR uid.is_read = FALSE);
  RETURN v_count;
END; $$;


--
-- Name: fn_incoming_doc_create(integer, timestamp with time zone, integer, character varying, character varying, text, character varying, timestamp with time zone, character varying, timestamp with time zone, integer, integer, integer, smallint, smallint, integer, integer, timestamp with time zone, text, boolean, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_create(p_unit_id integer, p_received_date timestamp with time zone, p_number integer, p_notation character varying, p_document_code character varying, p_abstract text, p_publish_unit character varying, p_publish_date timestamp with time zone, p_signer character varying, p_sign_date timestamp with time zone, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_secret_id smallint DEFAULT 1, p_urgent_id smallint DEFAULT 1, p_number_paper integer DEFAULT 1, p_number_copies integer DEFAULT 1, p_expired_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_recipients text DEFAULT NULL::text, p_is_received_paper boolean DEFAULT false, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_number IS NULL OR p_number = 0 THEN
    p_number := edoc.fn_incoming_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  -- Resolve department_id from created_by if not provided
  IF p_department_id IS NULL AND p_created_by IS NOT NULL THEN
    SELECT s.department_id INTO p_department_id FROM public.staff s WHERE s.id = p_created_by;
  END IF;

  INSERT INTO edoc.incoming_docs (
    unit_id, department_id, received_date, number, notation, document_code,
    abstract, publish_unit, publish_date, signer, sign_date,
    doc_book_id, doc_type_id, doc_field_id, secret_id, urgent_id,
    number_paper, number_copies, expired_date, recipients,
    is_received_paper, created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_department_id, p_unit_id), COALESCE(p_received_date, NOW()), p_number,
    NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), NULLIF(TRIM(p_publish_unit), ''), p_publish_date,
    NULLIF(TRIM(p_signer), ''), p_sign_date,
    p_doc_book_id, p_doc_type_id, p_doc_field_id, COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1), p_expired_date,
    NULLIF(TRIM(p_recipients), ''),
    COALESCE(p_is_received_paper, FALSE), p_created_by, p_created_by
  )
  RETURNING edoc.incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản đến thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_incoming_doc_delete(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_delete(p_id bigint) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  -- CASCADE sẽ xóa user_incoming_docs, attachments, leader_notes
  DELETE FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa văn bản đến thành công'::TEXT;
END;
$$;


--
-- Name: fn_incoming_doc_get_by_id(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_get_by_id(p_id bigint, p_staff_id integer) RETURNS TABLE(id bigint, unit_id integer, received_date timestamp with time zone, number integer, notation character varying, document_code character varying, abstract text, publish_unit character varying, publish_date timestamp with time zone, signer character varying, sign_date timestamp with time zone, doc_book_id integer, doc_type_id integer, doc_field_id integer, secret_id smallint, urgent_id smallint, number_paper integer, number_copies integer, expired_date timestamp with time zone, recipients text, sents text, approver character varying, approved boolean, is_handling boolean, is_received_paper boolean, received_paper_date timestamp with time zone, archive_status boolean, is_inter_doc boolean, inter_doc_id integer, created_by integer, created_at timestamp with time zone, updated_by integer, updated_at timestamp with time zone, doc_book_name character varying, doc_type_name character varying, doc_type_code character varying, doc_field_name character varying, created_by_name character varying, is_read boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Đánh dấu đã đọc
  PERFORM edoc.fn_incoming_doc_mark_read(p_id, p_staff_id);

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.notation, d.document_code,
    d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
    d.doc_book_id, d.doc_type_id, d.doc_field_id, d.secret_id, d.urgent_id,
    d.number_paper, d.number_copies, d.expired_date, d.recipients,
    d.sents,                                    -- MỚI
    d.approver, d.approved, d.is_handling, d.is_received_paper,
    d.received_paper_date,                      -- MỚI
    d.archive_status,
    d.is_inter_doc,                             -- MỚI
    d.inter_doc_id,                             -- MỚI
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name, s.full_name,
    TRUE  -- đã mark read ở trên
  FROM edoc.incoming_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;


--
-- Name: fn_incoming_doc_get_history(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_get_history(p_doc_id bigint) RETURNS TABLE(event_type character varying, event_time timestamp with time zone, staff_name character varying, content text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM (
    -- Tạo VB
    SELECT 'created'::VARCHAR AS evt, d.created_at AS etime, s.full_name AS sname, ('Tạo văn bản đến, số đến: ' || d.number)::TEXT AS econtent
    FROM edoc.incoming_docs d
    JOIN public.staff s ON s.id = d.created_by
    WHERE d.id = p_doc_id

    UNION ALL
    -- Duyệt
    SELECT 'approved'::VARCHAR, d.updated_at, d.approver::VARCHAR, 'Duyệt văn bản'::TEXT
    FROM edoc.incoming_docs d
    WHERE d.id = p_doc_id AND d.approved = TRUE

    UNION ALL
    -- Gửi cho cán bộ
    SELECT 'sent'::VARCHAR, uid.created_at, s.full_name, ('Nhận văn bản')::TEXT
    FROM edoc.user_incoming_docs uid
    JOIN public.staff s ON s.id = uid.staff_id
    WHERE uid.incoming_doc_id = p_doc_id

    UNION ALL
    -- Bút phê
    SELECT 'leader_note'::VARCHAR, ln.created_at, s.full_name, ln.content
    FROM edoc.leader_notes ln
    JOIN public.staff s ON s.id = ln.staff_id
    WHERE ln.incoming_doc_id = p_doc_id
  ) sub
  ORDER BY sub.etime DESC;
END;
$$;


--
-- Name: fn_incoming_doc_get_list(integer, integer, integer, integer, integer, smallint, boolean, boolean, timestamp with time zone, timestamp with time zone, text, text, integer, integer, integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_get_list(p_unit_id integer, p_staff_id integer, p_doc_book_id integer DEFAULT NULL::integer, p_doc_type_id integer DEFAULT NULL::integer, p_doc_field_id integer DEFAULT NULL::integer, p_urgent_id smallint DEFAULT NULL::smallint, p_is_read boolean DEFAULT NULL::boolean, p_approved boolean DEFAULT NULL::boolean, p_from_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_to_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_keyword text DEFAULT NULL::text, p_signer text DEFAULT NULL::text, p_from_number integer DEFAULT NULL::integer, p_to_number integer DEFAULT NULL::integer, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, unit_id integer, received_date timestamp with time zone, number integer, notation character varying, document_code character varying, abstract text, publish_unit character varying, publish_date timestamp with time zone, signer character varying, sign_date timestamp with time zone, doc_book_id integer, doc_type_id integer, doc_field_id integer, secret_id smallint, urgent_id smallint, number_paper integer, number_copies integer, expired_date timestamp with time zone, recipients text, sents text, approver character varying, approved boolean, is_handling boolean, is_received_paper boolean, archive_status boolean, created_by integer, created_at timestamp with time zone, doc_book_name character varying, doc_type_name character varying, doc_type_code character varying, doc_field_name character varying, created_by_name character varying, is_read boolean, read_at timestamp with time zone, attachment_count bigint, total_count bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_offset INT; v_keyword TEXT; v_signer TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  v_signer := NULLIF(TRIM(p_signer), '');
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id AS doc_id, d.*,
      db.name AS _doc_book_name, dt.name AS _doc_type_name, dt.code AS _doc_type_code,
      df.name AS _doc_field_name, s.full_name AS _created_by_name,
      uid.is_read AS _is_read, uid.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_incoming_docs a WHERE a.incoming_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.incoming_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
    LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
    LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_incoming_docs uid ON uid.incoming_doc_id = d.id AND uid.staff_id = p_staff_id
    WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (p_is_read IS NULL OR (p_is_read = TRUE AND uid.is_read = TRUE) OR (p_is_read = FALSE AND (uid.is_read IS NULL OR uid.is_read = FALSE)))
      AND (v_signer IS NULL OR d.signer ILIKE '%' || v_signer || '%')
      AND (p_from_number IS NULL OR d.number >= p_from_number)
      AND (p_to_number IS NULL OR d.number <= p_to_number)
      AND (v_keyword IS NULL OR d.abstract ILIKE '%' || v_keyword || '%' OR d.notation ILIKE '%' || v_keyword || '%' OR d.publish_unit ILIKE '%' || v_keyword || '%' OR d.signer ILIKE '%' || v_keyword || '%' OR d.document_code ILIKE '%' || v_keyword || '%')
    ORDER BY d.received_date DESC, d.number DESC LIMIT p_page_size OFFSET v_offset
  )
  SELECT f.doc_id, f.unit_id, f.received_date, f.number, f.notation, f.document_code, f.abstract,
    f.publish_unit, f.publish_date, f.signer, f.sign_date, f.doc_book_id, f.doc_type_id, f.doc_field_id,
    f.secret_id, f.urgent_id, f.number_paper, f.number_copies, f.expired_date, f.recipients, f.sents,
    f.approver, f.approved, f.is_handling, f.is_received_paper, f.archive_status,
    f.created_by, f.created_at, f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._created_by_name, COALESCE(f._is_read, FALSE), f._read_at, f._attachment_count, f._total_count
  FROM filtered f;
END; $$;


--
-- Name: fn_incoming_doc_get_next_number(integer, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_get_next_number(p_doc_book_id integer, p_unit_id integer DEFAULT NULL::integer, p_dept_id integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_max INT; v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.incoming_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = v_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;


--
-- Name: fn_incoming_doc_get_recipients(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_get_recipients(p_doc_id bigint) RETURNS TABLE(id bigint, staff_id integer, staff_name character varying, position_name character varying, department_name character varying, is_read boolean, read_at timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    uid.id, uid.staff_id,
    s.full_name,
    p.name AS position_name,
    dep.name AS department_name,
    uid.is_read, uid.read_at, uid.created_at
  FROM edoc.user_incoming_docs uid
  JOIN public.staff s ON s.id = uid.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  WHERE uid.incoming_doc_id = p_doc_id
  ORDER BY uid.created_at DESC;
END;
$$;


--
-- Name: fn_incoming_doc_get_sendable_staff(integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_get_sendable_staff(p_unit_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(staff_id integer, full_name character varying, position_name character varying, department_id integer, department_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT s.id, s.full_name, p.name, s.department_id, d.name
  FROM public.staff s
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE (
    p_dept_ids IS NOT NULL AND s.department_id = ANY(p_dept_ids)
    OR p_dept_ids IS NULL AND s.department_id IN (
      SELECT dep.id FROM public.departments dep
      WHERE dep.id = p_unit_id OR dep.parent_id = p_unit_id
    )
  )
  AND s.is_locked = FALSE AND s.is_deleted = FALSE
  ORDER BY d.sort_order, d.name, s.full_name;
END;
$$;


--
-- Name: fn_incoming_doc_handover(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_handover(p_doc_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count INT;
BEGIN
  -- Kiểm tra văn bản tồn tại
  SELECT COUNT(*) INTO v_count FROM edoc.incoming_docs WHERE id = p_doc_id;
  IF v_count = 0 THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT;
    RETURN;
  END IF;

  -- Đánh dấu nhân viên đã nhận bàn giao (ghi nhận user nhận VB)
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at)
  VALUES (p_doc_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (incoming_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = NOW();

  RETURN QUERY SELECT TRUE, 'Nhận bàn giao thành công'::TEXT;
END;
$$;


--
-- Name: fn_incoming_doc_mark_read(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_mark_read(p_doc_id bigint, p_staff_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at)
  VALUES (p_doc_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (incoming_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_incoming_docs.read_at, NOW());
END;
$$;


--
-- Name: fn_incoming_doc_mark_read_bulk(bigint[], integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_mark_read_bulk(p_doc_ids bigint[], p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, read_at)
  SELECT unnest(p_doc_ids), p_staff_id, TRUE, NOW()
  ON CONFLICT (incoming_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_incoming_docs.read_at, NOW());

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu đọc thành công'::TEXT;
END;
$$;


--
-- Name: fn_incoming_doc_receive_paper(bigint, integer, timestamp with time zone); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_receive_paper(p_id bigint, p_staff_id integer, p_received_paper_date timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE edoc.incoming_docs SET
    is_received_paper = TRUE,
    received_paper_date = COALESCE(p_received_paper_date, NOW()),  -- MỚI
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Đã xác nhận nhận bản giấy'::TEXT;
END;
$$;


--
-- Name: fn_incoming_doc_retract(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_retract(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_deleted_count INT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT; RETURN;
  END IF;

  DELETE FROM edoc.user_incoming_docs
  WHERE incoming_doc_id = p_id AND staff_id != p_staff_id;
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;

  UPDATE edoc.incoming_docs
  SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, ('Thu hồi thành công — đã xóa ' || v_deleted_count || ' người nhận')::TEXT;
END;
$$;


--
-- Name: fn_incoming_doc_return(bigint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_return(p_doc_id bigint, p_returned_by integer, p_reason text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count INT;
BEGIN
  -- Kiểm tra lý do không được rỗng
  IF p_reason IS NULL OR TRIM(p_reason) = '' THEN
    RETURN QUERY SELECT FALSE, 'Lý do chuyển lại không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Kiểm tra văn bản tồn tại
  SELECT COUNT(*) INTO v_count FROM edoc.incoming_docs WHERE id = p_doc_id;
  IF v_count = 0 THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản'::TEXT;
    RETURN;
  END IF;

  -- Ghi nhận bút phê lý do chuyển lại
  INSERT INTO edoc.leader_notes (incoming_doc_id, staff_id, content, created_at)
  VALUES (p_doc_id, p_returned_by, '[Chuyển lại] ' || TRIM(p_reason), NOW());

  -- Cập nhật trạng thái văn bản về chờ xử lý
  UPDATE edoc.incoming_docs
  SET
    approved = FALSE,
    updated_by = p_returned_by,
    updated_at = NOW()
  WHERE id = p_doc_id;

  RETURN QUERY SELECT TRUE, 'Chuyển lại văn bản thành công'::TEXT;
END;
$$;


--
-- Name: fn_incoming_doc_send(bigint, integer[], integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_send(p_doc_id bigint, p_staff_ids integer[], p_sent_by integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_approved BOOLEAN;
  v_count INT;
BEGIN
  -- Check approved
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;
  IF v_approved IS NULL OR v_approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể gửi'::TEXT;
    RETURN;
  END IF;

  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn ít nhất một người nhận'::TEXT;
    RETURN;
  END IF;

  -- Insert, skip duplicates
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), FALSE, NOW()
  ON CONFLICT (incoming_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;


--
-- Name: fn_incoming_doc_unapprove(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_unapprove(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_has_sent BOOLEAN;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;

  -- Không cho hủy duyệt nếu đã gửi
  SELECT EXISTS(SELECT 1 FROM edoc.user_incoming_docs WHERE incoming_doc_id = p_id) INTO v_has_sent;
  IF v_has_sent THEN
    RETURN QUERY SELECT FALSE, 'Không thể hủy duyệt: văn bản đã được gửi cho cán bộ'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.incoming_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt thành công'::TEXT;
END;
$$;


--
-- Name: fn_incoming_doc_update(bigint, timestamp with time zone, integer, character varying, character varying, text, character varying, timestamp with time zone, character varying, timestamp with time zone, integer, integer, integer, smallint, smallint, integer, integer, timestamp with time zone, text, text, boolean, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_incoming_doc_update(p_id bigint, p_received_date timestamp with time zone, p_number integer, p_notation character varying, p_document_code character varying, p_abstract text, p_publish_unit character varying, p_publish_date timestamp with time zone, p_signer character varying, p_sign_date timestamp with time zone, p_doc_book_id integer, p_doc_type_id integer, p_doc_field_id integer, p_secret_id smallint DEFAULT 1, p_urgent_id smallint DEFAULT 1, p_number_paper integer DEFAULT 1, p_number_copies integer DEFAULT 1, p_expired_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_recipients text DEFAULT NULL::text, p_sents text DEFAULT NULL::text, p_is_received_paper boolean DEFAULT false, p_updated_by integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.incoming_docs WHERE edoc.incoming_docs.id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.incoming_docs SET
    received_date   = COALESCE(p_received_date, received_date),
    number          = COALESCE(p_number, number),
    notation        = NULLIF(TRIM(p_notation), ''),
    document_code   = NULLIF(TRIM(p_document_code), ''),
    abstract        = TRIM(p_abstract),
    publish_unit    = NULLIF(TRIM(p_publish_unit), ''),
    publish_date    = p_publish_date,
    signer          = NULLIF(TRIM(p_signer), ''),
    sign_date       = p_sign_date,
    doc_book_id     = p_doc_book_id,
    doc_type_id     = p_doc_type_id,
    doc_field_id    = p_doc_field_id,
    secret_id       = COALESCE(p_secret_id, 1),
    urgent_id       = COALESCE(p_urgent_id, 1),
    number_paper    = COALESCE(p_number_paper, 1),
    number_copies   = COALESCE(p_number_copies, 1),
    expired_date    = p_expired_date,
    recipients      = NULLIF(TRIM(p_recipients), ''),
    sents           = NULLIF(TRIM(p_sents), ''),       -- MỚI
    is_received_paper = COALESCE(p_is_received_paper, FALSE),
    updated_by      = p_updated_by,
    updated_at      = NOW()
  WHERE edoc.incoming_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản đến thành công'::TEXT;
END;
$$;


--
-- Name: fn_inter_incoming_complete(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_inter_incoming_complete(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_status VARCHAR;
BEGIN
  SELECT status INTO v_status FROM edoc.inter_incoming_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản liên thông'::TEXT; RETURN;
  END IF;
  IF v_status != 'received' THEN
    RETURN QUERY SELECT FALSE, ('Không thể hoàn thành — trạng thái hiện tại: ' || v_status)::TEXT; RETURN;
  END IF;
  UPDATE edoc.inter_incoming_docs SET status = 'completed', updated_at = NOW() WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Hoàn thành xử lý văn bản liên thông'::TEXT;
END;
$$;


--
-- Name: fn_inter_incoming_create(integer, character varying, character varying, text, character varying, date, character varying, date, date, integer, character varying, character varying, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_inter_incoming_create(p_unit_id integer DEFAULT NULL::integer, p_notation character varying DEFAULT NULL::character varying, p_document_code character varying DEFAULT NULL::character varying, p_abstract text DEFAULT NULL::text, p_publish_unit character varying DEFAULT NULL::character varying, p_publish_date date DEFAULT NULL::date, p_signer character varying DEFAULT NULL::character varying, p_sign_date date DEFAULT NULL::date, p_expired_date date DEFAULT NULL::date, p_doc_type_id integer DEFAULT NULL::integer, p_source_system character varying DEFAULT NULL::character varying, p_external_doc_id character varying DEFAULT NULL::character varying, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF NOT EXISTS (SELECT 1 FROM public.departments WHERE id = v_unit_id) THEN
    RETURN QUERY SELECT FALSE, 'Đơn vị không tồn tại'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.inter_incoming_docs (
    unit_id, department_id, notation, document_code, abstract,
    publish_unit, publish_date, signer, sign_date,
    expired_date, doc_type_id, source_system, external_doc_id,
    created_by, created_at, updated_at
  ) VALUES (
    v_unit_id, p_department_id, p_notation, p_document_code, p_abstract,
    p_publish_unit, p_publish_date, p_signer, p_sign_date,
    p_expired_date, p_doc_type_id, p_source_system, p_external_doc_id,
    p_created_by, NOW(), NOW()
  )
  RETURNING inter_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản liên thông thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_inter_incoming_get_by_id(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_inter_incoming_get_by_id(p_id bigint) RETURNS TABLE(id bigint, unit_id integer, received_date timestamp without time zone, notation character varying, document_code character varying, abstract text, publish_unit character varying, publish_date date, signer character varying, sign_date date, expired_date date, doc_type_id integer, doc_field_id integer, secret_id smallint, urgent_id smallint, number_paper integer, number_copies integer, recipients text, status character varying, source_system character varying, external_doc_id character varying, organ_id character varying, from_organ_id character varying, created_by integer, created_at timestamp without time zone, updated_at timestamp without time zone, doc_type_name character varying, doc_field_name character varying, created_by_name character varying)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.notation, d.document_code,
    d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
    d.expired_date, d.doc_type_id,
    d.doc_field_id,                                -- MỚI
    d.secret_id,                                   -- MỚI
    d.urgent_id,                                   -- MỚI
    d.number_paper,                                -- MỚI
    d.number_copies,                               -- MỚI
    d.recipients,                                  -- MỚI
    d.status, d.source_system, d.external_doc_id,
    d.organ_id,                                    -- MỚI
    d.from_organ_id,                               -- MỚI
    d.created_by, d.created_at, d.updated_at,
    dt.name,                                       -- MỚI: doc_type_name
    df.name,                                       -- MỚI: doc_field_name
    s.full_name                                    -- MỚI: created_by_name
  FROM edoc.inter_incoming_docs d
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id        -- MỚI
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id      -- MỚI
  LEFT JOIN public.staff s ON s.id = d.created_by             -- MỚI
  WHERE d.id = p_id;
END;
$$;


--
-- Name: fn_inter_incoming_get_list(integer, text, text, date, date, integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_inter_incoming_get_list(p_unit_id integer, p_keyword text, p_status text, p_from_date date, p_to_date date, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, unit_id integer, received_date timestamp without time zone, notation character varying, document_code character varying, abstract text, publish_unit character varying, publish_date date, signer character varying, sign_date date, expired_date date, doc_type_id integer, status character varying, source_system character varying, external_doc_id character varying, created_by integer, created_at timestamp without time zone, updated_at timestamp without time zone, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id, d.unit_id, d.received_date, d.notation, d.document_code,
      d.abstract, d.publish_unit, d.publish_date, d.signer, d.sign_date,
      d.expired_date, d.doc_type_id, d.status, d.source_system,
      d.external_doc_id, d.created_by, d.created_at, d.updated_at
    FROM edoc.inter_incoming_docs d
    WHERE d.unit_id = p_unit_id
      AND (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_status IS NULL OR p_status = '' OR d.status = p_status)
      AND (p_from_date IS NULL OR d.received_date::DATE >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date::DATE <= p_to_date)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = ''
        OR d.notation ILIKE '%' || p_keyword || '%'
        OR d.abstract ILIKE '%' || p_keyword || '%'
        OR d.publish_unit ILIKE '%' || p_keyword || '%')
  )
  SELECT f.id, f.unit_id, f.received_date, f.notation, f.document_code,
    f.abstract, f.publish_unit, f.publish_date, f.signer, f.sign_date,
    f.expired_date, f.doc_type_id, f.status, f.source_system,
    f.external_doc_id, f.created_by, f.created_at, f.updated_at,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.received_date DESC NULLS LAST
  LIMIT COALESCE(p_page_size, 20) OFFSET v_offset;
END;
$$;


--
-- Name: fn_inter_incoming_receive(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_inter_incoming_receive(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_inter       edoc.inter_incoming_docs%ROWTYPE;
  v_unit_id     INT;
  v_incoming_id BIGINT;
  v_next_number INT;
BEGIN
  -- Lấy thông tin VB liên thông
  SELECT * INTO v_inter FROM edoc.inter_incoming_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản liên thông'::TEXT; RETURN;
  END IF;
  IF v_inter.status != 'pending' THEN
    RETURN QUERY SELECT FALSE, ('Không thể nhận bàn giao — trạng thái hiện tại: ' || v_inter.status)::TEXT; RETURN;
  END IF;

  -- Lấy unit_id từ staff
  SELECT s.unit_id INTO v_unit_id FROM public.staff s WHERE s.id = p_staff_id;
  IF v_unit_id IS NULL THEN v_unit_id := v_inter.unit_id; END IF;

  -- Tính số đến tiếp theo
  SELECT COALESCE(MAX(number), 0) + 1 INTO v_next_number
  FROM edoc.incoming_docs WHERE unit_id = v_unit_id;

  -- Tạo VB đến từ VB liên thông
  INSERT INTO edoc.incoming_docs (
    unit_id, received_date, number, notation, document_code,
    abstract, publish_unit, publish_date, signer, sign_date,
    doc_type_id, expired_date, secret_id, urgent_id,
    is_inter_doc, inter_doc_id,
    approved, is_handling, is_received_paper, archive_status,
    created_by, created_at
  ) VALUES (
    v_unit_id, NOW(), v_next_number, v_inter.notation, v_inter.document_code,
    v_inter.abstract, v_inter.publish_unit, v_inter.publish_date, v_inter.signer, v_inter.sign_date,
    v_inter.doc_type_id, v_inter.expired_date, 1, 1,
    TRUE, p_id::INT,
    FALSE, FALSE, FALSE, FALSE,
    p_staff_id, NOW()
  ) RETURNING id INTO v_incoming_id;

  -- Phân phối VB đến cho người nhận bàn giao
  INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, created_at)
  VALUES (v_incoming_id, p_staff_id, FALSE, NOW());

  -- Cập nhật trạng thái VB liên thông
  UPDATE edoc.inter_incoming_docs SET status = 'received', updated_at = NOW() WHERE id = p_id;

  RETURN QUERY SELECT TRUE, ('Nhận bàn giao thành công — đã tạo văn bản đến số ' || v_next_number)::TEXT;
END;
$$;


--
-- Name: fn_inter_incoming_return(bigint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_inter_incoming_return(p_id bigint, p_staff_id integer, p_reason text DEFAULT NULL::text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_status VARCHAR;
BEGIN
  SELECT status INTO v_status FROM edoc.inter_incoming_docs WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản liên thông'::TEXT; RETURN;
  END IF;
  IF v_status != 'pending' THEN
    RETURN QUERY SELECT FALSE, ('Không thể chuyển lại — trạng thái hiện tại: ' || v_status)::TEXT; RETURN;
  END IF;
  UPDATE edoc.inter_incoming_docs SET status = 'returned', updated_at = NOW() WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Chuyển lại văn bản thành công'::TEXT;
END;
$$;


--
-- Name: fn_leader_note_comment_and_assign(bigint, integer, text, timestamp with time zone, integer[], character varying); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_leader_note_comment_and_assign(p_doc_id bigint, p_staff_id integer, p_content text, p_expired_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_staff_ids integer[] DEFAULT NULL::integer[], p_doc_type character varying DEFAULT 'incoming'::character varying) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_id BIGINT;
  v_sent_count INT := 0;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung bút phê không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  -- Tạo leader note
  IF p_doc_type = 'incoming' THEN
    INSERT INTO edoc.leader_notes (incoming_doc_id, staff_id, content, expired_date, assigned_staff_ids)
    VALUES (p_doc_id, p_staff_id, TRIM(p_content), p_expired_date, p_staff_ids)
    RETURNING edoc.leader_notes.id INTO v_id;
  ELSIF p_doc_type = 'outgoing' THEN
    INSERT INTO edoc.leader_notes (outgoing_doc_id, staff_id, content, expired_date, assigned_staff_ids)
    VALUES (p_doc_id, p_staff_id, TRIM(p_content), p_expired_date, p_staff_ids)
    RETURNING edoc.leader_notes.id INTO v_id;
  ELSIF p_doc_type = 'drafting' THEN
    INSERT INTO edoc.leader_notes (drafting_doc_id, staff_id, content, expired_date, assigned_staff_ids)
    VALUES (p_doc_id, p_staff_id, TRIM(p_content), p_expired_date, p_staff_ids)
    RETURNING edoc.leader_notes.id INTO v_id;
  END IF;

  -- Gửi VB cho cán bộ được phân công
  IF p_staff_ids IS NOT NULL AND array_length(p_staff_ids, 1) > 0 THEN
    IF p_doc_type = 'incoming' THEN
      INSERT INTO edoc.user_incoming_docs (incoming_doc_id, staff_id, is_read, created_at)
      SELECT p_doc_id, unnest(p_staff_ids), FALSE, NOW()
      ON CONFLICT (incoming_doc_id, staff_id) DO NOTHING;
      GET DIAGNOSTICS v_sent_count = ROW_COUNT;
    ELSIF p_doc_type = 'outgoing' THEN
      INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, sent_by, is_read, created_at)
      SELECT p_doc_id, unnest(p_staff_ids), p_staff_id, FALSE, NOW()
      ON CONFLICT (outgoing_doc_id, staff_id) DO NOTHING;
      GET DIAGNOSTICS v_sent_count = ROW_COUNT;
    ELSIF p_doc_type = 'drafting' THEN
      INSERT INTO edoc.user_drafting_docs (drafting_doc_id, staff_id, sent_by, is_read, created_at)
      SELECT p_doc_id, unnest(p_staff_ids), p_staff_id, FALSE, NOW()
      ON CONFLICT (drafting_doc_id, staff_id) DO NOTHING;
      GET DIAGNOSTICS v_sent_count = ROW_COUNT;
    END IF;
  END IF;

  RETURN QUERY SELECT TRUE,
    ('Bút phê thành công' || CASE WHEN v_sent_count > 0 THEN ', đã phân công ' || v_sent_count || ' cán bộ' ELSE '' END)::TEXT,
    v_id;
END;
$$;


--
-- Name: fn_leader_note_create(bigint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_leader_note_create(p_doc_id bigint, p_staff_id integer, p_content text) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung bút phê không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.leader_notes (incoming_doc_id, staff_id, content)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content))
  RETURNING edoc.leader_notes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm bút phê thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_leader_note_create_drafting(bigint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_leader_note_create_drafting(p_doc_id bigint, p_staff_id integer, p_content text) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung ý kiến không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.leader_notes (drafting_doc_id, staff_id, content)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content))
  RETURNING edoc.leader_notes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm ý kiến thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_leader_note_create_outgoing(bigint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_leader_note_create_outgoing(p_doc_id bigint, p_staff_id integer, p_content text) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung ý kiến không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.leader_notes (outgoing_doc_id, staff_id, content)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content))
  RETURNING edoc.leader_notes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm ý kiến thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_leader_note_delete(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_leader_note_delete(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM edoc.leader_notes
  WHERE edoc.leader_notes.id = p_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy bút phê hoặc bạn không có quyền xóa'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa bút phê thành công'::TEXT;
END;
$$;


--
-- Name: fn_leader_note_get_by_drafting_doc(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_leader_note_get_by_drafting_doc(p_doc_id bigint) RETURNS TABLE(id bigint, staff_id integer, staff_name character varying, position_name character varying, content text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT ln.id, ln.staff_id, s.full_name, p.name, ln.content, ln.created_at
  FROM edoc.leader_notes ln
  JOIN public.staff s ON s.id = ln.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE ln.drafting_doc_id = p_doc_id
  ORDER BY ln.created_at DESC;
END;
$$;


--
-- Name: fn_leader_note_get_by_outgoing_doc(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_leader_note_get_by_outgoing_doc(p_doc_id bigint) RETURNS TABLE(id bigint, staff_id integer, staff_name character varying, position_name character varying, content text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT ln.id, ln.staff_id, s.full_name, p.name, ln.content, ln.created_at
  FROM edoc.leader_notes ln
  JOIN public.staff s ON s.id = ln.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE ln.outgoing_doc_id = p_doc_id
  ORDER BY ln.created_at DESC;
END;
$$;


--
-- Name: fn_leader_note_get_list(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_leader_note_get_list(p_doc_id bigint) RETURNS TABLE(id bigint, staff_id integer, staff_name character varying, position_name character varying, content text, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT ln.id, ln.staff_id, s.full_name, p.name, ln.content, ln.created_at
  FROM edoc.leader_notes ln
  JOIN public.staff s ON s.id = ln.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE ln.incoming_doc_id = p_doc_id
  ORDER BY ln.created_at DESC;
END;
$$;


--
-- Name: fn_lgsp_mock_receive(integer, character varying, text, character varying, character varying, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_lgsp_mock_receive(p_unit_id integer, p_notation character varying, p_abstract text, p_publish_unit character varying, p_signer character varying, p_doc_type_id integer DEFAULT NULL::integer, p_created_by integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  INSERT INTO edoc.inter_incoming_docs (
    unit_id, notation, abstract, publish_unit, signer,
    doc_type_id, source_system, status, created_by
  ) VALUES (
    p_unit_id, p_notation, p_abstract, p_publish_unit, p_signer,
    p_doc_type_id, 'LGSP_MOCK', 'pending', p_created_by
  )
  RETURNING inter_incoming_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, ('[MOCK] Đã nhận VB liên thông #' || v_id)::TEXT, v_id;
END;
$$;


--
-- Name: fn_lgsp_mock_send(bigint, character varying, character varying, character varying, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_lgsp_mock_send(p_doc_id bigint, p_doc_type character varying, p_dest_org_code character varying, p_dest_org_name character varying, p_sent_by integer) RETURNS TABLE(success boolean, message text, tracking_id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_tracking (
    outgoing_doc_id, incoming_doc_id, direction, dest_org_code, dest_org_name,
    status, sent_at, created_by
  ) VALUES (
    CASE WHEN p_doc_type = 'outgoing' THEN p_doc_id ELSE NULL END,
    CASE WHEN p_doc_type = 'incoming' THEN p_doc_id ELSE NULL END,
    'send', p_dest_org_code, p_dest_org_name,
    'success', NOW(), p_sent_by  -- Mock: luôn success
  )
  RETURNING edoc.lgsp_tracking.id INTO v_id;

  RETURN QUERY SELECT TRUE, ('[MOCK] Gửi liên thông thành công → ' || p_dest_org_name)::TEXT, v_id;
END;
$$;


--
-- Name: fn_lgsp_org_get_list(text, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_lgsp_org_get_list(p_search text DEFAULT NULL::text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20) RETURNS TABLE(id bigint, org_code character varying, org_name character varying, parent_code character varying, address character varying, email character varying, phone character varying, is_active boolean, synced_at timestamp with time zone, total_count bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_offset INT := (p_page - 1) * p_page_size;
  v_total  BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM edoc.lgsp_organizations o
  WHERE (p_search IS NULL OR p_search = ''
    OR o.org_code ILIKE '%' || p_search || '%'
    OR o.org_name ILIKE '%' || p_search || '%');

  RETURN QUERY
  SELECT
    o.id,
    o.org_code,
    o.org_name,
    o.parent_code,
    o.address,
    o.email,
    o.phone,
    o.is_active,
    o.synced_at,
    v_total
  FROM edoc.lgsp_organizations o
  WHERE (p_search IS NULL OR p_search = ''
    OR o.org_code ILIKE '%' || p_search || '%'
    OR o.org_name ILIKE '%' || p_search || '%')
  ORDER BY o.org_name
  LIMIT p_page_size OFFSET v_offset;
END;
$$;


--
-- Name: fn_lgsp_org_sync(character varying, character varying, character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_lgsp_org_sync(p_org_code character varying, p_org_name character varying, p_parent_code character varying DEFAULT NULL::character varying, p_address character varying DEFAULT NULL::character varying, p_email character varying DEFAULT NULL::character varying, p_phone character varying DEFAULT NULL::character varying) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_organizations (org_code, org_name, parent_code, address, email, phone, synced_at)
  VALUES (p_org_code, p_org_name, p_parent_code, p_address, p_email, p_phone, NOW())
  ON CONFLICT (org_code) DO UPDATE SET
    org_name    = EXCLUDED.org_name,
    parent_code = EXCLUDED.parent_code,
    address     = EXCLUDED.address,
    email       = EXCLUDED.email,
    phone       = EXCLUDED.phone,
    synced_at   = NOW()
  RETURNING edoc.lgsp_organizations.id INTO v_id;

  RETURN QUERY SELECT true, 'Dong bo co quan thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_lgsp_tracking_create(bigint, bigint, character varying, character varying, character varying, text, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_lgsp_tracking_create(p_outgoing_doc_id bigint DEFAULT NULL::bigint, p_incoming_doc_id bigint DEFAULT NULL::bigint, p_direction character varying DEFAULT 'send'::character varying, p_dest_org_code character varying DEFAULT NULL::character varying, p_dest_org_name character varying DEFAULT NULL::character varying, p_edxml_content text DEFAULT NULL::text, p_created_by integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.lgsp_tracking (
    outgoing_doc_id, incoming_doc_id, direction, dest_org_code, dest_org_name,
    edxml_content, status, created_by
  )
  VALUES (
    p_outgoing_doc_id, p_incoming_doc_id, p_direction, p_dest_org_code, p_dest_org_name,
    p_edxml_content, 'pending', p_created_by
  )
  RETURNING edoc.lgsp_tracking.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo tracking liên thông thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_lgsp_tracking_get_by_doc(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_lgsp_tracking_get_by_doc(p_outgoing_doc_id bigint) RETURNS TABLE(id bigint, direction character varying, lgsp_doc_id character varying, dest_org_code character varying, dest_org_name character varying, status character varying, error_message text, sent_at timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    t.id,
    t.direction,
    t.lgsp_doc_id,
    t.dest_org_code,
    t.dest_org_name,
    t.status,
    t.error_message,
    t.sent_at,
    t.created_at
  FROM edoc.lgsp_tracking t
  WHERE t.outgoing_doc_id = p_outgoing_doc_id
  ORDER BY t.created_at DESC;
END;
$$;


--
-- Name: fn_lgsp_tracking_get_list(character varying, character varying, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_lgsp_tracking_get_list(p_direction character varying DEFAULT NULL::character varying, p_status character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20) RETURNS TABLE(id bigint, outgoing_doc_id bigint, incoming_doc_id bigint, direction character varying, lgsp_doc_id character varying, dest_org_code character varying, dest_org_name character varying, status character varying, error_message text, sent_at timestamp with time zone, received_at timestamp with time zone, created_at timestamp with time zone, total_count bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_offset INT := (p_page - 1) * p_page_size;
  v_total  BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM edoc.lgsp_tracking t
  WHERE (p_direction IS NULL OR p_direction = '' OR t.direction = p_direction)
    AND (p_status IS NULL OR p_status = '' OR t.status = p_status);

  RETURN QUERY
  SELECT
    t.id,
    t.outgoing_doc_id,
    t.incoming_doc_id,
    t.direction,
    t.lgsp_doc_id,
    t.dest_org_code,
    t.dest_org_name,
    t.status,
    t.error_message,
    t.sent_at,
    t.received_at,
    t.created_at,
    v_total
  FROM edoc.lgsp_tracking t
  WHERE (p_direction IS NULL OR p_direction = '' OR t.direction = p_direction)
    AND (p_status IS NULL OR p_status = '' OR t.status = p_status)
  ORDER BY t.created_at DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;


--
-- Name: fn_lgsp_tracking_update_status(bigint, character varying, character varying, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_lgsp_tracking_update_status(p_id bigint, p_status character varying, p_lgsp_doc_id character varying DEFAULT NULL::character varying, p_error_message text DEFAULT NULL::text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE edoc.lgsp_tracking
  SET status        = p_status,
      lgsp_doc_id   = COALESCE(p_lgsp_doc_id, lgsp_doc_id),
      error_message = p_error_message,
      sent_at       = CASE WHEN p_status = 'success' THEN NOW() ELSE sent_at END,
      received_at   = CASE WHEN p_status = 'success' AND direction = 'receive' THEN NOW() ELSE received_at END
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay tracking'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cap nhat trang thai thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_meeting_type_create(integer, character varying, text, integer, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_meeting_type_create(p_unit_id integer, p_name character varying, p_description text, p_sort_order integer, p_created_user_id integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại cuộc họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.meeting_types (unit_id, name, description, sort_order, created_user_id)
  VALUES (v_unit_id, p_name, p_description, COALESCE(p_sort_order, 0), p_created_user_id)
  RETURNING edoc.meeting_types.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo loại cuộc họp thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_meeting_type_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_meeting_type_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  UPDATE edoc.meeting_types SET is_deleted = true WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy loại cuộc họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa loại cuộc họp thành công'::TEXT;
END;
$$;


--
-- Name: fn_meeting_type_get_list(integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_meeting_type_get_list(p_unit_id integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, unit_id integer, name character varying, description text, sort_order integer, created_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT mt.id, mt.unit_id, mt.name, mt.description, mt.sort_order, mt.created_date
  FROM edoc.meeting_types mt
  WHERE mt.unit_id = v_unit_id AND mt.is_deleted = false
  ORDER BY mt.sort_order, mt.name;
END;
$$;


--
-- Name: fn_meeting_type_update(integer, character varying, text, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_meeting_type_update(p_id integer, p_name character varying, p_description text, p_sort_order integer, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên loại cuộc họp không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.meeting_types SET
    name             = p_name,
    description      = p_description,
    sort_order       = COALESCE(p_sort_order, 0),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy loại cuộc họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;


--
-- Name: fn_message_count_unread(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_message_count_unread(p_staff_id integer) RETURNS TABLE(count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT COUNT(*)::BIGINT
  FROM edoc.message_recipients mr
  WHERE mr.staff_id = p_staff_id
    AND mr.is_read = FALSE
    AND mr.is_deleted = FALSE;
END;
$$;


--
-- Name: fn_message_create(integer, integer[], character varying, text, bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_message_create(p_from_staff_id integer, p_to_staff_ids integer[], p_subject character varying, p_content text, p_parent_id bigint DEFAULT NULL::bigint) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id          BIGINT;
  v_staff_id    INT;
BEGIN
  -- Kiểm tra người nhận
  IF p_to_staff_ids IS NULL OR array_length(p_to_staff_ids, 1) = 0 THEN
    RETURN QUERY SELECT FALSE, 'Phải có ít nhất một người nhận'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Kiểm tra tiêu đề
  IF p_subject IS NULL OR TRIM(p_subject) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề tin nhắn không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Kiểm tra nội dung
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung tin nhắn không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  -- Tạo tin nhắn
  INSERT INTO edoc.messages (from_staff_id, subject, content, parent_id, created_at)
  VALUES (p_from_staff_id, p_subject, p_content, p_parent_id, NOW())
  RETURNING messages.id INTO v_id;

  -- Thêm người nhận
  FOREACH v_staff_id IN ARRAY p_to_staff_ids LOOP
    INSERT INTO edoc.message_recipients (message_id, staff_id, is_read, is_deleted)
    VALUES (v_id, v_staff_id, FALSE, FALSE)
    ON CONFLICT (message_id, staff_id) DO NOTHING;
  END LOOP;

  RETURN QUERY SELECT TRUE, 'Gửi tin nhắn thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_message_delete(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_message_delete(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_is_sender BOOLEAN; v_is_recipient BOOLEAN;
BEGIN
  -- Check if sender
  SELECT EXISTS(SELECT 1 FROM edoc.messages WHERE edoc.messages.id = p_id AND from_staff_id = p_staff_id) INTO v_is_sender;
  -- Check if recipient
  SELECT EXISTS(SELECT 1 FROM edoc.message_recipients WHERE message_id = p_id AND staff_id = p_staff_id AND is_deleted = FALSE) INTO v_is_recipient;

  IF NOT v_is_sender AND NOT v_is_recipient THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn hoặc đã bị xóa'::TEXT;
    RETURN;
  END IF;

  -- Sender: soft delete from sent box
  IF v_is_sender THEN
    UPDATE edoc.messages SET sender_deleted = TRUE, sender_deleted_at = NOW() WHERE edoc.messages.id = p_id;
  END IF;

  -- Recipient: soft delete from inbox
  IF v_is_recipient THEN
    UPDATE edoc.message_recipients SET is_deleted = TRUE, deleted_at = NOW()
    WHERE message_id = p_id AND staff_id = p_staff_id;
  END IF;

  RETURN QUERY SELECT TRUE, 'Xóa tin nhắn thành công'::TEXT;
END; $$;


--
-- Name: fn_message_get_by_id(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_message_get_by_id(p_id bigint, p_staff_id integer) RETURNS TABLE(id bigint, from_staff_id integer, from_staff_name text, subject character varying, content text, parent_id bigint, created_at timestamp without time zone, is_read boolean, recipient_names text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Mark as read
  UPDATE edoc.message_recipients mr
  SET is_read = TRUE, read_at = NOW()
  WHERE mr.message_id = p_id AND mr.staff_id = p_staff_id AND mr.is_read = FALSE;

  RETURN QUERY
  SELECT
    m.id, m.from_staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT AS from_staff_name,
    m.subject, m.content, m.parent_id, m.created_at,
    COALESCE(mr.is_read, FALSE) AS is_read,
    (SELECT STRING_AGG(CONCAT(sr.last_name, ' ', sr.first_name), ', ' ORDER BY sr.last_name)
     FROM edoc.message_recipients mr2 JOIN public.staff sr ON sr.id = mr2.staff_id
     WHERE mr2.message_id = m.id
    )::TEXT AS recipient_names
  FROM edoc.messages m
  JOIN public.staff s ON s.id = m.from_staff_id
  LEFT JOIN edoc.message_recipients mr ON mr.message_id = m.id AND mr.staff_id = p_staff_id
  WHERE m.id = p_id
    AND (m.from_staff_id = p_staff_id
      OR EXISTS (SELECT 1 FROM edoc.message_recipients mr3 WHERE mr3.message_id = m.id AND mr3.staff_id = p_staff_id));
END; $$;


--
-- Name: fn_message_get_inbox(integer, text, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_message_get_inbox(p_staff_id integer, p_keyword text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20) RETURNS TABLE(id bigint, from_staff_id integer, from_staff_name text, subject character varying, content text, parent_id bigint, created_at timestamp without time zone, is_read boolean, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT
      m.id,
      m.from_staff_id,
      CONCAT(s.last_name, ' ', s.first_name) AS from_staff_name,
      m.subject,
      m.content,
      m.parent_id,
      m.created_at,
      mr.is_read
    FROM edoc.messages m
    JOIN edoc.message_recipients mr ON mr.message_id = m.id AND mr.staff_id = p_staff_id
    JOIN public.staff s ON s.id = m.from_staff_id
    WHERE
      mr.is_deleted = FALSE
      AND m.parent_id IS NULL
      AND (
        p_keyword IS NULL OR TRIM(p_keyword) = ''
        OR m.subject ILIKE '%' || p_keyword || '%'
        OR m.content ILIKE '%' || p_keyword || '%'
      )
  )
  SELECT
    f.id,
    f.from_staff_id,
    f.from_staff_name,
    f.subject,
    f.content,
    f.parent_id,
    f.created_at,
    f.is_read,
    COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.created_at DESC
  LIMIT COALESCE(p_page_size, 20)
  OFFSET v_offset;
END;
$$;


--
-- Name: fn_message_get_sent(integer, text, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_message_get_sent(p_staff_id integer, p_keyword text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20) RETURNS TABLE(id bigint, subject character varying, content text, parent_id bigint, created_at timestamp without time zone, recipient_names text, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT m.id, m.subject, m.content, m.parent_id, m.created_at,
      (SELECT STRING_AGG(CONCAT(sr.last_name, ' ', sr.first_name), ', ' ORDER BY sr.last_name)
       FROM edoc.message_recipients mr2 JOIN public.staff sr ON sr.id = mr2.staff_id WHERE mr2.message_id = m.id) AS recipient_names
    FROM edoc.messages m
    WHERE m.from_staff_id = p_staff_id AND m.parent_id IS NULL
      AND COALESCE(m.sender_deleted, FALSE) = FALSE
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR m.subject ILIKE '%' || p_keyword || '%' OR m.content ILIKE '%' || p_keyword || '%')
  )
  SELECT f.id, f.subject, f.content, f.parent_id, f.created_at, f.recipient_names, COUNT(*) OVER()::BIGINT
  FROM filtered f ORDER BY f.created_at DESC LIMIT COALESCE(p_page_size, 20) OFFSET v_offset;
END; $$;


--
-- Name: fn_message_get_trash(integer, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_message_get_trash(p_staff_id integer, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20) RETURNS TABLE(id bigint, from_staff_id integer, from_staff_name text, subject character varying, content text, parent_id bigint, created_at timestamp without time zone, deleted_at timestamp without time zone, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    -- Tin nhắn bị xóa với tư cách người nhận
    SELECT m.id, m.from_staff_id, CONCAT(s.last_name, ' ', s.first_name) AS from_staff_name,
      m.subject, m.content, m.parent_id, m.created_at, mr.deleted_at::TIMESTAMP
    FROM edoc.messages m
    JOIN edoc.message_recipients mr ON mr.message_id = m.id AND mr.staff_id = p_staff_id
    JOIN public.staff s ON s.id = m.from_staff_id
    WHERE mr.is_deleted = TRUE
    UNION
    -- Tin nhắn bị xóa với tư cách người gửi
    SELECT m.id, m.from_staff_id, CONCAT(s.last_name, ' ', s.first_name),
      m.subject, m.content, m.parent_id, m.created_at, m.sender_deleted_at::TIMESTAMP
    FROM edoc.messages m
    JOIN public.staff s ON s.id = m.from_staff_id
    WHERE m.from_staff_id = p_staff_id AND m.sender_deleted = TRUE
  )
  SELECT f.id, f.from_staff_id, f.from_staff_name, f.subject, f.content, f.parent_id, f.created_at, f.deleted_at,
    COUNT(*) OVER()::BIGINT
  FROM filtered f ORDER BY f.deleted_at DESC NULLS LAST LIMIT COALESCE(p_page_size, 20) OFFSET v_offset;
END; $$;


--
-- Name: fn_message_permanent_delete(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_message_permanent_delete(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_deleted BOOLEAN := FALSE;
BEGIN
  -- Delete as recipient
  IF EXISTS (SELECT 1 FROM edoc.message_recipients WHERE message_id = p_id AND staff_id = p_staff_id AND is_deleted = TRUE) THEN
    DELETE FROM edoc.message_recipients WHERE message_id = p_id AND staff_id = p_staff_id;
    v_deleted := TRUE;
  END IF;
  -- Delete as sender (mark permanently — don't delete message row as others may still have it)
  IF EXISTS (SELECT 1 FROM edoc.messages WHERE edoc.messages.id = p_id AND from_staff_id = p_staff_id AND sender_deleted = TRUE) THEN
    -- Keep the message but mark sender as permanently deleted
    v_deleted := TRUE;
  END IF;

  IF v_deleted THEN
    RETURN QUERY SELECT TRUE, 'Đã xóa vĩnh viễn tin nhắn'::TEXT;
  ELSE
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn trong thùng rác'::TEXT;
  END IF;
END; $$;


--
-- Name: fn_message_reply(bigint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_message_reply(p_message_id bigint, p_staff_id integer, p_content text) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_reply_id BIGINT;
  v_original edoc.messages%ROWTYPE;
  v_subject VARCHAR(200);
  v_staff_id INT;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung trả lời không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  SELECT * INTO v_original FROM edoc.messages m WHERE m.id = p_message_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn gốc'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  v_subject := 'Re: ' || v_original.subject;

  INSERT INTO edoc.messages (from_staff_id, subject, content, parent_id, created_at)
  VALUES (p_staff_id, v_subject, p_content, p_message_id, NOW())
  RETURNING edoc.messages.id INTO v_reply_id;

  INSERT INTO edoc.message_recipients (message_id, staff_id, is_read, is_deleted)
  VALUES (v_reply_id, v_original.from_staff_id, FALSE, FALSE)
  ON CONFLICT (message_id, staff_id) DO NOTHING;

  FOR v_staff_id IN
    SELECT mr.staff_id FROM edoc.message_recipients mr
    WHERE mr.message_id = p_message_id AND mr.staff_id <> p_staff_id
  LOOP
    INSERT INTO edoc.message_recipients (message_id, staff_id, is_read, is_deleted)
    VALUES (v_reply_id, v_staff_id, FALSE, FALSE)
    ON CONFLICT (message_id, staff_id) DO NOTHING;
  END LOOP;

  RETURN QUERY SELECT TRUE, 'Trả lời tin nhắn thành công'::TEXT, v_reply_id;
END; $$;


--
-- Name: fn_message_restore(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_message_restore(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_restored BOOLEAN := FALSE;
BEGIN
  -- Restore as recipient
  IF EXISTS (SELECT 1 FROM edoc.message_recipients WHERE message_id = p_id AND staff_id = p_staff_id AND is_deleted = TRUE) THEN
    UPDATE edoc.message_recipients SET is_deleted = FALSE, deleted_at = NULL
    WHERE message_id = p_id AND staff_id = p_staff_id;
    v_restored := TRUE;
  END IF;
  -- Restore as sender
  IF EXISTS (SELECT 1 FROM edoc.messages WHERE edoc.messages.id = p_id AND from_staff_id = p_staff_id AND sender_deleted = TRUE) THEN
    UPDATE edoc.messages SET sender_deleted = FALSE, sender_deleted_at = NULL WHERE edoc.messages.id = p_id;
    v_restored := TRUE;
  END IF;

  IF v_restored THEN
    RETURN QUERY SELECT TRUE, 'Khôi phục tin nhắn thành công'::TEXT;
  ELSE
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tin nhắn trong thùng rác'::TEXT;
  END IF;
END; $$;


--
-- Name: fn_notice_count_unread(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_notice_count_unread(p_staff_id integer) RETURNS TABLE(count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT COUNT(*)::BIGINT
  FROM edoc.notices n
  WHERE NOT EXISTS (
    SELECT 1 FROM edoc.notice_reads nr
    WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id
  );
END;
$$;


--
-- Name: fn_notice_create(integer, character varying, text, character varying, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_notice_create(p_unit_id integer DEFAULT NULL::integer, p_title character varying DEFAULT NULL::character varying, p_content text DEFAULT NULL::text, p_notice_type character varying DEFAULT NULL::character varying, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_title IS NULL OR TRIM(p_title) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề thông báo không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung thông báo không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.notices (unit_id, department_id, title, content, notice_type, created_by, created_at)
  VALUES (v_unit_id, p_department_id, p_title, p_content, COALESCE(p_notice_type, 'system'), p_created_by, NOW())
  RETURNING notices.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo thông báo thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_notice_get_list(integer, integer, text, integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_notice_get_list(p_unit_id integer, p_staff_id integer, p_is_read text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, unit_id integer, title character varying, content text, notice_type character varying, created_by integer, created_at timestamp without time zone, is_read boolean, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT n.id, n.unit_id, n.title, n.content, n.notice_type, n.created_by, n.created_at,
      CASE WHEN nr.id IS NOT NULL THEN TRUE ELSE FALSE END AS is_read
    FROM edoc.notices n
    LEFT JOIN edoc.notice_reads nr ON nr.notice_id = n.id AND nr.staff_id = p_staff_id
    WHERE (p_unit_id IS NULL OR n.unit_id = p_unit_id OR n.unit_id IS NULL)
      AND (p_dept_ids IS NULL OR n.department_id = ANY(p_dept_ids))
      AND (p_is_read IS NULL OR p_is_read = ''
        OR (p_is_read = 'true' AND nr.id IS NOT NULL)
        OR (p_is_read = 'false' AND nr.id IS NULL))
  )
  SELECT f.id, f.unit_id, f.title, f.content, f.notice_type, f.created_by, f.created_at,
    f.is_read, COUNT(*) OVER()::BIGINT AS total_count
  FROM filtered f
  ORDER BY f.created_at DESC
  LIMIT COALESCE(p_page_size, 20) OFFSET v_offset;
END;
$$;


--
-- Name: fn_notice_mark_all_read(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_notice_mark_all_read(p_staff_id integer, p_unit_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(success boolean, message text, count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_count BIGINT := 0;
BEGIN
  WITH unread_notices AS (
    SELECT n.id FROM edoc.notices n
    WHERE (p_unit_id IS NULL OR n.unit_id = p_unit_id OR n.unit_id IS NULL)
      AND (p_dept_ids IS NULL OR n.department_id = ANY(p_dept_ids))
      AND NOT EXISTS (SELECT 1 FROM edoc.notice_reads nr WHERE nr.notice_id = n.id AND nr.staff_id = p_staff_id)
  ),
  inserted AS (
    INSERT INTO edoc.notice_reads (notice_id, staff_id, read_at)
    SELECT un.id, p_staff_id, NOW() FROM unread_notices un
    ON CONFLICT (notice_id, staff_id) DO NOTHING
    RETURNING 1
  )
  SELECT COUNT(*) INTO v_count FROM inserted;

  RETURN QUERY SELECT TRUE, 'Đánh dấu tất cả đã đọc thành công'::TEXT, v_count;
END;
$$;


--
-- Name: fn_notice_mark_read(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_notice_mark_read(p_notice_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  -- Kiểm tra thông báo tồn tại
  IF NOT EXISTS (SELECT 1 FROM edoc.notices WHERE id = p_notice_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy thông báo'::TEXT;
    RETURN;
  END IF;

  -- Insert ON CONFLICT DO NOTHING để tránh duplicate
  INSERT INTO edoc.notice_reads (notice_id, staff_id, read_at)
  VALUES (p_notice_id, p_staff_id, NOW())
  ON CONFLICT (notice_id, staff_id) DO NOTHING;

  RETURN QUERY SELECT TRUE, 'Đánh dấu đã đọc thành công'::TEXT;
END;
$$;


--
-- Name: fn_notification_log_create(integer, character varying, character varying, character varying, text, character varying, bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_notification_log_create(p_staff_id integer, p_channel character varying, p_event_type character varying, p_title character varying DEFAULT NULL::character varying, p_body text DEFAULT NULL::text, p_ref_type character varying DEFAULT NULL::character varying, p_ref_id bigint DEFAULT NULL::bigint) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.notification_logs (
    staff_id, channel, event_type, title, body, ref_type, ref_id
  )
  VALUES (
    p_staff_id, p_channel, p_event_type, p_title, p_body, p_ref_type, p_ref_id
  )
  RETURNING edoc.notification_logs.id INTO v_id;

  RETURN QUERY SELECT true, 'Tao log thong bao thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_notification_log_get_list(integer, character varying, character varying, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_notification_log_get_list(p_staff_id integer DEFAULT NULL::integer, p_channel character varying DEFAULT NULL::character varying, p_send_status character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20) RETURNS TABLE(id bigint, staff_id integer, channel character varying, event_type character varying, title character varying, body text, ref_type character varying, ref_id bigint, send_status character varying, error_message text, sent_at timestamp with time zone, created_at timestamp with time zone, total_count bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_offset INT := (p_page - 1) * p_page_size;
  v_total  BIGINT;
BEGIN
  SELECT COUNT(*) INTO v_total
  FROM edoc.notification_logs nl
  WHERE (p_staff_id IS NULL OR nl.staff_id = p_staff_id)
    AND (p_channel IS NULL OR p_channel = '' OR nl.channel = p_channel)
    AND (p_send_status IS NULL OR p_send_status = '' OR nl.send_status = p_send_status);

  RETURN QUERY
  SELECT
    nl.id,
    nl.staff_id,
    nl.channel,
    nl.event_type,
    nl.title,
    nl.body,
    nl.ref_type,
    nl.ref_id,
    nl.send_status,
    nl.error_message,
    nl.sent_at,
    nl.created_at,
    v_total
  FROM edoc.notification_logs nl
  WHERE (p_staff_id IS NULL OR nl.staff_id = p_staff_id)
    AND (p_channel IS NULL OR p_channel = '' OR nl.channel = p_channel)
    AND (p_send_status IS NULL OR p_send_status = '' OR nl.send_status = p_send_status)
  ORDER BY nl.created_at DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;


--
-- Name: fn_notification_log_update_status(bigint, character varying, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_notification_log_update_status(p_id bigint, p_send_status character varying, p_error_message text DEFAULT NULL::text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE edoc.notification_logs
  SET send_status   = p_send_status,
      error_message = p_error_message,
      sent_at       = CASE WHEN p_send_status = 'sent' THEN NOW() ELSE sent_at END
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Khong tim thay log thong bao'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cap nhat trang thai thong bao thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_notification_pref_get_by_staff(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_notification_pref_get_by_staff(p_staff_id integer) RETURNS TABLE(id bigint, channel character varying, is_enabled boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    np.id,
    np.channel,
    np.is_enabled
  FROM edoc.notification_preferences np
  WHERE np.staff_id = p_staff_id
  ORDER BY np.channel;
END;
$$;


--
-- Name: fn_notification_pref_upsert(integer, character varying, boolean); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_notification_pref_upsert(p_staff_id integer, p_channel character varying, p_is_enabled boolean DEFAULT true) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_id BIGINT;
BEGIN
  INSERT INTO edoc.notification_preferences (staff_id, channel, is_enabled, updated_at)
  VALUES (p_staff_id, p_channel, p_is_enabled, NOW())
  ON CONFLICT (staff_id, channel) DO UPDATE SET
    is_enabled = EXCLUDED.is_enabled,
    updated_at = NOW()
  RETURNING edoc.notification_preferences.id INTO v_id;

  RETURN QUERY SELECT true, 'Cap nhat cau hinh thong bao thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_opinion_create(bigint, integer, text, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_opinion_create(p_doc_id bigint, p_staff_id integer, p_content text, p_opinion_type text DEFAULT 'general'::text) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung ý kiến không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM edoc.handling_docs WHERE id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Hồ sơ công việc không tồn tại'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  INSERT INTO edoc.opinion_handling_docs (handling_doc_id, staff_id, content, created_at)
  VALUES (p_doc_id, p_staff_id, TRIM(p_content), NOW())
  RETURNING edoc.opinion_handling_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Thêm ý kiến thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_opinion_get_list(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_opinion_get_list(p_doc_id bigint) RETURNS TABLE(id bigint, staff_id integer, staff_name text, content text, attachment_path character varying, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    o.id,
    o.staff_id,
    CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
    o.content,
    o.attachment_path,
    o.created_at
  FROM edoc.opinion_handling_docs o
  JOIN public.staff s ON s.id = o.staff_id
  WHERE o.handling_doc_id = p_doc_id
  ORDER BY o.created_at ASC;
END;
$$;


--
-- Name: fn_organization_get(integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_organization_get(p_unit_id integer DEFAULT NULL::integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, unit_id integer, code character varying, name character varying, address text, phone character varying, fax character varying, email character varying, email_doc character varying, secretary character varying, chairman_number character varying, level smallint, is_exchange boolean, lgsp_system_id character varying, lgsp_secret_key character varying, updated_by integer, updated_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT o.id, o.unit_id, o.code::VARCHAR, o.name::VARCHAR, o.address,
         o.phone::VARCHAR, o.fax::VARCHAR, o.email::VARCHAR, o.email_doc::VARCHAR,
         o.secretary::VARCHAR, o.chairman_number::VARCHAR, o.level,
         o.is_exchange, o.lgsp_system_id::VARCHAR, o.lgsp_secret_key::VARCHAR,
         o.updated_by, o.updated_at
  FROM edoc.organizations o
  WHERE o.unit_id = CASE WHEN p_dept_id IS NOT NULL THEN public.fn_get_ancestor_unit(p_dept_id)
                         ELSE p_unit_id END;
$$;


--
-- Name: fn_organization_upsert(integer, character varying, character varying, text, character varying, character varying, character varying, character varying, character varying, character varying, smallint, boolean, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_organization_upsert(p_unit_id integer DEFAULT NULL::integer, p_code character varying DEFAULT NULL::character varying, p_name character varying DEFAULT NULL::character varying, p_address text DEFAULT NULL::text, p_phone character varying DEFAULT NULL::character varying, p_fax character varying DEFAULT NULL::character varying, p_email character varying DEFAULT NULL::character varying, p_email_doc character varying DEFAULT NULL::character varying, p_secretary character varying DEFAULT NULL::character varying, p_chairman_number character varying DEFAULT NULL::character varying, p_level smallint DEFAULT 1, p_is_exchange boolean DEFAULT false, p_updated_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF NOT EXISTS(SELECT 1 FROM public.departments WHERE id = v_unit_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Đơn vị không tồn tại'::TEXT;
    RETURN;
  END IF;

  IF p_code IS NOT NULL AND LENGTH(p_code) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Mã cơ quan không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;
  IF p_email IS NOT NULL AND LENGTH(p_email) > 100 THEN
    RETURN QUERY SELECT FALSE, 'Email không được vượt quá 100 ký tự'::TEXT;
    RETURN;
  END IF;
  IF p_phone IS NOT NULL AND LENGTH(p_phone) > 20 THEN
    RETURN QUERY SELECT FALSE, 'Số điện thoại không được vượt quá 20 ký tự'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.organizations (
    unit_id, code, name, address, phone, fax, email, email_doc,
    secretary, chairman_number, level, is_exchange,
    lgsp_system_id, lgsp_secret_key, updated_by, updated_at
  ) VALUES (
    v_unit_id, p_code, p_name, p_address, p_phone, p_fax, p_email, p_email_doc,
    p_secretary, p_chairman_number, p_level, p_is_exchange,
    NULL, NULL, p_updated_by, NOW()
  )
  ON CONFLICT (unit_id) DO UPDATE SET
    code             = EXCLUDED.code,
    name             = EXCLUDED.name,
    address          = EXCLUDED.address,
    phone            = EXCLUDED.phone,
    fax              = EXCLUDED.fax,
    email            = EXCLUDED.email,
    email_doc        = EXCLUDED.email_doc,
    secretary        = EXCLUDED.secretary,
    chairman_number  = EXCLUDED.chairman_number,
    level            = EXCLUDED.level,
    is_exchange      = EXCLUDED.is_exchange,
    updated_by       = EXCLUDED.updated_by,
    updated_at       = NOW();

  RETURN QUERY SELECT TRUE, 'Cap nhat thong tin co quan thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_outgoing_doc_approve(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_approve(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_name TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;
  SELECT full_name INTO v_name FROM public.staff WHERE id = p_staff_id;
  UPDATE edoc.outgoing_docs
  SET approved = TRUE, approver = v_name, rejected_by = NULL, rejection_reason = NULL,
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Duyệt văn bản đi thành công'::TEXT;
END; $$;


--
-- Name: fn_outgoing_doc_check_number(integer, integer, integer, bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_check_number(p_unit_id integer DEFAULT NULL::integer, p_doc_book_id integer DEFAULT NULL::integer, p_number integer DEFAULT NULL::integer, p_exclude_id bigint DEFAULT NULL::bigint, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(is_exists boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT EXISTS (
    SELECT 1 FROM edoc.outgoing_docs
    WHERE unit_id = v_unit_id
      AND doc_book_id = p_doc_book_id
      AND number = p_number
      AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW())
      AND (p_exclude_id IS NULL OR id != p_exclude_id)
  );
END;
$$;


--
-- Name: fn_outgoing_doc_count_unread(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_count_unread(p_unit_id integer, p_staff_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*)::INT INTO v_count
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
  WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
    AND (uo.is_read IS NULL OR uo.is_read = FALSE);
  RETURN v_count;
END; $$;


--
-- Name: fn_outgoing_doc_create(integer, timestamp with time zone, integer, character varying, character varying, character varying, text, integer, integer, integer, timestamp with time zone, character varying, timestamp with time zone, integer, integer, integer, smallint, smallint, integer, integer, timestamp with time zone, text, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_create(p_unit_id integer, p_received_date timestamp with time zone, p_number integer, p_sub_number character varying, p_notation character varying, p_document_code character varying, p_abstract text, p_drafting_unit_id integer DEFAULT NULL::integer, p_drafting_user_id integer DEFAULT NULL::integer, p_publish_unit_id integer DEFAULT NULL::integer, p_publish_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_signer character varying DEFAULT NULL::character varying, p_sign_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_doc_book_id integer DEFAULT NULL::integer, p_doc_type_id integer DEFAULT NULL::integer, p_doc_field_id integer DEFAULT NULL::integer, p_secret_id smallint DEFAULT 1, p_urgent_id smallint DEFAULT 1, p_number_paper integer DEFAULT 1, p_number_copies integer DEFAULT 1, p_expired_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_recipients text DEFAULT NULL::text, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_number IS NULL OR p_number = 0 THEN
    p_number := edoc.fn_outgoing_doc_get_next_number(p_doc_book_id, p_unit_id);
  END IF;

  -- Resolve department_id from created_by if not provided
  IF p_department_id IS NULL AND p_created_by IS NOT NULL THEN
    SELECT s.department_id INTO p_department_id FROM public.staff s WHERE s.id = p_created_by;
  END IF;

  INSERT INTO edoc.outgoing_docs (
    unit_id, department_id, received_date, number, sub_number, notation, document_code,
    abstract, drafting_unit_id, drafting_user_id, publish_unit_id, publish_date,
    signer, sign_date, expired_date,
    number_paper, number_copies, secret_id, urgent_id,
    recipients, doc_book_id, doc_type_id, doc_field_id,
    created_by, updated_by
  ) VALUES (
    p_unit_id, COALESCE(p_department_id, p_unit_id), COALESCE(p_received_date, NOW()), p_number,
    NULLIF(TRIM(p_sub_number), ''), NULLIF(TRIM(p_notation), ''), NULLIF(TRIM(p_document_code), ''),
    TRIM(p_abstract), p_drafting_unit_id, p_drafting_user_id, p_publish_unit_id, p_publish_date,
    NULLIF(TRIM(p_signer), ''), p_sign_date, p_expired_date,
    COALESCE(p_number_paper, 1), COALESCE(p_number_copies, 1),
    COALESCE(p_secret_id, 1), COALESCE(p_urgent_id, 1),
    NULLIF(TRIM(p_recipients), ''), p_doc_book_id, p_doc_type_id, p_doc_field_id,
    p_created_by, p_created_by
  )
  RETURNING edoc.outgoing_docs.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tạo văn bản đi thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_outgoing_doc_delete(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_delete(p_id bigint) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa văn bản đi thành công'::TEXT;
END;
$$;


--
-- Name: fn_outgoing_doc_get_by_id(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_get_by_id(p_id bigint, p_staff_id integer) RETURNS TABLE(id bigint, unit_id integer, received_date timestamp with time zone, number integer, sub_number character varying, notation character varying, document_code character varying, abstract text, drafting_unit_id integer, drafting_user_id integer, publish_unit_id integer, publish_date timestamp with time zone, signer character varying, sign_date timestamp with time zone, expired_date timestamp with time zone, doc_book_id integer, doc_type_id integer, doc_field_id integer, secret_id smallint, urgent_id smallint, number_paper integer, number_copies integer, recipients text, approver character varying, approved boolean, is_handling boolean, archive_status boolean, is_inter_doc boolean, is_digital_signed smallint, created_by integer, created_at timestamp with time zone, updated_by integer, updated_at timestamp with time zone, doc_book_name character varying, doc_type_name character varying, doc_type_code character varying, doc_field_name character varying, drafting_unit_name character varying, drafting_user_name character varying, publish_unit_name character varying, created_by_name character varying, is_read boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Đánh dấu đã đọc
  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, is_read, read_at)
  VALUES (p_id, p_staff_id, TRUE, NOW())
  ON CONFLICT (outgoing_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_outgoing_docs.read_at, NOW());

  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.received_date, d.number, d.sub_number,
    d.notation, d.document_code, d.abstract,
    d.drafting_unit_id, d.drafting_user_id, d.publish_unit_id, d.publish_date,
    d.signer, d.sign_date, d.expired_date,
    d.doc_book_id, d.doc_type_id, d.doc_field_id,
    d.secret_id, d.urgent_id, d.number_paper, d.number_copies,
    d.recipients, d.approver, d.approved,
    d.is_handling, d.archive_status, d.is_inter_doc, d.is_digital_signed,
    d.created_by, d.created_at, d.updated_by, d.updated_at,
    db.name, dt.name, dt.code, df.name,
    du.name, ds.full_name,
    pu.name,                                       -- MỚI: publish_unit_name
    s.full_name,
    TRUE
  FROM edoc.outgoing_docs d
  LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id
  LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
  LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id
  LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
  LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id
  LEFT JOIN public.departments pu ON pu.id = d.publish_unit_id    -- MỚI
  LEFT JOIN public.staff s ON s.id = d.created_by
  WHERE d.id = p_id;
END;
$$;


--
-- Name: fn_outgoing_doc_get_history(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_get_history(p_doc_id bigint) RETURNS TABLE(event_type character varying, event_time timestamp with time zone, staff_name character varying, content text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM (
    -- Tạo
    SELECT 'created'::VARCHAR AS evt, d.created_at AS etime, s.full_name AS sname,
           ('Tạo văn bản đi, số: ' || d.number)::TEXT AS econtent
    FROM edoc.outgoing_docs d
    JOIN public.staff s ON s.id = d.created_by
    WHERE d.id = p_doc_id

    UNION ALL
    -- Duyệt
    SELECT 'approved'::VARCHAR, d.updated_at, d.approver::VARCHAR, 'Duyệt văn bản đi'::TEXT
    FROM edoc.outgoing_docs d
    WHERE d.id = p_doc_id AND d.approved = TRUE

    UNION ALL
    -- Gửi
    SELECT 'sent'::VARCHAR, uo.created_at, s.full_name, 'Nhận văn bản'::TEXT
    FROM edoc.user_outgoing_docs uo
    JOIN public.staff s ON s.id = uo.staff_id
    WHERE uo.outgoing_doc_id = p_doc_id
  ) sub
  ORDER BY sub.etime DESC;
END;
$$;


--
-- Name: fn_outgoing_doc_get_list(integer, integer, integer, integer, integer, smallint, boolean, timestamp with time zone, timestamp with time zone, text, integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_get_list(p_unit_id integer, p_staff_id integer, p_doc_book_id integer DEFAULT NULL::integer, p_doc_type_id integer DEFAULT NULL::integer, p_doc_field_id integer DEFAULT NULL::integer, p_urgent_id smallint DEFAULT NULL::smallint, p_approved boolean DEFAULT NULL::boolean, p_from_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_to_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_keyword text DEFAULT NULL::text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, unit_id integer, received_date timestamp with time zone, number integer, sub_number character varying, notation character varying, document_code character varying, abstract text, drafting_unit_id integer, drafting_user_id integer, publish_unit_id integer, publish_date timestamp with time zone, signer character varying, sign_date timestamp with time zone, expired_date timestamp with time zone, doc_book_id integer, doc_type_id integer, doc_field_id integer, secret_id smallint, urgent_id smallint, number_paper integer, number_copies integer, recipients text, approver character varying, approved boolean, is_handling boolean, archive_status boolean, created_by integer, created_at timestamp with time zone, doc_book_name character varying, doc_type_name character varying, doc_type_code character varying, doc_field_name character varying, drafting_unit_name character varying, drafting_user_name character varying, created_by_name character varying, is_read boolean, read_at timestamp with time zone, attachment_count bigint, total_count bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_offset INT; v_keyword TEXT;
BEGIN
  v_offset := (GREATEST(p_page, 1) - 1) * p_page_size;
  v_keyword := NULLIF(TRIM(p_keyword), '');
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id AS doc_id, d.*,
      db.name AS _doc_book_name, dt.name AS _doc_type_name, dt.code AS _doc_type_code,
      df.name AS _doc_field_name, du.name AS _drafting_unit_name, ds.full_name AS _drafting_user_name,
      s.full_name AS _created_by_name, uo.is_read AS _is_read, uo.read_at AS _read_at,
      (SELECT COUNT(*) FROM edoc.attachment_outgoing_docs a WHERE a.outgoing_doc_id = d.id) AS _attachment_count,
      COUNT(*) OVER() AS _total_count
    FROM edoc.outgoing_docs d
    LEFT JOIN edoc.doc_books db ON db.id = d.doc_book_id LEFT JOIN edoc.doc_types dt ON dt.id = d.doc_type_id
    LEFT JOIN edoc.doc_fields df ON df.id = d.doc_field_id LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    LEFT JOIN public.staff ds ON ds.id = d.drafting_user_id LEFT JOIN public.staff s ON s.id = d.created_by
    LEFT JOIN edoc.user_outgoing_docs uo ON uo.outgoing_doc_id = d.id AND uo.staff_id = p_staff_id
    WHERE (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_doc_book_id IS NULL OR d.doc_book_id = p_doc_book_id)
      AND (p_doc_type_id IS NULL OR d.doc_type_id = p_doc_type_id)
      AND (p_doc_field_id IS NULL OR d.doc_field_id = p_doc_field_id)
      AND (p_urgent_id IS NULL OR d.urgent_id = p_urgent_id)
      AND (p_approved IS NULL OR d.approved = p_approved)
      AND (p_from_date IS NULL OR d.received_date >= p_from_date)
      AND (p_to_date IS NULL OR d.received_date <= p_to_date)
      AND (v_keyword IS NULL OR d.abstract ILIKE '%' || v_keyword || '%' OR d.notation ILIKE '%' || v_keyword || '%' OR d.signer ILIKE '%' || v_keyword || '%' OR d.recipients ILIKE '%' || v_keyword || '%')
    ORDER BY d.received_date DESC, d.number DESC LIMIT p_page_size OFFSET v_offset
  )
  SELECT f.doc_id, f.unit_id, f.received_date, f.number, f.sub_number, f.notation, f.document_code, f.abstract,
    f.drafting_unit_id, f.drafting_user_id, f.publish_unit_id, f.publish_date, f.signer, f.sign_date, f.expired_date,
    f.doc_book_id, f.doc_type_id, f.doc_field_id, f.secret_id, f.urgent_id, f.number_paper, f.number_copies,
    f.recipients, f.approver, f.approved, f.is_handling, f.archive_status,
    f.created_by, f.created_at, f._doc_book_name, f._doc_type_name, f._doc_type_code, f._doc_field_name,
    f._drafting_unit_name, f._drafting_user_name, f._created_by_name,
    COALESCE(f._is_read, FALSE), f._read_at, f._attachment_count, f._total_count
  FROM filtered f;
END; $$;


--
-- Name: fn_outgoing_doc_get_next_number(integer, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_get_next_number(p_doc_book_id integer, p_unit_id integer DEFAULT NULL::integer, p_dept_id integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_max INT; v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.outgoing_docs
  WHERE doc_book_id = p_doc_book_id
    AND unit_id = v_unit_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());
  RETURN v_max + 1;
END;
$$;


--
-- Name: fn_outgoing_doc_get_recipients(bigint); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_get_recipients(p_doc_id bigint) RETURNS TABLE(id bigint, staff_id integer, staff_name character varying, position_name character varying, department_name character varying, is_read boolean, read_at timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    uo.id, uo.staff_id,
    s.full_name,
    p.name AS position_name,
    dep.name AS department_name,
    uo.is_read, uo.read_at, uo.created_at
  FROM edoc.user_outgoing_docs uo
  JOIN public.staff s ON s.id = uo.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  WHERE uo.outgoing_doc_id = p_doc_id
  ORDER BY uo.created_at DESC;
END;
$$;


--
-- Name: fn_outgoing_doc_get_unused_numbers(integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_get_unused_numbers(p_unit_id integer, p_doc_book_id integer) RETURNS TABLE(unused_number integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_max INT;
BEGIN
  -- Lấy số lớn nhất đã cấp trong năm
  SELECT COALESCE(MAX(number), 0) INTO v_max
  FROM edoc.outgoing_docs
  WHERE unit_id = p_unit_id
    AND doc_book_id = p_doc_book_id
    AND EXTRACT(YEAR FROM received_date) = EXTRACT(YEAR FROM NOW());

  -- Trả về các số bị bỏ qua (gaps)
  RETURN QUERY
  SELECT g.n::INT AS unused_number
  FROM generate_series(1, v_max) AS g(n)
  WHERE NOT EXISTS (
    SELECT 1 FROM edoc.outgoing_docs o
    WHERE o.unit_id = p_unit_id
      AND o.doc_book_id = p_doc_book_id
      AND o.number = g.n
      AND EXTRACT(YEAR FROM o.received_date) = EXTRACT(YEAR FROM NOW())
  )
  ORDER BY g.n;
END;
$$;


--
-- Name: fn_outgoing_doc_mark_read_bulk(bigint[], integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_mark_read_bulk(p_doc_ids bigint[], p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, is_read, read_at)
  SELECT unnest(p_doc_ids), p_staff_id, TRUE, NOW()
  ON CONFLICT (outgoing_doc_id, staff_id)
  DO UPDATE SET is_read = TRUE, read_at = COALESCE(edoc.user_outgoing_docs.read_at, NOW());

  RETURN QUERY SELECT TRUE, 'Đã đánh dấu đọc thành công'::TEXT;
END;
$$;


--
-- Name: fn_outgoing_doc_reject(bigint, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_reject(p_id bigint, p_staff_id integer, p_reason text DEFAULT NULL::text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;
  UPDATE edoc.outgoing_docs
  SET approved = FALSE, rejected_by = p_staff_id, rejection_reason = NULLIF(TRIM(p_reason), ''),
      updated_by = p_staff_id, updated_at = NOW()
  WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Đã từ chối văn bản đi'::TEXT;
END; $$;


--
-- Name: fn_outgoing_doc_retract(bigint, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_retract(p_id bigint, p_staff_id integer, p_staff_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_deleted_count INT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT; RETURN;
  END IF;

  IF p_staff_ids IS NULL THEN
    -- Thu hồi tất cả (trừ người thu hồi)
    DELETE FROM edoc.user_outgoing_docs WHERE outgoing_doc_id = p_id AND staff_id != p_staff_id;
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    -- Reset approved khi thu hồi toàn bộ
    UPDATE edoc.outgoing_docs SET approved = FALSE, updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  ELSE
    -- Thu hồi từng người cụ thể
    DELETE FROM edoc.user_outgoing_docs WHERE outgoing_doc_id = p_id AND staff_id = ANY(p_staff_ids);
    GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
    UPDATE edoc.outgoing_docs SET updated_by = p_staff_id, updated_at = NOW() WHERE id = p_id;
  END IF;

  RETURN QUERY SELECT TRUE, ('Thu hồi thành công — đã xóa ' || v_deleted_count || ' người nhận')::TEXT;
END;
$$;


--
-- Name: fn_outgoing_doc_send(bigint, integer[], integer, timestamp with time zone); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_send(p_doc_id bigint, p_staff_ids integer[], p_sent_by integer, p_expired_date timestamp with time zone DEFAULT NULL::timestamp with time zone) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_approved BOOLEAN;
  v_count INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_doc_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;
  IF v_approved IS NULL OR v_approved = FALSE THEN
    RETURN QUERY SELECT FALSE, 'Văn bản chưa được duyệt, không thể gửi'::TEXT;
    RETURN;
  END IF;

  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn ít nhất một người nhận'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.user_outgoing_docs (outgoing_doc_id, staff_id, sent_by, expired_date, is_read, created_at)
  SELECT p_doc_id, unnest(p_staff_ids), p_sent_by, p_expired_date, FALSE, NOW()
  ON CONFLICT (outgoing_doc_id, staff_id) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN QUERY SELECT TRUE, ('Đã gửi cho ' || v_count || ' người nhận')::TEXT;
END;
$$;


--
-- Name: fn_outgoing_doc_unapprove(bigint, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_unapprove(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_has_sent BOOLEAN;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;

  SELECT EXISTS(SELECT 1 FROM edoc.user_outgoing_docs WHERE outgoing_doc_id = p_id) INTO v_has_sent;
  IF v_has_sent THEN
    RETURN QUERY SELECT FALSE, 'Không thể hủy duyệt: văn bản đã được gửi cho cán bộ'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.outgoing_docs SET
    approved = FALSE,
    approver = NULL,
    updated_by = p_staff_id,
    updated_at = NOW()
  WHERE edoc.outgoing_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Hủy duyệt thành công'::TEXT;
END;
$$;


--
-- Name: fn_outgoing_doc_update(bigint, timestamp with time zone, integer, character varying, character varying, character varying, text, integer, integer, integer, timestamp with time zone, character varying, timestamp with time zone, integer, integer, integer, smallint, smallint, integer, integer, timestamp with time zone, text, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_outgoing_doc_update(p_id bigint, p_received_date timestamp with time zone, p_number integer, p_sub_number character varying, p_notation character varying, p_document_code character varying, p_abstract text, p_drafting_unit_id integer DEFAULT NULL::integer, p_drafting_user_id integer DEFAULT NULL::integer, p_publish_unit_id integer DEFAULT NULL::integer, p_publish_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_signer character varying DEFAULT NULL::character varying, p_sign_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_doc_book_id integer DEFAULT NULL::integer, p_doc_type_id integer DEFAULT NULL::integer, p_doc_field_id integer DEFAULT NULL::integer, p_secret_id smallint DEFAULT 1, p_urgent_id smallint DEFAULT 1, p_number_paper integer DEFAULT 1, p_number_copies integer DEFAULT 1, p_expired_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_recipients text DEFAULT NULL::text, p_updated_by integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_approved BOOLEAN;
BEGIN
  SELECT approved INTO v_approved FROM edoc.outgoing_docs WHERE edoc.outgoing_docs.id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT;
    RETURN;
  END IF;
  IF v_approved = TRUE THEN
    RETURN QUERY SELECT FALSE, 'Không thể sửa văn bản đã được duyệt'::TEXT;
    RETURN;
  END IF;

  IF p_abstract IS NULL OR TRIM(p_abstract) = '' THEN
    RETURN QUERY SELECT FALSE, 'Trích yếu nội dung không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_doc_book_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Sổ văn bản là bắt buộc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.outgoing_docs SET
    received_date     = COALESCE(p_received_date, received_date),
    number            = COALESCE(p_number, number),
    sub_number        = NULLIF(TRIM(p_sub_number), ''),
    notation          = NULLIF(TRIM(p_notation), ''),
    document_code     = NULLIF(TRIM(p_document_code), ''),
    abstract          = TRIM(p_abstract),
    drafting_unit_id  = p_drafting_unit_id,
    drafting_user_id  = p_drafting_user_id,
    publish_unit_id   = p_publish_unit_id,
    publish_date      = p_publish_date,
    signer            = NULLIF(TRIM(p_signer), ''),
    sign_date         = p_sign_date,
    doc_book_id       = p_doc_book_id,
    doc_type_id       = p_doc_type_id,
    doc_field_id      = p_doc_field_id,
    secret_id         = COALESCE(p_secret_id, 1),
    urgent_id         = COALESCE(p_urgent_id, 1),
    number_paper      = COALESCE(p_number_paper, 1),
    number_copies     = COALESCE(p_number_copies, 1),
    expired_date      = p_expired_date,
    recipients        = NULLIF(TRIM(p_recipients), ''),
    updated_by        = p_updated_by,
    updated_at        = NOW()
  WHERE edoc.outgoing_docs.id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật văn bản đi thành công'::TEXT;
END;
$$;


--
-- Name: fn_report_handling_by_assigner(integer, timestamp with time zone, timestamp with time zone, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_report_handling_by_assigner(p_unit_id integer, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(staff_id integer, staff_name text, department_name text, total bigint, completed bigint, in_progress bigint, overdue bigint, completion_rate numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT s.id AS staff_id, CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
    d.name::TEXT AS department_name,
    COUNT(h.id)::BIGINT AS total,
    COUNT(h.id) FILTER (WHERE h.status = 4)::BIGINT AS completed,
    COUNT(h.id) FILTER (WHERE h.status IN (0,1,2,3))::BIGINT AS in_progress,
    COUNT(h.id) FILTER (WHERE h.end_date < NOW() AND h.status NOT IN (4, -1))::BIGINT AS overdue,
    CASE WHEN COUNT(h.id) > 0
      THEN ROUND(COUNT(h.id) FILTER (WHERE h.status = 4)::NUMERIC / COUNT(h.id)::NUMERIC * 100, 2)
      ELSE 0 END AS completion_rate
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN edoc.handling_docs h ON h.created_by = s.id AND h.unit_id = p_unit_id
    AND (p_from_date IS NULL OR h.created_at >= p_from_date) AND (p_to_date IS NULL OR h.created_at <= p_to_date)
  WHERE (p_dept_ids IS NULL OR s.department_id = ANY(p_dept_ids))
    AND s.unit_id = p_unit_id AND s.is_locked = FALSE
  GROUP BY s.id, s.last_name, s.first_name, d.name
  HAVING COUNT(h.id) > 0
  ORDER BY total DESC, s.last_name;
END;
$$;


--
-- Name: fn_report_handling_by_resolver(integer, timestamp with time zone, timestamp with time zone, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_report_handling_by_resolver(p_unit_id integer, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(staff_id integer, staff_name text, department_name text, total bigint, completed bigint, in_progress bigint, overdue bigint, completion_rate numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT s.id AS staff_id, CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
    d.name::TEXT AS department_name,
    COUNT(h.id)::BIGINT AS total,
    COUNT(h.id) FILTER (WHERE h.status = 4)::BIGINT AS completed,
    COUNT(h.id) FILTER (WHERE h.status IN (0,1,2,3))::BIGINT AS in_progress,
    COUNT(h.id) FILTER (WHERE h.end_date < NOW() AND h.status NOT IN (4, -1))::BIGINT AS overdue,
    CASE WHEN COUNT(h.id) > 0
      THEN ROUND(COUNT(h.id) FILTER (WHERE h.status = 4)::NUMERIC / COUNT(h.id)::NUMERIC * 100, 2)
      ELSE 0 END AS completion_rate
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN edoc.handling_docs h ON h.curator = s.id AND h.unit_id = p_unit_id
    AND (p_from_date IS NULL OR h.created_at >= p_from_date) AND (p_to_date IS NULL OR h.created_at <= p_to_date)
  WHERE (p_dept_ids IS NULL OR s.department_id = ANY(p_dept_ids))
    AND s.unit_id = p_unit_id AND s.is_locked = FALSE
  GROUP BY s.id, s.last_name, s.first_name, d.name
  HAVING COUNT(h.id) > 0
  ORDER BY total DESC, s.last_name;
END;
$$;


--
-- Name: fn_report_handling_by_unit(integer, timestamp with time zone, timestamp with time zone, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_report_handling_by_unit(p_unit_id integer, p_from_date timestamp with time zone, p_to_date timestamp with time zone, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(department_id integer, department_name text, total bigint, completed bigint, in_progress bigint, overdue bigint, completion_rate numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id AS department_id, d.name::TEXT AS department_name,
    COUNT(h.id)::BIGINT AS total,
    COUNT(h.id) FILTER (WHERE h.status = 4)::BIGINT AS completed,
    COUNT(h.id) FILTER (WHERE h.status IN (0,1,2,3))::BIGINT AS in_progress,
    COUNT(h.id) FILTER (WHERE h.end_date < NOW() AND h.status NOT IN (4, -1))::BIGINT AS overdue,
    CASE WHEN COUNT(h.id) > 0
      THEN ROUND(COUNT(h.id) FILTER (WHERE h.status = 4)::NUMERIC / COUNT(h.id)::NUMERIC * 100, 2)
      ELSE 0 END AS completion_rate
  FROM public.departments d
  LEFT JOIN edoc.handling_docs h ON h.department_id = d.id
    AND h.unit_id = p_unit_id
    AND (p_from_date IS NULL OR h.created_at >= p_from_date)
    AND (p_to_date IS NULL OR h.created_at <= p_to_date)
  WHERE (p_dept_ids IS NULL OR d.id = ANY(p_dept_ids))
    AND d.parent_id = p_unit_id AND d.is_unit = FALSE AND d.is_deleted = FALSE
  GROUP BY d.id, d.name
  ORDER BY total DESC, d.name;
END;
$$;


--
-- Name: fn_room_create(integer, character varying, character varying, character varying, text, integer, boolean, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_create(p_unit_id integer, p_name character varying, p_code character varying, p_location character varying, p_note text, p_sort_order integer, p_show_in_calendar boolean, p_created_user_id integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phòng họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.rooms (unit_id, name, code, location, note, sort_order, show_in_calendar, created_user_id)
  VALUES (v_unit_id, p_name, NULLIF(TRIM(p_code),''), p_location, p_note,
          COALESCE(p_sort_order, 0), COALESCE(p_show_in_calendar, true), p_created_user_id)
  RETURNING edoc.rooms.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo phòng họp thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phòng họp đã tồn tại'::TEXT, NULL::INT;
END;
$$;


--
-- Name: fn_room_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM edoc.room_schedules WHERE room_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Phòng họp đang có lịch họp, không thể xóa'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.rooms SET is_deleted = true WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy phòng họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa phòng họp thành công'::TEXT;
END;
$$;


--
-- Name: fn_room_get_list(integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_get_list(p_unit_id integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, unit_id integer, name character varying, code character varying, location character varying, note text, sort_order integer, show_in_calendar boolean, created_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT r.id, r.unit_id, r.name, r.code, r.location, r.note,
    r.sort_order, r.show_in_calendar, r.created_date
  FROM edoc.rooms r
  WHERE r.unit_id = v_unit_id AND r.is_deleted = false
  ORDER BY r.sort_order, r.name;
END;
$$;


--
-- Name: fn_room_schedule_approve(integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_approve(p_id integer, p_approved_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_approved INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.room_schedules WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy cuộc họp'::TEXT;
    RETURN;
  END IF;

  IF v_approved <> 0 THEN
    RETURN QUERY SELECT false, 'Cuộc họp không ở trạng thái chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.room_schedules SET
    approved          = 1,
    approved_date     = NOW(),
    approved_staff_id = p_approved_staff_id,
    modified_user_id  = p_approved_staff_id,
    modified_date     = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Duyệt cuộc họp thành công'::TEXT;
END;
$$;


--
-- Name: fn_room_schedule_assign_staff(integer, integer[], integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_assign_staff(p_room_schedule_id integer, p_staff_ids integer[], p_user_type integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_staff_id INT;
BEGIN
  IF p_staff_ids IS NULL OR array_length(p_staff_ids, 1) IS NULL THEN
    RETURN QUERY SELECT false, 'Danh sách nhân sự trống'::TEXT;
    RETURN;
  END IF;

  FOREACH v_staff_id IN ARRAY p_staff_ids LOOP
    INSERT INTO edoc.room_schedule_staff (room_schedule_id, staff_id, user_type)
    VALUES (p_room_schedule_id, v_staff_id, COALESCE(p_user_type, 0))
    ON CONFLICT (room_schedule_id, staff_id) DO NOTHING;
  END LOOP;

  RETURN QUERY SELECT true, 'Phân công thành viên thành công'::TEXT;
END;
$$;


--
-- Name: fn_room_schedule_create(integer, integer, integer, character varying, text, character varying, date, date, character varying, character varying, integer, integer, character varying, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_create(p_unit_id integer, p_room_id integer, p_meeting_type_id integer, p_name character varying, p_content text, p_component character varying, p_start_date date, p_end_date date, p_start_time character varying, p_end_time character varying, p_master_id integer, p_secretary_id integer, p_online_link character varying, p_created_user_id integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên cuộc họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  IF p_start_date IS NULL THEN
    RETURN QUERY SELECT false, 'Ngày họp không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO edoc.room_schedules (
    unit_id, department_id, room_id, meeting_type_id, name, content, component,
    start_date, end_date, start_time, end_time, master_id, secretary_id,
    online_link, created_user_id
  ) VALUES (
    v_unit_id, p_department_id, p_room_id, p_meeting_type_id, p_name, p_content, p_component,
    p_start_date, p_end_date, p_start_time, p_end_time, p_master_id, p_secretary_id,
    p_online_link, p_created_user_id
  ) RETURNING edoc.room_schedules.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo cuộc họp thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_room_schedule_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_approved INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.room_schedules WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy cuộc họp'::TEXT;
    RETURN;
  END IF;

  IF v_approved <> 0 THEN
    RETURN QUERY SELECT false, 'Chỉ có thể xóa cuộc họp chưa được duyệt'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.room_schedules WHERE id = p_id;

  RETURN QUERY SELECT true, 'Xóa cuộc họp thành công'::TEXT;
END;
$$;


--
-- Name: fn_room_schedule_get_by_id(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_get_by_id(p_id integer) RETURNS TABLE(id integer, unit_id integer, room_id integer, room_name character varying, meeting_type_id integer, meeting_type_name character varying, name character varying, content text, component character varying, start_date date, end_date date, start_time character varying, end_time character varying, master_id integer, master_name text, secretary_id integer, approved integer, approved_date timestamp with time zone, approved_staff_id integer, rejection_reason text, meeting_status integer, online_link character varying, is_cancel integer, created_user_id integer, created_date timestamp with time zone, modified_user_id integer, modified_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    rs.id, rs.unit_id, rs.room_id, r.name AS room_name,
    rs.meeting_type_id, mt.name AS meeting_type_name,
    rs.name, rs.content, rs.component,
    rs.start_date, rs.end_date, rs.start_time, rs.end_time,
    rs.master_id, (ms.last_name || ' ' || ms.first_name)::TEXT AS master_name,
    rs.secretary_id, rs.approved, rs.approved_date, rs.approved_staff_id,
    rs.rejection_reason, rs.meeting_status, rs.online_link, rs.is_cancel,
    rs.created_user_id, rs.created_date, rs.modified_user_id, rs.modified_date
  FROM edoc.room_schedules rs
  LEFT JOIN edoc.rooms r ON r.id = rs.room_id
  LEFT JOIN edoc.meeting_types mt ON mt.id = rs.meeting_type_id
  LEFT JOIN public.staff ms ON ms.id = rs.master_id
  WHERE rs.id = p_id;
END;
$$;


--
-- Name: fn_room_schedule_get_list(integer, integer, integer, date, date, text, integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_get_list(p_unit_id integer, p_room_id integer, p_status integer, p_from_date date, p_to_date date, p_keyword text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id integer, unit_id integer, room_id integer, room_name character varying, meeting_type_id integer, meeting_type_name character varying, name character varying, content text, start_date date, end_date date, start_time character varying, end_time character varying, master_id integer, master_name text, approved integer, meeting_status integer, online_link character varying, created_date timestamp with time zone, staff_count bigint, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT rs.id, rs.unit_id, rs.room_id, r.name AS room_name,
      rs.meeting_type_id, mt.name AS meeting_type_name, rs.name, rs.content,
      rs.start_date, rs.end_date, rs.start_time, rs.end_time, rs.master_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS master_name,
      rs.approved, rs.meeting_status, rs.online_link, rs.created_date,
      (SELECT COUNT(*) FROM edoc.room_schedule_staff rss WHERE rss.room_schedule_id = rs.id) AS staff_count
    FROM edoc.room_schedules rs
    LEFT JOIN edoc.rooms r ON r.id = rs.room_id
    LEFT JOIN edoc.meeting_types mt ON mt.id = rs.meeting_type_id
    LEFT JOIN public.staff s ON s.id = rs.master_id
    WHERE rs.unit_id = p_unit_id
      AND (p_dept_ids IS NULL OR rs.department_id = ANY(p_dept_ids))
      AND (p_room_id IS NULL OR rs.room_id = p_room_id)
      AND (p_status IS NULL OR p_status = -99 OR rs.meeting_status = p_status)
      AND (p_from_date IS NULL OR rs.start_date >= p_from_date)
      AND (p_to_date IS NULL OR rs.start_date <= p_to_date)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR rs.name ILIKE '%' || p_keyword || '%')
  )
  SELECT flt.*, COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.start_date DESC, flt.start_time
  LIMIT p_page_size OFFSET v_offset;
END;
$$;


--
-- Name: fn_room_schedule_get_staff(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_get_staff(p_room_schedule_id integer) RETURNS TABLE(id integer, room_schedule_id integer, staff_id integer, staff_name text, position_name character varying, user_type integer, is_secretary boolean, is_represent boolean, attendance boolean, attendance_date timestamp with time zone, attendance_note text, received_appointment integer, received_appointment_date timestamp with time zone, view_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    rss.id,
    rss.room_schedule_id,
    rss.staff_id,
    (s.last_name || ' ' || s.first_name)::TEXT AS staff_name,
    p.name AS position_name,
    rss.user_type,
    rss.is_secretary,
    rss.is_represent,
    rss.attendance,
    rss.attendance_date,
    rss.attendance_note,
    rss.received_appointment,
    rss.received_appointment_date,
    rss.view_date
  FROM edoc.room_schedule_staff rss
  LEFT JOIN public.staff s ON s.id = rss.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE rss.room_schedule_id = p_room_schedule_id
  ORDER BY rss.user_type, s.last_name;
END;
$$;


--
-- Name: fn_room_schedule_reject(integer, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_reject(p_id integer, p_approved_staff_id integer, p_reason text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_approved INT;
BEGIN
  SELECT approved INTO v_approved FROM edoc.room_schedules WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy cuộc họp'::TEXT;
    RETURN;
  END IF;

  IF v_approved <> 0 THEN
    RETURN QUERY SELECT false, 'Cuộc họp không ở trạng thái chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.room_schedules SET
    approved          = -1,
    approved_date     = NOW(),
    approved_staff_id = p_approved_staff_id,
    rejection_reason  = p_reason,
    modified_user_id  = p_approved_staff_id,
    modified_date     = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Từ chối cuộc họp thành công'::TEXT;
END;
$$;


--
-- Name: fn_room_schedule_remove_staff(integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_remove_staff(p_room_schedule_id integer, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  DELETE FROM edoc.room_schedule_staff
  WHERE room_schedule_id = p_room_schedule_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy thành viên trong cuộc họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa thành viên thành công'::TEXT;
END;
$$;


--
-- Name: fn_room_schedule_stats(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_stats(p_unit_id integer, p_year integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(stat_type text, category_id integer, category_name character varying, month_num integer, count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT 'by_month'::TEXT, 0, 'Tất cả'::VARCHAR,
    EXTRACT(MONTH FROM rs.start_date)::INT, COUNT(*)::BIGINT
  FROM edoc.room_schedules rs
  WHERE rs.unit_id = p_unit_id AND EXTRACT(YEAR FROM rs.start_date) = p_year AND rs.is_cancel = 0
    AND (p_dept_ids IS NULL OR rs.department_id = ANY(p_dept_ids))
  GROUP BY EXTRACT(MONTH FROM rs.start_date) ORDER BY month_num;

  RETURN QUERY
  SELECT 'by_room'::TEXT, r.id, r.name, 0, COUNT(*)::BIGINT
  FROM edoc.room_schedules rs
  JOIN edoc.rooms r ON r.id = rs.room_id
  WHERE rs.unit_id = p_unit_id AND EXTRACT(YEAR FROM rs.start_date) = p_year AND rs.is_cancel = 0
    AND (p_dept_ids IS NULL OR rs.department_id = ANY(p_dept_ids))
  GROUP BY r.id, r.name ORDER BY count DESC;

  RETURN QUERY
  SELECT 'by_meeting_type'::TEXT, mt.id, mt.name, 0, COUNT(*)::BIGINT
  FROM edoc.room_schedules rs
  JOIN edoc.meeting_types mt ON mt.id = rs.meeting_type_id
  WHERE rs.unit_id = p_unit_id AND EXTRACT(YEAR FROM rs.start_date) = p_year AND rs.is_cancel = 0
    AND (p_dept_ids IS NULL OR rs.department_id = ANY(p_dept_ids))
  GROUP BY mt.id, mt.name ORDER BY count DESC;
END;
$$;


--
-- Name: fn_room_schedule_update(integer, integer, integer, character varying, text, character varying, date, date, character varying, character varying, integer, integer, character varying, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_schedule_update(p_id integer, p_room_id integer, p_meeting_type_id integer, p_name character varying, p_content text, p_component character varying, p_start_date date, p_end_date date, p_start_time character varying, p_end_time character varying, p_master_id integer, p_secretary_id integer, p_online_link character varying, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên cuộc họp không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.room_schedules SET
    room_id          = p_room_id,
    meeting_type_id  = p_meeting_type_id,
    name             = p_name,
    content          = p_content,
    component        = p_component,
    start_date       = COALESCE(p_start_date, start_date),
    end_date         = p_end_date,
    start_time       = p_start_time,
    end_time         = p_end_time,
    master_id        = p_master_id,
    secretary_id     = p_secretary_id,
    online_link      = p_online_link,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy cuộc họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;


--
-- Name: fn_room_update(integer, character varying, character varying, character varying, text, integer, boolean, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_room_update(p_id integer, p_name character varying, p_code character varying, p_location character varying, p_note text, p_sort_order integer, p_show_in_calendar boolean, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phòng họp không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.rooms SET
    name             = p_name,
    code             = NULLIF(TRIM(p_code),''),
    location         = p_location,
    note             = p_note,
    sort_order       = COALESCE(p_sort_order, 0),
    show_in_calendar = COALESCE(p_show_in_calendar, true),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy phòng họp'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phòng họp đã tồn tại'::TEXT;
END;
$$;


--
-- Name: fn_send_config_get_by_user(integer, character varying); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_send_config_get_by_user(p_user_id integer, p_config_type character varying DEFAULT 'doc'::character varying) RETURNS TABLE(id integer, target_user_id integer, target_name character varying, position_name character varying, department_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT c.id, c.target_user_id, s.full_name, p.name, d.name
  FROM edoc.send_doc_user_configs c
  JOIN public.staff s ON s.id = c.target_user_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE c.user_id = p_user_id AND c.config_type = p_config_type
  ORDER BY d.sort_order, s.full_name;
END;
$$;


--
-- Name: fn_send_config_save(integer, character varying, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_send_config_save(p_user_id integer, p_config_type character varying, p_target_user_ids integer[]) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_count INT;
BEGIN
  -- Xóa cũ
  DELETE FROM edoc.send_doc_user_configs
  WHERE user_id = p_user_id AND config_type = p_config_type;

  -- Insert mới
  IF p_target_user_ids IS NOT NULL AND array_length(p_target_user_ids, 1) > 0 THEN
    INSERT INTO edoc.send_doc_user_configs (user_id, target_user_id, config_type)
    SELECT p_user_id, unnest(p_target_user_ids), p_config_type
    ON CONFLICT (user_id, target_user_id, config_type) DO NOTHING;
  END IF;

  SELECT COUNT(*) INTO v_count
  FROM edoc.send_doc_user_configs
  WHERE user_id = p_user_id AND config_type = p_config_type;

  RETURN QUERY SELECT TRUE, ('Đã lưu ' || v_count || ' người nhận')::TEXT;
END;
$$;


--
-- Name: fn_signer_create(integer, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_signer_create(p_unit_id integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer, p_staff_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_staff_id IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Vui lòng chọn nhân viên'::TEXT, 0;
    RETURN;
  END IF;

  IF NOT EXISTS(SELECT 1 FROM public.staff s WHERE s.id = p_staff_id AND s.is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Nhân viên không tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  IF EXISTS(SELECT 1 FROM edoc.signers WHERE unit_id = v_unit_id AND staff_id = p_staff_id) THEN
    RETURN QUERY SELECT FALSE, 'Nhân viên đã có trong danh sách người ký'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.signers (unit_id, department_id, staff_id)
  VALUES (v_unit_id, p_department_id, p_staff_id)
  RETURNING signers.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Them nguoi ky thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_signer_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_signer_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.signers WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy người ký'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.signers WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa nguoi ky thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_signer_get_list(integer, integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_signer_get_list(p_unit_id integer, p_department_id integer DEFAULT NULL::integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id integer, unit_id integer, department_id integer, staff_id integer, staff_name character varying, position_name character varying, department_name character varying, sort_order integer)
    LANGUAGE sql STABLE
    AS $$
  SELECT sg.id, sg.unit_id, sg.department_id, sg.staff_id,
         s.full_name::VARCHAR AS staff_name,
         p.name::VARCHAR AS position_name,
         d.name::VARCHAR AS department_name,
         sg.sort_order
  FROM edoc.signers sg
    JOIN public.staff s ON s.id = sg.staff_id
    LEFT JOIN public.positions p ON p.id = s.position_id
    LEFT JOIN public.departments d ON d.id = sg.department_id
  WHERE sg.unit_id = p_unit_id
    AND (p_dept_ids IS NULL OR sg.department_id = ANY(p_dept_ids))
    AND (p_department_id IS NULL OR sg.department_id = p_department_id)
  ORDER BY sg.sort_order, s.full_name;
$$;


--
-- Name: fn_sms_template_create(integer, character varying, text, text, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_sms_template_create(p_unit_id integer DEFAULT NULL::integer, p_name character varying DEFAULT NULL::character varying, p_content text DEFAULT NULL::text, p_description text DEFAULT NULL::text, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu tin nhắn không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu tin nhắn không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu tin nhắn không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.sms_templates (unit_id, name, content, description, created_by)
  VALUES (v_unit_id, TRIM(p_name), TRIM(p_content), p_description, p_created_by)
  RETURNING sms_templates.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao mau tin nhan thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_sms_template_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_sms_template_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.sms_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu tin nhắn'::TEXT;
    RETURN;
  END IF;

  DELETE FROM edoc.sms_templates WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa mau tin nhan thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_sms_template_get_list(integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_sms_template_get_list(p_unit_id integer DEFAULT NULL::integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, unit_id integer, name character varying, content text, description text, is_active boolean, created_by integer, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT t.id, t.unit_id, t.name::VARCHAR, t.content,
         t.description, t.is_active, t.created_by, t.created_at
  FROM edoc.sms_templates t
  WHERE t.unit_id = CASE WHEN p_dept_id IS NOT NULL THEN public.fn_get_ancestor_unit(p_dept_id)
                         ELSE p_unit_id END
  ORDER BY t.name;
$$;


--
-- Name: fn_sms_template_update(integer, character varying, text, text, boolean); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_sms_template_update(p_id integer, p_name character varying DEFAULT NULL::character varying, p_content text DEFAULT NULL::text, p_description text DEFAULT NULL::text, p_is_active boolean DEFAULT NULL::boolean) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.sms_templates WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy mẫu tin nhắn'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên mẫu tin nhắn không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_content IS NULL OR TRIM(p_content) = '' THEN
    RETURN QUERY SELECT FALSE, 'Nội dung mẫu tin nhắn không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.sms_templates SET
    name        = TRIM(p_name),
    content     = TRIM(p_content),
    description = COALESCE(p_description, description),
    is_active   = COALESCE(p_is_active, is_active)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat mau tin nhan thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_staff_note_get_list(integer, character varying); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_staff_note_get_list(p_staff_id integer, p_doc_type character varying DEFAULT 'incoming'::character varying) RETURNS TABLE(note_id bigint, doc_id bigint, note text, is_important boolean, created_at timestamp with time zone, doc_number integer, doc_notation character varying, doc_abstract text, doc_received_date timestamp with time zone, doc_publish_unit character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF p_doc_type = 'incoming' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.is_important, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date, d.publish_unit
    FROM edoc.staff_notes sn
    JOIN edoc.incoming_docs d ON d.id = sn.doc_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'incoming'
    ORDER BY sn.is_important DESC, sn.created_at DESC;

  ELSIF p_doc_type = 'outgoing' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.is_important, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date,
           COALESCE(du.name, '')::VARCHAR
    FROM edoc.staff_notes sn
    JOIN edoc.outgoing_docs d ON d.id = sn.doc_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'outgoing'
    ORDER BY sn.is_important DESC, sn.created_at DESC;

  ELSIF p_doc_type = 'drafting' THEN
    RETURN QUERY
    SELECT sn.id, sn.doc_id, sn.note, sn.is_important, sn.created_at,
           d.number, d.notation, d.abstract, d.received_date,
           COALESCE(du.name, '')::VARCHAR
    FROM edoc.staff_notes sn
    JOIN edoc.drafting_docs d ON d.id = sn.doc_id
    LEFT JOIN public.departments du ON du.id = d.drafting_unit_id
    WHERE sn.staff_id = p_staff_id AND sn.doc_type = 'drafting'
    ORDER BY sn.is_important DESC, sn.created_at DESC;
  END IF;
END;
$$;


--
-- Name: fn_staff_note_toggle(character varying, bigint, integer, text, boolean); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_staff_note_toggle(p_doc_type character varying, p_doc_id bigint, p_staff_id integer, p_note text DEFAULT NULL::text, p_is_important boolean DEFAULT false) RETURNS TABLE(success boolean, message text, is_bookmarked boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE v_exists BOOLEAN;
BEGIN
  SELECT TRUE INTO v_exists
  FROM edoc.staff_notes
  WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;

  IF v_exists THEN
    DELETE FROM edoc.staff_notes
    WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;
    RETURN QUERY SELECT TRUE, 'Đã bỏ đánh dấu'::TEXT, FALSE;
  ELSE
    INSERT INTO edoc.staff_notes (doc_type, doc_id, staff_id, note, is_important)
    VALUES (p_doc_type, p_doc_id, p_staff_id, NULLIF(TRIM(p_note), ''), COALESCE(p_is_important, FALSE));
    RETURN QUERY SELECT TRUE, 'Đã đánh dấu'::TEXT, TRUE;
  END IF;
END;
$$;


--
-- Name: fn_staff_note_update_important(character varying, bigint, integer, boolean); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_staff_note_update_important(p_doc_type character varying, p_doc_id bigint, p_staff_id integer, p_is_important boolean) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE edoc.staff_notes SET
    is_important = p_is_important
  WHERE doc_type = p_doc_type AND doc_id = p_doc_id AND staff_id = p_staff_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy đánh dấu'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT TRUE,
    CASE WHEN p_is_important THEN 'Đã đánh dấu quan trọng'::TEXT
    ELSE 'Đã bỏ đánh dấu quan trọng'::TEXT END;
END;
$$;


--
-- Name: fn_vote_answer_create(uuid, integer, character varying, integer, boolean); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_vote_answer_create(p_question_id uuid, p_room_schedule_id integer, p_name character varying, p_order_no integer, p_is_other boolean) RETURNS TABLE(success boolean, message text, id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id UUID;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Nội dung đáp án không được để trống'::TEXT, NULL::UUID;
    RETURN;
  END IF;

  INSERT INTO edoc.room_schedule_answers (
    room_schedule_question_id, room_schedule_id, name, order_no, is_other
  ) VALUES (
    p_question_id, p_room_schedule_id, p_name,
    COALESCE(p_order_no, 0), COALESCE(p_is_other, false)
  ) RETURNING edoc.room_schedule_answers.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo đáp án thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_vote_cast(uuid, uuid, integer, text); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_vote_cast(p_question_id uuid, p_answer_id uuid, p_staff_id integer, p_other_text text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_q_status INT;
  v_room_schedule_id INT;
BEGIN
  SELECT q.status, q.room_schedule_id INTO v_q_status, v_room_schedule_id
  FROM edoc.room_schedule_questions q WHERE q.id = p_question_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy câu hỏi'::TEXT;
    RETURN;
  END IF;

  IF v_q_status <> 1 THEN
    RETURN QUERY SELECT false, 'Câu hỏi chưa mở biểu quyết'::TEXT;
    RETURN;
  END IF;

  INSERT INTO edoc.room_schedule_votes (room_schedule_id, question_id, answer_id, staff_id, other_text)
  VALUES (v_room_schedule_id, p_question_id, p_answer_id, p_staff_id, p_other_text)
  ON CONFLICT (question_id, staff_id) DO UPDATE SET
    answer_id  = EXCLUDED.answer_id,
    other_text = EXCLUDED.other_text,
    voted_at   = NOW();

  RETURN QUERY SELECT true, 'Biểu quyết thành công'::TEXT;
END;
$$;


--
-- Name: fn_vote_get_results(uuid); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_vote_get_results(p_question_id uuid) RETURNS TABLE(answer_id uuid, answer_name character varying, order_no integer, vote_count bigint, voter_names text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    a.id AS answer_id,
    a.name AS answer_name,
    a.order_no,
    COUNT(v.id) AS vote_count,
    STRING_AGG(
      (s.last_name || ' ' || s.first_name),
      ', ' ORDER BY s.last_name
    ) AS voter_names
  FROM edoc.room_schedule_answers a
  LEFT JOIN edoc.room_schedule_votes v ON v.answer_id = a.id AND v.question_id = p_question_id
  LEFT JOIN public.staff s ON s.id = v.staff_id
  WHERE a.room_schedule_question_id = p_question_id
  GROUP BY a.id, a.name, a.order_no
  ORDER BY a.order_no;
END;
$$;


--
-- Name: fn_vote_question_create(integer, character varying, integer, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_vote_question_create(p_room_schedule_id integer, p_name character varying, p_question_type integer, p_duration integer, p_order_no integer) RETURNS TABLE(success boolean, message text, id uuid)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id UUID;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Nội dung câu hỏi không được để trống'::TEXT, NULL::UUID;
    RETURN;
  END IF;

  INSERT INTO edoc.room_schedule_questions (
    room_schedule_id, name, question_type, duration, order_no
  ) VALUES (
    p_room_schedule_id, p_name, COALESCE(p_question_type, 0),
    COALESCE(p_duration, 60), COALESCE(p_order_no, 0)
  ) RETURNING edoc.room_schedule_questions.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo câu hỏi thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_vote_question_get_list(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_vote_question_get_list(p_room_schedule_id integer) RETURNS TABLE(id uuid, room_schedule_id integer, name character varying, start_time timestamp with time zone, stop_time timestamp with time zone, duration integer, status integer, question_type integer, order_no integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    q.id, q.room_schedule_id, q.name, q.start_time, q.stop_time,
    q.duration, q.status, q.question_type, q.order_no
  FROM edoc.room_schedule_questions q
  WHERE q.room_schedule_id = p_room_schedule_id
  ORDER BY q.order_no, q.start_time;
END;
$$;


--
-- Name: fn_vote_question_start(uuid); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_vote_question_start(p_question_id uuid) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM edoc.room_schedule_questions WHERE id = p_question_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy câu hỏi'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Câu hỏi đã bắt đầu hoặc kết thúc'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.room_schedule_questions SET
    status     = 1,
    start_time = NOW()
  WHERE id = p_question_id;

  RETURN QUERY SELECT true, 'Bắt đầu biểu quyết thành công'::TEXT;
END;
$$;


--
-- Name: fn_vote_question_stop(uuid); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_vote_question_stop(p_question_id uuid) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM edoc.room_schedule_questions WHERE id = p_question_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy câu hỏi'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 1 THEN
    RETURN QUERY SELECT false, 'Câu hỏi không đang trong trạng thái biểu quyết'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.room_schedule_questions SET
    status    = 2,
    stop_time = NOW()
  WHERE id = p_question_id;

  RETURN QUERY SELECT true, 'Kết thúc biểu quyết thành công'::TEXT;
END;
$$;


--
-- Name: fn_work_group_assign_members(integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_work_group_assign_members(p_group_id integer, p_staff_ids integer[]) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.work_groups WHERE id = p_group_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy nhóm'::TEXT;
    RETURN;
  END IF;

  -- Delete old members
  DELETE FROM edoc.work_group_members WHERE group_id = p_group_id;

  -- Insert new members
  IF p_staff_ids IS NOT NULL AND array_length(p_staff_ids, 1) > 0 THEN
    INSERT INTO edoc.work_group_members (group_id, staff_id)
    SELECT p_group_id, unnest(p_staff_ids)
    ON CONFLICT (group_id, staff_id) DO NOTHING;
  END IF;

  RETURN QUERY SELECT TRUE, 'Cap nhat thanh vien thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_work_group_create(integer, character varying, text, integer, integer, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_work_group_create(p_unit_id integer DEFAULT NULL::integer, p_name character varying DEFAULT NULL::character varying, p_function text DEFAULT NULL::text, p_sort_order integer DEFAULT 0, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được vượt quá 200 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  IF EXISTS(
    SELECT 1 FROM edoc.work_groups
    WHERE unit_id = v_unit_id AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm đã tồn tại trong đơn vị'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO edoc.work_groups (unit_id, name, function, sort_order, created_by)
  VALUES (v_unit_id, TRIM(p_name), p_function, p_sort_order, p_created_by)
  RETURNING work_groups.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao nhom thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_work_group_delete(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_work_group_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM edoc.work_groups WHERE id = p_id AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy nhóm'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.work_groups SET is_deleted = TRUE WHERE id = p_id;
  -- Also remove members
  DELETE FROM edoc.work_group_members WHERE group_id = p_id;

  RETURN QUERY SELECT TRUE, 'Xoa nhom thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_work_group_get_by_id(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_work_group_get_by_id(p_id integer) RETURNS TABLE(id integer, unit_id integer, name character varying, function text, sort_order integer, created_by integer, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT g.id, g.unit_id, g.name::VARCHAR, g.function,
         g.sort_order, g.created_by, g.created_at
  FROM edoc.work_groups g
  WHERE g.id = p_id AND g.is_deleted = FALSE;
$$;


--
-- Name: fn_work_group_get_list(integer, integer[]); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_work_group_get_list(p_unit_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id integer, unit_id integer, name character varying, function text, sort_order integer, member_count bigint, created_by integer, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT g.id, g.unit_id, g.name::VARCHAR, g.function,
         g.sort_order,
         (SELECT COUNT(*) FROM edoc.work_group_members m WHERE m.group_id = g.id) AS member_count,
         g.created_by, g.created_at
  FROM edoc.work_groups g
  WHERE g.unit_id = p_unit_id AND g.is_deleted = FALSE
  ORDER BY g.sort_order, g.name;
$$;


--
-- Name: fn_work_group_get_members(integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_work_group_get_members(p_group_id integer) RETURNS TABLE(id integer, group_id integer, staff_id integer, staff_name character varying, position_name character varying, department_name character varying, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT m.id, m.group_id, m.staff_id,
         s.full_name::VARCHAR AS staff_name,
         p.name::VARCHAR AS position_name,
         d.name::VARCHAR AS department_name,
         m.created_at
  FROM edoc.work_group_members m
    JOIN public.staff s ON s.id = m.staff_id
    LEFT JOIN public.positions p ON p.id = s.position_id
    LEFT JOIN public.departments d ON d.id = s.department_id
  WHERE m.group_id = p_group_id
  ORDER BY s.full_name;
$$;


--
-- Name: fn_work_group_update(integer, character varying, text, integer); Type: FUNCTION; Schema: edoc; Owner: -
--

CREATE FUNCTION edoc.fn_work_group_update(p_id integer, p_name character varying DEFAULT NULL::character varying, p_function text DEFAULT NULL::text, p_sort_order integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_unit_id INT;
BEGIN
  SELECT unit_id INTO v_unit_id FROM edoc.work_groups WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy nhóm'::TEXT;
    RETURN;
  END IF;

  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_name) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  -- Check unique name (exclude self)
  IF EXISTS(
    SELECT 1 FROM edoc.work_groups
    WHERE unit_id = v_unit_id AND LOWER(TRIM(name)) = LOWER(TRIM(p_name))
      AND id <> p_id AND is_deleted = FALSE
  ) THEN
    RETURN QUERY SELECT FALSE, 'Tên nhóm đã tồn tại trong đơn vị'::TEXT;
    RETURN;
  END IF;

  UPDATE edoc.work_groups SET
    name       = TRIM(p_name),
    function   = COALESCE(p_function, function),
    sort_order = COALESCE(p_sort_order, sort_order)
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cap nhat nhom thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_borrow_request_approve(bigint, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_borrow_request_approve(p_id bigint, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Yêu cầu không ở trạng thái chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = 1,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Duyệt yêu cầu thành công'::TEXT;
END;
$$;


--
-- Name: fn_borrow_request_checkout(bigint, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_borrow_request_checkout(p_id bigint, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 1 THEN
    RETURN QUERY SELECT false, 'Yêu cầu chưa được duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = 2,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Xác nhận mượn thành công'::TEXT;
END;
$$;


--
-- Name: fn_borrow_request_create(character varying, integer, integer, text, date, integer, integer[], integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_borrow_request_create(p_name character varying, p_unit_id integer, p_emergency integer, p_notice text, p_borrow_date date, p_created_user_id integer, p_record_ids integer[], p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id BIGINT; v_record_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên yêu cầu không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO esto.borrow_requests (name, unit_id, department_id, emergency, notice, borrow_date, created_user_id, status)
  VALUES (p_name, v_unit_id, p_department_id, p_emergency, p_notice, p_borrow_date, p_created_user_id, 0)
  RETURNING esto.borrow_requests.id INTO v_id;

  IF p_record_ids IS NOT NULL THEN
    FOREACH v_record_id IN ARRAY p_record_ids LOOP
      INSERT INTO esto.borrow_request_records (borrow_request_id, record_id)
      VALUES (v_id, v_record_id)
      ON CONFLICT (borrow_request_id, record_id) DO NOTHING;
    END LOOP;
  END IF;

  RETURN QUERY SELECT true, 'Tạo yêu cầu mượn thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_borrow_request_get_by_id(bigint); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_borrow_request_get_by_id(p_id bigint) RETURNS TABLE(id bigint, name character varying, unit_id integer, emergency integer, notice text, borrow_date date, status integer, created_user_id integer, creator_name text, created_date timestamp with time zone, modified_user_id integer, modified_date timestamp with time zone, record_id bigint, record_title character varying, return_date date, actual_return_date date)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    br.id,
    br.name,
    br.unit_id,
    br.emergency,
    br.notice,
    br.borrow_date,
    br.status,
    br.created_user_id,
    (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
    br.created_date,
    br.modified_user_id,
    br.modified_date,
    r.id AS record_id,
    r.title AS record_title,
    brr.return_date,
    brr.actual_return_date
  FROM esto.borrow_requests br
  LEFT JOIN public.staff s ON s.id = br.created_user_id
  LEFT JOIN esto.borrow_request_records brr ON brr.borrow_request_id = br.id
  LEFT JOIN esto.records r ON r.id = brr.record_id
  WHERE br.id = p_id;
END;
$$;


--
-- Name: fn_borrow_request_get_list(integer, integer, text, integer, integer, integer[]); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_borrow_request_get_list(p_unit_id integer, p_status integer, p_keyword text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, name character varying, unit_id integer, emergency integer, notice text, borrow_date date, status integer, created_user_id integer, creator_name text, created_date timestamp with time zone, record_count bigint, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT br.id, br.name, br.unit_id, br.emergency, br.notice, br.borrow_date,
      br.status, br.created_user_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
      br.created_date,
      (SELECT COUNT(*) FROM esto.borrow_request_records brr WHERE brr.borrow_request_id = br.id) AS record_count
    FROM esto.borrow_requests br
    LEFT JOIN public.staff s ON s.id = br.created_user_id
    WHERE br.unit_id = p_unit_id
      AND (p_dept_ids IS NULL OR br.department_id = ANY(p_dept_ids))
      AND (p_status IS NULL OR p_status = -99 OR br.status = p_status)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR br.name ILIKE '%' || p_keyword || '%')
  )
  SELECT flt.*, COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;


--
-- Name: fn_borrow_request_reject(bigint, integer, text); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_borrow_request_reject(p_id bigint, p_modified_user_id integer, p_notice text) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 0 THEN
    RETURN QUERY SELECT false, 'Yêu cầu không ở trạng thái chờ duyệt'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = -1,
    notice           = COALESCE(p_notice, notice),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT true, 'Từ chối yêu cầu thành công'::TEXT;
END;
$$;


--
-- Name: fn_borrow_request_return(bigint, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_borrow_request_return(p_id bigint, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_status INT;
BEGIN
  SELECT status INTO v_status FROM esto.borrow_requests WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy yêu cầu mượn'::TEXT;
    RETURN;
  END IF;

  IF v_status <> 2 THEN
    RETURN QUERY SELECT false, 'Yêu cầu chưa ở trạng thái đang mượn'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.borrow_requests SET
    status           = 3,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  UPDATE esto.borrow_request_records SET
    actual_return_date = CURRENT_DATE
  WHERE borrow_request_id = p_id;

  RETURN QUERY SELECT true, 'Xác nhận trả thành công'::TEXT;
END;
$$;


--
-- Name: fn_document_archive_create(character varying, bigint, integer, integer, bigint, character varying, character varying, integer, character varying, text, text, character varying, character varying, boolean, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_document_archive_create(p_doc_type character varying, p_doc_id bigint, p_fond_id integer DEFAULT NULL::integer, p_warehouse_id integer DEFAULT NULL::integer, p_record_id bigint DEFAULT NULL::bigint, p_file_catalog character varying DEFAULT NULL::character varying, p_file_notation character varying DEFAULT NULL::character varying, p_doc_ordinal integer DEFAULT NULL::integer, p_language character varying DEFAULT 'Tiếng Việt'::character varying, p_autograph text DEFAULT NULL::text, p_keyword text DEFAULT NULL::text, p_format character varying DEFAULT 'Điện tử'::character varying, p_confidence_level character varying DEFAULT NULL::character varying, p_is_original boolean DEFAULT true, p_archived_by integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id BIGINT;
BEGIN
  IF p_doc_type NOT IN ('incoming', 'outgoing') THEN
    RETURN QUERY SELECT FALSE, 'Loại văn bản không hợp lệ'::TEXT, 0::BIGINT;
    RETURN;
  END IF;

  IF p_doc_type = 'incoming' AND NOT EXISTS (SELECT 1 FROM edoc.incoming_docs ind WHERE ind.id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đến'::TEXT, 0::BIGINT; RETURN;
  END IF;
  IF p_doc_type = 'outgoing' AND NOT EXISTS (SELECT 1 FROM edoc.outgoing_docs od WHERE od.id = p_doc_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy văn bản đi'::TEXT, 0::BIGINT; RETURN;
  END IF;

  INSERT INTO esto.document_archives (
    doc_type, doc_id, fond_id, warehouse_id, record_id,
    file_catalog, file_notation, doc_ordinal, language,
    autograph, keyword, format, confidence_level, is_original, archived_by
  ) VALUES (
    p_doc_type, p_doc_id, p_fond_id, p_warehouse_id, p_record_id,
    NULLIF(TRIM(p_file_catalog), ''), NULLIF(TRIM(p_file_notation), ''), p_doc_ordinal,
    COALESCE(p_language, 'Tiếng Việt'),
    NULLIF(TRIM(p_autograph), ''), NULLIF(TRIM(p_keyword), ''),
    COALESCE(p_format, 'Điện tử'), NULLIF(TRIM(p_confidence_level), ''),
    COALESCE(p_is_original, true), p_archived_by
  )
  ON CONFLICT (doc_type, doc_id) DO UPDATE SET
    fond_id = EXCLUDED.fond_id, warehouse_id = EXCLUDED.warehouse_id,
    record_id = EXCLUDED.record_id, file_catalog = EXCLUDED.file_catalog,
    file_notation = EXCLUDED.file_notation, doc_ordinal = EXCLUDED.doc_ordinal,
    language = EXCLUDED.language, autograph = EXCLUDED.autograph,
    keyword = EXCLUDED.keyword, format = EXCLUDED.format,
    confidence_level = EXCLUDED.confidence_level, is_original = EXCLUDED.is_original,
    archived_by = EXCLUDED.archived_by, archive_date = NOW()
  RETURNING document_archives.id INTO v_id;

  -- Cập nhật archive_status trên VB gốc
  IF p_doc_type = 'incoming' THEN
    UPDATE edoc.incoming_docs SET archive_status = true WHERE edoc.incoming_docs.id = p_doc_id;
  ELSIF p_doc_type = 'outgoing' THEN
    UPDATE edoc.outgoing_docs SET archive_status = true WHERE edoc.outgoing_docs.id = p_doc_id;
  END IF;

  RETURN QUERY SELECT TRUE, 'Chuyển lưu trữ thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_document_archive_get_by_doc(character varying, bigint); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_document_archive_get_by_doc(p_doc_type character varying, p_doc_id bigint) RETURNS TABLE(id bigint, fond_id integer, fond_name character varying, warehouse_id integer, warehouse_name character varying, record_id bigint, record_name character varying, file_catalog character varying, file_notation character varying, doc_ordinal integer, language character varying, autograph text, keyword text, format character varying, confidence_level character varying, is_original boolean, archive_date timestamp with time zone, archived_by_name character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT a.id, a.fond_id, f.name, a.warehouse_id, w.name,
         a.record_id, r.name, a.file_catalog, a.file_notation,
         a.doc_ordinal, a.language, a.autograph, a.keyword,
         a.format, a.confidence_level, a.is_original,
         a.archive_date, s.full_name
  FROM esto.document_archives a
  LEFT JOIN esto.fonds f ON f.id = a.fond_id
  LEFT JOIN esto.warehouses w ON w.id = a.warehouse_id
  LEFT JOIN esto.records r ON r.id = a.record_id
  LEFT JOIN public.staff s ON s.id = a.archived_by
  WHERE a.doc_type = p_doc_type AND a.doc_id = p_doc_id;
END;
$$;


--
-- Name: fn_fond_create(integer, integer, character varying, character varying, text, character varying, numeric, numeric, character varying, character varying, character varying, character varying, numeric, integer, text, numeric, integer, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_fond_create(p_unit_id integer, p_parent_id integer, p_fond_code character varying, p_fond_name character varying, p_fond_history text, p_archives_time character varying, p_paper_total numeric, p_paper_digital numeric, p_keys_group character varying, p_other_type character varying, p_language character varying, p_lookup_tools character varying, p_coppy_number numeric, p_status integer, p_description text, p_version numeric, p_created_user_id integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_fond_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phông không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO esto.fonds (
    unit_id, parent_id, fond_code, fond_name, fond_history, archives_time,
    paper_total, paper_digital, keys_group, other_type, language,
    lookup_tools, coppy_number, status, description, version, created_user_id
  ) VALUES (
    v_unit_id, COALESCE(p_parent_id, 0), NULLIF(TRIM(p_fond_code),''),
    p_fond_name, p_fond_history, p_archives_time, p_paper_total, p_paper_digital,
    p_keys_group, p_other_type, p_language, p_lookup_tools, p_coppy_number,
    COALESCE(p_status, 1), p_description, p_version, p_created_user_id
  ) RETURNING esto.fonds.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo phông thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phông đã tồn tại trong đơn vị'::TEXT, NULL::INT;
END;
$$;


--
-- Name: fn_fond_delete(integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_fond_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM esto.records WHERE fond_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Phông đang có hồ sơ, không thể xóa'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_count FROM esto.fonds WHERE parent_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Phông đang có phông con, không thể xóa'::TEXT;
    RETURN;
  END IF;

  DELETE FROM esto.fonds WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy phông'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa phông thành công'::TEXT;
END;
$$;


--
-- Name: fn_fond_get_by_id(integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_fond_get_by_id(p_id integer) RETURNS TABLE(id integer, unit_id integer, parent_id integer, fond_code character varying, fond_name character varying, fond_history text, archives_time character varying, paper_total numeric, paper_digital numeric, keys_group character varying, other_type character varying, language character varying, lookup_tools character varying, coppy_number numeric, status integer, description text, version numeric, created_date timestamp with time zone, modified_user_id integer, modified_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    f.id, f.unit_id, f.parent_id, f.fond_code, f.fond_name,
    f.fond_history, f.archives_time, f.paper_total, f.paper_digital,
    f.keys_group, f.other_type, f.language, f.lookup_tools,
    f.coppy_number, f.status, f.description, f.version,
    f.created_date, f.modified_user_id, f.modified_date
  FROM esto.fonds f
  WHERE f.id = p_id;
END;
$$;


--
-- Name: fn_fond_get_tree(integer, integer[]); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_fond_get_tree(p_unit_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id integer, unit_id integer, parent_id integer, fond_code character varying, fond_name character varying, fond_history text, archives_time character varying, paper_total numeric, paper_digital numeric, keys_group character varying, other_type character varying, language character varying, lookup_tools character varying, coppy_number numeric, status integer, description text, version numeric, created_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT f.id, f.unit_id, f.parent_id, f.fond_code, f.fond_name,
    f.fond_history, f.archives_time, f.paper_total, f.paper_digital,
    f.keys_group, f.other_type, f.language, f.lookup_tools, f.coppy_number,
    f.status, f.description, f.version, f.created_date
  FROM esto.fonds f
  WHERE f.unit_id = p_unit_id
  ORDER BY f.parent_id, f.fond_name;
END;
$$;


--
-- Name: fn_fond_update(integer, integer, character varying, character varying, text, character varying, numeric, numeric, character varying, character varying, character varying, character varying, numeric, integer, text, numeric, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_fond_update(p_id integer, p_parent_id integer, p_fond_code character varying, p_fond_name character varying, p_fond_history text, p_archives_time character varying, p_paper_total numeric, p_paper_digital numeric, p_keys_group character varying, p_other_type character varying, p_language character varying, p_lookup_tools character varying, p_coppy_number numeric, p_status integer, p_description text, p_version numeric, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TRIM(COALESCE(p_fond_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên phông không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.fonds SET
    parent_id        = COALESCE(p_parent_id, 0),
    fond_code        = NULLIF(TRIM(p_fond_code),''),
    fond_name        = p_fond_name,
    fond_history     = p_fond_history,
    archives_time    = p_archives_time,
    paper_total      = p_paper_total,
    paper_digital    = p_paper_digital,
    keys_group       = p_keys_group,
    other_type       = p_other_type,
    language         = p_language,
    lookup_tools     = p_lookup_tools,
    coppy_number     = p_coppy_number,
    status           = COALESCE(p_status, 1),
    description      = p_description,
    version          = p_version,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy phông'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã phông đã tồn tại trong đơn vị'::TEXT;
END;
$$;


--
-- Name: fn_get_fonds_list(integer, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_get_fonds_list(p_unit_id integer DEFAULT NULL::integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, name character varying, code character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY SELECT f.id, f.fond_name, f.fond_code FROM esto.fonds f
  WHERE (v_unit_id IS NULL OR f.unit_id = v_unit_id)
  ORDER BY f.fond_name;
END;
$$;


--
-- Name: fn_get_warehouses_list(integer, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_get_warehouses_list(p_unit_id integer DEFAULT NULL::integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, name character varying, code character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY SELECT w.id, w.name, w.code FROM esto.warehouses w
  WHERE (v_unit_id IS NULL OR w.unit_id = v_unit_id)
  ORDER BY w.name;
END;
$$;


--
-- Name: fn_record_create(integer, integer, integer, character varying, integer, character varying, character varying, character varying, character varying, character varying, date, date, integer, text, character varying, character varying, numeric, numeric, integer, date, integer, date, integer, character varying, boolean, integer, integer, integer, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_record_create(p_unit_id integer, p_fond_id integer, p_warehouse_id integer, p_file_code character varying, p_file_catalog integer, p_file_notation character varying, p_title character varying, p_maintenance character varying, p_rights character varying, p_language character varying, p_start_date date, p_complete_date date, p_total_doc integer, p_description text, p_infor_sign character varying, p_keyword character varying, p_total_paper numeric, p_page_number numeric, p_format integer, p_archive_date date, p_in_charge_staff_id integer, p_reception_date date, p_reception_from integer, p_transfer_staff character varying, p_is_document_original boolean, p_number_of_copy integer, p_doc_field_id integer, p_created_user_id integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề hồ sơ không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO esto.records (
    unit_id, department_id, fond_id, warehouse_id, file_code, file_catalog, file_notation,
    title, maintenance, rights, language, start_date, complete_date, total_doc,
    description, infor_sign, keyword, total_paper, page_number, format,
    archive_date, in_charge_staff_id, reception_date, reception_from,
    transfer_staff, is_document_original, number_of_copy, doc_field_id,
    created_user_id
  ) VALUES (
    v_unit_id, p_department_id, p_fond_id, p_warehouse_id, p_file_code, p_file_catalog, p_file_notation,
    p_title, p_maintenance, p_rights, p_language, p_start_date, p_complete_date, p_total_doc,
    p_description, p_infor_sign, p_keyword, p_total_paper, p_page_number, COALESCE(p_format, 0),
    p_archive_date, p_in_charge_staff_id, p_reception_date, COALESCE(p_reception_from, 0),
    p_transfer_staff, p_is_document_original, p_number_of_copy, p_doc_field_id,
    p_created_user_id
  ) RETURNING esto.records.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo hồ sơ thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_record_delete(bigint); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_record_delete(p_id bigint) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM esto.borrow_request_records WHERE record_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Hồ sơ đang có yêu cầu mượn, không thể xóa'::TEXT;
    RETURN;
  END IF;

  DELETE FROM esto.records WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hồ sơ'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa hồ sơ thành công'::TEXT;
END;
$$;


--
-- Name: fn_record_get_by_id(bigint); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_record_get_by_id(p_id bigint) RETURNS TABLE(id bigint, unit_id integer, fond_id integer, fond_name character varying, file_code character varying, file_catalog integer, file_notation character varying, title character varying, maintenance character varying, rights character varying, language character varying, start_date date, complete_date date, total_doc integer, description text, infor_sign character varying, keyword character varying, total_paper numeric, page_number numeric, format integer, archive_date date, reception_archive_id integer, in_charge_staff_id integer, parent_id integer, warehouse_id integer, warehouse_name character varying, reception_date date, reception_from integer, transfer_staff character varying, is_document_original boolean, number_of_copy integer, doc_field_id integer, transfer_online_status boolean, created_user_id integer, created_date timestamp with time zone, modified_user_id integer, modified_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    r.id,
    r.unit_id,
    r.fond_id,
    f.fond_name,
    r.file_code,
    r.file_catalog,
    r.file_notation,
    r.title,
    r.maintenance,
    r.rights,
    r.language,
    r.start_date,
    r.complete_date,
    r.total_doc,
    r.description,
    r.infor_sign,
    r.keyword,
    r.total_paper,
    r.page_number,
    r.format,
    r.archive_date,
    r.reception_archive_id,
    r.in_charge_staff_id,
    r.parent_id,
    r.warehouse_id,
    w.name AS warehouse_name,
    r.reception_date,
    r.reception_from,
    r.transfer_staff,
    r.is_document_original,
    r.number_of_copy,
    r.doc_field_id,
    r.transfer_online_status,
    r.created_user_id,
    r.created_date,
    r.modified_user_id,
    r.modified_date
  FROM esto.records r
  LEFT JOIN esto.fonds f ON f.id = r.fond_id
  LEFT JOIN esto.warehouses w ON w.id = r.warehouse_id
  WHERE r.id = p_id;
END;
$$;


--
-- Name: fn_record_get_list(integer, integer, integer, text, integer, integer, integer[]); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_record_get_list(p_unit_id integer, p_fond_id integer, p_warehouse_id integer, p_keyword text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, unit_id integer, fond_id integer, fond_name character varying, file_code character varying, file_catalog integer, file_notation character varying, title character varying, maintenance character varying, rights character varying, language character varying, start_date date, complete_date date, total_doc integer, description text, infor_sign character varying, keyword character varying, total_paper numeric, page_number numeric, format integer, archive_date date, in_charge_staff_id integer, warehouse_id integer, warehouse_name character varying, transfer_online_status boolean, created_date timestamp with time zone, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT r.id, r.unit_id, r.fond_id, f.fond_name, r.file_code, r.file_catalog,
      r.file_notation, r.title, r.maintenance, r.rights, r.language,
      r.start_date, r.complete_date, r.total_doc, r.description, r.infor_sign,
      r.keyword, r.total_paper, r.page_number, r.format, r.archive_date,
      r.in_charge_staff_id, r.warehouse_id, w.name AS warehouse_name,
      r.transfer_online_status, r.created_date
    FROM esto.records r
    LEFT JOIN esto.fonds f ON f.id = r.fond_id
    LEFT JOIN esto.warehouses w ON w.id = r.warehouse_id
    WHERE r.unit_id = p_unit_id
      AND (p_dept_ids IS NULL OR r.department_id = ANY(p_dept_ids))
      AND (p_fond_id IS NULL OR r.fond_id = p_fond_id)
      AND (p_warehouse_id IS NULL OR r.warehouse_id = p_warehouse_id)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           r.title ILIKE '%' || p_keyword || '%' OR r.file_code ILIKE '%' || p_keyword || '%')
  )
  SELECT flt.*, COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;


--
-- Name: fn_record_update(bigint, integer, integer, character varying, integer, character varying, character varying, character varying, character varying, character varying, date, date, integer, text, character varying, character varying, numeric, numeric, integer, date, integer, date, integer, character varying, boolean, integer, integer, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_record_update(p_id bigint, p_fond_id integer, p_warehouse_id integer, p_file_code character varying, p_file_catalog integer, p_file_notation character varying, p_title character varying, p_maintenance character varying, p_rights character varying, p_language character varying, p_start_date date, p_complete_date date, p_total_doc integer, p_description text, p_infor_sign character varying, p_keyword character varying, p_total_paper numeric, p_page_number numeric, p_format integer, p_archive_date date, p_in_charge_staff_id integer, p_reception_date date, p_reception_from integer, p_transfer_staff character varying, p_is_document_original boolean, p_number_of_copy integer, p_doc_field_id integer, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề hồ sơ không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.records SET
    fond_id               = p_fond_id,
    warehouse_id          = p_warehouse_id,
    file_code             = p_file_code,
    file_catalog          = p_file_catalog,
    file_notation         = p_file_notation,
    title                 = p_title,
    maintenance           = p_maintenance,
    rights                = p_rights,
    language              = p_language,
    start_date            = p_start_date,
    complete_date         = p_complete_date,
    total_doc             = p_total_doc,
    description           = p_description,
    infor_sign            = p_infor_sign,
    keyword               = p_keyword,
    total_paper           = p_total_paper,
    page_number           = p_page_number,
    format                = COALESCE(p_format, 0),
    archive_date          = p_archive_date,
    in_charge_staff_id    = p_in_charge_staff_id,
    reception_date        = p_reception_date,
    reception_from        = COALESCE(p_reception_from, 0),
    transfer_staff        = p_transfer_staff,
    is_document_original  = p_is_document_original,
    number_of_copy        = p_number_of_copy,
    doc_field_id          = p_doc_field_id,
    modified_user_id      = p_modified_user_id,
    modified_date         = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy hồ sơ'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;


--
-- Name: fn_warehouse_create(integer, integer, character varying, character varying, character varying, character varying, boolean, text, integer, boolean, integer, integer, character varying, integer, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_warehouse_create(p_unit_id integer, p_type_id integer, p_code character varying, p_name character varying, p_phone_number character varying, p_address character varying, p_status boolean, p_description text, p_parent_id integer, p_is_unit boolean, p_warehouse_level integer, p_limit_child integer, p_position character varying, p_created_user_id integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên kho không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO esto.warehouses (
    unit_id, department_id, type_id, code, name, phone_number, address, status,
    description, parent_id, is_unit, warehouse_level, limit_child,
    "position", created_user_id
  ) VALUES (
    v_unit_id, p_department_id, p_type_id, NULLIF(TRIM(p_code),''), p_name, p_phone_number,
    p_address, COALESCE(p_status, true), p_description,
    COALESCE(p_parent_id, 0), COALESCE(p_is_unit, false),
    COALESCE(p_warehouse_level, 0), COALESCE(p_limit_child, 0),
    p_position, p_created_user_id
  ) RETURNING esto.warehouses.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo kho thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã kho đã tồn tại trong đơn vị'::TEXT, NULL::INT;
END;
$$;


--
-- Name: fn_warehouse_delete(integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_warehouse_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM esto.records WHERE warehouse_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Kho đang có hồ sơ, không thể xóa'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_count FROM esto.warehouses WHERE parent_id = p_id AND is_deleted = false;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Kho đang có kho con, không thể xóa'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.warehouses SET is_deleted = true WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy kho'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa kho thành công'::TEXT;
END;
$$;


--
-- Name: fn_warehouse_get_by_id(integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_warehouse_get_by_id(p_id integer) RETURNS TABLE(id integer, unit_id integer, type_id integer, code character varying, name character varying, phone_number character varying, address character varying, status boolean, description text, parent_id integer, is_unit boolean, warehouse_level integer, limit_child integer, "position" character varying, created_user_id integer, created_date timestamp with time zone, modified_user_id integer, modified_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    w.id,
    w.unit_id,
    w.type_id,
    w.code,
    w.name,
    w.phone_number,
    w.address,
    w.status,
    w.description,
    w.parent_id,
    w.is_unit,
    w.warehouse_level,
    w.limit_child,
    w."position",
    w.created_user_id,
    w.created_date,
    w.modified_user_id,
    w.modified_date
  FROM esto.warehouses w
  WHERE w.id = p_id AND w.is_deleted = false;
END;
$$;


--
-- Name: fn_warehouse_get_tree(integer, integer[]); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_warehouse_get_tree(p_unit_id integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id integer, unit_id integer, type_id integer, code character varying, name character varying, phone_number character varying, address character varying, status boolean, description text, parent_id integer, is_unit boolean, warehouse_level integer, limit_child integer, "position" character varying, created_user_id integer, created_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT w.id, w.unit_id, w.type_id, w.code, w.name, w.phone_number, w.address,
    w.status, w.description, w.parent_id, w.is_unit, w.warehouse_level,
    w.limit_child, w."position", w.created_user_id, w.created_date
  FROM esto.warehouses w
  WHERE w.unit_id = p_unit_id AND w.is_deleted = false
    AND (p_dept_ids IS NULL OR w.department_id = ANY(p_dept_ids))
  ORDER BY w.parent_id, w.name;
END;
$$;


--
-- Name: fn_warehouse_update(integer, integer, character varying, character varying, character varying, character varying, boolean, text, integer, boolean, integer, integer, character varying, integer); Type: FUNCTION; Schema: esto; Owner: -
--

CREATE FUNCTION esto.fn_warehouse_update(p_id integer, p_type_id integer, p_code character varying, p_name character varying, p_phone_number character varying, p_address character varying, p_status boolean, p_description text, p_parent_id integer, p_is_unit boolean, p_warehouse_level integer, p_limit_child integer, p_position character varying, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên kho không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE esto.warehouses SET
    type_id          = p_type_id,
    code             = NULLIF(TRIM(p_code),''),
    name             = p_name,
    phone_number     = p_phone_number,
    address          = p_address,
    status           = COALESCE(p_status, true),
    description      = p_description,
    parent_id        = COALESCE(p_parent_id, 0),
    is_unit          = COALESCE(p_is_unit, false),
    warehouse_level  = COALESCE(p_warehouse_level, 0),
    limit_child      = COALESCE(p_limit_child, 0),
    "position"       = p_position,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy kho'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã kho đã tồn tại trong đơn vị'::TEXT;
END;
$$;


--
-- Name: fn_doc_category_create(integer, character varying, character varying, numeric, text, numeric, integer, integer); Type: FUNCTION; Schema: iso; Owner: -
--

CREATE FUNCTION iso.fn_doc_category_create(p_parent_id integer, p_code character varying, p_name character varying, p_date_process numeric, p_description text, p_version numeric, p_unit_id integer, p_created_user_id integer) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id INT;
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên danh mục không được để trống'::TEXT, NULL::INT;
    RETURN;
  END IF;

  INSERT INTO iso.document_categories (
    parent_id, code, name, date_process, description, version, unit_id, created_user_id
  ) VALUES (
    COALESCE(p_parent_id, 0), NULLIF(TRIM(p_code),''), p_name,
    p_date_process, p_description, p_version, p_unit_id, p_created_user_id
  ) RETURNING iso.document_categories.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo danh mục thành công'::TEXT, v_id;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã danh mục đã tồn tại'::TEXT, NULL::INT;
END;
$$;


--
-- Name: fn_doc_category_delete(integer); Type: FUNCTION; Schema: iso; Owner: -
--

CREATE FUNCTION iso.fn_doc_category_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM iso.document_categories WHERE parent_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Danh mục đang có danh mục con, không thể xóa'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_count FROM iso.documents WHERE category_id = p_id AND is_deleted = false;
  IF v_count > 0 THEN
    RETURN QUERY SELECT false, 'Danh mục đang có tài liệu, không thể xóa'::TEXT;
    RETURN;
  END IF;

  UPDATE iso.document_categories SET status = 0 WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy danh mục'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa danh mục thành công'::TEXT;
END;
$$;


--
-- Name: fn_doc_category_get_tree(integer, integer); Type: FUNCTION; Schema: iso; Owner: -
--

CREATE FUNCTION iso.fn_doc_category_get_tree(p_unit_id integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, parent_id integer, code character varying, name character varying, date_process numeric, status integer, description text, version numeric, unit_id integer, created_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_unit_id INT;
BEGIN
  IF p_dept_id IS NOT NULL THEN v_unit_id := public.fn_get_ancestor_unit(p_dept_id);
  ELSE v_unit_id := p_unit_id; END IF;

  RETURN QUERY
  SELECT dc.id, dc.parent_id, dc.code, dc.name, dc.date_process, dc.status,
    dc.description, dc.version, dc.unit_id, dc.created_date
  FROM iso.document_categories dc
  WHERE (dc.unit_id IS NULL OR dc.unit_id = v_unit_id) AND dc.status = 1
  ORDER BY dc.parent_id, dc.name;
END;
$$;


--
-- Name: fn_doc_category_update(integer, integer, character varying, character varying, numeric, integer, text, numeric, integer); Type: FUNCTION; Schema: iso; Owner: -
--

CREATE FUNCTION iso.fn_doc_category_update(p_id integer, p_parent_id integer, p_code character varying, p_name character varying, p_date_process numeric, p_status integer, p_description text, p_version numeric, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TRIM(COALESCE(p_name, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tên danh mục không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE iso.document_categories SET
    parent_id        = COALESCE(p_parent_id, 0),
    code             = NULLIF(TRIM(p_code),''),
    name             = p_name,
    date_process     = p_date_process,
    status           = COALESCE(p_status, 1),
    description      = p_description,
    version          = p_version,
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy danh mục'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
EXCEPTION
  WHEN unique_violation THEN
    RETURN QUERY SELECT false, 'Mã danh mục đã tồn tại'::TEXT;
END;
$$;


--
-- Name: fn_document_create(integer, integer, character varying, text, character varying, character varying, bigint, character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: iso; Owner: -
--

CREATE FUNCTION iso.fn_document_create(p_unit_id integer, p_category_id integer, p_title character varying, p_description text, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_mime_type character varying, p_keyword character varying, p_status integer, p_created_user_id integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề tài liệu không được để trống'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO iso.documents (
    unit_id, department_id, category_id, title, description, file_name, file_path,
    file_size, mime_type, keyword, status, created_user_id
  ) VALUES (
    v_unit_id, p_department_id, p_category_id, p_title, p_description, p_file_name, p_file_path,
    p_file_size, p_mime_type, p_keyword, COALESCE(p_status, 1), p_created_user_id
  ) RETURNING iso.documents.id INTO v_id;

  RETURN QUERY SELECT true, 'Tạo tài liệu thành công'::TEXT, v_id;
END;
$$;


--
-- Name: fn_document_delete(bigint); Type: FUNCTION; Schema: iso; Owner: -
--

CREATE FUNCTION iso.fn_document_delete(p_id bigint) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  UPDATE iso.documents SET is_deleted = true WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy tài liệu'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Xóa tài liệu thành công'::TEXT;
END;
$$;


--
-- Name: fn_document_get_by_id(bigint); Type: FUNCTION; Schema: iso; Owner: -
--

CREATE FUNCTION iso.fn_document_get_by_id(p_id bigint) RETURNS TABLE(id bigint, unit_id integer, category_id integer, category_name character varying, title character varying, description text, file_name character varying, file_path character varying, file_size bigint, mime_type character varying, keyword character varying, status integer, created_user_id integer, creator_name text, created_date timestamp with time zone, modified_user_id integer, modified_date timestamp with time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    d.id, d.unit_id, d.category_id, dc.name AS category_name,
    d.title, d.description, d.file_name, d.file_path, d.file_size,
    d.mime_type, d.keyword, d.status, d.created_user_id,
    (s.last_name || ' ' || s.first_name)::TEXT AS creator_name,
    d.created_date, d.modified_user_id, d.modified_date
  FROM iso.documents d
  LEFT JOIN iso.document_categories dc ON dc.id = d.category_id
  LEFT JOIN public.staff s ON s.id = d.created_user_id
  WHERE d.id = p_id AND d.is_deleted = false;
END;
$$;


--
-- Name: fn_document_get_list(integer, integer, text, integer, integer, integer[]); Type: FUNCTION; Schema: iso; Owner: -
--

CREATE FUNCTION iso.fn_document_get_list(p_unit_id integer, p_category_id integer, p_keyword text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, unit_id integer, category_id integer, category_name character varying, title character varying, description text, file_name character varying, file_path character varying, file_size bigint, mime_type character varying, keyword character varying, status integer, created_user_id integer, creator_name text, created_date timestamp with time zone, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  WITH filtered AS (
    SELECT d.id, d.unit_id, d.category_id, dc.name AS category_name,
      d.title, d.description, d.file_name, d.file_path, d.file_size,
      d.mime_type, d.keyword, d.status, d.created_user_id,
      (s.last_name || ' ' || s.first_name)::TEXT AS creator_name, d.created_date
    FROM iso.documents d
    LEFT JOIN iso.document_categories dc ON dc.id = d.category_id
    LEFT JOIN public.staff s ON s.id = d.created_user_id
    WHERE d.unit_id = p_unit_id AND d.is_deleted = false
      AND (p_dept_ids IS NULL OR d.department_id = ANY(p_dept_ids))
      AND (p_category_id IS NULL OR d.category_id = p_category_id)
      AND (p_keyword IS NULL OR TRIM(p_keyword) = '' OR
           d.title ILIKE '%' || p_keyword || '%' OR d.keyword ILIKE '%' || p_keyword || '%')
  )
  SELECT flt.*, COUNT(*) OVER() AS total_count
  FROM filtered flt
  ORDER BY flt.created_date DESC
  LIMIT p_page_size OFFSET v_offset;
END;
$$;


--
-- Name: fn_document_update(bigint, integer, character varying, text, character varying, character varying, bigint, character varying, character varying, integer, integer); Type: FUNCTION; Schema: iso; Owner: -
--

CREATE FUNCTION iso.fn_document_update(p_id bigint, p_category_id integer, p_title character varying, p_description text, p_file_name character varying, p_file_path character varying, p_file_size bigint, p_mime_type character varying, p_keyword character varying, p_status integer, p_modified_user_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  IF TRIM(COALESCE(p_title, '')) = '' THEN
    RETURN QUERY SELECT false, 'Tiêu đề tài liệu không được để trống'::TEXT;
    RETURN;
  END IF;

  UPDATE iso.documents SET
    category_id      = p_category_id,
    title            = p_title,
    description      = p_description,
    file_name        = COALESCE(p_file_name, file_name),
    file_path        = COALESCE(p_file_path, file_path),
    file_size        = COALESCE(p_file_size, file_size),
    mime_type        = COALESCE(p_mime_type, mime_type),
    keyword          = p_keyword,
    status           = COALESCE(p_status, status),
    modified_user_id = p_modified_user_id,
    modified_date    = NOW()
  WHERE id = p_id AND is_deleted = false;

  IF NOT FOUND THEN
    RETURN QUERY SELECT false, 'Không tìm thấy tài liệu'::TEXT;
    RETURN;
  END IF;

  RETURN QUERY SELECT true, 'Cập nhật thành công'::TEXT;
END;
$$;


--
-- Name: fn_auth_cleanup_expired_tokens(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auth_cleanup_expired_tokens() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_count INT;
BEGIN
  DELETE FROM public.refresh_tokens
  WHERE expires_at < NOW() OR revoked_at IS NOT NULL;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$;


--
-- Name: FUNCTION fn_auth_cleanup_expired_tokens(); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_auth_cleanup_expired_tokens() IS 'Dọn dẹp refresh token hết hạn hoặc đã revoke';


--
-- Name: fn_auth_get_me(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auth_get_me(p_staff_id integer) RETURNS TABLE(staff_id integer, username character varying, full_name character varying, email character varying, phone character varying, image character varying, is_admin boolean, gender smallint, birth_date date, address text, department_id integer, unit_id integer, position_id integer, position_name character varying, department_name character varying, unit_name character varying, roles text, last_login_at timestamp with time zone, created_at timestamp with time zone)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id              AS staff_id,
    s.username,
    s.full_name::VARCHAR,
    s.email::VARCHAR,
    COALESCE(s.phone, s.mobile)::VARCHAR AS phone,
    s.image::VARCHAR,
    s.is_admin,
    s.gender,
    s.birth_date,
    s.address,
    s.department_id,
    s.unit_id,
    s.position_id,
    p.name::VARCHAR   AS position_name,
    d.name::VARCHAR   AS department_name,
    u.name::VARCHAR   AS unit_name,
    COALESCE(
      (SELECT string_agg(r.name, ',')
       FROM public.role_of_staff ros
       JOIN public.roles r ON r.id = ros.role_id
       WHERE ros.staff_id = s.id),
      ''
    )::TEXT AS roles,
    s.last_login_at,
    s.created_at
  FROM public.staff s
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  WHERE s.id = p_staff_id
    AND s.is_deleted = FALSE
    AND s.is_locked = FALSE;
END;
$$;


--
-- Name: FUNCTION fn_auth_get_me(p_staff_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_auth_get_me(p_staff_id integer) IS 'Lấy đầy đủ thông tin profile của user hiện tại';


--
-- Name: fn_auth_log_login(integer, character varying, character varying, text, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auth_log_login(p_staff_id integer, p_username character varying, p_ip_address character varying, p_user_agent text, p_success boolean) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  INSERT INTO public.login_history (staff_id, username, ip_address, user_agent, success)
  VALUES (p_staff_id, p_username, p_ip_address, p_user_agent, p_success);

  -- Cập nhật last_login_at nếu thành công
  IF p_success AND p_staff_id IS NOT NULL THEN
    UPDATE public.staff SET last_login_at = NOW() WHERE id = p_staff_id;
  END IF;
END;
$$;


--
-- Name: FUNCTION fn_auth_log_login(p_staff_id integer, p_username character varying, p_ip_address character varying, p_user_agent text, p_success boolean); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_auth_log_login(p_staff_id integer, p_username character varying, p_ip_address character varying, p_user_agent text, p_success boolean) IS 'Ghi nhận lịch sử đăng nhập (thành công/thất bại)';


--
-- Name: fn_auth_login(character varying, character varying, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auth_login(p_username character varying, p_ip_address character varying DEFAULT NULL::character varying, p_user_agent text DEFAULT NULL::text) RETURNS TABLE(staff_id integer, username character varying, password_hash character varying, full_name character varying, email character varying, phone character varying, image character varying, is_admin boolean, is_locked boolean, is_deleted boolean, department_id integer, unit_id integer, position_name character varying, department_name character varying, unit_name character varying, roles text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id              AS staff_id,
    s.username,
    s.password_hash,
    s.full_name::VARCHAR,
    s.email::VARCHAR,
    COALESCE(s.phone, s.mobile)::VARCHAR AS phone,
    s.image::VARCHAR,
    s.is_admin,
    s.is_locked,
    s.is_deleted,
    s.department_id,
    s.unit_id,
    p.name::VARCHAR   AS position_name,
    d.name::VARCHAR   AS department_name,
    u.name::VARCHAR   AS unit_name,
    COALESCE(
      (SELECT string_agg(r.name, ',')
       FROM public.role_of_staff ros
       JOIN public.roles r ON r.id = ros.role_id
       WHERE ros.staff_id = s.id),
      ''
    )::TEXT AS roles
  FROM public.staff s
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  WHERE s.username = p_username;
END;
$$;


--
-- Name: FUNCTION fn_auth_login(p_username character varying, p_ip_address character varying, p_user_agent text); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_auth_login(p_username character varying, p_ip_address character varying, p_user_agent text) IS 'Lấy thông tin staff theo username để xác thực (password check ở app layer)';


--
-- Name: fn_auth_logout(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auth_logout(p_token_hash character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.refresh_tokens
  SET revoked_at = NOW()
  WHERE token_hash = p_token_hash AND revoked_at IS NULL;
END;
$$;


--
-- Name: FUNCTION fn_auth_logout(p_token_hash character varying); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_auth_logout(p_token_hash character varying) IS 'Revoke refresh token khi logout';


--
-- Name: fn_auth_logout_all(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auth_logout_all(p_staff_id integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.refresh_tokens
  SET revoked_at = NOW()
  WHERE staff_id = p_staff_id AND revoked_at IS NULL;
END;
$$;


--
-- Name: FUNCTION fn_auth_logout_all(p_staff_id integer); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_auth_logout_all(p_staff_id integer) IS 'Revoke tất cả refresh token của user';


--
-- Name: fn_auth_save_refresh_token(integer, character varying, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auth_save_refresh_token(p_staff_id integer, p_token_hash character varying, p_expires_at timestamp with time zone) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  -- Revoke tất cả refresh token cũ của user (single session)
  UPDATE public.refresh_tokens
  SET revoked_at = NOW()
  WHERE staff_id = p_staff_id AND revoked_at IS NULL;

  -- Tạo token mới
  INSERT INTO public.refresh_tokens (staff_id, token_hash, expires_at)
  VALUES (p_staff_id, p_token_hash, p_expires_at);
END;
$$;


--
-- Name: FUNCTION fn_auth_save_refresh_token(p_staff_id integer, p_token_hash character varying, p_expires_at timestamp with time zone); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_auth_save_refresh_token(p_staff_id integer, p_token_hash character varying, p_expires_at timestamp with time zone) IS 'Lưu refresh token mới, revoke token cũ (single session)';


--
-- Name: fn_auth_verify_refresh_token(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_auth_verify_refresh_token(p_token_hash character varying) RETURNS TABLE(staff_id integer, username character varying, full_name character varying, email character varying, phone character varying, image character varying, is_admin boolean, is_locked boolean, is_deleted boolean, department_id integer, unit_id integer, position_name character varying, department_name character varying, unit_name character varying, roles text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    s.id              AS staff_id,
    s.username,
    s.full_name::VARCHAR,
    s.email::VARCHAR,
    COALESCE(s.phone, s.mobile)::VARCHAR AS phone,
    s.image::VARCHAR,
    s.is_admin,
    s.is_locked,
    s.is_deleted,
    s.department_id,
    s.unit_id,
    p.name::VARCHAR   AS position_name,
    d.name::VARCHAR   AS department_name,
    u.name::VARCHAR   AS unit_name,
    COALESCE(
      (SELECT string_agg(r.name, ',')
       FROM public.role_of_staff ros
       JOIN public.roles r ON r.id = ros.role_id
       WHERE ros.staff_id = s.id),
      ''
    )::TEXT AS roles
  FROM public.refresh_tokens rt
  JOIN public.staff s ON s.id = rt.staff_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  WHERE rt.token_hash = p_token_hash
    AND rt.revoked_at IS NULL
    AND rt.expires_at > NOW();
END;
$$;


--
-- Name: FUNCTION fn_auth_verify_refresh_token(p_token_hash character varying); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fn_auth_verify_refresh_token(p_token_hash character varying) IS 'Xác thực refresh token, trả về thông tin user';


--
-- Name: fn_calendar_event_create(character varying, text, timestamp without time zone, timestamp without time zone, boolean, character varying, character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calendar_event_create(p_title character varying, p_description text, p_start_time timestamp without time zone, p_end_time timestamp without time zone, p_all_day boolean, p_color character varying, p_repeat_type character varying, p_scope character varying, p_unit_id integer, p_created_by integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text, id bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_new_id BIGINT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_title IS NULL OR TRIM(p_title) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tiêu đề sự kiện là bắt buộc'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;
  IF p_end_time < p_start_time THEN
    RETURN QUERY SELECT FALSE, 'Thời gian kết thúc phải sau thời gian bắt đầu'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;
  IF p_scope NOT IN ('personal', 'unit', 'leader') THEN
    RETURN QUERY SELECT FALSE, 'Phạm vi sự kiện không hợp lệ'::TEXT, NULL::BIGINT;
    RETURN;
  END IF;

  INSERT INTO public.calendar_events (
    title, description, start_time, end_time, all_day,
    color, repeat_type, scope, unit_id, department_id, created_by
  ) VALUES (
    TRIM(p_title), p_description,
    p_start_time, p_end_time, COALESCE(p_all_day, FALSE),
    COALESCE(p_color, '#1B3A5C'), COALESCE(p_repeat_type, 'none'),
    p_scope, v_unit_id, p_department_id, p_created_by
  ) RETURNING calendar_events.id INTO v_new_id;

  RETURN QUERY SELECT TRUE, 'Tạo sự kiện thành công'::TEXT, v_new_id;
END;
$$;


--
-- Name: fn_calendar_event_delete(bigint, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calendar_event_delete(p_id bigint, p_staff_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_event public.calendar_events%ROWTYPE;
BEGIN
  SELECT * INTO v_event FROM public.calendar_events WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sự kiện'::TEXT;
    RETURN;
  END IF;
  -- Ownership check for personal scope
  IF v_event.scope = 'personal' AND v_event.created_by != p_staff_id THEN
    RETURN QUERY SELECT FALSE, 'Bạn không có quyền xóa sự kiện này'::TEXT;
    RETURN;
  END IF;

  UPDATE public.calendar_events SET is_deleted = TRUE, updated_at = NOW() WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa sự kiện thành công'::TEXT;
END;
$$;


--
-- Name: fn_calendar_event_get_by_id(bigint); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calendar_event_get_by_id(p_id bigint) RETURNS TABLE(id bigint, title character varying, description text, start_time timestamp without time zone, end_time timestamp without time zone, all_day boolean, color character varying, repeat_type character varying, scope character varying, unit_id integer, created_by integer, creator_name character varying, created_at timestamp without time zone, updated_at timestamp without time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT
    ce.id,
    ce.title,
    ce.description,
    ce.start_time,
    ce.end_time,
    ce.all_day,
    ce.color,
    ce.repeat_type,
    ce.scope,
    ce.unit_id,
    ce.created_by,
    (s.last_name || ' ' || s.first_name)::VARCHAR AS creator_name,
    ce.created_at,
    ce.updated_at
  FROM public.calendar_events ce
  LEFT JOIN public.staff s ON s.id = ce.created_by
  WHERE ce.id = p_id
    AND ce.is_deleted = FALSE;
END;
$$;


--
-- Name: fn_calendar_event_get_list(character varying, integer, integer, timestamp without time zone, timestamp without time zone, integer[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calendar_event_get_list(p_scope character varying, p_unit_id integer, p_staff_id integer, p_start timestamp without time zone, p_end timestamp without time zone, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id bigint, title character varying, description text, start_time timestamp without time zone, end_time timestamp without time zone, all_day boolean, color character varying, repeat_type character varying, scope character varying, unit_id integer, created_by integer, creator_name character varying, created_at timestamp without time zone, updated_at timestamp without time zone)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
BEGIN
  RETURN QUERY
  SELECT ce.id, ce.title, ce.description, ce.start_time, ce.end_time,
    ce.all_day, ce.color, ce.repeat_type, ce.scope, ce.unit_id, ce.created_by,
    (s.last_name || ' ' || s.first_name)::VARCHAR AS creator_name,
    ce.created_at, ce.updated_at
  FROM public.calendar_events ce
  LEFT JOIN public.staff s ON s.id = ce.created_by
  WHERE ce.is_deleted = FALSE
    AND ce.scope = p_scope
    AND (p_dept_ids IS NULL OR ce.department_id = ANY(p_dept_ids))
    AND (
      CASE
        WHEN p_scope = 'personal' THEN ce.created_by = p_staff_id
        ELSE ce.unit_id = p_unit_id
      END
    )
    AND ce.start_time >= p_start AND ce.start_time <= p_end
  ORDER BY ce.start_time ASC;
END;
$$;


--
-- Name: fn_calendar_event_update(bigint, character varying, text, timestamp without time zone, timestamp without time zone, boolean, character varying, character varying, character varying, integer, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_calendar_event_update(p_id bigint, p_title character varying, p_description text, p_start_time timestamp without time zone, p_end_time timestamp without time zone, p_all_day boolean, p_color character varying, p_repeat_type character varying, p_scope character varying, p_unit_id integer, p_staff_id integer, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_event public.calendar_events%ROWTYPE;
  v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  SELECT * INTO v_event FROM public.calendar_events WHERE id = p_id AND is_deleted = FALSE;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy sự kiện'::TEXT;
    RETURN;
  END IF;
  IF v_event.scope = 'personal' AND v_event.created_by != p_staff_id THEN
    RETURN QUERY SELECT FALSE, 'Bạn không có quyền chỉnh sửa sự kiện này'::TEXT;
    RETURN;
  END IF;
  IF p_end_time < p_start_time THEN
    RETURN QUERY SELECT FALSE, 'Thời gian kết thúc phải sau thời gian bắt đầu'::TEXT;
    RETURN;
  END IF;

  UPDATE public.calendar_events SET
    title       = TRIM(p_title),
    description = p_description,
    start_time  = p_start_time,
    end_time    = p_end_time,
    all_day     = COALESCE(p_all_day, FALSE),
    color       = COALESCE(p_color, '#1B3A5C'),
    repeat_type = COALESCE(p_repeat_type, 'none'),
    scope       = p_scope,
    unit_id     = v_unit_id,
    department_id = p_department_id,
    updated_at  = NOW()
  WHERE id = p_id;

  RETURN QUERY SELECT TRUE, 'Cập nhật sự kiện thành công'::TEXT;
END;
$$;


--
-- Name: fn_commune_create(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_commune_create(p_district_id integer, p_name character varying, p_code character varying DEFAULT NULL::character varying) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên phường/xã không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.districts ds WHERE ds.id = p_district_id) THEN
    RETURN QUERY SELECT FALSE, 'Quận/huyện không tồn tại'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NOT NULL AND LENGTH(p_code) > 10 THEN
    RETURN QUERY SELECT FALSE, 'Mã phường/xã không được vượt quá 10 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code within district
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.communes
    WHERE district_id = p_district_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã phường/xã đã tồn tại trong quận/huyện'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO public.communes (district_id, name, code)
  VALUES (p_district_id, TRIM(p_name), TRIM(p_code))
  RETURNING communes.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao phuong/xa thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_commune_delete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_commune_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.communes WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy phường/xã'::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.communes WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa phuong/xa thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_commune_get_list(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_commune_get_list(p_district_id integer DEFAULT NULL::integer, p_keyword character varying DEFAULT NULL::character varying) RETURNS TABLE(id integer, district_id integer, name character varying, code character varying, is_active boolean)
    LANGUAGE sql STABLE
    AS $$
  SELECT c.id, c.district_id, c.name::VARCHAR, c.code::VARCHAR, c.is_active
  FROM public.communes c
  WHERE (p_district_id IS NULL OR c.district_id = p_district_id)
    AND (p_keyword IS NULL OR c.name ILIKE '%' || p_keyword || '%'
         OR c.code ILIKE '%' || p_keyword || '%')
  ORDER BY c.name;
$$;


--
-- Name: fn_commune_update(integer, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_commune_update(p_id integer, p_name character varying, p_code character varying DEFAULT NULL::character varying, p_is_active boolean DEFAULT true) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_district_id INT;
BEGIN
  SELECT district_id INTO v_district_id FROM public.communes WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy phường/xã'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên phường/xã không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.communes
    WHERE district_id = v_district_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã phường/xã đã tồn tại trong quận/huyện'::TEXT;
    RETURN;
  END IF;

  UPDATE public.communes SET name = TRIM(p_name), code = TRIM(p_code), is_active = p_is_active WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_config_get_list(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_config_get_list(p_unit_id integer DEFAULT NULL::integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, unit_id integer, key character varying, value text, description text)
    LANGUAGE sql STABLE
    AS $$
  SELECT c.id, c.unit_id, c.key::VARCHAR, c.value, c.description
  FROM public.configurations c
  WHERE (
    CASE WHEN p_dept_id IS NOT NULL THEN c.unit_id = public.fn_get_ancestor_unit(p_dept_id)
    ELSE (p_unit_id IS NULL OR c.unit_id = p_unit_id) END
  )
  ORDER BY c.key;
$$;


--
-- Name: fn_config_upsert(integer, character varying, text, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_config_upsert(p_unit_id integer DEFAULT NULL::integer, p_key character varying DEFAULT NULL::character varying, p_value text DEFAULT NULL::text, p_description text DEFAULT NULL::text, p_department_id integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));

  IF p_key IS NULL OR TRIM(p_key) = '' THEN
    RETURN QUERY SELECT FALSE, 'Key cấu hình không được để trống'::TEXT;
    RETURN;
  END IF;
  IF LENGTH(p_key) > 100 THEN
    RETURN QUERY SELECT FALSE, 'Key cấu hình không được vượt quá 100 ký tự'::TEXT;
    RETURN;
  END IF;

  INSERT INTO public.configurations (unit_id, key, value, description)
  VALUES (v_unit_id, TRIM(p_key), p_value, p_description)
  ON CONFLICT (unit_id, key) DO UPDATE SET
    value       = EXCLUDED.value,
    description = COALESCE(EXCLUDED.description, configurations.description);

  RETURN QUERY SELECT TRUE, 'Cap nhat cau hinh thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_department_create(integer, character varying, character varying, character varying, character varying, character varying, boolean, integer, integer, character varying, character varying, character varying, text, boolean, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_department_create(p_parent_id integer, p_code character varying, p_name character varying, p_name_en character varying, p_short_name character varying, p_abb_name character varying, p_is_unit boolean, p_level integer, p_sort_order integer, p_phone character varying, p_fax character varying, p_email character varying, p_address text, p_allow_doc_book boolean, p_description text, p_created_by integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO public.departments (
    parent_id, code, name, name_en, short_name, abb_name, is_unit,
    level, sort_order, phone, fax, email, address, allow_doc_book,
    description, created_by
  ) VALUES (
    p_parent_id, p_code, p_name, p_name_en, p_short_name, p_abb_name, p_is_unit,
    p_level, p_sort_order, p_phone, p_fax, p_email, p_address, p_allow_doc_book,
    p_description, p_created_by
  ) RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;


--
-- Name: fn_department_delete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_department_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_staff_count INT; v_child_count INT;
BEGIN
  SELECT COUNT(*) INTO v_child_count FROM public.departments WHERE parent_id = p_id AND is_deleted = FALSE;
  IF v_child_count > 0 THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa: còn '|| v_child_count ||' phòng ban con';
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_staff_count FROM public.staff WHERE department_id = p_id AND is_deleted = FALSE;
  IF v_staff_count > 0 THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa: còn '|| v_staff_count ||' nhân viên thuộc phòng ban này';
    RETURN;
  END IF;

  UPDATE public.departments SET is_deleted = TRUE WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa thành công'::TEXT;
END;
$$;


--
-- Name: fn_department_get_by_id(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_department_get_by_id(p_id integer) RETURNS TABLE(id integer, parent_id integer, code character varying, name character varying, name_en character varying, short_name character varying, abb_name character varying, is_unit boolean, level integer, sort_order integer, phone character varying, fax character varying, email character varying, address text, allow_doc_book boolean, description text, is_locked boolean, lgsp_system_id character varying, lgsp_secret_key character varying, created_at timestamp with time zone, updated_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT d.id, d.parent_id, d.code::VARCHAR, d.name::VARCHAR, d.name_en::VARCHAR,
    d.short_name::VARCHAR, d.abb_name::VARCHAR, d.is_unit, d.level,
    d.sort_order, d.phone::VARCHAR, d.fax::VARCHAR, d.email::VARCHAR, d.address,
    d.allow_doc_book, d.description, d.is_locked,
    d.lgsp_system_id::VARCHAR, d.lgsp_secret_key::VARCHAR,
    d.created_at, d.updated_at
  FROM public.departments d WHERE d.id = p_id AND d.is_deleted = FALSE;
$$;


--
-- Name: fn_department_get_tree(integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_department_get_tree(p_unit_id integer DEFAULT NULL::integer, p_dept_id integer DEFAULT NULL::integer) RETURNS TABLE(id integer, parent_id integer, code character varying, name character varying, name_en character varying, short_name character varying, abb_name character varying, is_unit boolean, level integer, sort_order integer, phone character varying, fax character varying, email character varying, address text, allow_doc_book boolean, is_locked boolean, staff_count bigint)
    LANGUAGE sql STABLE
    AS $$
  SELECT
    d.id, d.parent_id, d.code::VARCHAR, d.name::VARCHAR, d.name_en::VARCHAR,
    d.short_name::VARCHAR, d.abb_name::VARCHAR, d.is_unit, d.level,
    d.sort_order, d.phone::VARCHAR, d.fax::VARCHAR, d.email::VARCHAR, d.address,
    d.allow_doc_book, d.is_locked,
    (SELECT COUNT(*) FROM public.staff s WHERE s.department_id = d.id AND s.is_deleted = FALSE) AS staff_count
  FROM public.departments d
  WHERE d.is_deleted = FALSE
    AND (
      CASE WHEN p_dept_id IS NOT NULL THEN
        d.id = public.fn_get_ancestor_unit(p_dept_id) OR d.parent_id = public.fn_get_ancestor_unit(p_dept_id)
        OR d.parent_id IN (SELECT dd.id FROM public.departments dd WHERE dd.parent_id = public.fn_get_ancestor_unit(p_dept_id) AND dd.is_deleted = FALSE)
      ELSE
        (p_unit_id IS NULL OR d.id = p_unit_id OR d.parent_id = p_unit_id
         OR d.parent_id IN (SELECT dd.id FROM public.departments dd WHERE dd.parent_id = p_unit_id AND dd.is_deleted = FALSE))
      END
    )
  ORDER BY d.sort_order, d.name;
$$;


--
-- Name: fn_department_toggle_lock(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_department_toggle_lock(p_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.departments SET is_locked = NOT is_locked WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_department_update(integer, integer, character varying, character varying, character varying, character varying, character varying, boolean, integer, integer, character varying, character varying, character varying, text, boolean, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_department_update(p_id integer, p_parent_id integer, p_code character varying, p_name character varying, p_name_en character varying, p_short_name character varying, p_abb_name character varying, p_is_unit boolean, p_level integer, p_sort_order integer, p_phone character varying, p_fax character varying, p_email character varying, p_address text, p_allow_doc_book boolean, p_description text, p_updated_by integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.departments SET
    parent_id = p_parent_id, code = p_code, name = p_name, name_en = p_name_en,
    short_name = p_short_name, abb_name = p_abb_name, is_unit = p_is_unit,
    level = p_level, sort_order = p_sort_order, phone = p_phone, fax = p_fax,
    email = p_email, address = p_address, allow_doc_book = p_allow_doc_book,
    description = p_description, updated_by = p_updated_by
  WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_directory_get_list(integer, integer, character varying, integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_directory_get_list(p_unit_id integer, p_department_id integer, p_search character varying, p_page integer, p_page_size integer, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id integer, full_name character varying, position_name character varying, department_name character varying, unit_name character varying, phone character varying, mobile character varying, email character varying, image character varying, total_count bigint)
    LANGUAGE plpgsql SECURITY DEFINER
    AS $$
DECLARE
  v_offset INT := (COALESCE(p_page, 1) - 1) * COALESCE(p_page_size, 20);
  v_limit  INT := COALESCE(p_page_size, 20);
BEGIN
  RETURN QUERY
  SELECT
    s.id,
    (s.last_name || ' ' || s.first_name)::VARCHAR AS full_name,
    pos.name::VARCHAR AS position_name,
    dep.name::VARCHAR AS department_name,
    unit.name::VARCHAR AS unit_name,
    s.phone,
    s.mobile,
    s.email,
    s.image,
    COUNT(*) OVER() AS total_count
  FROM public.staff s
  LEFT JOIN public.positions pos ON pos.id = s.position_id
  LEFT JOIN public.departments dep ON dep.id = s.department_id
  LEFT JOIN public.departments unit ON unit.id = s.unit_id
  WHERE s.is_locked = FALSE
    AND s.is_deleted = FALSE
    AND (p_dept_ids IS NULL OR s.department_id = ANY(p_dept_ids))
    AND (p_unit_id IS NULL OR s.unit_id = p_unit_id)
    AND (p_department_id IS NULL OR s.department_id = p_department_id)
    AND (
      p_search IS NULL OR TRIM(p_search) = '' OR
      (s.last_name || ' ' || s.first_name) ILIKE '%' || TRIM(p_search) || '%' OR
      s.phone ILIKE '%' || TRIM(p_search) || '%' OR
      s.mobile ILIKE '%' || TRIM(p_search) || '%' OR
      s.email ILIKE '%' || TRIM(p_search) || '%'
    )
  ORDER BY s.last_name ASC, s.first_name ASC
  OFFSET v_offset
  LIMIT v_limit;
END;
$$;


--
-- Name: fn_district_create(integer, character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_district_create(p_province_id integer, p_name character varying, p_code character varying DEFAULT NULL::character varying) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quận/huyện không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF NOT EXISTS(SELECT 1 FROM public.provinces pv WHERE pv.id = p_province_id) THEN
    RETURN QUERY SELECT FALSE, 'Tỉnh/thành không tồn tại'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NOT NULL AND LENGTH(p_code) > 10 THEN
    RETURN QUERY SELECT FALSE, 'Mã quận/huyện không được vượt quá 10 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code within province
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.districts
    WHERE province_id = p_province_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã quận/huyện đã tồn tại trong tỉnh/thành'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO public.districts (province_id, name, code)
  VALUES (p_province_id, TRIM(p_name), TRIM(p_code))
  RETURNING districts.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao quan/huyen thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_district_delete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_district_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_commune_count INT;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.districts WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy quận/huyện'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_commune_count FROM public.communes WHERE district_id = p_id;
  IF v_commune_count > 0 THEN
    RETURN QUERY SELECT FALSE, ('Không thể xóa: còn '|| v_commune_count ||' phường/xã thuộc quận/huyện này')::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.districts WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa quan/huyen thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_district_get_list(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_district_get_list(p_province_id integer DEFAULT NULL::integer, p_keyword character varying DEFAULT NULL::character varying) RETURNS TABLE(id integer, province_id integer, name character varying, code character varying, is_active boolean)
    LANGUAGE sql STABLE
    AS $$
  SELECT d.id, d.province_id, d.name::VARCHAR, d.code::VARCHAR, d.is_active
  FROM public.districts d
  WHERE (p_province_id IS NULL OR d.province_id = p_province_id)
    AND (p_keyword IS NULL OR d.name ILIKE '%' || p_keyword || '%'
         OR d.code ILIKE '%' || p_keyword || '%')
  ORDER BY d.name;
$$;


--
-- Name: fn_district_update(integer, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_district_update(p_id integer, p_name character varying, p_code character varying DEFAULT NULL::character varying, p_is_active boolean DEFAULT true) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_province_id INT;
BEGIN
  SELECT province_id INTO v_province_id FROM public.districts WHERE id = p_id;
  IF NOT FOUND THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy quận/huyện'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên quận/huyện không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.districts
    WHERE province_id = v_province_id AND LOWER(TRIM(code)) = LOWER(TRIM(p_code))
      AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã quận/huyện đã tồn tại trong tỉnh/thành'::TEXT;
    RETURN;
  END IF;

  UPDATE public.districts SET name = TRIM(p_name), code = TRIM(p_code), is_active = p_is_active WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_get_ancestor_unit(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_get_ancestor_unit(p_dept_id integer) RETURNS integer
    LANGUAGE sql STABLE
    AS $$
  WITH RECURSIVE ancestors AS (
    SELECT id, parent_id, is_unit
    FROM public.departments
    WHERE id = p_dept_id AND is_deleted = FALSE
    UNION ALL
    SELECT d.id, d.parent_id, d.is_unit
    FROM public.departments d
    JOIN ancestors a ON d.id = a.parent_id
    WHERE d.is_deleted = FALSE
  )
  SELECT COALESCE(
    (SELECT id FROM ancestors WHERE is_unit = TRUE LIMIT 1),
    p_dept_id
  );
$$;


--
-- Name: fn_get_department_subtree(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_get_department_subtree(p_dept_id integer) RETURNS integer[]
    LANGUAGE sql STABLE
    AS $$
  WITH RECURSIVE tree AS (
    SELECT id FROM public.departments WHERE id = p_dept_id AND is_deleted = FALSE
    UNION ALL
    SELECT d.id FROM public.departments d
    JOIN tree t ON d.parent_id = t.id
    WHERE d.is_deleted = FALSE
  )
  SELECT COALESCE(ARRAY(SELECT id FROM tree), ARRAY[p_dept_id]);
$$;


--
-- Name: fn_position_create(character varying, character varying, integer, text, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_position_create(p_name character varying, p_code character varying, p_sort_order integer, p_description text, p_is_leader boolean DEFAULT false, p_is_handle_document boolean DEFAULT true) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO public.positions (name, code, sort_order, description, is_leader, is_handle_document)
  VALUES (p_name, p_code, p_sort_order, p_description, p_is_leader, p_is_handle_document)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;


--
-- Name: fn_position_delete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_position_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM public.staff WHERE position_id = p_id AND is_deleted = FALSE;
  IF v_count > 0 THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa: còn '|| v_count ||' nhân viên đang sử dụng chức vụ này';
    RETURN;
  END IF;
  DELETE FROM public.positions WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa thành công'::TEXT;
END;
$$;


--
-- Name: fn_position_get_by_id(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_position_get_by_id(p_id integer) RETURNS TABLE(id integer, name character varying, code character varying, sort_order integer, description text, is_active boolean, is_leader boolean, is_handle_document boolean)
    LANGUAGE sql STABLE
    AS $$
  SELECT p.id, p.name::VARCHAR, p.code::VARCHAR, p.sort_order, p.description, p.is_active, p.is_leader, p.is_handle_document
  FROM public.positions p WHERE p.id = p_id;
$$;


--
-- Name: fn_position_get_list(character varying, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_position_get_list(p_keyword character varying DEFAULT NULL::character varying, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20) RETURNS TABLE(id integer, name character varying, code character varying, sort_order integer, description text, is_active boolean, is_leader boolean, is_handle_document boolean, staff_count bigint, total_count bigint)
    LANGUAGE sql STABLE
    AS $$
  WITH filtered AS (
    SELECT p.*, COUNT(*) OVER() AS total_count
    FROM public.positions p
    WHERE (p_keyword IS NULL OR p.name ILIKE '%' || p_keyword || '%' OR p.code ILIKE '%' || p_keyword || '%')
    ORDER BY p.sort_order, p.name
    OFFSET (p_page - 1) * p_page_size LIMIT p_page_size
  )
  SELECT f.id, f.name::VARCHAR, f.code::VARCHAR, f.sort_order,
    f.description, f.is_active, f.is_leader, f.is_handle_document,
    (SELECT COUNT(*) FROM public.staff s WHERE s.position_id = f.id AND s.is_deleted = FALSE) AS staff_count,
    f.total_count
  FROM filtered f;
$$;


--
-- Name: fn_position_update(integer, character varying, character varying, integer, text, boolean, boolean, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_position_update(p_id integer, p_name character varying, p_code character varying, p_sort_order integer, p_description text, p_is_active boolean, p_is_leader boolean DEFAULT false, p_is_handle_document boolean DEFAULT true) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.positions SET name = p_name, code = p_code, sort_order = p_sort_order,
    description = p_description, is_active = p_is_active,
    is_leader = p_is_leader, is_handle_document = p_is_handle_document
  WHERE id = p_id;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_province_create(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_province_create(p_name character varying, p_code character varying DEFAULT NULL::character varying) RETURNS TABLE(success boolean, message text, id integer)
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên tỉnh/thành không được để trống'::TEXT, 0;
    RETURN;
  END IF;
  IF p_code IS NOT NULL AND LENGTH(p_code) > 10 THEN
    RETURN QUERY SELECT FALSE, 'Mã tỉnh/thành không được vượt quá 10 ký tự'::TEXT, 0;
    RETURN;
  END IF;

  -- Check unique code
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.provinces WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code))
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã tỉnh/thành đã tồn tại'::TEXT, 0;
    RETURN;
  END IF;

  INSERT INTO public.provinces (name, code)
  VALUES (TRIM(p_name), TRIM(p_code))
  RETURNING provinces.id INTO v_id;

  RETURN QUERY SELECT TRUE, 'Tao tinh/thanh thanh cong'::TEXT, v_id;
END;
$$;


--
-- Name: fn_province_delete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_province_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_district_count INT;
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.provinces WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tỉnh/thành'::TEXT;
    RETURN;
  END IF;

  SELECT COUNT(*) INTO v_district_count FROM public.districts WHERE province_id = p_id;
  IF v_district_count > 0 THEN
    RETURN QUERY SELECT FALSE, ('Không thể xóa: còn '|| v_district_count ||' quận/huyện thuộc tỉnh/thành này')::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.provinces WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xoa tinh/thanh thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_province_get_list(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_province_get_list(p_keyword character varying DEFAULT NULL::character varying) RETURNS TABLE(id integer, name character varying, code character varying, is_active boolean)
    LANGUAGE sql STABLE
    AS $$
  SELECT p.id, p.name::VARCHAR, p.code::VARCHAR, p.is_active
  FROM public.provinces p
  WHERE (p_keyword IS NULL OR p.name ILIKE '%' || p_keyword || '%'
         OR p.code ILIKE '%' || p_keyword || '%')
  ORDER BY p.name;
$$;


--
-- Name: fn_province_update(integer, character varying, character varying, boolean); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_province_update(p_id integer, p_name character varying, p_code character varying DEFAULT NULL::character varying, p_is_active boolean DEFAULT true) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.provinces WHERE id = p_id) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy tỉnh/thành'::TEXT;
    RETURN;
  END IF;
  IF p_name IS NULL OR TRIM(p_name) = '' THEN
    RETURN QUERY SELECT FALSE, 'Tên tỉnh/thành không được để trống'::TEXT;
    RETURN;
  END IF;

  -- Check unique code (exclude self)
  IF p_code IS NOT NULL AND EXISTS(
    SELECT 1 FROM public.provinces
    WHERE LOWER(TRIM(code)) = LOWER(TRIM(p_code)) AND id <> p_id
  ) THEN
    RETURN QUERY SELECT FALSE, 'Mã tỉnh/thành đã tồn tại'::TEXT;
    RETURN;
  END IF;

  UPDATE public.provinces SET name = TRIM(p_name), code = TRIM(p_code), is_active = p_is_active WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Cap nhat thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_right_create(integer, character varying, character varying, character varying, character varying, integer, boolean, boolean, boolean, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_right_create(p_parent_id integer, p_name character varying, p_name_of_menu character varying, p_action_link character varying, p_icon character varying, p_sort_order integer, p_show_menu boolean, p_default_page boolean, p_show_in_app boolean, p_description text) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT;
BEGIN
  INSERT INTO public.rights (parent_id, name, name_of_menu, action_link, icon,
    sort_order, show_menu, default_page, show_in_app, description)
  VALUES (p_parent_id, p_name, p_name_of_menu, p_action_link, p_icon,
    p_sort_order, p_show_menu, p_default_page, p_show_in_app, p_description)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;


--
-- Name: fn_right_delete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_right_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM public.rights WHERE parent_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa: còn '|| v_count ||' chức năng con';
    RETURN;
  END IF;
  DELETE FROM public.action_of_role WHERE right_id = p_id;
  DELETE FROM public.rights WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa thành công'::TEXT;
END;
$$;


--
-- Name: fn_right_get_by_id(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_right_get_by_id(p_id integer) RETURNS TABLE(id integer, parent_id integer, name character varying, name_of_menu character varying, action_link character varying, icon character varying, sort_order integer, show_menu boolean, default_page boolean, show_in_app boolean, description text, is_locked boolean)
    LANGUAGE sql STABLE
    AS $$
  SELECT r.id, r.parent_id, r.name::VARCHAR, r.name_of_menu::VARCHAR,
    r.action_link::VARCHAR, r.icon::VARCHAR, r.sort_order,
    r.show_menu, r.default_page, r.show_in_app,
    r.description, r.is_locked
  FROM public.rights r WHERE r.id = p_id;
$$;


--
-- Name: fn_right_get_by_staff(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_right_get_by_staff(p_staff_id integer) RETURNS TABLE(id integer, parent_id integer, name character varying, name_of_menu character varying, action_link character varying, icon character varying, sort_order integer, show_menu boolean, default_page boolean, show_in_app boolean)
    LANGUAGE sql STABLE
    AS $$
  SELECT r.id, r.parent_id, r.name::VARCHAR, r.name_of_menu::VARCHAR,
    r.action_link::VARCHAR, r.icon::VARCHAR, r.sort_order,
    r.show_menu, r.default_page, r.show_in_app
  FROM public.rights r
  WHERE r.show_menu = TRUE
    AND (
      EXISTS (
        SELECT 1 FROM public.action_of_role aor
        JOIN public.role_of_staff ros ON ros.role_id = aor.role_id
        WHERE aor.right_id = r.id AND ros.staff_id = p_staff_id
      )
      OR EXISTS (
        SELECT 1 FROM public.staff s WHERE s.id = p_staff_id AND s.is_admin = TRUE
      )
    )
  ORDER BY r.sort_order, r.name;
$$;


--
-- Name: fn_right_get_tree(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_right_get_tree() RETURNS TABLE(id integer, parent_id integer, name character varying, name_of_menu character varying, action_link character varying, icon character varying, sort_order integer, show_menu boolean, default_page boolean, show_in_app boolean, description text, is_locked boolean)
    LANGUAGE sql STABLE
    AS $$
  SELECT r.id, r.parent_id, r.name::VARCHAR, r.name_of_menu::VARCHAR,
    r.action_link::VARCHAR, r.icon::VARCHAR, r.sort_order,
    r.show_menu, r.default_page, r.show_in_app,
    r.description, r.is_locked
  FROM public.rights r
  ORDER BY r.sort_order, r.name;
$$;


--
-- Name: fn_right_update(integer, integer, character varying, character varying, character varying, character varying, integer, boolean, boolean, boolean, text); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_right_update(p_id integer, p_parent_id integer, p_name character varying, p_name_of_menu character varying, p_action_link character varying, p_icon character varying, p_sort_order integer, p_show_menu boolean, p_default_page boolean, p_show_in_app boolean, p_description text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.rights SET parent_id = p_parent_id, name = p_name,
    name_of_menu = p_name_of_menu, action_link = p_action_link, icon = p_icon,
    sort_order = p_sort_order, show_menu = p_show_menu, default_page = p_default_page,
    show_in_app = p_show_in_app, description = p_description
  WHERE id = p_id;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_role_assign_rights(integer, integer[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_role_assign_rights(p_role_id integer, p_right_ids integer[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM public.action_of_role WHERE role_id = p_role_id;
  INSERT INTO public.action_of_role (role_id, right_id)
  SELECT p_role_id, unnest(p_right_ids)
  ON CONFLICT DO NOTHING;
END;
$$;


--
-- Name: fn_role_create(integer, character varying, text, integer, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_role_create(p_unit_id integer DEFAULT NULL::integer, p_name character varying DEFAULT NULL::character varying, p_description text DEFAULT NULL::text, p_created_by integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE v_id INT; v_unit_id INT;
BEGIN
  v_unit_id := public.fn_get_ancestor_unit(COALESCE(p_department_id, p_unit_id));
  INSERT INTO public.roles (unit_id, name, description, created_by)
  VALUES (v_unit_id, p_name, p_description, p_created_by)
  RETURNING id INTO v_id;
  RETURN v_id;
END;
$$;


--
-- Name: fn_role_delete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_role_delete(p_id integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE v_count INT;
BEGIN
  SELECT COUNT(*) INTO v_count FROM public.role_of_staff WHERE role_id = p_id;
  IF v_count > 0 THEN
    RETURN QUERY SELECT FALSE, 'Không thể xóa: còn '|| v_count ||' nhân viên trong nhóm quyền này';
    RETURN;
  END IF;
  DELETE FROM public.action_of_role WHERE role_id = p_id;
  DELETE FROM public.roles WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Xóa thành công'::TEXT;
END;
$$;


--
-- Name: fn_role_get_by_id(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_role_get_by_id(p_id integer) RETURNS TABLE(id integer, name character varying, description text, unit_id integer, is_locked boolean)
    LANGUAGE sql STABLE
    AS $$
  SELECT r.id, r.name::VARCHAR, r.description, r.unit_id, r.is_locked FROM public.roles r WHERE r.id = p_id;
$$;


--
-- Name: fn_role_get_list(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_role_get_list(p_unit_id integer DEFAULT NULL::integer, p_keyword character varying DEFAULT NULL::character varying) RETURNS TABLE(id integer, name character varying, description text, unit_id integer, is_locked boolean, staff_count bigint, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT r.id, r.name::VARCHAR, r.description, r.unit_id,
    r.is_locked,
    (SELECT COUNT(*) FROM public.role_of_staff ros WHERE ros.role_id = r.id) AS staff_count,
    r.created_at
  FROM public.roles r
  WHERE (p_unit_id IS NULL OR r.unit_id = p_unit_id OR r.unit_id IS NULL)
    AND (p_keyword IS NULL OR r.name ILIKE '%' || p_keyword || '%')
  ORDER BY r.name;
$$;


--
-- Name: fn_role_get_rights(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_role_get_rights(p_role_id integer) RETURNS TABLE(right_id integer)
    LANGUAGE sql STABLE
    AS $$
  SELECT aor.right_id FROM public.action_of_role aor WHERE aor.role_id = p_role_id;
$$;


--
-- Name: fn_role_update(integer, character varying, text, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_role_update(p_id integer, p_name character varying, p_description text, p_updated_by integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.roles SET name = p_name, description = p_description, updated_by = p_updated_by WHERE id = p_id;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_staff_assign_roles(integer, integer[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_assign_roles(p_staff_id integer, p_role_ids integer[]) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
  DELETE FROM public.role_of_staff WHERE staff_id = p_staff_id;
  INSERT INTO public.role_of_staff (staff_id, role_id)
  SELECT p_staff_id, unnest(p_role_ids)
  ON CONFLICT DO NOTHING;
END;
$$;


--
-- Name: fn_staff_auto_unit_id(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_auto_unit_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.unit_id := public.fn_get_ancestor_unit(NEW.department_id);
  RETURN NEW;
END; $$;


--
-- Name: fn_staff_change_password(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_change_password(p_id integer, p_new_password_hash character varying) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_current_hash VARCHAR;
BEGIN
  SELECT password_hash INTO v_current_hash FROM public.staff WHERE id = p_id AND is_deleted = FALSE AND is_locked = FALSE;

  IF v_current_hash IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Tài khoản không tồn tại hoặc đã bị khóa'::TEXT;
    RETURN;
  END IF;

  -- Note: So sánh old vs new password phải check ở app layer (bcrypt compare)
  -- Ở đây chỉ update
  UPDATE public.staff SET password_hash = p_new_password_hash, password_changed = TRUE WHERE id = p_id;
  RETURN QUERY SELECT TRUE, 'Đổi mật khẩu thành công'::TEXT;
END;
$$;


--
-- Name: fn_staff_create(integer, integer, integer, character varying, character varying, character varying, character varying, smallint, date, character varying, character varying, character varying, text, character varying, date, character varying, boolean, boolean, boolean, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_create(p_department_id integer, p_unit_id integer, p_position_id integer, p_username character varying, p_password_hash character varying, p_first_name character varying, p_last_name character varying, p_gender smallint, p_birth_date date, p_email character varying, p_phone character varying, p_mobile character varying, p_address text, p_id_card character varying, p_id_card_date date, p_id_card_place character varying, p_is_admin boolean, p_is_represent_unit boolean, p_is_represent_department boolean, p_created_by integer) RETURNS TABLE(id integer, message text)
    LANGUAGE plpgsql
    AS $$
DECLARE
  v_id INT;
  v_code VARCHAR;
  v_username VARCHAR;
BEGIN
  -- Normalize username: trim, lowercase
  v_username := LOWER(TRIM(REPLACE(p_username, ' ', '')));

  -- Check unique username (case-insensitive)
  IF EXISTS (SELECT 1 FROM public.staff WHERE LOWER(username) = v_username AND is_deleted = FALSE) THEN
    RETURN QUERY SELECT 0, 'Tên đăng nhập đã tồn tại'::TEXT;
    RETURN;
  END IF;

  -- Check email unique (nếu có)
  IF p_email IS NOT NULL AND p_email <> '' THEN
    IF EXISTS (SELECT 1 FROM public.staff WHERE LOWER(email) = LOWER(TRIM(p_email)) AND is_deleted = FALSE) THEN
      RETURN QUERY SELECT 0, 'Email đã được sử dụng'::TEXT;
      RETURN;
    END IF;
  END IF;

  -- Auto-generate staff code
  v_code := public.fn_staff_generate_code();

  INSERT INTO public.staff (
    department_id, unit_id, position_id, username, password_hash, code,
    first_name, last_name, gender, birth_date, email, phone, mobile,
    address, id_card, id_card_date, id_card_place,
    is_admin, is_represent_unit, is_represent_department,
    password_changed, created_by
  ) VALUES (
    p_department_id, p_unit_id, p_position_id, v_username, p_password_hash, v_code,
    TRIM(p_first_name), TRIM(p_last_name), p_gender, p_birth_date,
    LOWER(TRIM(p_email)), TRIM(p_phone), TRIM(p_mobile),
    TRIM(p_address), TRIM(p_id_card), p_id_card_date, TRIM(p_id_card_place),
    COALESCE(p_is_admin, FALSE), COALESCE(p_is_represent_unit, FALSE), COALESCE(p_is_represent_department, FALSE),
    FALSE,  -- password_changed = FALSE → bắt đổi pass lần đầu
    p_created_by
  ) RETURNING staff.id INTO v_id;

  RETURN QUERY SELECT v_id, 'Tạo thành công'::TEXT;
END;
$$;


--
-- Name: fn_staff_delete(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_delete(p_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.staff SET is_deleted = TRUE WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_staff_generate_code(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_generate_code() RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
  RETURN 'NV' || LPAD(nextval('seq_staff_code')::TEXT, 6, '0');
END;
$$;


--
-- Name: fn_staff_get_by_id(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_get_by_id(p_id integer) RETURNS TABLE(id integer, code character varying, username character varying, full_name character varying, first_name character varying, last_name character varying, email character varying, phone character varying, mobile character varying, image character varying, gender smallint, birth_date date, address text, id_card character varying, id_card_date date, id_card_place character varying, department_id integer, department_name character varying, unit_id integer, unit_name character varying, position_id integer, position_name character varying, is_admin boolean, is_locked boolean, is_represent_unit boolean, is_represent_department boolean, password_changed boolean, sign_phone character varying, sign_ca text, sign_image character varying, last_login_at timestamp with time zone, created_at timestamp with time zone, roles text)
    LANGUAGE sql STABLE
    AS $$
  SELECT
    s.id, s.code::VARCHAR, s.username::VARCHAR, s.full_name::VARCHAR, s.first_name::VARCHAR, s.last_name::VARCHAR,
    s.email::VARCHAR, s.phone::VARCHAR, s.mobile::VARCHAR, s.image::VARCHAR,
    s.gender, s.birth_date, s.address,
    s.id_card::VARCHAR, s.id_card_date, s.id_card_place::VARCHAR,
    s.department_id, d.name::VARCHAR, s.unit_id, u.name::VARCHAR,
    s.position_id, p.name::VARCHAR,
    s.is_admin, s.is_locked, s.is_represent_unit, s.is_represent_department,
    s.password_changed,
    s.sign_phone::VARCHAR, s.sign_ca, s.sign_image::VARCHAR,
    s.last_login_at, s.created_at,
    COALESCE((SELECT string_agg(r.name, ',') FROM public.role_of_staff ros JOIN public.roles r ON r.id = ros.role_id WHERE ros.staff_id = s.id), '')::TEXT AS roles
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE s.id = p_id AND s.is_deleted = FALSE;
$$;


--
-- Name: fn_staff_get_list(integer, integer, character varying, boolean, integer, integer, integer[]); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_get_list(p_unit_id integer DEFAULT NULL::integer, p_department_id integer DEFAULT NULL::integer, p_keyword character varying DEFAULT NULL::character varying, p_is_locked boolean DEFAULT NULL::boolean, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20, p_dept_ids integer[] DEFAULT NULL::integer[]) RETURNS TABLE(id integer, username character varying, full_name character varying, first_name character varying, last_name character varying, email character varying, phone character varying, image character varying, gender smallint, department_id integer, department_name character varying, unit_id integer, unit_name character varying, position_id integer, position_name character varying, is_admin boolean, is_locked boolean, is_represent_unit boolean, is_represent_department boolean, last_login_at timestamp with time zone, created_at timestamp with time zone, total_count bigint)
    LANGUAGE sql STABLE
    AS $$
  SELECT
    s.id, s.username::VARCHAR, s.full_name::VARCHAR, s.first_name::VARCHAR, s.last_name::VARCHAR,
    s.email::VARCHAR, COALESCE(s.phone, s.mobile)::VARCHAR AS phone, s.image::VARCHAR, s.gender,
    s.department_id, d.name::VARCHAR AS department_name,
    s.unit_id, u.name::VARCHAR AS unit_name,
    s.position_id, p.name::VARCHAR AS position_name,
    s.is_admin, s.is_locked, s.is_represent_unit, s.is_represent_department,
    s.last_login_at, s.created_at,
    COUNT(*) OVER() AS total_count
  FROM public.staff s
  LEFT JOIN public.departments d ON d.id = s.department_id
  LEFT JOIN public.departments u ON u.id = s.unit_id
  LEFT JOIN public.positions p ON p.id = s.position_id
  WHERE s.is_deleted = FALSE
    AND (p_dept_ids IS NULL OR s.department_id = ANY(p_dept_ids))
    AND (p_unit_id IS NULL OR s.unit_id = p_unit_id)
    AND (p_department_id IS NULL OR s.department_id = p_department_id)
    AND (p_keyword IS NULL OR s.full_name ILIKE '%' || p_keyword || '%' OR s.username ILIKE '%' || p_keyword || '%' OR s.email ILIKE '%' || p_keyword || '%')
    AND (p_is_locked IS NULL OR s.is_locked = p_is_locked)
  ORDER BY s.last_name, s.first_name
  OFFSET (p_page - 1) * p_page_size LIMIT p_page_size;
$$;


--
-- Name: fn_staff_get_roles(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_get_roles(p_staff_id integer) RETURNS TABLE(role_id integer, role_name character varying)
    LANGUAGE sql STABLE
    AS $$
  SELECT r.id, r.name::VARCHAR
  FROM public.role_of_staff ros
  JOIN public.roles r ON r.id = ros.role_id
  WHERE ros.staff_id = p_staff_id;
$$;


--
-- Name: fn_staff_reset_password(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_reset_password(p_id integer, p_new_password_hash character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.staff SET password_hash = p_new_password_hash WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_staff_toggle_lock(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_toggle_lock(p_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.staff SET is_locked = NOT is_locked WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_staff_update(integer, integer, integer, integer, character varying, character varying, smallint, date, character varying, character varying, character varying, text, character varying, date, character varying, boolean, boolean, boolean, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_update(p_id integer, p_department_id integer, p_unit_id integer, p_position_id integer, p_first_name character varying, p_last_name character varying, p_gender smallint, p_birth_date date, p_email character varying, p_phone character varying, p_mobile character varying, p_address text, p_id_card character varying, p_id_card_date date, p_id_card_place character varying, p_is_admin boolean, p_is_represent_unit boolean, p_is_represent_department boolean, p_updated_by integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.staff SET
    department_id = p_department_id, unit_id = p_unit_id, position_id = p_position_id,
    first_name = p_first_name, last_name = p_last_name, gender = p_gender,
    birth_date = p_birth_date, email = p_email, phone = p_phone, mobile = p_mobile,
    address = p_address, id_card = p_id_card, id_card_date = p_id_card_date,
    id_card_place = p_id_card_place, is_admin = p_is_admin,
    is_represent_unit = p_is_represent_unit, is_represent_department = p_is_represent_department,
    updated_by = p_updated_by
  WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_staff_update_avatar(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_staff_update_avatar(p_id integer, p_image_path character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
  UPDATE public.staff SET image = p_image_path WHERE id = p_id AND is_deleted = FALSE;
  RETURN FOUND;
END;
$$;


--
-- Name: fn_update_timestamp(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_update_timestamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;


--
-- Name: fn_work_calendar_get(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_work_calendar_get(p_year integer) RETURNS TABLE(id integer, date date, description character varying, is_holiday boolean, created_by integer, created_at timestamp with time zone)
    LANGUAGE sql STABLE
    AS $$
  SELECT wc.id, wc.date, wc.description::VARCHAR, wc.is_holiday,
         wc.created_by, wc.created_at
  FROM public.work_calendar wc
  WHERE EXTRACT(YEAR FROM wc.date) = p_year
  ORDER BY wc.date;
$$;


--
-- Name: fn_work_calendar_remove_holiday(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_work_calendar_remove_holiday(p_date date) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF NOT EXISTS(SELECT 1 FROM public.work_calendar WHERE date = p_date) THEN
    RETURN QUERY SELECT FALSE, 'Không tìm thấy ngày nghỉ'::TEXT;
    RETURN;
  END IF;

  DELETE FROM public.work_calendar WHERE date = p_date;
  RETURN QUERY SELECT TRUE, 'Xoa ngay nghi thanh cong'::TEXT;
END;
$$;


--
-- Name: fn_work_calendar_set_holiday(date, character varying, integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fn_work_calendar_set_holiday(p_date date, p_description character varying DEFAULT NULL::character varying, p_created_by integer DEFAULT NULL::integer) RETURNS TABLE(success boolean, message text)
    LANGUAGE plpgsql
    AS $$
BEGIN
  IF p_date IS NULL THEN
    RETURN QUERY SELECT FALSE, 'Ngày không được để trống'::TEXT;
    RETURN;
  END IF;
  IF p_description IS NOT NULL AND LENGTH(p_description) > 200 THEN
    RETURN QUERY SELECT FALSE, 'Mô tả không được vượt quá 200 ký tự'::TEXT;
    RETURN;
  END IF;

  INSERT INTO public.work_calendar (date, description, is_holiday, created_by)
  VALUES (p_date, p_description, TRUE, p_created_by)
  ON CONFLICT (date) DO UPDATE SET
    description = EXCLUDED.description,
    is_holiday  = TRUE,
    created_by  = EXCLUDED.created_by;

  RETURN QUERY SELECT TRUE, 'Cap nhat lich thanh cong'::TEXT;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: contract_attachments; Type: TABLE; Schema: cont; Owner: -
--

CREATE TABLE cont.contract_attachments (
    id bigint NOT NULL,
    contract_id integer NOT NULL,
    file_name character varying(500) NOT NULL,
    file_path character varying(1000) NOT NULL,
    file_size bigint,
    mime_type character varying(200),
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE contract_attachments; Type: COMMENT; Schema: cont; Owner: -
--

COMMENT ON TABLE cont.contract_attachments IS 'Đính kèm hợp đồng — ánh xạ từ AttachmentOfContract.cs';


--
-- Name: contract_attachments_id_seq; Type: SEQUENCE; Schema: cont; Owner: -
--

CREATE SEQUENCE cont.contract_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contract_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: cont; Owner: -
--

ALTER SEQUENCE cont.contract_attachments_id_seq OWNED BY cont.contract_attachments.id;


--
-- Name: contract_types; Type: TABLE; Schema: cont; Owner: -
--

CREATE TABLE cont.contract_types (
    id integer NOT NULL,
    unit_id integer,
    parent_id integer DEFAULT 0,
    code character varying(50),
    name character varying(200) NOT NULL,
    note text,
    sort_order integer DEFAULT 0,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone
);


--
-- Name: TABLE contract_types; Type: COMMENT; Schema: cont; Owner: -
--

COMMENT ON TABLE cont.contract_types IS 'Loại hợp đồng — ánh xạ từ ContractType.cs';


--
-- Name: contract_types_id_seq; Type: SEQUENCE; Schema: cont; Owner: -
--

CREATE SEQUENCE cont.contract_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contract_types_id_seq; Type: SEQUENCE OWNED BY; Schema: cont; Owner: -
--

ALTER SEQUENCE cont.contract_types_id_seq OWNED BY cont.contract_types.id;


--
-- Name: contracts; Type: TABLE; Schema: cont; Owner: -
--

CREATE TABLE cont.contracts (
    id integer NOT NULL,
    code_index integer,
    contract_type_id integer,
    department_id integer,
    type_of_contract integer DEFAULT 0,
    contact_id integer,
    contact_name character varying(200),
    unit_id integer NOT NULL,
    code character varying(100),
    sign_date date,
    input_date date,
    receive_date date,
    name character varying(500) NOT NULL,
    signer character varying(200),
    number integer,
    ballot character varying(200),
    marker character varying(200),
    curator_name character varying(200),
    currency character varying(50),
    transporter character varying(200),
    staff_id integer,
    note text,
    status integer DEFAULT 0,
    amount character varying(200),
    payment_amount numeric,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone
);


--
-- Name: TABLE contracts; Type: COMMENT; Schema: cont; Owner: -
--

COMMENT ON TABLE cont.contracts IS 'Hợp đồng — ánh xạ từ Contract.cs';


--
-- Name: contracts_id_seq; Type: SEQUENCE; Schema: cont; Owner: -
--

CREATE SEQUENCE cont.contracts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contracts_id_seq; Type: SEQUENCE OWNED BY; Schema: cont; Owner: -
--

ALTER SEQUENCE cont.contracts_id_seq OWNED BY cont.contracts.id;


--
-- Name: attachment_drafting_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.attachment_drafting_docs (
    id bigint NOT NULL,
    drafting_doc_id bigint NOT NULL,
    file_name character varying(500) NOT NULL,
    file_path character varying(1000) NOT NULL,
    file_size bigint DEFAULT 0,
    content_type character varying(100),
    sort_order integer DEFAULT 0,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    description text,
    is_ca boolean DEFAULT false,
    ca_date timestamp with time zone,
    signed_file_path character varying(1000)
);


--
-- Name: COLUMN attachment_drafting_docs.description; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.attachment_drafting_docs.description IS 'Mo ta file dinh kem';


--
-- Name: attachment_drafting_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.attachment_drafting_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachment_drafting_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.attachment_drafting_docs_id_seq OWNED BY edoc.attachment_drafting_docs.id;


--
-- Name: attachment_handling_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.attachment_handling_docs (
    id bigint NOT NULL,
    handling_doc_id bigint NOT NULL,
    file_name character varying(500) NOT NULL,
    file_path character varying(1000) NOT NULL,
    file_size bigint DEFAULT 0,
    content_type character varying(100),
    sort_order integer DEFAULT 0,
    created_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: attachment_handling_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.attachment_handling_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachment_handling_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.attachment_handling_docs_id_seq OWNED BY edoc.attachment_handling_docs.id;


--
-- Name: attachment_incoming_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.attachment_incoming_docs (
    id bigint NOT NULL,
    incoming_doc_id bigint NOT NULL,
    file_name character varying(500) NOT NULL,
    file_path character varying(1000) NOT NULL,
    file_size bigint DEFAULT 0,
    content_type character varying(100),
    sort_order integer DEFAULT 0,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    description text,
    is_ca boolean DEFAULT false,
    ca_date timestamp with time zone,
    signed_file_path character varying(1000)
);


--
-- Name: COLUMN attachment_incoming_docs.description; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.attachment_incoming_docs.description IS 'Mo ta file dinh kem';


--
-- Name: attachment_incoming_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.attachment_incoming_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachment_incoming_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.attachment_incoming_docs_id_seq OWNED BY edoc.attachment_incoming_docs.id;


--
-- Name: attachment_inter_incoming_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.attachment_inter_incoming_docs (
    id bigint NOT NULL,
    inter_incoming_doc_id bigint NOT NULL,
    file_name character varying(500) NOT NULL,
    file_path character varying(1000) NOT NULL,
    file_size bigint DEFAULT 0,
    content_type character varying(100),
    description text,
    sort_order integer DEFAULT 0,
    created_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE attachment_inter_incoming_docs; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.attachment_inter_incoming_docs IS 'File dinh kem VB lien thong (tu LGSP hoac upload thu cong)';


--
-- Name: attachment_inter_incoming_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.attachment_inter_incoming_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachment_inter_incoming_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.attachment_inter_incoming_docs_id_seq OWNED BY edoc.attachment_inter_incoming_docs.id;


--
-- Name: attachment_outgoing_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.attachment_outgoing_docs (
    id bigint NOT NULL,
    outgoing_doc_id bigint NOT NULL,
    file_name character varying(500) NOT NULL,
    file_path character varying(1000) NOT NULL,
    file_size bigint DEFAULT 0,
    content_type character varying(100),
    sort_order integer DEFAULT 0,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    description text,
    is_ca boolean DEFAULT false,
    ca_date timestamp with time zone,
    signed_file_path character varying(1000)
);


--
-- Name: COLUMN attachment_outgoing_docs.description; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.attachment_outgoing_docs.description IS 'Mo ta file dinh kem';


--
-- Name: attachment_outgoing_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.attachment_outgoing_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: attachment_outgoing_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.attachment_outgoing_docs_id_seq OWNED BY edoc.attachment_outgoing_docs.id;


--
-- Name: delegations; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.delegations (
    id integer NOT NULL,
    from_staff_id integer NOT NULL,
    to_staff_id integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    note text,
    is_revoked boolean DEFAULT false,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE delegations; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.delegations IS 'Uy quyen xu ly van ban';


--
-- Name: delegations_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.delegations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: delegations_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.delegations_id_seq OWNED BY edoc.delegations.id;


--
-- Name: device_tokens; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.device_tokens (
    id bigint NOT NULL,
    staff_id integer NOT NULL,
    device_token character varying(500) NOT NULL,
    device_type character varying(20) DEFAULT 'web'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT device_tokens_device_type_check CHECK (((device_type)::text = ANY ((ARRAY['web'::character varying, 'android'::character varying, 'ios'::character varying])::text[])))
);


--
-- Name: TABLE device_tokens; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.device_tokens IS 'FCM device tokens cho push notification';


--
-- Name: device_tokens_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.device_tokens_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: device_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.device_tokens_id_seq OWNED BY edoc.device_tokens.id;


--
-- Name: digital_signatures; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.digital_signatures (
    id bigint NOT NULL,
    doc_id bigint NOT NULL,
    doc_type character varying(20) NOT NULL,
    staff_id integer NOT NULL,
    sign_method character varying(30) NOT NULL,
    certificate_serial character varying(200),
    certificate_subject character varying(500),
    certificate_issuer character varying(500),
    signed_file_path character varying(1000),
    original_file_path character varying(1000),
    sign_status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    error_message text,
    signed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT digital_signatures_doc_type_check CHECK (((doc_type)::text = ANY ((ARRAY['outgoing'::character varying, 'drafting'::character varying])::text[]))),
    CONSTRAINT digital_signatures_sign_method_check CHECK (((sign_method)::text = ANY ((ARRAY['smart_ca'::character varying, 'esign_neac'::character varying, 'usb_token'::character varying])::text[]))),
    CONSTRAINT digital_signatures_sign_status_check CHECK (((sign_status)::text = ANY ((ARRAY['pending'::character varying, 'signing'::character varying, 'signed'::character varying, 'error'::character varying, 'rejected'::character varying])::text[])))
);


--
-- Name: TABLE digital_signatures; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.digital_signatures IS 'Chu ky so tren van ban — luu thong tin ky SmartCA, EsignNEAC, USB Token';


--
-- Name: digital_signatures_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.digital_signatures_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: digital_signatures_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.digital_signatures_id_seq OWNED BY edoc.digital_signatures.id;


--
-- Name: doc_books; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.doc_books (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    type_id smallint NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    sort_order integer DEFAULT 0,
    is_default boolean DEFAULT false,
    is_deleted boolean DEFAULT false,
    created_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE doc_books; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.doc_books IS 'Sổ văn bản: type_id 1=đến, 2=đi, 3=dự thảo';


--
-- Name: doc_books_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.doc_books_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doc_books_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.doc_books_id_seq OWNED BY edoc.doc_books.id;


--
-- Name: doc_columns; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.doc_columns (
    id integer NOT NULL,
    type_id smallint NOT NULL,
    column_name character varying(100) NOT NULL,
    label character varying(200) NOT NULL,
    is_mandatory boolean DEFAULT false,
    is_show_all boolean DEFAULT true,
    sort_order integer DEFAULT 0,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    data_type character varying(50) DEFAULT 'text'::character varying,
    max_length integer,
    is_system boolean DEFAULT false
);


--
-- Name: TABLE doc_columns; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.doc_columns IS 'Thuoc tinh van ban theo loai (den/di/du thao)';


--
-- Name: doc_columns_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.doc_columns_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doc_columns_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.doc_columns_id_seq OWNED BY edoc.doc_columns.id;


--
-- Name: doc_fields; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.doc_fields (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(200) NOT NULL,
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE doc_fields; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.doc_fields IS 'Lĩnh vực văn bản theo đơn vị';


--
-- Name: doc_fields_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.doc_fields_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doc_fields_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.doc_fields_id_seq OWNED BY edoc.doc_fields.id;


--
-- Name: doc_flow_step_links; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.doc_flow_step_links (
    id integer NOT NULL,
    from_step_id integer NOT NULL,
    to_step_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE doc_flow_step_links; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.doc_flow_step_links IS 'Liên kết định tuyến giữa các bước quy trình';


--
-- Name: doc_flow_step_links_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.doc_flow_step_links_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doc_flow_step_links_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.doc_flow_step_links_id_seq OWNED BY edoc.doc_flow_step_links.id;


--
-- Name: doc_flow_step_staff; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.doc_flow_step_staff (
    id integer NOT NULL,
    step_id integer NOT NULL,
    staff_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: TABLE doc_flow_step_staff; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.doc_flow_step_staff IS 'Cán bộ được giao thực hiện từng bước quy trình';


--
-- Name: doc_flow_step_staff_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.doc_flow_step_staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doc_flow_step_staff_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.doc_flow_step_staff_id_seq OWNED BY edoc.doc_flow_step_staff.id;


--
-- Name: doc_flow_steps; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.doc_flow_steps (
    id integer NOT NULL,
    flow_id integer NOT NULL,
    step_name character varying(500) NOT NULL,
    step_order integer DEFAULT 0 NOT NULL,
    step_type character varying(50) DEFAULT 'process'::character varying NOT NULL,
    allow_sign boolean DEFAULT false NOT NULL,
    deadline_days integer DEFAULT 0 NOT NULL,
    position_x double precision DEFAULT 0 NOT NULL,
    position_y double precision DEFAULT 0 NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT chk_doc_flow_steps_type CHECK (((step_type)::text = ANY ((ARRAY['start'::character varying, 'process'::character varying, 'end'::character varying])::text[])))
);


--
-- Name: TABLE doc_flow_steps; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.doc_flow_steps IS 'Các bước trong một quy trình xử lý';


--
-- Name: doc_flow_steps_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.doc_flow_steps_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doc_flow_steps_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.doc_flow_steps_id_seq OWNED BY edoc.doc_flow_steps.id;


--
-- Name: doc_flows; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.doc_flows (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    name character varying(500) NOT NULL,
    version character varying(50),
    doc_field_id integer,
    is_active boolean DEFAULT true NOT NULL,
    created_by integer,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    department_id integer
);


--
-- Name: TABLE doc_flows; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.doc_flows IS 'Quy trình xử lý văn bản / hồ sơ công việc';


--
-- Name: doc_flows_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.doc_flows_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doc_flows_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.doc_flows_id_seq OWNED BY edoc.doc_flows.id;


--
-- Name: doc_types; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.doc_types (
    id integer NOT NULL,
    type_id smallint NOT NULL,
    code character varying(20) NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    sort_order integer DEFAULT 0,
    notation_type smallint DEFAULT 0,
    is_default boolean DEFAULT false,
    is_deleted boolean DEFAULT false,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    parent_id integer
);


--
-- Name: TABLE doc_types; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.doc_types IS 'Loại văn bản: CV=Công văn, NQ=Nghị quyết, QĐ=Quyết định...';


--
-- Name: doc_types_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.doc_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: doc_types_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.doc_types_id_seq OWNED BY edoc.doc_types.id;


--
-- Name: drafting_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.drafting_docs (
    id bigint NOT NULL,
    unit_id integer NOT NULL,
    received_date timestamp with time zone,
    number integer,
    sub_number character varying(20),
    notation character varying(100),
    abstract text,
    drafting_unit_id integer,
    drafting_user_id integer,
    publish_unit_id integer,
    publish_date timestamp with time zone,
    signer character varying(200),
    sign_date timestamp with time zone,
    number_paper integer DEFAULT 1,
    number_copies integer DEFAULT 1,
    secret_id smallint DEFAULT 1,
    urgent_id smallint DEFAULT 1,
    recipients text,
    doc_book_id integer,
    doc_type_id integer,
    doc_field_id integer,
    approved boolean DEFAULT false,
    is_released boolean DEFAULT false,
    released_date timestamp with time zone,
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now(),
    approver character varying(200),
    expired_date timestamp with time zone,
    document_code character varying(100),
    reject_reason text,
    extra_fields jsonb DEFAULT '{}'::jsonb,
    department_id integer,
    rejected_by integer,
    rejection_reason text
);


--
-- Name: TABLE drafting_docs; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.drafting_docs IS 'Văn bản dự thảo — khi duyệt xong sẽ chuyển thành VB đi';


--
-- Name: COLUMN drafting_docs.reject_reason; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.drafting_docs.reject_reason IS 'Ly do tu choi (ghi boi nguoi tu choi)';


--
-- Name: COLUMN drafting_docs.extra_fields; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.drafting_docs.extra_fields IS 'Trường bổ sung theo cấu hình doc_columns (dynamic form)';


--
-- Name: drafting_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.drafting_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: drafting_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.drafting_docs_id_seq OWNED BY edoc.drafting_docs.id;


--
-- Name: email_templates; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.email_templates (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    name character varying(200) NOT NULL,
    subject character varying(500),
    content text NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE email_templates; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.email_templates IS 'Mau email thong bao (HTML)';


--
-- Name: email_templates_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.email_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: email_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.email_templates_id_seq OWNED BY edoc.email_templates.id;


--
-- Name: handling_doc_links; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.handling_doc_links (
    id bigint NOT NULL,
    handling_doc_id bigint NOT NULL,
    doc_type character varying(20) NOT NULL,
    doc_id bigint NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: handling_doc_links_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.handling_doc_links_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: handling_doc_links_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.handling_doc_links_id_seq OWNED BY edoc.handling_doc_links.id;


--
-- Name: handling_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.handling_docs (
    id bigint NOT NULL,
    unit_id integer NOT NULL,
    department_id integer,
    name character varying(500) NOT NULL,
    abstract text,
    comments text,
    doc_notation character varying(100),
    doc_type_id integer,
    doc_field_id integer,
    doc_book_id integer,
    start_date timestamp with time zone,
    end_date timestamp with time zone,
    received_date timestamp with time zone,
    curator integer,
    signer integer,
    status smallint DEFAULT 0,
    sign_status smallint DEFAULT 0,
    sign_date timestamp with time zone,
    progress smallint DEFAULT 0,
    workflow_id integer,
    step character varying(50),
    complete_user_id integer,
    complete_date timestamp with time zone,
    publish_unit_id integer,
    publish_name character varying(500),
    drafting_unit_id integer,
    number integer,
    sub_number character varying(20),
    notation character varying(100),
    parent_id bigint,
    root_id bigint,
    is_from_doc boolean DEFAULT false,
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE handling_docs; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.handling_docs IS 'Hồ sơ công việc — quản lý xử lý văn bản theo workflow';


--
-- Name: handling_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.handling_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: handling_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.handling_docs_id_seq OWNED BY edoc.handling_docs.id;


--
-- Name: incoming_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.incoming_docs (
    id bigint NOT NULL,
    unit_id integer NOT NULL,
    received_date timestamp with time zone,
    number integer,
    notation character varying(100),
    document_code character varying(100),
    abstract text,
    publish_unit character varying(500),
    publish_date timestamp with time zone,
    signer character varying(200),
    sign_date timestamp with time zone,
    doc_book_id integer,
    doc_type_id integer,
    doc_field_id integer,
    secret_id smallint DEFAULT 1,
    urgent_id smallint DEFAULT 1,
    number_paper integer DEFAULT 1,
    number_copies integer DEFAULT 1,
    expired_date timestamp with time zone,
    recipients text,
    approver character varying(200),
    approved boolean DEFAULT false,
    is_handling boolean DEFAULT false,
    is_received_paper boolean DEFAULT false,
    archive_status boolean DEFAULT false,
    is_inter_doc boolean DEFAULT false,
    inter_doc_id integer,
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now(),
    sents text,
    received_paper_date timestamp with time zone,
    extra_fields jsonb DEFAULT '{}'::jsonb,
    department_id integer,
    rejected_by integer,
    rejection_reason text
);


--
-- Name: TABLE incoming_docs; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.incoming_docs IS 'Văn bản đến — bảng chính';


--
-- Name: COLUMN incoming_docs.sents; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.incoming_docs.sents IS 'Noi gui van ban (source cu: Sents)';


--
-- Name: COLUMN incoming_docs.received_paper_date; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.incoming_docs.received_paper_date IS 'Ngay nhan ban giay (chi co khi is_received_paper=true)';


--
-- Name: COLUMN incoming_docs.extra_fields; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.incoming_docs.extra_fields IS 'Trường bổ sung theo cấu hình doc_columns (dynamic form)';


--
-- Name: incoming_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.incoming_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: incoming_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.incoming_docs_id_seq OWNED BY edoc.incoming_docs.id;


--
-- Name: inter_incoming_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.inter_incoming_docs (
    id bigint NOT NULL,
    unit_id integer NOT NULL,
    received_date timestamp without time zone DEFAULT now(),
    notation character varying(100),
    document_code character varying(100),
    abstract text,
    publish_unit character varying(300),
    publish_date date,
    signer character varying(200),
    sign_date date,
    expired_date date,
    doc_type_id integer,
    status character varying(50) DEFAULT 'pending'::character varying,
    source_system character varying(100),
    external_doc_id character varying(200),
    created_by integer,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    organ_id character varying(100),
    from_organ_id character varying(100),
    number_paper integer DEFAULT 1,
    number_copies integer DEFAULT 1,
    secret_id smallint DEFAULT 1,
    urgent_id smallint DEFAULT 1,
    recipients text,
    doc_field_id integer,
    department_id integer
);


--
-- Name: TABLE inter_incoming_docs; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.inter_incoming_docs IS 'Văn bản đến liên thông — nhận từ hệ thống LGSP bên ngoài';


--
-- Name: COLUMN inter_incoming_docs.organ_id; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.inter_incoming_docs.organ_id IS 'Ma don vi gui (LGSP OrganID)';


--
-- Name: COLUMN inter_incoming_docs.from_organ_id; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.inter_incoming_docs.from_organ_id IS 'Ma don vi nhan (LGSP FromOrganID)';


--
-- Name: inter_incoming_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.inter_incoming_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: inter_incoming_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.inter_incoming_docs_id_seq OWNED BY edoc.inter_incoming_docs.id;


--
-- Name: leader_notes; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.leader_notes (
    id bigint NOT NULL,
    incoming_doc_id bigint,
    staff_id integer NOT NULL,
    content text NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    outgoing_doc_id bigint,
    drafting_doc_id bigint,
    expired_date timestamp with time zone,
    assigned_staff_ids integer[],
    CONSTRAINT chk_leader_note_doc_type CHECK ((((((incoming_doc_id IS NOT NULL))::integer + ((outgoing_doc_id IS NOT NULL))::integer) + ((drafting_doc_id IS NOT NULL))::integer) = 1))
);


--
-- Name: COLUMN leader_notes.expired_date; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.leader_notes.expired_date IS 'Hạn giải quyết (khi phân công)';


--
-- Name: COLUMN leader_notes.assigned_staff_ids; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.leader_notes.assigned_staff_ids IS 'Danh sách cán bộ được phân công';


--
-- Name: leader_notes_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.leader_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: leader_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.leader_notes_id_seq OWNED BY edoc.leader_notes.id;


--
-- Name: lgsp_config; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.lgsp_config (
    id integer NOT NULL,
    unit_id integer,
    endpoint_url character varying(500) DEFAULT 'https://lgsp.laocai.gov.vn/api'::character varying NOT NULL,
    org_code character varying(100) NOT NULL,
    username character varying(100),
    password_encrypted character varying(200),
    polling_interval_sec integer DEFAULT 300,
    is_active boolean DEFAULT true,
    last_sync_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: lgsp_config_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.lgsp_config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lgsp_config_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.lgsp_config_id_seq OWNED BY edoc.lgsp_config.id;


--
-- Name: lgsp_organizations; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.lgsp_organizations (
    id bigint NOT NULL,
    org_code character varying(100) NOT NULL,
    org_name character varying(500) NOT NULL,
    parent_code character varying(100),
    address character varying(500),
    email character varying(200),
    phone character varying(50),
    is_active boolean DEFAULT true,
    synced_at timestamp with time zone DEFAULT now(),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE lgsp_organizations; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.lgsp_organizations IS 'Danh sach co quan lien thong dong bo tu LGSP';


--
-- Name: lgsp_organizations_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.lgsp_organizations_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lgsp_organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.lgsp_organizations_id_seq OWNED BY edoc.lgsp_organizations.id;


--
-- Name: lgsp_tracking; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.lgsp_tracking (
    id bigint NOT NULL,
    outgoing_doc_id bigint,
    incoming_doc_id bigint,
    direction character varying(10) NOT NULL,
    lgsp_doc_id character varying(200),
    dest_org_code character varying(100),
    dest_org_name character varying(500),
    edxml_content text,
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    error_message text,
    sent_at timestamp with time zone,
    received_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    created_by integer,
    CONSTRAINT lgsp_tracking_direction_check CHECK (((direction)::text = ANY ((ARRAY['send'::character varying, 'receive'::character varying])::text[]))),
    CONSTRAINT lgsp_tracking_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'processing'::character varying, 'success'::character varying, 'error'::character varying])::text[])))
);


--
-- Name: TABLE lgsp_tracking; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.lgsp_tracking IS 'Tracking trang thai gui/nhan van ban lien thong LGSP';


--
-- Name: lgsp_tracking_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.lgsp_tracking_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: lgsp_tracking_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.lgsp_tracking_id_seq OWNED BY edoc.lgsp_tracking.id;


--
-- Name: meeting_types; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.meeting_types (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    name character varying(200) NOT NULL,
    description text,
    sort_order integer DEFAULT 0,
    is_deleted boolean DEFAULT false,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone
);


--
-- Name: TABLE meeting_types; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.meeting_types IS 'Loại cuộc họp — ánh xạ từ RoomGroups.cs';


--
-- Name: meeting_types_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.meeting_types_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: meeting_types_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.meeting_types_id_seq OWNED BY edoc.meeting_types.id;


--
-- Name: message_recipients; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.message_recipients (
    id bigint NOT NULL,
    message_id bigint NOT NULL,
    staff_id integer NOT NULL,
    is_read boolean DEFAULT false,
    read_at timestamp without time zone,
    is_deleted boolean DEFAULT false,
    deleted_at timestamp without time zone
);


--
-- Name: TABLE message_recipients; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.message_recipients IS 'Người nhận tin nhắn — mỗi người nhận 1 bản copy riêng';


--
-- Name: message_recipients_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.message_recipients_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: message_recipients_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.message_recipients_id_seq OWNED BY edoc.message_recipients.id;


--
-- Name: messages; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.messages (
    id bigint NOT NULL,
    from_staff_id integer NOT NULL,
    subject character varying(200) NOT NULL,
    content text NOT NULL,
    parent_id bigint,
    created_at timestamp without time zone DEFAULT now(),
    sender_deleted boolean DEFAULT false,
    sender_deleted_at timestamp with time zone
);


--
-- Name: TABLE messages; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.messages IS 'Tin nhắn nội bộ — parent_id NULL = tin nhắn gốc, có giá trị = trả lời';


--
-- Name: messages_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.messages_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: messages_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.messages_id_seq OWNED BY edoc.messages.id;


--
-- Name: notice_reads; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.notice_reads (
    id bigint NOT NULL,
    notice_id bigint NOT NULL,
    staff_id integer NOT NULL,
    read_at timestamp without time zone DEFAULT now()
);


--
-- Name: TABLE notice_reads; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.notice_reads IS 'Lịch sử đọc thông báo — mỗi user 1 bản ghi per thông báo';


--
-- Name: notice_reads_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.notice_reads_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notice_reads_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.notice_reads_id_seq OWNED BY edoc.notice_reads.id;


--
-- Name: notices; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.notices (
    id bigint NOT NULL,
    unit_id integer,
    title character varying(300) NOT NULL,
    content text NOT NULL,
    notice_type character varying(50) DEFAULT 'system'::character varying,
    created_by integer,
    created_at timestamp without time zone DEFAULT now(),
    department_id integer
);


--
-- Name: TABLE notices; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.notices IS 'Thông báo hệ thống — system/admin gửi toàn đơn vị';


--
-- Name: notices_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.notices_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notices_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.notices_id_seq OWNED BY edoc.notices.id;


--
-- Name: notification_logs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.notification_logs (
    id bigint NOT NULL,
    staff_id integer NOT NULL,
    channel character varying(20) NOT NULL,
    event_type character varying(50) NOT NULL,
    title character varying(500),
    body text,
    ref_type character varying(30),
    ref_id bigint,
    send_status character varying(20) DEFAULT 'pending'::character varying NOT NULL,
    error_message text,
    sent_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    CONSTRAINT notification_logs_channel_check CHECK (((channel)::text = ANY ((ARRAY['fcm'::character varying, 'zalo'::character varying, 'sms'::character varying, 'email'::character varying])::text[]))),
    CONSTRAINT notification_logs_send_status_check CHECK (((send_status)::text = ANY ((ARRAY['pending'::character varying, 'sent'::character varying, 'failed'::character varying])::text[])))
);


--
-- Name: TABLE notification_logs; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.notification_logs IS 'Log tat ca thong bao gui qua cac kenh (FCM, Zalo, SMS, Email)';


--
-- Name: notification_logs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.notification_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.notification_logs_id_seq OWNED BY edoc.notification_logs.id;


--
-- Name: notification_preferences; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.notification_preferences (
    id bigint NOT NULL,
    staff_id integer NOT NULL,
    channel character varying(20) NOT NULL,
    is_enabled boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    CONSTRAINT notification_preferences_channel_check CHECK (((channel)::text = ANY ((ARRAY['fcm'::character varying, 'zalo'::character varying, 'sms'::character varying, 'email'::character varying])::text[])))
);


--
-- Name: TABLE notification_preferences; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.notification_preferences IS 'Cau hinh kenh thong bao theo user';


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.notification_preferences_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_preferences_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.notification_preferences_id_seq OWNED BY edoc.notification_preferences.id;


--
-- Name: opinion_handling_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.opinion_handling_docs (
    id bigint NOT NULL,
    handling_doc_id bigint NOT NULL,
    staff_id integer NOT NULL,
    content text NOT NULL,
    attachment_path character varying(1000),
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: opinion_handling_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.opinion_handling_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: opinion_handling_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.opinion_handling_docs_id_seq OWNED BY edoc.opinion_handling_docs.id;


--
-- Name: organizations; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.organizations (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    code character varying(20),
    name character varying(200),
    address text,
    phone character varying(20),
    fax character varying(20),
    email character varying(100),
    email_doc character varying(100),
    secretary character varying(200),
    chairman_number character varying(20),
    level smallint DEFAULT 1,
    is_exchange boolean DEFAULT false,
    lgsp_system_id character varying(50),
    lgsp_secret_key character varying(100),
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE organizations; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.organizations IS 'Thong tin co quan - 1 ban ghi / don vi';


--
-- Name: organizations_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.organizations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: organizations_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.organizations_id_seq OWNED BY edoc.organizations.id;


--
-- Name: outgoing_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.outgoing_docs (
    id bigint NOT NULL,
    unit_id integer NOT NULL,
    received_date timestamp with time zone,
    number integer,
    sub_number character varying(20),
    notation character varying(100),
    document_code character varying(100),
    abstract text,
    drafting_unit_id integer,
    drafting_user_id integer,
    publish_unit_id integer,
    publish_date timestamp with time zone,
    signer character varying(200),
    sign_date timestamp with time zone,
    expired_date timestamp with time zone,
    number_paper integer DEFAULT 1,
    number_copies integer DEFAULT 1,
    secret_id smallint DEFAULT 1,
    urgent_id smallint DEFAULT 1,
    recipients text,
    doc_book_id integer,
    doc_type_id integer,
    doc_field_id integer,
    approved boolean DEFAULT false,
    is_handling boolean DEFAULT false,
    archive_status boolean DEFAULT false,
    is_inter_doc boolean DEFAULT false,
    inter_doc_id bigint,
    is_digital_signed smallint DEFAULT 0,
    created_by integer NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now(),
    approver character varying(200),
    extra_fields jsonb DEFAULT '{}'::jsonb,
    department_id integer,
    rejected_by integer,
    rejection_reason text
);


--
-- Name: TABLE outgoing_docs; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.outgoing_docs IS 'Văn bản đi / phát hành';


--
-- Name: COLUMN outgoing_docs.extra_fields; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.outgoing_docs.extra_fields IS 'Trường bổ sung theo cấu hình doc_columns (dynamic form)';


--
-- Name: outgoing_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.outgoing_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: outgoing_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.outgoing_docs_id_seq OWNED BY edoc.outgoing_docs.id;


--
-- Name: room_schedule_answers; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.room_schedule_answers (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    room_schedule_id integer NOT NULL,
    room_schedule_question_id uuid NOT NULL,
    name character varying(500) NOT NULL,
    order_no integer DEFAULT 0,
    is_other boolean DEFAULT false
);


--
-- Name: TABLE room_schedule_answers; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.room_schedule_answers IS 'Đáp án biểu quyết — ánh xạ từ RoomScheduleAnswer.cs';


--
-- Name: room_schedule_attachments; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.room_schedule_attachments (
    id bigint NOT NULL,
    room_schedule_id integer NOT NULL,
    file_name character varying(500) NOT NULL,
    file_path character varying(1000) NOT NULL,
    file_size bigint,
    mime_type character varying(200),
    description text,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE room_schedule_attachments; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.room_schedule_attachments IS 'Tài liệu đính kèm cuộc họp';


--
-- Name: room_schedule_attachments_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.room_schedule_attachments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: room_schedule_attachments_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.room_schedule_attachments_id_seq OWNED BY edoc.room_schedule_attachments.id;


--
-- Name: room_schedule_questions; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.room_schedule_questions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    room_schedule_id integer NOT NULL,
    name character varying(500) NOT NULL,
    start_time timestamp with time zone,
    stop_time timestamp with time zone,
    duration integer DEFAULT 60,
    status integer DEFAULT 0,
    question_type integer DEFAULT 0,
    order_no integer DEFAULT 0
);


--
-- Name: TABLE room_schedule_questions; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.room_schedule_questions IS 'Câu hỏi biểu quyết — ánh xạ từ RoomScheduleQuestion.cs';


--
-- Name: room_schedule_staff; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.room_schedule_staff (
    id integer NOT NULL,
    room_schedule_id integer NOT NULL,
    staff_id integer NOT NULL,
    user_type integer DEFAULT 0,
    is_secretary boolean DEFAULT false,
    is_represent boolean DEFAULT false,
    attendance boolean DEFAULT false,
    attendance_date timestamp with time zone,
    attendance_note text,
    received_appointment integer DEFAULT 0,
    received_appointment_date timestamp with time zone,
    view_date timestamp with time zone
);


--
-- Name: TABLE room_schedule_staff; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.room_schedule_staff IS 'Thành viên cuộc họp — ánh xạ từ RoomScheduleStaff.cs';


--
-- Name: room_schedule_staff_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.room_schedule_staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: room_schedule_staff_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.room_schedule_staff_id_seq OWNED BY edoc.room_schedule_staff.id;


--
-- Name: room_schedule_votes; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.room_schedule_votes (
    id bigint NOT NULL,
    room_schedule_id integer NOT NULL,
    question_id uuid NOT NULL,
    answer_id uuid NOT NULL,
    staff_id integer NOT NULL,
    other_text text,
    voted_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE room_schedule_votes; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.room_schedule_votes IS 'Kết quả biểu quyết realtime — T-05-03: unique(question_id, staff_id)';


--
-- Name: room_schedule_votes_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.room_schedule_votes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: room_schedule_votes_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.room_schedule_votes_id_seq OWNED BY edoc.room_schedule_votes.id;


--
-- Name: room_schedules; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.room_schedules (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    room_id integer NOT NULL,
    meeting_type_id integer,
    name character varying(500) NOT NULL,
    content text,
    component character varying(500),
    start_date date NOT NULL,
    end_date date,
    start_time character varying(10),
    end_time character varying(10),
    master_id integer,
    secretary_id integer,
    approved integer DEFAULT 0,
    approved_date timestamp with time zone,
    approved_staff_id integer,
    rejection_reason text,
    meeting_status integer DEFAULT 0,
    online_link character varying(500),
    is_cancel integer DEFAULT 0,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone,
    department_id integer
);


--
-- Name: TABLE room_schedules; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.room_schedules IS 'Lịch họp / cuộc họp — ánh xạ từ RoomSchedule.cs';


--
-- Name: room_schedules_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.room_schedules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: room_schedules_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.room_schedules_id_seq OWNED BY edoc.room_schedules.id;


--
-- Name: rooms; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.rooms (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    name character varying(200) NOT NULL,
    code character varying(50),
    location character varying(500),
    note text,
    sort_order integer DEFAULT 0,
    show_in_calendar boolean DEFAULT true,
    is_deleted boolean DEFAULT false,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone
);


--
-- Name: TABLE rooms; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.rooms IS 'Phòng họp — ánh xạ từ Room.cs';


--
-- Name: rooms_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.rooms_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rooms_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.rooms_id_seq OWNED BY edoc.rooms.id;


--
-- Name: send_doc_user_configs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.send_doc_user_configs (
    id integer NOT NULL,
    user_id integer NOT NULL,
    target_user_id integer NOT NULL,
    config_type character varying(20) DEFAULT 'doc'::character varying NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE send_doc_user_configs; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.send_doc_user_configs IS 'Cấu hình gửi nhanh — preset danh sách người nhận per user';


--
-- Name: send_doc_user_configs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.send_doc_user_configs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: send_doc_user_configs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.send_doc_user_configs_id_seq OWNED BY edoc.send_doc_user_configs.id;


--
-- Name: signers; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.signers (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    department_id integer,
    staff_id integer NOT NULL,
    sort_order integer DEFAULT 0,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE signers; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.signers IS 'Danh sach nguoi ky van ban theo don vi';


--
-- Name: signers_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.signers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: signers_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.signers_id_seq OWNED BY edoc.signers.id;


--
-- Name: sms_templates; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.sms_templates (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    name character varying(200) NOT NULL,
    content text NOT NULL,
    description text,
    is_active boolean DEFAULT true,
    created_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE sms_templates; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.sms_templates IS 'Mau tin nhan SMS';


--
-- Name: sms_templates_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.sms_templates_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sms_templates_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.sms_templates_id_seq OWNED BY edoc.sms_templates.id;


--
-- Name: staff_handling_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.staff_handling_docs (
    id bigint NOT NULL,
    handling_doc_id bigint NOT NULL,
    staff_id integer NOT NULL,
    role smallint DEFAULT 1,
    step character varying(50),
    assigned_at timestamp with time zone DEFAULT now(),
    completed_at timestamp with time zone
);


--
-- Name: staff_handling_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.staff_handling_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_handling_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.staff_handling_docs_id_seq OWNED BY edoc.staff_handling_docs.id;


--
-- Name: staff_notes; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.staff_notes (
    id bigint NOT NULL,
    doc_type character varying(20) NOT NULL,
    doc_id bigint NOT NULL,
    staff_id integer NOT NULL,
    note text,
    created_at timestamp with time zone DEFAULT now(),
    is_important boolean DEFAULT false
);


--
-- Name: COLUMN staff_notes.is_important; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.staff_notes.is_important IS 'Danh dau quan trong (source cu: IsImportant)';


--
-- Name: staff_notes_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.staff_notes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_notes_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.staff_notes_id_seq OWNED BY edoc.staff_notes.id;


--
-- Name: user_drafting_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.user_drafting_docs (
    id bigint NOT NULL,
    drafting_doc_id bigint NOT NULL,
    staff_id integer NOT NULL,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    sent_by integer,
    expired_date timestamp with time zone
);


--
-- Name: COLUMN user_drafting_docs.sent_by; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.user_drafting_docs.sent_by IS 'Nguoi gui (staff_id)';


--
-- Name: COLUMN user_drafting_docs.expired_date; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.user_drafting_docs.expired_date IS 'Han xu ly per-person';


--
-- Name: user_drafting_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.user_drafting_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_drafting_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.user_drafting_docs_id_seq OWNED BY edoc.user_drafting_docs.id;


--
-- Name: user_incoming_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.user_incoming_docs (
    id bigint NOT NULL,
    incoming_doc_id bigint NOT NULL,
    staff_id integer NOT NULL,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: user_incoming_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.user_incoming_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_incoming_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.user_incoming_docs_id_seq OWNED BY edoc.user_incoming_docs.id;


--
-- Name: user_outgoing_docs; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.user_outgoing_docs (
    id bigint NOT NULL,
    outgoing_doc_id bigint NOT NULL,
    staff_id integer NOT NULL,
    is_read boolean DEFAULT false,
    read_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now(),
    sent_by integer,
    expired_date timestamp with time zone
);


--
-- Name: COLUMN user_outgoing_docs.sent_by; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.user_outgoing_docs.sent_by IS 'Nguoi gui (staff_id)';


--
-- Name: COLUMN user_outgoing_docs.expired_date; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON COLUMN edoc.user_outgoing_docs.expired_date IS 'Han xu ly per-person';


--
-- Name: user_outgoing_docs_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.user_outgoing_docs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: user_outgoing_docs_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.user_outgoing_docs_id_seq OWNED BY edoc.user_outgoing_docs.id;


--
-- Name: work_group_members; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.work_group_members (
    id integer NOT NULL,
    group_id integer NOT NULL,
    staff_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE work_group_members; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.work_group_members IS 'Thanh vien nhom xu ly';


--
-- Name: work_group_members_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.work_group_members_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_group_members_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.work_group_members_id_seq OWNED BY edoc.work_group_members.id;


--
-- Name: work_groups; Type: TABLE; Schema: edoc; Owner: -
--

CREATE TABLE edoc.work_groups (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    name character varying(200) NOT NULL,
    function text,
    sort_order integer DEFAULT 0,
    is_deleted boolean DEFAULT false,
    created_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE work_groups; Type: COMMENT; Schema: edoc; Owner: -
--

COMMENT ON TABLE edoc.work_groups IS 'Nhom xu ly cong viec';


--
-- Name: work_groups_id_seq; Type: SEQUENCE; Schema: edoc; Owner: -
--

CREATE SEQUENCE edoc.work_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: edoc; Owner: -
--

ALTER SEQUENCE edoc.work_groups_id_seq OWNED BY edoc.work_groups.id;


--
-- Name: borrow_request_records; Type: TABLE; Schema: esto; Owner: -
--

CREATE TABLE esto.borrow_request_records (
    id bigint NOT NULL,
    borrow_request_id bigint NOT NULL,
    record_id bigint NOT NULL,
    return_date date,
    actual_return_date date
);


--
-- Name: TABLE borrow_request_records; Type: COMMENT; Schema: esto; Owner: -
--

COMMENT ON TABLE esto.borrow_request_records IS 'Chi tiết hồ sơ trong yêu cầu mượn/trả';


--
-- Name: borrow_request_records_id_seq; Type: SEQUENCE; Schema: esto; Owner: -
--

CREATE SEQUENCE esto.borrow_request_records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: borrow_request_records_id_seq; Type: SEQUENCE OWNED BY; Schema: esto; Owner: -
--

ALTER SEQUENCE esto.borrow_request_records_id_seq OWNED BY esto.borrow_request_records.id;


--
-- Name: borrow_requests; Type: TABLE; Schema: esto; Owner: -
--

CREATE TABLE esto.borrow_requests (
    id bigint NOT NULL,
    name character varying(200) NOT NULL,
    unit_id integer NOT NULL,
    emergency integer,
    notice text,
    borrow_date date,
    status integer DEFAULT 0,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone,
    department_id integer
);


--
-- Name: TABLE borrow_requests; Type: COMMENT; Schema: esto; Owner: -
--

COMMENT ON TABLE esto.borrow_requests IS 'Yêu cầu mượn/trả hồ sơ lưu trữ — ánh xạ từ BorrowRequest.cs';


--
-- Name: borrow_requests_id_seq; Type: SEQUENCE; Schema: esto; Owner: -
--

CREATE SEQUENCE esto.borrow_requests_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: borrow_requests_id_seq; Type: SEQUENCE OWNED BY; Schema: esto; Owner: -
--

ALTER SEQUENCE esto.borrow_requests_id_seq OWNED BY esto.borrow_requests.id;


--
-- Name: document_archives; Type: TABLE; Schema: esto; Owner: -
--

CREATE TABLE esto.document_archives (
    id bigint NOT NULL,
    doc_type character varying(20) NOT NULL,
    doc_id bigint NOT NULL,
    fond_id integer,
    warehouse_id integer,
    record_id bigint,
    file_catalog character varying(200),
    file_notation character varying(100),
    doc_ordinal integer,
    language character varying(50) DEFAULT 'Tiếng Việt'::character varying,
    autograph text,
    keyword text,
    format character varying(50) DEFAULT 'Điện tử'::character varying,
    confidence_level character varying(50),
    is_original boolean DEFAULT true,
    archive_date timestamp with time zone DEFAULT now(),
    archived_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: document_archives_id_seq; Type: SEQUENCE; Schema: esto; Owner: -
--

CREATE SEQUENCE esto.document_archives_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: document_archives_id_seq; Type: SEQUENCE OWNED BY; Schema: esto; Owner: -
--

ALTER SEQUENCE esto.document_archives_id_seq OWNED BY esto.document_archives.id;


--
-- Name: fonds; Type: TABLE; Schema: esto; Owner: -
--

CREATE TABLE esto.fonds (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    parent_id integer DEFAULT 0,
    fond_code character varying(50),
    fond_name character varying(200) NOT NULL,
    fond_history text,
    archives_time character varying(100),
    paper_total numeric,
    paper_digital numeric,
    keys_group character varying(200),
    other_type character varying(200),
    language character varying(100),
    lookup_tools character varying(200),
    coppy_number numeric,
    status integer DEFAULT 1,
    description text,
    version numeric,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone
);


--
-- Name: TABLE fonds; Type: COMMENT; Schema: esto; Owner: -
--

COMMENT ON TABLE esto.fonds IS 'Phông lưu trữ — ánh xạ từ Fond.cs';


--
-- Name: fonds_id_seq; Type: SEQUENCE; Schema: esto; Owner: -
--

CREATE SEQUENCE esto.fonds_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fonds_id_seq; Type: SEQUENCE OWNED BY; Schema: esto; Owner: -
--

ALTER SEQUENCE esto.fonds_id_seq OWNED BY esto.fonds.id;


--
-- Name: records; Type: TABLE; Schema: esto; Owner: -
--

CREATE TABLE esto.records (
    id bigint NOT NULL,
    unit_id integer NOT NULL,
    fond_id integer NOT NULL,
    file_code character varying(100),
    file_catalog integer,
    file_notation character varying(200),
    title character varying(500) NOT NULL,
    maintenance character varying(200),
    rights character varying(200),
    language character varying(100),
    start_date date,
    complete_date date,
    total_doc integer,
    description text,
    infor_sign character varying(200),
    keyword character varying(500),
    total_paper numeric,
    page_number numeric,
    format integer DEFAULT 0,
    archive_date date,
    reception_archive_id integer,
    in_charge_staff_id integer NOT NULL,
    parent_id integer DEFAULT 0,
    warehouse_id integer NOT NULL,
    reception_date date,
    reception_from integer DEFAULT 0,
    transfer_staff character varying(200),
    is_document_original boolean,
    number_of_copy integer,
    doc_field_id integer,
    transfer_online_status boolean DEFAULT false,
    created_user_id integer,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone,
    department_id integer
);


--
-- Name: TABLE records; Type: COMMENT; Schema: esto; Owner: -
--

COMMENT ON TABLE esto.records IS 'Hồ sơ lưu trữ — ánh xạ từ Record.cs';


--
-- Name: records_id_seq; Type: SEQUENCE; Schema: esto; Owner: -
--

CREATE SEQUENCE esto.records_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: records_id_seq; Type: SEQUENCE OWNED BY; Schema: esto; Owner: -
--

ALTER SEQUENCE esto.records_id_seq OWNED BY esto.records.id;


--
-- Name: warehouses; Type: TABLE; Schema: esto; Owner: -
--

CREATE TABLE esto.warehouses (
    id integer NOT NULL,
    unit_id integer NOT NULL,
    type_id integer,
    code character varying(50),
    name character varying(200) NOT NULL,
    phone_number character varying(50),
    address character varying(500),
    status boolean DEFAULT true,
    description text,
    parent_id integer DEFAULT 0,
    is_unit boolean DEFAULT false,
    warehouse_level integer DEFAULT 0,
    limit_child integer DEFAULT 0,
    "position" character varying(200),
    is_deleted boolean DEFAULT false,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone,
    department_id integer
);


--
-- Name: TABLE warehouses; Type: COMMENT; Schema: esto; Owner: -
--

COMMENT ON TABLE esto.warehouses IS 'Kho lưu trữ — cấu trúc cây (parent_id), ánh xạ từ Warehouse.cs';


--
-- Name: warehouses_id_seq; Type: SEQUENCE; Schema: esto; Owner: -
--

CREATE SEQUENCE esto.warehouses_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: warehouses_id_seq; Type: SEQUENCE OWNED BY; Schema: esto; Owner: -
--

ALTER SEQUENCE esto.warehouses_id_seq OWNED BY esto.warehouses.id;


--
-- Name: document_categories; Type: TABLE; Schema: iso; Owner: -
--

CREATE TABLE iso.document_categories (
    id integer NOT NULL,
    parent_id integer DEFAULT 0,
    code character varying(50),
    name character varying(200) NOT NULL,
    date_process numeric,
    status integer DEFAULT 1,
    description text,
    version numeric,
    unit_id integer,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone
);


--
-- Name: TABLE document_categories; Type: COMMENT; Schema: iso; Owner: -
--

COMMENT ON TABLE iso.document_categories IS 'Danh mục tài liệu ISO — cây phân cấp, ánh xạ từ EstoCategory.cs';


--
-- Name: document_categories_id_seq; Type: SEQUENCE; Schema: iso; Owner: -
--

CREATE SEQUENCE iso.document_categories_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: document_categories_id_seq; Type: SEQUENCE OWNED BY; Schema: iso; Owner: -
--

ALTER SEQUENCE iso.document_categories_id_seq OWNED BY iso.document_categories.id;


--
-- Name: documents; Type: TABLE; Schema: iso; Owner: -
--

CREATE TABLE iso.documents (
    id bigint NOT NULL,
    unit_id integer NOT NULL,
    category_id integer,
    title character varying(500) NOT NULL,
    description text,
    file_name character varying(500),
    file_path character varying(1000),
    file_size bigint,
    mime_type character varying(200),
    keyword character varying(500),
    status integer DEFAULT 1,
    created_user_id integer NOT NULL,
    created_date timestamp with time zone DEFAULT now(),
    modified_user_id integer,
    modified_date timestamp with time zone,
    is_deleted boolean DEFAULT false,
    department_id integer
);


--
-- Name: TABLE documents; Type: COMMENT; Schema: iso; Owner: -
--

COMMENT ON TABLE iso.documents IS 'Tài liệu chung — tài liệu ISO, nội bộ, pháp quy';


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: iso; Owner: -
--

CREATE SEQUENCE iso.documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documents_id_seq; Type: SEQUENCE OWNED BY; Schema: iso; Owner: -
--

ALTER SEQUENCE iso.documents_id_seq OWNED BY iso.documents.id;


--
-- Name: action_of_role; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.action_of_role (
    id integer NOT NULL,
    role_id integer NOT NULL,
    right_id integer NOT NULL
);


--
-- Name: TABLE action_of_role; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.action_of_role IS 'Gán quyền chức năng cho nhóm quyền';


--
-- Name: action_of_role_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.action_of_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: action_of_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.action_of_role_id_seq OWNED BY public.action_of_role.id;


--
-- Name: calendar_events; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.calendar_events (
    id bigint NOT NULL,
    title character varying(300) NOT NULL,
    description text,
    start_time timestamp without time zone NOT NULL,
    end_time timestamp without time zone NOT NULL,
    all_day boolean DEFAULT false,
    color character varying(20) DEFAULT '#1B3A5C'::character varying,
    repeat_type character varying(20) DEFAULT 'none'::character varying,
    scope character varying(20) DEFAULT 'personal'::character varying,
    unit_id integer,
    created_by integer NOT NULL,
    created_at timestamp without time zone DEFAULT now(),
    updated_at timestamp without time zone DEFAULT now(),
    is_deleted boolean DEFAULT false,
    department_id integer,
    CONSTRAINT calendar_events_repeat_type_check CHECK (((repeat_type)::text = ANY ((ARRAY['none'::character varying, 'daily'::character varying, 'weekly'::character varying, 'monthly'::character varying])::text[]))),
    CONSTRAINT calendar_events_scope_check CHECK (((scope)::text = ANY ((ARRAY['personal'::character varying, 'unit'::character varying, 'leader'::character varying])::text[])))
);


--
-- Name: TABLE calendar_events; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.calendar_events IS 'Sự kiện lịch — scope: personal (cá nhân), unit (cơ quan), leader (lãnh đạo)';


--
-- Name: calendar_events_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.calendar_events_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: calendar_events_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.calendar_events_id_seq OWNED BY public.calendar_events.id;


--
-- Name: communes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.communes (
    id integer NOT NULL,
    district_id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(10),
    is_active boolean DEFAULT true
);


--
-- Name: communes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.communes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: communes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.communes_id_seq OWNED BY public.communes.id;


--
-- Name: configurations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.configurations (
    id integer NOT NULL,
    unit_id integer,
    key character varying(100) NOT NULL,
    value text,
    description text
);


--
-- Name: TABLE configurations; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.configurations IS 'Cấu hình hệ thống dạng key-value theo đơn vị';


--
-- Name: configurations_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.configurations_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: configurations_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.configurations_id_seq OWNED BY public.configurations.id;


--
-- Name: departments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.departments (
    id integer NOT NULL,
    parent_id integer,
    code character varying(50),
    name character varying(200) NOT NULL,
    name_en character varying(200),
    short_name character varying(50),
    abb_name character varying(20),
    is_unit boolean DEFAULT false,
    level integer DEFAULT 0,
    sort_order integer DEFAULT 0,
    allow_doc_book boolean DEFAULT false,
    description text,
    phone character varying(20),
    fax character varying(20),
    email character varying(100),
    address text,
    lgsp_system_id character varying(50),
    lgsp_secret_key character varying(100),
    is_locked boolean DEFAULT false,
    is_deleted boolean DEFAULT false,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE departments; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.departments IS 'Cây tổ chức: Đơn vị → Phòng ban (self-referencing tree)';


--
-- Name: departments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.departments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: departments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.departments_id_seq OWNED BY public.departments.id;


--
-- Name: districts; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.districts (
    id integer NOT NULL,
    province_id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(10),
    is_active boolean DEFAULT true
);


--
-- Name: districts_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.districts_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: districts_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.districts_id_seq OWNED BY public.districts.id;


--
-- Name: login_history; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.login_history (
    id bigint NOT NULL,
    staff_id integer,
    username character varying(50),
    ip_address character varying(50),
    user_agent text,
    success boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: login_history_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.login_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: login_history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.login_history_id_seq OWNED BY public.login_history.id;


--
-- Name: positions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.positions (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(20),
    sort_order integer DEFAULT 0,
    is_active boolean DEFAULT true,
    description text,
    created_at timestamp with time zone DEFAULT now(),
    updated_at timestamp with time zone DEFAULT now(),
    is_leader boolean DEFAULT false,
    is_handle_document boolean DEFAULT false
);


--
-- Name: TABLE positions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.positions IS 'Danh mục chức vụ: Giám đốc, Phó GĐ, Trưởng phòng, Chuyên viên, Văn thư...';


--
-- Name: COLUMN positions.is_leader; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.positions.is_leader IS 'Chức vụ lãnh đạo (ảnh hưởng workflow ký duyệt)';


--
-- Name: COLUMN positions.is_handle_document; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.positions.is_handle_document IS 'Cho phép xử lý văn bản (phân công VB)';


--
-- Name: positions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.positions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: positions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.positions_id_seq OWNED BY public.positions.id;


--
-- Name: provinces; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.provinces (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    code character varying(10),
    is_active boolean DEFAULT true
);


--
-- Name: provinces_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.provinces_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: provinces_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.provinces_id_seq OWNED BY public.provinces.id;


--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.refresh_tokens (
    id integer NOT NULL,
    staff_id integer NOT NULL,
    token_hash character varying(200) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT now(),
    revoked_at timestamp with time zone
);


--
-- Name: TABLE refresh_tokens; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.refresh_tokens IS 'Lưu refresh token (hashed) — hỗ trợ revoke và single session';


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.refresh_tokens_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: refresh_tokens_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.refresh_tokens_id_seq OWNED BY public.refresh_tokens.id;


--
-- Name: rights; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.rights (
    id integer NOT NULL,
    parent_id integer,
    name character varying(200) NOT NULL,
    name_of_menu character varying(200),
    action_link character varying(500),
    icon character varying(100),
    sort_order integer DEFAULT 0,
    show_menu boolean DEFAULT true,
    default_page boolean DEFAULT false,
    show_in_app boolean DEFAULT false,
    description text,
    is_locked boolean DEFAULT false,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE rights; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.rights IS 'Cây chức năng/menu hệ thống — phân quyền theo chức năng';


--
-- Name: rights_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.rights_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: rights_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.rights_id_seq OWNED BY public.rights.id;


--
-- Name: role_of_staff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.role_of_staff (
    id integer NOT NULL,
    staff_id integer NOT NULL,
    role_id integer NOT NULL
);


--
-- Name: TABLE role_of_staff; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.role_of_staff IS 'Gán nhóm quyền cho nhân viên';


--
-- Name: role_of_staff_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.role_of_staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: role_of_staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.role_of_staff_id_seq OWNED BY public.role_of_staff.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id integer NOT NULL,
    unit_id integer,
    name character varying(100) NOT NULL,
    description text,
    is_locked boolean DEFAULT false,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE roles; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.roles IS 'Nhóm quyền: Ban Lãnh đạo, Cán bộ, Chỉ đạo điều hành, Trưởng phòng, Quản trị, Văn thư';


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: seq_staff_code; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.seq_staff_code
    START WITH 1000
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.staff (
    id integer NOT NULL,
    department_id integer NOT NULL,
    unit_id integer NOT NULL,
    position_id integer,
    username character varying(50) NOT NULL,
    password_hash character varying(200) NOT NULL,
    is_admin boolean DEFAULT false,
    first_name character varying(50),
    last_name character varying(50) NOT NULL,
    full_name character varying(100) GENERATED ALWAYS AS (
CASE
    WHEN (first_name IS NOT NULL) THEN ((((first_name)::text || ' '::text) || (last_name)::text))::character varying
    ELSE last_name
END) STORED,
    gender smallint DEFAULT 0,
    birth_date date,
    email character varying(100),
    phone character varying(20),
    mobile character varying(20),
    address text,
    image character varying(500),
    id_card character varying(20),
    id_card_date date,
    id_card_place character varying(200),
    digital_cert text,
    is_represent_unit boolean DEFAULT false,
    is_represent_department boolean DEFAULT false,
    is_locked boolean DEFAULT false,
    is_deleted boolean DEFAULT false,
    last_login_at timestamp with time zone,
    created_by integer,
    created_at timestamp with time zone DEFAULT now(),
    updated_by integer,
    updated_at timestamp with time zone DEFAULT now(),
    code character varying(20),
    password_changed boolean DEFAULT false,
    sign_phone character varying(20),
    sign_ca text,
    sign_image character varying(500)
);


--
-- Name: TABLE staff; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.staff IS 'Người dùng hệ thống — cán bộ nhân viên';


--
-- Name: COLUMN staff.code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.staff.code IS 'Mã cán bộ (auto-generate từ seq_staff_code)';


--
-- Name: COLUMN staff.password_changed; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.staff.password_changed IS 'Đã đổi mật khẩu lần đầu (bắt đổi pass nếu FALSE)';


--
-- Name: COLUMN staff.sign_phone; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.staff.sign_phone IS 'SĐT ký số từ xa';


--
-- Name: COLUMN staff.sign_ca; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.staff.sign_ca IS 'Chứng thư số (base64)';


--
-- Name: COLUMN staff.sign_image; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.staff.sign_image IS 'Ảnh chữ ký scan (path MinIO)';


--
-- Name: staff_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.staff_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: staff_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.staff_id_seq OWNED BY public.staff.id;


--
-- Name: work_calendar; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.work_calendar (
    id integer NOT NULL,
    date date NOT NULL,
    description character varying(200),
    is_holiday boolean DEFAULT true,
    created_by integer,
    created_at timestamp with time zone DEFAULT now()
);


--
-- Name: TABLE work_calendar; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.work_calendar IS 'Lich ngay nghi / ngay le';


--
-- Name: work_calendar_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.work_calendar_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: work_calendar_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.work_calendar_id_seq OWNED BY public.work_calendar.id;


--
-- Name: contract_attachments id; Type: DEFAULT; Schema: cont; Owner: -
--

ALTER TABLE ONLY cont.contract_attachments ALTER COLUMN id SET DEFAULT nextval('cont.contract_attachments_id_seq'::regclass);


--
-- Name: contract_types id; Type: DEFAULT; Schema: cont; Owner: -
--

ALTER TABLE ONLY cont.contract_types ALTER COLUMN id SET DEFAULT nextval('cont.contract_types_id_seq'::regclass);


--
-- Name: contracts id; Type: DEFAULT; Schema: cont; Owner: -
--

ALTER TABLE ONLY cont.contracts ALTER COLUMN id SET DEFAULT nextval('cont.contracts_id_seq'::regclass);


--
-- Name: attachment_drafting_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_drafting_docs ALTER COLUMN id SET DEFAULT nextval('edoc.attachment_drafting_docs_id_seq'::regclass);


--
-- Name: attachment_handling_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_handling_docs ALTER COLUMN id SET DEFAULT nextval('edoc.attachment_handling_docs_id_seq'::regclass);


--
-- Name: attachment_incoming_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_incoming_docs ALTER COLUMN id SET DEFAULT nextval('edoc.attachment_incoming_docs_id_seq'::regclass);


--
-- Name: attachment_inter_incoming_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_inter_incoming_docs ALTER COLUMN id SET DEFAULT nextval('edoc.attachment_inter_incoming_docs_id_seq'::regclass);


--
-- Name: attachment_outgoing_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_outgoing_docs ALTER COLUMN id SET DEFAULT nextval('edoc.attachment_outgoing_docs_id_seq'::regclass);


--
-- Name: delegations id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.delegations ALTER COLUMN id SET DEFAULT nextval('edoc.delegations_id_seq'::regclass);


--
-- Name: device_tokens id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.device_tokens ALTER COLUMN id SET DEFAULT nextval('edoc.device_tokens_id_seq'::regclass);


--
-- Name: digital_signatures id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.digital_signatures ALTER COLUMN id SET DEFAULT nextval('edoc.digital_signatures_id_seq'::regclass);


--
-- Name: doc_books id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_books ALTER COLUMN id SET DEFAULT nextval('edoc.doc_books_id_seq'::regclass);


--
-- Name: doc_columns id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_columns ALTER COLUMN id SET DEFAULT nextval('edoc.doc_columns_id_seq'::regclass);


--
-- Name: doc_fields id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_fields ALTER COLUMN id SET DEFAULT nextval('edoc.doc_fields_id_seq'::regclass);


--
-- Name: doc_flow_step_links id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_step_links ALTER COLUMN id SET DEFAULT nextval('edoc.doc_flow_step_links_id_seq'::regclass);


--
-- Name: doc_flow_step_staff id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_step_staff ALTER COLUMN id SET DEFAULT nextval('edoc.doc_flow_step_staff_id_seq'::regclass);


--
-- Name: doc_flow_steps id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_steps ALTER COLUMN id SET DEFAULT nextval('edoc.doc_flow_steps_id_seq'::regclass);


--
-- Name: doc_flows id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flows ALTER COLUMN id SET DEFAULT nextval('edoc.doc_flows_id_seq'::regclass);


--
-- Name: doc_types id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_types ALTER COLUMN id SET DEFAULT nextval('edoc.doc_types_id_seq'::regclass);


--
-- Name: drafting_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs ALTER COLUMN id SET DEFAULT nextval('edoc.drafting_docs_id_seq'::regclass);


--
-- Name: email_templates id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.email_templates ALTER COLUMN id SET DEFAULT nextval('edoc.email_templates_id_seq'::regclass);


--
-- Name: handling_doc_links id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_doc_links ALTER COLUMN id SET DEFAULT nextval('edoc.handling_doc_links_id_seq'::regclass);


--
-- Name: handling_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs ALTER COLUMN id SET DEFAULT nextval('edoc.handling_docs_id_seq'::regclass);


--
-- Name: incoming_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.incoming_docs ALTER COLUMN id SET DEFAULT nextval('edoc.incoming_docs_id_seq'::regclass);


--
-- Name: inter_incoming_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.inter_incoming_docs ALTER COLUMN id SET DEFAULT nextval('edoc.inter_incoming_docs_id_seq'::regclass);


--
-- Name: leader_notes id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.leader_notes ALTER COLUMN id SET DEFAULT nextval('edoc.leader_notes_id_seq'::regclass);


--
-- Name: lgsp_config id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_config ALTER COLUMN id SET DEFAULT nextval('edoc.lgsp_config_id_seq'::regclass);


--
-- Name: lgsp_organizations id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_organizations ALTER COLUMN id SET DEFAULT nextval('edoc.lgsp_organizations_id_seq'::regclass);


--
-- Name: lgsp_tracking id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_tracking ALTER COLUMN id SET DEFAULT nextval('edoc.lgsp_tracking_id_seq'::regclass);


--
-- Name: meeting_types id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.meeting_types ALTER COLUMN id SET DEFAULT nextval('edoc.meeting_types_id_seq'::regclass);


--
-- Name: message_recipients id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.message_recipients ALTER COLUMN id SET DEFAULT nextval('edoc.message_recipients_id_seq'::regclass);


--
-- Name: messages id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.messages ALTER COLUMN id SET DEFAULT nextval('edoc.messages_id_seq'::regclass);


--
-- Name: notice_reads id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notice_reads ALTER COLUMN id SET DEFAULT nextval('edoc.notice_reads_id_seq'::regclass);


--
-- Name: notices id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notices ALTER COLUMN id SET DEFAULT nextval('edoc.notices_id_seq'::regclass);


--
-- Name: notification_logs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notification_logs ALTER COLUMN id SET DEFAULT nextval('edoc.notification_logs_id_seq'::regclass);


--
-- Name: notification_preferences id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notification_preferences ALTER COLUMN id SET DEFAULT nextval('edoc.notification_preferences_id_seq'::regclass);


--
-- Name: opinion_handling_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.opinion_handling_docs ALTER COLUMN id SET DEFAULT nextval('edoc.opinion_handling_docs_id_seq'::regclass);


--
-- Name: organizations id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.organizations ALTER COLUMN id SET DEFAULT nextval('edoc.organizations_id_seq'::regclass);


--
-- Name: outgoing_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs ALTER COLUMN id SET DEFAULT nextval('edoc.outgoing_docs_id_seq'::regclass);


--
-- Name: room_schedule_attachments id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_attachments ALTER COLUMN id SET DEFAULT nextval('edoc.room_schedule_attachments_id_seq'::regclass);


--
-- Name: room_schedule_staff id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_staff ALTER COLUMN id SET DEFAULT nextval('edoc.room_schedule_staff_id_seq'::regclass);


--
-- Name: room_schedule_votes id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_votes ALTER COLUMN id SET DEFAULT nextval('edoc.room_schedule_votes_id_seq'::regclass);


--
-- Name: room_schedules id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedules ALTER COLUMN id SET DEFAULT nextval('edoc.room_schedules_id_seq'::regclass);


--
-- Name: rooms id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.rooms ALTER COLUMN id SET DEFAULT nextval('edoc.rooms_id_seq'::regclass);


--
-- Name: send_doc_user_configs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.send_doc_user_configs ALTER COLUMN id SET DEFAULT nextval('edoc.send_doc_user_configs_id_seq'::regclass);


--
-- Name: signers id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.signers ALTER COLUMN id SET DEFAULT nextval('edoc.signers_id_seq'::regclass);


--
-- Name: sms_templates id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.sms_templates ALTER COLUMN id SET DEFAULT nextval('edoc.sms_templates_id_seq'::regclass);


--
-- Name: staff_handling_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.staff_handling_docs ALTER COLUMN id SET DEFAULT nextval('edoc.staff_handling_docs_id_seq'::regclass);


--
-- Name: staff_notes id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.staff_notes ALTER COLUMN id SET DEFAULT nextval('edoc.staff_notes_id_seq'::regclass);


--
-- Name: user_drafting_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_drafting_docs ALTER COLUMN id SET DEFAULT nextval('edoc.user_drafting_docs_id_seq'::regclass);


--
-- Name: user_incoming_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_incoming_docs ALTER COLUMN id SET DEFAULT nextval('edoc.user_incoming_docs_id_seq'::regclass);


--
-- Name: user_outgoing_docs id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_outgoing_docs ALTER COLUMN id SET DEFAULT nextval('edoc.user_outgoing_docs_id_seq'::regclass);


--
-- Name: work_group_members id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.work_group_members ALTER COLUMN id SET DEFAULT nextval('edoc.work_group_members_id_seq'::regclass);


--
-- Name: work_groups id; Type: DEFAULT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.work_groups ALTER COLUMN id SET DEFAULT nextval('edoc.work_groups_id_seq'::regclass);


--
-- Name: borrow_request_records id; Type: DEFAULT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.borrow_request_records ALTER COLUMN id SET DEFAULT nextval('esto.borrow_request_records_id_seq'::regclass);


--
-- Name: borrow_requests id; Type: DEFAULT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.borrow_requests ALTER COLUMN id SET DEFAULT nextval('esto.borrow_requests_id_seq'::regclass);


--
-- Name: document_archives id; Type: DEFAULT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.document_archives ALTER COLUMN id SET DEFAULT nextval('esto.document_archives_id_seq'::regclass);


--
-- Name: fonds id; Type: DEFAULT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.fonds ALTER COLUMN id SET DEFAULT nextval('esto.fonds_id_seq'::regclass);


--
-- Name: records id; Type: DEFAULT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.records ALTER COLUMN id SET DEFAULT nextval('esto.records_id_seq'::regclass);


--
-- Name: warehouses id; Type: DEFAULT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.warehouses ALTER COLUMN id SET DEFAULT nextval('esto.warehouses_id_seq'::regclass);


--
-- Name: document_categories id; Type: DEFAULT; Schema: iso; Owner: -
--

ALTER TABLE ONLY iso.document_categories ALTER COLUMN id SET DEFAULT nextval('iso.document_categories_id_seq'::regclass);


--
-- Name: documents id; Type: DEFAULT; Schema: iso; Owner: -
--

ALTER TABLE ONLY iso.documents ALTER COLUMN id SET DEFAULT nextval('iso.documents_id_seq'::regclass);


--
-- Name: action_of_role id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_of_role ALTER COLUMN id SET DEFAULT nextval('public.action_of_role_id_seq'::regclass);


--
-- Name: calendar_events id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events ALTER COLUMN id SET DEFAULT nextval('public.calendar_events_id_seq'::regclass);


--
-- Name: communes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communes ALTER COLUMN id SET DEFAULT nextval('public.communes_id_seq'::regclass);


--
-- Name: configurations id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configurations ALTER COLUMN id SET DEFAULT nextval('public.configurations_id_seq'::regclass);


--
-- Name: departments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments ALTER COLUMN id SET DEFAULT nextval('public.departments_id_seq'::regclass);


--
-- Name: districts id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts ALTER COLUMN id SET DEFAULT nextval('public.districts_id_seq'::regclass);


--
-- Name: login_history id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_history ALTER COLUMN id SET DEFAULT nextval('public.login_history_id_seq'::regclass);


--
-- Name: positions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions ALTER COLUMN id SET DEFAULT nextval('public.positions_id_seq'::regclass);


--
-- Name: provinces id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provinces ALTER COLUMN id SET DEFAULT nextval('public.provinces_id_seq'::regclass);


--
-- Name: refresh_tokens id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens ALTER COLUMN id SET DEFAULT nextval('public.refresh_tokens_id_seq'::regclass);


--
-- Name: rights id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rights ALTER COLUMN id SET DEFAULT nextval('public.rights_id_seq'::regclass);


--
-- Name: role_of_staff id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_of_staff ALTER COLUMN id SET DEFAULT nextval('public.role_of_staff_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: staff id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff ALTER COLUMN id SET DEFAULT nextval('public.staff_id_seq'::regclass);


--
-- Name: work_calendar id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_calendar ALTER COLUMN id SET DEFAULT nextval('public.work_calendar_id_seq'::regclass);


--
-- Data for Name: contract_attachments; Type: TABLE DATA; Schema: cont; Owner: -
--

COPY cont.contract_attachments (id, contract_id, file_name, file_path, file_size, mime_type, created_user_id, created_date) FROM stdin;
\.


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
-- Data for Name: attachment_drafting_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.attachment_drafting_docs (id, drafting_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at, description, is_ca, ca_date, signed_file_path) FROM stdin;
\.


--
-- Data for Name: attachment_handling_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.attachment_handling_docs (id, handling_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at) FROM stdin;
\.


--
-- Data for Name: attachment_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.attachment_incoming_docs (id, incoming_doc_id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at, description, is_ca, ca_date, signed_file_path) FROM stdin;
1	4	quy_uoc_chung.md	incoming/4/08645e01-80f0-413c-8038-bfab7cf12f1d.md	13550	application/octet-stream	0	1	2026-04-17 17:08:50.929598+00	\N	t	2026-04-17 17:08:58.673383+00	incoming/4/08645e01-80f0-413c-8038-bfab7cf12f1d.md
\.


--
-- Data for Name: attachment_inter_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.attachment_inter_incoming_docs (id, inter_incoming_doc_id, file_name, file_path, file_size, content_type, description, sort_order, created_by, created_at) FROM stdin;
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
-- Data for Name: doc_flow_steps; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.doc_flow_steps (id, flow_id, step_name, step_order, step_type, allow_sign, deadline_days, position_x, position_y, created_at) FROM stdin;
\.


--
-- Data for Name: doc_flows; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.doc_flows (id, unit_id, name, version, doc_field_id, is_active, created_by, created_at, updated_at, department_id) FROM stdin;
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
-- Data for Name: inter_incoming_docs; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.inter_incoming_docs (id, unit_id, received_date, notation, document_code, abstract, publish_unit, publish_date, signer, sign_date, expired_date, doc_type_id, status, source_system, external_doc_id, created_by, created_at, updated_at, organ_id, from_organ_id, number_paper, number_copies, secret_id, urgent_id, recipients, doc_field_id, department_id) FROM stdin;
1	1	2026-04-16 12:09:34.966774	LT-001/VPCP	LT001	V/v triển khai Đề án 06 về CSDL quốc gia dân cư	Văn phòng Chính phủ	2026-04-15	Trần Văn Sơn	\N	\N	1	pending	LGSP-TW	VPCP-2026-001	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	\N	\N	1	1	1	1	\N	\N	1
2	1	2026-04-14 12:09:34.966774	LT-002/BTTTT	LT002	V/v triển khai nền tảng LGSP tỉnh	Bộ TT&TT	2026-04-13	Nguyễn Mạnh Hùng	\N	\N	1	received	LGSP-TW	BTTTT-2026-015	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	\N	\N	1	1	1	1	\N	\N	1
3	1	2026-04-17 12:09:34.966774	LT-003/UBND-YB	LT003	V/v phối hợp xử lý văn bản liên thông Tây Bắc	UBND tỉnh Yên Bái	2026-04-16	Trần Huy Tuấn	\N	\N	1	pending	LGSP-YB	YB-2026-042	1	2026-04-17 12:09:34.966774	2026-04-17 12:09:34.966774	\N	\N	1	1	1	1	\N	\N	1
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
-- Data for Name: notice_reads; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.notice_reads (id, notice_id, staff_id, read_at) FROM stdin;
1	1	1	2026-04-17 15:58:15.861662
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
-- Data for Name: room_schedule_questions; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.room_schedule_questions (id, room_schedule_id, name, start_time, stop_time, duration, status, question_type, order_no) FROM stdin;
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
-- Data for Name: room_schedules; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.room_schedules (id, unit_id, room_id, meeting_type_id, name, content, component, start_date, end_date, start_time, end_time, master_id, secretary_id, approved, approved_date, approved_staff_id, rejection_reason, meeting_status, online_link, is_cancel, created_user_id, created_date, modified_user_id, modified_date, department_id) FROM stdin;
1	1	1	1	Họp giao ban tuần 15/2026	Giao ban tình hình tuần 15, triển khai nhiệm vụ tuần 16.	\N	2026-04-14	2026-04-14	08:00	09:30	1	9	1	\N	\N	\N	2	\N	0	1	2026-04-17 12:09:34.966774+00	\N	\N	1
2	1	1	2	Họp triển khai Chuyển đổi số tỉnh	Rà soát tiến độ CĐS, phân công nhiệm vụ CĐS quý II/2026.	\N	2026-04-15	2026-04-15	09:00	11:00	1	5	1	\N	\N	\N	0	\N	0	1	2026-04-17 12:09:34.966774+00	\N	\N	1
3	1	3	3	Họp Ban lãnh đạo — kế hoạch quý II	Thảo luận kế hoạch công tác quý II/2026.	\N	2026-04-16	2026-04-16	14:00	16:00	1	9	1	\N	\N	\N	0	\N	0	1	2026-04-17 12:09:34.966774+00	\N	\N	1
4	1	2	2	Demo hệ thống e-Office cho BLĐ	Trình diễn các chức năng mới: HSCV, Họp, Kho lưu trữ, LGSP, Ký số.	\N	2026-04-18	2026-04-18	14:00	16:00	4	8	0	\N	\N	\N	0	\N	0	4	2026-04-17 12:09:34.966774+00	\N	\N	4
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
-- Data for Name: work_groups; Type: TABLE DATA; Schema: edoc; Owner: -
--

COPY edoc.work_groups (id, unit_id, name, function, sort_order, is_deleted, created_by, created_at) FROM stdin;
1	1	Ban Chỉ đạo Chuyển đổi số	\N	1	f	1	2026-04-17 12:09:34.966774+00
2	1	Tổ Công tác cải cách hành chính	\N	2	f	1	2026-04-17 12:09:34.966774+00
\.


--
-- Data for Name: borrow_request_records; Type: TABLE DATA; Schema: esto; Owner: -
--

COPY esto.borrow_request_records (id, borrow_request_id, record_id, return_date, actual_return_date) FROM stdin;
1	1	3	2026-04-25	\N
2	2	5	2026-04-20	\N
\.


--
-- Data for Name: borrow_requests; Type: TABLE DATA; Schema: esto; Owner: -
--

COPY esto.borrow_requests (id, name, unit_id, emergency, notice, borrow_date, status, created_user_id, created_date, modified_user_id, modified_date, department_id) FROM stdin;
1	Mượn hồ sơ tuyển dụng 2025 để đối chiếu	1	0	Cần đối chiếu số liệu cho kế hoạch tuyển dụng 2026	2026-04-10	1	6	2026-04-17 12:09:34.966774+00	\N	\N	6
2	Mượn hồ sơ ngân sách 2025 để lập dự toán	1	1	Cần gấp để lập dự toán ngân sách quý II/2026	2026-04-12	0	7	2026-04-17 12:09:34.966774+00	\N	\N	7
\.


--
-- Data for Name: document_archives; Type: TABLE DATA; Schema: esto; Owner: -
--

COPY esto.document_archives (id, doc_type, doc_id, fond_id, warehouse_id, record_id, file_catalog, file_notation, doc_ordinal, language, autograph, keyword, format, confidence_level, is_original, archive_date, archived_by, created_at) FROM stdin;
3	incoming	8	\N	\N	\N	\N	\N	\N	Tiếng Việt	\N	\N	Điện tử	\N	t	2026-04-17 14:53:19.576311+00	1	2026-04-17 14:53:19.576311+00
4	incoming	6	2	2	\N	t	t	\N	Tiếng Việt	t	tt	Điện tử	t	t	2026-04-17 15:05:50.150041+00	1	2026-04-17 15:05:50.150041+00
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
-- Data for Name: warehouses; Type: TABLE DATA; Schema: esto; Owner: -
--

COPY esto.warehouses (id, unit_id, type_id, code, name, phone_number, address, status, description, parent_id, is_unit, warehouse_level, limit_child, "position", is_deleted, created_user_id, created_date, modified_user_id, modified_date, department_id) FROM stdin;
1	1	1	KHO-01	Kho lưu trữ UBND tỉnh	02143840900	Tầng hầm, Trụ sở UBND tỉnh Lào Cai	t	\N	0	t	0	0	\N	f	1	2026-04-17 12:09:34.966774+00	\N	\N	1
2	1	1	KHO-02	Kho lưu trữ Sở TT&TT	02143840901	Phòng 101, Trụ sở Sở TT&TT tỉnh Lào Cai	t	\N	0	t	0	0	\N	f	4	2026-04-17 12:09:34.966774+00	\N	\N	4
3	1	2	KE-A1	Kệ A1 — Tủ văn bản hành chính	\N	\N	t	\N	1	f	1	0	\N	f	1	2026-04-17 12:09:34.966774+00	\N	\N	1
4	1	2	KE-A2	Kệ A2 — Tủ văn bản tài chính	\N	\N	t	\N	1	f	1	0	\N	f	1	2026-04-17 12:09:34.966774+00	\N	\N	1
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
-- Name: contract_attachments contract_attachments_pkey; Type: CONSTRAINT; Schema: cont; Owner: -
--

ALTER TABLE ONLY cont.contract_attachments
    ADD CONSTRAINT contract_attachments_pkey PRIMARY KEY (id);


--
-- Name: contract_types contract_types_pkey; Type: CONSTRAINT; Schema: cont; Owner: -
--

ALTER TABLE ONLY cont.contract_types
    ADD CONSTRAINT contract_types_pkey PRIMARY KEY (id);


--
-- Name: contracts contracts_pkey; Type: CONSTRAINT; Schema: cont; Owner: -
--

ALTER TABLE ONLY cont.contracts
    ADD CONSTRAINT contracts_pkey PRIMARY KEY (id);


--
-- Name: attachment_drafting_docs attachment_drafting_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_drafting_docs
    ADD CONSTRAINT attachment_drafting_docs_pkey PRIMARY KEY (id);


--
-- Name: attachment_handling_docs attachment_handling_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_handling_docs
    ADD CONSTRAINT attachment_handling_docs_pkey PRIMARY KEY (id);


--
-- Name: attachment_incoming_docs attachment_incoming_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_incoming_docs
    ADD CONSTRAINT attachment_incoming_docs_pkey PRIMARY KEY (id);


--
-- Name: attachment_inter_incoming_docs attachment_inter_incoming_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_inter_incoming_docs
    ADD CONSTRAINT attachment_inter_incoming_docs_pkey PRIMARY KEY (id);


--
-- Name: attachment_outgoing_docs attachment_outgoing_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_outgoing_docs
    ADD CONSTRAINT attachment_outgoing_docs_pkey PRIMARY KEY (id);


--
-- Name: delegations delegations_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.delegations
    ADD CONSTRAINT delegations_pkey PRIMARY KEY (id);


--
-- Name: device_tokens device_tokens_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.device_tokens
    ADD CONSTRAINT device_tokens_pkey PRIMARY KEY (id);


--
-- Name: digital_signatures digital_signatures_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.digital_signatures
    ADD CONSTRAINT digital_signatures_pkey PRIMARY KEY (id);


--
-- Name: doc_books doc_books_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_books
    ADD CONSTRAINT doc_books_pkey PRIMARY KEY (id);


--
-- Name: doc_columns doc_columns_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_columns
    ADD CONSTRAINT doc_columns_pkey PRIMARY KEY (id);


--
-- Name: doc_columns doc_columns_type_id_column_name_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_columns
    ADD CONSTRAINT doc_columns_type_id_column_name_key UNIQUE (type_id, column_name);


--
-- Name: doc_fields doc_fields_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_fields
    ADD CONSTRAINT doc_fields_pkey PRIMARY KEY (id);


--
-- Name: doc_flow_step_links doc_flow_step_links_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_step_links
    ADD CONSTRAINT doc_flow_step_links_pkey PRIMARY KEY (id);


--
-- Name: doc_flow_step_staff doc_flow_step_staff_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_step_staff
    ADD CONSTRAINT doc_flow_step_staff_pkey PRIMARY KEY (id);


--
-- Name: doc_flow_steps doc_flow_steps_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_steps
    ADD CONSTRAINT doc_flow_steps_pkey PRIMARY KEY (id);


--
-- Name: doc_flows doc_flows_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flows
    ADD CONSTRAINT doc_flows_pkey PRIMARY KEY (id);


--
-- Name: doc_types doc_types_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_types
    ADD CONSTRAINT doc_types_pkey PRIMARY KEY (id);


--
-- Name: drafting_docs drafting_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_pkey PRIMARY KEY (id);


--
-- Name: email_templates email_templates_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.email_templates
    ADD CONSTRAINT email_templates_pkey PRIMARY KEY (id);


--
-- Name: handling_doc_links handling_doc_links_handling_doc_id_doc_type_doc_id_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_doc_links
    ADD CONSTRAINT handling_doc_links_handling_doc_id_doc_type_doc_id_key UNIQUE (handling_doc_id, doc_type, doc_id);


--
-- Name: handling_doc_links handling_doc_links_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_doc_links
    ADD CONSTRAINT handling_doc_links_pkey PRIMARY KEY (id);


--
-- Name: handling_docs handling_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_pkey PRIMARY KEY (id);


--
-- Name: incoming_docs incoming_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.incoming_docs
    ADD CONSTRAINT incoming_docs_pkey PRIMARY KEY (id);


--
-- Name: inter_incoming_docs inter_incoming_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.inter_incoming_docs
    ADD CONSTRAINT inter_incoming_docs_pkey PRIMARY KEY (id);


--
-- Name: leader_notes leader_notes_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.leader_notes
    ADD CONSTRAINT leader_notes_pkey PRIMARY KEY (id);


--
-- Name: lgsp_config lgsp_config_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_config
    ADD CONSTRAINT lgsp_config_pkey PRIMARY KEY (id);


--
-- Name: lgsp_organizations lgsp_organizations_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_organizations
    ADD CONSTRAINT lgsp_organizations_pkey PRIMARY KEY (id);


--
-- Name: lgsp_tracking lgsp_tracking_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_tracking
    ADD CONSTRAINT lgsp_tracking_pkey PRIMARY KEY (id);


--
-- Name: meeting_types meeting_types_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.meeting_types
    ADD CONSTRAINT meeting_types_pkey PRIMARY KEY (id);


--
-- Name: message_recipients message_recipients_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.message_recipients
    ADD CONSTRAINT message_recipients_pkey PRIMARY KEY (id);


--
-- Name: messages messages_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.messages
    ADD CONSTRAINT messages_pkey PRIMARY KEY (id);


--
-- Name: notice_reads notice_reads_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notice_reads
    ADD CONSTRAINT notice_reads_pkey PRIMARY KEY (id);


--
-- Name: notices notices_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notices
    ADD CONSTRAINT notices_pkey PRIMARY KEY (id);


--
-- Name: notification_logs notification_logs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notification_logs
    ADD CONSTRAINT notification_logs_pkey PRIMARY KEY (id);


--
-- Name: notification_preferences notification_preferences_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notification_preferences
    ADD CONSTRAINT notification_preferences_pkey PRIMARY KEY (id);


--
-- Name: opinion_handling_docs opinion_handling_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.opinion_handling_docs
    ADD CONSTRAINT opinion_handling_docs_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.organizations
    ADD CONSTRAINT organizations_pkey PRIMARY KEY (id);


--
-- Name: organizations organizations_unit_id_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.organizations
    ADD CONSTRAINT organizations_unit_id_key UNIQUE (unit_id);


--
-- Name: outgoing_docs outgoing_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_pkey PRIMARY KEY (id);


--
-- Name: room_schedule_answers room_schedule_answers_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_answers
    ADD CONSTRAINT room_schedule_answers_pkey PRIMARY KEY (id);


--
-- Name: room_schedule_attachments room_schedule_attachments_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_attachments
    ADD CONSTRAINT room_schedule_attachments_pkey PRIMARY KEY (id);


--
-- Name: room_schedule_questions room_schedule_questions_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_questions
    ADD CONSTRAINT room_schedule_questions_pkey PRIMARY KEY (id);


--
-- Name: room_schedule_staff room_schedule_staff_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_staff
    ADD CONSTRAINT room_schedule_staff_pkey PRIMARY KEY (id);


--
-- Name: room_schedule_staff room_schedule_staff_room_schedule_id_staff_id_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_staff
    ADD CONSTRAINT room_schedule_staff_room_schedule_id_staff_id_key UNIQUE (room_schedule_id, staff_id);


--
-- Name: room_schedule_votes room_schedule_votes_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_votes
    ADD CONSTRAINT room_schedule_votes_pkey PRIMARY KEY (id);


--
-- Name: room_schedule_votes room_schedule_votes_question_id_staff_id_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_votes
    ADD CONSTRAINT room_schedule_votes_question_id_staff_id_key UNIQUE (question_id, staff_id);


--
-- Name: room_schedules room_schedules_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedules
    ADD CONSTRAINT room_schedules_pkey PRIMARY KEY (id);


--
-- Name: rooms rooms_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.rooms
    ADD CONSTRAINT rooms_pkey PRIMARY KEY (id);


--
-- Name: send_doc_user_configs send_doc_user_configs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.send_doc_user_configs
    ADD CONSTRAINT send_doc_user_configs_pkey PRIMARY KEY (id);


--
-- Name: send_doc_user_configs send_doc_user_configs_user_id_target_user_id_config_type_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.send_doc_user_configs
    ADD CONSTRAINT send_doc_user_configs_user_id_target_user_id_config_type_key UNIQUE (user_id, target_user_id, config_type);


--
-- Name: signers signers_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.signers
    ADD CONSTRAINT signers_pkey PRIMARY KEY (id);


--
-- Name: signers signers_unit_id_staff_id_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.signers
    ADD CONSTRAINT signers_unit_id_staff_id_key UNIQUE (unit_id, staff_id);


--
-- Name: sms_templates sms_templates_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.sms_templates
    ADD CONSTRAINT sms_templates_pkey PRIMARY KEY (id);


--
-- Name: staff_handling_docs staff_handling_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.staff_handling_docs
    ADD CONSTRAINT staff_handling_docs_pkey PRIMARY KEY (id);


--
-- Name: staff_notes staff_notes_doc_type_doc_id_staff_id_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.staff_notes
    ADD CONSTRAINT staff_notes_doc_type_doc_id_staff_id_key UNIQUE (doc_type, doc_id, staff_id);


--
-- Name: staff_notes staff_notes_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.staff_notes
    ADD CONSTRAINT staff_notes_pkey PRIMARY KEY (id);


--
-- Name: device_tokens uq_device_token; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.device_tokens
    ADD CONSTRAINT uq_device_token UNIQUE (device_token);


--
-- Name: doc_flow_step_links uq_doc_flow_step_links; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_step_links
    ADD CONSTRAINT uq_doc_flow_step_links UNIQUE (from_step_id, to_step_id);


--
-- Name: doc_flow_step_staff uq_doc_flow_step_staff; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_step_staff
    ADD CONSTRAINT uq_doc_flow_step_staff UNIQUE (step_id, staff_id);


--
-- Name: doc_flows uq_doc_flows_unit_name_version; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flows
    ADD CONSTRAINT uq_doc_flows_unit_name_version UNIQUE (unit_id, name, version);


--
-- Name: lgsp_organizations uq_lgsp_org_code; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_organizations
    ADD CONSTRAINT uq_lgsp_org_code UNIQUE (org_code);


--
-- Name: message_recipients uq_msg_recipients_message_staff; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.message_recipients
    ADD CONSTRAINT uq_msg_recipients_message_staff UNIQUE (message_id, staff_id);


--
-- Name: notice_reads uq_notice_reads_notice_staff; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notice_reads
    ADD CONSTRAINT uq_notice_reads_notice_staff UNIQUE (notice_id, staff_id);


--
-- Name: notification_preferences uq_notif_pref_staff_channel; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notification_preferences
    ADD CONSTRAINT uq_notif_pref_staff_channel UNIQUE (staff_id, channel);


--
-- Name: user_drafting_docs user_drafting_docs_drafting_doc_id_staff_id_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_drafting_docs
    ADD CONSTRAINT user_drafting_docs_drafting_doc_id_staff_id_key UNIQUE (drafting_doc_id, staff_id);


--
-- Name: user_drafting_docs user_drafting_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_drafting_docs
    ADD CONSTRAINT user_drafting_docs_pkey PRIMARY KEY (id);


--
-- Name: user_incoming_docs user_incoming_docs_incoming_doc_id_staff_id_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_incoming_docs
    ADD CONSTRAINT user_incoming_docs_incoming_doc_id_staff_id_key UNIQUE (incoming_doc_id, staff_id);


--
-- Name: user_incoming_docs user_incoming_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_incoming_docs
    ADD CONSTRAINT user_incoming_docs_pkey PRIMARY KEY (id);


--
-- Name: user_outgoing_docs user_outgoing_docs_outgoing_doc_id_staff_id_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_outgoing_docs
    ADD CONSTRAINT user_outgoing_docs_outgoing_doc_id_staff_id_key UNIQUE (outgoing_doc_id, staff_id);


--
-- Name: user_outgoing_docs user_outgoing_docs_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_outgoing_docs
    ADD CONSTRAINT user_outgoing_docs_pkey PRIMARY KEY (id);


--
-- Name: work_group_members work_group_members_group_id_staff_id_key; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.work_group_members
    ADD CONSTRAINT work_group_members_group_id_staff_id_key UNIQUE (group_id, staff_id);


--
-- Name: work_group_members work_group_members_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.work_group_members
    ADD CONSTRAINT work_group_members_pkey PRIMARY KEY (id);


--
-- Name: work_groups work_groups_pkey; Type: CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.work_groups
    ADD CONSTRAINT work_groups_pkey PRIMARY KEY (id);


--
-- Name: borrow_request_records borrow_request_records_borrow_request_id_record_id_key; Type: CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.borrow_request_records
    ADD CONSTRAINT borrow_request_records_borrow_request_id_record_id_key UNIQUE (borrow_request_id, record_id);


--
-- Name: borrow_request_records borrow_request_records_pkey; Type: CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.borrow_request_records
    ADD CONSTRAINT borrow_request_records_pkey PRIMARY KEY (id);


--
-- Name: borrow_requests borrow_requests_pkey; Type: CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.borrow_requests
    ADD CONSTRAINT borrow_requests_pkey PRIMARY KEY (id);


--
-- Name: document_archives document_archives_doc_type_doc_id_key; Type: CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.document_archives
    ADD CONSTRAINT document_archives_doc_type_doc_id_key UNIQUE (doc_type, doc_id);


--
-- Name: document_archives document_archives_pkey; Type: CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.document_archives
    ADD CONSTRAINT document_archives_pkey PRIMARY KEY (id);


--
-- Name: fonds fonds_pkey; Type: CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.fonds
    ADD CONSTRAINT fonds_pkey PRIMARY KEY (id);


--
-- Name: records records_pkey; Type: CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.records
    ADD CONSTRAINT records_pkey PRIMARY KEY (id);


--
-- Name: warehouses warehouses_pkey; Type: CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.warehouses
    ADD CONSTRAINT warehouses_pkey PRIMARY KEY (id);


--
-- Name: document_categories document_categories_pkey; Type: CONSTRAINT; Schema: iso; Owner: -
--

ALTER TABLE ONLY iso.document_categories
    ADD CONSTRAINT document_categories_pkey PRIMARY KEY (id);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: iso; Owner: -
--

ALTER TABLE ONLY iso.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: action_of_role action_of_role_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_of_role
    ADD CONSTRAINT action_of_role_pkey PRIMARY KEY (id);


--
-- Name: action_of_role action_of_role_role_id_right_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_of_role
    ADD CONSTRAINT action_of_role_role_id_right_id_key UNIQUE (role_id, right_id);


--
-- Name: calendar_events calendar_events_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_pkey PRIMARY KEY (id);


--
-- Name: communes communes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communes
    ADD CONSTRAINT communes_pkey PRIMARY KEY (id);


--
-- Name: configurations configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_pkey PRIMARY KEY (id);


--
-- Name: configurations configurations_unit_id_key_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_unit_id_key_key UNIQUE (unit_id, key);


--
-- Name: departments departments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_pkey PRIMARY KEY (id);


--
-- Name: districts districts_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_pkey PRIMARY KEY (id);


--
-- Name: login_history login_history_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_history
    ADD CONSTRAINT login_history_pkey PRIMARY KEY (id);


--
-- Name: positions positions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.positions
    ADD CONSTRAINT positions_pkey PRIMARY KEY (id);


--
-- Name: provinces provinces_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provinces
    ADD CONSTRAINT provinces_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: rights rights_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rights
    ADD CONSTRAINT rights_pkey PRIMARY KEY (id);


--
-- Name: role_of_staff role_of_staff_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_of_staff
    ADD CONSTRAINT role_of_staff_pkey PRIMARY KEY (id);


--
-- Name: role_of_staff role_of_staff_staff_id_role_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_of_staff
    ADD CONSTRAINT role_of_staff_staff_id_role_id_key UNIQUE (staff_id, role_id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: staff staff_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_pkey PRIMARY KEY (id);


--
-- Name: staff staff_username_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_username_key UNIQUE (username);


--
-- Name: work_calendar work_calendar_date_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_calendar
    ADD CONSTRAINT work_calendar_date_key UNIQUE (date);


--
-- Name: work_calendar work_calendar_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.work_calendar
    ADD CONSTRAINT work_calendar_pkey PRIMARY KEY (id);


--
-- Name: idx_contracts_contract_type_id; Type: INDEX; Schema: cont; Owner: -
--

CREATE INDEX idx_contracts_contract_type_id ON cont.contracts USING btree (contract_type_id);


--
-- Name: idx_contracts_unit_id; Type: INDEX; Schema: cont; Owner: -
--

CREATE INDEX idx_contracts_unit_id ON cont.contracts USING btree (unit_id);


--
-- Name: uq_contract_types_code; Type: INDEX; Schema: cont; Owner: -
--

CREATE UNIQUE INDEX uq_contract_types_code ON cont.contract_types USING btree (unit_id, code) WHERE (code IS NOT NULL);


--
-- Name: idx_attach_inter_incoming_doc; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_attach_inter_incoming_doc ON edoc.attachment_inter_incoming_docs USING btree (inter_incoming_doc_id);


--
-- Name: idx_delegations_from; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_delegations_from ON edoc.delegations USING btree (from_staff_id) WHERE (is_revoked = false);


--
-- Name: idx_delegations_to; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_delegations_to ON edoc.delegations USING btree (to_staff_id) WHERE (is_revoked = false);


--
-- Name: idx_device_tokens_staff; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_device_tokens_staff ON edoc.device_tokens USING btree (staff_id);


--
-- Name: idx_digsig_doc; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_digsig_doc ON edoc.digital_signatures USING btree (doc_id, doc_type);


--
-- Name: idx_digsig_staff; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_digsig_staff ON edoc.digital_signatures USING btree (staff_id);


--
-- Name: idx_digsig_status; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_digsig_status ON edoc.digital_signatures USING btree (sign_status);


--
-- Name: idx_doc_columns_type; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_doc_columns_type ON edoc.doc_columns USING btree (type_id, sort_order);


--
-- Name: idx_doc_flow_step_staff_step; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_doc_flow_step_staff_step ON edoc.doc_flow_step_staff USING btree (step_id);


--
-- Name: idx_doc_flow_steps_flow; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_doc_flow_steps_flow ON edoc.doc_flow_steps USING btree (flow_id, step_order);


--
-- Name: idx_doc_flows_department; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_doc_flows_department ON edoc.doc_flows USING btree (department_id);


--
-- Name: idx_doc_flows_unit; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_doc_flows_unit ON edoc.doc_flows USING btree (unit_id, is_active);


--
-- Name: idx_drafting_docs_department; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_drafting_docs_department ON edoc.drafting_docs USING btree (department_id);


--
-- Name: idx_drafting_docs_search; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_drafting_docs_search ON edoc.drafting_docs USING gin (abstract public.gin_trgm_ops);


--
-- Name: idx_drafting_docs_unit; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_drafting_docs_unit ON edoc.drafting_docs USING btree (unit_id, received_date DESC);


--
-- Name: idx_handling_docs_curator; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_handling_docs_curator ON edoc.handling_docs USING btree (curator);


--
-- Name: idx_handling_docs_search; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_handling_docs_search ON edoc.handling_docs USING gin (name public.gin_trgm_ops);


--
-- Name: idx_handling_docs_unit; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_handling_docs_unit ON edoc.handling_docs USING btree (unit_id, status, start_date DESC);


--
-- Name: idx_incoming_docs_department; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_incoming_docs_department ON edoc.incoming_docs USING btree (department_id);


--
-- Name: idx_incoming_docs_notation; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_incoming_docs_notation ON edoc.incoming_docs USING btree (notation);


--
-- Name: idx_incoming_docs_number; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_incoming_docs_number ON edoc.incoming_docs USING btree (unit_id, number);


--
-- Name: idx_incoming_docs_search; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_incoming_docs_search ON edoc.incoming_docs USING gin (abstract public.gin_trgm_ops);


--
-- Name: idx_incoming_docs_unit; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_incoming_docs_unit ON edoc.incoming_docs USING btree (unit_id, received_date DESC);


--
-- Name: idx_inter_incoming_department; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_inter_incoming_department ON edoc.inter_incoming_docs USING btree (department_id);


--
-- Name: idx_inter_incoming_external; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_inter_incoming_external ON edoc.inter_incoming_docs USING btree (external_doc_id) WHERE (external_doc_id IS NOT NULL);


--
-- Name: idx_inter_incoming_organ; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_inter_incoming_organ ON edoc.inter_incoming_docs USING btree (organ_id) WHERE (organ_id IS NOT NULL);


--
-- Name: idx_inter_incoming_received_date; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_inter_incoming_received_date ON edoc.inter_incoming_docs USING btree (received_date DESC);


--
-- Name: idx_inter_incoming_status; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_inter_incoming_status ON edoc.inter_incoming_docs USING btree (status);


--
-- Name: idx_inter_incoming_unit_id; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_inter_incoming_unit_id ON edoc.inter_incoming_docs USING btree (unit_id);


--
-- Name: idx_leader_notes_drafting; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_leader_notes_drafting ON edoc.leader_notes USING btree (drafting_doc_id) WHERE (drafting_doc_id IS NOT NULL);


--
-- Name: idx_leader_notes_outgoing; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_leader_notes_outgoing ON edoc.leader_notes USING btree (outgoing_doc_id) WHERE (outgoing_doc_id IS NOT NULL);


--
-- Name: idx_lgsp_tracking_direction; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_lgsp_tracking_direction ON edoc.lgsp_tracking USING btree (direction);


--
-- Name: idx_lgsp_tracking_outgoing; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_lgsp_tracking_outgoing ON edoc.lgsp_tracking USING btree (outgoing_doc_id);


--
-- Name: idx_lgsp_tracking_status; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_lgsp_tracking_status ON edoc.lgsp_tracking USING btree (status);


--
-- Name: idx_messages_from_staff; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_messages_from_staff ON edoc.messages USING btree (from_staff_id);


--
-- Name: idx_messages_parent_id; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_messages_parent_id ON edoc.messages USING btree (parent_id);


--
-- Name: idx_msg_recipients_message_id; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_msg_recipients_message_id ON edoc.message_recipients USING btree (message_id);


--
-- Name: idx_msg_recipients_staff_id; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_msg_recipients_staff_id ON edoc.message_recipients USING btree (staff_id);


--
-- Name: idx_notices_created_at; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_notices_created_at ON edoc.notices USING btree (created_at DESC);


--
-- Name: idx_notices_department; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_notices_department ON edoc.notices USING btree (department_id);


--
-- Name: idx_notices_unit_id; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_notices_unit_id ON edoc.notices USING btree (unit_id);


--
-- Name: idx_notif_log_channel; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_notif_log_channel ON edoc.notification_logs USING btree (channel);


--
-- Name: idx_notif_log_created; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_notif_log_created ON edoc.notification_logs USING btree (created_at DESC);


--
-- Name: idx_notif_log_staff; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_notif_log_staff ON edoc.notification_logs USING btree (staff_id);


--
-- Name: idx_notif_log_status; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_notif_log_status ON edoc.notification_logs USING btree (send_status);


--
-- Name: idx_outgoing_docs_department; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_outgoing_docs_department ON edoc.outgoing_docs USING btree (department_id);


--
-- Name: idx_outgoing_docs_search; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_outgoing_docs_search ON edoc.outgoing_docs USING gin (abstract public.gin_trgm_ops);


--
-- Name: idx_outgoing_docs_unit; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_outgoing_docs_unit ON edoc.outgoing_docs USING btree (unit_id, received_date DESC);


--
-- Name: idx_questions_room_schedule_id; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_questions_room_schedule_id ON edoc.room_schedule_questions USING btree (room_schedule_id);


--
-- Name: idx_room_schedules_department; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_room_schedules_department ON edoc.room_schedules USING btree (department_id);


--
-- Name: idx_room_schedules_room_id; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_room_schedules_room_id ON edoc.room_schedules USING btree (room_id);


--
-- Name: idx_room_schedules_start_date; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_room_schedules_start_date ON edoc.room_schedules USING btree (start_date);


--
-- Name: idx_room_schedules_unit_id; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_room_schedules_unit_id ON edoc.room_schedules USING btree (unit_id);


--
-- Name: idx_send_config_user; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_send_config_user ON edoc.send_doc_user_configs USING btree (user_id, config_type);


--
-- Name: idx_staff_handling_docs_staff; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_staff_handling_docs_staff ON edoc.staff_handling_docs USING btree (staff_id, handling_doc_id);


--
-- Name: idx_user_drafting_docs_staff; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_user_drafting_docs_staff ON edoc.user_drafting_docs USING btree (staff_id, is_read);


--
-- Name: idx_user_incoming_docs_staff; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_user_incoming_docs_staff ON edoc.user_incoming_docs USING btree (staff_id, is_read);


--
-- Name: idx_user_outgoing_docs_staff; Type: INDEX; Schema: edoc; Owner: -
--

CREATE INDEX idx_user_outgoing_docs_staff ON edoc.user_outgoing_docs USING btree (staff_id, is_read);


--
-- Name: uq_rooms_code; Type: INDEX; Schema: edoc; Owner: -
--

CREATE UNIQUE INDEX uq_rooms_code ON edoc.rooms USING btree (unit_id, code) WHERE ((code IS NOT NULL) AND (is_deleted = false));


--
-- Name: idx_borrow_requests_department; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_borrow_requests_department ON esto.borrow_requests USING btree (department_id);


--
-- Name: idx_borrow_requests_status; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_borrow_requests_status ON esto.borrow_requests USING btree (status);


--
-- Name: idx_borrow_requests_unit_id; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_borrow_requests_unit_id ON esto.borrow_requests USING btree (unit_id);


--
-- Name: idx_doc_archives_doc; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_doc_archives_doc ON esto.document_archives USING btree (doc_type, doc_id);


--
-- Name: idx_fonds_unit_id; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_fonds_unit_id ON esto.fonds USING btree (unit_id);


--
-- Name: idx_records_department; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_records_department ON esto.records USING btree (department_id);


--
-- Name: idx_records_fond_id; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_records_fond_id ON esto.records USING btree (fond_id);


--
-- Name: idx_records_unit_id; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_records_unit_id ON esto.records USING btree (unit_id);


--
-- Name: idx_records_warehouse_id; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_records_warehouse_id ON esto.records USING btree (warehouse_id);


--
-- Name: idx_warehouses_department; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_warehouses_department ON esto.warehouses USING btree (department_id);


--
-- Name: idx_warehouses_parent_id; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_warehouses_parent_id ON esto.warehouses USING btree (parent_id);


--
-- Name: idx_warehouses_unit_id; Type: INDEX; Schema: esto; Owner: -
--

CREATE INDEX idx_warehouses_unit_id ON esto.warehouses USING btree (unit_id);


--
-- Name: uq_fonds_code; Type: INDEX; Schema: esto; Owner: -
--

CREATE UNIQUE INDEX uq_fonds_code ON esto.fonds USING btree (unit_id, fond_code) WHERE (fond_code IS NOT NULL);


--
-- Name: uq_warehouses_code; Type: INDEX; Schema: esto; Owner: -
--

CREATE UNIQUE INDEX uq_warehouses_code ON esto.warehouses USING btree (unit_id, code) WHERE ((code IS NOT NULL) AND (is_deleted = false));


--
-- Name: idx_documents_category_id; Type: INDEX; Schema: iso; Owner: -
--

CREATE INDEX idx_documents_category_id ON iso.documents USING btree (category_id);


--
-- Name: idx_documents_department; Type: INDEX; Schema: iso; Owner: -
--

CREATE INDEX idx_documents_department ON iso.documents USING btree (department_id);


--
-- Name: idx_documents_unit_id; Type: INDEX; Schema: iso; Owner: -
--

CREATE INDEX idx_documents_unit_id ON iso.documents USING btree (unit_id);


--
-- Name: uq_doc_categories_code; Type: INDEX; Schema: iso; Owner: -
--

CREATE UNIQUE INDEX uq_doc_categories_code ON iso.document_categories USING btree (unit_id, code) WHERE (code IS NOT NULL);


--
-- Name: idx_calendar_events_created_by_start; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_events_created_by_start ON public.calendar_events USING btree (created_by, start_time);


--
-- Name: idx_calendar_events_department; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_events_department ON public.calendar_events USING btree (department_id);


--
-- Name: idx_calendar_events_is_deleted; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_events_is_deleted ON public.calendar_events USING btree (is_deleted);


--
-- Name: idx_calendar_events_scope_unit_start; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_calendar_events_scope_unit_start ON public.calendar_events USING btree (scope, unit_id, start_time);


--
-- Name: idx_departments_is_unit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_departments_is_unit ON public.departments USING btree (is_unit) WHERE (is_deleted = false);


--
-- Name: idx_departments_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_departments_parent ON public.departments USING btree (parent_id);


--
-- Name: idx_login_history_staff; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_login_history_staff ON public.login_history USING btree (staff_id, created_at DESC);


--
-- Name: idx_refresh_tokens_hash; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_tokens_hash ON public.refresh_tokens USING btree (token_hash);


--
-- Name: idx_refresh_tokens_staff; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_refresh_tokens_staff ON public.refresh_tokens USING btree (staff_id);


--
-- Name: idx_rights_parent; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rights_parent ON public.rights USING btree (parent_id);


--
-- Name: idx_staff_department; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_department ON public.staff USING btree (department_id) WHERE (is_deleted = false);


--
-- Name: idx_staff_fullname; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_fullname ON public.staff USING gin (full_name public.gin_trgm_ops);


--
-- Name: idx_staff_unit; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_unit ON public.staff USING btree (unit_id) WHERE (is_deleted = false);


--
-- Name: idx_staff_username; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_staff_username ON public.staff USING btree (username);


--
-- Name: doc_flows trg_doc_flows_updated_at; Type: TRIGGER; Schema: edoc; Owner: -
--

CREATE TRIGGER trg_doc_flows_updated_at BEFORE UPDATE ON edoc.doc_flows FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- Name: drafting_docs trg_drafting_docs_updated_at; Type: TRIGGER; Schema: edoc; Owner: -
--

CREATE TRIGGER trg_drafting_docs_updated_at BEFORE UPDATE ON edoc.drafting_docs FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- Name: handling_docs trg_handling_docs_updated_at; Type: TRIGGER; Schema: edoc; Owner: -
--

CREATE TRIGGER trg_handling_docs_updated_at BEFORE UPDATE ON edoc.handling_docs FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- Name: incoming_docs trg_incoming_docs_updated_at; Type: TRIGGER; Schema: edoc; Owner: -
--

CREATE TRIGGER trg_incoming_docs_updated_at BEFORE UPDATE ON edoc.incoming_docs FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- Name: outgoing_docs trg_outgoing_docs_updated_at; Type: TRIGGER; Schema: edoc; Owner: -
--

CREATE TRIGGER trg_outgoing_docs_updated_at BEFORE UPDATE ON edoc.outgoing_docs FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- Name: departments trg_departments_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_departments_updated_at BEFORE UPDATE ON public.departments FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- Name: positions trg_positions_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_positions_updated_at BEFORE UPDATE ON public.positions FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- Name: roles trg_roles_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_roles_updated_at BEFORE UPDATE ON public.roles FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- Name: staff trg_staff_auto_unit_id; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_staff_auto_unit_id BEFORE INSERT OR UPDATE OF department_id ON public.staff FOR EACH ROW EXECUTE FUNCTION public.fn_staff_auto_unit_id();


--
-- Name: staff trg_staff_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_staff_updated_at BEFORE UPDATE ON public.staff FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();


--
-- Name: contract_attachments contract_attachments_contract_id_fkey; Type: FK CONSTRAINT; Schema: cont; Owner: -
--

ALTER TABLE ONLY cont.contract_attachments
    ADD CONSTRAINT contract_attachments_contract_id_fkey FOREIGN KEY (contract_id) REFERENCES cont.contracts(id) ON DELETE CASCADE;


--
-- Name: contracts contracts_contract_type_id_fkey; Type: FK CONSTRAINT; Schema: cont; Owner: -
--

ALTER TABLE ONLY cont.contracts
    ADD CONSTRAINT contracts_contract_type_id_fkey FOREIGN KEY (contract_type_id) REFERENCES cont.contract_types(id);


--
-- Name: attachment_drafting_docs attachment_drafting_docs_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_drafting_docs
    ADD CONSTRAINT attachment_drafting_docs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: attachment_drafting_docs attachment_drafting_docs_drafting_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_drafting_docs
    ADD CONSTRAINT attachment_drafting_docs_drafting_doc_id_fkey FOREIGN KEY (drafting_doc_id) REFERENCES edoc.drafting_docs(id) ON DELETE CASCADE;


--
-- Name: attachment_handling_docs attachment_handling_docs_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_handling_docs
    ADD CONSTRAINT attachment_handling_docs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: attachment_handling_docs attachment_handling_docs_handling_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_handling_docs
    ADD CONSTRAINT attachment_handling_docs_handling_doc_id_fkey FOREIGN KEY (handling_doc_id) REFERENCES edoc.handling_docs(id) ON DELETE CASCADE;


--
-- Name: attachment_incoming_docs attachment_incoming_docs_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_incoming_docs
    ADD CONSTRAINT attachment_incoming_docs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: attachment_incoming_docs attachment_incoming_docs_incoming_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_incoming_docs
    ADD CONSTRAINT attachment_incoming_docs_incoming_doc_id_fkey FOREIGN KEY (incoming_doc_id) REFERENCES edoc.incoming_docs(id) ON DELETE CASCADE;


--
-- Name: attachment_inter_incoming_docs attachment_inter_incoming_docs_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_inter_incoming_docs
    ADD CONSTRAINT attachment_inter_incoming_docs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: attachment_inter_incoming_docs attachment_inter_incoming_docs_inter_incoming_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_inter_incoming_docs
    ADD CONSTRAINT attachment_inter_incoming_docs_inter_incoming_doc_id_fkey FOREIGN KEY (inter_incoming_doc_id) REFERENCES edoc.inter_incoming_docs(id) ON DELETE CASCADE;


--
-- Name: attachment_outgoing_docs attachment_outgoing_docs_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_outgoing_docs
    ADD CONSTRAINT attachment_outgoing_docs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: attachment_outgoing_docs attachment_outgoing_docs_outgoing_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.attachment_outgoing_docs
    ADD CONSTRAINT attachment_outgoing_docs_outgoing_doc_id_fkey FOREIGN KEY (outgoing_doc_id) REFERENCES edoc.outgoing_docs(id) ON DELETE CASCADE;


--
-- Name: delegations delegations_from_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.delegations
    ADD CONSTRAINT delegations_from_staff_id_fkey FOREIGN KEY (from_staff_id) REFERENCES public.staff(id);


--
-- Name: delegations delegations_to_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.delegations
    ADD CONSTRAINT delegations_to_staff_id_fkey FOREIGN KEY (to_staff_id) REFERENCES public.staff(id);


--
-- Name: device_tokens device_tokens_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.device_tokens
    ADD CONSTRAINT device_tokens_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: digital_signatures digital_signatures_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.digital_signatures
    ADD CONSTRAINT digital_signatures_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: doc_books doc_books_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_books
    ADD CONSTRAINT doc_books_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: doc_fields doc_fields_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_fields
    ADD CONSTRAINT doc_fields_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: doc_flow_step_links doc_flow_step_links_from_step_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_step_links
    ADD CONSTRAINT doc_flow_step_links_from_step_id_fkey FOREIGN KEY (from_step_id) REFERENCES edoc.doc_flow_steps(id) ON DELETE CASCADE;


--
-- Name: doc_flow_step_links doc_flow_step_links_to_step_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_step_links
    ADD CONSTRAINT doc_flow_step_links_to_step_id_fkey FOREIGN KEY (to_step_id) REFERENCES edoc.doc_flow_steps(id) ON DELETE CASCADE;


--
-- Name: doc_flow_step_staff doc_flow_step_staff_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_step_staff
    ADD CONSTRAINT doc_flow_step_staff_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: doc_flow_step_staff doc_flow_step_staff_step_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_step_staff
    ADD CONSTRAINT doc_flow_step_staff_step_id_fkey FOREIGN KEY (step_id) REFERENCES edoc.doc_flow_steps(id) ON DELETE CASCADE;


--
-- Name: doc_flow_steps doc_flow_steps_flow_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flow_steps
    ADD CONSTRAINT doc_flow_steps_flow_id_fkey FOREIGN KEY (flow_id) REFERENCES edoc.doc_flows(id) ON DELETE CASCADE;


--
-- Name: doc_flows doc_flows_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flows
    ADD CONSTRAINT doc_flows_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: doc_flows doc_flows_department_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flows
    ADD CONSTRAINT doc_flows_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: doc_flows doc_flows_doc_field_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flows
    ADD CONSTRAINT doc_flows_doc_field_id_fkey FOREIGN KEY (doc_field_id) REFERENCES edoc.doc_fields(id);


--
-- Name: doc_flows doc_flows_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_flows
    ADD CONSTRAINT doc_flows_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: doc_types doc_types_parent_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.doc_types
    ADD CONSTRAINT doc_types_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES edoc.doc_types(id);


--
-- Name: drafting_docs drafting_docs_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: drafting_docs drafting_docs_department_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: drafting_docs drafting_docs_doc_book_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_doc_book_id_fkey FOREIGN KEY (doc_book_id) REFERENCES edoc.doc_books(id);


--
-- Name: drafting_docs drafting_docs_doc_field_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_doc_field_id_fkey FOREIGN KEY (doc_field_id) REFERENCES edoc.doc_fields(id);


--
-- Name: drafting_docs drafting_docs_doc_type_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_doc_type_id_fkey FOREIGN KEY (doc_type_id) REFERENCES edoc.doc_types(id);


--
-- Name: drafting_docs drafting_docs_drafting_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_drafting_unit_id_fkey FOREIGN KEY (drafting_unit_id) REFERENCES public.departments(id);


--
-- Name: drafting_docs drafting_docs_drafting_user_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_drafting_user_id_fkey FOREIGN KEY (drafting_user_id) REFERENCES public.staff(id);


--
-- Name: drafting_docs drafting_docs_publish_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_publish_unit_id_fkey FOREIGN KEY (publish_unit_id) REFERENCES public.departments(id);


--
-- Name: drafting_docs drafting_docs_rejected_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_rejected_by_fkey FOREIGN KEY (rejected_by) REFERENCES public.staff(id);


--
-- Name: drafting_docs drafting_docs_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.drafting_docs
    ADD CONSTRAINT drafting_docs_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: email_templates email_templates_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.email_templates
    ADD CONSTRAINT email_templates_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: handling_doc_links handling_doc_links_handling_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_doc_links
    ADD CONSTRAINT handling_doc_links_handling_doc_id_fkey FOREIGN KEY (handling_doc_id) REFERENCES edoc.handling_docs(id) ON DELETE CASCADE;


--
-- Name: handling_docs handling_docs_complete_user_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_complete_user_id_fkey FOREIGN KEY (complete_user_id) REFERENCES public.staff(id);


--
-- Name: handling_docs handling_docs_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: handling_docs handling_docs_curator_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_curator_fkey FOREIGN KEY (curator) REFERENCES public.staff(id);


--
-- Name: handling_docs handling_docs_department_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: handling_docs handling_docs_doc_book_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_doc_book_id_fkey FOREIGN KEY (doc_book_id) REFERENCES edoc.doc_books(id);


--
-- Name: handling_docs handling_docs_doc_field_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_doc_field_id_fkey FOREIGN KEY (doc_field_id) REFERENCES edoc.doc_fields(id);


--
-- Name: handling_docs handling_docs_doc_type_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_doc_type_id_fkey FOREIGN KEY (doc_type_id) REFERENCES edoc.doc_types(id);


--
-- Name: handling_docs handling_docs_drafting_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_drafting_unit_id_fkey FOREIGN KEY (drafting_unit_id) REFERENCES public.departments(id);


--
-- Name: handling_docs handling_docs_parent_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES edoc.handling_docs(id);


--
-- Name: handling_docs handling_docs_publish_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_publish_unit_id_fkey FOREIGN KEY (publish_unit_id) REFERENCES public.departments(id);


--
-- Name: handling_docs handling_docs_signer_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_signer_fkey FOREIGN KEY (signer) REFERENCES public.staff(id);


--
-- Name: handling_docs handling_docs_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.handling_docs
    ADD CONSTRAINT handling_docs_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: incoming_docs incoming_docs_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.incoming_docs
    ADD CONSTRAINT incoming_docs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: incoming_docs incoming_docs_department_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.incoming_docs
    ADD CONSTRAINT incoming_docs_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: incoming_docs incoming_docs_doc_book_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.incoming_docs
    ADD CONSTRAINT incoming_docs_doc_book_id_fkey FOREIGN KEY (doc_book_id) REFERENCES edoc.doc_books(id);


--
-- Name: incoming_docs incoming_docs_doc_field_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.incoming_docs
    ADD CONSTRAINT incoming_docs_doc_field_id_fkey FOREIGN KEY (doc_field_id) REFERENCES edoc.doc_fields(id);


--
-- Name: incoming_docs incoming_docs_doc_type_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.incoming_docs
    ADD CONSTRAINT incoming_docs_doc_type_id_fkey FOREIGN KEY (doc_type_id) REFERENCES edoc.doc_types(id);


--
-- Name: incoming_docs incoming_docs_rejected_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.incoming_docs
    ADD CONSTRAINT incoming_docs_rejected_by_fkey FOREIGN KEY (rejected_by) REFERENCES public.staff(id);


--
-- Name: incoming_docs incoming_docs_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.incoming_docs
    ADD CONSTRAINT incoming_docs_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: inter_incoming_docs inter_incoming_docs_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.inter_incoming_docs
    ADD CONSTRAINT inter_incoming_docs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: inter_incoming_docs inter_incoming_docs_department_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.inter_incoming_docs
    ADD CONSTRAINT inter_incoming_docs_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: inter_incoming_docs inter_incoming_docs_doc_field_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.inter_incoming_docs
    ADD CONSTRAINT inter_incoming_docs_doc_field_id_fkey FOREIGN KEY (doc_field_id) REFERENCES edoc.doc_fields(id);


--
-- Name: inter_incoming_docs inter_incoming_docs_doc_type_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.inter_incoming_docs
    ADD CONSTRAINT inter_incoming_docs_doc_type_id_fkey FOREIGN KEY (doc_type_id) REFERENCES edoc.doc_types(id);


--
-- Name: inter_incoming_docs inter_incoming_docs_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.inter_incoming_docs
    ADD CONSTRAINT inter_incoming_docs_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: leader_notes leader_notes_drafting_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.leader_notes
    ADD CONSTRAINT leader_notes_drafting_doc_id_fkey FOREIGN KEY (drafting_doc_id) REFERENCES edoc.drafting_docs(id) ON DELETE CASCADE;


--
-- Name: leader_notes leader_notes_incoming_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.leader_notes
    ADD CONSTRAINT leader_notes_incoming_doc_id_fkey FOREIGN KEY (incoming_doc_id) REFERENCES edoc.incoming_docs(id) ON DELETE CASCADE;


--
-- Name: leader_notes leader_notes_outgoing_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.leader_notes
    ADD CONSTRAINT leader_notes_outgoing_doc_id_fkey FOREIGN KEY (outgoing_doc_id) REFERENCES edoc.outgoing_docs(id) ON DELETE CASCADE;


--
-- Name: leader_notes leader_notes_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.leader_notes
    ADD CONSTRAINT leader_notes_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: lgsp_config lgsp_config_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_config
    ADD CONSTRAINT lgsp_config_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: lgsp_tracking lgsp_tracking_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_tracking
    ADD CONSTRAINT lgsp_tracking_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: lgsp_tracking lgsp_tracking_incoming_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_tracking
    ADD CONSTRAINT lgsp_tracking_incoming_doc_id_fkey FOREIGN KEY (incoming_doc_id) REFERENCES edoc.incoming_docs(id);


--
-- Name: lgsp_tracking lgsp_tracking_outgoing_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.lgsp_tracking
    ADD CONSTRAINT lgsp_tracking_outgoing_doc_id_fkey FOREIGN KEY (outgoing_doc_id) REFERENCES edoc.outgoing_docs(id);


--
-- Name: message_recipients message_recipients_message_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.message_recipients
    ADD CONSTRAINT message_recipients_message_id_fkey FOREIGN KEY (message_id) REFERENCES edoc.messages(id) ON DELETE CASCADE;


--
-- Name: message_recipients message_recipients_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.message_recipients
    ADD CONSTRAINT message_recipients_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: messages messages_from_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.messages
    ADD CONSTRAINT messages_from_staff_id_fkey FOREIGN KEY (from_staff_id) REFERENCES public.staff(id);


--
-- Name: messages messages_parent_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.messages
    ADD CONSTRAINT messages_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES edoc.messages(id);


--
-- Name: notice_reads notice_reads_notice_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notice_reads
    ADD CONSTRAINT notice_reads_notice_id_fkey FOREIGN KEY (notice_id) REFERENCES edoc.notices(id) ON DELETE CASCADE;


--
-- Name: notice_reads notice_reads_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notice_reads
    ADD CONSTRAINT notice_reads_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: notices notices_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notices
    ADD CONSTRAINT notices_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: notices notices_department_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notices
    ADD CONSTRAINT notices_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: notices notices_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notices
    ADD CONSTRAINT notices_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: notification_logs notification_logs_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notification_logs
    ADD CONSTRAINT notification_logs_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: notification_preferences notification_preferences_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.notification_preferences
    ADD CONSTRAINT notification_preferences_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: opinion_handling_docs opinion_handling_docs_handling_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.opinion_handling_docs
    ADD CONSTRAINT opinion_handling_docs_handling_doc_id_fkey FOREIGN KEY (handling_doc_id) REFERENCES edoc.handling_docs(id) ON DELETE CASCADE;


--
-- Name: opinion_handling_docs opinion_handling_docs_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.opinion_handling_docs
    ADD CONSTRAINT opinion_handling_docs_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: organizations organizations_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.organizations
    ADD CONSTRAINT organizations_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: outgoing_docs outgoing_docs_created_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: outgoing_docs outgoing_docs_department_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: outgoing_docs outgoing_docs_doc_book_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_doc_book_id_fkey FOREIGN KEY (doc_book_id) REFERENCES edoc.doc_books(id);


--
-- Name: outgoing_docs outgoing_docs_doc_field_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_doc_field_id_fkey FOREIGN KEY (doc_field_id) REFERENCES edoc.doc_fields(id);


--
-- Name: outgoing_docs outgoing_docs_doc_type_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_doc_type_id_fkey FOREIGN KEY (doc_type_id) REFERENCES edoc.doc_types(id);


--
-- Name: outgoing_docs outgoing_docs_drafting_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_drafting_unit_id_fkey FOREIGN KEY (drafting_unit_id) REFERENCES public.departments(id);


--
-- Name: outgoing_docs outgoing_docs_drafting_user_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_drafting_user_id_fkey FOREIGN KEY (drafting_user_id) REFERENCES public.staff(id);


--
-- Name: outgoing_docs outgoing_docs_publish_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_publish_unit_id_fkey FOREIGN KEY (publish_unit_id) REFERENCES public.departments(id);


--
-- Name: outgoing_docs outgoing_docs_rejected_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_rejected_by_fkey FOREIGN KEY (rejected_by) REFERENCES public.staff(id);


--
-- Name: outgoing_docs outgoing_docs_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.outgoing_docs
    ADD CONSTRAINT outgoing_docs_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: room_schedule_answers room_schedule_answers_room_schedule_question_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_answers
    ADD CONSTRAINT room_schedule_answers_room_schedule_question_id_fkey FOREIGN KEY (room_schedule_question_id) REFERENCES edoc.room_schedule_questions(id) ON DELETE CASCADE;


--
-- Name: room_schedule_attachments room_schedule_attachments_room_schedule_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_attachments
    ADD CONSTRAINT room_schedule_attachments_room_schedule_id_fkey FOREIGN KEY (room_schedule_id) REFERENCES edoc.room_schedules(id) ON DELETE CASCADE;


--
-- Name: room_schedule_questions room_schedule_questions_room_schedule_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_questions
    ADD CONSTRAINT room_schedule_questions_room_schedule_id_fkey FOREIGN KEY (room_schedule_id) REFERENCES edoc.room_schedules(id) ON DELETE CASCADE;


--
-- Name: room_schedule_staff room_schedule_staff_room_schedule_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_staff
    ADD CONSTRAINT room_schedule_staff_room_schedule_id_fkey FOREIGN KEY (room_schedule_id) REFERENCES edoc.room_schedules(id) ON DELETE CASCADE;


--
-- Name: room_schedule_votes room_schedule_votes_answer_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_votes
    ADD CONSTRAINT room_schedule_votes_answer_id_fkey FOREIGN KEY (answer_id) REFERENCES edoc.room_schedule_answers(id) ON DELETE CASCADE;


--
-- Name: room_schedule_votes room_schedule_votes_question_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedule_votes
    ADD CONSTRAINT room_schedule_votes_question_id_fkey FOREIGN KEY (question_id) REFERENCES edoc.room_schedule_questions(id) ON DELETE CASCADE;


--
-- Name: room_schedules room_schedules_department_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedules
    ADD CONSTRAINT room_schedules_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: room_schedules room_schedules_meeting_type_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedules
    ADD CONSTRAINT room_schedules_meeting_type_id_fkey FOREIGN KEY (meeting_type_id) REFERENCES edoc.meeting_types(id);


--
-- Name: room_schedules room_schedules_room_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.room_schedules
    ADD CONSTRAINT room_schedules_room_id_fkey FOREIGN KEY (room_id) REFERENCES edoc.rooms(id);


--
-- Name: send_doc_user_configs send_doc_user_configs_target_user_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.send_doc_user_configs
    ADD CONSTRAINT send_doc_user_configs_target_user_id_fkey FOREIGN KEY (target_user_id) REFERENCES public.staff(id) ON DELETE CASCADE;


--
-- Name: send_doc_user_configs send_doc_user_configs_user_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.send_doc_user_configs
    ADD CONSTRAINT send_doc_user_configs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.staff(id) ON DELETE CASCADE;


--
-- Name: signers signers_department_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.signers
    ADD CONSTRAINT signers_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: signers signers_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.signers
    ADD CONSTRAINT signers_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: signers signers_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.signers
    ADD CONSTRAINT signers_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: sms_templates sms_templates_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.sms_templates
    ADD CONSTRAINT sms_templates_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: staff_handling_docs staff_handling_docs_handling_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.staff_handling_docs
    ADD CONSTRAINT staff_handling_docs_handling_doc_id_fkey FOREIGN KEY (handling_doc_id) REFERENCES edoc.handling_docs(id) ON DELETE CASCADE;


--
-- Name: staff_handling_docs staff_handling_docs_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.staff_handling_docs
    ADD CONSTRAINT staff_handling_docs_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: staff_notes staff_notes_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.staff_notes
    ADD CONSTRAINT staff_notes_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: user_drafting_docs user_drafting_docs_drafting_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_drafting_docs
    ADD CONSTRAINT user_drafting_docs_drafting_doc_id_fkey FOREIGN KEY (drafting_doc_id) REFERENCES edoc.drafting_docs(id) ON DELETE CASCADE;


--
-- Name: user_drafting_docs user_drafting_docs_sent_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_drafting_docs
    ADD CONSTRAINT user_drafting_docs_sent_by_fkey FOREIGN KEY (sent_by) REFERENCES public.staff(id);


--
-- Name: user_drafting_docs user_drafting_docs_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_drafting_docs
    ADD CONSTRAINT user_drafting_docs_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: user_incoming_docs user_incoming_docs_incoming_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_incoming_docs
    ADD CONSTRAINT user_incoming_docs_incoming_doc_id_fkey FOREIGN KEY (incoming_doc_id) REFERENCES edoc.incoming_docs(id) ON DELETE CASCADE;


--
-- Name: user_incoming_docs user_incoming_docs_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_incoming_docs
    ADD CONSTRAINT user_incoming_docs_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: user_outgoing_docs user_outgoing_docs_outgoing_doc_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_outgoing_docs
    ADD CONSTRAINT user_outgoing_docs_outgoing_doc_id_fkey FOREIGN KEY (outgoing_doc_id) REFERENCES edoc.outgoing_docs(id) ON DELETE CASCADE;


--
-- Name: user_outgoing_docs user_outgoing_docs_sent_by_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_outgoing_docs
    ADD CONSTRAINT user_outgoing_docs_sent_by_fkey FOREIGN KEY (sent_by) REFERENCES public.staff(id);


--
-- Name: user_outgoing_docs user_outgoing_docs_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.user_outgoing_docs
    ADD CONSTRAINT user_outgoing_docs_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: work_group_members work_group_members_group_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.work_group_members
    ADD CONSTRAINT work_group_members_group_id_fkey FOREIGN KEY (group_id) REFERENCES edoc.work_groups(id) ON DELETE CASCADE;


--
-- Name: work_group_members work_group_members_staff_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.work_group_members
    ADD CONSTRAINT work_group_members_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: work_groups work_groups_unit_id_fkey; Type: FK CONSTRAINT; Schema: edoc; Owner: -
--

ALTER TABLE ONLY edoc.work_groups
    ADD CONSTRAINT work_groups_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: borrow_request_records borrow_request_records_borrow_request_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.borrow_request_records
    ADD CONSTRAINT borrow_request_records_borrow_request_id_fkey FOREIGN KEY (borrow_request_id) REFERENCES esto.borrow_requests(id) ON DELETE CASCADE;


--
-- Name: borrow_request_records borrow_request_records_record_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.borrow_request_records
    ADD CONSTRAINT borrow_request_records_record_id_fkey FOREIGN KEY (record_id) REFERENCES esto.records(id);


--
-- Name: borrow_requests borrow_requests_department_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.borrow_requests
    ADD CONSTRAINT borrow_requests_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: document_archives document_archives_archived_by_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.document_archives
    ADD CONSTRAINT document_archives_archived_by_fkey FOREIGN KEY (archived_by) REFERENCES public.staff(id);


--
-- Name: document_archives document_archives_fond_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.document_archives
    ADD CONSTRAINT document_archives_fond_id_fkey FOREIGN KEY (fond_id) REFERENCES esto.fonds(id);


--
-- Name: document_archives document_archives_record_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.document_archives
    ADD CONSTRAINT document_archives_record_id_fkey FOREIGN KEY (record_id) REFERENCES esto.records(id);


--
-- Name: document_archives document_archives_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.document_archives
    ADD CONSTRAINT document_archives_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES esto.warehouses(id);


--
-- Name: records records_department_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.records
    ADD CONSTRAINT records_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: records records_fond_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.records
    ADD CONSTRAINT records_fond_id_fkey FOREIGN KEY (fond_id) REFERENCES esto.fonds(id);


--
-- Name: records records_warehouse_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.records
    ADD CONSTRAINT records_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES esto.warehouses(id);


--
-- Name: warehouses warehouses_department_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.warehouses
    ADD CONSTRAINT warehouses_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: warehouses warehouses_unit_id_fkey; Type: FK CONSTRAINT; Schema: esto; Owner: -
--

ALTER TABLE ONLY esto.warehouses
    ADD CONSTRAINT warehouses_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: documents documents_category_id_fkey; Type: FK CONSTRAINT; Schema: iso; Owner: -
--

ALTER TABLE ONLY iso.documents
    ADD CONSTRAINT documents_category_id_fkey FOREIGN KEY (category_id) REFERENCES iso.document_categories(id);


--
-- Name: documents documents_department_id_fkey; Type: FK CONSTRAINT; Schema: iso; Owner: -
--

ALTER TABLE ONLY iso.documents
    ADD CONSTRAINT documents_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: action_of_role action_of_role_right_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_of_role
    ADD CONSTRAINT action_of_role_right_id_fkey FOREIGN KEY (right_id) REFERENCES public.rights(id) ON DELETE CASCADE;


--
-- Name: action_of_role action_of_role_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.action_of_role
    ADD CONSTRAINT action_of_role_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: calendar_events calendar_events_created_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_created_by_fkey FOREIGN KEY (created_by) REFERENCES public.staff(id);


--
-- Name: calendar_events calendar_events_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: calendar_events calendar_events_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.calendar_events
    ADD CONSTRAINT calendar_events_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: communes communes_district_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.communes
    ADD CONSTRAINT communes_district_id_fkey FOREIGN KEY (district_id) REFERENCES public.districts(id);


--
-- Name: configurations configurations_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.configurations
    ADD CONSTRAINT configurations_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: departments departments_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.departments
    ADD CONSTRAINT departments_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.departments(id) ON DELETE SET NULL;


--
-- Name: districts districts_province_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.districts
    ADD CONSTRAINT districts_province_id_fkey FOREIGN KEY (province_id) REFERENCES public.provinces(id);


--
-- Name: login_history login_history_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.login_history
    ADD CONSTRAINT login_history_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id);


--
-- Name: refresh_tokens refresh_tokens_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE CASCADE;


--
-- Name: rights rights_parent_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.rights
    ADD CONSTRAINT rights_parent_id_fkey FOREIGN KEY (parent_id) REFERENCES public.rights(id) ON DELETE SET NULL;


--
-- Name: role_of_staff role_of_staff_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_of_staff
    ADD CONSTRAINT role_of_staff_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles(id) ON DELETE CASCADE;


--
-- Name: role_of_staff role_of_staff_staff_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.role_of_staff
    ADD CONSTRAINT role_of_staff_staff_id_fkey FOREIGN KEY (staff_id) REFERENCES public.staff(id) ON DELETE CASCADE;


--
-- Name: roles roles_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- Name: staff staff_department_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_department_id_fkey FOREIGN KEY (department_id) REFERENCES public.departments(id);


--
-- Name: staff staff_position_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_position_id_fkey FOREIGN KEY (position_id) REFERENCES public.positions(id);


--
-- Name: staff staff_unit_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.staff
    ADD CONSTRAINT staff_unit_id_fkey FOREIGN KEY (unit_id) REFERENCES public.departments(id);


--
-- PostgreSQL database dump complete
--

\unrestrict VaH2ZtMkMxebpmflnpFPFcnXeD2F39FpjnUgR3YnqiOHCnrEa9Pdj6GbLF0Pxlx

