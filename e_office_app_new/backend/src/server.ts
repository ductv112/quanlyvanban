import 'dotenv/config';
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
import { authenticate } from './middleware/auth.js';

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

// --- TODO: Module routes sẽ được thêm sau ---
// app.use('/api/van-ban/den', incomingDocRoutes);
// app.use('/api/van-ban/di', outgoingDocRoutes);
// app.use('/api/ho-so-cong-viec', handlingDocRoutes);

// --- Error handler ---
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error(err);
  res.status(500).json({ success: false, message: err.message || 'Internal Server Error' });
});

// --- Start ---
app.listen(port, () => {
  logger.info(`🚀 QLVB Backend running at http://localhost:${port}`);
  logger.info(`📋 Health check: http://localhost:${port}/api/health`);
});

export default app;
