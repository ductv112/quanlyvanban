'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Button, Tag, Row, Col, Space, Spin, Empty, App,
  Popconfirm, Modal, Form, Input, Flex,
} from 'antd';
import {
  ArrowLeftOutlined, SwapOutlined, CheckCircleOutlined,
  RollbackOutlined, CloseCircleOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useParams, useRouter } from 'next/navigation';
import dayjs from 'dayjs';

const { TextArea } = Input;

interface LienThongDocDetail {
  id: number;
  received_date: string;
  notation: string;
  abstract: string;
  expired_date: string;
  publish_unit: string;
  publish_date: string;
  signer: string;
  sign_date: string;
  doc_type_name: string;
  doc_field_name: string;
  secret_id: number;
  urgent_id: number;
  number_paper: number;
  number_copies: number;
  recipients: string;
  status: string;
  status_label: string;
  created_by_name: string;
  created_at: string;
  unit_id: number;
}

const STATUS_MAP: Record<string, { text: string; color: string }> = {
  pending: { text: 'Chờ xử lý', color: 'gold' },
  received: { text: 'Đã nhận', color: 'cyan' },
  processing: { text: 'Đang xử lý', color: 'blue' },
  completed: { text: 'Hoàn thành', color: 'green' },
  returned: { text: 'Đã chuyển lại', color: 'orange' },
  cancelled: { text: 'Đã hủy', color: 'red' },
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
    fetchDoc().finally(() => setLoading(false));
  }, [fetchDoc]);

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

  if (loading) return <div style={{ textAlign: 'center', padding: 80 }}><Spin size="large" /></div>;
  if (!doc) return <Empty description="Không tìm thấy văn bản liên thông" />;

  const statusInfo = STATUS_MAP[doc.status] || { text: doc.status_label || 'Chờ xử lý', color: 'default' };
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
        </div>
      </div>

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
    </div>
  );
}
