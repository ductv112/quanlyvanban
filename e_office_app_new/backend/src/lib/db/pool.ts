import pg from 'pg';

const { Pool, types } = pg;

// Override timestamp parsers: return raw string from DB instead of JS Date
// This preserves the server timezone (Asia/Ho_Chi_Minh) set in PostgreSQL
// OID 1114 = TIMESTAMP, OID 1184 = TIMESTAMPTZ
types.setTypeParser(1114, (val: string) => val); // timestamp without tz
types.setTypeParser(1184, (val: string) => val); // timestamp with tz

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
