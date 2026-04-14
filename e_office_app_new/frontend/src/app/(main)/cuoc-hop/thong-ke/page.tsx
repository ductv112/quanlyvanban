'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Row, Col, Select, Skeleton, App, Typography } from 'antd';
import { Column, Pie } from '@ant-design/charts';
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

  const roomData = stats?.by_room?.map((r) => ({
    type: r.room_name || 'Không xác định',
    value: r.meeting_count,
  })) || [];

  const typeData = stats?.by_type?.map((t) => ({
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
            {/* Monthly bar chart */}
            <Col span={24}>
              <Card title={<Title level={5} style={{ margin: 0 }}>Cuộc họp theo tháng — Năm {year}</Title>}>
                {monthlyData.length > 0 ? (
                  <Column
                    data={monthlyData}
                    xField="month"
                    yField="Số cuộc họp"
                    style={{ fill: '#0891B2' }}
                    label={{
                      position: 'inside',
                      style: { fill: '#fff', fontSize: 12 },
                    }}
                    xAxis={{ label: { style: { fontSize: 12 } } }}
                    yAxis={{ grid: { line: { style: { stroke: '#E2E8F0' } } } }}
                    height={280}
                  />
                ) : (
                  <div className="empty-center" style={{ height: 200 }}>Không có dữ liệu</div>
                )}
              </Card>
            </Col>

            {/* Room pie chart */}
            <Col xs={24} md={12}>
              <Card title={<Title level={5} style={{ margin: 0 }}>Cuộc họp theo phòng họp</Title>}>
                {roomData.length > 0 ? (
                  <Pie
                    data={roomData}
                    angleField="value"
                    colorField="type"
                    radius={0.8}
                    label={{
                      type: 'outer',
                      content: '{name}: {value}',
                    }}
                    legend={{ position: 'bottom' }}
                    height={280}
                    color={['#1B3A5C', '#0891B2', '#059669', '#D97706', '#7C3AED', '#DC2626', '#0E7490']}
                  />
                ) : (
                  <div className="empty-center" style={{ height: 200 }}>Không có dữ liệu</div>
                )}
              </Card>
            </Col>

            {/* Type bar chart */}
            <Col xs={24} md={12}>
              <Card title={<Title level={5} style={{ margin: 0 }}>Cuộc họp theo loại</Title>}>
                {typeData.length > 0 ? (
                  <Column
                    data={typeData}
                    xField="Loại cuộc họp"
                    yField="Số cuộc họp"
                    style={{ fill: '#1B3A5C' }}
                    label={{
                      position: 'inside',
                      style: { fill: '#fff', fontSize: 12 },
                    }}
                    height={280}
                  />
                ) : (
                  <div className="empty-center" style={{ height: 200 }}>Không có dữ liệu</div>
                )}
              </Card>
            </Col>
          </Row>
        </>
      )}
    </div>
  );
}
