-- Allow users to leave (DELETE) their own membership
-- We previously only allowed INSERT and UPDATE.

CREATE POLICY "Users can leave organizations"
ON public.organization_members
FOR DELETE
TO authenticated
USING (
    user_id = auth.uid()
);
