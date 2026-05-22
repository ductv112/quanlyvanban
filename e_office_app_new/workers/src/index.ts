import 'dotenv/config';
import { Worker } from 'bullmq';
import IORedis from 'ioredis';
import pino from 'pino';
import {
  startLgspSendWorker,
  stopLgspSendWorker,
} from './jobs/lgsp-send-worker.js';
import {
  startLgspReceiveTickWorker,
  stopLgspReceiveTickWorker,
} from './jobs/lgsp-receive-tick-worker.js';
import {
  startLgspReceiveDnWorker,
  stopLgspReceiveDnWorker,
} from './jobs/lgsp-receive-dn-worker.js';
import {
  startLgspStatusTickWorker,
  stopLgspStatusTickWorker,
} from './jobs/lgsp-status-tick-worker.js';
import {
  startLgspStatusEventWorker,
  stopLgspStatusEventWorker,
} from './jobs/lgsp-status-event-worker.js';
import { getSharedPgPool, closeSharedPgPool } from './lib/pg-pool.js';

const logger = pino({
  level: 'info',
  transport: process.env.NODE_ENV !== 'production' ? { target: 'pino-pretty' } : undefined,
});

const connection = new IORedis({
  host: process.env.REDIS_HOST || 'localhost',
  port: Number(process.env.REDIS_PORT) || 6379,
  password: process.env.REDIS_PASSWORD,
  maxRetriesPerRequest: null,
});

// v3.2.2 fix #M10: dung shared pg pool thay vi tao pool rieng cho moi worker file
const pool = getSharedPgPool();

// ============================================================
// Helper: update notification_log status after mock send
// ============================================================
async function updateNotificationLogStatus(
  logId: number | undefined,
  status: 'sent' | 'failed',
  errorMessage: string | null,
): Promise<void> {
  if (!logId) return;
  try {
    await pool.query(
      'SELECT * FROM edoc.fn_notification_log_update_status($1, $2, $3)',
      [logId, status, errorMessage],
    );
  } catch (err) {
    logger.error({ logId, err }, 'Failed to update notification_log status');
  }
}

// --- Email Worker ---
const emailWorker = new Worker(
  'email-send',
  async (job) => {
    const { staff_id, title, body, notification_log_id } = job.data;
    try {
      logger.info(
        { jobId: job.id, staffId: staff_id, subject: title },
        'MOCK: Email sent to staff %d — Subject: %s',
        staff_id,
        title || '(no subject)',
      );
      // Mock: log instead of actually sending via nodemailer
      await updateNotificationLogStatus(notification_log_id, 'sent', null);
    } catch (err) {
      logger.error({ jobId: job.id, err }, 'MOCK: Email send failed');
      await updateNotificationLogStatus(notification_log_id, 'failed', (err as Error).message);
      throw err;
    }
  },
  { connection },
);

// --- SMS Worker ---
const smsWorker = new Worker(
  'sms-send',
  async (job) => {
    const { staff_id, body, notification_log_id } = job.data;
    try {
      logger.info(
        { jobId: job.id, staffId: staff_id },
        'MOCK: SMS sent to staff %d — %s',
        staff_id,
        body || '(empty)',
      );
      await updateNotificationLogStatus(notification_log_id, 'sent', null);
    } catch (err) {
      logger.error({ jobId: job.id, err }, 'MOCK: SMS send failed');
      await updateNotificationLogStatus(notification_log_id, 'failed', (err as Error).message);
      throw err;
    }
  },
  { connection },
);

// ============================================================
// LGSP Receive Workers (Phase 35) — REPLACED Phase 18 inline polling.
//
// New: BullMQ 2-worker system on queue 'lgsp-receive':
//   - 'receive-tick' (concurrency=1): repeat every 5 min OR manual via POST /api/lgsp/sync-now
//     Handler queries lgsp_agency_config active rows -> enqueues N 'receive-dn' jobs.
//   - 'receive-dn' (concurrency=3, retry 3x exp 30s): full per-DN sync pipeline
//     (list + getEdoc + parse + INSERT incoming_docs + MinIO + outbox status 01)
//
// Phase 18 helpers DELETED: lgspLogin(), lgspReceiveList(), LGSP_MOCK / LGSP_TOKEN_TTL_MS
// state vars, inline lgspReceiveWorker. All replaced by workers/src/jobs/lgsp-receive-*.ts
// using /v1/syncReceivedEdocList + /v1/getEdoc with X-SystemId/X-SecretKey headers
// (Postman authoritative).
//
// Repeat job is registered from backend/src/server.ts on startup
// (registerReceiveTickRepeatJob in backend/src/lib/queue/lgsp-receive-queue.ts — Plan 35-03).
// ============================================================
const lgspReceiveTickWorker = startLgspReceiveTickWorker();
const lgspReceiveDnWorker = startLgspReceiveDnWorker();

// ============================================================
// LGSP Status Workers (Phase 36) -- callback chain.
//
// 2-worker system on queue 'lgsp-status':
//   - 'status-tick' (concurrency=1): repeat every 30s OR future admin manual trigger
//     Handler queries fn_lgsp_status_outbox_get_pending(100) -> enqueues N 'status-event' jobs FIFO.
//   - 'status-event' (concurrency=5, retry 5x exp 30s): per-outbox-row POST /v1/updateStatus.
//     4xx no-retry mark error (D-10), network/5xx retry (D-09), exhausted -> on(failed) markError (D-11).
//
// Repeat job registered from backend/src/server.ts (Plan 36-03 wires registerStatusTickRepeatJob).
// ============================================================
const lgspStatusTickWorker = startLgspStatusTickWorker();
const lgspStatusEventWorker = startLgspStatusEventWorker();

// --- LGSP Send Worker (Phase 34) ---
// REPLACED Phase 18 inline worker. New handler in workers/src/jobs/lgsp-send-worker.ts:
//   - Job data shape: LgspSendJobData { recipient_id, outgoing_doc_id, tracking_id, sender_unit_id, environment }
//   - 1 job = 1 external recipient (granularity per-recipient — D-02)
//   - Concurrency 3 (D-04), retry 5 attempts exp backoff 30s/60s/120s/240s/480s (D-10)
//   - Per-attempt credential fresh-load (D-14 rotation, no in-worker cache)
//   - Build edXML + multipart /v1/sendEdoc + X-SystemId/X-SecretKey headers (Phase 34-01)
//   - 4xx LGSP errorCode = no-retry mark tracking error (D-11)
//   - Network/5xx = throw -> BullMQ retry, exhausted -> on('failed') mark error (D-13)
const lgspSendWorker = startLgspSendWorker();

// --- FCM Push Worker ---
const fcmWorker = new Worker(
  'fcm-push',
  async (job) => {
    const { staff_id, title, body, notification_log_id } = job.data;
    try {
      logger.info(
        { jobId: job.id, staffId: staff_id, title },
        'MOCK: FCM push sent to staff %d — %s',
        staff_id,
        title || '(no title)',
      );
      await updateNotificationLogStatus(notification_log_id, 'sent', null);
    } catch (err) {
      logger.error({ jobId: job.id, err }, 'MOCK: FCM push failed');
      await updateNotificationLogStatus(notification_log_id, 'failed', (err as Error).message);
      throw err;
    }
  },
  { connection },
);

// --- Zalo OA Worker ---
const zaloWorker = new Worker(
  'zalo-send',
  async (job) => {
    const { staff_id, title, body, notification_log_id } = job.data;
    try {
      logger.info(
        { jobId: job.id, staffId: staff_id, title },
        'MOCK: Zalo OA message sent to staff %d — %s',
        staff_id,
        title || '(no title)',
      );
      await updateNotificationLogStatus(notification_log_id, 'sent', null);
    } catch (err) {
      logger.error({ jobId: job.id, err }, 'MOCK: Zalo OA send failed');
      await updateNotificationLogStatus(notification_log_id, 'failed', (err as Error).message);
      throw err;
    }
  },
  { connection },
);

// --- Notification Router Worker (dispatches to channel-specific queues) ---
const notificationWorker = new Worker(
  'notification-send',
  async (job) => {
    const { staff_id, channel, event_type, title, body, notification_log_id } = job.data;
    logger.info(
      { jobId: job.id, staffId: staff_id, channel, eventType: event_type },
      'MOCK: Processing notification for staff %d via %s',
      staff_id,
      channel || 'all',
    );
    // Route to specific channel worker if needed
    await updateNotificationLogStatus(notification_log_id, 'sent', null);
  },
  { connection },
);

logger.info('Workers started: email-send, sms-send, lgsp-receive (Phase 35: tick + dn), lgsp-send (Phase 34), lgsp-status (Phase 36: tick + event), fcm-push, zalo-send, notification-send');

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('Shutting down workers...');
  await emailWorker.close();
  await smsWorker.close();
  await stopLgspReceiveTickWorker(lgspReceiveTickWorker);
  await stopLgspReceiveDnWorker(lgspReceiveDnWorker);
  await stopLgspStatusTickWorker(lgspStatusTickWorker);
  await stopLgspStatusEventWorker(lgspStatusEventWorker);
  await stopLgspSendWorker(lgspSendWorker);
  await fcmWorker.close();
  await zaloWorker.close();
  await notificationWorker.close();
  // v3.2.2 fix #M10: close shared pool (replaces individual pool.end calls)
  await closeSharedPgPool();
  process.exit(0);
});
