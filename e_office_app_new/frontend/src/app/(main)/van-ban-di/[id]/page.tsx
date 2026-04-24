'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Tag, Button, Space, Row, Col, Timeline, Avatar,
  Upload, Modal, Input, Popconfirm, Checkbox, Empty, Spin, App,
  Badge, Typography, Flex, Dropdown, Drawer, Form, DatePicker, Select,
  InputNumber,
} from 'antd';
import {
  ArrowLeftOutlined, CheckCircleOutlined, CloseCircleOutlined, SendOutlined,
  DeleteOutlined, DownloadOutlined, UploadOutlined, MoreOutlined,
  StarOutlined, StarFilled, PaperClipOutlined,
  ClockCircleOutlined, UserOutlined, FilePdfOutlined,
  FileImageOutlined, FileWordOutlined, FileExcelOutlined, FileOutlined,
  EditOutlined, SafetyCertificateOutlined, StopOutlined, RollbackOutlined,
  ThunderboltOutlined, InboxOutlined, CommentOutlined, SafetyOutlined,
  CloudUploadOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import { useSigning } from '@/hooks/use-signing';
import { useParams, useRouter } from 'next/navigation';
import dayjs from 'dayjs';

const { Text } = Typography;

interface DocDetail {
  id: number; unit_id: number; number: number; sub_number: string;
  notation: string; abstract: string;
  publish_date: string; signer: string; sign_date: string;
  doc_book_id: number; doc_type_id: number; doc_field_id: number;
  secret_id: number; urgent_id: number; number_paper: number; number_copies: number;
  expired_date: string; recipients: string; approver: string; approved: boolean;
  is_handling: boolean; archive_status: boolean;
  is_inter_doc: boolean; is_digital_signed: boolean | number;
  drafting_unit_id: number; drafting_user_id: number; publish_unit_id: number;
  drafting_unit_name: string; drafting_user_name: string; publish_unit_name: string;
  created_by: number; created_at: string; updated_by: number; updated_at: string;
  doc_book_name: string; doc_type_name: string; doc_type_code: string;
  doc_field_name: string; created_by_name: string;
  permissions?: {
    canEdit: boolean;
    canApprove: boolean;
    canRelease: boolean;
    canSend: boolean;
    canRetract: boolean;
  };
}
interface Attachment { id: number; file_name: string; file_path: string; file_size: number; content_type: string; created_by_name: string; created_at: string; is_ca?: boolean; ca_date?: string | null; signed_file_path?: string | null; }
interface Recipient { id: number; staff_id: number; staff_name: string; position_name: string; department_name: string; is_read: boolean; read_at: string; created_at: string; }
interface HistoryEvent { event_type: string; event_time: string; staff_name: string; content: string; }
interface SendableStaff { staff_id: number; full_name: string; position_name: string; department_id: number; department_name: string; }

const SECRET_TAGS: Record<number, { text: string; color: string }> = {
  1: { text: 'Thường', color: 'default' }, 2: { text: 'Mật', color: 'orange' },
  3: { text: 'Tối mật', color: 'red' }, 4: { text: 'Tuyệt mật', color: 'volcano' },
};
const URGENT_TAGS: Record<number, { text: string; color: string }> = {
  1: { text: 'Thường', color: 'default' }, 2: { text: 'Khẩn', color: 'orange' }, 3: { text: 'Hỏa tốc', color: 'red' },
};

// Gap B (HDSD II.3.8): danh sách bộ/ngành Chính phủ — mock data
const CP_ORGANIZATIONS = [
  { code: 'CP.VPCP', name: 'Văn phòng Chính phủ' },
  { code: 'CP.BNV', name: 'Bộ Nội vụ' },
  { code: 'CP.BTC', name: 'Bộ Tài chính' },
  { code: 'CP.BTP', name: 'Bộ Tư pháp' },
  { code: 'CP.BGDDT', name: 'Bộ Giáo dục và Đào tạo' },
  { code: 'CP.BYT', name: 'Bộ Y tế' },
  { code: 'CP.BCT', name: 'Bộ Công Thương' },
  { code: 'CP.BTNMT', name: 'Bộ Tài nguyên và Môi trường' },
];

function fileIcon(name: string) {
  const ext = name.split('.').pop()?.toLowerCase();
  if (ext === 'pdf') return <FilePdfOutlined style={{ color: '#f5222d', fontSize: 20 }} />;
  if (['jpg','jpeg','png','gif','bmp'].includes(ext||'')) return <FileImageOutlined style={{ color: '#1890ff', fontSize: 20 }} />;
  if (['doc','docx'].includes(ext||'')) return <FileWordOutlined style={{ color: '#2f54eb', fontSize: 20 }} />;
  if (['xls','xlsx'].includes(ext||'')) return <FileExcelOutlined style={{ color: '#52c41a', fontSize: 20 }} />;
  return <FileOutlined style={{ fontSize: 20 }} />;
}
function formatSize(bytes: number) {
  if (!bytes) return '';
  if (bytes < 1024) return bytes + ' B';
  if (bytes < 1048576) return (bytes / 1024).toFixed(1) + ' KB';
  return (bytes / 1048576).toFixed(1) + ' MB';
}
function fmtDate(d: string | null) { return d ? dayjs(d).format('DD/MM/YYYY') : '—'; }
function fmtDateTime(d: string | null) { return d ? dayjs(d).format('DD/MM/YYYY HH:mm') : '—'; }
function maskPhone(phone: string): string {
  if (!phone || phone.length < 8) return phone || '';
  return phone.substring(0, 4) + '***' + phone.substring(phone.length - 3);
}


export default function OutgoingDocDetailPage() {
  const { message, modal } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const params = useParams();
  const router = useRouter();
  const docId = Number(params.id);

  const [loading, setLoading] = useState(true);
  const [doc, setDoc] = useState<DocDetail | null>(null);
  const [attachments, setAttachments] = useState<Attachment[]>([]);
  const [recipients, setRecipients] = useState<Recipient[]>([]);
  // Phase 19 v3.0: outgoing_doc_recipients (department + inter_org) với tracking inline
  const [noiNhan, setNoiNhan] = useState<Array<{
    id: number;
    recipient_type: 'internal_unit' | 'external_org';
    recipient_unit_name: string | null;
    recipient_org_name: string | null;
    recipient_org_code: string | null;
    sent_at: string | null;
    sent_status: string;
    error_message: string | null;
    generated_incoming_doc_id: number | null;
    lgsp_doc_id: string | null;
    lgsp_status: string | null;
    lgsp_error_message: string | null;
  }>>([]);
  const [history, setHistory] = useState<HistoryEvent[]>([]);
  const [isBookmarked, setIsBookmarked] = useState(false);
  const [sendModalOpen, setSendModalOpen] = useState(false);
  const [sendableStaff, setSendableStaff] = useState<SendableStaff[]>([]);
  const [selectedStaffIds, setSelectedStaffIds] = useState<number[]>([]);
  const [sending, setSending] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [leaderNotes, setLeaderNotes] = useState<{ id: number; staff_id: number; staff_name: string; position_name: string; content: string; created_at: string }[]>([]);
  const [noteContent, setNoteContent] = useState('');
  const [addingNote, setAddingNote] = useState(false);

  // Giao việc
  const [giaoViecOpen, setGiaoViecOpen] = useState(false);
  const [giaoViecSaving, setGiaoViecSaving] = useState(false);
  const [giaoViecForm] = Form.useForm();
  const [staffOptions, setStaffOptions] = useState<{ value: number; label: string }[]>([]);
  // Thêm vào HSCV
  const [hscvModalOpen, setHscvModalOpen] = useState(false);
  const [hscvList, setHscvList] = useState<{ id: number; name: string; status: number }[]>([]);
  const [selectedHscvId, setSelectedHscvId] = useState<number | null>(null);
  const [hscvSaving, setHscvSaving] = useState(false);
  // Gửi liên thông
  const [lgspModalOpen, setLgspModalOpen] = useState(false);
  const [lgspOrgs, setLgspOrgs] = useState<{ id: number; org_code: string; org_name: string }[]>([]);
  const [selectedLgspOrgs, setSelectedLgspOrgs] = useState<number[]>([]);
  const [lgspSending, setLgspSending] = useState(false);
  // Ký số — sử dụng useSigning hook (Plan 11-06, thay thế mock OTP Plan 1)
  const { openSign, renderSignModal } = useSigning();
  // Gửi trục CP (HDSD II.3.8)
  const [cpModalOpen, setCpModalOpen] = useState(false);
  const [cpSelected, setCpSelected] = useState<string[]>([]);
  const [cpSending, setCpSending] = useState(false);
  // Chuyển lưu trữ VB đi (HDSD II.3.9)
  const [archiveOpen, setArchiveOpen] = useState(false);
  const [archiveForm] = Form.useForm();
  const [archiving, setArchiving] = useState(false);
  const [warehouseOptions, setWarehouseOptions] = useState<{ value: number; label: string }[]>([]);
  const [fondOptions, setFondOptions] = useState<{ value: number; label: string }[]>([]);
  // Phase 17 v3.0: Ban hành + Gửi nội bộ
  const [releasing, setReleasing] = useState(false);
  const [noiBoModalOpen, setNoiBoModalOpen] = useState(false);
  const [deptOptions, setDeptOptions] = useState<{ value: number; label: string }[]>([]);
  const [selectedDeptIds, setSelectedDeptIds] = useState<number[]>([]);
  const [noiBoSending, setNoiBoSending] = useState(false);
  // 'send' = chỉ gửi (VB đã ban hành). 'release-and-send' = ban hành + gửi trong 1 flow.
  const [noiBoMode, setNoiBoMode] = useState<'send' | 'release-and-send'>('send');

  const fetchDoc = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-di/${docId}`); setDoc(res.data); } catch { message.error('Không tìm thấy văn bản'); router.push('/van-ban-di'); } }, [docId, message, router]);
  const fetchBookmarkStatus = useCallback(async () => { try { const { data: res } = await api.get('/van-ban-di/danh-dau-ca-nhan'); const bookmarks: { doc_id: number | string }[] = res.data || []; setIsBookmarked(bookmarks.some((b) => Number(b.doc_id) === Number(docId))); } catch {} }, [docId]);
  const fetchAttachments = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-di/${docId}/dinh-kem`); setAttachments(res.data || []); } catch {} }, [docId]);
  const fetchRecipients = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-di/${docId}/nguoi-nhan`); setRecipients(res.data || []); } catch {} }, [docId]);
  // Phase 19 v3.0: load outgoing_doc_recipients (departments + inter_orgs) với tracking
  const fetchNoiNhan = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-di/${docId}/noi-nhan`); setNoiNhan(res.data || []); } catch {} }, [docId]);
  const fetchHistory = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-di/${docId}/lich-su`); setHistory(res.data || []); } catch {} }, [docId]);
  const fetchLeaderNotes = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-di/${docId}/y-kien`); setLeaderNotes(res.data || []); } catch {} }, [docId]);

  useEffect(() => {
    setLoading(true);
    Promise.all([fetchDoc(), fetchAttachments(), fetchRecipients(), fetchNoiNhan(), fetchHistory(), fetchLeaderNotes(), fetchBookmarkStatus()]).finally(() => setLoading(false));
    fetchStaffOptions();
  }, [fetchDoc, fetchAttachments, fetchRecipients, fetchNoiNhan, fetchHistory, fetchLeaderNotes, fetchBookmarkStatus]);

  // Actions
  const handleApprove = async () => { try { await api.patch(`/van-ban-di/${docId}/duyet`); message.success('Duyệt thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleUnapprove = async () => { try { await api.patch(`/van-ban-di/${docId}/huy-duyet`); message.success('Hủy duyệt thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleRetract = () => { modal.confirm({ title: 'Thu hồi văn bản đi', content: 'Thu hồi sẽ xóa tất cả người nhận và đặt lại trạng thái chưa duyệt. Bạn chắc chắn?', okText: 'Thu hồi', okButtonProps: { danger: true }, cancelText: 'Hủy', onOk: async () => { try { await api.post(`/van-ban-di/${docId}/thu-hoi`); message.success('Thu hồi thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } } }); };
  const handleReject = () => { let reason = ''; modal.confirm({ title: 'Từ chối văn bản đi', content: (<div style={{ marginTop: 12 }}><div style={{ marginBottom: 8, color: '#595959' }}>Lý do từ chối (không bắt buộc):</div><Input.TextArea rows={3} placeholder="Lý do..." onChange={(e) => { reason = e.target.value; }} /></div>), okText: 'Từ chối', okButtonProps: { danger: true }, cancelText: 'Hủy', onOk: async () => { try { await api.patch(`/van-ban-di/${docId}/tu-choi`, { reason: reason.trim() || undefined }); message.success('Đã từ chối'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } } }); };
  const handleDelete = () => { modal.confirm({ title: 'Xác nhận xóa', content: 'Xóa văn bản này?', okText: 'Xóa', okType: 'danger', cancelText: 'Hủy', onOk: async () => { try { await api.delete(`/van-ban-di/${docId}`); message.success('Đã xóa'); router.push('/van-ban-di'); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } } }); };
  const handleToggleBookmark = async () => { try { const { data: res } = await api.post(`/van-ban-di/${docId}/danh-dau`, {}); setIsBookmarked(res.data?.is_bookmarked); message.success(res.data?.message); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };

  // Leader Notes
  const handleAddNote = async () => {
    if (!noteContent.trim()) { message.warning('Nhập nội dung ý kiến'); return; }
    setAddingNote(true);
    try { await api.post(`/van-ban-di/${docId}/y-kien`, { content: noteContent.trim() }); message.success('Thêm ý kiến thành công'); setNoteContent(''); fetchLeaderNotes(); fetchHistory(); }
    catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setAddingNote(false); }
  };
  const handleDeleteNote = async (noteId: number) => { try { await api.delete(`/van-ban-di/${docId}/y-kien/${noteId}`); message.success('Đã xóa'); fetchLeaderNotes(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };

  // Giao việc
  const fetchStaffOptions = async () => {
    try { const { data: res } = await api.get('/quan-tri/nguoi-dung', { params: { page: 1, pageSize: 200 } }); setStaffOptions((res.data || []).map((s: { id: number; full_name: string; position_name?: string }) => ({ value: s.id, label: s.full_name + (s.position_name ? ` (${s.position_name})` : '') }))); } catch {}
  };
  const openGiaoViec = async () => { await fetchStaffOptions(); giaoViecForm.resetFields(); giaoViecForm.setFieldsValue({ name: doc ? `Xử lý VB đi: ${doc.notation || doc.abstract?.substring(0, 50)}` : '' }); setGiaoViecOpen(true); };
  const handleGiaoViec = async () => {
    try {
      const values = await giaoViecForm.validateFields();
      setGiaoViecSaving(true);
      await api.post(`/van-ban-di/${docId}/giao-viec`, { name: values.name, start_date: values.start_date?.toISOString() || null, end_date: values.end_date?.toISOString() || null, curator_ids: values.curator_ids || [], note: values.note || null });
      message.success('Giao việc thành công'); setGiaoViecOpen(false); giaoViecForm.resetFields();
    } catch (e: any) { if (e?.response?.data?.message) message.error(e.response.data.message); }
    finally { setGiaoViecSaving(false); }
  };
  // Thêm vào HSCV
  const openHscvModal = async () => { try { const { data: res } = await api.get(`/van-ban-di/${docId}/danh-sach-hscv`); setHscvList(res.data || []); setSelectedHscvId(null); setHscvModalOpen(true); } catch { message.error('Lỗi tải HSCV'); } };
  const handleLinkHscv = async () => {
    if (!selectedHscvId) { message.warning('Vui lòng chọn HSCV'); return; }
    setHscvSaving(true);
    try { const { data: res } = await api.post(`/van-ban-di/${docId}/them-vao-hscv`, { handling_doc_id: selectedHscvId }); if (res.success) { message.success('Đã thêm vào HSCV'); setHscvModalOpen(false); } else message.error(res.message); }
    catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setHscvSaving(false); }
  };
  // Gửi liên thông
  const openLgspModal = async () => { try { const { data: res } = await api.get(`/van-ban-den/1/lgsp/don-vi`); setLgspOrgs(res.data || []); setSelectedLgspOrgs([]); setLgspModalOpen(true); } catch { message.error('Lỗi tải đơn vị LGSP'); } };
  const handleSendLgsp = async () => {
    if (selectedLgspOrgs.length === 0) { message.warning('Vui lòng chọn đơn vị'); return; }
    setLgspSending(true);
    try {
      const orgCodes = selectedLgspOrgs.map(id => { const org = lgspOrgs.find(o => o.id === id); return { code: org?.org_code, name: org?.org_name }; });
      const { data: res } = await api.post(`/van-ban-di/${docId}/gui-lien-thong`, { org_codes: orgCodes });
      message.success(res.data?.message || 'Đã gửi liên thông'); setLgspModalOpen(false);
    } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setLgspSending(false); }
  };

  // Attachments
  const handleUpload = async (file: File) => { setUploading(true); try { const fd = new FormData(); fd.append('file', file); await api.post(`/van-ban-di/${docId}/dinh-kem`, fd, { headers: { 'Content-Type': 'multipart/form-data' } }); message.success('Tải lên thành công'); fetchAttachments(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } finally { setUploading(false); } return false; };
  const handleDownload = async (att: Attachment) => { try { const { data: res } = await api.get(`/van-ban-di/${docId}/dinh-kem/${att.id}/download`); window.open(res.data?.url, '_blank'); } catch { message.error('Lỗi tải file'); } };
  const handleDeleteAttachment = async (att: Attachment) => { try { await api.delete(`/van-ban-di/${docId}/dinh-kem/${att.id}`); message.success('Đã xóa'); fetchAttachments(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };

  // Chuyển lưu trữ VB đi (HDSD II.3.9)
  const openArchive = async () => {
    try {
      const [fondRes, whRes] = await Promise.all([
        api.get(`/van-ban-di/${docId}/luu-tru/phong`),
        api.get(`/van-ban-di/${docId}/luu-tru/kho`),
      ]);
      setFondOptions((fondRes.data?.data || []).map((f: { id: number; name: string }) => ({ value: f.id, label: f.name })));
      setWarehouseOptions((whRes.data?.data || []).map((w: { id: number; name: string }) => ({ value: w.id, label: w.name })));
      archiveForm.resetFields();
      archiveForm.setFieldsValue({ language: 'Tiếng Việt', format: 'Điện tử', is_original: true });
      setArchiveOpen(true);
    } catch { message.error('Lỗi tải dữ liệu lưu trữ'); }
  };
  const handleArchive = async () => {
    try {
      const values = await archiveForm.validateFields();
      setArchiving(true);
      const { data: res } = await api.post(`/van-ban-di/${docId}/chuyen-luu-tru`, values);
      if (res.success) { message.success('Chuyển lưu trữ thành công'); setArchiveOpen(false); fetchDoc(); fetchHistory(); }
      else message.error(res.message);
    } catch (e: any) { if (e?.response?.data?.message) message.error(e.response.data.message); }
    finally { setArchiving(false); }
  };

  // Gửi trục CP (mock — HDSD II.3.8)
  const handleSendCp = async () => {
    if (cpSelected.length === 0) {
      message.warning('Vui lòng chọn ít nhất 1 bộ/ngành');
      return;
    }
    setCpSending(true);
    try {
      const orgCodes = cpSelected
        .map(code => CP_ORGANIZATIONS.find(o => o.code === code))
        .filter((o): o is { code: string; name: string } => Boolean(o))
        .map(o => ({ code: o.code, name: o.name }));
      // TODO Phase 2: tích hợp API trục CP thực — hiện chỉ gọi mock endpoint
      const { data: res } = await api.post(`/van-ban-di/${docId}/gui-truc-cp`, { org_codes: orgCodes });
      message.success(res?.data?.message || 'Đã gửi trục CP');
      setCpModalOpen(false);
      setCpSelected([]);
      fetchHistory();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Gửi thất bại');
    } finally {
      setCpSending(false);
    }
  };

  // Phase 17 v3.0: Ban hành (cấp số) + Gửi nội bộ (chọn đơn vị → auto-sinh incoming)
  const handleRelease = async () => {
    setReleasing(true);
    try {
      const { data: res } = await api.patch(`/van-ban-di/${docId}/ban-hanh`);
      message.success(res?.data?.message || `Ban hành thành công, số ${res?.data?.doc_number}`);
      fetchDoc();
      fetchHistory();
    } catch (e: any) {
      message.error(e?.response?.data?.message || 'Lỗi');
    } finally {
      setReleasing(false);
    }
  };

  // Phase 17 v3.0 (Option C): Gửi tới recipients đã lưu trong outgoing_doc_recipients
  // Nếu chưa có recipients → mở modal chọn đơn vị nhận inline (tránh blocking user
  // khi VB đi tạo từ VB dự thảo chưa có structured recipients).
  const handleSendDirect = async () => {
    if (noiNhan.length === 0) {
      setNoiBoMode('send');
      openNoiBoModal();
      return;
    }
    setNoiBoSending(true);
    try {
      const { data: res } = await api.post(`/van-ban-di/${docId}/gui-noi-bo`);
      message.success(res?.data?.message || `Đã gửi: ${res?.data?.internal_count} đơn vị nội bộ + ${res?.data?.external_count} cơ quan ngoài`);
      fetchDoc();
      fetchHistory();
      fetchRecipients();
      fetchNoiNhan();
    } catch (e: any) {
      message.error(e?.response?.data?.message || 'Gửi thất bại');
    } finally {
      setNoiBoSending(false);
    }
  };

  // Combined: Ban hành + Gửi cùng 1 click (cho user fast workflow)
  // Nếu chưa có recipients → mở modal chọn trước, submit sẽ ban-hanh + send.
  const handleReleaseAndSend = async () => {
    if (noiNhan.length === 0) {
      setNoiBoMode('release-and-send');
      openNoiBoModal();
      return;
    }
    setReleasing(true);
    try {
      const { data: r1 } = await api.patch(`/van-ban-di/${docId}/ban-hanh`);
      if (!r1?.success) { message.error(r1?.data?.message || 'Ban hành thất bại'); return; }
      const { data: r2 } = await api.post(`/van-ban-di/${docId}/gui-noi-bo`);
      message.success(`Đã ban hành (số ${r1?.data?.doc_number}) và gửi: ${r2?.data?.internal_count} nội bộ + ${r2?.data?.external_count} ngoài`);
      fetchDoc();
      fetchHistory();
      fetchRecipients();
      fetchNoiNhan();
    } catch (e: any) {
      message.error(e?.response?.data?.message || 'Lỗi');
    } finally {
      setReleasing(false);
    }
  };

  const openNoiBoModal = async () => {
    try {
      const { data: res } = await api.get('/quan-tri/don-vi');
      // Loại trừ đơn vị phát hành VB (không gửi về chính mình) — mọi user khác đều được chọn.
      // Nghiệp vụ: nhân viên có thể gửi VB đi lên cấp trên, ngang cấp, hoặc phòng ban bất kỳ.
      const opts = (res.data || [])
        .filter((d: any) => d.id !== doc?.unit_id)
        .map((d: any) => ({ value: d.id, label: d.name }));
      setDeptOptions(opts);
      setSelectedDeptIds([]);
      setNoiBoModalOpen(true);
    } catch (e: any) {
      message.error(e?.response?.data?.message || 'Không tải được danh sách đơn vị');
    }
  };

  const handleSendNoiBo = async () => {
    if (selectedDeptIds.length === 0) { message.warning('Chọn ít nhất 1 đơn vị nhận'); return; }
    setNoiBoSending(true);
    try {
      // 1. Lưu recipients
      await api.post(`/van-ban-di/${docId}/noi-nhan`, {
        recipients: selectedDeptIds.map((unit_id) => ({ type: 'internal_unit', unit_id })),
      });
      // 2. Nếu mode release-and-send: ban-hành trước khi gửi
      if (noiBoMode === 'release-and-send') {
        const { data: r1 } = await api.patch(`/van-ban-di/${docId}/ban-hanh`);
        if (!r1?.success) { message.error(r1?.data?.message || 'Ban hành thất bại'); return; }
      }
      // 3. Gửi
      const { data: res } = await api.post(`/van-ban-di/${docId}/gui-noi-bo`);
      const prefix = noiBoMode === 'release-and-send' ? 'Đã ban hành và gửi' : 'Đã gửi';
      message.success(res?.data?.message || `${prefix}: ${res?.data?.internal_count} đơn vị nội bộ`);
      setNoiBoModalOpen(false);
      fetchDoc();
      fetchHistory();
      fetchNoiNhan();
    } catch (e: any) {
      message.error(e?.response?.data?.message || 'Gửi thất bại');
    } finally {
      setNoiBoSending(false);
    }
  };

  // Send
  const openSendModal = async () => { try { const { data: res } = await api.get(`/van-ban-di/${docId}/danh-sach-gui`); setSendableStaff(res.data || []); setSelectedStaffIds([]); setSendModalOpen(true); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleSend = async () => {
    if (selectedStaffIds.length === 0) { message.warning('Chọn ít nhất một người nhận'); return; }
    setSending(true);
    try { const { data: res } = await api.post(`/van-ban-di/${docId}/gui`, { staff_ids: selectedStaffIds }); message.success(res.data?.message || 'Đã gửi'); setSendModalOpen(false); fetchRecipients(); fetchHistory(); }
    catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setSending(false); }
  };

  if (loading) return <div style={{ textAlign: 'center', padding: 80 }}><Spin size="large" /></div>;
  if (!doc) return <Empty description="Không tìm thấy văn bản" />;

  const urgentTag = URGENT_TAGS[doc.urgent_id];
  const secretTag = SECRET_TAGS[doc.secret_id];
  const isOverdue = doc.expired_date && dayjs(doc.expired_date).isBefore(dayjs());

  return (
    <div>
      {/* ====== HEADER BAR ====== */}
      <div style={{
        background: '#fff', borderRadius: 10, padding: '16px 24px', marginBottom: 16,
        boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12,
      }}>
        <Flex align="center" gap={12}>
          <Button icon={<ArrowLeftOutlined />} onClick={() => router.push('/van-ban-di')} />
          <div>
            <div style={{ fontSize: 16, fontWeight: 700, color: '#1B3A5C' }}>
              Số đi: {doc.number}{doc.sub_number ? `/${doc.sub_number}` : ''} — {doc.notation || 'Không có ký hiệu'}
            </div>
            <div style={{ fontSize: 13, color: '#8c8c8c' }}>
              {doc.drafting_unit_name || 'Đơn vị soạn'} • Ngày ban hành: {fmtDate(doc.publish_date)}
            </div>
          </div>
          {doc.approved
            ? <Tag color="success" icon={<SafetyCertificateOutlined />}>Đã duyệt</Tag>
            : (doc as any).rejected_by
              ? <Tag color="error">Từ chối</Tag>
              : <Tag color="gold">Chờ duyệt</Tag>
          }
          {doc.urgent_id > 1 && <Tag color={urgentTag.color}>{urgentTag.text}</Tag>}
          {doc.secret_id > 1 && <Tag color={secretTag.color}>{secretTag.text}</Tag>}
        </Flex>
        {(doc as any).rejected_by && (doc as any).rejection_reason && (
          <div style={{ marginTop: 8, padding: '8px 12px', background: '#fff1f0', border: '1px solid #ffa39e', borderRadius: 6, color: '#cf1322' }}>
            <strong>Lý do từ chối:</strong> {(doc as any).rejection_reason}
          </div>
        )}

        <Space wrap>
          <Button
            icon={isBookmarked ? <StarFilled style={{ color: '#faad14' }} /> : <StarOutlined />}
            onClick={handleToggleBookmark}
          />
          {(doc.permissions?.canApprove ?? false) && (
            <Button icon={<ThunderboltOutlined />} type="primary" style={{ backgroundColor: '#0891B2', borderColor: '#0891B2' }} onClick={openGiaoViec}>Giao việc</Button>
          )}
          {(doc.permissions?.canApprove ?? false) && (
            <Button icon={<InboxOutlined />} onClick={openHscvModal}>Thêm vào HSCV</Button>
          )}
          {/* Phase 19 v3.0: ẨN 2 nút legacy v1.0 — recipient ngoài LGSP đã có trong form 'Cơ quan nhận ngoài' khi soạn. Trục CP defer Phase 2 KH. */}
          {/* Chuyển lưu trữ — tạm ẩn chờ Phase 2 (module Kho lưu trữ đang ẩn với KH) */}
          {false && doc?.approved && !doc?.archive_status && (doc?.permissions?.canApprove ?? false) && (
            <Button icon={<InboxOutlined />} onClick={openArchive}>Chuyển lưu trữ</Button>
          )}
          {!doc.approved && (
            <>
              {(doc.permissions?.canEdit ?? false) && (
                <Button icon={<EditOutlined />} onClick={() => router.push(`/van-ban-di?edit=${doc.id}`)}>Sửa</Button>
              )}
              {(doc.permissions?.canApprove ?? false) && (
                <Button type="primary" icon={<CheckCircleOutlined />} onClick={handleApprove}>Duyệt</Button>
              )}
              <Dropdown menu={{ items: [
                ...( !(doc as any).rejected_by && (doc.permissions?.canApprove ?? false) ? [{ key: 'reject', icon: <StopOutlined />, label: 'Từ chối', danger: true, onClick: handleReject }] : []),
                ...((doc.permissions?.canEdit ?? false) ? [
                  { type: 'divider' as const },
                  { key: 'delete', icon: <DeleteOutlined />, label: 'Xóa văn bản', danger: true, onClick: handleDelete },
                ] : []),
              ] }}>
                <Button icon={<MoreOutlined />} />
              </Dropdown>
            </>
          )}
          {/* Phase 17 v3.0 (Option C): Approved nhưng chưa ban hành → 2 lựa chọn */}
          {doc.approved && !(doc as any).is_released && (
            <>
              {(doc.permissions?.canRelease ?? false) && (
                <Button type="primary" icon={<CheckCircleOutlined />} loading={releasing} onClick={handleRelease} style={{ backgroundColor: '#7C3AED', borderColor: '#7C3AED' }}>Ban hành</Button>
              )}
              {(doc.permissions?.canRelease ?? false) && (doc.permissions?.canSend ?? false) && (
                <Button type="primary" icon={<SendOutlined />} loading={releasing || noiBoSending} onClick={handleReleaseAndSend} style={{ backgroundColor: '#059669', borderColor: '#059669' }}>Ban hành & Gửi</Button>
              )}
              <Dropdown menu={{ items: [
                ...((doc.permissions?.canApprove ?? false) ? [{ key: 'unapprove', icon: <CloseCircleOutlined />, label: 'Hủy duyệt', onClick: handleUnapprove }] : []),
              ] }}>
                <Button icon={<MoreOutlined />} />
              </Dropdown>
            </>
          )}
          {/* Đã ban hành, chưa gửi → nút Gửi (đẩy recipients đã lưu khi tạo) */}
          {doc.approved && (doc as any).is_released && (doc as any).status !== 'sent' && (
            <>
              {(doc.permissions?.canSend ?? false) && (
                <Button type="primary" icon={<SendOutlined />} loading={noiBoSending} onClick={handleSendDirect} style={{ backgroundColor: '#0891B2', borderColor: '#0891B2' }}>Gửi</Button>
              )}
              <Dropdown menu={{ items: [
                ...(recipients.length > 0 && (doc.permissions?.canRetract ?? false) ? [{ key: 'retract', icon: <RollbackOutlined />, label: 'Thu hồi', onClick: handleRetract }] : []),
              ] }}>
                <Button icon={<MoreOutlined />} />
              </Dropdown>
            </>
          )}
          {/* Đã gửi → readonly + Thu hồi nếu cần */}
          {doc.approved && (doc as any).status === 'sent' && (
            <Dropdown menu={{ items: [
              ...(recipients.length > 0 && (doc.permissions?.canRetract ?? false) ? [{ key: 'retract', icon: <RollbackOutlined />, label: 'Thu hồi', onClick: handleRetract }] : []),
            ] }}>
              <Button icon={<MoreOutlined />} />
            </Dropdown>
          )}
        </Space>
      </div>

      <Row gutter={16}>
        {/* ====== LEFT COLUMN ====== */}
        <Col xs={24} lg={16}>

          {/* --- Trích yếu --- */}
          <div style={{
            background: '#fff', borderRadius: 10, padding: '20px 24px', marginBottom: 16,
            boxShadow: '0 1px 3px rgba(0,0,0,0.06)', borderLeft: '4px solid #0891B2',
          }}>
            <div style={{ fontSize: 11, textTransform: 'uppercase', color: '#8c8c8c', letterSpacing: 1, marginBottom: 8 }}>Trích yếu nội dung</div>
            <div style={{ fontSize: 15, fontWeight: 600, color: '#1B3A5C', lineHeight: 1.6 }}>
              {doc.abstract}
            </div>
          </div>

          {/* --- Thông tin chi tiết --- */}
          <div style={{
            background: '#fff', borderRadius: 10, padding: '20px 24px', marginBottom: 16,
            boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
          }}>
            <div className="section-title">Thông tin văn bản</div>
            <div style={{ marginTop: 16 }}>
              <div className="info-grid">
                <div><div className="info-label">Số đi</div><div className="info-value">{doc.number}{doc.sub_number ? `/${doc.sub_number}` : ''}</div></div>
                <div><div className="info-label">Ngày ban hành</div><div className="info-value">{fmtDate(doc.publish_date)}</div></div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Số ký hiệu</div><div className="info-value" style={{ color: '#0891B2' }}>{doc.notation || '—'}</div></div>
                <div><div className="info-label">Sổ văn bản</div><div className="info-value">{doc.doc_book_name || '—'}</div></div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Đơn vị soạn</div><div className="info-value">{doc.drafting_unit_name || '—'}</div></div>
                <div><div className="info-label">Người soạn</div><div className="info-value">{doc.drafting_user_name || '—'}</div></div>
              </div>
              <div className="info-grid-full">
                <div className="info-label">Đơn vị phát hành</div>
                <div className="info-value">{doc.publish_unit_name || '—'}</div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Loại văn bản</div><div className="info-value">{doc.doc_type_name || '—'}</div></div>
                <div><div className="info-label">Lĩnh vực</div><div className="info-value">{doc.doc_field_name || '—'}</div></div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Người ký</div><div className="info-value">{doc.signer || '—'}</div></div>
                <div><div className="info-label">Ngày ký</div><div className="info-value">{fmtDate(doc.sign_date)}</div></div>
              </div>
              <div className="info-grid">
                <div>
                  <div className="info-label">Hạn xử lý</div>
                  <div className="info-value" style={{ color: isOverdue ? '#ff4d4f' : undefined }}>
                    {doc.expired_date ? fmtDate(doc.expired_date) : '—'}
                    {isOverdue && <Tag color="error" style={{ marginLeft: 8 }}>Quá hạn</Tag>}
                  </div>
                </div>
                <div>
                  <div className="info-label">Nơi nhận</div>
                  <div className="info-value">{doc.recipients || '—'}</div>
                  {!doc.is_released && noiNhan.length === 0 && (
                    <Tag color="warning" style={{ marginTop: 4 }}>Chưa chọn đơn vị nhận chính thức — sẽ yêu cầu chọn khi Gửi</Tag>
                  )}
                </div>
              </div>
              <div className="info-grid">
                <div>
                  <div className="info-label">Người duyệt</div>
                  <div className="info-value">
                    {doc.approver
                      ? <>{doc.approver} {(doc as any).approved_at && <Tag color="success" style={{ marginLeft: 8 }}>{fmtDateTime((doc as any).approved_at)}</Tag>}</>
                      : <span style={{ color: '#bfbfbf' }}>Chưa duyệt</span>}
                  </div>
                </div>
                <div>
                  <div className="info-label">Trạng thái phát hành</div>
                  <div className="info-value">
                    {(doc as any).is_released
                      ? <Tag color="purple">Đã ban hành{(doc as any).released_date ? ` ${fmtDateTime((doc as any).released_date)}` : ''}</Tag>
                      : <Tag color="default">Chưa ban hành</Tag>}
                  </div>
                </div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Độ mật</div><Tag color={secretTag.color}>{secretTag.text}</Tag></div>
                <div><div className="info-label">Độ khẩn</div><Tag color={urgentTag.color}>{urgentTag.text}</Tag></div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Số tờ / Số bản</div><div className="info-value">{doc.number_paper} tờ / {doc.number_copies} bản</div></div>
                <div><div className="info-label">Ký số</div>{doc.is_digital_signed ? <Tag color="success">Đã ký số</Tag> : <Tag>Chưa ký số</Tag>}</div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Liên thông</div>{doc.is_inter_doc ? <Tag color="processing">Liên thông</Tag> : <Tag>Nội bộ</Tag>}</div>
                {/* Lưu trữ — tạm ẩn chờ Phase 2 (module Kho lưu trữ đang ẩn với KH) */}
                {false && (
                  <div><div className="info-label">Lưu trữ</div>{doc?.archive_status ? <Tag color="success">Đã lưu trữ</Tag> : <Tag>Chưa lưu trữ</Tag>}</div>
                )}
              </div>
              <div className="info-grid" style={{ borderTop: '1px solid #f0f0f0', paddingTop: 12, marginTop: 12 }}>
                <div><div className="info-label">Người nhập</div><div style={{ fontSize: 13, color: '#595959' }}>{doc.created_by_name}</div></div>
                <div><div className="info-label">Thời gian tạo</div><div style={{ fontSize: 13, color: '#595959' }}>{fmtDateTime(doc.created_at)}</div></div>
              </div>
            </div>
          </div>

          {/* --- File đính kèm --- */}
          <div style={{
            background: '#fff', borderRadius: 10, padding: '20px 24px', marginBottom: 16,
            boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
          }}>
            <Flex justify="space-between" align="center" style={{ marginBottom: 12 }}>
              <div className="section-title"><PaperClipOutlined /> Tài liệu đính kèm ({attachments.length})</div>
              {!doc.approved && (
                <Upload showUploadList={false} beforeUpload={(file) => { handleUpload(file); return false; }}>
                  <Button icon={<UploadOutlined />} loading={uploading} size="small" type="primary" ghost>Thêm file</Button>
                </Upload>
              )}
            </Flex>
            {attachments.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '16px 0', color: '#bfbfbf' }}>Chưa có file đính kèm</div>
            ) : (
              <div>
                {attachments.map((att) => (
                  <Flex key={att.id} align="center" justify="space-between" style={{ padding: '10px 12px', borderRadius: 8, background: '#fafafa', marginBottom: 6 }}>
                    <Flex align="center" gap={10} style={{ flex: 1, minWidth: 0 }}>
                      {fileIcon(att.file_name)}
                      <div style={{ minWidth: 0 }}>
                        <div style={{ fontWeight: 500, fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{att.file_name}</div>
                        <Text type="secondary" style={{ fontSize: 11 }}>{formatSize(att.file_size)} • {fmtDateTime(att.created_at)}</Text>
                      </div>
                    </Flex>
                    <Space size={4}>
                      {att.is_ca ? (
                        <Tag color="success" icon={<CheckCircleOutlined />}>Đã ký số</Tag>
                      ) : (
                        <Button size="small" type="primary" ghost icon={<SafetyOutlined />} onClick={() => openSign({
                          attachment: { id: att.id, file_name: att.file_name },
                          attachmentType: 'outgoing',
                          docId: doc.id,
                          signReason: `Phê duyệt VB đi số ${doc.number}/${doc.notation}`,
                          signLocation: doc.drafting_unit_name || 'Lào Cai',
                          onSuccess: fetchAttachments,
                        })}>
                          Ký số
                        </Button>
                      )}
                      <Button size="small" type="link" icon={<DownloadOutlined />} onClick={() => handleDownload(att)} />
                      {!doc.approved && <Popconfirm title="Xóa file?" onConfirm={() => handleDeleteAttachment(att)}><Button size="small" type="link" danger icon={<DeleteOutlined />} /></Popconfirm>}
                    </Space>
                  </Flex>
                ))}
              </div>
            )}
          </div>
        </Col>

        {/* ====== RIGHT COLUMN ====== */}
        <Col xs={24} lg={8}>

          {/* --- Phase 19 v3.0: Đơn vị / Cơ quan nhận (recipient_type + tracking inline) --- */}
          {noiNhan.length > 0 && (
            <div style={{
              background: '#fff', borderRadius: 10, padding: '20px 24px', marginBottom: 16,
              boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
            }}>
              <div className="section-title" style={{ marginBottom: 12 }}>
                <SendOutlined /> Đơn vị / Cơ quan nhận ({noiNhan.length})
              </div>
              <div>
                {noiNhan.map((r) => (
                  <Flex key={r.id} align="center" gap={10} style={{ padding: '10px 0', borderBottom: '1px solid #f5f5f5' }}>
                    <Tag color={r.recipient_type === 'internal_unit' ? 'blue' : 'green'} style={{ minWidth: 64, textAlign: 'center', margin: 0 }}>
                      {r.recipient_type === 'internal_unit' ? 'Nội bộ' : 'LGSP'}
                    </Tag>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 500, fontSize: 13 }}>
                        {r.recipient_unit_name || r.recipient_org_name || '—'}
                        {r.recipient_org_code && <span style={{ color: '#8c8c8c', marginLeft: 6 }}>({r.recipient_org_code})</span>}
                      </div>
                      <div style={{ fontSize: 11, color: '#8c8c8c', marginTop: 2 }}>
                        {r.recipient_type === 'internal_unit' && r.sent_status === 'sent' && r.generated_incoming_doc_id ? (
                          <span style={{ color: '#52c41a' }}>✓ Đã nhận{r.sent_at ? ` lúc ${dayjs(r.sent_at).format('HH:mm DD/MM')}` : ''}</span>
                        ) : r.recipient_type === 'external_org' ? (
                          r.lgsp_status === 'success' ? (
                            <span style={{ color: '#52c41a' }}>✓ LGSP đã gửi{r.lgsp_doc_id ? ` (#${r.lgsp_doc_id.slice(0, 12)}...)` : ''}</span>
                          ) : r.lgsp_status === 'error' ? (
                            <span style={{ color: '#ff4d4f' }}>✗ Lỗi: {r.lgsp_error_message || 'unknown'}</span>
                          ) : (
                            <span style={{ color: '#faad14' }}>⏳ Đang chờ worker đẩy LGSP</span>
                          )
                        ) : r.sent_status === 'pending' ? (
                          <span style={{ color: '#faad14' }}>⏳ Chưa gửi</span>
                        ) : (
                          <span>{r.sent_status}</span>
                        )}
                      </div>
                    </div>
                  </Flex>
                ))}
              </div>
            </div>
          )}

          {/* --- Người nhận (legacy v2.0 — staff array) — Phase 19: chỉ hiện khi có data v2.0 --- */}
          {recipients.length > 0 && (
          <div style={{
            background: '#fff', borderRadius: 10, padding: '20px 24px', marginBottom: 16,
            boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
          }}>
            <div className="section-title" style={{ marginBottom: 12 }}><SendOutlined /> Người nhận ({recipients.length})</div>
            {recipients.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '16px 0', color: '#bfbfbf' }}>Chưa gửi cho ai</div>
            ) : (
              <div>
                {recipients.map((r) => (
                  <Flex key={r.id} align="center" gap={10} style={{ padding: '8px 0', borderBottom: '1px solid #f5f5f5' }}>
                    <Badge dot status={r.is_read ? 'success' : 'default'}>
                      <Avatar style={{ background: r.is_read ? '#52c41a' : '#d9d9d9' }} size={32} icon={<UserOutlined />} />
                    </Badge>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 500, fontSize: 13 }}>{r.staff_name}</div>
                      <div style={{ fontSize: 11, color: '#8c8c8c' }}>
                        {r.position_name}{r.department_name ? ` • ${r.department_name}` : ''}
                      </div>
                      <div style={{ fontSize: 11, color: r.is_read ? '#52c41a' : '#faad14' }}>
                        {r.is_read ? `Đã đọc lúc ${dayjs(r.read_at).format('HH:mm DD/MM')}` : 'Chưa đọc'}
                      </div>
                    </div>
                  </Flex>
                ))}
              </div>
            )}
          </div>
          )}

          {/* --- Ý kiến lãnh đạo --- */}
          <div style={{ background: '#fff', borderRadius: 10, padding: '20px 24px', boxShadow: '0 1px 3px rgba(0,0,0,0.06)', marginBottom: 16 }}>
            <div className="section-title" style={{ marginBottom: 12 }}><CommentOutlined /> Ý kiến lãnh đạo ({leaderNotes.length})</div>
            {leaderNotes.map((note) => (
              <div key={note.id} style={{ padding: '8px 12px', background: '#fffbe6', borderRadius: 8, marginBottom: 8, border: '1px solid #ffe58f' }}>
                <Flex justify="space-between" align="start">
                  <div>
                    <div style={{ fontWeight: 600, fontSize: 13, color: '#1B3A5C' }}>{note.staff_name}{note.position_name ? ` — ${note.position_name}` : ''}</div>
                    <div style={{ fontSize: 14, marginTop: 4, color: '#262626' }}>{note.content}</div>
                    <div style={{ fontSize: 11, color: '#8c8c8c', marginTop: 4 }}>{fmtDateTime(note.created_at)}</div>
                  </div>
                  {Number(note.staff_id) === user?.staffId && (
                    <Popconfirm title="Xóa ý kiến?" onConfirm={() => handleDeleteNote(note.id)}>
                      <Button size="small" type="text" danger icon={<DeleteOutlined />} />
                    </Popconfirm>
                  )}
                </Flex>
              </div>
            ))}
            <div style={{ marginTop: leaderNotes.length > 0 ? 8 : 0 }}>
              <Input.TextArea rows={2} placeholder="Nhập ý kiến..." value={noteContent} onChange={(e) => setNoteContent(e.target.value)} style={{ borderRadius: 8 }} />
              <Button type="primary" size="small" style={{ marginTop: 8 }} loading={addingNote} onClick={handleAddNote} disabled={!noteContent.trim()}>Gửi ý kiến</Button>
            </div>
          </div>

          {/* --- Lịch sử xử lý --- */}
          <div style={{
            background: '#fff', borderRadius: 10, padding: '20px 24px',
            boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
          }}>
            <div className="section-title" style={{ marginBottom: 16 }}><ClockCircleOutlined /> Lịch sử xử lý</div>
            {history.length === 0 ? (
              <div style={{ textAlign: 'center', padding: '16px 0', color: '#bfbfbf' }}>Chưa có lịch sử</div>
            ) : (
              <Timeline items={history.map((h) => ({
                color: h.event_type === 'created' ? 'blue' : h.event_type === 'approved' ? 'green' : h.event_type === 'sent' ? 'cyan' : h.event_type === 'leader_note' ? 'orange' : 'gray',
                content: (
                  <div style={{ paddingBottom: 4 }}>
                    <div style={{ fontSize: 13, color: '#262626' }}>{h.content}</div>
                    <div style={{ fontSize: 11, color: '#8c8c8c' }}>{h.staff_name} • {fmtDateTime(h.event_time)}</div>
                  </div>
                ),
              }))} />
            )}
          </div>
        </Col>
      </Row>

      {/* ====== MODAL GỬI ====== */}
      <Modal title="Gửi văn bản" open={sendModalOpen} onCancel={() => setSendModalOpen(false)} onOk={handleSend} okText={`Gửi (${selectedStaffIds.length})`} cancelText="Hủy" confirmLoading={sending} width={560}>
        <div style={{ marginBottom: 12 }}>
          <Checkbox checked={selectedStaffIds.length === sendableStaff.length && sendableStaff.length > 0} indeterminate={selectedStaffIds.length > 0 && selectedStaffIds.length < sendableStaff.length} onChange={(e) => setSelectedStaffIds(e.target.checked ? sendableStaff.map(s => s.staff_id) : [])}>Chọn tất cả</Checkbox>
        </div>
        <div style={{ maxHeight: 400, overflowY: 'auto' }}>
          {Object.entries(sendableStaff.reduce<Record<string, SendableStaff[]>>((acc, s) => { const d = s.department_name || 'Khác'; if (!acc[d]) acc[d] = []; acc[d].push(s); return acc; }, {})).map(([dept, staff]) => (
            <div key={dept} style={{ marginBottom: 12 }}>
              <Text strong style={{ fontSize: 13, color: '#1B3A5C' }}>{dept}</Text>
              <div style={{ paddingLeft: 8, marginTop: 4 }}>
                {staff.map((s) => (
                  <div key={s.staff_id} style={{ padding: '2px 0' }}>
                    <Checkbox checked={selectedStaffIds.includes(s.staff_id)} onChange={(e) => setSelectedStaffIds(prev => e.target.checked ? [...prev, s.staff_id] : prev.filter(id => id !== s.staff_id))}>
                      {s.full_name} {s.position_name ? <Text type="secondary">({s.position_name})</Text> : ''}
                    </Checkbox>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </Modal>

      {/* Drawer: Giao việc */}
      <Drawer
        title="Giao việc" size={600} open={giaoViecOpen} forceRender
        onClose={() => { setGiaoViecOpen(false); giaoViecForm.resetFields(); }}
        rootClassName="drawer-gradient"
        extra={<Space><Button onClick={() => setGiaoViecOpen(false)} ghost style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}>Hủy</Button><Button type="primary" loading={giaoViecSaving} onClick={handleGiaoViec}>Tạo và giao việc</Button></Space>}
      >
        <Form form={giaoViecForm} layout="vertical" validateTrigger="onSubmit" autoComplete="off">
          <Form.Item name="name" label="Tên hồ sơ công việc" rules={[{ required: true, message: 'Bắt buộc' }]}><Input maxLength={500} /></Form.Item>
          <Row gutter={16}>
            <Col span={12}><Form.Item name="start_date" label="Ngày bắt đầu"><DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" /></Form.Item></Col>
            <Col span={12}><Form.Item name="end_date" label="Hạn hoàn thành"><DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" /></Form.Item></Col>
          </Row>
          <Form.Item name="curator_ids" label="Người phụ trách"><Select mode="multiple" placeholder="Chọn người phụ trách..." options={staffOptions} filterOption={(input, opt) => (opt?.label ?? '').toLowerCase().includes(input.toLowerCase())} /></Form.Item>
          <Form.Item name="note" label="Ghi chú"><Input.TextArea rows={3} maxLength={500} showCount /></Form.Item>
        </Form>
      </Drawer>

      {/* Modal: Thêm vào HSCV */}
      <Modal title="Thêm vào hồ sơ công việc" open={hscvModalOpen} onCancel={() => setHscvModalOpen(false)} onOk={handleLinkHscv} confirmLoading={hscvSaving} okText="Thêm vào HSCV" cancelText="Hủy">
        <Select style={{ width: '100%', marginTop: 8 }} placeholder="Chọn hồ sơ công việc..." showSearch filterOption={(input, opt) => (opt?.label ?? '').toLowerCase().includes(input.toLowerCase())} value={selectedHscvId} onChange={setSelectedHscvId} options={hscvList.map(h => ({ value: h.id, label: `${h.name} (${h.status === 0 ? 'Mới' : h.status === 1 ? 'Đang xử lý' : 'Trình duyệt'})` }))} />
      </Modal>

      {/* Modal: Gửi liên thông */}
      <Modal title="Gửi liên thông LGSP" open={lgspModalOpen} onCancel={() => setLgspModalOpen(false)} onOk={handleSendLgsp} confirmLoading={lgspSending} okText="Gửi liên thông" cancelText="Hủy">
        <Select mode="multiple" style={{ width: '100%', marginTop: 8 }} placeholder="Chọn đơn vị nhận..." showSearch filterOption={(input, opt) => (opt?.label ?? '').toLowerCase().includes(input.toLowerCase())} value={selectedLgspOrgs} onChange={setSelectedLgspOrgs} options={lgspOrgs.map(o => ({ value: o.id, label: `${o.org_name} (${o.org_code})` }))} />
      </Modal>

      {/* Drawer: Chuyển lưu trữ VB đi (HDSD II.3.9) */}
      <Drawer
        title="Chuyển lưu trữ" open={archiveOpen} onClose={() => setArchiveOpen(false)}
        size={640} rootClassName="drawer-gradient" forceRender
        extra={<Space><Button onClick={() => setArchiveOpen(false)}>Hủy</Button><Button type="primary" onClick={handleArchive} loading={archiving}>Chuyển lưu trữ</Button></Space>}
      >
        <Form form={archiveForm} layout="vertical">
          <Row gutter={16}>
            <Col span={12}><Form.Item name="warehouse_id" label="Kho lưu trữ" rules={[{ required: true, message: 'Vui lòng chọn kho lưu trữ' }]}><Select placeholder="Chọn kho..." allowClear options={warehouseOptions} /></Form.Item></Col>
            <Col span={12}><Form.Item name="fond_id" label="Phông lưu trữ" rules={[{ required: true, message: 'Vui lòng chọn phông lưu trữ' }]}><Select placeholder="Chọn phông..." allowClear options={fondOptions} /></Form.Item></Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}><Form.Item name="file_catalog" label="Mục lục hồ sơ"><Input maxLength={200} /></Form.Item></Col>
            <Col span={12}><Form.Item name="file_notation" label="Ký hiệu hồ sơ"><Input maxLength={100} /></Form.Item></Col>
          </Row>
          <Row gutter={16}>
            <Col span={8}><Form.Item name="doc_ordinal" label="Thứ tự VB"><InputNumber style={{ width: '100%' }} min={1} /></Form.Item></Col>
            <Col span={8}><Form.Item name="language" label="Ngôn ngữ"><Input maxLength={50} /></Form.Item></Col>
            <Col span={8}><Form.Item name="format" label="Định dạng"><Select options={[{ value: 'Điện tử', label: 'Điện tử' }, { value: 'Giấy', label: 'Giấy' }, { value: 'Cả hai', label: 'Cả hai' }]} /></Form.Item></Col>
          </Row>
          <Form.Item name="autograph" label="Bút tích"><Input.TextArea rows={2} maxLength={500} showCount /></Form.Item>
          <Form.Item name="keyword" label="Từ khóa"><Input maxLength={500} /></Form.Item>
          <Row gutter={16}>
            <Col span={12}><Form.Item name="confidence_level" label="Mức độ tin cậy"><Input maxLength={50} /></Form.Item></Col>
            <Col span={12}><Form.Item name="is_original" label="Bản gốc" valuePropName="checked"><Checkbox>Là bản gốc</Checkbox></Form.Item></Col>
          </Row>
        </Form>
      </Drawer>

      {/* Modal: Gửi trục CP (HDSD II.3.8) */}
      <Modal
        open={cpModalOpen}
        title="Gửi trục Chính phủ"
        okText="Gửi"
        cancelText="Hủy"
        confirmLoading={cpSending}
        onCancel={() => setCpModalOpen(false)}
        onOk={handleSendCp}
        width={500}
      >
        <p style={{ marginBottom: 12 }}>Chọn các bộ/ngành Chính phủ để gửi văn bản:</p>
        <Checkbox.Group
          value={cpSelected}
          onChange={(vals) => setCpSelected(vals as string[])}
          style={{ display: 'flex', flexDirection: 'column', gap: 8 }}
        >
          {CP_ORGANIZATIONS.map(org => (
            <Checkbox key={org.code} value={org.code}>{org.name}</Checkbox>
          ))}
        </Checkbox.Group>
      </Modal>

      {/* Sign modal từ useSigning hook (Plan 11-06) — replace mock OTP với real async flow */}
      {renderSignModal()}

      {/* Phase 17 v3.0: Modal Gửi nội bộ — chọn đơn vị nhận, auto-sinh incoming_docs */}
      <Modal
        title={noiBoMode === 'release-and-send' ? 'Ban hành & Gửi — chọn đơn vị nhận' : 'Gửi nội bộ — chọn đơn vị nhận'}
        open={noiBoModalOpen}
        onCancel={() => setNoiBoModalOpen(false)}
        onOk={handleSendNoiBo}
        confirmLoading={noiBoSending}
        okText={noiBoMode === 'release-and-send' ? `Ban hành & Gửi (${selectedDeptIds.length})` : `Gửi (${selectedDeptIds.length} đơn vị)`}
        cancelText="Hủy"
        width={600}
      >
        <div style={{ marginBottom: 12, color: '#595959' }}>
          Văn bản này chưa chọn đơn vị nhận chính thức. Vui lòng chọn bên dưới để {noiBoMode === 'release-and-send' ? 'ban hành và gửi' : 'gửi'}. Hệ thống sẽ tự sinh &ldquo;Văn bản đến&rdquo; cho mỗi đơn vị.
        </div>
        <Checkbox.Group
          value={selectedDeptIds}
          onChange={(vals) => setSelectedDeptIds(vals as number[])}
          style={{ display: 'flex', flexDirection: 'column', gap: 8, maxHeight: 400, overflowY: 'auto' }}
        >
          {deptOptions.map((opt) => (
            <Checkbox key={opt.value} value={opt.value}>{opt.label}</Checkbox>
          ))}
        </Checkbox.Group>
      </Modal>
    </div>
  );
}
