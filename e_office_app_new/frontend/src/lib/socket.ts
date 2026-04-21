import { io, Socket } from 'socket.io-client';

let socket: Socket | null = null;

export const SOCKET_EVENTS = {
  NEW_DOCUMENT: 'new_document',
  NEW_MESSAGE: 'new_message',
  NEW_NOTIFICATION: 'new_notification',
  DOC_STATUS_CHANGED: 'doc_status_changed',
  // Phase 11 — async sign flow
  SIGN_COMPLETED: 'sign_completed',
  SIGN_FAILED: 'sign_failed',
} as const;

export function initSocket(token: string): Socket {
  if (socket && socket.connected) {
    return socket;
  }

  socket = io(process.env.NEXT_PUBLIC_API_URL || 'http://localhost:4000', {
    auth: { token },
    autoConnect: true,
    reconnection: true,
    reconnectionDelay: 3000,
  });

  return socket;
}

export function getSocket(): Socket | null {
  return socket;
}

export function disconnectSocket(): void {
  if (socket) {
    socket.disconnect();
    socket = null;
  }
}
