'use client';

import { create } from 'zustand';
import { api } from '@/lib/api';

export interface UserInfo {
  staffId: number;
  unitId: number;
  departmentId: number;
  username: string;
  fullName: string;
  email: string;
  phone: string;
  image: string;
  isAdmin: boolean;
  positionName: string;
  departmentName: string;
  unitName: string;
  roles: string[];
  // HDSD I.4 — chữ ký số (SmartCA)
  signPhone?: string | null;
  signImage?: string | null;
  signImageUrl?: string | null;
}

interface AuthState {
  user: UserInfo | null;
  isLoading: boolean;
  isAuthenticated: boolean;

  login: (username: string, password: string) => Promise<void>;
  logout: () => Promise<void>;
  fetchMe: () => Promise<void>;
  setUser: (user: UserInfo | null) => void;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isLoading: false,
  isAuthenticated: false,

  login: async (username: string, password: string) => {
    set({ isLoading: true });
    try {
      const { data: res } = await api.post('/auth/login', { username, password });
      const { accessToken, user } = res.data;
      localStorage.setItem('accessToken', accessToken);
      set({ user, isAuthenticated: true, isLoading: false });
    } catch (error) {
      set({ isLoading: false });
      throw error;
    }
  },

  logout: async () => {
    try {
      await api.post('/auth/logout');
    } catch {
      // ignore
    } finally {
      localStorage.removeItem('accessToken');
      set({ user: null, isAuthenticated: false });
      window.location.href = '/login';
    }
  },

  fetchMe: async () => {
    try {
      set({ isLoading: true });
      const { data: res } = await api.get('/auth/me');
      set({ user: res.data, isAuthenticated: true, isLoading: false });
    } catch {
      set({ user: null, isAuthenticated: false, isLoading: false });
    }
  },

  setUser: (user) => {
    set({ user, isAuthenticated: !!user });
  },
}));
