import { hashSync, compareSync } from 'bcryptjs';

export function hashPassword(plain: string): string {
  return hashSync(plain, 12);
}

export function verifyPassword(plain: string, hashed: string): boolean {
  return compareSync(plain, hashed);
}
