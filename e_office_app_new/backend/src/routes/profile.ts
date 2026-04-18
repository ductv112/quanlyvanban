import { Router } from 'express';
import type { Request, Response } from 'express';
import { randomUUID } from 'node:crypto';
import { type AuthRequest } from '../middleware/auth.js';
import { upload } from '../middleware/upload.js';
import { uploadFile, getFileUrl } from '../lib/minio/client.js';
import { profileRepository } from '../repositories/profile.repository.js';

/**
 * /api/ho-so-ca-nhan/* — routes cho profile cá nhân.
 * MOUNT với CHỈ authenticate (không requireRoles) để mọi user dùng được.
 * HDSD I.4: SmartCA UI — upload ảnh chữ ký + tài khoản ký số (sign_phone).
 */

const router = Router();

const SIGN_PHONE_PATTERN = /^[0-9+\-\s()]*$/;
const MAX_SIGN_IMAGE_SIZE = 2 * 1024 * 1024; // 2MB
const PRESIGNED_EXPIRY_SECONDS = 3600;

// PATCH /chu-ky-so — Cập nhật sign_phone (và optional sign_ca)
router.patch('/chu-ky-so', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;

    const signPhoneRaw = req.body?.sign_phone;
    const signCaRaw = req.body?.sign_ca;

    let signPhone: string | null = null;
    if (signPhoneRaw !== undefined && signPhoneRaw !== null) {
      if (typeof signPhoneRaw !== 'string') {
        res.status(400).json({ success: false, message: 'Tài khoản ký số không hợp lệ' });
        return;
      }
      const trimmed = signPhoneRaw.trim();
      if (trimmed.length > 0) {
        if (trimmed.length > 20) {
          res.status(400).json({ success: false, message: 'Tài khoản ký số tối đa 20 ký tự' });
          return;
        }
        if (!SIGN_PHONE_PATTERN.test(trimmed)) {
          res.status(400).json({ success: false, message: 'Số điện thoại ký số không hợp lệ' });
          return;
        }
      }
      signPhone = trimmed.length > 0 ? trimmed : '';
    }

    let signCa: string | null = null;
    if (signCaRaw !== undefined && signCaRaw !== null) {
      if (typeof signCaRaw !== 'string') {
        res.status(400).json({ success: false, message: 'sign_ca không hợp lệ' });
        return;
      }
      signCa = signCaRaw;
    }

    // SP COALESCE → NULL = giữ nguyên. Để cho phép XÓA sign_phone, ta truyền chuỗi rỗng → SP sẽ giữ nguyên.
    // Nếu cần XÓA hẳn, cần SP riêng — tạm thời: chuỗi rỗng → set thành '' (cho qua SP với COALESCE thì giữ nguyên).
    // Theo HDSD: chỉ cần update khi user nhập, không cần delete → truyền NULL nếu không nhập.
    const phoneParam = signPhone === null || signPhone === '' ? null : signPhone;
    const caParam = signCa === null || signCa === '' ? null : signCa;

    const result = await profileRepository.updateSignature(staffId, phoneParam, caParam, null);

    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Cập nhật thất bại' });
      return;
    }

    res.json({ success: true, message: result.message });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err instanceof Error ? err.message : 'Có lỗi xảy ra',
    });
  }
});

// POST /anh-chu-ky — Upload ảnh chữ ký (PNG ≤ 2MB)
router.post('/anh-chu-ky', upload.single('file'), async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;

    if (!req.file) {
      res.status(400).json({ success: false, message: 'Vui lòng chọn file ảnh PNG' });
      return;
    }

    if (req.file.mimetype !== 'image/png') {
      res.status(400).json({ success: false, message: 'Chỉ chấp nhận file PNG' });
      return;
    }

    if (req.file.size > MAX_SIGN_IMAGE_SIZE) {
      res.status(400).json({ success: false, message: 'Kích thước ảnh tối đa 2MB' });
      return;
    }

    const key = `signatures/${staffId}/${randomUUID()}.png`;
    await uploadFile(key, req.file.buffer, 'image/png');

    const result = await profileRepository.updateSignature(staffId, null, null, key);
    if (!result?.success) {
      res.status(400).json({ success: false, message: result?.message || 'Cập nhật thất bại' });
      return;
    }

    const url = await getFileUrl(key, PRESIGNED_EXPIRY_SECONDS);

    res.json({
      success: true,
      message: result.message,
      sign_image: key,
      sign_image_url: url,
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err instanceof Error ? err.message : 'Có lỗi khi tải lên ảnh chữ ký',
    });
  }
});

// GET /anh-chu-ky — Lấy presigned URL preview ảnh chữ ký hiện tại
router.get('/anh-chu-ky', async (req: Request, res: Response) => {
  try {
    const { staffId } = (req as AuthRequest).user;
    const row = await profileRepository.getSignature(staffId);

    if (!row?.sign_image) {
      res.json({ success: true, data: { url: null } });
      return;
    }

    const url = await getFileUrl(row.sign_image, PRESIGNED_EXPIRY_SECONDS);
    res.json({ success: true, data: { url } });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err instanceof Error ? err.message : 'Có lỗi khi lấy ảnh chữ ký',
    });
  }
});

export default router;
