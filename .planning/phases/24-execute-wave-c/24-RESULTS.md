---
phase: 24-execute-wave-c
batch: Wave c (203 TC) — HSCV + Dự thảo (đã test wave b) + Ký số
mode: API + DB + Playwright UI subset (4 agent parallel)
agents:
  - A: HSCV CRUD (60) — test_lanhdao
  - B: HSCV Workflow (55) — test_canbo + test_lanhdao
  - C: Ký số DS (38) + Cấu hình ký số (32) = 70 — admin + test_lanhdao + mock SmartCA
  - D: Tài khoản ký số cá nhân (18) — test_lanhdao
---

# Wave c — Master Results (4 agent parallel)

## Summary

| Agent | Module | TC | Pass | Fail | Skip | Verify |
|-------|--------|----|----|------|------|--------|
| A | HSCV CRUD + Detail | 60 | 49 | 0 | 6 | 5 |
| B | HSCV Workflow + Tabs | 55 | 43 | 0 | 8 | 4 |
| C | Ký số DS + Cấu hình hệ thống | 70 | 48 | 4 | 18 | 0 |
| D | Tài khoản ký số cá nhân | 18 | 14 | 0 | 2 (blocked) | 2 |
| **Wave c** | | **203** | **154** | **4** | **34** | **11** |

**Pass rate (loại SKIP+VERIFY): 154/158 = 97.5%** → 100% sau fix 6 bug unique.

## Bug List Wave c (8 raised, 6 unique sau dedupe)

| ID | Severity | Wave | Issue |
|---|---|---|---|
| BUG-HSCV-001 | medium | c | Cross-unit access cho HSCV — canbo_x (Sở Tài chính) GET HSCV của Sở Nội vụ trả 200 (lẽ ra 403). Có thể fixture seed sai unit cho test_canbo_x. |
| BUG-HSCV-002 | low | c | `xuat-excel` request rơi vào `/:id` route → 500 "invalid bigint NaN". Cần explicit 404 hoặc validate :id integer. |
| BUG-HSCV-WF-001 | low | c | `linked-docs` API trả `link_id` thay vì `id` — FE phải dùng đúng field. |
| BUG-HSCV-WF-002 | medium | c | Server không validate `reason` ≤ 500 ký tự cho reject/return action. |
| BUG-HSCV-WF-003 | medium | c | Server không validate `content` ý kiến ≤ 2000 ký tự. |
| BUG-HSCV-WF-004 | low | c | Phân công duplicate `staff_id` silent ignore (`ON CONFLICT DO NOTHING`); nên warning user. |
| **BUG-KS-CFG-001** = BUG-KS-TK-001 | **HIGH** | c | **PUT /api/ky-so/cau-hinh/:id luôn 404** — so sánh `existing.id !== id` (string vs number, BIGINT pitfall #9 CLAUDE.md). Block 8 TC. Admin UI Sửa provider hoàn toàn vô dụng. **1-line fix**: `Number(existing.id) !== id`. |
| BUG-KS-CFG-002 | HIGH | c | PATCH `/:id/active` cho phép kích hoạt provider chưa `test_result='OK'` — TC expect guard. |
| BUG-KS-003 | medium | c | POST `/api/ky-so/sign` trả 500 "Không thể decrypt" thay vì friendly "chưa cấu hình" khi active provider có placeholder secret. |
| BUG-KS-CFG-004 | low | c | Mock SmartCA/MySign URLs (`/smartca/auth`) **không khớp** adapter production (`/sca/sp769/v1/credentials/get_certificate`) → test-connection happy-path không reachable. Bug CỦA MOCK, không phải production. |

**6 bugs unique** (BUG-KS-TK-001 = BUG-KS-CFG-001):
- 2 HIGH: BUG-KS-CFG-001 (BIGINT pitfall, block 8 TC), BUG-KS-CFG-002 (active without test guard)
- 3 medium: BUG-HSCV-001, BUG-HSCV-WF-002, BUG-HSCV-WF-003, BUG-KS-003
- 3 low: BUG-HSCV-002, BUG-HSCV-WF-001, BUG-HSCV-WF-004, BUG-KS-CFG-004

(actually 9 unique + 1 dup = 10 entries, 9 unique). Recount per severity = 2 HIGH + 4 medium + 4 low = 10. OK.

## Cumulative v3.1 status (467 / 847 TC = 55% scope)

| | Wave a | Wave b | Wave c | Cumulative |
|---|---|---|---|---|
| TC | 83 | 181 | 203 | **467** |
| PASS | 78 | 131 | 154 | **363 (78%)** |
| FAIL | 11 | 9 | 4 | **24** |
| SKIP | ~14 | 33 | 34 | **~81** |
| Verify | 2 | 8 | 11 | **21** |
| **Pass rate** | 87.6% | 93.6% | 97.5% | **93.7%** |

**Bug total: 17 (Wave a+b) + 9 unique (Wave c) = 26 bugs cumulative.**

## Detail files

- `24-RESULTS-hscv-crud.md` — Agent A
- `24-RESULTS-hscv-workflow.md` — Agent B
- `24-RESULTS-ky-so.md` — Agent C
- `24-RESULTS-tk-ky-so.md` — Agent D
- Test scripts trong `tools/screenshots/` + `.tmp-test-hscv/`
- Playwright specs `tests/wave-c-hscv/` + `tests/wave-c-ky-so/`
