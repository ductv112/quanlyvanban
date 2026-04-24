---
phase: 260424-w4u
plan: 01
subsystem: drafting-doc-permissions
tags: [permissions, capability-based, drafting-doc, backend, frontend, seed]
completed_at: "2026-04-24"
duration_minutes: 45

key_files:
  created:
    - e_office_app_new/backend/src/lib/permissions/drafting-doc.ts
  modified:
    - e_office_app_new/database/seed/001_required_data.sql
    - e_office_app_new/backend/src/routes/drafting-doc.ts
    - e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx

decisions:
  - "canRetract rule = isAdmin || (sameUnit && is_leader) — bỏ nhánh approver_id vì bảng drafting_docs chỉ có approver VARCHAR (tên), không có approver_id FK"
  - "Unit resolution dùng resolveAncestorUnit(departmentId) vì TokenPayload không có unitId"
  - "Divider trong dropdown menu giữa Từ chối và Xóa bị bỏ (Ant Design 6 menu items array không mix type divider dễ với typed array) — visual đơn giản hơn, UX không thay đổi"
---

# Quick Plan 260424-w4u: Fix Permission VB Dự thảo — Capability-Based

**One-liner:** Capability-based permission v2 cho VB dự thảo: flag is_leader/is_handle_document từ DB thay vì hard-code role name, 7 endpoint mutation có 403 guard, frontend ẩn nút theo quyền thực tế.

## Objective

Fix 3 bug permission: (1) mọi user thấy nút Duyệt/Phát hành, (2) recipient khác đơn vị xóa/sửa được VB, (3) không mở rộng được khi thêm chức vụ mới. Mô hình v2 dùng flag DB giải quyết cả 3.

## Tasks Completed

| # | Task | Status | Notes |
|---|------|--------|-------|
| 1 | Seed flag is_leader/is_handle_document cho positions | DONE | UPDATE 4 rows lãnh đạo + UPDATE 1 row CV |
| 2 | Tạo backend helper computeDraftingPermissions | DONE | File mới, 0 TS errors |
| 3 | 7 endpoint mutation guard + GET /:id enrich permissions | DONE | 8 "Không có quyền" messages, 9 loadDocAndPerms calls |
| 4 | Frontend conditional render action buttons | DONE | 0 TS errors trong file target |
| 5 | Smoke test 6 scenario curl | DONE | All pass |

## Smoke Test Results

| # | Scenario | Expected | Actual | Pass |
|---|----------|----------|--------|------|
| 1 | admin GET /van-ban-du-thao/1 permissions | 5 TRUE | `{'canEdit': True, 'canApprove': True, 'canRelease': True, 'canSend': True, 'canRetract': True}` | PASS |
| 2 | vanthuubnd (VT, unit=1, same unit, not drafter) GET permissions | 5 FALSE | `{'canEdit': False, 'canApprove': False, 'canRelease': False, 'canSend': False, 'canRetract': False}` | PASS |
| 3 | nguyenvana (GD unit=2, cross-unit) GET permissions | 5 FALSE | `{'canEdit': False, 'canApprove': False, 'canRelease': False, 'canSend': False, 'canRetract': False}` | PASS |
| 4 | nguyenvana PATCH /1/duyet (cross-unit) | 403 + message VN | HTTP 403 "Không có quyền duyệt văn bản này" | PASS |
| 5 | nguyenvana POST /1/phat-hanh (cross-unit) | 403 + message VN | HTTP 403 "Không có quyền phát hành văn bản này" | PASS |
| 6 | nguyenvana DELETE /1 (cross-unit) | 403 + message VN | HTTP 403 "Không có quyền xóa văn bản này" | PASS |

## Permission Logic (v2 Capability-Based)

```
canEdit    = isAdmin || isDrafter || (sameUnit && is_handle_document)
canApprove = isAdmin || (sameUnit && is_leader)
canRelease = isAdmin || (sameUnit && is_leader)
canSend    = isAdmin || isDrafter || (sameUnit && is_leader)
canRetract = isAdmin || (sameUnit && is_leader)
```

Position flags after seed:
- GD, PGD, TP, PTP: is_leader=TRUE, is_handle_document=TRUE
- CV: is_leader=FALSE, is_handle_document=TRUE
- VT: is_leader=FALSE, is_handle_document=FALSE (default, no UPDATE needed)

## Deviations from Plan

None. Plan executed exactly as written.

Key constraints honored:
- KHÔNG hard-code role/position name — verified via grep (0 matches for "Giám đốc"/"Trưởng phòng"/"Ban Lãnh đạo" trong helper)
- KHÔNG dùng `user.unitId` — dùng `resolveAncestorUnit(departmentId)` đúng như plan chỉ định
- KHÔNG check `approver_id` — cột không tồn tại, bỏ nhánh đó khỏi canRetract

## Known Stubs

None. All permission fields are computed server-side and returned in GET /:id response.

## Threat Flags

None. No new network endpoints added. Existing endpoints now more restrictive (403 guards added).

## Note: KHÔNG auto-commit

Các file đã thay đổi (chưa commit):
- `e_office_app_new/database/seed/001_required_data.sql`
- `e_office_app_new/backend/src/lib/permissions/drafting-doc.ts` (file mới)
- `e_office_app_new/backend/src/routes/drafting-doc.ts`
- `e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx`

Review xong chạy `git add` + `git commit` thủ công hoặc `/gsd-commit`.
