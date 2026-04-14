'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Table, Button, Input, Select, Drawer, Form, DatePicker, Space,
  Tag, Modal, App, Tabs, Skeleton, Row, Col, Checkbox, Typography,
  Dropdown, Badge,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, MoreOutlined, CheckOutlined, CloseOutlined,
  ShoppingOutlined, RollbackOutlined, SearchOutlined, DeleteOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { api } from '@/lib/api';

const { TextArea } = Input;
const { Text } = Typography;

// ─── Constants ─────────────────────────────────────────────────────────────────

const STATUS_MAP: Record<number, { label: string; color: string }> = {
  0: { label: 'Mới', color: 'default' },
  1: { label: 'Đã duyệt', color: 'blue' },
  2: { label: 'Đã mượn', color: 'orange' },
  3: { label: 'Đã trả', color: 'green' },
  [-1]: { label: 'Từ chối', color: 'red' },
};

const FILTER_TABS = [
  { key: 'all', label: 'Tất cả' },
  { key: '0', label: 'Mới' },
  { key: '1', label: 'Đã duyệt' },
  { key: '2', label: 'Đã mượn' },
  { key: '3', label: 'Đã trả' },
  { key: '-1', label: 'Từ chối' },
];

const EMERGENCY_OPTIONS = [
  { value: 0, label: 'Bình thường' },
  { value: 1, label: 'Khẩn' },
];

// ─── Interfaces ────────────────────────────────────────────────────────────────

interface BorrowRequest {
  id: number;
  name: string;
  creator_name: string;
  borrow_date: string;
  status: number;
  created_date: string;
  notice?: string;
  emergency?: number;
}

interface HoSoRecord {
  id: number;
  file_code: string;
  title: string;
  fond_name: string;
  warehouse_name: string;
}

// ─── Main Component ────────────────────────────────────────────────────────────

export default function MuonTraPage() {
  const { message } = App.useApp();

  // Table state
  const [data, setData] = useState<BorrowRequest[]>([]);
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [initialLoading, setInitialLoading] = useState(true);

  // Filter state
  const [activeTab, setActiveTab] = useState('all');
  const [keyword, setKeyword] = useState('');

  // Drawer state — create borrow request
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  // Ho so selection in drawer
  const [hoSoList, setHoSoList] = useState<HoSoRecord[]>([]);
  const [hoSoLoading, setHoSoLoading] = useState(false);
  const [selectedRecordIds, setSelectedRecordIds] = useState<number[]>([]);
  const [hoSoKeyword, setHoSoKeyword] = useState('');

  // Reject modal
  const [rejectModal, setRejectModal] = useState<{ open: boolean; id: number | null }>({
    open: false,
    id: null,
  });
  const [rejectNotice, setRejectNotice] = useState('');
  const [rejectLoading, setRejectLoading] = useState(false);

  // ── Data fetching ─────────────────────────────────────────────────────────────

  const fetchList = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = { page, page_size: pageSize };
      if (activeTab !== 'all') params.status = Number(activeTab);
      if (keyword) params.keyword = keyword;
      const { data: res } = await api.get('/kho-luu-tru/muon-tra', { params });
      setData(res.data || []);
      setTotal(res.total ?? res.pagination?.total ?? 0);
    } catch {
      message.error('Lỗi tải danh sách mượn/trả');
    } finally {
      setLoading(false);
      setInitialLoading(false);
    }
  }, [page, pageSize, activeTab, keyword, message]);

  const fetchHoSo = useCallback(async () => {
    setHoSoLoading(true);
    try {
      const { data: res } = await api.get('/kho-luu-tru/ho-so', {
        params: { page: 1, page_size: 200 },
      });
      setHoSoList(res.data || []);
    } catch {
      // Bỏ qua lỗi tải hồ sơ
    } finally {
      setHoSoLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchList();
  }, [fetchList]);

  // ── Create drawer handlers ────────────────────────────────────────────────────

  const openCreateDrawer = () => {
    form.resetFields();
    setSelectedRecordIds([]);
    setHoSoKeyword('');
    fetchHoSo();
    setDrawerOpen(true);
  };

  const handleCreateSave = async () => {
    try {
      const values = await form.validateFields();
      if (selectedRecordIds.length === 0) {
        message.warning('Vui lòng chọn ít nhất một hồ sơ để mượn');
        return;
      }
      setSaving(true);
      const payload = {
        ...values,
        borrow_date: values.borrow_date ? dayjs(values.borrow_date).toISOString() : null,
        record_ids: selectedRecordIds,
      };
      await api.post('/kho-luu-tru/muon-tra', payload);
      message.success('Tạo yêu cầu mượn thành công');
      setDrawerOpen(false);
      fetchList();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; errorFields?: unknown[] };
      if (e?.errorFields) return;
      message.error(e?.response?.data?.message || 'Lỗi tạo yêu cầu mượn');
    } finally {
      setSaving(false);
    }
  };

  // ── Action handlers ───────────────────────────────────────────────────────────

  const handleApprove = async (id: number) => {
    try {
      await api.patch(`/kho-luu-tru/muon-tra/${id}/approve`);
      message.success('Đã duyệt yêu cầu mượn');
      fetchList();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Lỗi duyệt yêu cầu');
    }
  };

  const handleOpenReject = (id: number) => {
    setRejectNotice('');
    setRejectModal({ open: true, id });
  };

  const handleConfirmReject = async () => {
    if (!rejectModal.id) return;
    setRejectLoading(true);
    try {
      await api.patch(`/kho-luu-tru/muon-tra/${rejectModal.id}/reject`, { notice: rejectNotice });
      message.success('Đã từ chối yêu cầu mượn');
      setRejectModal({ open: false, id: null });
      fetchList();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Lỗi từ chối yêu cầu');
    } finally {
      setRejectLoading(false);
    }
  };

  const handleCheckout = (id: number) => {
    Modal.confirm({
      title: 'Xác nhận cho mượn',
      content: 'Xác nhận cho mượn hồ sơ này?',
      okText: 'Cho mượn',
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.patch(`/kho-luu-tru/muon-tra/${id}/checkout`);
          message.success('Đã cập nhật: Đã mượn');
          fetchList();
        } catch (err: unknown) {
          const e = err as { response?: { data?: { message?: string } } };
          message.error(e?.response?.data?.message || 'Lỗi cập nhật trạng thái');
        }
      },
    });
  };

  const handleReturn = (id: number) => {
    Modal.confirm({
      title: 'Xác nhận trả hồ sơ',
      content: 'Xác nhận người dùng đã trả hồ sơ?',
      okText: 'Xác nhận trả',
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.patch(`/kho-luu-tru/muon-tra/${id}/return`);
          message.success('Đã cập nhật: Đã trả');
          fetchList();
        } catch (err: unknown) {
          const e = err as { response?: { data?: { message?: string } } };
          message.error(e?.response?.data?.message || 'Lỗi cập nhật trạng thái');
        }
      },
    });
  };

  const handleDelete = (id: number, name: string) => {
    Modal.confirm({
      title: 'Xác nhận xóa',
      content: `Bạn có chắc muốn xóa yêu cầu "${name}"?`,
      okText: 'Xóa',
      cancelText: 'Hủy',
      okButtonProps: { danger: true },
      onOk: async () => {
        try {
          await api.delete(`/kho-luu-tru/muon-tra/${id}`);
          message.success('Đã xóa yêu cầu mượn');
          fetchList();
        } catch (err: unknown) {
          const e = err as { response?: { data?: { message?: string } } };
          message.error(e?.response?.data?.message || 'Lỗi xóa yêu cầu');
        }
      },
    });
  };

  // ── Filtered ho so list ───────────────────────────────────────────────────────

  const filteredHoSo = hoSoList.filter((hs) => {
    if (!hoSoKeyword.trim()) return true;
    const kw = hoSoKeyword.toLowerCase();
    return hs.title.toLowerCase().includes(kw) || hs.file_code.toLowerCase().includes(kw);
  });

  // ── Table columns ─────────────────────────────────────────────────────────────

  const columns: ColumnsType<BorrowRequest> = [
    {
      title: 'STT',
      width: 56,
      align: 'center',
      render: (_: unknown, __: BorrowRequest, index: number) =>
        (page - 1) * pageSize + index + 1,
    },
    {
      title: 'Tên yêu cầu',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
      render: (name: string) => (
        <span style={{ fontWeight: 500, color: '#1B3A5C' }}>{name}</span>
      ),
    },
    {
      title: 'Người yêu cầu',
      dataIndex: 'creator_name',
      key: 'creator_name',
      width: 160,
      ellipsis: true,
    },
    {
      title: 'Ngày mượn',
      dataIndex: 'borrow_date',
      key: 'borrow_date',
      width: 120,
      render: (d: string) => d ? dayjs(d).format('DD/MM/YYYY') : '—',
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      key: 'status',
      width: 120,
      render: (status: number) => {
        const s = STATUS_MAP[status] ?? { label: 'Không xác định', color: 'default' };
        return <Tag color={s.color}>{s.label}</Tag>;
      },
    },
    {
      title: 'Ngày tạo',
      dataIndex: 'created_date',
      key: 'created_date',
      width: 120,
      render: (d: string) => d ? dayjs(d).format('DD/MM/YYYY') : '—',
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 90,
      align: 'center',
      fixed: 'right',
      render: (_: unknown, record: BorrowRequest) => {
        type DividerItem = { type: 'divider'; key: string };
        type ActionItem = {
          key: string;
          icon: React.ReactNode;
          label: string;
          danger?: boolean;
          onClick: () => void;
        };
        const items: (ActionItem | DividerItem)[] = [];

        // Status 0 (Mới): Duyệt, Từ chối, Xóa
        if (record.status === 0) {
          items.push(
            {
              key: 'approve',
              icon: <CheckOutlined />,
              label: 'Duyệt',
              onClick: () => handleApprove(record.id),
            },
            {
              key: 'reject',
              icon: <CloseOutlined />,
              label: 'Từ chối',
              onClick: () => handleOpenReject(record.id),
            },
            { type: 'divider' as const, key: 'div1' },
            {
              key: 'delete',
              icon: <DeleteOutlined />,
              label: 'Xóa',
              danger: true,
              onClick: () => handleDelete(record.id, record.name),
            }
          );
        }

        // Status 1 (Đã duyệt): Cho mượn
        if (record.status === 1) {
          items.push({
            key: 'checkout',
            icon: <ShoppingOutlined />,
            label: 'Cho mượn',
            onClick: () => handleCheckout(record.id),
          });
        }

        // Status 2 (Đã mượn): Trả lại
        if (record.status === 2) {
          items.push({
            key: 'return',
            icon: <RollbackOutlined />,
            label: 'Trả lại',
            onClick: () => handleReturn(record.id),
          });
        }

        if (items.length === 0) return null;

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

  // ── Tab items ─────────────────────────────────────────────────────────────────

  const tabItems = FILTER_TABS.map((tab) => ({
    key: tab.key,
    label: (
      <span>
        {tab.label}
        {tab.key === 'all' && total > 0 && (
          <Badge
            count={total}
            size="small"
            style={{ backgroundColor: '#0891B2', marginLeft: 4 }}
            overflowCount={999}
          />
        )}
      </span>
    ),
  }));

  // ── Render ─────────────────────────────────────────────────────────────────────

  if (initialLoading) {
    return (
      <div style={{ padding: 24 }}>
        <Skeleton active paragraph={{ rows: 8 }} />
      </div>
    );
  }

  return (
    <div>
      {/* Page header */}
      <div className="page-header" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <h1 className="page-title">
            <ShoppingOutlined style={{ color: '#0891B2' }} />
            Quản lý mượn/trả hồ sơ
          </h1>
          <p className="page-description">Theo dõi và xử lý yêu cầu mượn, trả tài liệu lưu trữ</p>
        </div>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={openCreateDrawer}
        >
          Tạo yêu cầu mượn
        </Button>
      </div>

      <div className="page-card" style={{ padding: '16px 16px 0', background: '#fff' }}>
        {/* Status tabs */}
        <Tabs
          type="line"
          activeKey={activeTab}
          items={tabItems}
          onChange={(key) => {
            setActiveTab(key);
            setPage(1);
          }}
          style={{ marginBottom: 0 }}
        />

        {/* Filter row */}
        <div className="filter-row" style={{ padding: '12px 0' }}>
          <Space wrap>
            <Input
              placeholder="Tìm kiếm tên yêu cầu..."
              value={keyword}
              onChange={(e) => setKeyword(e.target.value)}
              onPressEnter={() => { setPage(1); fetchList(); }}
              prefix={<SearchOutlined style={{ color: '#94A3B8' }} />}
              allowClear
              style={{ width: 280 }}
            />
            <Button
              type="primary"
              icon={<SearchOutlined />}
              onClick={() => { setPage(1); fetchList(); }}
            >
              Tìm kiếm
            </Button>
          </Space>
        </div>

        {/* Table */}
        <Table<BorrowRequest>
          rowKey="id"
          loading={loading}
          columns={columns}
          dataSource={data}
          size="middle"
          scroll={{ x: 900 }}
          pagination={{
            current: page,
            pageSize,
            total,
            showSizeChanger: true,
            showTotal: (t) => `Tổng ${t} yêu cầu`,
            pageSizeOptions: ['10', '20', '50'],
            onChange: (p, ps) => { setPage(p); setPageSize(ps); },
          }}
          style={{ paddingBottom: 16 }}
        />
      </div>

      {/* Create borrow request drawer */}
      <Drawer
        title="Tạo yêu cầu mượn hồ sơ"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        destroyOnClose
        rootClassName="drawer-gradient"
        size={720}
        extra={
          <Space>
            <Button
              onClick={() => setDrawerOpen(false)}
              ghost
              style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}
            >
              Hủy
            </Button>
            <Button type="primary" loading={saving} onClick={handleCreateSave}>
              Tạo yêu cầu
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit">
          <Form.Item
            label="Tên yêu cầu"
            name="name"
            rules={[{ required: true, message: 'Nhập tên yêu cầu mượn' }]}
          >
            <Input placeholder="VD: Mượn hồ sơ dự án A" maxLength={200} />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item
                label="Ngày mượn"
                name="borrow_date"
                rules={[{ required: true, message: 'Chọn ngày mượn' }]}
              >
                <DatePicker
                  style={{ width: '100%' }}
                  format="DD/MM/YYYY"
                  placeholder="Chọn ngày mượn"
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item label="Mức độ ưu tiên" name="emergency" initialValue={0}>
                <Select options={EMERGENCY_OPTIONS} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item label="Ghi chú" name="notice">
            <TextArea rows={3} maxLength={1000} placeholder="Lý do mượn, ghi chú thêm..." />
          </Form.Item>

          {/* Ho so selection */}
          <div style={{ marginBottom: 8, display: 'flex', alignItems: 'center', gap: 8 }}>
            <Text strong style={{ color: '#1B3A5C' }}>
              Chọn hồ sơ cần mượn
            </Text>
            {selectedRecordIds.length > 0 && (
              <Tag color="#0891B2">Đã chọn {selectedRecordIds.length} hồ sơ</Tag>
            )}
          </div>

          <Input
            placeholder="Tìm kiếm hồ sơ..."
            value={hoSoKeyword}
            onChange={(e) => setHoSoKeyword(e.target.value)}
            prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
            allowClear
            style={{ marginBottom: 8 }}
          />

          <div
            style={{
              border: '1px solid #e8ecf1',
              borderRadius: 8,
              maxHeight: 280,
              overflowY: 'auto',
              padding: 8,
            }}
          >
            {hoSoLoading ? (
              <Skeleton active paragraph={{ rows: 4 }} />
            ) : filteredHoSo.length === 0 ? (
              <div style={{ textAlign: 'center', padding: 24, color: '#94a3b8' }}>
                Không có hồ sơ nào
              </div>
            ) : (
              filteredHoSo.map((hs) => (
                <div
                  key={hs.id}
                  style={{
                    display: 'flex',
                    alignItems: 'flex-start',
                    padding: '8px 4px',
                    borderBottom: '1px solid #f0f2f5',
                    cursor: 'pointer',
                  }}
                  onClick={() => {
                    setSelectedRecordIds((prev) =>
                      prev.includes(hs.id)
                        ? prev.filter((id) => id !== hs.id)
                        : [...prev, hs.id]
                    );
                  }}
                >
                  <Checkbox
                    checked={selectedRecordIds.includes(hs.id)}
                    style={{ marginRight: 8, marginTop: 2, flexShrink: 0 }}
                    onChange={() => {
                      setSelectedRecordIds((prev) =>
                        prev.includes(hs.id)
                          ? prev.filter((id) => id !== hs.id)
                          : [...prev, hs.id]
                      );
                    }}
                  />
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ fontWeight: 500, color: '#1B3A5C', fontSize: 13 }}>
                      [{hs.file_code}] {hs.title}
                    </div>
                    <div style={{ fontSize: 12, color: '#64748b', marginTop: 2 }}>
                      {hs.fond_name} · {hs.warehouse_name}
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        </Form>
      </Drawer>

      {/* Reject modal */}
      <Modal
        title="Từ chối yêu cầu mượn"
        open={rejectModal.open}
        onOk={handleConfirmReject}
        onCancel={() => setRejectModal({ open: false, id: null })}
        okText="Xác nhận từ chối"
        cancelText="Hủy"
        okButtonProps={{ danger: true, loading: rejectLoading }}
      >
        <div style={{ marginBottom: 8, color: '#64748b' }}>
          Nhập lý do từ chối (không bắt buộc):
        </div>
        <TextArea
          rows={4}
          value={rejectNotice}
          onChange={(e) => setRejectNotice(e.target.value)}
          placeholder="Lý do từ chối yêu cầu mượn hồ sơ..."
          maxLength={500}
        />
      </Modal>
    </div>
  );
}
