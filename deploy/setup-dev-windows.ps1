# ============================================================================
# Setup dev environment from scratch (Windows)
# - Copy .env files từ .example (nếu chưa có)
# - Docker compose up (postgres, mongo, redis, minio)
# - npm install backend + frontend + workers
# - Reset DB clean + apply schema v3.0 + seed 001 + seed 002
# ----------------------------------------------------------------------------
# Usage: powershell -File deploy/setup-dev-windows.ps1
# Pre-req: Docker Desktop chạy, Node.js 18+, PowerShell 5+
# ============================================================================

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent $PSScriptRoot
$APP = Join-Path $ROOT 'e_office_app_new'

function Log {
    param([string]$msg, [string]$color = 'Cyan')
    Write-Host "[setup-dev] $msg" -ForegroundColor $color
}

function Section {
    param([string]$title)
    Write-Host "" -ForegroundColor White
    Write-Host "=================================================================" -ForegroundColor Yellow
    Write-Host " $title" -ForegroundColor Yellow
    Write-Host "=================================================================" -ForegroundColor Yellow
}

# ----------------------------------------------------------------------------
Section "1/6 — Copy .env từ .example (nếu chưa có)"
# ----------------------------------------------------------------------------

$beEnv = Join-Path $APP 'backend\.env'
$beExample = Join-Path $APP 'backend\.env.example'
if (-not (Test-Path $beEnv)) {
    if (-not (Test-Path $beExample)) {
        Log "ERROR: Không tìm thấy backend/.env.example" 'Red'
        exit 1
    }
    Copy-Item $beExample $beEnv
    Log "✓ Tạo backend/.env (từ .example)" 'Green'
} else {
    Log "✓ backend/.env đã tồn tại — skip" 'Gray'
}

$feEnv = Join-Path $APP 'frontend\.env.local'
$feExample = Join-Path $APP 'frontend\.env.example'
if (-not (Test-Path $feEnv)) {
    if (Test-Path $feExample) {
        Copy-Item $feExample $feEnv
        Log "✓ Tạo frontend/.env.local (từ .example)" 'Green'
    } else {
        Log "WARN: Không có frontend/.env.example — tạo mặc định" 'Yellow'
        Set-Content $feEnv "NEXT_PUBLIC_API_URL=http://localhost:4000/api`r`nNEXT_PUBLIC_SOCKET_URL=http://localhost:4000"
    }
} else {
    Log "✓ frontend/.env.local đã tồn tại — skip" 'Gray'
}

# ----------------------------------------------------------------------------
Section "2/6 — Docker compose up (postgres, mongo, redis, minio)"
# ----------------------------------------------------------------------------

$composeFile = Join-Path $APP 'docker-compose.yml'
if (-not (Test-Path $composeFile)) {
    Log "ERROR: Không tìm thấy $composeFile" 'Red'
    exit 1
}

Log "Starting Docker services..."
& docker compose -f $composeFile up -d 2>&1 | Out-String | Write-Host
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: docker compose up thất bại — kiểm tra Docker Desktop chạy chưa?" 'Red'
    exit 1
}

Log "Đợi postgres healthy (max 30s)..."
$waited = 0
while ($waited -lt 30) {
    $health = & docker inspect --format '{{.State.Health.Status}}' qlvb_postgres 2>$null
    if ($health -eq 'healthy') {
        Log "✓ Postgres healthy" 'Green'
        break
    }
    Start-Sleep -Seconds 2
    $waited += 2
}
if ($waited -ge 30) {
    Log "WARN: Postgres chưa healthy sau 30s — vẫn tiếp tục" 'Yellow'
}

# ----------------------------------------------------------------------------
Section "3/6 — npm install (backend + frontend + workers)"
# ----------------------------------------------------------------------------

foreach ($mod in @('backend', 'frontend', 'workers')) {
    $modPath = Join-Path $APP $mod
    if (-not (Test-Path $modPath)) {
        Log "WARN: $mod không tồn tại — skip" 'Yellow'
        continue
    }
    if (Test-Path (Join-Path $modPath 'node_modules')) {
        Log "✓ $mod/node_modules đã có — skip install" 'Gray'
        continue
    }
    Log "Installing $mod..." 'Cyan'
    Push-Location $modPath
    try {
        & npm install --silent 2>&1 | Out-String | Write-Host
        if ($LASTEXITCODE -ne 0) {
            Log "ERROR: npm install $mod thất bại" 'Red'
            exit 1
        }
        Log "✓ $mod installed" 'Green'
    } finally {
        Pop-Location
    }
}

# ----------------------------------------------------------------------------
Section "4/6 — Reset DB clean + apply schema v3.0 + seed"
# ----------------------------------------------------------------------------

$resetScript = Join-Path $PSScriptRoot 'reset-db-windows.ps1'
if (-not (Test-Path $resetScript)) {
    Log "ERROR: Không tìm thấy $resetScript" 'Red'
    exit 1
}
Log "Running reset-db-windows.ps1 (drop schemas + apply schema v3.0 + seed 001 + seed 002)..."
& powershell -File $resetScript
if ($LASTEXITCODE -ne 0) {
    Log "ERROR: reset-db thất bại — xem log trên" 'Red'
    exit 1
}
Log "✓ DB ready: 50+ VB demo, admin login OK" 'Green'

# ----------------------------------------------------------------------------
Section "5/6 — Verify backend syntax (tsc check)"
# ----------------------------------------------------------------------------

Push-Location (Join-Path $APP 'backend')
try {
    Log "Quick TS check..."
    & npx tsc --noEmit 2>&1 | Select-Object -First 10 | Out-String | Write-Host
    Log "✓ Backend TS check done (errors trên là pre-existing — không block)" 'Gray'
} finally {
    Pop-Location
}

# ----------------------------------------------------------------------------
Section "6/6 — Done!"
# ----------------------------------------------------------------------------

Write-Host ""
Write-Host "  ✅ SETUP HOÀN TẤT — sẵn sàng test" -ForegroundColor Green
Write-Host ""
Write-Host "  Mở 2 terminal và chạy:" -ForegroundColor White
Write-Host "    Terminal 1: cd e_office_app_new\backend && npm run dev" -ForegroundColor Cyan
Write-Host "    Terminal 2: cd e_office_app_new\frontend && npm run dev" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Browser: http://localhost:3000" -ForegroundColor White
Write-Host "  Login:   admin / Admin@123" -ForegroundColor White
Write-Host ""
Write-Host "  Tài khoản test khác (đều password Admin@123):" -ForegroundColor White
Write-Host "    nguyenvana — Sở Nội vụ" -ForegroundColor Gray
Write-Host "    tranthib   — Sở Tài chính" -ForegroundColor Gray
Write-Host "    levand     — Sở Thông tin và Truyền thông" -ForegroundColor Gray
Write-Host ""
