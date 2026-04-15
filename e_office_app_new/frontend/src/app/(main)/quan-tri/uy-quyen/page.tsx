'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Drawer, Form, Select, DatePicker,
  Tag, Dropdown, Modal, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, DeleteOutlined, SearchOutlined, SafetyCertificateOutlined,
  MoreOutlined, StopOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import dayjs from 'dayjs';

interface Delegation {
  id: number;
  delegator_name: string;
  delegator_id: number;
  delegate_name: string;
  delegate_id: number;
  start_date: string;
  end_date: string;
  note: string;
  is_revoked: boolean;
}

interface StaffOption {
  id: number;
  full_name: string;
  position_name: string;
  department_name: string;
}

export default function DelegationPage() {
  const { message } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<Delegation[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [keyword, setKeyword] = useState('');
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();
  const [staffOptions, setStaffOptions] = useState<StaffOption[]>([]);
  const [staffLoading, setStaffLoading] = useState(false);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/uy-quyen', {
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

  const getStatus = (record: Delegation): { label: string; color: string } => {
    if (record.is_revoked) {
      return { label: 'Đã thu hồi', color: 'default' };
    }
    if (record.end_date && dayjs(record.end_date).isBefore(dayjs(), 'day')) {
      return { label: 'Hết hạn', color: 'warning' };
    }
    return { label: 'Đang hiệu lực', color: 'success' };
  };

  const isActive = (record: Delegation): boolean => {
    return !record.is_revoked && !(record.end_date && dayjs(record.end_date).isBefore(dayjs(), 'day'));
  };

  const handleAdd = () => {
    form.resetFields();
    setDrawerOpen(true);
    fetchStaff();
  };

  const handleRevoke = async (id: number) => {
    try {
      await api.patch(`/quan-tri/uy-quyen/${id}/thu-hoi`);
      message.success('Thu hồi ủy quyền thành công');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi thu hồi');
    }
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Người ủy quyền là bắt buộc': 'delegator_id',
      'Vui lòng chọn người ủy quyền và người nhận ủy quyền': 'delegator_id',
      'Người ủy quyền không tồn tại': 'delegator_id',
      'Người được ủy quyền là bắt buộc': 'delegate_id',
      'Không thể ủy quyền cho chính mình': 'delegate_id',
      'Người nhận ủy quyền không tồn tại': 'delegate_id',
      'Ngày bắt đầu là bắt buộc': 'start_date',
      'Ngày bắt đầu và ngày kết thúc không được để trống': 'start_date',
      'Đã tồn tại ủy quyền trong khoảng thời gian này': 'start_date',
      'Ngày kết thúc là bắt buộc': 'end_date',
      'Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu': 'end_date',
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
        start_date: values.start_date ? values.start_date.format('YYYY-MM-DD') : null,
        end_date: values.end_date ? values.end_date.format('YYYY-MM-DD') : null,
      };
      await api.post('/quan-tri/uy-quyen', payload);
      message.success('Thêm ủy quyền thành công');
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

  const columns: ColumnsType<Delegation> = [
    {
      title: 'Người ủy quyền',
      dataIndex: 'delegator_name',
      key: 'delegator_name',
      ellipsis: true,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Người được UQ',
      dataIndex: 'delegate_name',
      key: 'delegate_name',
      ellipsis: true,
    },
    {
      title: 'Từ ngày',
      dataIndex: 'start_date',
      key: 'start_date',
      width: 120,
      render: (v) => v ? dayjs(v).format('DD/MM/YYYY') : '',
    },
    {
      title: 'Đến ngày',
      dataIndex: 'end_date',
      key: 'end_date',
      width: 120,
      render: (v) => v ? dayjs(v).format('DD/MM/YYYY') : '',
    },
    {
      title: 'Ghi chú',
      dataIndex: 'note',
      key: 'note',
      ellipsis: true,
      width: 200,
    },
    {
      title: 'Trạng thái',
      key: 'status',
      width: 130,
      render: (_, record) => {
        const status = getStatus(record);
        return <Tag color={status.color}>{status.label}</Tag>;
      },
    },
    {
      title: '',
      key: 'actions',
      width: 50,
      align: 'center',
      fixed: 'right',
      render: (_, record) => {
        const active = isActive(record);
        if (!active) return null;
        return (
          <Dropdown
            trigger={['click']}
            menu={{
              items: [
                {
                  key: 'revoke',
                  icon: <StopOutlined />,
                  label: 'Thu hồi',
                  danger: true,
                  onClick: () => {
                    Modal.confirm({
                      title: 'Xác nhận thu hồi',
                      content: `Bạn có chắc chắn muốn thu hồi ủy quyền của "${record.delegator_name}" cho "${record.delegate_name}"?`,
                      okText: 'Thu hồi',
                      cancelText: 'Hủy',
                      okButtonProps: { danger: true },
                      onOk: () => handleRevoke(record.id),
                    });
                  },
                },
              ],
            }}
          >
            <Button type="text" size="small" icon={<MoreOutlined style={{ fontSize: 18 }} />} style={{ color: '#64748b' }} />
          </Dropdown>
        );
      },
    },
  ];

  const staffSelectOptions = (staffOptions || []).map((s) => ({
    value: s.id,
    label: `${s.full_name} - ${s.position_name || ''} - ${s.department_name || ''}`,
  }));

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Quản lý ủy quyền
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Quản lý việc ủy quyền xử lý văn bản giữa các cán bộ
        </p>
      </div>

      <Card
        variant="borderless"
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <SafetyCertificateOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Danh sách ủy quyền</span>
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
              Thêm ủy quyền
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
          scroll={{ x: 800 }}
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

      {/* Drawer add delegation */}
      <Drawer
        title="Thêm ủy quyền mới"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        destroyOnHidden
        rootClassName="drawer-gradient"
        size={720}
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)} ghost style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}>Hủy</Button>
            <Button type="primary" loading={saving} onClick={handleSave}>
              Thêm mới
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit">
          <Form.Item
            label="Người ủy quyền"
            name="delegator_id"
            rules={[{ required: true, message: 'Chọn người ủy quyền' }]}
          >
            <Select
              placeholder="Tìm và chọn người ủy quyền..."
              showSearch
              loading={staffLoading}
              filterOption={(input, option) =>
                (option?.label as string ?? '').toLowerCase().includes(input.toLowerCase())
              }
              options={staffSelectOptions}
              style={{ width: '100%' }}
            />
          </Form.Item>

          <Form.Item
            label="Người được ủy quyền"
            name="delegate_id"
            rules={[{ required: true, message: 'Chọn người được ủy quyền' }]}
          >
            <Select
              placeholder="Tìm và chọn người được ủy quyền..."
              showSearch
              loading={staffLoading}
              filterOption={(input, option) =>
                (option?.label as string ?? '').toLowerCase().includes(input.toLowerCase())
              }
              options={staffSelectOptions}
              style={{ width: '100%' }}
            />
          </Form.Item>

          <Form.Item
            label="Từ ngày"
            name="start_date"
            rules={[{ required: true, message: 'Chọn ngày bắt đầu' }]}
          >
            <DatePicker
              format="DD/MM/YYYY"
              placeholder="Chọn ngày bắt đầu"
              style={{ width: '100%', borderRadius: 8 }}
            />
          </Form.Item>

          <Form.Item
            label="Đến ngày"
            name="end_date"
            dependencies={['start_date']}
            rules={[
              { required: true, message: 'Chọn ngày kết thúc' },
              ({ getFieldValue }) => ({
                validator(_, value) {
                  const startDate = getFieldValue('start_date');
                  if (!value || !startDate) return Promise.resolve();
                  if (value.isAfter(startDate)) return Promise.resolve();
                  return Promise.reject(new Error('Ngày kết thúc phải sau ngày bắt đầu'));
                },
              }),
            ]}
          >
            <DatePicker
              format="DD/MM/YYYY"
              placeholder="Chọn ngày kết thúc"
              style={{ width: '100%', borderRadius: 8 }}
            />
          </Form.Item>

          <Form.Item label="Ghi chú" name="note">
            <Input.TextArea rows={3} placeholder="Nhập ghi chú" maxLength={500} style={{ borderRadius: 8 }} />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
