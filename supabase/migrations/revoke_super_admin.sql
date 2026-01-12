-- Revoke Super Admin from Org Admin Account
-- This script removes superadmin status from 'wficm@gmail.com' but keeps their Organization ownership.

DO $$
DECLARE
    target_email TEXT := 'wficm@gmail.com';
BEGIN
    -- Update Profiles: Remove Super Admin status
    UPDATE public.profiles 
    SET is_superadmin = false 
    FROM auth.users
    WHERE public.profiles.id = auth.users.id
    AND auth.users.email = target_email;

    RAISE NOTICE 'Revoked Super Admin status from %', target_email;
END $$;
