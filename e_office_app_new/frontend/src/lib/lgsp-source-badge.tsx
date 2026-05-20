'use client';

import React from 'react';
import { Tag, Tooltip, Select } from 'antd';
import { ApiOutlined, EditOutlined, TeamOutlined } from '@ant-design/icons';

// ============================================================
// LGSP Source Badge + Filter — helper dung chung cho Van ban den (Phase 35-04)
// REQ: LGSP-RECV-05
//
// Su dung tai:
//   - frontend/src/app/(main)/van-ban-den/page.tsx    (list rows + filter dropdown)
//   - frontend/src/app/(main)/van-ban-den/[id]/page.tsx (detail "Nguon LGSP" section)
//
// Source types (per enum edoc.doc_source_type):
//   'manual'         → Tao thu cong boi van thu (default)
//   'internal'       → Sinh tu dong tu "Gui noi bo" (Phase 17 + Phase 19)
//   'external_lgsp'  → Nhap tu truc LGSP (Phase 35 worker)
// ============================================================

export type DocSourceType = 'manual' | 'internal' | 'external_lgsp';

interface LgspSourceBadgeProps {
  sourceType: DocSourceType | string | null | undefined;
  lgspSenderOrgCode?: string | null;
  publishUnit?: string | null;
  /**
   * onlyShowLgsp=true (mac dinh, dung cho list column):
   *   chi render Tag mau xanh "LGSP" khi sourceType='external_lgsp', cac source khac → null.
   * onlyShowLgsp=false (dung cho detail header hoac filter preview):
   *   render Tag tuong ung cho ca 3 source ('Noi bo' / 'LGSP' / 'Thu cong').
   */
  onlyShowLgsp?: boolean;
}

/**
 * Tag hien thi nguon van ban den. Mac dinh chi render khi sourceType='external_lgsp' (list).
 */
export function LgspSourceBadge(props: LgspSourceBadgeProps): React.ReactElement | null {
  const { sourceType, lgspSenderOrgCode, publishUnit, onlyShowLgsp = true } = props;

  if (sourceType === 'external_lgsp') {
    const tooltipText = lgspSenderOrgCode
      ? `${publishUnit ?? 'Cơ quan ngoài'} (${lgspSenderOrgCode})`
      : (publishUnit ?? 'Văn bản từ trục LGSP');
    return (
      <Tooltip title={tooltipText}>
        <Tag color="blue" icon={<ApiOutlined />} style={{ marginInlineEnd: 0 }}>
          LGSP
        </Tag>
      </Tooltip>
    );
  }

  if (onlyShowLgsp) return null;

  if (sourceType === 'internal') {
    return (
      <Tag color="green" icon={<TeamOutlined />} style={{ marginInlineEnd: 0 }}>
        Nội bộ
      </Tag>
    );
  }

  if (sourceType === 'manual') {
    return (
      <Tag color="default" icon={<EditOutlined />} style={{ marginInlineEnd: 0 }}>
        Thủ công
      </Tag>
    );
  }

  return null;
}

interface LgspSourceFilterProps {
  value: DocSourceType | null;
  onChange: (next: DocSourceType | null) => void;
  style?: React.CSSProperties;
}

/**
 * Dropdown filter 4 lua chon (Tat ca nguon / Noi bo / LGSP / Thu cong).
 * Backend nhan query param `source_type` la 1 trong 3 enum value (manual|internal|external_lgsp)
 * hoac empty → "Tat ca nguon".
 */
export function LgspSourceFilter(props: LgspSourceFilterProps): React.ReactElement {
  const { value, onChange, style } = props;
  return (
    <Select
      allowClear
      placeholder="Tất cả nguồn"
      value={value ?? undefined}
      onChange={(next) => onChange((next as DocSourceType | undefined) ?? null)}
      style={{ minWidth: 160, ...style }}
      options={[
        { value: 'internal', label: 'Nội bộ' },
        { value: 'external_lgsp', label: 'LGSP' },
        { value: 'manual', label: 'Thủ công' },
      ]}
    />
  );
}
