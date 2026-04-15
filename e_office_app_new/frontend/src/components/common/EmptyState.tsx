'use client';

import React from 'react';
import { Empty } from 'antd';
import { InboxOutlined } from '@ant-design/icons';

interface EmptyStateProps {
  description?: string;
  icon?: React.ReactNode;
}

export default function EmptyState({
  description = 'Kh\u00f4ng c\u00f3 d\u1eef li\u1ec7u',
  icon,
}: EmptyStateProps) {
  return (
    <div className="empty-center">
      <Empty
        image={icon || <InboxOutlined style={{ fontSize: 48, color: '#94A3B8' }} />}
        description={<span style={{ color: '#94A3B8', fontSize: 14 }}>{description}</span>}
      />
    </div>
  );
}
