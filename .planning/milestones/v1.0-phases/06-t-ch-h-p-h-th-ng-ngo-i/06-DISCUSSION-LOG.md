# Phase 6: Tich hop he thong ngoai - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-15
**Phase:** 06-tich-hop-he-thong-ngoai
**Areas discussed:** LGSP lien thong, Ky so dien tu, Thong bao da kenh, Demo strategy

---

## LGSP Lien thong

### LGSP Access
| Option | Description | Selected |
|--------|-------------|----------|
| Co sandbox LGSP | Co URL + client_id/secret cua moi truong test LGSP tinh | |
| Mock toan bo | Chua co credentials — tao mock LGSP server local | |
| Mock + interface san | Mock cho demo, code viet du interface de doi env khi co credentials that | ✓ |

**User's choice:** Mock + interface san
**Notes:** None

### LGSP Receive Method
| Option | Description | Selected |
|--------|-------------|----------|
| Polling dinh ky | BullMQ repeatable job moi 30s-1min check LGSP | |
| Webhook + polling fallback | LGSP goi webhook khi co VB moi, polling la backup | |

**User's choice:** Tham khao source code cu xem xu ly nhu the nao, neu chua co thi khong can lam muc nay
**Notes:** User wants to defer to source code cu for this decision

### LGSP Send UI
| Option | Description | Selected |
|--------|-------------|----------|
| Nut tren VB di detail | Trang chi tiet VB di them nut 'Gui lien thong' | |
| Drawer rieng | Mo Drawer chon VB + co quan dich | |
| Theo source cu | Tham khao source code cu (.NET) | ✓ |

**User's choice:** Theo source cu
**Notes:** None

---

## Ky so dien tu

### Ky so Access
| Option | Description | Selected |
|--------|-------------|----------|
| Mock + interface san | Mock signing flow, code viet du interface | ✓ |
| Co sandbox SmartCA | Co tai khoan test VNPT SmartCA | |
| Co sandbox NEAC | Co tai khoan test EsignNEAC | |

**User's choice:** Mock + interface san
**Notes:** None

### Ky so UX
| Option | Description | Selected |
|--------|-------------|----------|
| Theo source cu | Tham khao source code cu (.NET) | ✓ |
| Nut tren VB du thao/VB di | Them nut 'Ky so' tren toolbar | |
| Modal chon phuong thuc ky | Click ky -> Modal chon SmartCA/NEAC -> OTP | |

**User's choice:** Theo source cu
**Notes:** None

---

## Thong bao da kenh

### Kenh uu tien
| Option | Description | Selected |
|--------|-------------|----------|
| Email + FCM | Email (Nodemailer) de setup nhat, FCM co free tier | |
| Ca 4 kenh mock | Mock tat ca 4 kenh, khong can credentials that | ✓ |
| Theo source cu | Xem source cu da tich hop nhung kenh nao | |

**User's choice:** Ca 4 kenh mock
**Notes:** None

### Notification Preferences
| Option | Description | Selected |
|--------|-------------|----------|
| Theo source cu | Xem source cu co UI preferences kenh thong bao khong | ✓ |
| Co — trang cai dat | Them trang cai dat thong bao: user chon kenh | |
| Khong can | He thong tu gui theo cau hinh admin | |

**User's choice:** Theo source cu
**Notes:** None

---

## Demo Strategy & Seed Data

### Seed Data
| Option | Description | Selected |
|--------|-------------|----------|
| 1 script toan bo | TRUNCATE toan bo -> seed lai tu dau voi data lien ket chuan | ✓ |
| Script theo phase | Moi phase co file seed rieng | |
| Cap nhat seed hien tai | Giu seed_demo.sql, them data moi | |

**User's choice:** 1 script toan bo
**Notes:** User emphasized: day la gan cuoi du an, can data chuan lien ket giua cac module de test

### Mock Layer
| Option | Description | Selected |
|--------|-------------|----------|
| Mock trong worker/service | Moi service co interface, mock implementation, env flag toggle | ✓ |
| Mock server rieng | Chay 1 Express mock server tra response gia | |
| Theo source cu | Xem source cu xu ly mock nhu the nao | |

**User's choice:** Mock trong worker/service
**Notes:** Env flag MOCK_EXTERNAL=true de toggle

---

## Claude's Discretion

- Mock response format chi tiet cho tung external API
- BullMQ queue configuration (concurrency, retry, delay)
- Migration file numbering
- Cach tich hop backend routes va BullMQ queues

## Deferred Ideas

None — discussion stayed within phase scope
