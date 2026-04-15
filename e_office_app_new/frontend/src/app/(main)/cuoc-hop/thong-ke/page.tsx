'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Row, Col, Select, Skeleton, App, Typography, Table, Tag } from 'antd';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

const { Title } = Typography;

// ─── Interfaces ──────────────────────────────────────────────────────────────

interface MonthlyStats {
  month: number;
  meeting_count: number;
}

interface RoomStats {
  room_name: string;
  meeting_count: number;
}

interface TypeStats {
  meeting_type_name: string;
  meeting_count: number;
}

interface MeetingStats {
  by_month: MonthlyStats[];
  by_room: RoomStats[];
  by_type: TypeStats[];
  total: number;
  approved: number;
  pending: number;
  rejected: number;
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function CuocHopThongKePage() {
  const { message } = App.useApp();
  const [year, setYear] = useState<number>(dayjs().year());
  const [stats, setStats] = useState<MeetingStats | null>(null);
  const [loading, setLoading] = useState(false);

  const fetchStats = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/cuoc-hop/thong-ke', { params: { year } });
      setStats(res.data || null);
    } catch {
      message.error('Lỗi tải thống kê cuộc họp');
    } finally {
      setLoading(false);
    }
  }, [year, message]);

  useEffect(() => {
    fetchStats();
  }, [fetchStats]);

  // ── Chart data transformations ────────────────────────────────────────────────

  const monthlyData = stats?.by_month
    ? Array.from({ length: 12 }, (_, i) => {
        const found = stats.by_month.find((m) => m.month === i + 1);
        return {
          month: `Tháng ${i + 1}`,
          'Số cuộc họp': found?.meeting_count || 0,
        };
      })
    : [];

  const roomData = stats?.by_room?.map((r, i) => ({
    _key: `room-${i}`,
    type: r.room_name || 'Không xác định',
    value: r.meeting_count,
  })) || [];

  const typeData = stats?.by_type?.map((t, i) => ({
    _key: `type-${i}`,
    'Loại cuộc họp': t.meeting_type_name || 'Không xác định',
    'Số cuộc họp': t.meeting_count,
  })) || [];

  // ── Year options ──────────────────────────────────────────────────────────────

  const currentYear = dayjs().year();
  const yearOptions = Array.from({ length: 5 }, (_, i) => ({
    value: currentYear - i,
    label: `Năm ${currentYear - i}`,
  }));

  return (
    <div className="page-card">
      {/* Header */}
      <div className="page-header">
        <h2 className="page-title">Thống kê cuộc họp</h2>
        <Select
          value={year}
          onChange={setYear}
          options={yearOptions}
          style={{ width: 140 }}
        />
      </div>

      {loading ? (
        <Skeleton active paragraph={{ rows: 10 }} />
      ) : (
        <>
          {/* Summary cards */}
          {stats && (
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
              <Col xs={12} sm={6}>
                <Card className="stat-card" style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 32, fontWeight: 700, color: '#1B3A5C' }}>{stats.total || 0}</div>
                  <div style={{ color: '#64748B', marginTop: 4 }}>Tổng cuộc họp</div>
                </Card>
              </Col>
              <Col xs={12} sm={6}>
                <Card className="stat-card" style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 32, fontWeight: 700, color: '#059669' }}>{stats.approved || 0}</div>
                  <div style={{ color: '#64748B', marginTop: 4 }}>Đã duyệt</div>
                </Card>
              </Col>
              <Col xs={12} sm={6}>
                <Card className="stat-card" style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 32, fontWeight: 700, color: '#D97706' }}>{stats.pending || 0}</div>
                  <div style={{ color: '#64748B', marginTop: 4 }}>Chờ duyệt</div>
                </Card>
              </Col>
              <Col xs={12} sm={6}>
                <Card className="stat-card" style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 32, fontWeight: 700, color: '#DC2626' }}>{stats.rejected || 0}</div>
                  <div style={{ color: '#64748B', marginTop: 4 }}>Từ chối</div>
                </Card>
              </Col>
            </Row>
          )}

          <Row gutter={[16, 16]}>
            {/* Monthly table */}
            <Col span={24}>
              <Card title={<Title level={5} style={{ margin: 0 }}>Cuộc họp theo tháng — Năm {year}</Title>}>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  {monthlyData.map((m) => (
                    <div key={m.month} style={{
                      flex: '1 1 70px', textAlign: 'center', padding: '12px 8px',
                      background: m['Số cuộc họp'] > 0 ? '#0891B2' : '#F1F5F9',
                      borderRadius: 8, color: m['Số cuộc họp'] > 0 ? '#fff' : '#94A3B8',
                    }}>
                      <div style={{ fontSize: 20, fontWeight: 700 }}>{m['Số cuộc họp']}</div>
                      <div style={{ fontSize: 11, marginTop: 4 }}>{m.month}</div>
                    </div>
                  ))}
                </div>
              </Card>
            </Col>

            {/* Room table */}
            <Col xs={24} md={12}>
              <Card title={<Title level={5} style={{ margin: 0 }}>Theo phòng họp</Title>}>
                <Table
                  dataSource={roomData}
                  rowKey="_key"
                  pagination={false}
                  size="small"
                  columns={[
                    { title: 'Phòng họp', dataIndex: 'type', ellipsis: true },
                    { title: 'Số cuộc họp', dataIndex: 'value', width: 100, align: 'center',
                      render: (v: number) => <Tag color="cyan">{v}</Tag> },
                  ]}
                />
              </Card>
            </Col>

            {/* Type table */}
            <Col xs={24} md={12}>
              <Card title={<Title level={5} style={{ margin: 0 }}>Theo loại cuộc họp</Title>}>
                <Table
                  dataSource={typeData}
                  rowKey="_key"
                  pagination={false}
                  size="small"
                  columns={[
                    { title: 'Loại', dataIndex: 'Loại cuộc họp', ellipsis: true },
                    { title: 'Số cuộc họp', dataIndex: 'Số cuộc họp', width: 100, align: 'center',
                      render: (v: number) => <Tag color="blue">{v}</Tag> },
                  ]}
                />
              </Card>
            </Col>
          </Row>
        </>
      )}
    </div>
  );
}
