'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, InputNumber, Switch, Tabs, Space, App,
} from 'antd';
import {
  SettingOutlined, SaveOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';

interface DocColumn {
  id: number;
  type_id: number;
  column_name: string;
  label: string;
  is_mandatory: boolean;
  is_show_all: boolean;
  sort_order: number;
  description: string;
}

interface EditedRow {
  label?: string;
  is_mandatory?: boolean;
  is_show_all?: boolean;
  sort_order?: number;
}

const TAB_ITEMS = [
  { key: '1', label: 'Văn bản đến' },
  { key: '2', label: 'Văn bản đi' },
  { key: '3', label: 'Văn bản dự thảo' },
];

export default function DocColumnPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<DocColumn[]>([]);
  const [activeTab, setActiveTab] = useState('1');
  const [editedRows, setEditedRows] = useState<Record<number, EditedRow>>({});
  const [savingIds, setSavingIds] = useState<Set<number>>(new Set());
  const [savingAll, setSavingAll] = useState(false);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/thuoc-tinh-van-ban', {
        params: { type_id: activeTab },
      });
      setData(res.data || []);
      setEditedRows({});
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải dữ liệu');
    } finally {
      setLoading(false);
    }
  }, [activeTab, message]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const updateField = (id: number, field: keyof EditedRow, value: any) => {
    setEditedRows((prev) => ({
      ...prev,
      [id]: { ...prev[id], [field]: value },
    }));
  };

  const getRowValue = <K extends keyof DocColumn>(record: DocColumn, field: K): DocColumn[K] => {
    const edited = editedRows[record.id];
    if (edited && field in edited) {
      return (edited as any)[field];
    }
    return record[field];
  };

  const handleSaveRow = async (record: DocColumn) => {
    const edited = editedRows[record.id];
    if (!edited) return;

    setSavingIds((prev) => new Set(prev).add(record.id));
    try {
      await api.put(`/quan-tri/thuoc-tinh-van-ban/${record.id}`, {
        label: edited.label ?? record.label,
        is_mandatory: edited.is_mandatory ?? record.is_mandatory,
        is_show_all: edited.is_show_all ?? record.is_show_all,
        sort_order: edited.sort_order ?? record.sort_order,
      });
      message.success('Cập nhật thành công');
      // Clear edited state for this row
      setEditedRows((prev) => {
        const next = { ...prev };
        delete next[record.id];
        return next;
      });
      // Update local data
      setData((prev) =>
        prev.map((item) =>
          item.id === record.id
            ? {
                ...item,
                label: edited.label ?? item.label,
                is_mandatory: edited.is_mandatory ?? item.is_mandatory,
                is_show_all: edited.is_show_all ?? item.is_show_all,
                sort_order: edited.sort_order ?? item.sort_order,
              }
            : item,
        ),
      );
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi cập nhật');
    } finally {
      setSavingIds((prev) => {
        const next = new Set(prev);
        next.delete(record.id);
        return next;
      });
    }
  };

  const handleSaveAll = async () => {
    const ids = Object.keys(editedRows).map(Number);
    if (ids.length === 0) {
      message.info('Không có thay đổi nào');
      return;
    }

    setSavingAll(true);
    try {
      const promises = ids.map((id) => {
        const record = data.find((d) => d.id === id);
        if (!record) return Promise.resolve();
        const edited = editedRows[id];
        return api.put(`/quan-tri/thuoc-tinh-van-ban/${id}`, {
          label: edited.label ?? record.label,
          is_mandatory: edited.is_mandatory ?? record.is_mandatory,
          is_show_all: edited.is_show_all ?? record.is_show_all,
          sort_order: edited.sort_order ?? record.sort_order,
        });
      });
      await Promise.all(promises);
      message.success('Lưu tất cả thành công');
      fetchData();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi lưu');
    } finally {
      setSavingAll(false);
    }
  };

  const hasChanges = Object.keys(editedRows).length > 0;

  const columns = [
    {
      title: 'Tên trường',
      dataIndex: 'column_name',
      key: 'column_name',
      width: 200,
      render: (v: string) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Nhãn hiển thị',
      dataIndex: 'label',
      key: 'label',
      render: (_: string, record: DocColumn) => (
        <Input
          value={getRowValue(record, 'label') as string}
          onChange={(e) => updateField(record.id, 'label', e.target.value)}
          maxLength={200}
          style={{ borderRadius: 8 }}
        />
      ),
    },
    {
      title: 'Bắt buộc',
      dataIndex: 'is_mandatory',
      key: 'is_mandatory',
      width: 100,
      align: 'center' as const,
      render: (_: boolean, record: DocColumn) => (
        <Switch
          checked={getRowValue(record, 'is_mandatory') as boolean}
          onChange={(checked) => updateField(record.id, 'is_mandatory', checked)}
          checkedChildren="Có"
          unCheckedChildren="Không"
          size="small"
        />
      ),
    },
    {
      title: 'Hiển thị',
      dataIndex: 'is_show_all',
      key: 'is_show_all',
      width: 100,
      align: 'center' as const,
      render: (_: boolean, record: DocColumn) => (
        <Switch
          checked={getRowValue(record, 'is_show_all') as boolean}
          onChange={(checked) => updateField(record.id, 'is_show_all', checked)}
          checkedChildren="Có"
          unCheckedChildren="Không"
          size="small"
        />
      ),
    },
    {
      title: 'Thứ tự',
      dataIndex: 'sort_order',
      key: 'sort_order',
      width: 100,
      align: 'center' as const,
      render: (_: number, record: DocColumn) => (
        <InputNumber
          value={getRowValue(record, 'sort_order') as number}
          onChange={(value) => updateField(record.id, 'sort_order', value ?? 0)}
          min={0}
          style={{ width: 80, borderRadius: 8 }}
          size="small"
        />
      ),
    },
    {
      title: '',
      key: 'actions',
      width: 80,
      align: 'center' as const,
      render: (_: any, record: DocColumn) => {
        const isEdited = !!editedRows[record.id];
        return isEdited ? (
          <Button
            type="link"
            size="small"
            icon={<SaveOutlined />}
            loading={savingIds.has(record.id)}
            onClick={() => handleSaveRow(record)}
          >
            Lưu
          </Button>
        ) : null;
      },
    },
  ];

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Thuộc tính văn bản
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Cấu hình các trường hiển thị trên form văn bản
        </p>
      </div>

      <Card
        variant="borderless"
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <SettingOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Cấu hình thuộc tính</span>
          </div>
        }
        extra={
          <Button
            type="primary"
            icon={<SaveOutlined />}
            onClick={handleSaveAll}
            loading={savingAll}
            disabled={!hasChanges}
            style={{ borderRadius: 8 }}
          >
            Lưu tất cả
          </Button>
        }
      >
        <Tabs
          activeKey={activeTab}
          onChange={(key) => setActiveTab(key)}
          items={TAB_ITEMS}
          style={{ marginBottom: 16 }}
        />
        <Table
          className="enhanced-table"
          columns={columns}
          dataSource={data}
          rowKey="id"
          loading={loading}
          size="middle"
          sticky
          scroll={{ x: 600 }}
          pagination={false}
          rowClassName={(record) => (editedRows[record.id] ? 'ant-table-row-selected' : '')}
        />
      </Card>
    </div>
  );
}
