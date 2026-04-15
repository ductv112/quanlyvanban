'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Card, Row, Col, Table, Button, Input, Tree, Space, Modal, Select,
  Skeleton, Tooltip, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, DeleteOutlined, SearchOutlined, ApartmentOutlined,
  ReloadOutlined, EditOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import type { TreeNode } from '@/types/tree';
import { filterTree } from '@/lib/tree-utils';

interface Signer {
  id: number;
  staff_id: number;
  staff_name: string;
  position_name: string;
  department_name: string;
}

interface StaffOption {
  id: number;
  full_name: string;
  position_name: string;
  department_name: string;
}

export default function SignerPage() {
  const { message } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const [loading, setLoading] = useState(false);
  const [treeData, setTreeData] = useState<TreeNode[]>([]);
  const [treeLoading, setTreeLoading] = useState(false);
  const [selectedDept, setSelectedDept] = useState<number | null>(null);
  const [signers, setSigners] = useState<Signer[]>([]);
  const [searchTree, setSearchTree] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [staffOptions, setStaffOptions] = useState<StaffOption[]>([]);
  const [staffLoading, setStaffLoading] = useState(false);
  const [selectedStaffId, setSelectedStaffId] = useState<number | null>(null);
  const [addingSigners, setAddingSigners] = useState(false);

  const mapTree = useCallback((nodes: any[]): TreeNode[] => {
    return nodes.map((n) => ({
      key: n.id,
      title: n.name,
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

  const fetchSigners = useCallback(async (departmentId?: number | null) => {
    if (!user?.unitId) return;
    setLoading(true);
    try {
      const params: any = { unit_id: user.unitId };
      if (departmentId) params.department_id = departmentId;
      const { data: res } = await api.get('/quan-tri/nguoi-ky', { params });
      setSigners(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách người ký');
    } finally {
      setLoading(false);
    }
  }, [user?.unitId, message]);

  useEffect(() => {
    fetchTree();
    fetchSigners();
  }, [fetchTree, fetchSigners]);

  const handleSelectNode = (keys: any) => {
    const id = keys?.[0] ?? null;
    setSelectedDept(id);
    fetchSigners(id);
  };

  const fetchStaff = useCallback(async () => {
    if (!user?.unitId) return;
    setStaffLoading(true);
    try {
      const params: any = { unit_id: user.unitId };
      if (selectedDept) params.department_id = selectedDept;
      const { data: res } = await api.get('/quan-tri/nguoi-dung', { params });
      setStaffOptions(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách nhân viên');
    } finally {
      setStaffLoading(false);
    }
  }, [user?.unitId, selectedDept, message]);

  const handleOpenAddModal = () => {
    setSelectedStaffId(null);
    setModalOpen(true);
    fetchStaff();
  };

  const handleAddSigner = async () => {
    if (!selectedStaffId) {
      message.warning('Vui lòng chọn nhân viên');
      return;
    }
    setAddingSigners(true);
    try {
      await api.post('/quan-tri/nguoi-ky', { staff_id: selectedStaffId });
      message.success('Thêm người ký thành công');
      setModalOpen(false);
      fetchSigners(selectedDept);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi thêm người ký');
    } finally {
      setAddingSigners(false);
    }
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/quan-tri/nguoi-ky/${id}`);
      message.success('Xóa người ký thành công');
      fetchSigners(selectedDept);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const filteredTree = useMemo(() => filterTree(treeData, searchTree), [treeData, searchTree]);

  const columns: ColumnsType<Signer> = [
    {
      title: 'Họ tên',
      dataIndex: 'staff_name',
      key: 'staff_name',
      ellipsis: true,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Chức vụ',
      dataIndex: 'position_name',
      key: 'position_name',
      width: 200,
    },
    {
      title: 'Phòng ban',
      dataIndex: 'department_name',
      key: 'department_name',
      width: 200,
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: 80,
      align: 'center',
      render: (_, record) => (
        <Button
          type="text"
          size="small"
          danger
          icon={<DeleteOutlined />}
          onClick={() => {
            Modal.confirm({
              title: 'Xác nhận xóa',
              content: `Bạn có chắc chắn muốn xóa người ký "${record.staff_name}"?`,
              okText: 'Xóa',
              cancelText: 'Hủy',
              okButtonProps: { danger: true },
              onOk: () => handleDelete(record.id),
            });
          }}
        />
      ),
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Quản lý người ký
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Quản lý danh sách người có quyền ký văn bản
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
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Phòng ban</span>
              </div>
            }
            extra={
              <Tooltip title="Tải lại">
                <Button type="text" size="small" icon={<ReloadOutlined />} onClick={fetchTree} />
              </Tooltip>
            }
          >
            <Input
              placeholder="Tìm kiếm phòng ban..."
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
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <EditOutlined style={{ color: '#0891B2' }} />
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách người ký</span>
              </div>
            }
            extra={
              <Button
                type="primary"
                icon={<PlusOutlined />}
                onClick={handleOpenAddModal}
                style={{ borderRadius: 8 }}
              >
                Thêm người ký
              </Button>
            }
          >
            <Table
              columns={columns}
              dataSource={signers}
              rowKey="id"
              loading={loading}
              pagination={false}
              size="middle"
              sticky
              scroll={{ x: 500 }}
            />
          </Card>
        </Col>
      </Row>

      {/* Modal add signer */}
      <Modal
        title="Thêm người ký"
        open={modalOpen}
        onCancel={() => setModalOpen(false)}
        onOk={handleAddSigner}
        okText="Thêm"
        cancelText="Hủy"
        confirmLoading={addingSigners}
        destroyOnHidden
      >
        <div style={{ marginBottom: 8, color: '#64748b', fontSize: 13 }}>
          Chọn nhân viên để thêm vào danh sách người ký
        </div>
        <Select
          placeholder="Tìm và chọn nhân viên..."
          showSearch
          loading={staffLoading}
          value={selectedStaffId}
          onChange={(v) => setSelectedStaffId(v)}
          filterOption={(input, option) =>
            (option?.label as string ?? '').toLowerCase().includes(input.toLowerCase())
          }
          options={(staffOptions || []).map((s) => ({
            value: s.id,
            label: `${s.full_name} - ${s.position_name || ''} - ${s.department_name || ''}`,
          }))}
          style={{ width: '100%' }}
        />
      </Modal>
    </div>
  );
}
