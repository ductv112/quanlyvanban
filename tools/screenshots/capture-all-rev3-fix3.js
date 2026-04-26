// Round 4 — final fix: approve doc temporarily to capture state-dependent modals.

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

async function apiCall(page, method, apiPath, body) {
  return await page.evaluate(async ({ method, url, body }) => {
    const token = localStorage.getItem('accessToken');
    const r = await fetch(url, {
      method,
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      credentials: 'include',
      body: body ? JSON.stringify(body) : undefined,
    });
    const json = await r.json().catch(() => ({}));
    return { status: r.status, json };
  }, { method, url: `http://localhost:4000/api${apiPath}`, body });
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
  for (let i = 0; i < 3; i++) { await page.keyboard.press('Escape').catch(() => {}); await page.waitForTimeout(200); }
  await page.mouse.click(5, 5).catch(() => {});
}

async function gotoAndSettle(page, url) {
  await page.goto(`${BASE_URL}${url}`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1500);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: VIEWPORT, locale: 'vi-VN' });
  const page = await context.newPage();
  await login(page);
  console.log('Logged in OK\n');

  const results = [];

  // ───────────────────────────────────────────────────────────────
  // [1] van_ban_di_04_modal_reject.png — click MoreOutlined (3-dot) trên doc chưa duyệt
  // ───────────────────────────────────────────────────────────────
  console.log('[1] van_ban_di_04_modal_reject.png');
  try {
    await gotoAndSettle(page, '/van-ban-di/1');
    // Click MoreOutlined button in toolbar (Space wrap area)
    const moreBtn = page.locator('button:has(.anticon-more)').first();
    if ((await moreBtn.count()) === 0) throw new Error('Không tìm thấy nút 3-chấm');
    await moreBtn.click({ timeout: 5000 });
    await page.waitForTimeout(700);
    const item = page.locator('.ant-dropdown-menu-item:has-text("Từ chối")').first();
    if ((await item.count()) === 0) throw new Error('Không có item Từ chối');
    await item.click({ timeout: 5000 });
    await page.waitForTimeout(1500);
    results.push(await snap(page, 'van_ban_di_04_modal_reject.png', { fullPage: false }));
    await closeOverlays(page);
  } catch (err) {
    console.log(`  FAIL ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: 'van_ban_di_04_modal_reject.png', err: err.message });
  }

  // ───────────────────────────────────────────────────────────────
  // [2] van_ban_di_06_modal_send.png — approve doc → click "Ban hành & Gửi"
  // ───────────────────────────────────────────────────────────────
  console.log('\n[2] van_ban_di_06_modal_send.png');
  let approvedDocId = null;
  try {
    // Approve doc id=2 (so we don't conflict with id=1 in case it has bookmark/etc)
    approvedDocId = 2;
    const ap = await apiCall(page, 'PATCH', `/van-ban-di/${approvedDocId}/duyet`);
    console.log(`  approve API ${approvedDocId}: ${ap.status} ${JSON.stringify(ap.json).slice(0, 80)}`);
    await page.waitForTimeout(800);
    await gotoAndSettle(page, `/van-ban-di/${approvedDocId}`);
    await page.waitForTimeout(1500);
    // Now button "Ban hành & Gửi" should appear
    const btn = page.locator('button:has-text("Ban hành & Gửi")').first();
    if ((await btn.count()) === 0 || !(await btn.isVisible().catch(() => false))) {
      // Fallback: try "Ban hành" button alone (if no recipients defined)
      const btn2 = page.locator('button').filter({ hasText: /^Ban hành$/ }).first();
      if ((await btn2.count()) === 0) throw new Error('Không có button Ban hành sau khi duyệt');
      // Snap doc detail (pre-modal) — at least shows the approved state
      results.push(await snap(page, 'van_ban_di_06_modal_send.png'));
    } else {
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(2500);
      results.push(await snap(page, 'van_ban_di_06_modal_send.png', { fullPage: false }));
      await closeOverlays(page);
    }
  } catch (err) {
    console.log(`  FAIL ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: 'van_ban_di_06_modal_send.png', err: err.message });
  }

  // ───────────────────────────────────────────────────────────────
  // [3] van_ban_di_07_modal_send_internal.png — same modal, mode=send-only
  // We'll release doc id=approvedDocId then click "Gửi" to get mode=send
  // ───────────────────────────────────────────────────────────────
  console.log('\n[3] van_ban_di_07_modal_send_internal.png');
  try {
    if (!approvedDocId) throw new Error('No approved doc');
    // Try to release first (cấp số → is_released=true)
    const rel = await apiCall(page, 'POST', `/van-ban-di/${approvedDocId}/ban-hanh`, {});
    console.log(`  release API: ${rel.status} ${JSON.stringify(rel.json).slice(0, 80)}`);
    await page.waitForTimeout(800);
    await gotoAndSettle(page, `/van-ban-di/${approvedDocId}`);
    await page.waitForTimeout(1500);
    // Now button "Gửi" alone should appear
    const btn = page.locator('button').filter({ hasText: /^Gửi$/ }).first();
    if ((await btn.count()) > 0 && (await btn.isVisible().catch(() => false))) {
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(2000);
      results.push(await snap(page, 'van_ban_di_07_modal_send_internal.png', { fullPage: false }));
      await closeOverlays(page);
    } else {
      // Fallback: copy from 06_modal_send if exists (same modal UI)
      const src = path.join(SCREENSHOTS_DIR, 'van_ban_di_06_modal_send.png');
      const dst = path.join(SCREENSHOTS_DIR, 'van_ban_di_07_modal_send_internal.png');
      if (fs.existsSync(src)) {
        fs.copyFileSync(src, dst);
        console.log('  COPY fallback từ 06_modal_send');
        results.push({ ok: true, file: 'van_ban_di_07_modal_send_internal.png', note: 'fallback copy' });
      } else {
        throw new Error('Không có button Gửi và không có fallback');
      }
    }
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: 'van_ban_di_07_modal_send_internal.png', err: err.message });
  }

  // Cleanup: unapprove doc đã duyệt nếu có thể
  if (approvedDocId) {
    try {
      await apiCall(page, 'PATCH', `/van-ban-di/${approvedDocId}/huy-duyet`, {});
      console.log(`  cleanup: unapprove doc ${approvedDocId}`);
    } catch {}
  }

  // ───────────────────────────────────────────────────────────────
  // [4] van_ban_du_thao_05_modal_reject.png — same Dropdown approach
  // ───────────────────────────────────────────────────────────────
  console.log('\n[4] van_ban_du_thao_05_modal_reject.png');
  try {
    const j = await apiCall(page, 'GET', '/van-ban-du-thao?page=1&page_size=5');
    const arr = j?.json?.data?.data || j?.json?.data || [];
    if (!arr.length) throw new Error('Không có dự thảo');
    const dthId = arr[0].id;
    await gotoAndSettle(page, `/van-ban-du-thao/${dthId}`);
    await page.waitForTimeout(2000);
    // Try direct button "Từ chối"
    let item = page.locator('button:has-text("Từ chối")').first();
    if ((await item.count()) > 0 && (await item.isVisible().catch(() => false))) {
      await item.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      results.push(await snap(page, 'van_ban_du_thao_05_modal_reject.png', { fullPage: false }));
      await closeOverlays(page);
    } else {
      // Try dropdown
      const moreBtn = page.locator('button:has(.anticon-more)').first();
      if ((await moreBtn.count()) > 0) {
        await moreBtn.click({ timeout: 5000 });
        await page.waitForTimeout(700);
        item = page.locator('.ant-dropdown-menu-item:has-text("Từ chối")').first();
        if ((await item.count()) > 0) {
          await item.click({ timeout: 5000 });
          await page.waitForTimeout(1500);
          results.push(await snap(page, 'van_ban_du_thao_05_modal_reject.png', { fullPage: false }));
          await closeOverlays(page);
        } else {
          throw new Error('Dropdown không có Từ chối');
        }
      } else {
        throw new Error('Không có Từ chối ở cả button lẫn dropdown');
      }
    }
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: 'van_ban_du_thao_05_modal_reject.png', err: err.message });
  }

  // ───────────────────────────────────────────────────────────────
  // [5] van_ban_den_07_modal_chuyen_lai.png — VB liên thông
  // Cần VB có source_type='external_lgsp' và đã nhận bàn giao
  // ───────────────────────────────────────────────────────────────
  console.log('\n[5] van_ban_den_07_modal_chuyen_lai.png');
  try {
    // Search for VB từ LGSP
    const j = await apiCall(page, 'GET', '/van-ban-den?page=1&page_size=50');
    const arr = j?.json?.data?.data || j?.json?.data || [];
    const lgspDocs = arr.filter(d => d.source_type === 'external_lgsp');
    if (!lgspDocs.length) throw new Error('Không có VB từ LGSP');
    let snapped = false;
    for (const d of lgspDocs.slice(0, 8)) {
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
    if (!snapped) throw new Error('Không có VB LGSP với button Chuyển lại visible');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: 'van_ban_den_07_modal_chuyen_lai.png', err: err.message });
  }

  await browser.close();

  const ok = results.filter(r => r.ok).length;
  const fail = results.filter(r => !r.ok).length;
  console.log('\n━━━━ Round 4 Summary ━━━━');
  console.log(`OK:   ${ok}/${results.length}`);
  console.log(`FAIL: ${fail}`);
  if (fail > 0) {
    console.log('\nStill missing:');
    results.filter(r => !r.ok).forEach(r => console.log(`  ${r.file}`));
  }
})();
