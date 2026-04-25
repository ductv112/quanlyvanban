'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Table, Button, Input, Select, DatePicker, Drawer, Form,
  Tag, Modal, App, Row, Col, Dropdown, Tabs, Badge, Progress,
  Space, Empty, Skeleton, TreeSelect,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, MoreOutlined, EyeOutlined, EditOutlined, DeleteOutlined,
  SearchOutlined, SaveOutlined, ExclamationCircleOutlined, PrinterOutlined,
} from '@ant-design/icons';
import { useRouter } from 'next/navigation';
import dayjs from 'dayjs';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import { buildTree, flattenTreeForSelect } from '@/lib/tree-utils';

const { TextArea } = Input;
const { RangePicker } = DatePicker;

// ─── Constants ────────────────────────────────────────────────────────────────

const STATUS_MAP: Record<number, { label: string; color: string }> = {
  0: { label: 'Mới tạo', color: '#1677FF' },
  1: { label: 'Đang xử lý', color: '#0891B2' },
  2: { label: 'Chờ trình ký', color: '#D97706' },
  3: { label: 'Đã trình ký', color: '#7C3AED' },
  4: { label: 'Hoàn thành', color: '#059669' },
  '-1': { label: 'Từ chối', color: '#DC2626' },
  '-2': { label: 'Trả về', color: '#F59E0B' },
};

const FILTER_TABS = [
  { key: 'all', label: 'Tất cả' },
  { key: 'created_by_me', label: 'Tôi tạo' },
  { key: 'rejected', label: 'Bị từ chối' },
  { key: 'returned', label: 'Trả về bổ sung' },
  { key: 'pending_primary', label: 'Chưa XL phụ trách' },
  { key: 'pending_coord', label: 'Chưa XL phối hợp' },
  { key: 'submitting', label: 'Trình ký' },
  { key: 'in_progress', label: 'Đang giải quyết' },
  { key: 'proposed_complete', label: 'Đề xuất hoàn thành' },
  { key: 'completed', label: 'Đã hoàn thành' },
];

// ─── Interfaces ───────────────────────────────────────────────────────────────

interface HscvRecord {
  id: number;
  name: string;
  start_date: string;
  end_date: string;
  status: number;
  curator_id: number;
  curator_name: string;
  signer_id: number;
  signer_name: string;
  progress: number;
  doc_type_id: number | null;
  doc_type_name: string | null;
  doc_field_id: number | null;
  doc_field_name: string | null;
  workflow_id: number | null;
  workflow_name: string | null;
  parent_id: number | null;
  parent_name: string | null;
  note: string | null;
  created_by: number;
  created_at: string;
  total_count: number;
}

interface SelectOption {
  value: number;
  label: string;
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function HoSoCongViecPage() {
  const { message, modal } = App.useApp();
  const router = useRouter();
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  const user = useAuthStore((s) => s.user);

  // Table state
  const [data, setData] = useState<HscvRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [initialLoading, setInitialLoading] = useState(true);

  // Filter state
  const [filterType, setFilterType] = useState('all');
  const [keyword, setKeyword] = useState('');
  const [fieldId, setFieldId] = useState<number | undefined>();
  const [unitId, setUnitId] = useState<number | undefined>();
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs] | null>(null);

  // Badge counts
  const [statusCounts, setStatusCounts] = useState<Record<string, number>>({});

  // Drawer state
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<HscvRecord | null>(null);
  const [formLoading, setFormLoading] = useState(false);
  const [form] = Form.useForm();

  // Select options
  const [docTypes, setDocTypes] = useState<SelectOption[]>([]);
  const [docFields, setDocFields] = useState<SelectOption[]>([]);
  const [staffList, setStaffList] = useState<SelectOption[]>([]);   // Người phụ trách: all staff cùng đơn vị
  const [leaderList, setLeaderList] = useState<SelectOption[]>([]); // Lãnh đạo ký: chỉ is_leader=true cùng đơn vị
  const [workflows, setWorkflows] = useState<SelectOption[]>([]);
  const [parentHscvs, setParentHscvs] = useState<SelectOption[]>([]);
  const [units, setUnits] = useState<SelectOption[]>([]);
  const [deptTreeData, setDeptTreeData] = useState<{ value: number; title: string; children?: any[] }[]>([]);

  // ── Data fetching ────────────────────────────────────────────────────────────

  const fetchList = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = {
        filter_type: filterType,
        page,
        page_size: pageSize,
      };
      if (keyword) params.keyword = keyword;
      if (fieldId) params.field_id = fieldId;
      if (unitId) params.department_id = unitId;
      if (dateRange) {
        params.from_date = dateRange[0].startOf('day').toISOString();
        params.to_date = dateRange[1].endOf('day').toISOString();
      }
      const { data: res } = await api.get('/ho-so-cong-viec', { params });
      setData(res.data || []);
      setTotal(res.pagination?.total || 0);
    } catch {
      message.error('Lỗi tải danh sách hồ sơ công việc');
    } finally {
      setLoading(false);
      setInitialLoading(false);
    }
  }, [filterType, page, pageSize, keyword, fieldId, unitId, dateRange, message]);

  const fetchCounts = useCallback(async () => {
    try {
      const { data: res } = await api.get('/ho-so-cong-viec/count-by-status');
      setStatusCounts(res.data || {});
    } catch {
      // Bỏ qua lỗi đếm — không ảnh hưởng trải nghiệm chính
    }
  }, []);

  const fetchOptions = useCallback(async () => {
    try {
      const [typeRes, fieldRes, staffRes, workflowRes, hscvRes, unitRes] = await Promise.all([
        api.get('/quan-tri/loai-van-ban/tree').catch(() => ({ data: { data: [] } })),
        api.get('/quan-tri/linh-vuc').catch(() => ({ data: { data: [] } })),
        // Bug fix: filter staff cùng đơn vị (Người phụ trách) + lọc thêm is_leader cho Lãnh đạo ký
        api.get('/ho-so-cong-viec/nhan-vien-cung-don-vi').catch(() => ({ data: { data: [] } })),
        api.get('/quan-tri/quy-trinh').catch(() => ({ data: { data: [] } })),
        api.get('/ho-so-cong-viec', { params: { page: 1, page_size: 200, filter_type: 'all' } }).catch(() => ({ data: { data: [] } })),
        api.get('/quan-tri/don-vi').catch(() => ({ data: { data: [] } })),
      ]);
      setDocTypes((typeRes.data.data || []).map((t: { id: number; name: string }) => ({ value: t.id, label: t.name })));
      setDocFields((fieldRes.data.data || []).map((f: { id: number; name: string }) => ({ value: f.id, label: f.name })));
      const staffItems: { id: number; full_name: string; is_leader?: boolean }[] = staffRes.data.data || [];
      setStaffList(staffItems.map((s) => ({ value: s.id, label: s.full_name })));
      setLeaderList(staffItems.filter((s) => s.is_leader).map((s) => ({ value: s.id, label: s.full_name })));
      setWorkflows((workflowRes.data.data || []).map((w: { id: number; name: string }) => ({ value: w.id, label: w.name })));
      setParentHscvs((hscvRes.data.data || []).map((h: { id: number; name: string }) => ({ value: h.id, label: h.name })));
      const unitItems = unitRes.data.data || [];
      setUnits(unitItems.map((u: { id: number; name: string }) => ({ value: u.id, label: u.name })));
      if (user?.isAdmin) {
        const tree = buildTree(unitItems.map((d: any) => ({ id: d.id, parent_id: d.parent_id, name: d.name })));
        setDeptTreeData(flattenTreeForSelect(tree));
      }
    } catch {
      // Bỏ qua lỗi tải tùy chọn
    }
  }, [user?.isAdmin]);

  useEffect(() => {
    fetchOptions();
    fetchCounts();
  }, [fetchOptions, fetchCounts]);

  useEffect(() => {
    fetchList();
  }, [fetchList]);

  // ── Drawer handlers ──────────────────────────────────────────────────────────

  const openDrawer = (record?: HscvRecord) => {
    if (record) {
      setEditingRecord(record);
      form.setFieldsValue({
        ...record,
        start_date: record.start_date ? dayjs(record.start_date) : null,
        end_date: record.end_date ? dayjs(record.end_date) : null,
      });
    } else {
      setEditingRecord(null);
      form.resetFields();
    }
    setDrawerOpen(true);
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setFormLoading(true);

      const payload = {
        ...values,
        start_date: values.start_date?.toISOString() || null,
        end_date: values.end_date?.toISOString() || null,
      };

      if (editingRecord) {
        const { data: res } = await api.put(`/ho-so-cong-viec/${editingRecord.id}`, payload);
        if (!res.success) { message.error(res.message || 'Lưu hồ sơ thất bại'); return; }
        message.success('Lưu hồ sơ thành công');
      } else {
        const { data: res } = await api.post('/ho-so-cong-viec', payload);
        if (!res.success) { message.error(res.message || 'Lưu hồ sơ thất bại'); return; }
        message.success('Tạo hồ sơ thành công');
      }

      setDrawerOpen(false);
      fetchList();
      fetchCounts();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; errorFields?: unknown[] };
      if (e?.errorFields) return; // lỗi validation form — Ant Design tự hiển thị
      if (e?.response?.data?.message) {
        message.error(e.response.data.message);
      } else {
        message.error('Lưu hồ sơ thất bại. Vui lòng kiểm tra lại thông tin và thử lại.');
      }
    } finally {
      setFormLoading(false);
    }
  };

  const handleDelete = (record: HscvRecord) => {
    modal.confirm({
      title: 'Xóa hồ sơ',
      type: 'warning',
      icon: <ExclamationCircleOutlined style={{ color: '#D97706' }} />,
      content: 'Bạn có chắc muốn xóa hồ sơ này? Hành động này không thể hoàn tác.',
      okText: 'Xóa',
      okType: 'danger',
      cancelText: 'Hủy bỏ',
      onOk: async () => {
        try {
          await api.delete(`/ho-so-cong-viec/${record.id}`);
          message.success('Đã xóa hồ sơ');
          fetchList();
          fetchCounts();
        } catch (err: unknown) {
          const e = err as { response?: { data?: { message?: string } } };
          message.error(e?.response?.data?.message || 'Lỗi xóa hồ sơ');
        }
      },
    });
  };

  const handleSearch = () => {
    setPage(1);
    fetchList();
  };

  const handleReset = () => {
    setKeyword('');
    setFieldId(undefined);
    setUnitId(undefined);
    setDateRange(null);
    setPage(1);
  };

  // ── Table columns ────────────────────────────────────────────────────────────

  const now = dayjs();

  const columns: ColumnsType<HscvRecord> = [
    {
      title: 'STT',
      width: 56,
      align: 'center',
      render: (_: unknown, __: HscvRecord, index: number) => (page - 1) * pageSize + index + 1,
    },
    {
      title: 'Tên hồ sơ công việc',
      dataIndex: 'name',
      ellipsis: true,
      render: (name: string, record: HscvRecord) => (
        <a
          onClick={() => router.push(`/ho-so-cong-viec/${record.id}`)}
          style={{ fontWeight: 500, color: '#1B3A5C', cursor: 'pointer' }}
        >
          {name}
        </a>
      ),
    },
    {
      title: 'Ngày mở',
      dataIndex: 'start_date',
      width: 110,
      render: (d: string) => d ? dayjs(d).format('DD/MM/YYYY') : '—',
    },
    {
      title: 'Hạn giải quyết',
      dataIndex: 'end_date',
      width: 130,
      render: (d: string, record: HscvRecord) => {
        if (!d) return '—';
        const isOverdue = dayjs(d).isBefore(now) && record.status !== 4;
        return (
          <span style={{ color: isOverdue ? '#DC2626' : undefined, fontWeight: isOverdue ? 600 : undefined }}>
            {isOverdue && <ExclamationCircleOutlined style={{ marginRight: 4 }} />}
            {dayjs(d).format('DD/MM/YYYY')}
          </span>
        );
      },
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      width: 140,
      render: (status: number) => {
        const statusEntry = STATUS_MAP[status] || { label: 'Không xác định', color: '#94A3B8' };
        return <Tag color={statusEntry.color}>{statusEntry.label}</Tag>;
      },
    },
    {
      title: 'Phụ trách',
      dataIndex: 'curator_name',
      width: 150,
      ellipsis: true,
    },
    {
      title: 'Lãnh đạo ký',
      dataIndex: 'signer_name',
      width: 150,
      ellipsis: true,
    },
    {
      title: 'Tiến độ',
      dataIndex: 'progress',
      width: 140,
      render: (percent: number) => (
        <Progress percent={percent || 0} size="small" strokeColor="#0891B2" />
      ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 80,
      align: 'center',
      fixed: 'right',
      render: (_: unknown, record: HscvRecord) => {
        const items = [
          {
            key: 'view',
            icon: <EyeOutlined />,
            label: 'Xem chi tiết',
            onClick: () => router.push(`/ho-so-cong-viec/${record.id}`),
          },
          {
            key: 'edit',
            icon: <EditOutlined />,
            label: 'Sửa',
            onClick: () => openDrawer(record),
          },
          { type: 'divider' as const },
          {
            key: 'delete',
            icon: <DeleteOutlined />,
            label: 'Xóa',
            danger: true,
            onClick: () => handleDelete(record),
          },
        ];
        return (
          <Dropdown trigger={['click']} menu={{ items }}>
            <Button
              type="text"
              size="small"
              icon={<MoreOutlined style={{ fontSize: 18 }} />}
              style={{ color: '#64748b' }}
              aria-label="Thao tác"
            />
          </Dropdown>
        );
      },
    },
  ];

  // ── Tab items ────────────────────────────────────────────────────────────────

  const tabItems = FILTER_TABS.map((tab) => ({
    key: tab.key,
    label: (
      <span>
        {tab.label}{' '}
        <Badge
          count={statusCounts[tab.key] || 0}
          size="small"
          style={{
            backgroundColor: filterType === tab.key ? '#0891B2' : '#94A3B8',
            marginLeft: 2,
          }}
        />
      </span>
    ),
  }));

  // ── Render ───────────────────────────────────────────────────────────────────

  if (initialLoading) {
    return (
      <div className="page-card">
        <Skeleton active paragraph={{ rows: 6 }} />
      </div>
    );
  }

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <h1 className="page-title">Hồ sơ công việc</h1>
        <Space>
          <Button icon={<PrinterOutlined />} onClick={() => window.print()}>In</Button>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => openDrawer()}
          >
            Tạo hồ sơ mới
          </Button>
        </Space>
      </div>

      <div className="page-card">
        {/* Filter Tabs */}
        <Tabs
          type="line"
          activeKey={filterType}
          items={tabItems}
          onChange={(key) => {
            setFilterType(key);
            setPage(1);
          }}
          style={{ marginBottom: 0 }}
        />

        {/* Filter Row */}
        <div className="list-filter-bar">
          <div className="filter-row" style={{ marginTop: 12 }}>
            <Space wrap>
              <Input
                placeholder="Tìm kiếm tên hồ sơ..."
                value={keyword}
                onChange={(e) => setKeyword(e.target.value)}
                onPressEnter={handleSearch}
                style={{ width: 240 }}
                prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
                allowClear
              />
              <Select
                placeholder="Lĩnh vực"
                allowClear
                options={docFields}
                value={fieldId}
                onChange={(val) => { setFieldId(val); setPage(1); }}
                style={{ width: 160 }}
              />
              {user?.isAdmin ? (
                <TreeSelect
                  placeholder="Phòng ban"
                  allowClear
                  showSearch
                  treeNodeFilterProp="title"
                  treeData={deptTreeData}
                  value={unitId}
                  onChange={(val) => { setUnitId(val); setPage(1); }}
                  style={{ width: 200 }}
                />
              ) : (
                <Select
                  placeholder="Đơn vị"
                  allowClear
                  options={units}
                  value={unitId}
                  onChange={(val) => { setUnitId(val); setPage(1); }}
                  style={{ width: 160 }}
                />
              )}
              <RangePicker
                format="DD/MM/YYYY"
                placeholder={['Từ ngày', 'Đến ngày']}
                value={dateRange}
                onChange={(val) => {
                  setDateRange(val as [dayjs.Dayjs, dayjs.Dayjs] | null);
                  setPage(1);
                }}
                style={{ width: 220 }}
              />
              <Button type="primary" icon={<SearchOutlined />} onClick={handleSearch}>
                Tìm kiếm
              </Button>
              <Button onClick={handleReset}>Đặt lại</Button>
            </Space>
          </div>
        </div>

        {/* Table */}
        <Table<HscvRecord>
          className="enhanced-table"
          rowKey="id"
          loading={loading}
          columns={columns}
          dataSource={data}
          size="small"
          scroll={{ x: 1200 }}
          locale={{
            emptyText: (
              <Empty
                description={
                  keyword || fieldId || unitId || dateRange
                    ? 'Không tìm thấy hồ sơ phù hợp. Thử thay đổi bộ lọc hoặc từ khóa tìm kiếm.'
                    : (
                      <span>
                        Chưa có hồ sơ công việc<br />
                        <span style={{ color: '#64748B', fontSize: 13 }}>
                          Nhấn &ldquo;Tạo hồ sơ mới&rdquo; để bắt đầu quản lý công việc của bạn.
                        </span>
                      </span>
                    )
                }
              />
            ),
          }}
          pagination={{
            current: page,
            pageSize,
            total,
            showSizeChanger: true,
            showTotal: (t) => `Tổng ${t} hồ sơ`,
            pageSizeOptions: ['10', '20', '50', '100'],
            onChange: (p, ps) => { setPage(p); setPageSize(ps); },
          }}
        />
      </div>

      {/* Drawer tạo/sửa HSCV */}
      <Drawer forceRender
        title={editingRecord ? 'Chỉnh sửa hồ sơ công việc' : 'Tạo hồ sơ công việc'}
        size={720}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        rootClassName="drawer-gradient"
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)}>Hủy</Button>
            <Button
              type="primary"
              icon={<SaveOutlined />}
              loading={formLoading}
              onClick={handleSave}
            >
              Lưu hồ sơ
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
          {/* Tên hồ sơ — full width */}
          <Row gutter={16}>
            <Col span={24}>
              <Form.Item
                name="name"
                label="Tên hồ sơ công việc"
                rules={[{ required: true, message: 'Vui lòng nhập tên hồ sơ công việc' }]}
              >
                <Input placeholder="Nhập tên hồ sơ công việc" maxLength={500} showCount />
              </Form.Item>
            </Col>
          </Row>

          {/* Loại văn bản + Lĩnh vực */}
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="doc_type_id" label="Loại văn bản">
                <Select
                  placeholder="Chọn loại văn bản"
                  allowClear
                  options={docTypes}
                  showSearch
                  optionFilterProp="label"
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="doc_field_id" label="Lĩnh vực">
                <Select
                  placeholder="Chọn lĩnh vực"
                  allowClear
                  options={docFields}
                  showSearch
                  optionFilterProp="label"
                />
              </Form.Item>
            </Col>
          </Row>

          {/* Ngày mở + Hạn giải quyết */}
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="start_date"
                label="Ngày mở"
                rules={[{ required: true, message: 'Vui lòng chọn ngày mở hồ sơ' }]}
              >
                <DatePicker
                  style={{ width: '100%' }}
                  format="DD/MM/YYYY"
                  placeholder="Chọn ngày mở"
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="end_date"
                label="Hạn giải quyết"
                dependencies={['start_date']}
                rules={[
                  { required: true, message: 'Vui lòng chọn hạn giải quyết' },
                  ({ getFieldValue }) => ({
                    validator(_, value) {
                      const startDate = getFieldValue('start_date');
                      if (!value || !startDate) return Promise.resolve();
                      if (!value.isBefore(startDate, 'day')) return Promise.resolve();
                      return Promise.reject(new Error('Hạn giải quyết phải sau hoặc bằng ngày mở hồ sơ'));
                    },
                  }),
                ]}
              >
                <DatePicker
                  style={{ width: '100%' }}
                  format="DD/MM/YYYY"
                  placeholder="Chọn hạn giải quyết"
                />
              </Form.Item>
            </Col>
          </Row>

          {/* Người phụ trách + Lãnh đạo ký */}
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                name="curator_id"
                label="Người phụ trách"
                rules={[{ required: true, message: 'Vui lòng chọn người phụ trách' }]}
              >
                <Select
                  placeholder="Tìm và chọn người phụ trách"
                  showSearch
                  optionFilterProp="label"
                  options={staffList}
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="signer_id"
                label="Lãnh đạo ký"
                rules={[{ required: true, message: 'Vui lòng chọn lãnh đạo ký' }]}
              >
                <Select
                  placeholder="Tìm và chọn lãnh đạo ký"
                  showSearch
                  optionFilterProp="label"
                  options={leaderList}
                  notFoundContent={leaderList.length === 0 ? 'Đơn vị chưa có lãnh đạo' : 'Không tìm thấy'}
                />
              </Form.Item>
            </Col>
          </Row>

          {/* Quy trình + HSCV cha */}
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="workflow_id" label="Quy trình">
                <Select
                  placeholder="Chọn quy trình xử lý"
                  allowClear
                  options={workflows}
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="parent_id" label="Hồ sơ cha">
                <Select
                  placeholder="Chọn hồ sơ cha (nếu là hồ sơ con)"
                  allowClear
                  showSearch
                  optionFilterProp="label"
                  options={parentHscvs}
                />
              </Form.Item>
            </Col>
          </Row>

          {/* Ghi chú — full width */}
          <Row gutter={16}>
            <Col span={24}>
              <Form.Item name="note" label="Ghi chú">
                <TextArea
                  rows={3}
                  placeholder="Nhập ghi chú (nếu có)"
                  maxLength={2000}
                  showCount
                />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Drawer>

      <div className="print-area">
        <div className="print-header">
          <h2>DANH SÁCH HỒ SƠ CÔNG VIỆC</h2>
          <p>Ngày in: {dayjs().format('DD/MM/YYYY HH:mm')}</p>
        </div>
        <table>
          <thead>
            <tr><th>STT</th><th>Tên hồ sơ</th><th>Ngày bắt đầu</th><th>Hạn hoàn thành</th><th>Người phụ trách</th><th>Tiến độ</th><th>Trạng thái</th></tr>
          </thead>
          <tbody>
            {data.map((r, i) => (
              <tr key={r.id}>
                <td style={{ textAlign: 'center' }}>{i + 1}</td>
                <td>{r.name}</td>
                <td>{r.start_date ? dayjs(r.start_date).format('DD/MM/YYYY') : ''}</td>
                <td>{r.end_date ? dayjs(r.end_date).format('DD/MM/YYYY') : ''}</td>
                <td>{r.curator_name}</td>
                <td style={{ textAlign: 'center' }}>{r.progress}%</td>
                <td>{r.status === 0 ? 'Mới' : r.status === 1 ? 'Đang xử lý' : r.status === 2 ? 'Trình duyệt' : r.status === 3 ? 'Hoàn thành' : ''}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="print-footer">Tổng: {data.length} hồ sơ</div>
      </div>
    </div>
  );
}
