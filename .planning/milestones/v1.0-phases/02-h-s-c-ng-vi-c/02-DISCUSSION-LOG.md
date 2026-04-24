# Phase 2: Hồ sơ công việc - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-14
**Phase:** 02-hồ sơ công việc
**Mode:** --auto (all decisions auto-selected)
**Areas discussed:** Danh sách HSCV & Filter, Chi tiết HSCV & Tabs, Workflow Designer, KPI & Báo cáo

---

## Danh sách HSCV & Filter

| Option | Description | Selected |
|--------|-------------|----------|
| Tab/filter bar ngang | Tabs hoặc Segmented ở đầu trang, consistent với VB đến/đi | ✓ |
| Sidebar sub-menu | Menu con trong sidebar với badge count | |
| Dropdown filter | Select dropdown cho trạng thái | |

**User's choice:** [auto] Tab/filter bar ngang (recommended default)
**Notes:** Giữ nhất quán với pattern VB đến/đi đã implement. Sidebar sub-menu phức tạp hơn và thay đổi navigation structure.

---

## Chi tiết HSCV & Tabs

| Option | Description | Selected |
|--------|-------------|----------|
| Trang riêng /ho-so-cong-viec/:id | Page riêng với Card Tabs 6 tab | ✓ |
| Drawer mở rộng | Drawer full-width cho detail | |

**User's choice:** [auto] Trang riêng (recommended — ROADMAP chỉ định)
**Notes:** Quá nhiều nội dung cho Drawer. 6 tab + toolbar actions cần không gian full page.

---

## Workflow Designer

| Option | Description | Selected |
|--------|-------------|----------|
| ReactFlow (drag-and-drop canvas) | Full visual flowchart editor | ✓ |
| Simplified step list | Ordered list với arrows, không kéo thả | |
| AntV X6 | Alternative flow chart library | |

**User's choice:** [auto] ReactFlow (recommended — ROADMAP chỉ định visual flowchart kéo thả)
**Notes:** ReactFlow là industry standard cho React flowcharts. ROADMAP.md đã suggest "ReactFlow hoặc tương đương".

---

## KPI & Báo cáo

| Option | Description | Selected |
|--------|-------------|----------|
| Ant Design Charts (Bar/Pie) | Consistent với tech stack, built on AntV | ✓ |
| Recharts | Popular alternative, lightweight | |
| ECharts | Full-featured, heavier | |

**User's choice:** [auto] Ant Design Charts (recommended — consistent với Ant Design ecosystem)
**Notes:** Ant Design Charts đã được chỉ định trong tech stack (CLAUDE.md). Bar chart cho so sánh, Pie cho tỷ lệ.

---

## Claude's Discretion

- Thứ tự implement các sub-features
- Chi tiết styling cho KPI cards, tag colors, progress bar
- Code organization (route file structure)
- ReactFlow node styling details
- HSCV con nesting depth

## Deferred Ideas

None
