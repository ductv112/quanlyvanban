/**
 * Sprint 5 — Seed Data (Node.js)
 * Tạo dữ liệu mẫu cho Hồ sơ công việc (HSCV) + Quy trình xử lý
 * Chạy: node seed_sprint5.js
 *
 * Yêu cầu: Backend đang chạy tại http://localhost:4000
 * Trước khi chạy:
 *   psql -f ../database/migrations/010_sprint5_handling_doc_sps.sql
 *   psql -f ../database/migrations/011_sprint6_workflow_tables_sps.sql
 */
const BASE = 'http://localhost:4000';

async function main() {
  // --- Đăng nhập ---
  console.log('--- ĐĂNG NHẬP ---');
  const loginRes = await fetch(`${BASE}/api/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ username: 'admin', password: 'Admin@123' }),
  });
  const { data: loginData } = await loginRes.json();
  if (!loginData?.accessToken) {
    throw new Error('Đăng nhập thất bại — kiểm tra backend đang chạy');
  }
  const TOKEN = loginData.accessToken;
  const AUTH = { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' };

  const post = (url, body) =>
    fetch(`${BASE}${url}`, { method: 'POST', headers: AUTH, body: JSON.stringify(body) }).then(r => r.json());
  const get = (url) =>
    fetch(`${BASE}${url}`, { headers: AUTH }).then(r => r.json());
  const patch = (url, body = {}) =>
    fetch(`${BASE}${url}`, { method: 'PATCH', headers: AUTH, body: JSON.stringify(body) }).then(r => r.json());

  console.log('Đã đăng nhập thành công');

  // ======================================================
  // 1. LẤY STAFF IDs ĐÃ TỒN TẠI
  // ======================================================
  console.log('\n--- LẤY DANH SÁCH CÁN BỘ ---');
  const staffRes = await get('/api/quan-tri/nguoi-dung?page=1&page_size=20');
  const staffList = staffRes.data || [];
  const staffIds = staffList.map(s => s.id).filter(Boolean);

  if (staffIds.length === 0) {
    console.log('  Cảnh báo: Không tìm thấy cán bộ. Dùng ID mặc định 1, 2, 3');
    staffIds.push(1, 2, 3);
  } else {
    console.log(`  Tìm thấy ${staffIds.length} cán bộ: ${staffIds.slice(0, 5).join(', ')}...`);
  }

  const s1 = staffIds[0] ?? 1;
  const s2 = staffIds[1] ?? 1;
  const s3 = staffIds[2] ?? 1;
  const s4 = staffIds[3] ?? 1;

  // ======================================================
  // 2. QUY TRÌNH XỬ LÝ (doc_flows)
  // ======================================================
  console.log('\n--- TẠO QUY TRÌNH XỬ LÝ ---');

  let flowId1 = null;
  let flowId2 = null;

  // Kiểm tra quy trình đã tồn tại chưa
  const existingFlows = await get('/api/quan-tri/quy-trinh');
  const flows = existingFlows.data || [];

  const flow1Exists = flows.find(f => f.name === 'Quy trình xử lý văn bản thông thường');
  const flow2Exists = flows.find(f => f.name === 'Quy trình xử lý văn bản mật');

  if (flow1Exists) {
    flowId1 = flow1Exists.id;
    console.log(`  Quy trình 1 đã tồn tại: id=${flowId1}`);
  } else {
    const r1 = await post('/api/quan-tri/quy-trinh', {
      name: 'Quy trình xử lý văn bản thông thường',
      version: '1.0',
      is_active: true,
    });
    if (r1.success || r1.id) {
      flowId1 = r1.id;
      console.log(`  Tạo quy trình 1: id=${flowId1}`);
    } else {
      console.log(`  Lỗi tạo quy trình 1: ${r1.message}`);
    }
  }

  if (flow2Exists) {
    flowId2 = flow2Exists.id;
    console.log(`  Quy trình 2 đã tồn tại: id=${flowId2}`);
  } else {
    const r2 = await post('/api/quan-tri/quy-trinh', {
      name: 'Quy trình xử lý văn bản mật',
      version: '1.0',
      is_active: true,
    });
    if (r2.success || r2.id) {
      flowId2 = r2.id;
      console.log(`  Tạo quy trình 2: id=${flowId2}`);
    } else {
      console.log(`  Lỗi tạo quy trình 2: ${r2.message}`);
    }
  }

  // ======================================================
  // 3. BƯỚC QUY TRÌNH (doc_flow_steps) — Cho quy trình 1
  // ======================================================
  let stepStartId = null;
  let stepTiepNhanId = null;
  let stepXuLyId = null;
  let stepPheDuyetId = null;
  let stepEndId = null;

  if (flowId1) {
    console.log(`\n--- TẠO BƯỚC QUY TRÌNH (flow_id=${flowId1}) ---`);

    // Kiểm tra bước đã tồn tại
    const existingDetail = await get(`/api/quan-tri/quy-trinh/${flowId1}/full`);
    const existingSteps = existingDetail.data?.steps || [];

    if (existingSteps.length > 0) {
      console.log(`  Đã có ${existingSteps.length} bước — bỏ qua tạo bước`);
      stepStartId = existingSteps.find(s => s.step_type === 'start')?.id;
      stepEndId = existingSteps.find(s => s.step_type === 'end')?.id;
      const processSteps = existingSteps.filter(s => s.step_type === 'process');
      stepTiepNhanId = processSteps[0]?.id;
      stepXuLyId = processSteps[1]?.id;
      stepPheDuyetId = processSteps[2]?.id;
    } else {
      // Bước 1: Start
      const rStart = await post(`/api/quan-tri/quy-trinh/${flowId1}/steps`, {
        step_name: 'Bắt đầu',
        step_order: 0,
        step_type: 'start',
        allow_sign: false,
        deadline_days: 0,
        position_x: 250,
        position_y: 50,
      });
      stepStartId = rStart.id;
      console.log(`  Bước Start: id=${stepStartId}`);

      // Bước 2: Tiếp nhận
      const rTiepNhan = await post(`/api/quan-tri/quy-trinh/${flowId1}/steps`, {
        step_name: 'Tiếp nhận',
        step_order: 1,
        step_type: 'process',
        allow_sign: false,
        deadline_days: 2,
        position_x: 250,
        position_y: 150,
      });
      stepTiepNhanId = rTiepNhan.id;
      console.log(`  Bước Tiếp nhận: id=${stepTiepNhanId}`);

      // Bước 3: Xử lý
      const rXuLy = await post(`/api/quan-tri/quy-trinh/${flowId1}/steps`, {
        step_name: 'Xử lý',
        step_order: 2,
        step_type: 'process',
        allow_sign: false,
        deadline_days: 5,
        position_x: 250,
        position_y: 250,
      });
      stepXuLyId = rXuLy.id;
      console.log(`  Bước Xử lý: id=${stepXuLyId}`);

      // Bước 4: Phê duyệt
      const rPheDuyet = await post(`/api/quan-tri/quy-trinh/${flowId1}/steps`, {
        step_name: 'Phê duyệt',
        step_order: 3,
        step_type: 'process',
        allow_sign: true,
        deadline_days: 3,
        position_x: 250,
        position_y: 350,
      });
      stepPheDuyetId = rPheDuyet.id;
      console.log(`  Bước Phê duyệt: id=${stepPheDuyetId}`);

      // Bước 5: End
      const rEnd = await post(`/api/quan-tri/quy-trinh/${flowId1}/steps`, {
        step_name: 'Kết thúc',
        step_order: 4,
        step_type: 'end',
        allow_sign: false,
        deadline_days: 0,
        position_x: 250,
        position_y: 450,
      });
      stepEndId = rEnd.id;
      console.log(`  Bước End: id=${stepEndId}`);

      // ======================================================
      // 4. LIÊN KẾT BƯỚC (doc_flow_step_links)
      // ======================================================
      console.log('\n--- TẠO LIÊN KẾT BƯỚC ---');

      const links = [
        { from: stepStartId, to: stepTiepNhanId, label: 'Start -> Tiếp nhận' },
        { from: stepTiepNhanId, to: stepXuLyId, label: 'Tiếp nhận -> Xử lý' },
        { from: stepXuLyId, to: stepPheDuyetId, label: 'Xử lý -> Phê duyệt' },
        { from: stepPheDuyetId, to: stepEndId, label: 'Phê duyệt -> End' },
      ];

      for (const link of links) {
        if (!link.from || !link.to) {
          console.log(`  Bỏ qua liên kết ${link.label} (step ID null)`);
          continue;
        }
        const r = await post('/api/quan-tri/quy-trinh/step-links', {
          from_step_id: link.from,
          to_step_id: link.to,
        });
        if (r.success || r.id) {
          console.log(`  Liên kết: ${link.label} — id=${r.id}`);
        } else {
          console.log(`  Liên kết ${link.label}: ${r.message || 'đã tồn tại'}`);
        }
      }
    }
  }

  // ======================================================
  // 5. HỒ SƠ CÔNG VIỆC (handling_docs)
  // ======================================================
  console.log('\n--- TẠO HỒ SƠ CÔNG VIỆC ---');

  const now = new Date();
  const daysAgo = (n) => new Date(now.getTime() - n * 86400000).toISOString();
  const daysLater = (n) => new Date(now.getTime() + n * 86400000).toISOString();

  const hscvList = [
    {
      name: 'Hồ sơ xử lý công văn về triển khai Chính phủ điện tử',
      comments: 'Ưu tiên xử lý trước 15/4/2026',
      start_date: daysAgo(15),
      end_date: daysLater(5),
      curator_id: s1,
      signer_id: s2,
      workflow_id: flowId1,
      _status: 1,
      _progress: 40,
    },
    {
      name: 'Hồ sơ phê duyệt kế hoạch CNTT năm 2026',
      comments: 'Báo cáo Ban Giám đốc',
      start_date: daysAgo(10),
      end_date: daysLater(10),
      curator_id: s2,
      signer_id: s1,
      workflow_id: flowId1,
      _status: 2,
      _progress: 70,
    },
    {
      name: 'Hồ sơ xét duyệt ngân sách mua sắm thiết bị văn phòng',
      start_date: daysAgo(20),
      end_date: daysLater(2),
      curator_id: s1,
      signer_id: s3,
      _status: 3,
      _progress: 90,
    },
    {
      name: 'Hồ sơ kiểm tra an toàn thông tin hạ tầng mạng',
      comments: 'Gấp — hạn nội tuần',
      start_date: daysAgo(5),
      end_date: daysLater(1),
      curator_id: s3,
      signer_id: s2,
      workflow_id: flowId2,
      _status: 1,
      _progress: 20,
    },
    {
      name: 'Hồ sơ tổ chức hội nghị cải cách hành chính quý II/2026',
      start_date: daysAgo(8),
      end_date: daysLater(7),
      curator_id: s2,
      signer_id: s4,
      _status: 0,
      _progress: 0,
    },
    {
      name: 'Hồ sơ xử lý khiếu nại công dân tháng 4/2026',
      comments: 'Theo dõi sát tiến độ',
      start_date: daysAgo(3),
      end_date: daysLater(14),
      curator_id: s4,
      signer_id: s1,
      _status: 1,
      _progress: 15,
    },
    {
      name: 'Hồ sơ hoàn thành — Quyết toán ngân sách quý I/2026',
      start_date: daysAgo(30),
      end_date: daysAgo(2),
      curator_id: s1,
      signer_id: s2,
      _status: 4,
      _progress: 100,
    },
    {
      name: 'Hồ sơ từ chối — Đề xuất thuê ngoài dịch vụ CNTT',
      comments: 'Không phù hợp quy định hiện hành',
      start_date: daysAgo(25),
      end_date: daysAgo(5),
      curator_id: s2,
      signer_id: s3,
      _status: -1,
      _progress: 0,
    },
    {
      name: 'Hồ sơ trả về — Dự thảo quy chế bảo mật thông tin',
      comments: 'Cần bổ sung chương 3',
      start_date: daysAgo(12),
      end_date: daysLater(3),
      curator_id: s3,
      signer_id: s1,
      _status: -2,
      _progress: 50,
    },
    {
      name: 'Hồ sơ đang xử lý — Phân công nhiệm vụ cán bộ mới',
      start_date: daysAgo(2),
      end_date: daysLater(20),
      curator_id: s1,
      signer_id: s4,
      _status: 1,
      _progress: 10,
    },
    {
      name: 'Hồ sơ chờ duyệt — Kế hoạch đào tạo nhân lực CNTT 2026',
      start_date: daysAgo(7),
      end_date: daysLater(8),
      curator_id: s4,
      signer_id: s2,
      _status: 2,
      _progress: 80,
    },
    {
      name: 'Hồ sơ đã duyệt — Báo cáo tổng kết công tác văn thư',
      start_date: daysAgo(18),
      end_date: daysAgo(1),
      curator_id: s2,
      signer_id: s1,
      _status: 3,
      _progress: 95,
    },
    {
      name: 'Hồ sơ mới — Triển khai chữ ký số toàn đơn vị',
      start_date: daysLater(1),
      end_date: daysLater(30),
      curator_id: s3,
      signer_id: s4,
      _status: 0,
      _progress: 0,
    },
    {
      name: 'Hồ sơ hoàn thành — Tổng kết năm 2025',
      start_date: daysAgo(40),
      end_date: daysAgo(10),
      curator_id: s1,
      signer_id: s2,
      _status: 4,
      _progress: 100,
    },
    {
      name: 'Hồ sơ đang xử lý — Rà soát hệ thống thông tin nội bộ',
      comments: 'Phối hợp phòng CNTT và văn thư',
      start_date: daysAgo(6),
      end_date: daysLater(4),
      curator_id: s2,
      signer_id: s3,
      workflow_id: flowId2,
      _status: 1,
      _progress: 55,
    },
  ];

  const hscvIds = [];
  for (const hscv of hscvList) {
    const { _status, _progress, ...body } = hscv;
    // Bỏ workflow_id null
    if (!body.workflow_id) delete body.workflow_id;
    if (!body.curator_id) delete body.curator_id;
    if (!body.signer_id) delete body.signer_id;

    const r = await post('/api/ho-so-cong-viec', body);
    if (r.success && r.data?.id) {
      hscvIds.push({ id: r.data.id, status: _status, progress: _progress });
      console.log(`  Tạo HSCV id=${r.data.id}: ${hscv.name.substring(0, 50)}...`);
    } else {
      console.log(`  Lỗi tạo HSCV "${hscv.name.substring(0, 40)}...": ${r.message}`);
    }
  }

  // Cập nhật trạng thái + tiến độ qua PATCH
  console.log('\n--- CẬP NHẬT TRẠNG THÁI HSCV ---');
  for (const { id, status, progress } of hscvIds) {
    if (status !== 0 || progress !== 0) {
      const r = await patch(`/api/ho-so-cong-viec/${id}/cap-nhat-trang-thai`, { status, progress });
      if (r.success) {
        console.log(`  Cập nhật id=${id}: status=${status}, progress=${progress}%`);
      } else {
        // Endpoint có thể không tồn tại — bỏ qua lỗi nhẹ
        console.log(`  Bỏ qua cập nhật trạng thái id=${id} (${r.message || 'endpoint không hỗ trợ'})`);
      }
    }
  }

  // ======================================================
  // 6. HSCV CON (2 records với parent_id)
  // ======================================================
  if (hscvIds.length >= 2) {
    console.log('\n--- TẠO HSCV CON ---');

    const parentId1 = hscvIds[0].id;
    const parentId2 = hscvIds[1].id;

    const children = [
      {
        name: 'HSCV con — Tiểu ban triển khai e-Office module văn bản đến',
        parent_id: parentId1,
        start_date: daysAgo(10),
        end_date: daysLater(3),
        curator_id: s2,
      },
      {
        name: 'HSCV con — Tiểu ban nghiệm thu hệ thống CNTT 2026',
        parent_id: parentId2,
        start_date: daysAgo(5),
        end_date: daysLater(8),
        curator_id: s3,
      },
    ];

    for (const child of children) {
      const r = await post('/api/ho-so-cong-viec', child);
      if (r.success && r.data?.id) {
        hscvIds.push({ id: r.data.id, status: 0, progress: 0 });
        console.log(`  Tạo HSCV con id=${r.data.id} (parent=${child.parent_id}): ${child.name.substring(0, 50)}`);
      } else {
        console.log(`  Lỗi tạo HSCV con: ${r.message}`);
      }
    }
  }

  // ======================================================
  // 7. PHÂN CÔNG CÁN BỘ (staff_handling_docs)
  // ======================================================
  if (hscvIds.length > 0) {
    console.log('\n--- PHÂN CÔNG CÁN BỘ ---');

    const assignments = [
      { hscvIdx: 0, staffIds: [s1, s2], role: 1 },
      { hscvIdx: 0, staffIds: [s3], role: 2 },
      { hscvIdx: 1, staffIds: [s2], role: 1 },
      { hscvIdx: 1, staffIds: [s3, s4], role: 2 },
      { hscvIdx: 2, staffIds: [s1], role: 1 },
      { hscvIdx: 3, staffIds: [s3, s2], role: 1 },
      { hscvIdx: 4, staffIds: [s2], role: 1 },
      { hscvIdx: 5, staffIds: [s4, s1], role: 2 },
      { hscvIdx: 6, staffIds: [s1], role: 1 },
      { hscvIdx: 7, staffIds: [s3], role: 1 },
    ];

    for (const { hscvIdx, staffIds: ids, role } of assignments) {
      if (hscvIdx >= hscvIds.length) continue;
      const docId = hscvIds[hscvIdx].id;
      const uniqueIds = [...new Set(ids.filter(Boolean))];
      if (uniqueIds.length === 0) continue;

      const r = await post(`/api/ho-so-cong-viec/${docId}/phan-cong`, {
        staff_ids: uniqueIds,
        role_type: role,
      });
      if (r.success) {
        console.log(`  Phân công HSCV id=${docId} role=${role}: staff ${uniqueIds.join(',')}`);
      } else {
        console.log(`  Lỗi phân công HSCV id=${docId}: ${r.message}`);
      }
    }
  }

  // ======================================================
  // 8. Ý KIẾN XỬ LÝ (opinion_handling_docs)
  // ======================================================
  if (hscvIds.length > 0) {
    console.log('\n--- TẠO Ý KIẾN XỬ LÝ ---');

    const opinions = [
      { hscvIdx: 0, content: 'Văn bản đã được kiểm tra đầy đủ, đề nghị chuyển bước phê duyệt.' },
      { hscvIdx: 0, content: 'Cần bổ sung thêm phụ lục kỹ thuật trước khi hoàn thiện.' },
      { hscvIdx: 1, content: 'Kế hoạch phù hợp với định hướng chiến lược CNTT đơn vị.' },
      { hscvIdx: 2, content: 'Đã xem xét hồ sơ, đồng ý phê duyệt ngân sách theo đề xuất.' },
      { hscvIdx: 3, content: 'Phát hiện 2 lỗ hổng bảo mật cần khắc phục ngay.' },
      { hscvIdx: 5, content: 'Đề nghị xem xét bổ sung thêm nhân lực xử lý hồ sơ.' },
    ];

    for (const { hscvIdx, content } of opinions) {
      if (hscvIdx >= hscvIds.length) continue;
      const docId = hscvIds[hscvIdx].id;
      const r = await post(`/api/ho-so-cong-viec/${docId}/y-kien`, { content });
      if (r.success) {
        console.log(`  Ý kiến HSCV id=${docId}: "${content.substring(0, 50)}..."`);
      } else {
        console.log(`  Lỗi thêm ý kiến HSCV id=${docId}: ${r.message}`);
      }
    }
  }

  // ======================================================
  // 9. LIÊN KẾT VĂN BẢN (handling_doc_links)
  // ======================================================
  if (hscvIds.length > 0) {
    console.log('\n--- TẠO LIÊN KẾT VĂN BẢN ---');

    // Lấy VB đến, VB đi đã có từ seed trước
    const incomingRes = await get('/api/van-ban-den?page=1&page_size=5');
    const outgoingRes = await get('/api/van-ban-di?page=1&page_size=5');
    const incomingDocs = incomingRes.data || [];
    const outgoingDocs = outgoingRes.data || [];

    let linkedCount = 0;

    if (incomingDocs.length > 0 && hscvIds.length > 0) {
      const r = await post(`/api/ho-so-cong-viec/${hscvIds[0].id}/lien-ket-van-ban`, {
        doc_type: 'incoming',
        doc_id: incomingDocs[0].id,
      });
      if (r.success) {
        console.log(`  Liên kết HSCV id=${hscvIds[0].id} ↔ VB đến id=${incomingDocs[0].id}`);
        linkedCount++;
      } else {
        console.log(`  Bỏ qua liên kết VB đến: ${r.message}`);
      }
    }

    if (incomingDocs.length > 1 && hscvIds.length > 1) {
      const r = await post(`/api/ho-so-cong-viec/${hscvIds[1].id}/lien-ket-van-ban`, {
        doc_type: 'incoming',
        doc_id: incomingDocs[1].id,
      });
      if (r.success) {
        console.log(`  Liên kết HSCV id=${hscvIds[1].id} ↔ VB đến id=${incomingDocs[1].id}`);
        linkedCount++;
      } else {
        console.log(`  Bỏ qua liên kết VB đến: ${r.message}`);
      }
    }

    if (outgoingDocs.length > 0 && hscvIds.length > 2) {
      const r = await post(`/api/ho-so-cong-viec/${hscvIds[2].id}/lien-ket-van-ban`, {
        doc_type: 'outgoing',
        doc_id: outgoingDocs[0].id,
      });
      if (r.success) {
        console.log(`  Liên kết HSCV id=${hscvIds[2].id} ↔ VB đi id=${outgoingDocs[0].id}`);
        linkedCount++;
      } else {
        console.log(`  Bỏ qua liên kết VB đi: ${r.message}`);
      }
    }

    if (outgoingDocs.length > 1 && hscvIds.length > 3) {
      const r = await post(`/api/ho-so-cong-viec/${hscvIds[3].id}/lien-ket-van-ban`, {
        doc_type: 'outgoing',
        doc_id: outgoingDocs[1].id,
      });
      if (r.success) {
        console.log(`  Liên kết HSCV id=${hscvIds[3].id} ↔ VB đi id=${outgoingDocs[1].id}`);
        linkedCount++;
      } else {
        console.log(`  Bỏ qua liên kết VB đi: ${r.message}`);
      }
    }

    if (linkedCount === 0) {
      console.log('  Không có VB đến/đi từ seed trước — bỏ qua liên kết');
    }
  }

  // ======================================================
  // TỔNG KẾT
  // ======================================================
  const hscvListRes = await get('/api/ho-so-cong-viec');
  const flowListRes = await get('/api/quan-tri/quy-trinh');

  console.log('\n==========================================');
  console.log(` Tổng HSCV: ${hscvListRes.pagination?.total || hscvIds.length}`);
  console.log(` Tổng Quy trình: ${(flowListRes.data || []).length}`);
  console.log('==========================================');
  console.log(' Seed Sprint 5 hoàn tất!');
}

main().catch(e => {
  console.error('Lỗi:', e.message);
  process.exit(1);
});
