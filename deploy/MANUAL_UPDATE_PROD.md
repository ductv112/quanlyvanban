# 🚀 Update PROD — 4 bước thủ công

> **Khi nào dùng**: Server prod đã có data KH (đang test thật), cần đẩy code mới
> **GIỮ NGUYÊN data**, chỉ pull code + re-apply schema (idempotent) + rebuild + restart.
>
> **KHÔNG dùng** `deploy-v2-kh-test.ps1` (script đó RESET DB → mất data KH).

## ⏱️ Tổng thời gian: ~5-7 phút

| Bước | Việc | Thời gian |
|---|---|---|
| 0 | Backup DB (đề phòng) | ~30s |
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

---

## 📂 Tham khảo

- `deploy/update-windows.ps1` — script tự động hóa 4 bước (chưa stable, dùng manual cho an toàn)
- `deploy/deploy-v2-kh-test.ps1` — **CHỈ dùng cho fresh setup**, KHÔNG dùng cho prod đang có data
- `CLAUDE.md` — section "Deploy Pitfalls"
