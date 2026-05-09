/**
 * tests/globalTeardown.ts — Playwright global teardown
 *
 * Chay 1 lan sau toan bo E2E suite. Currently no-op stub.
 *
 * Future enhancements (deferred to Phase 22+):
 *   - Cleanup test DB (drop qlvb_test_w1, qlvb_test_w2... per-worker DBs)
 *   - Stop mock servers neu start trong globalSetup (currently start rieng qua tools/mocks/start.ts)
 *   - Aggregate test results to json + commit
 *   - Cleanup tests/.auth/*.json (currently giu lai de re-use giua local runs - .gitignored)
 *
 * Note: storage state files trong tests/.auth/ duoc giu lai sau teardown
 * de re-run nhanh (skip globalSetup neu file fresh) - future optimization.
 */

import type { FullConfig } from '@playwright/test';

export default async function globalTeardown(_config: FullConfig): Promise<void> {
  // eslint-disable-next-line no-console
  console.log('[globalTeardown] DONE (no-op)');
}
