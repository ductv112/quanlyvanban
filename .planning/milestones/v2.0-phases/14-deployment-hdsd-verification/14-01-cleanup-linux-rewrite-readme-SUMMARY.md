---
phase: 14-deployment-hdsd-verification
plan: 01
subsystem: deployment
tags:
  - deployment
  - cleanup
  - windows
  - docs
one-liner: "Xóa 4 shell scripts Linux + rewrite deploy/README.md thành Windows-only"
requirements:
  - DEP-01 (một phần — seed fix ở Plan 14-02)
dependency_graph:
  requires: []
  provides:
    - "deploy/ thư mục cleaned — chỉ còn 4 PowerShell scripts + README Windows-only"
    - "Foundation cho Plan 14-02 (append section 'Development setup' vào README)"
    - "Foundation cho Plan 14-03 (REQUIREMENTS.md audit không cần đụng Linux files)"
  affects:
    - "IT triển khai: không còn option chạy `.sh` scripts"
    - "Dev onboarding: follow chỉ 1 workflow (Windows)"
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified:
    - deploy/README.md
  deleted:
    - deploy/deploy.sh
    - deploy/update.sh
    - deploy/reset-db.sh
    - deploy/backup.sh
decisions:
  - "D-01 locked: Windows-only target (bỏ Linux support)"
  - "D-02 executed: xóa 4 file .sh khỏi deploy/"
  - "D-04 (phần liên quan): README mới KHÔNG có section 'Backup database' — backup Windows script defer đến production chính thức"
metrics:
  duration: "2min"
  completed: "2026-04-23"
  tasks: 2
  files_modified: 1
  files_deleted: 4
---

# Phase 14 Plan 01: Cleanup Linux + rewrite README Windows-only — Summary

## Overview

Plan 14-01 khép 2 mục cleanup milestone v2.0 trước khi đụng seed/REQUIREMENTS:

1. Xóa hẳn 4 file shell scripts Linux (`deploy.sh`, `update.sh`, `reset-db.sh`, `backup.sh`) ra khỏi thư mục `deploy/`.
2. Rewrite `deploy/README.md` chỉ còn nội dung Windows Server + IIS, remove toàn bộ bash code blocks + bảng OS lựa chọn Linux/Windows.

Kết quả: Dự án lock target **Windows-only**, không còn ambiguity hay maintenance burden cho 2 OS.

## What Was Done

### Task 1 — Xóa 4 file shell scripts Linux

Dùng `git rm` để remove khỏi working tree + index trong 1 commit atomic:

```
deploy/deploy.sh   (14.7KB)
deploy/update.sh   (2.0KB)
deploy/reset-db.sh (6.0KB)
deploy/backup.sh   (1.0KB)
```

**Verify sau xóa:**
- `ls deploy/*.sh | wc -l` = `0`
- `ls deploy/*.ps1 | wc -l` = `4` (không đụng PowerShell scripts)
- `deploy/README.md` vẫn exists

**Commit:** `1d5c8fe` — `chore(14-01): remove 4 Linux shell scripts from deploy/`

### Task 2 — Rewrite deploy/README.md Windows-only

Viết lại toàn bộ README theo structure 12 section level-2, chỉ giữ Windows content:

1. Yêu cầu server (Windows Server 2022 + IIS)
2. Scripts có sẵn (bảng 4 PowerShell scripts)
3. Cấu trúc DB (v2.0 consolidated) — giữ nguyên từ bản cũ
4. Environment variable BẮT BUỘC — giữ `SIGNING_SECRET_KEY` note
5. Deploy lần đầu (PowerShell block)
6. Cập nhật code (PowerShell block)
7. Reset toàn bộ DB (PowerShell block + `-NoDemo` switch)
8. Quản lý thường ngày (pm2 + Get-Service Windows)
9. Kiến trúc (diagram IIS thay Nginx)
10. File cấu hình (Windows paths `C:\qlvb\...`)
11. Tài khoản mặc định (`admin / Admin@123`)
12. Tham khảo (4 bullet references)

**Remove khỏi bản cũ:**
- Mọi block `bash` (sudo bash, `.sh` file reference)
- Bảng 3 cột "Task / Linux / Windows"
- Section "Backup database" (backup.sh đã xóa; Windows backup script defer per CONTEXT D-04)
- File paths Linux (`/opt/eoffice/...`, `/etc/nginx/sites-available/...`)
- "Linux: Ubuntu 22.04+ hoặc Debian 12+" trong Yêu cầu server

**Add/explicit:**
- Dòng note: *"Dự án hiện CHỈ hỗ trợ Windows Server. Hệ điều hành khác không được support."*
- Nginx → IIS (URL Rewrite + ARR) trong Kiến trúc diagram
- Windows paths cho tất cả file config
- `Get-Service postgresql-16, Redis, minio` trong Quản lý thường ngày

**Acceptance verify (automated):**
| Check | Result |
|-------|--------|
| `.sh` count | 0 ✓ |
| `.ps1` count | 11 (>= 4) ✓ |
| `sudo bash` | 0 ✓ |
| `Linux` | 0 ✓ |
| `reset-db-windows` | 4 (>= 2) ✓ |
| `Admin@123` | 1 ✓ |
| `SIGNING_SECRET_KEY` | 4 (>= 2) ✓ |
| H2 headings | 12 (>= 10) ✓ |
| Line count | 177 (trong 100-180) ✓ |
| `backup.sh` | 0 ✓ |
| `Development setup` | 0 (Plan 14-02 sẽ add) ✓ |

**Commit:** `f349518` — `docs(14-01): rewrite deploy/README.md Windows-only`

## Files Changed

**Deleted (4 files, 739 lines removed):**
- `deploy/deploy.sh`
- `deploy/update.sh`
- `deploy/reset-db.sh`
- `deploy/backup.sh`

**Modified (1 file, -76 / +59 lines):**
- `deploy/README.md` (195 → 177 lines)

**Unchanged (verified MD5 identical pre/post plan):**
- `deploy/deploy-windows.ps1` → `84f7b5afc228244d1630299f123b3088`
- `deploy/update-windows.ps1` → `7b7f9e2d00d383e5ecbfe8f5d614842a`
- `deploy/reset-db-windows.ps1` → `d91523547ec22efdf422a073a189a4be`
- `deploy/setup-iis.ps1` → `7a5064833aca9ff8a10995e20b6f248e`

## Commits

| # | Hash | Message |
|---|------|---------|
| 1 | `1d5c8fe` | `chore(14-01): remove 4 Linux shell scripts from deploy/` |
| 2 | `f349518` | `docs(14-01): rewrite deploy/README.md Windows-only` |

## Decisions Implemented

- **D-01 (Windows-only target):** README note explicit, không còn Linux instructions nào
- **D-02 (delete 4 Linux scripts):** 4 file `.sh` removed qua `git rm`, git history vẫn giữ để recoverable

## Deviations from Plan

**None.** Plan 14-01 executed exactly as written. 2 tasks, 0 auto-fixes, 0 architectural checkpoints.

Một adjustment nhỏ trong Task 2: acceptance criteria ghi `grep -c "Admin@123" = 1`. Phiên bản đầu vô tình có 2 lần mention (cả trong mô tả bước seed + section Tài khoản mặc định) nên strip bớt mention trong mô tả seed (đổi "admin/Admin@123 + 2 provider config" → "admin + roles + rights + 2 provider config"). Không phải deviation — là self-correct để đạt acceptance criteria strict.

## Affects / Provides

- **Affects:**
  - `deploy/` thư mục: file .sh biến mất hoàn toàn
  - Docs cho IT triển khai: 1 source of truth Windows
- **Provides:**
  - Foundation cho Plan 14-02: README structure chừa sẵn chỗ insert section "## Development setup" trước "## Tham khảo" (Plan 14-02 Task 2)
  - Foundation cho Plan 14-03: REQUIREMENTS.md audit không cần đụng Linux files
- **Patterns (new):** None — cleanup-only plan
- **Patterns (reused):** Schema master idempotent reference trong DB section, structure 9-12 section level-2 của README trước đó

## Blockers / Concerns

None. Plan độc lập với 14-02 và 14-03 về file. README.md có thể được append section mới từ Plan 14-02 mà không conflict với section Plan 14-01 đã viết.

## Self-Check: PASSED

**Files deleted (4):**
- `test ! -f deploy/deploy.sh` → FOUND deleted ✓
- `test ! -f deploy/update.sh` → FOUND deleted ✓
- `test ! -f deploy/reset-db.sh` → FOUND deleted ✓
- `test ! -f deploy/backup.sh` → FOUND deleted ✓

**Files modified (1):**
- `deploy/README.md` → exists, 177 lines, 12 H2 headings ✓

**Commits exist:**
- `1d5c8fe` → FOUND in git log ✓
- `f349518` → FOUND in git log ✓

**PS1 scripts regression:**
- MD5 hashes identical pre/post (4/4 ✓)
