# Phase 5: Kho lưu trữ, Tài liệu & Họp - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 05-kho-luu-tru-tai-lieu-hop
**Areas discussed:** Kho lưu trữ & Mượn/trả, Tài liệu & Hợp đồng, Họp không giấy, Database & API chung

---

## Kho lưu trữ & Mượn/trả

### Cấu trúc Kho/Phông

| Option | Description | Selected |
|--------|-------------|----------|
| Kho → Phông (2 cấp) | Kho chứa nhiều Phông. Hồ sơ thuộc Phông. | |
| Tree nhiều cấp | Kho → Phông → Hộp → Cặp... không giới hạn cấp | |
| Theo source cũ | Xem source code cũ (.NET) để áp dụng đúng cấu trúc | ✓ |

**User's choice:** Theo source cũ
**Notes:** User yêu cầu toàn bộ nghiệp vụ kho lưu trữ phải tham chiếu source code cũ.

### Luồng mượn/trả

| Option | Description | Selected |
|--------|-------------|----------|
| Tạo yêu cầu → Duyệt → Trả | Flow cơ bản có deadline | |
| Theo source cũ | Xem source code cũ để áp dụng đúng luồng | ✓ |
| Claude quyết định | Claude tham khảo source cũ + bổ sung | |

**User's choice:** Theo source cũ

---

## Tài liệu & Hợp đồng

### Danh mục tài liệu

| Option | Description | Selected |
|--------|-------------|----------|
| Danh mục cố định | Đào tạo, Nội bộ, ISO... admin cấu hình | |
| Tree phân cấp | Danh mục là tree nhiều cấp | |
| Theo source cũ | Xem source code cũ để áp dụng | ✓ |

**User's choice:** Theo source cũ

### Quản lý hợp đồng

| Option | Description | Selected |
|--------|-------------|----------|
| Chỉ CRUD + upload | Không có flow duyệt | |
| CRUD + luồng duyệt | Có workflow trạng thái | |
| Theo source cũ | Xem source code cũ để áp dụng | ✓ |

**User's choice:** Theo source cũ

---

## Họp không giấy

### Biểu quyết realtime

| Option | Description | Selected |
|--------|-------------|----------|
| Y/N đơn giản | Đồng ý / Không đồng ý | |
| Nhiều lựa chọn | A/B/C/D với % và chart | |
| Theo source cũ | Xem source code cũ để áp dụng | ✓ |

**User's choice:** Theo source cũ

### Thống kê chart

| Option | Description | Selected |
|--------|-------------|----------|
| Ant Design Charts | @ant-design/charts, thống nhất ecosystem | ✓ |
| Recharts | Thư viện phổ biến, nhẹ | |
| Claude quyết định | Claude chọn phù hợp nhất | |

**User's choice:** Ant Design Charts

---

## Database & API chung

### Schema

| Option | Description | Selected |
|--------|-------------|----------|
| Schema riêng | esto, cont, edoc theo kế hoạch | |
| Tất cả vào edoc | Đơn giản hơn | |
| Theo source cũ | Xem source code cũ | ✓ |

**User's choice:** Theo source cũ

### Quy ước tên trường

| Option | Description | Selected |
|--------|-------------|----------|
| SP trả đúng tên cột DB | Không rename/alias | |
| Kiểm tra chéo SP ↔ frontend | Verify interface khớp | |
| Cả hai | SP đúng tên + kiểm tra chéo | ✓ |

**User's choice:** Cả hai — SP trả đúng tên cột DB + kiểm tra chéo tên trường

---

## Additional Notes (from user)

1. **Tham chiếu source code cũ (.NET)** là yêu cầu BẮT BUỘC cho mọi module, không phải optional.
2. **Sprint 4 mắc nhiều lỗi** do tên trường không thống nhất — cần quy ước nghiêm ngặt hơn.
3. **Chú ý quy tắc mới** về font (Inter), size, màu sắc từ hôm nay.
4. **Tích hợp Phase 1-4** — các chức năng mới phải liên kết với code đã có, không hoạt động cô lập.

## Claude's Discretion

- Chi tiết UI layout (table columns, drawer fields)
- Cách tích hợp cụ thể giữa modules
- Ant Design Charts configuration

## Deferred Ideas

None — discussion stayed within phase scope
