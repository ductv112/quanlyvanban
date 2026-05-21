# ============================================================================
# Test LOCAL LGSP UI v3.2 - smoke + inject fake data cho UI test
# ----------------------------------------------------------------------------
# Muc dich: Test UI moi cua v3.2 (3 admin page + Tag LGSP + Timeline + retry
#           button + badge VB di) MA KHONG CAN LGSP sandbox active.
#
# Script lam:
#  1. Pre-flight: check docker services (postgres/redis/minio) + backend port 4000
#  2. Inject SQL fake data: 1 VB den source_type=external_lgsp + 4 outbox events
#     + 1 lgsp_tracking error cho VB di test (neu co outgoing_doc san)
#  3. Print test checklist + URL + login info
#
# Usage:
#   .\deploy\test-local-lgsp-ui.ps1            # inject data + print checklist
#   .\deploy\test-local-lgsp-ui.ps1 -Cleanup   # xoa fake data sau khi test xong
#   .\deploy\test-local-lgsp-ui.ps1 -SkipPreflight   # bo qua check docker/backend
#
# Pre-req: docker compose up (postgres/redis/minio) + backend dev mode chay
#          (frontend optional - chi can khi mo browser test)
# ============================================================================

[CmdletBinding()]
param(
    [switch]$Cleanup,
    [switch]$SkipPreflight
)

$ErrorActionPreference = 'Stop'
$ROOT = Split-Path -Parent $PSScriptRoot

function Log {
    param([string]$msg, [string]$color = 'Cyan')
    Write-Host "[test-local-ui] $msg" -ForegroundColor $color
}

function Section {
    param([string]$title)
    Write-Host ''
    Write-Host '=================================================================' -ForegroundColor Yellow
    Write-Host " $title" -ForegroundColor Yellow
    Write-Host '=================================================================' -ForegroundColor Yellow
}

# Sentinel notation de detect/cleanup fake data
$SENTINEL = 'TEST-LGSP-UI-LOCAL'

# ---------------------------------------------------------------------------
# Pre-flight: check docker services + backend reachable
# ---------------------------------------------------------------------------
function Test-Preflight {
    Section 'PRE-FLIGHT CHECK'

    $pgRunning = docker ps --format '{{.Names}}' 2>$null | Select-String -Pattern '^qlvb_postgres$'
    if (-not $pgRunning) {
        Log 'qlvb_postgres KHONG chay. Chay lenh: docker compose -f e_office_app_new/docker-compose.yml up -d' 'Red'
        exit 1
    }
    Log 'docker qlvb_postgres OK' 'Green'

    $redisRunning = docker ps --format '{{.Names}}' 2>$null | Select-String -Pattern '^qlvb_redis$'
    if (-not $redisRunning) {
        Log 'qlvb_redis KHONG chay (worker se khong pickup job - chap nhan duoc cho UI test)' 'Yellow'
    } else {
        Log 'docker qlvb_redis OK' 'Green'
    }

    $minioRunning = docker ps --format '{{.Names}}' 2>$null | Select-String -Pattern '^qlvb_minio$'
    if (-not $minioRunning) {
        Log 'qlvb_minio KHONG chay (download attachment se loi - chap nhan duoc cho UI test khong co attachment)' 'Yellow'
    } else {
        Log 'docker qlvb_minio OK' 'Green'
    }

    try {
        $health = Invoke-WebRequest -Uri 'http://localhost:4000/api/health' -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        if ($health.StatusCode -eq 200) {
            Log 'backend port 4000 OK' 'Green'
        } else {
            Log "backend tra status $($health.StatusCode) - kiem tra log" 'Yellow'
        }
    } catch {
        Log 'backend KHONG reachable port 4000. Chay lenh: cd e_office_app_new/backend; npm run dev' 'Red'
        exit 1
    }

    try {
        $null = Invoke-WebRequest -Uri 'http://localhost:3000' -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
        Log 'frontend port 3000 OK' 'Green'
    } catch {
        Log 'frontend port 3000 chua chay (chua bat buoc). Start: cd e_office_app_new/frontend; npm run dev' 'Yellow'
    }
}

# ---------------------------------------------------------------------------
# Cleanup fake data
# ---------------------------------------------------------------------------
function Invoke-Cleanup {
    Section 'CLEANUP FAKE DATA'

    $sql = @"
DELETE FROM edoc.lgsp_status_outbox
WHERE incoming_doc_id IN (SELECT id FROM edoc.incoming_docs WHERE notation = '$SENTINEL');

DELETE FROM edoc.lgsp_tracking WHERE error_message LIKE '$SENTINEL%';

DELETE FROM edoc.incoming_docs WHERE notation = '$SENTINEL';

SELECT 'Cleanup done' AS status;
"@

    $tmp = Join-Path $env:TEMP "test-local-cleanup-$([guid]::NewGuid().ToString().Substring(0,8)).sql"
    $sql | Out-File -FilePath $tmp -Encoding utf8 -NoNewline

    try {
        $output = Get-Content $tmp -Raw | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 -f - 2>&1
        Log 'Da xoa fake data:' 'Green'
        Write-Host ($output -join "`n")
    } finally {
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Inject fake data
# ---------------------------------------------------------------------------
function Invoke-InjectData {
    Section 'INJECT FAKE DATA'

    Log "Sentinel notation = $SENTINEL (re-run safe, se SKIP neu da co)" 'Cyan'

    $sql = @"
WITH root_unit AS (
    SELECT id FROM public.departments WHERE parent_id IS NULL ORDER BY id LIMIT 1
),
existing AS (
    SELECT id FROM edoc.incoming_docs WHERE notation = '$SENTINEL'
)
SELECT
    CASE
        WHEN EXISTS (SELECT 1 FROM existing) THEN 'SKIP - test data already exists, id = ' || (SELECT id FROM existing)::text
        ELSE 'INSERT - will create new test data'
    END AS action,
    (SELECT id FROM root_unit) AS root_unit_id;

INSERT INTO edoc.incoming_docs (
    unit_id, department_id, received_date, "number", notation, document_code,
    abstract, signer, sign_date, publish_unit, publish_date,
    secret_id, urgent_id, number_paper, number_copies, created_by,
    source_type, external_doc_id, lgsp_sender_org_code,
    is_unit_send, unit_send, extra_fields
)
SELECT
    (SELECT id FROM public.departments WHERE parent_id IS NULL ORDER BY id LIMIT 1),
    (SELECT id FROM public.departments WHERE parent_id IS NULL ORDER BY id LIMIT 1),
    NOW(), 99001, '$SENTINEL', 'TEST/2026/UI',
    'Van ban test gia lap LGSP - chi de test UI v3.2',
    'Nguyen Test Signer', NOW() - INTERVAL '1 day', 'Co quan ngoai LGSP (test)', NOW() - INTERVAL '1 day',
    1, 1, 1, 1, 1,
    'external_lgsp', 'test-uuid-local-001', 'H37.SO.001',
    TRUE, 'Co quan ngoai LGSP (test)',
    '{"message_header":{"From":{"OrganizationId":"H37.SO.001","OrganizationName":"Co quan ngoai LGSP (test)"},"To":{"OrganizationId":"H37.DN.001","OrganizationName":"DN test"},"Subject":"Van ban test gia lap","DocumentId":"test-uuid-local-001"},"edxml_raw":"<EdXML><MessageHeader>test snippet</MessageHeader></EdXML>"}'::jsonb
WHERE NOT EXISTS (SELECT 1 FROM edoc.incoming_docs WHERE notation = '$SENTINEL')
RETURNING id AS doc_id;

CREATE TEMP TABLE _test_doc AS
SELECT id FROM edoc.incoming_docs WHERE notation = '$SENTINEL' LIMIT 1;

INSERT INTO edoc.lgsp_status_outbox (incoming_doc_id, target_status, payload, sent_status, sent_at, retry_count, created_at)
SELECT id, '01', '{"lgsp_doc_id":"test-uuid-local-001","sender_org_code":"H37.SO.001"}'::jsonb, 'success', NOW() - INTERVAL '2 hour', 0, NOW() - INTERVAL '2 hour' FROM _test_doc
ON CONFLICT (incoming_doc_id, target_status) DO NOTHING;

INSERT INTO edoc.lgsp_status_outbox (incoming_doc_id, target_status, payload, sent_status, sent_at, retry_count, created_at)
SELECT id, '03', '{"lgsp_doc_id":"test-uuid-local-001","sender_org_code":"H37.SO.001"}'::jsonb, 'success', NOW() - INTERVAL '1 hour', 0, NOW() - INTERVAL '1 hour' FROM _test_doc
ON CONFLICT (incoming_doc_id, target_status) DO NOTHING;

INSERT INTO edoc.lgsp_status_outbox (incoming_doc_id, target_status, payload, sent_status, sent_at, retry_count, created_at)
SELECT id, '04', '{"lgsp_doc_id":"test-uuid-local-001","sender_org_code":"H37.SO.001"}'::jsonb, 'pending', NULL, 0, NOW() - INTERVAL '30 min' FROM _test_doc
ON CONFLICT (incoming_doc_id, target_status) DO NOTHING;

INSERT INTO edoc.lgsp_status_outbox (incoming_doc_id, target_status, payload, sent_status, sent_at, retry_count, error_message, next_retry_at, created_at)
SELECT id, '05', '{"lgsp_doc_id":"test-uuid-local-001","sender_org_code":"H37.SO.001"}'::jsonb, 'error', NOW() - INTERVAL '5 min', 5, '${SENTINEL}: Retry exhausted: HTTP 401 Unauthorized (Sai SystemId hoac SecretKey - ma loi 15)', NULL, NOW() - INTERVAL '10 min' FROM _test_doc
ON CONFLICT (incoming_doc_id, target_status) DO NOTHING;

INSERT INTO edoc.lgsp_tracking (outgoing_doc_id, direction, status, dest_org_code, dest_org_name, error_message, sent_at, created_by, created_at)
SELECT
    (SELECT id FROM edoc.outgoing_docs ORDER BY id DESC LIMIT 1),
    'send', 'error', 'H37.SO.001', 'Co quan ngoai LGSP (test)',
    '${SENTINEL}: HTTP 401 Sai SystemId hoac SecretKey (ma loi 15)',
    NOW() - INTERVAL '15 min', 1, NOW() - INTERVAL '15 min'
WHERE EXISTS (SELECT 1 FROM edoc.outgoing_docs)
  AND NOT EXISTS (SELECT 1 FROM edoc.lgsp_tracking WHERE error_message LIKE '$SENTINEL%');

SELECT
    'Test VB den ID' AS info, id::text AS value FROM edoc.incoming_docs WHERE notation = '$SENTINEL'
UNION ALL
SELECT 'Outbox events count', count(*)::text FROM edoc.lgsp_status_outbox WHERE incoming_doc_id IN (SELECT id FROM edoc.incoming_docs WHERE notation = '$SENTINEL')
UNION ALL
SELECT 'LGSP tracking error count', count(*)::text FROM edoc.lgsp_tracking WHERE error_message LIKE '$SENTINEL%'
UNION ALL
SELECT 'Test outgoing_doc ID (cho badge VB di test)', COALESCE((SELECT outgoing_doc_id::text FROM edoc.lgsp_tracking WHERE error_message LIKE '$SENTINEL%' LIMIT 1), 'N/A - chua co outgoing_doc nao trong DB');
"@

    $tmp = Join-Path $env:TEMP "test-local-inject-$([guid]::NewGuid().ToString().Substring(0,8)).sql"
    $sql | Out-File -FilePath $tmp -Encoding utf8 -NoNewline

    try {
        Log 'Dang inject fake data...' 'Cyan'
        $output = Get-Content $tmp -Raw | docker exec -i qlvb_postgres psql -U qlvb_admin -d qlvb_dev -v ON_ERROR_STOP=1 -f - 2>&1
        Write-Host ($output -join "`n")

        if ($LASTEXITCODE -ne 0) {
            Log "psql exit code = $LASTEXITCODE - co loi" 'Red'
            exit 1
        }
        Log 'Inject fake data OK' 'Green'
    } finally {
        Remove-Item $tmp -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Print test checklist
# ---------------------------------------------------------------------------
function Show-Checklist {
    Section 'TEST CHECKLIST - UI v3.2 LGSP'

    $checklist = @'

LOGIN INFO:
- Admin (full quyen):   admin / Admin@123
- User thuong (test permission gate):  nguyenvana / Admin@123

URL chinh:
- Frontend dashboard:   http://localhost:3000
- Backend API health:   http://localhost:4000/api/health

=================================================================
A. ADMIN UI 3 PAGE MOI (login admin)
=================================================================

  [ ] 1. Sidebar group "TICH HOP" hien 3 menu:
        - /lgsp Lien thong LGSP (everyone)
        - /lgsp/co-quan Co quan ngoai (admin)
        - /lgsp/cau-hinh Cau hinh ket noi (admin only)

  [ ] 2. Page /lgsp Dashboard:
        - 5 stat cards (Gui hom nay / Nhan hom nay / Callback success/pending/error)
        - 6 DN cards grid voi badge "Chua kich hoat"
        - Button "Dong bo ngay" (admin only)
        - Quick links

  [ ] 3. Page /lgsp/co-quan:
        - List inter_organizations
        - Filter dropdown "Tat ca / Da xac nhan / Tu dang ky"
        - Search code/name
        - "+ Them co quan" -> Drawer 720 form Vietnamese co dau
        - Edit + Popconfirm Delete
        - Button "Dong bo tu LGSP" -> Modal confirm (se error vi chua DN active)

  [ ] 4. Page /lgsp/cau-hinh (admin only):
        - Load 12 row credential (6 DN x 2 env), all is_active=false default
        - Mat khau "***" masked
        - Click "Sua" -> Drawer 720 voi form system_id/base_url/secret_key
        - Click "Test" -> Modal spinner -> Error 401 expected (credential rotation)
        - Toggle is_active=true -> Modal confirm "Ban co chac kich hoat..."

=================================================================
B. PERMISSION TEST (logout admin, login nguyenvana)
=================================================================

  [ ] 5. Sidebar KHONG thay menu /lgsp/cau-hinh
  [ ] 6. Vao truc tiep URL /lgsp/cau-hinh -> Alert "Chi danh cho Quan tri he thong"
  [ ] 7. Vao /lgsp dashboard -> KHONG co button "Dong bo ngay"
  [ ] 8. Vao /lgsp/co-quan -> KHONG co buttons CRUD (chi xem list)

=================================================================
C. FRONTEND TAG LGSP (su dung fake data da inject)
=================================================================

  [ ] 9. Tab "Van ban den":
        - Row notation=TEST-LGSP-UI-LOCAL co Tag XANH "LGSP"
        - Hover tag -> tooltip "Co quan ngoai LGSP (test) (H37.SO.001)"
        - Filter dropdown "Nguon" -> chon "LGSP" -> chi thay row test

  [ ] 10. Click vao row TEST-LGSP-UI-LOCAL -> detail page:
        - Section "Nguon LGSP" hien external_doc_id + lgsp_sender_org_code
        - Collapse "MessageHeader JSON raw" -> click expand -> hien JSON formatted

=================================================================
D. TIMELINE LICH SU TRANG THAI LGSP (su dung fake outbox da inject)
=================================================================

  [ ] 11. Trong detail page VB den TEST-LGSP-UI-LOCAL, section "Lich su trang thai LGSP":
        Timeline 4 entries (theo thu tu thoi gian):
        - "Da gui" (green check) - 2 gio truoc
        - "Tiep nhan" (green check) - 1 gio truoc
        - "Phan cong" (gray spinner "Dang cho gui LGSP...") - 30 phut truoc
        - "Dang xu ly" (red Tag "Loi (retry 5)" + Tooltip error message)

  [ ] 12. Click button "Gui lai" tren entry "Dang xu ly" (admin only):
        - Toast success "Da reset, se gui lai trong 30s"
        - Polling 10s tu refresh

=================================================================
E. BADGE PER RECIPIENT VB DI (neu da inject lgsp_tracking error)
=================================================================

  [ ] 13. Vao outgoing_doc co lgsp_tracking error (xem ID o output script):
        - Recipient external_org co badge DO "Loi LGSP: TEST-LGSP-UI-LOCAL..."
        - Tooltip hien full error message
        - Button "Gui lai" (admin only) -> Popconfirm -> reset tracking

=================================================================
F. TEST CONNECTION REAL (can internet)
=================================================================

  [ ] 14. /lgsp/cau-hinh -> click "Test" tren DN.001 sandbox:
        - Modal spinner "Dang test ket noi..."
        - Sau 2-5s -> ket qua:
          * Neu sandbox active credential dung: green "Ket noi thanh cong"
          * Neu credential rotation: red "HTTP 401" (DUNG - dung UI flow)
          * Neu network fail: red "HTTP 0" + message

=================================================================
CLEANUP SAU KHI TEST XONG:
=================================================================

  .\deploy\test-local-lgsp-ui.ps1 -Cleanup

'@
    Write-Host $checklist -ForegroundColor White
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
Set-Location $ROOT

if ($Cleanup) {
    Invoke-Cleanup
    Log 'Done. Fake data da xoa. Run lai script de inject lai.' 'Green'
    exit 0
}

if (-not $SkipPreflight) {
    Test-Preflight
}

Invoke-InjectData
Show-Checklist

Log 'Done. Mo browser va lam theo checklist phia tren.' 'Green'
