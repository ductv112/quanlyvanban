import { useEffect, useState, type ReactNode } from 'react';
import { aspect } from '@/theme/tokens';

interface SlideStageProps {
  children: ReactNode;
  fit?: 'contain' | 'cover';
}

/**
 * 16:9 stage locked at 1920x1080. Scaled with CSS transform to fit viewport.
 */
export function SlideStage({ children, fit = 'contain' }: SlideStageProps) {
  const [scale, setScale] = useState(1);

  useEffect(() => {
    const compute = () => {
      const sx = window.innerWidth / aspect.width;
      const sy = window.innerHeight / aspect.height;
      setScale(fit === 'contain' ? Math.min(sx, sy) : Math.max(sx, sy));
    };
    compute();
    window.addEventListener('resize', compute);
    return () => window.removeEventListener('resize', compute);
  }, [fit]);

  return (
    <div className="slide-viewport">
      <div className="slide-stage" style={{ transform: `scale(${scale})` }}>
        {children}
      </div>
    </div>
  );
}
