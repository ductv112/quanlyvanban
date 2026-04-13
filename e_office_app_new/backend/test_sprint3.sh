#!/bin/bash
# Sprint 3 — Full API Test Suite
set -e

BASE="http://localhost:4000"
PASS=0
FAIL=0
TOTAL=0

# Login
LOGIN=$(curl -s -X POST "$BASE/api/auth/login" -H 'Content-Type: application/json' -d '{"username":"admin","password":"Admin@123"}')
TOKEN=$(node -e "console.log(JSON.parse(process.argv[1]).data.accessToken)" "$LOGIN")
AUTH="Authorization: Bearer $TOKEN"

assert_json() {
  local TEST_NAME="$1"
  local EXPR="$2"
  local RESPONSE="$3"
  TOTAL=$((TOTAL + 1))
  RESULT=$(echo "$RESPONSE" | node -e "
    let d=''; process.stdin.on('data',c=>d+=c); process.stdin.on('end',()=>{
      try { const j=JSON.parse(d); console.log(eval(\`(\${process.argv[1]})\`)); }
      catch(e) { console.log('PARSE_ERROR: '+e.message); }
    });
  " "$EXPR" 2>&1)
  if [ "$RESULT" = "true" ]; then
    echo "  ✅ $TEST_NAME"
    PASS=$((PASS + 1))
  else
    echo "  ❌ $TEST_NAME (got: $RESULT)"
    echo "     Response: $(echo "$RESPONSE" | head -c 200)"
    FAIL=$((FAIL + 1))
  fi
}

echo "=========================================="
echo " SPRINT 3 — VĂN BẢN ĐẾN — FULL TEST"
echo "=========================================="

# ==========================================
echo ""
echo "--- 1. SETUP: Create doc_book ---"
R=$(curl -s -X POST "$BASE/api/quan-tri/so-van-ban" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"name":"Sổ VB Đến Test","type_id":1}')
assert_json "Create doc_book" "j.success===true && j.data?.id>0" "$R"
BOOK_ID=$(echo "$R" | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).data?.id))")
echo "  → Book ID: $BOOK_ID"

# ==========================================
echo ""
echo "--- 2. LIST: Empty list ---"
R=$(curl -s "$BASE/api/van-ban-den?page=1&page_size=10" -H "$AUTH")
assert_json "List empty" "j.success===true && j.pagination?.total===0" "$R"

# ==========================================
echo ""
echo "--- 3. NEXT NUMBER ---"
R=$(curl -s "$BASE/api/van-ban-den/so-den-tiep-theo?doc_book_id=$BOOK_ID" -H "$AUTH")
assert_json "Next number = 1" "j.success===true && j.data?.number===1" "$R"

# ==========================================
echo ""
echo "--- 4. CREATE: Validation errors ---"
R=$(curl -s -X POST "$BASE/api/van-ban-den" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"abstract":"","doc_book_id":1}')
assert_json "Create empty abstract → error" "j.success===false" "$R"

R=$(curl -s -X POST "$BASE/api/van-ban-den" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"abstract":"Test VB","doc_book_id":null}')
assert_json "Create no doc_book → error" "j.success===false" "$R"

# ==========================================
echo ""
echo "--- 5. CREATE: 3 documents ---"
R1=$(curl -s -X POST "$BASE/api/van-ban-den" -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"abstract\":\"Về việc triển khai kế hoạch công nghệ thông tin năm 2026\",\"doc_book_id\":$BOOK_ID,\"notation\":\"CV-001/UBND\",\"publish_unit\":\"UBND tỉnh Lạng Sơn\",\"signer\":\"Nguyễn Văn A\",\"urgent_id\":1,\"secret_id\":1}")
assert_json "Create doc 1" "j.success===true && j.data?.id>0" "$R1"
DOC1=$(echo "$R1" | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).data?.id))")

R2=$(curl -s -X POST "$BASE/api/van-ban-den" -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"abstract\":\"Về việc phê duyệt dự toán ngân sách quý II\",\"doc_book_id\":$BOOK_ID,\"notation\":\"QD-055/STC\",\"publish_unit\":\"Sở Tài Chính\",\"signer\":\"Trần Văn B\",\"urgent_id\":2,\"secret_id\":1}")
assert_json "Create doc 2 (Khẩn)" "j.success===true" "$R2"
DOC2=$(echo "$R2" | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).data?.id))")

R3=$(curl -s -X POST "$BASE/api/van-ban-den" -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"abstract\":\"Về việc triệu tập họp khẩn cấp phòng chống bão số 3\",\"doc_book_id\":$BOOK_ID,\"notation\":\"CT-007/UBND\",\"publish_unit\":\"UBND tỉnh\",\"signer\":\"Lê Văn C\",\"urgent_id\":3,\"secret_id\":2,\"expired_date\":\"2026-04-20T00:00:00Z\"}")
assert_json "Create doc 3 (Hỏa tốc, Mật)" "j.success===true" "$R3"
DOC3=$(echo "$R3" | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).data?.id))")
echo "  → Doc IDs: $DOC1, $DOC2, $DOC3"

# ==========================================
echo ""
echo "--- 6. LIST: Should have 3 docs ---"
R=$(curl -s "$BASE/api/van-ban-den?page=1&page_size=10" -H "$AUTH")
assert_json "List has 3 docs" "j.success===true && j.pagination?.total===3" "$R"

# ==========================================
echo ""
echo "--- 7. LIST: Filter by keyword ---"
R=$(curl -s -G "$BASE/api/van-ban-den" --data-urlencode "keyword=ngân sách" -H "$AUTH")
assert_json "Filter keyword 'ngân sách' → 1 result" "j.success===true && j.pagination?.total===1" "$R"

# ==========================================
echo ""
echo "--- 8. LIST: Filter by urgent_id ---"
R=$(curl -s "$BASE/api/van-ban-den?urgent_id=3" -H "$AUTH")
assert_json "Filter Hỏa tốc → 1 result" "j.success===true && j.pagination?.total===1" "$R"

# ==========================================
echo ""
echo "--- 9. GET BY ID ---"
R=$(curl -s "$BASE/api/van-ban-den/$DOC1" -H "$AUTH")
assert_json "Get doc 1 detail" "j.success===true && j.data?.notation==='CV-001/UBND'" "$R"
assert_json "Auto mark read" "j.data?.is_read===true" "$R"

# ==========================================
echo ""
echo "--- 10. UPDATE ---"
R=$(curl -s -X PUT "$BASE/api/van-ban-den/$DOC1" -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"abstract\":\"Về việc triển khai kế hoạch CNTT năm 2026 (đã cập nhật)\",\"doc_book_id\":$BOOK_ID,\"notation\":\"CV-001/UBND\",\"publish_unit\":\"UBND tỉnh Lạng Sơn\",\"signer\":\"Nguyễn Văn A\"}")
assert_json "Update doc 1" "j.success===true" "$R"

R=$(curl -s "$BASE/api/van-ban-den/$DOC1" -H "$AUTH")
assert_json "Updated abstract changed" "j.data?.abstract?.includes('CNTT')" "$R"

# ==========================================
echo ""
echo "--- 11. APPROVE ---"
R=$(curl -s -X PATCH "$BASE/api/van-ban-den/$DOC1/duyet" -H "$AUTH")
assert_json "Approve doc 1" "j.success===true" "$R"

R=$(curl -s "$BASE/api/van-ban-den/$DOC1" -H "$AUTH")
assert_json "Doc 1 is approved" "j.data?.approved===true" "$R"
assert_json "Approver name set" "j.data?.approver?.length>0" "$R"

# ==========================================
echo ""
echo "--- 12. UPDATE after approve → should fail ---"
R=$(curl -s -X PUT "$BASE/api/van-ban-den/$DOC1" -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"abstract\":\"Try edit\",\"doc_book_id\":$BOOK_ID}")
assert_json "Update approved doc → error" "j.success===false" "$R"

# ==========================================
echo ""
echo "--- 13. DELETE approved → should fail ---"
R=$(curl -s -X DELETE "$BASE/api/van-ban-den/$DOC1" -H "$AUTH")
assert_json "Delete approved doc → error" "j.success===false" "$R"

# ==========================================
echo ""
echo "--- 14. SEND (distribute to staff) ---"
R=$(curl -s "$BASE/api/van-ban-den/$DOC1/danh-sach-gui" -H "$AUTH")
assert_json "Get sendable staff list" "j.success===true && Array.isArray(j.data)" "$R"
STAFF_COUNT=$(echo "$R" | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).data?.length||0))")
echo "  → Sendable staff count: $STAFF_COUNT"

R=$(curl -s -X POST "$BASE/api/van-ban-den/$DOC1/gui" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"staff_ids":[1]}')
assert_json "Send doc 1 to staff 1" "j.success===true" "$R"

# ==========================================
echo ""
echo "--- 15. SEND unapproved → should fail ---"
R=$(curl -s -X POST "$BASE/api/van-ban-den/$DOC2/gui" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"staff_ids":[1]}')
assert_json "Send unapproved doc → error" "j.success===false" "$R"

# ==========================================
echo ""
echo "--- 16. RECIPIENTS ---"
R=$(curl -s "$BASE/api/van-ban-den/$DOC1/nguoi-nhan" -H "$AUTH")
assert_json "Recipients list has entries" "j.success===true && j.data?.length>0" "$R"
assert_json "Recipient has staff_name" "j.data?.[0]?.staff_name?.length>0" "$R"

# ==========================================
echo ""
echo "--- 17. UNAPPROVE (should fail — already sent) ---"
R=$(curl -s -X PATCH "$BASE/api/van-ban-den/$DOC1/huy-duyet" -H "$AUTH")
assert_json "Unapprove sent doc → error" "j.success===false" "$R"

# Approve doc 2, then unapprove (no sends)
curl -s -X PATCH "$BASE/api/van-ban-den/$DOC2/duyet" -H "$AUTH" > /dev/null
R=$(curl -s -X PATCH "$BASE/api/van-ban-den/$DOC2/huy-duyet" -H "$AUTH")
assert_json "Unapprove unsent doc → success" "j.success===true" "$R"

# ==========================================
echo ""
echo "--- 18. LEADER NOTES ---"
R=$(curl -s -X POST "$BASE/api/van-ban-den/$DOC1/but-phe" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"content":"Đồng ý, chuyển phòng CNTT triển khai ngay"}')
assert_json "Create leader note" "j.success===true && j.data?.id>0" "$R"
NOTE_ID=$(echo "$R" | node -e "process.stdin.on('data',d=>console.log(JSON.parse(d).data?.id))")

R=$(curl -s -X POST "$BASE/api/van-ban-den/$DOC1/but-phe" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"content":"Yêu cầu báo cáo tiến độ trước 25/04"}')
assert_json "Create leader note 2" "j.success===true" "$R"

R=$(curl -s "$BASE/api/van-ban-den/$DOC1/but-phe" -H "$AUTH")
assert_json "List leader notes = 2" "j.success===true && j.data?.length===2" "$R"
assert_json "Note has staff_name" "j.data?.[0]?.staff_name?.length>0" "$R"

# Validate empty content
R=$(curl -s -X POST "$BASE/api/van-ban-den/$DOC1/but-phe" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"content":""}')
assert_json "Empty note → error" "j.success===false" "$R"

# Delete note
R=$(curl -s -X DELETE "$BASE/api/van-ban-den/$DOC1/but-phe/$NOTE_ID" -H "$AUTH")
assert_json "Delete own note" "j.success===true" "$R"

R=$(curl -s "$BASE/api/van-ban-den/$DOC1/but-phe" -H "$AUTH")
assert_json "Notes after delete = 1" "j.data?.length===1" "$R"

# ==========================================
echo ""
echo "--- 19. BOOKMARKS ---"
R=$(curl -s -X POST "$BASE/api/van-ban-den/$DOC1/danh-dau" -H "$AUTH" -H 'Content-Type: application/json' \
  -d '{"note":"Quan trọng - theo dõi"}')
assert_json "Toggle bookmark ON" "j.success===true && j.data?.is_bookmarked===true" "$R"

R=$(curl -s "$BASE/api/van-ban-den/danh-dau-ca-nhan" -H "$AUTH")
assert_json "Bookmarks list has 1" "j.success===true && j.data?.length===1" "$R"
assert_json "Bookmark has doc info" "j.data?.[0]?.doc_abstract?.length>0" "$R"

R=$(curl -s -X POST "$BASE/api/van-ban-den/$DOC1/danh-dau" -H "$AUTH" -H 'Content-Type: application/json' -d '{}')
assert_json "Toggle bookmark OFF" "j.success===true && j.data?.is_bookmarked===false" "$R"

R=$(curl -s "$BASE/api/van-ban-den/danh-dau-ca-nhan" -H "$AUTH")
assert_json "Bookmarks list empty" "j.data?.length===0" "$R"

# ==========================================
echo ""
echo "--- 20. HISTORY (Timeline) ---"
R=$(curl -s "$BASE/api/van-ban-den/$DOC1/lich-su" -H "$AUTH")
assert_json "History has events" "j.success===true && j.data?.length>=2" "$R"
assert_json "Has 'created' event" "j.data?.some(e=>e.event_type==='created')" "$R"
assert_json "Has 'approved' event" "j.data?.some(e=>e.event_type==='approved')" "$R"

# ==========================================
echo ""
echo "--- 21. UNREAD COUNT ---"
R=$(curl -s "$BASE/api/van-ban-den/chua-doc/count" -H "$AUTH")
assert_json "Unread count API works" "j.success===true && typeof j.data?.count==='number'" "$R"

# ==========================================
echo ""
echo "--- 22. BULK MARK READ ---"
R=$(curl -s -X PATCH "$BASE/api/van-ban-den/danh-dau-da-doc" -H "$AUTH" -H 'Content-Type: application/json' \
  -d "{\"doc_ids\":[$DOC2,$DOC3]}")
assert_json "Bulk mark read" "j.success===true" "$R"

# ==========================================
echo ""
echo "--- 23. RECEIVE PAPER ---"
R=$(curl -s -X PATCH "$BASE/api/van-ban-den/$DOC1/nhan-ban-giay" -H "$AUTH")
assert_json "Receive paper" "j.success===true" "$R"
R=$(curl -s "$BASE/api/van-ban-den/$DOC1" -H "$AUTH")
assert_json "Doc 1 is_received_paper=true" "j.data?.is_received_paper===true" "$R"

# ==========================================
echo ""
echo "--- 24. DELETE (unapproved doc) ---"
R=$(curl -s -X DELETE "$BASE/api/van-ban-den/$DOC3" -H "$AUTH")
assert_json "Delete unapproved doc 3" "j.success===true" "$R"

R=$(curl -s "$BASE/api/van-ban-den?page=1&page_size=10" -H "$AUTH")
assert_json "List now has 2 docs" "j.pagination?.total===2" "$R"

# ==========================================
echo ""
echo "--- 25. NEXT NUMBER (after creates) ---"
R=$(curl -s "$BASE/api/van-ban-den/so-den-tiep-theo?doc_book_id=$BOOK_ID" -H "$AUTH")
assert_json "Next number > 1" "j.data?.number>1" "$R"

# ==========================================
echo ""
echo "=========================================="
echo " RESULTS: $PASS passed / $FAIL failed / $TOTAL total"
echo "=========================================="
if [ $FAIL -eq 0 ]; then
  echo " 🎉 ALL TESTS PASSED!"
else
  echo " ⚠️  Some tests failed"
fi
