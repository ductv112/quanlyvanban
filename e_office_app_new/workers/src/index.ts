import 'dotenv/config';
import { Worker } from 'bullmq';
import IORedis from 'ioredis';
import pino from 'pino';

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

// --- Email Worker ---
const emailWorker = new Worker(
  'email-send',
  async (job) => {
    logger.info({ jobId: job.id, to: job.data.to }, 'Sending email...');
    // TODO: implement nodemailer send
  },
  { connection }
);

// --- SMS Worker ---
const smsWorker = new Worker(
  'sms-send',
  async (job) => {
    logger.info({ jobId: job.id }, 'Sending SMS...');
    // TODO: implement SMS gateway
  },
  { connection }
);

// --- LGSP Receive Worker ---
const lgspReceiveWorker = new Worker(
  'lgsp-receive',
  async (job) => {
    logger.info({ jobId: job.id }, 'Checking LGSP for new documents...');
    // TODO: implement LGSP API polling
  },
  { connection }
);

// --- FCM Push Worker ---
const fcmWorker = new Worker(
  'fcm-push',
  async (job) => {
    logger.info({ jobId: job.id }, 'Sending push notification...');
    // TODO: implement Firebase FCM
  },
  { connection }
);

logger.info('Workers started: email-send, sms-send, lgsp-receive, fcm-push');

// Graceful shutdown
process.on('SIGTERM', async () => {
  await emailWorker.close();
  await smsWorker.close();
  await lgspReceiveWorker.close();
  await fcmWorker.close();
  process.exit(0);
});
