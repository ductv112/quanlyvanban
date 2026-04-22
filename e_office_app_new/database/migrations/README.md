# migrations/ folder

Thư mục này đã được **consolidate** vào `database/schema/000_schema_v2.0.sql` trong Phase 11.1 (2026-04-22).

## Cấu trúc mới

- **Current schema:** `database/schema/000_schema_v2.0.sql` — master idempotent (82 tables + 373 functions)
- **Current seeds:** `database/seed/001_required_data.sql` + `database/seed/002_demo_data.sql`
- **Archive:** `database/archive/v1.0-migrations/` + `database/archive/v2.0-incrementals/`

## Thêm migration mới

**KHÔNG thêm file `.sql` rời vào folder này.**

Thay vào đó, edit trực tiếp `database/schema/000_schema_v2.0.sql`:

1. Thêm `CREATE TABLE IF NOT EXISTS` ở phần Tables
2. Thêm `CREATE OR REPLACE FUNCTION` ở phần Functions
3. Nếu ALTER cột hiện có → inline vào CREATE TABLE gốc
4. Đảm bảo idempotent (DROP IF EXISTS trước CREATE cho SPs)

Xem rules đầy đủ trong `CLAUDE.md` section **"DB Migration Strategy (v2.0+)"**.

## Reset DB flow

```bash
# Linux
sudo bash deploy/reset-db.sh              # seed required + demo
sudo bash deploy/reset-db.sh --no-demo    # chỉ seed required (production-like)

# Windows (PowerShell Administrator)
.\deploy\reset-db-windows.ps1
.\deploy\reset-db-windows.ps1 -NoDemo
```

## Lý do consolidate

Xem `.planning/phases/11.1-db-consolidation-seed-strategy/` để hiểu đầy đủ:
- `11.1-01-SUMMARY.md` — master schema consolidation (20,168 dòng, loại bỏ SP overload)
- `11.1-02-SUMMARY.md` — seed 001 required + 002 demo tách bạch (312 records demo)
- `11.1-03-SUMMARY.md` — deploy scripts + archive + CLAUDE.md rules
