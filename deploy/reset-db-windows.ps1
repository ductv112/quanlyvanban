# ============================================================
# e-Office - Reset DB Windows Server (CHI DUNG CHO TEST)
# Wipe sach DB -> re-run schema + migrations + seed demo
#
# [!!] CANH BAO: Xoa TOAN BO data - KHONG dung tren production that
# Chay: PowerShell (Administrator): .\reset-db-windows.ps1
# ============================================================

# Continue thay vì Stop — PS 5.1 bug: 'Stop' trip khi native command (psql) output NOTICE ra stderr
$ErrorActionPreference = "Continue"

$APP_DIR  = 'C:\qlvb\quanlyvanban'
$WORK_DIR = Join-Path $APP_DIR 'e_office_app_new'
$psqlExe  = 'C:\PostgreSQL\16\bin\psql.exe'
$PG_DB    = 'qlvb_prod'
$PG_USER  = 'qlvb_admin'
$PG_PASS  = 'QlvbProd2026'

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
Write-Host '================================================================' -ForegroundColor Red
Write-Host ''

# Xac nhan - yeu cau go chinh xac 'yes'
$confirm = Read-Host "Xac nhan xoa sach DB? Go 'yes' de tiep tuc"
if ($confirm -ne 'yes') {
    Write-Host 'Da huy.'
    exit 0
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

Log 'Schemas da duoc reset'

# ============================================================
# 3. Apply base schema + quick migrations
# ============================================================
Log 'Apply migrations...'

# Tracking table
$sqlTracking = "CREATE TABLE IF NOT EXISTS public._migration_history (filename VARCHAR(255) PRIMARY KEY, applied_at TIMESTAMPTZ DEFAULT NOW());"
& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -c $sqlTracking 2>$null | Out-Null

function Apply-Migration {
    param([string]$File)
    $fname = Split-Path $File -Leaf
    Log "  -> $fname"
    # Log errors + output to tmp file để debug nếu fail
    $logFile = Join-Path $env:TEMP "migrate_$fname.log"
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $File > $logFile 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "---- psql output (cuối file) ----" -ForegroundColor Yellow
        Get-Content $logFile -Tail 30
        Write-Host "---- full log: $logFile ----" -ForegroundColor Yellow
        Err "Migration $fname that bai"
    }
    Remove-Item $logFile -ErrorAction SilentlyContinue
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -c "INSERT INTO public._migration_history (filename) VALUES ('$fname') ON CONFLICT DO NOTHING" 2>$null | Out-Null
}

$migrationsDir = Join-Path $WORK_DIR 'database\migrations'
Apply-Migration (Join-Path $migrationsDir '000_full_schema.sql')

Get-ChildItem -Path $migrationsDir -Filter 'quick_*.sql' | Sort-Object Name | ForEach-Object {
    Apply-Migration $_.FullName
}

# ============================================================
# 4. Seed demo data
# ============================================================
Log 'Seed demo data...'
$seedFile = Join-Path $WORK_DIR 'database\seed-demo.sql'
if (Test-Path $seedFile) {
    $seedLog = Join-Path $env:TEMP 'seed-demo.log'
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $seedFile > $seedLog 2>&1
    if ($LASTEXITCODE -ne 0) {
        Warn 'Seed demo that bai'
        Write-Host ""
        Write-Host "---- seed-demo psql output (cuối file) ----" -ForegroundColor Yellow
        Get-Content $seedLog -Tail 30
        Write-Host "---- full log: $seedLog ----" -ForegroundColor Yellow
    } else {
        Remove-Item $seedLog -ErrorAction SilentlyContinue
    }
} else {
    Warn 'Khong tim thay seed-demo.sql'
}

# ============================================================
# 5. Rebuild + restart (optional)
# ============================================================
$rebuild = Read-Host 'Rebuild backend + frontend? [y/N]'
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
Log 'DB da reset + apply day du migrations + seed demo'
Write-Host ''
Write-Host '  Demo accounts: xem chi tiet trong seed-demo.sql'
Write-Host '  Login: http://<server-ip>'
Write-Host '================================================================' -ForegroundColor Green
Write-Host ''
