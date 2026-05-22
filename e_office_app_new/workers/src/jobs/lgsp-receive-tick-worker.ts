// ============================================================
// LGSP Receive Tick Worker - Phase 35 Plan 35-02
// REQ: LGSP-RECV-01
// CONTEXT D-02 (tick spawns N receive-dn jobs), D-04 (tick concurrency=1)
//
// Handler: query lgsp_agency_config WHERE is_active=TRUE -> for each row enqueue 'receive-dn'.
// No doc work here (delegated to receive-dn). Tick failures don't retry — next scheduled
// tick covers it (D-11 — tick attempts=1).
// ============================================================
import { Queue, Worker, Job } from 'bullmq';
import IORedis from 'ioredis';
import pg from 'pg';
import pino from 'pino';
import {
  // Phase 37.4 fix #5: tach 2 queue rieng - tick listen TICK queue, enqueue child sang DN queue
  LGSP_RECEIVE_TICK_QUEUE_NAME,
  LGSP_RECEIVE_DN_QUEUE_NAME,
  LGSP_RECEIVE_TICK_JOB_NAME,
  LGSP_RECEIVE_DN_JOB_NAME,
  LGSP_RECEIVE_TICK_CONCURRENCY,
  LGSP_RECEIVE_TICK_MAX_ATTEMPTS,
  LGSP_RECEIVE_DN_MAX_ATTEMPTS,
  LGSP_RECEIVE_DN_BACKOFF_DELAY,
  type LgspReceiveTickJobData,
  type LgspReceiveDnJobData,
} from '../queues/lgsp-receive-queue.js';

const { Pool } = pg;

const logger = pino({ name: 'lgsp-receive-tick-worker' });

let connection: IORedis | null = null;
let pool: pg.Pool | null = null;
let dnQueue: Queue<LgspReceiveDnJobData> | null = null;

function getConnection(): IORedis {
  if (!connection) {
    connection = new IORedis({
      host: process.env.REDIS_HOST || 'localhost',
      port: Number(process.env.REDIS_PORT) || 6379,
      password: process.env.REDIS_PASSWORD,
      maxRetriesPerRequest: null,
    });
  }
  return connection;
}

function getPool(): pg.Pool {
  if (!pool) {
    pool = new Pool({
      host: process.env.PG_HOST || 'localhost',
      port: Number(process.env.PG_PORT) || 5432,
      database: process.env.PG_DATABASE || 'qlvb_dev',
      user: process.env.PG_USER || 'qlvb_admin',
      password: process.env.PG_PASSWORD,
      max: 2,
      idleTimeoutMillis: 30000,
    });
  }
  return pool;
}

function getDnQueue(): Queue<LgspReceiveDnJobData> {
  if (!dnQueue) {
    // Phase 37.4 fix #5: enqueue child sang DN queue rieng (truoc dung chung tick queue)
    dnQueue = new Queue<LgspReceiveDnJobData>(LGSP_RECEIVE_DN_QUEUE_NAME, {
      connection: getConnection(),
      defaultJobOptions: {
        attempts: LGSP_RECEIVE_DN_MAX_ATTEMPTS,
        backoff: { type: 'exponential', delay: LGSP_RECEIVE_DN_BACKOFF_DELAY },
        removeOnComplete: { count: 500 },
        removeOnFail: { count: 2000 },
      },
    });
  }
  return dnQueue;
}

/**
 * Tick handler: list active DNs -> enqueue 1 receive-dn job per DN.
 * Only processes jobs with `job.name === 'receive-tick'` (filters out same-queue 'receive-dn' jobs).
 */
async function handleTick(
  job: Job<LgspReceiveTickJobData>,
): Promise<{ enqueued: number; agency_count: number }> {
  if (job.name !== LGSP_RECEIVE_TICK_JOB_NAME) {
    // Same queue but different job name — let the DN worker handle it.
    return { enqueued: 0, agency_count: 0 };
  }

  const tickId = job.id ?? `tick-${Date.now()}`;
  const trigger = job.data?.trigger_source ?? 'cron';
  logger.info({ tickId, trigger }, 'LGSP receive tick: querying active agencies');

  // Query all active DNs (both env). SP from Phase 33.
  const rs = await getPool().query<{
    id: string;
    unit_id: string;
    environment: 'sandbox' | 'prod';
    system_id: string;
    base_url: string;
    last_synced_at: string | null;
  }>(`SELECT * FROM edoc.fn_lgsp_agency_config_get_all_active(NULL)`);

  const dnQ = getDnQueue();
  let enqueued = 0;
  for (const row of rs.rows) {
    const unitId = Number(row.unit_id);
    const env = row.environment;
    const jobId = `lgsp-receive-dn-${unitId}-${env}-${tickId}`;
    try {
      await dnQ.add(
        LGSP_RECEIVE_DN_JOB_NAME,
        { unit_id: unitId, environment: env },
        { jobId },
      );
      enqueued += 1;
    } catch (err) {
      logger.warn(
        { unitId, env, err: (err as Error).message },
        'Failed to enqueue receive-dn job',
      );
    }
  }

  logger.info(
    { tickId, trigger, agency_count: rs.rows.length, enqueued },
    'LGSP receive tick: fan-out complete',
  );
  return { enqueued, agency_count: rs.rows.length };
}

export function startLgspReceiveTickWorker(): Worker<LgspReceiveTickJobData> {
  // Phase 37.4 fix #5: listen TICK queue rieng (truoc share chung 'lgsp-receive' -> race)
  const worker = new Worker<LgspReceiveTickJobData>(
    LGSP_RECEIVE_TICK_QUEUE_NAME,
    async (job) => handleTick(job),
    {
      connection: getConnection(),
      concurrency: LGSP_RECEIVE_TICK_CONCURRENCY,
      autorun: true,
    },
  );

  worker.on('completed', (job, result) => {
    if (job.name === LGSP_RECEIVE_TICK_JOB_NAME) {
      logger.info({ jobId: job.id, result }, 'LGSP receive tick completed');
    }
  });
  worker.on('failed', (job, err) => {
    if (job?.name === LGSP_RECEIVE_TICK_JOB_NAME) {
      logger.error({ jobId: job?.id, err: err?.message }, 'LGSP receive tick failed');
    }
  });
  worker.on('error', (err) => {
    logger.error({ err: err.message }, 'LGSP receive tick worker error');
  });

  logger.info(
    {
      queue: LGSP_RECEIVE_TICK_QUEUE_NAME,
      concurrency: LGSP_RECEIVE_TICK_CONCURRENCY,
      maxAttempts: LGSP_RECEIVE_TICK_MAX_ATTEMPTS,
    },
    'LGSP receive tick worker started',
  );
  return worker;
}

export async function stopLgspReceiveTickWorker(
  worker: Worker<LgspReceiveTickJobData>,
): Promise<void> {
  try {
    await worker.close();
  } catch (err) {
    logger.warn({ err: (err as Error).message }, 'Error closing tick worker');
  }
  try {
    if (dnQueue) {
      await dnQueue.close();
      dnQueue = null;
    }
  } catch (err) {
    logger.warn({ err: (err as Error).message }, 'Error closing dn queue (from tick worker)');
  }
  try {
    if (pool) {
      await pool.end();
      pool = null;
    }
  } catch (err) {
    logger.warn({ err: (err as Error).message }, 'Error ending tick pool');
  }
  try {
    if (connection) {
      connection.disconnect();
      connection = null;
    }
  } catch (err) {
    logger.warn({ err: (err as Error).message }, 'Error disconnecting tick connection');
  }
}
