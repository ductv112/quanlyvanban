import type { ThemeConfig } from 'antd';

/**
 * Ant Design 5 Theme — Quản lý Văn bản
 * Phong cách: Professional Government / Corporate Dashboard
 * Primary: Deep Navy (#1B3A5C) — uy tín, chuyên nghiệp
 * Accent: Teal (#0891B2) — hiện đại, sáng
 */
export const appTheme: ThemeConfig = {
  token: {
    // Colors
    colorPrimary: '#1B3A5C',
    colorInfo: '#0891B2',
    colorSuccess: '#059669',
    colorWarning: '#D97706',
    colorError: '#DC2626',
    colorLink: '#0891B2',

    // Typography — Inter, 4-level scale
    fontFamily: "'Inter', -apple-system, BlinkMacSystemFont, sans-serif",
    fontSize: 14,
    fontSizeHeading1: 20,
    fontSizeHeading2: 20,
    fontSizeHeading3: 15,
    fontSizeHeading4: 15,
    fontSizeSM: 12,
    fontSizeLG: 15,
    fontWeightStrong: 600,

    // Text colors — slate hierarchy
    colorText: '#1E293B',
    colorTextSecondary: '#475569',
    colorTextTertiary: '#94A3B8',
    colorTextQuaternary: '#CBD5E1',

    // Border
    borderRadius: 8,
    borderRadiusLG: 12,
    borderRadiusSM: 6,

    // Spacing
    padding: 16,
    paddingLG: 24,
    paddingSM: 12,
    paddingXS: 8,

    // Shadows
    boxShadow: '0 2px 8px rgba(27, 58, 92, 0.06)',
    boxShadowSecondary: '0 6px 20px rgba(27, 58, 92, 0.1)',

    // Layout
    colorBgLayout: '#F0F2F5',
    colorBgContainer: '#FFFFFF',

    // Control
    controlHeight: 36,
    controlHeightLG: 40,
    controlHeightSM: 28,
  },
  components: {
    Layout: {
      siderBg: '#0F1A2E',
      headerBg: '#FFFFFF',
      bodyBg: '#F0F2F5',
      triggerBg: '#1B3A5C',
    },
    Menu: {
      darkItemBg: '#0F1A2E',
      darkItemSelectedBg: 'rgba(8, 145, 178, 0.15)',
      darkItemColor: 'rgba(255, 255, 255, 0.55)',
      darkItemHoverBg: 'rgba(255, 255, 255, 0.06)',
      darkItemHoverColor: '#FFFFFF',
      darkItemSelectedColor: '#FFFFFF',
      itemBorderRadius: 6,
      iconSize: 17,
      collapsedIconSize: 19,
      itemMarginInline: 8,
      itemHeight: 40,
    },
    Button: {
      primaryShadow: '0 2px 4px rgba(27, 58, 92, 0.2)',
      fontWeight: 600,
      dangerColor: '#FFFFFF',
      dangerShadow: '0 2px 4px rgba(220, 38, 38, 0.2)',
    },
    Card: {
      borderRadiusLG: 12,
      paddingLG: 20,
    },
    Table: {
      headerBg: '#F8FAFC',
      headerColor: '#1B3A5C',
      headerSortActiveBg: '#EEF2F7',
      rowHoverBg: '#F0F7FF',
      borderColor: '#E8ECF1',
      headerBorderRadius: 8,
    },
    Tag: {
      borderRadiusSM: 4,
    },
    Input: {
      activeBorderColor: '#0891B2',
      hoverBorderColor: '#1B3A5C',
    },
    Select: {
      optionSelectedBg: '#EFF8FF',
    },
    Tabs: {
      inkBarColor: '#0891B2',
      itemSelectedColor: '#1B3A5C',
      itemHoverColor: '#0891B2',
    },
    Breadcrumb: {
      linkColor: '#64748B',
      lastItemColor: '#1B3A5C',
    },
  },
};
