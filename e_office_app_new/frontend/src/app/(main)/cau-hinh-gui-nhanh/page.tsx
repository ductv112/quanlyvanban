'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Button, App, Table, Checkbox, Space, Input, Tag, Empty, Row, Col } from 'antd';
import type { ColumnsType } from 'antd/es/table';
import { SettingOutlined, SaveOutlined, SearchOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';

interface StaffRow {
  id: number;
  full_name: string;
  position_name: string;
  department_name: string;
  department_id: number;
}

export default function SendConfigPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [allStaff, setAllStaff] = useState<StaffRow[]>([]);
  const [selectedIds, setSelectedIds] = useState<number[]>([]);
  const [keyword, setKeyword] = useState('');

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const [staffRes, configRes] = await Promise.all([
        api.get('/quan-tri/nguoi-dung', { params: { page: 1, pageSize: 200 } }),
        api.get('/cau-hinh-gui-nhanh', { params: { config_type: 'doc' } }),
      ]);

      setAllStaff(staffRes.data.data || []);
      const ids = (configRes.data.data || []).map((c: { target_user_id: number }) => c.target_user_id);
      setSelectedIds(ids);
    } catch {
      message.error('Lỗi tải dữ liệu');
    } finally {
      setLoading(false);
    }
  }, [message]);

  useEffect(() => { fetchData(); }, [fetchData]);

  const handleSave = async () => {
    setSaving(true);
    try {
      const { data: res } = await api.post('/cau-hinh-gui-nhanh', {
        config_type: 'doc',
        target_user_ids: selectedIds,
      });
      message.success(res.data?.message || 'Đã lưu cấu hình gửi nhanh');
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      message.error(err?.response?.data?.message || 'Lỗi lưu');
    } finally {
      setSaving(false);
    }
  };

  const toggleStaff = (staffId: number, checked: boolean) => {
    setSelectedIds(prev => checked ? [...prev, staffId] : prev.filter(id => id !== staffId));
  };

  const filteredStaff = keyword
    ? allStaff.filter(s =>
        s.full_name.toLowerCase().includes(keyword.toLowerCase()) ||
        (s.position_name || '').toLowerCase().includes(keyword.toLowerCase()) ||
        (s.department_name || '').toLowerCase().includes(keyword.toLowerCase())
      )
    : allStaff;

  const selectedStaff = allStaff.filter(s => selectedIds.includes(s.id));

  const columns: ColumnsType<StaffRow> = [
    {
      title: '', width: 40, align: 'center',
      render: (_, r) => (
        <Checkbox
          checked={selectedIds.includes(r.id)}
          onChange={(e) => toggleStaff(r.id, e.target.checked)}
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
          Lưu cấu hình ({selectedIds.length} người)
        </Button>
      }
    >
      <div style={{ marginBottom: 16, padding: 12, background: '#f0f5ff', borderRadius: 8, border: '1px solid #d6e4ff', color: '#1B3A5C' }}>
        Chọn cán bộ thường gửi văn bản. Khi gửi VB hoặc bút phê phân công, danh sách này sẽ được <strong>tick sẵn</strong> — tiết kiệm thời gian chọn lại mỗi lần.
      </div>

      <Row gutter={16}>
        {/* Cột trái: Danh sách toàn bộ cán bộ */}
        <Col span={14}>
          <div style={{ marginBottom: 12 }}>
            <Input
              prefix={<SearchOutlined />}
              placeholder="Tìm kiếm cán bộ..."
              allowClear
              value={keyword}
              onChange={(e) => setKeyword(e.target.value)}
            />
          </div>
          <Table<StaffRow>
            rowKey="id"
            loading={loading}
            columns={columns}
            dataSource={filteredStaff}
            size="small"
            pagination={{ pageSize: 10, showTotal: (t) => `${t} cán bộ`, size: 'small' }}
            locale={{ emptyText: <Empty description="Không tìm thấy cán bộ" image={Empty.PRESENTED_IMAGE_SIMPLE} /> }}
          />
        </Col>

        {/* Cột phải: Đã chọn */}
        <Col span={10}>
          <div style={{ padding: 16, background: '#fffbe6', borderRadius: 8, border: '1px solid #ffe58f', minHeight: 400 }}>
            <div style={{ fontWeight: 600, marginBottom: 12, color: '#d48806' }}>
              Đã chọn gửi nhanh ({selectedStaff.length} người)
            </div>
            {selectedStaff.length === 0 ? (
              <Empty description="Chưa chọn cán bộ nào" image={Empty.PRESENTED_IMAGE_SIMPLE} />
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
                {selectedStaff.map((s) => (
                  <div key={s.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '6px 10px', background: '#fff', borderRadius: 6, border: '1px solid #f0f0f0' }}>
                    <div>
                      <span style={{ fontWeight: 500 }}>{s.full_name}</span>
                      {s.position_name && <Tag style={{ marginLeft: 6, fontSize: 10 }}>{s.position_name}</Tag>}
                      <div style={{ fontSize: 11, color: '#8c8c8c' }}>{s.department_name}</div>
                    </div>
                    <Button size="small" type="text" danger onClick={() => toggleStaff(s.id, false)}>Bỏ</Button>
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
