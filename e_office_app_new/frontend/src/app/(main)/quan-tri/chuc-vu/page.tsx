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
  is_leader: boolean;
  is_handle_document: boolean;
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
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu');
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
    form.setFieldsValue({ is_active: true, sort_order: 0, is_leader: false, is_handle_document: true });
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
      message.success('Xóa thành công');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      if (editingRecord) {
        await api.put(`/quan-tri/chuc-vu/${editingRecord.id}`, values);
        message.success('Cập nhật thành công');
      } else {
        await api.post('/quan-tri/chuc-vu', values);
        message.success('Thêm thành công');
      }
      setDrawerOpen(false);
      fetchData();
    } catch (err: any) {
      if (err?.response) {
        message.error(err?.response?.data?.message || 'Lỗi khi lưu');
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
      title: 'Mã',
      dataIndex: 'code',
      key: 'code',
      width: 120,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Tên chức vụ',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
    },
    {
      title: 'Thứ tự',
      dataIndex: 'sort_order',
      key: 'sort_order',
      width: 90,
      align: 'center',
    },
    {
      title: 'Số NV',
      dataIndex: 'staff_count',
      key: 'staff_count',
      width: 80,
      align: 'center',
    },
    {
      title: 'Lãnh đạo',
      dataIndex: 'is_leader',
      key: 'is_leader',
      width: 100,
      align: 'center',
      render: (v) => (
        <Tag color={v ? 'success' : 'default'}>{v ? 'Có' : 'Không'}</Tag>
      ),
    },
    {
      title: 'XL Văn bản',
      dataIndex: 'is_handle_document',
      key: 'is_handle_document',
      width: 110,
      align: 'center',
      render: (v) => (
        <Tag color={v ? 'success' : 'default'}>{v ? 'Có' : 'Không'}</Tag>
      ),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'is_active',
      key: 'is_active',
      width: 120,
      render: (v) => (
        <Tag color={v ? 'success' : 'error'}>{v ? 'Hoạt động' : 'Ngừng'}</Tag>
      ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 100,
      align: 'center',
      render: (_, record) => (
        <Space size={4}>
          <Tooltip title="Sửa">
            <Button
              type="text"
              size="small"
              icon={<EditOutlined />}
              onClick={() => handleEdit(record)}
              style={{ color: '#0891B2' }}
            />
          </Tooltip>
          <Popconfirm
            title="Xác nhận xóa"
            description="Bạn có chắc chắn muốn xóa chức vụ này?"
            onConfirm={() => handleDelete(record.id)}
            okText="Xóa"
            cancelText="Hủy"
            okButtonProps={{ danger: true }}
          >
            <Tooltip title="Xóa">
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
          Quản lý chức vụ
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Danh mục chức vụ trong hệ thống
        </p>
      </div>

      <Card
        bordered={false}
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <IdcardOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách chức vụ</span>
          </div>
        }
        extra={
          <Space>
            <Input.Search
              placeholder="Tìm kiếm..."
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
              Thêm chức vụ
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
            showTotal: (t) => `Tổng ${t}`,
            onChange: (p, ps) => {
              setPage(p);
              setPageSize(ps);
            },
          }}
        />
      </Card>

      {/* Drawer add/edit */}
      <Drawer
        title={editingRecord ? 'Cập nhật chức vụ' : 'Thêm chức vụ mới'}
        width={720}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        destroyOnClose
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)}>Hủy</Button>
            <Button type="primary" loading={saving} onClick={handleSave} style={{ borderRadius: 8 }}>
              {editingRecord ? 'Cập nhật' : 'Thêm mới'}
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off">
          <Form.Item label="Tên chức vụ" name="name" rules={[{ required: true, message: 'Nhập tên chức vụ' }]}>
            <Input placeholder="VD: Giám đốc" style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Mã" name="code" rules={[{ required: true, message: 'Nhập mã' }]}>
            <Input placeholder="VD: GD" style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Thứ tự" name="sort_order" initialValue={0}>
            <InputNumber min={0} style={{ width: '100%', borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Mô tả" name="description">
            <Input.TextArea rows={3} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Chức vụ lãnh đạo" name="is_leader" valuePropName="checked" initialValue={false}>
            <Switch checkedChildren="Có" unCheckedChildren="Không" />
          </Form.Item>

          <Form.Item label="Được xử lý văn bản" name="is_handle_document" valuePropName="checked" initialValue={true}>
            <Switch checkedChildren="Có" unCheckedChildren="Không" />
          </Form.Item>

          <Form.Item label="Trạng thái" name="is_active" valuePropName="checked" initialValue={true}>
            <Switch checkedChildren="Hoạt động" unCheckedChildren="Ngừng" />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
