-- Enable RLS on branches if not already
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

-- Policy: Allow Owners, Admins, and respective Managers to update branch details
CREATE POLICY "Allow update for authorized roles" ON public.branches
FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM public.organization_members om
    WHERE om.user_id = auth.uid()
    AND om.organization_id = branches.organization_id
    AND (
       -- Owners and Admins can update any branch in the org
       om.role IN ('owner', 'admin')
       OR
       -- Managers can ONLY update the branch they are assigned to
       (om.role = 'manager' AND om.branch_id = branches.id)
    )
  )
);
