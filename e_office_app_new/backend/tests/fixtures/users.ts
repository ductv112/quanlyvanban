/**
 * tests/fixtures/users.ts — Test user fixtures
 *
 * Đồng bộ với database/seed/003_test_fixtures.sql.
 * KHI thay đổi seed 003 → update file này; ngược lại.
 *
 * Dùng cho:
 * - Integration test (supertest): import TEST_USERS rồi POST /api/auth/login
 * - E2E test (Playwright): import TEST_USERS trong globalSetup.ts để gen storage state
 */

export interface TestUser {
  id: number;
  username: string;
  password: string;
  full_name: string;
  email: string;
  department_id: number;
  unit_id: number;
  position_id: number;
  role_ids: number[];
  role_name: string;
  is_locked?: boolean;
}

export const TEST_USERS = {
  admin: {
    id: 9001,
    username: 'test_admin',
    password: 'Test@123',
    full_name: 'TEST Quan tri',
    email: 'test_admin@test.local',
    department_id: 1,
    unit_id: 1,
    position_id: 1,
    role_ids: [5],
    role_name: 'Quản trị hệ thống',
  },
  vanthu: {
    id: 9002,
    username: 'test_vanthu',
    password: 'Test@123',
    full_name: 'TEST Van thu',
    email: 'test_vanthu@test.local',
    department_id: 2,
    unit_id: 2,
    position_id: 6,
    role_ids: [6],
    role_name: 'Văn thư',
  },
  lanhdao: {
    id: 9003,
    username: 'test_lanhdao',
    password: 'Test@123',
    full_name: 'TEST Lanh dao',
    email: 'test_lanhdao@test.local',
    department_id: 2,
    unit_id: 2,
    position_id: 1,
    role_ids: [1],
    role_name: 'Ban Lãnh đạo',
  },
  canbo: {
    id: 9004,
    username: 'test_canbo',
    password: 'Test@123',
    full_name: 'TEST Can bo',
    email: 'test_canbo@test.local',
    department_id: 2,
    unit_id: 2,
    position_id: 5,
    role_ids: [2],
    role_name: 'Cán bộ',
  },
  canboX: {
    id: 9005,
    username: 'test_canbo_x',
    password: 'Test@123',
    full_name: 'TEST CB don vi khac',
    email: 'test_canbo_x@test.local',
    department_id: 3,
    unit_id: 3,
    position_id: 5,
    role_ids: [2],
    role_name: 'Cán bộ',
  },
  locked: {
    id: 9099,
    username: 'test_locked',
    password: 'Test@123',
    full_name: 'TEST User da khoa',
    email: 'test_locked@test.local',
    department_id: 2,
    unit_id: 2,
    position_id: 5,
    role_ids: [2],
    role_name: 'Cán bộ',
    is_locked: true,
  },
} as const satisfies Record<string, TestUser>;

export const ALL_TEST_USERS = Object.values(TEST_USERS);
export const ALL_TEST_USER_KEYS = Object.keys(TEST_USERS) as (keyof typeof TEST_USERS)[];

/**
 * Helper: lookup user theo role_id (phục vụ test parametrized theo role).
 * Trả về first match — không lookup mọi user của role đó.
 */
export function getUserByRoleId(roleId: number): TestUser | undefined {
  return ALL_TEST_USERS.find((u) => u.role_ids.includes(roleId));
}
