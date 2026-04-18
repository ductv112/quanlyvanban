# Quick Task 260418-jsd: Fix 6 gap HDSD — Summary

**Executed:** 2026-04-18
**Status:** ✅ Complete — 7/7 tasks, 32/32 verify checks pass, 8 flows cần human UAT

## Commits (on `main`)

| Hash | Task | Gap | Description |
|---|---|---|---|
| `a11f075` | 1 | A (TC-011) | feat: thêm UI ký số VB đi/dự thảo với mock OTP — HDSD I.5 |
| `bae9528` | 2 | B (TC-045) | feat: thêm chức năng gửi trục CP (mock) cho VB đi — HDSD II.3.8 |
| `75a6783` | 3 | C (TC-046) | feat: mở rộng form chuyển lưu trữ VB đi với phòng/kho — HDSD II.3.9 |
| `77a456b` | 4 | D (TC-066) | feat: thêm endpoint + button hủy HSCV riêng — HDSD III.2.5 |
| `e2b4e0c` | 5 | E (TC-067) | feat: thêm chức năng chuyển tiếp ý kiến HSCV — HDSD III.2.6 |
| `80f2ba7` | 6 | F (TC-068) | feat: thêm chức năng chuyển tiếp HSCV cho người khác — HDSD III.2.7 |
| `26caf2b` | 7 | — | docs: regenerate test catalog sau fix 6 gap HDSD |

## Coverage impact

**Trước:** 83 ✅ / 5 ⚠️ / 3 ❌ / 1 🚫 = **90.2%**
**Sau:** 90 ✅ / 0 ⚠️ / 1 ❌ / 1 🚫 = **97.8%**

Còn lại:
- **TC-079 (❌)** Giới hạn quyền đơn vị — defer Phase 2 (cần schema permission model mới)
- **TC-069 (🚫)** Cấu hình gửi nhanh — Hidden by Phase 1 design (Phase 2 unhide)

## Locked decisions (B1–B7)

- **B1** Mock OTP: `<Input.OTP length={6}>` + TODO VNPT SDK Phase 2
- **B2** Trục CP: `lgsp_tracking.channel VARCHAR(20) CHECK IN ('lgsp','cp')`, 8 bộ hardcode FE
- **B3** Chuyển lưu trữ VB đi: mirror 13 field pattern VB đến, tạo 2 endpoint mới `/van-ban-di/:id/luu-tru/{phong,kho}`
- **B4** Hủy HSCV: chỉ status=1; `fn_handling_doc_get_by_id` mở rộng 33→36 fields (+cancel_*)
- **B5** Chuyển tiếp ý kiến: `parent_opinion_id` self-FK + thread indent
- **B6** Chuyển tiếp HSCV: same-unit only (cross-unit defer Phase 2), table `handling_doc_history` mới
- **B7** Task 7 regen test catalog: tự động sau Task 1-6 commit

## DB changes

**5 migrations áp dụng:**
- `quick_260418_jsd_sign_otp.sql` — DROP/CREATE 2 SP attachment list (12 fields)
- `quick_260418_jsd_truc_cp.sql` — ALTER lgsp_tracking + DROP/CREATE fn_lgsp_tracking_create
- `quick_260418_jsd_hscv_cancel.sql` — ALTER handling_docs +3 cancel cols + SP cancel + DROP/CREATE get_by_id (36 fields)
- `quick_260418_jsd_opinion_forward.sql` — ALTER opinion_handling_docs +4 forward cols + SP forward + DROP/CREATE get_list
- `quick_260418_jsd_hscv_transfer.sql` — TABLE handling_doc_history + SP transfer + SP history_list

## Verification — [VERIFICATION.md](./260418-jsd-VERIFICATION.md)

**Code-level: 32/32 PASSED** ✅

8 flows cần human UAT browser trước demo:

1. Modal OTP Input.OTP rendering + animation
2. Preview chữ ký sau ký thành công
3. Thread indent khi chuyển tiếp ý kiến (parent-child visual)
4. Status transition HSCV từ 1→-3 (Hủy)
5. Transfer HSCV same-unit validation (staff picker filter)
6. Backward-compat LGSP (sendLgsp default 'lgsp')
7. Drawer chuyển lưu trữ VB đi — 13 field render đúng
8. Modal chọn bộ/ngành CP hardcode (8 bộ)

## Deviations handled

1. **TokenPayload thiếu `unitId`** → dùng `resolveAncestorUnit(departmentId)` (pattern có sẵn)
2. **FE staffOptions collision** → rename `forwardStaffOptions` tránh trùng state
3. **Worktree base mismatch** → soft reset + checkout HEAD để khôi phục files
4. **Worktree thiếu node_modules** → junction link sang main repo

## Files modified

- 5 migrations (new)
- 3 backend repos (`outgoing-doc`, `drafting-doc`, `handling-doc`, `incoming-doc`)
- 3 backend routes (`outgoing-doc`, `handling-doc`)
- 3 frontend pages (`van-ban-di/[id]`, `van-ban-du-thao/[id]`, `ho-so-cong-viec/[id]`)
- 1 script (`gen-test-catalog.cjs`)
- 2 docs (`test_theo_hdsd_cu.md`, `.xlsx`)

**Total:** 1417 insertions / 28 deletions across 16 files

## Next steps

1. Test 8 flows browser theo danh sách UAT
2. Fill cột "UAT thực tế" trong `docs/test_theo_hdsd_cu.xlsx`
3. Push main lên origin khi đã test OK
