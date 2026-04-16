'use client';

import React, { useState, useEffect } from 'react';
import {
  Card, Row, Col, Descriptions, Avatar, Form, Input, Button, App, Tag,
} from 'antd';
import {
  UserOutlined, LockOutlined, MailOutlined, PhoneOutlined,
  IdcardOutlined, ApartmentOutlined, SafetyOutlined,
} from '@ant-design/icons';
import { useAuthStore } from '@/stores/auth.store';
import { api } from '@/lib/api';

export default function ProfilePage() {
  const { message } = App.useApp();
  const { user, fetchMe } = useAuthStore();
  const [form] = Form.useForm();
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!user) fetchMe();
  }, [user, fetchMe]);

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

  if (!user) return null;

  return (
    <div>
      <div className="page-header">
        <h2 className="page-title">
          Thông tin cá nhân
        </h2>
        <p className="page-description">
          Xem thông tin tài khoản và đổi mật khẩu
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
            </Descriptions>
          </Card>
        </Col>

        {/* Right: Change password */}
        <Col xs={24} lg={10}>
          <Card
            variant="borderless"
            className="page-card"
            title={
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <LockOutlined style={{ color: '#0891B2' }} />
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Đổi mật khẩu</span>
              </div>
            }
          >
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
          </Card>
        </Col>
      </Row>
    </div>
  );
}
