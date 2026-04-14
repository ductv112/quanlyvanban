import 'dotenv/config';
import { Worker } from 'bullmq';
import IORedis from 'ioredis';
import pg from 'pg';
import pino from 'pino';

const { Pool } = pg;

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

const pool = new Pool({
  host: process.env.PG_HOST || 'localhost',
  port: Number(process.env.PG_PORT) || 5432,
  database: process.env.PG_DATABASE || 'qlvb_dev',
  user: process.env.PG_USER || 'qlvb_admin',
  password: process.env.PG_PASSWORD,
  max: 5,
  idleTimeoutMillis: 30000,
});

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

// --- LGSP Receive Worker ---
const lgspReceiveWorker = new Worker(
  'lgsp-receive',
  async (job) => {
    logger.info({ jobId: job.id }, 'Checking LGSP for new documents...');

    // Mock: simulate receiving 0-2 documents
    const count = Math.floor(Math.random() * 3);
    if (count === 0) {
      logger.info('LGSP: No new documents');
      return;
    }

    const mockDocs = [
      { lgsp_doc_id: `LGSP-MOCK-${Date.now()}-1`, org_code: 'H01.01', org_name: 'UBND tinh Lao Cai', edxml: '<edXML><header><subject>Mock received doc 1</subject></header></edXML>' },
      { lgsp_doc_id: `LGSP-MOCK-${Date.now()}-2`, org_code: 'H01.01.02', org_name: 'So Tai chinh tinh Lao Cai', edxml: '<edXML><header><subject>Mock received doc 2</subject></header></edXML>' },
    ];

    const docs = mockDocs.slice(0, count);
    for (const doc of docs) {
      await pool.query(
        'SELECT * FROM edoc.fn_lgsp_tracking_create($1, $2, $3, $4, $5, $6)',
        [null, 'receive', doc.org_code, doc.org_name, doc.edxml, null],
      );
    }

    logger.info(`LGSP: Received ${docs.length} documents`);
  },
  { connection },
);

// --- LGSP Send Worker ---
const lgspSendWorker = new Worker(
  'lgsp-send',
  async (job) => {
    const { tracking_id, dest_org_code } = job.data;
    logger.info({ jobId: job.id, destOrg: dest_org_code }, 'MOCK: Sending document to LGSP...');

    // Mock: update tracking status to 'success'
    await pool.query(
      'SELECT * FROM edoc.fn_lgsp_tracking_update_status($1, $2, $3, $4)',
      [tracking_id, 'success', `LGSP-MOCK-${Date.now()}`, null],
    );

    logger.info({ jobId: job.id, trackingId: tracking_id }, 'LGSP: Document sent successfully (mock)');
  },
  { connection },
);

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

logger.info('Workers started: email-send, sms-send, lgsp-receive, lgsp-send, fcm-push, zalo-send, notification-send');

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('Shutting down workers...');
  await emailWorker.close();
  await smsWorker.close();
  await lgspReceiveWorker.close();
  await lgspSendWorker.close();
  await fcmWorker.close();
  await zaloWorker.close();
  await notificationWorker.close();
  await pool.end();
  process.exit(0);
});
