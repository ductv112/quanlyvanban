// ============================================================
// LGSP Status Labels + Colors + Descriptions — Phase 36 Plan 36-04
// REQ: LGSP-STATUS-10
//
// Map 9 ma trang thai QD 28/2018/QD-TTg -> Vietnamese label + AntD Tag color + tooltip description
//
// Spec: Quyet dinh 28/2018/QD-TTg — "Quy dinh ve viec gui nhan VB dien tu"
//
// Su dung tai:
//   - frontend/src/components/lgsp-status-timeline.tsx (Plan 36-04 detail page Timeline)
//   - frontend/src/app/(main)/quan-tri/lgsp-config/ (Phase 37 admin UI — reuse)
//   - frontend/src/app/(main)/van-ban-di/[id]/ (Phase 37 sender-side UI 13/15/16 — reuse)
// ============================================================

/**
 * 9 ma trang thai QD 28/2018:
 *   01 — Da gui (sender-side, Phase 35 receive auto-INSERT khi nhan VB tu truc)
 *   02 — Tu choi tiep nhan (receiver-side, Phase 36 chuyen-lai LGSP doc)
 *   03 — Da tiep nhan (receiver-side, Phase 36 mark-read)
 *   04 — Phan cong (receiver-side, Phase 36 giao-viec)
 *   05 — Dang xu ly (receiver-side, Phase 36 but-phe + them-vao-hscv)
 *   06 — Hoan thanh (receiver-side, Phase 36 chuyen-luu-tru + HSCV complete)
 *   13 — Lay lai VB (sender-side, defer Phase 37)
 *   15 — Dong y lay lai (receiver-side, defer Phase 37)
 *   16 — Tu choi lay lai (receiver-side, defer Phase 37)
 */
export type LgspTargetStatus = '01' | '02' | '03' | '04' | '05' | '06' | '13' | '15' | '16';

export const LGSP_STATUS_LABELS: Record<LgspTargetStatus, string> = {
  '01': 'Đã gửi',
  '02': 'Từ chối tiếp nhận',
  '03': 'Đã tiếp nhận',
  '04': 'Phân công',
  '05': 'Đang xử lý',
  '06': 'Hoàn thành',
  '13': 'Lấy lại',
  '15': 'Đồng ý lấy lại',
  '16': 'Từ chối lấy lại',
};

/**
 * AntD Tag color (token name hoac hex).
 * Per CONTEXT D-14: '06'=xanh la, '02/16'=do, '03/04/05'=vang/orange, '13'=xam, '15'=xanh, '01'=xanh duong
 */
export const LGSP_STATUS_COLORS: Record<LgspTargetStatus, string> = {
  '01': 'blue',       // Da gui (initial state khi nhan VB)
  '02': 'red',        // Tu choi tiep nhan (negative)
  '03': 'gold',       // Da tiep nhan (in-progress)
  '04': 'orange',     // Phan cong (in-progress)
  '05': 'processing', // Dang xu ly (in-progress -- AntD processing color = blue animated)
  '06': 'green',      // Hoan thanh (success final)
  '13': 'default',    // Lay lai (neutral request)
  '15': 'green',      // Dong y lay lai (success)
  '16': 'red',        // Tu choi lay lai (negative)
};

/**
 * Tooltip description day du (Vietnamese, hover ra full label).
 */
export const LGSP_STATUS_DESCRIPTIONS: Record<LgspTargetStatus, string> = {
  '01': 'Đơn vị gửi đã đẩy VB lên trục, đơn vị nhận đã nhận được',
  '02': 'Văn thư đơn vị nhận đã từ chối tiếp nhận VB (kèm lý do)',
  '03': 'Văn thư đơn vị nhận đã tiếp nhận VB vào hệ thống',
  '04': 'Lãnh đạo đã giao việc/phân công VB cho cán bộ xử lý',
  '05': 'Cán bộ đang xử lý VB (có bút phê hoặc đã thêm vào HSCV)',
  '06': 'VB đã được xử lý xong (chuyển lưu trữ hoặc HSCV đóng)',
  '13': 'Đơn vị gửi yêu cầu lấy lại VB đã gửi',
  '15': 'Đơn vị nhận đồng ý cho lấy lại VB',
  '16': 'Đơn vị nhận từ chối yêu cầu lấy lại',
};

/**
 * Tag color cho sent_status badge (worker xu ly outbox).
 */
export const SENT_STATUS_COLORS: Record<'pending' | 'success' | 'error', string> = {
  pending: 'orange',
  success: 'green',
  error: 'red',
};

export const SENT_STATUS_LABELS: Record<'pending' | 'success' | 'error', string> = {
  pending: 'Đang chờ gửi',
  success: 'Đã gửi',
  error: 'Lỗi',
};
