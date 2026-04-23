# Phase 14: Deployment + HDSD triển khai + verification — Discussion Log

> **Audit trail only.** Không dùng làm input cho planning, research, execution agents.
> Decisions được capture trong CONTEXT.md — log này preserve alternatives considered.

**Date:** 2026-04-23
**Phase:** 14-deployment-hdsd-verification
**Areas discussed:** Target OS (feedback interrupt), Seed DEP-01, HDSD DEP-03, Checklist AC-04, UAT AC-03, Backup strategy, Defer scope

---

## Target OS (user feedback interrupt — không trong list gray area ban đầu)

**Source:** User message giữa chừng lúc đang present gray areas: "Từ từ dự án này deploy lên server product windown thôi, ko có linux đâu, nên xóa bỏ mấy file cài đặt cho linux đi, ko cần cho linux đâu"

**Decision:** Windows Server + IIS ONLY. Xóa 4 file Linux `.sh` (`deploy.sh`, `update.sh`, `reset-db.sh`, `backup.sh`). README viết lại Windows-only.

**Notes:** Feedback này lock được 1 decision lớn upfront (D-01) và giảm đáng kể scope Phase 14 — không cần parity Windows/Linux, không cần duplicate logic trong README.

---

## Seed DEP-01 — Strategy cho signing_provider_config

| Option | Description | Selected |
|--------|-------------|----------|
| A. Sửa seed 001 → cả 2 disabled (Recommended) | Sửa `001_required_data.sql`: SmartCA + MySign cả 2 is_active=FALSE, xóa dev creds. Dev test local: admin login + config tay sau reset-db. | ✓ |
| B. Tách 001 disabled / 002 extend dev creds | 001 prod-safe, 002 extend UPDATE set active + creds cho test env. Deploy prod chạy 001 only. | |
| C. Giữ 001 hiện tại + deploy script inject disable | Seed không đổi, `deploy-windows.ps1` thêm step UPDATE disable sau seed. Rủi ro deploy script quên run. | |

**User's choice:** A — Sửa seed 001, nhất quán production, đơn giản.
**Notes:** Dev workflow sau reset-db cần document ngắn (D-04). Xóa bỏ dev creds hardcoded trong seed (security hygiene).

---

## HDSD DEP-03 — Cấu hình ký số sau deploy

| Option | Description | Selected |
|--------|-------------|----------|
| A. Section inline trong deploy/README.md | 1-2 trang tutorial login admin → menu Ký số → config provider → test connection → distribute Root CA | |
| B. File riêng HDSD_SIGNING_CONFIG.md + screenshot (Recommended) | Tiếng Việt có screenshot embedded, README link vào. Deliverable in ra giao KH. | |
| C. Cả 2 — README quick + file HDSD chi tiết | README quick steps + link vào file HDSD có screenshot + troubleshooting. | |

**User's choice:** "Bỏ task này, ko cần viết HDSD phần này đâu" — CẮT HẲN khỏi Phase 14.
**Notes:** Task không bao giờ làm trong v2.0. Move to milestone v2.1 sau khi tích hợp ký số thật có real creds + UI screenshot thật.

---

## 42 REQ-IDs Acceptance Checklist AC-04

| Option | Description | Selected |
|--------|-------------|----------|
| A. Update REQUIREMENTS.md đã có (Recommended) | Add column Verify Evidence + Status inline. Không tạo file mới, reuse source of truth. | ✓ |
| B. File riêng deploy/ACCEPTANCE-v2.0.md | Professional report grouped by category, deliverable riêng giao KH. | |
| C. Section trong deploy/README.md | Markdown table trong README 'Acceptance Checklist'. | |

**User's choice:** A — inline trong REQUIREMENTS.md.
**Notes:** Số REQ sẽ giảm từ 42 → 41 sau khi remove DEP-03. Verify Evidence format Claude's Discretion (planner chọn command phù hợp per REQ).

---

## UAT cuối AC-03

| Option | Description | Selected |
|--------|-------------|----------|
| A. Manual checklist + mock creds + migration query verify (Recommended) | Test qua mock adapter từ Phase 9. Migration verify = psql query check data preserved. UAT = checklist. | |
| B. Automated PowerShell smoke test | Tạo `smoke-test.ps1` check health + login + API + config + migration. Output pass/fail. | |
| C. Deferred UAT to post-deploy on KH server | Phase 14 chỉ lo scripts + HDSD + checklist. UAT thực tế sau khi KH deploy real creds. | |

**User's choice:** "Để sau này tích hợp ký số thật thì mới test" — CẮT HẲN khỏi Phase 14 (tương đương option C nhưng không tạo placeholder trong SUMMARY).
**Notes:** Defer đến milestone v2.1 khi có real integration. Migration sign_phone verify cũng defer (schema master đã consolidate Phase 11.1, không cần verify lại Phase 14).

---

## Defer scope — Handle 2 REQ/AC bị bỏ

| Option | Description | Selected |
|--------|-------------|----------|
| Tạo Phase 15 sau để track (Recommended) | Phase 15 'Post-integration: HDSD + UAT với real ký số'. Roadmap rõ, không bỏ lọt. | |
| Thêm backlog 999.x (parking lot) | Todo backlog 'HDSD + UAT phần ký số sau tích hợp'. Không chiếm slot phase chính. | |
| Note trong SUMMARY + REQUIREMENTS status='Deferred' | Mark deferred, không tạo phase/backlog mới. Team khi tích hợp thật tự pick up. | |
| Cắt hẳn 2 REQ khỏi milestone v2.0 | Remove DEP-03 + AC-03 khỏi `.planning/REQUIREMENTS.md` (42→40 REQ). Milestone v2.0 không commit deliver. | ✓ |

**User's choice:** Cắt hẳn 2 REQ này khỏi milestone v2.0.
**Notes:**
- DEP-03 remove khỏi REQUIREMENTS.md (41 REQ còn lại)
- AC-03 remove khỏi Phase 14 success criteria trong ROADMAP.md (3 AC còn lại)
- Khi tích hợp ký số thật thì 2 item này sẽ vào milestone v2.1 (tracked trong deferred section CONTEXT.md)

---

## Backup Strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Tạo backup-windows.ps1 đơn giản (Recommended) | docker exec pg_dump → .sql timestamp. README hướng dẫn Task Scheduler 2h sáng. | |
| Bỏ backup, chạy pg_dump tay khi cần | Xóa backup.sh Linux, không tạo Windows version. Admin chạy docker exec thủ công. | |
| Bỏ hẳn 'backup' khỏi scope Phase 14 | Không script không hướng dẫn. KH tự lo backup. | |

**User's choice:** "Chưa cần, vì dự án vẫn còn test và sửa, chưa chạy bản chính thức, chưa cần backup" — tương đương option "bỏ backup khỏi scope".
**Notes:** Xóa `backup.sh` Linux. Không tạo Windows equivalent. Khi production chính thức sẽ bổ sung (note trong deferred section CONTEXT.md).

---

## Claude's Discretion

- Wording tiếng Việt cho section "Development setup" trong deploy/README.md (D-04)
- Exact grep/psql/curl commands cho Verify Evidence column mỗi REQ (D-08) — planner chọn
- Thứ tự section sau khi remove Linux
- Có mention "No Linux support" trong README hay remove hoàn toàn không đề cập
- Banner cảnh báo "Production-ready checklist" đầu README (nice-to-have)

## Deferred Ideas

### Milestone v2.1 (khi tích hợp ký số thật)
- HDSD cấu hình ký số sau deploy với screenshot UI thật (cũ DEP-03)
- UAT cuối real credentials + migration sign_phone verify (cũ AC-03)
- Backup script Windows `backup-windows.ps1`
- Automated `smoke-test.ps1`

### Nice-to-have không scope v2.0
- Multi-tenant deploy
- Container orchestration (K8s)
- Backup off-site (S3/Azure Blob)
- Monitoring dashboards

