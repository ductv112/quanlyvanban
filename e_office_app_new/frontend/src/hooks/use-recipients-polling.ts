// ============================================================
// useRecipientsPolling — Phase 34 (CONTEXT D-16)
//
// Poll `/api/van-ban-di/:id/noi-nhan` mỗi `intervalMs` ms khi:
//   - enabled=true (page chi tiết VB đi đang mở)
//   - hasPending=true (còn ít nhất 1 recipient sent_status='pending'
//     hoặc external + lgsp_status='pending'|'processing')
//
// Stop khi: enabled=false / hasPending=false / component unmount.
//
// Trả về: { data, loading, hasPending, refetch } — component dùng `data`
// render badge state machine 4 state (CONTEXT D-17).
// ============================================================

import { useCallback, useEffect, useRef, useState } from 'react';
import { api } from '@/lib/api';

export interface RecipientStatus {
  id: number;
  recipient_type: 'internal_unit' | 'external_org';
  recipient_unit_name: string | null;
  recipient_org_name: string | null;
  recipient_org_code: string | null;
  sent_at: string | null;
  sent_status: string;
  error_message: string | null;
  generated_incoming_doc_id: number | null;
  lgsp_doc_id: string | null;
  lgsp_status: string | null;
  lgsp_error_message: string | null;
}

interface UseRecipientsPollingResult {
  data: RecipientStatus[];
  loading: boolean;
  hasPending: boolean;
  refetch: () => Promise<void>;
}

/**
 * Pure helper: tính có recipient còn pending không.
 * "Pending" = sent_status='pending' HOAC external + lgsp_status in {pending, processing}.
 */
function computeHasPending(rows: RecipientStatus[]): boolean {
  return rows.some((r) => {
    if (r.sent_status === 'pending') return true;
    if (
      r.recipient_type === 'external_org' &&
      (r.lgsp_status === 'pending' || r.lgsp_status === 'processing')
    ) {
      return true;
    }
    return false;
  });
}

export function useRecipientsPolling(
  outgoingDocId: number,
  enabled: boolean,
  intervalMs: number = 10_000,
): UseRecipientsPollingResult {
  const [data, setData] = useState<RecipientStatus[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [hasPending, setHasPending] = useState<boolean>(false);
  const intervalRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const refetch = useCallback(async () => {
    if (!outgoingDocId || outgoingDocId <= 0) return;
    setLoading(true);
    try {
      const { data: res } = await api.get(`/van-ban-di/${outgoingDocId}/noi-nhan`);
      const rows: RecipientStatus[] = res?.data ?? [];
      setData(rows);
      setHasPending(computeHasPending(rows));
    } catch {
      // Silent — keep previous data, don't reset (UX tot hon khi transient API fail)
    } finally {
      setLoading(false);
    }
  }, [outgoingDocId]);

  // Initial fetch khi enabled chuyen true hoac docId thay doi
  useEffect(() => {
    if (enabled && outgoingDocId > 0) {
      refetch();
    }
  }, [enabled, outgoingDocId, refetch]);

  // Polling loop — chi chay khi enabled && hasPending && docId hop le
  useEffect(() => {
    // Cleanup previous interval
    if (intervalRef.current) {
      clearInterval(intervalRef.current);
      intervalRef.current = null;
    }

    if (!enabled || !hasPending || outgoingDocId <= 0) {
      return;
    }

    // Setup interval — poll every intervalMs ms
    intervalRef.current = setInterval(() => {
      refetch();
    }, intervalMs);

    // Cleanup on unmount / deps change
    return () => {
      if (intervalRef.current) {
        clearInterval(intervalRef.current);
        intervalRef.current = null;
      }
    };
  }, [enabled, hasPending, outgoingDocId, intervalMs, refetch]);

  return { data, loading, hasPending, refetch };
}
