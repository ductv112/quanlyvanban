// Merge all HDSD modules into HDSD_full.md, then export to docx via pandoc.

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const HDSD_DIR = path.resolve(__dirname, '../../docs/hdsd');
const FULL_MD = path.join(HDSD_DIR, 'HDSD_full.md');
const FULL_DOCX = path.join(HDSD_DIR, 'HDSD_full.docx');
const PANDOC = 'C:\\Users\\Admin\\AppData\\Local\\Pandoc\\pandoc.exe';

// Order matches HDSD_index.md sections 5.1 → 5.6
const MODULES = [
  'HDSD_dang_nhap_va_thong_tin_ca_nhan.md',
  'HDSD_dashboard.md',
  'HDSD_thong_bao.md',
  'HDSD_van_ban_den.md',
  'HDSD_van_ban_di.md',
  'HDSD_van_ban_du_thao.md',
  'HDSD_van_ban_danh_dau.md',
  'HDSD_cau_hinh_gui_nhanh.md',
  'HDSD_ho_so_cong_viec_danh_sach.md',
  'HDSD_ho_so_cong_viec_chi_tiet.md',
  'HDSD_ho_so_cong_viec_bao_cao.md',
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

fs.writeFileSync(FULL_MD, parts.join('\n'));
const stats = fs.statSync(FULL_MD);
console.log(`\n  Merged: ${FULL_MD}`);
console.log(`  Size:   ${(stats.size / 1024).toFixed(0)} KB`);
const lineCount = parts.join('\n').split('\n').length;
console.log(`  Lines:  ${lineCount}`);

// 2. Export to docx via pandoc
console.log('\n[2/3] Exporting to docx via pandoc');
const cmd = `"${PANDOC}" "${FULL_MD}" -o "${FULL_DOCX}" --resource-path="${HDSD_DIR}" --toc --toc-depth=2 --standalone -f gfm+raw_html -t docx`;
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
