// Merge 5 wave JSON testcases → Excel xlsx file for tester team.
//
// Output: docs/hdsd/Testcase_QLVB_V2.xlsx
// Sheets:
//   1. "Tóm tắt" — module list + count by category
//   2. "Test cases" — all TC, formatted, freeze header, AutoFilter

const fs = require('fs');
const path = require('path');
const ExcelJS = require('exceljs');

const ROOT = path.resolve(__dirname, '../..');
const TC_DIR = path.resolve(__dirname);
const OUT = path.join(ROOT, 'docs/hdsd/Testcase_QLVB_V2.xlsx');

const WAVE_FILES = [
  'testcases-wave-a.json',
  'testcases-wave-b.json',
  'testcases-wave-c.json',
  'testcases-wave-d.json',
  'testcases-wave-e.json',
];

// Module name lookup (for wave D/E nested format which only has module slug at parent level)
function deriveModuleFromTC(tc, moduleObj) {
  // Try multiple sources
  if (tc.module) return tc.module;
  if (moduleObj && moduleObj.module_name) return moduleObj.module_name;
  if (moduleObj && moduleObj.name) return moduleObj.name;
  if (moduleObj && moduleObj.module) return moduleObj.module;
  // Fallback: derive from TC id prefix
  const m = (tc.id || '').match(/^TC-([A-Z]+)-/);
  if (!m) return '';
  const prefix = m[1];
  const map = {
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
  return map[prefix] || prefix;
}

function normalizeTC(raw, moduleObj) {
  const tc = {
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
  return tc;
}

// Collect all TCs from all waves
const allTCs = [];
for (const f of WAVE_FILES) {
  const fp = path.join(TC_DIR, f);
  if (!fs.existsSync(fp)) {
    console.warn(`[!] Missing: ${f}`);
    continue;
  }
  const data = JSON.parse(fs.readFileSync(fp, 'utf8'));
  if (Array.isArray(data)) {
    // Wave A/B/C — flat array
    for (const tc of data) allTCs.push(normalizeTC(tc, null));
  } else if (data.modules) {
    // Wave D/E — nested
    for (const mod of data.modules) {
      for (const tc of (mod.testcases || [])) allTCs.push(normalizeTC(tc, mod));
    }
  }
  console.log(`  Loaded ${f}`);
}

console.log(`\nTotal TC: ${allTCs.length}`);

// Sort by module → id
const moduleOrder = [
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
];
allTCs.sort((a, b) => {
  const ma = moduleOrder.indexOf(a.module);
  const mb = moduleOrder.indexOf(b.module);
  if (ma !== mb) return (ma === -1 ? 999 : ma) - (mb === -1 ? 999 : mb);
  return a.id.localeCompare(b.id);
});

// Build summary by module
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
wb.title = 'Bộ Test case e-Office QLVB V2';

// Sheet 1: Tóm tắt
const s1 = wb.addWorksheet('Tóm tắt', { views: [{ state: 'frozen', ySplit: 1 }] });
s1.columns = [
  { header: 'STT', key: 'stt', width: 6 },
  { header: 'Module', key: 'module', width: 35 },
  { header: 'Tổng TC', key: 'total', width: 10 },
  { header: 'Positive', key: 'positive', width: 10 },
  { header: 'Negative', key: 'negative', width: 10 },
  { header: 'Boundary', key: 'boundary', width: 10 },
  { header: 'UI', key: 'ui', width: 8 },
  { header: 'Permission', key: 'permission', width: 12 },
  { header: 'Khác', key: 'other', width: 10 },
  { header: 'High', key: 'high', width: 8 },
  { header: 'Medium', key: 'medium', width: 10 },
  { header: 'Low', key: 'low', width: 8 },
];
const s1Header = s1.getRow(1);
s1Header.font = { bold: true, color: { argb: 'FFFFFFFF' } };
s1Header.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF1B3A5C' } };
s1Header.alignment = { vertical: 'middle', horizontal: 'center' };
s1Header.height = 24;

let stt = 1;
let sumTotal = 0,
  sumPos = 0,
  sumNeg = 0,
  sumBnd = 0,
  sumUi = 0,
  sumPerm = 0,
  sumOther = 0,
  sumHigh = 0,
  sumMed = 0,
  sumLow = 0;
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
  const other = s.total - pos - neg - bnd - ui - perm;
  s1.addRow({
    stt: stt++,
    module: mod,
    total: s.total,
    positive: pos,
    negative: neg,
    boundary: bnd,
    ui: ui,
    permission: perm,
    other: other,
    high: pri.High || 0,
    medium: pri.Medium || 0,
    low: pri.Low || 0,
  });
  sumTotal += s.total;
  sumPos += pos;
  sumNeg += neg;
  sumBnd += bnd;
  sumUi += ui;
  sumPerm += perm;
  sumOther += other;
  sumHigh += pri.High || 0;
  sumMed += pri.Medium || 0;
  sumLow += pri.Low || 0;
}
const totalRow = s1.addRow({
  stt: '',
  module: 'TỔNG CỘNG',
  total: sumTotal,
  positive: sumPos,
  negative: sumNeg,
  boundary: sumBnd,
  ui: sumUi,
  permission: sumPerm,
  other: sumOther,
  high: sumHigh,
  medium: sumMed,
  low: sumLow,
});
totalRow.font = { bold: true };
totalRow.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE0E7EF' } };

// Add borders to all cells in sheet 1
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
  { header: 'TC ID', key: 'id', width: 14 },
  { header: 'Module', key: 'module', width: 28 },
  { header: 'Màn hình', key: 'screen', width: 30 },
  { header: 'Loại', key: 'category', width: 12 },
  { header: 'Mức độ', key: 'priority', width: 10 },
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
  // Color priority cell
  if (tc.priority === 'High') row.getCell('priority').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFE5E5' } };
  else if (tc.priority === 'Low') row.getCell('priority').fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFE8F5E9' } };
}

// Borders + AutoFilter for sheet 2
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

// Data validation: Status column dropdown (Pass / Fail / Blocked / N/A)
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
  console.log(`  Modules: ${Object.keys(summary).length}`);
});
