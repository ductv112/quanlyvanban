import { spawn } from 'node:child_process';
import { promises as fs } from 'node:fs';
import * as path from 'node:path';
import * as os from 'node:os';
import type { Readable } from 'node:stream';
import { minioClient, uploadFile } from './minio/client.js';

const BUCKET = process.env.MINIO_BUCKET || 'documents';
const SOFFICE = process.env.LIBREOFFICE_PATH || (process.platform === 'win32'
  ? 'C:\\Program Files\\LibreOffice\\program\\soffice.exe'
  : '/usr/bin/soffice');

/** Office MIME types cần convert sang PDF để preview */
export const OFFICE_MIME_TYPES = new Set<string>([
  'application/msword',                                                          // .doc
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',     // .docx
  'application/vnd.ms-excel',                                                    // .xls
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',           // .xlsx
  'application/vnd.ms-powerpoint',                                               // .ppt
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',   // .pptx
  'application/rtf', 'text/rtf',                                                 // .rtf
  'application/vnd.oasis.opendocument.text',                                     // .odt
  'application/vnd.oasis.opendocument.spreadsheet',                              // .ods
  'application/vnd.oasis.opendocument.presentation',                             // .odp
]);

export function isOfficeMime(mime: string | null | undefined): boolean {
  if (!mime) return false;
  return OFFICE_MIME_TYPES.has(mime.toLowerCase().split(';')[0].trim());
}

/**
 * Convert file Office sang PDF qua LibreOffice headless.
 *
 * Flow:
 *  1. Check cache MinIO `previews/{attachmentId}.pdf` — nếu có → return path ngay
 *  2. Download source từ MinIO về temp dir
 *  3. Spawn `soffice --headless --convert-to pdf --outdir <tmp> <input>` (timeout 60s)
 *  4. Upload PDF result lên MinIO `previews/{attachmentId}.pdf`
 *  5. Cleanup temp files
 *  6. Return MinIO preview path
 *
 * @param sourceMinioPath MinIO path của file gốc (vd: incoming/123/uuid.docx)
 * @param attachmentId DB id của attachment row — dùng làm cache key
 * @returns MinIO path của file PDF preview
 * @throws Error nếu conversion fail / timeout
 */
export async function convertOfficeToPdf(sourceMinioPath: string, attachmentId: number): Promise<string> {
  const previewPath = `previews/${attachmentId}.pdf`;

  // Step 1: Cache check
  try {
    await minioClient.statObject(BUCKET, previewPath);
    return previewPath;  // Cache hit
  } catch {
    // Cache miss — fall through to convert
  }

  // Step 2: Download source về temp dir
  const tmpDir = await fs.mkdtemp(path.join(os.tmpdir(), 'qlvb-preview-'));
  const sourceExt = path.extname(sourceMinioPath) || '.bin';
  const sourceFile = path.join(tmpDir, `src${sourceExt}`);

  try {
    const stream = (await minioClient.getObject(BUCKET, sourceMinioPath)) as unknown as Readable;
    const chunks: Buffer[] = [];
    for await (const chunk of stream) chunks.push(chunk as Buffer);
    await fs.writeFile(sourceFile, Buffer.concat(chunks));

    // Step 3: Spawn soffice convert
    await new Promise<void>((resolve, reject) => {
      const proc = spawn(SOFFICE, [
        '--headless', '--norestore', '--nolockcheck',
        '--convert-to', 'pdf',
        '--outdir', tmpDir,
        sourceFile,
      ], { windowsHide: true });

      let stderr = '';
      proc.stderr.on('data', (d) => { stderr += d.toString(); });

      const timeout = setTimeout(() => {
        proc.kill('SIGKILL');
        reject(new Error('Convert Office sang PDF quá lâu (timeout 60s)'));
      }, 60_000);

      proc.on('error', (err) => { clearTimeout(timeout); reject(err); });
      proc.on('exit', (code) => {
        clearTimeout(timeout);
        if (code !== 0) reject(new Error(`LibreOffice exit code ${code}: ${stderr.slice(0, 300)}`));
        else resolve();
      });
    });

    // Step 4: Upload PDF result lên MinIO
    const pdfFile = path.join(tmpDir, `src.pdf`);
    const pdfBuf = await fs.readFile(pdfFile);
    await uploadFile(previewPath, pdfBuf, 'application/pdf');

    return previewPath;
  } finally {
    // Step 5: Cleanup temp
    await fs.rm(tmpDir, { recursive: true, force: true }).catch(() => { /* ignore cleanup errors */ });
  }
}
