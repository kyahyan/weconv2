-- 1. Ensure the column exists (Just in case the previous migration wasn't run)
ALTER TABLE public.profiles 
ADD COLUMN IF NOT EXISTS full_name TEXT;

-- 2. Force Supabase (PostgREST) to reload its schema cache
-- This is often required after adding new columns so the API "sees" them.
NOTIFY pgrst, 'reload config';
