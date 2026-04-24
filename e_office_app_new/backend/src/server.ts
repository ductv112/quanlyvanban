import 'dotenv/config';
import { createServer } from 'http';
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import compression from 'compression';
import cookieParser from 'cookie-parser';
import { pinoHttp } from 'pino-http';
import pino from 'pino';

import healthRoutes from './routes/health.js';
import authRoutes from './routes/auth.js';
import adminRoutes from './routes/admin.js';
import adminCatalogRoutes from './routes/admin-catalog.js';
import publicCatalogRoutes from './routes/public-catalog.js';
import incomingDocRoutes from './routes/incoming-doc.js';
import draftingDocRoutes from './routes/drafting-doc.js';
import outgoingDocRoutes from './routes/outgoing-doc.js';
import handlingDocRoutes from './routes/handling-doc.js';
import workflowRoutes from './routes/workflow.js';
import handlingDocReportRoutes from './routes/handling-doc-report.js';
import interIncomingRoutes from './routes/inter-incoming.js';
import messageRoutes from './routes/message.js';
import noticeRoutes from './routes/notice.js';
import calendarRoutes from './routes/calendar.js';
import directoryRoutes from './routes/directory.js';
import dashboardRoutes from './routes/dashboard.js';
import archiveRoutes from './routes/archive.js';
import documentRoutes from './routes/document.js';
import contractRoutes from './routes/contract.js';
import meetingRoutes from './routes/meeting.js';
import lgspRoutes from './routes/lgsp.js';
import digitalSignatureRoutes from './routes/digital-signature.js';
import kySoCauHinhRoutes from './routes/ky-so-cau-hinh.js';
import kySoTaiKhoanRoutes from './routes/ky-so-tai-khoan.js';
import kySoSignRoutes from './routes/ky-so-sign.js';
import kySoDanhSachRoutes from './routes/ky-so-danh-sach.js';
import notificationRoutes from './routes/notification.js';
import bellNotificationsRoutes from './routes/notifications.js';  // Phase 13 — personal bell
import sendConfigRoutes from './routes/send-config.js';
import profileRoutes from './routes/profile.js';
import { authenticate, requireRoles } from './middleware/auth.js';
import { initSocket } from './lib/socket.js';
import { ensureBucket } from './lib/minio/client.js';
import { startSigningWorker, stopSigningWorker } from './workers/signing-poll.worker.js';
import { closeSigningQueue } from './lib/queue/signing-queue.js';
import { closeRedisConnection } from './lib/queue/redis-connection.js';

const app = express();
const port = Number(process.env.PORT) || 4000;

const logger = pino({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  transport: process.env.NODE_ENV !== 'production' ? { target: 'pino-pretty' } : undefined,
});

// --- Middleware ---
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN || 'http://localhost:3000', credentials: true }));
app.use(compression());
app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(cookieParser());
app.use(pinoHttp({ logger }));

// --- Routes ---
app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);

// Phase 17 v3.0: 2 endpoints GET don-vi public cho non-admin (recipient picker)
// Mount TRƯỚC /api/quan-tri admin guard — longer-prefix-wins
app.use('/api/quan-tri', authenticate, publicCatalogRoutes);
app.use('/api/quan-tri', authenticate, requireRoles('Quản trị hệ thống'), adminRoutes);
app.use('/api/quan-tri', authenticate, requireRoles('Quản trị hệ thống'), adminCatalogRoutes);

// --- Module routes ---
app.use('/api/van-ban-den', authenticate, incomingDocRoutes);
app.use('/api/van-ban-du-thao', authenticate, draftingDocRoutes);
app.use('/api/van-ban-lien-thong', authenticate, interIncomingRoutes);
app.use('/api/van-ban-di', authenticate, outgoingDocRoutes);
// NOTE: /thong-ke must be mounted BEFORE /ho-so-cong-viec to prevent /:id param from catching 'thong-ke'
app.use('/api/ho-so-cong-viec/thong-ke', authenticate, handlingDocReportRoutes);
app.use('/api/ho-so-cong-viec', authenticate, handlingDocRoutes);
app.use('/api/quan-tri/quy-trinh', authenticate, workflowRoutes);
app.use('/api/tin-nhan', authenticate, messageRoutes);
app.use('/api/thong-bao', authenticate, noticeRoutes);
app.use('/api/notifications', authenticate, bellNotificationsRoutes);  // Phase 13 — personal bell
app.use('/api/lich', authenticate, calendarRoutes);
app.use('/api/danh-ba', authenticate, directoryRoutes);
app.use('/api/dashboard', authenticate, dashboardRoutes);
app.use('/api/cau-hinh-gui-nhanh', authenticate, sendConfigRoutes);

// HDSD I.4 — Profile cá nhân (chữ ký số). Chỉ authenticate, KHÔNG requireRoles để mọi user dùng được.
app.use('/api/ho-so-ca-nhan', authenticate, profileRoutes);

// --- Phase 5: Kho luu tru, Tai lieu, Hop dong, Cuoc hop ---
app.use('/api/kho-luu-tru', authenticate, archiveRoutes);
app.use('/api/tai-lieu', authenticate, documentRoutes);
app.use('/api/hop-dong', authenticate, contractRoutes);
app.use('/api/cuoc-hop', authenticate, meetingRoutes);

// --- Phase 6: Tich hop he thong ngoai ---
app.use('/api/lgsp', authenticate, lgspRoutes);
// Phase 9: Admin config cho ký số — MUST mount BEFORE /api/ky-so generic (longer prefix wins)
app.use('/api/ky-so/cau-hinh', authenticate, requireRoles('Quản trị hệ thống'), kySoCauHinhRoutes);
// Phase 10: User config ký số cá nhân — mount BEFORE /api/ky-so generic, authenticate only (mọi user)
app.use('/api/ky-so/tai-khoan', authenticate, kySoTaiKhoanRoutes);
// Phase 11: Async sign flow (POST /sign, GET /sign/:id, POST /sign/:id/cancel)
// MUST mount BEFORE /api/ky-so generic — longer prefix wins; authenticate only (mọi user)
app.use('/api/ky-so/sign', authenticate, kySoSignRoutes);
// Phase 11 Plan 05: Sign list (4 tab) + badge counts — mount BEFORE /api/ky-so catch-all
app.use('/api/ky-so/danh-sach', authenticate, kySoDanhSachRoutes);
app.use('/api/ky-so', authenticate, digitalSignatureRoutes);
app.use('/api/thong-bao-kenh', authenticate, notificationRoutes);

// --- Error handler ---
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error(err);
  // NEVER expose raw DB errors to client
  const isDev = process.env.NODE_ENV !== 'production';
  res.status(500).json({
    success: false,
    message: isDev ? err.message : 'Có lỗi xảy ra, vui lòng thử lại sau'
  });
});

// --- Start ---
const httpServer = createServer(app);
initSocket(httpServer);
httpServer.listen(port, async () => {
  logger.info(`QLVB Backend running at http://localhost:${port}`);
  logger.info(`Health check: http://localhost:${port}/api/health`);
  try { await ensureBucket(); logger.info('MinIO bucket ready'); } catch (e) { logger.warn('MinIO bucket init failed — file upload sẽ tự tạo khi cần'); }

  // Phase 11: Start BullMQ signing worker (poll-sign-status consumer)
  // WORKER_ENABLED=false env → skip (useful for CI / sync-only debug)
  try {
    startSigningWorker();
  } catch (err) {
    logger.error({ err }, 'Failed to start signing worker — async sign flow will not work');
  }
});

// --- Graceful shutdown (Phase 11 — ensure in-flight sign jobs finish before exit) ---
let shuttingDown = false;
async function shutdown(signal: string): Promise<void> {
  if (shuttingDown) return;
  shuttingDown = true;
  logger.info({ signal }, 'Shutting down gracefully');

  try { await stopSigningWorker(); } catch (err) { logger.warn({ err }, 'stopSigningWorker error'); }
  try { await closeSigningQueue(); } catch (err) { logger.warn({ err }, 'closeSigningQueue error'); }
  try { await closeRedisConnection(); } catch (err) { logger.warn({ err }, 'closeRedisConnection error'); }

  httpServer.close(() => {
    logger.info('HTTP server closed — exit 0');
    process.exit(0);
  });
  // Failsafe: force exit if close() hangs >10s
  setTimeout(() => {
    logger.error('Graceful shutdown timeout — force exit 1');
    process.exit(1);
  }, 10_000).unref();
}
process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));

export default app;
