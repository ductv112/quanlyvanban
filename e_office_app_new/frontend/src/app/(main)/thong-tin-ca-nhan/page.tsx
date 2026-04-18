'use client';

import React, { useState, useEffect } from 'react';
import {
  Card, Row, Col, Descriptions, Avatar, Form, Input, Button, App, Tag, Tabs, Upload, Space,
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
  const { message } = App.useApp();
  const { user, fetchMe } = useAuthStore();
  const [form] = Form.useForm();
  const [signForm] = Form.useForm();
  const [saving, setSaving] = useState(false);
  const [savingSignature, setSavingSignature] = useState(false);
  const [signatureFile, setSignatureFile] = useState<File | null>(null);
  // Track sign_phone value để tính hasChanges (disable Save khi không có thay đổi)
  const watchedSignPhone = Form.useWatch('sign_phone', signForm) ?? '';
  const hasChanges =
    signatureFile !== null ||
    String(watchedSignPhone).trim() !== String(user?.signPhone || '').trim();

  useEffect(() => {
    if (!user) fetchMe();
  }, [user, fetchMe]);

  // Pre-fill sign_phone vào signForm khi user load
  useEffect(() => {
    if (user) {
      signForm.setFieldsValue({ sign_phone: user.signPhone || '' });
    }
  }, [user, signForm]);

  const handleChangePassword = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      await api.patch(`/quan-tri/nguoi-dung/${user?.staffId}/change-password`, {
        oldPassword: values.oldPassword,
        newPassword: values.newPassword,
      });
      message.success('Đổi mật khẩu thành công');
      form.resetFields();
    } catch (err: any) {
      if (err?.response) {
        message.error(err?.response?.data?.message || 'Lỗi đổi mật khẩu');
      }
    } finally {
      setSaving(false);
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
    try {
      const values = await signForm.validateFields();

      // Validate: ít nhất 1 trong (ảnh chữ ký mới, số SmartCA khác giá trị cũ) phải có
      if (!hasChanges) {
        message.warning('Vui lòng nhập tài khoản ký số hoặc chọn ảnh chữ ký mới');
        return;
      }

      setSavingSignature(true);

      // 1. Upload ảnh nếu có file mới
      if (signatureFile) {
        const fd = new FormData();
        fd.append('file', signatureFile);
        await api.post('/ho-so-ca-nhan/anh-chu-ky', fd, {
          headers: { 'Content-Type': 'multipart/form-data' },
        });
      }

      // 2. Update sign_phone (nếu khác giá trị cũ hoặc mới nhập)
      const newPhone = (values.sign_phone || '').trim();
      if (newPhone !== (user?.signPhone || '')) {
        await api.patch('/ho-so-ca-nhan/chu-ky-so', {
          sign_phone: newPhone || null,
        });
      }

      message.success('Đã lưu thông tin chữ ký số');
      await fetchMe(); // refresh store để cập nhật signImageUrl mới
      setSignatureFile(null);
    } catch (err: any) {
      if (err?.response) {
        message.error(err?.response?.data?.message || 'Lưu thất bại');
      } else if (err?.errorFields) {
        // Form validation error — đã hiển thị inline
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
      <p style={{ fontSize: 13, color: '#64748b', marginBottom: 20 }}>
        Cấu hình tài khoản ký số SmartCA và ảnh chữ ký để sử dụng khi ký văn bản điện tử.
      </p>

      <Form form={signForm} layout="vertical" autoComplete="off">
        <Form.Item
          label="Tài khoản ký số (SmartCA)"
          name="sign_phone"
          rules={[
            { pattern: /^[0-9+\-\s()]*$/, message: 'Số điện thoại không hợp lệ' },
            { max: 20, message: 'Tối đa 20 ký tự' },
          ]}
          extra="Nhập số điện thoại đã đăng ký với nhà cung cấp SmartCA. Ví dụ: 84813789393"
        >
          <Input
            placeholder="Ví dụ: 84813789393"
            maxLength={20}
            allowClear
            style={{ borderRadius: 8 }}
          />
        </Form.Item>

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
            disabled={!hasChanges}
            onClick={handleSaveSignature}
            style={{ borderRadius: 8, height: 40, fontWeight: 600 }}
          >
            Lưu thông tin ký số
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
          Xem thông tin tài khoản, đổi mật khẩu và cấu hình chữ ký số
        </p>
      </div>

      <Row gutter={20}>
        {/* Left: Profile info */}
        <Col xs={24} lg={14}>
          <Card
            variant="borderless"
            className="page-card"
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
              <Descriptions.Item label={<><EditOutlined style={{ marginRight: 6 }} />Tài khoản ký số</>}>
                {user.signPhone || <span style={{ color: '#94a3b8' }}>Chưa cấu hình</span>}
              </Descriptions.Item>
            </Descriptions>
          </Card>
        </Col>

        {/* Right: Tabs Đổi mật khẩu / Chữ ký số */}
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
                {
                  key: 'signature',
                  label: (
                    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}>
                      <EditOutlined />
                      Chữ ký số
                    </span>
                  ),
                  children: signaturePanel,
                  forceRender: true,
                },
              ]}
            />
          </Card>
        </Col>
      </Row>
    </div>
  );
}
