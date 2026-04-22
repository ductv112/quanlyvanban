---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
stopped_at: Completed 12-01-PLAN.md — BE endpoint download + sidebar submenu (1/3 of Phase 12)
last_updated: "2026-04-22T09:42:00.852Z"
last_activity: 2026-04-22
progress:
  total_phases: 13
  completed_phases: 11
  total_plans: 57
  completed_plans: 54
  percent: 95
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-04-21 — Milestone v2.0 started)

**Core value:** Luồng văn bản đến → xử lý → văn bản đi phải hoạt động đúng nghiệp vụ cơ quan nhà nước
**Current focus:** Phase 12 — Menu Ký số + Danh sách 4 tab UI

## Current Position

Phase: 12 (Menu Ký số + Danh sách 4 tab UI) — EXECUTING
Plan: 2 of 3
Next: Plan 11.1-03 — move 18 file migrations cũ → archive/, update deploy scripts + dev onboarding README dùng schema/ + seed/ flow
Status: Ready to execute
Last activity: 2026-04-22

Progress: [██████████] 98% (53/54 plans complete — 11 phases Complete + Phase 11.1 2/3)

## Performance Metrics

**Velocity (v1.0 baseline):**

- Total plans completed (v1.0): 26
- v1.0 duration: 4 days (2026-04-14 → 2026-04-18)
- v1.0 achievement: 7 phases + 3 quick plans, 97.8% HDSD coverage (92 test cases)

**v2.0 tracking:** Reset — metrics populated as plans complete

**v2.0 planned phases (Phase 8-14):**

| Phase | Title | REQ count | Dependency |
|-------|-------|-----------|------------|
| 8 | Schema foundation + PDF signing layer | 5 | — (v1.0 shipped) |
| 9 | Admin config + provider adapters | 7 | Phase 8 |
| 10 | User config page + migrate tab | 3 | Phase 9 |
| 11 | Sign flow + async worker (core) | 12 | Phase 10 |
| 12 | Menu Ký số + Danh sách 4 tab UI | 7 | Phase 11 |
| 13 | Modal ký số robust + Root CA UX | 6 | Phase 12 |
| 14 | Deployment + HDSD + verification | 2 | Phase 13 |

**Total: 42 REQ-IDs (100% coverage, no orphans)**
| Phase 08 P01 | 25min | 2 tasks | 1 files |
| Phase 08 P02 | 10min | 1 tasks | 1 files |
| Phase 08 P03 | 12min | 2 tasks | 3 files |
| Phase 08 P04 | 5min | 2 tasks | 5 files |
| Phase 09 P01 | 10min | 3 tasks | 6 files |
| Phase 09 P02 | 4min | 3 tasks | 3 files |
| Phase 10 P01 | 4min | 2 tasks | 2 files |
| Phase 10 P02 | 45min | 3 tasks | 2 files |
| Phase 10 P03 | 10min | 1 tasks | 1 files |
| Phase 11 P01 | 5min | 2 tasks | 3 files |
| Phase 11 P02 | 4min | 2 tasks | 4 files |
| Phase 11 P03 | 7min | 3 tasks | 3 files |
| Phase 11 P04 | 8min | 3 tasks | 4 files |
| Phase 11 P05 | 7min | 3 tasks | 4 files |
| Phase 11 P06 | 5min | 3 tasks | 4 files |
| Phase 11 P07 | 4min | 3 tasks | 2 files |
| Phase 11 P08 | 3min | 2 tasks | 1 files |
| Phase 11.1 P01 | 11min | 3 tasks | 4 files |
| Phase 11.1 P02 | 8min | 3 tasks | 2 files |
| Phase 12 P01 | 4min | 2 tasks | 2 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.

**Key v2.0 decisions (2026-04-21):**

- 1 provider active cho toàn hệ thống (không multi song song) — đơn giản support/billing
- Pure JS PDF signing với `node-signpdf` + `node-forge` — không cần Java/DotNet runtime
- Async decoupled worker (BullMQ poll 5s × max 3 phút) — user tắt UI vẫn ký OK
- Menu "Ký số" riêng ở sidebar với 3 submenu — tập trung quản lý ký số
- 2 cấp cấu hình: Admin (provider + credentials) → User (user_id + cert)
- Test connection bắt buộc khi Admin lưu config
- Lưu `sign_provider_code` vào attachments + transactions để đổi provider không mất lịch sử
- Migration `staff.sign_phone` → table mới `staff_signing_config` (multi-provider schema)
- Root CA Viettel: KHÔNG code trong hệ thống, chỉ show banner link + HDSD PDF + `.cer` file
- Ký lại sau fail: tạo transaction MỚI (giữ record cũ cho audit), không reset record cũ

**Roadmap decisions (2026-04-21):**

- Phase granularity: coarse (7 phases cho 42 REQs — trung bình 6 REQs/phase)
- Phase 8 = foundation (schema + generic PDF layer) không có UI → giúp downstream không block bởi UI changes
- Phase 11 là phase lớn nhất (12 REQs) nhưng coherent: toàn bộ core sign flow + async worker phải ship cùng lúc để user test được end-to-end
- Phase 14 tách riêng deployment để ensure HDSD + seed scripts không bị quên cuối milestone
- [Phase 08]: BYTEA client_secret forces Node-side pgp_sym_encrypt at boundary (plaintext column rejected)
- [Phase 08]: Partial unique index on is_active=TRUE gives database-level single-active provider guarantee (vs trigger)
- [Phase 08]: attachment_type enum includes handling (4 values) to match plan's ALTER of attachment_handling_docs
- [Phase 08]: [Phase 08-02]: Data migration DO block pattern — info_schema guard + EXECUTE dynamic SQL + ON CONFLICT DO NOTHING + target>=source verify + RAISE EXCEPTION rollback — re-runnable forever
- [Phase 08]: [Phase 08-02]: Keep sign_ca + sign_image in staff table — out of scope MIG-04; sign_ca for UI cert subject display, sign_image for PDF stamp
- [Phase 08]: PrecomputedSigner pattern — extend @signpdf/utils.Signer to embed external provider signatures without local key access
- [Phase 08]: pdf-lib requires useObjectStreams:false for compatibility with @signpdf/placeholder-plain (classic xref only)
- [Phase 08]: Use Node builtin test runner (node:test via tsx) for signing unit tests — no jest/vitest dependency added
- [Phase 08]: [Phase 08-04]: SIGNING_SECRET_KEY fail-fast validation (throw on unset/<16 chars) — no weak default to avoid accidental production ship
- [Phase 08]: [Phase 08-04]: Wave 2 rule caught SP drift — pg_get_function_result() revealed fn_sign_transaction_increment_retry returns new_retry_count (plan had stale retry_count). Repository interface fixed before runtime bug.
- [Phase 09]: [Phase 09-01]: Node fetch thay vì axios — backend package.json không có axios (frontend-only), Node 18+ fetch + AbortController đủ cho JSON POST timeout
- [Phase 09]: [Phase 09-01]: HttpClient interface + DI factory — tests inject mock qua create*Provider(httpClient?), production dùng singleton với default fetch wrapper
- [Phase 09]: [Phase 09-01]: Stateless MySign adapter (no token cache) — fresh login every call prevents race in Phase 11 multi-concurrency BullMQ worker
- [Phase 09]: [Phase 09-01]: SmartCA getSignStatus là POST (không GET) — Model.cs Query() helper hardcode POST, plan draft sai method
- [Phase 09]: [Phase 09-02]: Migration 042 (not 041) — plan draft had stale number, 041 already used by migrate_sign_phone in Phase 8 (Rule 3 auto-fix)
- [Phase 09]: [Phase 09-02]: Mount /api/ky-so/cau-hinh BEFORE /api/ky-so generic — longer-prefix-wins pattern preserves requireRoles admin guard without leaking to digital-signature mock routes
- [Phase 09]: [Phase 09-02]: GET /cau-hinh returns skeleton rows for never-configured providers — UI loops both codes uniformly, no client-side merge
- [Phase 10]: [Phase 10-01]: staffId luôn từ JWT (req.user.staffId), KHÔNG từ body — mitigate T-10-01 Tampering cho user-level signing config
- [Phase 10]: [Phase 10-01]: Verify fail = HTTP 200 với verified:false (không 500) — cert-not-found là business outcome, không phải server error; FE parse data.verified flag thống nhất
- [Phase 10]: [Phase 10-01]: Mount /api/ky-so/tai-khoan riêng với authenticate-only (không requireRoles) BEFORE /api/ky-so generic — longer-prefix-wins tách biệt admin guard khỏi user endpoint
- [Phase 10]: [Phase 10-02]: Form-mount guard setTimeout(0) setFieldsValue — tránh AntD warning 'useForm not connected' khi active=null Form chưa render
- [Phase 10]: [Phase 10-02]: Label 'Xác thực tài khoản ký số' thay 'Kiểm tra kết nối' — action thực tế là verify mã định danh qua API provider, không test connection đơn thuần; mapping 1:1 với badge 'Đã xác thực'
- [Phase 10]: [Phase 10-02]: Group sidebar KÝ SỐ visible cho MỌI user (restructure từ admin-only) — push group header unconditionally, chỉ wrap submenu 'Cấu hình hệ thống' trong if (isAdmin); scale tốt cho Phase 12 UX-01 thêm submenu 'Danh sách ký số'
- [Phase 10]: [Phase 10-03]: Migration UI pattern — giữ Tabs 2 tab rename 'Chữ ký số' → 'Ảnh chữ ký' + Alert pointer với Next.js Link sang /ky-so/tai-khoan; KHÔNG hard redirect vì sign_image upload vẫn là functionality hợp lệ ở trang này
- [Phase 11]: [Phase 11-01]: GET DIAGNOSTICS ROW_COUNT thay FOUND — FOUND là special variable PL/pgSQL, không phải DIAGNOSTICS item; multi-branch UPDATE SP cần v_rows INT capture riêng mỗi branch
- [Phase 11]: [Phase 11-01]: Permission check fn_attachment_can_sign bao gồm cả approver (không chỉ signer) — outgoing/drafting có 2 field VARCHAR signer+approver; approver trình-ký cũng cần ký được theo legacy .NET flow
- [Phase 11]: [Phase 11-01]: Admin bypass kép — EXISTS(role 'Quản trị hệ thống') OR staff.is_admin TRUE; cover cả role-based và legacy flag-based admin
- [Phase 11]: [Phase 11-01]: doc_label compose trong SP (CASE theo doc_type) — FE Phase 12 render 1 query = 1 row hiển thị, giảm latency và loại bỏ client-side join 4 attachment × 4 doc tables
- [Phase 11]: [Phase 11-02]: Lazy-singleton getSigningQueue() — import không bị Redis ping, tests/CI không cần Redis
- [Phase 11]: [Phase 11-02]: Separate Worker connection createRedisConnection() — BullMQ v5 yêu cầu Worker exclusive BLPOP, Producer shared singleton OK
- [Phase 11]: [Phase 11-02]: Manual retry via re-enqueue (attempts:1) — exact 5s × 36 attempts aligned expires_at, không exponential backoff
- [Phase 11]: [Phase 11-02]: jobId=poll-{txnId}-{attempt} — BullMQ dedupe mitigates T-11-06 double-enqueue DoS không cần app-level lock
- [Phase 11]: [Phase 11-03]: MinIO placeholder store (prefix 'signing-placeholders/{txnId}.pdf') thay Redis — PDF placeholder ~200KB+ quá lớn cho Redis; MinIO đã có trong stack + key deterministic theo txnId
- [Phase 11]: [Phase 11-03]: DB transaction tạo TRƯỚC provider.signHash — cần txnId làm documentId provider echo back + làm placeholder key; rollback via updateStatus(failed) + removePlaceholder nếu signHash throw
- [Phase 11]: [Phase 11-03]: PLACEHOLDER_PREFIX exported để route + Plan 04 worker dùng cùng constant — không hardcode string ở 2 nơi, không drift
- [Phase 11]: [Phase 11-03]: Mount /api/ky-so/sign TRƯỚC /api/ky-so catch-all (longer-prefix-wins); authenticate only (không requireRoles) — mọi user có quyền đều ký được
- [Phase 11]: [Phase 11-04]: Manual re-enqueue (attempts:1) vs BullMQ auto-retry — exact 5s × 36 attempts aligned với sign_transactions.expires_at
- [Phase 11]: [Phase 11-04]: handleFailure + rescheduleOrExpire helpers consolidate 7+ failure branches — sửa logic 1 chỗ áp dụng tất cả call sites
- [Phase 11]: [Phase 11-04]: Short-circuit DB re-read mỗi job — mitigate T-11-13 Redis tampering; attacker inject job cho txn cancelled = no-op
- [Phase 11]: [Phase 11-04]: Graceful shutdown order stopSigningWorker → closeSigningQueue → closeRedisConnection với failsafe setTimeout(10s).unref() — tránh hang forever nhưng không block event loop
- [Phase 11]: [Phase 11-04]: noticeRepository.createForStaff dùng fn_notice_create (unit-wide) + notice_type=SIGN_RESULT — pragmatic v2.0 không migration mới; trade-off unit members thấy notice vì rare events + title có tên user
- [Phase 11]: [Phase 11-06]: .tsx extension cho hook (không .ts) — renderSignModal return JSX bắt buộc .tsx; Rule 3 auto-fix 15 TS errors
- [Phase 11]: [Phase 11-06]: AntD 6 Modal destroyOnHidden (không destroyOnClose deprecated) + width (không size — size chỉ Drawer)
- [Phase 11]: [Phase 11-06]: successFired useRef guard — onSuccess fire exactly once dù polling + Socket cả 2 nhận completed (mitigate double-refresh parent list)
- [Phase 11]: [Phase 11-06]: onSuccessRef pattern (ngoài state) cho useSigning — caller inline arrow không trigger re-render loop
- [Phase 11]: [Phase 11-06]: Đóng (chạy nền) KHÔNG auto-cancel txn — worker tiếp tục poll + bell notification fallback cho Socket miss
- [Phase 11]: Plan 07: Migrate VB đi + VB dự thảo detail pages sang useSigning hook. Pure migration — remove mock OTP state + /ky-so/mock/sign, thay bằng openSign() + renderSignModal(). Net -108/+26 lines. Breaking change MIG-05: 2/3 pages done (HSCV pending Plan 11-09).
- [Phase 11]: Plan 11-08: HSCV Ký số button — first-time integration (không phải migration). canSignHandling gate = signer_id === user.staffId + status ∈ {2,3}. attachmentType='handling' lần đầu có FE consumer.
- [Phase 11.1]: [Plan 11.1-01]: pg_dump --schema-only + node transform script thay merge thủ công 25K dòng SQL — auto-capture all SP signatures, reduce risk mất SP hoặc conflict constraint.
- [Phase 11.1]: [Plan 11.1-01]: DROP ALL fn_* functions loop ở Phần 3 master schema — zero maintenance khi thêm SP mới; thay thế band-aid `quick_260418_zz_cleanup_duplicates.sql`.
- [Phase 11.1]: [Plan 11.1-01]: ADD CONSTRAINT DO block catch 4 SQLSTATE codes (42710 duplicate_object, 42P07 duplicate_table, 42P16 invalid_table_definition cho multiple PKs, 42701 duplicate_column) — idempotent re-apply tested trên dev DB.
- [Phase 11.1]: [Plan 11.1-01]: SET client_min_messages = notice trước final DO block — pg_dump set warning suppress NOTICE, cần reset để 'Schema v2.0 applied OK' hiển thị.
- [Phase 11.1]: [Plan 11.1-01]: Loại trừ 041 data migration + 043 seed khỏi master; Plan 02 sẽ tạo seed riêng. Final state DB không có staff.sign_phone.
- [Phase 11.1]: [Plan 11.1-02]: Tách 2 file seed (001 required + 002 demo) thay vì 1 file mono seed_full_demo.sql — production chỉ chạy 001, dev/test chạy cả 2; production-safe không có TRUNCATE/DELETE.
- [Phase 11.1]: [Plan 11.1-02]: DO block guard ở đầu seed 002 — RAISE EXCEPTION rõ ràng nếu seed 001 chưa chạy (check admin user + root dept), tránh lỗi FK khó debug giữa chừng.
- [Phase 11.1]: [Plan 11.1-02]: Session variable app.signing_secret_key + RAISE EXCEPTION nếu length < 16 — fail-fast thay vì encrypt bằng NULL key rồi backend không decrypt được.
- [Phase 11.1]: [Plan 11.1-02]: generate_series + CASE + mod pattern cho bulk records phong phú — 50 VB đến trong 20 dòng code, dễ tăng/giảm số lượng; mix đầy đủ urgent/secret/type qua mod arithmetic.
- [Phase 11.1]: [Plan 11.1-02]: Schema column mismatch fix — plan giả định 6 cột không tồn tại trong bảng thực tế (user_incoming_docs/attachment_*/outgoing_docs/drafting_docs/handling_docs/inter_incoming_docs); đọc \d table trước khi INSERT là bắt buộc.
- [Phase 12]: [Plan 12-01]: GET /:id/download owner-or-admin bypass (khác cancel + GET /:id owner-only) — admin cần audit/support quyền truy cập file đã ký; dùng TokenPayload.isAdmin boolean từ JWT không cần DB query role
- [Phase 12]: [Plan 12-01]: file_name compute client-side từ segment cuối signed_file_path với prefix 'signed_' — không query thêm attachment table, trade-off tên hiển thị có thể là 'signed_txn-7-signed.pdf'
- [Phase 12]: [Plan 12-01]: Cache-Control: no-store header — ngăn browser/proxy cache URL HMAC presigned (T-12-06 mitigation), vì TTL 600s vẫn đủ leak window nếu cache response

### Pending Todos

- `/gsd-plan-phase 8` — lên kế hoạch chi tiết Phase 8 (schema foundation + PDF signing layer)
- Chuẩn bị docs reference cho Phase 9: đối chiếu code cũ `OneWin.WebApp/SmartCA_VNPT/Model.cs` (3 endpoints VNPT) và postman collection MySign Viettel (4 endpoints)

### Blockers/Concerns

- **SmartCA VNPT credentials thực tế**: client_id/secret trong source cũ (`Web.config`) có thể đã hết hạn hoặc cho dev env. Cần KH cấp credentials production khi triển khai.
- **MySign Viettel credentials**: chưa có — cần KH đăng ký với Viettel để lấy `client_id`, `client_secret`, `profile_id`.
- **Không test được ký thật** trong môi trường dev (không có số ĐT thật đăng ký SmartCA / không có app MySign). User đã confirm chấp nhận: code đầy đủ, test khi triển khai production.

### Reference Docs (v2.0)

- `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Tai lieu tich hop dich vu Mysign API+SDK v1.9.pdf` — MySign API spec
- `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/Viettel Mysign Gateway.postman_collection.json` — 4 API endpoints
- `docs/huong_dan_tich_hop_ky_so_MySign_Viettel/HUONG DAN CAI DAT CTS ROOT CA VIETTEL Mysign.pdf` — HDSD cài Root CA (cho end user)
- `docs/source_code_cu/sources/OneWin.WebApp/SmartCA_VNPT/Model.cs` — VNPT SmartCA reference implementation (3 endpoints, credentials trong Web.config)

### v1.0 Quick Tasks (archive reference)

v1.0 hoàn thành với 3 quick tasks (HDSD Compliance sprint cuối):

| # | Description | Commit |
|---|-------------|--------|
| 260418-gs7 | Phase 1 — ẩn các module chưa có trong HDSD cũ | 8afd6d7 |
| 260418-hlj | HDSD Compliance P0+P1 — SmartCA UI + thu hồi VB liên thông + HSCV mở lại/lấy số | f189464 |
| 260418-jsd | HDSD Compliance — fix 6 gap (ký số mock OTP + trục CP mock + ...) | 26caf2b |

## Session Continuity

Last session: 2026-04-22T09:42:00.841Z
Stopped at: Completed 12-01-PLAN.md — BE endpoint download + sidebar submenu (1/3 of Phase 12)
Resume: `/gsd-execute-phase 11.1` để tiếp tục Plan 11.1-02 (seed required data + rich demo data)
