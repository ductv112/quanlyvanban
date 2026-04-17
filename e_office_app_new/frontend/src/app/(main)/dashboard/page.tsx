'use client';

import React, { useEffect, useState, useMemo } from 'react';
import { Card, Row, Col, Table, Tag, Progress, Skeleton, Button, Badge, Timeline } from 'antd';
import {
  InboxOutlined,
  SendOutlined,
  FolderOpenOutlined,
  ClockCircleOutlined,
  FileTextOutlined,
  EditOutlined,
  MessageOutlined,
  BellOutlined,
  CalendarOutlined,
  PlusOutlined,
  BarChartOutlined,
} from '@ant-design/icons';
import { useRouter } from 'next/navigation';
import { Column, Pie } from '@ant-design/charts';
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

interface StatsExtra {
  drafting_pending: number;
  message_unread: number;
  notice_unread: number;
  today_meetings: number;
}

interface RecentIncomingItem {
  id: number | string;
  doc_code: string;
  abstract: string;
  received_date: string;
  urgency_name: string;
}

interface UpcomingTaskItem {
  id: number | string;
  title: string;
  status: number;
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

interface DocByMonthItem {
  month_label: string;
  incoming_count: number;
  outgoing_count: number;
}

interface TaskByStatusItem {
  status_code: number;
  status_name: string;
  task_count: number;
}

interface RecentNoticeItem {
  id: number;
  title: string;
  notice_type: string;
  created_at: string;
  is_read: boolean;
}

interface CalendarTodayItem {
  id: number;
  title: string;
  start_time: string;
  end_time: string;
  all_day: boolean;
  color: string;
  scope: string;
}

// ---- Helpers ----

const statusMap: Record<number, string> = {
  0: 'Mới', 1: 'Đang xử lý', 2: 'Chờ duyệt', 3: 'Đã duyệt',
  4: 'Hoàn thành', [-1]: 'Từ chối', [-2]: 'Trả về',
};

function statusTagColor(s: number): string {
  if (s === 4) return 'success';
  if (s === -1 || s === -2) return 'error';
  if (s === 1 || s === 2) return 'processing';
  if (s === 3) return 'warning';
  return 'default';
}

const STATUS_COLORS: Record<number, string> = {
  0: '#8c8c8c', 1: '#1677ff', 2: '#fa8c16', 3: '#faad14',
  4: '#52c41a', [-1]: '#ff4d4f', [-2]: '#ff7a45',
};

const noticeTypeTag: Record<string, { color: string; label: string }> = {
  system: { color: 'blue', label: 'Hệ thống' },
  maintenance: { color: 'orange', label: 'Bảo trì' },
  update: { color: 'green', label: 'Cập nhật' },
  guide: { color: 'cyan', label: 'Hướng dẫn' },
  security: { color: 'red', label: 'Bảo mật' },
};

// ---- Section header ----

function SectionHeader({ icon, iconBg, title }: { icon: React.ReactNode; iconBg: string; title: string }) {
  return (
    <div className="section-card-header">
      <div className="section-card-icon" style={{ background: iconBg }}>
        {icon}
      </div>
      <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{title}</span>
    </div>
  );
}

// ---- Main Dashboard Page ----

export default function DashboardPage() {
  const user = useAuthStore((s) => s.user);
  const router = useRouter();

  // Stats
  const [statsLoading, setStatsLoading] = useState(true);
  const [stats, setStats] = useState<DashboardStats>({ incoming_unread: 0, outgoing_pending: 0, handling_total: 0, handling_overdue: 0 });
  const [extraLoading, setExtraLoading] = useState(true);
  const [extra, setExtra] = useState<StatsExtra>({ drafting_pending: 0, message_unread: 0, notice_unread: 0, today_meetings: 0 });

  // Lists
  const [incomingLoading, setIncomingLoading] = useState(true);
  const [incomingData, setIncomingData] = useState<RecentIncomingItem[]>([]);
  const [tasksLoading, setTasksLoading] = useState(true);
  const [tasksData, setTasksData] = useState<UpcomingTaskItem[]>([]);
  const [outgoingLoading, setOutgoingLoading] = useState(true);
  const [outgoingData, setOutgoingData] = useState<RecentOutgoingItem[]>([]);

  // Charts
  const [docMonthLoading, setDocMonthLoading] = useState(true);
  const [docMonthData, setDocMonthData] = useState<DocByMonthItem[]>([]);
  const [taskStatusLoading, setTaskStatusLoading] = useState(true);
  const [taskStatusData, setTaskStatusData] = useState<TaskByStatusItem[]>([]);

  // Utility
  const [calendarLoading, setCalendarLoading] = useState(true);
  const [calendarData, setCalendarData] = useState<CalendarTodayItem[]>([]);
  const [noticesLoading, setNoticesLoading] = useState(true);
  const [noticesData, setNoticesData] = useState<RecentNoticeItem[]>([]);

  useEffect(() => {
    const safe = (p: Promise<any>) => p.catch(() => null);
    const arr = (res: any) => { const d = res?.data?.data ?? res?.data ?? []; return Array.isArray(d) ? d : []; };
    const obj = (res: any) => res?.data?.data ?? res?.data ?? null;

    safe(api.get('/dashboard/stats')).then((r) => { const v = obj(r); if (v) setStats(v); }).finally(() => setStatsLoading(false));
    safe(api.get('/dashboard/stats-extra')).then((r) => { const v = obj(r); if (v) setExtra(v); }).finally(() => setExtraLoading(false));
    safe(api.get('/dashboard/recent-incoming?limit=5')).then((r) => setIncomingData(arr(r))).finally(() => setIncomingLoading(false));
    safe(api.get('/dashboard/upcoming-tasks?limit=5')).then((r) => setTasksData(arr(r))).finally(() => setTasksLoading(false));
    safe(api.get('/dashboard/recent-outgoing?limit=5')).then((r) => setOutgoingData(arr(r))).finally(() => setOutgoingLoading(false));
    safe(api.get('/dashboard/doc-by-month')).then((r) => setDocMonthData(arr(r))).finally(() => setDocMonthLoading(false));
    safe(api.get('/dashboard/task-by-status')).then((r) => setTaskStatusData(arr(r))).finally(() => setTaskStatusLoading(false));
    safe(api.get('/dashboard/calendar-today?days=7')).then((r) => setCalendarData(arr(r))).finally(() => setCalendarLoading(false));
    safe(api.get('/dashboard/recent-notices?limit=5')).then((r) => setNoticesData(arr(r))).finally(() => setNoticesLoading(false));
  }, []);

  // ---- Chart data transforms ----

  const docMonthChartData = useMemo(() => {
    const result: { month: string; count: number; type: string }[] = [];
    docMonthData.forEach((d) => {
      result.push({ month: d.month_label, count: Number(d.incoming_count), type: 'VB đến' });
      result.push({ month: d.month_label, count: Number(d.outgoing_count), type: 'VB đi' });
    });
    return result;
  }, [docMonthData]);

  const taskStatusChartData = useMemo(() =>
    taskStatusData.map((d) => ({
      name: d.status_name,
      value: Number(d.task_count),
      color: STATUS_COLORS[d.status_code] || '#8c8c8c',
    })),
  [taskStatusData]);

  // ---- Stat cards ----

  const statCards = [
    { key: 'incoming_unread', title: 'VB đến chưa đọc', value: stats.incoming_unread, icon: <InboxOutlined />, gradient: 'linear-gradient(135deg, #1B3A5C, #2d5a8e)', shadow: 'rgba(27,58,92,0.3)', route: '/van-ban-den' },
    { key: 'outgoing_pending', title: 'VB đi chờ duyệt', value: stats.outgoing_pending, icon: <SendOutlined />, gradient: 'linear-gradient(135deg, #0891B2, #06b6d4)', shadow: 'rgba(8,145,178,0.3)', route: '/van-ban-di' },
    { key: 'handling_total', title: 'Hồ sơ công việc', value: stats.handling_total, icon: <FolderOpenOutlined />, gradient: 'linear-gradient(135deg, #059669, #10b981)', shadow: 'rgba(5,150,105,0.3)', route: '/ho-so-cong-viec' },
    { key: 'handling_overdue', title: 'Việc quá hạn', value: stats.handling_overdue, icon: <ClockCircleOutlined />, gradient: 'linear-gradient(135deg, #D97706, #f59e0b)', shadow: 'rgba(217,119,6,0.3)', route: '/ho-so-cong-viec' },
    { key: 'drafting_pending', title: 'Dự thảo chờ phát hành', value: extra.drafting_pending, icon: <EditOutlined />, gradient: 'linear-gradient(135deg, #7c3aed, #a78bfa)', shadow: 'rgba(124,58,237,0.3)', route: '/van-ban-du-thao' },
    { key: 'message_unread', title: 'Tin nhắn chưa đọc', value: extra.message_unread, icon: <MessageOutlined />, gradient: 'linear-gradient(135deg, #dc2626, #f87171)', shadow: 'rgba(220,38,38,0.3)', route: '/tin-nhan' },
    { key: 'notice_unread', title: 'Thông báo chưa đọc', value: extra.notice_unread, icon: <BellOutlined />, gradient: 'linear-gradient(135deg, #ea580c, #fb923c)', shadow: 'rgba(234,88,12,0.3)', route: '/thong-bao' },
    { key: 'today_meetings', title: 'Lịch họp hôm nay', value: extra.today_meetings, icon: <CalendarOutlined />, gradient: 'linear-gradient(135deg, #0284c7, #38bdf8)', shadow: 'rgba(2,132,199,0.3)', route: '/lich/co-quan' },
  ];

  const cardLoading = statsLoading || extraLoading;

  // ---- Table columns ----

  const incomingColumns = [
    { title: 'Số/Ký hiệu', dataIndex: 'doc_code', key: 'doc_code', width: 130, render: (v: string) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v || '—'}</span> },
    { title: 'Trích yếu', dataIndex: 'abstract', key: 'abstract', ellipsis: true },
    { title: 'Ngày nhận', dataIndex: 'received_date', key: 'received_date', width: 95, render: (v: string) => v ? dayjs(v).format('DD/MM/YYYY') : '—' },
    { title: 'Độ khẩn', dataIndex: 'urgency_name', key: 'urgency_name', width: 80, render: (v: string) => {
      if (!v) return null;
      const c = v.includes('Hỏa') ? 'red' : v.includes('Khẩn') ? 'orange' : 'blue';
      return <Tag color={c}>{v}</Tag>;
    }},
  ];

  const outgoingColumns = [
    { title: 'Số/Ký hiệu', dataIndex: 'doc_code', key: 'doc_code', width: 130, render: (v: string) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v || '—'}</span> },
    { title: 'Trích yếu', dataIndex: 'abstract', key: 'abstract', ellipsis: true },
    { title: 'Ngày ban hành', dataIndex: 'sent_date', key: 'sent_date', width: 105, render: (v: string) => v ? dayjs(v).format('DD/MM/YYYY') : '—' },
    { title: 'Loại VB', dataIndex: 'doc_type_name', key: 'doc_type_name', width: 110, render: (v: string) => v ? <Tag color="geekblue">{v}</Tag> : null },
  ];

  // ---- Quick actions ----

  const quickActions = [
    { icon: <InboxOutlined />, label: 'Tạo VB đến', path: '/van-ban-den', color: '#1B3A5C' },
    { icon: <SendOutlined />, label: 'Tạo VB đi', path: '/van-ban-di', color: '#0891B2' },
    { icon: <EditOutlined />, label: 'Soạn dự thảo', path: '/van-ban-du-thao', color: '#059669' },
    { icon: <MessageOutlined />, label: 'Soạn tin nhắn', path: '/tin-nhan', color: '#D97706' },
    { icon: <FolderOpenOutlined />, label: 'Tạo HSCV', path: '/ho-so-cong-viec', color: '#7c3aed' },
    { icon: <CalendarOutlined />, label: 'Tạo lịch', path: '/lich/ca-nhan', color: '#dc2626' },
  ];

  return (
    <div>
      {/* Header */}
      <div className="page-header">
        <h2 className="page-title">Xin chào, {user?.fullName || 'Người dùng'}</h2>
        <p className="page-description">Tổng quan hoạt động hệ thống văn bản</p>
      </div>

      {/* ===== SECTION 1: Stat Cards (8 cards, 1 row on desktop) ===== */}
      <Row gutter={[12, 12]} style={{ marginBottom: 24 }}>
        {statCards.map((card) => (
          <Col xs={12} sm={6} lg={3} key={card.key}>
            {cardLoading ? (
              <Skeleton.Button active block style={{ height: 80, borderRadius: 12 }} />
            ) : (
              <Card
                className="stat-card"
                variant="borderless"
                onClick={() => router.push(card.route)}
                style={{ boxShadow: `0 4px 12px ${card.shadow}`, background: card.gradient }}
                styles={{ body: { padding: '14px 16px' } }}
                hoverable
              >
                <div className="stat-card-body">
                  <div>
                    <p style={{ fontSize: 11, color: 'rgba(255,255,255,0.7)', margin: '0 0 6px 0', lineHeight: 1.3 }}>{card.title}</p>
                    <p style={{ fontSize: 26, fontWeight: 700, color: '#fff', margin: 0, lineHeight: 1 }}>{card.value ?? 0}</p>
                  </div>
                  <div className="stat-card-icon" style={{ background: 'rgba(255,255,255,0.15)', fontSize: 18, color: 'rgba(255,255,255,0.9)' }}>
                    {card.icon}
                  </div>
                </div>
              </Card>
            )}
          </Col>
        ))}
      </Row>

      {/* ===== SECTION 2: Biểu đồ thống kê ===== */}
      <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
        {/* Biểu đồ cột: VB theo tháng */}
        <Col xs={24} lg={14}>
          <Card
            className="page-card" variant="borderless"
            title={<SectionHeader icon={<BarChartOutlined style={{ color: '#fff', fontSize: 14 }} />} iconBg="linear-gradient(135deg, #1B3A5C, #2d5a8e)" title="Văn bản đến/đi theo tháng" />}
            styles={{ body: { padding: '12px 16px' } }}
          >
            {docMonthLoading ? <Skeleton active paragraph={{ rows: 4 }} /> : (
              <Column
                data={docMonthChartData}
                xField="month" yField="count" colorField="type"
                group
                scale={{ color: { range: ['#1B3A5C', '#0891B2'] } }}
                axis={{ y: { title: 'Số lượng' }, x: { title: false } }}
                legend={{ position: 'top-right' }}
                height={240}
              />
            )}
          </Card>
        </Col>

        {/* Biểu đồ tròn: HSCV theo trạng thái */}
        <Col xs={24} lg={10}>
          <Card
            className="page-card" variant="borderless"
            title={<SectionHeader icon={<FolderOpenOutlined style={{ color: '#fff', fontSize: 14 }} />} iconBg="linear-gradient(135deg, #059669, #10b981)" title="HSCV theo trạng thái" />}
            styles={{ body: { padding: '12px 16px' } }}
          >
            {taskStatusLoading ? <Skeleton active paragraph={{ rows: 4 }} /> : taskStatusChartData.length === 0 ? (
              <div style={{ textAlign: 'center', color: '#94a3b8', padding: '40px 0' }}>Chưa có dữ liệu</div>
            ) : (
              <Pie
                data={taskStatusChartData}
                angleField="value" colorField="name"
                innerRadius={0.55}
                label={{ text: 'value', position: 'outside' }}
                legend={{ position: 'right' }}
                height={240}
                scale={{ color: { range: taskStatusChartData.map((d) => d.color) } }}
              />
            )}
          </Card>
        </Col>
      </Row>

      {/* ===== SECTION 3: Danh sách VB đến + Việc sắp tới hạn ===== */}
      <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
        <Col xs={24} lg={14}>
          <Card
            className="page-card" variant="borderless"
            title={<SectionHeader icon={<FileTextOutlined style={{ color: '#fff', fontSize: 14 }} />} iconBg="linear-gradient(135deg, #1B3A5C, #0891B2)" title="Văn bản mới nhận" />}
            extra={<Button type="link" size="small" onClick={() => router.push('/van-ban-den')}>Xem thêm</Button>}
            styles={{ body: { padding: '8px 16px' } }}
          >
            {incomingLoading ? <Skeleton active paragraph={{ rows: 4 }} /> : (
              <Table dataSource={incomingData} columns={incomingColumns} rowKey="id" size="small" pagination={false} locale={{ emptyText: 'Chưa có văn bản mới' }} />
            )}
          </Card>
        </Col>

        <Col xs={24} lg={10}>
          <Card
            className="page-card" variant="borderless"
            title={<SectionHeader icon={<ClockCircleOutlined style={{ color: '#fff', fontSize: 14 }} />} iconBg="linear-gradient(135deg, #D97706, #f59e0b)" title="Việc sắp tới hạn" />}
            extra={<Button type="link" size="small" onClick={() => router.push('/ho-so-cong-viec')}>Xem thêm</Button>}
            styles={{ body: { padding: '8px 16px' } }}
          >
            {tasksLoading ? <Skeleton active paragraph={{ rows: 4 }} /> : tasksData.length === 0 ? (
              <div style={{ textAlign: 'center', color: '#94a3b8', padding: '32px 0', fontSize: 13 }}>Không có việc sắp tới hạn</div>
            ) : (
              <div>
                {tasksData.map((item) => (
                  <div key={item.id} style={{ padding: '8px 0', borderBottom: '1px solid #f0f0f0' }}>
                    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 4 }}>
                      <span style={{ fontWeight: 600, fontSize: 13, color: '#1B3A5C', flex: 1, marginRight: 8 }}>{item.title}</span>
                      <Tag color={statusTagColor(item.status)} style={{ flexShrink: 0 }}>{statusMap[item.status] || 'Đang xử lý'}</Tag>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                      <Progress percent={item.progress_percent ?? 0} size="small" style={{ flex: 1, margin: 0 }} strokeColor="#0891B2" />
                      <span style={{ fontSize: 11, color: '#94a3b8', flexShrink: 0 }}>{item.deadline ? dayjs(item.deadline).format('DD/MM') : '—'}</span>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </Col>
      </Row>

      {/* ===== SECTION 4: VB đi + Thao tác nhanh ===== */}
      <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
        <Col xs={24} lg={14}>
          <Card
            className="page-card" variant="borderless"
            title={<SectionHeader icon={<SendOutlined style={{ color: '#fff', fontSize: 14 }} />} iconBg="linear-gradient(135deg, #059669, #10b981)" title="Văn bản đi mới" />}
            extra={<Button type="link" size="small" onClick={() => router.push('/van-ban-di')}>Xem thêm</Button>}
            styles={{ body: { padding: '8px 16px' } }}
          >
            {outgoingLoading ? <Skeleton active paragraph={{ rows: 4 }} /> : (
              <Table dataSource={outgoingData} columns={outgoingColumns} rowKey="id" size="small" pagination={false} locale={{ emptyText: 'Chưa có văn bản đi mới' }} />
            )}
          </Card>
        </Col>

        <Col xs={24} lg={10}>
          <Card
            className="page-card" variant="borderless"
            title={<SectionHeader icon={<PlusOutlined style={{ color: '#fff', fontSize: 14 }} />} iconBg="linear-gradient(135deg, #6366f1, #818cf8)" title="Thao tác nhanh" />}
            styles={{ body: { padding: '12px 16px' } }}
          >
            <Row gutter={[8, 8]}>
              {quickActions.map((a) => (
                <Col span={8} key={a.path}>
                  <Button
                    type="text" block
                    onClick={() => router.push(a.path)}
                    style={{ height: 'auto', padding: '12px 4px', display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, borderRadius: 8, border: '1px solid #f0f0f0' }}
                  >
                    <span style={{ fontSize: 20, color: a.color }}>{a.icon}</span>
                    <span style={{ fontSize: 11, color: '#595959' }}>{a.label}</span>
                  </Button>
                </Col>
              ))}
            </Row>
          </Card>
        </Col>
      </Row>

      {/* ===== SECTION 5: Lịch + Thông báo ===== */}
      <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
        {/* Lịch sắp tới */}
        <Col xs={24} lg={12}>
          <Card
            className="page-card" variant="borderless"
            title={<SectionHeader icon={<CalendarOutlined style={{ color: '#fff', fontSize: 14 }} />} iconBg="linear-gradient(135deg, #dc2626, #f87171)" title="Lịch sắp tới" />}
            extra={<Button type="link" size="small" onClick={() => router.push('/lich/ca-nhan')}>Xem thêm</Button>}
            styles={{ body: { padding: '12px 16px' } }}
          >
            {calendarLoading ? <Skeleton active paragraph={{ rows: 3 }} /> : calendarData.length === 0 ? (
              <div style={{ textAlign: 'center', color: '#94a3b8', padding: '24px 0', fontSize: 13 }}>Không có sự kiện</div>
            ) : (
              <Timeline
                items={calendarData.map((ev) => ({
                  color: ev.color || '#1B3A5C',
                  content: (
                    <div>
                      <div style={{ fontWeight: 600, fontSize: 13, color: '#1B3A5C' }}>{ev.title}</div>
                      <div style={{ fontSize: 11, color: '#94a3b8' }}>
                        {ev.all_day
                          ? dayjs(ev.start_time).format('DD/MM') + ' — Cả ngày'
                          : dayjs(ev.start_time).format('DD/MM HH:mm') + ' – ' + dayjs(ev.end_time).format('HH:mm')
                        }
                        {ev.scope !== 'personal' && (
                          <Tag color={ev.scope === 'leader' ? 'red' : 'blue'} style={{ marginLeft: 6, fontSize: 10 }}>
                            {ev.scope === 'leader' ? 'Lãnh đạo' : 'Cơ quan'}
                          </Tag>
                        )}
                      </div>
                    </div>
                  ),
                }))}
              />
            )}
          </Card>
        </Col>

        {/* Thông báo mới nhất */}
        <Col xs={24} lg={12}>
          <Card
            className="page-card" variant="borderless"
            title={<SectionHeader icon={<BellOutlined style={{ color: '#fff', fontSize: 14 }} />} iconBg="linear-gradient(135deg, #ea580c, #fb923c)" title="Thông báo mới nhất" />}
            extra={<Button type="link" size="small" onClick={() => router.push('/thong-bao')}>Xem thêm</Button>}
            styles={{ body: { padding: '8px 16px' } }}
          >
            {noticesLoading ? <Skeleton active paragraph={{ rows: 3 }} /> : noticesData.length === 0 ? (
              <div style={{ textAlign: 'center', color: '#94a3b8', padding: '24px 0', fontSize: 13 }}>Không có thông báo</div>
            ) : (
              <div>
                {noticesData.map((n) => {
                  const t = noticeTypeTag[n.notice_type] || { color: 'default', label: n.notice_type };
                  return (
                    <div key={n.id} style={{ padding: '8px 0', borderBottom: '1px solid #f0f0f0', display: 'flex', alignItems: 'flex-start', gap: 8 }}>
                      <Badge dot={!n.is_read} offset={[-2, 2]}>
                        <BellOutlined style={{ fontSize: 16, color: '#94a3b8', marginTop: 2 }} />
                      </Badge>
                      <div style={{ flex: 1 }}>
                        <div style={{ fontWeight: n.is_read ? 400 : 600, fontSize: 13, color: '#1B3A5C' }}>{n.title}</div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 2 }}>
                          <Tag color={t.color} style={{ fontSize: 10, lineHeight: '16px', padding: '0 4px' }}>{t.label}</Tag>
                          <span style={{ fontSize: 11, color: '#94a3b8' }}>{dayjs(n.created_at).format('DD/MM HH:mm')}</span>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </Card>
        </Col>

      </Row>
    </div>
  );
}
