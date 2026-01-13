-- Add new columns to branches table
ALTER TABLE branches
ADD COLUMN IF NOT EXISTS acronym TEXT,
ADD COLUMN IF NOT EXISTS contact_mobile TEXT,
ADD COLUMN IF NOT EXISTS contact_landline TEXT,
ADD COLUMN IF NOT EXISTS address TEXT,
ADD COLUMN IF NOT EXISTS social_media_links JSONB,
ADD COLUMN IF NOT EXISTS avatar_url TEXT;

-- Indexing for performance if needed (jsonb often benefits from gin, but simple lookup is fine)
-- CREATE INDEX IF NOT EXISTS idx_branches_social ON branches USING gin (social_media_links);
