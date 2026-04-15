import { Skeleton, Card } from 'antd';

export default function MainLoading() {
  return (
    <div style={{ padding: 0 }}>
      {/* Skeleton ti\u00eau \u0111\u1ec1 trang */}
      <Skeleton
        active
        title={{ width: '30%' }}
        paragraph={false}
        style={{ marginBottom: 20 }}
      />
      {/* Skeleton n\u1ed9i dung ch\u00ednh */}
      <Card style={{ borderRadius: 12 }}>
        <Skeleton active paragraph={{ rows: 8 }} />
      </Card>
    </div>
  );
}
