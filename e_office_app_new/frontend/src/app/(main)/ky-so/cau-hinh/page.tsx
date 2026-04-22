'use client';

/**
 * Trang: /ky-so/cau-hinh — Cấu hình ký số hệ thống (Admin only)
 *
 * Thiết kế (fix patch 09-03):
 *  - Hệ thống CHỈ HỖ TRỢ 2 provider cố định: SmartCA VNPT + MySign Viettel
 *  - Không còn button "Thêm mới" và không còn "Xóa" — 2 provider được seed sẵn
 *    bởi migration 043, Admin CHỈ sửa/kích hoạt.
 *
 * Layout (top → bottom):
 *  1. Page header
 *  2. Alert trạng thái provider đang hoạt động (hoặc warning nếu chưa có)
 *  3. 5 Stat cards KPI (luôn hiển thị stats của provider đang active, không có tabs)
 *  4. 2 Card provider song song (Row 2 Col) với actions: "Sửa cấu hình" + "Kích hoạt"
 *  5. Drawer "Sửa cấu hình — {provider_name}" (không còn radio chọn provider type)
 *
 * Security:
 *  - client_secret trả về từ GET là '***' (server mask)
 *  - Edit: field secret để trống → backend giữ nguyên ciphertext cũ
 *  - Submit/test: payload client_secret là plaintext (HTTPS), backend encrypt trước khi lưu
 *
 * API (Plan 09-02 + patch 09-03):
 *  GET    /ky-so/cau-hinh                  → { data: { providers: [has_secret,...], active_code } }
 *  POST   /ky-so/cau-hinh/test-connection  → test với credentials user vừa nhập (plaintext trong body)
 *  POST   /ky-so/cau-hinh/:id/test-saved   → test với credentials đã lưu trong DB (không cần user nhập)
 *  PUT    /ky-so/cau-hinh/:id              → update (bắt buộc có id tồn tại)
 *  PATCH  /ky-so/cau-hinh/:id/active       → activate (auto-deactivate others)
 *  POST   /ky-so/cau-hinh                  → 405 (disabled)
 *  DELETE /ky-so/cau-hinh/:id              → 405 (disabled)
 */

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Card,
  Button,
  Input,
  Form,
  Drawer,
  Tag,
  Alert,
  Row,
  Col,
  Space,
  App,
  Empty,
  Skeleton,
  Descriptions,
  Badge,
  Tooltip,
} from 'antd';
import {
  SafetyCertificateOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  ThunderboltOutlined,
  TeamOutlined,
  AuditOutlined,
  RiseOutlined,
  EditOutlined,
  PoweroffOutlined,
  ReloadOutlined,
  WarningOutlined,
  ExclamationCircleOutlined,
  LockOutlined,
  DatabaseOutlined,
  KeyOutlined,
  QuestionCircleOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';

// ============================================================================
// Types — match GET /ky-so/cau-hinh response shape
// ============================================================================

type ProviderCode = 'SMARTCA_VNPT' | 'MYSIGN_VIETTEL';

interface ProviderStats {
  total_users: number;
  verified_users: number;
  monthly_transactions: number;
  monthly_completed: number;
  monthly_failed: number;
}

interface ProviderConfig {
  id: number | null;
  provider_code: ProviderCode;
  provider_name: string;
  base_url: string | null;
  client_id: string | null;
  profile_id: string | null;
  extra_config: Record<string, unknown>;
  is_active: boolean;
  last_tested_at: string | null;
  test_result: string | null;
  created_at: string | null;
  updated_at: string | null;
  has_secret: boolean;
  client_secret_masked: '***' | null;
  stats: ProviderStats;
}

interface FormValues {
  base_url: string;
  client_id: string;
  client_secret?: string;
  profile_id?: string;
}

interface TestResultState {
  ok: boolean;
  message: string;
  subject?: string | null;
  /**
   * 'new'  — test với secret user vừa nhập trong form (plaintext body)
   * 'saved' — test với credentials đã lưu trong DB (endpoint /:id/test-saved)
   */
  source: 'new' | 'saved';
  durationMs?: number;
}

// ============================================================================
// Constants
// ============================================================================

const PROVIDER_META: Record<
  ProviderCode,
  { label: string; baseUrlHint: string; needsProfileId: boolean }
> = {
  SMARTCA_VNPT: {
    label: 'SmartCA VNPT',
    baseUrlHint: 'https://gwsca.vnpt.vn',
    needsProfileId: false,
  },
  MYSIGN_VIETTEL: {
    label: 'MySign Viettel',
    baseUrlHint: 'https://remotesigning.viettel.vn',
    needsProfileId: true,
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

// ============================================================================
// Component
// ============================================================================

export default function KySoCauHinhPage() {
  const { message, modal } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const [form] = Form.useForm<FormValues>();

  // Data state
  const [loading, setLoading] = useState(true);
  const [providers, setProviders] = useState<ProviderConfig[]>([]);
  const [activeCode, setActiveCode] = useState<ProviderCode | null>(null);

  // Drawer state
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<ProviderConfig | null>(null);

  // Test connection state
  // testingSource: null khi idle, 'new' | 'saved' khi đang test (deduplicate 2 button)
  const [testingSource, setTestingSource] = useState<'new' | 'saved' | null>(null);
  const [testedOk, setTestedOk] = useState(false);
  const [testResult, setTestResult] = useState<TestResultState | null>(null);
  // Có thực sự user đã gõ secret mới trong form? — enable/disable button "test secret mới"
  const [secretDirty, setSecretDirty] = useState(false);

  // Save state
  const [saving, setSaving] = useState(false);

  // Activating state (when user clicks "Kích hoạt" on card footer)
  const [activatingCode, setActivatingCode] = useState<ProviderCode | null>(null);

  // ──────────────────────────────────────────────────────────────────────────
  // Data fetching
  // ──────────────────────────────────────────────────────────────────────────

  const fetchConfig = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get<{
        success: boolean;
        data: { providers: ProviderConfig[]; active_code: ProviderCode | null };
      }>('/ky-so/cau-hinh');
      const list = res.data?.providers ?? [];
      const active = res.data?.active_code ?? null;
      setProviders(list);
      setActiveCode(active);
    } catch (err) {
      const msg =
        (err as { response?: { data?: { message?: string } } })?.response?.data?.message
        ?? 'Không tải được cấu hình ký số';
      message.error(msg);
    } finally {
      setLoading(false);
    }
  }, [message]);

  useEffect(() => {
    if (user?.isAdmin) {
      fetchConfig();
    }
  }, [user?.isAdmin, fetchConfig]);

  // ──────────────────────────────────────────────────────────────────────────
  // Derived values
  // ──────────────────────────────────────────────────────────────────────────

  const activeProvider = useMemo(
    () => providers.find((p) => p.provider_code === activeCode) ?? null,
    [providers, activeCode],
  );

  // Stats hiển thị từ provider đang active (không có switcher tab)
  const displayStats: ProviderStats | null = activeProvider?.stats ?? null;

  const smartcaProvider = providers.find((p) => p.provider_code === 'SMARTCA_VNPT') ?? null;
  const mysignProvider = providers.find((p) => p.provider_code === 'MYSIGN_VIETTEL') ?? null;

  // ──────────────────────────────────────────────────────────────────────────
  // Drawer handlers
  // ──────────────────────────────────────────────────────────────────────────

  const handleEdit = (record: ProviderConfig) => {
    setEditingRecord(record);
    form.resetFields();
    form.setFieldsValue({
      base_url: record.base_url ?? '',
      client_id: record.client_id ?? '',
      client_secret: '',
      profile_id: record.profile_id ?? '',
    });
    setTestedOk(false);
    setTestResult(null);
    setSecretDirty(false);
    setTestingSource(null);
    setDrawerOpen(true);
  };

  const handleCloseDrawer = () => {
    setDrawerOpen(false);
    setEditingRecord(null);
    setTestedOk(false);
    setTestResult(null);
    setSecretDirty(false);
    setTestingSource(null);
    form.resetFields();
  };

  // Map backend validation error msgs → inline field errors
  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, keyof FormValues> = {
      'base_url là bắt buộc': 'base_url',
      'base_url phải là HTTPS (trừ localhost)': 'base_url',
      'client_id là bắt buộc': 'client_id',
      'client_id là bắt buộc (≤ 200 ký tự)': 'client_id',
      'client_secret là bắt buộc': 'client_secret',
      'client_secret tối thiểu 8 ký tự': 'client_secret',
    };
    const fieldName = fieldErrorMap[errorMessage];
    if (fieldName) {
      form.setFields([{ name: fieldName, errors: [errorMessage] }]);
      return true;
    }
    return false;
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Test connection — 2 variant:
  //   • onTestConnection      — dùng plaintext user vừa nhập trong form (không persist DB)
  //   • onTestSavedConnection — dùng credentials đã lưu trong DB (persist last_tested_at)
  // ──────────────────────────────────────────────────────────────────────────

  const onTestConnection = async () => {
    if (!editingRecord) return;
    try {
      const fieldsToValidate: Array<keyof FormValues> = ['base_url', 'client_id', 'client_secret'];
      if (PROVIDER_META[editingRecord.provider_code].needsProfileId) {
        fieldsToValidate.push('profile_id');
      }
      const values = await form.validateFields(fieldsToValidate);

      if (!values.client_secret || values.client_secret.length < 1) {
        form.setFields([
          { name: 'client_secret', errors: ['Nhập client_secret để kiểm tra kết nối'] },
        ]);
        return;
      }

      setTestingSource('new');
      setTestResult(null);

      const startedAt = Date.now();
      const { data: res } = await api.post<{
        success: boolean;
        data: {
          test_result: 'OK' | 'FAILED';
          message: string;
          certificate_subject: string | null;
        };
      }>('/ky-so/cau-hinh/test-connection', {
        provider_code: editingRecord.provider_code,
        base_url: values.base_url,
        client_id: values.client_id,
        client_secret: values.client_secret,
        profile_id: values.profile_id ?? null,
      });
      const durationMs = Date.now() - startedAt;

      if (res.data?.test_result === 'OK') {
        setTestedOk(true);
        setTestResult({
          ok: true,
          message: res.data.message,
          subject: res.data.certificate_subject,
          source: 'new',
          durationMs,
        });
        message.success('Kiểm tra kết nối thành công');
      } else {
        setTestedOk(false);
        setTestResult({
          ok: false,
          message: res.data?.message ?? 'Kết nối thất bại',
          source: 'new',
          durationMs,
        });
      }
    } catch (err) {
      setTestedOk(false);
      const httpErr = err as {
        response?: { data?: { message?: string } };
        errorFields?: unknown[];
      };
      if (httpErr?.errorFields) return;
      const msg = httpErr?.response?.data?.message ?? 'Không kết nối được provider';
      setTestResult({ ok: false, message: msg, source: 'new' });
    } finally {
      setTestingSource(null);
    }
  };

  /**
   * Test config đã lưu trong DB — gọi POST /:id/test-saved.
   * Không cần form values (ngoại trừ id editingRecord). Backend decrypt secret và
   * persist last_tested_at. Guard "chưa cấu hình" được backend trả 400.
   */
  const onTestSavedConnection = async () => {
    if (!editingRecord || !editingRecord.id) {
      message.warning('Không tìm thấy cấu hình provider đang sửa');
      return;
    }
    try {
      setTestingSource('saved');
      setTestResult(null);

      const { data: res } = await api.post<{
        success: boolean;
        data: {
          ok: boolean;
          test_result: 'OK' | 'FAILED';
          message: string;
          certificate_subject: string | null;
          duration_ms: number;
        };
      }>(`/ky-so/cau-hinh/${editingRecord.id}/test-saved`);

      if (res.data?.ok) {
        // testedOk KHÔNG set true ở đây — testedOk dành cho flow "Lưu & Kích hoạt"
        // (yêu cầu test với secret mới). Test saved chỉ là verify config hiện tại.
        setTestResult({
          ok: true,
          message: res.data.message,
          subject: res.data.certificate_subject,
          source: 'saved',
          durationMs: res.data.duration_ms,
        });
        message.success('Kiểm tra cấu hình đã lưu thành công');
        // Refresh list để card hiển thị last_tested_at + test_result mới
        fetchConfig();
      } else {
        setTestResult({
          ok: false,
          message: res.data?.message ?? 'Kết nối thất bại',
          source: 'saved',
          durationMs: res.data?.duration_ms,
        });
      }
    } catch (err) {
      const httpErr = err as {
        response?: { data?: { message?: string } };
      };
      const msg = httpErr?.response?.data?.message ?? 'Không kết nối được provider';
      setTestResult({ ok: false, message: msg, source: 'saved' });
    } finally {
      setTestingSource(null);
    }
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Save (với option kích hoạt sau khi lưu)
  // ──────────────────────────────────────────────────────────────────────────

  const handleSave = async (withActivate: boolean) => {
    if (!editingRecord || !editingRecord.id) {
      message.error('Không tìm thấy cấu hình provider đang sửa');
      return;
    }
    try {
      const values = await form.validateFields();
      setSaving(true);

      const payload: Record<string, unknown> = {
        provider_code: editingRecord.provider_code,
        provider_name: editingRecord.provider_name,
        base_url: values.base_url,
        client_id: values.client_id,
        profile_id: values.profile_id?.trim() || null,
      };

      // Chỉ gửi client_secret nếu user nhập — nếu trống, backend giữ ciphertext cũ
      if (values.client_secret && values.client_secret.length > 0) {
        payload.client_secret = values.client_secret;
      }

      await api.put(`/ky-so/cau-hinh/${editingRecord.id}`, payload);

      // Kích hoạt sau khi lưu (nếu được yêu cầu)
      if (withActivate) {
        try {
          await api.patch(`/ky-so/cau-hinh/${editingRecord.id}/active`);
        } catch (activateErr) {
          const msg =
            (activateErr as { response?: { data?: { message?: string } } })?.response?.data
              ?.message ?? 'Kích hoạt thất bại';
          message.warning(`Lưu thành công. ${msg}`);
          handleCloseDrawer();
          await fetchConfig();
          setSaving(false);
          return;
        }
      }

      message.success(
        withActivate ? 'Lưu và kích hoạt cấu hình thành công' : 'Cập nhật cấu hình thành công',
      );
      handleCloseDrawer();
      await fetchConfig();
    } catch (err) {
      const httpErr = err as {
        response?: { data?: { message?: string } };
        errorFields?: unknown[];
      };
      if (httpErr?.errorFields) {
        setSaving(false);
        return;
      }
      const msg = httpErr?.response?.data?.message ?? 'Lưu cấu hình thất bại';
      if (!setBackendFieldError(msg)) {
        message.error(msg);
      }
    } finally {
      setSaving(false);
    }
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Kích hoạt provider (từ card footer)
  // ──────────────────────────────────────────────────────────────────────────

  const handleActivate = (record: ProviderConfig) => {
    if (!record.id) {
      message.warning('Provider này chưa được cấu hình');
      return;
    }
    if (record.is_active) {
      message.info('Provider này đang được kích hoạt');
      return;
    }

    // Nếu chưa test OK thì cảnh báo
    if (record.test_result !== 'OK') {
      modal.warning({
        title: 'Không thể kích hoạt',
        content: (
          <div>
            <p>
              Không thể kích hoạt provider <strong>{record.provider_name}</strong> khi chưa kiểm
              tra kết nối thành công.
            </p>
            <p style={{ color: '#64748B', marginBottom: 0 }}>
              Vui lòng bấm <strong>&quot;Sửa cấu hình&quot;</strong>, nhập đầy đủ thông tin, bấm{' '}
              <strong>&quot;Kiểm tra kết nối&quot;</strong> cho kết quả OK, rồi mới có thể kích
              hoạt.
            </p>
          </div>
        ),
        okText: 'Đã hiểu',
      });
      return;
    }

    modal.confirm({
      title: 'Kích hoạt provider',
      content: (
        <div>
          <p>
            Kích hoạt <strong>&quot;{record.provider_name}&quot;</strong>?
          </p>
          <p style={{ color: '#64748B', marginBottom: 0 }}>
            Provider đang hoạt động khác (nếu có) sẽ tự động bị tắt.
          </p>
        </div>
      ),
      okText: 'Kích hoạt',
      cancelText: 'Hủy',
      onOk: async () => {
        setActivatingCode(record.provider_code);
        try {
          await api.patch(`/ky-so/cau-hinh/${record.id}/active`);
          message.success(`Đã kích hoạt ${record.provider_name}`);
          await fetchConfig();
        } catch (err) {
          const msg =
            (err as { response?: { data?: { message?: string } } })?.response?.data?.message
            ?? 'Kích hoạt thất bại';
          message.error(msg);
        } finally {
          setActivatingCode(null);
        }
      },
    });
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Guards
  // ──────────────────────────────────────────────────────────────────────────

  if (!user) {
    return (
      <div>
        <Skeleton active paragraph={{ rows: 8 }} />
      </div>
    );
  }

  if (!user.isAdmin) {
    return (
      <div style={{ padding: 40 }}>
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description="Bạn không có quyền truy cập trang này"
        />
      </div>
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Provider card renderer
  // ──────────────────────────────────────────────────────────────────────────

  const renderProviderCard = (
    provider: ProviderConfig | null,
    code: ProviderCode,
    gradient: string,
  ) => {
    const meta = PROVIDER_META[code];
    const isActive = provider?.is_active ?? false;
    const isConfigured = !!provider?.id;
    const isActivating = activatingCode === code;

    return (
      <Card
        className="page-card"
        variant="borderless"
        style={{
          height: '100%',
          border: isActive ? '2px solid #059669' : '1px solid #E2E8F0',
          boxShadow: isActive
            ? '0 4px 16px rgba(5, 150, 105, 0.15)'
            : '0 2px 8px rgba(27, 58, 92, 0.06)',
        }}
        styles={{ body: { padding: 20 } }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div
              style={{
                width: 36,
                height: 36,
                borderRadius: 10,
                background: gradient,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                color: '#fff',
                fontSize: 16,
              }}
            >
              <SafetyCertificateOutlined />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontWeight: 600, fontSize: 15, color: '#1B3A5C' }}>{meta.label}</div>
              <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 2 }}>
                {isActive ? 'Provider mặc định hệ thống' : 'Provider phụ'}
              </div>
            </div>
            {isActive ? (
              <Tag
                color="success"
                icon={<CheckCircleOutlined />}
                style={{ margin: 0, fontWeight: 600 }}
              >
                Đang kích hoạt
              </Tag>
            ) : (
              <Tag color="default" style={{ margin: 0 }}>
                Không hoạt động
              </Tag>
            )}
          </div>
        }
      >
        {!provider ? (
          <Empty description="Đang tải dữ liệu provider..." />
        ) : (
          <>
            <Descriptions
              column={1}
              size="small"
              styles={{
                label: { width: 130, color: '#64748B', fontSize: 13 },
                content: { fontSize: 13, color: '#1B3A5C' },
              }}
            >
              <Descriptions.Item label="Base URL">
                {provider.base_url ? (
                  <Tooltip title={provider.base_url}>
                    <span style={{ fontFamily: 'monospace', fontSize: 12 }}>
                      {provider.base_url}
                    </span>
                  </Tooltip>
                ) : (
                  <Tag color="warning" style={{ margin: 0 }}>
                    Chưa cấu hình
                  </Tag>
                )}
              </Descriptions.Item>
              <Descriptions.Item label="Client ID">
                {provider.client_id ? (
                  <Tooltip title={provider.client_id}>
                    <span style={{ fontFamily: 'monospace', fontSize: 12 }}>
                      {provider.client_id.length > 40
                        ? `${provider.client_id.slice(0, 37)}...`
                        : provider.client_id}
                    </span>
                  </Tooltip>
                ) : (
                  <span style={{ color: '#94A3B8' }}>—</span>
                )}
              </Descriptions.Item>
              <Descriptions.Item label="Client Secret">
                {provider.has_secret ? (
                  <Badge
                    status="success"
                    text={
                      <span style={{ fontFamily: 'monospace', fontSize: 12, color: '#1B3A5C' }}>
                        ***
                      </span>
                    }
                  />
                ) : (
                  <span style={{ color: '#94A3B8' }}>—</span>
                )}
              </Descriptions.Item>
              {meta.needsProfileId && (
                <Descriptions.Item label="Profile ID">
                  {provider.profile_id ? (
                    <span style={{ fontFamily: 'monospace', fontSize: 12 }}>
                      {provider.profile_id}
                    </span>
                  ) : (
                    <span style={{ color: '#94A3B8' }}>—</span>
                  )}
                </Descriptions.Item>
              )}
              <Descriptions.Item label="Kiểm tra">
                {!provider.test_result ? (
                  <Tag
                    color="warning"
                    icon={<WarningOutlined />}
                    style={{ margin: 0 }}
                  >
                    Chưa kiểm tra
                  </Tag>
                ) : provider.test_result === 'OK' ? (
                  <Space size={6}>
                    <Tag
                      color="success"
                      icon={<CheckCircleOutlined />}
                      style={{ margin: 0 }}
                    >
                      Kết nối OK
                    </Tag>
                    <span style={{ fontSize: 11, color: '#94A3B8' }}>
                      {formatDateTime(provider.last_tested_at)}
                    </span>
                  </Space>
                ) : (
                  <Space size={6}>
                    <Tag
                      color="error"
                      icon={<CloseCircleOutlined />}
                      style={{ margin: 0 }}
                    >
                      Lỗi kết nối
                    </Tag>
                    <span style={{ fontSize: 11, color: '#94A3B8' }}>
                      {formatDateTime(provider.last_tested_at)}
                    </span>
                  </Space>
                )}
              </Descriptions.Item>
              <Descriptions.Item label="Cập nhật">
                <span style={{ fontSize: 12, color: '#64748B' }}>
                  {formatDateTime(provider.updated_at)}
                </span>
              </Descriptions.Item>
            </Descriptions>

            <div
              style={{
                marginTop: 16,
                paddingTop: 16,
                borderTop: '1px solid #F1F5F9',
                display: 'flex',
                justifyContent: 'flex-end',
                gap: 8,
              }}
            >
              <Button
                icon={<EditOutlined />}
                onClick={() => handleEdit(provider)}
                disabled={!isConfigured}
              >
                Sửa cấu hình
              </Button>
              {!isActive && (
                <Button
                  type="primary"
                  icon={<PoweroffOutlined />}
                  onClick={() => handleActivate(provider)}
                  loading={isActivating}
                  disabled={!isConfigured}
                >
                  Kích hoạt
                </Button>
              )}
            </div>
          </>
        )}
      </Card>
    );
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Render
  // ──────────────────────────────────────────────────────────────────────────

  const statCards = [
    {
      key: 'total_users',
      title: 'Tổng người dùng',
      value: displayStats?.total_users ?? 0,
      icon: <TeamOutlined />,
      gradient: 'linear-gradient(135deg, #1B3A5C, #2d5a8e)',
      shadow: 'rgba(27,58,92,0.3)',
    },
    {
      key: 'verified_users',
      title: 'Đã xác thực',
      value: displayStats?.verified_users ?? 0,
      icon: <CheckCircleOutlined />,
      gradient: 'linear-gradient(135deg, #059669, #10b981)',
      shadow: 'rgba(5,150,105,0.3)',
    },
    {
      key: 'monthly_transactions',
      title: 'Giao dịch tháng',
      value: displayStats?.monthly_transactions ?? 0,
      icon: <RiseOutlined />,
      gradient: 'linear-gradient(135deg, #0891B2, #06b6d4)',
      shadow: 'rgba(8,145,178,0.3)',
    },
    {
      key: 'monthly_completed',
      title: 'Thành công',
      value: displayStats?.monthly_completed ?? 0,
      icon: <AuditOutlined />,
      gradient: 'linear-gradient(135deg, #7c3aed, #a78bfa)',
      shadow: 'rgba(124,58,237,0.3)',
    },
    {
      key: 'monthly_failed',
      title: 'Thất bại',
      value: displayStats?.monthly_failed ?? 0,
      icon: <CloseCircleOutlined />,
      gradient: 'linear-gradient(135deg, #dc2626, #f87171)',
      shadow: 'rgba(220,38,38,0.3)',
    },
  ];

  return (
    <div>
      {/* Page Header */}
      <div className="page-header">
        <h2 className="page-title">
          <SafetyCertificateOutlined style={{ color: '#0891B2' }} />
          Cấu hình ký số hệ thống
        </h2>
        <p className="page-description">
          Hệ thống hỗ trợ 2 nhà cung cấp dịch vụ ký số: SmartCA VNPT và MySign Viettel. Admin cấu
          hình credentials và kích hoạt 1 provider cho toàn hệ thống.
        </p>
      </div>

      {/* Active Provider Banner + Refresh */}
      {!loading && (
        <div style={{ marginBottom: 16 }}>
          {activeProvider ? (
            <Alert
              type="success"
              showIcon
              icon={<CheckCircleOutlined />}
              style={{ borderRadius: 12 }}
              title={
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 8 }}>
                  <span>
                    <strong>Provider đang hoạt động:</strong> {activeProvider.provider_name}
                    {activeProvider.base_url && (
                      <span style={{ marginLeft: 8, color: '#64748B', fontSize: 12, fontFamily: 'monospace' }}>
                        ({activeProvider.base_url})
                      </span>
                    )}
                    {activeProvider.last_tested_at && (
                      <span style={{ marginLeft: 12, color: '#64748B', fontSize: 12 }}>
                        Kiểm tra lần cuối: {formatDateTime(activeProvider.last_tested_at)}
                      </span>
                    )}
                  </span>
                  <Button
                    icon={<ReloadOutlined />}
                    onClick={fetchConfig}
                    disabled={loading}
                    size="small"
                  >
                    Làm mới
                  </Button>
                </div>
              }
            />
          ) : (
            <Alert
              type="warning"
              showIcon
              icon={<ExclamationCircleOutlined />}
              style={{ borderRadius: 12 }}
              title={
                <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 8 }}>
                  <span>
                    <strong>Chưa có provider nào được kích hoạt.</strong> Vui lòng cấu hình và kích
                    hoạt 1 provider để bật tính năng ký số.
                  </span>
                  <Button
                    icon={<ReloadOutlined />}
                    onClick={fetchConfig}
                    disabled={loading}
                    size="small"
                  >
                    Làm mới
                  </Button>
                </div>
              }
            />
          )}
        </div>
      )}

      {/* Stats Section */}
      <Card
        className="page-card"
        variant="borderless"
        style={{ marginBottom: 16 }}
        styles={{ body: { padding: '16px 16px 12px 16px' } }}
        title={
          <div className="section-card-header">
            <div
              className="section-card-icon"
              style={{
                background: 'linear-gradient(135deg, #1B3A5C, #0891B2)',
                color: '#fff',
              }}
            >
              <ThunderboltOutlined style={{ fontSize: 14 }} />
            </div>
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>
              Thống kê {activeProvider ? `(${activeProvider.provider_name})` : '(chưa có provider)'}
            </span>
          </div>
        }
      >
        {loading ? (
          <Skeleton active paragraph={{ rows: 2 }} />
        ) : (
          <Row gutter={[16, 16]}>
            {statCards.map((card) => (
              <Col xs={24} sm={12} md={8} lg={Math.floor(24 / 5)} xl={Math.floor(24 / 5)} key={card.key}>
                <Card
                  className="stat-card"
                  variant="borderless"
                  style={{
                    boxShadow: `0 4px 12px ${card.shadow}`,
                    background: card.gradient,
                  }}
                  styles={{ body: { padding: '14px 16px' } }}
                >
                  <div className="stat-card-body">
                    <div>
                      <p
                        style={{
                          fontSize: 11,
                          color: 'rgba(255,255,255,0.75)',
                          margin: '0 0 6px 0',
                          lineHeight: 1.3,
                          whiteSpace: 'nowrap',
                        }}
                      >
                        {card.title}
                      </p>
                      <p
                        style={{
                          fontSize: 26,
                          fontWeight: 700,
                          color: '#fff',
                          margin: 0,
                          lineHeight: 1,
                        }}
                      >
                        {card.value}
                      </p>
                    </div>
                    <div
                      className="stat-card-icon"
                      style={{
                        background: 'rgba(255,255,255,0.15)',
                        fontSize: 18,
                        color: 'rgba(255,255,255,0.9)',
                      }}
                    >
                      {card.icon}
                    </div>
                  </div>
                </Card>
              </Col>
            ))}
          </Row>
        )}
      </Card>

      {/* 2 Provider Cards — side by side (stack on mobile) */}
      {loading ? (
        <Row gutter={[16, 16]}>
          <Col xs={24} md={12}>
            <Card>
              <Skeleton active paragraph={{ rows: 5 }} />
            </Card>
          </Col>
          <Col xs={24} md={12}>
            <Card>
              <Skeleton active paragraph={{ rows: 5 }} />
            </Card>
          </Col>
        </Row>
      ) : (
        <Row gutter={[16, 16]}>
          <Col xs={24} md={12}>
            {renderProviderCard(
              smartcaProvider,
              'SMARTCA_VNPT',
              'linear-gradient(135deg, #1B3A5C, #0891B2)',
            )}
          </Col>
          <Col xs={24} md={12}>
            {renderProviderCard(
              mysignProvider,
              'MYSIGN_VIETTEL',
              'linear-gradient(135deg, #7c3aed, #a78bfa)',
            )}
          </Col>
        </Row>
      )}

      {/* Drawer — Sửa cấu hình */}
      <Drawer
        forceRender
        title={
          editingRecord
            ? `Sửa cấu hình — ${editingRecord.provider_name}`
            : 'Sửa cấu hình'
        }
        open={drawerOpen}
        onClose={handleCloseDrawer}
        destroyOnHidden
        rootClassName="drawer-gradient"
        size={720}
        extra={
          <Space>
            <Button onClick={handleCloseDrawer}>Hủy</Button>
            <Button loading={saving} onClick={() => handleSave(false)}>
              Lưu
            </Button>
            {editingRecord && !editingRecord.is_active && (
              <Button
                type="primary"
                loading={saving}
                disabled={!testedOk}
                onClick={() => handleSave(true)}
                icon={<PoweroffOutlined />}
              >
                Lưu &amp; Kích hoạt
              </Button>
            )}
          </Space>
        }
      >
        {editingRecord && (
          <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit">
            <Alert
              type="info"
              showIcon
              style={{ marginBottom: 16, borderRadius: 8 }}
              title={`Đang sửa: ${editingRecord.provider_name}`}
              description={
                editingRecord.is_active
                  ? 'Provider này đang hoạt động — thay đổi sẽ áp dụng ngay khi lưu.'
                  : 'Provider này chưa hoạt động. Có thể kích hoạt sau khi kiểm tra kết nối thành công.'
              }
            />

            <Form.Item
              name="base_url"
              label={
                <span>
                  Base URL{' '}
                  <Tooltip
                    title="URL cổng API của nhà cung cấp. Ví dụ: https://gwsca.vnpt.vn (SmartCA VNPT) hoặc https://remotesigning.viettel.vn (MySign Viettel)"
                  >
                    <QuestionCircleOutlined style={{ color: '#94A3B8', fontSize: 13 }} />
                  </Tooltip>
                </span>
              }
              rules={[
                { required: true, message: 'Nhập Base URL của provider' },
                {
                  validator: (_, value: string | undefined) => {
                    if (!value) return Promise.resolve();
                    const v = value.trim();
                    if (v.startsWith('https://') || v.startsWith('http://localhost')) {
                      return Promise.resolve();
                    }
                    return Promise.reject(
                      new Error('Base URL phải bắt đầu bằng https:// (hoặc http://localhost cho dev)'),
                    );
                  },
                },
              ]}
              extra={
                <span style={{ fontSize: 12, color: '#94A3B8' }}>
                  VD: {PROVIDER_META[editingRecord.provider_code].baseUrlHint}
                </span>
              }
            >
              <Input maxLength={500} placeholder="https://..." />
            </Form.Item>

            <Form.Item
              name="client_id"
              label={
                <span>
                  Client ID{' '}
                  <Tooltip
                    title="Mã định danh app QLVB, do nhà cung cấp cấp khi đăng ký tích hợp."
                  >
                    <QuestionCircleOutlined style={{ color: '#94A3B8', fontSize: 13 }} />
                  </Tooltip>
                </span>
              }
              rules={[{ required: true, message: 'Nhập Client ID' }]}
            >
              <Input maxLength={200} placeholder="VD: sp_vnpt_xxxx hoặc myapp_client" />
            </Form.Item>

            <Form.Item
              name="client_secret"
              label={
                <span>
                  Client Secret{' '}
                  <Tooltip
                    title="Mật khẩu của app QLVB với nhà cung cấp ký số. Khác với OTP cá nhân của user."
                  >
                    <QuestionCircleOutlined style={{ color: '#94A3B8', fontSize: 13 }} />
                  </Tooltip>
                  <Tag color="blue" style={{ marginLeft: 8, fontSize: 11 }}>
                    Để trống nếu giữ nguyên
                  </Tag>
                </span>
              }
              rules={[
                {
                  validator: (_, value: string | undefined) => {
                    if (!value) return Promise.resolve();
                    if (value.length < 8) {
                      return Promise.reject(new Error('Client Secret tối thiểu 8 ký tự'));
                    }
                    return Promise.resolve();
                  },
                },
              ]}
              extra={
                editingRecord.has_secret ? (
                  <span
                    style={{
                      fontSize: 12,
                      color: '#059669',
                      display: 'inline-flex',
                      alignItems: 'center',
                      gap: 4,
                    }}
                  >
                    <LockOutlined />
                    Client Secret đã được mã hóa và lưu trữ an toàn. Để trống để giữ nguyên, hoặc
                    nhập secret mới để thay thế.
                  </span>
                ) : (
                  <span style={{ fontSize: 12, color: '#94A3B8' }}>
                    Chưa cấu hình — nhập Client Secret từ nhà cung cấp.
                  </span>
                )
              }
            >
              <Input.Password
                maxLength={500}
                placeholder={
                  editingRecord.has_secret
                    ? 'Để trống nếu giữ nguyên secret cũ'
                    : 'Nhập Client Secret từ nhà cung cấp'
                }
                autoComplete="new-password"
                onChange={(e) => setSecretDirty(!!e.target.value && e.target.value.length > 0)}
              />
            </Form.Item>

            {PROVIDER_META[editingRecord.provider_code].needsProfileId && (
              <Form.Item
                name="profile_id"
                label="Profile ID"
                rules={[{ required: true, message: 'Profile ID là bắt buộc với MySign Viettel' }]}
                extra={
                  <span style={{ fontSize: 12, color: '#94A3B8' }}>
                    VD: adss:ras:profile:001 (do Viettel cấp cùng credentials)
                  </span>
                }
              >
                <Input maxLength={200} placeholder="adss:ras:profile:XXX" />
              </Form.Item>
            )}

            {/* Test Connection block — 2 variant (saved / new) */}
            <div
              style={{
                background: '#F8FAFC',
                border: '1px solid #E2E8F0',
                borderRadius: 12,
                padding: 16,
                marginTop: 8,
              }}
            >
              <div style={{ marginBottom: 12 }}>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#1B3A5C' }}>
                  Kiểm tra kết nối provider
                </div>
                <div style={{ fontSize: 12, color: '#64748B', marginTop: 2 }}>
                  Bắt buộc test thành công (với secret mới) trước khi &quot;Lưu &amp; Kích hoạt&quot;.
                  Có thể test lại cấu hình đã lưu để verify credentials còn hoạt động.
                </div>
              </div>

              <Space wrap size={8} style={{ width: '100%' }}>
                <Tooltip
                  title={
                    !editingRecord.has_secret
                      ? 'Provider chưa cấu hình — nhập credentials và lưu trước khi test'
                      : 'Dùng Base URL + Client ID + Client Secret đã lưu trong DB để test'
                  }
                >
                  <Button
                    icon={<DatabaseOutlined />}
                    onClick={onTestSavedConnection}
                    loading={testingSource === 'saved'}
                    disabled={!editingRecord.has_secret || testingSource === 'new'}
                  >
                    Kiểm tra cấu hình đã lưu
                  </Button>
                </Tooltip>
                <Tooltip
                  title={
                    !secretDirty
                      ? 'Nhập Client Secret mới trong form để bật nút này'
                      : 'Test với các giá trị user vừa nhập trong form (không persist DB)'
                  }
                >
                  <Button
                    type="primary"
                    ghost
                    icon={<KeyOutlined />}
                    onClick={onTestConnection}
                    loading={testingSource === 'new'}
                    disabled={!secretDirty || testingSource === 'saved'}
                  >
                    Kiểm tra với secret mới
                  </Button>
                </Tooltip>
              </Space>

              {testResult && (
                <Alert
                  type={testResult.ok ? 'success' : 'error'}
                  showIcon
                  style={{ marginTop: 12, borderRadius: 8 }}
                  title={
                    <span>
                      {testResult.ok ? 'Kết nối thành công' : 'Kết nối thất bại'}{' '}
                      <Tag
                        color={testResult.source === 'saved' ? 'blue' : 'purple'}
                        style={{ marginLeft: 4, fontSize: 11 }}
                      >
                        {testResult.source === 'saved'
                          ? 'Cấu hình đã lưu'
                          : 'Secret mới nhập'}
                      </Tag>
                      {typeof testResult.durationMs === 'number' && (
                        <span style={{ color: '#94A3B8', fontSize: 11, marginLeft: 4 }}>
                          ({testResult.durationMs} ms)
                        </span>
                      )}
                    </span>
                  }
                  description={
                    <div>
                      <div>{testResult.message}</div>
                      {testResult.ok && testResult.subject && (
                        <div style={{ marginTop: 4, fontSize: 12 }}>
                          <strong>Chứng thư:</strong>{' '}
                          <span style={{ fontFamily: 'monospace' }}>{testResult.subject}</span>
                        </div>
                      )}
                    </div>
                  }
                />
              )}
            </div>
          </Form>
        )}
      </Drawer>
    </div>
  );
}
