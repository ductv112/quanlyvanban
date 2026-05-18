import { motion } from 'framer-motion';
import {
  CoverSlide,
  ContentSlide,
  StatementSlide,
  fadeUp,
  stagger,
} from '@/layouts/Layouts';
import { Card, Pill, TwoColumn, BulletList, FlowStep } from '@/components/Bits';
import type { SlideEntry } from '@/presenter/SlideDeck';
import {
  Inbox,
  Search,
  PenTool,
  BarChart3,
  FileText,
  Send,
  Edit3,
  FolderKanban,
  Bell,
  ShieldCheck,
  LayoutDashboard,
  ArrowRight,
  Users,
  UserCheck,
  Briefcase,
  MessageCircle,
  Phone,
  Mail,
  CheckCircle2,
  AlertTriangle,
  PlayCircle,
} from 'lucide-react';

const TOTAL = 12;

/* ============================================================
 * SLIDE 1 — BÌA
 * ============================================================ */
export function Slide01Cover() {
  return (
    <CoverSlide
      eyebrow="Đào tạo người dùng"
      title={'Hệ thống Quản lý\nVăn bản điện tử'}
      subtitle="Một nơi duy nhất quản lý toàn bộ vòng đời văn bản đến — đi — dự thảo — hồ sơ công việc — ký số."
      meta={[
        { label: 'Thời lượng', value: '90 phút' },
        { label: 'Ngày đào tạo', value: '19/05/2026' },
        { label: 'Người đào tạo', value: 'Khương PD' },
      ]}
    />
  );
}

/* ============================================================
 * SLIDE 2 — CHƯƠNG TRÌNH BUỔI HỌC
 * ============================================================ */
export function Slide02Agenda() {
  return (
    <ContentSlide
      eyebrow="Chương trình hôm nay"
      title="3 phần trong 90 phút — Trọng tâm là Demo thực tế"
      pageNumber={2}
      totalPages={TOTAL}
    >
      <motion.div
        variants={stagger}
        initial="hidden"
        animate="show"
        className="grid grid-cols-3 gap-6 mt-4"
      >
        <Card icon={<FileText size={28} strokeWidth={2.2} />} title="1. Giới thiệu hệ thống">
          <div className="text-2xl font-bold text-brand-700 mb-2">20-25 phút</div>
          Tổng quan, nghiệp vụ chính, hướng dẫn cơ bản trên slide.
        </Card>
        <Card icon={<PlayCircle size={28} strokeWidth={2.2} />} title="2. Demo trực tiếp" accent>
          <div className="text-2xl font-bold text-white mb-2">50 phút ⭐</div>
          Thao tác thật trên hệ thống: Văn bản đến → đi → ký số 2 kênh.
        </Card>
        <Card icon={<MessageCircle size={28} strokeWidth={2.2} />} title="3. Hỏi đáp & hỗ trợ">
          <div className="text-2xl font-bold text-brand-700 mb-2">15-20 phút</div>
          Giải đáp thắc mắc, phát tài khoản, chuyển giao hỗ trợ.
        </Card>
      </motion.div>
      <motion.div variants={fadeUp} className="mt-8 text-2xl text-neutral-600 italic text-center">
        Slide chỉ định hướng — phần chính là demo trực tiếp + thực hành.
      </motion.div>
    </ContentSlide>
  );
}

/* ============================================================
 * SLIDE 3 — HỆ THỐNG LÀ GÌ & LỢI ÍCH
 * ============================================================ */
export function Slide03WhatAndWhy() {
  const benefits = [
    { icon: <Inbox size={24} />, title: 'Không còn xử lý giấy thủ công' },
    { icon: <Search size={24} />, title: 'Tra cứu nhanh theo số / ngày / trích yếu' },
    { icon: <PenTool size={24} />, title: 'Ký số ngay — SmartCA hoặc Viettel CA' },
    { icon: <BarChart3 size={24} />, title: 'Báo cáo tự động, lưu vết đầy đủ' },
  ];
  return (
    <ContentSlide
      eyebrow="Hệ thống là gì"
      title="Một nơi duy nhất — Quản lý toàn bộ vòng đời văn bản"
      pageNumber={3}
      totalPages={TOTAL}
    >
      <TwoColumn
        ratio="2:3"
        left={
          <motion.div variants={stagger} initial="hidden" animate="show" className="space-y-6">
            <motion.div variants={fadeUp} className="text-2xl text-neutral-700 leading-relaxed">
              <BulletList
                items={[
                  <span>Quản lý <strong>Văn bản đến – đi – dự thảo – hồ sơ công việc</strong></span>,
                  <span>Chạy trên <strong>trình duyệt web</strong>: máy tính, laptop, điện thoại</span>,
                  <span><strong>Ký số trực tiếp</strong> trên hệ thống</span>,
                  <span>Lưu vết đầy đủ — không bao giờ mất</span>,
                ]}
              />
            </motion.div>
            <motion.div variants={fadeUp} className="flex gap-3 flex-wrap pt-4">
              <Pill tone="brand">SmartCA</Pill>
              <Pill tone="accent">Viettel CA</Pill>
              <Pill tone="ink">Web + Mobile</Pill>
            </motion.div>
          </motion.div>
        }
        right={
          <motion.div variants={stagger} initial="hidden" animate="show" className="grid grid-cols-2 gap-5">
            {benefits.map((b, i) => (
              <motion.div
                key={i}
                variants={fadeUp}
                className="rounded-xl border border-neutral-200 bg-white p-5 shadow-sm flex items-start gap-4"
              >
                <div className="w-12 h-12 rounded-lg bg-accent-50 text-accent-700 flex items-center justify-center shrink-0">
                  {b.icon}
                </div>
                <div className="text-xl font-semibold text-neutral-800 leading-snug">{b.title}</div>
              </motion.div>
            ))}
          </motion.div>
        }
      />
    </ContentSlide>
  );
}

/* ============================================================
 * SLIDE 4 — SƠ ĐỒ LUỒNG VĂN BẢN CỐT LÕI
 * ============================================================ */
export function Slide04CoreFlow() {
  return (
    <ContentSlide
      eyebrow="Luồng nghiệp vụ cốt lõi"
      title="Luồng anh/chị sẽ dùng hàng ngày"
      pageNumber={4}
      totalPages={TOTAL}
    >
      <motion.div variants={stagger} initial="hidden" animate="show" className="space-y-8">
        {/* Flow row 1 */}
        <motion.div variants={fadeUp} className="flex items-center gap-3">
          <FlowStep step={1} title="Văn bản đến" caption="Tiếp nhận" />
          <ArrowRight className="text-accent-600 shrink-0" size={32} />
          <FlowStep step={2} title="Văn thư" caption="Vào sổ" />
          <ArrowRight className="text-accent-600 shrink-0" size={32} />
          <FlowStep step={3} title="Lãnh đạo" caption="Bút phê" active />
        </motion.div>
        {/* Flow row 2 */}
        <motion.div variants={fadeUp} className="flex items-center gap-3">
          <FlowStep step={6} title="Phát hành" caption="Gửi nội bộ" />
          <ArrowRight className="text-accent-600 shrink-0 rotate-180" size={32} />
          <FlowStep step={5} title="Ký số" caption="SmartCA / Viettel" active />
          <ArrowRight className="text-accent-600 shrink-0 rotate-180" size={32} />
          <FlowStep step={4} title="Chuyên viên" caption="Soạn VB đi" />
        </motion.div>

        {/* Roles legend */}
        <motion.div variants={fadeUp} className="grid grid-cols-3 gap-6 mt-8">
          <div className="rounded-xl bg-brand-50 border border-brand-200 p-5">
            <div className="flex items-center gap-3 mb-2">
              <Users size={24} className="text-brand-700" />
              <div className="text-2xl font-bold text-brand-700">Văn thư</div>
            </div>
            <div className="text-xl text-neutral-700">Vào sổ, scan, cấp số, phát hành</div>
          </div>
          <div className="rounded-xl bg-accent-50 border border-accent-200 p-5">
            <div className="flex items-center gap-3 mb-2">
              <UserCheck size={24} className="text-accent-700" />
              <div className="text-2xl font-bold text-accent-700">Lãnh đạo</div>
            </div>
            <div className="text-xl text-neutral-700">Bút phê, giao xử lý, ký số</div>
          </div>
          <div className="rounded-xl bg-neutral-100 border border-neutral-300 p-5">
            <div className="flex items-center gap-3 mb-2">
              <Briefcase size={24} className="text-neutral-700" />
              <div className="text-2xl font-bold text-neutral-800">Chuyên viên</div>
            </div>
            <div className="text-xl text-neutral-700">Xử lý nội dung, soạn VB đi</div>
          </div>
        </motion.div>
      </motion.div>
    </ContentSlide>
  );
}

/* ============================================================
 * SLIDE 5 — CÁC PHÂN HỆ
 * ============================================================ */
export function Slide05Modules() {
  const modules = [
    { icon: <Inbox size={28} />, title: 'Văn bản đến', desc: 'Tiếp nhận, vào sổ, theo dõi xử lý' },
    { icon: <Send size={28} />, title: 'Văn bản đi', desc: 'Soạn thảo, trình ký, phát hành' },
    { icon: <Edit3 size={28} />, title: 'Văn bản dự thảo', desc: 'Soạn nháp cá nhân, xin ý kiến' },
    { icon: <FolderKanban size={28} />, title: 'Hồ sơ công việc', desc: 'Gom văn bản liên quan thành hồ sơ' },
    { icon: <PenTool size={28} />, title: 'Ký số', desc: 'SmartCA + Viettel CA' },
    { icon: <Bell size={28} />, title: 'Thông báo', desc: 'Việc cần xử lý, bút phê mới' },
  ];
  return (
    <ContentSlide
      eyebrow="Các phân hệ chính"
      title="6 phân hệ — Tùy vai trò sẽ thấy phân hệ phù hợp"
      pageNumber={5}
      totalPages={TOTAL}
    >
      <motion.div
        variants={stagger}
        initial="hidden"
        animate="show"
        className="grid grid-cols-3 gap-5"
      >
        {modules.map((m, i) => (
          <motion.div
            key={i}
            variants={fadeUp}
            className="rounded-2xl bg-white border-2 border-neutral-200 p-6 shadow-sm hover:shadow-md hover:border-accent-300 transition"
          >
            <div className="w-14 h-14 rounded-xl bg-brand-50 text-brand-700 flex items-center justify-center mb-4">
              {m.icon}
            </div>
            <div className="text-2xl font-bold text-neutral-900 mb-2">{m.title}</div>
            <div className="text-xl text-neutral-600 leading-snug">{m.desc}</div>
          </motion.div>
        ))}
      </motion.div>
    </ContentSlide>
  );
}

/* ============================================================
 * SLIDE 6 — ĐĂNG NHẬP & GIAO DIỆN
 * ============================================================ */
export function Slide06Login() {
  return (
    <ContentSlide
      eyebrow="Bắt đầu sử dụng"
      title="Đăng nhập lần đầu — 4 bước đơn giản"
      pageNumber={6}
      totalPages={TOTAL}
    >
      <TwoColumn
        ratio="1:1"
        left={
          <motion.div variants={stagger} initial="hidden" animate="show" className="space-y-5">
            {[
              { n: 1, title: 'Mở trình duyệt', desc: 'Chrome / Edge / Cốc Cốc → vào địa chỉ hệ thống' },
              { n: 2, title: 'Nhập tài khoản', desc: 'Tên đăng nhập + mật khẩu do Quản trị viên cấp' },
              { n: 3, title: 'Đổi mật khẩu', desc: 'Bắt buộc trong lần đầu — vì lý do bảo mật' },
              { n: 4, title: 'Lưu URL vào dấu trang', desc: 'Truy cập nhanh các lần sau' },
            ].map((s) => (
              <motion.div key={s.n} variants={fadeUp} className="flex gap-5 items-start">
                <div className="shrink-0 w-14 h-14 rounded-xl bg-brand-600 text-white flex items-center justify-center font-display font-extrabold text-2xl shadow-lg shadow-brand-600/30">
                  {s.n}
                </div>
                <div className="pt-1">
                  <div className="text-2xl font-bold text-neutral-900">{s.title}</div>
                  <div className="text-xl text-neutral-600 mt-1.5">{s.desc}</div>
                </div>
              </motion.div>
            ))}
          </motion.div>
        }
        right={
          <motion.div variants={stagger} initial="hidden" animate="show" className="space-y-5">
            <motion.div variants={fadeUp}>
              <div className="rounded-2xl border-2 border-amber-300 bg-amber-50 p-6">
                <div className="flex items-center gap-3 mb-3">
                  <AlertTriangle size={28} className="text-amber-600" />
                  <div className="text-2xl font-bold text-amber-800">Lưu ý quan trọng</div>
                </div>
                <ul className="space-y-2 text-xl text-amber-900">
                  <li className="flex gap-2"><span>•</span>Không chia sẻ tài khoản cho người khác</li>
                  <li className="flex gap-2"><span>•</span>Mật khẩu mới ≥ 8 ký tự, có chữ hoa + số</li>
                  <li className="flex gap-2"><span>•</span>Quên mật khẩu → liên hệ Quản trị viên</li>
                </ul>
              </div>
            </motion.div>
            <motion.div variants={fadeUp}>
              <div className="rounded-2xl border-2 border-brand-200 bg-brand-50 p-6">
                <div className="flex items-center gap-3 mb-3">
                  <LayoutDashboard size={28} className="text-brand-700" />
                  <div className="text-2xl font-bold text-brand-800">Giao diện chính</div>
                </div>
                <ul className="space-y-2 text-xl text-neutral-700">
                  <li className="flex gap-2"><span className="text-accent-600 font-bold">•</span>Sidebar trái — menu chức năng</li>
                  <li className="flex gap-2"><span className="text-accent-600 font-bold">•</span>Header trên — thông báo, tài khoản</li>
                  <li className="flex gap-2"><span className="text-accent-600 font-bold">•</span>Trung tâm — khu vực làm việc</li>
                  <li className="flex gap-2"><span className="text-accent-600 font-bold">•</span>Dashboard — việc cần xử lý hôm nay</li>
                </ul>
              </div>
            </motion.div>
          </motion.div>
        }
      />
    </ContentSlide>
  );
}

/* ============================================================
 * SLIDE 7 — VĂN BẢN ĐẾN
 * ============================================================ */
export function Slide07IncomingDoc() {
  return (
    <ContentSlide
      eyebrow="Nghiệp vụ Văn bản đến"
      title="4 bước — Từ tiếp nhận đến hoàn thành"
      pageNumber={7}
      totalPages={TOTAL}
    >
      <motion.div variants={stagger} initial="hidden" animate="show" className="space-y-7">
        <motion.div variants={fadeUp} className="flex items-stretch gap-3">
          <FlowStep step={1} title="Tiếp nhận" caption="Văn thư" />
          <ArrowRight className="self-center text-accent-600 shrink-0" size={32} />
          <FlowStep step={2} title="Trình lãnh đạo" caption="Văn thư" />
          <ArrowRight className="self-center text-accent-600 shrink-0" size={32} />
          <FlowStep step={3} title="Chỉ đạo xử lý" caption="Lãnh đạo" active />
          <ArrowRight className="self-center text-accent-600 shrink-0" size={32} />
          <FlowStep step={4} title="Theo dõi hoàn thành" caption="Chuyên viên" />
        </motion.div>

        <motion.div variants={fadeUp} className="grid grid-cols-2 gap-6">
          <Card icon={<Users size={26} />} title="Văn thư">
            <BulletList
              items={[
                'Nhập thông tin: số, ngày, trích yếu, độ khẩn/mật',
                'Đính kèm file scan PDF gốc',
                'Vào sổ → chuyển lên lãnh đạo',
              ]}
            />
          </Card>
          <Card icon={<UserCheck size={26} />} title="Lãnh đạo">
            <BulletList
              items={[
                'Đọc nội dung, bút phê chỉ đạo',
                'Chọn người chủ trì + phối hợp',
                'Đặt thời hạn xử lý + mức ưu tiên',
              ]}
            />
          </Card>
        </motion.div>

        <motion.div
          variants={fadeUp}
          className="rounded-xl bg-gradient-to-r from-brand-50 to-accent-50 border border-brand-200 px-6 py-4 flex items-center gap-4"
        >
          <ShieldCheck size={32} className="text-brand-700 shrink-0" />
          <div className="text-2xl text-neutral-800">
            <strong className="text-brand-700">Mọi bước đều lưu vết đầy đủ</strong> — biết ai làm gì, lúc nào, mất bao lâu.
          </div>
        </motion.div>
      </motion.div>
    </ContentSlide>
  );
}

/* ============================================================
 * SLIDE 8 — VĂN BẢN ĐI
 * ============================================================ */
export function Slide08OutgoingDoc() {
  return (
    <ContentSlide
      eyebrow="Nghiệp vụ Văn bản đi"
      title="5 bước — Từ soạn dự thảo đến phát hành"
      pageNumber={8}
      totalPages={TOTAL}
    >
      <motion.div variants={stagger} initial="hidden" animate="show" className="space-y-7">
        <motion.div variants={fadeUp} className="flex items-stretch gap-2.5">
          <FlowStep step={1} title="Soạn dự thảo" caption="Chuyên viên" />
          <ArrowRight className="self-center text-accent-600 shrink-0" size={28} />
          <FlowStep step={2} title="Trình duyệt" caption="Trưởng phòng" />
          <ArrowRight className="self-center text-accent-600 shrink-0" size={28} />
          <FlowStep step={3} title="Ký số" caption="Lãnh đạo" active />
          <ArrowRight className="self-center text-accent-600 shrink-0" size={28} />
          <FlowStep step={4} title="Cấp số & Phát hành" caption="Văn thư" />
          <ArrowRight className="self-center text-accent-600 shrink-0" size={28} />
          <FlowStep step={5} title="Theo dõi" caption="Người soạn" />
        </motion.div>

        <motion.div variants={fadeUp} className="grid grid-cols-2 gap-6">
          <div className="rounded-2xl bg-white border-2 border-neutral-200 p-6">
            <div className="text-2xl font-bold text-neutral-900 mb-3">Người duyệt có 3 lựa chọn</div>
            <div className="space-y-3">
              <div className="flex items-center gap-3 text-xl">
                <CheckCircle2 size={22} className="text-emerald-600 shrink-0" />
                <span><strong className="text-emerald-700">Đồng ý</strong> → chuyển cấp duyệt tiếp</span>
              </div>
              <div className="flex items-center gap-3 text-xl">
                <ArrowRight size={22} className="text-amber-600 shrink-0 rotate-180" />
                <span><strong className="text-amber-700">Trả lại</strong> → người soạn sửa và gửi lại</span>
              </div>
              <div className="flex items-center gap-3 text-xl">
                <AlertTriangle size={22} className="text-rose-600 shrink-0" />
                <span><strong className="text-rose-700">Từ chối</strong> → văn bản kết thúc</span>
              </div>
            </div>
          </div>

          <div className="rounded-2xl bg-gradient-to-br from-brand-600 to-brand-800 text-white p-6 shadow-xl shadow-brand-600/20">
            <div className="text-2xl font-bold mb-3">Sau khi phát hành — Theo dõi 3 trạng thái</div>
            <div className="space-y-3">
              <div className="flex items-center gap-3 text-xl">
                <Send size={22} className="shrink-0" />
                <span><strong>Đã gửi</strong> — hệ thống đã chuyển đi</span>
              </div>
              <div className="flex items-center gap-3 text-xl">
                <Inbox size={22} className="shrink-0" />
                <span><strong>Đã nhận</strong> — nơi nhận đã thấy</span>
              </div>
              <div className="flex items-center gap-3 text-xl">
                <CheckCircle2 size={22} className="shrink-0 text-accent-300" />
                <span><strong>Đã đọc</strong> — nơi nhận đã mở file</span>
              </div>
            </div>
          </div>
        </motion.div>
      </motion.div>
    </ContentSlide>
  );
}

/* ============================================================
 * SLIDE 9 — KÝ SỐ 2 KÊNH ⭐
 * ============================================================ */
export function Slide09DigitalSign() {
  return (
    <ContentSlide
      eyebrow="Ký số — Trọng tâm buổi học"
      title="Hệ thống hỗ trợ 2 kênh ký số"
      pageNumber={9}
      totalPages={TOTAL}
    >
      <motion.div variants={stagger} initial="hidden" animate="show" className="space-y-6">
        <motion.div variants={fadeUp} className="grid grid-cols-2 gap-7">
          {/* SmartCA */}
          <div className="rounded-2xl bg-white border-2 border-brand-300 p-7 shadow-lg">
            <div className="flex items-center gap-4 mb-5">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-brand-600 to-brand-800 text-white flex items-center justify-center font-display font-extrabold text-3xl">
                S
              </div>
              <div>
                <div className="text-3xl font-bold text-brand-700">VNPT SmartCA</div>
                <div className="text-xl text-neutral-500 mt-0.5">Chứng thư số cá nhân do VNPT cấp</div>
              </div>
            </div>
            <div className="space-y-3 text-xl">
              <div className="flex gap-3">
                <span className="text-brand-600 font-bold shrink-0">1.</span>
                <span>Chọn <strong>"Ký số"</strong> trên hệ thống</span>
              </div>
              <div className="flex gap-3">
                <span className="text-brand-600 font-bold shrink-0">2.</span>
                <span>Chọn kênh <strong>SmartCA</strong></span>
              </div>
              <div className="flex gap-3">
                <span className="text-brand-600 font-bold shrink-0">3.</span>
                <span>Mở app <strong>SmartCA</strong> trên điện thoại</span>
              </div>
              <div className="flex gap-3">
                <span className="text-brand-600 font-bold shrink-0">4.</span>
                <span>Xác nhận → ký xong (~10-30 giây)</span>
              </div>
            </div>
          </div>

          {/* Viettel CA */}
          <div className="rounded-2xl bg-white border-2 border-accent-300 p-7 shadow-lg">
            <div className="flex items-center gap-4 mb-5">
              <div className="w-16 h-16 rounded-2xl bg-gradient-to-br from-accent-600 to-accent-800 text-white flex items-center justify-center font-display font-extrabold text-3xl">
                V
              </div>
              <div>
                <div className="text-3xl font-bold text-accent-700">Viettel CA</div>
                <div className="text-xl text-neutral-500 mt-0.5">Chứng thư số cá nhân do Viettel cấp</div>
              </div>
            </div>
            <div className="space-y-3 text-xl">
              <div className="flex gap-3">
                <span className="text-accent-600 font-bold shrink-0">1.</span>
                <span>Chọn <strong>"Ký số"</strong> trên hệ thống</span>
              </div>
              <div className="flex gap-3">
                <span className="text-accent-600 font-bold shrink-0">2.</span>
                <span>Chọn kênh <strong>Viettel CA</strong></span>
              </div>
              <div className="flex gap-3">
                <span className="text-accent-600 font-bold shrink-0">3.</span>
                <span>Mở app <strong>Viettel CA</strong> trên điện thoại</span>
              </div>
              <div className="flex gap-3">
                <span className="text-accent-600 font-bold shrink-0">4.</span>
                <span>Xác nhận → ký xong (~10-30 giây)</span>
              </div>
            </div>
          </div>
        </motion.div>

        <motion.div
          variants={fadeUp}
          className="rounded-xl bg-gradient-to-r from-emerald-50 to-accent-50 border border-emerald-200 px-7 py-5"
        >
          <div className="flex items-start gap-4">
            <ShieldCheck size={32} className="text-emerald-700 shrink-0 mt-0.5" />
            <div className="text-xl text-neutral-800 leading-relaxed">
              Cả 2 kênh đều <strong className="text-emerald-700">hợp pháp</strong> — có giá trị pháp lý
              như chữ ký tay đóng dấu. Chọn 1 kênh tùy chứng thư số đã đăng ký. Hệ thống tự gắn chữ ký + thời gian vào file PDF.
            </div>
          </div>
        </motion.div>
      </motion.div>
    </ContentSlide>
  );
}

/* ============================================================
 * SLIDE 10 — HỒ SƠ + THÔNG BÁO
 * ============================================================ */
export function Slide10WorkfileNotif() {
  return (
    <ContentSlide
      eyebrow="Công cụ hỗ trợ hàng ngày"
      title="Hồ sơ công việc & Thông báo"
      pageNumber={10}
      totalPages={TOTAL}
    >
      <TwoColumn
        ratio="1:1"
        left={
          <motion.div variants={stagger} initial="hidden" animate="show">
            <Card icon={<FolderKanban size={28} />} title="Hồ sơ công việc">
              <div className="space-y-3">
                <div className="text-xl">
                  Gom <strong>nhiều văn bản liên quan</strong> thành 1 hồ sơ theo chủ đề / vụ việc.
                </div>
                <div className="rounded-lg bg-brand-50 border border-brand-200 p-4 text-xl">
                  <div className="text-brand-700 font-bold mb-1">Ví dụ:</div>
                  Hồ sơ "Dự án xây dựng cầu X" gồm văn bản chỉ đạo + báo cáo + quyết định
                </div>
                <BulletList
                  items={[
                    'Tra cứu theo chủ đề thay vì lục từng văn bản',
                    'Bàn giao công việc dễ dàng khi chuyển vị trí',
                    'Phân quyền xem hồ sơ',
                  ]}
                />
              </div>
            </Card>
          </motion.div>
        }
        right={
          <motion.div variants={stagger} initial="hidden" animate="show">
            <Card icon={<Bell size={28} />} title="Thông báo" accent>
              <div className="space-y-3">
                <div className="text-xl">
                  Tổng hợp việc cần xử lý — không bỏ sót bằng cách phải nhớ thủ công.
                </div>
                <BulletList
                  accent
                  items={[
                    'Văn bản mới gửi đến',
                    'Bút phê mới từ lãnh đạo',
                    'Kết quả ký số',
                    'Lịch cuộc họp được mời',
                  ]}
                />
                <div className="rounded-lg bg-white/10 border border-white/20 p-4 text-xl mt-3">
                  <strong>Mẹo:</strong> Check Thông báo đầu giờ sáng + cuối giờ chiều — tránh quá hạn.
                </div>
              </div>
            </Card>
          </motion.div>
        }
      />
    </ContentSlide>
  );
}

/* ============================================================
 * SLIDE 11 — LƯU Ý & KÊNH HỖ TRỢ
 * ============================================================ */
export function Slide11RulesSupport() {
  return (
    <ContentSlide
      eyebrow="Trước khi sử dụng"
      title="5 nguyên tắc vàng & Kênh hỗ trợ sau đào tạo"
      pageNumber={11}
      totalPages={TOTAL}
    >
      <TwoColumn
        ratio="1:1"
        left={
          <motion.div variants={stagger} initial="hidden" animate="show" className="space-y-4">
            <motion.div variants={fadeUp} className="text-2xl font-bold text-brand-700 mb-2">
              5 nguyên tắc vàng
            </motion.div>
            {[
              'Đổi mật khẩu ngay lần đăng nhập đầu',
              'Không chia sẻ tài khoản cho người khác',
              'Trích yếu phải viết tiếng Việt có dấu',
              'File đính kèm đúng định dạng (PDF/Word, < 50MB)',
              'Đăng xuất khi rời máy',
            ].map((rule, i) => (
              <motion.div key={i} variants={fadeUp} className="flex items-start gap-4">
                <div className="shrink-0 w-10 h-10 rounded-full bg-emerald-100 text-emerald-700 flex items-center justify-center font-bold text-xl">
                  {i + 1}
                </div>
                <div className="text-xl text-neutral-800 pt-1.5">{rule}</div>
              </motion.div>
            ))}
          </motion.div>
        }
        right={
          <motion.div variants={stagger} initial="hidden" animate="show" className="space-y-4">
            <motion.div variants={fadeUp} className="text-2xl font-bold text-accent-700 mb-2">
              Kênh hỗ trợ
            </motion.div>
            {[
              { icon: <Phone size={26} />, label: 'Hotline', value: '0374 813 705' },
              { icon: <MessageCircle size={26} />, label: 'Zalo Group', value: '[QR code dán tại lớp]' },
              { icon: <Mail size={26} />, label: 'Email', value: 'khuongpd@sdgw.vn' },
            ].map((c) => (
              <motion.div
                key={c.label}
                variants={fadeUp}
                className="rounded-xl bg-white border border-neutral-200 p-5 flex items-center gap-4 shadow-sm"
              >
                <div className="w-12 h-12 rounded-xl bg-accent-50 text-accent-700 flex items-center justify-center shrink-0">
                  {c.icon}
                </div>
                <div>
                  <div className="text-xl text-neutral-500">{c.label}</div>
                  <div className="text-2xl font-bold text-neutral-900">{c.value}</div>
                </div>
              </motion.div>
            ))}
            <motion.div variants={fadeUp} className="rounded-xl bg-brand-700 text-white p-5">
              <div className="text-xl font-bold mb-2">Cam kết hỗ trợ</div>
              <div className="text-xl space-y-1">
                <div>Tuần 1: Hỗ trợ <strong>onsite</strong> tại đơn vị</div>
                <div>Tuần 2-4: Hỗ trợ từ xa qua Zalo / Hotline</div>
              </div>
            </motion.div>
          </motion.div>
        }
      />
    </ContentSlide>
  );
}

/* ============================================================
 * SLIDE 12 — CHUYỂN SANG DEMO / CẢM ƠN
 * ============================================================ */
export function Slide12ThankYou() {
  return (
    <StatementSlide
      eyebrow="Bây giờ — Thao tác trực tiếp"
      statement="Cảm ơn anh/chị. Chúng ta cùng vào hệ thống thực tế!"
      attribution="Smart Digiworld · Đào tạo Hệ thống Quản lý Văn bản"
    />
  );
}

/* ============================================================
 * SLIDE LIST
 * ============================================================ */
export const slideList: SlideEntry[] = [
  { id: 'cover', Component: Slide01Cover },
  { id: 'agenda', Component: Slide02Agenda },
  { id: 'what-and-why', Component: Slide03WhatAndWhy },
  { id: 'core-flow', Component: Slide04CoreFlow },
  { id: 'modules', Component: Slide05Modules },
  { id: 'login', Component: Slide06Login },
  { id: 'incoming-doc', Component: Slide07IncomingDoc },
  { id: 'outgoing-doc', Component: Slide08OutgoingDoc },
  { id: 'digital-sign', Component: Slide09DigitalSign },
  { id: 'workfile-notif', Component: Slide10WorkfileNotif },
  { id: 'rules-support', Component: Slide11RulesSupport },
  { id: 'thank-you', Component: Slide12ThankYou },
];
