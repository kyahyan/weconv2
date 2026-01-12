ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS contact_number TEXT;

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload config';
