import 'dotenv/config';
import { config as dotenvConfig } from 'dotenv';
import path from 'path';

// Load .env.test override .env neu co
dotenvConfig({ path: path.resolve(process.cwd(), '.env.test'), override: true });

// Verify dang dung test DB, KHONG dung dev DB
const dbName = process.env.PG_DATABASE;
if (!dbName || !dbName.includes('test')) {
  throw new Error(
    `[TEST SAFETY] PG_DATABASE='${dbName}' khong chua 'test'. Test stack chi chay tren DB co 'test' trong ten (qlvb_test, qlvb_test_w1...). Tao .env.test voi PG_DATABASE=qlvb_test.`
  );
}

// Verify NODE_ENV=test
if (process.env.NODE_ENV !== 'test') {
  process.env.NODE_ENV = 'test';
}
