# Phase 32: Audit & cập nhật toàn bộ HDSD - Context

**Gathered:** 2026-05-11
**Status:** Ready for planning
**Source:** Direct context capture from chat session (gap analysis + code references)

<domain>
## Phase Boundary

Phase này thuần **tài liệu** — KHÔNG đụng code production, KHÔNG migrate DB, KHÔNG đụng schema.

**Input:** 16 file HDSD .md hiện có (~4400 dòng tổng, đã merge thành `HDSD_full.md`) + ~50 screenshots cũ trong `docs/hdsd/screenshots/`.

**Process:** Đối chiếu từng file HDSD với code hiện tại (sau Phase 21 LGSP foundation + Phase 31 fix-gom UI), bổ sung mô tả nghiệp vụ còn thiếu, đồng bộ button/menu/field theo UI mới. Chụp lại screenshots bằng Playwright. Merge thành `HDSD_full.md` + export `HDSD_full.docx`.

**Output:**
- 16 file `docs/hdsd/HDSD_*.md` updated
- Screenshots mới trong `docs/hdsd/screenshots/` (thay ảnh cũ cùng tên)
- `docs/hdsd/HDSD_full.md` merged
- `docs/hdsd/HDSD_full.docx` exported với ảnh embedded
- 1 commit duy nhất `docs(32): audit + update toàn bộ HDSD + screenshots + export docx`

**Out of scope:**
- Fix code (vd: thêm notification bell cho VB đi giao việc — sẽ là backlog v3.2)
- Tạo HDSD cho module mới chưa có
- Translate HDSD sang tiếng Anh

</domain>

<decisions>
## Implementation Decisions

### Scope audit (locked)

- **16 module HDSD đầy đủ:**
  1. `HDSD_dang_nhap_va_thong_tin_ca_nhan.md`
  2. `HDSD_dashboard.md`
  3. `HDSD_van_ban_den.md`
  4. `HDSD_van_ban_di.md`
  5. `HDSD_van_ban_du_thao.md`
  6. `HDSD_van_ban_danh_dau.md`
  7. `HDSD_ho_so_cong_viec.md`
  8. `HDSD_thong_bao.md`
  9. `HDSD_cau_hinh_gui_nhanh.md`
  10. `HDSD_ky_so_cau_hinh.md`
  11. `HDSD_ky_so_danh_sach.md`
  12. `HDSD_ky_so_tai_khoan.md`
  13. `HDSD_quan_tri_don_vi.md`
  14. `HDSD_quan_tri_chuc_vu.md`
  15. `HDSD_quan_tri_nguoi_dung.md`
  16. `HDSD_quan_tri_nhom_quyen.md`
  17. `HDSD_quan_tri_so_van_ban.md`
  18. `HDSD_quan_tri_linh_vuc.md`
  19. `HDSD_quan_tri_loai_van_ban.md`
  20. `HDSD_quan_tri_nguoi_ky.md`
  21. `HDSD_index.md` (index)

Note: Đếm 20 file thực tế trong `docs/hdsd/`, "16 module" trong roadmap = ước lượng ban đầu. Plan phải xử lý đủ 20 file.

### Gap bắt buộc bổ sung (locked — tester đã hỏi)

**GAP 1 — HDSD_van_ban_den.md mục 3.6 (Drawer giao việc):**
- Hiện tại chỉ ghi "Tạo hồ sơ công việc, gửi thông báo cho người phụ trách, đóng Drawer".
- THIẾU: Mô tả cụ thể HSCV xuất hiện ở đâu của TK được giao (trang Hồ sơ công việc, tab "Mới tạo", status=0), có chuông bell hay không (CÓ — `task_assigned`).
- BỔ SUNG subsection mới: **"Sau khi giao việc — văn bản xuất hiện ở đâu?"**.

**GAP 2 — HDSD_van_ban_di.md mục 3.8 (Drawer giao việc):**
- Hiện tại chỉ ghi "Tạo hồ sơ công việc từ văn bản đi" + form fields đánh "Không bắt buộc" cho 4/5 trường.
- THIẾU: Mô tả nghiệp vụ hậu quả, lưu ý KHÔNG có chuông bell (gap code chưa fix), KHÔNG validate `Người phụ trách` rỗng + `Hạn hoàn thành`.
- BỔ SUNG subsection: **"Sau khi giao việc — văn bản xuất hiện ở đâu?"** + note gap.

**GAP 3 — HDSD_van_ban_di.md mục 3.7 (Modal Ban hành & Gửi):**
- Hiện tại chỉ tả UI Modal + 3 thông báo.
- THIẾU: Luồng kỹ thuật 3 bước khi Gửi:
  1. Lưu recipients (`outgoing_doc_recipients`, status `pending`)
  2. Ban hành cấp số (`is_released=true`)
  3. Gửi loop từng recipient:
     - **Internal** → INSERT vào `incoming_docs` của đơn vị nhận, status "Chưa duyệt", người nhận thấy ở trang VB đến NGAY.
     - **External LGSP** → INSERT `lgsp_tracking` status `pending`, queue worker BullMQ `lgsp-send`, badge "Đang chờ worker đẩy LGSP" hiển thị trên UI.
- BỔ SUNG subsection: **"Luồng kỹ thuật khi Gửi"**.

### Diff scope audit cho 16+ module (mỗi file)

Mỗi file HDSD phải đối chiếu với code hiện tại 5 chiều:
1. **Button/menu mới hoặc đổi tên** (Phase 31 fix-gom UI đã đụng nhiều)
2. **Field form mới hoặc đổi maxLength** (Phase 21+ schema v3.0)
3. **Workflow nghiệp vụ thay đổi** (đặc biệt LGSP routes Phase 18+)
4. **Notification/thông báo mới** (`task_assigned`, LGSP tracking events)
5. **Hidden routes** — file `frontend/src/config/hidden-routes.ts` mới có 44 dòng (Phase 31), HDSD phải tả các route bị ẩn cho ai

### Screenshots (locked)

- Dùng **Playwright** (đã có infra `tests/wave-31c-ui/` + `tools/screenshots/capture-*.js`).
- Capture từ **frontend dev server đang chạy localhost:3000** (yêu cầu backend localhost:4000 cũng chạy).
- Login bằng các test accounts trong `seed/002_demo_data.sql`: `admin/Admin@123`, `nguyenvana/Admin@123` (Sở Nội vụ), `tranthib/Admin@123` (Sở Tài chính), v.v.
- Save vào `docs/hdsd/screenshots/<tên_cũ>.png` (overwrite ảnh cũ để giữ link MD không vỡ).
- Định dạng: PNG, viewport 1440x900 hoặc 1920x1080 (theo ảnh hiện tại — kiểm tra ảnh đầu tiên).
- KHÔNG ghi tên cá nhân nhạy cảm trong screenshot (dùng test accounts demo).

### Merge HDSD_full.md (locked)

- File `docs/hdsd/HDSD_full.md` (4424 dòng hiện tại) đã có sẵn — phải re-merge từ các file con sau khi update.
- Thứ tự merge theo `HDSD_index.md`.
- Adjust relative path screenshots (file_con dùng `screenshots/xxx.png` → trong full vẫn `screenshots/xxx.png` vì cùng dir).

### Export HDSD_full.docx (locked)

- Tool: pandoc 3.9.0.2 (đã có ở `/c/Users/Admin/AppData/Local/Pandoc/pandoc`).
- Command pattern: `pandoc docs/hdsd/HDSD_full.md -o docs/hdsd/HDSD_full.docx --reference-doc=tools/screenshots/reference.docx --resource-path=docs/hdsd`
- Reference docx: `tools/screenshots/reference.docx` (đã có, generate bởi `generate-reference-docx.js`).
- Ảnh embedded: pandoc tự inline khi gặp `![](screenshots/xxx.png)` nếu `--resource-path` đúng.
- Output: `docs/hdsd/HDSD_full.docx` (overwrite file cũ — đã có file `HDSD_full.docx` 800KB).

### Wave structure (locked)

**Wave 1 — Audit + write/update text (TUẦN TỰ):**
- Audit tất cả 20 file một lượt (1 plan), output: AUDIT_REPORT.md liệt kê diff/gap cho mỗi file.
- Update từng file theo audit report (chia 4 plan parallel để giảm thời gian):
  - Plan A: VB (đến, đi, dự thảo, đánh dấu) — 4 file phức tạp nhất, ~1370 dòng
  - Plan B: HSCV + Dashboard + Thông báo + Cấu hình gửi nhanh — 4 file, ~1180 dòng
  - Plan C: Ký số (3 file) + Đăng nhập + Index — 5 file, ~770 dòng
  - Plan D: Quản trị (8 file: đơn vị, chức vụ, người dùng, nhóm quyền, sổ VB, lĩnh vực, loại VB, người ký) — 8 file, ~1100 dòng

**Wave 2 — Screenshots (depends on Wave 1 text):**
- Chụp lại screenshots Playwright (1 plan) sau khi text settle.
- Vì khi đổi text có thể đổi label trong UI → chụp sau khi text + code đồng bộ.

**Wave 3 — Merge + Export (depends on Wave 2):**
- Re-merge `HDSD_full.md` (1 plan)
- Export `HDSD_full.docx` qua pandoc (1 plan)

### Claude's Discretion

- Format tone của HDSD: giữ nguyên giọng của bản hiện tại (formal, ngắn gọn, bảng nhiều).
- Có thêm icon/emoji không: KHÔNG (theo CLAUDE.md global "Only use emojis if the user explicitly requests").
- Cấu trúc heading: giữ pattern `## 1. Giới thiệu` / `## 2. Quy trình nghiệp vụ` / `## 3. Các màn hình chức năng` / `### 3.X. Màn hình ABC` đang dùng.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### HDSD files (audit target)
- `docs/hdsd/HDSD_index.md` — Mục lục toàn bộ HDSD, thứ tự merge HDSD_full.md
- `docs/hdsd/HDSD_full.md` — Bản merged hiện tại (4424 dòng), reference cấu trúc cuối cùng
- `docs/hdsd/HDSD_van_ban_den.md` — Module VB đến (cần bổ sung subsection 3.6)
- `docs/hdsd/HDSD_van_ban_di.md` — Module VB đi (cần bổ sung subsection 3.7 + 3.8)
- `docs/hdsd/HDSD_ho_so_cong_viec.md` — Module HSCV (cần bổ sung note về "VB tự xuất hiện ở tab Mới tạo khi được giao việc")

### Code references (audit source-of-truth)
- `e_office_app_new/backend/src/routes/incoming-doc.ts` line 909-973 — Giao việc VB đến (có notifyBell)
- `e_office_app_new/backend/src/routes/outgoing-doc.ts` line 651-719 — Ban hành + Set recipients + Gửi (3 SP)
- `e_office_app_new/backend/src/routes/outgoing-doc.ts` line 899-926 — Giao việc VB đi (KHÔNG có notifyBell — gap)
- `e_office_app_new/database/schema/000_schema_v3.0.sql` line 3414-3468 — SP `fn_handling_doc_create_from_doc`
- `e_office_app_new/database/schema/000_schema_v3.0.sql` line 27846-27948 — SP `fn_outgoing_doc_send_to_recipients`
- `e_office_app_new/workers/src/index.ts` line 210-243 — Worker LGSP send
- `e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx` line 182-202 — Drawer Giao việc VB đến
- `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx` line 204-217, 336-357, 495 — Drawer Giao việc + handler "Ban hành & Gửi" VB đi
- `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/page.tsx` — Trang HSCV, nơi VB hiển thị sau khi giao
- `e_office_app_new/frontend/src/config/hidden-routes.ts` — Routes ẩn theo role (Phase 31 mới)
- `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` — Menu sidebar (đổi nhiều ở Phase 31)

### Infra references
- `tools/screenshots/capture-all-rev3-fix5.js` — Latest Playwright capture script
- `tools/screenshots/capture-detail3.js` — Detail page capture
- `tools/screenshots/generate-reference-docx.js` — Reference docx template generator
- `tools/screenshots/merge-and-export.js` — Existing merge+export pipeline (kiểm tra logic trước, có thể reuse)
- `tools/screenshots/reference.docx` — Pandoc reference style template
- `tools/screenshots/package.json` — Có node_modules sẵn (Playwright + dependencies)

### Test accounts (seed/002_demo_data.sql)
- `admin / Admin@123` — Quản trị Hệ thống
- `nguyenvana / Admin@123` — Sở Nội vụ
- `tranthib / Admin@123` — Sở Tài chính
- `levand / Admin@123` — Sở TT&TT

### Project guidelines
- `CLAUDE.md` (root) — Phase Execution Rules, naming conventions, deploy pitfalls
- `~/.claude/CLAUDE.md` (user global) — Design philosophy, color/typography

</canonical_refs>

<specifics>
## Specific Examples

### Exact text bổ sung cho GAP 1 (HDSD_van_ban_den.md mục 3.6)

Sau bảng "Thông báo của hệ thống" hiện tại (line 296), thêm:

```markdown
#### Sau khi giao việc — văn bản xuất hiện ở đâu của TK được giao?

Khi bấm "Tạo và giao việc", hệ thống tạo một Hồ sơ công việc (HSCV) mới và liên kết với văn bản đến này:

1. **TK được chọn làm Người phụ trách** sẽ nhận:
   - **Chuông thông báo** (góc trên màn hình) với nội dung "Bạn vừa được giao việc..." — bấm vào điều hướng sang HSCV chi tiết.
   - HSCV mới xuất hiện ở trang **Hồ sơ công việc** (menu trái), tab **"Mới tạo"** (status mặc định khi giao việc).

2. **Vào chi tiết HSCV**, người được giao thấy:
   - Thông tin HSCV (tên, ngày bắt đầu, hạn, ghi chú, người phụ trách)
   - Văn bản đến nguồn được link sẵn — bấm để mở chi tiết văn bản

3. **Văn bản đến** vẫn nằm ở trang VB đến cũ của người tiếp nhận ban đầu (lãnh đạo) — KHÔNG bị chuyển đi.
```

### Exact text bổ sung cho GAP 3 (HDSD_van_ban_di.md mục 3.7)

Sau bảng "Thông báo của hệ thống" hiện tại (line 309), thêm:

```markdown
#### Luồng kỹ thuật khi Gửi (3 bước nối tiếp)

Khi bấm nút "Ban hành & Gửi" hoặc "Gửi" trong modal, hệ thống thực hiện 3 bước nối tiếp:

**Bước 1 — Lưu danh sách đơn vị nhận:**
- Mỗi đơn vị/cơ quan được chọn được lưu thành 1 dòng trong bảng `outgoing_doc_recipients` với `sent_status='pending'`.
- Phân loại: `internal_unit` (đơn vị trong tỉnh) hoặc `external_org` (cơ quan ngoài tỉnh — gửi qua LGSP).

**Bước 2 — Ban hành cấp số:**
- Hệ thống cấp số văn bản đi chính thức và đánh dấu `is_released = TRUE`.
- Trạng thái văn bản đi chuyển sang **"Đã ban hành"**.

**Bước 3 — Gửi (loop từng recipient):**

- **Nếu là đơn vị Nội bộ:** Hệ thống tự sinh 1 Văn bản đến cho đơn vị nhận:
  - Văn bản đến nằm ngay ở trang **Văn bản đến** của đơn vị nhận, trạng thái "Chưa duyệt".
  - Người nhận có thể đăng nhập và xử lý ngay (duyệt → giao việc → ban hành công văn trả lời...).
  - Số văn bản đến được cấp tự động theo sổ của đơn vị nhận.

- **Nếu là cơ quan ngoài LGSP:** Hệ thống tạo bản ghi trong `lgsp_tracking` (trạng thái `pending`):
  - Badge **"Đang chờ worker đẩy LGSP"** hiển thị ở khung "Đơn vị / Cơ quan nhận" trên trang chi tiết.
  - Worker BullMQ (`lgsp-send`) sẽ pick lên, gọi API LGSP thật (apiltvb.langson.gov.vn), update trạng thái → `success` / `error`.
  - Khi worker xong, badge đổi thành **"Đã gửi LGSP"** hoặc **"Lỗi gửi LGSP"** (kèm thông báo lỗi).

Trạng thái cuối cùng của văn bản đi: **"Đã gửi"** (nội bộ done ngay, LGSP đợi worker).
```

</specifics>

<deferred>
## Deferred Ideas

- **Fix code gap VB đi Giao việc không có chuông bell** → backlog v3.2 (đã note trong HDSD: "Lưu ý: hiện tại VB đi giao việc chưa có chuông thông báo — sẽ bổ sung ở phiên bản sau").
- **Fix validation Người phụ trách + Hạn hoàn thành rỗng** → backlog v3.2.
- **Translate HDSD sang tiếng Anh** → Không trong scope.
- **Tạo video HDSD** → Không trong scope.
- **Generate PDF với mục lục tự động** → Không trong scope (chỉ docx).

</deferred>

---

*Phase: 32-hdsd-audit-update*
*Context gathered: 2026-05-11 from chat session (gap analysis + code references from Agent search)*
