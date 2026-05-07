/**
 * Wave E — Quan ly So van ban (DMSV) UI test cases (subset)
 *
 * Cover UI/visual TC:
 *   - 001 3 tab phan loai (default = VB den)
 *   - 002 Switch tabs reload data
 *   - 003 Hien day du cot bang
 *   - 016 Cancel xac nhan xoa
 *   - 018 Drawer title 'Them so van ban moi'
 *   - 019 Drawer title 'Cap nhat so van ban' khi sua
 *   - 020 Cancel drawer khi them moi khong save
 *
 * Other TC duoc cover bang API/SP test trong RESULTS.md.
 *
 * Run: npx playwright test tests/wave-e-so-van-ban/ --reporter=line --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

test.use({ storageState: storageStateFor('admin') });

const URL = '/quan-tri/so-van-ban';

test.describe('Wave E DMSV — Tabs phan loai @wave-e-dmsv', () => {
  test('TC-DMSV-001 Hien thi 3 tab + tab Van ban den la default', async ({ page }) => {
    await page.goto(URL);
    await page.waitForSelector('.ant-tabs-tab', { timeout: 10000 });
    const tabsTexts = (await page.locator('.ant-tabs-tab').allInnerTexts()).map(t => t.trim());
    expect(tabsTexts).toContain('Văn bản đến');
    expect(tabsTexts).toContain('Văn bản đi');
    expect(tabsTexts).toContain('Văn bản dự thảo');
    // Active tab default = VB den
    const active = await page.locator('.ant-tabs-tab-active').innerText();
    expect(active.trim()).toBe('Văn bản đến');
  });

  test('TC-DMSV-002 Chuyen tab trigger reload data', async ({ page }) => {
    await page.goto(URL);
    await page.waitForSelector('.ant-tabs-tab', { timeout: 10000 });
    let getCalls: string[] = [];
    page.on('request', (req) => {
      if (req.method() === 'GET' && req.url().includes('/api/quan-tri/so-van-ban')) {
        getCalls.push(req.url());
      }
    });
    await page.waitForTimeout(500);
    getCalls = [];
    // Click VB di tab
    await page.getByRole('tab', { name: /Văn bản đi/ }).click();
    await page.waitForTimeout(700);
    const sawTypeId2 = getCalls.some(u => u.includes('type_id=2'));
    expect(sawTypeId2).toBeTruthy();

    getCalls = [];
    await page.getByRole('tab', { name: /Văn bản dự thảo/ }).click();
    await page.waitForTimeout(700);
    const sawTypeId3 = getCalls.some(u => u.includes('type_id=3'));
    expect(sawTypeId3).toBeTruthy();
  });
});

test.describe('Wave E DMSV — Cot bang @wave-e-dmsv', () => {
  test('TC-DMSV-003 Hien thi day du cot Ten so / Mo ta / Thu tu / Mac dinh', async ({ page }) => {
    await page.goto(URL);
    await page.waitForSelector('table thead th', { timeout: 10000 });
    const headerText = (await page.locator('table thead th').allInnerTexts()).join('|').toLowerCase();
    expect(headerText).toContain('tên sổ');
    expect(headerText).toContain('mô tả');
    expect(headerText).toContain('thứ tự');
    expect(headerText).toContain('mặc định');
  });
});

test.describe('Wave E DMSV — Drawer add/edit @wave-e-dmsv', () => {
  test('TC-DMSV-018 Drawer Them moi co tieu de + 2 nut', async ({ page }) => {
    await page.goto(URL);
    await page.waitForSelector('.ant-tabs-tab', { timeout: 10000 });
    // Switch to VB di tab per TC precondition
    await page.getByRole('tab', { name: /Văn bản đi/ }).click();
    await page.waitForTimeout(500);
    await page.getByRole('button', { name: /Thêm sổ văn bản/ }).click();
    await page.waitForSelector('.ant-drawer-open', { timeout: 5000 });
    const title = await page.locator('.ant-drawer-open .ant-drawer-title').innerText();
    expect(title).toContain('Thêm sổ văn bản mới');
    // 2 nut Huy + Them moi o ben phai (drawer extra)
    const drawer = page.locator('.ant-drawer-open');
    await expect(drawer.getByRole('button', { name: /^Hủy$/ })).toBeVisible();
    await expect(drawer.getByRole('button', { name: /Thêm mới/ })).toBeVisible();
  });

  test('TC-DMSV-020 Cancel drawer khi them moi - khong tao record', async ({ page }) => {
    await page.goto(URL);
    await page.waitForSelector('.ant-tabs-tab', { timeout: 10000 });
    await page.waitForTimeout(500);
    const beforeRows = await page.locator('table tbody tr').count();
    await page.getByRole('button', { name: /Thêm sổ văn bản/ }).click();
    await page.waitForSelector('.ant-drawer-open', { timeout: 5000 });
    // Nhap mot vai field
    await page.getByLabel('Tên sổ').fill('TC020 chua luu');
    // Click Huy
    await page.locator('.ant-drawer-open').getByRole('button', { name: /^Hủy$/ }).click();
    await page.waitForTimeout(500);
    // Drawer dong
    await expect(page.locator('.ant-drawer-open')).toHaveCount(0);
    // Khong co record moi
    const afterRows = await page.locator('table tbody tr').count();
    expect(afterRows).toBe(beforeRows);
  });

  test('TC-DMSV-019 Drawer Sua co tieu de + form da fill', async ({ page }) => {
    await page.goto(URL);
    await page.waitForSelector('.ant-table-row', { timeout: 10000 });
    await page.waitForTimeout(800);
    // AntD render 2 <table> (header sticky + body) -> dung getByRole('button', name='more')
    const moreBtn = page.getByRole('button', { name: 'more' }).first();
    await moreBtn.click();
    await page.waitForSelector('.ant-dropdown-menu', { timeout: 5000 });
    await page.getByRole('menuitem', { name: /Sửa/ }).click();
    await page.waitForSelector('.ant-drawer-open', { timeout: 5000 });
    const title = await page.locator('.ant-drawer-open .ant-drawer-title').innerText();
    expect(title).toContain('Cập nhật sổ văn bản');
    // Field Ten so phai pre-filled (non-empty)
    const nameInput = page.getByLabel('Tên sổ');
    const val = await nameInput.inputValue();
    expect(val.length).toBeGreaterThan(0);
    // 2 nut Huy + Cap nhat
    const drawer = page.locator('.ant-drawer-open');
    await expect(drawer.getByRole('button', { name: /^Hủy$/ })).toBeVisible();
    await expect(drawer.getByRole('button', { name: /Cập nhật/ })).toBeVisible();
    // Close
    await drawer.getByRole('button', { name: /^Hủy$/ }).click();
  });
});

test.describe('Wave E DMSV — Confirm xoa @wave-e-dmsv', () => {
  test('TC-DMSV-016 Huy hop xac nhan xoa - record van ton tai', async ({ page }) => {
    await page.goto(URL);
    await page.waitForSelector('.ant-table-row', { timeout: 10000 });
    await page.waitForTimeout(800);
    const beforeRows = await page.locator('.ant-table-row').count();
    if (beforeRows === 0) test.skip(true, 'Khong co record de test');

    const moreBtn = page.getByRole('button', { name: 'more' }).first();
    await moreBtn.click();
    await page.waitForSelector('.ant-dropdown-menu', { timeout: 5000 });
    await page.getByRole('menuitem', { name: /Xóa/ }).click();
    await page.waitForSelector('.ant-modal', { timeout: 5000 });
    // Click Huy
    await page.locator('.ant-modal').getByRole('button', { name: /^Hủy$/ }).click();
    await page.waitForTimeout(500);
    // Modal dong
    await expect(page.locator('.ant-modal-confirm')).toHaveCount(0);
    // Record van con
    const afterRows = await page.locator('.ant-table-row').count();
    expect(afterRows).toBe(beforeRows);
  });
});
