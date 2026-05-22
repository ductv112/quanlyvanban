// ============================================================
// v3.2.2 fix #M12: param validation helpers
//
// Vi sao can:
//   - Number(req.params.id) khong validate. Neu user truyen "abc" -> NaN, SP nhan NULL hoac throw.
//   - Neu truyen so > Number.MAX_SAFE_INTEGER (2^53-1) -> precision loss, query wrong row.
//   - Neu truyen so am hoac 0 -> hau het ID dung SERIAL/BIGSERIAL nen >0.
//
// Helper tra ve null + auto-respond 400 neu invalid -> caller chi can early-return.
// ============================================================
import type { Request, Response } from 'express';

/**
 * Parse 1 param thanh int duong an toan (1 .. 2^53-1).
 * Neu invalid -> tu respond 400 va return null. Caller phai early-return.
 *
 * @example
 * const id = parseIdParam(req, res, 'id');
 * if (id === null) return;
 */
export function parseIdParam(
  req: Request,
  res: Response,
  paramName = 'id',
): number | null {
  const raw = req.params[paramName];
  if (typeof raw !== 'string' || raw.length === 0) {
    res.status(400).json({ success: false, message: `Thieu tham so ${paramName}` });
    return null;
  }
  // Reject non-digit (decimal, sign, scientific, etc.)
  if (!/^\d+$/.test(raw)) {
    res.status(400).json({ success: false, message: `Tham so ${paramName} khong hop le` });
    return null;
  }
  // Safe integer guard
  const n = Number(raw);
  if (!Number.isSafeInteger(n) || n < 1) {
    res.status(400).json({ success: false, message: `Tham so ${paramName} ngoai pham vi cho phep` });
    return null;
  }
  return n;
}
