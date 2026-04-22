# Archive: v1.0 Migrations

## ⚠️ KHÔNG CHẠY FILE NÀO Ở ĐÂY

Thư mục này chứa lịch sử migrations đã được merge vào `database/schema/000_schema_v2.0.sql` trong Phase 11.1 (2026-04-22).

## File trong thư mục

- `000_full_schema.sql` — consolidated schema v1.0 (Phase 1-7), 17,466 dòng
- `quick_260418_hlj_hscv.sql` — HDSD compliance: HSCV extensions
- `quick_260418_hlj_recall.sql` — HDSD compliance: recall feature
- `quick_260418_hlj_signature.sql` — HDSD compliance: signature SPs
- `quick_260418_jsd_hscv_cancel.sql` — bug fix: HSCV cancel
- `quick_260418_jsd_hscv_transfer.sql` — bug fix: HSCV transfer
- `quick_260418_jsd_opinion_forward.sql` — bug fix: opinion forward
- `quick_260418_jsd_sign_otp.sql` — mock sign OTP
- `quick_260418_jsd_truc_cp.sql` — trục CP mock
- `quick_260418_missing_helpers.sql` — 2 function helpers bị bỏ sót
- `quick_260418_restore_030_to_037.sql` — restore block (5,045 dòng)
- `quick_260418_zz_cleanup_duplicates.sql` — band-aid drop SP overload (đã loại bỏ trong master v2.0)
- `seed_full_demo.sql` — seed cũ v1.0 (replaced by `database/seed/001_required_data.sql` + `002_demo_data.sql`)

## Nếu cần revert về v1.0

Nếu schema master v2.0 bị lỗi, có thể tạm thời apply lại thứ tự cũ:

```bash
psql < 000_full_schema.sql
for f in quick_260418_hlj_*.sql quick_260418_jsd_*.sql; do psql < $f; done
psql < quick_260418_missing_helpers.sql
psql < quick_260418_restore_030_to_037.sql
psql < quick_260418_zz_cleanup_duplicates.sql  # BẮT BUỘC chạy CUỐI CÙNG
psql < seed_full_demo.sql
```

**Nhưng sẽ gặp lại các lỗi đã fix ở v2.0:**
- SP overload ambiguous (cần zz_cleanup_duplicates band-aid)
- Không có 2 provider config seeded (Phase 9)
- Seed trộn lẫn với schema (không tách production/demo)
- 6 migration v2.0 Phase 8-11 thiếu (ký số không hoạt động)

## Nguồn gốc

Xem `.planning/phases/11.1-db-consolidation-seed-strategy/` để biết lý do consolidate — đặc biệt `11.1-01-SUMMARY.md` liệt kê 82 tables + 373 functions sau khi merge.
