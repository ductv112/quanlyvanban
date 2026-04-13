# KIẾN TRÚC HỆ THỐNG — QUẢN LÝ VĂN BẢN (MỚI)
> Phiên bản: 1.0 | Ngày: 2026-04-13

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
          │                 │                       │
┌─────────┼─────────────────┼───────────────────────┼──────────────┐
│         ▼                 ▼                       ▼              │
│  ┌─────────────────────────────────────────────────────────────┐ │
│  │                   NEXT.JS APPLICATION                       │ │
│  │  ┌─────────────┐  ┌──────────────┐  ┌────────────────────┐ │ │
│  │  │  Pages /     │  │  API Routes  │  │  Middleware         │ │ │
│  │  │  App Router  │  │  /api/*      │  │  (Auth, RBAC,      │ │ │
│  │  │  (SSR/CSR)   │  │              │  │   Rate Limit)      │ │ │
│  │  └─────────────┘  └──────┬───────┘  └────────────────────┘ │ │
│  │                          │                                  │ │
│  │  ┌───────────────────────▼──────────────────────────────┐   │ │
│  │  │              SERVICE LAYER (TypeScript)               │   │ │
│  │  │  Business logic, validation, orchestration            │   │ │
│  │  │  ┌────────────┐ ┌────────────┐ ┌──────────────────┐  │   │ │
│  │  │  │ Document   │ │ Workflow   │ │ Notification     │  │   │ │
│  │  │  │ Service    │ │ Service    │ │ Service          │  │   │ │
│  │  │  └────────────┘ └────────────┘ └──────────────────┘  │   │ │
│  │  └───────────────────────┬──────────────────────────────┘   │ │
│  │                          │                                  │ │
│  │  ┌───────────────────────▼──────────────────────────────┐   │ │
│  │  │            REPOSITORY LAYER (TypeScript)              │   │ │
│  │  │  Gọi PostgreSQL Stored Procedures qua node-postgres   │   │ │
│  │  │  Type-safe request/response interfaces                │   │ │
│  │  └───────────────────────┬──────────────────────────────┘   │ │
│  └──────────────────────────┼──────────────────────────────────┘ │
│                             │                                    │
│              APPLICATION LAYER                                   │
└─────────────────────────────┼────────────────────────────────────┘
                              │
┌─────────────────────────────┼────────────────────────────────────┐
│                             ▼                                    │
│  ┌──────────┐  ┌──────────┐  ┌───────┐  ┌───────┐  ┌────────┐  │
│  │PostgreSQL│  │ MongoDB  │  │ Redis │  │ MinIO │  │Socket  │  │
│  │  (Main)  │  │  (Log)   │  │(Cache)│  │(Files)│  │  .IO   │  │
│  │  + SPs   │  │          │  │+Queue │  │  S3   │  │(RT)    │  │
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

## 2. TECH STACK CHI TIẾT

### 2.1 Frontend

| Thành phần | Công nghệ | Phiên bản | Ghi chú |
|-----------|-----------|-----------|---------|
| Framework | **Next.js** (App Router) | 15.x | SSR + CSR, API Routes |
| UI Library | **Ant Design 5** | 5.x | Custom theme, KHÔNG dùng default |
| State management | **Zustand** | 5.x | Nhẹ, đơn giản hơn Redux |
| HTTP Client | **axios** | 1.x | Gọi API, interceptors cho JWT |
| Workflow Designer | **React Flow** | 12.x | Thay GoJS, miễn phí, React-native |
| Dashboard Layout | **react-grid-layout** | 1.x | Drag & drop widget |
| Calendar | **FullCalendar** (@fullcalendar/react) | 6.x | Lịch cá nhân/cơ quan |
| Rich Text Editor | **TipTap** | 2.x | Soạn thảo VB, bút phê |
| Charts | **Ant Design Charts** (@ant-design/charts) | 2.x | Biểu đồ báo cáo |
| Tree View | **Ant Design Tree** | — | Cây tổ chức, cây chức năng |
| PDF Viewer | **react-pdf** | 9.x | Xem VB trực tuyến |
| Date | **dayjs** | 1.x | Xử lý ngày tháng |
| Number format | **numeral** | 2.x | Định dạng số |
| Icons | **@ant-design/icons** | 5.x | |
| QR/Barcode | **qrcode.react** + **jsbarcode** | — | Mã QR + mã vạch |

### 2.2 Backend (Next.js API Routes)

| Thành phần | Công nghệ | Phiên bản | Ghi chú |
|-----------|-----------|-----------|---------|
| Runtime | **Node.js** | 20 LTS | |
| Language | **TypeScript** | 5.x | Strict mode |
| PostgreSQL Driver | **node-postgres (pg)** | 8.x | Gọi SP trực tiếp, pool connection |
| Type Generator | **pgtyped** hoặc **kanel** | — | Sinh TS types từ PG schema |
| MongoDB Driver | **mongoose** | 8.x | Chỉ cho log/audit |
| Redis Client | **ioredis** | 5.x | Cache + Bull queue |
| Job Queue | **BullMQ** | 5.x | Background jobs (LGSP, FCM, Zalo, SMS, Email) |
| Real-time | **Socket.IO** | 4.x | Thông báo, biểu quyết |
| Auth | **jose** (JWT) | 5.x | JWT sign/verify, KHÔNG dùng next-auth |
| Password Hash | **bcrypt** | 5.x | Thay MD5 |
| File Upload | **MinIO SDK** (@minio/minio-js) | 8.x | S3-compatible |
| PDF Processing | **pdf-lib** | 1.x | Ký số, chèn ảnh chữ ký |
| Excel Export | **exceljs** | 4.x | Xuất báo cáo Excel |
| DOCX → PDF | **LibreOffice** (headless CLI) | — | Convert qua child_process |
| Email | **nodemailer** | 6.x | SMTP sender |
| Validation | **zod** | 3.x | Request validation |
| Logging | **pino** | 9.x | Structured JSON log → MongoDB |
| Migration | **dbmate** | 2.x | SQL migration files, không phụ thuộc ORM |

### 2.3 Database

| Database | Vai trò | Chi tiết |
|----------|---------|----------|
| **PostgreSQL 16** | Database chính | Stored Procedures cho toàn bộ data access. Functions trả về TABLE/SETOF. Full-text search (tsvector). |
| **MongoDB 7** | Log & Audit | Access log, action log, error log. Lưu trữ không giới hạn, query linh hoạt. |
| **Redis 7** | Cache + Queue | Cache danh mục (departments, positions, doc_types). Session store. BullMQ job queue. |

### 2.4 Infrastructure

| Thành phần | Công nghệ | Ghi chú |
|-----------|-----------|---------|
| File Storage | **MinIO** | S3-compatible, self-hosted |
| Reverse Proxy | **Nginx** | SSL, load balance |
| Containerization | **Docker** + **Docker Compose** | Dev + Production |
| CI/CD | Tùy chọn (GitLab CI / GitHub Actions) | |

---

## 3. DATA ACCESS PATTERN — STORED PROCEDURES

### 3.1 Nguyên tắc thiết kế

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  API Route       │────▶│  Service Layer   │────▶│  Repository     │
│  (Controller)    │     │  (Business Logic)│     │  (SP Caller)    │
│                  │     │                  │     │                 │
│  - Parse request │     │  - Validation    │     │  - pool.query() │
│  - Auth check    │     │  - Orchestration │     │  - Map result   │
│  - Return JSON   │     │  - Error handle  │     │  - Type-safe    │
└─────────────────┘     └──────────────────┘     └────────┬────────┘
                                                          │
                                                          ▼
                                                 ┌─────────────────┐
                                                 │  PostgreSQL     │
                                                 │  Stored Procs   │
                                                 │                 │
                                                 │  fn_xxx_get     │
                                                 │  fn_xxx_save    │
                                                 │  fn_xxx_delete  │
                                                 │  fn_xxx_list    │
                                                 └─────────────────┘
```

### 3.2 Quy ước đặt tên Stored Procedures

```sql
-- Schema: theo module
-- edoc.fn_incoming_doc_get_by_id(p_id BIGINT, p_unit_id INT)
-- edoc.fn_incoming_doc_get_by_page(p_unit_id INT, p_page INT, p_size INT, ...)
-- edoc.fn_incoming_doc_save(p_data JSON)
-- edoc.fn_incoming_doc_delete(p_id BIGINT, p_user_id INT)
-- edoc.fn_incoming_doc_search(p_keyword TEXT, p_filters JSON)

-- Schema mapping:
--   edoc.*    → Văn bản, HSCV, Workflow, Lịch, Họp, Tin nhắn
--   dbo.*     → Users, Departments, Roles, Rights, SMS, Email
--   esto.*    → Kho lưu trữ
--   cont.*    → Hợp đồng
--   iso.*     → Tài liệu ISO
```

### 3.3 Connection Pool & Repository Pattern

```typescript
// lib/db/pool.ts
import { Pool } from 'pg';

export const pool = new Pool({
  host: process.env.PG_HOST,
  port: Number(process.env.PG_PORT),
  database: process.env.PG_DATABASE,
  user: process.env.PG_USER,
  password: process.env.PG_PASSWORD,
  max: 20,                    // max connections
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
});

// lib/db/query.ts — type-safe SP caller
export async function callFunction<T>(
  functionName: string,
  params: unknown[] = []
): Promise<T[]> {
  const placeholders = params.map((_, i) => `$${i + 1}`).join(', ');
  const sql = `SELECT * FROM ${functionName}(${placeholders})`;
  const result = await pool.query(sql, params);
  return result.rows as T[];
}

export async function callProcedure(
  procedureName: string,
  params: unknown[] = []
): Promise<void> {
  const placeholders = params.map((_, i) => `$${i + 1}`).join(', ');
  await pool.query(`CALL ${procedureName}(${placeholders})`, params);
}
```

```typescript
// repositories/incoming-doc.repository.ts
import { callFunction } from '@/lib/db/query';
import type { IncomingDoc, IncomingDocDetail } from '@/types/edoc';

export const incomingDocRepo = {
  async getByPage(unitId: number, page: number, size: number, filters?: object) {
    return callFunction<IncomingDoc>(
      'edoc.fn_incoming_doc_get_by_page',
      [unitId, page, size, JSON.stringify(filters ?? {})]
    );
  },

  async getById(id: number, unitId: number) {
    const rows = await callFunction<IncomingDocDetail>(
      'edoc.fn_incoming_doc_get_by_id',
      [id, unitId]
    );
    return rows[0] ?? null;
  },

  async save(data: Partial<IncomingDoc>, userId: number) {
    const rows = await callFunction<{ id: number }>(
      'edoc.fn_incoming_doc_save',
      [JSON.stringify(data), userId]
    );
    return rows[0].id;
  },

  async delete(id: number, userId: number) {
    await callFunction('edoc.fn_incoming_doc_delete', [id, userId]);
  },
};
```

```typescript
// services/incoming-doc.service.ts
import { incomingDocRepo } from '@/repositories/incoming-doc.repository';
import { minioClient } from '@/lib/minio';
import { notificationService } from './notification.service';

export const incomingDocService = {
  async create(data: CreateIncomingDocInput, userId: number) {
    // 1. Validate business rules (TypeScript)
    if (data.urgentId && !VALID_URGENT_IDS.includes(data.urgentId)) {
      throw new AppError('Invalid urgentId', 400);
    }

    // 2. Save to DB (SP)
    const id = await incomingDocRepo.save(data, userId);

    // 3. Upload attachments (MinIO)
    if (data.attachments?.length) {
      await Promise.all(
        data.attachments.map(file =>
          minioClient.putObject('documents', `incoming/${id}/${file.name}`, file.buffer)
        )
      );
    }

    // 4. Notify (Business logic in TypeScript)
    await notificationService.notifyNewIncomingDoc(id, data.recipients);

    return id;
  },
};
```

### 3.4 Multi-result-set (khi cần)

```typescript
// Với pg, dùng multiple queries trong 1 transaction
export async function getIncomingDocDetail(id: number, unitId: number) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const docResult = await client.query(
      'SELECT * FROM edoc.fn_incoming_doc_get_by_id($1, $2)', [id, unitId]
    );
    const attachments = await client.query(
      'SELECT * FROM edoc.fn_attachment_incoming_doc_get($1)', [id]
    );
    const leaderNotes = await client.query(
      'SELECT * FROM edoc.fn_leader_note_get_by_doc($1)', [id]
    );
    const userDocs = await client.query(
      'SELECT * FROM edoc.fn_user_incoming_doc_get($1)', [id]
    );

    await client.query('COMMIT');

    return {
      doc: docResult.rows[0],
      attachments: attachments.rows,
      leaderNotes: leaderNotes.rows,
      recipients: userDocs.rows,
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

## 4. CẤU TRÚC THƯ MỤC DỰ ÁN

```
quanlyvanban/
├── docs/                           # Tài liệu dự án
│   ├── function_list.md
│   ├── architecture.md
│   └── database/                   # SQL schema + SP files
│       ├── migrations/             # dbmate migration files
│       │   ├── 001_init_schema.sql
│       │   ├── 002_create_edoc_tables.sql
│       │   └── ...
│       └── stored_procedures/
│           ├── edoc/
│           ├── dbo/
│           ├── esto/
│           ├── cont/
│           └── iso/
│
├── src/
│   ├── app/                        # Next.js App Router
│   │   ├── (auth)/                 # Auth pages (login, forgot-password)
│   │   │   └── login/page.tsx
│   │   ├── (main)/                 # Main layout (sidebar + header)
│   │   │   ├── dashboard/page.tsx
│   │   │   ├── van-ban/
│   │   │   │   ├── den/page.tsx
│   │   │   │   ├── di/page.tsx
│   │   │   │   ├── du-thao/page.tsx
│   │   │   │   └── lien-thong/page.tsx
│   │   │   ├── ho-so-cong-viec/
│   │   │   ├── hop-khong-giay/
│   │   │   ├── hop-dong/
│   │   │   ├── kho-luu-tru/
│   │   │   ├── tai-lieu/
│   │   │   ├── tin-nhan/
│   │   │   ├── tien-ich/
│   │   │   └── quan-tri/
│   │   │       ├── nguoi-dung/
│   │   │       ├── nhom-quyen/
│   │   │       ├── chuc-nang/
│   │   │       ├── don-vi/
│   │   │       ├── danh-muc-vb/
│   │   │       └── cau-hinh/
│   │   ├── api/                    # API Routes
│   │   │   ├── auth/
│   │   │   ├── van-ban/
│   │   │   │   ├── den/route.ts
│   │   │   │   ├── di/route.ts
│   │   │   │   └── du-thao/route.ts
│   │   │   ├── ho-so-cong-viec/
│   │   │   ├── workflow/
│   │   │   ├── hop/
│   │   │   ├── thong-bao/
│   │   │   ├── quan-tri/
│   │   │   └── upload/route.ts
│   │   └── layout.tsx
│   │
│   ├── components/                 # React Components
│   │   ├── ui/                     # Base UI (Button, Modal, Form wrappers)
│   │   ├── layout/                 # MainLayout, Sidebar, Header
│   │   ├── dashboard/              # Widget components
│   │   ├── van-ban/                # Document-specific components
│   │   ├── workflow/               # React Flow components
│   │   └── shared/                 # OrgTree, FileUpload, RichEditor...
│   │
│   ├── services/                   # Business Logic (TypeScript)
│   │   ├── incoming-doc.service.ts
│   │   ├── outgoing-doc.service.ts
│   │   ├── handling-doc.service.ts
│   │   ├── workflow.service.ts
│   │   ├── notification.service.ts
│   │   ├── digital-sign.service.ts
│   │   ├── lgsp.service.ts
│   │   └── ...
│   │
│   ├── repositories/              # Data Access (gọi SP)
│   │   ├── incoming-doc.repository.ts
│   │   ├── outgoing-doc.repository.ts
│   │   ├── handling-doc.repository.ts
│   │   ├── staff.repository.ts
│   │   ├── department.repository.ts
│   │   └── ...
│   │
│   ├── lib/                       # Shared utilities
│   │   ├── db/
│   │   │   ├── pool.ts            # PostgreSQL connection pool
│   │   │   ├── query.ts           # Type-safe SP caller
│   │   │   └── transaction.ts     # Transaction helper
│   │   ├── redis/
│   │   │   ├── client.ts          # Redis connection
│   │   │   └── cache.ts           # Cache helpers
│   │   ├── mongodb/
│   │   │   └── client.ts          # MongoDB connection (logging only)
│   │   ├── minio/
│   │   │   └── client.ts          # MinIO S3 client
│   │   ├── auth/
│   │   │   ├── jwt.ts             # JWT sign/verify (jose)
│   │   │   ├── password.ts        # bcrypt hash/compare
│   │   │   └── middleware.ts      # Auth + RBAC middleware
│   │   ├── socket/
│   │   │   └── server.ts          # Socket.IO server setup
│   │   └── logger.ts              # Pino → MongoDB
│   │
│   ├── types/                     # TypeScript Interfaces
│   │   ├── edoc.ts                # IncomingDoc, OutgoingDoc, HandlingDoc...
│   │   ├── dbo.ts                 # Staff, Department, Role, Right...
│   │   ├── esto.ts                # Storage entities
│   │   ├── cont.ts                # Contract entities
│   │   ├── api.ts                 # Request/Response DTOs
│   │   └── auth.ts                # JWT payload, session types
│   │
│   ├── hooks/                     # React Hooks
│   │   ├── use-auth.ts
│   │   ├── use-incoming-docs.ts
│   │   └── ...
│   │
│   ├── stores/                    # Zustand stores
│   │   ├── auth.store.ts
│   │   ├── notification.store.ts
│   │   └── sidebar.store.ts
│   │
│   ├── workers/                   # BullMQ Workers (Background Jobs)
│   │   ├── lgsp-receive.worker.ts   # Tự động nhận VB liên thông
│   │   ├── lgsp-send.worker.ts      # Gửi VB liên thông
│   │   ├── fcm.worker.ts            # Push notification
│   │   ├── zalo.worker.ts           # Zalo OA notification
│   │   ├── email.worker.ts          # Email sender
│   │   ├── sms.worker.ts            # SMS sender
│   │   └── pdf-convert.worker.ts    # DOCX → PDF conversion
│   │
│   └── config/                    # App configuration
│       ├── constants.ts
│       ├── menu.ts                # Menu tree definition
│       └── theme.ts               # Ant Design theme customization
│
├── public/                        # Static assets
├── docker-compose.yml             # PostgreSQL + MongoDB + Redis + MinIO
├── Dockerfile
├── .env.example
├── next.config.ts
├── tsconfig.json
├── package.json
└── dbmate.toml                    # Migration config
```

---

## 5. AUTHENTICATION & AUTHORIZATION

### 5.1 JWT Flow

```
Login:  POST /api/auth/login
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
        │   roles: ["LEADER", "ADMIN"] }       │
        ├──────────────────────────────────────┤
        │ Refresh Token (7 ngày)               │
        │ Lưu trong HttpOnly cookie            │
        └──────────────────────────────────────┘
            │
            ▼
        Response: { accessToken, user }
        Set-Cookie: refreshToken=xxx; HttpOnly; Secure; SameSite=Strict
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

Middleware kiểm tra:
1. JWT valid? → 401 Unauthorized
2. User có role cần thiết? → 403 Forbidden
3. Role có quyền truy cập action này? → 403 Forbidden

---

## 6. BACKGROUND JOBS (BullMQ)

| Queue | Chức năng | Schedule |
|-------|-----------|----------|
| `lgsp-receive` | Nhận VB liên thông từ trục LGSP | Mỗi 1 phút |
| `lgsp-send` | Gửi VB liên thông đi | Khi có VB mới (event-driven) |
| `fcm-push` | Push notification mobile | Khi có event (real-time) |
| `zalo-message` | Gửi tin Zalo OA | Khi có event |
| `email-send` | Gửi email thông báo | Khi có event |
| `sms-send` | Gửi SMS | Khi có event |
| `pdf-convert` | DOCX → PDF | Khi upload file |
| `report-export` | Xuất báo cáo Excel lớn | Khi user request |

---

## 7. REAL-TIME (Socket.IO)

```typescript
// Events
socket.emit('notification:new', { type, message, data });
socket.emit('document:updated', { docId, action });
socket.emit('vote:start', { roomId, voteId, options, countdown });
socket.emit('vote:cast', { roomId, voteId, optionId });
socket.emit('vote:result', { roomId, voteId, results });
socket.emit('meeting:reload', { roomId });
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
  table: "edoc.incoming_doc",
  recordId: 123,
  oldValues: { abstract: "...", urgentId: 1 },
  newValues: { abstract: "...", urgentId: 2 },
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
| `session:{token}` | 7 ngày | Refresh token → staffId |

Cache invalidation: Khi CRUD thì xóa key liên quan.

---

## 11. SO SÁNH VỚI HỆ THỐNG CŨ

| Khía cạnh | Hệ thống cũ | Hệ thống mới |
|-----------|-------------|--------------|
| Frontend | AngularJS (2013) | **Next.js 15 + Ant Design 5** |
| Backend | ASP.NET MVC 5 (.NET 4.8) | **Next.js API Routes (Node.js 20)** |
| Database | SQL Server + Stored Procedures | **PostgreSQL 16 + Stored Procedures** |
| Data access | ADO.NET + Reflection mapping | **node-postgres (pg) + TypeScript interfaces** |
| ORM | Không | **Không** (giữ SP) |
| Auth | Cookie + MD5 | **JWT + bcrypt** |
| File storage | Disk (C:\Temp) | **MinIO (S3)** |
| Logging | DB + text file | **MongoDB** (structured) |
| Cache | Không | **Redis** |
| Background jobs | 6 Windows Services | **BullMQ + Redis** (in-process) |
| Real-time | Node.js Socket.IO (app riêng) | **Socket.IO** (tích hợp trong Next.js) |
| Workflow designer | GoJS (commercial) | **React Flow** (free, React-native) |
| PDF processing | iText7 (.NET) | **pdf-lib** (JS) |
| Excel export | EPPlus (.NET) | **exceljs** (JS) |
| Migration | Không có (sửa tay) | **dbmate** (versioned SQL files) |
| CI/CD | Không | **Docker + CI/CD pipeline** |
