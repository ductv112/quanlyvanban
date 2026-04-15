'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Card, Row, Col, Table, Button, Input, Tree, Tag, Space, Drawer,
  Form, TreeSelect, Select, Radio, DatePicker,
  Skeleton, Tooltip, Avatar, Checkbox, App, Dropdown, Modal,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, LockOutlined, UnlockOutlined,
  DeleteOutlined, SearchOutlined, UserOutlined, ReloadOutlined,
  KeyOutlined, ApartmentOutlined, SafetyOutlined, SaveOutlined,
  MoreOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';
import type { TreeNode } from '@/types/tree';
import { filterTree, flattenTreeForSelect } from '@/lib/tree-utils';

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
  gender: number;
  birth_date: string;
  address: string;
  image: string;
  unit_id: number;
  department_id: number;
  position_id: number;
  position_name: string;
  department_name: string;
  unit_name: string;
  is_admin: boolean;
  is_represent_unit: boolean;
  is_represent_department: boolean;
  is_locked: boolean;
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
  const [deptToUnitMap, setDeptToUnitMap] = useState<Record<number, number>>({});

  // Phân quyền (gán nhóm quyền cho user)
  const [roleDrawerOpen, setRoleDrawerOpen] = useState(false);
  const [roleStaff, setRoleStaff] = useState<Staff | null>(null);
  const [allRoles, setAllRoles] = useState<{ id: number; name: string; description: string }[]>([]);
  const [staffRoleIds, setStaffRoleIds] = useState<number[]>([]);
  const [roleLoading, setRoleLoading] = useState(false);
  const [roleSaving, setRoleSaving] = useState(false);

  const mapTree = useCallback((nodes: any[]): any[] => {
    return nodes.map((n: any) => ({
      key: n.id,
      title: n.name,
      is_unit: n.is_unit,
      children: n.children ? mapTree(n.children) : undefined,
    }));
  }, []);

  // Build a map of dept_id -> unit_id by traversing the raw tree from API
  const buildDeptToUnitMap = useCallback((nodes: any[], currentUnitId?: number): Record<number, number> => {
    const map: Record<number, number> = {};
    for (const node of nodes) {
      const unitId = node.is_unit ? node.id : currentUnitId;
      if (unitId) {
        map[node.id] = unitId;
      }
      if (node.children) {
        const childMap = buildDeptToUnitMap(node.children, unitId);
        Object.assign(map, childMap);
      }
    }
    return map;
  }, []);

  const fetchTree = useCallback(async () => {
    setTreeLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/don-vi/tree');
      const rawData = res.data || [];
      setTreeData(mapTree(rawData));
      setDeptToUnitMap(buildDeptToUnitMap(rawData));
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải cây đơn vị');
    } finally {
      setTreeLoading(false);
    }
  }, [message, mapTree, buildDeptToUnitMap]);

  const fetchStaff = useCallback(async () => {
    setLoading(true);
    try {
      const params: any = { keyword, page, pageSize };
      if (selectedDept) params.department_id = selectedDept;
      if (statusFilter === 'active') params.is_locked = false;
      if (statusFilter === 'locked') params.is_locked = true;
      const { data: res } = await api.get('/quan-tri/nguoi-dung', { params });
      setData(res.data || []);
      setTotal(res.total || 0);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu');
    } finally {
      setLoading(false);
    }
  }, [keyword, page, pageSize, selectedDept, statusFilter, message]);

  const fetchPositions = useCallback(async () => {
    try {
      const { data: res } = await api.get('/quan-tri/chuc-vu', { params: { pageSize: 100 } });
      setPositions(res.data || []);
    } catch { /* ignore */ }
  }, []);

  const fetchDeptsByUnit = useCallback(async (unitId: number) => {
    try {
      const { data: res } = await api.get('/quan-tri/don-vi', { params: { parent_id: unitId } });
      setDepartments(res.data || []);
    } catch { /* ignore */ }
  }, []);

  // Phân quyền handlers
  const handleOpenRoles = async (record: Staff) => {
    setRoleStaff(record);
    setRoleDrawerOpen(true);
    setRoleLoading(true);
    try {
      const [rolesRes, staffRolesRes] = await Promise.all([
        api.get('/quan-tri/nhom-quyen'),
        api.get(`/quan-tri/nguoi-dung/${record.id}/nhom-quyen`),
      ]);
      setAllRoles(rolesRes.data?.data || []);
      const ids = (staffRolesRes.data?.data || []).map((r: any) => r.role_id);
      setStaffRoleIds(ids);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải nhóm quyền');
    } finally {
      setRoleLoading(false);
    }
  };

  const handleSaveRoles = async () => {
    if (!roleStaff) return;
    setRoleSaving(true);
    try {
      await api.put(`/quan-tri/nguoi-dung/${roleStaff.id}/nhom-quyen`, { roleIds: staffRoleIds });
      message.success('Lưu phân quyền thành công');
      setRoleDrawerOpen(false);
      fetchStaff();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi lưu phân quyền');
    } finally {
      setRoleSaving(false);
    }
  };

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
    form.setFieldsValue({ gender: 1 });

    // Pre-fill department from selected tree node
    if (selectedDept) {
      const unitId = deptToUnitMap[selectedDept];
      if (unitId) {
        setSelectedUnit(unitId);
        fetchDeptsByUnit(unitId);
        // If selected node IS the unit itself, only set unit_id
        if (unitId === selectedDept) {
          form.setFieldsValue({ unit_id: unitId });
        } else {
          form.setFieldsValue({ unit_id: unitId, department_id: selectedDept });
        }
      } else {
        setSelectedUnit(null);
        setDepartments([]);
      }
    } else {
      setSelectedUnit(null);
      setDepartments([]);
    }

    setDrawerOpen(true);
  };

  const handleEdit = (record: Staff) => {
    setEditingRecord(record);
    const values: any = {
      ...record,
      birth_date: record.birth_date ? dayjs(record.birth_date) : null,
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
      message.success(record.is_locked ? 'Đã mở khóa' : 'Đã khóa');
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

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Tên đăng nhập đã tồn tại': 'username',
      'Email đã được sử dụng': 'email',
      'Số điện thoại không đúng định dạng': 'phone',
      'Số di động không đúng định dạng': 'mobile',
      'Email không đúng định dạng': 'email',
      'Tên đăng nhập chỉ chứa chữ cái, số, dấu chấm, gạch ngang': 'username',
      'Tên đăng nhập phải có ít nhất 3 ký tự': 'username',
      'Mật khẩu phải có ít nhất 6 ký tự, chứa chữ hoa, chữ thường và số': 'password',
      'Họ và tên là bắt buộc': 'last_name',
      'Đơn vị và phòng ban là bắt buộc': 'department_id',
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
      const payload = {
        ...values,
        birth_date: values.birth_date ? values.birth_date.format('YYYY-MM-DD') : null,
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

  const handleUnitChange = (unitId: number) => {
    setSelectedUnit(unitId);
    form.setFieldsValue({ department_id: undefined });
    if (unitId) {
      fetchDeptsByUnit(unitId);
    } else {
      setDepartments([]);
    }
  };

  const filteredTree = useMemo(() => filterTree(treeData, searchTree), [treeData, searchTree]);

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
      dataIndex: 'is_locked',
      key: 'is_locked',
      width: 110,
      render: (v) => (
        <Tag color={v ? 'error' : 'success'}>{v ? 'Đã khóa' : 'Hoạt động'}</Tag>
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
                label: 'Sửa thông tin',
                onClick: () => handleEdit(record),
              },
              {
                key: 'roles',
                icon: <SafetyOutlined />,
                label: 'Phân quyền',
                onClick: () => handleOpenRoles(record),
              },
              {
                key: 'lock',
                icon: record.is_locked ? <UnlockOutlined /> : <LockOutlined />,
                label: record.is_locked ? 'Mở khóa tài khoản' : 'Khóa tài khoản',
                onClick: () => handleLockToggle(record),
              },
              {
                key: 'reset',
                icon: <KeyOutlined />,
                label: 'Reset mật khẩu',
                onClick: () => {
                  Modal.confirm({
                    title: 'Reset mật khẩu',
                    content: `Mật khẩu của "${record.full_name}" sẽ được đặt về mặc định (Admin@123)?`,
                    okText: 'Reset',
                    cancelText: 'Hủy',
                    onOk: () => handleResetPassword(record.id),
                  });
                },
              },
              { type: 'divider' },
              {
                key: 'delete',
                icon: <DeleteOutlined />,
                label: 'Xóa người dùng',
                danger: true,
                onClick: () => {
                  Modal.confirm({
                    title: 'Xác nhận xóa',
                    content: `Bạn có chắc chắn muốn xóa "${record.full_name}"?`,
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
            variant="borderless"
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
            variant="borderless"
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
        <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit" scrollToFirstError>
          {/* Prevent browser autofill */}
          <input type="text" name="prevent_autofill" style={{ display: 'none' }} />
          <input type="password" name="prevent_autofill_pass" style={{ display: 'none' }} />
          <Row gutter={16}>
            {/* Left column */}
            <Col span={12}>
              <Form.Item
                label="Tên đăng nhập"
                name="username"
                rules={[
                  { required: true, message: 'Nhập tên đăng nhập' },
                  { min: 3, message: 'Tối thiểu 3 ký tự' },
                  { pattern: /^[a-zA-Z0-9._-]+$/, message: 'Chỉ chứa chữ cái, số, dấu chấm, gạch ngang' },
                ]}
              >
                <Input placeholder="username" maxLength={50} disabled={!!editingRecord} autoComplete="off" style={{ borderRadius: 8 }} />
              </Form.Item>

              {!editingRecord && (
                <Form.Item
                  label="Mật khẩu"
                  name="password"
                  tooltip="Để trống sẽ dùng mặc định: Admin@123"
                  rules={[
                    { min: 6, message: 'Tối thiểu 6 ký tự' },
                    { pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, message: 'Phải chứa chữ hoa, chữ thường và số' },
                  ]}
                >
                  <Input.Password placeholder="Để trống = Admin@123" maxLength={50} autoComplete="new-password" style={{ borderRadius: 8 }} />
                </Form.Item>
              )}

              <Form.Item label="Họ" name="last_name" rules={[{ required: true, message: 'Nhập họ' }]}>
                <Input maxLength={50} style={{ borderRadius: 8 }} />
              </Form.Item>

              <Form.Item label="Tên" name="first_name" rules={[{ required: true, message: 'Nhập tên' }]}>
                <Input maxLength={50} style={{ borderRadius: 8 }} />
              </Form.Item>

              <Form.Item label="Email" name="email" rules={[{ type: 'email', message: 'Email không đúng định dạng' }]}>
                <Input type="email" maxLength={100} style={{ borderRadius: 8 }} />
              </Form.Item>

              <Form.Item label="Số điện thoại" name="phone" rules={[{ pattern: /^[0-9+\-\s()]{8,15}$/, message: 'Số điện thoại không đúng định dạng' }]}>
                <Input maxLength={20} style={{ borderRadius: 8 }} />
              </Form.Item>

              <Form.Item label="Di động" name="mobile" rules={[{ pattern: /^[0-9+\-\s()]{8,15}$/, message: 'Số di động không đúng định dạng' }]}>
                <Input maxLength={20} style={{ borderRadius: 8 }} />
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

              <Form.Item label="Giới tính" name="gender" initialValue={1}>
                <Radio.Group>
                  <Radio value={1}>Nam</Radio>
                  <Radio value={2}>Nữ</Radio>
                  <Radio value={0}>Khác</Radio>
                </Radio.Group>
              </Form.Item>

              <Form.Item label="Ngày sinh" name="birth_date">
                <DatePicker format="DD/MM/YYYY" style={{ width: '100%', borderRadius: 8 }} />
              </Form.Item>

              <Form.Item label="Địa chỉ" name="address">
                <Input maxLength={500} showCount style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>

        </Form>
      </Drawer>

      {/* Drawer phân quyền (gán nhóm quyền cho user) */}
      <Drawer
        title={<>Phân quyền: <strong>{roleStaff?.full_name}</strong></>}
        open={roleDrawerOpen}
        onClose={() => setRoleDrawerOpen(false)}
        destroyOnHidden
        rootClassName="drawer-gradient"
        size={480}
        extra={
          <Button
            type="primary"
            icon={<SaveOutlined />}
            loading={roleSaving}
            onClick={handleSaveRoles}
          >
            Lưu
          </Button>
        }
      >
        {roleLoading ? (
          <Skeleton active paragraph={{ rows: 6 }} />
        ) : (
          <div>
            <p style={{ fontSize: 13, color: '#64748b', marginBottom: 16 }}>
              Chọn nhóm quyền cho người dùng <strong>{roleStaff?.full_name}</strong> ({roleStaff?.username})
            </p>
            <Checkbox.Group
              value={staffRoleIds}
              onChange={(values) => setStaffRoleIds(values as number[])}
              style={{ width: '100%' }}
            >
              <Space orientation="vertical" style={{ width: '100%' }} size={8}>
                {allRoles.map((role) => (
                  <Card
                    key={role.id}
                    size="small"
                    variant="outlined"
                    style={{
                      borderRadius: 8,
                      borderColor: staffRoleIds.includes(role.id) ? '#0891B2' : '#e8ecf1',
                      background: staffRoleIds.includes(role.id) ? '#f0fdfa' : '#fff',
                      cursor: 'pointer',
                      transition: 'all 0.2s',
                    }}
                    styles={{ body: { padding: '10px 14px' } }}
                    onClick={() => {
                      setStaffRoleIds((prev) =>
                        prev.includes(role.id)
                          ? prev.filter((id) => id !== role.id)
                          : [...prev, role.id]
                      );
                    }}
                  >
                    <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <Checkbox value={role.id} onClick={(e) => e.stopPropagation()} />
                      <div>
                        <div style={{ fontWeight: 600, color: '#1B3A5C', fontSize: 14 }}>{role.name}</div>
                        {role.description && (
                          <div style={{ fontSize: 12, color: '#94a3b8' }}>{role.description}</div>
                        )}
                      </div>
                    </div>
                  </Card>
                ))}
              </Space>
            </Checkbox.Group>
          </div>
        )}
      </Drawer>
    </div>
  );
}
