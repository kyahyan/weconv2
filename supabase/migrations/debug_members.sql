-- Helper to check memberships for verification
-- We need to know the User ID and Org ID. 
-- Validating if multiple rows exist.

SELECT 
    om.id,
    om.user_id,
    p.email, 
    om.organization_id, 
    o.name as org_name,
    om.branch_id,
    b.name as branch_name,
    om.role
FROM public.organization_members om
JOIN public.profiles p ON om.user_id = p.id
JOIN public.organizations o ON om.organization_id = o.id
LEFT JOIN public.branches b ON om.branch_id = b.id
ORDER BY om.created_at DESC;
