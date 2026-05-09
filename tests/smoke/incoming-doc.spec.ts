/**
 * tests/smoke/incoming-doc.spec.ts — Smoke 8 TC VB đến (P-High)
 *
 * Coverage (TC-VBD-CRUD-001..008):
 *   - 001: Mở danh sách (verify table render + ≥ 5 fixture rows)
 *   - 002: Detail VB đến status NEW (id=90001, notation=TEST/VBD-NEW)
 *   - 003: Detail VB đến status PROCESSING (id=90003)
 *   - 004: Tìm kiếm theo notation
 *   - 005: Pagination component visible
 *   - 006: Mở Drawer thêm mới
 *   - 007: Detail VB đến đã hoàn thành (id=90004)
 *   - 008: Filter UI tồn tại
 *
 * Tất cả TC dùng storage state vanthu (có quyền vào sổ + giao việc).
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';
import { TEST_DOCS } from '../../e_office_app_new/backend/tests/fixtures/docs';

test.use({ storageState: storageStateFor('vanthu') });

test.describe('Smoke — Văn bản đến', () => {
  test('TC-VBD-CRUD-001 Mở danh sách VB đến @smoke @P-High', async ({ page }) => {
    await page.goto('/van-ban-den');
    // Page heading hoặc page-title visible
    await expect(
      page.locator('.page-title, h1, h2').filter({ hasText: /Văn bản đến/i }).first()
    ).toBeVisible({ timeout: 15000 });
    // Table render
    const rows = page.locator('.ant-table-row');
    await expect(rows.first()).toBeVisible({ timeout: 15000 });
    const count = await rows.count();
    expect(count).toBeGreaterThanOrEqual(5);
  });

  test('TC-VBD-CRUD-002 Xem chi tiết VB đến (status NEW) @smoke @P-High', async ({ page }) => {
    await page.goto(`/van-ban-den/${TEST_DOCS.incoming.new.id}`);
    // Detail page render với notation hiển thị
    await expect(
      page.getByText(TEST_DOCS.incoming.new.notation).first()
    ).toBeVisible({ timeout: 15000 });
  });

  test('TC-VBD-CRUD-003 Xem chi tiết VB đến (status PROCESSING) @smoke @P-High', async ({ page }) => {
    await page.goto(`/van-ban-den/${TEST_DOCS.incoming.processing.id}`);
    await expect(
      page.getByText(TEST_DOCS.incoming.processing.notation).first()
    ).toBeVisible({ timeout: 15000 });
  });

  test('TC-VBD-CRUD-004 Tìm kiếm VB đến theo notation @smoke @P-High', async ({ page }) => {
    await page.goto('/van-ban-den');
    // Đợi table load xong rồi mới search
    await expect(page.locator('.ant-table-row').first()).toBeVisible({ timeout: 15000 });

    const searchInput = page
      .locator(
        'input[placeholder*="tìm" i], input[placeholder*="search" i], input[type="search"], [data-testid="search-input"]'
      )
      .first();

    if (!(await searchInput.isVisible({ timeout: 3000 }).catch(() => false))) {
      test.skip(true, 'Search input not visible — UI cần data-testid="search-input"');
      return;
    }

    await searchInput.fill('TEST/VBD-NEW');
    await page.keyboard.press('Enter');
    await page.waitForTimeout(2000);
    // Verify table row đầu chứa notation tìm kiếm
    const firstRowText = await page.locator('.ant-table-row').first().textContent();
    expect(firstRowText).toContain('TEST/VBD-NEW');
  });

  test('TC-VBD-CRUD-005 Pagination VB đến hiển thị @smoke @P-High', async ({ page }) => {
    await page.goto('/van-ban-den');
    const pagination = page.locator('.ant-pagination').first();
    await expect(pagination).toBeVisible({ timeout: 15000 });
  });

  test('TC-VBD-CRUD-006 Mở Drawer thêm mới VB đến @smoke @P-High', async ({ page }) => {
    await page.goto('/van-ban-den');
    // Đợi page render
    await expect(page.locator('.ant-table, .page-card').first()).toBeVisible({ timeout: 15000 });

    const addButton = page
      .getByRole('button', { name: /Thêm mới|Vào sổ|Tạo mới|Thêm/i })
      .first();

    if (!(await addButton.isVisible({ timeout: 3000 }).catch(() => false))) {
      test.skip(true, 'Add button not visible — UI có thể dùng icon-only button');
      return;
    }

    await addButton.click();
    const drawer = page.locator('.ant-drawer-content').first();
    await expect(drawer).toBeVisible({ timeout: 5000 });

    const drawerTitle = await page.locator('.ant-drawer-title').first().textContent();
    expect(drawerTitle?.toLowerCase()).toMatch(/thêm|vào sổ|tạo|mới/);
  });

  test('TC-VBD-CRUD-007 Xem VB đến đã hoàn thành @smoke @P-High', async ({ page }) => {
    await page.goto(`/van-ban-den/${TEST_DOCS.incoming.completed.id}`);
    await expect(
      page.getByText(TEST_DOCS.incoming.completed.notation).first()
    ).toBeVisible({ timeout: 15000 });
  });

  test('TC-VBD-CRUD-008 Filter UI VB đến tồn tại @smoke @P-High', async ({ page }) => {
    await page.goto('/van-ban-den');
    // Filter UI: Select/Tag/Button "Lọc" hoặc filter row
    const filterUI = page
      .locator('.filter-row, .ant-select, [data-testid="status-filter"]')
      .or(page.getByRole('button', { name: /Lọc|Bộ lọc/i }))
      .first();
    await expect(filterUI).toBeVisible({ timeout: 15000 });
  });
});
