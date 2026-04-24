'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Table, Button, Input, Space, Select, DatePicker, Drawer, Form,
  InputNumber, Tag, Modal, App, Row, Col, Tooltip, Dropdown, TreeSelect,
} from 'antd';
import type { ColumnsType, TablePaginationConfig } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, MoreOutlined,
  CheckCircleOutlined, EyeOutlined, FileTextOutlined, ReloadOutlined,
  CloseCircleOutlined, RollbackOutlined, DownloadOutlined, PrinterOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import { buildTree, flattenTreeForSelect } from '@/lib/tree-utils';
import { useSearchParams, useRouter, usePathname } from 'next/navigation';
import dayjs from 'dayjs';

const { TextArea } = Input;
const { RangePicker } = DatePicker;

// ─── Phase 1 feature flag: ẩn dynamic "Trường bổ sung" ─────────────────────
// Phase 2: đổi thành false để bật lại UI render extraColumns trong form.
// Lưu ý: API fetch /van-ban-den/truong-bo-sung vẫn chạy — chỉ JSX bị wrap.
const PHASE1_HIDE_CUSTOM_FIELDS = true;

interface IncomingDoc {
  id: number; received_date: string; number: number; notation: string;
  document_code: string; abstract: string; publish_unit: string;
  publish_date: string; signer: string; sign_date: string;
  doc_book_id: number; doc_type_id: number; doc_field_id: number;
  secret_id: number; urgent_id: number; number_paper: number;
  number_copies: number; expired_date: string; recipients: string; sents: string;
  approver: string; approved: boolean; is_handling: boolean;
  is_received_paper: boolean; archive_status: boolean;
  created_by: number; created_at: string;
  doc_book_name: string; doc_type_name: string; doc_type_code: string;
  doc_field_name: string; created_by_name: string;
  is_read: boolean; read_at: string; attachment_count: number; total_count: number;
  permissions?: {
    canEdit: boolean;
    canApprove: boolean;
    canRelease: boolean;
    canSend: boolean;
    canRetract: boolean;
  };
}

interface SelectOption { value: number; label: string }

interface DepartmentNode {
  id: number;
  name: string;
  children?: DepartmentNode[];
}

const URGENT_MAP: Record<number, { text: string; color: string }> = {
  1: { text: 'Thường', color: 'default' },
  2: { text: 'Khẩn', color: 'orange' },
  3: { text: 'Hỏa tốc', color: 'red' },
};

// Đệ quy duyệt cây đơn vị → mảng phẳng SelectOption (label kèm prefix cha)
const flattenDepartments = (nodes: DepartmentNode[], prefix = ''): SelectOption[] => {
  const result: SelectOption[] = [];
  for (const node of nodes) {
    const label = prefix ? `${prefix} / ${node.name}` : node.name;
    result.push({ value: node.id, label });
    if (node.children && node.children.length > 0) {
      result.push(...flattenDepartments(node.children, label));
    }
  }
  return result;
};

export default function IncomingDocPage() {
  const { message, modal } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
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
  const [filterSigner, setFilterSigner] = useState('');
  const [docBooks, setDocBooks] = useState<SelectOption[]>([]);
  const [docTypes, setDocTypes] = useState<SelectOption[]>([]);
  const [docFields, setDocFields] = useState<SelectOption[]>([]);
  const [departments, setDepartments] = useState<SelectOption[]>([]);
  // Phase 20: cơ quan ngoài LGSP cho field "Nơi gửi" tự nhập VB đến
  const [interOrgs, setInterOrgs] = useState<SelectOption[]>([]);
  const [filterDeptId, setFilterDeptId] = useState<number | undefined>();
  const [deptTreeData, setDeptTreeData] = useState<{ value: number; title: string; children?: any[] }[]>([]);
  const [extraColumns, setExtraColumns] = useState<{ column_name: string; label: string; data_type: string; max_length: number | null; is_mandatory: boolean }[]>([]);
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
      if (filterSigner) params.signer = filterSigner;
      if (filterDeptId) params.department_id = filterDeptId;
      const { data: res } = await api.get('/van-ban-den', { params });
      setData(res.data || []);
      setTotal(res.pagination?.total || 0);
    } catch { message.error('Lỗi tải danh sách văn bản đến'); }
    finally { setLoading(false); }
  }, [page, pageSize, keyword, filterDocBookId, filterDocTypeId, filterUrgentId, filterDateRange, filterSigner, filterDeptId, message]);

  const fetchDropdowns = useCallback(async () => {
    try {
      const [bookRes, typeRes, fieldRes, deptRes, orgRes] = await Promise.all([
        api.get('/quan-tri/so-van-ban', { params: { type_id: 1 } }),
        api.get('/quan-tri/loai-van-ban/tree'),
        api.get('/quan-tri/linh-vuc'),
        api.get('/quan-tri/don-vi/tree'),
        api.get('/quan-tri/co-quan-lien-thong').catch(() => ({ data: { data: [] } })),
      ]);
      setDocBooks((bookRes.data.data || []).map((b: { id: number; name: string }) => ({ value: b.id, label: b.name })));
      setDocTypes((typeRes.data.data || []).map((t: { id: number; name: string }) => ({ value: t.id, label: t.name })));
      setDocFields((fieldRes.data.data || []).map((f: { id: number; name: string }) => ({ value: f.id, label: f.name })));
      // Cây đơn vị — phẳng hóa cho Select "Cơ quan ban hành" (mọi user dùng được)
      const deptTree: DepartmentNode[] = deptRes.data.data || [];
      setDepartments(flattenDepartments(deptTree));
      setInterOrgs((orgRes.data.data || []).map((o: { id: number | string; name: string; code: string }) => ({ value: o.name, label: `${o.name} (${o.code})` })));
      // TreeSelect cho admin filter (dùng chung response, không gọi API lần 2)
      if (user?.isAdmin) {
        const tree = buildTree(deptTree.map((d: any) => ({ id: d.id, parent_id: d.parent_id, name: d.name })));
        setDeptTreeData(flattenTreeForSelect(tree));
      }
    } catch { /* ignore */ }
  }, [user?.isAdmin]);

  // type_id=1 = VB đến (theo doc_columns convention)
  const fetchExtraColumns = useCallback(async () => {
    try {
      const { data: res } = await api.get('/van-ban-den/truong-bo-sung', { params: { doc_type_id: 1 } });
      setExtraColumns(res.data || []);
    } catch { setExtraColumns([]); }
  }, []);

  useEffect(() => { fetchDropdowns(); fetchExtraColumns(); }, [fetchDropdowns, fetchExtraColumns]);
  useEffect(() => { fetchData(); }, [fetchData]);

  // Handle ?edit=ID from detail page "Sửa" button (run once)
  const [editHandled, setEditHandled] = useState(false);
  useEffect(() => {
    const editId = searchParams.get('edit');
    if (editId && data.length > 0 && !editHandled) {
      const record = data.find((d) => String(d.id) === editId);
      if (record) { openDrawer(record); setEditHandled(true); }
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [searchParams, data, editHandled]);

  const closeDrawer = () => {
    setDrawerOpen(false);
    if (searchParams.get('edit')) router.replace(pathname);
  };

  const fetchNextNumber = async (docBookId: number) => {
    try {
      const { data: res } = await api.get('/van-ban-den/so-den-tiep-theo', { params: { doc_book_id: docBookId } });
      form.setFieldsValue({ number: res.data?.number || 1 });
    } catch { /* ignore */ }
  };

  const openDrawer = async (record?: IncomingDoc) => {
    if (record) {
      setEditingRecord(record);
      form.setFieldsValue({
        ...record,
        received_date: record.received_date ? dayjs(record.received_date) : dayjs(),
        publish_date: record.publish_date ? dayjs(record.publish_date) : null,
        sign_date: record.sign_date ? dayjs(record.sign_date) : null,
        expired_date: record.expired_date ? dayjs(record.expired_date) : null,
        // publish_unit + sents lưu DB là string, Select mode="tags" cần array → wrap
        publish_unit: record.publish_unit ? [record.publish_unit] : [],
        sents: (record as any).sents ? [(record as any).sents] : [],
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
      // Tách extra_fields ra khỏi payload chính
      const { extra_fields, ...mainValues } = values;
      const extraFieldsData: Record<string, unknown> = {};
      if (extra_fields) {
        for (const [key, val] of Object.entries(extra_fields)) {
          // Convert dayjs to ISO string for date fields
          extraFieldsData[key] = val && typeof val === 'object' && 'toISOString' in (val as object) ? (val as dayjs.Dayjs).toISOString() : val;
        }
      }
      // Select mode="tags" trả về array — backend SP nhận TEXT, lấy phần tử đầu
      const publishUnitRaw = mainValues.publish_unit;
      const publishUnit = Array.isArray(publishUnitRaw)
        ? (publishUnitRaw[0] || '')
        : (publishUnitRaw || '');
      // Phase 20: 'sents' (Nơi gửi) cũng dùng Select mode="tags" → cần convert array→string
      const sentsRaw = mainValues.sents;
      const sentsValue = Array.isArray(sentsRaw)
        ? (sentsRaw[0] || '')
        : (sentsRaw || '');
      const payload = {
        ...mainValues,
        publish_unit: publishUnit,
        sents: sentsValue,
        received_date: mainValues.received_date?.toISOString(),
        publish_date: mainValues.publish_date?.toISOString() || null,
        sign_date: mainValues.sign_date?.toISOString() || null,
        expired_date: mainValues.expired_date?.toISOString() || null,
        extra_fields: Object.keys(extraFieldsData).length > 0 ? extraFieldsData : undefined,
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
      closeDrawer();
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

  const handleUnapprove = async (record: IncomingDoc) => {
    modal.confirm({
      title: 'Xác nhận hủy duyệt', content: `Hủy duyệt văn bản "${record.abstract?.substring(0, 50)}..."?`,
      okText: 'Hủy duyệt', okButtonProps: { danger: true }, cancelText: 'Đóng',
      onOk: async () => {
        try { await api.patch(`/van-ban-den/${record.id}/huy-duyet`); message.success('Hủy duyệt thành công'); fetchData(); }
        catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi hủy duyệt'); }
      },
    });
  };

  const handleRetract = async (record: IncomingDoc) => {
    modal.confirm({
      title: 'Thu hồi văn bản đến', content: 'Thu hồi sẽ xóa tất cả người nhận và đặt lại trạng thái chưa duyệt. Bạn chắc chắn?',
      okText: 'Thu hồi', okButtonProps: { danger: true }, cancelText: 'Hủy',
      onOk: async () => {
        try { await api.post(`/van-ban-den/${record.id}/thu-hoi`); message.success('Thu hồi thành công'); fetchData(); }
        catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi thu hồi'); }
      },
    });
  };

  const handleApprove = async (record: IncomingDoc) => {
    try { await api.patch(`/van-ban-den/${record.id}/duyet`); message.success('Duyệt thành công'); fetchData(); }
    catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi duyệt'); }
  };

  const handleExportExcel = async () => {
    try {
      const params: Record<string, unknown> = {};
      if (filterDocBookId) params.doc_book_id = filterDocBookId;
      if (filterDocTypeId) params.doc_type_id = filterDocTypeId;
      if (keyword) params.keyword = keyword;
      if (filterDateRange) {
        params.from_date = filterDateRange[0].startOf('day').toISOString();
        params.to_date = filterDateRange[1].endOf('day').toISOString();
      }
      const response = await api.get('/van-ban-den/xuat-excel', { params, responseType: 'blob' });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a');
      link.href = url;
      link.setAttribute('download', `VanBanDen_${new Date().toISOString().slice(0, 10)}.xlsx`);
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(url);
    } catch { message.error('Lỗi xuất Excel'); }
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
          <a className="cell-abstract" href={`/van-ban-den/${r.id}`}>{val}</a>
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
      title: 'Trạng thái', width: 110, align: 'center',
      render: (_, r: any) => r.approved ? <Tag color="green">Đã duyệt</Tag> : r.rejected_by ? <Tag color="red">Từ chối</Tag> : <Tag color="gold">Chờ duyệt</Tag>,
    },
    {
      key: 'actions', width: 50, align: 'center', fixed: 'right',
      render: (_, record) => {
        const perms = record.permissions;
        const statusAllowEdit = !record.approved;
        const statusAllowRetract = !!record.approved;
        const isSourceManual = ((record as any).source_type || 'manual') === 'manual';

        const canEdit = statusAllowEdit && isSourceManual && (perms?.canEdit ?? false);
        const canApprove = statusAllowEdit && (perms?.canApprove ?? false);
        const canUnapprove = !statusAllowEdit && (perms?.canApprove ?? false);
        const canRetract = statusAllowRetract && (perms?.canRetract ?? false);
        const canDelete = statusAllowEdit && (perms?.canEdit ?? false);

        const items = [
          { key: 'view', icon: <EyeOutlined />, label: 'Xem chi tiết', onClick: () => { window.location.href = `/van-ban-den/${record.id}`; } },
          ...(canEdit ? [{ key: 'edit', icon: <EditOutlined />, label: 'Sửa', onClick: () => openDrawer(record) }] : []),
          ...(canApprove ? [{ key: 'approve', icon: <CheckCircleOutlined />, label: 'Duyệt', onClick: () => handleApprove(record) }] : []),
          ...(canUnapprove ? [{ key: 'unapprove', icon: <CloseCircleOutlined />, label: 'Hủy duyệt', onClick: () => handleUnapprove(record) }] : []),
          ...(canRetract ? [{ key: 'retract', icon: <RollbackOutlined />, label: 'Thu hồi', onClick: () => handleRetract(record) }] : []),
          ...(canDelete ? [
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
      className="page-card"
      title={<><FileTextOutlined style={{ marginRight: 8 }} />Văn bản đến</>}
      extra={
        <Space>
          {selectedRowKeys.length > 0 && <Button onClick={handleMarkReadBulk}>Đánh dấu đã đọc ({selectedRowKeys.length})</Button>}
          <Button icon={<DownloadOutlined />} onClick={handleExportExcel}>Xuất Excel</Button>
          <Button icon={<PrinterOutlined />} onClick={() => window.print()}>In</Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => openDrawer()}>Thêm mới</Button>
        </Space>
      }
    >
      <div className="list-filter-bar">
        <Row gutter={[10, 10]}>
          <Col span={6}><Input.Search placeholder="Tìm kiếm trích yếu, ký hiệu..." allowClear onSearch={(val) => { setKeyword(val); setPage(1); }} /></Col>
          {user?.isAdmin && <Col span={4}><TreeSelect style={{ width: '100%' }} placeholder="Phòng ban" allowClear showSearch treeNodeFilterProp="title" treeData={deptTreeData} value={filterDeptId} onChange={(val) => { setFilterDeptId(val); setPage(1); }} /></Col>}
          <Col span={4}><Select style={{ width: '100%' }} placeholder="Sổ văn bản" allowClear options={docBooks} value={filterDocBookId} onChange={(val) => { setFilterDocBookId(val); setPage(1); }} /></Col>
          <Col span={4}><Select style={{ width: '100%' }} placeholder="Loại văn bản" allowClear options={docTypes} value={filterDocTypeId} onChange={(val) => { setFilterDocTypeId(val); setPage(1); }} /></Col>
          <Col span={3}><Select style={{ width: '100%' }} placeholder="Độ khẩn" allowClear options={[{ value: 1, label: 'Thường' }, { value: 2, label: 'Khẩn' }, { value: 3, label: 'Hỏa tốc' }]} value={filterUrgentId} onChange={(val) => { setFilterUrgentId(val); setPage(1); }} /></Col>
          <Col span={5}><RangePicker style={{ width: '100%' }} format="DD/MM/YYYY" placeholder={['Từ ngày', 'Đến ngày']} value={filterDateRange} onChange={(val) => { setFilterDateRange(val as [dayjs.Dayjs, dayjs.Dayjs] | null); setPage(1); }} /></Col>
          <Col span={2}><Tooltip title="Xóa bộ lọc"><Button icon={<ReloadOutlined />} onClick={() => { setKeyword(''); setFilterDocBookId(undefined); setFilterDocTypeId(undefined); setFilterUrgentId(undefined); setFilterDateRange(null); setFilterSigner(''); setFilterDeptId(undefined); setPage(1); }} /></Tooltip></Col>
        </Row>
      </div>

      <Table<IncomingDoc>
        className="enhanced-table"
        rowKey="id" loading={loading} columns={columns} dataSource={data} size="small" scroll={{ x: 1100 }}
        rowSelection={{ selectedRowKeys, onChange: setSelectedRowKeys }}
        rowClassName={(record) => record.is_read ? '' : 'row-unread'}
        pagination={{ current: page, pageSize, total, showSizeChanger: true, showTotal: (t) => `Tổng ${t} văn bản`, pageSizeOptions: ['10', '20', '50', '100'] }}
        onChange={(p) => { setPage(p.current || 1); setPageSize(p.pageSize || 20); }}
      />

      <Drawer forceRender
        title={editingRecord ? 'Sửa văn bản đến' : 'Thêm văn bản đến'}
        size={800} open={drawerOpen} onClose={() => closeDrawer()}
        rootClassName="drawer-gradient"
        extra={<Space><Button onClick={() => closeDrawer()} ghost style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}>Hủy</Button><Button type="primary" loading={saving} onClick={handleSave}>{editingRecord ? 'Cập nhật' : 'Tạo mới'}</Button></Space>}
      >
        <Form form={form} layout="vertical" autoComplete="off">
          <Row gutter={16}>
            <Col span={9}><Form.Item name="doc_book_id" label="Sổ văn bản" rules={[{ required: true, message: 'Bắt buộc' }]}><Select placeholder="Chọn sổ văn bản" options={docBooks} onChange={(val) => { if (val && !editingRecord) fetchNextNumber(val); }} /></Form.Item></Col>
            <Col span={5}><Form.Item name="number" label="Số đến"><InputNumber style={{ width: '100%' }} min={1} /></Form.Item></Col>
            <Col span={4}><Form.Item name="sub_number" label="Số phụ"><Input placeholder="VD: a, b, c" maxLength={20} /></Form.Item></Col>
            <Col span={6}><Form.Item name="received_date" label="Ngày đến" rules={[{ required: true, message: 'Ngày đến là bắt buộc' }]}><DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" /></Form.Item></Col>
          </Row>
          <Row gutter={16}>
            <Col span={12}><Form.Item name="notation" label="Ký hiệu"><Input placeholder="VD: 123/UBND-VP" maxLength={100} /></Form.Item></Col>
            <Col span={12}><Form.Item name="publish_unit" label="Cơ quan ban hành"><Select
              mode="tags"
              maxCount={1}
              placeholder="Chọn hoặc nhập cơ quan ban hành"
              allowClear
              showSearch
              optionFilterProp="label"
              options={departments.map((d) => ({ value: d.label, label: d.label }))}
            /></Form.Item></Col>
          </Row>
          <Form.Item name="abstract" label="Trích yếu nội dung" rules={[{ required: true, message: 'Bắt buộc' }]}><TextArea rows={3} placeholder="Trích yếu nội dung văn bản" maxLength={2000} showCount /></Form.Item>
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
          <Row gutter={16}>
            <Col span={12}><Form.Item name="document_code" label="Mã văn bản (số CV gốc bên gửi)"><Input placeholder="VD: 123/CV-BNV" maxLength={100} /></Form.Item></Col>
            <Col span={12}>
              <Form.Item
                name="sents"
                label="Nơi gửi (cơ quan/đơn vị đã gửi VB này đến)"
                rules={[{ required: true, message: 'Bắt buộc khi tự nhập VB đến' }]}
                tooltip="Chọn từ danh sách (đơn vị nội bộ + cơ quan LGSP) hoặc gõ tên tự do nếu chưa có trong DB"
              >
                <Select
                  showSearch
                  allowClear
                  placeholder="Chọn hoặc gõ tên cơ quan gửi..."
                  filterOption={(input, opt) => (opt?.label as string)?.toLowerCase().includes(input.toLowerCase())}
                  options={[
                    { label: 'Đơn vị nội bộ (trong tỉnh)', options: departments.map((d) => ({ value: d.label as string, label: d.label as string })) },
                    { label: 'Cơ quan ngoài LGSP', options: interOrgs },
                  ]}
                  // Cho phép gõ tag mới (cơ quan ngoài cả 2 list)
                  mode="tags"
                  maxCount={1}
                />
              </Form.Item>
            </Col>
          </Row>
          {/* Phase 20 v3.0: bỏ field 'Nơi nhận' — VÔ LÝ cho VB đến (văn thư là người NHẬN, không phải người gửi nên không nhập 'nơi nhận') */}

          {/* Dynamic extra fields */}
          {!PHASE1_HIDE_CUSTOM_FIELDS && extraColumns.length > 0 && (
            <>
              <div style={{ borderTop: '1px dashed #d9d9d9', margin: '16px 0 12px', paddingTop: 12 }}>
                <span style={{ fontWeight: 600, color: '#1B3A5C', fontSize: 13 }}>Trường bổ sung</span>
              </div>
              <Row gutter={16}>
                {extraColumns.map((col) => (
                  <Col span={col.data_type === 'textarea' ? 24 : 12} key={col.column_name}>
                    <Form.Item
                      name={['extra_fields', col.column_name]}
                      label={col.label}
                      rules={col.is_mandatory ? [{ required: true, message: `${col.label} là bắt buộc` }] : undefined}
                    >
                      {col.data_type === 'date' ? (
                        <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" />
                      ) : col.data_type === 'number' ? (
                        <InputNumber style={{ width: '100%' }} />
                      ) : col.data_type === 'textarea' ? (
                        <TextArea rows={2} maxLength={col.max_length || undefined} />
                      ) : (
                        <Input maxLength={col.max_length || undefined} placeholder={col.label} />
                      )}
                    </Form.Item>
                  </Col>
                ))}
              </Row>
            </>
          )}
        </Form>
      </Drawer>

      {/* Hidden print area */}
      <div className="print-area">
        <div className="print-header">
          <h2>DANH SÁCH VĂN BẢN ĐẾN</h2>
          <p>Ngày in: {dayjs().format('DD/MM/YYYY HH:mm')}</p>
        </div>
        <table>
          <thead>
            <tr>
              <th>STT</th><th>Số đến</th><th>Ngày đến</th><th>Số ký hiệu</th>
              <th>Trích yếu</th><th>CQ ban hành</th><th>Người ký</th>
              <th>Loại VB</th><th>Trạng thái</th>
            </tr>
          </thead>
          <tbody>
            {data.map((r, i) => (
              <tr key={r.id}>
                <td style={{ textAlign: 'center' }}>{i + 1}</td>
                <td style={{ textAlign: 'center' }}>{r.number}</td>
                <td>{r.received_date ? dayjs(r.received_date).format('DD/MM/YYYY') : ''}</td>
                <td>{r.notation}</td>
                <td>{r.abstract}</td>
                <td>{r.publish_unit}</td>
                <td>{r.signer}</td>
                <td>{r.doc_type_name}</td>
                <td>{r.approved ? 'Đã duyệt' : 'Chờ duyệt'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="print-footer">Tổng: {data.length} văn bản</div>
      </div>
    </Card>
  );
}
