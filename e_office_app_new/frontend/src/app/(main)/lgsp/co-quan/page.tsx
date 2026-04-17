'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Table, Button, Input, Tag, Space, App } from 'antd';
import type { ColumnsType, TablePaginationConfig } from 'antd/es/table';
import { SyncOutlined, SearchOutlined, ReloadOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

// ─────────────────── interfaces (match LgspOrgRow) ───────────────────

interface LgspOrgRow {
  id: number;
  org_code: string;
  org_name: string;
  parent_code: string | null;
  address: string | null;
  email: string | null;
  phone: string | null;
  is_active: boolean;
  synced_at: string;
  total_count: number;
}

// ─────────────────── component ───────────────────

export default function LgspOrganizationsPage() {
  const { message } = App.useApp();

  const [data, setData] = useState<LgspOrgRow[]>([]);
  const [loading, setLoading] = useState(false);
  const [syncing, setSyncing] = useState(false);
  const [search, setSearch] = useState('');
  const [pagination, setPagination] = useState({ current: 1, pageSize: 20, total: 0 });

  const fetchData = useCallback(async (page = 1, pageSize = 20) => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/lgsp/organizations', {
        params: {
          search: search || undefined,
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
      message.error('Không thể tải danh sách cơ quan');
    } finally {
      setLoading(false);
    }
  }, [search, message]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleSync = async () => {
    setSyncing(true);
    try {
      const { data: res } = await api.post('/lgsp/organizations/sync');
      message.success(res.message || `Đã đồng bộ ${res.data?.synced || 0} cơ quan`);
      fetchData();
    } catch {
      message.error('Không thể đồng bộ cơ quan');
    } finally {
      setSyncing(false);
    }
  };

  const handleTableChange = (pag: TablePaginationConfig) => {
    fetchData(pag.current || 1, pag.pageSize || 20);
  };

  const columns: ColumnsType<LgspOrgRow> = [
    {
      title: 'Mã cơ quan',
      dataIndex: 'org_code',
      width: 140,
    },
    {
      title: 'Tên cơ quan',
      dataIndex: 'org_name',
      ellipsis: true,
    },
    {
      title: 'Địa chỉ',
      dataIndex: 'address',
      ellipsis: true,
      render: (val: string | null) => val || '—',
    },
    {
      title: 'Email',
      dataIndex: 'email',
      width: 200,
      render: (val: string | null) => val || '—',
    },
    {
      title: 'Điện thoại',
      dataIndex: 'phone',
      width: 130,
      render: (val: string | null) => val || '—',
    },
    {
      title: 'Trạng thái',
      dataIndex: 'is_active',
      width: 120,
      render: (val: boolean) =>
        val ? (
          <Tag color="green">Hoạt động</Tag>
        ) : (
          <Tag color="red">Ngừng</Tag>
        ),
    },
    {
      title: 'Lần đồng bộ cuối',
      dataIndex: 'synced_at',
      width: 160,
      render: (val: string) => val ? dayjs(val).format('DD/MM/YYYY HH:mm') : '—',
    },
  ];

  return (
    <>
      <div className="page-header">
        <h2 className="page-title">Cơ quan liên thông</h2>
        <Button
          type="primary"
          icon={<SyncOutlined spin={syncing} />}
          loading={syncing}
          onClick={handleSync}
        >
          Đồng bộ
        </Button>
      </div>

      <Card className="page-card">
        <div className="list-filter-bar">
          <div className="filter-row">
            <Space wrap>
              <Input
                placeholder="Tìm kiếm cơ quan..."
                prefix={<SearchOutlined />}
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                onPressEnter={() => fetchData()}
                style={{ width: 280 }}
                allowClear
              />
              <ReloadOutlined
                style={{ cursor: 'pointer', fontSize: 16 }}
                onClick={() => fetchData(pagination.current, pagination.pageSize)}
              />
            </Space>
          </div>
        </div>

        <Table<LgspOrgRow>
          className="enhanced-table"
          rowKey="id"
          columns={columns}
          dataSource={data}
          loading={loading}
          pagination={{
            current: pagination.current,
            pageSize: pagination.pageSize,
            total: pagination.total,
            showSizeChanger: true,
            showTotal: (total) => `Tổng ${total} cơ quan`,
          }}
          onChange={handleTableChange}
          scroll={{ x: 1000 }}
          size="small"
        />
      </Card>
    </>
  );
}
