-- Add full_name to profiles if it doesn't exist
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS full_name text;
