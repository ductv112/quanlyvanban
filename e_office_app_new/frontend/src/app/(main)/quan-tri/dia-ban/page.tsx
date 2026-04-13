'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Space, Drawer, Form, Input, Switch,
  Tag, Dropdown, Modal, App, Row, Col,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, MoreOutlined,
  EnvironmentOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';

interface Province {
  id: number;
  code: string;
  name: string;
  is_active: boolean;
}

interface District {
  id: number;
  code: string;
  name: string;
  province_id: number;
  is_active: boolean;
}

interface Ward {
  id: number;
  code: string;
  name: string;
  district_id: number;
  is_active: boolean;
}

type LevelType = 'province' | 'district' | 'ward';

const LEVEL_LABELS: Record<LevelType, { title: string; singular: string; deleteMsg: string }> = {
  province: { title: 'Tỉnh / Thành phố', singular: 'tỉnh/TP', deleteMsg: 'Bạn có chắc chắn muốn xóa tỉnh/TP này?' },
  district: { title: 'Huyện / Quận', singular: 'huyện/quận', deleteMsg: 'Bạn có chắc chắn muốn xóa huyện/quận này?' },
  ward: { title: 'Xã / Phường', singular: 'xã/phường', deleteMsg: 'Bạn có chắc chắn muốn xóa xã/phường này?' },
};

export default function AddressPage() {
  const { message } = App.useApp();

  // Province state
  const [provinces, setProvinces] = useState<Province[]>([]);
  const [loadingProvinces, setLoadingProvinces] = useState(false);
  const [selectedProvinceId, setSelectedProvinceId] = useState<number | null>(null);

  // District state
  const [districts, setDistricts] = useState<District[]>([]);
  const [loadingDistricts, setLoadingDistricts] = useState(false);
  const [selectedDistrictId, setSelectedDistrictId] = useState<number | null>(null);

  // Ward state
  const [wards, setWards] = useState<Ward[]>([]);
  const [loadingWards, setLoadingWards] = useState(false);

  // Drawer state
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [drawerLevel, setDrawerLevel] = useState<LevelType>('province');
  const [editingRecord, setEditingRecord] = useState<Province | District | Ward | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  const fetchProvinces = useCallback(async () => {
    setLoadingProvinces(true);
    try {
      const { data: res } = await api.get('/quan-tri/dia-ban/tinh');
      setProvinces(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách tỉnh/TP');
    } finally {
      setLoadingProvinces(false);
    }
  }, [message]);

  const fetchDistricts = useCallback(async (provinceId: number) => {
    setLoadingDistricts(true);
    try {
      const { data: res } = await api.get('/quan-tri/dia-ban/huyen', {
        params: { province_id: provinceId },
      });
      setDistricts(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách huyện/quận');
    } finally {
      setLoadingDistricts(false);
    }
  }, [message]);

  const fetchWards = useCallback(async (districtId: number) => {
    setLoadingWards(true);
    try {
      const { data: res } = await api.get('/quan-tri/dia-ban/xa', {
        params: { district_id: districtId },
      });
      setWards(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách xã/phường');
    } finally {
      setLoadingWards(false);
    }
  }, [message]);

  useEffect(() => {
    fetchProvinces();
  }, [fetchProvinces]);

  useEffect(() => {
    if (selectedProvinceId) {
      fetchDistricts(selectedProvinceId);
      setSelectedDistrictId(null);
      setWards([]);
    } else {
      setDistricts([]);
      setSelectedDistrictId(null);
      setWards([]);
    }
  }, [selectedProvinceId, fetchDistricts]);

  useEffect(() => {
    if (selectedDistrictId) {
      fetchWards(selectedDistrictId);
    } else {
      setWards([]);
    }
  }, [selectedDistrictId, fetchWards]);

  const getApiPath = (level: LevelType) => {
    switch (level) {
      case 'province': return '/quan-tri/dia-ban/tinh';
      case 'district': return '/quan-tri/dia-ban/huyen';
      case 'ward': return '/quan-tri/dia-ban/xa';
    }
  };

  const handleAdd = (level: LevelType) => {
    setDrawerLevel(level);
    setEditingRecord(null);
    form.resetFields();
    form.setFieldsValue({ is_active: true });
    setDrawerOpen(true);
  };

  const handleEdit = (level: LevelType, record: Province | District | Ward) => {
    setDrawerLevel(level);
    setEditingRecord(record);
    form.setFieldsValue(record);
    setDrawerOpen(true);
  };

  const handleDelete = async (level: LevelType, id: number) => {
    try {
      await api.delete(`${getApiPath(level)}/${id}`);
      message.success('Xóa thành công');
      if (level === 'province') {
        fetchProvinces();
        if (selectedProvinceId === id) {
          setSelectedProvinceId(null);
        }
      } else if (level === 'district') {
        if (selectedProvinceId) fetchDistricts(selectedProvinceId);
        if (selectedDistrictId === id) {
          setSelectedDistrictId(null);
        }
      } else {
        if (selectedDistrictId) fetchWards(selectedDistrictId);
      }
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      // Province (route + SP)
      'Tên tỉnh/thành phố là bắt buộc': 'name',
      'Tên tỉnh/thành không được để trống': 'name',
      'Tên tỉnh/thành phố không được vượt quá 200 ký tự': 'name',
      'Mã tỉnh/thành phố là bắt buộc': 'code',
      'Mã tỉnh/thành không được vượt quá 10 ký tự': 'code',
      'Mã tỉnh/thành phố không được vượt quá 20 ký tự': 'code',
      'Mã tỉnh/thành đã tồn tại': 'code',
      // District (route + SP)
      'Tỉnh/thành phố là bắt buộc': 'province_id',
      'Tỉnh/thành không tồn tại': 'province_id',
      'Tên quận/huyện là bắt buộc': 'name',
      'Tên quận/huyện không được để trống': 'name',
      'Tên quận/huyện không được vượt quá 200 ký tự': 'name',
      'Mã quận/huyện là bắt buộc': 'code',
      'Mã quận/huyện không được vượt quá 10 ký tự': 'code',
      'Mã quận/huyện không được vượt quá 20 ký tự': 'code',
      'Mã quận/huyện đã tồn tại trong tỉnh/thành': 'code',
      // Commune (route + SP)
      'Quận/huyện là bắt buộc': 'district_id',
      'Quận/huyện không tồn tại': 'district_id',
      'Tên xã/phường là bắt buộc': 'name',
      'Tên phường/xã không được để trống': 'name',
      'Tên xã/phường không được vượt quá 200 ký tự': 'name',
      'Mã xã/phường là bắt buộc': 'code',
      'Mã phường/xã không được vượt quá 10 ký tự': 'code',
      'Mã xã/phường không được vượt quá 20 ký tự': 'code',
      'Mã phường/xã đã tồn tại trong quận/huyện': 'code',
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
      const basePath = getApiPath(drawerLevel);

      if (drawerLevel === 'district') {
        values.province_id = selectedProvinceId;
      } else if (drawerLevel === 'ward') {
        values.district_id = selectedDistrictId;
      }

      if (editingRecord) {
        await api.put(`${basePath}/${editingRecord.id}`, values);
        message.success('Cập nhật thành công');
      } else {
        await api.post(basePath, values);
        message.success('Thêm thành công');
      }
      setDrawerOpen(false);

      if (drawerLevel === 'province') fetchProvinces();
      else if (drawerLevel === 'district' && selectedProvinceId) fetchDistricts(selectedProvinceId);
      else if (drawerLevel === 'ward' && selectedDistrictId) fetchWards(selectedDistrictId);
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

  const makeColumns = (level: LevelType): ColumnsType<any> => [
    {
      title: 'Mã',
      dataIndex: 'code',
      key: 'code',
      width: 80,
      render: (v: string) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Tên',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
    },
    {
      title: 'Trạng thái',
      dataIndex: 'is_active',
      key: 'is_active',
      width: 100,
      render: (v: boolean) => (
        <Tag color={v ? 'success' : 'error'}>{v ? 'Hoạt động' : 'Ngừng'}</Tag>
      ),
    },
    {
      title: '',
      key: 'actions',
      width: 50,
      align: 'center',
      render: (_: any, record: any) => (
        <Dropdown
          trigger={['click']}
          menu={{
            items: [
              {
                key: 'edit',
                icon: <EditOutlined />,
                label: 'Sửa thông tin',
                onClick: () => handleEdit(level, record),
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
                    content: LEVEL_LABELS[level].deleteMsg,
                    okText: 'Xóa',
                    cancelText: 'Hủy',
                    okButtonProps: { danger: true },
                    onOk: () => handleDelete(level, record.id),
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

  const tableStyle: React.CSSProperties = { minHeight: 400 };

  const renderLevelTable = (
    level: LevelType,
    data: any[],
    loading: boolean,
    selectedId: number | null,
    onRowClick?: (id: number) => void,
    disableAdd?: boolean,
  ) => (
    <Card
      variant="borderless"
      size="small"
      style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)', height: '100%' }}
      title={
        <span style={{ fontWeight: 600, color: '#1B3A5C', fontSize: 14 }}>
          {LEVEL_LABELS[level].title}
        </span>
      }
      extra={
        <Button
          type="primary"
          size="small"
          icon={<PlusOutlined />}
          onClick={() => handleAdd(level)}
          disabled={disableAdd}
          style={{ borderRadius: 8 }}
        >
          Thêm
        </Button>
      }
    >
      <Table
        columns={makeColumns(level)}
        dataSource={data}
        rowKey="id"
        loading={loading}
        size="small"
        style={tableStyle}
        scroll={{ x: 300 }}
        pagination={false}
        onRow={(record) => ({
          onClick: () => onRowClick?.(record.id),
          style: {
            cursor: onRowClick ? 'pointer' : 'default',
            background: selectedId === record.id ? '#e6f4ff' : undefined,
          },
        })}
      />
    </Card>
  );

  const drawerTitle = editingRecord
    ? `Cập nhật ${LEVEL_LABELS[drawerLevel].singular}`
    : `Thêm ${LEVEL_LABELS[drawerLevel].singular} mới`;

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Quản lý địa bàn
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Danh mục địa bàn hành chính: Tỉnh/TP, Huyện/Quận, Xã/Phường
        </p>
      </div>

      <Row gutter={[16, 16]}>
        <Col xs={24} md={8}>
          {renderLevelTable('province', provinces, loadingProvinces, selectedProvinceId, (id) => setSelectedProvinceId(id))}
        </Col>
        <Col xs={24} md={8}>
          {renderLevelTable('district', districts, loadingDistricts, selectedDistrictId, (id) => setSelectedDistrictId(id), !selectedProvinceId)}
        </Col>
        <Col xs={24} md={8}>
          {renderLevelTable('ward', wards, loadingWards, null, undefined, !selectedDistrictId)}
        </Col>
      </Row>

      <Drawer
        title={<span style={{ color: '#fff', fontWeight: 600 }}>{drawerTitle}</span>}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        destroyOnClose
        styles={{
          wrapper: { width: 720 },
          header: {
            background: 'linear-gradient(135deg, #1B3A5C 0%, #0891B2 100%)',
            borderBottom: 'none',
            padding: '16px 24px',
          },
          body: { padding: 24 },
        }}
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)} style={{ borderRadius: 8, borderColor: 'rgba(255,255,255,0.5)', color: '#fff' }} ghost>Hủy</Button>
            <Button type="primary" loading={saving} onClick={handleSave} style={{ borderRadius: 8, background: '#fff', color: '#1B3A5C', borderColor: '#fff', fontWeight: 600 }}>
              {editingRecord ? 'Cập nhật' : 'Thêm mới'}
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit">
          <Form.Item label="Mã" name="code" rules={[{ required: true, message: 'Nhập mã' }]}>
            <Input placeholder="VD: 01" maxLength={10} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Tên" name="name" rules={[{ required: true, message: 'Nhập tên' }]}>
            <Input placeholder="VD: Hà Nội" maxLength={100} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Trạng thái" name="is_active" valuePropName="checked" initialValue={true}>
            <Switch checkedChildren="Hoạt động" unCheckedChildren="Ngừng" />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
