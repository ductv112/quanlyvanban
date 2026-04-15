'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Modal, Radio, Input, Select, Button, Tag, Table, Space, Divider, Result, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  SafetyCertificateOutlined,
  FileProtectOutlined,
  UsbOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  LoadingOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

// ─────────────────── interfaces ───────────────────

export interface SigningModalProps {
  open: boolean;
  onClose: () => void;
  docId: number;
  docType: 'outgoing' | 'drafting';
  filePath: string;
  onSigned?: () => void;
}

interface DigitalSignatureRow {
  id: number;
  doc_id: number;
  doc_type: string;
  staff_id: number;
  staff_name: string;
  sign_method: string;
  certificate_serial: string | null;
  certificate_subject: string | null;
  certificate_issuer: string | null;
  signed_file_path: string | null;
  original_file_path: string | null;
  sign_status: string;
  error_message: string | null;
  signed_at: string | null;
  created_at: string;
}

type Step = 'choose' | 'verify' | 'result';
type SignMethod = 'smart_ca' | 'esign_neac' | 'usb_token';

interface SignResult {
  success: boolean;
  message: string;
  data?: {
    signature_id?: number;
    sign_status?: string;
    certificate_subject?: string;
    certificate_issuer?: string;
    signed_at?: string;
  };
}

// ─────────────────── constants ───────────────────

const METHOD_LABEL: Record<string, string> = {
  smart_ca: 'SmartCA (VNPT)',
  esign_neac: 'EsignNEAC',
  usb_token: 'USB Token',
};

const STATUS_MAP: Record<string, { color: string; label: string }> = {
  pending: { color: 'default', label: 'Chờ xác thực' },
  signed: { color: 'green', label: 'Đã ký' },
  error: { color: 'red', label: 'Lỗi' },
  rejected: { color: 'orange', label: 'Từ chối' },
};

const CA_PROVIDERS = [
  { value: 'vnpt-ca', label: 'VNPT CA' },
  { value: 'viettel-ca', label: 'Viettel CA' },
  { value: 'bkav-ca', label: 'BKAV CA' },
];

// ─────────────────── component ───────────────────

export default function SigningModal({
  open,
  onClose,
  docId,
  docType,
  filePath,
  onSigned,
}: SigningModalProps) {
  const { message } = App.useApp();

  const [step, setStep] = useState<Step>('choose');
  const [method, setMethod] = useState<SignMethod>('smart_ca');
  const [signatureId, setSignatureId] = useState<number | null>(null);
  const [otp, setOtp] = useState('');
  const [caProvider, setCaProvider] = useState('vnpt-ca');
  const [loading, setLoading] = useState(false);
  const [signResult, setSignResult] = useState<SignResult | null>(null);

  // Existing signatures for this doc
  const [signatures, setSignatures] = useState<DigitalSignatureRow[]>([]);
  const [sigLoading, setSigLoading] = useState(false);

  const fetchSignatures = useCallback(async () => {
    if (!docId || !open) return;
    setSigLoading(true);
    try {
      const { data: res } = await api.get(`/ky-so/doc/${docId}/${docType}`);
      setSignatures(res.data || []);
    } catch {
      // Silent
    } finally {
      setSigLoading(false);
    }
  }, [docId, docType, open]);

  useEffect(() => {
    if (open) {
      fetchSignatures();
      // Reset state when opening
      setStep('choose');
      setMethod('smart_ca');
      setSignatureId(null);
      setOtp('');
      setCaProvider('vnpt-ca');
      setSignResult(null);
    }
  }, [open, fetchSignatures]);

  // Step 1 -> Step 2: Initiate signing
  const handleInitiateSign = async () => {
    if (method === 'usb_token') return;

    setLoading(true);
    try {
      if (method === 'smart_ca') {
        const { data: res } = await api.post('/ky-so/sign/smart-ca', {
          doc_id: docId,
          doc_type: docType,
          file_path: filePath,
        });
        if (res.success) {
          setSignatureId(res.data?.signature_id || res.id || null);
          setStep('verify');
        } else {
          message.error(res.message || 'Không thể khởi tạo ký số');
        }
      } else if (method === 'esign_neac') {
        const { data: res } = await api.post('/ky-so/sign/esign-neac', {
          doc_id: docId,
          doc_type: docType,
          file_path: filePath,
          ca_provider: caProvider,
        });
        setSignResult(res);
        setStep('result');
        if (res.success) {
          fetchSignatures();
          onSigned?.();
        }
      }
    } catch (err: unknown) {
      const errMsg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message || 'Lỗi khi ký số';
      message.error(errMsg);
    } finally {
      setLoading(false);
    }
  };

  // Step 2 (SmartCA): Verify OTP
  const handleVerifyOtp = async () => {
    if (!signatureId || !otp) {
      message.warning('Vui lòng nhập mã OTP');
      return;
    }
    setLoading(true);
    try {
      const { data: res } = await api.post('/ky-so/sign/verify-otp', {
        signature_id: signatureId,
        otp,
      });
      setSignResult(res);
      setStep('result');
      if (res.success) {
        fetchSignatures();
        onSigned?.();
      }
    } catch (err: unknown) {
      const errMsg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message || 'Lỗi xác thực OTP';
      message.error(errMsg);
    } finally {
      setLoading(false);
    }
  };

  const handleClose = () => {
    onClose();
  };

  // Signature history table columns
  const sigColumns: ColumnsType<DigitalSignatureRow> = [
    {
      title: 'Người ký',
      dataIndex: 'staff_name',
      width: 150,
    },
    {
      title: 'Phương thức',
      dataIndex: 'sign_method',
      width: 130,
      render: (val: string) => METHOD_LABEL[val] || val,
    },
    {
      title: 'Trạng thái',
      dataIndex: 'sign_status',
      width: 120,
      render: (val: string) => {
        const st = STATUS_MAP[val] || { color: 'default', label: val };
        return <Tag color={st.color}>{st.label}</Tag>;
      },
    },
    {
      title: 'Thời gian ký',
      dataIndex: 'signed_at',
      width: 160,
      render: (val: string | null) => val ? dayjs(val).format('DD/MM/YYYY HH:mm') : '—',
    },
  ];

  // ─── Render steps ───

  const renderChooseStep = () => (
    <div>
      <h4 style={{ marginBottom: 16 }}>Chọn phương thức ký</h4>
      <Radio.Group
        value={method}
        onChange={(e) => setMethod(e.target.value)}
        style={{ display: 'flex', flexDirection: 'column', gap: 12 }}
      >
        <Radio value="smart_ca" style={{ fontSize: 15 }}>
          <Space>
            <SafetyCertificateOutlined style={{ color: '#0891B2' }} />
            SmartCA (VNPT)
          </Space>
        </Radio>
        <Radio value="esign_neac" style={{ fontSize: 15 }}>
          <Space>
            <FileProtectOutlined style={{ color: '#059669' }} />
            EsignNEAC
          </Space>
        </Radio>
        <Radio value="usb_token" disabled style={{ fontSize: 15 }}>
          <Space>
            <UsbOutlined style={{ color: '#94A3B8' }} />
            USB Token
            <Tag color="default">Sắp hỗ trợ</Tag>
          </Space>
        </Radio>
      </Radio.Group>

      {method === 'esign_neac' && (
        <div style={{ marginTop: 16 }}>
          <label style={{ display: 'block', marginBottom: 4, fontWeight: 500 }}>
            Nhà cung cấp CA
          </label>
          <Select
            value={caProvider}
            onChange={setCaProvider}
            options={CA_PROVIDERS}
            style={{ width: 240 }}
          />
        </div>
      )}

      <div style={{ marginTop: 24, textAlign: 'right' }}>
        <Space>
          <Button onClick={handleClose}>Hủy</Button>
          <Button
            type="primary"
            onClick={handleInitiateSign}
            loading={loading}
            disabled={method === 'usb_token'}
          >
            {method === 'esign_neac' ? 'Ký ngay' : 'Tiếp tục'}
          </Button>
        </Space>
      </div>
    </div>
  );

  const renderVerifyStep = () => (
    <div>
      <h4 style={{ marginBottom: 16 }}>Xác thực OTP</h4>
      <p style={{ color: '#64748B', marginBottom: 16 }}>
        Mã OTP đã được gửi đến ứng dụng SmartCA trên điện thoại của bạn.
        Vui lòng nhập mã gồm 6 chữ số.
      </p>
      <Input
        value={otp}
        onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
        placeholder="Nhập mã OTP 6 số"
        maxLength={6}
        style={{ width: 240, fontSize: 18, letterSpacing: 8, textAlign: 'center' }}
        onPressEnter={handleVerifyOtp}
      />
      <div style={{ marginTop: 24, textAlign: 'right' }}>
        <Space>
          <Button onClick={() => setStep('choose')}>Quay lại</Button>
          <Button
            type="primary"
            onClick={handleVerifyOtp}
            loading={loading}
            disabled={otp.length < 6}
          >
            Xác nhận OTP
          </Button>
        </Space>
      </div>
    </div>
  );

  const renderResultStep = () => {
    const isSuccess = signResult?.success;
    return (
      <div>
        <Result
          icon={isSuccess ? <CheckCircleOutlined /> : <CloseCircleOutlined />}
          status={isSuccess ? 'success' : 'error'}
          title={isSuccess ? 'Ký số thành công' : 'Ký số thất bại'}
          subTitle={signResult?.message}
          extra={
            isSuccess && signResult?.data ? (
              <div style={{ textAlign: 'left', maxWidth: 400, margin: '0 auto' }}>
                {signResult.data.certificate_subject && (
                  <p><strong>Chủ thể:</strong> {signResult.data.certificate_subject}</p>
                )}
                {signResult.data.certificate_issuer && (
                  <p><strong>Tổ chức cấp:</strong> {signResult.data.certificate_issuer}</p>
                )}
                {signResult.data.signed_at && (
                  <p><strong>Thời gian:</strong> {dayjs(signResult.data.signed_at).format('DD/MM/YYYY HH:mm:ss')}</p>
                )}
              </div>
            ) : null
          }
        />
        <div style={{ textAlign: 'right' }}>
          <Button type="primary" onClick={handleClose}>
            Đóng
          </Button>
        </div>
      </div>
    );
  };

  const renderStepContent = () => {
    switch (step) {
      case 'choose': return renderChooseStep();
      case 'verify': return renderVerifyStep();
      case 'result': return renderResultStep();
    }
  };

  const modalTitle = () => {
    switch (step) {
      case 'choose': return 'Ký số văn bản';
      case 'verify': return 'Xác thực OTP';
      case 'result': return 'Kết quả ký số';
    }
  };

  return (
    <Modal
      open={open}
      title={modalTitle()}
      onCancel={handleClose}
      footer={null}
      width={640}
      destroyOnHidden
    >
      {loading && step === 'choose' ? (
        <div style={{ textAlign: 'center', padding: 40 }}>
          <LoadingOutlined style={{ fontSize: 32, color: '#0891B2' }} />
          <p style={{ marginTop: 16, color: '#64748B' }}>Đang xử lý ký số...</p>
        </div>
      ) : (
        renderStepContent()
      )}

      {/* Existing signatures for this document */}
      {signatures.length > 0 && (
        <>
          <Divider />
          <h4 style={{ marginBottom: 12 }}>Lịch sử chữ ký số</h4>
          <Table<DigitalSignatureRow>
            rowKey="id"
            columns={sigColumns}
            dataSource={signatures}
            loading={sigLoading}
            pagination={false}
            size="small"
          />
        </>
      )}
    </Modal>
  );
}
