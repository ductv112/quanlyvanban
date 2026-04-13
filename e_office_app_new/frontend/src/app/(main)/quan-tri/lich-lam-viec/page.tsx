'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Calendar, Button, Input, Modal, App, Select, Tag, Space, Popover,
} from 'antd';
import {
  CalendarOutlined, PlusOutlined, DeleteOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs, { Dayjs } from 'dayjs';

interface Holiday {
  id: number;
  date: string;
  description: string;
}

export default function WorkCalendarPage() {
  const { message } = App.useApp();
  const [year, setYear] = useState<number>(dayjs().year());
  const [holidays, setHolidays] = useState<Holiday[]>([]);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);

  // Popover state
  const [activeDate, setActiveDate] = useState<string | null>(null);
  const [description, setDescription] = useState('');

  const fetchHolidays = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/lich-lam-viec', {
        params: { year },
      });
      setHolidays(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải lịch làm việc');
    } finally {
      setLoading(false);
    }
  }, [year, message]);

  useEffect(() => {
    fetchHolidays();
  }, [fetchHolidays]);

  const holidayMap = React.useMemo(() => {
    const map: Record<string, Holiday> = {};
    holidays.forEach((h) => {
      map[h.date] = h;
    });
    return map;
  }, [holidays]);

  const handleAddHoliday = async (dateStr: string) => {
    if (!description.trim()) {
      message.warning('Vui lòng nhập mô tả ngày nghỉ');
      return;
    }
    setSaving(true);
    try {
      await api.post('/quan-tri/lich-lam-viec', {
        date: dateStr,
        description: description.trim(),
      });
      message.success('Thêm thành công');
      setActiveDate(null);
      setDescription('');
      fetchHolidays();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi thêm ngày nghỉ');
    } finally {
      setSaving(false);
    }
  };

  const handleDeleteHoliday = async (holiday: Holiday) => {
    Modal.confirm({
      title: 'Xác nhận xóa',
      content: `Bạn có chắc chắn muốn xóa ngày nghỉ ${holiday.date}?`,
      okText: 'Xóa',
      cancelText: 'Hủy',
      okButtonProps: { danger: true },
      onOk: async () => {
        try {
          await api.delete(`/quan-tri/lich-lam-viec/${holiday.id}`);
          message.success('Xóa thành công');
          setActiveDate(null);
          fetchHolidays();
        } catch (err: any) {
          message.error(err?.response?.data?.message || 'Lỗi khi xóa');
        }
      },
    });
  };

  const cellRender = (current: Dayjs, info: { type: string }) => {
    if (info.type !== 'date') return null;
    const dateStr = current.format('YYYY-MM-DD');
    const holiday = holidayMap[dateStr];

    if (!holiday) return null;

    return (
      <div style={{ marginTop: 2 }}>
        <Tag color="red" style={{ fontSize: 11, lineHeight: '18px', padding: '0 4px' }}>
          Nghỉ
        </Tag>
      </div>
    );
  };

  const renderPopoverContent = (dateStr: string) => {
    const holiday = holidayMap[dateStr];

    if (holiday) {
      return (
        <div style={{ maxWidth: 260 }}>
          <p style={{ margin: '0 0 8px', fontWeight: 600, color: '#dc2626' }}>Ngày nghỉ</p>
          <p style={{ margin: '0 0 12px', color: '#475569' }}>{holiday.description}</p>
          <Button
            danger
            size="small"
            icon={<DeleteOutlined />}
            onClick={() => handleDeleteHoliday(holiday)}
            style={{ borderRadius: 8 }}
          >
            Xóa ngày nghỉ
          </Button>
        </div>
      );
    }

    return (
      <div style={{ maxWidth: 280 }}>
        <p style={{ margin: '0 0 8px', fontWeight: 600, color: '#1B3A5C' }}>Đánh dấu ngày nghỉ</p>
        <Input.TextArea
          rows={2}
          placeholder="Nhập mô tả ngày nghỉ..."
          maxLength={200}
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          style={{ borderRadius: 8, marginBottom: 8 }}
        />
        <Button
          type="primary"
          size="small"
          icon={<PlusOutlined />}
          loading={saving}
          onClick={() => handleAddHoliday(dateStr)}
          style={{ borderRadius: 8 }}
        >
          Đánh dấu ngày nghỉ
        </Button>
      </div>
    );
  };

  const dateFullCellRender = (current: Dayjs, info: { type: string }) => {
    if (info.type !== 'date') {
      return cellRender(current, info);
    }

    const dateStr = current.format('YYYY-MM-DD');
    const holiday = holidayMap[dateStr];
    const isCurrentMonth = current.month() === (activeDate ? dayjs(activeDate).month() : dayjs().month());

    return (
      <Popover
        content={renderPopoverContent(dateStr)}
        title={current.format('DD/MM/YYYY')}
        trigger="click"
        open={activeDate === dateStr}
        onOpenChange={(open) => {
          if (open) {
            setActiveDate(dateStr);
            setDescription('');
          } else {
            setActiveDate(null);
          }
        }}
      >
        <div
          style={{
            padding: '4px 8px',
            minHeight: 60,
            borderRadius: 6,
            cursor: 'pointer',
            background: holiday ? '#fef2f2' : undefined,
            border: holiday ? '1px solid #fecaca' : '1px solid transparent',
            opacity: isCurrentMonth ? 1 : 0.4,
          }}
        >
          <div style={{ fontWeight: 500, fontSize: 13, color: holiday ? '#dc2626' : '#334155' }}>
            {current.date()}
          </div>
          {holiday && (
            <Tag color="red" style={{ fontSize: 10, lineHeight: '16px', padding: '0 3px', marginTop: 2 }}>
              {holiday.description.length > 12 ? holiday.description.slice(0, 12) + '...' : holiday.description}
            </Tag>
          )}
        </div>
      </Popover>
    );
  };

  const yearOptions = Array.from({ length: 11 }, (_, i) => {
    const y = dayjs().year() - 5 + i;
    return { value: y, label: `Năm ${y}` };
  });

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Lịch làm việc
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Quản lý ngày nghỉ lễ, ngày nghỉ trong năm
        </p>
      </div>

      <Card
        variant="borderless"
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <CalendarOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Lịch năm {year}</span>
          </div>
        }
        extra={
          <Space>
            <Select
              value={year}
              onChange={setYear}
              options={yearOptions}
              style={{ width: 140 }}
            />
          </Space>
        }
        loading={loading}
      >
        <Calendar
          fullCellRender={dateFullCellRender}
          headerRender={({ value, onChange }) => {
            const months = Array.from({ length: 12 }, (_, i) => ({
              value: i,
              label: `Tháng ${i + 1}`,
            }));
            return (
              <div style={{ display: 'flex', justifyContent: 'flex-end', padding: '8px 0', gap: 8 }}>
                <Select
                  value={value.month()}
                  onChange={(m) => onChange(value.clone().month(m))}
                  options={months}
                  style={{ width: 130 }}
                />
              </div>
            );
          }}
        />
      </Card>
    </div>
  );
}
