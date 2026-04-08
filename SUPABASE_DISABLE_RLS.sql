-- ============================================================
-- SUPABASE RLS DISABLE - Copy & paste into Supabase SQL Editor
-- Run this to fix "permission denied" errors on backend tables
-- ============================================================

-- Disable RLS on backend-managed tables (service role needs full access)
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE payments DISABLE ROW LEVEL SECURITY;

-- Note: RLS stays ENABLED on user-facing tables:
-- - applications (users can only see/modify their own)
-- - documents (users can only see/upload their own)
-- - visa_progress (users can only see/modify their own)
-- - profiles (users can only see/modify their own)
