# Coding Conventions

**Analysis Date:** 2026-04-14

## Naming Patterns

**Files (Backend):**
- Use **kebab-case** with suffix: `{module}.repository.ts`, `{module}.service.ts`, `{module}.ts` (routes)
- Examples: `department.repository.ts`, `auth.service.ts`, `admin-catalog.ts`, `incoming-doc.ts`
- Location pattern: `backend/src/routes/`, `backend/src/repositories/`, `backend/src/services/`

**Files (Frontend):**
- Page files: `page.tsx` (Next.js App Router convention)
- Layout/Provider components: **PascalCase** — `MainLayout.tsx`, `AntdProvider.tsx`
- Stores: `{name}.store.ts` — e.g., `auth.store.ts`
- Hooks: `use-{name}.ts` (not yet created, but convention documented)
- Config: `theme.ts`, `constants.ts`

**Functions/Variables:**
- Use **camelCase** for all functions and variables: `handleDbError`, `fetchTree`, `staffId`
- Repository methods: `getTree`, `getById`, `create`, `update`, `delete`, `toggleLock`, `getList`

**Interfaces/Types:**
- Use **PascalCase** with descriptive suffixes: `DepartmentTreeRow`, `DepartmentDetailRow`, `IncomingDocListRow`
- Row suffix for DB result types: `*Row`
- Frontend state interfaces: `AuthState`, `UserInfo`
- Request extension: `AuthRequest extends Request`

**Database:**
- Tables: **snake_case**, plural — `departments`, `incoming_docs`
- Columns: **snake_case** — `first_name`, `created_at`, `is_locked`
- Stored procedures: `{schema}.fn_{module}_{action}` — `public.fn_department_get_tree`, `edoc.fn_incoming_doc_create`
- Constraints: `uq_{table}_{column}` (unique), `fk_{table}_{ref}` (foreign key), `idx_{table}_{column}` (index)

**API URLs:**
- Prefix: `/api/`
- Resource paths: **kebab-case Vietnamese** — `/quan-tri/don-vi`, `/van-ban-den`, `/so-van-ban`
- CRUD: `GET /resource`, `POST /resource`, `PUT /resource/:id`, `DELETE /resource/:id`
- Actions: `PATCH /resource/:id/lock`, `PATCH /resource/:id/reset-password`

**Form field names:**
- Use **snake_case** matching DB column names: `parent_id`, `is_unit`, `doc_book_id`

## Code Style

**Formatting:**
- No Prettier config detected. Rely on editor defaults and ESLint.
- Indentation: 2 spaces (observed throughout)
- Semicolons: required (TypeScript strict)
- Quotes: single quotes for strings

**Linting:**
- Frontend: ESLint with `eslint-config-next/core-web-vitals` and `eslint-config-next/typescript`
  - Config: `e_office_app_new/frontend/eslint.config.mjs`
  - Run: `npm run lint`
- Backend: No ESLint configured. TypeScript strict mode serves as the primary check.

**TypeScript Strictness:**
- Both backend and frontend use `"strict": true` in `tsconfig.json`
- Backend: `e_office_app_new/backend/tsconfig.json` — target ES2022, ESM modules
- Frontend: `e_office_app_new/frontend/tsconfig.json` — target ES2017, Next.js plugin

## Import Organization

**Order (observed pattern):**
1. Node built-ins — `import { createHash } from 'node:crypto'`
2. External packages — `import express from 'express'`, `import { Router } from 'express'`
3. Type imports — `import type { Request, Response } from 'express'`
4. Internal modules — `import { departmentRepository } from '../repositories/department.repository.js'`

**Path Aliases:**
- Frontend: `@/*` maps to `./src/*` — use as `import { api } from '@/lib/api'`
- Backend: `@/*` maps to `./src/*` and `@shared/*` maps to `../../shared/src/*`

**Backend import extension:**
- ALWAYS use `.js` extension in imports (ESM requirement): `import { pool } from './pool.js'`

## Error Handling

### Backend: `handleDbError` Pattern

Every route file defines a local `handleDbError(error, res)` function that maps PostgreSQL error codes to Vietnamese user messages. This is the **primary error handling pattern**.

```typescript
// Pattern from `e_office_app_new/backend/src/routes/admin.ts` and `admin-catalog.ts`
function handleDbError(error: unknown, res: Response): void {
  const err = error as any;

  // PostgreSQL unique violation (error code 23505)
  if (err?.code === '23505') {
    const constraint = err?.constraint || '';
    const messageMap: Record<string, string> = {
      'uq_departments_code': 'Ma don vi da ton tai',
      // ... constraint-to-message mapping
    };
    const msg = messageMap[constraint] || 'Du lieu da ton tai, vui long kiem tra lai';
    res.status(409).json({ success: false, message: msg });
    return;
  }

  // PostgreSQL foreign key violation (error code 23503)
  if (err?.code === '23503') {
    res.status(400).json({ success: false, message: 'Khong the thuc hien: du lieu dang duoc tham chieu' });
    return;
  }

  // PostgreSQL not null violation (error code 23502)
  if (err?.code === '23502') {
    const column = err?.column || '';
    res.status(400).json({ success: false, message: `Truong "${column}" la bat buoc` });
    return;
  }

  // Default
  const isDev = process.env.NODE_ENV !== 'production';
  res.status(500).json({
    success: false,
    message: isDev ? (err as Error).message : 'Co loi xay ra, vui long thu lai sau',
  });
}
```

**Each route file has its own `handleDbError` with module-specific constraint mappings.** When adding a new route file, copy the pattern and add relevant constraint names.

### Backend: Auth Error Pattern

Auth routes use a custom `AuthError` class instead of `handleDbError`:

```typescript
// From `e_office_app_new/backend/src/services/auth.service.ts`
export class AuthError extends Error {
  constructor(message: string, public statusCode: number) {
    super(message);
    this.name = 'AuthError';
  }
}

// In route handler:
if (error instanceof AuthError) {
  res.status(error.statusCode).json({ success: false, message: error.message });
  return;
}
```

### Backend: Route Handler Pattern

Every route handler follows try/catch with `handleDbError`:

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
// Pattern from `e_office_app_new/frontend/src/app/(main)/quan-tri/don-vi/page.tsx`

// 1. Map backend error messages to form field names
const setBackendFieldError = (errorMessage: string): boolean => {
  const fieldErrorMap: Record<string, string> = {
    'Ma don vi da ton tai': 'code',
    'Ten don vi la bat buoc': 'name',
  };
  const fieldName = fieldErrorMap[errorMessage];
  if (fieldName) {
    form.setFields([{ name: fieldName, errors: [errorMessage] }]);
    return true;
  }
  return false;
};

// 2. In save handler:
catch (err: any) {
  if (err?.response?.data?.message) {
    const mapped = setBackendFieldError(err.response.data.message);
    if (!mapped) {
      message.error(err.response.data.message);  // fallback toast
    }
  }
}
```

**Rule:** Field-specific errors display under the field. System errors use `message.error()` toast.

### Global Error Handler

Express global error handler in `e_office_app_new/backend/src/server.ts`:
```typescript
app.use((err: Error, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error(err);
  const isDev = process.env.NODE_ENV !== 'production';
  res.status(500).json({
    success: false,
    message: isDev ? err.message : 'Co loi xay ra, vui long thu lai sau'
  });
});
```

## API Response Format

**All responses use `{ success: boolean }` envelope.**

Success (no pagination):
```json
{ "success": true, "data": { ... }, "message": "Them thanh cong" }
```

Success (with pagination):
```json
{ "success": true, "data": [...], "total": 150, "page": 1, "pageSize": 20, "totalPages": 8 }
```

Error:
```json
{ "success": false, "message": "Ma don vi da ton tai" }
```

**HTTP Status Codes:**
- `200` — GET, PUT, PATCH, DELETE success
- `201` — POST create success
- `400` — Validation failure
- `401` — Unauthorized (missing/expired token)
- `403` — Forbidden (insufficient permissions)
- `404` — Not found
- `409` — Conflict (unique violation)
- `500` — Server error

## Database Access Pattern

**No ORM.** All database access uses PostgreSQL stored procedures via the query helper:

```typescript
// `e_office_app_new/backend/src/lib/db/query.ts`
callFunction<T>(functionName, params)      // Returns T[] (multiple rows)
callFunctionOne<T>(functionName, params)   // Returns T | null (single row)
callProcedure(procedureName, params)       // Void (side-effect only)
rawQuery<T>(sql, params)                   // Direct SQL (rare)
withTransaction<T>(callback)               // Transaction wrapper
```

Repository pattern example:
```typescript
// `e_office_app_new/backend/src/repositories/department.repository.ts`
export const departmentRepository = {
  async getTree(unitId: number | null): Promise<DepartmentTreeRow[]> {
    return callFunction<DepartmentTreeRow>('public.fn_department_get_tree', [unitId]);
  },
};
```

**Rules:**
- ALWAYS use parameterized queries (`$1, $2`) — never string concatenation
- Repository exports a plain object (not a class)
- Each repository defines its own row interfaces
- Stored procedure naming: `{schema}.fn_{module}_{action}`

## Frontend Component Patterns

### Page Structure

Every admin page follows this pattern (single-file, `'use client'`):

```typescript
// `e_office_app_new/frontend/src/app/(main)/quan-tri/{module}/page.tsx`
'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Table, Button, Drawer, Form, App, Modal, Dropdown, ... } from 'antd';
import { api } from '@/lib/api';

interface EntityType { /* snake_case fields matching DB */ }

export default function EntityPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<EntityType[]>([]);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<EntityType | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  const fetchData = useCallback(async () => { /* ... */ }, []);
  useEffect(() => { fetchData(); }, [fetchData]);

  // CRUD handlers...
  // Table columns definition...
  // JSX with page header, card, table, drawer...
}
```

### Drawer (Add/Edit)

- Width: `720` (standard for forms)
- Use `rootClassName="drawer-gradient"` for gradient header
- Title: dynamic based on `editingRecord` — "Them moi" vs "Chinh sua"
- Footer: Save + Cancel buttons in drawer `extra`
- Form uses `validateTrigger="onSubmit"` to prevent layout issues in 2-column forms

### Table Actions

- Use `Dropdown` with `MoreOutlined` icon button, NOT multiple icon buttons
- Divider before dangerous actions (delete)
- Delete uses `Modal.confirm` with `danger: true`
- Lock/Unlock is a toggle action via `PATCH`

### Notifications

- Success: `message.success('Them thanh cong')` — via `App.useApp()`
- Error: `message.error(...)` — only for system errors not mappable to fields
- Never use `alert()` or `notification` popup

### Loading States

- Table: `loading` prop on `<Table>`
- Tree/Page sections: `<Skeleton active paragraph={{ rows: N }} />`
- Never use `<Spin />` full-page

### State Management

- **Zustand** for global state (auth only so far): `e_office_app_new/frontend/src/stores/auth.store.ts`
- **Local state** (`useState`) for page-level data (lists, forms, drawers)
- **Axios** via shared instance: `e_office_app_new/frontend/src/lib/api.ts`
- Token stored in `localStorage`, auto-attached via Axios interceptor
- 401 response triggers automatic refresh token flow

## CSS Approach

**CSS-first layout to prevent FOUC (Flash of Unstyled Content).**

- Layout/structural styles MUST use CSS classes in `e_office_app_new/frontend/src/app/globals.css`
- Dynamic/data-driven styles MAY use inline `style={{}}`
- Shared CSS classes: `.main-layout`, `.main-sider`, `.main-header`, `.main-content`, `.page-header`, `.page-title`, `.page-card`, `.drawer-gradient`, `.stat-card`, `.info-grid`, `.detail-header`, `.filter-row`, `.empty-center`
- Ant Design theme customization in `e_office_app_new/frontend/src/config/theme.ts`
- TailwindCSS v4 is installed but primarily used via `@import "tailwindcss"` base — most styling is through Ant Design + custom CSS classes

**Color Palette:**
- Primary: `#1B3A5C` (deep navy)
- Accent: `#0891B2` (teal)
- Success: `#059669`
- Warning: `#D97706`
- Error: `#DC2626`
- Background: `#F0F2F5`
- Sidebar: `#0F1A2E`

## Language

- **ALL UI text MUST be in Vietnamese with diacritics** (co dau)
- Labels, messages, placeholders, tooltips, tags — everything in Vietnamese
- API error messages are also in Vietnamese
- Constants file uses Vietnamese labels: `e_office_app_new/frontend/src/config/constants.ts`

## Git Conventions

**Commit format:**
```
{type}: {description}

{body}

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
```

**Types:** `feat:`, `fix:`, `refactor:`, `docs:`, `style:`

---

*Convention analysis: 2026-04-14*
