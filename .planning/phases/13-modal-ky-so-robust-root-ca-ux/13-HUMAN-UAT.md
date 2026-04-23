---
status: partial
phase: 13-modal-ky-so-robust-root-ca-ux
source: [13-05-e2e-uat-checkpoint-SUMMARY.md]
started: 2026-04-23T14:15:00Z
updated: 2026-04-23T14:45:00Z
blocker: Chưa tích hợp hệ thống ký số thật (SmartCA VNPT + MySign Viettel) — các TC phụ thuộc OTP flow runtime không test được trên máy cá nhân dev.
---

## Current Test

[awaiting real signing integration — unblock TC1-TC4]

## Tests

### 1. Spam click button "Ký số" caller (tab Cần ký)
expected: Button disable ngay lần click đầu tiên, không tạo duplicate sign_transaction. Hook useSigning guard `if (open) return` + caller disabled prop `signModalOpen`.
result: pending
evidence_built: Grep verified `disabled={signModalOpen}` × 2 trong columns (Ký số + Ký lại) tại `ky-so/danh-sach/page.tsx`. `useSigning.openSign` có functional setState guard (stale-closure safe). Logic code correct, chưa test runtime vì flow phải mở modal thật.

### 2. Modal ký số countdown 3:00 + 3 màu + expired transition
expected: Circular Progress 3:00 → 0:00 tick realtime. Màu: `#1B3A5C` khi >60s → `#D97706` 30-60s → `#DC2626` <30s. Khi 0:00 → state `expired` + Alert error "Hết thời gian chờ xác nhận OTP".
result: pending
evidence_built: Grep verified `Progress type="circle" size={120}` + 3 color hex trong SignModal. `COUNTDOWN_MS=180_000`, `countdownColor` helper, `expiredFired` useRef guard chống double-set. Chỉ test được khi có provider OTP thật phản hồi.

### 3. Modal pending → click "Đóng (chạy nền)"
expected: Modal close, transaction giữ status=pending, flow worker polling tiếp, khi BE emit SIGN_COMPLETED/FAILED thì bell notification xuất hiện.
result: pending
evidence_built: 2 button pending state code correct (type=default cho "Đóng chạy nền", type=default danger cho "Hủy ký số"). Worker persist notification BEFORE socket.emit (verified Plan 13-01).

### 4. Modal pending → click "Hủy ký số"
expected: Modal close, POST /api/ky-so/sign/:id/cancel → transaction mark cancelled. User thấy trong tab "Thất bại" với status "Đã hủy giao dịch".
result: pending
evidence_built: Button "Hủy ký số" có `type="default" danger icon={<CloseOutlined />}` + onClick → cancel API. Backend API đã có từ Phase 11.

### 5. Bell icon dropdown + mark all read
expected: Badge hiện số unread (seed = 5 cho admin staff_id=1). Click bell → dropdown 5 item gần nhất (icon status + title + message + relative time vi locale). Click "Đánh dấu đã đọc tất cả" → PATCH /api/notifications/read-all → badge về 0.
result: passed
note: Verified trên browser — badge 5, dropdown hiển thị đúng 5 item từ seed data. 2 hệ thống notification tách biệt (bell `public.notifications` Phase 13 vs sidebar `/thong-bao` legacy `edoc.notification_logs`) — không lẫn lộn, không ảnh hưởng badge nhau.

### 6. Root CA banner trigger trên trang Danh sách ký số
expected: Banner info luôn hiển thị dưới page header, trên card tabs, với 2 button "Tải Root CA (.cer)" + "Xem hướng dẫn (PDF)". Bỏ trigger conditional per feedback UAT.
result: passed
note: **Spec drift (override D-22..D-26):** Ban đầu spec trigger chỉ khi click "Tải file đã ký" MYSIGN_VIETTEL lần đầu + có nút X dismiss + localStorage track. UAT feedback: user muốn banner LUÔN hiển thị để có thể tải HDSD bất cứ lúc nào (đổi máy/browser/forget cách cài). Commit 837cc0e bỏ conditional trigger + bỏ X close + bỏ localStorage — banner mount không điều kiện.

### 7. Dismiss banner + reload
expected: Click X đóng banner → localStorage.dismiss_root_ca_banner=true → reload trang banner KHÔNG hiện lại. Clear localStorage + download lại → banner hiện lại.
result: skipped
note: **Không áp dụng nữa** sau spec override TC6. Banner luôn visible, không dismiss được. Decision D-25/D-26 deprecated.

## Summary

total: 7
passed: 2
issues: 0
pending: 4
skipped: 1
blocked: 0

## Gaps

### Gap 1: Ký số runtime flow chưa test được (TC1-TC4)
status: failed
reason: Chưa tích hợp hệ thống ký số thật (MySign Viettel API SDK chưa triển khai server production, SmartCA VNPT chưa có credentials). UAT các flow spam-click / countdown / 2 button / cancel yêu cầu provider phản hồi OTP thật.
impact: Không thể verify end-to-end UX nhưng logic code đã implemented + verified qua grep + build. Khi production có real integration → re-run `/gsd-verify-work 13` để clear các TC này.
blocker_for: Production release milestone v2.0 — cần integration test 4 TC trước khi go-live.
