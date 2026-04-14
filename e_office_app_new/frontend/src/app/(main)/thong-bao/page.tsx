'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  List, Tabs, Button, Badge, Drawer, Form, Input, App, Skeleton,
} from 'antd';
import { BellOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import dayjs from 'dayjs';

const { TextArea } = Input;

// ─── Interfaces ───────────────────────────────────────────────────────────────

interface NoticeItem {
  id: number;
  title: string;
  content: string;
  is_read: boolean;
  created_at: string;
}

type ActiveTab = 'all' | 'unread' | 'read';

// ─── Main Component ───────────────────────────────────────────────────────────

export default function ThongBaoPage() {
  const { message } = App.useApp();
  const { user } = useAuthStore();

  // List state
  const [notices, setNotices] = useState<NoticeItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [activeTab, setActiveTab] = useState<ActiveTab>('all');
  const [page, setPage] = useState(1);
  const [pageSize] = useState(20);
  const [total, setTotal] = useState(0);

  // Create drawer (admin)
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [createForm] = Form.useForm();
  const [creating, setCreating] = useState(false);

  // Marking all read
  const [markingAll, setMarkingAll] = useState(false);

  // ─── Data Fetching ───────────────────────────────────────────────────────────

  const fetchNotices = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = { page, page_size: pageSize };
      if (activeTab === 'unread') params.is_read = false;
      if (activeTab === 'read') params.is_read = true;

      const { data: res } = await api.get('/thong-bao', { params });
      const list: NoticeItem[] = res.data?.list || res.data || [];
      setNotices(list);
      setTotal(res.data?.total || list.length);
    } catch {
      // Silent
    } finally {
      setLoading(false);
    }
  }, [activeTab, page, pageSize]);

  useEffect(() => {
    fetchNotices();
  }, [fetchNotices]);

  // ─── Handlers ────────────────────────────────────────────────────────────────

  const handleMarkRead = async (id: number) => {
    try {
      await api.patch(`/thong-bao/${id}/read`);
      setNotices((prev) =>
        prev.map((n) => (n.id === id ? { ...n, is_read: true } : n))
      );
    } catch {
      // Silent
    }
  };

  const handleMarkAllRead = async () => {
    setMarkingAll(true);
    try {
      await api.patch('/thong-bao/mark-all-read');
      message.success('Đã đánh dấu tất cả là đã đọc');
      fetchNotices();
    } catch {
      message.error('Thao tác thất bại. Vui lòng thử lại.');
    } finally {
      setMarkingAll(false);
    }
  };

  const handleCreate = async () => {
    try {
      const values = await createForm.validateFields();
      setCreating(true);
      await api.post('/thong-bao', {
        title: values.title,
        content: values.content,
      });
      message.success('Tạo thông báo thành công');
      setDrawerOpen(false);
      createForm.resetFields();
      fetchNotices();
    } catch (err: unknown) {
      if (err && typeof err === 'object' && 'errorFields' in err) return;
      message.error('Tạo thông báo thất bại. Vui lòng thử lại.');
    } finally {
      setCreating(false);
    }
  };

  // ─── Render ──────────────────────────────────────────────────────────────────

  const tabItems = [
    { key: 'all', label: 'Tất cả' },
    { key: 'unread', label: 'Chưa đọc' },
    { key: 'read', label: 'Đã đọc' },
  ];

  return (
    <>
      {/* Page Header */}
      <div className="page-header">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h1 className="page-title">
              <BellOutlined />
              Thông báo
            </h1>
            <p className="page-description">Quản lý và theo dõi các thông báo hệ thống</p>
          </div>
          <div style={{ display: 'flex', gap: 8 }}>
            <Button
              onClick={handleMarkAllRead}
              loading={markingAll}
            >
              Đánh dấu đã đọc tất cả
            </Button>
            {user?.isAdmin && (
              <Button
                type="primary"
                onClick={() => {
                  createForm.resetFields();
                  setDrawerOpen(true);
                }}
              >
                Tạo thông báo
              </Button>
            )}
          </div>
        </div>
      </div>

      {/* Notification Card */}
      <div className="page-card" style={{ background: '#fff', borderRadius: 12, overflow: 'hidden' }}>
        {/* Filter Tabs */}
        <div style={{ padding: '0 16px', borderBottom: '1px solid #F1F5F9' }}>
          <Tabs
            activeKey={activeTab}
            onChange={(key) => {
              setActiveTab(key as ActiveTab);
              setPage(1);
            }}
            items={tabItems}
            style={{ marginBottom: 0 }}
          />
        </div>

        {/* List */}
        {loading ? (
          <div style={{ padding: '16px' }}>
            {[1, 2, 3, 4, 5].map((i) => (
              <Skeleton key={i} active paragraph={{ rows: 2 }} style={{ marginBottom: 16 }} />
            ))}
          </div>
        ) : (
          <List
            dataSource={notices}
            locale={{
              emptyText: (
                <div className="empty-center" style={{ padding: '40px 0' }}>
                  <BellOutlined style={{ fontSize: 36, color: '#CBD5E1', display: 'block', marginBottom: 8 }} />
                  <div style={{ color: '#94A3B8', fontSize: 14 }}>Chưa có thông báo</div>
                  <div style={{ color: '#CBD5E1', fontSize: 12, marginTop: 4 }}>
                    Hệ thống sẽ thông báo khi có văn bản mới hoặc việc được giao.
                  </div>
                </div>
              ),
            }}
            renderItem={(item) => (
              <div
                className={`notif-item${!item.is_read ? ' unread' : ''}`}
                onClick={() => !item.is_read && handleMarkRead(item.id)}
              >
                {/* Icon */}
                <div style={{
                  width: 32,
                  height: 32,
                  borderRadius: '50%',
                  background: '#EFF8FF',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  flexShrink: 0,
                  marginTop: 2,
                }}>
                  <BellOutlined style={{ color: '#0891B2', fontSize: 14 }} />
                </div>

                {/* Content */}
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
                    <span style={{
                      fontSize: 14,
                      fontWeight: !item.is_read ? 600 : 400,
                      color: '#1B3A5C',
                      lineHeight: 1.4,
                    }}>
                      {!item.is_read && (
                        <Badge
                          dot
                          color="#0891B2"
                          style={{ marginRight: 6 }}
                        />
                      )}
                      {item.title}
                    </span>
                    <span style={{ fontSize: 12, color: '#64748B', flexShrink: 0 }}>
                      {dayjs(item.created_at).format('DD/MM/YYYY HH:mm')}
                    </span>
                  </div>
                  <div style={{
                    fontSize: 14,
                    color: '#64748B',
                    marginTop: 4,
                    overflow: 'hidden',
                    display: '-webkit-box',
                    WebkitLineClamp: 2,
                    WebkitBoxOrient: 'vertical',
                  } as React.CSSProperties}>
                    {item.content}
                  </div>
                </div>
              </div>
            )}
            pagination={
              total > pageSize
                ? {
                    current: page,
                    pageSize,
                    total,
                    onChange: (p) => setPage(p),
                    style: { padding: '16px', textAlign: 'right' },
                    showSizeChanger: false,
                  }
                : false
            }
          />
        )}
      </div>

      {/* Create Drawer (Admin only) */}
      <Drawer
        title="Tạo thông báo mới"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        width={720}
        rootClassName="drawer-gradient"
        extra={
          <div style={{ display: 'flex', gap: 8 }}>
            <Button onClick={() => setDrawerOpen(false)}>Hủy</Button>
            <Button type="primary" loading={creating} onClick={handleCreate}>
              Tạo thông báo
            </Button>
          </div>
        }
      >
        <Form form={createForm} layout="vertical" validateTrigger="onSubmit">
          <Form.Item
            name="title"
            label="Tiêu đề"
            rules={[{ required: true, message: 'Vui lòng nhập tiêu đề' }]}
          >
            <Input placeholder="Nhập tiêu đề thông báo..." maxLength={300} showCount />
          </Form.Item>

          <Form.Item
            name="content"
            label="Nội dung"
            rules={[{ required: true, message: 'Vui lòng nhập nội dung' }]}
          >
            <TextArea rows={6} placeholder="Nhập nội dung thông báo..." />
          </Form.Item>
        </Form>
      </Drawer>
    </>
  );
}
