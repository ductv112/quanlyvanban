'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Skeleton } from 'antd';

export default function HomePage() {
  const router = useRouter();

  useEffect(() => {
    const token = localStorage.getItem('accessToken');
    if (token) {
      router.replace('/dashboard');
    } else {
      router.replace('/login');
    }
  }, [router]);

  return (
    <div style={{ padding: 48, maxWidth: 600, margin: '120px auto' }}>
      <Skeleton active paragraph={{ rows: 4 }} />
    </div>
  );
}
