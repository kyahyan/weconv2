-- Add song_contributor_status to profiles table
ALTER TABLE profiles 
ADD COLUMN song_contributor_status text DEFAULT 'none';

-- Add comment to the column
COMMENT ON COLUMN profiles.song_contributor_status IS 'Status of song contributor request: none, pending, approved, rejected';
