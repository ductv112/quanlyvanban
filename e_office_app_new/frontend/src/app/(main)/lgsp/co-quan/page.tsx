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
  Select,
  App,
  Tooltip,
  Row,
  Col,
  Alert,
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
import { useUserRights } from '@/hooks/use-user-rights';
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
  const { hasRight } = useUserRights();
  // Phase 37.1: granular right_id=25 (RIGHT_LGSP_CATALOG) thay vi role hardcode.
  // Variable name "isAdmin" giu nguyen de minimize diff (reuse trong cot Hanh dong + Drawer + Sync button).
  const isAdmin = hasRight(25);

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

  // ── Delete: fetch usage truoc, hien Modal voi count + canh bao ───────────
  const handleDeleteWithCheck = async (row: InterOrgRow) => {
    let usage: {
      outgoing_count: number;
      incoming_count: number;
    } | null = null;
    try {
      const { data: res } = await api.get(
        `/admin/inter-organizations/${row.id}/usage`,
      );
      usage = res?.data ?? null;
    } catch (err: unknown) {
      const errAny = err as { response?: { data?: { message?: string } } };
      msg.error(
        errAny.response?.data?.message || 'Không kiểm tra được tham chiếu',
      );
      return;
    }
    if (!usage) {
      msg.error('Không kiểm tra được tham chiếu');
      return;
    }

    const { outgoing_count, incoming_count } = usage;
    const isBlocked = outgoing_count > 0;
    const hasIncoming = incoming_count > 0;

    modal.confirm({
      title: isBlocked
        ? `Không thể xóa: ${row.name}`
        : hasIncoming
          ? `Xác nhận xóa: ${row.name}`
          : `Xóa cơ quan: ${row.name}`,
      width: 560,
      icon: isBlocked ? null : undefined,
      content: (
        <div style={{ marginTop: 8 }}>
          <div style={{ marginBottom: 12 }}>
            <Tag style={{ fontFamily: 'monospace', fontWeight: 600 }}>
              {row.code}
            </Tag>
            {row.is_active ? (
              <Tag color="green">Đã xác nhận</Tag>
            ) : (
              <Tag color="orange">Tự đăng ký</Tag>
            )}
          </div>

          <div
            style={{
              border: '1px solid #e5e7eb',
              borderRadius: 6,
              padding: '12px 14px',
              marginBottom: 12,
              background: '#f9fafb',
            }}
          >
            <div style={{ marginBottom: 6 }}>
              <strong>Tham chiếu hiện tại:</strong>
            </div>
            <div style={{ marginBottom: 4 }}>
              📤 Văn bản đi tham chiếu:{' '}
              <strong
                style={{
                  color: isBlocked ? '#DC2626' : '#059669',
                }}
              >
                {outgoing_count}
              </strong>
            </div>
            <div>
              📥 Văn bản đến từ LGSP (sender code này):{' '}
              <strong
                style={{
                  color: hasIncoming ? '#D97706' : '#059669',
                }}
              >
                {incoming_count}
              </strong>
            </div>
          </div>

          {isBlocked && (
            <Alert
              type="error"
              showIcon
              title="Không thể xóa cơ quan này"
              description={
                <>
                  Còn <strong>{outgoing_count}</strong> văn bản đi đã chọn cơ
                  quan này làm nơi nhận. Hệ thống sẽ chặn xóa (DB foreign key
                  constraint).
                  <br />
                  <br />
                  <strong>Cách xử lý:</strong>
                  <ul style={{ marginTop: 6, marginBottom: 0, paddingLeft: 20 }}>
                    <li>Bỏ chọn cơ quan này trong các VB đi đó, hoặc</li>
                    <li>
                      Bỏ tích &quot;Đã xác nhận&quot; (is_active) để ẩn cơ quan
                      khỏi dropdown gửi VB mới mà vẫn giữ data lịch sử
                    </li>
                  </ul>
                </>
              }
            />
          )}

          {!isBlocked && hasIncoming && (
            <Alert
              type="warning"
              showIcon
              title={`${incoming_count} văn bản đến sẽ mất tên hiển thị`}
              description={
                <>
                  Khi xóa cơ quan này, <strong>{incoming_count}</strong> văn
                  bản đến từ LGSP có mã sender này sẽ KHÔNG còn link tới
                  catalog. UI sẽ fallback hiển thị tên đơn vị gửi từ bản gốc
                  edXML (vẫn giữ data, chỉ mất link). Có muốn tiếp tục?
                </>
              }
            />
          )}

          {!isBlocked && !hasIncoming && (
            <Alert
              type="info"
              showIcon
              title="Không có văn bản nào tham chiếu cơ quan này"
              description="Xóa sẽ KHÔNG ảnh hưởng VB nào."
            />
          )}
        </div>
      ),
      okText: isBlocked ? 'Đóng' : hasIncoming ? 'Vẫn xóa' : 'Xóa',
      okType: isBlocked ? 'default' : 'danger',
      okButtonProps: isBlocked
        ? { type: 'default' }
        : { danger: true, type: 'primary' },
      cancelText: 'Hủy',
      cancelButtonProps: isBlocked ? { style: { display: 'none' } } : undefined,
      onOk: async () => {
        if (isBlocked) return;
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
          const errAny = err as {
            response?: { data?: { message?: string } };
          };
          msg.error(errAny.response?.data?.message || 'Xóa thất bại');
        }
      },
    });
  };

  // ── Columns ──────────────────────────────────────────────────────────────
  const columns: ColumnsType<InterOrgRow> = [
    {
      title: 'Mã cơ quan',
      dataIndex: 'code',
      width: 110,
      render: (val: string) => (
        <span style={{ fontFamily: 'monospace', fontWeight: 600 }}>{val}</span>
      ),
    },
    {
      title: 'Tên cơ quan',
      dataIndex: 'name',
      width: 280,
      ellipsis: { showTitle: true },
      render: (val: string, row) => (
        <Space size={6}>
          <span title={val}>{val}</span>
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
      width: 120,
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
      width: 220,
      ellipsis: { showTitle: true },
      render: (v: string | null) => <span title={v ?? ''}>{v || '—'}</span>,
    },
    {
      title: 'Email',
      dataIndex: 'email',
      width: 180,
      ellipsis: { showTitle: true },
      render: (v: string | null) => <span title={v ?? ''}>{v || '—'}</span>,
    },
    {
      title: 'Điện thoại',
      dataIndex: 'phone',
      width: 110,
      render: (v: string | null) => v || '—',
    },
    {
      title: 'Ngày tạo',
      dataIndex: 'created_at',
      width: 130,
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
            width: 140,
            align: 'center' as const,
            fixed: 'right' as const,
            render: (_: unknown, row: InterOrgRow) => (
              <Space size={4}>
                <Tooltip title="Sửa">
                  <Button
                    size="small"
                    type="text"
                    icon={<EditOutlined />}
                    onClick={() => handleOpenEdit(row)}
                  />
                </Tooltip>
                <Tooltip title="Xóa">
                  <Button
                    size="small"
                    type="text"
                    danger
                    icon={<DeleteOutlined />}
                    onClick={() => handleDeleteWithCheck(row)}
                  />
                </Tooltip>
              </Space>
            ),
          },
        ]
      : []),
  ];

  // ── Render ───────────────────────────────────────────────────────────────
  return (
    <>
    <Card
      className="page-card"
      title={
        <>
          <BankOutlined style={{ marginRight: 8 }} />
          Cơ quan liên thông
        </>
      }
      extra={
        isAdmin && (
          <Space>
            <Button
              type="primary"
              icon={<PlusOutlined />}
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
        )
      }
    >
      <div className="list-filter-bar">
        <Row gutter={[10, 10]} align="middle">
          <Col xs={24} sm={12} md={9}>
            <Input.Search
              placeholder="Tìm theo mã hoặc tên cơ quan..."
              allowClear
              value={searchInput}
              onChange={(e) => setSearchInput(e.target.value)}
              onSearch={(val) => setSearch(val)}
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
          <Col xs={12} sm={6} md={2}>
            <Tooltip title="Làm mới">
              <Button
                icon={<ReloadOutlined />}
                onClick={() =>
                  fetchData(pagination.current, pagination.pageSize)
                }
              />
            </Tooltip>
          </Col>
        </Row>
      </div>

      {/* Empty state banner: hien khi count=0 (sau khi load xong) */}
      {!loading && data.length === 0 && isActiveFilter === '' && !searchInput && (
        <Alert
          type="info"
          showIcon
          style={{ marginBottom: 16 }}
          title="Danh sách cơ quan ngoài hiện rỗng"
          description={
            isAdmin
              ? 'Bấm "Đồng bộ từ LGSP" phía trên để lấy catalog cơ quan từ trục liên thông (cần ít nhất 1 DN đã kích hoạt credential trong "Cấu hình kết nối"). Hoặc bấm "Thêm cơ quan" để thêm thủ công.'
              : 'Liên hệ Quản trị hệ thống để đồng bộ catalog cơ quan từ trục LGSP.'
          }
        />
      )}

      <Table<InterOrgRow>
        className="enhanced-table"
        rowKey="id"
        columns={columns}
        dataSource={data}
        loading={loading}
        size="small"
        scroll={{ x: 1290 }}
        pagination={{
          current: pagination.current,
          pageSize: pagination.pageSize,
          total: pagination.total,
          showSizeChanger: true,
          pageSizeOptions: ['20', '50', '100'],
          showTotal: (total) => `Tổng ${total} cơ quan`,
        }}
        onChange={handleTableChange}
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
