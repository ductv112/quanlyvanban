// Re-capture quan_tri_loai_van_ban + quan_tri_nguoi_dung after rendering fixes
const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOTS_DIR = path.resolve(__dirname, '../../docs/hdsd/screenshots');

(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext({ viewport: { width: 1920, height: 900 }, locale: 'vi-VN' });
  const page = await ctx.newPage();

  await page.goto('http://localhost:3000/login', { waitUntil: 'networkidle' });
  await page.fill('input[placeholder="Nhập tên đăng nhập"]', 'admin');
  await page.fill('input[placeholder="Nhập mật khẩu"]', 'Admin@123');
  await Promise.all([
    page.waitForURL('**/dashboard'),
    page.click('button[type="submit"]:has-text("Đăng nhập")'),
  ]);

  for (const url of ['/quan-tri/loai-van-ban', '/quan-tri/nguoi-dung']) {
    await page.goto(`http://localhost:3000${url}`, { waitUntil: 'networkidle' });
    await page.waitForTimeout(2500);
    const file = url === '/quan-tri/loai-van-ban' ? 'quan_tri_loai_van_ban_01_main.png' : 'quan_tri_nguoi_dung_01_main.png';
    await page.screenshot({ path: path.join(SCREENSHOTS_DIR, file), fullPage: true });
    console.log(`Captured ${file}`);
  }

  await browser.close();
})();
