#!/usr/bin/env tsx
/**
 * test-db-reset.ts — Reset qlvb_test DB cho automation testing
 *
 * Flow (target < 30s):
 *   1. Ket noi postgres database (system DB) — KHONG ket noi truc tiep qlvb_test
 *   2. DROP DATABASE qlvb_test (force disconnect moi session)
 *   3. CREATE DATABASE qlvb_test
 *   4. Apply 4 file SQL tuan tu:
 *      - database/init/01_create_schemas.sql
 *      - database/schema/000_schema_v3.0.sql (master, idempotent)
 *      - database/seed/001_required_data.sql (admin + roles + signing config)
 *      - database/seed/003_test_fixtures.sql (5 user + 16 fixture)
 *   5. Verify: SELECT COUNT(*) FROM staff WHERE id IN (9001..9099)
 *
 * Usage:
 *   npm run test:db:reset
 *   tsx tools/test-db-reset.ts
 *
 * Env (doc tu .env.test override .env):
 *   PG_HOST, PG_PORT, PG_USER, PG_PASSWORD
 *   PG_DATABASE (must contain 'test')
 *   SIGNING_SECRET_KEY (>= 16 chars, default: qlvb-test-signing-key-32chars-fixed-for-deterministic-tests)
 */

import { Client } from 'pg';
import { execFileSync, execSync } from 'child_process';
import { config as dotenvConfig } from 'dotenv';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

// Resolve __dirname in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load .env.test override .env
dotenvConfig({ path: path.resolve(process.cwd(), '.env.test'), override: true });
dotenvConfig({ path: path.resolve(process.cwd(), '.env'), override: false });

const PG_HOST = process.env.PG_HOST || 'localhost';
const PG_PORT = Number(process.env.PG_PORT) || 5432;
const PG_USER = process.env.PG_USER || 'qlvb_admin';
const PG_PASSWORD = process.env.PG_PASSWORD || 'QlvbDev@2026';
const PG_DATABASE = process.env.PG_DATABASE || 'qlvb_test';
const SIGNING_SECRET_KEY =
  process.env.SIGNING_SECRET_KEY ||
  'qlvb-test-signing-key-32chars-fixed-for-deterministic-tests';
const APP_ENV = process.env.APP_ENV || 'test';

// SAFETY: chan reset DB khong co 'test' trong ten
if (!PG_DATABASE.includes('test')) {
  console.error(
    `[SAFETY] PG_DATABASE='${PG_DATABASE}' khong chua 'test'. test-db-reset.ts chi reset DB co 'test' trong ten (vi du qlvb_test).`,
  );
  process.exit(1);
}

// Resolve repo root: backend/tools → backend → e_office_app_new → ROOT
const REPO_ROOT = path.resolve(__dirname, '..', '..', '..');
const DB_DIR = path.join(REPO_ROOT, 'e_office_app_new', 'database');
const SQL_FILES = [
  path.join(DB_DIR, 'init', '01_create_schemas.sql'),
  path.join(DB_DIR, 'schema', '000_schema_v3.0.sql'),
  path.join(DB_DIR, 'seed', '001_required_data.sql'),
  path.join(DB_DIR, 'seed', '003_test_fixtures.sql'),
];

// SQL prepended TRUOC khi apply tung file (truyen qua psql -c)
function prelude(file: string): string {
  if (file.endsWith('001_required_data.sql')) {
    return `SET app.signing_secret_key='${SIGNING_SECRET_KEY}';`;
  }
  if (file.endsWith('003_test_fixtures.sql')) {
    return `SET app.environment='${APP_ENV}';`;
  }
  return '';
}

// Auto-detect Docker container chay psql
// Priority order:
//   1. PG_DOCKER_CONTAINER env set -> docker mode (explicit, fastest)
//   2. USE_DOCKER_PSQL=true env -> force docker mode (default container name)
//   3. Linux + /var/run/docker.sock exists -> docker mode (legacy auto-detect)
//   4. Windows + container 'qlvb_postgres' running -> docker mode (Windows fallback)
//   5. Otherwise -> direct psql CLI
function detectDockerMode(): { useDocker: boolean; container: string } {
  const explicitContainer = process.env.PG_DOCKER_CONTAINER;
  if (explicitContainer) {
    return { useDocker: true, container: explicitContainer };
  }
  if (process.env.USE_DOCKER_PSQL === 'true') {
    return { useDocker: true, container: 'qlvb_postgres' };
  }
  // Linux: check unix socket
  if (process.platform !== 'win32' && fs.existsSync('/var/run/docker.sock')) {
    return { useDocker: true, container: 'qlvb_postgres' };
  }
  // Windows: probe `docker ps` for qlvb_postgres container
  if (process.platform === 'win32') {
    try {
      const out = execSync('docker ps -q -f name=qlvb_postgres', {
        stdio: ['ignore', 'pipe', 'pipe'],
        encoding: 'utf-8',
        timeout: 5000,
      });
      if (out.trim().length > 0) {
        console.log(
          '[test-db-reset] Auto-detected Docker container qlvb_postgres on Windows',
        );
        return { useDocker: true, container: 'qlvb_postgres' };
      }
    } catch {
      // docker CLI not in PATH or daemon down -> fallback to direct psql
    }
  }
  return { useDocker: false, container: 'qlvb_postgres' };
}

async function main(): Promise<void> {
  const start = Date.now();
  console.log(`[test-db-reset] Target DB: ${PG_DATABASE}@${PG_HOST}:${PG_PORT}`);

  // 1. Verify SQL files ton tai
  for (const f of SQL_FILES) {
    if (!fs.existsSync(f)) {
      throw new Error(`SQL file not found: ${f}`);
    }
  }

  // 2. Connect to system DB (postgres) de DROP/CREATE qlvb_test
  const sysClient = new Client({
    host: PG_HOST,
    port: PG_PORT,
    user: PG_USER,
    password: PG_PASSWORD,
    database: 'postgres',
  });
  await sysClient.connect();

  try {
    console.log(
      `[test-db-reset] Force disconnect + DROP DATABASE IF EXISTS ${PG_DATABASE}...`,
    );
    await sysClient.query(
      `SELECT pg_terminate_backend(pid) FROM pg_stat_activity
       WHERE datname = $1 AND pid <> pg_backend_pid()`,
      [PG_DATABASE],
    );
    await sysClient.query(`DROP DATABASE IF EXISTS ${PG_DATABASE}`);

    console.log(`[test-db-reset] CREATE DATABASE ${PG_DATABASE}...`);
    await sysClient.query(
      `CREATE DATABASE ${PG_DATABASE} WITH ENCODING='UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE template0`,
    );
  } finally {
    await sysClient.end();
  }

  // 3. Apply 4 SQL files via psql CLI (faster than pg lib for big schema files)
  // Auto-detect psql trong docker hoac local
  // Priority order:
  //   1. PG_DOCKER_CONTAINER env set -> docker mode (explicit, fastest)
  //   2. USE_DOCKER_PSQL=true env -> force docker mode (default container name)
  //   3. Linux + /var/run/docker.sock exists -> docker mode (legacy auto-detect)
  //   4. Windows + container 'qlvb_postgres' running -> docker mode (Windows fallback)
  //   5. Otherwise -> direct psql CLI
  const { useDocker, container: dockerContainer } = detectDockerMode();

  for (const sqlFile of SQL_FILES) {
    const fileName = path.basename(sqlFile);
    const t0 = Date.now();
    console.log(`[test-db-reset] Applying ${fileName}...`);

    const sqlContent = fs.readFileSync(sqlFile, 'utf-8');
    const fullSql = (prelude(sqlFile) ? prelude(sqlFile) + '\n' : '') + sqlContent;

    try {
      if (useDocker) {
        // Docker exec mode
        execFileSync(
          'docker',
          [
            'exec',
            '-i',
            dockerContainer,
            'psql',
            '-U',
            PG_USER,
            '-d',
            PG_DATABASE,
            '-v',
            'ON_ERROR_STOP=1',
            '-q',
          ],
          {
            input: fullSql,
            env: { ...process.env, PGPASSWORD: PG_PASSWORD },
            stdio: ['pipe', 'pipe', 'pipe'],
          },
        );
      } else {
        // Direct psql CLI mode
        execFileSync(
          'psql',
          [
            '-h',
            PG_HOST,
            '-p',
            String(PG_PORT),
            '-U',
            PG_USER,
            '-d',
            PG_DATABASE,
            '-v',
            'ON_ERROR_STOP=1',
            '-q',
          ],
          {
            input: fullSql,
            env: { ...process.env, PGPASSWORD: PG_PASSWORD },
            stdio: ['pipe', 'pipe', 'pipe'],
          },
        );
      }
      console.log(
        `[test-db-reset]   ${fileName} OK (${Date.now() - t0}ms)`,
      );
    } catch (e) {
      const err = e as { stderr?: Buffer; stdout?: Buffer; message?: string };
      console.error(`[test-db-reset]   FAILED: ${fileName}`);
      if (err.stderr) console.error(err.stderr.toString());
      if (err.stdout) console.error(err.stdout.toString());
      if (err.message) console.error(err.message);
      throw e;
    }
  }

  // 4. Verify fixtures
  const verifyClient = new Client({
    host: PG_HOST,
    port: PG_PORT,
    user: PG_USER,
    password: PG_PASSWORD,
    database: PG_DATABASE,
  });
  await verifyClient.connect();
  try {
    const r1 = await verifyClient.query(
      `SELECT COUNT(*)::int AS n FROM public.staff WHERE id BETWEEN 9001 AND 9099`,
    );
    const r2 = await verifyClient.query(
      `SELECT COUNT(*)::int AS n FROM edoc.incoming_docs WHERE id BETWEEN 90001 AND 90005`,
    );
    const r3 = await verifyClient.query(
      `SELECT COUNT(*)::int AS n FROM public.role_of_staff WHERE staff_id BETWEEN 9001 AND 9099`,
    );

    const staffCount = r1.rows[0].n as number;
    const incomingCount = r2.rows[0].n as number;
    const roleCount = r3.rows[0].n as number;

    console.log(
      `[test-db-reset] VERIFY: staff=${staffCount} (expect 6) | incoming_docs=${incomingCount} (expect 5) | role_of_staff=${roleCount} (expect 6)`,
    );

    if (staffCount < 6 || incomingCount < 5 || roleCount < 6) {
      throw new Error(
        `Verify failed — staff=${staffCount}/6 incoming=${incomingCount}/5 roles=${roleCount}/6`,
      );
    }
  } finally {
    await verifyClient.end();
  }

  const elapsed = Date.now() - start;
  console.log(`[test-db-reset] DONE in ${elapsed}ms (target < 30000ms)`);
  if (elapsed > 30000) {
    console.warn(
      `[test-db-reset] WARNING: vuot 30s target (AUTO-02 acceptance criteria)`,
    );
  }
}

main().catch((err) => {
  console.error('[test-db-reset] FATAL:', err.message || err);
  process.exit(1);
});
