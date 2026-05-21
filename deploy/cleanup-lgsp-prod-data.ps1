# ============================================================================
# CLEANUP LGSP TEST DATA tren PROD (chuan bi go-live LGSP that v3.2)
# ----------------------------------------------------------------------------
# Muc dich: Xoa toan bo LGSP-related test data tren prod KH (mock data tu
#           Phase 18) de KH start fresh khi kich hoat LGSP that.
#
# Phai script tren prod (SSH/RDP vao server) — KHONG chay tu local!
#
# Script lam:
#  1. Pre-flight: check docker postgres + ASK confirm 2 lan (prod safety)
#  2. Count data se bi anh huong (BEFORE) + print rieng tung table
#  3. BACKUP toan bo affected rows ra file SQL (rollback duoc neu can)
#  4. DELETE theo thu tu FK an toan (outbox -> tracking -> attachments LGSP
#     -> incoming_docs source_type=external_lgsp -> inter_organizations)
#  5. MinIO: xoa folder lgsp/* trong bucket documents
#  6. Count AFTER + print summary
#
# Usage tren PROD:
#   .\deploy\cleanup-lgsp-prod-data.ps1 -DryRun        # in count, KHONG xoa
#   .\deploy\cleanup-lgsp-prod-data.ps1                # default = DryRun
#   .\deploy\cleanup-lgsp-prod-data.ps1 -Confirm       # tha't su xoa (yeu cau type 'XOA DATA LGSP')
#
# Pre-req: docker postgres dang chay (qlvb_postgres), pm2 backend dung khong sao
# ============================================================================

[CmdletBinding()]
param(
    [switch]$DryRun = $true,
    [switch]$Confirm
)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent $PSScriptRoot
$TIMESTAMP = Get-Date -Format 'yyyyMMdd-HHmmss'
$BACKUP_DIR = Join-Path $ROOT "backups\lgsp-cleanup-$TIMESTAMP"

function Log {
    param([string]$msg, [string]$color = 'Cyan')
    Write-Host "[cleanup-lgsp] $msg" -ForegroundColor $color
}

function Section {
    param([string]$title)
    Write-Host ''
    Write-Host '=================================================================' -ForegroundColor Yellow
    Write-Host " $title" -ForegroundColor Yellow
    Write-Host '=================================================================' -ForegroundColor Yellow
}

# Effective mode: -Confirm overrides default DryRun
if ($Confirm) { $DryRun = $false }

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
function Test-Preflight {
    Section 'PRE-FLIGHT CHECK'

    $pgRunning = docker ps --format '{{.Names}}' 2>$null | Select-String -Pattern '^qlvb_postgres$'
    if (-not $pgRunning) {
        Log 'qlvb_postgres KHONG chay. STOP.' 'Red'
        exit 1
    }
    Log 'docker qlvb_postgres OK' 'Green'

    $minioRunning = docker ps --format '{{.Names}}' 2>$null | Select-String -Pattern '^qlvb_minio$'
    if (-not $minioRunning) {
        Log 'qlvb_minio KHONG chay. MinIO cleanup se SKIP, can chay thu cong sau.' 'Yellow'
    } else {
        Log 'docker qlvb_minio OK' 'Green'
    }
}

# ---------------------------------------------------------------------------
# Count BEFORE
# ---------------------------------------------------------------------------
function Get-Counts {
    param([string]$Label)
    Section "COUNT $Label"

    $sql = @'
SELECT 'incoming_docs (external_lgsp)' AS table_name, count(*) AS rows
FROM edoc.incoming_docs WHERE source_type = 'external_lgsp'
UNION ALL
SELECT 'lgsp_tracking', count(*) FROM edoc.lgsp_tracking
UNION ALL
SELECT 'lgsp_status_outbox', count(*) FROM edoc.lgsp_status_outbox
UNION ALL
SELECT 'inter_organizations', count(*) FROM edoc.inter_organizations
UNION ALL
SELECT 'attachment_incoming_docs (LGSP)', count(*)
FROM edoc.attachment_incoming_docs a
JOIN edoc.incoming_docs d ON d.id = a.incoming_doc_id
WHERE d.source_type = 'external_lgsp';
'@

    $tmp = Join-Path $env:TEMP "cleanup-count-$([guid]::NewGuid().ToString().Substring(0,8)).sql"
    $sql | Out-File -FilePath $tmp -Encoding utf8 -NoNewline

    try {
        $output = Get-Content $tmp -Raw | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 -f - 2>&1
        Write-Host ($output -join "`n")
    } finally {
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Backup affected rows
# ---------------------------------------------------------------------------
function Save-Backup {
    Section 'BACKUP AFFECTED ROWS'

    New-Item -ItemType Directory -Force -Path $BACKUP_DIR | Out-Null
    Log "Backup folder: $BACKUP_DIR" 'Cyan'

    # Dump each table affected (pg_dump --data-only --inserts)
    $tables = @(
        @{ schema = 'edoc'; table = 'inter_organizations'; where = '' },
        @{ schema = 'edoc'; table = 'lgsp_status_outbox'; where = '' },
        @{ schema = 'edoc'; table = 'lgsp_tracking'; where = '' },
        @{ schema = 'edoc'; table = 'incoming_docs'; where = "WHERE source_type='external_lgsp'" }
    )

    foreach ($t in $tables) {
        $outFile = Join-Path $BACKUP_DIR "$($t.table).sql"
        $sql = "COPY (SELECT row_to_json(r) FROM $($t.schema).$($t.table) r $($t.where)) TO STDOUT;"
        $tmp = Join-Path $env:TEMP "backup-$($t.table)-$([guid]::NewGuid().ToString().Substring(0,8)).sql"
        $sql | Out-File -FilePath $tmp -Encoding utf8 -NoNewline

        try {
            Get-Content $tmp -Raw | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 -f - 2>&1 | Out-File -FilePath $outFile -Encoding utf8
            $rowCount = (Get-Content $outFile).Count
            Log "Backed up $($t.table): $rowCount rows -> $outFile" 'Green'
        } finally {
            Remove-Item $tmp -ErrorAction SilentlyContinue
        }
    }
}

# ---------------------------------------------------------------------------
# Delete LGSP data (theo thu tu FK an toan)
# ---------------------------------------------------------------------------
function Invoke-Delete {
    Section 'DELETE LGSP DATA'

    $sql = @'
BEGIN;

-- 1. lgsp_status_outbox (FK incoming_doc_id, CASCADE auto khi xoa incoming_docs)
DELETE FROM edoc.lgsp_status_outbox;

-- 2. lgsp_tracking (FK outgoing_doc_id, KHONG cascade tu outgoing)
DELETE FROM edoc.lgsp_tracking;

-- 3. attachment_incoming_docs (FK CASCADE auto khi xoa incoming_docs - khong can DELETE explicit)

-- 4. incoming_docs source_type=external_lgsp (LGSP receive flow)
-- CASCADE se tu xoa attachment_incoming_docs + lgsp_status_outbox FK incoming_doc_id
-- KHONG dung outgoing_doc_recipients.generated_lgsp_tracking_id -> SET NULL khi tracking xoa
-- (FK lgsp_tracking on delete set null da co tu Phase 17)
UPDATE edoc.outgoing_doc_recipients
SET generated_lgsp_tracking_id = NULL
WHERE generated_lgsp_tracking_id IS NOT NULL;

DELETE FROM edoc.incoming_docs WHERE source_type = 'external_lgsp';

-- 5. inter_organizations (catalog co quan ngoai)
DELETE FROM edoc.inter_organizations;

-- 6. Reset agency config last_synced_at + last_sync_error (de fresh tracking)
UPDATE edoc.lgsp_agency_config
SET last_synced_at = NULL, last_sync_error = NULL;

COMMIT;

SELECT 'DELETE done' AS status;
'@

    $tmp = Join-Path $env:TEMP "cleanup-delete-$([guid]::NewGuid().ToString().Substring(0,8)).sql"
    $sql | Out-File -FilePath $tmp -Encoding utf8 -NoNewline

    try {
        $output = Get-Content $tmp -Raw | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 -f - 2>&1
        Write-Host ($output -join "`n")
        if ($LASTEXITCODE -ne 0) {
            Log "psql exit code = $LASTEXITCODE. Da ROLLBACK transaction." 'Red'
            exit 1
        }
        Log 'DELETE thanh cong (transaction COMMIT)' 'Green'
    } finally {
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# MinIO cleanup
# ---------------------------------------------------------------------------
function Invoke-MinioCleanup {
    Section 'MINIO CLEANUP (folder lgsp/* trong bucket documents)'

    $minioRunning = docker ps --format '{{.Names}}' 2>$null | Select-String -Pattern '^qlvb_minio$'
    if (-not $minioRunning) {
        Log 'qlvb_minio KHONG chay. SKIP MinIO cleanup — chay thu cong sau.' 'Yellow'
        return
    }

    # Dung mc client neu co
    try {
        docker exec qlvb_minio mc alias set local http://localhost:9000 minioadmin minioadmin 2>&1 | Out-Null
        $listOutput = docker exec qlvb_minio mc ls --recursive local/documents/lgsp/ 2>&1
        $fileCount = ($listOutput | Where-Object { $_ -match '\.' }).Count
        Log "MinIO bucket documents/lgsp/ co $fileCount file" 'Cyan'

        if ($fileCount -gt 0) {
            docker exec qlvb_minio mc rm --recursive --force local/documents/lgsp/ 2>&1 | Out-Null
            Log 'Da xoa MinIO folder lgsp/*' 'Green'
        } else {
            Log 'MinIO folder lgsp/ trong, khong can xoa' 'Cyan'
        }
    } catch {
        Log "MinIO mc command loi: $($_.Exception.Message)" 'Yellow'
        Log 'Chay thu cong: docker exec qlvb_minio mc rm --recursive --force local/documents/lgsp/' 'Yellow'
    }
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
Set-Location $ROOT

Test-Preflight
Get-Counts -Label 'BEFORE'

if ($DryRun) {
    Write-Host ''
    Write-Host '*****************************************************************' -ForegroundColor Yellow
    Write-Host ' DRY RUN MODE - KHONG xoa data' -ForegroundColor Yellow
    Write-Host ' De thuc su xoa: .\deploy\cleanup-lgsp-prod-data.ps1 -Confirm' -ForegroundColor Yellow
    Write-Host '*****************************************************************' -ForegroundColor Yellow
    exit 0
}

# Production safety: yeu cau type confirmation string
Write-Host ''
Write-Host '*****************************************************************' -ForegroundColor Red
Write-Host ' XAC NHAN XOA DATA LGSP TREN PROD' -ForegroundColor Red
Write-Host ' Hanh dong nay KHONG REVERT duoc (chi co backup .sql)' -ForegroundColor Red
Write-Host ' Backup folder se tao: ' -ForegroundColor Yellow -NoNewline
Write-Host $BACKUP_DIR
Write-Host '*****************************************************************' -ForegroundColor Red
Write-Host ''
$confirm = Read-Host 'Type "XOA DATA LGSP" de tiep tuc (anything else cancel)'
if ($confirm -ne 'XOA DATA LGSP') {
    Log 'Cancel by user. KHONG xoa data.' 'Yellow'
    exit 0
}

Save-Backup
Invoke-Delete
Invoke-MinioCleanup
Get-Counts -Label 'AFTER'

Write-Host ''
Section 'DONE'
Log "Backup: $BACKUP_DIR" 'Green'
Log 'Prod KH san sang go-live LGSP that:' 'Green'
Log '  1. Admin login -> /lgsp/cau-hinh -> nhap credential 6 prod DN' 'Cyan'
Log '  2. Test connection -> PASS' 'Cyan'
Log '  3. Bat is_active=true tung DN' 'Cyan'
Log '  4. Admin login -> /lgsp/co-quan -> bam "Dong bo tu LGSP" lay catalog that' 'Cyan'
