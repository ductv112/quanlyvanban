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

  // Root element may be EdXML or EdXMLEnvelope (namespace prefix stripped by removeNSPrefix)
  const rootKey = Object.keys(parsed).find((k) => k === 'EdXML' || k === 'EdXMLEnvelope');
  if (!rootKey) {
    throw new Error(
      `parseEdxml: root element must be <EdXML> or <EdXMLEnvelope>, found: ${Object.keys(parsed).join(',')}`,
    );
  }
  const root = parsed[rootKey] as Record<string, any>;

  const mh = root.MessageHeader as Record<string, any> | undefined;
  if (!mh) throw new Error('parseEdxml: MessageHeader missing');

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
      promulgator: s(mh.PromulgationInfo?.Promulgator),
      promulgationDate: s(mh.PromulgationInfo?.PromulgationDate),
    },
    documentType: s(mh.DocumentType),
    subject: s(mh.Subject),
    signerInfo: {
      signer: s(mh.SignerInfo?.Signer),
      position: s(mh.SignerInfo?.Position) || undefined,
      competence: s(mh.SignerInfo?.Competence) || undefined,
    },
    otherInfo: {
      pageAmount: num(mh.OtherInfo?.PageAmount),
      appendix: s(mh.OtherInfo?.Appendix) || undefined,
    },
    documentId: s(mh.DocumentId),
    traceHeaderList: mh.TraceHeaderList,
  };

  const attachments: ParsedEdxmlAttachment[] = [];
  const manifest = root.Manifest as Record<string, any> | undefined;
  if (manifest && Array.isArray(manifest.Attachment)) {
    for (const att of manifest.Attachment) {
      const fileName = s(att?.FileName);
      const contentB64 = s(att?.Content);
      if (!fileName || !contentB64) {
        logger.warn({ fileName, hasContent: !!contentB64 }, 'Skipping incomplete attachment');
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
        logger.warn({ fileName, err: err?.message }, 'Skipping attachment with invalid base64');
      }
    }
  }

  return { messageHeader, attachments, raw: xml };
}
