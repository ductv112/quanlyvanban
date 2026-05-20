// ============================================================
// edXML Builder (Phase 34 - duplicated from backend/src/services/lgsp/edxml-builder.ts)
//
// APPROACH B: duplicated for workers tsconfig isolation. KEEP IN SYNC voi backend.
// Source spec: docs/Truc EDOC Lang Son/HuongDanKetNoiLienThongVB_v2.2.pdf section 3
// ============================================================

import { create } from 'xmlbuilder2';
import { randomUUID } from 'crypto';
import pino from 'pino';

const logger = pino({ name: 'edxml-builder' });

export interface BuildEdxmlInput {
  senderOrgCode: string;
  senderOrgName: string;
  destOrgCode: string;
  destOrgName: string;
  notation: string | null;
  documentCode: string | null;
  abstract: string | null;
  publishDate: Date | string | null;
  signer: string | null;
  signDate: Date | string | null;
  signerPosition: string | null;
  docTypeName: string | null;
  numberPaper: number | null;
  appendix: string | null;
  attachments: Array<{
    fileName: string;
    fileType: string;
    contentBase64: string;
  }>;
}

export interface BuildEdxmlResult {
  buffer: Buffer;
  docId: string;
  destOrgCode: string;
  docCode: string;
}

function strOrNa(
  value: string | null | undefined,
  fieldName: string,
  ctx: { docCode: string },
): string {
  if (value && value.trim()) return value.trim();
  logger.warn(
    { field: fieldName, docCode: ctx.docCode },
    'edXML field rong, fallback "N/A"',
  );
  return 'N/A';
}

function numOrZero(
  value: number | null | undefined,
  fieldName: string,
  ctx: { docCode: string },
): number {
  if (typeof value === 'number' && !isNaN(value)) return value;
  logger.warn(
    { field: fieldName, docCode: ctx.docCode },
    'edXML so field rong, fallback 0',
  );
  return 0;
}

function toIsoDateString(
  value: Date | string | null | undefined,
  fieldName: string,
  ctx: { docCode: string },
): string {
  if (!value) {
    logger.warn(
      { field: fieldName, docCode: ctx.docCode },
      'edXML date field rong, fallback NOW',
    );
    return new Date().toISOString();
  }
  if (value instanceof Date) return value.toISOString();
  return value;
}

/**
 * Build edXML envelope theo spec QD 28/2018/QD-TTg.
 * Structure: EdXMLEnvelope > MessageHeader (9 thanh phan) + Manifest (N attachments).
 */
export function buildEdxml(input: BuildEdxmlInput): BuildEdxmlResult {
  const docId = randomUUID();
  const docCode =
    input.notation?.trim() ||
    input.documentCode?.trim() ||
    `EDOC-${docId}`;
  const ctx = { docCode };
  const nowIso = new Date().toISOString();

  const root = create({ version: '1.0', encoding: 'UTF-8' })
    .ele('EdXMLEnvelope', { xmlns: 'http://www.go.vn/eDoc' });

  const messageHeader = root.ele('MessageHeader');

  // 1. From
  messageHeader
    .ele('From')
      .ele('OrganId').txt(input.senderOrgCode).up()
      .ele('OrganName').txt(strOrNa(input.senderOrgName, 'senderOrgName', ctx)).up()
    .up();

  // 2. To
  messageHeader
    .ele('To')
      .ele('OrganId').txt(input.destOrgCode).up()
      .ele('OrganName').txt(strOrNa(input.destOrgName, 'destOrgName', ctx)).up()
    .up();

  // 3. Code
  messageHeader
    .ele('Code')
      .ele('CodeNumber').txt(strOrNa(input.notation, 'notation', ctx)).up()
      .ele('CodeNotation').txt(strOrNa(input.documentCode, 'documentCode', ctx)).up()
    .up();

  // 4. PromulgationInfo
  messageHeader
    .ele('PromulgationInfo')
      .ele('Promulgator').txt(strOrNa(input.signer, 'signer/promulgator', ctx)).up()
      .ele('PromulgationDate').txt(toIsoDateString(input.publishDate, 'publishDate', ctx)).up()
    .up();

  // 5. DocumentType
  messageHeader
    .ele('DocumentType').txt(strOrNa(input.docTypeName, 'docTypeName', ctx)).up();

  // 6. Subject
  messageHeader
    .ele('Subject').txt(strOrNa(input.abstract, 'abstract/subject', ctx)).up();

  // 7. SignerInfo
  messageHeader
    .ele('SignerInfo')
      .ele('Signer').txt(strOrNa(input.signer, 'signer', ctx)).up()
      .ele('Position').txt(strOrNa(input.signerPosition, 'signerPosition', ctx)).up()
      .ele('Competence').txt('Truc tiep').up()
    .up();

  // 8. OtherInfo
  messageHeader
    .ele('OtherInfo')
      .ele('PageAmount').txt(String(numOrZero(input.numberPaper, 'numberPaper', ctx))).up()
      .ele('Appendix').txt(input.appendix?.trim() || '').up()
    .up();

  // 9. DocumentId
  messageHeader.ele('DocumentId').txt(docId).up();

  // 10. TraceHeaderList
  messageHeader
    .ele('TraceHeaderList')
      .ele('TraceHeader')
        .ele('Time').txt(nowIso).up()
        .ele('Path')
          .ele('From').txt(input.senderOrgCode).up()
          .ele('To').txt(input.destOrgCode).up()
        .up()
      .up()
    .up();

  // Manifest
  const manifest = root.ele('Manifest');
  for (const att of input.attachments) {
    manifest
      .ele('Attachment')
        .ele('Content').txt(att.contentBase64).up()
        .ele('FileName').txt(att.fileName).up()
        .ele('FileType').txt(att.fileType || 'application/octet-stream').up()
      .up();
  }

  const xmlString = root.end({ prettyPrint: false });
  const buffer = Buffer.from(xmlString, 'utf8');

  logger.info(
    {
      docId,
      docCode,
      destOrgCode: input.destOrgCode,
      senderOrgCode: input.senderOrgCode,
      attachmentCount: input.attachments.length,
      bytes: buffer.length,
    },
    'Built edXML envelope',
  );

  return {
    buffer,
    docId,
    destOrgCode: input.destOrgCode,
    docCode,
  };
}
