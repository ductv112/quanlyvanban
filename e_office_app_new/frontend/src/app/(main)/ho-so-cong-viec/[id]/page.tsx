'use client';

import React, { useState, useEffect, useCallback, useRef } from 'react';
import {
  Card, Tabs, Table, Button, Form, Input, Select, DatePicker, Tag, Badge,
  Progress, Upload, Avatar, Divider, Modal, Slider, InputNumber, Space,
  Breadcrumb, Skeleton, Radio, Popconfirm, App, Checkbox, Tree,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import type { DataNode } from 'antd/es/tree';
// UploadRequestOption type inline (rc-upload not directly available)
type UploadRequestOption = {
  file: File | Blob | string;
  onSuccess?: (body: unknown, xhr?: XMLHttpRequest) => void;
  onError?: (error: Error, body?: unknown) => void;
  onProgress?: (event: { percent: number }) => void;
  data?: Record<string, unknown>;
  filename?: string;
  headers?: Record<string, string>;
  withCredentials?: boolean;
  action?: string;
  method?: string;
};
import {
  ArrowLeftOutlined, FolderOutlined, FileTextOutlined, TeamOutlined,
  CommentOutlined, PaperClipOutlined, ApartmentOutlined, SaveOutlined,
  UploadOutlined, DeleteOutlined, DownloadOutlined, PlusOutlined,
  ExclamationCircleOutlined, FilePdfOutlined, FileWordOutlined,
  FileExcelOutlined, FileImageOutlined, FileOutlined, LinkOutlined,
  SendOutlined, SwapOutlined, HistoryOutlined,
  SafetyOutlined, SafetyCertificateOutlined, CheckCircleOutlined,
  CheckOutlined, CloseOutlined, RollbackOutlined, FieldNumberOutlined,
} from '@ant-design/icons';
import { useRouter, useParams } from 'next/navigation';
import dayjs from 'dayjs';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';
import { buildTree } from '@/lib/tree-utils';
import { useSigning } from '@/hooks/use-signing';

const { TextArea } = Input;
const { DirectoryTree } = Tree;

// ===========================
// Types
// ===========================

// Fields match fn_handling_doc_get_by_id SP output exactly
interface HscvDetail {
  id: number;
  name: string;
  status: number;
  start_date: string;       // SP: start_date (was: open_date)
  end_date: string;         // SP: end_date (was: deadline)
  doc_field_id: number | null;   // SP: doc_field_id (was: field_id)
  doc_field_name: string | null; // SP: doc_field_name (was: field_name)
  doc_type_id: number | null;
  doc_type_name: string | null;
  workflow_id: number | null;    // SP: workflow_id (was: process_id)
  workflow_name: string | null;  // SP: workflow_name (was: process_name)
  curator_id: number | null;     // SP: curator_id (was: lead_staff_id)
  curator_name: string | null;   // SP: curator_name (was: lead_staff_name)
  signer_id: number | null;
  signer_name: string | null;
  progress: number;
  comments: string | null;
  abstract: string | null;
  parent_id: number | null;
  parent_name: string | null;
  created_at: string;
  created_by: number;
  unit_id: number;
  unit_name: string;
  department_id: number;
  department_name: string;
  // HDSD 3.2 — Lấy số (4 field từ fn_handling_doc_get_by_id)
  number?: number | null;
  sub_number?: string | null;
  doc_book_id?: number | null;
  doc_book_name?: string | null;
  // Gap D (HDSD III.2.5) — Hủy HSCV
  cancel_reason?: string | null;
  cancelled_at?: string | null;
  cancelled_by?: number | null;
}

interface LinkedDoc {
  id: number;
  link_id: number;
  doc_number: number | string;
  abstract: string;
  doc_type: string;
  doc_type_name?: string;
  signed_date?: string;
}

interface StaffItem {
  id: number;
  staff_id: number;
  staff_name: string;
  position_name: string;
  department_name: string;
  role: number;
  deadline: string | null;
}

interface AssignedStaff {
  staff_id: number;
  staff_name: string;
  position_name: string;
  department_name: string;
  role: number;
  deadline: dayjs.Dayjs | null;
}

interface AvailableStaff {
  staff_id: number;
  staff_name: string;
  position_name: string;
  checked: boolean;
}

interface Opinion {
  id: number;
  staff_id: number;
  staff_name: string;
  content: string;
  created_at: string;
  // Gap E (HDSD III.2.6) — Chuyển tiếp ý kiến
  forwarded_to_staff_id?: number | null;
  forwarded_to_name?: string | null;
  forwarded_at?: string | null;
  forward_note?: string | null;
  parent_opinion_id?: number | null;
}

// Gap F (HDSD III.2.7) — Lịch sử HSCV
interface HscvHistoryRow {
  id: number;
  handling_doc_id: number;
  action_type: string;
  from_staff_id: number | null;
  from_staff_name: string | null;
  to_staff_id: number | null;
  to_staff_name: string | null;
  note: string | null;
  created_by: number | null;
  created_by_name: string | null;
  created_at: string;
}

interface Attachment {
  id: number;
  file_name: string;
  file_size: number;
  file_type: string;
  created_at: string;
  created_by_name: string;
  // Phase 11 — Ký số (Plan 11-01 ALTER table attachments)
  is_ca?: boolean;
  ca_date?: string | null;
  signed_file_path?: string | null;
}

interface ChildHscv {
  id: number;
  name: string;
  status: number;
  start_date: string;    // SP: start_date (was: open_date)
  end_date: string;      // SP: end_date (was: deadline)
  progress: number;
  curator_name: string | null;  // SP: curator_name (was: lead_staff_name)
}

interface SearchDocItem {
  id: number;
  doc_number: number | string;
  abstract: string;
  doc_type_name?: string;
  signed_date?: string;
}

interface DeptNode {
  id: number;
  name: string;
  parent_id: number | null;
  children?: DeptNode[];
}

// ===========================
// Constants
// ===========================

const STATUS_MAP: Record<number, { text: string; color: string }> = {
  0: { text: 'Mới tạo', color: 'blue' },
  1: { text: 'Đang xử lý', color: 'processing' },
  2: { text: 'Chờ trình ký', color: 'orange' },
  3: { text: 'Đã trình ký', color: 'purple' },
  4: { text: 'Hoàn thành', color: 'success' },
  '-1': { text: 'Từ chối', color: 'error' },
  '-2': { text: 'Trả về', color: 'warning' },
  '-3': { text: 'Đã hủy', color: 'default' },
};

const AVATAR_COLORS = [
  '#1B3A5C', '#0891B2', '#059669', '#D97706', '#7C3AED',
  '#DC2626', '#2563EB', '#0F766E', '#9333EA', '#C2410C',
];

function getAvatarColor(id: number): string {
  return AVATAR_COLORS[id % AVATAR_COLORS.length];
}

function formatFileSize(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

function getFileIcon(fileName: string): React.ReactNode {
  const ext = fileName.split('.').pop()?.toLowerCase();
  if (ext === 'pdf') return <FilePdfOutlined style={{ color: '#DC2626', fontSize: 18 }} />;
  if (ext === 'doc' || ext === 'docx') return <FileWordOutlined style={{ color: '#2563EB', fontSize: 18 }} />;
  if (ext === 'xls' || ext === 'xlsx') return <FileExcelOutlined style={{ color: '#059669', fontSize: 18 }} />;
  if (ext === 'png' || ext === 'jpg' || ext === 'jpeg') return <FileImageOutlined style={{ color: '#D97706', fontSize: 18 }} />;
  return <FileOutlined style={{ color: '#64748B', fontSize: 18 }} />;
}

// ===========================
// Toolbar button config
// ===========================

interface ToolbarButton {
  label: string;
  type: 'primary' | 'default';
  danger?: boolean;
  ghost?: boolean;
  style?: React.CSSProperties;
  action: string;
  newStatus?: number;
}

function getToolbarButtons(status: number, hasNumber: boolean = true): ToolbarButton[] {
  // Gap F (HDSD III.2.7): "Chuyển tiếp HSCV" + "Lịch sử" dùng cho status 0-3 (đang xử lý)
  const transferBtn: ToolbarButton = { label: 'Chuyển tiếp HSCV', type: 'default', action: 'transfer' };
  const historyBtn: ToolbarButton = { label: 'Lịch sử', type: 'default', action: 'history' };
  switch (status) {
    case 0:
      return [
        { label: 'Chuyển xử lý', type: 'primary', action: 'change', newStatus: 1 },
        { label: 'Sửa', type: 'default', action: 'edit' },
        transferBtn,
        historyBtn,
        { label: 'Xóa', type: 'default', danger: true, ghost: true, action: 'delete' },
      ];
    case 1: {
      // HDSD 3.2 — Lấy số chỉ hiện khi HSCV chưa có số (number=null)
      const buttons: ToolbarButton[] = [
        { label: 'Trình ký', type: 'primary', action: 'submit' },
        { label: 'Cập nhật tiến độ', type: 'default', action: 'progress' },
      ];
      if (!hasNumber) {
        buttons.push({ label: 'Lấy số', type: 'default', action: 'get_number' });
      }
      buttons.push(transferBtn);
      buttons.push(historyBtn);
      // Status=5 (Tạm dừng) đã deprecated — bỏ nút "Tạm dừng" trong commit gỡ Option 2.
      // Khi cần ngưng tạm thời, user ghi note trong tab "Ý kiến xử lý" thay thế.
      return buttons;
    }
    case 2:
      // Status 2 đã deprecated (gộp Trình ký + Gửi trình ký thành 1 step trong commit
      // 260425-h7q). Giữ lại case này phòng dữ liệu cũ chưa migrate — cho phép đẩy
      // tiếp lên status=3 hoặc trả về.
      return [
        { label: 'Đẩy lên duyệt', type: 'primary', action: 'change', newStatus: 3 },
        { label: 'Trả về', type: 'default', action: 'return' },
        transferBtn,
        historyBtn,
      ];
    case 3: {
      // HDSD 3.2 — Lấy số cũng cho phép ở status=3 (Đã duyệt) nếu chưa có số
      const buttons: ToolbarButton[] = [
        { label: 'Duyệt hồ sơ', type: 'primary', action: 'approve', style: { backgroundColor: '#059669', borderColor: '#059669' } },
        { label: 'Từ chối', type: 'primary', danger: true, action: 'reject' },
        { label: 'Trả về', type: 'default', action: 'return' },
      ];
      if (!hasNumber) {
        buttons.push({ label: 'Lấy số', type: 'default', action: 'get_number' });
      }
      buttons.push(transferBtn);
      buttons.push(historyBtn);
      return buttons;
    }
    case 4:
      // HDSD 3.1 — Mở lại HSCV đã hoàn thành
      return [
        { label: 'Mở lại', type: 'primary', action: 'reopen' },
        { label: 'Xem lịch sử', type: 'default', action: 'history' },
      ];
    // case 5 (Tạm dừng) đã deprecated — không còn HSCV nào ở status này.
    // Status 5 vẫn giữ trong DB schema để không phá data cũ nếu có.
    case -1:
    case -2:
      return [
        { label: 'Xử lý lại', type: 'primary', action: 'change', newStatus: 1 },
        // Gap D (HDSD III.2.5) — Hủy HSCV: action riêng với lý do required
        { label: 'Hủy HSCV', type: 'default', danger: true, ghost: true, action: 'cancel' },
      ];
    default:
      return [];
  }
}

// ===========================
// Main component
// ===========================

export default function HscvDetailPage() {
  const { message, modal } = App.useApp();
  const router = useRouter();
  const params = useParams<{ id: string }>();
  const id = params.id;
  const user = useAuthStore((s) => s.user);

  // Phase 11 — Ký số HSCV (Plan 11-08): shared hook + SignModal
  const { openSign, renderSignModal } = useSigning();

  // Core state
  const [detail, setDetail] = useState<HscvDetail | null>(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('info');
  const [actionLoading, setActionLoading] = useState(false);

  // Tab-specific data
  const [linkedDocs, setLinkedDocs] = useState<LinkedDoc[]>([]);
  const [linkedDocsLoading, setLinkedDocsLoading] = useState(false);
  const [staffList, setStaffList] = useState<StaffItem[]>([]);
  const [staffLoading, setStaffLoading] = useState(false);
  const [opinions, setOpinions] = useState<Opinion[]>([]);
  const [opinionsLoading, setOpinionsLoading] = useState(false);
  const [attachments, setAttachments] = useState<Attachment[]>([]);
  const [attachmentsLoading, setAttachmentsLoading] = useState(false);
  const [children, setChildren] = useState<ChildHscv[]>([]);
  const [childrenLoading, setChildrenLoading] = useState(false);

  // Transfer panel state
  const [deptTreeData, setDeptTreeData] = useState<DataNode[]>([]);
  const [selectedDeptId, setSelectedDeptId] = useState<number | null>(null);
  const [availableStaff, setAvailableStaff] = useState<AvailableStaff[]>([]);
  const [availableStaffLoading, setAvailableStaffLoading] = useState(false);
  const [assignedStaff, setAssignedStaff] = useState<AssignedStaff[]>([]);
  const [savingAssignment, setSavingAssignment] = useState(false);

  // Opinion form
  const [opinionForm] = Form.useForm();
  const [sendingOpinion, setSendingOpinion] = useState(false);

  // Progress update modal
  const [progressModalOpen, setProgressModalOpen] = useState(false);
  const [progressValue, setProgressValue] = useState(0);
  const [updatingProgress, setUpdatingProgress] = useState(false);

  // HDSD 3.2 — Lấy số modal
  const [laySoOpen, setLaySoOpen] = useState(false);
  const [docBooks, setDocBooks] = useState<{ id: number; name: string; code?: string }[]>([]);
  const [selectedBookId, setSelectedBookId] = useState<number | null>(null);
  const [layingNumber, setLayingNumber] = useState(false);

  // Gap D (HDSD III.2.5) — Hủy HSCV
  const [cancelOpen, setCancelOpen] = useState(false);
  const [cancelReason, setCancelReason] = useState('');
  const [cancelling, setCancelling] = useState(false);

  // Gap E (HDSD III.2.6) — Chuyển tiếp ý kiến HSCV + staff picker (reuse cho Gap F)
  const [fwdOpen, setFwdOpen] = useState(false);
  const [fwdOpinionId, setFwdOpinionId] = useState<number | null>(null);
  const [fwdToStaffId, setFwdToStaffId] = useState<number | null>(null);
  const [fwdNote, setFwdNote] = useState('');
  const [fwdSubmitting, setFwdSubmitting] = useState(false);
  const [forwardStaffOptions, setForwardStaffOptions] = useState<{ value: number; label: string }[]>([]);

  // Gap F (HDSD III.2.7) — Chuyển tiếp HSCV (reuse forwardStaffOptions)
  const [transferOpen, setTransferOpen] = useState(false);
  const [transferToStaffId, setTransferToStaffId] = useState<number | null>(null);
  const [transferNote, setTransferNote] = useState('');
  const [transferring, setTransferring] = useState(false);

  // Gap F — Lịch sử HSCV
  const [historyOpen, setHistoryOpen] = useState(false);
  const [historyList, setHistoryList] = useState<HscvHistoryRow[]>([]);
  const [historyLoading, setHistoryLoading] = useState(false);

  // Edit drawer for HSCV details
  const [editDrawerOpen, setEditDrawerOpen] = useState(false);
  const [editForm] = Form.useForm();
  const [saving, setSaving] = useState(false);

  // Add linked doc modal
  const [addDocModalOpen, setAddDocModalOpen] = useState(false);
  const [searchDocTab, setSearchDocTab] = useState('den');
  const [searchDocKeyword, setSearchDocKeyword] = useState('');
  const [searchDocResults, setSearchDocResults] = useState<SearchDocItem[]>([]);
  const [searchDocLoading, setSearchDocLoading] = useState(false);
  const [selectedDocKeys, setSelectedDocKeys] = useState<number[]>([]);

  // Child HSCV drawer
  const [childDrawerOpen, setChildDrawerOpen] = useState(false);
  const [childForm] = Form.useForm();
  const [savingChild, setSavingChild] = useState(false);

  // Shared select options
  const [docTypes, setDocTypes] = useState<{ value: number; label: string }[]>([]);
  const [fields, setFields] = useState<{ value: number; label: string }[]>([]);
  const [staffOptions, setStaffOptions] = useState<{ value: number; label: string }[]>([]);
  const [leaderOptions, setLeaderOptions] = useState<{ value: number; label: string }[]>([]);

  const tabsLoaded = useRef<Set<string>>(new Set(['info']));

  // ===========================
  // Fetch core detail
  // ===========================

  const fetchDetail = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get(`/ho-so-cong-viec/${id}`);
      const rec = res.data;
      setDetail(rec);
      setProgressValue(rec.progress || 0);
    } catch {
      message.error('Không thể tải hồ sơ công việc. Kiểm tra kết nối mạng và thử lại.');
    } finally {
      setLoading(false);
    }
  }, [id, message]);

  useEffect(() => {
    fetchDetail();
  }, [fetchDetail]);

  // ===========================
  // Lazy tab data loading
  // ===========================

  const fetchLinkedDocs = useCallback(async () => {
    if (linkedDocsLoading) return;
    setLinkedDocsLoading(true);
    try {
      const { data: res } = await api.get(`/ho-so-cong-viec/${id}/van-ban-lien-ket`);
      setLinkedDocs(res.data || []);
    } catch {
      message.error('Lỗi tải văn bản liên kết');
    } finally {
      setLinkedDocsLoading(false);
    }
  }, [id, message, linkedDocsLoading]);

  const fetchStaffAndDepts = useCallback(async () => {
    if (staffLoading) return;
    setStaffLoading(true);
    try {
      const [staffRes, deptRes] = await Promise.all([
        api.get(`/ho-so-cong-viec/${id}/can-bo`),
        api.get('/quan-tri/don-vi/tree'),
      ]);

      const rawDeptList: DeptNode[] = deptRes.data.data || [];
      const tree = buildTree(rawDeptList);
      const toDataNode = (nodes: DeptNode[]): DataNode[] =>
        nodes.map((n) => ({
          key: n.id,
          title: n.name,
          children: n.children ? toDataNode(n.children) : undefined,
        }));
      setDeptTreeData(toDataNode(tree as DeptNode[]));

      const existingStaff: StaffItem[] = staffRes.data.data || [];
      setStaffList(existingStaff);
      setAssignedStaff(
        existingStaff.map((s) => ({
          staff_id: s.staff_id,
          staff_name: s.staff_name,
          position_name: s.position_name,
          department_name: s.department_name,
          role: s.role,
          deadline: s.deadline ? dayjs(s.deadline) : null,
        }))
      );
    } catch {
      message.error('Lỗi tải danh sách cán bộ');
    } finally {
      setStaffLoading(false);
    }
  }, [id, message, staffLoading]);

  const fetchOpinions = useCallback(async () => {
    if (opinionsLoading) return;
    setOpinionsLoading(true);
    try {
      const { data: res } = await api.get(`/ho-so-cong-viec/${id}/y-kien`);
      setOpinions(res.data || []);
    } catch {
      message.error('Lỗi tải ý kiến xử lý');
    } finally {
      setOpinionsLoading(false);
    }
  }, [id, message, opinionsLoading]);

  const fetchAttachments = useCallback(async () => {
    if (attachmentsLoading) return;
    setAttachmentsLoading(true);
    try {
      const { data: res } = await api.get(`/ho-so-cong-viec/${id}/dinh-kem`);
      setAttachments(res.data || []);
    } catch {
      message.error('Lỗi tải file đính kèm');
    } finally {
      setAttachmentsLoading(false);
    }
  }, [id, message, attachmentsLoading]);

  const fetchChildren = useCallback(async () => {
    if (childrenLoading) return;
    setChildrenLoading(true);
    try {
      const { data: res } = await api.get(`/ho-so-cong-viec/${id}/hscv-con`);
      setChildren(res.data || []);
    } catch {
      message.error('Lỗi tải hồ sơ con');
    } finally {
      setChildrenLoading(false);
    }
  }, [id, message, childrenLoading]);

  const handleTabChange = (tabKey: string) => {
    setActiveTab(tabKey);
    if (tabsLoaded.current.has(tabKey)) return;
    tabsLoaded.current.add(tabKey);
    if (tabKey === 'linked-docs') fetchLinkedDocs();
    if (tabKey === 'staff') fetchStaffAndDepts();
    if (tabKey === 'opinions') fetchOpinions();
    if (tabKey === 'attachments') fetchAttachments();
    if (tabKey === 'children') fetchChildren();
  };

  // ===========================
  // Status transition handlers
  // ===========================

  const handleStatusChange = useCallback(
    async (action: string, newStatus?: number, reason?: string) => {
      setActionLoading(true);
      try {
        await api.patch(`/ho-so-cong-viec/${id}/trang-thai`, { action, new_status: newStatus, reason });
        message.success('Cập nhật trạng thái thành công');
        await fetchDetail();
        // Reload staff tab if assigned
        if (tabsLoaded.current.has('staff')) {
          tabsLoaded.current.delete('staff');
        }
      } catch (err: any) {
        message.error(err?.response?.data?.message || 'Cập nhật trạng thái thất bại');
      } finally {
        setActionLoading(false);
      }
    },
    [id, message, fetchDetail]
  );

  // State-based modals cho Tu choi / Tra ve — required validation, OK button
  // disabled khi chua nhap ly do. Tranh hack Promise.reject + runtime error.
  const [rejectModalOpen, setRejectModalOpen] = useState(false);
  const [rejectReason, setRejectReason] = useState('');
  const [returnModalOpen, setReturnModalOpen] = useState(false);
  const [returnReason, setReturnReason] = useState('');

  const handleReject = () => {
    setRejectReason('');
    setRejectModalOpen(true);
  };

  const submitReject = async () => {
    const trimmed = rejectReason.trim();
    if (!trimmed) return; // OK button da disabled, defensive
    await handleStatusChange('reject', undefined, trimmed);
    setRejectModalOpen(false);
  };

  const handleReturn = () => {
    setReturnReason('');
    setReturnModalOpen(true);
  };

  const submitReturn = async () => {
    const trimmed = returnReason.trim();
    if (!trimmed) return;
    await handleStatusChange('return', undefined, trimmed);
    setReturnModalOpen(false);
  };

  const handleDelete = () => {
    modal.confirm({
      title: 'Xóa hồ sơ',
      icon: <ExclamationCircleOutlined />,
      content: 'Bạn có chắc muốn xóa hồ sơ này? Hành động này không thể hoàn tác.',
      okText: 'Xóa',
      okType: 'danger',
      cancelText: 'Hủy bỏ',
      onOk: async () => {
        try {
          await api.delete(`/ho-so-cong-viec/${id}`);
          message.success('Xóa hồ sơ thành công');
          router.push('/ho-so-cong-viec');
        } catch (err: any) {
          message.error(err?.response?.data?.message || 'Xóa hồ sơ thất bại');
        }
      },
    });
  };

  const handleToolbarAction = (btn: ToolbarButton) => {
    if (btn.action === 'delete') { handleDelete(); return; }
    if (btn.action === 'reject') { handleReject(); return; }
    if (btn.action === 'return') { handleReturn(); return; }
    if (btn.action === 'edit') { openEditDrawer(); return; }
    if (btn.action === 'progress') { setProgressModalOpen(true); return; }
    if (btn.action === 'history') { openHistory(); return; }
    // Gap F (HDSD III.2.7) — Chuyển tiếp HSCV
    if (btn.action === 'transfer') { openTransfer(); return; }
    if (btn.action === 'submit') { handleStatusChange('submit'); return; }
    if (btn.action === 'approve') { handleStatusChange('approve'); return; }
    if (btn.action === 'reopen') { handleReopen(); return; }
    if (btn.action === 'get_number') { handleLaySo(); return; }
    // Gap D (HDSD III.2.5) — Hủy HSCV với lý do required
    if (btn.action === 'cancel') { setCancelReason(''); setCancelOpen(true); return; }
    if (btn.action === 'change' && btn.newStatus !== undefined) {
      handleStatusChange('change', btn.newStatus);
    }
  };

  // ===========================
  // Update progress
  // ===========================

  const handleUpdateProgress = async () => {
    setUpdatingProgress(true);
    try {
      await api.patch(`/ho-so-cong-viec/${id}/tien-do`, { progress: progressValue });
      message.success('Cập nhật tiến độ thành công');
      setProgressModalOpen(false);
      await fetchDetail();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Cập nhật tiến độ thất bại');
    } finally {
      setUpdatingProgress(false);
    }
  };

  // ===========================
  // HDSD 3.1 — Mở lại HSCV (status=4 → 1, GIỮ progress=100)
  // ===========================

  const handleReopen = () => {
    modal.confirm({
      title: 'Mở lại hồ sơ công việc?',
      content: 'Trạng thái sẽ chuyển từ "Hoàn thành" về "Đang xử lý" (giữ nguyên tiến độ 100%). Bạn xác nhận?',
      okText: 'Mở lại',
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          const { data: res } = await api.post(`/ho-so-cong-viec/${id}/mo-lai`);
          message.success(res?.message || 'Đã mở lại hồ sơ công việc');
          await fetchDetail();
        } catch (err: any) {
          message.error(err?.response?.data?.message || 'Thao tác thất bại');
        }
      },
    });
  };

  // Gap E (HDSD III.2.6) — Fetch staff cùng đơn vị (reuse cho Gap F)
  const fetchStaffForForward = async () => {
    try {
      const { data: res } = await api.get('/ho-so-cong-viec/nhan-vien-cung-don-vi');
      const list = res?.data || [];
      setForwardStaffOptions(list.map((s: { id: number; full_name: string }) => ({ value: s.id, label: s.full_name })));
    } catch {
      setForwardStaffOptions([]);
    }
  };

  const openForwardOpinion = (opinionId: number) => {
    setFwdOpinionId(opinionId);
    setFwdToStaffId(null);
    setFwdNote('');
    fetchStaffForForward();
    setFwdOpen(true);
  };

  const handleForwardOpinion = async () => {
    if (!fwdOpinionId) return;
    if (!fwdToStaffId) {
      message.warning('Vui lòng chọn người nhận');
      return;
    }
    if (!fwdNote.trim()) {
      message.warning('Vui lòng nhập nội dung chuyển tiếp');
      return;
    }
    setFwdSubmitting(true);
    try {
      const { data: res } = await api.post(
        `/ho-so-cong-viec/${id}/y-kien/${fwdOpinionId}/chuyen-tiep`,
        { to_staff_id: fwdToStaffId, note: fwdNote.trim() },
      );
      message.success(res?.message || 'Đã chuyển tiếp ý kiến');
      setFwdOpen(false);
      await fetchOpinions();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Chuyển tiếp thất bại');
    } finally {
      setFwdSubmitting(false);
    }
  };

  // Gap F (HDSD III.2.7) — Chuyển tiếp HSCV
  const openTransfer = () => {
    setTransferToStaffId(null);
    setTransferNote('');
    fetchStaffForForward();
    setTransferOpen(true);
  };
  const handleTransfer = async () => {
    if (!transferToStaffId) {
      message.warning('Vui lòng chọn người nhận');
      return;
    }
    setTransferring(true);
    try {
      const { data: res } = await api.post(`/ho-so-cong-viec/${id}/chuyen-tiep`, {
        to_staff_id: transferToStaffId,
        note: transferNote.trim(),
      });
      message.success(res?.message || 'Đã chuyển tiếp HSCV');
      setTransferOpen(false);
      await fetchDetail();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Chuyển tiếp thất bại');
    } finally {
      setTransferring(false);
    }
  };

  // Gap F — Fetch lịch sử HSCV
  const fetchHistory = async () => {
    setHistoryLoading(true);
    try {
      const { data: res } = await api.get(`/ho-so-cong-viec/${id}/lich-su`);
      setHistoryList(res?.data || []);
    } catch {
      setHistoryList([]);
    } finally {
      setHistoryLoading(false);
    }
  };
  const openHistory = () => {
    fetchHistory();
    setHistoryOpen(true);
  };

  // Gap D (HDSD III.2.5) — Hủy HSCV với lý do
  const handleCancel = async () => {
    if (!cancelReason.trim()) {
      message.warning('Vui lòng nhập lý do hủy');
      return;
    }
    setCancelling(true);
    try {
      const { data: res } = await api.post(`/ho-so-cong-viec/${id}/huy`, { reason: cancelReason.trim() });
      message.success(res?.message || 'Đã hủy HSCV');
      setCancelOpen(false);
      setCancelReason('');
      await fetchDetail();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Hủy thất bại');
    } finally {
      setCancelling(false);
    }
  };

  // ===========================
  // HDSD 3.2 — Lấy số HSCV
  // ===========================

  const handleLaySo = async () => {
    // Nếu HSCV đã có doc_book_id → confirm dùng luôn sổ đã chọn
    if (detail?.doc_book_id) {
      modal.confirm({
        title: 'Lấy số văn bản?',
        content: `Sẽ cấp số kế tiếp theo sổ "${detail.doc_book_name || '#' + detail.doc_book_id}". Bạn xác nhận?`,
        okText: 'Lấy số',
        cancelText: 'Hủy',
        onOk: async () => {
          try {
            const { data: res } = await api.post(
              `/ho-so-cong-viec/${id}/lay-so`,
              { doc_book_id: detail.doc_book_id },
            );
            message.success(res?.message || `Đã lấy số ${res?.number}`);
            await fetchDetail();
          } catch (err: any) {
            message.error(err?.response?.data?.message || 'Thao tác thất bại');
          }
        },
      });
      return;
    }

    // Chưa có sổ → mở Modal Select
    try {
      const { data: res } = await api.get('/quan-tri/so-van-ban', { params: { pageSize: 1000 } });
      setDocBooks(res?.data || res?.items || []);
      setSelectedBookId(null);
      setLaySoOpen(true);
    } catch {
      message.error('Không tải được danh sách sổ văn bản');
    }
  };

  const handleConfirmLaySo = async () => {
    if (!selectedBookId) {
      message.warning('Vui lòng chọn sổ văn bản');
      return;
    }
    setLayingNumber(true);
    try {
      const { data: res } = await api.post(
        `/ho-so-cong-viec/${id}/lay-so`,
        { doc_book_id: selectedBookId },
      );
      message.success(res?.message || `Đã lấy số ${res?.number}`);
      setLaySoOpen(false);
      await fetchDetail();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Thao tác thất bại');
    } finally {
      setLayingNumber(false);
    }
  };

  // ===========================
  // Edit HSCV drawer
  // ===========================

  const openEditDrawer = () => {
    if (!detail) return;
    editForm.setFieldsValue({
      name: detail.name,
      doc_field_id: detail.doc_field_id,
      doc_type_id: detail.doc_type_id,
      start_date: detail.start_date ? dayjs(detail.start_date) : null,
      end_date: detail.end_date ? dayjs(detail.end_date) : null,
      comments: detail.comments,
      curator_id: detail.curator_id,
      signer_id: detail.signer_id,
    });
    setEditDrawerOpen(true);
    // Load options if not yet loaded
    if (docTypes.length === 0) {
      api.get('/quan-tri/loai-van-ban/tree').then(({ data: r }) => {
        setDocTypes((r.data || []).map((x: any) => ({ value: x.id, label: x.name })));
      }).catch(() => {});
    }
    if (fields.length === 0) {
      api.get('/quan-tri/linh-vuc').then(({ data: r }) => {
        setFields((r.data || []).map((x: any) => ({ value: x.id, label: x.name })));
      }).catch(() => {});
    }
    if (staffOptions.length === 0) {
      // Curator: tat ca staff cung don vi
      api.get('/ho-so-cong-viec/nhan-vien-cung-don-vi').then(({ data: r }) => {
        const items: { id: number; full_name: string }[] = r.data || [];
        setStaffOptions(items.map((x) => ({ value: x.id, label: x.full_name })));
      }).catch(() => {});
      // Signer: chi nhung nguoi admin da dang ky lam "Nguoi ky" cho don vi
      // (theo pattern .NET cu Prc_StaffGetSignerByUnitId — bang edoc.signers)
      api.get('/ho-so-cong-viec/lanh-dao-cung-don-vi').then(({ data: r }) => {
        const items: { staff_id: number; staff_name: string }[] = r.data || [];
        setLeaderOptions(items.map((x) => ({ value: x.staff_id, label: x.staff_name })));
      }).catch(() => {});
    }
  };

  const handleEditSave = async () => {
    try {
      const values = await editForm.validateFields();
      setSaving(true);
      await api.put(`/ho-so-cong-viec/${id}`, {
        ...values,
        start_date: values.start_date?.toISOString(),
        end_date: values.end_date?.toISOString(),
      });
      message.success('Lưu hồ sơ thành công');
      setEditDrawerOpen(false);
      await fetchDetail();
    } catch (err: any) {
      if (err?.errorFields) return;
      message.error(err?.response?.data?.message || 'Lưu hồ sơ thất bại. Vui lòng kiểm tra lại thông tin và thử lại.');
    } finally {
      setSaving(false);
    }
  };

  // ===========================
  // Linked docs
  // ===========================

  const handleSearchDocs = async () => {
    setSearchDocLoading(true);
    try {
      const endpoint = searchDocTab === 'den' ? '/van-ban-den'
        : searchDocTab === 'di' ? '/van-ban-di'
        : '/van-ban-du-thao';
      const { data: res } = await api.get(endpoint, {
        params: { keyword: searchDocKeyword, page: 1, page_size: 20 },
      });
      setSearchDocResults((res.data || []).map((x: any) => ({
        id: x.id,
        doc_number: x.document_code || x.doc_number || x.number || '',
        abstract: x.abstract || '',
        doc_type_name: x.doc_type_name || '',
        signed_date: x.sign_date || x.signed_date || x.created_at || '',
      })));
    } catch {
      message.error('Lỗi tìm kiếm văn bản');
    } finally {
      setSearchDocLoading(false);
    }
  };

  const handleAddLinkedDocs = async () => {
    if (selectedDocKeys.length === 0) {
      message.warning('Vui lòng chọn ít nhất một văn bản');
      return;
    }
    try {
      await Promise.all(
        selectedDocKeys.map((docId) =>
          api.post(`/ho-so-cong-viec/${id}/lien-ket-van-ban`, {
            doc_id: docId,
            doc_type: searchDocTab,
          })
        )
      );
      message.success('Liên kết văn bản thành công');
      setAddDocModalOpen(false);
      setSelectedDocKeys([]);
      setSearchDocResults([]);
      await fetchLinkedDocs();
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi liên kết văn bản');
    }
  };

  const handleUnlinkDoc = async (linkId: number) => {
    try {
      await api.delete(`/ho-so-cong-viec/${id}/lien-ket-van-ban/${linkId}`);
      message.success('Đã gỡ liên kết văn bản');
      setLinkedDocs((prev) => prev.filter((d) => d.link_id !== linkId));
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi gỡ liên kết');
    }
  };

  // ===========================
  // Staff transfer panel
  // ===========================

  const handleDeptSelect = async (selectedKeys: React.Key[]) => {
    if (!selectedKeys.length) return;
    const deptId = selectedKeys[0] as number;
    setSelectedDeptId(deptId);
    setAvailableStaffLoading(true);
    try {
      const { data: res } = await api.get(`/quan-tri/don-vi/${deptId}/nhan-vien`);
      const assigned = new Set(assignedStaff.map((s) => s.staff_id));
      setAvailableStaff(
        (res.data || []).map((s: any) => ({
          staff_id: s.id || s.staff_id,
          staff_name: s.staff_name || s.full_name,
          position_name: s.position_name || '',
          checked: false,
          alreadyAdded: assigned.has(s.id || s.staff_id),
        }))
      );
    } catch {
      message.error('Lỗi tải danh sách nhân viên');
    } finally {
      setAvailableStaffLoading(false);
    }
  };

  const handleAddToAssigned = () => {
    const checked = availableStaff.filter((s) => s.checked);
    if (!checked.length) { message.warning('Vui lòng chọn cán bộ cần thêm'); return; }
    const existing = new Set(assignedStaff.map((s) => s.staff_id));
    const toAdd = checked
      .filter((s) => !existing.has(s.staff_id))
      .map((s) => ({
        staff_id: s.staff_id,
        staff_name: s.staff_name,
        position_name: s.position_name,
        department_name: '',
        role: 2,
        deadline: null,
      }));
    if (!toAdd.length) { message.info('Các cán bộ đã được phân công rồi'); return; }
    setAssignedStaff((prev) => [...prev, ...toAdd]);
    setAvailableStaff((prev) => prev.map((s) => ({ ...s, checked: false })));
  };

  const handleRemoveAssigned = (staffId: number) => {
    setAssignedStaff((prev) => prev.filter((s) => s.staff_id !== staffId));
  };

  const handleSaveAssignment = async () => {
    if (!assignedStaff.length) { message.warning('Chưa có cán bộ nào được phân công'); return; }
    setSavingAssignment(true);
    try {
      await api.post(`/ho-so-cong-viec/${id}/phan-cong`, {
        staff: assignedStaff.map((s) => ({
          staff_id: s.staff_id,
          role: s.role,
          deadline: s.deadline?.toISOString() || null,
        })),
      });
      message.success('Phân công cán bộ thành công');
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi phân công cán bộ');
    } finally {
      setSavingAssignment(false);
    }
  };

  // ===========================
  // Opinions
  // ===========================

  const handleSendOpinion = async () => {
    try {
      const values = await opinionForm.validateFields();
      setSendingOpinion(true);
      await api.post(`/ho-so-cong-viec/${id}/y-kien`, { content: values.content });
      message.success('Gửi ý kiến thành công');
      opinionForm.resetFields();
      // Refresh opinions
      const { data: res } = await api.get(`/ho-so-cong-viec/${id}/y-kien`);
      setOpinions(res.data || []);
    } catch (err: any) {
      if (err?.errorFields) return;
      message.error(err?.response?.data?.message || 'Gửi ý kiến thất bại');
    } finally {
      setSendingOpinion(false);
    }
  };

  // ===========================
  // Attachments
  // ===========================

  const handleUpload = async (options: UploadRequestOption) => {
    const { file, onSuccess, onError } = options;
    const formData = new FormData();
    formData.append('file', file as File);
    try {
      const { data: res } = await api.post(`/ho-so-cong-viec/${id}/dinh-kem`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      onSuccess?.(res);
      message.success('Tải lên file thành công');
      const { data: listRes } = await api.get(`/ho-so-cong-viec/${id}/dinh-kem`);
      setAttachments(listRes.data || []);
    } catch (err: any) {
      onError?.(err);
      message.error('Tải lên file thất bại');
    }
  };

  const handleDownload = async (attachmentId: number, fileName: string) => {
    try {
      const { data: res } = await api.get(`/ho-so-cong-viec/${id}/dinh-kem/${attachmentId}/download`);
      window.open(res.data.url, '_blank');
    } catch {
      message.error(`Không thể tải xuống file "${fileName}"`);
    }
  };

  const handleDeleteAttachment = async (attachmentId: number) => {
    try {
      await api.delete(`/ho-so-cong-viec/${id}/dinh-kem/${attachmentId}`);
      message.success('Đã xóa file');
      setAttachments((prev) => prev.filter((a) => a.id !== attachmentId));
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Xóa file thất bại');
    }
  };

  // ===========================
  // Child HSCV drawer
  // ===========================

  const handleCreateChild = () => {
    childForm.resetFields();
    childForm.setFieldsValue({ parent_id: detail?.id, parent_name: detail?.name });
    setChildDrawerOpen(true);
    if (staffOptions.length === 0) {
      // Curator: tat ca staff cung don vi
      api.get('/ho-so-cong-viec/nhan-vien-cung-don-vi').then(({ data: r }) => {
        const items: { id: number; full_name: string }[] = r.data || [];
        setStaffOptions(items.map((x) => ({ value: x.id, label: x.full_name })));
      }).catch(() => {});
      // Signer: chi nhung nguoi admin da dang ky lam "Nguoi ky" cho don vi
      // (theo pattern .NET cu Prc_StaffGetSignerByUnitId — bang edoc.signers)
      api.get('/ho-so-cong-viec/lanh-dao-cung-don-vi').then(({ data: r }) => {
        const items: { staff_id: number; staff_name: string }[] = r.data || [];
        setLeaderOptions(items.map((x) => ({ value: x.staff_id, label: x.staff_name })));
      }).catch(() => {});
    }
  };

  const handleSaveChild = async () => {
    try {
      const values = await childForm.validateFields();
      setSavingChild(true);
      await api.post('/ho-so-cong-viec', {
        ...values,
        parent_id: detail?.id,
        start_date: values.start_date?.toISOString(),
        end_date: values.end_date?.toISOString(),
      });
      message.success('Tạo hồ sơ con thành công');
      setChildDrawerOpen(false);
      // Refresh children tab
      const { data: res } = await api.get(`/ho-so-cong-viec/${id}/hscv-con`);
      setChildren(res.data || []);
    } catch (err: any) {
      if (err?.errorFields) return;
      message.error(err?.response?.data?.message || 'Tạo hồ sơ thất bại');
    } finally {
      setSavingChild(false);
    }
  };

  // ===========================
  // Table columns
  // ===========================

  const linkedDocsColumns: ColumnsType<LinkedDoc> = [
    { title: 'Số VB', dataIndex: 'doc_number', width: 120 },
    { title: 'Trích yếu', dataIndex: 'abstract', ellipsis: true },
    {
      title: 'Loại',
      dataIndex: 'doc_type_name',
      width: 130,
      render: (v: string) => v ? <Tag color="blue">{v}</Tag> : '-',
    },
    {
      title: 'Ngày ký',
      dataIndex: 'signed_date',
      width: 110,
      render: (v: string) => v ? dayjs(v).format('DD/MM/YYYY') : '-',
    },
    {
      title: 'Thao tác',
      width: 110,
      render: (_: unknown, record: LinkedDoc) => (
        <Popconfirm
          title="Gỡ liên kết văn bản này?"
          okText="Gỡ"
          cancelText="Hủy bỏ"
          okType="danger"
          onConfirm={() => handleUnlinkDoc(record.link_id)}
        >
          <Button type="link" danger size="small">Gỡ liên kết</Button>
        </Popconfirm>
      ),
    },
  ];

  const childrenColumns: ColumnsType<ChildHscv> = [
    {
      title: 'Tên hồ sơ',
      dataIndex: 'name',
      render: (v: string, record: ChildHscv) => (
        <Button
          type="link"
          style={{ padding: 0, fontWeight: 500, color: '#1B3A5C' }}
          onClick={() => router.push(`/ho-so-cong-viec/${record.id}`)}
        >
          {v}
        </Button>
      ),
    },
    {
      title: 'Ngày mở',
      dataIndex: 'start_date',
      width: 110,
      render: (v: string) => v ? dayjs(v).format('DD/MM/YYYY') : '-',
    },
    {
      title: 'Hạn giải quyết',
      dataIndex: 'end_date',
      width: 130,
      render: (v: string) => {
        if (!v) return '-';
        const isOverdue = dayjs(v).isBefore(dayjs(), 'day');
        return (
          <span style={{ color: isOverdue ? '#DC2626' : undefined }}>
            {isOverdue && <ExclamationCircleOutlined style={{ marginRight: 4 }} />}
            {dayjs(v).format('DD/MM/YYYY')}
          </span>
        );
      },
    },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      width: 130,
      render: (v: number) => {
        const s = STATUS_MAP[v] || STATUS_MAP[String(v) as unknown as number];
        return s ? <Tag color={s.color}>{s.text}</Tag> : <Tag>{v}</Tag>;
      },
    },
    {
      title: 'Tiến độ',
      dataIndex: 'progress',
      width: 140,
      render: (v: number) => (
        <Progress percent={v || 0} size="small" strokeColor="#0891B2" />
      ),
    },
  ];

  // ===========================
  // Render
  // ===========================

  if (loading) {
    return (
      <div>
        <Skeleton active paragraph={{ rows: 2 }} style={{ marginBottom: 16 }} />
        <Skeleton active paragraph={{ rows: 6 }} />
      </div>
    );
  }

  if (!detail) {
    return (
      <div className="empty-center">
        <p>Không tìm thấy hồ sơ công việc</p>
        <Button onClick={() => router.push('/ho-so-cong-viec')}>Quay lại danh sách</Button>
      </div>
    );
  }

  const statusInfo = STATUS_MAP[detail.status] || STATUS_MAP[String(detail.status) as unknown as number] || { text: 'Không xác định', color: 'default' };
  // HDSD 3.2 — pass hasNumber để getToolbarButtons quyết định hiện nút "Lấy số"
  const toolbarButtons = getToolbarButtons(detail.status, detail.number != null);

  // Phase 11 — Ký số gate (Plan 11-08).
  // UX gating only — backend fn_attachment_can_sign (Plan 11-01) is authoritative ACL.
  // Shown ONLY khi: current user là signer được chỉ định + HSCV đang "Chờ trình ký" (2) hoặc "Đã trình ký" (3).
  const canSignHandling = Boolean(
    detail &&
    user?.staffId &&
    detail.signer_id === user.staffId &&
    [2, 3].includes(detail.status)
  );

  const tabItems = [
    {
      key: 'info',
      label: <span><FolderOutlined /> Thông tin chung</span>,
      children: (
        <div>
          <p className="section-title" style={{ marginBottom: 12 }}>Thông tin hồ sơ</p>
          <div className="info-grid" style={{ marginBottom: 16 }}>
            <div>
              <div className="info-label">Ngày mở</div>
              <div className="info-value">
                {detail.start_date ? dayjs(detail.start_date).format('DD/MM/YYYY') : '—'}
              </div>
            </div>
            <div>
              <div className="info-label">Hạn giải quyết</div>
              <div className="info-value" style={{
                color: detail.end_date && dayjs(detail.end_date).isBefore(dayjs(), 'day') ? '#DC2626' : undefined,
              }}>
                {detail.end_date ? dayjs(detail.end_date).format('DD/MM/YYYY') : '—'}
              </div>
            </div>
            <div>
              <div className="info-label">Lĩnh vực</div>
              <div className="info-value">{detail.doc_field_name || '—'}</div>
            </div>
            <div>
              <div className="info-label">Loại văn bản</div>
              <div className="info-value">{detail.doc_type_name || '—'}</div>
            </div>
            <div>
              <div className="info-label">Quy trình</div>
              <div className="info-value">{detail.workflow_name || '—'}</div>
            </div>
            <div>
              <div className="info-label">Trạng thái</div>
              <div className="info-value">
                <Tag color={statusInfo.color}>{statusInfo.text}</Tag>
              </div>
            </div>
            <div>
              <div className="info-label">Người phụ trách</div>
              <div className="info-value">{detail.curator_name || '—'}</div>
            </div>
            <div>
              <div className="info-label">Lãnh đạo ký</div>
              <div className="info-value">{detail.signer_name || '—'}</div>
            </div>
          </div>
          <div style={{ marginBottom: 16 }}>
            <div className="info-label" style={{ marginBottom: 8 }}>Tiến độ</div>
            <Progress
              percent={detail.progress || 0}
              strokeColor="#0891B2"
              style={{ maxWidth: 400 }}
            />
          </div>
          {detail.comments && (
            <div>
              <p className="section-title" style={{ marginBottom: 8 }}>Ghi chú</p>
              <div className="doc-abstract-box">{detail.comments}</div>
            </div>
          )}
          {/* Gap D (HDSD III.2.5) — Thông tin hủy khi status=-3 */}
          {detail.status === -3 && detail.cancel_reason && (
            <div style={{ marginTop: 12, padding: 12, background: '#FEF2F2', border: '1px solid #FCA5A5', borderRadius: 8 }}>
              <p className="section-title" style={{ marginBottom: 8, color: '#B91C1C' }}>Thông tin hủy</p>
              <div style={{ fontSize: 13, lineHeight: 1.8 }}>
                <div><strong>Lý do:</strong> {detail.cancel_reason}</div>
                {detail.cancelled_at && <div><strong>Thời điểm:</strong> {dayjs(detail.cancelled_at).format('DD/MM/YYYY HH:mm')}</div>}
                {detail.cancelled_by && <div><strong>Người hủy:</strong> ID {detail.cancelled_by}</div>}
              </div>
            </div>
          )}
          {detail.parent_name && (
            <div style={{ marginTop: 8 }}>
              <div className="info-label">HSCV cha</div>
              <div className="info-value">
                <Button
                  type="link"
                  style={{ padding: 0, color: '#0891B2' }}
                  onClick={() => router.push(`/ho-so-cong-viec/${detail.parent_id}`)}
                >
                  {detail.parent_name}
                </Button>
              </div>
            </div>
          )}
        </div>
      ),
    },
    {
      key: 'linked-docs',
      label: <span><FileTextOutlined /> Văn bản liên kết</span>,
      children: (
        <div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 12 }}>
            <Space>
              <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Văn bản liên kết</span>
              <Badge count={linkedDocs.length} style={{ backgroundColor: '#0891B2' }} />
            </Space>
            <Button
              type="primary"
              ghost
              icon={<LinkOutlined />}
              onClick={() => {
                setAddDocModalOpen(true);
                setSearchDocResults([]);
                setSelectedDocKeys([]);
                setSearchDocKeyword('');
              }}
            >
              Thêm văn bản
            </Button>
          </div>
          <Table
            columns={linkedDocsColumns}
            dataSource={linkedDocs}
            rowKey="link_id"
            loading={linkedDocsLoading}
            size="small"
            locale={{
              emptyText: (
                <div className="empty-center">
                  Chưa có văn bản liên kết. Nhấn &quot;Thêm văn bản&quot; để liên kết văn bản đến/đi/dự thảo.
                </div>
              ),
            }}
            pagination={false}
          />
        </div>
      ),
    },
    {
      key: 'staff',
      label: <span><TeamOutlined /> Cán bộ xử lý</span>,
      children: (
        <div>
          {staffLoading ? (
            <Skeleton active paragraph={{ rows: 6 }} />
          ) : (
            <>
              <div className="transfer-panel">
                {/* Left: Department tree + staff list */}
                <div className="transfer-panel-left">
                  <div style={{ fontWeight: 600, color: '#1B3A5C', marginBottom: 8, fontSize: 13 }}>
                    Chọn đơn vị
                  </div>
                  <DirectoryTree
                    treeData={deptTreeData}
                    onSelect={handleDeptSelect}
                    style={{ marginBottom: 12 }}
                  />
                  {selectedDeptId && (
                    <>
                      <Divider style={{ margin: '8px 0' }} />
                      <div style={{ fontWeight: 600, color: '#1B3A5C', marginBottom: 8, fontSize: 13 }}>
                        Danh sách cán bộ
                      </div>
                      {availableStaffLoading ? (
                        <Skeleton active paragraph={{ rows: 3 }} />
                      ) : (
                        availableStaff.map((s) => (
                          <div key={s.staff_id} className="staff-assign-row">
                            <Checkbox
                              checked={s.checked}
                              onChange={(e) =>
                                setAvailableStaff((prev) =>
                                  prev.map((x) =>
                                    x.staff_id === s.staff_id ? { ...x, checked: e.target.checked } : x
                                  )
                                )
                              }
                            />
                            <div style={{ flex: 1 }}>
                              <div style={{ fontWeight: 500, fontSize: 13 }}>{s.staff_name}</div>
                              <div style={{ fontSize: 11, color: '#64748B' }}>{s.position_name}</div>
                            </div>
                          </div>
                        ))
                      )}
                    </>
                  )}
                </div>

                {/* Middle: actions */}
                <div className="transfer-panel-actions">
                  <Button
                    type="primary"
                    size="small"
                    onClick={handleAddToAssigned}
                  >
                    Thêm &gt;&gt;
                  </Button>
                </div>

                {/* Right: assigned staff */}
                <div className="transfer-panel-right">
                  <div style={{ fontWeight: 600, color: '#1B3A5C', marginBottom: 8, fontSize: 13 }}>
                    Cán bộ được phân công ({assignedStaff.length})
                  </div>
                  {assignedStaff.length === 0 ? (
                    <div className="empty-center" style={{ padding: '24px 0' }}>
                      Chưa có cán bộ nào được phân công
                    </div>
                  ) : (
                    assignedStaff.map((s) => (
                      <div key={s.staff_id} className="staff-assign-row" style={{ flexDirection: 'column', alignItems: 'flex-start', gap: 6 }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', width: '100%' }}>
                          <div>
                            <span style={{ fontWeight: 500, fontSize: 13 }}>{s.staff_name}</span>
                            {s.position_name && (
                              <span style={{ fontSize: 11, color: '#64748B', marginLeft: 6 }}>
                                {s.position_name}
                              </span>
                            )}
                          </div>
                          <Button
                            type="text"
                            danger
                            size="small"
                            icon={<DeleteOutlined />}
                            onClick={() => handleRemoveAssigned(s.staff_id)}
                          />
                        </div>
                        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                          <Radio.Group
                            size="small"
                            value={s.role}
                            onChange={(e) =>
                              setAssignedStaff((prev) =>
                                prev.map((x) =>
                                  x.staff_id === s.staff_id ? { ...x, role: e.target.value } : x
                                )
                              )
                            }
                          >
                            <Radio value={1}>
                              <span style={{ color: '#059669', fontWeight: 500 }}>Phụ trách</span>
                            </Radio>
                            <Radio value={2}>
                              <span style={{ color: '#0891B2', fontWeight: 500 }}>Phối hợp</span>
                            </Radio>
                          </Radio.Group>
                          <DatePicker
                            size="small"
                            placeholder="Hạn xử lý"
                            value={s.deadline}
                            format="DD/MM/YYYY"
                            onChange={(date) =>
                              setAssignedStaff((prev) =>
                                prev.map((x) =>
                                  x.staff_id === s.staff_id ? { ...x, deadline: date } : x
                                )
                              )
                            }
                          />
                        </div>
                      </div>
                    ))
                  )}
                </div>
              </div>
              <div style={{ marginTop: 16, textAlign: 'right' }}>
                <Button
                  type="primary"
                  icon={<SaveOutlined />}
                  loading={savingAssignment}
                  onClick={handleSaveAssignment}
                >
                  Lưu phân công
                </Button>
              </div>
            </>
          )}
        </div>
      ),
    },
    {
      key: 'opinions',
      label: <span><CommentOutlined /> Ý kiến xử lý</span>,
      children: (
        <div>
          {opinionsLoading ? (
            <Skeleton active paragraph={{ rows: 4 }} />
          ) : (
            <>
              {opinions.length === 0 ? (
                <div className="empty-center">
                  Chưa có ý kiến xử lý. Hãy là người đầu tiên thêm ý kiến.
                </div>
              ) : (
                <>
                  {opinions.map((item) => (
                    <div
                      key={item.id}
                      className="opinion-item"
                      style={item.parent_opinion_id ? {
                        marginLeft: 32,
                        borderLeft: '2px solid #E5E7EB',
                        paddingLeft: 12,
                      } : undefined}
                    >
                      <Avatar
                        size={32}
                        style={{ backgroundColor: getAvatarColor(item.staff_id), flexShrink: 0 }}
                      >
                        {item.staff_name?.charAt(0)?.toUpperCase() || '?'}
                      </Avatar>
                      <div className="opinion-item-content">
                        <div className="opinion-item-header">
                          <span className="opinion-item-name">{item.staff_name}</span>
                          <span className="opinion-item-time">
                            {dayjs(item.created_at).format('DD/MM/YYYY HH:mm')}
                          </span>
                        </div>
                        {item.parent_opinion_id && (
                          <div style={{ fontSize: 12, color: '#6B7280', marginBottom: 4 }}>
                            <SendOutlined /> Chuyển tiếp cho {item.forwarded_to_name || '—'}
                          </div>
                        )}
                        <div className="opinion-item-text">{item.content}</div>
                        <div style={{ marginTop: 6 }}>
                          <Button
                            size="small"
                            type="link"
                            icon={<SendOutlined />}
                            onClick={() => openForwardOpinion(item.id)}
                            style={{ padding: 0 }}
                          >
                            Chuyển tiếp
                          </Button>
                        </div>
                      </div>
                    </div>
                  ))}
                </>
              )}
              <Divider />
              <Form form={opinionForm} validateTrigger="onSubmit">
                <Form.Item
                  name="content"
                  rules={[{ required: true, message: 'Vui lòng nhập ý kiến' }]}
                  style={{ marginBottom: 8 }}
                >
                  <TextArea rows={4} placeholder="Nhập ý kiến xử lý..." maxLength={2000} showCount />
                </Form.Item>
                <div style={{ textAlign: 'right' }}>
                  <Button
                    type="primary"
                    loading={sendingOpinion}
                    onClick={handleSendOpinion}
                  >
                    Gửi ý kiến
                  </Button>
                </div>
              </Form>
            </>
          )}
        </div>
      ),
    },
    {
      key: 'attachments',
      label: <span><PaperClipOutlined /> File đính kèm</span>,
      children: (
        <div>
          <Upload.Dragger
            multiple
            showUploadList={false}
            accept=".pdf,.doc,.docx,.xls,.xlsx,.png,.jpg,.jpeg"
            customRequest={handleUpload}
            style={{ marginBottom: 16 }}
          >
            <p style={{ fontSize: 24, color: '#0891B2' }}><UploadOutlined /></p>
            <p style={{ fontWeight: 500 }}>Kéo thả file vào đây hoặc nhấn để chọn file</p>
            <p style={{ fontSize: 12, color: '#64748B' }}>
              Hỗ trợ: PDF, Word, Excel, PNG, JPG — tối đa 50MB mỗi file
            </p>
          </Upload.Dragger>
          {attachmentsLoading ? (
            <Skeleton active paragraph={{ rows: 3 }} />
          ) : attachments.length === 0 ? (
            <div className="empty-center">Chưa có file đính kèm</div>
          ) : (
            attachments.map((att) => (
              <div key={att.id} className="attachment-item">
                <div className="attachment-info">
                  {getFileIcon(att.file_name)}
                  <div>
                    <div className="file-name">{att.file_name}</div>
                    <div className="file-meta">
                      {formatFileSize(att.file_size)} · {dayjs(att.created_at).format('DD/MM/YYYY HH:mm')}
                      {att.created_by_name && ` · ${att.created_by_name}`}
                    </div>
                  </div>
                </div>
                <Space>
                  <Button
                    size="small"
                    icon={<DownloadOutlined />}
                    onClick={() => handleDownload(att.id, att.file_name)}
                  >
                    Tải xuống
                  </Button>

                  {/* Phase 11 — Ký số button (Plan 11-08).
                      Hiện khi: user là signer của HSCV + status ∈ {2,3} + file PDF + chưa ký. */}
                  {canSignHandling &&
                    !att.is_ca &&
                    att.file_name.toLowerCase().endsWith('.pdf') && (
                      <Button
                        size="small"
                        type="primary"
                        icon={<SafetyOutlined />}
                        style={{ backgroundColor: '#059669', borderColor: '#059669' }}
                        onClick={() => openSign({
                          attachment: { id: att.id, file_name: att.file_name },
                          attachmentType: 'handling',
                          docId: detail.id,
                          signReason: `Phê duyệt HSCV: ${detail.name}`,
                          signLocation: detail.unit_name || 'Lào Cai',
                          onSuccess: fetchAttachments,
                        })}
                      >
                        Ký số
                      </Button>
                    )}

                  {/* Badge "Đã ký số" — hiện khi file đã có is_ca từ backend */}
                  {att.is_ca && (
                    <Tag color="success" icon={<CheckCircleOutlined />}>
                      Đã ký số
                    </Tag>
                  )}

                  <Popconfirm
                    title="Xóa file này?"
                    okText="Xóa"
                    cancelText="Hủy bỏ"
                    okType="danger"
                    onConfirm={() => handleDeleteAttachment(att.id)}
                  >
                    <Button size="small" danger icon={<DeleteOutlined />}>Xóa</Button>
                  </Popconfirm>
                </Space>
              </div>
            ))
          )}
        </div>
      ),
    },
    {
      key: 'children',
      label: <span><ApartmentOutlined /> HSCV con</span>,
      children: (
        <div>
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 12 }}>
            <Button
              type="primary"
              ghost
              icon={<PlusOutlined />}
              onClick={handleCreateChild}
            >
              Tạo HSCV con
            </Button>
          </div>
          <Table
            columns={childrenColumns}
            dataSource={children}
            rowKey="id"
            loading={childrenLoading}
            size="small"
            locale={{
              emptyText: (
                <div className="empty-center">
                  Chưa có hồ sơ con. Nhấn &quot;Tạo HSCV con&quot; để thêm hồ sơ con.
                </div>
              ),
            }}
            pagination={false}
          />
        </div>
      ),
    },
  ];

  return (
    <div>
      {/* Breadcrumb */}
      <Breadcrumb
        style={{ marginBottom: 12 }}
        items={[
          { title: <a onClick={() => router.push('/')}>Trang chủ</a> },
          { title: <a onClick={() => router.push('/ho-so-cong-viec')}>Hồ sơ công việc</a> },
          { title: detail.name },
        ]}
      />

      {/* Detail header */}
      <div className="detail-header">
        <div className="detail-header-left">
          <Button
            icon={<ArrowLeftOutlined />}
            onClick={() => router.back()}
            aria-label="Quay lại"
          />
          <Tag color={statusInfo.color} style={{ margin: 0 }}>{statusInfo.text}</Tag>
          <h1 className="detail-header-title">{detail.name}</h1>
          {/* HDSD 3.2 — Hiển thị số văn bản (nếu đã lấy số) */}
          {detail.number != null && (
            <Tag color="blue" style={{ margin: 0, fontSize: 13 }}>
              Số: {detail.number}
              {detail.doc_book_name ? ` / ${detail.doc_book_name}` : ''}
            </Tag>
          )}
        </div>
        <div className="detail-header-right">
          {toolbarButtons.map((btn, idx) => (
            <Button
              key={idx}
              type={btn.type}
              danger={btn.danger}
              ghost={btn.ghost}
              style={btn.style}
              loading={actionLoading && idx === 0}
              onClick={() => handleToolbarAction(btn)}
              aria-label={btn.label}
            >
              {btn.label}
            </Button>
          ))}
        </div>
      </div>

      {/* Main content card with tabs */}
      <Card className="page-card" styles={{ body: { padding: 0, overflow: 'hidden' } }}>
        <Tabs
          type="card"
          activeKey={activeTab}
          onChange={handleTabChange}
          items={tabItems.map((t) => ({
            ...t,
            children: (
              <div style={{ padding: '16px 20px 8px', minWidth: 0, overflow: 'hidden' }}>
                {t.children}
              </div>
            ),
          }))}
          style={{ padding: '0 0 16px 0' }}
          tabBarStyle={{ marginBottom: 0, paddingLeft: 16, paddingTop: 8 }}
        />
      </Card>

      {/* Tu choi modal — required reason */}
      <Modal
        title="Từ chối hồ sơ"
        open={rejectModalOpen}
        onOk={submitReject}
        onCancel={() => setRejectModalOpen(false)}
        okText="Từ chối"
        okType="danger"
        cancelText="Hủy"
        okButtonProps={{ disabled: !rejectReason.trim() }}
      >
        <p>Nhập lý do từ chối để thông báo cho người xử lý.</p>
        <TextArea
          rows={3}
          maxLength={500}
          showCount
          placeholder="Nhập lý do từ chối..."
          value={rejectReason}
          onChange={(e) => setRejectReason(e.target.value)}
          autoFocus
        />
        <div style={{ height: 24 }} />
      </Modal>

      {/* Tra ve modal — required reason */}
      <Modal
        title="Trả về hồ sơ"
        open={returnModalOpen}
        onOk={submitReturn}
        onCancel={() => setReturnModalOpen(false)}
        okText="Trả về"
        cancelText="Hủy"
        okButtonProps={{ disabled: !returnReason.trim() }}
      >
        <p>Nhập lý do trả về để người xử lý biết cần chỉnh sửa gì.</p>
        <TextArea
          rows={3}
          maxLength={500}
          showCount
          placeholder="Nhập lý do trả về..."
          value={returnReason}
          onChange={(e) => setReturnReason(e.target.value)}
          autoFocus
        />
        <div style={{ height: 24 }} />
      </Modal>

      {/* Progress update modal */}
      <Modal
        title="Cập nhật tiến độ"
        open={progressModalOpen}
        onOk={handleUpdateProgress}
        onCancel={() => setProgressModalOpen(false)}
        okText="Cập nhật"
        cancelText="Hủy bỏ"
        confirmLoading={updatingProgress}
      >
        <div style={{ padding: '16px 0' }}>
          <div style={{ marginBottom: 12 }}>Tiến độ hoàn thành (%)</div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
            <Slider
              min={0}
              max={100}
              value={progressValue}
              onChange={setProgressValue}
              style={{ flex: 1 }}
              tooltip={{ formatter: (v) => `${v}%` }}
            />
            <InputNumber
              min={0}
              max={100}
              value={progressValue}
              onChange={(v) => setProgressValue(v || 0)}
              formatter={(v) => `${v}%`}
              parser={(s) => Number((s || '').replace('%', '')) as number & (0 | 100)}
              style={{ width: 100 }}
            />
          </div>
        </div>
      </Modal>

      {/* Gap F (HDSD III.2.7) — MODAL CHUYỂN TIẾP HSCV */}
      <Modal
        title="Chuyển tiếp hồ sơ công việc"
        open={transferOpen}
        onOk={handleTransfer}
        onCancel={() => setTransferOpen(false)}
        okText="Chuyển tiếp"
        cancelText="Hủy"
        confirmLoading={transferring}
        width={500}
      >
        <div style={{ marginBottom: 12, padding: 10, background: '#EFF6FF', border: '1px solid #BFDBFE', borderRadius: 6, fontSize: 12, color: '#1E40AF' }}>
          <ExclamationCircleOutlined /> Chỉ có thể chuyển HSCV cho người cùng đơn vị
        </div>
        <Form layout="vertical">
          <Form.Item label="Người nhận" required>
            <Select
              showSearch
              optionFilterProp="label"
              placeholder="Chọn người nhận (cùng đơn vị)"
              options={forwardStaffOptions.filter(s => s.value !== user?.staffId)}
              value={transferToStaffId ?? undefined}
              onChange={setTransferToStaffId}
            />
          </Form.Item>
          <Form.Item label="Ghi chú">
            <Input.TextArea
              rows={3}
              maxLength={500}
              showCount
              value={transferNote}
              onChange={(e) => setTransferNote(e.target.value)}
              placeholder="Ghi chú thêm (tuỳ chọn)"
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* Gap F (HDSD III.2.7) — MODAL LỊCH SỬ HSCV */}
      <Modal
        title="Lịch sử hồ sơ công việc"
        open={historyOpen}
        onCancel={() => setHistoryOpen(false)}
        footer={<Button onClick={() => setHistoryOpen(false)}>Đóng</Button>}
        width={720}
      >
        {historyLoading ? (
          <Skeleton active paragraph={{ rows: 4 }} />
        ) : historyList.length === 0 ? (
          <div className="empty-center">Chưa có lịch sử</div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
            {historyList.map((h) => (
              <div key={h.id} style={{ padding: 12, border: '1px solid #E5E7EB', borderRadius: 8 }}>
                <div style={{ fontWeight: 600, color: '#1B3A5C' }}>
                  {h.action_type === 'create' && (<><PlusOutlined /> Tạo HSCV</>)}
                  {h.action_type === 'submit' && (<><SendOutlined /> Trình ký</>)}
                  {h.action_type === 'approve' && (<><CheckOutlined style={{ color: '#059669' }} /> Duyệt hồ sơ</>)}
                  {h.action_type === 'reject' && (<><CloseOutlined style={{ color: '#DC2626' }} /> Từ chối</>)}
                  {h.action_type === 'return' && (<><RollbackOutlined style={{ color: '#D97706' }} /> Trả về bổ sung</>)}
                  {h.action_type === 'complete' && (<><CheckOutlined style={{ color: '#059669' }} /> Hoàn thành</>)}
                  {h.action_type === 'assign_number' && (<><FieldNumberOutlined /> Lấy số văn bản</>)}
                  {h.action_type === 'transfer' && (<><SwapOutlined /> Chuyển tiếp: {h.from_staff_name || '—'} → {h.to_staff_name || '—'}</>)}
                  {h.action_type === 'cancel' && (<><ExclamationCircleOutlined /> Hủy HSCV</>)}
                  {h.action_type === 'reopen' && (<><HistoryOutlined /> Mở lại</>)}
                  {h.action_type?.startsWith('change_status:') && (() => {
                    const ns = h.action_type!.split(':')[1];
                    const labelMap: Record<string, string> = { '0': 'Mới tạo', '1': 'Đang xử lý', '2': 'Chờ trình ký', '3': 'Đã trình ký', '4': 'Hoàn thành', '5': 'Tạm dừng', '-1': 'Từ chối', '-2': 'Trả về', '-3': 'Đã hủy' };
                    return <><HistoryOutlined /> Đổi trạng thái → {labelMap[ns] || ns}</>;
                  })()}
                </div>
                {h.note && <div style={{ marginTop: 6, color: '#4B5563' }}>Ghi chú: {h.note}</div>}
                <div style={{ marginTop: 6, fontSize: 12, color: '#6B7280' }}>
                  {dayjs(h.created_at).format('DD/MM/YYYY HH:mm')} · {h.created_by_name || '—'}
                </div>
              </div>
            ))}
          </div>
        )}
      </Modal>

      {/* Gap E (HDSD III.2.6) — MODAL CHUYỂN TIẾP Ý KIẾN */}
      <Modal
        title="Chuyển tiếp ý kiến"
        open={fwdOpen}
        onOk={handleForwardOpinion}
        onCancel={() => setFwdOpen(false)}
        okText="Gửi"
        cancelText="Hủy"
        confirmLoading={fwdSubmitting}
        width={500}
      >
        <Form layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item label="Người nhận" required>
            <Select
              showSearch
              optionFilterProp="label"
              placeholder="Chọn người nhận..."
              options={forwardStaffOptions}
              value={fwdToStaffId ?? undefined}
              onChange={setFwdToStaffId}
            />
          </Form.Item>
          <Form.Item label="Nội dung chuyển tiếp" required>
            <Input.TextArea
              rows={4}
              maxLength={1000}
              showCount
              value={fwdNote}
              onChange={(e) => setFwdNote(e.target.value)}
              placeholder="Nhập nội dung, ý kiến gửi kèm..."
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* Gap D (HDSD III.2.5) — MODAL HỦY HSCV */}
      <Modal
        title="Hủy hồ sơ công việc"
        open={cancelOpen}
        onOk={handleCancel}
        onCancel={() => { setCancelOpen(false); setCancelReason(''); }}
        okText="Xác nhận hủy"
        cancelText="Hủy thao tác"
        okButtonProps={{ danger: true }}
        confirmLoading={cancelling}
        width={480}
      >
        <Form layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item label="Lý do hủy HSCV" required>
            <Input.TextArea
              rows={4}
              maxLength={1000}
              showCount
              value={cancelReason}
              onChange={(e) => setCancelReason(e.target.value)}
              placeholder="Nhập lý do hủy HSCV..."
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* HDSD 3.2 — MODAL LẤY SỐ */}
      <Modal
        title="Chọn sổ văn bản để lấy số"
        open={laySoOpen}
        onOk={handleConfirmLaySo}
        onCancel={() => setLaySoOpen(false)}
        okText="Lấy số"
        cancelText="Hủy"
        confirmLoading={layingNumber}
      >
        <Form layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item label="Sổ văn bản" required>
            <Select
              placeholder="Chọn sổ văn bản"
              value={selectedBookId ?? undefined}
              onChange={(v) => setSelectedBookId(v)}
              options={docBooks.map((b) => ({
                value: b.id,
                label: b.code ? `${b.code} - ${b.name}` : b.name,
              }))}
              showSearch
              optionFilterProp="label"
              style={{ width: '100%' }}
            />
          </Form.Item>
          <div style={{ fontSize: 12, color: '#64748b' }}>
            Số văn bản được tính theo công thức MAX(số) + 1 trong cùng sổ và năm tạo HSCV.
          </div>
        </Form>
      </Modal>

      {/* Edit drawer */}
      <div
        style={{ position: 'fixed', inset: 0, display: editDrawerOpen ? undefined : 'none', zIndex: 1000 }}
      >
        <div style={{
          position: 'fixed',
          right: 0,
          top: 0,
          bottom: 0,
          width: 720,
          background: '#fff',
          boxShadow: '-4px 0 16px rgba(0,0,0,0.12)',
          display: 'flex',
          flexDirection: 'column',
        }}>
          <div style={{
            background: 'linear-gradient(135deg, #1B3A5C 0%, #0891B2 100%)',
            padding: '16px 24px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}>
            <span style={{ color: '#fff', fontSize: 16, fontWeight: 600 }}>Chỉnh sửa hồ sơ công việc</span>
            <Space>
              <Button ghost style={{ borderColor: 'rgba(255,255,255,0.5)', color: '#fff' }} onClick={() => setEditDrawerOpen(false)}>Hủy</Button>
              <Button style={{ background: '#fff', color: '#1B3A5C' }} icon={<SaveOutlined />} loading={saving} onClick={handleEditSave}>Lưu</Button>
            </Space>
          </div>
          <div style={{ flex: 1, overflowY: 'auto', padding: 24 }}>
            <Form form={editForm} layout="vertical" validateTrigger="onSubmit">
              <Form.Item name="name" label="Tên hồ sơ công việc" rules={[{ required: true, message: 'Vui lòng nhập tên hồ sơ' }]}>
                <Input maxLength={500} placeholder="Nhập tên hồ sơ công việc..." />
              </Form.Item>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 16px' }}>
                <Form.Item name="doc_type_id" label="Loại văn bản">
                  <Select options={docTypes} placeholder="Chọn loại văn bản" allowClear />
                </Form.Item>
                <Form.Item name="doc_field_id" label="Lĩnh vực">
                  <Select options={fields} placeholder="Chọn lĩnh vực" allowClear />
                </Form.Item>
                <Form.Item name="start_date" label="Ngày mở" rules={[{ required: true, message: 'Vui lòng chọn ngày mở' }]}>
                  <DatePicker format="DD/MM/YYYY" style={{ width: '100%' }} />
                </Form.Item>
                <Form.Item name="end_date" label="Hạn giải quyết" rules={[{ required: true, message: 'Vui lòng chọn hạn' }]}>
                  <DatePicker format="DD/MM/YYYY" style={{ width: '100%' }} />
                </Form.Item>
                <Form.Item name="curator_id" label="Người phụ trách">
                  <Select options={staffOptions} placeholder="Chọn người phụ trách" showSearch optionFilterProp="label" allowClear />
                </Form.Item>
                <Form.Item name="signer_id" label="Lãnh đạo ký">
                  <Select options={leaderOptions} placeholder="Chọn lãnh đạo ký" showSearch optionFilterProp="label" allowClear notFoundContent={leaderOptions.length === 0 ? 'Đơn vị chưa có lãnh đạo' : 'Không tìm thấy'} />
                </Form.Item>
              </div>
              <Form.Item name="comments" label="Ghi chú">
                <TextArea rows={3} maxLength={2000} placeholder="Nhập ghi chú..." />
              </Form.Item>
            </Form>
          </div>
        </div>
      </div>

      {/* Add linked document modal */}
      <Modal
        title="Thêm văn bản liên kết"
        open={addDocModalOpen}
        onOk={handleAddLinkedDocs}
        onCancel={() => { setAddDocModalOpen(false); setSelectedDocKeys([]); }}
        okText="Liên kết"
        cancelText="Hủy bỏ"
        size={800}
      >
        <div style={{ marginBottom: 12 }}>
          <Tabs
            activeKey={searchDocTab}
            onChange={(k) => { setSearchDocTab(k); setSearchDocResults([]); setSelectedDocKeys([]); }}
            items={[
              { key: 'den', label: 'Văn bản đến' },
              { key: 'di', label: 'Văn bản đi' },
              { key: 'du-thao', label: 'Dự thảo' },
            ]}
          />
          <Space.Compact style={{ width: '100%', marginBottom: 12 }}>
            <Input
              placeholder="Nhập từ khóa tìm kiếm..."
              value={searchDocKeyword}
              onChange={(e) => setSearchDocKeyword(e.target.value)}
              onPressEnter={handleSearchDocs}
            />
            <Button type="primary" onClick={handleSearchDocs} loading={searchDocLoading}>Tìm kiếm</Button>
          </Space.Compact>
          <Table
            size="small"
            loading={searchDocLoading}
            dataSource={searchDocResults}
            rowKey="id"
            rowSelection={{
              type: 'checkbox',
              selectedRowKeys: selectedDocKeys,
              onChange: (keys) => setSelectedDocKeys(keys as number[]),
            }}
            columns={[
              { title: 'Số VB', dataIndex: 'doc_number', width: 120 },
              { title: 'Trích yếu', dataIndex: 'abstract', ellipsis: true },
              { title: 'Loại', dataIndex: 'doc_type_name', width: 130 },
              {
                title: 'Ngày ký',
                dataIndex: 'signed_date',
                width: 110,
                render: (v: string) => v ? dayjs(v).format('DD/MM/YYYY') : '-',
              },
            ]}
            pagination={{ pageSize: 5, size: 'small' }}
          />
        </div>
      </Modal>

      {/* Child HSCV drawer */}
      <div
        style={{ position: 'fixed', inset: 0, display: childDrawerOpen ? undefined : 'none', zIndex: 1000 }}
      >
        <div style={{
          position: 'fixed',
          right: 0,
          top: 0,
          bottom: 0,
          width: 720,
          background: '#fff',
          boxShadow: '-4px 0 16px rgba(0,0,0,0.12)',
          display: 'flex',
          flexDirection: 'column',
        }}>
          <div style={{
            background: 'linear-gradient(135deg, #1B3A5C 0%, #0891B2 100%)',
            padding: '16px 24px',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
          }}>
            <span style={{ color: '#fff', fontSize: 16, fontWeight: 600 }}>Tạo hồ sơ con</span>
            <Space>
              <Button ghost style={{ borderColor: 'rgba(255,255,255,0.5)', color: '#fff' }} onClick={() => setChildDrawerOpen(false)}>Hủy</Button>
              <Button style={{ background: '#fff', color: '#1B3A5C' }} icon={<SaveOutlined />} loading={savingChild} onClick={handleSaveChild}>Lưu</Button>
            </Space>
          </div>
          <div style={{ flex: 1, overflowY: 'auto', padding: 24 }}>
            <Form form={childForm} layout="vertical" validateTrigger="onSubmit">
              <Form.Item name="parent_name" label="Hồ sơ cha">
                <Input disabled />
              </Form.Item>
              <Form.Item name="name" label="Tên hồ sơ con" rules={[{ required: true, message: 'Vui lòng nhập tên hồ sơ con' }]}>
                <Input maxLength={500} placeholder="Nhập tên hồ sơ công việc con..." />
              </Form.Item>
              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '0 16px' }}>
                <Form.Item name="start_date" label="Ngày mở" rules={[{ required: true, message: 'Vui lòng chọn ngày mở' }]}>
                  <DatePicker format="DD/MM/YYYY" style={{ width: '100%' }} />
                </Form.Item>
                <Form.Item name="end_date" label="Hạn giải quyết" rules={[{ required: true, message: 'Vui lòng chọn hạn' }]}>
                  <DatePicker format="DD/MM/YYYY" style={{ width: '100%' }} />
                </Form.Item>
                <Form.Item name="curator_id" label="Người phụ trách">
                  <Select options={staffOptions} placeholder="Chọn người phụ trách" showSearch optionFilterProp="label" allowClear />
                </Form.Item>
                <Form.Item name="signer_id" label="Lãnh đạo ký">
                  <Select options={leaderOptions} placeholder="Chọn lãnh đạo ký" showSearch optionFilterProp="label" allowClear notFoundContent={leaderOptions.length === 0 ? 'Đơn vị chưa có lãnh đạo' : 'Không tìm thấy'} />
                </Form.Item>
              </div>
              <Form.Item name="comments" label="Ghi chú">
                <TextArea rows={3} maxLength={2000} placeholder="Nhập ghi chú..." />
              </Form.Item>
            </Form>
          </div>
        </div>
      </div>

      {/* Phase 11 — SignModal từ useSigning hook (Plan 11-08) */}
      {renderSignModal()}
    </div>
  );
}
