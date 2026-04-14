# Phase 6: Tich hop he thong ngoai - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Ket noi he thong e-Office voi 3 he thong ngoai: LGSP (lien thong van ban lien co quan), Ky so dien tu (VNPT SmartCA / EsignNEAC), va Thong bao da kenh (FCM / Zalo OA / SMS / Email). Sprint 14 + 15 + 16. Requirements: LGSP-01 -> LGSP-04, SIGN-01 -> SIGN-03, NOTIF-01 -> NOTIF-04.

Tat ca external APIs deu duoc MOCK cho demo cuoi tuan — code viet du interface de khi co credentials that chi can doi env.

</domain>

<decisions>
## Implementation Decisions

### Nguyen tac chung — BAT BUOC cho toan bo Phase 6
- **D-00a:** **PHAI tham chieu source code cu (.NET)** truoc khi implement bat ky module nao. Doc Controllers, Services, Stored Procedures cu de ap dung dung nghiep vu, flow, va ten truong du lieu.
- **D-00b:** **Quy uoc ten truong nghiem ngat** — SP tra ve dung ten cot DB (snake_case), KHONG rename/alias. Repository Row interface khop 1:1 voi SP output. Frontend copy tu Row interface.
- **D-00c:** **Mock + Interface san** — Tat ca external API (LGSP, SmartCA, NEAC, FCM, Zalo, SMS, Email) deu duoc mock. Moi service co interface rieng, mock implementation tra data gia + log. Env flag `MOCK_EXTERNAL=true` de toggle giua mock va real. Khi co credentials that chi can doi env, KHONG can sua code.
- **D-00d:** **Seed data toan bo** — Tao 1 script SQL lon: TRUNCATE toan bo -> seed lai tu dau (departments, staff, VB den, VB di, HSCV, lich, hop, kho luu tru, tai lieu, hop dong...) voi data lien ket chuan. Day la gan cuoi du an, can data chuan de test va demo.
- **D-00e:** **Migration DB chay truoc** — Tat ca migration phai chay thanh cong truoc khi viet backend/frontend.

### LGSP Lien thong (LGSP-01, LGSP-02, LGSP-03, LGSP-04)
- **D-01:** Mock toan bo LGSP — chua co credentials. Code backend viet du interface (OAuth2 token management cache Redis, edXML parsing, send/receive). Mock implementation tra data mau.
- **D-02:** Worker nhan VB tu LGSP — **tham khao source code cu (.NET)**. Neu source cu co polling thi lam polling (BullMQ repeatable job), neu khong co thi KHONG can lam muc nay.
- **D-03:** GUI VB di lien thong — **theo source code cu (.NET)**. Xem nut gui lien thong dat o dau, flow chon co quan dich, tracking trang thai.
- **D-04:** Dong bo danh sach co quan lien thong — **theo source code cu**. Mock tra danh sach co quan mau.

### Ky so dien tu (SIGN-01, SIGN-02, SIGN-03)
- **D-05:** Mock toan bo ky so — chua co credentials SmartCA/NEAC. Code viet du interface cho ca 2 phuong thuc.
- **D-06:** UI ky so — **theo source code cu (.NET)**. Xem nut ky so dat o dau (VB du thao? VB di?), flow chon phuong thuc ky, preview PDF, trang thai da ky.
- **D-07:** Mock signing flow — User click ky -> Modal chon phuong thuc -> mock OTP/xac thuc -> tra ket qua ky thanh cong + trang thai "Da ky" hien thi.

### Thong bao da kenh (NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04)
- **D-08:** Mock ca 4 kenh — FCM, Zalo OA, SMS, Email. Moi kenh co worker rieng (BullMQ), mock implementation ghi log thay vi gui that.
- **D-09:** Notification preferences — **theo source code cu**. Neu source cu co UI de user chon kenh thi lam, neu khong thi he thong tu gui theo cau hinh admin.
- **D-10:** Workers da co skeleton trong `workers/src/index.ts` — 4 workers stub (email-send, sms-send, lgsp-receive, fcm-push). Them Zalo worker va implement mock logic cho tat ca.

### Database & API
- **D-11:** Migration files moi cho Phase 6: tables cho LGSP tracking, digital signatures, notification logs/preferences.
- **D-12:** SP naming — tiep tuc convention `{schema}.fn_{module}_{action}`.
- **D-13:** Backend can tich hop BullMQ de enqueue jobs tu route handlers -> workers xu ly.

### Seed Data & Demo
- **D-14:** 1 file SQL toan bo: `seed_full_demo.sql` — TRUNCATE tat ca tables -> seed data lien ket tu dau.
- **D-15:** Data phai bao phu: departments, staff (voi roles), VB den/di/du thao, HSCV, lich, danh ba, kho luu tru, tai lieu, hop dong, cuoc hop, VB lien thong (mock), ky so (mock status), notification logs.
- **D-16:** Data lien ket chuan: VB den -> HSCV -> VB di, Ho so luu tru -> VB, Cuoc hop -> Lich, etc.

### Claude's Discretion
- Chi tiet mock response format cho tung external API
- BullMQ queue configuration (concurrency, retry, delay)
- Migration file numbering (tiep noi tu Phase 5: 019, 020...)
- Cach tich hop cu the giua backend routes va BullMQ queues

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Source code cu (.NET) — TAI LIEU THAM CHIEU CHINH
- Source code cu (.NET) — Phai doc Controllers, Services, SPs cu cho LGSP, Ky so, Thong bao truoc khi implement

### Existing codebase
- `e_office_app_new/workers/src/index.ts` — BullMQ workers skeleton (4 workers stub)
- `e_office_app_new/backend/src/lib/socket.ts` — Socket.IO server da setup (JWT auth, personal rooms, emitToUser/emitToUsers)
- `e_office_app_new/backend/src/lib/redis/` — Redis client da config
- `e_office_app_new/backend/src/lib/minio/client.ts` — MinIO upload pattern
- `e_office_app_new/backend/src/lib/error-handler.ts` — Shared error handler pattern
- `e_office_app_new/backend/src/lib/db/` — callFunction/callFunctionOne/callProcedure helpers
- `e_office_app_new/database/seed_demo.sql` — Seed data hien tai (can thay the bang seed_full_demo.sql)

### Prior phase context
- `.planning/phases/05-kho-l-u-tr-t-i-li-u-h-p/05-CONTEXT.md` — Phase 5 decisions (D-00a -> D-00c apply here too)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **BullMQ workers skeleton** (`workers/src/index.ts`): 4 workers da stub (email-send, sms-send, lgsp-receive, fcm-push) — chi can implement logic
- **Socket.IO** (`backend/src/lib/socket.ts`): Da setup voi JWT auth, `emitToUser()` / `emitToUsers()` — dung cho realtime notification
- **Redis client** (`backend/src/lib/redis/`): Da config — dung cho LGSP OAuth2 token cache
- **MinIO upload** (`backend/src/lib/minio/client.ts`): Pattern upload da co — reuse cho PDF signing

### Established Patterns
- Repository pattern: `callFunction<T>()` / `callFunctionOne<T>()` cho database access
- Route handler: inline trong Express Router, `handleDbError()` cho error mapping
- Frontend: Ant Design 6, Drawer CRUD, Table + Dropdown actions, `message.success/error`

### Integration Points
- **Backend routes -> BullMQ**: Can them BullMQ Queue client trong backend de enqueue jobs
- **Workers -> Database**: Workers can pg pool de update trang thai sau khi xu ly
- **VB di detail page**: Them nut "Gui lien thong" va "Ky so"
- **VB du thao detail page**: Them nut "Ky so"
- **Notification bell** (Phase 3): Da co — workers co the push thong bao qua Socket.IO sau khi gui external

</code_context>

<specifics>
## Specific Ideas

- User nhan manh: **day la gan cuoi du an** — can data chuan, lien ket giua cac module de test va demo
- TRUNCATE toan bo + seed lai tu dau — KHONG append vao data cu
- Tat ca external integration deu mock nhung code phai du interface de "plug in" credentials that sau
- Tham chieu source code cu (.NET) la bat buoc cho moi module — khong tu sang tao flow

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 06-t-ch-h-p-h-th-ng-ngo-i*
*Context gathered: 2026-04-15*
