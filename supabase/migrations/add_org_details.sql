-- Add detailed fields to organizations table
ALTER TABLE public.organizations
ADD COLUMN IF NOT EXISTS acronym TEXT,
ADD COLUMN IF NOT EXISTS contact_mobile TEXT,
ADD COLUMN IF NOT EXISTS contact_landline TEXT,
ADD COLUMN IF NOT EXISTS location TEXT,
ADD COLUMN IF NOT EXISTS avatar_url TEXT,
ADD COLUMN IF NOT EXISTS website TEXT,
ADD COLUMN IF NOT EXISTS social_media_links JSONB; -- Store as JSON array of objects or strings

-- Notify PostgREST to reload schema
NOTIFY pgrst, 'reload config';
