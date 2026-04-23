'use client';

/**
 * SignModal — Shared modal component cho Phase 11 async sign flow.
 *
 * Usage:
 *   const { openSign, renderSignModal } = useSigning();
 *   // ... in handler: openSign({ attachment, attachmentType: 'outgoing', onSuccess })
 *   // ... in render:  {renderSignModal()}
 *
 * Flow:
 *   1. On open, POST /api/ky-so/sign → receive transaction_id + provider_code.
 *   2. Show "Đang chờ xác nhận OTP" — start polling GET /api/ky-so/sign/:id every 3s.
 *   3. Also listen Socket.IO 'sign_completed' / 'sign_failed' for current txn_id
 *      (fast-path over polling — instantaneous when user online).
 *   4. Terminal states:
 *        completed → message.success + onSuccess() callback + allow close
 *        failed|expired|cancelled → Alert error + allow retry (user re-opens modal)
 *   5. User có thể:
 *        - Bấm "Hủy ký số" (chỉ khi pending) → POST /:id/cancel
 *        - Bấm "Đóng (chạy nền)" → giữ txn pending; bell notification sẽ báo khi xong
 *        - Bấm "Đóng" (terminal) → unmount modal
 *
 * Security (see Plan 11-06 threat_model):
 *   - T-11-21 Info Disclosure: Socket events filtered by `payload.transaction_id !== txnId`
 *   - T-11-23 DoS: COUNTDOWN_MS=3min FE-local timer + destroyOnHidden cleanup
 *
 * Phase 13 polish (Plan 13-03):
 *   - Countdown circular UI 3:00 (D-13, D-14, D-15, D-16, D-17)
 *   - Color state theo remaining: xanh > 60s, vàng 30-60s, đỏ < 30s
 *   - Expired transition khi remainingMs=0 (idempotent với BE Socket event qua expiredFired ref)
 *   - Spam-click disable: caller page dùng useSigning.isOpen (D-18, D-19)
 *   - maskClosable={false} giữ AntD 6 API `mask={{ closable: false }}` (Phase 12 hotfix)
 */

import { useEffect, useRef, useState } from 'react';
import {
  Modal,
  Alert,
  Space,
  Typography,
  Tag,
  Button,
  App as AntApp,
  Progress,
} from 'antd';
import {
  LoadingOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  ClockCircleOutlined,
  SafetyCertificateOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { getSocket, SOCKET_EVENTS } from '@/lib/socket';
import type {
  AttachmentType,
  TxnStatus,
  TxnStatusData,
  SignCompletedEvent,
  SignFailedEvent,
} from '@/lib/signing/types';

const { Text, Paragraph } = Typography;

// Poll REST fallback every 3s khi Socket.IO disconnected hoặc miss event
const POLL_INTERVAL_MS = 3000;
// Phase 13: countdown 3:00 OTP — khớp BE sign_transactions.expires_at = 180s
const COUNTDOWN_MS = 180_000;

export interface SignModalProps {
  open: boolean;
  onClose: () => void;
  /** Called exactly once khi status='completed' — parent refresh file list. */
  onSuccess?: (data: { transaction_id: number; signed_file_path: string | null }) => void;
  attachmentId: number;
  attachmentType: AttachmentType;
  fileName: string;
  /** doc_id (outgoing/drafting/handling FK) — optional, audit trail. */
  docId?: number;
  /** Custom metadata embed vào PDF placeholder. */
  signReason?: string;
  signLocation?: string;
}

const PROVIDER_NAMES: Record<string, string> = {
  SMARTCA_VNPT: 'SmartCA VNPT',
  MYSIGN_VIETTEL: 'MySign Viettel',
};

/**
 * Phase 13 — D-15: Color theo remaining time
 * - > 60s: xanh navy (brand primary #1B3A5C)
 * - 30s - 60s: vàng (warning #D97706)
 * - < 30s: đỏ (danger #DC2626)
 */
function countdownColor(ms: number): string {
  const s = Math.ceil(ms / 1000);
  if (s > 60) return '#1B3A5C';
  if (s >= 30) return '#D97706';
  return '#DC2626';
}

/** Phase 13 — format ms → 'M:SS' (zero-padded seconds) */
function formatMMSS(ms: number): string {
  const totalSec = Math.max(0, Math.ceil(ms / 1000));
  const mm = Math.floor(totalSec / 60);
  const ss = totalSec % 60;
  return `${mm}:${ss.toString().padStart(2, '0')}`;
}

function statusTag(status: TxnStatus) {
  switch (status) {
    case 'pending':
      return (
        <Tag color="processing" icon={<ClockCircleOutlined />}>
          Đang chờ xác nhận OTP
        </Tag>
      );
    case 'completed':
      return (
        <Tag color="success" icon={<CheckCircleOutlined />}>
          Đã ký
        </Tag>
      );
    case 'failed':
      return (
        <Tag color="error" icon={<CloseCircleOutlined />}>
          Thất bại
        </Tag>
      );
    case 'expired':
      return (
        <Tag color="warning" icon={<ClockCircleOutlined />}>
          Hết thời gian
        </Tag>
      );
    case 'cancelled':
      return <Tag color="default">Đã hủy</Tag>;
    default:
      return <Tag>{status}</Tag>;
  }
}

export default function SignModal(props: SignModalProps) {
  const { message } = AntApp.useApp();
  const {
    open,
    onClose,
    onSuccess,
    attachmentId,
    attachmentType,
    fileName,
    docId,
    signReason,
    signLocation,
  } = props;

  // --- State
  const [initiating, setInitiating] = useState(false);
  const [txnId, setTxnId] = useState<number | null>(null);
  const [providerCode, setProviderCode] = useState<string | null>(null);
  const [providerMessage, setProviderMessage] = useState<string | null>(null);
  const [status, setStatus] = useState<TxnStatus | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [cancelling, setCancelling] = useState(false);
  const [signedFilePath, setSignedFilePath] = useState<string | null>(null);

  // --- Phase 13: countdown state (D-13, D-14)
  const [remainingMs, setRemainingMs] = useState<number>(COUNTDOWN_MS);

  // Refs để cleanup timers + prevent duplicate onSuccess / expired
  const pollTimer = useRef<ReturnType<typeof setInterval> | null>(null);
  const countdownTimer = useRef<ReturnType<typeof setInterval> | null>(null);
  const successFired = useRef(false);
  // Phase 13 — expired idempotent guard: FE timer hết hoặc BE emit expired
  // chỉ setStatus('expired') đúng 1 lần (tương tự successFired pattern).
  const expiredFired = useRef(false);

  // ==========================================================================
  // Step 1: Initiate sign on open
  // ==========================================================================
  useEffect(() => {
    if (!open) return;
    let cancelled = false;

    async function start() {
      setInitiating(true);
      setErrorMsg(null);
      setStatus(null);
      setTxnId(null);
      setSignedFilePath(null);
      successFired.current = false;
      // Phase 13: reset countdown mỗi lần start — tránh giá trị cũ flash
      setRemainingMs(COUNTDOWN_MS);
      expiredFired.current = false;

      try {
        const { data: res } = await api.post('/ky-so/sign', {
          attachment_id: attachmentId,
          attachment_type: attachmentType,
          doc_id: docId,
          sign_reason: signReason,
          sign_location: signLocation,
        });
        if (cancelled) return;

        if (res?.success === false) {
          setErrorMsg(res.message || 'Khởi tạo ký số thất bại');
          setStatus('failed');
        } else if (res?.data) {
          setTxnId(res.data.transaction_id);
          setProviderCode(res.data.provider_code);
          setProviderMessage(res.data.provider_message ?? null);
          setStatus('pending');
        } else {
          setErrorMsg('Phản hồi không hợp lệ từ máy chủ');
          setStatus('failed');
        }
      } catch (err: unknown) {
        if (cancelled) return;
        const e = err as { response?: { data?: { message?: string } } };
        setErrorMsg(
          e?.response?.data?.message || 'Không thể kết nối đến máy chủ',
        );
        setStatus('failed');
      } finally {
        if (!cancelled) setInitiating(false);
      }
    }

    start();
    return () => {
      cancelled = true;
    };
  }, [open, attachmentId, attachmentType, docId, signReason, signLocation]);

  // ==========================================================================
  // Step 2: Poll + Socket listen while pending
  // ==========================================================================
  useEffect(() => {
    if (!open || !txnId || status !== 'pending') return;

    // Phase 13: lifetime guard moved → countdown useEffect below (FE-local 3:00
    // timer với expiredFired idempotent, không dùng setTimeout riêng nữa).

    // REST poll fallback
    const poll = async () => {
      try {
        const { data: res } = await api.get(`/ky-so/sign/${txnId}`);
        if (res?.success && res.data) {
          const d = res.data as TxnStatusData;
          setStatus(d.status);
          if (d.error_message) setErrorMsg(d.error_message);
          if (d.signed_file_path) setSignedFilePath(d.signed_file_path);
        }
      } catch {
        // Transient error — keep polling
      }
    };
    pollTimer.current = setInterval(poll, POLL_INTERVAL_MS);

    // Socket fast-path (T-11-21: filter by transaction_id)
    const socket = getSocket();
    const onCompleted = (payload: SignCompletedEvent) => {
      if (payload.transaction_id !== txnId) return;
      setStatus('completed');
      setSignedFilePath(payload.signed_file_path);
    };
    const onFailed = (payload: SignFailedEvent) => {
      if (payload.transaction_id !== txnId) return;
      // Phase 13: BE emit expired cùng lúc FE timer hết → idempotent guard
      if (payload.status === 'expired') {
        if (expiredFired.current) return;
        expiredFired.current = true;
      }
      setStatus(payload.status);
      setErrorMsg(payload.error_message);
    };
    socket?.on(SOCKET_EVENTS.SIGN_COMPLETED, onCompleted);
    socket?.on(SOCKET_EVENTS.SIGN_FAILED, onFailed);

    return () => {
      if (pollTimer.current) clearInterval(pollTimer.current);
      pollTimer.current = null;
      socket?.off(SOCKET_EVENTS.SIGN_COMPLETED, onCompleted);
      socket?.off(SOCKET_EVENTS.SIGN_FAILED, onFailed);
    };
  }, [open, txnId, status]);

  // ==========================================================================
  // Phase 13 Step 2.5: Countdown timer (FE-local tick 1s — D-14)
  //
  // Chỉ chạy khi modal open + đã có txnId + status='pending'.
  // Khi remain <= 0: set status='expired' + Alert error, mark expiredFired
  // để tránh double-fire nếu BE Socket event `sign_failed` status=expired đến sau.
  // ==========================================================================
  useEffect(() => {
    if (!open || !txnId || status !== 'pending') return;

    const startAt = Date.now();
    countdownTimer.current = setInterval(() => {
      const elapsed = Date.now() - startAt;
      const remain = COUNTDOWN_MS - elapsed;
      if (remain <= 0) {
        setRemainingMs(0);
        if (!expiredFired.current) {
          expiredFired.current = true;
          setStatus('expired');
          setErrorMsg('Hết thời gian chờ xác nhận OTP. Vui lòng thử lại.');
        }
        if (countdownTimer.current) clearInterval(countdownTimer.current);
        countdownTimer.current = null;
      } else {
        setRemainingMs(remain);
      }
    }, 1000);

    return () => {
      if (countdownTimer.current) clearInterval(countdownTimer.current);
      countdownTimer.current = null;
    };
  }, [open, txnId, status]);

  // ==========================================================================
  // Step 3: React to terminal 'completed' — fire onSuccess exactly once
  // ==========================================================================
  useEffect(() => {
    if (status === 'completed' && txnId != null && !successFired.current) {
      successFired.current = true;
      message.success('Ký số thành công');
      onSuccess?.({ transaction_id: txnId, signed_file_path: signedFilePath });
    }
  }, [status, txnId, signedFilePath, message, onSuccess]);

  // ==========================================================================
  // Actions
  // ==========================================================================
  const handleCancelSign = async () => {
    if (!txnId) return;
    setCancelling(true);
    try {
      await api.post(`/ky-so/sign/${txnId}/cancel`);
      setStatus('cancelled');
      message.info('Đã hủy giao dịch ký số');
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Không thể hủy giao dịch');
    } finally {
      setCancelling(false);
    }
  };

  const handleClose = () => {
    // KHÔNG auto-cancel — txn tiếp tục chạy nền, user nhận bell notification
    // khi worker hoàn tất (Phase 11-04 noticeRepository.createForStaff).
    onClose();
  };

  // ==========================================================================
  // Render
  // ==========================================================================
  const providerName = providerCode
    ? PROVIDER_NAMES[providerCode] ?? providerCode
    : 'nhà cung cấp dịch vụ';
  const isTerminal =
    status === 'completed' ||
    status === 'failed' ||
    status === 'cancelled' ||
    status === 'expired';

  // Build footer array. AntD 6 Modal footer accepts ReactNode[] — filter null khỏi array
  const footer: React.ReactNode[] = [];
  if (status === 'pending') {
    footer.push(
      <Button
        key="cancel-sign"
        danger
        loading={cancelling}
        onClick={handleCancelSign}
      >
        Hủy ký số
      </Button>,
    );
  }
  footer.push(
    <Button
      key="close"
      type={isTerminal ? 'primary' : 'default'}
      onClick={handleClose}
    >
      {isTerminal ? 'Đóng' : 'Đóng (chạy nền)'}
    </Button>,
  );

  return (
    <Modal
      open={open}
      title={
        <Space>
          <SafetyCertificateOutlined style={{ color: '#1B3A5C' }} />
          Ký số điện tử
        </Space>
      }
      onCancel={handleClose}
      width={560}
      mask={{ closable: false }}
      destroyOnHidden
      footer={footer}
    >
      <div style={{ padding: '8px 0' }}>
        <Paragraph style={{ marginBottom: 8 }}>
          <Text strong>File: </Text>
          <Text>{fileName}</Text>
        </Paragraph>

        {providerCode && (
          <Paragraph style={{ marginBottom: 8 }}>
            <Text strong>Nhà cung cấp: </Text>
            <Tag color="blue">{providerName}</Tag>
          </Paragraph>
        )}

        <div style={{ marginBottom: 12 }}>
          <Text strong>Trạng thái: </Text>
          {initiating ? (
            <Tag color="processing" icon={<LoadingOutlined />}>
              Đang khởi tạo giao dịch...
            </Tag>
          ) : status ? (
            statusTag(status)
          ) : (
            <Tag>Chưa xác định</Tag>
          )}
        </div>

        {status === 'pending' && (
          <div
            style={{
              textAlign: 'center',
              padding: '16px 0 12px',
            }}
          >
            <Progress
              type="circle"
              size={120}
              percent={Math.round((remainingMs / COUNTDOWN_MS) * 100)}
              strokeColor={countdownColor(remainingMs)}
              format={() => (
                <span
                  style={{
                    fontSize: 24,
                    fontWeight: 600,
                    color: countdownColor(remainingMs),
                    fontVariantNumeric: 'tabular-nums',
                  }}
                >
                  {formatMMSS(remainingMs)}
                </span>
              )}
            />
            <div
              style={{
                marginTop: 12,
                fontSize: 13,
                color: '#475569',
                lineHeight: 1.5,
              }}
            >
              Vui lòng xác nhận OTP trên ứng dụng <b>{providerName}</b> trên
              điện thoại
            </div>
          </div>
        )}

        {status === 'pending' && (
          <Alert
            type="info"
            showIcon
            style={{ borderRadius: 12 }}
            message="Chờ xác nhận OTP trên thiết bị di động"
            description={
              <div>
                <p style={{ margin: '0 0 8px 0' }}>
                  Mở ứng dụng <b>{providerName}</b> trên điện thoại và xác nhận
                  yêu cầu ký số.
                </p>
                <p style={{ margin: '0 0 8px 0' }}>
                  Hệ thống sẽ tự động cập nhật khi bạn xác nhận. Bạn có thể bấm{' '}
                  <b>&quot;Đóng (chạy nền)&quot;</b> — giao dịch vẫn tiếp tục và
                  bạn sẽ nhận thông báo khi hoàn tất.
                </p>
                {providerMessage && (
                  <Text type="secondary" style={{ fontSize: 12 }}>
                    Phản hồi từ provider: {providerMessage}
                  </Text>
                )}
              </div>
            }
          />
        )}

        {status === 'completed' && (
          <Alert
            type="success"
            showIcon
            style={{ borderRadius: 12 }}
            message="Ký số thành công"
            description={`File đã được ký bằng ${providerName}. Bấm "Đóng" để xem file đã ký trong danh sách đính kèm.`}
          />
        )}

        {(status === 'failed' ||
          status === 'expired' ||
          status === 'cancelled') && (
          <Alert
            type={status === 'cancelled' ? 'warning' : 'error'}
            showIcon
            style={{ borderRadius: 12 }}
            message={
              status === 'expired'
                ? 'Hết thời gian chờ xác nhận OTP'
                : status === 'cancelled'
                  ? 'Đã hủy giao dịch'
                  : 'Ký số thất bại'
            }
            description={
              errorMsg ||
              (status === 'cancelled'
                ? 'Giao dịch đã được hủy theo yêu cầu.'
                : 'Vui lòng đóng cửa sổ và thử lại.')
            }
          />
        )}
      </div>
    </Modal>
  );
}
