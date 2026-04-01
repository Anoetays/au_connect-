-- ─────────────────────────────────────────────────────────────────────────────
-- AU Connect Feature Migration
-- Feature 1: Real-time Application Status Tracker
-- Feature 2: Document Verification System
-- Feature 3: Email/SMS Notifications (Edge Function)
-- Feature 4: Offer Letter PDF Generation (Edge Function)
-- ─────────────────────────────────────────────────────────────────────────────

-- ── Feature 1: Application Status ─────────────────────────────────────────────

ALTER TABLE applications
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();

CREATE TABLE IF NOT EXISTS application_status_history (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  status         TEXT NOT NULL,
  changed_by     TEXT,
  notes          TEXT,
  changed_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Realtime on both tables
ALTER PUBLICATION supabase_realtime ADD TABLE applications;
ALTER PUBLICATION supabase_realtime ADD TABLE application_status_history;

-- RLS: applicants can read their own history
ALTER TABLE application_status_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "applicant_read_own_history"
  ON application_status_history FOR SELECT
  USING (
    application_id IN (
      SELECT id FROM applications WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "admin_all_history"
  ON application_status_history FOR ALL
  USING (auth.role() = 'service_role');

-- ── Feature 2: Document Verification ──────────────────────────────────────────

ALTER TABLE documents
  ADD COLUMN IF NOT EXISTS verification_status TEXT DEFAULT 'Pending',
  ADD COLUMN IF NOT EXISTS verification_note   TEXT,
  ADD COLUMN IF NOT EXISTS verified_by         UUID,
  ADD COLUMN IF NOT EXISTS verified_at         TIMESTAMPTZ;

-- Enable Realtime on documents
ALTER PUBLICATION supabase_realtime ADD TABLE documents;

-- ── Feature 4: Offer Letters ───────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS offer_letters (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id UUID UNIQUE NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  applicant_id   TEXT NOT NULL,
  file_path      TEXT NOT NULL,
  signed_url     TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Realtime
ALTER PUBLICATION supabase_realtime ADD TABLE offer_letters;

-- RLS: applicants read their own, admins read all
ALTER TABLE offer_letters ENABLE ROW LEVEL SECURITY;

CREATE POLICY "applicant_read_own_offer"
  ON offer_letters FOR SELECT
  USING (
    application_id IN (
      SELECT id FROM applications WHERE user_id = auth.uid()
    )
  );

CREATE POLICY "admin_all_offers"
  ON offer_letters FOR ALL
  USING (auth.role() = 'service_role');

-- ── Storage bucket for offer letters ──────────────────────────────────────────
-- Run in Supabase Dashboard > Storage, or via CLI:
--   supabase storage create offer-letters --public=false
INSERT INTO storage.buckets (id, name, public)
VALUES ('offer-letters', 'offer-letters', false)
ON CONFLICT (id) DO NOTHING;

-- RLS on storage: only the owner and service_role can read
CREATE POLICY "offer_letter_owner_read"
  ON storage.objects FOR SELECT
  USING (
    bucket_id = 'offer-letters'
    AND auth.role() = 'service_role'
  );
