/**
 * tests/helpers/db.ts — DB helpers cho integration tests
 *
 * Pattern test isolation per AUTO-09:
 *
 *   beforeEach(async () => {
 *     client = await getTestClient();
 *     await client.query('BEGIN');
 *   });
 *   afterEach(async () => {
 *     await client.query('ROLLBACK');
 *     client.release();
 *   });
 *
 * Hoặc dùng helper `withTransaction()`:
 *
 *   await withTransaction(async (client) => {
 *     // test logic — auto rollback at end (kể cả khi throw)
 *   });
 *
 * Pool config:
 * - host/port/user/password/database từ .env.test (load qua tests/setup.ts)
 * - max=10 connections (đủ cho forks pool 4 workers × 2 connections)
 * - idleTimeoutMillis=30s
 *
 * SAFETY: Pool refuses to init nếu PG_DATABASE missing 'test' substring.
 */

import { Pool, PoolClient } from 'pg';

let testPool: Pool | null = null;

export function getTestPool(): Pool {
  if (!testPool) {
    const dbName = process.env.PG_DATABASE || 'qlvb_test';

    // [TEST SAFETY] Verify pool đang trỏ test DB, KHÔNG dev/prod
    if (!dbName.includes('test')) {
      throw new Error(
        `[TEST SAFETY] Test pool đang trỏ tới '${dbName}', không có 'test' trong tên. ` +
          `Set PG_DATABASE=qlvb_test (hoặc qlvb_test_w1...) trong .env.test trước khi chạy test.`,
      );
    }

    testPool = new Pool({
      host: process.env.PG_HOST || 'localhost',
      port: Number(process.env.PG_PORT) || 5432,
      user: process.env.PG_USER || 'qlvb_admin',
      password: process.env.PG_PASSWORD || 'QlvbDev@2026',
      database: dbName,
      max: Number(process.env.PG_MAX_CONNECTIONS) || 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 5000,
      client_encoding: 'UTF8',
    });
  }
  return testPool;
}

/**
 * Acquire a single client từ test pool. Caller phải `client.release()`.
 */
export async function getTestClient(): Promise<PoolClient> {
  return await getTestPool().connect();
}

/**
 * Wrap callback trong transaction, auto ROLLBACK ở cuối (kể cả khi callback throw).
 *
 * @returns Result của callback (T)
 *
 * Usage:
 *   const userCount = await withTransaction(async (client) => {
 *     const r = await client.query('SELECT COUNT(*)::int AS n FROM public.staff');
 *     return r.rows[0].n;
 *   });
 */
export async function withTransaction<T>(
  callback: (client: PoolClient) => Promise<T>,
): Promise<T> {
  const client = await getTestClient();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    return result;
  } finally {
    try {
      await client.query('ROLLBACK');
    } catch {
      // Ignore rollback error (kết nối đã đóng / transaction đã abort)
    }
    client.release();
  }
}

/**
 * Đóng pool khi suite end. Gọi trong afterAll() cuối cùng.
 *
 * Usage trong vitest:
 *   afterAll(async () => { await closeTestPool(); });
 */
export async function closeTestPool(): Promise<void> {
  if (testPool) {
    await testPool.end();
    testPool = null;
  }
}

/**
 * Reset pool reference (chỉ dùng trong test setup khi cần re-init).
 * KHÔNG đóng pool — để caller tự handle.
 */
export function resetTestPoolRef(): void {
  testPool = null;
}
