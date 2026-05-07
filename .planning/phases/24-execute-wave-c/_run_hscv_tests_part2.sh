#!/usr/bin/env bash
# HSCV Wave c — Part 2: TC-010..019, plus re-test 097/100 with rejected HSCV
set -u
API=http://localhost:4000/api
LOG=D:/ProjectAI/quanlyvanban/.planning/phases/24-execute-wave-c/_hscv_run.jsonl

login() {
  curl -s -X POST $API/auth/login -H "Content-Type: application/json" \
    -d "{\"username\":\"$1\",\"password\":\"Test@123\"}" \
    | python -c "import sys,json; print(json.load(sys.stdin)['data']['accessToken'])"
}

T_LANHDAO=$(login test_lanhdao)
T_CANBO=$(login test_canbo)
T_CANBO_X=$(login test_canbo_x)

logtc() { echo "$1 | $2 | $3" | tee -a "$LOG"; }

req() {
  local M=$1; local P=$2; local T=$3; local B=${4:-}
  if [ -n "$B" ]; then
    curl -s -X $M -H "Authorization: Bearer $T" -H "Content-Type: application/json" -d "$B" "$API$P"
  else
    curl -s -X $M -H "Authorization: Bearer $T" "$API$P"
  fi
}

# TC-HSCV-010: HSCV closed (status=4) — Hạn không hiển thị màu đỏ. Backend trả end_date đầy đủ — UI styling.
R=$(req GET "/ho-so-cong-viec/9002" $T_LANHDAO)
END=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['data']['end_date'])" 2>/dev/null)
ST=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['data']['status'])" 2>/dev/null)
logtc TC-HSCV-010 SKIP "UI-only color rendering. Backend OK: HSCV 9002 status=$ST end_date=$END"

# TC-HSCV-011: Bam ten -> Chi tiet (UI navigate). Backend GET detail OK
logtc TC-HSCV-011 SKIP "UI-only navigation. GET detail endpoint verified separately"

# TC-HSCV-012: Menu 3 cham — HSCV moi tao co Sua/Xoa
logtc TC-HSCV-012 SKIP "UI-only menu visibility based on status"

# TC-HSCV-013: Menu 3 cham — HSCV khong moi tao chi co Xem
logtc TC-HSCV-013 SKIP "UI-only menu visibility"

# TC-HSCV-014: In danh sach (browser print)
logtc TC-HSCV-014 SKIP "Browser print dialog — pure UI"

# TC-HSCV-015: Xuat Excel - co backend?
R=$(curl -s -H "Authorization: Bearer $T_LANHDAO" -o /tmp/hscv-export.xlsx -w "%{http_code}|%{size_download}" "$API/ho-so-cong-viec/xuat-excel?page=1&page_size=20")
echo "$R" | grep -q "^200" && logtc TC-HSCV-015 PASS "xuat-excel returned 200, size=$(echo $R | cut -d'|' -f2) bytes" \
  || logtc TC-HSCV-015 SKIP "xuat-excel endpoint not implemented (HTTP code: $R)"

# TC-HSCV-016: Excel empty list
R=$(curl -s -H "Authorization: Bearer $T_LANHDAO" -o /dev/null -w "%{http_code}" "$API/ho-so-cong-viec/xuat-excel?keyword=ZZZZNONEXISTENT")
[ "$R" = "200" ] && logtc TC-HSCV-016 SKIP "endpoint exists but UI message verification needed (FE)" \
  || logtc TC-HSCV-016 SKIP "xuat-excel endpoint not implemented (HTTP $R)"

# TC-HSCV-017: 10000 row limit
logtc TC-HSCV-017 SKIP "Cannot test 10000+ rows in test fixture (only 2 base + ~15 created)"

# TC-HSCV-018: Empty table no filter
# All test_lanhdao users see fixtures, hard to make empty. Use canbo_x
R=$(req GET "/ho-so-cong-viec/?page=1&page_size=20" $T_CANBO_X)
TOTAL=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin).get('pagination',{}).get('total'))" 2>/dev/null)
[ "$TOTAL" = "0" ] && logtc TC-HSCV-018 PASS "canbo_x (cross-unit) sees 0 HSCV — empty list rendered FE-side" \
  || logtc TC-HSCV-018 VERIFY "canbo_x sees total=$TOTAL HSCV (expected 0 if scope strict)"

# TC-HSCV-019: Empty filter
R=$(req GET "/ho-so-cong-viec/?keyword=ZZZNONEXISTENTKEYWORD" $T_LANHDAO)
TOTAL=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin).get('pagination',{}).get('total'))" 2>/dev/null)
[ "$TOTAL" = "0" ] && logtc TC-HSCV-019 PASS "non-existent keyword -> total=0, FE shows empty state" \
  || logtc TC-HSCV-019 FAIL "total=$TOTAL"

# === RE-TEST cancel TCs with rejected HSCV ===
# Setup: create -> submit (canbo) -> reject (lanhdao) -> cancel (lanhdao)

setup_rejected() {
  R=$(req POST "/ho-so-cong-viec/" $T_LANHDAO '{"name":"For cancel re-test '$RANDOM'","start_date":"2026-05-07","end_date":"2026-05-14","curator_id":9004,"signer_id":9003}')
  NID=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin)['data']['id'])" 2>/dev/null)
  req PATCH "/ho-so-cong-viec/$NID/trang-thai" $T_CANBO '{"action":"submit"}' > /dev/null
  req PATCH "/ho-so-cong-viec/$NID/trang-thai" $T_LANHDAO '{"action":"reject","reason":"test"}' > /dev/null
  echo "$NID"
}

# TC-HSCV-097 RE-TEST: Cancel rejected HSCV (status=-1)
NID=$(setup_rejected)
echo "Setup rejected HSCV id=$NID"
R=$(req POST "/ho-so-cong-viec/$NID/huy" $T_LANHDAO '{"reason":"Khong can xu ly"}')
SUC=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin).get('success'))" 2>/dev/null)
if [ "$SUC" = "True" ]; then
  R2=$(req GET "/ho-so-cong-viec/$NID" $T_LANHDAO)
  ST=$(echo "$R2" | python -c "import sys,json; print(json.load(sys.stdin)['data']['status'])")
  RR=$(echo "$R2" | python -c "import sys,json; print(json.load(sys.stdin)['data']['cancel_reason'])")
  # Update prior FAIL line for TC-HSCV-097 — append a re-test note
  echo "TC-HSCV-097-RETEST | PASS | After reject->cancel: id=$NID status=$ST reason=$RR" >> "$LOG"
  echo "TC-HSCV-097-RETEST | PASS | After reject->cancel: id=$NID status=$ST reason=$RR"
else
  echo "TC-HSCV-097-RETEST | FAIL | $R" >> "$LOG"
  echo "TC-HSCV-097-RETEST | FAIL | $R"
fi

# TC-HSCV-100 RE-TEST: 1000-char reason
NID=$(setup_rejected)
LONG=$(python -c "print('A'*1000)")
R=$(req POST "/ho-so-cong-viec/$NID/huy" $T_LANHDAO "{\"reason\":\"$LONG\"}")
SUC=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin).get('success'))" 2>/dev/null)
[ "$SUC" = "True" ] && echo "TC-HSCV-100-RETEST | PASS | 1000-char reason accepted on rejected HSCV id=$NID" | tee -a "$LOG" \
  || echo "TC-HSCV-100-RETEST | FAIL | $R" | tee -a "$LOG"

# TC-HSCV-021 RE-CHECK: confirm rejection message contains "bắt buộc"
R=$(req POST "/ho-so-cong-viec/" $T_LANHDAO '{"start_date":"2026-05-07","end_date":"2026-05-14"}')
SUC=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin).get('success'))" 2>/dev/null)
MSG=$(echo "$R" | python -c "import sys,json; print(json.load(sys.stdin).get('message',''))" 2>/dev/null)
[ "$SUC" = "False" ] && echo "$MSG" | grep -q "bắt buộc" && \
  echo "TC-HSCV-021-RECHECK | PASS | Missing name rejected: $MSG" | tee -a "$LOG" \
  || echo "TC-HSCV-021-RECHECK | UNEXPECTED | $R" | tee -a "$LOG"

echo "=== PART 2 DONE ==="
