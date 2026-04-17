'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Space, Drawer, Form, Select, Input, Switch,
  Dropdown, Modal, Tag, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, ApartmentOutlined,
  MoreOutlined, SettingOutlined, PoweroffOutlined,
} from '@ant-design/icons';
import { useRouter } from 'next/navigation';
import { api } from '@/lib/api';

interface WorkflowItem {
  id: number;
  name: string;
  doc_field_id: number | null;
  doc_field_name: string | null;
  version: string | null;
  step_count: number;
  is_active: boolean;
}

interface DocField {
  id: number;
  name: string;
}

export default function WorkflowPage() {
  const { message } = App.useApp();
  const router = useRouter();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<WorkflowItem[]>([]);
  const [docFields, setDocFields] = useState<DocField[]>([]);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<WorkflowItem | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/quy-trinh');
      setData(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu');
    } finally {
      setLoading(false);
    }
  }, [message]);

  const fetchDocFields = useCallback(async () => {
    try {
      const { data: res } = await api.get('/quan-tri/linh-vuc');
      setDocFields(res.data || []);
    } catch {
      // không hiện lỗi cho dropdown phụ
    }
  }, []);

  useEffect(() => {
    fetchData();
    fetchDocFields();
  }, [fetchData, fetchDocFields]);

  const handleAdd = () => {
    setEditingRecord(null);
    form.resetFields();
    form.setFieldsValue({ is_active: true });
    setDrawerOpen(true);
  };

  const handleEdit = (record: WorkflowItem) => {
    setEditingRecord(record);
    form.setFieldsValue({
      name: record.name,
      doc_field_id: record.doc_field_id,
      version: record.version,
      is_active: record.is_active,
    });
    setDrawerOpen(true);
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/quan-tri/quy-trinh/${id}`);
      message.success('Xóa quy trình thành công');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const handleToggleActive = async (record: WorkflowItem) => {
    try {
      await api.put(`/quan-tri/quy-trinh/${record.id}`, {
        ...record,
        is_active: !record.is_active,
      });
      message.success(record.is_active ? 'Đã vô hiệu hóa quy trình' : 'Đã kích hoạt quy trình');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi cập nhật trạng thái');
    }
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      if (editingRecord) {
        await api.put(`/quan-tri/quy-trinh/${editingRecord.id}`, values);
        message.success('Cập nhật quy trình thành công');
      } else {
        await api.post('/quan-tri/quy-trinh', values);
        message.success('Thêm quy trình thành công');
      }
      setDrawerOpen(false);
      fetchData();
    } catch (err: any) {
      if (err?.response?.data?.message) {
        message.error(err.response.data.message);
      }
    } finally {
      setSaving(false);
    }
  };

  const columns: ColumnsType<WorkflowItem> = [
    {
      title: 'STT',
      key: 'stt',
      width: 56,
      align: 'center',
      render: (_: unknown, __: WorkflowItem, index: number) => (
        <span style={{ color: '#64748b', fontSize: 13 }}>{index + 1}</span>
      ),
    },
    {
      title: 'Tên quy trình',
      dataIndex: 'name',
      key: 'name',
      render: (name: string) => (
        <span style={{ fontWeight: 500, color: '#1B3A5C' }}>{name}</span>
      ),
    },
    {
      title: 'Lĩnh vực',
      dataIndex: 'doc_field_name',
      key: 'doc_field_name',
      width: 150,
      render: (name: string | null) => name ? (
        <span style={{ color: '#475569' }}>{name}</span>
      ) : (
        <span style={{ color: '#94a3b8', fontStyle: 'italic' }}>—</span>
      ),
    },
    {
      title: 'Phiên bản',
      dataIndex: 'version',
      key: 'version',
      width: 100,
      align: 'center',
      render: (v: string | null) => v || <span style={{ color: '#94a3b8' }}>—</span>,
    },
    {
      title: 'Số bước',
      dataIndex: 'step_count',
      key: 'step_count',
      width: 80,
      align: 'center',
      render: (count: number) => (
        <span style={{ fontWeight: 600, color: '#0891B2' }}>{count || 0}</span>
      ),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'is_active',
      key: 'is_active',
      width: 100,
      align: 'center',
      render: (isActive: boolean) =>
        isActive ? (
          <Tag color="success">Hoạt động</Tag>
        ) : (
          <Tag color="default">Tạm dừng</Tag>
        ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 120,
      align: 'center',
      fixed: 'right',
      render: (_: unknown, record: WorkflowItem) => (
        <Dropdown
          trigger={['click']}
          menu={{
            items: [
              {
                key: 'design',
                icon: <ApartmentOutlined />,
                label: 'Thiết kế',
                onClick: () => router.push(`/quan-tri/quy-trinh/${record.id}/thiet-ke`),
              },
              {
                key: 'edit',
                icon: <EditOutlined />,
                label: 'Sửa',
                onClick: () => handleEdit(record),
              },
              {
                key: 'toggle',
                icon: <PoweroffOutlined />,
                label: record.is_active ? 'Vô hiệu hóa' : 'Kích hoạt',
                onClick: () => handleToggleActive(record),
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
                    content: `Bạn có chắc chắn muốn xóa quy trình "${record.name}"?`,
                    okText: 'Xóa',
                    cancelText: 'Hủy bỏ',
                    okButtonProps: { danger: true },
                    onOk: () => handleDelete(record.id),
                  });
                },
              },
            ],
          }}
        >
          <Button
            type="text"
            size="small"
            icon={<MoreOutlined style={{ fontSize: 18 }} />}
            style={{ color: '#64748b' }}
          />
        </Dropdown>
      ),
    },
  ];

  return (
    <div>
      <div className="page-header">
        <div>
          <h2 className="page-title">Quy trình xử lý</h2>
          <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
            Quản lý quy trình xử lý hồ sơ công việc
          </p>
        </div>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={handleAdd}
          style={{ borderRadius: 8 }}
        >
          Thêm quy trình
        </Button>
      </div>

      <Card
        className="page-card"
        variant="borderless"
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <SettingOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách quy trình</span>
          </div>
        }
      >
        <Table
          className="enhanced-table"
          columns={columns}
          dataSource={data}
          rowKey="id"
          loading={loading}
          size="middle"
          sticky
          scroll={{ x: 800 }}
          pagination={{ pageSize: 20, showSizeChanger: true }}
          locale={{
            emptyText: (
              <div style={{ padding: '32px 0', textAlign: 'center', color: '#64748b' }}>
                <ApartmentOutlined style={{ fontSize: 36, color: '#cbd5e1', marginBottom: 12, display: 'block' }} />
                <div style={{ fontWeight: 500, marginBottom: 4 }}>Chưa có quy trình xử lý</div>
                <div style={{ fontSize: 13 }}>Nhấn &ldquo;Thêm quy trình&rdquo; để tạo quy trình mới.</div>
              </div>
            ),
          }}
        />
      </Card>

      <Drawer forceRender
        title={editingRecord ? 'Chỉnh sửa quy trình' : 'Thêm quy trình'}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        destroyOnHidden
        rootClassName="drawer-gradient"
        size={720}
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)} ghost style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}>Hủy</Button>
            <Button type="primary" loading={saving} onClick={handleSave}>
              Lưu
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit">
          <Form.Item
            label="Tên quy trình"
            name="name"
            rules={[{ required: true, message: 'Vui lòng nhập tên quy trình' }]}
          >
            <Input
              placeholder="Nhập tên quy trình"
              maxLength={500}
              style={{ borderRadius: 8 }}
            />
          </Form.Item>

          <Form.Item label="Lĩnh vực" name="doc_field_id">
            <Select
              placeholder="Chọn lĩnh vực (nếu có)"
              allowClear
              showSearch
              optionFilterProp="label"
              options={docFields.map((f) => ({ value: f.id, label: f.name }))}
              style={{ borderRadius: 8 }}
            />
          </Form.Item>

          <Form.Item label="Phiên bản" name="version">
            <Input
              placeholder="VD: 1.0, 2.1"
              maxLength={50}
              style={{ borderRadius: 8 }}
            />
          </Form.Item>

          <Form.Item label="Trạng thái" name="is_active" valuePropName="checked">
            <Switch checkedChildren="Hoạt động" unCheckedChildren="Tạm dừng" />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
