# tools/test-report — Excel Sync Tool

Sync test results (Playwright + Vitest JSON) → Excel template với 5 cột status mới.

**Plan:** 21-05 RPT-01

## Quick Start

```bash
cd tools/test-report
npm install
npm run sync
```

Output: `docs/hdsd/<YYYYMMDD>_Testcase_QLVB_V2_results.xlsx`

## Pipeline

1. Đọc Playwright JSON results (`tests/results/playwright-results.json`)
2. Đọc Vitest JSON (integration + unit) — optional
3. Parse test titles → extract TC-ID via regex `^(TC-[A-Z0-9-]+)`
4. Mở Excel template (`docs/hdsd/20260505_Testcase_QLVB_V2.xlsx`)
5. Map TC-ID column A → fill 5 cột mới + tô màu status:
   - **Trạng thái** (Pass=green, Fail=red, Skip=yellow, Not run=gray)
   - **Run date** (yyyy-mm-dd)
   - **Duration** (`Nms` hoặc `Ns` nếu > 1s)
   - **Error msg** (chỉ Fail, 200 ký tự đầu)
   - **Trace link** (chỉ Fail E2E)
6. Write output Excel
7. Print coverage report stdout

## Customize via env vars

```bash
PLAYWRIGHT_RESULTS=./custom/pw.json \
EXCEL_TEMPLATE=./custom/template.xlsx \
OUTPUT_DIR=./reports \
npm run sync
```

## Help

```bash
npx tsx sync-to-excel.ts --help
```

## Coverage report sample

```
============================================================
Total TC trong Excel: 847
Mapped (auto coverage): 30 (3.5%)
  Pass: 28
  Fail: 1
  Skip: 1
Not run: 817
============================================================
```

## Future work

- **RPT-05 (Phase 22):** Coverage drop alert — if `mapped < previous` → fail CI.
- **RPT-04 (Phase 22):** HTML dashboard generation alongside Excel.
- **Slack/Teams webhook (Phase 22):** Push coverage delta to chatops.
