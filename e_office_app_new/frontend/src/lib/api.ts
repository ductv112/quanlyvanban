import axios from 'axios';

const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000/api';

export const api = axios.create({
  baseURL: API_URL,
  timeout: 30000,
  headers: { 'Content-Type': 'application/json' },
  withCredentials: true,
});

// Tự động gắn access token vào mọi request
api.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('accessToken');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

// Xử lý token expired → refresh
//
// BUG #87 (2026-05-19): Trang detail bắn 7 requests song song qua Promise.all.
// Nếu access token hết hạn → tất cả nhận 401 → mỗi cái gọi refresh độc lập →
// refresh token bị rotate sau cái thứ nhất → các cái sau dùng cookie cũ → fail
// → fetchDoc fail → bounce về list + show "Lỗi". Click lại lần 2 thì localStorage
// đã có access token mới → mọi thứ OK.
//
// Fix: dedupe — chỉ 1 refresh in-flight. Các 401 sau queue đợi promise đó, rồi
// retry với token mới.
let refreshPromise: Promise<string> | null = null;
async function refreshAccessToken(): Promise<string> {
  if (refreshPromise) return refreshPromise;
  refreshPromise = (async () => {
    try {
      const { data } = await axios.post(`${API_URL}/auth/refresh`, {}, { withCredentials: true });
      const newToken: string = data.data.accessToken;
      localStorage.setItem('accessToken', newToken);
      return newToken;
    } finally {
      // clear regardless of success/fail — next 401 wave có thể trigger refresh mới
      refreshPromise = null;
    }
  })();
  return refreshPromise;
}

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && !originalRequest._retry) {
      originalRequest._retry = true;
      try {
        const newToken = await refreshAccessToken();
        originalRequest.headers.Authorization = `Bearer ${newToken}`;
        return api(originalRequest);
      } catch {
        localStorage.removeItem('accessToken');
        if (typeof window !== 'undefined') {
          window.location.href = '/login';
        }
      }
    }

    return Promise.reject(error);
  }
);
