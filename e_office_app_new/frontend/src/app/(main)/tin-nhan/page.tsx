'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Drawer, Form, Input, Select, Button, Badge, Avatar,
  Skeleton, App, Popconfirm, Menu,
} from 'antd';
import type { MenuProps } from 'antd';
import {
  EditOutlined, SendOutlined, DeleteOutlined,
  InboxOutlined, MailOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';
import relativeTime from 'dayjs/plugin/relativeTime';
import 'dayjs/locale/vi';

dayjs.extend(relativeTime);
dayjs.locale('vi');

const { TextArea } = Input;

// ─── Interfaces ───────────────────────────────────────────────────────────────

interface MessageItem {
  id: number;
  sender_id: number;
  sender_name: string;
  subject: string;
  content: string;
  is_read: boolean;
  created_at: string;
  to_staff_ids?: number[];
  to_names?: string[];
  replies?: ReplyItem[];
}

interface ReplyItem {
  id: number;
  sender_name: string;
  content: string;
  created_at: string;
}

interface StaffOption {
  value: number;
  label: string;
}

type Folder = 'inbox' | 'sent' | 'trash';

// ─── Main Component ───────────────────────────────────────────────────────────

export default function TinNhanPage() {
  const { message } = App.useApp();

  // Folder & list state
  const [folder, setFolder] = useState<Folder>('inbox');
  const [messages, setMessages] = useState<MessageItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [messageDetail, setMessageDetail] = useState<MessageItem | null>(null);
  const [detailLoading, setDetailLoading] = useState(false);
  const [unreadCount, setUnreadCount] = useState(0);
  const [keyword, setKeyword] = useState('');
  const [page] = useState(1);
  const [pageSize] = useState(50);

  // Compose drawer
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [composeForm] = Form.useForm();
  const [sending, setSending] = useState(false);
  const [staffOptions, setStaffOptions] = useState<StaffOption[]>([]);

  // Reply
  const [replyContent, setReplyContent] = useState('');
  const [replying, setReplying] = useState(false);

  // ─── Data Fetching ───────────────────────────────────────────────────────────

  const fetchMessages = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get(`/tin-nhan/${folder}`, {
        params: { keyword, page, page_size: pageSize },
      });
      const list: MessageItem[] = res.data?.data || res.data?.list || (Array.isArray(res.data) ? res.data : []);
      setMessages(list);
      if (folder === 'inbox') {
        setUnreadCount(list.filter((m) => !m.is_read).length);
      }
    } catch {
      // Silent — show empty list
    } finally {
      setLoading(false);
    }
  }, [folder, keyword, page, pageSize]);

  const fetchDetail = useCallback(async (id: number) => {
    setDetailLoading(true);
    try {
      const { data: res } = await api.get(`/tin-nhan/${id}`);
      setMessageDetail(res.data);
      // Mark as read locally
      setMessages((prev) =>
        prev.map((m) => (m.id === id ? { ...m, is_read: true } : m))
      );
    } catch {
      message.error('Lỗi tải tin nhắn. Vui lòng thử lại.');
    } finally {
      setDetailLoading(false);
    }
  }, [message]);

  const fetchStaff = useCallback(async () => {
    try {
      const { data: res } = await api.get('/quan-tri/nhan-vien', {
        params: { page: 1, page_size: 200 },
      });
      const list = res.data?.list || res.data || [];
      setStaffOptions(
        list.map((s: { id: number; full_name: string }) => ({
          value: s.id,
          label: s.full_name,
        }))
      );
    } catch {
      // Silent
    }
  }, []);

  useEffect(() => {
    fetchMessages();
  }, [fetchMessages]);

  // ─── Handlers ────────────────────────────────────────────────────────────────

  const handleSelectMessage = (id: number) => {
    setSelectedId(id);
    setReplyContent('');
    fetchDetail(id);
  };

  const handleDelete = async (id: number) => {
    try {
      await api.delete(`/tin-nhan/${id}`);
      message.success('Đã xóa tin nhắn');
      setMessages((prev) => prev.filter((m) => m.id !== id));
      if (selectedId === id) {
        setSelectedId(null);
        setMessageDetail(null);
      }
    } catch {
      message.error('Xóa tin nhắn thất bại. Vui lòng thử lại.');
    }
  };

  const handleReply = async () => {
    if (!replyContent.trim() || !selectedId) return;
    setReplying(true);
    try {
      await api.post(`/tin-nhan/${selectedId}/reply`, { content: replyContent });
      message.success('Đã gửi trả lời');
      setReplyContent('');
      fetchDetail(selectedId);
    } catch {
      message.error('Gửi trả lời thất bại. Vui lòng thử lại.');
    } finally {
      setReplying(false);
    }
  };

  const handleOpenCompose = () => {
    fetchStaff();
    composeForm.resetFields();
    setDrawerOpen(true);
  };

  const handleSend = async () => {
    try {
      const values = await composeForm.validateFields();
      setSending(true);
      await api.post('/tin-nhan', {
        to_staff_ids: values.to_staff_ids,
        subject: values.subject,
        content: values.content,
      });
      message.success('Gửi tin nhắn thành công');
      setDrawerOpen(false);
      composeForm.resetFields();
      fetchMessages();
    } catch (err: unknown) {
      if (err && typeof err === 'object' && 'errorFields' in err) return;
      message.error('Gửi tin nhắn thất bại. Vui lòng kiểm tra kết nối và thử lại.');
    } finally {
      setSending(false);
    }
  };

  // ─── Menu items ──────────────────────────────────────────────────────────────

  const sidebarMenuItems: MenuProps['items'] = [
    {
      key: 'inbox',
      icon: <InboxOutlined />,
      label: (
        <span>
          Hộp thư đến{' '}
          {unreadCount > 0 && (
            <Badge count={unreadCount} size="small" style={{ marginLeft: 6 }} />
          )}
        </span>
      ),
    },
    {
      key: 'sent',
      icon: <SendOutlined />,
      label: 'Đã gửi',
    },
    {
      key: 'trash',
      icon: <DeleteOutlined />,
      label: 'Thùng rác',
    },
  ];

  // ─── Filtered messages ───────────────────────────────────────────────────────

  const filteredMessages = messages.filter((m) => {
    if (!keyword) return true;
    const kw = keyword.toLowerCase();
    return (
      m.subject?.toLowerCase().includes(kw) ||
      m.sender_name?.toLowerCase().includes(kw) ||
      m.content?.toLowerCase().includes(kw)
    );
  });

  // ─── Render ──────────────────────────────────────────────────────────────────

  return (
    <>
      <div className="mail-layout">
        {/* LEFT: Mail Sidebar */}
        <div className="mail-sidebar">
          <Button
            type="primary"
            icon={<EditOutlined />}
            onClick={handleOpenCompose}
            style={{ margin: '0 12px 16px', width: 'calc(100% - 24px)' }}
          >
            Soạn tin nhắn
          </Button>
          <Menu
            theme="dark"
            mode="inline"
            selectedKeys={[folder]}
            items={sidebarMenuItems}
            onClick={({ key }) => {
              setFolder(key as Folder);
              setSelectedId(null);
              setMessageDetail(null);
            }}
            style={{ background: 'transparent', border: 'none' }}
          />
        </div>

        {/* MIDDLE: Message List */}
        <div className="mail-list-panel">
          <div style={{ padding: '12px 16px', borderBottom: '1px solid #F1F5F9' }}>
            <Input
              placeholder="Tìm kiếm tin nhắn..."
              value={keyword}
              onChange={(e) => setKeyword(e.target.value)}
              allowClear
              size="small"
            />
          </div>

          {loading ? (
            <div style={{ padding: '12px 16px' }}>
              {[1, 2, 3, 4, 5].map((i) => (
                <Skeleton
                  key={i}
                  active
                  avatar={{ size: 32 }}
                  paragraph={{ rows: 2 }}
                  style={{ marginBottom: 12 }}
                />
              ))}
            </div>
          ) : filteredMessages.length === 0 ? (
            <div className="empty-center" style={{ paddingTop: 48 }}>
              <MailOutlined style={{ fontSize: 36, color: '#CBD5E1', display: 'block', marginBottom: 8 }} />
              <span>Hộp thư trống</span>
            </div>
          ) : (
            filteredMessages.map((msg) => (
              <div
                key={msg.id}
                className={[
                  'mail-item',
                  !msg.is_read ? 'unread' : '',
                  selectedId === msg.id ? 'selected' : '',
                ].filter(Boolean).join(' ')}
                onClick={() => handleSelectMessage(msg.id)}
              >
                <div style={{ display: 'flex', gap: 10, alignItems: 'flex-start' }}>
                  <Avatar
                    size={32}
                    style={{ background: '#1B3A5C', flexShrink: 0, fontSize: 13 }}
                  >
                    {msg.sender_name?.[0]?.toUpperCase() || 'N'}
                  </Avatar>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                      <span className="mail-item-sender">{msg.sender_name}</span>
                      <span className="mail-item-meta">
                        {dayjs(msg.created_at).fromNow()}
                      </span>
                    </div>
                    <div className="mail-item-subject">{msg.subject}</div>
                    <div className="mail-item-snippet">{msg.content}</div>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>

        {/* RIGHT: Message Detail */}
        <div className="mail-detail-pane">
          {!selectedId ? (
            <div className="empty-center" style={{ paddingTop: 80 }}>
              <MailOutlined style={{ fontSize: 48, color: '#CBD5E1', display: 'block', marginBottom: 12 }} />
              <div style={{ fontSize: 14, color: '#94A3B8' }}>
                Chọn tin nhắn để xem nội dung
              </div>
            </div>
          ) : detailLoading ? (
            <Skeleton active paragraph={{ rows: 6 }} />
          ) : messageDetail ? (
            <div>
              {/* Detail Header */}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 16 }}>
                <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: 0 }}>
                  {messageDetail.subject}
                </h2>
                <Popconfirm
                  title="Xóa tin nhắn?"
                  description="Tin nhắn sẽ chuyển vào thùng rác."
                  okText="Xóa"
                  okButtonProps={{ danger: true }}
                  cancelText="Hủy"
                  onConfirm={() => handleDelete(messageDetail.id)}
                >
                  <Button icon={<DeleteOutlined />} danger size="small">
                    Xóa
                  </Button>
                </Popconfirm>
              </div>

              {/* Meta */}
              <div style={{ fontSize: 12, color: '#64748B', marginBottom: 16 }}>
                <span>Từ: <strong>{messageDetail.sender_name}</strong></span>
                {messageDetail.to_names && messageDetail.to_names.length > 0 && (
                  <span style={{ marginLeft: 16 }}>
                    Đến: <strong>{messageDetail.to_names.join(', ')}</strong>
                  </span>
                )}
                <span style={{ marginLeft: 16 }}>
                  {dayjs(messageDetail.created_at).format('DD/MM/YYYY HH:mm')}
                </span>
              </div>

              {/* Body */}
              <div style={{
                fontSize: 14,
                lineHeight: 1.6,
                color: '#334155',
                marginBottom: 24,
                padding: '16px',
                background: '#F8FAFC',
                borderRadius: 8,
              }}>
                {messageDetail.content}
              </div>

              {/* Thread Replies */}
              {messageDetail.replies && messageDetail.replies.length > 0 && (
                <div style={{ marginBottom: 24 }}>
                  <div style={{ fontSize: 13, fontWeight: 600, color: '#1B3A5C', marginBottom: 12 }}>
                    Trả lời ({messageDetail.replies.length})
                  </div>
                  {messageDetail.replies.map((reply) => (
                    <div key={reply.id} className="opinion-item">
                      <Avatar
                        size={32}
                        style={{ background: '#0891B2', flexShrink: 0, fontSize: 13 }}
                      >
                        {reply.sender_name?.[0]?.toUpperCase() || 'N'}
                      </Avatar>
                      <div className="opinion-item-content">
                        <div className="opinion-item-header">
                          <span className="opinion-item-name">{reply.sender_name}</span>
                          <span className="opinion-item-time">
                            {dayjs(reply.created_at).format('DD/MM/YYYY HH:mm')}
                          </span>
                        </div>
                        <div className="opinion-item-text">{reply.content}</div>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* Reply Box */}
              <div style={{ borderTop: '1px solid #E8ECF1', paddingTop: 16 }}>
                <div style={{ fontSize: 13, fontWeight: 600, color: '#1B3A5C', marginBottom: 8 }}>
                  Trả lời
                </div>
                <TextArea
                  rows={4}
                  placeholder="Nhập nội dung trả lời..."
                  value={replyContent}
                  onChange={(e) => setReplyContent(e.target.value)}
                  style={{ marginBottom: 8 }}
                />
                <Button
                  type="primary"
                  icon={<SendOutlined />}
                  loading={replying}
                  disabled={!replyContent.trim()}
                  onClick={handleReply}
                >
                  Trả lời
                </Button>
              </div>
            </div>
          ) : null}
        </div>
      </div>

      {/* Compose Drawer */}
      <Drawer
        title="Soạn tin nhắn mới"
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        width={720}
        rootClassName="drawer-gradient"
        extra={
          <div style={{ display: 'flex', gap: 8 }}>
            <Button onClick={() => setDrawerOpen(false)}>Hủy</Button>
            <Button
              type="primary"
              icon={<SendOutlined />}
              loading={sending}
              onClick={handleSend}
            >
              Gửi tin nhắn
            </Button>
          </div>
        }
      >
        <Form
          form={composeForm}
          layout="vertical"
          validateTrigger="onSubmit"
        >
          <Form.Item
            name="to_staff_ids"
            label="Người nhận"
            rules={[{ required: true, message: 'Vui lòng chọn người nhận' }]}
          >
            <Select
              mode="multiple"
              placeholder="Tìm kiếm và chọn người nhận..."
              options={staffOptions}
              showSearch
              filterOption={(input, option) =>
                String(option?.label ?? '').toLowerCase().includes(input.toLowerCase())
              }
              allowClear
            />
          </Form.Item>

          <Form.Item
            name="subject"
            label="Tiêu đề"
            rules={[{ required: true, message: 'Vui lòng nhập tiêu đề' }]}
          >
            <Input
              placeholder="Nhập tiêu đề tin nhắn..."
              maxLength={200}
              showCount
            />
          </Form.Item>

          <Form.Item
            name="content"
            label="Nội dung"
            rules={[{ required: true, message: 'Vui lòng nhập nội dung' }]}
          >
            <TextArea
              rows={6}
              placeholder="Nhập nội dung tin nhắn..."
            />
          </Form.Item>
        </Form>
      </Drawer>
    </>
  );
}
