/**
 * useUserRights — fetch + cache user's rights (Set<number>) from
 * action_of_role × role_of_staff (via /quan-tri/chuc-nang/menu).
 *
 * Phase 37.1: shared hook để 3 LGSP page + MainLayout cùng dùng pattern
 * `hasRight(rightId)` thay vì hardcode isAdmin role check.
 *
 * Cache module-level (KHÔNG fetch lại trong cùng tab) — invalidate khi user
 * thay đổi (staff_id khác).
 *
 * Usage:
 *   const { hasRight, isAdmin, loaded } = useUserRights();
 *   if (!loaded) return <Skeleton />;
 *   if (!hasRight(26)) return <Alert>Không có quyền</Alert>;
 */
import { useEffect, useState, useRef } from 'react';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';

// Module-level cache scoped per staffId
let cachedStaffId: number | null = null;
let cachedRights: ReadonlySet<number> | null = null;
let cachedFetchPromise: Promise<ReadonlySet<number>> | null = null;

async function fetchRights(): Promise<ReadonlySet<number>> {
  const res = await api.get('/quan-tri/chuc-nang/menu');
  const ids = (res.data?.data || []).map((r: { id: number }) => r.id);
  return new Set<number>(ids);
}

/**
 * v3.2.2 fix #M11: Clear module-level rights cache.
 * Call tu auth.store.logout() de tranh leak quyen cua user truoc.
 * Hook se tu re-fetch khi staffId thay doi, nhung clear explicit
 * dam bao cache sach giua 2 phien dang nhap.
 */
export function clearUserRightsCache(): void {
  cachedStaffId = null;
  cachedRights = null;
  cachedFetchPromise = null;
}

export function useUserRights() {
  const { user } = useAuthStore();
  const isAdmin = Boolean(
    user?.isAdmin || user?.roles?.includes('Quản trị hệ thống'),
  );
  const staffId = user?.staffId ?? null;

  const [rights, setRights] = useState<ReadonlySet<number>>(
    cachedStaffId === staffId && cachedRights ? cachedRights : new Set(),
  );
  const [loaded, setLoaded] = useState<boolean>(
    cachedStaffId === staffId && cachedRights !== null,
  );
  const mountedRef = useRef(true);

  useEffect(() => {
    mountedRef.current = true;
    return () => {
      mountedRef.current = false;
    };
  }, []);

  useEffect(() => {
    if (!staffId) {
      setRights(new Set());
      setLoaded(false);
      return;
    }
    // Cache hit: cùng staffId + đã load
    if (cachedStaffId === staffId && cachedRights) {
      setRights(cachedRights);
      setLoaded(true);
      return;
    }
    // Dedupe concurrent: cùng staffId + đang fetch → await chung Promise
    if (cachedStaffId === staffId && cachedFetchPromise) {
      cachedFetchPromise.then((set) => {
        if (mountedRef.current) {
          setRights(set);
          setLoaded(true);
        }
      });
      return;
    }
    // Cold fetch
    cachedStaffId = staffId;
    cachedFetchPromise = fetchRights()
      .then((set) => {
        cachedRights = set;
        return set;
      })
      .catch(() => {
        cachedRights = new Set();
        return cachedRights;
      })
      .finally(() => {
        cachedFetchPromise = null;
      });
    cachedFetchPromise.then((set) => {
      if (mountedRef.current) {
        setRights(set);
        setLoaded(true);
      }
    });
  }, [staffId]);

  // hasRight: admin auto pass, else check Set
  const hasRight = (rightId: number): boolean => {
    if (isAdmin) return true;
    return rights.has(rightId);
  };

  return { hasRight, isAdmin, loaded, rights };
}
