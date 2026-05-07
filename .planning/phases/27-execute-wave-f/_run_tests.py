#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Wave f Boundary Tests - 27 TC for Auth/Notif/Admin modules."""
import sys, io, json, time, urllib.request, urllib.error, ssl

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

BASE = "http://localhost:4000/api"

def http(method, path, token=None, body=None):
    url = BASE + path
    data = json.dumps(body).encode('utf-8') if body is not None else None
    req = urllib.request.Request(url, data=data, method=method)
    req.add_header('Content-Type', 'application/json')
    if token:
        req.add_header('Authorization', f'Bearer {token}')
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, json.loads(resp.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        body_txt = e.read().decode('utf-8', errors='replace')
        try:
            body_json = json.loads(body_txt)
        except Exception:
            body_json = {'raw': body_txt}
        return e.code, body_json
    except Exception as e:
        return 0, {'error': str(e)}

def login(username, password):
    code, resp = http('POST', '/auth/login', body={'username': username, 'password': password})
    if code == 200 and resp.get('success'):
        return resp['data']['accessToken']
    print(f"LOGIN FAIL {username}: {code} {resp}")
    return None

print("=== Login admin + test_canbo ===")
TOK_AD = login('admin', 'Admin@123')
TOK_CB = login('test_canbo', 'Test@123')
print(f"admin token: {'OK' if TOK_AD else 'FAIL'}")
print(f"test_canbo token: {'OK' if TOK_CB else 'FAIL'}")

# Get user ids for password change tests
code, me_ad = http('GET', '/auth/me', token=TOK_AD)
ADMIN_ID = me_ad['data']['staffId']
code, me_cb = http('GET', '/auth/me', token=TOK_CB)
CB_ID = me_cb['data']['staffId']
print(f"admin id={ADMIN_ID}, test_canbo id={CB_ID}")

results = []  # list of (id, status, note)

def report(tc_id, expected_pass, actual_status, actual_msg, expected_desc):
    """expected_pass: True=should succeed, False=should reject."""
    status_pass = (actual_status in (200, 201))
    if expected_pass == status_pass:
        verdict = 'PASS'
    else:
        verdict = 'FAIL'
    note = f"HTTP {actual_status} | {str(actual_msg)[:120]}"
    results.append((tc_id, verdict, note, expected_desc))
    print(f"  [{verdict}] {tc_id}: {note}")

# ============================================================
# MODULE 0: AUTH - Đổi mật khẩu (6 TC)
# Endpoint: PATCH /quan-tri/nguoi-dung/:id/change-password
# Use test_canbo to avoid breaking admin login
# ============================================================
print("\n=== AUTH (6 TC) ===")
PWD_CB_CURRENT = 'Test@123'

# TC-BND-AUTH-001: Đổi mật khẩu mới đúng 6 ký tự (chứa hoa + số) - biên dưới
# Body: oldPassword + newPassword. Test 'Abcd12' (6 chars, has upper + digit)
new_pw = 'Abcd12'
code, resp = http('PATCH', f'/quan-tri/nguoi-dung/{CB_ID}/change-password',
                  token=TOK_AD, body={'oldPassword': PWD_CB_CURRENT, 'newPassword': new_pw})
# Note: Route also requires lowercase letter (regex includes [a-z])
expected_desc = "Mật khẩu 6 ký tự + chữ hoa + chữ thường + số → SUCCESS"
report('TC-BND-AUTH-001', True, code, resp.get('message') or resp.get('data'), expected_desc)
if code == 200:
    PWD_CB_CURRENT = new_pw

# TC-BND-AUTH-002: Đổi mật khẩu mới chỉ 5 ký tự - dưới biên
code, resp = http('PATCH', f'/quan-tri/nguoi-dung/{CB_ID}/change-password',
                  token=TOK_AD, body={'oldPassword': PWD_CB_CURRENT, 'newPassword': 'Abc12'})
expected_desc = "Mật khẩu 5 ký tự → REJECT 400"
report('TC-BND-AUTH-002', False, code, resp.get('message'), expected_desc)

# TC-BND-AUTH-003: 6 ký tự nhưng KHÔNG có chữ hoa
code, resp = http('PATCH', f'/quan-tri/nguoi-dung/{CB_ID}/change-password',
                  token=TOK_AD, body={'oldPassword': PWD_CB_CURRENT, 'newPassword': 'abcd12'})
expected_desc = "6 ký tự, không có chữ hoa → REJECT"
report('TC-BND-AUTH-003', False, code, resp.get('message'), expected_desc)

# TC-BND-AUTH-004: 6 ký tự nhưng KHÔNG có số
code, resp = http('PATCH', f'/quan-tri/nguoi-dung/{CB_ID}/change-password',
                  token=TOK_AD, body={'oldPassword': PWD_CB_CURRENT, 'newPassword': 'AbcDef'})
expected_desc = "6 ký tự, không có số → REJECT"
report('TC-BND-AUTH-004', False, code, resp.get('message'), expected_desc)

# TC-BND-AUTH-005: Mật khẩu mới trùng mật khẩu cũ
code, resp = http('PATCH', f'/quan-tri/nguoi-dung/{CB_ID}/change-password',
                  token=TOK_AD, body={'oldPassword': PWD_CB_CURRENT, 'newPassword': PWD_CB_CURRENT})
expected_desc = "Mật khẩu mới = cũ → REJECT 'không được trùng'"
report('TC-BND-AUTH-005', False, code, resp.get('message'), expected_desc)

# TC-BND-AUTH-006: Xác nhận lại không khớp
# NOTE: Backend chỉ nhận oldPassword + newPassword. Logic confirm chỉ trên FRONTEND.
# Skip backend test, mark SKIP-FE-ONLY
results.append(('TC-BND-AUTH-006', 'SKIP', 'Backend không có field confirmPassword - chỉ FE validate', 'FE-only check'))
print("  [SKIP] TC-BND-AUTH-006: confirmPassword check chỉ tồn tại trên frontend (Form rule)")

# Restore test_canbo password back to original Test@123
if PWD_CB_CURRENT != 'Test@123':
    code, resp = http('PATCH', f'/quan-tri/nguoi-dung/{CB_ID}/change-password',
                      token=TOK_AD, body={'oldPassword': PWD_CB_CURRENT, 'newPassword': 'Test@123'})
    print(f"  [restore] test_canbo password back to Test@123: HTTP {code}")

# ============================================================
# MODULE 1: NOTICES (Thông báo nội bộ) - 4 TC
# Endpoint: POST /thong-bao
# Body: { title, content, notice_type }
# DB: edoc.notices.title VARCHAR(300) (route validates > 300)
# ============================================================
print("\n=== NOTICES (4 TC) ===")

# TC-BND-NOTIF-001: Tiêu đề 200 ký tự (TC says limit is 200, but DB allows 300)
title_200 = 'A' * 200
content_x = 'Nội dung thông báo test boundary'
code, resp = http('POST', '/thong-bao', token=TOK_AD,
                  body={'title': title_200, 'content': content_x, 'notice_type': 'system'})
expected_desc = "title = 200 ký tự (DB VARCHAR(300) nên OK) → SUCCESS"
report('TC-BND-NOTIF-001', True, code, resp.get('message') or resp.get('data'), expected_desc)

# TC-BND-NOTIF-002: Tiêu đề 201 ký tự (TC says reject; but DB is 300, route validates > 300)
title_201 = 'B' * 201
code, resp = http('POST', '/thong-bao', token=TOK_AD,
                  body={'title': title_201, 'content': content_x, 'notice_type': 'system'})
# CRITICAL: TC expects reject at 201 but DB+route allow up to 300
# So actual server will SUCCESS (201). Mark as schema-mismatch
expected_desc = "TC giả định DB=200, thực tế DB=300 + route limit=300 → server CHẤP NHẬN 201 ký tự"
status_pass = (code in (200, 201))
if status_pass:
    # This is a TC vs schema mismatch, log as INFO/BUG-like
    results.append(('TC-BND-NOTIF-002', 'FAIL', f'HTTP {code} - server accept 201 chars (DB=VARCHAR(300), route limit=300, TC giả định 200)', expected_desc))
    print(f"  [FAIL] TC-BND-NOTIF-002: server accept 201 chars; TC expectation outdated (DB=300 not 200)")
else:
    results.append(('TC-BND-NOTIF-002', 'PASS', f'HTTP {code} - {resp.get("message")}', expected_desc))
    print(f"  [PASS] TC-BND-NOTIF-002: rejected as expected")

# Bonus: test 301 chars (true overflow)
title_301 = 'C' * 301
code301, resp301 = http('POST', '/thong-bao', token=TOK_AD,
                         body={'title': title_301, 'content': content_x, 'notice_type': 'system'})
print(f"    [bonus] 301 chars: HTTP {code301} - {resp301.get('message')}")

# TC-BND-NOTIF-003: Tiêu đề 1 ký tự
code, resp = http('POST', '/thong-bao', token=TOK_AD,
                  body={'title': 'A', 'content': content_x, 'notice_type': 'system'})
expected_desc = "title = 1 ký tự → SUCCESS (no min length)"
report('TC-BND-NOTIF-003', True, code, resp.get('message') or resp.get('data'), expected_desc)

# TC-BND-NOTIF-004: Nội dung 5000 ký tự
content_5000 = 'X' * 5000
code, resp = http('POST', '/thong-bao', token=TOK_AD,
                  body={'title': 'TB nội dung dài 5000', 'content': content_5000, 'notice_type': 'system'})
expected_desc = "content = 5000 ký tự (TEXT) → SUCCESS"
report('TC-BND-NOTIF-004', True, code, resp.get('message') or resp.get('data'), expected_desc)

# ============================================================
# MODULE 7: ĐỒN VỊ (departments) - 10 TC
# Endpoint: POST /quan-tri/don-vi
# DB: code VARCHAR(50), name VARCHAR(200), name_en VARCHAR(200), abb_name VARCHAR(20), phone VARCHAR(20), email VARCHAR(100)
# ============================================================
print("\n=== DEPARTMENTS (10 TC) ===")

import random
def uniq_suffix():
    return f"{int(time.time())}{random.randint(100,999)}"

created_dept_ids = []

# TC-BND-QTDV-001: code 50 ký tự
code_50 = ('TC1' + 'X' * 47)[:50]
body = {'code': code_50, 'name': 'Đơn vị test biên 50', 'parent_id': 1}
code, resp = http('POST', '/quan-tri/don-vi', token=TOK_AD, body=body)
expected_desc = "code = 50 ký tự (đúng biên VARCHAR(50)) → SUCCESS"
report('TC-BND-QTDV-001', True, code, resp.get('message') or resp.get('data'), expected_desc)
if code == 201:
    created_dept_ids.append(resp['data']['id'])

# TC-BND-QTDV-002: code 51 ký tự
code_51 = ('TC2' + 'X' * 48)[:51]
assert len(code_51) == 51
body = {'code': code_51, 'name': 'Đơn vị test biên 51', 'parent_id': 1}
code, resp = http('POST', '/quan-tri/don-vi', token=TOK_AD, body=body)
expected_desc = "code = 51 ký tự → REJECT (overflow VARCHAR(50))"
report('TC-BND-QTDV-002', False, code, resp.get('message'), expected_desc)

# TC-BND-QTDV-003: name 200 ký tự + name_en 200 ký tự
name_200 = ('Đơn vị ' + 'A' * 200)[:200]
name_en_200 = ('Unit ' + 'B' * 200)[:200]
body = {'code': 'TC3-' + uniq_suffix(), 'name': name_200, 'name_en': name_en_200, 'parent_id': 1}
code, resp = http('POST', '/quan-tri/don-vi', token=TOK_AD, body=body)
expected_desc = "name=200, name_en=200 → SUCCESS"
report('TC-BND-QTDV-003', True, code, resp.get('message') or resp.get('data'), expected_desc)
if code == 201:
    created_dept_ids.append(resp['data']['id'])

# TC-BND-QTDV-004: abb_name 20 ký tự
abb_20 = 'X' * 20
body = {'code': 'TC4-' + uniq_suffix(), 'name': 'Đơn vị abb 20', 'abb_name': abb_20, 'parent_id': 1}
code, resp = http('POST', '/quan-tri/don-vi', token=TOK_AD, body=body)
expected_desc = "abb_name = 20 ký tự (biên trên VARCHAR(20)) → SUCCESS"
report('TC-BND-QTDV-004', True, code, resp.get('message') or resp.get('data'), expected_desc)
if code == 201:
    created_dept_ids.append(resp['data']['id'])

# TC-BND-QTDV-005: abb_name 21 ký tự
abb_21 = 'Y' * 21
body = {'code': 'TC5-' + uniq_suffix(), 'name': 'Đơn vị abb 21', 'abb_name': abb_21, 'parent_id': 1}
code, resp = http('POST', '/quan-tri/don-vi', token=TOK_AD, body=body)
expected_desc = "abb_name = 21 ký tự → REJECT (overflow VARCHAR(20))"
report('TC-BND-QTDV-005', False, code, resp.get('message'), expected_desc)

# TC-BND-QTDV-006: phone hợp lệ với ký tự đặc biệt
phone_20 = '+84-(24)-1234-5678'  # 18 chars
body = {'code': 'TC6-' + uniq_suffix(), 'name': 'Đơn vị phone special', 'phone': phone_20, 'parent_id': 1}
code, resp = http('POST', '/quan-tri/don-vi', token=TOK_AD, body=body)
expected_desc = "phone format hợp lệ (số/+/-/space/parens) → SUCCESS"
report('TC-BND-QTDV-006', True, code, resp.get('message') or resp.get('data'), expected_desc)
if code == 201:
    created_dept_ids.append(resp['data']['id'])

# TC-BND-QTDV-007: phone chứa chữ cái (NOTE: backend không validate format - chỉ FE)
phone_invalid = '0912abc678'
body = {'code': 'TC7-' + uniq_suffix(), 'name': 'Đơn vị phone xấu', 'phone': phone_invalid, 'parent_id': 1}
code, resp = http('POST', '/quan-tri/don-vi', token=TOK_AD, body=body)
expected_desc = "TC expect reject; backend không validate phone format → BACKEND CHẤP NHẬN (FE-only validation)"
status_pass = (code in (200, 201))
if status_pass:
    results.append(('TC-BND-QTDV-007', 'FAIL', f'HTTP {code} - backend không có format validation, chấp nhận "0912abc678"', expected_desc))
    print(f"  [FAIL] TC-BND-QTDV-007: backend chấp nhận phone xấu - validation chỉ ở FE")
else:
    report('TC-BND-QTDV-007', False, code, resp.get('message'), expected_desc)

# TC-BND-QTDV-008: email 100 ký tự hợp lệ
# Build email <= 100 chars: aaaaa...@x.com
local = 'a' * 91  # 91 + '@x.com' (6) = 97 chars
email_100 = local + '@x.com'  # 97 chars - within 100
assert len(email_100) <= 100
body = {'code': 'TC8-' + uniq_suffix(), 'name': 'Đơn vị email 100', 'email': email_100, 'parent_id': 1}
code, resp = http('POST', '/quan-tri/don-vi', token=TOK_AD, body=body)
expected_desc = f"email = {len(email_100)} ký tự, format OK → SUCCESS"
report('TC-BND-QTDV-008', True, code, resp.get('message') or resp.get('data'), expected_desc)
if code == 201:
    created_dept_ids.append(resp['data']['id'])

# TC-BND-QTDV-009: email không hợp lệ (thiếu @)
email_bad = 'abc.gmail.com'
body = {'code': 'TC9-' + uniq_suffix(), 'name': 'Đơn vị email xấu', 'email': email_bad, 'parent_id': 1}
code, resp = http('POST', '/quan-tri/don-vi', token=TOK_AD, body=body)
expected_desc = "TC expect reject; backend không validate email format → BACKEND CHẤP NHẬN (FE-only)"
status_pass = (code in (200, 201))
if status_pass:
    results.append(('TC-BND-QTDV-009', 'FAIL', f'HTTP {code} - backend không validate email format, chấp nhận "abc.gmail.com"', expected_desc))
    print(f"  [FAIL] TC-BND-QTDV-009: backend chấp nhận email xấu - validation chỉ ở FE")
    if code == 201:
        created_dept_ids.append(resp['data']['id'])
else:
    report('TC-BND-QTDV-009', False, code, resp.get('message'), expected_desc)

# TC-BND-QTDV-010: lgsp_system_id 50 + lgsp_secret_key 100
# Note: route /don-vi không nhận lgsp_system_id/lgsp_secret_key trong body destructure!
# Check if these fields are accepted
lgsp_sys = 'L' * 50
lgsp_sec = 'S' * 100
body = {'code': 'TC10-' + uniq_suffix(), 'name': 'Đơn vị LGSP', 'lgsp_system_id': lgsp_sys, 'lgsp_secret_key': lgsp_sec, 'parent_id': 1}
code, resp = http('POST', '/quan-tri/don-vi', token=TOK_AD, body=body)
expected_desc = "lgsp_system_id=50 + lgsp_secret_key=100 → field bị bỏ qua (route không destructure) nhưng dept tạo OK"
report('TC-BND-QTDV-010', True, code, resp.get('message') or resp.get('data'), expected_desc)
if code == 201:
    created_dept_ids.append(resp['data']['id'])
    # Verify if LGSP fields were saved
    new_id = resp['data']['id']
    code2, resp2 = http('GET', f'/quan-tri/don-vi/{new_id}', token=TOK_AD)
    if code2 == 200:
        det = resp2.get('data', {})
        saved_sys = det.get('lgsp_system_id')
        saved_sec = det.get('lgsp_secret_key')
        if not saved_sys and not saved_sec:
            print(f"    [BUG-F-LGSP] Route POST /don-vi không lưu lgsp_system_id/lgsp_secret_key (không có trong destructure)")

# ============================================================
# MODULE 8: CHỨC VỤ (positions) - 4 TC
# Endpoint: POST /quan-tri/chuc-vu
# DB: name VARCHAR(100) NOT NULL, code VARCHAR(20)
# ============================================================
print("\n=== POSITIONS (4 TC) ===")

# TC-BND-QTCV-001: name 100 ký tự
name_100 = 'C' * 100
body = {'name': name_100, 'code': 'PCV-' + uniq_suffix()[:14]}
code, resp = http('POST', '/quan-tri/chuc-vu', token=TOK_AD, body=body)
expected_desc = "name = 100 ký tự (biên trên VARCHAR(100)) → SUCCESS"
report('TC-BND-QTCV-001', True, code, resp.get('message') or resp.get('data'), expected_desc)

# TC-BND-QTCV-002: name 101 ký tự
name_101 = 'D' * 101
body = {'name': name_101, 'code': 'PCV2-' + uniq_suffix()[:13]}
code, resp = http('POST', '/quan-tri/chuc-vu', token=TOK_AD, body=body)
expected_desc = "name = 101 ký tự → REJECT (overflow VARCHAR(100))"
report('TC-BND-QTCV-002', False, code, resp.get('message'), expected_desc)

# TC-BND-QTCV-003: code 20 ký tự
code_20 = 'P' * 20
body = {'name': 'Chức vụ test code 20', 'code': code_20}
code, resp = http('POST', '/quan-tri/chuc-vu', token=TOK_AD, body=body)
expected_desc = "code = 20 ký tự (biên trên VARCHAR(20)) → SUCCESS"
report('TC-BND-QTCV-003', True, code, resp.get('message') or resp.get('data'), expected_desc)

# TC-BND-QTCV-004: name rỗng (NOT NULL)
body = {'name': '', 'code': 'PCV4-' + uniq_suffix()[:13]}
code, resp = http('POST', '/quan-tri/chuc-vu', token=TOK_AD, body=body)
expected_desc = "name rỗng → REJECT 'Tên chức vụ là bắt buộc'"
report('TC-BND-QTCV-004', False, code, resp.get('message'), expected_desc)

# ============================================================
# MODULE 10: NHÓM QUYỀN (roles) - 3 TC
# Endpoint: POST /quan-tri/nhom-quyen, PUT /:id/quyen
# DB: name VARCHAR(100) - test wants 200 char (overflow)
# ============================================================
print("\n=== ROLES (3 TC) ===")

# TC-BND-QTNQ-001: name 200 ký tự (DB là VARCHAR(100) → expected fail!)
name_200_role = 'R' * 200
body = {'name': name_200_role, 'description': 'Test boundary'}
code, resp = http('POST', '/quan-tri/nhom-quyen', token=TOK_AD, body=body)
expected_desc = "TC says 200 chars OK, nhưng DB roles.name=VARCHAR(100) → SERVER REJECT (TC outdated)"
status_pass = (code in (200, 201))
if status_pass:
    report('TC-BND-QTNQ-001', True, code, resp.get('message') or resp.get('data'), expected_desc)
else:
    # Mark as FAIL because TC expected SUCCESS but actual schema only allows 100
    results.append(('TC-BND-QTNQ-001', 'FAIL', f'HTTP {code} - DB roles.name=VARCHAR(100), TC giả định 200 lỗi schema', expected_desc))
    print(f"  [FAIL] TC-BND-QTNQ-001: DB chỉ cho phép 100 ký tự, TC outdated assumption")
# Bonus test name=100 chars
body100 = {'name': 'R' * 100, 'description': 'biên 100'}
c100, r100 = http('POST', '/quan-tri/nhom-quyen', token=TOK_AD, body=body100)
print(f"    [bonus] name=100 chars: HTTP {c100} - {r100.get('message') or 'OK'}")
new_role_id = r100.get('data', {}).get('id') if c100 == 201 else None

# TC-BND-QTNQ-002: Gán 0 quyền cho nhóm
if new_role_id:
    code, resp = http('PUT', f'/quan-tri/nhom-quyen/{new_role_id}/quyen', token=TOK_AD, body={'rightIds': []})
    expected_desc = "Gán 0 quyền (rightIds=[]) → TC chấp nhận OK hoặc reject 'phải chọn 1+'"
    report('TC-BND-QTNQ-002', True, code, resp.get('message') or resp.get('data'), expected_desc)
else:
    results.append(('TC-BND-QTNQ-002', 'SKIP', 'Không tạo được role để test', 'depends on QTNQ-001 bonus'))
    print(f"  [SKIP] TC-BND-QTNQ-002: không có role_id để gán")

# TC-BND-QTNQ-003: Gán TẤT CẢ quyền
# Get all rights
code, resp = http('GET', '/quan-tri/chuc-nang/tree', token=TOK_AD)
all_right_ids = []
def flatten(nodes):
    for n in nodes:
        if 'id' in n:
            all_right_ids.append(n['id'])
        if n.get('children'):
            flatten(n['children'])
if code == 200 and resp.get('success'):
    flatten(resp['data'])
print(f"    [info] Tổng số quyền: {len(all_right_ids)}")

if new_role_id and all_right_ids:
    code, resp = http('PUT', f'/quan-tri/nhom-quyen/{new_role_id}/quyen', token=TOK_AD, body={'rightIds': all_right_ids})
    expected_desc = f"Gán TẤT CẢ ({len(all_right_ids)}) quyền → SUCCESS"
    report('TC-BND-QTNQ-003', True, code, resp.get('message') or resp.get('data'), expected_desc)
else:
    results.append(('TC-BND-QTNQ-003', 'SKIP', f'role_id={new_role_id}, rights={len(all_right_ids)}', 'precondition fail'))
    print(f"  [SKIP] TC-BND-QTNQ-003: precondition fail")

# Cleanup created role
if new_role_id:
    code, resp = http('DELETE', f'/quan-tri/nhom-quyen/{new_role_id}', token=TOK_AD)
    print(f"  [cleanup] DELETE role {new_role_id}: HTTP {code}")

# Cleanup departments
print(f"\n=== Cleanup {len(created_dept_ids)} departments ===")
for dept_id in created_dept_ids:
    code, _ = http('DELETE', f'/quan-tri/don-vi/{dept_id}', token=TOK_AD)
    print(f"  DELETE dept {dept_id}: HTTP {code}")

# ============================================================
# Summary
# ============================================================
print(f"\n{'='*60}")
print("SUMMARY")
print(f"{'='*60}")
counters = {'PASS':0, 'FAIL':0, 'SKIP':0}
for r in results:
    counters[r[1]] = counters.get(r[1], 0) + 1
print(f"Total: {len(results)} | PASS: {counters['PASS']} | FAIL: {counters['FAIL']} | SKIP: {counters['SKIP']}")

# Save results
with open('D:/ProjectAI/quanlyvanban/.planning/phases/27-execute-wave-f/_results.json', 'w', encoding='utf-8') as f:
    json.dump({
        'total': len(results),
        'pass': counters['PASS'],
        'fail': counters['FAIL'],
        'skip': counters['SKIP'],
        'cases': [{'id': r[0], 'verdict': r[1], 'note': r[2], 'expected': r[3]} for r in results],
    }, f, ensure_ascii=False, indent=2)
print("Saved _results.json")
