// Merge all HDSD modules into HDSD_full.md, then export to docx via pandoc.

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const HDSD_DIR = path.resolve(__dirname, '../../docs/hdsd');
const FULL_MD = path.join(HDSD_DIR, 'HDSD_full.md');
const FULL_DOCX = path.join(HDSD_DIR, 'HDSD_full.docx');
const PANDOC = 'C:\\Users\\Admin\\AppData\\Local\\Pandoc\\pandoc.exe';

// 20 modules — restructured rev3 (after gộp HSCV + bỏ HSCV Báo cáo dead route)
const MODULES = [
  'HDSD_dang_nhap_va_thong_tin_ca_nhan.md',
  'HDSD_dashboard.md',
  'HDSD_thong_bao.md',
  'HDSD_van_ban_den.md',
  'HDSD_van_ban_di.md',
  'HDSD_van_ban_du_thao.md',
  'HDSD_van_ban_danh_dau.md',
  'HDSD_cau_hinh_gui_nhanh.md',
  'HDSD_ho_so_cong_viec.md',
  'HDSD_ky_so_cau_hinh.md',
  'HDSD_ky_so_tai_khoan.md',
  'HDSD_ky_so_danh_sach.md',
  'HDSD_quan_tri_don_vi.md',
  'HDSD_quan_tri_chuc_vu.md',
  'HDSD_quan_tri_nguoi_dung.md',
  'HDSD_quan_tri_nhom_quyen.md',
  'HDSD_quan_tri_so_van_ban.md',
  'HDSD_quan_tri_loai_van_ban.md',
  'HDSD_quan_tri_linh_vuc.md',
  'HDSD_quan_tri_nguoi_ky.md',
];

// 1. Build merged Markdown
console.log('[1/3] Merging Markdown files');
let indexMd = fs.readFileSync(path.join(HDSD_DIR, 'HDSD_index.md'), 'utf8');

// Strip the "Mục lục các chức năng" section (5.x) — links to .md files are
// meaningless inside the docx output. Keep section 6 (Quy ước) onward.
indexMd = indexMd.replace(/## 5\. Mục lục các chức năng[\s\S]*?(?=^## 6\. )/m, '');

const parts = [
  indexMd.trimEnd(),
  '',
  // No page break: Word's TOC handles navigation; manual breaks fragment the doc.
  '# Phần I — Chi tiết các chức năng',
  '',
];

for (const file of MODULES) {
  const filePath = path.join(HDSD_DIR, file);
  if (!fs.existsSync(filePath)) {
    console.log(`  ⚠ missing: ${file}`);
    continue;
  }
  let content = fs.readFileSync(filePath, 'utf8');

  // Replace missing image references with italic caption
  content = content.replace(/!\[([^\]]*)\]\(screenshots\/([^)]+)\)/g, (full, alt, imgFile) => {
    const imgPath = path.join(HDSD_DIR, 'screenshots', imgFile);
    if (fs.existsSync(imgPath)) return full;
    return `*[Hình minh họa: ${alt}]*`;
  });

  // Demote heading levels so each module fits cleanly under "Phần I" (H1):
  //   - 1st H1 in file = module title          → H2 (demote +1)
  //   - 2nd+ H1 in file = sub-section ("PHẦN 1/2", etc.)
  //                                            → H3 (demote +2)
  //                       and all subsequent H2..H5 fall *inside* that sub-section
  //                                            → demote +2 instead of +1
  //   - H2..H5 before any H1 sub-section: demote +1 as usual
  const lines = content.split('\n');
  let firstH1Seen = false;
  let inSubsection = false;
  const fixed = lines.map((line) => {
    const m = line.match(/^(#{1,5}) /);
    if (!m) return line;
    if (m[1] === '#') {
      if (!firstH1Seen) {
        firstH1Seen = true;
        inSubsection = false;
        return '#' + line; // H1 → H2 (module title)
      }
      inSubsection = true;
      return '##' + line; // H1 → H3 (sub-section header)
    }
    // H2..H5: demote +2 if inside a sub-section (so 1.., 2.. become children of PHẦN 1)
    return inSubsection ? '##' + line : '#' + line;
  }).join('\n');
  parts.push(fixed);
  parts.push('');
  // No \newpage — Word will flow naturally; users can search via TOC.
  console.log(`  ✓ ${file}`);
}

let merged = parts.join('\n');

// Strip horizontal rules (---) — không cần đường line ngang giữa các mục.
// Pandoc render --- thành horizontal line trong docx, gây rối khi đọc.
const hrBefore = (merged.match(/^---\s*$/gm) || []).length;
merged = merged.replace(/^---\s*$/gm, '');
console.log(`  Stripped ${hrBefore} horizontal rule(s)`);

// Strip markdown links — printed docx has no clickable navigation:
//   [text](path) → text   ;  <http://...> → http://...   ;  ![alt](img) giữ nguyên
const linkBefore = (merged.match(/(?<!!)\[[^\]]+\]\([^)]+\)/g) || []).length;
merged = merged.replace(/(?<!!)\[([^\]]+)\]\(([^)]+)\)/g, '$1');
merged = merged.replace(/<((?:https?|mailto):[^>]+)>/g, '$1');
console.log(`  Stripped ${linkBefore} markdown link(s)`);

// Auto-number headings H2..H5 theo cấu trúc lồng:
//   H2 → "1." (chương — module title)
//   H3 → "1.1." (sub-section / section trong module)
//   H4 → "1.1.1." (mục trong section)
//   H5 → "1.1.1.1." (sub-mục)
// Đồng thời strip manual numbering cũ trong text gốc:
//   "Hướng dẫn sử dụng: X" → "X"
//   "PHẦN N — TEXT"        → "TEXT"
//   "N.M.K. TEXT"          → "TEXT"
const counters = { 2: 0, 3: 0, 4: 0, 5: 0 };
function stripPrefix(level, text) {
  let r = text;
  if (level === 2) {
    r = r.replace(/^Hướng dẫn sử dụng:\s*/i, '');
  }
  r = r.replace(/^PH[ẦầAa]N\s+\d+\s+[—–\-]\s+/i, '');
  r = r.replace(/^\d+(\.\d+)*\.?\s+/, '');
  return r.trim();
}
function makeNumber(level) {
  counters[level]++;
  for (let l = level + 1; l <= 5; l++) counters[l] = 0;
  const parts = [];
  for (let l = 2; l <= level; l++) parts.push(counters[l]);
  return parts.join('.') + '.';
}
const lines = merged.split('\n');
const renumbered = lines.map((line) => {
  // Reset counters at H1 "Phần I" boundary so detailed-section chapters start at 1
  if (/^# Ph[ầa]n\s+I\b/i.test(line)) {
    counters[2] = counters[3] = counters[4] = counters[5] = 0;
    return line;
  }
  const m = line.match(/^(#{2,5})\s+(.+?)\s*$/);
  if (!m) return line;
  const level = m[1].length;
  const num = makeNumber(level);
  const cleanText = stripPrefix(level, m[2]);
  return `${m[1]} ${num} ${cleanText}`;
});
merged = renumbered.join('\n');
console.log(`  Auto-numbered headings (chapter 1..N restart at "Phần I" boundary)`);

fs.writeFileSync(FULL_MD, merged);
const stats = fs.statSync(FULL_MD);
console.log(`\n  Merged: ${FULL_MD}`);
console.log(`  Size:   ${(stats.size / 1024).toFixed(0)} KB`);
const lineCount = merged.split('\n').length;
console.log(`  Lines:  ${lineCount}`);

// 2. Export to docx via pandoc — reference.docx adds borders to Table style.
//    --toc-depth=3 ⇒ TOC shows H1 + H2 + H3 (Phần I + các chương + sub-section).
console.log('\n[2/3] Exporting to docx via pandoc');
const REFERENCE_DOCX = path.resolve(__dirname, 'reference.docx');
const refFlag = fs.existsSync(REFERENCE_DOCX) ? `--reference-doc="${REFERENCE_DOCX}"` : '';
const cmd = `"${PANDOC}" "${FULL_MD}" -o "${FULL_DOCX}" --resource-path="${HDSD_DIR}" --toc --toc-depth=3 --standalone ${refFlag} -f gfm+raw_html -t docx`;
try {
  execSync(cmd, { stdio: 'inherit', cwd: HDSD_DIR });
  const docxStats = fs.statSync(FULL_DOCX);
  console.log(`  ✓ ${FULL_DOCX}`);
  console.log(`  Size: ${(docxStats.size / 1024).toFixed(0)} KB`);
} catch (err) {
  console.log(`  ✗ pandoc failed: ${err.message}`);
  process.exit(1);
}

console.log('\n[3/3] Done');
