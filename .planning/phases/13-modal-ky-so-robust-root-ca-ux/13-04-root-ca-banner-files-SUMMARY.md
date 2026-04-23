---
phase: 13-modal-ky-so-robust-root-ca-ux
plan: 04
subsystem: frontend
tags: [frontend, root-ca, banner, static-files, localStorage, antd6, viettel-mysign]

requires:
  - phase: 12-02
    provides: /ky-so/danh-sach 4-tab với handleDownload trong tab Đã ký gọi GET /ky-so/sign/:id/download
  - phase: 13-03
    provides: Sign flow đã polish, page header stable cho banner mount
provides:
  - "Static files /root-ca/viettel-ca-new.cer + /root-ca/huong-dan-cai-root-ca.pdf (Next.js tự serve từ public/)"
  - "RootCABanner.tsx component — Alert info dismissible với 2 download button + localStorage integration"
  - "Trigger banner trong handleDownload khi provider=MYSIGN_VIETTEL + chưa dismiss"
  - "localStorage key dismiss_root_ca_banner (permanent dismiss) + root_ca_banner_shown_once (informational)"
affects: [13-05]

tech-stack:
  added: []  # Dùng AntD Alert + Button + Space sẵn có, 3 icon sẵn có — không thêm dep
  patterns:
    - "Static asset distribution qua Next.js public/ folder — URL root tự serve, không cần middleware/API route"
    - "Dismiss UX banner qua localStorage per-browser (không persist DB) — chấp nhận user sang máy khác sẽ thấy lại"
    - "Defense-in-depth: parent set visible=true + component lại check localStorage lần nữa trước render"
    - "Ephemeral trigger state (showRootCABanner) reset per page load — user F5 có thể thấy lại nếu chưa dismiss vĩnh viễn"

key-files:
  created:
    - e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer
    - e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf
    - e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx
  modified:
    - e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx

key-decisions:
  - "Phase 13-04: File .cer + PDF commit vào git (không gitignore) — size chấp nhận (.cer ~1.5KB, PDF ~500KB); deploy server pull từ git không cần script copy riêng"
  - "Phase 13-04: DISMISS_KEY constant extract — tránh magic string scatter giữa component + parent, đồng thời làm rõ semantic key"
  - "Phase 13-04: Component props (visible, onDismiss) thay global state/context — parent quyết định trigger point, component chỉ handle render + dismiss side-effect"
  - "Phase 13-04: 2 button AntD type — 'Tải Root CA' type=primary (action chính) + 'Xem hướng dẫn' default (action phụ); màu accent #0891B2 giữ consistency với phase header"
  - "Phase 13-04: rel='noopener noreferrer' cho PDF link target=_blank — mitigate T-13-21 Referer leak, consistent Phase 12 pattern"

patterns-established:
  - "Banner dismissible pattern với localStorage: const KEY + defense-in-depth check + parent-controlled visible + onDismiss callback — reusable cho các info notification UX khác (VD: release notes, feature tour)"
  - "Static asset hosting qua public/ folder cho file non-secret (public certs, HDSD PDFs) — đơn giản hơn API endpoint, không auth overhead"

requirements-completed: [UX-11, DEP-02]

metrics:
  duration: 7 min
  tasks: 2
  files_created: 3
  files_modified: 1
  lines_added: ~119
  lines_removed: 0

completed: 2026-04-23
---

# Phase 13 Plan 04: Root CA Banner + Static Files Summary

**Copy Root CA Viettel files (cert + HDSD PDF) vào `frontend/public/root-ca/` commit vào git + tạo `RootCABanner.tsx` component Alert info dismissible với 2 download button + integrate trigger trong `/ky-so/danh-sach/page.tsx` khi user tải file ký MYSIGN_VIETTEL lần đầu chưa dismiss — localStorage-based permanent dismiss scope.**

## Performance

- **Duration:** ~7 phút
- **Tasks:** 2/2 (auto, no checkpoint)
- **Files created:** 3 (2 static assets + 1 component)
- **Files modified:** 1 (page.tsx trang danh sách ký số)
- **Lines:** +119 / -0 (net +119 — component ~94 dòng + integration page ~25 dòng)
- **Build status:** Next.js 16 compile PASS (52s)
- **TypeScript:** 0 new errors in touched files

## What Was Built

### Task 1 — Copy Root CA files (commit `111ca16`)

**Files created:**
- `e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer` (1526 bytes) — copy nguyên tên từ `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Code demo ky Mysign/DEMO_CLOUD_CA_JAVA/RootCA/viettel-ca-new.cer`
- `e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf` (512706 bytes) — copy + rename kebab-case từ `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/HUONG DAN CAI DAT CTS ROOT CA VIETTEL  Mysign.pdf`

**Verification:**
- `.cer` magic: binary certificate, size trong range 500-10000 bytes (expected .cer format)
- PDF magic bytes `%PDF` verified trên `head -c 4`
- `git check-ignore` confirm KHÔNG ignored (root .gitignore + frontend .gitignore không block `public/`)
- Next.js 16 convention: `public/root-ca/*` tự serve tại URL `/root-ca/*` — KHÔNG cần config thêm

### Task 2 — RootCABanner component + integration (commit `5474346`)

**File 1 — `e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx` (94 dòng, mới):**

```tsx
'use client';
import { Alert, Button, Space } from 'antd';
import { SafetyCertificateOutlined, DownloadOutlined, FilePdfOutlined } from '@ant-design/icons';

interface Props {
  visible: boolean;
  onDismiss: () => void;
}

const DISMISS_KEY = 'dismiss_root_ca_banner';

export default function RootCABanner({ visible, onDismiss }: Props) {
  if (!visible) return null;
  // Defense-in-depth localStorage check
  if (typeof window !== 'undefined' && localStorage.getItem(DISMISS_KEY) === 'true') {
    return null;
  }
  const handleClose = () => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(DISMISS_KEY, 'true');
    }
    onDismiss();
  };
  return (
    <Alert type="info" showIcon
      icon={<SafetyCertificateOutlined style={{ color: '#0891B2', fontSize: 20 }} />}
      message={<span style={{ fontWeight: 600, color: '#1B3A5C' }}>
        Cần cài Root CA Viettel để Adobe Reader hiển thị chữ ký hợp lệ
      </span>}
      description={
        <div>
          <p style={{ marginBottom: 12, color: '#475569', lineHeight: 1.5 }}>
            Nếu Adobe Reader báo chữ ký không xác thực khi mở file đã ký bằng MySign Viettel,
            hãy cài Root CA Viettel 1 lần duy nhất theo hướng dẫn bên dưới.
          </p>
          <Space wrap>
            <Button type="primary" icon={<DownloadOutlined />}
              href="/root-ca/viettel-ca-new.cer" download>Tải Root CA (.cer)</Button>
            <Button icon={<FilePdfOutlined />}
              href="/root-ca/huong-dan-cai-root-ca.pdf"
              target="_blank" rel="noopener noreferrer">Xem hướng dẫn (PDF)</Button>
          </Space>
        </div>
      }
      closable onClose={handleClose}
      style={{ marginBottom: 16, borderRadius: 8 }}
    />
  );
}
```

**File 2 — `e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx` (+25 dòng):**

- Import `RootCABanner` từ `@/components/notifications/RootCABanner`
- State mới `const [showRootCABanner, setShowRootCABanner] = useState(false)` — ephemeral per page load
- `handleDownload` useCallback: sau khi `window.open(url)` thành công + `provider_code === 'MYSIGN_VIETTEL'` + `localStorage.getItem('dismiss_root_ca_banner') !== 'true'` → `setShowRootCABanner(true)` + `localStorage.setItem('root_ca_banner_shown_once', 'true')`
- Render mount `<RootCABanner visible={showRootCABanner} onDismiss={() => setShowRootCABanner(false)} />` ngay dưới `.page-header` và trên `<Card className="page-card">`

**Trigger logic flow:**

1. User click "Tải file đã ký" trong tab Đã ký với row provider=MYSIGN_VIETTEL
2. API call `/ky-so/sign/:id/download` → response URL presigned MinIO
3. `window.open(url, '_blank')` → browser download file đã ký
4. Check: provider=MYSIGN_VIETTEL + chưa dismiss → banner render
5. User option A: Click "Tải Root CA (.cer)" → browser download `viettel-ca-new.cer`
6. User option B: Click "Xem hướng dẫn (PDF)" → mở tab mới với PDF viewer
7. User option C: Click X close → localStorage `dismiss_root_ca_banner=true` → banner unmount + không bao giờ hiện lại trong browser này

**3 lớp logic kiểm soát banner hiển thị:**

1. **Parent logic (page.tsx handleDownload):** Filter provider + dismiss status trước khi set visible — tiết kiệm render cycle
2. **Component visible prop:** Reset per page load — user F5 có thể thấy lại banner (trừ khi đã dismiss vĩnh viễn)
3. **Component defense-in-depth:** Ngay cả khi parent set visible=true, component vẫn check localStorage lần nữa → bảo vệ khỏi race condition SSR/hydration + lỗi logic parent

## Requirements Delivered

| REQ-ID | Description | Evidence |
|--------|-------------|----------|
| UX-11 | Banner hướng dẫn cài Root CA Viettel trong trang danh sách ký số | Alert type=info dismissible với icon SafetyCertificateOutlined + 2 button download + localStorage dismiss persistence |
| DEP-02 | File Root CA + HDSD PDF sẵn sàng tải từ URL tĩnh | `/root-ca/viettel-ca-new.cer` + `/root-ca/huong-dan-cai-root-ca.pdf` commit vào git, Next.js tự serve từ public/ |

## Deviations from Plan

### Rule 2 - Missing critical detail: Extract DISMISS_KEY constant

- **Found during:** Task 2 component write
- **Issue:** Plan spec có string literal `'dismiss_root_ca_banner'` 2 lần trong component (check + set) — magic string duplication dễ gây typo bug nếu refactor sau này
- **Fix:** Extract thành `const DISMISS_KEY = 'dismiss_root_ca_banner'` module-level
- **Impact:** Không thay đổi behavior — chỉ cải thiện maintainability. Parent page.tsx vẫn dùng literal string (không import constant) vì cross-file coupling không cần thiết cho 1 key đơn giản.
- **Files modified:** `e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx`
- **Commit:** `5474346`

### Không có deviation khác — plan executed exactly như designed.

## Authentication Gates

Không có — task pure FE + static file copy, không cần credential/auth setup.

## Known Stubs

Không có stub. Banner content hard-coded từ spec CONTEXT D-24 (không placeholder). Tất cả text đầy đủ tiếng Việt có dấu.

## Verification Results

### Automated checks — Task 1 static files

| Check | Expected | Actual |
|-------|----------|--------|
| `viettel-ca-new.cer` exists | true | ✓ |
| `huong-dan-cai-root-ca.pdf` exists | true | ✓ |
| `.cer` non-empty + size 500-10000 bytes | true | ✓ (1526 bytes) |
| PDF magic bytes `%PDF` | true | ✓ |
| Files not gitignored | true | ✓ (check-ignore empty output) |
| Git committed | true | ✓ (commit 111ca16) |

### Automated checks — Task 2 component + integration

| Check | Expected | Actual |
|-------|----------|--------|
| `components/notifications/RootCABanner.tsx` exists | true | ✓ |
| `export default function RootCABanner` | present | ✓ |
| `SafetyCertificateOutlined` import + usage | present | ✓ |
| `href="/root-ca/viettel-ca-new.cer"` | present | ✓ |
| `href="/root-ca/huong-dan-cai-root-ca.pdf"` | present | ✓ |
| `download` attr on .cer button | present | ✓ |
| `target="_blank"` + `rel="noopener noreferrer"` on PDF | present | ✓ |
| `localStorage.setItem(DISMISS_KEY, 'true')` on close | present | ✓ |
| `dismiss_root_ca_banner` string defined | present | ✓ (line 32 const) |
| `Cần cài Root CA Viettel` Vietnamese text | present | ✓ |
| `closable` prop on Alert | present | ✓ |
| `import RootCABanner from` in page.tsx | present | ✓ |
| `<RootCABanner` usage in page.tsx | present | ✓ |
| `setShowRootCABanner` usage | present | ✓ |
| `MYSIGN_VIETTEL` check | present | ✓ |
| `dismiss_root_ca_banner` check in page.tsx | present | ✓ |
| `root_ca_banner_shown_once` set in page.tsx | present | ✓ |
| TS errors in touched files | 0 | 0 |
| Frontend Next.js build | PASS | ✓ (52s compile) |

### Build verification

```
✓ Compiled successfully in 52s
✓ Generating static pages using 7 workers (52/52) in 9.1s
```

Frontend Next.js 16 production build PASS. 52 pages render OK. No regression in other pages.

### Manual smoke test TODO (Phase 13-05 UAT checkpoint scope)

- [ ] Navigate `/ky-so/danh-sach` → tab "Đã ký"
- [ ] Clear localStorage: `localStorage.clear()` trong DevTools
- [ ] Click "Tải file đã ký" trên row có provider=MYSIGN_VIETTEL → file đã ký download + banner hiện DƯỚI page header
- [ ] Click "Tải Root CA (.cer)" trên banner → browser download `viettel-ca-new.cer`
- [ ] Click "Xem hướng dẫn (PDF)" → mở tab mới với PDF viewer render HDSD
- [ ] Click X close trên banner → banner unmount
- [ ] Verify `localStorage.dismiss_root_ca_banner === 'true'` trong DevTools
- [ ] Click "Tải file đã ký" lần nữa → banner KHÔNG hiện (đã dismiss)
- [ ] Click "Tải file đã ký" trên row provider=SMARTCA_VNPT → banner KHÔNG hiện (wrong provider)
- [ ] Clear localStorage + F5 → trigger lại flow

## Threat Flags

Không có surface mới ngoài phạm vi threat_model của PLAN.md. Threat register cover:

- **T-13-17** (Info Disclosure Root CA public) — accept (file là public Viettel certificate)
- **T-13-18** (Tampering file .cer trong git) — mitigate (git audit + trusted remote; Phase 14 có thể add SHA256 checksum)
- **T-13-19** (Spoofing /root-ca/fake URL) — accept (relative URL same-origin only)
- **T-13-20** (DoS re-show banner) — mitigate (conditional render + namespaced keys không conflict)
- **T-13-21** (Info Disclosure Referer leak PDF) — mitigate (`rel="noopener noreferrer"` applied)

## Self-Check: PASSED

**Files:**
- FOUND: e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer (1526 bytes)
- FOUND: e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf (512706 bytes)
- FOUND: e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx
- FOUND: e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx (modified)

**Commits:**
- FOUND: 111ca16 (Task 1 — copy Root CA source files)
- FOUND: 5474346 (Task 2 — RootCABanner component + page integration)

**Grep verifications all passed.**
**TypeScript compile clean for touched files (0 new errors).**
**Frontend Next.js build PASS (52s).**
