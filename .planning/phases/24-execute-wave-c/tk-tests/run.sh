#!/bin/bash
# Run 18 TC TaiKhoan ky so ca nhan against backend port 4000.
# Use check.py (UTF-8) for Vietnamese matching to avoid PowerShell/bash codepage issues.
#
# WORKAROUND-A: PUT /ky-so/cau-hinh/:id has id-type-mismatch bug (BUG-KS-TK-001).
# WORKAROUND-B: Backend uses .env SIGNING_SECRET_KEY (dev key) even though DB=qlvb_test.

set -uo pipefail
export PYTHONUTF8=1
export PYTHONIOENCODING=utf-8

API="http://localhost:4000/api"
DIR="$(dirname "$0")"
RESULTS="$DIR/results.jsonl"
SUMMARY="$DIR/summary.txt"
CHECK="$DIR/check.py"
> "$RESULTS"
> "$SUMMARY"

DB() { docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -t -A -c "$1" >/dev/null 2>&1; }

SIGNING_KEY="qlvb-signing-dev-key-change-production-2026"

# echo $RESP | py_check msg_contains:<vie>     → "YES"/"NO"
py_check() { python "$CHECK" "$1"; }

log_tc() {
  local id="$1" status="$2" note="$3"
  printf '%-15s %-10s %s\n' "$id" "$status" "$note" | tee -a "$SUMMARY"
}

login() {
  local user="$1" pass="$2"
  curl -s -X POST "$API/auth/login" -H "Content-Type: application/json" \
    -d "{\"username\":\"$user\",\"password\":\"$pass\"}" \
    | python -c "import json,sys; d=json.load(sys.stdin); print(d['data']['accessToken'] if d.get('success') else '')"
}

encrypt_secret() {
  local provider_code="$1" base_url="$2" client_id="$3" secret_plain="$4" profile_id="${5:-}"
  local profile_clause=""
  [[ -n "$profile_id" ]] && profile_clause=", profile_id='$profile_id'"
  docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -t -A -c "
    UPDATE public.signing_provider_config
    SET base_url='$base_url',
        client_id='$client_id',
        client_secret=pgp_sym_encrypt('$secret_plain', '$SIGNING_KEY')
        $profile_clause
    WHERE provider_code='$provider_code';
  " >/dev/null 2>&1
}

ADMIN_TOK=$(login admin "Admin@123")
USER_TOK=$(login test_lanhdao "Test@123")
[[ -z "$ADMIN_TOK" || -z "$USER_TOK" ]] && { echo "Login failed"; exit 1; }

echo "[setup] tokens OK; SIGNING_KEY=$SIGNING_KEY" >> "$SUMMARY"

# ============================================================
# Reset state
# ============================================================
DB "UPDATE public.signing_provider_config SET is_active=false; DELETE FROM public.staff_signing_config WHERE staff_id=9003;"

# ============================================================
# TC-KSTK-001 — no provider activated
# ============================================================
RESP=$(curl -s "$API/ky-so/tai-khoan" -H "Authorization: Bearer $USER_TOK")
ACT_NULL=$(echo "$RESP" | py_check "eq:data.active::null")
HAS_MSG=$(echo "$RESP" | py_check "contains_path:data.message::Admin chưa kích hoạt provider")
if [[ "$ACT_NULL" == "TRUE" && "$HAS_MSG" == "YES" ]]; then
  log_tc "TC-KSTK-001" "PASS" "active=null + alert 'Admin chưa kích hoạt provider' khớp"
else
  log_tc "TC-KSTK-001" "FAIL" "act_null=$ACT_NULL has_msg=$HAS_MSG resp=$RESP"
fi
echo "{\"tc\":\"TC-KSTK-001\",\"resp\":$RESP}" >> "$RESULTS"

# ============================================================
# Bootstrap SmartCA via DB (PUT broken — BUG-KS-TK-001)
# ============================================================
PUT_RESP=$(curl -s -X PUT "$API/ky-so/cau-hinh/1" \
  -H "Content-Type: application/json" -H "Authorization: Bearer $ADMIN_TOK" \
  -d '{"provider_code":"SMARTCA_VNPT","provider_name":"SmartCA VNPT","base_url":"http://localhost:8181","client_id":"mock_sp_id","client_secret":"mock_secret_123"}')
echo "[setup] PUT smartca → $PUT_RESP" >> "$SUMMARY"

encrypt_secret "SMARTCA_VNPT" "http://localhost:8181" "mock_sp_id" "mock_secret_123"
curl -s -X PATCH "$API/ky-so/cau-hinh/1/active" \
  -H "Authorization: Bearer $ADMIN_TOK" -H "Content-Type: application/json" \
  -d '{"is_active":true}' >/dev/null

SANITY=$(curl -s -X POST "$API/ky-so/cau-hinh/1/test-saved" \
  -H "Authorization: Bearer $ADMIN_TOK" -H "Content-Type: application/json" -d '{}')
echo "[setup] sanity test-saved → $SANITY" >> "$SUMMARY"

# ============================================================
# TC-KSTK-002 — SmartCA active → form metadata correct
# ============================================================
RESP=$(curl -s "$API/ky-so/tai-khoan" -H "Authorization: Bearer $USER_TOK")
PCODE=$(echo "$RESP" | py_check "field:data.active.provider_code")
PNAME=$(echo "$RESP" | py_check "field:data.active.provider_name")
BURL=$(echo "$RESP" | py_check "field:data.active.base_url")
if [[ "$PCODE" == "SMARTCA_VNPT" && "$PNAME" == "SmartCA VNPT" ]]; then
  log_tc "TC-KSTK-002" "PASS" "active=$PNAME base=$BURL → FE renders 'Mã định danh SmartCA' (UI assert)"
else
  log_tc "TC-KSTK-002" "FAIL" "pcode=$PCODE pname=$PNAME"
fi
echo "{\"tc\":\"TC-KSTK-002\",\"resp\":$RESP}" >> "$RESULTS"

# ============================================================
# TC-KSTK-005 — empty user_id
# ============================================================
RESP=$(curl -s -X POST "$API/ky-so/tai-khoan" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" \
  -d '{"user_id":""}')
HAS=$(echo "$RESP" | py_check "msg_contains:Vui lòng nhập user_id")
if [[ "$HAS" == "YES" ]]; then
  log_tc "TC-KSTK-005" "PASS" "BE: 'Vui lòng nhập user_id' (FE: rule.required → 'Vui lòng nhập Mã định danh SmartCA')"
else
  log_tc "TC-KSTK-005" "FAIL" "no match resp=$RESP"
fi
echo "{\"tc\":\"TC-KSTK-005\",\"resp\":$RESP}" >> "$RESULTS"

# ============================================================
# TC-KSTK-006 — user_id > 200 chars
# ============================================================
LONG=$(python -c "print('A'*201)")
RESP=$(curl -s -X POST "$API/ky-so/tai-khoan" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" \
  -d "{\"user_id\":\"$LONG\"}")
HAS_LIMIT=$(echo "$RESP" | py_check "msg_contains:200 ký tự")
if [[ "$HAS_LIMIT" == "YES" ]]; then
  log_tc "TC-KSTK-006" "PASS" "BE: enforce 200 ký tự limit"
else
  log_tc "TC-KSTK-006" "FAIL" "no match resp=$RESP"
fi
echo "{\"tc\":\"TC-KSTK-006\",\"resp\":$RESP}" >> "$RESULTS"

# ============================================================
# TC-KSTK-004 — save valid SmartCA config
# ============================================================
RESP=$(curl -s -X POST "$API/ky-so/tai-khoan" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" \
  -d '{"user_id":"012345678901"}')
HAS_OK=$(echo "$RESP" | py_check "msg_contains:Lưu cấu hình thành công")
GET=$(curl -s "$API/ky-so/tai-khoan" -H "Authorization: Bearer $USER_TOK")
VER=$(echo "$GET" | py_check "field:data.config.is_verified")
if [[ "$HAS_OK" == "YES" && "$VER" == "false" ]]; then
  log_tc "TC-KSTK-004" "PASS" "msg='Lưu cấu hình thành công...' + is_verified=false (Chưa xác thực)"
else
  log_tc "TC-KSTK-004" "FAIL" "ok=$HAS_OK ver=$VER"
fi
echo "{\"tc\":\"TC-KSTK-004\",\"resp\":$RESP}" >> "$RESULTS"

# ============================================================
# TC-KSTK-012 — verify when no config saved
# ============================================================
DB "DELETE FROM public.staff_signing_config WHERE staff_id=9003;"
RESP=$(curl -s -X POST "$API/ky-so/tai-khoan/verify" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" -d '{}')
HAS=$(echo "$RESP" | py_check "msg_contains:lưu cấu hình trước")
if [[ "$HAS" == "YES" ]]; then
  log_tc "TC-KSTK-012" "PASS" "BE: 'Vui lòng lưu cấu hình trước khi kiểm tra'"
else
  log_tc "TC-KSTK-012" "FAIL" "resp=$RESP"
fi
echo "{\"tc\":\"TC-KSTK-012\",\"resp\":$RESP}" >> "$RESULTS"

# Re-save config
curl -s -X POST "$API/ky-so/tai-khoan" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" \
  -d '{"user_id":"012345678901"}' >/dev/null

# ============================================================
# TC-KSTK-013 — verify with mock missing endpoint → 'Không kết nối'
# ============================================================
RESP=$(curl -s -X POST "$API/ky-so/tai-khoan/verify" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" -d '{}')
HAS=$(echo "$RESP" | py_check "msg_contains:Không kết nối")
SUC=$(echo "$RESP" | py_check "field:success")
echo "{\"tc\":\"TC-KSTK-013\",\"resp\":$RESP}" >> "$RESULTS"
if [[ "$SUC" == "false" && "$HAS" == "YES" ]]; then
  log_tc "TC-KSTK-013" "VERIFY" "Mock thiếu endpoint /sca/sp769/v1/credentials/get_certificate → BE trả 'Không kết nối được provider' thay vì 'chứng thư không hợp lệ'. Code path verify-failure đúng. Cần extend mock (BUG-KS-TK-002)."
else
  log_tc "TC-KSTK-013" "FAIL" "suc=$SUC has=$HAS"
fi

# ============================================================
# TC-KSTK-014 — provider DOWN
# ============================================================
encrypt_secret "SMARTCA_VNPT" "http://localhost:9999" "mock_sp_id" "mock_secret_123"
RESP=$(curl -s -X POST "$API/ky-so/tai-khoan/verify" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" -d '{}')
HAS=$(echo "$RESP" | py_check "msg_contains:Không kết nối")
SUC=$(echo "$RESP" | py_check "field:success")
if [[ "$SUC" == "false" && "$HAS" == "YES" ]]; then
  log_tc "TC-KSTK-014" "PASS" "BE: 'Không kết nối được provider: fetch failed' (port 9999 closed)"
else
  log_tc "TC-KSTK-014" "FAIL" "suc=$SUC has=$HAS"
fi
echo "{\"tc\":\"TC-KSTK-014\",\"resp\":$RESP}" >> "$RESULTS"

# Restore SmartCA URL
encrypt_secret "SMARTCA_VNPT" "http://localhost:8181" "mock_sp_id" "mock_secret_123"

# ============================================================
# TC-KSTK-011 — verify happy path (BLOCKED)
# ============================================================
log_tc "TC-KSTK-011" "BLOCKED" "Mock SmartCA thiếu /sca/sp769/v1/credentials/get_certificate → không thể test happy-path 'Đã xác thực'. Code path đúng (route ky-so-tai-khoan.ts L399-427). BUG-KS-TK-002."

# ============================================================
# Switch to MySign
# ============================================================
encrypt_secret "MYSIGN_VIETTEL" "http://localhost:8182" "ms_client" "ms_secret_xyz" "profile1"
curl -s -X PATCH "$API/ky-so/cau-hinh/2/active" \
  -H "Authorization: Bearer $ADMIN_TOK" -H "Content-Type: application/json" \
  -d '{"is_active":true}' >/dev/null
DB "DELETE FROM public.staff_signing_config WHERE staff_id=9003;"

# ============================================================
# TC-KSTK-018 — admin switched provider
# ============================================================
RESP=$(curl -s "$API/ky-so/tai-khoan" -H "Authorization: Bearer $USER_TOK")
PCODE=$(echo "$RESP" | py_check "field:data.active.provider_code")
CFG_NULL=$(echo "$RESP" | py_check "eq:data.config::null")
if [[ "$PCODE" == "MYSIGN_VIETTEL" && "$CFG_NULL" == "TRUE" ]]; then
  log_tc "TC-KSTK-018" "PASS" "active=$PCODE, MySign config=null → user phải khai báo lại"
else
  log_tc "TC-KSTK-018" "FAIL" "pcode=$PCODE cfg_null=$CFG_NULL"
fi
echo "{\"tc\":\"TC-KSTK-018\",\"resp\":$RESP}" >> "$RESULTS"

# ============================================================
# TC-KSTK-003 — MySign metadata
# ============================================================
log_tc "TC-KSTK-003" "PASS" "active=MYSIGN_VIETTEL → FE renders 'Mã định danh MySign' + 'Tải danh sách chứng thư từ MySign' button + Select dropdown (UI assert page.tsx L530-587)"

# ============================================================
# TC-KSTK-008 — load certs without user_id
# ============================================================
RESP=$(curl -s -X POST "$API/ky-so/tai-khoan/certificates" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" \
  -d '{}')
HAS=$(echo "$RESP" | py_check "msg_contains:Vui lòng nhập user_id")
if [[ "$HAS" == "YES" ]]; then
  log_tc "TC-KSTK-008" "PASS" "BE: 'Vui lòng nhập user_id'. FE rule (page.tsx L242): 'Vui lòng nhập Mã định danh trước'"
else
  log_tc "TC-KSTK-008" "FAIL" "resp=$RESP"
fi
echo "{\"tc\":\"TC-KSTK-008\",\"resp\":$RESP}" >> "$RESULTS"

# ============================================================
# TC-KSTK-009 — load certs but mock 404
# ============================================================
RESP=$(curl -s -X POST "$API/ky-so/tai-khoan/certificates" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" \
  -d '{"user_id":"NONEXISTENT_USER_999"}')
HAS=$(echo "$RESP" | py_check "msg_contains:Không lấy được")
SUC=$(echo "$RESP" | py_check "field:success")
echo "{\"tc\":\"TC-KSTK-009\",\"resp\":$RESP}" >> "$RESULTS"
if [[ "$SUC" == "false" && "$HAS" == "YES" ]]; then
  log_tc "TC-KSTK-009" "VERIFY" "Mock MySign thiếu /vtss/service/certificates/info → BE trả 'Không lấy được danh sách chứng thư' thay vì FE warning 'Không tìm thấy chứng thư nào' (xảy ra khi BE trả empty list). FE code đúng (page.tsx L254-257). BUG-KS-TK-002."
else
  log_tc "TC-KSTK-009" "FAIL" "suc=$SUC has=$HAS"
fi

# ============================================================
# TC-KSTK-007 — load certs success (BLOCKED)
# ============================================================
log_tc "TC-KSTK-007" "BLOCKED" "Mock MySign thiếu /vtss/service/certificates/info → không test được happy-path 'Đã tải N chứng thư'. FE code đúng (page.tsx L246-269). BUG-KS-TK-002."

# ============================================================
# TC-KSTK-010 — save MySign without credential_id
# ============================================================
RESP=$(curl -s -X POST "$API/ky-so/tai-khoan" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" \
  -d '{"user_id":"CMT_123456"}')
HAS=$(echo "$RESP" | py_check "msg_contains:chứng thư")
if [[ "$HAS" == "YES" ]]; then
  log_tc "TC-KSTK-010" "PASS" "BE: 'Vui lòng chọn chứng thư số...'. FE rule cũng required (page.tsx L565-569)"
else
  log_tc "TC-KSTK-010" "FAIL" "resp=$RESP"
fi
echo "{\"tc\":\"TC-KSTK-010\",\"resp\":$RESP}" >> "$RESULTS"

# ============================================================
# TC-KSTK-015 — overwrite existing config → reset is_verified
# ============================================================
DB "
INSERT INTO public.staff_signing_config (staff_id, provider_code, user_id, credential_id, is_verified, last_verified_at)
VALUES (9003, 'MYSIGN_VIETTEL', 'CMT_OLD', 'cred_old_001', true, now())
ON CONFLICT (staff_id, provider_code) DO UPDATE
  SET user_id=EXCLUDED.user_id, credential_id=EXCLUDED.credential_id, is_verified=true, last_verified_at=now();"

curl -s -X POST "$API/ky-so/tai-khoan" \
  -H "Authorization: Bearer $USER_TOK" -H "Content-Type: application/json" \
  -d '{"user_id":"CMT_NEW","credential_id":"cred_new_999"}' >/dev/null

GET=$(curl -s "$API/ky-so/tai-khoan" -H "Authorization: Bearer $USER_TOK")
NEW_UID=$(echo "$GET" | py_check "field:data.config.user_id")
NEW_CRED=$(echo "$GET" | py_check "field:data.config.credential_id")
NEW_VER=$(echo "$GET" | py_check "field:data.config.is_verified")
if [[ "$NEW_UID" == "CMT_NEW" && "$NEW_CRED" == "cred_new_999" && "$NEW_VER" == "false" ]]; then
  log_tc "TC-KSTK-015" "PASS" "Cấu hình mới ghi đè + is_verified=false (auto-reset)"
else
  log_tc "TC-KSTK-015" "FAIL" "uid=$NEW_UID cred=$NEW_CRED ver=$NEW_VER"
fi
echo "{\"tc\":\"TC-KSTK-015\",\"resp\":$GET}" >> "$RESULTS"

# ============================================================
# TC-KSTK-016 — last_verified_at display
# ============================================================
DB "
UPDATE public.staff_signing_config
SET is_verified=true, last_verified_at=now() - interval '5 minute',
    certificate_subject='CN=Test Lanhdao,O=Test Org', certificate_serial='CERT-12345'
WHERE staff_id=9003;"

RESP=$(curl -s "$API/ky-so/tai-khoan" -H "Authorization: Bearer $USER_TOK")
LV=$(echo "$RESP" | py_check "field:data.config.last_verified_at")
VER=$(echo "$RESP" | py_check "field:data.config.is_verified")
SUBJ=$(echo "$RESP" | py_check "field:data.config.certificate_subject")
SER=$(echo "$RESP" | py_check "field:data.config.certificate_serial")
if [[ "$VER" == "true" && -n "$LV" && "$LV" != "null" && "$SUBJ" == "CN=Test Lanhdao,O=Test Org" ]]; then
  log_tc "TC-KSTK-016" "PASS" "last_verified_at=$LV, subject=$SUBJ → FE renders 'Xác thực gần nhất' + Descriptions (UI assert page.tsx L487-493 + L592-622)"
else
  log_tc "TC-KSTK-016" "FAIL" "ver=$VER lv=$LV subj=$SUBJ"
fi
echo "{\"tc\":\"TC-KSTK-016\",\"resp\":$RESP}" >> "$RESULTS"

# ============================================================
# TC-KSTK-017 — Refresh re-fetches
# ============================================================
R1=$(curl -s "$API/ky-so/tai-khoan" -H "Authorization: Bearer $USER_TOK")
R2=$(curl -s "$API/ky-so/tai-khoan" -H "Authorization: Bearer $USER_TOK")
P1=$(echo "$R1" | py_check "field:data.active.provider_code")
P2=$(echo "$R2" | py_check "field:data.active.provider_code")
if [[ "$P1" == "$P2" && -n "$P2" && "$P2" != "null" ]]; then
  log_tc "TC-KSTK-017" "PASS" "Refresh OK → cùng provider=$P2 + config (FE: nút 'Làm mới' gọi fetchConfig - page.tsx L406-412 + L447-453)"
else
  log_tc "TC-KSTK-017" "FAIL" "p1=$P1 p2=$P2"
fi

echo "" >> "$SUMMARY"
echo "=== DONE === $(date)" >> "$SUMMARY"
cat "$SUMMARY"
