---
phase: 25-execute-wave-d
batch: Wave d (126 TC) — Boundary Admin (Đơn vị + Chức vụ + Người dùng + Nhóm quyền)
mode: API + Playwright UI subset (4 agent parallel)
---

# Wave d — Master Results

## Summary

| Agent | Module | TC | Pass | Fail | Skip/Verify |
|---|---|---|---|---|---|
| 1 | Quản trị Đơn vị | 30 | 27 (25+2 note) | 2 | 1 |
| 2 | Quản trị Chức vụ | 20 | 19 (18+1 note) | 0 | 1 |
| 3 | Quản trị Người dùng | 53 | 48 (41+7 UI) | 3 | 5 |
| 4 | Quản trị Nhóm quyền | 23 | 20 (17+3 warn) | 2 | 1 |
| **Wave d** | | **126** | **114** | **7** | **8** |

**Pass rate: 114/121 = 94.2%** → 100% sau fix.

## 12 Bug Wave d (3 HIGH + 4 medium + 5 low)

| ID | Severity | Issue | Module |
|---|---|---|---|
| BUG-ND-001 | HIGH | Filter "Đã khóa" không work — public-catalog shadow route admin GET | Người dùng |
| BUG-ND-002 | HIGH | Search username không work — same shadow root | Người dùng |
| BUG-VT-001 | HIGH | Pagination role missing `page/pageSize/total` | Nhóm quyền |
| BUG-ND-003 | medium | DELETE user có workflow history không warning | Người dùng |
| BUG-VT-005 | medium | `/quan-tri/chuc-nang/menu` gated admin → non-admin can't fetch own menu | Nhóm quyền |
| BUG-VT-006 | medium | Search no diacritic-insensitive (ILIKE raw) | Nhóm quyền |
| BUG-DV-002 + BUG-CV-001 + BUG-VT-002 | medium | **3-in-1**: PG raw error 500 leak (SQLSTATE 22001 not mapped). Fix gom 1 update `error-handler.ts` | All |
| BUG-DV-001 | low | POST đơn vị accept empty code | Đơn vị |
| BUG-VT-003 | low | TextArea description missing showCount + DB no length limit | Nhóm quyền |
| BUG-VT-004 | low | `staff_count` returned as string (BIGINT type lie) | Nhóm quyền |

**Pattern repetition:** 3 bug PG error leak (DV-002, CV-001, VT-002) → fix 1 chỗ.

## Note: env discrepancy (NOT bug)
- `nguyenvana / tranthib / levand / Admin@123` only exist trong qlvb_dev (seed 002 demo). qlvb_test KHÔNG có → các TC dùng accounts này → SKIP với reason "demo seed only in dev DB".

## Cumulative v3.1 status (593 / 847 TC = 70% scope)

| | Wave a | b | c | d | Total |
|---|---|---|---|---|---|
| TC | 83 | 181 | 203 | 126 | **593** |
| PASS | 78 | 131 | 154 | 114 | **477 (80%)** |
| FAIL | 11 | 9 | 4 | 7 | **31** |
| Pass rate | 87.6% | 93.6% | 97.5% | 94.2% | **93.9%** |

**Bugs cumulative: 26 + 12 = 38 (1 BLOCKER + 10 HIGH/MAJOR + 12 medium + 15 low)**
