-- Function to Hard Delete an Organization and its Owner (allowing re-registration)
-- NOTE: This requires appropriate privileges. The 'postgres' role in Supabase can usually delete from auth.users.
-- We use SECURITY DEFINER to run this as the creator (postgres) rather than the caller (superadmin user).

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

    -- 3. Delete the User from Auth (This frees up the email)
    -- We delete from auth.users, which should cascade to public.profiles via Foreign Keys if set up, 
    -- but we'll let existing cascades handle it.
    IF target_owner_id IS NOT NULL THEN
        DELETE FROM auth.users WHERE id = target_owner_id;
    END IF;
END;
$$;
