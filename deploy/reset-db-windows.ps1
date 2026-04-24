# ============================================================
# e-Office - Reset DB Windows Server (CHI DUNG CHO TEST)
# Flow v2.0 consolidated: schema master + 2 file seed (KHONG loop migrations/)
#
# [!!] CANH BAO: Xoa TOAN BO data - KHONG dung tren production that
# Chay: PowerShell (Administrator):
#   .\reset-db-windows.ps1              # seed ca required + demo
#   .\reset-db-windows.ps1 -NoDemo      # chi seed required (production-like)
# ============================================================

param(
    [switch]$NoDemo,
    [switch]$Force   # Skip confirm prompt — dùng khi script khác gọi tự động
)

# Continue thay vì Stop — PS 5.1 bug: 'Stop' trip khi native command (psql) output NOTICE ra stderr
$ErrorActionPreference = "Continue"

$APP_DIR  = 'C:\qlvb\quanlyvanban'
$WORK_DIR = Join-Path $APP_DIR 'e_office_app_new'
$psqlExe  = 'C:\PostgreSQL\16\bin\psql.exe'
$PG_DB    = 'qlvb_prod'
$PG_USER  = 'qlvb_admin'
$PG_PASS  = 'QlvbProd2026'

# Session variable cho pgp_sym_encrypt trong seed/001 — PHAI match backend SIGNING_SECRET_KEY (.env)
if ($env:SIGNING_SECRET_KEY) {
    $SIGNING_KEY = $env:SIGNING_SECRET_KEY
} else {
    $SIGNING_KEY = 'qlvb-signing-dev-key-change-production-2026'
}

function Log($msg)  { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[!!] $msg" -ForegroundColor Yellow }
function Err($msg)  { Write-Host "[XX] $msg" -ForegroundColor Red; exit 1 }

# Kiem tra Administrator
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Err 'Chay PowerShell voi quyen Administrator'
}

if (-not (Test-Path $psqlExe)) {
    Err "Khong tim thay psql.exe tai: $psqlExe"
}

Write-Host ''
Write-Host '================================================================' -ForegroundColor Red
Write-Host "  [!!] RESET DB - se xoa SACH toan bo data trong $PG_DB" -ForegroundColor Red
if ($NoDemo) {
    Write-Host '  (-NoDemo: chi seed required, KHONG seed demo 002)' -ForegroundColor Yellow
}
Write-Host '================================================================' -ForegroundColor Red
Write-Host ''

# Xac nhan - yeu cau go chinh xac 'yes' (skip khi -Force)
if (-not $Force) {
    $confirm = Read-Host "Xac nhan xoa sach DB? Go 'yes' de tiep tuc"
    if ($confirm -ne 'yes') {
        Write-Host 'Da huy.'
        exit 0
    }
} else {
    Warn '-Force enabled - skip confirm, chay tu dong'
}
Write-Host ''

$env:PGPASSWORD = $PG_PASS

# ============================================================
# 1. Pull code moi (neu la git repo)
# ============================================================
if (Test-Path (Join-Path $APP_DIR '.git')) {
    Log 'Pull code moi...'
    Set-Location $APP_DIR
    git fetch --all -q
    git reset --hard origin/main -q
} else {
    Warn "Skip git pull - $APP_DIR khong phai git repo"
}

# ============================================================
# 2. Drop + recreate schemas
# ============================================================
Log 'Drop tat ca schemas...'

$sqlDrop = @"
DROP SCHEMA IF EXISTS edoc CASCADE;
DROP SCHEMA IF EXISTS esto CASCADE;
DROP SCHEMA IF EXISTS cont CASCADE;
DROP SCHEMA IF EXISTS iso  CASCADE;
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO $PG_USER;
GRANT ALL ON SCHEMA public TO PUBLIC;
"@

& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -c $sqlDrop 2>$null
if ($LASTEXITCODE -ne 0) { Err 'Drop schemas that bai' }

Log 'Schemas da reset'

# ============================================================
# 3. Apply init schemas (01_create_schemas.sql)
# ============================================================
Log 'Apply init/01_create_schemas.sql (extensions + schemas edoc/esto/cont/iso)...'

$initFile = Join-Path $WORK_DIR 'database\init\01_create_schemas.sql'
if (-not (Test-Path $initFile)) { Err "Khong tim thay $initFile" }

$initLog = Join-Path $env:TEMP 'init_schemas.log'
& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $initFile > $initLog 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '---- init_schemas psql output (cuoi file) ----' -ForegroundColor Yellow
    Get-Content $initLog -Tail 30
    Err 'Init schemas that bai'
}
Remove-Item $initLog -ErrorAction SilentlyContinue

# ============================================================
# 4. Apply master schema v2.0
# ============================================================
Log 'Apply schema/000_schema_v3.0.sql (MASTER - tables + SPs + triggers)...'

$schemaFile = Join-Path $WORK_DIR 'database\schema\000_schema_v3.0.sql'
if (-not (Test-Path $schemaFile)) { Err "Khong tim thay $schemaFile" }

$schemaLog = Join-Path $env:TEMP 'schema_master.log'
& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $schemaFile > $schemaLog 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '---- schema_master psql output (cuoi file) ----' -ForegroundColor Yellow
    Get-Content $schemaLog -Tail 30
    Write-Host "---- full log: $schemaLog ----" -ForegroundColor Yellow
    Err 'Schema master that bai'
}
Remove-Item $schemaLog -ErrorAction SilentlyContinue

# ============================================================
# 5. Apply seed 001 (required data)
#    PHAI set app.signing_secret_key cho pgp_sym_encrypt trong seed
# ============================================================
Log 'Apply seed/001_required_data.sql (admin + roles + rights + 2 providers)...'

$seed1File = Join-Path $WORK_DIR 'database\seed\001_required_data.sql'
if (-not (Test-Path $seed1File)) { Err "Khong tim thay $seed1File" }

$seed1Log = Join-Path $env:TEMP 'seed_001.log'
& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 `
  -c "SET app.signing_secret_key = '$SIGNING_KEY';" `
  -f $seed1File > $seed1Log 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '---- seed_001 psql output (cuoi file) ----' -ForegroundColor Yellow
    Get-Content $seed1Log -Tail 30
    Err 'Seed 001 that bai (kiem tra SIGNING_SECRET_KEY env var - can >= 16 ky tu)'
}
Remove-Item $seed1Log -ErrorAction SilentlyContinue

# ============================================================
# 6. Apply seed 002 (demo) - SKIP neu -NoDemo
# ============================================================
if (-not $NoDemo) {
    Log 'Apply seed/002_demo_data.sql (rich demo data 312 records)...'

    $seed2File = Join-Path $WORK_DIR 'database\seed\002_demo_data.sql'
    if (-not (Test-Path $seed2File)) { Err "Khong tim thay $seed2File" }

    $seed2Log = Join-Path $env:TEMP 'seed_002.log'
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $seed2File > $seed2Log 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ''
        Write-Host '---- seed_002 psql output (cuoi file) ----' -ForegroundColor Yellow
        Get-Content $seed2Log -Tail 30
        Err 'Seed 002 that bai'
    }
    Remove-Item $seed2Log -ErrorAction SilentlyContinue
} else {
    Warn 'Skip seed/002_demo_data.sql (-NoDemo) - DB chi co required data'
}

# Verify admin account
$adminCheck = & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -tAc "SELECT COUNT(*) FROM public.staff WHERE username='admin'" 2>$null
$adminCheck = ($adminCheck -replace '\s','')
if ($adminCheck -eq '1') {
    Log 'OK admin account da tao (admin/Admin@123)'
} else {
    Warn 'CHUA co admin account - kiem tra seed 001 logs'
}

# ============================================================
# 7. Rebuild + restart (optional)
# ============================================================
if ($Force) {
    Warn '-Force enabled - skip rebuild prompt (wrapper script se handle rebuild/restart)'
    $rebuild = 'n'
} else {
    $rebuild = Read-Host 'Rebuild backend + frontend? [y/N]'
}
if ($rebuild -eq 'y' -or $rebuild -eq 'Y') {
    Log 'Build Backend...'
    Set-Location (Join-Path $WORK_DIR 'backend')
    npm install --omit=dev 2>$null | Out-Null
    npm run build 2>$null | Out-Null

    Log 'Build Frontend (3-5 phut)...'
    Set-Location (Join-Path $WORK_DIR 'frontend')
    npm install 2>$null | Out-Null
    npm run build 2>$null | Out-Null

    Log 'Restart pm2...'
    Set-Location $WORK_DIR
    try {
        pm2 restart all
    } catch {
        Warn 'pm2 restart that bai - check pm2 status thu cong'
    }
}

Write-Host ''
Write-Host '================================================================' -ForegroundColor Green
Log 'DB reset thanh cong'
Write-Host ''
Write-Host '  Admin: username=admin, password=Admin@123'
Write-Host '  Login: http://<server-ip>'
if (-not $NoDemo) {
    Write-Host '  Demo data: 10 users, 50 VB den, 30 VB di, 20 du thao, 15 HSCV, 2 provider config'
} else {
    Write-Host '  -NoDemo mode: chi admin + 2 provider config (production-like)'
}
Write-Host '================================================================' -ForegroundColor Green
Write-Host ''
