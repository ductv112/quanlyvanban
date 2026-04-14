'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Drawer, Form, Switch, InputNumber,
  Tag, Dropdown, Modal, Tabs, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, BookOutlined,
  MoreOutlined, StarOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';

interface DocBook {
  id: number;
  unit_id: number;
  type_id: number;
  name: string;
  description: string;
  sort_order: number;
  is_default: boolean;
  created_by: number;
  created_at: string;
}

const TAB_ITEMS = [
  { key: '1', label: 'Văn bản đến' },
  { key: '2', label: 'Văn bản đi' },
  { key: '3', label: 'Văn bản dự thảo' },
];

export default function DocBookPage() {
  const { message } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<DocBook[]>([]);
  const [activeTab, setActiveTab] = useState('1');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<DocBook | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  const fetchData = useCallback(async () => {
    if (!user?.unitId) return;
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/so-van-ban', {
        params: { type_id: activeTab, unit_id: user.unitId },
      });
      setData(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu');
    } finally {
      setLoading(false);
    }
  }, [activeTab, user?.unitId, message]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleAdd = () => {
    setEditingRecord(null);
    form.resetFields();
    form.setFieldsValue({ is_default: false, sort_order: 0 });
    setDrawerOpen(true);
  };

  const handleEdit = (record: DocBook) => {
    setEditingRecord(record);
    form.setFieldsValue(record);
    setDrawerOpen(true);
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/quan-tri/so-van-ban/${id}`);
      message.success('Xóa thành công');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const handleSetDefault = async (record: DocBook) => {
    try {
      await api.patch(`/quan-tri/so-van-ban/${record.id}/mac-dinh`, {
        type_id: Number(activeTab),
        unit_id: user?.unitId,
      });
      message.success('Đặt mặc định thành công');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi đặt mặc định');
    }
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Tên sổ văn bản là bắt buộc': 'name',
      'Tên sổ văn bản không được để trống': 'name',
      'Tên sổ văn bản không được vượt quá 200 ký tự': 'name',
      'Tên sổ văn bản đã tồn tại trong đơn vị': 'name',
      'Loại văn bản là bắt buộc': 'type_id',
    };
    const fieldName = fieldErrorMap[errorMessage];
    if (fieldName) {
      form.setFields([{ name: fieldName, errors: [errorMessage] }]);
      return true;
    }
    return false;
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      if (editingRecord) {
        await api.put(`/quan-tri/so-van-ban/${editingRecord.id}`, values);
        message.success('Cập nhật thành công');
      } else {
        await api.post('/quan-tri/so-van-ban', {
          ...values,
          type_id: Number(activeTab),
          unit_id: user?.unitId,
        });
        message.success('Thêm thành công');
      }
      setDrawerOpen(false);
      fetchData();
    } catch (err: any) {
      if (err?.response?.data?.message) {
        const mapped = setBackendFieldError(err.response.data.message);
        if (!mapped) {
          message.error(err.response.data.message);
        }
      }
    } finally {
      setSaving(false);
    }
  };

  const columns: ColumnsType<DocBook> = [
    {
      title: 'Tên sổ',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Mô tả',
      dataIndex: 'description',
      key: 'description',
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
      title: 'Mặc định',
      dataIndex: 'is_default',
      key: 'is_default',
      width: 110,
      align: 'center',
      render: (v) => (
        <Tag color={v ? 'success' : 'default'}>{v ? 'Mặc định' : 'Không'}</Tag>
      ),
    },
    {
      title: '',
      key: 'actions',
      width: 50,
      align: 'center',
      fixed: 'right',
      render: (_, record) => (
        <Dropdown
          trigger={['click']}
          menu={{
            items: [
              {
                key: 'edit',
                icon: <EditOutlined />,
                label: 'Sửa',
                onClick: () => handleEdit(record),
              },
              {
                key: 'set-default',
                icon: <StarOutlined />,
                label: 'Đặt mặc định',
                onClick: () => handleSetDefault(record),
              },
              { type: 'divider' },
              {
                key: 'delete',
                icon: <DeleteOutlined />,
                label: 'Xóa',
                danger: true,
                onClick: () => {
                  Modal.confirm({
                    title: 'Xác nhận xóa',
                    content: 'Bạn có chắc chắn muốn xóa sổ văn bản này?',
                    okText: 'Xóa',
                    cancelText: 'Hủy',
                    okButtonProps: { danger: true },
                    onOk: () => handleDelete(record.id),
                  });
                },
              },
            ],
          }}
        >
          <Button type="text" size="small" icon={<MoreOutlined style={{ fontSize: 18 }} />} style={{ color: '#64748b' }} />
        </Dropdown>
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Quản lý sổ văn bản
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Danh mục sổ văn bản trong hệ thống
        </p>
      </div>

      <Card
        variant="borderless"
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <BookOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách sổ văn bản</span>
          </div>
        }
        extra={
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAdd}
            style={{ borderRadius: 8 }}
          >
            Thêm sổ văn bản
          </Button>
        }
      >
        <Tabs
          activeKey={activeTab}
          onChange={(key) => setActiveTab(key)}
          items={TAB_ITEMS}
          style={{ marginBottom: 16 }}
        />
        <Table
          columns={columns}
          dataSource={data}
          rowKey="id"
          loading={loading}
          size="middle"
          sticky
          scroll={{ x: 600 }}
          pagination={false}
        />
      </Card>

      <Drawer
        title={editingRecord ? 'Cập nhật sổ văn bản' : 'Thêm sổ văn bản mới'}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        destroyOnClose
        rootClassName="drawer-gradient"
        width={720}
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)} ghost style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}>Hủy</Button>
            <Button type="primary" loading={saving} onClick={handleSave}>
              {editingRecord ? 'Cập nhật' : 'Thêm mới'}
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit">
          <Form.Item label="Tên sổ" name="name" rules={[{ required: true, message: 'Nhập tên sổ văn bản' }]}>
            <Input placeholder="VD: Sổ văn bản đến" maxLength={200} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Mô tả" name="description">
            <Input.TextArea rows={3} maxLength={500} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Thứ tự" name="sort_order" initialValue={0}>
            <InputNumber min={0} style={{ width: '100%', borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Sổ mặc định" name="is_default" valuePropName="checked" initialValue={false}>
            <Switch checkedChildren="Có" unCheckedChildren="Không" />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
