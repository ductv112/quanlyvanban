'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Table, Button, Input, Select, DatePicker, Drawer, Form,
  Tag, Modal, App, Row, Col, Dropdown, Space, Skeleton, TimePicker,
  Divider,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, MoreOutlined, EyeOutlined, EditOutlined, DeleteOutlined,
  SearchOutlined, SaveOutlined, ExclamationCircleOutlined, CheckOutlined, CloseOutlined,
  TeamOutlined,
} from '@ant-design/icons';
import { useRouter } from 'next/navigation';
import dayjs from 'dayjs';
import { api } from '@/lib/api';

const { TextArea } = Input;
const { RangePicker } = DatePicker;

// ─── Constants ─────────────────────────────────────────────────────────────────

const APPROVED_MAP: Record<number, { label: string; color: string }> = {
  0: { label: 'Chưa duyệt', color: 'default' },
  1: { label: 'Đã duyệt', color: 'green' },
  [-1]: { label: 'Từ chối', color: 'red' },
};

const MEETING_STATUS_MAP: Record<number, { label: string; color: string }> = {
  0: { label: 'Chưa họp', color: 'default' },
  1: { label: 'Đang họp', color: 'processing' },
  2: { label: 'Đã họp', color: 'success' },
  3: { label: 'Hủy', color: 'error' },
};

// ─── Interfaces ──────────────────────────────────────────────────────────────

interface Room {
  id: number;
  code: string;
  name: string;
  location: string;
  sort_order: number;
  note: string | null;
  show_in_calendar: boolean;
}

interface MeetingType {
  id: number;
  name: string;
  description: string | null;
  sort_order: number;
}

interface MeetingRecord {
  id: number;
  name: string;
  room_id: number | null;
  room_name: string | null;
  meeting_type_id: number | null;
  meeting_type_name: string | null;
  content: string | null;
  start_date: string;
  end_date: string | null;
  start_time: string | null;
  end_time: string | null;
  master_id: number | null;
  master_name: string | null;
  secretary_id: number | null;
  secretary_name: string | null;
  online_link: string | null;
  component: string | null;
  approved: number;
  meeting_status: number;
  rejection_reason: string | null;
  created_at: string;
  total_count: number;
}

interface StaffOption {
  value: number;
  label: string;
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function CuocHopPage() {
  const { message, modal } = App.useApp();
  const router = useRouter();

  // Table state
  const [data, setData] = useState<MeetingRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [initialLoading, setInitialLoading] = useState(true);

  // Filter state
  const [roomIdFilter, setRoomIdFilter] = useState<number | undefined>();
  const [approvedFilter, setApprovedFilter] = useState<number | undefined>();
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs] | null>(null);
  const [keyword, setKeyword] = useState('');

  // Options
  const [rooms, setRooms] = useState<Room[]>([]);
  const [meetingTypes, setMeetingTypes] = useState<MeetingType[]>([]);
  const [staffOptions, setStaffOptions] = useState<StaffOption[]>([]);

  // Create/Edit Drawer
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<MeetingRecord | null>(null);
  const [formLoading, setFormLoading] = useState(false);
  const [form] = Form.useForm();

  // Room Management Drawer
  const [roomDrawerOpen, setRoomDrawerOpen] = useState(false);
  const [roomLoading, setRoomLoading] = useState(false);
  const [roomForm] = Form.useForm();
  const [editingRoom, setEditingRoom] = useState<Room | null>(null);
  const [roomFormOpen, setRoomFormOpen] = useState(false);
  const [roomFormLoading, setRoomFormLoading] = useState(false);

  // Type Management Drawer
  const [typeDrawerOpen, setTypeDrawerOpen] = useState(false);
  const [typeLoading, setTypeLoading] = useState(false);
  const [typeForm] = Form.useForm();
  const [editingType, setEditingType] = useState<MeetingType | null>(null);
  const [typeFormOpen, setTypeFormOpen] = useState(false);
  const [typeFormLoading, setTypeFormLoading] = useState(false);

  // Reject modal
  const [rejectModalOpen, setRejectModalOpen] = useState(false);
  const [rejectingId, setRejectingId] = useState<number | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');

  // ── Data fetching ─────────────────────────────────────────────────────────────

  const fetchList = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = { page, page_size: pageSize };
      if (roomIdFilter) params.room_id = roomIdFilter;
      if (approvedFilter !== undefined) params.status = approvedFilter;
      if (keyword) params.keyword = keyword;
      if (dateRange) {
        params.from_date = dateRange[0].startOf('day').toISOString();
        params.to_date = dateRange[1].endOf('day').toISOString();
      }
      const { data: res } = await api.get('/cuoc-hop', { params });
      setData(res.data || []);
      setTotal(res.pagination?.total || 0);
    } catch {
      message.error('Lỗi tải danh sách cuộc họp');
    } finally {
      setLoading(false);
      setInitialLoading(false);
    }
  }, [page, pageSize, roomIdFilter, approvedFilter, keyword, dateRange, message]);

  const fetchRooms = useCallback(async () => {
    try {
      const { data: res } = await api.get('/cuoc-hop/phong-hop');
      setRooms(res.data || []);
    } catch {
      // silent
    }
  }, []);

  const fetchMeetingTypes = useCallback(async () => {
    try {
      const { data: res } = await api.get('/cuoc-hop/loai-cuoc-hop');
      setMeetingTypes(res.data || []);
    } catch {
      // silent
    }
  }, []);

  const fetchStaff = useCallback(async () => {
    try {
      const { data: res } = await api.get('/quan-tri/nguoi-dung', { params: { page: 1, page_size: 500 } });
      setStaffOptions((res.data || []).map((s: { id: number; full_name: string }) => ({ value: s.id, label: s.full_name })));
    } catch {
      // silent
    }
  }, []);

  useEffect(() => {
    fetchRooms();
    fetchMeetingTypes();
    fetchStaff();
  }, [fetchRooms, fetchMeetingTypes, fetchStaff]);

  useEffect(() => {
    fetchList();
  }, [fetchList]);

  // ── Drawer handlers ──────────────────────────────────────────────────────────

  const openDrawer = (record?: MeetingRecord) => {
    if (record) {
      setEditingRecord(record);
      form.setFieldsValue({
        ...record,
        start_date: record.start_date ? dayjs(record.start_date) : null,
        end_date: record.end_date ? dayjs(record.end_date) : null,
        start_time: record.start_time ? dayjs(record.start_time, 'HH:mm') : null,
        end_time: record.end_time ? dayjs(record.end_time, 'HH:mm') : null,
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
        start_time: values.start_time ? values.start_time.format('HH:mm') : null,
        end_time: values.end_time ? values.end_time.format('HH:mm') : null,
      };

      if (editingRecord) {
        const { data: res } = await api.put(`/cuoc-hop/${editingRecord.id}`, payload);
        if (!res.success) { message.error(res.message || 'Lưu thất bại'); return; }
        message.success('Lưu cuộc họp thành công');
      } else {
        const { data: res } = await api.post('/cuoc-hop', payload);
        if (!res.success) { message.error(res.message || 'Tạo thất bại'); return; }
        message.success('Đăng ký cuộc họp thành công');
      }
      setDrawerOpen(false);
      fetchList();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; errorFields?: unknown[] };
      if (e?.errorFields) return;
      message.error(e?.response?.data?.message || 'Lỗi lưu cuộc họp');
    } finally {
      setFormLoading(false);
    }
  };

  const handleDelete = (record: MeetingRecord) => {
    modal.confirm({
      title: 'Xóa cuộc họp',
      icon: <ExclamationCircleOutlined style={{ color: '#DC2626' }} />,
      content: `Bạn có chắc muốn xóa cuộc họp "${record.name}"?`,
      okText: 'Xóa',
      okType: 'danger',
      cancelText: 'Hủy bỏ',
      onOk: async () => {
        try {
          await api.delete(`/cuoc-hop/${record.id}`);
          message.success('Đã xóa cuộc họp');
          fetchList();
        } catch (err: unknown) {
          const e = err as { response?: { data?: { message?: string } } };
          message.error(e?.response?.data?.message || 'Lỗi xóa cuộc họp');
        }
      },
    });
  };

  const handleApprove = async (id: number) => {
    try {
      const { data: res } = await api.patch(`/cuoc-hop/${id}/approve`);
      if (!res.success) { message.error(res.message || 'Duyệt thất bại'); return; }
      message.success('Đã duyệt cuộc họp');
      fetchList();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Lỗi duyệt cuộc họp');
    }
  };

  const openRejectModal = (id: number) => {
    setRejectingId(id);
    setRejectionReason('');
    setRejectModalOpen(true);
  };

  const handleReject = async () => {
    if (!rejectingId) return;
    try {
      const { data: res } = await api.patch(`/cuoc-hop/${rejectingId}/reject`, { rejection_reason: rejectionReason });
      if (!res.success) { message.error(res.message || 'Từ chối thất bại'); return; }
      message.success('Đã từ chối cuộc họp');
      setRejectModalOpen(false);
      fetchList();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Lỗi từ chối cuộc họp');
    }
  };

  // ── Room CRUD ──────────────────────────────────────────────────────────────

  const openRoomDrawer = async () => {
    setRoomLoading(true);
    setRoomDrawerOpen(true);
    try {
      await fetchRooms();
    } finally {
      setRoomLoading(false);
    }
  };

  const openRoomForm = (room?: Room) => {
    if (room) {
      setEditingRoom(room);
      roomForm.setFieldsValue(room);
    } else {
      setEditingRoom(null);
      roomForm.resetFields();
    }
    setRoomFormOpen(true);
  };

  const handleSaveRoom = async () => {
    try {
      const values = await roomForm.validateFields();
      setRoomFormLoading(true);
      if (editingRoom) {
        await api.put(`/cuoc-hop/phong-hop/${editingRoom.id}`, values);
        message.success('Lưu phòng họp thành công');
      } else {
        await api.post('/cuoc-hop/phong-hop', values);
        message.success('Thêm phòng họp thành công');
      }
      setRoomFormOpen(false);
      fetchRooms();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; errorFields?: unknown[] };
      if (e?.errorFields) return;
      message.error(e?.response?.data?.message || 'Lỗi lưu phòng họp');
    } finally {
      setRoomFormLoading(false);
    }
  };

  const handleDeleteRoom = (room: Room) => {
    modal.confirm({
      title: 'Xóa phòng họp',
      icon: <ExclamationCircleOutlined style={{ color: '#DC2626' }} />,
      content: `Bạn có chắc muốn xóa phòng "${room.name}"?`,
      okText: 'Xóa',
      okType: 'danger',
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.delete(`/cuoc-hop/phong-hop/${room.id}`);
          message.success('Đã xóa phòng họp');
          fetchRooms();
        } catch {
          message.error('Lỗi xóa phòng họp');
        }
      },
    });
  };

  // ── Meeting Type CRUD ──────────────────────────────────────────────────────

  const openTypeDrawer = async () => {
    setTypeLoading(true);
    setTypeDrawerOpen(true);
    try {
      await fetchMeetingTypes();
    } finally {
      setTypeLoading(false);
    }
  };

  const openTypeForm = (type?: MeetingType) => {
    if (type) {
      setEditingType(type);
      typeForm.setFieldsValue(type);
    } else {
      setEditingType(null);
      typeForm.resetFields();
    }
    setTypeFormOpen(true);
  };

  const handleSaveType = async () => {
    try {
      const values = await typeForm.validateFields();
      setTypeFormLoading(true);
      if (editingType) {
        await api.put(`/cuoc-hop/loai-cuoc-hop/${editingType.id}`, values);
        message.success('Lưu loại cuộc họp thành công');
      } else {
        await api.post('/cuoc-hop/loai-cuoc-hop', values);
        message.success('Thêm loại cuộc họp thành công');
      }
      setTypeFormOpen(false);
      fetchMeetingTypes();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; errorFields?: unknown[] };
      if (e?.errorFields) return;
      message.error(e?.response?.data?.message || 'Lỗi lưu loại cuộc họp');
    } finally {
      setTypeFormLoading(false);
    }
  };

  const handleDeleteType = (type: MeetingType) => {
    modal.confirm({
      title: 'Xóa loại cuộc họp',
      icon: <ExclamationCircleOutlined style={{ color: '#DC2626' }} />,
      content: `Bạn có chắc muốn xóa loại "${type.name}"?`,
      okText: 'Xóa',
      okType: 'danger',
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.delete(`/cuoc-hop/loai-cuoc-hop/${type.id}`);
          message.success('Đã xóa loại cuộc họp');
          fetchMeetingTypes();
        } catch {
          message.error('Lỗi xóa loại cuộc họp');
        }
      },
    });
  };

  // ── Table columns ────────────────────────────────────────────────────────────

  const columns: ColumnsType<MeetingRecord> = [
    {
      title: 'STT',
      width: 56,
      align: 'center',
      render: (_: unknown, __: MeetingRecord, index: number) => (page - 1) * pageSize + index + 1,
    },
    {
      title: 'Tên cuộc họp',
      dataIndex: 'name',
      ellipsis: true,
      render: (name: string, record: MeetingRecord) => (
        <a onClick={() => router.push(`/cuoc-hop/${record.id}`)} style={{ color: '#1B3A5C', fontWeight: 500 }}>
          {name}
        </a>
      ),
    },
    {
      title: 'Phòng họp',
      dataIndex: 'room_name',
      width: 140,
      ellipsis: true,
      render: (v: string | null) => v || '—',
    },
    {
      title: 'Loại',
      dataIndex: 'meeting_type_name',
      width: 130,
      ellipsis: true,
      render: (v: string | null) => v || '—',
    },
    {
      title: 'Ngày họp',
      dataIndex: 'start_date',
      width: 110,
      render: (v: string) => v ? dayjs(v).format('DD/MM/YYYY') : '—',
    },
    {
      title: 'Giờ',
      width: 110,
      render: (_: unknown, record: MeetingRecord) => {
        if (record.start_time && record.end_time) return `${record.start_time} - ${record.end_time}`;
        if (record.start_time) return record.start_time;
        return '—';
      },
    },
    {
      title: 'Chủ tọa',
      dataIndex: 'master_name',
      width: 140,
      ellipsis: true,
      render: (v: string | null) => v || '—',
    },
    {
      title: 'Trạng thái duyệt',
      dataIndex: 'approved',
      width: 130,
      render: (v: number) => {
        const s = APPROVED_MAP[v] || APPROVED_MAP[0];
        return <Tag color={s.color}>{s.label}</Tag>;
      },
    },
    {
      title: 'Trạng thái họp',
      dataIndex: 'meeting_status',
      width: 130,
      render: (v: number) => {
        const s = MEETING_STATUS_MAP[v] || MEETING_STATUS_MAP[0];
        return <Tag color={s.color}>{s.label}</Tag>;
      },
    },
    {
      title: 'Thao tác',
      width: 56,
      align: 'center',
      render: (_: unknown, record: MeetingRecord) => (
        <Dropdown
          menu={{
            items: [
              {
                key: 'view',
                icon: <EyeOutlined />,
                label: 'Xem chi tiết',
                onClick: () => router.push(`/cuoc-hop/${record.id}`),
              },
              {
                key: 'edit',
                icon: <EditOutlined />,
                label: 'Chỉnh sửa',
                onClick: () => openDrawer(record),
              },
              ...(record.approved === 0 ? [
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
                  onClick: () => openRejectModal(record.id),
                },
              ] : []),
              { type: 'divider' as const },
              {
                key: 'delete',
                icon: <DeleteOutlined />,
                label: 'Xóa',
                danger: true,
                disabled: record.approved !== 0,
                onClick: () => handleDelete(record),
              },
            ],
          }}
          trigger={['click']}
        >
          <Button type="text" icon={<MoreOutlined />} size="small" />
        </Dropdown>
      ),
    },
  ];

  // ── Room table columns ───────────────────────────────────────────────────────

  const roomColumns: ColumnsType<Room> = [
    { title: 'Mã', dataIndex: 'code', width: 80 },
    { title: 'Tên phòng', dataIndex: 'name', ellipsis: true },
    { title: 'Địa điểm', dataIndex: 'location', ellipsis: true },
    {
      title: 'Thao tác',
      width: 80,
      align: 'center',
      render: (_: unknown, record: Room) => (
        <Space>
          <Button type="text" size="small" icon={<EditOutlined />} onClick={() => openRoomForm(record)} />
          <Button type="text" size="small" icon={<DeleteOutlined />} danger onClick={() => handleDeleteRoom(record)} />
        </Space>
      ),
    },
  ];

  // ── Type table columns ───────────────────────────────────────────────────────

  const typeColumns: ColumnsType<MeetingType> = [
    { title: 'Tên loại', dataIndex: 'name', ellipsis: true },
    { title: 'Mô tả', dataIndex: 'description', ellipsis: true, render: (v: string | null) => v || '—' },
    {
      title: 'Thao tác',
      width: 80,
      align: 'center',
      render: (_: unknown, record: MeetingType) => (
        <Space>
          <Button type="text" size="small" icon={<EditOutlined />} onClick={() => openTypeForm(record)} />
          <Button type="text" size="small" icon={<DeleteOutlined />} danger onClick={() => handleDeleteType(record)} />
        </Space>
      ),
    },
  ];

  // ── Render ───────────────────────────────────────────────────────────────────

  if (initialLoading) {
    return (
      <div className="page-card">
        <Skeleton active paragraph={{ rows: 8 }} />
      </div>
    );
  }

  return (
    <div className="page-card">
      {/* Header */}
      <div className="page-header">
        <h2 className="page-title">Cuộc họp</h2>
        <Space>
          <Button icon={<TeamOutlined />} onClick={openTypeDrawer}>Loại cuộc họp</Button>
          <Button icon={<SearchOutlined />} onClick={openRoomDrawer}>Phòng họp</Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => openDrawer()}>Đăng ký cuộc họp</Button>
        </Space>
      </div>

      {/* Filter row */}
      <div className="filter-row">
        <Row gutter={[12, 12]} align="middle">
          <Col>
            <Select
              placeholder="Phòng họp"
              allowClear
              style={{ width: 180 }}
              value={roomIdFilter}
              onChange={(v) => { setRoomIdFilter(v); setPage(1); }}
              options={rooms.map((r) => ({ value: r.id, label: r.name }))}
            />
          </Col>
          <Col>
            <Select
              placeholder="Trạng thái duyệt"
              allowClear
              style={{ width: 160 }}
              value={approvedFilter}
              onChange={(v) => { setApprovedFilter(v); setPage(1); }}
              options={[
                { value: 0, label: 'Chưa duyệt' },
                { value: 1, label: 'Đã duyệt' },
                { value: -1, label: 'Từ chối' },
              ]}
            />
          </Col>
          <Col>
            <RangePicker
              value={dateRange}
              onChange={(v) => { setDateRange(v as [dayjs.Dayjs, dayjs.Dayjs] | null); setPage(1); }}
              placeholder={['Từ ngày', 'Đến ngày']}
              format="DD/MM/YYYY"
            />
          </Col>
          <Col flex="auto">
            <Input
              prefix={<SearchOutlined />}
              placeholder="Tìm kiếm tên cuộc họp..."
              value={keyword}
              onChange={(e) => setKeyword(e.target.value)}
              onPressEnter={() => setPage(1)}
              allowClear
            />
          </Col>
          <Col>
            <Button type="primary" icon={<SearchOutlined />} onClick={() => setPage(1)}>Tìm kiếm</Button>
          </Col>
        </Row>
      </div>

      {/* Main table */}
      <Table<MeetingRecord>
        rowKey="id"
        columns={columns}
        dataSource={data}
        loading={loading}
        pagination={{
          current: page,
          pageSize,
          total,
          showSizeChanger: true,
          showTotal: (t) => `Tổng ${t} cuộc họp`,
          onChange: (p, ps) => { setPage(p); setPageSize(ps); },
        }}
        onRow={(record) => ({
          onDoubleClick: () => router.push(`/cuoc-hop/${record.id}`),
          style: { cursor: 'pointer' },
        })}
        scroll={{ x: 1100 }}
        size="small"
      />

      {/* ── Create/Edit Meeting Drawer ─────────────────────────────────────────── */}
      <Drawer
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        title={editingRecord ? 'Chỉnh sửa cuộc họp' : 'Đăng ký cuộc họp'}
        width={720}
        rootClassName="drawer-gradient"
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)}>Hủy</Button>
            <Button type="primary" icon={<SaveOutlined />} loading={formLoading} onClick={handleSave}>Lưu</Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" validateTrigger="onSubmit">
          <Row gutter={16}>
            <Col span={24}>
              <Form.Item name="name" label="Tên cuộc họp" rules={[{ required: true, message: 'Vui lòng nhập tên cuộc họp' }]}>
                <Input placeholder="Nhập tên cuộc họp" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="room_id" label="Phòng họp">
                <Select placeholder="Chọn phòng họp" allowClear options={rooms.map((r) => ({ value: r.id, label: r.name }))} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="meeting_type_id" label="Loại cuộc họp">
                <Select placeholder="Chọn loại cuộc họp" allowClear options={meetingTypes.map((t) => ({ value: t.id, label: t.name }))} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="start_date" label="Ngày họp" rules={[{ required: true, message: 'Vui lòng chọn ngày họp' }]}>
                <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" placeholder="Chọn ngày" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="end_date" label="Ngày kết thúc">
                <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" placeholder="Chọn ngày" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="start_time" label="Giờ bắt đầu">
                <TimePicker style={{ width: '100%' }} format="HH:mm" placeholder="HH:mm" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="end_time" label="Giờ kết thúc">
                <TimePicker style={{ width: '100%' }} format="HH:mm" placeholder="HH:mm" />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="master_id" label="Chủ tọa">
                <Select placeholder="Chọn chủ tọa" allowClear options={staffOptions} showSearch filterOption={(input, opt) => (opt?.label as string || '').toLowerCase().includes(input.toLowerCase())} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="secretary_id" label="Thư ký">
                <Select placeholder="Chọn thư ký" allowClear options={staffOptions} showSearch filterOption={(input, opt) => (opt?.label as string || '').toLowerCase().includes(input.toLowerCase())} />
              </Form.Item>
            </Col>
            <Col span={24}>
              <Form.Item name="online_link" label="Đường dẫn họp trực tuyến">
                <Input placeholder="https://..." />
              </Form.Item>
            </Col>
            <Col span={24}>
              <Form.Item name="component" label="Thành phần tham dự">
                <Input placeholder="Nhập thành phần tham dự" />
              </Form.Item>
            </Col>
            <Col span={24}>
              <Form.Item name="content" label="Nội dung">
                <TextArea rows={4} placeholder="Nhập nội dung cuộc họp" />
              </Form.Item>
            </Col>
          </Row>
        </Form>
      </Drawer>

      {/* ── Room Management Drawer ────────────────────────────────────────────── */}
      <Drawer
        open={roomDrawerOpen}
        onClose={() => setRoomDrawerOpen(false)}
        title="Quản lý phòng họp"
        width={600}
        extra={<Button type="primary" icon={<PlusOutlined />} onClick={() => openRoomForm()}>Thêm phòng</Button>}
      >
        <Table<Room>
          rowKey="id"
          columns={roomColumns}
          dataSource={rooms}
          loading={roomLoading}
          size="small"
          pagination={false}
        />

        {/* Sub-form inside room drawer */}
        <Modal
          open={roomFormOpen}
          onCancel={() => setRoomFormOpen(false)}
          title={editingRoom ? 'Chỉnh sửa phòng họp' : 'Thêm phòng họp'}
          onOk={handleSaveRoom}
          confirmLoading={roomFormLoading}
          okText="Lưu"
          cancelText="Hủy"
        >
          <Form form={roomForm} layout="vertical">
            <Form.Item name="code" label="Mã phòng" rules={[{ required: true, message: 'Vui lòng nhập mã phòng' }]}>
              <Input placeholder="VD: P101" />
            </Form.Item>
            <Form.Item name="name" label="Tên phòng" rules={[{ required: true, message: 'Vui lòng nhập tên phòng' }]}>
              <Input placeholder="Nhập tên phòng họp" />
            </Form.Item>
            <Form.Item name="location" label="Địa điểm">
              <Input placeholder="Nhập địa điểm" />
            </Form.Item>
            <Form.Item name="sort_order" label="Thứ tự sắp xếp">
              <Input type="number" />
            </Form.Item>
            <Form.Item name="note" label="Ghi chú">
              <TextArea rows={2} />
            </Form.Item>
          </Form>
        </Modal>
      </Drawer>

      {/* ── Meeting Type Management Drawer ───────────────────────────────────── */}
      <Drawer
        open={typeDrawerOpen}
        onClose={() => setTypeDrawerOpen(false)}
        title="Quản lý loại cuộc họp"
        width={600}
        extra={<Button type="primary" icon={<PlusOutlined />} onClick={() => openTypeForm()}>Thêm loại</Button>}
      >
        <Table<MeetingType>
          rowKey="id"
          columns={typeColumns}
          dataSource={meetingTypes}
          loading={typeLoading}
          size="small"
          pagination={false}
        />

        <Modal
          open={typeFormOpen}
          onCancel={() => setTypeFormOpen(false)}
          title={editingType ? 'Chỉnh sửa loại cuộc họp' : 'Thêm loại cuộc họp'}
          onOk={handleSaveType}
          confirmLoading={typeFormLoading}
          okText="Lưu"
          cancelText="Hủy"
        >
          <Form form={typeForm} layout="vertical">
            <Form.Item name="name" label="Tên loại" rules={[{ required: true, message: 'Vui lòng nhập tên loại' }]}>
              <Input placeholder="Nhập tên loại cuộc họp" />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <TextArea rows={2} />
            </Form.Item>
            <Form.Item name="sort_order" label="Thứ tự sắp xếp">
              <Input type="number" />
            </Form.Item>
          </Form>
        </Modal>
      </Drawer>

      {/* ── Reject Modal ──────────────────────────────────────────────────────── */}
      <Modal
        open={rejectModalOpen}
        onCancel={() => setRejectModalOpen(false)}
        title="Từ chối cuộc họp"
        onOk={handleReject}
        okText="Xác nhận từ chối"
        okButtonProps={{ danger: true }}
        cancelText="Hủy"
      >
        <div style={{ marginBottom: 8 }}>Lý do từ chối:</div>
        <TextArea
          rows={3}
          value={rejectionReason}
          onChange={(e) => setRejectionReason(e.target.value)}
          placeholder="Nhập lý do từ chối..."
        />
      </Modal>

      {/* ── Approve/Reject inline ─────────────────────────────────────────────── */}
      <div style={{ display: 'none' }}>
        {/* api.patch for approve and reject — referenced in actions above */}
      </div>
    </div>
  );
}
