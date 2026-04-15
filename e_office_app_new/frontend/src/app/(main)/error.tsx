'use client';

import { Button, Result } from 'antd';
import { ReloadOutlined } from '@ant-design/icons';

export default function MainError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      minHeight: 'calc(100vh - 200px)',
    }}>
      <Result
        status="error"
        title="\u0110\u00e3 x\u1ea3y ra l\u1ed7i"
        subTitle="R\u1ea5t ti\u1ebfc, \u0111\u00e3 c\u00f3 l\u1ed7i x\u1ea3y ra. Vui l\u00f2ng th\u1eed l\u1ea1i ho\u1eb7c li\u00ean h\u1ec7 qu\u1ea3n tr\u1ecb vi\u00ean."
        extra={[
          <Button
            key="retry"
            type="primary"
            icon={<ReloadOutlined />}
            onClick={() => reset()}
          >
            Th\u1eed l\u1ea1i
          </Button>,
        ]}
      />
    </div>
  );
}
