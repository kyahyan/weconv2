-- Fix is_usher_or_admin to handle text[] correctly
CREATE OR REPLACE FUNCTION public.is_usher_or_admin(target_branch_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.organization_members
    WHERE user_id = auth.uid()
    AND branch_id = target_branch_id
    AND (
      role IN ('owner', 'admin') 
      OR 
      'Usher' = ANY(ministry_roles)
      OR
      'Ushering' = ANY(ministry_roles)
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
