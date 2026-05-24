/**
 * sign-required.ts — Helper notify "VB can ban ky" (v3.2.12).
 *
 * Trigger:
 *   - VB di / VB du thao: khi POST tao moi OR PUT update voi signer/approver
 *     -> bell cho 2 nguoi nay.
 *   - HSCV: khi trinh ky (status -> 3) OR PUT thay doi signer
 *     -> bell cho HSCV.signer.
 *
 * Best-effort: fail KHONG rollback main op (route success roi). Chi log warn.
 *
 * Resolve name -> staff_id qua LOWER(UNACCENT(full_name)) match (dong nhat
 * voi backend SP fn_attachment_can_sign + frontend canSignDoc helper).
 *
 * Dedup: notifyBell tu remove sender + dedup target list -> nguoi tao VB
 * va la signer/approver thi KHONG bi notify chinh minh.
 */

import pino from 'pino';
import { rawQuery } from '../db/query.js';
import { notifyBell } from './bell-emit.js';

const logger = pino({
  name: 'sign-required-notify',
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
});

/**
 * Resolve list of staff_ids tu list ten (LOWER + UNACCENT match, giong SP).
 * Tra empty array neu khong co name nao match.
 * Best-effort: query fail -> return [].
 */
async function resolveStaffIdsByNames(names: Array<string | null | undefined>): Promise<number[]> {
  const cleanNames = names
    .map((n) => (typeof n === 'string' ? n.trim() : ''))
    .filter((n) => n.length > 0);
  if (cleanNames.length === 0) return [];

  try {
    const rows = await rawQuery<{ id: number }>(
      `SELECT s.id
         FROM public.staff s
        WHERE COALESCE(s.is_deleted, FALSE) = FALSE
          AND COALESCE(s.is_locked, FALSE) = FALSE
          AND LOWER(unaccent(s.full_name)) = ANY(
            SELECT LOWER(unaccent(name)) FROM UNNEST($1::text[]) AS name
          )`,
      [cleanNames],
    );
    return rows.map((r) => Number(r.id)).filter((id) => Number.isFinite(id) && id > 0);
  } catch (err) {
    logger.warn({ err, cleanNames }, 'resolveStaffIdsByNames query failed');
    return [];
  }
}

export interface SignRequiredParams {
  /** outgoing_doc | drafting_doc | handling_doc */
  docType: 'outgoing' | 'drafting' | 'handling';
  docId: number;
  /** Hien thi trong title bell: vd "VB di so 5/UBND" hoac "HSCV: Mua may chu" */
  docLabel: string;
  /** Frontend link de bell click toi chi tiet */
  link: string;
  /** Sender (nguoi tao VB hoac trinh ky HSCV) — bi loai khoi target */
  senderStaffId: number;
  /** Cho VB di/du thao: ten signer text */
  signerName?: string | null;
  /** Cho VB di/du thao: ten approver text */
  approverName?: string | null;
  /** Cho HSCV: signer la INT staff_id (FK) — pass truc tiep */
  signerStaffId?: number | null;
}

/**
 * Bell notify "VB nay can ban ky" cho signer + approver duoc chi dinh.
 * Best-effort, non-throwing.
 */
export async function notifySignRequired(params: SignRequiredParams): Promise<void> {
  const {
    docType, docId, docLabel, link, senderStaffId,
    signerName, approverName, signerStaffId,
  } = params;

  // Collect target staff_ids
  const targets = new Set<number>();

  // Direct INT (HSCV case)
  if (signerStaffId && Number.isFinite(signerStaffId) && signerStaffId > 0) {
    targets.add(Number(signerStaffId));
  }

  // Resolve name -> staff_id (VB di/du thao case)
  const names = [signerName, approverName].filter((n): n is string => typeof n === 'string' && n.trim().length > 0);
  if (names.length > 0) {
    const ids = await resolveStaffIdsByNames(names);
    ids.forEach((id) => targets.add(id));
  }

  if (targets.size === 0) {
    // Khong co ai duoc chi dinh -> khong notify (binh thuong khi VB chua co signer)
    return;
  }

  // Title + message theo doc type
  let title: string;
  let message: string;
  if (docType === 'handling') {
    title = 'Bạn được giao ký số hồ sơ công việc';
    message = `Bạn được chỉ định ký số: ${docLabel}`;
  } else {
    title = 'Bạn được giao ký số văn bản';
    message = `Bạn được chỉ định ký số: ${docLabel}`;
  }

  try {
    await notifyBell({
      targetStaffIds: Array.from(targets),
      senderStaffId,
      type: 'sign_required',
      title,
      message,
      link,
      metadata: { doc_type: docType, doc_id: docId },
    });
  } catch (err) {
    logger.warn({ err, docType, docId, targets: Array.from(targets) }, 'notifySignRequired failed');
  }
}
