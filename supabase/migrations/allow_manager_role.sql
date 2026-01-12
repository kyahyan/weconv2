-- Allow 'manager' in the role column
-- The error "violates check constraint" means the DB was strictly enforcing a list (e.g. 'member', 'admin').

-- 1. Drop the old constraint
ALTER TABLE public.organization_members
DROP CONSTRAINT IF EXISTS "organization_members_role_check";

-- 2. Add the new constraint (including 'manager')
ALTER TABLE public.organization_members
ADD CONSTRAINT "organization_members_role_check"
CHECK (role IN ('member', 'admin', 'manager'));
