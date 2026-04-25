// Verify Fix #2: HSCV danh sách has new "Xuất Excel" button
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

  await page.goto('http://localhost:3000/ho-so-cong-viec', { waitUntil: 'networkidle' });
  await page.waitForTimeout(3000);

  const hasExcelBtn = await page.locator('button:has-text("Xuất Excel")').count();
  console.log(`"Xuất Excel" button visible: ${hasExcelBtn > 0 ? 'YES ✓' : 'NO ✗'}`);

  await page.screenshot({ path: path.join(SCREENSHOTS_DIR, 'hscv_danh_sach_01_main.png'), fullPage: true });
  console.log('Updated screenshot: hscv_danh_sach_01_main.png');

  await browser.close();
})();
