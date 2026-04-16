# KE HOACH 7 TINH NANG CAN SPRINT RIENG

> Ngay tao: 2026-04-16
> Sap xep theo thu tu uu tien thuc thi (dependency chain)
> LUU Y: Ky so VGCA + LGSP lam GIA LAP (mock success) — chua tich hop that.
> Khi co SDK/API that chi can swap mock → real implementation.

---

## TONG QUAN

| # | Tinh nang | Do phuc tap | Phu thuoc | Uu tien |
|---|-----------|-------------|-----------|---------|
| S1 | Gui nhanh (SendDocUserConfig) | Thap | Staff module | 1 — lam truoc, dung cho S2 |
| S2 | But phe ket hop phan cong | Thap | S1 (preset) | 2 — core nghiep vu |
| S3 | Chuyen luu tru (MoveToArchive) | Trung binh | Schema esto | 3 — quan trong cho archiving |
| S4 | In danh sach | Thap | List pages | 4 — UX, de lam |
| S5 | Dynamic DocColumns | Trung binh | DocType, form VB | 5 — nice-to-have |
| S6 | LGSP Integration (Worker) | Cao | BullMQ, MinIO, edXML | 6 — can thoi gian R&D |
| S7 | Ky so VGCA | Cao | Attachment, VGCA agent | 7 — can VGCA SDK + test device |

**Tong uoc luong: ~7 sprints nho (moi sprint 1-2 ngay)**

---

## S1: GUI NHANH (SendDocUserConfig)
> Thoi gian: 0.5 ngay | Do kho: Thap

### Muc tieu
Moi user co danh sach preset nguoi nhan thuong gui. Khi mo modal "Gui VB" hoac "But phe", 
danh sach nay duoc tick san — tiet kiem thoi gian chon nguoi.

### DB
```sql
-- Bang moi
CREATE TABLE edoc.send_doc_user_configs (
  id SERIAL PRIMARY KEY,
  user_id INT NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
  target_user_id INT NOT NULL REFERENCES staff(id),
  config_type VARCHAR(20) NOT NULL DEFAULT 'doc', -- 'doc' (VB den) | 'handling' (HSCV)
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, target_user_id, config_type)
);

-- 3 SPs: get_by_user, save (bulk upsert), delete
```

### Backend
- `send-config.repository.ts` — CRUD
- Route trong `admin.ts` hoac route rieng `/cau-hinh-gui-nhanh`
  - `GET /` — lay danh sach config cua user dang nhap
  - `POST /` — luu (body: { target_user_ids: number[], config_type: string })

### Frontend
- Trang "Cau hinh gui nhanh" (hoac tab trong Thong tin ca nhan)
  - Transfer component: Available Staff ↔ Selected Staff
- Modal "Gui VB": load preset, tick san cac user da cau hinh
- Modal "But phe": load preset tuong tu

---

## S2: BUT PHE KET HOP PHAN CONG
> Thoi gian: 0.5 ngay | Do kho: Thap | Phu thuoc: S1

### Muc tieu
Modal but phe co them section "Phan giai quyet ho so":
- Han giai quyet (DatePicker — bat buoc)
- Chon can bo xu ly (multi-select — bat buoc, load preset tu S1)
→ Khi submit: tao leader_note + gui VB cho cac can bo duoc chon

### DB
```sql
-- Mo rong leader_notes: them expired_date, assigned_staff_ids
ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS expired_date TIMESTAMPTZ;
ALTER TABLE edoc.leader_notes ADD COLUMN IF NOT EXISTS assigned_staff_ids INT[];

-- SP: fn_leader_note_comment_and_assign
-- Logic: 
--   1. INSERT leader_note (content + expired_date + assigned_staff_ids)
--   2. INSERT user_incoming_docs cho moi staff (gui VB)
--   3. Neu co handling_doc_id → link
```

### Backend
- Update `fn_leader_note_create` → version moi ho tro `p_expired_date`, `p_staff_ids`
- Route: `POST /van-ban-den/:id/but-phe` (da co) — them 2 params optional

### Frontend
- Sua modal but phe o 3 detail pages (VB den/di/du thao):
  - Them Collapse/Switch "Phan cong giai quyet"
  - Khi bat: hien DatePicker + Select multi (load preset tu S1)
  - Submit: gui ca content + expired_date + staff_ids

---

## S3: CHUYEN LUU TRU (MoveToArchive)
> Thoi gian: 1 ngay | Do kho: Trung binh

### Muc tieu  
Tu VB den/di da xu ly xong, chuyen vao luu tru voi day du metadata:
phong, kho, ho so, but tich, thoi han, tinh trang vat ly...

### DB
```sql
-- Bang moi (trong schema esto — da co tu migration 016)
-- Can them: esto.document_archives (lien ket VB ↔ record)
CREATE TABLE IF NOT EXISTS esto.document_archives (
  id BIGSERIAL PRIMARY KEY,
  doc_type VARCHAR(20) NOT NULL,     -- 'incoming' | 'outgoing'
  doc_id BIGINT NOT NULL,
  fond_id INT REFERENCES esto.fonds(id),
  warehouse_id INT REFERENCES esto.warehouses(id),
  record_id BIGINT REFERENCES esto.records(id),
  file_catalog VARCHAR(200),         -- Muc luc ho so
  file_notation VARCHAR(100),        -- Ky hieu ho so
  doc_ordinal INT,                   -- Thu tu VB trong ho so
  language VARCHAR(50) DEFAULT 'Tiếng Việt',
  autograph TEXT,                    -- But tich
  keyword TEXT,                      -- Tu khoa
  format VARCHAR(50),                -- Dinh dang (giay/dien tu)
  confidence_level VARCHAR(50),      -- Muc do tin cay
  is_original BOOLEAN DEFAULT true,  -- Ban goc
  archive_date TIMESTAMPTZ DEFAULT NOW(),
  archived_by INT REFERENCES staff(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3 SPs: create_archive, get_archive_by_doc, list_archives
```

### Backend
- `archive.repository.ts` — CRUD
- Routes trong `incoming-doc.ts` va `outgoing-doc.ts`:
  - `POST /:id/chuyen-luu-tru` — tao archive record
  - `GET /:id/luu-tru` — xem thong tin luu tru
- Update `incoming_docs.archive_status = true` khi chuyen

### Frontend
- Modal "Chuyen luu tru" (form phuc tap):
  - Row 1: Phong luu tru (Select) + Kho luu tru (Select)
  - Row 2: Ho so (Select — tu esto.records) + Thu tu (InputNumber)
  - Row 3: Muc luc + Ky hieu ho so
  - Row 4: Ngon ngu + Dinh dang + Ban goc (checkbox)
  - Row 5: But tich (TextArea)
  - Row 6: Tu khoa (TextArea)
- Nut "Chuyen luu tru" tren detail page VB den/di (chi khi da duyet)

---

## S4: IN DANH SACH
> Thoi gian: 0.5 ngay | Do kho: Thap

### Muc tieu
Nut "In" tren trang danh sach VB den/di/du thao — mo cua so in trinh duyet.

### Cach tiep can
Source cu dung `window.print()` voi CSS print — ta lam tuong tu.
KHONG can server-side PDF — trinh duyet xu ly.

### Frontend
- Tao component `PrintableTable`:
  ```tsx
  // Render hidden div voi table data
  // Khi click "In": window.print() voi @media print CSS
  ```
- Them CSS print vao `globals.css`:
  ```css
  @media print {
    body * { visibility: hidden; }
    .printable-area, .printable-area * { visibility: visible; }
    .printable-area { position: absolute; left: 0; top: 0; width: 100%; }
    @page { size: landscape; margin: 1cm; }
  }
  ```
- Nut "In" ben canh "Xuat Excel" tren 3 trang list
- Template in: Header (ten co quan + tieu de), Table (giong Excel columns), Footer (ngay in + trang)

### Backend
Khong can — du lieu da co tu API list.

---

## S5: DYNAMIC DOC COLUMNS
> Thoi gian: 1.5 ngay | Do kho: Trung binh

### Muc tieu
Admin cau hinh truong nao hien thi trong form VB theo tung loai VB.
VD: "Cong van" hien 10 truong, "Quyet dinh" hien 12 truong (them "Hieu luc tu/den").

### DB
```sql
CREATE TABLE edoc.doc_columns (
  id SERIAL PRIMARY KEY,
  doc_type_id INT NOT NULL REFERENCES edoc.doc_types(id) ON DELETE CASCADE,
  column_name VARCHAR(100) NOT NULL,   -- ten truong (map vao form field)
  label VARCHAR(200) NOT NULL,         -- nhan hien thi
  data_type VARCHAR(50) DEFAULT 'text', -- text|number|date|select|textarea
  max_length INT,
  sort_order INT DEFAULT 0,
  is_mandatory BOOLEAN DEFAULT false,
  is_system BOOLEAN DEFAULT false,     -- truong he thong (ko xoa duoc)
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- SPs: get_by_doc_type, save, delete, get_all (admin)
```

### Backend
- `doc-column.repository.ts` + routes CRUD (admin)
- `GET /quan-tri/loai-van-ban/:id/truong` — lay columns theo doc_type
- `POST /quan-tri/loai-van-ban/:id/truong` — luu (bulk)

### Frontend  
**Admin page:**
- Trang `/quan-tri/cau-hinh-truong-van-ban`
- Chon loai VB → hien danh sach columns (drag-drop sort)
- Them/Sua/Xoa column (Drawer)

**Form VB den/di/du thao:**
- Khi render form, query `GET /truong?doc_type_id=X`
- Render dynamic fields theo `data_type`:
  - `text` → Input, `number` → InputNumber, `date` → DatePicker
  - `textarea` → TextArea, `select` → Select (chua ro options)
- Validate theo `is_mandatory`
- Luu: them vao JSON field `extra_fields` tren VB (can ALTER TABLE)

---

## S6: LGSP INTEGRATION (Worker)
> Thoi gian: 2-3 ngay | Do kho: Cao

### Muc tieu
Worker tu dong pull VB tu truc LGSP, parse edXML, luu vao inter_incoming_docs.
Gui status ve truc sau moi action.

### Kien truc
```
[Truc LGSP] ←→ [LGSP Proxy (REST)] ←→ [BullMQ Worker] ←→ [PostgreSQL]
```

Source cu dung DLL `edVNPT.Edoc.edXML` (Windows-only). 
Phuong an moi: tao LGSP REST Proxy (Node.js wrapper) hoac dung API truc tiep neu LGSP co REST API.

### DB
- Da co: `edoc.inter_incoming_docs`, `edoc.lgsp_tracking`, `edoc.lgsp_organizations`
- Them: `edoc.lgsp_config` (endpoint, credentials, polling interval)
```sql
CREATE TABLE edoc.lgsp_config (
  id SERIAL PRIMARY KEY,
  unit_id INT REFERENCES departments(id),
  endpoint_url VARCHAR(500) NOT NULL,
  org_code VARCHAR(100) NOT NULL,
  username VARCHAR(100),
  password VARCHAR(200),
  polling_interval_sec INT DEFAULT 300,
  is_active BOOLEAN DEFAULT true,
  last_sync_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Backend (Worker)
- `workers/src/lgsp-worker.ts`:
  - BullMQ repeatable job (polling interval tu config)
  - Job logic:
    1. Goi LGSP API `List()` → lay danh sach VB moi
    2. Download file edXML
    3. Parse XML → extract fields + attachments (Base64 decode)
    4. Luu vao `inter_incoming_docs` + `attachment_inter_incoming_docs`
    5. Gui status "02" (da nhan) ve truc LGSP
  - Error handling: retry 3 lan, ghi log vao `lgsp_tracking`

- `workers/src/lgsp-sender.ts`:
  - Job: gui VB di ra truc LGSP
  - Logic: doc `lgsp_tracking` status='pending', build edXML, gui qua LGSP API

### Frontend
- Admin: Trang cau hinh LGSP (`/quan-tri/lgsp`)
  - Form: endpoint, org_code, username/password, interval
  - Nut "Dong bo ngay" (trigger manual)
  - Log: hien thi lgsp_tracking records

### Luu y
- Can tai lieu API LGSP cua tinh (endpoint, auth method, edXML schema)
- Co the can VPN/whitelist IP de truy cap truc LGSP
- Nen test voi mock server truoc khi ket noi that

---

## S7: KY SO VGCA
> Thoi gian: 2 ngay | Do kho: Cao

### Muc tieu
Ky so per-attachment bang VGCA SIM (qua desktop agent), xac thuc chu ky.

### Kien truc
```
[Frontend] ←WebSocket→ [VGCA Desktop Agent (localhost:8987)] → ky file
[Frontend] → [Backend API] → verify PDF signature (server-side)
```

### DB
```sql
-- Them cot vao 3 bang attachment
ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS is_ca BOOLEAN DEFAULT false;
ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS ca_date TIMESTAMPTZ;
ALTER TABLE edoc.attachment_incoming_docs ADD COLUMN IF NOT EXISTS signed_file_path VARCHAR(1000);

-- Tuong tu cho outgoing + drafting
-- SP: fn_attachment_update_ca_status
```

### Backend
- `digital-signature.ts` route:
  - `POST /xac-thuc-chu-ky` — upload file PDF, verify signature (dung thu vien pdf-lib hoac node-forge)
  - `PATCH /van-ban-den/:id/dinh-kem/:attId/ky-so` — cap nhat is_ca, ca_date, signed_file_path

### Frontend
- Component `SignButton` (reusable):
  ```tsx
  // 1. Lay file URL tu MinIO (presigned)
  // 2. Mo WebSocket den wss://127.0.0.1:8987
  // 3. Gui { FileUploadHandler: fileUrl, SessionId: uuid }
  // 4. Nhan response { Status: 0, FileServer: signedPath }
  // 5. Upload signed file len MinIO
  // 6. Goi API cap nhat attachment
  ```
- Hien thi badge "Da ky so" (mau xanh) + "Ngay ky: dd/MM/yyyy" tren attachment row
- Nut "Xac thuc" — goi backend verify endpoint

### Luu y
- Can cai VGCA Desktop Agent tren may user
- WebSocket chi hoat dong tren localhost (bao mat)
- Can test voi USB token hoac SIM PKI that
- Fallback: neu khong co VGCA agent → hien thong bao cai dat

---

## THU TU THUC THI

```
Tuan 1:  S1 (Gui nhanh)     → S2 (But phe + phan cong) → S4 (In danh sach)
Tuan 2:  S3 (Chuyen luu tru) → S5 (Dynamic DocColumns)
Tuan 3+: S6 (LGSP Worker)    → S7 (Ky so VGCA)
```

S1→S2 phu thuoc, lam lien.
S3, S4, S5 doc lap, co the lam song song.
S6, S7 phuc tap, can R&D truoc.

---

## TONG FILES CAN TAO/SUA

| Sprint | Files moi | Files sua |
|--------|-----------|-----------|
| S1 | migration, repository, route, 1 frontend page | 3 modal gui VB |
| S2 | migration (ALTER) | 3 detail pages (modal but phe) |
| S3 | migration, repository, route | 2 detail pages (modal archive) |
| S4 | PrintableTable component, CSS | 3 list pages |
| S5 | migration, repository, route, admin page | 3 form drawers |
| S6 | lgsp-config migration, worker file, admin page | — |
| S7 | migration (ALTER), SignButton component, route | 3 detail pages |
