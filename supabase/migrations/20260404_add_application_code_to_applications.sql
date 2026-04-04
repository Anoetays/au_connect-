-- ============================================================
-- AU Connect schema patch
-- Date: 2026-04-04
-- Adds a dedicated text application_code for AU-... identifiers
-- so no UUID column receives the generated code.
-- ============================================================

ALTER TABLE public.applications
  ADD COLUMN IF NOT EXISTS application_code text;

-- Backfill missing application codes for existing rows.
UPDATE public.applications
SET application_code = 'AU-' || EXTRACT(EPOCH FROM now())::bigint || '-' || substring(md5(random()::text) from 1 for 6)
WHERE application_code IS NULL OR btrim(application_code) = '';

-- Make the code unique if the table supports it.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND tablename = 'applications'
      AND indexname = 'applications_application_code_key'
  ) THEN
    CREATE UNIQUE INDEX applications_application_code_key
      ON public.applications (application_code);
  END IF;
END $$;
