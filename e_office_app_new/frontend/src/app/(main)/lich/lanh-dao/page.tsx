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
  Skeleton,
  App,
  Empty,
  Tag,
  ColorPicker,
} from 'antd';
import type { Dayjs } from 'dayjs';
import dayjs from 'dayjs';
import { PlusOutlined, DeleteOutlined, LockOutlined } from '@ant-design/icons';
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
}

const REPEAT_OPTIONS = [
  { value: 'none', label: 'Không lặp lại' },
  { value: 'daily', label: 'Hàng ngày' },
  { value: 'weekly', label: 'Hàng tuần' },
  { value: 'monthly', label: 'Hàng tháng' },
];

const LEADER_ROLES = ['admin', 'lanh_dao', 'leader', 'ADMIN', 'LEADER', 'giam_doc', 'pho_giam_doc'];

export default function LichLanhDaoPage() {
  const { message: msg } = App.useApp();
  const { modal } = App.useApp();
  const user = useAuthStore((s) => s.user);

  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(false);
  const [currentDate, setCurrentDate] = useState<Dayjs>(dayjs());

  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingEvent, setEditingEvent] = useState<CalendarEvent | null>(null);
  const [drawerLoading, setDrawerLoading] = useState(false);
  const [form] = Form.useForm();

  const hasPermission = user?.isAdmin || user?.roles?.some((r) => LEADER_ROLES.includes(r));

  const isEditable = user?.isAdmin || user?.roles?.some((r) =>
    ['admin', 'lanh_dao', 'ADMIN', 'LEADER', 'giam_doc'].includes(r)
  );

  const fetchEvents = useCallback(async (date: Dayjs) => {
    setLoading(true);
    try {
      const start = date.startOf('month').format('YYYY-MM-DD');
      const end = date.endOf('month').format('YYYY-MM-DD');
      const { data: res } = await api.get('/lich/events', {
        params: { scope: 'leader', start, end, unit_id: user?.unitId },
      });
      setEvents(res.data || []);
    } catch {
      setEvents([]);
    } finally {
      setLoading(false);
    }
  }, [user?.unitId]);

  useEffect(() => {
    if (hasPermission) {
      fetchEvents(currentDate);
    }
  }, [currentDate, fetchEvents, hasPermission]);

  if (!hasPermission) {
    return (
      <div>
        <div className="page-header">
          <h2 className="page-title">Lịch lãnh đạo</h2>
        </div>
        <div className="page-card" style={{ background: '#fff', borderRadius: 12, padding: 48, boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
          <Empty
            image={<LockOutlined style={{ fontSize: 64, color: '#D97706' }} />}
            description={
              <div>
                <p style={{ fontSize: 16, fontWeight: 600, color: '#1B3A5C', margin: '16px 0 8px' }}>
                  Không có quyền truy cập
                </p>
                <p style={{ color: '#64748b', margin: 0 }}>
                  Bạn không có quyền xem lịch lãnh đạo. Vui lòng liên hệ quản trị viên để được cấp quyền.
                </p>
              </div>
            }
          />
        </div>
      </div>
    );
  }

  const getEventsForDate = (date: Dayjs): CalendarEvent[] => {
    return events.filter((ev) => dayjs(ev.start_time).isSame(date, 'day'));
  };

  const cellRender = (date: Dayjs, info: { type: string; originNode: React.ReactElement }) => {
    if (info.type !== 'date') return info.originNode;
    const dayEvents = getEventsForDate(date);
    if (!dayEvents.length) return info.originNode;
    return (
      <div className="ant-picker-cell-inner">
        {date.date()}
        <ul style={{ listStyle: 'none', padding: 0, margin: '4px 0 0' }}>
          {dayEvents.slice(0, 3).map((ev) => (
            <li key={ev.id}>
              <Badge
                color={ev.color || '#D97706'}
                text={
                  <span
                    style={{
                      fontSize: 12,
                      fontWeight: 600,
                      overflow: 'hidden',
                      textOverflow: 'ellipsis',
                      whiteSpace: 'nowrap',
                      maxWidth: 110,
                      display: 'inline-block',
                      cursor: 'pointer',
                      color: ev.color || '#D97706',
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
      </div>
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
      color: event.color || '#D97706',
      repeat_type: event.repeat_type || 'none',
    });
    setDrawerOpen(true);
  };

  const openCreateDrawer = (date?: Dayjs) => {
    setEditingEvent(null);
    form.resetFields();
    form.setFieldsValue({
      start_time: (date || dayjs()).hour(8).minute(0),
      end_time: (date || dayjs()).hour(9).minute(0),
      all_day: false,
      color: '#D97706',
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
        color: typeof values.color === 'string' ? values.color : values.color?.toHexString?.() || '#D97706',
        scope: 'leader',
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

  return (
    <div>
      <div className="page-header">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 className="page-title">Lịch lãnh đạo</h2>
            <p className="page-description">Lịch công tác của ban lãnh đạo đơn vị</p>
          </div>
          {isEditable && (
            <Button type="primary" icon={<PlusOutlined />} onClick={() => openCreateDrawer()}>
              Thêm sự kiện
            </Button>
          )}
        </div>
      </div>

      <div className="page-card" style={{ background: '#fff', borderRadius: 12, padding: 24, boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
        {loading ? (
          <Skeleton active paragraph={{ rows: 10 }} />
        ) : (
          <Calendar
            value={currentDate}
            cellRender={cellRender}
            onPanelChange={(date) => setCurrentDate(date)}
            onSelect={(date, { source }) => {
              if (source === 'date' && isEditable) {
                openCreateDrawer(date);
              }
            }}
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
            {editingEvent && isEditable && (
              <Button danger icon={<DeleteOutlined />} onClick={handleDelete}>
                Xóa
              </Button>
            )}
            <Button onClick={() => { setDrawerOpen(false); setEditingEvent(null); form.resetFields(); }}>
              Hủy
            </Button>
            {isEditable && (
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
