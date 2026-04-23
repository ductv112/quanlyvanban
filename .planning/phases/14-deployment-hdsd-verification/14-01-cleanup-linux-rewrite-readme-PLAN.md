---
phase: 14-deployment-hdsd-verification
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - deploy/deploy.sh
  - deploy/update.sh
  - deploy/reset-db.sh
  - deploy/backup.sh
  - deploy/README.md
autonomous: true
requirements:
  - DEP-01
tags:
  - deployment
  - cleanup
  - windows

must_haves:
  truths:
    - "Thư mục deploy/ không còn file .sh nào — chỉ còn PowerShell scripts và README.md"
    - "deploy/README.md không còn mention file .sh hay hướng dẫn Linux bash trong các code block"
    - "deploy/README.md vẫn đầy đủ section Deploy/Update/Reset/Kiến trúc/File cấu hình/Quản lý — nhưng chỉ Windows Server + IIS"
  artifacts:
    - path: "deploy/README.md"
      provides: "Windows-only deploy documentation"
      min_lines: 100
      contains: "deploy-windows.ps1"
    - path: "deploy/deploy-windows.ps1"
      provides: "Reference duy nhất cho deploy lần đầu (giữ nguyên, không sửa)"
    - path: "deploy/update-windows.ps1"
      provides: "Reference duy nhất cho update code (giữ nguyên)"
    - path: "deploy/reset-db-windows.ps1"
      provides: "Reference duy nhất cho reset DB (giữ nguyên)"
  key_links:
    - from: "deploy/README.md"
      to: "deploy/deploy-windows.ps1"
      via: "code block PowerShell hướng dẫn chạy deploy lần đầu"
      pattern: "deploy-windows\\.ps1"
    - from: "deploy/README.md"
      to: "deploy/reset-db-windows.ps1"
      via: "code block PowerShell + switch -NoDemo"
      pattern: "reset-db-windows\\.ps1"
---

<objective>
Loại bỏ hoàn toàn scope Linux khỏi thư mục `deploy/` (D-01, D-02). Xóa 4 shell scripts `.sh` không còn được support và rewrite `deploy/README.md` chỉ còn instructions cho Windows Server + IIS.

Purpose: Project đã lock Windows-only target (D-01). Giữ scripts Linux + mention bash trong README gây confusion cho IT triển khai và bloat maintenance khi các PowerShell scripts tiến hóa. Cleanup 1 lần giúp bước 14-02 (seed fix) và 14-03 (REQUIREMENTS audit) không phải đụng file Linux.

Output:
- 4 file `.sh` trong `deploy/` bị xóa
- `deploy/README.md` rewrite: remove hết bash code block, remove cột Linux trong bảng, giữ nguyên các PowerShell blocks + structure 9 section
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

# Current state của deploy/README.md (195 dòng, bilingual Linux + Windows)
@deploy/README.md

# Reference PowerShell scripts (KHÔNG edit — giữ nguyên)
@deploy/deploy-windows.ps1
@deploy/update-windows.ps1
@deploy/reset-db-windows.ps1
@deploy/setup-iis.ps1

# CLAUDE.md — DB Migration Strategy section (README phải đồng bộ reference)
@CLAUDE.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Xóa 4 file shell scripts Linux</name>
  <files>
    deploy/deploy.sh (DELETE),
    deploy/update.sh (DELETE),
    deploy/reset-db.sh (DELETE),
    deploy/backup.sh (DELETE)
  </files>
  <read_first>
    - `deploy/deploy.sh` (14.7KB — xác nhận đúng file Linux deploy trước khi xóa)
    - `deploy/update.sh` (2.0KB — xác nhận đúng file Linux update)
    - `deploy/reset-db.sh` (6.0KB — xác nhận đúng file Linux reset-db)
    - `deploy/backup.sh` (1.0KB — xác nhận Linux backup)
    - `deploy/` listing tổng thể (xác nhận không còn .sh nào khác)
    - `.planning/phases/14-deployment-hdsd-verification/14-CONTEXT.md` D-02 (list 4 file cần xóa)
  </read_first>
  <action>
    Dùng git rm cho cleanup (commit sẽ được xử lý ở task finalize sau khi xong 3 plan; ở đây chỉ remove file khỏi working tree):

    ```bash
    # Từ repo root
    rm deploy/deploy.sh
    rm deploy/update.sh
    rm deploy/reset-db.sh
    rm deploy/backup.sh
    ```

    KHÔNG xóa các file sau (giữ nguyên, Windows target):
    - `deploy/deploy-windows.ps1`
    - `deploy/update-windows.ps1`
    - `deploy/reset-db-windows.ps1`
    - `deploy/setup-iis.ps1`
    - `deploy/README.md` (rewrite ở Task 2)

    Nếu shell không cho `rm` (Windows bash), dùng PowerShell equivalent:
    ```powershell
    Remove-Item deploy\deploy.sh, deploy\update.sh, deploy\reset-db.sh, deploy\backup.sh -Force
    ```
  </action>
  <acceptance_criteria>
    - `test ! -f deploy/deploy.sh` (file không tồn tại)
    - `test ! -f deploy/update.sh`
    - `test ! -f deploy/reset-db.sh`
    - `test ! -f deploy/backup.sh`
    - `ls deploy/*.sh 2>/dev/null | wc -l` = `0` (không còn file .sh nào trong deploy/)
    - `ls deploy/*.ps1 | wc -l` >= `4` (vẫn còn 4 PowerShell scripts: deploy-windows, update-windows, reset-db-windows, setup-iis)
    - `test -f deploy/README.md` (README vẫn tồn tại, chưa bị đụng ở task này)
  </acceptance_criteria>
  <verify>
    <automated>bash -c 'test ! -f deploy/deploy.sh && test ! -f deploy/update.sh && test ! -f deploy/reset-db.sh && test ! -f deploy/backup.sh && [ "$(ls deploy/*.sh 2>/dev/null | wc -l)" = "0" ] && [ "$(ls deploy/*.ps1 | wc -l)" -ge 4 ] && echo OK'</automated>
  </verify>
  <done>
    Thư mục `deploy/` chỉ còn `.ps1` scripts + `README.md`. Không còn file `.sh` nào.
  </done>
</task>

<task type="auto">
  <name>Task 2: Rewrite deploy/README.md Windows-only</name>
  <files>deploy/README.md</files>
  <read_first>
    - `deploy/README.md` hiện tại (195 dòng — bilingual Linux + Windows, 9 section)
    - `deploy/deploy-windows.ps1` (để biết script làm gì, wording chính xác cho section Deploy)
    - `deploy/reset-db-windows.ps1` (để biết `-NoDemo` switch)
    - `deploy/update-windows.ps1` (để biết flow update)
    - `.planning/phases/14-deployment-hdsd-verification/14-CONTEXT.md` D-01 (Windows Server + IIS only)
    - `CLAUDE.md` section "DB Migration Strategy (v2.0+)" (reference cho section "Cấu trúc DB")
  </read_first>
  <action>
    Viết lại hoàn toàn `deploy/README.md` theo cấu trúc 9 section dưới đây, CHỈ giữ Windows content. KHÔNG mention Linux, KHÔNG có code block bash (`).

    **Structure cuối cùng (giữ nguyên thứ tự section):**

    1. **# Deploy e-Office Production** (heading)
    2. **## Yêu cầu server** — bullet list: Windows Server 2022 + IIS, RAM >=4GB, Disk 40GB+, Port 80 mở HTTP. Thêm dòng: `> Lưu ý: Dự án hiện CHỈ hỗ trợ Windows Server. Linux không được support.`
    3. **## Scripts có sẵn** — bảng 3 cột (thay bảng OS Linux/Windows cũ):
       ```
       | Task | Script |
       |------|--------|
       | Deploy lần đầu | `deploy-windows.ps1` |
       | Update code    | `update-windows.ps1` |
       | Reset DB (test)| `reset-db-windows.ps1` |
       | Cấu hình IIS   | `setup-iis.ps1` |
       ```
    4. **## Cấu trúc DB (v2.0 consolidated)** — giữ nguyên y hệt section hiện tại (lines 18-38 của README cũ): tree diagram `e_office_app_new/database/`, luật DB migration. Không đụng nội dung này.
    5. **## Environment variable BẮT BUỘC** — giữ nguyên (lines 40-51 cũ), NHƯNG đổi `$env:SIGNING_SECRET_KEY` format Windows instead of bash export:
       - Backend `.env` block (dùng markdown ``` không tag hoặc tag `env`): giữ `SIGNING_SECRET_KEY=<32+ ký tự random hex>` (đây là file content, không phải bash export)
       - Giữ paragraph về JWT_SECRET dùng lại cho SIGNING_SECRET_KEY
       - Giữ paragraph Lưu ý quan trọng về đổi key
    6. **## Deploy lần đầu** — CHỈ block PowerShell, không Linux:
       ```powershell
       # PowerShell Administrator
       Set-ExecutionPolicy Bypass -Scope Process -Force
       cd C:\qlvb\quanlyvanban\deploy
       .\deploy-windows.ps1
       ```
       Giữ nguyên 7-step list "Script tự động" (Docker/Node.js/IIS/PM2/Apply DB/Build/IIS/Firewall) nhưng thay "Nginx reverse proxy" → "IIS reverse proxy" (vì chuyển sang Windows IIS hẳn). Xem `setup-iis.ps1` để confirm.
    7. **## Cập nhật code** — CHỈ PowerShell:
       ```powershell
       cd C:\qlvb\quanlyvanban\deploy
       .\update-windows.ps1
       ```
       Giữ list "Script tự động" (pull code, rebuild, re-apply schema idempotent, restart PM2, không re-run seed).
    8. **## Reset toàn bộ DB (CHỈ CHO TEST SERVER)** — CHỈ PowerShell:
       ```powershell
       cd C:\qlvb\quanlyvanban\deploy

       # Mặc định: seed cả required + demo (312 records test UI)
       .\reset-db-windows.ps1

       # Production simulation: chỉ seed required data
       .\reset-db-windows.ps1 -NoDemo
       ```
       Giữ list 8-step "Script tự động".
    9. **## Quản lý thường ngày** — thay block bash bằng block PowerShell tương đương:
       ```powershell
       pm2 status              # Xem trạng thái
       pm2 logs                # Xem logs realtime
       pm2 logs eoffice-api    # Logs backend
       pm2 logs eoffice-web    # Logs frontend
       pm2 restart all         # Restart tất cả
       pm2 restart eoffice-api # Restart backend

       docker compose -f C:\qlvb\quanlyvanban\e_office_app_new\docker-compose.prod.yml ps
       docker compose -f C:\qlvb\quanlyvanban\e_office_app_new\docker-compose.prod.yml logs postgres
       ```
    10. **## Kiến trúc** — giữ nguyên text diagram Client → IIS/Nginx → Next.js + Express (sửa Nginx thành IIS):
        ```
        Client → IIS (:80)
                  ├─ /        → Next.js (:3000)  ← PM2
                  └─ /api/    → Express (:4000)  ← PM2
                                 ├─ PostgreSQL (:5432)  ← Docker
                                 ├─ MongoDB (:27017)    ← Docker
                                 ├─ Redis (:6379)       ← Docker
                                 └─ MinIO (:9000)       ← Docker
        ```
    11. **## File cấu hình** — bảng Windows path thay Linux path:
        ```
        | File | Đường dẫn |
        |------|-----------|
        | Backend env  | `C:\qlvb\quanlyvanban\e_office_app_new\backend\.env` |
        | Frontend env | `C:\qlvb\quanlyvanban\e_office_app_new\frontend\.env.local` |
        | PM2          | `C:\qlvb\quanlyvanban\e_office_app_new\ecosystem.config.cjs` |
        | IIS config   | `deploy/setup-iis.ps1` + `%SystemRoot%\System32\inetsrv\config\applicationHost.config` |
        | Docker       | `C:\qlvb\quanlyvanban\e_office_app_new\docker-compose.prod.yml` |
        ```
    12. **## Tài khoản mặc định** — giữ nguyên (admin / Admin@123, đổi mật khẩu sau login lần đầu)
    13. **## Tham khảo** — giữ 4 bullet tham khảo:
        - `.planning/phases/11.1-db-consolidation-seed-strategy/` — chi tiết consolidate
        - `e_office_app_new/database/archive/v1.0-migrations/README.md`
        - `e_office_app_new/database/archive/v2.0-incrementals/README.md`
        - `CLAUDE.md` — section "DB Migration Strategy (v2.0+)"

    **KHÔNG** có section "Backup database" trong README mới (backup.sh đã xóa, chưa có Windows backup script — listed trong Deferred của CONTEXT).

    **KHÔNG** có section "Development setup" trong Plan này — section đó do Plan 14-02 Task 2 thêm vào.
  </action>
  <acceptance_criteria>
    - `grep -c "\.sh" deploy/README.md` = `0` (không còn mention .sh script nào)
    - `grep -c "\.ps1" deploy/README.md` >= `4` (có ít nhất 4 mention tới ps1 scripts: deploy-windows, update-windows, reset-db-windows, setup-iis)
    - `grep -c "sudo bash" deploy/README.md` = `0` (không còn lệnh sudo bash)
    - `grep -c "Linux" deploy/README.md` <= `1` (cho phép tối đa 1 mention "Linux không được support" trong section Yêu cầu server)
    - `grep -c "Windows" deploy/README.md` >= `3` (có ít nhất 3 mention Windows)
    - `grep -c "reset-db-windows" deploy/README.md` >= `2` (ít nhất 2 reference tới reset-db script trong Reset section + bảng Scripts)
    - `grep -c "Admin@123" deploy/README.md` = `1` (tài khoản mặc định vẫn giữ)
    - `grep -c "SIGNING_SECRET_KEY" deploy/README.md` >= `2` (env var section vẫn giữ)
    - `grep -cE "^## " deploy/README.md` >= `10` (vẫn có 10+ level-2 headings — structure không mất)
    - `wc -l deploy/README.md | awk '{print $1}'` trong range [100, 180] (không bị cắt ngắn < 100 cũng không phình > 180)
    - `grep -c "backup\.sh" deploy/README.md` = `0` (section Backup bị remove)
    - `grep -c "Development setup" deploy/README.md` = `0` (section này do Plan 14-02 thêm, Plan 14-01 không có)
  </acceptance_criteria>
  <verify>
    <automated>bash -c 'F=deploy/README.md; [ "$(grep -c "\.sh" $F)" = "0" ] && [ "$(grep -c "\.ps1" $F)" -ge 4 ] && [ "$(grep -c "sudo bash" $F)" = "0" ] && [ "$(grep -c "reset-db-windows" $F)" -ge 2 ] && [ "$(grep -c "Admin@123" $F)" = "1" ] && [ "$(grep -c "SIGNING_SECRET_KEY" $F)" -ge 2 ] && [ "$(grep -cE "^## " $F)" -ge 10 ] && L=$(wc -l < $F) && [ $L -ge 100 ] && [ $L -le 180 ] && [ "$(grep -c "backup\.sh" $F)" = "0" ] && [ "$(grep -c "Development setup" $F)" = "0" ] && echo OK'</automated>
  </verify>
  <done>
    `deploy/README.md` rewrite thành công: Windows-only, không còn mention bash/Linux scripts, giữ structure 9-10 section, dài 100-180 dòng. Reference PowerShell scripts đủ 4 loại.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| File system → repo | IT triển khai đọc `deploy/README.md` để biết cần chạy script nào |
| IT → production server | IT copy-paste lệnh PowerShell từ README chạy trên Windows Server |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-14-01-01 | Information Disclosure | deploy/README.md code blocks | accept | README chỉ chứa command pattern + hardcoded default password `Admin@123` (đã có sẵn trong README cũ, admin bắt buộc đổi sau login lần đầu). Không chứa real credentials. |
| T-14-01-02 | Tampering | Xóa sai file (VD lỡ tay xóa `.ps1`) | mitigate | Acceptance criteria Task 1 check rõ `ls deploy/*.ps1 | wc -l >= 4` sau khi xóa — nếu xóa nhầm PowerShell thì verify fail ngay. |
| T-14-01-03 | Repudiation | Git history mất reference Linux scripts | accept | Git giữ lịch sử commit — nếu sau này cần support Linux lại, `git show HEAD~1:deploy/deploy.sh` restore được. |
| T-14-01-04 | Denial of Service | User Linux hiểu nhầm project support Linux | mitigate | README section "Yêu cầu server" có dòng explicit "> Lưu ý: Dự án hiện CHỈ hỗ trợ Windows Server. Linux không được support." |
</threat_model>

<verification>
## Phase-level verification sau 2 task

1. **Xác nhận cleanup hoàn toàn:**
   ```bash
   ls deploy/*.sh 2>/dev/null | wc -l    # = 0
   ls deploy/*.ps1 | wc -l               # >= 4
   test -f deploy/README.md              # exists
   ```

2. **README consistency check:**
   ```bash
   grep -c "\.sh" deploy/README.md       # = 0
   grep -c "\.ps1" deploy/README.md      # >= 4
   grep -c "sudo bash" deploy/README.md  # = 0
   ```

3. **Integration check (Plan 14-02 sẽ append section "Development setup" vào README):** sau Plan 14-01, README structure đủ chỗ để Plan 14-02 append 1 section mới mà không conflict. Verify bằng cách đọc lại README và confirm section "## Tài khoản mặc định" và "## Tham khảo" là 2 section cuối — Plan 14-02 sẽ insert "## Development setup" trước "## Tham khảo".

4. **Không regression scripts PowerShell:** `deploy-windows.ps1`, `update-windows.ps1`, `reset-db-windows.ps1`, `setup-iis.ps1` phải giữ **hash MD5 không đổi** so với pre-Plan 14-01 (không ai đụng file content):
   ```bash
   md5sum deploy/*.ps1   # So sánh với commit trước
   ```
</verification>

<success_criteria>
Plan 14-01 hoàn thành khi:
- [ ] 4 file `.sh` (deploy.sh, update.sh, reset-db.sh, backup.sh) bị xóa khỏi `deploy/`
- [ ] Không có file `.sh` nào còn lại trong `deploy/`
- [ ] `deploy/README.md` rewrite: không mention .sh scripts, không mention sudo bash, ít nhất 4 reference .ps1 scripts
- [ ] README structure đủ 10+ section level 2 (Yêu cầu server → Scripts → Cấu trúc DB → Env var → Deploy → Update → Reset → Quản lý → Kiến trúc → File cấu hình → Tài khoản → Tham khảo)
- [ ] README file length 100-180 dòng (không bị cắt ngắn dưới 100 cũng không phình trên 180)
- [ ] 4 PowerShell scripts không bị sửa (content hash identical so với pre-plan)
- [ ] DEP-01 một phần được address (seed fix ở Plan 14-02, nhưng scripts cũ đã được cleanup để Plan 14-02 không cần care Linux flow)
</success_criteria>

<output>
After completion, create `.planning/phases/14-deployment-hdsd-verification/14-01-SUMMARY.md` với:
- **What was done:** Xóa 4 file `.sh`, rewrite README.md Windows-only
- **Files deleted:** deploy/deploy.sh, deploy/update.sh, deploy/reset-db.sh, deploy/backup.sh
- **Files modified:** deploy/README.md (rewrite)
- **Affects:** deploy/, docs cho IT triển khai
- **Provides:** Windows-only deploy workflow foundation cho Plan 14-02 (append "Development setup") và Plan 14-03 (REQUIREMENTS audit)
- **Patterns:** Không mới; chỉ cleanup
- **Decisions implemented:** D-01 Windows-only, D-02 delete 4 Linux scripts
- **Blockers/Concerns:** None — plan độc lập file với 14-02 và 14-03 ngoại trừ README.md (Plan 14-02 sẽ append section mới, không đụng section Plan 14-01 viết)
</output>
