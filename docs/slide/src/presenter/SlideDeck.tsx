import { useEffect, useState, type ComponentType } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import { ChevronLeft, ChevronRight, Maximize2, Minimize2, Grid3x3, X } from 'lucide-react';
import { Link, useNavigate } from 'react-router-dom';
import { SlideStage } from './SlideStage';

export interface SlideEntry {
  id: string;
  Component: ComponentType;
  notes?: string;
}

export interface DeckMeta {
  number: number;
  title: string;
  subtitle?: string;
  duration?: string;
  slides: SlideEntry[];
}

export function SlideDeck({ deck }: { deck: DeckMeta }) {
  const [index, setIndex] = useState(0);
  const [overview, setOverview] = useState(false);
  const [fullscreen, setFullscreen] = useState(false);
  const navigate = useNavigate();

  const total = deck.slides.length;
  const current = deck.slides[index];

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowRight' || e.key === ' ' || e.key === 'PageDown') {
        e.preventDefault();
        setIndex((i) => Math.min(total - 1, i + 1));
      } else if (e.key === 'ArrowLeft' || e.key === 'PageUp') {
        e.preventDefault();
        setIndex((i) => Math.max(0, i - 1));
      } else if (e.key === 'Home') {
        setIndex(0);
      } else if (e.key === 'End') {
        setIndex(total - 1);
      } else if (e.key === 'f' || e.key === 'F') {
        toggleFullscreen();
      } else if (e.key === 'Escape') {
        if (overview) setOverview(false);
        else if (document.fullscreenElement) document.exitFullscreen();
      } else if (e.key === 'o' || e.key === 'O' || e.key === 'Tab') {
        e.preventDefault();
        setOverview((v) => !v);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [total, overview]);

  useEffect(() => {
    const onChange = () => setFullscreen(!!document.fullscreenElement);
    document.addEventListener('fullscreenchange', onChange);
    return () => document.removeEventListener('fullscreenchange', onChange);
  }, []);

  const toggleFullscreen = () => {
    if (document.fullscreenElement) document.exitFullscreen();
    else document.documentElement.requestFullscreen();
  };

  if (overview) {
    return (
      <div className="fixed inset-0 bg-neutral-950/95 backdrop-blur-sm overflow-auto z-50 p-10">
        <div className="flex items-center justify-between mb-6">
          <div>
            <div className="text-accent-400 text-sm font-semibold uppercase tracking-wider">
              Overview · {total} slide
            </div>
            <h2 className="text-white text-3xl font-bold font-display">{deck.title}</h2>
          </div>
          <button
            onClick={() => setOverview(false)}
            className="text-white/70 hover:text-white p-2 rounded-lg hover:bg-white/10"
          >
            <X size={28} />
          </button>
        </div>
        <div className="grid grid-cols-4 gap-6">
          {deck.slides.map((s, i) => (
            <button
              key={s.id}
              onClick={() => {
                setIndex(i);
                setOverview(false);
              }}
              className={`relative aspect-video rounded-lg overflow-hidden border-2 transition-all ${
                i === index
                  ? 'border-accent-500 shadow-lg shadow-accent-500/40'
                  : 'border-white/10 hover:border-white/30'
              }`}
            >
              <div
                className="origin-top-left bg-white"
                style={{ width: 1920, height: 1080, transform: 'scale(0.18)' }}
              >
                <s.Component />
              </div>
              <div className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-black/80 to-transparent p-2">
                <span className="text-white text-xs font-semibold">{i + 1}</span>
              </div>
            </button>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="relative">
      <SlideStage>
        <AnimatePresence mode="wait">
          <motion.div
            key={current.id}
            initial={{ opacity: 0, x: 12 }}
            animate={{ opacity: 1, x: 0 }}
            exit={{ opacity: 0, x: -12 }}
            transition={{ duration: 0.25, ease: [0.4, 0, 0.2, 1] }}
            className="absolute inset-0"
          >
            <current.Component />
          </motion.div>
        </AnimatePresence>
      </SlideStage>

      {/* Controls */}
      <div className="fixed bottom-3 right-32 print:hidden z-40">
        <div className="flex items-center gap-0.5 px-2 py-1 rounded-full bg-neutral-900/85 backdrop-blur border border-white/10 shadow-2xl">
          <button
            onClick={() => navigate('/')}
            className="px-2 py-1 text-[11px] text-white/60 hover:text-white rounded-full hover:bg-white/10 transition"
            title="Trang chính"
          >
            ← Trang chính
          </button>
          <div className="w-px h-3 bg-white/15 mx-0.5" />
          <button
            onClick={() => setIndex((i) => Math.max(0, i - 1))}
            disabled={index === 0}
            className="p-1.5 text-white/80 hover:text-white rounded-full hover:bg-white/10 disabled:opacity-30 disabled:hover:bg-transparent transition"
          >
            <ChevronLeft size={14} />
          </button>
          <span className="text-white/90 text-[11px] font-medium tabular-nums px-1.5 min-w-[50px] text-center">
            {index + 1} / {total}
          </span>
          <button
            onClick={() => setIndex((i) => Math.min(total - 1, i + 1))}
            disabled={index === total - 1}
            className="p-1.5 text-white/80 hover:text-white rounded-full hover:bg-white/10 disabled:opacity-30 disabled:hover:bg-transparent transition"
          >
            <ChevronRight size={14} />
          </button>
          <div className="w-px h-3 bg-white/15 mx-0.5" />
          <button
            onClick={() => setOverview(true)}
            className="p-1.5 text-white/80 hover:text-white rounded-full hover:bg-white/10 transition"
            title="Overview (O)"
          >
            <Grid3x3 size={13} />
          </button>
          <button
            onClick={toggleFullscreen}
            className="p-1.5 text-white/80 hover:text-white rounded-full hover:bg-white/10 transition"
            title="Fullscreen (F)"
          >
            {fullscreen ? <Minimize2 size={13} /> : <Maximize2 size={13} />}
          </button>
        </div>
      </div>

      {/* Progress bar */}
      <div className="fixed bottom-0 left-0 right-0 h-1 bg-white/5 print:hidden z-30">
        <div
          className="h-full bg-gradient-to-r from-brand-600 to-accent-500 transition-all duration-300"
          style={{ width: `${((index + 1) / total) * 100}%` }}
        />
      </div>

      {/* Top-left badge */}
      <Link
        to="/"
        className="fixed top-4 left-4 print:hidden z-40 flex items-center gap-2 px-3 py-1.5 rounded-full bg-neutral-900/70 backdrop-blur border border-white/10 text-white/70 hover:text-white text-xs font-medium transition"
      >
        <span className="max-w-[260px] truncate">{deck.title}</span>
      </Link>
    </div>
  );
}
