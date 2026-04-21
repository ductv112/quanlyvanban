'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { Layout, Menu, Avatar, Dropdown, Badge, Breadcrumb, Skeleton, App, Button, Typography, Drawer } from 'antd';
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
  MenuOutlined,
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
  ApiOutlined,
  NotificationOutlined,
  LinkOutlined,
  SafetyCertificateOutlined,
} from '@ant-design/icons';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { useAuthStore } from '@/stores/auth.store';
import { api } from '@/lib/api';
import { initSocket, disconnectSocket, SOCKET_EVENTS } from '@/lib/socket';

const { Header, Sider, Content } = Layout;
const { Text } = Typography;

type MenuItem = Required<MenuProps>['items'][number];

// Role names from seed data
const ADMIN_ROLE = 'Quản trị hệ thống';
const VAN_THU_ROLE = 'Văn thư';
const LANH_DAO_ROLE = 'Ban Lãnh đạo';
const CHI_DAO_ROLE = 'Chỉ đạo điều hành';

// ─── Phase 1 feature flag: ẩn menu chưa có trong HDSD cũ ──────────────────
// Các route/module dưới đây tạm ẩn khỏi sidebar để bản demo chỉ hiển thị
// đúng scope nghiệp vụ trong HDSD cũ. KHÔNG xóa code — Phase 2 muốn bật lại
// chỉ cần xóa entry tương ứng khỏi Set này.
const HIDDEN_ROUTES: ReadonlySet<string> = new Set([
  // Tin nhắn
  '/tin-nhan',
  // Lịch (ẩn cả parent group 'lich' qua recursive check)
  'lich',
  '/lich/ca-nhan',
  '/lich/co-quan',
  '/lich/lanh-dao',
  // Danh bạ
  '/danh-ba',
  // Kho lưu trữ
  'kho-luu-tru',
  '/kho-luu-tru',
  '/kho-luu-tru/muon-tra',
  // Tài liệu
  '/tai-lieu',
  // Hợp đồng
  '/hop-dong',
  // Cuộc họp
  'cuoc-hop',
  '/cuoc-hop',
  '/cuoc-hop/thong-ke',
  // LGSP + kênh thông báo
  '/lgsp',
  '/lgsp/co-quan',
  '/thong-bao-kenh',
  // Quản trị items bị ẩn (chuyển sang Phase 2)
  '/quan-tri/chuc-nang',
  '/quan-tri/cau-hinh-truong',
  '/quan-tri/co-quan',
  '/quan-tri/nhom-lam-viec',
  '/quan-tri/uy-quyen',
  '/quan-tri/dia-ban',
  '/quan-tri/lich-lam-viec',
  '/quan-tri/mau-thong-bao',
  '/quan-tri/cau-hinh',
]);

// Recursive filter:
// 1. Item có key trong HIDDEN_ROUTES → drop.
// 2. Item có children → filter children; children rỗng sau filter → drop luôn cha.
// 3. Group header (type='group') không tự drop qua HIDDEN_ROUTES — sau khi filter
//    nếu group header không còn item thực ngay sau (trước group khác) → drop header.
function filterMenuItems(items: MenuItem[]): MenuItem[] {
  const afterHide: MenuItem[] = [];
  for (const item of items) {
    if (!item) continue;
    // Divider luôn giữ
    if ('type' in item && item.type === 'divider') {
      afterHide.push(item);
      continue;
    }
    const key = 'key' in item ? (item.key as string | undefined) : undefined;
    // Group header: xử lý ở bước 2 dưới
    if ('type' in item && item.type === 'group') {
      afterHide.push(item);
      continue;
    }
    // Item thường / submenu
    if (key && HIDDEN_ROUTES.has(key)) continue;
    // Recurse children
    if ('children' in item && Array.isArray(item.children) && item.children.length > 0) {
      const filteredChildren = filterMenuItems(item.children as MenuItem[]);
      if (filteredChildren.length === 0) continue; // parent trống → drop
      afterHide.push({ ...item, children: filteredChildren });
      continue;
    }
    afterHide.push(item);
  }
  // Bước 2: ẩn group header trống
  const result: MenuItem[] = [];
  for (let i = 0; i < afterHide.length; i++) {
    const cur = afterHide[i];
    if (cur && 'type' in cur && cur.type === 'group') {
      // Đếm item thực sau cur cho tới group tiếp theo hoặc hết array
      let hasContent = false;
      for (let j = i + 1; j < afterHide.length; j++) {
        const next = afterHide[j];
        if (!next) continue;
        if ('type' in next && next.type === 'group') break;
        // Divider không tính là content
        if ('type' in next && next.type === 'divider') continue;
        hasContent = true;
        break;
      }
      if (!hasContent) continue; // group trống → skip
    }
    result.push(cur);
  }
  return result;
}

interface MenuBuildParams {
  badgeCounts: { vbDen: number; tinNhan: number; thongBao: number };
  isAdmin: boolean;
  roles: string[];
}

// Menu builder filtered by user roles
function buildMenuItems({ badgeCounts, isAdmin, roles }: MenuBuildParams): MenuItem[] {
  const hasRole = (name: string) => roles.includes(name);
  const isLeader = hasRole(LANH_DAO_ROLE) || hasRole(CHI_DAO_ROLE);
  const isVanThu = hasRole(VAN_THU_ROLE);
  // Admin, Văn thư, Lãnh đạo can see management sections
  const canManage = isAdmin || isVanThu || isLeader;

  const items: MenuItem[] = [
    {
      key: '/dashboard',
      icon: <DashboardOutlined />,
      label: 'Tổng quan',
    },
    // ── NGHIỆP VỤ ── (everyone sees this)
    { key: 'grp-nghiepvu', type: 'group', label: 'NGHIỆP VỤ' },
    {
      key: 'van-ban',
      icon: <FileTextOutlined />,
      label: 'Văn bản',
      children: [
        {
          key: '/van-ban-den',
          icon: <InboxOutlined />,
          label: badgeCounts.vbDen > 0
            ? <span style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>Văn bản đến<span className="sidebar-badge">{badgeCounts.vbDen}</span></span>
            : 'Văn bản đến',
        },
        { key: '/van-ban-di', icon: <SendOutlined />, label: 'Văn bản đi' },
        { key: '/van-ban-du-thao', icon: <EditOutlined />, label: 'Văn bản dự thảo' },
        { key: '/van-ban-lien-thong', icon: <SwapOutlined />, label: 'Liên thông' },
        { key: '/van-ban-danh-dau', icon: <StarOutlined />, label: 'Đánh dấu cá nhân' },
        { key: '/cau-hinh-gui-nhanh', icon: <SettingOutlined />, label: 'Cấu hình gửi nhanh' },
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
      label: badgeCounts.tinNhan > 0
        ? <span style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>Tin nhắn<span className="sidebar-badge">{badgeCounts.tinNhan}</span></span>
        : 'Tin nhắn',
    },
    {
      key: '/thong-bao',
      icon: <BellOutlined />,
      label: badgeCounts.thongBao > 0
        ? <span style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>Thông báo<span className="sidebar-badge">{badgeCounts.thongBao}</span></span>
        : 'Thông báo',
    },
    {
      key: 'lich',
      icon: <CalendarOutlined />,
      label: 'Lịch',
      children: [
        { key: '/lich/ca-nhan', icon: <UserOutlined />, label: 'Lịch cá nhân' },
        { key: '/lich/co-quan', icon: <BankOutlined />, label: 'Lịch cơ quan' },
        ...(isLeader || isAdmin ? [{ key: '/lich/lanh-dao', icon: <SolutionOutlined />, label: 'Lịch lãnh đạo' }] : []),
      ],
    },
    { key: '/danh-ba', icon: <ContactsOutlined />, label: 'Danh bạ' },
  ];

  // ── QUẢN LÝ ── (Admin, Lãnh đạo, Văn thư see this)
  if (canManage) {
    items.push(
      { key: 'grp-quanly', type: 'group', label: 'QUẢN LÝ' },
      {
        key: 'kho-luu-tru',
        icon: <DatabaseOutlined />,
        label: 'Kho lưu trữ',
        children: [
          { key: '/kho-luu-tru', icon: <DatabaseOutlined />, label: 'Danh mục kho/phông' },
          { key: '/kho-luu-tru/muon-tra', icon: <SwapOutlined />, label: 'Mượn/trả hồ sơ' },
        ],
      },
      { key: '/tai-lieu', icon: <FileTextOutlined />, label: 'Tài liệu' },
      { key: '/hop-dong', icon: <AuditOutlined />, label: 'Hợp đồng' },
      {
        key: 'cuoc-hop',
        icon: <TeamOutlined />,
        label: 'Cuộc họp',
        children: [
          { key: '/cuoc-hop', icon: <TeamOutlined />, label: 'Danh sách cuộc họp' },
          { key: '/cuoc-hop/thong-ke', icon: <AppstoreOutlined />, label: 'Thống kê' },
        ],
      },
    );
  }

  // ── TÍCH HỢP ── (Admin only for LGSP/notification config; partner links for everyone)
  if (isAdmin) {
    items.push(
      { key: 'grp-tichhop', type: 'group', label: 'TÍCH HỢP' },
      { key: '/lgsp', icon: <SwapOutlined />, label: 'Liên thông LGSP' },
      { key: '/lgsp/co-quan', icon: <BankOutlined />, label: 'Cơ quan liên thông' },
      { key: '/thong-bao-kenh', icon: <NotificationOutlined />, label: 'Kênh thông báo' },
    );
  }

  // ── ĐỐI TÁC ── (flat list, everyone can see)
  items.push(
    { key: 'grp-doitac', type: 'group', label: 'ĐỐI TÁC' },
    { key: 'ext-vnpt', icon: <LinkOutlined />, label: <a href="https://vinvoice.vn" target="_blank" rel="noopener noreferrer">Hóa đơn VNPT</a> },
    { key: 'ext-viettel', icon: <LinkOutlined />, label: <a href="https://sinvoice.viettel.vn" target="_blank" rel="noopener noreferrer">Hóa đơn Viettel</a> },
    { key: 'ext-bhxh', icon: <LinkOutlined />, label: <a href="https://dichvucong.baohiemxahoi.gov.vn" target="_blank" rel="noopener noreferrer">Bảo hiểm XH</a> },
    { key: 'ext-thue', icon: <LinkOutlined />, label: <a href="https://thuedientu.gdt.gov.vn" target="_blank" rel="noopener noreferrer">Thuế điện tử</a> },
  );

  // ── KÝ SỐ ── (Admin only — Plan 10 sẽ thêm menu user-level)
  if (isAdmin) {
    items.push(
      { key: 'grp-kyso', type: 'group', label: 'KÝ SỐ' },
      {
        key: '/ky-so/cau-hinh',
        icon: <SafetyCertificateOutlined />,
        label: 'Cấu hình ký số hệ thống',
      },
    );
  }

  // ── HỆ THỐNG ── (Admin only)
  if (isAdmin) {
    items.push(
      { key: 'grp-hethong', type: 'group', label: 'HỆ THỐNG' },
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
          { key: '/quan-tri/cau-hinh-truong', icon: <TableOutlined />, label: 'Thuộc tính văn bản' },
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
    );
  }

  return filterMenuItems(items);
}

// Map pathname to breadcrumb labels
const breadcrumbMap: Record<string, string> = {
  '/dashboard': 'Tổng quan',
  '/van-ban-den': 'Văn bản đến',
  '/van-ban-danh-dau': 'Đánh dấu cá nhân',
  '/cau-hinh-gui-nhanh': 'Cấu hình gửi nhanh',
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
  '/quan-tri/cau-hinh-truong': 'Thuộc tính văn bản',
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
  '/lgsp': 'Liên thông văn bản',
  '/lgsp/co-quan': 'Cơ quan liên thông',
  '/thong-bao-kenh': 'Cấu hình thông báo',
  '/ky-so': 'Ký số',
  '/ky-so/cau-hinh': 'Cấu hình ký số hệ thống',
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
function getOpenKeys(pathname: string, items: MenuItem[]): string[] {
  for (const item of items) {
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

  // Badge counts for sidebar menu items
  const [badgeCounts, setBadgeCounts] = useState<{ vbDen: number; tinNhan: number }>({ vbDen: 0, tinNhan: 0 });

  // Mobile responsive state
  const [isMobile, setIsMobile] = useState(false);
  const [mobileDrawerOpen, setMobileDrawerOpen] = useState(false);

  // Detect mobile viewport
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const mql = window.matchMedia('(max-width: 768px)');
    setIsMobile(mql.matches);
    const handler = (e: MediaQueryListEvent) => setIsMobile(e.matches);
    mql.addEventListener('change', handler);
    return () => mql.removeEventListener('change', handler);
  }, []);

  useEffect(() => {
    if (!user) {
      fetchMe();
    }
  }, [user, fetchMe]);

  // Fetch unread counts on mount (notifications + badge counts)
  useEffect(() => {
    const fetchCounts = async () => {
      try {
        const [notifRes, vbDenRes, tinNhanRes] = await Promise.allSettled([
          api.get('/thong-bao/unread-count'),
          api.get('/van-ban-den', { params: { status: 'pending', page: 1, page_size: 1 } }),
          api.get('/tin-nhan/unread-count'),
        ]);

        if (notifRes.status === 'fulfilled') {
          const d = notifRes.value.data;
          setNotifUnreadCount(d.data?.count ?? d.data ?? 0);
        }
        if (vbDenRes.status === 'fulfilled') {
          const d = vbDenRes.value.data;
          const total = d.data?.pagination?.total ?? d.data?.total ?? d.pagination?.total ?? 0;
          setBadgeCounts((prev) => ({ ...prev, vbDen: total }));
        }
        if (tinNhanRes.status === 'fulfilled') {
          const d = tinNhanRes.value.data;
          setBadgeCounts((prev) => ({ ...prev, tinNhan: d.data?.count ?? d.data ?? 0 }));
        }
      } catch {
        // Silent
      }
    };
    fetchCounts();
  }, []);

  // Socket.IO integration
  useEffect(() => {
    if (typeof window === 'undefined') return;
    const token = localStorage.getItem('accessToken');
    if (!token) return;

    const socket = initSocket(token);

    socket.on(SOCKET_EVENTS.NEW_MESSAGE, () => {
      message.info('Bạn có tin nhắn mới');
      setBadgeCounts((prev) => ({ ...prev, tinNhan: prev.tinNhan + 1 }));
    });

    socket.on(SOCKET_EVENTS.NEW_NOTIFICATION, (data: { title?: string }) => {
      message.info(data?.title || 'Thông báo mới');
      setNotifUnreadCount((prev) => prev + 1);
    });

    socket.on(SOCKET_EVENTS.NEW_DOCUMENT, () => {
      message.info('Có văn bản mới cần xử lý');
      setBadgeCounts((prev) => ({ ...prev, vbDen: prev.vbDen + 1 }));
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
    // External links open via <a> tag — skip router navigation
    if (key.startsWith('ext-')) return;
    router.push(key);
    // Auto-close mobile drawer on navigation
    if (isMobile) {
      setMobileDrawerOpen(false);
    }
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

  // Memoize menu items with badge counts + role-based filtering
  const menuItems = useMemo(
    () => buildMenuItems({
      badgeCounts: { vbDen: badgeCounts.vbDen, tinNhan: badgeCounts.tinNhan, thongBao: notifUnreadCount },
      isAdmin: user?.isAdmin ?? false,
      roles: user?.roles ?? [],
    }),
    [badgeCounts.vbDen, badgeCounts.tinNhan, notifUnreadCount, user?.isAdmin, user?.roles]
  );

  const breadcrumbItems = buildBreadcrumbs(pathname);
  const openKeys = getOpenKeys(pathname, menuItems);

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

  // Sidebar menu content — shared between Sider and mobile Drawer
  const sidebarMenuContent = (
    <>
      <div
        className="main-sider-logo"
        onClick={() => {
          router.push('/dashboard');
          if (isMobile) setMobileDrawerOpen(false);
        }}
        style={{ cursor: 'pointer' }}
      >
        <div className="main-sider-logo-icon">
          <FileTextOutlined style={{ fontSize: 22, color: '#0891B2' }} />
        </div>
        <div style={{ display: 'flex', flexDirection: 'column' }}>
          <span className="main-sider-logo-title">QLVB</span>
          <span className="main-sider-logo-sub">Văn bản điện tử</span>
        </div>
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
    </>
  );

  return (
    <Layout className="main-layout">
      {/* SIDEBAR — hidden on mobile */}
      {!isMobile && (
        <Sider
          trigger={null}
          collapsible
          collapsed={collapsed}
          width={260}
          collapsedWidth={72}
          className="main-sider"
        >
          {/* Logo */}
          <div
            className="main-sider-logo"
            onClick={() => router.push('/dashboard')}
            style={{ cursor: 'pointer' }}
          >
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
      )}

      {/* MOBILE DRAWER */}
      {isMobile && (
        <Drawer
          placement="left"
          open={mobileDrawerOpen}
          onClose={() => setMobileDrawerOpen(false)}
          size={280}
          closable={false}
          styles={{ body: { padding: 0, background: '#0F1A2E' } }}
        >
          {sidebarMenuContent}
        </Drawer>
      )}

      {/* MAIN AREA */}
      <Layout className={`main-area${!isMobile && collapsed ? ' collapsed' : ''}${isMobile ? ' mobile' : ''}`}>
        {/* HEADER */}
        <Header className="main-header">
          <div className="main-header-left">
            {isMobile ? (
              <div
                onClick={() => setMobileDrawerOpen(true)}
                className="main-collapse-btn"
              >
                <MenuOutlined style={{ fontSize: 18 }} />
              </div>
            ) : (
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
            )}
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
