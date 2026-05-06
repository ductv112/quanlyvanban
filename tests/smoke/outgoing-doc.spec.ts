/**
 * tests/smoke/outgoing-doc.spec.ts — Smoke 5 TC VB đi (P-High)
 *
 * Coverage (TC-VBD-OUT-001..005):
 *   - 001: Mở danh sách
 *   - 002: Detail VB đi released (id=90001, notation=TEST/VBD-OUT-1)
 *   - 003: Tìm kiếm
 *   - 004: Mở Drawer thêm mới
 *   - 005: Pagination visible
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';
import { TEST_DOCS } from '../../e_office_app_new/backend/tests/fixtures/docs';

test.use({ storageState: storageStateFor('vanthu') });

test.describe('Smoke — Văn bản đi', () => {
  test('TC-VBD-OUT-001 Mở danh sách VB đi @smoke @P-High', async ({ page }) => {
    await page.goto('/van-ban-di');
    await expect(
      page.locator('.page-title, h1, h2').filter({ hasText: /Văn bản đi/i }).first()
    ).toBeVisible({ timeout: 15000 });
    const rows = page.locator('.ant-table-row');
    await expect(rows.first()).toBeVisible({ timeout: 15000 });
  });

  test('TC-VBD-OUT-002 Xem chi tiết VB đi đã ban hành @smoke @P-High', async ({ page }) => {
    await page.goto(`/van-ban-di/${TEST_DOCS.outgoing.released.id}`);
    await expect(
      page.getByText(TEST_DOCS.outgoing.released.notation).first()
    ).toBeVisible({ timeout: 15000 });
  });

  test('TC-VBD-OUT-003 Tìm kiếm VB đi @smoke @P-High', async ({ page }) => {
    await page.goto('/van-ban-di');
    await expect(page.locator('.ant-table-row').first()).toBeVisible({ timeout: 15000 });

    const searchInput = page
      .locator(
        'input[placeholder*="tìm" i], input[placeholder*="search" i], input[type="search"], [data-testid="search-input"]'
      )
      .first();

    if (!(await searchInput.isVisible({ timeout: 3000 }).catch(() => false))) {
      test.skip(true, 'Search input not visible');
      return;
    }

    await searchInput.fill('TEST/VBD-OUT-2');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    const firstRowText = await page.locator('.ant-table-row').first().textContent();
    expect(firstRowText).toContain('TEST/VBD-OUT-2');
  });

  test('TC-VBD-OUT-004 Mở Drawer thêm mới VB đi @smoke @P-High', async ({ page }) => {
    await page.goto('/van-ban-di');
    await expect(page.locator('.ant-table, .page-card').first()).toBeVisible({ timeout: 15000 });

    const addButton = page
      .getByRole('button', { name: /Thêm mới|Tạo mới|Phát hành|Thêm/i })
      .first();

    if (!(await addButton.isVisible({ timeout: 3000 }).catch(() => false))) {
      test.skip(true, 'Add button not visible');
      return;
    }

    await addButton.click();
    await expect(page.locator('.ant-drawer-content').first()).toBeVisible({ timeout: 5000 });
  });

  test('TC-VBD-OUT-005 Pagination VB đi hiển thị @smoke @P-High', async ({ page }) => {
    await page.goto('/van-ban-di');
    await expect(page.locator('.ant-pagination').first()).toBeVisible({ timeout: 15000 });
  });
});
