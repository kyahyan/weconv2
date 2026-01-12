-- Update the Hard Reject function to handle profiles constraint
CREATE OR REPLACE FUNCTION public.reject_and_delete_organization(target_org_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    target_owner_id UUID;
BEGIN
    -- 1. Get the owner_id before deleting the org
    SELECT owner_id INTO target_owner_id
    FROM public.organizations
    WHERE id = target_org_id;

    -- 2. Delete the Organization (Cascade will remove branches, members, services etc.)
    DELETE FROM public.organizations WHERE id = target_org_id;

    -- 3. Delete the User 
    IF target_owner_id IS NOT NULL THEN
        -- A. Must delete Profile first to satisfy FK constraint 'profiles_id_fkey'
        DELETE FROM public.profiles WHERE id = target_owner_id;
        
        -- B. Now delete from Auth (frees up email)
        DELETE FROM auth.users WHERE id = target_owner_id;
    END IF;
END;
$$;
