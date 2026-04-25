// Retry detail captures using browser-context fetch (auth token in localStorage).

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

async function fetchInPage(page, apiPath) {
  return await page.evaluate(async (url) => {
    const token = localStorage.getItem('accessToken');
    const r = await fetch(url, {
      headers: { Authorization: `Bearer ${token}` },
      credentials: 'include',
    });
    if (!r.ok) return { error: r.status };
    return r.json();
  }, `http://localhost:4000/api${apiPath}`);
}

async function snap(page, file, label) {
  const filePath = path.join(SCREENSHOTS_DIR, file);
  process.stdout.write(`  → ${label.padEnd(40)} `);
  try {
    await page.screenshot({ path: filePath, fullPage: true });
    const stats = fs.statSync(filePath);
    console.log(`✓ ${(stats.size / 1024).toFixed(0)} KB`);
    return true;
  } catch (err) {
    console.log(`✗ ${err.message.split('\n')[0]}`);
    return false;
  }
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: VIEWPORT, locale: 'vi-VN' });
  const page = await context.newPage();
  await login(page);

  const detailRoutes = [
    { listApi: '/van-ban-den?page=1&page_size=1', urlBase: '/van-ban-den', file: 'van_ban_den_02_detail.png', label: 'VB đến — chi tiết' },
    { listApi: '/van-ban-di?page=1&page_size=1', urlBase: '/van-ban-di', file: 'van_ban_di_02_detail.png', label: 'VB đi — chi tiết' },
    { listApi: '/van-ban-du-thao?page=1&page_size=1', urlBase: '/van-ban-du-thao', file: 'van_ban_du_thao_02_detail.png', label: 'VB dự thảo — chi tiết' },
    { listApi: '/ho-so-cong-viec?page=1&page_size=1', urlBase: '/ho-so-cong-viec', file: 'hscv_chi_tiet_01_main.png', label: 'HSCV — chi tiết' },
  ];

  let ok = 0, fail = 0;
  for (const r of detailRoutes) {
    const json = await fetchInPage(page, r.listApi);
    if (json.error) {
      console.log(`  → ${r.label.padEnd(40)} ✗ HTTP ${json.error}`);
      fail++;
      continue;
    }
    // Try multiple shapes
    const arr = json.data?.data || json.data || json.items || [];
    const id = Array.isArray(arr) && arr.length > 0 ? arr[0].id : null;
    if (!id) {
      console.log(`  → ${r.label.padEnd(40)} ✗ no record (response shape: ${JSON.stringify(Object.keys(json)).slice(0, 60)})`);
      fail++;
      continue;
    }
    try {
      await page.goto(`${BASE_URL}${r.urlBase}/${id}`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(3000);
      if (await snap(page, r.file, `${r.urlBase}/${id}`)) ok++; else fail++;
    } catch (err) {
      console.log(`  → ${r.label.padEnd(40)} ✗ ${err.message.split('\n')[0]}`);
      fail++;
    }
  }

  await browser.close();
  console.log(`\nOK: ${ok}/${ok + fail}`);
  if (fail > 0) process.exit(1);
})();
