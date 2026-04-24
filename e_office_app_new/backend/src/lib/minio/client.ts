import * as Minio from 'minio';
import type { Response } from 'express';
import type { Readable } from 'stream';

export const minioClient = new Minio.Client({
  endPoint: process.env.MINIO_ENDPOINT || 'localhost',
  port: Number(process.env.MINIO_PORT) || 9000,
  useSSL: process.env.MINIO_USE_SSL === 'true',
  accessKey: process.env.MINIO_ACCESS_KEY || '',
  secretKey: process.env.MINIO_SECRET_KEY || '',
});

const BUCKET = process.env.MINIO_BUCKET || 'documents';

export async function ensureBucket(): Promise<void> {
  const exists = await minioClient.bucketExists(BUCKET);
  if (!exists) await minioClient.makeBucket(BUCKET);
}

export async function uploadFile(path: string, buffer: Buffer, contentType: string): Promise<string> {
  await ensureBucket();
  await minioClient.putObject(BUCKET, path, buffer, buffer.length, { 'Content-Type': contentType });
  return path;
}

/**
 * Presigned URL - CHI DUNG khi MinIO endpoint cong khai, browser truy cap duoc.
 * Voi production MinIO localhost-only, dung streamFileToResponse thay the.
 */
export async function getFileUrl(path: string, expirySeconds = 3600): Promise<string> {
  return minioClient.presignedGetObject(BUCKET, path, expirySeconds);
}

/**
 * Stream file tu MinIO qua backend response. Dung cho production khi MinIO
 * khong public - browser download qua backend proxy.
 * File name dung UTF-8 encoded theo RFC 5987 de browser hien thi ten tieng Viet dung.
 */
export async function streamFileToResponse(
  res: Response,
  path: string,
  fileName: string,
  contentType?: string,
): Promise<void> {
  const stream: Readable = await minioClient.getObject(BUCKET, path);
  if (contentType) res.setHeader('Content-Type', contentType);
  // RFC 5987: filename* voi UTF-8 encoding + fallback filename= voi ASCII
  const asciiFallback = fileName.replace(/[^\x20-\x7E]/g, '_');
  res.setHeader(
    'Content-Disposition',
    `attachment; filename="${asciiFallback}"; filename*=UTF-8''${encodeURIComponent(fileName)}`,
  );
  stream.pipe(res);
}

export async function deleteFile(path: string): Promise<void> {
  await minioClient.removeObject(BUCKET, path);
}
