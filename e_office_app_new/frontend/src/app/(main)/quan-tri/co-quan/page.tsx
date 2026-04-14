'use client';

import React, { useState, useEffect, useCallback } from 'react';
import {
  Card, Row, Col, Form, Input, Select, Switch, Button, Spin, App,
} from 'antd';
import {
  BankOutlined, SaveOutlined,
} from '@ant-design/icons';
import { api } from '@/lib/api';
import { useAuthStore } from '@/stores/auth.store';

export default function OrganizationPage() {
  const { message } = App.useApp();
  const user = useAuthStore((s) => s.user);
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form] = Form.useForm();

  const fetchData = useCallback(async () => {
    if (!user?.unitId) return;
    setLoading(true);
    try {
      const { data: res } = await api.get('/quan-tri/co-quan', {
        params: { unit_id: user.unitId },
      });
      if (res.data) {
        form.setFieldsValue(res.data);
      }
    } catch (err: any) {
      message.error(err?.response?.data?.message || 'Lỗi tải thông tin cơ quan');
    } finally {
      setLoading(false);
    }
  }, [user?.unitId, form, message]);

  useEffect(() => {
    fetchData();
  }, [fetchData]);

  const setBackendFieldError = (errorMessage: string): boolean => {
    const fieldErrorMap: Record<string, string> = {
      'Đơn vị không tồn tại': 'unit_id',
      'Mã cơ quan không được vượt quá 20 ký tự': 'code',
      'Tên cơ quan không được vượt quá 200 ký tự': 'name',
      'Email không được vượt quá 100 ký tự': 'email',
      'Số điện thoại không được vượt quá 20 ký tự': 'phone',
    };
    const fieldName = fieldErrorMap[errorMessage];
    if (fieldName) {
      form.setFields([{ name: fieldName, errors: [errorMessage] }]);
      return true;
    }
    return false;
  };

  const handleSave = async () => {
    try {
      const values = await form.validateFields();
      setSaving(true);
      await api.put('/quan-tri/co-quan', values);
      message.success('Lưu thông tin cơ quan thành công');
    } catch (err: any) {
      if (err?.response?.data?.message) {
        const mapped = setBackendFieldError(err.response.data.message);
        if (!mapped) {
          message.error(err.response.data.message);
        }
      }
    } finally {
      setSaving(false);
    }
  };

  return (
    <div>
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ fontSize: 22, fontWeight: 700, color: '#1B3A5C', margin: '0 0 4px 0' }}>
          Thông tin cơ quan
        </h2>
        <p style={{ fontSize: 14, color: '#64748b', margin: 0 }}>
          Cập nhật thông tin cơ quan, đơn vị chủ quản
        </p>
      </div>

      <Card
        variant="borderless"
        style={{ borderRadius: 12, boxShadow: '0 2px 8px rgba(27,58,92,0.06)' }}
        title={
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <BankOutlined style={{ color: '#0891B2' }} />
            <span style={{ fontWeight: 600, color: '#1B3A5C' }}>Thông tin cơ quan</span>
          </div>
        }
        extra={
          <Button
            type="primary"
            icon={<SaveOutlined />}
            loading={saving}
            onClick={handleSave}
            style={{ borderRadius: 8 }}
          >
            Lưu thông tin
          </Button>
        }
      >
        <Spin spinning={loading}>
          <Form form={form} layout="vertical" autoComplete="off" validateTrigger="onSubmit">
            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  label="Mã cơ quan"
                  name="code"
                  rules={[{ required: true, message: 'Nhập mã cơ quan' }]}
                >
                  <Input placeholder="VD: UBND-HCM" maxLength={20} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  label="Tên cơ quan"
                  name="name"
                  rules={[{ required: true, message: 'Nhập tên cơ quan' }]}
                >
                  <Input placeholder="VD: UBND Thành phố Hồ Chí Minh" maxLength={200} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Col>
            </Row>

            <Row gutter={16}>
              <Col span={24}>
                <Form.Item label="Địa chỉ" name="address">
                  <Input placeholder="Nhập địa chỉ cơ quan" maxLength={500} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Col>
            </Row>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item label="Số điện thoại" name="phone" rules={[{ pattern: /^[0-9+\-\s()]*$/, message: 'Số điện thoại không hợp lệ' }]}>
                  <Input placeholder="Nhập số điện thoại" maxLength={20} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item label="Fax" name="fax" rules={[{ pattern: /^[0-9+\-\s()]*$/, message: 'Số fax không hợp lệ' }]}>
                  <Input placeholder="Nhập số fax" maxLength={20} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Col>
            </Row>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  label="Email"
                  name="email"
                  rules={[{ type: 'email', message: 'Email không hợp lệ' }]}
                >
                  <Input placeholder="Nhập email" maxLength={100} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  label="Email văn bản"
                  name="doc_email"
                  rules={[{ type: 'email', message: 'Email không hợp lệ' }]}
                >
                  <Input placeholder="Email nhận/gửi văn bản điện tử" maxLength={100} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Col>
            </Row>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item label="Thư ký" name="secretary">
                  <Input placeholder="Nhập tên thư ký" maxLength={200} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item label="Số chủ tịch" name="chairman_number">
                  <Input placeholder="Nhập số chủ tịch" maxLength={20} style={{ borderRadius: 8 }} />
                </Form.Item>
              </Col>
            </Row>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item label="Cấp cơ quan" name="org_level">
                  <Select
                    placeholder="Chọn cấp cơ quan"
                    allowClear
                    options={[
                      { value: 1, label: 'Cấp tỉnh' },
                      { value: 2, label: 'Cấp huyện' },
                      { value: 3, label: 'Cấp xã' },
                    ]}
                    style={{ borderRadius: 8 }}
                  />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  label="Tham gia trao đổi văn bản điện tử"
                  name="is_edoc_exchange"
                  valuePropName="checked"
                >
                  <Switch checkedChildren="Có" unCheckedChildren="Không" />
                </Form.Item>
              </Col>
            </Row>
          </Form>
        </Spin>
      </Card>
    </div>
  );
}
