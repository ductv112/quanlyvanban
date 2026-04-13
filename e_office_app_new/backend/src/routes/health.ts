import { Router } from 'express';
import { pool } from '../lib/db/pool.js';
import { redis } from '../lib/redis/client.js';
import { minioClient } from '../lib/minio/client.js';

const router = Router();

router.get('/', async (_req, res) => {
  const checks: Record<string, unknown> = {};

  // PostgreSQL
  try {
    const start = Date.now();
    const result = await pool.query('SELECT current_database() as db, NOW() as time');
    checks.postgresql = { status: 'connected', latency: Date.now() - start, ...result.rows[0] };
  } catch (e) {
    checks.postgresql = { status: 'error', error: (e as Error).message };
  }

  // Schemas
  try {
    const schemas = await pool.query(
      "SELECT schema_name FROM information_schema.schemata WHERE schema_name IN ('edoc','esto','cont','iso','public') ORDER BY schema_name"
    );
    checks.schemas = { status: 'ok', list: schemas.rows.map(r => r.schema_name) };
  } catch (e) {
    checks.schemas = { status: 'error', error: (e as Error).message };
  }

  // Redis
  try {
    const start = Date.now();
    const pong = await redis.ping();
    checks.redis = { status: pong === 'PONG' ? 'connected' : 'error', latency: Date.now() - start };
  } catch (e) {
    checks.redis = { status: 'error', error: (e as Error).message };
  }

  // MinIO
  try {
    const start = Date.now();
    const buckets = await minioClient.listBuckets();
    checks.minio = { status: 'connected', latency: Date.now() - start, buckets: buckets.map(b => b.name) };
  } catch (e) {
    checks.minio = { status: 'error', error: (e as Error).message };
  }

  const allHealthy = Object.values(checks).every((c: any) => c.status !== 'error');

  res.status(allHealthy ? 200 : 503).json({
    success: allHealthy,
    app: 'QLVB Backend',
    environment: process.env.NODE_ENV,
    timestamp: new Date().toISOString(),
    services: checks,
  });
});

export default router;
