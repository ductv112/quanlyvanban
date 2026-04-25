# ============================================================
# e-Office - Smoke Test HSCV (16 testcase E2E)
# Muc dich: Validate HSCV API end-to-end sau khi backend deploy
#           bao gom 5-step flow + reopen + cancel + transfer + opinion
#
# Chay: PowerShell tu root repo (backend phai dang chay port 4000):
#   .\deploy\smoke-test-hscv.ps1
#
# Hoac voi custom params:
#   .\deploy\smoke-test-hscv.ps1 -ApiUrl http://localhost:4000 -User admin -Pass 'Admin@123'
#
# Exit code:
#   0 = 16/16 PASS
#   1 = co testcase FAIL
# ============================================================

param(
    [string]$ApiUrl = 'http://localhost:4000',
    [string]$User   = 'admin',
    [string]$Pass   = 'Admin@123'
)

$ErrorActionPreference = 'Continue'
$Start = Get-Date

# -- Helpers --------------------------------------------------
$results = New-Object System.Collections.ArrayList
$createdIds = New-Object System.Collections.ArrayList
$createdOpinionIds = New-Object System.Collections.ArrayList
$logFile = Join-Path $env:TEMP "qlvb_smoke_hscv_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-Log {
    param([string]$msg)
    Add-Content -Path $logFile -Value "[$(Get-Date -Format 'HH:mm:ss')] $msg"
}

function Test-TC {
    param(
        [string]$Id,
        [string]$Name,
        [scriptblock]$Block
    )
    Write-Host -NoNewline ("  {0,-6} {1,-58}" -f $Id, $Name)
    Write-Log "BEGIN $Id $Name"
    try {
        $detail = & $Block
        if ($null -eq $detail) { $detail = 'OK' }
        $null = $results.Add([pscustomobject]@{ TC=$Id; Name=$Name; Status='PASS'; Detail=[string]$detail })
        Write-Host ' PASS' -ForegroundColor Green
        Write-Log "PASS $Id - $detail"
    } catch {
        $msg = $_.Exception.Message
        $null = $results.Add([pscustomobject]@{ TC=$Id; Name=$Name; Status='FAIL'; Detail=$msg })
        Write-Host ' FAIL' -ForegroundColor Red
        Write-Host "         -> $msg" -ForegroundColor Red
        Write-Log "FAIL $Id - $msg"
    }
}

function Invoke-Api {
    param(
        [string]$Method,
        [string]$Path,
        $Body = $null,
        [hashtable]$Headers = @{}
    )
    $url = "$ApiUrl$Path"
    $args = @{
        Uri = $url
        Method = $Method
        ContentType = 'application/json'
        UseBasicParsing = $true
        TimeoutSec = 15
    }
    if ($Headers.Count -gt 0) { $args['Headers'] = $Headers }
    if ($null -ne $Body) { $args['Body'] = ($Body | ConvertTo-Json -Compress -Depth 5) }
    Write-Log "API $Method $url body=$($args['Body'])"
    return Invoke-RestMethod @args
}

# -- Banner ---------------------------------------------------
Write-Host ''
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host '  SMOKE TEST HSCV - 16 testcase E2E' -ForegroundColor Cyan
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host "  API:  $ApiUrl"
Write-Host "  User: $User"
Write-Host "  Log:  $logFile"
Write-Host ''

# -- Shared state --------------------------------------------
$token = $null
$headers = @{}
$hscvId = $null
$hscvId2 = $null
$hscvId3 = $null
$opinionId = $null
$transferStaffId = $null
$docBookId = $null

# ============================================================
# TC1: Login
# ============================================================
Test-TC 'TC1' 'Login (POST /api/auth/login)' {
    $r = Invoke-Api -Method POST -Path '/api/auth/login' -Body @{ username = $User; password = $Pass }
    if (-not $r.success -or -not $r.data.accessToken) { throw 'Khong nhan duoc accessToken' }
    $script:token = $r.data.accessToken
    $script:headers = @{ Authorization = "Bearer $script:token" }
    "staffId=$($r.data.user.staffId) unitId=$($r.data.user.unitId)"
}

if (-not $token) {
    Write-Host ''
    Write-Host '================================================================' -ForegroundColor Red
    Write-Host '  LOGIN FAIL - khong the chay 15 TC con lai. Stop som.' -ForegroundColor Red
    Write-Host '================================================================' -ForegroundColor Red
    exit 1
}

# ============================================================
# TC2: List HSCV
# ============================================================
Test-TC 'TC2' 'GET /api/ho-so-cong-viec (list + pagination)' {
    $r = Invoke-Api -Method GET -Path '/api/ho-so-cong-viec?page=1&page_size=10' -Headers $script:headers
    if (-not $r.success) { throw 'List that bai' }
    if ($null -eq $r.pagination) { throw 'Thieu pagination object' }
    "total=$($r.pagination.total) items=$($r.data.Count)"
}

# ============================================================
# TC3: Count by status
# ============================================================
Test-TC 'TC3' 'GET /count-by-status (10 buckets)' {
    $r = Invoke-Api -Method GET -Path '/api/ho-so-cong-viec/count-by-status' -Headers $script:headers
    if (-not $r.success) { throw 'Count fail' }
    if ($r.data.Count -lt 1) { throw "Expected >= 1 bucket, got $($r.data.Count)" }
    "buckets=$($r.data.Count)"
}

# ============================================================
# TC4: Tao HSCV moi
# ============================================================
Test-TC 'TC4' 'POST tao HSCV moi (status=0)' {
    $stamp = Get-Date -Format 'HHmmss'
    $body = @{
        name       = "[SMOKE_HSCV_$stamp] Test create"
        comments   = 'Smoke test HSCV - se xoa o cuoi'
        start_date = (Get-Date -Format 'yyyy-MM-dd')
        end_date   = (Get-Date).AddDays(30).ToString('yyyy-MM-dd')
        curator_id = 1
    }
    $r = Invoke-Api -Method POST -Path '/api/ho-so-cong-viec' -Headers $script:headers -Body $body
    if (-not $r.success) { throw "Create fail: $($r.message)" }
    if (-not $r.data.id) { throw 'Khong nhan duoc id' }
    $script:hscvId = [int]$r.data.id
    $null = $script:createdIds.Add($script:hscvId)
    "id=$script:hscvId"
}

# ============================================================
# TC5: Change 0->1
# ============================================================
Test-TC 'TC5' 'PATCH /trang-thai action=change new_status=1' {
    if (-not $script:hscvId) { throw 'Skip - chua tao HSCV' }
    $r = Invoke-Api -Method PATCH -Path "/api/ho-so-cong-viec/$script:hscvId/trang-thai" `
        -Headers $script:headers -Body @{ action = 'change'; new_status = 1 }
    if (-not $r.success) { throw "Change fail: $($r.message)" }
    'ok 0->1'
}

# ============================================================
# TC6: Lay so
# ============================================================
Test-TC 'TC6' 'POST /lay-so (assign number)' {
    if (-not $script:hscvId) { throw 'Skip' }
    # Tim doc_book cua unit hien tai (admin unit_id=1, type_id=2 = So van ban di)
    if (-not $script:docBookId) {
        $out = docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -tAc "SELECT id FROM edoc.doc_books WHERE unit_id=1 AND type_id=2 ORDER BY id LIMIT 1;"
        if ($LASTEXITCODE -ne 0) { throw "Khong query duoc doc_books: $out" }
        $idStr = ($out -split "`n")[0].Trim()
        if (-not $idStr) { throw 'Khong tim thay doc_book cho unit_id=1 type_id=2' }
        $script:docBookId = [int]$idStr
    }
    $r = Invoke-Api -Method POST -Path "/api/ho-so-cong-viec/$script:hscvId/lay-so" `
        -Headers $script:headers -Body @{ doc_book_id = $script:docBookId }
    if (-not $r.success) { throw "Lay so fail: $($r.message)" }
    "number=$($r.number)"
}

# ============================================================
# TC7: Submit 1->3 (gop "Trinh ky" + "Gui trinh ky" thanh 1 step)
# ============================================================
Test-TC 'TC7' 'PATCH /trang-thai action=submit (1->3 truc tiep)' {
    if (-not $script:hscvId) { throw 'Skip' }
    $r = Invoke-Api -Method PATCH -Path "/api/ho-so-cong-viec/$script:hscvId/trang-thai" `
        -Headers $script:headers -Body @{ action = 'submit' }
    if (-not $r.success) { throw "Submit fail: $($r.message)" }
    'ok 1->3'
}

# ============================================================
# TC8: Verify status=3 sau submit (khong phai 2 nua)
# ============================================================
Test-TC 'TC8' 'GET detail xac nhan status=3 sau submit (khong qua status 2)' {
    if (-not $script:hscvId) { throw 'Skip' }
    $r = Invoke-Api -Method GET -Path "/api/ho-so-cong-viec/$script:hscvId" `
        -Headers $script:headers
    if (-not $r.success) { throw 'Get detail fail' }
    if ($r.data.status -ne 3) { throw "Expected status=3 sau submit, got $($r.data.status)" }
    'status=3 (gop 1->3)'
}

# ============================================================
# TC9: Approve 3->4 (Bug A fix verify)
# ============================================================
Test-TC 'TC9' 'PATCH /trang-thai action=approve (Bug A fix)' {
    if (-not $script:hscvId) { throw 'Skip' }
    $r = Invoke-Api -Method PATCH -Path "/api/ho-so-cong-viec/$script:hscvId/trang-thai" `
        -Headers $script:headers -Body @{ action = 'approve' }
    if (-not $r.success) { throw "Approve fail: $($r.message)" }
    'ok 3->4'
}

# ============================================================
# TC10: GET detail (verify status=4 + progress=100 + number set)
# ============================================================
Test-TC 'TC10' 'GET /:id detail (status=4 progress=100 number set)' {
    if (-not $script:hscvId) { throw 'Skip' }
    $r = Invoke-Api -Method GET -Path "/api/ho-so-cong-viec/$script:hscvId" -Headers $script:headers
    if (-not $r.success) { throw "Get detail fail: $($r.message)" }
    if ([int]$r.data.status -ne 4) { throw "Expected status=4, got $($r.data.status)" }
    if ([int]$r.data.progress -ne 100) { throw "Expected progress=100, got $($r.data.progress)" }
    if (-not $r.data.number) { throw 'Expected number set, got null' }
    "status=4 progress=100 number=$($r.data.number)"
}

# ============================================================
# TC11: Mo lai 4->1 (giu progress=100)
# ============================================================
Test-TC 'TC11' 'POST /mo-lai (4->1, progress giu 100)' {
    if (-not $script:hscvId) { throw 'Skip' }
    $r = Invoke-Api -Method POST -Path "/api/ho-so-cong-viec/$script:hscvId/mo-lai" -Headers $script:headers
    if (-not $r.success) { throw "Reopen fail: $($r.message)" }
    Start-Sleep -Milliseconds 200
    $r2 = Invoke-Api -Method GET -Path "/api/ho-so-cong-viec/$script:hscvId" -Headers $script:headers
    if ([int]$r2.data.status -ne 1) { throw "Expected status=1, got $($r2.data.status)" }
    if ([int]$r2.data.progress -ne 100) { throw "Expected progress=100 (giu), got $($r2.data.progress)" }
    'ok 4->1 progress=100'
}

# ============================================================
# TC12: Tao HSCV 2 + Chuyen tiep
# ============================================================
Test-TC 'TC12' 'POST /chuyen-tiep (transfer ownership)' {
    # Tao HSCV 2
    $stamp = Get-Date -Format 'HHmmss'
    $body = @{
        name       = "[SMOKE_HSCV_$stamp] Test transfer"
        comments   = 'Smoke test transfer'
        start_date = (Get-Date -Format 'yyyy-MM-dd')
        end_date   = (Get-Date).AddDays(15).ToString('yyyy-MM-dd')
        curator_id = 1
    }
    $cr = Invoke-Api -Method POST -Path '/api/ho-so-cong-viec' -Headers $script:headers -Body $body
    if (-not $cr.success) { throw "Create HSCV2 fail: $($cr.message)" }
    $script:hscvId2 = [int]$cr.data.id
    $null = $script:createdIds.Add($script:hscvId2)

    # Tim staff cung don vi (khac admin)
    $stf = Invoke-Api -Method GET -Path '/api/ho-so-cong-viec/nhan-vien-cung-don-vi' -Headers $script:headers
    if (-not $stf.success -or $stf.data.Count -lt 2) { throw 'Can >= 2 staff cung don vi' }
    $other = $stf.data | Where-Object { [int]$_.id -ne 1 } | Select-Object -First 1
    if (-not $other) { throw 'Khong tim duoc staff khac admin' }
    $script:transferStaffId = [int]$other.id

    # Transfer
    $r = Invoke-Api -Method POST -Path "/api/ho-so-cong-viec/$script:hscvId2/chuyen-tiep" `
        -Headers $script:headers `
        -Body @{ to_staff_id = $script:transferStaffId; note = 'Smoke test transfer note' }
    if (-not $r.success) { throw "Transfer fail: $($r.message)" }
    "id2=$script:hscvId2 to_staff=$script:transferStaffId"
}

# ============================================================
# TC13: GET lich-su (history >= 1)
# ============================================================
Test-TC 'TC13' 'GET /lich-su (history >= 1 entry)' {
    if (-not $script:hscvId2) { throw 'Skip' }
    $r = Invoke-Api -Method GET -Path "/api/ho-so-cong-viec/$script:hscvId2/lich-su" -Headers $script:headers
    if (-not $r.success) { throw "History fail: $($r.message)" }
    if ($r.data.Count -lt 1) { throw "Expected >= 1 entry, got $($r.data.Count)" }
    "entries=$($r.data.Count)"
}

# ============================================================
# TC14: POST y-kien (create opinion)
# ============================================================
Test-TC 'TC14' 'POST /y-kien (create opinion)' {
    if (-not $script:hscvId2) { throw 'Skip' }
    $r = Invoke-Api -Method POST -Path "/api/ho-so-cong-viec/$script:hscvId2/y-kien" `
        -Headers $script:headers `
        -Body @{ content = 'Smoke test opinion content' }
    if (-not $r.success) { throw "Create opinion fail: $($r.message)" }
    if (-not $r.data.id) { throw 'Khong nhan duoc opinion id' }
    $script:opinionId = [int]$r.data.id
    $null = $script:createdOpinionIds.Add($script:opinionId)
    "opinion_id=$script:opinionId"
}

# ============================================================
# TC15: POST y-kien chuyen-tiep (forward)
# ============================================================
Test-TC 'TC15' 'POST /y-kien/:id/chuyen-tiep (forward opinion)' {
    if (-not $script:hscvId2 -or -not $script:opinionId -or -not $script:transferStaffId) { throw 'Skip - missing prereq' }
    $r = Invoke-Api -Method POST `
        -Path "/api/ho-so-cong-viec/$script:hscvId2/y-kien/$script:opinionId/chuyen-tiep" `
        -Headers $script:headers `
        -Body @{ to_staff_id = $script:transferStaffId; note = 'Smoke forward opinion' }
    if (-not $r.success) { throw "Forward opinion fail: $($r.message)" }
    'ok forwarded'
}

# ============================================================
# TC16: Reject + Cancel flow (Bug B verify)
# ============================================================
Test-TC 'TC16' 'reject 3->-1 + huy -1->-3 + huy reject status=4 (Bug B)' {
    # Tao HSCV 3, day status len 3
    $stamp = Get-Date -Format 'HHmmss'
    $body = @{
        name       = "[SMOKE_HSCV_$stamp] Test reject"
        comments   = 'Smoke test reject + cancel'
        start_date = (Get-Date -Format 'yyyy-MM-dd')
        end_date   = (Get-Date).AddDays(15).ToString('yyyy-MM-dd')
        curator_id = 1
    }
    $cr = Invoke-Api -Method POST -Path '/api/ho-so-cong-viec' -Headers $script:headers -Body $body
    if (-not $cr.success) { throw "Create HSCV3 fail: $($cr.message)" }
    $script:hscvId3 = [int]$cr.data.id
    $null = $script:createdIds.Add($script:hscvId3)

    # 0 -> 1
    $r1 = Invoke-Api -Method PATCH -Path "/api/ho-so-cong-viec/$script:hscvId3/trang-thai" `
        -Headers $script:headers -Body @{ action = 'change'; new_status = 1 }
    if (-not $r1.success) { throw "Change 0->1 fail: $($r1.message)" }

    # 1 -> 3 (submit gop, khong qua status 2)
    $r2 = Invoke-Api -Method PATCH -Path "/api/ho-so-cong-viec/$script:hscvId3/trang-thai" `
        -Headers $script:headers -Body @{ action = 'submit' }
    if (-not $r2.success) { throw "Submit fail: $($r2.message)" }

    # Reject 3 -> -1 (Bug A: yeu cau reason)
    $rr = Invoke-Api -Method PATCH -Path "/api/ho-so-cong-viec/$script:hscvId3/trang-thai" `
        -Headers $script:headers -Body @{ action = 'reject'; reason = 'Smoke test reject reason' }
    if (-not $rr.success) { throw "Reject fail: $($rr.message)" }

    # Verify status=-1
    $g1 = Invoke-Api -Method GET -Path "/api/ho-so-cong-viec/$script:hscvId3" -Headers $script:headers
    if ([int]$g1.data.status -ne -1) { throw "After reject, expected status=-1, got $($g1.data.status)" }

    # Bug B positive: cancel -1 -> -3 (allow)
    $rc = Invoke-Api -Method POST -Path "/api/ho-so-cong-viec/$script:hscvId3/huy" `
        -Headers $script:headers -Body @{ reason = 'Smoke test cancel after reject' }
    if (-not $rc.success) { throw "Cancel after reject fail: $($rc.message)" }

    # Verify status=-3
    $g2 = Invoke-Api -Method GET -Path "/api/ho-so-cong-viec/$script:hscvId3" -Headers $script:headers
    if ([int]$g2.data.status -ne -3) { throw "After cancel, expected status=-3, got $($g2.data.status)" }

    # Bug B negative: HSCV1 dang status=1 (sau reopen) -> cancel phai REJECT (400 + success=false)
    if ($script:hscvId) {
        $negSuccess = $true
        try {
            $rcNeg = Invoke-Api -Method POST -Path "/api/ho-so-cong-viec/$script:hscvId/huy" `
                -Headers $script:headers -Body @{ reason = 'Bug B negative test' }
            # Khong throw -> co the response 200 nhung success=false (it gap)
            if ($rcNeg -and $rcNeg.success -eq $true) {
                throw 'Bug B negative FAIL: cancel HSCV status=1 lai succeed (must reject)'
            }
            $negSuccess = $false
        } catch [System.Net.WebException] {
            # Expected: 400 BadRequest tu backend khi cancel HSCV status=1
            $negSuccess = $false
        } catch {
            # Re-throw cac loi khac (test logic loi)
            if ($_.Exception.Message -match 'Bug B negative FAIL') { throw }
            # Generic Invoke-RestMethod throws "(400) Bad Request" -> coi nhu expected
            if ($_.Exception.Message -match '400|Bad Request') { $negSuccess = $false }
            else { throw "Bug B negative msg sai: $($_.Exception.Message)" }
        }
        if ($negSuccess) { throw 'Bug B negative FAIL: cancel succeed' }
    }
    'ok reject->-1, cancel->-3, Bug B negative reject'
}

# ============================================================
# Cleanup
# ============================================================
Write-Host ''
Write-Host '  Cleanup HSCV test...' -ForegroundColor DarkGray
foreach ($id in $script:createdIds) {
    try {
        $null = Invoke-RestMethod -Uri "$ApiUrl/api/ho-so-cong-viec/$id" -Method DELETE `
            -Headers $script:headers -UseBasicParsing -TimeoutSec 10
        Write-Log "Cleanup DELETE $id OK"
    } catch {
        # Best-effort - HSCV co the o status khong cho phep delete (status=-3 etc.)
        # Fallback: docker exec hard-delete
        Write-Log "Cleanup API DELETE $id fail: $($_.Exception.Message), try docker"
        $null = docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "
            DELETE FROM edoc.handling_doc_history WHERE handling_doc_id = $id;
            DELETE FROM edoc.opinion_handling_docs WHERE handling_doc_id = $id;
            DELETE FROM edoc.staff_handling_docs WHERE handling_doc_id = $id;
            DELETE FROM edoc.handling_docs WHERE id = $id;
        " 2>&1 | Out-Null
    }
}

# -- Summary --------------------------------------------------
$pass = ($results | Where-Object { $_.Status -eq 'PASS' }).Count
$fail = ($results | Where-Object { $_.Status -eq 'FAIL' }).Count
$total = $results.Count
$duration = [int]((Get-Date) - $Start).TotalSeconds

Write-Host ''
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host '  KET QUA SMOKE TEST HSCV' -ForegroundColor Cyan
Write-Host '================================================================' -ForegroundColor Cyan
Write-Host ("  Pass:     {0}/{1}" -f $pass, $total) -ForegroundColor Green
if ($fail -gt 0) {
    Write-Host ("  Fail:     {0}/{1}" -f $fail, $total) -ForegroundColor Red
} else {
    Write-Host ("  Fail:     {0}/{1}" -f $fail, $total) -ForegroundColor Green
}
Write-Host ("  Duration: {0}s" -f $duration)
Write-Host ("  Log:      {0}" -f $logFile)
Write-Host ''

if ($fail -gt 0) {
    Write-Host 'TESTCASE FAIL:' -ForegroundColor Red
    foreach ($t in ($results | Where-Object { $_.Status -eq 'FAIL' })) {
        Write-Host ("  - {0,-6} {1}" -f $t.TC, $t.Name) -ForegroundColor Red
        Write-Host ("           {0}" -f $t.Detail) -ForegroundColor DarkRed
    }
    Write-Host ''
    Write-Host '---- Log tail (30 dong cuoi) ----' -ForegroundColor Yellow
    Get-Content $logFile -Tail 30
    Write-Host "---- Full log: $logFile ----" -ForegroundColor Yellow
    exit 1
}

Write-Host 'SMOKE TEST PASS - san sang deploy' -ForegroundColor Green
exit 0
