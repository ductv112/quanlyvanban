'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { Layout, Menu, Avatar, Dropdown, Breadcrumb, Skeleton, App, Drawer } from 'antd';
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
import BellNotification from '@/components/notifications/BellNotification';
import { HIDDEN_ROUTES } from '@/config/hidden-routes';

const { Header, Sider, Content } = Layout;

type MenuItem = Required<MenuProps>['items'][number];

// Role names from seed data
const ADMIN_ROLE = 'Quản trị hệ thống';
const VAN_THU_ROLE = 'Văn thư';
const LANH_DAO_ROLE = 'Ban Lãnh đạo';
const CHI_DAO_ROLE = 'Chỉ đạo điều hành';

// BUG #44, #45: Filter menu key theo permission user (action_link cua right tuong ung).
// Khong gioi han neu user la admin (isAdmin=true) — backend cung tu dong tra full rights.
// Cac key bat dau bang 'grp-', 'ext-', 'lich' (parent submenu khong co route) duoc giu lai
// truoc khi filter children — neu children empty thi se bi drop o filterMenuItems().
function filterMenuItemsByPermissions(items: MenuItem[], allowed: Set<string>): MenuItem[] {
  const result: MenuItem[] = [];
  for (const item of items) {
    if (!item) continue;
    if ('type' in item && (item.type === 'group' || item.type === 'divider')) {
      result.push(item);
      continue;
    }
    const key = 'key' in item ? (item.key as string) : '';
    // Submenu parent khong co route truc tiep — luon giu, recurse vao children
    const isParent = 'children' in item && Array.isArray(item.children) && item.children.length > 0;
    if (isParent) {
      const filtered = filterMenuItemsByPermissions((item as any).children, allowed);
      if (filtered.length > 0) {
        result.push({ ...(item as any), children: filtered });
      }
      continue;
    }
    // External link (ext-*) hoac route khong khoa permission ('/') -> luon hien
    if (key.startsWith('ext-')) {
      result.push(item);
      continue;
    }
    // Cho phep neu key match exact 1 menuLink, hoac la prefix ('/quan-tri/' chap nhan
    // user co quyen vao tab con bat ky cua quan tri — vi du '/quan-tri/nguoi-dung').
    if (allowed.has(key)) {
      result.push(item);
      continue;
    }
    // Neu nguoi dung co bat ky right con cua nhom (vi du allowed has '/quan-tri/nguoi-dung'
    // -> giu cha '/quan-tri') -> handled qua isParent o tren. O day chi can match exact key.
  }
  return result;
}

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
  menuLinks: string[];
  userRights: ReadonlySet<number>;
}

// Right IDs từ public.rights table (xem fix backend granular permission)
const RIGHT_DON_VI = 14;
const RIGHT_NGUOI_DUNG = 15;
const RIGHT_NHOM_QUYEN = 16;
const RIGHT_CHUC_VU = 17;
const RIGHT_DANH_MUC = 18;
const RIGHT_KY_SO_CAU_HINH = 20;

// Menu builder filtered by user roles + rights (action_of_role)
function buildMenuItems({ badgeCounts, isAdmin, roles, menuLinks, userRights }: MenuBuildParams): MenuItem[] {
  const hasRole = (name: string) => roles.includes(name);
  const hasRight = (rightId: number) => isAdmin || userRights.has(rightId);
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
        // Phase 19 v3.0: BỎ menu 'Liên thông' — VB liên thông gộp vào 'Văn bản đến' với source_type='external_lgsp'
        // Tracking gửi LGSP hiển thị inline trong trang chi tiết VB đi (tab Người nhận)
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
        ? <span style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', width: '100%' }}>Thông báo nội bộ<span className="sidebar-badge">{badgeCounts.thongBao}</span></span>
        : 'Thông báo nội bộ',
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
      { key: '/lgsp', icon: <ApiOutlined />, label: 'Liên thông LGSP' },
      { key: '/lgsp/co-quan', icon: <BankOutlined />, label: 'Cơ quan liên thông' },
      { key: '/lgsp/cau-hinh', icon: <SettingOutlined />, label: 'Cấu hình kết nối' },
      { key: '/thong-bao-kenh', icon: <NotificationOutlined />, label: 'Kênh thông báo' },
    );
  }

  // ── KÝ SỐ ── (Group hiển thị cho MỌI user; submenu guard theo right granular)
  items.push({ key: 'grp-kyso', type: 'group', label: 'KÝ SỐ' });
  // Submenu Cấu hình ký số hệ thống — gate theo right 20 (action_of_role)
  if (hasRight(RIGHT_KY_SO_CAU_HINH)) {
    items.push({
      key: '/ky-so/cau-hinh',
      icon: <SafetyCertificateOutlined />,
      label: 'Cấu hình ký số hệ thống',
    });
  }
  // Submenu cho MỌI user: Tài khoản ký số cá nhân (Phase 10 Plan 02)
  items.push({
    key: '/ky-so/tai-khoan',
    icon: <SafetyCertificateOutlined />,
    label: 'Tài khoản ký số cá nhân',
  });
  // Submenu cho MỌI user: Danh sách ký số (Phase 12 Plan 01)
  items.push({
    key: '/ky-so/danh-sach',
    icon: <SafetyCertificateOutlined />,
    label: 'Danh sách ký số',
  });

  // ── ĐỐI TÁC ── (flat list, everyone can see)
  items.push(
    { key: 'grp-doitac', type: 'group', label: 'ĐỐI TÁC' },
    { key: 'ext-vnpt-invoice', icon: <LinkOutlined />, label: <a href="https://hst.vnpt-invoice.com.vn/login" target="_blank" rel="noopener noreferrer">VNPT Invoice</a> },
    { key: 'ext-vnpt-econtract', icon: <LinkOutlined />, label: <a href="https://econtract.vnpt.vn/" target="_blank" rel="noopener noreferrer">VNPT eContract</a> },
    { key: 'ext-vnpt-bhxh', icon: <LinkOutlined />, label: <a href="https://vnpt-bhxh.vn/" target="_blank" rel="noopener noreferrer">VNPT BHXH</a> },
    { key: 'ext-viettel-vinvoice', icon: <LinkOutlined />, label: <a href="https://vinvoice.viettel.vn/account/login" target="_blank" rel="noopener noreferrer">Viettel vInvoice</a> },
    { key: 'ext-viettel-econtract', icon: <LinkOutlined />, label: <a href="https://hopdongdientu.viettel.vn/enterprise-login" target="_blank" rel="noopener noreferrer">Viettel eContract</a> },
    { key: 'ext-viettel-vbhxh', icon: <LinkOutlined />, label: <a href="https://vbhxh.viettel.vn/dang-nhap" target="_blank" rel="noopener noreferrer">Viettel vBHXH</a> },
    { key: 'ext-kekhai-thue', icon: <LinkOutlined />, label: <a href="https://www.gdt.gov.vn/wps/portal/home/hotrokekhai" target="_blank" rel="noopener noreferrer">Kê khai thuế</a> },
  );

  // ── HỆ THỐNG ── (gate theo rights granular, không hardcode isAdmin)
  // Quản trị: hiện nếu user có bất kỳ right con (Đơn vị/Chức vụ/Người dùng/Nhóm quyền)
  const adminChildren = [
    hasRight(RIGHT_DON_VI) && { key: '/quan-tri/don-vi', icon: <ApartmentOutlined />, label: 'Đơn vị' },
    hasRight(RIGHT_CHUC_VU) && { key: '/quan-tri/chuc-vu', icon: <IdcardOutlined />, label: 'Chức vụ' },
    hasRight(RIGHT_NGUOI_DUNG) && { key: '/quan-tri/nguoi-dung', icon: <UserOutlined />, label: 'Người dùng' },
    hasRight(RIGHT_NHOM_QUYEN) && { key: '/quan-tri/nhom-quyen', icon: <KeyOutlined />, label: 'Nhóm quyền' },
    isAdmin && { key: '/quan-tri/chuc-nang', icon: <AppstoreOutlined />, label: 'Chức năng' },
  ].filter(Boolean) as MenuItem[];

  // Danh mục: hiện nếu có right 18 (Danh mục) — tất cả sub-item nằm chung
  const catalogChildren = hasRight(RIGHT_DANH_MUC) ? [
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
  ] as MenuItem[] : [];

  if (adminChildren.length > 0 || catalogChildren.length > 0) {
    items.push({ key: 'grp-hethong', type: 'group', label: 'HỆ THỐNG' });
    if (adminChildren.length > 0) {
      items.push({
        key: 'quan-tri',
        icon: <SettingOutlined />,
        label: 'Quản trị',
        children: adminChildren,
      });
    }
    if (catalogChildren.length > 0) {
      items.push({
        key: 'danh-muc',
        icon: <BookOutlined />,
        label: 'Danh mục',
        children: catalogChildren,
      });
    }
  }

  // BUG #44, #45: Sau khi build full menu theo role, ap them filter theo
  // permission action_link. Admin -> menuLinks da chua tat ca rights nen het
  // truoc filter; non-admin chua duoc cap right -> filter ra rong.
  let filtered = filterMenuItems(items);
  if (!isAdmin) {
    const allowed = new Set(menuLinks || []);
    // Fix 2026-05-14: Parent right (Danh muc) auto-expand sub action_links.
    // Rights table chi co 22 records (1 Danh muc parent, KHONG co rieng cho 12
    // sub-catalog). Khi user duoc cap right "Danh muc" -> expand de 12 sub
    // items qua duoc filter.
    if (allowed.has('/quan-tri/danh-muc')) {
      [
        '/quan-tri/so-van-ban', '/quan-tri/loai-van-ban', '/quan-tri/linh-vuc',
        '/quan-tri/cau-hinh-truong', '/quan-tri/co-quan', '/quan-tri/nguoi-ky',
        '/quan-tri/nhom-lam-viec', '/quan-tri/uy-quyen', '/quan-tri/dia-ban',
        '/quan-tri/lich-lam-viec', '/quan-tri/mau-thong-bao', '/quan-tri/cau-hinh',
        '/quan-tri/thuoc-tinh-van-ban',
      ].forEach((p) => allowed.add(p));
    }
    filtered = filterMenuItemsByPermissions(filtered, allowed);
  }
  return filtered;
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
  '/thong-bao': 'Thông báo nội bộ',
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
  '/lgsp/cau-hinh': 'Cấu hình kết nối LGSP',
  '/thong-bao-kenh': 'Cấu hình thông báo',
  '/ky-so': 'Ký số',
  '/ky-so/cau-hinh': 'Cấu hình ký số hệ thống',
  '/ky-so/tai-khoan': 'Tài khoản ký số cá nhân',
  '/ky-so/danh-sach': 'Danh sách ký số',
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
  // Mặc định mở sẵn menu "Văn bản" (submenu nghiệp vụ chính)
  const openKeys = new Set<string>(['van-ban']);
  for (const item of items) {
    if (item && 'children' in item && item.children) {
      for (const child of item.children) {
        if (child && 'key' in child && pathname.startsWith(child.key as string)) {
          openKeys.add(item.key as string);
        }
      }
    }
  }
  return Array.from(openKeys);
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function MainLayout({ children }: { children: React.ReactNode }) {
  const [collapsed, setCollapsed] = useState(false);
  const router = useRouter();
  const pathname = usePathname();
  const { user, isLoading, fetchMe, logout } = useAuthStore();
  const { modal, message } = App.useApp();

  // Sidebar menu badge count cho '/thong-bao' route (legacy /api/thong-bao unit-wide).
  // Header bell icon đã migrate sang <BellNotification /> consume /api/notifications riêng.
  const [notifUnreadCount, setNotifUnreadCount] = useState(0);

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

  // Fetch user rights từ /chuc-nang/menu để gate menu items granular (Phase 2 perm fix).
  // Note: JWT user.menuLinks (action_link strings) cũng được dùng cho filterMenuItemsByPermissions.
  const [userRights, setUserRights] = useState<ReadonlySet<number>>(new Set());
  useEffect(() => {
    if (!user) return;
    api.get('/quan-tri/chuc-nang/menu')
      .then((res) => {
        const ids = (res.data?.data || []).map((r: { id: number }) => r.id);
        setUserRights(new Set<number>(ids));
      })
      .catch(() => setUserRights(new Set()));
  }, [user?.staffId]);

  // Memoize menu items with badge counts + role + rights + menuLinks filtering
  const menuItems = useMemo(
    () => buildMenuItems({
      badgeCounts: { vbDen: badgeCounts.vbDen, tinNhan: badgeCounts.tinNhan, thongBao: notifUnreadCount },
      isAdmin: user?.isAdmin ?? false,
      roles: user?.roles ?? [],
      menuLinks: user?.menuLinks ?? [],
      userRights,
    }),
    [badgeCounts.vbDen, badgeCounts.tinNhan, notifUnreadCount, user?.isAdmin, user?.roles, user?.menuLinks, userRights]
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
            {/* Phase 13 — personal bell notification (consume /api/notifications) */}
            <BellNotification />

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
