-- 090_video_courses.sql
-- Video / Course Platform module.
-- Storage buckets (manual — see deliver.sh checklist):
--   course-videos      PRIVATE  (signed URLs only)
--   course-thumbnails  PUBLIC   (thumbnails served directly)

-- ── Tables ────────────────────────────────────────────────────────────────────

CREATE TABLE courses (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug                   TEXT UNIQUE NOT NULL,
  title                  TEXT NOT NULL,
  description            TEXT,
  thumbnail_storage_path TEXT,           -- path in course-thumbnails PUBLIC bucket
  price_cents            INT  NOT NULL DEFAULT 0,
  stripe_price_id        TEXT,           -- null = free or subscription-only
  subscription_plan_ids  UUID[],         -- active sub in any of these grants access
  instructor_id          UUID REFERENCES auth.users(id),
  is_published           BOOLEAN NOT NULL DEFAULT FALSE,
  display_order          INT     NOT NULL DEFAULT 0,
  created_at             TIMESTAMPTZ DEFAULT now()
);

-- Sections (chapters)
CREATE TABLE course_sections (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id     UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  title         TEXT NOT NULL,
  display_order INT  NOT NULL DEFAULT 0
);

-- Lessons (individual videos)
-- course_id denormalized to avoid 2-level JOIN in get-lesson-video
CREATE TABLE course_lessons (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id           UUID NOT NULL REFERENCES courses(id)         ON DELETE CASCADE,
  section_id          UUID NOT NULL REFERENCES course_sections(id) ON DELETE CASCADE,
  title               TEXT NOT NULL,
  description         TEXT,
  video_storage_path  TEXT,            -- path in course-videos PRIVATE bucket
  duration_seconds    INT,
  is_preview          BOOLEAN NOT NULL DEFAULT FALSE,
  display_order       INT     NOT NULL DEFAULT 0
);

-- Enrollments — created PENDING at checkout, marked ACTIVE by stripe-dispatcher
CREATE TABLE course_enrollments (
  id                      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  course_id               UUID NOT NULL REFERENCES courses(id) ON DELETE CASCADE,
  client_email            TEXT NOT NULL,
  status                  TEXT NOT NULL DEFAULT 'pending', -- pending | active | cancelled
  enrolled_at             TIMESTAMPTZ,                     -- set when status → active
  stripe_checkout_session TEXT,
  expires_at              TIMESTAMPTZ,                     -- null = lifetime access
  UNIQUE (course_id, client_email)
);

-- Per-lesson progress (auth users only — guest previews don't track)
CREATE TABLE lesson_progress (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id       UUID NOT NULL REFERENCES course_lessons(id) ON DELETE CASCADE,
  client_email    TEXT NOT NULL,
  watched_seconds INT  NOT NULL DEFAULT 0,
  completed_at    TIMESTAMPTZ,
  updated_at      TIMESTAMPTZ DEFAULT now(),
  UNIQUE (lesson_id, client_email)
);

-- ── Indexes ───────────────────────────────────────────────────────────────────

CREATE INDEX idx_course_lessons_course_id   ON course_lessons    (course_id);
CREATE INDEX idx_course_lessons_section_id  ON course_lessons    (section_id);
CREATE INDEX idx_course_enrollments_email   ON course_enrollments (client_email);
CREATE INDEX idx_lesson_progress_lesson_id  ON lesson_progress   (lesson_id);

-- ── Row Level Security ────────────────────────────────────────────────────────

ALTER TABLE courses             ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_sections     ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_lessons      ENABLE ROW LEVEL SECURITY;
ALTER TABLE course_enrollments  ENABLE ROW LEVEL SECURITY;
ALTER TABLE lesson_progress     ENABLE ROW LEVEL SECURITY;

-- Public can read published courses, their sections, and their lessons
CREATE POLICY "public_read_courses"
  ON courses         FOR SELECT USING (is_published = TRUE);

CREATE POLICY "public_read_sections"
  ON course_sections FOR SELECT USING (TRUE);

CREATE POLICY "public_read_lessons"
  ON course_lessons  FOR SELECT USING (TRUE);

-- Enrollments: master full access; clients read their own active enrollments
CREATE POLICY "master_enrollments"
  ON course_enrollments FOR ALL
  USING (auth.jwt() ->> 'role' = 'master');

CREATE POLICY "client_read_enrollment"
  ON course_enrollments FOR SELECT
  USING (client_email = auth.jwt() ->> 'email');

-- Progress: authenticated client read/write own rows
CREATE POLICY "client_progress"
  ON lesson_progress FOR ALL
  USING (client_email = auth.jwt() ->> 'email');

-- Master full write on content tables
CREATE POLICY "master_courses"
  ON courses         FOR ALL USING (auth.jwt() ->> 'role' = 'master');

CREATE POLICY "master_sections"
  ON course_sections FOR ALL USING (auth.jwt() ->> 'role' = 'master');

CREATE POLICY "master_lessons"
  ON course_lessons  FOR ALL USING (auth.jwt() ->> 'role' = 'master');
