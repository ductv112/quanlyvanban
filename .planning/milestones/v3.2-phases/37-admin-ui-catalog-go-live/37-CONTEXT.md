# Phase 37: Admin UI + Catalog + Go-live - Context

**Gathered:** 2026-05-21
**Status:** Ready for planning
**Mode:** Smart discuss — user accept all 4 area defaults (production-grade per memory `project_production_ready.md`)

<domain>
## Phase Boundary

Admin có UI tự cấu hình credential LGSP per-unit + test connection trước khi bật, có catalog đơn vị ngoài để chọn khi gửi VB external, **menu LGSP hiện lại trên sidebar** (xóa khỏi `hidden-routes.ts`), retry button cho event error (outbox Phase 36 + tracking Phase 34). Roll-out Wave 1 sandbox → Wave 2 prod qua toggle `is_active` per row, KHÔNG cần deploy/restart.

**Trong scope:**
- **3 page admin UI mới** dưới `(main)/lgsp/`:
  1. `/lgsp` — Overview dashboard (6 DN × 2 env grid status + tracking summary today + "Sync ngay" button)
  2. `/lgsp/co-quan` — CRUD catalog `inter_organizations` + "Sync từ LGSP" button + tag "Tự đăng ký" cho row Phase 35 auto-INSERT
  3. `/lgsp/cau-hinh` — Admin only. Table 12 row (6 DN × 2 env). Edit secret_key (password input + masked display), base_url, system_id, is_active toggle, "Test connection" button (gọi sandbox/prod thật), show last_synced_at + last_sync_error per row
- Backend admin endpoints (admin role required):
  - `GET /api/admin/lgsp-agency-config` list all 12 row (KHÔNG decrypt secret, chỉ show `secret_key_masked='***'`)
  - `PUT /api/admin/lgsp-agency-config/:id` update credential (encrypt secret_key bằng SIGNING_SECRET_KEY)
  - `POST /api/admin/lgsp-agency-config/:id/test` test connection (gọi LGSP `/v1/syncReceivedEdocList?fromDate=now-1d&toDate=now` — lightweight read-only test) return `{ok, message, http_status, response_summary}`
  - `PATCH /api/admin/lgsp-agency-config/:id/active` toggle `is_active` (skip cron khi false)
  - `POST /api/admin/lgsp-status-outbox/:id/retry` reset event sent_status='pending' + retry_count=0 + next_retry_at=NOW (Phase 36 outbox retry)
  - `POST /api/admin/lgsp-tracking/:id/retry` reset tracking + re-enqueue lgsp-send job (Phase 34 tracking retry)
  - `POST /api/admin/inter-organizations` create/update/delete (CRUD catalog)
  - `GET /api/admin/lgsp-overview` dashboard summary (counts today: sent/received/pending/error per DN)
- Frontend retry button:
  - Phase 36-04 Timeline entry sent_status='error' → button "Gửi lại" gọi outbox retry endpoint
  - Phase 34-04 badge per-recipient external_org error → button "Gửi lại" gọi tracking retry endpoint
- **Unhide menu LGSP** trong `hidden-routes.ts`: xóa `/lgsp` + `/lgsp/co-quan`; thêm sidebar entry `/lgsp/cau-hinh` admin only
- Production roll-out doc trong `deploy/MANUAL_UPDATE_PROD.md` section "Kích hoạt LGSP v3.2"
- Final milestone v3.2 verification report SHIP-READINESS.md aggregate 4 phase 34-37

**Ngoài scope (defer v3.3+):**
- Mã 13/15/16 sender-side (lấy lại) → defer (sender retract flow chưa nhiều use case)
- Bulk retry admin page → per-event retry trong UI detail đủ
- HDSD full refresh (per memory `project_hdsd_refresh_backlog.md`) → defer (KH self-onboarding qua admin UI inline help text)
- Feature flag advanced (gradual rollout per cookie) → defer
- Admin audit log tab LGSP actions → defer (MongoDB audit module v3.3+)
- DLQ tách bảng → defer
- MongoDB audit hook → defer
- Schema thay đổi → KHÔNG cần (lgsp_agency_config + inter_organizations + lgsp_status_outbox đã đủ)

</domain>

<decisions>
## Implementation Decisions

### Area 1: Admin UI Scope

- **D-01: 3 page admin UI:**
  1. `/lgsp` Overview dashboard (`(main)/lgsp/page.tsx` NEW) — grid 6 DN × 2 env card status, tracking summary (gửi today / nhận today / pending / error count per DN), button "Sync ngay" gọi Phase 35 `/api/lgsp/sync-now` endpoint
  2. `/lgsp/co-quan` Catalog (`(main)/lgsp/co-quan/page.tsx` — verify exist từ Phase 18 hoặc NEW) — Table list inter_organizations với CRUD (Drawer add/edit per pattern dự án), filter "Tự đăng ký" (`is_active=false AND code is set`), "Sync từ LGSP" button gọi Phase 18 `/organizations/sync`
  3. `/lgsp/cau-hinh` Admin only (`(main)/lgsp/cau-hinh/page.tsx` NEW) — Table 6 DN × 2 env (12 row max). Per row: edit secret_key (password input, masked display "***" khi load), base_url, system_id, is_active toggle, "Test connection" button, last_synced_at + last_sync_error display
- **D-02: Test connection:** `POST /api/admin/lgsp-agency-config/:id/test` → backend lookup credential từ row → gọi `LGSPRealService.receiveDocuments(formatLgspDate(now-1d), formatLgspDate(now))` lightweight read (KHÔNG có side effect — chỉ test endpoint reachable + auth OK) → return `{ok: boolean, message: string, http_status: number, response_summary: { count: number } | null}` → Modal AntD hiển thị kết quả inline với icon green/red
- **D-03: Catalog `/lgsp/co-quan`:** Reuse table `edoc.inter_organizations` (đã có Phase 18 + Phase 35 auto-INSERT). Form CRUD AntD Drawer pattern dự án. Filter dropdown: "Tất cả / Đã xác nhận (is_active=true) / Tự đăng ký (is_active=false từ Phase 35)". "Sync từ LGSP" button gọi `POST /organizations/sync` Phase 18 (verify still works — có thể cần fix sang `/v1/getAgenciesList` real endpoint nếu Phase 18 sai)
- **D-04: Page `/lgsp` overview:** Dashboard layout — top section grid 6 cards (1 per DN root unit) hiển thị: tên DN, environment active (badge sandbox/prod), is_active state, last_synced_at, last_sync_error truncated. Bottom section: 3 stat cards (gửi today count, nhận today count, callback today success/error). Button "Sync ngay" trên top right gọi `/api/lgsp/sync-now` Phase 35

### Area 2: Retry + Status Management

- **D-05:** Outbox retry endpoint:
  - `POST /api/admin/lgsp-status-outbox/:id/retry` admin role
  - SQL: `UPDATE edoc.lgsp_status_outbox SET sent_status='pending', retry_count=0, next_retry_at=NOW(), error_message=NULL, sent_at=NULL WHERE id=$1 AND sent_status='error'`
  - Response: `{success: true, message: 'Da reset event, cron se gui lai trong vong 30s'}`
  - Frontend (Phase 36-04 Timeline entry sent_status='error') thêm button "Gửi lại" gọi endpoint → toast success → polling 10s tự refresh
- **D-06:** Tracking retry endpoint (Phase 34 send):
  - `POST /api/admin/lgsp-tracking/:id/retry` admin role
  - SQL: `UPDATE edoc.lgsp_tracking SET status='pending', error_message=NULL WHERE id=$1 AND status='error'`
  - Backend logic: lookup tracking row → outgoing_doc_id → call `addLgspSendJob({recipient_id, outgoing_doc_id, tracking_id, sender_unit_id, environment})` (mirror Phase 34-03 enqueue)
  - Frontend (Phase 34-04 badge error) thêm Tooltip + button "Gửi lại"
- **D-07:** Mã 13/15/16 (sender retract) → **Defer v3.3+**. Document trong `.planning/REQUIREMENTS.md` future req `LGSP-RETRACT-13/15/16`. Schema CHECK constraint Phase 33 đã chấp nhận values này — sẵn cho future implement.
- **D-08:** Bulk retry page → **Defer v3.3+**. Per-event retry inline UI đủ cho v3.2.

### Area 3: Menu + Go-live

- **D-09:** Unhide menu — modify `frontend/src/config/hidden-routes.ts`:
  - REMOVE `'/lgsp'` + `'/lgsp/co-quan'` từ Set
  - KHÔNG remove `/thong-bao-kenh` (vẫn ẩn)
  - Sidebar `MainLayout.tsx` đã có entries Phase 18: verify line 273-274 (Liên thông LGSP + Cơ quan liên thông)
  - THÊM entry sidebar mới `/lgsp/cau-hinh` Cấu hình kết nối với icon `<SettingOutlined />` (admin only — wrap trong existing admin role check pattern)
- **D-10:** Sidebar group "TÍCH HỢP" final layout (extend Phase 18 line 269+):
  - `/lgsp` Liên thông LGSP (tất cả user xem được)
  - `/lgsp/co-quan` Cơ quan ngoài (admin)
  - `/lgsp/cau-hinh` Cấu hình kết nối (admin only — KHÔNG hiện cho user thường)
  - Existing entries khác giữ nguyên
- **D-11:** Production roll-out doc — APPEND section vào `deploy/MANUAL_UPDATE_PROD.md`:
  ```markdown
  ## Kích hoạt LGSP v3.2 (post-deploy)
  
  1. Admin SSH/RDP → backend đã restart sau `pm2 restart all --update-env`
  2. Browser → admin login → menu "TÍCH HỢP" → "Cấu hình kết nối"
  3. Form load 12 row (6 DN × 2 env sandbox/prod, all is_active=false default)
  4. Wave 1 (sandbox) — enable 3 sandbox row:
     - DN.001 sandbox: nhập secret_key từ List.txt → "Test connection" → green PASS → toggle is_active=true
     - DN.002 sandbox: tương tự
     - DN.003 sandbox: tương tự
  5. Verify receive/send/status callback E2E (gửi VB test giữa 3 DN qua Postman)
  6. Wave 2 (prod) — enable 6 prod row TỪ TỪ:
     - DN.001 prod: nhập secret_key từ QLVBDNAgencies.xlsx → Test connection → PASS → toggle is_active=true
     - Verify VB real từ DN.001 prod đến/đi ≥ 10 lần trong 24h
     - Enable từng DN.002 → DN.006 prod tương tự
  7. Monitoring: dashboard `/lgsp` tracking summary mỗi vài giờ
  ```
- **D-12:** Wave plan documented + Postman test edXML samples đính kèm trong `deploy/MANUAL_UPDATE_PROD.md`

### Area 4: Verification + Schema + Milestone Wrap

- **D-13:** Schema = **KHÔNG cần** — lgsp_agency_config + inter_organizations + lgsp_status_outbox + lgsp_tracking đã đủ
- **D-14:** HDSD = defer v3.3+ per memory. Phase 37 chỉ thêm inline help text trong UI form (Tooltip, Alert.info) + section MANUAL_UPDATE_PROD.md
- **D-15:** E2E test Phase 37 (gating):
  - Admin login → /lgsp/cau-hinh → load 12 row → all is_active=false, secret_key masked '***'
  - Edit DN.001 sandbox: nhập secret_key thật → save → SQL verify `pgp_sym_decrypt` ra plaintext đúng
  - "Test connection" DN.001 sandbox → modal hiển thị OK + http_status 200 (hoặc 401 credential rotation caveat — same Phase 34-05/35-05/36-05 pattern)
  - Toggle is_active=true → cron run pickup DN.001
  - /lgsp/co-quan: CRUD 1 org + filter "Tự đăng ký" hiển thị Phase 35 auto-registered row
  - /lgsp: dashboard load OK với 6 DN cards + tracking stats today
  - VB đến detail Timeline entry error → click "Gửi lại" → outbox row reset pending → wait 30s → success/error
  - VB đi badge error → click "Gửi lại" → tracking + lgsp-send job re-enqueue → success/error
  - Menu LGSP hiện sidebar sau khi xóa hidden-routes (verify với non-admin user vẫn thấy /lgsp + /lgsp/co-quan nhưng KHÔNG thấy /lgsp/cau-hinh)
- **D-16:** Final milestone v3.2 SHIP-READINESS report:
  - Aggregate 4 phase 34-37 VERIFICATION-REPORT
  - Summary 36 REQ-IDs status (LGSP-CRED-01..05 + STATUS-01 Phase 33 done; LGSP-SEND-01..06 Phase 34 done; LGSP-RECV-01..07 Phase 35 done; LGSP-STATUS-02..10 Phase 36 done; LGSP-UI-01..08 Phase 37 done)
  - Known caveats: sandbox credential rotation (Phase 34/35/36 same pattern — Phase 37 admin UI cho phép fix), worker race tick+event same-queue (defer split → v3.3+)
  - Roll-out wave plan doc reference
  - Final commit `feat(v3.2): milestone go-live ready` tag-able cho release

### Claude's Discretion

- Tên file kebab-case, page Next.js App Router pattern
- AntD 6 Drawer cho add/edit, Popconfirm cho delete
- Vietnamese diacritics ALL UI text
- Password input cho secret_key — autocomplete="new-password" + masked display khi load
- `useApp().message` cho toast
- Filter dropdown allowClear
- Skeleton loading cho Table/Cards
- Approach: gọi admin endpoint qua `api.get/post/put` với token

### Folded Todos

None.

</decisions>

<canonical_refs>
## Canonical References

### LGSP API Spec

- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/LTVB_API_TRUC_PROD_TICHHOP.postman_collection.json` — `/v1/syncReceivedEdocList` + `/v1/sendEdoc` + `/v1/updateStatus` (Test connection sẽ dùng syncReceivedEdocList vì lightweight read-only)
- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/List.txt` — sandbox credential
- `docs/Trục EDOC Lạng Sơn - QLVB Doanh nghiệp/QLVBDNAgencies.xlsx` — prod credential (Admin sẽ copy paste vào UI)

### Code đã có (reuse)

- `e_office_app_new/backend/src/services/lgsp-real.service.ts` (Phase 34/35/36 fixed) — Test connection dùng `receiveDocuments()`
- `e_office_app_new/backend/src/services/lgsp.service.ts` factory `getLgspService(unit_id, env)` (Phase 33)
- `e_office_app_new/backend/src/repositories/lgsp-agency-config.repository.ts` — verify có update method (Phase 33), thêm `markActive`, `getAllFor admin (KHÔNG decrypt secret)` nếu thiếu
- `e_office_app_new/backend/src/repositories/lgsp-status-outbox.repository.ts` (Phase 36) — thêm `resetForRetry(id)` method
- `e_office_app_new/backend/src/repositories/inter-organization.repository.ts` (Phase 35-01) — extend với CRUD admin methods
- Phase 18 routes/lgsp.ts existing endpoints (verify):
  - `GET /organizations` list (reuse cho dashboard)
  - `POST /organizations/sync` sync from LGSP (verify still works real endpoint `/v1/getAgenciesList`)
- `e_office_app_new/frontend/src/app/(main)/ky-so/cau-hinh/page.tsx` 1291 lines — **CLOSEST ANALOG** cho `/lgsp/cau-hinh` pattern (per-row credential edit + masked password + test connection button)
- `e_office_app_new/frontend/src/config/hidden-routes.ts` (modify — xóa 2 entry)
- `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` line 269-274 (admin only group "TÍCH HỢP" — thêm entry mới `/lgsp/cau-hinh`)
- `e_office_app_new/frontend/src/lib/lgsp-source-badge.tsx` + `lgsp-status-labels.ts` + `LgspStatusTimeline` (Phase 35-04/36-04 — extend với retry button trong Timeline + badge)
- `e_office_app_new/frontend/src/hooks/use-lgsp-status-history.ts` (Phase 36-04 polling hook — reuse)
- `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx` (Phase 34-04 badge + polling — extend với retry button)
- `e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx` (Phase 35-04 detail + Phase 36-04 Timeline — extend với retry button)

### Phase 34/35/36 SUMMARYs + VERIFICATION-REPORTs

- `.planning/phases/34-send-flow-sendedoc/34-04-SUMMARY.md` (frontend badge pattern)
- `.planning/phases/35-receive-flow-cron-syncreceivededoclist/35-04-SUMMARY.md` (frontend tag + detail section)
- `.planning/phases/36-status-callback-chain-9-ma-qd-28/36-04-SUMMARY.md` (Timeline + polling hook)
- `.planning/phases/34-05-VERIFICATION-REPORT.md` + 35-05 + 36-05 (template cho final SHIP-READINESS report Phase 37)

### Project rules

- `CLAUDE.md` § "Customer-Facing Scope" — Phase 37 unhide menu LGSP. KHÔNG nhắc các module ẩn khác (Lịch họp, Kho lưu trữ...) trong UI inline help
- `CLAUDE.md` § "Deploy Pitfalls" #11 — script ops không interactive
- `CLAUDE.md` § "Deploy Pitfalls" #14 — SIGNING_SECRET_KEY rotation rule (Phase 37 admin UI cho phép Admin nhập credential thật vào)
- `CLAUDE.md` § "Quy ước form" — maxLength, validation, password input pattern
- Memory `project_production_ready.md` — production-grade no shortcut
- Memory `project_hdsd_refresh_backlog.md` — defer HDSD full refresh

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `getLgspService(unit_id, env)` factory với cache invalidation Phase 33 — Phase 37 admin "Test connection" gọi
- `LGSPRealService.receiveDocuments(fromDate, toDate)` lightweight call cho test
- `lgspAgencyConfigRepository.update()` Phase 33 (verify exists; nếu chỉ có insert/setActive thì add)
- `inter_organizations` table + Phase 35-01 `autoRegisterFromLgsp` + Phase 18 `/organizations/sync`
- `pool.query` raw SQL cho admin retry endpoints
- Phase 36-04 `useLgspStatusHistory` hook + `LgspStatusTimeline` component — extend với retry button
- Phase 34-04 `useRecipientsPolling` hook + badge state machine — extend với retry button
- `requireRoles('Quản trị hệ thống')` middleware (Phase 35-03 verified)
- AntD 6 Form pattern dự án (Drawer + validateTrigger='onSubmit')

### Established Patterns

- Repository const object
- Admin endpoints `/api/admin/<resource>/<action>` (gom riêng namespace)
- Encrypted credential decrypt LAZY ở service layer
- Password input `<Input.Password>` + autocomplete="new-password"
- Masked display khi load (KHÔNG hiển thị plaintext secret_key cho admin — chỉ '***' + cho phép edit by typing new)
- Test connection → Modal AntD inline result
- Retry endpoint pattern: lookup → reset state → re-enqueue (if applicable)

### Integration Points

- `frontend/src/config/hidden-routes.ts` — modify Set
- `frontend/src/components/layout/MainLayout.tsx` line 269-274 — thêm `/lgsp/cau-hinh` entry
- 3 NEW pages dưới `(main)/lgsp/`
- `backend/src/routes/lgsp.ts` extend hoặc tạo `backend/src/routes/admin-lgsp.ts` riêng
- `backend/src/repositories/{lgsp-agency-config, lgsp-status-outbox, lgsp-tracking, inter-organization}.repository.ts` extend với admin methods
- `deploy/MANUAL_UPDATE_PROD.md` append section
- Phase 34-04 + 36-04 frontend pages extend với retry button

</code_context>

<specifics>
## Specific Ideas

- **Admin config form layout pattern (mirror /ky-so/cau-hinh):**
  - Table với columns: DN name, Environment (Tag sandbox/prod), SystemId, base_url, secret_key (masked + edit inline / Drawer), is_active toggle, "Test" button, Last synced, Last error
  - Edit row → Drawer mở với form Full edit
  - Test connection → Modal hiển thị spinner → kết quả + http_status + response sample (count VB sync được)
  - Toggle is_active=true → POST endpoint → success message → table refresh

- **Test connection backend handler:**
  ```ts
  router.post('/admin/lgsp-agency-config/:id/test', authenticate, requireRoles('Quản trị hệ thống'), async (req, res) => {
    try {
      const id = Number(req.params.id);
      const config = await lgspAgencyConfigRepository.getById(id);  // decrypt secret_key
      if (!config) return res.status(404).json({ success: false, message: 'Khong tim thay cau hinh' });
      
      const svc = createLgspRealService({
        baseUrl: config.base_url,
        systemId: config.system_id,
        secretKey: config.secret_key_plaintext,  // decrypted
      });
      
      const yesterday = new Date(Date.now() - 24 * 60 * 60 * 1000);
      const today = new Date();
      try {
        const result = await svc.receiveDocuments(formatLgspDate(yesterday), formatLgspDate(today));
        res.json({
          success: true,
          data: {
            ok: true,
            message: 'Ket noi LGSP thanh cong',
            http_status: 200,
            response_summary: { count: result?.length ?? 0 },
          },
        });
      } catch (err) {
        res.json({
          success: true,  // request OK, but test failed
          data: {
            ok: false,
            message: (err as Error).message,
            http_status: (err as any).status || 0,
            response_summary: null,
          },
        });
      }
    } catch (err) {
      handleDbError(err, res);
    }
  });
  ```

- **Retry button trong Timeline (extend Phase 36-04):**
  ```tsx
  {h.sent_status === 'error' && (
    <Space size="small">
      <Tooltip title={h.error_message}>
        <Tag color="red">Lỗi (retry {h.retry_count})</Tag>
      </Tooltip>
      <Button
        size="small"
        icon={<ReloadOutlined />}
        onClick={async () => {
          await api.post(`/admin/lgsp-status-outbox/${h.id}/retry`);
          message.success('Đã reset, sẽ gửi lại trong 30s');
        }}
      >
        Gửi lại
      </Button>
    </Space>
  )}
  ```

- **Sidebar entry mới (extend MainLayout.tsx line 269+):**
  ```tsx
  // TÍCH HỢP group:
  children: [
    { key: '/lgsp', icon: <SwapOutlined />, label: 'Liên thông LGSP' },
    { key: '/lgsp/co-quan', icon: <BankOutlined />, label: 'Cơ quan liên thông' },
    isAdmin && { key: '/lgsp/cau-hinh', icon: <SettingOutlined />, label: 'Cấu hình kết nối' },
    // existing entries...
  ].filter(Boolean)
  ```

- **MANUAL_UPDATE_PROD.md section text format:** Vietnamese KHÔNG dấu (per CLAUDE.md PowerShell rule — file này được copy paste sang PS script đôi khi)

</specifics>

<deferred>
## Deferred Ideas

- Mã 13/15/16 (sender retract Lấy lại) → v3.3+
- Bulk retry admin page → v3.3+
- HDSD full refresh → v3.3+
- Feature flag advanced (gradual rollout) → v3.3+
- MongoDB audit log LGSP actions → v3.3+
- DLQ table tách → v3.3+
- WebSocket realtime sidebar badge unread count → v3.3+
- Admin role assignment audit log → v3.3+
- Sandbox vs prod credential migration tool → v3.3+ (admin tự copy paste qua UI cho v3.2)

### Reviewed Todos (not folded)

None.

</deferred>

---

*Phase: 37-admin-ui-catalog-go-live*
*Context gathered: 2026-05-21 (smart discuss, user accept all 4 area defaults, production-grade)*
*Next: /gsd-plan-phase 37 → /gsd-execute-phase 37 → milestone v3.2 lifecycle audit/complete/cleanup*
