# ============================================================================
# fix-lgsp-config-prod.ps1
# One-shot fix cho prod KH Lang Son: re-seed lgsp_agency_config khi seed/001
# Phase 33.2 INSERT bi skip do conflict trigger parent_id IS NULL vs cay
# to chuc KH (6 DN duoi UBND tinh Lang Son).
# Date: 2026-05-21
# ----------------------------------------------------------------------------
# Cach chay (tren prod Windows Server):
#   cd C:\qlvb\quanlyvanban
#   git pull origin main
#   powershell -ExecutionPolicy Bypass -File deploy\fix-lgsp-config-prod.ps1
#
# Script tu doc SIGNING_SECRET_KEY (fallback JWT_SECRET) tu backend\.env,
# set qua psql session var, chay fix-lgsp-config-prod.sql.
#
# An toan:
#   - Idempotent: ON CONFLICT DO NOTHING — chay lai nhieu lan OK.
#   - Khong DROP table, khong DELETE row, khong DROP user.
#   - Chi UPDATE 1 trigger function + INSERT max 9 row vao lgsp_agency_config.
# ============================================================================

$ErrorActionPreference = 'Continue'

$ROOT     = Split-Path -Parent $PSScriptRoot
$APP      = Join-Path $ROOT 'e_office_app_new'
$ENV_FILE = Join-Path $APP 'backend\.env'
$SQL_FILE = Join-Path $PSScriptRoot 'fix-lgsp-config-prod.sql'
$PSQL_EXE = 'C:\PostgreSQL\16\bin\psql.exe'

$PG_USER  = 'qlvb_admin'
$PG_DB    = 'qlvb_prod'
$PG_HOST  = '127.0.0.1'
$PG_PORT  = '5432'
$PG_PASS  = 'QlvbProd2026'

function Log  { param($m) Write-Host "[fix-lgsp] $m" -ForegroundColor Green }
function Warn { param($m) Write-Host "[fix-lgsp] $m" -ForegroundColor Yellow }
function Err  { param($m) Write-Host "[fix-lgsp] ERROR: $m" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------------------
# 1. Verify pre-requisites
# ---------------------------------------------------------------------------
if (-not (Test-Path $PSQL_EXE)) { Err "Khong tim thay psql.exe: $PSQL_EXE" }
if (-not (Test-Path $SQL_FILE)) { Err "Khong tim thay SQL file: $SQL_FILE" }
if (-not (Test-Path $ENV_FILE)) { Err "Khong tim thay backend\.env: $ENV_FILE" }

# ---------------------------------------------------------------------------
# 2. Resolve SIGNING_SECRET_KEY tu backend\.env (fallback JWT_SECRET)
# ---------------------------------------------------------------------------
$SIGNING_KEY = $null
$hit = Select-String -Path $ENV_FILE -Pattern '^SIGNING_SECRET_KEY=(.+)$' -Encoding utf8 | Select-Object -First 1
if ($hit) {
    $val = $hit.Matches[0].Groups[1].Value.Trim()
    if ($val.Length -ge 16) { $SIGNING_KEY = $val }
}
if (-not $SIGNING_KEY) {
    Warn 'Khong co SIGNING_SECRET_KEY hop le trong .env — fallback JWT_SECRET'
    $hit2 = Select-String -Path $ENV_FILE -Pattern '^JWT_SECRET=(.+)$' -Encoding utf8 | Select-Object -First 1
    if ($hit2) {
        $val2 = $hit2.Matches[0].Groups[1].Value.Trim()
        if ($val2.Length -ge 16) { $SIGNING_KEY = $val2 }
    }
}
if (-not $SIGNING_KEY) { Err 'Khong tim thay SIGNING_SECRET_KEY hoac JWT_SECRET >= 16 ky tu trong backend\.env' }

Log "SIGNING_SECRET_KEY length = $($SIGNING_KEY.Length) chars"

# ---------------------------------------------------------------------------
# 3. Backup DB truoc khi chay (de an toan)
# ---------------------------------------------------------------------------
$BACKUP_DIR = Join-Path $env:TEMP 'qlvb_backup'
if (-not (Test-Path $BACKUP_DIR)) { New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null }
$ts = Get-Date -Format 'yyyyMMdd_HHmmss'
$BACKUP_FILE = Join-Path $BACKUP_DIR "lgsp_agency_config_before_fix_${ts}.sql"

Log "Backup edoc.lgsp_agency_config -> $BACKUP_FILE"
$env:PGPASSWORD = $PG_PASS
& "C:\PostgreSQL\16\bin\pg_dump.exe" -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB `
    -t edoc.lgsp_agency_config --data-only > $BACKUP_FILE 2>$null
if ($LASTEXITCODE -ne 0) {
    Warn 'pg_dump backup loi nhung khong block. Continue...'
}

# ---------------------------------------------------------------------------
# 4. Chay SQL fix
# ---------------------------------------------------------------------------
Log "Chay $SQL_FILE..."
$LOG_FILE = Join-Path $env:TEMP "fix-lgsp-config-prod_${ts}.log"

& $PSQL_EXE -h $PG_HOST -p $PG_PORT -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 `
    -c "SET app.signing_secret_key = '$SIGNING_KEY';" `
    -f $SQL_FILE 2>&1 | Tee-Object -FilePath $LOG_FILE

$exit = $LASTEXITCODE
Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue

if ($exit -ne 0) {
    Err "psql exit $exit — xem log: $LOG_FILE"
}

Log ''
Log '=========================================='
Log ' DONE. Mo /lgsp/cau-hinh tren prod browser:'
Log '   https://doanhnghiep.vatk.org/lgsp/cau-hinh'
Log ' -> Phai thay 9 row (6 prod + 3 sandbox)'
Log '=========================================='
Log ''
Log "Log file: $LOG_FILE"
Log "Backup:   $BACKUP_FILE"
