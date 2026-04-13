'use client';

import React, { useState, useEffect } from 'react';
import { Layout, Menu, Avatar, Dropdown, Badge, Breadcrumb, Skeleton, App } from 'antd';
import type { MenuProps } from 'antd';
import {
  DashboardOutlined,
  FileTextOutlined,
  FolderOpenOutlined,
  SettingOutlined,
  BellOutlined,
  LogoutOutlined,
  UserOutlined,
  MenuFoldOutlined,
  MenuUnfoldOutlined,
  InboxOutlined,
  SendOutlined,
  EditOutlined,
  HomeOutlined,
  KeyOutlined,
} from '@ant-design/icons';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/stores/auth.store';

const { Header, Sider, Content } = Layout;

type MenuItem = Required<MenuProps>['items'][number];

const menuItems: MenuItem[] = [
  {
    key: '/dashboard',
    icon: <DashboardOutlined />,
    label: 'Tổng quan',
  },
  {
    key: 'van-ban',
    icon: <FileTextOutlined />,
    label: 'Văn bản',
    children: [
      { key: '/van-ban/den', icon: <InboxOutlined />, label: 'Văn bản đến' },
      { key: '/van-ban/di', icon: <SendOutlined />, label: 'Văn bản đi' },
      { key: '/van-ban/du-thao', icon: <EditOutlined />, label: 'Văn bản dự thảo' },
    ],
  },
  {
    key: '/ho-so-cong-viec',
    icon: <FolderOpenOutlined />,
    label: 'Hồ sơ công việc',
  },
  {
    type: 'divider',
  },
  {
    key: 'quan-tri',
    icon: <SettingOutlined />,
    label: 'Quản trị',
    children: [
      { key: '/quan-tri/nguoi-dung', icon: <UserOutlined />, label: 'Người dùng' },
      { key: '/quan-tri/nhom-quyen', icon: <KeyOutlined />, label: 'Nhóm quyền' },
    ],
  },
];

// Map pathname to breadcrumb labels
const breadcrumbMap: Record<string, string> = {
  '/dashboard': 'Tổng quan',
  '/van-ban': 'Văn bản',
  '/van-ban/den': 'Văn bản đến',
  '/van-ban/di': 'Văn bản đi',
  '/van-ban/du-thao': 'Văn bản dự thảo',
  '/ho-so-cong-viec': 'Hồ sơ công việc',
  '/quan-tri': 'Quản trị',
  '/quan-tri/nguoi-dung': 'Người dùng',
  '/quan-tri/nhom-quyen': 'Nhóm quyền',
};

function buildBreadcrumbs(pathname: string) {
  const segments = pathname.split('/').filter(Boolean);
  const items: { title: React.ReactNode }[] = [
    {
      title: (
        <Link href="/dashboard">
          <HomeOutlined />
        </Link>
      ),
    },
  ];

  let path = '';
  for (const segment of segments) {
    path += `/${segment}`;
    const label = breadcrumbMap[path];
    if (label) {
      if (path === pathname) {
        items.push({ title: label });
      } else {
        items.push({ title: <Link href={path}>{label}</Link> });
      }
    }
  }

  return items;
}

// Find open keys for current path
function getOpenKeys(pathname: string): string[] {
  for (const item of menuItems) {
    if (item && 'children' in item && item.children) {
      for (const child of item.children) {
        if (child && 'key' in child && pathname.startsWith(child.key as string)) {
          return [item.key as string];
        }
      }
    }
  }
  return [];
}

export default function MainLayout({ children }: { children: React.ReactNode }) {
  const [collapsed, setCollapsed] = useState(false);
  const router = useRouter();
  const pathname = usePathname();
  const { user, isLoading, fetchMe, logout } = useAuthStore();
  const { modal } = App.useApp();

  useEffect(() => {
    if (!user) {
      fetchMe();
    }
  }, [user, fetchMe]);

  const handleMenuClick: MenuProps['onClick'] = ({ key }) => {
    router.push(key);
  };

  const handleLogout = () => {
    modal.confirm({
      title: 'Đăng xuất',
      content: 'Bạn có chắc chắn muốn đăng xuất?',
      okText: 'Đăng xuất',
      cancelText: 'Hủy',
      okButtonProps: { danger: true },
      onOk: () => logout(),
    });
  };

  const userMenuItems: MenuProps['items'] = [
    {
      key: 'profile',
      icon: <UserOutlined />,
      label: 'Thông tin cá nhân',
    },
    { type: 'divider' },
    {
      key: 'logout',
      icon: <LogoutOutlined />,
      label: 'Đăng xuất',
      danger: true,
      onClick: handleLogout,
    },
  ];

  const breadcrumbItems = buildBreadcrumbs(pathname);
  const openKeys = getOpenKeys(pathname);

  if (isLoading && !user) {
    return (
      <div style={{ padding: 48, maxWidth: 800, margin: '120px auto' }}>
        <Skeleton active paragraph={{ rows: 6 }} />
      </div>
    );
  }

  return (
    <Layout style={{ minHeight: '100vh' }}>
      {/* SIDEBAR */}
      <Sider
        trigger={null}
        collapsible
        collapsed={collapsed}
        width={260}
        collapsedWidth={72}
        style={styles.sider}
      >
        {/* Logo */}
        <div style={styles.logo}>
          <div style={styles.logoIconBox}>
            <FileTextOutlined style={{ fontSize: collapsed ? 20 : 22, color: '#0891B2' }} />
          </div>
          {!collapsed && (
            <div style={styles.logoText}>
              <span style={styles.logoTitle}>QLVB</span>
              <span style={styles.logoSub}>Văn bản điện tử</span>
            </div>
          )}
        </div>

        {/* Menu */}
        <Menu
          theme="dark"
          mode="inline"
          selectedKeys={[pathname]}
          defaultOpenKeys={openKeys}
          items={menuItems}
          onClick={handleMenuClick}
          style={{ border: 'none', marginTop: 8 }}
        />

        {/* User card at bottom */}
        {!collapsed && user && (
          <div style={styles.siderUserCard}>
            <Avatar
              size={36}
              src={user.image || undefined}
              icon={!user.image ? <UserOutlined /> : undefined}
              style={{ background: '#1B3A5C', flexShrink: 0 }}
            />
            <div style={styles.siderUserInfo}>
              <div style={styles.siderUserName}>{user.fullName}</div>
              <div style={styles.siderUserRole}>{user.positionName || 'Nhân viên'}</div>
            </div>
          </div>
        )}
      </Sider>

      {/* MAIN AREA */}
      <Layout style={{ marginLeft: collapsed ? 72 : 260, transition: 'margin-left 0.2s' }}>
        {/* HEADER */}
        <Header style={styles.header}>
          <div style={styles.headerLeft}>
            <div
              onClick={() => setCollapsed(!collapsed)}
              style={styles.collapseBtn}
            >
              {collapsed ? (
                <MenuUnfoldOutlined style={{ fontSize: 18 }} />
              ) : (
                <MenuFoldOutlined style={{ fontSize: 18 }} />
              )}
            </div>
            <Breadcrumb items={breadcrumbItems} style={{ marginLeft: 8 }} />
          </div>

          <div style={styles.headerRight}>
            <Badge count={3} size="small">
              <BellOutlined
                style={styles.headerIcon}
                onClick={() => {/* TODO: notification drawer */}}
              />
            </Badge>

            <Dropdown menu={{ items: userMenuItems }} placement="bottomRight" trigger={['click']}>
              <div style={styles.userDropdown}>
                <Avatar
                  size={32}
                  src={user?.image || undefined}
                  icon={!user?.image ? <UserOutlined /> : undefined}
                  style={{ background: '#1B3A5C' }}
                />
                {user && (
                  <span style={styles.userName}>{user.fullName}</span>
                )}
              </div>
            </Dropdown>
          </div>
        </Header>

        {/* CONTENT */}
        <Content style={styles.content}>
          {children}
        </Content>
      </Layout>
    </Layout>
  );
}

const styles: Record<string, React.CSSProperties> = {
  sider: {
    position: 'fixed',
    left: 0,
    top: 0,
    bottom: 0,
    zIndex: 100,
    overflow: 'auto',
    borderRight: '1px solid rgba(255,255,255,0.06)',
  },
  logo: {
    display: 'flex',
    alignItems: 'center',
    gap: 12,
    padding: '20px 16px 16px',
    borderBottom: '1px solid rgba(255,255,255,0.08)',
  },
  logoIconBox: {
    width: 40,
    height: 40,
    borderRadius: 10,
    background: 'rgba(8, 145, 178, 0.15)',
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    flexShrink: 0,
  },
  logoText: {
    display: 'flex',
    flexDirection: 'column',
  },
  logoTitle: {
    fontSize: 18,
    fontWeight: 700,
    color: '#ffffff',
    letterSpacing: '0.5px',
    lineHeight: 1.2,
  },
  logoSub: {
    fontSize: 11,
    color: 'rgba(255,255,255,0.45)',
    letterSpacing: '0.3px',
  },
  siderUserCard: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    display: 'flex',
    alignItems: 'center',
    gap: 10,
    padding: '14px 16px',
    borderTop: '1px solid rgba(255,255,255,0.08)',
    background: 'rgba(0,0,0,0.15)',
  },
  siderUserInfo: {
    overflow: 'hidden',
  },
  siderUserName: {
    fontSize: 13,
    fontWeight: 600,
    color: '#ffffff',
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
  },
  siderUserRole: {
    fontSize: 11,
    color: 'rgba(255,255,255,0.5)',
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
  },
  // Header
  header: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: '0 24px',
    height: 56,
    background: '#ffffff',
    borderBottom: '1px solid #e8ecf1',
    boxShadow: '0 1px 4px rgba(0,0,0,0.04)',
    position: 'sticky',
    top: 0,
    zIndex: 99,
  },
  headerLeft: {
    display: 'flex',
    alignItems: 'center',
    gap: 4,
  },
  collapseBtn: {
    width: 36,
    height: 36,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 8,
    cursor: 'pointer',
    color: '#64748b',
    transition: 'all 0.2s',
  },
  headerRight: {
    display: 'flex',
    alignItems: 'center',
    gap: 20,
  },
  headerIcon: {
    fontSize: 18,
    color: '#64748b',
    cursor: 'pointer',
    padding: 6,
  },
  userDropdown: {
    display: 'flex',
    alignItems: 'center',
    gap: 8,
    cursor: 'pointer',
    padding: '4px 8px',
    borderRadius: 8,
    transition: 'background 0.2s',
  },
  userName: {
    fontSize: 13,
    fontWeight: 600,
    color: '#1B3A5C',
    maxWidth: 150,
    whiteSpace: 'nowrap',
    overflow: 'hidden',
    textOverflow: 'ellipsis',
  },
  // Content
  content: {
    padding: 24,
    minHeight: 'calc(100vh - 56px)',
    background: '#F0F2F5',
  },
};
