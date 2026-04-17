# Phase 3: Liên thông & Tin nhắn - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.

**Date:** 2026-04-14
**Phase:** 03-liên thông & tin nhắn
**Mode:** --auto (all decisions auto-selected)
**Areas discussed:** VB liên thông, Giao việc, Tin nhắn layout, Thông báo realtime

---

## VB liên thông & Giao việc

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse VB đến pattern | Table + detail page tương tự VB đến | ✓ |
| Standalone design | Thiết kế hoàn toàn mới | |

**User's choice:** [auto] Reuse VB đến pattern (recommended — ROADMAP chỉ định "tương tự VB đến")

---

## Tin nhắn layout

| Option | Description | Selected |
|--------|-------------|----------|
| Mail-like 3-panel | Sidebar + list + detail (Gmail style) | ✓ |
| Chat-like | Conversation bubbles | |
| Simple list + modal | Table list + modal for detail | |

**User's choice:** [auto] Mail-like 3-panel (recommended — ROADMAP chỉ định "layout mail-like")

---

## Thông báo & Realtime

| Option | Description | Selected |
|--------|-------------|----------|
| Socket.IO + bell dropdown | Real-time events, bell icon in header | ✓ |
| Polling | Periodic API calls for notifications | |

**User's choice:** [auto] Socket.IO + bell dropdown (recommended — ROADMAP chỉ định Socket.IO)

## Claude's Discretion
- Route file organization, Socket.IO room strategy, rich text vs plain text, pagination approach

## Deferred Ideas
None
