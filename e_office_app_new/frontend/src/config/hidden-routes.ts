// Phase 1 feature flag: routes/modules tạm ẩn khỏi sidebar và mọi entry-point
// (dashboard cards, quick actions, breadcrumb fallback, ...). KHÔNG xóa code —
// muốn bật lại chỉ cần xóa entry tương ứng khỏi Set này.
//
// Convention: key có thể là route ('/tin-nhan') hoặc parent group key ('lich').
// Filter helpers chấp nhận cả 2 dạng.

export const HIDDEN_ROUTES: ReadonlySet<string> = new Set([
  // Tin nhắn
  '/tin-nhan',
  // Lịch (ẩn cả parent group 'lich' qua recursive check)
  'lich',
  '/lich/ca-nhan',
  '/lich/co-quan',
  '/lich/lanh-dao',
  // Danh bạ
  '/danh-ba',
  // Kho lưu trữ
  'kho-luu-tru',
  '/kho-luu-tru',
  '/kho-luu-tru/muon-tra',
  // Tài liệu
  '/tai-lieu',
  // Hợp đồng
  '/hop-dong',
  // Cuộc họp
  'cuoc-hop',
  '/cuoc-hop',
  '/cuoc-hop/thong-ke',
  // Phase 37: LGSP menu unhide (/lgsp + /lgsp/co-quan + /lgsp/cau-hinh hiện trên sidebar admin)
  // Kênh thông báo vẫn ẩn
  '/thong-bao-kenh',
  // Quản trị items bị ẩn (chuyển sang Phase 2)
  '/quan-tri/chuc-nang',
  '/quan-tri/cau-hinh-truong',
  '/quan-tri/co-quan',
  '/quan-tri/nhom-lam-viec',
  '/quan-tri/uy-quyen',
  '/quan-tri/dia-ban',
  '/quan-tri/lich-lam-viec',
  '/quan-tri/mau-thong-bao',
  '/quan-tri/cau-hinh',
]);
