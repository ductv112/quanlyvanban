# Wave i — Concurrent / Session / Race-condition / Performance — Results

**Date:** 2026-05-07
**Tester:** AI (Tester role)
**Scope:** 13 TC từ `tools/screenshots/testcases-wave-i.json`
**Backend:** http://localhost:4000 (qlvb_test)
**Method:** bash + curl parallel (`&` background, `xargs -P`)

## Tổng kết

| Module | Total | PASS | FAIL/BUG | NOT IMPL | NOTE |
|---|---|---|---|---|---|
| Session & Token (5) | 5 | 3 | 1 | 1 | |
| Race conditions (5) | 5 | 2 | 2 | 0 | 1 record-only |
| Performance (3) | 3 | 2 | 1 | 0 | |
| **TOTAL** | **13** | **7** | **4** | **1** | 1 record-only |

## Bugs phát hiện

### BUG-CONC-001 — Multi-device login: refresh token cũ bị revoke (P3)
- **TC:** TC-CONC-ST-004
- **Mô tả:** Khi cùng user login từ device 2, refresh_token của device 1 bị revoke (xem `staff_id=9004`: row id=39 active, các row trước đó đều có `revoked_at`).
- **Hệ quả:** Access token device 1 vẫn dùng được tới khi expire (15 min), nhưng `/auth/refresh` từ device 1 sẽ fail → bị logout.
- **Expected (theo TC):** Cả 2 device đều có refresh token riêng trong DB, đều dùng được.
- **Actual:** Login mới revoke token cũ → nghiệp vụ multi-device không hoạt động đúng.
- **Severity:** Medium (UX). Nhân sự nhà nước thường login PC + mobile.
- **Fix gợi ý:** Bỏ revoke trong login flow, chỉ revoke khi explicit logout.
- **Evidence:** `D:/temp/dev1.txt`, `D:/temp/dev2.txt`, query `SELECT * FROM refresh_tokens WHERE staff_id=9004 ORDER BY created_at DESC`.

### BUG-CONC-002 — Concurrent approve không idempotent (P2)
- **TC:** TC-CONC-RC-002
- **Mô tả:** 2 lãnh đạo cùng PATCH `/api/van-ban-du-thao/:id/duyet` → cả 2 đều HTTP 200 + "Duyệt thành công". DB chỉ giữ approver cuối (last write wins).
- **Expected:** 1 succeed, 1 báo "Đã được phê duyệt bởi <user>".
- **Actual:** Cả 2 đều succeed, không có guard "đã duyệt" trong SP.
- **Severity:** Medium (data consistency). Mất audit trail của approver thật.
- **Fix gợi ý:** SP `fn_drafting_doc_approve` check `IF approved=true THEN RAISE 'Đã được phê duyệt'` trước UPDATE.
- **Evidence:** `D:/temp/appr-a.json`, `D:/temp/appr-b.json` — both `{"success":true,"data":{"message":"Duyet thanh cong"}}`.

### BUG-CONC-003 — Outgoing doc number race condition: duplicate numbers (P1)
- **TC:** TC-CONC-RC-005
- **Mô tả:** SP `edoc.fn_outgoing_doc_get_next_number` dùng `SELECT MAX(number)+1` (KHÔNG atomic). Test 2 concurrent POST `/api/van-ban-di` với `number=1, doc_book_id=2` → cả 2 thành công với cùng number=1 trong cùng sổ.
- **Expected:** 1 VB number=1, 1 VB number=2 (auto-increment không trùng).
- **Actual:** 2 record cùng `(doc_book_id=2, number=1)` — vi phạm nghiệp vụ "số văn bản không trùng trong cùng sổ".
- **Severity:** **HIGH** — vi phạm nghiệp vụ lõi cơ quan nhà nước. Văn thư không thể có 2 VB cùng số trong 1 sổ năm.
- **Root cause:**
  1. SP MAX+1 không lock (không `SELECT FOR UPDATE` / serializable transaction)
  2. KHÔNG có UNIQUE INDEX trên `(doc_book_id, number, EXTRACT(YEAR FROM received_date))` ở table `outgoing_docs`
- **Fix gợi ý:**
  - Add: `CREATE UNIQUE INDEX ux_outgoing_docs_book_number_year ON edoc.outgoing_docs (doc_book_id, number, EXTRACT(YEAR FROM received_date)) WHERE number IS NOT NULL;`
  - Hoặc dùng PostgreSQL sequence per (doc_book_id, year) → atomic
  - Hoặc SP wrap trong `BEGIN; LOCK TABLE outgoing_docs IN ROW EXCLUSIVE; INSERT ...; COMMIT;`
- **Evidence:**
  - 5 concurrent GET `/so-tiep-theo` → tất cả trả `number=1` (race confirmed)
  - 2 concurrent POST → DB có 2 row id=90004,90005 cùng `(doc_book_id=2, number=1)`

### BUG-CONC-004 — Login P95 latency dưới load: 6231ms (P3)
- **TC:** TC-CONC-PERF-003
- **Mô tả:** 100 concurrent login (xargs -P 20):
  - Success: 100/100 (100% success rate, backend không sập — PASS spec này)
  - **P95 = 6231ms** vs target **500ms** (12x slower)
  - P50 = 4694ms, P99 = 6692ms, Max = 6692ms
  - Sequential baseline: 361ms/req — chấp nhận được
- **Root cause:** bcrypt cost factor cao + Node.js single-thread block event loop khi hash đồng thời.
- **Severity:** Low-Medium. Ảnh hưởng moment "100 user cùng login đầu giờ" → vẫn login OK nhưng chậm.
- **Fix gợi ý:** 
  - Move bcrypt sang worker_threads pool
  - Hoặc giảm cost factor từ default 10 → 8 (vẫn an toàn)
  - Hoặc cache successful login + reduce DB roundtrips

## Chi tiết từng TC

### TC-CONC-ST-001 — Multi-tab logout — PASS
- 2 tab cùng user → 2 access token + 2 refresh token độc lập (trong DB).
- Tab A bấm logout → revoke chỉ refresh token của session A.
- Tab B access token vẫn dùng được. Tab B refresh cookie vẫn refresh thành công.
- Tab A refresh sau logout → "Refresh token đã hết hạn hoặc bị thu hồi".
- **Behavior:** Per-session logout (đúng best practice).
- **Note:** Frontend không proactively invalidate tab khác → tab B chỉ logout khi access token expire (15 min) HOẶC user reload. Có thể enhancement: BroadcastChannel API để sync logout cross-tab.

### TC-CONC-ST-002 — Auto-refresh on 401 — PASS
- Backend: invalid/expired access token → HTTP 401.
- Backend: `/api/auth/refresh` với valid cookie → HTTP 200 + new access token + token rotation.
- Frontend (`src/lib/api.ts:23-46`): axios interceptor catch 401 → call `/auth/refresh` → save new token → retry original request → user không thấy gián đoạn.
- Verified end-to-end OK.

### TC-CONC-ST-003 — Refresh token expired (8 ngày) — PASS
- Force expire trong DB: `UPDATE refresh_tokens SET expires_at = NOW() - INTERVAL '1 day'`.
- Backend response: `{"success":false,"message":"Refresh token đã hết hạn hoặc bị thu hồi"}` HTTP 401.
- Frontend axios interceptor (line 36-41): catch error → `localStorage.removeItem('accessToken')` → `window.location.href = '/login'`. Verified.

### TC-CONC-ST-004 — Multi-device login — FAIL (BUG-CONC-001)
- See bug above.

### TC-CONC-ST-005 — Logout-all-devices — NOT IMPLEMENTED
- Grep `logout-all`, `logoutAll` trong backend `src/routes/`, `src/services/`, frontend `src/` → không có.
- Per TC notes: "Nếu chưa có chức năng này, ghi nhận làm enhancement."
- **Backlog:** Add `POST /api/auth/logout-all` → revoke tất cả refresh_tokens cho staff_id.

### TC-CONC-RC-001 — 2 user cùng edit VB đến — PASS (last-write-wins)
- 2 PUT `/api/van-ban-den/90001` parallel (test_vanthu vs test_admin):
  - Cả 2 HTTP 200 `{"success":true,"data":{"updated":true}}`
  - Final state = B (test_admin) — last to commit
- **Behavior:** Last-write-wins (no optimistic lock, no `version` field).
- **Per TC:** "Ghi nhận hành vi thực tế và đối chiếu nghiệp vụ" — đã ghi nhận.
- **Discussion với BA cần:** Có cần optimistic lock để cảnh báo "Người khác đã sửa, vui lòng tải lại"? Hiện tại data B sẽ silent overwrite data A → có thể mất công sức.

### TC-CONC-RC-002 — Concurrent approve — FAIL (BUG-CONC-002)
- See bug.

### TC-CONC-RC-003 — Double-click sign — PASS (frontend guard)
- `SigningModal.tsx` line 361: Submit button có `loading={loading}` → AntD auto-disable button khi loading.
- Backend ký số phải qua provider check (`getActiveProviderWithCredentials`) — không test được full flow vì DEV không có CA provider config.
- Frontend guard đủ để prevent double submission.

### TC-CONC-RC-004 — Delete + access — PASS
- User B đọc VB 90001 → HTTP 200.
- User A delete VB 90001 → HTTP 200 "Xóa văn bản đến thành công".
- User B re-read VB 90001 → HTTP 404 `{"success":false,"message":"Không tìm thấy văn bản đến"}`. Vietnamese message OK.
- Frontend mount trang chi tiết khi nhận 404 sẽ hiển thị "không tìm thấy" (cần verify trong wave UI).

### TC-CONC-RC-005 — Concurrent notation — FAIL (BUG-CONC-003)
- See bug. **Nghiêm trọng nhất** trong wave này.

### TC-CONC-PERF-001 — List 10000 records — PASS
- Bulk insert 10001 record → `count(*) = 10008`.
- Test pagination với test_admin (sees all units):

| Page | Run 1 | Run 2 | Run 3 |
|---|---|---|---|
| 1 | 224ms | 109ms | 79ms |
| 100 | 139ms | 171ms | 261ms |
| 500 (last) | 281ms | 448ms | 185ms |

- **Threshold:** < 2s. **Actual:** all < 500ms. PASS.
- Cleanup OK (delete 10001 PERF rows).

### TC-CONC-PERF-002 — Search 10000 — PASS (caveat)
- Search "quyết định" / "PERF-TEST":

| Query | Run 1 | Run 2 | Run 3 |
|---|---|---|---|
| "quyết định" | 263ms | 213ms | 265ms |
| "PERF-TEST" | 244ms | 211ms | 189ms |

- **Threshold:** < 3s. **Actual:** all < 300ms. PASS.
- **Caveat:** EXPLAIN ANALYZE shows `Seq Scan` on `incoming_docs` với `abstract ILIKE` (NOT using pg_trgm GIN index). 19ms execution time at 10k rows.
  - Index `idx_outgoing_docs_search` (GIN trgm) tồn tại ở `outgoing_docs` nhưng KHÔNG có ở `incoming_docs`.
  - **Recommendation (backlog):** Add `CREATE INDEX idx_incoming_docs_search ON edoc.incoming_docs USING gin (abstract gin_trgm_ops);` — sẽ scale tốt hơn ở 100k+ records.

### TC-CONC-PERF-003 — 100 concurrent login — FAIL (BUG-CONC-004 latency)
- Sequential 100 login: avg 361ms/req — acceptable.
- Parallel 100 login (xargs -P 20):
  - Success rate: **100% (100/100 HTTP 200)** — backend không sập, PASS reliability spec.
  - Avg: 4538ms, P50: 4694ms, **P95: 6231ms**, P99: 6692ms, Max: 6692ms
  - Wall time: 25s
- **Per TC:** "100% success rate. P95 < 500ms."
  - 100% success: PASS
  - P95 < 500ms: **FAIL by 12x** → BUG-CONC-004

## Test environment
- Backend: localhost:4000, qlvb_test DB (10008 incoming + ~14 outgoing trước cleanup)
- Test users: test_admin, test_vanthu, test_lanhdao, test_canbo (Test@123). test_chuyenvien/test_truongphong KHÔNG tồn tại (chỉ 4 user fixture available).
- Tools: bash + curl + xargs (KHÔNG dùng k6 per re-scope).
- Cleanup: 10001 PERF incoming_docs + 2 dup outgoing_docs đã xóa.

## Khuyến nghị priority

1. **P1 — BUG-CONC-003 (notation duplicate)** — Critical business logic violation. Cần fix trước khi go-prod. Effort: 1-2h (add unique index + sequence).
2. **P2 — BUG-CONC-002 (concurrent approve)** — Cần fix để có audit trail chính xác. Effort: 30min (SP guard).
3. **P3 — BUG-CONC-001 (multi-device login)** — Improve UX. Effort: 15min (bỏ revoke trong login).
4. **P3 — BUG-CONC-004 (login P95)** — Optimization, không block. Effort: 1h (worker_threads cho bcrypt).
5. **Backlog** — Logout-all-devices endpoint, GIN index trên `incoming_docs.abstract`, BroadcastChannel sync logout cross-tab, optimistic locking cho VB đến (cần BA discuss).
