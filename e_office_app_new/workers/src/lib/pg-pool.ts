// ============================================================
// Centralized pg pool helper - v3.2.2 fix #M10
// Truoc: 6 file worker tu tao pool rieng -> 6x connection so voi can thiet.
// Sau: 1 pool dung chung (singleton lazy init), default max=5 dung cho ca process.
//
// Worker process khoi tao 4-5 worker (send, receive-tick, receive-dn, status-tick,
// status-event). Neu moi cai tu open pool max=5 -> 25 idle conn co the giu Postgres
// dau gio cao diem. Centralize -> tong max=5 + reuse.
//
// CONFIG: PG_POOL_MAX (default 5), PG_POOL_IDLE_MS (default 30000).
// ============================================================
import pg from 'pg';

const { Pool } = pg;

let sharedPool: pg.Pool | null = null;

export function getSharedPgPool(): pg.Pool {
  if (!sharedPool) {
    sharedPool = new Pool({
      host: process.env.PG_HOST || 'localhost',
      port: Number(process.env.PG_PORT) || 5432,
      database: process.env.PG_DATABASE || 'qlvb_dev',
      user: process.env.PG_USER || 'qlvb_admin',
      password: process.env.PG_PASSWORD,
      max: Number(process.env.PG_POOL_MAX) || 5,
      idleTimeoutMillis: Number(process.env.PG_POOL_IDLE_MS) || 30_000,
    });
    sharedPool.on('error', (err) => {
      console.error('[pg-pool] unexpected error on idle client', err);
    });
  }
  return sharedPool;
}

export async function closeSharedPgPool(): Promise<void> {
  if (sharedPool) {
    try {
      await sharedPool.end();
    } catch (err) {
      console.warn('[pg-pool] error closing shared pool', (err as Error).message);
    } finally {
      sharedPool = null;
    }
  }
}
