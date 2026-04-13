'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Table, Button, Tag, Empty, App, Tooltip } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { StarFilled, EyeOutlined, DeleteOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

interface Bookmark {
  note_id: number;
  doc_id: number;
  note: string;
  created_at: string;
  doc_number: number;
  doc_notation: string;
  doc_abstract: string;
  doc_received_date: string;
  doc_publish_unit: string;
}

export default function BookmarksPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<Bookmark[]>([]);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/van-ban-den/danh-dau-ca-nhan');
      setData(res.data || []);
    } catch {
      message.error('Lỗi tải dữ liệu');
    } finally {
      setLoading(false);
    }
  }, [message]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleRemove = async (docId: number) => {
    try {
      await api.post(`/van-ban-den/${docId}/danh-dau`, {});
      message.success('Đã bỏ đánh dấu');
      fetchData();
    } catch { message.error('Lỗi'); }
  };

  const columns: ColumnsType<Bookmark> = [
    { title: 'Số đến', dataIndex: 'doc_number', width: 80, align: 'center' },
    {
      title: 'Ngày đến', dataIndex: 'doc_received_date', width: 100,
      render: (d) => d ? dayjs(d).format('DD/MM/YYYY') : '',
    },
    { title: 'Số ký hiệu', dataIndex: 'doc_notation', width: 130 },
    {
      title: 'Trích yếu', dataIndex: 'doc_abstract', ellipsis: true,
      render: (val, r) => <a href={`/van-ban-den/${r.doc_id}`}>{val}</a>,
    },
    { title: 'CQ ban hành', dataIndex: 'doc_publish_unit', width: 180, ellipsis: true },
    { title: 'Ghi chú', dataIndex: 'note', width: 150, ellipsis: true },
    {
      title: 'Ngày đánh dấu', dataIndex: 'created_at', width: 120,
      render: (d) => dayjs(d).format('DD/MM/YYYY'),
    },
    {
      title: '', width: 80, align: 'center',
      render: (_, r) => (
        <>
          <Tooltip title="Xem"><Button size="small" type="link" icon={<EyeOutlined />} href={`/van-ban-den/${r.doc_id}`} /></Tooltip>
          <Tooltip title="Bỏ đánh dấu"><Button size="small" type="link" danger icon={<DeleteOutlined />} onClick={() => handleRemove(r.doc_id)} /></Tooltip>
        </>
      ),
    },
  ];

  return (
    <Card title={<><StarFilled style={{ color: '#faad14', marginRight: 8 }} />Văn bản đánh dấu cá nhân</>}>
      <Table<Bookmark>
        rowKey="note_id"
        loading={loading}
        columns={columns}
        dataSource={data}
        size="small"
        pagination={{ pageSize: 20, showTotal: (t) => `Tổng ${t} văn bản` }}
        locale={{ emptyText: <Empty description="Chưa đánh dấu văn bản nào" /> }}
      />
    </Card>
  );
}
