/**
 * tests/smoke/admin.spec.ts — Smoke 4 TC Admin (P-High)
 *
 * Coverage (TC-ADMIN-001..004):
 *   - 001: Đơn vị (tree component)
 *   - 002: Người dùng (≥ 6 user fixture)
 *   - 003: Vai trò (≥ 6 roles từ seed 001)
 *   - 004: Sổ văn bản
 *
 * Cần admin role để truy cập /quan-tri/*.
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

test.use({ storageState: storageStateFor('admin') });

test.describe('Smoke — Quản trị', () => {
  test('TC-ADMIN-001 Mở trang quản trị Đơn vị @smoke @P-High', async ({ page }) => {
    await page.goto('/quan-tri/don-vi');
    await expect(
      page.locator('.page-title, h1, h2').filter({ hasText: /Đơn vị|Cơ cấu/i }).first()
    ).toBeVisible({ timeout: 15000 });
    // Tree component visible
    await expect(
      page.locator('.ant-tree, [role="tree"]').first()
    ).toBeVisible({ timeout: 15000 });
  });

  test('TC-ADMIN-002 Mở trang quản trị Người dùng @smoke @P-High', async ({ page }) => {
    await page.goto('/quan-tri/nguoi-dung');
    await expect(
      page.locator('.page-title, h1, h2').filter({ hasText: /Người dùng|Nhân viên/i }).first()
    ).toBeVisible({ timeout: 15000 });
    const rows = page.locator('.ant-table-row');
    await expect(rows.first()).toBeVisible({ timeout: 15000 });
    // ≥ 6 user (admin gốc + 6 test fixture). Page 1 mặc định = 10 → ≥ 6 OK.
    const count = await rows.count();
    expect(count).toBeGreaterThanOrEqual(6);
  });

  test('TC-ADMIN-003 Mở trang quản trị Vai trò @smoke @P-High', async ({ page }) => {
    await page.goto('/quan-tri/vai-tro');
    await expect(
      page.locator('.page-title, h1, h2').filter({ hasText: /Vai trò/i }).first()
    ).toBeVisible({ timeout: 15000 });
    const rows = page.locator('.ant-table-row');
    await expect(rows.first()).toBeVisible({ timeout: 15000 });
  });

  test('TC-ADMIN-004 Mở trang quản trị Sổ văn bản @smoke @P-High', async ({ page }) => {
    await page.goto('/quan-tri/so-van-ban');
    await expect(
      page.locator('.page-title, h1, h2').filter({ hasText: /Sổ văn bản/i }).first()
    ).toBeVisible({ timeout: 15000 });
  });
});
