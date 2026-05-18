import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import { ArrowRight, Clock, Users, PlayCircle } from 'lucide-react';
import { decks } from '@/decks';
import { BrandMarkOnDark } from '@/components/BrandMark';

export function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-neutral-950 via-brand-950 to-brand-900 text-white">
      <div className="max-w-[1400px] mx-auto px-12 py-16">
        {/* Header */}
        <motion.div
          initial={{ opacity: 0, y: -10 }}
          animate={{ opacity: 1, y: 0 }}
          className="flex items-center gap-5 mb-16"
        >
          <BrandMarkOnDark size="lg" />
          <div className="border-l border-white/20 pl-5">
            <div className="text-base font-bold tracking-wide text-white/90">
              CÔNG TY CỔ PHẦN GIẢI PHÁP CÔNG NGHỆ SMART DIGIWORLD
            </div>
            <div className="text-sm text-white/50 mt-0.5">
              Đơn vị triển khai: Khối doanh nghiệp tỉnh Lạng Sơn
            </div>
          </div>
        </motion.div>

        {/* Hero */}
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.1 }}
          className="mb-16"
        >
          <div className="inline-flex items-center gap-3 mb-6">
            <div className="w-12 h-1 bg-accent-500" />
            <span className="text-accent-300 text-sm font-bold uppercase tracking-[0.25em]">
              Đào tạo người dùng cuối
            </span>
          </div>
          <h1 className="font-display text-7xl font-extrabold leading-[1.05] tracking-tight max-w-[1100px]">
            Hệ thống Quản lý <span className="text-accent-400">Văn bản điện tử</span>
          </h1>
          <p className="mt-8 text-2xl text-white/70 max-w-[900px] leading-relaxed">
            Slide đào tạo người dùng cuối — gồm 12 slide trình bày (20-25 phút), demo trực tiếp (50 phút) và Q&A (15-20 phút).
          </p>
        </motion.div>

        {/* Deck cards */}
        <div className="grid grid-cols-1 gap-6">
          {decks.map((deck, i) => (
            <motion.div
              key={deck.number}
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 + i * 0.05 }}
            >
              <Link
                to={`/dao-tao`}
                className="group block rounded-2xl bg-white/5 hover:bg-white/10 border border-white/10 hover:border-accent-500/50 p-8 transition-all"
              >
                <div className="flex items-center gap-8">
                  <div className="shrink-0 w-20 h-20 rounded-2xl bg-gradient-to-br from-accent-500 to-accent-700 flex items-center justify-center shadow-lg shadow-accent-600/30">
                    <PlayCircle size={36} className="text-white" />
                  </div>
                  <div className="flex-1">
                    <h3 className="font-display text-3xl font-bold text-white mb-2">
                      {deck.title}
                    </h3>
                    <p className="text-lg text-white/60 mb-4">{deck.subtitle}</p>
                    <div className="flex items-center gap-5 text-sm text-white/50">
                      <div className="flex items-center gap-1.5">
                        <Clock size={16} />
                        {deck.duration}
                      </div>
                      <div className="flex items-center gap-1.5">
                        <Users size={16} />
                        {deck.slides.length} slide
                      </div>
                    </div>
                  </div>
                  <ArrowRight
                    size={32}
                    className="text-white/40 group-hover:text-accent-400 group-hover:translate-x-2 transition-all shrink-0"
                  />
                </div>
              </Link>
            </motion.div>
          ))}
        </div>

        {/* Footer */}
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className="mt-20 pt-8 border-t border-white/10 flex items-center justify-between text-sm text-white/40"
        >
          <div>
            Phím tắt: <kbd className="px-2 py-0.5 rounded bg-white/5 mx-1">←/→</kbd> chuyển slide ·{' '}
            <kbd className="px-2 py-0.5 rounded bg-white/5 mx-1">F</kbd> Fullscreen ·{' '}
            <kbd className="px-2 py-0.5 rounded bg-white/5 mx-1">O</kbd> Overview
          </div>
          <div>Smart Digiworld · 19/05/2026</div>
        </motion.div>
      </div>
    </div>
  );
}
