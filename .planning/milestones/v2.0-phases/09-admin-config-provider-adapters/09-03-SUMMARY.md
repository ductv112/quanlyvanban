---
phase: 09-admin-config-provider-adapters
plan: 03
subsystem: frontend
tags: [signing, admin-ui, ant-design, drawer, sidebar, fix-patch]

# Dependency graph
requires:
  - phase: 09-02
    provides: 6 Admin endpoints /api/ky-so/cau-hinh* (list / test-connection / upsert / update / active / delete)
  - phase: 09-01
    provides: Provider adapters + dispatcher (used indirectly qua POST /test-connection)
provides:
  - frontend/src/app/(main)/ky-so/cau-hinh/page.tsx — Admin config page cho 2 provider cố định
  - frontend/src/components/layout/MainLayout.tsx — menu 'KÝ SỐ > Cấu hình ký số hệ thống' (admin-only)
  - database/migrations/043_seed_default_providers.sql — seed SmartCA VNPT (active) + MySign Viettel (inactive)
affects:
  - Phase 10 (sign flow) — provider đã seed, sign flow đọc active provider ra để ký
  - UX: Admin chỉ sửa 2 provider cố định, không tạo/xóa

# Tech tracking
tech-stack:
  added: []  # Reuse AntD 6 primitives + existing api/axios
  patterns:
    - "Fixed provider set pattern: hệ thống cố định 2 provider (SmartCA VNPT + MySign Viettel) — không cho phép add/delete, chỉ sửa/kích hoạt"
    - "Card-based provider UI (thay cho Table): mỗi provider 1 Card độc lập với badge active, Descriptions chi tiết, footer actions (Sửa + Kích hoạt)"
    - "Seeded encrypted credentials: migration 043 dùng pgp_sym_encrypt với key trùng env SIGNING_SECRET_KEY để backend decrypt được lúc runtime"
    - "GET endpoint data integrity guard: trả 500 nếu thiếu provider default (ép Admin chạy migration 043 trước khi dùng trang)"
    - "405 Method Not Allowed cho POST + DELETE: không disable route hoàn toàn (vẫn route.post/delete) — trả 405 với message rõ để debug dễ"
    - "Kích hoạt gate on test_result: UI không cho kích hoạt provider có test_result != 'OK' (đảm bảo không kích hoạt provider chưa verify)"

key-files:
  created:
    - e_office_app_new/frontend/src/app/(main)/ky-so/cau-hinh/page.tsx (initial + rewrite)
    - e_office_app_new/database/migrations/043_seed_default_providers.sql (fix patch)
    - .planning/phases/09-admin-config-provider-adapters/09-03-SUMMARY.md
  modified:
    - e_office_app_new/frontend/src/components/layout/MainLayout.tsx (sidebar + breadcrumb)
    - e_office_app_new/backend/src/routes/ky-so-cau-hinh.ts (fix patch — disable POST + DELETE)

key-decisions:
  - "Fix patch lý do: UX feedback user — hệ thống thực tế CHỈ CÓ 2 provider cố định, không cần multi-provider CRUD. Pattern cũ (add/edit/delete + tabs switching stats) gây nhầm lẫn."
  - "Seed SmartCA VNPT với credentials từ source cũ (.NET) để demo có sẵn: client_id '4d00-638392811079166938.apps.smartcaapi.com', client_secret 'ZjA4MjE4NDg-MjU3Mi00ZDAw'. Production PHẢI update lại qua drawer."
  - "Migration 043 idempotent (WHERE NOT EXISTS) — an toàn chạy lại nhiều lần, không gây duplicate."
  - "Chọn 405 Method Not Allowed thay vì xóa route handler: giữ handler tránh 404 (misleading — route vẫn tồn tại, chỉ không được phép). Message tiếng Việt giải thích rõ."
  - "GET trả 500 khi thiếu provider default: ép ops team chạy migration trước khi dùng trang, tránh UI render nửa vời."
  - "Stats KHÔNG còn tabs switching: luôn hiển thị stats của provider đang active (hoặc 0 nếu chưa active). Đơn giản hóa UX — stats của provider phụ không hiển thị vì không dùng để ký."
  - "Card layout 2 cột (Row xs=24 md=12): responsive — mobile stack dọc, desktop side-by-side. Border xanh 2px cho provider active để nhấn mạnh."
  - "Kích hoạt gate on test_result != 'OK': cảnh báo modal rõ ràng, không cho kích hoạt mù quáng provider chưa verify → tránh break ký số production."
  - "Drawer không còn radio chọn provider type: provider được xác định từ card user click — form đơn giản hơn, loại bỏ trạng thái invalid."

patterns-established:
  - "Pattern: Fixed entity set — khi số lượng entity cố định & nhỏ (<= 5), dùng Card grid thay vì Table + CRUD full. UI rõ ràng hơn, UX ít bước hơn."
  - "Pattern: Migration seed dùng session variable — SET app.xxx='key'; \\i file — không cần psql -v variable (không work trong DO block)."
  - "Pattern: Data integrity check trong route GET — return 500 với hướng dẫn cụ thể thay vì lặng lẽ trả empty array."

requirements-completed: [SIGN-01, SIGN-02, CFG-01, CFG-02, CFG-03, CFG-04, CFG-07]

# Deviations
deviations:
  - "Rule 2 (missing critical functionality) — DB chưa seed provider default khi mount trang. Fix: thêm migration 043 + GET guard 500."
  - "Rule 1 (UX bug) — pattern multi-provider gây nhầm lẫn (tabs stats, button Thêm/Delete vô lý). Fix: rewrite page + disable POST/DELETE."

# Metrics
duration: ~35min (execute Task 1+2 ~20min + fix patch ~15min)
completed: 2026-04-21
---

# Phase 9 Plan 03: Admin Signing Config Page Summary

Admin config page tại `/ky-so/cau-hinh` cho phép quản trị viên cấu hình 2 provider cố định (SmartCA VNPT + MySign Viettel), kích hoạt 1 provider cho toàn hệ thống, xem stats KPI từ `fn_signing_stats`. **Fix patch 09-03** đổi UX từ multi-provider CRUD pattern (table + add/delete) sang fixed-card pattern (2 card cố định, chỉ sửa/kích hoạt).

## Overview

Plan 09-03 triển khai 2 bước:

1. **Triển khai ban đầu** (commits `b73e9fb` + `9408f1b`):
   - Page `/ky-so/cau-hinh` với stats + form + table multi-provider + drawer
   - Sidebar menu "KÝ SỐ" group, submenu "Cấu hình ký số hệ thống" (admin-only)

2. **Fix patch** (commits `afa1cb8` + `3515173` + `97a72a9`):
   - Migration 043 seed 2 provider cố định (SmartCA VNPT active + MySign Viettel inactive)
   - Backend: disable POST (405) + DELETE (405), GET trả 500 khi thiếu default
   - Frontend: rewrite hoàn toàn theo thiết kế 2-card, bỏ multi-provider CRUD

## Files

### Created

| File | Lines | Purpose |
|------|-------|---------|
| `e_office_app_new/frontend/src/app/(main)/ky-so/cau-hinh/page.tsx` | 777 | Admin config page (rewrite patch 09-03) |
| `e_office_app_new/database/migrations/043_seed_default_providers.sql` | 119 | Seed 2 provider cố định (patch 09-03) |

### Modified

| File | Change | Purpose |
|------|--------|---------|
| `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` | +15 lines | Menu group 'KÝ SỐ' + breadcrumbs (Task 2 original) |
| `e_office_app_new/backend/src/routes/ky-so-cau-hinh.ts` | -102 net | Disable POST + DELETE (patch 09-03) |

## Commits

| Hash | Message |
|------|---------|
| `b73e9fb` | `feat(09-03): add Admin signing-provider config page /ky-so/cau-hinh` |
| `9408f1b` | `feat(09-03): add KÝ SỐ sidebar group with admin-only Cấu hình submenu` |
| `afa1cb8` | `fix(09-03): seed 2 provider configs cố định (SmartCA VNPT + MySign Viettel)` |
| `3515173` | `fix(09-03): disable POST+DELETE endpoints ký số cau-hinh (chỉ 2 provider cố định)` |
| `97a72a9` | `fix(09-03): rewrite trang cấu hình ký số theo 2 provider cố định` |

## Layout sau patch 09-03

```
┌────────────────────────────────────────────────────────────┐
│ [Page Header] Cấu hình ký số hệ thống                      │
├────────────────────────────────────────────────────────────┤
│ [Alert success] ✓ Provider đang hoạt động: SmartCA VNPT   │
│                    (https://gwsca.vnpt.vn) ...  [Làm mới] │
├────────────────────────────────────────────────────────────┤
│ [Stats Card] Thống kê (SmartCA VNPT)                       │
│  [5 KPI cards grid] Tổng user / Verified / Tháng / OK / Fail │
├─────────────────────────────┬──────────────────────────────┤
│ [Card] SmartCA VNPT         │ [Card] MySign Viettel        │
│  🛡 ... [Đang kích hoạt]    │  🛡 ... [Không hoạt động]   │
│  Base URL: https://gwsca... │  Base URL: Chưa cấu hình    │
│  Client ID: 4d00-638...     │  Client ID: —               │
│  Client Secret: *** ✓       │  Client Secret: —           │
│                             │  Profile ID: —               │
│  Kiểm tra: ⚠ Chưa kiểm tra  │  Kiểm tra: ⚠ Chưa kiểm tra  │
│  Cập nhật: 21/04/2026 14:07 │  Cập nhật: 21/04/2026 14:07 │
│  [Sửa cấu hình]             │  [Sửa cấu hình] [Kích hoạt] │
└─────────────────────────────┴──────────────────────────────┘
```

## Migration 043 — Cách chạy

```bash
# Docker psql (dev):
docker cp e_office_app_new/database/migrations/043_seed_default_providers.sql qlvb_postgres:/tmp/
docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev \
  -c "SET app.signing_secret_key='qlvb-signing-dev-key-change-production-2026';" \
  -f /tmp/043_seed_default_providers.sql

# Production: dùng key từ env SIGNING_SECRET_KEY — PHẢI trùng với backend
```

Verify:
```sql
SELECT id, provider_code, is_active, base_url, client_id FROM public.signing_provider_config;
-- Expect: 2 rows (SmartCA active=t, MySign active=f)
```

## API surface sau patch

| Endpoint | Status | Note |
|----------|--------|------|
| GET /api/ky-so/cau-hinh | OK | Trả 500 nếu thiếu default rows |
| POST /api/ky-so/cau-hinh/test-connection | OK | Test credentials từ form (plaintext secret) |
| POST /api/ky-so/cau-hinh | **405** | Disabled — không tạo provider mới |
| PUT /api/ky-so/cau-hinh/:id | OK | Update 1 trong 2 row cố định |
| PATCH /api/ky-so/cau-hinh/:id/active | OK | Kích hoạt (auto-deactivate other) |
| DELETE /api/ky-so/cau-hinh/:id | **405** | Disabled — không xóa provider cố định |

## Acceptance verified

- [x] Migration 043 applied, DB có 2 row provider_code SMARTCA_VNPT (active=t) + MYSIGN_VIETTEL (active=f)
- [x] POST /cau-hinh trả 405 (verified via code review + route handler)
- [x] DELETE /cau-hinh/:id trả 405 (verified via code review + route handler)
- [x] Trang /ky-so/cau-hinh hiển thị 2 card cố định, không có button "Thêm mới", không có tabs SmartCA/MySign ở stats
- [x] Alert top: "Provider đang hoạt động: SmartCA VNPT (https://gwsca.vnpt.vn) ..." khi SmartCA active
- [x] Sửa SmartCA → Drawer prepopulated với base_url + client_id từ source cũ, secret field trống (placeholder "Để trống nếu giữ nguyên")
- [x] Kích hoạt MySign khi test_result != 'OK' → modal warning "Không thể kích hoạt provider chưa test OK"
- [x] TypeScript `tsc --noEmit` passes cho ky-so/cau-hinh/page.tsx (0 error new)
- [x] 3 commits atomic với prefix fix(09-03):
- [x] Phase 9 hoàn thành đủ 7 REQ-IDs (SIGN-01, SIGN-02, CFG-01..04, CFG-07)

## Self-Check: PASSED

- **Files exist:**
  - `e_office_app_new/frontend/src/app/(main)/ky-so/cau-hinh/page.tsx` (777 lines)
  - `e_office_app_new/database/migrations/043_seed_default_providers.sql` (119 lines)
  - `e_office_app_new/backend/src/routes/ky-so-cau-hinh.ts` (277 lines after patch)
- **Commits exist:**
  - `afa1cb8` — migration 043 seed
  - `3515173` — backend disable POST/DELETE
  - `97a72a9` — frontend rewrite
- **DB verified:** 2 rows seeded, pgp_sym_decrypt returns expected plaintext with env key.
