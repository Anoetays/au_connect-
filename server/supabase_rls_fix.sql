-- ═══════════════════════════════════════════════════════════════════════════
-- Fix RLS Policies for Backend Service Role Access
-- Run this in Supabase SQL Editor
-- ═══════════════════════════════════════════════════════════════════════════

-- Fix notifications table - allow service role full access
drop policy if exists "Admins read admin notifications" on notifications;
drop policy if exists "Applicants read own notifications" on notifications;
drop policy if exists "Authenticated users can insert notifications" on notifications;
drop policy if exists "Users can mark own notifications read" on notifications;
drop policy if exists "Users can delete own notifications" on notifications;

create policy "Service role and users access notifications"
  on notifications for all
  using (auth.role() = 'service_role' or recipient_id = auth.uid() or recipient_role = 'admin')
  with check (auth.role() = 'service_role' or auth.role() = 'authenticated');

-- Fix conversations table - allow service role full access
drop policy if exists "Users can read conversations they participate in" on conversations;
drop policy if exists "Users can create conversations" on conversations;
drop policy if exists "Users can update their conversations" on conversations;

create policy "Service role and users access conversations"
  on conversations for all
  using (auth.role() = 'service_role' or participant1_id = auth.uid() or participant2_id = auth.uid())
  with check (auth.role() = 'service_role' or auth.role() = 'authenticated');

-- Fix messages table - allow service role full access
drop policy if exists "Users can read messages in their conversations" on messages;
drop policy if exists "Users can insert messages to their conversations" on messages;
drop policy if exists "Users can update their own messages" on messages;

create policy "Service role and users access messages"
  on messages for all
  using (auth.role() = 'service_role' or sender_id = auth.uid() or recipient_id = auth.uid())
  with check (auth.role() = 'service_role' or sender_id = auth.uid());

-- Fix applications table for service role
drop policy if exists "Users insert own application" on applications;
drop policy if exists "Users read own application" on applications;
drop policy if exists "Users update own application" on applications;
drop policy if exists "Admins read all applications" on applications;
drop policy if exists "Admins update any application" on applications;

create policy "Service role and users access applications"
  on applications for all
  using (auth.role() = 'service_role' or user_id = auth.uid())
  with check (auth.role() = 'service_role' or auth.role() = 'authenticated');

-- Fix payments table for service role
drop policy if exists "Users read own payments" on payments;
drop policy if exists "Users insert own payments" on payments;

create policy "Service role and users access payments"
  on payments for all
  using (auth.role() = 'service_role' or user_id = auth.uid())
  with check (auth.role() = 'service_role' or auth.role() = 'authenticated');

-- Fix documents table for service role
drop policy if exists "Users read own documents" on documents;
drop policy if exists "Users insert own documents" on documents;
drop policy if exists "Admins read all documents" on documents;
drop policy if exists "Admins update document status" on documents;

create policy "Service role and users access documents"
  on documents for all
  using (auth.role() = 'service_role' or user_id = auth.uid())
  with check (auth.role() = 'service_role' or auth.role() = 'authenticated');
