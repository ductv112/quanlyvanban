'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Layout, Menu, Avatar, Dropdown, Badge, Breadcrumb, Skeleton, App, Button, Typography } from 'antd';
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
  ApartmentOutlined,
  IdcardOutlined,
  AppstoreOutlined,
  BookOutlined,
  TagsOutlined,
  ClusterOutlined,
  TableOutlined,
  BankOutlined,
  SolutionOutlined,
  TeamOutlined,
  SwapOutlined,
  EnvironmentOutlined,
  CalendarOutlined,
  MailOutlined,
  ToolOutlined,
  StarOutlined,
  ContactsOutlined,
  DatabaseOutlined,
  AuditOutlined,
} from '@ant-design/icons';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/stores/auth.store';
import { api } from '@/lib/api';
import { initSocket, disconnectSocket, SOCKET_EVENTS } from '@/lib/socket';

const { Header, Sider, Content } = Layout;
const { Text } = Typography;

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
      { key: '/van-ban-den', icon: <InboxOutlined />, label: 'Văn bản đến' },
      { key: '/van-ban-di', icon: <SendOutlined />, label: 'Văn bản đi' },
      { key: '/van-ban-du-thao', icon: <EditOutlined />, label: 'Văn bản dự thảo' },
      { key: '/van-ban-lien-thong', icon: <SwapOutlined />, label: 'Văn bản liên thông' },
      { key: '/van-ban-danh-dau', icon: <StarOutlined />, label: 'Đánh dấu cá nhân' },
    ],
  },
  {
    key: '/ho-so-cong-viec',
    icon: <FolderOpenOutlined />,
    label: 'Hồ sơ công việc',
  },
  {
    key: '/tin-nhan',
    icon: <MailOutlined />,
    label: 'Tin nhắn',
  },
  {
    key: '/thong-bao',
    icon: <BellOutlined />,
    label: 'Thông báo',
  },
  {
    key: 'lich',
    icon: <CalendarOutlined />,
    label: 'Lịch',
    children: [
      { key: '/lich/ca-nhan', icon: <UserOutlined />, label: 'Lịch cá nhân' },
      { key: '/lich/co-quan', icon: <BankOutlined />, label: 'Lịch cơ quan' },
      { key: '/lich/lanh-dao', icon: <SolutionOutlined />, label: 'Lịch lãnh đạo' },
    ],
  },
  {
    key: '/danh-ba',
    icon: <ContactsOutlined />,
    label: 'Danh bạ',
  },
  {
    key: 'kho-luu-tru',
    icon: <DatabaseOutlined />,
    label: 'Kho lưu trữ',
    children: [
      { key: '/kho-luu-tru', label: 'Danh mục kho/phông' },
      { key: '/kho-luu-tru/muon-tra', label: 'Mượn/trả hồ sơ' },
    ],
  },
  {
    key: '/tai-lieu',
    icon: <FileTextOutlined />,
    label: 'Tài liệu',
  },
  {
    key: '/hop-dong',
    icon: <AuditOutlined />,
    label: 'Hợp đồng',
  },
  {
    key: 'cuoc-hop',
    icon: <TeamOutlined />,
    label: 'Cuộc họp',
    children: [
      { key: '/cuoc-hop', label: 'Danh sách cuộc họp' },
      { key: '/cuoc-hop/thong-ke', label: 'Thống kê' },
    ],
  },
  {
    type: 'divider',
  },
  {
    key: 'quan-tri',
    icon: <SettingOutlined />,
    label: 'Quản trị',
    children: [
      { key: '/quan-tri/don-vi', icon: <ApartmentOutlined />, label: 'Đơn vị' },
      { key: '/quan-tri/chuc-vu', icon: <IdcardOutlined />, label: 'Chức vụ' },
      { key: '/quan-tri/nguoi-dung', icon: <UserOutlined />, label: 'Người dùng' },
      { key: '/quan-tri/nhom-quyen', icon: <KeyOutlined />, label: 'Nhóm quyền' },
      { key: '/quan-tri/chuc-nang', icon: <AppstoreOutlined />, label: 'Chức năng' },
    ],
  },
  {
    key: 'danh-muc',
    icon: <BookOutlined />,
    label: 'Danh mục',
    children: [
      { key: '/quan-tri/so-van-ban', icon: <BookOutlined />, label: 'Sổ văn bản' },
      { key: '/quan-tri/loai-van-ban', icon: <TagsOutlined />, label: 'Loại văn bản' },
      { key: '/quan-tri/linh-vuc', icon: <ClusterOutlined />, label: 'Lĩnh vực' },
      { key: '/quan-tri/thuoc-tinh-van-ban', icon: <TableOutlined />, label: 'Thuộc tính VB' },
      { key: '/quan-tri/co-quan', icon: <BankOutlined />, label: 'Cơ quan' },
      { key: '/quan-tri/nguoi-ky', icon: <SolutionOutlined />, label: 'Người ký' },
      { key: '/quan-tri/nhom-lam-viec', icon: <TeamOutlined />, label: 'Nhóm làm việc' },
      { key: '/quan-tri/uy-quyen', icon: <SwapOutlined />, label: 'Ủy quyền' },
      { key: '/quan-tri/dia-ban', icon: <EnvironmentOutlined />, label: 'Địa bàn' },
      { key: '/quan-tri/lich-lam-viec', icon: <CalendarOutlined />, label: 'Lịch làm việc' },
      { key: '/quan-tri/mau-thong-bao', icon: <MailOutlined />, label: 'Mẫu thông báo' },
      { key: '/quan-tri/cau-hinh', icon: <ToolOutlined />, label: 'Cấu hình' },
    ],
  },
];

// Map pathname to breadcrumb labels
const breadcrumbMap: Record<string, string> = {
  '/dashboard': 'Tổng quan',
  '/van-ban-den': 'Văn bản đến',
  '/van-ban-danh-dau': 'Đánh dấu cá nhân',
  '/van-ban-di': 'Văn bản đi',
  '/van-ban-du-thao': 'Văn bản dự thảo',
  '/van-ban-lien-thong': 'Văn bản liên thông',
  '/ho-so-cong-viec': 'Hồ sơ công việc',
  '/tin-nhan': 'Tin nhắn',
  '/thong-bao': 'Thông báo',
  '/quan-tri': 'Quản trị',
  '/quan-tri/don-vi': 'Đơn vị',
  '/quan-tri/chuc-vu': 'Chức vụ',
  '/quan-tri/nguoi-dung': 'Người dùng',
  '/quan-tri/nhom-quyen': 'Nhóm quyền',
  '/quan-tri/chuc-nang': 'Chức năng',
  '/quan-tri/so-van-ban': 'Sổ văn bản',
  '/quan-tri/loai-van-ban': 'Loại văn bản',
  '/quan-tri/linh-vuc': 'Lĩnh vực',
  '/quan-tri/thuoc-tinh-van-ban': 'Thuộc tính văn bản',
  '/quan-tri/co-quan': 'Cơ quan',
  '/quan-tri/nguoi-ky': 'Người ký',
  '/quan-tri/nhom-lam-viec': 'Nhóm làm việc',
  '/quan-tri/uy-quyen': 'Ủy quyền',
  '/quan-tri/dia-ban': 'Địa bàn',
  '/quan-tri/lich-lam-viec': 'Lịch làm việc',
  '/quan-tri/mau-thong-bao': 'Mẫu thông báo',
  '/quan-tri/cau-hinh': 'Cấu hình',
  '/thong-tin-ca-nhan': 'Thông tin cá nhân',
  '/lich/ca-nhan': 'Lịch cá nhân',
  '/lich/co-quan': 'Lịch cơ quan',
  '/lich/lanh-dao': 'Lịch lãnh đạo',
  '/danh-ba': 'Danh bạ điện thoại',
  '/kho-luu-tru': 'Kho lưu trữ',
  '/kho-luu-tru/muon-tra': 'Mượn/trả hồ sơ',
  '/tai-lieu': 'Tài liệu',
  '/hop-dong': 'Hợp đồng',
  '/cuoc-hop': 'Cuộc họp',
  '/cuoc-hop/thong-ke': 'Thống kê cuộc họp',
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
    } else if (/^\d+$/.test(segment)) {
      // Dynamic ID segment — show "Chi tiết"
      items.push({ title: 'Chi tiết' });
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

// ─── Notification item type ──────────────────────────────────────────────────

interface NotifItem {
  id: number;
  title: string;
  content: string;
  is_read: boolean;
  created_at: string;
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function MainLayout({ children }: { children: React.ReactNode }) {
  const [collapsed, setCollapsed] = useState(false);
  const router = useRouter();
  const pathname = usePathname();
  const { user, isLoading, fetchMe, logout } = useAuthStore();
  const { modal, message } = App.useApp();

  // Bell notification state
  const [notifItems, setNotifItems] = useState<NotifItem[]>([]);
  const [notifUnreadCount, setNotifUnreadCount] = useState(0);
  const [bellOpen, setBellOpen] = useState(false);

  useEffect(() => {
    if (!user) {
      fetchMe();
    }
  }, [user, fetchMe]);

  // Fetch unread count on mount
  useEffect(() => {
    const fetchUnreadCount = async () => {
      try {
        const { data: res } = await api.get('/thong-bao/unread-count');
        setNotifUnreadCount(res.data?.count ?? res.data ?? 0);
      } catch {
        // Silent
      }
    };
    fetchUnreadCount();
  }, []);

  // Socket.IO integration
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const token = localStorage.getItem('accessToken');
    if (!token) return;

    const socket = initSocket(token);

    socket.on(SOCKET_EVENTS.NEW_MESSAGE, () => {
      message.info('Bạn có tin nhắn mới');
    });

    socket.on(SOCKET_EVENTS.NEW_NOTIFICATION, (data: { title?: string }) => {
      message.info(data?.title || 'Thông báo mới');
      setNotifUnreadCount((prev) => prev + 1);
    });

    socket.on(SOCKET_EVENTS.NEW_DOCUMENT, () => {
      message.info('Có văn bản mới cần xử lý');
      setNotifUnreadCount((prev) => prev + 1);
    });

    return () => {
      disconnectSocket();
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Fetch notifications on bell click
  const handleBellOpenChange = useCallback(async (open: boolean) => {
    setBellOpen(open);
    if (open) {
      try {
        const { data: res } = await api.get('/thong-bao', {
          params: { page: 1, page_size: 10 },
        });
        const list: NotifItem[] = res.data?.list || res.data || [];
        setNotifItems(list);
      } catch {
        // Silent
      }
    }
  }, []);

  // Mark all read from bell dropdown
  const handleBellMarkAllRead = async () => {
    try {
      await api.patch('/thong-bao/mark-all-read');
      setNotifUnreadCount(0);
      setNotifItems((prev) => prev.map((n) => ({ ...n, is_read: true })));
      message.success('Đã đánh dấu tất cả là đã đọc');
    } catch {
      // Silent
    }
  };

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
      onClick: () => router.push('/thong-tin-ca-nhan'),
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
      <div className="main-loading">
        <Skeleton active paragraph={{ rows: 6 }} />
      </div>
    );
  }

  // Bell dropdown overlay content
  const bellDropdownContent = (
    <div className="notif-bell-overlay">
      {/* Header */}
      <div style={{
        display: 'flex',
        justifyContent: 'space-between',
        alignItems: 'center',
        padding: '12px 16px',
        borderBottom: '1px solid #F1F5F9',
      }}>
        <Text style={{ fontSize: 16, fontWeight: 600, color: '#1B3A5C' }}>Thông báo</Text>
        <Button
          type="link"
          size="small"
          style={{ fontSize: 12, color: '#0891B2', padding: 0 }}
          onClick={handleBellMarkAllRead}
        >
          Đánh dấu tất cả đã đọc
        </Button>
      </div>

      {/* Notification items */}
      {notifItems.length === 0 ? (
        <div style={{ padding: '16px', textAlign: 'center', color: '#94A3B8', fontSize: 13 }}>Không có thông báo</div>
      ) : (
        notifItems.map((item) => (
          <div
            key={item.id}
            className={`notif-item${!item.is_read ? ' unread' : ''}`}
            onClick={() => router.push('/thong-bao')}
            style={{ cursor: 'pointer' }}
          >
            <div style={{
              width: 28, height: 28, borderRadius: '50%', background: '#EFF8FF',
              display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0,
            }}>
              <BellOutlined style={{ color: '#0891B2', fontSize: 12 }} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{
                fontSize: 13, fontWeight: !item.is_read ? 600 : 400, color: '#1B3A5C',
                overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
              }}>
                {item.title}
              </div>
              <div style={{ fontSize: 12, color: '#94A3B8', marginTop: 2 }}>
                {new Date(item.created_at).toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
              </div>
            </div>
          </div>
        ))
      )}

      {/* Footer link */}
      <div style={{
        padding: '10px 16px',
        borderTop: '1px solid #F1F5F9',
        textAlign: 'center',
      }}>
        <Button
          type="link"
          size="small"
          style={{ fontSize: 13, color: '#0891B2' }}
          onClick={() => {
            setBellOpen(false);
            router.push('/thong-bao');
          }}
        >
          Xem tất cả thông báo
        </Button>
      </div>
    </div>
  );

  return (
    <Layout className="main-layout">
      {/* SIDEBAR */}
      <Sider
        trigger={null}
        collapsible
        collapsed={collapsed}
        width={260}
        collapsedWidth={72}
        className="main-sider"
      >
        {/* Logo */}
        <div className="main-sider-logo">
          <div className="main-sider-logo-icon">
            <FileTextOutlined style={{ fontSize: collapsed ? 20 : 22, color: '#0891B2' }} />
          </div>
          {!collapsed && (
            <div style={{ display: 'flex', flexDirection: 'column' }}>
              <span className="main-sider-logo-title">QLVB</span>
              <span className="main-sider-logo-sub">Văn bản điện tử</span>
            </div>
          )}
        </div>

        <div className="main-sider-menu-wrap">
          <Menu
            theme="dark"
            mode="inline"
            selectedKeys={[pathname]}
            defaultOpenKeys={openKeys}
            items={menuItems}
            onClick={handleMenuClick}
            style={{ border: 'none', marginTop: 8 }}
          />
        </div>
      </Sider>

      {/* MAIN AREA */}
      <Layout className={`main-area${collapsed ? ' collapsed' : ''}`}>
        {/* HEADER */}
        <Header className="main-header">
          <div className="main-header-left">
            <div
              onClick={() => setCollapsed(!collapsed)}
              className="main-collapse-btn"
            >
              {collapsed ? (
                <MenuUnfoldOutlined style={{ fontSize: 18 }} />
              ) : (
                <MenuFoldOutlined style={{ fontSize: 18 }} />
              )}
            </div>
            <Breadcrumb items={breadcrumbItems} style={{ marginLeft: 8 }} />
          </div>

          <div className="main-header-right">
            {/* Bell icon with dropdown */}
            <Dropdown
              open={bellOpen}
              onOpenChange={handleBellOpenChange}
              placement="bottomRight"
              trigger={['click']}
              popupRender={() => bellDropdownContent}
            >
              <Badge count={notifUnreadCount} size="small" overflowCount={99}>
                <BellOutlined
                  className="main-header-icon"
                  style={{ cursor: 'pointer' }}
                />
              </Badge>
            </Dropdown>

            <Dropdown menu={{ items: userMenuItems }} placement="bottomRight" trigger={['click']}>
              <div className="main-user-dropdown">
                <Avatar
                  size={32}
                  src={user?.image || undefined}
                  icon={!user?.image ? <UserOutlined /> : undefined}
                  style={{ background: '#1B3A5C' }}
                />
                {user && (
                  <span className="main-user-name">{user.fullName}</span>
                )}
              </div>
            </Dropdown>
          </div>
        </Header>

        {/* CONTENT */}
        <Content className="main-content">
          {children}
        </Content>
      </Layout>
    </Layout>
  );
}
