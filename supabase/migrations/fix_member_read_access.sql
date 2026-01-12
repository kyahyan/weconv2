-- Ensure Admins (and members) can VIEW the member list
-- Current policies might be too restrictive or broken.

CREATE POLICY "View Members of My Org"
ON public.organization_members
FOR SELECT
TO authenticated
USING (
    organization_id IN (
        SELECT organization_id FROM public.organization_members
        WHERE user_id = auth.uid()
    )
    OR 
    EXISTS (
        SELECT 1 FROM public.organizations 
        WHERE id = organization_id AND owner_id = auth.uid()
    )
);
