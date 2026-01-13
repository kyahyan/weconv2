-- Create a new migration to relax the permissions significantly for testing/unblocking tags.
-- We will allow ANY member of the same branch to update other members in that branch.

CREATE OR REPLACE FUNCTION public.can_manage_member(
    target_org_id UUID,
    target_branch_id UUID
) RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 
        FROM public.organization_members om
        WHERE om.user_id = auth.uid()
        AND (
            -- 1. Org Owner/Admin can manage anyone in the org (Cross-branch)
            (om.organization_id = target_org_id AND om.role IN ('owner', 'admin'))
            OR
            -- 2. Anyone in the same branch can manage (Update tags/notes)
            -- This covers Managers, Ushers, and regular Members within the branch context.
            (om.branch_id = target_branch_id)
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-apply policies to ensure they use the updated function logic
-- (The logic is dynamic inside the function, so re-creating the function is enough, 
-- but we ensure the policy exists).

DROP POLICY IF EXISTS "Update members" ON public.organization_members;

CREATE POLICY "Update members" ON public.organization_members
    FOR UPDATE
    USING (
        auth.uid() = user_id 
        OR 
        public.can_manage_member(organization_id, branch_id)
    );
