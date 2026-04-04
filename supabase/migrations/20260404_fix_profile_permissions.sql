-- ============================================================
-- AU Connect - Fix profile table permissions for authenticated users
-- Date: 2026-04-04
-- Reason: sign-in profile fetch failing with 42501 permission denied
-- ============================================================

-- Ensure app roles can access public schema
GRANT USAGE ON SCHEMA public TO anon, authenticated;

-- Profiles access is still constrained by RLS policies.
-- These grants only allow operations that RLS permits.
GRANT SELECT, INSERT, UPDATE ON TABLE public.profiles TO authenticated;

-- Optional read for anon in case any pre-auth flow queries profile metadata.
-- RLS remains the gatekeeper.
GRANT SELECT ON TABLE public.profiles TO anon;
