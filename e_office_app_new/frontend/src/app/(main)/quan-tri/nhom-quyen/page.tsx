'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Drawer, Form, Tree, Popconfirm,
  Tag, Tooltip, Spin, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined,
  SafetyCertificateOutlined, KeyOutlined, SaveOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

interface Role {
  id: number;
  name: string;
  description: string;
  staff_count: number;
  created_at: string;
}

interface RightTreeNode {
  key: number;
  title: string;
  children?: RightTreeNode[];
}

export default function RolePage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<Role[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [keyword, setKeyword] = useState('');

  // Drawer add/edit
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<Role | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  // Drawer permissions
  const [permDrawerOpen, setPermDrawerOpen] = useState(false);
  const [permRole, setPermRole] = useState<Role | null>(null);
  const [rightTree, setRightTree] = useState<RightTreeNode[]>([]);
  const [checkedKeys, setCheckedKeys] = useState<number[]>([]);
  const [permLoading, setPermLoading] = useState(false);
  const [permSaving, setPermSaving] = useState(false);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/nhom-quyen', {
        params: { keyword, page, pageSize },
      });
      setData(res.data?.items || res.data || []);
      setTotal(res.data?.total || 0);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Loi tai du lieu');
    } finally {
      setLoading(false);
    }
  }, [keyword, page, pageSize, message]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleAdd = () => {
    setEditingRecord(null);
    form.resetFields();
    setDrawerOpen(true);
  };

  const handleEdit = (record: Role) => {
    setEditingRecord(record);
    form.setFieldsValue(record);
    setDrawerOpen(true);
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/quan-tri/nhom-quyen/${id}`);
      message.success('Xoa thanh cong');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Loi khi xoa');
    }
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      if (editingRecord) {
        await api.put(`/quan-tri/nhom-quyen/${editingRecord.id}`, values);
        message.success('Cap nhat thanh cong');
      } else {
        await api.post('/quan-tri/nhom-quyen', values);
        message.success('Them thanh cong');
      }
      setDrawerOpen(false);
      fetchData();
    } catch (err: any) {
      if (err?.response) {
        message.error(err?.response?.data?.message || 'Loi khi luu');
      }
    } finally {
      setSaving(false);
    }
  };

  // Permissions
  const handleOpenPermissions = async (record: Role) => {
    setPermRole(record);
    setPermDrawerOpen(true);
    setPermLoading(true);
    try {
      const [treeRes, rolePermsRes] = await Promise.all([
        api.get('/quan-tri/chuc-nang/tree'),
        api.get(`/quan-tri/nhom-quyen/${record.id}/quyen`),
      ]);
      setRightTree(treeRes.data?.data || []);
      const ids = (rolePermsRes.data?.data || []).map((r: any) => r.right_id || r.id);
      setCheckedKeys(ids);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Loi tai quyen');
    } finally {
      setPermLoading(false);
    }
  };

  const handleSavePermissions = async () => {
    if (!permRole) return;
    setPermSaving(true);
    try {
      await api.put(`/quan-tri/nhom-quyen/${permRole.id}/quyen`, { rightIds: checkedKeys });
      message.success('Luu phan quyen thanh cong');
      setPermDrawerOpen(false);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Loi luu phan quyen');
    } finally {
      setPermSaving(false);
    }
  };

  const handleSearch = (value: string) => {
    setKeyword(value);
    setPage(1);
  };

  const columns: ColumnsType<Role> = [
    {
      title: 'Ten nhom',
      dataIndex: 'name',
      key: 'name',
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Mo ta',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
    },
    {
      title: 'So nguoi dung',
      dataIndex: 'staff_count',
      key: 'staff_count',
      width: 130,
      align: 'center',
      render: (v) => <Tag color="blue">{v || 0}</Tag>,
    },
    {
      title: 'Ngay tao',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 140,
      render: (v) => v ? dayjs(v).format('DD/MM/YYYY') : '-',
    },
    {
      title: 'Thao tac',
      key: 'actions',
      width: 140,
      align: 'center',
      render: (_, record) => (
        <Space size={4}>
          <Tooltip title="Sua">
            <Button type="text" size="small" icon={<EditOutlined />} onClick={() => handleEdit(record)} style={{ color: '#0891B2' }} />
          </Tooltip>
          <Tooltip title="Phan quyen">
            <Button type="text" size="small" icon={<KeyOutlined />} onClick={() => handleOpenPermissions(record)} style={{ color: '#1B3A5C' }} />
          </Tooltip>
          <Popconfirm
            title="Xac nhan xoa"
            description="Ban co chac chan muon xoa nhom quyen nay?"
            onConfirm={() => handleDelete(record.id)}
            okText="Xoa"
            cancelText="Huy"
            okButtonProps={{ danger: true }}
          >
            <Tooltip title="Xoa">
              <Button type="text" size="small" icon={<DeleteOutlined />} danger />
            </Tooltip>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Quan ly nhom quyen
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Quan ly nhom quyen va phan quyen cho nguoi dung
        </p>
      </div>

      <Card
        bordered={false}
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <SafetyCertificateOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sach nhom quyen</span>
          </div>
        }
        extra={
          <Space>
            <Input.Search
              placeholder="Tim kiem..."
              allowClear
              onSearch={handleSearch}
              style={{ width: 240, borderRadius: 8 }}
              prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
            />
            <Button type="primary" icon={<PlusOutlined />} onClick={handleAdd} style={{ borderRadius: 8 }}>
              Them nhom quyen
            </Button>
          </Space>
        }
      >
        <Table
          columns={columns}
          dataSource={data}
          rowKey="id"
          loading={loading}
          size="middle"
          sticky
          scroll={{ x: 700 }}
          pagination={{
            current: page,
            pageSize,
            total,
            showSizeChanger: true,
            showTotal: (t) => `Tong ${t}`,
            onChange: (p, ps) => { setPage(p); setPageSize(ps); },
          }}
        />
      </Card>

      {/* Drawer add/edit */}
      <Drawer
        title={editingRecord ? 'Cap nhat nhom quyen' : 'Them nhom quyen moi'}
        width={720}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        destroyOnClose
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)}>Huy</Button>
            <Button type="primary" loading={saving} onClick={handleSave} style={{ borderRadius: 8 }}>
              {editingRecord ? 'Cap nhat' : 'Them moi'}
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off">
          <Form.Item label="Ten nhom quyen" name="name" rules={[{ required: true, message: 'Nhap ten nhom quyen' }]}>
            <Input placeholder="VD: Quan tri he thong" style={{ borderRadius: 8 }} />
          </Form.Item>
          <Form.Item label="Mo ta" name="description">
            <Input.TextArea rows={4} placeholder="Mo ta vai tro cua nhom quyen" style={{ borderRadius: 8 }} />
          </Form.Item>
        </Form>
      </Drawer>

      {/* Drawer permissions */}
      <Drawer
        title={
          <div>
            <span>Phan quyen: </span>
            <span style={{ color: '#0891B2', fontWeight: 700 }}>{permRole?.name}</span>
          </div>
        }
        width={720}
        open={permDrawerOpen}
        onClose={() => setPermDrawerOpen(false)}
        destroyOnClose
        extra={
          <Button
            type="primary"
            icon={<SaveOutlined />}
            loading={permSaving}
            onClick={handleSavePermissions}
            style={{ borderRadius: 8 }}
          >
            Luu phan quyen
          </Button>
        }
      >
        {permLoading ? (
          <div style={{ textAlign: 'center', padding: 48 }}>
            <Spin size="large" />
          </div>
        ) : (
          <Tree
            checkable
            treeData={rightTree}
            checkedKeys={checkedKeys}
            onCheck={(keys: any) => setCheckedKeys(keys as number[])}
            defaultExpandAll
            blockNode
            style={{ background: 'transparent' }}
          />
        )}
      </Drawer>
    </div>
  );
}
