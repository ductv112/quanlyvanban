/**
 * tests/wave-31c-ui/bookmark-ui.spec.ts — Wave 31c UI follow-up: Bookmark
 *
 * Coverage SKIP UI từ Wave a (22-RESULTS.md) chưa cover ở wave-a-ui.spec.ts:
 *   - TC-MARK-008 — Tab filter + bộ đếm số lượng theo loại
 *
 * TC đã cover ở wave-a-ui.spec.ts:
 *   - TC-MARK-009 (empty state)
 *   - TC-MARK-010 (tag color theo doc_type)
 *   - TC-MARK-011 (pagination > 20 — SKIP nếu fixture không seed > 20)
 *
 * SKIP intentional:
 *   - Browser print dialog (window.print) — OS-level
 *
 * Run: npx playwright test tests/wave-31c-ui/bookmark-ui.spec.ts --reporter=line --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 20000;

test.describe('Wave 31c UI — Bookmark page (canbo) @wave-31c-ui', () => {
  test.use({ storageState: storageStateFor('canbo') });

  test('TC-MARK-008 Tab filter "Tất cả / VB đến / VB đi / Dự thảo" hiển thị + đếm theo loại', async ({
    page,
  }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Mock 3 endpoints để đảm bảo có data với mọi loại
    await page.route('**/api/van-ban-den/danh-dau-ca-nhan**', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: [
            {
              note_id: 101,
              doc_id: 90001,
              doc_type: 'incoming',
              note: 'Test note 1',
              is_important: true,
              created_at: '2026-05-01T10:00:00Z',
              doc_number: 1,
              doc_notation: 'KH-001',
              doc_abstract: 'TEST: VB den danh dau',
              doc_received_date: '2026-05-01',
              doc_publish_unit: 'UBND',
            },
          ],
        }),
      });
    });

    await page.route('**/api/van-ban-di/danh-dau-ca-nhan**', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: [
            {
              note_id: 201,
              doc_id: 90011,
              doc_type: 'outgoing',
              note: 'Test note 2',
              is_important: false,
              created_at: '2026-05-02T10:00:00Z',
              doc_number: 11,
              doc_notation: 'KH-011',
              doc_abstract: 'TEST: VB di danh dau',
              doc_received_date: '2026-05-02',
              doc_publish_unit: 'CQ ban hanh',
            },
            {
              note_id: 202,
              doc_id: 90012,
              doc_type: 'outgoing',
              note: 'Test note 3',
              is_important: false,
              created_at: '2026-05-02T10:00:00Z',
              doc_number: 12,
              doc_notation: 'KH-012',
              doc_abstract: 'TEST: VB di 2',
              doc_received_date: '2026-05-02',
              doc_publish_unit: 'CQ ban hanh',
            },
          ],
        }),
      });
    });

    await page.route('**/api/van-ban-du-thao/danh-dau-ca-nhan**', async (route) => {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: [
            {
              note_id: 301,
              doc_id: 90021,
              doc_type: 'drafting',
              note: 'Test note 4',
              is_important: false,
              created_at: '2026-05-03T10:00:00Z',
              doc_number: 21,
              doc_notation: 'DT-021',
              doc_abstract: 'TEST: Du thao danh dau',
              doc_received_date: '2026-05-03',
              doc_publish_unit: 'UBND',
            },
          ],
        }),
      });
    });

    await page.goto('/van-ban-danh-dau');
    await expect(page).toHaveURL(/van-ban-danh-dau/, { timeout: 10000 });

    // Card title
    await expect(page.getByText('Văn bản đánh dấu cá nhân').first()).toBeVisible({
      timeout: 10000,
    });

    // 4 tab labels: Tất cả (4) / VB đến (1) / VB đi (2) / Dự thảo (1)
    const tabBar = page.locator('.ant-tabs-tab');
    await expect(tabBar.filter({ hasText: /Tất cả \(4\)/ })).toHaveCount(1);
    await expect(tabBar.filter({ hasText: /VB đến \(1\)/ })).toHaveCount(1);
    await expect(tabBar.filter({ hasText: /VB đi \(2\)/ })).toHaveCount(1);
    await expect(tabBar.filter({ hasText: /Dự thảo \(1\)/ })).toHaveCount(1);

    // Click tab "VB đi" — chỉ data outgoing hiển thị (2 row)
    await tabBar.filter({ hasText: /VB đi \(2\)/ }).first().click();

    // AntD Table có class .ant-table — selector cụ thể vào table chính (không print-area)
    // Page có 2 table: hiển thị (.ant-table-tbody) + print (in .print-area). Lấy ant-table tbody.
    const visibleRows = page.locator('.ant-table-tbody tr');
    await expect(visibleRows.filter({ hasText: 'TEST: VB di' })).toHaveCount(2);
    await expect(visibleRows.filter({ hasText: 'TEST: VB den' })).toHaveCount(0);
  });
});
