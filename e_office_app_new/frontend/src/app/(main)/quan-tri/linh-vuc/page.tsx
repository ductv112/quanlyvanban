'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Drawer, Form, Switch, InputNumber,
  Tag, Dropdown, Modal, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined, AppstoreOutlined,
  MoreOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';

interface DocField {
  id: number;
  unit_id: number;
  code: string;
  name: string;
  sort_order: number;
  is_active: boolean;
}

export default function DocFieldPage() {
  const { message } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<DocField[]>([]);
  const [keyword, setKeyword] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<DocField | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  const fetchData = useCallback(async () => {
    if (!user?.unitId) return;
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/linh-vuc', {
        params: { unit_id: user.unitId, keyword },
      });
      setData(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu');
    } finally {
      setLoading(false);
    }
  }, [keyword, user?.unitId, message]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const handleAdd = () => {
    setEditingRecord(null);
    form.resetFields();
    form.setFieldsValue({ sort_order: 0, is_active: true });
    setDrawerOpen(true);
  };

  const handleEdit = (record: DocField) => {
    setEditingRecord(record);
    form.setFieldsValue(record);
    setDrawerOpen(true);
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/quan-tri/linh-vuc/${id}`);
      message.success('Xóa thành công');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Mã lĩnh vực là bắt buộc': 'code',
      'Mã lĩnh vực không được để trống': 'code',
      'Mã lĩnh vực không được vượt quá 20 ký tự': 'code',
      'Mã lĩnh vực đã tồn tại trong đơn vị': 'code',
      'Tên lĩnh vực là bắt buộc': 'name',
      'Tên lĩnh vực không được để trống': 'name',
      'Tên lĩnh vực không được vượt quá 200 ký tự': 'name',
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
        await api.put(`/quan-tri/linh-vuc/${editingRecord.id}`, values);
        message.success('Cập nhật thành công');
      } else {
        await api.post('/quan-tri/linh-vuc', {
          ...values,
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

  const handleSearch = (value: string) => {
    setKeyword(value);
  };

  const columns: ColumnsType<DocField> = [
    {
      title: 'Mã',
      dataIndex: 'code',
      key: 'code',
      width: 120,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Tên lĩnh vực',
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
      title: 'Trạng thái',
      dataIndex: 'is_active',
      key: 'is_active',
      width: 120,
      render: (v) => (
        <Tag color={v ? 'success' : 'error'}>{v ? 'Hoạt động' : 'Ngừng'}</Tag>
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
              { type: 'divider' },
              {
                key: 'delete',
                icon: <DeleteOutlined />,
                label: 'Xóa',
                danger: true,
                onClick: () => {
                  Modal.confirm({
                    title: 'Xác nhận xóa',
                    content: 'Bạn có chắc chắn muốn xóa lĩnh vực này?',
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
          Quản lý lĩnh vực
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Danh mục lĩnh vực văn bản trong hệ thống
        </p>
      </div>

      <Card
        variant="borderless"
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <AppstoreOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách lĩnh vực</span>
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
              Thêm lĩnh vực
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
          pagination={false}
        />
      </Card>

      <Drawer forceRender
        title={editingRecord ? 'Cập nhật lĩnh vực' : 'Thêm lĩnh vực mới'}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        destroyOnHidden
        rootClassName="drawer-gradient"
        size={720}
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
          <Form.Item label="Mã" name="code" rules={[{ required: true, message: 'Nhập mã lĩnh vực' }]}>
            <Input placeholder="VD: KHCN" maxLength={20} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Tên" name="name" rules={[{ required: true, message: 'Nhập tên lĩnh vực' }]}>
            <Input placeholder="VD: Khoa học công nghệ" maxLength={200} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Thứ tự" name="sort_order" initialValue={0}>
            <InputNumber min={0} style={{ width: '100%', borderRadius: 8 }} />
          </Form.Item>

          {editingRecord && (
            <Form.Item label="Trạng thái" name="is_active" valuePropName="checked">
              <Switch checkedChildren="Hoạt động" unCheckedChildren="Ngừng" />
            </Form.Item>
          )}
        </Form>
      </Drawer>
    </div>
  );
}
