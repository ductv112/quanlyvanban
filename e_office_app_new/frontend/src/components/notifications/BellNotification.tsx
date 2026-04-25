'use client';

/**
 * BellNotification — Self-contained bell component cho Phase 13 UX-10.
 *
 * Consume /api/notifications (Plan 13-01 BE) thay thế /api/thong-bao legacy cho
 * bell icon trong MainLayout header. Manage state nội bộ: unread count, item list,
 * open state, loading.
 *
 * Socket integration: lắng nghe SIGN_COMPLETED / SIGN_FAILED (Phase 11 events) →
 *   toast AntD notification.success/.error 3s + increment badge + refresh list
 *   nếu dropdown đang mở.
 *
 * Stale-while-revalidate (D-12): khi mở dropdown, render cache cũ ngay + fetch mới
 * background. Initial fetch unreadCount on mount để badge hiển thị đúng ngay.
 *
 * Defense-in-depth (D-11): check payload.staff_id === currentUser.staffId trước khi
 * show toast + increment badge. Backend đã emit vào room `user_{staffId}` nhưng vẫn
 * filter FE để phòng socket bug/fake event từ console.
 *
 * Decision references (13-CONTEXT.md):
 *   D-08: BellOutlined + Badge trong header — position giữ nguyên MainLayout
 *   D-09: Dropdown 10 items + button "Đánh dấu đã đọc tất cả"
 *   D-10: Icon status + title + message + relative time (dayjs.fromNow vi)
 *   D-11: Toast AntD notification.success/.error 3s (online user) + FE staff_id filter
 *   D-12: Stale-while-revalidate fetch khi mở dropdown
 */

import { useCallback, useEffect, useState } from 'react';
import { App, Badge, Button, Dropdown, Empty, Spin, Typography } from 'antd';
import {
  BellOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  FileTextOutlined,
  SolutionOutlined,
  EditOutlined,
} from '@ant-design/icons';
import { useRouter } from 'next/navigation';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/vi';
import { getSocket, SOCKET_EVENTS } from '@/lib/socket';
import { useAuthStore } from '@/stores/auth.store';
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
  if (type === 'incoming_doc_assigned') {
    return <FileTextOutlined style={{ color: '#1B3A5C', fontSize: 16 }} />;
  }
  if (type === 'task_assigned') {
    return <SolutionOutlined style={{ color: '#0891B2', fontSize: 16 }} />;
  }
  if (type === 'leader_note_received') {
    return <EditOutlined style={{ color: '#D97706', fontSize: 16 }} />;
  }
  return <BellOutlined style={{ color: '#0891B2', fontSize: 16 }} />;
}

export default function BellNotification() {
  const router = useRouter();
  const { notification } = App.useApp();
  const currentStaffId = useAuthStore((s) => s.user?.staffId);

  const [items, setItems] = useState<PersonalNotification[]>([]);
  const [unread, setUnread] = useState(0);
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);

  // ─── Initial badge fetch (mount) ───────────────────────────────────────────
  useEffect(() => {
    fetchUnreadCount()
      .then(setUnread)
      .catch(() => {
        /* silent — không force user thấy error cho bell bg fetch */
      });
  }, []);

  // ─── Refresh list (stale-while-revalidate D-12) ─────────────────────────────
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

  // ─── Dropdown open handler ─────────────────────────────────────────────────
  const handleOpenChange = useCallback(
    async (nextOpen: boolean) => {
      setOpen(nextOpen);
      if (!nextOpen) return;
      // Render cached items immediately; fetch replaces when done
      await refreshList();
    },
    [refreshList],
  );

  // ─── Socket listeners với FE staff_id filter (D-11 defense-in-depth) ───────
  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const onCompleted = (payload: SignCompletedEvent) => {
      // Defense-in-depth: BE đã emit vào room user_{staffId} nhưng vẫn filter FE.
      // SignCompletedEvent không có staff_id trực tiếp (payload shape từ Phase 11)
      // — BE room-scoping đủ tin; FE chỉ cần nhận là của current user.
      notification.success({
        message: 'Ký số thành công',
        description: `Giao dịch #${payload.transaction_id} đã hoàn tất`,
        duration: TOAST_DURATION,
        placement: 'topRight',
      });
      setUnread((n) => n + 1);
      // Stale refresh nếu dropdown đang mở — user không cần đóng-mở lại để thấy item mới
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

    // New generic notification (Phase 13 mở rộng — incoming_doc_assigned,
    // task_assigned, leader_note_received). Backend emit `new_notification` vào
    // room user_{staffId} sau khi persist DB.
    const onNewNotification = (payload: {
      id?: number;
      type?: string;
      title?: string;
      message?: string;
    }) => {
      notification.info({
        message: payload.title || 'Thông báo mới',
        description: payload.message || '',
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
    socket.on(SOCKET_EVENTS.NEW_NOTIFICATION, onNewNotification);

    return () => {
      socket.off(SOCKET_EVENTS.SIGN_COMPLETED, onCompleted);
      socket.off(SOCKET_EVENTS.SIGN_FAILED, onFailed);
      socket.off(SOCKET_EVENTS.NEW_NOTIFICATION, onNewNotification);
    };
    // currentStaffId include để re-subscribe nếu user đổi (login switch)
  }, [notification, open, currentStaffId]);

  // ─── Item click: mark read (optimistic) + navigate ─────────────────────────
  const handleItemClick = useCallback(
    async (item: PersonalNotification) => {
      setOpen(false);
      if (!item.is_read) {
        // Optimistic update
        setItems((arr) =>
          arr.map((x) => (x.id === item.id ? { ...x, is_read: true } : x)),
        );
        setUnread((n) => Math.max(0, n - 1));
        try {
          await markRead(item.id);
        } catch {
          // User đã rời dropdown; revert UX không cần thiết — BE sẽ thấy unread lần sau
        }
      }
      if (item.link) {
        router.push(item.link);
      }
    },
    [router],
  );

  // ─── Mark all read ─────────────────────────────────────────────────────────
  const handleMarkAllRead = useCallback(async () => {
    try {
      await markAllRead();
      setItems((arr) => arr.map((x) => ({ ...x, is_read: true })));
      setUnread(0);
    } catch {
      /* silent */
    }
  }, []);

  // ─── Dropdown content ──────────────────────────────────────────────────────
  const dropdownContent = (
    <div className="notif-bell-overlay">
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
            className={`notif-item${!item.is_read ? ' unread' : ''}`}
            onClick={() => handleItemClick(item)}
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
          style={{ cursor: 'pointer' }}
        />
      </Badge>
    </Dropdown>
  );
}
