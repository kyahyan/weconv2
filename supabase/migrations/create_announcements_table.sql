create table public.announcements (
  id uuid not null default gen_random_uuid (),
  created_at timestamp with time zone not null default now(),
  title text not null,
  content text not null,
  organization_id uuid not null default auth.uid(),
  constraint announcements_pkey primary key (id)
);

-- Enable RLS
alter table public.announcements enable row level security;

-- Policies
create policy "Enable read access for authenticated users"
on public.announcements
as permissive
for select
to authenticated
using (true);

create policy "Enable insert for authenticated users"
on public.announcements
as permissive
for insert
to authenticated
with check (auth.uid() = organization_id);

create policy "Enable delete for authenticated users"
on public.announcements
as permissive
for delete
to authenticated
using (auth.uid() = organization_id);
