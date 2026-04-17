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
  SendOutlined, FormOutlined, StopOutlined, CloseCircleOutlined, RollbackOutlined, DownloadOutlined, PrinterOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import { buildTree, flattenTreeForSelect } from '@/lib/tree-utils';
import { useSearchParams, useRouter, usePathname } from 'next/navigation';
import dayjs from 'dayjs';

const { TextArea } = Input;
const { RangePicker } = DatePicker;

interface DraftingDoc {
  id: number;
  number: number;
  sub_number: string;
  notation: string;
  document_code: string;
  abstract: string;
  drafting_unit_id: number;
  drafting_unit_name: string;
  drafting_user_id: number;
  drafting_user_name: string;
  publish_unit_id: number;
  publish_unit_name: string;
  publish_date: string;
  signer: string;
  sign_date: string;
  doc_book_id: number;
  doc_type_id: number;
  doc_field_id: number;
  secret_id: number;
  urgent_id: number;
  number_paper: number;
  number_copies: number;
  expired_date: string;
  recipients: string;
  approver: string;
  approved: boolean;
  is_released: boolean;
  created_by: number;
  created_at: string;
  doc_book_name: string;
  doc_type_name: string;
  doc_type_code: string;
  doc_field_name: string;
  created_by_name: string;
  attachment_count: number;
  total_count: number;
}

interface SelectOption { value: number; label: string }

interface DepartmentNode {
  id: number;
  name: string;
  children?: DepartmentNode[];
}

interface StaffItem {
  id: number;
  full_name: string;
}

const URGENT_MAP: Record<number, { text: string; color: string }> = {
  1: { text: 'Thường', color: 'default' },
  2: { text: 'Khẩn', color: 'orange' },
  3: { text: 'Hỏa tốc', color: 'red' },
};

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

export default function DraftingDocPage() {
  const { message, modal } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const searchParams = useSearchParams();
  const router = useRouter();
  const pathname = usePathname();
  const [loading, setLoading] = useState(false);
  const [data, setData] = useState<DraftingDoc[]>([]);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pageSize, setPageSize] = useState(20);
  const [keyword, setKeyword] = useState('');
  const [filterDocBookId, setFilterDocBookId] = useState<number | undefined>();
  const [filterDocTypeId, setFilterDocTypeId] = useState<number | undefined>();
  const [filterUrgentId, setFilterUrgentId] = useState<number | undefined>();
  const [filterIsReleased, setFilterIsReleased] = useState<boolean | undefined>();
  const [filterDateRange, setFilterDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs] | null>(null);
  const [filterDeptId, setFilterDeptId] = useState<number | undefined>();
  const [deptTreeData, setDeptTreeData] = useState<{ value: number; title: string; children?: any[] }[]>([]);
  const [docBooks, setDocBooks] = useState<SelectOption[]>([]);
  const [docTypes, setDocTypes] = useState<SelectOption[]>([]);
  const [docFields, setDocFields] = useState<SelectOption[]>([]);
  const [extraColumns, setExtraColumns] = useState<{ column_name: string; label: string; data_type: string; max_length: number | null; is_mandatory: boolean }[]>([]);
  const [departments, setDepartments] = useState<SelectOption[]>([]);
  const [staffList, setStaffList] = useState<SelectOption[]>([]);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [editingRecord, setEditingRecord] = useState<DraftingDoc | null>(null);
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
      if (filterIsReleased !== undefined) params.is_released = filterIsReleased;
      if (filterDateRange) {
        params.from_date = filterDateRange[0].startOf('day').toISOString();
        params.to_date = filterDateRange[1].endOf('day').toISOString();
      }
      if (filterDeptId) params.department_id = filterDeptId;
      const { data: res } = await api.get('/van-ban-du-thao', { params });
      setData(res.data || []);
      setTotal(res.pagination?.total || 0);
    } catch { message.error('Lỗi tải danh sách văn bản dự thảo'); }
    finally { setLoading(false); }
  }, [page, pageSize, keyword, filterDocBookId, filterDocTypeId, filterUrgentId, filterIsReleased, filterDateRange, filterDeptId, message]);

  const fetchDropdowns = useCallback(async () => {
    try {
      const [bookRes, typeRes, fieldRes, deptRes] = await Promise.all([
        api.get('/quan-tri/so-van-ban', { params: { type_id: 3 } }),
        api.get('/quan-tri/loai-van-ban/tree'),
        api.get('/quan-tri/linh-vuc'),
        api.get('/quan-tri/don-vi/tree'),
      ]);
      setDocBooks((bookRes.data.data || []).map((b: { id: number; name: string }) => ({ value: b.id, label: b.name })));
      setDocTypes((typeRes.data.data || []).map((t: { id: number; name: string }) => ({ value: t.id, label: t.name })));
      setDocFields((fieldRes.data.data || []).map((f: { id: number; name: string }) => ({ value: f.id, label: f.name })));
      const deptTree: DepartmentNode[] = deptRes.data.data || [];
      setDepartments(flattenDepartments(deptTree));
      if (user?.isAdmin) {
        const tree = buildTree(deptTree.map((d: any) => ({ id: d.id, parent_id: d.parent_id, name: d.name })));
        setDeptTreeData(flattenTreeForSelect(tree));
      }
    } catch { /* ignore */ }
  }, [user?.isAdmin]);

  const fetchExtraColumns = useCallback(async () => {
    try {
      const { data: res } = await api.get('/van-ban-du-thao/truong-bo-sung', { params: { doc_type_id: 3 } });
      setExtraColumns(res.data || []);
    } catch { setExtraColumns([]); }
  }, []);

  useEffect(() => { fetchDropdowns(); fetchExtraColumns(); }, [fetchDropdowns, fetchExtraColumns]);
  useEffect(() => { fetchData(); }, [fetchData]);

  // Handle ?edit=ID from detail page (run once)
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
      const { data: res } = await api.get('/van-ban-du-thao/so-tiep-theo', { params: { doc_book_id: docBookId } });
      form.setFieldsValue({ number: res.data?.number || 1 });
    } catch { /* ignore */ }
  };

  const fetchStaffByUnit = async (unitId: number) => {
    try {
      const { data: res } = await api.get('/quan-tri/nguoi-dung', { params: { unit_id: unitId } });
      const list = (res.data || []).map((u: StaffItem) => ({ value: u.id, label: u.full_name }));
      setStaffList(list);
    } catch { setStaffList([]); }
  };

  const openDrawer = async (record?: DraftingDoc) => {
    if (record) {
      setEditingRecord(record);
      form.setFieldsValue({
        ...record,
        publish_date: record.publish_date ? dayjs(record.publish_date) : null,
        sign_date: record.sign_date ? dayjs(record.sign_date) : null,
        expired_date: record.expired_date ? dayjs(record.expired_date) : null,
      });
      if (record.drafting_unit_id) {
        fetchStaffByUnit(record.drafting_unit_id);
      }
    } else {
      setEditingRecord(null);
      form.resetFields();
      form.setFieldsValue({
        secret_id: 1, urgent_id: 1, number_paper: 1, number_copies: 1,
        drafting_unit_id: user?.departmentId || user?.unitId,
        received_date: dayjs(),
      });
      // Load staff list trước, rồi mới set drafting_user_id (để Select có options)
      if (user?.departmentId || user?.unitId) {
        await fetchStaffByUnit(user.departmentId || user.unitId);
      }
      form.setFieldsValue({ drafting_user_id: user?.staffId });
    }
    setDrawerOpen(true);
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      const payload = {
        ...values,
        publish_date: values.publish_date?.toISOString() || null,
        sign_date: values.sign_date?.toISOString() || null,
        expired_date: values.expired_date?.toISOString() || null,
      };
      if (editingRecord) {
        const { data: res } = await api.put(`/van-ban-du-thao/${editingRecord.id}`, payload);
        if (!res.success) { message.error(res.message); return; }
        message.success('Cập nhật thành công');
      } else {
        const { data: res } = await api.post('/van-ban-du-thao', payload);
        if (!res.success) { message.error(res.message); return; }
        message.success('Tạo văn bản dự thảo thành công');
      }
      closeDrawer();
      fetchData();
    } catch (err: any) {
      if (err?.response?.data?.errors) {
        const backendErrors = err.response.data.errors;
        const fieldErrors = Object.entries(backendErrors).map(([name, msgs]) => ({
          name,
          errors: Array.isArray(msgs) ? msgs as string[] : [String(msgs)],
        }));
        form.setFields(fieldErrors);
      } else if (err?.response?.data?.message) {
        message.error(err.response.data.message);
      }
    } finally { setSaving(false); }
  };

  const handleDelete = (record: DraftingDoc) => {
    modal.confirm({
      title: 'Xác nhận xóa',
      content: `Xóa văn bản dự thảo "${record.abstract?.substring(0, 50)}..."?`,
      okText: 'Xóa', okType: 'danger', cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.delete(`/van-ban-du-thao/${record.id}`);
          message.success('Đã xóa');
          fetchData();
        } catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi xóa'); }
      },
    });
  };

  const handleApprove = async (record: DraftingDoc) => {
    modal.confirm({
      title: 'Xác nhận duyệt',
      content: `Duyệt văn bản dự thảo "${record.abstract?.substring(0, 50)}..."?`,
      okText: 'Duyệt', cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.patch(`/van-ban-du-thao/${record.id}/duyet`);
          message.success('Duyệt thành công');
          fetchData();
        } catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi duyệt'); }
      },
    });
  };

  const handleRetract = async (record: DraftingDoc) => {
    modal.confirm({
      title: 'Thu hồi văn bản dự thảo',
      content: 'Thu hồi sẽ xóa tất cả người nhận và đặt lại trạng thái chưa duyệt. Bạn chắc chắn?',
      okText: 'Thu hồi', okButtonProps: { danger: true }, cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.post(`/van-ban-du-thao/${record.id}/thu-hoi`);
          message.success('Thu hồi thành công');
          fetchData();
        } catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi thu hồi'); }
      },
    });
  };

  const handleUnapprove = async (record: DraftingDoc) => {
    modal.confirm({
      title: 'Xác nhận hủy duyệt',
      content: `Hủy duyệt văn bản dự thảo "${record.abstract?.substring(0, 50)}..."?`,
      okText: 'Hủy duyệt', okButtonProps: { danger: true }, cancelText: 'Đóng',
      onOk: async () => {
        try {
          await api.patch(`/van-ban-du-thao/${record.id}/huy-duyet`);
          message.success('Hủy duyệt thành công');
          fetchData();
        } catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi hủy duyệt'); }
      },
    });
  };

  const handleReject = (record: DraftingDoc) => {
    let reason = '';
    modal.confirm({
      title: 'Từ chối văn bản dự thảo',
      content: (
        <div style={{ marginTop: 12 }}>
          <div style={{ marginBottom: 8, color: '#595959' }}>Nhập lý do từ chối (không bắt buộc):</div>
          <Input.TextArea
            rows={3}
            placeholder="Lý do từ chối..."
            onChange={(e) => { reason = e.target.value; }}
          />
        </div>
      ),
      okText: 'Từ chối',
      okButtonProps: { danger: true },
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.patch(`/van-ban-du-thao/${record.id}/tu-choi`, { reason: reason.trim() || undefined });
          message.success('Đã từ chối văn bản dự thảo');
          fetchData();
        } catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi'); }
      },
    });
  };

  const handleRelease = async (record: DraftingDoc) => {
    modal.confirm({
      title: 'Xác nhận phát hành',
      content: `Phát hành văn bản "${record.abstract?.substring(0, 50)}..."? Sau khi phát hành sẽ không thể sửa hoặc xóa.`,
      okText: 'Phát hành', cancelText: 'Hủy',
      onOk: async () => {
        try {
          const { data: res } = await api.post(`/van-ban-du-thao/${record.id}/phat-hanh`);
          const outgoingId = res.data?.outgoing_doc_id;
          fetchData();
          if (outgoingId) {
            modal.success({
              title: 'Phát hành thành công',
              content: `Đã tạo văn bản đi #${outgoingId}.`,
              okText: 'Xem văn bản đi',
              cancelText: 'Ở lại',
              onOk: () => { window.location.href = `/van-ban-di/${outgoingId}`; },
            });
          } else { message.success('Phát hành thành công'); }
        } catch (err: any) { message.error(err?.response?.data?.message || 'Lỗi phát hành'); }
      },
    });
  };

  const getStatusTag = (record: DraftingDoc) => {
    if (record.is_released) return <Tag color="green">Đã phát hành</Tag>;
    if (record.approved) return <Tag color="blue">Đã duyệt</Tag>;
    return <Tag color="gold">Dự thảo</Tag>;
  };

  const columns: ColumnsType<DraftingDoc> = [
    {
      title: 'Số', dataIndex: 'number', width: 70, align: 'center',
      render: (num) => <span style={{ fontWeight: 600 }}>{num}</span>,
    },
    {
      title: 'Số phụ', dataIndex: 'sub_number', width: 90, align: 'center',
    },
    {
      title: 'Ký hiệu', dataIndex: 'notation', width: 130,
    },
    {
      title: 'Trích yếu', dataIndex: 'abstract', ellipsis: true,
      render: (val, r) => (
        <Tooltip title={val}>
          <a style={{ fontWeight: 500 }} href={`/van-ban-du-thao/${r.id}`}>{val}</a>
        </Tooltip>
      ),
    },
    {
      title: 'Đơn vị soạn', dataIndex: 'drafting_unit_name', width: 160, ellipsis: true,
    },
    {
      title: 'Người soạn', dataIndex: 'drafting_user_name', width: 140, ellipsis: true,
    },
    {
      title: 'Loại VB', dataIndex: 'doc_type_name', width: 110, ellipsis: true,
    },
    {
      title: 'Trạng thái', width: 120, align: 'center',
      render: (_, r) => getStatusTag(r),
    },
    {
      key: 'actions', width: 50, align: 'center', fixed: 'right',
      render: (_, record) => {
        const canEdit = !record.approved && !record.is_released;
        const canRelease = record.approved && !record.is_released;

        const items = [
          {
            key: 'view', icon: <EyeOutlined />, label: 'Xem chi tiết',
            onClick: () => { window.location.href = `/van-ban-du-thao/${record.id}`; },
          },
          ...(canEdit ? [
            {
              key: 'edit', icon: <EditOutlined />, label: 'Sửa',
              onClick: () => openDrawer(record),
            },
            {
              key: 'approve', icon: <CheckCircleOutlined />, label: 'Duyệt',
              onClick: () => handleApprove(record),
            },
            {
              key: 'reject', icon: <StopOutlined />, label: 'Từ chối', danger: true,
              onClick: () => handleReject(record),
            },
          ] : []),
          ...(canRelease ? [
            {
              key: 'release', icon: <SendOutlined />, label: 'Phát hành',
              onClick: () => handleRelease(record),
            },
            {
              key: 'unapprove', icon: <CloseCircleOutlined />, label: 'Hủy duyệt',
              onClick: () => handleUnapprove(record),
            },
          ] : []),
          ...(record.approved && !record.is_released ? [
            {
              key: 'retract', icon: <RollbackOutlined />, label: 'Thu hồi',
              onClick: () => handleRetract(record),
            },
          ] : []),
          ...(canEdit ? [
            { type: 'divider' as const },
            {
              key: 'delete', icon: <DeleteOutlined />, label: 'Xóa', danger: true,
              onClick: () => handleDelete(record),
            },
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

  const handleExportExcel = async () => {
    try {
      const params: Record<string, unknown> = {};
      if (keyword) params.keyword = keyword;
      if (filterDocBookId) params.doc_book_id = filterDocBookId;
      if (filterDocTypeId) params.doc_type_id = filterDocTypeId;
      if (filterDateRange) { params.from_date = filterDateRange[0].startOf('day').toISOString(); params.to_date = filterDateRange[1].endOf('day').toISOString(); }
      const response = await api.get('/van-ban-du-thao/xuat-excel', { params, responseType: 'blob' });
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement('a'); link.href = url;
      link.setAttribute('download', `VanBanDuThao_${new Date().toISOString().slice(0, 10)}.xlsx`);
      document.body.appendChild(link); link.click(); link.remove(); window.URL.revokeObjectURL(url);
    } catch { message.error('Lỗi xuất Excel'); }
  };

  return (
    <Card
      variant="borderless"
      style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(0,0,0,0.06)' }}
      title={
        <span style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C' }}>
          <FormOutlined style={{ marginRight: 8 }} />Văn bản dự thảo
        </span>
      }
      extra={
        <Space>
          <Button icon={<DownloadOutlined />} onClick={handleExportExcel}>Xuất Excel</Button>
          <Button icon={<PrinterOutlined />} onClick={() => window.print()}>In</Button>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => openDrawer()}>Thêm mới</Button>
        </Space>
      }
    >
      <Row gutter={[12, 12]} style={{ marginBottom: 16 }}>
        <Col span={5}>
          <Input.Search
            placeholder="Tìm kiếm trích yếu, ký hiệu..."
            allowClear
            onSearch={(val) => { setKeyword(val); setPage(1); }}
          />
        </Col>
        {user?.isAdmin && <Col span={4}><TreeSelect style={{ width: '100%' }} placeholder="Phòng ban" allowClear showSearch treeNodeFilterProp="title" treeData={deptTreeData} value={filterDeptId} onChange={(val) => { setFilterDeptId(val); setPage(1); }} /></Col>}
        <Col span={4}>
          <Select
            style={{ width: '100%' }}
            placeholder="Sổ văn bản"
            allowClear
            options={docBooks}
            value={filterDocBookId}
            onChange={(val) => { setFilterDocBookId(val); setPage(1); }}
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
        <Col span={3}>
          <Select
            style={{ width: '100%' }}
            placeholder="Trạng thái"
            allowClear
            options={[
              { value: true, label: 'Đã phát hành' },
              { value: false, label: 'Chưa phát hành' },
            ]}
            value={filterIsReleased}
            onChange={(val) => { setFilterIsReleased(val); setPage(1); }}
          />
        </Col>
        <Col span={3}>
          <Select
            style={{ width: '100%' }}
            placeholder="Độ khẩn"
            allowClear
            options={[
              { value: 1, label: 'Thường' },
              { value: 2, label: 'Khẩn' },
              { value: 3, label: 'Hỏa tốc' },
            ]}
            value={filterUrgentId}
            onChange={(val) => { setFilterUrgentId(val); setPage(1); }}
          />
        </Col>
        <Col span={4}>
          <RangePicker
            style={{ width: '100%' }}
            format="DD/MM/YYYY"
            placeholder={['Từ ngày', 'Đến ngày']}
            value={filterDateRange}
            onChange={(val) => { setFilterDateRange(val as [dayjs.Dayjs, dayjs.Dayjs] | null); setPage(1); }}
          />
        </Col>
        <Col span={1}>
          <Tooltip title="Xóa bộ lọc">
            <Button
              icon={<ReloadOutlined />}
              onClick={() => {
                setKeyword('');
                setFilterDocBookId(undefined);
                setFilterDocTypeId(undefined);
                setFilterUrgentId(undefined);
                setFilterIsReleased(undefined);
                setFilterDateRange(null);
                setFilterDeptId(undefined);
                setPage(1);
              }}
            />
          </Tooltip>
        </Col>
      </Row>

      <Table<DraftingDoc>
        rowKey="id"
        loading={loading}
        columns={columns}
        dataSource={data}
        size="small"
        scroll={{ x: 1100 }}
        rowSelection={{ selectedRowKeys, onChange: setSelectedRowKeys }}
        pagination={{
          current: page,
          pageSize,
          total,
          showSizeChanger: true,
          showTotal: (t) => `Tổng ${t} văn bản`,
          pageSizeOptions: ['10', '20', '50', '100'],
        }}
        onChange={(p) => { setPage(p.current || 1); setPageSize(p.pageSize || 20); }}
      />

      <Drawer
        title={editingRecord ? 'Sửa văn bản dự thảo' : 'Thêm văn bản dự thảo'}
        size={720}
        open={drawerOpen}
        onClose={() => closeDrawer()}
        rootClassName="drawer-gradient"
        extra={
          <Space>
            <Button onClick={() => closeDrawer()} ghost>
              Hủy
            </Button>
            <Button type="primary" loading={saving} onClick={handleSave}>
              {editingRecord ? 'Cập nhật' : 'Tạo mới'}
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off">
          <Row gutter={16}>
            <Col span={12}>
              <Form.Item name="doc_book_id" label="Sổ văn bản" rules={[{ required: true, message: 'Bắt buộc chọn sổ văn bản' }]}>
                <Select
                  placeholder="Chọn sổ văn bản"
                  options={docBooks}
                  onChange={(val) => { if (val && !editingRecord) fetchNextNumber(val); }}
                />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item name="number" label="Số">
                <InputNumber style={{ width: '100%' }} min={1} />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item name="sub_number" label="Số phụ">
                <Input placeholder="VD: a, b, bis..." maxLength={20} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="notation" label="Ký hiệu">
                <Input placeholder="VD: 123/UBND-VP" maxLength={100} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="document_code" label="Mã văn bản">
                <Input placeholder="Mã văn bản (nếu có)" maxLength={100} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="received_date" label="Ngày soạn">
                <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" />
              </Form.Item>
            </Col>
          </Row>

          <Form.Item name="abstract" label="Trích yếu nội dung" rules={[{ required: true, message: 'Bắt buộc nhập trích yếu' }]}>
            <TextArea rows={3} placeholder="Trích yếu nội dung văn bản dự thảo" maxLength={2000} showCount />
          </Form.Item>

          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="drafting_unit_id" label="Đơn vị soạn thảo" rules={[{ required: true, message: 'Bắt buộc chọn đơn vị soạn' }]}>
                <Select
                  placeholder="Chọn đơn vị soạn"
                  allowClear
                  showSearch
                  optionFilterProp="label"
                  options={departments}
                  onChange={(val) => {
                    form.setFieldsValue({ drafting_user_id: undefined });
                    setStaffList([]);
                    if (val) fetchStaffByUnit(val);
                  }}
                />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="drafting_user_id" label="Người soạn thảo" rules={[{ required: true, message: 'Bắt buộc chọn người soạn' }]}>
                <Select
                  placeholder="Chọn người soạn"
                  allowClear
                  showSearch
                  optionFilterProp="label"
                  options={staffList}
                  disabled={staffList.length === 0}
                />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="publish_unit_id" label="Đơn vị phát hành">
                <Select
                  placeholder="Chọn đơn vị phát hành"
                  allowClear
                  showSearch
                  optionFilterProp="label"
                  options={departments}
                />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={8}>
              <Form.Item name="doc_type_id" label="Loại văn bản">
                <Select placeholder="Chọn loại" allowClear options={docTypes} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="doc_field_id" label="Lĩnh vực">
                <Select placeholder="Chọn lĩnh vực" allowClear options={docFields} />
              </Form.Item>
            </Col>
            <Col span={8}>
              <Form.Item name="signer" label="Người ký">
                <Input placeholder="Họ tên người ký" maxLength={200} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={6}>
              <Form.Item name="sign_date" label="Ngày ký">
                <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item name="publish_date" label="Ngày ban hành">
                <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item name="expired_date" label="Hạn xử lý">
                <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item name="secret_id" label="Độ mật" initialValue={1}>
                <Select options={[
                  { value: 1, label: 'Thường' },
                  { value: 2, label: 'Mật' },
                  { value: 3, label: 'Tối mật' },
                  { value: 4, label: 'Tuyệt mật' },
                ]} />
              </Form.Item>
            </Col>
          </Row>

          <Row gutter={16}>
            <Col span={6}>
              <Form.Item name="urgent_id" label="Độ khẩn" initialValue={1}>
                <Select options={[
                  { value: 1, label: 'Thường' },
                  { value: 2, label: 'Khẩn' },
                  { value: 3, label: 'Hỏa tốc' },
                ]} />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item name="number_paper" label="Số tờ" initialValue={1}>
                <InputNumber style={{ width: '100%' }} min={0} />
              </Form.Item>
            </Col>
            <Col span={6}>
              <Form.Item name="number_copies" label="Số bản" initialValue={1}>
                <InputNumber style={{ width: '100%' }} min={0} />
              </Form.Item>
            </Col>
            <Col span={6} />
          </Row>

          <Form.Item name="recipients" label="Nơi nhận">
            <TextArea rows={2} placeholder="Nơi nhận văn bản" maxLength={2000} showCount />
          </Form.Item>

          {extraColumns.length > 0 && (
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

      <div className="print-area">
        <div className="print-header">
          <h2>DANH SÁCH VĂN BẢN DỰ THẢO</h2>
          <p>Ngày in: {dayjs().format('DD/MM/YYYY HH:mm')}</p>
        </div>
        <table>
          <thead>
            <tr>
              <th>STT</th><th>Số</th><th>Ký hiệu</th>
              <th>Trích yếu</th><th>Đơn vị soạn</th><th>Người soạn</th>
              <th>Người ký</th><th>Loại VB</th><th>Trạng thái</th>
            </tr>
          </thead>
          <tbody>
            {data.map((r, i) => (
              <tr key={r.id}>
                <td style={{ textAlign: 'center' }}>{i + 1}</td>
                <td style={{ textAlign: 'center' }}>{r.number}</td>
                <td>{r.notation}</td>
                <td>{r.abstract}</td>
                <td>{r.drafting_unit_name}</td>
                <td>{r.drafting_user_name}</td>
                <td>{r.signer}</td>
                <td>{r.doc_type_name}</td>
                <td>{r.is_released ? 'Đã phát hành' : r.approved ? 'Đã duyệt' : 'Dự thảo'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        <div className="print-footer">Tổng: {data.length} văn bản</div>
      </div>
    </Card>
  );
}
