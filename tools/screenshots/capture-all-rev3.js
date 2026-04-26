// Comprehensive capture script for HDSD rev3 (20 modules / 98 screens).
// 2-phase strategy:
//   Phase 1 (COPY): rename existing screenshots to new convention names
//   Phase 2 (CAPTURE): chụp các ảnh mới (drawer sửa, modal đặc biệt, detail pages mới)
// Best-effort: per-screenshot try/catch, never abort.

const { chromium } = require('playwright');
const path = require('path');
const fs = require('fs');

const BASE_URL = 'http://localhost:3000';
const SCREENSHOTS_DIR = path.resolve(__dirname, '../../docs/hdsd/screenshots');
const VIEWPORT = { width: 1440, height: 900 };

// ─── Phase 1: rename mappings (existing → new convention) ────────────
const RENAME_MAP = [
  // Quan tri don vi
  ['quan_tri_don_vi_01_main.png',          'quan_tri_don_vi_01_danh_sach.png'],
  ['quan_tri_don_vi_02_add_drawer.png',    'quan_tri_don_vi_02_drawer_them.png'],
  ['quan_tri_don_vi_04_delete_confirm.png','quan_tri_don_vi_04_modal_xoa.png'],
  // Quan tri chuc vu
  ['quan_tri_chuc_vu_01_main.png',          'quan_tri_chuc_vu_01_danh_sach.png'],
  ['quan_tri_chuc_vu_02_add_drawer.png',    'quan_tri_chuc_vu_02_drawer_them.png'],
  ['quan_tri_chuc_vu_04_delete_confirm.png','quan_tri_chuc_vu_04_modal_xoa.png'],
  // Quan tri nguoi dung
  ['quan_tri_nguoi_dung_01_main.png',          'quan_tri_nguoi_dung_01_danh_sach.png'],
  ['quan_tri_nguoi_dung_02_add_drawer.png',    'quan_tri_nguoi_dung_02_drawer_them.png'],
  ['quan_tri_nguoi_dung_03_phan_quyen.png',    'quan_tri_nguoi_dung_04_drawer_phan_quyen.png'],
  ['quan_tri_nguoi_dung_04_delete_confirm.png','quan_tri_nguoi_dung_06_modal_xoa.png'],
  // Quan tri nhom quyen
  ['quan_tri_nhom_quyen_01_main.png',           'quan_tri_nhom_quyen_01_danh_sach.png'],
  ['quan_tri_nhom_quyen_02_add_drawer.png',     'quan_tri_nhom_quyen_02_drawer_them.png'],
  ['quan_tri_nhom_quyen_03_perm_drawer.png',    'quan_tri_nhom_quyen_04_drawer_phan_quyen.png'],
  ['quan_tri_nhom_quyen_05_delete_confirm.png', 'quan_tri_nhom_quyen_05_modal_xoa.png'],
  // So van ban (short slug)
  ['quan_tri_so_van_ban_01_main.png',          'so_van_ban_01_danh_sach.png'],
  ['quan_tri_so_van_ban_02_add_drawer.png',    'so_van_ban_02_them_moi.png'],
  ['quan_tri_so_van_ban_04_delete_confirm.png','so_van_ban_04_xac_nhan_xoa.png'],
  // Loai van ban (short slug)
  ['quan_tri_loai_van_ban_01_main.png',          'loai_van_ban_01_danh_sach.png'],
  ['quan_tri_loai_van_ban_02_add_drawer.png',    'loai_van_ban_02_them_moi.png'],
  ['quan_tri_loai_van_ban_04_delete_confirm.png','loai_van_ban_03_xac_nhan_xoa.png'],
  // Linh vuc (short slug)
  ['quan_tri_linh_vuc_01_main.png',          'linh_vuc_01_danh_sach.png'],
  ['quan_tri_linh_vuc_02_add_drawer.png',    'linh_vuc_02_them_moi.png'],
  ['quan_tri_linh_vuc_04_delete_confirm.png','linh_vuc_03_xac_nhan_xoa.png'],
  // Nguoi ky (short slug)
  ['quan_tri_nguoi_ky_01_main.png',          'nguoi_ky_01_danh_sach.png'],
  ['quan_tri_nguoi_ky_02_add_modal.png',     'nguoi_ky_02_them_moi.png'],
  ['quan_tri_nguoi_ky_04_delete_confirm.png','nguoi_ky_03_xac_nhan_xoa.png'],
  // Thong bao
  ['thong_bao_02_bell.png',  'thong_bao_01_bell_dropdown.png'],
  ['thong_bao_02_main_page.png', 'thong_bao_02_main.png'],
  // Van ban den (extra renames where existing fits new name)
  ['van_ban_den_02_add_drawer.png','van_ban_den_02_drawer_add.png'],
  ['van_ban_den_02_detail.png',    'van_ban_den_04_detail.png'],
  ['van_ban_den_04_send_modal.png','van_ban_den_05_modal_send.png'],
  // Van ban di (existing map)
  ['van_ban_di_02_drawer.png',  'van_ban_di_02_drawer_add.png'],
  ['van_ban_di_02_detail.png',  'van_ban_di_05_detail.png'],
  // Van ban du thao
  ['van_ban_du_thao_03_drawer_add.png','van_ban_du_thao_02_drawer_add.png'],
  ['van_ban_du_thao_02_detail.png',    'van_ban_du_thao_07_detail.png'],
];

// ─── Helpers ────────────────────────────────────────────────────────
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

async function fetchFirstId(page, listApi) {
  try {
    const json = await page.evaluate(async (url) => {
      const token = localStorage.getItem('accessToken');
      const r = await fetch(url, { headers: { Authorization: `Bearer ${token}` }, credentials: 'include' });
      if (!r.ok) return { error: r.status };
      return r.json();
    }, `http://localhost:4000/api${listApi}`);
    if (json?.error) return null;
    const arr = json?.data?.data || json?.data || [];
    return Array.isArray(arr) && arr.length > 0 ? arr[0].id : null;
  } catch { return null; }
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
    const msg = err.message.split('\n')[0];
    console.log(`FAIL ${msg}`);
    return { ok: false, file, err: msg };
  }
}

async function closeOverlays(page) {
  try {
    for (let i = 0; i < 3; i++) {
      await page.keyboard.press('Escape');
      await page.waitForTimeout(250);
    }
    await page.mouse.click(5, 5);
    await page.waitForTimeout(250);
  } catch {}
}

async function gotoAndSettle(page, url) {
  await page.goto(`${BASE_URL}${url}`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1500);
}

async function clickButton(page, text, timeout = 5000) {
  const btn = page.locator(`button:has-text("${text}")`).first();
  await btn.click({ timeout });
  await page.waitForTimeout(1500);
}

async function openRowDropdownAndClick(page, itemText) {
  const moreBtn = page.locator('.ant-table-row').first().locator('.anticon-more').first();
  await moreBtn.click({ timeout: 5000 });
  await page.waitForTimeout(500);
  const menuItem = page.locator(`.ant-dropdown-menu-item:has-text("${itemText}")`).first();
  await menuItem.click({ timeout: 5000 });
  await page.waitForTimeout(1500);
}

async function runCase(label, fn, results) {
  console.log(`\n[${label}]`);
  try {
    const r = await fn();
    if (Array.isArray(r)) results.push(...r);
    else if (r) results.push(r);
  } catch (err) {
    console.log(`  FAIL ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: label, err: err.message.split('\n')[0] });
  }
}

// ─── Phase 1: copy existing files to new names ────────────────────────
function phase1Rename() {
  console.log('━━━━ Phase 1: Rename existing screenshots ━━━━\n');
  let renamed = 0, skipped = 0;
  for (const [src, dst] of RENAME_MAP) {
    const srcPath = path.join(SCREENSHOTS_DIR, src);
    const dstPath = path.join(SCREENSHOTS_DIR, dst);
    if (!fs.existsSync(srcPath)) {
      console.log(`  SKIP src missing: ${src}`);
      skipped++;
      continue;
    }
    if (fs.existsSync(dstPath)) {
      console.log(`  SKIP dst exists: ${dst}`);
      skipped++;
      continue;
    }
    try {
      fs.copyFileSync(srcPath, dstPath);
      console.log(`  COPY ${src.padEnd(45)} -> ${dst}`);
      renamed++;
    } catch (err) {
      console.log(`  FAIL ${src}: ${err.message}`);
    }
  }
  console.log(`\n  Phase 1 done: ${renamed} copied, ${skipped} skipped\n`);
  return renamed;
}

// ─── Phase 2: capture truly new screenshots ───────────────────────────
async function phase2Capture(browser, results) {
  console.log('\n━━━━ Phase 2: Capture new screenshots ━━━━\n');

  const context = await browser.newContext({ viewport: VIEWPORT, locale: 'vi-VN' });
  const page = await context.newPage();
  await login(page);
  console.log('Logged in OK\n');

  // ─── A. Drawer SỬA cho 4 admin pages chính ────────────────────────
  // Pattern: vào list → row dropdown → "Chỉnh sửa" / "Sửa" → screenshot drawer
  const editCases = [
    { url: '/quan-tri/don-vi',     file: 'quan_tri_don_vi_03_drawer_sua.png',     menu: 'Chỉnh sửa' },
    { url: '/quan-tri/chuc-vu',    file: 'quan_tri_chuc_vu_03_drawer_sua.png',    menu: 'Chỉnh sửa' },
    { url: '/quan-tri/nguoi-dung', file: 'quan_tri_nguoi_dung_03_drawer_them.png', menu: 'Chỉnh sửa' },
    { url: '/quan-tri/nhom-quyen', file: 'quan_tri_nhom_quyen_03_drawer_sua.png', menu: 'Chỉnh sửa' },
  ];
  for (const tc of editCases) {
    await runCase(`A:${tc.file}`, async () => {
      await gotoAndSettle(page, tc.url);
      try { await openRowDropdownAndClick(page, tc.menu); }
      catch {
        // fallback: try "Sửa"
        await closeOverlays(page);
        await gotoAndSettle(page, tc.url);
        await openRowDropdownAndClick(page, 'Sửa');
      }
      const r = await snap(page, tc.file);
      await closeOverlays(page);
      return r;
    }, results);
  }

  // ─── B. Modal reset password (nguoi-dung) ─────────────────────────
  await runCase('B:quan_tri_nguoi_dung_05_modal_reset.png', async () => {
    await gotoAndSettle(page, '/quan-tri/nguoi-dung');
    try { await openRowDropdownAndClick(page, 'Đặt lại mật khẩu'); }
    catch { await openRowDropdownAndClick(page, 'Reset'); }
    const r = await snap(page, 'quan_tri_nguoi_dung_05_modal_reset.png', { fullPage: false });
    await closeOverlays(page);
    return r;
  }, results);

  // ─── C. Sổ văn bản: đặt mặc định ──────────────────────────────────
  await runCase('C:so_van_ban_03_dat_mac_dinh.png', async () => {
    await gotoAndSettle(page, '/quan-tri/so-van-ban');
    // Try menu "Đặt mặc định" hoặc "Mặc định"
    try { await openRowDropdownAndClick(page, 'Đặt mặc định'); }
    catch { try { await openRowDropdownAndClick(page, 'Mặc định'); } catch {} }
    await page.waitForTimeout(800);
    const r = await snap(page, 'so_van_ban_03_dat_mac_dinh.png', { fullPage: false });
    await closeOverlays(page);
    return r;
  }, results);

  // ─── D. Logout confirm ────────────────────────────────────────────
  await runCase('D:thong_tin_ca_nhan_03_logout_confirm.png', async () => {
    await gotoAndSettle(page, '/dashboard');
    // Click avatar/user dropdown in header
    const avatarBtn = page.locator('.main-header-right .ant-avatar, .main-header-right .anticon-user').first();
    await avatarBtn.click({ timeout: 5000 });
    await page.waitForTimeout(700);
    // Click "Đăng xuất" menu item
    const logoutItem = page.locator('.ant-dropdown-menu-item:has-text("Đăng xuất"), .ant-dropdown-menu-item:has-text("Thoát")').first();
    await logoutItem.click({ timeout: 5000 });
    await page.waitForTimeout(1000);
    // Modal.confirm appears
    const r = await snap(page, 'thong_tin_ca_nhan_03_logout_confirm.png', { fullPage: false });
    // Click Hủy to keep session
    const cancelBtn = page.locator('.ant-modal-confirm-btns button:not(.ant-btn-primary), .ant-modal-confirm-btns button:has-text("Hủy")').first();
    await cancelBtn.click({ timeout: 3000 }).catch(() => {});
    await closeOverlays(page);
    return r;
  }, results);

  // ─── E. Văn bản đến: nghiệp vụ ────────────────────────────────────
  await runCase('E:van_ban_den_02_drawer_add.png', async () => {
    if (fs.existsSync(path.join(SCREENSHOTS_DIR, 'van_ban_den_02_drawer_add.png'))) {
      console.log('  SKIP exists');
      return { ok: true, file: 'van_ban_den_02_drawer_add.png' };
    }
    await gotoAndSettle(page, '/van-ban-den');
    await clickButton(page, 'Thêm mới');
    const r = await snap(page, 'van_ban_den_02_drawer_add.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('E:van_ban_den_03_confirm_delete.png', async () => {
    await gotoAndSettle(page, '/van-ban-den');
    await openRowDropdownAndClick(page, 'Xóa');
    const r = await snap(page, 'van_ban_den_03_confirm_delete.png', { fullPage: false });
    await closeOverlays(page);
    return r;
  }, results);

  // VB đến chi tiết — già có. Phần modal Giao việc, Chuyển lại, HSCV, LGSP
  const vbDenId = await fetchFirstId(page, '/van-ban-den?page=1&page_size=1');
  if (vbDenId) {
    await runCase('E:van_ban_den_06_drawer_giao_viec.png', async () => {
      await gotoAndSettle(page, `/van-ban-den/${vbDenId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /^Giao việc$/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Giao việc');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_den_06_drawer_giao_viec.png');
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('E:van_ban_den_07_modal_chuyen_lai.png', async () => {
      await gotoAndSettle(page, `/van-ban-den/${vbDenId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /Chuyển lại|Trả lại/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Chuyển lại');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_den_07_modal_chuyen_lai.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('E:van_ban_den_08_modal_hscv.png', async () => {
      await gotoAndSettle(page, `/van-ban-den/${vbDenId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /Thêm vào HSCV|HSCV|hồ sơ/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút HSCV');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_den_08_modal_hscv.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('E:van_ban_den_09_modal_lgsp.png', async () => {
      await gotoAndSettle(page, `/van-ban-den/${vbDenId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /liên thông|LGSP/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Liên thông');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_den_09_modal_lgsp.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);
  }

  // ─── F. Văn bản đi: nghiệp vụ ─────────────────────────────────────
  await runCase('F:van_ban_di_02_drawer_add.png', async () => {
    if (fs.existsSync(path.join(SCREENSHOTS_DIR, 'van_ban_di_02_drawer_add.png'))) {
      return { ok: true, file: 'van_ban_di_02_drawer_add.png' };
    }
    await gotoAndSettle(page, '/van-ban-di');
    await clickButton(page, 'Thêm mới');
    const r = await snap(page, 'van_ban_di_02_drawer_add.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('F:van_ban_di_03_confirm_delete.png', async () => {
    await gotoAndSettle(page, '/van-ban-di');
    await openRowDropdownAndClick(page, 'Xóa');
    const r = await snap(page, 'van_ban_di_03_confirm_delete.png', { fullPage: false });
    await closeOverlays(page);
    return r;
  }, results);

  const vbDiId = await fetchFirstId(page, '/van-ban-di?page=1&page_size=1');
  if (vbDiId) {
    await runCase('F:van_ban_di_04_modal_reject.png', async () => {
      await gotoAndSettle(page, `/van-ban-di/${vbDiId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /Từ chối|Trả về/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Từ chối');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_di_04_modal_reject.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('F:van_ban_di_06_modal_send.png', async () => {
      await gotoAndSettle(page, `/van-ban-di/${vbDiId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /^Gửi$|Phát hành/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Gửi');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_di_06_modal_send.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('F:van_ban_di_07_modal_send_internal.png', async () => {
      await gotoAndSettle(page, `/van-ban-di/${vbDiId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /Gửi nội bộ|nội bộ/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Gửi nội bộ');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_di_07_modal_send_internal.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('F:van_ban_di_08_drawer_giao_viec.png', async () => {
      await gotoAndSettle(page, `/van-ban-di/${vbDiId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /Giao việc/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Giao việc');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_di_08_drawer_giao_viec.png');
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('F:van_ban_di_09_modal_hscv.png', async () => {
      await gotoAndSettle(page, `/van-ban-di/${vbDiId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /Thêm vào HSCV|HSCV|hồ sơ/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút HSCV');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_di_09_modal_hscv.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);
  }

  // ─── G. Văn bản dự thảo: nghiệp vụ ────────────────────────────────
  await runCase('G:van_ban_du_thao_02_drawer_add.png', async () => {
    if (fs.existsSync(path.join(SCREENSHOTS_DIR, 'van_ban_du_thao_02_drawer_add.png'))) {
      return { ok: true, file: 'van_ban_du_thao_02_drawer_add.png' };
    }
    await gotoAndSettle(page, '/van-ban-du-thao');
    await clickButton(page, 'Thêm mới');
    const r = await snap(page, 'van_ban_du_thao_02_drawer_add.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('G:van_ban_du_thao_03_confirm_delete.png', async () => {
    await gotoAndSettle(page, '/van-ban-du-thao');
    await openRowDropdownAndClick(page, 'Xóa');
    const r = await snap(page, 'van_ban_du_thao_03_confirm_delete.png', { fullPage: false });
    await closeOverlays(page);
    return r;
  }, results);

  const dthId = await fetchFirstId(page, '/van-ban-du-thao?page=1&page_size=1');
  if (dthId) {
    await runCase('G:van_ban_du_thao_04_confirm_approve.png', async () => {
      await gotoAndSettle(page, `/van-ban-du-thao/${dthId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /^Duyệt$|Phê duyệt|Trình ký/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Duyệt');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1200);
      const r = await snap(page, 'van_ban_du_thao_04_confirm_approve.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('G:van_ban_du_thao_05_modal_reject.png', async () => {
      await gotoAndSettle(page, `/van-ban-du-thao/${dthId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /Từ chối|Trả về/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Từ chối');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_du_thao_05_modal_reject.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('G:van_ban_du_thao_06_confirm_release.png', async () => {
      await gotoAndSettle(page, `/van-ban-du-thao/${dthId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /Phát hành|Ban hành/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Phát hành');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_du_thao_06_confirm_release.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('G:van_ban_du_thao_08_modal_send.png', async () => {
      await gotoAndSettle(page, `/van-ban-du-thao/${dthId}`);
      await page.waitForTimeout(2000);
      const btn = page.locator('button').filter({ hasText: /^Gửi$|Trình ký/i }).first();
      if (await btn.count() === 0) throw new Error('Không có nút Gửi');
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'van_ban_du_thao_08_modal_send.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);
  }

  // ─── H. Văn bản đến #5 send modal duplicate (nếu chưa có thì chụp lại từ detail) ──
  await runCase('H:van_ban_den_05_modal_send.png', async () => {
    if (fs.existsSync(path.join(SCREENSHOTS_DIR, 'van_ban_den_05_modal_send.png'))) {
      return { ok: true, file: 'van_ban_den_05_modal_send.png' };
    }
    if (!vbDenId) throw new Error('Không có VB đến');
    await gotoAndSettle(page, `/van-ban-den/${vbDenId}`);
    await page.waitForTimeout(2000);
    const btn = page.locator('button').filter({ hasText: /^Gửi$/ }).first();
    if (await btn.count() === 0) throw new Error('Không có nút Gửi');
    await btn.click({ timeout: 5000 });
    await page.waitForTimeout(1500);
    const r = await snap(page, 'van_ban_den_05_modal_send.png', { fullPage: false });
    await closeOverlays(page);
    return r;
  }, results);

  await context.close();
}

// ─── MAIN ────────────────────────────────────────────────────────────
(async () => {
  if (!fs.existsSync(SCREENSHOTS_DIR)) fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true });
  console.log(`Output: ${SCREENSHOTS_DIR}\n`);
  const startTime = Date.now();

  // Phase 1: rename
  const renamed = phase1Rename();

  // Phase 2: capture new
  const browser = await chromium.launch({ headless: true });
  const results = [];
  await phase2Capture(browser, results);
  await browser.close();

  // Summary
  const ok = results.filter(r => r.ok).length;
  const fail = results.filter(r => !r.ok).length;
  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  console.log('\n━━━━ Summary ━━━━');
  console.log(`Phase 1 renames: ${renamed}`);
  console.log(`Phase 2 OK:      ${ok}/${results.length}`);
  console.log(`Phase 2 FAIL:    ${fail}`);
  console.log(`Total time:      ${elapsed}s`);
  if (fail > 0) {
    console.log('\nFailed:');
    results.filter(r => !r.ok).forEach(r => console.log(`  ${r.file}: ${r.err}`));
  }
})();
