-- Drop the incorrect policy
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.announcements;

-- Create correct policy allowing members with sufficient privileges to post
CREATE POLICY "Enable insert for org admins and managers"
ON public.announcements
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_members.organization_id = announcements.organization_id
    AND organization_members.user_id = auth.uid()
    AND organization_members.role IN ('owner', 'admin', 'manager')
  )
);

-- Also update DELETE policy as it likely has the same issue
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.announcements;

CREATE POLICY "Enable delete for org admins"
ON public.announcements
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM organization_members
    WHERE organization_members.organization_id = announcements.organization_id
    AND organization_members.user_id = auth.uid()
    AND organization_members.role IN ('owner', 'admin')
  )
);
