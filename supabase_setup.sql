-- ============================================================
-- AU Connect — Supabase SQL Setup
-- Run this in the Supabase SQL Editor (lwnblbrohablulbeiruf)
-- ============================================================

-- ── 1. NOTIFICATIONS TABLE ────────────────────────────────────────────────────
create table if not exists notifications (
  id            uuid default gen_random_uuid() primary key,
  recipient_id  uuid references auth.users(id) on delete cascade,
  recipient_role text check (recipient_role in ('admin', 'applicant')),
  type          text not null,  -- 'new_application' | 'status_update' | 'announcement' | 'document' | 'system'
  title         text not null,
  body          text not null default '',
  metadata      jsonb default '{}',
  is_read       boolean default false,
  created_at    timestamptz default now()
);

-- Index for efficient per-user and per-role queries
create index if not exists idx_notifications_recipient_id   on notifications(recipient_id);
create index if not exists idx_notifications_recipient_role on notifications(recipient_role);
create index if not exists idx_notifications_created_at     on notifications(created_at desc);

-- ── 2. RLS POLICIES ───────────────────────────────────────────────────────────
-- NOTE: Backend manages notifications, so RLS is DISABLED for service role access
alter table notifications disable row level security;

-- ── 3. NEW APPLICATION → ADMIN NOTIFICATION TRIGGER ──────────────────────────
-- Automatically notifies admins when a new application is submitted

create or replace function notify_admins_on_new_application()
returns trigger language plpgsql security definer as $$
declare
  v_hour int;
  v_greeting text;
  v_type text;
  v_name text;
  v_prog text;
  v_country text;
  v_body text;
begin
  -- Greeting based on Africa/Harare time (UTC+2)
  v_hour := extract(hour from now() at time zone 'Africa/Harare')::int;
  v_greeting := case
    when v_hour >= 5  and v_hour < 12 then 'Good morning'
    when v_hour >= 12 and v_hour < 17 then 'Good afternoon'
    else 'Good evening'
  end;

  v_type    := coalesce(new.type, 'Local');
  v_name    := coalesce(new.applicant_name, 'An applicant');
  v_prog    := coalesce(new.programme, 'an unspecified programme');
  v_country := coalesce(new.nationality, '');

  -- Dynamic body based on applicant type
  v_body := case
    when lower(v_type) like '%international%' then
      v_greeting || '. There''s a new international applicant'
      || case when v_country <> '' then ' from ' || v_country else '' end
      || ' applying for ' || v_prog || '.'
    when lower(v_type) like '%master%' or lower(v_type) like '%postgrad%' then
      'A new postgraduate applicant has submitted an application for ' || v_prog || '.'
    else
      'A new local applicant, ' || v_name || ', has applied for ' || v_prog || '.'
  end;

  insert into notifications (recipient_role, type, title, body, metadata)
  values (
    'admin',
    'new_application',
    'New Application — ' || v_name,
    v_body,
    jsonb_build_object(
      'application_id', new.id::text,
      'applicant_id',   coalesce(new.applicant_id, ''),
      'type',           v_type,
      'programme',      v_prog,
      'nationality',    v_country
    )
  );

  return new;
end;
$$;

-- Fires when an application's status is set to 'submitted' (not on draft creation)
create or replace function notify_admins_on_application_submitted()
returns trigger language plpgsql security definer as $$
declare
  v_hour int;
  v_greeting text;
  v_type text;
  v_name text;
  v_prog text;
  v_country text;
  v_body text;
begin
  -- Only fire when status transitions to 'submitted'
  if NEW.status <> 'submitted' or OLD.status = 'submitted' then
    return NEW;
  end if;

  v_hour := extract(hour from now() at time zone 'Africa/Harare')::int;
  v_greeting := case
    when v_hour >= 5  and v_hour < 12 then 'Good morning'
    when v_hour >= 12 and v_hour < 17 then 'Good afternoon'
    else 'Good evening'
  end;

  v_type    := coalesce(NEW.type, 'Local');
  v_name    := coalesce(NEW.applicant_name, 'An applicant');
  v_prog    := coalesce(NEW.programme, 'an unspecified programme');
  v_country := coalesce(NEW.nationality, '');

  v_body := case
    when lower(v_type) like '%international%' then
      v_greeting || '. A new international applicant'
      || case when v_country <> '' then ' from ' || v_country else '' end
      || ' has submitted an application for ' || v_prog || '.'
    when lower(v_type) like '%master%' or lower(v_type) like '%postgrad%' then
      'A new postgraduate applicant has submitted an application for ' || v_prog || '.'
    else
      'A new local applicant, ' || v_name || ', has submitted an application for ' || v_prog || '.'
  end;

  insert into notifications (recipient_role, type, title, body, metadata)
  values (
    'admin',
    'new_application',
    'New Application Submitted — ' || v_name,
    v_body,
    jsonb_build_object(
      'application_id', NEW.id::text,
      'applicant_id',   coalesce(NEW.user_id::text, ''),
      'type',           v_type,
      'programme',      v_prog,
      'nationality',    v_country
    )
  );

  return NEW;
end;
$$;

drop trigger if exists trg_new_application_notify on applications;
drop trigger if exists trg_application_submitted_notify on applications;
create trigger trg_application_submitted_notify
  after update on applications
  for each row execute function notify_admins_on_application_submitted();

-- ── 4. VISA PROGRESS TABLE ────────────────────────────────────────────────────
create table if not exists visa_progress (
  id              uuid default gen_random_uuid() primary key,
  user_id         uuid references auth.users(id) on delete cascade unique,
  completed_steps int[] default '{}',
  updated_at      timestamptz default now()
);

alter table visa_progress enable row level security;

drop policy if exists "Users manage own visa progress" on visa_progress;
create policy "Users manage own visa progress"
  on visa_progress for all
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ── 5. ENSURE APPLICATIONS HAS user_id COLUMN ────────────────────────────────
-- Add user_id if it doesn't exist (may already exist)
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'applications' and column_name = 'user_id'
  ) then
    alter table applications add column user_id uuid references auth.users(id);
  end if;
end $$;

create index if not exists idx_applications_user_id on applications(user_id);

-- ── 5b. ENSURE APPLICATIONS HAS submitted_at COLUMN ──────────────────────────
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'applications' and column_name = 'submitted_at'
  ) then
    alter table applications add column submitted_at timestamptz;
  end if;
end $$;

-- ── 5c. RLS FOR APPLICATIONS ─────────────────────────────────────────────────
alter table applications enable row level security;

-- Drop and recreate to avoid duplicate-policy errors on re-run
drop policy if exists "Users insert own application"    on applications;
drop policy if exists "Users read own application"      on applications;
drop policy if exists "Users update own application"    on applications;
drop policy if exists "Admins read all applications"    on applications;
drop policy if exists "Admins update any application"   on applications;

-- Applicants: full access to their own row
create policy "Users insert own application"
  on applications for insert
  with check (user_id = auth.uid());

create policy "Users read own application"
  on applications for select
  using (user_id = auth.uid());

create policy "Users update own application"
  on applications for update
  using (user_id = auth.uid());

-- Admins: read & update ALL applications
-- NOTE: The logged-in admin's profile row must have role = 'admin'
create policy "Admins read all applications"
  on applications for select
  using (
    exists (
      select 1 from profiles
      where profiles.user_id = auth.uid()
        and lower(profiles.role) = 'admin'
    )
  );

create policy "Admins update any application"
  on applications for update
  using (
    exists (
      select 1 from profiles
      where profiles.user_id = auth.uid()
        and lower(profiles.role) = 'admin'
    )
  );

-- ── 5d. ENSURE profiles HAS role COLUMN ──────────────────────────────────────
do $$
begin
  if not exists (
    select 1 from information_schema.columns
    where table_name = 'profiles' and column_name = 'role'
  ) then
    alter table profiles add column role text default 'applicant';
  end if;
end $$;

-- ── 5e. PAYMENTS TABLE ────────────────────────────────────────────────────────
create table if not exists payments (
  id             uuid default gen_random_uuid() primary key,
  user_id        uuid references auth.users(id) on delete cascade,
  application_id bigint references applications(id) on delete set null,
  amount         numeric(10,2) not null default 25,
  method         text,
  reference      text,
  payment_type   text default 'application_fee',
  paid_at        timestamptz default now(),
  created_at     timestamptz default now()
);

create index if not exists idx_payments_user_id on payments(user_id);

-- Backend manages this table, so RLS is DISABLED for service role access
alter table payments disable row level security;

-- ── 6. DOCUMENTS TABLE ────────────────────────────────────────────────────────
create table if not exists documents (
  id                  uuid default gen_random_uuid() primary key,
  user_id             uuid references auth.users(id) on delete cascade,
  application_id      bigint references applications(id) on delete set null,
  file_name           text not null,
  document_type       text not null,
  verification_status text not null default 'Pending',
  status              text not null default 'Pending',
  reviewed_by         text,
  uploaded_at         timestamptz default now(),
  created_at          timestamptz default now()
);

create index if not exists idx_documents_user_id        on documents(user_id);
create index if not exists idx_documents_application_id on documents(application_id);
create index if not exists idx_documents_uploaded_at    on documents(uploaded_at desc);

alter table documents enable row level security;

drop policy if exists "Users read own documents"    on documents;
drop policy if exists "Users insert own documents"  on documents;
drop policy if exists "Admins read all documents"   on documents;
drop policy if exists "Admins update document status" on documents;

-- Applicants can read their own documents
create policy "Users read own documents"
  on documents for select
  using (user_id = auth.uid());

-- Applicants can insert their own documents
create policy "Users insert own documents"
  on documents for insert
  with check (user_id = auth.uid());

-- Admins can read all documents
create policy "Admins read all documents"
  on documents for select
  using (
    exists (
      select 1 from profiles
      where profiles.user_id = auth.uid()
        and profiles.role = 'admin'
    )
  );

-- Admins can update document status
create policy "Admins update document status"
  on documents for update
  using (
    exists (
      select 1 from profiles
      where profiles.user_id = auth.uid()
        and profiles.role = 'admin'
    )
  );

-- ── 7. CONVERSATIONS TABLE ───────────────────────────────────────────────────
create table if not exists conversations (
  id                uuid default gen_random_uuid() primary key,
  participant1_id   uuid references auth.users(id) on delete cascade,
  participant2_id   uuid references auth.users(id) on delete cascade,
  created_at        timestamptz default now(),
  updated_at        timestamptz default now()
);

create index if not exists idx_conversations_participant1 on conversations(participant1_id);
create index if not exists idx_conversations_participant2 on conversations(participant2_id);
create index if not exists idx_conversations_updated_at   on conversations(updated_at desc);

-- Backend manages this table, so RLS is DISABLED for service role access
alter table conversations disable row level security;

-- ── 8. MESSAGES TABLE ────────────────────────────────────────────────────────
create table if not exists messages (
  id                uuid default gen_random_uuid() primary key,
  conversation_id   uuid references conversations(id) on delete cascade,
  sender_id         uuid references auth.users(id) on delete cascade,
  recipient_id      uuid references auth.users(id) on delete cascade,
  content           text not null,
  type              text default 'text' check (type in ('text', 'file', 'document')),
  file_url          text,
  file_name         text,
  is_read           boolean default false,
  sent_at           timestamptz default now(),
  created_at        timestamptz default now()
);

create index if not exists idx_messages_conversation  on messages(conversation_id);
create index if not exists idx_messages_sender        on messages(sender_id);
create index if not exists idx_messages_recipient     on messages(recipient_id);
create index if not exists idx_messages_is_read       on messages(is_read);
create index if not exists idx_messages_sent_at       on messages(sent_at desc);

-- Backend manages this table, so RLS is DISABLED for service role access
alter table messages disable row level security;

-- ── 9. ADMIN ACTIONS LOG TABLE ───────────────────────────────────────────────
create table if not exists admin_actions (
  id               uuid default gen_random_uuid() primary key,
  admin_id         text not null,  -- admin user ID or name
  action           text not null,  -- 'review_application', 'approve_document', 'send_notification', etc
  application_id   bigint references applications(id) on delete set null,
  document_id      bigint references documents(id) on delete set null,
  details          jsonb default '{}',  -- action-specific data
  created_at       timestamptz default now()
);

create index if not exists idx_admin_actions_admin_id       on admin_actions(admin_id);
create index if not exists idx_admin_actions_application_id on admin_actions(application_id);
create index if not exists idx_admin_actions_created_at     on admin_actions(created_at desc);

-- Backend manages this table, so RLS is DISABLED
alter table admin_actions disable row level security;

