/**
 * tests/wave-31c-ui/notification-ui.spec.ts — Wave 31c UI follow-up: Notification
 *
 * Coverage SKIP UI từ Wave a (22-RESULTS.md) chưa cover ở wave-a-ui.spec.ts:
 *   - TC-NOTIF-006 — Bell dropdown: bấm nút "Đánh dấu đã đọc tất cả" → badge về 0
 *   - TC-NOTIF-007 — Bell dropdown: nút "Đánh dấu đã đọc tất cả" disabled khi unread=0
 *   - TC-NOTIF-023 — Drawer Tạo TB: validation required title/content
 *
 * TC đã cover ở wave-a-ui.spec.ts:
 *   - TC-NOTIF-004 (badge 99+)
 *   - TC-NOTIF-005 (empty bell)
 *   - TC-NOTIF-012/013 (notice page filter / pagination)
 *   - TC-NOTIF-024/025 (drawer counter / close)
 *
 * SKIP intentional (document trong RESULTS):
 *   - TC-NOTIF-002 (no unread fixture in qlvb_test)
 *   - Socket.IO realtime push (cần worker setup)
 *
 * Run: npx playwright test tests/wave-31c-ui/notification-ui.spec.ts --reporter=line --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 20000;

// ─────────────────────────────────────────────────────────────────────────────
// BELL DROPDOWN — Mark all read button behavior
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave 31c UI — Bell notification (admin) @wave-31c-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-NOTIF-006 Bấm "Đánh dấu đã đọc tất cả" trong dropdown → badge về 0 + items cập nhật', async ({
    page,
  }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Mock unread-count = 5 + list 5 items unread
    await page.route('**/api/notifications/unread-count', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: { count: 5 } }),
      });
    });

    let listCallCount = 0;
    await page.route('**/api/notifications?**', async (route) => {
      listCallCount++;
      const items = Array.from({ length: 5 }, (_, i) => ({
        id: 1000 + i,
        type: 'sign_completed',
        title: `Test thong bao ${i + 1}`,
        message: `Noi dung ${i + 1}`,
        link: null,
        metadata: null,
        is_read: false,
        created_at: '2026-05-01T10:00:00Z',
        read_at: null,
      }));
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: items,
          pagination: { total: 5, page: 1, pageSize: 10 },
        }),
      });
    });

    let markAllCalled = false;
    await page.route('**/api/notifications/read-all', async (route) => {
      markAllCalled = true;
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: { updated_count: 5, message: 'OK' },
        }),
      });
    });

    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });

    // Đợi badge hiện số 5
    const badge = page.locator('.main-header-icon').first().locator('..'); // ancestor Badge
    await expect(page.locator('.ant-badge-count').filter({ hasText: '5' }).first()).toBeVisible({
      timeout: 10000,
    });

    // Click bell icon để mở dropdown
    await page.locator('.main-header-icon').first().click();

    // Dropdown overlay hiển thị
    const overlay = page.locator('.notif-bell-overlay').first();
    await expect(overlay).toBeVisible({ timeout: 5000 });
    expect(listCallCount).toBeGreaterThan(0);

    // Click "Đánh dấu đã đọc tất cả"
    const markAllBtn = overlay.getByRole('button', { name: /Đánh dấu đã đọc tất cả/i }).first();
    await expect(markAllBtn).toBeVisible({ timeout: 3000 });
    await expect(markAllBtn).toBeEnabled();
    await markAllBtn.click();

    // Verify API called
    await page.waitForTimeout(800);
    expect(markAllCalled).toBe(true);

    // Badge biến mất (count = 0 → AntD hide badge)
    await expect(page.locator('.ant-badge-count').filter({ hasText: '5' })).toHaveCount(0);
  });

  test('TC-NOTIF-007 Nút "Đánh dấu đã đọc tất cả" disabled khi unread=0', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Mock unread-count = 0 + list empty
    await page.route('**/api/notifications/unread-count', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: { count: 0 } }),
      });
    });

    await page.route('**/api/notifications?**', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: [],
          pagination: { total: 0, page: 1, pageSize: 10 },
        }),
      });
    });

    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });
    await page.waitForLoadState('networkidle');

    // Click bell icon
    await page.locator('.main-header-icon').first().click();

    const overlay = page.locator('.notif-bell-overlay').first();
    await expect(overlay).toBeVisible({ timeout: 5000 });

    // Nút "Đánh dấu đã đọc tất cả" — disabled
    const markAllBtn = overlay.getByRole('button', { name: /Đánh dấu đã đọc tất cả/i }).first();
    await expect(markAllBtn).toBeVisible({ timeout: 3000 });
    await expect(markAllBtn).toBeDisabled();

    // Empty state hiển thị: "Không có thông báo"
    await expect(overlay.getByText('Không có thông báo')).toBeVisible();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// TRANG THÔNG BÁO DRAWER — Tạo TB validation
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave 31c UI — Drawer Tạo TB validation (admin) @wave-31c-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-NOTIF-023 Drawer "Tạo thông báo": validate required title + content khi để trống', async ({
    page,
  }) => {
    test.setTimeout(TEST_TIMEOUT);

    await page.goto('/thong-bao');
    await expect(page).toHaveURL(/\/thong-bao/, { timeout: 10000 });
    await page.waitForLoadState('networkidle');

    // Click button "Tạo thông báo" (chỉ admin mới thấy)
    const createBtn = page.getByRole('button', { name: /^Tạo thông báo$/i }).first();
    await expect(createBtn).toBeVisible({ timeout: 10000 });
    await createBtn.click();

    // Drawer mở
    const drawer = page.locator('.ant-drawer').first();
    await expect(drawer).toBeVisible({ timeout: 5000 });
    await expect(drawer).toContainText('Tạo thông báo mới');

    // Width >= 700 (size=720)
    const drawerContent = page.locator('.ant-drawer-content-wrapper').first();
    const box = await drawerContent.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.width).toBeGreaterThanOrEqual(700);

    // Bấm "Tạo thông báo" trong drawer extra (KHÔNG nhập gì) → error inline
    // Có 2 nút "Tạo thông báo": page header + drawer extra. Lấy nút trong drawer.
    const submitInDrawer = drawer.getByRole('button', { name: /^Tạo thông báo$/i }).first();
    await expect(submitInDrawer).toBeVisible({ timeout: 3000 });
    await submitInDrawer.click();

    // Lỗi validation: 2 message inline
    await expect(drawer.getByText('Vui lòng nhập tiêu đề')).toBeVisible({ timeout: 5000 });
    await expect(drawer.getByText('Vui lòng nhập nội dung')).toBeVisible({ timeout: 3000 });

    // Drawer vẫn mở (không submit)
    await expect(drawer).toBeVisible();
  });
});
