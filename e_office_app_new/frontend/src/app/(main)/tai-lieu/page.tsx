'use client';

import React, { useState, useEffect, useCallback, useMemo } from 'react';
import {
  Card, Row, Col, Table, Button, Input, InputNumber, Tree, Space, Drawer,
  Form, TreeSelect, Skeleton, Dropdown, Modal, App, Upload, Select,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import type { UploadFile, RcFile } from 'antd/es/upload/interface';
import {
  PlusOutlined, FolderOutlined, DeleteOutlined, EditOutlined,
  DownloadOutlined, MoreOutlined, ReloadOutlined, InboxOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import type { TreeNode } from '@/types/tree';
import { buildTree, filterTree, flattenTreeForSelect } from '@/lib/tree-utils';

const { TextArea } = Input;
const { Dragger } = Upload;

interface DocCategory {
  id: number;
  parent_id: number | null;
  code: string;
  name: string;
  description: string;
  date_process?: number;
}

interface Document {
  id: number;
  title: string;
  description: string;
  keyword: string;
  file_name: string;
  file_size: number;
  file_path: string;
  category_id: number;
  category_name: string;
  creator_name: string;
  created_date: string;
  total_count: number;
}

function formatFileSize(bytes: number): string {
  if (!bytes || bytes === 0) return '0 B';
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export default function TaiLieuPage() {
  const { message } = App.useApp();

  // Category tree state
  const [categoryLoading, setCategoryLoading] = useState(false);
  const [categories, setCategories] = useState<DocCategory[]>([]);
  const [treeData, setTreeData] = useState<TreeNode[]>([]);
  const [selectedCategoryId, setSelectedCategoryId] = useState<number | null>(null);
  const [searchTree, setSearchTree] = useState('');

  // Category drawer
  const [catDrawerOpen, setCatDrawerOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<DocCategory | null>(null);
  const [catSaving, setCatSaving] = useState(false);
  const [catForm] = Form.useForm();

  // Document table state
  const [docLoading, setDocLoading] = useState(false);
  const [documents, setDocuments] = useState<Document[]>([]);
  const [keyword, setKeyword] = useState('');
  const [pagination, setPagination] = useState({ current: 1, pageSize: 20, total: 0 });

  // Document drawer
  const [docDrawerOpen, setDocDrawerOpen] = useState(false);
  const [editingDoc, setEditingDoc] = useState<Document | null>(null);
  const [docSaving, setDocSaving] = useState(false);
  const [docForm] = Form.useForm();
  const [fileList, setFileList] = useState<UploadFile[]>([]);

  // ─────────────────── helpers ───────────────────

  const mapCategoriesToTree = useCallback((items: DocCategory[]): TreeNode[] => {
    const built = buildTree<DocCategory & { children?: DocCategory[] }>(items as any);
    function toNode(node: any): TreeNode {
      return {
        key: node.id,
        title: node.code ? `${node.code} - ${node.name}` : node.name,
        children: node.children ? node.children.map(toNode) : undefined,
        icon: <FolderOutlined />,
      };
    }
    return built.map(toNode);
  }, []);

  const treeSelectData = useMemo(() => {
    function toSelect(items: DocCategory[]): any[] {
      const built = buildTree<DocCategory & { children?: DocCategory[] }>(items as any);
      function toNode(node: any): any {
        return {
          value: node.id,
          title: node.code ? `${node.code} - ${node.name}` : node.name,
          children: node.children ? node.children.map(toNode) : undefined,
        };
      }
      return built.map(toNode);
    }
    return toSelect(categories);
  }, [categories]);

  const filteredTree = useMemo(() => filterTree(treeData, searchTree), [treeData, searchTree]);

  // ─────────────────── fetch ───────────────────

  const fetchCategories = useCallback(async () => {
    setCategoryLoading(true);
    try {
      const { data: res } = await api.get('/tai-lieu/danh-muc');
      const cats: DocCategory[] = res.data || [];
      setCategories(cats);
      setTreeData(mapCategoriesToTree(cats));
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh mục tài liệu');
    } finally {
      setCategoryLoading(false);
    }
  }, [message, mapCategoriesToTree]);

  const fetchDocuments = useCallback(async (
    catId: number | null = selectedCategoryId,
    kw: string = keyword,
    page = pagination.current,
    pageSize = pagination.pageSize
  ) => {
    setDocLoading(true);
    try {
      const params: any = { page, page_size: pageSize };
      if (catId) params.category_id = catId;
      if (kw) params.keyword = kw;
      const { data: res } = await api.get('/tai-lieu', { params });
      setDocuments(res.data || []);
      const total = res.data?.[0]?.total_count ?? res.pagination?.total ?? 0;
      setPagination((p) => ({ ...p, current: page, pageSize, total }));
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải danh sách tài liệu');
    } finally {
      setDocLoading(false);
    }
  }, [selectedCategoryId, keyword, pagination.current, pagination.pageSize, message]);

  useEffect(() => {
    fetchCategories();
  }, [fetchCategories]);

  useEffect(() => {
    fetchDocuments(selectedCategoryId, keyword, 1, pagination.pageSize);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selectedCategoryId]);

  // ─────────────────── category CRUD ───────────────────

  const handleAddCategory = (parentId?: number) => {
    setEditingCategory(null);
    catForm.resetFields();
    if (parentId) catForm.setFieldsValue({ parent_id: parentId });
    setCatDrawerOpen(true);
  };

  const handleEditCategory = (cat: DocCategory) => {
    setEditingCategory(cat);
    catForm.setFieldsValue({ ...cat });
    setCatDrawerOpen(true);
  };

  const handleDeleteCategory = (id: number) => {
    Modal.confirm({
      title: 'Xác nhận xóa',
      content: 'Bạn có chắc muốn xóa danh mục này? Tất cả tài liệu trong danh mục cũng sẽ bị ảnh hưởng.',
      okText: 'Xóa',
      okButtonProps: { danger: true },
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.delete(`/tai-lieu/danh-muc/${id}`);
          message.success('Xóa danh mục thành công');
          fetchCategories();
          if (selectedCategoryId === id) setSelectedCategoryId(null);
        } catch (err: any) {
          message.error(err?.response?.data?.message || 'Lỗi khi xóa danh mục');
        }
      },
    });
  };

  const setCatBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Mã danh mục đã tồn tại': 'code',
    };
    const fieldName = fieldErrorMap[errorMessage];
    if (fieldName) {
      catForm.setFields([{ name: fieldName, errors: [errorMessage] }]);
      return true;
    }
    return false;
  };

  const setDocBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Tiêu đề tài liệu là bắt buộc': 'title',
    };
    const fieldName = fieldErrorMap[errorMessage];
    if (fieldName) {
      docForm.setFields([{ name: fieldName, errors: [errorMessage] }]);
      return true;
    }
    return false;
  };

  const handleSaveCategory = async () => {
    try {
      const values = await catForm.validateFields();
      setCatSaving(true);
      if (editingCategory) {
        await api.put(`/tai-lieu/danh-muc/${editingCategory.id}`, values);
        message.success('Cập nhật danh mục thành công');
      } else {
        await api.post('/tai-lieu/danh-muc', values);
        message.success('Thêm danh mục thành công');
      }
      setCatDrawerOpen(false);
      fetchCategories();
    } catch (err: any) {
      if (err?.errorFields) return;
      const msg = err?.response?.data?.message;
      if (msg && !setCatBackendFieldError(msg)) message.error(msg);
    } finally {
      setCatSaving(false);
    }
  };

  // ─────────────────── document CRUD ───────────────────

  const handleAddDoc = () => {
    setEditingDoc(null);
    docForm.resetFields();
    if (selectedCategoryId) docForm.setFieldsValue({ category_id: selectedCategoryId });
    setFileList([]);
    setDocDrawerOpen(true);
  };

  const handleEditDoc = (doc: Document) => {
    setEditingDoc(doc);
    docForm.setFieldsValue({
      title: doc.title,
      category_id: doc.category_id,
      description: doc.description,
      keyword: doc.keyword,
    });
    setFileList([]);
    setDocDrawerOpen(true);
  };

  const handleDeleteDoc = (id: number) => {
    Modal.confirm({
      title: 'Xác nhận xóa',
      content: 'Bạn có chắc muốn xóa tài liệu này?',
      okText: 'Xóa',
      okButtonProps: { danger: true },
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.delete(`/tai-lieu/${id}`);
          message.success('Xóa tài liệu thành công');
          fetchDocuments();
        } catch (err: any) {
          message.error(err?.response?.data?.message || 'Lỗi khi xóa tài liệu');
        }
      },
    });
  };

  const handleDownloadDoc = async (doc: Document) => {
    try {
      const { data: res } = await api.get(`/tai-lieu/${doc.id}`);
      const url = res.data?.file_path;
      if (url) {
        window.open(url, '_blank');
      } else {
        message.warning('Không có đường dẫn tải xuống');
      }
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi khi tải tài liệu');
    }
  };

  const handleSaveDoc = async () => {
    try {
      const values = await docForm.validateFields();
      setDocSaving(true);

      const formData = new FormData();
      formData.append('title', values.title);
      if (values.category_id) formData.append('category_id', String(values.category_id));
      if (values.description) formData.append('description', values.description);
      if (values.keyword) formData.append('keyword', values.keyword);

      const rawFile = fileList[0]?.originFileObj as RcFile | undefined;
      if (rawFile) {
        formData.append('file', rawFile);
      }

      if (editingDoc) {
        await api.put(`/tai-lieu/${editingDoc.id}`, formData, {
          headers: { 'Content-Type': 'multipart/form-data' },
        });
        message.success('Cập nhật tài liệu thành công');
      } else {
        if (!rawFile) {
          message.error('Vui lòng chọn file tài liệu');
          setDocSaving(false);
          return;
        }
        await api.post('/tai-lieu', formData, {
          headers: { 'Content-Type': 'multipart/form-data' },
        });
        message.success('Thêm tài liệu thành công');
      }
      setDocDrawerOpen(false);
      fetchDocuments();
    } catch (err: any) {
      if (err?.errorFields) return;
      const msg = err?.response?.data?.message;
      if (msg && !setDocBackendFieldError(msg)) message.error(msg);
    } finally {
      setDocSaving(false);
    }
  };

  // ─────────────────── columns ───────────────────

  const docColumns: ColumnsType<Document> = [
    {
      title: 'STT',
      key: 'stt',
      width: 55,
      align: 'center',
      render: (_, __, index) => (pagination.current - 1) * pagination.pageSize + index + 1,
    },
    {
      title: 'Tên tài liệu',
      dataIndex: 'title',
      key: 'title',
      ellipsis: true,
    },
    {
      title: 'Danh mục',
      dataIndex: 'category_name',
      key: 'category_name',
      width: 160,
      ellipsis: true,
    },
    {
      title: 'File',
      dataIndex: 'file_name',
      key: 'file_name',
      width: 200,
      ellipsis: true,
      render: (name, record) => (
        <Button
          type="link"
          size="small"
          style={{ padding: 0 }}
          onClick={() => handleDownloadDoc(record)}
        >
          {name || '—'}
        </Button>
      ),
    },
    {
      title: 'Kích thước',
      dataIndex: 'file_size',
      key: 'file_size',
      width: 100,
      align: 'right',
      render: (v) => formatFileSize(v),
    },
    {
      title: 'Từ khóa',
      dataIndex: 'keyword',
      key: 'keyword',
      width: 130,
      ellipsis: true,
    },
    {
      title: 'Người tạo',
      dataIndex: 'creator_name',
      key: 'creator_name',
      width: 130,
      ellipsis: true,
    },
    {
      title: 'Ngày tạo',
      dataIndex: 'created_date',
      key: 'created_date',
      width: 110,
      render: (v) => v ? new Date(v).toLocaleDateString('vi-VN') : '—',
    },
    {
      title: '',
      key: 'actions',
      width: 50,
      align: 'center',
      fixed: 'right',
      render: (_, record) => (
        <Dropdown
          trigger={['click']}
          menu={{
            items: [
              {
                key: 'download',
                label: 'Tải xuống',
                icon: <DownloadOutlined />,
                onClick: () => handleDownloadDoc(record),
              },
              {
                key: 'edit',
                label: 'Sửa',
                icon: <EditOutlined />,
                onClick: () => handleEditDoc(record),
              },
              { type: 'divider' },
              {
                key: 'delete',
                label: 'Xóa',
                icon: <DeleteOutlined />,
                danger: true,
                onClick: () => handleDeleteDoc(record.id),
              },
            ],
          }}
        >
          <Button type="text" icon={<MoreOutlined />} size="small" />
        </Dropdown>
      ),
    },
  ];

  // ─────────────────── render ───────────────────

  return (
    <div>
      <div className="page-header">
        <span className="page-title">Quản lý tài liệu</span>
      </div>

      <Row gutter={16} wrap={false} style={{ margin: '0 16px 16px' }}>
        {/* Left: Category tree */}
        <Col flex="280px">
          <Card
            size="small"
            title="Danh mục tài liệu"
            extra={
              <Button
                type="primary"
                size="small"
                icon={<PlusOutlined />}
                onClick={() => handleAddCategory()}
              >
                Thêm
              </Button>
            }
            style={{ minHeight: 500 }}
          >
            <Input
              placeholder="Tìm danh mục..."
              value={searchTree}
              onChange={(e) => setSearchTree(e.target.value)}
              style={{ marginBottom: 8 }}
              size="small"
            />
            {categoryLoading ? (
              <Skeleton active paragraph={{ rows: 6 }} />
            ) : (
              <Tree
                treeData={filteredTree}
                selectedKeys={selectedCategoryId ? [selectedCategoryId] : []}
                onSelect={(keys) => {
                  const id = (keys[0] as number) ?? null;
                  setSelectedCategoryId(id);
                  fetchDocuments(id, keyword, 1, pagination.pageSize);
                }}
                titleRender={(node) => {
                  const cat = categories.find((c) => c.id === node.key);
                  return (
                    <span style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                      <span style={{ flex: 1 }}>{node.title as string}</span>
                      <Dropdown
                        trigger={['click']}
                        menu={{
                          items: [
                            {
                              key: 'add-child',
                              label: 'Thêm danh mục con',
                              icon: <PlusOutlined />,
                              onClick: (e) => { e.domEvent.stopPropagation(); handleAddCategory(node.key as number); },
                            },
                            {
                              key: 'edit',
                              label: 'Sửa',
                              icon: <EditOutlined />,
                              onClick: (e) => { e.domEvent.stopPropagation(); if (cat) handleEditCategory(cat); },
                            },
                            { type: 'divider' },
                            {
                              key: 'delete',
                              label: 'Xóa',
                              icon: <DeleteOutlined />,
                              danger: true,
                              onClick: (e) => { e.domEvent.stopPropagation(); handleDeleteCategory(node.key as number); },
                            },
                          ],
                        }}
                      >
                        <Button
                          type="text"
                          size="small"
                          icon={<MoreOutlined />}
                          onClick={(e) => e.stopPropagation()}
                          style={{ opacity: 0.6 }}
                        />
                      </Dropdown>
                    </span>
                  );
                }}
              />
            )}
          </Card>
        </Col>

        {/* Right: Document table */}
        <Col flex="1">
          <Card className="page-card">
            <div className="filter-row" style={{ marginBottom: 12 }}>
              <Space wrap>
                <Input
                  placeholder="Tìm kiếm tài liệu..."
                  value={keyword}
                  onChange={(e) => setKeyword(e.target.value)}
                  onPressEnter={() => fetchDocuments(selectedCategoryId, keyword, 1, pagination.pageSize)}
                  style={{ width: 260 }}
                  allowClear
                />
                <Button
                  onClick={() => fetchDocuments(selectedCategoryId, keyword, 1, pagination.pageSize)}
                >
                  Tìm kiếm
                </Button>
              </Space>
              <Space>
                <Button icon={<ReloadOutlined />} onClick={() => fetchDocuments()}>
                  Làm mới
                </Button>
                <Button
                  type="primary"
                  icon={<PlusOutlined />}
                  onClick={handleAddDoc}
                >
                  Thêm tài liệu
                </Button>
              </Space>
            </div>

            <Table
              rowKey="id"
              dataSource={documents}
              columns={docColumns}
              loading={docLoading}
              size="small"
              scroll={{ x: 1100 }}
              pagination={{
                current: pagination.current,
                pageSize: pagination.pageSize,
                total: pagination.total,
                showSizeChanger: true,
                showTotal: (total) => `Tổng ${total} tài liệu`,
                onChange: (page, pageSize) => {
                  setPagination((p) => ({ ...p, current: page, pageSize }));
                  fetchDocuments(selectedCategoryId, keyword, page, pageSize);
                },
              }}
            />
          </Card>
        </Col>
      </Row>

      {/* Category Drawer */}
      <Drawer
        title={editingCategory ? 'Chỉnh sửa danh mục' : 'Thêm danh mục tài liệu'}
        open={catDrawerOpen}
        onClose={() => setCatDrawerOpen(false)}
        size={520}
        rootClassName="drawer-gradient"
        extra={
          <Space>
            <Button onClick={() => setCatDrawerOpen(false)}>Hủy</Button>
            <Button type="primary" loading={catSaving} onClick={handleSaveCategory}>
              Lưu
            </Button>
          </Space>
        }
      >
        <Form form={catForm} layout="vertical" validateTrigger="onSubmit">
          <Form.Item name="code" label="Mã danh mục">
            <Input placeholder="Nhập mã danh mục" maxLength={50} />
          </Form.Item>
          <Form.Item
            name="name"
            label="Tên danh mục"
            rules={[{ required: true, message: 'Vui lòng nhập tên danh mục' }]}
          >
            <Input placeholder="Nhập tên danh mục" maxLength={200} />
          </Form.Item>
          <Form.Item name="parent_id" label="Danh mục cha">
            <TreeSelect
              treeData={treeSelectData}
              placeholder="Chọn danh mục cha (để trống nếu là gốc)"
              allowClear
              treeDefaultExpandAll
              style={{ width: '100%' }}
            />
          </Form.Item>
          <Form.Item name="description" label="Mô tả">
            <TextArea rows={3} placeholder="Mô tả danh mục" />
          </Form.Item>
          <Form.Item name="date_process" label="Thời hạn xử lý (ngày)">
            <InputNumber min={0} style={{ width: '100%' }} placeholder="Số ngày xử lý" />
          </Form.Item>
        </Form>
      </Drawer>

      {/* Document Drawer */}
      <Drawer
        title={editingDoc ? 'Chỉnh sửa tài liệu' : 'Thêm tài liệu mới'}
        open={docDrawerOpen}
        onClose={() => setDocDrawerOpen(false)}
        size={720}
        rootClassName="drawer-gradient"
        extra={
          <Space>
            <Button onClick={() => setDocDrawerOpen(false)}>Hủy</Button>
            <Button type="primary" loading={docSaving} onClick={handleSaveDoc}>
              Lưu
            </Button>
          </Space>
        }
      >
        <Form form={docForm} layout="vertical" validateTrigger="onSubmit">
          <Form.Item
            name="title"
            label="Tên tài liệu"
            rules={[{ required: true, message: 'Vui lòng nhập tên tài liệu' }]}
          >
            <Input placeholder="Nhập tên tài liệu" maxLength={500} />
          </Form.Item>

          <Form.Item
            name="category_id"
            label="Danh mục"
            rules={[{ required: true, message: 'Vui lòng chọn danh mục' }]}
          >
            <TreeSelect
              treeData={treeSelectData}
              placeholder="Chọn danh mục tài liệu"
              allowClear
              treeDefaultExpandAll
              style={{ width: '100%' }}
            />
          </Form.Item>

          <Form.Item name="description" label="Mô tả">
            <TextArea rows={3} placeholder="Mô tả tài liệu" />
          </Form.Item>

          <Form.Item name="keyword" label="Từ khóa">
            <Input placeholder="Nhập từ khóa (cách nhau bằng dấu phẩy)" maxLength={500} />
          </Form.Item>

          <Form.Item
            label={editingDoc ? 'File đính kèm (để trống nếu không đổi)' : 'File tài liệu'}
          >
            <Dragger
              fileList={fileList}
              beforeUpload={() => false}
              onChange={({ fileList: newList }) => setFileList(newList.slice(-1))}
              maxCount={1}
              accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.zip,.rar"
            >
              <p className="ant-upload-drag-icon">
                <InboxOutlined />
              </p>
              <p className="ant-upload-text">Nhấp hoặc kéo thả file vào đây</p>
              <p className="ant-upload-hint">
                Hỗ trợ: PDF, Word, Excel, PowerPoint, TXT, ZIP (tối đa 50MB)
              </p>
            </Dragger>
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
