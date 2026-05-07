/**
 * tests/wave-f-ui/boundary-ui.spec.ts — Wave F UI testcases (1 TC SKIP UI)
 *
 * Coverage:
 *   - TC-BND-AUTH-006: confirmPassword check chỉ ở FE (Form rule),
 *     backend không nhận field này → phải test qua UI Playwright.
 *
 *     Form: /thong-tin-ca-nhan → tab "Đổi mật khẩu"
 *     Trường:
 *       - Mật khẩu hiện tại (oldPassword)
 *       - Mật khẩu mới (newPassword) — pattern: ≥6, có chữ hoa+thường+số
 *       - Xác nhận mật khẩu mới (confirmPassword) — phải khớp newPassword
 *
 *     Sub-cases (kiểm tra Form rule FE):
 *       a. confirm để trống → "Xác nhận mật khẩu mới"
 *       b. confirm khác newPassword → "Mật khẩu xác nhận không khớp"
 *       c. confirm khớp newPassword → KHÔNG có lỗi inline (rule pass)
 *
 *     KHÔNG submit thật (tránh đổi password test_admin) — chỉ verify lỗi inline.
 *
 * Run:
 *   npx playwright test tests/wave-f-ui/ --reporter=line --workers=1
 *
 * Tag: @wave-f-ui
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 20000;

test.describe('Wave F UI — Đổi mật khẩu confirmPassword @wave-f-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-BND-AUTH-006 confirmPassword không khớp newPassword hiển thị lỗi FE', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Mở trang Thông tin cá nhân (default tab = Đổi mật khẩu)
    await page.goto('/thong-tin-ca-nhan');
    await expect(page.getByRole('button', { name: 'Đổi mật khẩu' })).toBeVisible({ timeout: 10000 });

    // Locator các trường — dùng id selector để tránh strict-mode collision
    // (label "Mật khẩu mới" trùng prefix với "Xác nhận mật khẩu mới")
    const oldPwd = page.locator('#oldPassword');
    const newPwd = page.locator('#newPassword');
    const confirmPwd = page.locator('#confirmPassword');
    const submitBtn = page.getByRole('button', { name: 'Đổi mật khẩu' });

    await expect(oldPwd).toBeVisible();
    await expect(newPwd).toBeVisible();
    await expect(confirmPwd).toBeVisible();

    // ─────────────────────────────────────────────────────────────────────
    // Sub-case a: confirm để trống → "Xác nhận mật khẩu mới"
    // ─────────────────────────────────────────────────────────────────────
    await oldPwd.fill('Test@123');
    await newPwd.fill('NewPass1');
    await confirmPwd.fill('');
    // blur khỏi confirm để trigger rule
    await newPwd.click();
    await submitBtn.click();
    await expect(page.getByText('Xác nhận mật khẩu mới', { exact: true }).last()).toBeVisible({ timeout: 5000 });

    // ─────────────────────────────────────────────────────────────────────
    // Sub-case b: confirm khác newPassword → "Mật khẩu xác nhận không khớp"
    // ─────────────────────────────────────────────────────────────────────
    await confirmPwd.fill('NewPass2');
    await newPwd.click(); // blur trigger
    await submitBtn.click();
    await expect(page.getByText('Mật khẩu xác nhận không khớp')).toBeVisible({ timeout: 5000 });

    // Backend KHÔNG được gọi (FE rule chặn) — verify không có message.success
    // Chỉ check không xuất hiện thông báo "Đổi mật khẩu thành công"
    await page.waitForTimeout(500);
    await expect(page.getByText('Đổi mật khẩu thành công')).toHaveCount(0);

    // ─────────────────────────────────────────────────────────────────────
    // Sub-case c: confirm khớp newPassword → KHÔNG còn lỗi "không khớp"
    // ─────────────────────────────────────────────────────────────────────
    await confirmPwd.fill('NewPass1');
    await newPwd.click(); // blur trigger re-validate
    await page.waitForTimeout(300);
    // Lỗi "không khớp" PHẢI biến mất (FE rule pass)
    await expect(page.getByText('Mật khẩu xác nhận không khớp')).toHaveCount(0);

    // KHÔNG click submit ở case c — tránh đổi password test_admin thật
  });
});
