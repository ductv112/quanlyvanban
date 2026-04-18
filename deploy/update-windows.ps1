# ============================================================
# e-Office — Cap nhat code tren Windows Server
# Chay: PowerShell (Administrator): .\update-windows.ps1
# ============================================================

$ErrorActionPreference = "Stop"
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

# Apply migration moi (idempotent - tracking qua public._migration_history)
Log "Kiem tra migration moi..."
$psqlExe = 'C:\PostgreSQL\16\bin\psql.exe'
$PG_DB   = 'qlvb_prod'
$PG_USER = 'qlvb_admin'
$PG_PASS = 'QlvbProd2026'
$env:PGPASSWORD = $PG_PASS

& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -c "CREATE TABLE IF NOT EXISTS public._migration_history (filename VARCHAR(255) PRIMARY KEY, applied_at TIMESTAMPTZ DEFAULT NOW());" 2>$null | Out-Null

$migrationsDir = Join-Path $WORK_DIR 'database\migrations'
Get-ChildItem -Path $migrationsDir -Filter 'quick_*.sql' | Sort-Object Name | ForEach-Object {
    $fname = $_.Name
    $exists = & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -tAc "SELECT 1 FROM public._migration_history WHERE filename='$fname'" 2>$null
    if ($exists -notmatch '1') {
        Log "  -> Apply $fname"
        & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $_.FullName 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[XX] Migration $fname that bai - kiem tra thu cong" -ForegroundColor Red
            exit 1
        }
        & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -c "INSERT INTO public._migration_history (filename) VALUES ('$fname') ON CONFLICT DO NOTHING" 2>$null | Out-Null
    }
}

# Restart
Log "Restart ung dung..."
Set-Location $WORK_DIR
pm2 restart all

pm2 status

Write-Host ""
Log "Cap nhat hoan thanh!"
Write-Host ""
