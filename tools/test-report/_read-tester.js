// Đọc file kết quả test từ team tester — full extract
import ExcelJS from 'exceljs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const FILE = path.join(REPO_ROOT, 'docs', 'Tester test PM Quản lý Văn Bản.xlsx');

function cellText(cell) {
  if (!cell || cell.value == null) return '';
  const v = cell.value;
  if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') return String(v);
  if (v instanceof Date) return v.toISOString().slice(0, 10);
  if (v.richText) return v.richText.map(t => t.text).join('');
  if (v.formula !== undefined) return String(v.result ?? '');
  if (v.text) return v.text;
  if (v.hyperlink) return v.text || v.hyperlink;
  return '';
}

const wb = new ExcelJS.Workbook();
await wb.xlsx.readFile(FILE);

console.log('═══════════════════════════════════════════════════════════');
console.log('  TESTER REPORT ANALYSIS');
console.log('═══════════════════════════════════════════════════════════');

for (const sheet of wb.worksheets) {
  console.log(`\n\n###### SHEET: "${sheet.name}" ######`);
  console.log(`Rows: ${sheet.rowCount} × Cols: ${sheet.columnCount}`);

  // Print first 20 rows of every sheet
  let rowsPrinted = 0;
  const limit = sheet.name.includes('BUG') ? 60 : sheet.name.includes('cải tiến') ? 50 : 30;
  sheet.eachRow({ includeEmpty: false }, (row, rowNum) => {
    if (rowsPrinted >= limit) return;
    const cells = [];
    row.eachCell({ includeEmpty: false }, (cell, col) => {
      const t = cellText(cell).replace(/\r?\n/g, ' \\n ').slice(0, 150);
      if (t.trim()) cells.push(`[${col}] ${t}`);
    });
    if (cells.length > 0) {
      console.log(`R${rowNum}: ${cells.join(' || ').slice(0, 500)}`);
      rowsPrinted++;
    }
  });
  if (sheet.rowCount > limit) {
    console.log(`  ... (${sheet.rowCount - rowsPrinted} more rows)`);
  }
}
