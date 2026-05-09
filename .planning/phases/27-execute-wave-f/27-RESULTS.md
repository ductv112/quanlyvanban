---
phase: 27-execute-wave-f
batch: Wave f (97 TC) — Boundary VARCHAR + file upload (17 module)
mode: API + python boundary payloads (4 agent parallel)
---

# Wave f — Master Results

| Agent | Scope | TC | Pass | Fail/Bug |
|---|---|---|---|---|
| 1 | Auth+Notif+Đơn vị+Chức vụ+Nhóm quyền | 27 | 22 | 4 |
| 2 | VB đến + VB đi | 26 | 19 | 7 |
| 3 | Dự thảo + HSCV + Ký số HT + TK ký số | 20 | 13 | 5 (+2 not testable) |
| 4 | Người dùng + 4 Danh mục + Cấu hình gửi nhanh | 24 | 21 | 3 |
| **Wave f** | | **97** | **75** | **19** (3 misc) |

**Pass rate: 75/94 = 79.8%**

## 🚨 HIGH severity bugs Wave f

| ID | Severity | Issue |
|---|---|---|
| BUG-F-VB-006 | **HIGH SECURITY** | Upload `.exe` (mọi extension) accepted — `middleware/upload.ts` không có MIME/extension whitelist |
| BUG-F-VB-005 | HIGH | Duplicate `notation` cùng `doc_book_id` KHÔNG chặn (no unique index, no pre-check SP) — 2 VB cùng số ký hiệu trong 1 sổ vẫn lưu OK |
| BUG-F-VB-004 | HIGH | VB đi field `approver` bị silent drop — route + repo + SP không truyền param dù DB column tồn tại |
| BUG-F-VB-003 | HIGH | Multer reject file ĐÚNG 50MB (52428800 bytes) — operator `>=` thay vì `>` |
| BUG-F-ND-002 | HIGH (schema) | `first_name(50) + last_name(50)` → `full_name STORED VARCHAR(100)` tràn (101 chars) → 500. Cần mở rộng full_name → 150 hoặc add guard route |

## Medium/low + duplicates

- BUG-F-001 (medium): POST đơn vị silent drop `lgsp_system_id`/`lgsp_secret_key`
- BUG-F-002 (low): phone format không validate BE
- BUG-F-003 (low): email format không validate BE
- BUG-F-004/007 + BUG-F-HSCV-001 = duplicate **PG raw error 500 leak** (đã có Wave d/e)
- BUG-F-KS-001 = duplicate **BIGINT pitfall PUT 404** (đã có Wave c)
- BUG-F-VB-001 (medium): `number_paper = -1` không validate range
- BUG-F-VB-002 (medium): `expired_date >= received_date/publish_date` không enforce BE
- BUG-F-VB-007 (low): English raw msg + HTTP 500 thay vì 413 cho LIMIT_FILE_SIZE
- BUG-F-DT-001 (low): `number_copies = 0` silent coerce → 1
- BUG-F-ND-001 (medium): username 51 chars → 500 raw (route thiếu validate)
- BUG-F-ND-003 (medium): phone regex `{8,15}` chặn 20 chars dù DB VARCHAR(20)

## Schema gaps (TC re-baseline cần thiết)

- `edoc.notices.title`: thực tế VARCHAR(300), TC giả định 200
- `public.roles.name`: thực tế VARCHAR(100), TC giả định 200

## Cumulative v3.1 status (765 / 847 TC = 90% scope)

| | Wave a-e | Wave f | Total |
|---|---|---|---|
| TC | 668 | 97 | **765** |
| PASS | 528 | 75 | **603 (79%)** |
| FAIL | 48 | 19 | **67** |
| Pass rate | 91.6% | 79.8% | **90%** |

**Bugs cumulative ~64 unique** (51 + 13 new). Pattern fixes critical:
- 1 fix `error-handler.ts` (SQLSTATE 22001) → resolve 5+ bugs
- 1 fix `server.ts` mount order → resolve 9 bugs (public-catalog shadow)
- 1 fix `ky-so-cau-hinh.ts:471` `Number(existing.id)` → resolve 3+ bugs (BIGINT pitfall)
- 1 fix `middleware/upload.ts` MIME whitelist → 1 critical security bug
