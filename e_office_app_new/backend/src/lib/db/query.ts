import { pool } from './pool.js';
import type { QueryResultRow, PoolClient } from 'pg';

export async function callFunction<T extends QueryResultRow>(
  functionName: string,
  params: unknown[] = []
): Promise<T[]> {
  const placeholders = params.map((_, i) => `$${i + 1}`).join(', ');
  const sql = `SELECT * FROM ${functionName}(${placeholders})`;
  const result = await pool.query<T>(sql, params);
  return result.rows;
}

export async function callFunctionOne<T extends QueryResultRow>(
  functionName: string,
  params: unknown[] = []
): Promise<T | null> {
  const rows = await callFunction<T>(functionName, params);
  return rows[0] ?? null;
}

export async function callProcedure(
  procedureName: string,
  params: unknown[] = []
): Promise<void> {
  const placeholders = params.map((_, i) => `$${i + 1}`).join(', ');
  await pool.query(`CALL ${procedureName}(${placeholders})`, params);
}

export async function rawQuery<T extends QueryResultRow>(
  sql: string,
  params: unknown[] = []
): Promise<T[]> {
  const result = await pool.query<T>(sql, params);
  return result.rows;
}

export async function withTransaction<T>(
  callback: (client: PoolClient) => Promise<T>
): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await callback(client);
    await client.query('COMMIT');
    return result;
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

export interface PaginatedResult<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  totalPages: number;
}
