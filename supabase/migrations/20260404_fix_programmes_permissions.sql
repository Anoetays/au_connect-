-- ============================================================
-- AU Connect - Fix programmes table permissions and RLS
-- Date: 2026-04-04
-- Reason: 42501 permission denied for table programmes in admin dashboard
-- ============================================================

-- Ensure base schema access
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Table privileges (RLS still enforces row-level access)
GRANT SELECT ON TABLE public.programmes TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.programmes TO authenticated;

-- Enable RLS and define safe policies
ALTER TABLE public.programmes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS programmes_select_all ON public.programmes;
DROP POLICY IF EXISTS programmes_insert_admin ON public.programmes;
DROP POLICY IF EXISTS programmes_update_admin ON public.programmes;
DROP POLICY IF EXISTS programmes_delete_admin ON public.programmes;

-- Applicants and admins can read programmes
CREATE POLICY programmes_select_all
  ON public.programmes
  FOR SELECT
  USING (true);

-- Only admins (or service role) can create/edit/remove programmes
CREATE POLICY programmes_insert_admin
  ON public.programmes
  FOR INSERT
  WITH CHECK (public.is_admin() OR auth.role() = 'service_role');

CREATE POLICY programmes_update_admin
  ON public.programmes
  FOR UPDATE
  USING (public.is_admin() OR auth.role() = 'service_role')
  WITH CHECK (public.is_admin() OR auth.role() = 'service_role');

CREATE POLICY programmes_delete_admin
  ON public.programmes
  FOR DELETE
  USING (public.is_admin() OR auth.role() = 'service_role');

CREATE OR REPLACE FUNCTION public.admin_insert_programme(
  p_name text,
  p_faculty text,
  p_level text,
  p_duration_years int,
  p_status text DEFAULT 'Active'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT (public.is_admin() OR auth.role() = 'service_role') THEN
    RAISE EXCEPTION 'not authorized to add programme';
  END IF;

  INSERT INTO public.programmes (name, faculty, level, duration_years, status)
  VALUES (p_name, p_faculty, p_level, p_duration_years, coalesce(p_status, 'Active'));
END;
$$;

REVOKE ALL ON FUNCTION public.admin_insert_programme(text, text, text, int, text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_insert_programme(text, text, text, int, text) TO authenticated;

-- Realtime support for dashboards using stream subscriptions
DO $$
BEGIN
  IF to_regclass('public.programmes') IS NOT NULL
     AND NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'programmes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.programmes;
  END IF;
END $$;
