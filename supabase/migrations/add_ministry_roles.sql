-- 1. Add ministry_roles column (Array of Text)
ALTER TABLE public.organization_members
ADD COLUMN IF NOT EXISTS ministry_roles text[] DEFAULT '{}';

-- 2. Allow Managers to UPDATE members within their own branch
-- Note: This policy allows updating *any* column, but we will control UI to only utilize ministry_roles.
-- Ideally, we'd restrict column updates, but RLS is row-based.
-- This checks: Is the user executing the update a 'manager' of the SAME branch as the target row?

CREATE POLICY "Managers can update members in their branch"
ON public.organization_members
FOR UPDATE
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.organization_members AS my_membership
        WHERE my_membership.user_id = auth.uid()
        AND my_membership.branch_id = organization_members.branch_id -- Same Branch
        AND my_membership.organization_id = organization_members.organization_id -- Same Org (Redundant but safe)
        AND my_membership.role = 'manager' -- I am a Manager
    )
)
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.organization_members AS my_membership
        WHERE my_membership.user_id = auth.uid()
        AND my_membership.branch_id = organization_members.branch_id
        AND my_membership.role = 'manager'
    )
);
