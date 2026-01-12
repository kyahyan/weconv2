-- Diagnostic Script: Check Branches and Permissions

-- 1. List all branches with their Organization Name
-- This will confirm if the branches actually exist in the DB.
SELECT 
    b.id as branch_id, 
    b.name as branch_name, 
    o.name as org_name, 
    o.status as org_status
FROM public.branches b
JOIN public.organizations o ON b.organization_id = o.id;

-- 2. Check if RLS is enabled on branches
SELECT relname, relrowsecurity 
FROM pg_class 
WHERE oid = 'public.branches'::regclass;

-- 3. Check Policies on branches
SELECT * FROM pg_policies WHERE tablename = 'branches';

-- 4. Force allow select (Just in case the previous one failed)
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
GRANT SELECT ON public.branches TO authenticated;
GRANT SELECT ON public.branches TO anon; -- Just for testing, remove later if needed

DROP POLICY IF EXISTS "Allow all to read branches" ON public.branches;
CREATE POLICY "Allow all to read branches"
ON public.branches
FOR SELECT
USING (true);
