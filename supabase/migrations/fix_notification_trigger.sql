-- Fix Trigger Function: Notify on Service Assignment
-- We need to look up the actual auth.users.id from organization_members table
-- because service_assignments.member_id refers to organization_members.id, not auth.users.id directly.

CREATE OR REPLACE FUNCTION public.handle_new_service_assignment()
RETURNS trigger AS $$
DECLARE
    target_user_id uuid;
BEGIN
    -- Fetch the correct user_id from organization_members
    SELECT user_id INTO target_user_id
    FROM public.organization_members
    WHERE id = NEW.member_id;

    -- Only insert notification if we found a valid user
    IF target_user_id IS NOT NULL THEN
        INSERT INTO public.notifications (user_id, title, body, type, related_id)
        VALUES (
            target_user_id,
            'New Service Assignment',
            'You have been assigned to ' || NEW.team_name || ' as ' || NEW.role_name,
            'assignment',
            NEW.service_id
        );
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
