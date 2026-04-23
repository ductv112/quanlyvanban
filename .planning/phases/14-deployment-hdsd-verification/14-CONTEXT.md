# Phase 14: Deployment + HDSD triển khai + verification — Context

**Gathered:** 2026-04-23
**Status:** Ready for planning
**Source:** Interactive discuss-phase — 10 decisions locked + scope trimmed (cắt 2 REQ/AC)

<domain>
## Phase Boundary

Phase 14 khép lại milestone v2.0 bằng 3 nhóm việc:

1. **Cleanup Windows-only target** — xóa bỏ mọi file Linux (`.sh`), rewrite `deploy/README.md` chỉ Windows Server + IIS
2. **Seed fix cho production safety (DEP-01)** — disable cả 2 provider trong `001_required_data.sql` + xóa dev creds, document dev workflow config provider sau reset-db
3. **Acceptance audit (AC-04 adjusted)** — update `.planning/REQUIREMENTS.md` với column Verify Evidence + Status, audit 41 REQ (sau khi remove DEP-03), báo cáo blocker production deploy

**KHÔNG thuộc Phase 14** (cắt khỏi scope ban đầu):
- **DEP-03 HDSD cấu hình ký số sau deploy** — CẮT HẲN khỏi milestone v2.0 (user feedback: bỏ task này)
- **AC-03 UAT cuối cover 2 provider + migration sign_phone** — CẮT HẲN khỏi milestone v2.0 (defer đến khi tích hợp ký số thật trên KH server)
- **Backup script Windows** — chưa cần (dự án còn test), bỏ `backup.sh` Linux luôn, sau này production chính thức mới bổ sung
- **HDSD chi tiết end user cài Root CA** — đã xong ở Phase 13 (DEP-02 file `public/root-ca/`)
- **Migration `staff.sign_phone` verify** — migration đã consolidate vào schema master Phase 11.1, production re-apply schema idempotent tự đồng bộ; verify thật sự khi KH deploy

**Foundation đã có sẵn:**
- `deploy/deploy-windows.ps1` (16.6KB) — full end-to-end install
- `deploy/update-windows.ps1` (2.2KB) — pull + rebuild + re-apply schema
- `deploy/reset-db-windows.ps1` (8.6KB) — drop + apply schema + seed
- `deploy/setup-iis.ps1` (3.1KB) — IIS config
- `deploy/README.md` (195 dòng) — đã có section Deploy/Update/Reset/Backup/Kiến trúc cho cả 2 OS → chỉ cần remove Linux sections
- `.planning/REQUIREMENTS.md` — đã có list 42 REQ-IDs grouped 6 category

</domain>

<decisions>
## Implementation Decisions (Locked)

### Target OS (NEW locked từ user feedback)

- **D-01:** **Windows Server + IIS ONLY**. Dự án KHÔNG support Linux. Xóa bỏ mọi file `.sh` trong `deploy/`. README viết lại chỉ hướng dẫn Windows.

### Files to DELETE

- **D-02:** Xóa 4 file Linux shell scripts:
  - `deploy/deploy.sh` (14.7KB)
  - `deploy/update.sh` (2.0KB)
  - `deploy/reset-db.sh` (6.0KB)
  - `deploy/backup.sh` (1.0KB)

### Seed strategy DEP-01 (Locked Option A)

- **D-03:** Sửa `e_office_app_new/database/seed/001_required_data.sql`:
  - SmartCA VNPT: `is_active=FALSE`, `client_id=''`, `client_secret=NULL` (hoặc placeholder)
  - MySign Viettel: giữ `is_active=FALSE` (hiện tại đã đúng)
  - Kết quả: production deploy → cả 2 provider disabled, admin bắt buộc login `/ky-so/cau-hinh` enable + nhập real creds
- **D-04:** Dev workflow sau khi seed fix: admin login → menu "Cấu hình ký số" → chọn provider → nhập dev creds (manual 1 lần). Document ngắn 3-5 dòng trong `deploy/README.md` section "Development setup" hoặc `CLAUDE.md` section "Dev setup".
- **D-05:** **KHÔNG** tách 002_demo_data.sql extend dev creds — giữ nguyên hiện tại chỉ seed demo data (transactions, users test). Lý do: nhất quán 1 source of truth, ít risk nhầm lẫn dev vs prod credentials.

### Acceptance Checklist AC-04 (Locked Option A)

- **D-06:** Format: Update file `.planning/REQUIREMENTS.md` đã có inline. KHÔNG tạo file mới `deploy/ACCEPTANCE-v2.0.md` hay section riêng trong deploy/README.md.
- **D-07:** Schema update REQUIREMENTS.md:
  - Thêm column `Verify Evidence` trong bảng 42 REQ-IDs (command grep/curl/psql hoặc path file để check REQ pass)
  - Thêm column `Status` (Pass/Fail/Deferred) — đa số Pass vì phase trước đã verify
  - Remove `DEP-03` khỏi danh sách REQ-IDs (42 → **41 REQ**)
  - Update footer "Total: 42 requirements" → "Total: 41 requirements"
  - Update distribution table (DEP-* count từ 3 → 2)
- **D-08:** Verify Evidence mỗi REQ dạng command concrete:
  - Code REQ (UI-*, SIGN-*, BE-*, UX-*): `grep -l "pattern" path/to/file.ts` hoặc `test -f path/to/file.tsx`
  - DB REQ (MIG-*): `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT ..."` expected result
  - Config REQ (DEP-*): `cat path/to/config | grep ...` expected line
  - Planner sẽ chọn command thực tế per REQ, không cần user chốt từng REQ một

### Scope cut (2 REQ/AC bị cắt khỏi milestone v2.0)

- **D-09:** **CẮT DEP-03** (HDSD cấu hình ký số sau deploy) khỏi `.planning/REQUIREMENTS.md`. Milestone v2.0 không commit deliver task này. Khi tích hợp ký số thật sẽ bổ sung trong milestone v2.1.
- **D-10:** **CẮT AC-03** (UAT cuối cover 2 provider + migration sign_phone verify) khỏi Phase 14 success criteria trong `.planning/ROADMAP.md`. Lý do: máy cá nhân không có real SmartCA/MySign creds, test mock trùng lặp Phase 11 testing đã làm. Verify thật khi KH deploy có real creds.

### Claude's Discretion

- Thứ tự đoạn section trong `deploy/README.md` sau khi remove Linux
- Wording copy tiếng Việt cho section "Development setup" (D-04 document)
- Exact grep/psql commands cho Verify Evidence column (D-08) — planner chọn phù hợp per REQ
- Có giữ lại mention "Linux support" trong README để nói rõ không hỗ trợ, hay xóa hoàn toàn không đề cập
- Có cần thêm banner cảnh báo "Production-ready checklist" đầu README hay không

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Roadmap + Requirements
- `.planning/ROADMAP.md` — Phase 14 section (cần update: remove AC-03, adjust AC-04 count 42→41, remove Linux mentions)
- `.planning/REQUIREMENTS.md` — 42 REQ-IDs hiện tại, phải update thành 41 (remove DEP-03) + thêm Verify Evidence + Status columns

### Prior phase SUMMARY (foundation)
- `.planning/phases/11.1-db-consolidation-seed-strategy/` — Schema master + seed strategy (`001_required_data.sql` có seed provider hiện tại, Phase 14 fix)
- `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-HUMAN-UAT.md` — 4 TC ký số thật đã defer, context cho việc cắt AC-03
- `.planning/phases/13-modal-ky-so-robust-root-ca-ux/13-SUMMARY.md` (nếu có) — DEP-02 Root CA files đã xong

### Deploy files (read-first)
- `deploy/README.md` (195 dòng) — rewrite Windows-only, remove Linux sections
- `deploy/deploy-windows.ps1` — giữ nguyên, reference duy nhất sau khi xóa Linux
- `deploy/update-windows.ps1` — giữ nguyên
- `deploy/reset-db-windows.ps1` — giữ nguyên
- `deploy/setup-iis.ps1` — giữ nguyên
- `deploy/deploy.sh` — xóa (D-02)
- `deploy/update.sh` — xóa (D-02)
- `deploy/reset-db.sh` — xóa (D-02)
- `deploy/backup.sh` — xóa (D-02)

### DB Seed (read-first)
- `e_office_app_new/database/seed/001_required_data.sql` — sửa dòng 188-202 SmartCA insert → is_active=FALSE + empty creds (D-03)
- `e_office_app_new/database/seed/002_demo_data.sql` — giữ nguyên, KHÔNG extend dev creds (D-05)

### Project conventions
- `CLAUDE.md` — section "DB Migration Strategy (v2.0+)" + "Phase Execution Rules" + checklist lỗi 1-14
- `CLAUDE.md` có thể thêm section "Dev setup: config ký số provider sau reset-db" (D-04)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Windows deploy scripts** full set đã sẵn sàng (`deploy-windows.ps1`, `update-windows.ps1`, `reset-db-windows.ps1`, `setup-iis.ps1`) — chỉ cần xóa Linux counterparts, không tạo mới gì
- **Seed file hiện tại** (`001_required_data.sql` dòng 188-217) đã có INSERT INTO `signing_provider_config` cho cả 2 provider — chỉ cần sửa `is_active` + xóa credentials hardcoded
- **REQUIREMENTS.md** structure đã organize theo 6 category (UI-*, SIGN-*, BE-*, MIG-*, UX-*, DEP-*) — chỉ cần thêm 2 column và remove 1 row (DEP-03)
- **README.md** đã có structure 9 section (Yêu cầu server, Chọn scripts, Cấu trúc DB, Env var, Deploy, Update, Reset, Backup, Quản lý) — pattern Linux/Windows song song → remove bên Linux mỗi section

### Established Patterns
- **Seed ON CONFLICT DO NOTHING** — idempotent safe, apply lần 2 không double rows
- **REQUIREMENTS.md markdown table** — mỗi REQ có ID + description, sẵn sàng thêm column
- **Deploy README bilingual code blocks** — Linux bash + Windows powershell song song → remove bash block chỉ giữ powershell

### Integration Points
- `deploy-windows.ps1` → chạy `reset-db-windows.ps1` internal hoặc `deploy-windows.ps1` trigger full flow: docker compose + apply schema + seed
- `reset-db-windows.ps1` → chạy 3 sql file trong thứ tự init → schema → seed 001 (+ optional 002 với `-NoDemo` switch)
- Backend `signing_provider_config` read qua `signing-provider.repository.ts` → repository call SP `public.fn_signing_provider_list` → return rows với is_active filter (sau seed fix: list empty cho to-be-configured providers)

</code_context>

<specifics>
## Specific Ideas & Patterns

### Seed 001 patch pattern (D-03)
```sql
-- TRƯỚC (hiện tại):
INSERT INTO public.signing_provider_config
  (provider_code, provider_name, base_url, client_id, client_secret, ..., is_active, ...)
VALUES (
  'SMARTCA_VNPT', 'SmartCA VNPT', 'https://...', 'real-dev-client-id',
  pgp_sym_encrypt('real-dev-secret', current_setting('app.signing_secret_key')),
  ..., TRUE, ...
)
ON CONFLICT (provider_code) DO NOTHING;

-- SAU (Phase 14):
INSERT INTO public.signing_provider_config
  (provider_code, provider_name, base_url, client_id, client_secret, ..., is_active, ...)
VALUES (
  'SMARTCA_VNPT', 'SmartCA VNPT', 'https://rmgateway.vnptit.vn',
  '', NULL, ..., FALSE, ...
)
ON CONFLICT (provider_code) DO NOTHING;
```

### REQUIREMENTS.md table extend pattern (D-07)
Hiện tại:
```markdown
| Requirement | Phase | Status |
|-------------|-------|--------|
| SIGN-01     | Phase 9 — ... | Complete |
```

Sau Phase 14:
```markdown
| Requirement | Phase | Status | Verify Evidence |
|-------------|-------|--------|-----------------|
| SIGN-01     | Phase 9 — ... | Pass | `grep "provider_adapter" backend/src/lib/signing/*.ts` |
| MIG-05      | Phase 11 — ... | Pass | `docker exec ... -c "SELECT count(*) FROM user_sign_account"` |
```

### Dev setup section addition (D-04)
Thêm vào `deploy/README.md`:
```markdown
## Development setup sau reset-db

Sau khi chạy `reset-db-windows.ps1`, cả 2 provider ký số ở trạng thái **disabled**:

1. Login admin: `admin` / `Admin@123`
2. Menu **Ký số → Cấu hình ký số hệ thống**
3. Chọn provider (SmartCA VNPT hoặc MySign Viettel)
4. Nhập `client_id`, `client_secret`, `base_url` từ file `.env.dev-creds` (nội bộ)
5. Bật toggle **Kích hoạt** → Test connection → Lưu

Production deploy: IT triển khai làm bước tương tự với real credentials từ KH.
```

### Plan breakdown (proposed — let planner confirm)
- **Plan 14-01**: Cleanup Linux + rewrite README Windows-only (2 task — xóa 4 file + edit README)
- **Plan 14-02**: Fix seed `001_required_data.sql` + thêm section "Development setup" README (2 task)
- **Plan 14-03**: Update `.planning/REQUIREMENTS.md` (thêm 2 column, remove DEP-03, 41 REQ audit + fill Verify Evidence + Status) + update `.planning/ROADMAP.md` (Phase 14 success criteria adjust) (1-2 task)

**Total:** 3 plan / 2-3 wave / autonomous:true toàn bộ (không có UAT checkpoint vì cắt AC-03)

</specifics>

<deferred>
## Deferred Ideas

### Milestone v2.1 (sau khi tích hợp ký số thật)
- **HDSD cấu hình ký số sau deploy** (cũ DEP-03) — khi KH cấp real creds, viết HDSD hoàn chỉnh với screenshot
- **UAT cuối cover 2 provider real + sign_phone migration verify** (cũ AC-03) — test real flow SmartCA + MySign trên production server, verify migration data integrity
- **Backup script Windows** (`backup-windows.ps1`) — tạo khi chuyển sang production chính thức
- **Automated smoke test `smoke-test.ps1`** — healthcheck BE, login, API, verify config — nếu cần audit production post-deploy

### Nice-to-have không scope v2.0
- Multi-tenant deploy (multiple KH cùng 1 server)
- Container orchestration (Kubernetes thay Docker Compose)
- Backup off-site (S3/Azure Blob)
- Monitoring dashboards (Grafana + Prometheus)

</deferred>

---

*Phase: 14-deployment-hdsd-verification*
*Context gathered: 2026-04-23 via discuss-phase — 10 decisions locked + scope trimmed 4 AC → 2 AC + 42 REQ → 41 REQ*
