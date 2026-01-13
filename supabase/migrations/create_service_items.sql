-- Create Service Items table
create table public.service_items (
  id uuid not null default gen_random_uuid(),
  service_id uuid not null references public.services(id) on delete cascade,
  title text not null,
  type text not null default 'generic', -- generic, song, sermon, etc.
  description text,
  duration_seconds integer,
  order_index integer not null default 0,
  song_id uuid references public.songs(id), -- Optional foreign key if type is song
  created_at timestamp with time zone not null default now(),
  updated_at timestamp with time zone not null default now(),
  
  constraint service_items_pkey primary key (id)
);

-- RLS
alter table public.service_items enable row level security;

-- Policy: Everyone can view (if they have app access, enforced by UI/API usually but let's be open for read)
create policy "Allow read access for authenticated users"
  on public.service_items
  for select
  to authenticated
  using (true);

-- Policy: Only Admins/Ministry Leaders can insert/update/delete
-- For now, let's allow all authenticated users to manage service plans to simplify
-- Or better, reuse the "is_org_member" concept if we had it, but here we assume app access is gated.
create policy "Allow all access for authenticated users"
  on public.service_items
  for all
  to authenticated
  using (true)
  with check (true);

-- Indexes
create index service_items_service_id_idx on public.service_items(service_id);
