'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Calendar,
  Badge,
  Drawer,
  Form,
  Input,
  DatePicker,
  Switch,
  Select,
  Button,
  Segmented,
  Table,
  Skeleton,
  App,
  Modal,
  Tag,
  ColorPicker,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import type { Dayjs } from 'dayjs';
import dayjs from 'dayjs';
import { PlusOutlined, DeleteOutlined, CalendarOutlined, UnorderedListOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';

interface CalendarEvent {
  id: number;
  title: string;
  description?: string;
  start_time: string;
  end_time: string;
  all_day: boolean;
  color: string;
  repeat_type: string;
  scope: string;
  created_by_name?: string;
}

const REPEAT_OPTIONS = [
  { value: 'none', label: 'Không lặp lại' },
  { value: 'daily', label: 'Hàng ngày' },
  { value: 'weekly', label: 'Hàng tuần' },
  { value: 'monthly', label: 'Hàng tháng' },
];

const VIEW_OPTIONS = [
  { label: <span><CalendarOutlined /> Lịch</span>, value: 'calendar' },
  { label: <span><UnorderedListOutlined /> Danh sách</span>, value: 'list' },
];

export default function LichCoQuanPage() {
  const { message: msg } = App.useApp();
  const { modal } = App.useApp();
  const user = useAuthStore((s) => s.user);

  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(false);
  const [currentDate, setCurrentDate] = useState<Dayjs>(dayjs());
  const [viewMode, setViewMode] = useState<'calendar' | 'list'>('calendar');

  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingEvent, setEditingEvent] = useState<CalendarEvent | null>(null);
  const [drawerLoading, setDrawerLoading] = useState(false);
  const [form] = Form.useForm();

  const isAdminOrSecretary = user?.roles?.some((r) =>
    ['admin', 'secretary', 'van_thu', 'ADMIN', 'SECRETARY'].includes(r)
  ) || user?.isAdmin;

  const fetchEvents = useCallback(async (date: Dayjs) => {
    setLoading(true);
    try {
      const start = date.startOf('month').format('YYYY-MM-DD');
      const end = date.endOf('month').format('YYYY-MM-DD');
      const { data: res } = await api.get('/lich/events', {
        params: { scope: 'unit', start, end, unit_id: user?.unitId },
      });
      setEvents(res.data || []);
    } catch {
      setEvents([]);
    } finally {
      setLoading(false);
    }
  }, [user?.unitId]);

  useEffect(() => {
    fetchEvents(currentDate);
  }, [currentDate, fetchEvents]);

  const getEventsForDate = (date: Dayjs): CalendarEvent[] => {
    return events.filter((ev) => dayjs(ev.start_time).isSame(date, 'day'));
  };

  const cellRender = (date: Dayjs) => {
    const dayEvents = getEventsForDate(date);
    if (!dayEvents.length) return null;
    return (
      <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
        {dayEvents.slice(0, 3).map((ev) => (
          <li key={ev.id}>
            <Badge
              color={ev.color || '#0891B2'}
              text={
                <span
                  style={{
                    fontSize: 11,
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                    maxWidth: 100,
                    display: 'inline-block',
                    cursor: 'pointer',
                    color: '#1B3A5C',
                  }}
                  onClick={(e) => {
                    e.stopPropagation();
                    openEditDrawer(ev);
                  }}
                >
                  {ev.title}
                </span>
              }
            />
          </li>
        ))}
        {dayEvents.length > 3 && (
          <li>
            <Tag color="default" style={{ fontSize: 10, lineHeight: '16px' }}>
              +{dayEvents.length - 3} sự kiện
            </Tag>
          </li>
        )}
      </ul>
    );
  };

  const openEditDrawer = (event: CalendarEvent) => {
    setEditingEvent(event);
    form.setFieldsValue({
      title: event.title,
      description: event.description,
      start_time: event.start_time ? dayjs(event.start_time) : null,
      end_time: event.end_time ? dayjs(event.end_time) : null,
      all_day: event.all_day,
      color: event.color || '#0891B2',
      repeat_type: event.repeat_type || 'none',
    });
    setDrawerOpen(true);
  };

  const openCreateDrawer = () => {
    setEditingEvent(null);
    form.resetFields();
    form.setFieldsValue({
      start_time: dayjs().hour(8).minute(0),
      end_time: dayjs().hour(9).minute(0),
      all_day: false,
      color: '#0891B2',
      repeat_type: 'none',
    });
    setDrawerOpen(true);
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setDrawerLoading(true);
      const payload = {
        ...values,
        start_time: values.start_time?.toISOString(),
        end_time: values.end_time?.toISOString(),
        color: typeof values.color === 'string' ? values.color : values.color?.toHexString?.() || '#0891B2',
        scope: 'unit',
        unit_id: user?.unitId,
      };

      if (editingEvent) {
        await api.put(`/lich/events/${editingEvent.id}`, payload);
        msg.success('Cập nhật sự kiện thành công');
      } else {
        await api.post('/lich/events', payload);
        msg.success('Tạo sự kiện thành công');
      }
      setDrawerOpen(false);
      form.resetFields();
      setEditingEvent(null);
      fetchEvents(currentDate);
    } catch (err: any) {
      if (err?.errorFields) return;
      msg.error(err?.response?.data?.message || 'Lưu sự kiện thất bại');
    } finally {
      setDrawerLoading(false);
    }
  };

  const handleDelete = () => {
    if (!editingEvent) return;
    modal.confirm({
      title: 'Xóa sự kiện',
      content: `Bạn có chắc chắn muốn xóa sự kiện "${editingEvent.title}"?`,
      okText: 'Xóa',
      cancelText: 'Hủy',
      okButtonProps: { danger: true },
      onOk: async () => {
        try {
          await api.delete(`/lich/events/${editingEvent.id}`);
          msg.success('Xóa sự kiện thành công');
          setDrawerOpen(false);
          setEditingEvent(null);
          fetchEvents(currentDate);
        } catch (err: any) {
          msg.error(err?.response?.data?.message || 'Xóa sự kiện thất bại');
        }
      },
    });
  };

  // List view — current week events
  const weekEvents = events.filter((ev) => {
    const evDate = dayjs(ev.start_time);
    return evDate.isSame(dayjs(), 'week');
  }).sort((a, b) => dayjs(a.start_time).unix() - dayjs(b.start_time).unix());

  const listColumns: ColumnsType<CalendarEvent> = [
    {
      title: 'Tiêu đề',
      dataIndex: 'title',
      key: 'title',
      render: (text, record) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <div
            style={{
              width: 10,
              height: 10,
              borderRadius: '50%',
              background: record.color || '#0891B2',
              flexShrink: 0,
            }}
          />
          <span style={{ fontWeight: 500, color: '#1B3A5C' }}>{text}</span>
        </div>
      ),
    },
    {
      title: 'Thời gian',
      key: 'time',
      width: 200,
      render: (_, record) => (
        <span style={{ fontSize: 13, color: '#64748b' }}>
          {record.all_day
            ? dayjs(record.start_time).format('DD/MM/YYYY') + ' (Cả ngày)'
            : `${dayjs(record.start_time).format('DD/MM HH:mm')} - ${dayjs(record.end_time).format('HH:mm')}`}
        </span>
      ),
    },
    {
      title: 'Mô tả',
      dataIndex: 'description',
      key: 'description',
      render: (text) => <span style={{ color: '#64748b', fontSize: 13 }}>{text || '—'}</span>,
    },
    {
      title: 'Người tạo',
      dataIndex: 'created_by_name',
      key: 'created_by_name',
      width: 150,
      render: (text) => <span style={{ fontSize: 13 }}>{text || '—'}</span>,
    },
  ];

  return (
    <div>
      <div className="page-header">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 className="page-title">Lịch cơ quan</h2>
            <p className="page-description">Lịch làm việc chung của đơn vị</p>
          </div>
          <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
            <Segmented
              options={VIEW_OPTIONS}
              value={viewMode}
              onChange={(v) => setViewMode(v as 'calendar' | 'list')}
            />
            {isAdminOrSecretary && (
              <Button type="primary" icon={<PlusOutlined />} onClick={openCreateDrawer}>
                Thêm sự kiện
              </Button>
            )}
          </div>
        </div>
      </div>

      <div className="page-card" style={{ background: '#fff', borderRadius: 12, padding: 24, boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
        {loading ? (
          <Skeleton active paragraph={{ rows: 10 }} />
        ) : viewMode === 'calendar' ? (
          <Calendar
            value={currentDate}
            cellRender={cellRender}
            onPanelChange={(date) => setCurrentDate(date)}
            onSelect={(date, { source }) => {
              if (source === 'date' && isAdminOrSecretary) {
                setEditingEvent(null);
                form.resetFields();
                form.setFieldsValue({
                  start_time: date.hour(8).minute(0),
                  end_time: date.hour(9).minute(0),
                  all_day: false,
                  color: '#0891B2',
                  repeat_type: 'none',
                });
                setDrawerOpen(true);
              }
            }}
          />
        ) : (
          <Table
            columns={listColumns}
            dataSource={weekEvents}
            rowKey="id"
            loading={loading}
            locale={{ emptyText: 'Không có sự kiện trong tuần này' }}
            pagination={false}
            onRow={(record) => ({
              onClick: () => isAdminOrSecretary && openEditDrawer(record),
              style: { cursor: isAdminOrSecretary ? 'pointer' : 'default' },
            })}
          />
        )}
      </div>

      {/* Drawer */}
      <Drawer
        title={editingEvent ? 'Chỉnh sửa sự kiện' : 'Thêm sự kiện mới'}
        width={720}
        open={drawerOpen}
        rootClassName="drawer-gradient"
        onClose={() => {
          setDrawerOpen(false);
          setEditingEvent(null);
          form.resetFields();
        }}
        extra={
          <div style={{ display: 'flex', gap: 8 }}>
            {editingEvent && isAdminOrSecretary && (
              <Button danger icon={<DeleteOutlined />} onClick={handleDelete}>
                Xóa
              </Button>
            )}
            <Button onClick={() => { setDrawerOpen(false); setEditingEvent(null); form.resetFields(); }}>
              Hủy
            </Button>
            {isAdminOrSecretary && (
              <Button type="primary" loading={drawerLoading} onClick={handleSave}>
                Lưu
              </Button>
            )}
          </div>
        }
      >
        <Form form={form} layout="vertical" validateTrigger="onSubmit">
          <Form.Item
            name="title"
            label="Tiêu đề"
            rules={[{ required: true, message: 'Vui lòng nhập tiêu đề sự kiện' }]}
          >
            <Input placeholder="Nhập tiêu đề sự kiện" />
          </Form.Item>

          <Form.Item name="description" label="Mô tả">
            <Input.TextArea rows={3} placeholder="Nhập mô tả (tùy chọn)" />
          </Form.Item>

          <Form.Item name="start_time" label="Thời gian bắt đầu">
            <DatePicker showTime format="DD/MM/YYYY HH:mm" style={{ width: '100%' }} placeholder="Chọn thời gian bắt đầu" />
          </Form.Item>

          <Form.Item name="end_time" label="Thời gian kết thúc">
            <DatePicker showTime format="DD/MM/YYYY HH:mm" style={{ width: '100%' }} placeholder="Chọn thời gian kết thúc" />
          </Form.Item>

          <Form.Item name="all_day" label="Cả ngày" valuePropName="checked">
            <Switch />
          </Form.Item>

          <Form.Item name="color" label="Màu sắc">
            <ColorPicker />
          </Form.Item>

          <Form.Item name="repeat_type" label="Lặp lại">
            <Select options={REPEAT_OPTIONS} placeholder="Chọn kiểu lặp lại" />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
