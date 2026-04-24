// Public catalog routes — readable cho mọi user authenticated
// Phase 17 v3.0: cần cho recipient picker (multi-select departments) trong form VB đi
import { Router, type Request, type Response } from 'express';
import { rawQuery } from '../lib/db/query.js';
import { handleDbError } from '../lib/error-handler.js';

const router = Router();

interface DeptRow {
  id: number;
  parent_id: number | null;
  code: string | null;
  name: string;
  short_name: string | null;
  is_unit: boolean;
  level: number | null;
  sort_order: number | null;
}

// GET /don-vi — flat list cho Select component
router.get('/don-vi', async (_req: Request, res: Response) => {
  try {
    const rows = await rawQuery<DeptRow>(
      `SELECT id, parent_id, code, name, short_name, is_unit, level, sort_order
       FROM public.departments
       WHERE COALESCE(is_locked, false) = false
       ORDER BY sort_order NULLS LAST, name`,
    );
    res.json({ success: true, data: rows });
  } catch (error) {
    handleDbError(error, res);
  }
});

// GET /don-vi/tree — tree (con lồng vào parent) cho Tree/TreeSelect component
router.get('/don-vi/tree', async (_req: Request, res: Response) => {
  try {
    const rows = await rawQuery<DeptRow>(
      `SELECT id, parent_id, code, name, short_name, is_unit, level, sort_order
       FROM public.departments
       WHERE COALESCE(is_locked, false) = false
       ORDER BY sort_order NULLS LAST, name`,
    );
    // Build tree
    const map = new Map<number, DeptRow & { children: any[] }>();
    rows.forEach((r) => map.set(r.id, { ...r, children: [] }));
    const roots: any[] = [];
    rows.forEach((r) => {
      const node = map.get(r.id)!;
      if (r.parent_id && map.has(r.parent_id)) {
        map.get(r.parent_id)!.children.push(node);
      } else {
        roots.push(node);
      }
    });
    res.json({ success: true, data: roots });
  } catch (error) {
    handleDbError(error, res);
  }
});

export default router;
