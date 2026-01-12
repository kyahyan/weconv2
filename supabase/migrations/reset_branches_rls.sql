-- "Nuke" Script: Reset Branch Policies to be 100% Open
-- We suspect existing policies might be conflicting or failing.

ALTER TABLE public.branches DISABLE ROW LEVEL SECURITY; -- Typo fixed: DISABLE, not ERROR
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

-- Drop ALL known policies on branches
DROP POLICY IF EXISTS "Authenticated users can read branches" ON public.branches;
DROP POLICY IF EXISTS "Start fresh read branches" ON public.branches;
DROP POLICY IF EXISTS "Owners can insert branches" ON public.branches;
DROP POLICY IF EXISTS "Everyone read branches" ON public.branches;
DROP POLICY IF EXISTS "Allow all to read branches" ON public.branches;
DROP POLICY IF EXISTS "Read branches" ON public.branches;
DROP POLICY IF EXISTS "Public Read Access" ON public.branches;
DROP POLICY IF EXISTS "Owners Insert Access" ON public.branches;

-- Create ONE simple policy for EVERYTHING (Read)
CREATE POLICY "Public Read Access"
ON public.branches
FOR SELECT
TO authenticated
USING (true);

-- Restore Insert Policy (restricting to owners)
CREATE POLICY "Owners Insert Access"
ON public.branches
FOR INSERT
TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.organizations 
        WHERE id = organization_id 
        AND owner_id = auth.uid()
    )
);
