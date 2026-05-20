# Phase 33-02: Root Unit ↔ lgsp_org_code Mapping

**Queried:** 2026-05-20 từ DB `qlvb_dev` (môi trường local development)
**Status:** Dev DB seed cho khách hàng demo khác (UBND tỉnh Lào Cai), KHÔNG có 6 DN Lạng Sơn

## Root units tìm thấy trong departments (parent_id IS NULL)

| dept_id | code | name | short_name | match → lgsp_org_code |
|---------|------|------|------------|------------------------|
| 1 | UBND | UBND tỉnh Lào Cai | UBND | _(không match — đây là demo seed Lào Cai, không phải Lạng Sơn DN)_ |

**Tổng:** 1 root unit, 10 departments total

## Phân tích & Quyết định mapping

**Tình huống:** Dev DB hiện tại seed bằng `seed/002_demo_data.sql` cho mục đích demo workflow VB chính quyền cấp tỉnh (UBND + 4 sở + 5 phòng). Đây **KHÔNG phải** 6 DN Lạng Sơn target của Phase 33.

**Authorization (per executor context):** "Nếu dev DB có ZERO matching root units (dev is fresh seed without KH data), seed `lgsp_agency_config` rows with `unit_id` from the auto-created seed root units in `seed/002_demo_data.sql` — log assumption."

**Decision:** Seed SQL append vào `001_required_data.sql` viết theo pattern **lookup by `lgsp_org_code`** (đã có sẵn trong PLAN line 294-299):

```sql
SELECT id INTO v_unit_dn_001 FROM public.departments WHERE lgsp_org_code = 'H37.DN.001' AND parent_id IS NULL LIMIT 1;
```

→ Trên dev DB Lào Cai (không có DN nào có `lgsp_org_code` H37.DN.*): tất cả lookup sẽ trả NULL → INSERT skip với RAISE NOTICE → **0 row inserted** (đúng và an toàn).

→ Trên prod DB Lạng Sơn (khi KH setup 6 DN với code đúng): admin sẽ UPDATE `lgsp_org_code` cho 6 root DN unit → re-apply seed → 9 row insert đúng.

## Mapping cho 6 DN Lạng Sơn (DÙNG KHI KH SETUP PROD)

| lgsp_org_code | DN name (từ Excel) | dept_id trong dev DB | trạng thái dev seed |
|---------------|---------------------|----------------------|---------------------|
| H37.DN.001 | Cty CP Hữu nghị Xuân Cương | _(chưa có)_ | UPDATE skip + RAISE NOTICE |
| H37.DN.002 | Cty CP Sản xuất và Thương Mại Lạng Sơn | _(chưa có)_ | UPDATE skip + RAISE NOTICE |
| H37.DN.003 | Cty CP Tập đoàn ĐT & XD Phú Lộc | _(chưa có)_ | UPDATE skip + RAISE NOTICE |
| H37.DN.004 | Cty CP Kim loại màu Bắc Bộ | _(chưa có)_ | UPDATE skip + RAISE NOTICE |
| H37.DN.005 | Cty TNHH TM XD Thiên Phú | _(chưa có)_ | UPDATE skip + RAISE NOTICE |
| H37.DN.006 | Cty TNHH MTV Xe điện DK Việt Nhật | _(chưa có)_ | UPDATE skip + RAISE NOTICE |

## Seed SQL Adaptation Strategy

**Vấn đề:** PLAN gốc yêu cầu hard-code `{DEPT_ID_DN_001}..{DEPT_ID_DN_006}` trong UPDATE statement → cần biết dept_id thật. Trên dev DB hiện tại KHÔNG biết dept_id của 6 DN Lạng Sơn (chưa được tạo).

**Giải pháp adopted:** Đổi UPDATE statement từ "WHERE id = {hardcoded_id}" sang **"WHERE id = (SELECT id FROM departments WHERE code = 'H37.DN.001' AND parent_id IS NULL)"** hoặc match theo `name LIKE` keyword.

→ UPDATE statement **production-safe template**:
- Trên dev Lào Cai DB: 0 row affected → RAISE NOTICE → seed pass
- Trên prod Lạng Sơn DB (khi KH tạo 6 DN với name chuẩn): match được → UPDATE thành công → INSERT lgsp_agency_config 9 row

**Pattern UPDATE thay đổi:**
```sql
-- DN.001 — match by name keyword (case-insensitive, accent-insensitive nếu cần unaccent)
UPDATE public.departments
SET lgsp_org_code = 'H37.DN.001'
WHERE parent_id IS NULL
  AND (lgsp_org_code IS NULL OR lgsp_org_code = '')
  AND (name ILIKE '%Xuân Cương%' OR name ILIKE '%Xuan Cuong%');
```

## Production Setup Guide (KH triển khai)

Khi triển khai môi trường prod 6 DN Lạng Sơn, KH sẽ:

1. Insert 6 DN root unit vào `departments` (qua admin UI hoặc INSERT trực tiếp) — name chứa keyword đúng (VD: "Cty CP Hữu nghị Xuân Cương")
2. Re-apply `seed/001_required_data.sql` — UPDATE 6 statements match theo name keyword → UPDATE thành công → INSERT 9 row `lgsp_agency_config`
3. Admin vào UI `/ky-so/lgsp-config` (Phase 37) nhập `secret_key` thật → bật `is_active = TRUE`

Hoặc admin có thể UPDATE manual:
```sql
UPDATE departments SET lgsp_org_code='H37.DN.001' WHERE id={id_DN_xuan_cuong};
-- ... 5 statements tương tự cho DN.002..006
-- Sau đó re-apply seed/001 → 9 row tự insert
```

## Approved (auto-decision)

Per user delegation (executor context line "Auto-decide root_unit ↔ H37.DN.001..006 mapping based on name match or sequence"):

**Decision:** Dev DB không có 6 DN Lạng Sơn → seed sẽ apply nhưng không insert row nào (lookup trả NULL). Seed SQL viết theo pattern lookup-by-code/name → portable sang prod KH mà không cần edit. Document rõ trong SUMMARY để user verify khi KH setup prod.
