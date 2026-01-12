-- Enable RLS on branches (ensure it is on)
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

-- Allow everyone (authenticated) to READ/SELECT branches
-- We previously only added INSERT policies for Owners.
-- We missed the SELECT policy for normal users.

DROP POLICY IF EXISTS "Authenticated users can read branches" ON public.branches;

CREATE POLICY "Authenticated users can read branches"
ON public.branches
FOR SELECT
TO authenticated
USING (true);
