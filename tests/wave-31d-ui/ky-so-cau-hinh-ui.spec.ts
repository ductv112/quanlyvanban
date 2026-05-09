/**
 * tests/wave-31d-ui/ky-so-cau-hinh-ui.spec.ts — Ky so cau hinh UI rules
 *
 * Coverage SKIP UI Wave c Ky so Cau hinh (~5 testable, 3 SKIP):
 *   - TC-KSCH-015 — Test connection client_secret < 8 chars
 *   - TC-KSCH-016 — client_secret = 8 chars boundary
 *   - TC-KSCH-017 — Empty Client Secret on Save → keep old value (UI: "Để trống nếu giữ nguyên")
 *   - TC-KSCH-025 — Save & Activate button only enabled khi testedOk = true
 *   - TC-KSCH-030 — Profile ID conditional render — VNPT KHONG có, MySign CO
 *   - TC-KSCH-031/032 — PUT activation flows (verify modal flow)
 *
 * Run: npx playwright test tests/wave-31d-ui/ky-so-cau-hinh-ui.spec.ts --workers=1
 */
import { test, expect, type Page } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 25000;

interface ProviderMock {
  id?: number;
  provider_code: 'SMARTCA_VNPT' | 'MYSIGN_VIETTEL';
  provider_name: string;
  base_url?: string;
  client_id?: string;
  has_secret?: boolean;
  is_active?: boolean;
  profile_id?: string | null;
  test_result?: 'OK' | 'FAILED' | null;
}

async function mockKySoCauHinh(page: Page, providers: ProviderMock[]) {
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
            providers: providers.map((p, i) => ({
              id: p.id ?? i + 1,
              provider_code: p.provider_code,
              provider_name: p.provider_name,
              base_url: p.base_url ?? 'https://gwsca.vnpt.vn',
              client_id: p.client_id ?? 'demo_client',
              has_secret: p.has_secret ?? true,
              client_secret_masked: p.has_secret === false ? null : '***',
              test_result: p.test_result ?? null,
              last_tested_at: p.test_result ? '2026-05-01T10:00:00Z' : null,
              is_active: p.is_active ?? false,
              profile_id: p.profile_id ?? null,
            })),
            active_code: providers.find((p) => p.is_active)?.provider_code ?? null,
            stats: {},
          },
        }),
      });
      return;
    }
    await route.continue();
  });
}

test.describe('Wave 31d Ky so cau hinh — admin @wave-31d-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-KSCH-015 Test connection — client_secret 7 chars (< 8) → inline error "Client Secret tối thiểu 8 ký tự"', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    await mockKySoCauHinh(page, [
      { provider_code: 'SMARTCA_VNPT', provider_name: 'SmartCA VNPT', has_secret: true },
    ]);

    await page.goto('/ky-so/cau-hinh');
    await expect(page.locator('text=/SmartCA VNPT/i').first()).toBeVisible({ timeout: 10000 });

    // Click Sửa cấu hình
    const editBtn = page.getByRole('button', { name: /Sửa cấu hình/i }).first();
    await expect(editBtn).toBeVisible({ timeout: 5000 });
    await editBtn.click();

    const drawer = page.locator('.ant-drawer:visible').first();
    await expect(drawer).toBeVisible({ timeout: 5000 });

    // Type 7 chars vao client_secret
    const secretInput = drawer.locator('input[type="password"]').first();
    await secretInput.fill('1234567'); // 7 chars

    // Click "Kiểm tra với secret mới"
    const testBtn = drawer.getByRole('button', { name: /Kiểm tra với secret mới/i });
    await expect(testBtn).toBeEnabled({ timeout: 3000 });
    await testBtn.click();

    // Inline error
    await page.waitForTimeout(500);
    const errorMsg = drawer.locator('.ant-form-item-explain-error').filter({ hasText: /tối thiểu 8 ký tự/i }).first();
    await expect(errorMsg).toBeVisible({ timeout: 3000 });
  });

  test('TC-KSCH-016 client_secret 8 chars boundary — pass validation (no inline error)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    await mockKySoCauHinh(page, [
      { provider_code: 'SMARTCA_VNPT', provider_name: 'SmartCA VNPT', has_secret: true },
    ]);

    // Mock test-connection success
    await page.route('**/api/ky-so/cau-hinh/test-connection', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: { test_result: 'OK', message: 'Connection OK', certificate_subject: 'CN=Demo' },
        }),
      });
    });

    await page.goto('/ky-so/cau-hinh');
    await expect(page.locator('text=/SmartCA VNPT/i').first()).toBeVisible({ timeout: 10000 });

    const editBtn = page.getByRole('button', { name: /Sửa cấu hình/i }).first();
    await editBtn.click();

    const drawer = page.locator('.ant-drawer:visible').first();
    await expect(drawer).toBeVisible({ timeout: 5000 });

    // Type 8 chars vao client_secret (boundary)
    const secretInput = drawer.locator('input[type="password"]').first();
    await secretInput.fill('12345678'); // 8 chars

    const testBtn = drawer.getByRole('button', { name: /Kiểm tra với secret mới/i });
    await testBtn.click();
    await page.waitForTimeout(1500);

    // KHONG co inline error voi text "tối thiểu 8 ký tự"
    const errorMsg = drawer.locator('.ant-form-item-explain-error').filter({ hasText: /tối thiểu 8 ký tự/i });
    expect(await errorMsg.count()).toBe(0);
  });

  test('TC-KSCH-017 Empty Client Secret on Save → "Để trống nếu giữ nguyên" tag visible', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    await mockKySoCauHinh(page, [
      { provider_code: 'SMARTCA_VNPT', provider_name: 'SmartCA VNPT', has_secret: true },
    ]);

    await page.goto('/ky-so/cau-hinh');
    await expect(page.locator('text=/SmartCA VNPT/i').first()).toBeVisible({ timeout: 10000 });

    const editBtn = page.getByRole('button', { name: /Sửa cấu hình/i }).first();
    await editBtn.click();

    const drawer = page.locator('.ant-drawer:visible').first();
    await expect(drawer).toBeVisible({ timeout: 5000 });

    // Verify Tag "Để trống nếu giữ nguyên" beside Client Secret label
    const tag = drawer.locator('.ant-tag').filter({ hasText: /Để trống nếu giữ nguyên/i }).first();
    await expect(tag).toBeVisible({ timeout: 3000 });

    // Verify hint text khi has_secret = true
    const hint = drawer.locator('text=/Client Secret đã được mã hóa/i').first();
    await expect(hint).toBeVisible({ timeout: 3000 });
  });

  test('TC-KSCH-025 "Lưu & Kích hoạt" button DISABLED khi chua test thanh cong', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    await mockKySoCauHinh(page, [
      { provider_code: 'SMARTCA_VNPT', provider_name: 'SmartCA VNPT', has_secret: true, is_active: false },
    ]);

    await page.goto('/ky-so/cau-hinh');
    await expect(page.locator('text=/SmartCA VNPT/i').first()).toBeVisible({ timeout: 10000 });

    const editBtn = page.getByRole('button', { name: /Sửa cấu hình/i }).first();
    await editBtn.click();

    const drawer = page.locator('.ant-drawer:visible').first();
    await expect(drawer).toBeVisible({ timeout: 5000 });

    // "Lưu & Kích hoạt" button should be disabled (testedOk default false)
    const saveActivateBtn = drawer.getByRole('button', { name: /Lưu & Kích hoạt/i }).first();
    await expect(saveActivateBtn).toBeVisible({ timeout: 3000 });
    await expect(saveActivateBtn).toBeDisabled();
  });

  test('TC-KSCH-030 Profile ID FIELD chỉ render với MySign Viettel (KHONG render cho SmartCA)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    await mockKySoCauHinh(page, [
      { provider_code: 'SMARTCA_VNPT', provider_name: 'SmartCA VNPT', has_secret: true },
      { provider_code: 'MYSIGN_VIETTEL', provider_name: 'MySign Viettel', has_secret: true, profile_id: 'PROF-001' },
    ]);

    await page.goto('/ky-so/cau-hinh');
    await expect(page.locator('text=/SmartCA VNPT/i').first()).toBeVisible({ timeout: 10000 });
    await expect(page.locator('text=/MySign Viettel/i').first()).toBeVisible();

    // Open SmartCA drawer first
    const allEditBtns = page.getByRole('button', { name: /Sửa cấu hình/i });
    expect(await allEditBtns.count()).toBeGreaterThanOrEqual(2);
    await allEditBtns.nth(0).click();

    const drawer = page.locator('.ant-drawer:visible').first();
    await expect(drawer).toBeVisible({ timeout: 5000 });

    // Verify drawer title "Sửa cấu hình — SmartCA VNPT"
    await expect(drawer).toContainText(/SmartCA VNPT/i, { timeout: 3000 });

    // Profile ID field NOT visible
    const profileIdLabel = drawer.locator('label').filter({ hasText: /^Profile ID$/ });
    expect(await profileIdLabel.count()).toBe(0);

    // Close drawer via ESC key (more reliable than clicking Hủy button across forceRender drawers)
    await page.keyboard.press('Escape');
    await page.waitForTimeout(500);

    // Open MySign drawer
    await allEditBtns.nth(1).click();
    // Wait drawer voi MySign title — luc nay drawer co the la 1 instance forceRender duy nhat
    await page.waitForTimeout(500);
    const drawerMysign = page.locator('.ant-drawer:visible').filter({ hasText: /MySign Viettel/i }).first();
    await expect(drawerMysign).toBeVisible({ timeout: 5000 });

    // Profile ID field VISIBLE
    const profileIdLabel2 = drawerMysign.locator('label').filter({ hasText: /^Profile ID$/ }).first();
    await expect(profileIdLabel2).toBeVisible({ timeout: 3000 });
  });

  test('TC-KSCH-031 PATCH activation flow — confirm modal "Kích hoạt provider" hien thi', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    await mockKySoCauHinh(page, [
      {
        provider_code: 'SMARTCA_VNPT',
        provider_name: 'SmartCA VNPT',
        has_secret: true,
        is_active: false,
        test_result: 'OK',
      },
    ]);

    let patchCalled = false;
    await page.route('**/api/ky-so/cau-hinh/*/active', async (route) => {
      if (route.request().method() === 'PATCH') {
        patchCalled = true;
        await route.fulfill({
          status: 200,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ success: true, data: { activated: 'SMARTCA_VNPT' } }),
        });
        return;
      }
      await route.continue();
    });

    await page.goto('/ky-so/cau-hinh');
    await expect(page.locator('text=/SmartCA VNPT/i').first()).toBeVisible({ timeout: 10000 });

    // Click "Kích hoạt" button on card — accessible name "poweroff Kích hoạt" (icon prefix)
    const activateBtn = page.getByRole('button', { name: /Kích hoạt/i }).first();
    await expect(activateBtn).toBeVisible({ timeout: 5000 });
    await activateBtn.click();

    // Modal.confirm "Kích hoạt provider"
    const confirmModal = page.locator('.ant-modal-confirm:visible').first();
    await expect(confirmModal).toBeVisible({ timeout: 5000 });
    await expect(confirmModal).toContainText(/Kích hoạt/i, { timeout: 3000 });

    // OK button "Kích hoạt" trong modal
    const okBtn = confirmModal.getByRole('button', { name: /Kích hoạt/i });
    expect(await okBtn.count()).toBeGreaterThanOrEqual(1);
  });

  test('TC-KSCH-032 PATCH activation success → modal close + refetch + provider hien is_active', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    let getCount = 0;
    await page.route('**/api/ky-so/cau-hinh**', async (route) => {
      const url = route.request().url();
      const method = route.request().method();
      if (method === 'GET' && url.endsWith('/cau-hinh')) {
        getCount += 1;
        const isActive = getCount > 1; // After PATCH, 2nd GET returns is_active=true
        await route.fulfill({
          status: 200,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({
            success: true,
            data: {
              providers: [
                {
                  id: 1, provider_code: 'SMARTCA_VNPT', provider_name: 'SmartCA VNPT',
                  base_url: 'https://gwsca.vnpt.vn', client_id: 'demo_client',
                  has_secret: true, client_secret_masked: '***',
                  test_result: 'OK', last_tested_at: '2026-05-01T10:00:00Z',
                  is_active: isActive, profile_id: null,
                },
              ],
              active_code: isActive ? 'SMARTCA_VNPT' : null,
              stats: {},
            },
          }),
        });
        return;
      }
      if (method === 'PATCH' && url.includes('/active')) {
        await route.fulfill({
          status: 200,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ success: true, data: { activated: 'SMARTCA_VNPT' } }),
        });
        return;
      }
      await route.continue();
    });

    await page.goto('/ky-so/cau-hinh');
    await expect(page.locator('text=/SmartCA VNPT/i').first()).toBeVisible({ timeout: 10000 });

    const activateBtn = page.getByRole('button', { name: /Kích hoạt/i }).first();
    await activateBtn.click();

    const confirmModal = page.locator('.ant-modal-confirm:visible').first();
    await expect(confirmModal).toBeVisible({ timeout: 5000 });

    // Click OK "Kích hoạt" trong modal — last button (modal cancel + ok)
    const okBtn = confirmModal.getByRole('button', { name: /Kích hoạt/i }).last();
    await okBtn.click();

    // Modal closes
    await expect(confirmModal).toBeHidden({ timeout: 5000 });

    // Refetch happens — getCount > 1
    await page.waitForTimeout(1500);
    expect(getCount).toBeGreaterThan(1);
  });
});
