'use client';

import React from 'react';
import { ConfigProvider, App } from 'antd';
import viVN from 'antd/locale/vi_VN';
import { appTheme } from '@/config/theme';

export default function AntdProvider({ children }: { children: React.ReactNode }) {
  return (
    <ConfigProvider theme={appTheme} locale={viVN}>
      <App>{children}</App>
    </ConfigProvider>
  );
}
