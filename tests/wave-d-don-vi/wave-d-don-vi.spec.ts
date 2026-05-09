/**
 * tests/wave-d-don-vi/wave-d-don-vi.spec.ts — Wave D Quan tri Don vi UI testcases
 *
 * Coverage: UI TC tu wave-d module QTDV ma can browser interaction.
 * API-only TC duoc cover bang curl trong RESULTS.md.
 *
 * Strategy:
 *   - Reuse storageState (admin)
 *   - Title format: 'TC-QTDV-NNN <Vietnamese title>'
 *   - Tag @wave-d-ui
 *
 * Run: npx playwright test tests/wave-d-don-vi/ --reporter=line --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 25000;

test.use({ storageState: storageStateFor('admin') });

// Helper: open Them drawer (button text "plus Thêm đơn vị" — use substring match)
async function openAddDrawer(page: any) {
  await page.goto('/quan-tri/don-vi');
  await page.waitForSelector('table');
  await page.getByRole('button', { name: /Thêm đơn vị/ }).click();
  await page.waitForSelector('.ant-drawer-open', { timeout: 8000 });
}

test.describe('Wave D Don vi — Layout + Tree (UI) @wave-d-ui', () => {
  test('TC-QTDV-001 Hien thi cay co cau to chuc va bang danh sach', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/quan-tri/don-vi');
    await expect(page.getByText('Quản lý đơn vị').first()).toBeVisible();
    await expect(page.getByText('Cơ cấu tổ chức').first()).toBeVisible();
    await expect(page.locator('.ant-tree')).toBeVisible();
    await expect(page.getByText('Danh sách đơn vị').first()).toBeVisible();
    await expect(page.locator('table').first()).toBeVisible();
    const treeBox = await page.locator('.ant-tree').first().boundingBox();
    const tableBox = await page.locator('table').first().boundingBox();
    expect(tableBox!.x).toBeGreaterThan(treeBox!.x);
  });

  test('TC-QTDV-002 Bang co 5 cot Ma Ten Cap So NV Trang thai', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/quan-tri/don-vi');
    await page.waitForSelector('table thead th');
    const headers = (await page.locator('table thead th').allInnerTexts()).join('|').toUpperCase();
    expect(headers).toContain('MÃ');
    expect(headers).toContain('TÊN');
    expect(headers).toContain('CẤP');
    expect(headers).toContain('SỐ NV');
    expect(headers).toContain('TRẠNG THÁI');
  });

  test('TC-QTDV-004 Tim kiem don vi tren cay theo ten', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/quan-tri/don-vi');
    await page.waitForSelector('.ant-tree-treenode');
    await page.locator('input[placeholder="Tìm kiếm đơn vị..."]').fill('Sở Nội vụ');
    await page.waitForTimeout(500);
    await expect(page.locator('.ant-tree')).toContainText(/Sở Nội vụ/);
  });

  test('TC-QTDV-005 Nut Tai lai cay don vi hoat dong', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/quan-tri/don-vi');
    await page.waitForSelector('.ant-tree-treenode');
    let apiCalled = false;
    page.on('request', (req: any) => {
      if (req.url().includes('/api/quan-tri/don-vi/tree')) apiCalled = true;
    });
    apiCalled = false;
    await page.getByRole('button', { name: 'reload' }).click();
    await page.waitForTimeout(800);
    expect(apiCalled).toBeTruthy();
  });
});

test.describe('Wave D Don vi — Drawer Them validation @wave-d-ui', () => {
  test('TC-QTDV-009 Bo trong Ma -> loi inline Nhap ma', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    await page.getByLabel('Tên', { exact: true }).fill('Test loi UI 9');
    await page.getByRole('button', { name: 'Thêm mới' }).click();
    await expect(page.locator('.ant-form-item-explain-error', { hasText: 'Nhập mã' })).toBeVisible();
  });

  test('TC-QTDV-010 Bo trong Ten -> loi inline Nhap ten', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    await page.getByLabel('Mã', { exact: true }).fill('UI_TC010');
    await page.getByRole('button', { name: 'Thêm mới' }).click();
    await expect(page.locator('.ant-form-item-explain-error', { hasText: 'Nhập tên' })).toBeVisible();
  });

  test('TC-QTDV-012 Email sai dinh dang -> Email khong hop le', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    await page.getByLabel('Mã', { exact: true }).fill('UI_TC012');
    await page.getByLabel('Tên', { exact: true }).fill('Test email loi');
    await page.getByLabel('Email', { exact: true }).fill('abc@xyz');
    await page.getByRole('button', { name: 'Thêm mới' }).click();
    await expect(page.locator('.ant-form-item-explain-error', { hasText: /Email không hợp lệ/ })).toBeVisible();
  });

  test('TC-QTDV-013 SDT chua chu cai -> So dien thoai khong hop le', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    await page.getByLabel('Mã', { exact: true }).fill('UI_TC013');
    await page.getByLabel('Tên', { exact: true }).fill('Test sdt loi');
    await page.getByLabel('SDT', { exact: true }).fill('024abc123');
    await page.getByRole('button', { name: 'Thêm mới' }).click();
    await expect(page.locator('.ant-form-item-explain-error', { hasText: /Số điện thoại không hợp lệ/ })).toBeVisible();
  });

  test('TC-QTDV-014 Fax chua ky tu khong hop le -> So fax khong hop le', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    await page.getByLabel('Mã', { exact: true }).fill('UI_TC014');
    await page.getByLabel('Tên', { exact: true }).fill('Test fax loi');
    await page.getByLabel('Fax', { exact: true }).fill('02@3#456');
    await page.getByRole('button', { name: 'Thêm mới' }).click();
    await expect(page.locator('.ant-form-item-explain-error', { hasText: /Số fax không hợp lệ/ })).toBeVisible();
  });

  test('TC-QTDV-015 Ma vuot 50 ky tu -> bi cat o 50', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const long = 'A'.repeat(60);
    const codeInput = page.getByLabel('Mã', { exact: true });
    await codeInput.fill(long);
    const value = await codeInput.inputValue();
    expect(value.length).toBe(50);
  });

  test('TC-QTDV-018 Mo ta 500 ky tu -> bi cat o 500', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const ta = page.getByLabel('Mô tả', { exact: true });
    await ta.fill('D'.repeat(500));
    expect((await ta.inputValue()).length).toBe(500);
    await ta.fill('D'.repeat(501));
    expect((await ta.inputValue()).length).toBeLessThanOrEqual(500);
  });

  test('TC-QTDV-028 Switch Cho phep so van ban toggle', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const switchEl = page.locator('.ant-drawer-body').getByRole('switch').first();
    const before = await switchEl.getAttribute('aria-checked');
    await switchEl.click();
    const after = await switchEl.getAttribute('aria-checked');
    expect(after).not.toBe(before);
  });

  test('TC-QTDV-029 Thu tu InputNumber min=0 chan so am', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    const sortInput = page.getByLabel('Thứ tự', { exact: true });
    await sortInput.fill('-5');
    await sortInput.blur();
    const v = await sortInput.inputValue();
    const num = Number(v);
    // Either reset to 0 or clamped (>=0)
    expect(num >= 0 || isNaN(num) || v === '').toBeTruthy();
  });

  test('TC-QTDV-030 Click Huy o header drawer dong khong luu', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    await page.getByLabel('Mã', { exact: true }).fill('CANCEL_TEST');
    await page.getByLabel('Tên', { exact: true }).fill('Test cancel');
    // Click Huy in drawer header extra
    await page.locator('.ant-drawer-header').getByRole('button', { name: 'Hủy' }).click();
    await page.waitForTimeout(500);
    await expect(page.locator('.ant-drawer-open')).toHaveCount(0);
    // Reopen — fields cleared
    await page.getByRole('button', { name: /Thêm đơn vị/ }).click();
    await page.waitForSelector('.ant-drawer-open');
    expect(await page.getByLabel('Mã', { exact: true }).inputValue()).toBe('');
  });
});

test.describe('Wave D Don vi — Modal Xoa @wave-d-ui', () => {
  test('TC-QTDV-026 Click Huy trong modal xoa -> dong khong xoa', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/quan-tri/don-vi');
    await page.waitForSelector('table tbody tr');
    const rowCountBefore = await page.locator('table tbody tr').count();
    // Open ba cham menu (button with aria-label="more")
    await page.locator('table tbody tr').first().getByRole('button', { name: 'more' }).click();
    await page.waitForTimeout(300);
    // Click "Xóa" menu item
    await page.locator('.ant-dropdown-menu-item', { hasText: 'Xóa' }).click();
    await expect(page.locator('.ant-modal-confirm', { hasText: 'Xác nhận xóa' })).toBeVisible();
    // Click Hủy
    await page.locator('.ant-modal-confirm').getByRole('button', { name: 'Hủy' }).click();
    await page.waitForTimeout(300);
    await expect(page.locator('.ant-modal-confirm')).toHaveCount(0);
    // Row count unchanged
    const rowCountAfter = await page.locator('table tbody tr').count();
    expect(rowCountAfter).toBe(rowCountBefore);
  });
});
