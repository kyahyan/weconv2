DO $$
DECLARE
    target_org_id uuid;
BEGIN
    -- 1. Get the ID of the 'WFICM' organization (using the most recent one if duplicates exist)
    SELECT id INTO target_org_id 
    FROM public.organizations 
    WHERE name = 'WFICM' 
    ORDER BY created_at DESC 
    LIMIT 1;

    IF target_org_id IS NOT NULL THEN
        RAISE NOTICE 'Target Org ID: %', target_org_id;

        -- 2. Check if branches exist for this Org
        IF NOT EXISTS (SELECT 1 FROM public.branches WHERE organization_id = target_org_id) THEN
            RAISE NOTICE 'No branches found. Creating defaults...';
            
            INSERT INTO public.branches (organization_id, name) VALUES 
            (target_org_id, 'Main Campus'),
            (target_org_id, 'Marikina Chapter'),
            (target_org_id, 'San Mateo'),
            (target_org_id, 'Montalban');
        ELSE
            RAISE NOTICE 'Branches found. Count: %', (SELECT count(*) FROM public.branches WHERE organization_id = target_org_id);
        END IF;
    ELSE
        RAISE NOTICE 'Organization WFICM not found.';
    END IF;
END $$;

-- Verify Policies again just in case
ALTER TABLE public.branches ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Everyone read branches" ON public.branches;
CREATE POLICY "Everyone read branches" ON public.branches FOR SELECT USING (true);
