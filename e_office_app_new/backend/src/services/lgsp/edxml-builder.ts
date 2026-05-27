// ============================================================
// edXML Builder (Phase 37.6 — rewrite theo SDK chuan QCVN 102:2016)
//
// Spec: docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/20190108_net_sdk_example/
//   - File mau: CodeXamplesEdXML/File_EdXML/edoc_new.edxml
//   - C# reference: CodeXamplesEdXML/Program.cs (function edoc_new)
//
// Cau truc chuan:
//   <edXML xmlns:xsi xmlns:xsd xmlns="http://www.mic.gov.vn/TBT/QCVN_102_2016">
//     <edXML:edXMLEnvelope xmlns:edXML="http://www.mic.gov.vn/TBT/QCVN_102_2016">
//       <edXML:edXMLHeader>
//         <edXML:MessageHeader>... 14 thanh phan ...</edXML:MessageHeader>
//         <edXML:TraceHeaderList id="..." version="1.0" mustUnderstand="1" actor="...">
//           <edXML:TraceHeader> <OrganId/> <Timestamp/> </edXML:TraceHeader>
//           <edXML:Bussiness> <BussinessDocType/> <BussinessDocReason/> <StaffInfo/> <Paper/> </edXML:Bussiness>
//         </edXML:TraceHeaderList>
//         <edXML:DigitalSignature/>
//       </edXML:edXMLHeader>
//       <edXML:edXMLBody>
//         <edXML:edXMLManifest version="1.0">
//           <edXML:Reference xmlns:xlink xlink:href="cid:..." xlink:role="XLinkRole" xlink:type="simple">
//             ...
//           </edXML:Reference>
//         </edXML:edXMLManifest>
//       </edXML:edXMLBody>
//     </edXML:edXMLEnvelope>
//     <AttachmentEncoded>
//       <Attachment> <ContentType/> <ContentId/> <Description/> <ContentTransferEncoded/> <AttachmentName/> </Attachment>
//     </AttachmentEncoded>
//   </edXML>
//
// History 4 variants truoc Phase 37.6 dung sai namespace + sai root + thieu wrapper +
// thieu edXMLHeader/edXMLBody layer + Attachment inline thay vi xlink binding.
//
// MIRROR cho workers/src/lgsp/edxml-builder.ts (APPROACH B duplication).
// KEEP IN SYNC khi sua — checksum verify Plan 34-05.
// ============================================================

import { create } from 'xmlbuilder2';
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

/** id attribute cho TraceHeaderList — random 8 ky tu alphanumeric. */
function genTraceHeaderListId(): string {
  return randomBytes(4).toString('hex');
}

/**
 * Build edXML envelope theo SDK chuan QCVN 102:2016 (Phase 37.6).
 *
 * Khac biet vs variants 1-4:
 *   - Namespace: http://www.mic.gov.vn/TBT/QCVN_102_2016 (KHONG phai go.vn/eDoc)
 *   - Root <edXML> wrapper voi 3 xmlns (default + xsi + xsd)
 *   - edXMLEnvelope > edXMLHeader > MessageHeader/TraceHeaderList/DigitalSignature
 *   - edXMLEnvelope > edXMLBody > Manifest > Reference (xlink binding)
 *   - Attachment dung xlink+ContentId, base64 trong <AttachmentEncoded> ngoai envelope
 *   - DocumentId format: "{senderOrgCode},{YYYY/MM/DD},{notation}/{documentCode}"
 *   - TraceHeaderList co 4 attributes: id, version, mustUnderstand, actor
 */
export function buildEdxml(input: BuildEdxmlInput): BuildEdxmlResult {
  const internalDocId = randomUUID(); // returned to caller cho tracking
  const docCode =
    input.notation?.trim() ||
    input.documentCode?.trim() ||
    `EDOC-${internalDocId}`;
  const ctx = { docCode };
  const now = new Date();
  const nowDate = toDateString(now, '_now', ctx);
  const nowTimestamp = toTimestamp(now);

  // DocumentId format chuan QCVN 102: "{senderOrgCode},{YYYY/MM/DD},{number}/{notation}"
  const docIdValue = `${input.senderOrgCode},${toDateString(input.publishDate, 'publishDate', ctx)},${strOrNa(input.notation, 'notation', ctx)}/${strOrNa(input.documentCode, 'documentCode', ctx)}`;

  // Generate cid uuid moi cho moi attachment
  const attachmentRefs = input.attachments.map((att, idx) => ({
    contentId: randomUUID(),
    description: `File dinh kem ${idx + 1}`,
    fileName: att.fileName,
    contentType: att.fileType || 'application/octet-stream',
    contentBase64: att.contentBase64,
  }));

  // Root <edXML> voi 3 namespace declarations
  const root = create({ version: '1.0', encoding: 'utf-8' })
    .ele('edXML', {
      'xmlns:xsi': XSI_NS,
      'xmlns:xsd': XSD_NS,
      xmlns: EDXML_NS,
    });

  // <edXML:edXMLEnvelope>
  const envelope = root.ele('edXML:edXMLEnvelope', { 'xmlns:edXML': EDXML_NS });

  // ===== edXMLHeader =====
  const header = envelope.ele('edXML:edXMLHeader');

  // ----- MessageHeader -----
  const messageHeader = header.ele('edXML:MessageHeader');

  // 1.1 From
  messageHeader
    .ele('edXML:From')
      .ele('edXML:OrganId').txt(input.senderOrgCode).up()
      .ele('edXML:OrganizationInCharge').txt(strOrNa(input.senderOrgName, 'senderOrgName', ctx)).up()
      .ele('edXML:OrganName').txt(strOrNa(input.senderOrgName, 'senderOrgName', ctx)).up()
    .up();

  // 1.2 To
  messageHeader
    .ele('edXML:To')
      .ele('edXML:OrganId').txt(input.destOrgCode).up()
      .ele('edXML:OrganizationInCharge').txt(strOrNa(input.destOrgName, 'destOrgName', ctx)).up()
      .ele('edXML:OrganName').txt(strOrNa(input.destOrgName, 'destOrgName', ctx)).up()
    .up();

  // 1.3 Code
  messageHeader
    .ele('edXML:Code')
      .ele('edXML:CodeNumber').txt(strOrNa(input.notation, 'notation', ctx)).up()
      .ele('edXML:CodeNotation').txt(strOrNa(input.documentCode, 'documentCode', ctx)).up()
    .up();

  // 1.4 PromulgationInfo
  messageHeader
    .ele('edXML:PromulgationInfo')
      .ele('edXML:Place').txt('N/A').up()
      .ele('edXML:PromulgationDate').txt(toDateString(input.publishDate, 'publishDate', ctx)).up()
    .up();

  // 1.5 DocumentType (Type=18 = Cong van, default theo C# SDK)
  messageHeader
    .ele('edXML:DocumentType')
      .ele('edXML:Type').txt('18').up()
      .ele('edXML:TypeName').txt(strOrNa(input.docTypeName, 'docTypeName', ctx)).up()
      .ele('edXML:TypeDetail').txt('0').up()
    .up();

  // 1.6 Subject + 1.7 Content (cung gia tri = abstract neu khong co Content rieng)
  const subjectText = strOrNa(input.abstract, 'abstract/subject', ctx);
  messageHeader.ele('edXML:Subject').txt(subjectText).up();
  messageHeader.ele('edXML:Content').txt(subjectText).up();

  // 1.8 SignerInfo
  messageHeader
    .ele('edXML:SignerInfo')
      .ele('edXML:Competence').txt('Truc tiep').up()
      .ele('edXML:Position').txt(strOrNa(input.signerPosition, 'signerPosition', ctx)).up()
      .ele('edXML:FullName').txt(strOrNa(input.signer, 'signer', ctx)).up()
    .up();

  // 1.9 DueDate (default = publish + 2 days)
  const dueDate = new Date(now);
  dueDate.setDate(dueDate.getDate() + 2);
  messageHeader.ele('edXML:DueDate').txt(toDateString(dueDate, 'dueDate', ctx)).up();

  // 1.10 ToPlaces
  messageHeader
    .ele('edXML:ToPlaces')
      .ele('edXML:Place').txt(strOrNa(input.destOrgName, 'destOrgName', ctx)).up()
    .up();

  // 1.11 OtherInfo
  const otherInfo = messageHeader.ele('edXML:OtherInfo');
  otherInfo.ele('edXML:Priority').txt('0').up();
  otherInfo.ele('edXML:SphereOfPromulgation').txt('Lien thong van ban').up();
  otherInfo.ele('edXML:TyperNotation').txt('TVC').up();
  otherInfo.ele('edXML:PromulgationAmount').txt('1').up();
  otherInfo.ele('edXML:PageAmount').txt(String(numOrDefault(input.numberPaper, 1, 'numberPaper', ctx))).up();
  const appendixes = otherInfo.ele('edXML:Appendixes');
  if (input.appendix && input.appendix.trim()) {
    appendixes.ele('edXML:Appendix').txt(input.appendix.trim()).up();
  } else {
    appendixes.ele('edXML:Appendix').txt('').up();
  }
  appendixes.up();
  otherInfo.up();

  // 1.13 SteeringType
  messageHeader.ele('edXML:SteeringType').txt('0').up();

  // 1.14 DocumentId — format chuan: senderOrgCode,YYYY/MM/DD,number/notation
  messageHeader.ele('edXML:DocumentId').txt(docIdValue).up();

  messageHeader.up();

  // ----- TraceHeaderList (4 attributes) -----
  const traceHeaderList = header.ele('edXML:TraceHeaderList', {
    id: genTraceHeaderListId(),
    version: '1.0',
    mustUnderstand: '1',
    actor: SOAP_ACTOR,
  });

  // TraceHeader
  traceHeaderList
    .ele('edXML:TraceHeader')
      .ele('edXML:OrganId').txt(input.senderOrgCode).up()
      .ele('edXML:Timestamp').txt(nowTimestamp).up()
    .up();

  // Bussiness (sibling cua TraceHeader)
  traceHeaderList
    .ele('edXML:Bussiness')
      .ele('edXML:BussinessDocType').txt('0').up() // 0 = Van ban moi
      .ele('edXML:BussinessDocReason').txt('Van ban dien tu moi').up()
      .ele('edXML:StaffInfo')
        .ele('edXML:Department').txt('N/A').up()
        .ele('edXML:Staff').txt(strOrNa(input.signer, 'signer', ctx)).up()
        .ele('edXML:Mobile').txt('').up()
        .ele('edXML:Email').txt('').up()
      .up()
      .ele('edXML:Paper').txt('0').up() // 0 = khong gui giay
    .up();

  traceHeaderList.up();

  // ----- DigitalSignature (empty self-closing) -----
  header.ele('edXML:DigitalSignature').up();

  header.up();

  // ===== edXMLBody (Manifest + References) =====
  const body = envelope.ele('edXML:edXMLBody');
  const manifest = body.ele('edXML:edXMLManifest', { version: '1.0' });

  for (const ref of attachmentRefs) {
    manifest
      .ele('edXML:Reference', {
        'xmlns:xlink': XLINK_NS,
        'xlink:href': `cid:${ref.contentId}`,
        'xlink:role': 'XLinkRole',
        'xlink:type': 'simple',
      })
        .ele('edXML:Description').txt(ref.description).up()
        .ele('edXML:AttachmentName').txt(ref.fileName).up()
        .ele('edXML:ContentType').txt(ref.contentType).up()
        .ele('edXML:ContentId').txt(`cid:${ref.contentId}`).up()
      .up();
  }

  manifest.up();
  body.up();
  envelope.up();

  // ===== AttachmentEncoded (OUTSIDE envelope, default namespace - KHONG prefix edXML:) =====
  if (attachmentRefs.length > 0) {
    const attEncoded = root.ele('AttachmentEncoded');
    for (const ref of attachmentRefs) {
      attEncoded
        .ele('Attachment')
          .ele('ContentType').txt(ref.contentType).up()
          .ele('ContentId').txt(ref.contentId).up() // KHONG cid: prefix o day
          .ele('Description').txt(ref.description).up()
          .ele('ContentTransferEncoded').txt(ref.contentBase64).up()
          .ele('AttachmentName').txt(ref.fileName).up()
        .up();
    }
    attEncoded.up();
  }

  const xmlString = root.end({ prettyPrint: false });
  const buffer = Buffer.from(xmlString, 'utf8');

  logger.info(
    {
      docId: docIdValue,
      docCode,
      destOrgCode: input.destOrgCode,
      senderOrgCode: input.senderOrgCode,
      attachmentCount: input.attachments.length,
      bytes: buffer.length,
    },
    'Built edXML envelope (Phase 37.6 SDK QCVN 102:2016)',
  );

  return {
    buffer,
    docId: internalDocId,
    destOrgCode: input.destOrgCode,
    docCode,
  };
}
