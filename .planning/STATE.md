---
gsd_state_version: 1.0
milestone: v3.2
milestone_name: LGSP Production Go-live cho 6 DN Lạng Sơn
status: shipped
stopped_at: v3.2 milestone COMPLETE — archived to .planning/milestones/v3.2-* — ready for /gsd-new-milestone
last_updated: "2026-05-21T15:45:00.000Z"
last_activity: 2026-05-21 — Completed quick task 260521-v8t: them tinh nang xem truc tiep file dinh kem (PDF/anh/Office qua LibreOffice) cho 4 module VB + HSCV
progress:
  total_phases: 5
  completed_phases: 5
  total_plans: 27
  completed_plans: 27
  percent: 100
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-05-19)

**Core value:** Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước (6 DN Lạng Sơn dùng prod thật trên `doanhnghiep.vatk.org`, là 6 đơn vị cấp cao trong cây tổ chức `departments`)
**Current focus:** Milestone v3.2 SHIPPED — chờ `/gsd-new-milestone` start v3.3+ (backlog: mã 13/15/16, worker queue split, DLQ, MongoDB audit, HDSD refresh round 2)

## Current Position

Milestone: v3.2 ✅ SHIPPED (5/5 phase, 27/27 plan, 36/36 REQ)
Status: SHIPPED — archived
Last activity: 2026-05-21 — milestone v3.2 closed, ROADMAP collapsed, REQUIREMENTS archived to milestones/, MILESTONES.md updated
Resume: `/gsd-new-milestone` để start v3.3+ HOẶC `/gsd-cleanup` để archive phase directories Phase 33-37

## Decisions

- 2026-05-20 (33-01): Append vào master schema thay vì tạo file migrations rời (CLAUDE.md DB Migration Strategy mandate)
- 2026-05-20 (33-01): Reuse SIGNING_SECRET_KEY env var (chung signing module) cho lgsp_agency_config secret_key_encrypted — không tạo LGSP_SECRET_KEY riêng
- 2026-05-20 (33-01): Trigger BEFORE INSERT/UPDATE validate root unit thay vì CHECK constraint (CHECK không gọi subquery được)
- 2026-05-20 (33-01): FK departments ON DELETE RESTRICT (chặn xóa root unit có LGSP config) + FK incoming_docs ON DELETE CASCADE (outbox event mồ côi vô nghĩa)
- 2026-05-20 (33-01): Partial index WHERE sent_status='pending' tối ưu worker poll 30s + regular index per doc cho UI history query
- [Phase 33]: Plan 33-02: Doi UPDATE pattern hardcode dept_id sang match by name keyword (ILIKE) — portable across dev/prod DBs
- [Phase 33-database-core-infrastructure]: Repo Buffer pass-through (KHONG decrypt) — service layer decrypt via crypto.ts
- [Phase 33-database-core-infrastructure]: setActive KHONG atomic single-active (moi DN co the prod+sandbox dong thoi)
- [Phase 33-database-core-infrastructure]: Inline Map cache (khong them lru-cache dep) cho service factory per-unit — max 12 entries, scale Redis pub/sub defer v3.3+
- [Phase 33-database-core-infrastructure]: Backward compat tuyet doi: singleton lgspRealService + getLgspService() no-arg giu nguyen — routes/lgsp.ts khong sua
- [Phase 33-database-core-infrastructure]: Plan 33-05: Frontend 4 TS errors (HSCV + VB pages) → OUT OF SCOPE (verified pre-Phase 33 via git checkout), deferred to /gsd-quick task — Phase 33 backend TS clean
- [Phase 33-database-core-infrastructure]: Plan 33-05: Auto-approve final user checkpoint per delegation mode (all 3 acceptance criteria met: TS backend, idempotent 3x, smoke 6/6 + trigger 2/2)
- [Phase 33-database-core-infrastructure]: Plan 33-05: PLAN baseline 386 SPs outdated — actual 350 + 11 Phase 33 = 361 (VERIFICATION-REPORT.md dùng số correct)

## Performance Metrics

- **v1.0 (shipped 2026-04-18):** 7 phases + 3 quick plans, 26 plans, 4 days, 97.8% HDSD coverage
- **v2.0 (shipped 2026-04-23):** 8 phases (8-14 + 11.1), 39 plans, 3 days, 41/41 REQ Pass
- **v3.0 (shipped 2026-04-24):** 6 phases (15-20), 23 commits chính, 17 bugs UAT fixed, 29/29 REQ Pass
- **v3.1 (shipped 2026-05-19):** 12 phases (21 INFRA + 22-30 EXEC + 31 fix-gom + 32 HDSD), 164+ commits, 15 days, 22/22 REQ complete, 847 TC executed, 90+ bug fixed, 6 KH DN Lạng Sơn dùng prod thật

## v3.2 Phase Plan (5 phases / 36 REQ-IDs)

| Phase | Name | Reqs | Estimated | Depends on |
|---|---|---|---|---|
| 33 | Database + Core Infrastructure | 6 (CRED-01..05 + STATUS-01) | 2 ngày | Phase 17, 18 v3.0 |
| 34 | Send Flow (sendEdoc) | 6 (SEND-01..06) | 3 ngày | Phase 33 |
| 35 | Receive Flow (cron syncReceivedEdocList) | 7 (RECV-01..07) | 3 ngày | Phase 33 |
| 36 | Status Callback Chain (9 mã QĐ 28) | 9 (STATUS-02..10) | 3 ngày | Phase 33 |
| 37 | Admin UI + Catalog + Go-live | 8 (UI-01..08) | 3 ngày | Phase 33-36 |

**Total estimated:** ~14 ngày làm việc

**Roll-out post-Phase 37:** Wave 1 (DN.001/002/003 sandbox) → Wave 2 (DN.004/005/006 prod) qua toggle `lgsp_agency_config.is_active=true` per row — KHÔNG cần deploy/restart.
| Phase 33 P02 | 25min | 4 tasks | 2 files |
| Phase 33-database-core-infrastructure P03 | 12min | 4 tasks | 3 files |
| Phase 33-database-core-infrastructure P04 | 18min | 3 tasks | 2 files |
| Phase 33-database-core-infrastructure P05 | 7min | 3 tasks | 2 files (artifacts, no source) |

## Roadmap Evolution

- 2026-05-05: Phase 21 (LGSP Từ chối tiếp nhận) added → renumber Phase 24 cùng ngày để nhường slot 21-23 cho v3.1 Automation Test. Phase 24 sau đó defer sang v3.2 (do v3.1 re-scope manual execute).
- 2026-05-05: Milestone v3.1 (Automation Test Suite + Bug Fix) started — phase 21-23 cho automation test 847 TC.
- 2026-05-06: **v3.1 RE-SCOPE** — đổi từ "Automation Test Suite production-grade" → "Claude execute 847 TC thủ công + fill Excel + log bug". Lý do: user clarify không có team QA → CI/CD framework irrelevant. Phase 22-30 split theo 9 wave.
- 2026-05-11: Phase 32 added — Audit & cập nhật HDSD (16 module) sau khi test fix nhiều vòng.
- 2026-05-19: **Milestone v3.1 closed** — 12 phases shipped (21 + 22-30 + 31 + 32), 164 commits, 847 TC executed, 90+ bug fixed. UAT Phase 32: 4 passed / 2 skipped (HDSD stale → defer refresh round 2 sang v3.2+).
- 2026-05-19: **Multi-tenant clarification** — User confirm 6 DN Lạng Sơn dùng chung 1 system / 1 DB (mỗi DN = root unit trong cây departments), KHÔNG phải 6 deploy riêng. Architecture v3.2 LGSP phải dùng `lgsp_agency_config` per `unit_id`.
- 2026-05-19: **v3.2 ROADMAP created** — 5 phases (33-37), 36/36 REQ-IDs covered, total ~14 ngày, roll-out wave config-level (toggle `is_active`).

## Session Continuity

Last session: 2026-05-20T04:49:39.293Z
Stopped at: Completed 33-04-PLAN.md (service factory + cache + invalidate)
Resume: `/gsd-execute-phase 33` (continue with Plan 33-02 seed 9 row placeholder) or chain auto-mode

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 260521-v8t | Xem trực tiếp file đính kèm (PDF/ảnh/Office qua LibreOffice) cho 4 module VB + HSCV | 2026-05-21 | 84a03a3 | [260521-v8t-them-tinh-nang-xem-truc-tiep-file-dinh-k](./quick/260521-v8t-them-tinh-nang-xem-truc-tiep-file-dinh-k/) |

### Notes

- Phase 32 UAT note: HDSD đã out-of-date so với reality (code drift 8 ngày). Defer "HDSD full refresh round 2" vào v3.2+ scope.
- 6 DN Lạng Sơn đang dùng prod thật trên `doanhnghiep.vatk.org` — kích hoạt LGSP phải KHÔNG mất data nghiệp vụ KH. Phase 37 roll-out qua toggle config, không deploy.
- Memory `project_lgsp_architecture` + `project_hdsd_refresh_backlog` đã ghi nhận decision context.
- Spec reference: `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/` (HDSD v2.2 PDF + Postman collection + 6 credential Excel + List.txt prod/sandbox endpoint).
