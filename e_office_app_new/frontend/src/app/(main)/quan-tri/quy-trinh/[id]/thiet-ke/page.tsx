'use client';

import { useCallback, useState, useEffect, useRef } from 'react';
import {
  ReactFlow, Background, Controls, MiniMap, Handle, Position,
  useNodesState, useEdgesState, addEdge,
  NodeProps, ReactFlowProvider, useReactFlow,
  type Connection, type Edge, type Node,
  type OnConnect, type OnNodesDelete, type OnEdgesDelete,
} from '@xyflow/react';
import '@xyflow/react/dist/style.css';
import {
  Button, Card, Form, Input, Select, Switch, InputNumber, Space,
  Spin, App, Modal,
} from 'antd';
import {
  SaveOutlined, DeleteOutlined, ArrowLeftOutlined,
  PlusCircleOutlined,
} from '@ant-design/icons';
import { useParams, useRouter } from 'next/navigation';
import { api } from '@/lib/api';

// ─── Custom Node Types ────────────────────────────────────────────────────────

function StartNode({ data, selected }: NodeProps) {
  return (
    <div
      style={{
        width: 60,
        height: 60,
        borderRadius: '50%',
        background: '#059669',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#fff',
        fontWeight: 700,
        fontSize: 11,
        textAlign: 'center',
        boxShadow: selected
          ? '0 0 0 3px rgba(5, 150, 105, 0.35)'
          : '0 2px 8px rgba(5, 150, 105, 0.3)',
        border: selected ? '2px solid #059669' : '2px solid transparent',
        transition: 'box-shadow 0.15s',
        cursor: 'default',
        userSelect: 'none',
      }}
    >
      <span>{String(data.label || 'Bắt đầu')}</span>
      <Handle
        type="source"
        position={Position.Bottom}
        style={{ background: '#059669', border: '2px solid #fff', width: 10, height: 10 }}
      />
    </div>
  );
}

function ProcessNode({ data, selected }: NodeProps) {
  const [hovered, setHovered] = useState(false);
  return (
    <div
      onMouseEnter={() => setHovered(true)}
      onMouseLeave={() => setHovered(false)}
      style={{
        width: 180,
        minHeight: 80,
        background: '#fff',
        border: selected
          ? '2px solid #0891B2'
          : '2px solid #1B3A5C',
        borderRadius: 8,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        padding: '8px 12px',
        boxShadow: selected
          ? '0 0 0 3px rgba(8, 145, 178, 0.2)'
          : hovered
          ? '0 4px 12px rgba(27, 58, 92, 0.15)'
          : '0 2px 6px rgba(27, 58, 92, 0.08)',
        transition: 'box-shadow 0.2s, border-color 0.15s',
        cursor: 'default',
        userSelect: 'none',
        position: 'relative',
      }}
    >
      <Handle
        type="target"
        position={Position.Top}
        style={{ background: '#1B3A5C', border: '2px solid #fff', width: 10, height: 10 }}
      />
      <div style={{ textAlign: 'center' }}>
        <div style={{ fontWeight: 600, fontSize: 13, color: '#1B3A5C', lineHeight: 1.4 }}>
          {String(data.label || 'Bước xử lý')}
        </div>
        {data.step_type && (
          <div style={{ fontSize: 11, color: '#64748b', marginTop: 2 }}>
            {data.step_type === 'review'
              ? 'Xem xét'
              : data.step_type === 'approve'
              ? 'Phê duyệt'
              : 'Xử lý'}
          </div>
        )}
      </div>
      <Handle
        type="source"
        position={Position.Bottom}
        style={{ background: '#1B3A5C', border: '2px solid #fff', width: 10, height: 10 }}
      />
    </div>
  );
}

function EndNode({ data, selected }: NodeProps) {
  return (
    <div
      style={{
        width: 60,
        height: 60,
        borderRadius: '50%',
        background: '#DC2626',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        color: '#fff',
        fontWeight: 700,
        fontSize: 11,
        textAlign: 'center',
        boxShadow: selected
          ? '0 0 0 3px rgba(220, 38, 38, 0.35)'
          : '0 2px 8px rgba(220, 38, 38, 0.3)',
        border: selected ? '2px solid #DC2626' : '2px solid transparent',
        transition: 'box-shadow 0.15s',
        cursor: 'default',
        userSelect: 'none',
      }}
    >
      <Handle
        type="target"
        position={Position.Top}
        style={{ background: '#DC2626', border: '2px solid #fff', width: 10, height: 10 }}
      />
      <span>{String(data.label || 'Kết thúc')}</span>
    </div>
  );
}

const nodeTypes = { start: StartNode, process: ProcessNode, end: EndNode };

const defaultEdgeStyle = { stroke: '#64748B', strokeWidth: 2 };

// ─── Designer Content ─────────────────────────────────────────────────────────

function DesignerContent() {
  const { message } = App.useApp();
  const params = useParams();
  const router = useRouter();
  const { screenToFlowPosition } = useReactFlow();

  const id = params?.id as string;

  const [flowName, setFlowName] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [nodes, setNodes, onNodesChange] = useNodesState<Node>([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState<Edge>([]);
  const [selectedNode, setSelectedNode] = useState<Node | null>(null);
  const [propForm] = Form.useForm();
  const reactFlowWrapper = useRef<HTMLDivElement>(null);
  const stepOrderRef = useRef(1);

  // Load workflow data on mount
  useEffect(() => {
    if (!id) return;

    const loadFlow = async () => {
      setLoading(true);
      try {
        const { data: res } = await api.get(`/quan-tri/quy-trinh/${id}/full`);
        const { flow, steps, links } = res.data || {};

        setFlowName(flow?.name || `Quy trình #${id}`);

        if (steps && steps.length > 0) {
          const loadedNodes: Node[] = steps.map((step: any) => ({
            id: String(step.id),
            type: step.step_type === 'start' ? 'start' : step.step_type === 'end' ? 'end' : 'process',
            position: { x: step.position_x || 0, y: step.position_y || 0 },
            data: {
              label: step.step_name,
              step_type: step.step_type,
              allow_sign: step.allow_sign,
              deadline_days: step.deadline_days,
              step_order: step.step_order,
            },
          }));
          setNodes(loadedNodes);
          stepOrderRef.current = steps.length + 1;
        } else {
          // Default Start + End nodes
          setNodes([
            {
              id: 'start-default',
              type: 'start',
              position: { x: 250, y: 50 },
              data: { label: 'Bắt đầu' },
            },
            {
              id: 'end-default',
              type: 'end',
              position: { x: 250, y: 400 },
              data: { label: 'Kết thúc' },
            },
          ]);
        }

        if (links && links.length > 0) {
          const loadedEdges: Edge[] = links.map((link: any) => ({
            id: String(link.id),
            source: String(link.from_step_id),
            target: String(link.to_step_id),
            style: defaultEdgeStyle,
            markerEnd: { type: 'arrowclosed' as const },
          }));
          setEdges(loadedEdges);
        }
      } catch {
        message.error('Không thể tải dữ liệu quy trình');
        // Use default nodes even if API fails
        setFlowName(`Quy trình #${id}`);
        setNodes([
          {
            id: 'start-default',
            type: 'start',
            position: { x: 250, y: 50 },
            data: { label: 'Bắt đầu' },
          },
          {
            id: 'end-default',
            type: 'end',
            position: { x: 250, y: 400 },
            data: { label: 'Kết thúc' },
          },
        ]);
      } finally {
        setLoading(false);
      }
    };

    loadFlow();
  }, [id, message, setNodes, setEdges]);

  // Handle new connection
  const onConnect: OnConnect = useCallback(
    async (connection: Connection) => {
      const newEdge: Edge = {
        ...connection,
        id: `edge-${Date.now()}`,
        style: defaultEdgeStyle,
        markerEnd: { type: 'arrowclosed' as const },
      } as Edge;

      setEdges((eds) => addEdge(newEdge, eds));

      try {
        await api.post('/quan-tri/quy-trinh/step-links', {
          workflow_id: id,
          from_step_id: connection.source,
          to_step_id: connection.target,
        });
      } catch {
        // Link will be saved on workflow save
      }
    },
    [id, setEdges]
  );

  // Drag over handler
  const onDragOver = useCallback((event: React.DragEvent) => {
    event.preventDefault();
    event.dataTransfer.dropEffect = 'move';
  }, []);

  // Drop new node from toolbar
  const onDrop = useCallback(
    async (event: React.DragEvent) => {
      event.preventDefault();

      const type = event.dataTransfer.getData('application/reactflow');
      if (!type || !reactFlowWrapper.current) return;

      const bounds = reactFlowWrapper.current.getBoundingClientRect();
      const position = screenToFlowPosition({
        x: event.clientX - bounds.left,
        y: event.clientY - bounds.top,
      });

      const newNode: Node = {
        id: `node-${Date.now()}`,
        type: 'process',
        position,
        data: {
          label: 'Bước mới',
          step_type: 'process',
          step_order: stepOrderRef.current,
          allow_sign: false,
          deadline_days: null,
        },
      };

      setNodes((nds) => [...nds, newNode]);
      stepOrderRef.current += 1;

      try {
        const { data: res } = await api.post(`/quan-tri/quy-trinh/${id}/steps`, {
          step_name: 'Bước mới',
          step_type: 'process',
          step_order: newNode.data.step_order,
          position_x: Math.round(position.x),
          position_y: Math.round(position.y),
        });
        if (res.data?.id) {
          setNodes((nds) =>
            nds.map((n) => (n.id === newNode.id ? { ...n, id: String(res.data.id) } : n))
          );
        }
      } catch {
        // Node saved locally for now
      }
    },
    [id, screenToFlowPosition, setNodes]
  );

  // Node click — show properties panel
  const onNodeClick = useCallback(
    (_event: React.MouseEvent, node: Node) => {
      if (node.type === 'process') {
        setSelectedNode(node);
        propForm.setFieldsValue({
          label: node.data.label,
          step_type: node.data.step_type || 'process',
          allow_sign: node.data.allow_sign || false,
          deadline_days: node.data.deadline_days || null,
        });
      } else {
        setSelectedNode(null);
      }
    },
    [propForm]
  );

  // Click on canvas background — deselect
  const onPaneClick = useCallback(() => {
    setSelectedNode(null);
  }, []);

  // Node drag stop — update position
  const onNodeDragStop = useCallback(
    async (_event: React.MouseEvent, node: Node) => {
      try {
        await api.put(`/quan-tri/quy-trinh/steps/${node.id}`, {
          position_x: Math.round(node.position.x),
          position_y: Math.round(node.position.y),
        });
      } catch {
        // position updated locally
      }
    },
    []
  );

  // Delete nodes
  const onNodesDelete: OnNodesDelete = useCallback(
    async (deletedNodes) => {
      for (const node of deletedNodes) {
        try {
          await api.delete(`/quan-tri/quy-trinh/steps/${node.id}`);
        } catch {
          // ignore
        }
      }
      if (selectedNode && deletedNodes.some((n) => n.id === selectedNode.id)) {
        setSelectedNode(null);
      }
    },
    [selectedNode]
  );

  // Delete edges
  const onEdgesDelete: OnEdgesDelete = useCallback(async (deletedEdges) => {
    for (const edge of deletedEdges) {
      try {
        await api.delete(`/quan-tri/quy-trinh/step-links/${edge.id}`);
      } catch {
        // ignore
      }
    }
  }, []);

  // Apply node property changes
  const handleApplyProps = async () => {
    if (!selectedNode) return;
    try {
      const values = await propForm.validateFields();

      setNodes((nds) =>
        nds.map((n) =>
          n.id === selectedNode.id
            ? {
                ...n,
                data: {
                  ...n.data,
                  label: values.label,
                  step_type: values.step_type,
                  allow_sign: values.allow_sign,
                  deadline_days: values.deadline_days,
                },
              }
            : n
        )
      );

      setSelectedNode((prev) =>
        prev
          ? {
              ...prev,
              data: {
                ...prev.data,
                label: values.label,
                step_type: values.step_type,
                allow_sign: values.allow_sign,
                deadline_days: values.deadline_days,
              },
            }
          : null
      );

      await api.put(`/quan-tri/quy-trinh/steps/${selectedNode.id}`, {
        step_name: values.label,
        step_type: values.step_type,
        allow_sign: values.allow_sign,
        deadline_days: values.deadline_days,
      });

      message.success('Cập nhật bước thành công');
    } catch (err: any) {
      if (err?.response?.data?.message) {
        message.error(err.response.data.message);
      }
    }
  };

  // Delete selected step
  const handleDeleteStep = () => {
    if (!selectedNode) return;
    Modal.confirm({
      title: 'Xóa bước',
      content: `Bạn có chắc muốn xóa bước "${selectedNode.data.label}"?`,
      okText: 'Xóa',
      cancelText: 'Hủy',
      okButtonProps: { danger: true },
      onOk: async () => {
        try {
          await api.delete(`/quan-tri/quy-trinh/steps/${selectedNode.id}`);
          setNodes((nds) => nds.filter((n) => n.id !== selectedNode.id));
          setEdges((eds) =>
            eds.filter((e) => e.source !== selectedNode.id && e.target !== selectedNode.id)
          );
          setSelectedNode(null);
          message.success('Đã xóa bước');
        } catch (err: any) {
          message.error(err?.response?.data?.message || 'Lỗi khi xóa bước');
        }
      },
    });
  };

  // Save all node positions
  const handleSave = async () => {
    setSaving(true);
    try {
      await Promise.all(
        nodes
          .filter((n) => n.type === 'process')
          .map((n) =>
            api.put(`/quan-tri/quy-trinh/steps/${n.id}`, {
              position_x: Math.round(n.position.x),
              position_y: Math.round(n.position.y),
              step_name: n.data.label,
              step_type: n.data.step_type,
              allow_sign: n.data.allow_sign,
              deadline_days: n.data.deadline_days,
            }).catch(() => null)
          )
      );
      message.success('Lưu quy trình thành công');
    } catch {
      message.error('Lưu quy trình thất bại');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: '100vh', background: '#f0f2f5' }}>
      {/* Header bar */}
      <div
        style={{
          height: 56,
          background: '#fff',
          borderBottom: '1px solid #e2e8f0',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'space-between',
          padding: '0 20px',
          boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
          flexShrink: 0,
          zIndex: 10,
        }}
      >
        <Space size={12}>
          <Button
            type="text"
            icon={<ArrowLeftOutlined />}
            onClick={() => router.back()}
            style={{ color: '#475569' }}
          >
            Quay lại
          </Button>
          <div
            style={{
              width: 1,
              height: 24,
              background: '#e2e8f0',
            }}
          />
          <div style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C' }}>
            Thiết kế quy trình: {flowName}
          </div>
        </Space>
        <Button
          type="primary"
          icon={<SaveOutlined />}
          loading={saving}
          onClick={handleSave}
          style={{ borderRadius: 8 }}
        >
          Lưu quy trình
        </Button>
      </div>

      {/* Main canvas area */}
      <div style={{ flex: 1, display: 'flex', overflow: 'hidden' }}>
        {/* Left toolbar */}
        <div
          style={{
            width: 60,
            background: '#fff',
            borderRight: '1px solid #e2e8f0',
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            padding: '12px 0',
            gap: 8,
            flexShrink: 0,
          }}
        >
          <div
            title="Kéo để thêm bước xử lý"
            draggable
            onDragStart={(e) => {
              e.dataTransfer.setData('application/reactflow', 'process');
              e.dataTransfer.effectAllowed = 'move';
            }}
            style={{
              width: 40,
              height: 40,
              background: 'linear-gradient(135deg, #1B3A5C, #2D5A8A)',
              borderRadius: 8,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              cursor: 'grab',
              color: '#fff',
              fontSize: 18,
              boxShadow: '0 2px 6px rgba(27, 58, 92, 0.25)',
            }}
          >
            <PlusCircleOutlined />
          </div>
          <div
            style={{
              fontSize: 9,
              color: '#94a3b8',
              textAlign: 'center',
              lineHeight: 1.3,
              maxWidth: 52,
            }}
          >
            Bước xử lý
          </div>
        </div>

        {/* ReactFlow canvas */}
        <div
          ref={reactFlowWrapper}
          style={{ flex: 1, height: '100%', position: 'relative' }}
          onDrop={onDrop}
          onDragOver={onDragOver}
        >
          {loading ? (
            <div
              style={{
                position: 'absolute',
                inset: 0,
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                background: 'rgba(240, 242, 245, 0.8)',
                zIndex: 10,
              }}
            >
              <Spin size="large" tip="Đang tải quy trình..." />
            </div>
          ) : null}
          <ReactFlow
            nodes={nodes}
            edges={edges}
            onNodesChange={onNodesChange}
            onEdgesChange={onEdgesChange}
            onConnect={onConnect}
            onNodeClick={onNodeClick}
            onPaneClick={onPaneClick}
            onNodeDragStop={onNodeDragStop}
            onNodesDelete={onNodesDelete}
            onEdgesDelete={onEdgesDelete}
            nodeTypes={nodeTypes}
            snapToGrid={true}
            snapGrid={[8, 8]}
            defaultEdgeOptions={{
              style: defaultEdgeStyle,
              markerEnd: { type: 'arrowclosed' },
            }}
            fitView
            fitViewOptions={{ padding: 0.2 }}
            deleteKeyCode={['Backspace', 'Delete']}
            style={{ background: '#f8fafc' }}
          >
            <Background color="#e2e8f0" gap={16} />
            <Controls />
            <MiniMap
              nodeColor={(n) => {
                if (n.type === 'start') return '#059669';
                if (n.type === 'end') return '#DC2626';
                return '#1B3A5C';
              }}
              maskColor="rgba(240, 242, 245, 0.7)"
            />
          </ReactFlow>
        </div>

        {/* Right properties panel */}
        {selectedNode && (
          <div
            style={{
              width: 320,
              background: '#fff',
              borderLeft: '1px solid #e2e8f0',
              display: 'flex',
              flexDirection: 'column',
              flexShrink: 0,
              overflow: 'auto',
            }}
          >
            <Card
              size="small"
              variant="borderless"
              title={
                <div
                  style={{
                    background: 'linear-gradient(135deg, #1B3A5C, #0891B2)',
                    margin: '-12px -16px',
                    padding: '12px 16px',
                    color: '#fff',
                    borderRadius: '8px 8px 0 0',
                    fontWeight: 600,
                    fontSize: 13,
                  }}
                >
                  Thuộc tính bước
                </div>
              }
              style={{ borderRadius: 0, flex: 1 }}
            >
              <Form
                form={propForm}
                layout="vertical"
                size="small"
                style={{ marginTop: 8 }}
                validateTrigger="onSubmit"
              >
                <Form.Item
                  label="Tên bước"
                  name="label"
                  rules={[{ required: true, message: 'Nhập tên bước' }]}
                >
                  <Input placeholder="Nhập tên bước" maxLength={200} />
                </Form.Item>

                <Form.Item label="Loại bước" name="step_type">
                  <Select
                    options={[
                      { value: 'process', label: 'Xử lý' },
                      { value: 'review', label: 'Xem xét' },
                      { value: 'approve', label: 'Phê duyệt' },
                    ]}
                  />
                </Form.Item>

                <Form.Item
                  label="Cho phép trình ký"
                  name="allow_sign"
                  valuePropName="checked"
                >
                  <Switch size="small" />
                </Form.Item>

                <Form.Item label="Thời hạn (ngày)" name="deadline_days">
                  <InputNumber
                    min={0}
                    max={365}
                    placeholder="0"
                    addonAfter="ngày"
                    style={{ width: '100%' }}
                  />
                </Form.Item>
              </Form>

              <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
                <Button
                  type="primary"
                  size="small"
                  onClick={handleApplyProps}
                  style={{ flex: 1 }}
                >
                  Áp dụng
                </Button>
                <Button
                  danger
                  size="small"
                  icon={<DeleteOutlined />}
                  onClick={handleDeleteStep}
                  style={{ flex: 1 }}
                >
                  Xóa bước
                </Button>
              </div>
            </Card>
          </div>
        )}
      </div>
    </div>
  );
}

// ─── Page Export wrapped in ReactFlowProvider ─────────────────────────────────

export default function WorkflowDesignerPage() {
  return (
    <ReactFlowProvider>
      <DesignerContent />
    </ReactFlowProvider>
  );
}
