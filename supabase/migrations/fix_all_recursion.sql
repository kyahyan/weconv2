-- COMPREHENSIVE FIX FOR INFINITE RECURSION
-- We are replacing direct table queries with SECURITY DEFINER functions.
-- This breaks the "Loop" because the function runs with elevated privileges
-- and doesn't trigger the RLS check on itself again.

-- 1. Helper Function: Am I a member of this Org?
CREATE OR REPLACE FUNCTION public.is_org_member(target_org_id uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE organization_id = target_org_id
    AND user_id = auth.uid()
  );
END;
$$;

-- 2. Helper Function: Am I a Manager of this Branch?
CREATE OR REPLACE FUNCTION public.is_branch_manager(target_org_id uuid, target_branch_id uuid)
RETURNS boolean
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE organization_id = target_org_id
    AND branch_id = target_branch_id
    AND user_id = auth.uid()
    AND role = 'manager'
  );
END;
$$;

-- 3. Drop ALL existing policies on organization_members (Clean Slate)
DROP POLICY IF EXISTS "View Members of My Org" ON public.organization_members;
DROP POLICY IF EXISTS "Managers can update members in their branch" ON public.organization_members;
DROP POLICY IF EXISTS "Users can leave organizations" ON public.organization_members;
DROP POLICY IF EXISTS "Users can join default branch" ON public.organization_members;
DROP POLICY IF EXISTS "Users can join specific branch" ON public.organization_members;
DROP POLICY IF EXISTS "Users can see own membership" ON public.organization_members;
DROP POLICY IF EXISTS "Owners can view all members" ON public.organization_members; -- If exists

-- 4. Re-Apply Policies using SAFE functions

-- A. SELECT: See myself OR see others if I am a member of the same Org
CREATE POLICY "Safe Read Members"
ON public.organization_members
FOR SELECT
TO authenticated
USING (
    user_id = auth.uid() -- I can always see myself
    OR
    public.is_org_member(organization_id) -- I can see others if I'm in the org
    OR
    EXISTS ( -- I can see if I am the Org Owner (Organizations table policy usually handles this, but good to be safe)
        SELECT 1 FROM public.organizations 
        WHERE id = organization_id AND owner_id = auth.uid()
    )
);

-- B. INSERT: Join (Standard check on user_id)
CREATE POLICY "Safe Join"
ON public.organization_members
FOR INSERT
TO authenticated
WITH CHECK (
    user_id = auth.uid()
);

-- C. UPDATE: Managers can update members in their branch
CREATE POLICY "Safe Manager Update"
ON public.organization_members
FOR UPDATE
TO authenticated
USING (
    public.is_branch_manager(organization_id, branch_id)
);

-- D. DELETE: Leave (Delete my own row)
CREATE POLICY "Safe Leave"
ON public.organization_members
FOR DELETE
TO authenticated
USING (
    user_id = auth.uid()
);
