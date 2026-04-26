# ============================================================
# e-Office - Cap nhat code va schema tren Windows Server PROD
# Muc dich: Pull code moi nhat + rebuild PRODUCTION + re-apply schema
#           (idempotent, GIU NGUYEN data prod) + restart pm2 + verify.
#
# Chay: PowerShell Administrator:
#   .\deploy\update-windows.ps1
#
# KHAC voi deploy-v2-kh-test.ps1:
#   - KHONG reset DB (chi re-apply schema master, idempotent)
#   - KHONG clear Redis / MinIO
#   - KHONG seed lai
#   - Phu hop khi DB prod da co data nghiep vu
# ============================================================

$ErrorActionPreference = 'Continue'
$ScriptStart = Get-Date

# -- Config ---------------------------------------------------
$APP_DIR    = 'C:\qlvb\quanlyvanban'
$WORK_DIR   = Join-Path $APP_DIR 'e_office_app_new'
$psqlExe    = 'C:\PostgreSQL\16\bin\psql.exe'
$PG_DB      = 'qlvb_prod'
$PG_USER    = 'qlvb_admin'
$PG_PASS    = 'QlvbProd2026'

$BACKEND_HEALTH = 'http://localhost:4000/api/health'
$FRONTEND_URL   = 'http://localhost:3000'

# -- Helpers --------------------------------------------------
function Log  ($m) { Write-Host "[OK] $m" -ForegroundColor Green }
function Step ($m) { $sec = [int]((Get-Date) - $ScriptStart).TotalSeconds; Write-Host "`n[${sec}s] $m" -ForegroundColor Cyan }
function Warn ($m) { Write-Host "[!!] $m" -ForegroundColor Yellow }
function Err  ($m) { Write-Host "[XX] $m" -ForegroundColor Red; exit 1 }

# -- Precheck -------------------------------------------------
Step 'Precheck'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Err 'Can chay PowerShell voi quyen Administrator'
}
Log 'Administrator'

if (-not (Test-Path $APP_DIR))  { Err "Khong tim thay APP_DIR: $APP_DIR" }
if (-not (Test-Path $WORK_DIR)) { Err "Khong tim thay WORK_DIR: $WORK_DIR" }
if (-not (Test-Path $psqlExe))  { Err "Khong tim thay psql.exe: $psqlExe" }
Log 'Paths OK'

$env:PGPASSWORD = $PG_PASS

# -- 1. Stop pm2 services ------------------------------------
Step '1. Stop pm2 services (tranh ket noi DB khi re-apply schema)'
pm2 stop all 2>$null | Out-Null
Log 'pm2 stopped'

# -- 2. Pull code moi ----------------------------------------
Step '2. Pull code moi tu git'
Set-Location $APP_DIR
git fetch --all -q
if ($LASTEXITCODE -ne 0) { Err 'git fetch that bai' }
git reset --hard origin/main -q
if ($LASTEXITCODE -ne 0) { Err 'git reset that bai' }
$headSha = (git rev-parse --short HEAD).Trim()
$headMsg = (git log -1 --pretty=format:"%s").Trim()
Log "HEAD: $headSha $headMsg"

# -- 3. Build Backend PRODUCTION -----------------------------
Step '3. Build Backend PRODUCTION (npm ci + build)'
Set-Location "$WORK_DIR\backend"
# QUAN TRONG: NODE_ENV=development khi install de co devDeps (typescript)
# NODE_ENV=production chi set khi pm2 chay app, KHONG set khi npm ci/install.
$env:NODE_ENV = 'development'

Log '  -> npm ci (clean install, full deps)...'
npm ci 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Warn '  npm ci fail, fallback npm install (full)'
    npm install 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Err 'Backend npm install that bai' }
}

# Verify tsc present truoc khi build
if (-not (Test-Path "$WORK_DIR\backend\node_modules\.bin\tsc.cmd") -and -not (Test-Path "$WORK_DIR\backend\node_modules\typescript\bin\tsc")) {
    Err 'typescript khong co trong node_modules - npm install chua cai devDependencies. Kiem tra .npmrc / NODE_ENV.'
}

Log '  -> npm run build (tsc -> dist/)...'
$buildLog = Join-Path $env:TEMP 'qlvb_update_be_build.log'
npm run build > $buildLog 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '---- Backend build output (cuoi file) ----' -ForegroundColor Yellow
    Get-Content $buildLog -Tail 50
    Write-Host "---- Full log: $buildLog ----" -ForegroundColor Yellow
    Err 'Backend build that bai - xem log phia tren'
}
Remove-Item $buildLog -ErrorAction SilentlyContinue
if (-not (Test-Path "$WORK_DIR\backend\dist\server.js")) { Err 'Backend dist/server.js khong ton tai sau build' }
Log 'Backend built'

# -- 4. Build Frontend PRODUCTION ----------------------------
Step '4. Build Frontend PRODUCTION (Next.js build 3-5 phut)'
Set-Location "$WORK_DIR\frontend"
$env:NODE_ENV = 'development'

Log '  -> npm ci (full deps)...'
npm ci 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Warn '  npm ci fail, fallback npm install (full)'
    npm install 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Err 'Frontend npm install that bai' }
}

# Verify next CLI
if (-not (Test-Path "$WORK_DIR\frontend\node_modules\.bin\next.cmd") -and -not (Test-Path "$WORK_DIR\frontend\node_modules\next\dist\bin\next")) {
    Err 'next CLI khong co trong node_modules - npm install chua cai day du.'
}

# Switch sang production cho qua trinh build (Next.js read NODE_ENV)
$env:NODE_ENV = 'production'

Log '  -> npm run build (Next.js production)...'
$feBuildLog = Join-Path $env:TEMP 'qlvb_update_fe_build.log'
npm run build > $feBuildLog 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '---- Frontend build output (cuoi file) ----' -ForegroundColor Yellow
    Get-Content $feBuildLog -Tail 60
    Write-Host "---- Full log: $feBuildLog ----" -ForegroundColor Yellow
    Err 'Frontend build that bai - xem log phia tren'
}
Remove-Item $feBuildLog -ErrorAction SilentlyContinue
if (-not (Test-Path "$WORK_DIR\frontend\.next\BUILD_ID")) { Err 'Frontend .next/BUILD_ID khong ton tai sau build' }
Log 'Frontend built'

# -- 5. Re-apply master schema (idempotent, GIU DATA) ---------
Step '5. Re-apply master schema (idempotent, GIU NGUYEN data prod)'
$schemaFile = Join-Path $WORK_DIR 'database\schema\000_schema_v3.0.sql'
if (-not (Test-Path $schemaFile)) { Err "Khong tim thay $schemaFile" }

# Schema master file safe de chay lai vi:
#   - DROP cu the cac SP truoc CREATE OR REPLACE (target list, khong dung LIKE prefix)
#   - CREATE TABLE IF NOT EXISTS + ADD CONSTRAINT wrap DO block catch duplicate
# Apply lan 1: tat ca SP / trigger / cot moi se duoc cap nhat.
$schemaLog = Join-Path $env:TEMP 'qlvb_update_schema.log'
& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $schemaFile > $schemaLog 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '---- Schema apply output (cuoi file) ----' -ForegroundColor Yellow
    Get-Content $schemaLog -Tail 40
    Write-Host "---- Full log: $schemaLog ----" -ForegroundColor Yellow
    Err 'Schema master re-apply that bai - xem log phia tren'
}
Remove-Item $schemaLog -ErrorAction SilentlyContinue
Log "  -> $schemaFile re-applied OK"

# Verify SP count khong bi hut (baseline >= 200, Phase 11.1 v2.0.2 = 386 SPs)
$spCount = (& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -tAc `
    "SELECT count(*) FROM pg_proc WHERE pronamespace IN ('public'::regnamespace, 'edoc'::regnamespace) AND proname LIKE 'fn_%';").Trim()
if ([int]$spCount -lt 200) {
    Err "SP count chi $spCount (< 200) - co SP bi mat khi re-apply schema!"
}
Log "  SP count: $spCount (>= 200, OK)"

# Verify SP overload (KHONG duoc co duplicate)
$overloadCount = (& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -tAc @"
SELECT count(*) FROM (
  SELECT n.nspname, p.proname
  FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
  WHERE n.nspname IN ('public','edoc','esto','cont','iso') AND p.proname LIKE 'fn_%'
  GROUP BY 1,2 HAVING count(*) > 1
) t;
"@).Trim()
if ([int]$overloadCount -gt 0) {
    Err "Co $overloadCount SP overload (duplicate signature) - chay 'DROP FUNCTION ... CASCADE' thu cong"
}
Log "  SP overload: 0 (OK)"

# Verify trigger sync signers moi (commit f65a1e4)
$trgCheck = (& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -tAc `
    "SELECT count(*) FROM pg_trigger WHERE tgname = 'trg_staff_sync_signers_dept';").Trim()
if ([int]$trgCheck -eq 0) {
    Warn '  trg_staff_sync_signers_dept chua duoc tao - kiem tra schema file co commit moi nhat'
} else {
    Log '  trg_staff_sync_signers_dept (auto sync edoc.signers khi staff doi phong ban) OK'
}

# -- 6. Restart pm2 voi --update-env --------------------------
Step '6. Restart pm2 (--update-env de pick up .env changes)'
Set-Location $WORK_DIR
pm2 restart all --update-env
if ($LASTEXITCODE -ne 0) { Warn 'pm2 restart fail - kiem tra pm2 logs' }
Start-Sleep -Seconds 3
pm2 status

# -- 7. Verify -----------------------------------------------
Step '7. Verify deployment'

Log "  -> Check backend health: $BACKEND_HEALTH"
try {
    $h = Invoke-WebRequest -Uri $BACKEND_HEALTH -TimeoutSec 10 -UseBasicParsing
    if ($h.StatusCode -eq 200) { Log '    Backend healthy' }
    else { Warn "    Backend status $($h.StatusCode)" }
} catch { Warn "    Backend unreachable: $($_.Exception.Message)" }

Log "  -> Check frontend: $FRONTEND_URL"
try {
    $f = Invoke-WebRequest -Uri $FRONTEND_URL -TimeoutSec 15 -UseBasicParsing
    if ($f.StatusCode -eq 200) { Log '    Frontend reachable' }
    else { Warn "    Frontend status $($f.StatusCode)" }
} catch { Warn "    Frontend unreachable: $($_.Exception.Message)" }

Log '  -> Test login admin (qua backend local)'
try {
    $body = @{ username = 'admin'; password = 'Admin@123' } | ConvertTo-Json -Compress
    $login = Invoke-WebRequest -Uri 'http://localhost:4000/api/auth/login' -Method POST -ContentType 'application/json' -Body $body -TimeoutSec 10 -UseBasicParsing
    $loginData = $login.Content | ConvertFrom-Json
    if ($loginData.data.accessToken) { Log '    Login admin OK (accessToken received)' }
    else { Warn "    Login response khong co accessToken" }
} catch { Warn "    Login that bai: $($_.Exception.Message)" }

# -- Summary -------------------------------------------------
$duration = [int]((Get-Date) - $ScriptStart).TotalSeconds
Write-Host ''
Write-Host '================================================================' -ForegroundColor Green
Write-Host "  CAP NHAT HOAN THANH sau $duration giay" -ForegroundColor Green
Write-Host '================================================================' -ForegroundColor Green
Write-Host ''
Write-Host "  Git HEAD: $headSha $headMsg" -ForegroundColor DarkGray
Write-Host '  Schema:   re-applied (idempotent), data prod giu nguyen' -ForegroundColor DarkGray
Write-Host '  pm2:      restarted voi --update-env' -ForegroundColor DarkGray
Write-Host ''
