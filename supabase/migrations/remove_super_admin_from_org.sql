-- Remove Organization Admin Role from Super Admin
-- This script removes 'yancolasino01@gmail.com' from the 'organization_members' table
-- so they no longer appear as an Org Admin/Owner, but remain a Super Admin.

DO $$
DECLARE
    target_email TEXT := 'yancolasino01@gmail.com';
BEGIN
    -- Remove from organization members
    DELETE FROM public.organization_members
    USING auth.users
    WHERE public.organization_members.user_id = auth.users.id
    AND auth.users.email = target_email;

    RAISE NOTICE 'Removed organization membership for %', target_email;
END $$;
