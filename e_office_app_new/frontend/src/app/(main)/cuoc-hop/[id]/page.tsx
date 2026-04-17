'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Tabs, Table, Button, Form, Input, Select, Tag, Badge,
  Progress, Upload, Divider, Modal, Space, Skeleton, Radio, App, Checkbox,
  Descriptions, Typography, Drawer,
} from 'antd';
import type { ColumnsType } from 'antd/es/table';
import type { UploadFile } from 'antd/es/upload/interface';
import {
  ArrowLeftOutlined, PlusOutlined, DeleteOutlined, DownloadOutlined,
  UploadOutlined, CheckOutlined, PlayCircleOutlined, StopOutlined,
  UserAddOutlined, ExclamationCircleOutlined,
} from '@ant-design/icons';
import { useRouter, useParams } from 'next/navigation';
import dayjs from 'dayjs';
import { api } from '@/lib/api';
import { getSocket, initSocket } from '@/lib/socket';

const { TextArea } = Input;
const { Text } = Typography;

// ─── Constants ─────────────────────────────────────────────────────────────────

const APPROVED_MAP: Record<number, { label: string; color: string }> = {
  0: { label: 'Chưa duyệt', color: 'default' },
  1: { label: 'Đã duyệt', color: 'green' },
  [-1]: { label: 'Từ chối', color: 'red' },
};

const MEETING_STATUS_MAP: Record<number, { label: string; color: string }> = {
  0: { label: 'Chưa họp', color: 'default' },
  1: { label: 'Đang họp', color: 'processing' },
  2: { label: 'Đã họp', color: 'success' },
  3: { label: 'Hủy', color: 'error' },
};

const USER_TYPE_MAP: Record<number, { label: string; color: string }> = {
  1: { label: 'Chủ tọa', color: 'blue' },
  2: { label: 'Thư ký', color: 'cyan' },
  0: { label: 'Thành viên', color: 'default' },
};

const QUESTION_STATUS_MAP: Record<number, { label: string; color: string }> = {
  0: { label: 'Chưa bắt đầu', color: 'default' },
  1: { label: 'Đang biểu quyết', color: 'processing' },
  2: { label: 'Kết thúc', color: 'success' },
};

// ─── Interfaces ──────────────────────────────────────────────────────────────

interface MeetingDetail {
  id: number;
  name: string;
  room_id: number | null;
  room_name: string | null;
  meeting_type_id: number | null;
  meeting_type_name: string | null;
  content: string | null;
  start_date: string;
  end_date: string | null;
  start_time: string | null;
  end_time: string | null;
  master_id: number | null;
  master_name: string | null;
  secretary_id: number | null;
  secretary_name?: string | null;
  online_link: string | null;
  component: string | null;
  approved: number;
  meeting_status: number;
  rejection_reason: string | null;
}

interface MeetingStaff {
  id: number;
  staff_id: number;
  staff_name: string;
  position_name: string | null;
  department_name?: string | null;
  user_type: number;
  attendance: boolean;
  attendance_note: string | null;
}

interface MeetingAttachment {
  id: number;
  file_name: string;
  file_size: number;
  file_path: string;
  created_date: string;
}

interface VoteAnswer {
  id: number;
  name: string;
  order_no: number;
  is_other: boolean;
}

interface VoteQuestion {
  id: number;
  name: string;
  question_type: number; // 0=single, 1=multiple
  duration: number | null;
  status: number; // 0=pending, 1=active, 2=ended
  answers: VoteAnswer[];
}

interface VoteResult {
  answer_id: number;
  answer_name: string;
  vote_count: number;
  voter_names: string[];
  percentage: number;
}

interface StaffSelectOption {
  value: number;
  label: string;
}

// ─── Main Component ───────────────────────────────────────────────────────────

export default function CuocHopDetailPage() {
  const { message, modal } = App.useApp();
  const router = useRouter();
  const params = useParams();
  const id = params?.id as string;

  // Detail state
  const [detail, setDetail] = useState<MeetingDetail | null>(null);
  const [loading, setLoading] = useState(true);

  // Staff tab
  const [staffList, setStaffList] = useState<MeetingStaff[]>([]);
  const [staffLoading, setStaffLoading] = useState(false);
  const [addStaffModalOpen, setAddStaffModalOpen] = useState(false);
  const [staffOptions, setStaffOptions] = useState<StaffSelectOption[]>([]);
  const [selectedStaffIds, setSelectedStaffIds] = useState<number[]>([]);
  const [addingUserType, setAddingUserType] = useState(0);
  const [addStaffLoading, setAddStaffLoading] = useState(false);

  // Attachments tab
  const [attachments, setAttachments] = useState<MeetingAttachment[]>([]);
  const [attachLoading, setAttachLoading] = useState(false);
  const [fileList, setFileList] = useState<UploadFile[]>([]);

  // Voting tab
  const [questions, setQuestions] = useState<VoteQuestion[]>([]);
  const [voteLoading, setVoteLoading] = useState(false);
  const [addQuestionModalOpen, setAddQuestionModalOpen] = useState(false);
  const [questionForm] = Form.useForm();
  const [addAnswerModalOpen, setAddAnswerModalOpen] = useState(false);
  const [answerForm] = Form.useForm();
  const [addingToQuestionId, setAddingToQuestionId] = useState<number | null>(null);
  const [results, setResults] = useState<Record<number, VoteResult[]>>({});
  const [selectedAnswers, setSelectedAnswers] = useState<Record<number, number | number[]>>({});

  // ── Fetch functions ───────────────────────────────────────────────────────────

  const fetchDetail = useCallback(async () => {
    setLoading(true);
    try {
      const { data: res } = await api.get(`/cuoc-hop/${id}`);
      setDetail(res.data || null);
    } catch {
      message.error('Lỗi tải chi tiết cuộc họp');
    } finally {
      setLoading(false);
    }
  }, [id, message]);

  const fetchStaff = useCallback(async () => {
    setStaffLoading(true);
    try {
      const { data: res } = await api.get(`/cuoc-hop/${id}/thanh-vien`);
      setStaffList(res.data || []);
    } catch {
      message.error('Lỗi tải danh sách thành viên');
    } finally {
      setStaffLoading(false);
    }
  }, [id, message]);

  const fetchAttachments = useCallback(async () => {
    setAttachLoading(true);
    try {
      const { data: res } = await api.get(`/cuoc-hop/${id}/tai-lieu`);
      setAttachments(res.data || []);
    } catch {
      // silent
    } finally {
      setAttachLoading(false);
    }
  }, [id]);

  const fetchVoteQuestions = useCallback(async () => {
    setVoteLoading(true);
    try {
      const { data: res } = await api.get(`/cuoc-hop/${id}/bieu-quyet`);
      setQuestions(res.data || []);
    } catch {
      // silent
    } finally {
      setVoteLoading(false);
    }
  }, [id]);

  const fetchVoteResults = useCallback(async (questionId: number) => {
    try {
      const { data: res } = await api.get(`/cuoc-hop/${id}/bieu-quyet/cau-hoi/${questionId}/ket-qua`);
      setResults((prev) => ({ ...prev, [questionId]: res.data || [] }));
    } catch {
      // silent
    }
  }, [id]);

  const fetchStaffOptions = useCallback(async () => {
    try {
      const { data: res } = await api.get('/quan-tri/nguoi-dung', { params: { page: 1, pageSize: 500 } });
      setStaffOptions((res.data || []).map((s: { id: number; full_name: string }) => ({ value: s.id, label: s.full_name })));
    } catch {
      // silent
    }
  }, []);

  useEffect(() => {
    fetchDetail();
    fetchStaff();
    fetchAttachments();
    fetchVoteQuestions();
    fetchStaffOptions();
  }, [fetchDetail, fetchStaff, fetchAttachments, fetchVoteQuestions, fetchStaffOptions]);

  // ── Socket.IO realtime voting ─────────────────────────────────────────────────

  useEffect(() => {
    if (typeof window === 'undefined') return;
    const token = localStorage.getItem('accessToken');
    if (!token) return;

    const socket = getSocket() || initSocket(token);

    socket.on('vote_update', (data: { room_schedule_id: number; question_id: number }) => {
      if (data.room_schedule_id === Number(id)) {
        fetchVoteQuestions();
        if (data.question_id) {
          fetchVoteResults(data.question_id);
        }
      }
    });

    socket.on('vote_status_change', (data: { question_id: number; status: number }) => {
      if (data.question_id) {
        fetchVoteQuestions();
        if (data.status === 2) {
          fetchVoteResults(data.question_id);
        }
      }
    });

    return () => {
      socket.off('vote_update');
      socket.off('vote_status_change');
    };
  }, [id, fetchVoteQuestions, fetchVoteResults]);

  // ── Actions ───────────────────────────────────────────────────────────────────

  const handleApprove = async () => {
    try {
      await api.patch(`/cuoc-hop/${id}/approve`);
      message.success('Đã duyệt cuộc họp');
      fetchDetail();
    } catch {
      message.error('Lỗi duyệt cuộc họp');
    }
  };

  const handleReject = () => {
    let reason = '';
    modal.confirm({
      title: 'Từ chối cuộc họp',
      content: (
        <div>
          <p>Nhập lý do từ chối:</p>
          <TextArea rows={3} onChange={(e) => { reason = e.target.value; }} />
        </div>
      ),
      onOk: async () => {
        try {
          await api.patch(`/cuoc-hop/${id}/reject`, { rejection_reason: reason });
          message.success('Đã từ chối cuộc họp');
          fetchDetail();
        } catch {
          message.error('Lỗi từ chối cuộc họp');
        }
      },
      okText: 'Từ chối',
      okButtonProps: { danger: true },
      cancelText: 'Hủy',
    });
  };

  const handleStartMeeting = async () => {
    try {
      await api.patch(`/cuoc-hop/${id}/bat-dau-hop`);
      message.success('Đã bắt đầu cuộc họp');
      fetchDetail();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Lỗi bắt đầu cuộc họp');
    }
  };

  const handleEndMeeting = async () => {
    try {
      await api.patch(`/cuoc-hop/${id}/ket-thuc-hop`);
      message.success('Đã kết thúc cuộc họp');
      fetchDetail();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Lỗi kết thúc cuộc họp');
    }
  };

  // ── Staff actions ─────────────────────────────────────────────────────────────

  const handleAddStaff = async () => {
    if (!selectedStaffIds.length) {
      message.warning('Vui lòng chọn thành viên');
      return;
    }
    setAddStaffLoading(true);
    try {
      await api.post(`/cuoc-hop/${id}/thanh-vien`, { staff_ids: selectedStaffIds, user_type: addingUserType });
      message.success('Đã thêm thành viên');
      setAddStaffModalOpen(false);
      setSelectedStaffIds([]);
      fetchStaff();
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Lỗi thêm thành viên');
    } finally {
      setAddStaffLoading(false);
    }
  };

  const handleRemoveStaff = (staffId: number) => {
    modal.confirm({
      title: 'Xóa thành viên',
      icon: <ExclamationCircleOutlined style={{ color: '#DC2626' }} />,
      content: 'Bạn có chắc muốn xóa thành viên này khỏi cuộc họp?',
      okText: 'Xóa',
      okType: 'danger',
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.delete(`/cuoc-hop/${id}/thanh-vien/${staffId}`);
          message.success('Đã xóa thành viên');
          fetchStaff();
        } catch {
          message.error('Lỗi xóa thành viên');
        }
      },
    });
  };

  // ── Attachment upload ─────────────────────────────────────────────────────────

  const handleUpload = async (file: File) => {
    const formData = new FormData();
    formData.append('file', file);
    try {
      await api.post(`/cuoc-hop/${id}/tai-lieu`, formData, {
        headers: { 'Content-Type': 'multipart/form-data' },
      });
      message.success('Tải lên tệp thành công');
      fetchAttachments();
    } catch {
      message.error('Lỗi tải lên tệp');
    }
    return false;
  };

  const handleDeleteAttachment = (attId: number) => {
    modal.confirm({
      title: 'Xóa tệp đính kèm',
      content: 'Bạn có chắc muốn xóa tệp này?',
      okText: 'Xóa',
      okType: 'danger',
      cancelText: 'Hủy',
      onOk: async () => {
        try {
          await api.delete(`/cuoc-hop/${id}/tai-lieu/${attId}`);
          message.success('Đã xóa tệp');
          fetchAttachments();
        } catch {
          message.error('Lỗi xóa tệp');
        }
      },
    });
  };

  // ── Voting actions ────────────────────────────────────────────────────────────

  const handleAddQuestion = async () => {
    try {
      const values = await questionForm.validateFields();
      const { data: res } = await api.post(`/cuoc-hop/${id}/bieu-quyet/cau-hoi`, values);
      if (!res.success) { message.error(res.message || 'Lỗi tạo câu hỏi'); return; }
      message.success('Đã thêm câu hỏi biểu quyết');
      setAddQuestionModalOpen(false);
      questionForm.resetFields();
      fetchVoteQuestions();
    } catch (err: unknown) {
      const e = err as { errorFields?: unknown[] };
      if (e?.errorFields) return;
      message.error('Lỗi tạo câu hỏi');
    }
  };

  const handleAddAnswer = async () => {
    if (!addingToQuestionId) return;
    try {
      const values = await answerForm.validateFields();
      await api.post(`/cuoc-hop/${id}/bieu-quyet/cau-hoi/${addingToQuestionId}/dap-an`, values);
      message.success('Đã thêm đáp án');
      setAddAnswerModalOpen(false);
      answerForm.resetFields();
      fetchVoteQuestions();
    } catch (err: unknown) {
      const e = err as { errorFields?: unknown[] };
      if (e?.errorFields) return;
      message.error('Lỗi thêm đáp án');
    }
  };

  const handleStartVoting = async (questionId: number) => {
    try {
      await api.patch(`/cuoc-hop/${id}/bieu-quyet/cau-hoi/${questionId}/bat-dau`);
      message.success('Đã bắt đầu biểu quyết');
      fetchVoteQuestions();
    } catch {
      message.error('Lỗi bắt đầu biểu quyết');
    }
  };

  const handleStopVoting = async (questionId: number) => {
    try {
      await api.patch(`/cuoc-hop/${id}/bieu-quyet/cau-hoi/${questionId}/ket-thuc`);
      message.success('Đã kết thúc biểu quyết');
      fetchVoteQuestions();
      fetchVoteResults(questionId);
    } catch {
      message.error('Lỗi kết thúc biểu quyết');
    }
  };

  const handleVote = async (questionId: number, answerId: number | number[]) => {
    try {
      const aid = Array.isArray(answerId) ? answerId[0] : answerId;
      await api.post(`/cuoc-hop/${id}/bieu-quyet/cau-hoi/${questionId}/vote`, { answer_id: aid });
      message.success('Đã ghi nhận phiếu bầu');
      fetchVoteResults(questionId);
    } catch (err: unknown) {
      const e = err as { response?: { data?: { message?: string } } };
      message.error(e?.response?.data?.message || 'Lỗi biểu quyết');
    }
  };

  // ── Render helpers ────────────────────────────────────────────────────────────

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
  };

  const staffColumns: ColumnsType<MeetingStaff> = [
    { title: 'STT', width: 56, align: 'center', render: (_: unknown, __: MeetingStaff, i: number) => i + 1 },
    { title: 'Họ tên', dataIndex: 'staff_name' },
    { title: 'Chức vụ', dataIndex: 'position_name', render: (v: string | null) => v || '—' },
    { title: 'Phòng ban', dataIndex: 'department_name', render: (v: string | null) => v || '—' },
    {
      title: 'Vai trò',
      dataIndex: 'user_type',
      render: (v: number) => {
        const s = USER_TYPE_MAP[v] || USER_TYPE_MAP[0];
        return <Tag color={s.color}>{s.label}</Tag>;
      },
    },
    {
      title: 'Tham dự',
      dataIndex: 'attendance',
      render: (v: boolean) => v ? <Tag color="green">Đã tham dự</Tag> : <Tag>Chưa xác nhận</Tag>,
    },
    {
      title: 'Thao tác',
      width: 60,
      align: 'center',
      render: (_: unknown, record: MeetingStaff) => (
        <Button type="text" size="small" icon={<DeleteOutlined />} danger onClick={() => handleRemoveStaff(record.staff_id)} />
      ),
    },
  ];

  if (loading) {
    return <div className="page-card"><Skeleton active paragraph={{ rows: 10 }} /></div>;
  }

  if (!detail) {
    return <div className="page-card"><div className="empty-center">Không tìm thấy cuộc họp</div></div>;
  }

  const approved = APPROVED_MAP[detail.approved] || APPROVED_MAP[0];
  const meetingStatus = MEETING_STATUS_MAP[detail.meeting_status] || MEETING_STATUS_MAP[0];

  return (
    <div className="page-card">
      {/* Header */}
      <div className="detail-header">
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <Button type="text" icon={<ArrowLeftOutlined />} onClick={() => router.push('/cuoc-hop')}>Quay lại</Button>
          <h2 className="page-title" style={{ margin: 0 }}>{detail.name}</h2>
          <Tag color={approved.color}>{approved.label}</Tag>
          <Tag color={meetingStatus.color}>{meetingStatus.label}</Tag>
        </div>
        <Space>
          {detail.approved === 0 && (
            <>
              <Button type="primary" icon={<CheckOutlined />} onClick={handleApprove}>Duyệt</Button>
              <Button danger icon={<StopOutlined />} onClick={handleReject}>Từ chối</Button>
            </>
          )}
          {detail.meeting_status === 0 && detail.approved === 1 && (
            <Button type="primary" icon={<PlayCircleOutlined />} onClick={handleStartMeeting}>Bắt đầu họp</Button>
          )}
          {detail.meeting_status === 1 && (
            <Button danger icon={<StopOutlined />} onClick={handleEndMeeting}>Kết thúc họp</Button>
          )}
        </Space>
      </div>

      {/* Tabs */}
      <Tabs
        defaultActiveKey="info"
        items={[
          {
            key: 'info',
            label: 'Thông tin chung',
            children: (
              <Card>
                <Descriptions column={2} bordered size="small">
                  <Descriptions.Item label="Tên cuộc họp" span={2}>{detail.name}</Descriptions.Item>
                  <Descriptions.Item label="Phòng họp">{detail.room_name || '—'}</Descriptions.Item>
                  <Descriptions.Item label="Loại cuộc họp">{detail.meeting_type_name || '—'}</Descriptions.Item>
                  <Descriptions.Item label="Ngày họp">{detail.start_date ? dayjs(detail.start_date).format('DD/MM/YYYY') : '—'}</Descriptions.Item>
                  <Descriptions.Item label="Ngày kết thúc">{detail.end_date ? dayjs(detail.end_date).format('DD/MM/YYYY') : '—'}</Descriptions.Item>
                  <Descriptions.Item label="Giờ bắt đầu">{detail.start_time || '—'}</Descriptions.Item>
                  <Descriptions.Item label="Giờ kết thúc">{detail.end_time || '—'}</Descriptions.Item>
                  <Descriptions.Item label="Chủ tọa">{detail.master_name || '—'}</Descriptions.Item>
                  <Descriptions.Item label="Thư ký">{detail.secretary_name || '—'}</Descriptions.Item>
                  <Descriptions.Item label="Thành phần tham dự" span={2}>{detail.component || '—'}</Descriptions.Item>
                  <Descriptions.Item label="Đường dẫn trực tuyến" span={2}>
                    {detail.online_link ? <a href={detail.online_link} target="_blank" rel="noreferrer">{detail.online_link}</a> : '—'}
                  </Descriptions.Item>
                  <Descriptions.Item label="Nội dung" span={2}>{detail.content || '—'}</Descriptions.Item>
                  <Descriptions.Item label="Trạng thái duyệt">
                    <Tag color={approved.color}>{approved.label}</Tag>
                    {detail.rejection_reason && <Text type="danger" style={{ marginLeft: 8 }}>({detail.rejection_reason})</Text>}
                  </Descriptions.Item>
                  <Descriptions.Item label="Trạng thái họp">
                    <Tag color={meetingStatus.color}>{meetingStatus.label}</Tag>
                  </Descriptions.Item>
                </Descriptions>
              </Card>
            ),
          },
          {
            key: 'thanh-vien',
            label: 'Thành viên',
            children: (
              <Card
                extra={
                  <Button type="primary" icon={<UserAddOutlined />} onClick={() => setAddStaffModalOpen(true)}>
                    Thêm thành viên
                  </Button>
                }
              >
                <Table<MeetingStaff>
                  rowKey="id"
                  columns={staffColumns}
                  dataSource={staffList}
                  loading={staffLoading}
                  size="small"
                  pagination={false}
                />
              </Card>
            ),
          },
          {
            key: 'tai-lieu',
            label: 'Tài liệu',
            children: (
              <Card
                extra={
                  <Upload
                    beforeUpload={(file) => { handleUpload(file); return false; }}
                    fileList={fileList}
                    onChange={({ fileList: fl }) => setFileList(fl)}
                    showUploadList={false}
                  >
                    <Button icon={<UploadOutlined />}>Tải lên tài liệu</Button>
                  </Upload>
                }
              >
                {attachLoading ? <Skeleton active paragraph={{ rows: 4 }} /> : attachments.length === 0 ? (
                  <div style={{ padding: '16px', textAlign: 'center', color: '#94A3B8' }}>Chưa có tài liệu đính kèm</div>
                ) : (
                  attachments.map((item) => (
                    <div key={item.id} style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 0', borderBottom: '1px solid #F1F5F9' }}>
                      <div>
                        <div style={{ fontWeight: 500 }}>{item.file_name}</div>
                        <div style={{ fontSize: 12, color: '#94A3B8' }}>{formatFileSize(item.file_size)} — {dayjs(item.created_date).format('DD/MM/YYYY HH:mm')}</div>
                      </div>
                      <div>
                        <Button type="link" icon={<DownloadOutlined />} href={item.file_path} target="_blank">Tải về</Button>
                        <Button type="text" icon={<DeleteOutlined />} danger onClick={() => handleDeleteAttachment(item.id)}>Xóa</Button>
                      </div>
                    </div>
                  ))
                )}
              </Card>
            ),
          },
          {
            key: 'bieu-quyet',
            label: 'Biểu quyết',
            children: (
              <Card
                extra={
                  <Button type="primary" icon={<PlusOutlined />} onClick={() => setAddQuestionModalOpen(true)}>
                    Thêm câu hỏi
                  </Button>
                }
              >
                {voteLoading ? <Skeleton active paragraph={{ rows: 4 }} /> : (
                  questions.length === 0 ? (
                    <div className="empty-center">Chưa có câu hỏi biểu quyết</div>
                  ) : (
                    questions.map((q) => {
                      const qStatus = QUESTION_STATUS_MAP[q.status] || QUESTION_STATUS_MAP[0];
                      const qResults = results[q.id] || [];
                      return (
                        <Card
                          key={q.id}
                          size="small"
                          style={{ marginBottom: 16 }}
                          title={
                            <Space>
                              <span>{q.name}</span>
                              <Badge status={q.status === 1 ? 'processing' : q.status === 2 ? 'success' : 'default'} text={qStatus.label} />
                            </Space>
                          }
                          extra={
                            <Space>
                              {q.status === 0 && (
                                <>
                                  <Button size="small" onClick={() => { setAddingToQuestionId(q.id); setAddAnswerModalOpen(true); }}>
                                    Thêm đáp án
                                  </Button>
                                  <Button size="small" type="primary" icon={<PlayCircleOutlined />} onClick={() => handleStartVoting(q.id)}>
                                    Bắt đầu
                                  </Button>
                                </>
                              )}
                              {q.status === 1 && (
                                <Button size="small" danger icon={<StopOutlined />} onClick={() => handleStopVoting(q.id)}>
                                  Kết thúc
                                </Button>
                              )}
                              {q.status === 2 && (
                                <Button size="small" onClick={() => fetchVoteResults(q.id)}>Xem kết quả</Button>
                              )}
                            </Space>
                          }
                        >
                          {/* Answers list */}
                          {q.answers && q.answers.length > 0 && (
                            <div style={{ marginBottom: 12 }}>
                              {q.status === 1 && (
                                <div>
                                  <div style={{ marginBottom: 8, fontWeight: 500 }}>Chọn đáp án của bạn:</div>
                                  {q.question_type === 0 ? (
                                    <Radio.Group
                                      value={selectedAnswers[q.id]}
                                      onChange={(e) => setSelectedAnswers((prev) => ({ ...prev, [q.id]: e.target.value }))}
                                    >
                                      <Space orientation="vertical">
                                        {q.answers.map((a) => <Radio key={a.id} value={a.id}>{a.name}</Radio>)}
                                      </Space>
                                    </Radio.Group>
                                  ) : (
                                    <Checkbox.Group
                                      value={selectedAnswers[q.id] as number[] || []}
                                      onChange={(vals) => setSelectedAnswers((prev) => ({ ...prev, [q.id]: vals as number[] }))}
                                    >
                                      <Space orientation="vertical">
                                        {q.answers.map((a) => <Checkbox key={a.id} value={a.id}>{a.name}</Checkbox>)}
                                      </Space>
                                    </Checkbox.Group>
                                  )}
                                  <div style={{ marginTop: 12 }}>
                                    <Button type="primary" size="small" onClick={() => handleVote(q.id, selectedAnswers[q.id])}>
                                      Gửi phiếu bầu
                                    </Button>
                                  </div>
                                </div>
                              )}
                              {q.status !== 1 && (
                                <div>
                                  {q.answers.map((a) => <div key={a.id} style={{ color: '#64748B', marginBottom: 4 }}>• {a.name}</div>)}
                                </div>
                              )}
                            </div>
                          )}

                          {/* Results */}
                          {q.status === 2 && qResults.length > 0 && (
                            <div>
                              <Divider style={{ margin: '12px 0 8px' }}>Kết quả biểu quyết</Divider>
                              {qResults.map((r) => (
                                <div key={r.answer_id} style={{ marginBottom: 12 }}>
                                  <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 4 }}>
                                    <span style={{ fontWeight: 500 }}>{r.answer_name}</span>
                                    <span>{r.vote_count} phiếu ({r.percentage}%)</span>
                                  </div>
                                  <Progress percent={r.percentage} strokeColor="#0891B2" showInfo={false} />
                                  {r.voter_names && r.voter_names.length > 0 && (
                                    <div style={{ fontSize: 12, color: '#94A3B8' }}>
                                      {r.voter_names.join(', ')}
                                    </div>
                                  )}
                                </div>
                              ))}
                            </div>
                          )}
                        </Card>
                      );
                    })
                  )
                )}
              </Card>
            ),
          },
        ]}
      />

      {/* ── Drawer: Thêm thành viên cuộc họp ──────────────────────────────── */}
      <Drawer
        open={addStaffModalOpen}
        onClose={() => { setAddStaffModalOpen(false); setSelectedStaffIds([]); }}
        title="Thêm thành viên cuộc họp"
        size={480} rootClassName="drawer-gradient"
        extra={<Space><Button onClick={() => { setAddStaffModalOpen(false); setSelectedStaffIds([]); }}>Hủy</Button><Button type="primary" onClick={handleAddStaff} loading={addStaffLoading}>Thêm</Button></Space>}
      >
        <Form layout="vertical">
          <Form.Item label="Vai trò">
            <Select
              value={addingUserType}
              onChange={setAddingUserType}
              style={{ width: '100%' }}
              options={[
                { value: 0, label: 'Thành viên' },
                { value: 1, label: 'Chủ tọa' },
                { value: 2, label: 'Thư ký' },
              ]}
            />
          </Form.Item>
          <Form.Item label="Chọn thành viên">
            <Select
              mode="multiple"
              value={selectedStaffIds}
              onChange={setSelectedStaffIds}
              style={{ width: '100%' }}
              options={staffOptions}
              showSearch
              filterOption={(input, opt) => (opt?.label as string || '').toLowerCase().includes(input.toLowerCase())}
              placeholder="Tìm kiếm và chọn thành viên..."
            />
          </Form.Item>
        </Form>
      </Drawer>

      {/* ── Drawer: Thêm câu hỏi biểu quyết ────────────────────────────────── */}
      <Drawer
        open={addQuestionModalOpen}
        onClose={() => { setAddQuestionModalOpen(false); questionForm.resetFields(); }}
        title="Thêm câu hỏi biểu quyết"
        size={480} rootClassName="drawer-gradient" forceRender
        extra={<Space><Button onClick={() => { setAddQuestionModalOpen(false); questionForm.resetFields(); }}>Hủy</Button><Button type="primary" onClick={handleAddQuestion}>Thêm</Button></Space>}
      >
        <Form form={questionForm} layout="vertical">
          <Form.Item name="name" label="Nội dung câu hỏi" rules={[{ required: true, message: 'Vui lòng nhập câu hỏi' }]}>
            <Input placeholder="Nhập nội dung câu hỏi biểu quyết" />
          </Form.Item>
          <Form.Item name="question_type" label="Loại câu hỏi" initialValue={0}>
            <Select options={[{ value: 0, label: 'Đơn lẻ (chọn một)' }, { value: 1, label: 'Nhiều lựa chọn' }]} />
          </Form.Item>
          <Form.Item name="duration" label="Thời gian biểu quyết (giây)">
            <Input type="number" placeholder="VD: 60" />
          </Form.Item>
        </Form>
      </Drawer>

      {/* ── Drawer: Thêm đáp án ──────────────────────────────────────────────── */}
      <Drawer
        open={addAnswerModalOpen}
        onClose={() => { setAddAnswerModalOpen(false); answerForm.resetFields(); }}
        title="Thêm đáp án"
        size={480} rootClassName="drawer-gradient" forceRender
        extra={<Space><Button onClick={() => { setAddAnswerModalOpen(false); answerForm.resetFields(); }}>Hủy</Button><Button type="primary" onClick={handleAddAnswer}>Thêm</Button></Space>}
      >
        <Form form={answerForm} layout="vertical">
          <Form.Item name="name" label="Tên đáp án" rules={[{ required: true, message: 'Vui lòng nhập đáp án' }]}>
            <Input placeholder="VD: Đồng ý / Không đồng ý / Ý kiến khác" />
          </Form.Item>
          <Form.Item name="order_no" label="Thứ tự" initialValue={1}>
            <Input type="number" />
          </Form.Item>
          <Form.Item name="is_other" label="Là lựa chọn khác" valuePropName="checked" initialValue={false}>
            <Checkbox>Cho phép nhập văn bản</Checkbox>
          </Form.Item>
        </Form>
      </Drawer>
    </div>
  );
}
