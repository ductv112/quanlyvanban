import ExcelJS from 'exceljs';
import type { Response } from 'express';

export interface ExcelColumn {
  header: string;
  key: string;
  width?: number;
  style?: Partial<ExcelJS.Style>;
}

export async function exportExcel(
  res: Response,
  filename: string,
  sheetName: string,
  columns: ExcelColumn[],
  rows: Record<string, unknown>[],
) {
  const workbook = new ExcelJS.Workbook();
  workbook.creator = 'e-Office';
  workbook.created = new Date();

  const sheet = workbook.addWorksheet(sheetName);

  // Define columns
  sheet.columns = columns.map((col) => ({
    header: col.header,
    key: col.key,
    width: col.width || 15,
    style: col.style,
  }));

  // Style header row
  const headerRow = sheet.getRow(1);
  headerRow.font = { bold: true, size: 11 };
  headerRow.fill = {
    type: 'pattern',
    pattern: 'solid',
    fgColor: { argb: 'FF1B3A5C' },
  };
  headerRow.font = { bold: true, size: 11, color: { argb: 'FFFFFFFF' } };
  headerRow.alignment = { vertical: 'middle', horizontal: 'center', wrapText: true };
  headerRow.height = 30;

  // Add data rows
  for (const row of rows) {
    sheet.addRow(row);
  }

  // Style data rows
  for (let i = 2; i <= rows.length + 1; i++) {
    const dataRow = sheet.getRow(i);
    dataRow.alignment = { vertical: 'middle', wrapText: true };
    dataRow.border = {
      top: { style: 'thin', color: { argb: 'FFD9D9D9' } },
      bottom: { style: 'thin', color: { argb: 'FFD9D9D9' } },
    };
  }

  // Set response headers
  res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);

  await workbook.xlsx.write(res);
  res.end();
}
