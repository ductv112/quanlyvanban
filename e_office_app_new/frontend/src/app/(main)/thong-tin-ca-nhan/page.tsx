'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  Card, Row, Col, Descriptions, Avatar, Form, Input, Button, App, Tag, Tabs, Upload, Space, Alert, Modal,
} from 'antd';
import type { UploadFile, UploadProps } from 'antd';
import {
  UserOutlined, LockOutlined, MailOutlined, PhoneOutlined,
  IdcardOutlined, ApartmentOutlined, SafetyOutlined,
  EditOutlined, UploadOutlined,
} from '@ant-design/icons';
import { useAuthStore } from '@/stores/auth.store';
import { api } from '@/lib/api';

const MAX_SIGN_IMAGE_SIZE = 2 * 1024 * 1024; // 2MB

export default function ProfilePage() {
  const { message, modal } = App.useApp();
  const { user, fetchMe, logout } = useAuthStore();
  const [form] = Form.useForm();
  const [signForm] = Form.useForm();
  const [editForm] = Form.useForm();
  const [saving, setSaving] = useState(false);
  const [savingSignature, setSavingSignature] = useState(false);
  const [signatureFile, setSignatureFile] = useState<File | null>(null);
  // Chỉ track signatureFile — cấu hình tài khoản ký số đã migrate sang /ky-so/tai-khoan
  const hasImageChange = signatureFile !== null;

  // BUG #13: Sửa thông tin tài khoản
  const [editOpen, setEditOpen] = useState(false);
  const [savingEdit, setSavingEdit] = useState(false);

  useEffect(() => {
    if (!user) fetchMe();
  }, [user, fetchMe]);

  const handleChangePassword = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      // BUG #70: endpoint /quan-tri/... yêu cầu quyền admin → non-admin user bị 403.
      // Chuyển sang /auth/change-password (chỉ cần authenticate, không cần admin).
      await api.post('/auth/change-password', {
        old_password: values.oldPassword,
        new_password: values.newPassword,
        confirm_password: values.confirmPassword ?? values.newPassword,
      });
      // BUG #12: sau khi đổi mật khẩu thành công → modal thông báo + đăng xuất + redirect login
      form.resetFields();
      modal.success({
        title: 'Đổi mật khẩu thành công',
        content: 'Vui lòng đăng nhập lại với mật khẩu mới.',
        okText: 'Đăng nhập lại',
        centered: true,
        maskClosable: false,
        onOk: async () => {
          await logout();
        },
      });
    } catch (err: any) {
      if (err?.response) {
        message.error(err?.response?.data?.message || 'Lỗi đổi mật khẩu');
      }
    } finally {
      setSaving(false);
    }
  };

  // BUG #13: Mở modal sửa thông tin
  const openEditProfile = () => {
    if (!user) return;
    // Tách full_name thành first_name + last_name (Vietnamese: last_name = họ, first_name = tên)
    const parts = (user.fullName || '').trim().split(/\s+/);
    const last = parts.length > 1 ? parts.slice(0, -1).join(' ') : '';
    const first = parts.length > 0 ? parts[parts.length - 1] : user.fullName;
    editForm.setFieldsValue({
      first_name: first,
      last_name: last,
      email: user.email || '',
      phone: user.phone || '',
    });
    setEditOpen(true);
  };

  const handleSaveProfile = async () => {
    try {
      const values = await editForm.validateFields();
      setSavingEdit(true);
      await api.patch('/ho-so-ca-nhan/thong-tin', {
        first_name: values.first_name,
        last_name: values.last_name,
        email: values.email || '',
        phone: values.phone || '',
      });
      message.success('Cập nhật thông tin thành công');
      await fetchMe();
      setEditOpen(false);
    } catch (err: any) {
      if (err?.response) {
        message.error(err?.response?.data?.message || 'Cập nhật thất bại');
      }
    } finally {
      setSavingEdit(false);
    }
  };

  // Upload props — validate PNG ≤ 2MB, KHÔNG auto-upload, lưu vào state
  const uploadProps: UploadProps = {
    accept: '.png,image/png',
    maxCount: 1,
    beforeUpload: (file) => {
      if (file.type !== 'image/png') {
        message.error('Chỉ chấp nhận file PNG');
        return Upload.LIST_IGNORE;
      }
      if (file.size > MAX_SIGN_IMAGE_SIZE) {
        message.error('Kích thước ảnh tối đa 2MB');
        return Upload.LIST_IGNORE;
      }
      setSignatureFile(file);
      return false;
    },
    onRemove: () => {
      setSignatureFile(null);
    },
    fileList: signatureFile
      ? [{ uid: '-1', name: signatureFile.name, status: 'done' } as UploadFile]
      : [],
  };

  const handleSaveSignature = async () => {
    if (!signatureFile) {
      message.warning('Vui lòng chọn ảnh chữ ký mới');
      return;
    }

    try {
      setSavingSignature(true);

      const fd = new FormData();
      fd.append('file', signatureFile);
      await api.post('/ho-so-ca-nhan/anh-chu-ky', fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });

      message.success('Đã cập nhật ảnh chữ ký');
      await fetchMe(); // refresh store để cập nhật signImageUrl mới
      setSignatureFile(null);
    } catch (err: any) {
      if (err?.response) {
        message.error(err?.response?.data?.message || 'Lưu thất bại');
      } else {
        message.error('Có lỗi xảy ra, vui lòng thử lại');
      }
    } finally {
      setSavingSignature(false);
    }
  };

  if (!user) return null;

  const passwordPanel = (
    <>
      <p style={{ fontSize: 13, color: '#64748b', marginBottom: 20 }}>
        Mật khẩu phải có ít nhất 6 ký tự, chứa chữ hoa, chữ thường và số.
      </p>

      <Form form={form} layout="vertical" autoComplete="off">
        <Form.Item
          label="Mật khẩu hiện tại"
          name="oldPassword"
          rules={[{ required: true, message: 'Nhập mật khẩu hiện tại' }]}
        >
          <Input.Password
            placeholder="Nhập mật khẩu hiện tại"
            autoComplete="current-password"
            style={{ borderRadius: 8 }}
          />
        </Form.Item>

        <Form.Item
          label="Mật khẩu mới"
          name="newPassword"
          rules={[
            { required: true, message: 'Nhập mật khẩu mới' },
            { min: 6, message: 'Tối thiểu 6 ký tự' },
            { pattern: /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)/, message: 'Phải chứa chữ hoa, chữ thường và số' },
          ]}
        >
          <Input.Password
            placeholder="Nhập mật khẩu mới"
            autoComplete="new-password"
            style={{ borderRadius: 8 }}
          />
        </Form.Item>

        <Form.Item
          label="Xác nhận mật khẩu mới"
          name="confirmPassword"
          dependencies={['newPassword']}
          rules={[
            { required: true, message: 'Xác nhận mật khẩu mới' },
            ({ getFieldValue }) => ({
              validator(_, value) {
                if (!value || getFieldValue('newPassword') === value) {
                  return Promise.resolve();
                }
                return Promise.reject(new Error('Mật khẩu xác nhận không khớp'));
              },
            }),
          ]}
        >
          <Input.Password
            placeholder="Nhập lại mật khẩu mới"
            autoComplete="new-password"
            style={{ borderRadius: 8 }}
          />
        </Form.Item>

        <Button
          type="primary"
          loading={saving}
          onClick={handleChangePassword}
          block
          style={{ borderRadius: 8, height: 40, fontWeight: 600, marginTop: 8 }}
        >
          Đổi mật khẩu
        </Button>
      </Form>
    </>
  );

  const signaturePanel = (
    <>
      <Alert
        type="info"
        showIcon
        style={{ marginBottom: 16, borderRadius: 8 }}
        title="Thông tin cấu hình ký số đã chuyển trang"
        description={
          <span>
            Cấu hình tài khoản ký số với nhà cung cấp (SmartCA VNPT / MySign Viettel) đã
            chuyển sang menu{' '}
            <Link href="/ky-so/tai-khoan" style={{ fontWeight: 600 }}>
              Ký số → Tài khoản ký số cá nhân
            </Link>
            . Trang này chỉ còn quản lý ảnh chữ ký để in trên PDF khi ký.
          </span>
        }
      />

      <p style={{ fontSize: 13, color: '#64748b', marginBottom: 20 }}>
        Tải lên ảnh chữ ký PNG để hệ thống chèn lên văn bản PDF khi ký số.
      </p>

      <Form form={signForm} layout="vertical" autoComplete="off">
        <Form.Item
          label="Ảnh chữ ký (PNG, khuyến nghị 150×150)"
          extra="Chỉ chấp nhận file PNG, kích thước tối đa 2MB."
        >
          <Upload {...uploadProps}>
            <Button icon={<UploadOutlined />}>Chọn file PNG</Button>
          </Upload>
        </Form.Item>

        {user.signImageUrl ? (
          <Form.Item label="Chữ ký hiện tại">
            <div style={{
              padding: 12,
              background: '#F9FAFB',
              border: '1px dashed #CBD5E1',
              borderRadius: 8,
              display: 'inline-block',
            }}>
              <Avatar
                shape="square"
                size={150}
                src={user.signImageUrl}
                alt="Ảnh chữ ký hiện tại"
                style={{ background: '#fff', objectFit: 'contain' }}
              />
            </div>
          </Form.Item>
        ) : (
          <Form.Item label="Chữ ký hiện tại">
            <span style={{ color: '#94a3b8', fontSize: 13 }}>Chưa cập nhật ảnh chữ ký</span>
          </Form.Item>
        )}

        <Space>
          <Button
            type="primary"
            icon={<EditOutlined />}
            loading={savingSignature}
            disabled={!hasImageChange}
            onClick={handleSaveSignature}
            style={{ borderRadius: 8, height: 40, fontWeight: 600 }}
          >
            Lưu ảnh chữ ký
          </Button>
        </Space>
      </Form>
    </>
  );

  return (
    <div>
      <div className="page-header">
        <h2 className="page-title">
          Thông tin cá nhân
        </h2>
        <p className="page-description">
          Xem thông tin tài khoản, đổi mật khẩu và quản lý ảnh chữ ký
        </p>
      </div>

      <Row gutter={20}>
        {/* Left: Profile info */}
        <Col xs={24} lg={14}>
          <Card
            variant="borderless"
            className="page-card"
            extra={
              <Button
                type="primary"
                icon={<EditOutlined />}
                onClick={openEditProfile}
              >
                Sửa thông tin
              </Button>
            }
          >
            {/* Profile header */}
            <div className="profile-header">
              <Avatar
                size={72}
                src={user.image || undefined}
                icon={!user.image ? <UserOutlined /> : undefined}
                style={{
                  background: 'rgba(255,255,255,0.2)',
                  border: '3px solid rgba(255,255,255,0.3)',
                  fontSize: 32,
                }}
              />
              <div>
                <div style={{ fontSize: 20, fontWeight: 700, color: '#fff', marginBottom: 4 }}>
                  {user.fullName}
                </div>
                <div style={{ fontSize: 13, color: 'rgba(255,255,255,0.7)', marginBottom: 6 }}>
                  @{user.username}
                </div>
                <div style={{ display: 'flex', gap: 6 }}>
                  {user.positionName && (
                    <Tag color="cyan" style={{ margin: 0 }}>{user.positionName}</Tag>
                  )}
                  {user.isAdmin && (
                    <Tag color="gold" style={{ margin: 0 }}>Quản trị viên</Tag>
                  )}
                </div>
              </div>
            </div>

            <Descriptions
              column={1}
              styles={{ label: { fontWeight: 600, color: '#64748b', width: 160 }, content: { color: '#1B3A5C' } }}
              size="middle"
            >
              <Descriptions.Item label={<><UserOutlined style={{ marginRight: 6 }} />Họ và tên</>}>
                {user.fullName}
              </Descriptions.Item>
              <Descriptions.Item label={<><IdcardOutlined style={{ marginRight: 6 }} />Tên đăng nhập</>}>
                {user.username}
              </Descriptions.Item>
              <Descriptions.Item label={<><MailOutlined style={{ marginRight: 6 }} />Email</>}>
                {user.email || <span style={{ color: '#94a3b8' }}>Chưa cập nhật</span>}
              </Descriptions.Item>
              <Descriptions.Item label={<><PhoneOutlined style={{ marginRight: 6 }} />Số điện thoại</>}>
                {user.phone || <span style={{ color: '#94a3b8' }}>Chưa cập nhật</span>}
              </Descriptions.Item>
              <Descriptions.Item label={<><SafetyOutlined style={{ marginRight: 6 }} />Chức vụ</>}>
                {user.positionName || <span style={{ color: '#94a3b8' }}>Chưa cập nhật</span>}
              </Descriptions.Item>
              <Descriptions.Item label={<><ApartmentOutlined style={{ marginRight: 6 }} />Phòng ban</>}>
                {user.departmentName || <span style={{ color: '#94a3b8' }}>Chưa cập nhật</span>}
              </Descriptions.Item>
              <Descriptions.Item label={<><ApartmentOutlined style={{ marginRight: 6 }} />Đơn vị</>}>
                {user.unitName || <span style={{ color: '#94a3b8' }}>Chưa cập nhật</span>}
              </Descriptions.Item>
            </Descriptions>
          </Card>
        </Col>

        {/* Right: Tabs Đổi mật khẩu / Ảnh chữ ký */}
        <Col xs={24} lg={10}>
          <Card
            variant="borderless"
            className="page-card"
            styles={{ body: { paddingTop: 8 } }}
          >
            <Tabs
              defaultActiveKey="password"
              items={[
                {
                  key: 'password',
                  label: (
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                      <LockOutlined />
                      Đổi mật khẩu
                    </span>
                  ),
                  children: passwordPanel,
                  forceRender: true,
                },
                // Tab "Ảnh chữ ký" đã chuyển sang trang riêng "Tài khoản ký số cá nhân"
                // (menu KÝ SỐ → Tài khoản ký số cá nhân). Xoá tab trùng ở đây.
              ]}
            />
          </Card>
        </Col>
      </Row>

      {/* BUG #13: Modal sửa thông tin tài khoản */}
      <Modal
        title="Sửa thông tin tài khoản"
        open={editOpen}
        onCancel={() => setEditOpen(false)}
        onOk={handleSaveProfile}
        okText="Lưu"
        cancelText="Hủy"
        confirmLoading={savingEdit}
        maskClosable={false}
        destroyOnHidden
        width={520}
      >
        <Form form={editForm} layout="vertical" autoComplete="off" style={{ marginTop: 12 }}>
          <Row gutter={12}>
            <Col span={12}>
              <Form.Item
                label="Họ"
                name="last_name"
                rules={[
                  { required: true, message: 'Nhập họ' },
                  { max: 100, message: 'Tối đa 100 ký tự' },
                ]}
              >
                <Input placeholder="Nhập họ" maxLength={100} />
              </Form.Item>
            </Col>
            <Col span={12}>
              <Form.Item
                label="Tên"
                name="first_name"
                rules={[
                  { required: true, message: 'Nhập tên' },
                  { max: 100, message: 'Tối đa 100 ký tự' },
                ]}
              >
                <Input placeholder="Nhập tên" maxLength={100} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item
            label="Email"
            name="email"
            rules={[
              { type: 'email', message: 'Email không hợp lệ' },
              { max: 200, message: 'Tối đa 200 ký tự' },
            ]}
          >
            <Input placeholder="Nhập email" maxLength={200} prefix={<MailOutlined />} />
          </Form.Item>
          <Form.Item
            label="Số điện thoại"
            name="phone"
            rules={[
              { pattern: /^[0-9+\-\s()]*$/, message: 'Số điện thoại không hợp lệ' },
              { max: 50, message: 'Tối đa 50 ký tự' },
            ]}
          >
            <Input placeholder="Nhập số điện thoại" maxLength={50} prefix={<PhoneOutlined />} />
          </Form.Item>
        </Form>
      </Modal>
    </div>
  );
}
