// ============================================================
// edXML Parser — DUPLICATED from backend/src/services/lgsp/edxml-parser.ts
// Approach B (Phase 34 ratified): worker self-contained, no backend imports.
// MUST stay in sync with backend version. Plan 35-05 verification audit checksum.
// ============================================================
// edXML Parser - Phase 35 Plan 35-01 Task 2
// REQ: LGSP-RECV-04 - parse edXML payload from /v1/getEdoc into typed shape
// Library: fast-xml-parser ^4.4.0
// CONTEXT D-05 (parser config) + D-06 (field mapping)
//
// Pair voi services/lgsp/edxml-builder.ts (Phase 34, xmlbuilder2) — cung 1 nhom
// LGSP envelope handling: builder cho send flow, parser cho receive flow.
// ============================================================
import { XMLParser } from 'fast-xml-parser';
import pino from 'pino';

const logger = pino({ name: 'edxml-parser' });

export interface ParsedEdxmlAttachment {
  fileName: string;
  content: Buffer;
  mimeType?: string;
}

export interface EdxmlMessageHeader {
  from: { organId: string; organName: string };
  to: { organId: string; organName: string };
  code: { codeNumber: string; codeNotation: string };
  promulgationInfo: { promulgator: string; promulgationDate: string };
  documentType: string;
  subject: string;
  signerInfo: { signer: string; position?: string; competence?: string };
  otherInfo: { pageAmount?: number; appendix?: string };
  documentId: string;
  traceHeaderList?: unknown;
}

export interface ParsedEdxml {
  messageHeader: EdxmlMessageHeader;
  attachments: ParsedEdxmlAttachment[];
  raw: string;
}

const parser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '@_',
  parseAttributeValue: false, // keep attrs as strings (org codes)
  parseTagValue: false,       // keep tag values as strings (avoid 123 -> 123 number coercion)
  trimValues: true,
  removeNSPrefix: true,        // strip namespace prefixes e.g. e:EdXMLEnvelope -> EdXMLEnvelope
  isArray: (name) => ['Attachment', 'Path'].includes(name),
});

function s(v: unknown): string {
  if (v === null || v === undefined) return '';
  if (typeof v === 'object') return ''; // empty <Tag/> parsed as {} -> coerce to ''
  return String(v);
}

function num(v: unknown): number | undefined {
  const sv = s(v);
  if (!sv) return undefined;
  const n = Number(sv);
  return Number.isFinite(n) ? n : undefined;
}

/**
 * Parse a raw edXML string into a typed ParsedEdxml.
 *
 * Supports:
 *   - Root <EdXML> or <EdXMLEnvelope> (with or without namespace prefix)
 *   - Optional <Manifest><Attachment>...</Attachment></Manifest>
 *   - Attachment content as base64 string -> Buffer decode
 *
 * @throws Error if XML is malformed, root element missing, or MessageHeader missing.
 */
export function parseEdxml(xml: string): ParsedEdxml {
  if (!xml || typeof xml !== 'string') {
    throw new Error('parseEdxml: empty or non-string input');
  }

  let parsed: Record<string, any>;
  try {
    parsed = parser.parse(xml) as Record<string, any>;
  } catch (err: any) {
    throw new Error(`parseEdxml: invalid XML -- ${err?.message ?? err}`);
  }

  // Phase 37.10: support both layered (Phase 37.8 SDK QCVN 102:2016) + flat (older variants).
  // Root element variants: edXML / EdXML / edXMLEnvelope / EdXMLEnvelope (removeNSPrefix strips edXML:).
  const rootKey = Object.keys(parsed).find(
    (k) => k === 'EdXML' || k === 'edXML' || k === 'EdXMLEnvelope' || k === 'edXMLEnvelope',
  );
  if (!rootKey) {
    throw new Error(
      `parseEdxml: root element must be <edXML>/<EdXML>/<EdXMLEnvelope>, found: ${Object.keys(parsed).join(',')}`,
    );
  }
  const rootNode = parsed[rootKey] as Record<string, any>;

  // Layered SDK structure: edXML > edXMLEnvelope > edXMLHeader > MessageHeader
  // Flat older structure: EdXMLEnvelope > MessageHeader
  const envelope = (rootNode.edXMLEnvelope ?? rootNode.EdXMLEnvelope ?? rootNode) as Record<string, any>;
  const header = (envelope.edXMLHeader ?? envelope.EdXMLHeader ?? envelope) as Record<string, any>;
  const mh = header.MessageHeader as Record<string, any> | undefined;
  if (!mh) throw new Error('parseEdxml: MessageHeader missing');

  // DocumentType: Phase 37.8 nested {Type, TypeName, TypeDetail}, older = flat string
  const docTypeNode = mh.DocumentType;
  const documentType =
    typeof docTypeNode === 'string'
      ? docTypeNode
      : s(docTypeNode?.TypeName) || s(docTypeNode?.Type);

  // SignerInfo: Phase 37.8 uses FullName, older uses Signer
  const signerName = s(mh.SignerInfo?.FullName) || s(mh.SignerInfo?.Signer);

  const messageHeader: EdxmlMessageHeader = {
    from: {
      organId: s(mh.From?.OrganId),
      organName: s(mh.From?.OrganName),
    },
    to: {
      organId: s(mh.To?.OrganId),
      organName: s(mh.To?.OrganName),
    },
    code: {
      codeNumber: s(mh.Code?.CodeNumber),
      codeNotation: s(mh.Code?.CodeNotation),
    },
    promulgationInfo: {
      // Phase 37.8 dung Place thay vi Promulgator (signer info da co o SignerInfo)
      promulgator: s(mh.PromulgationInfo?.Place) || s(mh.PromulgationInfo?.Promulgator),
      promulgationDate: s(mh.PromulgationInfo?.PromulgationDate),
    },
    documentType,
    subject: s(mh.Subject),
    signerInfo: {
      signer: signerName,
      position: s(mh.SignerInfo?.Position) || undefined,
      competence: s(mh.SignerInfo?.Competence) || undefined,
    },
    otherInfo: {
      pageAmount: num(mh.OtherInfo?.PageAmount),
      appendix: s(mh.OtherInfo?.Appendixes?.Appendix) || s(mh.OtherInfo?.Appendix) || undefined,
    },
    documentId: s(mh.DocumentId),
    traceHeaderList: header.TraceHeaderList ?? mh.TraceHeaderList,
  };

  const attachments: ParsedEdxmlAttachment[] = [];

  // Phase 37.8 SDK QCVN 102:2016: AttachmentEncoded sibling cua envelope (outside)
  // Cau truc: <AttachmentEncoded> <Attachment> <ContentTransferEncoded/> <AttachmentName/> <ContentType/> </Attachment> </AttachmentEncoded>
  const attEncoded = rootNode.AttachmentEncoded as Record<string, any> | undefined;
  if (attEncoded && Array.isArray(attEncoded.Attachment)) {
    for (const att of attEncoded.Attachment) {
      const fileName = s(att?.AttachmentName);
      const contentB64 = s(att?.ContentTransferEncoded);
      if (!fileName || !contentB64) {
        logger.warn({ fileName, hasContent: !!contentB64 }, 'Skipping incomplete AttachmentEncoded');
        continue;
      }
      try {
        const buf = Buffer.from(contentB64, 'base64');
        attachments.push({
          fileName,
          content: buf,
          mimeType: s(att?.ContentType) || undefined,
        });
      } catch (err: any) {
        logger.warn({ fileName, err: err?.message }, 'Skipping AttachmentEncoded invalid base64');
      }
    }
  }

  // Fallback older format: <Manifest><Attachment><FileName/><Content/></Attachment></Manifest>
  const manifest = (envelope.Manifest ?? envelope.edXMLManifest) as Record<string, any> | undefined;
  if (attachments.length === 0 && manifest && Array.isArray(manifest.Attachment)) {
    for (const att of manifest.Attachment) {
      const fileName = s(att?.FileName);
      const contentB64 = s(att?.Content);
      if (!fileName || !contentB64) {
        logger.warn({ fileName, hasContent: !!contentB64 }, 'Skipping incomplete Manifest attachment');
        continue;
      }
      try {
        const buf = Buffer.from(contentB64, 'base64');
        attachments.push({
          fileName,
          content: buf,
          mimeType: s(att?.FileType) || undefined,
        });
      } catch (err: any) {
        logger.warn({ fileName, err: err?.message }, 'Skipping Manifest invalid base64');
      }
    }
  }

  return { messageHeader, attachments, raw: xml };
}
