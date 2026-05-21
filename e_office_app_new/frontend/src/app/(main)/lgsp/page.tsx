'use client';

/**
 * Trang: /lgsp — Liên thông LGSP Dashboard
 *
 * Phase 37 Plan 37-05. REQ: LGSP-UI-04.
 *
 * REWRITE từ Phase 18 tracking list stub thành Overview Dashboard:
 *   - 4 stat cards tổng quan today (gửi / nhận / outbox pending / outbox error)
 *   - 6 DN cards với env status + last_synced_at + count today
 *   - Button "Đồng bộ ngay" gọi /api/lgsp/sync-now (Phase 35-03, admin only)
 *   - Tracking history section (giữ Table list từ Phase 18)
 *
 * Endpoint chính:
 *   GET  /api/admin/lgsp-overview  → dashboard data (admin only)
 *   POST /api/lgsp/sync-now        → trigger cron immediate (admin only)
 *   GET  /api/lgsp/tracking        → recent tracking (Phase 18 reuse, all authenticated users)
 *
 * Non-admin user:
 *   - Vẫn xem được page (transparent visibility)
 *   - KHÔNG fetch /admin/lgsp-overview (sẽ 403) → ẩn 4 stat cards + 6 DN cards
 *   - KHÔNG thấy button "Đồng bộ ngay"
 *   - Vẫn xem được tracking history (Phase 18 endpoint không admin gate)
 */

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Row, Col, Button, Space, Tag, Tooltip, Skeleton, Alert, Empty,
  Table, App, Statistic,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  ApiOutlined, SendOutlined, InboxOutlined,
  ClockCircleOutlined, ExclamationCircleOutlined, CheckCircleOutlined,
  CloseCircleOutlined, ReloadOutlined, ThunderboltOutlined, BankOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useUserRights } from '@/hooks/use-user-rights';
import dayjs from 'dayjs';

// ============================================================================
// Types — match Plan 37-02 LgspOverviewRow shape exactly
// ============================================================================

interface OverviewUnit {
  unit_id: number;
  unit_name: string;
  lgsp_org_code: string | null;
  prod_config_id: number | null;
  prod_is_active: boolean | null;
  prod_last_synced_at: string | null;
  prod_last_sync_error: string | null;
  sandbox_config_id: number | null;
  sandbox_is_active: boolean | null;
  sandbox_last_synced_at: string | null;
  sandbox_last_sync_error: string | null;
  send_today_total: number;
  send_today_success: number;
  send_today_error: number;
  send_today_pending: number;
  receive_today_total: number;
  outbox_today_pending: number;
  outbox_today_error: number;
}

interface OverviewTotals {
  send_today: number;
  send_success: number;
  send_error: number;
  receive_today: number;
  outbox_pending: number;
  outbox_error: number;
  active_count: number;
}

interface TrackingRow {
  id: number;
  outgoing_doc_id: number | null;
  incoming_doc_id: number | null;
  direction: string;
  lgsp_doc_id: string | null;
  dest_org_code: string | null;
  dest_org_name: string | null;
  status: string;
  error_message: string | null;
  sent_at: string | null;
  received_at: string | null;
  created_at: string;
}

interface SyncNowResponse {
  success: boolean;
  message?: string;
  job_id?: string;
}

// ============================================================================
// Constants
// ============================================================================

const POLL_INTERVAL_MS = 30_000;

const STATUS_COLOR: Record<string, string> = {
  pending: 'orange',
  processing: 'blue',
  success: 'green',
  error: 'red',
};

const STATUS_LABEL: Record<string, string> = {
  pending: 'Chờ xử lý',
  processing: 'Đang xử lý',
  success: 'Thành công',
  error: 'Lỗi',
};

// ============================================================================
// Component
// ============================================================================

export default function LgspOverviewPage(): React.ReactElement {
  const { message: msg } = App.useApp();
  const { hasRight } = useUserRights();
  // Phase 37.1: granular right_id=24 (RIGHT_LGSP_OVERVIEW) thay vi role hardcode.
  // Variable name "isAdmin" giu nguyen de minimize diff (reuse trong stats panel + sync button).
  const isAdmin = hasRight(24);

  const [units, setUnits] = useState<OverviewUnit[]>([]);
  const [totals, setTotals] = useState<OverviewTotals | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [syncing, setSyncing] = useState<boolean>(false);
  const [tracking, setTracking] = useState<TrackingRow[]>([]);
  const [trackingLoading, setTrackingLoading] = useState<boolean>(true);

  // ── Fetch overview (admin only — non-admin sẽ bị 403, skip silent) ─────
  const fetchOverview = useCallback(async () => {
    if (!isAdmin) {
      setLoading(false);
      return;
    }
    try {
      const { data: res } = await api.get('/admin/lgsp-overview');
      if (res?.success && res.data) {
        setUnits(res.data.units || []);
        setTotals(res.data.totals || null);
      }
    } catch {
      // Silent — keep previous data hoặc empty state
    } finally {
      setLoading(false);
    }
  }, [isAdmin]);

  // ── Fetch tracking (all authenticated users) ────────────────
  const fetchTracking = useCallback(async () => {
    try {
      const { data: res } = await api.get('/lgsp/tracking', {
        params: { page: 1, pageSize: 10 },
      });
      if (res?.success) setTracking(res.data || []);
    } catch {
      // Silent
    } finally {
      setTrackingLoading(false);
    }
  }, []);

  useEffect(() => {
    fetchOverview();
    fetchTracking();
  }, [fetchOverview, fetchTracking]);

  // ── Polling 30s tự refresh background ────────────────────────────────
  useEffect(() => {
    const id = setInterval(() => {
      fetchOverview();
      fetchTracking();
    }, POLL_INTERVAL_MS);
    return () => clearInterval(id);
  }, [fetchOverview, fetchTracking]);

  // ── Sync now (admin only) ────────────────────────────────────────────
  const handleSyncNow = async () => {
    setSyncing(true);
    try {
      const { data: res } = await api.post<SyncNowResponse>('/lgsp/sync-now');
      if (res?.success) {
        msg.success(
          res.message ||
            'Đã xếp hàng đồng bộ LGSP — worker sẽ chạy trong giây lát',
        );
        // Refresh sau 8s để cron pick up xong
        setTimeout(() => {
          fetchOverview();
          fetchTracking();
        }, 8000);
      } else {
        msg.error(res?.message || 'Không thể trigger đồng bộ');
      }
    } catch (err: unknown) {
      const errAny = err as { response?: { data?: { message?: string } } };
      msg.error(
        errAny.response?.data?.message || 'Không thể trigger đồng bộ LGSP',
      );
    } finally {
      setSyncing(false);
    }
  };

  // ── Tracking columns ───────────────────────────────────────────────
  const trackingColumns: ColumnsType<TrackingRow> = [
    {
      title: 'Hướng',
      dataIndex: 'direction',
      width: 100,
      render: (val: string) =>
        val === 'send' ? (
          <Tag color="blue" icon={<SendOutlined />}>Gửi đi</Tag>
        ) : (
          <Tag color="green" icon={<InboxOutlined />}>Nhận về</Tag>
        ),
    },
    {
      title: 'Cơ quan',
      dataIndex: 'dest_org_name',
      ellipsis: true,
      render: (v: string | null, r: TrackingRow) =>
        v || r.dest_org_code || '—',
    },
    {
      title: 'Mã LGSP',
      dataIndex: 'lgsp_doc_id',
      width: 200,
      render: (v: string | null) => v || '—',
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      width: 120,
      render: (val: string, row: TrackingRow) => (
        <Tooltip title={row.error_message || undefined}>
          <Tag color={STATUS_COLOR[val] || 'default'}>
            {STATUS_LABEL[val] || val}
          </Tag>
        </Tooltip>
      ),
    },
    {
      title: 'Thời gian',
      dataIndex: 'created_at',
      width: 150,
      render: (v: string) => dayjs(v).format('DD/MM HH:mm'),
    },
  ];

  return (
    <>
      <div
        className="page-header"
        style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}
      >
        <h2 className="page-title">
          <ApiOutlined style={{ marginRight: 8, color: '#1B3A5C' }} />
          Liên thông LGSP
        </h2>
        <Space>
          <Button
            icon={<ReloadOutlined />}
            onClick={() => {
              fetchOverview();
              fetchTracking();
            }}
          >
            Làm mới
          </Button>
          {isAdmin && (
            <Button
              type="primary"
              icon={<ThunderboltOutlined />}
              loading={syncing}
              onClick={handleSyncNow}
            >
              Đồng bộ ngay
            </Button>
          )}
        </Space>
      </div>

      {!isAdmin && (
        <Alert
          type="info"
          showIcon
          style={{ marginBottom: 16 }}
          title="Chế độ xem cho người dùng thường"
          description="Một số chức năng (Đồng bộ ngay, Cấu hình kết nối, Trạng thái 6 doanh nghiệp) chỉ dành cho Quản trị hệ thống."
        />
      )}

      {isAdmin && totals && totals.active_count === 0 && (
        <Alert
          type="warning"
          showIcon
          style={{ marginBottom: 16 }}
          title="Chưa có đơn vị LGSP nào đang bật kết nối"
          description={
            <>
              Truy cập <a href="/lgsp/cau-hinh">Cấu hình kết nối</a> → nhập credential thật →
              bật <b>Trạng thái</b> để cron tự đồng bộ.
            </>
          }
        />
      )}

      {/* ── 4 Stat cards (admin only) ── */}
      {isAdmin && (
        <Row gutter={16} style={{ marginBottom: 16 }}>
          <Col xs={12} sm={6}>
            <Card size="small">
              <Statistic
                title="VB gửi hôm nay"
                value={totals?.send_today ?? 0}
                prefix={<SendOutlined style={{ color: '#1890ff' }} />}
                suffix={
                  totals && totals.send_error > 0 ? (
                    <Tag color="red" style={{ marginLeft: 8 }}>
                      {totals.send_error} lỗi
                    </Tag>
                  ) : null
                }
              />
            </Card>
          </Col>
          <Col xs={12} sm={6}>
            <Card size="small">
              <Statistic
                title="VB nhận hôm nay"
                value={totals?.receive_today ?? 0}
                prefix={<InboxOutlined style={{ color: '#52c41a' }} />}
              />
            </Card>
          </Col>
          <Col xs={12} sm={6}>
            <Card size="small">
              <Statistic
                title="Callback chờ xử lý"
                value={totals?.outbox_pending ?? 0}
                prefix={<ClockCircleOutlined style={{ color: '#D97706' }} />}
              />
            </Card>
          </Col>
          <Col xs={12} sm={6}>
            <Card size="small">
              <Statistic
                title="Callback lỗi"
                value={totals?.outbox_error ?? 0}
                prefix={<ExclamationCircleOutlined style={{ color: '#DC2626' }} />}
                styles={{
                  content: {
                    color:
                      totals && totals.outbox_error > 0
                        ? '#DC2626'
                        : undefined,
                  },
                }}
              />
            </Card>
          </Col>
        </Row>
      )}

      {/* ── 6 DN cards (admin only) ── */}
      {isAdmin && (
        <>
          <h3 style={{ color: '#1B3A5C', marginBottom: 12 }}>
            Trạng thái 6 doanh nghiệp
          </h3>
          {loading ? (
            <Row gutter={[16, 16]} style={{ marginBottom: 16 }}>
              {[1, 2, 3, 4, 5, 6].map((i) => (
                <Col xs={24} sm={12} lg={8} key={i}>
                  <Card size="small">
                    <Skeleton active paragraph={{ rows: 3 }} />
                  </Card>
                </Col>
              ))}
            </Row>
          ) : units.length === 0 ? (
            <Card style={{ marginBottom: 16 }}>
              <Empty description="Chưa có DN nào được cấu hình LGSP (cần root unit có lgsp_org_code)" />
            </Card>
          ) : (
            <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
              {units.map((u) => (
                <Col xs={24} sm={12} lg={8} key={u.unit_id}>
                  <Card
                    size="small"
                    title={
                      <Space>
                        <BankOutlined style={{ color: '#1B3A5C' }} />
                        <span style={{ fontWeight: 600 }}>{u.unit_name}</span>
                      </Space>
                    }
                    extra={
                      u.lgsp_org_code && <Tag color="blue">{u.lgsp_org_code}</Tag>
                    }
                  >
                    <Space direction="vertical" size={8} style={{ width: '100%' }}>
                      {/* Env badges */}
                      <Space size={6}>
                        <Tooltip
                          title={
                            u.sandbox_last_sync_error ||
                            (u.sandbox_is_active ? 'Sandbox đang bật' : 'Sandbox tắt')
                          }
                        >
                          <Tag
                            color={u.sandbox_is_active ? 'orange' : 'default'}
                            icon={
                              u.sandbox_is_active ? (
                                <CheckCircleOutlined />
                              ) : (
                                <CloseCircleOutlined />
                              )
                            }
                          >
                            Sandbox
                          </Tag>
                        </Tooltip>
                        <Tooltip
                          title={
                            u.prod_last_sync_error ||
                            (u.prod_is_active ? 'Production đang bật' : 'Production tắt')
                          }
                        >
                          <Tag
                            color={u.prod_is_active ? 'red' : 'default'}
                            icon={
                              u.prod_is_active ? (
                                <CheckCircleOutlined />
                              ) : (
                                <CloseCircleOutlined />
                              )
                            }
                          >
                            Production
                          </Tag>
                        </Tooltip>
                      </Space>

                      {/* Last synced */}
                      <div style={{ fontSize: 12, color: '#8c8c8c' }}>
                        Đồng bộ cuối:{' '}
                        {(() => {
                          const lastSynced =
                            u.prod_last_synced_at || u.sandbox_last_synced_at;
                          return lastSynced ? (
                            <strong>
                              {dayjs(lastSynced).format('DD/MM HH:mm')}
                            </strong>
                          ) : (
                            <span style={{ color: '#bfbfbf' }}>Chưa đồng bộ</span>
                          );
                        })()}
                      </div>

                      {/* Counts */}
                      <Row gutter={8}>
                        <Col span={8}>
                          <div
                            style={{
                              textAlign: 'center',
                              padding: 4,
                              background: '#f0f9ff',
                              borderRadius: 6,
                            }}
                          >
                            <div
                              style={{
                                fontSize: 18,
                                fontWeight: 700,
                                color: '#1890ff',
                              }}
                            >
                              {u.send_today_total}
                            </div>
                            <div style={{ fontSize: 11, color: '#8c8c8c' }}>
                              Gửi today
                            </div>
                          </div>
                        </Col>
                        <Col span={8}>
                          <div
                            style={{
                              textAlign: 'center',
                              padding: 4,
                              background: '#f6ffed',
                              borderRadius: 6,
                            }}
                          >
                            <div
                              style={{
                                fontSize: 18,
                                fontWeight: 700,
                                color: '#52c41a',
                              }}
                            >
                              {u.receive_today_total}
                            </div>
                            <div style={{ fontSize: 11, color: '#8c8c8c' }}>
                              Nhận today
                            </div>
                          </div>
                        </Col>
                        <Col span={8}>
                          <div
                            style={{
                              textAlign: 'center',
                              padding: 4,
                              background:
                                u.outbox_today_pending > 0 ? '#fff7e6' : '#fafafa',
                              borderRadius: 6,
                            }}
                          >
                            <div
                              style={{
                                fontSize: 18,
                                fontWeight: 700,
                                color:
                                  u.outbox_today_pending > 0
                                    ? '#D97706'
                                    : '#bfbfbf',
                              }}
                            >
                              {u.outbox_today_pending}
                            </div>
                            <div style={{ fontSize: 11, color: '#8c8c8c' }}>
                              Outbox
                            </div>
                          </div>
                        </Col>
                      </Row>

                      {u.send_today_error > 0 && (
                        <Alert
                          type="error"
                          showIcon
                          title={`${u.send_today_error} VB gửi lỗi today`}
                          style={{ padding: '4px 12px' }}
                        />
                      )}
                    </Space>
                  </Card>
                </Col>
              ))}
            </Row>
          )}
        </>
      )}

      {/* ── Tracking history (all authenticated users) ── */}
      <Card
        title="Lịch sử liên thông gần đây (10 bản ghi mới nhất)"
        className="page-card"
      >
        {trackingLoading ? (
          <Skeleton active paragraph={{ rows: 4 }} />
        ) : tracking.length === 0 ? (
          <Empty description="Chưa có liên thông LGSP nào" />
        ) : (
          <Table<TrackingRow>
            rowKey="id"
            columns={trackingColumns}
            dataSource={tracking}
            pagination={false}
            size="small"
            scroll={{ x: 800 }}
          />
        )}
      </Card>
    </>
  );
}
