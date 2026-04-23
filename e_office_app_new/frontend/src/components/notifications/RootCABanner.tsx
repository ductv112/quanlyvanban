'use client';

/**
 * RootCABanner — Banner hướng dẫn cài Root CA Viettel (Phase 13 UX-11 + DEP-02).
 *
 * Luôn hiển thị ở trang Danh sách ký số để user có thể tải Root CA + HDSD bất cứ lúc nào
 * (override D-22 → D-26: bỏ trigger conditional + bỏ dismiss localStorage per user feedback UAT).
 *
 * Static URLs (D-30): /root-ca/*.cer và /root-ca/*.pdf — Next.js tự serve từ public/.
 */

import { Alert, Button, Space } from 'antd';
import {
  SafetyCertificateOutlined,
  DownloadOutlined,
  FilePdfOutlined,
} from '@ant-design/icons';

export default function RootCABanner() {
  return (
    <Alert
      type="info"
      showIcon
      icon={<SafetyCertificateOutlined style={{ color: '#0891B2', fontSize: 20 }} />}
      title={
        <span style={{ fontWeight: 600, color: '#1B3A5C' }}>
          Cần cài Root CA Viettel để Adobe Reader hiển thị chữ ký hợp lệ
        </span>
      }
      description={
        <div>
          <p style={{ marginBottom: 12, color: '#475569', lineHeight: 1.5 }}>
            Nếu Adobe Reader báo chữ ký không xác thực khi mở file đã ký bằng MySign Viettel,
            hãy cài Root CA Viettel 1 lần duy nhất theo hướng dẫn bên dưới.
          </p>
          <Space wrap>
            <Button
              type="primary"
              icon={<DownloadOutlined />}
              href="/root-ca/viettel-ca-new.cer"
              download
            >
              Tải Root CA (.cer)
            </Button>
            <Button
              icon={<FilePdfOutlined />}
              href="/root-ca/huong-dan-cai-root-ca.pdf"
              target="_blank"
              rel="noopener noreferrer"
            >
              Xem hướng dẫn (PDF)
            </Button>
          </Space>
        </div>
      }
      style={{ marginBottom: 16, borderRadius: 8 }}
    />
  );
}
