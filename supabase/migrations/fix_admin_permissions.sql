-- Fix Admin Permissions for Super Admin Account
-- This script assigns ALL organizations to 'yancolasino01@gmail.com' and ensures they have 'owner' role and superadmin status.

DO $$
DECLARE
    target_email TEXT := 'yancolasino01@gmail.com';
    target_user_id UUID;
BEGIN
    -- 1. Find the User ID from Auth
    SELECT id INTO target_user_id FROM auth.users WHERE email = target_email LIMIT 1;
    
    RAISE NOTICE 'Target User ID: %', target_user_id;

    IF target_user_id IS NOT NULL THEN
        -- 2. Update Profiles: Make Super Admin
        UPDATE public.profiles 
        SET is_superadmin = true 
        WHERE id = target_user_id;

        -- 3. Update Organizations: Transfer ownership to this user
        UPDATE public.organizations 
        SET owner_id = target_user_id;

        -- 4. Ensure Membership: Add 'owner' role in organization_members if missing
        INSERT INTO public.organization_members (organization_id, user_id, role, branch_id)
        SELECT 
            o.id, 
            target_user_id, 
            'owner',
            (SELECT b.id FROM public.branches b WHERE b.organization_id = o.id ORDER BY created_at LIMIT 1)
        FROM public.organizations o
        WHERE NOT EXISTS (
            SELECT 1 FROM public.organization_members om 
            WHERE om.organization_id = o.id AND om.user_id = target_user_id
        );
        
    END IF;
END $$;
