-- Add superadmin flag to profiles
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS is_superadmin BOOLEAN DEFAULT FALSE;

-- Organizations Table
CREATE TABLE public.organizations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name TEXT NOT NULL,
    owner_id UUID REFERENCES public.profiles(id) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Branches Table
CREATE TABLE public.branches (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Organization Members Table
CREATE TABLE public.organization_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE NOT NULL,
    organization_id UUID REFERENCES public.organizations(id) ON DELETE CASCADE NOT NULL,
    branch_id UUID REFERENCES public.branches(id) ON DELETE SET NULL, -- Can be null if org-wide admin
    role TEXT NOT NULL CHECK (role IN ('owner', 'admin', 'member')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, organization_id)
);

-- RLS Policies

-- Profiles: Superadmins can view/edit all profiles
CREATE POLICY "Superadmins can do everything on profiles" ON public.profiles
    FOR ALL USING (
        (SELECT is_superadmin FROM public.profiles WHERE id = auth.uid()) = TRUE
    );

-- Organizations: 
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Read organizations" ON public.organizations
    FOR SELECT USING (true); -- Publicly viewable for joining/searching

CREATE POLICY "Insert organizations" ON public.organizations
    FOR INSERT WITH CHECK (auth.role() = 'authenticated'); -- Anyone can start an org

CREATE POLICY "Update organizations" ON public.organizations
    FOR UPDATE USING (
        auth.uid() = owner_id OR 
        (SELECT is_superadmin FROM public.profiles WHERE id = auth.uid()) = TRUE
    );

-- Branches:
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Read branches" ON public.branches
    FOR SELECT USING (true);

-- Script to make yancolasino@icloud.com a Superadmin
-- Note: This requires the user to ALREADY exist in profiles.
-- The user ID is fetched dynamically based on the email.
DO $$
BEGIN
    UPDATE public.profiles
    SET is_superadmin = TRUE
    WHERE username = 'yancolasino@icloud.com'; -- Assuming username was set to email by handle_new_user
END $$;
