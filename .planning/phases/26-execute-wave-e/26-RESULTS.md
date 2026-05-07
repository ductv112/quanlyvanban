---
phase: 26-execute-wave-e
batch: Wave e (75 TC) — Danh mục (Sổ VB + Loại VB + Lĩnh vực + Người ký)
mode: API + Playwright UI subset (4 agent parallel)
---

# Wave e — Master Results

| Agent | Module | TC | Pass | Fail |
|---|---|---|---|---|
| 1 | Sổ văn bản | 22 | 16 (+2 warn) | 4 |
| 2 | Loại văn bản | 20 | 11 | 5 |
| 3 | Lĩnh vực | 15 | 11 | 4 |
| 4 | Người ký | 18 | 13 (+2 partial) | 2 |
| **Wave e** | | **75** | **51** | **17** (7 misc) |

**Pass rate: 51/68 = 75%** — thấp hơn Wave d vì discover architectural bug shadowing.

## 🔴 BUG-CATALOG-SHADOW (CRITICAL ROOT CAUSE)

**File:** `e_office_app_new/backend/src/server.ts:72-74`
**Problem:** `publicCatalogRoutes` mount BEFORE `adminCatalogRoutes` cùng prefix `/api/quan-tri`. Express first-match wins → admin routes bị shadow.
**Impact:** Public routes chỉ trả subset fields + hardcoded filter `is_active=true`/`is_locked=false` → admin UI hiển thị thiếu data + không filter được.

**1-line fix resolve 7+ bug:**
```ts
// server.ts: swap order
app.use('/api/quan-tri', authenticate, adminCatalogRoutes); // mount admin FIRST
app.use('/api/quan-tri', authenticate, publicCatalogRoutes); // public sau (override-able)
// HOẶC: rename public routes prefix '/api/quan-tri-public/*'
```

**Affected bugs (cumulative dedupe):**
- Wave d: BUG-ND-001 (filter Đã khóa) + BUG-ND-002 (search username) ← same root
- Wave e: BUG-DMSV-001 (Sổ VB columns), BUG-DMLV-001+002 (Loại VB), BUG-DMLN-001+002+003 (Lĩnh vực), BUG-DMNK-002 (dropdown rỗng)
- **Total: 9 bug cùng 1 root cause** → fix 1 lần

## Other unique bugs Wave e

| ID | Severity | Issue |
|---|---|---|
| BUG-DMSV-004 | HIGH | SP `fn_doc_book_delete` không check FK (incoming/outgoing/drafting/handling docs) → soft-delete book còn ref → orphan |
| BUG-DMLV-003 | CRITICAL | SP `fn_doc_type_delete` không check FK từ 3 docs tables → orphan |
| BUG-DMSV-002 | low | POST/PUT description > 500 chars accepted (DB TEXT no limit) |
| BUG-DMSV-003 | low | PUT accept negative sort_order |
| BUG-DMLV-004 | medium | notation_type Frontend Select string→Number()→NaN→0 fallback |
| BUG-DMNK-001 | medium | `?department_id=X` strict equality, không bao gồm sub-tree (SP có support nhưng route không pass) |
| BUG-DMNK-003 | medium | Modal Thêm mở ngay cả chưa chọn nhánh cây (FE bug) |
| BUG-DMNK-004 | low | UNIQUE constraint `(unit_id, staff_id)` — 1 NV chỉ làm signer 1 lần toàn đơn vị, không kiêm nhiệm nhiều dept |

## Cumulative v3.1 status (668 / 847 TC = 79% scope)

| | Wave a-d | Wave e | Total |
|---|---|---|---|
| TC | 593 | 75 | **668** |
| PASS | 477 | 51 | **528 (79%)** |
| FAIL | 31 | 17 | **48** |
| Pass rate | 93.9% | 75% | **91.6%** |

**Bugs cumulative: 38 + 13 = 51, sau dedupe public-catalog-shadow (-7): ~44 unique.**
