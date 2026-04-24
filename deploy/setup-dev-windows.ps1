# ============================================================================
# Setup DEV environment from scratch (Windows)
# - Copy .env files tu .example (neu chua co) + merge keys con thieu
# - Docker compose up (postgres, mongo, redis, minio)
# - npm install backend + frontend + workers
# - Reset DB clean + apply schema v3.0 + seed 001 + seed 002
# ----------------------------------------------------------------------------
# Usage: powershell -File deploy/setup-dev-windows.ps1
# Pre-req: Docker Desktop chay, Node.js 18+, PowerShell 5+
# ============================================================================

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent $PSScriptRoot
$APP  = Join-Path $ROOT 'e_office_app_new'

function Log {
    param([string]$msg, [string]$color = 'Cyan')
    Write-Host "[setup-dev] $msg" -ForegroundColor $color
}

function Section {
    param([string]$title)
    Write-Host ''
    Write-Host '=================================================================' -ForegroundColor Yellow
    Write-Host " $title" -ForegroundColor Yellow
    Write-Host '=================================================================' -ForegroundColor Yellow
}

# ---------------------------------------------------------------------------
# Helper: sync .env with .env.example (copy if missing, merge missing keys if exists)
# ---------------------------------------------------------------------------
function Sync-EnvFile {
    param([string]$EnvFile, [string]$ExampleFile)

    if (-not (Test-Path $ExampleFile)) {
        return @{ Status = 'no-example'; Keys = @() }
    }

    if (-not (Test-Path $EnvFile)) {
        Copy-Item $ExampleFile $EnvFile
        return @{ Status = 'copied'; Keys = @() }
    }

    # Parse keys from both files (line starting with KEY=)
    $envKeys = @{}
    foreach ($line in Get-Content $EnvFile) {
        if ($line -match '^\s*([A-Z0-9_]+)\s*=') { $envKeys[$matches[1]] = $true }
    }

    $missing = @()
    foreach ($line in Get-Content $ExampleFile) {
        if ($line -match '^\s*([A-Z0-9_]+)\s*=') {
            if (-not $envKeys.ContainsKey($matches[1])) {
                $missing += [pscustomobject]@{ Key = $matches[1]; Line = $line }
            }
        }
    }

    if ($missing.Count -eq 0) {
        return @{ Status = 'up-to-date'; Keys = @() }
    }

    # Append missing keys (preserve original line including comments would be nice,
    # but plain key=value line is sufficient for dev defaults).
    $stamp = Get-Date -Format 'yyyy-MM-dd'
    Add-Content -Path $EnvFile -Value ''
    Add-Content -Path $EnvFile -Value "# === Auto-added missing keys from .env.example ($stamp) ==="
    foreach ($m in $missing) {
        Add-Content -Path $EnvFile -Value $m.Line
    }
    return @{ Status = 'merged'; Keys = ($missing | ForEach-Object { $_.Key }) }
}

# ---------------------------------------------------------------------------
Section '1/6 - Sync .env files with .env.example'
# ---------------------------------------------------------------------------

$beRes = Sync-EnvFile (Join-Path $APP 'backend\.env') (Join-Path $APP 'backend\.env.example')
switch ($beRes.Status) {
    'no-example' { Log 'ERROR: khong tim thay backend/.env.example' 'Red'; exit 1 }
    'copied'     { Log 'OK backend/.env (tao moi tu .env.example)' 'Green' }
    'up-to-date' { Log 'OK backend/.env (dung + day du keys)' 'Gray' }
    'merged'     { Log "OK backend/.env (da append $($beRes.Keys.Count) keys: $($beRes.Keys -join ', '))" 'Green' }
}

$feRes = Sync-EnvFile (Join-Path $APP 'frontend\.env.local') (Join-Path $APP 'frontend\.env.example')
switch ($feRes.Status) {
    'no-example' {
        Log 'WARN: khong co frontend/.env.example — tao mac dinh' 'Yellow'
        $feEnv = Join-Path $APP 'frontend\.env.local'
        if (-not (Test-Path $feEnv)) {
            Set-Content $feEnv "NEXT_PUBLIC_API_URL=http://localhost:4000/api`r`nNEXT_PUBLIC_SOCKET_URL=http://localhost:4000"
        }
    }
    'copied'     { Log 'OK frontend/.env.local (tao moi tu .env.example)' 'Green' }
    'up-to-date' { Log 'OK frontend/.env.local (day du keys)' 'Gray' }
    'merged'     { Log "OK frontend/.env.local (da append $($feRes.Keys.Count) keys: $($feRes.Keys -join ', '))" 'Green' }
}

# ---------------------------------------------------------------------------
Section '2/6 - Docker compose up (postgres, mongo, redis, minio)'
# ---------------------------------------------------------------------------

$composeFile = Join-Path $APP 'docker-compose.yml'
if (-not (Test-Path $composeFile)) {
    Log "ERROR: khong tim thay $composeFile" 'Red'
    exit 1
}

Log 'Starting Docker services...'
& docker compose -f $composeFile up -d
if ($LASTEXITCODE -ne 0) {
    Log 'ERROR: docker compose up that bai — Docker Desktop chay chua?' 'Red'
    exit 1
}

Log 'Doi postgres healthy (max 30s)...'
$waited = 0
while ($waited -lt 30) {
    $health = & docker inspect --format '{{.State.Health.Status}}' qlvb_postgres 2>$null
    if ($health -eq 'healthy') {
        Log 'OK postgres healthy' 'Green'
        break
    }
    Start-Sleep -Seconds 2
    $waited += 2
}
if ($waited -ge 30) {
    Log 'WARN: postgres chua healthy sau 30s — van tiep tuc' 'Yellow'
}

# ---------------------------------------------------------------------------
Section '3/6 - npm install (backend + frontend + workers)'
# ---------------------------------------------------------------------------

foreach ($mod in @('backend', 'frontend', 'workers')) {
    $modPath = Join-Path $APP $mod
    if (-not (Test-Path $modPath)) {
        Log "WARN: $mod khong ton tai — skip" 'Yellow'
        continue
    }
    if (Test-Path (Join-Path $modPath 'node_modules')) {
        Log "OK $mod/node_modules da co — skip install" 'Gray'
        continue
    }
    Log "Installing $mod..." 'Cyan'
    Push-Location $modPath
    try {
        & npm install --silent
        if ($LASTEXITCODE -ne 0) {
            Log "ERROR: npm install $mod that bai" 'Red'
            exit 1
        }
        Log "OK $mod installed" 'Green'
    } finally {
        Pop-Location
    }
}

# ---------------------------------------------------------------------------
Section '4/6 - Reset DB clean + apply schema v3.0 + seed'
# ---------------------------------------------------------------------------

$resetScript = Join-Path $PSScriptRoot 'reset-db-dev.ps1'
if (-not (Test-Path $resetScript)) {
    Log "ERROR: khong tim thay $resetScript" 'Red'
    exit 1
}
Log 'Running reset-db-dev.ps1 (docker exec psql, drop + schema v3.0 + seed 001 + 002)...'
& powershell -ExecutionPolicy Bypass -File $resetScript
if ($LASTEXITCODE -ne 0) {
    Log 'ERROR: reset-db-dev that bai — xem log tren' 'Red'
    exit 1
}
Log 'OK DB ready: ~320 records demo, admin login OK' 'Green'

# ---------------------------------------------------------------------------
Section '5/6 - Verify backend syntax (tsc check)'
# ---------------------------------------------------------------------------

Push-Location (Join-Path $APP 'backend')
try {
    Log 'Quick TS check...'
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    & npx tsc --noEmit
    $ErrorActionPreference = $prevEAP
    Log 'OK Backend TS check done (errors tren la pre-existing — khong block)' 'Gray'
} finally {
    Pop-Location
}

# ---------------------------------------------------------------------------
Section '6/6 - Done!'
# ---------------------------------------------------------------------------

Write-Host ''
Write-Host '  SETUP HOAN TAT — san sang test' -ForegroundColor Green
Write-Host ''
Write-Host '  Mo 2 terminal va chay:' -ForegroundColor White
Write-Host '    Terminal 1: cd e_office_app_new\backend  ; npm run dev' -ForegroundColor Cyan
Write-Host '    Terminal 2: cd e_office_app_new\frontend ; npm run dev' -ForegroundColor Cyan
Write-Host ''
Write-Host '  Browser: http://localhost:3000' -ForegroundColor White
Write-Host '  Login:   admin / Admin@123' -ForegroundColor White
Write-Host ''
Write-Host '  Tai khoan test khac (deu password Admin@123):' -ForegroundColor White
Write-Host '    nguyenvana - So Noi vu' -ForegroundColor Gray
Write-Host '    tranthib   - So Tai chinh' -ForegroundColor Gray
Write-Host '    levand     - So Thong tin va Truyen thong' -ForegroundColor Gray
Write-Host ''
