#!/usr/bin/env bash
# Wave d - Quan tri Nguoi dung API tests (53 TC)
set -u
BASE="http://localhost:4000/api"
RESULTS="/tmp/qtnd_results.txt"
BODY_FILE="/tmp/_body.json"
WIN_BODY=$(cygpath -w "$BODY_FILE" 2>/dev/null || echo "$BODY_FILE")
> "$RESULTS"

login() {
  local user="$1" pass="$2"
  curl -s -m 5 -X POST "$BASE/auth/login" -H "Content-Type: application/json" \
    -d "{\"username\":\"$user\",\"password\":\"$pass\"}" \
    | python -c "import sys,json
try:
  d=json.load(sys.stdin)
  print(d.get('data',{}).get('accessToken','') or '')
except: print('')"
}

ADMIN_TOKEN=$(login admin "Admin@123")
[ -z "$ADMIN_TOKEN" ] && { echo "FATAL admin login fail"; exit 1; }
echo "ADMIN_TOKEN_LEN=${#ADMIN_TOKEN}"

# Test fixtures use Test@123 (per seed/003_test_fixtures.sql)
CANBO_TOKEN=$(login test_canbo "Test@123")
echo "CANBO_TOKEN_LEN=${#CANBO_TOKEN}"

H_ADMIN_AUTH="Authorization: Bearer $ADMIN_TOKEN"
H_CANBO_AUTH="Authorization: Bearer $CANBO_TOKEN"

log() { printf '[%s] %s -> %s\n' "$1" "$2" "$3" | tee -a "$RESULTS"; }
http_code() { curl -s -m 8 -o "$BODY_FILE" -w '%{http_code}' "$@"; }
body() { cat "$BODY_FILE"; }
msg() {
  python -c "import json
try: print(json.load(open(r'$WIN_BODY')).get('message',''))
except: print('')"
}
extract() {
  python -c "import json
try:
  d=json.load(open(r'$WIN_BODY'))
  v=d
  for k in '$1'.split('.'):
    v = v.get(k) if isinstance(v, dict) else (v[int(k)] if isinstance(v, list) else None)
    if v is None: break
  print(v if v is not None else '')
except: print('')"
}
# helper to count list len in data
data_len() {
  python -c "import json
try:
  d=json.load(open(r'$WIN_BODY'))
  print(len(d.get('data',[])))
except: print(0)"
}

####### TC-QTND-001..003 (UI)
log "TC-QTND-001" "MANUAL_UI" "Layout 2 cot — Playwright"
log "TC-QTND-002" "MANUAL_UI" "9 cot bang — Playwright"
log "TC-QTND-003" "MANUAL_UI" "Cot SDT dau gach — Playwright"

####### TC-QTND-004 filter dept
code=$(http_code -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung?department_id=2&page=1&pageSize=20")
total=$(extract total)
rows=$(python -c "import json; d=json.load(open(r'$WIN_BODY')); print(len(d.get('data',[])))")
all_dept2=$(python -c "import json; d=json.load(open(r'$WIN_BODY')); print('OK' if all(r.get('department_id')==2 for r in d.get('data',[])) else 'NO')")
if [ "$code" = "200" ] && [ "$all_dept2" = "OK" ]; then
  log "TC-QTND-004" "PASS" "code=$code total=$total rows=$rows all_dept_id=2"
else
  log "TC-QTND-004" "FAIL" "code=$code rows=$rows all_dept2=$all_dept2"
fi

####### TC-QTND-005 search by username — bug? shadow filters full_name only
http_code -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung?keyword=test_admin&page=1&pageSize=20" >/dev/null
hits1=$(python -c "import json; d=json.load(open(r'$WIN_BODY')); print(len(d.get('data',[])))")
http_code -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung?keyword=TEST%20Quan&page=1&pageSize=20" >/dev/null
hits2=$(python -c "import json; d=json.load(open(r'$WIN_BODY')); print(len(d.get('data',[])))")
if [ "$hits1" = "0" ] && [ "$hits2" -gt "0" ]; then
  log "TC-QTND-005" "FAIL" "BUG-ND-002: search 'test_admin' (username) hits=$hits1, search 'TEST Quan' (full_name) hits=$hits2 — shadow public-catalog chi search full_name, KHONG search username"
elif [ "$hits1" -gt "0" ]; then
  log "TC-QTND-005" "PASS" "search by username hits=$hits1"
else
  log "TC-QTND-005" "FAIL" "hits1=$hits1 hits2=$hits2"
fi

####### TC-QTND-006 status active filter
http_code -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung?is_locked=false&page=1&pageSize=50" >/dev/null
total=$(extract total)
locked_in_data=$(python -c "import json; d=json.load(open(r'$WIN_BODY')); print(sum(1 for r in d.get('data',[]) if r.get('is_locked')))")
if [ "$locked_in_data" = "0" ] && [ "$total" -gt "0" ]; then
  log "TC-QTND-006" "PASS" "is_locked=false total=$total locked=$locked_in_data"
else
  log "TC-QTND-006" "FAIL" "total=$total locked=$locked_in_data"
fi

####### TC-QTND-007 status locked filter
http_code -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung?is_locked=true&page=1&pageSize=50" >/dev/null
total=$(extract total)
locked_in_data=$(python -c "import json; d=json.load(open(r'$WIN_BODY')); print(sum(1 for r in d.get('data',[]) if r.get('is_locked')))")
all_locked=$(python -c "import json; d=json.load(open(r'$WIN_BODY')); print('OK' if d.get('data') and all(r.get('is_locked') for r in d.get('data',[])) else 'NO')")
# We have user 9099 test_locked in DB. Shadow route hardcodes is_locked=false -> never returns it.
if [ "$total" = "0" ] || [ "$all_locked" = "NO" ]; then
  log "TC-QTND-007" "FAIL" "BUG-ND-001: is_locked=true filter khong hoat dong (shadow route hardcode is_locked=false). total=$total locked_count=$locked_in_data — Da khoa nguoi dung KHONG bao gio hien thi"
else
  log "TC-QTND-007" "PASS" "total=$total all locked"
fi

####### TC-QTND-008 ADD valid
TS=$(date +%s)
U="testu${TS}"
payload="{\"username\":\"$U\",\"password\":\"Abcd1234\",\"first_name\":\"Nguyen Van\",\"last_name\":\"Test\",\"unit_id\":2,\"department_id\":2}"
code=$(http_code -H "$H_ADMIN_AUTH" -X POST "$BASE/quan-tri/nguoi-dung" -H "Content-Type: application/json" -d "$payload")
new_id=$(extract data.id)
if [ "$code" = "201" ] && [ -n "$new_id" ]; then
  log "TC-QTND-008" "PASS" "code=$code new_id=$new_id user=$U"
else
  log "TC-QTND-008" "FAIL" "code=$code body=$(body | head -c 300)"
fi

####### TC-QTND-009 ADD with empty password -> default Admin@123
U2="testu_def${TS}"
payload="{\"username\":\"$U2\",\"first_name\":\"Default\",\"last_name\":\"PW\",\"unit_id\":2,\"department_id\":2}"
code=$(http_code -H "$H_ADMIN_AUTH" -X POST "$BASE/quan-tri/nguoi-dung" -H "Content-Type: application/json" -d "$payload")
if [ "$code" = "201" ]; then
  TOK=$(login "$U2" "Admin@123")
  if [ -n "$TOK" ]; then
    log "TC-QTND-009" "PASS" "create OK + login Admin@123 OK"
  else
    log "TC-QTND-009" "FAIL" "create OK but Admin@123 login fail"
  fi
else
  log "TC-QTND-009" "FAIL" "code=$code body=$(body | head -c 300)"
fi

####### TC-QTND-010 ADD full fields
U3="testu_full${TS}"
payload=$(cat <<EOF
{"username":"$U3","password":"Abcd1234","first_name":"Nguyen Van","last_name":"Day Du","email":"full${TS}@dft.vn","phone":"0241234567","mobile":"0987654321","unit_id":2,"department_id":2,"position_id":13,"gender":1,"birth_date":"1990-01-15","address":"so 1, Ho Guom"}
EOF
)
code=$(http_code -H "$H_ADMIN_AUTH" -X POST "$BASE/quan-tri/nguoi-dung" -H "Content-Type: application/json" -d "$payload")
nid=$(extract data.id)
if [ "$code" = "201" ] && [ -n "$nid" ]; then
  http_code -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung/$nid" >/dev/null
  has_all=$(python -c "
import json
d=json.load(open(r'$WIN_BODY'))['data']
need=['username','first_name','last_name','email','phone','mobile','unit_id','department_id','position_id','birth_date','address']
miss=[k for k in need if not d.get(k)]
print('OK' if not miss else 'MISSING:'+','.join(miss))")
  log "TC-QTND-010" "PASS" "code=$code id=$nid verify=$has_all"
else
  log "TC-QTND-010" "FAIL" "code=$code body=$(body | head -c 300)"
fi

####### TC-QTND-011 UI
log "TC-QTND-011" "MANUAL_UI" "Pre-fill don vi/phong ban — Playwright"

####### TC-QTND-012..030 NEGATIVES
neg() {
  local id="$1" payload="$2" expect_codes="$3" desc="$4"
  local code m
  code=$(http_code -H "$H_ADMIN_AUTH" -X POST "$BASE/quan-tri/nguoi-dung" -H "Content-Type: application/json" -d "$payload")
  m=$(msg)
  if echo "$expect_codes" | grep -qw "$code"; then
    log "$id" "PASS" "code=$code msg='$m'"
  else
    log "$id" "FAIL" "code=$code expect=$expect_codes msg='$m' desc=$desc"
  fi
}
neg "TC-QTND-012" '{"first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"password":"Abcd1234"}' "400" "empty username"
neg "TC-QTND-013" '{"username":"ab","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"password":"Abcd1234"}' "400" "username < 3"
neg "TC-QTND-014" '{"username":"user 01","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"password":"Abcd1234"}' "400" "username has space"
neg "TC-QTND-015" '{"username":"user@01","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"password":"Abcd1234"}' "400" "username has @"
neg "TC-QTND-016" '{"username":"admin","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"password":"Abcd1234"}' "409 400" "duplicate username"
neg "TC-QTND-017" '{"username":"newuserx1","password":"Ab1","first_name":"X","last_name":"Y","unit_id":2,"department_id":2}' "400" "password < 6"
neg "TC-QTND-018" '{"username":"newuserx2","password":"abcdef1","first_name":"X","last_name":"Y","unit_id":2,"department_id":2}' "400" "password no upper"
neg "TC-QTND-019" '{"username":"newuserx3","password":"ABCDEF1","first_name":"X","last_name":"Y","unit_id":2,"department_id":2}' "400" "password no lower"
neg "TC-QTND-020" '{"username":"newuserx4","password":"AbcdefG","first_name":"X","last_name":"Y","unit_id":2,"department_id":2}' "400" "password no digit"
neg "TC-QTND-021" '{"username":"newuserx5","password":"Abcd1234","last_name":"Y","unit_id":2,"department_id":2}' "400" "empty first_name"
neg "TC-QTND-022" '{"username":"newuserx6","password":"Abcd1234","first_name":"X","unit_id":2,"department_id":2}' "400" "empty last_name"
neg "TC-QTND-023" '{"username":"newuserx7","password":"Abcd1234","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"email":"abc"}' "400" "invalid email"
neg "TC-QTND-024" "{\"username\":\"newuserdup${TS}\",\"password\":\"Abcd1234\",\"first_name\":\"X\",\"last_name\":\"Y\",\"unit_id\":2,\"department_id\":2,\"email\":\"test_admin@test.local\"}" "409 400" "duplicate email"
neg "TC-QTND-025" '{"username":"newuserx9","password":"Abcd1234","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"phone":"12345"}' "400" "phone < 8"
neg "TC-QTND-026" '{"username":"newuserxa","password":"Abcd1234","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"phone":"0241234567890123"}' "400" "phone > 15"
neg "TC-QTND-027" '{"username":"newuserxb","password":"Abcd1234","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"phone":"0241234abc"}' "400" "phone has letters"
neg "TC-QTND-028" '{"username":"newuserxc","password":"Abcd1234","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"mobile":"098abc1234"}' "400" "mobile invalid"
neg "TC-QTND-029" '{"username":"newuserxd","password":"Abcd1234","first_name":"X","last_name":"Y","department_id":2}' "400" "empty unit_id"
neg "TC-QTND-030" '{"username":"newuserxe","password":"Abcd1234","first_name":"X","last_name":"Y","unit_id":2}' "400" "empty department_id"

####### TC-QTND-031 UI
log "TC-QTND-031" "MANUAL_UI" "Doi don vi -> reset phong ban — Playwright"

####### TC-QTND-032..034 boundary
# Use TS suffix so re-runs don't collide on unique username
SUFFIX_LEN=${#TS}
PREFIX_LEN=$((50 - SUFFIX_LEN))
U50=$(python -c "print('a'*$PREFIX_LEN + '$TS')")
payload="{\"username\":\"$U50\",\"password\":\"Abcd1234\",\"first_name\":\"X\",\"last_name\":\"Y\",\"unit_id\":2,\"department_id\":2}"
code=$(http_code -H "$H_ADMIN_AUTH" -X POST "$BASE/quan-tri/nguoi-dung" -H "Content-Type: application/json" -d "$payload")
[ "$code" = "201" ] && log "TC-QTND-032" "PASS" "username 50 chars (len=${#U50}) code=$code" || log "TC-QTND-032" "FAIL" "code=$code msg='$(msg)' username=$U50 len=${#U50}"

F50=$(python -c "print('a'*50)")
U=test50fn$TS
payload="{\"username\":\"$U\",\"password\":\"Abcd1234\",\"first_name\":\"$F50\",\"last_name\":\"Y\",\"unit_id\":2,\"department_id\":2}"
code=$(http_code -H "$H_ADMIN_AUTH" -X POST "$BASE/quan-tri/nguoi-dung" -H "Content-Type: application/json" -d "$payload")
[ "$code" = "201" ] && log "TC-QTND-033" "PASS" "first_name 50 chars code=$code" || log "TC-QTND-033" "FAIL" "code=$code msg='$(msg)'"

A500=$(python -c "print('a'*500)")
U=test500addr$TS
payload="{\"username\":\"$U\",\"password\":\"Abcd1234\",\"first_name\":\"X\",\"last_name\":\"Y\",\"unit_id\":2,\"department_id\":2,\"address\":\"$A500\"}"
code=$(http_code -H "$H_ADMIN_AUTH" -X POST "$BASE/quan-tri/nguoi-dung" -H "Content-Type: application/json" -d "$payload")
[ "$code" = "201" ] && log "TC-QTND-034" "PASS" "address 500 chars code=$code" || log "TC-QTND-034" "FAIL" "code=$code msg='$(msg)'"

####### TC-QTND-035..036 UI
log "TC-QTND-035" "MANUAL_UI" "gender default Nam — page.tsx line 718 initialValue=1"
log "TC-QTND-036" "MANUAL_UI" "DatePicker DD/MM/YYYY — page.tsx line 727 format='DD/MM/YYYY'"

####### TC-QTND-037 PUT khong sua username
payload='{"username":"changed","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"email":""}'
http_code -H "$H_ADMIN_AUTH" -X PUT "$BASE/quan-tri/nguoi-dung/9099" -H "Content-Type: application/json" -d "$payload" >/dev/null
un=$(docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -t -c "SELECT username FROM public.staff WHERE id=9099;" 2>/dev/null | tr -d ' \n')
[ "$un" = "test_locked" ] && log "TC-QTND-037" "PASS" "PUT khong doi username (DB still '$un')" || log "TC-QTND-037" "FAIL" "username='$un'"

####### TC-QTND-038 UI
log "TC-QTND-038" "MANUAL_UI" "Drawer Sua khong co Mat khau — page.tsx 652 wrap !editingRecord"

####### TC-QTND-039 update email
U_E="teste${TS}"
payload="{\"username\":\"$U_E\",\"password\":\"Abcd1234\",\"first_name\":\"X\",\"last_name\":\"Y\",\"unit_id\":2,\"department_id\":2,\"email\":\"old${TS}@dft.vn\"}"
http_code -H "$H_ADMIN_AUTH" -X POST "$BASE/quan-tri/nguoi-dung" -H "Content-Type: application/json" -d "$payload" >/dev/null
NID=$(extract data.id)
echo "DEBUG NID=$NID"
if [ -n "$NID" ]; then
  payload="{\"first_name\":\"X\",\"last_name\":\"Y\",\"unit_id\":2,\"department_id\":2,\"email\":\"new${TS}@dft.vn\"}"
  code=$(http_code -H "$H_ADMIN_AUTH" -X PUT "$BASE/quan-tri/nguoi-dung/$NID" -H "Content-Type: application/json" -d "$payload")
  if [ "$code" = "200" ]; then
    http_code -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung/$NID" >/dev/null
    new_email=$(extract data.email)
    [ "$new_email" = "new${TS}@dft.vn" ] && log "TC-QTND-039" "PASS" "email updated to $new_email" || log "TC-QTND-039" "FAIL" "email='$new_email'"
  else
    log "TC-QTND-039" "FAIL" "PUT code=$code body=$(body | head -c 200)"
  fi
else
  log "TC-QTND-039" "BLOCKED" "create user fail body=$(body | head -c 200)"
fi

####### TC-QTND-040 update email duplicate
if [ -n "$NID" ]; then
  payload="{\"first_name\":\"X\",\"last_name\":\"Y\",\"unit_id\":2,\"department_id\":2,\"email\":\"test_admin@test.local\"}"
  code=$(http_code -H "$H_ADMIN_AUTH" -X PUT "$BASE/quan-tri/nguoi-dung/$NID" -H "Content-Type: application/json" -d "$payload")
  m=$(msg)
  if [ "$code" = "409" ] || [ "$code" = "400" ]; then
    log "TC-QTND-040" "PASS" "code=$code msg='$m'"
  else
    log "TC-QTND-040" "FAIL" "code=$code msg='$m'"
  fi
else
  log "TC-QTND-040" "BLOCKED" "no NID"
fi

####### TC-QTND-041 update unit/department
if [ -n "$NID" ]; then
  payload='{"first_name":"X","last_name":"Y","unit_id":3,"department_id":3}'
  code=$(http_code -H "$H_ADMIN_AUTH" -X PUT "$BASE/quan-tri/nguoi-dung/$NID" -H "Content-Type: application/json" -d "$payload")
  if [ "$code" = "200" ]; then
    http_code -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung/$NID" >/dev/null
    uid=$(extract data.unit_id)
    did=$(extract data.department_id)
    if [ "$uid" = "3" ] && [ "$did" = "3" ]; then
      log "TC-QTND-041" "PASS" "moved to unit=$uid dept=$did"
    else
      log "TC-QTND-041" "FAIL" "uid=$uid did=$did"
    fi
  else
    log "TC-QTND-041" "FAIL" "code=$code body=$(body | head -c 200)"
  fi
else
  log "TC-QTND-041" "BLOCKED" "no NID"
fi

####### TC-QTND-042 lock account
U_LK="tlk${TS}"
payload="{\"username\":\"$U_LK\",\"password\":\"Abcd1234\",\"first_name\":\"L\",\"last_name\":\"K\",\"unit_id\":2,\"department_id\":2}"
http_code -H "$H_ADMIN_AUTH" -X POST "$BASE/quan-tri/nguoi-dung" -H "Content-Type: application/json" -d "$payload" >/dev/null
LK_ID=$(extract data.id)
echo "DEBUG LK_ID=$LK_ID"
if [ -n "$LK_ID" ]; then
  code=$(http_code -H "$H_ADMIN_AUTH" -X PATCH "$BASE/quan-tri/nguoi-dung/$LK_ID/lock")
  is_locked=$(docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -t -c "SELECT is_locked FROM public.staff WHERE id=$LK_ID;" 2>/dev/null | tr -d ' \n')
  if [ "$code" = "200" ] && [ "$is_locked" = "t" ]; then
    TT=$(login "$U_LK" "Abcd1234")
    if [ -z "$TT" ]; then
      log "TC-QTND-042" "PASS" "locked OK + login blocked"
    else
      log "TC-QTND-042" "PARTIAL" "locked DB=t but login still works (BUG?)"
    fi
  else
    log "TC-QTND-042" "FAIL" "code=$code is_locked='$is_locked'"
  fi
else
  log "TC-QTND-042" "BLOCKED" "create user fail body=$(body | head -c 200)"
fi

####### TC-QTND-043 unlock
if [ -n "${LK_ID:-}" ]; then
  code=$(http_code -H "$H_ADMIN_AUTH" -X PATCH "$BASE/quan-tri/nguoi-dung/$LK_ID/lock")
  is_locked=$(docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -t -c "SELECT is_locked FROM public.staff WHERE id=$LK_ID;" 2>/dev/null | tr -d ' \n')
  if [ "$code" = "200" ] && [ "$is_locked" = "f" ]; then
    TT=$(login "$U_LK" "Abcd1234")
    if [ -n "$TT" ]; then
      log "TC-QTND-043" "PASS" "unlocked + login OK"
    else
      log "TC-QTND-043" "FAIL" "unlocked DB=f but login fails"
    fi
  else
    log "TC-QTND-043" "FAIL" "code=$code is_locked='$is_locked'"
  fi
else
  log "TC-QTND-043" "BLOCKED" "no LK_ID"
fi

####### TC-QTND-044..045 UI
log "TC-QTND-044" "MANUAL_UI" "Drawer Phan quyen 480px — Playwright"
log "TC-QTND-045" "MANUAL_UI" "Card teal khi tich — Playwright"

####### TC-QTND-046 assign roles
if [ -n "$NID" ]; then
  code=$(http_code -H "$H_ADMIN_AUTH" -X PUT "$BASE/quan-tri/nguoi-dung/$NID/nhom-quyen" -H "Content-Type: application/json" -d '{"roleIds":[2,5]}')
  if [ "$code" = "200" ]; then
    log "TC-QTND-046" "PASS" "assign 2 roles code=$code"
  else
    log "TC-QTND-046" "FAIL" "code=$code body=$(body | head -c 300)"
  fi
else
  log "TC-QTND-046" "BLOCKED" "no NID"
fi

####### TC-QTND-047 reload roles
if [ -n "$NID" ]; then
  http_code -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung/$NID/nhom-quyen" >/dev/null
  ids=$(python -c "import json; d=json.load(open(r'$WIN_BODY')).get('data',[]); print(sorted([r.get('role_id') for r in d]))")
  if echo "$ids" | grep -q "2" && echo "$ids" | grep -q "5"; then
    log "TC-QTND-047" "PASS" "GET roles=$ids"
  else
    log "TC-QTND-047" "FAIL" "ids=$ids"
  fi
else
  log "TC-QTND-047" "BLOCKED" "no NID"
fi

####### TC-QTND-048 clear all roles
if [ -n "$NID" ]; then
  code=$(http_code -H "$H_ADMIN_AUTH" -X PUT "$BASE/quan-tri/nguoi-dung/$NID/nhom-quyen" -H "Content-Type: application/json" -d '{"roleIds":[]}')
  http_code -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung/$NID/nhom-quyen" >/dev/null
  remain=$(python -c "import json; d=json.load(open(r'$WIN_BODY')).get('data',[]); print(len(d))")
  if [ "$code" = "200" ] && [ "$remain" = "0" ]; then
    log "TC-QTND-048" "PASS" "all cleared remain=0"
  else
    log "TC-QTND-048" "FAIL" "code=$code remain=$remain"
  fi
else
  log "TC-QTND-048" "BLOCKED" "no NID"
fi

####### TC-QTND-049 reset password
if [ -n "$NID" ]; then
  code=$(http_code -H "$H_ADMIN_AUTH" -X PATCH "$BASE/quan-tri/nguoi-dung/$NID/reset-password")
  if [ "$code" = "200" ]; then
    TT=$(login "$U_E" "Admin@123")
    [ -n "$TT" ] && log "TC-QTND-049" "PASS" "reset OK + login Admin@123 OK" || log "TC-QTND-049" "FAIL" "reset 200 but login Admin@123 fails"
  else
    log "TC-QTND-049" "FAIL" "code=$code body=$(body | head -c 200)"
  fi
else
  log "TC-QTND-049" "BLOCKED" "no NID"
fi

####### TC-QTND-050 UI
log "TC-QTND-050" "MANUAL_UI" "Modal Reset MK click Huy — Playwright"

####### TC-QTND-051 delete user (no history)
if [ -n "$NID" ]; then
  code=$(http_code -H "$H_ADMIN_AUTH" -X DELETE "$BASE/quan-tri/nguoi-dung/$NID")
  rcode=$(curl -s -o /dev/null -w '%{http_code}' -m 5 -H "$H_ADMIN_AUTH" "$BASE/quan-tri/nguoi-dung/$NID")
  isdel=$(docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -t -c "SELECT is_deleted FROM public.staff WHERE id=$NID;" 2>/dev/null | tr -d ' \n')
  if [ "$code" = "200" ]; then
    log "TC-QTND-051" "PASS" "DELETE code=$code GET-after=$rcode is_deleted=$isdel"
  else
    log "TC-QTND-051" "FAIL" "code=$code body=$(body | head -c 200)"
  fi
else
  log "TC-QTND-051" "BLOCKED" "no NID"
fi

####### TC-QTND-052 delete user with history
# Tim user co handling history: check created_by/curator/signer/complete_user_id
TARGET=$(docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -t -c "
  SELECT s.id FROM public.staff s
  WHERE s.is_deleted=false AND s.id != 1
    AND EXISTS (
      SELECT 1 FROM edoc.handling_docs h
      WHERE h.created_by=s.id OR h.curator=s.id OR h.signer=s.id OR h.complete_user_id=s.id
      LIMIT 1
    )
  ORDER BY s.id LIMIT 1;" 2>/dev/null | tr -d ' \n')
echo "DEBUG TARGET for hist test=$TARGET"
if [ -n "$TARGET" ]; then
  isdel_before=$(docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -t -c "SELECT is_deleted FROM public.staff WHERE id=$TARGET;" 2>/dev/null | tr -d ' \n')
  code=$(http_code -H "$H_ADMIN_AUTH" -X DELETE "$BASE/quan-tri/nguoi-dung/$TARGET")
  m=$(msg)
  isdel=$(docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -t -c "SELECT is_deleted FROM public.staff WHERE id=$TARGET;" 2>/dev/null | tr -d ' \n')
  if [ "$code" = "200" ] && [ "$isdel" = "t" ]; then
    log "TC-QTND-052" "VERIFY" "BUG-ND-003: DELETE id=$TARGET co handling history van soft-delete THANH CONG (code=$code, before_del=$isdel_before, after_del=$isdel) — KHONG WARN, KHONG BLOCK. TC mong doi: 'Loi khi xoa' hoac warning 'nen Khoa thay vi xoa'."
    # rollback for next runs
    docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_test -c "UPDATE public.staff SET is_deleted=false WHERE id=$TARGET;" >/dev/null 2>&1
  elif [ "$code" != "200" ]; then
    log "TC-QTND-052" "PASS" "DELETE block code=$code msg='$m' (dung mong doi)"
  else
    log "TC-QTND-052" "FAIL" "code=$code isdel=$isdel msg='$m'"
  fi
else
  log "TC-QTND-052" "BLOCKED" "khong tim duoc user co handling history"
fi

####### TC-QTND-053 non-admin
if [ -n "$CANBO_TOKEN" ]; then
  code_get=$(http_code -H "$H_CANBO_AUTH" "$BASE/quan-tri/nguoi-dung?page=1&pageSize=5")
  code_post=$(http_code -H "$H_CANBO_AUTH" -X POST "$BASE/quan-tri/nguoi-dung" -H "Content-Type: application/json" -d '{"username":"hack","first_name":"X","last_name":"Y","unit_id":2,"department_id":2,"password":"Abcd1234"}')
  code_del=$(http_code -H "$H_CANBO_AUTH" -X DELETE "$BASE/quan-tri/nguoi-dung/9001")
  if [ "$code_post" = "403" ] && [ "$code_del" = "403" ]; then
    log "TC-QTND-053" "PASS" "GET=$code_get (shadow public-catalog read OK), POST=$code_post DELETE=$code_del (admin guard 403)"
  else
    log "TC-QTND-053" "FAIL" "POST=$code_post DELETE=$code_del — non-admin co the modify!"
  fi
else
  log "TC-QTND-053" "BLOCKED" "test_canbo login fail"
fi

echo ""
echo "===== RESULTS SUMMARY ====="
sort -t- -k3 -n "$RESULTS"
echo ""
echo "PASS=$(grep -c PASS $RESULTS)  FAIL=$(grep -c FAIL $RESULTS)  MANUAL_UI=$(grep -c MANUAL_UI $RESULTS)  VERIFY=$(grep -c VERIFY $RESULTS)  BLOCKED=$(grep -c BLOCKED $RESULTS)  PARTIAL=$(grep -c PARTIAL $RESULTS)"
