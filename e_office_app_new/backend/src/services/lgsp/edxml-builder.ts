// ============================================================
// edXML Builder (Phase 34 - CONTEXT D-05, D-06, D-08, D-09)
// Source spec: docs/Truc EDOC Lang Son/HuongDanKetNoiLienThongVB_v2.2.pdf section 3
// Library: xmlbuilder2 (type-safe, escape XML auto)
//
// Output: Buffer chua edXML envelope theo chuan QD 28/2018/QD-TTg
//         + DocumentId UUID generated (luu vao lgsp_tracking.lgsp_doc_id PLACEHOLDER
//           se overwrite bang docId LGSP tra ve sau send thanh cong)
//
// Caller: Worker (Plan 34-02) load data tu DB + MinIO, build BuildEdxmlInput,
//         goi buildEdxml() de co Buffer + docId + destOrgCode + docCode,
//         truyen vao LGSPRealService.sendDocument(buffer, destOrgCode, docCode).
// ============================================================

import { create } from 'xmlbuilder2';
import { randomUUID } from 'crypto';
import pino from 'pino';

const logger = pino({ name: 'edxml-builder' });

/**
 * Input data cho builder. Caller (Plan 34-02 worker) build object nay tu:
 *   - lgsp_agency_config (sender systemId/lgsp_org_code)
 *   - departments (sender name)
 *   - inter_organizations (recipient code + name)
 *   - outgoing_docs (notation, document_code, abstract, signer, ...)
 *   - doc_types (docTypeName via lookup)
 *   - attachment_outgoing_docs + MinIO buffer (base64)
 */
export interface BuildEdxmlInput {
  // Sender (DN gui) - tu lgsp_agency_config + departments
  senderOrgCode: string;        // departments.lgsp_org_code (VD 'H37.DN.001')
  senderOrgName: string;        // departments.name

  // Recipient (don vi ngoai) - tu inter_organizations
  destOrgCode: string;          // inter_organizations.code (VD 'H37.DN.002')
  destOrgName: string;          // inter_organizations.name

  // Document fields (outgoing_docs - schema v3.0)
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

  // Attachments (already loaded from MinIO + base64 encoded by caller)
  attachments: Array<{
    fileName: string;
    fileType: string;        // VD 'application/pdf'
    contentBase64: string;
  }>;
}

export interface BuildEdxmlResult {
  buffer: Buffer;           // UTF-8 edXML bytes
  docId: string;            // UUID generated (DocumentId in MessageHeader)
  destOrgCode: string;      // for log + downstream
  docCode: string;          // notation || documentCode || 'EDOC-<docId>'
}

/**
 * Fallback string cho field null/empty (CONTEXT D-09).
 *
 * Log warning de dev biet - KHONG reject voi UX nhe nhang
 * (KH chua quen field bat buoc spec QD 28, va nhieu VB cu khong day du).
 */
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
  // String (tu pg driver TIMESTAMP -> ISO string)
  return value;
}

/**
 * Build edXML envelope dung spec QD 28/2018/QD-TTg.
 *
 * Structure (theo HDSD v2.2 section 3):
 *   <EdXMLEnvelope xmlns="http://www.go.vn/eDoc">
 *     <MessageHeader>
 *       <From><OrganId/><OrganName/></From>
 *       <To><OrganId/><OrganName/></To>
 *       <Code><CodeNumber/><CodeNotation/></Code>
 *       <PromulgationInfo><Promulgator/><PromulgationDate/></PromulgationInfo>
 *       <DocumentType>{docTypeName}</DocumentType>
 *       <Subject>{abstract}</Subject>
 *       <SignerInfo><Signer/><Position/><Competence/></SignerInfo>
 *       <OtherInfo><PageAmount/><Appendix/></OtherInfo>
 *       <DocumentId>{uuid}</DocumentId>
 *       <TraceHeaderList>
 *         <TraceHeader>
 *           <Time/>
 *           <Path><From/><To/></Path>
 *         </TraceHeader>
 *       </TraceHeaderList>
 *     </MessageHeader>
 *     <Manifest>
 *       <Attachment>
 *         <Content>{base64}</Content>
 *         <FileName>{name}</FileName>
 *         <FileType>{mime}</FileType>
 *       </Attachment>
 *     </Manifest>
 *   </EdXMLEnvelope>
 *
 * @param input All fields needed - caller load tu DB + MinIO truoc khi goi.
 * @returns Result voi buffer (Buffer UTF-8), docId (UUID), destOrgCode (cho log),
 *          docCode (cho multipart filename)
 */
export function buildEdxml(input: BuildEdxmlInput): BuildEdxmlResult {
  const docId = randomUUID();
  const docCode =
    input.notation?.trim() ||
    input.documentCode?.trim() ||
    `EDOC-${docId}`;
  const ctx = { docCode };
  const nowIso = new Date().toISOString();

  // xmlbuilder2 chain - tao envelope + MessageHeader 9 thanh phan
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

  // 3. Code (Number + Notation)
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

  // 9. DocumentId (UUID generated)
  messageHeader.ele('DocumentId').txt(docId).up();

  // 10. TraceHeaderList (1 entry initial)
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

  // Manifest (attachments)
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
