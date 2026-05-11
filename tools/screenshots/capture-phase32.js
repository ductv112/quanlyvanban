// Phase 32 — focused recapture of 6 screenshots flagged by 32-AUDIT-REPORT.md.
// Each capture is wrapped in try/catch so a single failure does not abort the batch.
//
// Targets (per docs/hdsd/screenshots/<file>):
//   1. dashboard_01_main.png                — /dashboard
//   2. van_ban_den_04_detail.png            — /van-ban-den/<id>
//   3. van_ban_den_06_drawer_giao_viec.png  — VB đến detail → Giao việc drawer (always visible)
//   4. van_ban_di_05_detail.png             — /van-ban-di/<id> (released doc, full layout)
//   5. van_ban_di_07_modal_send_internal.png — VB đi detail → "Ban hành & Gửi" modal
//                                              (requires approved=true && is_released=false)
//   6. van_ban_di_08_drawer_giao_viec.png   — VB đi detail → Giao việc drawer (canApprove required)
//
// Pre-requisites (verified by orchestrator before launch):
//   - Backend running at http://localhost:4000
//   - Frontend running at http://localhost:3000
//   - DB seeded with seed/001 + seed/002 (admin / Admin@123 works)
//
// Viewport: 1440x900 — matches all existing screenshots in docs/hdsd/screenshots/.

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE_URL = 'http://localhost:3000';
const API_URL = 'http://localhost:4000';
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

async function apiFetch(page, urlPath) {
  return await page.evaluate(async (url) => {
    const token = localStorage.getItem('accessToken');
    const r = await fetch(url, { headers: { Authorization: `Bearer ${token}` }, credentials: 'include' });
    if (!r.ok) return { __error: r.status };
    return r.json();
  }, `${API_URL}${urlPath}`);
}

async function snap(page, file, opts = {}) {
  const filePath = path.join(SCREENSHOTS_DIR, file);
  const fullPage = opts.fullPage !== false;
  process.stdout.write(`  -> ${file.padEnd(50)} `);
  try {
    await page.screenshot({ path: filePath, fullPage });
    const stats = fs.statSync(filePath);
    console.log(`OK ${(stats.size / 1024).toFixed(0)} KB`);
    return { ok: true, file, size: stats.size };
  } catch (err) {
    const msg = err.message.split('\n')[0];
    console.log(`FAIL ${msg}`);
    return { ok: false, file, err: msg };
  }
}

async function closeOverlays(page) {
  try {
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    await page.mouse.click(10, 10);
    await page.waitForTimeout(300);
  } catch { /* best-effort */ }
}

async function gotoAndSettle(page, url, extraWaitMs = 2000) {
  await page.goto(`${BASE_URL}${url}`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(extraWaitMs);
}

async function runCase(label, fn, results) {
  console.log(`\n[${label}]`);
  try {
    const r = await fn();
    if (r) results.push(r);
  } catch (err) {
    const msg = err.message.split('\n')[0];
    console.log(`  FAIL ${msg}`);
    results.push({ ok: false, file: label, err: msg });
  }
}

(async () => {
  if (!fs.existsSync(SCREENSHOTS_DIR)) fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true });

  console.log(`Output dir: ${SCREENSHOTS_DIR}`);
  console.log('Launching browser (headless)...');
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: VIEWPORT, locale: 'vi-VN' });
  const page = await context.newPage();

  await login(page);
  console.log('Logged in OK\n');

  const results = [];

  // ── 1. Dashboard main ────────────────────────────────────────────
  await runCase('1:dashboard_01_main.png', async () => {
    await gotoAndSettle(page, '/dashboard', 2500);
    return await snap(page, 'dashboard_01_main.png');
  }, results);

  // ── Pick VB đến doc for cases 2 & 3 ──────────────────────────────
  const vbDenList = await apiFetch(page, '/api/van-ban-den?page=1&page_size=5');
  const vbDenDocs = vbDenList?.data || [];
  if (vbDenDocs.length === 0) {
    console.log('\n[!] Không có VB đến nào — skip cases 2 & 3');
  } else {
    const vbDenId = vbDenDocs[0].id;
    console.log(`\n[*] VB đến target id=${vbDenId}`);

    // ── 2. VB đến detail ───────────────────────────────────────────
    await runCase('2:van_ban_den_04_detail.png', async () => {
      await gotoAndSettle(page, `/van-ban-den/${vbDenId}`, 2500);
      return await snap(page, 'van_ban_den_04_detail.png');
    }, results);

    // ── 3. VB đến drawer Giao việc (always visible) ───────────────
    await runCase('3:van_ban_den_06_drawer_giao_viec.png', async () => {
      await gotoAndSettle(page, `/van-ban-den/${vbDenId}`, 2500);
      const btn = page.locator('button').filter({ hasText: /^Giao việc$/i }).first();
      if (await btn.count() === 0) throw new Error('Không thấy nút "Giao việc" trên trang chi tiết VB đến');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_den_06_drawer_giao_viec.png');
      await closeOverlays(page);
      return r;
    }, results);
  }

  // ── Pick VB đi docs for cases 4, 5, 6 ────────────────────────────
  const vbDiList = await apiFetch(page, '/api/van-ban-di?page=1&page_size=100');
  const vbDiDocs = vbDiList?.data || [];
  if (vbDiDocs.length === 0) {
    console.log('\n[!] Không có VB đi nào — skip cases 4, 5, 6');
  } else {
    // For _05_detail.png: prefer a released ('sent') doc to show full status badge layout
    const sentDoc = vbDiDocs.find(d => d.is_released === true && d.status === 'sent') || vbDiDocs[0];
    // For _07_modal_send_internal: need approved=true AND is_released=false
    const releasableDoc = vbDiDocs.find(d => d.approved === true && d.is_released === false);
    // For _08_drawer_giao_viec: need canApprove=true (any approved doc works)
    const giaoViecDoc = vbDiDocs.find(d => d.permissions?.canApprove === true) || sentDoc;

    console.log(`\n[*] VB đi targets: detail=${sentDoc?.id} releasable=${releasableDoc?.id ?? 'NONE'} giaoViec=${giaoViecDoc?.id}`);

    // ── 4. VB đi detail ────────────────────────────────────────────
    await runCase('4:van_ban_di_05_detail.png', async () => {
      await gotoAndSettle(page, `/van-ban-di/${sentDoc.id}`, 2500);
      return await snap(page, 'van_ban_di_05_detail.png');
    }, results);

    // ── 5. VB đi modal "Ban hành & Gửi" ────────────────────────────
    await runCase('5:van_ban_di_07_modal_send_internal.png', async () => {
      if (!releasableDoc) {
        throw new Error('Không có VB đi với approved=true && is_released=false trong DB');
      }
      await gotoAndSettle(page, `/van-ban-di/${releasableDoc.id}`, 2500);
      // The button is the exact text "Ban hành & Gửi" (page.tsx line 495)
      const btn = page.locator('button:has-text("Ban hành & Gửi")').first();
      if (await btn.count() === 0) {
        throw new Error('Không thấy nút "Ban hành & Gửi" (canRelease && canSend không thoả)');
      }
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1800);
      // Modal title contains "chọn đơn vị nhận"
      const modal = page.locator('.ant-modal-content:has-text("chọn đơn vị nhận")').first();
      if (await modal.count() === 0) {
        throw new Error('Modal "chọn đơn vị nhận" không mở');
      }
      const r = await snap(page, 'van_ban_di_07_modal_send_internal.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);

    // ── 6. VB đi drawer Giao việc ─────────────────────────────────
    await runCase('6:van_ban_di_08_drawer_giao_viec.png', async () => {
      await gotoAndSettle(page, `/van-ban-di/${giaoViecDoc.id}`, 2500);
      // Per page.tsx line 459: button "Giao việc" requires canApprove
      const btn = page.locator('button:has-text("Giao việc")').first();
      if (await btn.count() === 0) {
        throw new Error('Không thấy nút "Giao việc" (canApprove không thoả)');
      }
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      // Drawer title is "Giao việc"
      const drawer = page.locator('.ant-drawer-title:has-text("Giao việc")').first();
      if (await drawer.count() === 0) {
        throw new Error('Drawer "Giao việc" không mở');
      }
      const r = await snap(page, 'van_ban_di_08_drawer_giao_viec.png');
      await closeOverlays(page);
      return r;
    }, results);
  }

  await browser.close();

  // ── Summary ────────────────────────────────────────────────────
  const ok = results.filter(r => r.ok).length;
  const fail = results.filter(r => !r.ok).length;
  console.log('\n──── Summary ────');
  console.log(`OK:   ${ok}/${results.length}`);
  console.log(`FAIL: ${fail}`);
  if (fail > 0) {
    console.log('\nFailed:');
    results.filter(r => !r.ok).forEach(r => console.log(`  ${r.file}: ${r.err}`));
    process.exit(1);
  }
})();
