'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Space, Select, Drawer, Form, Input, InputNumber,
  Switch, App, Popconfirm, Tag, Empty, Tabs,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { PlusOutlined, EditOutlined, DeleteOutlined, SettingOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';

interface DocColumn {
  id: number;
  column_name: string;
  label: string;
  data_type: string;
  max_length: number | null;
  sort_order: number;
  is_mandatory: boolean;
  is_system: boolean;
  description: string;
}

// Module tabs: 1=VB đến, 2=VB đi, 3=VB dự thảo (theo doc_columns.type_id)

const DATA_TYPE_OPTIONS = [
  { value: 'text', label: 'Văn bản (text)' },
  { value: 'textarea', label: 'Văn bản dài (textarea)' },
  { value: 'number', label: 'Số (number)' },
  { value: 'date', label: 'Ngày (date)' },
  { value: 'select', label: 'Chọn (select)' },
];

const DATA_TYPE_COLOR: Record<string, string> = {
  text: 'blue', textarea: 'cyan', number: 'green', date: 'orange', select: 'purple',
};

export default function DocColumnConfigPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [data, setData] = useState<DocColumn[]>([]);
  // type_id: 1=VB đến, 2=VB đi, 3=VB dự thảo (theo doc_columns convention)
  const MODULE_TABS = [
    { key: '1', label: 'Văn bản đến' },
    { key: '2', label: 'Văn bản đi' },
    { key: '3', label: 'Văn bản dự thảo' },
  ];
  const [selectedTypeId, setSelectedTypeId] = useState<number>(1);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<DocColumn | null>(null);
  const [form] = Form.useForm();

  const fetchColumns = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/cau-hinh-truong', { params: { type_id: selectedTypeId } });
      setData(res.data || []);
    } catch { message.error('Lỗi tải cấu hình trường'); }
    finally { setLoading(false); }
  }, [selectedTypeId, message]);

  useEffect(() => { fetchColumns(); }, [fetchColumns]);

  const openDrawer = (record?: DocColumn) => {
    if (record) {
      setEditingRecord(record);
      form.setFieldsValue(record);
    } else {
      setEditingRecord(null);
      form.resetFields();
      form.setFieldsValue({ data_type: 'text', sort_order: (data.length + 1) * 10, is_mandatory: false });
    }
    setDrawerOpen(true);
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      const payload = {
        ...values,
        id: editingRecord?.id || null,
        type_id: selectedTypeId,
      };
      const { data: res } = await api.post('/quan-tri/cau-hinh-truong', payload);
      if (!res.success) { message.error(res.message); return; }
      message.success(editingRecord ? 'Cập nhật thành công' : 'Thêm trường thành công');
      setDrawerOpen(false);
      fetchColumns();
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      if (err?.response?.data?.message) message.error(err.response.data.message);
    } finally { setSaving(false); }
  };

  const handleDelete = async (id: number) => {
    try {
      const { data: res } = await api.delete(`/quan-tri/cau-hinh-truong/${id}`);
      if (!res.success) { message.error(res.message); return; }
      message.success('Đã xóa');
      fetchColumns();
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      message.error(err?.response?.data?.message || 'Lỗi xóa');
    }
  };

  const columns: ColumnsType<DocColumn> = [
    { title: 'Thứ tự', dataIndex: 'sort_order', width: 70, align: 'center' },
    { title: 'Tên trường', dataIndex: 'column_name', width: 150 },
    { title: 'Nhãn hiển thị', dataIndex: 'label', width: 200 },
    {
      title: 'Kiểu dữ liệu', dataIndex: 'data_type', width: 120,
      render: (val: string) => <Tag color={DATA_TYPE_COLOR[val] || 'default'}>{DATA_TYPE_OPTIONS.find(o => o.value === val)?.label || val}</Tag>,
    },
    { title: 'Độ dài', dataIndex: 'max_length', width: 80, align: 'center', render: (v) => v || '—' },
    {
      title: 'Bắt buộc', dataIndex: 'is_mandatory', width: 80, align: 'center',
      render: (val: boolean) => val ? <Tag color="red">Có</Tag> : <Tag>Không</Tag>,
    },
    { title: 'Mô tả', dataIndex: 'description', ellipsis: true },
    {
      title: '', width: 80, align: 'center',
      render: (_, record) => (
        <Space size={4}>
          <Button size="small" type="link" icon={<EditOutlined />} onClick={() => openDrawer(record)} />
          {!record.is_system && (
            <Popconfirm title="Xóa trường này?" onConfirm={() => handleDelete(record.id)}>
              <Button size="small" type="link" danger icon={<DeleteOutlined />} />
            </Popconfirm>
          )}
        </Space>
      ),
    },
  ];

  const selectedModuleName = MODULE_TABS.find(t => t.key === String(selectedTypeId))?.label || '';

  return (
    <Card
      title={<><SettingOutlined style={{ marginRight: 8 }} />Thuộc tính văn bản</>}
      extra={
        <Button type="primary" icon={<PlusOutlined />} onClick={() => openDrawer()}>Thêm trường mới</Button>
      }
    >
      <Tabs
        type="line"
        activeKey={String(selectedTypeId)}
        onChange={(key) => setSelectedTypeId(Number(key))}
        items={MODULE_TABS.map(t => ({
          key: t.key,
          label: t.label,
        }))}
        style={{ marginBottom: 0 }}
      />

      <div style={{ marginBottom: 12, marginTop: 12, color: '#595959' }}>
        Các trường bổ sung cho <strong>{selectedModuleName}</strong>. Khi tạo/sửa văn bản, các trường dưới đây sẽ hiển thị thêm trong form.
      </div>
          <Table<DocColumn>
            rowKey="id"
            loading={loading}
            columns={columns}
            dataSource={data}
            size="small"
            pagination={false}
            locale={{ emptyText: <Empty description="Chưa có trường bổ sung nào. Bấm 'Thêm trường mới' để tạo." /> }}
          />

      <Drawer forceRender
        title={editingRecord ? 'Sửa trường bổ sung' : 'Thêm trường bổ sung'}
        size={500}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        rootClassName="drawer-gradient"
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)} ghost style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}>Hủy</Button>
            <Button type="primary" loading={saving} onClick={handleSave}>{editingRecord ? 'Cập nhật' : 'Thêm'}</Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off">
          <Form.Item name="column_name" label="Tên trường (key)" rules={[{ required: true, message: 'Bắt buộc' }, { pattern: /^[a-z_][a-z0-9_]*$/, message: 'Chỉ dùng chữ thường, số, dấu gạch dưới' }]}>
            <Input placeholder="VD: effective_from, report_period" maxLength={100} disabled={!!editingRecord} />
          </Form.Item>
          <Form.Item name="label" label="Nhãn hiển thị" rules={[{ required: true, message: 'Bắt buộc' }]}>
            <Input placeholder="VD: Hiệu lực từ ngày" maxLength={200} />
          </Form.Item>
          <Form.Item name="data_type" label="Kiểu dữ liệu" rules={[{ required: true }]}>
            <Select options={DATA_TYPE_OPTIONS} />
          </Form.Item>
          <Form.Item name="max_length" label="Độ dài tối đa (chỉ cho text)">
            <InputNumber style={{ width: '100%' }} min={1} max={5000} />
          </Form.Item>
          <Form.Item name="sort_order" label="Thứ tự hiển thị">
            <InputNumber style={{ width: '100%' }} min={0} />
          </Form.Item>
          <Form.Item name="is_mandatory" label="Bắt buộc nhập" valuePropName="checked">
            <Switch />
          </Form.Item>
          <Form.Item name="description" label="Mô tả">
            <Input.TextArea rows={2} maxLength={500} showCount />
          </Form.Item>
        </Form>
      </Drawer>
    </Card>
  );
}
