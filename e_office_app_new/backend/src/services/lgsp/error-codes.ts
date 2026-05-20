// ============================================================
// LGSP Error Code Mapping (Phase 34 - CONTEXT D-12)
// Source: docs/Truc EDOC Lang Son/HuongDanKetNoiLienThongVB_v2.2.pdf section 4
// + LTVB_API_TRUC_PROD_TICHHOP.postman_collection.json response examples
//
// Worker (Phase 34-02) consume:
//   - Code = '0' -> success path, update lgsp_tracking status='success' + lgsp_doc_id
//   - Code in {10,15,18,19,20,21,22,23} -> no-retry path, update tracking status='error'
//     + Vietnamese error_message
//   - Network/timeout/5xx -> throw LgspSendError + ko-set-code -> BullMQ retry per D-11
// ============================================================

/**
 * 9 ErrorCode LGSP -> Vietnamese message (CONTEXT D-12).
 *
 * Tat ca message KHONG CO DAU (chuan PowerShell 5.1 + log file safe).
 * Khi hien thi UI (Plan 34-04 badge) frontend hardcode message Tieng Viet co dau.
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

/**
 * Custom Error class cho structured throw trong sendDocument().
 *
 * Worker handler (Plan 34-02) catch -> instanceof check -> neu co `code` 4xx -> no-retry,
 * neu khong co code (network/timeout) -> rethrow de BullMQ retry per D-11.
 */
export class LgspSendError extends Error {
  public readonly code: string | undefined;
  public readonly vietnameseMessage: string;
  public readonly rawMessage: string;

  constructor(rawMessage: string, code?: string) {
    const vietnamese = code && LGSP_ERROR_CODES[code]
      ? LGSP_ERROR_CODES[code]
      : `Loi khong xac dinh${code ? ` (Code ${code})` : ''}: ${rawMessage}`;
    super(vietnamese);
    this.name = 'LgspSendError';
    this.code = code;
    this.vietnameseMessage = vietnamese;
    this.rawMessage = rawMessage;
  }
}

/**
 * Map ErrorCode -> Vietnamese message (utility cho route/worker khi khong throw).
 *
 * @param errorCode Ma string tu LGSP response (VD '15', '18'). Co the null/undefined.
 * @param fallbackMessage Raw message tu LGSP (dung khi errorCode khong trong table).
 * @returns Vietnamese message co format hop ly cho UI display.
 */
export function mapLgspError(
  errorCode: string | null | undefined,
  fallbackMessage: string,
): string {
  if (!errorCode) return fallbackMessage || 'Loi khong xac dinh';
  const known = LGSP_ERROR_CODES[errorCode];
  if (known) return `${known} (Code ${errorCode})`;
  return `${fallbackMessage || 'Loi khong xac dinh'} (Code ${errorCode})`;
}

/**
 * Classify error code thanh retry vs no-retry (Phase 34 worker dung - CONTEXT D-11).
 *
 * @param errorCode Ma tu LGSP response
 * @returns `true` = no-retry (4xx LGSP error da ro), `false` = retry (network/timeout/5xx)
 */
export function isLgspNonRetryableError(
  errorCode: string | null | undefined,
): boolean {
  if (!errorCode) return false;
  return errorCode in LGSP_ERROR_CODES && errorCode !== '0';
}
