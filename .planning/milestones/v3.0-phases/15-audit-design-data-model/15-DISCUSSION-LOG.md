# Phase 15: Audit & design data model — Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-23
**Phase:** 15-audit-design-data-model
**Mode:** --auto (Claude pick recommended defaults)
**Areas discussed:** Schema strategy, Data model fields, Recipients table, Approver mechanism, Lifecycle workflow, Migration approach, Breaking change mitigation

---

## Schema Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Reset DB clean + bump master schema v2.0 → v3.0 | User approved 2026-04-23, không preserve data v2.0 | ✓ |
| Incremental ALTER + migration script | Preserve data v2.0, complex migration | |
| Side-by-side schema (v2 + v3 parallel) | Risk lớn, dual maintenance | |

**Auto-selected:** Reset DB clean — locked from PROJECT.md decision table

---

## source_type ENUM Values

| Option | Description | Selected |
|--------|-------------|----------|
| `'internal' \| 'external_lgsp' \| 'manual'` | Manual cover cả nhập tay từ giấy + import từ file | ✓ |
| `'internal' \| 'external_lgsp' \| 'external_paper' \| 'external_email'` | Tách chi tiết hơn nguồn ngoài | |
| `'internal' \| 'external'` (boolean simpler) | Đơn giản nhưng mất context LGSP | |

**Auto-selected:** 3 values với 'manual' — đủ phân biệt cho UI filter, không over-engineer

---

## Recipients Table Design

| Option | Description | Selected |
|--------|-------------|----------|
| 1 bảng `outgoing_doc_recipients` + recipient_type ENUM | Match source cũ ListRecipients pattern, query đơn giản | ✓ |
| 2 bảng riêng (`outgoing_internal_recipients` + `outgoing_external_recipients`) | Schema rõ hơn, cần JOIN nhiều khi query | |
| Inline JSONB array trong outgoing_docs.recipients_json | Flexible nhưng khó query/index | |

**Auto-selected:** 1 bảng + ENUM với CHECK constraint XOR (recipient_unit_id XOR recipient_org_id)

---

## Approver Field Type

| Option | Description | Selected |
|--------|-------------|----------|
| `approver VARCHAR(255)` text | Match source .NET cũ, đơn giản, không JOIN | ✓ |
| `approver_id BIGINT FK staff.id` | Type-safe, nhưng cần JOIN khi hiển thị + xử lý người duyệt rời cơ quan | |
| Cả 2 (`approver_id` + `approver_name` snapshot) | An toàn nhất nhưng phức tạp cho v3.0 đầu tiên | |

**Auto-selected:** VARCHAR text — đơn giản như source cũ, đủ cho 1 cấp duyệt

---

## inter_organizations Seeding

| Option | Description | Selected |
|--------|-------------|----------|
| Manual seed 8 cơ quan demo trong Phase 16 | Đủ cho dev/test, sync thật khi có credentials | ✓ |
| Sync from LGSP `/organizations/sync` endpoint ngay | Cần credentials thật, defer Phase 18 | |
| Empty table, để user input qua UI | Quá raw cho dev experience | |

**Auto-selected:** Manual seed — sync thật defer Phase 18 khi có credentials Lào Cai

---

## Lifecycle Workflow Status

| Option | Description | Selected |
|--------|-------------|----------|
| Status text VARCHAR + boolean is_released | Match source cũ, query nhanh | ✓ |
| Native PostgreSQL ENUM type cho status | Type-safe, harder to extend | |
| Numeric status code (1, 2, 3) | Compact nhưng kém readable | |

**Auto-selected:** VARCHAR text + boolean is_released — match source cũ pattern

---

## Stored Procedure Preview Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 15 chỉ list SP signatures preview, Phase 17 implement | Design vs implementation tách rõ | ✓ |
| Phase 15 implement luôn SPs (vào schema file) | Phase 17 chỉ wire UI, faster | |
| Phase 15 không nhắc SP, Phase 17 design + implement | Tách triệt để | |

**Auto-selected:** Preview signatures trong DESIGN.md để Phase 16 implement schema có context

---

## Breaking Change Mitigation

**User's choice:** DESIGN.md MUST list all downstream modules + risk + mitigation plan
- HSCV (`handling_docs`)
- Ký số v2.0 (`sign_transactions`, `attachments`)
- Dashboard widgets
- Báo cáo Excel
- API consumers (frontend pages cũ)

**Notes:** Phase 20 sẽ regression test toàn bộ — Phase 15 design chỉ flag risk, không fix

---

## Claude's Discretion

- ENUM PostgreSQL syntax: native ENUM type (chọn sau khi kiểm existing pattern trong schema)
- Index strategy chi tiết: Claude design dựa trên query pattern
- ERD diagram format: mermaid (consistent với PROJECT.md/CLAUDE.md)
- soft delete policy: Claude verify từng bảng có/không có `is_deleted` cột

## Deferred Ideas

- Multi-level approval workflow (3 cấp: Trưởng phòng → Phó GĐ → Giám đốc) → v3.1
- LGSP credentials production thật → defer Phase 18 khi có thông tin
- MongoDB approval audit log → v3.1
- Migration data v2.0 → v3.0 → user chọn reset clean, không cần
