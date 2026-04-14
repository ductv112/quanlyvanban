'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Table, Select, Tag, Tooltip, Switch, Space, App, Divider } from 'antd';
import type { ColumnsType, TablePaginationConfig } from 'antd/es/table';
import {
  BellOutlined,
  MessageOutlined,
  MobileOutlined,
  MailOutlined,
  ReloadOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

// ─────────────────── interfaces (match backend Row interfaces) ───────────────────

interface NotificationPrefRow {
  id: number;
  channel: string;
  is_enabled: boolean;
}

interface NotificationLogRow {
  id: number;
  staff_id: number;
  channel: string;
  event_type: string;
  title: string | null;
  body: string | null;
  ref_type: string | null;
  ref_id: number | null;
  send_status: string;
  error_message: string | null;
  sent_at: string | null;
  created_at: string;
  total_count: number;
}

// ─────────────────── constants ───────────────────

const CHANNELS = [
  { key: 'fcm', label: 'Push Notification (FCM)', desc: 'Thông báo đẩy qua trình duyệt và ứng dụng', icon: <BellOutlined style={{ fontSize: 20, color: '#1677ff' }} /> },
  { key: 'zalo', label: 'Zalo OA', desc: 'Thông báo qua Zalo Official Account', icon: <MessageOutlined style={{ fontSize: 20, color: '#0068ff' }} /> },
  { key: 'sms', label: 'SMS', desc: 'Tin nhắn SMS đến số điện thoại', icon: <MobileOutlined style={{ fontSize: 20, color: '#D97706' }} /> },
  { key: 'email', label: 'Email', desc: 'Thông báo qua email', icon: <MailOutlined style={{ fontSize: 20, color: '#059669' }} /> },
];

const CHANNEL_COLOR: Record<string, string> = {
  fcm: 'blue',
  zalo: 'cyan',
  sms: 'orange',
  email: 'green',
};

const CHANNEL_LABEL: Record<string, string> = {
  fcm: 'FCM',
  zalo: 'Zalo',
  sms: 'SMS',
  email: 'Email',
};

const EVENT_TYPE_LABEL: Record<string, string> = {
  new_doc: 'VB mới',
  task_assigned: 'Giao việc',
  deadline_warning: 'Sắp hết hạn',
  meeting_reminder: 'Nhắc họp',
  test: 'Thử nghiệm',
};

const STATUS_COLOR: Record<string, string> = {
  pending: 'default',
  sent: 'green',
  failed: 'red',
};

const STATUS_LABEL: Record<string, string> = {
  pending: 'Chờ gửi',
  sent: 'Đã gửi',
  failed: 'Thất bại',
};

const CHANNEL_FILTER = [
  { value: '', label: 'Tất cả kênh' },
  { value: 'fcm', label: 'FCM' },
  { value: 'zalo', label: 'Zalo' },
  { value: 'sms', label: 'SMS' },
  { value: 'email', label: 'Email' },
];

const SEND_STATUS_FILTER = [
  { value: '', label: 'Tất cả trạng thái' },
  { value: 'pending', label: 'Chờ gửi' },
  { value: 'sent', label: 'Đã gửi' },
  { value: 'failed', label: 'Thất bại' },
];

// ─────────────────── component ───────────────────

export default function NotificationChannelPage() {
  const { message } = App.useApp();

  // Preferences state
  const [prefs, setPrefs] = useState<Record<string, boolean>>({});
  const [prefLoading, setPrefLoading] = useState(false);
  const [togglingChannel, setTogglingChannel] = useState<string | null>(null);

  // Logs state
  const [logs, setLogs] = useState<NotificationLogRow[]>([]);
  const [logLoading, setLogLoading] = useState(false);
  const [channelFilter, setChannelFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [logPagination, setLogPagination] = useState({ current: 1, pageSize: 20, total: 0 });

  // ─── Load preferences ───
  const fetchPrefs = useCallback(async () => {
    setPrefLoading(true);
    try {
      const { data: res } = await api.get('/thong-bao-kenh/preferences');
      const prefMap: Record<string, boolean> = {};
      (res.data || []).forEach((p: NotificationPrefRow) => {
        prefMap[p.channel] = p.is_enabled;
      });
      setPrefs(prefMap);
    } catch {
      message.error('Không thể tải cấu hình thông báo');
    } finally {
      setPrefLoading(false);
    }
  }, [message]);

  // ─── Load logs ───
  const fetchLogs = useCallback(async (page = 1, pageSize = 20) => {
    setLogLoading(true);
    try {
      const { data: res } = await api.get('/thong-bao-kenh/logs', {
        params: {
          channel: channelFilter || undefined,
          send_status: statusFilter || undefined,
          page,
          pageSize,
        },
      });
      setLogs(res.data || []);
      setLogPagination({
        current: res.pagination?.page || page,
        pageSize: res.pagination?.pageSize || pageSize,
        total: res.pagination?.total || 0,
      });
    } catch {
      message.error('Không thể tải lịch sử thông báo');
    } finally {
      setLogLoading(false);
    }
  }, [channelFilter, statusFilter, message]);

  useEffect(() => {
    fetchPrefs();
  }, [fetchPrefs]);

  useEffect(() => {
    fetchLogs();
  }, [fetchLogs]);

  // ─── Toggle preference ───
  const handleToggle = async (channel: string, checked: boolean) => {
    setTogglingChannel(channel);
    try {
      await api.put('/thong-bao-kenh/preferences', {
        channel,
        is_enabled: checked,
      });
      setPrefs((prev) => ({ ...prev, [channel]: checked }));
      message.success(`Đã ${checked ? 'bật' : 'tắt'} kênh ${CHANNEL_LABEL[channel] || channel}`);
    } catch {
      message.error('Không thể cập nhật cấu hình');
    } finally {
      setTogglingChannel(null);
    }
  };

  const handleLogTableChange = (pag: TablePaginationConfig) => {
    fetchLogs(pag.current || 1, pag.pageSize || 20);
  };

  // ─── Log table columns ───
  const logColumns: ColumnsType<NotificationLogRow> = [
    {
      title: 'Kênh',
      dataIndex: 'channel',
      width: 90,
      render: (val: string) => (
        <Tag color={CHANNEL_COLOR[val] || 'default'}>
          {CHANNEL_LABEL[val] || val}
        </Tag>
      ),
    },
    {
      title: 'Loại sự kiện',
      dataIndex: 'event_type',
      width: 130,
      render: (val: string) => EVENT_TYPE_LABEL[val] || val,
    },
    {
      title: 'Tiêu đề',
      dataIndex: 'title',
      ellipsis: true,
      render: (val: string | null) => val || '—',
    },
    {
      title: 'Trạng thái',
      dataIndex: 'send_status',
      width: 110,
      render: (val: string, record) => (
        <Tooltip title={record.error_message || undefined}>
          <Tag color={STATUS_COLOR[val] || 'default'}>
            {STATUS_LABEL[val] || val}
          </Tag>
        </Tooltip>
      ),
    },
    {
      title: 'Thời gian gửi',
      dataIndex: 'sent_at',
      width: 160,
      render: (val: string | null) => val ? dayjs(val).format('DD/MM/YYYY HH:mm') : '—',
    },
  ];

  return (
    <>
      <div className="page-header">
        <h2 className="page-title">Cấu hình thông báo</h2>
      </div>

      {/* Channel preferences card */}
      <Card
        className="page-card"
        title="Kênh thông báo"
        loading={prefLoading}
        style={{ marginBottom: 16 }}
      >
        {CHANNELS.map((ch) => (
          <div
            key={ch.key}
            style={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              padding: '12px 0',
              borderBottom: '1px solid #f0f0f0',
            }}
          >
            <Space size={12}>
              {ch.icon}
              <div>
                <div style={{ fontWeight: 500 }}>{ch.label}</div>
                <div style={{ fontSize: 13, color: '#94A3B8' }}>{ch.desc}</div>
              </div>
            </Space>
            <Switch
              checked={prefs[ch.key] ?? true}
              onChange={(checked) => handleToggle(ch.key, checked)}
              loading={togglingChannel === ch.key}
            />
          </div>
        ))}
      </Card>

      {/* Notification logs card */}
      <Card className="page-card" title="Lịch sử gửi thông báo">
        <div className="filter-row" style={{ marginBottom: 16 }}>
          <Space wrap>
            <Select
              style={{ width: 160 }}
              value={channelFilter}
              onChange={setChannelFilter}
              options={CHANNEL_FILTER}
              placeholder="Kênh"
            />
            <Select
              style={{ width: 160 }}
              value={statusFilter}
              onChange={setStatusFilter}
              options={SEND_STATUS_FILTER}
              placeholder="Trạng thái"
            />
            <ReloadOutlined
              style={{ cursor: 'pointer', fontSize: 16 }}
              onClick={() => fetchLogs(logPagination.current, logPagination.pageSize)}
            />
          </Space>
        </div>

        <Table<NotificationLogRow>
          rowKey="id"
          columns={logColumns}
          dataSource={logs}
          loading={logLoading}
          pagination={{
            current: logPagination.current,
            pageSize: logPagination.pageSize,
            total: logPagination.total,
            showSizeChanger: true,
            showTotal: (total) => `Tổng ${total} bản ghi`,
          }}
          onChange={handleLogTableChange}
          scroll={{ x: 800 }}
          size="small"
        />
      </Card>
    </>
  );
}
