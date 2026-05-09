'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Card, Table, Button, Space, Drawer, Form, Select, Input, InputNumber,
  Dropdown, Modal, Tabs, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, FileTextOutlined,
  MoreOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';

interface DocType {
  id: number;
  type_id: number;
  parent_id: number | null;
  code: string;
  name: string;
  description: string;
  sort_order: number;
  // DB column = SMALLINT: 0 = Khong co, 1 = So/Ky hieu, 2 = So-Ky hieu
  notation_type: number;
  is_default: boolean;
  children?: DocType[];
}

const TAB_ITEMS = [
  { key: '1', label: 'Văn bản đến' },
  { key: '2', label: 'Văn bản đi' },
  { key: '3', label: 'Văn bản dự thảo' },
];

// Flatten tree for parent select options
function flattenTree(nodes: DocType[], level = 0): { id: number; name: string; level: number }[] {
  const result: { id: number; name: string; level: number }[] = [];
  for (const node of nodes) {
    result.push({ id: node.id, name: node.name, level });
    if (node.children) {
      result.push(...flattenTree(node.children, level + 1));
    }
  }
  return result;
}

export default function DocTypePage() {
  const { message, modal } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<DocType[]>([]);
  const [activeTab, setActiveTab] = useState('1');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<DocType | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/loai-van-ban/tree', {
        params: { type_id: activeTab },
      });
      setData(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu');
    } finally {
      setLoading(false);
    }
  }, [activeTab, message]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const parentOptions = useMemo(() => {
    const flat = flattenTree(data);
    return flat.map((item) => ({
      value: item.id,
      label: `${'— '.repeat(item.level)}${item.name}`,
    }));
  }, [data]);

  const handleAdd = () => {
    setEditingRecord(null);
    form.resetFields();
    form.setFieldsValue({ sort_order: 0, parent_id: null, notation_type: 0 });
    setDrawerOpen(true);
  };

  const handleEdit = (record: DocType) => {
    setEditingRecord(record);
    form.setFieldsValue({
      parent_id: record.parent_id,
      code: record.code,
      name: record.name,
      // BUG #29: DB tra ve notation_type = number (smallint). Coerce de Select hien dung option.
      notation_type: Number(record.notation_type) || 0,
      sort_order: record.sort_order,
    });
    setDrawerOpen(true);
  };

  // BUG #27 + #32: Hoi xac nhan khi click Huy/onClose neu form dirty.
  const handleCancelDrawer = () => {
    if (form.isFieldsTouched()) {
      modal.confirm({
        title: 'Xác nhận hủy',
        content: 'Bạn có chắc chắn muốn hủy? Dữ liệu đã nhập/sửa sẽ không được lưu.',
        okText: 'Hủy bỏ',
        cancelText: 'Tiếp tục',
        okButtonProps: { danger: true },
        onOk: () => {
          form.resetFields();
          setDrawerOpen(false);
        },
      });
    } else {
      setDrawerOpen(false);
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/quan-tri/loai-van-ban/${id}`);
      message.success('Xóa thành công');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Tên loại văn bản là bắt buộc': 'name',
      'Tên loại văn bản không được để trống': 'name',
      'Tên loại văn bản không được vượt quá 200 ký tự': 'name',
      'Mã loại văn bản là bắt buộc': 'code',
      'Mã loại văn bản không được để trống': 'code',
      'Mã loại văn bản không được vượt quá 20 ký tự': 'code',
      'Mã loại văn bản đã tồn tại': 'code',
      'Loại văn bản cha không tồn tại': 'parent_id',
      'Không thể chọn chính mình làm cha': 'parent_id',
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
        await api.put(`/quan-tri/loai-van-ban/${editingRecord.id}`, values);
        message.success('Cập nhật thành công');
      } else {
        await api.post('/quan-tri/loai-van-ban', {
          ...values,
          type_id: Number(activeTab),
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

  const columns: ColumnsType<DocType> = [
    {
      title: 'Mã',
      dataIndex: 'code',
      key: 'code',
      width: 120,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Tên loại VB',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
    },
    {
      title: 'Kiểu ký hiệu',
      dataIndex: 'notation_type',
      key: 'notation_type',
      width: 140,
      render: (v: number | string | null | undefined) => {
        const n = Number(v);
        if (n === 1) return 'Số/Ký hiệu';
        if (n === 2) return 'Số-Ký hiệu';
        return <span style={{ color: '#9CA3AF' }}>Không có</span>;
      },
    },
    {
      title: 'Thứ tự',
      dataIndex: 'sort_order',
      key: 'sort_order',
      width: 90,
      align: 'center',
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
                    content: 'Bạn có chắc chắn muốn xóa loại văn bản này?',
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
          Quản lý loại văn bản
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Danh mục loại văn bản trong hệ thống
        </p>
      </div>

      <Card
        variant="borderless"
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <FileTextOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách loại văn bản</span>
          </div>
        }
        extra={
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={handleAdd}
            style={{ borderRadius: 8 }}
          >
            Thêm loại văn bản
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
          className="enhanced-table"
          columns={columns}
          dataSource={data}
          rowKey="id"
          loading={loading}
          size="middle"
          sticky
          scroll={{ x: 600 }}
          pagination={false}
          expandable={{ childrenColumnName: 'children' }}
        />
      </Card>

      <Drawer forceRender
        title={editingRecord ? 'Cập nhật loại văn bản' : 'Thêm loại văn bản mới'}
        open={drawerOpen}
        onClose={handleCancelDrawer}
        rootClassName="drawer-gradient"
        size={720}
        extra={
          <Space>
            <Button onClick={handleCancelDrawer} ghost style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}>Hủy</Button>
            <Button type="primary" loading={saving} onClick={handleSave}>
              {editingRecord ? 'Cập nhật' : 'Thêm mới'}
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit">
          <Form.Item label="Loại cha" name="parent_id">
            <Select
              placeholder="Chọn loại cha (nếu có)"
              allowClear
              showSearch
              filterOption={(input, option) => {
                const label = String(option?.label ?? '').toLowerCase();
                return label.includes((input || '').trim().toLowerCase());
              }}
              options={parentOptions}
              style={{ borderRadius: 8 }}
            />
          </Form.Item>

          <Form.Item label="Mã" name="code" rules={[{ required: true, message: 'Nhập mã loại văn bản' }]}>
            <Input placeholder="VD: NQ" maxLength={20} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Tên" name="name" rules={[{ required: true, message: 'Nhập tên loại văn bản' }]}>
            <Input placeholder="VD: Nghị quyết" maxLength={200} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Kiểu ký hiệu" name="notation_type" initialValue={0}>
            <Select
              placeholder="Chọn kiểu ký hiệu"
              options={[
                { value: 0, label: 'Không có' },
                { value: 1, label: 'Số/Ký hiệu' },
                { value: 2, label: 'Số-Ký hiệu' },
              ]}
              style={{ borderRadius: 8 }}
            />
          </Form.Item>

          <Form.Item label="Thứ tự" name="sort_order" initialValue={0}>
            <InputNumber min={0} style={{ width: '100%', borderRadius: 8 }} />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
