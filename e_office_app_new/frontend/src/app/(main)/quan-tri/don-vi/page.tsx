'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Card, Row, Col, Table, Button, Input, Tree, Tag, Space, Drawer,
  Form, TreeSelect, Radio, Switch, InputNumber, Skeleton, Tooltip, Dropdown, Modal, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, LockOutlined, UnlockOutlined,
  DeleteOutlined, SearchOutlined, ApartmentOutlined, ReloadOutlined,
  MoreOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import type { TreeNode } from '@/types/tree';
import { filterTree, flattenTreeForSelect } from '@/lib/tree-utils';

interface Department {
  id: number;
  parent_id: number | null;
  code: string;
  name: string;
  name_en: string;
  short_name: string;
  is_unit: boolean;
  sort_order: number;
  phone: string;
  fax: string;
  email: string;
  address: string;
  allow_doc_book: boolean;
  description: string;
  is_locked: boolean;
  staff_count: number;
}

export default function DepartmentPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [treeData, setTreeData] = useState<TreeNode[]>([]);
  const [treeLoading, setTreeLoading] = useState(false);
  const [selectedNode, setSelectedNode] = useState<number | null>(null);
  const [departments, setDepartments] = useState<Department[]>([]);
  const [searchTree, setSearchTree] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<Department | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  // Map API tree (id/name/children) → Ant Design Tree (key/title/children)
  const mapTree = useCallback((nodes: any[]): TreeNode[] => {
    return nodes.map((n) => ({
      key: n.id,
      title: n.name,
      is_unit: n.is_unit,
      children: n.children ? mapTree(n.children) : undefined,
    }));
  }, []);

  const fetchTree = useCallback(async () => {
    setTreeLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/don-vi/tree');
      setTreeData(mapTree(res.data || []));
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu đơn vị');
    } finally {
      setTreeLoading(false);
    }
  }, [message, mapTree]);

  const fetchDepartments = useCallback(async (parentId?: number | null) => {
    setLoading(true);
    try {
      const params: any = {};
      if (parentId) params.parent_id = parentId;
      const { data: res } = await api.get('/quan-tri/don-vi', { params });
      setDepartments(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách');
    } finally {
      setLoading(false);
    }
  }, [message]);

  useEffect(() => {
    fetchTree();
    fetchDepartments();
  }, [fetchTree, fetchDepartments]);

  const handleSelectNode = (keys: any) => {
    const id = keys?.[0] ?? null;
    setSelectedNode(id);
    fetchDepartments(id);
  };

  const handleAdd = () => {
    setEditingRecord(null);
    form.resetFields();
    if (selectedNode) {
      form.setFieldsValue({ parent_id: selectedNode });
    }
    setDrawerOpen(true);
  };

  const handleEdit = (record: Department) => {
    setEditingRecord(record);
    form.setFieldsValue({
      ...record,
      is_unit: record.is_unit ? 'unit' : 'dept',
    });
    setDrawerOpen(true);
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/quan-tri/don-vi/${id}`);
      message.success('Xóa thành công');
      fetchTree();
      fetchDepartments(selectedNode);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const handleLockToggle = async (record: Department) => {
    try {
      await api.patch(`/quan-tri/don-vi/${record.id}/lock`);
      message.success(record.is_locked ? 'Đã mở khóa' : 'Đã khóa');
      fetchDepartments(selectedNode);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi');
    }
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Mã đơn vị đã tồn tại': 'code',
      'Tên đơn vị là bắt buộc': 'name',
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
        is_unit: values.is_unit === 'unit',
      };
      if (editingRecord) {
        await api.put(`/quan-tri/don-vi/${editingRecord.id}`, payload);
        message.success('Cập nhật thành công');
      } else {
        await api.post('/quan-tri/don-vi', payload);
        message.success('Thêm thành công');
      }
      setDrawerOpen(false);
      fetchTree();
      fetchDepartments(selectedNode);
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

  const filteredTree = useMemo(() => filterTree(treeData, searchTree), [treeData, searchTree]);

  const columns: ColumnsType<Department> = [
    {
      title: 'Mã',
      dataIndex: 'code',
      key: 'code',
      width: 100,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Tên',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
    },
    {
      title: 'Cấp',
      dataIndex: 'is_unit',
      key: 'is_unit',
      width: 120,
      render: (v) => (
        <Tag color={v ? '#0891B2' : '#1B3A5C'}>{v ? 'Đơn vị' : 'Phòng ban'}</Tag>
      ),
    },
    {
      title: 'Số NV',
      dataIndex: 'staff_count',
      key: 'staff_count',
      width: 80,
      align: 'center',
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
                key: 'lock',
                icon: record.is_locked ? <UnlockOutlined /> : <LockOutlined />,
                label: record.is_locked ? 'Mở khóa' : 'Khóa',
                onClick: () => handleLockToggle(record),
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
                    content: 'Bạn có chắc chắn muốn xóa đơn vị này?',
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
          Quản lý đơn vị
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Quản lý cơ cấu tổ chức, đơn vị và phòng ban
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
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Cơ cấu tổ chức</span>
              </div>
            }
            extra={
              <Tooltip title="Tải lại">
                <Button type="text" size="small" icon={<ReloadOutlined />} onClick={fetchTree} />
              </Tooltip>
            }
          >
            <Input
              placeholder="Tìm kiếm đơn vị..."
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
                selectedKeys={selectedNode ? [selectedNode] : []}
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
              <span style={{ fontWeight: 600, color: '#1B3A5C' }}>
                Danh sách đơn vị
              </span>
            }
            extra={
              <Button
                type="primary"
                icon={<PlusOutlined />}
                onClick={handleAdd}
                style={{ borderRadius: 8 }}
              >
                Thêm đơn vị
              </Button>
            }
          >
            <Table
              className="enhanced-table"
              columns={columns}
              dataSource={departments}
              rowKey="id"
              loading={loading}
              pagination={false}
              size="middle"
              sticky
              scroll={{ x: 600 }}
            />
          </Card>
        </Col>
      </Row>

      {/* Drawer add/edit */}
      <Drawer forceRender
        title={editingRecord ? 'Cập nhật đơn vị' : 'Thêm đơn vị mới'}
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
          <Form.Item label="Đơn vị cha" name="parent_id">
            <TreeSelect
              treeData={flattenTreeForSelect(treeData)}
              placeholder="Chọn đơn vị cha (bỏ trống nếu là gốc)"
              allowClear
              treeDefaultExpandAll
              style={{ borderRadius: 8 }}
            />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item label="Mã" name="code" rules={[{ required: true, message: 'Nhập mã' }]}>
                <Input placeholder="VD: PB01" maxLength={50} style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item label="Tên" name="name" rules={[{ required: true, message: 'Nhập tên' }]}>
                <Input placeholder="Tên đơn vị / phòng ban" maxLength={200} style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item label="Tên tiếng Anh" name="name_en">
                <Input placeholder="English name" maxLength={200} style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item label="Tên viết tắt" name="short_name">
                <Input placeholder="VD: CNTT" maxLength={50} style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item label="Cấp" name="is_unit" initialValue="dept">
            <Radio.Group>
              <Radio value="unit">Đơn vị</Radio>
              <Radio value="dept">Phòng ban</Radio>
            </Radio.Group>
          </Form.Item>

          <Row gutter={16}>
            <Col span={8}>
              <Form.Item label="Thứ tự" name="sort_order" initialValue={0}>
                <InputNumber min={0} style={{ width: '100%', borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item label="SDT" name="phone" rules={[{ pattern: /^[0-9+\-\s()]*$/, message: 'Số điện thoại không hợp lệ' }]}>
                <Input maxLength={20} style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item label="Fax" name="fax" rules={[{ pattern: /^[0-9+\-\s()]*$/, message: 'Số fax không hợp lệ' }]}>
                <Input maxLength={20} style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item label="Email" name="email" rules={[{ type: 'email', message: 'Email không hợp lệ' }]}>
                <Input maxLength={100} style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item label="Địa chỉ" name="address">
                <Input maxLength={500} style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item label="Cho phép sổ VB" name="allow_doc_book" valuePropName="checked">
            <Switch />
          </Form.Item>

          <Form.Item label="Mô tả" name="description">
            <Input.TextArea rows={3} maxLength={500} style={{ borderRadius: 8 }} />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
