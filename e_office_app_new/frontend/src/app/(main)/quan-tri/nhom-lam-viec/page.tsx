'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Drawer, Form, InputNumber,
  Dropdown, Modal, Select, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined, TeamOutlined,
  MoreOutlined, UserAddOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';

interface WorkGroup {
  id: number;
  name: string;
  description: string;
  sort_order: number;
  member_count: number;
}

interface Member {
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

export default function WorkGroupPage() {
  const { message } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<WorkGroup[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [keyword, setKeyword] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<WorkGroup | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  // Member management state
  const [memberDrawerOpen, setMemberDrawerOpen] = useState(false);
  const [currentGroup, setCurrentGroup] = useState<WorkGroup | null>(null);
  const [members, setMembers] = useState<Member[]>([]);
  const [membersLoading, setMembersLoading] = useState(false);
  const [addMemberModalOpen, setAddMemberModalOpen] = useState(false);
  const [staffOptions, setStaffOptions] = useState<StaffOption[]>([]);
  const [staffLoading, setStaffLoading] = useState(false);
  const [selectedStaffIds, setSelectedStaffIds] = useState<number[]>([]);
  const [addingMembers, setAddingMembers] = useState(false);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/nhom-lam-viec', {
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
    form.setFieldsValue({ sort_order: 0 });
    setDrawerOpen(true);
  };

  const handleEdit = (record: WorkGroup) => {
    setEditingRecord(record);
    form.setFieldsValue(record);
    setDrawerOpen(true);
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/quan-tri/nhom-lam-viec/${id}`);
      message.success('Xóa nhóm làm việc thành công');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Tên nhóm làm việc là bắt buộc': 'name',
      'Tên nhóm không được để trống': 'name',
      'Tên nhóm làm việc không được vượt quá 200 ký tự': 'name',
      'Tên nhóm không được vượt quá 200 ký tự': 'name',
      'Tên nhóm đã tồn tại trong đơn vị': 'name',
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
        await api.put(`/quan-tri/nhom-lam-viec/${editingRecord.id}`, values);
        message.success('Cập nhật thành công');
      } else {
        await api.post('/quan-tri/nhom-lam-viec', values);
        message.success('Thêm nhóm làm việc thành công');
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

  const handleSearch = (value: string) => {
    setKeyword(value);
    setPage(1);
  };

  // Member management
  const fetchMembers = useCallback(async (groupId: number) => {
    setMembersLoading(true);
    try {
      const { data: res } = await api.get(`/quan-tri/nhom-lam-viec/${groupId}/thanh-vien`);
      setMembers(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách thành viên');
    } finally {
      setMembersLoading(false);
    }
  }, [message]);

  const handleManageMembers = (record: WorkGroup) => {
    setCurrentGroup(record);
    setMemberDrawerOpen(true);
    fetchMembers(record.id);
  };

  const fetchStaff = useCallback(async () => {
    if (!user?.unitId) return;
    setStaffLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/nguoi-dung', {
        params: { unit_id: user.unitId },
      });
      setStaffOptions(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách nhân viên');
    } finally {
      setStaffLoading(false);
    }
  }, [user?.unitId, message]);

  const handleOpenAddMemberModal = () => {
    setSelectedStaffIds([]);
    setAddMemberModalOpen(true);
    fetchStaff();
  };

  const handleAddMembers = async () => {
    if (!currentGroup || selectedStaffIds.length === 0) {
      message.warning('Vui lòng chọn ít nhất một nhân viên');
      return;
    }
    setAddingMembers(true);
    try {
      await api.post(`/quan-tri/nhom-lam-viec/${currentGroup.id}/thanh-vien`, {
        staff_ids: selectedStaffIds,
      });
      message.success('Thêm thành viên thành công');
      setAddMemberModalOpen(false);
      fetchMembers(currentGroup.id);
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi thêm thành viên');
    } finally {
      setAddingMembers(false);
    }
  };

  const handleRemoveMember = async (memberId: number) => {
    if (!currentGroup) return;
    try {
      await api.delete(`/quan-tri/nhom-lam-viec/${currentGroup.id}/thanh-vien/${memberId}`);
      message.success('Xóa thành viên thành công');
      fetchMembers(currentGroup.id);
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa thành viên');
    }
  };

  const columns: ColumnsType<WorkGroup> = [
    {
      title: 'Tên nhóm',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Chức năng',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
    },
    {
      title: 'Thứ tự',
      dataIndex: 'sort_order',
      key: 'sort_order',
      width: 90,
      align: 'center',
    },
    {
      title: 'Số thành viên',
      dataIndex: 'member_count',
      key: 'member_count',
      width: 120,
      align: 'center',
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
                label: 'Sửa',
                onClick: () => handleEdit(record),
              },
              {
                key: 'members',
                icon: <TeamOutlined />,
                label: 'Quản lý thành viên',
                onClick: () => handleManageMembers(record),
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
                    content: `Bạn có chắc chắn muốn xóa nhóm "${record.name}"?`,
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

  const memberColumns: ColumnsType<Member> = [
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
      width: 180,
    },
    {
      title: 'Phòng ban',
      dataIndex: 'department_name',
      key: 'department_name',
      width: 180,
    },
    {
      title: '',
      key: 'actions',
      width: 60,
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
              content: `Xóa "${record.staff_name}" khỏi nhóm?`,
              okText: 'Xóa',
              cancelText: 'Hủy',
              okButtonProps: { danger: true },
              onOk: () => handleRemoveMember(record.id),
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
          Quản lý nhóm làm việc
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Tạo và quản lý các nhóm làm việc trong đơn vị
        </p>
      </div>

      <Card
        variant="borderless"
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <TeamOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách nhóm làm việc</span>
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
            <Button
              type="primary"
              icon={<PlusOutlined />}
              onClick={handleAdd}
              style={{ borderRadius: 8 }}
            >
              Thêm nhóm
            </Button>
          </Space>
        }
      >
        <Table
          columns={columns}
          dataSource={data}
          rowKey="id"
          loading={loading}
          size="middle"
          sticky
          scroll={{ x: 600 }}
          pagination={{
            current: page,
            pageSize,
            total,
            showSizeChanger: true,
            showTotal: (t) => `Tổng ${t}`,
            onChange: (p, ps) => {
              setPage(p);
              setPageSize(ps);
            },
          }}
        />
      </Card>

      {/* Drawer add/edit group */}
      <Drawer
        title={editingRecord ? 'Cập nhật nhóm làm việc' : 'Thêm nhóm làm việc mới'}
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
          <Form.Item
            label="Tên nhóm"
            name="name"
            rules={[{ required: true, message: 'Nhập tên nhóm làm việc' }]}
          >
            <Input placeholder="VD: Nhóm xử lý văn bản" maxLength={200} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Chức năng" name="description">
            <Input.TextArea rows={3} placeholder="Mô tả chức năng của nhóm" maxLength={500} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Thứ tự" name="sort_order" initialValue={0}>
            <InputNumber min={0} style={{ width: '100%', borderRadius: 8 }} />
          </Form.Item>
        </Form>
      </Drawer>

      {/* Drawer manage members */}
      <Drawer
        title={<>Quản lý thành viên — {currentGroup?.name}</>}
        open={memberDrawerOpen}
        onClose={() => setMemberDrawerOpen(false)}
        destroyOnHidden
        rootClassName="drawer-gradient"
        size={720}
        extra={
          <Button
            type="primary"
            icon={<UserAddOutlined />}
            onClick={handleOpenAddMemberModal}
          >
            Thêm thành viên
          </Button>
        }
      >
        <Table
          columns={memberColumns}
          dataSource={members}
          rowKey="id"
          loading={membersLoading}
          pagination={false}
          size="middle"
          scroll={{ x: 400 }}
        />
      </Drawer>

      {/* Modal add members */}
      <Modal
        title="Thêm thành viên vào nhóm"
        open={addMemberModalOpen}
        onCancel={() => setAddMemberModalOpen(false)}
        onOk={handleAddMembers}
        okText="Thêm"
        cancelText="Hủy"
        confirmLoading={addingMembers}
        destroyOnHidden
      >
        <div style={{ marginBottom: 8, color: '#64748b', fontSize: 13 }}>
          Chọn nhân viên để thêm vào nhóm làm việc
        </div>
        <Select
          mode="multiple"
          placeholder="Tìm và chọn nhân viên..."
          showSearch
          loading={staffLoading}
          value={selectedStaffIds}
          onChange={(v) => setSelectedStaffIds(v)}
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
