-- Drop the existing unique constraint which limits 1 role per user per org
-- Constraint name usually follows pattern: table_col_col_key. We'll try to drop by name or by definition if possible.
-- Since we know the definition is UNIQUE(user_id, organization_id), we can try to drop it.
-- Depending on Postgres version, we might need the exact name. 
-- In the original create script: UNIQUE(user_id, organization_id)
-- Supabase likely named it "organization_members_user_id_organization_id_key"

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'organization_members_user_id_organization_id_key') THEN
        ALTER TABLE public.organization_members DROP CONSTRAINT "organization_members_user_id_organization_id_key";
    END IF;
END $$;

-- Add new unique constraint including branch_id
-- This allows:
-- User A, Org 1, Branch A
-- User A, Org 1, Branch B
-- But prevents duplicate: User A, Org 1, Branch A
ALTER TABLE public.organization_members 
ADD CONSTRAINT "organization_members_user_org_branch_unique" 
UNIQUE (user_id, organization_id, branch_id);
