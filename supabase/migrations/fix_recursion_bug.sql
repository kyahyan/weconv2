-- Create a secure function to check admin status without triggering RLS loops
CREATE OR REPLACE FUNCTION public.check_is_superadmin()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER -- Runs with owner privileges, bypassing RLS
SET search_path = public
AS $$
DECLARE
  is_admin BOOLEAN;
BEGIN
  -- Check if user is authenticated
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT is_superadmin INTO is_admin
  FROM profiles
  WHERE id = auth.uid();
  
  RETURN COALESCE(is_admin, FALSE);
END;
$$;

-- Refactor Profiles Policy
DROP POLICY IF EXISTS "Superadmins can do everything on profiles" ON public.profiles;

CREATE POLICY "Superadmins can do everything on profiles" ON public.profiles
    FOR ALL USING (
        check_is_superadmin() = TRUE
    );

-- Refactor Organizations Policies to use the safe function
DROP POLICY IF EXISTS "Read organizations" ON public.organizations;

CREATE POLICY "Read organizations" ON public.organizations
    FOR SELECT USING (
        status = 'approved' OR 
        auth.uid() = owner_id OR
        check_is_superadmin() = TRUE
    );

DROP POLICY IF EXISTS "Update organizations" ON public.organizations;

CREATE POLICY "Update organizations" ON public.organizations
    FOR UPDATE USING (
        auth.uid() = owner_id OR 
        check_is_superadmin() = TRUE
    );
