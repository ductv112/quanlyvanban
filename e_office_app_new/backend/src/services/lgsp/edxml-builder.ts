// ============================================================
// edXML Builder (Phase 37.5 — rewrite theo spec QD 28/2018/QD-TTg v2.2)
//
// Spec: docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/HuongDanKetNoiLienThongVB_v2.2.pdf
//   - Root: <edXMLEnvelope xmlns="http://www.go.vn/eDoc"> (e thuong + default xmlns)
//   - Children inherit default namespace (NO prefix can thiet) — convention .NET XmlSerializer
//   - Date format: PromulgationDate "YYYY/MM/DD", Timestamp "yyyy/MM/dd HH:mm:ss"
//
// Bug history Phase 37.5:
//   Variant 1: <EdXMLEnvelope xmlns="..."> (E hoa)             -> reject (1, 40) - sai case
//   Variant 2: <edXMLEnvelope xmlns:edXML="..."><edXML:Child/> -> reject (1, 40) - sai namespace root
//   Variant 3 (current): <edXMLEnvelope xmlns="..."><Child/>   -> dang test
//
// MIRROR cho workers/src/lgsp/edxml-builder.ts (APPROACH B duplication).
// KEEP IN SYNC khi sua — checksum verify Plan 34-05.
// ============================================================

import { create } from 'xmlbuilder2';
import { randomUUID } from 'crypto';
import pino from 'pino';

const logger = pino({ name: 'edxml-builder' });

const EDXML_NS = 'http://www.go.vn/eDoc';

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

function numOrDefault(
  value: number | null | undefined,
  fallback: number,
  fieldName: string,
  ctx: { docCode: string },
): number {
  if (typeof value === 'number' && !isNaN(value)) return value;
  logger.warn(
    { field: fieldName, docCode: ctx.docCode, fallback },
    'edXML so field rong',
  );
  return fallback;
}

/** Format YYYY/MM/DD theo spec PromulgationDate. Fallback NOW neu null. */
function toPromulgationDate(
  value: Date | string | null | undefined,
  fieldName: string,
  ctx: { docCode: string },
): string {
  let d: Date;
  if (!value) {
    logger.warn(
      { field: fieldName, docCode: ctx.docCode },
      'edXML date field rong, fallback NOW',
    );
    d = new Date();
  } else if (value instanceof Date) {
    d = value;
  } else {
    d = new Date(value);
    if (isNaN(d.getTime())) {
      logger.warn(
        { field: fieldName, docCode: ctx.docCode, value },
        'edXML date parse fail, fallback NOW',
      );
      d = new Date();
    }
  }
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}/${m}/${day}`;
}

/** Format yyyy/MM/dd HH:mm:ss theo spec Timestamp (TraceHeader). */
function toTimestamp(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  const ss = String(d.getSeconds()).padStart(2, '0');
  return `${y}/${m}/${day} ${hh}:${mm}:${ss}`;
}

/**
 * Build edXML envelope theo spec QD 28/2018/QD-TTg v2.2.
 *
 * Structure:
 *   <?xml version="1.0" encoding="UTF-8"?>
 *   <edXMLEnvelope xmlns="http://www.go.vn/eDoc">
 *     <MessageHeader>
 *       <From> <OrganId/> <OrganName/> </From>
 *       <To> <OrganId/> <OrganName/> </To>
 *       <Code> <CodeNumber/> <CodeNotation/> </Code>
 *       <PromulgationInfo> <PromulgationDate/> </PromulgationInfo>
 *       <DocumentType> <Type/> <TypeName/> </DocumentType>
 *       <Subject/>
 *       <SignerInfo> <Competence/> <Position/> <FullName/> </SignerInfo>
 *       <OtherInfo> <Priority/> <PageAmount/> </OtherInfo>
 *       <SteeringType/>
 *       <DocumentId/>
 *     </MessageHeader>
 *     <TraceHeaderList>
 *       <TraceHeader> <OrganId/> <Timestamp/> </TraceHeader>
 *     </TraceHeaderList>
 *     <Attachment> <FileName/> <FileType/> <Content/> </Attachment>
 *   </edXMLEnvelope>
 */
export function buildEdxml(input: BuildEdxmlInput): BuildEdxmlResult {
  const docId = randomUUID();
  const docCode =
    input.notation?.trim() ||
    input.documentCode?.trim() ||
    `EDOC-${docId}`;
  const ctx = { docCode };
  const nowTimestamp = toTimestamp(new Date());

  const root = create({ version: '1.0', encoding: 'UTF-8' })
    .ele('edXML:edXMLEnvelope', { 'xmlns:edXML': EDXML_NS });

  const messageHeader = root.ele('edXML:MessageHeader');

  // 1.1 From
  messageHeader
    .ele('edXML:From')
      .ele('edXML:OrganId').txt(input.senderOrgCode).up()
      .ele('edXML:OrganName').txt(strOrNa(input.senderOrgName, 'senderOrgName', ctx)).up()
    .up();

  // 1.2 To
  messageHeader
    .ele('edXML:To')
      .ele('edXML:OrganId').txt(input.destOrgCode).up()
      .ele('edXML:OrganName').txt(strOrNa(input.destOrgName, 'destOrgName', ctx)).up()
    .up();

  // 1.3 Code
  messageHeader
    .ele('edXML:Code')
      .ele('edXML:CodeNumber').txt(strOrNa(input.notation, 'notation', ctx)).up()
      .ele('edXML:CodeNotation').txt(strOrNa(input.documentCode, 'documentCode', ctx)).up()
    .up();

  // 1.4 PromulgationInfo (Place optional - bo qua)
  messageHeader
    .ele('edXML:PromulgationInfo')
      .ele('edXML:PromulgationDate').txt(toPromulgationDate(input.publishDate, 'publishDate', ctx)).up()
    .up();

  // 1.5 DocumentType: Type=2 (van ban hanh chinh, mac dinh) + TypeName
  messageHeader
    .ele('edXML:DocumentType')
      .ele('edXML:Type').txt('2').up()
      .ele('edXML:TypeName').txt(strOrNa(input.docTypeName, 'docTypeName', ctx)).up()
    .up();

  // 1.6 Subject (trich yeu)
  messageHeader
    .ele('edXML:Subject').txt(strOrNa(input.abstract, 'abstract/subject', ctx)).up();

  // 1.8 SignerInfo
  messageHeader
    .ele('edXML:SignerInfo')
      .ele('edXML:Competence').txt('Truc tiep').up()
      .ele('edXML:Position').txt(strOrNa(input.signerPosition, 'signerPosition', ctx)).up()
      .ele('edXML:FullName').txt(strOrNa(input.signer, 'signer', ctx)).up()
    .up();

  // 1.11 OtherInfo: Priority + PageAmount (toi thieu)
  messageHeader
    .ele('edXML:OtherInfo')
      .ele('edXML:Priority').txt('0').up()
      .ele('edXML:PageAmount').txt(String(numOrDefault(input.numberPaper, 1, 'numberPaper', ctx))).up()
    .up();

  // 1.13 SteeringType: 0 = khong phai chi dao (mac dinh)
  messageHeader.ele('edXML:SteeringType').txt('0').up();

  // 1.14 DocumentId (UUID duy nhat tren toan he thong lien thong)
  messageHeader.ele('edXML:DocumentId').txt(docId).up();

  // 2. TraceHeaderList > TraceHeader
  root
    .ele('edXML:TraceHeaderList')
      .ele('edXML:TraceHeader')
        .ele('edXML:OrganId').txt(input.senderOrgCode).up()
        .ele('edXML:Timestamp').txt(nowTimestamp).up()
      .up()
    .up();

  // Attachments — moi file 1 phan tu Attachment chua FileName + FileType + Content base64
  for (const att of input.attachments) {
    root
      .ele('edXML:Attachment')
        .ele('edXML:FileName').txt(att.fileName).up()
        .ele('edXML:FileType').txt(att.fileType || 'application/octet-stream').up()
        .ele('edXML:Content').txt(att.contentBase64).up()
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
    'Built edXML envelope (Phase 37.5 spec v2.2)',
  );

  return {
    buffer,
    docId,
    destOrgCode: input.destOrgCode,
    docCode,
  };
}
