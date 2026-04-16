'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { Card, Transfer, Button, App, Space, Tag } from 'antd';
import { SettingOutlined, SaveOutlined } from '@ant-design/icons';
import { api } from '@/lib/api';

interface StaffItem {
  key: string;
  title: string;
  description: string;
  department_name: string;
}

export default function SendConfigPage() {
  const { message } = App.useApp();
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [allStaff, setAllStaff] = useState<StaffItem[]>([]);
  const [targetKeys, setTargetKeys] = useState<string[]>([]);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const [staffRes, configRes] = await Promise.all([
        api.get('/quan-tri/nguoi-dung', { params: { page: 1, pageSize: 200 } }),
        api.get('/cau-hinh-gui-nhanh', { params: { config_type: 'doc' } }),
      ]);

      const staffList = (staffRes.data.data || []).map((s: { id: number; full_name: string; position_name?: string; department_name?: string }) => ({
        key: String(s.id),
        title: s.full_name,
        description: s.position_name || '',
        department_name: s.department_name || '',
      }));
      setAllStaff(staffList);

      const selectedIds = (configRes.data.data || []).map((c: { target_user_id: number }) => String(c.target_user_id));
      setTargetKeys(selectedIds);
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
        target_user_ids: targetKeys.map(Number),
      });
      message.success(res.data?.message || 'Đã lưu cấu hình');
    } catch (e: unknown) {
      const err = e as { response?: { data?: { message?: string } } };
      message.error(err?.response?.data?.message || 'Lỗi lưu');
    } finally {
      setSaving(false);
    }
  };

  return (
    <Card
      title={<><SettingOutlined style={{ marginRight: 8 }} />Cấu hình gửi nhanh</>}
      extra={
        <Button type="primary" icon={<SaveOutlined />} loading={saving} onClick={handleSave}>
          Lưu cấu hình
        </Button>
      }
    >
      <div style={{ marginBottom: 16, color: '#595959' }}>
        Chọn danh sách cán bộ thường gửi văn bản. Khi gửi VB hoặc bút phê phân công, danh sách này sẽ được tick sẵn.
      </div>

      <Transfer
        dataSource={allStaff}
        targetKeys={targetKeys}
        onChange={setTargetKeys}
        showSearch
        filterOption={(input, item) =>
          (item.title || '').toLowerCase().includes(input.toLowerCase()) ||
          (item.description || '').toLowerCase().includes(input.toLowerCase()) ||
          (item.department_name || '').toLowerCase().includes(input.toLowerCase())
        }
        titles={['Tất cả cán bộ', 'Đã chọn gửi nhanh']}
        listStyle={{ width: '100%', height: 400 }}
        render={(item) => (
          <span>
            {item.title}
            {item.description && <Tag style={{ marginLeft: 6, fontSize: 10 }}>{item.description}</Tag>}
          </span>
        )}
        locale={{
          itemUnit: 'người',
          itemsUnit: 'người',
          searchPlaceholder: 'Tìm kiếm...',
        }}
        style={{ width: '100%' }}
      />

      <div style={{ marginTop: 12, color: '#8c8c8c', fontSize: 12 }}>
        Đã chọn {targetKeys.length} cán bộ
      </div>
    </Card>
  );
}
