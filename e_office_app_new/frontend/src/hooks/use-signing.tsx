'use client';

/**
 * useSigning — React hook quản lý state + render cho SignModal.
 *
 * Usage trong detail pages (Plans 11-07/08/09):
 *
 *   const { openSign, renderSignModal } = useSigning();
 *
 *   // Trong action handler:
 *   openSign({
 *     attachment: { id: file.id, file_name: file.file_name },
 *     attachmentType: 'outgoing',
 *     docId: doc.id,
 *     onSuccess: () => fetchAttachments(),
 *   });
 *
 *   // Trong render:
 *   return (
 *     <>
 *       ...JSX page...
 *       {renderSignModal()}
 *     </>
 *   );
 *
 * Hook đảm bảo:
 *   - Chỉ 1 modal active cùng lúc (single state)
 *   - onSuccess callback của caller được giữ trong state + fire lại khi terminal
 *   - Auto-close 1.2s sau 'completed' để user kịp thấy Alert success
 *   - closeSign không trigger onSuccess → idempotent
 */

import { useCallback, useRef, useState } from 'react';
import SignModal from '@/components/signing/SignModal';
import type { AttachmentType } from '@/lib/signing/types';

/** Tối thiểu shape cho attachment — chỉ cần id + file_name. */
interface AttachmentLike {
  id: number;
  file_name: string;
}

export interface OpenSignParams {
  attachment: AttachmentLike;
  attachmentType: AttachmentType;
  docId?: number;
  signReason?: string;
  signLocation?: string;
  /** Fired exactly once khi modal chuyển 'completed' — parent refresh danh sách file. */
  onSuccess?: () => void;
}

interface SigningState {
  open: boolean;
  attachment: AttachmentLike | null;
  attachmentType: AttachmentType;
  docId?: number;
  signReason?: string;
  signLocation?: string;
}

export function useSigning() {
  const [state, setState] = useState<SigningState>({
    open: false,
    attachment: null,
    attachmentType: 'outgoing',
  });

  // onSuccess callback không lưu vào state — tránh re-render loop khi caller
  // pass inline arrow function. Ref pattern: fire-and-forget.
  const onSuccessRef = useRef<(() => void) | undefined>(undefined);

  const openSign = useCallback((params: OpenSignParams) => {
    onSuccessRef.current = params.onSuccess;
    setState({
      open: true,
      attachment: params.attachment,
      attachmentType: params.attachmentType,
      docId: params.docId,
      signReason: params.signReason,
      signLocation: params.signLocation,
    });
  }, []);

  const closeSign = useCallback(() => {
    setState((s) => ({ ...s, open: false }));
  }, []);

  const handleSuccess = useCallback(() => {
    // Fire caller callback — parent refresh file list
    try {
      onSuccessRef.current?.();
    } catch {
      // Swallow — callback lỗi không nên crash modal
    }
    // Auto-close ~1.2s để user kịp thấy Alert "Ký số thành công"
    setTimeout(() => {
      setState((s) => ({ ...s, open: false }));
    }, 1200);
  }, []);

  const renderSignModal = useCallback(() => {
    if (!state.attachment) return null;
    return (
      <SignModal
        open={state.open}
        onClose={closeSign}
        onSuccess={handleSuccess}
        attachmentId={state.attachment.id}
        attachmentType={state.attachmentType}
        fileName={state.attachment.file_name}
        docId={state.docId}
        signReason={state.signReason}
        signLocation={state.signLocation}
      />
    );
  }, [state, closeSign, handleSuccess]);

  return { openSign, closeSign, renderSignModal };
}
