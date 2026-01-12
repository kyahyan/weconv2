-- Allow users to Insert (Join) themselves into organizations
CREATE POLICY "Users can join organizations" 
ON public.organization_members 
FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = user_id);

-- Allow users to Update their own membership (e.g. switching branches)
CREATE POLICY "Users can update own membership" 
ON public.organization_members 
FOR UPDATE
TO authenticated 
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
