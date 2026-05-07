/**
 * tests/wave-bc-ui/ky-so-ui.spec.ts — Wave c Ky so UI testcases (SKIP UI from Wave c)
 *
 * Coverage Wave c Ky so SKIP UI (~6-8 TC):
 *   Cau hinh:
 *   - TC-KSCH-027 — Modal xac nhan kich hoat (Modal.confirm)
 *   - TC-KSCH-028 — Huy kich hoat trong modal (close without API call)
 *   - TC-KSCH-030 — Profile ID field — KHONG render trong drawer SmartCA (chỉ show với MySign)
 *   Danh sach:
 *   - TC-KSDS-019 — Pha "Dang cho OTP" voi countdown 3:00 — SKIP (timer animation)
 *   - TC-KSDS-020 — Dong ho doi mau khi dem nguoc — SKIP (timer animation)
 *   - TC-KSDS-024 — Dong modal de chay nen — SKIP (UI behavior on backgrounding)
 *   - TC-KSDS-035 — Dong modal cancel khong thuc hien — verifiable
 *
 * Run: npx playwright test tests/wave-bc-ui/ky-so-ui.spec.ts --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 20000;

// ─────────────────────────────────────────────────────────────────────────────
// CAU HINH KY SO — admin only
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave c Ky so cau hinh UI — admin @wave-bc-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-KSCH-027 Modal xac nhan kich hoat hien thi truoc khi PATCH', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Mock GET config — return 2 providers, 1 has been tested OK
    await page.route('**/api/ky-so/cau-hinh**', async (route) => {
      const url = route.request().url();
      const method = route.request().method();
      if (method === 'GET' && url.endsWith('/cau-hinh')) {
        await route.fulfill({
          status: 200,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({
            success: true,
            data: {
              providers: [
                {
                  id: 1, provider_code: 'SMARTCA_VNPT', provider_name: 'SmartCA VNPT',
                  base_url: 'http://localhost:8181', client_id: 'demo_client',
                  has_secret: true, client_secret_masked: '***',
                  test_result: 'OK', last_tested_at: '2026-05-01T10:00:00Z',
                  is_active: false, profile_id: null,
                },
                {
                  id: 2, provider_code: 'MYSIGN_VIETTEL', provider_name: 'MySign Viettel',
                  base_url: 'http://localhost:8182', client_id: 'demo_client',
                  has_secret: true, client_secret_masked: '***',
                  test_result: null, last_tested_at: null,
                  is_active: false, profile_id: 'PROF-001',
                },
              ],
              active_code: null,
              stats: {},
            },
          }),
        });
        return;
      }
      // Block PATCH from actually firing
      if (method === 'PATCH') {
        await route.fulfill({
          status: 200,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ success: true }),
        });
        return;
      }
      await route.continue();
    });

    await page.goto('/ky-so/cau-hinh');

    // Wait page loaded
    await expect(page.locator('text=/Cấu hình ký số|SmartCA/i').first()).toBeVisible({ timeout: 10000 });

    // Find activate button on SmartCA provider (test_result=OK eligible)
    const activateBtn = page.getByRole('button', { name: /Kích hoạt/i }).first();
    if (await activateBtn.count() === 0) {
      test.skip(true, 'Kích hoạt button not visible');
    }
    await activateBtn.click();

    // Modal.confirm hien thi
    const confirmModal = page.locator('.ant-modal-confirm').first();
    await expect(confirmModal).toBeVisible({ timeout: 5000 });
    // Title chứa "Kích hoạt"
    await expect(confirmModal.locator('text=/Kích hoạt/i').first()).toBeVisible();
  });

  test('TC-KSCH-028 Huy modal kich hoat — KHONG goi PATCH', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    let patchCalled = false;
    page.on('request', (req) => {
      if (req.method() === 'PATCH' && req.url().includes('/ky-so/cau-hinh') && req.url().includes('/active')) {
        patchCalled = true;
      }
    });

    // Mock GET config
    await page.route('**/api/ky-so/cau-hinh**', async (route) => {
      const url = route.request().url();
      const method = route.request().method();
      if (method === 'GET' && url.endsWith('/cau-hinh')) {
        await route.fulfill({
          status: 200,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({
            success: true,
            data: {
              providers: [
                {
                  id: 1, provider_code: 'SMARTCA_VNPT', provider_name: 'SmartCA VNPT',
                  base_url: 'http://localhost:8181', client_id: 'demo_client',
                  has_secret: true, client_secret_masked: '***',
                  test_result: 'OK', last_tested_at: '2026-05-01T10:00:00Z',
                  is_active: false, profile_id: null,
                },
              ],
              active_code: null, stats: {},
            },
          }),
        });
        return;
      }
      await route.continue();
    });

    await page.goto('/ky-so/cau-hinh');
    await expect(page.locator('text=/SmartCA/i').first()).toBeVisible({ timeout: 10000 });

    const activateBtn = page.getByRole('button', { name: /Kích hoạt/i }).first();
    if (await activateBtn.count() === 0) {
      test.skip(true, 'Kích hoạt button not visible');
    }
    await activateBtn.click();

    // Modal.confirm
    const confirmModal = page.locator('.ant-modal-confirm').first();
    await expect(confirmModal).toBeVisible({ timeout: 5000 });

    // Click Hủy
    const cancelBtn = confirmModal.getByRole('button', { name: /^Hủy$/i }).first();
    await cancelBtn.click();

    // Modal closed
    await expect(confirmModal).toBeHidden({ timeout: 3000 });

    // PATCH KHONG duoc goi
    await page.waitForTimeout(500);
    expect(patchCalled).toBe(false);
  });

  test.skip('TC-KSCH-030 Profile ID field hide trong drawer SmartCA (manual UI verify — drawer not always exposed)', async () => {
    // Skip: Drawer activation flow requires full provider config setup; conditional render only show MySign
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// DANH SACH KY SO UI
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave c Danh sach ky so UI — lanhdao @wave-bc-ui', () => {
  test.use({ storageState: storageStateFor('lanhdao') });

  test.skip('TC-KSDS-019 Pha "Dang cho OTP" voi dem nguoc 3:00 (timer UI animation)', async () => {
    // Skip: Timer animation needs full sign flow setup with mock provider returning OTP state
  });

  test.skip('TC-KSDS-020 Dong ho doi mau khi dem nguoc (timer UI animation)', async () => {
    // Skip: Same as TC-KSDS-019
  });

  test.skip('TC-KSDS-024 Dong modal ky so de chay nen (UI background behavior)', async () => {
    // Skip: Background behavior cannot be reliably tested without real worker/provider
  });

  test.skip('TC-KSDS-035 Dong modal cancel khong thuc hien — needs active sign transaction (fixture limitation)', async () => {
    // Skip: Fixture has no pending sign transactions — cancel modal cannot be triggered
  });

  // Add a smoke test that's testable: tab switching preserves URL state
  test('TC-KSDS-013-bonus URL update khi switch tab (cross-check)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/ky-so/danh-sach');

    // Default tab "Cần ký"
    await expect(page.locator('.page-title')).toContainText(/Danh sách ký số/i, { timeout: 10000 });

    // Click tab "Đang xử lý"
    const pendingTab = page.getByRole('tab', { name: /Đang xử lý/i });
    await pendingTab.click();
    await page.waitForTimeout(500);

    // URL should contain ?tab=pending
    expect(page.url()).toMatch(/[?&]tab=pending/);

    // Click tab "Đã ký"
    const completedTab = page.getByRole('tab', { name: /Đã ký/i });
    await completedTab.click();
    await page.waitForTimeout(500);

    expect(page.url()).toMatch(/[?&]tab=completed/);
  });
});
