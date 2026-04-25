// Capture 33 detail screenshots (drawers, modals, tabs, etc.) for HDSD docs.
// Best-effort: each case wrapped in try/catch — failures are logged but don't abort.
// Requires backend (4000) + frontend (3000) running, login admin/Admin@123.

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

async function fetchFirstId(page, listApi) {
  try {
    const json = await page.evaluate(async (url) => {
      const token = localStorage.getItem('accessToken');
      const r = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
        credentials: 'include',
      });
      if (!r.ok) return { error: r.status };
      return r.json();
    }, `http://localhost:4000/api${listApi}`);
    if (json?.error) return null;
    const arr = json?.data?.data || json?.data || [];
    return Array.isArray(arr) && arr.length > 0 ? arr[0].id : null;
  } catch {
    return null;
  }
}

async function snap(page, file, opts = {}) {
  const filePath = path.join(SCREENSHOTS_DIR, file);
  const fullPage = opts.fullPage !== false;
  process.stdout.write(`  → ${file.padEnd(50)} `);
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

// Close any open drawer/modal/dropdown to reset state
async function closeOverlays(page) {
  try {
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    await page.keyboard.press('Escape');
    await page.waitForTimeout(300);
    // Click outside in case Esc didn't work
    await page.mouse.click(10, 10);
    await page.waitForTimeout(300);
  } catch {}
}

// Run a single case wrapped in try/catch — best-effort
async function runCase(label, fn, results) {
  console.log(`\n[${label}]`);
  try {
    const r = await fn();
    if (Array.isArray(r)) {
      results.push(...r);
    } else if (r) {
      results.push(r);
    }
  } catch (err) {
    console.log(`  FAIL ${err.message.split('\n')[0]}`);
    results.push({ ok: false, file: label, err: err.message.split('\n')[0] });
  }
}

// Helper: navigate + wait
async function gotoAndSettle(page, url) {
  await page.goto(`${BASE_URL}${url}`, { waitUntil: 'networkidle', timeout: 30000 });
  await page.waitForTimeout(1500);
}

// Helper: click first matching button text
async function clickButton(page, text, timeout = 5000) {
  const btn = page.locator(`button:has-text("${text}")`).first();
  await btn.click({ timeout });
  await page.waitForTimeout(1500);
}

// Helper: open the row-action dropdown (3-dot) on the first table row, then click an item
async function openRowDropdownAndClick(page, itemText) {
  // First row's MoreOutlined icon button — table row → look for .anticon-more
  const moreBtn = page.locator('.ant-table-row').first().locator('.anticon-more').first();
  await moreBtn.click({ timeout: 5000 });
  await page.waitForTimeout(500);
  // Dropdown menu item
  const menuItem = page.locator(`.ant-dropdown-menu-item:has-text("${itemText}")`).first();
  await menuItem.click({ timeout: 5000 });
  await page.waitForTimeout(1500);
}

(async () => {
  if (!fs.existsSync(SCREENSHOTS_DIR)) fs.mkdirSync(SCREENSHOTS_DIR, { recursive: true });

  console.log(`Output: ${SCREENSHOTS_DIR}`);
  console.log('Launching browser...\n');

  const browser = await chromium.launch({ headless: true });
  const context = await browser.newContext({ viewport: VIEWPORT, locale: 'vi-VN' });
  const page = await context.newPage();
  await login(page);
  console.log('Logged in OK\n');

  const results = [];

  // ────────────────────────────────────────────────────────────────────
  // GROUP A — Drawer Add filled (5)
  // ────────────────────────────────────────────────────────────────────
  const groupA = [
    {
      url: '/quan-tri/don-vi',
      addBtn: 'Thêm đơn vị',
      file: 'quan_tri_don_vi_03_add_filled.png',
      fill: async () => {
        await page.fill('input[id*="code"]', 'PB99').catch(() => {});
        await page.fill('input[id*="name"]', 'Phòng demo').catch(() => {});
      },
    },
    {
      url: '/quan-tri/chuc-vu',
      addBtn: 'Thêm',
      file: 'quan_tri_chuc_vu_03_add_filled.png',
      fill: async () => {
        // Try common field name patterns
        await page.locator('input').nth(0).fill('Chức vụ demo').catch(() => {});
        await page.locator('input').nth(1).fill('CV99').catch(() => {});
      },
    },
    {
      url: '/quan-tri/so-van-ban',
      addBtn: 'Thêm',
      file: 'quan_tri_so_van_ban_03_add_filled.png',
      fill: async () => {
        const inputs = page.locator('.ant-drawer-body input:not([type="hidden"])');
        await inputs.first().fill('Sổ demo').catch(() => {});
      },
    },
    {
      url: '/quan-tri/loai-van-ban',
      addBtn: 'Thêm',
      file: 'quan_tri_loai_van_ban_03_add_filled.png',
      fill: async () => {
        const inputs = page.locator('.ant-drawer-body input:not([type="hidden"])');
        await inputs.nth(0).fill('LD99').catch(() => {});
        await inputs.nth(1).fill('Loại demo').catch(() => {});
      },
    },
    {
      url: '/quan-tri/linh-vuc',
      addBtn: 'Thêm lĩnh vực',
      file: 'quan_tri_linh_vuc_03_add_filled.png',
      fill: async () => {
        const inputs = page.locator('.ant-drawer-body input:not([type="hidden"])');
        await inputs.nth(0).fill('LV99').catch(() => {});
        await inputs.nth(1).fill('Lĩnh vực demo').catch(() => {});
      },
    },
  ];

  for (const tc of groupA) {
    await runCase(`A:${tc.file}`, async () => {
      await gotoAndSettle(page, tc.url);
      await clickButton(page, tc.addBtn);
      await tc.fill();
      await page.waitForTimeout(500);
      const r = await snap(page, tc.file);
      await closeOverlays(page);
      return r;
    }, results);
  }

  // ────────────────────────────────────────────────────────────────────
  // GROUP B — Modal "Xác nhận xóa" (8)
  // Pattern: open row dropdown → click "Xóa" → screenshot Modal.confirm
  // ────────────────────────────────────────────────────────────────────
  const groupB = [
    { url: '/quan-tri/don-vi', file: 'quan_tri_don_vi_04_delete_confirm.png' },
    { url: '/quan-tri/chuc-vu', file: 'quan_tri_chuc_vu_04_delete_confirm.png' },
    { url: '/quan-tri/so-van-ban', file: 'quan_tri_so_van_ban_04_delete_confirm.png' },
    { url: '/quan-tri/loai-van-ban', file: 'quan_tri_loai_van_ban_04_delete_confirm.png' },
    { url: '/quan-tri/linh-vuc', file: 'quan_tri_linh_vuc_04_delete_confirm.png' },
    { url: '/quan-tri/nguoi-dung', file: 'quan_tri_nguoi_dung_04_delete_confirm.png' },
    { url: '/quan-tri/nhom-quyen', file: 'quan_tri_nhom_quyen_05_delete_confirm.png' },
    { url: '/quan-tri/nguoi-ky', file: 'quan_tri_nguoi_ky_04_delete_confirm.png' },
  ];

  for (const tc of groupB) {
    await runCase(`B:${tc.file}`, async () => {
      await gotoAndSettle(page, tc.url);
      // For nguoi-ky: tree on left, click a leaf (department with signers)
      if (tc.url === '/quan-tri/nguoi-ky') {
        // Try clicking each tree node until table has rows
        const treeNodes = page.locator('.ant-tree-treenode');
        const cnt = await treeNodes.count();
        for (let i = 1; i < Math.min(cnt, 12); i++) {
          await treeNodes.nth(i).click({ timeout: 3000 }).catch(() => {});
          await page.waitForTimeout(800);
          const rows = await page.locator('.ant-table-row').count();
          if (rows > 0) break;
        }
        // nguoi-ky uses direct trash icon (not dropdown)
        const trashBtn = page.locator('.ant-table-row').first().locator('.anticon-delete').first();
        await trashBtn.click({ timeout: 5000 });
        await page.waitForTimeout(1000);
        const r = await snap(page, tc.file, { fullPage: false });
        await closeOverlays(page);
        return r;
      }
      // Other pages: row dropdown → "Xóa"
      try {
        await openRowDropdownAndClick(page, 'Xóa');
      } catch (err) {
        // Some pages may have different label e.g. "Xóa người dùng", "Xóa nhóm quyền"
        try {
          await page.keyboard.press('Escape');
          await page.waitForTimeout(300);
          // Try another row click
          const moreBtn = page.locator('.ant-table-row').first().locator('.anticon-more').first();
          await moreBtn.click({ timeout: 5000 });
          await page.waitForTimeout(500);
          const menu = page.locator('.ant-dropdown-menu-item').filter({ hasText: /Xóa/ }).first();
          await menu.click({ timeout: 5000 });
          await page.waitForTimeout(1500);
        } catch (err2) {
          throw new Error('Không tìm thấy nút Xóa: ' + err2.message.split('\n')[0]);
        }
      }
      // Wait for modal animation
      await page.waitForTimeout(800);
      const r = await snap(page, tc.file, { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);
  }

  // ────────────────────────────────────────────────────────────────────
  // GROUP C — Drawer/Modal đặc biệt Quản trị (7)
  // ────────────────────────────────────────────────────────────────────
  await runCase('C:quan_tri_nguoi_dung_02_add_drawer.png', async () => {
    await gotoAndSettle(page, '/quan-tri/nguoi-dung');
    await clickButton(page, 'Thêm');
    const r = await snap(page, 'quan_tri_nguoi_dung_02_add_drawer.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('C:quan_tri_nguoi_dung_03_phan_quyen.png', async () => {
    await gotoAndSettle(page, '/quan-tri/nguoi-dung');
    await openRowDropdownAndClick(page, 'Phân quyền');
    const r = await snap(page, 'quan_tri_nguoi_dung_03_phan_quyen.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('C:quan_tri_nhom_quyen_02_add_drawer.png', async () => {
    await gotoAndSettle(page, '/quan-tri/nhom-quyen');
    await clickButton(page, 'Thêm');
    const r = await snap(page, 'quan_tri_nhom_quyen_02_add_drawer.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('C:quan_tri_nhom_quyen_03_perm_drawer.png', async () => {
    await gotoAndSettle(page, '/quan-tri/nhom-quyen');
    await openRowDropdownAndClick(page, 'Phân quyền');
    const r = await snap(page, 'quan_tri_nhom_quyen_03_perm_drawer.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('C:quan_tri_nhom_quyen_04_add_filled.png', async () => {
    await gotoAndSettle(page, '/quan-tri/nhom-quyen');
    await clickButton(page, 'Thêm');
    const inputs = page.locator('.ant-drawer-body input:not([type="hidden"]), .ant-drawer-body textarea');
    await inputs.nth(0).fill('Nhóm demo').catch(() => {});
    await inputs.nth(1).fill('Mô tả nhóm').catch(() => {});
    await page.waitForTimeout(500);
    const r = await snap(page, 'quan_tri_nhom_quyen_04_add_filled.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('C:quan_tri_nguoi_ky_02_add_modal.png', async () => {
    await gotoAndSettle(page, '/quan-tri/nguoi-ky');
    // Click first non-root tree node to enable "Thêm người ký" button
    const treeNodes = page.locator('.ant-tree-treenode');
    await treeNodes.nth(1).click({ timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(1000);
    await clickButton(page, 'Thêm người ký');
    const r = await snap(page, 'quan_tri_nguoi_ky_02_add_modal.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('C:quan_tri_nguoi_ky_03_add_filled.png', async () => {
    await gotoAndSettle(page, '/quan-tri/nguoi-ky');
    const treeNodes = page.locator('.ant-tree-treenode');
    await treeNodes.nth(1).click({ timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(1000);
    await clickButton(page, 'Thêm người ký');
    // Open the staff Select dropdown — find Select inside modal
    const sel = page.locator('.ant-modal .ant-select, .ant-drawer-body .ant-select').first();
    await sel.click({ timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(800);
    // Pick first option
    const opt = page.locator('.ant-select-item-option').first();
    await opt.click({ timeout: 5000 }).catch(() => {});
    await page.waitForTimeout(500);
    const r = await snap(page, 'quan_tri_nguoi_ky_03_add_filled.png');
    await closeOverlays(page);
    return r;
  }, results);

  // ────────────────────────────────────────────────────────────────────
  // GROUP D — Văn bản & HSCV nghiệp vụ (7)
  // ────────────────────────────────────────────────────────────────────
  await runCase('D:van_ban_den_02_add_drawer.png', async () => {
    await gotoAndSettle(page, '/van-ban-den');
    await clickButton(page, 'Thêm mới');
    const r = await snap(page, 'van_ban_den_02_add_drawer.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('D:van_ban_den_04_send_modal.png', async () => {
    const id = await fetchFirstId(page, '/van-ban-den?page=1&page_size=1');
    if (!id) throw new Error('Không có VB đến');
    await gotoAndSettle(page, `/van-ban-den/${id}`);
    await page.waitForTimeout(2000);
    // VB needs to be approved before "Gửi" button appears.
    // Check current state via DOM — look for "Gửi" button first.
    let sendBtn = page.locator('button:has-text("Gửi")').filter({ hasNotText: /liên thông|bút phê/i }).first();
    if (await sendBtn.count() === 0 || !(await sendBtn.isVisible().catch(() => false))) {
      // Try to approve first
      const approveBtn = page.locator('button:has-text("Duyệt")').first();
      if (await approveBtn.count() > 0 && await approveBtn.isVisible().catch(() => false)) {
        await approveBtn.click({ timeout: 3000 });
        // Wait for confirm modal if any
        await page.waitForTimeout(1000);
        // Click confirm OK if a modal appeared
        const okBtn = page.locator('.ant-modal-confirm-btns button.ant-btn-primary, .ant-modal-footer button.ant-btn-primary').first();
        if (await okBtn.count() > 0 && await okBtn.isVisible().catch(() => false)) {
          await okBtn.click({ timeout: 3000 }).catch(() => {});
        }
        // Wait for re-render
        await page.waitForTimeout(2500);
        // Reload to ensure fresh state
        await page.reload({ waitUntil: 'networkidle' });
        await page.waitForTimeout(2000);
        sendBtn = page.locator('button:has-text("Gửi")').filter({ hasNotText: /liên thông|bút phê/i }).first();
      }
    }
    if (await sendBtn.count() === 0) {
      throw new Error('Không thấy nút "Gửi" sau khi thử duyệt');
    }
    await sendBtn.click({ timeout: 5000 });
    await page.waitForTimeout(1500);
    const r = await snap(page, 'van_ban_den_04_send_modal.png', { fullPage: false });
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('D:van_ban_di_02_drawer.png', async () => {
    await gotoAndSettle(page, '/van-ban-di');
    await clickButton(page, 'Thêm mới');
    const r = await snap(page, 'van_ban_di_02_drawer.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('D:van_ban_du_thao_03_drawer_add.png', async () => {
    await gotoAndSettle(page, '/van-ban-du-thao');
    await clickButton(page, 'Thêm mới');
    const r = await snap(page, 'van_ban_du_thao_03_drawer_add.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('D:hscv_danh_sach_02_create_drawer.png', async () => {
    await gotoAndSettle(page, '/ho-so-cong-viec');
    await clickButton(page, 'Tạo hồ sơ mới');
    const r = await snap(page, 'hscv_danh_sach_02_create_drawer.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('D:cau_hinh_gui_nhanh_02_selected.png', async () => {
    await gotoAndSettle(page, '/cau-hinh-gui-nhanh');
    await page.waitForTimeout(1500);
    // Tick first 2-3 checkboxes in left table
    const checks = page.locator('.ant-table-row .ant-checkbox-input');
    const n = Math.min(3, await checks.count());
    for (let i = 0; i < n; i++) {
      try { await checks.nth(i).click({ timeout: 2000, force: true }); } catch {}
    }
    await page.waitForTimeout(800);
    const r = await snap(page, 'cau_hinh_gui_nhanh_02_selected.png');
    return r;
  }, results);

  await runCase('D:hscv_bao_cao_02_filter.png', async () => {
    await page.goto(`${BASE_URL}/ho-so-cong-viec/bao-cao`, { waitUntil: 'domcontentloaded', timeout: 60000 });
    await page.waitForTimeout(8000);
    // Open unit Select — pick first option to apply a filter
    const unitSel = page.locator('.filter-row .ant-select').first();
    try {
      await unitSel.click({ timeout: 5000 });
      await page.waitForTimeout(800);
      const opt = page.locator('.ant-select-item-option').first();
      if (await opt.count() > 0) {
        await opt.click({ timeout: 3000 });
      }
      await page.waitForTimeout(500);
      // Close any open dropdown
      await page.keyboard.press('Escape');
      await page.waitForTimeout(500);
    } catch {}
    const r = await snap(page, 'hscv_bao_cao_02_filter.png');
    return r;
  }, results);

  // ────────────────────────────────────────────────────────────────────
  // GROUP E — Thông báo & Tài khoản (2)
  // ────────────────────────────────────────────────────────────────────
  await runCase('E:thong_bao_03_create_drawer.png', async () => {
    await gotoAndSettle(page, '/thong-bao');
    await clickButton(page, 'Tạo thông báo');
    const r = await snap(page, 'thong_bao_03_create_drawer.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('E:thong_tin_ca_nhan_02_change_password.png', async () => {
    await gotoAndSettle(page, '/thong-tin-ca-nhan');
    // Tab "Đổi mật khẩu" is default — just snap full page
    await page.waitForTimeout(1500);
    const r = await snap(page, 'thong_tin_ca_nhan_02_change_password.png');
    return r;
  }, results);

  // ────────────────────────────────────────────────────────────────────
  // GROUP F — Ký số (5)
  // ────────────────────────────────────────────────────────────────────
  await runCase('F:ky_so_cau_hinh_02_edit_drawer.png', async () => {
    await gotoAndSettle(page, '/ky-so/cau-hinh');
    await page.waitForTimeout(1500);
    // Click "Sửa cấu hình" (first provider card)
    await clickButton(page, 'Sửa cấu hình');
    const r = await snap(page, 'ky_so_cau_hinh_02_edit_drawer.png');
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('F:ky_so_cau_hinh_03_activate_confirm.png', async () => {
    await gotoAndSettle(page, '/ky-so/cau-hinh');
    await page.waitForTimeout(1500);
    // Click "Kích hoạt" — opens Modal.confirm (or warning modal if not configured)
    const btn = page.locator('button:has-text("Kích hoạt")').first();
    await btn.click({ timeout: 5000 });
    await page.waitForTimeout(1200);
    const r = await snap(page, 'ky_so_cau_hinh_03_activate_confirm.png', { fullPage: false });
    await closeOverlays(page);
    return r;
  }, results);

  await runCase('F:ky_so_tai_khoan_02_verified.png', async () => {
    await gotoAndSettle(page, '/ky-so/tai-khoan');
    await page.waitForTimeout(2000);
    // Check if there's a "Đã xác thực" badge already; if not, skip
    const verifiedBadge = page.locator('text=Đã xác thực').first();
    if (await verifiedBadge.count() === 0) {
      throw new Error('Chưa có badge "Đã xác thực" — bỏ qua');
    }
    const r = await snap(page, 'ky_so_tai_khoan_02_verified.png');
    return r;
  }, results);

  await runCase('F:ky_so_tai_khoan_03_mysign_certs.png', async () => {
    await gotoAndSettle(page, '/ky-so/tai-khoan');
    await page.waitForTimeout(2000);
    const btn = page.locator('button:has-text("Tải danh sách chứng thư")').first();
    if (await btn.count() === 0) {
      throw new Error('Provider không phải MySign — không có nút Tải CTS');
    }
    // Click — but it may fail without valid Mã định danh. Best effort.
    try { await btn.click({ timeout: 3000 }); } catch {}
    await page.waitForTimeout(1500);
    const r = await snap(page, 'ky_so_tai_khoan_03_mysign_certs.png');
    return r;
  }, results);

  await runCase('F:ky_so_danh_sach_02_sign_modal_pending.png', async () => {
    await gotoAndSettle(page, '/ky-so/danh-sach');
    await page.waitForTimeout(2000);
    // Look for sign action buttons in table row
    const signBtn = page.locator('button:has-text("Ký")').first();
    if (await signBtn.count() === 0) {
      throw new Error('Không có tài liệu pending để ký — bỏ qua');
    }
    try {
      await signBtn.click({ timeout: 3000 });
      await page.waitForTimeout(2000);
    } catch (err) {
      throw new Error('Click nút Ký fail: ' + err.message.split('\n')[0]);
    }
    const r = await snap(page, 'ky_so_danh_sach_02_sign_modal_pending.png', { fullPage: false });
    await closeOverlays(page);
    return r;
  }, results);

  // ────────────────────────────────────────────────────────────────────
  // GROUP G — HSCV chi tiết (6)
  // ────────────────────────────────────────────────────────────────────
  const hscvId = await fetchFirstId(page, '/ho-so-cong-viec?page=1&page_size=1');
  if (!hscvId) {
    console.log('\n[G] Không có HSCV để chụp — skip nhóm G');
  } else {
    const goDetail = async () => {
      await page.goto(`${BASE_URL}/ho-so-cong-viec/${hscvId}`, { waitUntil: 'networkidle', timeout: 30000 });
      await page.waitForTimeout(2500);
    };

    await runCase('G:hscv_chi_tiet_02_tab_thong_tin.png', async () => {
      await goDetail();
      // Default tab is "info" — just snap
      const r = await snap(page, 'hscv_chi_tiet_02_tab_thong_tin.png');
      return r;
    }, results);

    await runCase('G:hscv_chi_tiet_03_tab_can_bo.png', async () => {
      await goDetail();
      const tab = page.locator('.ant-tabs-tab:has-text("Cán bộ xử lý")').first();
      await tab.click({ timeout: 5000 });
      await page.waitForTimeout(2000);
      const r = await snap(page, 'hscv_chi_tiet_03_tab_can_bo.png');
      return r;
    }, results);

    await runCase('G:hscv_chi_tiet_04_tab_file.png', async () => {
      await goDetail();
      const tab = page.locator('.ant-tabs-tab:has-text("File đính kèm")').first();
      await tab.click({ timeout: 5000 });
      await page.waitForTimeout(2000);
      const r = await snap(page, 'hscv_chi_tiet_04_tab_file.png');
      return r;
    }, results);

    await runCase('G:hscv_chi_tiet_05_toolbar.png', async () => {
      await goDetail();
      // Just snap full page — toolbar at top
      const r = await snap(page, 'hscv_chi_tiet_05_toolbar.png');
      return r;
    }, results);

    await runCase('G:hscv_chi_tiet_06_chuyen_tiep.png', async () => {
      await goDetail();
      const btn = page.locator('button:has-text("Chuyển tiếp HSCV")').first();
      if (await btn.count() === 0) {
        throw new Error('Không có nút "Chuyển tiếp HSCV" — trạng thái HSCV không phù hợp');
      }
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'hscv_chi_tiet_06_chuyen_tiep.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);

    await runCase('G:hscv_chi_tiet_07_tra_ve_tu_choi.png', async () => {
      await goDetail();
      // Look for "Trả về" or "Từ chối" button
      let btn = page.locator('button:has-text("Trả về")').first();
      if (await btn.count() === 0 || !(await btn.isVisible().catch(() => false))) {
        btn = page.locator('button:has-text("Từ chối")').first();
      }
      if (await btn.count() === 0) {
        throw new Error('HSCV không ở trạng thái "Chờ trình ký/Đã trình ký" — bỏ qua');
      }
      await btn.click({ timeout: 5000 });
      await page.waitForTimeout(1500);
      const r = await snap(page, 'hscv_chi_tiet_07_tra_ve_tu_choi.png', { fullPage: false });
      await closeOverlays(page);
      return r;
    }, results);
  }

  await browser.close();

  // ────────────────────────────────────────────────────────────────────
  // SUMMARY
  // ────────────────────────────────────────────────────────────────────
  const ok = results.filter((r) => r.ok).length;
  const fail = results.filter((r) => !r.ok).length;
  console.log('\n──── Summary ────');
  console.log(`OK:   ${ok}/${results.length}`);
  console.log(`FAIL: ${fail}`);
  if (fail > 0) {
    console.log('\nFailed:');
    results.filter((r) => !r.ok).forEach((r) => console.log(`  ${r.file}: ${r.err}`));
  }
})();
