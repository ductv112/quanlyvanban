/**
 * tests/wave-31c-ui/auth-ui.spec.ts — Wave 31c UI follow-up: Auth/Login/Logout/Profile
 *
 * Coverage SKIP UI từ Wave a (22-RESULTS.md) chưa cover ở wave-a-ui.spec.ts:
 *   - TC-AUTH-002 — Enter key submit form login
 *   - TC-AUTH-033 — Logout cancel modal (đóng modal mà không đăng xuất)
 *
 * Các TC đã cover ở tests/wave-a-ui/wave-a-ui.spec.ts:
 *   - TC-AUTH-011..015 (login UI layout/loading/eye/remember)
 *   - TC-AUTH-019..021 (profile drawer)
 *
 * SKIP intentional (document trong RESULTS):
 *   - TC-AUTH-010 (no fixture user_xoa)
 *   - TC-AUTH-017 (token expire 15min real wait)
 *
 * Run: npx playwright test tests/wave-31c-ui/auth-ui.spec.ts --reporter=line --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 20000;

// ─────────────────────────────────────────────────────────────────────────────
// AUTH UI — Login (no auth)
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave 31c UI — Auth login (no session) @wave-31c-ui', () => {
  test.use({ storageState: { cookies: [], origins: [] } });

  test('TC-AUTH-002 Submit form đăng nhập bằng phím Enter', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/login');
    await expect(page.locator('.login-form-title')).toHaveText('Đăng nhập', { timeout: 10000 });

    // Nhập thông tin đăng nhập (test_admin / Test@123)
    await page.getByLabel('Tên đăng nhập').fill('test_admin');
    await page.getByLabel('Mật khẩu').fill('Test@123');

    // Nhấn Enter trong ô mật khẩu — form phải submit, redirect /dashboard
    await page.getByLabel('Mật khẩu').press('Enter');

    // Verify redirect tới /dashboard sau khi login OK
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 15000 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// AUTH UI — Logout cancel modal (cần session)
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave 31c UI — Logout cancel modal @wave-31c-ui', () => {
  test.use({ storageState: storageStateFor('canbo') });

  test('TC-AUTH-033 Bấm Hủy trên modal đăng xuất — đóng modal, vẫn ở trang hiện tại', async ({
    page,
  }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });
    await page.waitForLoadState('networkidle');

    // Click avatar dropdown trigger (header right) — main-user-dropdown div
    const userDropdown = page.locator('.main-user-dropdown').first();
    await expect(userDropdown).toBeVisible({ timeout: 10000 });
    await userDropdown.click();

    // Menu item "Đăng xuất"
    const logoutItem = page.getByRole('menuitem', { name: /Đăng xuất/i }).first();
    await expect(logoutItem).toBeVisible({ timeout: 5000 });
    await logoutItem.click();

    // Modal.confirm hiển thị: title "Đăng xuất" + content "Bạn có chắc chắn..."
    const confirmModal = page.locator('.ant-modal-confirm').first();
    await expect(confirmModal).toBeVisible({ timeout: 5000 });
    await expect(confirmModal).toContainText(/Bạn có chắc chắn muốn đăng xuất/i);

    // Click nút "Hủy" — modal đóng, KHÔNG redirect /login
    const cancelBtn = confirmModal.getByRole('button', { name: /Hủy/i }).first();
    await expect(cancelBtn).toBeVisible({ timeout: 3000 });
    await cancelBtn.click();

    // Modal disappear
    await expect(confirmModal).toBeHidden({ timeout: 5000 });

    // Vẫn ở /dashboard (không bị logout)
    await expect(page).toHaveURL(/\/dashboard/);

    // Sidebar vẫn render → user vẫn authenticated
    await expect(page.locator('.main-sider').first()).toBeVisible();
  });
});
