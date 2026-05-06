# ============================================================
# test-db-setup.ps1 - Setup qlvb_test DB cho automation testing
# Wrapper cho npm run test:db:reset (chay tx backend dir)
#
# Chay:
#   .\deploy\test-db-setup.ps1              # confirm prompt
#   .\deploy\test-db-setup.ps1 -Force       # skip confirm (CI / auto)
#
# Yeu cau:
#   - PostgreSQL chay tren localhost:5432 (docker compose hoac local)
#   - Node.js + npm da install (da chay setup-dev-windows.ps1)
#   - Backend da chay 'npm install' (vitest + tsx + pg deps)
#
# Pre-requisite: tao .env.test trong backend dir tu .env.test.example
# ============================================================

param([switch]$Force)

# Continue thay vi Stop - PS 5.1 bug: Stop trip khi native command output ra stderr
$ErrorActionPreference = "Continue"

$REPO_ROOT = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$BACKEND_DIR = Join-Path $REPO_ROOT 'e_office_app_new\backend'
$ENV_TEST_EXAMPLE = Join-Path $REPO_ROOT '.env.test.example'
$ENV_TEST_BACKEND = Join-Path $BACKEND_DIR '.env.test'

function Log($msg)  { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[!!] $msg" -ForegroundColor Yellow }
function Err($msg)  { Write-Host "[XX] $msg" -ForegroundColor Red; exit 1 }

Write-Host ''
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host '  Setup qlvb_test DB cho automation test' -ForegroundColor Cyan
Write-Host '  (DROP qlvb_test + apply schema v3.0 + seed 001 + seed 003)' -ForegroundColor Cyan
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host ''

# Confirm (skip khi -Force)
if (-not $Force) {
    $confirm = Read-Host "Setup qlvb_test DB? Go 'yes' de tiep tuc"
    if ($confirm -ne 'yes') {
        Write-Host 'Da huy.'
        exit 0
    }
} else {
    Warn '-Force enabled - skip confirm, chay tu dong'
}

# Verify backend dir ton tai
if (-not (Test-Path $BACKEND_DIR)) {
    Err "Backend dir khong ton tai: $BACKEND_DIR"
}

# Verify .env.test ton tai trong backend dir, neu khong copy tu .env.test.example
if (-not (Test-Path $ENV_TEST_BACKEND)) {
    Warn ".env.test khong ton tai trong backend - copy tu .env.test.example..."
    if (Test-Path $ENV_TEST_EXAMPLE) {
        Copy-Item $ENV_TEST_EXAMPLE $ENV_TEST_BACKEND
        Log ".env.test created tu template: $ENV_TEST_BACKEND"
    } else {
        Err ".env.test.example khong ton tai tai $ENV_TEST_EXAMPLE - tao file truoc khi chay"
    }
}

# Verify tools/test-db-reset.ts ton tai
$RESET_SCRIPT = Join-Path $BACKEND_DIR 'tools\test-db-reset.ts'
if (-not (Test-Path $RESET_SCRIPT)) {
    Err "Khong tim thay tools/test-db-reset.ts tai $RESET_SCRIPT"
}

# Detect Docker postgres - neu co thi pass PG_DOCKER_CONTAINER
$dockerContainer = ''
$dockerCheck = & docker ps --filter "name=qlvb_postgres" --format "{{.Names}}" 2>$null
if ($LASTEXITCODE -eq 0 -and $dockerCheck -match 'qlvb_postgres') {
    $dockerContainer = 'qlvb_postgres'
    Log "Detected Docker postgres: $dockerContainer"
} else {
    Log 'Docker postgres khong detect - dung psql local'
}

# Run npm script
Set-Location $BACKEND_DIR
Log 'Running npm run test:db:reset...'
$env:NODE_ENV = 'test'
if ($dockerContainer) {
    $env:PG_DOCKER_CONTAINER = $dockerContainer
}

$startTime = Get-Date
& npm run test:db:reset
$exitCode = $LASTEXITCODE
$elapsed = (Get-Date) - $startTime

Remove-Item Env:NODE_ENV -ErrorAction SilentlyContinue
if ($dockerContainer) {
    Remove-Item Env:PG_DOCKER_CONTAINER -ErrorAction SilentlyContinue
}

if ($exitCode -eq 0) {
    Log "Test DB setup DONE in $([math]::Round($elapsed.TotalSeconds, 1))s"
    if ($elapsed.TotalSeconds -gt 30) {
        Warn "Vuot 30s target (AUTO-02 acceptance) - kiem tra performance"
    }
} else {
    Err "Test DB setup FAILED with exit code $exitCode (elapsed: $([math]::Round($elapsed.TotalSeconds, 1))s)"
}
