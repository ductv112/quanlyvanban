import pg from 'pg';

const { Pool, types } = pg;

// Override date/time parsers: return raw string from DB instead of JS Date
// This preserves the server timezone (Asia/Ho_Chi_Minh) set in PostgreSQL
// Ensures ALL date/time types return consistent string format
types.setTypeParser(1082, (val: string) => val); // DATE → "2026-04-15"
types.setTypeParser(1083, (val: string) => val); // TIME → "14:00:00"
types.setTypeParser(1114, (val: string) => val); // TIMESTAMP → "2026-04-15 11:30:00"
types.setTypeParser(1184, (val: string) => val); // TIMESTAMPTZ → "2026-04-15 11:30:00+07"

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
