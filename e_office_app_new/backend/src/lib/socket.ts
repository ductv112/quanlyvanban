import { Server as SocketIOServer } from 'socket.io';
import type { Server as HTTPServer } from 'http';
import pino from 'pino';
import { verifyToken } from './auth/jwt.js';

const logger = pino({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  transport: process.env.NODE_ENV !== 'production' ? { target: 'pino-pretty' } : undefined,
});

// ============================================================
// Socket event constants
// ============================================================

export const SOCKET_EVENTS = {
  NEW_DOCUMENT: 'new_document',
  NEW_MESSAGE: 'new_message',
  NEW_NOTIFICATION: 'new_notification',
  DOC_STATUS_CHANGED: 'doc_status_changed',
} as const;

// ============================================================
// Module-level singleton
// ============================================================

let io: SocketIOServer | null = null;

// ============================================================
// initSocket — attach Socket.IO to existing HTTP server
// ============================================================

export function initSocket(httpServer: HTTPServer): SocketIOServer {
  io = new SocketIOServer(httpServer, {
    cors: {
      origin: process.env.CORS_ORIGIN || 'http://localhost:3000',
      credentials: true,
    },
  });

  // JWT authentication middleware (T-03-08 mitigation)
  io.use(async (socket, next) => {
    try {
      // Accept token from handshake.auth.token or Authorization header
      let token: string | undefined =
        socket.handshake.auth?.token as string | undefined;

      if (!token) {
        const authHeader = socket.handshake.headers?.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
          token = authHeader.slice(7);
        }
      }

      if (!token) {
        return next(new Error('Authentication error'));
      }

      const payload = await verifyToken(token);
      socket.data.user = payload;
      next();
    } catch {
      next(new Error('Authentication error'));
    }
  });

  // Connection handler
  io.on('connection', (socket) => {
    const user = socket.data.user;
    const room = `user_${user.staffId}`;

    // Join personal room so we can target this user
    socket.join(room);
    logger.debug({ staffId: user.staffId, socketId: socket.id }, 'Socket connected');

    socket.on('disconnect', (reason) => {
      logger.debug({ staffId: user.staffId, socketId: socket.id, reason }, 'Socket disconnected');
    });
  });

  // Expose on globalThis for lazy use in route files (avoids circular import)
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  (globalThis as any).__socketModule = { emitToUsers, emitToUser };

  logger.info('Socket.IO server initialized');
  return io;
}

// ============================================================
// getIO — returns the initialized Socket.IO server
// ============================================================

export function getIO(): SocketIOServer {
  if (!io) {
    throw new Error('Socket.IO server not initialized. Call initSocket() first.');
  }
  return io;
}

// ============================================================
// Convenience helpers
// ============================================================

export function emitToUser(staffId: number, event: string, data: unknown): void {
  try {
    getIO().to(`user_${staffId}`).emit(event, data);
  } catch {
    // Silently fail — socket errors must not break API
  }
}

export function emitToUsers(staffIds: number[], event: string, data: unknown): void {
  try {
    const ioInstance = getIO();
    for (const staffId of staffIds) {
      ioInstance.to(`user_${staffId}`).emit(event, data);
    }
  } catch {
    // Silently fail — socket errors must not break API
  }
}
