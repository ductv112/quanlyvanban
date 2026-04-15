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
        title="Đã xảy ra lỗi"
        subTitle="Rất tiếc, đã có lỗi xảy ra. Vui lòng thử lại hoặc liên hệ quản trị viên."
        extra={[
          <Button
            key="retry"
            type="primary"
            icon={<ReloadOutlined />}
            onClick={() => reset()}
          >
            Thử lại
          </Button>,
        ]}
      />
    </div>
  );
}
