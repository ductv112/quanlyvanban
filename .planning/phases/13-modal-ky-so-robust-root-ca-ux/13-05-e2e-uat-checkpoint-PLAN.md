---
phase: 13
plan: 05
type: execute
wave: 3
depends_on: [13-01, 13-02, 13-03, 13-04]
files_modified: []
autonomous: false
requirements:
  - UX-07
  - UX-08
  - UX-09
  - UX-10
  - UX-11
  - DEP-02
tags: [e2e, uat, checkpoint, verification, signing, root-ca, bell]
must_haves:
  truths:
    - "AC#1: Modal ký số không bị spam — button Ký số disable khi modal open, loading spinner khi POST /sign"
    - "AC#2: Countdown 3:00 hiển thị circular realtime, đổi màu 3 mốc, expired text khi hết giờ, 2 button pending + 1 button terminal"
    - "AC#3: Bell notification toast + badge khi Socket event, user offline vẫn thấy notification trong dropdown khi login lại"
    - "AC#4: Banner Root CA dismissible với 2 link .cer + PDF, localStorage persist dismiss state"
    - "AC#5: File /root-ca/viettel-ca-new.cer + /root-ca/huong-dan-cai-root-ca.pdf accessible qua URL tĩnh (200 OK)"
  artifacts:
    - path: ".planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md"
      provides: "Bảng verify 5 AC từ ROADMAP, 30 decisions từ CONTEXT (D-01 → D-30), 6 REQ IDs (UX-07..11 + DEP-02)"
  key_links: []
---

<objective>
Verify end-to-end + UAT checkpoint cho Phase 13. Tổng hợp kết quả 4 plan trước (13-01 BE notifications, 13-02 FE bell, 13-03 SignModal polish, 13-04 Root CA) thành báo cáo + test thủ công với user. Đây là plan cuối CHẶN NGANG, KHÔNG tự chạy — yêu cầu user test và approve.

**Scope verify:**
1. Test backend infrastructure (DB table, SPs, API endpoints) hoạt động đúng
2. Test FE bell component với data real (socket event fire → toast → badge → dropdown update)
3. Test SignModal countdown + color states + 2 button semantic
4. Test Root CA banner trigger + dismiss + localStorage persist
5. Compile toàn bộ TypeScript zero new errors
6. Seed optional: 1 notification completed + 1 failed cho user test UI với data có sẵn
7. Gatekeeper: human-verify checkpoint

**KHÔNG thuộc scope:**
- Fix bug mới phát sinh — nếu verify fail, tạo gap-closure plan mới (Plan 13-06+)
- Change scope decisions từ 13-CONTEXT — user đã lock, chỉ verify implement đúng
- Load test / stress test — Phase 14

Output: 1 verification report + checkpoint gate để user approve trước khi commit Phase 13.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md
@.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-01-notification-backend-infrastructure-PLAN.md
@.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-02-bell-notification-frontend-PLAN.md
@.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-03-signmodal-countdown-polish-PLAN.md
@.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-04-root-ca-banner-files-PLAN.md
@.planning/ROADMAP.md
@CLAUDE.md
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 1: Seed 2 test notifications + compile check + automated E2E verify toàn phase</name>
  <files>.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md</files>
  <read_first>
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-CONTEXT.md` (30 decisions để map verify)
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-01-notification-backend-infrastructure-PLAN.md`
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-02-bell-notification-frontend-PLAN.md`
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-03-signmodal-countdown-polish-PLAN.md`
    - `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-04-root-ca-banner-files-PLAN.md`
    - `.planning/phases/12-menu-ky-so-danh-sach-4-tab/12-03-SUMMARY.md` (pattern seed test + UAT)
  </read_first>
  <action>
**Step 1: Seed 2 test notifications vào DB dev (cho user test bell UI):**

```bash
# Lấy staff_id=1 (admin) — user login để test
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 -c "
-- 1. Notification sign_completed (~5 phút trước)
INSERT INTO public.notifications(staff_id, type, title, message, link, metadata, is_read, created_at)
VALUES (
  1,
  'sign_completed',
  'Ký số thành công: đính kèm #100',
  'Giao dịch ký số #9001 đã hoàn tất. Nhấn để xem file đã ký.',
  '/ky-so/danh-sach?tab=completed',
  '{\"transaction_id\":9001,\"provider_code\":\"MYSIGN_VIETTEL\",\"attachment_id\":100,\"attachment_type\":\"outgoing\"}'::jsonb,
  FALSE,
  NOW() - INTERVAL '5 minutes'
);

-- 2. Notification sign_failed (~2 phút trước)
INSERT INTO public.notifications(staff_id, type, title, message, link, metadata, is_read, created_at)
VALUES (
  1,
  'sign_failed',
  'Ký số thất bại',
  'Giao dịch ký số #9002 thất bại: Provider từ chối chữ ký.',
  '/ky-so/danh-sach?tab=failed',
  '{\"transaction_id\":9002,\"provider_code\":\"SMARTCA_VNPT\",\"attachment_id\":101,\"attachment_type\":\"drafting\",\"error_message\":\"Provider từ chối chữ ký\",\"status\":\"failed\"}'::jsonb,
  FALSE,
  NOW() - INTERVAL '2 minutes'
);

-- Verify
SELECT id, type, title, is_read, created_at
FROM public.notifications WHERE staff_id = 1 ORDER BY created_at DESC LIMIT 5;
"
```

**Step 2: Run TypeScript compile check toàn bộ:**

```bash
# Backend
cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tee /tmp/tsc_backend.log
# Check: không có "error TS" mới trong 4 file Phase 13 touched
grep -E "notification\.repository\.ts|routes/notifications\.ts|workers/signing-poll\.worker\.ts|server\.ts" /tmp/tsc_backend.log | (! grep -q "error TS") && echo "Backend TS clean for Phase 13 files"

# Frontend
cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | tee /tmp/tsc_frontend.log
# Check: không có "error TS" mới trong 6 file Phase 13 touched
grep -E "api-notifications\.ts|BellNotification\.tsx|SignModal\.tsx|use-signing\.tsx|RootCABanner\.tsx|ky-so/danh-sach/page\.tsx|layout/MainLayout\.tsx" /tmp/tsc_frontend.log | (! grep -q "error TS") && echo "Frontend TS clean for Phase 13 files"
```

**Step 3: Automated verify 5 AC + 30 decisions + 6 REQ IDs:**

```bash
# AC#1: Spam-click protection
grep -q "disabled={signModalOpen}" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx  # caller disable
grep -q "initiating" e_office_app_new/frontend/src/components/signing/SignModal.tsx  # state guard

# AC#2: Countdown + 2 button
grep -q "type=\"circle\"" e_office_app_new/frontend/src/components/signing/SignModal.tsx
grep -q "COUNTDOWN_MS = 180_000" e_office_app_new/frontend/src/components/signing/SignModal.tsx
grep -q 'mask={{ closable: false }}' e_office_app_new/frontend/src/components/signing/SignModal.tsx
grep -q "'#1B3A5C'" e_office_app_new/frontend/src/components/signing/SignModal.tsx
grep -q "'#D97706'" e_office_app_new/frontend/src/components/signing/SignModal.tsx
grep -q "'#DC2626'" e_office_app_new/frontend/src/components/signing/SignModal.tsx

# AC#3: Bell notification infrastructure + UI
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -tAc "SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='notifications'" | grep -q 1
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -tAc "SELECT count(*) FROM pg_proc WHERE proname LIKE 'fn_notification_%'" | grep -q 5
test -f e_office_app_new/backend/src/repositories/notification.repository.ts
test -f e_office_app_new/backend/src/routes/notifications.ts
grep -q "app.use('/api/notifications'" e_office_app_new/backend/src/server.ts
test -f e_office_app_new/frontend/src/components/notifications/BellNotification.tsx
grep -q "notificationRepository.create" e_office_app_new/backend/src/workers/signing-poll.worker.ts

# AC#4: Root CA banner + dismiss
test -f e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx
grep -q "localStorage.setItem.*dismiss_root_ca_banner" e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx

# AC#5: Root CA static files
test -f e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer
test -f e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf

# Next.js static serve (yêu cầu frontend dev server đang chạy)
curl -sI http://localhost:3000/root-ca/viettel-ca-new.cer 2>/dev/null | head -1 | grep -q "200" || echo "WARNING: frontend chưa chạy, bỏ qua static serve test"
```

**Step 4: Tạo file report `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md`:**

```markdown
# Phase 13 — Verification Report

**Generated:** {date}
**Status:** PENDING_UAT

## AC Coverage (5 ACs từ ROADMAP)

| AC# | Description | Automated Verify | Manual UAT | Status |
|-----|-------------|------------------|------------|--------|
| 1 | Modal maskClosable:false + spam protection | grep check passed | user test double-click button Ký số | PENDING |
| 2 | Countdown 3:00 + 2 button phân biệt | grep countdown Progress + footer logic | user test visual timer + color transition | PENDING |
| 3 | Bell toast + offline persistence | DB table + 5 SPs + 4 endpoints OK, BellNotification.tsx mounted | user test Socket emit + F5 refresh badge | PENDING |
| 4 | Banner dismissible Root CA | Component exists + localStorage logic | user test click download MYSIGN → banner | PENDING |
| 5 | Root CA files URL tĩnh | 2 files copied vào public/root-ca/, static serve | curl URL 200 OK | PENDING |

## Decision Coverage (30 decisions D-01 → D-30)

(Auto-populate bảng qua grep các marker trong implementation files)

| ID | Decision summary | Plan | File | Verified |
|----|------------------|------|------|----------|
| D-01 | Bell notification DB PostgreSQL | 13-01 | schema/000_schema_v2.0.sql | ✓ |
| D-02 | Table notifications schema | 13-01 | CREATE TABLE IF NOT EXISTS public.notifications | ✓ |
| D-03 | 5 SPs fn_notification_* | 13-01 | pg_proc count=5 | ✓ |
| D-04 | Retention 30 ngày (defer cleanup Phase 14) | 13-01 | Documented only, no cleanup job | ✓ (defer) |
| D-05 | Scope chỉ sign_completed + sign_failed | 13-01 | Worker branches | ✓ |
| D-06 | Worker persist TRƯỚC emit | 13-01 | awk line order check | ✓ |
| D-07 | 4 API endpoints | 13-01 | routes/notifications.ts | ✓ |
| D-08 | Bell icon trong header | 13-02 | MainLayout <BellNotification /> | ✓ |
| D-09 | Dropdown 10 items + mark-all button | 13-02 | BellNotification dropdownContent | ✓ |
| D-10 | Icon + title + time + click navigate | 13-02 | BellNotification item render | ✓ |
| D-11 | Toast notification.success/.error 3s | 13-02 | Socket listener | ✓ |
| D-12 | Stale-while-revalidate fetch | 13-02 | handleOpenChange refreshList | ✓ |
| D-13 | Circular progress size=120 + MM:SS | 13-03 | SignModal Progress | ✓ |
| D-14 | FE local timer tick 1s | 13-03 | countdown useEffect setInterval | ✓ |
| D-15 | Color state 3 mốc | 13-03 | countdownColor helper | ✓ |
| D-16 | Expired state transition | 13-03 | expiredFired ref | ✓ |
| D-17 | Text dưới countdown | 13-03 | "Vui lòng xác nhận OTP trên ứng dụng" | ✓ |
| D-18 | Giữ auto-fire, không thêm confirm button | 13-03 | start() in useEffect | ✓ |
| D-19 | Caller button disable | 13-03 | disabled={signModalOpen} | ✓ |
| D-20 | 2 button pending | 13-03 | footer logic | ✓ |
| D-21 | 1 button terminal | 13-03 | footer logic | ✓ |
| D-22 | Trigger banner MYSIGN + chưa dismiss | 13-04 | handleDownload logic | ✓ |
| D-23 | Banner vị trí dưới page header | 13-04 | page.tsx render order | ✓ |
| D-24 | Banner content + 2 button | 13-04 | RootCABanner JSX | ✓ |
| D-25 | Dismiss per-browser localStorage | 13-04 | localStorage.setItem | ✓ |
| D-26 | root_ca_banner_shown_once informational | 13-04 | page.tsx handleDownload | ✓ |
| D-27 | Source files đã có trong repo | 13-04 | docs/... exists | ✓ |
| D-28 | Copy + rename kebab-case | 13-04 | public/root-ca/*.{cer,pdf} | ✓ |
| D-29 | Commit vào git | 13-04 | git add staged | ✓ |
| D-30 | Next.js tự serve public/* | 13-04 | curl 200 OK | ✓ |

## REQ Coverage (6 REQs)

| REQ | Description | Plan(s) | Status |
|-----|-------------|---------|--------|
| UX-07 | Modal spam protection | 13-03 | ✓ |
| UX-08 | maskClosable + 2 button | 13-03 | ✓ |
| UX-09 | Countdown 3:00 | 13-03 | ✓ |
| UX-10 | Bell notification toast + persist | 13-01 + 13-02 | ✓ |
| UX-11 | Root CA banner dismissible | 13-04 | ✓ |
| DEP-02 | Root CA files public/root-ca/ | 13-04 | ✓ |

## TypeScript Compile

- Backend: 0 new errors in 4 files (repo + route + worker + server.ts)
- Frontend: 0 new errors in 6 files (api-notifications + BellNotification + SignModal + use-signing + RootCABanner + danh-sach page + MainLayout)

## Threat Mitigations (STRIDE register coverage)

| Threat | Mitigation | Status |
|--------|------------|--------|
| T-13-01 (URL tamper page/pageSize) | parse guard + cap 100 | ✓ |
| T-13-02 (IDOR notification) | staffId từ JWT + SP filter | ✓ |
| T-13-03 (Mark read user khác) | SP owner check | ✓ |
| T-13-07 (Worker inject staff_id) | txn.staff_id từ DB | ✓ |
| T-13-08 (Socket cross-user) | Room user_{staffId} BE + toast filter | ✓ |
| T-13-13 (FE timer tamper) | BE authoritative, accept | ✓ |
| T-13-17 (Root CA public) | intentional, accept | ✓ |
| T-13-21 (Referer leak PDF) | rel=noopener noreferrer | ✓ |

## UAT Checklist (User sẽ test)

### UAT-1: Modal Spam Protection
1. Login admin, navigate `/ky-so/danh-sach` tab "Cần ký" (cần có data — seed Plan 12-03 đã có)
2. Double-click button "Ký số" một row
3. **Expected:** Chỉ 1 modal mở, không có 2 transaction tạo (kiểm tra DB `sign_transactions` count trước-sau)
4. Button "Ký số" các row khác disable trong khi modal mở

### UAT-2: Countdown 3:00 + Color + Expired
1. Tiếp UAT-1, modal đã mở với 1 txn pending
2. **Expected:** Circular progress 120px xanh đậm `#1B3A5C` với text `3:00` center
3. Đợi ~2 phút → text đổi `1:00`, màu đổi vàng `#D97706`
4. Đợi thêm ~30s → text `0:30`, màu đổi đỏ `#DC2626`
5. Đợi đến `0:00` → state chuyển `expired`, Alert error "Hết thời gian chờ xác nhận OTP", footer chỉ còn button "Đóng" primary
6. Trước khi hết giờ, verify text dưới circular: "Vui lòng xác nhận OTP trên ứng dụng **MySign Viettel** trên điện thoại" (hoặc SmartCA VNPT tùy provider active)

### UAT-3: 2 Button Phân Biệt
1. Mở modal mới (txn pending)
2. **Expected footer:**
   - Button "Hủy ký số" (danger, đỏ viền)
   - Button "Đóng (chạy nền)" (default)
3. Click "Đóng (chạy nền)" → modal close, txn tiếp tục pending (verify DB status='pending')
4. Open modal lần nữa (txn fail/expire/cancelled) — footer: chỉ button "Đóng" (type=primary)

### UAT-4: Bell Notification Flow
1. Seed data Task 1 đã insert 2 notifications cho staff_id=1
2. Login admin
3. **Expected:** Bell icon header có Badge count = 2 (hoặc cao hơn nếu có sẵn)
4. Click bell → Dropdown mở, hiển thị 2 items (seed) + có thể item khác
5. Verify item: icon status (✓ xanh cho completed, ✗ đỏ cho failed) + title + message + "5 phút trước" / "2 phút trước"
6. Click item 1 → navigate `/ky-so/danh-sach?tab=completed` + bell badge giảm 1 + item đổi từ unread sang read (background gần trắng)
7. Quay lại dashboard → click bell → click "Đánh dấu đã đọc tất cả" → badge count = 0 + tất cả items đổi sang read
8. Manual trigger Socket emit (nếu có tool): backend emit `sign_completed` → toast top-right 3s + badge +1 (online flow)

### UAT-5: Offline Persistence
1. Logout + close browser
2. Trigger sign event fake (run SP insert notification trực tiếp qua psql cho staff_id=1)
3. Login lại
4. **Expected:** Bell badge hiển thị count đúng + click bell → notification mới xuất hiện trong list
5. Confirm: user không cần online lúc event fire vẫn thấy notification sau login

### UAT-6: Root CA Banner
1. `localStorage.clear()` trong DevTools
2. Navigate `/ky-so/danh-sach` tab "Đã ký" (seed đã có txn completed với provider MYSIGN từ Plan 12-03)
3. Click "Tải file đã ký" row provider MYSIGN
4. **Expected:** Tab mới mở với file + quay lại trang banner Alert info hiển thị dưới page header, trên card tabs
5. Banner chứa:
   - Icon SafetyCertificate + title "Cần cài Root CA Viettel..."
   - Description + 2 button
   - Icon X góc phải
6. Click "Tải Root CA (.cer)" → browser download `viettel-ca-new.cer`
7. Click "Xem hướng dẫn (PDF)" → tab mới mở PDF viewer
8. Click X close → banner unmount + `localStorage.dismiss_root_ca_banner` = `"true"` (verify DevTools)
9. Click download MYSIGN lần nữa → banner KHÔNG hiện
10. Download txn SMARTCA_VNPT → banner KHÔNG hiện (chỉ cho MYSIGN)
11. `localStorage.removeItem('dismiss_root_ca_banner')` + download MYSIGN → banner hiện lại

### UAT-7: Root CA Files Static Serve
1. Mở 2 URL trực tiếp trong browser:
   - `http://localhost:3000/root-ca/viettel-ca-new.cer`
   - `http://localhost:3000/root-ca/huong-dan-cai-root-ca.pdf`
2. **Expected:** Cả 2 load 200 OK; .cer → browser download hoặc hiển thị binary; PDF → render PDF viewer
3. KHÔNG trả 404 dù không login (file public intentional)

## Status: PENDING_UAT_APPROVAL

Next step: User test manual theo UAT-1 đến UAT-7, approve hoặc báo bug.
```

Save file. Summary trong output message:
- 2 notifications seed OK
- TS compile clean Phase 13 files
- 30 decisions verified
- 5 AC + 6 REQ mapped
- Report tại `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md`
  </action>
  <verify>
<automated>
# Verify 2 notifications seeded
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -tAc "SELECT count(*) FROM public.notifications WHERE staff_id=1 AND type IN ('sign_completed','sign_failed')" | awk '$1 >= 2 {exit 0} {exit 1}' && \
# Verify report file
test -f .planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md && \
grep -q "## AC Coverage" .planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md && \
grep -q "D-30" .planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md && \
grep -q "PENDING_UAT" .planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md && \
# Automated verify 5 AC pointers đều resolve
grep -q "disabled={signModalOpen}" e_office_app_new/frontend/src/app/\(main\)/ky-so/danh-sach/page.tsx && \
grep -q "COUNTDOWN_MS = 180_000" e_office_app_new/frontend/src/components/signing/SignModal.tsx && \
test -f e_office_app_new/frontend/src/components/notifications/BellNotification.tsx && \
test -f e_office_app_new/frontend/src/components/notifications/RootCABanner.tsx && \
test -f e_office_app_new/frontend/public/root-ca/viettel-ca-new.cer && \
test -f e_office_app_new/frontend/public/root-ca/huong-dan-cai-root-ca.pdf && \
echo "Task 1 OK — ready for UAT checkpoint"
</automated>
  </verify>
  <done>
    - 2 test notifications seeded vào `public.notifications` cho staff_id=1 (1 sign_completed + 1 sign_failed)
    - TypeScript compile check Phase 13 files: 0 new errors backend + frontend
    - Automated verify chạy qua 5 AC + 30 decisions + 6 REQ IDs
    - File `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md` tạo với bảng AC/decisions/REQ/threat + UAT checklist 7 cases
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <name>Task 2: UAT checkpoint — user test 7 UAT cases, approve toàn Phase 13</name>
  <files>.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md</files>
  <action>
File verification report đã tạo ở Task 1. Claude KHÔNG tự chạy action mới — chuyển sang chế độ wait cho user test 7 UAT cases theo how-to-verify. Khi user reply `approved` hoặc `fail UAT-N: mô tả`, Claude tiếp tục xử lý.
  </action>
  <verify>
    <automated>test -f .planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md && grep -q "UAT Checklist" .planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md</automated>
  </verify>
  <done>User type `approved` hoặc `fail UAT-N: {mô tả bug}` — Claude resume tương ứng</done>
  <what-built>
Phase 13 đã hoàn tất 4 plan technical (13-01 → 13-04). Toàn bộ 6 REQ IDs (UX-07, UX-08, UX-09, UX-10, UX-11, DEP-02) + 30 CONTEXT decisions implemented. Automated grep/test passed. Giờ cần user test UX manual theo UAT checklist trong `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md`.
  </what-built>
  <how-to-verify>
**Setup:**
1. Đảm bảo backend + worker + frontend + PostgreSQL + Redis + MinIO tất cả running (docker compose up nếu chưa).
2. Login admin (email trong seed/001_required_data.sql, password Admin@123 mặc định).
3. Navigate `/ky-so/danh-sach` — seed từ Plan 12-03 đã có data 4 tab.

**UAT-1: Modal Spam Protection (AC#1)**
- Tab "Cần ký" → double-click "Ký số" một row
- PASS: Chỉ 1 modal mở, các button "Ký số" khác disable khi modal open
- FAIL: Nếu 2 modal / 2 transaction tạo

**UAT-2: Countdown 3:00 + Color (AC#2)**
- Modal vừa mở (txn pending)
- PASS: Circular 120px, text "3:00" xanh `#1B3A5C` tick xuống 2:59, 2:58...
- Sau 2 phút (tại 1:00 — hoặc QUÉT mockup tăng tốc bằng DevTools if needed) → vàng `#D97706`
- Sau 2:30 (tại 0:30) → đỏ `#DC2626`
- Tại 0:00 → state `expired` + Alert error
- Text dưới circular: "Vui lòng xác nhận OTP trên ứng dụng {SmartCA VNPT hoặc MySign Viettel} trên điện thoại"

**UAT-3: 2 Button Phân Biệt (AC#1 part 2)**
- Modal pending: footer có "Hủy ký số" (danger) + "Đóng (chạy nền)" (default)
- Click "Đóng (chạy nền)" → modal close, txn pending vẫn tồn tại trong tab "Đang xử lý"
- Modal terminal (completed/failed/expired/cancelled): chỉ 1 button "Đóng" primary
- maskClosable false: click backdrop → modal KHÔNG đóng

**UAT-4: Bell Online Flow (AC#3)**
- Bell badge hiển thị count ≥ 2 (seed notifications + có thể khác)
- Click bell → dropdown mở, 10 items gần nhất, seeded items có icon ✓ xanh (completed) và ✗ đỏ (failed)
- Relative time "5 phút trước", "2 phút trước"
- Click item → navigate link + badge giảm + item chuyển read
- "Đánh dấu đã đọc tất cả" → badge = 0

**UAT-5: Bell Offline Persistence (AC#3)**
- Logout
- Admin chạy: `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT * FROM public.fn_notification_create(1, 'sign_completed', 'Test offline', 'Notif khi user offline', '/ky-so/danh-sach', NULL::jsonb);"`
- Login lại
- PASS: Badge increment, bell dropdown hiển thị notification mới tạo lúc offline

**UAT-6: Root CA Banner (AC#4)**
- `localStorage.clear()` trong DevTools
- Tab "Đã ký" → click "Tải file đã ký" row có provider=MYSIGN
- PASS: Banner info hiển thị dưới page header với icon + title + 2 button + X
- "Tải Root CA (.cer)" → download file .cer
- "Xem hướng dẫn (PDF)" → tab mới mở PDF
- Click X → banner unmount, `localStorage.dismiss_root_ca_banner = "true"`
- Download MYSIGN lần nữa → banner KHÔNG hiện
- Download SMARTCA row → banner KHÔNG hiện (chỉ MYSIGN)

**UAT-7: Static Files Serve (AC#5)**
- Mở trực tiếp: `http://localhost:3000/root-ca/viettel-ca-new.cer` → 200 OK
- Mở: `http://localhost:3000/root-ca/huong-dan-cai-root-ca.pdf` → 200 OK, PDF render trong viewer

**Optional: Test trên browser khác** (Chrome → Firefox) để verify banner cross-browser CSS/layout không vỡ.
  </how-to-verify>
  <resume-signal>
Sau khi test đủ 7 UAT cases, reply:
- `approved` nếu tất cả pass → Phase 13 done, commit + update STATE.md + ROADMAP.md
- `fail UAT-{N}: {mô tả bug}` → tạo gap-closure plan Plan 13-06+ theo bug report
  </resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Human UAT tester → system | Trusted human testing manual — verify behavior không phải attack surface |
| Seed data → DB | Admin-only psql command (dev env), không affect production |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-13-22 | — | UAT process | accept | Checkpoint gate — human verify before commit; bug phát sinh tạo gap-closure plan |
| T-13-23 | I (Info Disclosure) — Seed data leak thông tin | seed notifications | accept | Dev env only; seed data mang title/message fake (#9001, #9002), không real txn |
</threat_model>

<verification>
Plan 13-05 hoàn tất khi:
- [ ] Task 1 seed + report passed automated verify
- [ ] Task 2 UAT checkpoint user response "approved" (hoặc fail+bug report xử lý riêng)

Sau khi approved:
- Commit toàn bộ Phase 13 files (user manual `git commit` theo CLAUDE.md rule)
- Update `.planning/STATE.md`: last_activity + stopped_at + Phase 13 completed
- Update `.planning/ROADMAP.md`: Phase 13 [x] completed + plan list tick off
- Update `.planning/REQUIREMENTS.md`: UX-07, UX-08, UX-09, UX-10, UX-11, DEP-02 → Status Complete
</verification>

<success_criteria>
Plan 13-05 gate hoàn tất khi:
- [ ] 2 notifications seeded + DB có data test UI
- [ ] `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-VERIFICATION.md` exists với đầy đủ AC/Decision/REQ matrix
- [ ] TypeScript compile clean cho tất cả file Phase 13 touched
- [ ] User manual test 7 UAT cases + reply `approved`
- [ ] Không có BLOCKER bug mới cần gap-closure plan
</success_criteria>

<output>
Sau khi UAT approved:
- Tạo `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-05-SUMMARY.md`
- Tạo `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-SUMMARY.md` (phase-level summary tổng hợp 4 plan + UAT)
</output>
