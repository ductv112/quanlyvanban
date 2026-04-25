// Capture detail screenshots: HSCV báo cáo retry + detail pages + drawers + bell.
// Requires backend (4000) + frontend (3000) running.

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE_URL = 'http://localhost:3000';
const API_URL = 'http://localhost:4000/api';
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

// Fetch first ID from a list endpoint (uses cookies from page context)
async function fetchFirstId(page, listUrl) {
  const resp = await page.request.get(listUrl);
  if (!resp.ok()) {
    console.log(`    fetch ${listUrl}: ${resp.status()}`);
    return null;
  }
  const json = await resp.json();
  const arr = json.data?.data || json.data || [];
  return Array.isArray(arr) && arr.length > 0 ? arr[0].id : null;
}

async function snap(page, file, label) {
  const filePath = path.join(SCREENSHOTS_DIR, file);
  process.stdout.write(`  → ${label.padEnd(50)} `);
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

  let ok = 0;
  let fail = 0;
  const tally = (b) => { if (b) ok++; else fail++; };

  // ─── 1. HSCV báo cáo retry ────────────────────────────────────────
  console.log('[1] HSCV báo cáo (retry with 60s timeout)');
  try {
    await page.goto(`${BASE_URL}/ho-so-cong-viec/bao-cao`, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(8000); // wait for stats SP to finish
    tally(await snap(page, 'hscv_bao_cao_01_main.png', '/ho-so-cong-viec/bao-cao'));
  } catch (err) {
    console.log(`    fail: ${err.message.split('\n')[0]}`);
    fail++;
  }

  // ─── 2. Detail pages ──────────────────────────────────────────────
  console.log('\n[2] Detail pages');
  const detailRoutes = [
    { listApi: '/van-ban-den?page=1&page_size=1', urlBase: '/van-ban-den', file: 'van_ban_den_02_detail.png', label: 'Văn bản đến — chi tiết' },
    { listApi: '/van-ban-di?page=1&page_size=1', urlBase: '/van-ban-di', file: 'van_ban_di_02_detail.png', label: 'Văn bản đi — chi tiết' },
    { listApi: '/van-ban-du-thao?page=1&page_size=1', urlBase: '/van-ban-du-thao', file: 'van_ban_du_thao_02_detail.png', label: 'Văn bản dự thảo — chi tiết' },
    { listApi: '/ho-so-cong-viec?page=1&page_size=1', urlBase: '/ho-so-cong-viec', file: 'hscv_chi_tiet_01_main.png', label: 'HSCV — chi tiết' },
  ];

  for (const r of detailRoutes) {
    const id = await fetchFirstId(page, `${API_URL}${r.listApi}`);
    if (!id) {
      console.log(`  → ${r.label.padEnd(50)} ✗ no record found`);
      fail++;
      continue;
    }
    try {
      await page.goto(`${BASE_URL}${r.urlBase}/${id}`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(3000);
      tally(await snap(page, r.file, `${r.urlBase}/${id}`));
    } catch (err) {
      console.log(`  → ${r.label.padEnd(50)} ✗ ${err.message.split('\n')[0]}`);
      fail++;
    }
  }

  // ─── 3. Add drawer for key admin pages ────────────────────────────
  console.log('\n[3] Add drawers');
  const drawerRoutes = [
    { url: '/quan-tri/don-vi', addBtnText: 'Thêm đơn vị', file: 'quan_tri_don_vi_02_add_drawer.png', label: 'Đơn vị — Drawer Thêm' },
    { url: '/quan-tri/chuc-vu', addBtnText: 'Thêm', file: 'quan_tri_chuc_vu_02_add_drawer.png', label: 'Chức vụ — Drawer Thêm' },
    { url: '/quan-tri/linh-vuc', addBtnText: 'Thêm lĩnh vực', file: 'quan_tri_linh_vuc_02_add_drawer.png', label: 'Lĩnh vực — Drawer Thêm' },
    { url: '/quan-tri/loai-van-ban', addBtnText: 'Thêm', file: 'quan_tri_loai_van_ban_02_add_drawer.png', label: 'Loại VB — Drawer Thêm' },
    { url: '/quan-tri/so-van-ban', addBtnText: 'Thêm', file: 'quan_tri_so_van_ban_02_add_drawer.png', label: 'Sổ VB — Drawer Thêm' },
  ];

  for (const r of drawerRoutes) {
    try {
      await page.goto(`${BASE_URL}${r.url}`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(1500);
      // Click any button containing the add text
      const btn = page.locator(`button:has-text("${r.addBtnText}")`).first();
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500); // wait for drawer animation
      tally(await snap(page, r.file, r.label));
      // Close drawer (Esc or click cancel)
      await page.keyboard.press('Escape');
      await page.waitForTimeout(500);
    } catch (err) {
      console.log(`  → ${r.label.padEnd(50)} ✗ ${err.message.split('\n')[0]}`);
      fail++;
    }
  }

  // ─── 4. Bell notification dropdown ────────────────────────────────
  console.log('\n[4] Bell notification dropdown (header)');
  try {
    await page.goto(`${BASE_URL}/dashboard`, { waitUntil: 'networkidle' });
    await page.waitForTimeout(1500);
    // Bell is in header — click the BellOutlined icon in main-header-right
    const bellBtn = page.locator('.main-header-right [class*="BellOutlined"], .main-header-right button:has(svg[data-icon="bell"]), .main-header-right svg[data-icon="bell"]').first();
    await bellBtn.click({ timeout: 5000 });
    await page.waitForTimeout(1000);
    tally(await snap(page, 'thong_bao_02_bell.png', 'Bell dropdown'));
  } catch (err) {
    console.log(`  → Bell dropdown                                     ✗ ${err.message.split('\n')[0]}`);
    fail++;
  }

  await browser.close();

  console.log('\n──── Summary ────');
  console.log(`OK:   ${ok}`);
  console.log(`FAIL: ${fail}`);
  if (fail > 0) process.exit(1);
})();
