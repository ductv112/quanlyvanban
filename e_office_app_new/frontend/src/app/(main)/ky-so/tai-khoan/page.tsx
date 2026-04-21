'use client';

/**
 * Trang: /ky-so/tai-khoan — Tài khoản ký số cá nhân (mọi user)
 *
 * Mỗi user tự cấu hình user_id (+ credential_id cho MySign) theo provider đang
 * active — form dynamic theo provider_code. Button "Kiểm tra kết nối" verify
 * config qua provider listCertificates và cập nhật badge "Đã xác thực".
 *
 * API (Plan 10-01):
 *   GET    /ky-so/tai-khoan              → { active, config }
 *   POST   /ky-so/tai-khoan              → upsert config
 *   POST   /ky-so/tai-khoan/certificates → list cert cho MySign "Tải danh sách CTS"
 *   POST   /ky-so/tai-khoan/verify       → verify + lưu cert snapshot
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card,
  Button,
  Input,
  Form,
  Alert,
  Tag,
  Space,
  App,
  Skeleton,
  Select,
  Tooltip,
  Descriptions,
} from 'antd';
import {
  SafetyCertificateOutlined,
  CheckCircleOutlined,
  WarningOutlined,
  ReloadOutlined,
  SaveOutlined,
  QuestionCircleOutlined,
  ExclamationCircleOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';

// ============================================================================
// Types — match Plan 10-01 API response shape
// ============================================================================

type ProviderCode = 'SMARTCA_VNPT' | 'MYSIGN_VIETTEL';

interface ActiveProvider {
  provider_code: ProviderCode;
  provider_name: string;
  base_url: string;
}

interface UserConfig {
  staff_id: number;
  provider_code: string;
  user_id: string;
  credential_id: string | null;
  certificate_subject: string | null;
  certificate_serial: string | null;
  is_verified: boolean;
  last_verified_at: string | null;
}

interface ClientCert {
  credential_id: string;
  subject: string;
  serial_number: string;
  valid_from: string;
  valid_to: string;
  status: string;
}

interface FormValues {
  user_id: string;
  credential_id?: string;
}

interface GetResponse {
  success: boolean;
  data: {
    active: ActiveProvider | null;
    config: UserConfig | null;
    message?: string;
  };
}

interface CertificatesResponse {
  success: boolean;
  data: { certificates: ClientCert[] };
}

interface VerifyResponse {
  success: boolean;
  data: {
    verified: boolean;
    message?: string;
    certificate_subject?: string;
    cert_valid_to?: string;
    last_verified_at?: string;
  };
}

// ============================================================================
// Constants
// ============================================================================

// Provider-specific UI metadata
const PROVIDER_UX: Record<
  ProviderCode,
  {
    userIdLabel: string;
    userIdTooltip: string;
    userIdPlaceholder: string;
    needsCertList: boolean;
  }
> = {
  SMARTCA_VNPT: {
    userIdLabel: 'Mã định danh SmartCA',
    userIdTooltip:
      'Số CMND/CCCD hoặc Mã định danh đã đăng ký với VNPT SmartCA',
    userIdPlaceholder: 'Ví dụ: 012345678901',
    needsCertList: false,
  },
  MYSIGN_VIETTEL: {
    userIdLabel: 'Mã định danh MySign',
    userIdTooltip:
      'Mã định danh cá nhân đã đăng ký với Viettel MySign (do Viettel cấp)',
    userIdPlaceholder: 'Ví dụ: CMT_123456',
    needsCertList: true,
  },
};

// ============================================================================
// Helpers
// ============================================================================

function formatDateTime(iso: string | null): string {
  if (!iso) return '—';
  try {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return '—';
    return d.toLocaleString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return '—';
  }
}

function formatDate(iso: string): string {
  if (!iso) return '—';
  try {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return iso;
    return d.toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
    });
  } catch {
    return iso;
  }
}

// ============================================================================
// Component
// ============================================================================

export default function KySoTaiKhoanPage() {
  const { message } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const [form] = Form.useForm<FormValues>();

  // Data state
  const [loading, setLoading] = useState(true);
  const [active, setActive] = useState<ActiveProvider | null>(null);
  const [config, setConfig] = useState<UserConfig | null>(null);
  const [activeMessage, setActiveMessage] = useState<string | null>(null);

  // Certificates (MySign only)
  const [certificates, setCertificates] = useState<ClientCert[]>([]);
  const [loadingCerts, setLoadingCerts] = useState(false);

  // Action loading states
  const [saving, setSaving] = useState(false);
  const [verifying, setVerifying] = useState(false);

  // ──────────────────────────────────────────────────────────────────────────
  // Data fetching
  // ──────────────────────────────────────────────────────────────────────────

  const fetchConfig = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get<GetResponse>('/ky-so/tai-khoan');
      const nextActive = res.data?.active ?? null;
      const nextConfig = res.data?.config ?? null;
      setActive(nextActive);
      setConfig(nextConfig);
      setActiveMessage(res.data?.message ?? null);

      if (nextConfig) {
        form.setFieldsValue({
          user_id: nextConfig.user_id,
          credential_id: nextConfig.credential_id ?? undefined,
        });
      } else {
        form.resetFields();
      }
    } catch (err) {
      const msg =
        (err as { response?: { data?: { message?: string } } })?.response?.data
          ?.message ?? 'Không tải được cấu hình';
      message.error(msg);
    } finally {
      setLoading(false);
    }
  }, [form, message]);

  useEffect(() => {
    if (user) fetchConfig();
  }, [user, fetchConfig]);

  // ──────────────────────────────────────────────────────────────────────────
  // Fetch certificates (MySign — "Tải danh sách CTS")
  // ──────────────────────────────────────────────────────────────────────────

  const onLoadCertificates = async () => {
    const userId = (form.getFieldValue('user_id') ?? '').toString().trim();
    if (!userId) {
      form.setFields([
        { name: 'user_id', errors: ['Vui lòng nhập Mã định danh trước'] },
      ]);
      return;
    }
    try {
      setLoadingCerts(true);
      const { data: res } = await api.post<CertificatesResponse>(
        '/ky-so/tai-khoan/certificates',
        { user_id: userId },
      );
      const certs = res.data?.certificates ?? [];
      setCertificates(certs);
      if (certs.length === 0) {
        message.warning(
          'Không tìm thấy chứng thư nào cho mã định danh này',
        );
      } else {
        message.success(`Đã tải ${certs.length} chứng thư số`);
      }
    } catch (err) {
      const msg =
        (err as { response?: { data?: { message?: string } } })?.response?.data
          ?.message ?? 'Không tải được danh sách chứng thư';
      message.error(msg);
      setCertificates([]);
    } finally {
      setLoadingCerts(false);
    }
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Save & Verify
  // ──────────────────────────────────────────────────────────────────────────

  const setBackendFieldError = (msg: string): boolean => {
    const map: Record<string, keyof FormValues> = {
      'Vui lòng nhập user_id': 'user_id',
      'Vui lòng nhập user_id (không quá 200 ký tự)': 'user_id',
    };
    // Credential-related messages → inline credential_id field
    if (msg.includes('chứng thư số') || msg.includes('chứng thư')) {
      form.setFields([{ name: 'credential_id', errors: [msg] }]);
      return true;
    }
    const field = map[msg];
    if (field) {
      form.setFields([{ name: field, errors: [msg] }]);
      return true;
    }
    return false;
  };

  const onSave = async () => {
    if (!active) return;
    try {
      const values = await form.validateFields();
      setSaving(true);
      await api.post('/ky-so/tai-khoan', {
        user_id: values.user_id.trim(),
        credential_id: values.credential_id?.trim() || null,
      });
      message.success(
        'Lưu cấu hình thành công. Vui lòng bấm "Kiểm tra kết nối" để xác thực.',
      );
      await fetchConfig();
    } catch (err) {
      const httpErr = err as {
        response?: { data?: { message?: string } };
        errorFields?: unknown[];
      };
      // Form validation error (AntD) — AntD đã hiển thị inline, không toast
      if (httpErr?.errorFields) return;
      const msg =
        httpErr?.response?.data?.message ?? 'Lưu cấu hình thất bại';
      if (!setBackendFieldError(msg)) message.error(msg);
    } finally {
      setSaving(false);
    }
  };

  const onVerify = async () => {
    if (!active || !config) {
      message.warning('Vui lòng lưu cấu hình trước khi kiểm tra');
      return;
    }
    try {
      setVerifying(true);
      const { data: res } = await api.post<VerifyResponse>(
        '/ky-so/tai-khoan/verify',
      );
      if (res.data?.verified) {
        message.success('Kiểm tra thành công — chứng thư hợp lệ');
        await fetchConfig();
      } else {
        // Verify returned 200 but verified=false (business outcome, not error)
        message.warning(
          res.data?.message ?? 'Kiểm tra thất bại — chứng thư không hợp lệ',
        );
        // Re-fetch để lấy last_error persist từ backend (optional)
        await fetchConfig();
      }
    } catch (err) {
      const msg =
        (err as { response?: { data?: { message?: string } } })?.response?.data
          ?.message ?? 'Không kết nối được provider';
      message.error(msg);
    } finally {
      setVerifying(false);
    }
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Guards
  // ──────────────────────────────────────────────────────────────────────────

  if (!user) {
    return (
      <div>
        <Skeleton active paragraph={{ rows: 6 }} />
      </div>
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Render
  // ──────────────────────────────────────────────────────────────────────────

  const providerMeta = active ? PROVIDER_UX[active.provider_code] : null;
  const needsCertList = providerMeta?.needsCertList ?? false;

  return (
    <div>
      {/* Page Header */}
      <div className="page-header">
        <h2 className="page-title">
          <SafetyCertificateOutlined style={{ color: '#0891B2' }} />
          Tài khoản ký số cá nhân
        </h2>
        <p className="page-description">
          Cấu hình tài khoản ký số của bạn theo nhà cung cấp dịch vụ mà hệ
          thống đang sử dụng.
        </p>
      </div>

      {loading ? (
        <Card className="page-card" variant="borderless">
          <Skeleton active paragraph={{ rows: 5 }} />
        </Card>
      ) : !active ? (
        /* Empty state — admin chưa kích hoạt provider */
        <Card className="page-card" variant="borderless">
          <Alert
            type="warning"
            showIcon
            icon={<ExclamationCircleOutlined />}
            style={{ borderRadius: 12 }}
            title="Hệ thống chưa kích hoạt provider ký số"
            description={
              <Space direction="vertical" size={8}>
                <span>
                  {activeMessage ??
                    'Vui lòng liên hệ Quản trị viên để cấu hình và kích hoạt nhà cung cấp dịch vụ ký số.'}
                </span>
                <Button
                  icon={<ReloadOutlined />}
                  size="small"
                  onClick={fetchConfig}
                >
                  Làm mới
                </Button>
              </Space>
            }
          />
        </Card>
      ) : (
        <>
          {/* Card 1 — Active provider info */}
          <Alert
            type="info"
            showIcon
            style={{ marginBottom: 16, borderRadius: 12 }}
            title={
              <div
                style={{
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'space-between',
                  flexWrap: 'wrap',
                  gap: 8,
                }}
              >
                <span>
                  <strong>Provider đang hoạt động:</strong>{' '}
                  {active.provider_name}
                  <span
                    style={{
                      marginLeft: 8,
                      color: '#64748B',
                      fontSize: 12,
                      fontFamily: 'monospace',
                    }}
                  >
                    ({active.base_url})
                  </span>
                </span>
                <Button
                  icon={<ReloadOutlined />}
                  size="small"
                  onClick={fetchConfig}
                >
                  Làm mới
                </Button>
              </div>
            }
          />

          {/* Card 2 — Config form */}
          <Card
            className="page-card"
            variant="borderless"
            title={
              <Space>
                <span>Cấu hình tài khoản</span>
                {config?.is_verified ? (
                  <Tooltip title={config.certificate_subject ?? ''}>
                    <Tag
                      color="success"
                      icon={<CheckCircleOutlined />}
                      style={{ margin: 0 }}
                    >
                      Đã xác thực
                    </Tag>
                  </Tooltip>
                ) : (
                  <Tag
                    color="warning"
                    icon={<WarningOutlined />}
                    style={{ margin: 0 }}
                  >
                    Chưa xác thực
                  </Tag>
                )}
              </Space>
            }
            extra={
              config?.is_verified && config.last_verified_at ? (
                <span style={{ fontSize: 12, color: '#64748B' }}>
                  Kiểm tra gần nhất:{' '}
                  {formatDateTime(config.last_verified_at)}
                </span>
              ) : null
            }
          >
            <Form
              form={form}
              layout="vertical"
              autoComplete="off"
              validateTrigger="onSubmit"
            >
              <Form.Item
                name="user_id"
                label={
                  <span>
                    {providerMeta?.userIdLabel ?? 'Mã định danh'}{' '}
                    <Tooltip title={providerMeta?.userIdTooltip ?? ''}>
                      <QuestionCircleOutlined
                        style={{ color: '#94A3B8', fontSize: 13 }}
                      />
                    </Tooltip>
                  </span>
                }
                rules={[
                  {
                    required: true,
                    message: `Vui lòng nhập ${
                      providerMeta?.userIdLabel ?? 'mã định danh'
                    }`,
                  },
                  { max: 200, message: 'Tối đa 200 ký tự' },
                ]}
              >
                <Input
                  maxLength={200}
                  placeholder={providerMeta?.userIdPlaceholder ?? ''}
                  allowClear
                />
              </Form.Item>

              {needsCertList && (
                <>
                  <Form.Item>
                    <Space wrap size={8}>
                      <Button
                        icon={<ReloadOutlined />}
                        onClick={onLoadCertificates}
                        loading={loadingCerts}
                      >
                        Tải danh sách chứng thư từ MySign
                      </Button>
                      <span
                        style={{
                          fontSize: 12,
                          color: '#94A3B8',
                        }}
                      >
                        Nhập Mã định danh trước, sau đó bấm để lấy danh sách
                        chứng thư.
                      </span>
                    </Space>
                  </Form.Item>

                  <Form.Item
                    name="credential_id"
                    label={
                      <span>
                        Chứng thư số{' '}
                        <Tooltip title="Chọn một trong các chứng thư số đã tải về từ MySign">
                          <QuestionCircleOutlined
                            style={{ color: '#94A3B8', fontSize: 13 }}
                          />
                        </Tooltip>
                      </span>
                    }
                    rules={[
                      {
                        required: true,
                        message: 'Vui lòng chọn chứng thư số',
                      },
                    ]}
                  >
                    <Select
                      placeholder={
                        certificates.length === 0
                          ? 'Bấm "Tải danh sách chứng thư" để chọn'
                          : 'Chọn chứng thư số'
                      }
                      disabled={certificates.length === 0}
                      options={certificates.map((c) => ({
                        value: c.credential_id,
                        label: `${c.subject} (hết hạn: ${formatDate(
                          c.valid_to,
                        )})`,
                      }))}
                      allowClear
                    />
                  </Form.Item>
                </>
              )}

              {/* Cert info when verified */}
              {config?.is_verified && config.certificate_subject && (
                <Descriptions
                  column={1}
                  size="small"
                  bordered
                  style={{ marginBottom: 16 }}
                  labelStyle={{
                    width: 160,
                    background: '#F8FAFC',
                    color: '#64748B',
                  }}
                >
                  <Descriptions.Item label="Chủ thể chứng thư">
                    <span
                      style={{ fontFamily: 'monospace', fontSize: 12 }}
                    >
                      {config.certificate_subject}
                    </span>
                  </Descriptions.Item>
                  {config.certificate_serial && (
                    <Descriptions.Item label="Số serial">
                      <span
                        style={{ fontFamily: 'monospace', fontSize: 12 }}
                      >
                        {config.certificate_serial}
                      </span>
                    </Descriptions.Item>
                  )}
                </Descriptions>
              )}

              {/* Actions */}
              <Space wrap size={8}>
                <Button
                  type="primary"
                  icon={<SaveOutlined />}
                  loading={saving}
                  onClick={onSave}
                >
                  Lưu cấu hình
                </Button>
                <Tooltip
                  title={
                    !config
                      ? 'Vui lòng lưu cấu hình trước khi kiểm tra kết nối'
                      : 'Kết nối tới provider để xác thực user_id và chứng thư'
                  }
                >
                  <Button
                    icon={<CheckCircleOutlined />}
                    loading={verifying}
                    disabled={!config}
                    onClick={onVerify}
                  >
                    Kiểm tra kết nối
                  </Button>
                </Tooltip>
              </Space>
            </Form>
          </Card>
        </>
      )}
    </div>
  );
}
