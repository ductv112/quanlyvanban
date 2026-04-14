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
import { authenticate } from './middleware/auth.js';
import { initSocket } from './lib/socket.js';

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

app.use('/api/quan-tri', authenticate, adminRoutes);
app.use('/api/quan-tri', authenticate, adminCatalogRoutes);

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
app.use('/api/lich', authenticate, calendarRoutes);
app.use('/api/danh-ba', authenticate, directoryRoutes);
app.use('/api/dashboard', authenticate, dashboardRoutes);

// --- Phase 5: Kho luu tru, Tai lieu, Hop dong, Cuoc hop ---
app.use('/api/kho-luu-tru', authenticate, archiveRoutes);
app.use('/api/tai-lieu', authenticate, documentRoutes);
app.use('/api/hop-dong', authenticate, contractRoutes);
app.use('/api/cuoc-hop', authenticate, meetingRoutes);

// --- Phase 6: Tich hop he thong ngoai ---
app.use('/api/lgsp', authenticate, lgspRoutes);

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
httpServer.listen(port, () => {
  logger.info(`QLVB Backend running at http://localhost:${port}`);
  logger.info(`Health check: http://localhost:${port}/api/health`);
});

export default app;
