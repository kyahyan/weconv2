-- 1. Create the bucket (Safe to run if exists)
insert into storage.buckets (id, name, public)
values ('activity_images', 'activity_images', true)
on conflict (id) do update set public = true;

-- 2. Drop existing policies for this bucket to avoid conflicts/errors
drop policy if exists "Public Access" on storage.objects;
drop policy if exists "Authenticated Upload" on storage.objects;
drop policy if exists "Authenticated Update" on storage.objects;
drop policy if exists "Authenticated Delete" on storage.objects;

-- 3. Re-create Policies
-- Note: We skipped 'alter table storage.objects enable row level security' as it is enabled by default 
-- and requires special permissions to change.

-- Allow Public Read Access
create policy "Public Access"
on storage.objects for select
to public
using ( bucket_id = 'activity_images' );

-- Allow Authenticated Users to Upload (INSERT)
create policy "Authenticated Upload"
on storage.objects for insert
to authenticated
with check ( bucket_id = 'activity_images' );

-- Allow Authenticated Users to Update (UPDATE)
create policy "Authenticated Update"
on storage.objects for update
to authenticated
using ( bucket_id = 'activity_images' );

-- Allow Authenticated Users to Delete (DELETE)
create policy "Authenticated Delete"
on storage.objects for delete
to authenticated
using ( bucket_id = 'activity_images' );
