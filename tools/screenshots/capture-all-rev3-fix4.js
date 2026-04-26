// Round 5 - dự thảo Từ chối modal (need fresh draft, click MoreOutlined dropdown).

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE_URL = 'http://localhost:3000';
const SCREENSHOTS_DIR = path.resolve(__dirname, '../../docs/hdsd/screenshots');
const VIEWPORT = { width: 1440, height: 900 };

async function login(page) {
  await page.goto(`${BASE_URL}/login`, { waitUntil: 'networkidle' });
  await page.fill('input[placeholder="Nhập tên đăng nhập"]', 'admin');
  await page.fill('input[placeholder="Nhập mật khẩu"]', 'Admin@123');
  await Promise.all([
    page.waitForURL(`${BASE_URL}/dashboard`, { timeout: 15000 }),
    page.click('button[type="submit"]:has-text("Đăng nhập")'),
  ]);
  await page.waitForLoadState('networkidle');
}

async function apiCall(page, method, apiPath) {
  return await page.evaluate(async ({ method, url }) => {
    const token = localStorage.getItem('accessToken');
    const r = await fetch(url, { method, headers: { Authorization: `Bearer ${token}` }, credentials: 'include' });
    return r.json().catch(() => ({}));
  }, { method, url: `http://localhost:4000/api${apiPath}` });
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: VIEWPORT, locale: 'vi-VN' });
  const page = await context.newPage();
  await login(page);
  console.log('Logged in OK\n');

  // Find a draft NOT yet rejected
  const list = await apiCall(page, 'GET', '/van-ban-du-thao?page=1&page_size=10');
  const arr = list?.data?.data || list?.data || [];
  console.log(`Found ${arr.length} drafts`);
  let snapped = false;
  for (const d of arr.slice(0, 5)) {
    if (d.rejected_by) continue;
    if (d.approved) continue;
    if (d.is_released) continue;
    await page.goto(`${BASE_URL}/van-ban-du-thao/${d.id}`, { waitUntil: 'networkidle', timeout: 30000 });
    await page.waitForTimeout(2500);

    // Click MoreOutlined button (3-dot)
    const moreBtn = page.locator('button:has(.anticon-more)').first();
    const cnt = await moreBtn.count();
    console.log(`  doc ${d.id}: more buttons = ${cnt}`);
    if (cnt === 0) continue;
    await moreBtn.click({ timeout: 5000 });
    await page.waitForTimeout(800);
    const item = page.locator('.ant-dropdown-menu-item:has-text("Từ chối")').first();
    if ((await item.count()) === 0) {
      await page.keyboard.press('Escape');
      console.log(`  doc ${d.id}: dropdown không có Từ chối`);
      continue;
    }
    await item.click({ timeout: 5000 });
    await page.waitForTimeout(2000);
    const filePath = path.join(SCREENSHOTS_DIR, 'van_ban_du_thao_05_modal_reject.png');
    await page.screenshot({ path: filePath, fullPage: false });
    console.log(`  -> van_ban_du_thao_05_modal_reject.png OK`);
    snapped = true;
    break;
  }

  if (!snapped) {
    console.log('  WARN: không capture được — có thể tất cả drafts đều bị admin reject');
  }

  await browser.close();
})();
