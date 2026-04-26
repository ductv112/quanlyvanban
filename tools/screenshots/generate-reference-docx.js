// Generate reference.docx with table borders for pandoc.
// Steps:
//   1. Get default reference.docx from pandoc.
//   2. Open the docx (zip), modify word/styles.xml to add borders to "Table" style.
//   3. Save as tools/screenshots/reference.docx for use with --reference-doc.

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');
const AdmZip = require('adm-zip');

const PANDOC = 'C:\\Users\\Admin\\AppData\\Local\\Pandoc\\pandoc.exe';
const REF_PATH = path.resolve(__dirname, 'reference.docx');

// 1. Get default reference docx
console.log('Generating default reference.docx from pandoc...');
execSync(`"${PANDOC}" -o "${REF_PATH}" --print-default-data-file reference.docx`);

// 2. Read & modify styles.xml
const zip = new AdmZip(REF_PATH);
let styles = zip.readAsText('word/styles.xml');

// Border block for Table cells + outside
const tableBorders = `<w:tblBorders><w:top w:val="single" w:sz="4" w:space="0" w:color="808080"/><w:left w:val="single" w:sz="4" w:space="0" w:color="808080"/><w:bottom w:val="single" w:sz="4" w:space="0" w:color="808080"/><w:right w:val="single" w:sz="4" w:space="0" w:color="808080"/><w:insideH w:val="single" w:sz="4" w:space="0" w:color="808080"/><w:insideV w:val="single" w:sz="4" w:space="0" w:color="808080"/></w:tblBorders>`;

// Apply borders to two table styles pandoc uses: "Table" and "Compact"
let modified = 0;
function applyToStyle(styleId) {
  // Pattern: <w:style ... w:styleId="STYLEID" ...> ... </w:style>
  const re = new RegExp(`(<w:style[^>]*w:styleId="${styleId}"[^>]*>)([\\s\\S]*?)(</w:style>)`);
  const match = styles.match(re);
  if (!match) {
    console.log(`  - Style "${styleId}" not found in default reference.docx`);
    return;
  }
  // Inject inside <w:tblPr> if exists, else add a new <w:tblPr>
  let inner = match[2];
  if (inner.includes('<w:tblPr>')) {
    inner = inner.replace(/<w:tblPr>/, `<w:tblPr>${tableBorders}`);
  } else {
    inner += `<w:tblPr>${tableBorders}</w:tblPr>`;
  }
  styles = styles.replace(re, match[1] + inner + match[3]);
  modified++;
  console.log(`  ✓ Added borders to "${styleId}" style`);
}

applyToStyle('Table');
applyToStyle('Compact');

if (modified === 0) {
  // Try alternative names
  applyToStyle('TableNormal');
  applyToStyle('TableGrid');
}

zip.updateFile('word/styles.xml', Buffer.from(styles, 'utf8'));
zip.writeZip(REF_PATH);

const stats = fs.statSync(REF_PATH);
console.log(`\nReference docx ready: ${REF_PATH} (${(stats.size / 1024).toFixed(0)} KB)`);
console.log(`Modified ${modified} table style(s).`);
