import type { Metadata } from 'next';
import { Plus_Jakarta_Sans } from 'next/font/google';
import AntdProvider from '@/components/layout/AntdProvider';
import './globals.css';

const jakartaSans = Plus_Jakarta_Sans({
  variable: '--font-jakarta',
  subsets: ['latin', 'vietnamese'],
  weight: ['300', '400', '500', '600', '700'],
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
    <html lang="vi" className={`${jakartaSans.variable} h-full`}>
      <body className="min-h-full" style={{ fontFamily: 'var(--font-jakarta), sans-serif' }}>
        <AntdProvider>{children}</AntdProvider>
      </body>
    </html>
  );
}
