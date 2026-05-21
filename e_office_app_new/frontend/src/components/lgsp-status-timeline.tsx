'use client';

import React, { useCallback, useEffect, useState } from 'react';
import { Timeline, Tag, Tooltip, Card, Empty, Skeleton, Space, Typography, Spin, Button, App, Popconfirm } from 'antd';
import { ApiOutlined, ClockCircleOutlined, CheckCircleOutlined, CloseCircleOutlined, ReloadOutlined } from '@ant-design/icons';
import dayjs from 'dayjs';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import {
  LGSP_STATUS_LABELS,
  LGSP_STATUS_COLORS,
  LGSP_STATUS_DESCRIPTIONS,
  SENT_STATUS_COLORS,
  SENT_STATUS_LABELS,
  type LgspTargetStatus,
} from '@/lib/lgsp-status-labels';

const { Text } = Typography;

// ============================================================
// LGSP Status Timeline Component — Phase 36 Plan 36-04
// REQ: LGSP-STATUS-10
//
// Render chronological list outbox events cho 1 VB nguon LGSP.
// Fetch tu GET /api/van-ban-den/:id/lgsp-status-history (Plan 36-03).
// Polling 10s khi co >=1 row pending (auto-refresh sau worker xu ly xong).
// ============================================================

/**
 * Row shape tu backend GET /lgsp-status-history (Plan 36-03).
 * BIGINT id pg driver tra string -> Number() wrap.
 */
export interface LgspStatusHistoryRow {
  id: number;
  target_status: LgspTargetStatus;
  sent_status: 'pending' | 'success' | 'error';
  sent_at: string | null;
  retry_count: number;
  error_message: string | null;
  created_at: string;
}

interface Props {
  incomingDocId: number;
}

const POLL_INTERVAL_MS = 10_000;

export function LgspStatusTimeline({ incomingDocId }: Props): React.ReactElement {
  const [rows, setRows] = useState<LgspStatusHistoryRow[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Phase 37 Plan 37-06: admin role gate + retry handler cho entry sent_status='error'
  const { message: msg } = App.useApp();
  const isAdmin = useAuthStore((s) =>
    (s.user?.isAdmin ?? false) || (s.user?.roles?.includes('Quản trị hệ thống') ?? false),
  );
  const [retryingId, setRetryingId] = useState<number | null>(null);

  const fetchHistory = useCallback(async () => {
    try {
      const res = await api.get<{ success: boolean; data: LgspStatusHistoryRow[] }>(
        `/van-ban-den/${incomingDocId}/lgsp-status-history`,
      );
      if (res.data?.success && Array.isArray(res.data.data)) {
        // BIGINT id pg driver tra string -- normalize qua Number()
        setRows(res.data.data.map((r) => ({ ...r, id: Number(r.id), retry_count: Number(r.retry_count) })));
        setError(null);
      } else {
        setRows([]);
      }
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : 'Không tải được lịch sử trạng thái LGSP';
      setError(msg);
    } finally {
      setLoading(false);
    }
  }, [incomingDocId]);

  // Phase 37 Plan 37-06: retry handler cho outbox event sent_status='error'
  const handleRetry = useCallback(async (outboxId: number) => {
    setRetryingId(outboxId);
    try {
      const { data: res } = await api.post(`/admin/lgsp-status-outbox/${outboxId}/retry`);
      if (res?.success) {
        msg.success(res.message || 'Đã reset outbox event, worker sẽ gửi lại trong vòng 30 giây');
        // Refetch ngay + sau 5s cho worker pick up + cap nhat status
        fetchHistory();
        setTimeout(() => { fetchHistory(); }, 5000);
      } else {
        msg.error(res?.message || 'Không thể gửi lại sự kiện này');
      }
    } catch (err: unknown) {
      const errAny = err as { response?: { data?: { message?: string } } };
      msg.error(errAny.response?.data?.message || 'Không thể gửi lại sự kiện này');
    } finally {
      setRetryingId(null);
    }
  }, [fetchHistory, msg]);

  // Initial fetch
  useEffect(() => {
    fetchHistory();
  }, [fetchHistory]);

  // Polling 10s chi khi co pending event (saves bandwidth)
  useEffect(() => {
    const hasPending = rows.some((r) => r.sent_status === 'pending');
    if (!hasPending) return;
    const id = setInterval(() => { fetchHistory(); }, POLL_INTERVAL_MS);
    return () => clearInterval(id);
  }, [rows, fetchHistory]);

  // Render
  const cardTitle = (
    <Space>
      <ApiOutlined style={{ color: '#1B3A5C' }} />
      <span style={{ color: '#1B3A5C', fontWeight: 600 }}>Lịch sử trạng thái LGSP</span>
      <Tag>{rows.length} sự kiện</Tag>
    </Space>
  );

  if (loading) {
    return (
      <Card size="small" title={cardTitle} style={{ marginBottom: 16, borderRadius: 10, boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}>
        <Skeleton active paragraph={{ rows: 3 }} />
      </Card>
    );
  }

  if (error) {
    return (
      <Card size="small" title={cardTitle} style={{ marginBottom: 16, borderRadius: 10, boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}>
        <Text type="danger">Lỗi: {error}</Text>
      </Card>
    );
  }

  if (rows.length === 0) {
    return (
      <Card size="small" title={cardTitle} style={{ marginBottom: 16, borderRadius: 10, boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}>
        <Empty description="Chưa có sự kiện trạng thái LGSP nào cho văn bản này" image={Empty.PRESENTED_IMAGE_SIMPLE} />
      </Card>
    );
  }

  // AntD v6 prefer items prop. Map rows -> Timeline items.
  const items = rows.map((r) => {
    const targetLabel = LGSP_STATUS_LABELS[r.target_status] ?? r.target_status;
    const targetTooltip = LGSP_STATUS_DESCRIPTIONS[r.target_status] ?? targetLabel;
    const targetColor = LGSP_STATUS_COLORS[r.target_status] ?? 'default';
    const sentLabel = SENT_STATUS_LABELS[r.sent_status];
    const sentColor = SENT_STATUS_COLORS[r.sent_status];

    // Timeline dot color: uu tien sent_status (vi worker chua day thi chua biet success)
    let dotColor: string;
    let dot: React.ReactNode | undefined;
    if (r.sent_status === 'success') {
      dotColor = 'green';
      dot = <CheckCircleOutlined style={{ fontSize: 16, color: '#52c41a' }} />;
    } else if (r.sent_status === 'error') {
      dotColor = 'red';
      dot = <CloseCircleOutlined style={{ fontSize: 16, color: '#ff4d4f' }} />;
    } else {
      dotColor = 'orange';
      dot = <Spin size="small" />;
    }

    const labelText = (
      <Text style={{ fontSize: 12, color: '#8c8c8c' }}>
        {dayjs(r.created_at).format('DD/MM HH:mm')}
      </Text>
    );

    const children = (
      <Space direction="vertical" size={4} style={{ width: '100%' }}>
        <Space size={8} wrap>
          <Tooltip title={targetTooltip}>
            <Tag color={targetColor}>{r.target_status} — {targetLabel}</Tag>
          </Tooltip>
          <Tag color={sentColor}>{sentLabel}</Tag>
          {r.sent_status === 'error' && r.retry_count > 0 && (
            <Tooltip title={`Đã retry ${r.retry_count} lần`}>
              <Tag icon={<ClockCircleOutlined />}>{r.retry_count}/5</Tag>
            </Tooltip>
          )}
          {/* Phase 37 Plan 37-06: button "Gửi lại" admin only cho entry error */}
          {r.sent_status === 'error' && isAdmin && (
            <Popconfirm
              title="Gửi lại sự kiện này?"
              description="Worker sẽ retry đẩy trạng thái lên LGSP trong vòng 30 giây."
              okText="Gửi lại"
              cancelText="Hủy"
              onConfirm={() => handleRetry(r.id)}
            >
              <Button
                size="small"
                type="link"
                icon={<ReloadOutlined />}
                loading={retryingId === r.id}
              >
                Gửi lại
              </Button>
            </Popconfirm>
          )}
        </Space>
        {r.sent_status === 'success' && r.sent_at && (
          <Text type="secondary" style={{ fontSize: 12 }}>
            Đã đẩy lên trục lúc {dayjs(r.sent_at).format('DD/MM/YYYY HH:mm:ss')}
          </Text>
        )}
        {r.sent_status === 'error' && r.error_message && (
          <Tooltip title={r.error_message}>
            <Text type="danger" style={{ fontSize: 12, display: 'block', maxWidth: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
              {r.error_message}
            </Text>
          </Tooltip>
        )}
      </Space>
    );

    return {
      key: String(r.id),
      color: dotColor,
      dot,
      label: labelText,
      children,
    };
  });

  return (
    <Card
      size="small"
      title={cardTitle}
      style={{ marginBottom: 16, borderRadius: 10, boxShadow: '0 1px 3px rgba(0,0,0,0.06)' }}
    >
      <Timeline mode="left" items={items} />
    </Card>
  );
}
