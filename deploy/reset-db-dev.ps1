# ============================================================================
# Reset DEV database (Docker container qlvb_postgres)
# - Khac voi reset-db-windows.ps1 (production): KHONG yeu cau Administrator,
#   KHONG yeu cau native psql, KHONG interactive prompt.
# - Target container: qlvb_postgres (tu docker-compose.yml)
# - DB: qlvb_dev / qlvb_admin / QlvbDev@2026
# ----------------------------------------------------------------------------
# Usage:
#   powershell -File deploy/reset-db-dev.ps1           # reset + seed required + demo
#   powershell -File deploy/reset-db-dev.ps1 -NoDemo   # chi seed required
# Pre-req: container qlvb_postgres phai dang chay (docker compose up -d)
# ============================================================================

param([switch]$NoDemo)

# 'Continue' thay vi 'Stop' — PS 5.1 wrap psql NOTICE stderr thanh ErrorRecord.
$ErrorActionPreference = 'Continue'

$ROOT      = Split-Path -Parent $PSScriptRoot
$APP       = Join-Path $ROOT 'e_office_app_new'
$DB_DIR    = Join-Path $APP 'database'
$CONTAINER = 'qlvb_postgres'
$PG_DB     = 'qlvb_dev'
$PG_USER   = 'qlvb_admin'
$PG_PASS   = 'QlvbDev@2026'

function Log  { param($m) Write-Host "[reset-db-dev] $m" -ForegroundColor Green }
function Warn { param($m) Write-Host "[reset-db-dev] $m" -ForegroundColor Yellow }
function Die  { param($m) Write-Host "[reset-db-dev] ERROR: $m" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------------------
# 1. Verify container running
# ---------------------------------------------------------------------------
$state = & docker inspect --format '{{.State.Status}}' $CONTAINER 2>$null
if ($state -ne 'running') {
    Die "Container '$CONTAINER' chua chay. Chay truoc: docker compose up -d"
}

# ---------------------------------------------------------------------------
# 2. Resolve SIGNING_SECRET_KEY tu backend/.env (fallback: default dev key)
#    Key PHAI match backend SIGNING_SECRET_KEY de pgp_sym_decrypt doc lai duoc.
# ---------------------------------------------------------------------------
$SIGNING_KEY = 'qlvb-dev-signing-key-change-in-production-32chars'
$envFile = Join-Path $APP 'backend\.env'
if (Test-Path $envFile) {
    $hit = Select-String -Path $envFile -Pattern '^SIGNING_SECRET_KEY=(.+)$' -Encoding utf8 | Select-Object -First 1
    if ($hit) {
        $val = $hit.Matches[0].Groups[1].Value.Trim()
        if ($val.Length -ge 16) { $SIGNING_KEY = $val }
    }
}
Log "SIGNING_SECRET_KEY length = $($SIGNING_KEY.Length) chars"

# ---------------------------------------------------------------------------
# Helper: docker cp + psql -f, inline LASTEXITCODE check per call.
# Writes script-level $script:SqlExit so caller can check after invocation.
# ---------------------------------------------------------------------------
function Invoke-SqlFile {
    param([string]$HostFile, [string[]]$PrependArgs = @())
    $script:SqlExit = -1
    if (-not (Test-Path $HostFile)) { Die "Khong tim thay: $HostFile" }
    $name = Split-Path $HostFile -Leaf
    $containerPath = "/tmp/$name"

    & docker cp $HostFile "${CONTAINER}:$containerPath"
    if ($LASTEXITCODE -ne 0) { Die "docker cp $name that bai" }

    $psqlArgs = @('exec', '-e', "PGPASSWORD=$PG_PASS", $CONTAINER,
                  'psql', '-U', $PG_USER, '-d', $PG_DB, '-v', 'ON_ERROR_STOP=1')
    $psqlArgs += $PrependArgs
    $psqlArgs += @('-f', $containerPath)

    & docker @psqlArgs
    $script:SqlExit = $LASTEXITCODE

    & docker exec $CONTAINER rm -f $containerPath | Out-Null
}

# ---------------------------------------------------------------------------
# 3. Drop + recreate schemas (1 inline SQL)
# ---------------------------------------------------------------------------
Log 'Drop schemas (edoc, esto, cont, iso, public) + recreate public...'
$dropSql = "DROP SCHEMA IF EXISTS edoc CASCADE; DROP SCHEMA IF EXISTS esto CASCADE; DROP SCHEMA IF EXISTS cont CASCADE; DROP SCHEMA IF EXISTS iso CASCADE; DROP SCHEMA IF EXISTS public CASCADE; CREATE SCHEMA public; GRANT ALL ON SCHEMA public TO $PG_USER; GRANT ALL ON SCHEMA public TO PUBLIC;"
& docker exec -e "PGPASSWORD=$PG_PASS" $CONTAINER psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 -c $dropSql | Out-Null
if ($LASTEXITCODE -ne 0) { Die 'Drop schemas that bai' }
Log 'OK schemas reset'

# ---------------------------------------------------------------------------
# 4. Apply init/01_create_schemas.sql
# ---------------------------------------------------------------------------
Log 'Apply init/01_create_schemas.sql...'
Invoke-SqlFile (Join-Path $DB_DIR 'init\01_create_schemas.sql')
if ($script:SqlExit -ne 0) { Die 'Init schemas that bai' }
Log 'OK init schemas'

# ---------------------------------------------------------------------------
# 5. Apply master schema v3.0 (tables + SPs + triggers, ~27K lines)
# ---------------------------------------------------------------------------
Log 'Apply schema/000_schema_v3.0.sql (master tables + SPs)...'
Invoke-SqlFile (Join-Path $DB_DIR 'schema\000_schema_v3.0.sql')
if ($script:SqlExit -ne 0) { Die 'Master schema v3.0 that bai' }
Log 'OK schema v3.0'

# ---------------------------------------------------------------------------
# 6. Apply seed/001_required_data.sql — prepend SET signing_key
#    Multiple -f flags: SET file -> session-scoped SET persists qua file seed
# ---------------------------------------------------------------------------
Log 'Apply seed/001_required_data.sql (admin + roles + rights + 2 providers)...'
$setFile = Join-Path $env:TEMP 'set_signing_key.sql'
"SET app.signing_secret_key = '$SIGNING_KEY';" | Out-File -FilePath $setFile -Encoding ascii

& docker cp $setFile "${CONTAINER}:/tmp/set_signing_key.sql"
if ($LASTEXITCODE -ne 0) { Die 'docker cp set_signing_key.sql that bai' }
& docker cp (Join-Path $DB_DIR 'seed\001_required_data.sql') "${CONTAINER}:/tmp/seed_001.sql"
if ($LASTEXITCODE -ne 0) { Die 'docker cp seed_001.sql that bai' }

& docker exec -e "PGPASSWORD=$PG_PASS" $CONTAINER psql -U $PG_USER -d $PG_DB -v ON_ERROR_STOP=1 -f /tmp/set_signing_key.sql -f /tmp/seed_001.sql
$seed1Exit = $LASTEXITCODE

& docker exec $CONTAINER rm -f /tmp/set_signing_key.sql /tmp/seed_001.sql | Out-Null
Remove-Item $setFile -ErrorAction SilentlyContinue

if ($seed1Exit -ne 0) { Die 'Seed 001 that bai (kiem tra SIGNING_SECRET_KEY >= 16 chars)' }
Log 'OK seed 001'

# ---------------------------------------------------------------------------
# 7. Apply seed/002_demo_data.sql (skip if -NoDemo)
# ---------------------------------------------------------------------------
if (-not $NoDemo) {
    Log 'Apply seed/002_demo_data.sql (~320 records demo)...'
    Invoke-SqlFile (Join-Path $DB_DIR 'seed\002_demo_data.sql')
    if ($script:SqlExit -ne 0) { Die 'Seed 002 that bai' }
    Log 'OK seed 002'
} else {
    Warn 'Skip seed/002 (-NoDemo) — DB chi co required data'
}

# ---------------------------------------------------------------------------
# 8. Verify admin account
# ---------------------------------------------------------------------------
$adminCheck = & docker exec -e "PGPASSWORD=$PG_PASS" $CONTAINER psql -U $PG_USER -d $PG_DB -tAc "SELECT COUNT(*) FROM public.staff WHERE username='admin'" 2>$null
$adminCheck = ($adminCheck -join '' -replace '\s','')
if ($adminCheck -match '^1$') {
    Log 'OK admin account (username=admin, password=Admin@123)'
} else {
    Warn "Admin account khong tim thay (got: '$adminCheck')"
}

Write-Host ''
Write-Host '================================================================' -ForegroundColor Green
Log 'DB reset thanh cong'
Write-Host '================================================================' -ForegroundColor Green
