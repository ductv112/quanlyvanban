/**
 * Smart Digiworld text-based brand mark — used on dark backgrounds.
 */
export function BrandMarkOnDark({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) {
  const sizes = {
    sm: 'h-10',
    md: 'h-14',
    lg: 'h-20',
  } as const;
  return (
    <div className={`inline-flex items-center ${sizes[size]}`}>
      <img
        src="/brand/logo.jpg"
        alt="Smart Digiworld"
        className="h-full w-auto rounded shadow-lg ring-1 ring-white/10"
      />
    </div>
  );
}
