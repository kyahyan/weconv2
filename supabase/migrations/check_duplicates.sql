-- Check for duplicate organizations
SELECT id, name, status, created_at, owner_id 
FROM public.organizations 
WHERE name = 'WFICM'
ORDER BY created_at DESC;

-- Also check which Org the branches belong to
SELECT b.name as branch_name, o.id as org_id, o.name as org_name, o.created_at as org_created_at
FROM public.branches b
JOIN public.organizations o ON b.organization_id = o.id
WHERE o.name = 'WFICM';
