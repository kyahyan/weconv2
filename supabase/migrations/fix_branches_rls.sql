-- Enable RLS on organization_members if not already
ALTER TABLE public.organization_members ENABLE ROW LEVEL SECURITY;

-- Policy: Allow organization owners to insert branches for their org
CREATE POLICY "Owners can insert branches" ON public.branches
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.organizations 
            WHERE id = organization_id 
            AND owner_id = auth.uid()
        )
    );

-- Policy: Allow organization owners to add members (including themselves)
CREATE POLICY "Owners can insert members" ON public.organization_members
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.organizations 
            WHERE id = organization_id 
            AND owner_id = auth.uid()
        )
    );

-- Policy: Members can view their own membership
CREATE POLICY "Members can view own membership" ON public.organization_members
    FOR SELECT USING (
        user_id = auth.uid() OR 
        check_is_superadmin() = TRUE
    );
