'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Table, Button, Tag, Empty, App, Tooltip } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { StarFilled, EyeOutlined, DeleteOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

interface Bookmark {
  note_id: number | string;
  doc_id: number | string;
  doc_type: string;
  note: string;
  created_at: string;
  doc_number: number;
  doc_notation: string;
  doc_abstract: string;
  doc_received_date: string;
  doc_publish_unit: string;
}

const DOC_TYPE_LABEL: Record<string, string> = {
  incoming: 'VB đến',
  outgoing: 'VB đi',
  drafting: 'VB dự thảo',
};

const DOC_TYPE_COLOR: Record<string, string> = {
  incoming: 'blue',
  outgoing: 'green',
  drafting: 'orange',
};

const DOC_TYPE_PATH: Record<string, string> = {
  incoming: '/van-ban-den',
  outgoing: '/van-ban-di',
  drafting: '/van-ban-du-thao',
};

export default function BookmarksPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<Bookmark[]>([]);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const [inRes, outRes, draftRes] = await Promise.allSettled([
        api.get('/van-ban-den/danh-dau-ca-nhan'),
        api.get('/van-ban-di/danh-dau-ca-nhan'),
        api.get('/van-ban-du-thao/danh-dau-ca-nhan'),
      ]);

      const all: Bookmark[] = [];
      if (inRes.status === 'fulfilled') {
        (inRes.value.data.data || []).forEach((b: Bookmark) => all.push({ ...b, doc_type: 'incoming' }));
      }
      if (outRes.status === 'fulfilled') {
        (outRes.value.data.data || []).forEach((b: Bookmark) => all.push({ ...b, doc_type: 'outgoing' }));
      }
      if (draftRes.status === 'fulfilled') {
        (draftRes.value.data.data || []).forEach((b: Bookmark) => all.push({ ...b, doc_type: 'drafting' }));
      }

      all.sort((a, b) => new Date(b.created_at).getTime() - new Date(a.created_at).getTime());
      setData(all);
    } catch {
      message.error('Lỗi tải dữ liệu');
    } finally {
      setLoading(false);
    }
  }, [message]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleRemove = async (record: Bookmark) => {
    const basePath = DOC_TYPE_PATH[record.doc_type] || '/van-ban-den';
    try {
      await api.post(`${basePath}/${record.doc_id}/danh-dau`, {});
      message.success('Đã bỏ đánh dấu');
      fetchData();
    } catch { message.error('Lỗi'); }
  };

  const columns: ColumnsType<Bookmark> = [
    {
      title: 'Loại', dataIndex: 'doc_type', width: 100, align: 'center',
      render: (val: string) => <Tag color={DOC_TYPE_COLOR[val]}>{DOC_TYPE_LABEL[val] || val}</Tag>,
    },
    { title: 'Số đến', dataIndex: 'doc_number', width: 80, align: 'center' },
    {
      title: 'Ngày nhận', dataIndex: 'doc_received_date', width: 100,
      render: (d) => d ? dayjs(d).format('DD/MM/YYYY') : '',
    },
    { title: 'Số ký hiệu', dataIndex: 'doc_notation', width: 130 },
    {
      title: 'Trích yếu', dataIndex: 'doc_abstract', ellipsis: true,
      render: (val, r) => <a href={`${DOC_TYPE_PATH[r.doc_type]}/${r.doc_id}`}>{val}</a>,
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
          <Tooltip title="Xem"><Button size="small" type="link" icon={<EyeOutlined />} href={`${DOC_TYPE_PATH[r.doc_type]}/${r.doc_id}`} /></Tooltip>
          <Tooltip title="Bỏ đánh dấu"><Button size="small" type="link" danger icon={<DeleteOutlined />} onClick={() => handleRemove(r)} /></Tooltip>
        </>
      ),
    },
  ];

  return (
    <Card title={<><StarFilled style={{ color: '#faad14', marginRight: 8 }} />Văn bản đánh dấu cá nhân</>}>
      <Table<Bookmark>
        rowKey={(r) => `${r.doc_type}-${r.note_id}`}
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
