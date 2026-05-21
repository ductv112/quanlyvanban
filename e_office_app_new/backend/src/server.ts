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
// Phase 19 v3.0: removed import interIncomingRoutes — VB liên thông gộp vào VB đến (source_type)
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
import adminLgspRoutes from './routes/admin-lgsp.js';
import digitalSignatureRoutes from './routes/digital-signature.js';
import kySoCauHinhRoutes from './routes/ky-so-cau-hinh.js';
import kySoTaiKhoanRoutes from './routes/ky-so-tai-khoan.js';
import kySoSignRoutes from './routes/ky-so-sign.js';
import kySoDanhSachRoutes from './routes/ky-so-danh-sach.js';
import notificationRoutes from './routes/notification.js';
import bellNotificationsRoutes from './routes/notifications.js';  // Phase 13 — personal bell
import sendConfigRoutes from './routes/send-config.js';
import profileRoutes from './routes/profile.js';
import { authenticate, requireRightByPathOrNext, requireRightOrNext, requireRoles } from './middleware/auth.js';
import { initSocket } from './lib/socket.js';
import { ensureBucket } from './lib/minio/client.js';
import { startSigningWorker, stopSigningWorker } from './workers/signing-poll.worker.js';
import { closeSigningQueue } from './lib/queue/signing-queue.js';
import { closeLgspSendQueue } from './lib/queue/lgsp-send-queue.js';
import {
  registerReceiveTickRepeatJob,
  closeLgspReceiveQueue,
} from './lib/queue/lgsp-receive-queue.js';
import {
  registerStatusTickRepeatJob,
  closeLgspStatusQueue,
} from './lib/queue/lgsp-status-queue.js';
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
// BUG #41: axios.patch(url) không gửi body + Content-Type → express.json() bỏ qua
// → req.body = undefined → `const { x } = req.body` throw 500. Default về {} cho an toàn.
app.use((req, _res, next) => { if (req.body == null) req.body = {}; next(); });
app.use(cookieParser());
app.use(pinoHttp({ logger }));

// --- Routes ---
app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);

// Phase 31 fix(BUG-CATALOG-SHADOW): admin routes MUST mount BEFORE publicCatalog
// to avoid public-catalog shadowing admin endpoints (e.g. /nguoi-dung w/ is_locked filter).
// Use requireRolesOrNext so non-admin users fall THROUGH to publicCatalog (read-only picker)
// instead of getting 403. Admin users hit full admin handler.
//
// Fix 2026-05-11: wrap admin routes in sub-Router để `next('router')` thoát đúng
// sub-Router (Express semantics) thay vì thoát toàn bộ app routing -> 404 cho
// non-admin user.
//
// Fix 2026-05-11 (2): đổi từ requireRolesOrNext('Quản trị hệ thống') sang
// requireRightByPathOrNext() - check action_of_role table thay vì hardcode role
// name. Cho phép admin gán quyền granular qua UI Nhóm quyền (action_of_role).
// Ví dụ: tick "Danh mục" cho "Ban Lãnh đạo" -> Ban Lãnh đạo CRUD được Danh mục.
const adminGuard = express.Router({ mergeParams: true });
adminGuard.use(requireRightByPathOrNext(), adminRoutes);
const adminCatalogGuard = express.Router({ mergeParams: true });
adminCatalogGuard.use(requireRightByPathOrNext(), adminCatalogRoutes);

app.use('/api/quan-tri', authenticate, adminGuard);
app.use('/api/quan-tri', authenticate, adminCatalogGuard);
// Public catalog SAU — chỉ catch khi admin routes không match HOẶC user không phải admin
app.use('/api/quan-tri', authenticate, publicCatalogRoutes);

// --- Module routes ---
app.use('/api/van-ban-den', authenticate, incomingDocRoutes);
app.use('/api/van-ban-du-thao', authenticate, draftingDocRoutes);
// Phase 19 v3.0: removed /api/van-ban-lien-thong — gộp vào /api/van-ban-den với source_type
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
// Phase 37 + Phase 37.1: Admin LGSP namespace — granular permission per-route
// (admin-lgsp.ts dung requireRightOrNext(24/25/26) tuong ung Overview/Catalog/Config)
// Authenticate global, KHONG check role o day de role khac (vd: Van thu) co the cap right rieng le
app.use('/api/admin', authenticate, adminLgspRoutes);
// Phase 9: Admin config cho ký số — MUST mount BEFORE /api/ky-so generic (longer prefix wins)
// Fix 2026-05-11: dùng requireRightOrNext(20) — check right "Cấu hình ký số hệ
// thống" qua action_of_role table thay vì hardcode role name "Quản trị hệ thống"
app.use('/api/ky-so/cau-hinh', authenticate, requireRightOrNext(20), kySoCauHinhRoutes);
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

  // Phase 31 fix(BUG-F-VB-006): map multer/upload validation errors → 400
  // (fileFilter rejection cb(new Error(...)) bubbles up here as plain Error)
  const errAny = err as any;
  const msg = err.message || '';
  if (errAny?.code === 'LIMIT_FILE_SIZE') {
    res.status(400).json({ success: false, message: 'File vượt quá kích thước cho phép' });
    return;
  }
  // Multer fileFilter rejection (custom whitelist message in Vietnamese)
  if (msg.startsWith('Loại file không được phép tải lên')) {
    res.status(400).json({ success: false, message: msg });
    return;
  }
  // Generic MulterError
  if (errAny?.name === 'MulterError') {
    res.status(400).json({ success: false, message: 'Lỗi tải file: ' + msg });
    return;
  }

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

  // Phase 35 Plan 03: Register the 5-min LGSP receive cron repeat scheduler.
  // Idempotent (removes pre-existing repeat first) — safe to call on every restart.
  // Non-blocking: failure here does NOT crash server (Redis may not yet be ready);
  // manual /api/lgsp/sync-now still works because it uses the same queue.
  registerReceiveTickRepeatJob()
    .then(() => {
      // Success log emitted inside registerReceiveTickRepeatJob — no duplicate here.
    })
    .catch((err) => {
      logger.error(
        { err: err?.message ?? err },
        'Failed to register LGSP receive tick repeat job (cron will NOT fire — manual /sync-now still works)',
      );
    });

  // Phase 36 Plan 03: Register the 30s LGSP status callback tick repeat scheduler.
  // Idempotent (removes pre-existing repeat first) — safe to call on every restart.
  // Non-blocking: failure here does NOT crash server (Redis may not yet be ready);
  // outbox events accumulate until worker can consume them.
  registerStatusTickRepeatJob()
    .then(() => {
      // Success log emitted inside registerStatusTickRepeatJob — no duplicate here.
    })
    .catch((err) => {
      logger.error(
        { err: err?.message ?? err },
        'Failed to register LGSP status tick repeat job (worker cron will NOT fire — outbox events accumulate)',
      );
    });
});

// --- Graceful shutdown (Phase 11 — ensure in-flight sign jobs finish before exit) ---
let shuttingDown = false;
async function shutdown(signal: string): Promise<void> {
  if (shuttingDown) return;
  shuttingDown = true;
  logger.info({ signal }, 'Shutting down gracefully');

  try { await stopSigningWorker(); } catch (err) { logger.warn({ err }, 'stopSigningWorker error'); }
  try { await closeSigningQueue(); } catch (err) { logger.warn({ err }, 'closeSigningQueue error'); }
  try { await closeLgspSendQueue(); } catch (err) { logger.warn({ err }, 'closeLgspSendQueue error'); }
  try { await closeLgspReceiveQueue(); } catch (err) { logger.warn({ err }, 'closeLgspReceiveQueue error'); }
  try { await closeLgspStatusQueue(); } catch (err) { logger.warn({ err }, 'closeLgspStatusQueue error'); }  // Phase 36
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
