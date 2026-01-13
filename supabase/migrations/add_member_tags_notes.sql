-- Add tags and notes to organization_members
ALTER TABLE public.organization_members
ADD COLUMN IF NOT EXISTS tags TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS notes TEXT DEFAULT '';

-- Helper to get all distinct tags used in a branch (for autocomplete)
CREATE OR REPLACE FUNCTION get_branch_tags(branch_uuid UUID)
RETURNS TABLE (tag TEXT)
LANGUAGE sql
AS $$
  SELECT DISTINCT unnest(tags)
  FROM public.organization_members
  WHERE branch_id = branch_uuid
  ORDER BY 1;
$$;
