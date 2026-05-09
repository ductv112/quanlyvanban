import { defineConfig, devices } from '@playwright/test';
import path from 'path';
import { config as dotenvConfig } from 'dotenv';

// Root package.json khong set "type": "module" -> Playwright load config qua CJS,
// __dirname co san. Khong dung import.meta.url de tranh ESM/CJS conflict.
dotenvConfig({ path: path.resolve(__dirname, '.env.test'), override: false });

const BASE_URL = process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000';

export default defineConfig({
  testDir: './tests',
  testIgnore: ['**/node_modules/**', '**/integration/**'],
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  workers: process.env.CI ? 2 : 4,
  reporter: [
    ['list'],
    ['json', { outputFile: 'tests/results/playwright-results.json' }],
    ['html', { outputFolder: 'tests/results/playwright-report', open: 'never' }],
  ],
  // globalSetup: login 5 user fixture + save tests/.auth/<role>.json (Plan 21-04)
  // CJS context (root khong "type":"module") -> dung path.resolve thay vi require.resolve
  globalSetup: path.resolve(__dirname, 'tests/globalSetup.ts'),
  globalTeardown: path.resolve(__dirname, 'tests/globalTeardown.ts'),
  use: {
    baseURL: BASE_URL,
    actionTimeout: 10000,
    navigationTimeout: 30000,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    locale: 'vi-VN',
    timezoneId: 'Asia/Ho_Chi_Minh',
  },
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],
  outputDir: 'tests/results/artifacts',
});
