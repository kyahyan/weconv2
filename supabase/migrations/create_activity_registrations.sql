create type public.registration_status as enum ('registered', 'checked_in', 'cancelled');

create table public.activity_registrations (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  activity_id uuid not null references public.activities (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  status registration_status not null default 'registered',
  form_data jsonb null,
  
  constraint activity_registrations_pkey primary key (id),
  constraint unique_registration unique (activity_id, user_id)
);

-- Enable RLS
alter table public.activity_registrations enable row level security;

-- Policies

-- 1. Read Access:
--    - Users can read their own registrations.
--    - Admins/Managers (Ushering/Leaders) can read all registrations for their branch activities (simplified to authenticated for now, or based on permission).
--    Let's start permissive for authenticated users to view registrations (e.g. for checking people in).

create policy "Enable read access for authenticated users"
on public.activity_registrations
as permissive
for select
to authenticated
using (true);

-- 2. Insert Access:
--    - Users can register themselves.
--    - Ushers can register/check-in others (maybe?).
create policy "Enable insert for authenticated users"
on public.activity_registrations
as permissive
for insert
to authenticated
with check (true);

-- 3. Update Access:
--    - Users can cancel their own registration?
--    - Ushers can update status to 'checked_in'.
create policy "Enable update for authenticated users"
on public.activity_registrations
as permissive
for update
to authenticated
using (true);

-- 4. Delete Access
create policy "Enable delete for authenticated users"
on public.activity_registrations
as permissive
for delete
to authenticated
using (true);
