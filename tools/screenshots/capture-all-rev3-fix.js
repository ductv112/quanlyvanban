// Round 2: capture remaining 9 missing screenshots after first run.
// Strategy: more specific selectors + try multiple records to find one in correct state.

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

async function fetchList(page, listApi) {
  try {
    const json = await page.evaluate(async (url) => {
      const token = localStorage.getItem('accessToken');
      const r = await fetch(url, { headers: { Authorization: `Bearer ${token}` }, credentials: 'include' });
      if (!r.ok) return { error: r.status };
      return r.json();
    }, `http://localhost:4000/api${listApi}`);
    if (json?.error) return [];
    const arr = json?.data?.data || json?.data || [];
    return Array.isArray(arr) ? arr : [];
  } catch { return []; }
}

async function snap(page, file, opts = {}) {
  const filePath = path.join(SCREENSHOTS_DIR, file);
  const fullPage = opts.fullPage !== false;
  process.stdout.write(`  -> ${file.padEnd(60)} `);
  try {
    await page.screenshot({ path: filePath, fullPage });
    const stats = fs.statSync(filePath);
    console.log(`OK ${(stats.size / 1024).toFixed(0)} KB`);
    return { ok: true, file };
  } catch (err) {
    console.log(`FAIL ${err.message.split('\n')[0]}`);
    return { ok: false, file, err: err.message };
  }
}

async function closeOverlays(page) {
  try {
    for (let i = 0; i < 3; i++) {
      await page.keyboard.press('Escape');
      await page.waitForTimeout(200);
    }
    await page.mouse.click(5, 5);
    await page.waitForTimeout(200);
  } catch {}
}

async function gotoAndSettle(page, url) {
  await page.goto(`${BASE_URL}${url}`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1500);
}

// Find a doc in given status by paging through results
async function findDocInStatus(page, listApi, statusFilter) {
  for (let p = 1; p <= 5; p++) {
    const docs = await fetchList(page, `${listApi}&page=${p}&page_size=20`);
    if (docs.length === 0) break;
    const match = docs.find(statusFilter);
    if (match) return match;
  }
  return null;
}

// Open row dropdown by row index, click an item by exact text
async function openRowMenuByIndex(page, rowIdx, itemTextRegex) {
  const row = page.locator('.ant-table-row').nth(rowIdx);
  const moreBtn = row.locator('.anticon-more').first();
  await moreBtn.scrollIntoViewIfNeeded();
  await moreBtn.click({ timeout: 8000 });
  await page.waitForTimeout(500);
  const menuItems = page.locator('.ant-dropdown-menu-item');
  const cnt = await menuItems.count();
  for (let i = 0; i < cnt; i++) {
    const text = (await menuItems.nth(i).textContent()) || '';
    if (itemTextRegex.test(text)) {
      await menuItems.nth(i).click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      return true;
    }
  }
  await page.keyboard.press('Escape');
  return false;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: VIEWPORT, locale: 'vi-VN' });
  const page = await context.newPage();
  await login(page);
  console.log('Logged in OK\n');

  const results = [];
  const tally = (r) => results.push(r);

  // ─── 1. quan_tri_nguoi_dung_03_drawer_sua.png ─────────────────
  // Menu key in code: "Sửa thông tin" (NOT "Chỉnh sửa")
  console.log('[1] quan_tri_nguoi_dung_03_drawer_sua.png');
  try {
    await gotoAndSettle(page, '/quan-tri/nguoi-dung');
    const ok = await openRowMenuByIndex(page, 0, /Sửa thông tin/);
    if (!ok) throw new Error('Không tìm thấy menu Sửa thông tin');
    tally(await snap(page, 'quan_tri_nguoi_dung_03_drawer_sua.png'));
    await closeOverlays(page);
  } catch (err) {
    console.log(`  FAIL ${err.message.split('\n')[0]}`);
    tally({ ok: false, file: 'quan_tri_nguoi_dung_03_drawer_sua.png', err: err.message });
  }

  // ─── 2. quan_tri_nguoi_dung_05_modal_reset.png ────────────────
  // Menu label "Reset mật khẩu" → Modal.confirm
  console.log('\n[2] quan_tri_nguoi_dung_05_modal_reset.png');
  try {
    await gotoAndSettle(page, '/quan-tri/nguoi-dung');
    const ok = await openRowMenuByIndex(page, 0, /Reset mật khẩu/);
    if (!ok) throw new Error('Không tìm thấy menu Reset mật khẩu');
    tally(await snap(page, 'quan_tri_nguoi_dung_05_modal_reset.png', { fullPage: false }));
    await closeOverlays(page);
  } catch (err) {
    console.log(`  FAIL ${err.message.split('\n')[0]}`);
    tally({ ok: false, file: 'quan_tri_nguoi_dung_05_modal_reset.png', err: err.message });
  }

  // ─── 3. van_ban_den_03_confirm_delete.png ─────────────────────
  // Menu label "Xóa" → Modal.confirm "Xác nhận xóa"
  console.log('\n[3] van_ban_den_03_confirm_delete.png');
  try {
    await gotoAndSettle(page, '/van-ban-den');
    // Try multiple rows since some don't have Delete in menu
    let snapped = false;
    for (let i = 0; i < 5 && !snapped; i++) {
      try {
        const ok = await openRowMenuByIndex(page, i, /^Xóa$/);
        if (ok) {
          // Wait modal animation
          await page.waitForTimeout(800);
          tally(await snap(page, 'van_ban_den_03_confirm_delete.png', { fullPage: false }));
          await closeOverlays(page);
          snapped = true;
        } else {
          await page.keyboard.press('Escape');
          await page.waitForTimeout(300);
        }
      } catch {
        await page.keyboard.press('Escape');
      }
    }
    if (!snapped) throw new Error('Không tìm được row có menu Xóa');
  } catch (err) {
    console.log(`  FAIL ${err.message.split('\n')[0]}`);
    tally({ ok: false, file: 'van_ban_den_03_confirm_delete.png', err: err.message });
  }

  // ─── 4. van_ban_den_07_modal_chuyen_lai.png ───────────────────
  // Chuyển lại button only for VB liên thông with status 18 (Đã nhận bàn giao)
  // Search for VB containing "liên thông" or with specific status
  console.log('\n[4] van_ban_den_07_modal_chuyen_lai.png');
  try {
    // Try to find VB liên thông in any status
    const docs = await fetchList(page, '/van-ban-den?page=1&page_size=50');
    // Heuristic: try docs sorted, click each detail until Chuyển lại appears
    let snapped = false;
    for (const d of docs.slice(0, 15)) {
      await gotoAndSettle(page, `/van-ban-den/${d.id}`);
      await page.waitForTimeout(1500);
      const btn = page.locator('button:has-text("Chuyển lại")').first();
      if ((await btn.count()) > 0 && (await btn.isVisible().catch(() => false))) {
        await btn.click({ timeout: 5000 });
        await page.waitForTimeout(1500);
        tally(await snap(page, 'van_ban_den_07_modal_chuyen_lai.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
    }
    if (!snapped) throw new Error('Không có VB nào ở trạng thái cho phép Chuyển lại — fallback chụp danh sách');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]} — placeholder ảnh`);
    tally({ ok: false, file: 'van_ban_den_07_modal_chuyen_lai.png', err: err.message });
  }

  // ─── 5. van_ban_di_04_modal_reject.png ────────────────────────
  // Tù chối — chỉ trên detail VB đi và canApprove
  console.log('\n[5] van_ban_di_04_modal_reject.png');
  try {
    const docs = await fetchList(page, '/van-ban-di?page=1&page_size=50');
    let snapped = false;
    for (const d of docs.slice(0, 15)) {
      await gotoAndSettle(page, `/van-ban-di/${d.id}`);
      await page.waitForTimeout(1500);
      // Open dropdown action menu (3-dot in toolbar)
      const moreToolbar = page.locator('.detail-header .anticon-more, .page-header .anticon-more').first();
      if ((await moreToolbar.count()) > 0) {
        await moreToolbar.click({ timeout: 3000 }).catch(() => {});
        await page.waitForTimeout(500);
      }
      const rejectItem = page.locator('.ant-dropdown-menu-item:has-text("Từ chối"), button:has-text("Từ chối")').first();
      if ((await rejectItem.count()) > 0 && (await rejectItem.isVisible().catch(() => false))) {
        await rejectItem.click({ timeout: 3000 });
        await page.waitForTimeout(1500);
        tally(await snap(page, 'van_ban_di_04_modal_reject.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
      await closeOverlays(page);
    }
    if (!snapped) throw new Error('Không có VB đi có nút Từ chối');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    tally({ ok: false, file: 'van_ban_di_04_modal_reject.png', err: err.message });
  }

  // ─── 6. van_ban_di_06_modal_send.png ──────────────────────────
  // Nút Gửi xuất hiện sau khi Ban hành (đã có số văn bản)
  console.log('\n[6] van_ban_di_06_modal_send.png');
  try {
    const docs = await fetchList(page, '/van-ban-di?page=1&page_size=50');
    let snapped = false;
    for (const d of docs.slice(0, 15)) {
      await gotoAndSettle(page, `/van-ban-di/${d.id}`);
      await page.waitForTimeout(1500);
      // "Gửi" button (not "Gửi nội bộ", not "Gửi liên thông")
      const sendBtn = page.locator('button').filter({ hasText: /^Gửi$/ }).first();
      if ((await sendBtn.count()) > 0 && (await sendBtn.isVisible().catch(() => false))) {
        await sendBtn.click({ timeout: 5000 });
        await page.waitForTimeout(1500);
        tally(await snap(page, 'van_ban_di_06_modal_send.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
      // Try "Ban hành & Gửi" — opens combined send flow
      const sendCombined = page.locator('button:has-text("Ban hành & Gửi")').first();
      if ((await sendCombined.count()) > 0 && (await sendCombined.isVisible().catch(() => false))) {
        await sendCombined.click({ timeout: 5000 });
        await page.waitForTimeout(2000);
        tally(await snap(page, 'van_ban_di_06_modal_send.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
    }
    if (!snapped) throw new Error('Không có VB đi đã ban hành để chụp Gửi');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    tally({ ok: false, file: 'van_ban_di_06_modal_send.png', err: err.message });
  }

  // ─── 7. van_ban_di_07_modal_send_internal.png ──────────────────
  // Gửi nội bộ — sau khi đã ban hành
  console.log('\n[7] van_ban_di_07_modal_send_internal.png');
  try {
    const docs = await fetchList(page, '/van-ban-di?page=1&page_size=50');
    let snapped = false;
    for (const d of docs.slice(0, 15)) {
      await gotoAndSettle(page, `/van-ban-di/${d.id}`);
      await page.waitForTimeout(1500);
      const btn = page.locator('button:has-text("Gửi nội bộ")').first();
      if ((await btn.count()) > 0 && (await btn.isVisible().catch(() => false))) {
        await btn.click({ timeout: 5000 });
        await page.waitForTimeout(1500);
        tally(await snap(page, 'van_ban_di_07_modal_send_internal.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
    }
    if (!snapped) throw new Error('Không có nút Gửi nội bộ');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    tally({ ok: false, file: 'van_ban_di_07_modal_send_internal.png', err: err.message });
  }

  // ─── 8. van_ban_du_thao_05_modal_reject.png ────────────────────
  console.log('\n[8] van_ban_du_thao_05_modal_reject.png');
  try {
    const docs = await fetchList(page, '/van-ban-du-thao?page=1&page_size=50');
    let snapped = false;
    for (const d of docs.slice(0, 15)) {
      await gotoAndSettle(page, `/van-ban-du-thao/${d.id}`);
      await page.waitForTimeout(1500);
      // Try toolbar dropdown first
      const moreBtn = page.locator('.detail-header .anticon-more, .page-header .anticon-more').first();
      if ((await moreBtn.count()) > 0) {
        await moreBtn.click({ timeout: 3000 }).catch(() => {});
        await page.waitForTimeout(500);
      }
      const rejectItem = page.locator('.ant-dropdown-menu-item:has-text("Từ chối"), button:has-text("Từ chối")').first();
      if ((await rejectItem.count()) > 0 && (await rejectItem.isVisible().catch(() => false))) {
        await rejectItem.click({ timeout: 3000 });
        await page.waitForTimeout(1500);
        tally(await snap(page, 'van_ban_du_thao_05_modal_reject.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
      await closeOverlays(page);
    }
    if (!snapped) throw new Error('Không có dự thảo có nút Từ chối');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    tally({ ok: false, file: 'van_ban_du_thao_05_modal_reject.png', err: err.message });
  }

  // ─── 9. van_ban_du_thao_08_modal_send.png ──────────────────────
  console.log('\n[9] van_ban_du_thao_08_modal_send.png');
  try {
    const docs = await fetchList(page, '/van-ban-du-thao?page=1&page_size=50');
    let snapped = false;
    for (const d of docs.slice(0, 15)) {
      await gotoAndSettle(page, `/van-ban-du-thao/${d.id}`);
      await page.waitForTimeout(1500);
      // Try send / Trình ký / Phát hành
      const btn = page.locator('button').filter({ hasText: /^Gửi$|Trình ký|Phát hành|Ban hành/ }).first();
      if ((await btn.count()) > 0 && (await btn.isVisible().catch(() => false))) {
        await btn.click({ timeout: 5000 });
        await page.waitForTimeout(1500);
        tally(await snap(page, 'van_ban_du_thao_08_modal_send.png', { fullPage: false }));
        await closeOverlays(page);
        snapped = true;
        break;
      }
    }
    if (!snapped) throw new Error('Không có dự thảo có nút Gửi/Trình ký');
  } catch (err) {
    console.log(`  WARN ${err.message.split('\n')[0]}`);
    tally({ ok: false, file: 'van_ban_du_thao_08_modal_send.png', err: err.message });
  }

  await browser.close();

  const ok = results.filter(r => r.ok).length;
  const fail = results.filter(r => !r.ok).length;
  console.log('\n━━━━ Summary ━━━━');
  console.log(`OK:   ${ok}/${results.length}`);
  console.log(`FAIL: ${fail}`);
  if (fail > 0) {
    console.log('\nStill missing:');
    results.filter(r => !r.ok).forEach(r => console.log(`  ${r.file}: ${(r.err || '').split('\n')[0]}`));
  }
})();
