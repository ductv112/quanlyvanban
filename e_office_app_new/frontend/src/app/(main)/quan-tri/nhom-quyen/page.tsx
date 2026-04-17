'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Drawer, Form, Tree,
  Tag, Spin, Dropdown, Modal, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined,
  SafetyCertificateOutlined, KeyOutlined, SaveOutlined, MoreOutlined,
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
      setData(res.data || []);
      setTotal(res.total || 0);
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
      message.success('Xóa thành công');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Tên nhóm quyền đã tồn tại': 'name',
      'Tên nhóm quyền là bắt buộc': 'name',
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
        await api.put(`/quan-tri/nhom-quyen/${editingRecord.id}`, values);
        message.success('Cập nhật thành công');
      } else {
        await api.post('/quan-tri/nhom-quyen', values);
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

  // Map API tree → Ant Design Tree format
  const mapRightTree = (nodes: any[]): any[] => {
    return nodes.map((n: any) => ({
      key: n.id,
      title: n.name_of_menu || n.name,
      children: n.children ? mapRightTree(n.children) : undefined,
    }));
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
      setRightTree(mapRightTree(treeRes.data?.data || []));
      const ids = (rolePermsRes.data?.data || []).map((r: any) => r.right_id || r.id);
      setCheckedKeys(ids);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải quyền');
    } finally {
      setPermLoading(false);
    }
  };

  const handleSavePermissions = async () => {
    if (!permRole) return;
    setPermSaving(true);
    try {
      await api.put(`/quan-tri/nhom-quyen/${permRole.id}/quyen`, { rightIds: checkedKeys });
      message.success('Lưu phân quyền thành công');
      setPermDrawerOpen(false);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi lưu phân quyền');
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
      title: 'Tên nhóm',
      dataIndex: 'name',
      key: 'name',
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Mô tả',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
    },
    {
      title: 'Số người dùng',
      dataIndex: 'staff_count',
      key: 'staff_count',
      width: 130,
      align: 'center',
      render: (v) => <Tag color="blue">{v || 0}</Tag>,
    },
    {
      title: 'Ngày tạo',
      dataIndex: 'created_at',
      key: 'created_at',
      width: 140,
      render: (v) => v ? dayjs(v).format('DD/MM/YYYY') : '-',
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
                label: 'Sửa thông tin',
                onClick: () => handleEdit(record),
              },
              {
                key: 'permissions',
                icon: <KeyOutlined />,
                label: 'Phân quyền',
                onClick: () => handleOpenPermissions(record),
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
                    content: 'Bạn có chắc chắn muốn xóa nhóm quyền này?',
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
          Quản lý nhóm quyền
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Quản lý nhóm quyền và phân quyền cho người dùng
        </p>
      </div>

      <Card
        variant="borderless"
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <SafetyCertificateOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách nhóm quyền</span>
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
            <Button type="primary" icon={<PlusOutlined />} onClick={handleAdd} style={{ borderRadius: 8 }}>
              Thêm nhóm quyền
            </Button>
          </Space>
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
          scroll={{ x: 700 }}
          pagination={{
            current: page,
            pageSize,
            total,
            showSizeChanger: true,
            showTotal: (t) => `Tổng ${t}`,
            onChange: (p, ps) => { setPage(p); setPageSize(ps); },
          }}
        />
      </Card>

      {/* Drawer add/edit */}
      <Drawer forceRender
        title={editingRecord ? 'Cập nhật nhóm quyền' : 'Thêm nhóm quyền mới'}
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
          <Form.Item label="Tên nhóm quyền" name="name" rules={[{ required: true, message: 'Nhập tên nhóm quyền' }]}>
            <Input placeholder="VD: Quản trị hệ thống" maxLength={100} style={{ borderRadius: 8 }} />
          </Form.Item>
          <Form.Item label="Mô tả" name="description">
            <Input.TextArea rows={4} maxLength={500} placeholder="Mô tả vai trò của nhóm quyền" style={{ borderRadius: 8 }} />
          </Form.Item>
        </Form>
      </Drawer>

      {/* Drawer permissions */}
      <Drawer forceRender
        title={<>Phân quyền: <strong>{permRole?.name}</strong></>}
        open={permDrawerOpen}
        onClose={() => setPermDrawerOpen(false)}
        destroyOnHidden
        rootClassName="drawer-gradient"
        size={720}
        extra={
          <Button
            type="primary"
            icon={<SaveOutlined />}
            loading={permSaving}
            onClick={handleSavePermissions}
          >
            Lưu phân quyền
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
