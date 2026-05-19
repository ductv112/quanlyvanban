'use client';

import React, { useState } from 'react';
import { Form, Input, Button, App, Checkbox } from 'antd';
import {
  UserOutlined,
  LockOutlined,
  FileProtectOutlined,
  SafetyOutlined,
  CloudServerOutlined,
  TeamOutlined,
} from '@ant-design/icons';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/stores/auth.store';
import './login.css';

export default function LoginPage() {
  const [loading, setLoading] = useState(false);
  const { message } = App.useApp();
  const router = useRouter();
  const login = useAuthStore((s) => s.login);

  const onFinish = async (values: { username: string; password: string; remember: boolean }) => {
    setLoading(true);
    // Destroy any existing message instance trước khi gọi để mỗi lần sai mật khẩu
    // đều hiển thị lại toast (BUG #7 — tránh AntD dedupe khi cùng content)
    message.destroy();
    try {
      await login(values.username, values.password);
      message.success({ content: 'Đăng nhập thành công', key: 'login-status' });
      router.push('/dashboard');
    } catch (error: any) {
      const msg = error?.response?.data?.message || 'Tên đăng nhập hoặc mật khẩu không đúng';
      // Dùng key + duration cố định để mỗi lần error đều show lại
      message.error({ content: msg, key: 'login-status', duration: 4 });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      {/* Left panel — branding */}
      <div className="login-left">
        <div className="login-left-overlay" />
        <div className="login-brand">
          <div className="login-logo-box">
            <FileProtectOutlined style={{ fontSize: 36, color: '#ffffff' }} />
          </div>
          <h1 className="login-brand-title">Quản lý Văn bản</h1>
          <p className="login-brand-subtitle">
            Hệ thống quản lý văn bản điện tử — Chuyển đổi số doanh nghiệp
          </p>

          <div className="login-features">
            {[
              { icon: <SafetyOutlined />, text: 'Bảo mật — Ký số điện tử, mã hóa dữ liệu' },
              { icon: <CloudServerOutlined />, text: 'Liên thông — Tích hợp LGSP quốc gia' },
              { icon: <TeamOutlined />, text: 'Cộng tác — Quản lý hồ sơ công việc realtime' },
            ].map((f, i) => (
              <div key={i} className="login-feature-item">
                <span className="login-feature-icon">{f.icon}</span>
                <span className="login-feature-text">{f.text}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Decorative elements */}
        <div className="login-decor-1" />
        <div className="login-decor-2" />
      </div>

      {/* Right panel — login form */}
      <div className="login-right">
        <div className="login-form-wrapper">
          <div className="login-form-header">
            <h2 className="login-form-title">Đăng nhập</h2>
            <p className="login-form-subtitle">Nhập thông tin tài khoản để truy cập hệ thống</p>
          </div>

          <Form
            name="login"
            size="large"
            onFinish={onFinish}
            autoComplete="on"
            layout="vertical"
            initialValues={{ remember: true }}
          >
            <Form.Item
              name="username"
              label={<span style={{ fontWeight: 600, color: '#334155', fontSize: 13 }}>Tên đăng nhập</span>}
              rules={[{ required: true, message: 'Vui lòng nhập tên đăng nhập' }]}
            >
              <Input
                prefix={<UserOutlined style={{ color: '#94a3b8' }} />}
                placeholder="Nhập tên đăng nhập"
                autoComplete="username"
                style={{ borderRadius: 8, height: 44 }}
              />
            </Form.Item>

            <Form.Item
              name="password"
              label={<span style={{ fontWeight: 600, color: '#334155', fontSize: 13 }}>Mật khẩu</span>}
              rules={[{ required: true, message: 'Vui lòng nhập mật khẩu' }]}
            >
              <Input.Password
                prefix={<LockOutlined style={{ color: '#94a3b8' }} />}
                placeholder="Nhập mật khẩu"
                autoComplete="current-password"
                style={{ borderRadius: 8, height: 44 }}
              />
            </Form.Item>

            <Form.Item>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                <Form.Item name="remember" valuePropName="checked" noStyle>
                  <Checkbox>Ghi nhớ đăng nhập</Checkbox>
                </Form.Item>
              </div>
            </Form.Item>

            <Form.Item>
              <Button
                type="primary"
                htmlType="submit"
                block
                loading={loading}
                className="login-submit-btn"
              >
                Đăng nhập
              </Button>
            </Form.Item>
          </Form>

          <div className="login-footer">
            <p>Phiên bản 2.0 &middot; Chuyển đổi số Doanh nghiệp</p>
          </div>
        </div>
      </div>
    </div>
  );
}
