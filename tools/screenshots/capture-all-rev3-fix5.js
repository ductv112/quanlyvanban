// Round 6: open van_ban_den Chuyển lại modal via direct DOM injection.

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

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: VIEWPORT, locale: 'vi-VN' });
  const page = await context.newPage();
  await login(page);

  // Try to override fetch response to inject is_inter_doc=true
  await page.addInitScript(() => {
    const origFetch = window.fetch;
    window.fetch = async (...args) => {
      const r = await origFetch(...args);
      const url = typeof args[0] === 'string' ? args[0] : args[0].url;
      if (/\/api\/van-ban-den\/\d+(?!\/)/.test(url)) {
        const cloned = r.clone();
        try {
          const body = await cloned.json();
          if (body?.data) {
            body.data.is_inter_doc = true;
            body.data.permissions = body.data.permissions || {};
            body.data.permissions.canRetract = true;
          }
          return new Response(JSON.stringify(body), { status: r.status, headers: r.headers });
        } catch { return r; }
      }
      return r;
    };
  });

  // Re-login after init script (init script applies on next nav)
  await page.goto(`${BASE_URL}/login`, { waitUntil: 'networkidle' });
  await page.fill('input[placeholder="Nhập tên đăng nhập"]', 'admin');
  await page.fill('input[placeholder="Nhập mật khẩu"]', 'Admin@123');
  await Promise.all([
    page.waitForURL(`${BASE_URL}/dashboard`, { timeout: 15000 }),
    page.click('button[type="submit"]:has-text("Đăng nhập")'),
  ]);
  await page.waitForLoadState('networkidle');

  // Find a VB từ LGSP
  const docs = await page.evaluate(async () => {
    const token = localStorage.getItem('accessToken');
    const r = await fetch('http://localhost:4000/api/van-ban-den?page=1&page_size=20', {
      headers: { Authorization: `Bearer ${token}` },
    });
    return r.json();
  });
  const arr = docs?.data?.data || docs?.data || [];
  const lgsp = arr.find(d => d.source_type === 'external_lgsp') || arr[0];
  if (!lgsp) { console.log('No doc'); process.exit(1); }
  console.log(`Using doc id=${lgsp.id}`);

  await page.goto(`${BASE_URL}/van-ban-den/${lgsp.id}`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(2500);

  // Click "Chuyển lại" button — must be visible (not the modal okBtn which is hidden)
  const btns = page.locator('button:visible:has-text("Chuyển lại")');
  const cnt = await btns.count();
  console.log(`visible Chuyển lại buttons: ${cnt}`);
  if (cnt === 0) {
    console.log('FAIL: button Chuyển lại không xuất hiện sau khi inject is_inter_doc');
    await browser.close();
    process.exit(1);
  }
  // Click the toolbar one (has anticon-rollback icon)
  const btn = btns.filter({ has: page.locator('.anticon-rollback') }).first();
  const finalBtn = (await btn.count()) > 0 ? btn : btns.first();
  await finalBtn.click({ timeout: 5000 });
  await page.waitForTimeout(1500);

  const filePath = path.join(SCREENSHOTS_DIR, 'van_ban_den_07_modal_chuyen_lai.png');
  await page.screenshot({ path: filePath, fullPage: false });
  console.log('-> van_ban_den_07_modal_chuyen_lai.png OK');

  await browser.close();
})();
