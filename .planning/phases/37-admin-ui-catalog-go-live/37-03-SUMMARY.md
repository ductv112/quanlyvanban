---
phase: 37-admin-ui-catalog-go-live
plan: 03
subsystem: frontend
tags: [frontend, ui, admin, lgsp, cau-hinh, antd, phase-37]

# Dependency graph
requires:
  - phase: 37-admin-ui-catalog-go-live
    plan: 01
    provides: 9 admin endpoints (GET /lgsp-agency-config + PUT /:id + PATCH /:id/active + 6 more)
  - phase: 37-admin-ui-catalog-go-live
    plan: 02
    provides: POST /lgsp-agency-config/:id/test endpoint (lightweight read-only)
provides:
  - "NEW page /lgsp/cau-hinh — Admin LGSP credential config Table 12 row + Drawer edit + Test Modal + active toggle"
  - "Pattern wiring 4 endpoints admin namespace: GET list / PUT update / PATCH active / POST test"
  - "Skeleton mirror /ky-so/cau-hinh nhưng đơn giản hơn (KHÔNG có stats provider riêng, tập trung Table inline + Drawer edit per row)"
affects: [37-06-frontend-menu-unhide-retry]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Admin role guard tại entry page: useAuthStore + check user?.isAdmin || roles.includes('Quản trị hệ thống') → render Alert warning nếu fail"
    - "Drawer 720 AntD 6 size= (không width=) + rootClassName='drawer-gradient' + extra footer Lưu/Hủy"
    - "Input.Password autoComplete='new-password' + KHÔNG prefill secret_key — admin nhập mới nếu muốn thay đổi, để trống = giữ ciphertext cũ"
    - "Switch toggle inline trong Table cell — KHÔNG cần confirm modal (admin có thể undo dễ dàng)"
    - "Modal test connection inline result: Spin loading → Alert success (Vietnamese + count VB) / error (HTTP status + gợi ý kiểm tra)"
    - "Form validateTrigger='onSubmit' theo project convention"

key-files:
  created:
    - e_office_app_new/frontend/src/app/(main)/lgsp/cau-hinh/page.tsx (735 lines)
  modified: []

key-decisions:
  - "Admin role check inline ở entry component (KHÔNG dùng redirect/middleware) — render Alert warning thân thiện hơn redirect đột ngột, vẫn enforce non-admin KHÔNG thấy data"
  - "Switch toggle is_active KHÔNG dùng confirm modal — UX rảnh tay hơn cho admin (toggle là idempotent, có thể flip lại ngay)"
  - "Input.Password placeholder + extra hint 'Để trống nếu giữ secret_key hiện tại' + KHÔNG prefill — UX rõ ràng tránh confusion 'giá trị '***' có phải secret thật không?'"
  - "Form payload secretKey chỉ truyền khi user nhập mới (trim != '') — match backend Plan 37-01 logic (undefined hoặc empty → giữ ciphertext cũ)"
  - "Test modal: button 'Kiểm tra lại' khi đã có result (tránh đóng modal + mở lại để re-test)"
  - "Stat cards: 3 metric đơn giản (đang kết nối / production active / sandbox active) — KHÔNG load thêm endpoint, compute từ data array"

patterns-established:
  - "Page admin per-row credential edit: Table inline + Drawer edit + Test Modal + Switch toggle — pattern reusable cho future credential pages (SmartCA per-user, OAuth providers...)"
  - "Test connection UX flow: open modal idle (Empty) → click 'Bắt đầu kiểm tra' → spinner → Alert result với gợi ý fix"

requirements-completed: [LGSP-UI-01, LGSP-UI-02, LGSP-UI-03, LGSP-UI-04]

# Metrics
duration: ~5 min
completed: 2026-05-21
---

# Phase 37 Plan 03: Frontend Admin Config Page /lgsp/cau-hinh Summary

**NEW page /lgsp/cau-hinh (735 lines) — Admin LGSP credential management: Table 12 row + Drawer edit + Test Connection Modal + Switch toggle inline — wire vào 4 endpoint admin từ Plan 37-01/02**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-05-21
- **Completed:** 2026-05-21
- **Tasks:** 2/2 (Task 2 verification-only, no commit)
- **Files created:** 1

## Accomplishments

- **NEW** `e_office_app_new/frontend/src/app/(main)/lgsp/cau-hinh/page.tsx` 735 dòng:
  - Admin role guard inline (useAuthStore — check `user?.isAdmin || roles.includes('Quản trị hệ thống')`) → non-admin nhận Alert warning "Không có quyền truy cập"
  - Header section: title "Cấu hình kết nối LGSP" với icon SettingOutlined + nút "Làm mới"
  - Alert info hướng dẫn Wave 1 sandbox → Wave 2 prod (link tài liệu `QLVBDNAgencies.xlsx` + `List.txt`)
  - 3 Stat cards KPI: "Đang kết nối X/N", "Production active", "Sandbox active" (compute từ data array, KHÔNG load thêm endpoint)
  - Table 12 row (6 DN × 2 env max): 7 column — Đơn vị (với badge Mã LGSP), Môi trường (Tag Production red / Sandbox orange), SystemId (monospace), Base URL (Tooltip + monospace), Trạng thái (Switch Bật/Tắt), Đồng bộ cuối (dayjs format + Tag "Lỗi gần nhất" nếu có), Hành động (Sửa + Kiểm tra)
  - Drawer 720 (AntD 6 `size={720}`, `rootClassName="drawer-gradient"`) "Sửa cấu hình — {DN} ({env})":
    - Row 2 col: Môi trường (Radio.Group disabled prefilled) + Mã LGSP (Input disabled prefilled)
    - SystemId (Input maxLength=13, required, max 13 rules)
    - Base URL (Input maxLength=500, required, pattern `^https?://`, max 500)
    - SecretKey (Input.Password autoComplete='new-password' maxLength=500, NO prefill, extra hint "Để trống nếu giữ secret_key hiện tại")
    - Alert warning "Sau khi lưu credential mới → bấm Kiểm tra kết nối"
    - Footer: Lưu (loading) + Hủy buttons
  - Modal "Kiểm tra kết nối — {DN} ({env})" (width=620):
    - Alert info "Backend gọi POST /v1/syncReceivedEdocList lightweight read-only"
    - Idle state: Empty với hint "Bấm 'Bắt đầu kiểm tra' để gọi LGSP"
    - Loading state: Spin lớn + "Đang kiểm tra kết nối tới LGSP..."
    - Success state: Alert success với count VB 24h + HTTP status
    - Error state: Alert error với HTTP status + danh sách gợi ý kiểm tra (SystemId/SecretKey, Base URL firewall, tài khoản LGSP hiệu lực)
    - Footer: Đóng + "Bắt đầu kiểm tra" (đổi thành "Kiểm tra lại" sau lần test đầu)
  - Switch toggle is_active inline → PATCH `/admin/lgsp-agency-config/:id/active` body `{is_active}` → toast success + refresh
- **4 endpoint integration:**
  - `GET /admin/lgsp-agency-config` (Plan 37-01) — load 12 row on mount + sau mỗi mutate
  - `PUT /admin/lgsp-agency-config/:id` (Plan 37-01) — save drawer, body `{systemId, baseUrl, secretKey?}` (chỉ truyền secretKey khi user nhập mới)
  - `PATCH /admin/lgsp-agency-config/:id/active` (Plan 37-01) — toggle Switch inline
  - `POST /admin/lgsp-agency-config/:id/test` (Plan 37-02) — test connection trong modal
- TypeScript strict: 0 NEW error (4 pre-existing Phase 33-05 errors filtered per CLAUDE.md scope boundary)
- Production build frontend: PASS (exit 0, route `/lgsp/cau-hinh` compiled static `○`)

## Task Commits

1. **Task 1: NEW page.tsx /lgsp/cau-hinh** — `6159877` (feat) — 735 lines, full implementation

Task 2 (Production build verify) — verification only, no code change → no commit.

## Files Created/Modified

- `e_office_app_new/frontend/src/app/(main)/lgsp/cau-hinh/page.tsx` **(NEW)** — 735 dòng, full self-contained page với Table + Drawer + Modal + Switch + 4 endpoint integration

## Decisions Made

1. **Admin role guard inline tại entry component** — render Alert warning "Không có quyền truy cập" thay vì redirect hoặc middleware. Lý do: UX thân thiện hơn (admin user vô tình mất role vẫn thấy page với lý do rõ ràng), code đơn giản hơn (KHÔNG cần wrap layout/route), vẫn enforce non-admin KHÔNG fetch data (useEffect skip khi `!isAdmin`).

2. **Switch toggle is_active KHÔNG dùng confirm modal** — admin có thể flip lại ngay nếu sai (idempotent action), modal confirm gây friction. Trade-off chấp nhận: admin click nhầm tắt 1 row → bật lại 1 click, không gây data loss.

3. **Input.Password KHÔNG prefill + extra hint 'Để trống nếu giữ secret_key hiện tại'** — UX rõ ràng tránh confusion "giá trị '***' có phải secret thật không?". Backend GET trả `secret_key_masked: '***'` chỉ để UI display Column nếu cần, KHÔNG prefill vào field edit. Mỗi lần edit, admin phải chủ động nhập mới hoặc để trống.

4. **Form payload secretKey chỉ truyền khi user nhập mới (trim != '')** — match backend Plan 37-01 logic: `secretKey` undefined hoặc empty string → backend giữ ciphertext cũ. Frontend chỉ include field này trong payload khi user thực sự nhập (tránh accidentally truyền empty string lên backend).

5. **Test modal button 'Kiểm tra lại' khi đã có result** — UX cho phép admin retest nhanh sau khi đã thấy kết quả (VD: thấy fail → đóng → sửa credential → mở lại → retest). KHÔNG cần đóng modal + mở lại.

6. **Stat cards compute từ data array (KHÔNG load thêm endpoint)** — 12 row đã load sẵn, count đang active là `data.filter().length` — không cần thêm `/lgsp-overview` (đã có cho Plan 37-04 trang khác). Trade-off OK: page này tập trung Table + edit, KHÔNG cần KPI dashboard riêng.

## Deviations from Plan

None — plan executed exactly as written.

Plan skeleton đã full implementation (~640 dòng skeleton + comments). File final 735 dòng vì:
- Comments header chi tiết hơn (Vietnamese descriptions)
- Vietnamese diacritics formatting với line break đúng JSX
- Type annotations explicit hơn (FormValues, TestResult, LgspConfigRow)
- Error handling typed unknown casting

## Issues Encountered

- **(None)** — backend endpoints (Plan 37-01/02) đã đầy đủ + tested. Pattern AntD 6 đã ổn định từ /ky-so/cau-hinh (1291 lines analog). Implementation thẳng theo skeleton plan.

## Acceptance Criteria — All PASS

| Check | Result |
|---|---|
| File exists | ✓ `e_office_app_new/frontend/src/app/(main)/lgsp/cau-hinh/page.tsx` |
| File length ≥ 350 lines | ✓ 735 lines |
| Grep `Cấu hình kết nối LGSP` | ✓ 4 matches (header + alerts) |
| Grep `Kiểm tra kết nối\|Kết nối thành công\|Kết nối thất bại` | ✓ 4 + 1 + 1 matches |
| Grep `admin/lgsp-agency-config` | ✓ 9 matches (GET + PUT + PATCH + POST in 4 endpoints) |
| Grep `/test` | ✓ 2 matches |
| Grep `/active` | ✓ 2 matches |
| Grep `size={720}` | ✓ 1 match (Drawer AntD 6) |
| Grep `Input.Password` | ✓ 1 match (secret_key field) |
| Grep `autoComplete="new-password"` | ✓ 1 match |
| `npx tsc --noEmit` 0 NEW error in this file | ✓ 0 matches for `lgsp/cau-hinh` in TS output |
| `npm run build` exit 0 | ✓ PASS + `/lgsp/cau-hinh` route compiled `○` static |
| Build manifest `.next/build-manifest.json` exists | ✓ |

## User Setup Required

None — page sẵn sàng.

Manual visual test (defer Plan 37-07 E2E full):
1. Backend running dev + admin login
2. Tạm sửa `hidden-routes.ts` xóa `/lgsp/cau-hinh` (hoặc gõ URL trực tiếp `http://localhost:3000/lgsp/cau-hinh`)
3. Verify Table load 12 row (sau khi DB seed có lgsp_agency_config rows)
4. Click "Sửa" row → Drawer mở với form prefilled (env + Mã LGSP read-only; system_id + base_url editable; secret_key trống)
5. Nhập secret_key thật từ tài liệu KH → Lưu → toast "Đã cập nhật cấu hình LGSP"
6. Click "Kiểm tra" → Modal mở → "Bắt đầu kiểm tra" → spinner → Alert success/error
7. Toggle Switch is_active → toast "Đã bật/tắt kết nối LGSP" → table refresh

## Next Phase Readiness

- **Plan 37-04 (frontend overview dashboard `/lgsp`)** unblocked — pattern admin guard từ page này có thể reuse
- **Plan 37-05 (frontend catalog `/lgsp/co-quan`)** unblocked — pattern CRUD Drawer reuse được
- **Plan 37-06 (frontend menu unhide + retry button)** unblocked — page mới này sẽ được thêm vào sidebar group "TÍCH HỢP" admin only entry `/lgsp/cau-hinh`

## Known Stubs

None — page là production-ready, KHÔNG có placeholder/TODO/mock data. Tất cả data flow từ backend real endpoints.

## Threat Flags

None — page admin-only đã có role guard inline (`isAdmin || roles.includes('Quản trị hệ thống')`), backend mount tại `/api/admin/*` đã wrap `authenticate + requireRoles('Quản trị hệ thống')` (Plan 37-01 mount), secret_key plaintext chỉ tồn tại trên wire HTTPS (browser → backend) — backend encrypt qua `pgp_sym_encrypt` ngay trước khi lưu DB. Không có surface mới tại trust boundary.

## Self-Check: PASSED

**Files created/modified verified:**
- FOUND: e_office_app_new/frontend/src/app/(main)/lgsp/cau-hinh/page.tsx (735 lines)

**Commits verified:**
- FOUND: 6159877 (Task 1 — NEW page.tsx)

**Acceptance criteria check:** All 13 criteria PASS (see table above)

---
*Phase: 37-admin-ui-catalog-go-live*
*Completed: 2026-05-21*
