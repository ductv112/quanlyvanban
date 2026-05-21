'use client';

/**
 * Trang: /lgsp/co-quan — Cơ quan liên thông (Admin only CRUD)
 *
 * Phase 37 Plan 37-04. REQ: LGSP-UI-05, LGSP-UI-06.
 *
 * REWRITE từ Phase 18 read-only stub thành full CRUD admin:
 *   - List + filter is_active 3-state (Tất cả / Đã xác nhận / Tự đăng ký)
 *   - Search code + name (gửi query param `search`)
 *   - Drawer 720 Add/Edit form (Drawer AntD 6 với size= thay vì width=)
 *   - Popconfirm Delete (per project convention)
 *   - Button "Đồng bộ từ trục LGSP" (yêu cầu ≥1 lgsp_agency_config is_active=TRUE)
 *
 * Endpoints (Plan 37-01 + 37-02):
 *   GET    /api/admin/inter-organizations             → list (paginated)
 *   POST   /api/admin/inter-organizations             → create
 *   PUT    /api/admin/inter-organizations/:id         → update
 *   DELETE /api/admin/inter-organizations/:id         → delete
 *   POST   /api/admin/inter-organizations/sync        → batch sync từ LGSP
 *
 * Filter is_active mapping:
 *   - true  = Đã xác nhận (admin approved hoặc sync từ LGSP về)
 *   - false = Tự đăng ký (Phase 35 auto-INSERT khi nhận VB từ sender chưa có trong catalog)
 *
 * Pattern reference: cau-hinh/page.tsx (Plan 37-03) cho admin role guard + Drawer.
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card,
  Table,
  Button,
  Input,
  Tag,
  Space,
  Drawer,
  Form,
  Switch,
  Popconfirm,
  Select,
  App,
  Tooltip,
  Row,
  Col,
} from 'antd';
import type { ColumnsType, TablePaginationConfig } from 'antd/es/table';
import {
  SyncOutlined,
  SearchOutlined,
  ReloadOutlined,
  PlusOutlined,
  EditOutlined,
  DeleteOutlined,
  BankOutlined,
  ApiOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import dayjs from 'dayjs';

// ============================================================================
// Types — match backend InterOrgFullRow (Plan 37-01)
// ============================================================================

interface InterOrgRow {
  id: number;
  code: string;
  name: string;
  lgsp_organ_id: string | null;
  parent_id: number | null;
  is_active: boolean;
  address: string | null;
  email: string | null;
  phone: string | null;
  created_at: string;
  updated_at: string;
  total_count?: number;
}

interface FormValues {
  code: string;
  name: string;
  lgsp_organ_id?: string;
  is_active: boolean;
  address?: string;
  email?: string;
  phone?: string;
}

interface SyncResultData {
  total: number;
  created: number;
  updated: number;
  failed: number;
}

type IsActiveFilter = '' | 'true' | 'false';

const IS_ACTIVE_OPTIONS: { value: IsActiveFilter; label: string }[] = [
  { value: '', label: 'Tất cả' },
  { value: 'true', label: 'Đã xác nhận' },
  { value: 'false', label: 'Tự đăng ký' },
];

// ============================================================================
// Component
// ============================================================================

export default function LgspCoQuanPage(): React.ReactElement {
  const { message: msg, modal } = App.useApp();
  const { user } = useAuthStore();
  const isAdmin =
    Boolean(user?.isAdmin) ||
    Boolean(user?.roles?.includes('Quản trị hệ thống'));

  const [data, setData] = useState<InterOrgRow[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [syncing, setSyncing] = useState<boolean>(false);
  const [search, setSearch] = useState<string>('');
  const [searchInput, setSearchInput] = useState<string>('');
  const [isActiveFilter, setIsActiveFilter] = useState<IsActiveFilter>('');
  const [pagination, setPagination] = useState({
    current: 1,
    pageSize: 20,
    total: 0,
  });

  const [drawerOpen, setDrawerOpen] = useState<boolean>(false);
  const [editingRow, setEditingRow] = useState<InterOrgRow | null>(null);
  const [saving, setSaving] = useState<boolean>(false);
  const [form] = Form.useForm<FormValues>();

  // ── Fetch list ────────────────────────────────────────────────────────────
  const fetchData = useCallback(
    async (page = 1, pageSize = 20) => {
      setLoading(true);
      try {
        const { data: res } = await api.get('/admin/inter-organizations', {
          params: {
            search: search.trim() || undefined,
            is_active: isActiveFilter || undefined,
            page,
            pageSize,
          },
        });
        if (res?.success) {
          setData((res.data || []) as InterOrgRow[]);
          setPagination({
            current: res.pagination?.page || page,
            pageSize: res.pagination?.pageSize || pageSize,
            total: res.pagination?.total || 0,
          });
        } else {
          msg.error(res?.message || 'Không tải được danh sách cơ quan');
        }
      } catch (err: unknown) {
        const errAny = err as { response?: { data?: { message?: string } } };
        msg.error(
          errAny.response?.data?.message || 'Không tải được danh sách cơ quan',
        );
      } finally {
        setLoading(false);
      }
    },
    [search, isActiveFilter, msg],
  );

  // Reset về page 1 khi search/filter đổi
  useEffect(() => {
    fetchData(1, pagination.pageSize);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [search, isActiveFilter]);

  const handleTableChange = (pag: TablePaginationConfig) => {
    fetchData(pag.current || 1, pag.pageSize || 20);
  };

  // ── Sync từ LGSP ──────────────────────────────────────────────────────────
  const handleSync = () => {
    modal.confirm({
      title: 'Đồng bộ danh sách cơ quan từ trục LGSP',
      content: (
        <div>
          <p style={{ marginTop: 0 }}>
            Hệ thống sẽ gọi API <code>/v1/getAgenciesList</code> trên trục LGSP
            và đồng bộ danh sách cơ quan ngoài về catalog nội bộ.
          </p>
          <p style={{ marginBottom: 0, color: '#8c8c8c' }}>
            Yêu cầu: ít nhất 1 cấu hình LGSP đang bật (
            <b>Trạng thái = Bật</b>) tại trang <b>Cấu hình kết nối</b>.
          </p>
        </div>
      ),
      okText: 'Đồng bộ ngay',
      cancelText: 'Hủy',
      onOk: async () => {
        setSyncing(true);
        try {
          const { data: res } = await api.post(
            '/admin/inter-organizations/sync',
          );
          if (res?.success) {
            const d = (res.data || {}) as SyncResultData;
            modal.success({
              title: 'Đồng bộ thành công',
              content: (
                <div>
                  <p style={{ marginTop: 0 }}>{res.message}</p>
                  <ul style={{ marginBottom: 0, paddingLeft: 20 }}>
                    <li>
                      Tổng số cơ quan: <b>{d.total ?? 0}</b>
                    </li>
                    <li>
                      Thêm mới: <b style={{ color: '#059669' }}>{d.created ?? 0}</b>
                    </li>
                    <li>
                      Cập nhật: <b style={{ color: '#1B3A5C' }}>{d.updated ?? 0}</b>
                    </li>
                    {d.failed > 0 && (
                      <li>
                        Lỗi: <b style={{ color: '#DC2626' }}>{d.failed}</b>
                      </li>
                    )}
                  </ul>
                </div>
              ),
            });
            fetchData(pagination.current, pagination.pageSize);
          } else {
            msg.error(res?.message || 'Đồng bộ thất bại');
          }
        } catch (err: unknown) {
          const errAny = err as { response?: { data?: { message?: string } } };
          msg.error(
            errAny.response?.data?.message || 'Đồng bộ thất bại',
          );
        } finally {
          setSyncing(false);
        }
      },
    });
  };

  // ── Drawer open / close ──────────────────────────────────────────────────
  const handleOpenAdd = () => {
    setEditingRow(null);
    form.resetFields();
    form.setFieldsValue({ is_active: true });
    setDrawerOpen(true);
  };

  const handleOpenEdit = (row: InterOrgRow) => {
    setEditingRow(row);
    form.setFieldsValue({
      code: row.code,
      name: row.name,
      lgsp_organ_id: row.lgsp_organ_id ?? '',
      is_active: row.is_active,
      address: row.address ?? '',
      email: row.email ?? '',
      phone: row.phone ?? '',
    });
    setDrawerOpen(true);
  };

  const handleCloseDrawer = () => {
    setDrawerOpen(false);
    setEditingRow(null);
    form.resetFields();
  };

  // ── Backend error → inline field error ───────────────────────────────────
  const setBackendFieldError = (msgText: string): boolean => {
    if (msgText.includes('Mã cơ quan đã tồn tại')) {
      form.setFields([{ name: 'code', errors: [msgText] }]);
      return true;
    }
    return false;
  };

  // ── Save ─────────────────────────────────────────────────────────────────
  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      const payload = {
        code: values.code.trim(),
        name: values.name.trim(),
        lgsp_organ_id: values.lgsp_organ_id?.trim() || null,
        is_active: values.is_active !== false,
        address: values.address?.trim() || null,
        email: values.email?.trim() || null,
        phone: values.phone?.trim() || null,
      };

      let res;
      if (editingRow) {
        ({ data: res } = await api.put(
          `/admin/inter-organizations/${editingRow.id}`,
          payload,
        ));
      } else {
        ({ data: res } = await api.post(
          '/admin/inter-organizations',
          payload,
        ));
      }
      if (res?.success) {
        msg.success(
          res.message ||
            (editingRow ? 'Đã cập nhật cơ quan ngoài' : 'Đã thêm cơ quan ngoài'),
        );
        handleCloseDrawer();
        fetchData(pagination.current, pagination.pageSize);
      } else {
        const m = res?.message || 'Lưu thất bại';
        if (!setBackendFieldError(m)) msg.error(m);
      }
    } catch (err: unknown) {
      const errAny = err as {
        response?: { data?: { message?: string } };
        errorFields?: unknown;
      };
      // Form validation error → errorFields có sẵn, KHÔNG show msg riêng
      if (errAny.errorFields) return;
      const m = errAny.response?.data?.message || 'Lưu thất bại';
      if (!setBackendFieldError(m)) msg.error(m);
    } finally {
      setSaving(false);
    }
  };

  // ── Delete ───────────────────────────────────────────────────────────────
  const handleDelete = async (row: InterOrgRow) => {
    try {
      const { data: res } = await api.delete(
        `/admin/inter-organizations/${row.id}`,
      );
      if (res?.success) {
        msg.success(res.message || 'Đã xóa cơ quan ngoài');
        fetchData(pagination.current, pagination.pageSize);
      } else {
        msg.error(res?.message || 'Xóa thất bại');
      }
    } catch (err: unknown) {
      const errAny = err as { response?: { data?: { message?: string } } };
      msg.error(errAny.response?.data?.message || 'Xóa thất bại');
    }
  };

  // ── Columns ──────────────────────────────────────────────────────────────
  const columns: ColumnsType<InterOrgRow> = [
    {
      title: 'Mã cơ quan',
      dataIndex: 'code',
      width: 160,
      render: (val: string) => (
        <span style={{ fontFamily: 'monospace', fontWeight: 600 }}>{val}</span>
      ),
    },
    {
      title: 'Tên cơ quan',
      dataIndex: 'name',
      ellipsis: true,
      render: (val: string, row) => (
        <Space size={6}>
          <span>{val}</span>
          {row.lgsp_organ_id && (
            <Tooltip title={`Mã LGSP: ${row.lgsp_organ_id}`}>
              <Tag
                color="blue"
                icon={<ApiOutlined />}
                style={{ fontSize: 10 }}
              >
                LGSP
              </Tag>
            </Tooltip>
          )}
        </Space>
      ),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'is_active',
      width: 140,
      align: 'center',
      render: (val: boolean) =>
        val ? (
          <Tag color="green">Đã xác nhận</Tag>
        ) : (
          <Tooltip title="Cơ quan này được tự động đăng ký khi hệ thống nhận văn bản từ trục LGSP. Admin cần xác nhận để cho phép gửi văn bản đi.">
            <Tag color="orange">Tự đăng ký</Tag>
          </Tooltip>
        ),
    },
    {
      title: 'Địa chỉ',
      dataIndex: 'address',
      ellipsis: true,
      render: (v: string | null) => v || '—',
    },
    {
      title: 'Email',
      dataIndex: 'email',
      width: 200,
      ellipsis: true,
      render: (v: string | null) => v || '—',
    },
    {
      title: 'Điện thoại',
      dataIndex: 'phone',
      width: 130,
      render: (v: string | null) => v || '—',
    },
    {
      title: 'Ngày tạo',
      dataIndex: 'created_at',
      width: 150,
      render: (val: string) =>
        val ? (
          <span style={{ fontSize: 12 }}>
            {dayjs(val).format('DD/MM/YYYY HH:mm')}
          </span>
        ) : (
          '—'
        ),
    },
    ...(isAdmin
      ? [
          {
            title: 'Hành động',
            key: 'actions',
            width: 180,
            align: 'center' as const,
            render: (_: unknown, row: InterOrgRow) => (
              <Space size={4}>
                <Button
                  size="small"
                  icon={<EditOutlined />}
                  onClick={() => handleOpenEdit(row)}
                >
                  Sửa
                </Button>
                <Popconfirm
                  title="Xóa cơ quan ngoài?"
                  description="Hành động này không thể hoàn tác. Nếu cơ quan đang được tham chiếu bởi văn bản đến/đi, hệ thống sẽ chặn xóa."
                  okText="Xóa"
                  okType="danger"
                  cancelText="Hủy"
                  onConfirm={() => handleDelete(row)}
                >
                  <Button size="small" danger icon={<DeleteOutlined />}>
                    Xóa
                  </Button>
                </Popconfirm>
              </Space>
            ),
          },
        ]
      : []),
  ];

  // ── Render ───────────────────────────────────────────────────────────────
  return (
    <>
      <div className="page-header">
        <h2 className="page-title">
          <BankOutlined style={{ marginRight: 8, color: '#1B3A5C' }} />
          Cơ quan liên thông
        </h2>
        {isAdmin && (
          <Space>
            <Button
              icon={<PlusOutlined />}
              type="primary"
              onClick={handleOpenAdd}
            >
              Thêm mới
            </Button>
            <Button
              icon={<SyncOutlined spin={syncing} />}
              loading={syncing}
              onClick={handleSync}
            >
              Đồng bộ từ trục LGSP
            </Button>
          </Space>
        )}
      </div>

      <Card className="page-card">
        <div className="filter-row" style={{ marginBottom: 12 }}>
          <Row gutter={[12, 12]} align="middle">
            <Col xs={24} sm={12} md={9}>
              <Input
                placeholder="Tìm theo mã hoặc tên cơ quan..."
                prefix={<SearchOutlined />}
                value={searchInput}
                onChange={(e) => setSearchInput(e.target.value)}
                onPressEnter={() => setSearch(searchInput)}
                allowClear
                onClear={() => {
                  setSearchInput('');
                  setSearch('');
                }}
              />
            </Col>
            <Col xs={12} sm={6} md={5}>
              <Select<IsActiveFilter>
                style={{ width: '100%' }}
                value={isActiveFilter}
                onChange={(v) => setIsActiveFilter(v)}
                options={IS_ACTIVE_OPTIONS}
                placeholder="Trạng thái"
              />
            </Col>
            <Col xs={12} sm={6} md={4}>
              <Space>
                <Button
                  type="primary"
                  icon={<SearchOutlined />}
                  onClick={() => setSearch(searchInput)}
                >
                  Tìm
                </Button>
                <Tooltip title="Làm mới">
                  <Button
                    icon={<ReloadOutlined />}
                    onClick={() =>
                      fetchData(pagination.current, pagination.pageSize)
                    }
                  />
                </Tooltip>
              </Space>
            </Col>
          </Row>
        </div>

        <Table<InterOrgRow>
          rowKey="id"
          columns={columns}
          dataSource={data}
          loading={loading}
          pagination={{
            current: pagination.current,
            pageSize: pagination.pageSize,
            total: pagination.total,
            showSizeChanger: true,
            pageSizeOptions: ['20', '50', '100'],
            showTotal: (total) => `Tổng ${total} cơ quan`,
          }}
          onChange={handleTableChange}
          scroll={{ x: 1200 }}
          size="small"
        />
      </Card>

      {/* ── Drawer Add/Edit ── */}
      <Drawer
        title={
          editingRow
            ? `Sửa cơ quan — ${editingRow.code}`
            : 'Thêm cơ quan ngoài'
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
              <Form.Item
                label="Mã cơ quan"
                name="code"
                rules={[
                  { required: true, message: 'Bắt buộc nhập mã cơ quan' },
                  { max: 100, message: 'Mã cơ quan tối đa 100 ký tự' },
                ]}
                extra={
                  editingRow
                    ? 'Mã cơ quan KHÔNG đổi được sau khi tạo (liên kết FK với văn bản đã có)'
                    : undefined
                }
              >
                <Input
                  placeholder="VD: H37.BNV"
                  maxLength={100}
                  disabled={!!editingRow}
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label="Mã LGSP (lgsp_organ_id)"
                name="lgsp_organ_id"
                rules={[{ max: 100, message: 'Mã LGSP tối đa 100 ký tự' }]}
                extra="Để trống nếu cơ quan này không có mã trên trục LGSP"
              >
                <Input placeholder="VD: 000.00.00.H37" maxLength={100} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            label="Tên cơ quan"
            name="name"
            rules={[
              { required: true, message: 'Bắt buộc nhập tên cơ quan' },
              { max: 500, message: 'Tên cơ quan tối đa 500 ký tự' },
            ]}
          >
            <Input placeholder="VD: Bộ Nội vụ" maxLength={500} />
          </Form.Item>

          <Form.Item
            label="Địa chỉ"
            name="address"
            rules={[{ max: 500, message: 'Địa chỉ tối đa 500 ký tự' }]}
          >
            <Input.TextArea
              placeholder="Địa chỉ trụ sở (tùy chọn)"
              maxLength={500}
              rows={2}
              showCount
            />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                label="Email"
                name="email"
                rules={[
                  { type: 'email', message: 'Email không hợp lệ' },
                  { max: 200, message: 'Email tối đa 200 ký tự' },
                ]}
              >
                <Input placeholder="email@example.gov.vn" maxLength={200} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label="Điện thoại"
                name="phone"
                rules={[
                  {
                    pattern: /^[0-9+\-\s()]*$/,
                    message: 'Số điện thoại không hợp lệ',
                  },
                  { max: 50, message: 'Số điện thoại tối đa 50 ký tự' },
                ]}
              >
                <Input placeholder="VD: 0203 1234 567" maxLength={50} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            label="Trạng thái xác nhận"
            name="is_active"
            valuePropName="checked"
            initialValue={true}
            extra="Bật = cho phép gửi văn bản đi tới cơ quan này qua trục LGSP. Tắt = cơ quan chưa được admin xác nhận (thường do Phase 35 tự đăng ký từ văn bản đến)."
          >
            <Switch
              checkedChildren="Đã xác nhận"
              unCheckedChildren="Tự đăng ký"
            />
          </Form.Item>
        </Form>
      </Drawer>
    </>
  );
}
