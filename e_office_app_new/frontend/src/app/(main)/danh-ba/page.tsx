'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Table,
  Input,
  TreeSelect,
  Avatar,
  Skeleton,
  App,
  Tag,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { UserOutlined, PhoneOutlined, MailOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import { buildTree, flattenTreeForSelect } from '@/lib/tree-utils';
import type { TreeNode } from '@/types/tree';

interface DirectoryRow {
  id: number;
  full_name: string;
  position_name: string;
  department_name: string;
  unit_name: string;
  phone: string;
  mobile: string;
  email: string;
  image: string;
  department_id: number;
  unit_id: number;
}

interface DeptTreeItem {
  id: number;
  name: string;
  parent_id: number | null;
  children?: DeptTreeItem[];
}

export default function DanhBaPage() {
  const { message: msg } = App.useApp();
  const user = useAuthStore((s) => s.user);

  const [data, setData] = useState<DirectoryRow[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [search, setSearch] = useState('');
  const [searchInput, setSearchInput] = useState('');
  const [departmentId, setDepartmentId] = useState<number | undefined>(undefined);

  const [deptTreeData, setDeptTreeData] = useState<{ value: number; title: string; children?: any[] }[]>([]);
  const [deptLoading, setDeptLoading] = useState(false);

  // Fetch department tree for filter
  useEffect(() => {
    const fetchDepts = async () => {
      setDeptLoading(true);
      try {
        const { data: res } = await api.get('/quan-tri/don-vi/tree');
        const items: DeptTreeItem[] = res.data || [];
        const tree = buildTree(items) as unknown as TreeNode[];
        setDeptTreeData(flattenTreeForSelect(tree));
      } catch {
        // Silent
      } finally {
        setDeptLoading(false);
      }
    };
    fetchDepts();
  }, []);

  const fetchDirectory = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, any> = {
        page,
        page_size: pageSize,
        unit_id: user?.unitId,
      };
      if (search) params.search = search;
      if (departmentId) params.department_id = departmentId;

      const { data: res } = await api.get('/danh-ba', { params });
      const resData = res.data;
      if (Array.isArray(resData)) {
        setData(resData);
        setTotal(resData.length);
      } else {
        setData(resData?.data || resData?.list || []);
        setTotal(resData?.total || 0);
      }
    } catch {
      setData([]);
      setTotal(0);
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, search, departmentId, user?.unitId]);

  useEffect(() => {
    fetchDirectory();
  }, [fetchDirectory]);

  const handleSearch = (value: string) => {
    setSearch(value);
    setPage(1);
  };

  const handleDeptChange = (value: number | undefined) => {
    setDepartmentId(value);
    setPage(1);
  };

  const columns: ColumnsType<DirectoryRow> = [
    {
      title: 'Họ tên',
      key: 'full_name',
      width: 220,
      render: (_, record) => (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <Avatar
            size={36}
            src={record.image || undefined}
            icon={!record.image ? <UserOutlined /> : undefined}
            style={{ background: '#1B3A5C', flexShrink: 0 }}
          />
          <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{record.full_name}</span>
        </div>
      ),
    },
    {
      title: 'Chức vụ',
      dataIndex: 'position_name',
      key: 'position_name',
      width: 160,
      render: (text) => (
        <Tag color="blue" style={{ borderRadius: 4 }}>
          {text || '—'}
        </Tag>
      ),
    },
    {
      title: 'Phòng ban',
      dataIndex: 'department_name',
      key: 'department_name',
      width: 180,
      render: (text) => <span style={{ color: '#334155' }}>{text || '—'}</span>,
    },
    {
      title: 'Điện thoại',
      key: 'phone',
      width: 140,
      render: (_, record) => {
        const phoneNum = record.mobile || record.phone;
        return phoneNum ? (
          <a href={`tel:${phoneNum}`} style={{ color: '#0891B2', display: 'flex', alignItems: 'center', gap: 4 }}>
            <PhoneOutlined style={{ fontSize: 12 }} />
            {phoneNum}
          </a>
        ) : (
          <span style={{ color: '#94A3B8' }}>—</span>
        );
      },
    },
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
      render: (text) =>
        text ? (
          <a href={`mailto:${text}`} style={{ color: '#0891B2', display: 'flex', alignItems: 'center', gap: 4 }}>
            <MailOutlined style={{ fontSize: 12 }} />
            {text}
          </a>
        ) : (
          <span style={{ color: '#94A3B8' }}>—</span>
        ),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <h2 className="page-title">Danh bạ điện thoại</h2>
        <p className="page-description">Tra cứu thông tin liên hệ cán bộ, nhân viên</p>
      </div>

      <div className="page-card" style={{ background: '#fff', borderRadius: 12, padding: 24, boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}>
        {/* Filter row */}
        <div className="filter-row" style={{ marginBottom: 20 }}>
          <TreeSelect
            showSearch
            allowClear
            placeholder="Lọc theo đơn vị / phòng ban"
            treeData={deptTreeData}
            loading={deptLoading}
            value={departmentId}
            onChange={handleDeptChange}
            treeNodeFilterProp="title"
            style={{ width: 280 }}
          />
          <Input.Search
            placeholder="Tìm kiếm theo tên cán bộ..."
            allowClear
            value={searchInput}
            onChange={(e) => setSearchInput(e.target.value)}
            onSearch={handleSearch}
            style={{ width: 280 }}
          />
        </div>

        {/* Table */}
        {loading && !data.length ? (
          <Skeleton active paragraph={{ rows: 8 }} />
        ) : (
          <Table
            columns={columns}
            dataSource={data}
            rowKey="id"
            loading={loading}
            locale={{ emptyText: 'Không tìm thấy cán bộ nào' }}
            pagination={{
              current: page,
              pageSize,
              total,
              showTotal: (t) => `Tổng ${t} cán bộ`,
              onChange: (p) => setPage(p),
              showSizeChanger: false,
            }}
          />
        )}
      </div>
    </div>
  );
}
