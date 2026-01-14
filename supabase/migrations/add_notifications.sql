-- Create notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id uuid NOT NULL DEFAULT gen_random_uuid(),
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title text NOT NULL,
    body text NOT NULL,
    type text NOT NULL, -- 'assignment', 'announcement', etc.
    related_id uuid, -- Optional Ref ID
    is_read boolean NOT NULL DEFAULT false,
    created_at timestamp with time zone NOT NULL DEFAULT now(),
    CONSTRAINT notifications_pkey PRIMARY KEY (id)
);

-- RLS Policies
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own notifications"
    ON public.notifications FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications (mark as read)"
    ON public.notifications FOR UPDATE
    USING (auth.uid() = user_id);

-- Trigger Function: Notify on Service Assignment
CREATE OR REPLACE FUNCTION public.handle_new_service_assignment()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.notifications (user_id, title, body, type, related_id)
    VALUES (
        NEW.member_id,
        'New Service Assignment',
        'You have been assigned to ' || NEW.team_name || ' as ' || NEW.role_name,
        'assignment',
        NEW.service_id
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Service Assignment
DROP TRIGGER IF EXISTS on_service_assignment_created ON public.service_assignments;
CREATE TRIGGER on_service_assignment_created
    AFTER INSERT ON public.service_assignments
    FOR EACH ROW
    EXECUTE PROCEDURE public.handle_new_service_assignment();


-- Trigger Function: Notify on Announcement
-- This is trickier as we need to fan-out to all members of the org/branch.
-- We will use a cursor or insert-select.
CREATE OR REPLACE FUNCTION public.handle_new_announcement()
RETURNS trigger AS $$
BEGIN
    -- If branch_id is set, notify branch members
    IF NEW.branch_id IS NOT NULL THEN
        INSERT INTO public.notifications (user_id, title, body, type, related_id)
        SELECT 
            om.user_id,
            'New Announcement',
            NEW.title,
            'announcement',
            NEW.id
        FROM public.organization_members om
        WHERE om.branch_id = NEW.branch_id
        AND om.user_id != NEW.author_id; -- Don't notify the author
    
    -- If only organization_id is set (and branch_id is null - Org Wide), notify all org members
    ELSIF NEW.organization_id IS NOT NULL THEN
        INSERT INTO public.notifications (user_id, title, body, type, related_id)
        SELECT 
            om.user_id,
            'Organization Announcement',
            NEW.title,
            'announcement',
            NEW.id
        FROM public.organization_members om
        WHERE om.organization_id = NEW.organization_id
        AND om.user_id != NEW.author_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger: Announcement
DROP TRIGGER IF EXISTS on_announcement_created ON public.announcements;
CREATE TRIGGER on_announcement_created
    AFTER INSERT ON public.announcements
    FOR EACH ROW
    EXECUTE PROCEDURE public.handle_new_announcement();
