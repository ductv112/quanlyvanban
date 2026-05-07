/**
 * Wave E DMSV (Quan ly So van ban) — UI test cases bo sung
 *
 * Source: .planning/phases/26-execute-wave-e/26-RESULTS-so-vb.md
 *
 * Existing spec wave-e-so-van-ban/wave-e-so-van-ban.spec.ts da cover:
 *   001, 002, 003, 016, 018, 019, 020
 *
 * Spec nay add:
 *   TC-DMSV-006 Drawer Them: empty Ten so -> inline 'Nhập tên' (UI)
 *   TC-DMSV-013 Drawer Sua mo -> form da fill (alternative to existing 019)
 *   TC-DMSV-022 Tabs phan loai trang thai active CSS (visual)
 *
 * Run: npx playwright test tests/wave-de-ui/dm-so-vb-ui.spec.ts --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

test.use({ storageState: storageStateFor('admin') });

const URL = '/quan-tri/so-van-ban';
const TEST_TIMEOUT = 25000;

test.describe('Wave E DMSV — Drawer validation @wave-e-ui', () => {
  test('TC-DMSV-006 Drawer Them — empty Ten so -> inline error', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('.ant-tabs-tab', { timeout: 10000 });
    await page.waitForTimeout(800);
    await page.getByRole('button', { name: /Thêm sổ văn bản/ }).click();
    await page.waitForSelector('.ant-drawer-open', { timeout: 5000 });
    const drawer = page.locator('.ant-drawer-open');
    // Click Them moi without filling -> expect inline error on Ten so
    await drawer.getByRole('button', { name: /Thêm mới/ }).click();
    await page.waitForTimeout(500);
    const errors = await page.locator('.ant-form-item-explain-error').allInnerTexts();
    const text = errors.join('|').toLowerCase();
    expect(text).toMatch(/tên sổ|nhập tên/);
    await page.keyboard.press('Escape');
  });
});

test.describe('Wave E DMSV — Tabs visual @wave-e-ui', () => {
  test('TC-DMSV-022 Tab active co underline / highlight', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('.ant-tabs-tab', { timeout: 10000 });
    // Default active = VB den
    const active = page.locator('.ant-tabs-tab-active').first();
    await expect(active).toBeVisible();
    const activeText = (await active.innerText()).trim();
    expect(activeText).toBe('Văn bản đến');
    // Switch to VB di and verify active changes
    await page.getByRole('tab', { name: /Văn bản đi/ }).click();
    await page.waitForTimeout(500);
    const newActive = (await page.locator('.ant-tabs-tab-active').first().innerText()).trim();
    expect(newActive).toBe('Văn bản đi');
  });
});

test.describe('Wave E DMSV — Drawer Sua field fill @wave-e-ui', () => {
  test('TC-DMSV-013 Drawer Sua — open from menu -> form fields visible', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('.ant-table-row', { timeout: 10000 });
    await page.waitForTimeout(800);
    const moreBtn = page.getByRole('button', { name: 'more' }).first();
    await moreBtn.click();
    await page.waitForSelector('.ant-dropdown-menu', { timeout: 5000 });
    await page.getByRole('menuitem', { name: /Sửa/ }).click();
    await page.waitForSelector('.ant-drawer-open', { timeout: 5000 });
    const drawer = page.locator('.ant-drawer-open');
    // Form fields visible
    await expect(drawer.getByLabel('Tên sổ')).toBeVisible();
    await expect(drawer.getByLabel('Mô tả')).toBeVisible();
    // Tieu de drawer = "Cap nhat ..."
    const title = await drawer.locator('.ant-drawer-title').innerText();
    expect(title).toMatch(/Cập nhật/);
    await drawer.getByRole('button', { name: /^Hủy$/ }).click();
  });
});
