-- Enable RLS on organization_members
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

-- Policy: Allow members to view other members in the same organization
CREATE POLICY "View members of same org" ON public.organization_members
FOR SELECT
USING (
    organization_id IN (
        SELECT organization_id 
        FROM public.organization_members 
        WHERE user_id = auth.uid()
    )
);

-- Policy: Allow updating members (tags, notes, etc.)
-- Who can update?
-- 1. Owners/Admins of the organization
-- 2. Managers of the specific branch
-- 3. Users with "Usher" in their ministry_roles (for taking attendance/tagging)
CREATE POLICY "Update members" ON public.organization_members
FOR UPDATE
USING (
    -- Check if requester is Owner/Admin of the org
    EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.user_id = auth.uid()
        AND om.organization_id = organization_members.organization_id
        AND om.role IN ('owner', 'admin')
    )
    OR
    -- Check if requester is Manager of the branch
    EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.user_id = auth.uid()
        AND om.branch_id = organization_members.branch_id
        AND om.role = 'manager'
    )
    OR
    -- Check if requester has 'Usher' role (case insensitive check often safer but string strict here)
    EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.user_id = auth.uid()
        AND om.branch_id = organization_members.branch_id
        AND 'Usher' = ANY(om.ministry_roles) -- Assuming 'Usher' is exact string used
    )
    OR
    -- Allow users to update their own record? (Maybe not needed for tags/notes by themselves)
    auth.uid() = user_id
)
WITH CHECK (
    -- Same conditions for the new row state
    EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.user_id = auth.uid()
        AND om.organization_id = organization_members.organization_id
        AND om.role IN ('owner', 'admin')
    )
    OR
    EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.user_id = auth.uid()
        AND om.branch_id = organization_members.branch_id
        AND om.role = 'manager'
    )
    OR
    EXISTS (
        SELECT 1 FROM public.organization_members om
        WHERE om.user_id = auth.uid()
        AND om.branch_id = organization_members.branch_id
        AND 'Usher' = ANY(om.ministry_roles)
    )
    OR
    auth.uid() = user_id
);

-- Policy: Allow Insert? Usually handling by invite logic or admin dashboard. 
-- Existing policies might cover inserts if any, but for now we focus on UPDATE fix.
