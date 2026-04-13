'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Card, Row, Col, Table, Button, Input, Tree, Tag, Space, Drawer,
  Form, TreeSelect, Radio, Switch, InputNumber, Popconfirm, Skeleton, Tooltip, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, LockOutlined, UnlockOutlined,
  DeleteOutlined, SearchOutlined, ApartmentOutlined, ReloadOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';

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

interface TreeNode {
  key: number;
  title: string;
  children?: TreeNode[];
  is_unit?: boolean;
  [key: string]: any;
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

  const fetchTree = useCallback(async () => {
    setTreeLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/don-vi/tree');
      setTreeData(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu đơn vị');
    } finally {
      setTreeLoading(false);
    }
  }, [message]);

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
      if (err?.response) {
        message.error(err?.response?.data?.message || 'Lỗi khi lưu');
      }
    } finally {
      setSaving(false);
    }
  };

  const filterTree = useCallback((nodes: TreeNode[], keyword: string): TreeNode[] => {
    if (!keyword) return nodes;
    return nodes
      .map((node) => {
        const children = node.children ? filterTree(node.children, keyword) : [];
        if (
          (node.title as string).toLowerCase().includes(keyword.toLowerCase()) ||
          children.length > 0
        ) {
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
      title: 'Thao tác',
      key: 'actions',
      width: 130,
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
          <Tooltip title={record.is_locked ? 'Mở khóa' : 'Khóa'}>
            <Button
              type="text"
              size="small"
              icon={record.is_locked ? <UnlockOutlined /> : <LockOutlined />}
              onClick={() => handleLockToggle(record)}
              style={{ color: record.is_locked ? '#059669' : '#D97706' }}
            />
          </Tooltip>
          <Popconfirm
            title="Xác nhận xóa"
            description="Bạn có chắc chắn muốn xóa đơn vị này?"
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
            bordered={false}
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
            bordered={false}
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
      <Drawer
        title={editingRecord ? 'Cập nhật đơn vị' : 'Thêm đơn vị mới'}
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
                <Input placeholder="VD: PB01" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item label="Tên" name="name" rules={[{ required: true, message: 'Nhập tên' }]}>
                <Input placeholder="Tên đơn vị / phòng ban" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item label="Tên tiếng Anh" name="name_en">
                <Input placeholder="English name" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item label="Tên viết tắt" name="short_name">
                <Input placeholder="VD: CNTT" style={{ borderRadius: 8 }} />
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
              <Form.Item label="SDT" name="phone">
                <Input style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item label="Fax" name="fax">
                <Input style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item label="Email" name="email">
                <Input type="email" style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item label="Địa chỉ" name="address">
                <Input style={{ borderRadius: 8 }} />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item label="Cho phép sổ VB" name="allow_doc_book" valuePropName="checked">
            <Switch />
          </Form.Item>

          <Form.Item label="Mô tả" name="description">
            <Input.TextArea rows={3} style={{ borderRadius: 8 }} />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
