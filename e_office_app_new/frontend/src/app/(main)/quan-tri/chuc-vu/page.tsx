'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Drawer, Form, Switch, InputNumber,
  Popconfirm, Tag, Tooltip, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined, IdcardOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';

interface Position {
  id: number;
  code: string;
  name: string;
  sort_order: number;
  description: string;
  is_active: boolean;
  staff_count: number;
}

export default function PositionPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<Position[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [keyword, setKeyword] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<Position | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/chuc-vu', {
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
    form.setFieldsValue({ is_active: true, sort_order: 0 });
    setDrawerOpen(true);
  };

  const handleEdit = (record: Position) => {
    setEditingRecord(record);
    form.setFieldsValue(record);
    setDrawerOpen(true);
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/quan-tri/chuc-vu/${id}`);
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
        await api.put(`/quan-tri/chuc-vu/${editingRecord.id}`, values);
        message.success('Cap nhat thanh cong');
      } else {
        await api.post('/quan-tri/chuc-vu', values);
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

  const handleSearch = (value: string) => {
    setKeyword(value);
    setPage(1);
  };

  const columns: ColumnsType<Position> = [
    {
      title: 'Ma',
      dataIndex: 'code',
      key: 'code',
      width: 120,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Ten chuc vu',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
    },
    {
      title: 'Thu tu',
      dataIndex: 'sort_order',
      key: 'sort_order',
      width: 90,
      align: 'center',
    },
    {
      title: 'So NV',
      dataIndex: 'staff_count',
      key: 'staff_count',
      width: 80,
      align: 'center',
    },
    {
      title: 'Trang thai',
      dataIndex: 'is_active',
      key: 'is_active',
      width: 120,
      render: (v) => (
        <Tag color={v ? 'success' : 'error'}>{v ? 'Hoat dong' : 'Ngung'}</Tag>
      ),
    },
    {
      title: 'Thao tac',
      key: 'actions',
      width: 100,
      align: 'center',
      render: (_, record) => (
        <Space size={4}>
          <Tooltip title="Sua">
            <Button
              type="text"
              size="small"
              icon={<EditOutlined />}
              onClick={() => handleEdit(record)}
              style={{ color: '#0891B2' }}
            />
          </Tooltip>
          <Popconfirm
            title="Xac nhan xoa"
            description="Ban co chac chan muon xoa chuc vu nay?"
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
          Quan ly chuc vu
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Danh muc chuc vu trong he thong
        </p>
      </div>

      <Card
        bordered={false}
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <IdcardOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sach chuc vu</span>
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
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={handleAdd}
              style={{ borderRadius: 8 }}
            >
              Them chuc vu
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
          scroll={{ x: 600 }}
          pagination={{
            current: page,
            pageSize,
            total,
            showSizeChanger: true,
            showTotal: (t) => `Tong ${t}`,
            onChange: (p, ps) => {
              setPage(p);
              setPageSize(ps);
            },
          }}
        />
      </Card>

      {/* Drawer add/edit */}
      <Drawer
        title={editingRecord ? 'Cap nhat chuc vu' : 'Them chuc vu moi'}
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
          <Form.Item label="Ten chuc vu" name="name" rules={[{ required: true, message: 'Nhap ten chuc vu' }]}>
            <Input placeholder="VD: Giam doc" style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Ma" name="code" rules={[{ required: true, message: 'Nhap ma' }]}>
            <Input placeholder="VD: GD" style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Thu tu" name="sort_order" initialValue={0}>
            <InputNumber min={0} style={{ width: '100%', borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Mo ta" name="description">
            <Input.TextArea rows={3} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Trang thai" name="is_active" valuePropName="checked" initialValue={true}>
            <Switch checkedChildren="Hoat dong" unCheckedChildren="Ngung" />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
