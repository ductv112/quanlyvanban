'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Select, DatePicker, Drawer, Form,
  InputNumber, Tag, Modal, App, Row, Col, Tooltip, Dropdown,
} from 'antd';
import type { ColumnsType, TablePaginationConfig } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, MoreOutlined,
  CheckCircleOutlined, EyeOutlined, FileTextOutlined, ReloadOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import dayjs from 'dayjs';

const { TextArea } = Input;
const { RangePicker } = DatePicker;

interface IncomingDoc {
  id: number; received_date: string; number: number; notation: string;
  document_code: string; abstract: string; publish_unit: string;
  publish_date: string; signer: string; sign_date: string;
  doc_book_id: number; doc_type_id: number; doc_field_id: number;
  secret_id: number; urgent_id: number; number_paper: number;
  number_copies: number; expired_date: string; recipients: string;
  approver: string; approved: boolean; is_handling: boolean;
  is_received_paper: boolean; archive_status: boolean;
  created_by: number; created_at: string;
  doc_book_name: string; doc_type_name: string; doc_type_code: string;
  doc_field_name: string; created_by_name: string;
  is_read: boolean; read_at: string; attachment_count: number; total_count: number;
}

interface SelectOption { value: number; label: string }

const URGENT_MAP: Record<number, { text: string; color: string }> = {
  1: { text: 'Thường', color: 'default' },
  2: { text: 'Khẩn', color: 'orange' },
  3: { text: 'Hỏa tốc', color: 'red' },
};

export default function IncomingDocPage() {
  const { message, modal } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<IncomingDoc[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [keyword, setKeyword] = useState('');
  const [filterDocBookId, setFilterDocBookId] = useState<number | undefined>();
  const [filterDocTypeId, setFilterDocTypeId] = useState<number | undefined>();
  const [filterUrgentId, setFilterUrgentId] = useState<number | undefined>();
  const [filterDateRange, setFilterDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs] | null>(null);
  const [docBooks, setDocBooks] = useState<SelectOption[]>([]);
  const [docTypes, setDocTypes] = useState<SelectOption[]>([]);
  const [docFields, setDocFields] = useState<SelectOption[]>([]);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<IncomingDoc | null>(null);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();
  const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([]);

  const fetchData = useCallback(async () => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = { page, page_size: pageSize };
      if (keyword) params.keyword = keyword;
      if (filterDocBookId) params.doc_book_id = filterDocBookId;
      if (filterDocTypeId) params.doc_type_id = filterDocTypeId;
      if (filterUrgentId) params.urgent_id = filterUrgentId;
      if (filterDateRange) {
        params.from_date = filterDateRange[0].startOf('day').toISOString();
        params.to_date = filterDateRange[1].endOf('day').toISOString();
      }
      const { data: res } = await api.get('/van-ban-den', { params });
      setData(res.data || []);
      setTotal(res.pagination?.total || 0);
    } catch { message.error('Lỗi tải danh sách văn bản đến'); }
    finally { setLoading(false); }
  }, [page, pageSize, keyword, filterDocBookId, filterDocTypeId, filterUrgentId, filterDateRange, message]);

  const fetchDropdowns = useCallback(async () => {
    try {
      const [bookRes, typeRes, fieldRes] = await Promise.all([
        api.get('/quan-tri/so-van-ban', { params: { type_id: 1 } }),
        api.get('/quan-tri/loai-van-ban/tree'),
        api.get('/quan-tri/linh-vuc'),
      ]);
      setDocBooks((bookRes.data.data || []).map((b: { id: number; name: string }) => ({ value: b.id, label: b.name })));
      setDocTypes((typeRes.data.data || []).map((t: { id: number; name: string }) => ({ value: t.id, label: t.name })));
      setDocFields((fieldRes.data.data || []).map((f: { id: number; name: string }) => ({ value: f.id, label: f.name })));
    } catch { /* ignore */ }
  }, []);

  useEffect(() => { fetchDropdowns(); }, [fetchDropdowns]);
  useEffect(() => { fetchData(); }, [fetchData]);

  const fetchNextNumber = async (docBookId: number) => {
    try {
      const { data: res } = await api.get('/van-ban-den/so-den-tiep-theo', { params: { doc_book_id: docBookId } });
      form.setFieldsValue({ number: res.data?.number || 1 });
    } catch { /* ignore */ }
  };

  const openDrawer = (record?: IncomingDoc) => {
    if (record) {
      setEditingRecord(record);
      form.setFieldsValue({
        ...record,
        received_date: record.received_date ? dayjs(record.received_date) : dayjs(),
        publish_date: record.publish_date ? dayjs(record.publish_date) : null,
        sign_date: record.sign_date ? dayjs(record.sign_date) : null,
        expired_date: record.expired_date ? dayjs(record.expired_date) : null,
      });
    } else {
      setEditingRecord(null);
      form.resetFields();
      form.setFieldsValue({ received_date: dayjs(), secret_id: 1, urgent_id: 1, number_paper: 1, number_copies: 1 });
    }
    setDrawerOpen(true);
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      const payload = {
        ...values,
        received_date: values.received_date?.toISOString(),
        publish_date: values.publish_date?.toISOString() || null,
        sign_date: values.sign_date?.toISOString() || null,
        expired_date: values.expired_date?.toISOString() || null,
      };
      if (editingRecord) {
        const { data: res } = await api.put(`/van-ban-den/${editingRecord.id}`, payload);
        if (!res.success) { message.error(res.message); return; }
        message.success('Cập nhật thành công');
      } else {
        const { data: res } = await api.post('/van-ban-den', payload);
        if (!res.success) { message.error(res.message); return; }
        message.success('Tạo văn bản đến thành công');
      }
      setDrawerOpen(false);
      fetchData();
    } catch (err: any) {
      if (err?.response?.data?.message) message.error(err.response.data.message);
    } finally { setSaving(false); }
  };

  const handleDelete = (record: IncomingDoc) => {
    modal.confirm({
      title: 'Xác nhận xóa', content: `Xóa văn bản "${record.abstract?.substring(0, 50)}..."?`,
      okText: 'Xóa', okType: 'danger', cancelText: 'Hủy',
      onOk: async () => {
        try { await api.delete(`/van-ban-den/${record.id}`); message.success('Đã xóa'); fetchData(); }
        catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi xóa'); }
      },
    });
  };

  const handleApprove = async (record: IncomingDoc) => {
    try { await api.patch(`/van-ban-den/${record.id}/duyet`); message.success('Duyệt thành công'); fetchData(); }
    catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi duyệt'); }
  };

  const handleMarkReadBulk = async () => {
    if (selectedRowKeys.length === 0) return;
    try {
      await api.patch('/van-ban-den/danh-dau-da-doc', { doc_ids: selectedRowKeys });
      message.success('Đã đánh dấu đọc'); setSelectedRowKeys([]); fetchData();
    } catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi'); }
  };

  const columns: ColumnsType<IncomingDoc> = [
    {
      title: 'Số đến', dataIndex: 'number', width: 80, align: 'center',
      render: (num, r) => <span style={{ fontWeight: r.is_read ? 'normal' : 'bold' }}>{num}</span>,
    },
    {
      title: 'Ngày đến', dataIndex: 'received_date', width: 100,
      render: (d, r) => <span style={{ fontWeight: r.is_read ? 'normal' : 'bold' }}>{d ? dayjs(d).format('DD/MM/YYYY') : ''}</span>,
    },
    {
      title: 'Số ký hiệu', dataIndex: 'notation', width: 130,
      render: (val, r) => <span style={{ fontWeight: r.is_read ? 'normal' : 'bold' }}>{val}</span>,
    },
    {
      title: 'Trích yếu', dataIndex: 'abstract', ellipsis: true,
      render: (val, r) => (
        <Tooltip title={val}>
          <a style={{ fontWeight: r.is_read ? 'normal' : 'bold' }} href={`/van-ban-den/${r.id}`}>{val}</a>
        </Tooltip>
      ),
    },
    { title: 'CQ ban hành', dataIndex: 'publish_unit', width: 180, ellipsis: true },
    { title: 'Loại VB', dataIndex: 'doc_type_name', width: 110, ellipsis: true },
    {
      title: 'Độ khẩn', dataIndex: 'urgent_id', width: 90, align: 'center',
      render: (val: number) => { const u = URGENT_MAP[val]; return u && val > 1 ? <Tag color={u.color}>{u.text}</Tag> : null; },
    },
    {
      title: 'Trạng thái', width: 100, align: 'center',
      render: (_, r) => r.approved ? <Tag color="green">Đã duyệt</Tag> : <Tag color="gold">Chờ duyệt</Tag>,
    },
    {
      key: 'actions', width: 50, align: 'center', fixed: 'right',
      render: (_, record) => {
        const items = [
          { key: 'view', icon: <EyeOutlined />, label: 'Xem chi tiết', onClick: () => { window.location.href = `/van-ban-den/${record.id}`; } },
          ...(!record.approved ? [
            { key: 'edit', icon: <EditOutlined />, label: 'Sửa', onClick: () => openDrawer(record) },
            { key: 'approve', icon: <CheckCircleOutlined />, label: 'Duyệt', onClick: () => handleApprove(record) },
            { type: 'divider' as const },
            { key: 'delete', icon: <DeleteOutlined />, label: 'Xóa', danger: true, onClick: () => handleDelete(record) },
          ] : []),
        ];
        return (
          <Dropdown trigger={['click']} menu={{ items }}>
            <Button type="text" size="small" icon={<MoreOutlined style={{ fontSize: 18 }} />} style={{ color: '#64748b' }} />
          </Dropdown>
        );
      },
    },
  ];

  return (
    <Card
      title={<><FileTextOutlined style={{ marginRight: 8 }} />Văn bản đến</>}
      extra={
        <Space>
          {selectedRowKeys.length > 0 && <Button onClick={handleMarkReadBulk}>Đánh dấu đã đọc ({selectedRowKeys.length})</Button>}
          <Button type="primary" icon={<PlusOutlined />} onClick={() => openDrawer()}>Thêm mới</Button>
        </Space>
      }
    >
      <Row gutter={[12, 12]} style={{ marginBottom: 16 }}>
        <Col span={6}><Input.Search placeholder="Tìm kiếm trích yếu, ký hiệu..." allowClear onSearch={(val) => { setKeyword(val); setPage(1); }} /></Col>
        <Col span={4}><Select style={{ width: '100%' }} placeholder="Sổ văn bản" allowClear options={docBooks} value={filterDocBookId} onChange={(val) => { setFilterDocBookId(val); setPage(1); }} /></Col>
        <Col span={4}><Select style={{ width: '100%' }} placeholder="Loại văn bản" allowClear options={docTypes} value={filterDocTypeId} onChange={(val) => { setFilterDocTypeId(val); setPage(1); }} /></Col>
        <Col span={3}><Select style={{ width: '100%' }} placeholder="Độ khẩn" allowClear options={[{ value: 1, label: 'Thường' }, { value: 2, label: 'Khẩn' }, { value: 3, label: 'Hỏa tốc' }]} value={filterUrgentId} onChange={(val) => { setFilterUrgentId(val); setPage(1); }} /></Col>
        <Col span={5}><RangePicker style={{ width: '100%' }} format="DD/MM/YYYY" placeholder={['Từ ngày', 'Đến ngày']} value={filterDateRange} onChange={(val) => { setFilterDateRange(val as [dayjs.Dayjs, dayjs.Dayjs] | null); setPage(1); }} /></Col>
        <Col span={2}><Tooltip title="Xóa bộ lọc"><Button icon={<ReloadOutlined />} onClick={() => { setKeyword(''); setFilterDocBookId(undefined); setFilterDocTypeId(undefined); setFilterUrgentId(undefined); setFilterDateRange(null); setPage(1); }} /></Tooltip></Col>
      </Row>

      <Table<IncomingDoc>
        rowKey="id" loading={loading} columns={columns} dataSource={data} size="small" scroll={{ x: 1100 }}
        rowSelection={{ selectedRowKeys, onChange: setSelectedRowKeys }}
        pagination={{ current: page, pageSize, total, showSizeChanger: true, showTotal: (t) => `Tổng ${t} văn bản`, pageSizeOptions: ['10', '20', '50', '100'] }}
        onChange={(p) => { setPage(p.current || 1); setPageSize(p.pageSize || 20); }}
      />

      <Drawer
        title={editingRecord ? 'Sửa văn bản đến' : 'Thêm văn bản đến'}
        size={800} open={drawerOpen} onClose={() => setDrawerOpen(false)}
        rootClassName="drawer-gradient"
        extra={<Space><Button onClick={() => setDrawerOpen(false)} ghost style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}>Hủy</Button><Button type="primary" loading={saving} onClick={handleSave}>{editingRecord ? 'Cập nhật' : 'Tạo mới'}</Button></Space>}
      >
        <Form form={form} layout="vertical" autoComplete="off">
          <Row gutter={16}>
            <Col span={12}><Form.Item name="doc_book_id" label="Sổ văn bản" rules={[{ required: true, message: 'Bắt buộc' }]}><Select placeholder="Chọn sổ văn bản" options={docBooks} onChange={(val) => { if (val && !editingRecord) fetchNextNumber(val); }} /></Form.Item></Col>
            <Col span={6}><Form.Item name="number" label="Số đến"><InputNumber style={{ width: '100%' }} min={1} /></Form.Item></Col>
            <Col span={6}><Form.Item name="received_date" label="Ngày đến"><DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" /></Form.Item></Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}><Form.Item name="notation" label="Số ký hiệu"><Input placeholder="VD: 123/UBND-VP" maxLength={100} /></Form.Item></Col>
            <Col span={12}><Form.Item name="publish_unit" label="Cơ quan ban hành"><Input placeholder="VD: UBND tỉnh Lạng Sơn" maxLength={500} /></Form.Item></Col>
          </Row>
          <Form.Item name="abstract" label="Trích yếu nội dung" rules={[{ required: true, message: 'Bắt buộc' }]}><TextArea rows={3} placeholder="Trích yếu nội dung văn bản" /></Form.Item>
          <Row gutter={16}>
            <Col span={8}><Form.Item name="doc_type_id" label="Loại văn bản"><Select placeholder="Chọn loại" allowClear options={docTypes} /></Form.Item></Col>
            <Col span={8}><Form.Item name="doc_field_id" label="Lĩnh vực"><Select placeholder="Chọn lĩnh vực" allowClear options={docFields} /></Form.Item></Col>
            <Col span={8}><Form.Item name="signer" label="Người ký"><Input placeholder="Họ tên người ký" maxLength={200} /></Form.Item></Col>
          </Row>
          <Row gutter={16}>
            <Col span={6}><Form.Item name="sign_date" label="Ngày ký"><DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" /></Form.Item></Col>
            <Col span={6}><Form.Item name="publish_date" label="Ngày ban hành"><DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" /></Form.Item></Col>
            <Col span={6}><Form.Item name="expired_date" label="Hạn xử lý"><DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" /></Form.Item></Col>
            <Col span={6}><Form.Item name="secret_id" label="Độ mật" initialValue={1}><Select options={[{ value: 1, label: 'Thường' }, { value: 2, label: 'Mật' }, { value: 3, label: 'Tối mật' }, { value: 4, label: 'Tuyệt mật' }]} /></Form.Item></Col>
          </Row>
          <Row gutter={16}>
            <Col span={6}><Form.Item name="urgent_id" label="Độ khẩn" initialValue={1}><Select options={[{ value: 1, label: 'Thường' }, { value: 2, label: 'Khẩn' }, { value: 3, label: 'Hỏa tốc' }]} /></Form.Item></Col>
            <Col span={6}><Form.Item name="number_paper" label="Số tờ" initialValue={1}><InputNumber style={{ width: '100%' }} min={0} /></Form.Item></Col>
            <Col span={6}><Form.Item name="number_copies" label="Số bản" initialValue={1}><InputNumber style={{ width: '100%' }} min={0} /></Form.Item></Col>
            <Col span={6}><Form.Item name="is_received_paper" label="Bản giấy"><Select options={[{ value: false, label: 'Chưa nhận' }, { value: true, label: 'Đã nhận' }]} /></Form.Item></Col>
          </Row>
          <Form.Item name="recipients" label="Nơi nhận"><TextArea rows={2} placeholder="Nơi nhận văn bản" /></Form.Item>
        </Form>
      </Drawer>
    </Card>
  );
}
