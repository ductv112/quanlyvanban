/**
 * tests/wave-c-ky-so/tk-tai-khoan-ui.spec.ts
 *
 * Wave c — UI smoke for /ky-so/tai-khoan page (TC-KSTK module).
 * Asserts critical UI elements that API tests cannot verify:
 *   - TC-KSTK-001: alert text khi không có provider
 *   - TC-KSTK-002 / 003: form labels theo provider active
 *   - TC-KSTK-016: badge 'Đã xác thực' + 'Xác thực gần nhất'
 *
 * Pre-condition: backend port 4000, frontend port 3000, mock 8181/8182.
 * Backend DB pre-seeded by API run.sh (so SmartCA/MySign config + staff_signing_config in known states).
 *
 * Run: npx playwright test tests/wave-c-ky-so/tk-tai-khoan-ui.spec.ts --reporter=line --workers=1
 */
import { test, expect, request as pwRequest } from '@playwright/test';
import { storageStateFor } from '../fixtures/auth';
import { execSync } from 'child_process';

const TEST_TIMEOUT = 25000;

/** SQL helper — write SQL to temp file then exec inside container via psql -f */
import { writeFileSync, mkdtempSync } from 'fs';
import os from 'os';
import path from 'path';

function db(sql: string) {
  const dir = mkdtempSync(path.join(os.tmpdir(), 'kstk-'));
  const file = path.join(dir, 'q.sql');
  writeFileSync(file, sql, 'utf8');
  // Copy file into container then run
  execSync(`docker cp "${file}" qlvb_postgres:/tmp/q.sql`, { stdio: 'ignore' });
  execSync(
    `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -v ON_ERROR_STOP=1 -f /tmp/q.sql`,
    { stdio: 'ignore' },
  );
}

const SIGNING_KEY = 'qlvb-signing-dev-key-change-production-2026';

function setupSmartCAActive() {
  db(`
UPDATE public.signing_provider_config SET is_active=false;
UPDATE public.signing_provider_config
SET base_url='http://localhost:8181', client_id='mock_sp_id',
    client_secret=pgp_sym_encrypt('mock_secret_123', '${SIGNING_KEY}'),
    is_active=true
WHERE provider_code='SMARTCA_VNPT';
DELETE FROM public.staff_signing_config WHERE staff_id=9003;
`);
}

function setupMySignActive() {
  db(`
UPDATE public.signing_provider_config SET is_active=false;
UPDATE public.signing_provider_config
SET base_url='http://localhost:8182', client_id='ms_client',
    client_secret=pgp_sym_encrypt('ms_secret_xyz', '${SIGNING_KEY}'),
    profile_id='profile1', is_active=true
WHERE provider_code='MYSIGN_VIETTEL';
DELETE FROM public.staff_signing_config WHERE staff_id=9003;
`);
}

function setupNoProvider() {
  db(`
UPDATE public.signing_provider_config SET is_active=false;
DELETE FROM public.staff_signing_config WHERE staff_id=9003;
`);
}

function setupVerifiedConfig() {
  setupMySignActive();
  db(`
INSERT INTO public.staff_signing_config
  (staff_id, provider_code, user_id, credential_id, is_verified, last_verified_at, certificate_subject, certificate_serial)
VALUES (9003, 'MYSIGN_VIETTEL', 'CMT_TESTLD', 'cred_test_001', true, now() - interval '5 minute',
        'CN=Test Lanhdao,O=Test Org', 'CERT-12345')
ON CONFLICT (staff_id, provider_code) DO UPDATE
  SET user_id=EXCLUDED.user_id, credential_id=EXCLUDED.credential_id,
      is_verified=true, last_verified_at=EXCLUDED.last_verified_at,
      certificate_subject=EXCLUDED.certificate_subject,
      certificate_serial=EXCLUDED.certificate_serial;
`);
}

test.describe('Wave c — Tài khoản ký số cá nhân @wave-c-kstk', () => {
  test.use({ storageState: storageStateFor('lanhdao') });

  test('TC-KSTK-001 No provider activated → warning alert', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    setupNoProvider();
    await page.goto('/ky-so/tai-khoan');
    await expect(page.locator('.page-title')).toContainText('Tài khoản ký số cá nhân');
    await expect(page.getByText('Hệ thống chưa kích hoạt provider ký số')).toBeVisible();
    await expect(page.getByRole('button', { name: /Làm mới/i })).toBeVisible();
  });

  test('TC-KSTK-002 SmartCA active → label "Mã định danh SmartCA", no cert dropdown', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    setupSmartCAActive();
    await page.goto('/ky-so/tai-khoan');
    // Provider banner
    await expect(page.getByText(/Provider đang hoạt động/i)).toBeVisible();
    await expect(page.getByText('SmartCA VNPT')).toBeVisible();
    // SmartCA-specific label
    await expect(page.getByText('Mã định danh SmartCA')).toBeVisible();
    // No cert dropdown for SmartCA
    await expect(page.getByText('Tải danh sách chứng thư từ MySign')).toHaveCount(0);
  });

  test('TC-KSTK-003 MySign active → label "Mã định danh MySign" + cert dropdown', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    setupMySignActive();
    await page.goto('/ky-so/tai-khoan');
    await expect(page.getByText('MySign Viettel')).toBeVisible();
    await expect(page.getByText('Mã định danh MySign')).toBeVisible();
    await expect(page.getByRole('button', { name: /Tải danh sách chứng thư từ MySign/i })).toBeVisible();
    await expect(page.getByText('Chứng thư số')).toBeVisible();
  });

  test('TC-KSTK-016 Verified config → badge "Đã xác thực" + "Xác thực gần nhất"', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    setupVerifiedConfig();
    await page.goto('/ky-so/tai-khoan');
    // Badge — Tag with success color
    await expect(page.getByText('Đã xác thực')).toBeVisible();
    // Card extra — last verified time
    await expect(page.getByText(/Xác thực gần nhất/i)).toBeVisible();
    // Cert info Descriptions
    await expect(page.getByText('CN=Test Lanhdao,O=Test Org')).toBeVisible();
    await expect(page.getByText('CERT-12345')).toBeVisible();
  });

  test('TC-KSTK-017 Refresh button reloads provider info', async ({ page }) => {
    test.setTimeout(TEST_TIMEOUT);
    setupSmartCAActive();
    await page.goto('/ky-so/tai-khoan');
    await expect(page.getByText('SmartCA VNPT')).toBeVisible();
    // Click "Làm mới" button in alert area
    const refresh = page.getByRole('button', { name: /Làm mới/i }).first();
    await refresh.click();
    // Provider should still be SmartCA VNPT after refresh
    await expect(page.getByText('SmartCA VNPT')).toBeVisible();
  });
});
