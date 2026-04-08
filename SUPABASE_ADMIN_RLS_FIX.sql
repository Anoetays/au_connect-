-- ============================================================
-- FIX: Disable all RLS for backend admin operations
-- Copy & paste into Supabase SQL Editor
-- ============================================================

-- Disable RLS on all backend-managed and admin-queried tables
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE payments DISABLE ROW LEVEL SECURITY;
ALTER TABLE admin_actions DISABLE ROW LEVEL SECURITY;

-- For admin queries: These stay enabled, but use service role bypass
-- If you want backend to access applications/documents, run below:
-- ALTER TABLE applications DISABLE ROW LEVEL SECURITY;
-- ALTER TABLE documents DISABLE ROW LEVEL SECURITY;

-- Alternative: Create permissive policies that allow service role
-- CREATE POLICY "Service role bypass" ON applications 
--   USING (true) 
--   WITH CHECK (true);

-- For now, admin endpoints will use service role which should bypass RLS
-- Verify in Supabase dashboard that service role is configured
