'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Select, DatePicker, Drawer,
  Form, InputNumber, Tag, Modal, App, Row, Col, Dropdown, Upload,
  Divider, Typography,
Card, } from 'antd';
import type { ColumnsType, TablePaginationConfig } from 'antd/es/table';
import type { UploadFile, RcFile } from 'antd/es/upload/interface';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, MoreOutlined,
  ReloadOutlined, EyeOutlined, UploadOutlined, DownloadOutlined,
  SettingOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

const { TextArea } = Input;

// ─────────────────── interfaces ───────────────────

interface ContractType {
  id: number;
  code: string;
  name: string;
  note: string;
  sort_order: number;
  is_locked?: boolean;
}

interface Contract {
  id: number;
  code: string;
  name: string;
  contract_type_id: number;
  type_name: string;
  contact_name: string;
  sign_date: string;
  input_date: string;
  receive_date: string;
  signer: string;
  amount?: string;
  payment_amount?: string;
  currency: string;
  note: string;
  staff_id: number;
  department_id: number;
  status: number;
  created_date: string;
  total_count: number;
}

interface Attachment {
  id: number;
  file_name: string;
  file_size: number;
  file_path: string;
  created_date: string;
}

const STATUS_MAP: Record<number, { label: string; color: string }> = {
  0: { label: 'Mới', color: 'default' },
  1: { label: 'Đang thực hiện', color: 'processing' },
  2: { label: 'Hoàn thành', color: 'success' },
  [-1]: { label: 'Hủy', color: 'error' },
};

function formatFileSize(bytes: number): string {
  if (!bytes || bytes === 0) return '0 B';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function formatCurrency(amount: string | number | null | undefined, currency = 'VND'): string {
  if (!amount) return '—';
  const num = typeof amount === 'string' ? parseFloat(amount.replace(/,/g, '')) : amount;
  if (isNaN(num)) return String(amount);
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency }).format(num);
}

// ─────────────────── component ───────────────────

export default function HopDongPage() {
  const { message } = App.useApp();

  // Contract types
  const [contractTypes, setContractTypes] = useState<ContractType[]>([]);
  const [typeDrawerOpen, setTypeDrawerOpen] = useState(false);
  const [editingType, setEditingType] = useState<ContractType | null>(null);
  const [typeSaving, setTypeSaving] = useState(false);
  const [typeForm] = Form.useForm();

  // Contract list
  const [loading, setLoading] = useState(false);
  const [contracts, setContracts] = useState<Contract[]>([]);
  const [filterTypeId, setFilterTypeId] = useState<number | undefined>();
  const [filterStatus, setFilterStatus] = useState<number | undefined>();
  const [keyword, setKeyword] = useState('');
  const [pagination, setPagination] = useState({ current: 1, pageSize: 20, total: 0 });

  // Contract drawer
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingContract, setEditingContract] = useState<Contract | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  // Contract detail / attachments
  const [detailDrawerOpen, setDetailDrawerOpen] = useState(false);
  const [selectedContract, setSelectedContract] = useState<Contract | null>(null);
  const [attachments, setAttachments] = useState<Attachment[]>([]);
  const [attachLoading, setAttachLoading] = useState(false);
  const [attachFileList, setAttachFileList] = useState<UploadFile[]>([]);
  const [attachUploading, setAttachUploading] = useState(false);

  // ─────────────────── fetch ───────────────────

  const fetchContractTypes = useCallback(async () => {
    try {
      const { data: res } = await api.get('/hop-dong/loai');
      setContractTypes(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách loại hợp đồng');
    }
  }, [message]);

  const fetchContracts = useCallback(async (
    page = pagination.current,
    pageSize = pagination.pageSize
  ) => {
    setLoading(true);
    try {
      const params: any = { page, page_size: pageSize };
      if (filterTypeId) params.contract_type_id = filterTypeId;
      if (filterStatus !== undefined) params.status = filterStatus;
      if (keyword) params.keyword = keyword;
      const { data: res } = await api.get('/hop-dong', { params });
      setContracts(res.data || []);
      const total = res.data?.[0]?.total_count ?? res.pagination?.total ?? 0;
      setPagination((p) => ({ ...p, current: page, pageSize, total }));
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách hợp đồng');
    } finally {
      setLoading(false);
    }
  }, [filterTypeId, filterStatus, keyword, pagination.current, pagination.pageSize, message]);

  const fetchAttachments = useCallback(async (contractId: number) => {
    setAttachLoading(true);
    try {
      const { data: res } = await api.get(`/hop-dong/${contractId}/dinh-kem`);
      setAttachments(res.data || []);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải đính kèm');
    } finally {
      setAttachLoading(false);
    }
  }, [message]);

  useEffect(() => {
    fetchContractTypes();
  }, [fetchContractTypes]);

  useEffect(() => {
    fetchContracts(1, pagination.pageSize);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [filterTypeId, filterStatus]);

  // ─────────────────── contract type CRUD ───────────────────

  const handleAddType = () => {
    setEditingType(null);
    typeForm.resetFields();
    setTypeDrawerOpen(true);
  };

  const handleEditType = (type: ContractType) => {
    setEditingType(type);
    typeForm.setFieldsValue({ ...type });
    setTypeDrawerOpen(true);
  };

  const handleDeleteType = (id: number) => {
    Modal.confirm({
      title: 'Xác nhận xóa loại hợp đồng',
      content: 'Bạn có chắc muốn xóa loại hợp đồng này?',
      okText: 'Xóa',
      okButtonProps: { danger: true },
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.delete(`/hop-dong/loai/${id}`);
          message.success('Xóa loại hợp đồng thành công');
          fetchContractTypes();
        } catch (err: any) {
          message.error(err?.response?.data?.message || 'Lỗi khi xóa');
        }
      },
    });
  };

  const setTypeBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Mã loại hợp đồng đã tồn tại': 'code',
    };
    const fieldName = fieldErrorMap[errorMessage];
    if (fieldName) {
      typeForm.setFields([{ name: fieldName, errors: [errorMessage] }]);
      return true;
    }
    return false;
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Tên hợp đồng là bắt buộc': 'name',
    };
    const fieldName = fieldErrorMap[errorMessage];
    if (fieldName) {
      form.setFields([{ name: fieldName, errors: [errorMessage] }]);
      return true;
    }
    return false;
  };

  const handleSaveType = async () => {
    try {
      const values = await typeForm.validateFields();
      setTypeSaving(true);
      if (editingType) {
        await api.put(`/hop-dong/loai/${editingType.id}`, values);
        message.success('Cập nhật loại hợp đồng thành công');
      } else {
        await api.post('/hop-dong/loai', values);
        message.success('Thêm loại hợp đồng thành công');
      }
      setEditingType(null);
      typeForm.resetFields();
      fetchContractTypes();
    } catch (err: any) {
      if (err?.errorFields) return;
      const msg = err?.response?.data?.message;
      if (msg && !setTypeBackendFieldError(msg)) message.error(msg);
    } finally {
      setTypeSaving(false);
    }
  };

  // ─────────────────── contract CRUD ───────────────────

  const handleAddContract = () => {
    setEditingContract(null);
    form.resetFields();
    form.setFieldsValue({ currency: 'VND', status: 0 });
    setDrawerOpen(true);
  };

  const handleEditContract = (contract: Contract) => {
    setEditingContract(contract);
    form.setFieldsValue({
      ...contract,
      sign_date: contract.sign_date ? dayjs(contract.sign_date) : null,
      input_date: contract.input_date ? dayjs(contract.input_date) : null,
      receive_date: contract.receive_date ? dayjs(contract.receive_date) : null,
    });
    setDrawerOpen(true);
  };

  const handleDeleteContract = (id: number) => {
    Modal.confirm({
      title: 'Xác nhận xóa hợp đồng',
      content: 'Bạn chỉ có thể xóa hợp đồng ở trạng thái "Mới". Bạn có chắc muốn xóa?',
      okText: 'Xóa',
      okButtonProps: { danger: true },
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.delete(`/hop-dong/${id}`);
          message.success('Xóa hợp đồng thành công');
          fetchContracts();
        } catch (err: any) {
          message.error(err?.response?.data?.message || 'Lỗi khi xóa hợp đồng');
        }
      },
    });
  };

  const handleSaveContract = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      const payload = {
        ...values,
        sign_date: values.sign_date ? values.sign_date.toISOString() : undefined,
        input_date: values.input_date ? values.input_date.toISOString() : undefined,
        receive_date: values.receive_date ? values.receive_date.toISOString() : undefined,
      };
      if (editingContract) {
        await api.put(`/hop-dong/${editingContract.id}`, payload);
        message.success('Cập nhật hợp đồng thành công');
      } else {
        await api.post('/hop-dong', payload);
        message.success('Thêm hợp đồng thành công');
      }
      setDrawerOpen(false);
      fetchContracts();
    } catch (err: any) {
      if (err?.errorFields) return;
      const msg = err?.response?.data?.message;
      if (msg && !setBackendFieldError(msg)) message.error(msg);
    } finally {
      setSaving(false);
    }
  };

  // ─────────────────── detail & attachments ───────────────────

  const handleViewDetail = (contract: Contract) => {
    setSelectedContract(contract);
    setAttachFileList([]);
    fetchAttachments(contract.id);
    setDetailDrawerOpen(true);
  };

  const handleUploadAttachment = async () => {
    if (!selectedContract || !attachFileList.length) return;
    const rawFile = attachFileList[0]?.originFileObj as RcFile;
    if (!rawFile) return;
    setAttachUploading(true);
    try {
      const formData = new FormData();
      formData.append('file', rawFile);
      await api.post(`/hop-dong/${selectedContract.id}/dinh-kem`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      message.success('Tải lên đính kèm thành công');
      setAttachFileList([]);
      fetchAttachments(selectedContract.id);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải lên đính kèm');
    } finally {
      setAttachUploading(false);
    }
  };

  const handleDeleteAttachment = (attachmentId: number) => {
    if (!selectedContract) return;
    Modal.confirm({
      title: 'Xác nhận xóa đính kèm',
      content: 'Bạn có chắc muốn xóa file đính kèm này?',
      okText: 'Xóa',
      okButtonProps: { danger: true },
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.delete(`/hop-dong/${selectedContract.id}/dinh-kem/${attachmentId}`);
          message.success('Xóa đính kèm thành công');
          fetchAttachments(selectedContract.id);
        } catch (err: any) {
          message.error(err?.response?.data?.message || 'Lỗi khi xóa đính kèm');
        }
      },
    });
  };

  // ─────────────────── columns ───────────────────

  const contractColumns: ColumnsType<Contract> = [
    {
      title: 'STT',
      key: 'stt',
      width: 55,
      align: 'center',
      render: (_, __, index) => (pagination.current - 1) * pagination.pageSize + index + 1,
    },
    {
      title: 'Mã HĐ',
      dataIndex: 'code',
      key: 'code',
      width: 110,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v || '—'}</span>,
    },
    {
      title: 'Tên hợp đồng',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
    },
    {
      title: 'Loại',
      dataIndex: 'type_name',
      key: 'type_name',
      width: 140,
      ellipsis: true,
    },
    {
      title: 'Đối tác',
      dataIndex: 'contact_name',
      key: 'contact_name',
      width: 160,
      ellipsis: true,
    },
    {
      title: 'Ngày ký',
      dataIndex: 'sign_date',
      key: 'sign_date',
      width: 100,
      render: (v) => v ? new Date(v).toLocaleDateString('vi-VN') : '—',
    },
    {
      title: 'Số tiền',
      dataIndex: 'amount',
      key: 'amount',
      width: 130,
      align: 'right',
      render: (v, record) => formatCurrency(v, record.currency),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      key: 'status',
      width: 130,
      render: (v) => {
        const s = STATUS_MAP[v] ?? { label: String(v), color: 'default' };
        return <Tag color={s.color}>{s.label}</Tag>;
      },
    },
    {
      title: 'Ngày tạo',
      dataIndex: 'created_date',
      key: 'created_date',
      width: 100,
      render: (v) => v ? new Date(v).toLocaleDateString('vi-VN') : '—',
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
                key: 'view',
                label: 'Xem chi tiết',
                icon: <EyeOutlined />,
                onClick: () => handleViewDetail(record),
              },
              {
                key: 'edit',
                label: 'Sửa',
                icon: <EditOutlined />,
                onClick: () => handleEditContract(record),
              },
              ...(record.status === 0 ? [
                { type: 'divider' as const },
                {
                  key: 'delete',
                  label: 'Xóa',
                  icon: <DeleteOutlined />,
                  danger: true,
                  onClick: () => handleDeleteContract(record.id),
                },
              ] : []),
            ],
          }}
        >
          <Button type="text" icon={<MoreOutlined />} size="small" />
        </Dropdown>
      ),
    },
  ];

  const typeColumns: ColumnsType<ContractType> = [
    { title: 'Mã', dataIndex: 'code', key: 'code', width: 100 },
    { title: 'Tên loại hợp đồng', dataIndex: 'name', key: 'name', ellipsis: true },
    { title: 'Ghi chú', dataIndex: 'note', key: 'note', ellipsis: true },
    { title: 'Thứ tự', dataIndex: 'sort_order', key: 'sort_order', width: 80, align: 'center' },
    {
      title: '',
      key: 'actions',
      width: 80,
      align: 'center',
      render: (_, record) => (
        <Space size="small">
          <Button
            type="text"
            size="small"
            icon={<EditOutlined />}
            onClick={() => handleEditType(record)}
          />
          <Button
            type="text"
            size="small"
            icon={<DeleteOutlined />}
            danger
            onClick={() => handleDeleteType(record.id)}
          />
        </Space>
      ),
    },
  ];

  const attachColumns: ColumnsType<Attachment> = [
    {
      title: 'Tên file',
      dataIndex: 'file_name',
      key: 'file_name',
      ellipsis: true,
      render: (name, record) => (
        <Button
          type="link"
          size="small"
          style={{ padding: 0 }}
          onClick={() => record.file_path && window.open(record.file_path, '_blank')}
        >
          {name}
        </Button>
      ),
    },
    {
      title: 'Kích thước',
      dataIndex: 'file_size',
      key: 'file_size',
      width: 100,
      align: 'right',
      render: (v) => formatFileSize(v),
    },
    {
      title: 'Ngày tải',
      dataIndex: 'created_date',
      key: 'created_date',
      width: 100,
      render: (v) => v ? new Date(v).toLocaleDateString('vi-VN') : '—',
    },
    {
      title: '',
      key: 'actions',
      width: 80,
      align: 'center',
      render: (_, record) => (
        <Space size="small">
          {record.file_path && (
            <Button
              type="text"
              size="small"
              icon={<DownloadOutlined />}
              onClick={() => window.open(record.file_path, '_blank')}
            />
          )}
          <Button
            type="text"
            size="small"
            icon={<DeleteOutlined />}
            danger
            onClick={() => handleDeleteAttachment(record.id)}
          />
        </Space>
      ),
    },
  ];

  // ─────────────────── render ───────────────────

  return (
    <div>
      <div className="page-header">
        <span className="page-title">Quản lý hợp đồng</span>
        <Space>
          <Button
            icon={<SettingOutlined />}
            onClick={() => { setEditingType(null); typeForm.resetFields(); setTypeDrawerOpen(true); }}
          >
            Quản lý loại hợp đồng
          </Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={handleAddContract}>
            Thêm hợp đồng
          </Button>
        </Space>
      </div>

      <div style={{ margin: '0 16px 16px' }}>
        <Card className="page-card">
          <div className="filter-row" style={{ marginBottom: 12 }}>
            <Space wrap>
              <Select
                placeholder="Loại hợp đồng"
                allowClear
                style={{ width: 200 }}
                value={filterTypeId}
                onChange={setFilterTypeId}
                options={contractTypes.map((t) => ({ value: t.id, label: t.name }))}
              />
              <Select
                placeholder="Trạng thái"
                allowClear
                style={{ width: 160 }}
                value={filterStatus}
                onChange={setFilterStatus}
                options={[
                  { value: 0, label: 'Mới' },
                  { value: 1, label: 'Đang thực hiện' },
                  { value: 2, label: 'Hoàn thành' },
                  { value: -1, label: 'Hủy' },
                ]}
              />
              <Input
                placeholder="Tìm kiếm hợp đồng..."
                value={keyword}
                onChange={(e) => setKeyword(e.target.value)}
                onPressEnter={() => fetchContracts(1, pagination.pageSize)}
                style={{ width: 260 }}
                allowClear
              />
              <Button onClick={() => fetchContracts(1, pagination.pageSize)}>Tìm kiếm</Button>
            </Space>
            <Button icon={<ReloadOutlined />} onClick={() => fetchContracts()}>Làm mới</Button>
          </div>

          <Table
            rowKey="id"
            dataSource={contracts}
            columns={contractColumns}
            loading={loading}
            size="small"
            scroll={{ x: 1200 }}
            pagination={{
              current: pagination.current,
              pageSize: pagination.pageSize,
              total: pagination.total,
              showSizeChanger: true,
              showTotal: (total) => `Tổng ${total} hợp đồng`,
              onChange: (page, pageSize) => {
                setPagination((p) => ({ ...p, current: page, pageSize }));
                fetchContracts(page, pageSize);
              },
            }}
          />
        </Card>
      </div>

      {/* Contract Type Management Drawer */}
      <Drawer
        title="Quản lý loại hợp đồng"
        open={typeDrawerOpen}
        onClose={() => { setTypeDrawerOpen(false); setEditingType(null); typeForm.resetFields(); }}
        size={600}
        rootClassName="drawer-gradient"
      >
        <Card
          size="small"
          title={editingType ? 'Chỉnh sửa loại hợp đồng' : 'Thêm loại hợp đồng mới'}
          style={{ marginBottom: 16 }}
        >
          <Form form={typeForm} layout="vertical" validateTrigger="onSubmit">
            <Row gutter={12}>
              <Col span={12}>
                <Form.Item name="code" label="Mã loại">
                  <Input placeholder="Nhập mã loại" maxLength={50} />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item name="sort_order" label="Thứ tự">
                  <InputNumber min={0} style={{ width: '100%' }} placeholder="0" />
                </Form.Item>
              </Col>
            </Row>
            <Form.Item
              name="name"
              label="Tên loại hợp đồng"
              rules={[{ required: true, message: 'Vui lòng nhập tên loại hợp đồng' }]}
            >
              <Input placeholder="Nhập tên loại hợp đồng" maxLength={200} />
            </Form.Item>
            <Form.Item name="note" label="Ghi chú">
              <TextArea rows={2} placeholder="Ghi chú" />
            </Form.Item>
            <Space>
              <Button
                type="primary"
                loading={typeSaving}
                onClick={handleSaveType}
              >
                {editingType ? 'Cập nhật' : 'Thêm mới'}
              </Button>
              {editingType && (
                <Button onClick={() => { setEditingType(null); typeForm.resetFields(); }}>
                  Hủy
                </Button>
              )}
            </Space>
          </Form>
        </Card>

        <Table
          rowKey="id"
          dataSource={contractTypes}
          columns={typeColumns}
          size="small"
          pagination={false}
          onRow={(record) => ({ onDoubleClick: () => handleEditType(record) })}
        />
      </Drawer>

      {/* Contract CRUD Drawer */}
      <Drawer
        title={editingContract ? 'Chỉnh sửa hợp đồng' : 'Thêm hợp đồng mới'}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        size={720}
        rootClassName="drawer-gradient"
        extra={
          <Space>
            <Button onClick={() => setDrawerOpen(false)}>Hủy</Button>
            <Button type="primary" loading={saving} onClick={handleSaveContract}>
              Lưu
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" validateTrigger="onSubmit">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="code" label="Mã hợp đồng">
                <Input placeholder="Nhập mã hợp đồng" maxLength={100} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                name="contract_type_id"
                label="Loại hợp đồng"
                rules={[{ required: true, message: 'Vui lòng chọn loại hợp đồng' }]}
              >
                <Select
                  placeholder="Chọn loại hợp đồng"
                  options={contractTypes.map((t) => ({ value: t.id, label: t.name }))}
                />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item
            name="name"
            label="Tên hợp đồng"
            rules={[{ required: true, message: 'Vui lòng nhập tên hợp đồng' }]}
          >
            <Input placeholder="Nhập tên hợp đồng" maxLength={500} />
          </Form.Item>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="contact_name" label="Đối tác">
                <Input placeholder="Tên đối tác / tổ chức" maxLength={200} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="signer" label="Người ký">
                <Input placeholder="Họ tên người ký" maxLength={200} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="sign_date" label="Ngày ký">
                <DatePicker format="DD/MM/YYYY" style={{ width: '100%' }} placeholder="dd/mm/yyyy" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="input_date" label="Ngày nhập">
                <DatePicker format="DD/MM/YYYY" style={{ width: '100%' }} placeholder="dd/mm/yyyy" />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="receive_date" label="Ngày nhận">
                <DatePicker format="DD/MM/YYYY" style={{ width: '100%' }} placeholder="dd/mm/yyyy" />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="amount" label="Giá trị hợp đồng">
                <Input placeholder="Nhập giá trị hợp đồng" maxLength={200} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="payment_amount" label="Số tiền đã thanh toán">
                <Input placeholder="Nhập số tiền đã thanh toán" maxLength={200} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="currency" label="Đơn vị tiền tệ" initialValue="VND">
                <Select
                  options={[
                    { value: 'VND', label: 'VND - Việt Nam Đồng' },
                    { value: 'USD', label: 'USD - Đô la Mỹ' },
                    { value: 'EUR', label: 'EUR - Euro' },
                  ]}
                />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item name="status" label="Trạng thái" initialValue={0}>
                <Select
                  options={[
                    { value: 0, label: 'Mới' },
                    { value: 1, label: 'Đang thực hiện' },
                    { value: 2, label: 'Hoàn thành' },
                    { value: -1, label: 'Hủy' },
                  ]}
                />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item name="note" label="Ghi chú">
            <TextArea rows={3} placeholder="Ghi chú thêm về hợp đồng" />
          </Form.Item>
        </Form>
      </Drawer>

      {/* Contract Detail Drawer */}
      <Drawer
        title={`Chi tiết hợp đồng: ${selectedContract?.name || ''}`}
        open={detailDrawerOpen}
        onClose={() => setDetailDrawerOpen(false)}
        size={720}
        rootClassName="drawer-gradient"
        extra={
          <Button
            icon={<EditOutlined />}
            onClick={() => {
              setDetailDrawerOpen(false);
              if (selectedContract) handleEditContract(selectedContract);
            }}
          >
            Chỉnh sửa
          </Button>
        }
      >
        {selectedContract && (
          <>
            <div className="info-grid" style={{ marginBottom: 16 }}>
              <Row gutter={[8, 8]}>
                <Col span={12}>
                  <Typography.Text type="secondary">Mã hợp đồng: </Typography.Text>
                  <Typography.Text strong>{selectedContract.code || '—'}</Typography.Text>
                </Col>
                <Col span={12}>
                  <Typography.Text type="secondary">Loại: </Typography.Text>
                  <Typography.Text strong>{selectedContract.type_name || '—'}</Typography.Text>
                </Col>
                <Col span={12}>
                  <Typography.Text type="secondary">Đối tác: </Typography.Text>
                  <Typography.Text>{selectedContract.contact_name || '—'}</Typography.Text>
                </Col>
                <Col span={12}>
                  <Typography.Text type="secondary">Trạng thái: </Typography.Text>
                  {(() => {
                    const s = STATUS_MAP[selectedContract.status] ?? { label: String(selectedContract.status), color: 'default' };
                    return <Tag color={s.color}>{s.label}</Tag>;
                  })()}
                </Col>
                <Col span={12}>
                  <Typography.Text type="secondary">Ngày ký: </Typography.Text>
                  <Typography.Text>
                    {selectedContract.sign_date ? new Date(selectedContract.sign_date).toLocaleDateString('vi-VN') : '—'}
                  </Typography.Text>
                </Col>
                <Col span={12}>
                  <Typography.Text type="secondary">Giá trị: </Typography.Text>
                  <Typography.Text strong>
                    {formatCurrency(selectedContract.amount, selectedContract.currency)}
                  </Typography.Text>
                </Col>
              </Row>
            </div>

            <Divider>Hồ sơ đính kèm</Divider>

            <Space style={{ marginBottom: 12 }}>
              <Upload
                fileList={attachFileList}
                beforeUpload={() => false}
                onChange={({ fileList: newList }) => setAttachFileList(newList.slice(-1))}
                maxCount={1}
                showUploadList={attachFileList.length > 0}
              >
                <Button icon={<UploadOutlined />}>Chọn file</Button>
              </Upload>
              {attachFileList.length > 0 && (
                <Button
                  type="primary"
                  loading={attachUploading}
                  onClick={handleUploadAttachment}
                >
                  Tải lên
                </Button>
              )}
            </Space>

            <Table
              rowKey="id"
              dataSource={attachments}
              columns={attachColumns}
              loading={attachLoading}
              size="small"
              pagination={false}
            />
          </>
        )}
      </Drawer>
    </div>
  );
}
