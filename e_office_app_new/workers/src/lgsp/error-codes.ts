// ============================================================
// LGSP Error Code Mapping (Phase 34 — duplicated from backend/src/services/lgsp/error-codes.ts)
//
// APPROACH B (Plan 34-02): workers tsconfig khong import backend (transitive deps cascade
// loi rootDir). Duplicate 3 module LGSP vao workers/src/lgsp/ — trade-off:
//   - Lost: single source of truth
//   - Gained: workers tsconfig clean, build coupling tach bach, dev test workers riêng
//
// NEU sua file nay PHAI sua dong bo backend/src/services/lgsp/error-codes.ts.
// Plan 34-05 (verify E2E) audit checksum 2 file moi pre-deploy.
// ============================================================

/**
 * 9 ErrorCode LGSP -> Vietnamese (CONTEXT D-12).
 * Tieng Viet KHONG DAU (PowerShell 5.1 + log file safe).
 * UI badge (Plan 34-04) hardcode tieng Viet co dau.
 */
export const LGSP_ERROR_CODES: Record<string, string> = {
  '0': 'Thanh cong',
  '10': 'File khong hop le',
  '15': 'Sai SystemId hoac SecretKey',
  '18': 'Don vi nhan khong ton tai',
  '19': 'Don vi gui khong dang ky',
  '20': 'Loi he thong tu phia LGSP',
  '21': 'Loi xu ly file',
  '22': 'Format edXML khong dung chuan QD 28',
  '23': 'Don vi nhan da khoa',
};

export class LgspSendError extends Error {
  public readonly code: string | undefined;
  public readonly vietnameseMessage: string;
  public readonly rawMessage: string;

  constructor(rawMessage: string, code?: string) {
    const vietnamese =
      code && LGSP_ERROR_CODES[code]
        ? LGSP_ERROR_CODES[code]
        : `Loi khong xac dinh${code ? ` (Code ${code})` : ''}: ${rawMessage}`;
    super(vietnamese);
    this.name = 'LgspSendError';
    this.code = code;
    this.vietnameseMessage = vietnamese;
    this.rawMessage = rawMessage;
  }
}

export function mapLgspError(
  errorCode: string | null | undefined,
  fallbackMessage: string,
): string {
  if (!errorCode) return fallbackMessage || 'Loi khong xac dinh';
  const known = LGSP_ERROR_CODES[errorCode];
  if (known) return `${known} (Code ${errorCode})`;
  return `${fallbackMessage || 'Loi khong xac dinh'} (Code ${errorCode})`;
}

export function isLgspNonRetryableError(
  errorCode: string | null | undefined,
): boolean {
  if (!errorCode) return false;
  return errorCode in LGSP_ERROR_CODES && errorCode !== '0';
}
