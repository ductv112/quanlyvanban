# Phase 7: Polish & Redirect - Context

**Gathered:** 2026-04-15
**Status:** Ready for planning

<domain>
## Phase Boundary

Polish UI/UX toan bo he thong de dat chat luong demo: sidebar dynamic tu API quyen, responsive mobile, skeleton/empty/error states nhat quan, va redirect trang doi tac. Sprint 17 (cuoi cung). Requirements: UI-01 -> UI-04.

Day la phase cuoi cung truoc demo — chi lam UI/UX polish, KHONG them tinh nang moi.

</domain>

<decisions>
## Implementation Decisions

### Nguyen tac chung — BAT BUOC cho toan bo Phase 7
- **D-00a:** Phase nay chi sua/them frontend code. KHONG tao migration DB, KHONG them backend routes/repositories moi.
- **D-00b:** Tat ca thay doi phai backward-compatible — khong lam vo chuc nang da co.
- **D-00c:** Uu tien chat luong demo — moi thay doi phai nhin thay duoc tren UI.

### UI-01: Menu redirect trang doi tac
- **D-01:** Them nhom menu "Doi tac" trong sidebar voi cac link external:
  - Hoa don dien tu VNPT (https://vinvoice.vn) — target="_blank"
  - Hoa don dien tu Viettel (https://sinvoice.viettel.vn) — target="_blank"
  - Bao hiem xa hoi (https://dichvucong.baohiemxahoi.gov.vn) — target="_blank"
  - Thue dien tu (https://thuedientu.gdt.gov.vn) — target="_blank"
- **D-02:** Cac link nay la placeholder — URL that se duoc cau hinh boi admin sau. Hien tai hardcode URL demo.
- **D-03:** Menu items co icon LinkOutlined hoac ExportOutlined de phan biet voi menu internal.

### UI-02: Sidebar menu dynamic tu API quyen
- **D-04:** Backend da co RBAC (roles, rights, action_of_role). Tuy nhien voi deadline demo, **KHONG lam dynamic menu tu API** — giu sidebar tinh nhu hien tai. Ly do: can SP moi de load menu theo quyen, qua phuc tap cho 1 phase polish.
- **D-05:** Thay vao do, **them badge counts** cho cac muc chinh:
  - Van ban den: so VB chua xu ly (goi API `/api/van-ban-den?status=pending` lay total)
  - Tin nhan: so tin chua doc (goi API `/api/tin-nhan/unread-count`)
  - Thong bao: da co notifUnreadCount — giu nguyen
- **D-06:** Badge counts cap nhat khi mount + khi nhan Socket.IO event.

### UI-03: Responsive mobile
- **D-07:** Breakpoint chinh: 768px (tablet/mobile). Duoi 768px:
  - Sidebar an di, hien hamburger button o header
  - Click hamburger mo sidebar dang Drawer (tu trai)
  - Click menu item auto dong Drawer
- **D-08:** Tables responsive: duoi 768px, an cot it quan trong (bang `responsive` prop cua AntD Table column), giu cot ten/trang thai/hanh dong.
- **D-09:** Forms responsive: chuyen tu 2 cot sang 1 cot khi duoi 768px (dung AntD Grid `<Col xs={24} md={12}>`).
- **D-10:** **KHONG lam PWA hoac offline** — chi responsive CSS.

### UI-04: Polish UX
- **D-11:** **Skeleton loading** — Them `loading.tsx` vao cac route groups chinh: `(main)/loading.tsx`, de Next.js tu dong hien skeleton khi chuyen trang.
- **D-12:** **Empty states** — Tao component EmptyState dung chung, hien khi Table khong co data. Hien tai dang dung AntD Table default empty — them icon + text tieng Viet co y nghia (VD: "Chua co van ban den nao").
- **D-13:** **Error boundaries** — Them `error.tsx` vao route group `(main)/error.tsx`. Hien thong bao loi than thien + nut "Thu lai".
- **D-14:** **Toast/notification nhat quan** — Da dung `message.success/error` qua `App.useApp()` — chi can verify toan bo cac trang deu dung pattern nay, khong co trang nao dung `notification` hoac `alert()`.

### Claude's Discretion
- Chi tiet CSS responsive (media queries, breakpoints cu the)
- Skeleton loading animation style
- Empty state icon/illustration chon tu AntD icons
- Thu tu thuc hien cac task trong phase

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing codebase
- `e_office_app_new/frontend/src/components/layout/MainLayout.tsx` — Sidebar chinh, menu items, bell notification, breadcrumb
- `e_office_app_new/frontend/src/app/globals.css` — CSS classes toan cuc
- `e_office_app_new/frontend/src/config/theme.ts` — AntD theme config
- `e_office_app_new/frontend/src/stores/auth.store.ts` — Auth state (user, roles)
- `e_office_app_new/frontend/src/lib/api.ts` — Axios instance
- `e_office_app_new/frontend/src/lib/socket.ts` — Socket.IO client (da co events: NEW_MESSAGE, NEW_NOTIFICATION, NEW_DOCUMENT)

### Prior phase context
- `.planning/phases/06-t-ch-h-p-h-th-ng-ngo-i/06-CONTEXT.md` — Phase 6 decisions

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **MainLayout.tsx**: Da co sidebar, bell notification voi Socket.IO, breadcrumb, user dropdown — chi can sua/them vao
- **Socket.IO events**: Da co NEW_MESSAGE, NEW_NOTIFICATION, NEW_DOCUMENT — dung de cap nhat badge counts
- **globals.css**: Da co .main-layout, .main-sider, .main-header, .main-content, .page-header, .page-card — them responsive vao day
- **AntD Table**: Da dung `loading` prop tren tat ca pages — pattern da nhat quan

### What's Missing (Phase 7 creates)
- Khong co `error.tsx` hay `loading.tsx` nao
- Khong co responsive CSS (@media queries)
- Khong co EmptyState component chung
- Khong co menu redirect doi tac
- Khong co badge counts tren sidebar menu items

### Integration Points
- **MainLayout.tsx**: Them menu doi tac, badge counts, responsive drawer
- **globals.css**: Them @media queries cho responsive
- **Route groups**: Them error.tsx va loading.tsx

</code_context>

<specifics>
## Specific Ideas

- Day la phase cuoi — uu tien visual impact cho demo
- Khong can dynamic menu tu API quyen (qua phuc tap) — chi badge counts
- Responsive chi can hoat dong co ban tren tablet, khong can pixel-perfect mobile

</specifics>

<deferred>
## Deferred Ideas

None — phase 7 is the final phase

</deferred>

---

*Phase: 07-polish-redirect*
*Context gathered: 2026-04-15*
