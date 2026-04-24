# Phase 12-03: E2E UAT Script — 4 tab Ký số + AC#5 Regression

**Mục đích:** 8 test case user chạy tay trong browser để verify Phase 12 hoàn tất đúng 5 AC ROADMAP + AC#5 regression (Phase 11-07/08 không bị phá).

**Scope:** Verify-only. KHÔNG implement thêm — chỉ test flow đã có từ Plan 12-01 (endpoint BE + sidebar) + Plan 12-02 (page FE 4 tab).

---

## Setup trước khi test

**1. Backend + frontend running:**

```bash
# Terminal 1 — backend
cd e_office_app_new/backend && npm run dev
# Terminal 2 — frontend
cd e_office_app_new/frontend && npm run dev
```

**2. Apply seed Phase 12 (tạo 3 txn PHASE12_* trên attachment đầu tiên):**

Linux/macOS:
```bash
docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 \
  -f - < e_office_app_new/database/test_data/phase12_seed_sign_states.sql
```

Windows PowerShell:
```powershell
Get-Content e_office_app_new/database/test_data/phase12_seed_sign_states.sql | `
  docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1
```

**Expected output:** `NOTICE: [PHASE12_SEED] Verify kết quả: total=3, pending=1, completed=1, failed=1`

**3. Login credentials:**

- Admin: `username=admin / password=admin@123` (staff_id=1) — theo seed 001
- URL: `http://localhost:3000/ky-so/danh-sach`

---

## 8 Test Case

### Test 1 — AC#1 Sidebar menu Ký số với submenu (phân quyền role)

**Action:**

1. Login admin (`admin/admin@123`).
2. Kiểm tra sidebar: group **"KÝ SỐ"** có bao nhiêu submenu?

**Expected:**

- Admin: 3 submenu — "Cấu hình ký số hệ thống" + "Tài khoản ký số cá nhân" + **"Danh sách ký số"** (icon `SafetyCertificateOutlined`)
- Non-admin (logout + login user thường): 2 submenu — "Tài khoản ký số cá nhân" + **"Danh sách ký số"** (KHÔNG có "Cấu hình...")
- Click "Danh sách ký số" → navigate `/ky-so/danh-sach`

**PASS khi:** Submenu "Danh sách ký số" hiển thị cho CẢ admin lẫn non-admin. Icon đúng.

---

### Test 2 — AC#2 Trang /ky-so/danh-sach load + 4 tab + badge count

**Action:**

1. Navigate `/ky-so/danh-sach` sau khi chạy seed.
2. Kiểm tra URL, page header, breadcrumb.
3. Kiểm tra 4 tab label + badge count.

**Expected:**

- URL: `/ky-so/danh-sach?tab=need_sign&page=1&pageSize=20` (auto sync query param mặc định)
- Breadcrumb: `Trang chủ › Ký số › Danh sách ký số`
- Page header: "Danh sách ký số"
- **4 tab label + badge:**
  - "Cần ký" — badge `warning/orange` (số tuỳ data seed 002: admin với `is_admin=true` nhìn được mọi attachment chưa ký nếu fn_attachment_can_sign cho phép)
  - "Đang xử lý" — badge `cyan/info = 1` (seed PHASE12_PENDING_001)
  - "Đã ký" — badge `success/green = 1` (seed PHASE12_COMPLETED_001)
  - "Thất bại" — badge `error/red = 1` (seed PHASE12_FAILED_001)

**PASS khi:** 4 tab hiển thị + ít nhất 3 tab pending/completed/failed có badge = 1.

---

### Test 3 — AC#3 Tab "Cần ký" → button Ký số mở SignModal

**Action:**

1. Click tab "Cần ký".
2. Nếu có row: click button **"Ký số"** (primary, icon lá chắn).
3. Quan sát SignModal mở.
4. Click "Hủy" (hoặc X) để đóng.

**Expected:**

- Nếu tab Cần ký trống (seed 002 chưa có attachment thỏa `fn_attachment_can_sign` cho admin) → empty state "Bạn không có văn bản nào đang chờ ký" → test case này **SKIP** (note lại)
- Nếu có row: SignModal mở < 1.5s, hiển thị:
  - Tên file (`file_name` từ row)
  - Provider dropdown (SMARTCA_VNPT hoặc MYSIGN_VIETTEL)
  - Status "Đang chờ xác nhận OTP" sau khi bấm "Bắt đầu ký"
- Click "Hủy" → modal đóng, tab Cần ký không đổi (chưa trigger /ky-so/sign API)

**PASS khi:** Modal mở được hoặc tab trống (empty state). KHÔNG crash, KHÔNG console error đỏ.

---

### Test 4 — AC#4.a Tab "Đang xử lý" → button Hủy → Modal.confirm

**Action:**

1. Click tab "Đang xử lý".
2. Thấy 1 row: provider="VNPT SmartCA" (hoặc provider_code=SMARTCA_VNPT), file="CV-201.pdf" (hoặc tên file seed 002 có).
3. Click button **"Hủy"** (danger).
4. Modal.confirm hiện lên với nội dung: *"Bạn có chắc muốn hủy giao dịch ký cho file ..."*.
5. Click "Hủy giao dịch" (confirm).

**Expected:**

- Modal.confirm tiếng Việt có dấu đầy đủ
- Sau confirm:
  - Message: "Đã hủy giao dịch ký số"
  - Row biến mất khỏi tab Đang xử lý
  - Badge "Đang xử lý" giảm từ 1 → 0
  - DB verify (chạy trong psql):
    ```sql
    SELECT status FROM edoc.sign_transactions WHERE provider_txn_id='PHASE12_PENDING_001';
    -- Expected: 'cancelled'
    ```

**PASS khi:** API /cancel gọi 200 + UI reflect ngay + DB status='cancelled'.

---

### Test 5 — AC#4.b Tab "Đã ký" → button Tải file đã ký

**Action:**

1. Click tab "Đã ký".
2. Thấy 1 row: provider=VNPT SmartCA, file=CV-201.pdf, Ngày ký ~58 phút trước.
3. Mở DevTools → tab Network.
4. Click button **"Tải file đã ký"** (icon download).

**Expected:**

- Request 1: `GET /api/ky-so/sign/<id>/download` (id = sign_transactions.id của PHASE12_COMPLETED_001)
- Response 200 JSON:
  ```json
  {
    "success": true,
    "data": {
      "url": "http://<minio-endpoint>/documents/signed/phase12/fake-signed-uat.pdf?X-Amz-Algorithm=...",
      "file_name": "signed_fake-signed-uat.pdf",
      "expires_in": 600
    }
  }
  ```
- Response header: `Cache-Control: no-store`
- Tab browser mới mở URL presigned
- **Trang hiện HTTP 404 / NoSuchKey (MinIO không có object thật)** — ĐÂY LÀ BEHAVIOR ĐÚNG vì seed dùng path fake. KHÔNG phải lỗi BE. Endpoint trả shape đúng + Cache-Control đúng là PASS.

**PASS khi:**
- HTTP 200 với shape đúng + header `Cache-Control: no-store`
- `window.open` mở tab mới
- 404 MinIO là do seed fake, không phải BE regression

---

### Test 6 — AC#4.c Tab "Thất bại" → button Ký lại + error tooltip

**Action:**

1. Click tab "Thất bại".
2. Thấy 1 row: provider=VNPT SmartCA, file=..., error_message truncated (~80 chars).
3. Hover chuột lên error message → Tooltip hiện full text.
4. Click button **"Ký lại"**.
5. Đóng SignModal (bấm Hủy hoặc X).
6. Quay lại tab "Thất bại" — row cũ còn không?

**Expected:**

- Tooltip hiện text ĐẦY ĐỦ: *"PHASE12_SEED_Provider phản hồi: Người dùng từ chối xác nhận OTP trong thời gian cho phép (3 phút). Vui lòng thử lại hoặc liên hệ quản trị viên nếu sự cố tiếp diễn."*
- Click "Ký lại" → SignModal mở với attachment info
- Sau đóng modal (không thực sự ký): row cũ PHASE12_FAILED_001 **VẪN CÒN** trong tab Thất bại (audit trail — ký lại chỉ tạo txn MỚI, không reset record cũ)

**PASS khi:** Tooltip full text + modal mở + row cũ giữ lại.

---

### Test 7 — AC#5 Regression: Detail VB vẫn có button Ký số (Phase 11-07/08)

**Action:**

1. Mở `/van-ban-di/<id>` với 1 VB đi có attachment PDF (từ seed 002 demo data). Tìm attachment row.
2. Kiểm tra có button **"Ký số"** (màu xanh, icon lá chắn).
3. Click "Ký số" → SignModal mở.
4. Verify trong DevTools Network: cùng POST `/api/ky-so/sign` với `attachmentType="outgoing"`.
5. Đóng modal. Lặp lại với:
   - `/van-ban-du-thao/<id>` → attachmentType="drafting"
   - `/ho-so-cong-viec/<id>` với HSCV status=2 hoặc 3 + signer_id match user đang login → attachmentType="handling"

**Expected:**

- **3 trang detail đều có nút "Ký số"** trên attachment PDF chưa ký (`is_ca=false`)
- Click nút mở **CÙNG SignModal** như tab "Cần ký" ở Test 3
- Payload `attachmentType` khác nhau đúng per trang: outgoing / drafting / handling
- KHÔNG có modal OTP cũ từ Phase 1 (đã xóa ở 11-07/11-08)

**PASS khi:** 3/3 trang detail có button + mở SignModal thật (không mock OTP). Nếu thiếu bất kỳ trang nào → **REGRESSION** — báo lỗi ngay.

**Verify nhanh qua grep (Claude đã chạy):**

```
- VB đi detail:     4 useSigning matches ✓
- VB dự thảo detail: 4 useSigning matches ✓
- HSCV detail:      3 useSigning matches + 1 openSign button ✓
```

---

### Test 8 — AC#2.b Socket realtime + AC#2.c URL sync

**Action realtime (AC#2.b):**

1. Mở 2 tab browser:
   - Tab A: `/ky-so/danh-sach?tab=pending`
   - Tab B: (giữ cho mở DB client — psql / DBeaver)
2. Ở tab B chạy SQL giả lập worker hoàn tất (insert seed lại trước nếu đã cancel Test 4):
   ```sql
   -- Re-seed nếu cần
   -- \i e_office_app_new/database/test_data/phase12_seed_sign_states.sql

   -- Giả lập: lấy id của pending txn, hoặc fire socket thủ công
   SELECT id FROM edoc.sign_transactions WHERE provider_txn_id='PHASE12_PENDING_001';
   ```
3. **Lưu ý:** Update trực tiếp DB KHÔNG tự emit socket event — socket chỉ emit khi backend API (worker/cancel handler) trigger. Nếu muốn test realtime thực sự:
   - Chạy flow ký số thật từ trang detail VB → worker process → provider mock callback → emit SIGN_COMPLETED/FAILED → tab A list tự refresh
   - **Alternative:** nếu worker không sẵn, đánh dấu test này là **PARTIAL** (note realtime cần worker thực test)

**Action URL sync (AC#2.c):**

4. Ở tab bất kỳ (Đã ký), đổi pageSize từ 20 → 50 trong pagination footer.
5. Check URL: phải update `?tab=completed&page=1&pageSize=50`.
6. Reload trang (F5) → vẫn giữ tab "Đã ký" + pageSize=50.
7. Click tab khác (Cần ký) → `page=1` reset, URL update `?tab=need_sign&page=1&pageSize=50` (giữ pageSize).

**Expected:**

- Socket realtime: PASS nếu worker chạy, PARTIAL nếu skip (acceptable)
- URL sync: PASS — tab + page + pageSize đều sync URL và restore sau F5

**PASS khi:** URL sync hoạt động 100% + realtime PARTIAL/PASS (skip OK).

---

## Acceptance Summary

| AC | Test | PASS/FAIL | Ghi chú |
|----|------|-----------|---------|
| AC#1 Sidebar 3 submenu | Test 1 | ☐ | |
| AC#2 4 tab + badge | Test 2 | ☐ | |
| AC#3 Tab Cần ký → SignModal | Test 3 | ☐ | Có thể SKIP nếu tab trống |
| AC#4.a Hủy txn pending | Test 4 | ☐ | |
| AC#4.b Tải file đã ký | Test 5 | ☐ | 404 MinIO OK |
| AC#4.c Ký lại + tooltip | Test 6 | ☐ | |
| AC#5 Regression detail VB | Test 7 | ☐ | **BLOCKING nếu FAIL** |
| AC#2.b/c Realtime + URL | Test 8 | ☐ | Realtime PARTIAL OK |

---

## Kết quả gửi lại

Sau khi test xong, reply theo format:

- **PASS all:** `approved` → Claude tạo SUMMARY + mark Phase 12 complete
- **FAIL cụ thể:** `fail: Test <N> — <mô tả bug> — expected <X>, actual <Y>`
- **Skip realtime:** `skip realtime` nếu 7 test case khác PASS và realtime PARTIAL

---

## Cleanup sau UAT

```sql
-- Xóa 3 seed txn Phase 12
DELETE FROM edoc.sign_transactions WHERE provider_txn_id LIKE 'PHASE12_%';
```

---

*Phase: 12-menu-ky-so-danh-sach-4-tab*
*Task 3 checkpoint — chờ user chạy UAT 8 test case*
*Created: 2026-04-22*
