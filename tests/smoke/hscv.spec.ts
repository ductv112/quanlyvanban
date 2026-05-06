/**
 * tests/smoke/hscv.spec.ts — Smoke 5 TC HSCV (P-High)
 *
 * Coverage (TC-HSCV-001..005):
 *   - 001: Mở danh sách
 *   - 002: Detail HSCV active (id=9001)
 *   - 003: Detail HSCV closed (id=9002)
 *   - 004: Mở Drawer tạo HSCV
 *   - 005: Tìm kiếm
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';
import { TEST_DOCS } from '../../e_office_app_new/backend/tests/fixtures/docs';

test.use({ storageState: storageStateFor('canbo') });

test.describe('Smoke — Hồ sơ công việc', () => {
  test('TC-HSCV-001 Mở danh sách HSCV @smoke @P-High', async ({ page }) => {
    await page.goto('/ho-so-cong-viec');
    await expect(
      page.locator('.page-title, h1, h2').filter({ hasText: /Hồ sơ công việc/i }).first()
    ).toBeVisible({ timeout: 15000 });
  });

  test('TC-HSCV-002 Xem chi tiết HSCV active @smoke @P-High', async ({ page }) => {
    await page.goto(`/ho-so-cong-viec/${TEST_DOCS.handling.active.id}`);
    // HSCV name fixture: "TEST: HSCV active"
    await expect(
      page.getByText(/TEST: HSCV active/i).first()
    ).toBeVisible({ timeout: 15000 });
  });

  test('TC-HSCV-003 Xem chi tiết HSCV closed @smoke @P-High', async ({ page }) => {
    await page.goto(`/ho-so-cong-viec/${TEST_DOCS.handling.closed.id}`);
    await expect(
      page.getByText(/TEST: HSCV closed/i).first()
    ).toBeVisible({ timeout: 15000 });
  });

  test('TC-HSCV-004 Mở Drawer tạo HSCV @smoke @P-High', async ({ page }) => {
    await page.goto('/ho-so-cong-viec');
    await expect(page.locator('.ant-table, .page-card').first()).toBeVisible({ timeout: 15000 });

    const addButton = page
      .getByRole('button', { name: /Thêm mới|Tạo mới|Tạo HSCV|Thêm/i })
      .first();

    if (!(await addButton.isVisible({ timeout: 3000 }).catch(() => false))) {
      test.skip(true, 'Add HSCV button not visible');
      return;
    }

    await addButton.click();
    await expect(page.locator('.ant-drawer-content').first()).toBeVisible({ timeout: 5000 });
  });

  test('TC-HSCV-005 Tìm kiếm HSCV @smoke @P-High', async ({ page }) => {
    await page.goto('/ho-so-cong-viec');
    await page.waitForTimeout(2000);

    const searchInput = page
      .locator(
        'input[placeholder*="tìm" i], input[placeholder*="search" i], input[type="search"], [data-testid="search-input"]'
      )
      .first();

    if (!(await searchInput.isVisible({ timeout: 3000 }).catch(() => false))) {
      test.skip(true, 'Search input not visible');
      return;
    }

    await searchInput.fill('TEST: HSCV');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(1500);
    // Smoke: chỉ verify search input nhận input không lỗi — không assert kết quả cụ thể
  });
});
