-- Fix services table foreign key to allow user deletion
-- Previous definition was: worship_leader_id UUID REFERENCES public.profiles(id)
-- This blocks deletion of a profile if they are a worship leader.
-- We change it to ON DELETE SET NULL.

DO $$
BEGIN
    -- Try to drop the constraint if it exists (guessing the name)
    -- Postgres standard naming: table_column_fkey
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'services_worship_leader_id_fkey') THEN
        ALTER TABLE public.services DROP CONSTRAINT services_worship_leader_id_fkey;
    END IF;
    
    -- Re-add the constraint with ON DELETE SET NULL
    ALTER TABLE public.services
    ADD CONSTRAINT services_worship_leader_id_fkey
    FOREIGN KEY (worship_leader_id)
    REFERENCES public.profiles(id)
    ON DELETE SET NULL;
END $$;
