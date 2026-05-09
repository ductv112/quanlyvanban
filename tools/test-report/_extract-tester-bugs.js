// Extract toàn bộ 59 bugs + 5 đề xuất từ tester file → JSON structured
import ExcelJS from 'exceljs';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const FILE = path.join(REPO_ROOT, 'docs', 'Tester test PM Quản lý Văn Bản.xlsx');

function cellText(cell) {
  if (!cell || cell.value == null) return '';
  const v = cell.value;
  let out = '';
  if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') out = String(v);
  else if (v instanceof Date) out = v.toISOString().slice(0, 10);
  else if (v.richText) out = v.richText.map(t => t.text).join('');
  else if (v.formula !== undefined) out = String(v.result ?? '');
  else if (v.hyperlink) out = String(v.text ?? v.hyperlink ?? '');
  else if (v.text) out = String(v.text);
  return String(out).trim();
}

const wb = new ExcelJS.Workbook();
await wb.xlsx.readFile(FILE);

// === BUG sheet ===
const bugSheet = wb.worksheets.find((s) => s.name.includes('BUG'));
const bugs = [];
let bugId = 0;
for (let rowNum = 3; rowNum <= bugSheet.rowCount; rowNum++) {
  const row = bugSheet.getRow(rowNum);
  const id = cellText(row.getCell(1));
  const ngayLog = cellText(row.getCell(2));
  const uc = cellText(row.getCell(4));
  const cacBuoc = cellText(row.getCell(5));
  const bugMm = cellText(row.getCell(6));
  const minhChung = cellText(row.getCell(7));
  const trangThai = cellText(row.getCell(8));
  const ngLog = cellText(row.getCell(9));
  const uuTien = cellText(row.getCell(10));
  const feBe = cellText(row.getCell(11));
  const ghiChu = cellText(row.getCell(12));
  if (!uc || uc.length < 5) continue; // skip empty rows
  bugId++;
  bugs.push({
    bug_no: bugId,
    excel_row: rowNum,
    id_excel: id,
    date: ngayLog,
    module: uc.slice(0, 200),
    steps: cacBuoc,
    bug_expected: bugMm,
    evidence: minhChung,
    status: trangThai,
    logger: ngLog,
    priority: uuTien,
    fe_be: feBe,
    note: ghiChu,
  });
}

// === Đề xuất cải tiến sheet ===
const improveSheet = wb.worksheets.find((s) => s.name.includes('cải tiến'));
const improvements = [];
let impId = 0;
for (let rowNum = 2; rowNum <= improveSheet.rowCount; rowNum++) {
  const row = improveSheet.getRow(rowNum);
  const date = cellText(row.getCell(1));
  const uc = cellText(row.getCell(2));
  const moTa = cellText(row.getCell(3));
  const cacBuoc = cellText(row.getCell(4));
  const deXuat = cellText(row.getCell(5));
  const xacNhan = cellText(row.getCell(6));
  const nguoiDx = cellText(row.getCell(7));
  if (!uc || uc.length < 5) continue;
  impId++;
  improvements.push({
    imp_no: impId,
    excel_row: rowNum,
    date,
    module: uc.slice(0, 200),
    description: moTa,
    steps: cacBuoc,
    proposal: deXuat,
    confirmed: xacNhan,
    proposer: nguoiDx,
  });
}

// === Categorize bugs by module keyword (4 agents) ===
function categorize(b) {
  const m = b.module.toLowerCase();
  // C_TASK first — giao việc / phân công có thể overlap với VB đến/đi
  if (m.includes('giao việc') || m.includes('phân công') || m.includes('hồ sơ công việc') || m.includes('hscv')) return 'C_TASK';
  // B_ADMIN cross — quản trị / danh mục / phân quyền / khóa TK / lọc người dùng
  if (m.includes('quản trị') || m.includes('danh mục') || m.includes('phân quyền') || m.includes('khóa tài khoản') || (m.includes('lọc') && m.includes('người dùng'))) return 'B_ADMIN';
  // D_AUTH_DASH
  if (m.includes('đăng nhập') || m.includes('thông tin tài khoản') || m.includes('trang chủ') || m.includes('dashboard') || m.includes('tổng quan')) return 'D_AUTH_DASH';
  // A_VB chuyên VB đến / đi / dự thảo (sau khi đã loại giao việc)
  if (m.includes('văn bản dự thảo') || m.includes('văn bản đến') || m.includes('văn bản đi') || m.includes('vb đến') || m.includes('vb đi') || m.includes('văn bản  đi') || m.includes('thêm mới') || m.includes('sửa thông tin')) return 'A_VB';
  return 'X_OTHER';
}

const grouped = { A_VB: [], B_ADMIN: [], C_TASK: [], D_AUTH_DASH: [], X_OTHER: [] };
for (const b of bugs) {
  const cat = categorize(b);
  grouped[cat].push(b);
}

const out = {
  summary: {
    total_bugs: bugs.length,
    total_improvements: improvements.length,
    by_priority: {
      high: bugs.filter((b) => /high/i.test(b.priority)).length,
      medium: bugs.filter((b) => /medium/i.test(b.priority)).length,
      low: bugs.filter((b) => /low/i.test(b.priority)).length,
      none: bugs.filter((b) => !b.priority).length,
    },
    by_category: Object.fromEntries(Object.entries(grouped).map(([k, v]) => [k, v.length])),
  },
  bugs_by_category: grouped,
  improvements,
};

const outPath = path.join(__dirname, '_tester-bugs.json');
fs.writeFileSync(outPath, JSON.stringify(out, null, 2), 'utf8');
console.log('Wrote', outPath);
console.log('Summary:', JSON.stringify(out.summary, null, 2));

// Write per-category file for each agent
for (const [cat, list] of Object.entries(grouped)) {
  const sub = { category: cat, count: list.length, bugs: list };
  if (cat === 'D_AUTH_DASH') {
    sub.improvements = improvements; // give D agent the improvements too
    sub.other_bugs = grouped.X_OTHER;
  }
  fs.writeFileSync(path.join(__dirname, `_tester-bugs-${cat}.json`), JSON.stringify(sub, null, 2), 'utf8');
}
