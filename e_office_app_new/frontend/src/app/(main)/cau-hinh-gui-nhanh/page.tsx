'use client';

import React, { useState, useEffect, useCallback, useRef } from 'react';
import { Card, Button, App, Table, Checkbox, Tag, Empty, Row, Col, Input } from 'antd';
import type { ColumnsType, TablePaginationConfig } from 'antd/es/table';
import { SettingOutlined, SaveOutlined, SearchOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';

interface StaffRow {
  id: number;
  full_name: string;
  position_name: string;
  department_name: string;
}

const PAGE_SIZE = 20;

export default function SendConfigPage() {
  const { message } = App.useApp();

  // Bảng trái: tải theo trang + tìm kiếm phía máy chủ
  const [staff, setStaff] = useState<StaffRow[]>([]);
  const [staffLoading, setStaffLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [total, setTotal] = useState(0);
  const [keyword, setKeyword] = useState('');
  const [keywordInput, setKeywordInput] = useState('');

  // Cột phải: danh sách đã chọn (giữ độc lập với bảng trái — không bị mất khi đổi từ khóa / sang trang khác)
  const [selectedStaff, setSelectedStaff] = useState<StaffRow[]>([]);
  const [initialLoading, setInitialLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const fetchStaff = useCallback(async (p: number, kw: string) => {
    setStaffLoading(true);
    try {
      const params: Record<string, string | number> = { page: p, pageSize: PAGE_SIZE };
      if (kw.trim()) params.keyword = kw.trim();
      const { data: res } = await api.get('/quan-tri/nguoi-dung', { params });
      setStaff(res.data ?? []);
      setTotal(res.pagination?.total ?? res.data?.length ?? 0);
    } catch {
      message.error('Lỗi tải danh sách cán bộ');
    } finally {
      setStaffLoading(false);
    }
  }, [message]);

  // Tải lần đầu: cấu hình đã lưu (cột phải) + trang 1 cán bộ (cột trái)
  useEffect(() => {
    (async () => {
      try {
        const [cfgRes] = await Promise.all([
          api.get('/cau-hinh-gui-nhanh', { params: { config_type: 'doc' } }),
          fetchStaff(1, ''),
        ]);
        const cfgRows: Array<{ target_user_id: number; target_name: string; position_name: string; department_name: string }>
          = cfgRes.data.data ?? [];
        setSelectedStaff(cfgRows.map((c) => ({
          id: c.target_user_id,
          full_name: c.target_name,
          position_name: c.position_name,
          department_name: c.department_name,
        })));
      } catch {
        message.error('Lỗi tải cấu hình hiện tại');
      } finally {
        setInitialLoading(false);
      }
    })();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Tìm kiếm có chống dội (debounce 350 ms)
  const onKeywordChange = (val: string) => {
    setKeywordInput(val);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      setKeyword(val);
      setPage(1);
      fetchStaff(1, val);
    }, 350);
  };

  const onTableChange = (pag: TablePaginationConfig) => {
    const next = pag.current ?? 1;
    setPage(next);
    fetchStaff(next, keyword);
  };

  const isSelected = (id: number) => selectedStaff.some((s) => s.id === id);

  const toggleStaff = (row: StaffRow, checked: boolean) => {
    setSelectedStaff((prev) => {
      if (checked) {
        if (prev.some((s) => s.id === row.id)) return prev;
        return [...prev, row];
      }
      return prev.filter((s) => s.id !== row.id);
    });
  };

  const handleSave = async () => {
    setSaving(true);
    try {
      const { data: res } = await api.post('/cau-hinh-gui-nhanh', {
        config_type: 'doc',
        target_user_ids: selectedStaff.map((s) => s.id),
      });
      message.success(res.data?.message || 'Đã lưu cấu hình gửi nhanh');
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      message.error(err?.response?.data?.message || 'Lỗi lưu');
    } finally {
      setSaving(false);
    }
  };

  const columns: ColumnsType<StaffRow> = [
    {
      title: '', width: 40, align: 'center',
      render: (_, r) => (
        <Checkbox
          checked={isSelected(r.id)}
          onChange={(e) => toggleStaff(r, e.target.checked)}
        />
      ),
    },
    { title: 'Họ tên', dataIndex: 'full_name', width: 180 },
    { title: 'Chức vụ', dataIndex: 'position_name', width: 150, render: (v) => v || '—' },
    { title: 'Phòng ban', dataIndex: 'department_name', width: 180, render: (v) => v || '—' },
  ];

  return (
    <Card
      title={<><SettingOutlined style={{ marginRight: 8 }} />Cấu hình gửi nhanh</>}
      extra={
        <Button type="primary" icon={<SaveOutlined />} loading={saving} onClick={handleSave}>
          Lưu cấu hình ({selectedStaff.length} người)
        </Button>
      }
      loading={initialLoading}
    >
      <div style={{ marginBottom: 16, padding: 12, background: '#f0f5ff', borderRadius: 8, border: '1px solid #d6e4ff', color: '#1B3A5C' }}>
        Chọn cán bộ thường gửi văn bản. Khi gửi VB hoặc bút phê phân công, danh sách này sẽ được <strong>tick sẵn</strong> — tiết kiệm thời gian chọn lại mỗi lần.
      </div>

      <Row gutter={16}>
        {/* Cột trái: bảng cán bộ với tìm kiếm phía máy chủ */}
        <Col span={14}>
          <div style={{ marginBottom: 12 }}>
            <Input
              prefix={<SearchOutlined />}
              placeholder="Tìm kiếm cán bộ theo tên, chức vụ, phòng ban..."
              allowClear
              value={keywordInput}
              onChange={(e) => onKeywordChange(e.target.value)}
            />
          </div>
          <Table<StaffRow>
            rowKey="id"
            loading={staffLoading}
            columns={columns}
            dataSource={staff}
            size="small"
            pagination={{
              current: page,
              pageSize: PAGE_SIZE,
              total,
              showTotal: (t) => `${t} cán bộ`,
              size: 'small',
              showSizeChanger: false,
            }}
            onChange={onTableChange}
            locale={{ emptyText: <Empty description="Không tìm thấy cán bộ" image={Empty.PRESENTED_IMAGE_SIMPLE} /> }}
          />
        </Col>

        {/* Cột phải: danh sách đã chọn */}
        <Col span={10}>
          <div style={{ padding: 16, background: '#fffbe6', borderRadius: 8, border: '1px solid #ffe58f', minHeight: 400 }}>
            <div style={{ fontWeight: 600, marginBottom: 12, color: '#d48806' }}>
              Đã chọn gửi nhanh ({selectedStaff.length} người)
            </div>
            {selectedStaff.length === 0 ? (
              <Empty description="Chưa chọn cán bộ nào" image={Empty.PRESENTED_IMAGE_SIMPLE} />
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6, maxHeight: 600, overflowY: 'auto' }}>
                {selectedStaff.map((s) => (
                  <div key={s.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 10px', background: '#fff', borderRadius: 6, border: '1px solid #f0f0f0' }}>
                    <div>
                      <span style={{ fontWeight: 500 }}>{s.full_name}</span>
                      {s.position_name && <Tag style={{ marginLeft: 6, fontSize: 10 }}>{s.position_name}</Tag>}
                      <div style={{ fontSize: 11, color: '#8c8c8c' }}>{s.department_name}</div>
                    </div>
                    <Button size="small" type="text" danger onClick={() => toggleStaff(s, false)}>Bỏ</Button>
                  </div>
                ))}
              </div>
            )}
          </div>
        </Col>
      </Row>
    </Card>
  );
}
