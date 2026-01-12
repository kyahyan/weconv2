-- Create a table for public profiles using Supabase Auth
create table profiles (
  id uuid references auth.users not null,
  username text unique,
  avatar_url text,
  updated_at timestamp with time zone,
  primary key (id),
  constraint username_length check (char_length(username) >= 3)
);

alter table profiles enable row level security;

create policy "Public profiles are viewable by everyone."
  on profiles for select
  using ( true );

create policy "Users can insert their own profile."
  on profiles for insert
  with check ( auth.uid() = id );

create policy "Users can update own profile."
  on profiles for update
  using ( auth.uid() = id );

-- Create a table for Songs
create table songs (
  id uuid default gen_random_uuid() primary key,
  title text not null,
  artist text,
  content text, -- Lyrics or ChordPro
  key text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null
);

alter table songs enable row level security;

-- Allow read access to authenticated users
create policy "Enable read access for all users"
    on songs for select
    using ( true );

-- Allow insert/update access to authenticated users (simplify for now)
create policy "Enable insert for authenticated users only"
    on songs for insert
    with check ( auth.role() = 'authenticated' );

create policy "Enable update for authenticated users only"
    on songs for update
    using ( auth.role() = 'authenticated' );
