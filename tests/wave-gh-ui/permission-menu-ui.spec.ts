/**
 * tests/wave-gh-ui/permission-menu-ui.spec.ts — Wave g UI follow-up
 *
 * Mục tiêu: Cover các SKIP TC từ Wave g (28-RESULTS.md) bằng UI verification.
 * Wave g executor (urllib backend) SKIP các TC phụ thuộc fixture destructive
 * (lock account mid-session) hoặc role hiếm (Trưởng phòng, is_represent_unit).
 * UI angle: kiểm tra menu sidebar HIDE đúng cho từng role (admin / vanthu /
 * lanhdao / canbo / canbo_x).
 *
 * Reality kiểm chứng từ probe (2026-05-07):
 *   - admin    : 4 group [NGHIỆP VỤ, KÝ SỐ, ĐỐI TÁC, HỆ THỐNG]
 *   - vanthu   : 3 group [NGHIỆP VỤ, KÝ SỐ, ĐỐI TÁC] — không HỆ THỐNG
 *   - lanhdao  : 3 group [NGHIỆP VỤ, KÝ SỐ, ĐỐI TÁC] — không HỆ THỐNG
 *   - canbo    : 3 group [NGHIỆP VỤ, KÝ SỐ, ĐỐI TÁC] — không HỆ THỐNG
 *   - canbo_x  : 3 group [NGHIỆP VỤ, KÝ SỐ, ĐỐI TÁC] — không HỆ THỐNG
 *
 * Phase 1 feature flag (HIDDEN_ROUTES) ẩn QUẢN LÝ + TÍCH HỢP groups khỏi
 * sidebar — đây là expected behavior. Test reflect đúng reality hiện tại.
 *
 * Coverage: 8 TC mới (UI permission menu hide + direct URL access).
 *
 * Run: npx playwright test tests/wave-gh-ui/permission-menu-ui.spec.ts --reporter=line --workers=1
 */
import { test, expect, Page } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 25000;

// Helper: read visible group titles trong sidebar (sau khi đã wait load)
async function getVisibleGroups(page: Page): Promise<string[]> {
  // Wait sider menu render xong (có ít nhất 1 group title)
  await page.waitForSelector('.main-sider .ant-menu-item-group-title', { timeout: 10000 });
  // Extra settle (canboX cần chờ thêm vì store fetch /me chậm hơn)
  await page.waitForTimeout(800);
  const titles = await page.locator('.main-sider .ant-menu-item-group-title').allInnerTexts();
  return titles.map((t) => t.trim());
}

// Helper: kiểm tra label menu item có trong sider không (substring match — vì có badge)
async function isMenuItemVisible(page: Page, label: string): Promise<boolean> {
  // Sider có thể có .ant-menu-item hoặc .ant-menu-submenu-title.
  // textContent có thể chứa ' Văn bản đến 5' (badge) → dùng substring contains.
  const items = await page
    .locator('.main-sider .ant-menu-item, .main-sider .ant-menu-submenu-title')
    .allInnerTexts();
  return items.some((t) => t.trim().startsWith(label));
}

// ─────────────────────────────────────────────────────────────────────────────
// ADMIN — 4 group: NGHIỆP VỤ + KÝ SỐ + ĐỐI TÁC + HỆ THỐNG
// (QUẢN LÝ + TÍCH HỢP bị ẩn bởi Phase 1 HIDDEN_ROUTES)
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave g UI — Permission menu hide (admin) @wave-g-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-PERM-MENU-UI-01 Admin thấy group HỆ THỐNG + submenu Quản trị + Cấu hình ký số', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');

    const groups = await getVisibleGroups(page);
    const joined = groups.join('|').toUpperCase();
    expect(joined).toContain('NGHIỆP VỤ');
    expect(joined).toContain('KÝ SỐ');
    expect(joined).toContain('ĐỐI TÁC');
    expect(joined).toContain('HỆ THỐNG');

    // Admin-only items
    expect(await isMenuItemVisible(page, 'Quản trị')).toBe(true);
    expect(await isMenuItemVisible(page, 'Danh mục')).toBe(true);
    expect(await isMenuItemVisible(page, 'Cấu hình ký số hệ thống')).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// VĂN THƯ — 3 group, KHÔNG HỆ THỐNG
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave g UI — Permission menu hide (vanthu) @wave-g-ui', () => {
  test.use({ storageState: storageStateFor('vanthu') });

  test('TC-PERM-MENU-UI-02 Văn thư KHÔNG thấy group HỆ THỐNG (Quản trị admin-only)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');

    const groups = await getVisibleGroups(page);
    const joined = groups.join('|').toUpperCase();
    expect(joined).toContain('NGHIỆP VỤ');
    expect(joined).toContain('KÝ SỐ');
    expect(joined).toContain('ĐỐI TÁC');
    expect(joined).not.toContain('HỆ THỐNG');

    // KHÔNG thấy admin-only items
    expect(await isMenuItemVisible(page, 'Quản trị')).toBe(false);
    expect(await isMenuItemVisible(page, 'Danh mục')).toBe(false);
    expect(await isMenuItemVisible(page, 'Cấu hình ký số hệ thống')).toBe(false);

    // Vẫn thấy item phổ thông
    expect(await isMenuItemVisible(page, 'Văn bản đến')).toBe(true);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// LÃNH ĐẠO — 3 group, KHÔNG HỆ THỐNG
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave g UI — Permission menu hide (lanhdao) @wave-g-ui', () => {
  test.use({ storageState: storageStateFor('lanhdao') });

  test('TC-PERM-MENU-UI-03 Lãnh đạo KHÔNG thấy group HỆ THỐNG (Quản trị admin-only)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');

    const groups = await getVisibleGroups(page);
    const joined = groups.join('|').toUpperCase();
    expect(joined).toContain('NGHIỆP VỤ');
    expect(joined).not.toContain('HỆ THỐNG');

    expect(await isMenuItemVisible(page, 'Quản trị')).toBe(false);
    expect(await isMenuItemVisible(page, 'Cấu hình ký số hệ thống')).toBe(false);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// CÁN BỘ — 3 group, KHÔNG HỆ THỐNG
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave g UI — Permission menu hide (canbo) @wave-g-ui', () => {
  test.use({ storageState: storageStateFor('canbo') });

  test('TC-PERM-MENU-UI-04 Cán bộ chỉ thấy NGHIỆP VỤ + KÝ SỐ + ĐỐI TÁC (3 group)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');

    const groups = await getVisibleGroups(page);
    const joined = groups.join('|').toUpperCase();
    expect(joined).toContain('NGHIỆP VỤ');
    expect(joined).toContain('KÝ SỐ');
    expect(joined).toContain('ĐỐI TÁC');
    expect(joined).not.toContain('HỆ THỐNG');

    // KHÔNG thấy admin items
    expect(await isMenuItemVisible(page, 'Quản trị')).toBe(false);
    expect(await isMenuItemVisible(page, 'Danh mục')).toBe(false);
    expect(await isMenuItemVisible(page, 'Cấu hình ký số hệ thống')).toBe(false);

    // Thấy item phổ thông cho mọi user
    expect(await isMenuItemVisible(page, 'Văn bản đến')).toBe(true);
    expect(await isMenuItemVisible(page, 'Tài khoản ký số cá nhân')).toBe(true);
    expect(await isMenuItemVisible(page, 'Hồ sơ công việc')).toBe(true);
  });

  test('TC-PERM-MENU-UI-05 Cán bộ KHÔNG thấy submenu Lịch lãnh đạo', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');
    await page.waitForSelector('.main-sider .ant-menu-item', { timeout: 10000 });
    // Note: 'Lịch' submenu hiện đang HIDE bởi HIDDEN_ROUTES (Phase 1 feature flag).
    // Test verify cán bộ KHÔNG thấy 'Lịch lãnh đạo' kể cả trong tương lai khi 'Lịch'
    // submenu được mở lại — chỉ leader/admin mới thấy submenu này.
    expect(await isMenuItemVisible(page, 'Lịch lãnh đạo')).toBe(false);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// CÁN BỘ ĐƠN VỊ KHÁC (canbo_x) — same restriction as canbo
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave g UI — Permission menu hide (canbo_x cross-unit) @wave-g-ui', () => {
  test.use({ storageState: storageStateFor('canboX') });

  test('TC-PERM-MENU-UI-06 Cán bộ đơn vị khác cũng bị ẩn HỆ THỐNG (3 group only)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');

    const groups = await getVisibleGroups(page);
    const joined = groups.join('|').toUpperCase();
    expect(joined).toContain('NGHIỆP VỤ');
    expect(joined).not.toContain('HỆ THỐNG');
    expect(await isMenuItemVisible(page, 'Quản trị')).toBe(false);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// REDIRECT / EMPTY STATE khi truy cập trực tiếp route admin
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave g UI — Direct admin URL access (canbo) @wave-g-ui', () => {
  test.use({ storageState: storageStateFor('canbo') });

  test('TC-PERM-MENU-UI-07 Cán bộ truy cập /quan-tri/don-vi nhận 403 từ API (UI hiển thị empty/error)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    let api403 = false;
    page.on('response', (resp) => {
      const url = resp.url();
      if (url.includes('/api/quan-tri/don-vi') && resp.status() === 403) {
        api403 = true;
      }
    });

    await page.goto('/quan-tri/don-vi');
    // Wait cho API requests + UI settle
    await page.waitForTimeout(3000);

    const url = page.url();
    const stillOnAdmin = url.includes('/quan-tri/don-vi');
    if (stillOnAdmin) {
      // Acceptable: API trả 403 hoặc UI hiển thị empty state / table không có data
      const errorOrEmpty =
        api403 ||
        (await page.locator('.ant-empty, .ant-table-placeholder, .empty-center').count()) > 0;
      expect(errorOrEmpty).toBe(true);
    }
    // Nếu auto-redirect → cũng OK (defense in depth)
  });

  test('TC-PERM-MENU-UI-08 Cán bộ truy cập /quan-tri/nguoi-dung — UI không crash (sidebar still render)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/quan-tri/nguoi-dung');
    await page.waitForTimeout(2000);

    // Sidebar vẫn render → UI không crash
    await expect(page.locator('.main-sider').first()).toBeVisible({ timeout: 5000 });
  });
});
