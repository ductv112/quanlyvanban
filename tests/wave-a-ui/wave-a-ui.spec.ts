/**
 * tests/wave-a-ui/wave-a-ui.spec.ts — Wave A UI testcases (22 TC, category=UI)
 *
 * Coverage:
 *   - 5 TC Login UI (TC-AUTH-011..015)
 *   - 3 TC Profile UI (TC-AUTH-019..021)
 *   - 5 TC Dashboard UI (TC-DASH-007..011)
 *   - 2 TC Bell notification (TC-NOTIF-004, 005)
 *   - 2 TC Notice page (TC-NOTIF-012, 013)
 *   - 2 TC Notice drawer (TC-NOTIF-024, 025)
 *   - 3 TC Bookmark (TC-MARK-009, 010, 011)
 *
 * Run: npx playwright test tests/wave-a-ui/ --reporter=line --workers=1
 *
 * Strategy:
 *   - Reuse storageState (admin / canbo) qua test.use({ storageState })
 *   - Title format: 'TC-XXX-NNN <Vietnamese title>' để Excel parser map ngược
 *   - Tag @wave-a-ui để filter
 *   - TC-AUTH-014 (network slow): dùng page.route() throttle response
 *   - TC-NOTIF-004 (99+): mock /api/notifications/unread-count → 100
 *   - TC-NOTIF-005 (empty bell): mock list → []
 *   - TC-NOTIF-013, MARK-011 (pagination > 20): SKIP nếu fixture không seed > 20 records
 *   - TC-DASH-009/010 (empty state): SKIP nếu test_canbo có data — kiểm tra runtime
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 15000;

// ─────────────────────────────────────────────────────────────────────────────
// AUTH UI (5 TC) — Login page, không cần auth
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave A UI — Auth Login @wave-a-ui', () => {
  test.use({ storageState: { cookies: [], origins: [] } });

  test('TC-AUTH-011 Hiển thị bố cục 2 cột trên màn hình lớn', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.setViewportSize({ width: 1280, height: 800 });
    await page.goto('/login');

    // Cột trái: branding
    await expect(page.locator('.login-left')).toBeVisible();
    await expect(page.locator('.login-brand-title')).toHaveText('Quản lý Văn bản');
    await expect(page.locator('.login-brand-subtitle')).toContainText(
      'Hệ thống quản lý văn bản điện tử'
    );

    // 3 dòng tính năng
    const features = page.locator('.login-feature-item');
    await expect(features).toHaveCount(3);
    await expect(features.nth(0)).toContainText('Bảo mật');
    await expect(features.nth(1)).toContainText('Liên thông');
    await expect(features.nth(2)).toContainText('Cộng tác');

    // Cột phải: form login
    await expect(page.locator('.login-right')).toBeVisible();
    await expect(page.locator('.login-form-title')).toHaveText('Đăng nhập');
    await expect(page.getByLabel('Tên đăng nhập')).toBeVisible();
    await expect(page.getByLabel('Mật khẩu')).toBeVisible();
    await expect(page.getByText('Ghi nhớ đăng nhập')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Đăng nhập' })).toBeVisible();

    // Footer
    await expect(page.locator('.login-footer')).toContainText('Phiên bản 2.0');
    await expect(page.locator('.login-footer')).toContainText('Chuyển đổi số Doanh nghiệp');

    // Verify 2-col layout: left + right side-by-side (left.x < right.x)
    const leftBox = await page.locator('.login-left').boundingBox();
    const rightBox = await page.locator('.login-right').boundingBox();
    expect(leftBox).not.toBeNull();
    expect(rightBox).not.toBeNull();
    expect(rightBox!.x).toBeGreaterThan(leftBox!.x);
  });

  test('TC-AUTH-012 Hiển thị xếp chồng dọc trên thiết bị di động', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.setViewportSize({ width: 375, height: 812 });
    await page.goto('/login');

    // Form vẫn hiển thị
    await expect(page.locator('.login-form-title')).toHaveText('Đăng nhập');
    await expect(page.getByLabel('Tên đăng nhập')).toBeVisible();
    await expect(page.getByLabel('Mật khẩu')).toBeVisible();
    await expect(page.getByRole('button', { name: 'Đăng nhập' })).toBeVisible();

    // Mobile layout: form chiếm full width hoặc left ẩn — không tràn ngang
    const formWrapper = page.locator('.login-form-wrapper');
    const box = await formWrapper.boundingBox();
    expect(box).not.toBeNull();
    expect(box!.width).toBeLessThanOrEqual(375);
  });

  test('TC-AUTH-013 Bật/tắt hiển thị mật khẩu bằng nút con mắt', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/login');
    const pwdInput = page.getByLabel('Mật khẩu');
    await pwdInput.fill('Admin@123');
    // Default: type="password"
    await expect(pwdInput).toHaveAttribute('type', 'password');

    // Eye toggle (AntD Input.Password): .ant-input-password-icon
    const eyeBtn = page.locator('.ant-input-password-icon').first();
    await eyeBtn.click();
    await expect(pwdInput).toHaveAttribute('type', 'text');

    await eyeBtn.click();
    await expect(pwdInput).toHaveAttribute('type', 'password');
  });

  test('TC-AUTH-014 Trạng thái loading của nút Đăng nhập trong khi xử lý', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Throttle login API: delay 2s
    await page.route('**/api/auth/login', async (route) => {
      await new Promise((r) => setTimeout(r, 2000));
      await route.continue();
    });

    await page.goto('/login');
    await page.getByLabel('Tên đăng nhập').fill('test_admin');
    await page.getByLabel('Mật khẩu').fill('Test@123');
    const btn = page.getByRole('button', { name: 'Đăng nhập' });
    await btn.click();

    // Trong khi đang fetch: button có class loading hoặc icon loading
    const btnClass = await btn.getAttribute('class');
    expect(btnClass).toMatch(/loading|disabled/i);
    // Spinner icon AntD: .ant-btn-loading-icon hoặc .anticon-loading
    const spinner = page.locator('.ant-btn-loading-icon, .anticon-loading').first();
    await expect(spinner).toBeVisible({ timeout: 1500 });
  });

  test('TC-AUTH-015 Mặc định ô Ghi nhớ đăng nhập đã được tích', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/login');

    // AntD Checkbox: input[type=checkbox] bên trong .ant-checkbox
    const checkbox = page.locator('.ant-checkbox-input').first();
    await expect(checkbox).toBeChecked();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE UI (3 TC)
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave A UI — Profile (admin) @wave-a-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-AUTH-019 Hiển thị banner và bảng thông tin tài khoản đầy đủ', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/thong-tin-ca-nhan');
    await expect(page).toHaveURL(/thong-tin-ca-nhan/);

    // Banner: avatar + họ tên + @username
    const profileHeader = page.locator('.profile-header');
    await expect(profileHeader).toBeVisible();
    await expect(profileHeader.locator('.ant-avatar').first()).toBeVisible();
    await expect(profileHeader).toContainText('@test_admin');

    // Nhãn "Quản trị viên" (admin)
    await expect(profileHeader.getByText('Quản trị viên')).toBeVisible();

    // Bảng thông tin: Descriptions với 7 dòng label
    const labels = ['Họ và tên', 'Tên đăng nhập', 'Email', 'Số điện thoại', 'Chức vụ', 'Phòng ban', 'Đơn vị'];
    for (const label of labels) {
      await expect(page.locator('.ant-descriptions-item-label').filter({ hasText: label }).first())
        .toBeVisible();
    }
  });

  test('TC-AUTH-020 Trường thiếu dữ liệu hiển thị "Chưa cập nhật"', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Mock /me API trả về user thiếu email + phone (synthetic response — không dùng route.fetch)
    await page.route('**/api/auth/me', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: {
            staffId: 9001, unitId: 1, departmentId: 1,
            username: 'test_admin', fullName: 'TEST Quản trị',
            email: null, phone: null, image: '', isAdmin: true,
            gender: 1, birthDate: null, address: '',
            positionId: 1, positionName: 'Giám đốc',
            departmentName: 'UBND tỉnh Lào Cai',
            unitName: 'UBND tỉnh Lào Cai',
            roles: ['Quản trị hệ thống'],
            lastLoginAt: '2026-05-06T10:52:59Z',
            createdAt: '2026-05-06T10:05:25Z',
            signPhone: '', signImage: '', signImageUrl: null,
          },
        }),
      });
    });

    await page.goto('/thong-tin-ca-nhan');
    await expect(page).toHaveURL(/thong-tin-ca-nhan/);
    // Đợi profile-header render (xác nhận store đã pick up mock /me)
    await expect(page.locator('.profile-header')).toBeVisible({ timeout: 10000 });

    // Phải thấy ít nhất 2 "Chưa cập nhật" (email + phone)
    const placeholder = page.locator('.ant-descriptions-item-content').filter({ hasText: 'Chưa cập nhật' });
    await expect(placeholder.first()).toBeVisible({ timeout: 5000 });
    const count = await placeholder.count();
    expect(count).toBeGreaterThanOrEqual(2);
  });
});

test.describe('Wave A UI — Profile (canbo non-admin) @wave-a-ui', () => {
  test.use({ storageState: storageStateFor('canbo') });

  test('TC-AUTH-021 Tài khoản không phải Quản trị viên không hiển thị nhãn "Quản trị viên"', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/thong-tin-ca-nhan');
    await expect(page).toHaveURL(/thong-tin-ca-nhan/);

    const profileHeader = page.locator('.profile-header');
    await expect(profileHeader).toBeVisible();
    await expect(profileHeader).toContainText('@test_canbo');

    // KHÔNG có nhãn "Quản trị viên"
    await expect(profileHeader.getByText('Quản trị viên')).toHaveCount(0);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD UI (5 TC)
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave A UI — Dashboard (admin) @wave-a-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-DASH-007 Hiển thị 6 tháng gần nhất trong biểu đồ Văn bản đến/đi theo tháng', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/);

    // Chart title section
    await expect(page.getByText('Văn bản đến/đi theo tháng')).toBeVisible({ timeout: 10000 });

    // Đợi chart render — @ant-design/charts dùng canvas
    const chartCard = page.locator('.page-card').filter({ hasText: 'Văn bản đến/đi theo tháng' });
    await expect(chartCard).toBeVisible();
    // Chờ canvas hoặc svg render
    const canvas = chartCard.locator('canvas, svg').first();
    await expect(canvas).toBeVisible({ timeout: 10000 });
  });

  test('TC-DASH-008 Biểu đồ "HSCV theo trạng thái" dạng tròn donut', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/dashboard');
    await expect(page.getByText('HSCV theo trạng thái')).toBeVisible({ timeout: 10000 });

    const chartCard = page.locator('.page-card').filter({ hasText: 'HSCV theo trạng thái' });
    await expect(chartCard).toBeVisible();
    // Chart hoặc empty state
    const canvasOrEmpty = chartCard.locator('canvas, svg, :text("Chưa có dữ liệu")').first();
    await expect(canvasOrEmpty).toBeVisible({ timeout: 10000 });
  });

  test('TC-DASH-009 Trạng thái rỗng của bảng "Văn bản mới nhận"', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Force empty bằng cách mock API
    await page.route('**/api/dashboard/recent-incoming**', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: [] }),
      });
    });

    await page.goto('/dashboard');
    await expect(page.getByText('Văn bản mới nhận')).toBeVisible({ timeout: 10000 });

    // AntD Table empty: locale.emptyText = 'Chưa có văn bản mới'
    const emptyText = page.getByText('Chưa có văn bản mới').first();
    await expect(emptyText).toBeVisible({ timeout: 10000 });
  });

  test('TC-DASH-010 Trạng thái rỗng khung "Việc sắp tới hạn"', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Force empty
    await page.route('**/api/dashboard/upcoming-tasks**', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: [] }),
      });
    });

    await page.goto('/dashboard');
    await expect(page.getByText('Việc sắp tới hạn').first()).toBeVisible({ timeout: 10000 });
    await expect(page.getByText('Không có việc sắp tới hạn')).toBeVisible({ timeout: 10000 });
  });

  test('TC-DASH-011 Nhãn độ khẩn của VB đến với màu sắc đúng', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Mock 3 mức urgency
    await page.route('**/api/dashboard/recent-incoming**', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: [
            { id: 1, doc_code: 'VB001', abstract: 'Test hỏa tốc', received_date: '2026-05-01', urgency_name: 'Hỏa tốc' },
            { id: 2, doc_code: 'VB002', abstract: 'Test khẩn', received_date: '2026-05-01', urgency_name: 'Khẩn' },
            { id: 3, doc_code: 'VB003', abstract: 'Test thường', received_date: '2026-05-01', urgency_name: 'Thường' },
          ],
        }),
      });
    });

    await page.goto('/dashboard');
    await expect(page.getByText('Văn bản mới nhận')).toBeVisible({ timeout: 10000 });

    // Verify 3 tags với màu khác nhau (AntD Tag class: .ant-tag-red, .ant-tag-orange, .ant-tag-blue)
    const incomingCard = page.locator('.page-card').filter({ hasText: 'Văn bản mới nhận' });
    await expect(incomingCard.locator('.ant-tag-red').filter({ hasText: 'Hỏa tốc' })).toBeVisible();
    await expect(incomingCard.locator('.ant-tag-orange').filter({ hasText: 'Khẩn' })).toBeVisible();
    await expect(incomingCard.locator('.ant-tag-blue').filter({ hasText: 'Thường' })).toBeVisible();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// NOTIF — BELL (2 TC)
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave A UI — Bell notification @wave-a-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-NOTIF-004 Chấm đỏ hiển thị "99+" khi vượt 99 thông báo chưa đọc', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Mock unread-count → 100 (> 99 → show '99+')
    await page.route('**/api/notifications/unread-count', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: { count: 150 } }),
      });
    });

    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/);

    // Bell badge — AntD Badge với overflowCount=99 → render '99+'
    const badge = page.locator('.main-header .ant-badge-count, .ant-badge-count').first();
    await expect(badge).toBeVisible({ timeout: 10000 });
    await expect(badge).toContainText('99+');
  });

  test('TC-NOTIF-005 Trạng thái rỗng dropdown khi không có thông báo', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Note: route order matters — broader pattern first, specific override later
    await page.route('**/api/notifications**', async (route) => {
      const url = route.request().url();
      if (url.includes('/unread-count')) {
        await route.fulfill({
          status: 200,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ success: true, data: { count: 0 } }),
        });
        return;
      }
      // List endpoint
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: [], total: 0, page: 1, page_size: 10 }),
      });
    });

    await page.goto('/dashboard');
    await expect(page).toHaveURL(/\/dashboard/);

    // Bell icon trong header — Dropdown trigger bao quanh icon. Click icon hoặc parent.
    const bellIcon = page.locator('.main-header .anticon-bell').first();
    await expect(bellIcon).toBeVisible({ timeout: 10000 });
    // Click trigger với retry — Dropdown có thể bỏ lỡ click đầu nếu đang animation
    await bellIcon.click();

    // Đợi dropdown overlay (notif-bell-overlay class) hiện
    const overlay = page.locator('.notif-bell-overlay').first();
    await expect(overlay).toBeVisible({ timeout: 8000 });

    // Empty state text trong overlay
    await expect(overlay.getByText('Không có thông báo')).toBeVisible({ timeout: 5000 });
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// NOTIF — Trang Thông báo nội bộ (2 TC)
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave A UI — Notice page @wave-a-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-NOTIF-012 Trạng thái rỗng khi danh sách trống', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Mock list = empty
    await page.route('**/api/thong-bao**', async (route) => {
      const req = route.request();
      // Chỉ mock GET list, không mock POST
      if (req.method() === 'GET' && !req.url().includes('/mark-all-read')) {
        await route.fulfill({
          status: 200,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ success: true, data: { list: [], total: 0 } }),
        });
        return;
      }
      await route.continue();
    });

    await page.goto('/thong-bao');
    await expect(page).toHaveURL(/thong-bao/);
    await expect(page.getByText('Chưa có thông báo').first()).toBeVisible({ timeout: 10000 });
    await expect(
      page.getByText('Hệ thống sẽ thông báo khi có văn bản mới hoặc việc được giao.')
    ).toBeVisible();
  });

  test('TC-NOTIF-013 Phân trang khi tổng số > 20', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Mock list = 20 items + total=25 → pagination hiển thị
    const items = Array.from({ length: 20 }, (_, i) => ({
      id: i + 1,
      title: `Thông báo ${i + 1}`,
      content: `Nội dung ${i + 1}`,
      is_read: false,
      created_at: '2026-05-01T10:00:00Z',
    }));
    await page.route('**/api/thong-bao**', async (route) => {
      const req = route.request();
      if (req.method() === 'GET' && !req.url().includes('/mark-all-read')) {
        await route.fulfill({
          status: 200,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({ success: true, data: { list: items, total: 25 } }),
        });
        return;
      }
      await route.continue();
    });

    await page.goto('/thong-bao');
    await expect(page).toHaveURL(/thong-bao/);

    // 20 notif items render
    await expect(page.locator('.notif-item').first()).toBeVisible({ timeout: 10000 });

    // AntD Pagination component visible
    const pagination = page.locator('.ant-pagination').first();
    await expect(pagination).toBeVisible({ timeout: 5000 });
    // Có ít nhất nút trang 2
    await expect(pagination.locator('.ant-pagination-item-2')).toBeVisible();
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// NOTIF — Drawer tạo thông báo (2 TC) — admin only
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave A UI — Notice drawer (admin) @wave-a-ui', () => {
  test.use({ storageState: storageStateFor('admin') });

  test('TC-NOTIF-024 Bộ đếm ký tự cập nhật khi gõ', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    await page.goto('/thong-bao');
    await expect(page).toHaveURL(/thong-bao/);

    // Click "Tạo thông báo" button (admin only) — top button (NOT footer)
    // Top button locate trong page-header section.
    const createBtn = page.locator('.page-header').getByRole('button', { name: 'Tạo thông báo' });
    await expect(createBtn).toBeVisible({ timeout: 10000 });
    await createBtn.click();

    // Drawer opens — AntD 6 dùng [role="dialog"] (snapshot xác nhận)
    const drawer = page.getByRole('dialog', { name: 'Tạo thông báo mới' });
    await expect(drawer).toBeVisible({ timeout: 5000 });

    // Type vào ô Tiêu đề (maxLength=300)
    const titleInput = drawer.getByRole('textbox', { name: /Tiêu đề/i });
    await titleInput.fill('ABC');
    // Counter "x / 300" — AntD render show count as text
    await expect(drawer.getByText('3 / 300', { exact: false }).first()).toBeVisible();

    // Type vào ô Nội dung (textarea, maxLength=5000)
    const contentArea = drawer.getByRole('textbox', { name: /Nội dung/i });
    await contentArea.fill('Hello world');
    await expect(drawer.getByText('11 / 5000', { exact: false }).first()).toBeVisible();
  });

  test('TC-NOTIF-025 Đóng drawer bằng nút X', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Spy POST /api/thong-bao — phải KHÔNG bị gọi
    let createCalled = false;
    page.on('request', (req) => {
      if (req.method() === 'POST' && req.url().includes('/api/thong-bao') && !req.url().includes('mark-')) {
        createCalled = true;
      }
    });

    await page.goto('/thong-bao');
    await expect(page).toHaveURL(/thong-bao/);

    const createBtn = page.locator('.page-header').getByRole('button', { name: 'Tạo thông báo' });
    await expect(createBtn).toBeVisible({ timeout: 10000 });
    await createBtn.click();

    const drawer = page.getByRole('dialog', { name: 'Tạo thông báo mới' });
    await expect(drawer).toBeVisible({ timeout: 5000 });

    // Nút X close — AntD Drawer 6: button có aria-label="Đóng" (snapshot xác nhận)
    const closeBtn = drawer.getByRole('button', { name: 'Đóng' });
    await expect(closeBtn).toBeVisible();

    await closeBtn.click();
    // Drawer closes (animation ~300ms)
    await expect(drawer).toBeHidden({ timeout: 3000 });
    expect(createCalled).toBe(false);
  });
});

// ─────────────────────────────────────────────────────────────────────────────
// MARK — Bookmark page (3 TC)
// ─────────────────────────────────────────────────────────────────────────────

test.describe('Wave A UI — Bookmark @wave-a-ui', () => {
  test.use({ storageState: storageStateFor('canbo') });

  test('TC-MARK-009 Trạng thái rỗng khi tab không có dữ liệu', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Mock all 3 bookmark APIs → empty
    const empty = { success: true, data: [] };
    await page.route('**/danh-dau-ca-nhan', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify(empty),
      });
    });

    await page.goto('/van-ban-danh-dau');
    await expect(page).toHaveURL(/van-ban-danh-dau/);

    // Click tab "Dự thảo (0)"
    const tabDraft = page.locator('.ant-tabs-tab').filter({ hasText: 'Dự thảo' });
    await expect(tabDraft).toBeVisible({ timeout: 10000 });
    await tabDraft.click();

    // Empty state: "Chưa đánh dấu văn bản nào"
    await expect(page.getByText('Chưa đánh dấu văn bản nào').first()).toBeVisible({ timeout: 5000 });
  });

  test('TC-MARK-010 Nhãn loại có màu phân biệt theo phân hệ', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Mock 3 loại bookmark
    const baseDoc = {
      note_id: 0, doc_id: 1, note: '', is_important: false,
      created_at: '2026-05-01T10:00:00Z',
      doc_number: 1, doc_notation: 'KH-01', doc_abstract: 'Abc',
      doc_received_date: '2026-05-01', doc_publish_unit: 'UBND',
    };
    await page.route('**/van-ban-den/danh-dau-ca-nhan', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: [{ ...baseDoc, note_id: 1, doc_id: 1 }] }),
      });
    });
    await page.route('**/van-ban-di/danh-dau-ca-nhan', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: [{ ...baseDoc, note_id: 2, doc_id: 2 }] }),
      });
    });
    await page.route('**/van-ban-du-thao/danh-dau-ca-nhan', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: [{ ...baseDoc, note_id: 3, doc_id: 3 }] }),
      });
    });

    await page.goto('/van-ban-danh-dau');
    await expect(page).toHaveURL(/van-ban-danh-dau/);

    // Tab "Tất cả" mặc định
    await expect(page.locator('.ant-tabs-tab-active')).toContainText('Tất cả', { timeout: 10000 });

    // Verify tags trong table: VB đến (blue), VB đi (green), VB dự thảo (orange)
    await expect(page.locator('.ant-tag-blue').filter({ hasText: 'VB đến' }).first())
      .toBeVisible({ timeout: 5000 });
    await expect(page.locator('.ant-tag-green').filter({ hasText: 'VB đi' }).first()).toBeVisible();
    await expect(page.locator('.ant-tag-orange').filter({ hasText: 'VB dự thảo' }).first())
      .toBeVisible();
  });

  test('TC-MARK-011 Phân trang khi tổng số > 20', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    // Mock 25 bookmarks (all incoming)
    const items = Array.from({ length: 25 }, (_, i) => ({
      note_id: i + 1, doc_id: i + 1, note: '', is_important: false,
      created_at: '2026-05-01T10:00:00Z',
      doc_number: i + 1, doc_notation: `KH-${i + 1}`, doc_abstract: `Abstract ${i + 1}`,
      doc_received_date: '2026-05-01', doc_publish_unit: 'UBND',
    }));
    await page.route('**/van-ban-den/danh-dau-ca-nhan', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: items }),
      });
    });
    await page.route('**/van-ban-di/danh-dau-ca-nhan', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: [] }),
      });
    });
    await page.route('**/van-ban-du-thao/danh-dau-ca-nhan', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({ success: true, data: [] }),
      });
    });

    await page.goto('/van-ban-danh-dau');
    await expect(page).toHaveURL(/van-ban-danh-dau/);

    // Pagination visible — pageSize=20, total=25 → có nút trang 2
    const pagination = page.locator('.ant-pagination').first();
    await expect(pagination).toBeVisible({ timeout: 10000 });
    await expect(pagination.locator('.ant-pagination-item-2')).toBeVisible();
  });
});
