'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Card, Row, Col, Tree, Button, Input, Form, Switch, InputNumber,
  Popconfirm, Skeleton, Tooltip, Empty, Space, App,
} from 'antd';
import {
  PlusOutlined, DeleteOutlined, SearchOutlined, SaveOutlined,
  AppstoreOutlined, ReloadOutlined, PlusCircleOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';

interface RightNode {
  id: number;
  parent_id: number | null;
  name: string;
  name_of_menu: string;
  action_link: string;
  icon: string;
  sort_order: number;
  show_menu: boolean;
  default_page: boolean;
  show_in_app: boolean;
  description: string;
}

interface TreeNode {
  key: number;
  title: string;
  children?: TreeNode[];
  data?: RightNode;
  [key: string]: any;
}

export default function RightsPage() {
  const { message } = App.useApp();
  const [treeData, setTreeData] = useState<TreeNode[]>([]);
  const [treeLoading, setTreeLoading] = useState(false);
  const [searchTree, setSearchTree] = useState('');
  const [selectedNode, setSelectedNode] = useState<RightNode | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  // Map API tree → Ant Design Tree format (key/title/children) + store data
  const mapTree = useCallback((nodes: any[]): TreeNode[] => {
    return nodes.map((n) => ({
      key: n.id,
      title: n.name_of_menu || n.name,
      data: n as RightNode,
      children: n.children ? mapTree(n.children) : undefined,
    }));
  }, []);

  const fetchTree = useCallback(async () => {
    setTreeLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/chuc-nang/tree');
      setTreeData(mapTree(res.data || []));
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu');
    } finally {
      setTreeLoading(false);
    }
  }, [message, mapTree]);

  useEffect(() => {
    fetchTree();
  }, [fetchTree]);

  const findNodeData = useCallback((nodes: TreeNode[], key: number): RightNode | null => {
    for (const node of nodes) {
      if (node.key === key) return node.data || null;
      if (node.children) {
        const found = findNodeData(node.children, key);
        if (found) return found;
      }
    }
    return null;
  }, []);

  const handleSelectNode = (keys: any) => {
    const key = keys?.[0];
    if (!key) {
      setSelectedNode(null);
      return;
    }
    const nodeData = findNodeData(treeData, key);
    if (nodeData) {
      setSelectedNode(nodeData);
      form.setFieldsValue(nodeData);
    }
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Tên chức năng là bắt buộc': 'name',
    };
    const fieldName = fieldErrorMap[errorMessage];
    if (fieldName) {
      form.setFields([{ name: fieldName, errors: [errorMessage] }]);
      return true;
    }
    return false;
  };

  const handleSave = async () => {
    if (!selectedNode) return;
    try {
      const values = await form.validateFields();
      setSaving(true);
      await api.put(`/quan-tri/chuc-nang/${selectedNode.id}`, {
        ...values,
        parent_id: selectedNode.parent_id,
      });
      message.success('Cập nhật thành công');
      fetchTree();
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

  const handleDelete = async () => {
    if (!selectedNode) return;
    try {
      await api.delete(`/quan-tri/chuc-nang/${selectedNode.id}`);
      message.success('Xóa thành công');
      setSelectedNode(null);
      form.resetFields();
      fetchTree();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const handleAddRoot = async () => {
    try {
      await api.post('/quan-tri/chuc-nang', {
        name: 'Chức năng mới',
        name_of_menu: 'Menu mới',
        parent_id: null,
        sort_order: 0,
      });
      message.success('Thêm chức năng gốc thành công');
      fetchTree();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi thêm');
    }
  };

  const handleAddChild = async () => {
    if (!selectedNode) return;
    try {
      await api.post('/quan-tri/chuc-nang', {
        name: 'Chức năng con mới',
        name_of_menu: 'Menu con',
        parent_id: selectedNode.id,
        sort_order: 0,
      });
      message.success('Thêm chức năng con thành công');
      fetchTree();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi thêm');
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

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Quản lý chức năng
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Quản lý cây chức năng và menu hệ thống
        </p>
      </div>

      <Row gutter={16}>
        {/* Left: Tree */}
        <Col xs={24} lg={10}>
          <Card
            variant="borderless"
            style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)', minHeight: 500 }}
            title={
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <AppstoreOutlined style={{ color: '#0891B2' }} />
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Cây chức năng</span>
              </div>
            }
            extra={
              <Space>
                <Tooltip title="Thêm gốc">
                  <Button type="primary" size="small" icon={<PlusOutlined />} onClick={handleAddRoot} style={{ borderRadius: 6 }}>
                    Thêm gốc
                  </Button>
                </Tooltip>
                <Tooltip title="Tải lại">
                  <Button type="text" size="small" icon={<ReloadOutlined />} onClick={fetchTree} />
                </Tooltip>
              </Space>
            }
          >
            <Input
              placeholder="Tìm kiếm chức năng..."
              prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
              value={searchTree}
              onChange={(e) => setSearchTree(e.target.value)}
              allowClear
              style={{ marginBottom: 12, borderRadius: 8 }}
            />
            {treeLoading ? (
              <Skeleton active paragraph={{ rows: 10 }} />
            ) : (
              <Tree
                treeData={filteredTree}
                onSelect={handleSelectNode}
                selectedKeys={selectedNode ? [selectedNode.id] : []}
                defaultExpandAll
                showLine
                blockNode
                style={{ background: 'transparent' }}
              />
            )}
          </Card>
        </Col>

        {/* Right: Detail form */}
        <Col xs={24} lg={14}>
          <Card
            variant="borderless"
            style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)', minHeight: 500 }}
            title={
              <span style={{ fontWeight: 600, color: '#1B3A5C' }}>
                {selectedNode ? `Chi tiết: ${selectedNode.name}` : 'Chi tiết chức năng'}
              </span>
            }
            extra={
              selectedNode && (
                <Space>
                  <Tooltip title="Thêm con">
                    <Button size="small" icon={<PlusCircleOutlined />} onClick={handleAddChild} style={{ borderRadius: 6 }}>
                      Thêm con
                    </Button>
                  </Tooltip>
                  <Button type="primary" icon={<SaveOutlined />} loading={saving} onClick={handleSave} style={{ borderRadius: 6 }}>
                    Lưu
                  </Button>
                  <Popconfirm
                    title="Xác nhận xóa"
                    description="Bạn có chắc chắn muốn xóa chức năng này?"
                    onConfirm={handleDelete}
                    okText="Xóa"
                    cancelText="Hủy"
                    okButtonProps={{ danger: true }}
                  >
                    <Button danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>
                      Xóa
                    </Button>
                  </Popconfirm>
                </Space>
              )
            }
          >
            {!selectedNode ? (
              <div style={{ textAlign: 'center', padding: '60px 0' }}>
                <Empty description="Chọn một chức năng từ cây bên trái để xem chi tiết" />
              </div>
            ) : (
              <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit">
                <Row gutter={16}>
                  <Col span={12}>
                    <Form.Item label="Tên chức năng" name="name" rules={[{ required: true, message: 'Nhập tên' }]}>
                      <Input maxLength={200} style={{ borderRadius: 8 }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item label="Tên menu" name="name_of_menu">
                      <Input maxLength={200} style={{ borderRadius: 8 }} />
                    </Form.Item>
                  </Col>
                </Row>

                <Row gutter={16}>
                  <Col span={12}>
                    <Form.Item label="URL (action_link)" name="action_link">
                      <Input placeholder="/quan-tri/..." maxLength={500} style={{ borderRadius: 8 }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item label="Icon" name="icon">
                      <Input placeholder="VD: SettingOutlined" maxLength={100} style={{ borderRadius: 8 }} />
                    </Form.Item>
                  </Col>
                </Row>

                <Form.Item label="Thứ tự" name="sort_order">
                  <InputNumber min={0} style={{ width: '100%', borderRadius: 8 }} />
                </Form.Item>

                <Row gutter={24}>
                  <Col span={8}>
                    <Form.Item label="Hiện trên menu" name="show_menu" valuePropName="checked">
                      <Switch />
                    </Form.Item>
                  </Col>
                  <Col span={8}>
                    <Form.Item label="Trang mặc định" name="default_page" valuePropName="checked">
                      <Switch />
                    </Form.Item>
                  </Col>
                  <Col span={8}>
                    <Form.Item label="Hiện trên mobile" name="show_in_app" valuePropName="checked">
                      <Switch />
                    </Form.Item>
                  </Col>
                </Row>

                <Form.Item label="Mô tả" name="description">
                  <Input.TextArea rows={3} maxLength={500} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Form>
            )}
          </Card>
        </Col>
      </Row>
    </div>
  );
}
