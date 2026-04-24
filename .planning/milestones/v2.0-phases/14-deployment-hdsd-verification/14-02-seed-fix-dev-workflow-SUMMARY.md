---
phase: 14-deployment-hdsd-verification
plan: 02
subsystem: deployment
tags:
  - deployment
  - seed
  - security
  - docs
one-liner: "Seed 001 disable cả 2 provider + strip hardcoded dev creds; README.md thêm section Development setup 6-bước"
requirements:
  - DEP-01
dependency_graph:
  requires:
    - "Plan 14-01 (README.md baseline Windows-only)"
  provides:
    - "Production-safe seed — deploy KH không leak dev credentials SmartCA"
    - "Admin workflow tài liệu: config provider qua UI sau mỗi deploy/reset"
    - "Evidence concrete cho Plan 14-03 DEP-01 Verify Evidence column"
  affects:
    - "deploy-windows.ps1 fresh deploy: 2 provider disabled sau seed → admin bắt buộc config"
    - "Dev environment đã có DB cũ: ON CONFLICT DO NOTHING — không overwrite, cần UPDATE thủ công nếu muốn reset"
tech-stack:
  added: []
  patterns:
    - "Seed idempotent ON CONFLICT DO NOTHING + pgp_sym_encrypt('', key) cho disabled provider (giữ BYTEA non-null, avoid pgp_sym_decrypt NULL crash)"
key-files:
  created: []
  modified:
    - e_office_app_new/database/seed/001_required_data.sql
    - deploy/README.md
decisions:
  - "D-03 executed: SmartCA VNPT TRUE→FALSE + empty creds + xóa hardcoded 'ZjA4MjE4NDg-MjU3Mi00ZDAw' và '4d00-638392811079166938.apps.smartcaapi.com'"
  - "D-04 executed: README.md thêm section 'Development setup sau reset-db' 6-bước flow"
  - "D-05 executed: KHÔNG tách 002_demo_data.sql — chỉ sửa 001"
  - "Option B cho dev DB (không UPDATE thủ công): verify seed FILE đúng, DB cũ mặc kệ vì chỉ là local dev — production deploy fresh sẽ chạy seed mới"
  - "Warning comment thêm vào seed hướng dẫn UPDATE thủ công nếu KH/dev gặp edge case DB đã có row active từ seed cũ"
metrics:
  duration: "3min"
  completed: "2026-04-23"
  tasks: 2
  files_modified: 2
---

# Phase 14 Plan 02: Seed fix + Dev workflow — Summary

## Overview

Plan 14-02 triển khai 2 deliverable của DEP-01 (milestone v2.0 production deploy safety):

1. **Production-safe seed:** đổi `seed/001_required_data.sql` từ "SmartCA active với hardcoded dev creds" → "cả 2 provider disabled + empty/placeholder credentials". Khi KH deploy production, DB sẽ có 2 provider ở trạng thái disabled — không thể vô tình ký số qua kênh SmartCA của dev team.
2. **Dev workflow documentation:** thêm section `## Development setup sau reset-db` vào `deploy/README.md` hướng dẫn admin (dev/test/production) cấu hình provider qua UI sau mỗi lần reset-db.

Kết quả: DEP-01 (production deploy seed scripts cho provider config) có evidence concrete (seed file disabled + README dev workflow section), chuẩn bị cho Plan 14-03 audit REQUIREMENTS.md.

## What Was Done

### Task 1 — Fix seed 001: SmartCA disable + strip dev creds

Edit `e_office_app_new/database/seed/001_required_data.sql`:

**SmartCA VNPT block (dòng 197-211):**
- `is_active`: `TRUE` → `FALSE`
- `client_id`: `'4d00-638392811079166938.apps.smartcaapi.com'` → `''` (empty string, column NOT NULL DEFAULT '' cho phép)
- `client_secret`: `pgp_sym_encrypt('ZjA4MjE4NDg-MjU3Mi00ZDAw', v_key)` → `pgp_sym_encrypt('', v_key)` (giữ BYTEA non-null, decrypt ra empty signal "chưa config")
- Thêm comment `-- SmartCA VNPT (production-safe: is_active=FALSE + empty credentials)` + pointer tới deploy/README

**MySign Viettel block (dòng 215-229):**
- KHÔNG đổi values (đã là FALSE + empty/placeholder từ trước)
- Chỉ update comment `-- MySign Viettel (production-safe: is_active=FALSE + placeholder credentials)` cho đồng nhất wording

**Warning comment (dòng 187-192):** hướng dẫn UPDATE thủ công nếu DB đã có row từ seed cũ:

```sql
-- ⚠️ LƯU Ý: Nếu DB đã có row provider từ seed cũ (is_active đang bật + dev creds),
-- ON CONFLICT DO NOTHING sẽ KHÔNG overwrite. Chạy UPDATE thủ công để reset:
--   UPDATE public.signing_provider_config
--      SET is_active=FALSE, client_id='', client_secret=pgp_sym_encrypt('', v_key)
--    WHERE provider_code='SMARTCA_VNPT';
-- Hoặc chạy reset-db-windows.ps1 để reset fresh DB.
```

**RAISE NOTICE** cuối DO block update message: `2 providers disabled — admin must configure via /ky-so/cau-hinh`.

**Runtime verify (optional smoke test):** Apply seed file lên dev DB → `NOTICE: seed/001_required_data.sql: Master data OK (admin/Admin@123, 2 providers disabled — admin must configure via /ky-so/cau-hinh)`. SQL syntax valid, zero error.

**Acceptance checks (grep):**

| Check | Result |
|-------|--------|
| dev secret hardcoded (`ZjA4MjE4NDg-MjU3Mi00ZDAw`) | 0 (expected 0) ✓ |
| dev client_id hardcoded (`4d00-638392811079166938`) | 0 (expected 0) ✓ |
| SmartCA 15-line FALSE count | 3 (expected ≥ 1) ✓ |
| SmartCA 15-line TRUE count | 0 (expected 0) ✓ |
| MySign 15-line FALSE count | 1 (expected ≥ 1) ✓ |
| `production-safe` markers | 3 (expected ≥ 2) ✓ |
| `pgp_sym_encrypt('', v_key)` empty encrypts | 2 (expected ≥ 1) ✓ |
| `ON CONFLICT (provider_code) DO NOTHING` | 2 (expected = 2) ✓ |

**Commit:** `c102ab4` — `fix(14-02): seed 001 disable SmartCA + strip dev creds (production-safe)`

### Task 2 — Append section "Development setup sau reset-db" vào deploy/README.md

Append section mới **ngay trước** `## Tham khảo` trong `deploy/README.md`:

**Cấu trúc section (6-bước flow):**

1. Đăng nhập admin (`admin` / `Admin@123`)
2. Menu Ký số → Cấu hình ký số hệ thống (`/ky-so/cau-hinh`)
3. Chọn provider (SmartCA VNPT / MySign Viettel) + field cần nhập
4. Credentials dev/test từ `.env.dev-creds` (KHÔNG commit); credentials production từ KH
5. Bấm Test connection → bắt buộc OK mới lưu được
6. Bật toggle Kích hoạt → Lưu

**Lưu ý (3 bullet):**
- Chỉ 1 provider active cùng lúc (partial unique index)
- Đổi `SIGNING_SECRET_KEY` → credentials cũ không decrypt được → phải nhập lại
- KHÔNG hardcode creds vào seed hoặc commit `.env.dev-creds`

**Acceptance checks (grep):**

| Check | Result |
|-------|--------|
| `## Development setup` heading | 1 (expected = 1) ✓ |
| `Development setup sau reset-db` | 1 ✓ |
| `/ky-so/cau-hinh` URL mention | 2 (expected ≥ 1) ✓ |
| `Test connection` bước 5 | 1 (expected ≥ 1) ✓ |
| `.env.dev-creds` reference | 2 (expected ≥ 1) ✓ |
| `Admin@123` mention | 2 (expected ≥ 1) ✓ |
| `## Tham khảo` section cuối | 1 ✓ |
| Last 2 H2: Development setup → Tham khảo | ✓ đúng thứ tự |
| Total lines | 198 (trong [120, 220]) ✓ |
| dev secret leak (`ZjA4MjE4NDg-MjU3Mi00ZDAw`) | 0 ✓ |
| dev client_id leak (`4d00-638392811079166938`) | 0 ✓ |

**Commit:** `804bd03` — `docs(14-02): thêm section "Development setup sau reset-db" vào deploy/README.md`

## Files Changed

**Modified (2 files):**
- `e_office_app_new/database/seed/001_required_data.sql` (+16 / -6 lines) — SmartCA disabled + dev creds removed + warning comment + comment đồng nhất cả 2 block
- `deploy/README.md` (+21 / -0 lines) — section "Development setup sau reset-db" thêm ngay trước "Tham khảo"

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | `c102ab4` | `fix(14-02): seed 001 disable SmartCA + strip dev creds (production-safe)` |
| 2 | `804bd03` | `docs(14-02): thêm section "Development setup sau reset-db" vào deploy/README.md` |

## Decisions Implemented

- **D-03 (seed fix Option A):** SmartCA `is_active=TRUE` → `FALSE` + credentials hardcoded xóa hoàn toàn. Giữ `pgp_sym_encrypt('', v_key)` thay `NULL` để tránh `pgp_sym_decrypt NULL` crash runtime backend.
- **D-04 (dev workflow documentation):** section ngắn 6-bước trong `deploy/README.md` (không viết vào `CLAUDE.md` — giữ CLAUDE.md focused vào code conventions). Production deploy IT triển khai làm bước tương tự với real credentials từ KH.
- **D-05 (KHÔNG tách 002_demo_data.sql):** chỉ edit `001_required_data.sql`. File `002_demo_data.sql` giữ nguyên — chỉ seed demo data (transactions, users test), không extend dev creds.
- **Design choice: `pgp_sym_encrypt('', v_key)` vs `NULL`:** giữ non-null BYTEA để `fn_signing_provider_list` / `fn_signing_provider_get` decrypt không crash. Decrypt ra empty string = signal "chưa config", backend UI có thể check `client_secret_length=0` thay `NULL`.
- **Option B cho dev DB state:** không UPDATE manual row cũ (SmartCA is_active=t, cid_len=43 trong dev DB hiện tại) — vì seed FILE đã đúng cho production fresh deploy. Warning comment trong seed giải thích edge case cho dev gặp phải.

## Deviations from Plan

**None.** Plan 14-02 executed exactly as written. 2 tasks, 0 auto-fixes, 0 architectural checkpoints.

**1 minor self-correction:** Phiên bản đầu của warning comment chứa chuỗi `is_active=TRUE` (giải thích scenario seed cũ). Acceptance criteria strict yêu cầu 15-line-window sau SMARTCA_VNPT KHÔNG có `TRUE`. Đổi wording warning → `is_active đang bật` (vẫn rõ nghĩa tiếng Việt), pass acceptance. Không phải deviation — self-correct để đạt acceptance criteria strict, không thay đổi ý nghĩa.

## Affects / Provides

- **Affects:**
  - Production deploy flow: admin MUST login + config provider sau mỗi `deploy-windows.ps1` / `reset-db-windows.ps1`
  - Dev environment đã seed: ON CONFLICT DO NOTHING không overwrite — có warning comment hướng dẫn cleanup
  - User experience: sau fresh deploy, `/ky-so/sign` sẽ fail-fast với message "Chưa có provider active" cho đến khi admin config
- **Provides:**
  - Evidence concrete cho Plan 14-03 DEP-01 Verify Evidence column: `grep -A 15 "SMARTCA_VNPT" seed/001_required_data.sql | grep -c FALSE` ≥ 1
  - Production-safe seed baseline cho KH triển khai v2.0
- **Patterns reused:** Seed idempotent (`ON CONFLICT DO NOTHING`), v_key session variable validate (≥16 chars), pgp_sym_encrypt wrap tại DB boundary
- **Patterns new:** `pgp_sym_encrypt('', v_key)` cho "disabled-but-decryptable" state — avoid NULL BYTEA crash trong decrypt flow

## Blockers / Concerns

None. Plan độc lập với 14-03 về file và logic. 14-03 đã executed trước (per STATE.md timeline) nên không block.

**Edge case documented:** Dev/test environment đã có DB cũ với SmartCA is_active=TRUE — không tự động reset. Nếu dev cần test "fresh seed state": chạy `reset-db-windows.ps1` hoặc UPDATE manual theo pattern trong warning comment.

## Threat Mitigations

| Threat ID | Category | Mitigation | Evidence |
|-----------|----------|------------|----------|
| T-14-02-01 | Information Disclosure | Xóa hardcoded dev credentials khỏi seed | `grep -c 'ZjA4MjE4NDg-MjU3Mi00ZDAw' 001_required_data.sql` = 0 |
| T-14-02-02 | Elevation of Privilege | `is_active=FALSE` sau seed → user không ký được cho đến khi admin config | Seed file line 208: `FALSE` cho SmartCA |
| T-14-02-03 | Tampering | Accepted — warning comment trong seed hướng dẫn UPDATE manual | Seed dòng 187-192 |
| T-14-02-04 | Information Disclosure | README chỉ reference `.env.dev-creds`, không hardcode | `grep -c 'ZjA4MjE4NDg-MjU3Mi00ZDAw' README.md` = 0 |
| T-14-02-05 | Denial of Service | Accepted — ưu tiên security over UX convenience | README section hướng dẫn rõ admin config |
| T-14-02-06 | Repudiation | README explicit "KHÔNG commit .env.dev-creds vào git" | README.md dòng 187-188 |
| T-14-02-07 | Spoofing | Accepted — base_url config bởi admin RBAC | Không phải seed threat |

## Self-Check: PASSED

**Files modified (2):**
- `e_office_app_new/database/seed/001_required_data.sql` → exists, 233 lines, warning comment + 2 provider blocks ✓
- `deploy/README.md` → exists, 198 lines, `## Development setup sau reset-db` section at line 172 ✓

**Commits exist in git log:**
- `c102ab4` → FOUND ✓
- `804bd03` → FOUND ✓

**Acceptance grep all pass:**
- Seed file: 8/8 checks ✓
- README: 11/11 checks ✓

**Runtime smoke test:**
- `docker exec qlvb_postgres psql -f seed/001_required_data.sql` → exit 0, NOTICE message updated ✓

## Known Stubs

None. Provider rows intentionally disabled (is_active=FALSE) by design — this is the feature, not a stub. Admin configures via `/ky-so/cau-hinh` UI (existing, working, from Phase 9).
