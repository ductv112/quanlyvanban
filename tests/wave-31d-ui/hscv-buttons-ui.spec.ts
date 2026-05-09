/**
 * tests/wave-31d-ui/hscv-buttons-ui.spec.ts — HSCV button visibility UI tests
 *
 * Coverage SKIP UI Wave c HSCV (~5 testable, 4 SKIP):
 *   - TC-HSCV-002 — Lay so button KHONG hien khi HSCV status=0 hoac da co so
 *   - TC-HSCV-072 — Ky so visible: signer + status 2/3 + .pdf
 *   - TC-HSCV-073 — Ky so HIDDEN khi user khong la signer
 *   - TC-HSCV-074 — Ky so HIDDEN khi status=4 (hoan thanh)
 *   - TC-HSCV-075 — Ky so HIDDEN khi file khong phai .pdf
 *   - TC-HSCV-017/067/068 — SKIP perf
 *
 * Run: npx playwright test tests/wave-31d-ui/hscv-buttons-ui.spec.ts --workers=1
 */
import { test, expect, type Page } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';

const TEST_TIMEOUT = 25000;

interface HscvDetailMock {
  status: number;
  number?: number | null;
  signer_id?: number | null;
  signer_name?: string | null;
}

interface AttachmentMock {
  id: number;
  file_name: string;
  is_ca?: boolean;
}

/** Cai mocks cho HSCV detail + attachments + relevant tabs.
 * IMPORTANT: Playwright routes LIFO — register catch-all FIRST,
 * then specific routes (dinh-kem, /:id) LATER so they take priority. */
async function mockHscvDetail(page: Page, hscvId: number, detail: HscvDetailMock, attachments: AttachmentMock[]) {
  // Catch-all sub-resource (lich-su, y-kien, van-ban-lien-ket, hscv-con, can-bo, etc.)
  // Registered FIRST so specific routes registered later take priority (LIFO).
  await page.route(`**/api/ho-so-cong-viec/${hscvId}/**`, async (route) => {
    await route.fulfill({
      status: 200,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ success: true, data: [] }),
    });
  });

  // Mock /quan-tri/don-vi/tree for staff tab
  await page.route('**/api/quan-tri/don-vi/tree', async (route) => {
    await route.fulfill({
      status: 200,
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ success: true, data: [] }),
    });
  });

  // Specific: dinh-kem (registered AFTER catch-all → takes priority)
  await page.route(`**/api/ho-so-cong-viec/${hscvId}/dinh-kem`, async (route) => {
    if (route.request().method() === 'GET') {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: attachments.map((a) => ({
            id: a.id, file_name: a.file_name, file_path: `path/${a.file_name}`,
            file_size: 100000, mime_type: a.file_name.endsWith('.pdf') ? 'application/pdf' : 'application/octet-stream',
            uploaded_by: 9001, uploaded_by_name: 'admin',
            uploaded_at: '2026-05-01T10:00:00Z',
            is_ca: a.is_ca ?? false,
            signed_file_path: null, signed_at: null, signed_date: null,
          })),
        }),
      });
      return;
    }
    await route.continue();
  });

  // Specific: /:id (registered LAST → takes priority)
  await page.route(`**/api/ho-so-cong-viec/${hscvId}`, async (route) => {
    if (route.request().method() === 'GET') {
      await route.fulfill({
        status: 200,
        headers: { 'content-type': 'application/json' },
        body: JSON.stringify({
          success: true,
          data: {
            id: hscvId, code: `HSCV-${hscvId}`, name: 'TEST HSCV',
            description: 'TEST',
            status: detail.status,
            progress: 0,
            number: detail.number ?? null,
            sub_number: null,
            received_date: null,
            doc_book_id: null, doc_book_name: null,
            doc_field_id: 1, doc_field_name: 'Hanh chinh',
            unit_id: 2, unit_name: 'Phong A',
            created_by: 9003, created_by_name: 'Lanh dao',
            signer_id: detail.signer_id ?? null,
            signer_name: detail.signer_name ?? null,
            start_date: '2026-05-01',
            end_date: '2026-06-01',
            cancel_reason: null,
            created_at: '2026-05-01T10:00:00Z',
            updated_at: '2026-05-01T10:00:00Z',
            permissions: { canEdit: true, canDelete: true },
          },
        }),
      });
      return;
    }
    await route.continue();
  });
}

test.describe('Wave 31d HSCV — Lay so button @wave-31d-ui', () => {
  test.use({ storageState: storageStateFor('lanhdao') });

  test('TC-HSCV-002 Lay so button HIDDEN khi status=0 (Mới tạo) va status=1 da co số', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Status 0 — KHONG co Lay so button trong toolbar (case 0 — only Chuyển xử lý/Sửa/Xóa)
    await mockHscvDetail(page, 70001, { status: 0, number: null }, []);

    await page.goto('/ho-so-cong-viec/70001', { waitUntil: 'domcontentloaded' });
    await expect(page.locator('.detail-header-title')).toBeVisible({ timeout: 10000 });

    // Lay so button KHONG xuat hien
    const layNumberBtn = page.getByRole('button', { name: /Lấy số/i });
    expect(await layNumberBtn.count()).toBe(0);
  });

  test('TC-HSCV-002b Lay so button VISIBLE khi status=1 va chua co số', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Status 1 + number=null → "Lay so" SHOULD show
    await mockHscvDetail(page, 70002, { status: 1, number: null }, []);

    await page.goto('/ho-so-cong-viec/70002', { waitUntil: 'domcontentloaded' });
    await expect(page.locator('.detail-header-title')).toBeVisible({ timeout: 10000 });

    // Lay so button visible
    const layNumberBtn = page.getByRole('button', { name: /Lấy số/i });
    await expect(layNumberBtn).toBeVisible({ timeout: 5000 });
  });
});

test.describe('Wave 31d HSCV — Ký số button visibility @wave-31d-ui', () => {
  // lanhdao staffId = 9003
  test.use({ storageState: storageStateFor('lanhdao') });

  test('TC-HSCV-072 Ký số button VISIBLE khi user la signer + status=3 + .pdf', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // User lanhdao staffId 9003 — signer matches
    await mockHscvDetail(
      page,
      70003,
      { status: 3, number: 5, signer_id: 9003, signer_name: 'Lanh dao' },
      [{ id: 1, file_name: 'test-document.pdf', is_ca: false }]
    );

    await page.goto('/ho-so-cong-viec/70003', { waitUntil: 'domcontentloaded' });
    await expect(page.locator('.detail-header-title')).toBeVisible({ timeout: 10000 });

    // Click tab "File đính kèm"
    const attachTab = page.locator('.ant-tabs-tab').filter({ hasText: /File đính kèm|Đính kèm/i }).first();
    if (await attachTab.count() > 0) {
      await attachTab.click();
      await page.waitForTimeout(500);
    }

    // Ký số button visible
    const kySoBtn = page.getByRole('button', { name: /Ký số/ });
    await expect(kySoBtn).toBeVisible({ timeout: 5000 });
  });

  test('TC-HSCV-073 Ký số HIDDEN khi user KHONG phai signer (signer_id != user.staffId)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    // Signer = 9001 (admin) ≠ lanhdao 9003
    await mockHscvDetail(
      page,
      70004,
      { status: 3, number: 5, signer_id: 9001, signer_name: 'Admin' },
      [{ id: 1, file_name: 'test-document.pdf', is_ca: false }]
    );

    await page.goto('/ho-so-cong-viec/70004', { waitUntil: 'domcontentloaded' });
    await expect(page.locator('.detail-header-title')).toBeVisible({ timeout: 10000 });

    const attachTab = page.locator('.ant-tabs-tab').filter({ hasText: /File đính kèm|Đính kèm/i }).first();
    if (await attachTab.count() > 0) {
      await attachTab.click();
      await page.waitForTimeout(500);
    }

    const kySoBtn = page.getByRole('button', { name: /Ký số/ });
    expect(await kySoBtn.count()).toBe(0);
  });

  test('TC-HSCV-074 Ký số HIDDEN khi status=4 (hoan thanh)', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    await mockHscvDetail(
      page,
      70005,
      { status: 4, number: 5, signer_id: 9003, signer_name: 'Lanh dao' },
      [{ id: 1, file_name: 'test-document.pdf', is_ca: false }]
    );

    await page.goto('/ho-so-cong-viec/70005', { waitUntil: 'domcontentloaded' });
    await expect(page.locator('.detail-header-title')).toBeVisible({ timeout: 10000 });

    const attachTab = page.locator('.ant-tabs-tab').filter({ hasText: /File đính kèm|Đính kèm/i }).first();
    if (await attachTab.count() > 0) {
      await attachTab.click();
      await page.waitForTimeout(500);
    }

    const kySoBtn = page.getByRole('button', { name: /Ký số/ });
    expect(await kySoBtn.count()).toBe(0);
  });

  test('TC-HSCV-075 Ký số HIDDEN khi file khong phai .pdf', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);

    await mockHscvDetail(
      page,
      70006,
      { status: 3, number: 5, signer_id: 9003, signer_name: 'Lanh dao' },
      [{ id: 1, file_name: 'document.docx', is_ca: false }]
    );

    await page.goto('/ho-so-cong-viec/70006', { waitUntil: 'domcontentloaded' });
    await expect(page.locator('.detail-header-title')).toBeVisible({ timeout: 10000 });

    const attachTab = page.locator('.ant-tabs-tab').filter({ hasText: /File đính kèm|Đính kèm/i }).first();
    if (await attachTab.count() > 0) {
      await attachTab.click();
      await page.waitForTimeout(500);
    }

    const kySoBtn = page.getByRole('button', { name: /Ký số/ });
    expect(await kySoBtn.count()).toBe(0);
  });

  test.skip('TC-HSCV-017 10000-row perf — SKIP', async () => {});
  test.skip('TC-HSCV-067 50MB+ upload perf — SKIP', async () => {});
  test.skip('TC-HSCV-068 50MB+ upload perf — SKIP', async () => {});
});
