-- COMPLETE RLS REMOVAL FOR BACKEND TABLES
-- Run this in Supabase SQL Editor to fully unlock tables for backend
-- ═══════════════════════════════════════════════════════════

-- Step 1: Drop ALL existing policies on each table
drop policy if exists "Admins read admin notifications" on notifications;
drop policy if exists "Applicants read own notifications" on notifications;
drop policy if exists "Authenticated users can insert notifications" on notifications;
drop policy if exists "Users can mark own notifications read" on notifications;
drop policy if exists "Users can delete own notifications" on notifications;
drop policy if exists "Service role bypass" on notifications;
drop policy if exists "Service role and users access notifications" on notifications;

drop policy if exists "Users can read conversations they participate in" on conversations;
drop policy if exists "Users can create conversations" on conversations;
drop policy if exists "Users can update their conversations" on conversations;
drop policy if exists "Service role bypass" on conversations;
drop policy if exists "Service role and users access conversations" on conversations;

drop policy if exists "Users can read messages in their conversations" on messages;
drop policy if exists "Users can insert messages to their conversations" on messages;
drop policy if exists "Users can update their own messages" on messages;
drop policy if exists "Service role bypass" on messages;
drop policy if exists "Service role and users access messages" on messages;

drop policy if exists "Users read own payments" on payments;
drop policy if exists "Users insert own payments" on payments;
drop policy if exists "Service role bypass" on payments;
drop policy if exists "Service role and users access payments" on payments;

-- Step 2: COMPLETELY DISABLE RLS on all tables
alter table notifications disable row level security;
alter table conversations disable row level security;
alter table messages disable row level security;
alter table payments disable row level security;

-- Step 3: Verify by checking a count (optional)
-- SELECT tablename FROM pg_tables WHERE tablename IN ('notifications', 'conversations', 'messages', 'payments');
