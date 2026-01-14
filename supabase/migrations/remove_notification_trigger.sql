-- Drop the trigger that auto-notifies on service assignment creation
DROP TRIGGER IF EXISTS on_service_assignment_created ON public.service_assignments;
DROP FUNCTION IF EXISTS public.handle_new_service_assignment();
