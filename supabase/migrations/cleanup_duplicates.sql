-- Cleanup Script: Delete "Ghost" Duplicate Organizations
-- The issue: You likely have 2 "WFICM" organizations.
-- 1. The "Real" one (ID: 8d7...) which HAS branches.
-- 2. A "Ghost" one (Different ID) which has NO branches.
-- The App might be loading the "Ghost" one.

DO $$
DECLARE
    r RECORD;
    branch_count INT;
    deleted_count INT := 0;
BEGIN
    RAISE NOTICE 'Starting Cleanup for WFICM duplicates...';

    FOR r IN (SELECT * FROM public.organizations WHERE name = 'WFICM') LOOP
        
        -- Count branches for this specific org ID
        SELECT count(*) INTO branch_count FROM public.branches WHERE organization_id = r.id;
        
        IF branch_count = 0 THEN
            RAISE NOTICE 'Deleting Empty Duplicate Org: % (ID: %)', r.name, r.id;
            
            -- Delete the empty org
            -- Note: Dependent memberships will be cascade deleted if foreign keys are set up that way,
            -- otherwise we delete manually to be safe.
            DELETE FROM public.organization_members WHERE organization_id = r.id;
            DELETE FROM public.organizations WHERE id = r.id;
            
            deleted_count := deleted_count + 1;
        ELSE
            RAISE NOTICE 'Keeping Valid Org: % (ID: %) - Has % branches', r.name, r.id, branch_count;
        END IF;

    END LOOP;

    RAISE NOTICE 'Cleanup Complete. Deleted % empty organizations.', deleted_count;
END $$;
