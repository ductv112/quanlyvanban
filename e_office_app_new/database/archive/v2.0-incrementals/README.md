# Archive: v2.0 Incrementals (Phase 8-11)

## ⚠️ KHÔNG CHẠY FILE NÀO Ở ĐÂY

Thư mục này chứa các migration incremental của v2.0 Phase 8-11 — đã merge vào `database/schema/000_schema_v2.0.sql` trong Phase 11.1 (2026-04-22).

## File trong thư mục

- `040_signing_schema.sql` — Phase 8 Plan 01: 3 bảng signing + ALTER 4 attachment tables + 15 SPs
- `041_migrate_sign_phone.sql` — Phase 8 Plan 02: data migration `staff.sign_phone` → `staff_signing_config` (1 lần chạy, final state đã reflect trong master — bảng `staff` không còn column `sign_phone`)
- `042_signing_stats_sp.sql` — Phase 9 Plan 02: dashboard stats SP `fn_signing_provider_config_stats`
- `043_seed_default_providers.sql` — Phase 9 Plan 03: seed 2 provider rows (SmartCA VNPT + MySign Viettel). **MOVED** sang `seed/001_required_data.sql` ở Plan 11.1-02
- `045_sign_flow_attachment_helpers.sql` — Phase 11 Plan 01: 4 SPs (`fn_attachment_finalize_sign`, `fn_attachment_can_sign`, `fn_sign_transaction_list_by_staff`, `fn_sign_transaction_count_by_staff`)
- `046_sign_list_pending_docs.sql` — Phase 11 Plan 05: SP `fn_sign_need_list_by_staff` + `fn_sign_need_count_by_staff` (dashboard "Cần ký")

## Lưu ý về data migration (041)

`041_migrate_sign_phone.sql` là **data migration 1 lần chạy**:
- Source: `staff.sign_phone` column (VARCHAR)
- Target: `staff_signing_config` table (multi-provider schema)
- Sau migration: `ALTER TABLE staff DROP COLUMN sign_phone`

Trong master schema v2.0, bảng `staff` đã reflect **final state** — không còn column `sign_phone`. File này chỉ có giá trị lịch sử, không áp dụng cho DB mới.

## Khi thêm feature mới (sau Phase 11.1)

**KHÔNG thêm file `047_*.sql` hoặc `048_*.sql` vào folder này.**

Thay vào đó, edit trực tiếp `database/schema/000_schema_v2.0.sql` (hoặc bump version `000_schema_v2.1.sql` nếu milestone mới). Xem rules đầy đủ trong `CLAUDE.md` section **"DB Migration Strategy (v2.0+)"**.

## Nếu cần revert 1 migration cụ thể

Ví dụ revert Plan 11 Plan 05 để xem lại SP cũ `fn_sign_need_list_by_staff`:

```bash
# KHÔNG drop — chỉ đọc file để xem source code
cat 046_sign_list_pending_docs.sql
```

Sau đó edit `schema/000_schema_v2.0.sql` để fix/modify SP (tìm `CREATE OR REPLACE FUNCTION edoc.fn_sign_need_list_by_staff` block).

## Nguồn gốc

Xem `.planning/phases/11.1-db-consolidation-seed-strategy/11.1-01-SUMMARY.md` để biết chi tiết quá trình merge.
