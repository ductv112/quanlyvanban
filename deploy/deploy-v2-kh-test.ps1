# ============================================================
# e-Office v2 — Deploy fresh cho KH Test
# Mục đích: Pull code v2 mới nhất + rebuild PRODUCTION + reset DB sạch
#           + clear Redis/MinIO + seed đầy đủ (001 + 002 demo) + verify.
#
# [!!] CẢNH BÁO: Xoá TOÀN BỘ data trong qlvb_prod + toàn bộ Redis cache
#                + toàn bộ MinIO uploads. KHÔNG dùng cho production thật.
#
# Chạy: PowerShell Administrator:
#   .\deploy-v2-kh-test.ps1
#
# Hoặc tự động (skip confirm):
#   .\deploy-v2-kh-test.ps1 -Force
# ============================================================

param(
    [switch]$Force   # Skip mọi confirm prompt
)

$ErrorActionPreference = 'Continue'
$ScriptStart = Get-Date

# ── Config ──────────────────────────────────────────────────
$APP_DIR    = 'C:\qlvb\quanlyvanban'
$WORK_DIR   = Join-Path $APP_DIR 'e_office_app_new'
$DEPLOY_DIR = Join-Path $APP_DIR 'deploy'
$psqlExe    = 'C:\PostgreSQL\16\bin\psql.exe'
$PG_DB      = 'qlvb_prod'
$PG_USER    = 'qlvb_admin'
$PG_PASS    = 'QlvbProd2026'

$PROD_URL   = 'http://103.97.134.87'
$BACKEND_HEALTH = "${PROD_URL}:4000/api/health"   # local backend qua pm2
$FRONTEND_URL   = $PROD_URL                         # IIS reverse proxy → Next

# ── Helpers ─────────────────────────────────────────────────
function Log  ($m) { Write-Host "[OK] $m" -ForegroundColor Green }
function Step ($m) { Write-Host "`n[$([int]((Get-Date) - $ScriptStart).TotalSeconds)s] $m" -ForegroundColor Cyan }
function Warn ($m) { Write-Host "[!!] $m" -ForegroundColor Yellow }
function Err  ($m) { Write-Host "[XX] $m" -ForegroundColor Red; exit 1 }

# ── Precheck ────────────────────────────────────────────────
Step 'Precheck'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Err 'Can chay PowerShell voi quyen Administrator'
}
Log 'Administrator'

if (-not (Test-Path $APP_DIR)) { Err "Khong tim thay APP_DIR: $APP_DIR" }
if (-not (Test-Path $WORK_DIR)) { Err "Khong tim thay WORK_DIR: $WORK_DIR" }
if (-not (Test-Path $psqlExe)) { Err "Khong tim thay psql.exe: $psqlExe" }
Log 'Paths OK'

# ── Confirm ─────────────────────────────────────────────────
if (-not $Force) {
    Write-Host ''
    Write-Host '================================================================' -ForegroundColor Red
    Write-Host '  [!!] DEPLOY V2 — KH TEST' -ForegroundColor Red
    Write-Host '       - Pull code v2 + rebuild PRODUCTION' -ForegroundColor Red
    Write-Host '       - Xoa SACH qlvb_prod DB + seed lai (001 + 002 demo)' -ForegroundColor Red
    Write-Host '       - Clear Redis (FLUSHALL) + MinIO (all objects trong bucket)' -ForegroundColor Red
    Write-Host '       - Restart pm2' -ForegroundColor Red
    Write-Host '================================================================' -ForegroundColor Red
    Write-Host ''
    $c = Read-Host "Xac nhan? Go 'yes' de tiep tuc"
    if ($c -ne 'yes') { Write-Host 'Da huy.'; exit 0 }
}

# ── 1. Stop pm2 services ────────────────────────────────────
Step '1. Stop pm2 services (tranh kết nối DB khi reset)'
pm2 stop all 2>$null | Out-Null
Log 'pm2 stopped'

# ── 2. Pull code v2 ─────────────────────────────────────────
Step '2. Pull code v2 tu git'
Set-Location $APP_DIR
git fetch --all -q
if ($LASTEXITCODE -ne 0) { Err 'git fetch that bai' }
git reset --hard origin/main -q
if ($LASTEXITCODE -ne 0) { Err 'git reset that bai' }
$headSha = (git rev-parse --short HEAD).Trim()
$headMsg = (git log -1 --pretty=format:"%s").Trim()
Log "HEAD: $headSha $headMsg"

# ── 3. Build Backend PRODUCTION ─────────────────────────────
Step '3. Build Backend PRODUCTION (npm ci + build)'
Set-Location "$WORK_DIR\backend"
$env:NODE_ENV = 'production'

Log '  -> npm ci (clean install)...'
npm ci 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Warn '  npm ci fail, fallback sang npm install --omit=dev'
    npm install --omit=dev 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Err 'Backend npm install that bai' }
}

Log '  -> npm run build (tsc -> dist/)...'
npm run build 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { Err 'Backend build that bai' }
if (-not (Test-Path "$WORK_DIR\backend\dist\server.js")) { Err 'Backend dist/server.js khong ton tai sau build' }
Log 'Backend built'

# ── 4. Build Frontend PRODUCTION ────────────────────────────
Step '4. Build Frontend PRODUCTION (Next.js build 3-5 phut)'
Set-Location "$WORK_DIR\frontend"
$env:NODE_ENV = 'production'

Log '  -> npm ci...'
npm ci 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) {
    Warn '  npm ci fail, fallback npm install'
    npm install 2>$null | Out-Null
    if ($LASTEXITCODE -ne 0) { Err 'Frontend npm install that bai' }
}

Log '  -> npm run build (Next.js production)...'
npm run build 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { Err 'Frontend build that bai' }
if (-not (Test-Path "$WORK_DIR\frontend\.next\BUILD_ID")) { Err 'Frontend .next/BUILD_ID khong ton tai sau build' }
Log 'Frontend built'

# ── 5. Load .env backend de doc config Redis/MinIO ──────────
Step '5. Load backend/.env'
$envFile = "$WORK_DIR\backend\.env"
if (-not (Test-Path $envFile)) { Err "Khong tim thay $envFile" }

$envMap = @{}
Get-Content $envFile | ForEach-Object {
    if ($_ -match '^\s*([A-Z_]+)\s*=\s*(.*?)\s*$') {
        $key = $matches[1]
        $val = $matches[2].Trim('"').Trim("'")
        $envMap[$key] = $val
    }
}
Log "Loaded $($envMap.Count) env vars"

# ── 6. Clear Redis (FLUSHALL) ───────────────────────────────
Step '6. Clear Redis (FLUSHALL)'
$redisUrl = $envMap['REDIS_URL']
if (-not $redisUrl) { Warn 'REDIS_URL khong co trong .env - skip Redis clear' }
else {
    Set-Location "$WORK_DIR\backend"
    $env:REDIS_URL = $redisUrl
    $script = @'
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
'@
    $script | node
    if ($LASTEXITCODE -ne 0) { Warn 'Redis clear fail - kiem tra thu cong sau deploy' }
    else { Log 'Redis cleared' }
}

# ── 7. Clear MinIO (xoa all objects trong bucket) ───────────
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

    $script = @'
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
'@
    $script | node
    if ($LASTEXITCODE -ne 0) { Warn 'MinIO clear fail - kiem tra thu cong sau deploy' }
    else { Log 'MinIO cleared' }
}

# ── 8. Reset DB + seed 001 + 002 (goi script co san -Force) ─
Step '8. Reset DB + seed 001 + 002 (full demo data)'
$resetScript = Join-Path $DEPLOY_DIR 'reset-db-windows.ps1'
if (-not (Test-Path $resetScript)) { Err "Khong tim thay $resetScript" }

# Call reset-db-windows.ps1 -Force (skip internal confirm)
& powershell -ExecutionPolicy Bypass -File $resetScript -Force
if ($LASTEXITCODE -ne 0) { Err 'reset-db-windows.ps1 that bai' }
Log 'DB reset + seed OK'

# ── 9. Start pm2 services ───────────────────────────────────
Step '9. Start pm2 services'
Set-Location $WORK_DIR
pm2 restart all 2>$null | Out-Null
Start-Sleep -Seconds 5
pm2 status
Log 'pm2 restarted'

# ── 10. Verify ──────────────────────────────────────────────
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
    $body = @{ username = 'admin'; password = 'Admin@123' } | ConvertTo-Json
    $login = Invoke-WebRequest -Uri 'http://localhost:4000/api/auth/login' -Method POST -ContentType 'application/json' -Body $body -TimeoutSec 10 -UseBasicParsing
    $loginData = $login.Content | ConvertFrom-Json
    if ($loginData.data.accessToken) { Log '    Login admin OK (accessToken received)' }
    else { Warn "    Login response khong co accessToken: $($login.Content)" }
} catch { Warn "    Login that bai: $($_.Exception.Message)" }

# ── Summary ─────────────────────────────────────────────────
$duration = [int]((Get-Date) - $ScriptStart).TotalSeconds
Write-Host ''
Write-Host '================================================================' -ForegroundColor Green
Write-Host "  DEPLOY V2 HOAN THANH sau $duration s" -ForegroundColor Green
Write-Host '================================================================' -ForegroundColor Green
Write-Host ''
Write-Host "  URL:     $PROD_URL" -ForegroundColor Cyan
Write-Host '  Admin:   admin / Admin@123' -ForegroundColor Cyan
Write-Host '  Demo:    nguyenvana / Admin@123 (Sở Nội vụ)' -ForegroundColor Cyan
Write-Host '           tranthib   / Admin@123 (Sở Tài chính)' -ForegroundColor Cyan
Write-Host '           levand     / Admin@123 (Sở TT&TT)' -ForegroundColor Cyan
Write-Host '           phamvane   / Admin@123 (VP UBND)' -ForegroundColor Cyan
Write-Host ''
Write-Host "  Git HEAD: $headSha $headMsg" -ForegroundColor DarkGray
Write-Host ''
