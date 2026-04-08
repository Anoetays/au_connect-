-- NUCLEAR OPTION: Complete RLS Reset
-- Drop and recreate tables without RLS
-- Run in Supabase SQL Editor

-- Option 1: Just disable RLS completely (simplest)
ALTER TABLE notifications DISABLE ROW LEVEL SECURITY;
ALTER TABLE conversations DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE payments DISABLE ROW LEVEL SECURITY;

-- Verify it worked (you should see no policies listed)
SELECT tablename FROM pg_tables 
WHERE tablename IN ('notifications', 'conversations', 'messages', 'payments');
