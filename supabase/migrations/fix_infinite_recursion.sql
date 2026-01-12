-- Fix Infinite Recursion by using a SECURITY DEFINER function
-- This allows us to query organization_members WITHOUT triggering the RLS policy recursively.

-- 1. Create a secure function to get my orgs
CREATE OR REPLACE FUNCTION public.get_my_org_ids()
RETURNS TABLE (org_id uuid) 
SECURITY DEFINER -- <--- Crucial: Runs with privileges of creator, bypassing RLS
SET search_path = public -- Secure search path
LANGUAGE plpgsql
AS $$
BEGIN
  RETURN QUERY 
  SELECT organization_id 
  FROM public.organization_members 
  WHERE user_id = auth.uid();
END;
$$;

-- 2. Drop the buggy policy
DROP POLICY IF EXISTS "View Members of My Org" ON public.organization_members;

-- 3. Re-create the policy using the secure function
CREATE POLICY "View Members of My Org"
ON public.organization_members
FOR SELECT
TO authenticated
USING (
    organization_id IN ( SELECT org_id FROM get_my_org_ids() )
    OR 
    EXISTS (
        SELECT 1 FROM public.organizations 
        WHERE id = organization_id AND owner_id = auth.uid()
    )
);
