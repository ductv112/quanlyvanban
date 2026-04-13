'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Card, Row, Col, Table, Button, Input, Tree, Tag, Space, Drawer,
  Form, TreeSelect, Select, Radio, Switch, DatePicker, Popconfirm,
  Skeleton, Tooltip, Avatar, Checkbox, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, LockOutlined, UnlockOutlined,
  DeleteOutlined, SearchOutlined, UserOutlined, ReloadOutlined,
  KeyOutlined, ApartmentOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

interface Staff {
  id: number;
  code: string;
  username: string;
  first_name: string;
  last_name: string;
  full_name: string;
  email: string;
  phone: string;
  mobile: string;
  gender: string;
  birthday: string;
  address: string;
  image: string;
  unit_id: number;
  department_id: number;
  position_id: number;
  position_name: string;
  department_name: string;
  unit_name: string;
  is_admin: boolean;
  is_unit_leader: boolean;
  is_dept_leader: boolean;
  locked: boolean;
}

interface TreeNode {
  key: number;
  title: string;
  children?: TreeNode[];
  [key: string]: any;
}

interface PositionOption {
  id: number;
  name: string;
}

interface DeptOption {
  id: number;
  name: string;
}

export default function StaffPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [treeData, setTreeData] = useState<TreeNode[]>([]);
  const [treeLoading, setTreeLoading] = useState(false);
  const [selectedDept, setSelectedDept] = useState<number | null>(null);
  const [data, setData] = useState<Staff[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [keyword, setKeyword] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [searchTree, setSearchTree] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<Staff | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();
  const [positions, setPositions] = useState<PositionOption[]>([]);
  const [departments, setDepartments] = useState<DeptOption[]>([]);
  const [selectedUnit, setSelectedUnit] = useState<number | null>(null);

  const fetchTree = useCallback(async () => {
    setTreeLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/don-vi/tree');
      setTreeData(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải cây đơn vị');
    } finally {
      setTreeLoading(false);
    }
  }, [message]);

  const fetchStaff = useCallback(async () => {
    setLoading(true);
    try {
      const params: any = { keyword, page, pageSize };
      if (selectedDept) params.department_id = selectedDept;
      if (statusFilter === 'active') params.locked = false;
      if (statusFilter === 'locked') params.locked = true;
      const { data: res } = await api.get('/quan-tri/nguoi-dung', { params });
      setData(res.data?.items || res.data || []);
      setTotal(res.data?.total || 0);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu');
    } finally {
      setLoading(false);
    }
  }, [keyword, page, pageSize, selectedDept, statusFilter, message]);

  const fetchPositions = useCallback(async () => {
    try {
      const { data: res } = await api.get('/quan-tri/chuc-vu', { params: { pageSize: 100 } });
      setPositions(res.data?.items || res.data || []);
    } catch { /* ignore */ }
  }, []);

  const fetchDeptsByUnit = useCallback(async (unitId: number) => {
    try {
      const { data: res } = await api.get('/quan-tri/don-vi', { params: { parent_id: unitId } });
      setDepartments(res.data || []);
    } catch { /* ignore */ }
  }, []);

  useEffect(() => {
    fetchTree();
    fetchPositions();
  }, [fetchTree, fetchPositions]);

  useEffect(() => {
    fetchStaff();
  }, [fetchStaff]);

  const handleSelectNode = (keys: any) => {
    const id = keys?.[0] ?? null;
    setSelectedDept(id);
    setPage(1);
  };

  const handleAdd = () => {
    setEditingRecord(null);
    form.resetFields();
    form.setFieldsValue({ gender: 'male' });
    setSelectedUnit(null);
    setDepartments([]);
    setDrawerOpen(true);
  };

  const handleEdit = (record: Staff) => {
    setEditingRecord(record);
    const values: any = {
      ...record,
      birthday: record.birthday ? dayjs(record.birthday) : null,
    };
    form.setFieldsValue(values);
    if (record.unit_id) {
      setSelectedUnit(record.unit_id);
      fetchDeptsByUnit(record.unit_id);
    }
    setDrawerOpen(true);
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/quan-tri/nguoi-dung/${id}`);
      message.success('Xóa thành công');
      fetchStaff();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const handleLockToggle = async (record: Staff) => {
    try {
      await api.patch(`/quan-tri/nguoi-dung/${record.id}/lock`);
      message.success(record.locked ? 'Đã mở khóa' : 'Đã khóa');
      fetchStaff();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi');
    }
  };

  const handleResetPassword = async (id: number) => {
    try {
      await api.patch(`/quan-tri/nguoi-dung/${id}/reset-password`);
      message.success('Đã reset mật khẩu');
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi reset mật khẩu');
    }
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      const payload = {
        ...values,
        birthday: values.birthday ? values.birthday.format('YYYY-MM-DD') : null,
      };
      if (editingRecord) {
        delete payload.password;
        await api.put(`/quan-tri/nguoi-dung/${editingRecord.id}`, payload);
        message.success('Cập nhật thành công');
      } else {
        await api.post('/quan-tri/nguoi-dung', payload);
        message.success('Thêm thành công');
      }
      setDrawerOpen(false);
      fetchStaff();
    } catch (err: any) {
      if (err?.response) {
        message.error(err?.response?.data?.message || 'Lỗi khi lưu');
      }
    } finally {
      setSaving(false);
    }
  };

  const handleUnitChange = (unitId: number) => {
    setSelectedUnit(unitId);
    form.setFieldsValue({ department_id: undefined });
    if (unitId) {
      fetchDeptsByUnit(unitId);
    } else {
      setDepartments([]);
    }
  };

  const filterTree = useCallback((nodes: TreeNode[], kw: string): TreeNode[] => {
    if (!kw) return nodes;
    return nodes
      .map((node) => {
        const children = node.children ? filterTree(node.children, kw) : [];
        if ((node.title as string).toLowerCase().includes(kw.toLowerCase()) || children.length > 0) {
          return { ...node, children };
        }
        return null;
      })
      .filter(Boolean) as TreeNode[];
  }, []);

  const filteredTree = useMemo(() => filterTree(treeData, searchTree), [treeData, searchTree, filterTree]);

  const flattenTreeForSelect = useCallback((nodes: TreeNode[]): any[] => {
    return nodes.map((n) => ({
      value: n.key,
      title: n.title,
      children: n.children ? flattenTreeForSelect(n.children) : undefined,
    }));
  }, []);

  const columns: ColumnsType<Staff> = [
    {
      title: '',
      dataIndex: 'image',
      key: 'avatar',
      width: 48,
      render: (v) => (
        <Avatar size={32} src={v || undefined} icon={!v ? <UserOutlined /> : undefined} style={{ background: '#1B3A5C' }} />
      ),
    },
    {
      title: 'Họ tên',
      dataIndex: 'full_name',
      key: 'full_name',
      ellipsis: true,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Mã NV',
      dataIndex: 'code',
      key: 'code',
      width: 110,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Username',
      dataIndex: 'username',
      key: 'username',
      width: 120,
    },
    {
      title: 'Chức vụ',
      dataIndex: 'position_name',
      key: 'position_name',
      width: 140,
      ellipsis: true,
    },
    {
      title: 'Phòng ban',
      dataIndex: 'department_name',
      key: 'department_name',
      width: 160,
      ellipsis: true,
    },
    {
      title: 'Email',
      dataIndex: 'email',
      key: 'email',
      width: 180,
      ellipsis: true,
    },
    {
      title: 'SDT',
      dataIndex: 'phone',
      key: 'phone',
      width: 110,
    },
    {
      title: 'Trạng thái',
      dataIndex: 'locked',
      key: 'locked',
      width: 110,
      render: (v) => (
        <Tag color={v ? 'error' : 'success'}>{v ? 'Đã khóa' : 'Hoạt động'}</Tag>
      ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 160,
      align: 'center',
      fixed: 'right',
      render: (_, record) => (
        <Space size={2}>
          <Tooltip title="Sửa">
            <Button type="text" size="small" icon={<EditOutlined />} onClick={() => handleEdit(record)} style={{ color: '#0891B2' }} />
          </Tooltip>
          <Tooltip title={record.locked ? 'Mở khóa' : 'Khóa'}>
            <Button type="text" size="small" icon={record.locked ? <UnlockOutlined /> : <LockOutlined />} onClick={() => handleLockToggle(record)} style={{ color: record.locked ? '#059669' : '#D97706' }} />
          </Tooltip>
          <Popconfirm title="Reset mật khẩu" description="Mật khẩu sẽ được đặt về mặc định?" onConfirm={() => handleResetPassword(record.id)} okText="Reset" cancelText="Hủy">
            <Tooltip title="Reset mật khẩu">
              <Button type="text" size="small" icon={<KeyOutlined />} style={{ color: '#64748b' }} />
            </Tooltip>
          </Popconfirm>
          <Popconfirm title="Xác nhận xóa" description="Bạn có chắc chắn muốn xóa người dùng này?" onConfirm={() => handleDelete(record.id)} okText="Xóa" cancelText="Hủy" okButtonProps={{ danger: true }}>
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
          Quản lý người dùng
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Quản lý tài khoản người dùng trong hệ thống
        </p>
      </div>

      <Row gutter={16}>
        {/* Left: Tree */}
        <Col xs={24} lg={7}>
          <Card
            bordered={false}
            style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)', minHeight: 500 }}
            title={
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <ApartmentOutlined style={{ color: '#0891B2' }} />
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Đơn vị / Phòng ban</span>
              </div>
            }
            extra={
              <Tooltip title="Tải lại">
                <Button type="text" size="small" icon={<ReloadOutlined />} onClick={fetchTree} />
              </Tooltip>
            }
          >
            <Input
              placeholder="Tìm kiếm..."
              prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
              value={searchTree}
              onChange={(e) => setSearchTree(e.target.value)}
              allowClear
              style={{ marginBottom: 12, borderRadius: 8 }}
            />
            {treeLoading ? (
              <Skeleton active paragraph={{ rows: 8 }} />
            ) : (
              <Tree
                treeData={filteredTree}
                onSelect={handleSelectNode}
                selectedKeys={selectedDept ? [selectedDept] : []}
                defaultExpandAll
                showLine
                blockNode
                style={{ background: 'transparent' }}
              />
            )}
          </Card>
        </Col>

        {/* Right: Table */}
        <Col xs={24} lg={17}>
          <Card
            bordered={false}
            style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
            title={
              <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách người dùng</span>
            }
            extra={
              <Button type="primary" icon={<PlusOutlined />} onClick={handleAdd} style={{ borderRadius: 8 }}>
                Thêm người dùng
              </Button>
            }
          >
            {/* Filter bar */}
            <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
              <Input.Search
                placeholder="Tìm kiếm họ tên, username..."
                allowClear
                onSearch={(v) => { setKeyword(v); setPage(1); }}
                style={{ width: 280, borderRadius: 8 }}
                prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
              />
              <Select
                value={statusFilter}
                onChange={(v) => { setStatusFilter(v); setPage(1); }}
                style={{ width: 160 }}
                options={[
                  { label: 'Tất cả', value: 'all' },
                  { label: 'Hoạt động', value: 'active' },
                  { label: 'Đã khóa', value: 'locked' },
                ]}
              />
            </div>

            <Table
              columns={columns}
              dataSource={data}
              rowKey="id"
              loading={loading}
              size="middle"
              sticky
              scroll={{ x: 1100 }}
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
        </Col>
      </Row>

      {/* Drawer add/edit */}
      <Drawer
        title={editingRecord ? `Sửa người dùng — ${editingRecord.code || ''}` : 'Thêm người dùng mới'}
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
          <Row gutter={16}>
            {/* Left column */}
            <Col span={12}>
              <Form.Item label="Tên đăng nhập" name="username" rules={[{ required: true, message: 'Nhập tên đăng nhập' }]}>
                <Input placeholder="username" disabled={!!editingRecord} style={{ borderRadius: 8 }} />
              </Form.Item>

              {!editingRecord && (
                <Form.Item label="Mật khẩu" name="password">
                  <Input.Password placeholder="Mặc định: Admin@123" style={{ borderRadius: 8 }} />
                </Form.Item>
              )}

              <Form.Item label="Họ" name="last_name" rules={[{ required: true, message: 'Nhập họ' }]}>
                <Input style={{ borderRadius: 8 }} />
              </Form.Item>

              <Form.Item label="Tên" name="first_name" rules={[{ required: true, message: 'Nhập tên' }]}>
                <Input style={{ borderRadius: 8 }} />
              </Form.Item>

              <Form.Item label="Email" name="email">
                <Input type="email" style={{ borderRadius: 8 }} />
              </Form.Item>

              <Form.Item label="SDT" name="phone">
                <Input style={{ borderRadius: 8 }} />
              </Form.Item>

              <Form.Item label="Di động" name="mobile">
                <Input style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>

            {/* Right column */}
            <Col span={12}>
              <Form.Item label="Đơn vị" name="unit_id" rules={[{ required: true, message: 'Chọn đơn vị' }]}>
                <TreeSelect
                  treeData={flattenTreeForSelect(treeData)}
                  placeholder="Chọn đơn vị"
                  allowClear
                  treeDefaultExpandAll
                  onChange={handleUnitChange}
                  style={{ borderRadius: 8 }}
                />
              </Form.Item>

              <Form.Item label="Phòng ban" name="department_id" rules={[{ required: true, message: 'Chọn phòng ban' }]}>
                <Select
                  placeholder="Chọn phòng ban"
                  allowClear
                  options={departments.map((d) => ({ label: d.name, value: d.id }))}
                  style={{ borderRadius: 8 }}
                />
              </Form.Item>

              <Form.Item label="Chức vụ" name="position_id">
                <Select
                  placeholder="Chọn chức vụ"
                  allowClear
                  options={positions.map((p) => ({ label: p.name, value: p.id }))}
                  style={{ borderRadius: 8 }}
                />
              </Form.Item>

              <Form.Item label="Giới tính" name="gender" initialValue="male">
                <Radio.Group>
                  <Radio value="male">Nam</Radio>
                  <Radio value="female">Nữ</Radio>
                  <Radio value="other">Khác</Radio>
                </Radio.Group>
              </Form.Item>

              <Form.Item label="Ngày sinh" name="birthday">
                <DatePicker format="DD/MM/YYYY" style={{ width: '100%', borderRadius: 8 }} />
              </Form.Item>

              <Form.Item label="Địa chỉ" name="address">
                <Input style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>

          <div style={{ borderTop: '1px solid #e8ecf1', paddingTop: 16, marginTop: 8 }}>
            <Space size={24}>
              <Form.Item name="is_admin" valuePropName="checked" noStyle>
                <Checkbox>Quản trị viên</Checkbox>
              </Form.Item>
              <Form.Item name="is_unit_leader" valuePropName="checked" noStyle>
                <Checkbox>Đại diện đơn vị</Checkbox>
              </Form.Item>
              <Form.Item name="is_dept_leader" valuePropName="checked" noStyle>
                <Checkbox>Đại diện phòng ban</Checkbox>
              </Form.Item>
            </Space>
          </div>
        </Form>
      </Drawer>
    </div>
  );
}
