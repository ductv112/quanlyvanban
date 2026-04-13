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
  menu_name: string;
  action_link: string;
  icon: string;
  sort_order: number;
  show_on_menu: boolean;
  is_default: boolean;
  show_on_mobile: boolean;
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

  const fetchTree = useCallback(async () => {
    setTreeLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/chuc-nang/tree');
      setTreeData(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Loi tai du lieu');
    } finally {
      setTreeLoading(false);
    }
  }, [message]);

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

  const handleSave = async () => {
    if (!selectedNode) return;
    try {
      const values = await form.validateFields();
      setSaving(true);
      await api.put(`/quan-tri/chuc-nang/${selectedNode.id}`, {
        ...values,
        parent_id: selectedNode.parent_id,
      });
      message.success('Cap nhat thanh cong');
      fetchTree();
    } catch (err: any) {
      if (err?.response) {
        message.error(err?.response?.data?.message || 'Loi khi luu');
      }
    } finally {
      setSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!selectedNode) return;
    try {
      await api.delete(`/quan-tri/chuc-nang/${selectedNode.id}`);
      message.success('Xoa thanh cong');
      setSelectedNode(null);
      form.resetFields();
      fetchTree();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Loi khi xoa');
    }
  };

  const handleAddRoot = async () => {
    try {
      await api.post('/quan-tri/chuc-nang', {
        name: 'Chuc nang moi',
        menu_name: 'Menu moi',
        parent_id: null,
        sort_order: 0,
      });
      message.success('Them chuc nang goc thanh cong');
      fetchTree();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Loi khi them');
    }
  };

  const handleAddChild = async () => {
    if (!selectedNode) return;
    try {
      await api.post('/quan-tri/chuc-nang', {
        name: 'Chuc nang con moi',
        menu_name: 'Menu con',
        parent_id: selectedNode.id,
        sort_order: 0,
      });
      message.success('Them chuc nang con thanh cong');
      fetchTree();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Loi khi them');
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
          Quan ly chuc nang
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Quan ly cay chuc nang va menu he thong
        </p>
      </div>

      <Row gutter={16}>
        {/* Left: Tree */}
        <Col xs={24} lg={10}>
          <Card
            bordered={false}
            style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)', minHeight: 500 }}
            title={
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <AppstoreOutlined style={{ color: '#0891B2' }} />
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Cay chuc nang</span>
              </div>
            }
            extra={
              <Space>
                <Tooltip title="Them goc">
                  <Button type="primary" size="small" icon={<PlusOutlined />} onClick={handleAddRoot} style={{ borderRadius: 6 }}>
                    Them goc
                  </Button>
                </Tooltip>
                <Tooltip title="Tai lai">
                  <Button type="text" size="small" icon={<ReloadOutlined />} onClick={fetchTree} />
                </Tooltip>
              </Space>
            }
          >
            <Input
              placeholder="Tim kiem chuc nang..."
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
            bordered={false}
            style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)', minHeight: 500 }}
            title={
              <span style={{ fontWeight: 600, color: '#1B3A5C' }}>
                {selectedNode ? `Chi tiet: ${selectedNode.name}` : 'Chi tiet chuc nang'}
              </span>
            }
            extra={
              selectedNode && (
                <Space>
                  <Tooltip title="Them con">
                    <Button size="small" icon={<PlusCircleOutlined />} onClick={handleAddChild} style={{ borderRadius: 6 }}>
                      Them con
                    </Button>
                  </Tooltip>
                  <Button type="primary" icon={<SaveOutlined />} loading={saving} onClick={handleSave} style={{ borderRadius: 6 }}>
                    Luu
                  </Button>
                  <Popconfirm
                    title="Xac nhan xoa"
                    description="Ban co chac chan muon xoa chuc nang nay?"
                    onConfirm={handleDelete}
                    okText="Xoa"
                    cancelText="Huy"
                    okButtonProps={{ danger: true }}
                  >
                    <Button danger icon={<DeleteOutlined />} style={{ borderRadius: 6 }}>
                      Xoa
                    </Button>
                  </Popconfirm>
                </Space>
              )
            }
          >
            {!selectedNode ? (
              <div style={{ textAlign: 'center', padding: '60px 0' }}>
                <Empty description="Chon mot chuc nang tu cay ben trai de xem chi tiet" />
              </div>
            ) : (
              <Form form={form} layout="vertical" autoComplete="off">
                <Row gutter={16}>
                  <Col span={12}>
                    <Form.Item label="Ten chuc nang" name="name" rules={[{ required: true, message: 'Nhap ten' }]}>
                      <Input style={{ borderRadius: 8 }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item label="Ten menu" name="menu_name">
                      <Input style={{ borderRadius: 8 }} />
                    </Form.Item>
                  </Col>
                </Row>

                <Row gutter={16}>
                  <Col span={12}>
                    <Form.Item label="URL (action_link)" name="action_link">
                      <Input placeholder="/quan-tri/..." style={{ borderRadius: 8 }} />
                    </Form.Item>
                  </Col>
                  <Col span={12}>
                    <Form.Item label="Icon" name="icon">
                      <Input placeholder="VD: SettingOutlined" style={{ borderRadius: 8 }} />
                    </Form.Item>
                  </Col>
                </Row>

                <Form.Item label="Thu tu" name="sort_order">
                  <InputNumber min={0} style={{ width: '100%', borderRadius: 8 }} />
                </Form.Item>

                <Row gutter={24}>
                  <Col span={8}>
                    <Form.Item label="Hien tren menu" name="show_on_menu" valuePropName="checked">
                      <Switch />
                    </Form.Item>
                  </Col>
                  <Col span={8}>
                    <Form.Item label="Trang mac dinh" name="is_default" valuePropName="checked">
                      <Switch />
                    </Form.Item>
                  </Col>
                  <Col span={8}>
                    <Form.Item label="Hien tren mobile" name="show_on_mobile" valuePropName="checked">
                      <Switch />
                    </Form.Item>
                  </Col>
                </Row>

                <Form.Item label="Mo ta" name="description">
                  <Input.TextArea rows={3} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Form>
            )}
          </Card>
        </Col>
      </Row>
    </div>
  );
}
