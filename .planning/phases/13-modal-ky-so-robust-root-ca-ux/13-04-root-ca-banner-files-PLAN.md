---
phase: 13
plan: 04
type: execute
wave: 2
depends_on: [13-03]
files_modified:
  - e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer
  - e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf
  - e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx
  - e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx
autonomous: true
requirements:
  - UX-11
  - DEP-02
tags: [frontend, root-ca, banner, static-files, localStorage, antd6]
must_haves:
  truths:
    - "File viettel-ca-new.cer + huong-dan-cai-root-ca.pdf tồn tại trong frontend/public/root-ca/ (commit vào git)"
    - "URL /root-ca/viettel-ca-new.cer trả về file .cer 200 OK (Next.js tự serve)"
    - "URL /root-ca/huong-dan-cai-root-ca.pdf trả về PDF 200 OK"
    - "Khi user click 'Tải file đã ký' trong tab Đã ký AND provider=MYSIGN_VIETTEL AND localStorage dismiss_root_ca_banner !== 'true' → banner Alert info hiển thị dưới page header"
    - "Banner có 2 button: 'Tải Root CA (.cer)' link /root-ca/viettel-ca-new.cer download + 'Xem hướng dẫn (PDF)' link /root-ca/huong-dan-cai-root-ca.pdf target=_blank"
    - "Click close X trên banner → localStorage.setItem('dismiss_root_ca_banner', 'true') → banner unmount và KHÔNG hiện lại trừ khi clear localStorage"
    - "Sau khi banner mount lần đầu, set localStorage 'root_ca_banner_shown_once' = 'true' — lần tải sau không tự động hiện nữa"
  artifacts:
    - path: "e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer"
      provides: "Root CA certificate Viettel, tải từ docs/.../DEMO_CLOUD_CA_JAVA/RootCA/viettel-ca-new.cer"
      contains: "binary .cer"
    - path: "e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf"
      provides: "HDSD cài Root CA Viettel, copy từ docs/.../HUONG DAN CAI DAT CTS ROOT CA VIETTEL  Mysign.pdf (rename kebab-case)"
      contains: "binary PDF"
    - path: "e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx"
      provides: "Component Alert info dismissible với 2 download button + localStorage integration"
      exports: ["default"]
    - path: "e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx"
      provides: "Mount <RootCABanner /> dưới page header + trigger banner visible state khi handleDownload MYSIGN lần đầu"
      contains: "RootCABanner"
  key_links:
    - from: "RootCABanner.tsx"
      to: "localStorage dismiss_root_ca_banner"
      via: "getItem/setItem"
      pattern: "localStorage.(get|set)Item.*dismiss_root_ca_banner"
    - from: "page.tsx (danh-sach)"
      to: "RootCABanner"
      via: "import + conditional mount"
      pattern: "<RootCABanner"
    - from: "page.tsx handleDownload"
      to: "setShowRootCABanner"
      via: "trigger khi provider_code=MYSIGN_VIETTEL"
      pattern: "provider_code.*MYSIGN_VIETTEL"
---

<objective>
Phase 13 AC#4 + AC#5:

1. **Copy Root CA files (D-27, D-28, D-29):** Copy 2 file nguồn vào `frontend/public/root-ca/`:
   - `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Code demo ky Mysign/DEMO_CLOUD_CA_JAVA/RootCA/viettel-ca-new.cer` → `frontend/public/root-ca/viettel-ca-new.cer` (giữ tên)
   - `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/HUONG DAN CAI DAT CTS ROOT CA VIETTEL  Mysign.pdf` → `frontend/public/root-ca/huong-dan-cai-root-ca.pdf` (rename kebab-case)

2. **Tạo `RootCABanner.tsx` component (D-22 → D-26):**
   - AntD `<Alert type="info" closable>` với icon SafetyCertificateOutlined
   - Title: "Cần cài Root CA Viettel để Adobe Reader hiển thị chữ ký hợp lệ"
   - Description: giải thích ngắn + 2 button download + link HDSD
   - onClose: `localStorage.setItem('dismiss_root_ca_banner', 'true')`
   - Component accept prop `visible: boolean` (parent quyết định khi nào mount)

3. **Integration với `/ky-so/danh-sach/page.tsx` (D-22, D-23):**
   - `handleDownload` phát hiện `provider_code === 'MYSIGN_VIETTEL'` → nếu `localStorage.dismiss_root_ca_banner !== 'true'`:
     - Set `showRootCABanner = true` (state mới)
     - Set `localStorage.root_ca_banner_shown_once = 'true'` (chỉ mark lần đầu — không liên quan dismiss)
   - Nếu `dismiss_root_ca_banner === 'true'` → bỏ qua, không hiện lại (user đã dismiss)
   - Render `<RootCABanner visible={showRootCABanner} onDismiss={() => setShowRootCABanner(false)} />` dưới page header

**D-22 trigger detail:**
- Banner xuất hiện **ngay sau** user click "Tải file đã ký" lần đầu tiên **AND** provider = `MYSIGN_VIETTEL` **AND** chưa dismiss.
- KHÔNG tự mount on page load.
- Component tự handle `localStorage.setItem('dismiss_root_ca_banner', 'true')` khi click close — parent chỉ set `visible=true` trigger, unmount khi banner dismiss.

**D-26 one-time logic:** localStorage `root_ca_banner_shown_once` là informational (analytics/debug). Logic ưu tiên: `dismiss_root_ca_banner === 'true'` → không bao giờ hiện nữa. Nếu chưa dismiss, lần download MYSIGN kế tiếp VẪN hiện nếu state `showRootCABanner` chưa set từ click trước (tức user đã navigate away). Thực tế logic đơn giản: `showRootCABanner` state ephemeral — user download lần 2 sau F5 sẽ thấy lại banner (trừ khi đã dismiss). CONTEXT D-26 nói "chỉ hiện khi user click download lần đầu" — interpret là "mỗi session, trigger khi download MYSIGN" vì state `showRootCABanner` reset per page load. Acceptable để user biết banner tồn tại, và họ có thể dismiss vĩnh viễn bằng X.

**KHÔNG thuộc scope:**
- Production MinIO config cho signed file (defer Phase 14)
- Banner cho provider khác (chỉ MYSIGN_VIETTEL — D-22)
- Persist banner state trong DB (chỉ localStorage per-browser — D-25)

Output: 2 binary file copy + 1 component mới + 1 modify page.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md
@CLAUDE.md
@e_office_app_new/frontend/CLAUDE.md
@e_office_app_new/frontend/AGENTS.md

<interfaces>
**File paths (verified existence):**

Source files trong repo:
- `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Code demo ky Mysign/DEMO_CLOUD_CA_JAVA/RootCA/viettel-ca-new.cer` — exists (trong ls)
- `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/HUONG DAN CAI DAT CTS ROOT CA VIETTEL  Mysign.pdf` — exists (tên có 2 space giữa "VIETTEL" và "Mysign")

Target:
- `e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer`
- `e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf`

Folder `frontend/public/root-ca/` CHƯA tồn tại → cần `mkdir -p`.

**Next.js 16 static serve convention:** Tất cả `public/*` tự mount tại URL root. `public/root-ca/viettel-ca-new.cer` → accessible tại `http://localhost:3000/root-ca/viettel-ca-new.cer`. Không cần config thêm.

**Gitignore check:** Xem `e_office_app_new/frontend/.gitignore` nếu có exclude `public/` — grep `public/root-ca` trong .gitignore. Theo D-29 yêu cầu commit vào git (size .cer ~2KB, PDF ~500KB-2MB chấp nhận được).

**RootCABanner component (pseudo):**
```tsx
'use client';
import { Alert, Button, Space } from 'antd';
import { SafetyCertificateOutlined, DownloadOutlined, FilePdfOutlined } from '@ant-design/icons';

interface Props {
  visible: boolean;
  onDismiss: () => void;
}

export default function RootCABanner({ visible, onDismiss }: Props) {
  if (!visible) return null;
  if (typeof window !== 'undefined' && localStorage.getItem('dismiss_root_ca_banner') === 'true') {
    return null;  // Defense-in-depth — parent đã filter nhưng component tự check lần nữa
  }

  const handleClose = () => {
    if (typeof window !== 'undefined') {
      localStorage.setItem('dismiss_root_ca_banner', 'true');
    }
    onDismiss();
  };

  return (
    <Alert
      type="info"
      showIcon
      icon={<SafetyCertificateOutlined />}
      message="Cần cài Root CA Viettel để Adobe Reader hiển thị chữ ký hợp lệ"
      description={
        <div>
          <p style={{ marginBottom: 12 }}>
            Nếu Adobe Reader báo chữ ký không xác thực, hãy cài Root CA Viettel 1 lần duy nhất theo hướng dẫn.
          </p>
          <Space>
            <Button
              type="primary"
              icon={<DownloadOutlined />}
              href="/root-ca/viettel-ca-new.cer"
              download
            >
              Tải Root CA (.cer)
            </Button>
            <Button
              icon={<FilePdfOutlined />}
              href="/root-ca/huong-dan-cai-root-ca.pdf"
              target="_blank"
              rel="noopener noreferrer"
            >
              Xem hướng dẫn (PDF)
            </Button>
          </Space>
        </div>
      }
      closable
      onClose={handleClose}
      style={{ marginBottom: 16 }}
    />
  );
}
```

**Integration handleDownload trong page.tsx:**

Hiện tại handleDownload (line ~400+):
```typescript
const handleDownload = useCallback(async (row: TxnRow) => {
  try {
    const { data: res } = await api.get(`/ky-so/sign/${row.transaction_id}/download`);
    if (res?.success && res?.data?.url) {
      window.open(res.data.url, '_blank', 'noopener,noreferrer');
    }
  } catch (err: unknown) { ... }
}, [message]);
```

Đổi thành:
```typescript
const handleDownload = useCallback(async (row: TxnRow) => {
  try {
    const { data: res } = await api.get(`/ky-so/sign/${row.transaction_id}/download`);
    if (res?.success && res?.data?.url) {
      window.open(res.data.url, '_blank', 'noopener,noreferrer');

      // Phase 13: Trigger Root CA banner nếu MYSIGN_VIETTEL + chưa dismiss (D-22)
      if (row.provider_code === 'MYSIGN_VIETTEL' && typeof window !== 'undefined') {
        const dismissed = localStorage.getItem('dismiss_root_ca_banner') === 'true';
        if (!dismissed) {
          setShowRootCABanner(true);
          localStorage.setItem('root_ca_banner_shown_once', 'true');  // D-26 informational
        }
      }
    }
  } catch (err: unknown) { ... }
}, [message]);
```

Thêm state trên:
```typescript
const [showRootCABanner, setShowRootCABanner] = useState(false);
```

Render block (thay page header hiện tại line 780-787):
```tsx
return (
  <>
    <div className="page-header">
      <Title level={3} className="page-title">
        <SafetyCertificateOutlined style={{ color: '#0891B2' }} /> Danh sách ký số
      </Title>
    </div>

    {/* Phase 13 — Root CA banner (chỉ MYSIGN_VIETTEL, trigger bởi handleDownload) */}
    <RootCABanner
      visible={showRootCABanner}
      onDismiss={() => setShowRootCABanner(false)}
    />

    <Card className="page-card">
      ...
    </Card>
    {renderSignModal()}
  </>
);
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Copy 2 Root CA source files vào frontend/public/root-ca/ + commit vào git</name>
  <files>
    e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer,
    e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf
  </files>
  <read_first>
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md` D-27 D-28 D-29 D-30 (file paths + rename rules + git commit)
    - Check `ls docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Code\ demo\ ky\ Mysign/DEMO_CLOUD_CA_JAVA/RootCA/` (source .cer exists)
    - Check `ls docs/huong_dan_tich_hop_ky_so_MySign_Viettel/` (source PDF exists — tên có 2 space giữa VIETTEL và Mysign)
    - Check `e_office_app_new/frontend/.gitignore` grep `public` — đảm bảo không exclude /public/root-ca/ (Next.js public folder phải commit)
  </read_first>
  <action>
**Bước 1: Tạo folder đích:**
```bash
mkdir -p e_office_app_new/frontend/public/root-ca
```

**Bước 2: Copy .cer file (giữ tên):**
```bash
cp "docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Code demo ky Mysign/DEMO_CLOUD_CA_JAVA/RootCA/viettel-ca-new.cer" \
   "e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer"
```

**Bước 3: Copy PDF + rename kebab-case (D-28):**

Source PDF có tên phức tạp với space và chữ in hoa: `HUONG DAN CAI DAT CTS ROOT CA VIETTEL  Mysign.pdf` (CHÚ Ý: có 2 space giữa "VIETTEL" và "Mysign").

Target rename: `huong-dan-cai-root-ca.pdf` (kebab-case, không dấu, không space).

```bash
cp "docs/huong_dan_tich_hop_ky_so_MySign_Viettel/HUONG DAN CAI DAT CTS ROOT CA VIETTEL  Mysign.pdf" \
   "e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf"
```

Verify copy thành công + kích thước hợp lý:
```bash
ls -la e_office_app_new/frontend/public/root-ca/
# Expected:
#   viettel-ca-new.cer (~1-3 KB)
#   huong-dan-cai-root-ca.pdf (~500 KB - 5 MB)
```

**Bước 4: Verify git KHÔNG ignore folder public/root-ca/:**
```bash
cd e_office_app_new/frontend && cat .gitignore 2>/dev/null | grep -E "^public|^/public|root-ca" | head -5
# Nếu có 'public' trong gitignore → sửa để exclude `.next/` nhưng GIỮ `public/` (Next.js convention)
# Nếu .gitignore không có 'public' → OK
```

Next.js 16 convention: `public/` là commit folder, `.next/` mới là build output ignore. Không expect conflict.

**Bước 5: Smoke test Next.js serve (optional — executor dev env):**

Start frontend (nếu chưa chạy):
```bash
cd e_office_app_new/frontend && npm run dev
```

Sau khi server ready (port 3000):
```bash
curl -I http://localhost:3000/root-ca/viettel-ca-new.cer
# Expected: HTTP/1.1 200 OK + Content-Type: application/octet-stream hoặc application/pkix-cert

curl -I http://localhost:3000/root-ca/huong-dan-cai-root-ca.pdf
# Expected: HTTP/1.1 200 OK + Content-Type: application/pdf
```

**Bước 6: Git add (không commit — user quyết định):**
```bash
git add e_office_app_new/frontend/public/root-ca/
git status --porcelain e_office_app_new/frontend/public/root-ca/
# Expected 2 dòng: A  ...viettel-ca-new.cer, A  ...huong-dan-cai-root-ca.pdf
```

KHÔNG commit — CLAUDE.md rule "KHÔNG tự động commit. Chỉ commit khi user yêu cầu rõ ràng."
  </action>
  <verify>
<automated>
test -f e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer && \
test -f e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf && \
# Verify non-empty
test -s e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer && \
test -s e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf && \
# Verify PDF magic bytes (%PDF)
head -c 4 e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf | grep -q "%PDF" && \
# Verify .cer file size reasonable (1-10KB typically)
[ "$(wc -c < e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer)" -gt 500 ] && \
[ "$(wc -c < e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer)" -lt 10000 ] && \
echo "Task 1 OK"
</automated>
  </verify>
  <done>
    - 2 file tồn tại trong `public/root-ca/`: `viettel-ca-new.cer` (~1-3KB) + `huong-dan-cai-root-ca.pdf` (~500KB-5MB)
    - Tên file kebab-case, không dấu, không space (PDF renamed)
    - Files non-empty, PDF có magic bytes "%PDF"
    - Next.js dev server serve 200 OK cả 2 URL (nếu server running)
    - Files added to git staging (pending user commit instruction)
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Tạo RootCABanner.tsx component + integrate vào /ky-so/danh-sach page</name>
  <files>
    e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx,
    e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx
  </files>
  <read_first>
    - `e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx` (full file — đặc biệt line 32-62 imports, 400+ handleDownload, 780-805 render)
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md` D-22 → D-26 (banner specs + trigger conditions + localStorage logic)
    - AntD 6 Alert component specs (icon custom qua `icon` prop, `closable={true}`, `onClose` handler)
  </read_first>
  <action>
**Part A: Tạo `e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx`:**

```tsx
'use client';

/**
 * RootCABanner — Banner hướng dẫn cài Root CA Viettel (Phase 13 UX-11 + DEP-02).
 *
 * Trigger (D-22): Hiện khi user tải file ký bằng MYSIGN_VIETTEL lần đầu tiên AND
 * localStorage.dismiss_root_ca_banner !== 'true'. Parent decide visible=true qua
 * handleDownload. Component tự check localStorage defense-in-depth + handle dismiss.
 *
 * Position (D-23): Mount dưới page header, trước main content card — full width.
 *
 * Dismiss (D-25): Click X → localStorage.dismiss_root_ca_banner = 'true' →
 * không bao giờ hiện lại trong browser này (user sang browser/máy khác sẽ thấy lại).
 *
 * Static URLs (D-30): /root-ca/*.cer và /root-ca/*.pdf — Next.js tự serve từ public/.
 */

import { Alert, Button, Space } from 'antd';
import {
  SafetyCertificateOutlined,
  DownloadOutlined,
  FilePdfOutlined,
} from '@ant-design/icons';

interface Props {
  /** Parent-controlled visibility — reset sau khi user dismiss */
  visible: boolean;
  /** Callback khi user click X close — parent remove trigger state */
  onDismiss: () => void;
}

const DISMISS_KEY = 'dismiss_root_ca_banner';

export default function RootCABanner({ visible, onDismiss }: Props) {
  if (!visible) return null;

  // Defense-in-depth: ngay cả khi parent set visible=true, check localStorage
  // một lần nữa trước render (tránh race condition trong SSR/hydration)
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
    <Alert
      type="info"
      showIcon
      icon={<SafetyCertificateOutlined style={{ color: '#0891B2', fontSize: 20 }} />}
      message={
        <span style={{ fontWeight: 600, color: '#1B3A5C' }}>
          Cần cài Root CA Viettel để Adobe Reader hiển thị chữ ký hợp lệ
        </span>
      }
      description={
        <div>
          <p style={{ marginBottom: 12, color: '#475569' }}>
            Nếu Adobe Reader báo chữ ký không xác thực khi mở file đã ký bằng MySign Viettel,
            hãy cài Root CA Viettel 1 lần duy nhất theo hướng dẫn bên dưới.
          </p>
          <Space wrap>
            <Button
              type="primary"
              icon={<DownloadOutlined />}
              href="/root-ca/viettel-ca-new.cer"
              download
            >
              Tải Root CA (.cer)
            </Button>
            <Button
              icon={<FilePdfOutlined />}
              href="/root-ca/huong-dan-cai-root-ca.pdf"
              target="_blank"
              rel="noopener noreferrer"
            >
              Xem hướng dẫn (PDF)
            </Button>
          </Space>
        </div>
      }
      closable
      onClose={handleClose}
      style={{ marginBottom: 16, borderRadius: 8 }}
    />
  );
}
```

**Part B: Modify `e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx`:**

**Step B.1: Thêm import:**
```tsx
import RootCABanner from '@/components/notifications/RootCABanner';
```

**Step B.2: Thêm state (gần các state hiện có):**
```tsx
const [showRootCABanner, setShowRootCABanner] = useState(false);
```

**Step B.3: Modify handleDownload để trigger banner (trong existing useCallback):**

Tìm function handleDownload hiện tại:
```tsx
const handleDownload = useCallback(async (row: TxnRow) => {
  try {
    const { data: res } = await api.get(`/ky-so/sign/${row.transaction_id}/download`);
    if (res?.success && res?.data?.url) {
      window.open(res.data.url, '_blank', 'noopener,noreferrer');
    }
  } catch (err: unknown) {
    // ... error handling
  }
}, [message]);
```

Thay bằng:
```tsx
const handleDownload = useCallback(async (row: TxnRow) => {
  try {
    const { data: res } = await api.get(`/ky-so/sign/${row.transaction_id}/download`);
    if (res?.success && res?.data?.url) {
      window.open(res.data.url, '_blank', 'noopener,noreferrer');

      // Phase 13 D-22: Trigger Root CA banner khi MYSIGN_VIETTEL + chưa dismiss
      if (
        row.provider_code === 'MYSIGN_VIETTEL' &&
        typeof window !== 'undefined' &&
        localStorage.getItem('dismiss_root_ca_banner') !== 'true'
      ) {
        setShowRootCABanner(true);
        // D-26: Mark shown-once (informational — dismiss logic riêng)
        localStorage.setItem('root_ca_banner_shown_once', 'true');
      }
    }
  } catch (err: unknown) {
    // ... existing error handling giữ nguyên
  }
}, [message]);
```

**Step B.4: Mount RootCABanner trong render block:**

Tìm hiện tại:
```tsx
return (
  <>
    <div className="page-header">
      <Title level={3} className="page-title">
        <SafetyCertificateOutlined style={{ color: '#0891B2' }} /> Danh sách ký số
      </Title>
    </div>

    <Card className="page-card">
      <Tabs ... />
    </Card>

    {renderSignModal()}
  </>
);
```

Thay bằng:
```tsx
return (
  <>
    <div className="page-header">
      <Title level={3} className="page-title">
        <SafetyCertificateOutlined style={{ color: '#0891B2' }} /> Danh sách ký số
      </Title>
    </div>

    {/* Phase 13 D-23: Root CA banner vị trí dưới page header, full width */}
    <RootCABanner
      visible={showRootCABanner}
      onDismiss={() => setShowRootCABanner(false)}
    />

    <Card className="page-card">
      <Tabs ... />
    </Card>

    {renderSignModal()}
  </>
);
```

**Step B.5: Cùng pattern cho initialLoading render (line ~764-777)** — nếu banner logic không cần cho initial loading (user chưa download được gì), thì bỏ qua. Giữ initialLoading block nguyên. Banner chỉ mount trong return chính.

Compile + verify:
```bash
cd e_office_app_new/frontend
npx tsc --noEmit 2>&1 | grep -E "components/notifications/RootCABanner\.tsx|ky-so/danh-sach/page\.tsx" | (! grep -q "error TS")
```

Smoke test manual:
1. Clear localStorage: `localStorage.clear()` trong DevTools
2. Navigate `/ky-so/danh-sach` tab "Đã ký" (cần có txn completed với provider=MYSIGN)
3. Click "Tải file đã ký" → new tab mở với file
4. Quay lại trang → Banner info hiển thị dưới page header, trên card tabs
5. Click "Tải Root CA (.cer)" → file `viettel-ca-new.cer` download
6. Click "Xem hướng dẫn (PDF)" → mở tab mới với PDF
7. Click X close trên banner → banner unmount, `localStorage.dismiss_root_ca_banner = 'true'`
8. Click download file MYSIGN lần nữa → banner KHÔNG hiện lại (đã dismiss)
9. Clear localStorage + click download → banner hiện lại

**Verify Vietnamese diacritics:**
Tất cả text trong banner: "Cần cài Root CA Viettel để Adobe Reader hiển thị chữ ký hợp lệ", "Nếu Adobe Reader báo chữ ký không xác thực khi mở file đã ký bằng MySign Viettel...", "Tải Root CA (.cer)", "Xem hướng dẫn (PDF)" — ĐÚNG có dấu.
  </action>
  <verify>
<automated>
test -f e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx && \
grep -q "export default function RootCABanner" e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx && \
grep -q "SafetyCertificateOutlined" e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx && \
grep -q "href=\"/root-ca/viettel-ca-new.cer\"" e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx && \
grep -q "href=\"/root-ca/huong-dan-cai-root-ca.pdf\"" e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx && \
grep -q 'download' e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx && \
grep -q "localStorage.setItem.*dismiss_root_ca_banner" e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx && \
grep -q "Cần cài Root CA Viettel" e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx && \
grep -q 'closable' e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx && \
# Verify integration page.tsx
grep -q "import RootCABanner from" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx && \
grep -q "<RootCABanner" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx && \
grep -q "setShowRootCABanner" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx && \
grep -q "MYSIGN_VIETTEL" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx && \
grep -q "dismiss_root_ca_banner" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx && \
grep -q "root_ca_banner_shown_once" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx && \
cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | grep -E "components/notifications/RootCABanner\.tsx|ky-so/danh-sach/page\.tsx" | (! grep -q "error TS") && \
echo "Task 2 OK"
</automated>
  </verify>
  <done>
    - `RootCABanner.tsx` tồn tại với `export default function RootCABanner`
    - Component accept `visible` + `onDismiss` props
    - AntD 6 `<Alert type="info" closable onClose={...} />` với icon SafetyCertificateOutlined
    - 2 Button download links: `/root-ca/viettel-ca-new.cer` (download attr) và `/root-ca/huong-dan-cai-root-ca.pdf` (target _blank)
    - localStorage.setItem `dismiss_root_ca_banner = 'true'` trong onClose
    - Defense-in-depth check localStorage trước render
    - `/ky-so/danh-sach/page.tsx` import + mount banner dưới page header
    - `handleDownload` trigger `setShowRootCABanner(true)` khi `provider_code === 'MYSIGN_VIETTEL'` + chưa dismiss
    - Banner state reset per page load (user F5 có thể thấy lại nếu chưa dismiss)
    - TypeScript clean
    - Vietnamese diacritics đầy đủ
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Next.js static server → Browser | `/root-ca/*` files public, không auth — intentional (public CA certs) |
| localStorage → Component | Untrusted — attacker có thể tampering qua DevTools, nhưng banner chỉ là UX hint |
| Click download → Browser download dialog | Browser enforce same-origin hoặc CORS; static file serve same-origin OK |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-13-17 | I (Info Disclosure) — Root CA file lộ public, không authz | /root-ca/*.cer | accept | File Root CA là PUBLIC certificate từ Viettel — intentional distribution. Không có secret. Download by anyone = no harm |
| T-13-18 | T (Tampering) — Attacker tamper file .cer trong git và user download file malicious | /root-ca/viettel-ca-new.cer | mitigate | File trong git history → git audit + code review. Production deploy lấy từ trusted git remote. Để defense-in-depth cao hơn: Phase 14 có thể add SHA256 checksum verify (hiện defer) |
| T-13-19 | S (Spoofing) — Attacker create site giả với URL /root-ca/fake.cer | Banner | accept | URL là relative (`/root-ca/...`) → chỉ hoạt động trên cùng domain. Nếu user click từ app legit → luôn lấy từ cùng server. Phishing qua external link không thuộc phạm vi banner |
| T-13-20 | D (DoS) — Infinite re-show banner consume client memory | localStorage key collision | mitigate | Banner render conditional `visible && !dismissed` → unmount khi dismissed. localStorage key namespaced `dismiss_root_ca_banner` + `root_ca_banner_shown_once` — không conflict |
| T-13-21 | I (Info Disclosure) — Download URL leak qua referer khi target=_blank | PDF link | mitigate | `rel="noopener noreferrer"` attr thêm vào PDF link — browser không send Referer header (Phase 12 pattern consistent) |
</threat_model>

<verification>
1. **Files exist + valid:**
   - `e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer` — tồn tại, size > 500 bytes < 10KB (typical .cer)
   - `e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf` — tồn tại, size > 0, PDF magic "%PDF"

2. **Next.js static serve:**
   ```bash
   curl -sI http://localhost:3000/root-ca/viettel-ca-new.cer | grep "HTTP/1.1 200"
   curl -sI http://localhost:3000/root-ca/huong-dan-cai-root-ca.pdf | grep "HTTP/1.1 200"
   ```

3. **Banner component render:**
   - DevTools browser manually set: `window.__test_showBanner = true` và render component mock → Alert visible với title + description + 2 buttons + X close
   - Click X → `localStorage.getItem('dismiss_root_ca_banner')` = `'true'`

4. **Integration trigger:**
   - localStorage.clear() → click download txn MYSIGN → banner hiện
   - Click download txn SMARTCA_VNPT → banner KHÔNG hiện
   - localStorage `dismiss_root_ca_banner` = `'true'` → click download MYSIGN → banner KHÔNG hiện (dismissed)

5. **Downloads work:**
   - Click "Tải Root CA (.cer)" → browser download `viettel-ca-new.cer`
   - Click "Xem hướng dẫn (PDF)" → mở tab mới với PDF viewer
</verification>

<success_criteria>
Plan 13-04 hoàn tất khi:
- [ ] `frontend/public/root-ca/viettel-ca-new.cer` tồn tại (copy từ docs source, giữ tên)
- [ ] `frontend/public/root-ca/huong-dan-cai-root-ca.pdf` tồn tại (copy từ docs source, rename kebab-case)
- [ ] `RootCABanner.tsx` component với props `visible` + `onDismiss`, Alert type=info closable
- [ ] 2 Button download links: .cer (download attr) + PDF (target=_blank, rel noopener noreferrer)
- [ ] localStorage integration: check + set `dismiss_root_ca_banner` key
- [ ] `/ky-so/danh-sach/page.tsx` mount banner dưới page header
- [ ] `handleDownload` trigger banner khi `provider_code === 'MYSIGN_VIETTEL'` + chưa dismiss
- [ ] localStorage `root_ca_banner_shown_once` set sau lần trigger đầu
- [ ] TypeScript clean, Vietnamese diacritics, AntD 6 `<Alert closable onClose>`
- [ ] Next.js dev server serve `/root-ca/*` 200 OK
- [ ] UX-11 + DEP-02 covered
</success_criteria>

<output>
Tạo `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-04-SUMMARY.md` sau khi hoàn tất.
</output>
