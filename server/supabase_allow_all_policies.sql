-- Re-enable RLS with completely permissive policies for backend use
-- This allows service role (backend) to read/write freely while keeping structure

alter table notifications enable row level security;
drop policy if exists "allow all" on notifications;
create policy "allow all" on notifications for all using (true) with check (true);

alter table conversations enable row level security;
drop policy if exists "allow all" on conversations;
create policy "allow all" on conversations for all using (true) with check (true);

alter table messages enable row level security;
drop policy if exists "allow all" on messages;
create policy "allow all" on messages for all using (true) with check (true);

alter table payments enable row level security;
drop policy if exists "allow all" on payments;
create policy "allow all" on payments for all using (true) with check (true);
