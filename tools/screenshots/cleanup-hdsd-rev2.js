// Cleanup HDSD docs based on user feedback rev2:
//   - Remove "Bảng tổng hợp các thông báo" subsection from all files
//     (duplicates info already in process steps)
//   - File Đăng nhập specifically: also remove 13.1 (Quy tắc mật khẩu — dup with mục 10),
//     13.4 (Quên mật khẩu — không có chức năng) + renumber 13.2/13.3/13.5 → 13.1/13.2/13.3

const fs = require('fs');
const path = require('path');

const HDSD_DIR = path.resolve(__dirname, '../../docs/hdsd');

const files = fs
  .readdirSync(HDSD_DIR)
  .filter((f) => f.startsWith('HDSD_') && f.endsWith('.md') && !f.includes('full') && !f.includes('index'));

console.log(`Processing ${files.length} files in ${HDSD_DIR}`);

let totalRemoved = 0;

for (const file of files) {
  const filePath = path.join(HDSD_DIR, file);
  let content = fs.readFileSync(filePath, 'utf8');
  const before = content.length;

  // Generic: remove "### X.Y. Bảng tổng hợp các thông báo của hệ thống" + table
  // Pattern matches until next ## section, or "---\n\n*Tài liệu" footer, or EOF
  content = content.replace(
    /\n+### \d+\.\d+\.\s+B[ảa]ng\s+t[ổo]ng\s+h[ợo]p\s+(các\s+)?th[ôo]ng\s+b[áa]o[\s\S]*?(?=\n## |\n---\s*\n\s*\*Tài liệu|$)/g,
    '\n\n',
  );

  // Some files use "## X. Bảng tổng hợp" (not subsection) — match too
  content = content.replace(
    /\n+## \d+\.\s+B[ảa]ng\s+t[ổo]ng\s+h[ợo]p\s+(các\s+)?th[ôo]ng\s+b[áa]o[\s\S]*?(?=\n## |\n---\s*\n\s*\*Tài liệu|$)/g,
    '\n\n',
  );

  if (content.length !== before) {
    fs.writeFileSync(filePath, content);
    console.log(`  ✓ ${file}: removed ${before - content.length} chars (Bảng tổng hợp)`);
    totalRemoved += before - content.length;
  }
}

// File Đăng nhập specific
console.log('\nFile Đăng nhập specific cleanup:');
const dnPath = path.join(HDSD_DIR, 'HDSD_dang_nhap_va_thong_tin_ca_nhan.md');
let dn = fs.readFileSync(dnPath, 'utf8');
const dnBefore = dn.length;

// Remove 13.1 Quy tắc mật khẩu (dup with mục 10)
dn = dn.replace(/\n+### 13\.1\.\s+Quy tắc mật khẩu[\s\S]*?(?=\n+### 13\.2)/, '\n\n');

// Remove 13.4 Quên mật khẩu (không có chức năng)
dn = dn.replace(/\n+### 13\.4\.\s+Quên mật khẩu[\s\S]*?(?=\n+### 13\.5)/, '\n\n');

// Renumber 13.2 → 13.1, 13.3 → 13.2, 13.5 → 13.3 (sau khi xoá 13.1 + 13.4)
dn = dn.replace(/### 13\.2\./g, '### 13.1.');
dn = dn.replace(/### 13\.3\./g, '### 13.2.');
dn = dn.replace(/### 13\.5\./g, '### 13.3.');

if (dn !== fs.readFileSync(dnPath, 'utf8')) {
  fs.writeFileSync(dnPath, dn);
  console.log(`  ✓ HDSD_dang_nhap_va_thong_tin_ca_nhan.md: removed ${dnBefore - dn.length} chars + renumbered`);
}

console.log(`\nTotal removed: ${totalRemoved} chars across ${files.length} files`);
