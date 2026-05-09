/**
 * tests/smoke/dashboard.spec.ts — Smoke 3 TC Dashboard (P-High)
 *
 * Coverage (TC-DASH-001..003):
 *   - 001: Mở dashboard sau login (sidebar + header render)
 *   - 002: Widget thống kê (stat-card / KPI)
 *   - 003: Sidebar menu hiển thị đầy đủ (≥ 5 menu item)
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

test.use({ storageState: storageStateFor('vanthu') });

test.describe('Smoke — Dashboard', () => {
  test('TC-DASH-001 Mở dashboard sau login @smoke @P-High', async ({ page }) => {
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 15000 });
    // Sidebar/header layout visible
    await expect(
      page.locator('.main-sider, aside, [role="navigation"]').first()
    ).toBeVisible({ timeout: 15000 });
  });

  test('TC-DASH-002 Hiển thị widget thống kê @smoke @P-High', async ({ page }) => {
    await page.goto('/dashboard');
    // Stat cards hoặc Card widget — class .stat-card từ globals.css hoặc .ant-card
    await expect(
      page.locator('.stat-card, .ant-card').first()
    ).toBeVisible({ timeout: 15000 });
  });

  test('TC-DASH-003 Sidebar menu hiển thị đầy đủ @smoke @P-High', async ({ page }) => {
    await page.goto('/dashboard');
    // Menu items: Dashboard, VB đến, VB đi, HSCV, Quản trị, ... (≥ 5)
    const menuItems = page.locator('.ant-menu-item, [role="menuitem"]');
    // Wait at least 1 visible
    await expect(menuItems.first()).toBeVisible({ timeout: 15000 });
    const count = await menuItems.count();
    expect(count).toBeGreaterThanOrEqual(5);
  });
});
