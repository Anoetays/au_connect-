-- ============================================================
-- AU Connect schema compatibility patch
-- Date: 2026-04-04
-- Fixes:
-- 1) Missing public.documents table (PGRST205)
-- 2) Missing applications.applicant_id column (PGRST204)
-- ============================================================

-- Ensure applications.applicant_id exists
ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS applicant_id text;

-- Backfill applicant_id for existing rows where missing/blank
UPDATE public.applications
SET applicant_id = 'AU-' || EXTRACT(EPOCH FROM now())::bigint || '-' || substring(md5(random()::text) from 1 for 6)
WHERE applicant_id IS NULL OR btrim(applicant_id) = '';

-- Create documents table if it does not exist
CREATE TABLE IF NOT EXISTS public.documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id uuid NULL REFERENCES public.applications(id) ON DELETE SET NULL,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  document_type text NOT NULL,
  file_name text NOT NULL,
  file_url text,
  status text DEFAULT 'Pending',
  verification_status text DEFAULT 'pending_review',
  verification_note text,
  verified boolean NOT NULL DEFAULT false,
  reviewed_by uuid,
  uploaded_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- If table existed with partial schema, ensure required columns exist
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS application_id uuid NULL REFERENCES public.applications(id) ON DELETE SET NULL;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS user_id uuid;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS document_type text;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS file_name text;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS file_url text;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS status text DEFAULT 'Pending';
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS verification_status text DEFAULT 'pending_review';
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS verification_note text;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS verified boolean DEFAULT false;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS reviewed_by uuid;
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS uploaded_at timestamptz DEFAULT now();
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS created_at timestamptz DEFAULT now();
ALTER TABLE public.documents ADD COLUMN IF NOT EXISTS updated_at timestamptz DEFAULT now();

-- Tighten nullability where possible after ensuring columns exist
ALTER TABLE public.documents ALTER COLUMN user_id SET NOT NULL;
ALTER TABLE public.documents ALTER COLUMN document_type SET NOT NULL;
ALTER TABLE public.documents ALTER COLUMN file_name SET NOT NULL;

-- Grants required for API access under RLS
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.documents TO authenticated;

-- Enable RLS and add baseline applicant-safe policies
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS documents_select_own_or_service ON public.documents;
DROP POLICY IF EXISTS documents_insert_own_or_service ON public.documents;
DROP POLICY IF EXISTS documents_update_own_or_service ON public.documents;

CREATE POLICY documents_select_own_or_service
  ON public.documents
  FOR SELECT
  USING (user_id = auth.uid() OR auth.role() = 'service_role');

CREATE POLICY documents_insert_own_or_service
  ON public.documents
  FOR INSERT
  WITH CHECK (user_id = auth.uid() OR auth.role() = 'service_role');

CREATE POLICY documents_update_own_or_service
  ON public.documents
  FOR UPDATE
  USING (user_id = auth.uid() OR auth.role() = 'service_role')
  WITH CHECK (user_id = auth.uid() OR auth.role() = 'service_role');

-- Add documents to realtime publication safely
DO $$
BEGIN
  IF to_regclass('public.documents') IS NOT NULL
     AND NOT EXISTS (
      SELECT 1
      FROM pg_publication_tables
      WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'documents'
    ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.documents;
  END IF;
END $$;
