'use client';

/**
 * Trang: /lgsp/cau-hinh — Cấu hình kết nối LGSP (Admin only)
 *
 * Phase 37 Plan 37-03. REQ: LGSP-UI-01/02/03/04.
 *
 * Layout (top → bottom):
 *   1. Page header: title "Cấu hình kết nối LGSP" + nút "Làm mới"
 *   2. Alert info inline help (hướng dẫn Wave 1 sandbox → Wave 2 prod)
 *   3. 3 Stat cards KPI (đang kết nối / production active / sandbox active)
 *   4. Table 12 row (6 DN × 2 env): columns DN | Môi trường | SystemId | Base URL | Trạng thái (Switch) | Đồng bộ cuối | Hành động
 *   5. Drawer 720 "Sửa cấu hình — {DN} ({env})" với form (env + Mã LGSP read-only; system_id, base_url, secret_key editable)
 *   6. Modal "Kiểm tra kết nối — {DN} ({env})" hiển thị spinner → Alert kết quả
 *
 * Security:
 *   - secret_key_masked trả về từ GET luôn = '***' (server mask)
 *   - Edit: field secret_key để trống → backend giữ nguyên ciphertext cũ
 *   - Submit payload secretKey là plaintext (HTTPS), backend encrypt qua pgp_sym_encrypt trước khi lưu
 *
 * API (Plan 37-01 + 37-02):
 *   GET    /api/admin/lgsp-agency-config              → load 12 row
 *   PUT    /api/admin/lgsp-agency-config/:id          → save form (body: {systemId, baseUrl, secretKey?})
 *   POST   /api/admin/lgsp-agency-config/:id/test     → test connection (lightweight read-only)
 *   PATCH  /api/admin/lgsp-agency-config/:id/active   → toggle is_active
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card,
  Table,
  Button,
  Drawer,
  Form,
  Input,
  Switch,
  Tag,
  Space,
  Modal,
  Alert,
  Tooltip,
  Skeleton,
  App,
  Row,
  Col,
  Radio,
  Empty,
  Spin,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  ApiOutlined,
  EditOutlined,
  ThunderboltOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  ReloadOutlined,
  SettingOutlined,
  KeyOutlined,
  ClockCircleOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useUserRights } from '@/hooks/use-user-rights';
import dayjs from 'dayjs';

// ============================================================================
// Types — match GET /api/admin/lgsp-agency-config response shape
// ============================================================================

interface LgspConfigRow {
  id: number;
  unit_id: number;
  unit_name: string;
  lgsp_org_code: string | null;
  environment: 'sandbox' | 'prod';
  system_id: string;
  base_url: string;
  is_active: boolean;
  last_synced_at: string | null;
  last_sync_error: string | null;
  created_at: string;
  updated_at: string;
  secret_key_masked: string;
}

interface TestResult {
  ok: boolean;
  message: string;
  http_status: number;
  response_summary: { count: number } | null;
}

interface FormValues {
  system_id?: string;
  base_url?: string;
  secret_key?: string;
}

// ============================================================================
// Component
// ============================================================================

export default function LgspCauHinhPage(): React.ReactElement {
  const { message: msg } = App.useApp();
  const { hasRight, loaded: rightsLoaded } = useUserRights();
  // Phase 37.1: granular right_id=26 (RIGHT_LGSP_CONFIG) thay vi role hardcode
  const canAccess = hasRight(26);

  const [data, setData] = useState<LgspConfigRow[]>([]);
  const [loading, setLoading] = useState<boolean>(true);

  // Drawer state
  const [drawerOpen, setDrawerOpen] = useState<boolean>(false);
  const [editingRow, setEditingRow] = useState<LgspConfigRow | null>(null);
  const [saving, setSaving] = useState<boolean>(false);
  const [form] = Form.useForm<FormValues>();

  // Test modal state
  const [testModalOpen, setTestModalOpen] = useState<boolean>(false);
  const [testingRow, setTestingRow] = useState<LgspConfigRow | null>(null);
  const [testing, setTesting] = useState<boolean>(false);
  const [testResult, setTestResult] = useState<TestResult | null>(null);

  // ── Fetch list ──────────────────────────────────────────────────────────
  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/admin/lgsp-agency-config');
      if (res?.success) {
        setData((res.data || []) as LgspConfigRow[]);
      } else {
        msg.error(res?.message || 'Không tải được cấu hình LGSP');
      }
    } catch (err: unknown) {
      const errAny = err as { response?: { data?: { message?: string } } };
      msg.error(errAny.response?.data?.message || 'Không tải được cấu hình LGSP');
    } finally {
      setLoading(false);
    }
  }, [msg]);

  useEffect(() => {
    if (rightsLoaded && canAccess) fetchData();
  }, [rightsLoaded, canAccess, fetchData]);

  // ── Drawer open / close ────────────────────────────────────────────────
  const handleEdit = (row: LgspConfigRow) => {
    setEditingRow(row);
    form.setFieldsValue({
      system_id: row.system_id,
      base_url: row.base_url,
      // KHÔNG prefill secret — admin nhập mới nếu muốn thay đổi
      secret_key: '',
    });
    setDrawerOpen(true);
  };

  const handleCloseDrawer = () => {
    setDrawerOpen(false);
    setEditingRow(null);
    form.resetFields();
  };

  // ── Save form ──────────────────────────────────────────────────────────
  const handleSave = async () => {
    if (!editingRow) return;
    try {
      const values = await form.validateFields();
      setSaving(true);
      const payload: {
        systemId?: string;
        baseUrl?: string;
        secretKey?: string;
      } = {
        systemId: values.system_id?.trim(),
        baseUrl: values.base_url?.trim(),
      };
      // Chỉ truyền secretKey khi user nhập mới — để trống = giữ ciphertext cũ
      if (values.secret_key && values.secret_key.trim() !== '') {
        payload.secretKey = values.secret_key.trim();
      }
      const { data: res } = await api.put(
        `/admin/lgsp-agency-config/${editingRow.id}`,
        payload,
      );
      if (res?.success) {
        msg.success('Đã cập nhật cấu hình LGSP');
        handleCloseDrawer();
        fetchData();
      } else {
        msg.error(res?.message || 'Lưu thất bại');
      }
    } catch (err: unknown) {
      const errAny = err as {
        response?: { data?: { message?: string } };
        errorFields?: unknown;
      };
      // Form validation error → errorFields có sẵn, KHÔNG show msg riêng
      if (errAny.errorFields) return;
      msg.error(errAny.response?.data?.message || 'Lưu thất bại');
    } finally {
      setSaving(false);
    }
  };

  // ── Toggle active inline ───────────────────────────────────────────────
  const handleToggleActive = async (row: LgspConfigRow, next: boolean) => {
    try {
      const { data: res } = await api.patch(
        `/admin/lgsp-agency-config/${row.id}/active`,
        { is_active: next },
      );
      if (res?.success) {
        msg.success(
          res.message || (next ? 'Đã bật kết nối LGSP' : 'Đã tắt kết nối LGSP'),
        );
        fetchData();
      } else {
        msg.error(res?.message || 'Không thể cập nhật trạng thái');
      }
    } catch (err: unknown) {
      const errAny = err as { response?: { data?: { message?: string } } };
      msg.error(errAny.response?.data?.message || 'Không thể cập nhật trạng thái');
    }
  };

  // ── Test connection ────────────────────────────────────────────────────
  const handleOpenTest = (row: LgspConfigRow) => {
    setTestingRow(row);
    setTestResult(null);
    setTestModalOpen(true);
  };

  const handleCloseTest = () => {
    setTestModalOpen(false);
    setTestingRow(null);
    setTestResult(null);
  };

  const handleRunTest = async () => {
    if (!testingRow) return;
    setTesting(true);
    setTestResult(null);
    try {
      const { data: res } = await api.post(
        `/admin/lgsp-agency-config/${testingRow.id}/test`,
      );
      if (res?.success && res.data) {
        setTestResult(res.data as TestResult);
      } else {
        setTestResult({
          ok: false,
          message: res?.message || 'Lỗi không xác định',
          http_status: 0,
          response_summary: null,
        });
      }
    } catch (err: unknown) {
      const errAny = err as { response?: { data?: { message?: string } } };
      setTestResult({
        ok: false,
        message:
          errAny.response?.data?.message || 'Không thể kết nối tới backend',
        http_status: 0,
        response_summary: null,
      });
    } finally {
      setTesting(false);
    }
  };

  // ── Columns ────────────────────────────────────────────────────────────
  const columns: ColumnsType<LgspConfigRow> = [
    {
      title: 'Đơn vị',
      dataIndex: 'unit_name',
      width: 240,
      render: (val: string, row) => (
        <Space direction="vertical" size={0}>
          <span style={{ fontWeight: 600 }}>{val || `Đơn vị #${row.unit_id}`}</span>
          {row.lgsp_org_code && (
            <Tag color="blue" style={{ fontSize: 11, marginTop: 2 }}>
              Mã: {row.lgsp_org_code}
            </Tag>
          )}
        </Space>
      ),
    },
    {
      title: 'Môi trường',
      dataIndex: 'environment',
      width: 120,
      align: 'center',
      render: (val: 'sandbox' | 'prod') =>
        val === 'prod' ? (
          <Tag color="red">Production</Tag>
        ) : (
          <Tag color="orange">Sandbox</Tag>
        ),
    },
    {
      title: 'SystemId',
      dataIndex: 'system_id',
      width: 140,
      ellipsis: true,
      render: (val: string) => (
        <span style={{ fontFamily: 'monospace', fontSize: 12 }}>{val || '—'}</span>
      ),
    },
    {
      title: 'Base URL',
      dataIndex: 'base_url',
      ellipsis: true,
      render: (val: string) => (
        <Tooltip title={val}>
          <span style={{ fontFamily: 'monospace', fontSize: 12 }}>
            {val || '—'}
          </span>
        </Tooltip>
      ),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'is_active',
      width: 120,
      align: 'center',
      render: (val: boolean, row) => (
        <Switch
          checked={val}
          checkedChildren="Bật"
          unCheckedChildren="Tắt"
          onChange={(next) => handleToggleActive(row, next)}
        />
      ),
    },
    {
      title: 'Đồng bộ cuối',
      dataIndex: 'last_synced_at',
      width: 170,
      render: (val: string | null, row) => (
        <Tooltip title={row.last_sync_error || undefined}>
          <Space direction="vertical" size={0}>
            {val ? (
              <span style={{ fontSize: 12 }}>
                {dayjs(val).format('DD/MM/YYYY HH:mm')}
              </span>
            ) : (
              <span style={{ color: '#bfbfbf', fontSize: 12 }}>Chưa đồng bộ</span>
            )}
            {row.last_sync_error && (
              <Tag color="red" style={{ fontSize: 10, marginTop: 2 }}>
                Lỗi gần nhất
              </Tag>
            )}
          </Space>
        </Tooltip>
      ),
    },
    {
      title: 'Hành động',
      key: 'actions',
      width: 220,
      align: 'center',
      render: (_, row) => (
        <Space size={4}>
          <Button
            size="small"
            icon={<EditOutlined />}
            onClick={() => handleEdit(row)}
          >
            Sửa
          </Button>
          <Button
            size="small"
            icon={<ThunderboltOutlined />}
            onClick={() => handleOpenTest(row)}
          >
            Kiểm tra
          </Button>
        </Space>
      ),
    },
  ];

  // ── Stats ───────────────────────────────────────────────────────────────
  const activeCount = data.filter((d) => d.is_active).length;
  const prodActive = data.filter(
    (d) => d.is_active && d.environment === 'prod',
  ).length;
  const sandboxActive = data.filter(
    (d) => d.is_active && d.environment === 'sandbox',
  ).length;

  // ── Render ─────────────────────────────────────────────────────────────
  if (rightsLoaded && !canAccess) {
    return (
      <Alert
        type="warning"
        showIcon
        title="Không có quyền truy cập"
        description="Trang Cấu hình kết nối LGSP chỉ dành cho người dùng có vai trò Quản trị hệ thống."
      />
    );
  }

  return (
    <>
      <div className="page-header">
        <h2 className="page-title">
          <SettingOutlined style={{ marginRight: 8, color: '#1B3A5C' }} />
          Cấu hình kết nối LGSP
        </h2>
        <Button icon={<ReloadOutlined />} onClick={fetchData} loading={loading}>
          Làm mới
        </Button>
      </div>

      <Alert
        type="info"
        showIcon
        style={{ marginBottom: 16 }}
        title="Cấu hình kết nối tỉnh Lạng Sơn"
        description={
          <>
            Mỗi đơn vị có 2 môi trường: <b>Sandbox</b> (kiểm thử) và{' '}
            <b>Production</b> (vận hành thật). Nhập <code>SystemId</code> +{' '}
            <code>SecretKey</code> từ tài liệu LGSP do Sở TT&amp;TT cung cấp,
            bấm <b>Kiểm tra kết nối</b> đạt → bật <b>Trạng thái</b> để cron tự
            động đồng bộ mỗi 5 phút.
          </>
        }
      />

      <Row gutter={16} style={{ marginBottom: 16 }}>
        <Col xs={24} sm={8}>
          <Card size="small">
            <Space>
              <ApiOutlined style={{ fontSize: 28, color: '#1B3A5C' }} />
              <div>
                <div style={{ fontSize: 12, color: '#8c8c8c' }}>Đang kết nối</div>
                <div
                  style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C' }}
                >
                  {activeCount} / {data.length}
                </div>
              </div>
            </Space>
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card size="small">
            <Space>
              <CheckCircleOutlined
                style={{ fontSize: 28, color: '#059669' }}
              />
              <div>
                <div style={{ fontSize: 12, color: '#8c8c8c' }}>
                  Production active
                </div>
                <div
                  style={{ fontSize: 22, fontWeight: 700, color: '#059669' }}
                >
                  {prodActive}
                </div>
              </div>
            </Space>
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card size="small">
            <Space>
              <ClockCircleOutlined
                style={{ fontSize: 28, color: '#D97706' }}
              />
              <div>
                <div style={{ fontSize: 12, color: '#8c8c8c' }}>
                  Sandbox active
                </div>
                <div
                  style={{ fontSize: 22, fontWeight: 700, color: '#D97706' }}
                >
                  {sandboxActive}
                </div>
              </div>
            </Space>
          </Card>
        </Col>
      </Row>

      <Card className="page-card">
        {loading ? (
          <Skeleton active paragraph={{ rows: 8 }} />
        ) : data.length === 0 ? (
          <Empty description="Chưa có cấu hình LGSP nào" />
        ) : (
          <Table<LgspConfigRow>
            rowKey="id"
            columns={columns}
            dataSource={data}
            pagination={false}
            scroll={{ x: 1200 }}
            size="small"
          />
        )}
      </Card>

      {/* ── Drawer Edit ── */}
      <Drawer
        title={
          editingRow
            ? `Sửa cấu hình — ${editingRow.unit_name || `Đơn vị #${editingRow.unit_id}`} (${
                editingRow.environment === 'prod' ? 'Production' : 'Sandbox'
              })`
            : 'Sửa cấu hình LGSP'
        }
        size={720}
        open={drawerOpen}
        onClose={handleCloseDrawer}
        rootClassName="drawer-gradient"
        extra={
          <Space>
            <Button onClick={handleCloseDrawer}>Hủy</Button>
            <Button type="primary" loading={saving} onClick={handleSave}>
              Lưu
            </Button>
          </Space>
        }
      >
        <Form
          form={form}
          layout="vertical"
          validateTrigger="onSubmit"
          autoComplete="off"
        >
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item label="Môi trường">
                <Radio.Group value={editingRow?.environment} disabled>
                  <Radio.Button value="sandbox">Sandbox</Radio.Button>
                  <Radio.Button value="prod">Production</Radio.Button>
                </Radio.Group>
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item label="Mã LGSP">
                <Input
                  value={editingRow?.lgsp_org_code ?? ''}
                  disabled
                  placeholder="(chưa đặt)"
                />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            label="SystemId (X-SystemId header)"
            name="system_id"
            rules={[
              { required: true, message: 'Bắt buộc nhập SystemId' },
              { max: 13, message: 'SystemId tối đa 13 ký tự' },
            ]}
          >
            <Input placeholder="VD: H37.DN.001" maxLength={13} />
          </Form.Item>

          <Form.Item
            label="Base URL"
            name="base_url"
            rules={[
              { required: true, message: 'Bắt buộc nhập Base URL' },
              {
                pattern: /^https?:\/\/.+/i,
                message: 'Base URL phải bắt đầu bằng http:// hoặc https://',
              },
              { max: 500, message: 'Base URL tối đa 500 ký tự' },
            ]}
          >
            <Input
              placeholder="VD: https://apiltvb.langson.gov.vn"
              maxLength={500}
            />
          </Form.Item>

          <Form.Item
            label={
              <span>
                SecretKey (X-SecretKey header){' '}
                <span style={{ color: '#8c8c8c', fontWeight: 400 }}>
                  — để trống nếu giữ nguyên
                </span>
              </span>
            }
            name="secret_key"
            extra="Backend tự encrypt bằng pgp_sym_encrypt trước khi lưu — plaintext KHÔNG bao giờ tồn tại trong DB. Để trống nếu giữ secret_key hiện tại."
          >
            <Input.Password
              prefix={<KeyOutlined />}
              placeholder="Để trống nếu giữ secret_key hiện tại"
              autoComplete="new-password"
              maxLength={500}
            />
          </Form.Item>

          <Alert
            type="warning"
            showIcon
            title="Lưu ý quan trọng"
            description={
              <>
                Sau khi lưu credential mới, bấm <b>Kiểm tra kết nối</b> để xác
                nhận backend gọi được LGSP. Nếu OK mới bật <b>Trạng thái</b> để
                cron tự đồng bộ.
              </>
            }
          />
        </Form>
      </Drawer>

      {/* ── Modal Test Connection ── */}
      <Modal
        title={
          <Space>
            <ThunderboltOutlined style={{ color: '#1B3A5C' }} />
            <span>
              Kiểm tra kết nối —{' '}
              {testingRow?.unit_name || `Đơn vị #${testingRow?.unit_id ?? ''}`}{' '}
              ({testingRow?.environment === 'prod' ? 'Production' : 'Sandbox'})
            </span>
          </Space>
        }
        open={testModalOpen}
        onCancel={handleCloseTest}
        footer={[
          <Button key="close" onClick={handleCloseTest}>
            Đóng
          </Button>,
          <Button
            key="run"
            type="primary"
            icon={<ThunderboltOutlined />}
            loading={testing}
            onClick={handleRunTest}
          >
            {testResult ? 'Kiểm tra lại' : 'Bắt đầu kiểm tra'}
          </Button>,
        ]}
        width={620}
      >
        <Alert
          type="info"
          showIcon
          style={{ marginBottom: 16 }}
          title="Cách thức kiểm tra"
          description={
            <>
              Hệ thống gọi thử LGSP đọc danh sách VB 24h gần nhất với credential
              hiện tại (KHÔNG ghi DB). Nếu trục phản hồi danh sách = credential
              đúng.
            </>
          }
        />
        {testing ? (
          <div style={{ textAlign: 'center', padding: 32 }}>
            <Spin size="large" />
            <div style={{ marginTop: 12, color: '#8c8c8c' }}>
              Đang kiểm tra kết nối tới LGSP...
            </div>
          </div>
        ) : testResult ? (
          testResult.ok ? (
            <Alert
              type="success"
              icon={<CheckCircleOutlined />}
              showIcon
              title="Kết nối thành công"
              description={
                <>
                  <div>{testResult.message}</div>
                  {testResult.response_summary && (
                    <div style={{ marginTop: 8 }}>
                      <b>Số VB trên trục 24h qua:</b>{' '}
                      {testResult.response_summary.count}
                    </div>
                  )}
                  <div
                    style={{ marginTop: 8, color: '#8c8c8c', fontSize: 12 }}
                  >
                    HTTP Status: {testResult.http_status}
                  </div>
                </>
              }
            />
          ) : (
            <Alert
              type="error"
              icon={<CloseCircleOutlined />}
              showIcon
              title="Kết nối thất bại"
              description={
                <>
                  <div>{testResult.message}</div>
                  <div
                    style={{ marginTop: 8, color: '#8c8c8c', fontSize: 12 }}
                  >
                    HTTP Status:{' '}
                    {testResult.http_status || 'Không phản hồi'}
                  </div>
                  <div style={{ marginTop: 12 }}>
                    <b>Gợi ý kiểm tra:</b>
                    <ul style={{ marginTop: 4, paddingLeft: 24 }}>
                      <li>
                        SystemId + SecretKey có khớp với tài liệu LGSP do Sở
                        TT&amp;TT cung cấp chưa?
                      </li>
                      <li>
                        Base URL có truy cập được từ server không (firewall /
                        DNS)?
                      </li>
                      <li>Tài khoản LGSP còn hiệu lực không?</li>
                    </ul>
                  </div>
                </>
              }
            />
          )
        ) : (
          <Empty description="Bấm 'Bắt đầu kiểm tra' để gọi LGSP" />
        )}
      </Modal>
    </>
  );
}
