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
| 3 | Build backend + frontend | ~3-5 phút |
| 4 | Restart pm2 + verify | ~10s |

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

### Bước 3 — Build backend + frontend

```powershell
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
