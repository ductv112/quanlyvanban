/**
 * Wave E DMLN (Linh vuc) — UI test cases
 *
 * Source: .planning/phases/26-execute-wave-e/26-RESULTS-linh-vuc.md
 *
 * No existing UI spec — covers UI flow:
 *   TC-DMLN-001: Layout (header + table + filter)
 *   TC-DMLN-006: Drawer Them KHONG co field "Trang thai"
 *   TC-DMLN-007: Empty Ma -> inline error
 *   TC-DMLN-008: Empty Ten -> inline error
 *   TC-DMLN-012: Drawer Sua CO field "Trang thai" (Switch)
 *
 * Run: npx playwright test tests/wave-de-ui/dm-linh-vuc-ui.spec.ts --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

test.use({ storageState: storageStateFor('admin') });

const URL = '/quan-tri/linh-vuc';
const TEST_TIMEOUT = 25000;

async function openAddDrawer(page: any) {
  await page.goto(URL);
  await page.waitForSelector('table thead th', { timeout: 15000 });
  await page.waitForLoadState('networkidle').catch(() => {});
  await page.waitForTimeout(800);
  const addBtn = page.getByRole('button', { name: /Thêm lĩnh vực/ });
  await addBtn.first().waitFor({ state: 'visible', timeout: 5000 });
  await addBtn.first().click();
  await page.waitForSelector('.ant-drawer-open', { timeout: 12000 });
  await page.waitForTimeout(600);
}

test.describe('Wave E DMLN — Layout @wave-e-ui', () => {
  test('TC-DMLN-001 Header + table + filter visible', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('table', { timeout: 10000 });
    await expect(page.getByText('Quản lý lĩnh vực').first()).toBeVisible();
    await expect(page.getByText('Danh sách lĩnh vực').first()).toBeVisible();
    await expect(page.getByPlaceholder('Tìm kiếm...').first()).toBeVisible();
    await expect(page.getByRole('button', { name: /Thêm lĩnh vực/ })).toBeVisible();
    // Headers contain Ma + Ten + Thu tu + Trang thai
    const headers = (await page.locator('table thead th').allInnerTexts()).join('|').toLowerCase();
    expect(headers).toContain('mã');
    expect(headers).toContain('tên lĩnh vực');
    expect(headers).toContain('thứ tự');
    expect(headers).toContain('trạng thái');
  });
});

test.describe('Wave E DMLN — Drawer Them @wave-e-ui', () => {
  test('TC-DMLN-006 Drawer Them KHONG co field Trang thai', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const drawer = page.locator('.ant-drawer-open');
    // Tieu de phai la "Them ..."
    const title = await drawer.locator('.ant-drawer-title').first().innerText();
    expect(title).toMatch(/Thêm/);
    // Khong co Form.Item cho "Trang thai" (chi render khi editingRecord)
    const trangThaiItem = drawer.locator('.ant-form-item').filter({ hasText: 'Trạng thái' });
    await expect(trangThaiItem).toHaveCount(0);
  });

  test('TC-DMLN-007 Empty Ma -> inline error', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const drawer = page.locator('.ant-drawer-open');
    // Fill Ten by placeholder (avoid label collision)
    await drawer.locator('input[placeholder="VD: Khoa học công nghệ"]').first().fill('Test loi UI 007');
    await drawer.getByRole('button', { name: /Thêm mới/ }).click();
    await expect(
      page.locator('.ant-form-item-explain-error', { hasText: 'Nhập mã lĩnh vực' })
    ).toBeVisible({ timeout: 5000 });
  });

  test('TC-DMLN-008 Empty Ten -> inline error', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const drawer = page.locator('.ant-drawer-open');
    await drawer.locator('input[placeholder="VD: KHCN"]').first().fill('UITC008');
    await drawer.getByRole('button', { name: /Thêm mới/ }).click();
    await expect(
      page.locator('.ant-form-item-explain-error', { hasText: 'Nhập tên lĩnh vực' })
    ).toBeVisible({ timeout: 5000 });
  });
});

test.describe('Wave E DMLN — Drawer Sua @wave-e-ui', () => {
  test('TC-DMLN-012 Drawer Sua CO field Trang thai (Switch)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('table tbody tr', { timeout: 10000 });
    await page.waitForTimeout(800);
    const rowCount = await page.locator('table tbody tr.ant-table-row').count();
    if (rowCount === 0) test.skip(true, 'Khong co linh vuc de test edit');

    const firstRow = page.locator('table tbody tr.ant-table-row').first();
    await firstRow.locator('td').last().locator('button').first().click();
    await page.waitForSelector('.ant-dropdown-menu', { timeout: 5000 });
    await page.locator('.ant-dropdown-menu-item').filter({ hasText: 'Sửa' }).first().click();
    await page.waitForSelector('.ant-drawer-open', { timeout: 8000 });
    await page.waitForTimeout(500);
    const drawer = page.locator('.ant-drawer-open');
    const title = await drawer.locator('.ant-drawer-title').first().innerText();
    expect(title).toContain('Cập nhật lĩnh vực');
    // Trang thai Switch must be present
    const trangThaiItem = drawer.locator('.ant-form-item').filter({ hasText: 'Trạng thái' }).first();
    await expect(trangThaiItem).toBeVisible();
    await expect(trangThaiItem.getByRole('switch').first()).toBeVisible();
    await drawer.getByRole('button', { name: /^Hủy$/ }).click();
  });
});
