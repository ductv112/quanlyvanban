/**
 * ioredis connection factory for BullMQ Queue + Worker (Phase 11+ sign flow).
 *
 * CRITICAL (BullMQ requirement): `maxRetriesPerRequest: null` — without it
 * BullMQ throws when the connection drops during a blocking command (BLPOP)
 * and the worker dies. Same applies to `enableReadyCheck: false`.
 *
 * Design:
 *   - Queue (producer) reuses a shared singleton via `getRedisConnection()`.
 *   - Worker (consumer) must call `createRedisConnection()` to get its OWN
 *     connection — Worker issues BLPOP which blocks the connection. Sharing
 *     would starve the producer.
 *
 * Config priority:
 *   1. REDIS_URL (redis://[:password@]host:port[/db]) — preferred for prod
 *   2. REDIS_HOST + REDIS_PORT + REDIS_PASSWORD — legacy / dev
 */

import IORedis from 'ioredis';
import type { Redis } from 'ioredis';
import pino from 'pino';

const logger = pino({ name: 'redis-connection' });

let defaultConnection: Redis | null = null;

interface RedisCfg {
  host: string;
  port: number;
  password?: string;
}

function parseRedisUrl(): RedisCfg {
  const url = process.env.REDIS_URL;
  if (url) {
    try {
      const u = new URL(url);
      return {
        host: u.hostname,
        port: u.port ? Number(u.port) : 6379,
        password: u.password ? decodeURIComponent(u.password) : undefined,
      };
    } catch (err) {
      logger.warn({ err, REDIS_URL: url }, 'Invalid REDIS_URL — fallback to REDIS_HOST');
    }
  }
  return {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT ? Number(process.env.REDIS_PORT) : 6379,
    password: process.env.REDIS_PASSWORD || undefined,
  };
}

/**
 * Get/reuse the default Redis connection for Queue (producer side).
 * Safe to call repeatedly — returns the same Redis instance.
 *
 * For Worker use, call `createRedisConnection()` to get a fresh one
 * (blocking BLPOP inside Worker requires an exclusive connection).
 */
export function getRedisConnection(): Redis {
  if (defaultConnection && defaultConnection.status !== 'end') {
    return defaultConnection;
  }
  const cfg = parseRedisUrl();
  defaultConnection = new IORedis({
    host: cfg.host,
    port: cfg.port,
    password: cfg.password,
    maxRetriesPerRequest: null,
    enableReadyCheck: false,
    lazyConnect: false,
  });

  defaultConnection.on('error', (err) => {
    logger.error({ err: err.message }, 'Redis (queue) connection error');
  });

  return defaultConnection;
}

/**
 * Create a NEW Redis connection (for Worker — do NOT share with Queue).
 * Caller owns the lifecycle (typically BullMQ Worker will close it on shutdown).
 */
export function createRedisConnection(): Redis {
  const cfg = parseRedisUrl();
  const conn = new IORedis({
    host: cfg.host,
    port: cfg.port,
    password: cfg.password,
    maxRetriesPerRequest: null,
    enableReadyCheck: false,
  });

  conn.on('error', (err) => {
    logger.error({ err: err.message }, 'Redis (worker) connection error');
  });

  return conn;
}

/**
 * Graceful shutdown helper — call from SIGTERM handler in server.ts.
 * Worker connections should be closed by Worker.close() separately.
 */
export async function closeRedisConnection(): Promise<void> {
  if (defaultConnection) {
    try {
      await defaultConnection.quit();
    } catch (err) {
      logger.warn({ err }, 'Error during Redis quit — forcing disconnect');
      defaultConnection.disconnect();
    }
    defaultConnection = null;
  }
}
