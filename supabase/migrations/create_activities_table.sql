create table public.activities (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone not null default now(),
  title text not null,
  description text null,
  start_time timestamp with time zone not null,
  end_time timestamp with time zone not null,
  location text null,
  image_url text null,
  is_registration_required boolean not null default false,
  form_config jsonb null,
  organization_id uuid not null default auth.uid(), -- Assumes simplified RLS or org logic
  constraint activities_pkey primary key (id)
);

-- Enable RLS
alter table public.activities enable row level security;

-- Policies
create policy "Enable read access for authenticated users"
on public.activities
as permissive
for select
to authenticated
using (true);

create policy "Enable insert for authenticated users"
on public.activities
as permissive
for insert
to authenticated
with check (true);

create policy "Enable update for authenticated users"
on public.activities
as permissive
for update
to authenticated
using (true);

create policy "Enable delete for authenticated users"
on public.activities
as permissive
for delete
to authenticated
using (true);
