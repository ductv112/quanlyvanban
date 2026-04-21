'use client';

/**
 * Trang: /ky-so/cau-hinh — Cấu hình ký số hệ thống (Admin only)
 *
 * Nội dung:
 *  - Banner provider đang hoạt động (hoặc cảnh báo chưa kích hoạt)
 *  - 5 stat cards KPI từ provider active (tổng user / đã xác thực / giao dịch tháng / thành công / thất bại)
 *  - Bảng 2 provider (SmartCA VNPT + MySign Viettel) với status, test result, actions
 *  - Drawer thêm/cập nhật cấu hình:
 *      * Radio chọn provider (disable khi edit — không đổi type)
 *      * Fields: base_url, client_id, client_secret, profile_id (chỉ hiện khi MySign)
 *      * Nút "Kiểm tra kết nối" gọi POST /test-connection trực tiếp tới provider
 *      * Nút "Lưu & Kích hoạt" chỉ enable sau khi test pass (OK)
 *      * Nút "Chỉ lưu" (edit mode) lưu không kích hoạt
 *  - Guard admin client-side (defense-in-depth; backend enforce requireRoles)
 *
 * Security:
 *  - client_secret TRẢ VỀ từ GET chỉ là '***' (server mask) — KHÔNG bao giờ hiển thị plaintext
 *  - Edit: field secret để trống → backend giữ nguyên ciphertext cũ
 *  - Submit/test: payload client_secret là plaintext (qua HTTPS), backend encrypt trước khi lưu
 *
 * API (từ Plan 09-02):
 *  GET    /ky-so/cau-hinh                  → { data: { providers: [], active_code } }
 *  POST   /ky-so/cau-hinh/test-connection  → { data: { test_result, message, certificate_subject } }
 *  POST   /ky-so/cau-hinh                  → create (201)
 *  PUT    /ky-so/cau-hinh/:id              → update
 *  PATCH  /ky-so/cau-hinh/:id/active       → activate (auto-deactivate others)
 *  DELETE /ky-so/cau-hinh/:id              → 409 nếu đang active
 */

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Card,
  Table,
  Button,
  Input,
  Form,
  Radio,
  Drawer,
  Tag,
  Alert,
  Row,
  Col,
  Space,
  Dropdown,
  Modal,
  App,
  Empty,
  Skeleton,
  Tooltip,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined,
  SafetyCertificateOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  MoreOutlined,
  ThunderboltOutlined,
  TeamOutlined,
  AuditOutlined,
  RiseOutlined,
  EditOutlined,
  DeleteOutlined,
  PoweroffOutlined,
  ReloadOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';

// ============================================================================
// Types — match GET /ky-so/cau-hinh response shape (Plan 09-02)
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
  provider_code: ProviderCode;
  base_url: string;
  client_id: string;
  client_secret?: string;
  profile_id?: string;
}

interface TestResultState {
  ok: boolean;
  message: string;
  subject?: string | null;
}

// ============================================================================
// Constants
// ============================================================================

const PROVIDER_OPTIONS: { value: ProviderCode; label: string; baseUrlHint: string }[] = [
  { value: 'SMARTCA_VNPT', label: 'SmartCA VNPT', baseUrlHint: 'https://gwsca.vnpt.vn/sca/sp769/v1' },
  { value: 'MYSIGN_VIETTEL', label: 'MySign Viettel', baseUrlHint: 'https://remotesigning.viettel.vn' },
];

const PROVIDER_NAME_MAP: Record<ProviderCode, string> = {
  SMARTCA_VNPT: 'SmartCA VNPT',
  MYSIGN_VIETTEL: 'MySign Viettel',
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
  const [selectedStatsCode, setSelectedStatsCode] = useState<ProviderCode | null>(null);

  // Drawer state
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<ProviderConfig | null>(null);

  // Test connection state
  const [testing, setTesting] = useState(false);
  const [testedOk, setTestedOk] = useState(false);
  const [testResult, setTestResult] = useState<TestResultState | null>(null);

  // Save state
  const [saving, setSaving] = useState(false);

  // Watched form value — controls conditional profile_id field
  const selectedProviderCode = Form.useWatch('provider_code', form);

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
      // Preselect stats view: active provider > first configured > SmartCA
      setSelectedStatsCode((prev) => {
        if (prev && list.some((p) => p.provider_code === prev)) return prev;
        if (active) return active;
        const firstConfigured = list.find((p) => p.id !== null);
        return firstConfigured?.provider_code ?? list[0]?.provider_code ?? null;
      });
    } catch (err) {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message
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

  // Reset testedOk whenever form values change (security: new creds must re-test)
  useEffect(() => {
    setTestedOk(false);
    setTestResult(null);
  }, [selectedProviderCode]);

  // ──────────────────────────────────────────────────────────────────────────
  // Derived values
  // ──────────────────────────────────────────────────────────────────────────

  const selectedStats: ProviderStats | null = useMemo(() => {
    if (!selectedStatsCode) return null;
    const row = providers.find((p) => p.provider_code === selectedStatsCode);
    return row?.stats ?? null;
  }, [providers, selectedStatsCode]);

  const activeProvider = useMemo(
    () => providers.find((p) => p.provider_code === activeCode) ?? null,
    [providers, activeCode],
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Drawer handlers
  // ──────────────────────────────────────────────────────────────────────────

  const handleAdd = () => {
    setEditingRecord(null);
    form.resetFields();
    form.setFieldsValue({ provider_code: 'SMARTCA_VNPT' });
    setTestedOk(false);
    setTestResult(null);
    setDrawerOpen(true);
  };

  const handleEdit = (record: ProviderConfig) => {
    setEditingRecord(record);
    form.resetFields();
    form.setFieldsValue({
      provider_code: record.provider_code,
      base_url: record.base_url ?? '',
      client_id: record.client_id ?? '',
      client_secret: '',
      profile_id: record.profile_id ?? '',
    });
    setTestedOk(false);
    setTestResult(null);
    setDrawerOpen(true);
  };

  const handleCloseDrawer = () => {
    setDrawerOpen(false);
    setEditingRecord(null);
    setTestedOk(false);
    setTestResult(null);
    form.resetFields();
  };

  // Map backend validation error msgs → inline field errors
  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, keyof FormValues> = {
      'provider_code không hợp lệ': 'provider_code',
      'base_url là bắt buộc': 'base_url',
      'base_url phải là HTTPS (trừ localhost)': 'base_url',
      'client_id là bắt buộc': 'client_id',
      'client_id là bắt buộc (≤ 200 ký tự)': 'client_id',
      'client_secret là bắt buộc': 'client_secret',
      'client_secret tối thiểu 8 ký tự': 'client_secret',
      'provider_name là bắt buộc': 'provider_code',
      'provider_name là bắt buộc (≤ 100 ký tự)': 'provider_code',
    };
    const fieldName = fieldErrorMap[errorMessage];
    if (fieldName) {
      form.setFields([{ name: fieldName, errors: [errorMessage] }]);
      return true;
    }
    return false;
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Test connection (no persistence)
  // ──────────────────────────────────────────────────────────────────────────

  const onTestConnection = async () => {
    try {
      // Validate only the fields needed for test
      const fields: Array<keyof FormValues> = ['provider_code', 'base_url', 'client_id', 'client_secret'];
      if (selectedProviderCode === 'MYSIGN_VIETTEL') fields.push('profile_id');
      const values = await form.validateFields(fields);

      if (!values.client_secret || values.client_secret.length < 1) {
        form.setFields([{ name: 'client_secret', errors: ['Nhập client_secret để kiểm tra kết nối'] }]);
        return;
      }

      setTesting(true);
      setTestResult(null);

      const { data: res } = await api.post<{
        success: boolean;
        data: { test_result: 'OK' | 'FAILED'; message: string; certificate_subject: string | null };
      }>('/ky-so/cau-hinh/test-connection', {
        provider_code: values.provider_code,
        base_url: values.base_url,
        client_id: values.client_id,
        client_secret: values.client_secret,
        profile_id: values.profile_id ?? null,
      });

      if (res.data?.test_result === 'OK') {
        setTestedOk(true);
        setTestResult({
          ok: true,
          message: res.data.message,
          subject: res.data.certificate_subject,
        });
        message.success('Kiểm tra kết nối thành công');
      } else {
        setTestedOk(false);
        setTestResult({
          ok: false,
          message: res.data?.message ?? 'Kết nối thất bại',
        });
      }
    } catch (err) {
      setTestedOk(false);
      const httpErr = err as { response?: { data?: { message?: string } }; errorFields?: unknown[] };
      // If it's a Form validation error (errorFields) — no toast, just inline
      if (httpErr?.errorFields) return;
      const msg = httpErr?.response?.data?.message ?? 'Không kết nối được provider';
      setTestResult({ ok: false, message: msg });
    } finally {
      setTesting(false);
    }
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Save (with optional activate)
  // ──────────────────────────────────────────────────────────────────────────

  const handleSave = async (withActivate: boolean) => {
    try {
      const values = await form.validateFields();
      setSaving(true);

      const providerName = PROVIDER_NAME_MAP[values.provider_code];
      const payload: Record<string, unknown> = {
        provider_code: values.provider_code,
        provider_name: providerName,
        base_url: values.base_url,
        client_id: values.client_id,
        profile_id: values.profile_id?.trim() || null,
      };

      // Only include client_secret if non-empty (PUT allows omit = keep existing)
      if (values.client_secret && values.client_secret.length > 0) {
        payload.client_secret = values.client_secret;
      } else if (!editingRecord) {
        // Create mode — secret required
        form.setFields([{ name: 'client_secret', errors: ['Nhập client_secret khi tạo cấu hình mới'] }]);
        setSaving(false);
        return;
      }

      // Create vs update
      let savedId: number | null = editingRecord?.id ?? null;
      if (editingRecord && editingRecord.id) {
        await api.put(`/ky-so/cau-hinh/${editingRecord.id}`, payload);
      } else {
        // set_active is sent during create to let backend activate in one shot
        if (withActivate) payload.set_active = true;
        const { data: res } = await api.post<{
          success: boolean;
          message: string;
          data: { id: number };
        }>('/ky-so/cau-hinh', payload);
        savedId = res.data?.id ?? null;
      }

      // For update, call PATCH /active separately if asked
      if (withActivate && editingRecord && savedId) {
        try {
          await api.patch(`/ky-so/cau-hinh/${savedId}/active`);
        } catch (activateErr) {
          const msg = (activateErr as { response?: { data?: { message?: string } } })?.response?.data?.message
            ?? 'Kích hoạt thất bại';
          message.warning(`Lưu thành công. ${msg}`);
          handleCloseDrawer();
          await fetchConfig();
          setSaving(false);
          return;
        }
      }

      message.success(
        withActivate
          ? 'Lưu và kích hoạt cấu hình thành công'
          : editingRecord
            ? 'Cập nhật cấu hình thành công'
            : 'Lưu cấu hình thành công',
      );
      handleCloseDrawer();
      await fetchConfig();
    } catch (err) {
      const httpErr = err as { response?: { data?: { message?: string } }; errorFields?: unknown[] };
      if (httpErr?.errorFields) {
        // Form validation error — already inline
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
  // Activate (from table action)
  // ──────────────────────────────────────────────────────────────────────────

  const handleActivate = (record: ProviderConfig) => {
    if (record.id === null) {
      message.warning('Provider này chưa được cấu hình');
      return;
    }
    if (record.is_active) {
      message.info('Provider này đang được kích hoạt');
      return;
    }
    modal.confirm({
      title: 'Kích hoạt provider',
      content: `Kích hoạt "${record.provider_name}"? Provider đang hoạt động khác (nếu có) sẽ tự động bị tắt.`,
      okText: 'Kích hoạt',
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.patch(`/ky-so/cau-hinh/${record.id}/active`);
          message.success('Kích hoạt thành công');
          await fetchConfig();
        } catch (err) {
          const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message
            ?? 'Kích hoạt thất bại';
          message.error(msg);
        }
      },
    });
  };

  // ──────────────────────────────────────────────────────────────────────────
  // Delete (block when active)
  // ──────────────────────────────────────────────────────────────────────────

  const handleDelete = (record: ProviderConfig) => {
    if (record.id === null) return;
    if (record.is_active) {
      message.warning('Không thể xóa provider đang được kích hoạt. Vui lòng chuyển sang provider khác trước.');
      return;
    }
    modal.confirm({
      title: 'Xác nhận xóa cấu hình',
      content: (
        <div>
          <p>Xóa cấu hình provider <strong>&quot;{record.provider_name}&quot;</strong>?</p>
          <p style={{ color: '#DC2626', marginBottom: 0 }}>
            Hành động này không thể hoàn tác. Bạn có thể cấu hình lại bất cứ lúc nào.
          </p>
        </div>
      ),
      okText: 'Xóa',
      cancelText: 'Hủy',
      okButtonProps: { danger: true },
      onOk: async () => {
        try {
          await api.delete(`/ky-so/cau-hinh/${record.id}`);
          message.success('Xóa cấu hình thành công');
          await fetchConfig();
        } catch (err) {
          const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message
            ?? 'Xóa thất bại';
          message.error(msg);
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
  // Table columns
  // ──────────────────────────────────────────────────────────────────────────

  const columns: ColumnsType<ProviderConfig> = [
    {
      title: 'Nhà cung cấp',
      dataIndex: 'provider_name',
      key: 'provider_name',
      width: 200,
      render: (name: string, record) => (
        <Space>
          <SafetyCertificateOutlined
            style={{
              color: record.is_active ? '#059669' : '#94A3B8',
              fontSize: 16,
            }}
          />
          <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{name}</span>
        </Space>
      ),
    },
    {
      title: 'Base URL',
      dataIndex: 'base_url',
      key: 'base_url',
      ellipsis: true,
      render: (v: string | null) =>
        v ? (
          <Tooltip title={v}>
            <span style={{ color: '#475569', fontFamily: 'monospace', fontSize: 12 }}>{v}</span>
          </Tooltip>
        ) : (
          <Tag color="default">Chưa cấu hình</Tag>
        ),
    },
    {
      title: 'Client ID',
      dataIndex: 'client_id',
      key: 'client_id',
      width: 180,
      ellipsis: true,
      render: (v: string | null) =>
        v ? (
          <Tooltip title={v}>
            <span style={{ fontFamily: 'monospace', fontSize: 12 }}>{v}</span>
          </Tooltip>
        ) : (
          <span style={{ color: '#94A3B8' }}>—</span>
        ),
    },
    {
      title: 'Trạng thái',
      key: 'status',
      width: 140,
      align: 'center',
      render: (_, record) => {
        if (record.id === null) {
          return <Tag color="warning">Chưa cấu hình</Tag>;
        }
        if (record.is_active) {
          return (
            <Tag color="success" icon={<CheckCircleOutlined />}>
              Đang hoạt động
            </Tag>
          );
        }
        return <Tag color="default">Tạm dừng</Tag>;
      },
    },
    {
      title: 'Kiểm tra kết nối',
      key: 'test_result',
      width: 160,
      align: 'center',
      render: (_, record) => {
        if (!record.test_result) {
          return <span style={{ color: '#94A3B8' }}>Chưa kiểm tra</span>;
        }
        if (record.test_result === 'OK') {
          return (
            <Tooltip title={`Kiểm tra: ${formatDateTime(record.last_tested_at)}`}>
              <Tag color="success" icon={<CheckCircleOutlined />}>
                Thành công
              </Tag>
            </Tooltip>
          );
        }
        return (
          <Tooltip title={`Kiểm tra: ${formatDateTime(record.last_tested_at)}`}>
            <Tag color="error" icon={<CloseCircleOutlined />}>
              Thất bại
            </Tag>
          </Tooltip>
        );
      },
    },
    {
      title: 'Cập nhật',
      dataIndex: 'updated_at',
      key: 'updated_at',
      width: 150,
      render: (v: string | null) => (
        <span style={{ fontSize: 12, color: '#64748B' }}>{formatDateTime(v)}</span>
      ),
    },
    {
      title: '',
      key: 'actions',
      width: 60,
      align: 'center',
      fixed: 'right',
      render: (_, record) => (
        <Dropdown
          trigger={['click']}
          menu={{
            items: [
              {
                key: 'edit',
                icon: <EditOutlined />,
                label: record.id ? 'Cập nhật' : 'Cấu hình',
                onClick: () => handleEdit(record),
              },
              {
                key: 'activate',
                icon: <PoweroffOutlined />,
                label: record.is_active ? 'Đang hoạt động' : 'Kích hoạt',
                disabled: record.is_active || record.id === null,
                onClick: () => handleActivate(record),
              },
              { type: 'divider' },
              {
                key: 'delete',
                icon: <DeleteOutlined />,
                label: 'Xóa',
                danger: true,
                disabled: record.id === null || record.is_active,
                onClick: () => handleDelete(record),
              },
            ],
          }}
        >
          <Button
            type="text"
            size="small"
            icon={<MoreOutlined style={{ fontSize: 18 }} />}
            style={{ color: '#64748b' }}
          />
        </Dropdown>
      ),
    },
  ];

  // ──────────────────────────────────────────────────────────────────────────
  // Render
  // ──────────────────────────────────────────────────────────────────────────

  const statCards = [
    {
      key: 'total_users',
      title: 'Tổng người dùng',
      value: selectedStats?.total_users ?? 0,
      icon: <TeamOutlined />,
      gradient: 'linear-gradient(135deg, #1B3A5C, #2d5a8e)',
      shadow: 'rgba(27,58,92,0.3)',
    },
    {
      key: 'verified_users',
      title: 'Đã xác thực',
      value: selectedStats?.verified_users ?? 0,
      icon: <CheckCircleOutlined />,
      gradient: 'linear-gradient(135deg, #059669, #10b981)',
      shadow: 'rgba(5,150,105,0.3)',
    },
    {
      key: 'monthly_transactions',
      title: 'Giao dịch tháng này',
      value: selectedStats?.monthly_transactions ?? 0,
      icon: <RiseOutlined />,
      gradient: 'linear-gradient(135deg, #0891B2, #06b6d4)',
      shadow: 'rgba(8,145,178,0.3)',
    },
    {
      key: 'monthly_completed',
      title: 'Thành công',
      value: selectedStats?.monthly_completed ?? 0,
      icon: <AuditOutlined />,
      gradient: 'linear-gradient(135deg, #7c3aed, #a78bfa)',
      shadow: 'rgba(124,58,237,0.3)',
    },
    {
      key: 'monthly_failed',
      title: 'Thất bại',
      value: selectedStats?.monthly_failed ?? 0,
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
          Chọn nhà cung cấp dịch vụ ký số (SmartCA VNPT hoặc MySign Viettel), cấu hình credentials và kích hoạt cho toàn hệ thống
        </p>
      </div>

      {/* Active Provider Banner */}
      {!loading && (
        activeProvider ? (
          <Alert
            type="success"
            showIcon
            style={{ marginBottom: 16, borderRadius: 12 }}
            message={
              <span>
                <strong>Provider đang hoạt động:</strong> {activeProvider.provider_name}
                {activeProvider.last_tested_at && (
                  <span style={{ marginLeft: 12, color: '#64748B', fontSize: 12 }}>
                    (Kiểm tra lần cuối: {formatDateTime(activeProvider.last_tested_at)})
                  </span>
                )}
              </span>
            }
          />
        ) : (
          <Alert
            type="warning"
            showIcon
            style={{ marginBottom: 16, borderRadius: 12 }}
            message="Chưa có provider nào được kích hoạt"
            description="Vui lòng cấu hình và kích hoạt 1 provider (SmartCA VNPT hoặc MySign Viettel) để bật tính năng ký số trong toàn hệ thống."
          />
        )
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
              style={{ background: 'linear-gradient(135deg, #1B3A5C, #0891B2)', color: '#fff' }}
            >
              <ThunderboltOutlined style={{ fontSize: 14 }} />
            </div>
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Thống kê provider</span>
          </div>
        }
        extra={
          providers.length > 0 && (
            <Radio.Group
              size="small"
              value={selectedStatsCode}
              onChange={(e) => setSelectedStatsCode(e.target.value as ProviderCode)}
              buttonStyle="solid"
            >
              {providers.map((p) => (
                <Radio.Button key={p.provider_code} value={p.provider_code}>
                  {p.provider_name}
                </Radio.Button>
              ))}
            </Radio.Group>
          )
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
                  style={{ boxShadow: `0 4px 12px ${card.shadow}`, background: card.gradient }}
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

      {/* Providers Table */}
      <Card
        className="page-card"
        variant="borderless"
        title={
          <div className="section-card-header">
            <div
              className="section-card-icon"
              style={{ background: 'linear-gradient(135deg, #0891B2, #06b6d4)', color: '#fff' }}
            >
              <SafetyCertificateOutlined style={{ fontSize: 14 }} />
            </div>
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách cấu hình</span>
          </div>
        }
        extra={
          <Space>
            <Button icon={<ReloadOutlined />} onClick={fetchConfig} disabled={loading}>
              Làm mới
            </Button>
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={handleAdd}
            >
              Thêm / Cấu hình mới
            </Button>
          </Space>
        }
      >
        <Table
          className="enhanced-table"
          columns={columns}
          dataSource={providers}
          rowKey={(r) => r.provider_code}
          loading={loading}
          size="middle"
          sticky
          scroll={{ x: 1100 }}
          pagination={false}
        />
      </Card>

      {/* Drawer — Add/Edit */}
      <Drawer
        forceRender
        title={
          editingRecord
            ? `Cập nhật cấu hình — ${editingRecord.provider_name}`
            : 'Thêm cấu hình ký số'
        }
        open={drawerOpen}
        onClose={handleCloseDrawer}
        destroyOnHidden
        rootClassName="drawer-gradient"
        size={720}
        extra={
          <Space>
            <Button onClick={handleCloseDrawer}>Hủy</Button>
            {editingRecord && (
              <Button
                loading={saving}
                onClick={() => handleSave(false)}
              >
                Chỉ lưu
              </Button>
            )}
            <Button
              type="primary"
              loading={saving}
              disabled={!testedOk}
              onClick={() => handleSave(true)}
              icon={<PoweroffOutlined />}
            >
              Lưu & Kích hoạt
            </Button>
          </Space>
        }
      >
        <Form
          form={form}
          layout="vertical"
          autoComplete="off"
          validateTrigger="onSubmit"
        >
          <Form.Item
            name="provider_code"
            label="Nhà cung cấp"
            rules={[{ required: true, message: 'Vui lòng chọn nhà cung cấp' }]}
          >
            <Radio.Group disabled={!!editingRecord}>
              {PROVIDER_OPTIONS.map((opt) => (
                <Radio key={opt.value} value={opt.value}>
                  {opt.label}
                </Radio>
              ))}
            </Radio.Group>
          </Form.Item>

          <Form.Item
            name="base_url"
            label="Base URL"
            rules={[
              { required: true, message: 'Nhập Base URL của provider' },
              {
                validator: (_, value: string | undefined) => {
                  if (!value) return Promise.resolve();
                  const v = value.trim();
                  if (v.startsWith('https://') || v.startsWith('http://localhost')) {
                    return Promise.resolve();
                  }
                  return Promise.reject(new Error('Base URL phải bắt đầu bằng https:// (hoặc http://localhost cho dev)'));
                },
              },
            ]}
            extra={
              <span style={{ fontSize: 12, color: '#94A3B8' }}>
                VD: {PROVIDER_OPTIONS.find((o) => o.value === selectedProviderCode)?.baseUrlHint ?? '—'}
              </span>
            }
          >
            <Input maxLength={500} placeholder="https://..." />
          </Form.Item>

          <Form.Item
            name="client_id"
            label="Client ID"
            rules={[{ required: true, message: 'Nhập Client ID' }]}
          >
            <Input maxLength={200} placeholder="VD: sp_vnpt_xxxx hoặc myapp_client" />
          </Form.Item>

          <Form.Item
            name="client_secret"
            label={
              <span>
                Client Secret
                {editingRecord && (
                  <Tag color="blue" style={{ marginLeft: 8, fontSize: 11 }}>
                    Để trống nếu giữ nguyên
                  </Tag>
                )}
              </span>
            }
            rules={
              editingRecord
                ? [
                    {
                      validator: (_, value: string | undefined) => {
                        if (!value) return Promise.resolve();
                        if (value.length < 8) {
                          return Promise.reject(new Error('Client Secret tối thiểu 8 ký tự'));
                        }
                        return Promise.resolve();
                      },
                    },
                  ]
                : [
                    { required: true, message: 'Nhập Client Secret' },
                    { min: 8, message: 'Client Secret tối thiểu 8 ký tự' },
                  ]
            }
          >
            <Input.Password
              maxLength={500}
              placeholder={
                editingRecord
                  ? 'Để trống nếu giữ nguyên secret cũ'
                  : 'Nhập client_secret do provider cấp'
              }
              autoComplete="new-password"
            />
          </Form.Item>

          {selectedProviderCode === 'MYSIGN_VIETTEL' && (
            <Form.Item
              name="profile_id"
              label="Profile ID"
              rules={[
                { required: true, message: 'Profile ID là bắt buộc với MySign Viettel' },
              ]}
              extra={
                <span style={{ fontSize: 12, color: '#94A3B8' }}>
                  VD: adss:ras:profile:001 (do Viettel cấp cùng credentials)
                </span>
              }
            >
              <Input maxLength={200} placeholder="adss:ras:profile:XXX" />
            </Form.Item>
          )}

          {/* Test Connection block */}
          <div
            style={{
              background: '#F8FAFC',
              border: '1px solid #E2E8F0',
              borderRadius: 12,
              padding: 16,
              marginTop: 8,
            }}
          >
            <div
              style={{
                display: 'flex',
                justifyContent: 'space-between',
                alignItems: 'center',
                marginBottom: 12,
              }}
            >
              <div>
                <div style={{ fontSize: 14, fontWeight: 600, color: '#1B3A5C' }}>
                  Kiểm tra kết nối provider
                </div>
                <div style={{ fontSize: 12, color: '#64748B', marginTop: 2 }}>
                  Bắt buộc test thành công trước khi &quot;Lưu &amp; Kích hoạt&quot;
                </div>
              </div>
              <Button
                type="primary"
                ghost
                icon={<ThunderboltOutlined />}
                onClick={onTestConnection}
                loading={testing}
              >
                Kiểm tra kết nối
              </Button>
            </div>

            {testResult && (
              <Alert
                type={testResult.ok ? 'success' : 'error'}
                showIcon
                style={{ marginTop: 8, borderRadius: 8 }}
                message={
                  testResult.ok
                    ? 'Kết nối thành công'
                    : 'Kết nối thất bại'
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
      </Drawer>
    </div>
  );
}
