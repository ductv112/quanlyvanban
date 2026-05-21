# 🚀 Update PROD — 4 bước thủ công

> **Khi nào dùng**: Server prod đã có data KH (đang test thật), cần đẩy code mới
> **GIỮ NGUYÊN data**, chỉ pull code + re-apply schema (idempotent) + rebuild + restart.
>
> **KHÔNG dùng** `deploy-v2-kh-test.ps1` (script đó RESET DB → mất data KH).

> ## ⚠️ FILE NÀY LÀ CANONICAL — copy-paste từ ĐÂY
>
> Server prod chạy **PostgreSQL native** trên Windows (KHÔNG Docker). Mọi lệnh
> ở đây dùng path `C:\PostgreSQL\16\bin\*.exe` + PowerShell flag `-f file` (không
> dùng `< file` redirect — PS cấm).
>
> **Nếu AI assistant (Claude/ChatGPT) đưa lệnh khác file này** (vd `docker exec
> qlvb_postgres pg_dump ...` hoặc `psql ... < file`) → **BỎ QUA**, dùng file này.
> AI có thể nhầm môi trường.

## ⏱️ Tổng thời gian: ~5-7 phút

| Bước | Việc | Thời gian |
|---|---|---|
| 0 | Backup DB (đề phòng) | ~30s |
| 0.5 | Verify env trỏ đúng domain (lần đầu / khi đổi domain) | ~1 phút |
| 1 | Pull code mới | ~5s |
| 2 | Re-apply master schema (idempotent) | ~30s |
| 3 | Stop pm2 + Build backend + frontend | ~3-5 phút |
| 4 | Restart pm2 + verify | ~10s |

---

## 📦 Pre-requisite: Cài LibreOffice (cho tính năng "Xem trực tiếp file đính kèm")

> Bắt buộc CHỈ khi deploy từ **release 2026-05-21 trở đi** (quick task `260521-v8t`).
> Chỉ cần cài 1 lần — các deploy sau không phải làm lại.

Tính năng "Xem trực tiếp file đính kèm" cho phép user bấm icon Mắt để xem inline file Office (`.doc/.docx/.xls/.xlsx/.ppt/.pptx`) ngay trong browser, không cần tải xuống. Backend cần LibreOffice headless để convert Office → PDF rồi stream PDF về browser.

**Cài đặt:**

1. **Tải LibreOffice** (bản mới nhất, ~350MB): <https://www.libreoffice.org/download/download-libreoffice/>
2. **Cài đặt mặc định** vào `C:\Program Files\LibreOffice\` (Next → Next → Install)
3. **Verify đã cài**:
   ```powershell
   & 'C:\Program Files\LibreOffice\program\soffice.com' --version
   # → in ra: LibreOffice 24.x.x.x ...
   ```
4. **Thêm biến môi trường vào `backend\.env`**:
   ```powershell
   notepad C:\qlvb\quanlyvanban\e_office_app_new\backend\.env
   # Thêm dòng:
   # LIBREOFFICE_PATH=C:\Program Files\LibreOffice\program\soffice.com
   ```
5. **Apply env mới**: `pm2 restart all --update-env` (BẮT BUỘC `--update-env` để pick up biến mới — pitfall #3).

**Smoke test sau deploy:**

1. Login vào hệ thống
2. Mở 1 VB đến có file đính kèm `.docx` → bấm icon Mắt cạnh tên file
3. Modal mở → loading spinner ~3-10s (lần đầu) → hiển thị PDF đã convert
4. Đóng Modal → mở lại file đó → hiển thị NGAY (cache hit MinIO `previews/{id}.pdf`)

**Troubleshoot:**

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Bấm Mắt → loading mãi → "Không thể tải file" | `LIBREOFFICE_PATH` sai hoặc chưa cài | Verify Bước 3 + `pm2 restart all --update-env` |
| Log `ENOENT` hoặc `LibreOffice exit code` trong `pm2 logs eoffice-api` | Đường dẫn `soffice.exe` không tồn tại | Cài lại LibreOffice + check path |
| File PDF/ảnh xem trực tiếp OK, chỉ Office fail | LibreOffice chưa cài | Cài LibreOffice — PDF/ảnh không cần dependency này |
| File `.zip/.rar` không có icon Mắt | Đúng — loại file này không hỗ trợ xem | Dùng nút Tải xuống |

**Lưu ý:** Lần convert đầu tiên cho mỗi file mất ~3-10s tùy size. Cache MinIO `previews/{attachment_id}.pdf` được tạo → các lần sau load tức thì.

---

## 📋 Copy-paste run

RDP/SSH vào server Windows prod, mở **PowerShell Administrator**, paste từng block:

### Bước 0 — Backup DB (đề phòng rollback)

```powershell
# Tạo folder backup nếu chưa có
New-Item -ItemType Directory -Force -Path C:\qlvb\backups | Out-Null

$env:PGPASSWORD = 'QlvbProd2026'
$ts = Get-Date -Format 'yyyyMMdd-HHmmss'
& 'C:\PostgreSQL\16\bin\pg_dump.exe' -U qlvb_admin -h 127.0.0.1 -d qlvb_prod -F c -f "C:\qlvb\backups\qlvb_prod_$ts.dump"
```

→ File `C:\qlvb\backups\qlvb_prod_YYYYMMDD-HHmmss.dump` (~50-200MB tùy data).

### Bước 0.5 — Verify env trỏ đúng domain (chỉ làm LẦN ĐẦU hoặc khi đổi domain)

> `.env` + `.env.local` **gitignored** → `git pull` KHÔNG overwrite. Chỉ cần check 1 lần khi setup hoặc khi domain thay đổi.

```powershell
# 1. Backend CORS_ORIGIN — phải có domain KH đang dùng
Get-Content C:\qlvb\quanlyvanban\e_office_app_new\backend\.env | Select-String "CORS_ORIGIN"

# 2. Frontend NEXT_PUBLIC_API_URL — KHUYẾN NGHỊ relative `/api`
Get-Content C:\qlvb\quanlyvanban\e_office_app_new\frontend\.env.local | Select-String "NEXT_PUBLIC_API_URL"
```

**Mong đợi (prod):**

```
CORS_ORIGIN=http://doanhnghiep.vatk.org,http://103.97.134.87,https://doanhnghiep.vatk.org
NEXT_PUBLIC_API_URL=/api
```

**Triệu chứng SAI:**

| Triệu chứng | Nguyên nhân | Fix |
|---|---|---|
| Browser KH login fail "Network Error" | `NEXT_PUBLIC_API_URL` hard-code IP, KH access qua domain → CORS reject | Sửa `.env.local` → `/api`, rebuild frontend |
| Mixed content "Blocked: HTTP from HTTPS" | KH access HTTPS, bundle gọi HTTP IP | Same fix — relative `/api` |
| CORS error console "Access-Control-Allow-Origin" | `CORS_ORIGIN` thiếu origin domain | Add domain vào `CORS_ORIGIN`, restart backend |

**Sửa env (nếu cần):**

```powershell
notepad C:\qlvb\quanlyvanban\e_office_app_new\backend\.env
notepad C:\qlvb\quanlyvanban\e_office_app_new\frontend\.env.local
# Save + close → tiếp tục Bước 1
```

### Bước 1 — Pull code

```powershell
cd C:\qlvb\quanlyvanban
git fetch --all -q
git reset --hard origin/main -q
git log --oneline -3   # verify HEAD = commit mới nhất trên GitHub
```

### Bước 2 — Re-apply master schema (idempotent — KHÔNG mất data)

```powershell
& 'C:\PostgreSQL\16\bin\psql.exe' -U qlvb_admin -h 127.0.0.1 -d qlvb_prod -v ON_ERROR_STOP=1 -f C:\qlvb\quanlyvanban\e_office_app_new\database\schema\000_schema_v3.0.sql 2>&1 | Select-String -Pattern "^(ERROR|FATAL):"
```

→ **Phải KHÔNG in gì** = clean. Nếu in `ERROR:` hoặc `FATAL:` → STOP, copy ra check.

Schema sẽ tự:
- Add column mới (CREATE COLUMN IF NOT EXISTS)
- Update SPs (DROP+CREATE per signature)
- Run migration block cuối file (status, unit_id sync, ...)

### Bước 3 — Stop pm2 + Build backend + frontend

> ⚠️ **PHẢI stop pm2 TRƯỚC khi `npm install/ci`** — pm2 đang chạy giữ file lock
> trên native modules (`msgpackr-extract/node.abi115.node` etc.) → `npm install`
> fail với `EPERM: operation not permitted, unlink ...` → `node_modules` lỗi
> nửa chừng → `tsc` không tìm thấy → build fail.

```powershell
# 0. Stop pm2 truoc de giai phong file lock
pm2 stop all

# Backend (set NODE_ENV=development để có typescript CLI cho tsc)
cd C:\qlvb\quanlyvanban\e_office_app_new\backend
$env:NODE_ENV = 'development'
npm install
npm run build

# Frontend (CLEAR NODE_ENV trước build để Next.js tự set production)
cd C:\qlvb\quanlyvanban\e_office_app_new\frontend
$env:NODE_ENV = 'development'
npm install
Remove-Item Env:NODE_ENV
npm run build
```

⚠️ **Quan trọng**:
- **`pm2 stop all` TRƯỚC `npm install`** — tránh EPERM unlink native modules
- Backend: cần `NODE_ENV=development` để có `typescript` CLI cho `tsc` build
- Frontend: PHẢI `Remove-Item Env:NODE_ENV` TRƯỚC `next build` — nếu để `development` thì Next.js prerender fail "Cannot read properties of null (reading 'useContext')"

### Bước 4 — Restart pm2 + verify

```powershell
pm2 restart all --update-env
pm2 status
curl http://localhost:4000/api/health
```

→ Backend health phải `{"success":true,...,"environment":"production","postgresql":{"status":"connected"}}`.

---

## ✅ Verify sau deploy (optional)

```powershell
# 1. SP overload duplicate (phai = 0)
& 'C:\PostgreSQL\16\bin\psql.exe' -U qlvb_admin -h 127.0.0.1 -d qlvb_prod -tAc "SELECT count(*) FROM (SELECT n.nspname, p.proname, count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ('public','edoc','esto','cont','iso') AND p.proname LIKE 'fn_%' GROUP BY 1,2 HAVING count(*) > 1) t;"

# 2. SP count baseline (phai >= 340)
& 'C:\PostgreSQL\16\bin\psql.exe' -U qlvb_admin -h 127.0.0.1 -d qlvb_prod -tAc "SELECT count(*) FROM pg_proc WHERE pronamespace IN ('public'::regnamespace, 'edoc'::regnamespace) AND proname LIKE 'fn_%';"

# 3. PM2 logs check (5-10 phut dau)
pm2 logs eoffice-api --lines 30
```

---

## 🚨 KHẨN — Rollback nếu fail

Nếu deploy fail (backend không start, lỗi runtime):

```powershell
# 1. Restore DB từ backup ở Bước 0
$env:PGPASSWORD = 'QlvbProd2026'
& 'C:\PostgreSQL\16\bin\pg_restore.exe' -U qlvb_admin -h 127.0.0.1 -d qlvb_prod --clean --if-exists C:\qlvb\backups\qlvb_prod_YYYYMMDD-HHmmss.dump

# 2. Revert code
cd C:\qlvb\quanlyvanban
git reset --hard <commit-cu>   # commit trước khi deploy
git log --oneline -5

# 3. Rebuild + restart như Bước 3-4
```

---

## 📌 Pitfalls đã gặp (đừng lặp lại)

1. **`NODE_ENV=development` cho `next build`** → prerender error. Phải `Remove-Item Env:NODE_ENV` trước build frontend.
2. **`npm install --omit=dev`** trước build backend → thiếu `typescript` CLI → `npm run build` fail. Phải `NODE_ENV=development` (full deps).
3. **`pm2 restart all`** không có `--update-env` → KHÔNG pick up `.env` mới. Phải có flag.
4. **Schema apply 2 lần liên tiếp** → kiểm tra idempotent. Nếu có ERROR ở lần 2 = bug schema không idempotent (fix bằng `DROP FUNCTION IF EXISTS` trước CREATE khi đổi signature).
5. **Folder backup chưa có** → `pg_dump` fail "No such file or directory". Tạo `New-Item -ItemType Directory -Force -Path C:\qlvb\backups` trước.
6. **Server Action error trong browser KH** sau deploy → bình thường, KH refresh hard (Ctrl+Shift+R) là hết.
7. **Frontend `NEXT_PUBLIC_API_URL` hard-code IP** → KH access qua domain (vd `https://prod.com`) sẽ vỡ vì:
    - CORS reject (origin domain ≠ allowed IP)
    - Mixed content (HTTPS page → HTTP IP API call)
    Fix: dùng `NEXT_PUBLIC_API_URL=/api` (relative) + reverse proxy IIS/Nginx route `/api/*` → backend port 4000. Sửa env XONG phải `npm run build` lại (env baked vào JS bundle) + `pm2 restart eoffice-web --update-env`.
8. **Backend `CORS_ORIGIN` thiếu domain** → preflight OPTIONS fail. Multi-origin syntax: `CORS_ORIGIN=https://prod.com,http://prod.com,http://ip-raw` (comma-separated).

---

## 📂 Tham khảo

- `deploy/update-windows.ps1` — script tự động hóa 4 bước (chưa stable, dùng manual cho an toàn)
- `deploy/deploy-v2-kh-test.ps1` — **CHỈ dùng cho fresh setup**, KHÔNG dùng cho prod đang có data
- `CLAUDE.md` — section "Deploy Pitfalls"

---

## Kich hoat LGSP v3.2 (post-deploy)

> Sau khi update code v3.2 thanh cong (qua 4 buoc o tren), can buoc bo sung de kich hoat
> tinh nang lien thong LGSP cho 6 DN Lang Son. Toan bo cau hinh qua UI admin — KHONG can
> SSH/SQL update direct.
>
> **Reference**: file `docs/Truc EDOC Lang Son - QLVB Doanh nghiep/` chua credential
> sandbox (List.txt) + prod (QLVBDNAgencies.xlsx) tu tinh.

### Buoc A — Admin login + truy cap menu LGSP

1. Mo browser → `http://doanhnghiep.vatk.org` → login `admin / Admin@123` (hoac credential prod)
2. Sidebar trai → group **TICH HOP** → click **Cau hinh ket noi**
3. Page `/lgsp/cau-hinh` hien Table 12 row (6 DN x 2 env), tat ca `is_active=FALSE` mac dinh

### Buoc B — Wave 1 (Sandbox testing — 3 DN.001/002/003)

Muc tieu: Verify code v3.2 hoat dong dung voi sandbox truoc khi enable prod.

Cho moi DN trong DN.001 / DN.002 / DN.003:

1. Click **Sua** row DN.00X sandbox
2. Nhap **SystemId** + **SecretKey** tu file `List.txt` (sandbox section)
3. Verify **Base URL** = `https://apiltvbsandbox.langson.gov.vn` (sandbox)
4. **Luu** form (chua bat is_active)
5. Click **Kiem tra** row vua sua → Modal mo → **Bat dau kiem tra**
   - Mong doi: Alert green **Ket noi thanh cong** + `So VB tren truc 24h qua: N`
   - Neu RED **Ket noi that bai** → check SystemId/SecretKey, base URL, firewall — sua + test lai
6. Sau khi test PASS → toggle **Trang thai** Switch → bat ON
   - Toast: **Da bat ket noi LGSP**
7. Cron 5 phut + status callback 30s se tu start cho DN.00X

Verify Wave 1 (sau ~10 phut):
- Page `/lgsp` dashboard → 3 DN sandbox card hien tag **Sandbox** active (orange)
- Stats `VB nhan today` co count > 0 (neu sandbox co VB)
- Postman manual: gui 1 edXML test giua 3 DN sandbox → trong 5 phut VB hien o `/van-ban-den` cua DN nhan

### Buoc C — Wave 2 (Production rollout — TUNG DN MOT, KHONG dong loat)

> **Quan trong**: enable tung DN, test ~24h, moi enable DN tiep theo.
> **Mat data dichvu = mat uy tin**. KHONG enable batch ca 6 DN cung luc.

Cho moi DN trong DN.001 → DN.002 → ... → DN.006 (theo thu tu prio cua KH):

1. Click **Sua** row DN.00X prod (tag red **Production**)
2. Nhap **SystemId** + **SecretKey** tu file `QLVBDNAgencies.xlsx` (sheet prod)
3. Verify **Base URL** = `https://apiltvb.langson.gov.vn` (prod)
4. **Luu** form
5. Click **Kiem tra** → modal PASS → toggle **Trang thai** ON
6. Verify trong 24h:
   - Page `/lgsp` dashboard → DN.00X prod card hien `last_synced_at` cap nhat moi 5 phut
   - Stats `VB nhan today` count tang dan
   - Stats `Callback loi` = 0 (neu khong, click vao VB error → admin co button **Gui lai**)
7. Sau 24h on dinh → repeat cho DN tiep theo

### Buoc D — Setup catalog co quan ngoai (1 lan dau)

1. Sidebar **TICH HOP** → **Co quan lien thong** → page `/lgsp/co-quan`
2. Click **Dong bo tu truc LGSP** → toast `Dong bo thanh cong: them moi N, cap nhat M`
3. Table hien danh sach co quan tu truc (auto-fetch qua `/v1/getAgenciesList`)
4. Cac co quan **Tu dang ky** (orange tag) la do worker Phase 35 auto-INSERT khi nhan VB tu don vi
   chua co trong catalog — admin verify, click **Sua** → bat **Da xac nhan** neu hop le

### Buoc E — Monitoring + Recovery

- **Dashboard tong quan**: `/lgsp` polling 30s → admin xem real-time 6 DN status + counts today
- **VB error**: click vao detail VB den → Timeline **Lich su trang thai LGSP** → entry RED error → click **Gui lai** → worker retry trong 30s
- **VB di error**: click vao detail VB di → recipient badge external_org RED → click **Gui lai** → worker retry
- **Force sync**: button **Dong bo ngay** tren page `/lgsp` → ko cho cron 5 phut, trigger immediate
- **Log file**: `pm2 logs all` → grep `lgsp` cho luong receive/send/status worker

### Lan dau setup — Check encrypt key

> Truoc khi admin nhap credential dau tien, verify backend co `SIGNING_SECRET_KEY` set trong `.env`:
> ```powershell
> Get-Content C:\qlvb\quanlyvanban\e_office_app_new\backend\.env | Select-String "SIGNING_SECRET_KEY"
> ```
> Mong doi: `SIGNING_SECRET_KEY=<>=32 ky tu ngau nhien>`. Neu thieu → them line, restart pm2 `--update-env`.
>
> **CANH BAO**: NEU thay doi `SIGNING_SECRET_KEY` SAU khi admin da nhap credential → toan bo
> secret_key luu DB se KHONG decrypt duoc → phai nhap lai het. Set 1 lan tu dau + backup key an toan.

### Tom tat Wave plan

| Wave | Pham vi | Thoi gian | Verify |
|---|---|---|---|
| Sandbox | DN.001/002/003 sandbox | ~1 ngay | Postman test send/receive E2E PASS |
| Prod DN.001 | 1 DN prod | 24h | last_synced_at xanh, 0 callback loi |
| Prod DN.002..006 | Tung DN mot | 24h moi DN | Tuong tu |

Tong roll-out: ~7-10 ngay tu Wave 1 → toan bo 6 DN prod active.

