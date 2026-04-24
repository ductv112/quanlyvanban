import { api } from './api';

/**
 * Tải file đính kèm qua backend proxy (stream response).
 * Dùng thay cho pattern cũ `window.open(presignedUrl)` vì MinIO nội bộ
 * không public cho browser truy cập trực tiếp.
 */
export async function downloadAttachment(apiPath: string, fileName: string): Promise<void> {
  const res = await api.get(apiPath, { responseType: 'blob' });
  const contentType = (res.headers?.['content-type'] as string) || 'application/octet-stream';
  const blobUrl = URL.createObjectURL(new Blob([res.data], { type: contentType }));
  const a = document.createElement('a');
  a.href = blobUrl;
  a.download = fileName || 'download';
  document.body.appendChild(a);
  a.click();
  document.body.removeChild(a);
  setTimeout(() => URL.revokeObjectURL(blobUrl), 1000);
}
