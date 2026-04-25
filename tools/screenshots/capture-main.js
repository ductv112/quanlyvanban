// Capture main screenshots for HDSD documentation.
// Requires backend (4000) + frontend (3000) running, admin login admin/Admin@123.

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE_URL = 'http://localhost:3000';
const SCREENSHOTS_DIR = path.resolve(__dirname, '../../docs/hdsd/screenshots');
const VIEWPORT = { width: 1440, height: 900 };

const ROUTES = [
  // Auth — captured before login
  { path: '/login', file: 'auth_01_login.png', preLogin: true },

  // Dashboard
  { path: '/dashboard', file: 'dashboard_01_main.png' },

  // Profile
  { path: '/thong-tin-ca-nhan', file: 'thong_tin_ca_nhan_01_main.png' },

  // Văn bản (đến / đi / dự thảo / đánh dấu / cấu hình gửi nhanh)
  { path: '/van-ban-den', file: 'van_ban_den_01_list.png' },
  { path: '/van-ban-di', file: 'van_ban_di_01_list.png' },
  { path: '/van-ban-du-thao', file: 'van_ban_du_thao_01_list.png' },
  { path: '/van-ban-danh-dau', file: 'van_ban_danh_dau_01_main.png' },
  { path: '/cau-hinh-gui-nhanh', file: 'cau_hinh_gui_nhanh_01_main.png' },

  // HSCV
  { path: '/ho-so-cong-viec', file: 'hscv_danh_sach_01_main.png' },
  { path: '/ho-so-cong-viec/bao-cao', file: 'hscv_bao_cao_01_main.png' },

  // Thông báo
  { path: '/thong-bao', file: 'thong_bao_01_main.png' },

  // Ký số
  { path: '/ky-so/cau-hinh', file: 'ky_so_cau_hinh_01_main.png' },
  { path: '/ky-so/tai-khoan', file: 'ky_so_tai_khoan_01_main.png' },
  { path: '/ky-so/danh-sach', file: 'ky_so_danh_sach_01_main.png' },

  // Quản trị (admin)
  { path: '/quan-tri/don-vi', file: 'quan_tri_don_vi_01_main.png' },
  { path: '/quan-tri/chuc-vu', file: 'quan_tri_chuc_vu_01_main.png' },
  { path: '/quan-tri/nguoi-dung', file: 'quan_tri_nguoi_dung_01_main.png' },
  { path: '/quan-tri/nhom-quyen', file: 'quan_tri_nhom_quyen_01_main.png' },

  // Danh mục
  { path: '/quan-tri/so-van-ban', file: 'quan_tri_so_van_ban_01_main.png' },
  { path: '/quan-tri/loai-van-ban', file: 'quan_tri_loai_van_ban_01_main.png' },
  { path: '/quan-tri/linh-vuc', file: 'quan_tri_linh_vuc_01_main.png' },
  { path: '/quan-tri/nguoi-ky', file: 'quan_tri_nguoi_ky_01_main.png' },
];

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

async function captureRoute(page, route, dir) {
  const filePath = path.join(dir, route.file);
  process.stdout.write(`  → ${route.path.padEnd(40)} `);
  try {
    await page.goto(`${BASE_URL}${route.path}`, { waitUntil: 'networkidle', timeout: 30000 });
    // Wait additional time for AntD animations / data loading
    await page.waitForTimeout(2500);
    await page.screenshot({ path: filePath, fullPage: true });
    const stats = fs.statSync(filePath);
    console.log(`✓ ${(stats.size / 1024).toFixed(0)} KB`);
    return { ok: true, file: route.file };
  } catch (err) {
    console.log(`✗ ${err.message.split('\n')[0]}`);
    return { ok: false, file: route.file, err: err.message };
  }
}

(async () => {
  if (!fs.existsSync(SCREENSHOTS_DIR)) fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true });

  console.log(`Output dir: ${SCREENSHOTS_DIR}`);
  console.log(`Routes:     ${ROUTES.length}`);
  console.log('');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: VIEWPORT, locale: 'vi-VN' });
  const page = await context.newPage();

  // 1. Capture login page first (no auth required)
  console.log('[1/2] Pre-login captures');
  const preLoginRoutes = ROUTES.filter((r) => r.preLogin);
  const results = [];
  for (const r of preLoginRoutes) {
    results.push(await captureRoute(page, r, SCREENSHOTS_DIR));
  }

  // 2. Login then capture authenticated routes
  console.log('\n[2/2] Logging in...');
  await login(page);
  console.log('     Logged in OK\n');

  console.log('[2/2] Authenticated captures');
  const authRoutes = ROUTES.filter((r) => !r.preLogin);
  for (const r of authRoutes) {
    results.push(await captureRoute(page, r, SCREENSHOTS_DIR));
  }

  await browser.close();

  console.log('\n──── Summary ────');
  const ok = results.filter((r) => r.ok).length;
  const fail = results.filter((r) => !r.ok).length;
  console.log(`OK:   ${ok}/${results.length}`);
  if (fail > 0) {
    console.log(`FAIL: ${fail}`);
    results.filter((r) => !r.ok).forEach((r) => console.log(`  ${r.file}: ${r.err.split('\n')[0]}`));
    process.exit(1);
  }
})();
