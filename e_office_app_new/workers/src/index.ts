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

// ============================================================
// LGSP HTTP client — Phase 18 v3.0: real call apiltvb.langson.gov.vn
// (fallback mock khi MOCK_EXTERNAL=true)
// ============================================================
const LGSP_MOCK = process.env.MOCK_EXTERNAL === 'true' || !process.env.LGSP_ENDPOINT;
const LGSP_TOKEN_TTL_MS = 29 * 60 * 1000;
let lgspToken: string | null = null;
let lgspTokenExp = 0;

async function lgspLogin(): Promise<string> {
  if (lgspToken && Date.now() < lgspTokenExp) return lgspToken;
  const ep = process.env.LGSP_ENDPOINT!.replace(/\/$/, '');
  const res = await fetch(`${ep}/api/lgspedoc/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      username: process.env.LGSP_USERNAME,
      password: process.env.LGSP_PASSWORD,
      applicationCode: process.env.LGSP_APPLICATION_CODE,
    }),
  });
  if (!res.ok) throw new Error(`LGSP login failed HTTP ${res.status}`);
  const json = await res.json() as { success: boolean; message: string; token: string };
  if (!json.success || !json.token) throw new Error(`LGSP login failed: ${json.message}`);
  lgspToken = json.token;
  lgspTokenExp = Date.now() + LGSP_TOKEN_TTL_MS;
  return lgspToken;
}

interface LgspReceivedItem {
  docId: string;
  from: string;
  status: string;
}

async function lgspReceiveList(): Promise<LgspReceivedItem[]> {
  const token = await lgspLogin();
  const ep = process.env.LGSP_ENDPOINT!.replace(/\/$/, '');
  const today = new Date().toISOString().slice(0, 10);
  const fromDate = new Date(Date.now() - 7 * 86400_000).toISOString().slice(0, 10);
  const url = `${ep}/api/lgspedoc/received-edocs?token=${encodeURIComponent(token)}` +
    `&messageType=edoc&fromDate=${fromDate}&toDate=${today}` +
    `&systemId=${encodeURIComponent(process.env.LGSP_SYSTEM_ID || '')}` +
    `&secretKey=${encodeURIComponent(process.env.LGSP_SECRET_KEY || '')}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`LGSP received-edocs HTTP ${res.status}`);
  const json = await res.json() as { success: boolean; data?: LgspReceivedItem[] };
  if (!json.success || !Array.isArray(json.data)) return [];
  return json.data.filter((d) => d.status === 'initial');
}

async function lgspSendEdoc(edxml: string, destOrgCode: string): Promise<{ ok: boolean; docId?: string; message: string }> {
  const token = await lgspLogin();
  const ep = process.env.LGSP_ENDPOINT!.replace(/\/$/, '');
  const res = await fetch(`${ep}/api/lgspedoc/send-edoc`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      token,
      edocContent: edxml,
      messageType: 'edoc',
      systemId: process.env.LGSP_SYSTEM_ID || '',
      secretKey: process.env.LGSP_SECRET_KEY || '',
      destOrgCode,
    }),
  });
  const json = await res.json() as { success: boolean; message: string; docId?: string; data?: { docId?: string; errorDesc?: string } };
  return {
    ok: !!json.success,
    docId: json.docId || json.data?.docId,
    message: json.message || json.data?.errorDesc || 'unknown',
  };
}

// --- LGSP Receive Worker (polling) ---
const lgspReceiveWorker = new Worker(
  'lgsp-receive',
  async (job) => {
    logger.info({ jobId: job.id, mock: LGSP_MOCK }, 'LGSP: polling for new documents...');

    if (LGSP_MOCK) {
      const mockDocs = [
        { lgsp_doc_id: `LGSP-MOCK-${Date.now()}`, org_code: 'BNV', org_name: 'Bộ Nội vụ', edxml: '<edXML>Mock</edXML>' },
      ];
      const count = Math.floor(Math.random() * 2); // 0-1 mock
      for (const doc of mockDocs.slice(0, count)) {
        // Insert incoming_docs với source_type='external_lgsp' (Phase 17 SP fn_incoming_doc_create đã hỗ trợ)
        await pool.query(
          'SELECT * FROM edoc.fn_incoming_doc_create($1, NOW(), NULL::integer, $2, $3, $4, $5, NOW(), NULL::varchar, NULL::timestamptz, NULL::integer, NULL::integer, NULL::integer, 1::smallint, 1::smallint, 1::integer, 1::integer, NULL::timestamptz, NULL::text, FALSE::boolean, 1::integer, NULL::integer, $6::edoc.doc_source_type, FALSE::boolean, $7::varchar, NULL::bigint, $8::varchar)',
          [1, doc.lgsp_doc_id.slice(0, 50), doc.lgsp_doc_id.slice(0, 50), 'Mock LGSP doc ' + doc.lgsp_doc_id, doc.org_name, 'external_lgsp', doc.org_name, doc.lgsp_doc_id],
        );
        logger.info({ docId: doc.lgsp_doc_id }, 'LGSP MOCK: incoming created');
      }
      return;
    }

    // Real LGSP polling
    try {
      const items = await lgspReceiveList();
      logger.info({ count: items.length }, 'LGSP: received initial docs');
      for (const item of items) {
        // Check dedupe (fn_incoming_doc_create có UNIQUE INDEX trên external_doc_id WHERE source_type='external_lgsp')
        await pool.query(
          'SELECT * FROM edoc.fn_incoming_doc_create($1, NOW(), NULL::integer, $2, $3, $4, $5, NOW(), NULL::varchar, NULL::timestamptz, NULL::integer, NULL::integer, NULL::integer, 1::smallint, 1::smallint, 1::integer, 1::integer, NULL::timestamptz, NULL::text, FALSE::boolean, 1::integer, NULL::integer, $6::edoc.doc_source_type, FALSE::boolean, $7::varchar, NULL::bigint, $8::varchar)',
          [1, item.docId.slice(0, 50), item.docId.slice(0, 50), `LGSP doc from ${item.from}`, item.from, 'external_lgsp', item.from, item.docId],
        ).catch((e) => logger.warn({ docId: item.docId, err: e.message }, 'LGSP receive insert failed (likely duplicate)'));
      }
    } catch (err) {
      logger.error({ err: (err as Error).message }, 'LGSP receive polling error');
    }
  },
  { connection },
);

// --- LGSP Send Worker ---
const lgspSendWorker = new Worker(
  'lgsp-send',
  async (job) => {
    const { tracking_id, dest_org_code, edxml_content } = job.data;
    logger.info({ jobId: job.id, trackingId: tracking_id, destOrg: dest_org_code, mock: LGSP_MOCK }, 'LGSP: sending...');

    if (LGSP_MOCK) {
      await pool.query(
        'SELECT * FROM edoc.fn_lgsp_tracking_update_status($1, $2, $3, $4)',
        [tracking_id, 'success', `LGSP-MOCK-${Date.now()}`, null],
      );
      logger.info({ trackingId: tracking_id }, 'LGSP MOCK: sent OK');
      return;
    }

    try {
      const result = await lgspSendEdoc(edxml_content || '<edXML/>', dest_org_code);
      if (result.ok) {
        await pool.query('SELECT * FROM edoc.fn_lgsp_tracking_update_status($1, $2, $3, $4)',
          [tracking_id, 'success', result.docId || '', null]);
        logger.info({ trackingId: tracking_id, lgspDocId: result.docId }, 'LGSP: sent OK');
      } else {
        await pool.query('SELECT * FROM edoc.fn_lgsp_tracking_update_status($1, $2, $3, $4)',
          [tracking_id, 'error', null, result.message]);
        logger.warn({ trackingId: tracking_id, message: result.message }, 'LGSP: sent failed');
      }
    } catch (err) {
      await pool.query('SELECT * FROM edoc.fn_lgsp_tracking_update_status($1, $2, $3, $4)',
        [tracking_id, 'error', null, (err as Error).message]).catch(() => null);
      logger.error({ trackingId: tracking_id, err: (err as Error).message }, 'LGSP: send error');
    }
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
