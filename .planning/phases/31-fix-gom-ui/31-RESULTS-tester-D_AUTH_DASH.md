# Phase 31 — Tester D_AUTH_DASH (Đăng nhập / Thông tin TK / Dashboard) Results

Tester: yến (bugs) + Nhung (improvements)
Date applied: 2026-05-09
Branch: main

## Tóm tắt

- 4 / 4 bugs fixed
- 4 / 4 improvements applied
- Files touched: ~38 (35 cho IMP #4 batch + 3 file riêng)
- Backend: thêm 1 endpoint `PATCH /api/ho-so-ca-nhan/thong-tin` cho BUG #13

## Bugs

| # | Bug (tóm tắt) | Module | Priority | Fix | File(s) |
|---|---|---|---|---|---|
| 2 | Thẻ "Việc quá hạn" + "VB đi chờ duyệt" trên Dashboard không thẳng hàng / cao đều | Dashboard | Medium | CSS `.stat-card` `height: 100%; min-height: 92px; flex-direction: column;` + Card `width: 100%` + `Col style={display:'flex'}` để các thẻ đồng đều mọi breakpoint | `app/globals.css`, `app/(main)/dashboard/page.tsx` |
| 7 | Đăng nhập sai lần 1 hiện thông báo, lần 2-3 không hiện | Đăng nhập | Medium | `message.destroy()` trước mỗi lần submit; dùng `key: 'login-status'` để force re-render toast (tránh AntD dedupe khi cùng content) | `app/(auth)/login/page.tsx` |
| 12 | Đổi mật khẩu thành công không tự logout | Thông tin TK | Medium | `Modal.success` → onOk gọi `logout()` + redirect `/login` (backend đã clear refresh cookie + revoke tokens) | `app/(main)/thong-tin-ca-nhan/page.tsx` |
| 13 | Không có chức năng sửa thông tin cá nhân | Thông tin TK | Medium | Thêm nút **Sửa thông tin** + Modal form (Họ / Tên / Email / SĐT) với validation; backend `PATCH /api/ho-so-ca-nhan/thong-tin` dùng `staffRepository.update()` (giữ nguyên field nhạy cảm department/unit/position/admin) | `routes/profile.ts` (BE), `app/(main)/thong-tin-ca-nhan/page.tsx` (FE) |

## Improvements

| # | Đề xuất | Module | Áp dụng | File(s) |
|---|---|---|---|---|
| 1 | HSCV — Sửa/Xóa chỉ hiện ở trạng thái "Mới tạo" | Hồ sơ công việc | **Đã có sẵn**: list page dùng `const isEditable = record.status === 0;` để filter dropdown items; detail page dùng `getToolbarButtons(status)` chỉ trả "Sửa" / "Xóa" cho status=0 | `app/(main)/ho-so-cong-viec/page.tsx`, `app/(main)/ho-so-cong-viec/[id]/page.tsx` (verify only) |
| 2 | Xuất Excel — danh sách rỗng → toast "Không có dữ liệu để xuất", KHÔNG xuất file | VB đến / VB đi / VB dự thảo / Báo cáo HSCV | Thêm guard `if (!data || data.length === 0)` ở đầu mỗi `handleExportExcel` / `exportExcel`; HSCV list đã có sẵn check `exportRows.length === 0` | `van-ban-den/page.tsx`, `van-ban-di/page.tsx`, `van-ban-du-thao/page.tsx`, `ho-so-cong-viec/bao-cao/page.tsx` |
| 3 | Modal "Gửi văn bản" — disable cán bộ đã được gửi + tooltip "Đã gửi" | VB đến / VB dự thảo (detail) | Fetch song song `/danh-sach-gui` + `/nguoi-nhan` khi mở modal → tính `alreadySentIds: Set<number>`; Checkbox `checked` (force tick) + `disabled` cho cán bộ đã gửi, bao bọc Tooltip; "Chọn tất cả" chỉ áp dụng cho danh sách CHƯA gửi | `app/(main)/van-ban-den/[id]/page.tsx`, `app/(main)/van-ban-du-thao/[id]/page.tsx` |
| 4 | Modal/Drawer Thêm/Sửa — cố định, không đóng khi click ngoài | Tất cả các màn | Batch patch script (`tools/test-report/_imp4_patch.cjs`, đã xóa sau khi chạy) thêm `maskClosable={false}` vào **67 instances** `<Modal>` + `<Drawer>` thuộc **35 files** (toàn bộ trang admin + nghiệp vụ + chi tiết) | 35 page.tsx files (xem section "Files" bên dưới) |

## Files (IMP #4 — 35 files batch patched)

`quan-tri/{nguoi-dung, loai-van-ban, nhom-quyen, chuc-vu, linh-vuc, nguoi-ky, uy-quyen, so-van-ban, quy-trinh, nhom-lam-viec, mau-thong-bao, don-vi, dia-ban, cau-hinh, cau-hinh-truong}`, `van-ban-den/{page, [id]/page}`, `van-ban-di/{page, [id]/page}`, `van-ban-du-thao/{page, [id]/page}`, `ho-so-cong-viec/{page, [id]/page}`, `thong-tin-ca-nhan`, `thong-bao`, `tin-nhan`, `kho-luu-tru/{page, muon-tra/page}`, `ky-so/cau-hinh`, `lich/{ca-nhan, lanh-dao, co-quan}`, `cuoc-hop/{page, [id]/page}`, `hop-dong`, `tai-lieu`.

## Backend changes

- **`backend/src/routes/profile.ts`** — added `PATCH /thong-tin` route cho BUG #13. Validate input (first/last name not empty, email format, phone pattern, max length); load current via `staffRepository.getById()` để giữ field nhạy cảm; call `staffRepository.update()` với `updated_by = self`. KHÔNG sửa SP.

## Notes / By-product fixes

- **Pre-existing TS bug fixed**: `ho-so-cong-viec/[id]/page.tsx` Modal "Thêm văn bản liên kết" dùng `size={800}` (không hợp lệ trên `<Modal>` AntD 6) → đổi thành `width={800}`.
- **Pre-existing TS errors KHÔNG được fix** (nằm ngoài scope D_AUTH_DASH): 4× `TreeNode` type mismatch ở `ho-so-cong-viec/page.tsx`, `van-ban-{den,di,du-thao}/page.tsx` (đã tồn tại trên main HEAD trước khi tôi bắt đầu).

## Verification

- `npx tsc --noEmit` (backend): zero errors.
- `npx tsc --noEmit` (frontend): chỉ 4 errors **PRE-EXISTING** (xác nhận bằng `git stash` + recheck).
- Production build deferred — Next.js dev server đang chạy giữ lock `.next/server/app`. Dev server hot-reload đã pick up tất cả thay đổi.

## Commit

`fix(auth-dash): D_AUTH_DASH bugs #2 #7 #12 #13 + UX improvements #1 #2 #3 #4 [tester]`
