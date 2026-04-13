import * as Minio from 'minio';

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

export async function getFileUrl(path: string, expirySeconds = 3600): Promise<string> {
  return minioClient.presignedGetObject(BUCKET, path, expirySeconds);
}

export async function deleteFile(path: string): Promise<void> {
  await minioClient.removeObject(BUCKET, path);
}
