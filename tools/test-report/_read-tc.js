// Đọc TC-DASH-002..011 từ Excel template
import ExcelJS from 'exceljs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const REPO_ROOT = path.resolve(__dirname, '..', '..');
const TEMPLATE = path.join(REPO_ROOT, 'docs', 'hdsd', '20260509_Testcase_QLVB_V2_results.xlsx');

const wb = new ExcelJS.Workbook();
await wb.xlsx.readFile(TEMPLATE);
const sheet = wb.getWorksheet('Test cases');
console.log('Total rows:', sheet.rowCount);

// Columns: A=ID, B=?, C=?, ... print header first
const headerRow = sheet.getRow(1);
console.log('Headers:');
headerRow.eachCell({ includeEmpty: false }, (cell, col) => {
  console.log(`  Col ${col}: ${cell.value}`);
});

console.log('\n=== TC-DASH-002 to TC-DASH-011 ===');
sheet.eachRow({ includeEmpty: false }, (row, rowNum) => {
  const id = String(row.getCell(1).value || '').trim();
  if (/^TC-DASH-(0(0[2-9]|1[01]))$/.test(id)) {
    console.log(`\n--- Row ${rowNum}: ${id} ---`);
    row.eachCell({ includeEmpty: false }, (cell, col) => {
      const val = cell.value;
      let str = typeof val === 'object' && val?.richText ? val.richText.map(t => t.text).join('') : String(val ?? '');
      str = str.replace(/\r?\n/g, ' \\n ').slice(0, 300);
      console.log(`  Col ${col}: ${str}`);
    });
  }
});
