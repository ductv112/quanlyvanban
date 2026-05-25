# ============================================================
# e-Office - Deploy Production tren Windows Server 2022
# Chay: PowerShell (Run as Administrator)
#   Set-ExecutionPolicy Bypass -Scope Process -Force
#
# Mac dinh deploy server Lang Son (qlvbdn.lstt.vn / 113.160.156.10):
#   .\deploy-windows.ps1
#
# Override IP/Domain neu deploy server khac:
#   .\deploy-windows.ps1 -ServerIP 1.2.3.4 -Domain my.domain.vn
#   .\deploy-windows.ps1 -ServerIP 103.97.134.87 -Domain doanhnghiep.vatk.org
#
# Sau khi seed 001 xong, neu file seed 003_lang_son_init.sql ton tai trong repo
# (default: co), script tu dong apply -> rename UBND -> Lang Son + tao 6 DN +
# 9 row lgsp_agency_config. Skip neu ko muon: them flag -SkipLangSonSeed.
# ============================================================
param(
    [string]$ServerIP = '113.160.156.10',
    [string]$Domain = 'qlvbdn.lstt.vn',
    [switch]$SkipLangSonSeed
)

# Continue thay vì Stop — PS 5.1 bug: 'Stop' trip khi native command (psql) output NOTICE ra stderr
$ErrorActionPreference = 'Continue'

# QUAN TRONG: PS 5.1 default client encoding = WIN1252 -> psql doc file UTF-8 co tieng
# Viet se conversion fail ("character with byte sequence 0xXX in encoding WIN1252 has no
# equivalent in UTF8"). Set PGCLIENTENCODING=UTF8 de psql doc file UTF-8 truc tiep.
# Reference: memory reference_prod_server_setup.md (encoding trap)
$env:PGCLIENTENCODING = 'UTF8'

# ---- CAU HINH ----
$SERVER_IP     = $ServerIP
$DOMAIN        = $Domain
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

# NSSM (service manager) — skip toan bo block neu MinIO service da chay (cai thu cong qua choco/winget)
$minioSvc = Get-Service -Name 'minio' -ErrorAction SilentlyContinue
if (-not $minioSvc -and (-not (Test-Path $nssmExe))) {
    Log 'Tai NSSM (nssm.cc thuong sap, neu fail anh dung: choco install nssm hoac winget install NSSM.NSSM)...'
    $nssmZip = Join-Path $DOWNLOADS 'nssm.zip'
    try {
        Invoke-WebRequest -Uri 'https://nssm.cc/release/nssm-2.24.zip' -OutFile $nssmZip -UseBasicParsing -ErrorAction Stop
        Expand-Archive -Path $nssmZip -DestinationPath (Join-Path $DOWNLOADS 'nssm-extract') -Force
        Copy-Item (Join-Path $DOWNLOADS 'nssm-extract\nssm-2.24\win64\nssm.exe') $nssmExe
    } catch {
        Warn 'NSSM download fail (nssm.cc 503/down). Dung choco install nssm hoac winget install NSSM.NSSM roi re-run.'
    }
}

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

# Apply DB schema + seed (v2.0 consolidated)
#   - init/01_create_schemas.sql  -> schemas + extensions
#   - schema/000_schema_v3.0.sql  -> MASTER idempotent (tables + SPs + triggers)
#   - seed/001_required_data.sql  -> admin + roles + rights + 2 provider config
#   KHONG chay seed/002_demo_data.sql (production deploy - khong demo data)
Log 'Apply DB schema + seed...'
$env:PGPASSWORD = $PG_PASS

# Kiem tra DB da co data chua (detect fresh install vs update)
$staffCount = & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -tAc "SELECT COUNT(*) FROM public.staff" 2>$null
$staffCount = ($staffCount -replace '\s','')

if ([string]::IsNullOrEmpty($staffCount) -or $staffCount -eq '0') {
    Log '  -> Fresh install - apply schema v2.0 + seed 001...'

    # 1. Init schemas + extensions
    $initFile = Join-Path $WORK_DIR 'database\init\01_create_schemas.sql'
    Log "  -> init/01_create_schemas.sql"
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $initFile 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host '[XX] Init schemas that bai' -ForegroundColor Red; exit 1 }

    # 2. Apply master schema (idempotent)
    $schemaFile = Join-Path $WORK_DIR 'database\schema\000_schema_v3.0.sql'
    Log "  -> schema/000_schema_v3.0.sql (master - tables + SPs + triggers)"
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $schemaFile 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host '[XX] Schema master that bai' -ForegroundColor Red; exit 1 }

    # 3. Apply seed 001 - required data + 2 provider config
    # CRITICAL: psql `-c "SET ..." -f file.sql` KHONG truyen SET context sang -f
    # (verified bug 2026-05-25). Phai dung WRAPPER FILE: SET + \i seed_file gop trong
    # cung 1 file -> 1 psql session. Stderr KHONG suppress (2>&1 -> log file) de debug.
    $seed1File = Join-Path $WORK_DIR 'database\seed\001_required_data.sql'
    $seed1Wrapper = Join-Path $env:TEMP 'qlvb_seed001_wrapper.sql'
    $seed1Path = $seed1File -replace '\\', '/'  # \i needs forward slashes
    $seed1Content = "SET app.signing_secret_key = '$JWT_SECRET';`n\i '$seed1Path'"
    [System.IO.File]::WriteAllText($seed1Wrapper, $seed1Content, [System.Text.UTF8Encoding]::new($false))
    Log "  -> seed/001_required_data.sql (admin/Admin@123 + 2 providers, wrapper qua $env:TEMP)"
    $seed1Log = Join-Path $env:TEMP 'qlvb_seed001.log'
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $seed1Wrapper > $seed1Log 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host '---- seed/001 output (50 dong cuoi) ----' -ForegroundColor Yellow
        Get-Content $seed1Log -Tail 50
        Write-Host "---- Full log: $seed1Log ----" -ForegroundColor Yellow
        Write-Host '[XX] Seed 001 that bai' -ForegroundColor Red; exit 1
    }
    Remove-Item $seed1Wrapper -ErrorAction SilentlyContinue
    Remove-Item $seed1Log -ErrorAction SilentlyContinue

    Log '  -> Fresh install hoan thanh (admin/Admin@123 san sang)'

    # 4. Apply seed 003 - init cay to chuc Lang Son (UBND + 6 DN + 9 lgsp_agency_config)
    #    Cung dung wrapper pattern voi seed 001.
    $seed3File = Join-Path $WORK_DIR 'database\seed\003_lang_son_init.sql'
    if ((-not $SkipLangSonSeed) -and (Test-Path $seed3File)) {
        $seed3Wrapper = Join-Path $env:TEMP 'qlvb_seed003_wrapper.sql'
        $seed3Path = $seed3File -replace '\\', '/'
        $seed3Content = "SET app.signing_secret_key = '$JWT_SECRET';`n\i '$seed3Path'"
        [System.IO.File]::WriteAllText($seed3Wrapper, $seed3Content, [System.Text.UTF8Encoding]::new($false))
        Log "  -> seed/003_lang_son_init.sql (UBND tinh Lang Son + 6 DN + 9 lgsp_agency_config)"
        $seed3Log = Join-Path $env:TEMP 'qlvb_seed003.log'
        & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $seed3Wrapper > $seed3Log 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host '---- seed/003 output (50 dong cuoi) ----' -ForegroundColor Yellow
            Get-Content $seed3Log -Tail 50
            Write-Host "---- Full log: $seed3Log ----" -ForegroundColor Yellow
            Write-Host '[XX] Seed 003 Lang Son that bai' -ForegroundColor Red; exit 1
        }
        Remove-Item $seed3Wrapper -ErrorAction SilentlyContinue
        Remove-Item $seed3Log -ErrorAction SilentlyContinue
        Log '  -> Lang Son init done: 6 DN H37.DN.001..006 + 9 lgsp_agency_config (placeholder)'
    } else {
        Log '  -> Skip seed 003 Lang Son (SkipLangSonSeed=true hoac file khong ton tai)'
    }
} else {
    # Update deploy - re-apply master schema de dong bo SP moi, KHONG seed
    Log '  -> Update deploy - re-apply master schema (idempotent)...'
    $schemaFile = Join-Path $WORK_DIR 'database\schema\000_schema_v3.0.sql'
    & $psqlExe -U $PG_USER -d $PG_DB -p 5432 -h 127.0.0.1 -v ON_ERROR_STOP=1 -f $schemaFile 2>$null
    if ($LASTEXITCODE -ne 0) { Write-Host '[XX] Schema master re-apply that bai' -ForegroundColor Red; exit 1 }
    Log "  -> Da co $staffCount staff - bo qua seed, giu nguyen data"
}

Log 'Database setup hoan thanh'

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
# CORS_ORIGIN: whitelist domain + IP (HTTP only - chua co SSL).
# Khi co cert: them https://$DOMAIN vao truoc HTTP version, pm2 restart all --update-env.
CORS_ORIGIN=http://$DOMAIN,http://$SERVER_IP,http://localhost:3000

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

# PHAI match key da dung khi seed 001 encrypt provider client_secret
SIGNING_SECRET_KEY=$JWT_SECRET

# LibreOffice cho preview file Word/Excel/PowerPoint
LIBREOFFICE_PATH=C:\Program Files\LibreOffice\program\soffice.com

# LGSP mock (chua go-live LGSP that, admin nhap credential qua UI sau)
MOCK_EXTERNAL=true
"@
$backendEnvPath = Join-Path $WORK_DIR 'backend\.env'
[System.IO.File]::WriteAllText($backendEnvPath, $backendEnv)

# Build backend
# IMPORTANT (CLAUDE.md pitfall #2): npm install KHONG --omit=dev vi can typescript
# (devDep) de compile tsc -> dist/. NODE_ENV=development truoc npm install, sau do
# pm2 chay app voi NODE_ENV=production trong ecosystem config.
Log 'npm install backend (full deps including devDeps for tsc)...'
Set-Location (Join-Path $WORK_DIR 'backend')
$env:NODE_ENV = 'development'
npm install 2>$null | Out-Null
if (-not (Test-Path "$WORK_DIR\backend\node_modules\.bin\tsc.cmd") -and -not (Test-Path "$WORK_DIR\backend\node_modules\typescript\bin\tsc")) {
    Write-Host '[XX] typescript khong co trong node_modules - check .npmrc' -ForegroundColor Red; exit 1
}
Log 'Build backend (tsc -> dist/)...'
npm run build 2>$null | Out-Null
if (-not (Test-Path "$WORK_DIR\backend\dist\server.js")) {
    Write-Host '[XX] Backend dist/server.js khong ton tai sau build' -ForegroundColor Red; exit 1
}
Log 'Backend build xong'

# Frontend .env
# NEXT_PUBLIC_API_URL = /api (RELATIVE - khuyen nghi):
#   - Browser tu dung host hien tai (https://$DOMAIN hoac http://$SERVER_IP)
#   - Tranh hard-code IP vao bundle -> tuong thich ca domain HTTPS sau nay
#   - Tham khao .env.example line 13-31
Log 'Tao frontend .env.local...'
$feEnvPath = Join-Path $WORK_DIR 'frontend\.env.local'
$feEnv = @"
NEXT_PUBLIC_API_URL=/api
NEXT_PUBLIC_SOCKET_URL=/
"@
[System.IO.File]::WriteAllText($feEnvPath, $feEnv)

# Build frontend
Log 'npm install frontend (full deps for next CLI)...'
Set-Location (Join-Path $WORK_DIR 'frontend')
$env:NODE_ENV = 'development'
npm install 2>$null | Out-Null
if (-not (Test-Path "$WORK_DIR\frontend\node_modules\.bin\next.cmd") -and -not (Test-Path "$WORK_DIR\frontend\node_modules\next\dist\bin\next")) {
    Write-Host '[XX] next CLI khong co trong node_modules' -ForegroundColor Red; exit 1
}
$env:NODE_ENV = 'production'
Log 'Build frontend (Next.js production, 3-5 phut)...'
npm run build 2>$null | Out-Null
if (-not (Test-Path "$WORK_DIR\frontend\.next\BUILD_ID")) {
    Write-Host '[XX] Frontend .next/BUILD_ID khong ton tai sau build' -ForegroundColor Red; exit 1
}
Log 'Frontend build xong'

# Build workers (BullMQ consumer cho LGSP send/receive/status + email/SMS)
# Workers la process RIENG, KHONG chay chung backend. Khong co workers thi LGSP
# queue produced nhung khong consume -> VB khong gui/nhan duoc qua truc.
Log 'Tao workers .env (copy tu backend/.env - dung chung Redis/PG/MinIO/LGSP creds)...'
Copy-Item (Join-Path $WORK_DIR 'backend\.env') (Join-Path $WORK_DIR 'workers\.env') -Force

Log 'npm install workers (full deps for tsc)...'
Set-Location (Join-Path $WORK_DIR 'workers')
$env:NODE_ENV = 'development'
npm install 2>$null | Out-Null
if (-not (Test-Path "$WORK_DIR\workers\node_modules\typescript\bin\tsc")) {
    Write-Host '[XX] typescript khong co trong workers/node_modules' -ForegroundColor Red; exit 1
}
Log 'Build workers (tsc -> dist/)...'
npm run build 2>$null | Out-Null
if (-not (Test-Path "$WORK_DIR\workers\dist\index.js")) {
    Write-Host '[XX] Workers dist/index.js khong ton tai sau build' -ForegroundColor Red; exit 1
}
Log 'Workers build xong'

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
      // PM2 cluster mode KHONG truyen --env-file dung cach -> backend crash silent.
      // Express server khong can cluster. Force fork mode de --env-file work.
      exec_mode: 'fork',
      instances: 1,
      env: { NODE_ENV: 'production' },
      max_memory_restart: '400M',
    },
    {
      name: 'eoffice-web',
      cwd: './frontend',
      // Windows: KHONG dung 'node_modules/.bin/next' (bash script -> Node parse fail).
      // Dung entry point JS that cua next CLI.
      script: 'node_modules/next/dist/bin/next',
      args: 'start',
      exec_mode: 'fork',
      instances: 1,
      env: { NODE_ENV: 'production', PORT: 3000 },
      max_memory_restart: '400M',
    },
    {
      // BullMQ consumer: LGSP send/receive/status workers + email/SMS workers.
      // Backend chi PRODUCE jobs vao Redis queue, workers consume va execute.
      // KHONG co process nay -> queue tich luy, VB khong gui/nhan duoc qua truc.
      name: 'eoffice-workers',
      cwd: './workers',
      script: 'dist/index.js',
      node_args: '--env-file=.env',
      exec_mode: 'fork',
      instances: 1,
      env: { NODE_ENV: 'production' },
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
Write-Host "  Sau do truy cap: http://$DOMAIN  (hoac http://$SERVER_IP)"
Write-Host ''
Write-Host '  Quan ly:'
Write-Host '    pm2 status         - xem trang thai'
Write-Host '    pm2 logs           - xem logs'
Write-Host '    pm2 restart all    - restart'
Write-Host ''
Write-Host "  JWT_SECRET: $JWT_SECRET"
Write-Host ''
Write-Host '============================================' -ForegroundColor Green
