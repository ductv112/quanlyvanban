'use client';

import React from 'react';
import { Card, Row, Col, Statistic, Tag } from 'antd';
import {
  InboxOutlined,
  SendOutlined,
  FolderOpenOutlined,
  ClockCircleOutlined,
  ArrowUpOutlined,
  FileTextOutlined,
} from '@ant-design/icons';
import { useAuthStore } from '@/stores/auth.store';

const statCards = [
  {
    title: 'Văn bản đến chưa đọc',
    value: 12,
    icon: <InboxOutlined />,
    gradient: 'linear-gradient(135deg, #1B3A5C 0%, #2d5a8e 100%)',
    shadowColor: 'rgba(27, 58, 92, 0.3)',
  },
  {
    title: 'Văn bản đi chưa đọc',
    value: 5,
    icon: <SendOutlined />,
    gradient: 'linear-gradient(135deg, #0891B2 0%, #06b6d4 100%)',
    shadowColor: 'rgba(8, 145, 178, 0.3)',
  },
  {
    title: 'Hồ sơ công việc',
    value: 28,
    icon: <FolderOpenOutlined />,
    gradient: 'linear-gradient(135deg, #059669 0%, #10b981 100%)',
    shadowColor: 'rgba(5, 150, 105, 0.3)',
  },
  {
    title: 'Việc sắp tới hạn',
    value: 3,
    icon: <ClockCircleOutlined />,
    gradient: 'linear-gradient(135deg, #D97706 0%, #f59e0b 100%)',
    shadowColor: 'rgba(217, 119, 6, 0.3)',
  },
];

export default function DashboardPage() {
  const user = useAuthStore((s) => s.user);

  return (
    <div>
      {/* Welcome */}
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ fontSize: 24, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Xin chào, {user?.fullName || 'Người dùng'}
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Tổng quan hoạt động hệ thống văn bản
        </p>
      </div>

      {/* KPI Cards */}
      <Row gutter={[20, 20]} style={{ marginBottom: 24 }}>
        {statCards.map((card, index) => (
          <Col xs={24} sm={12} lg={6} key={index}>
            <Card
              bordered={false}
              style={{
                borderRadius: 12,
                boxShadow: `0 4px 16px ${card.shadowColor}`,
                background: card.gradient,
                cursor: 'pointer',
                transition: 'transform 0.2s ease, box-shadow 0.2s ease',
              }}
              styles={{ body: { padding: 20 } }}
              hoverable
            >
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                <div>
                  <p style={{ fontSize: 13, color: 'rgba(255,255,255,0.7)', margin: '0 0 8px 0' }}>
                    {card.title}
                  </p>
                  <p style={{ fontSize: 32, fontWeight: 700, color: '#ffffff', margin: 0, lineHeight: 1 }}>
                    {card.value}
                  </p>
                </div>
                <div
                  style={{
                    width: 48,
                    height: 48,
                    borderRadius: 12,
                    background: 'rgba(255,255,255,0.15)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                    fontSize: 22,
                    color: 'rgba(255,255,255,0.9)',
                  }}
                >
                  {card.icon}
                </div>
              </div>
            </Card>
          </Col>
        ))}
      </Row>

      {/* Recent activity placeholder */}
      <Row gutter={[20, 20]}>
        <Col xs={24} lg={16}>
          <Card
            title={
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div
                  style={{
                    width: 32,
                    height: 32,
                    borderRadius: 8,
                    background: 'linear-gradient(135deg, #1B3A5C, #0891B2)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <FileTextOutlined style={{ color: '#fff', fontSize: 16 }} />
                </div>
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Văn bản mới nhận</span>
                <Tag color="blue">Hôm nay</Tag>
              </div>
            }
            bordered={false}
            style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
          >
            <div style={{ textAlign: 'center', padding: '40px 0', color: '#94a3b8' }}>
              <InboxOutlined style={{ fontSize: 48, marginBottom: 16, display: 'block' }} />
              <p style={{ margin: 0 }}>Dữ liệu sẽ hiển thị khi kết nối database</p>
            </div>
          </Card>
        </Col>
        <Col xs={24} lg={8}>
          <Card
            title={
              <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                <div
                  style={{
                    width: 32,
                    height: 32,
                    borderRadius: 8,
                    background: 'linear-gradient(135deg, #D97706, #f59e0b)',
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center',
                  }}
                >
                  <ClockCircleOutlined style={{ color: '#fff', fontSize: 16 }} />
                </div>
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Việc sắp tới hạn</span>
              </div>
            }
            bordered={false}
            style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
          >
            <div style={{ textAlign: 'center', padding: '40px 0', color: '#94a3b8' }}>
              <ClockCircleOutlined style={{ fontSize: 48, marginBottom: 16, display: 'block' }} />
              <p style={{ margin: 0 }}>Chưa có việc sắp tới hạn</p>
            </div>
          </Card>
        </Col>
      </Row>
    </div>
  );
}
