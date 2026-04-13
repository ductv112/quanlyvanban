export const APP_NAME = process.env.NEXT_PUBLIC_APP_NAME || 'Quản lý Văn bản';
export const APP_URL = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';
export const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';

export const PAGE_SIZE = 20;
export const MAX_UPLOAD_SIZE = 50 * 1024 * 1024; // 50MB

export const ALLOWED_FILE_EXTENSIONS = [
  'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
  'pdf', 'jpg', 'jpeg', 'png', 'gif',
  'rar', 'zip', '7z',
  'odt', 'ods', 'odp',
  'mp3', 'wav', 'mp4',
];

export const URGENT_LEVELS = [
  { value: 1, label: 'Thường', color: 'default' },
  { value: 2, label: 'Khẩn', color: 'warning' },
  { value: 3, label: 'Hỏa tốc', color: 'error' },
] as const;

export const SECRET_LEVELS = [
  { value: 1, label: 'Thường', color: 'default' },
  { value: 2, label: 'Mật', color: 'warning' },
  { value: 3, label: 'Tối mật', color: 'error' },
  { value: 4, label: 'Tuyệt mật', color: 'volcano' },
] as const;

export const HANDLING_DOC_STATUS = [
  { value: 0, label: 'Mới tạo', color: 'default' },
  { value: 1, label: 'Đang thực hiện', color: 'processing' },
  { value: 2, label: 'Chờ duyệt', color: 'warning' },
  { value: 3, label: 'Đã duyệt', color: 'success' },
  { value: 4, label: 'Hoàn thành', color: 'success' },
  { value: -1, label: 'Từ chối', color: 'error' },
  { value: -2, label: 'Trả về', color: 'volcano' },
] as const;
