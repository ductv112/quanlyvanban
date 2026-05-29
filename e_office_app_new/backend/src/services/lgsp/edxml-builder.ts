// ============================================================
// edXML Builder (Phase 37.8 — template literal, full prefix edXML: control)
//
// Phase 37.6 dung xmlbuilder2 nhung library tu optimize bo prefix `edXML:` khi
// default xmlns tren root cung URI voi xmlns:edXML tren envelope. Output thieu
// prefix tren children -> .NET XmlSerializer ben VPCP reject schema validation.
// LGSP Lang Son noi tinh accept nhe nen Phase 37.6 deploy vao da pass nhung
// cross-tinh qua VDXP (vi du gui Sở KHCN H37.02.02) phai chinh xac prefix.
//
// Phase 37.8 dung template literal — full control output, KHONG dung xmlbuilder2.
//
// Spec: docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/
//   - File chuan VPCP: edoc_new.edxml
//   - File chuan LGSP tinh: 3caa7148-90af-4a92-937e-df2e894422db.edxml
//   - SDK NET: 20190108_net_sdk_example/CodeXamplesEdXML/Program.cs
//
// MIRROR cho workers/src/lgsp/edxml-builder.ts (APPROACH B duplication).
// KEEP IN SYNC khi sua — checksum verify Plan 34-05.
// ============================================================

import { randomUUID, randomBytes } from 'crypto';
import pino from 'pino';

const logger = pino({ name: 'edxml-builder' });

const EDXML_NS = 'http://www.mic.gov.vn/TBT/QCVN_102_2016';
const XLINK_NS = 'http://www.w3.org/1999/xlink';
const XSI_NS = 'http://www.w3.org/2001/XMLSchema-instance';
const XSD_NS = 'http://www.w3.org/2001/XMLSchema';
const SOAP_ACTOR = 'http://schemas.xmlsoap.org/soap/actor/next';

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

/** Escape XML special chars (text content). */
function xmlEsc(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}

/** Escape XML attribute value. */
function xmlAttrEsc(s: string): string {
  return xmlEsc(s);
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

/** YYYY/MM/DD — format chuan PromulgationDate / DueDate. */
function toDateString(
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

/** yyyy/MM/dd HH:mm:ss — format chuan TraceHeader Timestamp. */
function toTimestamp(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const hh = String(d.getHours()).padStart(2, '0');
  const mm = String(d.getMinutes()).padStart(2, '0');
  const ss = String(d.getSeconds()).padStart(2, '0');
  return `${y}/${m}/${day} ${hh}:${mm}:${ss}`;
}

/** id attribute cho TraceHeaderList — random 8 ky tu hex. */
function genTraceHeaderListId(): string {
  return randomBytes(4).toString('hex');
}

/**
 * Build edXML envelope theo chuan QCVN 102:2016 — Phase 37.8 template literal.
 * Tat ca element con cua edXMLEnvelope co prefix `edXML:` (TRU `<AttachmentEncoded>` ngoai envelope).
 */
export function buildEdxml(input: BuildEdxmlInput): BuildEdxmlResult {
  const internalDocId = randomUUID();
  const docCode =
    input.notation?.trim() ||
    input.documentCode?.trim() ||
    `EDOC-${internalDocId}`;
  const ctx = { docCode };
  const now = new Date();
  const nowTimestamp = toTimestamp(now);

  // DocumentId format chuan: "{senderOrgCode},{YYYY/MM/DD},{number}/{notation}"
  const docIdValue = `${input.senderOrgCode},${toDateString(input.publishDate, 'publishDate', ctx)},${strOrNa(input.notation, 'notation', ctx)}/${strOrNa(input.documentCode, 'documentCode', ctx)}`;

  // Generate cid uuid moi cho moi attachment
  const attachmentRefs = input.attachments.map((att, idx) => ({
    contentId: randomUUID(),
    description: `File dinh kem ${idx + 1}`,
    fileName: att.fileName,
    contentType: att.fileType || 'application/octet-stream',
    contentBase64: att.contentBase64,
  }));

  const senderName = strOrNa(input.senderOrgName, 'senderOrgName', ctx);
  const destName = strOrNa(input.destOrgName, 'destOrgName', ctx);
  const notationVal = strOrNa(input.notation, 'notation', ctx);
  const documentCodeVal = strOrNa(input.documentCode, 'documentCode', ctx);
  const promulDate = toDateString(input.publishDate, 'publishDate', ctx);
  const docTypeNameVal = strOrNa(input.docTypeName, 'docTypeName', ctx);
  const subjectText = strOrNa(input.abstract, 'abstract/subject', ctx);
  const signerPosVal = strOrNa(input.signerPosition, 'signerPosition', ctx);
  const signerNameVal = strOrNa(input.signer, 'signer', ctx);
  const dueDate = new Date(now);
  dueDate.setDate(dueDate.getDate() + 2);
  const dueDateStr = toDateString(dueDate, 'dueDate', ctx);
  const pageAmount = String(numOrDefault(input.numberPaper, 1, 'numberPaper', ctx));
  const appendixVal = input.appendix?.trim() || '';
  const traceListId = genTraceHeaderListId();

  // ===== Build XML qua template literal — full control output =====
  let xml = `<?xml version="1.0" encoding="utf-8"?>\n`;
  xml += `<edXML xmlns:xsi="${XSI_NS}" xmlns:xsd="${XSD_NS}" xmlns="${EDXML_NS}">\n`;
  xml += `  <edXML:edXMLEnvelope xmlns:edXML="${EDXML_NS}">\n`;
  xml += `    <edXML:edXMLHeader>\n`;

  // ----- MessageHeader -----
  xml += `      <edXML:MessageHeader>\n`;

  // 1.1 From
  xml += `        <edXML:From>\n`;
  xml += `          <edXML:OrganId>${xmlEsc(input.senderOrgCode)}</edXML:OrganId>\n`;
  xml += `          <edXML:OrganizationInCharge>${xmlEsc(senderName)}</edXML:OrganizationInCharge>\n`;
  xml += `          <edXML:OrganName>${xmlEsc(senderName)}</edXML:OrganName>\n`;
  xml += `        </edXML:From>\n`;

  // 1.2 To
  xml += `        <edXML:To>\n`;
  xml += `          <edXML:OrganId>${xmlEsc(input.destOrgCode)}</edXML:OrganId>\n`;
  xml += `          <edXML:OrganizationInCharge>${xmlEsc(destName)}</edXML:OrganizationInCharge>\n`;
  xml += `          <edXML:OrganName>${xmlEsc(destName)}</edXML:OrganName>\n`;
  xml += `        </edXML:To>\n`;

  // 1.3 Code
  xml += `        <edXML:Code>\n`;
  xml += `          <edXML:CodeNumber>${xmlEsc(notationVal)}</edXML:CodeNumber>\n`;
  xml += `          <edXML:CodeNotation>${xmlEsc(documentCodeVal)}</edXML:CodeNotation>\n`;
  xml += `        </edXML:Code>\n`;

  // 1.4 PromulgationInfo
  xml += `        <edXML:PromulgationInfo>\n`;
  xml += `          <edXML:Place>N/A</edXML:Place>\n`;
  xml += `          <edXML:PromulgationDate>${xmlEsc(promulDate)}</edXML:PromulgationDate>\n`;
  xml += `        </edXML:PromulgationInfo>\n`;

  // 1.5 DocumentType (Type=18 = Cong van, theo C# SDK default)
  xml += `        <edXML:DocumentType>\n`;
  xml += `          <edXML:Type>18</edXML:Type>\n`;
  xml += `          <edXML:TypeName>${xmlEsc(docTypeNameVal)}</edXML:TypeName>\n`;
  xml += `          <edXML:TypeDetail>0</edXML:TypeDetail>\n`;
  xml += `        </edXML:DocumentType>\n`;

  // 1.6 Subject + 1.7 Content
  xml += `        <edXML:Subject>${xmlEsc(subjectText)}</edXML:Subject>\n`;
  xml += `        <edXML:Content>${xmlEsc(subjectText)}</edXML:Content>\n`;

  // 1.8 SignerInfo
  xml += `        <edXML:SignerInfo>\n`;
  xml += `          <edXML:Competence>Truc tiep</edXML:Competence>\n`;
  xml += `          <edXML:Position>${xmlEsc(signerPosVal)}</edXML:Position>\n`;
  xml += `          <edXML:FullName>${xmlEsc(signerNameVal)}</edXML:FullName>\n`;
  xml += `        </edXML:SignerInfo>\n`;

  // 1.9 DueDate
  xml += `        <edXML:DueDate>${xmlEsc(dueDateStr)}</edXML:DueDate>\n`;

  // 1.10 ToPlaces
  xml += `        <edXML:ToPlaces>\n`;
  xml += `          <edXML:Place>${xmlEsc(destName)}</edXML:Place>\n`;
  xml += `        </edXML:ToPlaces>\n`;

  // 1.11 OtherInfo
  xml += `        <edXML:OtherInfo>\n`;
  xml += `          <edXML:Priority>0</edXML:Priority>\n`;
  xml += `          <edXML:SphereOfPromulgation>Lien thong van ban</edXML:SphereOfPromulgation>\n`;
  xml += `          <edXML:TyperNotation>TVC</edXML:TyperNotation>\n`;
  xml += `          <edXML:PromulgationAmount>1</edXML:PromulgationAmount>\n`;
  xml += `          <edXML:PageAmount>${pageAmount}</edXML:PageAmount>\n`;
  xml += `          <edXML:Appendixes>\n`;
  xml += `            <edXML:Appendix>${xmlEsc(appendixVal)}</edXML:Appendix>\n`;
  xml += `          </edXML:Appendixes>\n`;
  xml += `        </edXML:OtherInfo>\n`;

  // 1.13 SteeringType
  xml += `        <edXML:SteeringType>0</edXML:SteeringType>\n`;

  // 1.14 DocumentId
  xml += `        <edXML:DocumentId>${xmlEsc(docIdValue)}</edXML:DocumentId>\n`;

  xml += `      </edXML:MessageHeader>\n`;

  // ----- TraceHeaderList (4 attributes) -----
  xml += `      <edXML:TraceHeaderList id="${xmlAttrEsc(traceListId)}" version="1.0" mustUnderstand="1" actor="${xmlAttrEsc(SOAP_ACTOR)}">\n`;

  // TraceHeader
  xml += `        <edXML:TraceHeader>\n`;
  xml += `          <edXML:OrganId>${xmlEsc(input.senderOrgCode)}</edXML:OrganId>\n`;
  xml += `          <edXML:Timestamp>${xmlEsc(nowTimestamp)}</edXML:Timestamp>\n`;
  xml += `        </edXML:TraceHeader>\n`;

  // Bussiness (sibling cua TraceHeader)
  xml += `        <edXML:Bussiness>\n`;
  xml += `          <edXML:BussinessDocType>0</edXML:BussinessDocType>\n`;
  xml += `          <edXML:BussinessDocReason>Van ban dien tu moi</edXML:BussinessDocReason>\n`;
  xml += `          <edXML:StaffInfo>\n`;
  xml += `            <edXML:Department>N/A</edXML:Department>\n`;
  xml += `            <edXML:Staff>${xmlEsc(signerNameVal)}</edXML:Staff>\n`;
  xml += `            <edXML:Mobile></edXML:Mobile>\n`;
  xml += `            <edXML:Email></edXML:Email>\n`;
  xml += `          </edXML:StaffInfo>\n`;
  xml += `          <edXML:Paper>0</edXML:Paper>\n`;
  xml += `        </edXML:Bussiness>\n`;

  xml += `      </edXML:TraceHeaderList>\n`;

  // ----- DigitalSignature (empty self-closing) -----
  xml += `      <edXML:DigitalSignature />\n`;

  xml += `    </edXML:edXMLHeader>\n`;

  // ===== edXMLBody (Manifest + References) =====
  xml += `    <edXML:edXMLBody>\n`;
  xml += `      <edXML:edXMLManifest version="1.0">\n`;

  for (const ref of attachmentRefs) {
    xml += `        <edXML:Reference xmlns:xlink="${XLINK_NS}" xlink:href="cid:${xmlAttrEsc(ref.contentId)}" xlink:role="XLinkRole" xlink:type="simple">\n`;
    xml += `          <edXML:Description>${xmlEsc(ref.description)}</edXML:Description>\n`;
    xml += `          <edXML:AttachmentName>${xmlEsc(ref.fileName)}</edXML:AttachmentName>\n`;
    xml += `          <edXML:ContentType>${xmlEsc(ref.contentType)}</edXML:ContentType>\n`;
    xml += `          <edXML:ContentId>cid:${xmlEsc(ref.contentId)}</edXML:ContentId>\n`;
    xml += `        </edXML:Reference>\n`;
  }

  xml += `      </edXML:edXMLManifest>\n`;
  xml += `    </edXML:edXMLBody>\n`;
  xml += `  </edXML:edXMLEnvelope>\n`;

  // ===== AttachmentEncoded (OUTSIDE envelope, default namespace - KHONG prefix edXML:) =====
  if (attachmentRefs.length > 0) {
    xml += `  <AttachmentEncoded>\n`;
    for (const ref of attachmentRefs) {
      xml += `    <Attachment>\n`;
      xml += `      <ContentType>${xmlEsc(ref.contentType)}</ContentType>\n`;
      xml += `      <ContentId>${xmlEsc(ref.contentId)}</ContentId>\n`;
      xml += `      <Description>${xmlEsc(ref.description)}</Description>\n`;
      xml += `      <ContentTransferEncoded>${ref.contentBase64}</ContentTransferEncoded>\n`;
      xml += `      <AttachmentName>${xmlEsc(ref.fileName)}</AttachmentName>\n`;
      xml += `    </Attachment>\n`;
    }
    xml += `  </AttachmentEncoded>\n`;
  }

  xml += `</edXML>\n`;

  const buffer = Buffer.from(xml, 'utf8');

  logger.info(
    {
      docId: docIdValue,
      docCode,
      destOrgCode: input.destOrgCode,
      senderOrgCode: input.senderOrgCode,
      attachmentCount: input.attachments.length,
      bytes: buffer.length,
    },
    'Built edXML envelope (Phase 37.8 template literal)',
  );

  return {
    buffer,
    docId: internalDocId,
    destOrgCode: input.destOrgCode,
    docCode,
  };
}
