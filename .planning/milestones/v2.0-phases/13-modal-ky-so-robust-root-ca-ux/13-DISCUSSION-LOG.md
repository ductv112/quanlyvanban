# Phase 13: Modal ký số robust + Root CA UX — Discussion Log

> **Audit trail only.** Không dùng làm input cho planning/research/execution.
> Decisions canonical lưu trong `13-CONTEXT.md` — log này giữ alternatives considered.

**Date:** 2026-04-22
**Phase:** 13-modal-ky-so-robust-root-ca-ux
**Areas discussed:** Bell store, Countdown UI, Root CA banner, Bell scope

---

## Bell notification storage

| Option | Description | Selected |
|--------|-------------|----------|
| PostgreSQL `notifications` table (Recommended) | Bảng public.notifications + 5 SPs. Fit stack hiện tại (repository pattern), query dễ, transaction safe, join với staff/txn dễ. Retention 30 ngày qua cron. | ✓ |
| MongoDB audit log | Collection notifications. Memory note tech-gaps: Mongo chưa dùng — cơ hội start. Tạo thêm 1 stack layer, indexing riêng. | |
| Redis persistent + TTL | List `notif:staff_{id}` TTL 30 ngày. Nhanh read, mất data nếu crash. Không đủ bền vững production. | |

**User's choice:** PostgreSQL `notifications` table
**Notes:** Chuẩn hoá với pattern repository + SP, không tạo tech stack layer mới cho 1 feature.

---

## Countdown UI 3:00 → 0:00

| Option | Description | Selected |
|--------|-------------|----------|
| Circular progress + text MM:SS giữa (Recommended) | AntD `<Progress type='circle' size=120>` với percent + format text. Visual đẹp, user thấy rõ tỉ lệ thời gian còn lại. | ✓ |
| Text only MM:SS | `<Tag>⏱️ 2:45</Tag>` warning <30s. Code ít, visual kém ấn tượng. | |
| Linear progress bar + text | Progress bar ngang + text. Chiếm width trong modal 560px. | |

**User's choice:** Circular progress
**Notes:** Visual feedback rõ ràng nhất cho user đang chờ xác nhận OTP mobile.

---

## Root CA banner trigger + dismiss scope

| Option | Description | Selected |
|--------|-------------|----------|
| Trigger sau download MySign + localStorage per-browser (Recommended) | Banner xuất hiện trong `/ky-so/danh-sach` khi user click Tải lần đầu + provider=MySign. Dismiss lưu localStorage. | ✓ |
| Banner cố định tại page nếu provider=MySign | Proactive hơn nhưng spam user chưa ký. | |
| Modal popup thay banner | Intrusive, dismiss DB. | |

**User's choice:** Trigger sau download + localStorage
**Notes:** Không intrusive, đúng mô tả UX-11.

---

## Bell notification scope

| Option | Description | Selected |
|--------|-------------|----------|
| Chỉ SIGN_COMPLETED + SIGN_FAILED (Recommended) | Giữ scope Phase 13 đúng UX-10. Infrastructure sẵn sàng extend sau. | ✓ |
| Mở rộng 3-4 event: sign + VB đến mới + HSCV gán | Scope creep, kéo dài Phase 13 thêm 2-3 plan. | |

**User's choice:** Chỉ sign events
**Notes:** Tránh scope creep, infrastructure generic notification có thể Phase 15+ mở rộng.

---

## Claude's Discretion

Các quyết định Claude tự handle trong Phase 13:
- Exact wording tiếng Việt cho toast/banner/empty state
- Header bell icon spacing + placement chi tiết
- Dropdown max-height + scroll behavior
- Toast position
- Circular progress size/stroke width/animation
- Color thresholds countdown: >60s xanh, 30-60s vàng, <30s đỏ
- Retention cleanup cron — defer, document trong SUMMARY.md

## Deferred Ideas

Ghi nhận trong `<deferred>` của CONTEXT.md:
- Phase 14: MinIO prod config, audit log Mongo, rate limit, cron cleanup notif, DEP-03 HDSD
- Sau v2.0: generic notification types, /thong-bao page, notification settings per user, SigningModal legacy cleanup
- Nice-to-have: Web Push, dashboard widget, mute per VB
