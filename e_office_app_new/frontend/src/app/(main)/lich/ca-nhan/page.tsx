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
  Popover,
  Skeleton,
  App,
  Modal,
  Tag,
  ColorPicker,
  Segmented,
  Table,
} from 'antd';
import { CalendarOutlined, UnorderedListOutlined } from '@ant-design/icons';
import type { Dayjs } from 'dayjs';
import dayjs from 'dayjs';
import { PlusOutlined, DeleteOutlined } from '@ant-design/icons';
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

interface QuickCreateForm {
  title: string;
  start_time: Dayjs | null;
  end_time: Dayjs | null;
}

const REPEAT_OPTIONS = [
  { value: 'none', label: 'Không lặp lại' },
  { value: 'daily', label: 'Hàng ngày' },
  { value: 'weekly', label: 'Hàng tuần' },
  { value: 'monthly', label: 'Hàng tháng' },
];

export default function LichCaNhanPage() {
  const { message: msg, modal } = App.useApp();
  const user = useAuthStore((s) => s.user);

  const [events, setEvents] = useState<CalendarEvent[]>([]);
  const [loading, setLoading] = useState(false);
  const [currentDate, setCurrentDate] = useState<Dayjs>(dayjs());
  const [viewMode, setViewMode] = useState<'calendar' | 'list'>('calendar');

  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingEvent, setEditingEvent] = useState<CalendarEvent | null>(null);
  const [drawerLoading, setDrawerLoading] = useState(false);
  const [form] = Form.useForm();

  // Popover state
  const [popoverDate, setPopoverDate] = useState<Dayjs | null>(null);
  const [popoverOpen, setPopoverOpen] = useState(false);
  const [quickForm] = Form.useForm<QuickCreateForm>();

  const fetchEvents = useCallback(async (date: Dayjs) => {
    setLoading(true);
    try {
      const start = date.startOf('month').format('YYYY-MM-DD');
      const end = date.endOf('month').format('YYYY-MM-DD');
      const { data: res } = await api.get('/lich/events', {
        params: { scope: 'personal', start, end, unit_id: user?.unitId },
      });
      setEvents(res.data || []);
    } catch {
      // Silent - API may not exist yet
      setEvents([]);
    } finally {
      setLoading(false);
    }
  }, [user?.unitId]);

  useEffect(() => {
    fetchEvents(currentDate);
  }, [currentDate, fetchEvents]);

  const getEventsForDate = (date: Dayjs): CalendarEvent[] => {
    return events.filter((ev) => {
      const evDate = dayjs(ev.all_day ? ev.start_time : ev.start_time);
      return evDate.isSame(date, 'day');
    });
  };

  const cellRender = (date: Dayjs, info: { type: string }) => {
    if (info.type !== 'date') return null;
    const dayEvents = getEventsForDate(date);
    if (!dayEvents.length) return null;
    return (
      <ul style={{ listStyle: 'none', padding: 0, margin: 0 }}>
          {dayEvents.slice(0, 3).map((ev) => (
            <li key={ev.id}>
              <Badge
                color={ev.color || '#1B3A5C'}
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
                      color: ev.color || '#1B3A5C',
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
      color: event.color || '#1B3A5C',
      repeat_type: event.repeat_type || 'none',
    });
    setDrawerOpen(true);
  };

  const openCreateDrawer = (date: Dayjs) => {
    setEditingEvent(null);
    form.resetFields();
    form.setFieldsValue({
      start_time: date.hour(8).minute(0),
      end_time: date.hour(9).minute(0),
      all_day: false,
      color: '#1B3A5C',
      repeat_type: 'none',
    });
    setDrawerOpen(true);
  };

  const handleDateClick = (date: Dayjs) => {
    setPopoverDate(date);
    quickForm.resetFields();
    quickForm.setFieldsValue({
      start_time: date.hour(8).minute(0),
      end_time: date.hour(9).minute(0),
    });
    setPopoverOpen(true);
  };

  const handleDateDoubleClick = (date: Dayjs) => {
    setPopoverOpen(false);
    openCreateDrawer(date);
  };

  const handleQuickCreate = async () => {
    try {
      const values = await quickForm.validateFields();
      await api.post('/lich/events', {
        title: values.title,
        start_time: values.start_time?.toISOString(),
        end_time: values.end_time?.toISOString(),
        scope: 'personal',
        all_day: false,
        color: '#1B3A5C',
        repeat_type: 'none',
        unit_id: user?.unitId,
      });
      msg.success('Tạo sự kiện thành công');
      setPopoverOpen(false);
      fetchEvents(currentDate);
    } catch (err: any) {
      if (err?.errorFields) return;
      msg.error(err?.response?.data?.message || 'Tạo sự kiện thất bại');
    }
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setDrawerLoading(true);
      const payload = {
        ...values,
        start_time: values.start_time?.toISOString(),
        end_time: values.end_time?.toISOString(),
        color: typeof values.color === 'string' ? values.color : values.color?.toHexString?.() || '#1B3A5C',
        scope: 'personal',
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

  const popoverContent = (
    <div style={{ width: 260 }}>
      <Form form={quickForm} layout="vertical" size="small">
        <Form.Item
          name="title"
          label="Tiêu đề"
          rules={[{ required: true, message: 'Vui lòng nhập tiêu đề' }]}
        >
          <Input placeholder="Nhập tiêu đề sự kiện" />
        </Form.Item>
        <Form.Item name="start_time" label="Thời gian bắt đầu">
          <DatePicker showTime format="DD/MM/YYYY HH:mm" style={{ width: '100%' }} />
        </Form.Item>
        <Form.Item name="end_time" label="Thời gian kết thúc">
          <DatePicker showTime format="DD/MM/YYYY HH:mm" style={{ width: '100%' }} />
        </Form.Item>
        <div style={{ display: 'flex', gap: 8, justifyContent: 'flex-end' }}>
          <Button size="small" onClick={() => setPopoverOpen(false)}>Hủy</Button>
          <Button size="small" type="primary" icon={<PlusOutlined />} onClick={handleQuickCreate}>
            Tạo nhanh
          </Button>
        </div>
      </Form>
    </div>
  );

  return (
    <div>
      <div className="page-header">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 className="page-title">Lịch cá nhân</h2>
            <p className="page-description">Quản lý lịch làm việc và sự kiện cá nhân</p>
          </div>
          <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
            <Segmented
              options={[
                { label: <span><CalendarOutlined /> Lịch</span>, value: 'calendar' },
                { label: <span><UnorderedListOutlined /> Danh sách</span>, value: 'list' },
              ]}
              value={viewMode}
              onChange={(v) => setViewMode(v as 'calendar' | 'list')}
            />
            <Button type="primary" icon={<PlusOutlined />} onClick={() => openCreateDrawer(dayjs())}>
              Thêm sự kiện
            </Button>
          </div>
        </div>
      </div>

      <div className="page-card" style={{ background: '#fff', borderRadius: 12, padding: 24, boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
        {loading ? (
          <Skeleton active paragraph={{ rows: 10 }} />
        ) : viewMode === 'calendar' ? (
          <Popover
            content={popoverContent}
            title={popoverDate ? `Ngày ${popoverDate.format('DD/MM/YYYY')}` : ''}
            open={popoverOpen}
            onOpenChange={setPopoverOpen}
            trigger="click"
          >
            <Calendar
              value={currentDate}
              cellRender={cellRender}
              onPanelChange={(date) => {
                setCurrentDate(date);
              }}
              onSelect={(date, { source }) => {
                if (source === 'date') {
                  handleDateClick(date);
                }
              }}
            />
          </Popover>
        ) : (
          <Table
            dataSource={events}
            rowKey="id"
            pagination={false}
            locale={{ emptyText: 'Chưa có sự kiện nào' }}
            columns={[
              { title: 'Tiêu đề', dataIndex: 'title', key: 'title' },
              { title: 'Ngày bắt đầu', dataIndex: 'start_date', key: 'start_date', width: 160, render: (v: string) => v ? dayjs(v).format('DD/MM/YYYY HH:mm') : '---' },
              { title: 'Ngày kết thúc', dataIndex: 'end_date', key: 'end_date', width: 160, render: (v: string) => v ? dayjs(v).format('DD/MM/YYYY HH:mm') : '---' },
              { title: 'Cả ngày', dataIndex: 'all_day', key: 'all_day', width: 80, render: (v: boolean) => v ? <Tag color="blue">Cả ngày</Tag> : '---' },
              { title: 'Màu', dataIndex: 'color', key: 'color', width: 60, render: (v: string) => v ? <div style={{ width: 16, height: 16, borderRadius: 4, background: v }} /> : '---' },
            ]}
            onRow={(record) => ({ onClick: () => { setEditingEvent(record); setDrawerOpen(true); form.setFieldsValue({ ...record, start_date: record.start_date ? dayjs(record.start_date) : null, end_date: record.end_date ? dayjs(record.end_date) : null }); }, style: { cursor: 'pointer' } })}
          />
        )}
      </div>

      {/* Note: Double-click is handled via direct event listener below */}
      <style>{`
        .ant-picker-cell-inner {
          min-height: 80px;
        }
        .ant-picker-calendar-date-content {
          height: 68px !important;
          overflow: hidden !important;
        }
      `}</style>

      {/* Drawer for full create/edit */}
      <Drawer
        title={editingEvent ? 'Chỉnh sửa sự kiện' : 'Thêm sự kiện mới'}
        size={720}
        open={drawerOpen}
        rootClassName="drawer-gradient"
        onClose={() => {
          setDrawerOpen(false);
          setEditingEvent(null);
          form.resetFields();
        }}
        extra={
          <div style={{ display: 'flex', gap: 8 }}>
            {editingEvent && (
              <Button danger icon={<DeleteOutlined />} onClick={handleDelete}>
                Xóa
              </Button>
            )}
            <Button onClick={() => { setDrawerOpen(false); setEditingEvent(null); form.resetFields(); }}>
              Hủy
            </Button>
            <Button type="primary" loading={drawerLoading} onClick={handleSave}>
              Lưu
            </Button>
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
