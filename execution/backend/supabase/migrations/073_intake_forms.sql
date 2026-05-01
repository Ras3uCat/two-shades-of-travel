-- 073_intake_forms.sql
-- Client intake form system.
-- intake_questions  — admin-managed question definitions
-- intake_responses  — one JSONB blob per booking (answers keyed by question id)

-- ── Intake questions ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.intake_questions (
  id            UUID    PRIMARY KEY DEFAULT gen_random_uuid(),
  label         TEXT    NOT NULL,
  field_type    TEXT    NOT NULL CHECK (field_type IN ('text', 'textarea', 'yesno', 'select')),
  options       TEXT[]  NOT NULL DEFAULT '{}',
  required      BOOLEAN NOT NULL DEFAULT false,
  display_order INTEGER NOT NULL DEFAULT 0,
  is_active     BOOLEAN NOT NULL DEFAULT true,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.intake_questions ENABLE ROW LEVEL SECURITY;

-- Unauthenticated clients need to read active questions to render the form
CREATE POLICY "public read active questions"
  ON public.intake_questions
  FOR SELECT
  USING (is_active = true);

-- Admins (master + staff) have full control over question definitions
CREATE POLICY "admin manage questions"
  ON public.intake_questions
  FOR ALL
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
       WHERE id = auth.uid() AND role IN ('master', 'staff')
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
       WHERE id = auth.uid() AND role IN ('master', 'staff')
    )
  );

-- ── Intake responses ──────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.intake_responses (
  id           UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id   UUID        NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
  answers      JSONB       NOT NULL DEFAULT '{}',
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (booking_id)
);

ALTER TABLE public.intake_responses ENABLE ROW LEVEL SECURITY;

-- Unauthenticated clients submit their answers right after booking (no auth token yet)
CREATE POLICY "submit intake"
  ON public.intake_responses
  FOR INSERT
  WITH CHECK (true);

-- Admins can read all responses
CREATE POLICY "admin read intake"
  ON public.intake_responses
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
       WHERE id = auth.uid() AND role IN ('master', 'staff')
    )
  );

-- Clients can read their own response (by booking id — kept simple: allow all authenticated).
-- A stricter policy would join bookings on client_email = auth.email(), but that
-- requires the client to be signed in. The permissive rule below is intentional for
-- a booking-flow where clients are typically unauthenticated.
