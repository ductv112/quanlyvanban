// Đọc cụ thể các sheet sau (BUG, admin, VB đi, Đề xuất)
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
  let out = '';
  if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') out = String(v);
  else if (v instanceof Date) out = v.toISOString().slice(0, 10);
  else if (v.richText) out = v.richText.map(t => t.text).join('');
  else if (v.formula !== undefined) out = String(v.result ?? '');
  else if (v.hyperlink) out = String(v.text ?? v.hyperlink ?? '');
  else if (v.text) out = String(v.text);
  return String(out);
}

const wb = new ExcelJS.Workbook();
await wb.xlsx.readFile(FILE);

const TARGET = process.argv[2] || 'BUG';

for (const sheet of wb.worksheets) {
  if (!sheet.name.toLowerCase().includes(TARGET.toLowerCase())) continue;
  console.log(`\n###### SHEET: "${sheet.name}" (${sheet.rowCount} × ${sheet.columnCount}) ######\n`);

  // Iterate row by row index 1..rowCount (do NOT skip empty)
  for (let rowNum = 1; rowNum <= sheet.rowCount; rowNum++) {
    const row = sheet.getRow(rowNum);
    const cells = [];
    for (let col = 1; col <= sheet.columnCount; col++) {
      const cell = row.getCell(col);
      const t = cellText(cell).replace(/\r?\n/g, ' \\n ').slice(0, 200);
      if (t.trim()) cells.push(`[${col}] ${t}`);
    }
    if (cells.length > 0) {
      console.log(`R${rowNum}: ${cells.join(' || ').slice(0, 600)}`);
    }
  }
}
