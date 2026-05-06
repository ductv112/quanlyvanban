/**
 * sync-to-excel.ts — Sync test results to Excel template (Plan 21-05 RPT-01)
 *
 * Pipeline:
 *   1. Read Playwright JSON (tests/results/playwright-results.json)
 *   2. Read Vitest JSON (e_office_app_new/backend/tests/results/vitest-{integration,unit}.json) — optional
 *   3. Parse test titles → extract TC-ID via regex `^(TC-[A-Z0-9-]+)`
 *   4. Open Excel template (docs/hdsd/20260505_Testcase_QLVB_V2.xlsx)
 *   5. For each row, lookup TC-ID in column A → fill 5 new columns:
 *      - Trạng thái (Pass/Fail/Skip/Not run) + cell color
 *      - Run date (yyyy-mm-dd)
 *      - Duration (Nms or Ns)
 *      - Error msg (only Fail, 200 char first)
 *      - Trace link (only Fail E2E)
 *   6. Write output: docs/hdsd/<YYYYMMDD>_Testcase_QLVB_V2_results.xlsx
 *   7. Print coverage report stdout
 *   8. Warn TC in test ↔ TC in Excel mismatches
 *
 * Usage:
 *   tsx sync-to-excel.ts                          # default paths
 *   tsx sync-to-excel.ts --help                   # print help
 *   PLAYWRIGHT_RESULTS=./custom.json tsx sync-to-excel.ts
 */

import ExcelJS from 'exceljs';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..', '..');

// Help flag
if (process.argv.includes('--help') || process.argv.includes('-h')) {
  console.log(`
sync-to-excel.ts — Sync test results to Excel template

Usage:
  tsx sync-to-excel.ts [flags]

Flags:
  --help, -h            Show this help

Environment variables:
  PLAYWRIGHT_RESULTS    Path to Playwright JSON results
                        (default: tests/results/playwright-results.json)
  VITEST_INTEGRATION_RESULTS  Path to Vitest integration JSON
                        (default: e_office_app_new/backend/tests/results/vitest-integration.json)
  VITEST_UNIT_RESULTS   Path to Vitest unit JSON
                        (default: e_office_app_new/backend/tests/results/vitest-unit.json)
  EXCEL_TEMPLATE        Path to Excel template (.xlsx)
                        (default: docs/hdsd/20260505_Testcase_QLVB_V2.xlsx)
  OUTPUT_DIR            Output directory
                        (default: docs/hdsd/)

Output:
  <OUTPUT_DIR>/<YYYYMMDD>_Testcase_QLVB_V2_results.xlsx

Coverage report (stdout):
  Total TC trong Excel: <N>
  Mapped (auto coverage): <X> (<Y>%)
    Pass: <P>
    Fail: <F>
    Skip: <S>
  Not run: <N>
`);
  process.exit(0);
}

const PLAYWRIGHT_RESULTS =
  process.env.PLAYWRIGHT_RESULTS ||
  path.join(REPO_ROOT, 'tests', 'results', 'playwright-results.json');
const VITEST_INTEGRATION_RESULTS =
  process.env.VITEST_INTEGRATION_RESULTS ||
  path.join(
    REPO_ROOT,
    'e_office_app_new',
    'backend',
    'tests',
    'results',
    'vitest-integration.json'
  );
const VITEST_UNIT_RESULTS =
  process.env.VITEST_UNIT_RESULTS ||
  path.join(REPO_ROOT, 'e_office_app_new', 'backend', 'tests', 'results', 'vitest-unit.json');
const EXCEL_TEMPLATE =
  process.env.EXCEL_TEMPLATE ||
  path.join(REPO_ROOT, 'docs', 'hdsd', '20260505_Testcase_QLVB_V2.xlsx');
const OUTPUT_DIR = process.env.OUTPUT_DIR || path.join(REPO_ROOT, 'docs', 'hdsd');

interface TestResult {
  tcId: string;
  status: 'Pass' | 'Fail' | 'Skip';
  duration: number; // ms
  error?: string;
  traceUrl?: string;
}

const TC_ID_REGEX = /^(TC-[A-Z0-9-]+)/;

// ARGB colors for cell fill (alpha + RGB)
const COLOR = {
  PASS: 'FFB7E1CD', // pastel green
  FAIL: 'FFFFB6B6', // pastel red
  SKIP: 'FFFFE699', // pastel yellow
  NOT_RUN: 'FFD9D9D9', // pastel gray
};

interface PlaywrightSpec {
  title?: string;
  tests?: Array<{
    results?: Array<{
      status?: string;
      duration?: number;
      error?: { message?: string };
      attachments?: Array<{ name?: string; path?: string }>;
    }>;
  }>;
}

interface PlaywrightSuite {
  suites?: PlaywrightSuite[];
  specs?: PlaywrightSpec[];
}

function parsePlaywrightJson(filePath: string): TestResult[] {
  if (!fs.existsSync(filePath)) {
    console.warn(`[sync] Playwright results file missing: ${filePath} — skipping`);
    return [];
  }
  let raw: { suites?: PlaywrightSuite[] };
  try {
    raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    console.warn(`[sync] Failed to parse Playwright JSON ${filePath}: ${(e as Error).message}`);
    return [];
  }

  const results: TestResult[] = [];

  function walkSuite(suite: PlaywrightSuite): void {
    (suite.suites || []).forEach((s) => walkSuite(s));
    (suite.specs || []).forEach((spec) => {
      const title = spec.title || '';
      const m = title.match(TC_ID_REGEX);
      if (!m) return;
      const tcId = m[1];

      const test = spec.tests?.[0];
      const result = test?.results?.[0];
      if (!result) {
        results.push({ tcId, status: 'Skip', duration: 0 });
        return;
      }
      const status: 'Pass' | 'Fail' | 'Skip' =
        result.status === 'passed'
          ? 'Pass'
          : result.status === 'skipped'
            ? 'Skip'
            : 'Fail';
      const trace = result.attachments?.find((a) => a.name === 'trace');
      results.push({
        tcId,
        status,
        duration: result.duration || 0,
        error:
          status === 'Fail' ? (result.error?.message || '').slice(0, 200) : undefined,
        traceUrl: trace?.path,
      });
    });
  }

  (raw.suites || []).forEach((s) => walkSuite(s));
  return results;
}

interface VitestAssertion {
  title?: string;
  fullName?: string;
  status?: string;
  duration?: number;
  failureMessages?: string[];
}

interface VitestTestResult {
  assertionResults?: VitestAssertion[];
}

function parseVitestJson(filePath: string): TestResult[] {
  if (!fs.existsSync(filePath)) {
    console.warn(`[sync] Vitest results file missing: ${filePath} — skipping`);
    return [];
  }
  let raw: { testResults?: VitestTestResult[] };
  try {
    raw = JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (e) {
    console.warn(`[sync] Failed to parse Vitest JSON ${filePath}: ${(e as Error).message}`);
    return [];
  }
  const results: TestResult[] = [];

  (raw.testResults || []).forEach((tr) => {
    (tr.assertionResults || []).forEach((ar) => {
      const title = ar.fullName || ar.title || '';
      const m = title.match(TC_ID_REGEX);
      if (!m) return;
      const tcId = m[1];
      const status: 'Pass' | 'Fail' | 'Skip' =
        ar.status === 'passed' ? 'Pass' : ar.status === 'skipped' ? 'Skip' : 'Fail';
      results.push({
        tcId,
        status,
        duration: ar.duration || 0,
        error:
          status === 'Fail' ? (ar.failureMessages?.[0] || '').slice(0, 200) : undefined,
      });
    });
  });
  return results;
}

function formatDuration(ms: number): string {
  if (ms < 1000) return `${Math.round(ms)}ms`;
  return `${(ms / 1000).toFixed(1)}s`;
}

function statusFillColor(status: 'Pass' | 'Fail' | 'Skip' | 'Not run'): string {
  if (status === 'Pass') return COLOR.PASS;
  if (status === 'Fail') return COLOR.FAIL;
  if (status === 'Skip') return COLOR.SKIP;
  return COLOR.NOT_RUN;
}

async function syncToExcel(): Promise<void> {
  if (!fs.existsSync(EXCEL_TEMPLATE)) {
    throw new Error(`Excel template not found: ${EXCEL_TEMPLATE}`);
  }
  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  // Aggregate results (Playwright wins ties)
  const allResults = new Map<string, TestResult>();
  for (const r of parsePlaywrightJson(PLAYWRIGHT_RESULTS)) allResults.set(r.tcId, r);
  for (const r of parseVitestJson(VITEST_INTEGRATION_RESULTS)) {
    if (!allResults.has(r.tcId)) allResults.set(r.tcId, r);
  }
  for (const r of parseVitestJson(VITEST_UNIT_RESULTS)) {
    if (!allResults.has(r.tcId)) allResults.set(r.tcId, r);
  }

  console.log(`[sync] Parsed ${allResults.size} test results`);

  // Open Excel template
  const wb = new ExcelJS.Workbook();
  await wb.xlsx.readFile(EXCEL_TEMPLATE);
  const sheet = wb.worksheets[0];
  if (!sheet) throw new Error('No worksheet found in template');

  // Find header row + TC-ID column
  const headerRow = sheet.getRow(1);
  let tcIdCol = -1;
  headerRow.eachCell((cell, colNumber) => {
    const v = String(cell.value || '').toLowerCase();
    if (
      v.includes('tc-id') ||
      v === 'tc id' ||
      v === 'mã tc' ||
      v.includes('test case id') ||
      v.includes('mã test') ||
      v === 'id'
    ) {
      if (tcIdCol === -1) tcIdCol = colNumber;
    }
  });
  if (tcIdCol === -1) tcIdCol = 1; // fallback to column A
  console.log(`[sync] TC-ID column = ${tcIdCol}`);

  // Add 5 new columns after last column
  const lastCol = sheet.actualColumnCount;
  const STATUS_COL = lastCol + 1;
  const RUN_DATE_COL = lastCol + 2;
  const DURATION_COL = lastCol + 3;
  const ERROR_COL = lastCol + 4;
  const TRACE_COL = lastCol + 5;

  headerRow.getCell(STATUS_COL).value = 'Trạng thái';
  headerRow.getCell(RUN_DATE_COL).value = 'Run date';
  headerRow.getCell(DURATION_COL).value = 'Duration';
  headerRow.getCell(ERROR_COL).value = 'Error msg';
  headerRow.getCell(TRACE_COL).value = 'Trace link';

  // Bold header for new columns
  for (const col of [STATUS_COL, RUN_DATE_COL, DURATION_COL, ERROR_COL, TRACE_COL]) {
    headerRow.getCell(col).font = { bold: true };
  }

  // Iterate rows (start row 2)
  let totalTC = 0;
  let mappedCount = 0;
  let passCount = 0;
  let failCount = 0;
  let skipCount = 0;
  let notRunCount = 0;
  const today = new Date().toISOString().slice(0, 10);

  const lastRow = sheet.actualRowCount;
  for (let rowIdx = 2; rowIdx <= lastRow; rowIdx++) {
    const row = sheet.getRow(rowIdx);
    const tcIdCell = row.getCell(tcIdCol);
    const tcIdValue = String(tcIdCell.value || '').trim();
    if (!tcIdValue || !TC_ID_REGEX.test(tcIdValue)) continue;
    totalTC++;

    const result = allResults.get(tcIdValue);
    const statusCell = row.getCell(STATUS_COL);

    if (!result) {
      statusCell.value = 'Not run';
      statusCell.fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: statusFillColor('Not run') },
      };
      notRunCount++;
      continue;
    }

    mappedCount++;
    statusCell.value = result.status;
    statusCell.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: statusFillColor(result.status) },
    };
    row.getCell(RUN_DATE_COL).value = today;
    row.getCell(DURATION_COL).value = formatDuration(result.duration);

    if (result.status === 'Pass') passCount++;
    else if (result.status === 'Skip') skipCount++;
    else {
      failCount++;
      row.getCell(ERROR_COL).value = result.error || '';
      row.getCell(TRACE_COL).value = result.traceUrl || '';
    }
  }

  // Coverage report stdout
  const coverage = totalTC > 0 ? ((mappedCount / totalTC) * 100).toFixed(1) : '0.0';
  console.log('');
  console.log('='.repeat(60));
  console.log(`Total TC trong Excel: ${totalTC}`);
  console.log(`Mapped (auto coverage): ${mappedCount} (${coverage}%)`);
  console.log(`  Pass: ${passCount}`);
  console.log(`  Fail: ${failCount}`);
  console.log(`  Skip: ${skipCount}`);
  console.log(`Not run: ${notRunCount}`);
  console.log('='.repeat(60));

  // Warn TC in test but not in Excel
  const excelTcIds = new Set<string>();
  for (let i = 2; i <= lastRow; i++) {
    const v = String(sheet.getRow(i).getCell(tcIdCol).value || '').trim();
    if (v && TC_ID_REGEX.test(v)) excelTcIds.add(v);
  }
  let orphanCount = 0;
  for (const [tcId] of allResults) {
    if (!excelTcIds.has(tcId)) {
      if (orphanCount < 10) {
        console.warn(`[sync] WARN: TC ${tcId} có trong test nhưng KHÔNG có trong Excel template`);
      }
      orphanCount++;
    }
  }
  if (orphanCount > 10) {
    console.warn(`[sync] ... and ${orphanCount - 10} more orphan TC IDs`);
  }

  // Write output
  const dateStr = today.replace(/-/g, '');
  const outputPath = path.join(OUTPUT_DIR, `${dateStr}_Testcase_QLVB_V2_results.xlsx`);
  await wb.xlsx.writeFile(outputPath);
  console.log(`[sync] Written: ${outputPath}`);
}

syncToExcel().catch((e: Error) => {
  console.error('[sync] FATAL:', e.message || e);
  process.exit(1);
});
