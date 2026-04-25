// Verify Fix #1: Bell notification mở rộng — tạo 1 HSCV với curator khác user, check bell user kia tăng
const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOTS_DIR = path.resolve(__dirname, '../../docs/hdsd/screenshots');

async function loginAs(context, username, password) {
  const page = await context.newPage();
  await page.goto('http://localhost:3000/login', { waitUntil: 'networkidle' });
  await page.fill('input[placeholder="Nhập tên đăng nhập"]', username);
  await page.fill('input[placeholder="Nhập mật khẩu"]', password);
  await Promise.all([
    page.waitForURL('**/dashboard', { timeout: 15000 }),
    page.click('button[type="submit"]:has-text("Đăng nhập")'),
  ]);
  await page.waitForLoadState('networkidle');
  return page;
}

async function getUnreadCount(page) {
  const r = await page.evaluate(async () => {
    const token = localStorage.getItem('accessToken');
    const res = await fetch('http://localhost:4000/api/notifications/unread-count', {
      headers: { Authorization: `Bearer ${token}` },
    });
    return await res.json();
  });
  return Number(r.data?.count ?? 0);
}

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctxAdmin = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: 'vi-VN' });
  const ctxUser = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: 'vi-VN' });

  const adminPage = await loginAs(ctxAdmin, 'admin', 'Admin@123');
  const userPage = await loginAs(ctxUser, 'nguyenvana', 'Admin@123');

  const before = await getUnreadCount(userPage);
  console.log(`User nguyenvana — before: ${before} unread`);

  // Admin tạo 1 HSCV mới với curator = nguyenvana (id=2 thường là user staff đầu tiên non-admin)
  // Tìm nguyenvana ID + tạo HSCV
  const result = await adminPage.evaluate(async () => {
    const token = localStorage.getItem('accessToken');
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    // Get all staff (page 1, large pageSize) and pick by id
    const u = await fetch('http://localhost:4000/api/quan-tri/nguoi-dung?page=1&pageSize=50', { headers });
    const uj = await u.json();
    const all = uj.data || [];
    const nguyenvana = all.find((x) => x.id === 2 || x.username === 'nguyenvana');
    if (!nguyenvana) return { error: 'nguyenvana not found', sample: all.slice(0, 3).map((x) => ({ id: x.id, username: x.username, full_name: x.full_name })) };

    // Pick any leader different from nguyenvana
    const signer = all.find((x) => x.is_leader && x.id !== nguyenvana.id) || all.find((x) => x.id !== nguyenvana.id && x.id !== 1);
    if (!signer) return { error: 'no signer found' };

    // Create HSCV via POST /ho-so-cong-viec
    const create = await fetch('http://localhost:4000/api/ho-so-cong-viec', {
      method: 'POST',
      headers,
      body: JSON.stringify({
        name: `HSCV test bell ${Date.now()}`,
        start_date: new Date().toISOString().slice(0, 10),
        end_date: new Date(Date.now() + 7 * 86400000).toISOString().slice(0, 10),
        curator_id: nguyenvana.id,
        signer_id: signer.id,
      }),
    });
    return { status: create.status, body: await create.json(), curatorId: nguyenvana.id };
  });
  console.log(`Create HSCV result:`, JSON.stringify(result).slice(0, 200));

  // Wait for notification to be persisted + socket emit
  await userPage.waitForTimeout(2000);
  const after = await getUnreadCount(userPage);
  console.log(`User nguyenvana — after: ${after} unread`);
  console.log(`Delta: ${after - before} (expected: 1 from task_assigned)`);

  // Capture bell on userPage
  await userPage.goto('http://localhost:3000/dashboard', { waitUntil: 'networkidle' });
  await userPage.waitForTimeout(1500);
  const bell = userPage.locator('.main-header-right svg[data-icon="bell"]').first();
  await bell.click({ timeout: 5000 });
  await userPage.waitForTimeout(1000);
  await userPage.screenshot({ path: path.join(SCREENSHOTS_DIR, 'thong_bao_02_bell.png'), fullPage: true });
  console.log('Captured bell dropdown for nguyenvana');

  await browser.close();
  process.exit(after > before ? 0 : 1);
})();
