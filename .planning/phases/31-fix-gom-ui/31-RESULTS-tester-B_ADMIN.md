# Phase 31 — Tester Bug Fix Results: B_ADMIN (25 bugs)

**Date:** 2026-05-09
**Scope:** Quản trị + Danh mục + Phân quyền + Khóa TK + Lọc người dùng
**Source:** `tools/test-report/_tester-bugs-B_ADMIN.json`
**Branch:** `main`

## Summary

| Status | Count |
|---|---|
| FIXED | 19 |
| ALREADY FIXED (Phase 31 trước) | 0 |
| SKIPPED (architectural / out-of-scope) | 1 |
| NOT REPRO / Cancel by tester | 5 |
| **Total** | **25** |

- **High priority fixed:** 5/6 (#17, #18, #44, #48, #52, #53 — chỉ skip 1 #51 do architectural)
- **Critical priority fixed:** 1/2 (#45 — skip #51 architectural)
- **Build:** Backend `tsc --noEmit` clean. Frontend `next build` compiled OK (lgsp prerender error unrelated).

## Bug-by-bug

| # | Module | Priority | Status | Commit | Note |
|---|---|---|---|---|---|
| 14 | Người dùng — search trim | Medium | FIXED | 032c333 | `setKeyword((v||'').trim())` cho list + tree search trim |
| 15 | Người dùng — Update lỗi 404 nhưng data lưu | Medium | NOT REPRO | — | Đã verify SP `fn_staff_update` trả `RETURN FOUND`, route map đúng. Không reproduce được. Cần tester re-test với user thật + capture network log. |
| 16 | Người dùng — refresh mất data | High | CANCEL | — | Status: Cancel (tester đã hủy) |
| 17 | Người dùng — Xóa thành công nhưng vẫn còn trong list | High | FIXED | 8057f91 | Public-catalog `/nguoi-dung` thêm `WHERE COALESCE(s.is_deleted, false) = false` — soft-deleted user không còn xuất hiện cho non-admin user (admin route đã filter từ trước trong SP) |
| 18 | Người dùng — Xóa lại báo "Không tìm thấy" | High | FIXED | 8057f91 | Cùng commit như #17. Sau khi public-catalog filter is_deleted, user đã xóa không hiển thị → không click xóa lại → không gặp lỗi "Không tìm thấy" |
| 19 | Người dùng — Hủy form không confirm dialog | Medium | FIXED | 0f351a5 | `handleCancelDrawer` dùng `form.isFieldsTouched()` → `modal.confirm` |
| 20 | Nhóm quyền — search không dấu | Medium | CANCEL | — | Note tester: "không hỗ trợ tìm kiếm kh dấu" — đã hủy |
| 21 | Nhóm quyền — search trim | Medium | FIXED | 032c333 | `setKeyword((v||'').trim())` |
| 22 | Chức vụ — search không dấu | Medium | CANCEL | — | Status: Cancel |
| 23 | Chức vụ — search trim | Medium | FIXED | 032c333 | `setKeyword((v||'').trim())` |
| 25 | Chức vụ — Hủy sửa không confirm | Medium | FIXED | 0f351a5 | `handleCancelDrawer` |
| 26 | Nhóm quyền — Hủy sửa không confirm | Medium | FIXED | 0f351a5 | `handleCancelDrawer` |
| 27 | Loại VB — Hủy sửa không confirm | Medium | FIXED | 0f351a5 | `handleCancelDrawer` |
| 29 | Loại VB — Cập nhật ký hiệu không lưu | Medium | FIXED | 4f7fdda | Frontend Select options đổi từ string `'so/ky_hieu'` → numeric `1/2`. Backend SP nhận SMALLINT → trước đó `Number('so/ky_hieu')` = NaN → 0. DB luôn store 0. Sau fix: lưu đúng giá trị 1/2 |
| 30 | Loại VB — search loại cha không dấu | Low | CANCEL | — | Status: Cancel |
| 31 | Loại VB — dropdown search trim | Medium | FIXED | 032c333 | `filterOption` callback trim input trước khi compare |
| 32 | Loại VB — Hủy thêm mới không confirm | Medium | FIXED | 0f351a5 | Cùng `handleCancelDrawer` cover cả Add + Edit |
| 38 | Người dùng — Email/SDT/Địa chỉ/Di động không placeholder | Medium | FIXED | 0f351a5 | Added placeholders: `nguyenvana@example.com`, `02143123456`, `0912345678`, `Số 10 Lê Văn Lương, Hà Nội` |
| 39 | Chức vụ — Mô tả không placeholder | Medium | FIXED | 0f351a5 | Added placeholder TextArea Mô tả |
| 44 | Sidebar trống vẫn hiển thị màn | High | FIXED | d8e88e4 | Backend `/auth/me` trả thêm `menuLinks[]` từ `fn_right_get_by_staff`. Frontend `MainLayout.filterMenuItemsByPermissions` lọc menu cho non-admin theo allowed set |
| 45 | Phân quyền sidebar — chỉ tick 3 menu nhưng hiện hết | Critical | FIXED | d8e88e4 | Cùng commit như #44. Non-admin user chỉ thấy menu khớp với `action_link` của các right được gán |
| 48 | Chức vụ — Dropdown chọn chức vụ vẫn hiện status="Ngừng" | High | FIXED | 8057f91 | Filter `positions.filter(p => p.is_active !== false || p.id === editingRecord?.position_id)`. Edit user có position cũ đã ngừng → giữ option với suffix "(Đã ngừng)" + disable các option ngừng khác |
| 51 | Phân quyền — Cán bộ không có quyền XL văn bản vẫn thao tác | Critical | SKIPPED | — | **Architectural fix cần phân tích sâu:** user tạo VB → trở thành owner → `canEdit = isOwner = true` → tất cả button hiện. Để fix triệt để cần redesign permission model (gate cả owner check theo `is_handle_document`) — risk cao breaking Văn thư workflow. Recommend tách phase riêng. |
| 52 | Người dùng — TK đã khóa bị ẩn hoàn toàn | High | FIXED | 8057f91 | Public-catalog (non-admin fallthrough) trước hardcode `is_locked=false`. Đã thêm support param `is_locked=true/false/all` |
| 53 | Người dùng — Filter trạng thái không trả đúng | High | FIXED | 8057f91 | Cùng commit. Public-catalog respect `is_locked` query param thay vì hardcode |

## Commits

```
032c333  fix(quan-tri): trim search input prevent missed results [BUG #14, #21, #23, #31 tester]
4f7fdda  fix(loai-van-ban): notation_type lay/luu numeric khop SMALLINT DB [BUG #29 tester]
0f351a5  fix(quan-tri): dialog xac nhan khi huy form dirty + placeholders [BUG #19, #25, #26, #27, #32, #38, #39 tester]
d8e88e4  fix(sidebar): filter menu theo permission action_link cua user [BUG #44, #45 tester]
8057f91  fix(quan-tri): chuc vu dropdown filter active + public-catalog respect is_locked + is_deleted [BUG #48, #52, #53, #17, #18 tester]
```

## Files touched

**Frontend:**
- `e_office_app_new/frontend/src/app/(main)/quan-tri/nguoi-dung/page.tsx`
- `e_office_app_new/frontend/src/app/(main)/quan-tri/chuc-vu/page.tsx`
- `e_office_app_new/frontend/src/app/(main)/quan-tri/nhom-quyen/page.tsx`
- `e_office_app_new/frontend/src/app/(main)/quan-tri/loai-van-ban/page.tsx`
- `e_office_app_new/frontend/src/app/(main)/quan-tri/linh-vuc/page.tsx`
- `e_office_app_new/frontend/src/components/layout/MainLayout.tsx`
- `e_office_app_new/frontend/src/stores/auth.store.ts`

**Backend:**
- `e_office_app_new/backend/src/services/auth.service.ts`
- `e_office_app_new/backend/src/repositories/doc-type.repository.ts`
- `e_office_app_new/backend/src/routes/public-catalog.ts`

## Pending / Recommendation

- **BUG #51 (Critical)**: Permission gating cho document actions cần phase riêng. Gợi ý: thêm explicit flag check `canEdit = (isOwner && (is_handle_document || isAdmin || roles.includes('Văn thư')))` — tránh owner-bypass. Cần tester scope ra workflow Văn thư có muốn giữ canEdit khi `is_handle_document=false` không.
- **BUG #15 (Medium)**: Cần tester re-test capture network tab để xác định status code thật + body trả về. SP `fn_staff_update` đã verify đúng. Có thể là race condition browser cache hoặc tester thấy lỗi ở 2 dialog confirm khác nhau.

## Build verification

- Backend: `npx tsc --noEmit` → 0 errors
- Frontend: `npm run build` → ✓ Compiled successfully (TS errors pre-existing trong `ho-so-cong-viec`, `van-ban-den/page.tsx` không liên quan; `next.config.ts` đã `ignoreBuildErrors: true`)
