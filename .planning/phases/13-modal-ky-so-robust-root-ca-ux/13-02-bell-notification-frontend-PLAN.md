---
phase: 13
plan: 02
type: execute
wave: 2
depends_on: [13-01]
files_modified:
  - e_office_app_new/frontend/src/components/layout/MainLayout.tsx
  - e_office_app_new/frontend/src/lib/api-notifications.ts
  - e_office_app_new/frontend/src/components/notifications/BellNotification.tsx
autonomous: true
requirements:
  - UX-10
tags: [frontend, bell, antd6, socket, notifications, toast, header]
must_haves:
  truths:
    - "Icon BellOutlined + Badge unreadCount hiển thị trong header MainLayout (đã có — hoán đổi datasource qua /api/notifications)"
    - "Dropdown click mở ra hiển thị 10 notification gần nhất với icon status + title + message + relative time (dayjs fromNow vi)"
    - "Click item navigate tới link của item + mark read"
    - "Button 'Đánh dấu đã đọc tất cả' call PATCH /read-all + refresh count=0"
    - "Socket event sign_completed/sign_failed → toast AntD notification.success/.error 3s + increment badge + refresh dropdown cache"
    - "User offline khi nhận sign_completed → đăng nhập lại vẫn thấy notification trong dropdown qua GET /api/notifications"
  artifacts:
    - path: "e_office_app_new/frontend/src/lib/api-notifications.ts"
      provides: "API client wrappers: listNotifications, unreadCount, markRead, markAllRead"
      exports: ["listNotifications", "unreadCount", "markRead", "markAllRead", "type PersonalNotification"]
    - path: "e_office_app_new/frontend/src/components/notifications/BellNotification.tsx"
      provides: "Self-contained bell component — Badge + BellOutlined + Dropdown + list items + toast handler"
      exports: ["default"]
    - path: "e_office_app_new/frontend/src/components/layout/MainLayout.tsx"
      provides: "Replace inline bell block với <BellNotification /> component + remove cũ unread count fetch cho /thong-bao (giữ nguyên fetch cho văn bản đến + tin nhắn)"
      contains: "import BellNotification"
  key_links:
    - from: "BellNotification.tsx"
      to: "/api/notifications"
      via: "api.get/.patch qua api-notifications.ts"
      pattern: "/notifications(\\?|/unread-count|/read-all|/\\d+/read)"
    - from: "BellNotification.tsx"
      to: "SOCKET_EVENTS.SIGN_COMPLETED / SIGN_FAILED"
      via: "socket.on listener"
      pattern: "SOCKET_EVENTS\\.SIGN_(COMPLETED|FAILED)"
    - from: "MainLayout.tsx"
      to: "BellNotification component"
      via: "import + mount trong main-header-right"
      pattern: "<BellNotification"
---

<objective>
Tạo component bell notification độc lập consume `/api/notifications` (Plan 13-01 backend) và replace bell logic hiện tại trong `MainLayout.tsx` (hiện đang dùng `/api/thong-bao` unit-wide notice). Yêu cầu D-08 → D-12:

1. `BellOutlined` + `<Badge count={unread}>` trong header position TRƯỚC avatar (giữ position hiện tại của MainLayout).
2. Click mở Dropdown/Popover 10 items gần nhất + button "Đánh dấu đã đọc tất cả" + link "Xem tất cả" (stub — Phase 13 KHÔNG tạo trang detail, chỉ stub hoặc remove link).
3. Mỗi item: icon status (✓ xanh cho `sign_completed`, ✗ đỏ cho `sign_failed`) + title + message (ellipsis) + relative time `dayjs.fromNow()` vi locale.
4. Click item → navigate `item.link` + `PATCH /:id/read` + refresh list + decrement badge.
5. Socket event `SIGN_COMPLETED` / `SIGN_FAILED` (đã có Phase 11) → toast AntD `notification.success/.error` 3s + increment badge + refresh dropdown nếu đang mở. Defense-in-depth filter `payload` theo `transaction_id` là không cần (BE emit room user_{staffId}) nhưng giữ thông tin để phân loại.
6. Stale-while-revalidate pattern: khi mở dropdown, render cache cũ ngay + fetch mới background.

**KHÔNG thuộc scope Plan 13-02:**
- Trang `/thong-bao` detail redesign (giữ nguyên hoạt động với /api/thong-bao unit-wide hiện tại — coexist)
- Cleanup legacy `handleBellOpenChange` + `notifUnreadCount` state cho `/thong-bao` — có thể giữ song song hoặc unify sau. Plan 13-02 CHỈ swap bell source từ `/api/thong-bao` sang `/api/notifications`.

**Coexistence strategy (quan trọng):**
- Backend đã có `/api/thong-bao` (unit-wide notice, tồn tại từ Phase 3) và `/api/notifications` mới (personal — Plan 13-01).
- Frontend bell icon hiện DẢO sang consume `/api/notifications`.
- Menu sidebar "Thông báo" (`/thong-bao` route) GIỮ NGUYÊN consume `/api/thong-bao` (backwards-compat, không phá Phase 3 functionality).
- Badge count sidebar "Thông báo" giữ nguyên từ `/api/thong-bao/unread-count` — độc lập với bell badge header.

Output: 2 files mới + 1 modify.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md
@.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-01-notification-backend-infrastructure-PLAN.md
@CLAUDE.md
@e_office_app_new/frontend/CLAUDE.md
@e_office_app_new/frontend/AGENTS.md

<interfaces>
<!-- Hiện tại BellNotification block trong MainLayout.tsx (line ~824-837) đang consume /api/thong-bao: -->

```tsx
// Đang có:
<Dropdown
  open={bellOpen}
  onOpenChange={handleBellOpenChange}   // fetch /thong-bao
  placement="bottomRight"
  trigger={['click']}
  popupRender={() => bellDropdownContent}
>
  <Badge count={notifUnreadCount} size="small" overflowCount={99}>
    <BellOutlined className="main-header-icon" style={{ cursor: 'pointer' }} />
  </Badge>
</Dropdown>
```

**Replace block này với:**
```tsx
<BellNotification />  // Self-contained, manage state + socket + API internally
```

**Component skeleton BellNotification.tsx (pseudo):**
```tsx
'use client';
import { useState, useEffect, useCallback } from 'react';
import { Dropdown, Badge, Button, Typography, App, Empty, Spin } from 'antd';
import {
  BellOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
} from '@ant-design/icons';
import { useRouter } from 'next/navigation';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/vi';
import { getSocket, SOCKET_EVENTS } from '@/lib/socket';
import {
  listNotifications,
  unreadCount as fetchUnreadCount,
  markRead,
  markAllRead,
  type PersonalNotification,
} from '@/lib/api-notifications';
import type { SignCompletedEvent, SignFailedEvent } from '@/lib/signing/types';

dayjs.extend(relativeTime);
dayjs.locale('vi');

const { Text } = Typography;

export default function BellNotification() {
  const router = useRouter();
  const { notification } = App.useApp();

  const [items, setItems] = useState<PersonalNotification[]>([]);
  const [unread, setUnread] = useState(0);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  // Initial fetch unread count
  useEffect(() => {
    fetchUnreadCount().then(setUnread).catch(() => {/* silent */});
  }, []);

  // Fetch list on open (stale-while-revalidate — render cached items immediately)
  const handleOpenChange = useCallback(async (nextOpen: boolean) => {
    setOpen(nextOpen);
    if (!nextOpen) return;
    setLoading(true);
    try {
      const res = await listNotifications(1, 10);
      setItems(res.data);
      // Refresh count while we're at it
      const c = await fetchUnreadCount();
      setUnread(c);
    } catch {/* silent */} finally { setLoading(false); }
  }, []);

  // Socket listeners → toast + badge + refresh cache
  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const onCompleted = (payload: SignCompletedEvent) => {
      notification.success({
        message: 'Ký số thành công',
        description: `Giao dịch #${payload.transaction_id} đã hoàn tất`,
        duration: 3,
        placement: 'topRight',
      });
      setUnread((n) => n + 1);
      // Stale refresh nếu dropdown đang mở
      if (open) listNotifications(1, 10).then((r) => setItems(r.data)).catch(() => {/* silent */});
    };

    const onFailed = (payload: SignFailedEvent) => {
      notification.error({
        message: payload.status === 'expired' ? 'Ký số hết hạn' : 'Ký số thất bại',
        description: payload.error_message || `Giao dịch #${payload.transaction_id}`,
        duration: 3,
        placement: 'topRight',
      });
      setUnread((n) => n + 1);
      if (open) listNotifications(1, 10).then((r) => setItems(r.data)).catch(() => {/* silent */});
    };

    socket.on(SOCKET_EVENTS.SIGN_COMPLETED, onCompleted);
    socket.on(SOCKET_EVENTS.SIGN_FAILED, onFailed);

    return () => {
      socket.off(SOCKET_EVENTS.SIGN_COMPLETED, onCompleted);
      socket.off(SOCKET_EVENTS.SIGN_FAILED, onFailed);
    };
  }, [notification, open]);

  // Click item → navigate + mark read
  const handleItemClick = useCallback(async (item: PersonalNotification) => {
    setOpen(false);
    try {
      if (!item.is_read) {
        await markRead(item.id);
        setItems((arr) => arr.map((x) => (x.id === item.id ? { ...x, is_read: true } : x)));
        setUnread((n) => Math.max(0, n - 1));
      }
    } catch {/* silent */}
    if (item.link) router.push(item.link);
  }, [router]);

  // Mark all read
  const handleMarkAllRead = useCallback(async () => {
    try {
      const res = await markAllRead();
      setItems((arr) => arr.map((x) => ({ ...x, is_read: true })));
      setUnread(0);
      // optional toast: message.success(`Đã đánh dấu ${res.updated_count} thông báo là đã đọc`);
    } catch {/* silent */}
  }, []);

  const iconForType = (type: string) => {
    if (type === 'sign_completed') return <CheckCircleOutlined style={{ color: '#059669', fontSize: 16 }} />;
    if (type === 'sign_failed')    return <CloseCircleOutlined style={{ color: '#DC2626', fontSize: 16 }} />;
    return <BellOutlined style={{ color: '#0891B2', fontSize: 16 }} />;
  };

  const dropdownContent = (
    <div style={{ width: 380, maxHeight: 480, overflow: 'auto', background: '#FFFFFF', borderRadius: 8, boxShadow: '0 6px 20px rgba(0,0,0,0.1)' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px', borderBottom: '1px solid #F1F5F9' }}>
        <Text style={{ fontSize: 16, fontWeight: 600, color: '#1B3A5C' }}>Thông báo</Text>
        <Button
          type="link"
          size="small"
          disabled={unread === 0}
          onClick={handleMarkAllRead}
          style={{ fontSize: 12, color: '#0891B2', padding: 0 }}
        >
          Đánh dấu đã đọc tất cả
        </Button>
      </div>
      {loading && items.length === 0 ? (
        <div style={{ padding: '16px', textAlign: 'center' }}><Spin /></div>
      ) : items.length === 0 ? (
        <Empty image={Empty.PRESENTED_IMAGE_SIMPLE} description="Không có thông báo" style={{ padding: '24px 0' }} />
      ) : (
        items.map((item) => (
          <div
            key={item.id}
            className={`notif-item${!item.is_read ? ' unread' : ''}`}
            onClick={() => handleItemClick(item)}
            style={{
              display: 'flex', gap: 12, padding: '12px 16px',
              cursor: 'pointer',
              borderBottom: '1px solid #F1F5F9',
              background: !item.is_read ? '#F0F9FF' : '#FFFFFF',
            }}
          >
            <div style={{ flexShrink: 0, marginTop: 2 }}>{iconForType(item.type)}</div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13, fontWeight: !item.is_read ? 600 : 400, color: '#1B3A5C', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {item.title}
              </div>
              {item.message && (
                <div style={{ fontSize: 12, color: '#475569', marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {item.message}
                </div>
              )}
              <div style={{ fontSize: 11, color: '#94A3B8', marginTop: 4 }}>
                {dayjs(item.created_at).fromNow()}
              </div>
            </div>
          </div>
        ))
      )}
    </div>
  );

  return (
    <Dropdown
      open={open}
      onOpenChange={handleOpenChange}
      placement="bottomRight"
      trigger={['click']}
      popupRender={() => dropdownContent}
    >
      <Badge count={unread} size="small" overflowCount={99}>
        <BellOutlined className="main-header-icon" style={{ cursor: 'pointer' }} />
      </Badge>
    </Dropdown>
  );
}
```

**api-notifications.ts skeleton (pseudo):**
```typescript
import { api } from './api';

export interface PersonalNotification {
  id: number;
  type: string;
  title: string;
  message: string | null;
  link: string | null;
  metadata: Record<string, unknown> | null;
  is_read: boolean;
  created_at: string;  // ISO string
  read_at: string | null;
}

export interface ListResponse {
  success: boolean;
  data: PersonalNotification[];
  pagination: { total: number; page: number; pageSize: number };
}

export async function listNotifications(page: number, pageSize: number): Promise<ListResponse> {
  const { data } = await api.get('/notifications', { params: { page, page_size: pageSize } });
  return data;
}

export async function unreadCount(): Promise<number> {
  const { data } = await api.get('/notifications/unread-count');
  return Number(data?.data?.count ?? 0);
}

export async function markRead(id: number): Promise<void> {
  await api.patch(`/notifications/${id}/read`);
}

export async function markAllRead(): Promise<{ updated_count: number }> {
  const { data } = await api.patch('/notifications/read-all');
  return { updated_count: Number(data?.data?.updated_count ?? 0) };
}
```

**CHÚ Ý api path:** axios instance `api` có `baseURL='/api'` sẵn → dùng path `/notifications` (không `/api/notifications`). Khớp convention Plan 12-02 (`/ky-so/...`).
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Tạo lib/api-notifications.ts (API client wrappers)</name>
  <files>e_office_app_new/frontend/src/lib/api-notifications.ts</files>
  <read_first>
    - `e_office_app_new/frontend/src/lib/api.ts` (axios instance + baseURL pattern — confirm `/api` đã có)
    - `e_office_app_new/frontend/src/lib/signing/types.ts` (types pattern — snake_case khớp BE output)
    - `e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx` dòng 32-62 (import pattern + api.get convention)
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-01-notification-backend-infrastructure-PLAN.md` section `<interfaces>` (Response shapes từ BE)
  </read_first>
  <action>
Tạo file mới `e_office_app_new/frontend/src/lib/api-notifications.ts` với content:

```typescript
/**
 * API client cho bell notifications (Phase 13).
 * Consume endpoints backend Plan 13-01:
 *   GET    /api/notifications?page=1&page_size=10
 *   GET    /api/notifications/unread-count
 *   PATCH  /api/notifications/:id/read
 *   PATCH  /api/notifications/read-all
 *
 * Axios instance @/lib/api có baseURL='/api' sẵn → path dùng '/notifications/...'
 * KHÔNG '/api/notifications/...' (tránh double /api/, khớp convention Plan 12-02).
 */

import { api } from './api';

// =============================================================================
// Types (snake_case khớp BE — CLAUDE.md checklist #1)
// =============================================================================

export interface PersonalNotification {
  id: number;
  type: string;        // 'sign_completed' | 'sign_failed' (Phase 13 scope)
  title: string;
  message: string | null;
  link: string | null;
  metadata: Record<string, unknown> | null;
  is_read: boolean;
  created_at: string;  // ISO 8601 — pg driver trả string (CLAUDE.md checklist #8)
  read_at: string | null;
}

export interface ListResponse {
  success: boolean;
  data: PersonalNotification[];
  pagination: {
    total: number;
    page: number;
    pageSize: number;
  };
}

export interface UnreadCountResponse {
  success: boolean;
  data: { count: number };
}

export interface MarkAllReadResponse {
  success: boolean;
  data: { updated_count: number; message: string };
}

// =============================================================================
// API calls
// =============================================================================

/** List notifications — page 1-based, pageSize max 100 (cap BE). */
export async function listNotifications(
  page: number = 1,
  pageSize: number = 10,
): Promise<ListResponse> {
  const { data } = await api.get<ListResponse>('/notifications', {
    params: { page, page_size: pageSize },  // snake_case backend convention
  });
  return data;
}

/** Unread count — dùng cho badge. */
export async function unreadCount(): Promise<number> {
  const { data } = await api.get<UnreadCountResponse>('/notifications/unread-count');
  return Number(data?.data?.count ?? 0);
}

/** Mark 1 notification đã đọc. Owner check BE-side (IDOR mitigation T-13-02). */
export async function markRead(id: number): Promise<void> {
  await api.patch(`/notifications/${id}/read`);
}

/** Mark tất cả notification của current user đã đọc. */
export async function markAllRead(): Promise<{ updated_count: number }> {
  const { data } = await api.patch<MarkAllReadResponse>('/notifications/read-all');
  return { updated_count: Number(data?.data?.updated_count ?? 0) };
}
```

Lưu file. Chạy TypeScript check:
```bash
cd e_office_app_new/frontend
npx tsc --noEmit 2>&1 | grep -E "lib/api-notifications" | (! grep -q "error TS")
```
  </action>
  <verify>
<automated>
test -f e_office_app_new/frontend/src/lib/api-notifications.ts && \
grep -q "export async function listNotifications" e_office_app_new/frontend/src/lib/api-notifications.ts && \
grep -q "export async function unreadCount" e_office_app_new/frontend/src/lib/api-notifications.ts && \
grep -q "export async function markRead" e_office_app_new/frontend/src/lib/api-notifications.ts && \
grep -q "export async function markAllRead" e_office_app_new/frontend/src/lib/api-notifications.ts && \
grep -q "export interface PersonalNotification" e_office_app_new/frontend/src/lib/api-notifications.ts && \
grep -q "/notifications" e_office_app_new/frontend/src/lib/api-notifications.ts && \
! grep -q "'/api/notifications" e_office_app_new/frontend/src/lib/api-notifications.ts && \
cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | grep -E "lib/api-notifications\.ts" | (! grep -q "error TS") && \
echo "Task 1 OK"
</automated>
  </verify>
  <done>
    - File tồn tại với 4 exported async functions + 3 response interfaces + 1 domain interface
    - Path dùng `/notifications` (KHÔNG `/api/notifications` — axios baseURL đã có /api)
    - page param snake_case: `page_size` (khớp BE)
    - TypeScript clean
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Tạo components/notifications/BellNotification.tsx (self-contained bell component)</name>
  <files>e_office_app_new/frontend/src/components/notifications/BellNotification.tsx</files>
  <read_first>
    - `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` dòng 630-703 (bellDropdownContent hiện có — style reference)
    - `e_office_app_new/frontend/src/lib/socket.ts` (SOCKET_EVENTS.SIGN_COMPLETED / SIGN_FAILED đã có từ Phase 11)
    - `e_office_app_new/frontend/src/lib/signing/types.ts` (SignCompletedEvent / SignFailedEvent)
    - `e_office_app_new/frontend/src/lib/api-notifications.ts` (file vừa tạo Task 1)
    - `e_office_app_new/frontend/src/app/globals.css` (tìm class `.notif-item` và `.notif-bell-overlay` — giữ dùng style hiện có để thống nhất)
    - `e_office_app_new/frontend/AGENTS.md` — Next.js version mới, đọc `node_modules/next/dist/docs/` nếu cần route API mới; nhưng với client component chỉ cần `'use client'` + `useRouter` từ `next/navigation`
  </read_first>
  <action>
Tạo folder + file mới `e_office_app_new/frontend/src/components/notifications/BellNotification.tsx`:

```tsx
'use client';

/**
 * BellNotification — Self-contained bell component cho Phase 13 UX-10.
 *
 * Consume /api/notifications (Plan 13-01) thay thế /api/thong-bao legacy cho bell icon.
 * Manage state nội bộ: unread count, item list, open state, loading.
 *
 * Socket integration: lắng nghe SIGN_COMPLETED / SIGN_FAILED (Phase 11 events) →
 *   toast AntD notification.success/.error 3s + increment badge + refresh list nếu đang mở.
 *
 * Stale-while-revalidate: khi mở dropdown, render cache cũ ngay + fetch mới background.
 * Initial fetch unreadCount on mount để badge hiển thị đúng ngay.
 *
 * Decision references (13-CONTEXT.md):
 *   D-08: BellOutlined + Badge trong header — position giữ nguyên MainLayout hiện tại
 *   D-09: Dropdown 10 items + button "Đánh dấu đã đọc tất cả"
 *   D-10: Icon status + title + message + relative time (dayjs.fromNow vi)
 *   D-11: Toast AntD notification.success/.error 3s (online)
 *   D-12: Stale-while-revalidate fetch khi mở dropdown
 */

import { useCallback, useEffect, useState } from 'react';
import { App, Badge, Button, Dropdown, Empty, Spin, Typography } from 'antd';
import {
  BellOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
} from '@ant-design/icons';
import { useRouter } from 'next/navigation';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/vi';
import { getSocket, SOCKET_EVENTS } from '@/lib/socket';
import {
  listNotifications,
  unreadCount as fetchUnreadCount,
  markRead,
  markAllRead,
  type PersonalNotification,
} from '@/lib/api-notifications';
import type {
  SignCompletedEvent,
  SignFailedEvent,
} from '@/lib/signing/types';

dayjs.extend(relativeTime);
dayjs.locale('vi');

const { Text } = Typography;

const PAGE_SIZE = 10;
const TOAST_DURATION = 3;

function iconForType(type: string): React.ReactNode {
  if (type === 'sign_completed') {
    return <CheckCircleOutlined style={{ color: '#059669', fontSize: 16 }} />;
  }
  if (type === 'sign_failed') {
    return <CloseCircleOutlined style={{ color: '#DC2626', fontSize: 16 }} />;
  }
  return <BellOutlined style={{ color: '#0891B2', fontSize: 16 }} />;
}

export default function BellNotification() {
  const router = useRouter();
  const { notification } = App.useApp();

  const [items, setItems] = useState<PersonalNotification[]>([]);
  const [unread, setUnread] = useState(0);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  // ---- Initial badge fetch (mount) ----
  useEffect(() => {
    fetchUnreadCount()
      .then(setUnread)
      .catch(() => {
        /* silent — không force user thấy error */
      });
  }, []);

  // ---- Refresh list (stale-while-revalidate) ----
  const refreshList = useCallback(async () => {
    setLoading(true);
    try {
      const res = await listNotifications(1, PAGE_SIZE);
      setItems(res.data);
      const c = await fetchUnreadCount();
      setUnread(c);
    } catch {
      /* silent */
    } finally {
      setLoading(false);
    }
  }, []);

  // ---- Dropdown open handler ----
  const handleOpenChange = useCallback(
    async (nextOpen: boolean) => {
      setOpen(nextOpen);
      if (!nextOpen) return;
      // Render cached items immediately; fetch replaces when done
      await refreshList();
    },
    [refreshList],
  );

  // ---- Socket listeners ----
  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const onCompleted = (payload: SignCompletedEvent) => {
      notification.success({
        message: 'Ký số thành công',
        description: `Giao dịch #${payload.transaction_id} đã hoàn tất`,
        duration: TOAST_DURATION,
        placement: 'topRight',
      });
      setUnread((n) => n + 1);
      // Refresh list nếu dropdown đang mở — user không cần đóng-mở lại để thấy item mới
      if (open) {
        listNotifications(1, PAGE_SIZE)
          .then((r) => setItems(r.data))
          .catch(() => {
            /* silent */
          });
      }
    };

    const onFailed = (payload: SignFailedEvent) => {
      notification.error({
        message:
          payload.status === 'expired'
            ? 'Ký số hết hạn'
            : payload.status === 'cancelled'
              ? 'Đã hủy ký số'
              : 'Ký số thất bại',
        description:
          payload.error_message ||
          `Giao dịch #${payload.transaction_id}`,
        duration: TOAST_DURATION,
        placement: 'topRight',
      });
      setUnread((n) => n + 1);
      if (open) {
        listNotifications(1, PAGE_SIZE)
          .then((r) => setItems(r.data))
          .catch(() => {
            /* silent */
          });
      }
    };

    socket.on(SOCKET_EVENTS.SIGN_COMPLETED, onCompleted);
    socket.on(SOCKET_EVENTS.SIGN_FAILED, onFailed);

    return () => {
      socket.off(SOCKET_EVENTS.SIGN_COMPLETED, onCompleted);
      socket.off(SOCKET_EVENTS.SIGN_FAILED, onFailed);
    };
  }, [notification, open]);

  // ---- Item click: mark read + navigate ----
  const handleItemClick = useCallback(
    async (item: PersonalNotification) => {
      setOpen(false);
      // Optimistic update
      if (!item.is_read) {
        setItems((arr) =>
          arr.map((x) => (x.id === item.id ? { ...x, is_read: true } : x)),
        );
        setUnread((n) => Math.max(0, n - 1));
        try {
          await markRead(item.id);
        } catch {
          // Revert optimistic update nếu fail — nhưng hiếm vì BE SP rất nhanh
          // silent — user đã rời dropdown
        }
      }
      if (item.link) {
        router.push(item.link);
      }
    },
    [router],
  );

  // ---- Mark all read ----
  const handleMarkAllRead = useCallback(async () => {
    try {
      await markAllRead();
      setItems((arr) => arr.map((x) => ({ ...x, is_read: true })));
      setUnread(0);
    } catch {
      /* silent */
    }
  }, []);

  // ---- Dropdown content ----
  const dropdownContent = (
    <div
      style={{
        width: 380,
        maxHeight: 480,
        overflow: 'auto',
        background: '#FFFFFF',
        borderRadius: 8,
        boxShadow: '0 6px 20px rgba(0, 0, 0, 0.1)',
      }}
    >
      {/* Header */}
      <div
        style={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          padding: '12px 16px',
          borderBottom: '1px solid #F1F5F9',
          position: 'sticky',
          top: 0,
          background: '#FFFFFF',
          zIndex: 1,
        }}
      >
        <Text style={{ fontSize: 16, fontWeight: 600, color: '#1B3A5C' }}>
          Thông báo
        </Text>
        <Button
          type="link"
          size="small"
          disabled={unread === 0}
          onClick={handleMarkAllRead}
          style={{ fontSize: 12, color: '#0891B2', padding: 0 }}
        >
          Đánh dấu đã đọc tất cả
        </Button>
      </div>

      {/* Body */}
      {loading && items.length === 0 ? (
        <div style={{ padding: '24px 0', textAlign: 'center' }}>
          <Spin />
        </div>
      ) : items.length === 0 ? (
        <Empty
          image={Empty.PRESENTED_IMAGE_SIMPLE}
          description={
            <Text type="secondary" style={{ fontSize: 13 }}>
              Không có thông báo
            </Text>
          }
          style={{ padding: '24px 0' }}
        />
      ) : (
        items.map((item) => (
          <div
            key={item.id}
            onClick={() => handleItemClick(item)}
            style={{
              display: 'flex',
              gap: 12,
              padding: '12px 16px',
              cursor: 'pointer',
              borderBottom: '1px solid #F1F5F9',
              background: !item.is_read ? '#F0F9FF' : '#FFFFFF',
              transition: 'background 0.2s',
            }}
            onMouseEnter={(e) => {
              e.currentTarget.style.background = '#E0F2FE';
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.background = !item.is_read
                ? '#F0F9FF'
                : '#FFFFFF';
            }}
          >
            <div style={{ flexShrink: 0, marginTop: 2 }}>
              {iconForType(item.type)}
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div
                style={{
                  fontSize: 13,
                  fontWeight: !item.is_read ? 600 : 400,
                  color: '#1B3A5C',
                  overflow: 'hidden',
                  textOverflow: 'ellipsis',
                  whiteSpace: 'nowrap',
                }}
              >
                {item.title}
              </div>
              {item.message && (
                <div
                  style={{
                    fontSize: 12,
                    color: '#475569',
                    marginTop: 2,
                    overflow: 'hidden',
                    textOverflow: 'ellipsis',
                    whiteSpace: 'nowrap',
                  }}
                >
                  {item.message}
                </div>
              )}
              <div
                style={{
                  fontSize: 11,
                  color: '#94A3B8',
                  marginTop: 4,
                }}
              >
                {dayjs(item.created_at).fromNow()}
              </div>
            </div>
          </div>
        ))
      )}
    </div>
  );

  return (
    <Dropdown
      open={open}
      onOpenChange={handleOpenChange}
      placement="bottomRight"
      trigger={['click']}
      popupRender={() => dropdownContent}
    >
      <Badge count={unread} size="small" overflowCount={99}>
        <BellOutlined
          className="main-header-icon"
          style={{ cursor: 'pointer', fontSize: 20 }}
        />
      </Badge>
    </Dropdown>
  );
}
```

Lưu file. Run TypeScript check:
```bash
cd e_office_app_new/frontend
npx tsc --noEmit 2>&1 | grep -E "components/notifications" | (! grep -q "error TS")
```

Chú ý checklist:
- **CLAUDE.md #4:** `type: string` trong interface là OK (TypeScript, không SQL). SQL reserved words chỉ áp dụng khi SELECT/RETURNS TABLE.
- **AntD 6 APIs:** Dropdown dùng `popupRender` (không `overlay` deprecated). Badge đã dùng đúng. Button dùng `type="link"` + `size="small"` — đúng AntD 6.
- **Vietnamese diacritics:** "Thông báo", "Đánh dấu đã đọc tất cả", "Không có thông báo", "Ký số thành công", "Ký số thất bại", "Ký số hết hạn", "Đã hủy ký số" — CHECK.
- **No inline layout:** Layout structure dùng style inline cho component độc lập, nhưng vì đây là component nhỏ 1 file và không có layout-level CSS class có sẵn cho dropdown overlay nên chấp nhận. Nếu `e_office_app_new/frontend/src/app/globals.css` đã có class `.notif-bell-overlay` + `.notif-item` (grep để confirm), dùng lại.
  </action>
  <verify>
<automated>
test -f e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "export default function BellNotification" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "SOCKET_EVENTS.SIGN_COMPLETED" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "SOCKET_EVENTS.SIGN_FAILED" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "BellOutlined" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "Badge count=" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "listNotifications" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "markAllRead" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "notification.success" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "notification.error" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "dayjs(item.created_at).fromNow()" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
grep -q "dayjs.locale('vi')" e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | grep -E "components/notifications/BellNotification\.tsx" | (! grep -q "error TS") && \
echo "Task 2 OK"
</automated>
  </verify>
  <done>
    - File tồn tại với `export default function BellNotification`
    - Consume 4 functions từ `api-notifications.ts`
    - Socket listener cho SIGN_COMPLETED + SIGN_FAILED với toast 3s
    - dayjs fromNow vi locale configured
    - TypeScript clean
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Modify MainLayout.tsx — replace bell block bằng <BellNotification />, giữ nguyên logic khác</name>
  <files>e_office_app_new/frontend/src/components/layout/MainLayout.tsx</files>
  <read_first>
    - `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` (full file — đặc biệt dòng 437-568 state bell + fetchCounts + handleBellOpenChange + handleBellMarkAllRead + bellDropdownContent, dòng 822-837 bell JSX mount)
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md` D-08 (position trước avatar, giữ nguyên)
  </read_first>
  <action>
Mục đích: REPLACE inline bell block trong MainLayout (hiện dùng /api/thong-bao) bằng `<BellNotification />` component tự quản state.

**Bước 1: Thêm import ở block top imports của MainLayout.tsx:**
```tsx
import BellNotification from '@/components/notifications/BellNotification';
```

**Bước 2: Remove các state + handler KHÔNG CÒN DÙNG cho bell:**

Xóa (nhưng GIỮ LẠI nếu dùng cho mục khác):
- `const [notifItems, setNotifItems] = useState<NotifItem[]>([]);` — xóa
- `const [bellOpen, setBellOpen] = useState(false);` — xóa
- `interface NotifItem { ... }` — xóa
- `handleBellOpenChange` function — xóa
- `handleBellMarkAllRead` function — xóa
- `bellDropdownContent` JSX block — xóa (khoảng 70 dòng, line 630-703)

**GIỮ LẠI (vì còn dùng cho sidebar menu badge "Thông báo" — khác với header bell):**
- `const [notifUnreadCount, setNotifUnreadCount] = useState(0);` — giữ, vì badge menu "/thong-bao" sidebar dùng
- Fetch `/thong-bao/unread-count` trong `useEffect` — giữ để badge sidebar hoạt động
- Socket listener `NEW_NOTIFICATION` increment `notifUnreadCount` — giữ cho sidebar badge

**Bước 3: Replace bell JSX trong `<Header className="main-header">`:**

Tìm khối (hiện line ~822-837):
```tsx
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
```

Replace bằng:
```tsx
            {/* Phase 13 — personal bell notification (consume /api/notifications) */}
            <BellNotification />
```

**Bước 4: Cleanup unused imports:**

Nếu `Dropdown`, `Badge`, `Typography.Text` còn dùng chỗ khác trong MainLayout (user dropdown, mobile drawer, etc.) thì GIỮ. Nếu CHỈ dùng cho bell thì có thể xóa, nhưng rủi ro — để an toàn GIỮ NGUYÊN imports (chỉ remove state + functions + JSX block nói ở Step 2-3, TypeScript sẽ báo nếu unused local var không dùng).

Chạy `tsc --noEmit` để verify không có unused variable warnings khác ngoài những gì mình cố ý. Nếu có warning về unused `Text` hay `Badge`, xử lý từng trường hợp (xóa import hoặc giữ nếu còn dùng chỗ khác trong file).

```bash
cd e_office_app_new/frontend
npx tsc --noEmit 2>&1 | grep -E "components/layout/MainLayout\.tsx" | (! grep -q "error TS")

# Kiểm tra bell block mới mount đúng
grep -q "<BellNotification />" e_office_app_new/frontend/src/components/layout/MainLayout.tsx
grep -q "import BellNotification from" e_office_app_new/frontend/src/components/layout/MainLayout.tsx

# Kiểm tra bell handlers cũ đã xóa
! grep -q "handleBellOpenChange" e_office_app_new/frontend/src/components/layout/MainLayout.tsx
! grep -q "bellDropdownContent" e_office_app_new/frontend/src/components/layout/MainLayout.tsx
```

Restart Next.js dev server nếu cần để thấy UI mới.

**Smoke test manual (optional — Plan 13-05 sẽ UAT):**
1. `npm run dev` trong frontend
2. Navigate `/dashboard` (sau login)
3. Click bell → dropdown mở, hiển thị "Thông báo" header + "Đánh dấu đã đọc tất cả"
4. Nếu có notification test từ Plan 13-01 Task 3 (smoke test insert SP), item hiển thị
5. Click item → navigate + mark read
6. Badge count giảm
  </action>
  <verify>
<automated>
grep -q "import BellNotification from '@/components/notifications/BellNotification'" e_office_app_new/frontend/src/components/layout/MainLayout.tsx && \
grep -q "<BellNotification />" e_office_app_new/frontend/src/components/layout/MainLayout.tsx && \
! grep -q "handleBellOpenChange" e_office_app_new/frontend/src/components/layout/MainLayout.tsx && \
! grep -q "bellDropdownContent" e_office_app_new/frontend/src/components/layout/MainLayout.tsx && \
! grep -q "setNotifItems" e_office_app_new/frontend/src/components/layout/MainLayout.tsx && \
! grep -q "handleBellMarkAllRead" e_office_app_new/frontend/src/components/layout/MainLayout.tsx && \
cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | grep -E "components/layout/MainLayout\.tsx" | (! grep -q "error TS") && \
echo "Task 3 OK"
</automated>
  </verify>
  <done>
    - `import BellNotification` thêm vào top imports
    - `<BellNotification />` mount trong `main-header-right` đúng position (trước avatar dropdown)
    - Bell-specific handlers cũ (`handleBellOpenChange`, `handleBellMarkAllRead`, `bellDropdownContent`, `notifItems`) đã xóa
    - Giữ `notifUnreadCount` cho sidebar menu badge "Thông báo" (/thong-bao route, không liên quan bell mới)
    - TypeScript clean, không unused imports
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Browser JS → /api/notifications | Frontend trust nội dung response, BE đã filter theo staff_id từ JWT (Plan 13-01 T-13-02) |
| Socket.IO server → client | Room `user_{staffId}` enforced BE-side (Phase 11 T-11-14); client-side mặc định trust |
| localStorage (accessToken) | Browser-side — XSS có thể leak. Đã mitigate qua helmet CSP + httpOnly refresh cookie (Phase 6) |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-13-08 | I (Info Disclosure) — Socket leak notification của user khác | BellNotification socket listener | mitigate | BE emit room `user_{staffId}` đảm bảo mỗi connection chỉ nhận event của mình (Phase 11 Socket JWT middleware). FE defense-in-depth: listener chỉ react qua notification toast + refresh badge — không expose cross-user data vì BE không gửi sang |
| T-13-09 | S (Spoofing) — Fake Socket event trong dev console | BellNotification | accept | Attacker có thể manually emit `socket.emit('sign_completed', ...)` từ browser console để fake toast. Không impact security vì BE chỉ send từ Worker trusted — toast chỉ là UI hint, không trigger destructive action. Badge increment là cosmetic |
| T-13-10 | I (Info Disclosure) — Notification message chứa PII | API response | mitigate | Backend Plan 13-01 chỉ đưa txn_id + attachment_id + provider_code vào message/metadata — không chứa email/phone/SSN của user |
| T-13-11 | D (DoS) — User spam click mark-all-read | PATCH /read-all | accept | Backend có rate limit default qua helmet; mark-all-read là idempotent (0 row affected nếu đã hết unread). SP exec time O(N) cho N unread, N≤100 trong thực tế |
| T-13-12 | T (Tampering) — Click item gọi markRead với id không thuộc user | PATCH /:id/read | mitigate | BE Plan 13-01 owner check trong SP (staff_id filter). FE chỉ gửi id hiển thị trên UI (từ list API đã filter theo staff_id) — không có cách user click id user khác |
</threat_model>

<verification>
1. **File existence:** 2 files mới + 1 modified exist.
2. **TypeScript clean:** `npx tsc --noEmit` zero new errors cho 3 files Plan 13-02 touched.
3. **Runtime render:**
   - Navigate to `/dashboard` post-login → bell icon hiển thị với Badge
   - Click bell → dropdown mở, header "Thông báo" + button "Đánh dấu đã đọc tất cả"
   - Nếu DB có test notification (Plan 13-01 Task 3 smoke test), item list render với icon status + title + relative time ("vài giây trước")
4. **Socket integration:** emit `SIGN_COMPLETED` từ backend worker → toast notification.success xuất hiện top-right, tự hide sau 3s.
5. **Mark read flow:** click item → dropdown close + navigate tới link + badge count giảm 1.
6. **Owner check:** fake curl request `PATCH /api/notifications/999/read` với JWT user A cho notification id=999 của user B → 404.
</verification>

<success_criteria>
Plan 13-02 hoàn tất khi:
- [ ] `lib/api-notifications.ts` exports 4 functions + 1 domain type
- [ ] `components/notifications/BellNotification.tsx` self-contained với Badge + Dropdown + Socket listener + toast
- [ ] MainLayout.tsx mount `<BellNotification />` thay inline bell block
- [ ] Bell position: trong `main-header-right`, TRƯỚC avatar dropdown (giữ nguyên như cũ)
- [ ] Dropdown mở render 10 notification gần nhất từ `/api/notifications`
- [ ] Click item → markRead + navigate
- [ ] Button "Đánh dấu đã đọc tất cả" → PATCH /read-all + badge=0
- [ ] Socket SIGN_COMPLETED/SIGN_FAILED → toast 3s + badge++
- [ ] dayjs fromNow() vi locale áp dụng
- [ ] TypeScript clean, Vietnamese diacritics, AntD 6 APIs (popupRender, notification.*)
</success_criteria>

<output>
Tạo `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-02-SUMMARY.md` sau khi hoàn tất.
</output>
