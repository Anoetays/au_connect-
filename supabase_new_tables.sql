-- ============================================================
-- AU Connect — New Tables (run in Supabase SQL Editor)
-- ============================================================

-- Offer letters
CREATE TABLE IF NOT EXISTS offer_letters (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id    text,
  applicant_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  programme         text,
  issued_at         timestamptz DEFAULT NOW(),
  letter_content    text,
  is_read           boolean DEFAULT false
);
ALTER TABLE offer_letters DISABLE ROW LEVEL SECURITY;

-- Rejection letters
CREATE TABLE IF NOT EXISTS rejection_letters (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id    text,
  applicant_user_id uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  programme         text,
  rejection_reason  text,
  issued_at         timestamptz DEFAULT NOW(),
  letter_content    text,
  is_read           boolean DEFAULT false
);
ALTER TABLE rejection_letters DISABLE ROW LEVEL SECURITY;

-- Document requests
CREATE TABLE IF NOT EXISTS document_requests (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  applicant_user_id   uuid REFERENCES auth.users(id) ON DELETE CASCADE,
  document_type       text,
  message             text,
  requested_by        uuid,
  requested_at        timestamptz DEFAULT NOW(),
  status              text DEFAULT 'pending'
);
ALTER TABLE document_requests DISABLE ROW LEVEL SECURITY;

-- Staff invites
CREATE TABLE IF NOT EXISTS staff_invites (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email       text,
  role        text,
  department  text,
  invited_by  uuid,
  invited_at  timestamptz DEFAULT NOW(),
  status      text DEFAULT 'pending'
);
ALTER TABLE staff_invites DISABLE ROW LEVEL SECURITY;

-- Interviews
CREATE TABLE IF NOT EXISTS interviews (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id      text,
  applicant_user_id   uuid,
  applicant_name      text,
  programme           text,
  interview_date      date,
  interview_time      time,
  format              text,
  location_or_link    text,
  interviewer_name    text,
  notes               text,
  status              text DEFAULT 'scheduled',
  created_by          uuid,
  created_at          timestamptz DEFAULT NOW()
);
ALTER TABLE interviews DISABLE ROW LEVEL SECURITY;

-- Scheduled reports
CREATE TABLE IF NOT EXISTS scheduled_reports (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  report_type      text,
  frequency        text,
  recipient_email  text,
  created_by       uuid,
  created_at       timestamptz DEFAULT NOW()
);
ALTER TABLE scheduled_reports DISABLE ROW LEVEL SECURITY;

-- Audit log
CREATE TABLE IF NOT EXISTS audit_log (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  created_at   timestamptz DEFAULT NOW(),
  admin_id     uuid REFERENCES auth.users(id),
  admin_name   text,
  action       text NOT NULL,
  target_name  text,
  target_id    text,
  description  text,
  ip_address   text,
  metadata     jsonb
);
ALTER TABLE audit_log DISABLE ROW LEVEL SECURITY;

-- Announcements table (if not exists)
CREATE TABLE IF NOT EXISTS announcements (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title            text NOT NULL,
  message          text NOT NULL,
  priority         text DEFAULT 'normal',
  target_audience  text DEFAULT 'Everyone',
  status           text DEFAULT 'draft',
  sent_at          timestamptz,
  scheduled_for    timestamptz,
  recipient_count  int DEFAULT 0,
  created_by       uuid,
  created_at       timestamptz DEFAULT NOW()
);
ALTER TABLE announcements DISABLE ROW LEVEL SECURITY;

-- Programmes table (if not exists)
CREATE TABLE IF NOT EXISTS programmes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name            text NOT NULL,
  faculty         text,
  field_of_study  text,
  level           text,
  duration_years  int,
  requirements    text,
  status          text DEFAULT 'active',
  created_by      uuid,
  created_at      timestamptz DEFAULT NOW()
);
ALTER TABLE programmes DISABLE ROW LEVEL SECURITY;

-- Add missing columns to existing tables
ALTER TABLE applications ADD COLUMN IF NOT EXISTS approved_at        timestamptz;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS approved_by        uuid;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS rejected_at        timestamptz;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS rejected_by        uuid;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS rejection_reason   text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS created_by_admin   boolean DEFAULT false;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS preferred_name     text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS gender             text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS date_of_birth      text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS study_level        text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS field_of_study     text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS language           text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS financing          text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS accommodation      text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS disability         text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS disability_detail  text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS kin_name           text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS kin_relationship   text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS kin_phone          text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS payment_method     text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS certificate_file_name text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS school_attended    text;
ALTER TABLE applications ADD COLUMN IF NOT EXISTS grades             text;
