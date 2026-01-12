-- Make yancolasino01@gmail.com the Super Admin

-- 1. Ensure the user exists (they must have signed in/up first)
-- 2. Update their profile
UPDATE public.profiles
SET is_superadmin = TRUE
WHERE username = 'yancolasino01@gmail.com' OR id IN (
    SELECT id FROM auth.users WHERE email = 'yancolasino01@gmail.com'
);

-- Verify
SELECT * FROM public.profiles WHERE is_superadmin = TRUE;
