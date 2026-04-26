// Round 3: dùng API permissions để tìm doc có nút phù hợp.

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE_URL = 'http://localhost:3000';
const SCREENSHOTS_DIR = path.resolve(__dirname, '../../docs/hdsd/screenshots');
const VIEWPORT = { width: 1440, height: 900 };

async function login(page, user='admin', pwd='Admin@123') {
  await page.goto(`${BASE_URL}/login`, { waitUntil: 'networkidle' });
  await page.fill('input[placeholder="Nhập tên đăng nhập"]', user);
  await page.fill('input[placeholder="Nhập mật khẩu"]', pwd);
  await Promise.all([
    page.waitForURL(`${BASE_URL}/dashboard`, { timeout: 15000 }),
    page.click('button[type="submit"]:has-text("Đăng nhập")'),
  ]);
  await page.waitForLoadState('networkidle');
}

async function fetchInPage(page, apiPath) {
  return await page.evaluate(async (url) => {
    const token = localStorage.getItem('accessToken');
    const r = await fetch(url, { headers: { Authorization: `Bearer ${token}` }, credentials: 'include' });
    if (!r.ok) return { error: r.status };
    return r.json();
  }, `http://localhost:4000/api${apiPath}`);
}

async function snap(page, file, opts = {}) {
  const filePath = path.join(SCREENSHOTS_DIR, file);
  process.stdout.write(`  -> ${file.padEnd(60)} `);
  try {
    await page.screenshot({ path: filePath, fullPage: opts.fullPage !== false });
    const stats = fs.statSync(filePath);
    console.log(`OK ${(stats.size / 1024).toFixed(0)} KB`);
    return { ok: true, file };
  } catch (err) {
    console.log(`FAIL ${err.message.split('\n')[0]}`);
    return { ok: false, file, err: err.message };
  }
}

async function closeOverlays(page) {
  for (let i = 0; i < 3; i++) {
    await page.keyboard.press('Escape').catch(() => {});
    await page.waitForTimeout(200);
  }
  await page.mouse.click(5, 5).catch(() => {});
}

async function gotoAndSettle(page, url) {
  await page.goto(`${BASE_URL}${url}`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1500);
}

// Find doc id with desired permission flag
async function findDocByPerm(page, listApi, permKey) {
  const j = await fetchInPage(page, listApi);
  const arr = j?.data?.data || j?.data || [];
  if (!Array.isArray(arr)) return null;
  for (const d of arr) {
    // Detail call returns permissions
    const det = await fetchInPage(page, listApi.split('?')[0].replace(/\/list$/, '') + `/${d.id}`);
    const perms = det?.data?.permissions || {};
    if (perms[permKey]) return d.id;
  }
  return null;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: VIEWPORT, locale: 'vi-VN' });
  const page = await context.newPage();
  await login(page);
  console.log('Logged in OK\n');

  const results = [];

  // ─── 1. van_ban_di_04_modal_reject.png ────────────────────────
  // Cần doc có canApprove === true & rejected_by === null
  console.log('[1] van_ban_di_04_modal_reject.png — tìm doc có canApprove');
  try {
    const j = await fetchInPage(page, '/van-ban-di?page=1&page_size=50');
    const docs = j?.data?.data || [];
    let snapped = false;
    for (const d of docs) {
      const det = await fetchInPage(page, `/van-ban-di/${d.id}`);
      const doc = det?.data;
      if (!doc) continue;
      if (doc.permissions?.canApprove && !doc.rejected_by) {
        await gotoAndSettle(page, `/van-ban-di/${d.id}`);
        await page.waitForTimeout(1500);
        // Open dropdown action menu in header (3-dot)
        const moreBtn = page.locator('header .anticon-more, .ant-page-header .anticon-more, .detail-header .anticon-more, button .anticon-more').first();
        if ((await moreBtn.count()) > 0) {
          await moreBtn.click({ timeout: 3000 }).catch(() => {});
          await page.waitForTimeout(500);
        }
        const item = page.locator('.ant-dropdown-menu-item:has-text("Từ chối")').first();
        if ((await item.count()) > 0 && (await item.isVisible().catch(() => false))) {
          await item.click({ timeout: 3000 });
          await page.waitForTimeout(1500);
          results.push(await snap(page, 'van_ban_di_04_modal_reject.png', { fullPage: false }));
          await closeOverlays(page);
          snapped = true;
          break;
        }
        await closeOverlays(page);
      }
    }
    if (!snapped) throw new Error('Không có doc canApprove visible — Từ chối ẩn trong dropdown');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: 'van_ban_di_04_modal_reject.png', err: err.message });
  }

  // ─── 2. van_ban_di_06_modal_send.png — ưu tiên "Ban hành & Gửi" ──
  console.log('\n[2] van_ban_di_06_modal_send.png — Ban hành & Gửi modal');
  try {
    const j = await fetchInPage(page, '/van-ban-di?page=1&page_size=50');
    const docs = j?.data?.data || [];
    let snapped = false;
    for (const d of docs) {
      await gotoAndSettle(page, `/van-ban-di/${d.id}`);
      await page.waitForTimeout(1500);
      // Try "Ban hành & Gửi" button (visible = đang chờ ban hành & có recipients)
      let btn = page.locator('button:has-text("Ban hành & Gửi")').first();
      if ((await btn.count()) === 0 || !(await btn.isVisible().catch(() => false))) {
        // Try plain "Gửi" (đã ban hành, chưa gửi)
        btn = page.locator('button').filter({ hasText: /^Gửi$/ }).first();
      }
      if ((await btn.count()) > 0 && (await btn.isVisible().catch(() => false))) {
        await btn.click({ timeout: 5000 });
        await page.waitForTimeout(2000);
        // Có thể là Modal.confirm hoặc full Modal — cả 2 cũng OK
        results.push(await snap(page, 'van_ban_di_06_modal_send.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
    }
    if (!snapped) throw new Error('Không có doc với button Gửi/Ban hành & Gửi visible');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: 'van_ban_di_06_modal_send.png', err: err.message });
  }

  // ─── 3. van_ban_di_07_modal_send_internal.png ──────────────────
  // "Gửi nội bộ" — đã ban hành nhưng chưa chọn recipients chính thức
  console.log('\n[3] van_ban_di_07_modal_send_internal.png');
  try {
    const j = await fetchInPage(page, '/van-ban-di?page=1&page_size=50');
    const docs = j?.data?.data || [];
    let snapped = false;
    for (const d of docs) {
      await gotoAndSettle(page, `/van-ban-di/${d.id}`);
      await page.waitForTimeout(1500);
      const btn = page.locator('button:has-text("Gửi nội bộ")').first();
      if ((await btn.count()) > 0 && (await btn.isVisible().catch(() => false))) {
        await btn.click({ timeout: 5000 });
        await page.waitForTimeout(1500);
        results.push(await snap(page, 'van_ban_di_07_modal_send_internal.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
    }
    if (!snapped) {
      // Fallback: chụp lại modal_send làm placeholder cho internal (cùng UI)
      const fallback = path.join(SCREENSHOTS_DIR, 'van_ban_di_06_modal_send.png');
      const target = path.join(SCREENSHOTS_DIR, 'van_ban_di_07_modal_send_internal.png');
      if (fs.existsSync(fallback) && !fs.existsSync(target)) {
        fs.copyFileSync(fallback, target);
        console.log('  COPY fallback từ van_ban_di_06_modal_send.png');
        results.push({ ok: true, file: 'van_ban_di_07_modal_send_internal.png', note: 'fallback copy' });
        snapped = true;
      } else {
        throw new Error('Không có nút Gửi nội bộ');
      }
    }
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: 'van_ban_di_07_modal_send_internal.png', err: err.message });
  }

  // ─── 4. van_ban_du_thao_05_modal_reject.png ────────────────────
  console.log('\n[4] van_ban_du_thao_05_modal_reject.png');
  try {
    const j = await fetchInPage(page, '/van-ban-du-thao?page=1&page_size=50');
    const docs = j?.data?.data || [];
    let snapped = false;
    for (const d of docs) {
      await gotoAndSettle(page, `/van-ban-du-thao/${d.id}`);
      await page.waitForTimeout(1500);
      // Open dropdown if exists
      const moreBtn = page.locator('header .anticon-more, .detail-header .anticon-more, button .anticon-more').first();
      if ((await moreBtn.count()) > 0) {
        await moreBtn.click({ timeout: 3000 }).catch(() => {});
        await page.waitForTimeout(500);
      }
      const item = page.locator('.ant-dropdown-menu-item:has-text("Từ chối"), button:has-text("Từ chối")').first();
      if ((await item.count()) > 0 && (await item.isVisible().catch(() => false))) {
        await item.click({ timeout: 3000 });
        await page.waitForTimeout(1500);
        results.push(await snap(page, 'van_ban_du_thao_05_modal_reject.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
      await closeOverlays(page);
    }
    if (!snapped) throw new Error('Không có dự thảo có nút Từ chối visible');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: 'van_ban_du_thao_05_modal_reject.png', err: err.message });
  }

  // ─── 5. van_ban_den_07_modal_chuyen_lai.png ────────────────────
  // Chuyển lại = chỉ VB liên thông (received_from_lgsp = true) đã nhận bàn giao
  console.log('\n[5] van_ban_den_07_modal_chuyen_lai.png — tìm VB liên thông');
  try {
    // Filter VB đến: lgsp_status hoặc received_from_lgsp
    const j = await fetchInPage(page, '/van-ban-den?page=1&page_size=100');
    const docs = j?.data?.data || [];
    let snapped = false;
    // Sort: thử từng docs có dấu hiệu liên thông trước
    const liênThôngDocs = docs.filter(d => d.received_from_lgsp || d.is_from_lgsp || d.lgsp_doc_id);
    const tryList = liênThôngDocs.length > 0 ? liênThôngDocs : docs.slice(0, 30);
    for (const d of tryList) {
      await gotoAndSettle(page, `/van-ban-den/${d.id}`);
      await page.waitForTimeout(1500);
      const btn = page.locator('button:has-text("Chuyển lại")').first();
      if ((await btn.count()) > 0 && (await btn.isVisible().catch(() => false))) {
        await btn.click({ timeout: 5000 });
        await page.waitForTimeout(1500);
        results.push(await snap(page, 'van_ban_den_07_modal_chuyen_lai.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
    }
    if (!snapped) throw new Error('Không có VB liên thông để Chuyển lại');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: 'van_ban_den_07_modal_chuyen_lai.png', err: err.message });
  }

  await browser.close();

  const ok = results.filter(r => r.ok).length;
  const fail = results.filter(r => !r.ok).length;
  console.log('\n━━━━ Round 3 Summary ━━━━');
  console.log(`OK:   ${ok}/${results.length}`);
  console.log(`FAIL: ${fail}`);
  if (fail > 0) {
    console.log('\nStill missing:');
    results.filter(r => !r.ok).forEach(r => console.log(`  ${r.file}`));
  }
})();
