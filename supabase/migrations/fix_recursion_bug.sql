-- Drop the problematic policies that cause recursion
DROP POLICY IF EXISTS "Update members" ON public.organization_members;
DROP POLICY IF EXISTS "View members of same org" ON public.organization_members;
DROP POLICY IF EXISTS "View members" ON public.organization_members; -- In case it was named differently in previous attempts or defaults

-- Create a helper function to check permissions safely
-- SECURITY DEFINER allows this function to bypass RLS when querying the table
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
            -- 1. Org Owner/Admin can manage anyone in the org
            (om.organization_id = target_org_id AND om.role IN ('owner', 'admin'))
            OR
            -- 2. Branch Manager can manage anyone in their branch
            (om.branch_id = target_branch_id AND om.role = 'manager')
            OR
            -- 3. Ushers can update (for tagging/notes purposes) in their branch
            (om.branch_id = target_branch_id AND 'Usher' = ANY(om.ministry_roles))
        )
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Re-create the policies using the function

-- SELECT Policy (View)
-- We use a simpler check for viewing: valid member of the same org
-- Using a function here too can be safer for recursion, or we can assume basic membership check is fine 
-- providing we don't query the table itself in a complex way.
-- However, standard "member of same org" usually requires querying the table.
-- Let's make a specific view function for "can_view_org_members" to be safe.

CREATE OR REPLACE FUNCTION public.can_view_org_members(target_org_id UUID) 
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.organization_members 
        WHERE user_id = auth.uid() 
        AND organization_id = target_org_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE POLICY "View members" ON public.organization_members
    FOR SELECT
    USING (
        public.can_view_org_members(organization_id)
    );

-- UPDATE Policy
CREATE POLICY "Update members" ON public.organization_members
    FOR UPDATE
    USING (
        -- User can update their own record OR has management permissions
        auth.uid() = user_id 
        OR 
        public.can_manage_member(organization_id, branch_id)
    );

-- Ensure RLS is on
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;
