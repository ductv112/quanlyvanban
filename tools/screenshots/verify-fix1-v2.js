// Re-verify Fix #1: nguyenvana (unit=2) tạo HSCV cho dothil (id=10, cùng unit=2)
const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOTS_DIR = path.resolve(__dirname, '../../docs/hdsd/screenshots');

async function loginAs(context, username) {
  const page = await context.newPage();
  await page.goto('http://localhost:3000/login', { waitUntil: 'networkidle' });
  await page.fill('input[placeholder="Nhập tên đăng nhập"]', username);
  await page.fill('input[placeholder="Nhập mật khẩu"]', 'Admin@123');
  await Promise.all([
    page.waitForURL('**/dashboard', { timeout: 15000 }),
    page.click('button[type="submit"]:has-text("Đăng nhập")'),
  ]);
  await page.waitForLoadState('networkidle');
  return page;
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctxA = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: 'vi-VN' });
  const ctxB = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: 'vi-VN' });

  // nguyenvana (sender) — unit=2
  const sender = await loginAs(ctxA, 'nguyenvana');
  // dothil (receiver) — unit=2
  const recv = await loginAs(ctxB, 'dothil');

  const before = await recv.evaluate(async () => {
    const t = localStorage.getItem('accessToken');
    const r = await fetch('http://localhost:4000/api/notifications/unread-count', { headers: { Authorization: `Bearer ${t}` } });
    return Number((await r.json()).data?.count ?? 0);
  });
  console.log(`dothil before: ${before} unread`);

  const result = await sender.evaluate(async () => {
    const t = localStorage.getItem('accessToken');
    const headers = { Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' };
    // Find dothil id (must be in same unit dropdown)
    const u = await fetch('http://localhost:4000/api/ho-so-cong-viec/nhan-vien-cung-don-vi', { headers });
    const uj = await u.json();
    const dothil = (uj.data || []).find((x) => x.username === 'dothil' || x.id === 10);
    if (!dothil) return { error: 'dothil not in same unit dropdown', sample: uj.data?.slice(0, 3) };
    // Find a leader same unit
    const l = await fetch('http://localhost:4000/api/ho-so-cong-viec/lanh-dao-cung-don-vi', { headers });
    const leader = ((await l.json()).data || [])[0];
    if (!leader) return { error: 'no leader same unit' };
    // Create HSCV
    const create = await fetch('http://localhost:4000/api/ho-so-cong-viec', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        name: `HSCV nội bộ Sở Nội vụ ${Date.now()}`,
        start_date: new Date().toISOString().slice(0, 10),
        end_date: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
        curator_id: dothil.id,
        signer_id: leader.id,
      }),
    });
    return { status: create.status, body: await create.json(), dothilId: dothil.id };
  });
  console.log('Create result:', JSON.stringify(result).slice(0, 250));

  await recv.waitForTimeout(2000);
  const after = await recv.evaluate(async () => {
    const t = localStorage.getItem('accessToken');
    const r = await fetch('http://localhost:4000/api/notifications/unread-count', { headers: { Authorization: `Bearer ${t}` } });
    return Number((await r.json()).data?.count ?? 0);
  });
  console.log(`dothil after: ${after} unread (delta: ${after - before})`);

  // Try clicking the link
  const docId = result.body?.data?.id;
  if (docId) {
    await recv.goto(`http://localhost:3000/ho-so-cong-viec/${docId}`, { waitUntil: 'networkidle' });
    await recv.waitForTimeout(2500);
    const errVisible = await recv.locator('text=/Không thể tải|Không tìm thấy/').count();
    console.log(`dothil opens HSCV ${docId}: ${errVisible > 0 ? 'BLOCKED ✗' : 'OK ✓'}`);
    await recv.screenshot({ path: path.join(SCREENSHOTS_DIR, 'hscv_chi_tiet_01_main.png'), fullPage: true });
  }

  await browser.close();
})();
