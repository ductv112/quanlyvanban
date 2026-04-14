'use client';

import React, { useEffect, useState, useCallback } from 'react';
import { Card, Row, Col, Table, Tag, Progress, Skeleton, Button } from 'antd';
import {
  InboxOutlined,
  SendOutlined,
  FolderOpenOutlined,
  ClockCircleOutlined,
  FileTextOutlined,
  HolderOutlined,
} from '@ant-design/icons';
import { useRouter } from 'next/navigation';
import { ResponsiveGridLayout, useContainerWidth } from 'react-grid-layout';
import type { LayoutItem, ResponsiveLayouts } from 'react-grid-layout';
import 'react-grid-layout/css/styles.css';
import 'react-resizable/css/styles.css';
import { useAuthStore } from '@/stores/auth.store';
import { api } from '@/lib/api';
import dayjs from 'dayjs';


// ---- Types ----

interface DashboardStats {
  incoming_unread: number;
  outgoing_pending: number;
  handling_total: number;
  handling_overdue: number;
}

interface RecentIncomingItem {
  id: number | string;
  doc_code: string;
  abstract: string;
  received_date: string;
  urgency_name: string;
  sender_name: string;
}

interface UpcomingTaskItem {
  id: number | string;
  title: string;
  open_date: string;
  status: string;
  progress_percent: number;
  deadline: string;
}

interface RecentOutgoingItem {
  id: number | string;
  doc_code: string;
  abstract: string;
  sent_date: string;
  doc_type_name: string;
}

// ---- localStorage helpers ----

const LAYOUT_STORAGE_KEY = 'dashboard-layout';

const defaultLayouts = {
  lg: [
    { i: 'incoming', x: 0, y: 0, w: 8, h: 4 },
    { i: 'tasks', x: 8, y: 0, w: 4, h: 4 },
    { i: 'outgoing', x: 0, y: 4, w: 12, h: 4 },
  ],
  md: [
    { i: 'incoming', x: 0, y: 0, w: 6, h: 4 },
    { i: 'tasks', x: 6, y: 0, w: 4, h: 4 },
    { i: 'outgoing', x: 0, y: 4, w: 10, h: 4 },
  ],
  sm: [
    { i: 'incoming', x: 0, y: 0, w: 6, h: 4 },
    { i: 'tasks', x: 0, y: 4, w: 6, h: 4 },
    { i: 'outgoing', x: 0, y: 8, w: 6, h: 4 },
  ],
};

function loadSavedLayouts() {
  try {
    if (typeof window === 'undefined') return null;
    const saved = localStorage.getItem(LAYOUT_STORAGE_KEY);
    if (saved) return JSON.parse(saved);
  } catch {
    // ignore
  }
  return null;
}

// ---- Urgency tag color ----

function urgencyColor(name: string): string {
  if (!name) return 'default';
  const n = name.toLowerCase();
  if (n.includes('khẩn') || n.includes('khan')) return 'red';
  if (n.includes('hỏa') || n.includes('thượng')) return 'volcano';
  return 'blue';
}

// ---- Widget: Văn bản mới nhận ----

function IncomingWidget({ data, loading }: { data: RecentIncomingItem[]; loading: boolean }) {
  const router = useRouter();

  const columns = [
    {
      title: 'Số hiệu',
      dataIndex: 'doc_code',
      key: 'doc_code',
      width: 120,
      render: (v: string) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v || '—'}</span>,
    },
    {
      title: 'Trích yếu',
      dataIndex: 'abstract',
      key: 'abstract',
      ellipsis: true,
    },
    {
      title: 'Ngày nhận',
      dataIndex: 'received_date',
      key: 'received_date',
      width: 100,
      render: (v: string) => v ? dayjs(v).format('DD/MM/YYYY') : '—',
    },
    {
      title: 'Độ khẩn',
      dataIndex: 'urgency_name',
      key: 'urgency_name',
      width: 90,
      render: (v: string) => v ? <Tag color={urgencyColor(v)}>{v}</Tag> : null,
    },
  ];

  return (
    <Card
      className="page-card"
      variant="borderless"
      style={{ height: '100%' }}
      styles={{ body: { padding: '12px 16px', height: 'calc(100% - 56px)', overflow: 'auto' } }}
      title={
        <div className="section-card-header">
          <HolderOutlined className="widget-drag-handle" style={{ cursor: 'grab', color: '#94a3b8', fontSize: 14, marginRight: 2 }} />
          <div className="section-card-icon" style={{ background: 'linear-gradient(135deg, #1B3A5C, #0891B2)' }}>
            <FileTextOutlined style={{ color: '#fff', fontSize: 14 }} />
          </div>
          <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Văn bản mới nhận</span>
        </div>
      }
      extra={
        <Button type="link" size="small" onClick={() => router.push('/van-ban-den')}>
          Xem thêm
        </Button>
      }
    >
      {loading ? (
        <Skeleton active paragraph={{ rows: 4 }} />
      ) : (
        <Table
          dataSource={data}
          columns={columns}
          rowKey="id"
          size="small"
          pagination={false}
          locale={{ emptyText: 'Chưa có văn bản mới' }}
        />
      )}
    </Card>
  );
}

// ---- Widget: Việc sắp tới hạn ----

function TasksWidget({ data, loading }: { data: UpcomingTaskItem[]; loading: boolean }) {
  const router = useRouter();

  function statusColor(s: string): string {
    if (!s) return 'default';
    const n = s.toLowerCase();
    if (n.includes('hoàn') || n.includes('xong')) return 'success';
    if (n.includes('quá') || n.includes('hạn')) return 'error';
    if (n.includes('đang')) return 'processing';
    return 'warning';
  }

  return (
    <Card
      className="page-card"
      variant="borderless"
      style={{ height: '100%' }}
      styles={{ body: { padding: '12px 16px', height: 'calc(100% - 56px)', overflow: 'auto' } }}
      title={
        <div className="section-card-header">
          <HolderOutlined className="widget-drag-handle" style={{ cursor: 'grab', color: '#94a3b8', fontSize: 14, marginRight: 2 }} />
          <div className="section-card-icon" style={{ background: 'linear-gradient(135deg, #D97706, #f59e0b)' }}>
            <ClockCircleOutlined style={{ color: '#fff', fontSize: 14 }} />
          </div>
          <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Việc sắp tới hạn</span>
        </div>
      }
      extra={
        <Button type="link" size="small" onClick={() => router.push('/ho-so-cong-viec')}>
          Xem thêm
        </Button>
      }
    >
      {loading ? (
        <Skeleton active paragraph={{ rows: 4 }} />
      ) : data.length === 0 ? (
        <div style={{ textAlign: 'center', color: '#94a3b8', padding: '24px 0', fontSize: 13 }}>
          Không có việc sắp tới hạn
        </div>
      ) : (
        <div>
          {data.map((item) => (
            <div
              key={item.id}
              style={{ padding: '8px 0', borderBottom: '1px solid #f0f0f0' }}
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                <span style={{ fontWeight: 600, fontSize: 13, color: '#1B3A5C', flex: 1, marginRight: 8 }}>
                  {item.title}
                </span>
                <Tag color={statusColor(item.status)} style={{ flexShrink: 0 }}>{item.status || 'Đang xử lý'}</Tag>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <Progress
                  percent={item.progress_percent ?? 0}
                  size="small"
                  style={{ flex: 1, margin: 0 }}
                  strokeColor="#0891B2"
                />
                <span style={{ fontSize: 11, color: '#94a3b8', flexShrink: 0 }}>
                  {item.deadline ? dayjs(item.deadline).format('DD/MM') : '—'}
                </span>
              </div>
            </div>
          ))}
        </div>
      )}
    </Card>
  );
}

// ---- Widget: Văn bản đi mới ----

function OutgoingWidget({ data, loading }: { data: RecentOutgoingItem[]; loading: boolean }) {
  const router = useRouter();

  const columns = [
    {
      title: 'Số hiệu',
      dataIndex: 'doc_code',
      key: 'doc_code',
      width: 120,
      render: (v: string) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v || '—'}</span>,
    },
    {
      title: 'Trích yếu',
      dataIndex: 'abstract',
      key: 'abstract',
      ellipsis: true,
    },
    {
      title: 'Ngày gửi',
      dataIndex: 'sent_date',
      key: 'sent_date',
      width: 100,
      render: (v: string) => v ? dayjs(v).format('DD/MM/YYYY') : '—',
    },
    {
      title: 'Loại VB',
      dataIndex: 'doc_type_name',
      key: 'doc_type_name',
      width: 120,
      render: (v: string) => v ? <Tag color="geekblue">{v}</Tag> : null,
    },
  ];

  return (
    <Card
      className="page-card"
      variant="borderless"
      style={{ height: '100%' }}
      styles={{ body: { padding: '12px 16px', height: 'calc(100% - 56px)', overflow: 'auto' } }}
      title={
        <div className="section-card-header">
          <HolderOutlined className="widget-drag-handle" style={{ cursor: 'grab', color: '#94a3b8', fontSize: 14, marginRight: 2 }} />
          <div className="section-card-icon" style={{ background: 'linear-gradient(135deg, #059669, #10b981)' }}>
            <SendOutlined style={{ color: '#fff', fontSize: 14 }} />
          </div>
          <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Văn bản đi mới</span>
        </div>
      }
      extra={
        <Button type="link" size="small" onClick={() => router.push('/van-ban-di')}>
          Xem thêm
        </Button>
      }
    >
      {loading ? (
        <Skeleton active paragraph={{ rows: 4 }} />
      ) : (
        <Table
          dataSource={data}
          columns={columns}
          rowKey="id"
          size="small"
          pagination={false}
          locale={{ emptyText: 'Chưa có văn bản đi mới' }}
        />
      )}
    </Card>
  );
}

// ---- Main Dashboard Page ----

export default function DashboardPage() {
  const user = useAuthStore((s) => s.user);
  const router = useRouter();

  const [statsLoading, setStatsLoading] = useState(true);
  const [stats, setStats] = useState<DashboardStats>({
    incoming_unread: 0,
    outgoing_pending: 0,
    handling_total: 0,
    handling_overdue: 0,
  });

  const [incomingLoading, setIncomingLoading] = useState(true);
  const [incomingData, setIncomingData] = useState<RecentIncomingItem[]>([]);

  const [tasksLoading, setTasksLoading] = useState(true);
  const [tasksData, setTasksData] = useState<UpcomingTaskItem[]>([]);

  const [outgoingLoading, setOutgoingLoading] = useState(true);
  const [outgoingData, setOutgoingData] = useState<RecentOutgoingItem[]>([]);

  const [layouts, setLayouts] = useState<ResponsiveLayouts>(
    () => loadSavedLayouts() || defaultLayouts
  );

  const { width: containerWidth, containerRef } = useContainerWidth();

  // Fetch all data
  useEffect(() => {
    // Stats
    api.get('/dashboard/stats')
      .then((res) => {
        setStats(res.data?.data || res.data || {});
      })
      .catch(() => {
        // Keep zeros on error
      })
      .finally(() => setStatsLoading(false));

    // Recent incoming
    api.get('/dashboard/recent-incoming?limit=5')
      .then((res) => {
        const d = res.data?.data || res.data || [];
        setIncomingData(Array.isArray(d) ? d : []);
      })
      .catch(() => setIncomingData([]))
      .finally(() => setIncomingLoading(false));

    // Upcoming tasks
    api.get('/dashboard/upcoming-tasks?limit=5')
      .then((res) => {
        const d = res.data?.data || res.data || [];
        setTasksData(Array.isArray(d) ? d : []);
      })
      .catch(() => setTasksData([]))
      .finally(() => setTasksLoading(false));

    // Recent outgoing
    api.get('/dashboard/recent-outgoing?limit=5')
      .then((res) => {
        const d = res.data?.data || res.data || [];
        setOutgoingData(Array.isArray(d) ? d : []);
      })
      .catch(() => setOutgoingData([]))
      .finally(() => setOutgoingLoading(false));
  }, []);

  const handleLayoutChange = useCallback((_currentLayout: readonly LayoutItem[], allLayouts: ResponsiveLayouts) => {
    setLayouts(allLayouts);
    try {
      localStorage.setItem(LAYOUT_STORAGE_KEY, JSON.stringify(allLayouts));
    } catch {
      // ignore storage errors
    }
  }, []);

  // KPI card config
  const statCards = [
    {
      key: 'incoming_unread',
      title: 'Văn bản đến chưa đọc',
      value: stats.incoming_unread,
      icon: <InboxOutlined />,
      gradient: 'linear-gradient(135deg, #1B3A5C 0%, #2d5a8e 100%)',
      shadowColor: 'rgba(27, 58, 92, 0.3)',
      route: '/van-ban-den',
    },
    {
      key: 'outgoing_pending',
      title: 'Văn bản đi chưa duyệt',
      value: stats.outgoing_pending,
      icon: <SendOutlined />,
      gradient: 'linear-gradient(135deg, #0891B2 0%, #06b6d4 100%)',
      shadowColor: 'rgba(8, 145, 178, 0.3)',
      route: '/van-ban-di',
    },
    {
      key: 'handling_total',
      title: 'Hồ sơ công việc',
      value: stats.handling_total,
      icon: <FolderOpenOutlined />,
      gradient: 'linear-gradient(135deg, #059669 0%, #10b981 100%)',
      shadowColor: 'rgba(5, 150, 105, 0.3)',
      route: '/ho-so-cong-viec',
    },
    {
      key: 'handling_overdue',
      title: 'Việc sắp tới hạn',
      value: stats.handling_overdue,
      icon: <ClockCircleOutlined />,
      gradient: 'linear-gradient(135deg, #D97706 0%, #f59e0b 100%)',
      shadowColor: 'rgba(217, 119, 6, 0.3)',
      route: '/ho-so-cong-viec',
    },
  ];

  return (
    <div>
      {/* Welcome header */}
      <div className="page-header">
        <h2 className="page-title">
          Xin chào, {user?.fullName || 'Người dùng'}
        </h2>
        <p className="page-description">
          Tổng quan hoạt động hệ thống văn bản
        </p>
      </div>

      {/* KPI Cards */}
      <Row gutter={[20, 20]} style={{ marginBottom: 24 }}>
        {statCards.map((card) => (
          <Col xs={24} sm={12} lg={6} key={card.key}>
            {statsLoading ? (
              <Skeleton.Button active block style={{ height: 88, borderRadius: 12 }} />
            ) : (
              <Card
                className="stat-card"
                variant="borderless"
                onClick={() => router.push(card.route)}
                style={{
                  boxShadow: `0 4px 16px ${card.shadowColor}`,
                  background: card.gradient,
                }}
                styles={{ body: { padding: 20 } }}
                hoverable
              >
                <div className="stat-card-body">
                  <div>
                    <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.7)', margin: '0 0 8px 0' }}>
                      {card.title}
                    </p>
                    <p style={{ fontSize: 32, fontWeight: 700, color: '#ffffff', margin: 0, lineHeight: 1 }}>
                      {card.value ?? 0}
                    </p>
                  </div>
                  <div
                    className="stat-card-icon"
                    style={{
                      background: 'rgba(255,255,255,0.15)',
                      fontSize: 22,
                      color: 'rgba(255,255,255,0.9)',
                    }}
                  >
                    {card.icon}
                  </div>
                </div>
              </Card>
            )}
          </Col>
        ))}
      </Row>

      {/* Draggable Widgets */}
      <div ref={containerRef}>
      <ResponsiveGridLayout
        className="layout"
        width={containerWidth}
        layouts={layouts}
        breakpoints={{ lg: 1200, md: 996, sm: 768 }}
        cols={{ lg: 12, md: 10, sm: 6 }}
        rowHeight={60}
        dragConfig={{ handle: '.widget-drag-handle' }}
        onLayoutChange={handleLayoutChange}
        margin={[16, 16]}
        containerPadding={[0, 0]}
      >
        <div key="incoming">
          <IncomingWidget data={incomingData} loading={incomingLoading} />
        </div>
        <div key="tasks">
          <TasksWidget data={tasksData} loading={tasksLoading} />
        </div>
        <div key="outgoing">
          <OutgoingWidget data={outgoingData} loading={outgoingLoading} />
        </div>
      </ResponsiveGridLayout>
      </div>
    </div>
  );
}
