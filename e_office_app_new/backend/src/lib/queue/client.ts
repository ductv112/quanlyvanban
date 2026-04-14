import { Queue } from 'bullmq';

// Reuse same Redis connection config as workers
const connection = {
  host: process.env.REDIS_HOST || 'localhost',
  port: Number(process.env.REDIS_PORT) || 6379,
  password: process.env.REDIS_PASSWORD,
};

// --- LGSP Queues ---
export const lgspReceiveQueue = new Queue('lgsp-receive', { connection });
export const lgspSendQueue = new Queue('lgsp-send', { connection });

// --- Notification Queues ---
export const notificationQueue = new Queue('notification-send', { connection });
export const emailQueue = new Queue('email-send', { connection });
export const smsQueue = new Queue('sms-send', { connection });
export const fcmQueue = new Queue('fcm-push', { connection });
export const zaloQueue = new Queue('zalo-send', { connection });
