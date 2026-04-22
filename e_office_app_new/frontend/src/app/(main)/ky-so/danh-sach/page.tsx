'use client';

/**
 * Trang: /ky-so/danh-sach — Danh sách ký số 4 tab (Phase 12-02)
 *
 * Layout:
 *  - Page header (tiêu đề + icon)
 *  - Card chứa <Tabs> 4 tab: Cần ký / Đang xử lý / Đã ký / Thất bại
 *  - Mỗi tab label có Badge hiển thị count (fetch từ /ky-so/danh-sach/counts)
 *  - Mỗi tab là Table + action column + pagination
 *
 * Realtime:
 *  - Socket.IO events SIGN_COMPLETED / SIGN_FAILED → tự refetch counts + list
 *  - Action thành công (sign / cancel / retry) → onSuccess callback refetch
 *
 * URL sync:
 *  - Query `?tab=X&page=Y&pageSize=Z` — refresh/share URL giữ state
 *  - Tab switch reset page=1, giữ pageSize (D-11 CONTEXT)
 *
 * API contract (Phase 11-05 + 12-01):
 *  GET  /ky-so/danh-sach/counts → { data: { need_sign, pending, completed, failed } }
 *  GET  /ky-so/danh-sach?tab=X&page=Y&page_size=Z → { data: [...], pagination }
 *  POST /ky-so/sign/:id/cancel → { success, data: { transaction_id } }
 *  GET  /ky-so/sign/:id/download → { data: { url, file_name, expires_in } }
 *
 * Chú ý quan trọng:
 *  - Backend query param là `page_size` (snake_case) KHÔNG `pageSize`
 *  - axios instance (@/lib/api) đã có baseURL='/api' → dùng path '/ky-so/...' KHÔNG '/api/ky-so/...'
 *  - need_sign rows KHÁC txn rows — discriminated union theo tab (D-12 CONTEXT)
 */

import { useEffect, useMemo, useState, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import {
  App,
  Badge,
  Button,
  Card,
  Skeleton,
  Space,
  Table,
  Tabs,
  Tag,
  Tooltip,
  Typography,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  CloseOutlined,
  DownloadOutlined,
  ReloadOutlined,
  SafetyCertificateOutlined,
} from '@ant-design/icons';
import dayjs from 'dayjs';
import { api } from '@/lib/api';
import { useSigning } from '@/hooks/use-signing';
import { getSocket, SOCKET_EVENTS } from '@/lib/socket';
import type {
  AttachmentType,
  SignCompletedEvent,
  SignFailedEvent,
} from '@/lib/signing/types';

const { Title } = Typography;

// ============================================================================
// Constants
// ============================================================================

type TabKey = 'need_sign' | 'pending' | 'completed' | 'failed';

const TAB_KEYS: TabKey[] = ['need_sign', 'pending', 'completed', 'failed'];

const TAB_LABELS: Record<TabKey, string> = {
  need_sign: 'Cần ký',
  pending: 'Đang xử lý',
  completed: 'Đã ký',
  failed: 'Thất bại',
};

const TAB_BADGE_COLOR: Record<TabKey, string> = {
  need_sign: '#D97706', // Warning — cần user hành động
  pending: '#0891B2', // Accent — đang chạy
  completed: '#059669', // Success
  failed: '#DC2626', // Error
};

const DEFAULT_PAGE_SIZE = 20;
const PAGE_SIZE_OPTIONS = ['10', '20', '50', '100'];

const DOC_TYPE_LABEL: Record<string, string> = {
  outgoing_doc: 'Văn bản đi',
  drafting_doc: 'Dự thảo',
  handling_doc: 'Hồ sơ công việc',
};

const PROVIDER_LABEL: Record<string, string> = {
  SMARTCA_VNPT: 'VNPT SmartCA',
  MYSIGN_VIETTEL: 'Viettel MySign',
};

// ============================================================================
// Row types — discriminated union theo tab (D-12)
// ============================================================================

/** Tab "Cần ký" — chưa có transaction, chỉ attachment cần ký */
interface NeedSignRow {
  attachment_id: number;
  attachment_type: AttachmentType;
  file_name: string;
  doc_id: number;
  doc_type: string;
  doc_label: string;
  doc_number: number;
  doc_notation: string;
  created_at: string;
}

/** Tab "Đang xử lý" / "Đã ký" / "Thất bại" — có transaction */
interface TxnRow {
  transaction_id: number;
  provider_code: string;
  provider_name: string;
  attachment_id: number;
  attachment_type: AttachmentType;
  file_name: string;
  doc_id: number;
  doc_type: string;
  doc_label: string;
  status: string;
  error_message: string | null;
  created_at: string;
  completed_at: string | null;
}

interface Counts {
  need_sign: number;
  pending: number;
  completed: number;
  failed: number;
}

// ============================================================================
// Helpers
// ============================================================================

function isValidTab(value: string | null | undefined): value is TabKey {
  return !!value && (TAB_KEYS as string[]).includes(value);
}

function parsePositiveInt(value: string | null, fallback: number): number {
  if (!value) return fallback;
  const n = Number(value);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : fallback;
}

function parsePageSize(value: string | null, fallback: number): number {
  const n = parsePositiveInt(value, fallback);
  // Cap 100 — khớp backend SP (Phase 11-05)
  return Math.min(n, 100);
}

function formatDate(iso: string | null | undefined): string {
  if (!iso) return '—';
  const d = dayjs(iso);
  if (!d.isValid()) return '—';
  return d.format('DD/MM/YYYY HH:mm');
}

function docTypeLabel(key: string): string {
  return DOC_TYPE_LABEL[key] ?? key ?? '—';
}

function providerLabel(code: string, name?: string | null): string {
  if (name && name.trim()) return name;
  return PROVIDER_LABEL[code] || code || '—';
}

function statusFallbackLabel(status: string): string {
  switch (status) {
    case 'expired':
      return 'Hết thời gian';
    case 'cancelled':
      return 'Đã hủy';
    case 'failed':
      return 'Thất bại';
    default:
      return status || 'Thất bại';
  }
}

// ============================================================================
// Component
// ============================================================================

export default function DanhSachKySoPage() {
  const { message, modal } = App.useApp();
  const router = useRouter();
  const searchParams = useSearchParams();

  // --- URL → initial state
  const urlTab = searchParams.get('tab');
  const urlPage = searchParams.get('page');
  const urlPageSize = searchParams.get('pageSize');

  const [activeTab, setActiveTab] = useState<TabKey>(
    isValidTab(urlTab) ? urlTab : 'need_sign',
  );
  const [page, setPage] = useState<number>(parsePositiveInt(urlPage, 1));
  const [pageSize, setPageSize] = useState<number>(
    parsePageSize(urlPageSize, DEFAULT_PAGE_SIZE),
  );

  // --- Data state
  const [counts, setCounts] = useState<Counts>({
    need_sign: 0,
    pending: 0,
    completed: 0,
    failed: 0,
  });
  const [rows, setRows] = useState<NeedSignRow[] | TxnRow[]>([]);
  const [total, setTotal] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);
  const [initialLoading, setInitialLoading] = useState<boolean>(true);

  // --- Sign modal hook (consume Phase 11-06, KHÔNG sửa)
  const { openSign, renderSignModal } = useSigning();

  // ==========================================================================
  // URL sync
  // ==========================================================================
  const syncUrl = useCallback(
    (nextTab: TabKey, nextPage: number, nextPageSize: number) => {
      const params = new URLSearchParams();
      params.set('tab', nextTab);
      params.set('page', String(nextPage));
      params.set('pageSize', String(nextPageSize));
      router.replace(`/ky-so/danh-sach?${params.toString()}`, { scroll: false });
    },
    [router],
  );

  // ==========================================================================
  // Fetchers
  // ==========================================================================
  const fetchCounts = useCallback(async () => {
    try {
      const { data: res } = await api.get<{
        success: boolean;
        data: Counts;
      }>('/ky-so/danh-sach/counts');
      if (res?.success && res.data) {
        setCounts(res.data);
      }
    } catch {
      // Giữ counts cũ — không spam user message; lần fetch kế tiếp sẽ auto-heal
    }
  }, []);

  const fetchList = useCallback(
    async (tab: TabKey, p: number, ps: number) => {
      setLoading(true);
      try {
        const { data: res } = await api.get<{
          success: boolean;
          data: NeedSignRow[] | TxnRow[];
          pagination?: { total: number; page: number; pageSize: number };
          message?: string;
        }>('/ky-so/danh-sach', {
          // NOTE: backend đọc `page_size` (snake_case) — xem routes/ky-so-danh-sach.ts
          params: { tab, page: p, page_size: ps },
        });
        if (res?.success) {
          setRows(res.data ?? []);
          setTotal(res.pagination?.total ?? 0);
        } else {
          setRows([]);
          setTotal(0);
          message.error(res?.message || 'Không tải được danh sách');
        }
      } catch (err: unknown) {
        const axiosErr = err as {
          response?: { data?: { message?: string } };
        };
        message.error(
          axiosErr?.response?.data?.message || 'Không tải được danh sách',
        );
        setRows([]);
        setTotal(0);
      } finally {
        setLoading(false);
      }
    },
    [message],
  );

  // ==========================================================================
  // Mount effect — initial fetch
  // ==========================================================================
  useEffect(() => {
    (async () => {
      await Promise.all([
        fetchCounts(),
        fetchList(activeTab, page, pageSize),
      ]);
      setInitialLoading(false);
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []); // Mount only — state changes handled below

  // ==========================================================================
  // State change effect — refetch list + sync URL
  // ==========================================================================
  useEffect(() => {
    if (initialLoading) return;
    fetchList(activeTab, page, pageSize);
    syncUrl(activeTab, page, pageSize);
  }, [activeTab, page, pageSize, fetchList, syncUrl, initialLoading]);

  // ==========================================================================
  // Socket realtime — SIGN_COMPLETED / SIGN_FAILED
  // ==========================================================================
  useEffect(() => {
    const socket = getSocket();
    if (!socket) return;

    const refreshAll = () => {
      fetchCounts();
      fetchList(activeTab, page, pageSize);
    };

    const onCompleted = (payload: SignCompletedEvent) => {
      // Defense-in-depth (T-12-05): BE đã emit tới room user_{staffId} only,
      // FE chỉ nhận event của mình. Refresh gọi API với JWT hiện tại → data
      // tiếp tục được filter server-side.
      if (payload?.transaction_id) refreshAll();
    };
    const onFailed = (payload: SignFailedEvent) => {
      if (payload?.transaction_id) refreshAll();
    };

    socket.on(SOCKET_EVENTS.SIGN_COMPLETED, onCompleted);
    socket.on(SOCKET_EVENTS.SIGN_FAILED, onFailed);
    return () => {
      socket.off(SOCKET_EVENTS.SIGN_COMPLETED, onCompleted);
      socket.off(SOCKET_EVENTS.SIGN_FAILED, onFailed);
    };
  }, [activeTab, page, pageSize, fetchCounts, fetchList]);

  // ==========================================================================
  // Actions
  // ==========================================================================

  /** Mở modal ký cho row Cần ký hoặc Thất bại (ký lại) — dùng useSigning hook. */
  const handleSign = useCallback(
    (row: NeedSignRow | TxnRow) => {
      openSign({
        attachment: { id: row.attachment_id, file_name: row.file_name },
        attachmentType: row.attachment_type,
        docId: row.doc_id,
        onSuccess: () => {
          // Sau khi ký thành công — refresh list + counts
          fetchCounts();
          fetchList(activeTab, page, pageSize);
        },
      });
    },
    [openSign, fetchCounts, fetchList, activeTab, page, pageSize],
  );

  /** Hủy transaction pending — POST /ky-so/sign/:id/cancel */
  const handleCancel = useCallback(
    (row: TxnRow) => {
      modal.confirm({
        title: 'Hủy giao dịch ký số',
        content: `Bạn có chắc muốn hủy giao dịch ký cho file "${row.file_name}"?`,
        okText: 'Hủy giao dịch',
        okType: 'danger',
        cancelText: 'Đóng',
        maskClosable: false,
        onOk: async () => {
          try {
            const { data: res } = await api.post<{
              success: boolean;
              message?: string;
              data?: { transaction_id: number };
            }>(`/ky-so/sign/${row.transaction_id}/cancel`);
            if (res?.success) {
              message.success('Đã hủy giao dịch ký số');
              await Promise.all([
                fetchCounts(),
                fetchList(activeTab, page, pageSize),
              ]);
            } else {
              message.error(res?.message || 'Không thể hủy giao dịch');
            }
          } catch (err: unknown) {
            const axiosErr = err as {
              response?: { data?: { message?: string } };
            };
            message.error(
              axiosErr?.response?.data?.message || 'Không thể hủy giao dịch',
            );
          }
        },
      });
    },
    [modal, message, fetchCounts, fetchList, activeTab, page, pageSize],
  );

  /** Tải file đã ký — GET /ky-so/sign/:id/download → window.open */
  const handleDownload = useCallback(
    async (row: TxnRow) => {
      try {
        const { data: res } = await api.get<{
          success: boolean;
          message?: string;
          data?: { url: string; file_name: string; expires_in: number };
        }>(`/ky-so/sign/${row.transaction_id}/download`);

        const url = res?.data?.url;
        if (!url) {
          message.error(res?.message || 'Không lấy được link tải file');
          return;
        }
        // Browser mở tab mới → trigger download từ presigned MinIO URL
        window.open(url, '_blank', 'noopener,noreferrer');
      } catch (err: unknown) {
        const axiosErr = err as {
          response?: { data?: { message?: string }; status?: number };
        };
        const status = axiosErr?.response?.status;
        const fallback =
          status === 403
            ? 'Bạn không có quyền tải file này'
            : status === 404
              ? 'File đã ký chưa sẵn sàng hoặc giao dịch không tồn tại'
              : 'Không tải được file đã ký';
        message.error(axiosErr?.response?.data?.message || fallback);
      }
    },
    [message],
  );

  // ==========================================================================
  // Column definitions per tab
  // ==========================================================================

  const needSignColumns: ColumnsType<NeedSignRow> = useMemo(
    () => [
      {
        title: 'Mã VB',
        dataIndex: 'doc_notation',
        key: 'doc_notation',
        width: 200,
        render: (value: string, row) =>
          value || row.doc_label || `#${row.doc_id}` || '—',
      },
      {
        title: 'Tên file',
        dataIndex: 'file_name',
        key: 'file_name',
        ellipsis: true,
        render: (value: string) => (
          <Tooltip title={value}>
            <span>{value}</span>
          </Tooltip>
        ),
      },
      {
        title: 'Loại VB',
        dataIndex: 'doc_type',
        key: 'doc_type',
        width: 170,
        render: (value: string) => <Tag>{docTypeLabel(value)}</Tag>,
      },
      {
        title: 'Ngày tạo',
        dataIndex: 'created_at',
        key: 'created_at',
        width: 170,
        render: (value: string) => formatDate(value),
      },
      {
        title: 'Thao tác',
        key: 'actions',
        width: 140,
        align: 'right' as const,
        render: (_: unknown, row: NeedSignRow) => (
          <Button
            type="primary"
            icon={<SafetyCertificateOutlined />}
            onClick={() => handleSign(row)}
          >
            Ký số
          </Button>
        ),
      },
    ],
    [handleSign],
  );

  const pendingColumns: ColumnsType<TxnRow> = useMemo(
    () => [
      {
        title: 'Mã VB',
        dataIndex: 'doc_label',
        key: 'doc_label',
        width: 220,
        render: (value: string, row) => value || `#${row.doc_id}` || '—',
      },
      {
        title: 'Tên file',
        dataIndex: 'file_name',
        key: 'file_name',
        ellipsis: true,
        render: (value: string) => (
          <Tooltip title={value}>
            <span>{value}</span>
          </Tooltip>
        ),
      },
      {
        title: 'Nhà cung cấp',
        dataIndex: 'provider_code',
        key: 'provider',
        width: 170,
        render: (_value: string, row) => (
          <Tag color="blue">
            {providerLabel(row.provider_code, row.provider_name)}
          </Tag>
        ),
      },
      {
        title: 'Bắt đầu lúc',
        dataIndex: 'created_at',
        key: 'created_at',
        width: 170,
        render: (value: string) => formatDate(value),
      },
      {
        title: 'Thao tác',
        key: 'actions',
        width: 120,
        align: 'right' as const,
        render: (_: unknown, row: TxnRow) => (
          <Button
            danger
            icon={<CloseOutlined />}
            onClick={() => handleCancel(row)}
          >
            Hủy
          </Button>
        ),
      },
    ],
    [handleCancel],
  );

  const completedColumns: ColumnsType<TxnRow> = useMemo(
    () => [
      {
        title: 'Mã VB',
        dataIndex: 'doc_label',
        key: 'doc_label',
        width: 220,
        render: (value: string, row) => value || `#${row.doc_id}` || '—',
      },
      {
        title: 'Tên file',
        dataIndex: 'file_name',
        key: 'file_name',
        ellipsis: true,
        render: (value: string) => (
          <Tooltip title={value}>
            <span>{value}</span>
          </Tooltip>
        ),
      },
      {
        title: 'Nhà cung cấp',
        dataIndex: 'provider_code',
        key: 'provider',
        width: 170,
        render: (_value: string, row) => (
          <Tag color="green">
            {providerLabel(row.provider_code, row.provider_name)}
          </Tag>
        ),
      },
      {
        title: 'Ngày ký',
        dataIndex: 'completed_at',
        key: 'completed_at',
        width: 170,
        render: (value: string | null) => formatDate(value),
      },
      {
        title: 'Thao tác',
        key: 'actions',
        width: 180,
        align: 'right' as const,
        render: (_: unknown, row: TxnRow) => (
          <Button
            icon={<DownloadOutlined />}
            onClick={() => handleDownload(row)}
          >
            Tải file đã ký
          </Button>
        ),
      },
    ],
    [handleDownload],
  );

  const failedColumns: ColumnsType<TxnRow> = useMemo(
    () => [
      {
        title: 'Mã VB',
        dataIndex: 'doc_label',
        key: 'doc_label',
        width: 220,
        render: (value: string, row) => value || `#${row.doc_id}` || '—',
      },
      {
        title: 'Tên file',
        dataIndex: 'file_name',
        key: 'file_name',
        width: 220,
        ellipsis: true,
        render: (value: string) => (
          <Tooltip title={value}>
            <span>{value}</span>
          </Tooltip>
        ),
      },
      {
        title: 'Lý do lỗi',
        dataIndex: 'error_message',
        key: 'error_message',
        ellipsis: true,
        render: (value: string | null, row) => {
          const fullMsg = value || statusFallbackLabel(row.status);
          const truncated =
            fullMsg.length > 80 ? `${fullMsg.slice(0, 80)}…` : fullMsg;
          return (
            <Tooltip title={fullMsg}>
              <span>{truncated}</span>
            </Tooltip>
          );
        },
      },
      {
        title: 'Thất bại lúc',
        dataIndex: 'completed_at',
        key: 'completed_at',
        width: 170,
        render: (value: string | null, row) =>
          formatDate(value || row.created_at),
      },
      {
        title: 'Thao tác',
        key: 'actions',
        width: 130,
        align: 'right' as const,
        render: (_: unknown, row: TxnRow) => (
          <Button
            type="primary"
            icon={<ReloadOutlined />}
            onClick={() => handleSign(row)}
          >
            Ký lại
          </Button>
        ),
      },
    ],
    [handleSign],
  );

  // Map tab key → columns
  const getColumnsForTab = useCallback(
    (tab: TabKey): ColumnsType<NeedSignRow> | ColumnsType<TxnRow> => {
      switch (tab) {
        case 'need_sign':
          return needSignColumns;
        case 'pending':
          return pendingColumns;
        case 'completed':
          return completedColumns;
        case 'failed':
          return failedColumns;
      }
    },
    [needSignColumns, pendingColumns, completedColumns, failedColumns],
  );

  // Empty state Vietnamese per tab
  const emptyTextForTab = useCallback((tab: TabKey): string => {
    switch (tab) {
      case 'need_sign':
        return 'Bạn không có văn bản nào đang chờ ký';
      case 'pending':
        return 'Không có giao dịch nào đang xử lý';
      case 'completed':
        return 'Bạn chưa có giao dịch ký số hoàn tất';
      case 'failed':
        return 'Không có giao dịch thất bại / hết hạn / đã hủy';
    }
  }, []);

  // ==========================================================================
  // Render
  // ==========================================================================

  const tabItems = TAB_KEYS.map((key) => ({
    key,
    label: (
      <Space size={8}>
        <span>{TAB_LABELS[key]}</span>
        <Badge
          count={counts[key]}
          showZero
          overflowCount={999}
          style={{
            backgroundColor: TAB_BADGE_COLOR[key],
            fontWeight: 600,
          }}
        />
      </Space>
    ),
    children: (
      <Table
        rowKey={(row) =>
          'transaction_id' in row
            ? `txn-${row.transaction_id}`
            : `att-${row.attachment_id}`
        }
        // Union type → cast 1 lần tại ranh giới render (AntD ColumnsType
        // không union được giữa 2 row type khác nhau).
        dataSource={rows as Array<NeedSignRow | TxnRow>}
        columns={getColumnsForTab(key) as ColumnsType<NeedSignRow | TxnRow>}
        loading={loading}
        pagination={{
          current: page,
          pageSize,
          total,
          showSizeChanger: true,
          pageSizeOptions: PAGE_SIZE_OPTIONS,
          showTotal: (t) => `Tổng ${t} giao dịch`,
          onChange: (p, ps) => {
            setPage(p);
            setPageSize(ps);
          },
        }}
        locale={{ emptyText: emptyTextForTab(key) }}
        scroll={{ x: 960 }}
      />
    ),
  }));

  // ──────────────────────────────────────────────────────────────────────
  // Initial loading skeleton
  // ──────────────────────────────────────────────────────────────────────
  if (initialLoading) {
    return (
      <div>
        <div className="page-header">
          <Title level={3} className="page-title">
            <SafetyCertificateOutlined style={{ color: '#0891B2' }} /> Danh
            sách ký số
          </Title>
        </div>
        <Card className="page-card">
          <Skeleton active paragraph={{ rows: 8 }} />
        </Card>
      </div>
    );
  }

  return (
    <>
      <div className="page-header">
        <Title level={3} className="page-title">
          <SafetyCertificateOutlined style={{ color: '#0891B2' }} /> Danh sách
          ký số
        </Title>
      </div>

      <Card className="page-card">
        <Tabs
          activeKey={activeTab}
          onChange={(k) => {
            if (isValidTab(k)) {
              setActiveTab(k);
              setPage(1); // Tab switch reset page=1, giữ pageSize (D-11)
            }
          }}
          items={tabItems}
          destroyOnHidden
        />
      </Card>

      {renderSignModal()}
    </>
  );
}
