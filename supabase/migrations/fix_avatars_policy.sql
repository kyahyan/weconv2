-- Relax policies for 'avatars' bucket to allow app logic to handle permissions via 'authenticated' role
-- The application code checks organization/branch permissions before attempting upload.

-- Drop existing restricted policies if they exist (to be safe)
DROP POLICY IF EXISTS "Owner Update" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated Upload" ON storage.objects;

-- Re-create policies for 'avatars' bucket

-- 1. Allow Authenticated users to Insert (Upload)
-- (We rely on app logic to restrict who initiates this, or we could add complex checks, but simpler is better generally for storage if filenames are obscure or path-based)
CREATE POLICY "Authenticated Upload Avatars"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK ( bucket_id = 'avatars' );

-- 2. Allow Authenticated users to Update (Overwrite)
-- Needed because we use upsert: true
CREATE POLICY "Authenticated Update Avatars"
ON storage.objects FOR UPDATE
TO authenticated
USING ( bucket_id = 'avatars' );

-- 3. Allow Authenticated users to Delete (optional but good for cleanup)
CREATE POLICY "Authenticated Delete Avatars"
ON storage.objects FOR DELETE
TO authenticated
USING ( bucket_id = 'avatars' );
