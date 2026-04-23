'use client';

/**
 * RootCABanner — Banner hướng dẫn cài Root CA Viettel (Phase 13 UX-11 + DEP-02).
 *
 * Trigger (D-22): Hiện khi user tải file ký bằng MYSIGN_VIETTEL lần đầu tiên AND
 * localStorage.dismiss_root_ca_banner !== 'true'. Parent decide visible=true qua
 * handleDownload. Component tự check localStorage defense-in-depth + handle dismiss.
 *
 * Position (D-23): Mount dưới page header, trước main content card — full width.
 *
 * Dismiss (D-25): Click X → localStorage.dismiss_root_ca_banner = 'true' →
 * không bao giờ hiện lại trong browser này (user sang browser/máy khác sẽ thấy lại).
 *
 * Static URLs (D-30): /root-ca/*.cer và /root-ca/*.pdf — Next.js tự serve từ public/.
 */

import { Alert, Button, Space } from 'antd';
import {
  SafetyCertificateOutlined,
  DownloadOutlined,
  FilePdfOutlined,
} from '@ant-design/icons';

interface Props {
  /** Parent-controlled visibility — reset sau khi user dismiss */
  visible: boolean;
  /** Callback khi user click X close — parent remove trigger state */
  onDismiss: () => void;
}

const DISMISS_KEY = 'dismiss_root_ca_banner';

export default function RootCABanner({ visible, onDismiss }: Props) {
  if (!visible) return null;

  // Defense-in-depth: ngay cả khi parent set visible=true, check localStorage
  // một lần nữa trước render (tránh race condition trong SSR/hydration + bảo vệ
  // khỏi lỗi logic trong parent không filter dismiss trước khi set visible).
  if (typeof window !== 'undefined' && localStorage.getItem(DISMISS_KEY) === 'true') {
    return null;
  }

  const handleClose = () => {
    if (typeof window !== 'undefined') {
      localStorage.setItem(DISMISS_KEY, 'true');
    }
    onDismiss();
  };

  return (
    <Alert
      type="info"
      showIcon
      icon={<SafetyCertificateOutlined style={{ color: '#0891B2', fontSize: 20 }} />}
      message={
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
      closable
      onClose={handleClose}
      style={{ marginBottom: 16, borderRadius: 8 }}
    />
  );
}
