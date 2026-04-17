'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Table, Tree, Tabs, Button, Drawer, Form, Input, Select, DatePicker,
  Space, Dropdown, Modal, Tag, Row, Col, Card, Skeleton, App, InputNumber,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import {
  PlusOutlined, EditOutlined, DeleteOutlined, MoreOutlined,
  InboxOutlined, FolderOpenOutlined, SearchOutlined,
} from '@ant-design/icons';
import type { DataNode } from 'antd/es/tree';
import dayjs from 'dayjs';
import { api } from '@/lib/api';
import { buildTree } from '@/lib/tree-utils';

const { TextArea } = Input;

// ─── Interfaces ───────────────────────────────────────────────────────────────

interface Warehouse {
  id: number;
  parent_id: number | null;
  code: string;
  name: string;
  phone_number?: string;
  address?: string;
  description?: string;
  type_id?: number;
  is_unit?: boolean;
  children?: Warehouse[];
}

interface Fond {
  id: number;
  parent_id: number | null;
  fond_code: string;
  fond_name: string;
  fond_history?: string;
  archives_time?: string;
  paper_total?: number;
  paper_digital?: number;
  description?: string;
  children?: Fond[];
}

interface HoSoRecord {
  id: number;
  file_code: string;
  title: string;
  fond_id: number;
  fond_name: string;
  warehouse_id: number;
  warehouse_name: string;
  in_charge_staff_id?: number;
  in_charge_staff_name?: string;
  start_date?: string;
  complete_date?: string;
  total_doc?: number;
  description?: string;
  keyword?: string;
  maintenance?: string;
  language?: string;
  format?: number;
  total_count?: number;
}

type DrawerType = 'warehouse' | 'fond' | 'record';

interface SelectOption {
  value: number;
  label: string;
}

// ─── Helper: convert tree to Ant Design TreeNode with actions ─────────────────

function mapWarehouseToTreeData(
  nodes: Warehouse[],
  onAdd: (parentId: number) => void,
  onEdit: (item: Warehouse) => void,
  onDelete: (id: number) => void
): DataNode[] {
  return nodes.map((node) => ({
    key: node.id,
    title: (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', minWidth: 0 }}>
        <span style={{ flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {node.code} - {node.name}
        </span>
        <Dropdown
          trigger={['click']}
          menu={{
            items: [
              {
                key: 'add-child',
                icon: <PlusOutlined />,
                label: 'Thêm kho con',
                onClick: (e) => { e.domEvent.stopPropagation(); onAdd(node.id); },
              },
              {
                key: 'edit',
                icon: <EditOutlined />,
                label: 'Sửa',
                onClick: (e) => { e.domEvent.stopPropagation(); onEdit(node); },
              },
              { type: 'divider' as const },
              {
                key: 'delete',
                icon: <DeleteOutlined />,
                label: 'Xóa',
                danger: true,
                onClick: (e) => {
                  e.domEvent.stopPropagation();
                  Modal.confirm({
                    title: 'Xác nhận xóa',
                    content: `Bạn có chắc muốn xóa kho "${node.name}"?`,
                    okText: 'Xóa',
                    cancelText: 'Hủy',
                    okButtonProps: { danger: true },
                    onOk: () => onDelete(node.id),
                  });
                },
              },
            ],
          }}
        >
          <Button
            type="text"
            size="small"
            icon={<MoreOutlined />}
            onClick={(e) => e.stopPropagation()}
            style={{ color: '#94a3b8', flexShrink: 0 }}
          />
        </Dropdown>
      </div>
    ),
    children: node.children ? mapWarehouseToTreeData(node.children, onAdd, onEdit, onDelete) : undefined,
  }));
}

function mapFondToTreeData(
  nodes: Fond[],
  onAdd: (parentId: number) => void,
  onEdit: (item: Fond) => void,
  onDelete: (id: number) => void
): DataNode[] {
  return nodes.map((node) => ({
    key: node.id,
    title: (
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', minWidth: 0 }}>
        <span style={{ flex: 1, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {node.fond_code} - {node.fond_name}
        </span>
        <Dropdown
          trigger={['click']}
          menu={{
            items: [
              {
                key: 'add-child',
                icon: <PlusOutlined />,
                label: 'Thêm phông con',
                onClick: (e) => { e.domEvent.stopPropagation(); onAdd(node.id); },
              },
              {
                key: 'edit',
                icon: <EditOutlined />,
                label: 'Sửa',
                onClick: (e) => { e.domEvent.stopPropagation(); onEdit(node); },
              },
              { type: 'divider' as const },
              {
                key: 'delete',
                icon: <DeleteOutlined />,
                label: 'Xóa',
                danger: true,
                onClick: (e) => {
                  e.domEvent.stopPropagation();
                  Modal.confirm({
                    title: 'Xác nhận xóa',
                    content: `Bạn có chắc muốn xóa phông "${node.fond_name}"?`,
                    okText: 'Xóa',
                    cancelText: 'Hủy',
                    okButtonProps: { danger: true },
                    onOk: () => onDelete(node.id),
                  });
                },
              },
            ],
          }}
        >
          <Button
            type="text"
            size="small"
            icon={<MoreOutlined />}
            onClick={(e) => e.stopPropagation()}
            style={{ color: '#94a3b8', flexShrink: 0 }}
          />
        </Dropdown>
      </div>
    ),
    children: node.children ? mapFondToTreeData(node.children, onAdd, onEdit, onDelete) : undefined,
  }));
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function KhoLuuTruPage() {
  const { message } = App.useApp();

  // Tree state
  const [warehouses, setWarehouses] = useState<Warehouse[]>([]);
  const [fonds, setFonds] = useState<Fond[]>([]);
  const [treeLoading, setTreeLoading] = useState(false);
  const [selectedWarehouseId, setSelectedWarehouseId] = useState<number | null>(null);
  const [selectedFondId, setSelectedFondId] = useState<number | null>(null);
  const [activeTab, setActiveTab] = useState<'kho' | 'phong'>('kho');

  // Record table state
  const [records, setRecords] = useState<HoSoRecord[]>([]);
  const [loading, setLoading] = useState(false);
  const [pagination, setPagination] = useState({ current: 1, pageSize: 20, total: 0 });
  const [keyword, setKeyword] = useState('');

  // Drawer state
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [drawerType, setDrawerType] = useState<DrawerType>('record');
  const [editingWarehouse, setEditingWarehouse] = useState<Warehouse | null>(null);
  const [editingFond, setEditingFond] = useState<Fond | null>(null);
  const [editingRecord, setEditingRecord] = useState<HoSoRecord | null>(null);
  const [saving, setSaving] = useState(false);
  const [parentIdForAdd, setParentIdForAdd] = useState<number | null>(null);
  const [form] = Form.useForm();

  // Options for selects
  const [warehouseOptions, setWarehouseOptions] = useState<SelectOption[]>([]);
  const [fondOptions, setFondOptions] = useState<SelectOption[]>([]);
  const [staffOptions, setStaffOptions] = useState<SelectOption[]>([]);

  // ── Flatten tree for options ────────────────────────────────────────────────

  const flattenWarehouses = useCallback((items: Warehouse[], prefix = ''): SelectOption[] => {
    return items.flatMap((item) => [
      { value: item.id, label: `${prefix}${item.code} - ${item.name}` },
      ...(item.children ? flattenWarehouses(item.children, prefix + '  ') : []),
    ]);
  }, []);

  const flattenFonds = useCallback((items: Fond[], prefix = ''): SelectOption[] => {
    return items.flatMap((item) => [
      { value: item.id, label: `${prefix}${item.fond_code} - ${item.fond_name}` },
      ...(item.children ? flattenFonds(item.children, prefix + '  ') : []),
    ]);
  }, []);

  // ── Fetch trees ─────────────────────────────────────────────────────────────

  const fetchWarehouses = useCallback(async () => {
    setTreeLoading(true);
    try {
      const { data: res } = await api.get('/kho-luu-tru/kho');
      const flat: Warehouse[] = res.data || [];
      const tree = buildTree(flat) as Warehouse[];
      setWarehouses(tree);
      setWarehouseOptions(flattenWarehouses(tree));
    } catch {
      message.error('Lỗi tải danh sách kho lưu trữ');
    } finally {
      setTreeLoading(false);
    }
  }, [message, flattenWarehouses]);

  const fetchFonds = useCallback(async () => {
    try {
      const { data: res } = await api.get('/kho-luu-tru/phong');
      const flat: Fond[] = res.data || [];
      const tree = buildTree(flat as unknown as (Fond & { id: number; parent_id: number | null })[]) as Fond[];
      setFonds(tree);
      setFondOptions(flattenFonds(tree));
    } catch {
      message.error('Lỗi tải danh sách phông lưu trữ');
    }
  }, [message, flattenFonds]);

  const fetchStaff = useCallback(async () => {
    try {
      const { data: res } = await api.get('/quan-tri/nguoi-dung', { params: { page: 1, pageSize: 500 } });
      setStaffOptions((res.data || []).map((s: { id: number; full_name: string }) => ({
        value: s.id,
        label: s.full_name,
      })));
    } catch {
      // Bỏ qua lỗi tải nhân viên
    }
  }, []);

  // ── Fetch records ────────────────────────────────────────────────────────────

  const fetchRecords = useCallback(async (page = 1, pageSize = 20) => {
    setLoading(true);
    try {
      const params: Record<string, unknown> = { page, page_size: pageSize };
      if (selectedFondId) params.fond_id = selectedFondId;
      if (selectedWarehouseId) params.warehouse_id = selectedWarehouseId;
      if (keyword) params.keyword = keyword;
      const { data: res } = await api.get('/kho-luu-tru/ho-so', { params });
      setRecords(res.data || []);
      setPagination((prev) => ({ ...prev, current: page, pageSize, total: res.pagination?.total || 0 }));
    } catch {
      message.error('Lỗi tải danh sách hồ sơ');
    } finally {
      setLoading(false);
    }
  }, [selectedFondId, selectedWarehouseId, keyword, message]);

  useEffect(() => {
    fetchWarehouses();
    fetchFonds();
    fetchStaff();
  }, [fetchWarehouses, fetchFonds, fetchStaff]);

  useEffect(() => {
    fetchRecords(1, pagination.pageSize);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedWarehouseId, selectedFondId]);

  // ── Warehouse CRUD ───────────────────────────────────────────────────────────

  const openWarehouseDrawer = useCallback((item: Warehouse | null, parentId: number | null = null) => {
    setDrawerType('warehouse');
    setEditingWarehouse(item);
    setParentIdForAdd(parentId);
    form.resetFields();
    if (item) {
      form.setFieldsValue({ ...item });
    } else if (parentId) {
      form.setFieldsValue({ parent_id: parentId });
    }
    setDrawerOpen(true);
  }, [form]);

  const handleDeleteWarehouse = useCallback(async (id: number) => {
    try {
      await api.delete(`/kho-luu-tru/kho/${id}`);
      message.success('Đã xóa kho lưu trữ');
      fetchWarehouses();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Lỗi xóa kho');
    }
  }, [message, fetchWarehouses]);

  // ── Fond CRUD ────────────────────────────────────────────────────────────────

  const openFondDrawer = useCallback((item: Fond | null, parentId: number | null = null) => {
    setDrawerType('fond');
    setEditingFond(item);
    setParentIdForAdd(parentId);
    form.resetFields();
    if (item) {
      form.setFieldsValue({ ...item });
    } else if (parentId) {
      form.setFieldsValue({ parent_id: parentId });
    }
    setDrawerOpen(true);
  }, [form]);

  const handleDeleteFond = useCallback(async (id: number) => {
    try {
      await api.delete(`/kho-luu-tru/phong/${id}`);
      message.success('Đã xóa phông lưu trữ');
      fetchFonds();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Lỗi xóa phông');
    }
  }, [message, fetchFonds]);

  // ── Record CRUD ──────────────────────────────────────────────────────────────

  const openRecordDrawer = useCallback((item: HoSoRecord | null) => {
    setDrawerType('record');
    setEditingRecord(item);
    form.resetFields();
    if (item) {
      form.setFieldsValue({
        ...item,
        start_date: item.start_date ? dayjs(item.start_date) : null,
        complete_date: item.complete_date ? dayjs(item.complete_date) : null,
      });
    } else {
      if (selectedFondId) form.setFieldValue('fond_id', selectedFondId);
      if (selectedWarehouseId) form.setFieldValue('warehouse_id', selectedWarehouseId);
    }
    setDrawerOpen(true);
  }, [form, selectedFondId, selectedWarehouseId]);

  const handleDeleteRecord = useCallback((id: number, title: string) => {
    Modal.confirm({
      title: 'Xác nhận xóa',
      content: `Bạn có chắc muốn xóa hồ sơ "${title}"?`,
      okText: 'Xóa',
      cancelText: 'Hủy',
      okButtonProps: { danger: true },
      onOk: async () => {
        try {
          await api.delete(`/kho-luu-tru/ho-so/${id}`);
          message.success('Đã xóa hồ sơ');
          fetchRecords(pagination.current, pagination.pageSize);
        } catch (err: unknown) {
          const e = err as { response?: { data?: { message?: string } } };
          message.error(e?.response?.data?.message || 'Lỗi xóa hồ sơ');
        }
      },
    });
  }, [message, fetchRecords, pagination.current, pagination.pageSize]);

  // ── Backend field error mapping ──────────────────────────────────────────────

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Mã kho đã tồn tại': 'code',
      'Mã phông đã tồn tại': 'code',
    };
    const fieldName = fieldErrorMap[errorMessage];
    if (fieldName) {
      form.setFields([{ name: fieldName, errors: [errorMessage] }]);
      return true;
    }
    return false;
  };

  // ── Drawer save ──────────────────────────────────────────────────────────────

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);

      if (drawerType === 'warehouse') {
        const payload = { ...values };
        if (editingWarehouse) {
          await api.put(`/kho-luu-tru/kho/${editingWarehouse.id}`, payload);
          message.success('Cập nhật kho thành công');
        } else {
          await api.post('/kho-luu-tru/kho', payload);
          message.success('Thêm kho thành công');
        }
        setDrawerOpen(false);
        fetchWarehouses();

      } else if (drawerType === 'fond') {
        const payload = { ...values };
        if (editingFond) {
          await api.put(`/kho-luu-tru/phong/${editingFond.id}`, payload);
          message.success('Cập nhật phông thành công');
        } else {
          await api.post('/kho-luu-tru/phong', payload);
          message.success('Thêm phông thành công');
        }
        setDrawerOpen(false);
        fetchFonds();

      } else if (drawerType === 'record') {
        const payload = {
          ...values,
          start_date: values.start_date ? dayjs(values.start_date).toISOString() : null,
          complete_date: values.complete_date ? dayjs(values.complete_date).toISOString() : null,
        };
        if (editingRecord) {
          await api.put(`/kho-luu-tru/ho-so/${editingRecord.id}`, payload);
          message.success('Cập nhật hồ sơ thành công');
        } else {
          await api.post('/kho-luu-tru/ho-so', payload);
          message.success('Thêm hồ sơ thành công');
        }
        setDrawerOpen(false);
        fetchRecords(pagination.current, pagination.pageSize);
      }
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } }; errorFields?: unknown[] };
      if (e?.errorFields) return;
      const msg = e?.response?.data?.message;
      if (msg && !setBackendFieldError(msg)) {
        message.error(msg);
      }
    } finally {
      setSaving(false);
    }
  };

  // ── Tree nodes ───────────────────────────────────────────────────────────────

  const warehouseTreeData = useMemo(
    () => mapWarehouseToTreeData(
      warehouses,
      (parentId) => openWarehouseDrawer(null, parentId),
      (item) => openWarehouseDrawer(item),
      handleDeleteWarehouse
    ),
    [warehouses, openWarehouseDrawer, handleDeleteWarehouse]
  );

  const fondTreeData = useMemo(
    () => mapFondToTreeData(
      fonds,
      (parentId) => openFondDrawer(null, parentId),
      (item) => openFondDrawer(item),
      handleDeleteFond
    ),
    [fonds, openFondDrawer, handleDeleteFond]
  );

  // ── Table columns ────────────────────────────────────────────────────────────

  const columns: ColumnsType<HoSoRecord> = [
    {
      title: 'STT',
      width: 56,
      align: 'center',
      render: (_: unknown, __: HoSoRecord, index: number) =>
        (pagination.current - 1) * pagination.pageSize + index + 1,
    },
    {
      title: 'Mã hồ sơ',
      dataIndex: 'file_code',
      key: 'file_code',
      width: 120,
      render: (v: string) => <span style={{ fontWeight: 600, color: '#1B3A5C' }}>{v}</span>,
    },
    {
      title: 'Tên hồ sơ',
      dataIndex: 'title',
      key: 'title',
      ellipsis: true,
    },
    {
      title: 'Phông lưu trữ',
      dataIndex: 'fond_name',
      key: 'fond_name',
      width: 160,
      ellipsis: true,
    },
    {
      title: 'Kho lưu trữ',
      dataIndex: 'warehouse_name',
      key: 'warehouse_name',
      width: 160,
      ellipsis: true,
    },
    {
      title: 'Ngày bắt đầu',
      dataIndex: 'start_date',
      key: 'start_date',
      width: 120,
      render: (d: string) => d ? dayjs(d).format('DD/MM/YYYY') : '—',
    },
    {
      title: 'Ngày hoàn thành',
      dataIndex: 'complete_date',
      key: 'complete_date',
      width: 140,
      render: (d: string) => d ? dayjs(d).format('DD/MM/YYYY') : '—',
    },
    {
      title: 'Số tài liệu',
      dataIndex: 'total_doc',
      key: 'total_doc',
      width: 100,
      align: 'center',
      render: (v: number) => v ?? 0,
    },
    {
      title: '',
      key: 'actions',
      width: 50,
      align: 'center',
      fixed: 'right',
      render: (_: unknown, record: HoSoRecord) => (
        <Dropdown
          trigger={['click']}
          menu={{
            items: [
              {
                key: 'edit',
                icon: <EditOutlined />,
                label: 'Sửa',
                onClick: () => openRecordDrawer(record),
              },
              { type: 'divider' as const },
              {
                key: 'delete',
                icon: <DeleteOutlined />,
                label: 'Xóa',
                danger: true,
                onClick: () => handleDeleteRecord(record.id, record.title),
              },
            ],
          }}
        >
          <Button
            type="text"
            size="small"
            icon={<MoreOutlined style={{ fontSize: 18 }} />}
            style={{ color: '#64748b' }}
          />
        </Dropdown>
      ),
    },
  ];

  // ── Drawer title ─────────────────────────────────────────────────────────────

  const drawerTitle = useMemo(() => {
    if (drawerType === 'warehouse') {
      return editingWarehouse ? 'Chỉnh sửa kho lưu trữ' : 'Thêm mới kho lưu trữ';
    }
    if (drawerType === 'fond') {
      return editingFond ? 'Chỉnh sửa phông lưu trữ' : 'Thêm mới phông lưu trữ';
    }
    return editingRecord ? 'Chỉnh sửa hồ sơ lưu trữ' : 'Thêm mới hồ sơ lưu trữ';
  }, [drawerType, editingWarehouse, editingFond, editingRecord]);

  // ── Tab items ─────────────────────────────────────────────────────────────────

  const treeTabItems = [
    {
      key: 'kho',
      label: (
        <span>
          <InboxOutlined style={{ marginRight: 6 }} />
          Kho lưu trữ
        </span>
      ),
      children: (
        <div>
          <Button
            type="dashed"
            icon={<PlusOutlined />}
            size="small"
            onClick={() => openWarehouseDrawer(null)}
            style={{ width: '100%', marginBottom: 12 }}
          >
            Thêm kho gốc
          </Button>
          {treeLoading ? (
            <Skeleton active paragraph={{ rows: 6 }} />
          ) : (
            <Tree
              treeData={warehouseTreeData}
              onSelect={(keys) => {
                const id = keys[0] ? Number(keys[0]) : null;
                setSelectedWarehouseId(id);
                setSelectedFondId(null);
              }}
              selectedKeys={selectedWarehouseId ? [selectedWarehouseId] : []}
              defaultExpandAll
              showLine
              blockNode
            />
          )}
        </div>
      ),
    },
    {
      key: 'phong',
      label: (
        <span>
          <FolderOpenOutlined style={{ marginRight: 6 }} />
          Phông lưu trữ
        </span>
      ),
      children: (
        <div>
          <Button
            type="dashed"
            icon={<PlusOutlined />}
            size="small"
            onClick={() => openFondDrawer(null)}
            style={{ width: '100%', marginBottom: 12 }}
          >
            Thêm phông gốc
          </Button>
          {treeLoading ? (
            <Skeleton active paragraph={{ rows: 6 }} />
          ) : (
            <Tree
              treeData={fondTreeData}
              onSelect={(keys) => {
                const id = keys[0] ? Number(keys[0]) : null;
                setSelectedFondId(id);
                setSelectedWarehouseId(null);
              }}
              selectedKeys={selectedFondId ? [selectedFondId] : []}
              defaultExpandAll
              showLine
              blockNode
            />
          )}
        </div>
      ),
    },
  ];

  // ── Render ────────────────────────────────────────────────────────────────────

  return (
    <div>
      {/* Page header */}
      <div className="page-header" style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <h1 className="page-title">
            <InboxOutlined style={{ color: '#0891B2' }} />
            Kho lưu trữ
          </h1>
          <p className="page-description">Quản lý kho, phông và hồ sơ lưu trữ</p>
        </div>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={() => openRecordDrawer(null)}
        >
          Thêm hồ sơ
        </Button>
      </div>

      <Row gutter={16}>
        {/* Left: Tree panel */}
        <Col xs={24} lg={7}>
          <Card
            variant="borderless"
            style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)', minHeight: 500 }}
          >
            <Tabs
              activeKey={activeTab}
              onChange={(k) => setActiveTab(k as 'kho' | 'phong')}
              items={treeTabItems}
              size="small"
            />
          </Card>
        </Col>

        {/* Right: Record table */}
        <Col xs={24} lg={17}>
          <Card
            variant="borderless"
            style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
            title={
              <span style={{ fontWeight: 600, color: '#1B3A5C' }}>
                Hồ sơ lưu trữ
                {(selectedWarehouseId || selectedFondId) && (
                  <Tag color="#0891B2" style={{ marginLeft: 8, fontWeight: 400 }}>
                    Đang lọc
                  </Tag>
                )}
              </span>
            }
            extra={
              <Space>
                <Input
                  placeholder="Tìm kiếm hồ sơ..."
                  value={keyword}
                  onChange={(e) => setKeyword(e.target.value)}
                  onPressEnter={() => fetchRecords(1, pagination.pageSize)}
                  prefix={<SearchOutlined style={{ color: '#94a3b8' }} />}
                  allowClear
                  style={{ width: 200 }}
                />
                <Button
                  icon={<SearchOutlined />}
                  onClick={() => fetchRecords(1, pagination.pageSize)}
                >
                  Tìm
                </Button>
              </Space>
            }
          >
            <Table<HoSoRecord>
              rowKey="id"
              loading={loading}
              columns={columns}
              dataSource={records}
              size="middle"
              scroll={{ x: 1000 }}
              pagination={{
                current: pagination.current,
                pageSize: pagination.pageSize,
                total: pagination.total,
                showSizeChanger: true,
                showTotal: (t) => `Tổng ${t} hồ sơ`,
                pageSizeOptions: ['10', '20', '50'],
                onChange: (page, pageSize) => fetchRecords(page, pageSize),
              }}
            />
          </Card>
        </Col>
      </Row>

      {/* Drawer */}
      <Drawer forceRender
        title={drawerTitle}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        destroyOnHidden
        rootClassName="drawer-gradient"
        size={720}
        extra={
          <Space>
            <Button
              onClick={() => setDrawerOpen(false)}
              ghost
              style={{ borderColor: 'rgba(255,255,255,0.6)', color: '#fff' }}
            >
              Hủy
            </Button>
            <Button type="primary" loading={saving} onClick={handleSave}>
              {(drawerType === 'warehouse' && editingWarehouse) ||
               (drawerType === 'fond' && editingFond) ||
               (drawerType === 'record' && editingRecord)
                ? 'Cập nhật'
                : 'Thêm mới'}
            </Button>
          </Space>
        }
      >
        <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit">

          {/* ── Warehouse form ── */}
          {drawerType === 'warehouse' && (
            <>
              <Form.Item label="Kho cha" name="parent_id">
                <Select
                  placeholder="Chọn kho cha (bỏ trống nếu là gốc)"
                  allowClear
                  options={warehouseOptions}
                  showSearch
                  optionFilterProp="label"
                />
              </Form.Item>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    label="Mã kho"
                    name="code"
                    rules={[{ required: true, message: 'Nhập mã kho' }]}
                  >
                    <Input placeholder="VD: KHO-01" maxLength={50} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    label="Tên kho"
                    name="name"
                    rules={[{ required: true, message: 'Nhập tên kho' }]}
                  >
                    <Input placeholder="Tên kho lưu trữ" maxLength={200} />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item label="Số điện thoại" name="phone_number" rules={[{ pattern: /^[0-9+\-\s()]*$/, message: 'Số điện thoại không hợp lệ' }]}>
                    <Input placeholder="Số điện thoại" maxLength={50} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="Địa chỉ" name="address">
                    <Input placeholder="Địa chỉ kho" maxLength={500} />
                  </Form.Item>
                </Col>
              </Row>
              <Form.Item label="Mô tả" name="description">
                <TextArea rows={3} maxLength={1000} placeholder="Mô tả kho lưu trữ" />
              </Form.Item>
            </>
          )}

          {/* ── Fond form ── */}
          {drawerType === 'fond' && (
            <>
              <Form.Item label="Phông cha" name="parent_id">
                <Select
                  placeholder="Chọn phông cha (bỏ trống nếu là gốc)"
                  allowClear
                  options={fondOptions}
                  showSearch
                  optionFilterProp="label"
                />
              </Form.Item>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    label="Mã phông"
                    name="fond_code"
                    rules={[{ required: true, message: 'Nhập mã phông' }]}
                  >
                    <Input placeholder="VD: PHONG-01" maxLength={50} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    label="Tên phông"
                    name="fond_name"
                    rules={[{ required: true, message: 'Nhập tên phông' }]}
                  >
                    <Input placeholder="Tên phông lưu trữ" maxLength={200} />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item label="Thời hạn lưu trữ" name="archives_time">
                    <Input placeholder="VD: Vĩnh viễn, 20 năm..." maxLength={100} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="Số tờ giấy" name="paper_total">
                    <InputNumber min={0} style={{ width: '100%' }} placeholder="Tổng số tờ" />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item label="Số tờ điện tử" name="paper_digital">
                    <InputNumber min={0} style={{ width: '100%' }} placeholder="Số tờ điện tử" />
                  </Form.Item>
                </Col>
              </Row>
              <Form.Item label="Lịch sử phông" name="fond_history">
                <TextArea rows={3} maxLength={2000} placeholder="Lịch sử hình thành phông lưu trữ" />
              </Form.Item>
              <Form.Item label="Mô tả" name="description">
                <TextArea rows={2} maxLength={1000} placeholder="Mô tả phông lưu trữ" />
              </Form.Item>
            </>
          )}

          {/* ── Record form ── */}
          {drawerType === 'record' && (
            <>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    label="Mã hồ sơ"
                    name="file_code"
                    rules={[{ required: true, message: 'Nhập mã hồ sơ' }]}
                  >
                    <Input placeholder="VD: HS-2024-001" maxLength={100} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    label="Tiêu đề hồ sơ"
                    name="title"
                    rules={[{ required: true, message: 'Nhập tiêu đề hồ sơ' }]}
                  >
                    <Input placeholder="Tên hồ sơ lưu trữ" maxLength={500} />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item
                    label="Phông lưu trữ"
                    name="fond_id"
                    rules={[{ required: true, message: 'Chọn phông lưu trữ' }]}
                  >
                    <Select
                      placeholder="Chọn phông"
                      options={fondOptions}
                      showSearch
                      optionFilterProp="label"
                    />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item
                    label="Kho lưu trữ"
                    name="warehouse_id"
                    rules={[{ required: true, message: 'Chọn kho lưu trữ' }]}
                  >
                    <Select
                      placeholder="Chọn kho"
                      options={warehouseOptions}
                      showSearch
                      optionFilterProp="label"
                    />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item label="Người phụ trách" name="in_charge_staff_id" rules={[{ required: true, message: 'Chọn người phụ trách' }]}>
                    <Select
                      placeholder="Chọn người phụ trách"
                      allowClear
                      options={staffOptions}
                      showSearch
                      optionFilterProp="label"
                    />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="Số tài liệu" name="total_doc">
                    <InputNumber min={0} style={{ width: '100%' }} placeholder="Tổng số tài liệu" />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item label="Ngày bắt đầu" name="start_date">
                    <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" placeholder="Chọn ngày" />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="Ngày hoàn thành" name="complete_date">
                    <DatePicker style={{ width: '100%' }} format="DD/MM/YYYY" placeholder="Chọn ngày" />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item label="Ngôn ngữ" name="language">
                    <Input placeholder="VD: Tiếng Việt" maxLength={100} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="Hình thức" name="format">
                    <Select
                      placeholder="Chọn hình thức"
                      allowClear
                      options={[
                        { value: 1, label: 'Bản giấy' },
                        { value: 2, label: 'Điện tử' },
                        { value: 3, label: 'Hỗn hợp' },
                      ]}
                    />
                  </Form.Item>
                </Col>
              </Row>
              <Row gutter={16}>
                <Col span={12}>
                  <Form.Item label="Thời hạn bảo quản" name="maintenance">
                    <Input placeholder="VD: Vĩnh viễn, 20 năm..." maxLength={200} />
                  </Form.Item>
                </Col>
                <Col span={12}>
                  <Form.Item label="Từ khóa" name="keyword">
                    <Input placeholder="Từ khóa tìm kiếm" maxLength={500} />
                  </Form.Item>
                </Col>
              </Row>
              <Form.Item label="Mô tả" name="description">
                <TextArea rows={3} maxLength={2000} placeholder="Mô tả hồ sơ lưu trữ" />
              </Form.Item>
            </>
          )}
        </Form>
      </Drawer>
    </div>
  );
}
