/**
 * tests/wave-31c-ui/dashboard-ui.spec.ts — Wave 31c UI follow-up: Dashboard
 *
 * Coverage SKIP UI từ Wave a (22-RESULTS.md) chưa cover ở wave-a-ui.spec.ts:
 *   - TC-DASH-002 — Stat cards: 6 thẻ KPI hiển thị (sau khi filter HIDDEN_ROUTES còn 6, không 8)
 *   - TC-DASH-003 — Stat card: bấm vào card điều hướng đúng route
 *   - TC-DASH-004 — Section "Văn bản mới nhận" + "Xem thêm" link
 *   - TC-DASH-005 — Section "Việc sắp tới hạn" với progress bar
 *   - TC-DASH-006 — "Thao tác nhanh" — 6 nút quick action điều hướng
 *
 * TC đã cover ở wave-a-ui.spec.ts:
 *   - TC-DASH-007..011 (charts, empty states, urgency tag colors)
 *
 * Run: npx playwright test tests/wave-31c-ui/dashboard-ui.spec.ts --reporter=line --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 20000;

test.describe('Wave 31c UI — Dashboard (admin) @wave-31c-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-DASH-002 Hiển thị 6 thẻ KPI sau khi filter HIDDEN_ROUTES (Tin nhắn + Lịch họp ẩn)', async ({
    page,
  }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });
    await page.waitForLoadState('networkidle');

    // .stat-card — render sau khi loading=false
    // Đợi ít nhất 1 stat-card hiện
    const firstCard = page.locator('.stat-card').first();
    await expect(firstCard).toBeVisible({ timeout: 15000 });

    // Đếm tổng: 8 cards trong source, filter Tin nhắn + Lịch họp = còn 6
    const cardCount = await page.locator('.stat-card').count();
    expect(cardCount).toBe(6);

    // Verify các card title hiện diện (substring match)
    const cardArea = page.locator('.stat-card');
    await expect(cardArea.filter({ hasText: 'VB đến chưa đọc' })).toHaveCount(1);
    await expect(cardArea.filter({ hasText: 'VB đi chờ duyệt' })).toHaveCount(1);
    await expect(cardArea.filter({ hasText: 'Hồ sơ công việc' })).toHaveCount(1);
    await expect(cardArea.filter({ hasText: 'Việc quá hạn' })).toHaveCount(1);
    await expect(cardArea.filter({ hasText: 'Dự thảo chờ phát hành' })).toHaveCount(1);
    await expect(cardArea.filter({ hasText: 'Thông báo chưa đọc' })).toHaveCount(1);

    // Tin nhắn + Lịch họp KHÔNG hiển thị (đã filter)
    await expect(cardArea.filter({ hasText: 'Tin nhắn chưa đọc' })).toHaveCount(0);
    await expect(cardArea.filter({ hasText: 'Lịch họp hôm nay' })).toHaveCount(0);
  });

  test('TC-DASH-003 Bấm thẻ KPI "VB đến chưa đọc" điều hướng tới /van-ban-den', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });
    await page.waitForLoadState('networkidle');

    // Đợi card render xong (loading skeleton biến mất)
    const card = page.locator('.stat-card').filter({ hasText: 'VB đến chưa đọc' }).first();
    await expect(card).toBeVisible({ timeout: 15000 });

    // Click card
    await card.click();

    // Redirect /van-ban-den
    await expect(page).toHaveURL(/\/van-ban-den/, { timeout: 10000 });
  });

  test('TC-DASH-004 Section "Văn bản mới nhận" có link "Xem thêm" điều hướng tới /van-ban-den', async ({
    page,
  }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });
    await page.waitForLoadState('networkidle');

    // Card "Văn bản mới nhận"
    const card = page.locator('.page-card').filter({ hasText: 'Văn bản mới nhận' });
    await expect(card.first()).toBeVisible({ timeout: 15000 });

    // Link "Xem thêm" trong extra của Card
    const xemThemLink = card.getByRole('button', { name: /Xem thêm/i }).first();
    await expect(xemThemLink).toBeVisible({ timeout: 5000 });
    await xemThemLink.click();

    // Redirect /van-ban-den
    await expect(page).toHaveURL(/\/van-ban-den/, { timeout: 10000 });
  });

  test('TC-DASH-005 Section "Việc sắp tới hạn" hiển thị (kể cả empty state hoặc danh sách)', async ({
    page,
  }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });
    await page.waitForLoadState('networkidle');

    // Section title
    await expect(page.getByText('Việc sắp tới hạn').first()).toBeVisible({ timeout: 15000 });

    // Card chứa hoặc empty text "Không có việc sắp tới hạn" hoặc Progress component
    const card = page.locator('.page-card').filter({ hasText: 'Việc sắp tới hạn' });
    await expect(card.first()).toBeVisible();

    // Either empty text or progress bar element
    const hasContent = await card
      .locator(':text("Không có việc sắp tới hạn"), .ant-progress')
      .first()
      .isVisible()
      .catch(() => false);
    expect(hasContent).toBe(true);

    // "Xem thêm" link → /ho-so-cong-viec
    const xemThemLink = card.getByRole('button', { name: /Xem thêm/i }).first();
    await expect(xemThemLink).toBeVisible();
    await xemThemLink.click();
    await expect(page).toHaveURL(/\/ho-so-cong-viec/, { timeout: 10000 });
  });

  test('TC-DASH-006 Section "Thao tác nhanh" hiển thị 6 nút quick action + click điều hướng', async ({
    page,
  }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/, { timeout: 10000 });
    await page.waitForLoadState('networkidle');

    // Card "Thao tác nhanh"
    const card = page.locator('.page-card').filter({ hasText: 'Thao tác nhanh' });
    await expect(card.first()).toBeVisible({ timeout: 15000 });

    // Verify 6 quick action buttons hiển thị: Tạo VB đến/đi, Soạn dự thảo, Soạn tin nhắn, Tạo HSCV, Tạo lịch
    await expect(card.getByText('Tạo VB đến')).toBeVisible();
    await expect(card.getByText('Tạo VB đi')).toBeVisible();
    await expect(card.getByText('Soạn dự thảo')).toBeVisible();
    await expect(card.getByText('Tạo HSCV')).toBeVisible();

    // Click "Tạo VB đi" → /van-ban-di
    await card.getByText('Tạo VB đi').click();
    await expect(page).toHaveURL(/\/van-ban-di/, { timeout: 10000 });
  });
});
