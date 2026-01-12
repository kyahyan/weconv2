-- Create Attendance Table
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    branch_id UUID NOT NULL REFERENCES public.branches(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    service_date DATE NOT NULL,
    service_type TEXT NOT NULL, -- 'Sunday Service', 'Midweek', etc.
    category TEXT NOT NULL, -- 'new_attender', 'attender', 'worker'
    recorded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    
    -- Ensure one record per user per service per date (optional, prevents duplicates)
    UNIQUE(branch_id, user_id, service_date, service_type)
);

-- Enable RLS
ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is Usher or Admin/Owner for a branch
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
      (ministry_roles::jsonb ? 'Usher') -- Assuming ministry_roles is JSONB
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Policies

-- 1. Select: Ushers and Admins (of that branch) can view
CREATE POLICY "Ushers and Admins can view attendance" ON public.attendance
    FOR SELECT
    USING ( public.is_usher_or_admin(branch_id) );

-- 2. Insert: Ushers and Admins can insert
CREATE POLICY "Ushers and Admins can insert attendance" ON public.attendance
    FOR INSERT
    WITH CHECK ( public.is_usher_or_admin(branch_id) );

-- 3. Update: Ushers and Admins can update
CREATE POLICY "Ushers and Admins can update attendance" ON public.attendance
    FOR UPDATE
    USING ( public.is_usher_or_admin(branch_id) );

-- 4. Delete: Ushers and Admins can delete
CREATE POLICY "Ushers and Admins can delete attendance" ON public.attendance
    FOR DELETE
    USING ( public.is_usher_or_admin(branch_id) );
