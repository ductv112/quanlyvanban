# KE HOACH CAP NHAT TOAN DIEN 5 MODULE VAN BAN

> Ngay tao: 2026-04-16
> Muc tieu: Hoan thien day du nghiep vu tat ca module VB den/di/du thao/lien thong/danh dau
> Chat luong: Production-grade, khong phai demo tam

---

## TONG QUAN

| Batch | Noi dung | So tasks | Phu thuoc |
|-------|----------|----------|-----------|
| **Batch 1** | DB Schema — ALTER TABLE + tao bang moi | 8 | Khong |
| **Batch 2** | DB SPs — Fix SP cu + tao SP moi | 18 | Batch 1 |
| **Batch 3** | Backend — Fix routes + repos + them routes moi | 14 | Batch 2 |
| **Batch 4** | Frontend — Fix bugs + bo sung UI/form/actions | 16 | Batch 3 |
| **Batch 5** | Export/Print — Excel + In | 5 | Batch 3 |
| **Batch 6** | Integration test + seed data update | 3 | Batch 4+5 |

---

## BATCH 1: DB SCHEMA CHANGES
> File: `database/migrations/022_doc_module_fixes.sql`
> Chay 1 lan, tat ca ALTER TABLE + CREATE TABLE

### 1.1 incoming_docs — Them cot
```sql
ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS sents TEXT;
-- "Noi gui" — source cu co, moi thieu
ALTER TABLE edoc.incoming_docs ADD COLUMN IF NOT EXISTS received_paper_date TIMESTAMPTZ;
-- Ngay nhan ban giay — chi co boolean is_received_paper la khong du
```

### 1.2 leader_notes — Mo rong cho VB di + du thao
```sql
-- Hien tai chi co incoming_doc_id NOT NULL — can cho phep null va them cot khac
ALTER TABLE edoc.leader_notes ALTER COLUMN incoming_doc_id DROP NOT NULL;
ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS outgoing_doc_id BIGINT REFERENCES edoc.outgoing_docs(id) ON DELETE CASCADE;
ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS drafting_doc_id BIGINT REFERENCES edoc.drafting_docs(id) ON DELETE CASCADE;
-- Constraint: chi 1 trong 3 doc_id duoc co gia tri
ALTER TABLE edoc.leader_notes ADD CONSTRAINT chk_leader_note_doc_type 
  CHECK (
    (incoming_doc_id IS NOT NULL)::int + 
    (outgoing_doc_id IS NOT NULL)::int + 
    (drafting_doc_id IS NOT NULL)::int = 1
  );
```

### 1.3 staff_notes — Them is_important
```sql
ALTER TABLE edoc.staff_notes ADD COLUMN IF NOT EXISTS is_important BOOLEAN DEFAULT false;
```

### 1.4 drafting_docs — Them reject_reason
```sql
ALTER TABLE edoc.drafting_docs ADD COLUMN IF NOT EXISTS reject_reason TEXT;
```

### 1.5 Attachment tables — Them description cho 3 bang
```sql
ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE edoc.attachment_outgoing_docs ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE edoc.attachment_drafting_docs ADD COLUMN IF NOT EXISTS description TEXT;
```

### 1.6 user_outgoing_docs + user_drafting_docs — Them cot tracking
```sql
-- Nguoi gui + han xu ly per-person
ALTER TABLE edoc.user_outgoing_docs ADD COLUMN IF NOT EXISTS sent_by INTEGER REFERENCES staff(id);
ALTER TABLE edoc.user_outgoing_docs ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;

ALTER TABLE edoc.user_drafting_docs ADD COLUMN IF NOT EXISTS sent_by INTEGER REFERENCES staff(id);
ALTER TABLE edoc.user_drafting_docs ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;
```

### 1.7 inter_incoming_docs — Them truong LGSP
```sql
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS organ_id VARCHAR(100);
-- Ma don vi gui (LGSP OrganID)
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS from_organ_id VARCHAR(100);
-- Ma don vi nhan (LGSP FromOrganID)
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS number_paper INTEGER DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS number_copies INTEGER DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS secret_id SMALLINT DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS urgent_id SMALLINT DEFAULT 1;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS recipients TEXT;
ALTER TABLE edoc.inter_incoming_docs ADD COLUMN IF NOT EXISTS doc_field_id INTEGER REFERENCES edoc.doc_fields(id);
```

### 1.8 Tao bang attachment_inter_incoming_docs
```sql
CREATE TABLE IF NOT EXISTS edoc.attachment_inter_incoming_docs (
  id BIGSERIAL PRIMARY KEY,
  inter_incoming_doc_id BIGINT NOT NULL REFERENCES edoc.inter_incoming_docs(id) ON DELETE CASCADE,
  file_name VARCHAR(500) NOT NULL,
  file_path VARCHAR(1000) NOT NULL,
  file_size BIGINT DEFAULT 0,
  content_type VARCHAR(100),
  description TEXT,
  sort_order INTEGER DEFAULT 0,
  created_by INTEGER REFERENCES staff(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

---

## BATCH 2: STORED PROCEDURES — Fix + Tao moi
> File: `database/migrations/022_doc_module_fixes.sql` (tiep theo sau ALTER)

### VB DEN (6 SPs)

**2.1** `fn_incoming_doc_get_by_id` — Them `is_inter_doc`, `inter_doc_id` vao RETURNS TABLE + SELECT
- Hien tai: SP thieu 2 field nay → nut "Nhan ban giao" ko hien

**2.2** `fn_incoming_doc_create` + `fn_incoming_doc_update` — Them param `p_sents TEXT`
- Hien tai: thieu truong "Noi gui"

**2.3** `fn_incoming_doc_receive_paper` — Them param `p_received_paper_date`, ghi vao cot moi
- Hien tai: chi set boolean, ko ghi ngay

**2.4** `fn_incoming_doc_get_list` — Bo sung filter: `p_signer`, `p_from_number`, `p_to_number`, `p_is_read`, `p_is_bookmarked`
- Hien tai: chi co keyword + date range

**2.5** Thong nhat `huy-duyet` — Bo 1 trong 2 SP trung (giu `fn_incoming_doc_unapprove`, bo route POST /huy-duyet)

**2.6** `fn_incoming_doc_export_list` — SP moi cho Export Excel
- SELECT tuong tu get_list nhung khong phan trang, tra toan bo fields

### VB DI (6 SPs)

**2.7** `fn_outgoing_doc_get_by_id` — Them JOIN `publish_unit_name`, them `document_code` vao RETURNS TABLE
- Hien tai: hien thi "Don vi #N"

**2.8** `fn_outgoing_doc_retract` — Doi tu "xoa tat ca + reset approved" thanh "xoa per-person hoac tat ca tuy param"
- Them param `p_staff_ids INT[] DEFAULT NULL` — null = thu hoi tat ca, co gia tri = thu hoi tung nguoi

**2.9** `fn_outgoing_doc_send` — Them `p_sent_by`, `p_expired_date` ghi vao user_outgoing_docs
- Hien tai: ko ghi nguoi gui va han xu ly

**2.10** `fn_outgoing_doc_check_number` — SP moi kiem tra trung so
- Input: p_unit_id, p_doc_book_id, p_number, p_exclude_id
- Output: boolean exists

**2.11** `fn_outgoing_doc_export_list` — SP moi cho Export Excel

**2.12** `fn_leader_note_get_by_outgoing_doc` + `fn_leader_note_create_outgoing` — SP y kien lanh dao cho VB di

### VB DU THAO (3 SPs)

**2.13** `fn_drafting_doc_get_by_id` — Them JOIN `publish_unit_name`
- Hien tai: hien thi "#ID"

**2.14** `fn_drafting_doc_reject` — Ghi `p_reason` vao `drafting_docs.reject_reason`
- Hien tai: param bi bo qua, ly do tu choi mat

**2.15** `fn_drafting_doc_retract` — Doi thanh per-person tuong tu outgoing
- Them param `p_staff_ids INT[] DEFAULT NULL`

### VB LIEN THONG (2 SPs)

**2.16** `fn_inter_incoming_get_by_id` — Them LEFT JOIN doc_types, doc_fields, staff (created_by_name)
- Hien tai: ko JOIN gi ca, frontend hien thi "—" het

**2.17** `fn_inter_incoming_get_list` — Them param `p_doc_type_id`
- Hien tai: frontend gui doc_type_id nhung SP ko nhan

### BOOKMARK (1 SP)

**2.18** `fn_staff_note_toggle` — Them param `p_is_important BOOLEAN DEFAULT false`
- Ghi vao cot is_important moi

---

## BATCH 3: BACKEND — Routes + Repositories

### VB DEN (3 tasks)

**3.1** Fix route `huy-duyet` — Bo route `POST /:id/huy-duyet` trung, giu `PATCH`
- File: `backend/src/routes/incoming-doc.ts`

**3.2** Update repository: them `sents` param vao create/update methods
- Them `receivedPaperDate` param vao `receivePaper` method
- File: `backend/src/repositories/incoming-doc.repository.ts`

**3.3** Them route `GET /van-ban-den/xuat-excel` — goi SP export, tra file Excel (exceljs)
- File: `backend/src/routes/incoming-doc.ts`

### VB DI (5 tasks)

**3.4** Update repository `outgoing-doc.repository.ts`:
- Fix `OutgoingDocDetailRow` — them `publish_unit_name`, `document_code`
- Fix `getSendableStaff` — tao SP rieng hoac rename cho dung

**3.5** Update route retract — them optional `staff_ids` body param
- File: `backend/src/routes/outgoing-doc.ts`

**3.6** Them route `GET /van-ban-di/kiem-tra-so` — goi `fn_outgoing_doc_check_number`

**3.7** Them route `GET /van-ban-di/xuat-excel`

**3.8** Them routes leader_note cho VB di:
- `GET /:id/y-kien` — lay danh sach y kien
- `POST /:id/y-kien` — them y kien
- `DELETE /:id/y-kien/:noteId` — xoa y kien

### VB DU THAO (3 tasks)

**3.9** Update repository — them `reject_reason` vao `DraftingDocDetailRow`
- File: `backend/src/repositories/drafting-doc.repository.ts`

**3.10** Update route reject — truyen `reason` param xuong SP
- File: `backend/src/routes/drafting-doc.ts`

**3.11** Them route `GET /van-ban-du-thao/xuat-excel`

### VB LIEN THONG (2 tasks)

**3.12** Update repository — sua `LienThongDocDetail` interface cho khop SP moi
- File: `backend/src/repositories/inter-incoming.repository.ts`

**3.13** Update route — them doc_type_id vao query params cho get_list
- File: `backend/src/routes/inter-incoming.ts`

### BOOKMARK (1 task)

**3.14** Update toggle route — them `is_important` param
- Tim route trong incoming-doc.ts / outgoing-doc.ts / drafting-doc.ts

---

## BATCH 4: FRONTEND — Fix bugs + Bo sung UI

### VB DEN (3 tasks)

**4.1** Form Drawer — Them fields:
- `sents` (Input — Noi gui)
- `document_code` (Input — Ma van ban)
- `received_paper_date` (DatePicker — hien khi is_received_paper = true)
- File: `frontend/src/app/(main)/van-ban-den/page.tsx`

**4.2** Detail page — Fix nut "Nhan ban giao"/"Chuyen lai" (da co logic nhung `is_inter_doc` undefined)
- Verify sau khi SP duoc fix (Batch 2.1)
- File: `frontend/src/app/(main)/van-ban-den/[id]/page.tsx`

**4.3** Filter nang cao — Them vao SearchForm:
- Nguoi ky (Input)
- So den tu — den (2 InputNumber)
- Filter nhanh: Chua doc / Da danh dau / Tat ca
- File: `frontend/src/app/(main)/van-ban-den/page.tsx`

### VB DI (4 tasks)

**4.4** Detail page — Fix hien thi:
- `publish_unit_name` thay vi "#ID" (sau SP fix)
- `document_code` hien thi
- File: `frontend/src/app/(main)/van-ban-di/[id]/page.tsx`

**4.5** Modal gui VB — Them "Han xu ly" (DatePicker) cho tung nguoi nhan
- File: `frontend/src/app/(main)/van-ban-di/[id]/page.tsx`

**4.6** Them thu hoi per-person — Modal chon nguoi can thu hoi thay vi thu hoi tat ca
- File: `frontend/src/app/(main)/van-ban-di/[id]/page.tsx`

**4.7** Them section "Y kien lanh dao" vao detail page VB di
- Tuong tu section leader_notes cua VB den
- File: `frontend/src/app/(main)/van-ban-di/[id]/page.tsx`

### VB DU THAO (4 tasks)

**4.8** Fix `api.patch` → `api.post` cho handleRelease trong list page
- File: `frontend/src/app/(main)/van-ban-du-thao/page.tsx` line ~340

**4.9** Detail page — Fix `publish_unit_name` hien thi "#ID"
- File: `frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx`

**4.10** Form Drawer — Them fields:
- `received_date` (DatePicker — Ngay soan thao)
- Them `maxLength` cho tat ca Input: sub_number(20), notation(100), signer(200), document_code(100)
- File: `frontend/src/app/(main)/van-ban-du-thao/page.tsx`

**4.11** Hien thi `reject_reason` trong detail page khi VB bi tu choi
- File: `frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx`

### VB LIEN THONG (3 tasks)

**4.12** Detail page — Fix interface cho khop SP moi (sau Batch 2.16)
- Bo cac field khong co hoac them cho dung
- File: `frontend/src/app/(main)/van-ban-lien-thong/[id]/page.tsx`

**4.13** List page — Fix filter doc_type_id: bo hoac lam cho hoat dong
- Bo `processing` khoi STATUS_MAP
- File: `frontend/src/app/(main)/van-ban-lien-thong/page.tsx` (neu co)

**4.14** Them hien thi file dinh kem trong detail (sau khi co bang attachment_inter_incoming_docs)
- File: `frontend/src/app/(main)/van-ban-lien-thong/[id]/page.tsx`

### BOOKMARK (2 tasks)

**4.15** Them cot "Quan trong" (star icon) + toggle is_important
- Doi "So den" → "So VB"
- File: `frontend/src/app/(main)/van-ban-danh-dau/page.tsx`

**4.16** Them Filter tabs: Tat ca / VB den / VB di / Du thao
- File: `frontend/src/app/(main)/van-ban-danh-dau/page.tsx`

---

## BATCH 5: EXPORT EXCEL + IN

### 5.1 Shared utility: `createExcelExport()`
- Dung `exceljs` (da co dependency)
- Tao helper trong `backend/src/lib/excel.ts`
- Input: columns config + data rows → tra ve Buffer
- Auto: header row bold, column widths, date formatting, border

### 5.2 VB den — Export Excel
- Route: `GET /van-ban-den/xuat-excel`
- Columns: So den, Ngay den, So ky hieu, Trich yeu, CQ ban hanh, Nguoi ky, Loai VB, Linh vuc, So van ban
- File name: `VanBanDen_YYYYMMDD.xlsx`

### 5.3 VB di — Export Excel
- Route: `GET /van-ban-di/xuat-excel`
- Columns tuong tu + Don vi soan, Nguoi soan

### 5.4 VB du thao — Export Excel
- Route: `GET /van-ban-du-thao/xuat-excel`

### 5.5 Frontend — Them nut "Xuat Excel" tren thanh toolbar moi page
- Icon: DownloadOutlined
- Goi API → download file
- Files: 3 page.tsx (van-ban-den, van-ban-di, van-ban-du-thao)

---

## BATCH 6: INTEGRATION + SEED DATA

### 6.1 Chay migration 022 vao DB
### 6.2 Cap nhat seed_full_demo.sql — them data cho cac cot moi:
- `sents` cho incoming_docs
- `received_paper_date` cho incoming_docs co is_received_paper=true
- `reject_reason` cho drafting_docs bi tu choi
- `sent_by`, `expired_date` cho user_outgoing_docs / user_drafting_docs
- `is_important` cho mot so staff_notes
- leader_notes cho outgoing_docs / drafting_docs
- attachment_inter_incoming_docs data
- `organ_id`, `from_organ_id` cho inter_incoming_docs

### 6.3 Test toan bo flow:
- Dang nhap admin → tao VB den moi (tat ca fields) → duyet → gui → but phe → giao viec → xuat Excel
- Dang nhap nguyenvana → tao du thao → gui → duyet → phat hanh → tao VB di → gui → thu hoi → y kien lanh dao
- VB lien thong: xem chi tiet → nhan ban giao → verify tao VB den
- Bookmark: danh dau → quan trong → loc → bo danh dau

---

## THU TU THUC THI

```
Batch 1 (DB schema)     ──→ Batch 2 (SPs)     ──→ Batch 3 (Backend)
                                                       │
                                                       ├──→ Batch 4 (Frontend)
                                                       │
                                                       └──→ Batch 5 (Export Excel)
                                                                    │
                                                              Batch 6 (Integration)
```

**Batch 1+2**: Tao chung trong 1 file migration `022_doc_module_fixes.sql`
**Batch 3+4+5**: Co the chay song song (3 modules frontend doc lap)
**Batch 6**: Chay cuoi cung sau khi moi thu hoan thanh

---

## DANH SACH FILES CAN TAO/SUA

### Files moi:
| File | Muc dich |
|------|----------|
| `database/migrations/022_doc_module_fixes.sql` | Tat ca DB changes |
| `backend/src/lib/excel.ts` | Shared Excel export utility |

### Files sua:
| File | Batch |
|------|-------|
| `backend/src/routes/incoming-doc.ts` | 3.1, 3.2, 3.3 |
| `backend/src/repositories/incoming-doc.repository.ts` | 3.2 |
| `backend/src/routes/outgoing-doc.ts` | 3.5, 3.6, 3.7, 3.8 |
| `backend/src/repositories/outgoing-doc.repository.ts` | 3.4 |
| `backend/src/routes/drafting-doc.ts` | 3.10, 3.11 |
| `backend/src/repositories/drafting-doc.repository.ts` | 3.9 |
| `backend/src/routes/inter-incoming.ts` | 3.13 |
| `backend/src/repositories/inter-incoming.repository.ts` | 3.12 |
| `frontend/src/app/(main)/van-ban-den/page.tsx` | 4.1, 4.3 |
| `frontend/src/app/(main)/van-ban-den/[id]/page.tsx` | 4.2 |
| `frontend/src/app/(main)/van-ban-di/page.tsx` | 5.5 |
| `frontend/src/app/(main)/van-ban-di/[id]/page.tsx` | 4.4, 4.5, 4.6, 4.7 |
| `frontend/src/app/(main)/van-ban-du-thao/page.tsx` | 4.8, 4.10, 5.5 |
| `frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx` | 4.9, 4.11 |
| `frontend/src/app/(main)/van-ban-lien-thong/page.tsx` | 4.13 |
| `frontend/src/app/(main)/van-ban-lien-thong/[id]/page.tsx` | 4.12, 4.14 |
| `frontend/src/app/(main)/van-ban-danh-dau/page.tsx` | 4.15, 4.16 |
| `database/seed_full_demo.sql` | 6.2 |

**Tong: 2 files moi + 18 files sua**

---

## NHUNG GI CHUA LAM TRONG PLAN NAY (can them plan rieng)

Cac tinh nang lon can plan rieng (sprint tiep theo):
1. **Ky so VGCA** — Can tich hop SDK ky so, API VGCA SIM
2. **LGSP integration** — Worker pull VB tu LGSP, gui status len truc
3. **Gui nhanh (SendDocUserConfig)** — bang cau hinh + UI preset
4. **Chuyen luu tru** (Archive) — form phuc tap (ho so, phong, kho, thoi han...)
5. **Dynamic DocColumns** — Admin cau hinh form per loai VB
6. **But phe ket hop phan cong** — Modal but phe co section "Phan giai quyet ho so"
7. **In danh sach** — Template in cho trinh duyet
