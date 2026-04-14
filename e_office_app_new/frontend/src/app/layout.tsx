import type { Metadata } from 'next';
import { Inter } from 'next/font/google';
import AntdProvider from '@/components/layout/AntdProvider';
import './globals.css';

const inter = Inter({
  variable: '--font-inter',
  subsets: ['latin', 'vietnamese'],
  weight: ['400', '600', '700'],
});

export const metadata: Metadata = {
  title: 'Quản lý Văn bản',
  description: 'Hệ thống Quản lý Văn bản điện tử',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="vi" className={`${inter.variable} h-full`}>
      <body className="min-h-full" style={{ fontFamily: 'var(--font-inter), Inter, sans-serif' }}>
        <AntdProvider>{children}</AntdProvider>
      </body>
    </html>
  );
}
