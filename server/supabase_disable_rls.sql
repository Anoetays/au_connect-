-- ═══════════════════════════════════════════════════════════════════════════
-- Simplest Fix: Disable RLS on Backend-Managed Tables
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════
-- Note: Service role will have full access. User-facing tables like 
-- applications, documents still have RLS for security.

-- Disable RLS on notifications (backend handles access control)
alter table notifications disable row level security;

-- Disable RLS on conversations (backend handles access control)
alter table conversations disable row level security;

-- Disable RLS on messages (backend handles access control)
alter table messages disable row level security;

-- Disable RLS on payments (backend handles access control)
alter table payments disable row level security;
