-- Function to allow Super Admins to delete a user and all their related data
CREATE OR REPLACE FUNCTION delete_user_as_admin(target_user_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Check if the executing user is a Super Admin
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles 
    WHERE id = auth.uid() AND is_superadmin = TRUE
  ) THEN
    RAISE EXCEPTION 'Access Denied: Only Super Admins can delete users.';
  END IF;

  -- 2. Delete organizations owned by the user
  -- This is required because 'organizations' -> 'owner_id' might not have ON DELETE CASCADE.
  -- Deleting an organization usually cascades to branches, members, etc.
  DELETE FROM public.organizations WHERE owner_id = target_user_id;

  -- 3. Delete the user's profile
  -- Explicitly deleting the profile ensures efficient cascading to all tables referencing public.profiles
  -- (like organization_members, posts, comments, etc.) and avoids potential foreign key issues 
  -- if the profiles -> auth.users constraint is not ON DELETE CASCADE.
  DELETE FROM public.profiles WHERE id = target_user_id;

  -- 4. Delete the user from auth.users
  -- This completely removes the user's authentication record.
  -- SECURITY DEFINER allows this if the creator (postgres) has permissions.
  DELETE FROM auth.users WHERE id = target_user_id;
END;
$$;
