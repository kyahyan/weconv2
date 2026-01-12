-- Fix: Allow Org Owners to Update Members (Promote to Manager)
-- Previously, only existing Managers could update, blocking the Owner from creating the first Manager.

DROP POLICY IF EXISTS "Safe Manager Update" ON public.organization_members;

CREATE POLICY "Safe Manager Update"
ON public.organization_members
FOR UPDATE
TO authenticated
USING (
    public.is_branch_manager(organization_id, branch_id) -- Managers can update their branch
    OR
    EXISTS ( -- Owners can update their org
        SELECT 1 FROM public.organizations 
        WHERE id = organization_id AND owner_id = auth.uid()
    )
);
