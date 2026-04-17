'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Tag, Button, Space, Row, Col, Timeline, Avatar,
  Upload, Modal, Input, Popconfirm, Checkbox, Empty, Spin, App,
  Badge, Typography, Flex, Dropdown, Drawer, Form, DatePicker, Select, InputNumber,
} from 'antd';
import {
  ArrowLeftOutlined, CheckCircleOutlined, CloseCircleOutlined, SendOutlined,
  DeleteOutlined, DownloadOutlined, UploadOutlined, MoreOutlined,
  StarOutlined, StarFilled, CommentOutlined, PaperClipOutlined,
  InboxOutlined, ClockCircleOutlined, UserOutlined, FilePdfOutlined,
  FileImageOutlined, FileWordOutlined, FileExcelOutlined, FileOutlined,
  EditOutlined, SafetyCertificateOutlined, ThunderboltOutlined,
  RollbackOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import { useParams, useRouter } from 'next/navigation';
import dayjs from 'dayjs';

const { TextArea } = Input;
const { Text } = Typography;

interface DocDetail {
  id: number; unit_id: number; received_date: string; number: number;
  notation: string; document_code: string; abstract: string;
  publish_unit: string; publish_date: string; signer: string; sign_date: string;
  doc_book_id: number; doc_type_id: number; doc_field_id: number;
  secret_id: number; urgent_id: number; number_paper: number; number_copies: number;
  expired_date: string; recipients: string; approver: string; approved: boolean;
  is_handling: boolean; is_received_paper: boolean; archive_status: boolean;
  created_by: number; created_at: string; updated_by: number; updated_at: string;
  doc_book_name: string; doc_type_name: string; doc_type_code: string;
  doc_field_name: string; created_by_name: string; is_read: boolean;
}
interface Attachment { id: number; file_name: string; file_path: string; file_size: number; content_type: string; created_by_name: string; created_at: string; is_ca?: boolean; ca_date?: string; }
interface Recipient { id: number; staff_id: number; staff_name: string; position_name: string; department_name: string; is_read: boolean; read_at: string; created_at: string; }
interface HistoryEvent { event_type: string; event_time: string; staff_name: string; content: string; }
interface LeaderNote { id: number; staff_id: number; staff_name: string; position_name: string; content: string; created_at: string; }
interface SendableStaff { staff_id: number; full_name: string; position_name: string; department_id: number; department_name: string; }

const SECRET_TAGS: Record<number, { text: string; color: string }> = {
  1: { text: 'Thường', color: 'default' }, 2: { text: 'Mật', color: 'orange' },
  3: { text: 'Tối mật', color: 'red' }, 4: { text: 'Tuyệt mật', color: 'volcano' },
};
const URGENT_TAGS: Record<number, { text: string; color: string }> = {
  1: { text: 'Thường', color: 'default' }, 2: { text: 'Khẩn', color: 'orange' }, 3: { text: 'Hỏa tốc', color: 'red' },
};

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

// ====== Styles — use CSS classes from globals.css for layout ======
// sectionTitle → className="section-title"
// fieldLabel → className="info-label"
// fieldValue → className="info-value"
// infoRow → className="info-grid"
// infoRowFull → className="info-grid-full"

export default function IncomingDocDetailPage() {
  const { message, modal } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const params = useParams();
  const router = useRouter();
  const docId = Number(params.id);

  const [loading, setLoading] = useState(true);
  const [doc, setDoc] = useState<DocDetail | null>(null);
  const [attachments, setAttachments] = useState<Attachment[]>([]);
  const [recipients, setRecipients] = useState<Recipient[]>([]);
  const [history, setHistory] = useState<HistoryEvent[]>([]);
  const [leaderNotes, setLeaderNotes] = useState<LeaderNote[]>([]);
  const [isBookmarked, setIsBookmarked] = useState(false);
  const [sendModalOpen, setSendModalOpen] = useState(false);
  const [sendableStaff, setSendableStaff] = useState<SendableStaff[]>([]);
  const [selectedStaffIds, setSelectedStaffIds] = useState<number[]>([]);
  const [sending, setSending] = useState(false);
  const [noteContent, setNoteContent] = useState('');
  const [addingNote, setAddingNote] = useState(false);
  const [assignMode, setAssignMode] = useState(false);
  const [assignStaffIds, setAssignStaffIds] = useState<number[]>([]);
  const [assignExpiredDate, setAssignExpiredDate] = useState<dayjs.Dayjs | null>(null);
  const [presetStaff, setPresetStaff] = useState<number[]>([]);
  const [uploading, setUploading] = useState(false);

  // Giao việc drawer
  const [giaoViecOpen, setGiaoViecOpen] = useState(false);
  const [giaoViecSaving, setGiaoViecSaving] = useState(false);
  const [giaoViecForm] = Form.useForm();
  const [staffOptions, setStaffOptions] = useState<{ value: number; label: string }[]>([]);

  // Chuyển lại modal
  const [chuyenLaiOpen, setChuyenLaiOpen] = useState(false);
  const [chuyenLaiSaving, setChuyenLaiSaving] = useState(false);
  const [chuyenLaiForm] = Form.useForm();

  // Thêm vào HSCV modal
  const [hscvModalOpen, setHscvModalOpen] = useState(false);
  const [hscvList, setHscvList] = useState<{ id: number; name: string; status: number }[]>([]);
  const [selectedHscvId, setSelectedHscvId] = useState<number | null>(null);
  const [hscvSaving, setHscvSaving] = useState(false);

  // Gửi liên thông modal
  const [lgspModalOpen, setLgspModalOpen] = useState(false);
  const [lgspOrgs, setLgspOrgs] = useState<{ id: number; org_code: string; org_name: string }[]>([]);
  const [selectedLgspOrgs, setSelectedLgspOrgs] = useState<number[]>([]);
  const [lgspSending, setLgspSending] = useState(false);

  // Lưu trữ modal
  const [archiveModalOpen, setArchiveModalOpen] = useState(false);
  const [archiveSaving, setArchiveSaving] = useState(false);
  const [archiveForm] = Form.useForm();
  const [fondOptions, setFondOptions] = useState<{ value: number; label: string }[]>([]);
  const [warehouseOptions, setWarehouseOptions] = useState<{ value: number; label: string }[]>([]);

  // Action loading
  const [actionLoading, setActionLoading] = useState(false);

  const fetchDoc = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}`); setDoc(res.data); } catch { message.error('Không tìm thấy văn bản'); router.push('/van-ban-den'); } }, [docId, message, router]);
  const fetchBookmarkStatus = useCallback(async () => { try { const { data: res } = await api.get('/van-ban-den/danh-dau-ca-nhan'); const bookmarks: { doc_id: number | string }[] = res.data || []; setIsBookmarked(bookmarks.some((b) => Number(b.doc_id) === Number(docId))); } catch {} }, [docId]);

  const fetchStaffOptions = useCallback(async () => {
    try {
      const { data: res } = await api.get('/quan-tri/nguoi-dung', { params: { page: 1, pageSize: 200 } });
      setStaffOptions((res.data || []).map((s: { id: number; full_name: string; position_name?: string }) => ({
        value: s.id,
        label: s.full_name + (s.position_name ? ` (${s.position_name})` : ''),
      })));
    } catch { /* ignore */ }
  }, []);
  const fetchAttachments = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/dinh-kem`); setAttachments(res.data || []); } catch {} }, [docId]);
  const fetchRecipients = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/nguoi-nhan`); setRecipients(res.data || []); } catch {} }, [docId]);
  const fetchHistory = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/lich-su`); setHistory(res.data || []); } catch {} }, [docId]);
  const fetchLeaderNotes = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/but-phe`); setLeaderNotes(res.data || []); } catch {} }, [docId]);

  useEffect(() => {
    setLoading(true);
    Promise.all([fetchDoc(), fetchAttachments(), fetchRecipients(), fetchHistory(), fetchLeaderNotes(), fetchBookmarkStatus(), fetchStaffOptions()]).finally(() => setLoading(false));
  }, [fetchDoc, fetchAttachments, fetchRecipients, fetchHistory, fetchLeaderNotes, fetchBookmarkStatus, fetchStaffOptions]);

  // Actions
  const handleApprove = async () => { try { await api.patch(`/van-ban-den/${docId}/duyet`); message.success('Duyệt thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleUnapprove = async () => { try { await api.patch(`/van-ban-den/${docId}/huy-duyet`); message.success('Hủy duyệt thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleRetract = () => { modal.confirm({ title: 'Thu hồi văn bản đến', content: 'Thu hồi sẽ xóa tất cả người nhận và đặt lại trạng thái chưa duyệt. Bạn chắc chắn?', okText: 'Thu hồi', okButtonProps: { danger: true }, cancelText: 'Hủy', onOk: async () => { try { await api.post(`/van-ban-den/${docId}/thu-hoi`); message.success('Thu hồi thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } } }); };

  const openGiaoViec = () => {
    giaoViecForm.resetFields();
    if (doc) {
      giaoViecForm.setFieldsValue({
        name: doc.abstract,
        end_date: doc.expired_date ? dayjs(doc.expired_date) : undefined,
      });
    }
    fetchStaffOptions();
    setGiaoViecOpen(true);
  };

  const handleGiaoViec = async () => {
    try {
      const values = await giaoViecForm.validateFields();
      setGiaoViecSaving(true);
      const payload = {
        name: values.name,
        start_date: dayjs().toISOString(),
        end_date: values.end_date?.toISOString() || null,
        curator_ids: values.curator_ids || [],
        note: values.note || '',
      };
      await api.post(`/van-ban-den/${docId}/giao-viec`, payload);
      message.success('Giao việc thành công');
      setGiaoViecOpen(false);
      giaoViecForm.resetFields();
    } catch (e: any) {
      if (e?.response?.data?.message) message.error(e.response.data.message);
    } finally {
      setGiaoViecSaving(false);
    }
  };

  const handleNhanBanGiao = async () => {
    setActionLoading(true);
    try {
      await api.post(`/van-ban-den/${docId}/nhan-ban-giao`, {});
      message.success('Nhận bàn giao thành công');
      fetchDoc();
      fetchHistory();
    } catch (e: any) {
      message.error(e?.response?.data?.message || 'Thao tác thất bại');
    } finally {
      setActionLoading(false);
    }
  };

  const handleChuyenLai = async () => {
    try {
      const values = await chuyenLaiForm.validateFields();
      setChuyenLaiSaving(true);
      await api.post(`/van-ban-den/${docId}/chuyen-lai`, { reason: values.reason });
      message.success('Chuyển lại văn bản thành công');
      setChuyenLaiOpen(false);
      chuyenLaiForm.resetFields();
      fetchDoc();
      fetchHistory();
    } catch (e: any) {
      if (e?.response?.data?.message) message.error(e.response.data.message);
    } finally {
      setChuyenLaiSaving(false);
    }
  };

  const handleHuyDuyet = async () => {
    setActionLoading(true);
    try {
      await api.patch(`/van-ban-den/${docId}/huy-duyet`);
      message.success('Đã hủy duyệt văn bản');
      fetchDoc();
      fetchHistory();
    } catch (e: any) {
      message.error(e?.response?.data?.message || 'Thao tác thất bại');
    } finally {
      setActionLoading(false);
    }
  };
  const handleDelete = () => { modal.confirm({ title: 'Xác nhận xóa', content: 'Xóa văn bản này?', okText: 'Xóa', okType: 'danger', cancelText: 'Hủy', onOk: async () => { try { await api.delete(`/van-ban-den/${docId}`); message.success('Đã xóa'); router.push('/van-ban-den'); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } } }); };
  const handleReceivePaper = async () => { try { await api.patch(`/van-ban-den/${docId}/nhan-ban-giay`); message.success('Đã xác nhận nhận bản giấy'); fetchDoc(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleToggleBookmark = async () => { try { const { data: res } = await api.post(`/van-ban-den/${docId}/danh-dau`, {}); setIsBookmarked(res.data?.is_bookmarked); message.success(res.data?.message); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };

  // Thêm vào HSCV sẵn có
  const openHscvModal = async () => {
    try {
      const { data: res } = await api.get(`/van-ban-den/${docId}/danh-sach-hscv`);
      setHscvList(res.data || []);
      setSelectedHscvId(null);
      setHscvModalOpen(true);
    } catch { message.error('Lỗi tải danh sách HSCV'); }
  };
  const handleLinkHscv = async () => {
    if (!selectedHscvId) { message.warning('Vui lòng chọn hồ sơ công việc'); return; }
    setHscvSaving(true);
    try {
      const { data: res } = await api.post(`/van-ban-den/${docId}/them-vao-hscv`, { handling_doc_id: selectedHscvId });
      if (res.success) { message.success('Đã thêm vào hồ sơ công việc'); setHscvModalOpen(false); }
      else message.error(res.message);
    } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setHscvSaving(false); }
  };

  // Gửi liên thông LGSP
  const openLgspModal = async () => {
    try {
      const { data: res } = await api.get(`/van-ban-den/${docId}/lgsp/don-vi`);
      setLgspOrgs(res.data || []);
      setSelectedLgspOrgs([]);
      setLgspModalOpen(true);
    } catch { message.error('Lỗi tải danh sách đơn vị liên thông'); }
  };
  const handleSendLgsp = async () => {
    if (selectedLgspOrgs.length === 0) { message.warning('Vui lòng chọn ít nhất một đơn vị'); return; }
    setLgspSending(true);
    try {
      const orgCodes = selectedLgspOrgs.map(id => {
        const org = lgspOrgs.find(o => o.id === id);
        return { code: org?.org_code, name: org?.org_name };
      });
      const { data: res } = await api.post(`/van-ban-den/${docId}/gui-lien-thong`, { org_codes: orgCodes });
      message.success(res.data?.message || 'Đã gửi liên thông');
      setLgspModalOpen(false);
    } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi gửi liên thông'); }
    finally { setLgspSending(false); }
  };

  // Chuyển lưu trữ
  const openArchiveModal = async () => {
    try {
      const [fondRes, whRes] = await Promise.all([
        api.get(`/van-ban-den/${docId}/luu-tru/phong`),
        api.get(`/van-ban-den/${docId}/luu-tru/kho`),
      ]);
      setFondOptions((fondRes.data.data || []).map((f: { id: number; name: string }) => ({ value: f.id, label: f.name })));
      setWarehouseOptions((whRes.data.data || []).map((w: { id: number; name: string }) => ({ value: w.id, label: w.name })));
      archiveForm.resetFields();
      archiveForm.setFieldsValue({ language: 'Tiếng Việt', format: 'Điện tử', is_original: true });
      setArchiveModalOpen(true);
    } catch { message.error('Lỗi tải dữ liệu lưu trữ'); }
  };
  const handleArchive = async () => {
    try {
      const values = await archiveForm.validateFields();
      setArchiveSaving(true);
      const { data: res } = await api.post(`/van-ban-den/${docId}/chuyen-luu-tru`, values);
      if (res.success) { message.success('Chuyển lưu trữ thành công'); setArchiveModalOpen(false); fetchDoc(); }
      else message.error(res.message);
    } catch (e: any) { if (e?.response?.data?.message) message.error(e.response.data.message); }
    finally { setArchiveSaving(false); }
  };

  // Attachments
  const handleUpload = async (file: File) => { setUploading(true); try { const fd = new FormData(); fd.append('file', file); await api.post(`/van-ban-den/${docId}/dinh-kem`, fd, { headers: { 'Content-Type': 'multipart/form-data' } }); message.success('Tải lên thành công'); fetchAttachments(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } finally { setUploading(false); } return false; };
  const handleDownload = async (att: Attachment) => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/dinh-kem/${att.id}/download`); window.open(res.data?.url, '_blank'); } catch { message.error('Lỗi tải file'); } };
  const handleDeleteAttachment = async (att: Attachment) => { try { await api.delete(`/van-ban-den/${docId}/dinh-kem/${att.id}`); message.success('Đã xóa'); fetchAttachments(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleSignAttachment = async (att: Attachment) => {
    try {
      const { data: res } = await api.post('/ky-so/mock/sign', { attachment_id: att.id, attachment_type: 'incoming' });
      message.success(res.message || 'Ký số thành công'); fetchAttachments();
    } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi ký số'); }
  };
  const handleVerifyAttachment = async (att: Attachment) => {
    try {
      const { data: res } = await api.post('/ky-so/mock/verify', { attachment_id: att.id, attachment_type: 'incoming' });
      const d = res.data;
      if (d?.is_valid) modal.success({ title: 'Chữ ký hợp lệ', content: `${d.signer_name} • ${d.sign_date ? dayjs(d.sign_date).format('DD/MM/YYYY HH:mm') : ''}` });
      else modal.warning({ title: 'Chưa ký số', content: d?.message || 'File chưa được ký số' });
    } catch { message.error('Lỗi xác thực'); }
  };

  // Send
  const openSendModal = async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/danh-sach-gui`); setSendableStaff(res.data || []); setSelectedStaffIds([]); setSendModalOpen(true); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleSend = async () => {
    if (selectedStaffIds.length === 0) { message.warning('Chọn ít nhất một người nhận'); return; }
    setSending(true);
    try { const { data: res } = await api.post(`/van-ban-den/${docId}/gui`, { staff_ids: selectedStaffIds }); message.success(res.data?.message || 'Đã gửi'); setSendModalOpen(false); fetchRecipients(); fetchHistory(); }
    catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setSending(false); }
  };

  // Leader Notes — load preset khi bật phân công
  const loadPresetStaff = async () => {
    try {
      const { data: res } = await api.get('/cau-hinh-gui-nhanh', { params: { config_type: 'doc' } });
      const ids = (res.data || []).map((r: { target_user_id: number }) => r.target_user_id);
      setPresetStaff(ids);
      setAssignStaffIds(ids);
    } catch {}
  };
  const handleAddNote = async () => {
    if (!noteContent.trim()) { message.warning('Nhập nội dung bút phê'); return; }
    if (assignMode && assignStaffIds.length === 0) { message.warning('Vui lòng chọn cán bộ phân công'); return; }
    setAddingNote(true);
    try {
      const payload: Record<string, unknown> = { content: noteContent.trim() };
      if (assignMode && assignStaffIds.length > 0) {
        payload.staff_ids = assignStaffIds;
        if (assignExpiredDate) payload.expired_date = assignExpiredDate.toISOString();
      }
      const { data: res } = await api.post(`/van-ban-den/${docId}/but-phe`, payload);
      message.success(res.data?.message || 'Thêm bút phê thành công');
      setNoteContent(''); setAssignMode(false); setAssignStaffIds([]); setAssignExpiredDate(null);
      fetchLeaderNotes(); fetchHistory();
    }
    catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setAddingNote(false); }
  };
  const handleDeleteNote = async (noteId: number) => { try { await api.delete(`/van-ban-den/${docId}/but-phe/${noteId}`); message.success('Đã xóa'); fetchLeaderNotes(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };

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
          <Button icon={<ArrowLeftOutlined />} onClick={() => router.push('/van-ban-den')} />
          <div>
            <div style={{ fontSize: 16, fontWeight: 700, color: '#1B3A5C' }}>
              Số đến: {doc.number} — {doc.notation || 'Không có ký hiệu'}
            </div>
            <div style={{ fontSize: 13, color: '#8c8c8c' }}>
              {doc.publish_unit} • Ngày đến: {fmtDate(doc.received_date)}
            </div>
          </div>
          {doc.approved
            ? <Tag color="success" icon={<SafetyCertificateOutlined />}>Đã duyệt</Tag>
            : (doc as any).rejected_by
              ? <Tag color="error">Từ chối</Tag>
              : <Tag color="warning">Chờ duyệt</Tag>
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

          {/* Giao việc — always visible */}
          <Button
            type="primary"
            icon={<ThunderboltOutlined />}
            style={{ backgroundColor: '#0891B2', borderColor: '#0891B2' }}
            onClick={openGiaoViec}
          >
            Giao việc
          </Button>

          {/* Thêm vào HSCV sẵn có */}
          <Button onClick={openHscvModal} icon={<InboxOutlined />}>Thêm vào HSCV</Button>

          {/* Gửi liên thông LGSP — chỉ khi đã duyệt */}
          {doc.approved && (
            <Button onClick={openLgspModal} icon={<SendOutlined />} style={{ backgroundColor: '#059669', borderColor: '#059669', color: '#fff' }}>Gửi liên thông</Button>
          )}

          {/* Chuyển lưu trữ — chỉ khi đã duyệt và chưa lưu trữ */}
          {doc.approved && !doc.archive_status && (
            <Button onClick={openArchiveModal} icon={<InboxOutlined />} style={{ backgroundColor: '#7c3aed', borderColor: '#7c3aed', color: '#fff' }}>Chuyển lưu trữ</Button>
          )}
          {doc.archive_status && <Tag color="purple">Đã lưu trữ</Tag>}

          {/* Nhận bàn giao / Chuyển lại — chỉ VB liên thông */}
          {doc.is_inter_doc && (
            <>
              <Popconfirm
                title="Nhận bàn giao văn bản?"
                description="Bạn có chắc chắn nhận bàn giao văn bản này?"
                okText="Xác nhận"
                cancelText="Hủy"
                onConfirm={handleNhanBanGiao}
                disabled={actionLoading}
              >
                <Button
                  icon={<CheckCircleOutlined />}
                  loading={actionLoading}
                  style={{ color: '#059669', borderColor: '#059669' }}
                >
                  Nhận bàn giao
                </Button>
              </Popconfirm>
              <Button
                icon={<RollbackOutlined />}
                onClick={() => { chuyenLaiForm.resetFields(); setChuyenLaiOpen(true); }}
              >
                Chuyển lại
              </Button>
            </>
          )}

          {/* Chưa duyệt: Sửa, Duyệt, Xóa */}
          {!doc.approved && (
            <>
              <Button icon={<EditOutlined />} onClick={() => router.push(`/van-ban-den?edit=${doc.id}`)}>Sửa</Button>
              <Button type="primary" icon={<CheckCircleOutlined />} onClick={handleApprove}>Duyệt</Button>
              <Dropdown menu={{ items: [
                ...(recipients.length > 0 ? [{ key: 'retract', icon: <RollbackOutlined />, label: 'Thu hồi', onClick: handleRetract }] : []),
                { type: 'divider' as const },
                { key: 'delete', icon: <DeleteOutlined />, label: 'Xóa văn bản', danger: true, onClick: handleDelete },
              ] }}>
                <Button icon={<MoreOutlined />} />
              </Dropdown>
            </>
          )}

          {/* Đã duyệt: Gửi, Bút phê, Hủy duyệt, Thu hồi */}
          {doc.approved && (
            <>
              <Button type="primary" icon={<SendOutlined />} onClick={openSendModal}>Gửi</Button>
              <Button icon={<CommentOutlined />} onClick={() => document.getElementById('note-input')?.focus()}>Bút phê</Button>
              <Dropdown menu={{ items: [
                ...(!doc.is_received_paper ? [{ key: 'paper', icon: <InboxOutlined />, label: 'Nhận bản giấy', onClick: handleReceivePaper }] : []),
                { key: 'unapprove', icon: <CloseCircleOutlined />, label: 'Hủy duyệt', danger: true, onClick: handleHuyDuyet },
                { key: 'retract', icon: <RollbackOutlined />, label: 'Thu hồi', onClick: handleRetract },
              ] }}>
                <Button icon={<MoreOutlined />} />
              </Dropdown>
            </>
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
                <div><div className="info-label">Số đến</div><div className="info-value">{doc.number}</div></div>
                <div><div className="info-label">Ngày đến</div><div className="info-value">{fmtDate(doc.received_date)}</div></div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Số ký hiệu</div><div className="info-value" style={{ color: '#0891B2' }}>{doc.notation || '—'}</div></div>
                <div><div className="info-label">Sổ văn bản</div><div className="info-value">{doc.doc_book_name || '—'}</div></div>
              </div>
              <div className="info-grid-full">
                <div className="info-label">Cơ quan ban hành</div>
                <div className="info-value">{doc.publish_unit || '—'}</div>
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
                <div><div className="info-label">Nơi nhận</div><div className="info-value">{doc.recipients || '—'}</div></div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Độ mật</div><Tag color={secretTag.color}>{secretTag.text}</Tag></div>
                <div><div className="info-label">Độ khẩn</div><Tag color={urgentTag.color}>{urgentTag.text}</Tag></div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Số tờ / Số bản</div><div className="info-value">{doc.number_paper} tờ / {doc.number_copies} bản</div></div>
                <div><div className="info-label">Bản giấy</div>{doc.is_received_paper ? <Tag color="success">Đã nhận</Tag> : <Tag>Chưa nhận</Tag>}</div>
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
                        <Text type="secondary" style={{ fontSize: 11 }}>
                          {formatSize(att.file_size)} • {fmtDateTime(att.created_at)}
                          {att.is_ca && <Tag color="green" style={{ marginLeft: 6, fontSize: 10 }}>Đã ký số {att.ca_date ? dayjs(att.ca_date).format('DD/MM/YYYY') : ''}</Tag>}
                        </Text>
                      </div>
                    </Flex>
                    <Space size={4}>
                      <Button size="small" type="link" icon={<DownloadOutlined />} onClick={() => handleDownload(att)} />
                      {!att.is_ca && <Button size="small" type="link" style={{ color: '#059669' }} onClick={() => handleSignAttachment(att)}>Ký số</Button>}
                      {att.is_ca && <Button size="small" type="link" onClick={() => handleVerifyAttachment(att)}>Xác thực</Button>}
                      {!doc.approved && <Popconfirm title="Xóa file?" onConfirm={() => handleDeleteAttachment(att)}><Button size="small" type="link" danger icon={<DeleteOutlined />} /></Popconfirm>}
                    </Space>
                  </Flex>
                ))}
              </div>
            )}
          </div>

          {/* --- Bút phê lãnh đạo --- */}
          <div style={{
            background: '#fff', borderRadius: 10, padding: '20px 24px', marginBottom: 16,
            boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
          }}>
            <div className="section-title" style={{ marginBottom: 12 }}><CommentOutlined /> Ý kiến bút phê ({leaderNotes.length})</div>

            {leaderNotes.map((note) => (
              <div key={note.id} style={{ padding: '12px 16px', background: '#f6ffed', borderRadius: 8, marginBottom: 8, borderLeft: '3px solid #52c41a' }}>
                <Flex justify="space-between" align="flex-start">
                  <Flex gap={10}>
                    <Avatar style={{ background: '#0891B2' }} size="small" icon={<UserOutlined />} />
                    <div>
                      <div style={{ fontWeight: 600, fontSize: 13, color: '#1B3A5C' }}>
                        {note.staff_name}{note.position_name ? ` — ${note.position_name}` : ''}
                      </div>
                      <div style={{ fontSize: 14, marginTop: 4, color: '#262626', lineHeight: 1.5 }}>{note.content}</div>
                      <div style={{ fontSize: 11, color: '#8c8c8c', marginTop: 4 }}>{fmtDateTime(note.created_at)}</div>
                    </div>
                  </Flex>
                  {Number(note.staff_id) === user?.staffId && (
                    <Popconfirm title="Xóa bút phê?" onConfirm={() => handleDeleteNote(note.id)}>
                      <Button size="small" type="text" danger icon={<DeleteOutlined />} />
                    </Popconfirm>
                  )}
                </Flex>
              </div>
            ))}

            {doc.approved && (
              <div style={{ marginTop: leaderNotes.length > 0 ? 12 : 0 }}>
                <TextArea id="note-input" rows={2} placeholder="Nhập nội dung bút phê..." value={noteContent} onChange={(e) => setNoteContent(e.target.value)} style={{ borderRadius: 8 }} />
                <div style={{ marginTop: 8 }}>
                  <Checkbox checked={assignMode} onChange={(e) => { setAssignMode(e.target.checked); if (e.target.checked) loadPresetStaff(); }}>
                    Phân công giải quyết
                  </Checkbox>
                </div>
                {assignMode && (
                  <div style={{ marginTop: 8, padding: 12, background: '#f0f5ff', borderRadius: 8, border: '1px solid #d6e4ff' }}>
                    <Row gutter={12}>
                      <Col span={16}>
                        <div style={{ marginBottom: 4, fontSize: 12, color: '#595959' }}>Cán bộ xử lý</div>
                        <Select mode="multiple" style={{ width: '100%' }} placeholder="Chọn cán bộ..." value={assignStaffIds} onChange={setAssignStaffIds} options={staffOptions} filterOption={(input, opt) => (opt?.label ?? '').toLowerCase().includes(input.toLowerCase())} />
                      </Col>
                      <Col span={8}>
                        <div style={{ marginBottom: 4, fontSize: 12, color: '#595959' }}>Hạn giải quyết</div>
                        <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" value={assignExpiredDate} onChange={setAssignExpiredDate} />
                      </Col>
                    </Row>
                  </div>
                )}
                <Button type="primary" size="small" style={{ marginTop: 8 }} loading={addingNote} onClick={handleAddNote} disabled={!noteContent.trim()}>
                  {assignMode ? 'Bút phê & Phân công' : 'Gửi bút phê'}
                </Button>
              </div>
            )}
          </div>
        </Col>

        {/* ====== RIGHT COLUMN ====== */}
        <Col xs={24} lg={8}>

          {/* --- Người nhận --- */}
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

      {/* ====== DRAWER GIAO VIỆC ====== */}
      <Drawer forceRender
        title="Giao việc"
        size={720}
        open={giaoViecOpen}
        forceRender
        onClose={() => { setGiaoViecOpen(false); giaoViecForm.resetFields(); }}
        rootClassName="drawer-gradient"
        extra={
          <Space>
            <Button onClick={() => { setGiaoViecOpen(false); giaoViecForm.resetFields(); }} ghost style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}>Hủy</Button>
            <Button type="primary" loading={giaoViecSaving} onClick={handleGiaoViec}>Tạo và giao việc</Button>
          </Space>
        }
      >
        <Form form={giaoViecForm} layout="vertical" validateTrigger="onSubmit" autoComplete="off">
          <Form.Item
            name="name"
            label="Tên hồ sơ"
            rules={[{ required: true, message: 'Vui lòng nhập tên hồ sơ' }]}
          >
            <Input placeholder="Nhập tên hồ sơ công việc..." maxLength={200} />
          </Form.Item>
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="end_date"
                label="Hạn xử lý"
                rules={[{ required: true, message: 'Vui lòng chọn hạn xử lý' }]}
              >
                <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" placeholder="Chọn ngày hạn xử lý" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item
            name="curator_ids"
            label="Người phụ trách"
            rules={[{ required: true, message: 'Vui lòng chọn ít nhất một người phụ trách' }]}
          >
            <Select
              mode="multiple"
              placeholder="Tìm kiếm và chọn người phụ trách..."
              options={staffOptions}
              showSearch
              filterOption={(input, option) =>
                (option?.label as string)?.toLowerCase().includes(input.toLowerCase())
              }
              style={{ width: '100%' }}
            />
          </Form.Item>
          <Form.Item name="note" label="Ghi chú">
            <Input.TextArea rows={4} placeholder="Nhập ghi chú (không bắt buộc)..." maxLength={500} showCount />
          </Form.Item>
        </Form>
      </Drawer>

      {/* ====== MODAL CHUYỂN LẠI ====== */}
      <Modal
        title="Lý do chuyển lại"
        open={chuyenLaiOpen}
        forceRender
        onCancel={() => { setChuyenLaiOpen(false); chuyenLaiForm.resetFields(); }}
        onOk={handleChuyenLai}
        okText="Chuyển lại"
        cancelText="Hủy"
        confirmLoading={chuyenLaiSaving}
        width={480}
      >
        <Form form={chuyenLaiForm} layout="vertical" validateTrigger="onSubmit" style={{ marginTop: 16 }}>
          <Form.Item
            name="reason"
            label="Lý do chuyển lại"
            rules={[{ required: true, message: 'Vui lòng nhập lý do chuyển lại' }]}
          >
            <Input.TextArea
              rows={4}
              placeholder="Nhập lý do chuyển lại văn bản..."
              maxLength={500}
              showCount
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* Modal: Thêm vào HSCV sẵn có */}
      <Modal
        title="Thêm vào hồ sơ công việc"
        open={hscvModalOpen}
        onCancel={() => setHscvModalOpen(false)}
        onOk={handleLinkHscv}
        confirmLoading={hscvSaving}
        okText="Thêm vào HSCV"
        cancelText="Hủy"
      >
        <Select
          style={{ width: '100%', marginTop: 8 }}
          placeholder="Chọn hồ sơ công việc..."
          showSearch
          filterOption={(input, option) => (option?.label ?? '').toLowerCase().includes(input.toLowerCase())}
          value={selectedHscvId}
          onChange={setSelectedHscvId}
          options={hscvList.map(h => ({ value: h.id, label: `${h.name} (${h.status === 0 ? 'Mới' : h.status === 1 ? 'Đang xử lý' : 'Trình duyệt'})` }))}
        />
      </Modal>

      {/* Modal: Gửi liên thông LGSP */}
      <Modal
        title="Gửi liên thông LGSP"
        open={lgspModalOpen}
        onCancel={() => setLgspModalOpen(false)}
        onOk={handleSendLgsp}
        confirmLoading={lgspSending}
        okText="Gửi liên thông"
        cancelText="Hủy"
      >
        <Select
          mode="multiple"
          style={{ width: '100%', marginTop: 8 }}
          placeholder="Chọn đơn vị nhận..."
          showSearch
          filterOption={(input, option) => (option?.label ?? '').toLowerCase().includes(input.toLowerCase())}
          value={selectedLgspOrgs}
          onChange={setSelectedLgspOrgs}
          options={lgspOrgs.map(o => ({ value: o.id, label: `${o.org_name} (${o.org_code})` }))}
        />
      </Modal>

      {/* Drawer: Chuyển lưu trữ */}
      <Drawer forceRender
        title="Chuyển lưu trữ" open={archiveModalOpen} onClose={() => setArchiveModalOpen(false)}
        size={640} rootClassName="drawer-gradient" forceRender
        extra={<Space><Button onClick={() => setArchiveModalOpen(false)}>Hủy</Button><Button type="primary" onClick={handleArchive} loading={archiveSaving}>Chuyển lưu trữ</Button></Space>}
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
    </div>
  );
}
