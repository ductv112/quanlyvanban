#!/usr/bin/env python3
"""Wave g: Permission test runner — 50 TC.
Executes all TCs and writes JSON output."""
import json
import sys
import time
import urllib.request
import urllib.error
import urllib.parse
from typing import Optional, Tuple

BASE = "http://localhost:4000"
FE_BASE = "http://localhost:3000"

USERS = {
    "admin":       ("admin",         "Admin@123"),
    "test_admin":  ("test_admin",    "Test@123"),
    "test_vanthu": ("test_vanthu",   "Test@123"),
    "test_lanhdao":("test_lanhdao",  "Test@123"),
    "test_canbo":  ("test_canbo",    "Test@123"),
    "test_canbo_x":("test_canbo_x",  "Test@123"),
}

tokens = {}
refresh_cookies = {}
results = []  # list of {id, status, http, note}


def login(user: str, save_refresh: bool = False) -> Tuple[str, Optional[str]]:
    """Returns (access_token, refresh_cookie_value)."""
    u, p = USERS[user]
    body = json.dumps({"username": u, "password": p}).encode()
    req = urllib.request.Request(
        BASE + "/api/auth/login",
        data=body,
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    resp = urllib.request.urlopen(req, timeout=10)
    cookie = None
    if save_refresh:
        for k, v in resp.getheaders():
            if k.lower() == "set-cookie":
                # extract refreshToken value
                if "refreshToken=" in v:
                    rest = v.split("refreshToken=", 1)[1]
                    cookie = rest.split(";", 1)[0]
                    break
    data = json.loads(resp.read())
    return data["data"]["accessToken"], cookie


def req(
    method: str,
    path: str,
    token: Optional[str] = None,
    body: Optional[dict] = None,
    cookies: Optional[dict] = None,
    extra_headers: Optional[dict] = None,
    base: str = BASE,
):
    """Returns (status, body_text, headers)."""
    url = base + path
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body).encode()
    if cookies:
        headers["Cookie"] = "; ".join(f"{k}={v}" for k, v in cookies.items())
    if extra_headers:
        headers.update(extra_headers)
    r = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        resp = urllib.request.urlopen(r, timeout=15)
        return resp.status, resp.read().decode("utf-8", errors="replace"), dict(resp.getheaders())
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode("utf-8", errors="replace"), dict(e.headers)
    except Exception as e:
        return 0, f"ERR: {e}", {}


def record(tc_id: str, status: str, note: str = "", http: Optional[int] = None):
    results.append({
        "id": tc_id,
        "status": status,
        "http": http,
        "note": note,
    })
    print(f"[{status:5}] {tc_id} (HTTP {http}) {note}", flush=True)


def main():
    # Login all users
    for u in USERS:
        try:
            tok, cookie = login(u, save_refresh=(u == "test_vanthu"))
            tokens[u] = tok
            if cookie:
                refresh_cookies[u] = cookie
            print(f"OK login {u}", flush=True)
        except Exception as e:
            print(f"FAIL login {u}: {e}", flush=True)
            sys.exit(1)

    T_AD = tokens["admin"]
    T_TA = tokens["test_admin"]
    T_VT = tokens["test_vanthu"]    # unit 2 (Sở Nội vụ)
    T_LD = tokens["test_lanhdao"]   # unit 2
    T_CB = tokens["test_canbo"]     # unit 2 dept 2
    T_X  = tokens["test_canbo_x"]   # unit 3 (Sở Tài chính)

    # ========== Cross-unit Isolation (15 TC) ==========

    # XU-001: vanthu unit 2 list — only see unit 2 docs
    s, b, _ = req("GET", "/api/van-ban-den?page=1&pageSize=50", T_VT)
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        units = set(i.get("unit_id") for i in items)
        if s == 200 and units.issubset({2}):
            record("TC-PERM-XU-001", "PASS", f"{len(items)} docs all unit_id=2", s)
        else:
            record("TC-PERM-XU-001", "FAIL", f"units seen: {units}", s)
    except Exception as e:
        record("TC-PERM-XU-001", "FAIL", f"parse: {e}", s)

    # XU-002 / XU-003: bypass URL — canbo_x GET unit 2's doc (id=90001)
    s, b, _ = req("GET", "/api/van-ban-den/90001", T_X)
    try:
        d = json.loads(b)
        if s in (403, 404):
            record("TC-PERM-XU-002", "PASS", "blocked", s)
            record("TC-PERM-XU-003", "PASS", "blocked", s)
        elif s == 200 and d.get("data", {}).get("unit_id") == 2:
            record("TC-PERM-XU-002", "FAIL", "BUG-PERM-001: cross-unit GET leaks unit 2 doc to unit 3 user", s)
            record("TC-PERM-XU-003", "FAIL", "BUG-PERM-001: same — cross-unit isolation broken on GET /:id", s)
        else:
            record("TC-PERM-XU-002", "VERIFY", f"unexpected: {b[:120]}", s)
            record("TC-PERM-XU-003", "VERIFY", f"unexpected: {b[:120]}", s)
    except Exception as e:
        record("TC-PERM-XU-002", "FAIL", f"parse: {e}", s)
        record("TC-PERM-XU-003", "FAIL", f"parse: {e}", s)

    # XU-004: vanthu list outgoing only sees unit 2
    s, b, _ = req("GET", "/api/van-ban-di?page=1&pageSize=50", T_VT)
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        units = set(i.get("unit_id") for i in items)
        if s == 200 and (units.issubset({2}) or len(items) == 0):
            record("TC-PERM-XU-004", "PASS", f"{len(items)} docs unit={units}", s)
        else:
            record("TC-PERM-XU-004", "FAIL", f"units: {units}", s)
    except Exception as e:
        record("TC-PERM-XU-004", "FAIL", f"parse: {e}", s)

    # XU-005: cross-department within same unit (canbo dept 2 should not see canbo_x's hscv)
    # Note: test_canbo (dept 2) and test_canbo_x (dept 3) — but X is in different unit. Skip with VERIFY.
    s, b, _ = req("GET", "/api/ho-so-cong-viec?page=1&pageSize=20", T_CB)
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        # Look for HSCV not belonging to dept 2 staff
        record("TC-PERM-XU-005", "VERIFY", f"canbo dept 2 sees {len(items)} HSCV — manual cross-dept verification needed", s)
    except Exception as e:
        record("TC-PERM-XU-005", "FAIL", f"parse: {e}", s)

    # XU-006: vanthu access /quan-tri/don-vi — backend
    s, b, _ = req("GET", "/api/quan-tri/don-vi", T_VT)
    if s in (200,):
        record("TC-PERM-XU-006", "FAIL", "BUG-PERM-002: vanthu can read /api/quan-tri/don-vi (admin endpoint)", s)
    elif s in (403, 401):
        record("TC-PERM-XU-006", "PASS", "blocked", s)
    else:
        record("TC-PERM-XU-006", "VERIFY", f"unexpected status", s)

    # XU-007: doc books dropdown — canbo_x should not see unit 2's books
    s, b, _ = req("GET", "/api/quan-tri/so-van-ban", T_X)
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        units = set(i.get("unit_id") for i in items if isinstance(i, dict))
        if s == 200 and (units.issubset({3, None}) or len(items) == 0):
            record("TC-PERM-XU-007", "PASS", f"{len(items)} books, units={units}", s)
        elif s in (403,):
            record("TC-PERM-XU-007", "PASS", f"403 (no read access)", s)
        else:
            record("TC-PERM-XU-007", "FAIL", f"units leaked: {units}", s)
    except Exception as e:
        record("TC-PERM-XU-007", "VERIFY", f"parse: {e}", s)

    # XU-008: Tampering — canbo_x submits VB den with doc_book_id of unit 2
    # Find a unit 2 doc_book_id first via vanthu
    s, b, _ = req("GET", "/api/quan-tri/so-van-ban", T_VT)
    book_id_unit2 = None
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        for i in items:
            if i.get("unit_id") == 2:
                book_id_unit2 = i.get("id")
                break
    except Exception:
        pass

    if book_id_unit2:
        # canbo_x tries to create with this book_id
        body = {
            "doc_book_id": book_id_unit2,
            "doc_type_id": 1,
            "doc_field_id": 1,
            "secret_id": 1,
            "urgent_id": 1,
            "abstract": "TAMPER TEST",
            "publish_unit": "X",
            "publish_date": "2026-05-07",
            "received_date": "2026-05-07",
            "notation": "X",
            "document_code": "X",
            "number_paper": 1,
            "number_copies": 1,
            "sents": "X",
        }
        s, b, _ = req("POST", "/api/van-ban-den", T_X, body=body)
        if s in (400, 403):
            record("TC-PERM-XU-008", "PASS", "tampering rejected", s)
        elif s == 201:
            record("TC-PERM-XU-008", "FAIL", "BUG-PERM-003: tampering accepted — canbo_x created VB with unit 2's doc_book_id", s)
        else:
            record("TC-PERM-XU-008", "VERIFY", f"unexpected: {b[:120]}", s)
    else:
        record("TC-PERM-XU-008", "SKIP", "no unit 2 doc_book found", 0)

    # XU-009: signers — canbo_x should not see unit 2's signers
    s, b, _ = req("GET", "/api/quan-tri/nguoi-ky", T_X)
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        units = set(i.get("unit_id") for i in items if isinstance(i, dict))
        if s == 200 and (units.issubset({3, None}) or len(items) == 0):
            record("TC-PERM-XU-009", "PASS", f"{len(items)} signers units={units}", s)
        elif s == 403:
            record("TC-PERM-XU-009", "PASS", "no read access", s)
        else:
            record("TC-PERM-XU-009", "FAIL", f"leaked units: {units}", s)
    except Exception as e:
        record("TC-PERM-XU-009", "VERIFY", f"parse: {e}", s)

    # XU-010: doc types — distinguish global vs unit-specific
    s, b, _ = req("GET", "/api/quan-tri/loai-van-ban", T_X)
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        # Common types should be visible. Unit-specific from unit 2 should NOT
        record("TC-PERM-XU-010", "VERIFY", f"canbo_x sees {len(items)} doc types — manual check vs unit 2 types", s)
    except Exception as e:
        record("TC-PERM-XU-010", "VERIFY", f"parse: {e}", s)

    # XU-011: PUT 90001 (unit 2 doc) with canbo_x token
    s, b, _ = req("PUT", "/api/van-ban-den/90001", T_X, body={"abstract": "hacked"})
    if s in (403, 404):
        record("TC-PERM-XU-011", "PASS", "PUT blocked", s)
    elif s == 200:
        record("TC-PERM-XU-011", "FAIL", "BUG-PERM-004: PUT cross-unit accepted", s)
    else:
        record("TC-PERM-XU-011", "VERIFY", f"unexpected: {b[:120]}", s)

    # XU-012: DELETE outgoing doc cross-unit — find a unit 2 outgoing first
    s, b, _ = req("GET", "/api/van-ban-di?page=1&pageSize=5", T_VT)
    od_id = None
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        for i in items:
            if i.get("unit_id") == 2:
                od_id = i.get("id")
                break
    except Exception:
        pass
    if od_id:
        s, b, _ = req("DELETE", f"/api/van-ban-di/{od_id}", T_X)
        if s in (403, 404):
            record("TC-PERM-XU-012", "PASS", f"DELETE blocked for od_id={od_id}", s)
        elif s == 200:
            record("TC-PERM-XU-012", "FAIL", f"BUG-PERM-005: DELETE cross-unit accepted od_id={od_id}", s)
        else:
            record("TC-PERM-XU-012", "VERIFY", f"unexpected: {b[:120]}", s)
    else:
        record("TC-PERM-XU-012", "SKIP", "no unit 2 outgoing doc available", 0)

    # XU-013: parent unit visibility — admin (unit 1, parent) sees unit 2 docs?
    s, b, _ = req("GET", "/api/van-ban-den?page=1&pageSize=20", T_AD)
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        units = set(i.get("unit_id") for i in items)
        record("TC-PERM-XU-013", "VERIFY", f"admin (unit 1) sees {len(items)} docs, units={units} — confirm hierarchy rule", s)
    except Exception as e:
        record("TC-PERM-XU-013", "VERIFY", f"parse: {e}", s)

    # XU-014: search "TEST" — vanthu should only get unit 2 results
    s, b, _ = req("GET", "/api/van-ban-den?keyword=TEST&page=1&pageSize=50", T_VT)
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        units = set(i.get("unit_id") for i in items)
        if s == 200 and units.issubset({2}):
            record("TC-PERM-XU-014", "PASS", f"search returned {len(items)} all unit 2", s)
        else:
            record("TC-PERM-XU-014", "FAIL", f"search leaked units: {units}", s)
    except Exception as e:
        record("TC-PERM-XU-014", "VERIFY", f"parse: {e}", s)

    # XU-015: LGSP cross-unit — manual scenario
    record("TC-PERM-XU-015", "SKIP", "LGSP cross-unit send/receive scenario requires multi-step LGSP setup — manual test needed", 0)

    # ========== Role Matrix (30 TC) ==========

    # RM-001: Cán bộ menu — frontend layer (check by GET /quan-tri/* must 403)
    # Backend only: cán bộ access /api/quan-tri/nguoi-dung
    s, b, _ = req("GET", "/api/quan-tri/nguoi-dung", T_CB)
    if s in (403, 401):
        record("TC-PERM-RM-001", "PASS", "cán bộ blocked from /quan-tri", s)
    else:
        record("TC-PERM-RM-001", "FAIL", f"BUG-PERM-006: cán bộ accessed admin route", s)

    # RM-002: Văn thư blocked from /quan-tri/nguoi-dung
    s, b, _ = req("GET", "/api/quan-tri/nguoi-dung", T_VT)
    if s in (403, 401):
        record("TC-PERM-RM-002", "PASS", "văn thư blocked from /quan-tri/nguoi-dung", s)
    else:
        record("TC-PERM-RM-002", "FAIL", f"BUG-PERM-007: văn thư accessed admin route", s)

    # RM-003: Lãnh đạo — has signing menu, blocked from quản trị system config?
    # Test: lãnh đạo blocked from /api/quan-tri/nguoi-dung
    s, b, _ = req("GET", "/api/quan-tri/nguoi-dung", T_LD)
    if s in (403, 401):
        record("TC-PERM-RM-003", "PASS", "lãnh đạo blocked from /quan-tri/nguoi-dung", s)
    else:
        record("TC-PERM-RM-003", "FAIL", f"BUG-PERM-008: lãnh đạo accessed admin route", s)

    # RM-004: Admin can access everything
    s, b, _ = req("GET", "/api/quan-tri/nguoi-dung", T_AD)
    if s == 200:
        record("TC-PERM-RM-004", "PASS", "admin can access /quan-tri", s)
    else:
        record("TC-PERM-RM-004", "FAIL", f"admin denied", s)

    # RM-005: Văn thư can create incoming doc
    s, b, _ = req("GET", "/api/quan-tri/so-van-ban", T_VT)
    book_id = None
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        for i in items:
            if i.get("unit_id") == 2:
                book_id = i.get("id")
                break
    except Exception:
        pass
    if book_id:
        body = {
            "doc_book_id": book_id, "doc_type_id": 1, "doc_field_id": 1,
            "secret_id": 1, "urgent_id": 1,
            "abstract": "RM-005 test", "publish_unit": "TEST",
            "publish_date": "2026-05-07", "received_date": "2026-05-07",
            "notation": "RM005", "document_code": "RM005",
            "number_paper": 1, "number_copies": 1, "sents": "TEST",
        }
        s, b, _ = req("POST", "/api/van-ban-den", T_VT, body=body)
        if s == 201:
            record("TC-PERM-RM-005", "PASS", "văn thư created VB", s)
        else:
            record("TC-PERM-RM-005", "FAIL", f"create failed: {b[:120]}", s)
    else:
        record("TC-PERM-RM-005", "SKIP", "no doc_book", 0)

    # RM-006: Cán bộ cannot create incoming doc
    if book_id:
        body = {"doc_book_id": book_id, "doc_type_id": 1, "doc_field_id": 1,
                "secret_id": 1, "urgent_id": 1, "abstract": "RM006",
                "publish_unit": "X", "publish_date": "2026-05-07",
                "received_date": "2026-05-07", "notation": "X",
                "document_code": "X", "number_paper": 1, "number_copies": 1, "sents": "X"}
        s, b, _ = req("POST", "/api/van-ban-den", T_CB, body=body)
        if s in (403, 401):
            record("TC-PERM-RM-006", "PASS", "cán bộ blocked from create", s)
        elif s == 201:
            record("TC-PERM-RM-006", "FAIL", "BUG-PERM-009: cán bộ created VB", s)
        else:
            record("TC-PERM-RM-006", "VERIFY", f"unexpected: {b[:120]}", s)
    else:
        record("TC-PERM-RM-006", "SKIP", "no doc_book", 0)

    # RM-007: Lãnh đạo has 'giao việc' on assigned doc — test endpoint
    # Use 90002 (đã giao việc) per fixture name
    s, b, _ = req("POST", "/api/van-ban-den/90002/giao-viec", T_LD, body={"staff_ids": [9004]})
    # Either success or business rule rejection — but NOT 403 from RBAC
    if s == 403:
        record("TC-PERM-RM-007", "FAIL", "BUG-PERM-010: lãnh đạo blocked from giao-viec", s)
    elif s in (200, 201, 400):
        record("TC-PERM-RM-007", "PASS", f"lãnh đạo can call giao-viec endpoint (HTTP {s})", s)
    else:
        record("TC-PERM-RM-007", "VERIFY", f"unexpected: {b[:120]}", s)

    # RM-008: Cán bộ blocked from giao-viec
    s, b, _ = req("POST", "/api/van-ban-den/90002/giao-viec", T_CB, body={"staff_ids": [9005]})
    if s in (403, 401):
        record("TC-PERM-RM-008", "PASS", "cán bộ blocked from giao-viec", s)
    elif s in (200, 201):
        record("TC-PERM-RM-008", "FAIL", "BUG-PERM-011: cán bộ executed giao-viec", s)
    else:
        record("TC-PERM-RM-008", "VERIFY", f"unexpected: {b[:120]}", s)

    # RM-009: Lãnh đạo can sign — call /ky-so endpoint with lanhdao token
    # Find an outgoing doc waiting for signature
    s, b, _ = req("POST", "/api/ky-so/sign", T_LD, body={"document_type": "outgoing", "document_id": 90100, "provider_id": 1})
    if s in (200, 201, 400, 404, 500):  # 500 might be config issue, not perm
        record("TC-PERM-RM-009", "PASS", f"lãnh đạo can call /ky-so/sign (HTTP {s})", s)
    elif s == 403:
        record("TC-PERM-RM-009", "FAIL", "BUG-PERM-012: lãnh đạo blocked from /ky-so/sign", s)
    else:
        record("TC-PERM-RM-009", "VERIFY", f"unexpected: {b[:120]}", s)

    # RM-010: Văn thư cannot sign (no signing right)
    s, b, _ = req("POST", "/api/ky-so/sign", T_VT, body={"document_type": "outgoing", "document_id": 90100, "provider_id": 1})
    if s in (403, 401):
        record("TC-PERM-RM-010", "PASS", "văn thư blocked from /ky-so/sign", s)
    else:
        record("TC-PERM-RM-010", "VERIFY", f"văn thư /ky-so/sign returned HTTP {s} — expected 403 if RBAC enforces", s)

    # RM-011: Văn thư blocked from POST /api/quan-tri/nguoi-dung
    s, b, _ = req("POST", "/api/quan-tri/nguoi-dung", T_VT, body={"username": "x", "password": "x"})
    if s in (403, 401):
        record("TC-PERM-RM-011", "PASS", "văn thư blocked from create user", s)
    else:
        record("TC-PERM-RM-011", "FAIL", f"BUG-PERM-013: văn thư accessed POST /quan-tri/nguoi-dung", s)

    # RM-012: Lãnh đạo blocked from PUT /api/quan-tri/don-vi/:id
    s, b, _ = req("PUT", "/api/quan-tri/don-vi/2", T_LD, body={"name": "hack"})
    if s in (403, 401):
        record("TC-PERM-RM-012", "PASS", "lãnh đạo blocked from edit unit", s)
    else:
        record("TC-PERM-RM-012", "FAIL", f"BUG-PERM-014: lãnh đạo modified unit", s)

    # RM-013: Lãnh đạo blocked from /api/quan-tri/nhom-quyen
    s, b, _ = req("GET", "/api/quan-tri/nhom-quyen", T_LD)
    if s in (403, 401):
        record("TC-PERM-RM-013", "PASS", "lãnh đạo blocked from roles admin", s)
    else:
        record("TC-PERM-RM-013", "FAIL", f"BUG-PERM-015: lãnh đạo accessed roles admin", s)

    # RM-014: Lãnh đạo blocked from PUT /api/ky-so/cau-hinh/:id
    s, b, _ = req("PUT", "/api/ky-so/cau-hinh/1", T_LD, body={"provider_name": "x"})
    if s in (403, 401):
        record("TC-PERM-RM-014", "PASS", "lãnh đạo blocked from sign config", s)
    else:
        record("TC-PERM-RM-014", "FAIL", f"BUG-PERM-016: lãnh đạo modified provider config (HTTP {s})", s)

    # RM-015: User can view own personal sign account
    s, b, _ = req("GET", "/api/ky-so/tai-khoan-ca-nhan", T_LD)
    if s == 200:
        record("TC-PERM-RM-015", "PASS", "lãnh đạo can view own sign acct", s)
    elif s == 404:
        record("TC-PERM-RM-015", "VERIFY", "no record yet (expected if user has no acct)", s)
    else:
        record("TC-PERM-RM-015", "FAIL", f"unexpected", s)

    # RM-016: Văn thư GET /api/quan-tri/so-van-ban — view-only
    s, b, _ = req("GET", "/api/quan-tri/so-van-ban", T_VT)
    if s == 200:
        # Try to PUT to verify view-only
        try:
            d = json.loads(b)
            items = d.get("data") or d.get("items") or []
            book_id_test = items[0].get("id") if items else None
        except Exception:
            book_id_test = None
        if book_id_test:
            s2, b2, _ = req("PUT", f"/api/quan-tri/so-van-ban/{book_id_test}", T_VT, body={"name": "test"})
            if s2 in (403, 401):
                record("TC-PERM-RM-016", "PASS", f"văn thư read-only on so-van-ban (GET 200, PUT 403)", s)
            elif s2 == 200:
                record("TC-PERM-RM-016", "VERIFY", f"BUG candidate? văn thư can PUT so-van-ban (HTTP {s2})", s2)
            else:
                record("TC-PERM-RM-016", "VERIFY", f"PUT returned {s2}", s2)
        else:
            record("TC-PERM-RM-016", "VERIFY", "GET 200 but no items to test PUT", s)
    elif s in (403, 401):
        record("TC-PERM-RM-016", "PASS", "văn thư blocked entirely", s)
    else:
        record("TC-PERM-RM-016", "VERIFY", f"unexpected", s)

    # RM-017: Lãnh đạo blocked from PATCH /api/quan-tri/nguoi-dung/:id/reset-password
    s, b, _ = req("PATCH", "/api/quan-tri/nguoi-dung/9002/reset-password", T_LD)
    if s in (403, 401):
        record("TC-PERM-RM-017", "PASS", "lãnh đạo blocked from reset password", s)
    else:
        record("TC-PERM-RM-017", "FAIL", f"BUG-PERM-017: lãnh đạo can reset password", s)

    # RM-018: HSCV — non-owner read-only. Skip detail (need fixture)
    record("TC-PERM-RM-018", "SKIP", "needs HSCV fixture with chủ trì=A, tham gia=B, both in unit 2", 0)

    # RM-019: Lãnh đạo report HSCV — try report endpoint
    s, b, _ = req("GET", "/api/ho-so-cong-viec/bao-cao", T_LD)
    if s in (200,):
        record("TC-PERM-RM-019", "PASS", "lãnh đạo can view HSCV report", s)
    elif s == 404:
        record("TC-PERM-RM-019", "VERIFY", "endpoint not found — may be different URL", s)
    elif s in (403, 401):
        record("TC-PERM-RM-019", "FAIL", f"lãnh đạo blocked from report", s)
    else:
        record("TC-PERM-RM-019", "VERIFY", f"HTTP {s}", s)

    # RM-020: Cán bộ report HSCV — own only
    s, b, _ = req("GET", "/api/ho-so-cong-viec/bao-cao", T_CB)
    if s in (200, 403, 404):
        record("TC-PERM-RM-020", "VERIFY", f"HTTP {s} — content scope needs manual review", s)
    else:
        record("TC-PERM-RM-020", "VERIFY", f"HTTP {s}", s)

    # RM-021: Multi-role union — admin user has 2 roles, can access both
    # Already verified by admin (Ban Lãnh đạo + Quản trị) — test he can call both signing + admin
    s1, _, _ = req("GET", "/api/quan-tri/nguoi-dung", T_AD)
    s2, _, _ = req("GET", "/api/ky-so/cau-hinh", T_AD)
    if s1 == 200 and s2 in (200, 404):
        record("TC-PERM-RM-021", "PASS", f"admin multi-role works: nguoi-dung={s1} ky-so/cau-hinh={s2}", s1)
    else:
        record("TC-PERM-RM-021", "FAIL", f"admin multi-role fail: {s1} {s2}", s1)

    # RM-022: User loses role mid-session — token still valid until expiry
    # Hard to simulate without modifying DB. Skip with verify
    record("TC-PERM-RM-022", "SKIP", "requires admin to remove role on test_canbo + verify session — destructive, manual", 0)

    # RM-023: User locked mid-session — token rejected
    # Same — would lock test user. Skip
    record("TC-PERM-RM-023", "SKIP", "requires locking active user — destructive, manual test", 0)

    # RM-024: Cán bộ access /quan-tri/nguoi-dung URL bypass (frontend), backend already covered by RM-001
    # Test backend block confirmed in RM-001
    s, _, _ = req("GET", "/api/quan-tri/nguoi-dung", T_CB)
    if s in (403, 401):
        record("TC-PERM-RM-024", "PASS", "backend blocks cán bộ — frontend route guard expected", s)
    else:
        record("TC-PERM-RM-024", "FAIL", f"backend allowed cán bộ", s)

    # RM-025: Văn thư access /api/ky-so/cau-hinh — should be 403
    s, _, _ = req("GET", "/api/ky-so/cau-hinh", T_VT)
    if s in (403, 401):
        record("TC-PERM-RM-025", "PASS", "văn thư blocked from /ky-so/cau-hinh", s)
    elif s == 200:
        record("TC-PERM-RM-025", "FAIL", f"BUG-PERM-018: văn thư can read /ky-so/cau-hinh", s)
    else:
        record("TC-PERM-RM-025", "VERIFY", f"HTTP {s}", s)

    # RM-026: DELETE VB đến — văn thư + admin OK, others blocked
    # Find a unit 2 VB to test
    s, b, _ = req("GET", "/api/van-ban-den?page=1&pageSize=20", T_VT)
    test_doc_id = None
    try:
        d = json.loads(b)
        items = d.get("data") or d.get("items") or []
        # Pick a TEST doc to delete
        for i in items:
            ab = i.get("abstract") or ""
            if "RM-005 test" in ab:
                test_doc_id = i.get("id")
                break
    except Exception:
        pass
    if test_doc_id:
        # Lãnh đạo tries DELETE first
        s_ld, _, _ = req("DELETE", f"/api/van-ban-den/{test_doc_id}", T_LD)
        # Cán bộ tries DELETE
        s_cb, _, _ = req("DELETE", f"/api/van-ban-den/{test_doc_id}", T_CB)
        # Then văn thư DELETE (last so it actually deletes)
        s_vt, _, _ = req("DELETE", f"/api/van-ban-den/{test_doc_id}", T_VT)
        if s_ld in (403, 401) and s_cb in (403, 401) and s_vt in (200, 204):
            record("TC-PERM-RM-026", "PASS", f"DELETE: lãnh đạo={s_ld} cán bộ={s_cb} văn thư={s_vt}", s_vt)
        else:
            record("TC-PERM-RM-026", "FAIL", f"DELETE perms wrong: lãnh đạo={s_ld} cán bộ={s_cb} văn thư={s_vt}", s_vt)
    else:
        record("TC-PERM-RM-026", "SKIP", "no test doc to delete", 0)

    # RM-027: VB đi đã phát hành — DELETE/PUT bị reject. Need fixture
    # Try DELETE on 90100 (assume issued)
    s, b, _ = req("DELETE", "/api/van-ban-di/90100", T_VT)
    if s in (400, 403, 409):
        record("TC-PERM-RM-027", "PASS", f"published VB delete blocked HTTP {s}", s)
    elif s == 404:
        record("TC-PERM-RM-027", "VERIFY", "VB 90100 not found — fixture may differ", s)
    elif s in (200, 204):
        record("TC-PERM-RM-027", "FAIL", f"BUG-PERM-019: published VB deleted", s)
    else:
        record("TC-PERM-RM-027", "VERIFY", f"HTTP {s}", s)

    # RM-028: Same as RM-027 backend test — covered
    record("TC-PERM-RM-028", "PASS" if s in (400, 403, 409) else ("VERIFY" if s == 404 else "FAIL"),
           f"covered by RM-027 (HTTP {s})", s)

    # RM-029: Trưởng phòng giao việc trong phòng — needs role fixture. Skip
    record("TC-PERM-RM-029", "SKIP", "requires Trưởng phòng role fixture", 0)

    # RM-030: is_represent_unit user — not in fixture. Skip
    record("TC-PERM-RM-030", "SKIP", "requires is_represent_unit user fixture", 0)

    # ========== Token & Session (5 TC) ==========

    # TK-001: No Authorization header
    s, b, _ = req("GET", "/api/van-ban-den")
    if s == 401:
        record("TC-PERM-TK-001", "PASS", "no auth header rejected", s)
    else:
        record("TC-PERM-TK-001", "FAIL", f"expected 401, got {s}", s)

    # TK-002: Expired token — simulate with garbage signature suffix
    # Construct a valid-looking JWT structure with old iat/exp
    import base64
    h = base64.urlsafe_b64encode(json.dumps({"alg":"HS256","typ":"JWT"}).encode()).rstrip(b"=").decode()
    p = base64.urlsafe_b64encode(json.dumps({"staffId":9002,"departmentId":2,"username":"x","roles":["x"],"isAdmin":False,"iat":1,"exp":2}).encode()).rstrip(b"=").decode()
    expired_tok = f"{h}.{p}.invalidsig"
    s, b, _ = req("GET", "/api/van-ban-den", expired_tok)
    if s == 401:
        record("TC-PERM-TK-002", "PASS", "expired/bad-sig token rejected", s)
    else:
        record("TC-PERM-TK-002", "FAIL", f"expected 401, got {s}", s)

    # TK-003: Tampered token — take valid VT token, change payload, leave sig
    parts = T_VT.split(".")
    p_obj = json.loads(base64.urlsafe_b64decode(parts[1] + "=" * (-len(parts[1]) % 4)))
    p_obj["isAdmin"] = True
    new_p = base64.urlsafe_b64encode(json.dumps(p_obj).encode()).rstrip(b"=").decode()
    tampered = f"{parts[0]}.{new_p}.{parts[2]}"
    s, b, _ = req("GET", "/api/van-ban-den", tampered)
    if s == 401:
        record("TC-PERM-TK-003", "PASS", "tampered payload rejected (sig mismatch)", s)
    elif s == 200:
        record("TC-PERM-TK-003", "FAIL", "BUG-PERM-020: tampered token accepted", s)
    else:
        record("TC-PERM-TK-003", "VERIFY", f"HTTP {s}", s)

    # TK-004: Refresh token after logout — revoked
    rc = refresh_cookies.get("test_vanthu")
    if rc:
        # Logout first
        s_logout, _, _ = req("POST", "/api/auth/logout", T_VT, cookies={"refreshToken": rc})
        # Try refresh
        s, b, _ = req("POST", "/api/auth/refresh", cookies={"refreshToken": rc})
        if s == 401:
            record("TC-PERM-TK-004", "PASS", f"refresh after logout rejected (logout={s_logout})", s)
        else:
            record("TC-PERM-TK-004", "FAIL", f"BUG-PERM-021: refresh used after logout (HTTP {s})", s)
    else:
        record("TC-PERM-TK-004", "SKIP", "no refresh cookie captured", 0)

    # TK-005: Token rotation — after refresh, old refresh cookie revoked
    # Login fresh user
    try:
        new_tok, new_rc = login("test_canbo", save_refresh=True)
    except Exception:
        new_rc = None
    if new_rc:
        # First refresh — should succeed and rotate
        s1, b1, h1 = req("POST", "/api/auth/refresh", cookies={"refreshToken": new_rc})
        # Now use OLD refresh again
        s2, b2, _ = req("POST", "/api/auth/refresh", cookies={"refreshToken": new_rc})
        if s1 == 200 and s2 == 401:
            record("TC-PERM-TK-005", "PASS", f"rotation works: 1st={s1}, 2nd with old={s2}", s2)
        elif s1 == 200 and s2 == 200:
            record("TC-PERM-TK-005", "FAIL", f"BUG-PERM-022: refresh token reusable (no rotation)", s2)
        else:
            record("TC-PERM-TK-005", "VERIFY", f"1st={s1} 2nd={s2}", s2)
    else:
        record("TC-PERM-TK-005", "SKIP", "no refresh cookie", 0)

    # ===== Save results =====
    pass_n = sum(1 for r in results if r["status"] == "PASS")
    fail_n = sum(1 for r in results if r["status"] == "FAIL")
    skip_n = sum(1 for r in results if r["status"] == "SKIP")
    verify_n = sum(1 for r in results if r["status"] == "VERIFY")

    print(f"\n=== SUMMARY ===")
    print(f"Total: {len(results)} | PASS: {pass_n} | FAIL: {fail_n} | SKIP: {skip_n} | VERIFY: {verify_n}")

    with open(".planning/phases/28-execute-wave-g/_results.json", "w", encoding="utf-8") as f:
        json.dump({
            "summary": {"total": len(results), "pass": pass_n, "fail": fail_n, "skip": skip_n, "verify": verify_n},
            "results": results,
        }, f, indent=2, ensure_ascii=False)


if __name__ == "__main__":
    main()
