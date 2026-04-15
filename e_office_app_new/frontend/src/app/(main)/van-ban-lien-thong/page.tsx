'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Select, DatePicker, Tag, Tooltip, Space, Row, Col, Empty, App,
Card, } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  SwapOutlined, ReloadOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useRouter } from 'next/navigation';
import dayjs from 'dayjs';

const { RangePicker } = DatePicker;

interface LienThongDoc {
  id: number;
  received_date: string;
  notation: string;
  abstract: string;
  expired_date: string;
  publish_unit: string;
  signer: string;
  status: string;
  status_label: string;
  doc_type_id: number;
  doc_type_name: string;
  total_count: number;
}

const STATUS_MAP: Record<string, { text: string; color: string }> = {
  pending: { text: 'Chờ xử lý', color: 'gold' },
  received: { text: 'Đã nhận', color: 'cyan' },
  processing: { text: 'Đang xử lý', color: 'blue' },
  completed: { text: 'Hoàn thành', color: 'green' },
  returned: { text: 'Đã chuyển lại', color: 'orange' },
  cancelled: { text: 'Đã hủy', color: 'red' },
};

export default function LienThongDocPage() {
  const { message } = App.useApp();
  const router = useRouter();

  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<LienThongDoc[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [keyword, setKeyword] = useState('');
  const [filterDocTypeId, setFilterDocTypeId] = useState<number | undefined>();
  const [filterStatus, setFilterStatus] = useState<string | undefined>();
  const [filterDateRange, setFilterDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs] | null>(null);
  const [docTypes, setDocTypes] = useState<{ value: number; label: string }[]>([]);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = { page, page_size: pageSize };
      if (keyword) params.keyword = keyword;
      if (filterDocTypeId) params.doc_type_id = filterDocTypeId;
      if (filterStatus) params.status = filterStatus;
      if (filterDateRange) {
        params.from_date = filterDateRange[0].startOf('day').toISOString();
        params.to_date = filterDateRange[1].endOf('day').toISOString();
      }
      const { data: res } = await api.get('/van-ban-lien-thong', { params });
      setData(res.data || []);
      setTotal(res.pagination?.total || 0);
    } catch {
      message.error('Lỗi tải danh sách văn bản liên thông');
    } finally {
      setLoading(false);
    }
  }, [page, pageSize, keyword, filterDocTypeId, filterStatus, filterDateRange, message]);

  const fetchDocTypes = useCallback(async () => {
    try {
      const { data: res } = await api.get('/quan-tri/loai-van-ban/tree');
      setDocTypes((res.data || []).map((t: { id: number; name: string }) => ({ value: t.id, label: t.name })));
    } catch { /* ignore */ }
  }, []);

  useEffect(() => { fetchDocTypes(); }, [fetchDocTypes]);
  useEffect(() => { fetchData(); }, [fetchData]);

  const handleReset = () => {
    setKeyword('');
    setFilterDocTypeId(undefined);
    setFilterStatus(undefined);
    setFilterDateRange(null);
    setPage(1);
  };

  const columns: ColumnsType<LienThongDoc> = [
    {
      title: 'STT',
      width: 60,
      align: 'center',
      render: (_: unknown, __: LienThongDoc, index: number) => (page - 1) * pageSize + index + 1,
    },
    {
      title: 'Ngày nhận',
      dataIndex: 'received_date',
      width: 110,
      render: (d: string) => d ? dayjs(d).format('DD/MM/YYYY') : '—',
    },
    {
      title: 'Ký hiệu',
      dataIndex: 'notation',
      width: 160,
      render: (val: string) => (
        <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{val || '—'}</span>
      ),
    },
    {
      title: 'Trích yếu',
      dataIndex: 'abstract',
      ellipsis: true,
      render: (val: string) => (
        <Tooltip title={val}>
          <span>{val}</span>
        </Tooltip>
      ),
    },
    {
      title: 'Hạn trả lời',
      dataIndex: 'expired_date',
      width: 110,
      render: (d: string) => {
        if (!d) return '—';
        const isOverdue = dayjs().isAfter(dayjs(d));
        return (
          <span style={{ color: isOverdue ? '#DC2626' : undefined, fontWeight: isOverdue ? 600 : 400 }}>
            {dayjs(d).format('DD/MM/YYYY')}
          </span>
        );
      },
    },
    {
      title: 'Đơn vị phát hành',
      dataIndex: 'publish_unit',
      width: 180,
      ellipsis: true,
    },
    {
      title: 'Người ký',
      dataIndex: 'signer',
      width: 140,
      ellipsis: true,
      render: (val: string) => val || '—',
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      width: 120,
      align: 'center',
      render: (val: string, record: LienThongDoc) => {
        const statusInfo = STATUS_MAP[val];
        if (statusInfo) return <Tag color={statusInfo.color}>{statusInfo.text}</Tag>;
        if (record.status_label) return <Tag>{record.status_label}</Tag>;
        return <Tag color="default">Chờ xử lý</Tag>;
      },
    },
  ];

  return (
    <Card
      title={<><SwapOutlined style={{ marginRight: 8 }} />Văn bản liên thông</>}
    >
      <Row gutter={[12, 12]} className="filter-row">
        <Col span={6}>
          <Input.Search
            placeholder="Tìm kiếm trích yếu, ký hiệu..."
            allowClear
            onSearch={(val) => { setKeyword(val); setPage(1); }}
          />
        </Col>
        <Col span={4}>
          <Select
            style={{ width: '100%' }}
            placeholder="Loại văn bản"
            allowClear
            options={docTypes}
            value={filterDocTypeId}
            onChange={(val) => { setFilterDocTypeId(val); setPage(1); }}
          />
        </Col>
        <Col span={4}>
          <Select
            style={{ width: '100%' }}
            placeholder="Trạng thái"
            allowClear
            options={Object.entries(STATUS_MAP).map(([val, info]) => ({ value: val, label: info.text }))}
            value={filterStatus}
            onChange={(val) => { setFilterStatus(val); setPage(1); }}
          />
        </Col>
        <Col span={7}>
          <RangePicker
            style={{ width: '100%' }}
            format="DD/MM/YYYY"
            placeholder={['Từ ngày', 'Đến ngày']}
            value={filterDateRange}
            onChange={(val) => { setFilterDateRange(val as [dayjs.Dayjs, dayjs.Dayjs] | null); setPage(1); }}
          />
        </Col>
        <Col span={2}>
          <Tooltip title="Xóa bộ lọc">
            <Button icon={<ReloadOutlined />} onClick={handleReset} />
          </Tooltip>
        </Col>
      </Row>

      <Table<LienThongDoc>
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={data}
        size="small"
        scroll={{ x: 1000 }}
        locale={{
          emptyText: (
            <Empty
              description={
                <Space orientation="vertical" size={4}>
                  <span style={{ fontWeight: 600 }}>Không có văn bản liên thông</span>
                  <span style={{ color: '#8c8c8c', fontSize: 13 }}>Hiện chưa có văn bản liên thông nào. Hãy kiểm tra lại bộ lọc.</span>
                </Space>
              }
            />
          ),
        }}
        pagination={{
          current: page,
          pageSize,
          total,
          showSizeChanger: true,
          showTotal: (t) => `Tổng ${t} văn bản`,
          pageSizeOptions: ['10', '20', '50', '100'],
        }}
        onRow={(record) => ({
          onClick: () => router.push(`/van-ban-lien-thong/${record.id}`),
          style: { cursor: 'pointer' },
        })}
        onChange={(p) => { setPage(p.current || 1); setPageSize(p.pageSize || 20); }}
      />
    </Card>
  );
}
