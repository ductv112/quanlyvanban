# ============================================================
# e-Office — Cap nhat code tren Windows Server
# Chay: PowerShell (Administrator): .\update-windows.ps1
# ============================================================

# Continue thay vì Stop — PS 5.1 bug: 'Stop' trip khi native command (psql) output NOTICE ra stderr
$ErrorActionPreference = "Continue"
function Log($msg) { Write-Host "[OK] $msg" -ForegroundColor Green }

$repoDir = "C:\qlvb\quanlyvanban"
$WORK_DIR = "$repoDir\e_office_app_new"

Write-Host "`n=== e-Office — Cap nhat ===" -ForegroundColor Cyan

# Pull code
Set-Location $repoDir
Log "Pull code moi..."
git fetch --all -q
git reset --hard origin/main -q

# Build backend
Log "Build Backend..."
Set-Location "$WORK_DIR\backend"
npm install --omit=dev 2>$null | Out-Null
npm run build 2>$null | Out-Null

# Build frontend
Log "Build Frontend (3-5 phut)..."
Set-Location "$WORK_DIR\frontend"
npm install 2>$null | Out-Null
npm run build 2>$null | Out-Null

# Re-apply master schema v2.0 (idempotent) - dong bo SP moi neu schema thay doi
# File schema/000_schema_v3.0.sql safe de chay lai vi:
#   - DROP ALL fn_* dau file + CREATE OR REPLACE cho SPs
#   - CREATE TABLE IF NOT EXISTS + ADD CONSTRAINT wrapped trong DO block catch duplicate
# KHONG chay seed (giu nguyen data production)
Log "Re-apply master schema (dong bo SPs moi, idempotent)..."
$psqlExe = 'C:\PostgreSQL\16\bin\psql.exe'
$PG_DB   = 'qlvb_prod'
$PG_USER = 'qlvb_admin'
$PG_PASS = 'QlvbProd2026'
$env:PGPASSWORD = $PG_PASS

$schemaFile = Join-Path $WORK_DIR 'database\schema\000_schema_v3.0.sql'
if (Test-Path $schemaFile) {
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $schemaFile 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[XX] Schema master re-apply that bai - kiem tra thu cong" -ForegroundColor Red
        exit 1
    }
    Log "  -> schema/000_schema_v3.0.sql re-applied OK"
} else {
    Write-Host "[XX] Khong tim thay $schemaFile - kiem tra cau truc repo" -ForegroundColor Red
    exit 1
}

# Restart
Log "Restart ung dung..."
Set-Location $WORK_DIR
pm2 restart all

pm2 status

Write-Host ""
Log "Cap nhat hoan thanh!"
Write-Host ""
