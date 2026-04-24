---
phase: 02-h-s-c-ng-vi-c
plan: "03"
subsystem: backend
tags: [workflow, kpi, reports, repository, routes]
dependency_graph:
  requires: [02-01]
  provides: [workflow-crud-api, kpi-api, report-api]
  affects: [server.ts, admin-catalog routes]
tech_stack:
  added: []
  patterns: [repository-pattern, express-router, stored-procedures]
key_files:
  created:
    - e_office_app_new/backend/src/repositories/workflow.repository.ts
    - e_office_app_new/backend/src/routes/workflow.ts
    - e_office_app_new/backend/src/repositories/handling-doc-report.repository.ts
    - e_office_app_new/backend/src/routes/handling-doc-report.ts
  modified:
    - e_office_app_new/backend/src/server.ts
decisions:
  - "Mounted /api/ho-so-cong-viec/thong-ke before /api/ho-so-cong-viec to prevent Express /:id param swallowing 'thong-ke' segment"
  - "getStepLinks uses rawQuery with ANY($1) array parameter — no stored procedure for this cross-step query"
  - "workflow.ts uses /steps/:stepId and /step-links/:linkId as sub-paths on the same router rather than nested routers"
metrics:
  duration: "12 minutes"
  completed_date: "2026-04-14"
  tasks_completed: 2
  tasks_total: 2
  files_created: 4
  files_modified: 1
requirements: [HSCV-08, HSCV-09, HSCV-10]
---

# Phase 02 Plan 03: Workflow CRUD + KPI/Report API Summary

**One-liner:** Workflow designer CRUD API (flows, steps, links, staff assignment) and KPI/report endpoints scoped by unitId from JWT.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create workflow repository + routes | baf6d58 | workflow.repository.ts, workflow.ts |
| 2 | Create KPI/report repository + routes + mount server.ts | 6b9d762 | handling-doc-report.repository.ts, handling-doc-report.ts, server.ts |

## What Was Built

### workflow.repository.ts
14 methods covering full workflow lifecycle:
- `getList` — filtered by unitId, docFieldId, isActive
- `getById` — flow detail with doc_field_name join
- `create` / `update` / `delete` — flow CRUD
- `getSteps` / `createStep` / `updateStep` / `deleteStep` — step CRUD
- `createStepLink` / `deleteStepLink` — step routing links
- `getStepStaff` / `assignStepStaff` — replace-all staff assignment per step
- `getStepLinks(stepIds[])` — rawQuery with ANY($1) for designer full-load

### workflow.ts (13 endpoints)
```
GET    /                      — list flows
POST   /                      — create flow
GET    /:id                   — flow + steps
PUT    /:id                   — update flow
DELETE /:id                   — delete flow
GET    /:id/full              — flow + steps + links (designer view)
POST   /:id/steps             — create step
PUT    /steps/:stepId         — update step
DELETE /steps/:stepId         — delete step
POST   /step-links            — create link
DELETE /step-links/:linkId    — delete link
GET    /steps/:stepId/staff   — list step staff
POST   /steps/:stepId/staff   — assign step staff (replace-all)
```

### handling-doc-report.repository.ts
4 methods all scoped to unitId:
- `getKpi` → `edoc.fn_handling_doc_kpi`
- `reportByUnit` → `edoc.fn_report_handling_by_unit`
- `reportByResolver` → `edoc.fn_report_handling_by_resolver`
- `reportByAssigner` → `edoc.fn_report_handling_by_assigner`

### handling-doc-report.ts (4 endpoints)
```
GET /kpi                       — KPI dashboard data
GET /bao-cao/theo-don-vi       — report by department
GET /bao-cao/theo-can-bo       — report by resolver (curator)
GET /bao-cao/theo-nguoi-giao   — report by assigner (created_by)
```

### server.ts changes
- Added imports for workflowRoutes and handlingDocReportRoutes
- Mounted `/api/ho-so-cong-viec/thong-ke` BEFORE `/api/ho-so-cong-viec` (critical ordering)
- Mounted `/api/quan-tri/quy-trinh` for workflow admin

## Deviations from Plan

None — plan executed exactly as written.

## Threat Model Mitigations Applied

| Threat ID | Mitigation |
|-----------|-----------|
| T-02-10 | All report/KPI endpoints extract unitId from JWT — results are always unit-scoped |
| T-02-11 | Workflow routes require `authenticate` middleware; all handlers validate input before calling SPs |
| T-02-12 | Accepted — date-range aggregation is PostgreSQL-side with indexes |

## Known Stubs

None — all repository methods wire to real stored procedures defined in 011_sprint6_workflow_tables_sps.sql.

## Self-Check: PASSED

- FOUND: workflow.repository.ts
- FOUND: workflow.ts
- FOUND: handling-doc-report.repository.ts
- FOUND: handling-doc-report.ts
- FOUND commit: baf6d58 (Task 1)
- FOUND commit: 6b9d762 (Task 2)
