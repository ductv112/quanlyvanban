import pg from 'pg';

const { Pool } = pg;

export const pool = new Pool({
  host: process.env.PG_HOST || 'localhost',
  port: Number(process.env.PG_PORT) || 5432,
  database: process.env.PG_DATABASE || 'qlvb_dev',
  user: process.env.PG_USER || 'qlvb_admin',
  password: process.env.PG_PASSWORD,
  max: Number(process.env.PG_MAX_CONNECTIONS) || 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});
