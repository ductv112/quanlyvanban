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

# Restart
Log "Restart ung dung..."
Set-Location $WORK_DIR
pm2 restart all

pm2 status

Write-Host ""
Log "Cap nhat hoan thanh!"
Write-Host ""
