'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Button, Tag, Row, Col, Space, Spin, Empty, App,
  Popconfirm, Modal, Form, Input, Flex, Upload,
} from 'antd';
import {
  ArrowLeftOutlined, SwapOutlined, CheckCircleOutlined,
  RollbackOutlined, CloseCircleOutlined, UploadOutlined,
  DownloadOutlined, DeleteOutlined, PaperClipOutlined,
  FilePdfOutlined, FileImageOutlined, FileWordOutlined,
  FileExcelOutlined, FileOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useParams, useRouter } from 'next/navigation';
import dayjs from 'dayjs';

const { TextArea } = Input;

interface LienThongDocDetail {
  id: number;
  unit_id: number;
  received_date: string;
  notation: string;
  document_code: string;
  abstract: string;
  expired_date: string;
  publish_unit: string;
  publish_date: string;
  signer: string;
  sign_date: string;
  doc_type_id: number;
  doc_field_id: number;
  secret_id: number;
  urgent_id: number;
  number_paper: number;
  number_copies: number;
  recipients: string;
  status: string;
  source_system: string;
  external_doc_id: string;
  organ_id: string;
  from_organ_id: string;
  created_by: number;
  created_at: string;
  updated_at: string;
  doc_type_name: string;
  doc_field_name: string;
  created_by_name: string;
  // HDSD 2.3 — recall flow
  recall_reason?: string | null;
  recall_requested_at?: string | null;
  recall_response?: string | null;
  recall_responded_by?: number | null;
  recall_responded_at?: string | null;
  status_before_recall?: string | null;
}

const STATUS_MAP: Record<string, { text: string; color: string }> = {
  pending: { text: 'Chờ xử lý', color: 'gold' },
  received: { text: 'Đã nhận', color: 'cyan' },
  completed: { text: 'Hoàn thành', color: 'green' },
  returned: { text: 'Đã chuyển lại', color: 'orange' },
  recall_requested: { text: 'Đang yêu cầu thu hồi', color: 'volcano' },
  recalled: { text: 'Đã thu hồi', color: 'red' },
};

const SECRET_MAP: Record<number, { text: string; color: string }> = {
  1: { text: 'Thường', color: 'default' },
  2: { text: 'Mật', color: 'orange' },
  3: { text: 'Tối mật', color: 'red' },
  4: { text: 'Tuyệt mật', color: 'volcano' },
};

const URGENT_MAP: Record<number, { text: string; color: string }> = {
  1: { text: 'Thường', color: 'default' },
  2: { text: 'Khẩn', color: 'orange' },
  3: { text: 'Hỏa tốc', color: 'red' },
};

function fmtDate(d: string | null | undefined) { return d ? dayjs(d).format('DD/MM/YYYY') : '—'; }
function fmtDateTime(d: string | null | undefined) { return d ? dayjs(d).format('DD/MM/YYYY HH:mm') : '—'; }

export default function LienThongDocDetailPage() {
  const { message } = App.useApp();
  const params = useParams();
  const router = useRouter();
  const docId = Number(params.id);

  const [loading, setLoading] = useState(true);
  const [doc, setDoc] = useState<LienThongDocDetail | null>(null);
  const [actionLoading, setActionLoading] = useState(false);

  // Chuyển lại modal
  const [chuyenLaiOpen, setChuyenLaiOpen] = useState(false);
  const [chuyenLaiSaving, setChuyenLaiSaving] = useState(false);
  const [chuyenLaiForm] = Form.useForm();

  // HDSD 2.3 — Từ chối thu hồi modal
  const [tuChoiThuHoiOpen, setTuChoiThuHoiOpen] = useState(false);
  const [tuChoiThuHoiSaving, setTuChoiThuHoiSaving] = useState(false);
  const [tuChoiThuHoiForm] = Form.useForm();

  // Attachments
  interface Attachment { id: number; file_name: string; file_path: string; file_size: number; content_type: string; created_by_name: string; created_at: string; }
  const [attachments, setAttachments] = useState<Attachment[]>([]);
  const [uploading, setUploading] = useState(false);

  const fetchAttachments = useCallback(async () => { try { const { data: res } = await api.get(`/van-ban-lien-thong/${docId}/dinh-kem`); setAttachments(res.data || []); } catch {} }, [docId]);

  const fetchDoc = useCallback(async () => {
    try {
      const { data: res } = await api.get(`/van-ban-lien-thong/${docId}`);
      setDoc(res.data);
    } catch {
      message.error('Không tìm thấy văn bản liên thông');
      router.push('/van-ban-lien-thong');
    }
  }, [docId, message, router]);

  useEffect(() => {
    setLoading(true);
    Promise.all([fetchDoc(), fetchAttachments()]).finally(() => setLoading(false));
  }, [fetchDoc, fetchAttachments]);

  const handleUpload = async (file: File) => {
    setUploading(true);
    try {
      const fd = new FormData(); fd.append('file', file);
      await api.post(`/van-ban-lien-thong/${docId}/dinh-kem`, fd, { headers: { 'Content-Type': 'multipart/form-data' } });
      message.success('Tải lên thành công'); fetchAttachments();
    } catch (e: unknown) { const err = e as { response?: { data?: { message?: string } } }; message.error(err?.response?.data?.message || 'Lỗi'); }
    finally { setUploading(false); } return false;
  };
  const handleDownload = async (att: Attachment) => { try { const { data: res } = await api.get(`/van-ban-lien-thong/${docId}/dinh-kem/${att.id}/download`); window.open(res.data?.url, '_blank'); } catch { message.error('Lỗi tải file'); } };
  const handleDeleteAttachment = async (att: Attachment) => { try { await api.delete(`/van-ban-lien-thong/${docId}/dinh-kem/${att.id}`); message.success('Đã xóa'); fetchAttachments(); } catch (e: unknown) { const err = e as { response?: { data?: { message?: string } } }; message.error(err?.response?.data?.message || 'Lỗi'); } };

  const handleNhanBanGiao = async () => {
    setActionLoading(true);
    try {
      await api.post(`/van-ban-lien-thong/${docId}/nhan-ban-giao`, {});
      message.success('Nhận bàn giao thành công');
      fetchDoc();
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      message.error(err?.response?.data?.message || 'Thao tác thất bại');
    } finally {
      setActionLoading(false);
    }
  };

  const handleChuyenLai = async () => {
    try {
      const values = await chuyenLaiForm.validateFields();
      setChuyenLaiSaving(true);
      await api.post(`/van-ban-lien-thong/${docId}/chuyen-lai`, { reason: values.reason });
      message.success('Chuyển lại văn bản thành công');
      setChuyenLaiOpen(false);
      chuyenLaiForm.resetFields();
      fetchDoc();
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      if (err?.response?.data?.message) message.error(err.response.data.message);
    } finally {
      setChuyenLaiSaving(false);
    }
  };

  const handleHoanThanh = async () => {
    setActionLoading(true);
    try {
      await api.post(`/van-ban-lien-thong/${docId}/hoan-thanh`, {});
      message.success('Đã hoàn thành xử lý văn bản liên thông');
      fetchDoc();
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      message.error(err?.response?.data?.message || 'Thao tác thất bại');
    } finally {
      setActionLoading(false);
    }
  };

  // HDSD 2.3 — Đồng ý thu hồi (status='recall_requested' → 'recalled' + soft-delete VB đến liên kết)
  const handleDongYThuHoi = () => {
    Modal.confirm({
      title: 'Đồng ý thu hồi văn bản?',
      content: 'Văn bản đến đã phát sinh từ văn bản liên thông này sẽ bị xóa (chuyển vào thùng rác). Bạn xác nhận?',
      okText: 'Đồng ý thu hồi',
      okButtonProps: { danger: true },
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          const { data: res } = await api.post(`/van-ban-lien-thong/${docId}/dong-y-thu-hoi`);
          message.success(res?.message || 'Đã đồng ý thu hồi');
          fetchDoc();
        } catch (e: unknown) {
          const err = e as { response?: { data?: { message?: string } } };
          message.error(err?.response?.data?.message || 'Thao tác thất bại');
        }
      },
    });
  };

  // HDSD 2.3 — Từ chối thu hồi (restore status_before_recall, fallback 'received')
  const handleTuChoiThuHoi = async () => {
    try {
      const values = await tuChoiThuHoiForm.validateFields();
      setTuChoiThuHoiSaving(true);
      const { data: res } = await api.post(
        `/van-ban-lien-thong/${docId}/tu-choi-thu-hoi`,
        { reason: values.reason },
      );
      message.success(res?.message || 'Đã từ chối thu hồi');
      setTuChoiThuHoiOpen(false);
      tuChoiThuHoiForm.resetFields();
      fetchDoc();
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      if (err?.response?.data?.message) message.error(err.response.data.message);
    } finally {
      setTuChoiThuHoiSaving(false);
    }
  };

  if (loading) return <div style={{ textAlign: 'center', padding: 80 }}><Spin size="large" /></div>;
  if (!doc) return <Empty description="Không tìm thấy văn bản liên thông" />;

  const statusInfo = STATUS_MAP[doc.status] || { text: doc.status || 'Chờ xử lý', color: 'default' };
  const secretInfo = SECRET_MAP[doc.secret_id] || SECRET_MAP[1];
  const urgentInfo = URGENT_MAP[doc.urgent_id] || URGENT_MAP[1];
  const isOverdue = doc.expired_date && dayjs().isAfter(dayjs(doc.expired_date));

  return (
    <div>
      {/* HEADER BAR */}
      <div className="detail-header">
        <div className="detail-header-left">
          <Button icon={<ArrowLeftOutlined />} onClick={() => router.push('/van-ban-lien-thong')} />
          <div>
            <div style={{ fontSize: 16, fontWeight: 700, color: '#1B3A5C' }}>
              <SwapOutlined style={{ marginRight: 8 }} />
              {doc.notation || 'Văn bản liên thông'}
            </div>
            <div style={{ fontSize: 13, color: '#8c8c8c' }}>
              {doc.publish_unit} • Ngày nhận: {fmtDate(doc.received_date)}
            </div>
          </div>
          <Tag color={statusInfo.color}>{statusInfo.text}</Tag>
          {doc.urgent_id > 1 && <Tag color={urgentInfo.color}>{urgentInfo.text}</Tag>}
        </div>

        <div className="detail-header-right">
          {/* Nhận bàn giao — chỉ hiện khi pending */}
          {doc.status === 'pending' && (
            <Popconfirm
              title="Nhận bàn giao văn bản?"
              description="Văn bản sẽ được chuyển thành VB đến để xử lý."
              okText="Xác nhận"
              cancelText="Hủy"
              onConfirm={handleNhanBanGiao}
              disabled={actionLoading}
            >
              <Button
                type="primary"
                icon={<CheckCircleOutlined />}
                loading={actionLoading}
                style={{ backgroundColor: '#059669', borderColor: '#059669' }}
              >
                Nhận bàn giao
              </Button>
            </Popconfirm>
          )}

          {/* Chuyển lại (Từ chối) — chỉ hiện khi pending */}
          {doc.status === 'pending' && (
            <Button
              icon={<RollbackOutlined />}
              onClick={() => { chuyenLaiForm.resetFields(); setChuyenLaiOpen(true); }}
            >
              Chuyển lại
            </Button>
          )}

          {/* Hoàn thành — chỉ hiện khi đã nhận (received) */}
          {doc.status === 'received' && (
            <Popconfirm
              title="Hoàn thành xử lý?"
              description="Đánh dấu văn bản liên thông này đã xử lý xong."
              okText="Hoàn thành"
              cancelText="Hủy"
              onConfirm={handleHoanThanh}
              disabled={actionLoading}
            >
              <Button
                type="primary"
                icon={<CheckCircleOutlined />}
                loading={actionLoading}
              >
                Hoàn thành
              </Button>
            </Popconfirm>
          )}

          {/* HDSD 2.3 — 2 nút Đồng ý / Từ chối thu hồi (chỉ hiện khi recall_requested) */}
          {doc.status === 'recall_requested' && (
            <>
              <Button danger icon={<CheckCircleOutlined />} onClick={handleDongYThuHoi}>
                Đồng ý thu hồi
              </Button>
              <Button
                type="primary"
                icon={<CloseCircleOutlined />}
                onClick={() => { tuChoiThuHoiForm.resetFields(); setTuChoiThuHoiOpen(true); }}
              >
                Từ chối thu hồi
              </Button>
            </>
          )}
        </div>
      </div>

      {/* HDSD 2.3 — Card Lý do yêu cầu thu hồi (hiện khi đang yêu cầu hoặc đã có recall_response) */}
      {(doc.recall_reason || doc.recall_response) && (
        <Card
          size="small"
          style={{
            marginBottom: 16,
            borderLeft: '4px solid #DC2626',
            background: '#FEF2F2',
          }}
        >
          {doc.recall_reason && (
            <div style={{ marginBottom: doc.recall_response ? 12 : 0 }}>
              <div style={{ fontSize: 12, fontWeight: 600, color: '#991B1B', marginBottom: 4 }}>
                LÝ DO YÊU CẦU THU HỒI
                {doc.recall_requested_at && (
                  <span style={{ fontWeight: 400, color: '#7F1D1D', marginLeft: 8 }}>
                    ({fmtDateTime(doc.recall_requested_at)})
                  </span>
                )}
              </div>
              <div style={{ fontSize: 14, color: '#1B3A5C' }}>{doc.recall_reason}</div>
            </div>
          )}
          {doc.recall_response && (
            <div>
              <div style={{ fontSize: 12, fontWeight: 600, color: '#991B1B', marginBottom: 4 }}>
                PHẢN HỒI TỪ CHỐI THU HỒI
                {doc.recall_responded_at && (
                  <span style={{ fontWeight: 400, color: '#7F1D1D', marginLeft: 8 }}>
                    ({fmtDateTime(doc.recall_responded_at)})
                  </span>
                )}
              </div>
              <div style={{ fontSize: 14, color: '#1B3A5C' }}>{doc.recall_response}</div>
            </div>
          )}
        </Card>
      )}

      {/* BODY */}
      <Row gutter={16}>
        <Col xs={24} lg={16}>
          {/* Trích yếu */}
          <div className="doc-abstract-box" style={{ marginBottom: 16, background: '#fff', borderRadius: 10, padding: '20px 24px', boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}>
            <div style={{ fontSize: 11, textTransform: 'uppercase', color: '#8c8c8c', letterSpacing: 1, marginBottom: 8 }}>Trích yếu nội dung</div>
            <div style={{ fontSize: 15, fontWeight: 600, color: '#1B3A5C', lineHeight: 1.6 }}>
              {doc.abstract}
            </div>
          </div>

          {/* Thông tin chi tiết */}
          <Card style={{ marginBottom: 16 }}>
            <div className="section-title" style={{ marginBottom: 16 }}>Thông tin văn bản</div>

            <div className="info-grid">
              <div><div className="info-label">Ký hiệu văn bản</div><div className="info-value" style={{ color: '#0891B2' }}>{doc.notation || '—'}</div></div>
              <div><div className="info-label">Ngày nhận</div><div className="info-value">{fmtDate(doc.received_date)}</div></div>
            </div>
            <div className="info-grid-full">
              <div className="info-label">Đơn vị phát hành</div>
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
              <div><div className="info-label">Ngày ban hành</div><div className="info-value">{fmtDate(doc.publish_date)}</div></div>
              <div>
                <div className="info-label">Hạn trả lời</div>
                <div className="info-value" style={{ color: isOverdue ? '#DC2626' : undefined }}>
                  {doc.expired_date ? fmtDate(doc.expired_date) : '—'}
                  {isOverdue && <Tag color="error" style={{ marginLeft: 8 }}>Quá hạn</Tag>}
                </div>
              </div>
            </div>
            <div className="info-grid">
              <div><div className="info-label">Độ mật</div><Tag color={secretInfo.color}>{secretInfo.text}</Tag></div>
              <div><div className="info-label">Độ khẩn</div><Tag color={urgentInfo.color}>{urgentInfo.text}</Tag></div>
            </div>
            <div className="info-grid">
              <div><div className="info-label">Số tờ / Số bản</div><div className="info-value">{doc.number_paper} tờ / {doc.number_copies} bản</div></div>
              <div><div className="info-label">Trạng thái</div><Tag color={statusInfo.color}>{statusInfo.text}</Tag></div>
            </div>
            {doc.recipients && (
              <div className="info-grid-full">
                <div className="info-label">Nơi nhận</div>
                <div className="info-value">{doc.recipients}</div>
              </div>
            )}
            <div className="info-grid" style={{ borderTop: '1px solid #f0f0f0', paddingTop: 12, marginTop: 12 }}>
              <div><div className="info-label">Người nhập</div><div style={{ fontSize: 13, color: '#595959' }}>{doc.created_by_name || '—'}</div></div>
              <div><div className="info-label">Thời gian tạo</div><div style={{ fontSize: 13, color: '#595959' }}>{fmtDateTime(doc.created_at)}</div></div>
            </div>
          </Card>
        </Col>

        <Col xs={24} lg={8}>
          <Card>
            <div className="section-title" style={{ marginBottom: 12 }}>Thông tin liên thông</div>
            <Flex vertical gap={8}>
              <div>
                <div className="info-label">Trạng thái xử lý</div>
                <Tag color={statusInfo.color} style={{ marginTop: 4 }}>{statusInfo.text}</Tag>
              </div>
              <div>
                <div className="info-label">Đơn vị phát hành</div>
                <div className="info-value">{doc.publish_unit || '—'}</div>
              </div>
              <div>
                <div className="info-label">Ngày nhận</div>
                <div className="info-value">{fmtDate(doc.received_date)}</div>
              </div>
              {doc.expired_date && (
                <div>
                  <div className="info-label">Hạn trả lời</div>
                  <div className="info-value" style={{ color: isOverdue ? '#DC2626' : undefined }}>
                    {fmtDate(doc.expired_date)}
                    {isOverdue && <span style={{ marginLeft: 6, fontSize: 12, color: '#DC2626' }}>(Quá hạn)</span>}
                  </div>
                </div>
              )}
            </Flex>
          </Card>
        </Col>
      </Row>

      {/* FILE ĐÍNH KÈM */}
      <Card size="small" style={{ marginTop: 16 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <div className="section-title"><PaperClipOutlined /> File đính kèm ({attachments.length})</div>
          <Upload showUploadList={false} beforeUpload={handleUpload as unknown as () => boolean} disabled={uploading}>
            <Button size="small" icon={<UploadOutlined />} loading={uploading}>Tải lên</Button>
          </Upload>
        </div>
        {attachments.length === 0 ? (
          <Empty description="Chưa có file đính kèm" image={Empty.PRESENTED_IMAGE_SIMPLE} />
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {attachments.map((att) => (
              <div key={att.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 12px', background: '#fafafa', borderRadius: 6 }}>
                <Space>
                  {att.file_name.match(/\.pdf$/i) ? <FilePdfOutlined style={{ color: '#f5222d' }} /> : att.file_name.match(/\.(jpg|jpeg|png|gif)$/i) ? <FileImageOutlined style={{ color: '#1890ff' }} /> : att.file_name.match(/\.(doc|docx)$/i) ? <FileWordOutlined style={{ color: '#2f54eb' }} /> : att.file_name.match(/\.(xls|xlsx)$/i) ? <FileExcelOutlined style={{ color: '#52c41a' }} /> : <FileOutlined />}
                  <span>{att.file_name}</span>
                  <span style={{ color: '#8c8c8c', fontSize: 12 }}>{att.file_size ? (att.file_size < 1048576 ? (att.file_size / 1024).toFixed(1) + ' KB' : (att.file_size / 1048576).toFixed(1) + ' MB') : ''}</span>
                </Space>
                <Space>
                  <Button size="small" type="link" icon={<DownloadOutlined />} onClick={() => handleDownload(att)}>Tải</Button>
                  <Popconfirm title="Xóa file?" onConfirm={() => handleDeleteAttachment(att)}>
                    <Button size="small" type="link" danger icon={<DeleteOutlined />} />
                  </Popconfirm>
                </Space>
              </div>
            ))}
          </div>
        )}
      </Card>

      {/* MODAL CHUYỂN LẠI */}
      <Modal
        title="Lý do chuyển lại"
        open={chuyenLaiOpen}
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
            <TextArea
              rows={4}
              placeholder="Nhập lý do chuyển lại văn bản..."
              maxLength={500}
              showCount
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* HDSD 2.3 — MODAL TỪ CHỐI THU HỒI */}
      <Modal
        title="Từ chối yêu cầu thu hồi"
        open={tuChoiThuHoiOpen}
        onCancel={() => { setTuChoiThuHoiOpen(false); tuChoiThuHoiForm.resetFields(); }}
        onOk={handleTuChoiThuHoi}
        okText="Gửi từ chối"
        cancelText="Hủy"
        confirmLoading={tuChoiThuHoiSaving}
        width={480}
      >
        <Form form={tuChoiThuHoiForm} layout="vertical" validateTrigger="onSubmit" style={{ marginTop: 16 }}>
          <Form.Item
            name="reason"
            label="Lý do từ chối thu hồi"
            rules={[{ required: true, message: 'Vui lòng nhập lý do từ chối thu hồi' }]}
          >
            <TextArea
              rows={4}
              placeholder="Nhập lý do từ chối thu hồi..."
              maxLength={1000}
              showCount
            />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
