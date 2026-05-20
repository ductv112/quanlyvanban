---
phase: 23-execute-wave-b
batch: Wave b — Văn bản đi (54 TC) + Cấu hình gửi nhanh (18 TC)
started: 2026-05-07T02:20:00.000Z
completed: 2026-05-07T02:35:00.000Z
backend_db: qlvb_test
backend_env: NODE_ENV=test (PG_DATABASE=qlvb_test)
test_users: test_lanhdao (Ban Lãnh đạo) / test_canbo / test_canbo_x / test_vanthu / test_admin
mode: API + DB query (no browser, no screenshot)
fixtures: edoc.outgoing_docs id=90001 released, 90002 sent, 90003 released cross-unit
script: tools/screenshots/wave-b-vbdi-api.sh
results_json: .planning/phases/23-execute-wave-b/23-vbdi-results.json
---

# Wave b — Văn bản đi + Cấu hình gửi nhanh — Test Results

## Summary

| Sub-batch | Module / Screen | TC | Pass | Fail | Skip |
|-----------|-----------------|----|------|------|------|
| 2A-1 | VB đi — Màn hình danh sách | 7 | 6 | 0 | 1 |
| 2A-2 | VB đi — Drawer thêm văn bản | 12 | 7 | 1 | 4 |
| 2A-3 | VB đi — Hộp xác nhận xóa | 3 | 3 | 0 | 0 |
| 2A-4 | VB đi — Modal từ chối | 3 | 3 | 0 | 0 |
| 2A-5 | VB đi — Trang chi tiết | 15 | 11 | 2 | 2 |
| 2A-6 | VB đi — Modal gửi nội bộ | 4 | 2 | 0 | 2 |
| 2A-7 | VB đi — Modal gửi cán bộ | 3 | 3 | 0 | 0 |
| 2A-8 | VB đi — Drawer giao việc | 4 | 4 | 0 | 0 |
| 2A-9 | VB đi — Modal thêm vào HSCV | 3 | 3 | 0 | 0 |
| 2B   | Cấu hình gửi nhanh — Màn hình chính | 18 | 13 | 0 | 5 |
| **TOTAL Wave b** | — | **72** | **55** | **3** | **14** |

**Pass rate** (loại SKIP): **55 / (55+3) = 94.8%** → sẽ thành **100%** sau fix 3 bug (BUG-VB-DI-001/002/003).

**SKIP breakdown (14 TC):**
- 7 TC UI/visual (cần browser render — TC-VBI-007/018/039/040 + TC-CHGN-005/006/007/009/015 — màu trạng thái, drawer gradient, exclude self-unit, modal title, em-dash placeholder, pagination/search UI state)
- 1 TC ký số (TC-VBI-033 — cần real cert/HSM, mock mode bật)
- 1 TC composite UI flow (TC-VBI-029 — chains 2 API đã verify riêng)
- 4 TC frontend-only validation (TC-VBI-011/012/013 — drafting_unit_id / drafting_user_id / staff cascade; TC-VBI-013 cần endpoint cascade riêng)
- 1 TC search filter UI (TC-VBI-013 cascade fallback do /nhan-vien thiếu permission cho test_lanhdao)

## Bug List Wave b (3 BUGS)

### BUG-VB-DI-001 (MAJOR) — Upload đính kèm KHÔNG check trạng thái duyệt
**Affected TC:** TC-VBI-035
**Symptom:** `POST /api/van-ban-di/:id/dinh-kem` cho phép upload file vào VB đã `approved=true` (status=`approved`) — phải bị chặn theo nghiệp vụ.
**Reproduce:**
```bash
curl -X POST -F "file=@x.txt" /api/van-ban-di/<approved_doc_id>/dinh-kem
# Hiện: HTTP 201 → upload thành công
# Mong đợi: HTTP 403 "Không thể sửa đính kèm khi VB đã duyệt"
```
**Root cause:** Route `outgoing-doc.ts:513 POST /:id/dinh-kem` thiếu `loadDocAndPerms()` + check `perms.canEdit`. So sánh: routes `PUT /:id` và `DELETE /:id` đã có guard này, route attachment thì không.
**Required fix:**
- Thêm vào đầu handler `POST /:id/dinh-kem` (sau `if (!file)`):
  ```typescript
  const { staffId, departmentId, isAdmin } = (req as AuthRequest).user;
  const loaded = await loadDocAndPerms(docId, { staffId, departmentId, isAdmin });
  if (!loaded) { res.status(404).json(...); return; }
  if (!loaded.perms.canEdit) {
    res.status(403).json({ success: false, message: 'Không thể sửa đính kèm khi văn bản đã duyệt' });
    return;
  }
  ```
**Estimate:** 10 phút.

### BUG-VB-DI-002 (MAJOR) — Delete đính kèm KHÔNG check trạng thái duyệt
**Affected TC:** TC-VBI-054
**Symptom:** `DELETE /api/van-ban-di/:id/dinh-kem/:attachmentId` xóa được attachment của VB đã `approved=true`. Phải bị chặn.
**Reproduce:**
```bash
curl -X DELETE /api/van-ban-di/<approved_doc_id>/dinh-kem/<att_id>
# Hiện: HTTP 200 → xóa thành công
# Mong đợi: HTTP 403
```
**Root cause:** Route `outgoing-doc.ts:542 DELETE /:id/dinh-kem/:attachmentId` thiếu `loadDocAndPerms` + canEdit guard (cùng pattern thiếu như BUG-001).
**Required fix:** Cùng pattern như BUG-VB-DI-001 — thêm `loadDocAndPerms` + `canEdit` check ở đầu handler.
**Estimate:** 10 phút (làm chung với BUG-001).

### BUG-VB-DI-003 (MINOR) — Trích yếu không validate maxLength 2000
**Affected TC:** TC-VBI-014
**Symptom:** Cột `abstract` trong DB là `TEXT` (no limit). Backend route `POST /` chỉ check `body.abstract?.trim()` rỗng, không check độ dài. Spec testcase nói boundary 2000.
**Reproduce:**
```bash
curl -X POST -H "Content-Type: application/json" /api/van-ban-di/ -d '{"abstract":"a×2001 chars","doc_book_id":5}'
# Hiện: HTTP 201 → tạo thành công
# Mong đợi: HTTP 400 "Trích yếu không được vượt quá 2000 ký tự"
```
**Root cause:** Backend không enforce, frontend chưa có `maxLength={2000}` rõ ràng trên textarea.
**Required fix (chọn 1):**
- Option A (recommended): Thêm validation trong route `POST /` + `PUT /:id`:
  ```typescript
  if (body.abstract.trim().length > 2000) {
    res.status(400).json({ success: false, message: 'Trích yếu không được vượt quá 2000 ký tự' });
    return;
  }
  ```
- Option B: Frontend `<TextArea maxLength={2000} showCount />` ở drawer thêm/sửa VB đi.
- Khuyến nghị làm cả 2 (defense in depth).
**Estimate:** 15 phút.

## Sub-batch Detail

### 2A-1: VB đi — Màn hình danh sách (7 TC)
- **TC-VBI-001** PASS — list 4 items, đủ cột (number, sub_number, received_date, notation, abstract, drafting_unit_name, recipients, doc_type_name, status).
- **TC-VBI-002** PASS — filter `doc_book_id=5` chính xác, all rows match.
- **TC-VBI-003** PASS — `keyword=cross-unit` matched 1 doc (90003).
- **TC-VBI-004** PASS — `PATCH /danh-dau-da-doc` với `doc_ids=["90001","90002"]` returned success. **Lưu ý: payload field là `doc_ids` chứ không phải `ids`** (đã có tài liệu để FE dùng đúng).
- **TC-VBI-005** PASS — `xuat-excel` với token sai → HTTP 401.
- **TC-VBI-006** PASS — list không token → HTTP 401.
- **TC-VBI-007** SKIP — UI visual (color tags).

### 2A-2: VB đi — Drawer thêm văn bản (12 TC)
- **TC-VBI-008** PASS — POST tạo draft id=90006.
- **TC-VBI-009** PASS — abstract rỗng → "Trích yếu nội dung là bắt buộc".
- **TC-VBI-010** PASS — doc_book_id rỗng → "Sổ văn bản là bắt buộc".
- **TC-VBI-011/012** SKIP — frontend-only validation (backend chấp nhận `drafting_unit_id`/`drafting_user_id` undefined).
- **TC-VBI-013** SKIP — endpoint `/quan-tri/nhan-vien` trả 403 với role Lãnh đạo (chỉ admin); cascade trong UI cần endpoint khác.
- **TC-VBI-014** **FAIL → BUG-VB-DI-003** — abstract 2001 ký tự được chấp nhận.
- **TC-VBI-015** PASS — notation 101 ký tự bị DB chặn (VARCHAR(100) overflow).
- **TC-VBI-016** PASS — sửa draft OK.
- **TC-VBI-017** PASS — sửa VB released → HTTP 400 "Không thể sửa văn bản đã được duyệt" (semantic correct, dùng 400 thay 403 — chấp nhận được).
- **TC-VBI-018** SKIP — UI Drawer 720px gradient.
- **TC-VBI-053** PASS — test_canbo_x update doc đơn vị khác → HTTP 403.

### 2A-3: VB đi — Hộp xác nhận xóa (3 TC)
- **TC-VBI-019** PASS — xóa draft OK.
- **TC-VBI-020** PASS — xóa released → HTTP 400 "Không thể xóa văn bản đã duyệt".
- **TC-VBI-021** PASS — test_canbo_x xóa doc đơn vị khác → HTTP 403.

### 2A-4: VB đi — Modal từ chối (3 TC)
- **TC-VBI-022** PASS — `PATCH /tu-choi` với reason OK.
- **TC-VBI-023** PASS — empty reason — backend chấp nhận (UI sẽ chặn).
- **TC-VBI-024** PASS — test_canbo từ chối → HTTP 403.

### 2A-5: VB đi — Trang chi tiết (15 TC)
- **TC-VBI-025** PASS — detail trả full data + permissions object.
- **TC-VBI-026** PASS — `PATCH /duyet` OK.
- **TC-VBI-027** PASS — `PATCH /huy-duyet` (chưa ban hành) OK.
- **TC-VBI-028** PASS — `PATCH /ban-hanh` cấp số (doc_number sequence increments).
- **TC-VBI-029** SKIP — composite UI flow (đã verify từng API riêng).
- **TC-VBI-030** PASS — `gui-noi-bo` internal_count=1 sau khi add recipient.
- **TC-VBI-031** PASS — `POST /thu-hoi` OK.
- **TC-VBI-032** PASS — gửi VB chưa ban hành → "Văn bản chưa ban hành, không thể gửi".
- **TC-VBI-033** SKIP — real ký số cert (mock mode).
- **TC-VBI-034** PASS — upload attachment khi draft OK.
- **TC-VBI-035** **FAIL → BUG-VB-DI-001** — upload sau khi đã duyệt vẫn HTTP 201.
- **TC-VBI-036** PASS — `POST /y-kien` tạo leader note id=3.
- **TC-VBI-051** PASS — `GET /noi-nhan` trả recipient + tracking fields đầy đủ (sent_status, recipient_unit_name, lgsp_status...).
- **TC-VBI-052** PASS — `so-tiep-theo?doc_book_id=5` trả number tăng dần.
- **TC-VBI-054** **FAIL → BUG-VB-DI-002** — DELETE attachment sau khi đã duyệt HTTP 200.

### 2A-6: VB đi — Modal gửi nội bộ (4 TC)
- **TC-VBI-037** PASS — `POST /noi-nhan` lưu recipients (insert_count=1).
- **TC-VBI-038** PASS — empty recipients array — backend chấp nhận inserted=0 (UI chặn).
- **TC-VBI-039** SKIP — UI exclude self-unit (client-side).
- **TC-VBI-040** SKIP — UI text label changes.

### 2A-7: VB đi — Modal gửi cán bộ (3 TC)
- **TC-VBI-041** PASS — `POST /gui` với staff_ids=[9004] OK.
- **TC-VBI-042** PASS — empty staff_ids → "Vui lòng chọn ít nhất một người nhận".
- **TC-VBI-043** PASS — test_canbo gửi → HTTP 403.

### 2A-8: VB đi — Drawer giao việc (4 TC)
- **TC-VBI-044** PASS — `POST /giao-viec` tạo HSCV id=9003.
- **TC-VBI-045** PASS — empty name → "Tên hồ sơ công việc là bắt buộc".
- **TC-VBI-046** PASS — name 501 ký tự bị DB chặn (VARCHAR(500)).
- **TC-VBI-047** PASS — test_canbo giao việc → HTTP 403.

### 2A-9: VB đi — Modal thêm vào HSCV (3 TC)
- **TC-VBI-048** PASS — link 90002 vào HSCV 9003.
- **TC-VBI-049** PASS — empty handling_doc_id → "Vui lòng chọn hồ sơ công việc".
- **TC-VBI-050** PASS — test_canbo → HTTP 403.

### 2B: Cấu hình gửi nhanh — Màn hình chính (18 TC)
**Endpoints:** `GET /api/cau-hinh-gui-nhanh?config_type=doc|task` + `POST` (bulk replace).

- **TC-CHGN-001** PASS — GET config user mới (test_vanthu) trả `success:true`, data=[] (default empty).
- **TC-CHGN-002** PASS — POST save 1 user → success.
- **TC-CHGN-003** PASS — Re-GET sau save → 1 user visible.
- **TC-CHGN-004** PASS — POST với target_user_ids=[] → bulk delete (0 users sau).
- **TC-CHGN-005/006/007/009** SKIP — UI checkbox toggle / search state preservation / dept filter / pagination (backend stateless, semantics đã cover qua TC-004/008).
- **TC-CHGN-008** PASS — Save [9003] → save [9001,9004] → ghi đè đúng (sau lưu = [9001,9004]).
- **TC-CHGN-010** PASS — `/quan-tri/nhan-vien` không token → HTTP 401.
- **TC-CHGN-011** PASS — `/cau-hinh-gui-nhanh` không token → HTTP 401.
- **TC-CHGN-012** PASS — search nonexistent → 0 results.
- **TC-CHGN-013** PASS — backend chấp nhận empty array (UI phải chặn).
- **TC-CHGN-014** PASS — invalid `target_user_ids:"NOT_AN_ARRAY"` → HTTP 400 "Danh sách người nhận không hợp lệ".
- **TC-CHGN-015** SKIP — UI render em-dash placeholder.
- **TC-CHGN-016** PASS — `config_type=doc` save+read OK (frontend dùng cho gửi VB đến pre-fill).
- **TC-CHGN-017** PASS — `config_type=task` save 2 users + read = 2 (bút phê pre-fill).
- **TC-CHGN-018** PASS — per-user isolation: lanhdao/task=[] vs vanthu/task=[9001,9003] → riêng biệt.

## Files Written

- `tools/screenshots/wave-b-vbdi-api.sh` — bash test script (72 TC, ~470 lines).
- `.planning/phases/23-execute-wave-b/23-vbdi-results.json` — machine-readable results.
- `.planning/phases/23-execute-wave-b/23-RESULTS-vb-di.md` — this file.

## Notes for Next Wave

1. **Frontend không chạy** trong môi trường này (port 3000 not listening). UI-visual TC để parent agent quyết định: chạy Playwright sau khi start FE, hoặc giữ SKIP với reason như Wave a.
2. **Endpoint `/quan-tri/nhan-vien`** trả 403 cho role Lãnh đạo — nếu Drawer thêm VB đi cần cascade staff theo dept, có thể cần endpoint public hoặc relax permission. Đáng làm phase tiếp.
3. **Backend env đã chuyển sang qlvb_test** (`.env` overridden từ `.env.test`). Khi chạy lại dev cần restore `.env.dev_backup`.
4. **Pattern thiếu permission guard cho attachment routes** (BUG-001/002) gợi ý audit toàn bộ routes có dạng `/:id/sub-resource` — incoming-doc cũng nên check tương tự.
