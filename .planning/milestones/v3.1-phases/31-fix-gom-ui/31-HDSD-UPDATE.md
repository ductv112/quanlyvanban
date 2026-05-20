# Phase 31 — HDSD Update (Hide 9 modules + 9 admin items)

**Date:** 2026-05-09
**Trigger:** Frontend `HIDDEN_ROUTES` set ẩn 9 phân hệ + 9 mục Quản trị khỏi sidebar/dashboard. Cần đối chiếu HDSD đảm bảo tài liệu KH thấy không mô tả module ẩn.

---

## 1. Tóm tắt kết quả

**Audit-only — KHÔNG có thay đổi nào cần áp dụng.**

Sau khi rà soát toàn bộ 22 file `docs/hdsd/*.md`, kết luận: bộ HDSD HIỆN TẠI **đã align hoàn toàn** với `HIDDEN_ROUTES` — tất cả 9 phân hệ ẩn (Tin nhắn, Lịch, Danh bạ, Kho lưu trữ, Tài liệu, Hợp đồng, Cuộc họp, LGSP-cơ-quan, Kênh thông báo) và 9 mục Quản trị ẩn (chức năng, cấu hình trường, cơ quan, nhóm làm việc, ủy quyền, địa bàn, lịch làm việc, mẫu thông báo, cấu hình hệ thống) đã KHÔNG còn xuất hiện trong tài liệu.

Điều này phản ánh kết quả của các đợt cập nhật HDSD trước đó (commit `06ff467` "bo refs module tam an + chup du 82 screenshots cho 98 man hinh con" và `9ec30a4` "them ban HDSD final V2 da format gui KH").

---

## 2. Số dòng thay đổi mỗi file

| File | Trước | Sau | Diff |
|---|---:|---:|---:|
| `docs/hdsd/HDSD_full.md` | 4424 | 4424 | 0 |
| `docs/hdsd/HDSD_index.md` | 129 | 129 | 0 |
| `docs/hdsd/HDSD_dashboard.md` | 123 | 123 | 0 |

---

## 3. Section headings đã xóa

**Không có.** Cấu trúc heading hiện tại của `HDSD_full.md`:

```
Phần mở đầu (mục 1-6: giới thiệu, đăng nhập, bố cục, vai trò, quy ước, liên hệ)
Phần I — Chi tiết các chức năng:
  1. Đăng nhập và Thông tin cá nhân
  2. Tổng quan (Dashboard)
  3. Thông báo nội bộ
  4. Văn bản đến
  5. Văn bản đi
  6. Văn bản dự thảo
  7. Đánh dấu cá nhân
  8. Cấu hình gửi nhanh
  9. Hồ sơ công việc
 10. Cấu hình ký số hệ thống
 11. Tài khoản ký số cá nhân
 12. Danh sách ký số
 13. Quản trị đơn vị
 14. Quản trị chức vụ
 15. Quản trị người dùng
 16. Quản trị nhóm quyền
 17. Quản lý sổ văn bản
 18. Quản lý loại văn bản
 19. Quản lý lĩnh vực
 20. Quản lý người ký
```

20 mục — khớp 1-1 với `HDSD_index.md` (mục 5.1-5.6 liệt kê 22 dòng tài liệu, gồm 2 dòng "Hồ sơ công việc" tách Danh sách + Chi tiết + Báo cáo trong index nhưng gộp vào HDSD_full).

---

## 4. Dashboard đã align

**`HDSD_full.md` mục 2.3.1 (Tổng quan)** và **`HDSD_dashboard.md` mục 3.1**:

- Dòng mô tả Khu vực 1: *"6 thẻ thống kê màu sắc khác nhau"* — đã đúng số (không phải 8).
- Bảng "Các nút chức năng" liệt kê đúng 6 thẻ:
  1. VB đến chưa đọc → Văn bản đến
  2. VB đi chờ duyệt → Văn bản đi
  3. Hồ sơ công việc → Hồ sơ công việc
  4. Việc quá hạn → Hồ sơ công việc
  5. Dự thảo chờ phát hành → Văn bản dự thảo
  6. Thông báo chưa đọc → Thông báo nội bộ
- Bảng "Các trường dữ liệu — Bảng thẻ thống kê" liệt kê đúng 6 dòng.
- KHÔNG còn dòng nào cho "Tin nhắn chưa đọc" hay "Lịch họp hôm nay".

(Các tài liệu hiện dùng thuật ngữ *"thẻ thống kê"* thay vì *"thẻ KPI"* — về số lượng (6) đã chính xác. Thuật ngữ này thống nhất xuyên suốt 2 file dashboard, giữ nguyên để tránh inconsistency với 4 vị trí khác nhau cùng dùng "thẻ thống kê".)

---

## 5. Index đã align

**`HDSD_index.md` mục 5 (Mục lục)** chỉ có 6 nhóm — tất cả trỏ đến module **đang active**:

- 5.1 Tổng quan và cá nhân (3 mục: đăng nhập, dashboard, thông báo)
- 5.2 Văn bản (5 mục: VB đến, VB đi, dự thảo, đánh dấu, cấu hình gửi nhanh)
- 5.3 Hồ sơ công việc (3 mục: danh sách, chi tiết, báo cáo)
- 5.4 Ký số (3 mục: cấu hình, tài khoản, danh sách)
- 5.5 Quản trị hệ thống (4 mục: đơn vị, chức vụ, người dùng, nhóm quyền)
- 5.6 Danh mục (4 mục: sổ vb, loại vb, lĩnh vực, người ký)

Tổng 22 link tài liệu — không có link nào trỏ đến module ẩn (Tin nhắn, Lịch, Danh bạ, Kho lưu trữ, Tài liệu, Hợp đồng, Cuộc họp, LGSP-cơ-quan, Kênh thông báo, hoặc 9 mục Quản trị ẩn).

---

## 6. Cross-reference & encoding

- Tìm kiếm regex toàn thư mục `docs/hdsd/` cho 30+ keyword/route ẩn → **0 match**.
- Tìm kiếm pattern `HDSD_(tin_nhan|lich|danh_ba|kho_luu_tru|tai_lieu|hop_dong|cuoc_hop|lgsp|thong_bao_kenh|chuc_nang|cau_hinh_truong|co_quan|nhom_lam_viec|uy_quyen|dia_ban|lich_lam_viec|mau_thong_bao|cau_hinh)` → chỉ 1 false-positive trên `HDSD_cau_hinh_gui_nhanh.md` (Cấu hình gửi nhanh — module ACTIVE, khác với "cấu hình hệ thống" ẩn).
- Các đề cập đến **LGSP** trong `HDSD_full.md` (line 8, 542-561, 658-671, 884-903, 918-944, 1046, 1119-1121) — giữ nguyên vì LGSP là **kênh tích hợp** trong VB đến/VB đi (active), không phải module standalone ẩn `/lgsp/co-quan`.

---

## 7. Mục lục TOC

`HDSD_full.md` không có TOC tự động (markdown thuần, không front-matter). `HDSD_index.md` đóng vai trò TOC tổng — đã align.

---

## 8. Khuyến nghị

- **KHÔNG cần re-export `.docx`** vì nội dung markdown không đổi.
- Khi Phase 2 bật lại các module ẩn, cần:
  1. Thêm section mới vào `HDSD_full.md` (theo format mục 1-20).
  2. Thêm dòng tương ứng vào `HDSD_index.md` mục 5.x.
  3. Tạo file `HDSD_<module>.md` riêng cho module đó.
- Khi thêm card mới vào dashboard frontend (vd: nâng từ 6 lên 8 cards), cập nhật:
  - `HDSD_full.md` line 274 (số "6") + bảng nút line 283-297 + bảng trường dữ liệu line 301-310.
  - `HDSD_dashboard.md` line 40 (số "6") + bảng nút line 49-63 + bảng trường dữ liệu line 67-76.

---

## 9. Files audited

| File | Outcome |
|---|---|
| `docs/hdsd/HDSD_full.md` | Clean — 20 sections active modules only |
| `docs/hdsd/HDSD_index.md` | Clean — 22 links to active modules only |
| `docs/hdsd/HDSD_dashboard.md` | Clean — 6 cards, no hidden card refs |
| `docs/hdsd/HDSD_dang_nhap_va_thong_tin_ca_nhan.md` | Clean (no hidden refs) |
| `docs/hdsd/HDSD_thong_bao.md` | Clean |
| `docs/hdsd/HDSD_van_ban_den.md` | Clean (LGSP only as integration source) |
| `docs/hdsd/HDSD_van_ban_di.md` | Clean (LGSP only as integration target) |
| `docs/hdsd/HDSD_van_ban_du_thao.md` | Clean |
| `docs/hdsd/HDSD_van_ban_danh_dau.md` | Clean |
| `docs/hdsd/HDSD_cau_hinh_gui_nhanh.md` | Clean |
| `docs/hdsd/HDSD_ho_so_cong_viec.md` | Clean |
| `docs/hdsd/HDSD_ky_so_cau_hinh.md` | Clean |
| `docs/hdsd/HDSD_ky_so_tai_khoan.md` | Clean |
| `docs/hdsd/HDSD_ky_so_danh_sach.md` | Clean |
| `docs/hdsd/HDSD_quan_tri_don_vi.md` | Clean |
| `docs/hdsd/HDSD_quan_tri_chuc_vu.md` | Clean |
| `docs/hdsd/HDSD_quan_tri_nguoi_dung.md` | Clean |
| `docs/hdsd/HDSD_quan_tri_nhom_quyen.md` | Clean |
| `docs/hdsd/HDSD_quan_tri_so_van_ban.md` | Clean |
| `docs/hdsd/HDSD_quan_tri_loai_van_ban.md` | Clean |
| `docs/hdsd/HDSD_quan_tri_linh_vuc.md` | Clean |
| `docs/hdsd/HDSD_quan_tri_nguoi_ky.md` | Clean |

---

**Verdict:** Tài liệu HDSD đã sẵn sàng cho demo KH cuối tuần — không có nội dung mô tả module ẩn nào lọt qua.
