'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Table, Select, Tag, Tooltip, Space, App } from 'antd';
import type { ColumnsType, TablePaginationConfig } from 'antd/es/table';
import { ReloadOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

// ─────────────────── interfaces (match LgspTrackingRow) ───────────────────

interface LgspTrackingRow {
  id: number;
  outgoing_doc_id: number | null;
  incoming_doc_id: number | null;
  direction: string;
  lgsp_doc_id: string | null;
  dest_org_code: string | null;
  dest_org_name: string | null;
  status: string;
  error_message: string | null;
  sent_at: string | null;
  received_at: string | null;
  created_at: string;
  total_count: number;
}

// ─────────────────── constants ───────────────────

const DIRECTION_OPTIONS = [
  { value: '', label: 'Tất cả hướng' },
  { value: 'send', label: 'Gửi đi' },
  { value: 'receive', label: 'Nhận về' },
];

const STATUS_OPTIONS = [
  { value: '', label: 'Tất cả trạng thái' },
  { value: 'pending', label: 'Chờ xử lý' },
  { value: 'processing', label: 'Đang xử lý' },
  { value: 'success', label: 'Thành công' },
  { value: 'error', label: 'Lỗi' },
];

const STATUS_COLOR: Record<string, string> = {
  pending: 'default',
  processing: 'blue',
  success: 'green',
  error: 'red',
};

const STATUS_LABEL: Record<string, string> = {
  pending: 'Chờ xử lý',
  processing: 'Đang xử lý',
  success: 'Thành công',
  error: 'Lỗi',
};

// ─────────────────── component ───────────────────

export default function LgspTrackingPage() {
  const { message } = App.useApp();

  const [data, setData] = useState<LgspTrackingRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [direction, setDirection] = useState('');
  const [status, setStatus] = useState('');
  const [pagination, setPagination] = useState({ current: 1, pageSize: 20, total: 0 });

  const fetchData = useCallback(async (page = 1, pageSize = 20) => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/lgsp/tracking', {
        params: {
          direction: direction || undefined,
          status: status || undefined,
          page,
          pageSize,
        },
      });
      setData(res.data || []);
      setPagination({
        current: res.pagination?.page || page,
        pageSize: res.pagination?.pageSize || pageSize,
        total: res.pagination?.total || 0,
      });
    } catch {
      message.error('Không thể tải danh sách liên thông');
    } finally {
      setLoading(false);
    }
  }, [direction, status, message]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleTableChange = (pag: TablePaginationConfig) => {
    fetchData(pag.current || 1, pag.pageSize || 20);
  };

  const columns: ColumnsType<LgspTrackingRow> = [
    {
      title: 'Hướng',
      dataIndex: 'direction',
      width: 110,
      render: (val: string) =>
        val === 'send' ? (
          <Tag color="blue">Gửi đi</Tag>
        ) : (
          <Tag color="green">Nhận về</Tag>
        ),
    },
    {
      title: 'Cơ quan',
      dataIndex: 'dest_org_name',
      ellipsis: true,
      render: (val: string | null, record) => val || record.dest_org_code || '—',
    },
    {
      title: 'Mã LGSP',
      dataIndex: 'lgsp_doc_id',
      width: 160,
      render: (val: string | null) => val || '—',
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      width: 130,
      render: (val: string, record) => (
        <Tooltip title={record.error_message || undefined}>
          <Tag color={STATUS_COLOR[val] || 'default'}>
            {STATUS_LABEL[val] || val}
          </Tag>
        </Tooltip>
      ),
    },
    {
      title: 'Thời gian',
      key: 'time',
      width: 160,
      render: (_: unknown, record) => {
        const t = record.direction === 'send' ? record.sent_at : record.received_at;
        return t ? dayjs(t).format('DD/MM/YYYY HH:mm') : '—';
      },
    },
    {
      title: 'Ngày tạo',
      dataIndex: 'created_at',
      width: 160,
      render: (val: string) => dayjs(val).format('DD/MM/YYYY HH:mm'),
    },
  ];

  return (
    <>
      <div className="page-header">
        <h2 className="page-title">Liên thông văn bản</h2>
      </div>

      <Card className="page-card">
        <div className="filter-row" style={{ marginBottom: 16 }}>
          <Space wrap>
            <Select
              style={{ width: 180 }}
              value={direction}
              onChange={setDirection}
              options={DIRECTION_OPTIONS}
              placeholder="Hướng liên thông"
            />
            <Select
              style={{ width: 180 }}
              value={status}
              onChange={setStatus}
              options={STATUS_OPTIONS}
              placeholder="Trạng thái"
            />
            <ReloadOutlined
              style={{ cursor: 'pointer', fontSize: 16 }}
              onClick={() => fetchData(pagination.current, pagination.pageSize)}
            />
          </Space>
        </div>

        <Table<LgspTrackingRow>
          rowKey="id"
          columns={columns}
          dataSource={data}
          loading={loading}
          pagination={{
            current: pagination.current,
            pageSize: pagination.pageSize,
            total: pagination.total,
            showSizeChanger: true,
            showTotal: (total) => `Tổng ${total} bản ghi`,
          }}
          onChange={handleTableChange}
          scroll={{ x: 900 }}
          size="small"
        />
      </Card>
    </>
  );
}
