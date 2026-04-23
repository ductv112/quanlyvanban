---
phase: 14-deployment-hdsd-verification
plan: 02
type: execute
wave: 2
depends_on:
  - 01
files_modified:
  - e_office_app_new/database/seed/001_required_data.sql
  - deploy/README.md
autonomous: true
requirements:
  - DEP-01
tags:
  - deployment
  - seed
  - security

must_haves:
  truths:
    - "Sau khi chạy seed 001, cả 2 provider (SmartCA VNPT + MySign Viettel) ở trạng thái disabled (is_active=FALSE)"
    - "Seed 001 không chứa real/dev credentials hardcoded — client_id trống, client_secret placeholder"
    - "Admin login production/dev/test → thấy `/ky-so/cau-hinh` hiển thị 2 provider đều OFF, bắt buộc config trước khi user ký được"
    - "deploy/README.md có section mới hướng dẫn dev setup provider sau reset-db (flow 5 bước admin login → nhập creds từ .env.dev-creds → test connection → lưu)"
  artifacts:
    - path: "e_office_app_new/database/seed/001_required_data.sql"
      provides: "Production-safe seed — 2 provider disabled, empty credentials"
      contains: "FALSE"
    - path: "deploy/README.md"
      provides: "Thêm section '## Development setup sau reset-db' (5-10 dòng)"
      contains: "Development setup"
  key_links:
    - from: "seed/001_required_data.sql"
      to: "backend signing-provider.repository.ts"
      via: "INSERT signing_provider_config rows (disabled)"
      pattern: "is_active.*FALSE|FALSE.*is_active"
    - from: "deploy/README.md"
      to: "UI /ky-so/cau-hinh"
      via: "Development setup section hướng dẫn login → config provider"
      pattern: "ky-so/cau-hinh|Cấu hình ký số"
---

<objective>
Triển khai DEP-01 production-safe: đổi seed provider config từ "SmartCA active với dev creds" → "cả 2 provider disabled + empty creds" (D-03). Thêm section ngắn trong `deploy/README.md` hướng dẫn dev/admin config provider bằng tay sau reset-db (D-04). KHÔNG tách 002_demo_data.sql (D-05).

Purpose: Hiện tại `001_required_data.sql` dòng 196 có hardcoded encrypted `client_secret` từ source .NET cũ. Nếu IT triển khai KH chạy seed này trên server production, họ sẽ có 1 SmartCA provider **đang active với credentials của dev team**. Nguy cơ: KH có thể vô tình ký số gửi qua kênh SmartCA của dev (billing, audit), hoặc credentials bị lộ nếu backup DB rò rỉ. Đổi seed về "cả 2 disabled + empty" buộc admin phải config tay sau mỗi deploy — đây là compliance production deploy checklist.

Output:
- `seed/001_required_data.sql` dòng 187-202: SmartCA VNPT đổi `is_active=FALSE` + `client_id=''` + `client_secret=pgp_sym_encrypt('', v_key)` (giữ encrypt để schema không break)
- `seed/001_required_data.sql` dòng 204-219: MySign Viettel giữ nguyên (đã FALSE + placeholder)
- `deploy/README.md`: append section `## Development setup sau reset-db` trước section `## Tham khảo`
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

# Seed file hiện tại — sửa dòng 187-219
@e_office_app_new/database/seed/001_required_data.sql

# deploy/README.md — file đích append section mới (Plan 14-01 Task 2 rewrite trước)
@deploy/README.md

# CLAUDE.md — reference cho Dev setup section (có thể cross-link)
@CLAUDE.md
</context>

<interfaces>
<!-- Schema signing_provider_config (Phase 8) — minh hoạ required columns cho INSERT -->

```sql
-- Từ schema/000_schema_v2.0.sql (Phase 8-01)
CREATE TABLE public.signing_provider_config (
  provider_code VARCHAR(20) PRIMARY KEY,
  provider_name VARCHAR(100) NOT NULL,
  base_url      VARCHAR(500),
  client_id     VARCHAR(200) NOT NULL DEFAULT '',   -- allow empty string
  client_secret BYTEA,                              -- pgp_sym_encrypt OR NULL
  profile_id    VARCHAR(100),
  extra_config  JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_active     BOOLEAN NOT NULL DEFAULT FALSE,
  created_by    BIGINT,
  updated_by    BIGINT,
  created_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at    TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Partial unique index enforce single-active
CREATE UNIQUE INDEX IF NOT EXISTS uq_signing_provider_one_active
  ON public.signing_provider_config (is_active)
  WHERE is_active = TRUE;
```

Key constraint: `client_id` NOT NULL DEFAULT '' — cho phép empty string. `client_secret` BYTEA nullable. `is_active` có partial unique index chặn 2 row cùng TRUE.

Seed hiện tại dòng 196 dùng `pgp_sym_encrypt('ZjA4MjE4NDg-MjU3Mi00ZDAw', v_key)` — sau fix sẽ thay bằng `pgp_sym_encrypt('', v_key)` để giữ BYTEA column non-null (safer than NULL — `pgp_sym_decrypt` NULL crash runtime) nhưng decrypt ra empty string signal "chưa config".
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: Fix seed 001 — disable SmartCA VNPT + empty creds</name>
  <files>e_office_app_new/database/seed/001_required_data.sql</files>
  <read_first>
    - `e_office_app_new/database/seed/001_required_data.sql` toàn bộ (223 dòng — đặc biệt dòng 187-222 INSERT signing_provider_config)
    - `.planning/phases/14-deployment-hdsd-verification/14-CONTEXT.md` D-03 (seed patch pattern cụ thể: SmartCA TRUE → FALSE, creds hardcoded → empty)
    - `.planning/phases/11.1-db-consolidation-seed-strategy/11.1-02-SUMMARY.md` (context seed strategy — nếu tồn tại)
    - Schema `signing_provider_config` column constraints (from interfaces above)
  </read_first>
  <action>
    Edit `e_office_app_new/database/seed/001_required_data.sql`:

    **TRƯỚC (dòng 187-202 hiện tại):**
    ```sql
      -- SmartCA VNPT (active=TRUE với credentials dev từ source cũ .NET)
      INSERT INTO public.signing_provider_config
        (provider_code, provider_name, base_url, client_id, client_secret,
         profile_id, extra_config, is_active, created_by, updated_by)
      VALUES (
        'SMARTCA_VNPT',
        'SmartCA VNPT',
        'https://gwsca.vnpt.vn',
        '4d00-638392811079166938.apps.smartcaapi.com',
        pgp_sym_encrypt('ZjA4MjE4NDg-MjU3Mi00ZDAw', v_key),
        NULL,
        '{}'::jsonb,
        TRUE,
        1, 1
      )
      ON CONFLICT (provider_code) DO NOTHING;
    ```

    **SAU (thay thế block trên):**
    ```sql
      -- SmartCA VNPT (production-safe: is_active=FALSE + empty credentials)
      -- Admin PHẢI login /ky-so/cau-hinh và nhập real credentials trước khi user ký được.
      -- Xem: deploy/README.md section "Development setup sau reset-db".
      INSERT INTO public.signing_provider_config
        (provider_code, provider_name, base_url, client_id, client_secret,
         profile_id, extra_config, is_active, created_by, updated_by)
      VALUES (
        'SMARTCA_VNPT',
        'SmartCA VNPT',
        'https://gwsca.vnpt.vn',
        '',
        pgp_sym_encrypt('', v_key),
        NULL,
        '{}'::jsonb,
        FALSE,
        1, 1
      )
      ON CONFLICT (provider_code) DO NOTHING;
    ```

    **MySign Viettel block (dòng 204-219 hiện tại):** KHÔNG đổi — đã là `is_active=FALSE` + `client_id=''` + `client_secret=pgp_sym_encrypt('placeholder_not_configured', v_key)`. Chỉ cập nhật comment từ `-- MySign Viettel (active=FALSE, placeholder chưa cấu hình)` → `-- MySign Viettel (production-safe: is_active=FALSE + placeholder credentials)` để đồng nhất wording với SmartCA block.

    **KHÔNG đổi các phần khác** của file 001 (positions, departments, staff admin, roles, rights, doc_types — giữ y hệt).

    **KHÔNG sửa `002_demo_data.sql`** (D-05 — không tách dev creds vào file 002).

    **Validation sau edit:**
    - `v_key` vẫn được set và validate (>= 16 chars) — pattern hiện tại giữ nguyên
    - `pgp_sym_encrypt('', v_key)` vẫn hợp lệ (empty string encrypt OK, not NULL)
    - File vẫn idempotent (`ON CONFLICT (provider_code) DO NOTHING`)
    - Nếu re-apply trên DB đã có SMARTCA_VNPT với is_active=TRUE từ seed cũ: DO NOTHING → row cũ KHÔNG bị overwrite. **Đây là edge case cần warn trong comment + deploy/README** (production sẽ deploy fresh DB nên không gặp; dev environment đã chạy seed cũ cần manual UPDATE để reset — ghi chú comment trong seed file).

    **Thêm comment ngay trước block SmartCA** (sau paragraph check v_key, trước INSERT):
    ```sql
      -- ⚠️ LƯU Ý: Nếu DB đã có row SMARTCA_VNPT từ seed cũ (is_active=TRUE),
      -- ON CONFLICT DO NOTHING sẽ KHÔNG overwrite. Chạy UPDATE thủ công:
      --   UPDATE public.signing_provider_config
      --      SET is_active=FALSE, client_id='', client_secret=pgp_sym_encrypt('', v_key)
      --    WHERE provider_code='SMARTCA_VNPT';
      -- Hoặc chạy reset-db-windows.ps1 để reset fresh DB.
    ```
  </action>
  <acceptance_criteria>
    - `grep -c "TRUE" e_office_app_new/database/seed/001_required_data.sql` giảm so với trước (SmartCA row không còn TRUE). Kiểm cụ thể: `grep -A 15 "SMARTCA_VNPT" e_office_app_new/database/seed/001_required_data.sql | grep -c "TRUE"` = `0` (trong 15 dòng ngay sau VALUES SmartCA không còn TRUE)
    - `grep -A 15 "SMARTCA_VNPT" e_office_app_new/database/seed/001_required_data.sql | grep -c "FALSE"` >= `1` (is_active=FALSE xuất hiện)
    - `grep -A 15 "MYSIGN_VIETTEL" e_office_app_new/database/seed/001_required_data.sql | grep -c "FALSE"` >= `1` (MySign giữ FALSE)
    - `grep -c "ZjA4MjE4NDg-MjU3Mi00ZDAw" e_office_app_new/database/seed/001_required_data.sql` = `0` (dev secret hardcoded bị xóa hoàn toàn)
    - `grep -c "4d00-638392811079166938.apps.smartcaapi.com" e_office_app_new/database/seed/001_required_data.sql` = `0` (dev client_id hardcoded bị xóa)
    - `grep -c "production-safe" e_office_app_new/database/seed/001_required_data.sql` >= `2` (comment marker cả 2 block)
    - `grep -c "pgp_sym_encrypt('', v_key)" e_office_app_new/database/seed/001_required_data.sql` >= `1` (empty string encrypt cho SmartCA)
    - `grep -c "ON CONFLICT (provider_code) DO NOTHING" e_office_app_new/database/seed/001_required_data.sql` = `2` (idempotent cho cả 2 provider)
    - File syntax valid: thử compile SQL bằng psql dry-run (nếu môi trường dev có docker postgres lên):
      ```bash
      docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 \
        -c "SET app.signing_secret_key='qlvb-signing-dev-key-change-production-2026';" \
        -f - < e_office_app_new/database/seed/001_required_data.sql
      ```
      Expected: "seed/001_required_data.sql: Master data OK" notice, exit 0. (Nếu docker không lên, skip test này — acceptance grep-only đủ.)
  </acceptance_criteria>
  <verify>
    <automated>bash -c 'F=e_office_app_new/database/seed/001_required_data.sql; [ "$(grep -A 15 "SMARTCA_VNPT" $F | grep -c "FALSE")" -ge 1 ] && [ "$(grep -A 15 "SMARTCA_VNPT" $F | grep -c "TRUE")" = "0" ] && [ "$(grep -A 15 "MYSIGN_VIETTEL" $F | grep -c "FALSE")" -ge 1 ] && [ "$(grep -c "ZjA4MjE4NDg-MjU3Mi00ZDAw" $F)" = "0" ] && [ "$(grep -c "4d00-638392811079166938" $F)" = "0" ] && [ "$(grep -c "production-safe" $F)" -ge 2 ] && [ "$(grep -c "pgp_sym_encrypt(..., v_key)" $F)" -ge 0 ] && [ "$(grep -c "ON CONFLICT (provider_code) DO NOTHING" $F)" = "2" ] && echo OK'</automated>
  </verify>
  <done>
    `seed/001_required_data.sql`: SmartCA VNPT row có `is_active=FALSE` + `client_id=''` + `client_secret=pgp_sym_encrypt('', v_key)`. MySign Viettel giữ FALSE. Dev credentials hardcoded ('ZjA4MjE4NDg...' + '4d00-638392811079166938') bị xóa hoàn toàn khỏi file. Comment "production-safe" xuất hiện 2 lần.
  </done>
</task>

<task type="auto">
  <name>Task 2: Append section "Development setup sau reset-db" vào deploy/README.md</name>
  <files>deploy/README.md</files>
  <read_first>
    - `deploy/README.md` sau khi Plan 14-01 Task 2 rewrite (Windows-only, 10 section). Lưu ý: Plan 14-02 **cùng wave** với 14-01, nhưng `files_modified` cả 2 plan đều có `deploy/README.md` → có conflict?

      **Giải quyết conflict:** Plan 14-01 rewrite README hoàn chỉnh (không có section Development setup). Plan 14-02 append 1 section trước "## Tham khảo". Vì cùng file → orchestrator PHẢI serialize 14-01 chạy trước 14-02. Do đó Plan 14-02 depends_on sẽ điều chỉnh.
      **→ FIX: Plan 14-02 depends_on: [14-01]** (xem frontmatter dưới — thực tế updated)

    - `.planning/phases/14-deployment-hdsd-verification/14-CONTEXT.md` D-04 wording example (5 bullet points admin flow)
  </read_first>
  <action>
    **LƯU Ý SERIALIZATION**: Plan 14-01 và Plan 14-02 cả 2 đụng `deploy/README.md`. Dù khác section nhưng 2 edit song song sẽ conflict. Orchestrator phải chạy Task 14-01-Task-2 xong trước khi Task 14-02-Task-2 chạy.

    → Kiểm tra trước khi sửa: README.md phải đã ở trạng thái post Plan 14-01 Task 2 (Windows-only, có section `## Tham khảo` cuối cùng). Nếu chưa, abort và báo orchestrator.

    Append section mới **NGAY TRƯỚC** heading `## Tham khảo` trong `deploy/README.md`. Nội dung section:

    ```markdown
    ## Development setup sau reset-db

    Sau khi chạy `.\reset-db-windows.ps1`, cả 2 provider ký số ở trạng thái **disabled** (is_active=FALSE + empty credentials) để đảm bảo production-safe. Admin bắt buộc phải cấu hình thủ công trước khi người dùng có thể ký số.

    **Quy trình config provider (dev/test/production):**

    1. Đăng nhập admin: username `admin`, password `Admin@123` (đổi password ngay sau login lần đầu)
    2. Vào menu **Ký số → Cấu hình ký số hệ thống** (`/ky-so/cau-hinh`)
    3. Chọn provider cần enable:
       - **SmartCA VNPT**: nhập `base_url`, `client_id`, `client_secret`
       - **MySign Viettel**: nhập `base_url`, `client_id`, `client_secret`, `profile_id`
    4. Credentials dev/test: đọc từ file nội bộ `.env.dev-creds` (KHÔNG commit vào git). Credentials production: yêu cầu khách hàng cấp từ VNPT/Viettel.
    5. Bấm **Test connection** → chỉ lưu được nếu provider trả response OK
    6. Bật toggle **Kích hoạt** → Lưu

    **Lưu ý:**
    - Chỉ 1 provider active tại 1 thời điểm (partial unique index enforce). Khi bật provider A → provider B tự động bị disabled.
    - Nếu đổi `SIGNING_SECRET_KEY` sau config, credentials cũ không decrypt được — phải login và nhập lại.
    - KHÔNG hardcode credentials vào seed file hay commit `.env.dev-creds` vào git.
    ```

    Sau đó giữ nguyên section `## Tham khảo` (cuối file).

    **KHÔNG đụng các section khác** của README (Yêu cầu server, Scripts, Cấu trúc DB, Env var, Deploy, Update, Reset, Quản lý, Kiến trúc, File cấu hình, Tài khoản mặc định).
  </action>
  <acceptance_criteria>
    - `grep -c "## Development setup" deploy/README.md` = `1` (section heading xuất hiện 1 lần)
    - `grep -c "Development setup sau reset-db" deploy/README.md` = `1`
    - `grep -c "/ky-so/cau-hinh" deploy/README.md` >= `1` (link URL đúng)
    - `grep -c "Test connection" deploy/README.md` >= `1` (flow bước 5)
    - `grep -c "\.env\.dev-creds" deploy/README.md` >= `1` (reference file nội bộ)
    - `grep -c "Admin@123" deploy/README.md` >= `1` (giữ default pwd mention)
    - `grep -c "## Tham khảo" deploy/README.md` = `1` (section cuối không bị trùng)
    - Thứ tự section: `grep -nE "^## " deploy/README.md | tail -2` phải cho ra `## Development setup sau reset-db` rồi `## Tham khảo` — Development setup phải ngay trước Tham khảo.
    - `wc -l deploy/README.md | awk '{print $1}'` nằm trong [120, 220] (đã thêm ~20-30 dòng so với sau Plan 14-01)
    - Không phá section khác: `grep -c "Admin@123" deploy/README.md` >= `1` (tài khoản mặc định section vẫn còn)
    - Grep security-hardening: KHÔNG có real creds trong README — `grep -c "ZjA4MjE4NDg-MjU3Mi00ZDAw" deploy/README.md` = `0` AND `grep -c "4d00-638392811079166938" deploy/README.md` = `0`
  </acceptance_criteria>
  <verify>
    <automated>bash -c 'F=deploy/README.md; [ "$(grep -c "## Development setup" $F)" = "1" ] && [ "$(grep -c "/ky-so/cau-hinh" $F)" -ge 1 ] && [ "$(grep -c "Test connection" $F)" -ge 1 ] && [ "$(grep -c ".env.dev-creds" $F)" -ge 1 ] && [ "$(grep -c "## Tham khảo" $F)" = "1" ] && LAST2=$(grep -nE "^## " $F | tail -2 | awk -F: "{print \$2}" | tr "\n" "|") && echo "$LAST2" | grep -q "Development setup sau reset-db" && echo "$LAST2" | grep -q "Tham khảo" && L=$(wc -l < $F) && [ $L -ge 120 ] && [ $L -le 220 ] && [ "$(grep -c "ZjA4MjE4NDg-MjU3Mi00ZDAw" $F)" = "0" ] && [ "$(grep -c "4d00-638392811079166938" $F)" = "0" ] && echo OK'</automated>
  </verify>
  <done>
    `deploy/README.md` có thêm section `## Development setup sau reset-db` với 6-bước flow admin config provider. Section nằm ngay trước `## Tham khảo`. KHÔNG hardcode real/dev credentials. File length 120-220 dòng.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Seed file → production DB | IT triển khai chạy `seed/001_required_data.sql` trên DB production — nếu chứa dev creds, creds leak sang production |
| README.md → git public repo | `deploy/README.md` nằm trong git, public (hoặc internal) — nếu chứa real credentials, lộ ra ngoài |
| Admin UI `/ky-so/cau-hinh` → provider API | Admin nhập credentials trên UI, được encrypt pgp_sym_encrypt trước khi save DB |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-14-02-01 | Information Disclosure | seed/001_required_data.sql dev creds hardcoded | **mitigate** | Task 1 xóa hoàn toàn `'ZjA4MjE4NDg-MjU3Mi00ZDAw'` + `'4d00-638392811079166938.apps.smartcaapi.com'`. Acceptance criteria check grep count = 0 cho 2 pattern này. |
| T-14-02-02 | Elevation of Privilege | SmartCA active sau deploy production với dev creds → user vô tình ký qua kênh dev team | **mitigate** | `is_active=FALSE` sau seed → flow `/ky-so/sign` fail-fast với message "Chưa có provider active" — user không ký được. Admin phải config explicit. |
| T-14-02-03 | Tampering | Re-apply seed lên DB cũ có is_active=TRUE → `ON CONFLICT DO NOTHING` không reset | accept | Production deploy always fresh DB (Phase 11.1 strategy). Dev có comment trong seed file chỉ cách UPDATE manual. Không phải threat production. |
| T-14-02-04 | Information Disclosure | README.md chứa credentials | **mitigate** | Task 2 acceptance criteria grep count real creds = 0. README chỉ hướng dẫn "đọc từ file nội bộ .env.dev-creds" — không hardcode creds. |
| T-14-02-05 | Denial of Service | Admin login production nhưng quên config provider → user không ký được | accept | Acceptable trade-off: ưu tiên security (disable by default) hơn UX convenience (ready-to-sign). Admin login lần đầu sẽ thấy menu config và self-discover nhanh; deploy/README hướng dẫn rõ. |
| T-14-02-06 | Repudiation | Ai đó commit `.env.dev-creds` vào git | **mitigate** | Task 2 README explicit instruction "KHÔNG commit .env.dev-creds vào git". Defense-in-depth: project-level `.gitignore` phải có `.env*` (ngoài scope phase này — nếu chưa có thì Plan 14-03 có thể flag). |
| T-14-02-07 | Spoofing | Attacker impersonate provider bằng fake `base_url` | accept | base_url config bởi admin privilege trên UI, có protection RBAC. Không phải seed threat. |
</threat_model>

<verification>
## Phase-level verification sau 2 task

1. **Seed security check:**
   ```bash
   F=e_office_app_new/database/seed/001_required_data.sql
   grep -c "ZjA4MjE4NDg-MjU3Mi00ZDAw" $F   # = 0
   grep -c "4d00-638392811079166938" $F    # = 0
   grep -A 15 "SMARTCA_VNPT" $F | grep -c "FALSE"  # >= 1
   grep -A 15 "MYSIGN_VIETTEL" $F | grep -c "FALSE"  # >= 1
   ```

2. **README consistency:**
   ```bash
   grep -c "## Development setup" deploy/README.md  # = 1
   grep -c "ZjA4MjE4NDg-MjU3Mi00ZDAw" deploy/README.md  # = 0 (không leak creds)
   ```

3. **Runtime DB smoke test (optional, nếu docker up):**
   ```bash
   docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 \
     -c "SET app.signing_secret_key='qlvb-signing-dev-key-change-production-2026';" \
     -f - < e_office_app_new/database/seed/001_required_data.sql
   # Expected: NOTICE 'seed/001_required_data.sql: Master data OK'
   docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c \
     "SELECT provider_code, is_active, length(client_id) AS cid_len FROM public.signing_provider_config;"
   # Expected: 2 rows, cả 2 is_active=f, cid_len=0
   ```

4. **Integration check với Plan 14-01:** 
   - 14-01 Task 2 rewrite README → section cuối phải là `## Tham khảo`
   - 14-02 Task 2 insert `## Development setup sau reset-db` ngay trước `## Tham khảo`
   - Sau cả 2 plan xong: `grep -nE "^## " deploy/README.md | tail -2` phải hiện đúng thứ tự
</verification>

<success_criteria>
Plan 14-02 hoàn thành khi:
- [ ] `seed/001_required_data.sql`: SmartCA VNPT đổi `is_active=FALSE` + `client_id=''` + `client_secret=pgp_sym_encrypt('', v_key)`
- [ ] Dev credentials hardcoded 'ZjA4MjE4NDg-MjU3Mi00ZDAw' + '4d00-638392811079166938.apps.smartcaapi.com' xóa sạch khỏi seed file
- [ ] MySign Viettel giữ nguyên FALSE (đã đúng từ đầu)
- [ ] Seed file vẫn idempotent (`ON CONFLICT DO NOTHING` giữ nguyên) và sync với schema (pgp_sym_encrypt non-null BYTEA)
- [ ] Comment `production-safe` xuất hiện >= 2 lần trong seed file
- [ ] `deploy/README.md`: có section `## Development setup sau reset-db` với 6-step admin flow
- [ ] Section Development setup nằm ngay trước `## Tham khảo`
- [ ] README không leak real/dev credentials (grep count pattern = 0)
- [ ] DEP-01 acceptance full: deploy script seed providers disabled → admin phải config sau deploy (verify evidence: `docker exec psql -c "SELECT is_active FROM signing_provider_config"` → 2 rows, cả 2 FALSE)
</success_criteria>

<output>
After completion, create `.planning/phases/14-deployment-hdsd-verification/14-02-SUMMARY.md` với:
- **What was done:** Fix seed 001 → SmartCA disabled + empty creds; README.md thêm section Development setup
- **Files modified:** e_office_app_new/database/seed/001_required_data.sql, deploy/README.md
- **Affects:** DEP-01 requirement, production deploy safety, dev workflow
- **Provides:** Production-safe seed state → Plan 14-03 có evidence concrete cho DEP-01 Verify Evidence column
- **Patterns:** Seed idempotent ON CONFLICT DO NOTHING + pgp_sym_encrypt('', key) pattern cho disabled provider
- **Decisions implemented:** D-03 (seed fix), D-04 (dev workflow section), D-05 (KHÔNG tách 002 — chỉ seed 001 được chỉnh)
- **Blockers/Concerns:** Plan 14-02 depends_on Plan 14-01 cho deploy/README.md rewrite baseline — serialize execution.
</output>
