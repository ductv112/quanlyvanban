# Coding Conventions

**Analysis Date:** 2026-04-14 (refreshed after Phase 4 completion)

## Naming Patterns

**Files (Backend):**
- Repositories: `kebab-case.repository.ts` — e.g., `incoming-doc.repository.ts`, `handling-doc.repository.ts`
- Routes: `kebab-case.ts` — e.g., `admin-catalog.ts`, `handling-doc-report.ts`
- Services: `kebab-case.service.ts` — e.g., `auth.service.ts`
- Shared libs: `kebab-case.ts` in `lib/` — e.g., `error-handler.ts`, `socket.ts`
- Lib subdirectories: grouped by domain — `lib/auth/`, `lib/db/`, `lib/minio/`, `lib/redis/`, `lib/mongodb/`

**Files (Frontend):**
- Pages: `page.tsx` (Next.js App Router convention)
- Layout/Provider components: **PascalCase** — `MainLayout.tsx`, `AntdProvider.tsx`
- Stores: `{name}.store.ts` — `auth.store.ts`
- Libs: `kebab-case.ts` — `api.ts`, `socket.ts`, `tree-utils.ts`
- Types: `kebab-case.ts` — `tree.ts`
- Config: `theme.ts`, `constants.ts`

**Functions/Variables:**
- **camelCase** for all: `handleDbError`, `fetchData`, `staffId`, `drawerOpen`
- Repository methods: `getTree`, `getById`, `create`, `update`, `delete`, `toggleLock`, `getList`
- Frontend handlers: `handleSave`, `handleDelete`, `handleEdit`, `handleCancel`

**Interfaces/Types:**
- **PascalCase** with descriptive suffixes
- DB result types: `*Row` — `DepartmentTreeRow`, `IncomingDocListRow`, `HandlingDocDetailRow`
- Frontend state: `AuthState`, `UserInfo`
- Request extension: `AuthRequest extends Request`

**Database:**
- Tables: **snake_case**, plural — `departments`, `incoming_docs`, `handling_doc_links`
- Columns: **snake_case** — `first_name`, `created_at`, `is_locked`
- Schemas: `public` (system tables), `edoc` (document tables)
- Stored procedures: `{schema}.fn_{module}_{action}` — `public.fn_department_get_tree`, `edoc.fn_incoming_doc_create`
- Constraints: `uq_{table}_{column}`, `fk_{table}_{ref}`, `idx_{table}_{column}`

**API URLs:**
- Prefix: `/api/`
- Resource paths: **kebab-case Vietnamese** — `/quan-tri/don-vi`, `/van-ban-den`, `/ho-so-cong-viec`
- CRUD: `GET /resource`, `POST /resource`, `PUT /resource/:id`, `DELETE /resource/:id`
- Actions: `PATCH /resource/:id/lock`, `PATCH /resource/:id/reset-password`
- Sub-resources: `/api/ho-so-cong-viec/thong-ke` (reports mounted before `/:id`)

**Form field names:**
- **snake_case** matching DB column names: `parent_id`, `is_unit`, `doc_book_id`

## Code Style

**Formatting:**
- Indentation: 2 spaces
- Semicolons: required
- Quotes: single quotes for strings
- No Prettier config — editor defaults + ESLint

**Linting:**
- Frontend: ESLint with `eslint-config-next/core-web-vitals` + `eslint-config-next/typescript`
- Backend: No ESLint. TypeScript strict mode is the primary check.

**TypeScript:**
- Both backend and frontend use `"strict": true`
- Backend: target ES2022, ESM modules
- Frontend: target ES2017, Next.js plugin

## Import Organization

**Order:**
1. Node built-ins — `import { createHash } from 'node:crypto'`
2. External packages — `import express from 'express'`
3. Type imports — `import type { Request, Response } from 'express'`
4. Internal modules — `import { departmentRepository } from '../repositories/department.repository.js'`

**Path Aliases:**
- Frontend: `@/*` → `./src/*` — `import { api } from '@/lib/api'`
- Backend: `@/*` → `./src/*` and `@shared/*` → `../../shared/src/*`

**Backend import extension:**
- ALWAYS use `.js` extension (ESM requirement): `import { pool } from './pool.js'`

## Error Handling

### Backend: Centralized handleDbError (Phase 1 extraction)

Shared `handleDbError` in `e_office_app_new/backend/src/lib/error-handler.ts` maps PostgreSQL error codes to Vietnamese messages. All route files import from this shared module.

```typescript
import { handleDbError } from '../lib/error-handler.js';

// In route handler:
catch (error) {
  handleDbError(error, res);
}
```

The shared handler covers constraint names from all modules (admin, catalog, handling docs). New constraint names should be added to the shared `messageMap` in `error-handler.ts`.

### Backend: Auth Error Pattern

Auth routes use `AuthError` class from `auth.service.ts`:
```typescript
if (error instanceof AuthError) {
  res.status(error.statusCode).json({ success: false, message: error.message });
  return;
}
```

### Backend: Route Handler Pattern

Every handler follows try/catch with handleDbError:
```typescript
router.get('/resource', async (req: Request, res: Response) => {
  try {
    const { staffId, unitId } = (req as AuthRequest).user;
    const data = await someRepository.getList(/* params */);
    res.json({ success: true, data });
  } catch (error) {
    handleDbError(error, res);
  }
});
```

### Frontend: Error Display

```typescript
// Map backend error messages to form field names
const setBackendFieldError = (errorMessage: string): boolean => {
  const fieldErrorMap: Record<string, string> = {
    'Mã đơn vị đã tồn tại': 'code',
  };
  const fieldName = fieldErrorMap[errorMessage];
  if (fieldName) {
    form.setFields([{ name: fieldName, errors: [errorMessage] }]);
    return true;
  }
  return false;
};
```

**Rule:** Field-specific errors display under the field. System errors use `message.error()` toast.

### Global Error Handler

Express global error handler in `server.ts` catches unhandled errors:
```typescript
app.use((err: Error, _req, res, _next) => {
  logger.error(err);
  const isDev = process.env.NODE_ENV !== 'production';
  res.status(500).json({
    success: false,
    message: isDev ? err.message : 'Có lỗi xảy ra, vui lòng thử lại sau'
  });
});
```

## API Response Format

**All responses use `{ success: boolean }` envelope.**

Success (no pagination):
```json
{ "success": true, "data": { ... }, "message": "Thêm thành công" }
```

Success (with pagination):
```json
{
  "success": true,
  "data": [...],
  "pagination": { "total": 150, "page": 1, "pageSize": 20, "totalPages": 8 }
}
```

Error:
```json
{ "success": false, "message": "Mã đơn vị đã tồn tại" }
```

**HTTP Status Codes:**
- `200` — GET, PUT, PATCH, DELETE success
- `201` — POST create success
- `400` — Validation failure
- `401` — Unauthorized
- `403` — Forbidden
- `404` — Not found
- `409` — Conflict (unique violation)
- `500` — Server error

## Database Access Pattern

**No ORM.** All database access uses PostgreSQL stored procedures via the query helper:

```typescript
// e_office_app_new/backend/src/lib/db/query.ts
callFunction<T>(functionName, params)      // Returns T[] (multiple rows)
callFunctionOne<T>(functionName, params)   // Returns T | null (single row)
callProcedure(procedureName, params)       // Void (side-effect only)
rawQuery<T>(sql, params)                   // Direct SQL (rare)
withTransaction<T>(callback)               // Transaction wrapper
```

**Rules:**
- ALWAYS use parameterized queries — never string concatenation
- Repository exports a plain object (not a class)
- Each repository defines its own row interfaces
- SP naming: `{schema}.fn_{module}_{action}`

## Frontend Component Patterns

### Page Structure

Every page is `'use client'` with local state management:

```typescript
'use client';
import React, { useState, useEffect, useCallback } from 'react';
import { Card, Table, Button, Drawer, Form, App } from 'antd';
import { api } from '@/lib/api';

export default function EntityPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<EntityType[]>([]);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<EntityType | null>(null);
  const [form] = Form.useForm();

  const fetchData = useCallback(async () => { ... }, []);
  useEffect(() => { fetchData(); }, [fetchData]);
  // CRUD handlers, table columns, JSX...
}
```

### Detail Page Pattern (`[id]/page.tsx`)

Used for van-ban-den, van-ban-du-thao, van-ban-di, van-ban-lien-thong, ho-so-cong-viec:
- `useParams()` to get `id`
- Tabs for different sections (info, attachments, history, workflow)
- Helper functions for rendering status tags, formatting dates
- Often duplicated `Attachment`, `HistoryEvent` interfaces across detail pages

### Drawer (Add/Edit)

- Width: `720`
- `rootClassName="drawer-gradient"` for gradient header
- Title: dynamic — "Thêm mới" vs "Chỉnh sửa"
- Footer: Save + Cancel buttons in drawer `extra`
- Form: `validateTrigger="onSubmit"`

### Table Actions

- `Dropdown` with `MoreOutlined` icon button
- Divider before dangerous actions
- Delete: `Modal.confirm` with `danger: true`
- Lock/Unlock: toggle via PATCH

### Notifications

- Success: `message.success('Thêm thành công')` via `App.useApp()`
- Error: `message.error(...)` for unmappable errors
- Never `alert()` or `notification` popup

### State Management

- **Zustand** for global state (auth only): `auth.store.ts`
- **Local `useState`** for all page-level data
- **Axios** via shared instance with auto token refresh
- Token stored in `localStorage`, attached via interceptor

## Route Registration Pattern (server.ts)

```typescript
// Public routes
app.use('/api/health', healthRoutes);
app.use('/api/auth', authRoutes);

// Authenticated routes
app.use('/api/quan-tri', authenticate, adminRoutes);
app.use('/api/van-ban-den', authenticate, incomingDocRoutes);
// NOTE: sub-routes must be mounted BEFORE parametric parent routes
app.use('/api/ho-so-cong-viec/thong-ke', authenticate, reportRoutes);
app.use('/api/ho-so-cong-viec', authenticate, handlingDocRoutes);
```

## Socket.IO Pattern

**Backend** (`lib/socket.ts`): Server init with auth middleware, room-based messaging:
```typescript
export function initSocket(httpServer: HttpServer) {
  const io = new Server(httpServer, { cors: { ... } });
  io.use(socketAuthMiddleware);
  io.on('connection', (socket) => {
    socket.join(`user:${socket.data.staffId}`);
    // handle events...
  });
  (globalThis as any).__io = io;
}
```

**Frontend** (`lib/socket.ts`): Client singleton connected on import.

## CSS Approach

**CSS-first layout to prevent FOUC.**

- Layout styles: CSS classes in `globals.css` (620+ lines)
- Dynamic styles: inline `style={{}}`
- Key classes: `.main-layout`, `.main-sider`, `.main-header`, `.main-content`, `.page-header`, `.page-card`, `.drawer-gradient`, `.stat-card`, `.info-grid`, `.detail-header`, `.filter-row`
- Ant Design theme in `theme.ts` (Inter font, navy palette)
- TailwindCSS v4 installed but primarily used for base — most styling via Ant Design + custom CSS

**Color Palette:**
- Primary: `#1B3A5C` (deep navy)
- Accent: `#0891B2` (teal)
- Background: `#F0F2F5`
- Sidebar: `#0F1A2E`

## Language

- **ALL UI text MUST be in Vietnamese with diacritics** (có dấu)
- Labels, messages, placeholders, tooltips, tags — everything in Vietnamese
- API error messages also in Vietnamese
- Constants file uses Vietnamese labels

## Migration File Pattern

```sql
-- File: NNN_sprint{N}_{description}.sql
-- Naming: sequential number, sprint reference, descriptive name
-- Structure: tables first, then stored functions
-- SP params: use _prefix for parameters (_staff_id, _unit_id, _page, _page_size)
-- SP returns: RETURNS TABLE(...) or RETURNS void
```

## Git Conventions

**Commit format:**
```
{type}({scope}): {description}

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
```

**Types:** `feat:`, `fix:`, `refactor:`, `docs:`, `style:`, `chore:`
**Scopes:** sprint number, module name, or phase reference

---

*Convention analysis: 2026-04-14 (refreshed)*
