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
  StarOutlined, StarFilled, CommentOutlined, PaperClipOutlined,
  InboxOutlined, ClockCircleOutlined, UserOutlined, FilePdfOutlined,
  FileImageOutlined, FileWordOutlined, FileExcelOutlined, FileOutlined,
  EditOutlined, SafetyCertificateOutlined,
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
interface Attachment { id: number; file_name: string; file_path: string; file_size: number; content_type: string; created_by_name: string; created_at: string; }
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

// ====== Styles ======
const sectionTitle: React.CSSProperties = {
  fontSize: 14, fontWeight: 600, color: '#1B3A5C', margin: 0,
  display: 'flex', alignItems: 'center', gap: 8,
};
const fieldLabel: React.CSSProperties = {
  fontSize: 12, color: '#8c8c8c', marginBottom: 2,
};
const fieldValue: React.CSSProperties = {
  fontSize: 14, color: '#262626', fontWeight: 500,
};
const infoRow: React.CSSProperties = {
  display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px 24px', marginBottom: 8,
};
const infoRowFull: React.CSSProperties = {
  marginBottom: 8,
};

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
  const [uploading, setUploading] = useState(false);

  const fetchDoc = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}`); setDoc(res.data); } catch { message.error('Không tìm thấy văn bản'); router.push('/van-ban-den'); } }, [docId, message, router]);
  const fetchAttachments = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/dinh-kem`); setAttachments(res.data || []); } catch {} }, [docId]);
  const fetchRecipients = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/nguoi-nhan`); setRecipients(res.data || []); } catch {} }, [docId]);
  const fetchHistory = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/lich-su`); setHistory(res.data || []); } catch {} }, [docId]);
  const fetchLeaderNotes = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/but-phe`); setLeaderNotes(res.data || []); } catch {} }, [docId]);

  useEffect(() => {
    setLoading(true);
    Promise.all([fetchDoc(), fetchAttachments(), fetchRecipients(), fetchHistory(), fetchLeaderNotes()]).finally(() => setLoading(false));
  }, [fetchDoc, fetchAttachments, fetchRecipients, fetchHistory, fetchLeaderNotes]);

  // Actions
  const handleApprove = async () => { try { await api.patch(`/van-ban-den/${docId}/duyet`); message.success('Duyệt thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleUnapprove = async () => { try { await api.patch(`/van-ban-den/${docId}/huy-duyet`); message.success('Hủy duyệt thành công'); fetchDoc(); fetchHistory(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleDelete = () => { modal.confirm({ title: 'Xác nhận xóa', content: 'Xóa văn bản này?', okText: 'Xóa', okType: 'danger', cancelText: 'Hủy', onOk: async () => { try { await api.delete(`/van-ban-den/${docId}`); message.success('Đã xóa'); router.push('/van-ban-den'); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } } }); };
  const handleReceivePaper = async () => { try { await api.patch(`/van-ban-den/${docId}/nhan-ban-giay`); message.success('Đã xác nhận nhận bản giấy'); fetchDoc(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleToggleBookmark = async () => { try { const { data: res } = await api.post(`/van-ban-den/${docId}/danh-dau`, {}); setIsBookmarked(res.data?.is_bookmarked); message.success(res.data?.message); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };

  // Attachments
  const handleUpload = async (file: File) => { setUploading(true); try { const fd = new FormData(); fd.append('file', file); await api.post(`/van-ban-den/${docId}/dinh-kem`, fd, { headers: { 'Content-Type': 'multipart/form-data' } }); message.success('Tải lên thành công'); fetchAttachments(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } finally { setUploading(false); } return false; };
  const handleDownload = async (att: Attachment) => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/dinh-kem/${att.id}/download`); window.open(res.data?.url, '_blank'); } catch { message.error('Lỗi tải file'); } };
  const handleDeleteAttachment = async (att: Attachment) => { try { await api.delete(`/van-ban-den/${docId}/dinh-kem/${att.id}`); message.success('Đã xóa'); fetchAttachments(); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };

  // Send
  const openSendModal = async () => { try { const { data: res } = await api.get(`/van-ban-den/${docId}/danh-sach-gui`); setSendableStaff(res.data || []); setSelectedStaffIds([]); setSendModalOpen(true); } catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); } };
  const handleSend = async () => {
    if (selectedStaffIds.length === 0) { message.warning('Chọn ít nhất một người nhận'); return; }
    setSending(true);
    try { const { data: res } = await api.post(`/van-ban-den/${docId}/gui`, { staff_ids: selectedStaffIds }); message.success(res.data?.message || 'Đã gửi'); setSendModalOpen(false); fetchRecipients(); fetchHistory(); }
    catch (e: any) { message.error(e?.response?.data?.message || 'Lỗi'); }
    finally { setSending(false); }
  };

  // Leader Notes
  const handleAddNote = async () => {
    if (!noteContent.trim()) { message.warning('Nhập nội dung bút phê'); return; }
    setAddingNote(true);
    try { await api.post(`/van-ban-den/${docId}/but-phe`, { content: noteContent.trim() }); message.success('Thêm bút phê thành công'); setNoteContent(''); fetchLeaderNotes(); fetchHistory(); }
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
            : <Tag color="warning">Chờ duyệt</Tag>
          }
          {doc.urgent_id > 1 && <Tag color={urgentTag.color}>{urgentTag.text}</Tag>}
          {doc.secret_id > 1 && <Tag color={secretTag.color}>{secretTag.text}</Tag>}
        </Flex>

        <Space wrap>
          <Button
            icon={isBookmarked ? <StarFilled style={{ color: '#faad14' }} /> : <StarOutlined />}
            onClick={handleToggleBookmark}
          />
          {!doc.approved && (
            <>
              <Button icon={<EditOutlined />} onClick={() => router.push(`/van-ban-den?edit=${doc.id}`)}>Sửa</Button>
              <Button type="primary" icon={<CheckCircleOutlined />} onClick={handleApprove}>Duyệt</Button>
              <Dropdown menu={{ items: [
                { key: 'delete', icon: <DeleteOutlined />, label: 'Xóa văn bản', danger: true, onClick: handleDelete },
              ] }}>
                <Button icon={<MoreOutlined />} />
              </Dropdown>
            </>
          )}
          {doc.approved && (
            <>
              <Button type="primary" icon={<SendOutlined />} onClick={openSendModal}>Gửi</Button>
              <Button icon={<CommentOutlined />} onClick={() => document.getElementById('note-input')?.focus()}>Bút phê</Button>
              <Dropdown menu={{ items: [
                { key: 'unapprove', icon: <CloseCircleOutlined />, label: 'Hủy duyệt', onClick: handleUnapprove },
                ...(!doc.is_received_paper ? [{ key: 'paper', icon: <InboxOutlined />, label: 'Nhận bản giấy', onClick: handleReceivePaper }] : []),
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
            <div style={sectionTitle}>Thông tin văn bản</div>
            <div style={{ marginTop: 16 }}>
              <div style={infoRow}>
                <div><div style={fieldLabel}>Số đến</div><div style={fieldValue}>{doc.number}</div></div>
                <div><div style={fieldLabel}>Ngày đến</div><div style={fieldValue}>{fmtDate(doc.received_date)}</div></div>
              </div>
              <div style={infoRow}>
                <div><div style={fieldLabel}>Số ký hiệu</div><div style={{ ...fieldValue, color: '#0891B2' }}>{doc.notation || '—'}</div></div>
                <div><div style={fieldLabel}>Sổ văn bản</div><div style={fieldValue}>{doc.doc_book_name || '—'}</div></div>
              </div>
              <div style={infoRowFull}>
                <div style={fieldLabel}>Cơ quan ban hành</div>
                <div style={fieldValue}>{doc.publish_unit || '—'}</div>
              </div>
              <div style={infoRow}>
                <div><div style={fieldLabel}>Loại văn bản</div><div style={fieldValue}>{doc.doc_type_name || '—'}</div></div>
                <div><div style={fieldLabel}>Lĩnh vực</div><div style={fieldValue}>{doc.doc_field_name || '—'}</div></div>
              </div>
              <div style={infoRow}>
                <div><div style={fieldLabel}>Người ký</div><div style={fieldValue}>{doc.signer || '—'}</div></div>
                <div><div style={fieldLabel}>Ngày ký</div><div style={fieldValue}>{fmtDate(doc.sign_date)}</div></div>
              </div>
              <div style={infoRow}>
                <div>
                  <div style={fieldLabel}>Hạn xử lý</div>
                  <div style={{ ...fieldValue, color: isOverdue ? '#ff4d4f' : undefined }}>
                    {doc.expired_date ? fmtDate(doc.expired_date) : '—'}
                    {isOverdue && <Tag color="error" style={{ marginLeft: 8 }}>Quá hạn</Tag>}
                  </div>
                </div>
                <div><div style={fieldLabel}>Nơi nhận</div><div style={fieldValue}>{doc.recipients || '—'}</div></div>
              </div>
              <div style={infoRow}>
                <div><div style={fieldLabel}>Độ mật</div><Tag color={secretTag.color}>{secretTag.text}</Tag></div>
                <div><div style={fieldLabel}>Độ khẩn</div><Tag color={urgentTag.color}>{urgentTag.text}</Tag></div>
              </div>
              <div style={infoRow}>
                <div><div style={fieldLabel}>Số tờ / Số bản</div><div style={fieldValue}>{doc.number_paper} tờ / {doc.number_copies} bản</div></div>
                <div><div style={fieldLabel}>Bản giấy</div>{doc.is_received_paper ? <Tag color="success">Đã nhận</Tag> : <Tag>Chưa nhận</Tag>}</div>
              </div>
              <div style={{ borderTop: '1px solid #f0f0f0', paddingTop: 12, marginTop: 12, ...infoRow }}>
                <div><div style={fieldLabel}>Người nhập</div><div style={{ fontSize: 13, color: '#595959' }}>{doc.created_by_name}</div></div>
                <div><div style={fieldLabel}>Thời gian tạo</div><div style={{ fontSize: 13, color: '#595959' }}>{fmtDateTime(doc.created_at)}</div></div>
              </div>
            </div>
          </div>

          {/* --- File đính kèm --- */}
          <div style={{
            background: '#fff', borderRadius: 10, padding: '20px 24px', marginBottom: 16,
            boxShadow: '0 1px 3px rgba(0,0,0,0.06)',
          }}>
            <Flex justify="space-between" align="center" style={{ marginBottom: 12 }}>
              <div style={sectionTitle}><PaperClipOutlined /> Tài liệu đính kèm ({attachments.length})</div>
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
                      <Button size="small" type="link" icon={<DownloadOutlined />} onClick={() => handleDownload(att)} />
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
            <div style={{ ...sectionTitle, marginBottom: 12 }}><CommentOutlined /> Ý kiến bút phê ({leaderNotes.length})</div>

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
                  {note.staff_id === user?.staffId && (
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
                <Button type="primary" size="small" style={{ marginTop: 8 }} loading={addingNote} onClick={handleAddNote} disabled={!noteContent.trim()}>Gửi bút phê</Button>
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
            <div style={{ ...sectionTitle, marginBottom: 12 }}><SendOutlined /> Người nhận ({recipients.length})</div>
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
            <div style={{ ...sectionTitle, marginBottom: 16 }}><ClockCircleOutlined /> Lịch sử xử lý</div>
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
    </div>
  );
}
