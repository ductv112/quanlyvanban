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

export default function LoginPage() {
  const [loading, setLoading] = useState(false);
  const { message } = App.useApp();
  const router = useRouter();
  const login = useAuthStore((s) => s.login);

  const onFinish = async (values: { username: string; password: string; remember: boolean }) => {
    setLoading(true);
    try {
      await login(values.username, values.password);
      message.success('Đăng nhập thành công');
      router.push('/dashboard');
    } catch (error: any) {
      const msg = error?.response?.data?.message || 'Đăng nhập thất bại';
      message.error(msg);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={styles.container}>
      {/* Left panel — branding */}
      <div style={styles.leftPanel}>
        <div style={styles.overlay} />
        <div style={styles.brandContent}>
          <div style={styles.logoBox}>
            <FileProtectOutlined style={styles.logoIcon} />
          </div>
          <h1 style={styles.brandTitle}>Quản lý Văn bản</h1>
          <p style={styles.brandSubtitle}>
            Hệ thống quản lý văn bản điện tử — Chuyển đổi số doanh nghiệp
          </p>

          <div style={styles.featureList}>
            {[
              { icon: <SafetyOutlined />, text: 'Bảo mật — Ký số điện tử, mã hóa dữ liệu' },
              { icon: <CloudServerOutlined />, text: 'Liên thông — Tích hợp LGSP quốc gia' },
              { icon: <TeamOutlined />, text: 'Cộng tác — Quản lý hồ sơ công việc realtime' },
            ].map((f, i) => (
              <div key={i} style={styles.featureItem}>
                <span style={styles.featureIcon}>{f.icon}</span>
                <span style={styles.featureText}>{f.text}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Decorative elements */}
        <div style={styles.decorCircle1} />
        <div style={styles.decorCircle2} />
      </div>

      {/* Right panel — login form */}
      <div style={styles.rightPanel}>
        <div style={styles.formWrapper}>
          <div style={styles.formHeader}>
            <h2 style={styles.formTitle}>Đăng nhập</h2>
            <p style={styles.formSubtitle}>Nhập thông tin tài khoản để truy cập hệ thống</p>
          </div>

          <Form
            name="login"
            size="large"
            onFinish={onFinish}
            autoComplete="off"
            layout="vertical"
            initialValues={{ remember: true }}
          >
            <Form.Item
              name="username"
              label={<span style={styles.label}>Tên đăng nhập</span>}
              rules={[{ required: true, message: 'Vui lòng nhập tên đăng nhập' }]}
            >
              <Input
                prefix={<UserOutlined style={{ color: '#94a3b8' }} />}
                placeholder="Nhập tên đăng nhập"
                style={styles.input}
              />
            </Form.Item>

            <Form.Item
              name="password"
              label={<span style={styles.label}>Mật khẩu</span>}
              rules={[{ required: true, message: 'Vui lòng nhập mật khẩu' }]}
            >
              <Input.Password
                prefix={<LockOutlined style={{ color: '#94a3b8' }} />}
                placeholder="Nhập mật khẩu"
                style={styles.input}
              />
            </Form.Item>

            <Form.Item>
              <div style={styles.rememberRow}>
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
                style={styles.submitBtn}
              >
                Đăng nhập
              </Button>
            </Form.Item>
          </Form>

          <div style={styles.footer}>
            <p style={styles.footerText}>
              Phiên bản 2.0 &middot; Chuyển đổi số Doanh nghiệp
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}

const styles: Record<string, React.CSSProperties> = {
  container: {
    display: 'flex',
    minHeight: '100vh',
    background: '#f0f2f5',
  },
  // -- Left panel --
  leftPanel: {
    flex: '0 0 55%',
    background: 'linear-gradient(135deg, #0F1A2E 0%, #1B3A5C 50%, #0891B2 100%)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    position: 'relative',
    overflow: 'hidden',
    padding: '48px',
  },
  overlay: {
    position: 'absolute',
    inset: 0,
    background: `url("data:image/svg+xml,%3Csvg width='60' height='60' viewBox='0 0 60 60' xmlns='http://www.w3.org/2000/svg'%3E%3Cg fill='none' fill-rule='evenodd'%3E%3Cg fill='%23ffffff' fill-opacity='0.03'%3E%3Cpath d='M36 34v-4h-2v4h-4v2h4v4h2v-4h4v-2h-4zm0-30V0h-2v4h-4v2h4v4h2V6h4V4h-4zM6 34v-4H4v4H0v2h4v4h2v-4h4v-2H6zM6 4V0H4v4H0v2h4v4h2V6h4V4H6z'/%3E%3C/g%3E%3C/g%3E%3C/svg%3E")`,
  },
  brandContent: {
    position: 'relative',
    zIndex: 1,
    maxWidth: 480,
  },
  logoBox: {
    width: 72,
    height: 72,
    background: 'rgba(255, 255, 255, 0.15)',
    borderRadius: 16,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 32,
    backdropFilter: 'blur(8px)',
  },
  logoIcon: {
    fontSize: 36,
    color: '#ffffff',
  },
  brandTitle: {
    fontSize: 36,
    fontWeight: 700,
    color: '#ffffff',
    margin: '0 0 12px 0',
    letterSpacing: '-0.5px',
    lineHeight: 1.2,
  },
  brandSubtitle: {
    fontSize: 16,
    color: 'rgba(255, 255, 255, 0.7)',
    margin: '0 0 48px 0',
    lineHeight: 1.6,
  },
  featureList: {
    display: 'flex',
    flexDirection: 'column',
    gap: 20,
  },
  featureItem: {
    display: 'flex',
    alignItems: 'center',
    gap: 14,
  },
  featureIcon: {
    width: 40,
    height: 40,
    background: 'rgba(255, 255, 255, 0.1)',
    borderRadius: 10,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    fontSize: 18,
    color: '#67e8f9',
    flexShrink: 0,
  },
  featureText: {
    fontSize: 14,
    color: 'rgba(255, 255, 255, 0.8)',
    lineHeight: 1.5,
  },
  decorCircle1: {
    position: 'absolute',
    width: 300,
    height: 300,
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(8,145,178,0.2) 0%, transparent 70%)',
    bottom: -80,
    right: -60,
  },
  decorCircle2: {
    position: 'absolute',
    width: 200,
    height: 200,
    borderRadius: '50%',
    background: 'radial-gradient(circle, rgba(255,255,255,0.05) 0%, transparent 70%)',
    top: -40,
    left: -40,
  },
  // -- Right panel --
  rightPanel: {
    flex: '0 0 45%',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '48px',
    background: '#ffffff',
  },
  formWrapper: {
    width: '100%',
    maxWidth: 400,
  },
  formHeader: {
    marginBottom: 36,
  },
  formTitle: {
    fontSize: 28,
    fontWeight: 700,
    color: '#1B3A5C',
    margin: '0 0 8px 0',
    letterSpacing: '-0.3px',
  },
  formSubtitle: {
    fontSize: 14,
    color: '#64748b',
    margin: 0,
    lineHeight: 1.5,
  },
  label: {
    fontWeight: 600,
    color: '#334155',
    fontSize: 13,
  },
  input: {
    borderRadius: 8,
    height: 44,
  },
  rememberRow: {
    display: 'flex',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  submitBtn: {
    height: 48,
    borderRadius: 8,
    fontWeight: 600,
    fontSize: 15,
    background: 'linear-gradient(135deg, #1B3A5C 0%, #0891B2 100%)',
    border: 'none',
    boxShadow: '0 4px 12px rgba(27, 58, 92, 0.3)',
  },
  footer: {
    marginTop: 48,
    textAlign: 'center' as const,
  },
  footerText: {
    fontSize: 12,
    color: '#94a3b8',
    margin: 0,
  },
};
