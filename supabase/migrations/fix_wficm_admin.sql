-- Fix Admin Permissions for WFICM Account
-- This script assigns ALL organizations to 'wficm@gmail.com' and ensures they have 'owner' role.

DO $$
DECLARE
    target_email TEXT := 'wficm@gmail.com';
    target_user_id UUID;
BEGIN
    -- 1. Find the User ID from Auth
    SELECT id INTO target_user_id FROM auth.users WHERE email = target_email LIMIT 1;
    
    RAISE NOTICE 'Target User ID for %: %', target_email, target_user_id;

    IF target_user_id IS NOT NULL THEN
        -- 2. Update Profiles: Make Super Admin (optional, but good for testing)
        UPDATE public.profiles 
        SET is_superadmin = true 
        WHERE id = target_user_id;

        -- 3. Update Organizations: Transfer ownership to this user
        -- WARNING: This transfers ownership of ALL orgs. Adjust if multi-tenant.
        UPDATE public.organizations 
        SET owner_id = target_user_id;

        -- 4. Ensure Membership: Add 'owner' role in organization_members if missing
        -- First, we need to know which organizations exist.
        -- We will insert a membership for EVERY organization found.
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

        -- 5. Force update existing membership if valid but wrong role
        UPDATE public.organization_members
        SET role = 'owner'
        WHERE user_id = target_user_id;
        
    ELSE
        RAISE NOTICE 'User % not found in auth.users', target_email;
    END IF;
END $$;
