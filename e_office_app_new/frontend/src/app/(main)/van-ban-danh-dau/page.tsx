'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Table, Button, Tag, Empty, App, Tooltip, Tabs } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { StarFilled, StarOutlined, EyeOutlined, DeleteOutlined, PrinterOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';
import dayjs from 'dayjs';

interface Bookmark {
  note_id: number;
  doc_id: number;
  doc_type: string;
  note: string;
  is_important: boolean;
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
  const [filterType, setFilterType] = useState<string>('all');

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

      all.sort((a, b) => {
        if (a.is_important !== b.is_important) return a.is_important ? -1 : 1;
        return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
      });
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

  const filteredData = filterType === 'all' ? data : data.filter((d) => d.doc_type === filterType);

  const handleToggleImportant = async (record: Bookmark) => {
    const basePath = DOC_TYPE_PATH[record.doc_type] || '/van-ban-den';
    try {
      await api.post(`${basePath}/${record.doc_id}/danh-dau`, { is_important: !record.is_important });
      fetchData();
    } catch { message.error('Lỗi'); }
  };

  const columns: ColumnsType<Bookmark> = [
    {
      title: '', width: 40, align: 'center',
      render: (_, r) => (
        <Tooltip title={r.is_important ? 'Bỏ quan trọng' : 'Đánh dấu quan trọng'}>
          <Button type="text" size="small" onClick={() => handleToggleImportant(r)}
            icon={r.is_important ? <StarFilled style={{ color: '#faad14' }} /> : <StarOutlined style={{ color: '#d9d9d9' }} />} />
        </Tooltip>
      ),
    },
    {
      title: 'Loại', dataIndex: 'doc_type', width: 100, align: 'center',
      render: (val: string) => <Tag color={DOC_TYPE_COLOR[val]}>{DOC_TYPE_LABEL[val] || val}</Tag>,
    },
    { title: 'Số VB', dataIndex: 'doc_number', width: 80, align: 'center' },
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
    <Card title={<><StarFilled style={{ color: '#faad14', marginRight: 8 }} />Văn bản đánh dấu cá nhân</>} extra={<Button icon={<PrinterOutlined />} onClick={() => window.print()}>In</Button>}>
      <Tabs
        type="line"
        activeKey={filterType}
        onChange={(key) => setFilterType(key)}
        style={{ marginBottom: 0 }}
        items={[
          { key: 'all', label: `Tất cả (${data.length})` },
          { key: 'incoming', label: `VB đến (${data.filter(d => d.doc_type === 'incoming').length})` },
          { key: 'outgoing', label: `VB đi (${data.filter(d => d.doc_type === 'outgoing').length})` },
          { key: 'drafting', label: `Dự thảo (${data.filter(d => d.doc_type === 'drafting').length})` },
        ]}
      />
      <Table<Bookmark>
        rowKey={(r) => `${r.doc_type}-${r.note_id}`}
        loading={loading}
        columns={columns}
        dataSource={filteredData}
        size="small"
        pagination={{ pageSize: 20, showTotal: (t) => `Tổng ${t} văn bản` }}
        locale={{ emptyText: <Empty description="Chưa đánh dấu văn bản nào" /> }}
      />

      <div className="print-area">
        <div className="print-header">
          <h2>VĂN BẢN ĐÁNH DẤU CÁ NHÂN</h2>
          <p>Ngày in: {dayjs().format('DD/MM/YYYY HH:mm')}</p>
        </div>
        <table>
          <thead>
            <tr><th>STT</th><th>Loại</th><th>Số VB</th><th>Ngày</th><th>Số ký hiệu</th><th>Trích yếu</th><th>CQ ban hành</th><th>Ghi chú</th></tr>
          </thead>
          <tbody>
            {filteredData.map((r, i) => (
              <tr key={`${r.doc_type}-${r.note_id}`}>
                <td style={{ textAlign: 'center' }}>{i + 1}</td>
                <td>{DOC_TYPE_LABEL[r.doc_type] || r.doc_type}</td>
                <td style={{ textAlign: 'center' }}>{r.doc_number}</td>
                <td>{r.doc_received_date ? dayjs(r.doc_received_date).format('DD/MM/YYYY') : ''}</td>
                <td>{r.doc_notation}</td>
                <td>{r.doc_abstract}</td>
                <td>{r.doc_publish_unit}</td>
                <td>{r.note}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="print-footer">Tổng: {filteredData.length} văn bản</div>
      </div>
    </Card>
  );
}
