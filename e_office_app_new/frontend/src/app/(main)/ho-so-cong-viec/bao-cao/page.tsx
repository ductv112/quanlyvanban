'use client';

import { useState, useEffect, useCallback } from 'react';
import {
  Row,
  Col,
  Card,
  Tabs,
  Table,
  Button,
  Select,
  DatePicker,
  Space,
  Skeleton,
  Progress,
  App,
} from 'antd';
import {
  FolderOpenOutlined,
  SwapOutlined,
  CalendarOutlined,
  CheckCircleOutlined,
  SyncOutlined,
  ExclamationCircleOutlined,
  FileSearchOutlined,
  UserOutlined,
  TeamOutlined,
  FileExcelOutlined,
} from '@ant-design/icons';
import { Column, Pie } from '@ant-design/charts';
import dayjs from 'dayjs';
import ExcelJS from 'exceljs';
import { api } from '@/lib/api';

const { RangePicker } = DatePicker;

// ── KPI card config ──────────────────────────────────────────────────────────

interface KpiCard {
  key: string;
  label: string;
  icon: React.ComponentType<{ style?: React.CSSProperties }>;
  gradient: string;
}

const KPI_CARDS: KpiCard[] = [
  {
    key: 'total',
    label: 'Tổng số',
    icon: FolderOpenOutlined,
    gradient: 'linear-gradient(135deg, #1B3A5C, #2D5A8A)',
  },
  {
    key: 'prev_period',
    label: 'Chuyển kỳ trước',
    icon: SwapOutlined,
    gradient: 'linear-gradient(135deg, #475569, #64748B)',
  },
  {
    key: 'current_period',
    label: 'Kỳ này',
    icon: CalendarOutlined,
    gradient: 'linear-gradient(135deg, #0891B2, #06B6D4)',
  },
  {
    key: 'completed',
    label: 'Hoàn thành',
    icon: CheckCircleOutlined,
    gradient: 'linear-gradient(135deg, #059669, #10B981)',
  },
  {
    key: 'in_progress',
    label: 'Đang thực hiện',
    icon: SyncOutlined,
    gradient: 'linear-gradient(135deg, #D97706, #F59E0B)',
  },
  {
    key: 'overdue_percent',
    label: 'Quá hạn %',
    icon: ExclamationCircleOutlined,
    gradient: 'linear-gradient(135deg, #DC2626, #EF4444)',
  },
];

// ── Types ─────────────────────────────────────────────────────────────────────

interface KpiData {
  total: number;
  prev_period: number;
  current_period: number;
  completed: number;
  in_progress: number;
  overdue: number;
  overdue_percent: number;
  [key: string]: number;
}

interface ReportRow {
  department_name?: string;
  staff_name?: string;
  assigner_name?: string;
  total: number;
  completed: number;
  in_progress: number;
  overdue: number;
  completion_rate: number;
}

interface DepartmentOption {
  value: number;
  label: string;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

const DATE_FORMAT = 'DD/MM/YYYY';

function formatKpiValue(key: string, value: number): string {
  if (key === 'overdue_percent') return `${value}%`;
  return String(value ?? 0);
}

// ── Component ─────────────────────────────────────────────────────────────────

export default function BaoCaoPage() {
  const { message } = App.useApp();

  // KPI state
  const [kpiData, setKpiData] = useState<KpiData>({
    total: 0,
    prev_period: 0,
    current_period: 0,
    completed: 0,
    in_progress: 0,
    overdue: 0,
    overdue_percent: 0,
  });
  const [kpiLoading, setKpiLoading] = useState(false);

  // Report state
  const [reportTab, setReportTab] = useState<'by-unit' | 'by-staff' | 'by-assigner'>('by-unit');
  const [reportData, setReportData] = useState<ReportRow[]>([]);
  const [reportLoading, setReportLoading] = useState(false);

  // Filter state — default: first day of current month to today
  const [dateRange, setDateRange] = useState<[dayjs.Dayjs, dayjs.Dayjs]>([
    dayjs().startOf('month'),
    dayjs(),
  ]);
  const [selectedUnitId, setSelectedUnitId] = useState<number | null>(null);
  const [departments, setDepartments] = useState<DepartmentOption[]>([]);

  // ── Fetch departments for Select ──────────────────────────────────────────

  useEffect(() => {
    api
      .get<{ data: { id: number; ten_don_vi: string }[] }>('/quan-tri/don-vi')
      .then((res) => {
        const list = res.data?.data ?? [];
        setDepartments(
          list.map((d) => ({ value: d.id, label: d.ten_don_vi }))
        );
      })
      .catch(() => {
        // non-blocking — unit select just stays empty
      });
  }, []);

  // ── Fetch KPI ─────────────────────────────────────────────────────────────

  const fetchKpi = useCallback(async () => {
    setKpiLoading(true);
    try {
      const from = dateRange[0].format('YYYY-MM-DD');
      const to = dateRange[1].format('YYYY-MM-DD');
      const res = await api.get<{ data: KpiData }>(
        `/ho-so-cong-viec/thong-ke/kpi?from_date=${from}&to_date=${to}`
      );
      if (res.data?.data) {
        setKpiData(res.data.data);
      }
    } catch {
      // silently ignore — server may not be up during demo
    } finally {
      setKpiLoading(false);
    }
  }, [dateRange]);

  // ── Fetch Report ──────────────────────────────────────────────────────────

  const fetchReport = useCallback(async () => {
    setReportLoading(true);
    try {
      const from = dateRange[0].format('YYYY-MM-DD');
      const to = dateRange[1].format('YYYY-MM-DD');
      const unitParam = selectedUnitId ? `&unit_id=${selectedUnitId}` : '';

      const endpointMap: Record<string, string> = {
        'by-unit': `/ho-so-cong-viec/thong-ke/bao-cao/theo-don-vi?from_date=${from}&to_date=${to}${unitParam}`,
        'by-staff': `/ho-so-cong-viec/thong-ke/bao-cao/theo-can-bo?from_date=${from}&to_date=${to}${unitParam}`,
        'by-assigner': `/ho-so-cong-viec/thong-ke/bao-cao/theo-nguoi-giao?from_date=${from}&to_date=${to}${unitParam}`,
      };

      const res = await api.get<{ data: ReportRow[] }>(endpointMap[reportTab]);
      setReportData(res.data?.data ?? []);
    } catch {
      setReportData([]);
    } finally {
      setReportLoading(false);
    }
  }, [dateRange, selectedUnitId, reportTab]);

  // ── Initial load ──────────────────────────────────────────────────────────

  useEffect(() => {
    fetchKpi();
  }, [fetchKpi]);

  useEffect(() => {
    fetchReport();
  }, [fetchReport]);

  // ── Excel Export ──────────────────────────────────────────────────────────

  const exportExcel = async () => {
    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet('Báo cáo HSCV');

    const tabLabel =
      reportTab === 'by-unit' ? 'Đơn vị' : reportTab === 'by-staff' ? 'Cán bộ' : 'Người giao';

    sheet.columns = [
      { header: tabLabel, key: 'name', width: 30 },
      { header: 'Tổng', key: 'total', width: 10 },
      { header: 'Hoàn thành', key: 'completed', width: 12 },
      { header: 'Đang xử lý', key: 'in_progress', width: 12 },
      { header: 'Quá hạn', key: 'overdue', width: 10 },
      { header: 'Tỷ lệ HT %', key: 'completion_rate', width: 12 },
    ];

    // Style header
    const headerRow = sheet.getRow(1);
    headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
    headerRow.fill = {
      type: 'pattern',
      pattern: 'solid',
      fgColor: { argb: 'FF1B3A5C' },
    };

    // Data rows
    reportData.forEach((row) => {
      const name = row.department_name ?? row.staff_name ?? row.assigner_name ?? '';
      sheet.addRow({
        name,
        total: row.total,
        completed: row.completed,
        in_progress: row.in_progress,
        overdue: row.overdue,
        completion_rate: row.completion_rate,
      });
    });

    // Download
    const buffer = await workbook.xlsx.writeBuffer();
    const blob = new Blob([buffer], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `bao-cao-hscv-${dayjs().format('YYYYMMDD')}.xlsx`;
    a.click();
    URL.revokeObjectURL(url);
    message.success('Xuất Excel thành công');
  };

  // ── Chart data ────────────────────────────────────────────────────────────

  const barChartData = reportData.map((row) => ({
    department: row.department_name ?? row.staff_name ?? row.assigner_name ?? '',
    value: row.total,
  }));

  const pieChartData = [
    { type: 'Hoàn thành', value: kpiData.completed },
    { type: 'Đang thực hiện', value: kpiData.in_progress },
    { type: 'Quá hạn', value: kpiData.overdue },
  ].filter((d) => d.value > 0);

  // ── Table columns ─────────────────────────────────────────────────────────

  const firstColLabel =
    reportTab === 'by-unit' ? 'Đơn vị' : reportTab === 'by-staff' ? 'Cán bộ' : 'Người giao';

  const tableColumns = [
    {
      title: firstColLabel,
      dataIndex:
        reportTab === 'by-unit'
          ? 'department_name'
          : reportTab === 'by-staff'
          ? 'staff_name'
          : 'assigner_name',
      key: 'name',
      ellipsis: true,
    },
    {
      title: 'Tổng',
      dataIndex: 'total',
      key: 'total',
      width: 80,
      align: 'center' as const,
    },
    {
      title: 'Hoàn thành',
      dataIndex: 'completed',
      key: 'completed',
      width: 100,
      align: 'center' as const,
      render: (val: number) => (
        <span style={{ color: '#059669', fontWeight: 600 }}>{val}</span>
      ),
    },
    {
      title: 'Đang xử lý',
      dataIndex: 'in_progress',
      key: 'in_progress',
      width: 100,
      align: 'center' as const,
      render: (val: number) => (
        <span style={{ color: '#0891B2', fontWeight: 600 }}>{val}</span>
      ),
    },
    {
      title: 'Quá hạn',
      dataIndex: 'overdue',
      key: 'overdue',
      width: 80,
      align: 'center' as const,
      render: (val: number) => (
        <span style={{ color: '#DC2626', fontWeight: 600 }}>{val}</span>
      ),
    },
    {
      title: 'Tỷ lệ hoàn thành %',
      dataIndex: 'completion_rate',
      key: 'completion_rate',
      width: 130,
      render: (val: number) => (
        <Progress
          percent={val ?? 0}
          size="small"
          strokeColor="#0891B2"
          style={{ marginBottom: 0 }}
        />
      ),
    },
  ];

  // ── Tab items ─────────────────────────────────────────────────────────────

  const reportTabItems = [
    {
      key: 'by-unit',
      label: (
        <span>
          <FileSearchOutlined /> Theo đơn vị
        </span>
      ),
    },
    {
      key: 'by-staff',
      label: (
        <span>
          <UserOutlined /> Theo cán bộ
        </span>
      ),
    },
    {
      key: 'by-assigner',
      label: (
        <span>
          <TeamOutlined /> Theo người giao
        </span>
      ),
    },
  ];

  // ── Render ────────────────────────────────────────────────────────────────

  return (
    <div>
      {/* Page Header */}
      <div className="page-header">
        <h2 className="page-title">Báo cáo hồ sơ công việc</h2>
        <p className="page-description">
          Thống kê hiệu suất xử lý hồ sơ công việc theo đơn vị, cán bộ và người giao
        </p>
      </div>

      {/* ── KPI Cards ── */}
      <Row gutter={[16, 16]} style={{ marginBottom: 24 }}>
        {KPI_CARDS.map((card) => {
          const IconComp = card.icon;
          return (
            <Col xs={12} xl={4} key={card.key}>
              <Card
                className="stat-card"
                variant="borderless"
                style={{
                  background: card.gradient,
                  boxShadow: '0 4px 16px rgba(0,0,0,0.15)',
                }}
                styles={{ body: { padding: 20 } }}
                hoverable
              >
                {kpiLoading ? (
                  <Space orientation="vertical" size={8}>
                    <Skeleton.Avatar active size={40} shape="square" />
                    <Skeleton.Input active size="small" style={{ width: 80 }} />
                  </Space>
                ) : (
                  <div className="stat-card-body">
                    <div>
                      <p
                        style={{
                          fontSize: 12,
                          color: 'rgba(255,255,255,0.75)',
                          margin: '0 0 8px 0',
                          fontWeight: 400,
                        }}
                      >
                        {card.label}
                      </p>
                      <p
                        style={{
                          fontSize: 28,
                          fontWeight: 700,
                          color: '#ffffff',
                          margin: 0,
                          lineHeight: 1.2,
                        }}
                      >
                        {formatKpiValue(card.key, kpiData[card.key])}
                      </p>
                    </div>
                    <div
                      className="stat-card-icon"
                      style={{
                        background: 'rgba(255,255,255,0.15)',
                        fontSize: 22,
                        color: 'rgba(255,255,255,0.9)',
                      }}
                    >
                      <IconComp style={{ fontSize: 22 }} />
                    </div>
                  </div>
                )}
              </Card>
            </Col>
          );
        })}
      </Row>

      {/* ── Charts ── */}
      <Row gutter={16} style={{ marginBottom: 24 }}>
        <Col xs={24} lg={12}>
          <Card
            className="page-card"
            title={
              <div className="section-card-header">
                <div
                  className="section-card-icon"
                  style={{ background: 'linear-gradient(135deg, #1B3A5C, #2D5A8A)' }}
                >
                  <FileSearchOutlined style={{ color: '#fff', fontSize: 16 }} />
                </div>
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>So sánh theo đơn vị</span>
              </div>
            }
            variant="borderless"
          >
            {barChartData.length > 0 ? (
              <Column
                data={barChartData}
                xField="department"
                yField="value"
                color="#1B3A5C"
                height={300}
                label={{ position: 'top', style: { fontSize: 11 } }}
                xAxis={{ label: { autoRotate: true, style: { fontSize: 11 } } }}
              />
            ) : (
              <div
                style={{
                  height: 300,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#94A3B8',
                  fontSize: 14,
                }}
              >
                Chưa có dữ liệu biểu đồ
              </div>
            )}
          </Card>
        </Col>

        <Col xs={24} lg={12}>
          <Card
            className="page-card"
            title={
              <div className="section-card-header">
                <div
                  className="section-card-icon"
                  style={{ background: 'linear-gradient(135deg, #0891B2, #06B6D4)' }}
                >
                  <SyncOutlined style={{ color: '#fff', fontSize: 16 }} />
                </div>
                <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Tỷ lệ trạng thái</span>
              </div>
            }
            variant="borderless"
          >
            {pieChartData.length > 0 ? (
              <Pie
                data={pieChartData}
                angleField="value"
                colorField="type"
                innerRadius={0.6}
                height={300}
                color={['#059669', '#0891B2', '#DC2626']}
                label={{
                  type: 'spider',
                  labelHeight: 28,
                  content: '{name}\n{percentage}',
                  style: { fontSize: 12 },
                }}
                legend={{ position: 'bottom' }}
              />
            ) : (
              <div
                style={{
                  height: 300,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  color: '#94A3B8',
                  fontSize: 14,
                }}
              >
                Chưa có dữ liệu biểu đồ
              </div>
            )}
          </Card>
        </Col>
      </Row>

      {/* ── Report Tabs ── */}
      <Card className="page-card" variant="borderless">
        <Tabs
          type="card"
          activeKey={reportTab}
          onChange={(key) => setReportTab(key as typeof reportTab)}
          items={reportTabItems}
          style={{ marginBottom: 16 }}
        />

        {/* Filter Row */}
        <div className="filter-row" style={{ marginBottom: 16 }}>
          <Space wrap>
            <Select
              allowClear
              placeholder="Chọn đơn vị"
              style={{ width: 160 }}
              options={departments}
              value={selectedUnitId}
              onChange={(val) => setSelectedUnitId(val ?? null)}
            />
            <RangePicker
              format={DATE_FORMAT}
              style={{ width: 220 }}
              value={dateRange}
              onChange={(vals) => {
                if (vals && vals[0] && vals[1]) {
                  setDateRange([vals[0], vals[1]]);
                }
              }}
              placeholder={['Từ ngày', 'Đến ngày']}
            />
            <Button type="primary" onClick={() => { fetchKpi(); fetchReport(); }}>
              Tìm kiếm
            </Button>
            <Button
              icon={<FileExcelOutlined />}
              style={{ color: '#059669', borderColor: '#059669' }}
              onClick={exportExcel}
            >
              Xuất Excel
            </Button>
          </Space>
        </div>

        {/* Report Table */}
        <Table
          rowKey={(_, index) => String(index)}
          columns={tableColumns}
          dataSource={reportData}
          loading={reportLoading}
          size="small"
          pagination={{ pageSize: 20, showSizeChanger: false }}
          scroll={{ x: 700 }}
          locale={{ emptyText: 'Không có dữ liệu thống kê' }}
        />
      </Card>
    </div>
  );
}
