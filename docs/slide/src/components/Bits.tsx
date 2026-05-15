import type { ReactNode } from 'react';
import { motion } from 'framer-motion';
import { fadeUp } from '@/layouts/Layouts';

/* ---------- CARD ---------- */
export function Card({
  icon,
  title,
  children,
  accent = false,
  className = '',
}: {
  icon?: ReactNode;
  title?: string;
  children: ReactNode;
  accent?: boolean;
  className?: string;
}) {
  return (
    <motion.div
      variants={fadeUp}
      className={`rounded-2xl p-7 border ${
        accent
          ? 'bg-gradient-to-br from-brand-600 to-brand-700 border-brand-700 text-white shadow-xl shadow-brand-600/20'
          : 'bg-white border-neutral-200 text-neutral-800 shadow-sm'
      } ${className}`}
    >
      {(icon || title) && (
        <div className="flex items-center gap-4 mb-4">
          {icon && (
            <div
              className={`w-14 h-14 rounded-xl flex items-center justify-center shrink-0 ${
                accent ? 'bg-white/15' : 'bg-brand-50 text-brand-700'
              }`}
            >
              {icon}
            </div>
          )}
          {title && (
            <div className={`font-bold text-2xl leading-tight ${accent ? 'text-white' : 'text-neutral-900'}`}>
              {title}
            </div>
          )}
        </div>
      )}
      <div className={`text-xl leading-relaxed ${accent ? 'text-white/90' : 'text-neutral-600'}`}>
        {children}
      </div>
    </motion.div>
  );
}

/* ---------- BIG STAT ---------- */
export function StatCard({
  value,
  label,
  caption,
  accent = false,
}: {
  value: string;
  label: string;
  caption?: string;
  accent?: boolean;
}) {
  return (
    <motion.div
      variants={fadeUp}
      className={`rounded-2xl p-8 ${
        accent
          ? 'bg-gradient-to-br from-brand-600 to-brand-800 text-white shadow-xl shadow-brand-600/30'
          : 'bg-neutral-50 border border-neutral-200 text-neutral-900'
      }`}
    >
      <div
        className={`text-6xl font-display font-extrabold tabular-nums leading-none ${
          accent ? 'text-white' : 'text-brand-700'
        }`}
      >
        {value}
      </div>
      <div
        className={`mt-4 text-xl font-semibold ${
          accent ? 'text-white/95' : 'text-neutral-800'
        }`}
      >
        {label}
      </div>
      {caption && (
        <div className={`mt-2 text-xl ${accent ? 'text-white/65' : 'text-neutral-500'}`}>
          {caption}
        </div>
      )}
    </motion.div>
  );
}

/* ---------- BULLET LIST ---------- */
export function BulletList({
  items,
  icon = '●',
  accent = false,
}: {
  items: ReactNode[];
  icon?: ReactNode;
  accent?: boolean;
}) {
  return (
    <ul className="space-y-3.5">
      {items.map((item, i) => (
        <motion.li key={i} variants={fadeUp} className="flex items-start gap-3.5">
          <span
            className={`mt-1.5 ${
              accent ? 'text-white/70' : 'text-accent-600'
            } text-xl shrink-0 leading-none`}
          >
            {icon}
          </span>
          <span className="flex-1">{item}</span>
        </motion.li>
      ))}
    </ul>
  );
}

/* ---------- PILL / BADGE ---------- */
export function Pill({
  children,
  tone = 'brand',
}: {
  children: ReactNode;
  tone?: 'brand' | 'ink' | 'emerald' | 'amber' | 'accent';
}) {
  const tones = {
    brand: 'bg-brand-50 text-brand-700 border-brand-200',
    accent: 'bg-accent-50 text-accent-700 border-accent-200',
    ink: 'bg-neutral-100 text-neutral-700 border-neutral-200',
    emerald: 'bg-emerald-50 text-emerald-700 border-emerald-200',
    amber: 'bg-amber-50 text-amber-700 border-amber-200',
  };
  return (
    <span
      className={`inline-flex items-center px-3.5 py-1.5 rounded-full text-xl font-bold uppercase tracking-wider border ${tones[tone]}`}
    >
      {children}
    </span>
  );
}

/* ---------- TIMELINE ROW ---------- */
export function TimelineRow({
  step,
  title,
  description,
  active = false,
}: {
  step: string;
  title: string;
  description?: string;
  active?: boolean;
}) {
  return (
    <motion.div variants={fadeUp} className="flex items-start gap-5">
      <div
        className={`shrink-0 w-14 h-14 rounded-xl flex items-center justify-center font-display font-bold text-xl ${
          active
            ? 'bg-brand-600 text-white shadow-lg shadow-brand-600/30'
            : 'bg-neutral-100 text-neutral-700 border border-neutral-200'
        }`}
      >
        {step}
      </div>
      <div className="flex-1 pt-2">
        <div className={`font-bold text-xl ${active ? 'text-brand-700' : 'text-neutral-900'}`}>
          {title}
        </div>
        {description && (
          <div className="text-xl text-neutral-600 mt-1.5 leading-relaxed">{description}</div>
        )}
      </div>
    </motion.div>
  );
}

/* ---------- TWO-COLUMN ---------- */
export function TwoColumn({
  left,
  right,
  ratio = '1:1',
}: {
  left: ReactNode;
  right: ReactNode;
  ratio?: '1:1' | '2:3' | '3:2' | '1:2' | '2:1';
}) {
  const ratios: Record<string, string> = {
    '1:1': 'grid-cols-2',
    '2:3': 'grid-cols-[2fr_3fr]',
    '3:2': 'grid-cols-[3fr_2fr]',
    '1:2': 'grid-cols-[1fr_2fr]',
    '2:1': 'grid-cols-[2fr_1fr]',
  };
  return (
    <div className={`grid ${ratios[ratio]} gap-10 items-start h-full`}>
      <div>{left}</div>
      <div>{right}</div>
    </div>
  );
}

/* ---------- FLOW STEP (for horizontal flow diagrams) ---------- */
export function FlowStep({
  step,
  title,
  caption,
  active = false,
}: {
  step: number;
  title: string;
  caption?: string;
  active?: boolean;
}) {
  return (
    <motion.div
      variants={fadeUp}
      className={`flex-1 rounded-2xl p-6 text-center ${
        active
          ? 'bg-gradient-to-br from-accent-500 to-accent-700 text-white shadow-xl shadow-accent-500/30'
          : 'bg-white border-2 border-neutral-200 text-neutral-800'
      }`}
    >
      <div
        className={`mx-auto w-12 h-12 rounded-full flex items-center justify-center font-display font-extrabold text-2xl mb-3 ${
          active ? 'bg-white/20 text-white' : 'bg-brand-50 text-brand-700'
        }`}
      >
        {step}
      </div>
      <div className={`font-bold text-xl leading-tight ${active ? 'text-white' : 'text-neutral-900'}`}>
        {title}
      </div>
      {caption && (
        <div className={`mt-2 text-xl leading-snug ${active ? 'text-white/85' : 'text-neutral-500'}`}>
          {caption}
        </div>
      )}
    </motion.div>
  );
}
