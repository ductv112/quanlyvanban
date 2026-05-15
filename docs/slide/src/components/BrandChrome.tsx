import { MapPin, Phone, Mail } from 'lucide-react';

/**
 * Smart Digiword brand chrome — header & footer used on every "content" slide.
 */

export function BrandHeader({ variant = 'light' }: { variant?: 'light' | 'dark' }) {
  return (
    <div
      className={`relative h-[120px] flex items-center px-16 ${
        variant === 'dark' ? 'bg-neutral-900' : 'bg-white'
      }`}
    >
      <img src="/brand/logo.jpg" alt="Smart Digiword" className="h-16 w-auto rounded" />
      <div
        className={`ml-6 pl-6 border-l-2 ${
          variant === 'dark' ? 'border-white/20' : 'border-neutral-200'
        }`}
      >
        <div
          className={`text-[20px] font-bold tracking-wide ${
            variant === 'dark' ? 'text-white' : 'text-neutral-900'
          }`}
        >
          CÔNG TY CỔ PHẦN GIẢI PHÁP CÔNG NGHỆ SMART DIGIWORD
        </div>
        <div
          className={`text-[20px] mt-1 ${
            variant === 'dark' ? 'text-white/60' : 'text-neutral-500'
          }`}
        >
          Đào tạo Hệ thống Quản lý Văn bản điện tử
        </div>
      </div>
      <div className="ml-auto flex items-center gap-4">
        <div className="text-right leading-tight">
          <div
            className={`text-[18px] uppercase tracking-[0.2em] font-bold ${
              variant === 'dark' ? 'text-white/50' : 'text-neutral-400'
            }`}
          >
            Triển khai cho
          </div>
          <div
            className={`text-2xl font-black ${
              variant === 'dark' ? 'text-white' : 'text-brand-700'
            }`}
          >
            DOANH NGHIỆP
          </div>
        </div>
      </div>
      <div className="absolute left-0 right-0 bottom-0 h-1.5 bg-gradient-to-r from-brand-700 via-accent-600 to-brand-700" />
    </div>
  );
}

export function BrandFooter({
  pageNumber,
  totalPages,
}: {
  pageNumber?: number;
  totalPages?: number;
}) {
  return (
    <div className="relative h-[90px] overflow-hidden">
      <div
        className="absolute inset-0 bg-gradient-to-r from-brand-700 via-brand-600 to-brand-600"
        style={{ clipPath: 'polygon(0 0, 86% 0, 92% 100%, 0 100%)' }}
      />
      <div
        className="absolute inset-0 bg-neutral-900"
        style={{ clipPath: 'polygon(86% 0, 100% 0, 100% 100%, 92% 100%)' }}
      />
      <div className="absolute right-[7%] top-0 bottom-0 w-[8%] bg-white/5" />

      <div className="relative h-full flex items-center px-16 gap-12 text-white text-[20px]">
        <div className="flex items-center gap-3">
          <MapPin size={20} className="text-white shrink-0" strokeWidth={2.2} />
          <div className="leading-snug">
            <div>Smart Digiword</div>
            <div className="text-white/70 text-[18px]">Giải pháp công nghệ doanh nghiệp</div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <Phone size={20} className="text-white shrink-0" strokeWidth={2.2} />
          <div className="font-semibold">[Hotline hỗ trợ]</div>
        </div>
        <div className="flex items-center gap-3">
          <Mail size={20} className="text-white shrink-0" strokeWidth={2.2} />
          <div className="font-semibold">[Email hỗ trợ]</div>
        </div>

        {pageNumber !== undefined && (
          <div className="ml-auto pr-6 text-white/90 text-[20px] font-semibold tabular-nums">
            {pageNumber}
            {totalPages !== undefined ? ` / ${totalPages}` : ''}
          </div>
        )}
      </div>
    </div>
  );
}
