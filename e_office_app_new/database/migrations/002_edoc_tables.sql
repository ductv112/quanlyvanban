-- ============================================
-- MIGRATION 002: Bảng văn bản điện tử (edoc schema)
-- Core tables cho module Văn bản
-- ============================================

-- ==========================================
-- 1. SỔ VĂN BẢN (DocBook)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.doc_books (
  id          SERIAL PRIMARY KEY,
  unit_id     INT NOT NULL REFERENCES public.departments(id),
  type_id     SMALLINT NOT NULL,               -- 1=VB đến, 2=VB đi, 3=Dự thảo
  name        VARCHAR(200) NOT NULL,
  description TEXT,
  sort_order  INT DEFAULT 0,
  is_default  BOOLEAN DEFAULT FALSE,
  is_deleted  BOOLEAN DEFAULT FALSE,
  created_by  INT,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.doc_books IS 'Sổ văn bản: type_id 1=đến, 2=đi, 3=dự thảo';

-- ==========================================
-- 2. LOẠI VĂN BẢN (DocType)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.doc_types (
  id              SERIAL PRIMARY KEY,
  type_id         SMALLINT NOT NULL,             -- 1=QPPL, 2=Hành chính, 3=Khác
  code            VARCHAR(20) NOT NULL,          -- CV, NQ, QĐ, CT, QC...
  name            VARCHAR(200) NOT NULL,
  description     TEXT,
  sort_order      INT DEFAULT 0,
  notation_type   SMALLINT DEFAULT 0,            -- Kiểu đánh số ký hiệu
  is_default      BOOLEAN DEFAULT FALSE,
  is_deleted      BOOLEAN DEFAULT FALSE,
  created_by      INT,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.doc_types IS 'Loại văn bản: CV=Công văn, NQ=Nghị quyết, QĐ=Quyết định...';

INSERT INTO edoc.doc_types (type_id, code, name, sort_order) VALUES
  (2, 'CV', 'Công văn', 1),
  (1, 'NQ', 'Nghị quyết', 2),
  (1, 'QD', 'Quyết định', 3),
  (1, 'CT', 'Chỉ thị', 4),
  (1, 'QC', 'Quy chế', 5)
ON CONFLICT DO NOTHING;

-- ==========================================
-- 3. LĨNH VỰC VĂN BẢN (DocField)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.doc_fields (
  id          SERIAL PRIMARY KEY,
  unit_id     INT NOT NULL REFERENCES public.departments(id),
  code        VARCHAR(20) NOT NULL,
  name        VARCHAR(200) NOT NULL,
  sort_order  INT DEFAULT 0,
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.doc_fields IS 'Lĩnh vực văn bản theo đơn vị';

-- ==========================================
-- 4. VĂN BẢN ĐẾN (IncomingDoc)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.incoming_docs (
  id                BIGSERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id),

  -- Thông tin chính
  received_date     TIMESTAMPTZ,               -- Ngày đến
  number            INT,                       -- Số đến
  notation          VARCHAR(100),              -- Số ký hiệu
  document_code     VARCHAR(100),              -- Mã văn bản
  abstract          TEXT,                      -- Trích yếu nội dung
  publish_unit      VARCHAR(500),              -- Cơ quan phát hành
  publish_date      TIMESTAMPTZ,               -- Ngày phát hành
  signer            VARCHAR(200),              -- Người ký
  sign_date         TIMESTAMPTZ,               -- Ngày ký

  -- Phân loại
  doc_book_id       INT REFERENCES edoc.doc_books(id),
  doc_type_id       INT REFERENCES edoc.doc_types(id),
  doc_field_id      INT REFERENCES edoc.doc_fields(id),
  secret_id         SMALLINT DEFAULT 1,        -- 1=Thường, 2=Mật, 3=Tối mật, 4=Tuyệt mật
  urgent_id         SMALLINT DEFAULT 1,        -- 1=Thường, 2=Khẩn, 3=Hỏa tốc

  -- Số lượng
  number_paper      INT DEFAULT 1,             -- Số tờ
  number_copies     INT DEFAULT 1,             -- Số bản

  -- Xử lý
  expired_date      TIMESTAMPTZ,               -- Hạn xử lý
  recipients        TEXT,                      -- Nơi nhận (text)
  approver          VARCHAR(200),              -- Người duyệt
  approved          BOOLEAN DEFAULT FALSE,     -- Đã duyệt chưa

  -- Trạng thái
  is_handling       BOOLEAN DEFAULT FALSE,     -- Đã tạo HSCV chưa
  is_received_paper BOOLEAN DEFAULT FALSE,     -- Đã nhận bản giấy
  archive_status    BOOLEAN DEFAULT FALSE,     -- Đã lưu trữ

  -- Liên thông
  is_inter_doc      BOOLEAN DEFAULT FALSE,     -- Là VB liên thông
  inter_doc_id      INT,                       -- ID VB trên trục liên thông

  -- Audit
  created_by        INT NOT NULL REFERENCES public.staff(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_by        INT,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_incoming_docs_unit ON edoc.incoming_docs(unit_id, received_date DESC);
CREATE INDEX idx_incoming_docs_number ON edoc.incoming_docs(unit_id, number);
CREATE INDEX idx_incoming_docs_notation ON edoc.incoming_docs(notation);
CREATE INDEX idx_incoming_docs_search ON edoc.incoming_docs USING gin(abstract gin_trgm_ops);
-- Full-text search tiếng Việt (bỏ dấu)
CREATE INDEX idx_incoming_docs_fts ON edoc.incoming_docs USING gin(
  to_tsvector('simple', coalesce(unaccent(abstract), '') || ' ' || coalesce(unaccent(notation), '') || ' ' || coalesce(unaccent(publish_unit), ''))
);

COMMENT ON TABLE edoc.incoming_docs IS 'Văn bản đến — bảng chính';

-- ==========================================
-- 5. NGƯỜI NHẬN VĂN BẢN ĐẾN
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.user_incoming_docs (
  id              BIGSERIAL PRIMARY KEY,
  incoming_doc_id BIGINT NOT NULL REFERENCES edoc.incoming_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  is_read         BOOLEAN DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(incoming_doc_id, staff_id)
);

CREATE INDEX idx_user_incoming_docs_staff ON edoc.user_incoming_docs(staff_id, is_read);

-- ==========================================
-- 6. FILE ĐÍNH KÈM VĂN BẢN ĐẾN
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.attachment_incoming_docs (
  id              BIGSERIAL PRIMARY KEY,
  incoming_doc_id BIGINT NOT NULL REFERENCES edoc.incoming_docs(id) ON DELETE CASCADE,
  file_name       VARCHAR(500) NOT NULL,
  file_path       VARCHAR(1000) NOT NULL,       -- Path trên MinIO
  file_size       BIGINT DEFAULT 0,
  content_type    VARCHAR(100),
  sort_order      INT DEFAULT 0,
  created_by      INT REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 7. BÚT PHÊ LÃNH ĐẠO (LeaderNote)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.leader_notes (
  id              BIGSERIAL PRIMARY KEY,
  incoming_doc_id BIGINT NOT NULL REFERENCES edoc.incoming_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  content         TEXT NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 8. GHI CHÚ CÁ NHÂN (StaffNote — bookmark)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.staff_notes (
  id              BIGSERIAL PRIMARY KEY,
  doc_type        VARCHAR(20) NOT NULL,         -- 'incoming', 'outgoing', 'drafting'
  doc_id          BIGINT NOT NULL,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  note            TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(doc_type, doc_id, staff_id)
);

-- ==========================================
-- 9. VĂN BẢN ĐI / PHÁT HÀNH (OutgoingDoc)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.outgoing_docs (
  id                BIGSERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id),

  received_date     TIMESTAMPTZ,
  number            INT,
  sub_number        VARCHAR(20),
  notation          VARCHAR(100),
  document_code     VARCHAR(100),
  abstract          TEXT,

  -- Đơn vị soạn & phát hành
  drafting_unit_id  INT REFERENCES public.departments(id),
  drafting_user_id  INT REFERENCES public.staff(id),
  publish_unit_id   INT REFERENCES public.departments(id),
  publish_date      TIMESTAMPTZ,

  signer            VARCHAR(200),
  sign_date         TIMESTAMPTZ,
  expired_date      TIMESTAMPTZ,

  number_paper      INT DEFAULT 1,
  number_copies     INT DEFAULT 1,
  secret_id         SMALLINT DEFAULT 1,
  urgent_id         SMALLINT DEFAULT 1,

  recipients        TEXT,
  doc_book_id       INT REFERENCES edoc.doc_books(id),
  doc_type_id       INT REFERENCES edoc.doc_types(id),
  doc_field_id      INT REFERENCES edoc.doc_fields(id),

  approved          BOOLEAN DEFAULT FALSE,
  is_handling       BOOLEAN DEFAULT FALSE,
  archive_status    BOOLEAN DEFAULT FALSE,

  -- Liên thông
  is_inter_doc      BOOLEAN DEFAULT FALSE,
  inter_doc_id      BIGINT,

  -- Ký số
  is_digital_signed SMALLINT DEFAULT 0,        -- 0=chưa ký, 1=đã ký

  created_by        INT NOT NULL REFERENCES public.staff(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_by        INT,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_outgoing_docs_unit ON edoc.outgoing_docs(unit_id, received_date DESC);
CREATE INDEX idx_outgoing_docs_search ON edoc.outgoing_docs USING gin(abstract gin_trgm_ops);

COMMENT ON TABLE edoc.outgoing_docs IS 'Văn bản đi / phát hành';

-- ==========================================
-- 10. VĂN BẢN DỰ THẢO (DraftingDoc)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.drafting_docs (
  id                BIGSERIAL PRIMARY KEY,
  unit_id           INT NOT NULL REFERENCES public.departments(id),

  received_date     TIMESTAMPTZ,
  number            INT,
  sub_number        VARCHAR(20),
  notation          VARCHAR(100),
  abstract          TEXT,

  drafting_unit_id  INT REFERENCES public.departments(id),
  drafting_user_id  INT REFERENCES public.staff(id),
  publish_unit_id   INT REFERENCES public.departments(id),
  publish_date      TIMESTAMPTZ,

  signer            VARCHAR(200),
  sign_date         TIMESTAMPTZ,

  number_paper      INT DEFAULT 1,
  number_copies     INT DEFAULT 1,
  secret_id         SMALLINT DEFAULT 1,
  urgent_id         SMALLINT DEFAULT 1,

  recipients        TEXT,
  doc_book_id       INT REFERENCES edoc.doc_books(id),
  doc_type_id       INT REFERENCES edoc.doc_types(id),
  doc_field_id      INT REFERENCES edoc.doc_fields(id),

  approved          BOOLEAN DEFAULT FALSE,
  is_released       BOOLEAN DEFAULT FALSE,       -- Đã phát hành thành VB đi
  released_date     TIMESTAMPTZ,

  created_by        INT NOT NULL REFERENCES public.staff(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_by        INT,
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE edoc.drafting_docs IS 'Văn bản dự thảo — khi duyệt xong sẽ chuyển thành VB đi';

-- ==========================================
-- 11. FILE ĐÍNH KÈM VB ĐI + DỰ THẢO
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.attachment_outgoing_docs (
  id              BIGSERIAL PRIMARY KEY,
  outgoing_doc_id BIGINT NOT NULL REFERENCES edoc.outgoing_docs(id) ON DELETE CASCADE,
  file_name       VARCHAR(500) NOT NULL,
  file_path       VARCHAR(1000) NOT NULL,
  file_size       BIGINT DEFAULT 0,
  content_type    VARCHAR(100),
  sort_order      INT DEFAULT 0,
  created_by      INT REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS edoc.attachment_drafting_docs (
  id              BIGSERIAL PRIMARY KEY,
  drafting_doc_id BIGINT NOT NULL REFERENCES edoc.drafting_docs(id) ON DELETE CASCADE,
  file_name       VARCHAR(500) NOT NULL,
  file_path       VARCHAR(1000) NOT NULL,
  file_size       BIGINT DEFAULT 0,
  content_type    VARCHAR(100),
  sort_order      INT DEFAULT 0,
  created_by      INT REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 12. NGƯỜI NHẬN VB ĐI + DỰ THẢO
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.user_outgoing_docs (
  id              BIGSERIAL PRIMARY KEY,
  outgoing_doc_id BIGINT NOT NULL REFERENCES edoc.outgoing_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  is_read         BOOLEAN DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(outgoing_doc_id, staff_id)
);

CREATE TABLE IF NOT EXISTS edoc.user_drafting_docs (
  id              BIGSERIAL PRIMARY KEY,
  drafting_doc_id BIGINT NOT NULL REFERENCES edoc.drafting_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  is_read         BOOLEAN DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(drafting_doc_id, staff_id)
);

-- ==========================================
-- 13. HỒ SƠ CÔNG VIỆC (HandlingDoc)
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.handling_docs (
  id              BIGSERIAL PRIMARY KEY,
  unit_id         INT NOT NULL REFERENCES public.departments(id),
  department_id   INT REFERENCES public.departments(id),

  name            VARCHAR(500) NOT NULL,         -- Tên HSCV
  abstract        TEXT,                          -- Trích yếu
  comments        TEXT,                          -- Ghi chú
  doc_notation    VARCHAR(100),                  -- Số ký hiệu

  -- Phân loại
  doc_type_id     INT REFERENCES edoc.doc_types(id),
  doc_field_id    INT REFERENCES edoc.doc_fields(id),
  doc_book_id     INT REFERENCES edoc.doc_books(id),

  -- Thời hạn
  start_date      TIMESTAMPTZ,                   -- Ngày mở
  end_date        TIMESTAMPTZ,                   -- Hạn giải quyết
  received_date   TIMESTAMPTZ,

  -- Người liên quan
  curator         INT REFERENCES public.staff(id),  -- Người phụ trách
  signer          INT REFERENCES public.staff(id),  -- Lãnh đạo ký

  -- Trạng thái
  status          SMALLINT DEFAULT 0,            -- 0=Mới, 1=Đang xử lý, 2=Chờ duyệt, 3=Đã duyệt, 4=Hoàn thành, -1=Từ chối, -2=Trả về
  sign_status     SMALLINT DEFAULT 0,
  sign_date       TIMESTAMPTZ,
  progress        SMALLINT DEFAULT 0,            -- 0-100%

  -- Workflow
  workflow_id     INT,
  step            VARCHAR(50),                   -- Bước hiện tại

  -- Hoàn thành
  complete_user_id INT REFERENCES public.staff(id),
  complete_date    TIMESTAMPTZ,

  -- Đơn vị phát hành/soạn thảo
  publish_unit_id  INT REFERENCES public.departments(id),
  publish_name     VARCHAR(500),
  drafting_unit_id INT REFERENCES public.departments(id),
  number           INT,
  sub_number       VARCHAR(20),
  notation         VARCHAR(100),

  -- Liên kết
  parent_id       BIGINT REFERENCES edoc.handling_docs(id),  -- HSCV cha
  root_id         BIGINT,                        -- HSCV gốc
  is_from_doc     BOOLEAN DEFAULT FALSE,         -- Tạo từ văn bản đến

  -- Audit
  created_by      INT NOT NULL REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_by      INT,
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_handling_docs_unit ON edoc.handling_docs(unit_id, status, start_date DESC);
CREATE INDEX idx_handling_docs_curator ON edoc.handling_docs(curator);
CREATE INDEX idx_handling_docs_search ON edoc.handling_docs USING gin(name gin_trgm_ops);

COMMENT ON TABLE edoc.handling_docs IS 'Hồ sơ công việc — quản lý xử lý văn bản theo workflow';

-- ==========================================
-- 14. LIÊN KẾT HSCV ↔ VĂN BẢN
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.handling_doc_links (
  id              BIGSERIAL PRIMARY KEY,
  handling_doc_id BIGINT NOT NULL REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
  doc_type        VARCHAR(20) NOT NULL,          -- 'incoming', 'outgoing', 'drafting'
  doc_id          BIGINT NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(handling_doc_id, doc_type, doc_id)
);

-- ==========================================
-- 15. CÁN BỘ XỬ LÝ HSCV
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.staff_handling_docs (
  id              BIGSERIAL PRIMARY KEY,
  handling_doc_id BIGINT NOT NULL REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  role            SMALLINT DEFAULT 1,            -- 1=Phụ trách (Prim), 2=Phối hợp (Coordinator)
  step            VARCHAR(50),
  assigned_at     TIMESTAMPTZ DEFAULT NOW(),
  completed_at    TIMESTAMPTZ
);

CREATE INDEX idx_staff_handling_docs_staff ON edoc.staff_handling_docs(staff_id, handling_doc_id);

-- ==========================================
-- 16. Ý KIẾN XỬ LÝ HSCV
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.opinion_handling_docs (
  id              BIGSERIAL PRIMARY KEY,
  handling_doc_id BIGINT NOT NULL REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
  staff_id        INT NOT NULL REFERENCES public.staff(id),
  content         TEXT NOT NULL,
  attachment_path VARCHAR(1000),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- 17. FILE ĐÍNH KÈM HSCV
-- ==========================================
CREATE TABLE IF NOT EXISTS edoc.attachment_handling_docs (
  id              BIGSERIAL PRIMARY KEY,
  handling_doc_id BIGINT NOT NULL REFERENCES edoc.handling_docs(id) ON DELETE CASCADE,
  file_name       VARCHAR(500) NOT NULL,
  file_path       VARCHAR(1000) NOT NULL,
  file_size       BIGINT DEFAULT 0,
  content_type    VARCHAR(100),
  sort_order      INT DEFAULT 0,
  created_by      INT REFERENCES public.staff(id),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- ==========================================
-- TRIGGERS
-- ==========================================
CREATE TRIGGER trg_incoming_docs_updated_at
  BEFORE UPDATE ON edoc.incoming_docs
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();

CREATE TRIGGER trg_outgoing_docs_updated_at
  BEFORE UPDATE ON edoc.outgoing_docs
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();

CREATE TRIGGER trg_drafting_docs_updated_at
  BEFORE UPDATE ON edoc.drafting_docs
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();

CREATE TRIGGER trg_handling_docs_updated_at
  BEFORE UPDATE ON edoc.handling_docs
  FOR EACH ROW EXECUTE FUNCTION public.fn_update_timestamp();
