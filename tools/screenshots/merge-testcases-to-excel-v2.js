// Merge 9 wave JSON testcases (A-I) → Excel xlsx file v2 (date-versioned).
//
// Output: docs/hdsd/20260505_Testcase_QLVB_V2.xlsx
// Wave A-E: 668 TC chuẩn theo HDSD_full.md
// Wave F-I: ~180 TC bổ sung lấp gap (Boundary 97, Permission 50, E2E 19, Concurrent 13)
//
// Sheets:
//   1. "Tóm tắt" — module list + count by category (incl. E2E, Concurrent)
//   2. "Test cases" — all TC, formatted, freeze header, AutoFilter

const fs = require('fs');
const path = require('path');
const ExcelJS = require('exceljs');

const ROOT = path.resolve(__dirname, '../..');
const TC_DIR = path.resolve(__dirname);
const OUT = path.join(ROOT, 'docs/hdsd/20260505_Testcase_QLVB_V2.xlsx');

const WAVE_FILES = [
  'testcases-wave-a.json',
  'testcases-wave-b.json',
  'testcases-wave-c.json',
  'testcases-wave-d.json',
  'testcases-wave-e.json',
  'testcases-wave-f.json',
  'testcases-wave-g.json',
  'testcases-wave-h.json',
  'testcases-wave-i.json',
];

function deriveModuleFromTC(tc, moduleObj) {
  // 1. Explicit module on TC wins (used by wave-A/B/C/F flat arrays)
  if (tc.module) return tc.module;

  // 2. ID prefix lookup — returns diacritic-correct module name.
  // This MUST come before moduleObj fallback because some legacy waves (D/E)
  // store module names without diacritics ("Quan tri Don vi") which won't match
  // moduleOrder entries ("Quản trị Đơn vị") and would be silently dropped from summary.
  const m = (tc.id || '').match(/^TC-([A-Z]+)-/);
  const prefix = m ? m[1] : null;
  const idMap = {
    AUTH: 'Đăng nhập và Thông tin cá nhân',
    DASH: 'Tổng quan (Dashboard)',
    NOTIF: 'Thông báo nội bộ',
    MARK: 'Đánh dấu cá nhân',
    VBD: 'Văn bản đến',
    VBI: 'Văn bản đi',
    VBT: 'Văn bản dự thảo',
    CHGN: 'Cấu hình gửi nhanh',
    HSCV: 'Hồ sơ công việc',
    KSCH: 'Cấu hình ký số hệ thống',
    KSTK: 'Tài khoản ký số cá nhân',
    KSDS: 'Danh sách ký số',
    QTDV: 'Quản trị Đơn vị',
    QTCV: 'Quản trị Chức vụ',
    QTND: 'Quản trị Người dùng',
    QTNQ: 'Quản trị Nhóm quyền',
    DMSV: 'Danh mục Sổ văn bản',
    DMLV: 'Danh mục Loại văn bản',
    DMLN: 'Danh mục Lĩnh vực',
    DMNK: 'Danh mục Người ký',
  };
  if (prefix && idMap[prefix]) return idMap[prefix];

  // 3. moduleObj fallback (used by wave-G/H/I nested with diacritic-correct names)
  if (moduleObj && moduleObj.module_name) return moduleObj.module_name;
  if (moduleObj && moduleObj.name) return moduleObj.name;
  if (moduleObj && moduleObj.module) return moduleObj.module;

  return prefix || '';
}

function normalizeTC(raw, moduleObj) {
  return {
    id: raw.id || '',
    module: deriveModuleFromTC(raw, moduleObj),
    screen: raw.screen || (moduleObj && (moduleObj.screen || moduleObj.module_name)) || '',
    category: raw.category || raw.type || '',
    priority: raw.priority || 'Medium',
    title: raw.title || '',
    preconditions: raw.preconditions || '',
    steps: Array.isArray(raw.steps) ? raw.steps.join('\n') : (raw.steps || ''),
    expected: raw.expected || raw.expected_result || '',
    notes: raw.notes || '',
  };
}

const allTCs = [];
for (const f of WAVE_FILES) {
  const fp = path.join(TC_DIR, f);
  if (!fs.existsSync(fp)) {
    console.warn(`[!] Missing: ${f}`);
    continue;
  }
  const data = JSON.parse(fs.readFileSync(fp, 'utf8'));
  if (Array.isArray(data)) {
    for (const tc of data) allTCs.push(normalizeTC(tc, null));
  } else if (data.modules) {
    for (const mod of data.modules) {
      for (const tc of (mod.testcases || [])) allTCs.push(normalizeTC(tc, mod));
    }
  }
  console.log(`  Loaded ${f}`);
}

console.log(`\nTotal TC: ${allTCs.length}`);

// 20 standard modules + 11 cross-cutting groups (Permission/E2E/Concurrent)
const moduleOrder = [
  // Wave A-E: Functional modules
  'Đăng nhập và Thông tin cá nhân',
  'Tổng quan (Dashboard)',
  'Thông báo nội bộ',
  'Văn bản đến',
  'Văn bản đi',
  'Văn bản dự thảo',
  'Đánh dấu cá nhân',
  'Cấu hình gửi nhanh',
  'Hồ sơ công việc',
  'Cấu hình ký số hệ thống',
  'Tài khoản ký số cá nhân',
  'Danh sách ký số',
  'Quản trị Đơn vị',
  'Quản trị Chức vụ',
  'Quản trị Người dùng',
  'Quản trị Nhóm quyền',
  'Danh mục Sổ văn bản',
  'Danh mục Loại văn bản',
  'Danh mục Lĩnh vực',
  'Danh mục Người ký',
  // Wave G: Permission cross-cutting
  'Permission - Cross-unit Isolation',
  'Permission - Role Matrix',
  'Permission - Token & Session',
  // Wave H: E2E workflows
  'E2E - Core Document Flow',
  'E2E - HSCV Workflow',
  'E2E - Notification & Audit',
  'E2E - Integration External',
  'E2E - Multi-Role Journey',
  // Wave I: Concurrent
  'Concurrent - Session & Token',
  'Concurrent - Race conditions',
  'Concurrent - Performance',
];

allTCs.sort((a, b) => {
  const ma = moduleOrder.indexOf(a.module);
  const mb = moduleOrder.indexOf(b.module);
  if (ma !== mb) return (ma === -1 ? 999 : ma) - (mb === -1 ? 999 : mb);
  return a.id.localeCompare(b.id);
});

// Build summary
const summary = {};
for (const tc of allTCs) {
  if (!summary[tc.module]) {
    summary[tc.module] = { total: 0, byCategory: {}, byPriority: {} };
  }
  summary[tc.module].total++;
  const cat = tc.category || 'Other';
  const pri = tc.priority || 'Medium';
  summary[tc.module].byCategory[cat] = (summary[tc.module].byCategory[cat] || 0) + 1;
  summary[tc.module].byPriority[pri] = (summary[tc.module].byPriority[pri] || 0) + 1;
}

// === Build Excel ===
console.log('\nBuilding Excel...');
const wb = new ExcelJS.Workbook();
wb.creator = 'QLVB Team';
wb.created = new Date();
wb.title = 'Bộ Test case e-Office QLVB V2 — Phiên bản 20260505 (lấp gap Boundary/Permission/E2E/Concurrent)';

// Sheet 1: Tóm tắt
const s1 = wb.addWorksheet('Tóm tắt', { views: [{ state: 'frozen', ySplit: 1 }] });
s1.columns = [
  { header: 'STT', key: 'stt', width: 5 },
  { header: 'Module / Nhóm', key: 'module', width: 38 },
  { header: 'Tổng TC', key: 'total', width: 9 },
  { header: 'Positive', key: 'positive', width: 10 },
  { header: 'Negative', key: 'negative', width: 10 },
  { header: 'Boundary', key: 'boundary', width: 10 },
  { header: 'UI', key: 'ui', width: 7 },
  { header: 'Permission', key: 'permission', width: 11 },
  { header: 'E2E', key: 'e2e', width: 7 },
  { header: 'Concurrent', key: 'concurrent', width: 11 },
  { header: 'Khác', key: 'other', width: 8 },
  { header: 'High', key: 'high', width: 7 },
  { header: 'Medium', key: 'medium', width: 9 },
  { header: 'Low', key: 'low', width: 7 },
];
const s1Header = s1.getRow(1);
s1Header.font = { bold: true, color: { argb: 'FFFFFFFF' } };
s1Header.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1B3A5C' } };
s1Header.alignment = { vertical: 'middle', horizontal: 'center' };
s1Header.height = 28;

let stt = 1;
const sums = { total: 0, pos: 0, neg: 0, bnd: 0, ui: 0, perm: 0, e2e: 0, conc: 0, other: 0, high: 0, med: 0, low: 0 };

for (const mod of moduleOrder) {
  if (!summary[mod]) continue;
  const s = summary[mod];
  const cat = s.byCategory;
  const pri = s.byPriority;
  const pos = cat.Positive || 0;
  const neg = cat.Negative || 0;
  const bnd = cat.Boundary || 0;
  const ui = cat.UI || 0;
  const perm = cat.Permission || 0;
  const e2e = cat.E2E || 0;
  const conc = cat.Concurrent || 0;
  const other = s.total - pos - neg - bnd - ui - perm - e2e - conc;
  const row = s1.addRow({
    stt: stt++,
    module: mod,
    total: s.total,
    positive: pos,
    negative: neg,
    boundary: bnd,
    ui,
    permission: perm,
    e2e,
    concurrent: conc,
    other,
    high: pri.High || 0,
    medium: pri.Medium || 0,
    low: pri.Low || 0,
  });
  // Highlight cross-cutting groups (rows 21+)
  if (mod.startsWith('Permission - ') || mod.startsWith('E2E - ') || mod.startsWith('Concurrent - ')) {
    row.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFF5F9FC' } };
  }
  sums.total += s.total;
  sums.pos += pos; sums.neg += neg; sums.bnd += bnd;
  sums.ui += ui; sums.perm += perm; sums.e2e += e2e; sums.conc += conc; sums.other += other;
  sums.high += pri.High || 0; sums.med += pri.Medium || 0; sums.low += pri.Low || 0;
}

const totalRow = s1.addRow({
  stt: '',
  module: 'TỔNG CỘNG',
  total: sums.total,
  positive: sums.pos,
  negative: sums.neg,
  boundary: sums.bnd,
  ui: sums.ui,
  permission: sums.perm,
  e2e: sums.e2e,
  concurrent: sums.conc,
  other: sums.other,
  high: sums.high,
  medium: sums.med,
  low: sums.low,
});
totalRow.font = { bold: true };
totalRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E7EF' } };

// Borders sheet 1
s1.eachRow({ includeEmpty: false }, (row) => {
  row.eachCell({ includeEmpty: false }, (cell) => {
    cell.border = {
      top: { style: 'thin', color: { argb: 'FF808080' } },
      left: { style: 'thin', color: { argb: 'FF808080' } },
      bottom: { style: 'thin', color: { argb: 'FF808080' } },
      right: { style: 'thin', color: { argb: 'FF808080' } },
    };
  });
});

// Sheet 2: Test cases
const s2 = wb.addWorksheet('Test cases', {
  views: [{ state: 'frozen', ySplit: 1 }],
});
s2.columns = [
  { header: 'TC ID', key: 'id', width: 16 },
  { header: 'Module / Nhóm', key: 'module', width: 30 },
  { header: 'Màn hình', key: 'screen', width: 28 },
  { header: 'Loại', key: 'category', width: 12 },
  { header: 'Mức độ', key: 'priority', width: 9 },
  { header: 'Tiêu đề testcase', key: 'title', width: 50 },
  { header: 'Tiền điều kiện', key: 'preconditions', width: 40 },
  { header: 'Các bước thực hiện', key: 'steps', width: 50 },
  { header: 'Kết quả mong đợi', key: 'expected', width: 50 },
  { header: 'Kết quả thực tế', key: 'actual', width: 30 },
  { header: 'Trạng thái', key: 'status', width: 12 },
  { header: 'Ghi chú', key: 'notes', width: 25 },
];
const s2Header = s2.getRow(1);
s2Header.font = { bold: true, color: { argb: 'FFFFFFFF' } };
s2Header.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1B3A5C' } };
s2Header.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
s2Header.height = 28;

const CAT_COLOR = {
  Positive: 'FFE6F4EA',
  Negative: 'FFFCE8E6',
  Boundary: 'FFFFF4CE',
  UI: 'FFEAF1FB',
  Permission: 'FFF3E5F5',
  E2E: 'FFFFE0B2',
  Concurrent: 'FFD7CCC8',
};

for (const tc of allTCs) {
  const row = s2.addRow({
    id: tc.id,
    module: tc.module,
    screen: tc.screen,
    category: tc.category,
    priority: tc.priority,
    title: tc.title,
    preconditions: tc.preconditions,
    steps: tc.steps,
    expected: tc.expected,
    actual: '',
    status: '',
    notes: tc.notes,
  });
  row.alignment = { vertical: 'top', wrapText: true };
  if (tc.priority === 'High') row.getCell('priority').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFE5E5' } };
  else if (tc.priority === 'Low') row.getCell('priority').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE8F5E9' } };
  const catColor = CAT_COLOR[tc.category];
  if (catColor) row.getCell('category').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: catColor } };
}

// Borders + AutoFilter sheet 2
s2.eachRow({ includeEmpty: false }, (row) => {
  row.eachCell({ includeEmpty: false }, (cell) => {
    cell.border = {
      top: { style: 'thin', color: { argb: 'FF808080' } },
      left: { style: 'thin', color: { argb: 'FF808080' } },
      bottom: { style: 'thin', color: { argb: 'FF808080' } },
      right: { style: 'thin', color: { argb: 'FF808080' } },
    };
  });
});
s2.autoFilter = {
  from: { row: 1, column: 1 },
  to: { row: allTCs.length + 1, column: s2.columns.length },
};

// Status dropdown
const statusCol = s2.getColumn('status');
for (let r = 2; r <= allTCs.length + 1; r++) {
  s2.getCell(r, statusCol.number).dataValidation = {
    type: 'list',
    allowBlank: true,
    formulae: ['"Pass,Fail,Blocked,N/A"'],
  };
}

// Save
wb.xlsx.writeFile(OUT).then(() => {
  const stats = fs.statSync(OUT);
  console.log(`\n✓ Saved: ${OUT}`);
  console.log(`  Size: ${(stats.size / 1024).toFixed(0)} KB`);
  console.log(`  Total testcase: ${allTCs.length}`);
  console.log(`  Modules / groups: ${Object.keys(summary).length}`);
  console.log('\n  Category breakdown:');
  console.log(`    Positive:   ${sums.pos}`);
  console.log(`    Negative:   ${sums.neg}`);
  console.log(`    Boundary:   ${sums.bnd}`);
  console.log(`    UI:         ${sums.ui}`);
  console.log(`    Permission: ${sums.perm}`);
  console.log(`    E2E:        ${sums.e2e}`);
  console.log(`    Concurrent: ${sums.conc}`);
  console.log(`    Khác:       ${sums.other}`);
  console.log('\n  Priority breakdown:');
  console.log(`    High:   ${sums.high}`);
  console.log(`    Medium: ${sums.med}`);
  console.log(`    Low:    ${sums.low}`);
});
