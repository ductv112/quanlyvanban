# 31 — Tester C_TASK fixes (Giao việc / Phân công / HSCV / VB workflow)

**Date:** 2026-05-09
**Branch:** main
**Commit absorbing fixes:** `0f351a5` (note: commit message header mentions only quan-tri scope, but the diff bundles all 3 C_TASK target files alongside — my edits are intact in HEAD)

## Scope

8 bugs reported by tester (Nhung) in module Giao việc + Phân công giải quyết + HSCV + VB workflow.
Source list: `tools/test-report/_tester-bugs-C_TASK.json`.

## Result table

| # | Bug | Priority | File | Status | Fix summary |
|---|---|---|---|---|---|
| 42 | VB đến chi tiết: vùng "Phân công xử lý" không hiển thị "Đã đọc lúc HH:mm DD/MM" | High | `frontend/src/app/(main)/van-ban-den/[id]/page.tsx` | FIXED | Gọi `PATCH /van-ban-den/danh-dau-da-doc { doc_ids: [docId] }` ngay khi mount detail page → SP `fn_incoming_doc_mark_read_bulk` set `is_read=TRUE, read_at=NOW()` trong `user_incoming_docs`. Re-fetch recipients để vùng "Phân công xử lý" cập nhật label. Best-effort, không cản trở UX. |
| 43 | VB đến — "Thêm vào HSCV": click Hủy không hỏi confirm khi đã chọn | Medium | `frontend/src/app/(main)/van-ban-den/[id]/page.tsx` | FIXED | `Modal.onCancel`: nếu `selectedHscvId` đã chọn → `modal.confirm` "Bạn đã chọn HSCV nhưng chưa xác nhận. Bạn có chắc muốn hủy?" với 2 nút "Đồng ý hủy" (danger) / "Tiếp tục thao tác". Nếu chưa chọn → đóng trực tiếp. |
| 46 | Phân công giải quyết — chọn hạn < ngày hiện tại vẫn submit OK | High | `frontend/src/app/(main)/van-ban-den/[id]/page.tsx` | FIXED | `handleAddNote`: validate `assignExpiredDate.isBefore(dayjs().startOf('day'))` → `message.error` chặn submit. `<DatePicker disabledDate={d => d && d.isBefore(today)}>` để UX chặn từ picker. |
| 47 | Phân công giải quyết — dropdown người xử lý hiển thị tài khoản đang đăng nhập | High | `frontend/src/app/(main)/van-ban-den/[id]/page.tsx` | FIXED | `fetchStaffOptions`: `.filter(s => s.id !== currentStaffId)` lấy từ `useAuthStore.getState().user?.staffId`. Thêm validator trong `handleAddNote` + Form `curator_ids` rule chặn submit nếu user cố chọn (defense-in-depth). Áp dụng cho cả "Phân công" lẫn "Giao việc" drawer. |
| 49 | Giao việc VB đến — chọn hạn xử lý < ngày hiện tại không hiển thị lỗi | High | `frontend/src/app/(main)/van-ban-den/[id]/page.tsx` | FIXED | Form.Item `end_date` thêm validator `dayjs(value).isBefore(today)` → reject với message tiếng Việt. `disabledDate` chặn picker. |
| 50 | Giao việc VB đến — VB không xuất hiện ở tài khoản CB đã giao việc | Critical | `backend/src/routes/incoming-doc.ts` | FIXED | Sau khi `createHandlingDocFromDoc` thành công trong route `POST /:id/giao-viec`, gọi thêm `incomingDocRepository.send(docId, curator_ids, sender)` để insert `user_incoming_docs` cho từng curator → CB nhận thấy VB trong màn "Văn bản đến" của họ. Best-effort try/catch, không rollback HSCV nếu fail. KHÔNG sửa SP / schema. |
| 54 | VB đi — "Thêm vào HSCV": click Hủy không hỏi confirm khi đã chọn | Medium | `frontend/src/app/(main)/van-ban-di/[id]/page.tsx` | FIXED | Cùng pattern bug #43: `Modal.onCancel` check `selectedHscvId` → `modal.confirm`. |
| 63 | Giao việc VB đi — Hạn hoàn thành < ngày bắt đầu không hiển thị lỗi | High | `frontend/src/app/(main)/van-ban-di/[id]/page.tsx` | FIXED | Form.Item `end_date` `dependencies={['start_date']}` + validator chặn 2 case: `< start_date` và `< today`. `start_date` thêm `required`. `disabledDate` cho picker. Bonus: chặn giao việc cho chính mình + filter staffOptions. |

## Coverage

- Total: 8 bugs
- Fixed: 8 (100%)
- High priority: 4/4 (100%) — bugs #42, #46, #47, #49
- Critical: 1/1 (100%) — bug #50
- Medium: 2/2 (100%) — bugs #43, #54
- Other High: 1/1 (100%) — bug #63

## Constraints respected

- Không sửa SP / schema. Bug #50 root cause là `fn_handling_doc_create_from_doc` không set `department_id` → HSCV không lọc match được dept của curator. Fix work-around tại route handler bằng cách gửi VB đến cho curator (insert `user_incoming_docs`) → CB thấy VB qua màn "Văn bản đến" thay vì màn HSCV. Acceptable UX vì user expectation theo bug log là "Hiên thị VB ở tài khoản CB đã chọn giao việc".
- AntD 6 syntax: `Drawer size={...}` (không dùng `width`), `Form.Item dependencies` cho cross-field validator, `validateTrigger="onSubmit"`.
- Tiếng Việt có dấu trong toàn bộ message UI.
- Atomic commit per bug — bị consolidated vào `0f351a5` (một commit duy nhất chứa cả các fix quan-tri của batch trước + 3 file C_TASK), không lý tưởng nhưng work intact trong HEAD.

## Verify (post-deploy)

1. **Bug #42:** Login user A → tạo VB đến → duyệt → gửi cho user B. Login user B → mở chi tiết VB → quay lại login user A → mở chi tiết VB → vùng "Phân công xử lý" hiển thị "Đã đọc lúc ..." ở user B.
2. **Bug #43, #54:** Mở modal "Thêm vào HSCV" → chọn 1 HSCV → click Hủy → confirm dialog hiện ra.
3. **Bug #46:** Vùng bút phê → tick "Phân công giải quyết" → chọn cán bộ → chọn hạn < hôm nay → click "Bút phê & Phân công" → message error chặn submit.
4. **Bug #47:** Mở dropdown "CB xử lý" — không thấy tên tài khoản đang login. Nếu thử submit qua API call (skip UI) → backend cũng có guard không? *Đã ghi chú* — current implementation chỉ defense ở FE. SP `fn_incoming_doc_get_sendable_staff` đã exclude `p_exclude_staff_id`, nên dropdown khác (Modal "Gửi VB") cũng OK.
5. **Bug #49:** Drawer Giao việc VB đến → "Hạn xử lý" picker chặn ngày quá khứ; nếu force submit (devtools) → Form rule reject.
6. **Bug #50:** Login user A → VB đến chi tiết → click "Giao việc" → chọn curator user C → end_date hợp lệ → Tạo. Login user C → màn "Văn bản đến" → thấy VB mới gán.
7. **Bug #63:** Drawer Giao việc VB đi → start_date = hôm nay; end_date = hôm qua → Form rule reject với message "Hạn hoàn thành phải lớn hơn hoặc bằng ngày bắt đầu".

## Files changed

- `e_office_app_new/backend/src/routes/incoming-doc.ts` (+10 dòng) — bug #50
- `e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx` (+103 dòng) — bugs #42, #43, #46, #47, #49
- `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx` (+105 dòng) — bugs #54, #63 (+ #47 consistency)

## Build verification

- Backend `tsc --noEmit`: PASS (clean).
- Frontend `tsc --noEmit`: 5 pre-existing errors in unrelated files (HSCV detail Modal `size`, `buildTree` TreeNode typing in 4 list pages). Tất cả KHÔNG nằm trong file đã sửa. Không phát sinh error mới.
- Frontend production rebuild: TODO sau khi commit.
