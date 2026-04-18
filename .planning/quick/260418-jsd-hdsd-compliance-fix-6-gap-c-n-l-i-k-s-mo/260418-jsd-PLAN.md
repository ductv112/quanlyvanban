---
phase: quick-260418-jsd
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: true
requirements: [HDSD-I.5, HDSD-II.3.8, HDSD-II.3.9, HDSD-III.2.5, HDSD-III.2.6, HDSD-III.2.7, HDSD-TC]
files_modified:
  # Task 1 — Gap A (TC-011) Ký số mock OTP VB đi + VB dự thảo
  - e_office_app_new/database/migrations/quick_260418_jsd_sign_otp.sql
  - e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts
  - e_office_app_new/backend/src/repositories/drafting-doc.repository.ts
  - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
  - e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx

  # Task 2 — Gap B (TC-045) Gửi trục CP mock
  - e_office_app_new/database/migrations/quick_260418_jsd_truc_cp.sql
  - e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts
  - e_office_app_new/backend/src/routes/outgoing-doc.ts
  - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx

  # Task 3 — Gap C (TC-046) Chuyển lưu trữ VB đi — mở rộng form + backend endpoints lưu trữ
  - e_office_app_new/backend/src/routes/outgoing-doc.ts
  - e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx

  # Task 4 — Gap D (TC-066) Hủy HSCV action riêng với lý do
  - e_office_app_new/database/migrations/quick_260418_jsd_hscv_cancel.sql
  - e_office_app_new/backend/src/repositories/handling-doc.repository.ts
  - e_office_app_new/backend/src/routes/handling-doc.ts
  - e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx

  # Task 5 — Gap E (TC-067) Chuyển tiếp ý kiến HSCV + staff picker endpoint mới
  - e_office_app_new/database/migrations/quick_260418_jsd_opinion_forward.sql
  - e_office_app_new/backend/src/repositories/handling-doc.repository.ts
  - e_office_app_new/backend/src/routes/handling-doc.ts
  - e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx

  # Task 6 — Gap F (TC-068) Chuyển tiếp HSCV (transfer ownership)
  - e_office_app_new/database/migrations/quick_260418_jsd_hscv_transfer.sql
  - e_office_app_new/backend/src/repositories/handling-doc.repository.ts
  - e_office_app_new/backend/src/routes/handling-doc.ts
  - e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx

  # Task 7 — Regenerate test catalog
  - e_office_app_new/backend/scripts/gen-test-catalog.cjs
  - docs/test_theo_hdsd_cu.md
  - docs/test_theo_hdsd_cu.xlsx

must_haves:
  truths:
    # Gap A — Ký số mock OTP (TC-011)
    - "Attachment row trên VB đi detail có nút 'Ký số' khi is_ca=false; Tag 'Đã ký số' khi is_ca=true"
    - "Attachment row trên VB dự thảo detail có nút 'Ký số' và Tag như VB đi"
    - "Bấm 'Ký số' → Modal OTP mở với label 'Nhập mã OTP (6 chữ số) gửi tới số ĐT SmartCA 84xxx***xxx'"
    - "Nhập 6 digits bất kỳ → bấm 'Xác nhận ký' → gọi POST /api/ky-so/mock/sign với {attachment_id, attachment_type} → thành công → attachment reload với is_ca=true"
    - "SP edoc.fn_attachment_outgoing_get_list + edoc.fn_attachment_drafting_get_list trả về ĐẦY ĐỦ 9 field cũ (id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at, created_by_name) + 3 field mới (is_ca, ca_date, signed_file_path) — KHÔNG đổi tên/xoá field nào"

    # Gap B — Gửi trục CP (TC-045)
    - "edoc.lgsp_tracking có cột channel VARCHAR(20) DEFAULT 'lgsp' CHECK IN ('lgsp','cp')"
    - "SP fn_lgsp_tracking_create nhận thêm param p_channel VARCHAR (default 'lgsp') — khi p_channel='cp' thì log record channel='cp'. Signature full: (p_outgoing_doc_id, p_incoming_doc_id, p_direction, p_dest_org_code, p_dest_org_name, p_edxml_content, p_created_by, p_channel)"
    - "VB đi detail (doc.approved=true) hiển thị nút 'Gửi trục CP' (màu xanh lá, kế nút 'Gửi liên thông')"
    - "Bấm nút → Modal 'Gửi trục Chính phủ' mở với Checkbox list hardcode 5+ bộ/ngành CP (Văn phòng CP, Bộ Nội vụ, Bộ Tài chính, Bộ Tư pháp, Bộ GDĐT)"
    - "Bấm 'Gửi' → gọi POST /api/van-ban-di/:id/gui-truc-cp với {org_codes: [{code,name}]} → thành công → message success"
    - "DB row lgsp_tracking mới có channel='cp', direction='send', outgoing_doc_id khớp"
    - "Call sites cũ của sendLgsp() trong outgoing-doc.repository.ts PHẢI truyền 'lgsp' ở param cuối (p_channel) để không break LGSP hiện có"

    # Gap C — Chuyển lưu trữ VB đi form (TC-046)
    - "VB đi detail (doc.approved=true AND !doc.archive_status) hiển thị nút 'Chuyển lưu trữ'"
    - "Bấm nút → Drawer 'Chuyển lưu trữ' (size=640) mở với đầy đủ 13 field giống VB đến: warehouse_id, fond_id, record_id, file_catalog, file_notation, doc_ordinal, language (default 'Tiếng Việt'), autograph, keyword, format (default 'Điện tử'), confidence_level, is_original (default true)"
    - "Warehouse + Fond dropdown load được data qua 2 endpoint mới: GET /api/van-ban-di/:id/luu-tru/phong + GET /api/van-ban-di/:id/luu-tru/kho (mirror pattern van-ban-den, dùng resolveAncestorUnit + repository.getFonds/getWarehouses)"
    - "Bấm 'Lưu' → gọi POST /api/van-ban-di/:id/chuyen-luu-tru → thành công → Drawer đóng, detail reload, Tag 'Đã lưu trữ' hiện"

    # Gap D — Hủy HSCV action riêng (TC-066)
    - "edoc.handling_docs có 3 cột mới: cancel_reason TEXT, cancelled_at TIMESTAMPTZ, cancelled_by INT"
    - "SP edoc.fn_handling_doc_cancel(p_id BIGINT, p_user_id INT, p_reason TEXT) set status=-3 + lưu 3 field audit, reject nếu reason rỗng"
    - "SP fn_handling_doc_get_by_id (DROP/CREATE) trả về toàn bộ 33 field cũ (sau hlj đã có: number, sub_number, doc_notation, doc_book_id, doc_book_name) + 3 field cancel_*"
    - "HSCV detail case status=-1 hoặc -2: nút 'Hủy HSCV' (màu đỏ) thay thế nút cũ — mở Modal nhập lý do required"
    - "Bấm 'Xác nhận hủy' → gọi POST /api/ho-so-cong-viec/:id/huy → thành công → status=-3, Tag cập nhật"
    - "Khi status=-3, detail hiển thị card 'Đã hủy' với cancel_reason + cancelled_at + cancelled_by name"

    # Gap E — Chuyển tiếp ý kiến HSCV (TC-067) — cùng Staff picker endpoint mới
    - "Endpoint mới GET /api/ho-so-cong-viec/nhan-vien-cung-don-vi (middleware: authenticate ONLY, KHÔNG requireRoles) trả list staff active cùng unit_id với current user (JWT)"
    - "edoc.opinion_handling_docs có 4 cột mới: forwarded_to_staff_id INT, forwarded_at TIMESTAMPTZ, forward_note TEXT, parent_opinion_id BIGINT REFERENCES opinion_handling_docs(id) ON DELETE SET NULL"
    - "SP edoc.fn_opinion_forward(p_opinion_id BIGINT, p_from_staff_id INT, p_to_staff_id INT, p_note TEXT) tạo row mới với parent_opinion_id=p_opinion_id, forwarded_to_staff_id=p_to_staff_id, content=p_note, staff_id=p_from_staff_id"
    - "SP fn_opinion_get_list (DROP/CREATE) giữ nguyên 6 field cũ (id, staff_id, staff_name TEXT, content, attachment_path, created_at) + thêm 5 field forward_* (forwarded_to_staff_id, forwarded_to_name TEXT, forwarded_at, forward_note, parent_opinion_id). Param vẫn là p_doc_id BIGINT. staff_name vẫn dùng CONCAT(last_name,' ',first_name)::TEXT"
    - "Mỗi opinion-item trên tab 'Ý kiến xử lý' có nút 'Chuyển tiếp' (icon share)"
    - "Bấm 'Chuyển tiếp' → Modal chọn Staff (Select) load từ /api/ho-so-cong-viec/nhan-vien-cung-don-vi + TextArea note → POST /api/ho-so-cong-viec/:id/y-kien/:opinionId/chuyen-tiep → reload"
    - "Child opinion (parent_opinion_id IS NOT NULL) render indent 24px + icon '↪' + label 'Chuyển tiếp cho {forwarded_to_name}'"

    # Gap F — Chuyển tiếp HSCV (TC-068)
    - "Table mới edoc.handling_doc_history(id BIGSERIAL, handling_doc_id BIGINT, action_type VARCHAR(50), from_staff_id INT, to_staff_id INT, note TEXT, created_by INT, created_at TIMESTAMPTZ DEFAULT NOW())"
    - "SP edoc.fn_handling_doc_transfer(p_id BIGINT, p_from_staff_id INT, p_to_staff_id INT, p_note TEXT, p_by INT) update curator + INSERT history; reject nếu to_staff khác unit_id"
    - "SP edoc.fn_handling_doc_history_list(p_id BIGINT) trả về danh sách history (JOIN staff lấy name)"
    - "HSCV detail (status IN 0,1,2,3) hiển thị nút 'Chuyển tiếp HSCV' khi user.staffId === detail.curator_id HOẶC isAdmin"
    - "Bấm nút → Modal chọn staff cùng unit (LOAD TỪ endpoint đã tạo ở Task 5: /api/ho-so-cong-viec/nhan-vien-cung-don-vi) + TextArea note → POST /api/ho-so-cong-viec/:id/chuyen-tiep → reload với curator mới"
    - "Tab 'Lịch sử' trên HSCV detail (thay button 'Xem lịch sử' stub hiện có) hiển thị list history từ GET /api/ho-so-cong-viec/:id/lich-su"

    # Gap 7 — Test catalog regenerate (PHẢI chạy CUỐI CÙNG sau Task 1-6 commit xong)
    - "TC-011, TC-045, TC-046, TC-066, TC-067, TC-068, TC-070 trong docs/test_theo_hdsd_cu.md cập nhật auto='✅ Pass' với note tương ứng"
    - "TC-079 giữ '❌ Missing' với note 'Defer Phase 2 — cần schema permission model mới'"
    - "docs/test_theo_hdsd_cu.xlsx regenerate khớp .md"

  artifacts:
    # Gap A
    - path: e_office_app_new/database/migrations/quick_260418_jsd_sign_otp.sql
      provides: "DROP/CREATE fn_attachment_outgoing_get_list + fn_attachment_drafting_get_list bổ sung 3 field is_ca/ca_date/signed_file_path (giữ đầy đủ 9 field cũ + JOIN public.staff)"
      contains: "is_ca"
    - path: e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
      provides: "Nút 'Ký số' + Modal OTP + Tag 'Đã ký số' trên attachment table"
      contains: "Input.OTP"

    # Gap B
    - path: e_office_app_new/database/migrations/quick_260418_jsd_truc_cp.sql
      provides: "ALTER lgsp_tracking ADD channel + DROP/CREATE fn_lgsp_tracking_create với signature (p_outgoing_doc_id, p_incoming_doc_id, p_direction, p_dest_org_code, p_dest_org_name, p_edxml_content, p_created_by, p_channel)"
      contains: "channel VARCHAR(20)"
    - path: e_office_app_new/backend/src/routes/outgoing-doc.ts
      provides: "POST /:id/gui-truc-cp endpoint"
      contains: "gui-truc-cp"

    # Gap C
    - path: e_office_app_new/backend/src/routes/outgoing-doc.ts
      provides: "GET /:id/luu-tru/phong + GET /:id/luu-tru/kho (mirror pattern van-ban-den)"
      contains: "luu-tru/phong"
    - path: e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
      provides: "Drawer 'Chuyển lưu trữ' với 13 field + button toolbar + fetch dropdowns"
      contains: "chuyen-luu-tru"

    # Gap D
    - path: e_office_app_new/database/migrations/quick_260418_jsd_hscv_cancel.sql
      provides: "ALTER handling_docs ADD 3 cancel fields + CREATE fn_handling_doc_cancel + DROP/CREATE fn_handling_doc_get_by_id (33 field cũ + 3 cancel_*)"
      contains: "fn_handling_doc_cancel"
    - path: e_office_app_new/backend/src/routes/handling-doc.ts
      provides: "POST /:id/huy endpoint"
      contains: "huy"

    # Gap E
    - path: e_office_app_new/database/migrations/quick_260418_jsd_opinion_forward.sql
      provides: "ALTER opinion_handling_docs ADD 4 forward fields + CREATE fn_opinion_forward + DROP/CREATE fn_opinion_get_list (6 field cũ + 5 forward_*)"
      contains: "fn_opinion_forward"
    - path: e_office_app_new/backend/src/routes/handling-doc.ts
      provides: "POST /:id/y-kien/:opinionId/chuyen-tiep + GET /nhan-vien-cung-don-vi (staff picker)"
      contains: "nhan-vien-cung-don-vi"
    - path: e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx
      provides: "Nút 'Chuyển tiếp' trên opinion-item + Modal chọn staff + thread indent"
      contains: "parent_opinion_id"

    # Gap F
    - path: e_office_app_new/database/migrations/quick_260418_jsd_hscv_transfer.sql
      provides: "CREATE TABLE handling_doc_history + CREATE fn_handling_doc_transfer + fn_handling_doc_history_list"
      contains: "handling_doc_history"
    - path: e_office_app_new/backend/src/routes/handling-doc.ts
      provides: "POST /:id/chuyen-tiep + GET /:id/lich-su"
      contains: "chuyen-tiep"

    # Gap 7
    - path: e_office_app_new/backend/scripts/gen-test-catalog.cjs
      provides: "Script generate test catalog với status updates"
    - path: docs/test_theo_hdsd_cu.md
      provides: "Test catalog regenerated với 7 TC updated"
      contains: "TC-011"

  key_links:
    # Gap A
    - from: "frontend van-ban-di/[id]/page.tsx + van-ban-du-thao/[id]/page.tsx"
      to: "/api/ky-so/mock/sign"
      via: "axios POST"
      pattern: "ky-so/mock/sign"
    - from: "SP fn_attachment_outgoing_get_list + fn_attachment_drafting_get_list"
      to: "attachment_outgoing_docs.is_ca, ca_date, signed_file_path + JOIN public.staff"
      via: "SELECT bổ sung 3 field"
      pattern: "is_ca|ca_date|signed_file_path"

    # Gap B
    - from: "frontend van-ban-di/[id]/page.tsx"
      to: "/api/van-ban-di/:id/gui-truc-cp"
      via: "axios POST"
      pattern: "gui-truc-cp"
    - from: "backend routes/outgoing-doc.ts"
      to: "edoc.fn_lgsp_tracking_create(outgoing_doc_id, NULL, 'send', org_code, org_name, NULL, staffId, 'cp')"
      via: "callFunctionOne"
      pattern: "channel.*cp"

    # Gap C
    - from: "frontend van-ban-di/[id]/page.tsx Drawer"
      to: "/api/van-ban-di/:id/chuyen-luu-tru + /luu-tru/phong + /luu-tru/kho"
      via: "axios GET+POST"
      pattern: "chuyen-luu-tru|luu-tru/(phong|kho)"
    - from: "backend routes/outgoing-doc.ts /:id/chuyen-luu-tru"
      to: "esto.fn_document_archive_create(doc_type='outgoing', ...13 params)"
      via: "callFunctionOne"
      pattern: "fn_document_archive_create"

    # Gap D
    - from: "frontend ho-so-cong-viec/[id]/page.tsx"
      to: "/api/ho-so-cong-viec/:id/huy"
      via: "axios POST"
      pattern: "/huy"
    - from: "edoc.fn_handling_doc_cancel"
      to: "edoc.handling_docs.status=-3 + cancel_reason + cancelled_at + cancelled_by"
      via: "UPDATE"
      pattern: "status.*-3"

    # Gap E
    - from: "frontend ho-so-cong-viec/[id]/page.tsx opinion-item"
      to: "/api/ho-so-cong-viec/:id/y-kien/:opinionId/chuyen-tiep"
      via: "axios POST"
      pattern: "y-kien.*chuyen-tiep"
    - from: "frontend Modal chọn staff forward"
      to: "/api/ho-so-cong-viec/nhan-vien-cung-don-vi"
      via: "axios GET (no admin RBAC)"
      pattern: "nhan-vien-cung-don-vi"
    - from: "edoc.fn_opinion_forward"
      to: "edoc.opinion_handling_docs (INSERT row với parent_opinion_id)"
      via: "INSERT"
      pattern: "parent_opinion_id"

    # Gap F
    - from: "frontend ho-so-cong-viec/[id]/page.tsx"
      to: "/api/ho-so-cong-viec/:id/chuyen-tiep + /lich-su"
      via: "axios POST/GET"
      pattern: "(/chuyen-tiep|/lich-su)"
    - from: "frontend Modal chọn staff transfer"
      to: "/api/ho-so-cong-viec/nhan-vien-cung-don-vi (reuse từ Task 5)"
      via: "axios GET"
      pattern: "nhan-vien-cung-don-vi"
    - from: "edoc.fn_handling_doc_transfer"
      to: "edoc.handling_docs.curator + edoc.handling_doc_history (INSERT)"
      via: "UPDATE + INSERT"
      pattern: "handling_doc_history"
---

<objective>
Hoàn thành 6 gap HDSD compliance còn lại (sau task 260418-hlj đã đóng 3 gap P0/P1):

- **Gap A (TC-011)** — UI ký số mock OTP trên VB đi + VB dự thảo (backend mock đã sẵn).
- **Gap B (TC-045)** — Gửi trục CP (mock) — fork pattern LGSP.
- **Gap C (TC-046)** — Mở rộng form chuyển lưu trữ VB đi với 13 field (copy từ VB đến) + 2 endpoint dropdowns mới.
- **Gap D (TC-066)** — Hủy HSCV thành action riêng, thu lý do (schema mới + SP mới).
- **Gap E (TC-067)** — Chuyển tiếp ý kiến HSCV (forward opinion to another staff) + endpoint staff picker mới (bypass RBAC admin).
- **Gap F (TC-068)** — Chuyển tiếp HSCV (transfer ownership + history table). Reuse staff picker từ Task 5.

Thêm Task 7 — regenerate test catalog (docs/test_theo_hdsd_cu.md + .xlsx) để update 7 TC sau khi fix.

Purpose: gom 7 task TUẦN TỰ trong 1 PLAN (tránh parallel bug Phase 5), mỗi task là 1 commit riêng. Target ~40% context budget.
Output: 7 commit độc lập — demo HDSD compliance đầy đủ trước 2026-04-18/19.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<db_verified>
**DB verify đã chạy trước khi viết plan (revision 1). KHÔNG dùng memory, đối chiếu output thật:**

### fn_attachment_outgoing_get_list
```
RETURNS TABLE(
  id bigint, file_name character varying, file_path character varying,
  file_size bigint, content_type character varying, sort_order integer,
  created_by integer, created_at timestamp with time zone,
  created_by_name character varying
)
Argument: p_doc_id bigint
Body:
  SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
         a.sort_order, a.created_by, a.created_at, s.full_name
  FROM edoc.attachment_outgoing_docs a
  LEFT JOIN public.staff s ON s.id = a.created_by
  WHERE a.outgoing_doc_id = p_doc_id  -- !!! cột FK là outgoing_doc_id, KHÔNG phải doc_id
  ORDER BY a.sort_order, a.created_at;
```

### fn_attachment_drafting_get_list
```
RETURNS TABLE(id bigint, file_name, file_path, file_size, content_type,
              sort_order, created_by, created_at, created_by_name) — 9 cột GIỐNG HỆT outgoing
Argument: p_doc_id bigint
Cột FK: drafting_doc_id (KHÔNG phải doc_id)
```

### fn_attachment_mock_sign
```
RETURNS TABLE(success boolean, message text)
Arguments: p_attachment_id bigint, p_attachment_type character varying, p_signed_by integer
=> attachment_type enum: verify trong SP body trước khi code FE — expect 'outgoing' và 'drafting'
```

### fn_lgsp_tracking_create (HIỆN TẠI — CẦN DROP/CREATE)
```
RETURNS TABLE(success boolean, message text, id bigint)
Arguments (theo đúng thứ tự):
  p_outgoing_doc_id bigint DEFAULT NULL,
  p_incoming_doc_id bigint DEFAULT NULL,
  p_direction character varying DEFAULT 'send',
  p_dest_org_code character varying DEFAULT NULL,
  p_dest_org_name character varying DEFAULT NULL,
  p_edxml_content text DEFAULT NULL,
  p_created_by integer DEFAULT NULL
```

### fn_opinion_get_list (HIỆN TẠI — CẦN DROP/CREATE)
```
RETURNS TABLE(
  id bigint, staff_id integer, staff_name text, content text,
  attachment_path character varying, created_at timestamp with time zone
)
Argument: p_doc_id bigint
Body uses: CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name
          JOIN public.staff s ON s.id = o.staff_id
          WHERE o.handling_doc_id = p_doc_id
          ORDER BY o.created_at ASC
```

### fn_handling_doc_get_by_id (HIỆN TẠI — đã mở rộng ở hlj)
```
RETURNS TABLE 33 fields:
  id bigint, unit_id integer, unit_name character varying,
  department_id integer, department_name character varying,
  name character varying, abstract text, comments text,
  doc_notation character varying, doc_type_id integer,
  doc_type_name character varying, doc_field_id integer,
  doc_field_name character varying, start_date, end_date,
  curator_id integer, curator_name text,
  signer_id integer, signer_name text,
  status smallint, progress smallint,
  workflow_id integer, workflow_name character varying,
  parent_id bigint, parent_name character varying,
  is_from_doc boolean, created_by integer, created_at, updated_at,
  number integer, sub_number character varying,
  doc_book_id integer, doc_book_name character varying
=> 33 cột, KHÔNG có cột nào tên là "id_curator" hoặc "curator" — bảng column tên `curator` nhưng SP trả `curator_id`
```

### public.staff
```
Có cột: id (SERIAL), username, first_name (VARCHAR 50), last_name (VARCHAR 50 NOT NULL),
        full_name (GENERATED: CASE WHEN first_name IS NOT NULL THEN first_name||' '||last_name ELSE last_name END),
        unit_id INT NOT NULL, department_id INT NOT NULL, is_locked BOOLEAN DEFAULT false,
        is_deleted BOOLEAN DEFAULT false, sign_phone, ...
=> CÓ cột full_name (generated) — dùng được trong JOIN cho forwarded_to_name
=> CÓ cột is_deleted — filter staff picker
```

### edoc.lgsp_tracking
```
Cột thật: id BIGSERIAL, outgoing_doc_id BIGINT, incoming_doc_id BIGINT,
          direction VARCHAR(10) CHECK ('send','receive'),
          lgsp_doc_id VARCHAR(200), dest_org_code VARCHAR(100), dest_org_name VARCHAR(500),
          edxml_content TEXT, status VARCHAR(50) CHECK ('pending','processing','success','error') DEFAULT 'pending',
          error_message TEXT, sent_at, received_at, created_at, created_by INT
=> KHÔNG có cột doc_id, incoming_id, response — tên CHÍNH XÁC là outgoing_doc_id, incoming_doc_id, edxml_content
=> CẦN ADD: channel VARCHAR(20) DEFAULT 'lgsp' CHECK IN ('lgsp','cp')
```

### edoc.opinion_handling_docs
```
Cột thật: id BIGSERIAL, handling_doc_id BIGINT NOT NULL, staff_id INT NOT NULL,
          content TEXT NOT NULL, attachment_path VARCHAR(1000), created_at
=> KHÔNG có cột opinion_type, is_forwarded — cần ADD 4 cột forward_*
```
</db_verified>

<context>
@CLAUDE.md
@.planning/quick/260418-jsd-hdsd-compliance-fix-6-gap-c-n-l-i-k-s-mo/260418-jsd-RESEARCH.md
@.planning/quick/260418-hlj-hdsd-compliance-p0-p1-k-s-smartca-ui-thu/260418-hlj-PLAN.md
@e_office_app_new/backend/src/server.ts
@e_office_app_new/backend/src/middleware/auth.ts
@e_office_app_new/backend/src/lib/db/pool.ts
@e_office_app_new/backend/src/routes/digital-signature.ts
@e_office_app_new/backend/src/routes/outgoing-doc.ts
@e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts
@e_office_app_new/backend/src/routes/drafting-doc.ts
@e_office_app_new/backend/src/repositories/drafting-doc.repository.ts
@e_office_app_new/backend/src/routes/handling-doc.ts
@e_office_app_new/backend/src/repositories/handling-doc.repository.ts
@e_office_app_new/backend/src/routes/incoming-doc.ts
@e_office_app_new/backend/src/repositories/incoming-doc.repository.ts
@e_office_app_new/backend/src/lib/error-handler.ts
@e_office_app_new/backend/scripts/gen-test-catalog.cjs
@e_office_app_new/frontend/src/lib/api.ts
@e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
@e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx
@e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx
@e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx
@docs/test_theo_hdsd_cu.md

<critical_constraints>
- **Sequential execution** — KHÔNG chạy parallel (bài học Phase 5, CLAUDE.md).
- **Per-task integration check**: sau mỗi task, chạy type-check (BE + FE) + manual smoke test DB trước khi sang task tiếp theo.
- **AntD 6.3.5**: Drawer dùng `size={640}` (không `width`); **Modal vẫn dùng `width={720}`** — CHỈ Drawer đổi sang `size`; `<Input.OTP length={6} />` (AntD 5.13+, inherited).
- **PostgreSQL reserved words** trong RETURNS TABLE: `"number"`, `"status"`, `"order"`, `"position"`, `"comment"`, `"user"`, `"type"`, `"name"`, `"value"`, `"key"`. Task 2 có cột `channel` — không reserved, OK. Task 6 dùng cột `action_type` (đổi từ `action` cho an toàn) — không reserved.
- **BIGSERIAL → BIGINT param**: `handling_docs.id`, `opinion_handling_docs.id`, `lgsp_tracking.id` đều BIGSERIAL → SP param PHẢI `p_id BIGINT`. `staff.id`, `doc_books.id`, `departments.id` là SERIAL (INT) → `p_*_id INT`.
- **DROP/CREATE** (không dùng `CREATE OR REPLACE`) khi RETURNS TABLE signature đổi:
  - Task 1: `fn_attachment_outgoing_get_list`, `fn_attachment_drafting_get_list` (thêm 3 field — giữ đầy đủ 9 field cũ).
  - Task 2: `fn_lgsp_tracking_create` (thêm p_channel — signature đổi).
  - Task 4: `fn_handling_doc_get_by_id` (đã DROP/CREATE 1 lần ở hlj — phải COPY 33 field cũ rồi thêm 3 field cancel_*).
  - Task 5: `fn_opinion_get_list` (thêm 5 field forward_*).
- **Field name SP ↔ Repo Row interface ↔ FE** PHẢI match đúng tên cột DB snake_case (CLAUDE.md rule 1). KHÔNG alias rename.
- **Cập nhật AttachmentRow interface**: giữ tên cũ, chỉ ADD 3 field optional (is_ca, ca_date, signed_file_path) để không break các repo/route khác đang import.
- **Backend imports .js extension** (ESM): `import { ... } from '../lib/db/pool.js';`.
- **maxLength trên Input** khớp DB VARCHAR (CLAUDE.md rule 9). Query `\d table_name` trước khi đặt maxLength.
- **NOT NULL columns** → Form.Item rules required (CLAUDE.md rule 10).
- **setBackendFieldError** cho unique violation (CLAUDE.md rule 13).
- **All UI text tiếng Việt có dấu**.
- **Mock endpoints PHẢI có comment** `// TODO Phase 2: tích hợp VNPT SmartCA SDK thực` hoặc `// TODO Phase 2: tích hợp trục CP thực`.
- **Migration chạy ngay sau khi viết**: `docker cp ... qlvb_postgres:/tmp/ && docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -f /tmp/...` rồi verify SP bằng `\df+` hoặc SELECT test.
  - **DB credentials**: User=`qlvb_admin`, DB=`qlvb_dev`, Password=`QlvbDev@2026`. KHÔNG dùng `postgres`/`qlvb` (sai).
- **Staff picker endpoint** (Task 5 tạo, Task 6 reuse): mount TRỰC TIẾP trong `/api/ho-so-cong-viec` sub-route (file handling-doc.ts). Middleware CHỈ `authenticate` — KHÔNG `requireRoles`. Điều này tránh block RBAC `/api/quan-tri` (chỉ admin được gọi).
- **Commit format**: prefix tiếng Anh (`feat:`, `docs:`), nội dung tiếng Việt có dấu. Mỗi task 1 commit riêng.
- **KHÔNG tự commit** — chờ user xác nhận hoặc orchestrator ra lệnh.
- **Next.js 16**: đọc file source trực tiếp, KHÔNG dùng training knowledge (breaking changes so với Next.js 14/15).
- **Backend + FE hot-reload** đang chạy (ports 4000, 3000) — không cần restart server.
- **Task 7 BLOCKING**: PHẢI chạy CUỐI CÙNG, sau khi Task 1-6 commit xong. Nếu Task 1-6 có task nào fail → Task 7 phải chờ hoặc điều chỉnh note theo kết quả thực.
</critical_constraints>

<interfaces>
<!-- Key contracts từ codebase — executor dùng trực tiếp, không cần explore -->

From e_office_app_new/backend/src/lib/db/pool.ts:
```typescript
export async function callFunction<T>(name: string, params: unknown[]): Promise<T[]>;
export async function callFunctionOne<T>(name: string, params: unknown[]): Promise<T | null>;
export async function rawQuery<T>(sql: string, params?: unknown[]): Promise<T[]>;
export async function withTransaction<T>(callback: (client: PoolClient) => Promise<T>): Promise<T>;
```

From e_office_app_new/backend/src/middleware/auth.ts:
```typescript
export interface AuthRequest extends Request {
  user?: { staffId: number; unitId: number; departmentId: number; roles: string[]; ... };
}
export const authenticate: RequestHandler;
export const requireRoles: (...roles: string[]) => RequestHandler;
```

From e_office_app_new/backend/src/lib/error-handler.ts:
```typescript
export function handleDbError(err: unknown, res: Response, next?: NextFunction): void;
// Maps 23505 (unique), 23503 (FK), 23502 (NOT NULL) sang Vietnamese messages.
```

From e_office_app_new/backend/src/routes/digital-signature.ts (đã existing):
```typescript
// Route mount tại /api/ky-so
// POST /mock/sign body { attachment_id: number, attachment_type: 'outgoing'|'drafting' }
// Trả { success, message }. Gọi edoc.fn_attachment_mock_sign(p_attachment_id, p_attachment_type, p_signed_by).
// POST /mock/verify body { attachment_id, attachment_type } — no-op, trả { valid: true } nếu is_ca=true.
```

From e_office_app_new/backend/src/routes/outgoing-doc.ts (~line 708):
```typescript
// Pattern hiện có: POST /:id/gui-lien-thong
router.post('/:id/gui-lien-thong', authenticate, async (req, res, next) => {
  const docId = Number(req.params.id);
  const { org_codes } = req.body; // Array<{code, name}>
  for (const org of org_codes) {
    await outgoingDocRepository.sendLgsp(docId, org.code, org.name, req.user!.staffId);
  }
  res.json({ success: true });
});
// outgoingDocRepository.sendLgsp gọi edoc.fn_lgsp_tracking_create — CẦN UPDATE sau Task 2 thêm 'lgsp' param cuối.
```

From e_office_app_new/backend/src/routes/outgoing-doc.ts (~line 740):
```typescript
// POST /:id/chuyen-luu-tru — ĐÃ CÓ endpoint, chỉ thiếu FE drawer
router.post('/:id/chuyen-luu-tru', authenticate, async (req, res, next) => {
  // body chứa 13 field: warehouse_id, fond_id, record_id, file_catalog, file_notation,
  //   doc_ordinal, language, autograph, keyword, format, confidence_level, is_original
  // gọi incomingDocRepository.createArchive('outgoing', docId, {...}, staffId)
});
```

From e_office_app_new/backend/src/routes/incoming-doc.ts (~line 812-828) — PATTERN MẪU CHO TASK 3:
```typescript
// GET /:id/luu-tru/phong (fond dropdown)
router.get('/:id/luu-tru/phong', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const fonds = await incomingDocRepository.getFonds(ancestorUnitId);
    res.json({ success: true, data: fonds });
  } catch (error) { handleDbError(error, res); }
});

// GET /:id/luu-tru/kho (warehouse dropdown)
router.get('/:id/luu-tru/kho', async (req: Request, res: Response) => {
  try {
    const { departmentId } = (req as AuthRequest).user;
    const ancestorUnitId = await resolveAncestorUnit(departmentId);
    const warehouses = await incomingDocRepository.getWarehouses(ancestorUnitId);
    res.json({ success: true, data: warehouses });
  } catch (error) { handleDbError(error, res); }
});
// => Task 3 COPY 2 handler này sang routes/outgoing-doc.ts (đổi module name trong comment). Helper resolveAncestorUnit đã tồn tại trong incoming-doc.ts — cần export hoặc duplicate (ưu tiên export từ incoming-doc.ts).
```

From e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx (~line 289-301):
```tsx
// FE gọi 2 endpoint SCOPED theo doc, KHÔNG phải global:
api.get(`/van-ban-den/${docId}/luu-tru/phong`),
api.get(`/van-ban-den/${docId}/luu-tru/kho`),
// => Task 3 FE gọi: api.get(`/van-ban-di/${id}/luu-tru/phong`) + api.get(`/van-ban-di/${id}/luu-tru/kho`)
```

From e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx (~line 876-901):
```tsx
// Drawer "Chuyển lưu trữ" mẫu — COPY toàn bộ khối này sang VB đi:
<Drawer
  title="Chuyển lưu trữ"
  size={640}
  open={archiveOpen}
  onClose={() => setArchiveOpen(false)}
  extra={<Space><Button onClick={() => setArchiveOpen(false)}>Hủy</Button><Button type="primary" loading={archiving} onClick={() => archiveForm.submit()}>Lưu</Button></Space>}
  rootClassName="drawer-gradient"
>
  <Form form={archiveForm} layout="vertical" onFinish={handleArchive} initialValues={{ language: 'Tiếng Việt', format: 'Điện tử', is_original: true }}>
    {/* 13 Form.Item: warehouse_id, fond_id, record_id, file_catalog, file_notation, doc_ordinal, language, autograph, keyword, format, confidence_level, is_original */}
  </Form>
</Drawer>
```

From e_office_app_new/backend/src/server.ts (~line 61-71):
```typescript
// CHÚ Ý RBAC mount boundary:
app.use('/api/quan-tri', authenticate, requireRoles('Quản trị hệ thống'), adminRoutes);  // Block non-admin
app.use('/api/ho-so-cong-viec', authenticate, handlingDocRoutes);  // Chỉ authenticate, KHÔNG role
// => Task 5 staff picker PHẢI mount trong handling-doc.ts (không đụng /api/quan-tri)
```

From e_office_app_new/frontend/src/lib/api.ts:
```typescript
export const api: AxiosInstance; // baseURL: /api, JWT auto-attached
```

DB schema verified (đã query thực):

edoc.attachment_outgoing_docs (Gap A) — ĐÃ CÓ:
  - id BIGSERIAL, outgoing_doc_id BIGINT (tên CHUẨN — không phải doc_id),
    file_name VARCHAR, file_path VARCHAR, file_size BIGINT,
    content_type VARCHAR, sort_order INT, created_by INT, created_at,
    is_ca BOOLEAN DEFAULT FALSE, ca_date TIMESTAMPTZ, signed_file_path VARCHAR(1000)

edoc.attachment_drafting_docs (Gap A) — ĐÃ CÓ:
  - id BIGSERIAL, drafting_doc_id BIGINT (tên CHUẨN), + các cột tương tự outgoing.

edoc.lgsp_tracking (Gap B):
  - id BIGSERIAL, outgoing_doc_id BIGINT, incoming_doc_id BIGINT,
    direction VARCHAR(10) CHECK ('send','receive'),
    lgsp_doc_id VARCHAR(200), dest_org_code VARCHAR(100), dest_org_name VARCHAR(500),
    edxml_content TEXT, status VARCHAR(50), error_message TEXT, sent_at, received_at, created_at, created_by INT
  - **CẦN ADD: channel VARCHAR(20) DEFAULT 'lgsp' CHECK IN ('lgsp','cp')**

edoc.handling_docs (Gap D + F):
  - id BIGSERIAL, status SMALLINT DEFAULT 0, curator INT REFERENCES public.staff(id),
    unit_id INT, department_id INT, created_at, updated_at, progress SMALLINT
  - **CẦN ADD cho Task 4: cancel_reason TEXT, cancelled_at TIMESTAMPTZ, cancelled_by INT**

edoc.opinion_handling_docs (Gap E):
  - id BIGSERIAL, handling_doc_id BIGINT, staff_id INT, content TEXT NOT NULL,
    attachment_path VARCHAR(1000), created_at
  - **CẦN ADD: forwarded_to_staff_id INT, forwarded_at TIMESTAMPTZ, forward_note TEXT, parent_opinion_id BIGINT REFERENCES edoc.opinion_handling_docs(id) ON DELETE SET NULL**

public.staff (Task 5+6 staff picker):
  - id INT (SERIAL), username, first_name, last_name, full_name GENERATED,
    unit_id INT NOT NULL, department_id INT NOT NULL,
    is_locked BOOLEAN DEFAULT false, is_deleted BOOLEAN DEFAULT false,
    sign_phone VARCHAR(20)
  - **Filter cho staff picker**: WHERE unit_id = ? AND is_locked = false AND is_deleted = false
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Gap A (TC-011) — Ký số mock OTP trên VB đi + VB dự thảo</name>
  <files>
    e_office_app_new/database/migrations/quick_260418_jsd_sign_otp.sql,
    e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts,
    e_office_app_new/backend/src/repositories/drafting-doc.repository.ts,
    e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx,
    e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx
  </files>
  <action>
    **Wave 1 — DB: DROP/CREATE 2 SP attachment, GIỮ ĐẦY ĐỦ 9 field cũ + ADD 3 field mới.**

    1. VERIFY SP hiện tại (đọc exact body để copy):
       ```bash
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname='edoc' AND p.proname='fn_attachment_outgoing_get_list';"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname='edoc' AND p.proname='fn_attachment_mock_sign';"
       ```
       - **Xác nhận attachment_type enum** trong `fn_attachment_mock_sign` body — expect 'outgoing'/'drafting' (và có thể 'handling'). Ghi lại exact values cho FE.

    2. Tạo `e_office_app_new/database/migrations/quick_260418_jsd_sign_otp.sql` — **COPY chính xác 9 field cũ + JOIN staff + thêm 3 field cuối**:
       ```sql
       -- Gap A (TC-011): bổ sung is_ca/ca_date/signed_file_path vào 2 SP get_attachments
       -- GIỮ ĐẦY ĐỦ 9 field cũ + JOIN public.staff cho created_by_name
       -- CHÚ Ý: cột FK là outgoing_doc_id / drafting_doc_id (KHÔNG phải doc_id)

       DROP FUNCTION IF EXISTS edoc.fn_attachment_outgoing_get_list(BIGINT);
       CREATE OR REPLACE FUNCTION edoc.fn_attachment_outgoing_get_list(p_doc_id BIGINT)
       RETURNS TABLE(
           id BIGINT,
           file_name VARCHAR,
           file_path VARCHAR,
           file_size BIGINT,
           content_type VARCHAR,
           sort_order INT,
           created_by INT,
           created_at TIMESTAMPTZ,
           created_by_name VARCHAR,
           -- 3 field MỚI thêm vào cuối:
           is_ca BOOLEAN,
           ca_date TIMESTAMPTZ,
           signed_file_path VARCHAR
       )
       LANGUAGE plpgsql
       AS $$
       BEGIN
           RETURN QUERY
           SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
                  a.sort_order, a.created_by, a.created_at, s.full_name AS created_by_name,
                  COALESCE(a.is_ca, FALSE) AS is_ca,
                  a.ca_date,
                  a.signed_file_path
           FROM edoc.attachment_outgoing_docs a
           LEFT JOIN public.staff s ON s.id = a.created_by
           WHERE a.outgoing_doc_id = p_doc_id  -- GIỮ đúng tên cột FK
           ORDER BY a.sort_order, a.created_at;
       END;
       $$;

       DROP FUNCTION IF EXISTS edoc.fn_attachment_drafting_get_list(BIGINT);
       CREATE OR REPLACE FUNCTION edoc.fn_attachment_drafting_get_list(p_doc_id BIGINT)
       RETURNS TABLE(
           id BIGINT,
           file_name VARCHAR,
           file_path VARCHAR,
           file_size BIGINT,
           content_type VARCHAR,
           sort_order INT,
           created_by INT,
           created_at TIMESTAMPTZ,
           created_by_name VARCHAR,
           is_ca BOOLEAN,
           ca_date TIMESTAMPTZ,
           signed_file_path VARCHAR
       )
       LANGUAGE plpgsql
       AS $$
       BEGIN
           RETURN QUERY
           SELECT a.id, a.file_name, a.file_path, a.file_size, a.content_type,
                  a.sort_order, a.created_by, a.created_at, s.full_name AS created_by_name,
                  COALESCE(a.is_ca, FALSE) AS is_ca,
                  a.ca_date,
                  a.signed_file_path
           FROM edoc.attachment_drafting_docs a
           LEFT JOIN public.staff s ON s.id = a.created_by
           WHERE a.drafting_doc_id = p_doc_id  -- Cột FK drafting_doc_id
           ORDER BY a.sort_order, a.created_at;
       END;
       $$;
       ```

    3. Chạy migration:
       ```bash
       docker cp e_office_app_new/database/migrations/quick_260418_jsd_sign_otp.sql qlvb_postgres:/tmp/
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -f /tmp/quick_260418_jsd_sign_otp.sql
       # Verify 12 field:
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\df+ edoc.fn_attachment_outgoing_get_list"
       # Test (chọn 1 doc_id có attachment):
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT id, file_name, is_ca, ca_date, signed_file_path FROM edoc.fn_attachment_outgoing_get_list((SELECT outgoing_doc_id FROM edoc.attachment_outgoing_docs LIMIT 1));"
       ```

    **Wave 2 — Backend repo: ADD 3 field vào interface AttachmentRow (KHÔNG xóa field cũ, KHÔNG đổi tên).**

    4. Update `e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts`:
       - Tìm interface `AttachmentRow` (line ~178 area).
       - **ADD 3 field** (optional để backward-compat với nơi khác import):
         ```typescript
         is_ca?: boolean;
         ca_date?: string | null;
         signed_file_path?: string | null;
         ```
       - KHÔNG xóa hay rename field cũ (id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at, created_by_name).

    5. Tương tự cho `e_office_app_new/backend/src/repositories/drafting-doc.repository.ts`:
       - Add 3 field optional vào AttachmentRow interface tương ứng.

    **Wave 3 — Frontend: nút Ký số + Modal OTP trên 2 page.**

    6. Update `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx`:
       - **Đọc file trước** để biết structure attachment table (columns, render function, Attachment interface).
       - Bổ sung interface `Attachment`: `is_ca?: boolean; ca_date?: string | null; signed_file_path?: string | null;`.
       - State mới:
         ```typescript
         const [otpOpen, setOtpOpen] = useState(false);
         const [otpValue, setOtpValue] = useState('');
         const [signing, setSigning] = useState(false);
         const [targetAttachment, setTargetAttachment] = useState<Attachment | null>(null);
         ```
       - Thêm column "Chữ ký số" vào attachment table (hoặc bổ sung nút vào column "Thao tác"):
         ```tsx
         {
           title: 'Chữ ký số',
           key: 'signature',
           width: 180,
           render: (_: unknown, record: Attachment) => record.is_ca
             ? <Tag color="success" icon={<CheckCircleOutlined />}>Đã ký số</Tag>
             : <Button size="small" type="primary" ghost icon={<SafetyOutlined />} onClick={() => { setTargetAttachment(record); setOtpOpen(true); setOtpValue(''); }}>Ký số</Button>
         }
         ```
       - Modal OTP (width=420 dùng default AntD Modal — note Modal DÙNG `width` không `size`):
         ```tsx
         <Modal
           open={otpOpen}
           title="Xác thực OTP để ký số"
           okText="Xác nhận ký"
           cancelText="Hủy"
           confirmLoading={signing}
           onCancel={() => { setOtpOpen(false); setOtpValue(''); setTargetAttachment(null); }}
           onOk={handleSignOtp}
         >
           <p style={{ marginBottom: 16 }}>
             Nhập mã OTP (6 chữ số) đã gửi đến số điện thoại đăng ký SmartCA
             {user?.sign_phone ? ` (${maskPhone(user.sign_phone)})` : ''}:
           </p>
           <Input.OTP length={6} value={otpValue} onChange={setOtpValue} />
           {/* TODO Phase 2: tích hợp VNPT SmartCA SDK thực — gọi BE verify OTP */}
         </Modal>
         ```
       - Helper `maskPhone`:
         ```typescript
         const maskPhone = (phone: string): string => {
           if (!phone || phone.length < 8) return phone;
           return phone.substring(0, 4) + '***' + phone.substring(phone.length - 3);
         };
         ```
       - Handler `handleSignOtp`:
         ```typescript
         const handleSignOtp = async () => {
           if (otpValue.length !== 6) {
             message.warning('Vui lòng nhập đủ 6 chữ số OTP');
             return;
           }
           if (!targetAttachment) return;
           setSigning(true);
           try {
             // TODO Phase 2: tích hợp VNPT SmartCA SDK thực — hiện chỉ FE giả lập OTP
             const res = await api.post('/ky-so/mock/sign', {
               attachment_id: targetAttachment.id,
               attachment_type: 'outgoing',
             });
             if (res.data?.success === false) {
               message.error(res.data.message || 'Ký số thất bại');
             } else {
               message.success('Ký số thành công');
               setOtpOpen(false);
               setOtpValue('');
               setTargetAttachment(null);
               fetchAttachments(); // hoặc fetchDetail() nếu attachment inline trong detail
             }
           } catch (err: any) {
             message.error(err.response?.data?.message || 'Ký số thất bại');
           } finally {
             setSigning(false);
           }
         };
         ```
       - Import `Input.OTP`: `import { Modal, Input, Tag, Button } from 'antd';` + `SafetyOutlined, CheckCircleOutlined` từ `@ant-design/icons`.
       - Nếu `Input.OTP` KHÔNG render (AntD 6.3.5 edge case) → fallback `<Input maxLength={6} placeholder="Nhập 6 chữ số" value={otpValue} onChange={(e) => setOtpValue(e.target.value.replace(/\D/g, ''))} />`.

    7. Tương tự với `e_office_app_new/frontend/src/app/(main)/van-ban-du-thao/[id]/page.tsx`:
       - Copy pattern từ (6) — chỉ đổi `attachment_type: 'drafting'` khi gọi `/ky-so/mock/sign`.
       - Column attachment có thể khác tên state — đọc file trước.

    **Verification sau task:**
    - `cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tail -20` → 0 new errors.
    - `cd e_office_app_new/frontend && npx tsc --noEmit 2>&1 | tail -20` → 0 new errors.
    - DB: `SELECT COUNT(*) FROM (SELECT * FROM edoc.fn_attachment_outgoing_get_list(1)) x;` — 12 cột trả về.
    - Manual smoke test:
      - Login → VB đi detail có file → attachment table có nút "Ký số".
      - Nhấn → Modal OTP mở → nhập 6 digits bất kỳ → "Xác nhận ký" → Tag "Đã ký số" hiện.
      - Check DB: `SELECT is_ca, ca_date FROM edoc.attachment_outgoing_docs WHERE id = <attachment_id>` → is_ca=true.
      - Tương tự VB dự thảo.

    **Commit:** `feat: thêm UI ký số VB đi/dự thảo với mock OTP — HDSD I.5`
  </action>
  <verify>
    <automated>
      cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tail -20 &&
      cd ../frontend && npx tsc --noEmit 2>&1 | tail -20 &&
      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT pg_get_function_result(p.oid) FROM pg_proc p WHERE p.proname IN ('fn_attachment_outgoing_get_list','fn_attachment_drafting_get_list');"
    </automated>
  </verify>
  <done>
    - 2 SP attachment (fn_attachment_outgoing_get_list + fn_attachment_drafting_get_list) trả về ĐỦ 12 field: 9 cũ (id, file_name, file_path, file_size, content_type, sort_order, created_by, created_at, created_by_name) + 3 mới (is_ca, ca_date, signed_file_path).
    - SP dùng đúng tên cột FK (outgoing_doc_id / drafting_doc_id) và JOIN public.staff cho created_by_name.
    - AttachmentRow interface trong cả outgoing + drafting repo có thêm 3 field optional (is_ca, ca_date, signed_file_path) — KHÔNG xoá field cũ.
    - Backend + FE type-check pass.
    - VB đi + VB dự thảo attachment table có nút "Ký số" + Tag "Đã ký số".
    - Modal OTP với `<Input.OTP length={6}>` hoặc fallback Input maxLength=6.
    - maskPhone helper render đúng format 84xxx***xxx khi user.sign_phone có.
    - Comment `// TODO Phase 2: tích hợp VNPT SmartCA SDK thực` tại chỗ gọi `/ky-so/mock/sign`.
    - Manual test ký số thành công → DB is_ca=true.
    - Commit: `feat: thêm UI ký số VB đi/dự thảo với mock OTP — HDSD I.5`.
  </done>
</task>

<task type="auto">
  <name>Task 2: Gap B (TC-045) — Gửi trục CP (mock)</name>
  <files>
    e_office_app_new/database/migrations/quick_260418_jsd_truc_cp.sql,
    e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts,
    e_office_app_new/backend/src/routes/outgoing-doc.ts,
    e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
  </files>
  <action>
    **Wave 1 — DB: ALTER lgsp_tracking + DROP/CREATE fn_lgsp_tracking_create với signature ĐÚNG.**

    1. VERIFY SP hiện tại (signature CHÍNH XÁC từ pg_proc):
       ```bash
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\df+ edoc.fn_lgsp_tracking_create"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\d edoc.lgsp_tracking"
       # Expect args: (p_outgoing_doc_id bigint, p_incoming_doc_id bigint, p_direction varchar, p_dest_org_code varchar, p_dest_org_name varchar, p_edxml_content text, p_created_by integer)
       ```

    2. Tạo `e_office_app_new/database/migrations/quick_260418_jsd_truc_cp.sql` — **DÙNG ĐÚNG TÊN PARAM + TÊN CỘT từ DB**:
       ```sql
       -- Gap B (TC-045): thêm cột channel vào lgsp_tracking + mở rộng SP fn_lgsp_tracking_create
       -- CHÚ Ý: cột DB là outgoing_doc_id, incoming_doc_id, edxml_content (KHÔNG phải doc_id, incoming_id, response).

       -- 1. ADD cột channel
       ALTER TABLE edoc.lgsp_tracking
         ADD COLUMN IF NOT EXISTS channel VARCHAR(20) DEFAULT 'lgsp' NOT NULL;

       -- 2. ADD CHECK constraint
       DO $$
       BEGIN
           IF NOT EXISTS (
               SELECT 1 FROM pg_constraint WHERE conname = 'lgsp_tracking_channel_check'
           ) THEN
               ALTER TABLE edoc.lgsp_tracking
                 ADD CONSTRAINT lgsp_tracking_channel_check CHECK (channel IN ('lgsp', 'cp'));
           END IF;
       END $$;

       -- 3. DROP signature cũ (ĐÚNG theo \df+ output: 7 params)
       DROP FUNCTION IF EXISTS edoc.fn_lgsp_tracking_create(
           BIGINT, BIGINT, VARCHAR, VARCHAR, VARCHAR, TEXT, INT
       );

       -- 4. CREATE mới với thêm p_channel default 'lgsp' ở cuối (backward-compat)
       CREATE OR REPLACE FUNCTION edoc.fn_lgsp_tracking_create(
           p_outgoing_doc_id BIGINT DEFAULT NULL,
           p_incoming_doc_id BIGINT DEFAULT NULL,
           p_direction VARCHAR DEFAULT 'send',
           p_dest_org_code VARCHAR DEFAULT NULL,
           p_dest_org_name VARCHAR DEFAULT NULL,
           p_edxml_content TEXT DEFAULT NULL,
           p_created_by INT DEFAULT NULL,
           p_channel VARCHAR DEFAULT 'lgsp'
       )
       RETURNS TABLE(success BOOLEAN, message TEXT, id BIGINT)
       LANGUAGE plpgsql
       SECURITY DEFINER
       AS $$
       DECLARE
           v_id BIGINT;
       BEGIN
           IF p_channel NOT IN ('lgsp', 'cp') THEN
               RETURN QUERY SELECT FALSE, 'channel phải là lgsp hoặc cp'::TEXT, NULL::BIGINT;
               RETURN;
           END IF;
           IF p_direction NOT IN ('send', 'receive') THEN
               RETURN QUERY SELECT FALSE, 'direction phải là send hoặc receive'::TEXT, NULL::BIGINT;
               RETURN;
           END IF;

           -- INSERT dùng ĐÚNG tên cột DB: outgoing_doc_id, incoming_doc_id, edxml_content
           INSERT INTO edoc.lgsp_tracking(
               outgoing_doc_id, incoming_doc_id, direction,
               dest_org_code, dest_org_name, edxml_content,
               channel, status, created_by, created_at
           )
           VALUES (
               p_outgoing_doc_id, p_incoming_doc_id, p_direction,
               p_dest_org_code, p_dest_org_name, p_edxml_content,
               p_channel, 'pending', p_created_by, NOW()
           )
           RETURNING edoc.lgsp_tracking.id INTO v_id;

           RETURN QUERY SELECT TRUE, 'Đã log tracking record'::TEXT, v_id;
       END;
       $$;
       ```

    3. Chạy migration + test:
       ```bash
       docker cp e_office_app_new/database/migrations/quick_260418_jsd_truc_cp.sql qlvb_postgres:/tmp/
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -f /tmp/quick_260418_jsd_truc_cp.sql
       # Verify cột channel
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\d edoc.lgsp_tracking" | grep channel
       # Test SP mới — cp channel:
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT * FROM edoc.fn_lgsp_tracking_create((SELECT id FROM edoc.outgoing_docs LIMIT 1), NULL, 'send', 'CP.VPCP', 'Văn phòng Chính phủ', NULL, 1, 'cp');"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT id, channel, direction, dest_org_name, outgoing_doc_id FROM edoc.lgsp_tracking WHERE channel='cp' ORDER BY id DESC LIMIT 1;"
       # Test SP cũ (không pass p_channel) — phải default 'lgsp':
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT * FROM edoc.fn_lgsp_tracking_create((SELECT id FROM edoc.outgoing_docs LIMIT 1), NULL, 'send', 'TEST.LGSP', 'Test LGSP', NULL, 1);"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT channel FROM edoc.lgsp_tracking WHERE dest_org_code='TEST.LGSP' LIMIT 1;"
       # Expect: channel='lgsp'
       ```

    **Wave 2 — Backend: repo method MỚI + update method CŨ để pass 'lgsp' explicit.**

    4. Update `e_office_app_new/backend/src/repositories/outgoing-doc.repository.ts`:
       - **Đọc file trước** để thấy method `sendLgsp` hiện tại (gọi `edoc.fn_lgsp_tracking_create`).
       - **Update `sendLgsp`**: truyền `'lgsp'` ở param cuối để khớp signature mới:
         ```typescript
         async sendLgsp(docId: number, destOrgCode: string, destOrgName: string, createdBy: number) {
           return callFunctionOne(
             'edoc.fn_lgsp_tracking_create',
             [docId, null, 'send', destOrgCode, destOrgName, null, createdBy, 'lgsp']  // THÊM 'lgsp'
           );
         },
         ```
       - **ADD method `sendCp`** mới (truyền 'cp'):
         ```typescript
         async sendCp(docId: number, destOrgCode: string, destOrgName: string, createdBy: number): Promise<{ success: boolean; message: string; id: number | null } | null> {
           return callFunctionOne(
             'edoc.fn_lgsp_tracking_create',
             [docId, null, 'send', destOrgCode, destOrgName, null, createdBy, 'cp']
           );
         },
         ```

    5. Update `e_office_app_new/backend/src/routes/outgoing-doc.ts`:
       - Thêm route sau `/gui-lien-thong`:
         ```typescript
         router.post('/:id/gui-truc-cp', authenticate, async (req: AuthRequest, res, next) => {
           try {
             const docId = Number(req.params.id);
             if (!Number.isInteger(docId) || docId <= 0) {
               return res.status(400).json({ message: 'ID không hợp lệ' });
             }
             const orgCodes = req.body?.org_codes;
             if (!Array.isArray(orgCodes) || orgCodes.length === 0) {
               return res.status(400).json({ message: 'Vui lòng chọn ít nhất 1 bộ/ngành' });
             }
             // TODO Phase 2: tích hợp API trục CP thực — hiện chỉ mock log tracking record
             const results = [];
             for (const org of orgCodes) {
               if (!org?.code || !org?.name) continue;
               const r = await outgoingDocRepository.sendCp(docId, String(org.code), String(org.name), req.user!.staffId);
               results.push(r);
             }
             res.json({ success: true, message: `Đã gửi ${results.length} bộ/ngành CP (mock)`, count: results.length });
           } catch (err) { handleDbError(err, res, next); }
         });
         ```

    **Wave 3 — Frontend: button + Modal chọn bộ/ngành hardcode.**

    6. Update `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx`:
       - **Đọc file trước** để thấy khối Modal LGSP hiện có (`lgspModalOpen`, `handleSendLgsp`).
       - Hardcode constant đầu file:
         ```typescript
         const CP_ORGANIZATIONS = [
           { code: 'CP.VPCP', name: 'Văn phòng Chính phủ' },
           { code: 'CP.BNV', name: 'Bộ Nội vụ' },
           { code: 'CP.BTC', name: 'Bộ Tài chính' },
           { code: 'CP.BTP', name: 'Bộ Tư pháp' },
           { code: 'CP.BGDDT', name: 'Bộ Giáo dục và Đào tạo' },
           { code: 'CP.BYT', name: 'Bộ Y tế' },
           { code: 'CP.BCT', name: 'Bộ Công Thương' },
           { code: 'CP.BTNMT', name: 'Bộ Tài nguyên và Môi trường' },
         ];
         ```
       - State:
         ```typescript
         const [cpModalOpen, setCpModalOpen] = useState(false);
         const [cpSelected, setCpSelected] = useState<string[]>([]);
         const [cpSending, setCpSending] = useState(false);
         ```
       - Button (sau button "Gửi liên thông", conditional `doc?.approved`):
         ```tsx
         {doc?.approved && (
           <Button
             style={{ background: '#059669', borderColor: '#059669', color: '#fff' }}
             icon={<CloudUploadOutlined />}
             onClick={() => { setCpModalOpen(true); setCpSelected([]); }}
           >
             Gửi trục CP
           </Button>
         )}
         ```
       - Modal (dùng `width`, không `size` — vì là Modal):
         ```tsx
         <Modal
           open={cpModalOpen}
           title="Gửi trục Chính phủ"
           okText="Gửi"
           cancelText="Hủy"
           confirmLoading={cpSending}
           onCancel={() => setCpModalOpen(false)}
           onOk={handleSendCp}
         >
           <p>Chọn các bộ/ngành Chính phủ để gửi văn bản:</p>
           <Checkbox.Group
             value={cpSelected}
             onChange={(vals) => setCpSelected(vals as string[])}
             style={{ display: 'flex', flexDirection: 'column', gap: 8 }}
           >
             {CP_ORGANIZATIONS.map(org => (
               <Checkbox key={org.code} value={org.code}>{org.name}</Checkbox>
             ))}
           </Checkbox.Group>
         </Modal>
         ```
       - Handler:
         ```typescript
         const handleSendCp = async () => {
           if (cpSelected.length === 0) {
             message.warning('Vui lòng chọn ít nhất 1 bộ/ngành');
             return;
           }
           setCpSending(true);
           try {
             const orgCodes = cpSelected
               .map(code => CP_ORGANIZATIONS.find(o => o.code === code))
               .filter(Boolean)
               .map(o => ({ code: o!.code, name: o!.name }));
             const res = await api.post(`/van-ban-di/${id}/gui-truc-cp`, { org_codes: orgCodes });
             message.success(res.data?.message || 'Đã gửi trục CP');
             setCpModalOpen(false);
             setCpSelected([]);
             fetchDetail();
           } catch (err: any) {
             message.error(err.response?.data?.message || 'Gửi thất bại');
           } finally {
             setCpSending(false);
           }
         };
         ```
       - Import `Checkbox` từ antd, `CloudUploadOutlined` từ `@ant-design/icons`.

    **Verification sau task:**
    - Type-check BE + FE pass.
    - DB: `SELECT channel, COUNT(*) FROM edoc.lgsp_tracking GROUP BY channel;` — có row channel='cp' và 'lgsp'.
    - Manual: VB đi detail approved → nhấn "Gửi liên thông" (cũ) vẫn work (channel='lgsp' default) + nhấn "Gửi trục CP" → Modal → chọn 2-3 bộ → Gửi → success message.
    - Check DB: `SELECT outgoing_doc_id, channel, dest_org_name FROM edoc.lgsp_tracking ORDER BY id DESC LIMIT 5;` → thấy rows cp + lgsp.

    **Commit:** `feat: thêm chức năng gửi trục CP (mock) cho VB đi — HDSD II.3.8`
  </action>
  <verify>
    <automated>
      cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tail -20 &&
      cd ../frontend && npx tsc --noEmit 2>&1 | tail -20 &&
      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT column_name FROM information_schema.columns WHERE table_schema='edoc' AND table_name='lgsp_tracking' AND column_name='channel';" &&
      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT conname FROM pg_constraint WHERE conname='lgsp_tracking_channel_check';"
    </automated>
  </verify>
  <done>
    - Cột channel exists trên edoc.lgsp_tracking với CHECK constraint ('lgsp','cp').
    - SP fn_lgsp_tracking_create signature mới: (p_outgoing_doc_id, p_incoming_doc_id, p_direction, p_dest_org_code, p_dest_org_name, p_edxml_content, p_created_by, p_channel) — 8 params.
    - SP INSERT dùng ĐÚNG cột DB: outgoing_doc_id, incoming_doc_id, edxml_content.
    - Route POST /api/van-ban-di/:id/gui-truc-cp mount với comment `// TODO Phase 2`.
    - outgoingDocRepository.sendCp() method thêm, sendLgsp() cập nhật truyền 'lgsp' explicit.
    - VB đi detail có button "Gửi trục CP" + Modal với 8 bộ/ngành hardcode + Checkbox.Group.
    - Manual test: LGSP hiện có vẫn work (channel='lgsp'); gửi trục CP → DB row channel='cp' tạo mới.
    - Type-check BE + FE pass.
    - Commit: `feat: thêm chức năng gửi trục CP (mock) cho VB đi — HDSD II.3.8`.
  </done>
</task>

<task type="auto">
  <name>Task 3: Gap C (TC-046) — Mở rộng form chuyển lưu trữ VB đi + 2 endpoint dropdowns</name>
  <files>
    e_office_app_new/backend/src/routes/outgoing-doc.ts,
    e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx
  </files>
  <action>
    **Task có 2 phần: (A) Backend mirror 2 endpoint dropdown + (B) FE Drawer copy từ VB đến.**

    **Phần A — Backend: mirror pattern van-ban-den sang van-ban-di.**

    1. **Đọc** `e_office_app_new/backend/src/routes/incoming-doc.ts` từ line 810-830 để lấy exact code pattern:
       ```typescript
       router.get('/:id/luu-tru/phong', async (req: Request, res: Response) => { ... });
       router.get('/:id/luu-tru/kho', async (req: Request, res: Response) => { ... });
       ```
       - Đọc helper `resolveAncestorUnit(departmentId)` — nếu local trong file thì EXPORT (`export async function resolveAncestorUnit`).
       - Đọc `incomingDocRepository.getFonds(ancestorUnitId)` + `getWarehouses(ancestorUnitId)` — đây là 2 method generic (không scoped theo doc).

    2. Update `e_office_app_new/backend/src/routes/outgoing-doc.ts`:
       - Import `resolveAncestorUnit` từ incoming-doc.ts (hoặc extract sang lib/utils nếu cleaner — quick task → import trực tiếp).
       - Import `incomingDocRepository` từ incoming-doc.repository.ts (để reuse getFonds/getWarehouses — generic, không scope theo doc type).
       - THÊM 2 endpoint MIRROR:
         ```typescript
         // Mirror pattern từ incoming-doc.ts — dropdown phòng/kho lưu trữ cho VB đi
         router.get('/:id/luu-tru/phong', authenticate, async (req, res, next) => {
           try {
             const { departmentId } = (req as AuthRequest).user!;
             const ancestorUnitId = await resolveAncestorUnit(departmentId);
             const fonds = await incomingDocRepository.getFonds(ancestorUnitId);
             res.json({ success: true, data: fonds });
           } catch (err) { handleDbError(err, res, next); }
         });

         router.get('/:id/luu-tru/kho', authenticate, async (req, res, next) => {
           try {
             const { departmentId } = (req as AuthRequest).user!;
             const ancestorUnitId = await resolveAncestorUnit(departmentId);
             const warehouses = await incomingDocRepository.getWarehouses(ancestorUnitId);
             res.json({ success: true, data: warehouses });
           } catch (err) { handleDbError(err, res, next); }
         });
         ```
       - **Note**: resolveAncestorUnit và getFonds/getWarehouses là generic (không đụng bảng incoming/outgoing) — reuse an toàn. Nếu cần scope theo module (best-practice) → vẫn OK vì data về phông/kho là shared.

    **Phần B — Frontend: copy Drawer từ VB đến.**

    3. **Đọc `e_office_app_new/frontend/src/app/(main)/van-ban-den/[id]/page.tsx`** toàn bộ section:
       - Line ~289-301: `fetchWarehouses`, `fetchFonds` (gọi `/van-ban-den/${docId}/luu-tru/...`).
       - State: `archiveOpen, archiveForm, archiving, warehouseOptions, fondOptions, archiveStatus`.
       - Functions: `handleOpenArchive()`, `handleArchive(values)`.
       - Drawer JSX (~line 876-901).

    4. Update `e_office_app_new/frontend/src/app/(main)/van-ban-di/[id]/page.tsx`:
       - Import thêm nếu chưa có: `Drawer, Row, Col, Select, InputNumber, Checkbox, Form, Input` từ antd.
       - Thêm interface `WarehouseOption { value: number; label: string }` và `FondOption` tương tự.
       - State mới:
         ```typescript
         const [archiveOpen, setArchiveOpen] = useState(false);
         const [archiveForm] = Form.useForm();
         const [archiving, setArchiving] = useState(false);
         const [warehouseOptions, setWarehouseOptions] = useState<WarehouseOption[]>([]);
         const [fondOptions, setFondOptions] = useState<FondOption[]>([]);
         ```
       - Functions (đổi endpoint thành `van-ban-di`):
         ```typescript
         const fetchWarehouses = async () => {
           try {
             const res = await api.get(`/van-ban-di/${id}/luu-tru/kho`);
             const list = res.data?.data || [];
             setWarehouseOptions(list.map((w: any) => ({ value: w.id, label: w.name })));
           } catch { setWarehouseOptions([]); }
         };
         const fetchFonds = async () => {
           try {
             const res = await api.get(`/van-ban-di/${id}/luu-tru/phong`);
             const list = res.data?.data || [];
             setFondOptions(list.map((f: any) => ({ value: f.id, label: f.name })));
           } catch { setFondOptions([]); }
         };
         const handleOpenArchive = () => {
           archiveForm.resetFields();
           archiveForm.setFieldsValue({ language: 'Tiếng Việt', format: 'Điện tử', is_original: true });
           fetchWarehouses();
           fetchFonds();
           setArchiveOpen(true);
         };
         const handleArchive = async (values: any) => {
           setArchiving(true);
           try {
             const res = await api.post(`/van-ban-di/${id}/chuyen-luu-tru`, values);
             message.success(res.data?.message || 'Đã chuyển lưu trữ');
             setArchiveOpen(false);
             fetchDetail();
           } catch (err: any) {
             message.error(err.response?.data?.message || 'Chuyển lưu trữ thất bại');
           } finally {
             setArchiving(false);
           }
         };
         ```
         - **Note**: response shape VB đến đang dùng có thể khác (flat array hay wrapped `{success, data}`). Đọc van-ban-den/[id]/page.tsx fetchWarehouses để xem exact mapping — adjust theo đó. Kiểm tra BE endpoint đã tạo ở phần A trả `{success: true, data: [...]}`.
       - Button toolbar (conditional `doc?.approved && !doc?.archive_status`):
         ```tsx
         {doc?.approved && !doc?.archive_status && (
           <Button icon={<InboxOutlined />} onClick={handleOpenArchive}>Chuyển lưu trữ</Button>
         )}
         ```
       - Drawer (copy nguyên 13 field từ VB đến ~line 876-901):
         ```tsx
         <Drawer
           title="Chuyển lưu trữ"
           size={640}
           open={archiveOpen}
           onClose={() => setArchiveOpen(false)}
           rootClassName="drawer-gradient"
           extra={
             <Space>
               <Button onClick={() => setArchiveOpen(false)}>Hủy</Button>
               <Button type="primary" loading={archiving} onClick={() => archiveForm.submit()}>Lưu</Button>
             </Space>
           }
         >
           <Form form={archiveForm} layout="vertical" onFinish={handleArchive}>
             <Row gutter={16}>
               <Col span={12}>
                 <Form.Item label="Kho lưu trữ" name="warehouse_id" rules={[{ required: true, message: 'Chọn kho' }]}>
                   <Select options={warehouseOptions} placeholder="Chọn kho" />
                 </Form.Item>
               </Col>
               <Col span={12}>
                 <Form.Item label="Phông lưu trữ" name="fond_id" rules={[{ required: true, message: 'Chọn phông' }]}>
                   <Select options={fondOptions} placeholder="Chọn phông" />
                 </Form.Item>
               </Col>
             </Row>
             {/* 11 field còn lại: record_id, file_catalog, file_notation, doc_ordinal, language, autograph, keyword, format, confidence_level, is_original. COPY CHÍNH XÁC từ VB đến — giữ nguyên maxLength và required rules. */}
             {/* VERIFY maxLength từng field = VARCHAR(N) bằng \d esto.document_archives. */}
           </Form>
         </Drawer>
         ```
       - **QUAN TRỌNG:** copy chính xác 13 field từ VB đến — KHÔNG thêm/bớt. Giữ nguyên `rules required` và `initialValues`.

    **Verification sau task:**
    - BE + FE type-check pass.
    - Manual test endpoint:
      - `curl -H "Authorization: Bearer <token>" http://localhost:4000/api/van-ban-di/1/luu-tru/phong` → JSON {success, data: [...]}.
      - Tương tự `/luu-tru/kho`.
    - Manual: VB đi detail approved + chưa lưu trữ → nhấn "Chuyển lưu trữ" → Drawer mở với defaults (Tiếng Việt, Điện tử, is_original=true) + dropdown có data → nhập đầy đủ → Lưu → success → `archive_status=true`.
    - DB: `SELECT * FROM esto.document_archives WHERE doc_type='outgoing' AND doc_id=<X>` — row tồn tại.

    **Commit:** `feat: mở rộng form chuyển lưu trữ VB đi với phòng/kho — HDSD II.3.9`
  </action>
  <verify>
    <automated>
      cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tail -20 &&
      cd ../frontend && npx tsc --noEmit 2>&1 | tail -20 &&
      grep -c "luu-tru/phong\|luu-tru/kho" e_office_app_new/backend/src/routes/outgoing-doc.ts &&
      grep -c "archiveOpen\|chuyen-luu-tru" e_office_app_new/frontend/src/app/\(main\)/van-ban-di/\[id\]/page.tsx
    </automated>
  </verify>
  <done>
    - Backend có 2 route mới: GET /api/van-ban-di/:id/luu-tru/phong + GET /api/van-ban-di/:id/luu-tru/kho (mirror pattern van-ban-den).
    - resolveAncestorUnit + incomingDocRepository.getFonds/getWarehouses reused (generic).
    - VB đi detail có button "Chuyển lưu trữ" conditional (approved && !archive_status).
    - Drawer size=640 với đầy đủ 13 field khớp VB đến.
    - Defaults initial: language='Tiếng Việt', format='Điện tử', is_original=true.
    - maxLength từng Input khớp DB VARCHAR(N).
    - fetchWarehouses/fetchFonds gọi 2 endpoint scoped `/van-ban-di/${id}/luu-tru/*`.
    - Manual test: dropdowns load data; lưu trữ thành công → Tag trạng thái đổi.
    - BE + FE type-check pass.
    - Commit: `feat: mở rộng form chuyển lưu trữ VB đi với phòng/kho — HDSD II.3.9`.
  </done>
</task>

<task type="auto">
  <name>Task 4: Gap D (TC-066) — Hủy HSCV action riêng với lý do</name>
  <files>
    e_office_app_new/database/migrations/quick_260418_jsd_hscv_cancel.sql,
    e_office_app_new/backend/src/repositories/handling-doc.repository.ts,
    e_office_app_new/backend/src/routes/handling-doc.ts,
    e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx
  </files>
  <action>
    **Wave 1 — DB: ALTER handling_docs + CREATE fn_handling_doc_cancel + DROP/CREATE fn_handling_doc_get_by_id.**
    **Reminder: handling_docs.id BIGSERIAL → p_id BIGINT. staff.id SERIAL → p_user_id INT.**

    1. VERIFY trước — **COPY exact 33 field cũ từ fn_handling_doc_get_by_id**:
       ```bash
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\d edoc.handling_docs" | grep -E "status|curator|cancel"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname='edoc' AND p.proname='fn_handling_doc_get_by_id';"
       ```
       - **CHECKLIST** expected 33+ fields bao gồm từ hlj: `number integer, sub_number character varying, doc_notation character varying, doc_book_id integer, doc_book_name character varying`. Ghi chú lại full list trước khi DROP.

    2. Tạo `e_office_app_new/database/migrations/quick_260418_jsd_hscv_cancel.sql`:
       ```sql
       -- Gap D (TC-066): HSCV hủy action riêng với lý do

       -- 1. ALTER handling_docs: thêm 3 cột audit hủy
       ALTER TABLE edoc.handling_docs
         ADD COLUMN IF NOT EXISTS cancel_reason TEXT,
         ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMPTZ,
         ADD COLUMN IF NOT EXISTS cancelled_by INT;

       -- 2. SP fn_handling_doc_cancel
       CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_cancel(
           p_id BIGINT,
           p_user_id INT,
           p_reason TEXT
       )
       RETURNS TABLE(success BOOLEAN, message TEXT)
       LANGUAGE plpgsql
       SECURITY DEFINER
       AS $$
       DECLARE
           v_status SMALLINT;
       BEGIN
           IF p_reason IS NULL OR LENGTH(TRIM(p_reason)) = 0 THEN
               RETURN QUERY SELECT FALSE, 'Vui lòng nhập lý do hủy'::TEXT;
               RETURN;
           END IF;

           SELECT h.status INTO v_status FROM edoc.handling_docs h WHERE h.id = p_id;
           IF NOT FOUND THEN
               RETURN QUERY SELECT FALSE, 'Không tìm thấy hồ sơ công việc'::TEXT;
               RETURN;
           END IF;
           IF v_status = -3 THEN
               RETURN QUERY SELECT FALSE, 'HSCV đã hủy trước đó'::TEXT;
               RETURN;
           END IF;
           IF v_status = 4 THEN
               RETURN QUERY SELECT FALSE, 'HSCV đã hoàn thành, không thể hủy'::TEXT;
               RETURN;
           END IF;

           UPDATE edoc.handling_docs
           SET status = -3,
               cancel_reason = p_reason,
               cancelled_at = NOW(),
               cancelled_by = p_user_id,
               updated_at = NOW()
           WHERE id = p_id;

           RETURN QUERY SELECT TRUE, 'Đã hủy hồ sơ công việc'::TEXT;
       END;
       $$;

       -- 3. DROP/CREATE fn_handling_doc_get_by_id:
       --    COPY ĐẦY ĐỦ 33 field cũ (expect: id, unit_id, unit_name, department_id, department_name,
       --    name, abstract, comments, doc_notation, doc_type_id, doc_type_name, doc_field_id, doc_field_name,
       --    start_date, end_date, curator_id, curator_name, signer_id, signer_name, status, progress,
       --    workflow_id, workflow_name, parent_id, parent_name, is_from_doc, created_by, created_at, updated_at,
       --    number, sub_number, doc_book_id, doc_book_name)
       --    + THÊM 3 field cuối: cancel_reason TEXT, cancelled_at TIMESTAMPTZ, cancelled_by INT
       DROP FUNCTION IF EXISTS edoc.fn_handling_doc_get_by_id(BIGINT);

       CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_get_by_id(p_id BIGINT)
       RETURNS TABLE(
           -- ===== COPY ĐẦY ĐỦ 33 field từ pg_get_functiondef output =====
           -- Executor: paste exact RETURNS TABLE từ \df+ (bao gồm curator_id, doc_book_id, etc.).
           -- KHÔNG rename, KHÔNG xoá, KHÔNG đảo thứ tự.
           -- Thêm 3 field cuối:
           cancel_reason TEXT,
           cancelled_at TIMESTAMPTZ,
           cancelled_by INT
       )
       LANGUAGE plpgsql
       AS $$
       BEGIN
           RETURN QUERY
           SELECT
               -- ===== COPY SELECT cũ 33 field (incl. JOIN doc_books, staff curator/signer, workflows, etc.) =====
               h.cancel_reason,
               h.cancelled_at,
               h.cancelled_by
           FROM edoc.handling_docs h
           -- ===== GIỮ NGUYÊN các JOIN từ SP cũ: doc_types, doc_fields, staff curator, staff signer, workflows, doc_books, parent handling_doc =====
           WHERE h.id = p_id;
       END;
       $$;
       ```
       **HƯỚNG DẪN executor:** Paste EXACT RETURNS TABLE + SELECT + JOINs từ `pg_get_functiondef` output. KHÔNG đoán — expect 33 field. Test sau DROP/CREATE: `SELECT COUNT(*) FROM (SELECT * FROM edoc.fn_handling_doc_get_by_id(1) LIMIT 1) x;` → 36 cột (33 + 3 mới).

    3. Chạy migration + test:
       ```bash
       docker cp e_office_app_new/database/migrations/quick_260418_jsd_hscv_cancel.sql qlvb_postgres:/tmp/
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -f /tmp/quick_260418_jsd_hscv_cancel.sql
       # Verify SP signature: 36 fields expected
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\df+ edoc.fn_handling_doc_get_by_id"
       # Test cancel
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT * FROM edoc.fn_handling_doc_cancel(1, 1, 'Lý do test hủy');"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT id, status, cancel_reason, cancelled_by FROM edoc.handling_docs WHERE id=1;"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT id, status, cancel_reason, number FROM edoc.fn_handling_doc_get_by_id(1);"
       # Reset cho dev sau test:
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "UPDATE edoc.handling_docs SET status=1, cancel_reason=NULL, cancelled_at=NULL, cancelled_by=NULL WHERE id=1;"
       ```

    **Wave 2 — Backend: repo method + route endpoint.**

    4. Update `e_office_app_new/backend/src/repositories/handling-doc.repository.ts`:
       - **Đọc file để lấy Row interface `HscvDetailRow`**, thêm 3 field:
         ```typescript
         cancel_reason: string | null;
         cancelled_at: string | null;
         cancelled_by: number | null;
         ```
       - Thêm method:
         ```typescript
         async cancel(id: number, userId: number, reason: string): Promise<{ success: boolean; message: string } | null> {
           return callFunctionOne('edoc.fn_handling_doc_cancel', [id, userId, reason]);
         },
         ```

    5. Update `e_office_app_new/backend/src/routes/handling-doc.ts`:
       - Thêm route sau `/lay-so` (từ task hlj):
         ```typescript
         router.post('/:id/huy', authenticate, async (req: AuthRequest, res, next) => {
           try {
             const id = Number(req.params.id);
             const reason = String(req.body?.reason || '').trim();
             if (!Number.isInteger(id) || id <= 0) {
               return res.status(400).json({ message: 'ID không hợp lệ' });
             }
             if (!reason) {
               return res.status(400).json({ message: 'Vui lòng nhập lý do hủy' });
             }
             const result = await handlingDocRepository.cancel(id, req.user!.staffId, reason);
             if (!result?.success) {
               return res.status(400).json({ message: result?.message || 'Hủy thất bại' });
             }
             res.json({ success: true, message: result.message });
           } catch (err) { handleDbError(err, res, next); }
         });
         ```

    **Wave 3 — Frontend: thay button "Hủy HSCV" + Modal nhập lý do + Card hiển thị khi status=-3.**

    6. Update `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`:
       - **Đọc file trước** để thấy `getToolbarButtons`, `handleChangeStatus`, interface `HscvDetail`.
       - Bổ sung interface HscvDetail: `cancel_reason?: string | null; cancelled_at?: string | null; cancelled_by?: number | null;` (cancelled_by_name defer — hiển thị ID nếu không có JOIN).
       - State:
         ```typescript
         const [cancelOpen, setCancelOpen] = useState(false);
         const [cancelReason, setCancelReason] = useState('');
         const [cancelling, setCancelling] = useState(false);
         ```
       - Trong `getToolbarButtons`, khi case -1 HOẶC -2, THAY thế button "Hủy HSCV" cũ (dùng `/trang-thai`):
         ```tsx
         {(detail?.status === -1 || detail?.status === -2) && (
           <Button danger icon={<CloseCircleOutlined />} onClick={() => { setCancelReason(''); setCancelOpen(true); }}>
             Hủy HSCV
           </Button>
         )}
         ```
       - Handler:
         ```typescript
         const handleCancel = async () => {
           if (!cancelReason.trim()) {
             message.warning('Vui lòng nhập lý do hủy');
             return;
           }
           setCancelling(true);
           try {
             const res = await api.post(`/ho-so-cong-viec/${id}/huy`, { reason: cancelReason.trim() });
             message.success(res.data?.message || 'Đã hủy HSCV');
             setCancelOpen(false);
             setCancelReason('');
             fetchDetail();
           } catch (err: any) {
             message.error(err.response?.data?.message || 'Hủy thất bại');
           } finally {
             setCancelling(false);
           }
         };
         ```
       - Modal:
         ```tsx
         <Modal
           open={cancelOpen}
           title="Hủy hồ sơ công việc"
           okText="Xác nhận hủy"
           cancelText="Hủy thao tác"
           okButtonProps={{ danger: true }}
           confirmLoading={cancelling}
           onCancel={() => { setCancelOpen(false); setCancelReason(''); }}
           onOk={handleCancel}
         >
           <Form layout="vertical">
             <Form.Item label="Lý do hủy HSCV" required>
               <Input.TextArea
                 rows={4}
                 maxLength={1000}
                 showCount
                 value={cancelReason}
                 onChange={(e) => setCancelReason(e.target.value)}
                 placeholder="Nhập lý do hủy HSCV..."
               />
             </Form.Item>
           </Form>
         </Modal>
         ```
       - Card hiển thị khi status=-3 (trên detail, sau Card info chính):
         ```tsx
         {detail?.status === -3 && detail?.cancel_reason && (
           <Card title="Thông tin hủy" style={{ marginTop: 16 }} size="small" styles={{ header: { background: '#FEF2F2' } }}>
             <p><strong>Lý do:</strong> {detail.cancel_reason}</p>
             <p><strong>Thời điểm:</strong> {detail.cancelled_at ? dayjs(detail.cancelled_at).format('DD/MM/YYYY HH:mm') : '—'}</p>
             <p><strong>Người hủy:</strong> ID {detail.cancelled_by || '—'}</p>
           </Card>
         )}
         ```

    **Verification sau task:**
    - Type-check BE + FE pass.
    - DB: `SELECT column_name FROM information_schema.columns WHERE table_schema='edoc' AND table_name='handling_docs' AND column_name LIKE 'cancel%';` — 3 cột.
    - DB: `\df+ edoc.fn_handling_doc_get_by_id` → 36 field (33 + 3 cancel_*).
    - Manual: HSCV status=-1 → nút "Hủy HSCV" → Modal → nhập lý do → Xác nhận → status=-3, Card hiển thị lý do.

    **Commit:** `feat: thêm endpoint + button hủy HSCV riêng — HDSD III.2.5`
  </action>
  <verify>
    <automated>
      cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tail -20 &&
      cd ../frontend && npx tsc --noEmit 2>&1 | tail -20 &&
      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT column_name FROM information_schema.columns WHERE table_schema='edoc' AND table_name='handling_docs' AND column_name IN ('cancel_reason','cancelled_at','cancelled_by');" &&
      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT proname FROM pg_proc WHERE proname='fn_handling_doc_cancel';"
    </automated>
  </verify>
  <done>
    - 3 cột cancel_* exist trên edoc.handling_docs.
    - SP fn_handling_doc_cancel exists, reject reason rỗng, reject status=4/-3.
    - SP fn_handling_doc_get_by_id DROP/CREATE với 36 field (33 cũ + 3 mới, GIỮ đầy đủ number/sub_number/doc_notation/doc_book_id/doc_book_name từ hlj).
    - Route POST /api/ho-so-cong-viec/:id/huy mount.
    - HSCV status=-1/-2 có button "Hủy HSCV" mở Modal required reason.
    - Card "Thông tin hủy" hiển thị khi status=-3.
    - Manual test: hủy → status=-3 + cancel_reason persisted.
    - Type-check BE + FE pass.
    - Commit: `feat: thêm endpoint + button hủy HSCV riêng — HDSD III.2.5`.
  </done>
</task>

<task type="auto">
  <name>Task 5: Gap E (TC-067) — Chuyển tiếp ý kiến HSCV + staff picker endpoint mới</name>
  <files>
    e_office_app_new/database/migrations/quick_260418_jsd_opinion_forward.sql,
    e_office_app_new/backend/src/repositories/handling-doc.repository.ts,
    e_office_app_new/backend/src/routes/handling-doc.ts,
    e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx
  </files>
  <action>
    **Task này CÓ THÊM: tạo endpoint staff picker mới (`GET /api/ho-so-cong-viec/nhan-vien-cung-don-vi`) để bypass RBAC block của `/api/quan-tri`. Task 6 sẽ reuse endpoint này.**

    **Wave 1 — DB: ALTER opinion_handling_docs + CREATE fn_opinion_forward + DROP/CREATE fn_opinion_get_list.**
    **Reminder: opinion_handling_docs.id BIGSERIAL → p_id BIGINT. Param SP cũ `p_doc_id` (không đổi tên).**

    1. VERIFY trước:
       ```bash
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\d edoc.opinion_handling_docs"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT pg_get_functiondef(p.oid) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE n.nspname='edoc' AND p.proname='fn_opinion_get_list';"
       ```
       - **Xác nhận signature cũ**: `p_doc_id bigint`, RETURNS TABLE(id, staff_id, staff_name TEXT, content, attachment_path, created_at), body dùng `CONCAT(s.last_name, ' ', s.first_name)::TEXT`.

    2. Tạo `e_office_app_new/database/migrations/quick_260418_jsd_opinion_forward.sql`:
       ```sql
       -- Gap E (TC-067): Chuyển tiếp ý kiến HSCV

       -- 1. ALTER: thêm 4 cột forward
       ALTER TABLE edoc.opinion_handling_docs
         ADD COLUMN IF NOT EXISTS forwarded_to_staff_id INT,
         ADD COLUMN IF NOT EXISTS forwarded_at TIMESTAMPTZ,
         ADD COLUMN IF NOT EXISTS forward_note TEXT,
         ADD COLUMN IF NOT EXISTS parent_opinion_id BIGINT;

       -- Thêm FK self-reference (ON DELETE SET NULL — giữ forward history)
       DO $$
       BEGIN
           IF NOT EXISTS (
               SELECT 1 FROM pg_constraint WHERE conname = 'fk_opinion_parent'
           ) THEN
               ALTER TABLE edoc.opinion_handling_docs
                 ADD CONSTRAINT fk_opinion_parent
                 FOREIGN KEY (parent_opinion_id)
                 REFERENCES edoc.opinion_handling_docs(id)
                 ON DELETE SET NULL;
           END IF;
       END $$;

       -- 2. SP fn_opinion_forward
       CREATE OR REPLACE FUNCTION edoc.fn_opinion_forward(
           p_opinion_id BIGINT,
           p_from_staff_id INT,
           p_to_staff_id INT,
           p_note TEXT
       )
       RETURNS TABLE(success BOOLEAN, message TEXT, id BIGINT)
       LANGUAGE plpgsql
       SECURITY DEFINER
       AS $$
       DECLARE
           v_handling_doc_id BIGINT;
           v_to_exists BOOLEAN;
           v_new_id BIGINT;
       BEGIN
           IF p_note IS NULL OR LENGTH(TRIM(p_note)) = 0 THEN
               RETURN QUERY SELECT FALSE, 'Vui lòng nhập nội dung chuyển tiếp'::TEXT, NULL::BIGINT;
               RETURN;
           END IF;

           SELECT o.handling_doc_id INTO v_handling_doc_id
             FROM edoc.opinion_handling_docs o
             WHERE o.id = p_opinion_id;
           IF NOT FOUND THEN
               RETURN QUERY SELECT FALSE, 'Không tìm thấy ý kiến gốc'::TEXT, NULL::BIGINT;
               RETURN;
           END IF;

           SELECT EXISTS(
               SELECT 1 FROM public.staff s
               WHERE s.id = p_to_staff_id
                 AND COALESCE(s.is_locked, FALSE) = FALSE
                 AND COALESCE(s.is_deleted, FALSE) = FALSE
           ) INTO v_to_exists;
           IF NOT v_to_exists THEN
               RETURN QUERY SELECT FALSE, 'Không tìm thấy người nhận hoặc đã khóa/xoá'::TEXT, NULL::BIGINT;
               RETURN;
           END IF;

           INSERT INTO edoc.opinion_handling_docs(
               handling_doc_id, staff_id, content, created_at,
               forwarded_to_staff_id, forwarded_at, forward_note, parent_opinion_id
           )
           VALUES (
               v_handling_doc_id, p_from_staff_id, p_note, NOW(),
               p_to_staff_id, NOW(), p_note, p_opinion_id
           )
           RETURNING edoc.opinion_handling_docs.id INTO v_new_id;

           RETURN QUERY SELECT TRUE, 'Đã chuyển tiếp ý kiến'::TEXT, v_new_id;
       END;
       $$;

       -- 3. DROP/CREATE fn_opinion_get_list — GIỮ param name cũ p_doc_id, GIỮ staff_name TEXT
       DROP FUNCTION IF EXISTS edoc.fn_opinion_get_list(BIGINT);

       CREATE OR REPLACE FUNCTION edoc.fn_opinion_get_list(p_doc_id BIGINT)
       RETURNS TABLE(
           -- 6 field cũ (GIỮ NGUYÊN):
           id BIGINT,
           staff_id INT,
           staff_name TEXT,
           content TEXT,
           attachment_path VARCHAR,
           created_at TIMESTAMPTZ,
           -- 5 field MỚI:
           forwarded_to_staff_id INT,
           forwarded_to_name TEXT,
           forwarded_at TIMESTAMPTZ,
           forward_note TEXT,
           parent_opinion_id BIGINT
       )
       LANGUAGE plpgsql
       AS $$
       BEGIN
           RETURN QUERY
           SELECT
               o.id,
               o.staff_id,
               CONCAT(s.last_name, ' ', s.first_name)::TEXT AS staff_name,
               o.content,
               o.attachment_path,
               o.created_at,
               o.forwarded_to_staff_id,
               CASE
                   WHEN ts.id IS NOT NULL THEN CONCAT(ts.last_name, ' ', ts.first_name)::TEXT
                   ELSE NULL::TEXT
               END AS forwarded_to_name,
               o.forwarded_at,
               o.forward_note,
               o.parent_opinion_id
           FROM edoc.opinion_handling_docs o
           JOIN public.staff s ON s.id = o.staff_id
           LEFT JOIN public.staff ts ON ts.id = o.forwarded_to_staff_id
           WHERE o.handling_doc_id = p_doc_id
           ORDER BY o.created_at ASC;
       END;
       $$;
       ```

    3. Chạy migration + test:
       ```bash
       docker cp e_office_app_new/database/migrations/quick_260418_jsd_opinion_forward.sql qlvb_postgres:/tmp/
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -f /tmp/quick_260418_jsd_opinion_forward.sql
       # Verify
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\df+ edoc.fn_opinion_get_list"
       # Test
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "INSERT INTO edoc.opinion_handling_docs(handling_doc_id, staff_id, content, created_at) VALUES (1, 1, 'Ý kiến gốc test', NOW()) RETURNING id;"
       # Giả sử id=X, test forward:
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT * FROM edoc.fn_opinion_forward(X, 1, 2, 'Chuyển để xem xét');"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT id, staff_name, content, forwarded_to_staff_id, forwarded_to_name, parent_opinion_id FROM edoc.fn_opinion_get_list(1) ORDER BY id DESC LIMIT 3;"
       ```

    **Wave 2 — Backend: endpoint staff picker MỚI + repo method + route endpoint forward.**

    4. Update `e_office_app_new/backend/src/repositories/handling-doc.repository.ts`:
       - Bổ sung interface `OpinionRow` với 11 field (6 cũ + 5 forward_*):
         ```typescript
         export interface OpinionRow {
           id: number;
           staff_id: number;
           staff_name: string;
           content: string;
           attachment_path: string | null;
           created_at: string;
           forwarded_to_staff_id: number | null;
           forwarded_to_name: string | null;
           forwarded_at: string | null;
           forward_note: string | null;
           parent_opinion_id: number | null;
         }
         ```
       - Thêm method:
         ```typescript
         async forwardOpinion(opinionId: number, fromStaffId: number, toStaffId: number, note: string): Promise<{ success: boolean; message: string; id: number | null } | null> {
           return callFunctionOne('edoc.fn_opinion_forward', [opinionId, fromStaffId, toStaffId, note]);
         },
         async listStaffSameUnit(unitId: number): Promise<Array<{ id: number; full_name: string; username: string; department_id: number }>> {
           return rawQuery(
             `SELECT id, full_name, username, department_id
              FROM public.staff
              WHERE unit_id = $1 AND is_locked = FALSE AND is_deleted = FALSE
              ORDER BY full_name ASC`,
             [unitId]
           );
         },
         ```

    5. Update `e_office_app_new/backend/src/routes/handling-doc.ts`:
       - **ENDPOINT STAFF PICKER MỚI** (mount trước các route có :id param để không bị catch):
         ```typescript
         // MỚI — bypass RBAC /api/quan-tri. Chỉ authenticate. Dùng cho Task 5 (forward opinion) + Task 6 (transfer HSCV).
         router.get('/nhan-vien-cung-don-vi', authenticate, async (req: AuthRequest, res, next) => {
           try {
             const unitId = req.user!.unitId;
             if (!Number.isInteger(unitId) || unitId <= 0) {
               return res.status(400).json({ message: 'Không xác định được đơn vị' });
             }
             const list = await handlingDocRepository.listStaffSameUnit(unitId);
             res.json({ data: list });
           } catch (err) { handleDbError(err, res, next); }
         });
         ```
         **QUAN TRỌNG**: route PHẢI mount TRƯỚC các route có pattern `/:id/...` (ví dụ `/:id/y-kien`) để Express khớp exact string `/nhan-vien-cung-don-vi` trước khi bị catch bởi `/:id`. Đọc handling-doc.ts và đặt TRƯỚC `router.get('/', ...)` hoặc ngay sau import block.

       - **ENDPOINT FORWARD OPINION**:
         ```typescript
         router.post('/:id/y-kien/:opinionId/chuyen-tiep', authenticate, async (req: AuthRequest, res, next) => {
           try {
             const opinionId = Number(req.params.opinionId);
             const toStaffId = Number(req.body?.to_staff_id);
             const note = String(req.body?.note || '').trim();
             if (!Number.isInteger(opinionId) || opinionId <= 0) {
               return res.status(400).json({ message: 'ID ý kiến không hợp lệ' });
             }
             if (!Number.isInteger(toStaffId) || toStaffId <= 0) {
               return res.status(400).json({ message: 'Vui lòng chọn người nhận' });
             }
             if (!note) {
               return res.status(400).json({ message: 'Vui lòng nhập nội dung chuyển tiếp' });
             }
             const result = await handlingDocRepository.forwardOpinion(opinionId, req.user!.staffId, toStaffId, note);
             if (!result?.success) {
               return res.status(400).json({ message: result?.message || 'Chuyển tiếp thất bại' });
             }
             res.json({ success: true, message: result.message, id: result.id });
           } catch (err) { handleDbError(err, res, next); }
         });
         ```

    **Wave 3 — Frontend: nút "Chuyển tiếp" trên opinion-item + Modal + thread indent.**

    6. Update `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`:
       - **Đọc file trước** — tab "Ý kiến xử lý" (~line 1360+).
       - Bổ sung interface Opinion: `forwarded_to_staff_id?: number | null; forwarded_to_name?: string | null; forwarded_at?: string | null; forward_note?: string | null; parent_opinion_id?: number | null;`.
       - State staff picker:
         ```typescript
         const [fwdOpen, setFwdOpen] = useState(false);
         const [fwdOpinionId, setFwdOpinionId] = useState<number | null>(null);
         const [fwdToStaffId, setFwdToStaffId] = useState<number | null>(null);
         const [fwdNote, setFwdNote] = useState('');
         const [fwdSubmitting, setFwdSubmitting] = useState(false);
         const [staffOptions, setStaffOptions] = useState<{ value: number; label: string }[]>([]);
         ```
       - **Fetch staff options dùng endpoint MỚI tạo ở Wave 2**:
         ```typescript
         const fetchStaffForForward = async () => {
           try {
             // Endpoint MỚI /nhan-vien-cung-don-vi — bypass RBAC /api/quan-tri
             const res = await api.get('/ho-so-cong-viec/nhan-vien-cung-don-vi');
             const list = res.data?.data || [];
             setStaffOptions(list.map((s: any) => ({ value: s.id, label: s.full_name })));
           } catch {
             setStaffOptions([]);
           }
         };
         ```
       - Button "Chuyển tiếp" trên mỗi opinion-item:
         ```tsx
         <Button size="small" type="link" icon={<SendOutlined />} onClick={() => {
           setFwdOpinionId(item.id);
           setFwdToStaffId(null);
           setFwdNote('');
           fetchStaffForForward();
           setFwdOpen(true);
         }}>Chuyển tiếp</Button>
         ```
       - Render thread indent (opinion có parent_opinion_id):
         ```tsx
         <div style={{ marginLeft: item.parent_opinion_id ? 32 : 0, borderLeft: item.parent_opinion_id ? '2px solid #e5e7eb' : 'none', paddingLeft: item.parent_opinion_id ? 12 : 0 }}>
           {item.parent_opinion_id && (
             <div style={{ fontSize: 12, color: '#6b7280' }}>
               <SendOutlined /> Chuyển tiếp cho {item.forwarded_to_name || '—'}
             </div>
           )}
           {/* existing opinion-item render */}
         </div>
         ```
       - Handler:
         ```typescript
         const handleForwardOpinion = async () => {
           if (!fwdOpinionId || !fwdToStaffId) {
             message.warning('Vui lòng chọn người nhận');
             return;
           }
           if (!fwdNote.trim()) {
             message.warning('Vui lòng nhập nội dung chuyển tiếp');
             return;
           }
           setFwdSubmitting(true);
           try {
             const res = await api.post(`/ho-so-cong-viec/${id}/y-kien/${fwdOpinionId}/chuyen-tiep`, {
               to_staff_id: fwdToStaffId,
               note: fwdNote.trim(),
             });
             message.success(res.data?.message || 'Đã chuyển tiếp ý kiến');
             setFwdOpen(false);
             fetchOpinions();
           } catch (err: any) {
             message.error(err.response?.data?.message || 'Chuyển tiếp thất bại');
           } finally {
             setFwdSubmitting(false);
           }
         };
         ```
       - Modal:
         ```tsx
         <Modal
           open={fwdOpen}
           title="Chuyển tiếp ý kiến"
           okText="Gửi"
           cancelText="Hủy"
           confirmLoading={fwdSubmitting}
           onCancel={() => setFwdOpen(false)}
           onOk={handleForwardOpinion}
         >
           <Form layout="vertical">
             <Form.Item label="Người nhận" required>
               <Select
                 showSearch
                 optionFilterProp="label"
                 placeholder="Chọn người nhận"
                 options={staffOptions}
                 value={fwdToStaffId}
                 onChange={setFwdToStaffId}
               />
             </Form.Item>
             <Form.Item label="Nội dung chuyển tiếp" required>
               <Input.TextArea
                 rows={4}
                 maxLength={1000}
                 showCount
                 value={fwdNote}
                 onChange={(e) => setFwdNote(e.target.value)}
                 placeholder="Nhập nội dung, ý kiến gửi kèm..."
               />
             </Form.Item>
           </Form>
         </Modal>
         ```
       - Import `SendOutlined` từ `@ant-design/icons`.

    **Verification sau task:**
    - Type-check BE + FE pass.
    - Test endpoint staff picker: `curl -H "Authorization: Bearer <non-admin-token>" http://localhost:4000/api/ho-so-cong-viec/nhan-vien-cung-don-vi` → 200 (KHÔNG 403).
    - DB: kiểm tra row mới sau forward có parent_opinion_id link đúng + forwarded_to_staff_id đúng.
    - Manual: tab Ý kiến → nút Chuyển tiếp → Select staff có options (không 403) → note → Gửi → child opinion hiện indent.

    **Commit:** `feat: thêm chức năng chuyển tiếp ý kiến HSCV — HDSD III.2.6`
  </action>
  <verify>
    <automated>
      cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tail -20 &&
      cd ../frontend && npx tsc --noEmit 2>&1 | tail -20 &&
      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT column_name FROM information_schema.columns WHERE table_schema='edoc' AND table_name='opinion_handling_docs' AND column_name IN ('forwarded_to_staff_id','forwarded_at','forward_note','parent_opinion_id');" &&
      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT proname FROM pg_proc WHERE proname IN ('fn_opinion_forward','fn_opinion_get_list');" &&
      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT conname FROM pg_constraint WHERE conname='fk_opinion_parent';" &&
      grep -c "nhan-vien-cung-don-vi" e_office_app_new/backend/src/routes/handling-doc.ts
    </automated>
  </verify>
  <done>
    - 4 cột forward_* exist trên edoc.opinion_handling_docs + FK self-reference fk_opinion_parent.
    - SP fn_opinion_forward exists, reject note rỗng, verify to_staff exists (is_locked=false, is_deleted=false).
    - SP fn_opinion_get_list DROP/CREATE — GIỮ param name p_doc_id, GIỮ staff_name TEXT với CONCAT(last_name,' ',first_name)::TEXT. Thêm 5 field forward_* với forwarded_to_name TEXT.
    - Endpoint staff picker mới: GET /api/ho-so-cong-viec/nhan-vien-cung-don-vi (middleware: authenticate ONLY, KHÔNG admin role).
    - Route POST /api/ho-so-cong-viec/:id/y-kien/:opinionId/chuyen-tiep mount.
    - Mỗi opinion-item có nút "Chuyển tiếp" mở Modal staff picker + note.
    - Child opinion (parent_opinion_id ≠ null) render indent + label "Chuyển tiếp cho {name}".
    - Manual test (non-admin user): staff picker không 403; forward → row mới tạo, indent hiển thị đúng.
    - Type-check BE + FE pass.
    - Commit: `feat: thêm chức năng chuyển tiếp ý kiến HSCV — HDSD III.2.6`.
  </done>
</task>

<task type="auto">
  <name>Task 6: Gap F (TC-068) — Chuyển tiếp HSCV (transfer ownership)</name>
  <files>
    e_office_app_new/database/migrations/quick_260418_jsd_hscv_transfer.sql,
    e_office_app_new/backend/src/repositories/handling-doc.repository.ts,
    e_office_app_new/backend/src/routes/handling-doc.ts,
    e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx
  </files>
  <action>
    **Wave 1 — DB: CREATE TABLE handling_doc_history + CREATE 2 SPs (transfer + history_list).**
    **Reminder: handling_docs.id BIGSERIAL → p_id BIGINT. staff.id SERIAL → INT params.**

    1. VERIFY trước:
       ```bash
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\d edoc.handling_docs" | grep curator
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\dt edoc.handling_doc_history"  # expect: not found
       ```

    2. Tạo `e_office_app_new/database/migrations/quick_260418_jsd_hscv_transfer.sql`:
       ```sql
       -- Gap F (TC-068): Chuyển tiếp HSCV (transfer ownership)
       -- Dùng cột `action_type` thay vì `action` cho safety (dù action không reserved trong PG).

       -- 1. CREATE TABLE handling_doc_history
       CREATE TABLE IF NOT EXISTS edoc.handling_doc_history (
           id BIGSERIAL PRIMARY KEY,
           handling_doc_id BIGINT NOT NULL REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
           action_type VARCHAR(50) NOT NULL,  -- 'transfer','cancel','reopen'
           from_staff_id INT REFERENCES public.staff(id),
           to_staff_id INT REFERENCES public.staff(id),
           note TEXT,
           created_by INT REFERENCES public.staff(id),
           created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
       );

       CREATE INDEX IF NOT EXISTS idx_handling_doc_history_doc_id
         ON edoc.handling_doc_history(handling_doc_id);
       CREATE INDEX IF NOT EXISTS idx_handling_doc_history_created_at
         ON edoc.handling_doc_history(created_at DESC);

       -- 2. SP fn_handling_doc_transfer
       CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_transfer(
           p_id BIGINT,
           p_from_staff_id INT,
           p_to_staff_id INT,
           p_note TEXT,
           p_by INT
       )
       RETURNS TABLE(success BOOLEAN, message TEXT)
       LANGUAGE plpgsql
       SECURITY DEFINER
       AS $$
       DECLARE
           v_current_curator INT;
           v_doc_unit INT;
           v_to_unit INT;
           v_to_locked BOOLEAN;
           v_to_deleted BOOLEAN;
       BEGIN
           IF p_to_staff_id IS NULL OR p_to_staff_id <= 0 THEN
               RETURN QUERY SELECT FALSE, 'Vui lòng chọn người nhận'::TEXT;
               RETURN;
           END IF;
           IF p_from_staff_id = p_to_staff_id THEN
               RETURN QUERY SELECT FALSE, 'Không thể chuyển cho chính mình'::TEXT;
               RETURN;
           END IF;

           SELECT h.curator, h.unit_id INTO v_current_curator, v_doc_unit
             FROM edoc.handling_docs h WHERE h.id = p_id;
           IF NOT FOUND THEN
               RETURN QUERY SELECT FALSE, 'Không tìm thấy hồ sơ công việc'::TEXT;
               RETURN;
           END IF;

           -- Scope: cùng unit_id, không locked, không deleted
           SELECT s.unit_id, COALESCE(s.is_locked, FALSE), COALESCE(s.is_deleted, FALSE)
             INTO v_to_unit, v_to_locked, v_to_deleted
             FROM public.staff s WHERE s.id = p_to_staff_id;
           IF NOT FOUND THEN
               RETURN QUERY SELECT FALSE, 'Không tìm thấy người nhận'::TEXT;
               RETURN;
           END IF;
           IF v_to_locked THEN
               RETURN QUERY SELECT FALSE, 'Người nhận đã khóa tài khoản'::TEXT;
               RETURN;
           END IF;
           IF v_to_deleted THEN
               RETURN QUERY SELECT FALSE, 'Người nhận đã bị xoá'::TEXT;
               RETURN;
           END IF;
           IF v_to_unit <> v_doc_unit THEN
               RETURN QUERY SELECT FALSE, 'Chỉ có thể chuyển HSCV cho người cùng đơn vị'::TEXT;
               RETURN;
           END IF;

           -- UPDATE curator + INSERT history
           UPDATE edoc.handling_docs
           SET curator = p_to_staff_id,
               updated_at = NOW()
           WHERE id = p_id;

           INSERT INTO edoc.handling_doc_history(
               handling_doc_id, action_type, from_staff_id, to_staff_id, note, created_by, created_at
           )
           VALUES (p_id, 'transfer', v_current_curator, p_to_staff_id, p_note, p_by, NOW());

           RETURN QUERY SELECT TRUE, 'Đã chuyển tiếp hồ sơ công việc'::TEXT;
       END;
       $$;

       -- 3. SP fn_handling_doc_history_list — dùng CONCAT cho staff name (consistent với fn_opinion_get_list)
       CREATE OR REPLACE FUNCTION edoc.fn_handling_doc_history_list(p_id BIGINT)
       RETURNS TABLE(
           id BIGINT,
           handling_doc_id BIGINT,
           action_type VARCHAR,
           from_staff_id INT,
           from_staff_name TEXT,
           to_staff_id INT,
           to_staff_name TEXT,
           note TEXT,
           created_by INT,
           created_by_name TEXT,
           created_at TIMESTAMPTZ
       )
       LANGUAGE plpgsql
       AS $$
       BEGIN
           RETURN QUERY
           SELECT
               h.id,
               h.handling_doc_id,
               h.action_type,
               h.from_staff_id,
               CASE WHEN fs.id IS NOT NULL THEN CONCAT(fs.last_name, ' ', fs.first_name)::TEXT ELSE NULL END AS from_staff_name,
               h.to_staff_id,
               CASE WHEN ts.id IS NOT NULL THEN CONCAT(ts.last_name, ' ', ts.first_name)::TEXT ELSE NULL END AS to_staff_name,
               h.note,
               h.created_by,
               CASE WHEN cs.id IS NOT NULL THEN CONCAT(cs.last_name, ' ', cs.first_name)::TEXT ELSE NULL END AS created_by_name,
               h.created_at
           FROM edoc.handling_doc_history h
           LEFT JOIN public.staff fs ON fs.id = h.from_staff_id
           LEFT JOIN public.staff ts ON ts.id = h.to_staff_id
           LEFT JOIN public.staff cs ON cs.id = h.created_by
           WHERE h.handling_doc_id = p_id
           ORDER BY h.created_at DESC;
       END;
       $$;
       ```

    3. Chạy migration + test:
       ```bash
       docker cp e_office_app_new/database/migrations/quick_260418_jsd_hscv_transfer.sql qlvb_postgres:/tmp/
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -f /tmp/quick_260418_jsd_hscv_transfer.sql
       # Verify
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "\d edoc.handling_doc_history"
       # Tìm 2 staff cùng unit_id:
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT id, full_name, unit_id FROM public.staff WHERE unit_id = (SELECT unit_id FROM public.staff WHERE id=1) LIMIT 3;"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT * FROM edoc.fn_handling_doc_transfer(1, 1, 2, 'Chuyển để xử lý', 1);"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT id, curator FROM edoc.handling_docs WHERE id=1;"
       docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT * FROM edoc.fn_handling_doc_history_list(1);"
       ```

    **Wave 2 — Backend: repo methods + route endpoints.**

    4. Update `e_office_app_new/backend/src/repositories/handling-doc.repository.ts`:
       - Thêm interface:
         ```typescript
         export interface HscvHistoryRow {
           id: number;
           handling_doc_id: number;
           action_type: string;
           from_staff_id: number | null;
           from_staff_name: string | null;
           to_staff_id: number | null;
           to_staff_name: string | null;
           note: string | null;
           created_by: number | null;
           created_by_name: string | null;
           created_at: string;
         }
         ```
       - Thêm methods:
         ```typescript
         async transfer(id: number, fromStaffId: number, toStaffId: number, note: string, byStaffId: number): Promise<{ success: boolean; message: string } | null> {
           return callFunctionOne('edoc.fn_handling_doc_transfer', [id, fromStaffId, toStaffId, note, byStaffId]);
         },
         async getHistory(id: number): Promise<HscvHistoryRow[]> {
           return callFunction<HscvHistoryRow>('edoc.fn_handling_doc_history_list', [id]);
         },
         ```

    5. Update `e_office_app_new/backend/src/routes/handling-doc.ts`:
       - Thêm 2 route:
         ```typescript
         router.post('/:id/chuyen-tiep', authenticate, async (req: AuthRequest, res, next) => {
           try {
             const id = Number(req.params.id);
             const toStaffId = Number(req.body?.to_staff_id);
             const note = String(req.body?.note || '').trim();
             if (!Number.isInteger(id) || id <= 0) {
               return res.status(400).json({ message: 'ID không hợp lệ' });
             }
             if (!Number.isInteger(toStaffId) || toStaffId <= 0) {
               return res.status(400).json({ message: 'Vui lòng chọn người nhận' });
             }
             const result = await handlingDocRepository.transfer(id, req.user!.staffId, toStaffId, note, req.user!.staffId);
             if (!result?.success) {
               return res.status(400).json({ message: result?.message || 'Chuyển tiếp thất bại' });
             }
             res.json({ success: true, message: result.message });
           } catch (err) { handleDbError(err, res, next); }
         });

         router.get('/:id/lich-su', authenticate, async (req: AuthRequest, res, next) => {
           try {
             const id = Number(req.params.id);
             if (!Number.isInteger(id) || id <= 0) {
               return res.status(400).json({ message: 'ID không hợp lệ' });
             }
             const list = await handlingDocRepository.getHistory(id);
             res.json({ data: list });
           } catch (err) { handleDbError(err, res, next); }
         });
         ```

    **Wave 3 — Frontend: button Chuyển tiếp HSCV + Modal (REUSE staff picker endpoint từ Task 5) + Modal Lịch sử.**

    6. Update `e_office_app_new/frontend/src/app/(main)/ho-so-cong-viec/[id]/page.tsx`:
       - **Đọc file trước** — tìm `getToolbarButtons` case 4 (Xem lịch sử stub), interface HscvDetail để add `curator_id`.
       - Bổ sung state:
         ```typescript
         const [transferOpen, setTransferOpen] = useState(false);
         const [transferToStaffId, setTransferToStaffId] = useState<number | null>(null);
         const [transferNote, setTransferNote] = useState('');
         const [transferring, setTransferring] = useState(false);
         const [historyList, setHistoryList] = useState<HscvHistoryRow[]>([]);
         const [historyOpen, setHistoryOpen] = useState(false);
         const [historyLoading, setHistoryLoading] = useState(false);
         // REUSE staffOptions + fetchStaffForForward từ Task 5 — KHÔNG tạo mới
         ```
       - Interface `HscvHistoryRow`: copy từ BE repository.
       - Button toolbar (conditional: user là curator hoặc admin, và status IN 0/1/2/3):
         ```tsx
         {detail && [0, 1, 2, 3].includes(detail.status) && (user?.staffId === detail.curator_id || user?.roles?.includes('Quản trị hệ thống')) && (
           <Button icon={<SwapOutlined />} onClick={() => {
             setTransferToStaffId(null);
             setTransferNote('');
             fetchStaffForForward();  // REUSE từ Task 5 — gọi /nhan-vien-cung-don-vi
             setTransferOpen(true);
           }}>Chuyển tiếp HSCV</Button>
         )}
         ```
       - Button "Lịch sử" (thay thế stub):
         ```tsx
         <Button icon={<HistoryOutlined />} onClick={() => {
           fetchHistory();
           setHistoryOpen(true);
         }}>Lịch sử</Button>
         ```
       - Handlers:
         ```typescript
         const handleTransfer = async () => {
           if (!transferToStaffId) {
             message.warning('Vui lòng chọn người nhận');
             return;
           }
           setTransferring(true);
           try {
             const res = await api.post(`/ho-so-cong-viec/${id}/chuyen-tiep`, {
               to_staff_id: transferToStaffId,
               note: transferNote.trim(),
             });
             message.success(res.data?.message || 'Đã chuyển tiếp HSCV');
             setTransferOpen(false);
             fetchDetail();
           } catch (err: any) {
             message.error(err.response?.data?.message || 'Chuyển tiếp thất bại');
           } finally {
             setTransferring(false);
           }
         };

         const fetchHistory = async () => {
           setHistoryLoading(true);
           try {
             const res = await api.get(`/ho-so-cong-viec/${id}/lich-su`);
             setHistoryList(res.data?.data || []);
           } catch {
             setHistoryList([]);
           } finally {
             setHistoryLoading(false);
           }
         };
         ```
       - Modal Chuyển tiếp (Modal dùng `width`, không `size`):
         ```tsx
         <Modal
           open={transferOpen}
           title="Chuyển tiếp HSCV"
           okText="Chuyển tiếp"
           cancelText="Hủy"
           confirmLoading={transferring}
           onCancel={() => setTransferOpen(false)}
           onOk={handleTransfer}
         >
           <Alert message="Chỉ có thể chuyển HSCV cho người cùng đơn vị" type="info" showIcon style={{ marginBottom: 16 }} />
           <Form layout="vertical">
             <Form.Item label="Người nhận" required>
               <Select
                 showSearch
                 optionFilterProp="label"
                 placeholder="Chọn người nhận (cùng đơn vị)"
                 options={staffOptions.filter(s => s.value !== user?.staffId)}
                 value={transferToStaffId}
                 onChange={setTransferToStaffId}
               />
             </Form.Item>
             <Form.Item label="Ghi chú">
               <Input.TextArea
                 rows={3}
                 maxLength={500}
                 showCount
                 value={transferNote}
                 onChange={(e) => setTransferNote(e.target.value)}
                 placeholder="Ghi chú thêm (tuỳ chọn)"
               />
             </Form.Item>
           </Form>
         </Modal>
         ```
       - Modal Lịch sử (Modal dùng `width={720}` — KHÔNG `size`):
         ```tsx
         <Modal
           open={historyOpen}
           title="Lịch sử HSCV"
           footer={<Button onClick={() => setHistoryOpen(false)}>Đóng</Button>}
           width={720}
           onCancel={() => setHistoryOpen(false)}
         >
           {historyLoading ? <Skeleton active paragraph={{ rows: 4 }} /> : (
             historyList.length === 0 ? <Empty description="Chưa có lịch sử" /> : (
               <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                 {historyList.map(h => (
                   <div key={h.id} style={{ padding: 12, border: '1px solid #e5e7eb', borderRadius: 8 }}>
                     <div style={{ fontWeight: 600 }}>
                       {h.action_type === 'transfer' && (
                         <><SwapOutlined /> Chuyển tiếp: {h.from_staff_name || '—'} → {h.to_staff_name || '—'}</>
                       )}
                       {h.action_type === 'cancel' && (<><CloseCircleOutlined /> Hủy HSCV</>)}
                       {h.action_type === 'reopen' && (<><ReloadOutlined /> Mở lại</>)}
                     </div>
                     {h.note && <div style={{ marginTop: 6, color: '#4b5563' }}>Ghi chú: {h.note}</div>}
                     <div style={{ marginTop: 6, fontSize: 12, color: '#6b7280' }}>
                       {dayjs(h.created_at).format('DD/MM/YYYY HH:mm')} · {h.created_by_name || '—'}
                     </div>
                   </div>
                 ))}
               </div>
             )
           )}
         </Modal>
         ```
       - Import: `SwapOutlined, HistoryOutlined, ReloadOutlined` từ `@ant-design/icons`; `Skeleton, Empty, Alert` từ antd.

    **Verification sau task:**
    - Type-check BE + FE pass.
    - DB: `\d edoc.handling_doc_history` → table exist với 2 index.
    - Manual (non-admin user là curator):
      - Nút "Chuyển tiếp HSCV" hiện → Modal staff picker load options (dùng endpoint Task 5) → chọn staff cùng unit + note → Gửi → curator đổi.
      - Nút "Lịch sử" → Modal hiện list history (có row transfer vừa tạo).
      - Thử chuyển cho staff khác unit → error "Chỉ chuyển cho người cùng đơn vị".

    **Commit:** `feat: thêm chức năng chuyển tiếp HSCV cho người khác — HDSD III.2.7`
  </action>
  <verify>
    <automated>
      cd e_office_app_new/backend && npx tsc --noEmit 2>&1 | tail -20 &&
      cd ../frontend && npx tsc --noEmit 2>&1 | tail -20 &&
      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT table_name FROM information_schema.tables WHERE table_schema='edoc' AND table_name='handling_doc_history';" &&
      docker exec qlvb_postgres psql -U qlvb_admin -d qlvb_dev -c "SELECT proname FROM pg_proc WHERE proname IN ('fn_handling_doc_transfer','fn_handling_doc_history_list');"
    </automated>
  </verify>
  <done>
    - Table edoc.handling_doc_history created với 2 index, cột action_type (không phải reserved).
    - SP fn_handling_doc_transfer exists, validate same unit_id, reject locked/deleted staff.
    - SP fn_handling_doc_history_list exists, JOIN staff 3 lần (from/to/created_by) dùng CONCAT(last_name,' ',first_name)::TEXT.
    - Routes POST /:id/chuyen-tiep + GET /:id/lich-su mount.
    - HSCV detail có nút "Chuyển tiếp HSCV" conditional (curator hoặc admin, status 0-3).
    - Modal staff picker REUSE fetchStaffForForward từ Task 5 (gọi /nhan-vien-cung-don-vi).
    - Modal Lịch sử dùng width={720}, hiển thị timeline.
    - Manual test: transfer same unit thành công, cross-unit bị reject, lịch sử đúng.
    - Type-check BE + FE pass.
    - Commit: `feat: thêm chức năng chuyển tiếp HSCV cho người khác — HDSD III.2.7`.
  </done>
</task>

<task type="auto">
  <name>Task 7: Regenerate test catalog HDSD sau fix 6 gap (BLOCKING — chạy CUỐI CÙNG)</name>
  <files>
    e_office_app_new/backend/scripts/gen-test-catalog.cjs,
    docs/test_theo_hdsd_cu.md,
    docs/test_theo_hdsd_cu.xlsx
  </files>
  <action>
    **BLOCKING DEPENDENCY — Task này PHẢI chạy CUỐI CÙNG, sau khi Task 1-6 đã commit xong. Nếu Task 1-6 có task nào FAIL → task 7 không chạy hoặc phải điều chỉnh note theo kết quả thực.**

    1. **Đọc** `e_office_app_new/backend/scripts/gen-test-catalog.cjs` để hiểu structure:
       - Kiểm tra cấu trúc data (array of TC objects với `id, description, auto, note`).
       - Tìm entries cho TC-011, TC-045, TC-046, TC-066, TC-067, TC-068, TC-070, TC-079.

    2. Update 8 entries:
       ```javascript
       // TC-011 — Ký số VB đi/dự thảo
       {
         id: 'TC-011',
         ...existing,
         auto: '✅ Pass',
         note: 'Mock OTP flow — TODO tích hợp VNPT SmartCA SDK thực ở Phase 2'
       },

       // TC-045 — Gửi trục CP
       {
         id: 'TC-045',
         ...existing,
         auto: '✅ Pass',
         note: 'Mock trục CP — TODO tích hợp thực Phase 2'
       },

       // TC-046 — Chuyển lưu trữ VB đi
       {
         id: 'TC-046',
         ...existing,
         auto: '✅ Pass',
         note: 'Form đầy đủ với Phòng/Kho lưu trữ'
       },

       // TC-066 — Hủy HSCV
       {
         id: 'TC-066',
         ...existing,
         auto: '✅ Pass',
         note: 'Action hủy HSCV riêng với lý do'
       },

       // TC-067 — Chuyển tiếp ý kiến HSCV
       {
         id: 'TC-067',
         ...existing,
         auto: '✅ Pass',
         note: 'Chuyển tiếp ý kiến cho user review'
       },

       // TC-068 — Chuyển tiếp HSCV
       {
         id: 'TC-068',
         ...existing,
         auto: '✅ Pass',
         note: 'Transfer ownership HSCV (same unit)'
       },

       // TC-070 — Dashboard
       {
         id: 'TC-070',
         ...existing,
         auto: '✅ Pass',
         note: 'Gộp vào /dashboard chung — thống nhất với user'
       },

       // TC-079 — giữ Missing, note mới
       {
         id: 'TC-079',
         ...existing,
         auto: '❌ Missing',
         note: 'Defer Phase 2 — cần schema permission model mới'
       },
       ```

    3. Chạy regenerate:
       ```bash
       cd e_office_app_new/backend && node scripts/gen-test-catalog.cjs
       ```
       - Script sẽ regenerate `docs/test_theo_hdsd_cu.md` và `docs/test_theo_hdsd_cu.xlsx`.

    4. Verify:
       ```bash
       grep -E "TC-011|TC-045|TC-046|TC-066|TC-067|TC-068|TC-070|TC-079" docs/test_theo_hdsd_cu.md | head -20
       ls -la docs/test_theo_hdsd_cu.xlsx
       ```
       - TC-011, 045, 046, 066, 067, 068, 070 đều hiện `✅ Pass`.
       - TC-079 vẫn `❌ Missing` với note mới.
       - File .xlsx có timestamp mới (just regenerated).

    **Verification sau task:**
    - `docs/test_theo_hdsd_cu.md` chứa 7 TC updated với ✅ Pass.
    - TC-079 giữ ❌ Missing với note `Defer Phase 2...`.
    - File .xlsx regenerated (mtime mới).

    **Commit:** `docs: regenerate test catalog sau fix 6 gap HDSD`
  </action>
  <verify>
    <automated>
      cd e_office_app_new/backend && node scripts/gen-test-catalog.cjs 2>&1 | tail -10 &&
      grep -E "TC-011|TC-045|TC-046|TC-066|TC-067|TC-068|TC-070" docs/test_theo_hdsd_cu.md | grep -c "Pass" &&
      grep -E "TC-079" docs/test_theo_hdsd_cu.md | grep -c "Missing"
    </automated>
  </verify>
  <done>
    - Task chạy sau Task 1-6 commit xong (BLOCKING dependency).
    - gen-test-catalog.cjs updated với 8 entries (7 pass + 1 defer).
    - Script chạy thành công, regenerate .md + .xlsx.
    - grep check: 7 TC có "Pass", 1 TC có "Missing".
    - Commit: `docs: regenerate test catalog sau fix 6 gap HDSD`.
  </done>
</task>

</tasks>

<verification>

**Per-task verification (đã nêu trong từng task):**
- Type-check BE + FE sau mỗi task (không thêm errors mới).
- DB smoke test cho Task 1-2-4-5-6 (migration + SP verify).
- Manual UAT flow cho từng gap trước khi sang task tiếp theo.

**Cross-task integration check (sau Task 6, trước Task 7):**
- `cd e_office_app_new/backend && npx tsc --noEmit 2>&1` — 0 new errors.
- `cd e_office_app_new/frontend && npx tsc --noEmit 2>&1` — 0 new errors.
- Manual: test 6 flows end-to-end lần lượt.
- DB: 4 bảng ảnh hưởng (lgsp_tracking, handling_docs, opinion_handling_docs, handling_doc_history) verify schema khớp spec.
- **Non-admin user test**: login với user không phải admin, test forward opinion + transfer HSCV → staff picker trả 200 (không 403).

**Final gate (sau Task 7):**
- `docs/test_theo_hdsd_cu.md` mới sinh có đủ 7 TC updated.
- `docs/test_theo_hdsd_cu.xlsx` mtime mới.

</verification>

<success_criteria>

- [ ] Task 1 (Gap A): SP attachment trả 12 field (9 cũ + 3 mới is_ca/ca_date/signed_file_path), dùng đúng cột FK outgoing_doc_id/drafting_doc_id + JOIN public.staff; VB đi + VB dự thảo có nút Ký số + Modal OTP + Tag "Đã ký số".
- [ ] Task 2 (Gap B): cột channel thêm vào lgsp_tracking; SP fn_lgsp_tracking_create DROP/CREATE với signature đúng (p_outgoing_doc_id, p_incoming_doc_id, p_direction, p_dest_org_code, p_dest_org_name, p_edxml_content, p_created_by, p_channel); sendLgsp() cập nhật truyền 'lgsp' explicit; endpoint /gui-truc-cp + Modal FE hardcode 8 bộ/ngành CP.
- [ ] Task 3 (Gap C): 2 endpoint BE mirror (/van-ban-di/:id/luu-tru/phong + /kho); VB đi detail có Drawer "Chuyển lưu trữ" với 13 field (clone từ VB đến).
- [ ] Task 4 (Gap D): 3 cột cancel_* thêm vào handling_docs; SP fn_handling_doc_cancel; SP fn_handling_doc_get_by_id DROP/CREATE với 36 field (33 cũ + 3 cancel_*); endpoint /huy; button + Modal required reason; Card hiển thị khi status=-3.
- [ ] Task 5 (Gap E): Endpoint staff picker mới /api/ho-so-cong-viec/nhan-vien-cung-don-vi (authenticate ONLY, non-admin accessible); 4 cột forward_* thêm vào opinion_handling_docs + FK self-reference; SP fn_opinion_forward; SP fn_opinion_get_list DROP/CREATE (11 field: 6 cũ + 5 forward_*, staff_name TEXT với CONCAT, param p_doc_id); button + Modal staff picker + thread indent FE.
- [ ] Task 6 (Gap F): Table handling_doc_history (cột action_type) created; SP fn_handling_doc_transfer (validate same unit_id); SP fn_handling_doc_history_list; endpoints /chuyen-tiep + /lich-su; button + Modal FE (reuse staff picker từ Task 5) + History Modal timeline (width={720}).
- [ ] Task 7 (BLOCKING sau Task 1-6): gen-test-catalog.cjs updated + regenerate md+xlsx. 7 TC có ✅ Pass, TC-079 giữ ❌ Missing với note defer.
- [ ] Mỗi task có 1 commit riêng theo format chỉ định.
- [ ] Backend + FE type-check không phát sinh errors mới.
- [ ] Non-admin user test: staff picker endpoint Task 5 trả 200 (KHÔNG 403).
- [ ] Demo HDSD compliance test (docs/test_theo_hdsd_cu.md) đạt ≥7/8 TC target.

</success_criteria>

<output>
Tạo summary sau khi task hoàn tất:
.planning/quick/260418-jsd-hdsd-compliance-fix-6-gap-c-n-l-i-k-s-mo/260418-jsd-SUMMARY.md
</output>
