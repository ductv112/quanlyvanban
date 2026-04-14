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

  const dateCellRender = (current: Dayjs) => {
    const dateStr = current.format('YYYY-MM-DD');
    const holiday = holidayMap[dateStr];

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
        <div style={{ minHeight: 40, cursor: 'pointer' }}>
          {holiday && (
            <Tag color="red" style={{ fontSize: 10, lineHeight: '16px', padding: '0 3px', marginTop: 2 }}>
              {holiday.description.length > 15 ? holiday.description.slice(0, 15) + '...' : holiday.description}
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
      <div className="page-header">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h2 className="page-title">Lịch làm việc</h2>
            <p className="page-description">Quản lý ngày nghỉ lễ, ngày nghỉ trong năm</p>
          </div>
          <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
            <Select
              value={year}
              onChange={setYear}
              options={yearOptions}
              style={{ width: 140 }}
            />
          </div>
        </div>
      </div>

      <div className="page-card" style={{ background: '#fff', borderRadius: 12, padding: 24, boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
        <Calendar
          cellRender={dateCellRender}
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
      </div>
    </div>
  );
}
