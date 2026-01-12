-- Fix: Allow 'owner' (and 'manager') in the role column
-- The previous script failed because 'owner' rows already existed.

-- 1. Drop the old constraint
ALTER TABLE public.organization_members
DROP CONSTRAINT IF EXISTS "organization_members_role_check";

-- 2. Add the new constraint (allow ALL known roles)
ALTER TABLE public.organization_members
ADD CONSTRAINT "organization_members_role_check"
CHECK (role IN ('member', 'admin', 'manager', 'owner'));
