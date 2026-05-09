/**
 * Wave D Quan tri Nguoi dung (QTND) — UI test cases bo sung
 *
 * Source: .planning/phases/25-execute-wave-d/25-RESULTS-nguoi-dung.md
 *
 * Existing spec wave-d-nguoi-dung/wave-d-nguoi-dung.spec.ts da cover:
 *   001, 002, 003, 005, 007, 011, 031, 035, 036, 038, 044, 045, 050
 *
 * Spec nay bo sung cac UI flow chua test:
 *   TC-QTND-006 — Filter trang thai = "Hoat dong" (basis case)
 *   TC-QTND-008 — Drawer Them mo + tieu de + co field Mat khau (positive vs TC-038)
 *   TC-QTND-021 — Empty Ho/Ten -> inline error
 *   TC-QTND-023 — Email sai dinh dang -> inline error
 *
 * Run: npx playwright test tests/wave-de-ui/qt-nguoi-dung-ui.spec.ts --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

test.use({ storageState: storageStateFor('admin') });

const URL = '/quan-tri/nguoi-dung';
const TEST_TIMEOUT = 30000;

async function openAddDrawer(page: any) {
  await page.goto(URL);
  await page.waitForSelector('table', { timeout: 15000 });
  await page.waitForLoadState('networkidle').catch(() => {});
  await page.waitForTimeout(800);
  await page.getByRole('button', { name: /Thêm người dùng/ }).first().click();
  await page.waitForSelector('.ant-drawer-open', { timeout: 12000 });
  await page.waitForTimeout(700);
}

test.describe('Wave D QTND — Filter @wave-d-ui', () => {
  test('TC-QTND-006 Filter trang thai = Hoat dong tra ket qua', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('table', { timeout: 15000 });
    await page.waitForLoadState('networkidle').catch(() => {});
    await page.waitForTimeout(1200);
    // Status select default 'Tat ca' — open and choose 'Hoat dong'
    const statusSel = page
      .locator('.ant-select')
      .filter({ has: page.locator('.ant-select-selection-item:has-text("Tất cả")') })
      .first();
    if (!(await statusSel.isVisible().catch(() => false))) {
      // Try alternate label search
      const fallback = page.locator('.list-filter-bar .ant-select').first();
      await fallback.click({ timeout: 5000 });
    } else {
      await statusSel.click({ timeout: 5000 });
    }
    await page.waitForTimeout(400);
    await page.locator('.ant-select-item-option').filter({ hasText: 'Hoạt động' }).first().click();
    await page.waitForTimeout(1500);
    const rows = await page
      .locator('table tbody tr.ant-table-row')
      .count();
    // Should have at least 1 active staff (admin + others)
    expect(rows).toBeGreaterThan(0);
  });
});

test.describe('Wave D QTND — Drawer Them positive @wave-d-ui', () => {
  test('TC-QTND-008 Drawer Them mo voi tieu de + form rong', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const drawer = page.locator('.ant-drawer-open');
    const title = await drawer.locator('.ant-drawer-title').first().innerText();
    expect(title).toContain('Thêm');
    // Username field visible (input with id contains 'username')
    await expect(drawer.locator('input[id$="username"], input[id*="_username"]').first()).toBeVisible({ timeout: 5000 });
    // Password input — AntD Input.Password renders as visible input + toggle. Use ant-input-password class.
    await expect(drawer.locator('.ant-input-password input').first()).toBeVisible({ timeout: 5000 });
  });

  test('TC-QTND-021 Empty form submit -> inline error cho Ho va ten dem', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const drawer = page.locator('.ant-drawer-open');
    await drawer.getByRole('button', { name: /Thêm mới/ }).click();
    await page.waitForTimeout(800);
    const errors = await page.locator('.ant-form-item-explain-error').allInnerTexts();
    const text = errors.join('|');
    // Page rule message: 'Nhập họ và tên đệm' — match 'họ' substring case-insensitive
    expect(text.toLowerCase()).toMatch(/họ|h.+t.+n/i);
  });

  test('TC-QTND-022 Empty form submit -> inline error cho Ten', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const drawer = page.locator('.ant-drawer-open');
    await drawer.getByRole('button', { name: /Thêm mới/ }).click();
    await page.waitForTimeout(800);
    const errors = await page.locator('.ant-form-item-explain-error').allInnerTexts();
    const text = errors.join('|');
    // Page rule message: 'Nhập tên'
    expect(text.toLowerCase()).toMatch(/tên|nhập tên/i);
  });

  test('TC-QTND-023 Email sai dinh dang -> inline error', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const drawer = page.locator('.ant-drawer-open');
    // Email input has type=email — find by form-item label
    const emailField = drawer.locator('.ant-form-item').filter({ hasText: 'Email' }).locator('input[type="email"]').first();
    if (await emailField.isVisible().catch(() => false)) {
      await emailField.fill('abc-not-email');
    } else {
      await drawer.locator('input[type="email"]').first().fill('abc-not-email');
    }
    // Submit
    await drawer.getByRole('button', { name: /Thêm mới/ }).click();
    await page.waitForTimeout(800);
    const errors = await page.locator('.ant-form-item-explain-error').allInnerTexts();
    const text = errors.join('|').toLowerCase();
    expect(text).toMatch(/email/);
  });
});
