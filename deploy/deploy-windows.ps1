# ============================================================
# e-Office - Deploy Production tren Windows Server 2022
# Chay: PowerShell (Run as Administrator)
#   Set-ExecutionPolicy Bypass -Scope Process -Force
#   .\deploy-windows.ps1
# ============================================================

# Continue thay vì Stop — PS 5.1 bug: 'Stop' trip khi native command (psql) output NOTICE ra stderr
$ErrorActionPreference = 'Continue'

# ---- CAU HINH ----
$SERVER_IP     = '103.97.134.87'
$APP_DIR       = 'C:\qlvb'
$REPO_URL      = 'https://github.com/ductv112/quanlyvanban.git'

$PG_DB         = 'qlvb_prod'
$PG_USER       = 'qlvb_admin'
$PG_PASS       = 'QlvbProd2026'
$REDIS_PASS    = 'QlvbRedis2026'
$MINIO_USER    = 'qlvb_admin'
$MINIO_PASS    = 'QlvbMinio2026'

$JWT_SECRET    = -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 64 | ForEach-Object {[char]$_})

$DOWNLOADS     = Join-Path $APP_DIR '_installers'

function Log($msg)  { Write-Host "[OK] $msg" -ForegroundColor Green }
function Warn($msg) { Write-Host "[!!] $msg" -ForegroundColor Yellow }

# Kiem tra Administrator
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host '[XX] Chay PowerShell voi quyen Administrator' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '============================================' -ForegroundColor Cyan
Write-Host '  e-Office - Deploy Production'
Write-Host "  Server: $SERVER_IP (Windows Server 2022)"
Write-Host '============================================' -ForegroundColor Cyan
Write-Host ''

New-Item -ItemType Directory -Force -Path $APP_DIR | Out-Null
New-Item -ItemType Directory -Force -Path $DOWNLOADS | Out-Null

# ============================================================
# BUOC 1: Cai Git
# ============================================================
Write-Host ''
Write-Host '=== BUOC 1/8: Cai Git ===' -ForegroundColor Yellow

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Log 'Tai Git...'
    $gitUrl = 'https://github.com/git-for-windows/git/releases/download/v2.47.1.windows.2/Git-2.47.1.2-64-bit.exe'
    $gitInstaller = Join-Path $DOWNLOADS 'git-installer.exe'
    Invoke-WebRequest -Uri $gitUrl -OutFile $gitInstaller -UseBasicParsing
    Log 'Cai Git (silent)...'
    Start-Process -FilePath $gitInstaller -ArgumentList '/VERYSILENT /NORESTART /NOCANCEL /SP-' -Wait
    # Refresh PATH
    $machPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $usrPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = $machPath + ';' + $usrPath
    Log 'Git da cai xong'
} else {
    Log ('Git da co san: ' + (git --version))
}

# ============================================================
# BUOC 2: Cai Node.js 20
# ============================================================
Write-Host ''
Write-Host '=== BUOC 2/8: Cai Node.js ===' -ForegroundColor Yellow

if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
    Log 'Tai Node.js 20 LTS...'
    $nodeUrl = 'https://nodejs.org/dist/v20.19.0/node-v20.19.0-x64.msi'
    $nodeInstaller = Join-Path $DOWNLOADS 'node-installer.msi'
    Invoke-WebRequest -Uri $nodeUrl -OutFile $nodeInstaller -UseBasicParsing
    Log 'Cai Node.js (silent)...'
    Start-Process msiexec.exe -ArgumentList ('/i "' + $nodeInstaller + '" /quiet /norestart') -Wait
    $machPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $usrPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = $machPath + ';' + $usrPath
    Log 'Node.js da cai xong'
} else {
    Log ('Node.js da co san: ' + (node --version))
}

# PM2
Log 'Cai PM2...'
npm install -g pm2 2>$null | Out-Null
Log 'PM2 da cai'

# ============================================================
# BUOC 3: Cai PostgreSQL 16
# ============================================================
Write-Host ''
Write-Host '=== BUOC 3/8: Cai PostgreSQL ===' -ForegroundColor Yellow

$pgDir = 'C:\PostgreSQL\16'
$pgBin = Join-Path $pgDir 'bin'
$psqlExe = Join-Path $pgBin 'psql.exe'

if (-not (Test-Path $psqlExe)) {
    Log 'Tai PostgreSQL 16...'
    $pgUrl = 'https://get.enterprisedb.com/postgresql/postgresql-16.8-1-windows-x64.exe'
    $pgInstaller = Join-Path $DOWNLOADS 'pg-installer.exe'
    Invoke-WebRequest -Uri $pgUrl -OutFile $pgInstaller -UseBasicParsing
    Log 'Cai PostgreSQL 16 (mat vai phut)...'
    $pgArgs = '--mode unattended --unattendedmodeui none --prefix "' + $pgDir + '" --datadir "' + $pgDir + '\data" --superpassword "' + $PG_PASS + '" --serverport 5432 --servicename postgresql-16 --enable-components server'
    Start-Process -FilePath $pgInstaller -ArgumentList $pgArgs -Wait
    $env:Path = $env:Path + ';' + $pgBin
    [Environment]::SetEnvironmentVariable('Path', $env:Path, 'Machine')
    Log 'PostgreSQL 16 da cai xong'
} else {
    Log 'PostgreSQL 16 da co san'
}

# Tao database va user
Log 'Tao database va user...'
$env:PGPASSWORD = $PG_PASS
$sqlCreateUser = "DO `$`$`$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '" + $PG_USER + "') THEN CREATE ROLE " + $PG_USER + " LOGIN PASSWORD '" + $PG_PASS + "'; END IF; END `$`$`$;"
& $psqlExe -U postgres -p 5432 -c $sqlCreateUser 2>$null

# Check if DB exists
$dbCheck = & $psqlExe -U postgres -p 5432 -t -c "SELECT 1 FROM pg_database WHERE datname = '$PG_DB'" 2>$null
if ($dbCheck -notmatch '1') {
    & $psqlExe -U postgres -p 5432 -c "CREATE DATABASE $PG_DB OWNER $PG_USER ENCODING 'UTF8';" 2>$null
}
& $psqlExe -U postgres -p 5432 -c "GRANT ALL PRIVILEGES ON DATABASE $PG_DB TO $PG_USER;" 2>$null
& $psqlExe -U postgres -p 5432 -d $PG_DB -c "GRANT ALL ON SCHEMA public TO $PG_USER;" 2>$null
Log "Database $PG_DB da tao"

# ============================================================
# BUOC 4: Cai Redis
# ============================================================
Write-Host ''
Write-Host '=== BUOC 4/8: Cai Redis ===' -ForegroundColor Yellow

$redisSvc = Get-Service -Name 'Redis' -ErrorAction SilentlyContinue
if (-not $redisSvc) {
    Log 'Tai Redis for Windows...'
    $redisUrl = 'https://github.com/tporadowski/redis/releases/download/v5.0.14.1/Redis-x64-5.0.14.1.msi'
    $redisInstaller = Join-Path $DOWNLOADS 'redis-installer.msi'
    Invoke-WebRequest -Uri $redisUrl -OutFile $redisInstaller -UseBasicParsing
    Log 'Cai Redis...'
    Start-Process msiexec.exe -ArgumentList ('/i "' + $redisInstaller + '" /quiet /norestart ADD_TO_PATH=1') -Wait
    $machPath = [System.Environment]::GetEnvironmentVariable('Path', 'Machine')
    $usrPath = [System.Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = $machPath + ';' + $usrPath
    # Set password
    $redisConf = 'C:\Program Files\Redis\redis.windows-service.conf'
    if (Test-Path $redisConf) {
        Add-Content $redisConf ("`nrequirepass " + $REDIS_PASS)
        Restart-Service Redis -ErrorAction SilentlyContinue
    }
    Log 'Redis da cai xong'
} else {
    Log 'Redis da co san'
}

# ============================================================
# BUOC 5: Cai MinIO
# ============================================================
Write-Host ''
Write-Host '=== BUOC 5/8: Cai MinIO ===' -ForegroundColor Yellow

$minioDir = 'C:\minio'
$minioExe = Join-Path $minioDir 'minio.exe'
$nssmExe = Join-Path $DOWNLOADS 'nssm.exe'

if (-not (Test-Path $minioExe)) {
    New-Item -ItemType Directory -Force -Path $minioDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $minioDir 'data') | Out-Null
    Log 'Tai MinIO...'
    Invoke-WebRequest -Uri 'https://dl.min.io/server/minio/release/windows-amd64/minio.exe' -OutFile $minioExe -UseBasicParsing
    Log 'MinIO da tai xong'
}

# NSSM (service manager)
if (-not (Test-Path $nssmExe)) {
    Log 'Tai NSSM...'
    $nssmZip = Join-Path $DOWNLOADS 'nssm.zip'
    Invoke-WebRequest -Uri 'https://nssm.cc/release/nssm-2.24.zip' -OutFile $nssmZip -UseBasicParsing
    Expand-Archive -Path $nssmZip -DestinationPath (Join-Path $DOWNLOADS 'nssm-extract') -Force
    Copy-Item (Join-Path $DOWNLOADS 'nssm-extract\nssm-2.24\win64\nssm.exe') $nssmExe
}

$minioSvc = Get-Service -Name 'minio' -ErrorAction SilentlyContinue
if (-not $minioSvc) {
    Log 'Dang ky MinIO service...'
    $minioArgs = 'server C:\minio\data --console-address :9001'
    & $nssmExe install minio $minioExe $minioArgs
    & $nssmExe set minio AppEnvironmentExtra "MINIO_ROOT_USER=$MINIO_USER" "MINIO_ROOT_PASSWORD=$MINIO_PASS"
    & $nssmExe set minio AppDirectory $minioDir
    & $nssmExe set minio Start SERVICE_AUTO_START
    Start-Service minio
    Log 'MinIO service da chay'
} else {
    Log 'MinIO service da co san'
}

# ============================================================
# BUOC 6: Clone code + Migrations
# ============================================================
Write-Host ''
Write-Host '=== BUOC 6/8: Clone code + Database ===' -ForegroundColor Yellow

$repoDir = Join-Path $APP_DIR 'quanlyvanban'
$gitDir = Join-Path $repoDir '.git'

if (Test-Path $gitDir) {
    Set-Location $repoDir
    git fetch --all -q
    git reset --hard origin/main -q
    git pull -q
    Log 'Source code da cap nhat'
} else {
    Set-Location $APP_DIR
    git clone --depth 1 $REPO_URL 2>$null
    Log 'Source code da clone'
}

$WORK_DIR = Join-Path $repoDir 'e_office_app_new'

# Chay migrations + seed demo (neu fresh install)
Log 'Chay database migrations...'
$env:PGPASSWORD = $PG_PASS

# Tracking table de skip migration da apply
$sqlTracking = "CREATE TABLE IF NOT EXISTS public._migration_history (filename VARCHAR(255) PRIMARY KEY, applied_at TIMESTAMPTZ DEFAULT NOW());"
& $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -c $sqlTracking 2>$null | Out-Null

function Apply-Migration {
    param([string]$File)
    $fname = Split-Path $File -Leaf
    $exists = & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -tAc "SELECT 1 FROM public._migration_history WHERE filename='$fname'" 2>$null
    if ($exists -match '1') { return }
    Log "  -> $fname"
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $File 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[XX] Migration $fname that bai" -ForegroundColor Red
        exit 1
    }
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -c "INSERT INTO public._migration_history (filename) VALUES ('$fname') ON CONFLICT DO NOTHING" 2>$null | Out-Null
}

# Apply base schema
$migrationsDir = Join-Path $WORK_DIR 'database\migrations'
Apply-Migration (Join-Path $migrationsDir '000_full_schema.sql')

# Apply quick migrations (hlj, jsd, ...)
Get-ChildItem -Path $migrationsDir -Filter 'quick_*.sql' | Sort-Object Name | ForEach-Object {
    Apply-Migration $_.FullName
}

# Seed demo chi khi DB trong (fresh install)
$staffCount = & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -tAc "SELECT COUNT(*) FROM public.staff" 2>$null
$staffCount = ($staffCount -replace '\s','')
if ($staffCount -eq '0' -or [string]::IsNullOrEmpty($staffCount)) {
    $seedFile = Join-Path $WORK_DIR 'database\seed-demo.sql'
    if (Test-Path $seedFile) {
        Log "  -> Seed demo data (lan dau)..."
        & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $seedFile 2>$null
        if ($LASTEXITCODE -ne 0) { Warn 'Seed demo that bai (khong critical)' }
    } else {
        Warn 'Khong tim thay seed-demo.sql'
    }
} else {
    Log "  -> Da co $staffCount staff - bo qua seed"
}

Log 'Database migrations hoan thanh'

# ============================================================
# BUOC 7: Build Backend + Frontend
# ============================================================
Write-Host ''
Write-Host '=== BUOC 7/8: Build ung dung ===' -ForegroundColor Yellow

# Backend .env
Log 'Tao backend .env...'
$backendEnv = @"
PORT=4000
NODE_ENV=production
CORS_ORIGIN=http://$SERVER_IP

PG_HOST=127.0.0.1
PG_PORT=5432
PG_DATABASE=$PG_DB
PG_USER=$PG_USER
PG_PASSWORD=$PG_PASS
PG_MAX_CONNECTIONS=20

MONGODB_URI=

REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=$REDIS_PASS

MINIO_ENDPOINT=127.0.0.1
MINIO_PORT=9000
MINIO_ACCESS_KEY=$MINIO_USER
MINIO_SECRET_KEY=$MINIO_PASS
MINIO_USE_SSL=false
MINIO_BUCKET=documents

JWT_SECRET=$JWT_SECRET
JWT_ACCESS_EXPIRES=15m
JWT_REFRESH_EXPIRES=7d
"@
$backendEnvPath = Join-Path $WORK_DIR 'backend\.env'
[System.IO.File]::WriteAllText($backendEnvPath, $backendEnv)

# Build backend
Log 'npm install backend...'
Set-Location (Join-Path $WORK_DIR 'backend')
npm install --omit=dev 2>$null | Out-Null
Log 'Build backend...'
npm run build 2>$null | Out-Null
Log 'Backend build xong'

# Frontend .env
Log 'Tao frontend .env.local...'
$feEnvPath = Join-Path $WORK_DIR 'frontend\.env.local'
[System.IO.File]::WriteAllText($feEnvPath, "NEXT_PUBLIC_API_URL=http://${SERVER_IP}/api")

# Build frontend
Log 'npm install frontend...'
Set-Location (Join-Path $WORK_DIR 'frontend')
npm install 2>$null | Out-Null
Log 'Build frontend (mat 3-5 phut)...'
npm run build 2>$null | Out-Null
Log 'Frontend build xong'

# ============================================================
# BUOC 8: Khoi dong PM2 + Firewall
# ============================================================
Write-Host ''
Write-Host '=== BUOC 8/8: Khoi dong ung dung ===' -ForegroundColor Yellow

# PM2 ecosystem
$ecosystem = @"
module.exports = {
  apps: [
    {
      name: 'eoffice-api',
      cwd: './backend',
      script: 'dist/server.js',
      node_args: '--env-file=.env',
      instances: 1,
      env: { NODE_ENV: 'production' },
      max_memory_restart: '400M',
    },
    {
      name: 'eoffice-web',
      cwd: './frontend',
      script: 'node_modules/.bin/next',
      args: 'start',
      instances: 1,
      env: { NODE_ENV: 'production', PORT: 3000 },
      max_memory_restart: '400M',
    },
  ],
};
"@
$ecoPath = Join-Path $WORK_DIR 'ecosystem.config.cjs'
[System.IO.File]::WriteAllText($ecoPath, $ecosystem)

Set-Location $WORK_DIR
pm2 delete all 2>$null | Out-Null
pm2 start ecosystem.config.cjs
pm2 save

# Firewall
Log 'Cau hinh Firewall...'
New-NetFirewallRule -DisplayName 'HTTP 80' -Direction Inbound -Protocol TCP -LocalPort 80 -Action Allow -ErrorAction SilentlyContinue | Out-Null
New-NetFirewallRule -DisplayName 'HTTPS 443' -Direction Inbound -Protocol TCP -LocalPort 443 -Action Allow -ErrorAction SilentlyContinue | Out-Null
Log 'Firewall: da mo port 80, 443'

# ============================================================
# HOAN THANH
# ============================================================
Write-Host ''
Write-Host '============================================' -ForegroundColor Green
Write-Host '  DEPLOY HOAN THANH!' -ForegroundColor Green
Write-Host '============================================' -ForegroundColor Green
Write-Host ''
Write-Host '  Ung dung dang chay tai:'
Write-Host '    Frontend: http://localhost:3000'
Write-Host '    Backend:  http://localhost:4000'
Write-Host ''
Write-Host '  Tai khoan mac dinh:'
Write-Host '    Username: admin'
Write-Host '    Password: Admin@123'
Write-Host ''
Write-Host '  Tiep theo: chay setup-iis.ps1 de cau hinh reverse proxy'
Write-Host "  Sau do truy cap: http://$SERVER_IP"
Write-Host ''
Write-Host '  Quan ly:'
Write-Host '    pm2 status         - xem trang thai'
Write-Host '    pm2 logs           - xem logs'
Write-Host '    pm2 restart all    - restart'
Write-Host ''
Write-Host "  JWT_SECRET: $JWT_SECRET"
Write-Host ''
Write-Host '============================================' -ForegroundColor Green
