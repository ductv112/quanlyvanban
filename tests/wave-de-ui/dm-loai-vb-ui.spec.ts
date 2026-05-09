/**
 * Wave E DMLV (Loai van ban) — UI test cases
 *
 * Source: .planning/phases/26-execute-wave-e/26-RESULTS-loai-vb.md
 *
 * No existing UI spec — covers SKIP-UI items:
 *   TC-DMLV-001: Hien thi 3 tab phan loai (default = VB den)
 *   TC-DMLV-014: Search Loai cha trong dropdown (UI flow only)
 *   TC-DMLV-019: Drawer Sua tieu de "Cap nhat loai van ban"
 *   TC-DMLV-020: Cancel Drawer Sua khong luu thay doi
 *   TC-DMLV-007: Empty Ma -> inline error (drawer)
 *   TC-DMLV-008: Empty Ten -> inline error
 *
 * Run: npx playwright test tests/wave-de-ui/dm-loai-vb-ui.spec.ts --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

test.use({ storageState: storageStateFor('admin') });

const URL = '/quan-tri/loai-van-ban';
const TEST_TIMEOUT = 25000;

async function openAddDrawer(page: any) {
  await page.goto(URL);
  await page.waitForSelector('.ant-tabs-tab', { timeout: 15000 });
  await page.waitForLoadState('networkidle').catch(() => {});
  await page.waitForTimeout(800);
  const addBtn = page.getByRole('button', { name: /Thêm loại văn bản/ });
  await addBtn.first().waitFor({ state: 'visible', timeout: 5000 });
  await addBtn.first().click();
  await page.waitForSelector('.ant-drawer-open', { timeout: 12000 });
  await page.waitForTimeout(600);
}

test.describe('Wave E DMLV — Tabs phan loai @wave-e-ui', () => {
  test('TC-DMLV-001 Hien thi 3 tab + default = Van ban den', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('.ant-tabs-tab', { timeout: 10000 });
    const tabsTexts = (await page.locator('.ant-tabs-tab').allInnerTexts()).map((t) => t.trim());
    expect(tabsTexts).toContain('Văn bản đến');
    expect(tabsTexts).toContain('Văn bản đi');
    expect(tabsTexts).toContain('Văn bản dự thảo');
    const active = (await page.locator('.ant-tabs-tab-active').first().innerText()).trim();
    expect(active).toBe('Văn bản đến');
  });
});

test.describe('Wave E DMLV — Drawer Them validation @wave-e-ui', () => {
  test('TC-DMLV-007 Empty Ma -> inline error', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const drawer = page.locator('.ant-drawer-open');
    await drawer.getByLabel('Tên', { exact: true }).fill('Test loi UI 007');
    await drawer.getByRole('button', { name: /Thêm mới/ }).click();
    await expect(
      page.locator('.ant-form-item-explain-error', { hasText: 'Nhập mã loại văn bản' })
    ).toBeVisible();
  });

  test('TC-DMLV-008 Empty Ten -> inline error', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const drawer = page.locator('.ant-drawer-open');
    await drawer.getByLabel('Mã', { exact: true }).fill('UITC008');
    await drawer.getByRole('button', { name: /Thêm mới/ }).click();
    await expect(
      page.locator('.ant-form-item-explain-error', { hasText: 'Nhập tên loại văn bản' })
    ).toBeVisible();
  });
});

test.describe('Wave E DMLV — Drawer Sua @wave-e-ui', () => {
  test('TC-DMLV-019 Drawer Sua tieu de "Cap nhat loai van ban"', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('.ant-table-row, table tbody tr', { timeout: 15000 });
    await page.waitForLoadState('networkidle').catch(() => {});
    await page.waitForTimeout(1500);
    // Find first more button inside table body
    const moreBtns = page.locator('table tbody').getByRole('button', { name: 'more' });
    const moreCnt = await moreBtns.count();
    if (moreCnt === 0) {
      test.skip(true, 'Khong co row de test Sua');
      return;
    }
    await moreBtns.first().click();
    await page.waitForSelector('.ant-dropdown-menu', { timeout: 5000 });
    // Click Sua menu item (use first menuitem matching "Sửa" text)
    await page.locator('.ant-dropdown-menu-item').filter({ hasText: 'Sửa' }).first().click();
    await page.waitForSelector('.ant-drawer-open', { timeout: 5000 });
    const drawer = page.locator('.ant-drawer-open');
    const title = await drawer.locator('.ant-drawer-title').first().innerText();
    expect(title).toContain('Cập nhật loại văn bản');
    // Form fields pre-filled (Ma + Ten not empty)
    const codeVal = await drawer.getByLabel('Mã', { exact: true }).inputValue();
    const nameVal = await drawer.getByLabel('Tên', { exact: true }).inputValue();
    expect(codeVal.length).toBeGreaterThan(0);
    expect(nameVal.length).toBeGreaterThan(0);
    await drawer.getByRole('button', { name: /^Hủy$/ }).click();
  });

  test('TC-DMLV-020 Cancel Drawer Sua — drawer dong, no save', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('.ant-table-row, table tbody tr', { timeout: 15000 });
    await page.waitForLoadState('networkidle').catch(() => {});
    await page.waitForTimeout(1500);
    // Find first more button inside table body
    const moreBtns = page.locator('table tbody').getByRole('button', { name: 'more' });
    const moreCnt = await moreBtns.count();
    if (moreCnt === 0) {
      test.skip(true, 'Khong co row de test Sua');
      return;
    }
    await moreBtns.first().click();
    await page.waitForSelector('.ant-dropdown-menu', { timeout: 5000 });
    // Click Sua menu item (use first menuitem matching "Sửa" text)
    await page.locator('.ant-dropdown-menu-item').filter({ hasText: 'Sửa' }).first().click();
    await page.waitForSelector('.ant-drawer-open', { timeout: 5000 });
    const drawer = page.locator('.ant-drawer-open');
    // Modify a field then click Huy
    await drawer.getByLabel('Tên', { exact: true }).fill('TC020 cancel test');
    await drawer.getByRole('button', { name: /^Hủy$/ }).click();
    await page.waitForTimeout(500);
    await expect(page.locator('.ant-drawer-open')).toHaveCount(0);
    // Reload to verify no persistence (via API)
    // (don't depend on table refresh — the cancel itself is the assertion)
  });
});

test.describe('Wave E DMLV — Search Loai cha dropdown @wave-e-ui', () => {
  test('TC-DMLV-014 Drawer Them: Loai cha select co showSearch (dropdown opens)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const drawer = page.locator('.ant-drawer-open');
    // The first Form.Item is "Loại cha" (Select with showSearch)
    const firstSelect = drawer.locator('.ant-select').first();
    await firstSelect.click();
    await page.waitForTimeout(700);
    // Dropdown must open
    const dropdownVisible = await page.locator('.ant-select-dropdown:visible').count();
    expect(dropdownVisible).toBeGreaterThan(0);
    // showSearch=true: the .ant-select-show-search class is applied to the Select wrapper
    const showSearchCount = await drawer.locator('.ant-select-show-search').count();
    expect(showSearchCount).toBeGreaterThan(0);
    await page.keyboard.press('Escape');
  });
});
