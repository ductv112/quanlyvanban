/**
 * tests/wave-c-ky-so/wave-c-ky-so-ui.spec.ts
 *
 * Wave c — Ký số UI smoke (subset of 70 TC):
 *   - 4 tab Danh sách ký số (Cần ký / Đang xử lý / Đã ký / Thất bại)
 *   - Banner Root CA luôn hiển thị
 *   - Permission test_lanhdao
 *   - Cấu hình ký số trang admin
 *
 * Run: npx playwright test tests/wave-c-ky-so/ --reporter=line --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 20000;

// ──────────────────────────────────────────────────────────
// DANH SÁCH KÝ SỐ — test_lanhdao session
// ──────────────────────────────────────────────────────────
test.describe('Wave c — Danh sách ký số @wave-c-ks', () => {
  test.use({ storageState: storageStateFor('lanhdao') });

  test('TC-KSDS-001 Truy cập Danh sách ký số — title + 4 tab + Root CA banner', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/ky-so/danh-sach');

    // Title
    await expect(page.locator('.page-title')).toContainText('Danh sách ký số');

    // Root CA banner (TC-KSDS-015)
    await expect(page.getByText('Cần cài Root CA Viettel')).toBeVisible();

    // 4 tabs
    await expect(page.getByRole('tab', { name: /Cần ký/i })).toBeVisible();
    await expect(page.getByRole('tab', { name: /Đang xử lý/i })).toBeVisible();
    await expect(page.getByRole('tab', { name: /Đã ký/i })).toBeVisible();
    await expect(page.getByRole('tab', { name: /Thất bại/i })).toBeVisible();
  });

  test('TC-KSDS-002 Mặc định mở tab Cần ký', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/ky-so/danh-sach');
    // Active tab is Cần ký
    const activeTab = page.locator('.ant-tabs-tab-active');
    await expect(activeTab).toContainText('Cần ký');
  });

  test('TC-KSDS-013 URL cập nhật khi đổi tab', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/ky-so/danh-sach');
    await page.getByRole('tab', { name: /Đang xử lý/i }).click();
    await expect(page).toHaveURL(/tab=pending/);

    await page.getByRole('tab', { name: /Đã ký/i }).click();
    await expect(page).toHaveURL(/tab=completed/);

    await page.getByRole('tab', { name: /Thất bại/i }).click();
    await expect(page).toHaveURL(/tab=failed/);
  });

  test('TC-KSDS-015 Banner Root CA luôn hiển thị (link tải .cer + HDSD PDF)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/ky-so/danh-sach');

    // TC-KSDS-016: link Tải Root CA
    const cerLink = page.getByRole('link', { name: /Tải Root CA/i });
    await expect(cerLink).toBeVisible();
    await expect(cerLink).toHaveAttribute('href', /\.cer$/);

    // TC-KSDS-017: link HDSD PDF
    const pdfLink = page.getByRole('link', { name: /hướng dẫn|HDSD/i });
    await expect(pdfLink).toBeVisible();
    await expect(pdfLink).toHaveAttribute('href', /\.pdf$/);
  });

  test('TC-KSDS-005 Tab Cần ký trống — empty placeholder', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/ky-so/danh-sach');
    await page.waitForLoadState('networkidle');
    const tableRows = page.locator('.ant-table-tbody .ant-table-row').filter({
      hasNot: page.locator('.ant-table-placeholder'),
    });
    const rowCount = await tableRows.count();
    if (rowCount === 0) {
      // AntD default empty pattern
      const empty = page.locator('.ant-empty, .ant-table-placeholder').first();
      await expect(empty).toBeVisible();
    }
  });
});

// ──────────────────────────────────────────────────────────
// CẤU HÌNH KÝ SỐ — admin session
// ──────────────────────────────────────────────────────────
test.describe('Wave c — Cấu hình ký số hệ thống @wave-c-ks-cfg', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-KSCH-002 Admin truy cập trang cấu hình', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/ky-so/cau-hinh');
    // Page should load successfully (not 403)
    await expect(page.locator('.page-title, h1, h2, h3').first()).toBeVisible({ timeout: 10000 });
  });

  test('TC-KSCH-003/004 Banner trạng thái nhà cung cấp', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/ky-so/cau-hinh');
    // Banner xanh khi có active, vàng khi chưa — chỉ check banner exist
    const banner = page.locator('[class*="ant-alert"]').first();
    await expect(banner).toBeVisible({ timeout: 10000 });
  });
});

// ──────────────────────────────────────────────────────────
// PERMISSION — test_lanhdao KHÔNG truy cập được /ky-so/cau-hinh
// ──────────────────────────────────────────────────────────
test.describe('Wave c — Permission @wave-c-ks-perm', () => {
  test.use({ storageState: storageStateFor('lanhdao') });

  test('TC-KSCH-001 User không có quyền — Empty với "không có quyền truy cập"', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/ky-so/cau-hinh');
    await page.waitForLoadState('networkidle');
    // Frontend shows AntD Empty với mô tả "Bạn không có quyền truy cập trang này"
    await expect(page.getByText('Bạn không có quyền truy cập trang này')).toBeVisible();
  });
});
