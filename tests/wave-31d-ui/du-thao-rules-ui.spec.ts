/**
 * tests/wave-31d-ui/du-thao-rules-ui.spec.ts — Wave b VB du thao UI rules / dialog warning
 *
 * Coverage SKIP UI Wave b Du thao:
 *   - TC-VBT-030 — Dialog warning text khi bam Phat hanh trong row dropdown
 *   - TC-VBT-016 — SKIP duplicate (covered by TC-015)
 *   - TC-VBT-036 — SKIP HSM token
 *
 * Run: npx playwright test tests/wave-31d-ui/du-thao-rules-ui.spec.ts --workers=1
 */
import { test, expect } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 25000;

test.describe('Wave 31d Du thao rules UI — lanhdao @wave-31d-ui', () => {
  test.use({ storageState: storageStateFor('lanhdao') });

  test('TC-VBT-030 Dialog warning text khi bam Phat hanh trong list — content "Sau khi phát hành sẽ không thể sửa hoặc xóa"', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Mock list voi 1 row approved (canRelease = true)
    await page.route('**/api/van-ban-du-thao**', async (route) => {
      const url = route.request().url();
      if (route.request().method() === 'GET' && !url.match(/\/van-ban-du-thao\/\d+/) && !url.includes('xuat-excel') && !url.includes('danh-dau')) {
        await route.fulfill({
          status: 200,
          headers: { 'content-type': 'application/json' },
          body: JSON.stringify({
            success: true,
            data: [
              {
                id: 90001, abstract: 'TEST: VB approved chua phat hanh',
                drafting_user_id: 9003, unit_id: 2, doc_book_id: 5,
                doc_book_name: 'So 1', doc_type_id: 1, doc_type_name: 'Cong van',
                approved: true, rejected_by: null, is_released: false,
                urgent_id: 1, secret_id: 1, created_at: '2026-05-01T10:00:00Z',
                permissions: { canEdit: false, canApprove: false, canRelease: true, canSend: false },
              },
            ],
            pagination: { total: 1, page: 1, pageSize: 20 },
          }),
        });
        return;
      }
      await route.continue();
    });

    // Stub bookmark check
    await page.route('**/api/van-ban-du-thao/danh-dau-ca-nhan**', async (r) =>
      r.fulfill({ status: 200, body: JSON.stringify({ success: true, data: [] }) })
    );

    await page.goto('/van-ban-du-thao');
    await expect(page).toHaveURL(/van-ban-du-thao/);

    // Wait row render
    await expect(page.locator('text=/TEST: VB approved chua phat hanh/').first()).toBeVisible({ timeout: 10000 });

    // Click 3-dot menu
    const dataRow = page.locator('tbody tr').filter({ hasText: 'TEST: VB approved chua phat hanh' }).first();
    const moreBtn = dataRow.locator('.anticon-more').first();
    await expect(moreBtn).toBeVisible({ timeout: 5000 });
    await moreBtn.click();

    // Click "Phat hanh"
    const releaseItem = page.getByRole('menuitem', { name: /Phát hành/i });
    await expect(releaseItem).toBeVisible({ timeout: 3000 });
    await releaseItem.click();

    // Modal.confirm voi text "Sau khi phát hành sẽ không thể sửa hoặc xóa"
    const confirmModal = page.locator('.ant-modal-confirm').first();
    await expect(confirmModal).toBeVisible({ timeout: 5000 });
    await expect(confirmModal).toContainText(/sẽ không thể sửa hoặc xóa/i, { timeout: 3000 });

    // OK text "Phát hành" + Cancel "Hủy"
    const okBtn = confirmModal.getByRole('button', { name: /^Phát hành$/i });
    const cancelBtn = confirmModal.getByRole('button', { name: /^Hủy$/i });
    await expect(okBtn).toBeVisible();
    await expect(cancelBtn).toBeVisible();
  });

  test.skip('TC-VBT-016 Sua VB da phat hanh (duplicate of TC-015 backend SP guard)', async () => {
    // Skip: redundant per Wave b results
  });

  test.skip('TC-VBT-036 HSM token / real cert sign — SKIP no real cert in test env', async () => {});
});
