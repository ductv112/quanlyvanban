# KIẾN TRÚC HỆ THỐNG — QUẢN LÝ VĂN BẢN (MỚI)
> Phiên bản: 2.0 | Ngày cập nhật: 2026-04-13

---

## 1. TỔNG QUAN KIẾN TRÚC

```
┌─────────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                             │
│  ┌──────────────┐  ┌──────────────┐  ┌───────────────────────┐  │
│  │  Web Browser  │  │  Mobile App  │  │  Đơn vị ngoài (LGSP) │  │
│  │  (Next.js)    │  │  (PWA/React  │  │  edXML / REST API     │  │
│  │  + Ant Design │  │   Native)    │  │                       │  │
│  └──────┬───────┘  └──────┬───────┘  └───────────┬───────────┘  │
│         │                 │                       │              │
└─────────┼─────────────────┼───────────────────────┼──────────────┘
          │ :3000           │                       │
          ▼                 ▼                       │
┌──────────────────────────────────────┐            │
│       FRONTEND (Next.js 16)          │            │
│  App Router, SSR/CSR, Ant Design 6   │            │
│  Zustand state, Axios HTTP client    │            │
│  Port 3000 — CHỈ UI, không API      │            │
└──────────────┬───────────────────────┘            │
               │ HTTP (Axios)                       │
               ▼                                    ▼
┌──────────────────────────────────────────────────────────────────┐
│                    BACKEND (Express 5 + TypeScript)               │
│                         Port 4000                                │
│  ┌─────────────┐  ┌──────────────┐  ┌────────────────────────┐   │
│  │  Routes      │  │  Middleware  │  │  Socket.IO Server      │   │
│  │  /api/*      │  │  Auth, RBAC  │  │  (Real-time)           │   │
│  │              │  │  Rate Limit  │  │                        │   │
│  └──────┬──────┘  └──────────────┘  └────────────────────────┘   │
│         │                                                        │
│  ┌──────▼──────────────────────────────────────────────────────┐  │
│  │              SERVICE LAYER (TypeScript)                      │  │
│  │  Business logic, validation, orchestration                  │  │
│  │  ┌──────────────┐ ┌──────────────┐ ┌────────────────────┐  │  │
│  │  │ Document     │ │ Workflow     │ │ Notification       │  │  │
│  │  │ Service      │ │ Service      │ │ Service            │  │  │
│  │  └──────────────┘ └──────────────┘ └────────────────────┘  │  │
│  └──────────────────────────┬─────────────────────────────────┘  │
│                             │                                    │
│  ┌──────────────────────────▼─────────────────────────────────┐  │
│  │            REPOSITORY LAYER (TypeScript)                    │  │
│  │  Gọi PostgreSQL Stored Procedures qua node-postgres (pg)   │  │
│  │  Type-safe request/response interfaces                     │  │
│  └──────────────────────────┬─────────────────────────────────┘  │
│                             │                                    │
└─────────────────────────────┼────────────────────────────────────┘
                              │
┌─────────────────────────────┼────────────────────────────────────┐
│                             ▼                                    │
│  ┌──────────┐  ┌──────────┐  ┌───────┐  ┌───────┐  ┌────────┐  │
│  │PostgreSQL│  │ MongoDB  │  │ Redis │  │ MinIO │  │BullMQ  │  │
│  │  16      │  │  7       │  │   7   │  │(Files)│  │Workers │  │
│  │  + SPs   │  │  (Log)   │  │(Cache)│  │  S3   │  │(Jobs)  │  │
│  └──────────┘  └──────────┘  └───────┘  └───────┘  └────────┘  │
│                      DATA LAYER                                  │
└──────────────────────────────────────────────────────────────────┘
                              │
┌─────────────────────────────┼────────────────────────────────────┐
│                             ▼                                    │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌─────────────────┐  │
│  │  LGSP    │  │  VNPT    │  │ Firebase │  │  Zalo OA API   │  │
│  │  Lạng Sơn│  │ SmartCA  │  │   FCM    │  │                │  │
│  │  (edXML) │  │  + NEAC  │  │          │  │                │  │
│  └──────────┘  └──────────┘  └──────────┘  └─────────────────┘  │
│                  EXTERNAL SERVICES                               │
└──────────────────────────────────────────────────────────────────┘
```

---

## 2. MONOREPO — CẤU TRÚC DỰ ÁN

```
quanlyvanban/
├── docs/                               # Tài liệu dự án
│   ├── architecture.md                 # File này
│   ├── function_list.md
│   ├── phan_tich_he_thong_cu.md
│   └── screen_short/                   # Screenshots hệ thống cũ
│
├── e_office_app_new/                   # Source code chính
│   ├── docker-compose.yml              # PostgreSQL + MongoDB + Redis + MinIO
│   ├── ROADMAP.md                      # Sprint plan chi tiết
│   │
│   ├── database/                       # ★ Database layer
│   │   ├── init/
│   │   │   └── 01_create_schemas.sql   # Schemas + extensions
│   │   ├── migrations/                 # Versioned migration files
│   │   │   ├── 001_system_tables.sql   # public.* tables
│   │   │   ├── 002_edoc_tables.sql     # edoc.* tables
│   │   │   ├── 003_auth_stored_procedures.sql
│   │   │   └── ...
│   │   └── stored_procedures/          # SP files theo schema (khi tách riêng)
│   │       ├── public/                 # fn_auth_*, fn_staff_*, fn_department_*
│   │       ├── edoc/                   # fn_incoming_doc_*, fn_outgoing_doc_*
│   │       ├── esto/                   # fn_archive_*, fn_borrow_*
│   │       ├── cont/                   # fn_contract_*
│   │       └── iso/                    # fn_iso_doc_*
│   │
│   ├── backend/                        # ★ Express 5 + TypeScript (port 4000)
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   ├── .env.example
│   │   └── src/
│   │       ├── server.ts               # Express app entry point
│   │       ├── routes/                 # API route handlers
│   │       │   ├── auth.ts             # /api/auth/*
│   │       │   ├── health.ts           # /api/health
│   │       │   ├── incoming-doc.ts     # /api/van-ban/den/*
│   │       │   ├── outgoing-doc.ts     # /api/van-ban/di/*
│   │       │   ├── handling-doc.ts     # /api/ho-so-cong-viec/*
│   │       │   ├── admin.ts            # /api/quan-tri/*
│   │       │   └── ...
│   │       ├── services/               # Business logic
│   │       │   ├── auth.service.ts
│   │       │   ├── incoming-doc.service.ts
│   │       │   ├── notification.service.ts
│   │       │   └── ...
│   │       ├── repositories/           # Data access (gọi SP)
│   │       │   ├── auth.repository.ts
│   │       │   ├── incoming-doc.repository.ts
│   │       │   ├── staff.repository.ts
│   │       │   └── ...
│   │       ├── middleware/             # Express middleware
│   │       │   └── auth.ts            # JWT verify + RBAC
│   │       └── lib/                   # Shared utilities
│   │           ├── db/
│   │           │   ├── pool.ts        # PostgreSQL connection pool
│   │           │   └── query.ts       # Type-safe SP caller
│   │           ├── redis/
│   │           │   └── client.ts      # Redis + cache helpers
│   │           ├── mongodb/
│   │           │   └── client.ts      # MongoDB (logging only)
│   │           ├── minio/
│   │           │   └── client.ts      # MinIO S3 client
│   │           ├── auth/
│   │           │   ├── jwt.ts         # JWT sign/verify (jose)
│   │           │   └── password.ts    # bcrypt hash/compare
│   │           └── socket/
│   │               └── server.ts      # Socket.IO setup
│   │
│   ├── frontend/                       # ★ Next.js 16 + Ant Design 6 (port 3000)
│   │   ├── package.json
│   │   ├── next.config.ts
│   │   ├── tsconfig.json
│   │   ├── .env.example
│   │   └── src/
│   │       ├── app/                   # App Router
│   │       │   ├── (auth)/            # Auth pages (no sidebar)
│   │       │   │   └── login/page.tsx
│   │       │   ├── (main)/            # Main layout (sidebar + header)
│   │       │   │   ├── layout.tsx
│   │       │   │   ├── dashboard/page.tsx
│   │       │   │   ├── van-ban/
│   │       │   │   │   ├── den/page.tsx
│   │       │   │   │   ├── di/page.tsx
│   │       │   │   │   ├── du-thao/page.tsx
│   │       │   │   │   └── lien-thong/page.tsx
│   │       │   │   ├── ho-so-cong-viec/
│   │       │   │   ├── hop-khong-giay/
│   │       │   │   ├── hop-dong/
│   │       │   │   ├── kho-luu-tru/
│   │       │   │   ├── tai-lieu/
│   │       │   │   ├── tin-nhan/
│   │       │   │   ├── tien-ich/
│   │       │   │   └── quan-tri/
│   │       │   │       ├── nguoi-dung/
│   │       │   │       ├── nhom-quyen/
│   │       │   │       ├── chuc-nang/
│   │       │   │       ├── don-vi/
│   │       │   │       ├── danh-muc-vb/
│   │       │   │       └── cau-hinh/
│   │       │   ├── layout.tsx         # Root layout (font, AntdProvider)
│   │       │   ├── page.tsx           # Redirect → /login hoặc /dashboard
│   │       │   └── globals.css
│   │       ├── components/
│   │       │   ├── layout/            # MainLayout, Sidebar, Header
│   │       │   ├── shared/            # OrgTree, FileUpload, RichEditor
│   │       │   ├── dashboard/         # Widget components
│   │       │   ├── van-ban/           # Document-specific components
│   │       │   ├── workflow/          # React Flow components
│   │       │   └── ui/               # Base wrappers
│   │       ├── stores/                # Zustand stores
│   │       │   ├── auth.store.ts
│   │       │   ├── notification.store.ts
│   │       │   └── sidebar.store.ts
│   │       ├── hooks/                 # React hooks
│   │       │   ├── use-auth.ts
│   │       │   └── use-incoming-docs.ts
│   │       ├── lib/
│   │       │   └── api.ts            # Axios client (→ backend:4000)
│   │       ├── config/
│   │       │   ├── theme.ts          # Ant Design theme
│   │       │   └── constants.ts
│   │       └── types/                 # Frontend-specific types
│   │
│   ├── shared/                         # ★ Types + constants dùng chung
│   │   └── src/
│   │       ├── types/
│   │       │   ├── auth.ts
│   │       │   ├── api.ts
│   │       │   ├── edoc.ts           # IncomingDoc, OutgoingDoc, HandlingDoc...
│   │       │   ├── dbo.ts            # Staff, Department, Role, Right...
│   │       │   ├── esto.ts           # Storage entities
│   │       │   └── cont.ts           # Contract entities
│   │       └── constants/
│   │           └── index.ts
│   │
│   └── workers/                        # ★ BullMQ background jobs
│       ├── package.json
│       └── src/
│           ├── index.ts               # Worker entry point
│           ├── queues/                # Queue definitions
│           └── jobs/                  # Job handlers
│               ├── email-send.ts
│               ├── sms-send.ts
│               ├── lgsp-receive.ts
│               ├── lgsp-send.ts
│               ├── fcm-push.ts
│               ├── zalo-message.ts
│               ├── pdf-convert.ts
│               └── report-export.ts
│
└── .gitignore
```

---

## 3. TECH STACK CHI TIẾT

### 3.1 Frontend (frontend/)

| Thành phần | Công nghệ | Phiên bản | Ghi chú |
|-----------|-----------|-----------|---------|
| Framework | **Next.js** (App Router) | 16.x | SSR + CSR, CHỈ UI (không API Routes) |
| UI Library | **Ant Design** | 6.x | Custom theme, KHÔNG dùng default |
| State management | **Zustand** | 5.x | Nhẹ, đơn giản hơn Redux |
| HTTP Client | **Axios** | 1.x | Gọi backend:4000, interceptors cho JWT |
| Workflow Designer | **React Flow** | 12.x | Miễn phí, React-native |
| Dashboard Layout | **react-grid-layout** | 1.x | Drag & drop widget |
| Charts | **Ant Design Charts** (@ant-design/charts) | 2.x | Biểu đồ báo cáo |
| Tree View | **Ant Design Tree** | — | Cây tổ chức, cây chức năng |
| PDF Viewer | **react-pdf** | 9.x | Xem VB trực tuyến |
| Rich Text Editor | **TipTap** | 2.x | Soạn thảo VB, bút phê |
| Calendar | **Ant Design Calendar** hoặc **FullCalendar** | — | Lịch cá nhân/cơ quan |
| Date | **dayjs** | 1.x | Xử lý ngày tháng |
| Number format | **numeral** | 2.x | Định dạng số |
| Icons | **@ant-design/icons** | 6.x | |
| QR/Barcode | **qrcode.react** + **jsbarcode** | — | Mã QR + mã vạch |

### 3.2 Backend (backend/)

| Thành phần | Công nghệ | Phiên bản | Ghi chú |
|-----------|-----------|-----------|---------|
| Framework | **Express** | 5.x | REST API server, tách riêng khỏi frontend |
| Runtime | **Node.js** | 20 LTS | |
| Language | **TypeScript** | 6.x | Strict mode |
| PostgreSQL Driver | **node-postgres (pg)** | 8.x | Gọi SP trực tiếp, pool connection |
| MongoDB Driver | **mongoose** | 9.x | Chỉ cho log/audit |
| Redis Client | **ioredis** | 5.x | Cache + Bull queue |
| Job Queue | **BullMQ** | 5.x | Background jobs |
| Real-time | **Socket.IO** | 4.x | Tích hợp trong Express server |
| Auth | **jose** (JWT) | 6.x | JWT sign/verify, KHÔNG dùng Passport |
| Password Hash | **bcryptjs** | 3.x | |
| File Upload | **MinIO SDK** (@minio/minio-js) | 8.x | S3-compatible |
| PDF Processing | **pdf-lib** | 1.x | Ký số, chèn ảnh chữ ký |
| Excel Export | **exceljs** | 4.x | Xuất báo cáo Excel |
| Email | **nodemailer** | 8.x | SMTP sender |
| Validation | **zod** | 4.x | Request validation |
| Logging | **pino** + **pino-http** | 10.x | Structured JSON log |
| Security | **helmet** + **cors** + **compression** | — | HTTP security headers |

### 3.3 Database

| Database | Vai trò | Chi tiết |
|----------|---------|----------|
| **PostgreSQL 16** | Database chính | Stored Procedures cho toàn bộ data access. Functions trả về TABLE/SETOF. Full-text search (tsvector + pg_trgm). |
| **MongoDB 7** | Log & Audit | Access log, action log, error log. |
| **Redis 7** | Cache + Queue | Cache danh mục. BullMQ job queue. |

### 3.4 Infrastructure

| Thành phần | Công nghệ | Ghi chú |
|-----------|-----------|---------|
| File Storage | **MinIO** | S3-compatible, self-hosted |
| Containerization | **Docker Compose** | Dev: 4 services (PG, Mongo, Redis, MinIO) |
| Reverse Proxy | **Nginx** (production) | SSL, load balance |
| CI/CD | GitHub Actions | |

---

## 4. DATA ACCESS PATTERN — STORED PROCEDURES

### 4.1 Nguyên tắc thiết kế

```
Frontend (Next.js :3000)
     │
     │  Axios HTTP
     ▼
Backend (Express :4000)
     │
     ├── Routes (Controller)     ← Parse request, auth check, return JSON
     ├── Services (Business)     ← Validation, orchestration, error handling
     └── Repositories (Data)     ← pool.query() gọi SP, map result, type-safe
              │
              ▼
         PostgreSQL
         Stored Procedures
         (fn_xxx_get, fn_xxx_save, fn_xxx_delete)
```

### 4.2 Quy ước đặt tên Stored Procedures

```sql
-- Pattern: {schema}.fn_{module}_{action}
-- Schema mapping:
--   public.*   → Auth, Staff, Department, Role, Right, Position, Config
--   edoc.*     → Văn bản, HSCV, Workflow, Lịch, Họp, Tin nhắn
--   esto.*     → Kho lưu trữ
--   cont.*     → Hợp đồng
--   iso.*      → Tài liệu ISO

-- Ví dụ:
public.fn_auth_login(p_username VARCHAR)
public.fn_staff_get_list(p_unit_id INT, p_keyword VARCHAR, p_page INT, p_page_size INT)
public.fn_department_get_tree(p_unit_id INT)

edoc.fn_incoming_doc_get_list(p_unit_id INT, p_filters JSONB, p_page INT, p_page_size INT)
edoc.fn_incoming_doc_get_by_id(p_id INT, p_staff_id INT)
edoc.fn_incoming_doc_save(p_id INT, p_data JSONB, p_user_id INT)
edoc.fn_incoming_doc_delete(p_id INT, p_user_id INT)
edoc.fn_incoming_doc_search(p_keyword TEXT, p_unit_id INT)

edoc.fn_handling_doc_get_list(p_unit_id INT, p_filter_type VARCHAR, p_page INT, p_page_size INT)
edoc.fn_handling_doc_change_status(p_id INT, p_new_status INT, p_user_id INT)

esto.fn_doc_archive_get_list(p_warehouse_id INT, p_page INT, p_page_size INT)
cont.fn_contract_get_list(p_type_id INT, p_page INT, p_page_size INT)

-- Procedures (không trả dữ liệu):
public.fn_auth_log_login(p_staff_id INT, p_username VARCHAR, p_ip VARCHAR, p_user_agent TEXT, p_success BOOLEAN)
public.fn_auth_save_refresh_token(p_staff_id INT, p_token_hash VARCHAR, p_expires_at TIMESTAMPTZ)
```

### 4.3 Connection Pool & Repository Pattern

```typescript
// backend/src/lib/db/pool.ts
import { Pool } from 'pg';

export const pool = new Pool({
  host: process.env.PG_HOST,
  port: Number(process.env.PG_PORT),
  database: process.env.PG_DATABASE,
  user: process.env.PG_USER,
  password: process.env.PG_PASSWORD,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// backend/src/lib/db/query.ts — type-safe SP caller
export async function callFunction<T>(
  functionName: string,       // "public.fn_auth_login" hoặc "edoc.fn_incoming_doc_get_list"
  params: unknown[] = []
): Promise<T[]> {
  const placeholders = params.map((_, i) => `$${i + 1}`).join(', ');
  const sql = `SELECT * FROM ${functionName}(${placeholders})`;
  const result = await pool.query(sql, params);
  return result.rows as T[];
}
```

```typescript
// backend/src/repositories/incoming-doc.repository.ts
import { callFunction, callFunctionOne } from '../lib/db/query.js';
import type { IncomingDoc } from '@shared/types/edoc';

export const incomingDocRepository = {
  async getList(unitId: number, filters: object, page: number, pageSize: number) {
    return callFunction<IncomingDoc>(
      'edoc.fn_incoming_doc_get_list',
      [unitId, JSON.stringify(filters), page, pageSize]
    );
  },

  async getById(id: number, staffId: number) {
    return callFunctionOne<IncomingDoc>(
      'edoc.fn_incoming_doc_get_by_id',
      [id, staffId]
    );
  },

  async save(id: number | null, data: Partial<IncomingDoc>, userId: number) {
    return callFunctionOne<{ id: number }>(
      'edoc.fn_incoming_doc_save',
      [id, JSON.stringify(data), userId]
    );
  },

  async delete(id: number, userId: number) {
    await callFunction('edoc.fn_incoming_doc_delete', [id, userId]);
  },
};
```

```typescript
// backend/src/services/incoming-doc.service.ts
import { incomingDocRepository } from '../repositories/incoming-doc.repository.js';
import { minioClient } from '../lib/minio/client.js';
import { notificationService } from './notification.service.js';

export const incomingDocService = {
  async create(data: CreateIncomingDocInput, userId: number) {
    // 1. Validate business rules (TypeScript)
    // 2. Save to DB (SP)
    const result = await incomingDocRepository.save(null, data, userId);
    // 3. Upload attachments (MinIO)
    // 4. Notify (Socket.IO + BullMQ)
    return result;
  },
};
```

### 4.4 Multi-result-set (khi cần lấy nhiều data cùng lúc)

```typescript
// backend/src/repositories/incoming-doc.repository.ts
import { pool } from '../lib/db/pool.js';

export async function getIncomingDocDetail(id: number, staffId: number) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const doc = await client.query(
      'SELECT * FROM edoc.fn_incoming_doc_get_by_id($1, $2)', [id, staffId]
    );
    const attachments = await client.query(
      'SELECT * FROM edoc.fn_attachment_incoming_get_list($1)', [id]
    );
    const leaderNotes = await client.query(
      'SELECT * FROM edoc.fn_leader_note_get_list($1)', [id]
    );
    const recipients = await client.query(
      'SELECT * FROM edoc.fn_incoming_doc_get_recipients($1)', [id]
    );

    await client.query('COMMIT');
    return {
      doc: doc.rows[0],
      attachments: attachments.rows,
      leaderNotes: leaderNotes.rows,
      recipients: recipients.rows,
    };
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally {
    client.release();
  }
}
```

---

## 5. AUTHENTICATION & AUTHORIZATION

### 5.1 JWT Flow

```
Login:  POST /api/auth/login  (→ backend:4000)
        { username, password }
            │
            ▼
        Verify bcrypt(password, hash)
            │
            ▼
        Generate JWT:
        ┌──────────────────────────────────────┐
        │ Access Token  (15 phút)              │
        │ { staffId, unitId, departmentId,     │
        │   username, roles: ["Quản trị HT"] } │
        ├──────────────────────────────────────┤
        │ Refresh Token (7 ngày)               │
        │ Lưu hash trong DB + HttpOnly cookie  │
        └──────────────────────────────────────┘
            │
            ▼
        Response: { accessToken, user }
        Set-Cookie: refreshToken=xxx; HttpOnly; Secure; SameSite=Lax; Path=/api/auth

Token Refresh:  POST /api/auth/refresh
        Cookie: refreshToken=xxx
            │
            ▼
        Verify JWT → Check hash in DB → Revoke old → Issue new pair (rotation)
```

### 5.2 RBAC (Role-Based Access Control)

```
Staff ──┤has many├── RoleOfStaff ──┤belongs to├── Role
                                                    │
                                               ┤has many├
                                                    │
                                              ActionOfRole
                                                    │
                                               ┤belongs to├
                                                    │
                                                  Right (Action/Menu)
```

Backend middleware kiểm tra:
1. JWT valid? → 401 Unauthorized
2. User có role cần thiết? → 403 Forbidden
3. Role có quyền truy cập action này? → 403 Forbidden

---

## 6. BACKGROUND JOBS (BullMQ)

> Workers chạy trong process riêng (`workers/`), kết nối Redis queue

| Queue | Chức năng | Trigger |
|-------|-----------|---------|
| `lgsp-receive` | Nhận VB liên thông từ trục LGSP | Polling mỗi 1 phút |
| `lgsp-send` | Gửi VB liên thông đi | Event-driven (khi phát hành VB) |
| `fcm-push` | Push notification mobile | Event-driven |
| `zalo-message` | Gửi tin Zalo OA | Event-driven |
| `email-send` | Gửi email thông báo | Event-driven |
| `sms-send` | Gửi SMS | Event-driven |
| `pdf-convert` | DOCX → PDF (LibreOffice headless) | Khi upload file |
| `report-export` | Xuất báo cáo Excel lớn | Khi user request |

---

## 7. REAL-TIME (Socket.IO)

> Socket.IO server tích hợp trong Express backend

```typescript
// Events
socket.emit('notification:new', { type, message, data });
socket.emit('document:updated', { docId, action });
socket.emit('message:new', { fromStaffId, subject });
socket.emit('vote:start', { roomId, voteId, options, countdown });
socket.emit('vote:cast', { roomId, voteId, optionId });
socket.emit('vote:result', { roomId, voteId, results });
```

Rooms: `unit:{unitId}`, `department:{deptId}`, `user:{staffId}`, `meeting:{roomId}`

---

## 8. FILE STORAGE (MinIO)

```
Bucket: documents
├── incoming/{docId}/{filename}       # VB đến
├── outgoing/{docId}/{filename}       # VB đi
├── drafting/{docId}/{filename}       # Dự thảo
├── handling/{handlingId}/{filename}  # HSCV
├── meeting/{scheduleId}/{filename}   # Cuộc họp
├── contract/{contractId}/{filename}  # Hợp đồng
├── storage/{archiveId}/{filename}    # Kho lưu trữ
├── iso/{isoDocId}/{filename}         # ISO
└── avatar/{staffId}.jpg              # Ảnh đại diện

Bucket: temp
└── uploads/{sessionId}/{filename}    # File tạm khi upload
```

---

## 9. LOGGING (MongoDB)

```javascript
// Collection: access_logs
{
  timestamp: ISODate,
  staffId: 1,
  action: "VIEW_INCOMING_DOC",
  resourceType: "IncomingDoc",
  resourceId: 123,
  ip: "192.168.1.1",
  userAgent: "...",
  duration: 45  // ms
}

// Collection: change_logs
{
  timestamp: ISODate,
  staffId: 1,
  action: "UPDATE",
  table: "edoc.incoming_docs",
  recordId: 123,
  oldValues: { abstract: "...", urgent_id: 1 },
  newValues: { abstract: "...", urgent_id: 2 },
}

// Collection: error_logs
{
  timestamp: ISODate,
  level: "error",
  message: "...",
  stack: "...",
  context: { route: "/api/van-ban/den", method: "POST" }
}
```

---

## 10. CACHING STRATEGY (Redis)

| Key Pattern | TTL | Dữ liệu |
|-------------|-----|----------|
| `departments:{unitId}` | 1 giờ | Danh sách phòng ban |
| `positions` | 24 giờ | Danh sách chức vụ |
| `doc_types:{unitId}` | 1 giờ | Loại văn bản |
| `doc_fields:{unitId}` | 1 giờ | Lĩnh vực VB |
| `doc_books:{unitId}:{typeId}` | 30 phút | Sổ văn bản |
| `rights:{roleId}` | 15 phút | Quyền của nhóm |
| `staff:{staffId}` | 15 phút | Thông tin cán bộ |
| `provinces` | 24 giờ | Tỉnh/thành phố |
| `districts:{provinceId}` | 24 giờ | Quận/huyện |

Cache invalidation: Khi CRUD thì xóa key liên quan.

---

## 11. SO SÁNH VỚI HỆ THỐNG CŨ

| Khía cạnh | Hệ thống cũ | Hệ thống mới |
|-----------|-------------|--------------|
| Frontend | AngularJS (2013) | **Next.js 16 + Ant Design 6** |
| Backend | ASP.NET MVC 5 (.NET 4.8) | **Express 5 + TypeScript** (tách riêng) |
| Database | SQL Server + Stored Procedures | **PostgreSQL 16 + Stored Procedures** |
| Data access | ADO.NET + Reflection mapping | **node-postgres (pg) + TypeScript interfaces** |
| ORM | Không | **Không** (giữ SP) |
| Auth | Cookie + MD5 | **JWT (jose) + bcrypt + HttpOnly cookie** |
| File storage | Disk (C:\Temp) | **MinIO (S3-compatible)** |
| Logging | DB + text file | **MongoDB** (structured) |
| Cache | Không | **Redis** |
| Background jobs | 6 Windows Services | **BullMQ + Redis** (workers/) |
| Real-time | Node.js Socket.IO (app riêng) | **Socket.IO** (tích hợp trong Express) |
| Workflow designer | GoJS (commercial) | **React Flow** (free) |
| PDF processing | iText7 (.NET) | **pdf-lib** (JS) |
| Excel export | EPPlus (.NET) | **exceljs** (JS) |
| Migration | Không có (sửa tay) | **Versioned SQL files** (database/migrations/) |
| CI/CD | Không | **Docker + GitHub Actions** |
| Deploy | IIS trên Windows Server | **Docker containers** |
