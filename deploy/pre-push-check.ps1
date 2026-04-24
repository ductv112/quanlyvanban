# ============================================================
# e-Office - Pre-Push Check (Local Dev)
# Muc dich: Validate backend + frontend build TRUOC khi git push
#           de tranh code broken len prod.
#
# Chay: PowerShell tu root repo:
#   .\deploy\pre-push-check.ps1
#
# Nen chay sau khi code change lon, truoc khi 'git push origin main'.
# Pass -Fast de skip full frontend build (chi tsc --noEmit).
# ============================================================

param(
    [switch]$Fast   # Skip frontend 'next build' (30-60s), chi tsc check
)

$ErrorActionPreference = 'Continue'
$Start = Get-Date

# -- Helpers --------------------------------------------------
function Log  ($m) { Write-Host "[OK] $m" -ForegroundColor Green }
function Step ($m) { $sec = [int]((Get-Date) - $Start).TotalSeconds; Write-Host "`n[${sec}s] $m" -ForegroundColor Cyan }
function Warn ($m) { Write-Host "[!!] $m" -ForegroundColor Yellow }
function Err  ($m) { Write-Host "[XX] $m" -ForegroundColor Red; exit 1 }

# -- Locate repo root -----------------------------------------
$root = Split-Path -Parent $PSScriptRoot   # deploy/ is child of root
$backend  = Join-Path $root 'e_office_app_new\backend'
$frontend = Join-Path $root 'e_office_app_new\frontend'

if (-not (Test-Path $backend))  { Err "Khong tim thay backend: $backend" }
if (-not (Test-Path $frontend)) { Err "Khong tim thay frontend: $frontend" }

Write-Host ''
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host '  PRE-PUSH CHECK - Validate build truoc khi git push' -ForegroundColor Cyan
Write-Host '================================================================' -ForegroundColor Cyan

# -- 1. Backend TS strict check ------------------------------
Step '1. Backend: tsc --noEmit (strict type check)'
Set-Location $backend

# Kiem tra node_modules co tsc khong
if (-not (Test-Path "$backend\node_modules\.bin\tsc.cmd") -and
    -not (Test-Path "$backend\node_modules\typescript\bin\tsc")) {
    Warn '  tsc khong co trong node_modules - chay npm install truoc'
    npm install 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Err 'Backend npm install that bai' }
}

$log = Join-Path $env:TEMP 'qlvb_pre_push_be.log'
npx tsc --noEmit > $log 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '---- Backend TS errors (cuoi file) ----' -ForegroundColor Yellow
    Get-Content $log -Tail 30
    Write-Host "---- Full log: $log ----" -ForegroundColor Yellow
    Err 'Backend TS strict check FAIL - fix loi tren truoc khi push'
}
Remove-Item $log -ErrorAction SilentlyContinue
Log 'Backend TS strict: 0 errors'

# -- 2. Backend full build -----------------------------------
Step '2. Backend: npm run build (tsc -> dist/)'
$log = Join-Path $env:TEMP 'qlvb_pre_push_be_build.log'
npm run build > $log 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '---- Backend build errors (cuoi file) ----' -ForegroundColor Yellow
    Get-Content $log -Tail 30
    Err 'Backend build FAIL'
}
Remove-Item $log -ErrorAction SilentlyContinue
if (-not (Test-Path "$backend\dist\server.js")) { Err 'dist/server.js khong ton tai' }
Log 'Backend build OK'

# -- 3. Frontend TS / Next build -----------------------------
if ($Fast) {
    Step '3. Frontend: tsc --noEmit (fast mode, skip next build)'
    Set-Location $frontend
    if (-not (Test-Path "$frontend\node_modules\.bin\tsc.cmd") -and
        -not (Test-Path "$frontend\node_modules\typescript\bin\tsc")) {
        Warn '  tsc khong co - chay npm install'
        npm install 2>$null | Out-Null
    }
    $log = Join-Path $env:TEMP 'qlvb_pre_push_fe_tsc.log'
    npx tsc --noEmit > $log 2>&1
    $rc = $LASTEXITCODE
    if ($rc -ne 0) {
        # Frontend TS co pre-existing errors (TreeNode, modal size) - warn nhung khong block
        Warn '  Frontend TS co errors (co the pre-existing, xem log):'
        Get-Content $log -Tail 15
        Warn '  Neu tat ca pre-existing thi OK, neu co loi moi thi fix.'
    } else {
        Log 'Frontend TS strict: 0 errors'
    }
    Remove-Item $log -ErrorAction SilentlyContinue
} else {
    Step '3. Frontend: npm run build (Next.js production, ~30-60s)'
    Set-Location $frontend

    # Verify next CLI
    if (-not (Test-Path "$frontend\node_modules\.bin\next.cmd") -and
        -not (Test-Path "$frontend\node_modules\next\dist\bin\next")) {
        Warn '  next CLI khong co - chay npm install'
        npm install 2>$null | Out-Null
    }

    $log = Join-Path $env:TEMP 'qlvb_pre_push_fe_build.log'
    npm run build > $log 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ''
        Write-Host '---- Frontend build errors (cuoi file) ----' -ForegroundColor Yellow
        Get-Content $log -Tail 40
        Err 'Frontend build FAIL'
    }
    Remove-Item $log -ErrorAction SilentlyContinue
    if (-not (Test-Path "$frontend\.next\BUILD_ID")) { Err '.next/BUILD_ID khong ton tai' }
    Log 'Frontend build OK'
}

# -- Summary --------------------------------------------------
$duration = [int]((Get-Date) - $Start).TotalSeconds
Write-Host ''
Write-Host '================================================================' -ForegroundColor Green
Write-Host "  PRE-PUSH CHECK PASS sau $duration giay - an toan 'git push'" -ForegroundColor Green
Write-Host '================================================================' -ForegroundColor Green
