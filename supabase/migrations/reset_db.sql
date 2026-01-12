-- DANGEROUS: This will wipe all data in the public schema
-- It is intended for development reset only.

-- 1. Truncate all application data tables
TRUNCATE TABLE public.songs CASCADE;
TRUNCATE TABLE public.services CASCADE;
TRUNCATE TABLE public.posts CASCADE;
TRUNCATE TABLE public.organization_members CASCADE;
TRUNCATE TABLE public.organizations CASCADE;
TRUNCATE TABLE public.profiles CASCADE;

-- 2. Delete all auth users (This effectively resets the accounts)
-- Note: This requires appropriate permissions in the SQL Editor.
-- If this fails, you may need to delete users via the Auth dashboard or ignore if just resetting app data is enough.
DELETE FROM auth.users;
