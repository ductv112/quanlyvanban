'use client';

import { useEffect, useState } from 'react';
import { Modal, Spin, Empty, Button, App } from 'antd';
import { DownloadOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';
import { getPreviewKind, type PreviewKind } from '@/lib/preview';

export interface AttachmentPreviewModalProps {
  open: boolean;
  onClose: () => void;
  /** API path tương đối — vd: /van-ban-den/123/dinh-kem/456/preview */
  previewPath: string | null;
  /** API path tải xuống (fallback) — vd: /van-ban-den/123/dinh-kem/456/download */
  downloadPath?: string | null;
  fileName: string;
  /** MIME của file (từ AttachmentRow.content_type) */
  mimeType?: string | null;
}

/**
 * Modal full-screen hiển thị xem trực tiếp file đính kèm.
 *
 * - PDF / Office (đã convert PDF tại backend): iframe
 * - Image: <img>
 * - Text: <pre>
 * - MIME khác: thông báo không hỗ trợ + nút Tải xuống
 *
 * Fetch file qua axios (blob) -> URL.createObjectURL -> set vào iframe/img/pre.
 * Cleanup blob URL khi đóng Modal hoặc đổi file.
 */
export function AttachmentPreviewModal(props: AttachmentPreviewModalProps) {
  const { open, onClose, previewPath, downloadPath, fileName, mimeType } = props;
  const { message } = App.useApp();

  const [loading, setLoading] = useState(false);
  const [blobUrl, setBlobUrl] = useState<string | null>(null);
  const [textContent, setTextContent] = useState<string | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);

  const kind: PreviewKind = getPreviewKind(mimeType, fileName);

  useEffect(() => {
    if (!open || !previewPath) return;

    let cancelled = false;
    let createdBlobUrl: string | null = null;

    const fetchPreview = async () => {
      setLoading(true);
      setErrorMsg(null);
      setBlobUrl(null);
      setTextContent(null);

      try {
        if (kind === 'unsupported') {
          setErrorMsg('Loại file này không hỗ trợ xem trực tiếp. Vui lòng tải xuống để mở bằng ứng dụng phù hợp.');
          return;
        }

        const res = await api.get(previewPath, { responseType: 'blob' });
        if (cancelled) return;

        const responseType = (res.headers?.['content-type'] as string) || mimeType || 'application/octet-stream';

        if (kind === 'text') {
          const text = await (res.data as Blob).text();
          if (!cancelled) setTextContent(text);
        } else {
          const blob = new Blob([res.data], { type: responseType });
          createdBlobUrl = URL.createObjectURL(blob);
          if (!cancelled) setBlobUrl(createdBlobUrl);
        }
      } catch (err: unknown) {
        if (cancelled) return;
        const e = err as { response?: { status?: number; data?: { message?: string } | Blob } };
        if (e.response?.status === 415) {
          // Backend tra blob JSON message — cần parse
          const data = e.response.data;
          let msg = 'Loại file không hỗ trợ xem trực tiếp.';
          if (data instanceof Blob) {
            try {
              const text = await data.text();
              const parsed = JSON.parse(text) as { message?: string };
              if (parsed.message) msg = parsed.message;
            } catch { /* keep default */ }
          } else if (data && typeof data === 'object' && 'message' in data && data.message) {
            msg = data.message;
          }
          setErrorMsg(msg);
        } else if (e.response?.status === 404) {
          setErrorMsg('Không tìm thấy file đính kèm.');
        } else {
          setErrorMsg('Không thể tải file để xem trực tiếp. Vui lòng thử tải xuống.');
          // eslint-disable-next-line no-console
          console.error('Preview fetch error:', err);
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    };

    fetchPreview();

    return () => {
      cancelled = true;
      if (createdBlobUrl) URL.revokeObjectURL(createdBlobUrl);
    };
  }, [open, previewPath, kind, mimeType]);

  // Cleanup blob URL khi component unmount
  useEffect(() => {
    return () => {
      if (blobUrl) URL.revokeObjectURL(blobUrl);
    };
  }, [blobUrl]);

  const handleDownloadFallback = async () => {
    if (!downloadPath) return;
    try {
      const res = await api.get(downloadPath, { responseType: 'blob' });
      const url = URL.createObjectURL(new Blob([res.data]));
      const a = document.createElement('a');
      a.href = url;
      a.download = fileName || 'download';
      document.body.appendChild(a);
      a.click();
      document.body.removeChild(a);
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    } catch {
      message.error('Tải xuống thất bại');
    }
  };

  const footerButtons: React.ReactNode[] = [];
  if (downloadPath) {
    footerButtons.push(
      <Button key="download" icon={<DownloadOutlined />} onClick={handleDownloadFallback}>
        Tải xuống
      </Button>,
    );
  }
  footerButtons.push(
    <Button key="close" type="primary" onClick={onClose}>
      Đóng
    </Button>,
  );

  return (
    <Modal
      open={open}
      onCancel={onClose}
      title={`Xem trực tiếp: ${fileName}`}
      width="90vw"
      style={{ top: 20, maxWidth: 1400 }}
      styles={{ body: { height: 'calc(100vh - 200px)', overflow: 'hidden', padding: 0 } }}
      footer={footerButtons}
      destroyOnHidden
    >
      {loading && (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
          <Spin size="large" tip="Đang tải file để xem trực tiếp..." />
        </div>
      )}

      {!loading && errorMsg && (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100%' }}>
          <Empty description={errorMsg} />
        </div>
      )}

      {!loading && !errorMsg && blobUrl && (kind === 'pdf' || kind === 'office') && (
        <iframe
          src={blobUrl}
          style={{ width: '100%', height: '100%', border: 'none' }}
          title={fileName}
        />
      )}

      {!loading && !errorMsg && blobUrl && kind === 'image' && (
        <div style={{
          display: 'flex', justifyContent: 'center', alignItems: 'center',
          height: '100%', background: '#0F1A2E', overflow: 'auto',
        }}>
          <img src={blobUrl} alt={fileName} style={{ maxWidth: '100%', maxHeight: '100%', objectFit: 'contain' }} />
        </div>
      )}

      {!loading && !errorMsg && textContent !== null && kind === 'text' && (
        <pre style={{
          width: '100%', height: '100%', margin: 0, padding: 16,
          overflow: 'auto', whiteSpace: 'pre-wrap', wordBreak: 'break-word',
          fontFamily: 'Consolas, Monaco, monospace', fontSize: 13, lineHeight: 1.5,
        }}>
          {textContent}
        </pre>
      )}
    </Modal>
  );
}
