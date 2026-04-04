-- ============================================================
-- AU Connect — Applicant/Admin RLS Hardening
-- Date: 2026-04-04
-- Purpose:
-- 1) Ensure applicants can submit/read/update their own application data
-- 2) Ensure admins can see and decide (approve/deny/review) all applications
-- 3) Ensure docs + notifications + offer letters are correctly secured
-- 4) Ensure realtime tables are in publication for live dashboards
-- ============================================================

-- ---------- Helpers ----------

-- Ensure profiles.role exists
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'profiles'
      AND column_name = 'role'
  ) THEN
    ALTER TABLE public.profiles ADD COLUMN role text DEFAULT 'applicant';
  END IF;
END $$;

-- Admin helper (used by policies)
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.profiles p
    WHERE p.user_id = auth.uid()
      AND lower(coalesce(p.role, '')) = 'admin'
  );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;

-- ---------- Base Grants ----------
-- RLS controls row access. These grants allow authenticated requests to reach policies.
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON TABLE public.profiles TO authenticated;
GRANT SELECT ON TABLE public.profiles TO anon;

-- ---------- Realtime Publication Safety ----------

DO $$
BEGIN
  IF to_regclass('public.applications') IS NOT NULL
     AND NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'applications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.applications;
  END IF;
END $$;

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

DO $$
BEGIN
  IF to_regclass('public.notifications') IS NOT NULL
     AND NOT EXISTS (
    SELECT 1
    FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'notifications'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
  END IF;
END $$;

-- ---------- PROFILES ----------

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS profiles_select_self_or_admin ON public.profiles;
DROP POLICY IF EXISTS profiles_insert_self_or_admin ON public.profiles;
DROP POLICY IF EXISTS profiles_update_self_or_admin ON public.profiles;

CREATE POLICY profiles_select_self_or_admin
  ON public.profiles
  FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY profiles_insert_self_or_admin
  ON public.profiles
  FOR INSERT
  WITH CHECK (user_id = auth.uid() OR public.is_admin());

CREATE POLICY profiles_update_self_or_admin
  ON public.profiles
  FOR UPDATE
  USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());

-- ---------- APPLICATIONS ----------

ALTER TABLE public.applications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS applications_select_own_or_admin ON public.applications;
DROP POLICY IF EXISTS applications_insert_own_or_admin ON public.applications;
DROP POLICY IF EXISTS applications_update_own_or_admin ON public.applications;
DROP POLICY IF EXISTS applications_delete_admin_only ON public.applications;

CREATE POLICY applications_select_own_or_admin
  ON public.applications
  FOR SELECT
  USING (user_id = auth.uid() OR public.is_admin());

CREATE POLICY applications_insert_own_or_admin
  ON public.applications
  FOR INSERT
  WITH CHECK (user_id = auth.uid() OR public.is_admin());

CREATE POLICY applications_update_own_or_admin
  ON public.applications
  FOR UPDATE
  USING (user_id = auth.uid() OR public.is_admin())
  WITH CHECK (user_id = auth.uid() OR public.is_admin());

CREATE POLICY applications_delete_admin_only
  ON public.applications
  FOR DELETE
  USING (public.is_admin());

-- ---------- PROGRAMMES ----------

ALTER TABLE public.programmes ENABLE ROW LEVEL SECURITY;

GRANT SELECT ON TABLE public.programmes TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.programmes TO authenticated;

DROP POLICY IF EXISTS programmes_select_all ON public.programmes;
DROP POLICY IF EXISTS programmes_insert_admin ON public.programmes;
DROP POLICY IF EXISTS programmes_update_admin ON public.programmes;
DROP POLICY IF EXISTS programmes_delete_admin ON public.programmes;

CREATE POLICY programmes_select_all
  ON public.programmes
  FOR SELECT
  USING (true);

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

-- ---------- DOCUMENTS ----------

ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS documents_select_own_or_admin ON public.documents;
DROP POLICY IF EXISTS documents_insert_own_or_admin ON public.documents;
DROP POLICY IF EXISTS documents_update_own_or_admin ON public.documents;
DROP POLICY IF EXISTS documents_delete_admin_only ON public.documents;

CREATE POLICY documents_select_own_or_admin
  ON public.documents
  FOR SELECT
  USING (
    user_id = auth.uid()
    OR application_id IN (
      SELECT a.id FROM public.applications a WHERE a.user_id = auth.uid()
    )
    OR public.is_admin()
  );

CREATE POLICY documents_insert_own_or_admin
  ON public.documents
  FOR INSERT
  WITH CHECK (
    user_id = auth.uid()
    OR public.is_admin()
  );

CREATE POLICY documents_update_own_or_admin
  ON public.documents
  FOR UPDATE
  USING (
    user_id = auth.uid()
    OR public.is_admin()
  )
  WITH CHECK (
    user_id = auth.uid()
    OR public.is_admin()
  );

CREATE POLICY documents_delete_admin_only
  ON public.documents
  FOR DELETE
  USING (public.is_admin());

-- ---------- NOTIFICATIONS ----------

ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS notifications_select_own_or_admin_role ON public.notifications;
DROP POLICY IF EXISTS notifications_insert_admin_or_service ON public.notifications;
DROP POLICY IF EXISTS notifications_update_own_or_admin ON public.notifications;
DROP POLICY IF EXISTS notifications_delete_own_or_admin ON public.notifications;

CREATE POLICY notifications_select_own_or_admin_role
  ON public.notifications
  FOR SELECT
  USING (
    recipient_id = auth.uid()
    OR (recipient_role = 'admin' AND public.is_admin())
  );

CREATE POLICY notifications_insert_admin_or_service
  ON public.notifications
  FOR INSERT
  WITH CHECK (
    auth.role() = 'service_role'
    OR public.is_admin()
    OR recipient_id = auth.uid()
  );

CREATE POLICY notifications_update_own_or_admin
  ON public.notifications
  FOR UPDATE
  USING (
    recipient_id = auth.uid()
    OR (recipient_role = 'admin' AND public.is_admin())
  )
  WITH CHECK (true);

CREATE POLICY notifications_delete_own_or_admin
  ON public.notifications
  FOR DELETE
  USING (
    recipient_id = auth.uid()
    OR (recipient_role = 'admin' AND public.is_admin())
  );

-- ---------- OFFER LETTERS ----------

ALTER TABLE public.offer_letters ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS offer_letters_select_own_or_admin ON public.offer_letters;
DROP POLICY IF EXISTS offer_letters_insert_admin_only ON public.offer_letters;
DROP POLICY IF EXISTS offer_letters_update_admin_only ON public.offer_letters;
DROP POLICY IF EXISTS offer_letters_delete_admin_only ON public.offer_letters;

CREATE POLICY offer_letters_select_own_or_admin
  ON public.offer_letters
  FOR SELECT
  USING (
    application_id IN (
      SELECT a.id FROM public.applications a WHERE a.user_id = auth.uid()
    )
    OR public.is_admin()
  );

CREATE POLICY offer_letters_insert_admin_only
  ON public.offer_letters
  FOR INSERT
  WITH CHECK (public.is_admin() OR auth.role() = 'service_role');

CREATE POLICY offer_letters_update_admin_only
  ON public.offer_letters
  FOR UPDATE
  USING (public.is_admin() OR auth.role() = 'service_role')
  WITH CHECK (public.is_admin() OR auth.role() = 'service_role');

CREATE POLICY offer_letters_delete_admin_only
  ON public.offer_letters
  FOR DELETE
  USING (public.is_admin() OR auth.role() = 'service_role');

-- ---------- STORAGE: applicant-documents ----------
-- Lets applicants upload/read their own files under: documents/<uid>/...

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM storage.buckets
    WHERE id = 'applicant-documents'
  ) THEN
    INSERT INTO storage.buckets (id, name, public)
    VALUES ('applicant-documents', 'applicant-documents', false);
  END IF;
END $$;

DROP POLICY IF EXISTS storage_docs_select_own_or_admin ON storage.objects;
DROP POLICY IF EXISTS storage_docs_insert_own_or_admin ON storage.objects;
DROP POLICY IF EXISTS storage_docs_update_own_or_admin ON storage.objects;
DROP POLICY IF EXISTS storage_docs_delete_own_or_admin ON storage.objects;

CREATE POLICY storage_docs_select_own_or_admin
  ON storage.objects
  FOR SELECT
  USING (
    bucket_id = 'applicant-documents'
    AND (
      public.is_admin()
      OR (auth.uid()::text = (storage.foldername(name))[2])
    )
  );

CREATE POLICY storage_docs_insert_own_or_admin
  ON storage.objects
  FOR INSERT
  WITH CHECK (
    bucket_id = 'applicant-documents'
    AND (
      public.is_admin()
      OR (auth.uid()::text = (storage.foldername(name))[2])
    )
  );

CREATE POLICY storage_docs_update_own_or_admin
  ON storage.objects
  FOR UPDATE
  USING (
    bucket_id = 'applicant-documents'
    AND (
      public.is_admin()
      OR (auth.uid()::text = (storage.foldername(name))[2])
    )
  )
  WITH CHECK (
    bucket_id = 'applicant-documents'
    AND (
      public.is_admin()
      OR (auth.uid()::text = (storage.foldername(name))[2])
    )
  );

CREATE POLICY storage_docs_delete_own_or_admin
  ON storage.objects
  FOR DELETE
  USING (
    bucket_id = 'applicant-documents'
    AND (
      public.is_admin()
      OR (auth.uid()::text = (storage.foldername(name))[2])
    )
  );

-- ---------- Trigger: Notify admins on new application ----------

CREATE OR REPLACE FUNCTION public.notify_admins_on_new_application()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_name text;
  v_prog text;
  v_type text;
BEGIN
  v_name := coalesce(new.applicant_name, 'Applicant');
  v_prog := coalesce(new.programme, 'N/A');
  v_type := coalesce(new.type, 'Local');

  INSERT INTO public.notifications (recipient_role, type, title, body, metadata)
  VALUES (
    'admin',
    'new_application',
    'New Application - ' || v_name,
    v_name || ' submitted an application for ' || v_prog || '.',
    jsonb_build_object(
      'application_id', new.id::text,
      'applicant_id', coalesce(new.applicant_id, ''),
      'type', v_type,
      'programme', v_prog
    )
  );

  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS trg_new_application_notify ON public.applications;
CREATE TRIGGER trg_new_application_notify
AFTER INSERT ON public.applications
FOR EACH ROW
EXECUTE FUNCTION public.notify_admins_on_new_application();
