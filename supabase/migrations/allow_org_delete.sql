-- Allow Super Admins to DELETE organizations
CREATE POLICY "Super Admins can delete organizations"
ON public.organizations
FOR DELETE
USING (
  (SELECT is_superadmin FROM public.profiles WHERE id = auth.uid()) = TRUE
);
