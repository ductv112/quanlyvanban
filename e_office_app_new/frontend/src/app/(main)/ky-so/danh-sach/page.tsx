'use client';

/**
 * Trang: /ky-so/danh-sach — Danh sách ký số 4 tab (Phase 12-02)
 *
 * Task 1: Structure + state + fetchers + Tabs layout + counts + socket listener.
 * (Task 2 sẽ bổ sung column definitions + action handlers.)
 *
 * Layout:
 *  - Page header (tiêu đề + icon)
 *  - Card chứa <Tabs> 4 tab: Cần ký / Đang xử lý / Đã ký / Thất bại
 *  - Mỗi tab label có Badge hiển thị count (fetch từ /ky-so/danh-sach/counts)
 *
 * Realtime:
 *  - Socket.IO events SIGN_COMPLETED / SIGN_FAILED → tự refetch counts + list
 *
 * URL sync:
 *  - Query `?tab=X&page=Y&pageSize=Z` — refresh/share URL giữ state
 *  - Tab switch reset page=1, giữ pageSize (D-11 CONTEXT)
 *
 * API contract (Phase 11-05):
 *  GET /ky-so/danh-sach/counts → { data: { need_sign, pending, completed, failed } }
 *  GET /ky-so/danh-sach?tab=X&page=Y&page_size=Z → { data: [...], pagination }
 *
 * Chú ý quan trọng:
 *  - Backend query param là `page_size` (snake_case) KHÔNG `pageSize`
 *  - axios instance (@/lib/api) đã có baseURL='/api' → dùng path '/ky-so/...' KHÔNG '/api/ky-so/...'
 *  - need_sign rows KHÁC txn rows — discriminated union theo tab (D-12 CONTEXT)
 */

import { useEffect, useState, useCallback } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import {
  App,
  Badge,
  Card,
  Skeleton,
  Space,
  Table,
  Tabs,
  Typography,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { SafetyCertificateOutlined } from '@ant-design/icons';
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

// ============================================================================
// Component
// ============================================================================

export default function DanhSachKySoPage() {
  const { message } = App.useApp();
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

  // Keep openSign referenced để Task 2 implement action handlers mà không
  // thay đổi import list.
  void openSign;

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
  // Column definitions per tab (Task 2 sẽ implement đầy đủ)
  // ==========================================================================
  const getColumnsForTab = useCallback(
    (_tab: TabKey): ColumnsType<NeedSignRow> | ColumnsType<TxnRow> => {
      // Stub — Task 2 sẽ thêm column định nghĩa chi tiết cho mỗi tab
      return [];
    },
    [],
  );

  const emptyTextForTab = useCallback((_tab: TabKey): string => {
    // Stub — Task 2 sẽ thêm empty message tiếng Việt theo tab
    return 'Không có dữ liệu';
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
