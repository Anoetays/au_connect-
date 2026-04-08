-- Force service role access by adding explicit pass-through policies
-- Run this if tables still have RLS enabled despite alter table ... disable rls

-- For notifications
alter table notifications enable row level security;
drop policy if exists "Service role bypass" on notifications;
create policy "Service role bypass" on notifications 
  for all using (true) with check (true);

-- For conversations
alter table conversations enable row level security;
drop policy if exists "Service role bypass" on conversations;
create policy "Service role bypass" on conversations 
  for all using (true) with check (true);

-- For messages
alter table messages enable row level security;
drop policy if exists "Service role bypass" on messages;
create policy "Service role bypass" on messages 
  for all using (true) with check (true);

-- For payments
alter table payments enable row level security;
drop policy if exists "Service role bypass" on payments;
create policy "Service role bypass" on payments 
  for all using (true) with check (true);
