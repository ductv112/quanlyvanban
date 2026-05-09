/**
 * Wave D Quan tri Chuc vu (QTCV) — UI test cases
 *
 * Source: .planning/phases/25-execute-wave-d/25-RESULTS-chuc-vu.md
 *
 * No existing UI spec — this file covers UI flow for chuc vu module:
 *   TC-QTCV-001: List has 7 cols + actions (Ma, Ten, Thu tu, So NV, Lanh dao, XL VB, Trang thai)
 *   TC-QTCV-002: Pagination + page size selector visible
 *   TC-QTCV-003: Search keyword filters list (UI flow)
 *   TC-QTCV-007: Drawer Them — Empty Ten -> inline 'Nhap ten'
 *   TC-QTCV-008: Drawer Them — Empty Ma -> inline 'Nhap ma'
 *   TC-QTCV-018: Drawer mac dinh Switch Trang thai = Hoat dong (ON)
 *   TC-QTCV-019: Drawer mac dinh Switch "Duoc xu ly van ban" = Co (ON)
 *
 * Run: npx playwright test tests/wave-de-ui/qt-chuc-vu-ui.spec.ts --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

test.use({ storageState: storageStateFor('admin') });

const URL = '/quan-tri/chuc-vu';
const TEST_TIMEOUT = 25000;

async function openAddDrawer(page: any) {
  await page.goto(URL);
  await page.waitForSelector('table thead th', { timeout: 15000 });
  await page.waitForLoadState('networkidle').catch(() => {});
  await page.waitForTimeout(800);
  // Click via button.first() to disambiguate (sidebar menu also has "Chức vụ" entries)
  const addBtn = page.getByRole('button', { name: /Thêm chức vụ/ });
  await addBtn.first().waitFor({ state: 'visible', timeout: 5000 });
  await addBtn.first().click();
  await page.waitForSelector('.ant-drawer-open', { timeout: 12000 });
  await page.waitForTimeout(700);
}

test.describe('Wave D QTCV — Layout & cot @wave-d-ui', () => {
  test('TC-QTCV-001 Bang co cot Ma/Ten/Thu tu/So NV/Lanh dao/XL VB/Trang thai', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('table thead th', { timeout: 10000 });
    const headers = (await page.locator('table thead th').allInnerTexts()).join('|').toLowerCase();
    expect(headers).toContain('mã');
    expect(headers).toContain('tên chức vụ');
    expect(headers).toContain('thứ tự');
    expect(headers).toContain('số nv');
    expect(headers).toContain('lãnh đạo');
    expect(headers).toContain('xl văn bản');
    expect(headers).toContain('trạng thái');
  });

  test('TC-QTCV-002 Pagination footer + showSizeChanger + Tong N', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('table', { timeout: 10000 });
    await page.waitForTimeout(800);
    // Pagination wrapper appears (AntD .ant-pagination)
    await expect(page.locator('.ant-pagination').first()).toBeVisible();
    // Page size selector
    const sizeChanger = page.locator('.ant-pagination-options .ant-select').first();
    await expect(sizeChanger).toBeVisible();
    // Tong N text in footer (showTotal callback renders 'Tổng <n>')
    await expect(page.getByText(/Tổng\s+\d+/).first()).toBeVisible();
  });
});

test.describe('Wave D QTCV — Search @wave-d-ui', () => {
  test('TC-QTCV-003 Search keyword loc bang', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto(URL);
    await page.waitForSelector('table tbody', { timeout: 10000 });
    await page.waitForTimeout(800);

    // Capture API calls
    const reqs: string[] = [];
    page.on('request', (r) => {
      const u = r.url();
      if (u.includes('/api/quan-tri/chuc-vu') && r.method() === 'GET') reqs.push(u);
    });

    const search = page.getByPlaceholder('Tìm kiếm...');
    await search.click();
    await search.fill('Trưởng phòng');
    await search.press('Enter');
    await page.waitForTimeout(1000);
    // API trigger with keyword=
    const sawKeyword = reqs.some((u) => /keyword=Tr[%a-zA-Z0-9]/i.test(u));
    expect(sawKeyword).toBeTruthy();
  });
});

test.describe('Wave D QTCV — Drawer Them validation @wave-d-ui', () => {
  test('TC-QTCV-007 Empty Ten -> inline error', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    // Fill Ma only
    await page.getByLabel('Mã', { exact: true }).fill('UI_QTCV007');
    // Click Them moi
    await page.locator('.ant-drawer-open').getByRole('button', { name: /Thêm mới/ }).click();
    await expect(
      page.locator('.ant-form-item-explain-error', { hasText: 'Nhập tên chức vụ' })
    ).toBeVisible();
  });

  test('TC-QTCV-008 Empty Ma -> inline error', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    await page.getByLabel('Tên chức vụ', { exact: true }).fill('Test loi UI 008');
    await page.locator('.ant-drawer-open').getByRole('button', { name: /Thêm mới/ }).click();
    await expect(
      page.locator('.ant-form-item-explain-error', { hasText: 'Nhập mã' })
    ).toBeVisible();
  });
});

test.describe('Wave D QTCV — Drawer default values @wave-d-ui', () => {
  test('TC-QTCV-018 Switch Trang thai default = Hoat dong (ON)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    await page.waitForTimeout(500);
    // Form items: 0=Tên, 1=Mã, 2=Thứ tự, 3=Mô tả, 4=Lãnh đạo, 5=XL VB, 6=Trạng thái
    // Locate by exact label match using .ant-form-item-label having the exact text
    const switches = page.locator('.ant-drawer-body .ant-form-item').filter({
      has: page.locator('button[role="switch"]')
    });
    const count = await switches.count();
    expect(count).toBeGreaterThanOrEqual(3);
    // Trang thai is the LAST switch row
    const trangThaiSw = switches.last().locator('button[role="switch"]');
    const checked = await trangThaiSw.getAttribute('aria-checked');
    expect(checked).toBe('true');
  });

  test('TC-QTCV-019 Switch Duoc xu ly van ban default = Co (ON)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    await page.waitForTimeout(500);
    const switches = page.locator('.ant-drawer-body .ant-form-item').filter({
      has: page.locator('button[role="switch"]')
    });
    const count = await switches.count();
    expect(count).toBeGreaterThanOrEqual(3);
    // is_handle_document is the SECOND switch (between is_leader and is_active)
    const sw = switches.nth(1).locator('button[role="switch"]');
    const checked = await sw.getAttribute('aria-checked');
    expect(checked).toBe('true');
  });

  test('TC-QTCV-018b Switch Lanh dao default = Khong (OFF)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await openAddDrawer(page);
    await page.waitForTimeout(500);
    const switches = page.locator('.ant-drawer-body .ant-form-item').filter({
      has: page.locator('button[role="switch"]')
    });
    const count = await switches.count();
    expect(count).toBeGreaterThanOrEqual(3);
    // is_leader is the FIRST switch
    const sw = switches.first().locator('button[role="switch"]');
    const checked = await sw.getAttribute('aria-checked');
    expect(checked).toBe('false');
  });
});
