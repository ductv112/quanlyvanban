---
phase: 14-deployment-hdsd-verification
plan: 03
type: execute
wave: 1
depends_on: []
files_modified:
  - .planning/REQUIREMENTS.md
  - .planning/ROADMAP.md
autonomous: true
requirements:
  - DEP-01
tags:
  - planning
  - audit
  - requirements

must_haves:
  truths:
    - ".planning/REQUIREMENTS.md có 41 REQ-IDs (DEP-03 bị remove khỏi v2.0 Requirements list)"
    - ".planning/REQUIREMENTS.md bảng traceability 'Chi tiết REQ → Phase' có 2 column mới: 'Verify Evidence' + 'Status'"
    - "Mọi Verify Evidence cell là command concrete (grep/curl/psql/test) copy-paste chạy được, không viết văn xuôi"
    - "Mọi Status cell là enum Pass/Deferred (không Fail — phase trước đã ship xong)"
    - "Distribution table 'Category summary' update: DEP count 3 → 2 (DEP-01 + DEP-02); Phase load table: Phase 14 count 2 → 1; Total 42 → 41"
    - ".planning/ROADMAP.md Phase 14 section update: remove AC-03 (UAT cover 2 provider), remove DEP-03 reference, adjust 42 REQ → 41 REQ trong AC-04"
  artifacts:
    - path: ".planning/REQUIREMENTS.md"
      provides: "Audit document 41 REQ với verify evidence — blocker check cho production deploy"
      contains: "Verify Evidence"
    - path: ".planning/ROADMAP.md"
      provides: "Phase 14 section adjusted — 3 success criteria còn lại, reference 41 REQ"
      contains: "41 REQ"
  key_links:
    - from: ".planning/REQUIREMENTS.md"
      to: "Actual code/DB/config files"
      via: "Verify Evidence column commands (grep/psql/test -f) point to source of truth"
      pattern: "grep|psql|test -f|docker exec"
    - from: ".planning/ROADMAP.md Phase 14"
      to: ".planning/REQUIREMENTS.md"
      via: "AC-04 text reference '41 REQ-IDs v2.0'"
      pattern: "41 REQ"
---

<objective>
Hoàn tất milestone v2.0 verification document (D-06, D-07, D-08): update `.planning/REQUIREMENTS.md` thêm 2 column `Verify Evidence` + `Status`, remove DEP-03 (D-09), và đồng bộ `.planning/ROADMAP.md` Phase 14 section sau scope cut (D-10 — remove AC-03).

Purpose: Trước khi ship milestone v2.0 cho KH, cần đảm bảo mọi requirement đã claim implemented có **evidence concrete** check được trong 1 command. Current REQUIREMENTS.md chỉ có Pass/Fail status phẳng không có pointer tới code/DB/config — KH hoặc auditor muốn verify phải đi grep toàn repo. Thêm column Verify Evidence biến file này thành acceptance checklist tự-verify, giảm blocker 5-10 giờ audit thành 30 phút chạy commands.

Output:
- `.planning/REQUIREMENTS.md`:
  - Section "v2.0 Requirements": DEP-03 bullet bị remove, total "42 requirements" → "41 requirements"
  - Section "Traceability": bảng "Chi tiết REQ → Phase" thêm column `Verify Evidence`; row DEP-03 bị remove
  - Section "Category summary": DEP-* count 3 → 2, Total 42 → 41
  - Section "Phase load": Phase 14 count 2 → 1, Total 42 → 41
  - Verify Evidence mỗi row là command concrete: code REQ dùng grep/test -f, DB REQ dùng psql/docker, config REQ dùng cat/grep
- `.planning/ROADMAP.md` Phase 14 section:
  - "Requirements: DEP-01, DEP-03" → "Requirements: DEP-01" (DEP-03 removed)
  - "Success Criteria" list 4 → 3: remove AC-03 UAT, remove AC-02 HDSD cấu hình, adjust AC-04 text "42 REQ-IDs" → "41 REQ-IDs"
  - "Goal" text remove Linux mentions nếu có (nếu không có thì giữ)
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/14-deployment-hdsd-verification/14-CONTEXT.md

# Current state của REQUIREMENTS.md (182 dòng, 42 REQ trong 6 category)
@.planning/REQUIREMENTS.md

# Reference: Plan 14-02 seed fix → Verify Evidence cho DEP-01 dựa vào seed file sau fix
@e_office_app_new/database/seed/001_required_data.sql

# Reference: các file phase trước để tạo Verify Evidence commands concrete
# (planner thay mặt đọc nhanh để chọn pattern phù hợp mỗi REQ — không cần load full)
</context>

<tasks>

<task type="auto">
  <name>Task 1: Update REQUIREMENTS.md — remove DEP-03 + add Verify Evidence/Status columns</name>
  <files>.planning/REQUIREMENTS.md</files>
  <read_first>
    - `.planning/REQUIREMENTS.md` toàn bộ (182 dòng)
    - `.planning/phases/14-deployment-hdsd-verification/14-CONTEXT.md` D-06, D-07, D-08 (schema update REQUIREMENTS + table pattern example)
    - `e_office_app_new/database/seed/001_required_data.sql` (DEP-01 evidence = grep this file)
    - `e_office_app_new/frontend/public/root-ca/` directory listing (DEP-02 evidence = ls this)
    - Phase SUMMARYs `.planning/phases/*/SUMMARY.md` relevant — cần 1-2 phase tham khảo pattern command concrete (VD: Phase 11 Plan 11-04 để tìm ASYNC-02 worker poll 5s evidence)
  </read_first>
  <action>
    Edit `.planning/REQUIREMENTS.md` theo 4 change group:

    **CHANGE 1: Section "v2.0 Requirements" → DEP subsection (dòng ~75-80)**

    **TRƯỚC:**
    ```markdown
    ### DEP — Deployment & Docs (3 requirements)

    - [ ] **DEP-01:** Deploy scripts (`deploy/*.sh`, `deploy/*.ps1`) cập nhật seed `signing_provider_config` mặc định disabled (cần admin config sau khi deploy)
    - [ ] **DEP-02:** Copy Root CA Viettel `.cer` + HDSD PDF vào `frontend/public/root-ca/` từ `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/` (build time)
    - [ ] **DEP-03:** HDSD triển khai (`deploy/README.md`) thêm section "Cấu hình ký số sau deploy" hướng dẫn Admin: test connection, distribute Root CA cho end user máy

    **Total: 42 requirements across 6 categories**
    ```

    **SAU:**
    ```markdown
    ### DEP — Deployment & Docs (2 requirements)

    - [x] **DEP-01:** Deploy scripts (`deploy/*.ps1` — Windows-only) cập nhật seed `signing_provider_config` mặc định disabled (cần admin config sau khi deploy)
    - [x] **DEP-02:** Copy Root CA Viettel `.cer` + HDSD PDF vào `frontend/public/root-ca/` từ `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/` (build time)

    > **Note:** DEP-03 (HDSD cấu hình ký số sau deploy) đã được cắt khỏi milestone v2.0 theo quyết định 2026-04-23 (D-09). Defer sang milestone v2.1 khi tích hợp ký số thật trên KH server.

    **Total: 41 requirements across 6 categories**
    ```

    Update DEP-01 text: `deploy/*.sh` → chỉ `deploy/*.ps1` (sync với scope cut Linux D-01).

    **CHANGE 2: Section "Out of Scope" giữ nguyên. Section "Traceability" → Category summary table (dòng ~109-116)**

    **TRƯỚC:**
    ```markdown
    | DEP-*    | 3 | DEP-02 → Phase 13; DEP-01, DEP-03 → Phase 14 |
    ```

    **SAU:**
    ```markdown
    | DEP-*    | 2 | DEP-02 → Phase 13; DEP-01 → Phase 14 |
    ```

    **CHANGE 3: Section "Chi tiết REQ → Phase" table — schema update + remove DEP-03 row**

    **TRƯỚC header:**
    ```markdown
    | Requirement | Phase | Status |
    |-------------|-------|--------|
    ```

    **SAU header:**
    ```markdown
    | Requirement | Phase | Status | Verify Evidence |
    |-------------|-------|--------|-----------------|
    ```

    Fill Verify Evidence cho mỗi row theo pattern (plan sẽ fill concrete command cho 41 REQ):

    **SIGN category (8 REQ):**
    - `SIGN-01`: Phase 9 Complete | Pass | `grep -l "SmartCAProvider\|smartca-vnpt" e_office_app_new/backend/src/lib/signing/`
    - `SIGN-02`: Phase 9 Complete | Pass | `grep -l "MySignProvider\|mysign-viettel" e_office_app_new/backend/src/lib/signing/`
    - `SIGN-03`: Phase 11 Complete | Pass | `test -f e_office_app_new/backend/src/routes/ky-so-sign.ts && grep "router.post.*'/sign'" e_office_app_new/backend/src/routes/ky-so-sign.ts`
    - `SIGN-04`: Phase 8 Complete | Pass | `test -f e_office_app_new/backend/src/lib/signing/pdf-signer.ts && grep -l "computePdfHash\|node-signpdf" e_office_app_new/backend/src/lib/signing/`
    - `SIGN-05`: Phase 11 Complete | Pass | `grep -l "poll.*5000\|36.*attempts\|pollInterval" e_office_app_new/workers/src/`
    - `SIGN-06`: Phase 11 Complete | Pass | `grep "fn_sign_transaction_create" e_office_app_new/database/schema/000_schema_v2.0.sql` (new txn per resign)
    - `SIGN-07`: Phase 11 Complete | Pass | `grep -l "cancel.*sign_transactions\|status.*=.*'cancelled'" e_office_app_new/backend/src/routes/ky-so-sign.ts`
    - `SIGN-08`: Phase 11 Complete | Pass | `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\\d public.attachments" | grep -E "sign_provider_code|sign_transaction_id"`

    **CFG category (7 REQ):**
    - `CFG-01`: Phase 9 Complete | Pass | `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\\d public.signing_provider_config" | grep -E "uq_signing_provider_one_active|is_active.*WHERE"`
    - `CFG-02`: Phase 8 Complete | Pass | `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\\d public.staff_signing_config" | grep -E "PRIMARY KEY.*staff_id.*provider_code"`
    - `CFG-03`: Phase 9 Complete | Pass | `grep -l "test-connection\|testConnection" e_office_app_new/backend/src/routes/ky-so-cau-hinh.ts e_office_app_new/frontend/src/app/\(main\)/ky-so/cau-hinh/`
    - `CFG-04`: Phase 9 Complete | Pass | `grep "pgp_sym_encrypt\|pgp_sym_decrypt" e_office_app_new/database/schema/000_schema_v2.0.sql | head -5`
    - `CFG-05`: Phase 10 Complete | Pass | `test -f "e_office_app_new/frontend/src/app/(main)/ky-so/tai-khoan/page.tsx" && grep "SmartCA\|MySign" "e_office_app_new/frontend/src/app/(main)/ky-so/tai-khoan/page.tsx"`
    - `CFG-06`: Phase 10 Complete | Pass | `grep -l "is_verified\|last_verified_at" e_office_app_new/backend/src/routes/ky-so-tai-khoan.ts`
    - `CFG-07`: Phase 9 Complete | Pass | `grep -l "fn_signing_stats\|dashboard.*stats" e_office_app_new/backend/src/routes/ky-so-cau-hinh.ts`

    **UX category (13 REQ):**
    - `UX-01`: Phase 12 Complete | Pass | `grep -l "Ký số\|ky-so/cau-hinh\|ky-so/tai-khoan\|ky-so/danh-sach" e_office_app_new/frontend/src/components/MainLayout.tsx`
    - `UX-02`: Phase 12 Complete | Pass | `test -f "e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx" && grep -c "Tabs\|Cần ký\|Đang xử lý\|Đã ký\|Thất bại" "e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx"`
    - `UX-03`: Phase 12 Complete | Pass | `grep "fn_ky_so_can_sign_list\|signer_id.*currentUser" e_office_app_new/database/schema/000_schema_v2.0.sql`
    - `UX-04`: Phase 12 Complete | Pass | `grep -A 3 "Đang xử lý\|status.*pending" "e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx" | grep -i "cancel\|hủy"`
    - `UX-05`: Phase 12 Complete | Pass | `grep -l "RootCABanner\|banner.*viettel\|dismiss_root_ca_banner" e_office_app_new/frontend/src/`
    - `UX-06`: Phase 12 Complete | Pass | `grep -A 3 "Thất bại\|failed\|expired" "e_office_app_new/frontend/src/app/(main)/ky-so/danh-sach/page.tsx" | grep -i "resign\|Ký lại"`
    - `UX-07`: Phase 13 Complete | Pass | `grep -l "initiating\|LoadingOutlined.*disabled\|disable.*spam" e_office_app_new/frontend/src/components/SignModal.tsx`
    - `UX-08`: Phase 13 Complete | Pass | `grep "maskClosable.*false\|Đóng.*chạy nền\|Hủy ký số" e_office_app_new/frontend/src/components/SignModal.tsx`
    - `UX-09`: Phase 13 Complete | Pass | `grep -l "countdown\|COUNTDOWN_MS\|3:00\|180_000\|180000" e_office_app_new/frontend/src/components/SignModal.tsx`
    - `UX-10`: Phase 13 Complete | Pass | `grep -l "BellNotification\|SIGN_COMPLETED\|SIGN_FAILED\|toast" e_office_app_new/frontend/src/components/BellNotification.tsx`
    - `UX-11`: Phase 13 Complete | Pass | `grep "dismiss_root_ca_banner\|localStorage" e_office_app_new/frontend/src/components/RootCABanner.tsx`
    - `UX-12`: Phase 12 Complete | Pass | `grep -l "openSign\|useSigning" e_office_app_new/frontend/src/app/\(main\)/van-ban-di/\[id\]/ e_office_app_new/frontend/src/app/\(main\)/van-ban-du-thao/\[id\]/ e_office_app_new/frontend/src/app/\(main\)/ho-so-cong-viec/\[id\]/`
    - `UX-13`: Phase 10 Complete | Pass | `grep -c "ky-so/tai-khoan" "e_office_app_new/frontend/src/app/(main)/thong-tin-ca-nhan/page.tsx"` (Alert pointer link)

    **ASYNC category (6 REQ):**
    - `ASYNC-01`: Phase 11 Complete | Pass | `grep "transaction_id" e_office_app_new/backend/src/routes/ky-so-sign.ts | head -3`
    - `ASYNC-02`: Phase 11 Complete | Pass | `grep -l "BullMQ\|Queue.*signing\|poll.*5000" e_office_app_new/workers/src/`
    - `ASYNC-03`: Phase 11 Complete | Pass | `grep -l "Worker\|processJob\|poll.*provider" e_office_app_new/workers/src/` (worker persists dù UI đóng)
    - `ASYNC-04`: Phase 11 Complete | Pass | `grep "attempts.*1\|redis.*persist\|BullMQ" e_office_app_new/workers/src/` (Redis persistence)
    - `ASYNC-05`: Phase 11 Complete | Pass | `grep -l "io.emit.*SIGN_COMPLETED\|signed_file_path" e_office_app_new/workers/src/`
    - `ASYNC-06`: Phase 11 Complete | Pass | `grep -l "io.emit.*SIGN_FAILED\|error_message" e_office_app_new/workers/src/`

    **MIG category (5 REQ):**
    - `MIG-01`: Phase 8 Complete | Pass | `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\\dt public.signing_provider_config public.staff_signing_config public.sign_transactions"` expect 3 tables
    - `MIG-02`: Phase 8 Complete | Pass | `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\\d public.attachments" | grep -E "sign_provider_code|sign_transaction_id"`
    - `MIG-03`: Phase 8 Complete | Pass | `grep -l "migrate.*sign_phone\|INSERT INTO.*staff_signing_config.*SELECT" e_office_app_new/database/schema/000_schema_v2.0.sql`
    - `MIG-04`: Phase 8 Complete | Pass | `docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\\d public.staff" | grep -c "sign_phone"` expect 0 (column dropped)
    - `MIG-05`: Phase 11 Complete | Pass | `grep -c "/ky-so/mock/sign" e_office_app_new/frontend/src/` expect 0 (migrated to /ky-so/sign)

    **DEP category (2 REQ — after DEP-03 cut):**
    - `DEP-01`: Phase 14 Complete | **Pass** | `grep -A 15 "SMARTCA_VNPT" e_office_app_new/database/seed/001_required_data.sql | grep -c "FALSE"` expect >= 1 AND `ls deploy/*.sh 2>/dev/null | wc -l` expect 0
    - `DEP-02`: Phase 13 Complete | Pass | `ls e_office_app_new/frontend/public/root-ca/` expect `.cer` + `.pdf` files

    **CHANGE 4: Section "Phase load" table (dòng ~167-176)**

    **TRƯỚC:**
    ```markdown
    | Phase 14 | 2 | DEP (2) |
    | **Total** | **42** | — |
    ```

    **SAU:**
    ```markdown
    | Phase 14 | 1 | DEP (1) |
    | **Total** | **41** | — |
    ```

    Và footer `Coverage: 42/42 ✓` → `Coverage: 41/41 ✓ (DEP-03 deferred to v2.1)`.

    **Updated footer line 105 "Total: 42/42":**
    ```markdown
    Mỗi REQ-ID v2.0 map tới đúng 1 phase (8-14). Tổng 41/41 — 100% coverage v2.0 (DEP-03 defer sang v2.1), không có orphan.
    ```

    **Footer timestamp** (dòng 182 hiện tại):
    ```markdown
    *Updated 2026-04-23 — Phase 14 audit: remove DEP-03 (deferred v2.1), add Verify Evidence + Status columns, 41 REQ total*
    ```

    **Lưu ý:** Mọi Verify Evidence phải dùng ABSOLUTE hoặc relative-from-repo-root path. Ký tự đặc biệt trong Next.js route groups `(main)` phải escape shell hoặc quote bằng `"..."`. Backtick trong markdown table cell phải dùng `<code>...</code>` nếu lồng backtick — hoặc dùng single backtick wrap command, không lồng.
  </action>
  <acceptance_criteria>
    - `grep -c "^| DEP-03" .planning/REQUIREMENTS.md` = `0` (row DEP-03 removed)
    - `grep -c "DEP-03" .planning/REQUIREMENTS.md` <= `1` (cho phép 1 mention trong note "defer sang v2.1")
    - `grep -c "Verify Evidence" .planning/REQUIREMENTS.md` >= `1` (column header xuất hiện)
    - `grep -c "| Requirement | Phase | Status | Verify Evidence |" .planning/REQUIREMENTS.md` = `1` (header exact)
    - `grep -c "^| SIGN-" .planning/REQUIREMENTS.md` = `8` (8 rows SIGN với new column)
    - `grep -c "^| CFG-" .planning/REQUIREMENTS.md` = `7`
    - `grep -c "^| UX-" .planning/REQUIREMENTS.md` = `13`
    - `grep -c "^| ASYNC-" .planning/REQUIREMENTS.md` = `6`
    - `grep -c "^| MIG-" .planning/REQUIREMENTS.md` = `5`
    - `grep -c "^| DEP-" .planning/REQUIREMENTS.md` = `2` (DEP-01 + DEP-02, DEP-03 removed)
    - Tổng: `grep -cE "^\| (SIGN|CFG|UX|ASYNC|MIG|DEP)-" .planning/REQUIREMENTS.md` = `41`
    - `grep -c "41 requirements" .planning/REQUIREMENTS.md` >= `1`
    - `grep -c "42 requirements" .planning/REQUIREMENTS.md` = `0` (old total hoàn toàn replaced)
    - `grep -c "41/41" .planning/REQUIREMENTS.md` >= `1`
    - `grep -c "42/42" .planning/REQUIREMENTS.md` = `0`
    - Mỗi Verify Evidence là command concrete: verify random 3 REQ có pattern `grep |test |docker |psql |cat |ls ` trong cột Evidence:
      - `grep -E "^\| SIGN-01.*grep" .planning/REQUIREMENTS.md` match
      - `grep -E "^\| DEP-01.*FALSE" .planning/REQUIREMENTS.md` match
      - `grep -E "^\| MIG-04.*psql" .planning/REQUIREMENTS.md` match
    - Status Pass count: `grep -c "| Pass |" .planning/REQUIREMENTS.md` >= `35` (đa số REQ Pass)
    - `grep -c "DEP count 3" .planning/REQUIREMENTS.md` = `0` (nếu có mention phải update thành "2")
    - Category summary: `grep "DEP-\*" .planning/REQUIREMENTS.md | grep -c " 2 "` >= `1`
    - Phase load: `grep "Phase 14" .planning/REQUIREMENTS.md | grep -c " 1 "` >= `1`
    - Footer timestamp updated: `grep -c "2026-04-23" .planning/REQUIREMENTS.md` >= `1`
  </acceptance_criteria>
  <verify>
    <automated>bash -c 'F=.planning/REQUIREMENTS.md; [ "$(grep -c "^| DEP-03" $F)" = "0" ] && [ "$(grep -c "Verify Evidence" $F)" -ge 1 ] && [ "$(grep -c "| Requirement | Phase | Status | Verify Evidence |" $F)" = "1" ] && [ "$(grep -c "^| SIGN-" $F)" = "8" ] && [ "$(grep -c "^| CFG-" $F)" = "7" ] && [ "$(grep -c "^| UX-" $F)" = "13" ] && [ "$(grep -c "^| ASYNC-" $F)" = "6" ] && [ "$(grep -c "^| MIG-" $F)" = "5" ] && [ "$(grep -c "^| DEP-" $F)" = "2" ] && [ "$(grep -cE "^\| (SIGN|CFG|UX|ASYNC|MIG|DEP)-" $F)" = "41" ] && [ "$(grep -c "41 requirements" $F)" -ge 1 ] && [ "$(grep -c "42 requirements" $F)" = "0" ] && [ "$(grep -c "41/41" $F)" -ge 1 ] && [ "$(grep -c "42/42" $F)" = "0" ] && [ "$(grep -c "| Pass |" $F)" -ge 35 ] && [ "$(grep -c "2026-04-23" $F)" -ge 1 ] && echo OK'</automated>
  </verify>
  <done>
    `.planning/REQUIREMENTS.md`: 41 REQ-IDs (DEP-03 removed), bảng traceability có 2 column mới (Verify Evidence + Status), mỗi REQ có command concrete check được. Footer total = 41, coverage = 41/41.
  </done>
</task>

<task type="auto">
  <name>Task 2: Update ROADMAP.md Phase 14 section — cut AC-03, adjust AC-04, remove Linux mentions</name>
  <files>.planning/ROADMAP.md</files>
  <read_first>
    - `.planning/ROADMAP.md` Phase 14 section (dòng 282-292)
    - `.planning/phases/14-deployment-hdsd-verification/14-CONTEXT.md` D-09, D-10 (scope cut details)
    - `.planning/REQUIREMENTS.md` sau Task 1 (confirm DEP-03 removed, total = 41)
  </read_first>
  <action>
    Edit `.planning/ROADMAP.md` CHỈ section `### Phase 14: ...` (dòng 282-292 hiện tại):

    **TRƯỚC:**
    ```markdown
    ### Phase 14: Deployment + HDSD triển khai + verification
    **Goal**: Hệ thống sẵn sàng deploy cho KH — deploy scripts seed config mặc định disabled, HDSD triển khai hướng dẫn IT cấu hình sau deploy, UAT cuối confirm toàn bộ flow v2.0
    **Depends on**: Phase 13
    **Requirements**: DEP-01, DEP-03
    **Success Criteria** (what must be TRUE):
      1. Deploy scripts (`deploy/*.sh`, `deploy/*.ps1`) seed `signing_provider_config` 2 rows (SmartCA + MySign) với `is_active=false` — Admin bắt buộc phải config sau deploy trước khi ký
      2. `deploy/README.md` có section "Cấu hình ký số sau deploy" hướng dẫn đủ: (a) Admin login → menu Ký số → chọn provider → nhập credentials → test connection; (b) phân phối Root CA Viettel cho end user cài lên máy (nếu chọn MySign)
      3. UAT cuối cover cả 2 provider: tạo test transaction SmartCA VNPT (nếu KH có cấp credentials) hoặc confirm code path qua mock; tương tự MySign; xác nhận migration `staff.sign_phone` không mất data
      4. Checklist acceptance 42 REQ-IDs v2.0 được tick đủ, không có blocker cho production deploy
    **Plans**: TBD
    **UI hint**: no
    ```

    **SAU:**
    ```markdown
    ### Phase 14: Deployment + HDSD triển khai + verification
    **Goal**: Hệ thống sẵn sàng deploy cho KH trên Windows Server + IIS — deploy scripts seed config mặc định disabled + dev workflow documented + REQUIREMENTS.md audit 41 REQ v2.0 với verify evidence. Cleanup Linux scripts không còn support.
    **Depends on**: Phase 13
    **Requirements**: DEP-01
    **Success Criteria** (what must be TRUE):
      1. Deploy scripts (`deploy/*.ps1` — Windows-only; 4 file `.sh` Linux đã xóa khỏi repo) seed `signing_provider_config` 2 rows (SmartCA + MySign) với `is_active=false` và empty credentials — Admin bắt buộc phải config sau deploy trước khi user ký
      2. `deploy/README.md` rewrite Windows-only + thêm section "Development setup sau reset-db" hướng dẫn admin login → menu Ký số → nhập credentials từ `.env.dev-creds` → test connection → lưu
      3. Checklist acceptance **41 REQ-IDs v2.0** (DEP-03 defer sang v2.1) được tick đủ với column `Verify Evidence` concrete (grep/psql/test commands); không có blocker Pass/Deferred cho production deploy
    **Plans**: 3 plans
    Plans:
    - [ ] 14-01-cleanup-linux-rewrite-readme-PLAN.md — Xóa 4 file Linux shell scripts + rewrite deploy/README.md Windows-only
    - [ ] 14-02-seed-fix-dev-workflow-PLAN.md — Fix seed 001_required_data.sql (cả 2 provider disabled + empty creds) + thêm section Development setup vào README
    - [ ] 14-03-requirements-roadmap-audit-PLAN.md — Update REQUIREMENTS.md (41 REQ + 2 column Verify Evidence/Status, remove DEP-03) + đồng bộ ROADMAP.md Phase 14 section
    **UI hint**: no
    ```

    **Thay đổi summary:**
    - Goal: thêm "Windows Server + IIS", "41 REQ", "cleanup Linux"
    - Requirements: `DEP-01, DEP-03` → `DEP-01`
    - Success Criteria: 4 → 3 items (remove old AC-02 HDSD, remove old AC-03 UAT, adjust AC-04 text "42 REQ" → "41 REQ")
    - Plans: "TBD" → "3 plans" với list 3 PLAN filename kèm mô tả ngắn

    **KHÔNG đổi các phase khác** trong ROADMAP.md (Phase 1-13 giữ nguyên). Đặc biệt KHÔNG đụng phần `### v2.0 (Active — Milestone: Tích hợp ký số 2 kênh)` list, chỉ update `### Phase 14: ...` subsection.

    **BONUS FIX** (optional nếu tìm thấy drift): Overview section dòng 10 có `42 REQ-IDs across 6 categories` — có thể update `41 REQ-IDs` cho đồng bộ. Nếu thấy, update kèm.
  </action>
  <acceptance_criteria>
    - `grep -A 15 "^### Phase 14:" .planning/ROADMAP.md | grep -c "DEP-03"` = `0` (không còn mention DEP-03 trong section Phase 14)
    - `grep -A 15 "^### Phase 14:" .planning/ROADMAP.md | grep -c "41 REQ"` >= `1`
    - `grep -A 15 "^### Phase 14:" .planning/ROADMAP.md | grep -c "42 REQ"` = `0`
    - `grep -A 15 "^### Phase 14:" .planning/ROADMAP.md | grep -c "UAT cuối"` = `0` (AC-03 removed)
    - `grep -A 15 "^### Phase 14:" .planning/ROADMAP.md | grep -c "Cấu hình ký số sau deploy"` = `0` (old AC-02 text removed — DEP-03 scope)
    - `grep -A 15 "^### Phase 14:" .planning/ROADMAP.md | grep -c "Windows Server\|Windows-only\|deploy/\*\.ps1"` >= `1`
    - `grep -A 15 "^### Phase 14:" .planning/ROADMAP.md | grep -c "Development setup"` >= `1` (reference Plan 14-02 section)
    - `grep -A 20 "^### Phase 14:" .planning/ROADMAP.md | grep -cE "^  [0-9]\."` = `3` (exactly 3 success criteria items numbered 1/2/3)
    - `grep -A 30 "^### Phase 14:" .planning/ROADMAP.md | grep -c "14-01-cleanup-linux"` = `1`
    - `grep -A 30 "^### Phase 14:" .planning/ROADMAP.md | grep -c "14-02-seed-fix"` = `1`
    - `grep -A 30 "^### Phase 14:" .planning/ROADMAP.md | grep -c "14-03-requirements-roadmap-audit"` = `1`
    - `grep -A 30 "^### Phase 14:" .planning/ROADMAP.md | grep -c "3 plans"` >= `1`
    - Phase 14 section **Requirements** line đúng: `grep -A 5 "^### Phase 14:" .planning/ROADMAP.md | grep -E "^\*\*Requirements\*\*: DEP-01$"` match (chỉ DEP-01, không có DEP-03)
    - Không ảnh hưởng Phase khác: `grep -c "^### Phase " .planning/ROADMAP.md` = số phase header không đổi so với trước (= 15: Phase 1-7, 8-14, 11.1)
  </acceptance_criteria>
  <verify>
    <automated>bash -c 'F=.planning/ROADMAP.md; [ "$(grep -A 15 "^### Phase 14:" $F | grep -c "DEP-03")" = "0" ] && [ "$(grep -A 15 "^### Phase 14:" $F | grep -c "41 REQ")" -ge 1 ] && [ "$(grep -A 15 "^### Phase 14:" $F | grep -c "42 REQ")" = "0" ] && [ "$(grep -A 15 "^### Phase 14:" $F | grep -c "UAT cuối")" = "0" ] && [ "$(grep -A 15 "^### Phase 14:" $F | grep -c "Windows")" -ge 1 ] && [ "$(grep -A 20 "^### Phase 14:" $F | grep -cE "^  [0-9]\.")" = "3" ] && [ "$(grep -A 30 "^### Phase 14:" $F | grep -c "14-01-cleanup-linux")" = "1" ] && [ "$(grep -A 30 "^### Phase 14:" $F | grep -c "14-02-seed-fix")" = "1" ] && [ "$(grep -A 30 "^### Phase 14:" $F | grep -c "14-03-requirements-roadmap-audit")" = "1" ] && echo OK'</automated>
  </verify>
  <done>
    `.planning/ROADMAP.md` Phase 14 section updated: Requirements = DEP-01 only, 3 success criteria (không UAT cover, không HDSD cấu hình), reference 3 plan filenames, mention Windows-only + 41 REQ. Phase khác không bị ảnh hưởng.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| REQUIREMENTS.md → KH auditor / QA | Auditor đọc file để verify milestone shippable |
| ROADMAP.md → team / KH | Source of truth cho status phase + scope delivered |
| Verify Evidence commands → repo files | Commands chạy từ repo root, expose path source code + DB |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-14-03-01 | Information Disclosure | Verify Evidence commands expose internal file paths | accept | Paths đã public trong git (CLAUDE.md, ROADMAP.md mention nhiều path). Chỉ risk là QA chạy command không có quyền đọc — accept vì QA cần access repo mới audit. |
| T-14-03-02 | Spoofing | Fake "Pass" status trên REQ thực ra chưa implement | **mitigate** | Verify Evidence column biến từng claim "Pass" thành command concrete chạy được — auditor chạy command, nếu không match thì REQ actually Fail. Loại bỏ khả năng claim false positive. |
| T-14-03-03 | Tampering | Ai đó edit REQUIREMENTS.md và set "Pass" cho REQ chưa làm | **mitigate** | Git history track mọi change + Verify Evidence commands độc lập với claim status. Auditor rerun commands bất cứ lúc nào để cross-check. |
| T-14-03-04 | Denial of Service | Commands Verify Evidence đòi docker lên → auditor không có docker local không chạy được | accept | Acceptable degradation. Commands grep/test -f đa số không cần docker; chỉ 3-4 MIG-* REQ cần psql. Auditor không có docker vẫn verify được 37+/41 REQ. |
| T-14-03-05 | Repudiation | "Status Pass" hôm nay nhưng code đổi ngày mai → evidence lỗi | mitigate | Command re-runnable — auditor chạy lại bất cứ lúc nào. Nếu regression xảy ra, verify command sẽ fail visible → alert team. |
| T-14-03-06 | Elevation of Privilege | Verify Evidence leak sensitive file path (VD config prod) | accept | Paths chỉ src code + schema + public README. KHÔNG expose `.env` hay credentials path. Tất cả đã public trong repo. |
</threat_model>

<verification>
## Phase-level verification sau 2 task

1. **REQUIREMENTS.md structure:**
   ```bash
   F=.planning/REQUIREMENTS.md
   grep -cE "^\| (SIGN|CFG|UX|ASYNC|MIG|DEP)-" $F     # = 41
   grep -c "^| DEP-03" $F                              # = 0
   grep -c "Verify Evidence" $F                        # >= 1
   grep -c "| Pass |" $F                               # >= 35
   ```

2. **ROADMAP.md consistency với REQUIREMENTS.md:**
   ```bash
   F=.planning/ROADMAP.md
   grep -A 15 "^### Phase 14:" $F | grep "Requirements"   # = "**Requirements**: DEP-01"
   grep -A 30 "^### Phase 14:" $F | grep -c "14-01\|14-02\|14-03"   # = 3
   ```

3. **Sanity check Verify Evidence executable (spot-check 3 random):**
   ```bash
   # DEP-01 evidence (Plan 14-02 sẽ fix seed, chạy sau khi 14-02 done)
   grep -A 15 "SMARTCA_VNPT" e_office_app_new/database/seed/001_required_data.sql | grep -c "FALSE"
   # Expected: >= 1

   # SIGN-04 evidence
   test -f e_office_app_new/backend/src/lib/signing/pdf-signer.ts && echo "SIGN-04 OK"

   # UX-09 evidence
   grep -l "COUNTDOWN_MS\|180_000" e_office_app_new/frontend/src/components/SignModal.tsx
   ```

4. **Cross-file consistency:** REQUIREMENTS.md total count = ROADMAP.md Phase 14 AC-04 text:
   ```bash
   grep -c "41 REQ\|41 requirements" .planning/REQUIREMENTS.md   # >= 2
   grep "41 REQ" .planning/ROADMAP.md   # match in Phase 14 section
   ```

5. **Không regression phase khác trong ROADMAP:**
   ```bash
   # Phase 1-13 section header counts không đổi
   grep -c "^### Phase " .planning/ROADMAP.md   # = 15 (không đổi so với baseline)
   # Phase 11.1 INSERTED marker giữ nguyên
   grep "INSERTED" .planning/ROADMAP.md | wc -l   # >= 1
   ```
</verification>

<success_criteria>
Plan 14-03 hoàn thành khi:
- [ ] `.planning/REQUIREMENTS.md` DEP-03 row removed (grep `^| DEP-03` count = 0)
- [ ] Column `Verify Evidence` thêm vào bảng "Chi tiết REQ → Phase" với command concrete cho 41 REQ
- [ ] Status column có value Pass/Deferred (không Fail)
- [ ] Tổng 41 REQ (grep count = 41), footer "41 requirements" + "41/41" coverage
- [ ] Category summary: DEP-* count 3 → 2; Phase load: Phase 14 count 2 → 1; Total 42 → 41
- [ ] `.planning/ROADMAP.md` Phase 14 section updated: Requirements = DEP-01 only, 3 success criteria, reference 3 plan filenames
- [ ] Phase 1-13 sections không bị ảnh hưởng (grep section count không đổi)
- [ ] Cross-file check: REQUIREMENTS.md 41 REQ count khớp ROADMAP.md AC-04 "41 REQ-IDs"
- [ ] DEP-01 acceptance: Verify Evidence command cho DEP-01 là concrete: `grep -A 15 "SMARTCA_VNPT" seed/001_required_data.sql | grep -c "FALSE"` expect >= 1 AND `ls deploy/*.sh | wc -l` expect 0
</success_criteria>

<output>
After completion, create `.planning/phases/14-deployment-hdsd-verification/14-03-SUMMARY.md` với:
- **What was done:** Remove DEP-03 khỏi REQUIREMENTS.md (41 REQ), thêm Verify Evidence + Status columns cho bảng traceability; update ROADMAP.md Phase 14 section (3 AC, DEP-01 only, 3 plan references)
- **Files modified:** .planning/REQUIREMENTS.md, .planning/ROADMAP.md
- **Affects:** Milestone v2.0 acceptance document, cross-file consistency với Phase 14 plans
- **Provides:** Sign-off checklist cho milestone v2.0 — mỗi REQ có command concrete verify
- **Patterns:** Verify Evidence pattern per category (code=grep/test -f, DB=docker psql, config=cat/ls)
- **Decisions implemented:** D-06 (update REQUIREMENTS.md inline), D-07 (add 2 columns + remove DEP-03), D-08 (concrete commands), D-09 (cut DEP-03 v2.0), D-10 (cut AC-03 khỏi ROADMAP)
- **Blockers/Concerns:** Không có — plan hoàn toàn độc lập file với 14-01 (deploy/) và 14-02 (seed/ + deploy/README.md). Có thể chạy song song Wave 1 với 14-01.
</output>
