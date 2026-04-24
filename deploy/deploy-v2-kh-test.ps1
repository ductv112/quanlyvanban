# ============================================================
# e-Office v2 - Deploy fresh cho KH Test
# Muc dich: Pull code v2 moi nhat + rebuild PRODUCTION + reset DB sach
#           + clear Redis/MinIO + seed day du (001 + 002 demo) + verify.
#
# [!!] CANH BAO: Xoa TOAN BO data trong qlvb_prod + toan bo Redis cache
#                + toan bo MinIO uploads. KHONG dung cho production that.
#
# Chay: PowerShell Administrator:
#   .\deploy-v2-kh-test.ps1
#
# Hoac tu dong (skip confirm):
#   .\deploy-v2-kh-test.ps1 -Force
# ============================================================

param(
    [switch]$Force   # Skip moi confirm prompt
)

$ErrorActionPreference = 'Continue'
$ScriptStart = Get-Date

# -- Config ---------------------------------------------------
$APP_DIR    = 'C:\qlvb\quanlyvanban'
$WORK_DIR   = Join-Path $APP_DIR 'e_office_app_new'
$DEPLOY_DIR = Join-Path $APP_DIR 'deploy'
$psqlExe    = 'C:\PostgreSQL\16\bin\psql.exe'
$PG_DB      = 'qlvb_prod'
$PG_USER    = 'qlvb_admin'
$PG_PASS    = 'QlvbProd2026'

$PROD_URL       = 'http://103.97.134.87'
$BACKEND_HEALTH = 'http://localhost:4000/api/health'
$FRONTEND_URL   = $PROD_URL

# -- Helpers --------------------------------------------------
function Log  ($m) { Write-Host "[OK] $m" -ForegroundColor Green }
function Step ($m) { $sec = [int]((Get-Date) - $ScriptStart).TotalSeconds; Write-Host "`n[${sec}s] $m" -ForegroundColor Cyan }
function Warn ($m) { Write-Host "[!!] $m" -ForegroundColor Yellow }
function Err  ($m) { Write-Host "[XX] $m" -ForegroundColor Red; exit 1 }

# -- Precheck -------------------------------------------------
Step 'Precheck'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Err 'Can chay PowerShell voi quyen Administrator'
}
Log 'Administrator'

if (-not (Test-Path $APP_DIR))  { Err "Khong tim thay APP_DIR: $APP_DIR" }
if (-not (Test-Path $WORK_DIR)) { Err "Khong tim thay WORK_DIR: $WORK_DIR" }
if (-not (Test-Path $psqlExe))  { Err "Khong tim thay psql.exe: $psqlExe" }
Log 'Paths OK'

# -- Confirm --------------------------------------------------
if (-not $Force) {
    Write-Host ''
    Write-Host '================================================================' -ForegroundColor Red
    Write-Host '  [!!] DEPLOY V2 - KH TEST' -ForegroundColor Red
    Write-Host '       - Pull code v2 + rebuild PRODUCTION' -ForegroundColor Red
    Write-Host '       - Xoa sach qlvb_prod DB + seed lai (001 + 002 demo)' -ForegroundColor Red
    Write-Host '       - Clear Redis (FLUSHALL) + MinIO (all objects trong bucket)' -ForegroundColor Red
    Write-Host '       - Restart pm2' -ForegroundColor Red
    Write-Host '================================================================' -ForegroundColor Red
    Write-Host ''
    $c = Read-Host "Xac nhan? Go 'yes' de tiep tuc"
    if ($c -ne 'yes') { Write-Host 'Da huy.'; exit 0 }
}

# -- 1. Stop pm2 services ------------------------------------
Step '1. Stop pm2 services (tranh ket noi DB khi reset)'
pm2 stop all 2>$null | Out-Null
Log 'pm2 stopped'

# -- 2. Pull code v2 -----------------------------------------
Step '2. Pull code v2 tu git'
Set-Location $APP_DIR
git fetch --all -q
if ($LASTEXITCODE -ne 0) { Err 'git fetch that bai' }
git reset --hard origin/main -q
if ($LASTEXITCODE -ne 0) { Err 'git reset that bai' }
$headSha = (git rev-parse --short HEAD).Trim()
$headMsg = (git log -1 --pretty=format:"%s").Trim()
Log "HEAD: $headSha $headMsg"

# -- 3. Build Backend PRODUCTION -----------------------------
Step '3. Build Backend PRODUCTION (npm ci + build)'
Set-Location "$WORK_DIR\backend"
# QUAN TRONG: npm install/ci KHONG dung --omit=dev vi can 'typescript' (devDep)
# de compile tsc -> dist/. NODE_ENV=production chi set khi CHAY app, khong set
# khi install (NODE_ENV=production + npm install = skip devDependencies).
$env:NODE_ENV = 'development'

Log '  -> npm ci (clean install, full deps including dev)...'
npm ci 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Warn '  npm ci fail, fallback npm install (full)'
    npm install 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Err 'Backend npm install that bai' }
}

# Verify tsc present
if (-not (Test-Path "$WORK_DIR\backend\node_modules\.bin\tsc.cmd") -and -not (Test-Path "$WORK_DIR\backend\node_modules\typescript\bin\tsc")) {
    Err 'typescript khong co trong node_modules - npm install chua install devDependencies. Kiem tra .npmrc / NODE_ENV.'
}

Log '  -> npm run build (tsc -> dist/)...'
$buildLog = Join-Path $env:TEMP 'qlvb_backend_build.log'
npm run build > $buildLog 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '---- Backend build output (cuoi file) ----' -ForegroundColor Yellow
    Get-Content $buildLog -Tail 50
    Write-Host "---- Full log: $buildLog ----" -ForegroundColor Yellow
    Err 'Backend build that bai - xem log phia tren'
}
Remove-Item $buildLog -ErrorAction SilentlyContinue
if (-not (Test-Path "$WORK_DIR\backend\dist\server.js")) { Err 'Backend dist/server.js khong ton tai sau build' }
Log 'Backend built'

# -- 4. Build Frontend PRODUCTION ----------------------------
Step '4. Build Frontend PRODUCTION (Next.js build 3-5 phut)'
Set-Location "$WORK_DIR\frontend"
# Next.js build can devDeps (next CLI chi co neu full install). NODE_ENV=production
# KHONG duoc set luc install.
$env:NODE_ENV = 'development'

Log '  -> npm ci (full deps)...'
npm ci 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Warn '  npm ci fail, fallback npm install (full)'
    npm install 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Err 'Frontend npm install that bai' }
}

# Verify next CLI present
if (-not (Test-Path "$WORK_DIR\frontend\node_modules\.bin\next.cmd") -and -not (Test-Path "$WORK_DIR\frontend\node_modules\next\dist\bin\next")) {
    Err 'next CLI khong co trong node_modules - npm install chua install day du.'
}

# Switch sang production cho qua trinh build (Next.js read NODE_ENV)
$env:NODE_ENV = 'production'

Log '  -> npm run build (Next.js production)...'
$feBuildLog = Join-Path $env:TEMP 'qlvb_frontend_build.log'
npm run build > $feBuildLog 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host '---- Frontend build output (cuoi file) ----' -ForegroundColor Yellow
    Get-Content $feBuildLog -Tail 60
    Write-Host "---- Full log: $feBuildLog ----" -ForegroundColor Yellow
    Err 'Frontend build that bai - xem log phia tren'
}
Remove-Item $feBuildLog -ErrorAction SilentlyContinue
if (-not (Test-Path "$WORK_DIR\frontend\.next\BUILD_ID")) { Err 'Frontend .next/BUILD_ID khong ton tai sau build' }
Log 'Frontend built'

# -- 5. Load .env backend de doc config Redis/MinIO ----------
Step '5. Load backend/.env'
$envFile = "$WORK_DIR\backend\.env"
if (-not (Test-Path $envFile)) { Err "Khong tim thay $envFile" }

$envMap = @{}
Get-Content $envFile | ForEach-Object {
    $line = $_
    if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$') {
        $key = $matches[1]
        $val = $matches[2]
        if ($val.StartsWith('"') -and $val.EndsWith('"')) { $val = $val.Substring(1, $val.Length - 2) }
        elseif ($val.StartsWith("'") -and $val.EndsWith("'")) { $val = $val.Substring(1, $val.Length - 2) }
        $envMap[$key] = $val
    }
}
Log "Loaded $($envMap.Count) env vars"

# -- 6. Clear Redis (FLUSHALL) -------------------------------
Step '6. Clear Redis (FLUSHALL)'
$redisUrl = $envMap['REDIS_URL']
$redisHost = $envMap['REDIS_HOST']
$redisPort = $envMap['REDIS_PORT']
$redisPass = $envMap['REDIS_PASSWORD']
if (-not $redisUrl -and $redisHost) {
    # Build REDIS_URL tu host/port/password (fallback legacy config)
    $pw = ''
    if ($redisPass) { $pw = ":$redisPass@" }
    $pt = '6379'
    if ($redisPort) { $pt = $redisPort }
    $redisUrl = "redis://$pw$redisHost`:$pt"
    Log "  Built REDIS_URL tu REDIS_HOST/PORT"
}
if (-not $redisUrl) {
    Warn 'REDIS config khong co trong .env (REDIS_URL / REDIS_HOST) - skip Redis clear'
} else {
    Set-Location "$WORK_DIR\backend"
    $env:REDIS_URL = $redisUrl

    # QUAN TRONG: script file PHAI nam trong backend dir de Node resolve node_modules
    $redisScript = Join-Path "$WORK_DIR\backend" '_qlvb_redis_flush.js'
    @'
const { Redis } = require('ioredis');
const r = new Redis(process.env.REDIS_URL, { maxRetriesPerRequest: 3, lazyConnect: true });
(async () => {
  try {
    await r.connect();
    await r.flushall();
    console.log('Redis FLUSHALL OK');
    r.disconnect();
    process.exit(0);
  } catch (e) {
    console.error('Redis error:', e.message);
    process.exit(1);
  }
})();
'@ | Out-File -FilePath $redisScript -Encoding ASCII

    node $redisScript
    $redisRc = $LASTEXITCODE
    Remove-Item $redisScript -ErrorAction SilentlyContinue
    if ($redisRc -ne 0) { Warn 'Redis clear fail - kiem tra thu cong sau deploy' }
    else { Log 'Redis cleared' }
}

# -- 7. Clear MinIO ------------------------------------------
Step '7. Clear MinIO (all objects trong bucket documents)'
$minioEndpoint = $envMap['MINIO_ENDPOINT']
$minioAK = $envMap['MINIO_ACCESS_KEY']
$minioSK = $envMap['MINIO_SECRET_KEY']
$minioBucket = $envMap['MINIO_BUCKET']
if (-not $minioBucket) { $minioBucket = 'documents' }

if (-not $minioEndpoint -or -not $minioAK -or -not $minioSK) {
    Warn 'MinIO config thieu trong .env - skip MinIO clear'
} else {
    Set-Location "$WORK_DIR\backend"
    $env:MINIO_ENDPOINT   = $minioEndpoint
    $env:MINIO_ACCESS_KEY = $minioAK
    $env:MINIO_SECRET_KEY = $minioSK
    $env:MINIO_BUCKET     = $minioBucket

    # QUAN TRONG: script file PHAI nam trong backend dir de Node resolve node_modules
    $minioScript = Join-Path "$WORK_DIR\backend" '_qlvb_minio_clear.js'
    @'
const Minio = require('minio');
const u = new URL(process.env.MINIO_ENDPOINT);
const mc = new Minio.Client({
  endPoint: u.hostname,
  port: Number(u.port || (u.protocol === 'https:' ? 443 : 9000)),
  useSSL: u.protocol === 'https:',
  accessKey: process.env.MINIO_ACCESS_KEY,
  secretKey: process.env.MINIO_SECRET_KEY,
});
const bucket = process.env.MINIO_BUCKET;
(async () => {
  try {
    const exists = await mc.bucketExists(bucket);
    if (!exists) { console.log('Bucket khong ton tai, skip:', bucket); process.exit(0); }
    const objects = [];
    const stream = mc.listObjectsV2(bucket, '', true);
    await new Promise((resolve, reject) => {
      stream.on('data', o => objects.push(o.name));
      stream.on('end', resolve);
      stream.on('error', reject);
    });
    if (objects.length === 0) { console.log('Bucket empty, OK'); process.exit(0); }
    await mc.removeObjects(bucket, objects);
    console.log('MinIO cleared', objects.length, 'objects');
    process.exit(0);
  } catch (e) {
    console.error('MinIO error:', e.message);
    process.exit(1);
  }
})();
'@ | Out-File -FilePath $minioScript -Encoding ASCII

    node $minioScript
    $minioRc = $LASTEXITCODE
    Remove-Item $minioScript -ErrorAction SilentlyContinue
    if ($minioRc -ne 0) { Warn 'MinIO clear fail - kiem tra thu cong sau deploy' }
    else { Log 'MinIO cleared' }
}

# -- 8. Reset DB + seed 001 + 002 ----------------------------
Step '8. Reset DB + seed 001 + 002 (full demo data)'
$resetScript = Join-Path $DEPLOY_DIR 'reset-db-windows.ps1'
if (-not (Test-Path $resetScript)) { Err "Khong tim thay $resetScript" }

& powershell -ExecutionPolicy Bypass -File $resetScript -Force
if ($LASTEXITCODE -ne 0) { Err 'reset-db-windows.ps1 that bai' }
Log 'DB reset + seed OK'

# -- 9. Start pm2 services -----------------------------------
Step '9. Start pm2 services'
Set-Location $WORK_DIR
pm2 restart all 2>$null | Out-Null
Start-Sleep -Seconds 5
pm2 status
Log 'pm2 restarted'

# -- 10. Verify ----------------------------------------------
Step '10. Verify deployment'

Log "  -> Check backend health: $BACKEND_HEALTH"
try {
    $h = Invoke-WebRequest -Uri $BACKEND_HEALTH -TimeoutSec 10 -UseBasicParsing
    if ($h.StatusCode -eq 200) { Log '    Backend healthy' }
    else { Warn "    Backend status $($h.StatusCode)" }
} catch { Warn "    Backend unreachable: $($_.Exception.Message)" }

Log "  -> Check frontend: $FRONTEND_URL"
try {
    $f = Invoke-WebRequest -Uri $FRONTEND_URL -TimeoutSec 15 -UseBasicParsing
    if ($f.StatusCode -eq 200) { Log '    Frontend reachable' }
    else { Warn "    Frontend status $($f.StatusCode)" }
} catch { Warn "    Frontend unreachable: $($_.Exception.Message)" }

Log '  -> Test login admin (qua backend local)'
try {
    $body = @{ username = 'admin'; password = 'Admin@123' } | ConvertTo-Json -Compress
    $login = Invoke-WebRequest -Uri 'http://localhost:4000/api/auth/login' -Method POST -ContentType 'application/json' -Body $body -TimeoutSec 10 -UseBasicParsing
    $loginData = $login.Content | ConvertFrom-Json
    if ($loginData.data.accessToken) { Log '    Login admin OK (accessToken received)' }
    else { Warn "    Login response khong co accessToken: $($login.Content)" }
} catch { Warn "    Login that bai: $($_.Exception.Message)" }

# -- Summary -------------------------------------------------
$duration = [int]((Get-Date) - $ScriptStart).TotalSeconds
Write-Host ''
Write-Host '================================================================' -ForegroundColor Green
Write-Host "  DEPLOY V2 HOAN THANH sau $duration giay" -ForegroundColor Green
Write-Host '================================================================' -ForegroundColor Green
Write-Host ''
Write-Host "  URL:     $PROD_URL" -ForegroundColor Cyan
Write-Host '  Admin:   admin / Admin@123' -ForegroundColor Cyan
Write-Host '  Demo:    nguyenvana / Admin@123  (So Noi vu)' -ForegroundColor Cyan
Write-Host '           tranthib   / Admin@123  (So Tai chinh)' -ForegroundColor Cyan
Write-Host '           levand     / Admin@123  (So TT-TT)' -ForegroundColor Cyan
Write-Host '           phamvane   / Admin@123  (VP UBND)' -ForegroundColor Cyan
Write-Host ''
Write-Host "  Git HEAD: $headSha $headMsg" -ForegroundColor DarkGray
Write-Host ''
