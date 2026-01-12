-- We need to remove the OLD restrictions that say "User can only have 1 Role per Org".
-- This script finds any unique constraint on (user_id, organization_id) and drops it.

DO $$
DECLARE
    r RECORD;
BEGIN
    -- Loop through all unique constraints on the table that constitute the old rule
    -- We look for constraints that are NOT our new one ('organization_members_user_org_branch_unique')
    -- and are NOT the Primary Key.
    FOR r IN (
        SELECT conname
        FROM pg_constraint
        WHERE conrelid = 'public.organization_members'::regclass
        AND contype = 'u'  -- Unique constraints only
        AND conname != 'organization_members_user_org_branch_unique' -- Don't delete our new one
    ) LOOP
        -- Execute Drop
        RAISE NOTICE 'Dropping old constraint: %', r.conname;
        EXECUTE 'ALTER TABLE public.organization_members DROP CONSTRAINT ' || quote_ident(r.conname);
    END LOOP;
END $$;
