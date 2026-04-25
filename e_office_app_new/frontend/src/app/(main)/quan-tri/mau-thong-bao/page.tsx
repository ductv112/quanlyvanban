'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Drawer, Form, Switch, Tabs,
  Tag, Dropdown, Modal, App,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, SearchOutlined,
  MoreOutlined, MessageOutlined, MailOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';

interface SmsTemplate {
  id: number;
  name: string;
  content: string;
  description: string;
  is_active: boolean;
}

interface EmailTemplate {
  id: number;
  name: string;
  subject: string;
  content: string;
  description: string;
  is_active: boolean;
}

type TabType = 'sms' | 'email';

export default function NotificationTemplatePage() {
  const { message } = App.useApp();
  const [activeTab, setActiveTab] = useState<TabType>('sms');

  // SMS state
  const [smsData, setSmsData] = useState<SmsTemplate[]>([]);
  const [smsLoading, setSmsLoading] = useState(false);
  const [smsTotal, setSmsTotal] = useState(0);
  const [smsPage, setSmsPage] = useState(1);
  const [smsPageSize, setSmsPageSize] = useState(20);
  const [smsKeyword, setSmsKeyword] = useState('');

  // Email state
  const [emailData, setEmailData] = useState<EmailTemplate[]>([]);
  const [emailLoading, setEmailLoading] = useState(false);
  const [emailTotal, setEmailTotal] = useState(0);
  const [emailPage, setEmailPage] = useState(1);
  const [emailPageSize, setEmailPageSize] = useState(20);
  const [emailKeyword, setEmailKeyword] = useState('');

  // Drawer state
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [drawerType, setDrawerType] = useState<TabType>('sms');
  const [editingRecord, setEditingRecord] = useState<SmsTemplate | EmailTemplate | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  const fetchSms = useCallback(async () => {
    setSmsLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/mau-sms', {
        params: { keyword: smsKeyword, page: smsPage, pageSize: smsPageSize },
      });
      setSmsData(res.data || []);
      setSmsTotal(res.total || 0);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách mẫu SMS');
    } finally {
      setSmsLoading(false);
    }
  }, [smsKeyword, smsPage, smsPageSize, message]);

  const fetchEmail = useCallback(async () => {
    setEmailLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/mau-email', {
        params: { keyword: emailKeyword, page: emailPage, pageSize: emailPageSize },
      });
      setEmailData(res.data || []);
      setEmailTotal(res.total || 0);
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách mẫu email');
    } finally {
      setEmailLoading(false);
    }
  }, [emailKeyword, emailPage, emailPageSize, message]);

  useEffect(() => {
    fetchSms();
  }, [fetchSms]);

  useEffect(() => {
    fetchEmail();
  }, [fetchEmail]);

  const handleAdd = (type: TabType) => {
    setDrawerType(type);
    setEditingRecord(null);
    form.resetFields();
    form.setFieldsValue({ is_active: true });
    setDrawerOpen(true);
  };

  const handleEdit = (type: TabType, record: SmsTemplate | EmailTemplate) => {
    setDrawerType(type);
    setEditingRecord(record);
    form.setFieldsValue(record);
    setDrawerOpen(true);
  };

  const handleDelete = async (type: TabType, id: number) => {
    const apiPath = type === 'sms' ? '/quan-tri/mau-sms' : '/quan-tri/mau-email';
    try {
      await api.delete(`${apiPath}/${id}`);
      message.success('Xóa thành công');
      if (type === 'sms') fetchSms();
      else fetchEmail();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi xóa');
    }
  };

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      // SMS (route + SP)
      'Tên mẫu SMS là bắt buộc': 'name',
      'Tên mẫu tin nhắn không được để trống': 'name',
      'Tên mẫu SMS không được vượt quá 200 ký tự': 'name',
      'Tên mẫu tin nhắn không được vượt quá 200 ký tự': 'name',
      'Nội dung mẫu tin nhắn không được để trống': 'content',
      // Email (route + SP)
      'Tên mẫu email là bắt buộc': 'name',
      'Tên mẫu email không được để trống': 'name',
      'Tên mẫu email không được vượt quá 200 ký tự': 'name',
      'Nội dung mẫu email không được để trống': 'content',
      'Tiêu đề email không được vượt quá 500 ký tự': 'subject',
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
      const apiPath = drawerType === 'sms' ? '/quan-tri/mau-sms' : '/quan-tri/mau-email';

      if (editingRecord) {
        await api.put(`${apiPath}/${editingRecord.id}`, values);
        message.success('Cập nhật thành công');
      } else {
        await api.post(apiPath, values);
        message.success('Thêm thành công');
      }
      setDrawerOpen(false);
      if (drawerType === 'sms') fetchSms();
      else fetchEmail();
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

  const smsColumns: ColumnsType<SmsTemplate> = [
    {
      title: 'Tên mẫu',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Nội dung',
      dataIndex: 'content',
      key: 'content',
      ellipsis: true,
      width: 300,
      render: (v) => <span style={{ color: '#64748b' }}>{v}</span>,
    },
    {
      title: 'Trạng thái',
      dataIndex: 'is_active',
      key: 'is_active',
      width: 120,
      render: (v) => (
        <Tag color={v ? 'success' : 'error'}>{v ? 'Hoạt động' : 'Ngừng'}</Tag>
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
                onClick: () => handleEdit('sms', record),
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
                    content: 'Bạn có chắc chắn muốn xóa mẫu SMS này?',
                    okText: 'Xóa',
                    cancelText: 'Hủy',
                    okButtonProps: { danger: true },
                    onOk: () => handleDelete('sms', record.id),
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

  const emailColumns: ColumnsType<EmailTemplate> = [
    {
      title: 'Tên mẫu',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
      render: (v) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Tiêu đề',
      dataIndex: 'subject',
      key: 'subject',
      ellipsis: true,
      width: 300,
    },
    {
      title: 'Trạng thái',
      dataIndex: 'is_active',
      key: 'is_active',
      width: 120,
      render: (v) => (
        <Tag color={v ? 'success' : 'error'}>{v ? 'Hoạt động' : 'Ngừng'}</Tag>
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
                onClick: () => handleEdit('email', record),
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
                    content: 'Bạn có chắc chắn muốn xóa mẫu email này?',
                    okText: 'Xóa',
                    cancelText: 'Hủy',
                    okButtonProps: { danger: true },
                    onOk: () => handleDelete('email', record.id),
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

  const drawerTitle = editingRecord
    ? `Cập nhật mẫu ${drawerType === 'sms' ? 'SMS' : 'email'}`
    : `Thêm mẫu ${drawerType === 'sms' ? 'SMS' : 'email'} mới`;

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Mẫu thông báo
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Quản lý mẫu tin nhắn SMS và email thông báo
        </p>
      </div>

      <Card
        variant="borderless"
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
      >
        <Tabs
          activeKey={activeTab}
          onChange={(key) => setActiveTab(key as TabType)}
          items={[
            {
              key: 'sms',
              label: (
                <span>
                  <MessageOutlined style={{ marginRight: 6 }} />
                  Mẫu SMS
                </span>
              ),
              children: (
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16, flexWrap: 'wrap', gap: 8 }}>
                    <Input.Search
                      placeholder="Tìm kiếm mẫu SMS..."
                      allowClear
                      onSearch={(v) => { setSmsKeyword(v); setSmsPage(1); }}
                      style={{ width: 280, borderRadius: 8 }}
                      prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
                    />
                    <Button
                      type="primary"
                      icon={<PlusOutlined />}
                      onClick={() => handleAdd('sms')}
                      style={{ borderRadius: 8 }}
                    >
                      Thêm mẫu SMS
                    </Button>
                  </div>
                  <Table
                    className="enhanced-table"
                    columns={smsColumns}
                    dataSource={smsData}
                    rowKey="id"
                    loading={smsLoading}
                    size="middle"
                    sticky
                    scroll={{ x: 600 }}
                    pagination={{
                      current: smsPage,
                      pageSize: smsPageSize,
                      total: smsTotal,
                      showSizeChanger: true,
                      showTotal: (t) => `Tổng ${t}`,
                      onChange: (p, ps) => { setSmsPage(p); setSmsPageSize(ps); },
                    }}
                  />
                </div>
              ),
            },
            {
              key: 'email',
              label: (
                <span>
                  <MailOutlined style={{ marginRight: 6 }} />
                  Mẫu Email
                </span>
              ),
              children: (
                <div>
                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 16, flexWrap: 'wrap', gap: 8 }}>
                    <Input.Search
                      placeholder="Tìm kiếm mẫu email..."
                      allowClear
                      onSearch={(v) => { setEmailKeyword(v); setEmailPage(1); }}
                      style={{ width: 280, borderRadius: 8 }}
                      prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
                    />
                    <Button
                      type="primary"
                      icon={<PlusOutlined />}
                      onClick={() => handleAdd('email')}
                      style={{ borderRadius: 8 }}
                    >
                      Thêm mẫu email
                    </Button>
                  </div>
                  <Table
                    className="enhanced-table"
                    columns={emailColumns}
                    dataSource={emailData}
                    rowKey="id"
                    loading={emailLoading}
                    size="middle"
                    sticky
                    scroll={{ x: 600 }}
                    pagination={{
                      current: emailPage,
                      pageSize: emailPageSize,
                      total: emailTotal,
                      showSizeChanger: true,
                      showTotal: (t) => `Tổng ${t}`,
                      onChange: (p, ps) => { setEmailPage(p); setEmailPageSize(ps); },
                    }}
                  />
                </div>
              ),
            },
          ]}
        />
      </Card>

      <Drawer forceRender
        title={drawerTitle}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
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
          <Form.Item label="Tên mẫu" name="name" rules={[{ required: true, message: 'Nhập tên mẫu' }]}>
            <Input placeholder="VD: Thông báo văn bản mới" maxLength={200} style={{ borderRadius: 8 }} />
          </Form.Item>

          {drawerType === 'email' && (
            <Form.Item label="Tiêu đề" name="subject">
              <Input placeholder="Tiêu đề email" maxLength={500} style={{ borderRadius: 8 }} />
            </Form.Item>
          )}

          <Form.Item
            label="Nội dung"
            name="content"
            rules={[{ required: true, message: 'Nhập nội dung' }]}
          >
            <Input.TextArea
              rows={drawerType === 'email' ? 10 : 4}
              maxLength={drawerType === 'email' ? 5000 : 1000}
              placeholder="Dùng [CVNAME], [STAFFNAME] cho biến động"
              style={{ borderRadius: 8 }}
            />
          </Form.Item>

          <Form.Item label="Mô tả" name="description">
            <Input.TextArea rows={2} maxLength={500} style={{ borderRadius: 8 }} />
          </Form.Item>

          <Form.Item label="Trạng thái" name="is_active" valuePropName="checked" initialValue={true}>
            <Switch checkedChildren="Hoạt động" unCheckedChildren="Ngừng" />
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
