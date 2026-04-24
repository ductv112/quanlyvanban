'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Tag, Button, Space, Row, Col, Timeline, Avatar,
  Upload, Modal, Input, Popconfirm, Checkbox, Empty, Spin, App,
  Badge, Typography, Flex, Dropdown,
} from 'antd';
import {
  ArrowLeftOutlined, CheckCircleOutlined, CloseCircleOutlined, SendOutlined,
  DeleteOutlined, DownloadOutlined, UploadOutlined, MoreOutlined,
  StarOutlined, StarFilled, PaperClipOutlined,
  ClockCircleOutlined, UserOutlined, FilePdfOutlined,
  FileImageOutlined, FileWordOutlined, FileExcelOutlined, FileOutlined,
  EditOutlined, SafetyCertificateOutlined, RocketOutlined, StopOutlined, RollbackOutlined, CommentOutlined, SafetyOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import { useSigning } from '@/hooks/use-signing';
import { useParams, useRouter } from 'next/navigation';
import dayjs from 'dayjs';

const { TextArea } = Input;
const { Text } = Typography;

interface DocDetail {
  id: number; unit_id: number; number: number; sub_number: string;
  notation: string; abstract: string;
  publish_date: string; signer: string; sign_date: string;
  doc_book_id: number; doc_type_id: number; doc_field_id: number;
  secret_id: number; urgent_id: number; number_paper: number; number_copies: number;
  expired_date: string; recipients: string; approver: string; approved: boolean;
  is_handling: boolean; archive_status: boolean;
  drafting_unit_id: number; drafting_user_id: number; publish_unit_id: number;
  is_released: boolean; released_date: string; reject_reason: string;
  received_date: string; document_code: string;
  drafting_unit_name: string; drafting_user_name: string; publish_unit_name: string;
  created_by: number; created_at: string; updated_by: number; updated_at: string;
  doc_book_name: string; doc_type_name: string; doc_type_code: string;
  doc_field_name: string; created_by_name: string; is_read: boolean;
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


export default function DraftingDocDetailPage() {
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
  const [isBookmarked, setIsBookmarked] = useState(false);
  const [sendModalOpen, setSendModalOpen] = useState(false);
  const [sendableStaff, setSendableStaff] = useState<SendableStaff[]>([]);
  const [selectedStaffIds, setSelectedStaffIds] = useState<number[]>([]);
  const [sending, setSending] = useState(false);
  const [uploading, setUploading] = useState(false);
  const [rejectModalOpen, setRejectModalOpen] = useState(false);
  const [rejectReason, setRejectReason] = useState('');
  const [rejecting, setRejecting] = useState(false);
  const [leaderNotes, setLeaderNotes] = useState<{ id: number; staff_id: number; staff_name: string; position_name: string; content: string; created_at: string }[]>([]);
  const [noteContent, setNoteContent] = useState('');
  const [addingNote, setAddingNote] = useState(false);
  // Ký số — sử dụng useSigning hook (Plan 11-06, thay thế mock OTP Plan 1)
  const { openSign, renderSignModal } = useSigning();

  const fetchDoc = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-du-thao/${docId}`); setDoc(res.data); } catch { message.error('Không tìm thấy văn bản'); router.push('/van-ban-du-thao'); } }, [docId, message, router]);
  const fetchBookmarkStatus = useCallback(async () => { try { const { data: res } = await api.get('/van-ban-du-thao/danh-dau-ca-nhan'); const bookmarks: { doc_id: number | string }[] = res.data || []; setIsBookmarked(bookmarks.some((b) => Number(b.doc_id) === Number(docId))); } catch {} }, [docId]);
  const fetchAttachments = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-du-thao/${docId}/dinh-kem`); setAttachments(res.data || []); } catch {} }, [docId]);
  const fetchRecipients = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-du-thao/${docId}/nguoi-nhan`); setRecipients(res.data || []); } catch {} }, [docId]);
  const fetchHistory = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-du-thao/${docId}/lich-su`); setHistory(res.data || []); } catch {} }, [docId]);
  const fetchLeaderNotes = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-du-thao/${docId}/y-kien`); setLeaderNotes(res.data || []); } catch {} }, [docId]);

  useEffect(() => {
    setLoading(true);
    Promise.all([fetchDoc(), fetchAttachments(), fetchRecipients(), fetchHistory(), fetchLeaderNotes(), fetchBookmarkStatus()]).finally(() => setLoading(false));
  }, [fetchDoc, fetchAttachments, fetchRecipients, fetchHistory, fetchBookmarkStatus]);

  // Actions
  const handleApprove = async () => { try { await api.patch(`/van-ban-du-thao/${docId}/duyet`); message.success('Duyệt thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleUnapprove = async () => { try { await api.patch(`/van-ban-du-thao/${docId}/huy-duyet`); message.success('Hủy duyệt thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleRetract = () => { modal.confirm({ title: 'Thu hồi văn bản dự thảo', content: 'Thu hồi sẽ xóa tất cả người nhận và đặt lại trạng thái chưa duyệt. Bạn chắc chắn?', okText: 'Thu hồi', okButtonProps: { danger: true }, cancelText: 'Hủy', onOk: async () => { try { await api.post(`/van-ban-du-thao/${docId}/thu-hoi`); message.success('Thu hồi thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } } }); };
  const handleDelete = () => { modal.confirm({ title: 'Xác nhận xóa', content: 'Xóa văn bản dự thảo này?', okText: 'Xóa', okType: 'danger', cancelText: 'Hủy', onOk: async () => { try { await api.delete(`/van-ban-du-thao/${docId}`); message.success('Đã xóa'); router.push('/van-ban-du-thao'); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } } }); };
  const handleRelease = async () => {
    try {
      const { data: res } = await api.post(`/van-ban-du-thao/${docId}/phat-hanh`);
      const outgoingId = res.data?.outgoing_doc_id;
      fetchDoc(); fetchHistory();
      if (outgoingId) {
        modal.success({
          title: 'Phát hành thành công',
          content: `Đã tạo văn bản đi #${outgoingId} từ dự thảo này.`,
          okText: 'Xem văn bản đi',
          cancelText: 'Ở lại trang này',
          onOk: () => router.push(`/van-ban-di/${outgoingId}`),
        });
      } else {
        message.success('Phát hành thành công');
      }
    } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
  };
  const handleReject = async () => {
    setRejecting(true);
    try {
      await api.patch(`/van-ban-du-thao/${docId}/tu-choi`, { reason: rejectReason.trim() || undefined });
      message.success('Đã từ chối văn bản dự thảo');
      setRejectModalOpen(false);
      setRejectReason('');
      fetchDoc(); fetchHistory();
    } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setRejecting(false); }
  };
  const handleToggleBookmark = async () => { try { const { data: res } = await api.post(`/van-ban-du-thao/${docId}/danh-dau`, {}); setIsBookmarked(res.data?.is_bookmarked); message.success(res.data?.message); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };

  // Leader Notes
  const handleAddNote = async () => {
    if (!noteContent.trim()) { message.warning('Nhập nội dung ý kiến'); return; }
    setAddingNote(true);
    try { await api.post(`/van-ban-du-thao/${docId}/y-kien`, { content: noteContent.trim() }); message.success('Thêm ý kiến thành công'); setNoteContent(''); fetchLeaderNotes(); fetchHistory(); }
    catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setAddingNote(false); }
  };
  const handleDeleteNote = async (noteId: number) => { try { await api.delete(`/van-ban-du-thao/${docId}/y-kien/${noteId}`); message.success('Đã xóa'); fetchLeaderNotes(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };

  // Attachments
  const handleUpload = async (file: File) => { setUploading(true); try { const fd = new FormData(); fd.append('file', file); await api.post(`/van-ban-du-thao/${docId}/dinh-kem`, fd, { headers: { 'Content-Type': 'multipart/form-data' } }); message.success('Tải lên thành công'); fetchAttachments(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } finally { setUploading(false); } return false; };
  const handleDownload = async (att: Attachment) => { try { const { data: res } = await api.get(`/van-ban-du-thao/${docId}/dinh-kem/${att.id}/download`); window.open(res.data?.url, '_blank'); } catch { message.error('Lỗi tải file'); } };
  const handleDeleteAttachment = async (att: Attachment) => { try { await api.delete(`/van-ban-du-thao/${docId}/dinh-kem/${att.id}`); message.success('Đã xóa'); fetchAttachments(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };

  // Send
  const openSendModal = async () => { try { const { data: res } = await api.get(`/van-ban-du-thao/${docId}/danh-sach-gui`); setSendableStaff(res.data || []); setSelectedStaffIds([]); setSendModalOpen(true); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleSend = async () => {
    if (selectedStaffIds.length === 0) { message.warning('Chọn ít nhất một người nhận'); return; }
    setSending(true);
    try { const { data: res } = await api.post(`/van-ban-du-thao/${docId}/gui`, { staff_ids: selectedStaffIds }); message.success(res.data?.message || 'Đã gửi'); setSendModalOpen(false); fetchRecipients(); fetchHistory(); }
    catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setSending(false); }
  };

  if (loading) return <div style={{ textAlign: 'center', padding: 80 }}><Spin size="large" /></div>;
  if (!doc) return <Empty description="Không tìm thấy văn bản dự thảo" />;

  const urgentTag = URGENT_TAGS[doc.urgent_id];
  const secretTag = SECRET_TAGS[doc.secret_id];
  const isOverdue = doc.expired_date && dayjs(doc.expired_date).isBefore(dayjs());

  // Status logic
  const statusTag = doc.is_released
    ? <Tag color="success" icon={<RocketOutlined />}>Đã phát hành</Tag>
    : doc.approved
      ? <Tag color="blue" icon={<SafetyCertificateOutlined />}>Đã duyệt</Tag>
      : (doc as any).rejected_by || doc.reject_reason
        ? <Tag color="red">Từ chối</Tag>
        : <Tag color="gold">Dự thảo</Tag>;

  return (
    <div>
      {/* ====== HEADER BAR ====== */}
      <div style={{
        background: '#fff', borderRadius: 10, padding: '16px 24px', marginBottom: 16,
        boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
        display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 12,
      }}>
        <Flex align="center" gap={12}>
          <Button icon={<ArrowLeftOutlined />} onClick={() => router.push('/van-ban-du-thao')} />
          <div>
            <div style={{ fontSize: 16, fontWeight: 700, color: '#1B3A5C' }}>
              Số: {doc.number}{doc.sub_number ? `/${doc.sub_number}` : ''} — {doc.notation || 'Không có ký hiệu'}
            </div>
            <div style={{ fontSize: 13, color: '#8c8c8c' }}>
              {doc.drafting_unit_name || 'Đơn vị soạn'} • Người soạn: {doc.drafting_user_name || '—'}
            </div>
          </div>
          {statusTag}
          {doc.urgent_id > 1 && <Tag color={urgentTag.color}>{urgentTag.text}</Tag>}
          {doc.secret_id > 1 && <Tag color={secretTag.color}>{secretTag.text}</Tag>}
        </Flex>
        {(doc as any).rejected_by && ((doc as any).rejection_reason || doc.reject_reason) && (
          <div style={{ marginTop: 8, padding: '8px 12px', background: '#fff1f0', border: '1px solid #ffa39e', borderRadius: 6, color: '#cf1322' }}>
            <strong>Lý do từ chối:</strong> {(doc as any).rejection_reason || doc.reject_reason}
          </div>
        )}

        <Space wrap>
          <Button
            icon={isBookmarked ? <StarFilled style={{ color: '#faad14' }} /> : <StarOutlined />}
            onClick={handleToggleBookmark}
          />
          {/* Not approved: Edit, Approve, Reject, Delete */}
          {/* Chưa duyệt, chưa phát hành: Sửa, Duyệt, Từ chối, Xóa */}
          {!doc.approved && !doc.is_released && (
            <>
              <Button icon={<EditOutlined />} onClick={() => router.push(`/van-ban-du-thao?edit=${doc.id}`)}>Sửa</Button>
              <Button type="primary" icon={<CheckCircleOutlined />} onClick={handleApprove}>Duyệt</Button>
              <Dropdown menu={{ items: [
                ...( !(doc as any).rejected_by ? [{ key: 'reject', icon: <StopOutlined />, label: 'Từ chối', danger: true, onClick: () => { setRejectReason(''); setRejectModalOpen(true); } }] : []),
                { type: 'divider' as const },
                { key: 'delete', icon: <DeleteOutlined />, label: 'Xóa văn bản', danger: true, onClick: handleDelete },
              ] }}>
                <Button icon={<MoreOutlined />} />
              </Dropdown>
            </>
          )}
          {/* Đã duyệt, chưa phát hành: Phát hành, Gửi, Hủy duyệt, Thu hồi */}
          {doc.approved && !doc.is_released && (
            <>
              <Button type="primary" style={{ background: '#52c41a', borderColor: '#52c41a' }} icon={<RocketOutlined />} onClick={handleRelease}>Phát hành</Button>
              <Button type="primary" icon={<SendOutlined />} onClick={openSendModal}>Gửi</Button>
              <Dropdown menu={{ items: [
                { key: 'unapprove', icon: <CloseCircleOutlined />, label: 'Hủy duyệt', onClick: handleUnapprove },
                { key: 'retract', icon: <RollbackOutlined />, label: 'Thu hồi', onClick: handleRetract },
              ] }}>
                <Button icon={<MoreOutlined />} />
              </Dropdown>
            </>
          )}
          {/* Released: view only, badge already shown */}
          {doc.is_released && (
            <Tag color="success" style={{ fontSize: 13, padding: '4px 12px' }}>Đã phát hành ngày {fmtDate(doc.released_date)}</Tag>
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
            <div className="section-title">Thông tin văn bản dự thảo</div>
            <div style={{ marginTop: 16 }}>
              <div className="info-grid">
                <div><div className="info-label">Số văn bản</div><div className="info-value">{doc.number}{doc.sub_number ? `/${doc.sub_number}` : ''}</div></div>
                <div><div className="info-label">Số ký hiệu</div><div className="info-value" style={{ color: '#0891B2' }}>{doc.notation || '—'}</div></div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Sổ văn bản</div><div className="info-value">{doc.doc_book_name || '—'}</div></div>
                <div><div className="info-label">Loại văn bản</div><div className="info-value">{doc.doc_type_name || '—'}</div></div>
              </div>
              <div className="info-grid-full">
                <div className="info-label">Đơn vị soạn</div>
                <div className="info-value">{doc.drafting_unit_name || '—'}</div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Người soạn</div><div className="info-value">{doc.drafting_user_name || '—'}</div></div>
                <div><div className="info-label">Đơn vị phát hành</div><div className="info-value">{doc.publish_unit_name || '—'}</div></div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Lĩnh vực</div><div className="info-value">{doc.doc_field_name || '—'}</div></div>
                <div><div className="info-label">Ngày ban hành</div><div className="info-value">{fmtDate(doc.publish_date)}</div></div>
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
                <div>
                  <div className="info-label">Người duyệt</div>
                  <div className="info-value">
                    {doc.approver
                      ? <>{doc.approver}{(doc as any).approved_at && <Tag color="success" style={{ marginLeft: 8 }}>{dayjs((doc as any).approved_at).format('DD/MM/YYYY HH:mm')}</Tag>}</>
                      : <span style={{ color: '#bfbfbf' }}>Chưa duyệt</span>}
                  </div>
                </div>
                {doc.reject_reason && (
                  <div><div className="info-label">Lý do từ chối</div><div className="info-value" style={{ color: '#DC2626' }}>{doc.reject_reason}</div></div>
                )}
              </div>
              <div className="info-grid">
                <div><div className="info-label">Độ mật</div><Tag color={secretTag.color}>{secretTag.text}</Tag></div>
                <div><div className="info-label">Độ khẩn</div><Tag color={urgentTag.color}>{urgentTag.text}</Tag></div>
              </div>
              <div className="info-grid">
                <div><div className="info-label">Số tờ / Số bản</div><div className="info-value">{doc.number_paper} tờ / {doc.number_copies} bản</div></div>
                <div>
                  <div className="info-label">Trạng thái phát hành</div>
                  {doc.is_released
                    ? <Tag color="success">Đã phát hành — {fmtDate(doc.released_date)}</Tag>
                    : <Tag>Chưa phát hành</Tag>
                  }
                </div>
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
              {!doc.is_released && (
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
                          attachmentType: 'drafting',
                          docId: doc.id,
                          signReason: `Phê duyệt VB dự thảo số ${doc.number}/${doc.notation}`,
                          signLocation: doc.drafting_unit_name || 'Lào Cai',
                          onSuccess: fetchAttachments,
                        })}>
                          Ký số
                        </Button>
                      )}
                      <Button size="small" type="link" icon={<DownloadOutlined />} onClick={() => handleDownload(att)} />
                      {!doc.is_released && <Popconfirm title="Xóa file?" onConfirm={() => handleDeleteAttachment(att)}><Button size="small" type="link" danger icon={<DeleteOutlined />} /></Popconfirm>}
                    </Space>
                  </Flex>
                ))}
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

          {/* --- Ý kiến lãnh đạo --- */}
          <div style={{ background: '#fff', borderRadius: 10, padding: '20px 24px', boxShadow: '0 1px 3px rgba(0,0,0,0.06)', marginBottom: 16 }}>
            <div className="section-title" style={{ marginBottom: 12 }}><CommentOutlined /> Ý kiến lãnh đạo ({leaderNotes.length})</div>
            {leaderNotes.map((note) => (
              <div key={note.id} style={{ padding: '8px 12px', background: '#fffbe6', borderRadius: 8, marginBottom: 8, border: '1px solid #ffe58f' }}>
                <Flex justify="space-between" align="start">
                  <div>
                    <div style={{ fontWeight: 600, fontSize: 13, color: '#1B3A5C' }}>{note.staff_name}{note.position_name ? ` — ${note.position_name}` : ''}</div>
                    <div style={{ fontSize: 14, marginTop: 4, color: '#262626' }}>{note.content}</div>
                    <div style={{ fontSize: 11, color: '#8c8c8c', marginTop: 4 }}>{note.created_at ? dayjs(note.created_at).format('DD/MM/YYYY HH:mm') : ''}</div>
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
                color: h.event_type === 'created' ? 'blue' : h.event_type === 'approved' ? 'green' : h.event_type === 'sent' ? 'cyan' : h.event_type === 'released' ? 'purple' : h.event_type === 'rejected' ? 'red' : 'gray',
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
      <Modal title="Gửi văn bản dự thảo" open={sendModalOpen} onCancel={() => setSendModalOpen(false)} onOk={handleSend} okText={`Gửi (${selectedStaffIds.length})`} cancelText="Hủy" confirmLoading={sending} width={560}>
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

      {/* ====== MODAL TỪ CHỐI ====== */}
      <Modal
        title="Từ chối văn bản dự thảo"
        open={rejectModalOpen}
        onCancel={() => { setRejectModalOpen(false); setRejectReason(''); }}
        onOk={handleReject}
        okText="Từ chối"
        okType="danger"
        cancelText="Hủy"
        confirmLoading={rejecting}
        width={480}
      >
        <div style={{ marginBottom: 8, fontSize: 13, color: '#595959' }}>
          Nhập lý do từ chối (không bắt buộc):
        </div>
        <TextArea
          rows={3}
          placeholder="Lý do từ chối..."
          value={rejectReason}
          onChange={(e) => setRejectReason(e.target.value)}
          style={{ borderRadius: 8 }}
        />
      </Modal>

      {/* Sign modal từ useSigning hook (Plan 11-06) — replace mock OTP với real async flow */}
      {renderSignModal()}
    </div>
  );
}
