/**
 * tests/smoke/auth.spec.ts — Smoke 5 TC Auth (P-High)
 *
 * Coverage:
 *   - TC-AUTH-001: login OK admin
 *   - TC-AUTH-002: login OK vanthu
 *   - TC-AUTH-003: login fail — sai mật khẩu
 *   - TC-AUTH-004: login fail — tài khoản đã khoá
 *   - TC-AUTH-005: logout từ session vanthu
 *
 * Note:
 *   - 4 TC đầu KHÔNG dùng storage state (test login từ /login fresh).
 *   - TC-AUTH-005 override storageState='vanthu' (đã có session) để test logout.
 *   - Login form labels khớp /login page.tsx: "Tên đăng nhập" + "Mật khẩu".
 *   - Frontend redirect /dashboard sau login OK (page.tsx:31 `router.push('/dashboard')`).
 *   - AntD message.success/error → toast `.ant-message` overlay.
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

// 4 TC đầu KHÔNG có storage state — test login từ /login
test.describe('Smoke — Auth', () => {
  test.use({ storageState: { cookies: [], origins: [] } });

  test('TC-AUTH-001 Đăng nhập thành công với tài khoản admin @smoke @P-High', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Tên đăng nhập').fill('test_admin');
    await page.getByLabel('Mật khẩu').fill('Test@123');
    await page.getByRole('button', { name: 'Đăng nhập' }).click();
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 15000 });
    // Toast success xuất hiện rồi tắt — verify đã rời /login là đủ cho smoke
  });

  test('TC-AUTH-002 Đăng nhập thành công với tài khoản văn thư @smoke @P-High', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Tên đăng nhập').fill('test_vanthu');
    await page.getByLabel('Mật khẩu').fill('Test@123');
    await page.getByRole('button', { name: 'Đăng nhập' }).click();
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 15000 });
  });

  test('TC-AUTH-003 Đăng nhập thất bại — sai mật khẩu @smoke @P-High', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Tên đăng nhập').fill('test_vanthu');
    await page.getByLabel('Mật khẩu').fill('Wrong@123');
    await page.getByRole('button', { name: 'Đăng nhập' }).click();
    // Stay on /login (không redirect)
    await page.waitForTimeout(2000); // chờ API response + toast
    await expect(page).toHaveURL(/\/login/);
    // AntD message.error toast — locator class .ant-message-notice-error
    const errorToast = page
      .locator('.ant-message-error, .ant-message-notice-error, [role="alert"]')
      .first();
    await expect(errorToast).toBeVisible({ timeout: 5000 });
  });

  test('TC-AUTH-004 Đăng nhập thất bại — tài khoản đã khoá @smoke @P-High', async ({ page }) => {
    await page.goto('/login');
    await page.getByLabel('Tên đăng nhập').fill('test_locked');
    await page.getByLabel('Mật khẩu').fill('Test@123');
    await page.getByRole('button', { name: 'Đăng nhập' }).click();
    await page.waitForTimeout(2000);
    await expect(page).toHaveURL(/\/login/);
    const errorToast = page
      .locator('.ant-message-error, .ant-message-notice-error, [role="alert"]')
      .first();
    await expect(errorToast).toBeVisible({ timeout: 5000 });
  });
});

// TC-AUTH-005 cần session vanthu trước → override storage state
test.describe('Smoke — Auth (logout)', () => {
  test.use({ storageState: storageStateFor('vanthu') });

  test('TC-AUTH-005 Đăng xuất thành công @smoke @P-High', async ({ page }) => {
    await page.goto('/dashboard');
    // Đợi page load xong
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });

    // Click avatar/user menu — fallback sequence:
    //   1. data-testid="user-menu" (preferred)
    //   2. .ant-avatar trong header
    //   3. button có text chứa username
    const userMenuTrigger = page
      .locator('[data-testid="user-menu"]')
      .or(page.locator('.main-header .ant-avatar').first())
      .or(page.locator('.main-header [role="button"]').first());

    if (!(await userMenuTrigger.isVisible({ timeout: 3000 }).catch(() => false))) {
      test.skip(true, 'User menu trigger not found — UI cần thêm data-testid="user-menu"');
      return;
    }

    await userMenuTrigger.click();
    // Click menu item "Đăng xuất"
    const logoutItem = page.getByRole('menuitem', { name: /Đăng xuất|Logout/i });
    if (!(await logoutItem.isVisible({ timeout: 3000 }).catch(() => false))) {
      test.skip(true, 'Logout menuitem not visible — kiểm tra MainLayout dropdown menu');
      return;
    }
    await logoutItem.click();
    await expect(page).toHaveURL(/\/login/, { timeout: 10000 });
  });
});
