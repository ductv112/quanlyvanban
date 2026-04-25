const { chromium } = require('playwright');
const path = require('path');
const SCREENSHOTS_DIR = path.resolve(__dirname, '../../docs/hdsd/screenshots');
(async () => {
  const browser = await chromium.launch({ headless: true });
  const ctx = await browser.newContext({ viewport: { width: 1440, height: 900 }, locale: 'vi-VN' });
  const page = await ctx.newPage();
  await page.goto('http://localhost:3000/login', { waitUntil: 'networkidle' });
  await page.fill('input[placeholder="Nhập tên đăng nhập"]', 'admin');
  await page.fill('input[placeholder="Nhập mật khẩu"]', 'Admin@123');
  await Promise.all([
    page.waitForURL('**/dashboard'),
    page.click('button[type="submit"]:has-text("Đăng nhập")'),
  ]);
  await page.goto('http://localhost:3000/thong-bao', { waitUntil: 'networkidle' });
  await page.waitForTimeout(2000);
  await page.screenshot({ path: path.join(SCREENSHOTS_DIR, 'thong_bao_01_main.png'), fullPage: true });
  console.log('Captured /thong-bao with new label');
  await browser.close();
})();
