// Verify Fix #3: Cau hinh gui nhanh — server-side search with debounce
const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOTS_DIR = path.resolve(__dirname, '../../docs/hdsd/screenshots');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: 'vi-VN' });
  const page = await context.newPage();

  await page.goto('http://localhost:3000/login', { waitUntil: 'networkidle' });
  await page.fill('input[placeholder="Nhập tên đăng nhập"]', 'admin');
  await page.fill('input[placeholder="Nhập mật khẩu"]', 'Admin@123');
  await Promise.all([
    page.waitForURL('**/dashboard', { timeout: 15000 }),
    page.click('button[type="submit"]:has-text("Đăng nhập")'),
  ]);

  // Track API calls to verify server-side search
  const calls = [];
  page.on('request', (req) => {
    if (req.url().includes('/api/quan-tri/nguoi-dung')) calls.push(req.url());
  });

  await page.goto('http://localhost:3000/cau-hinh-gui-nhanh', { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);

  console.log(`Initial calls to /quan-tri/nguoi-dung: ${calls.length}`);
  if (calls.length > 0) console.log(`  → ${calls[0].split('?')[1] || ''}`);

  // Type a keyword
  await page.fill('input[placeholder*="Tìm kiếm cán bộ"]', 'admin');
  await page.waitForTimeout(700); // wait for debounce + fetch
  const newCalls = calls.length;
  console.log(`After typing 'admin': ${newCalls} total calls`);
  if (newCalls > 1) console.log(`  → ${calls[newCalls - 1].split('?')[1] || ''}`);

  // Clear keyword and capture default state
  await page.fill('input[placeholder*="Tìm kiếm cán bộ"]', '');
  await page.waitForTimeout(700);
  await page.screenshot({ path: path.join(SCREENSHOTS_DIR, 'cau_hinh_gui_nhanh_01_main.png'), fullPage: true });
  console.log('Updated screenshot (default state, no keyword)');

  await browser.close();
})();
